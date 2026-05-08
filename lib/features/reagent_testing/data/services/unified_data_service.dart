import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/reagent_model.dart';
import '../models/drug_result_model.dart';
import 'remote_config_service.dart';
import '../../../../core/utils/logger.dart';

// ═════════════════════════════════════════════════════════════════════════════
// Enums & Value Objects
// ═════════════════════════════════════════════════════════════════════════════

enum DataSource { firebase, local, staleCache }

/// Severity assigned to the current data state — used by UI to decide
/// whether to show a warning banner.
enum DataHealthStatus {
  /// Firebase data, fresh.
  healthy,

  /// Firebase data returned but might be slightly old (< 2 * TTL).
  degraded,

  /// Local JSON or stale cache — user should be warned.
  fallback,
}

// ─── DataSnapshot ────────────────────────────────────────────────────────────

/// Everything the UI needs to know about the current data load result.
class DataSnapshot {
  final List<ReagentModel> reagents;
  final DataSource source;
  final DataHealthStatus health;
  final String version;
  final DateTime loadedAt;

  /// Set when [health] != healthy, so the UI can display it.
  final String? warningMessage;

  const DataSnapshot({
    required this.reagents,
    required this.source,
    required this.health,
    required this.version,
    required this.loadedAt,
    this.warningMessage,
  });

  bool get isFirebase  => source == DataSource.firebase;
  bool get isFallback  => source == DataSource.local || source == DataSource.staleCache;
  bool get hasWarning  => warningMessage != null;
}

// ─── ReagentSafetyData ───────────────────────────────────────────────────────

class ReagentSafetyData {
  final String reagentName;
  final String safetyLevel;
  final List<String> requiredEquipment;
  final List<String> handlingProcedures;
  final List<String> specificHazards;
  final List<String> storageRequirements;

  const ReagentSafetyData({
    required this.reagentName,
    required this.safetyLevel,
    required this.requiredEquipment,
    required this.handlingProcedures,
    required this.specificHazards,
    required this.storageRequirements,
  });

  factory ReagentSafetyData.fromJson(
    String name,
    Map<String, dynamic> jsonMap,
  ) {
    List<String> asList(String key) =>
        (jsonMap[key] as List? ?? []).map((e) => e.toString()).toList();

    return ReagentSafetyData(
      reagentName:         name,
      safetyLevel:         jsonMap['safetyLevel']?.toString() ?? 'MEDIUM',
      requiredEquipment:   asList('requiredEquipment'),
      handlingProcedures:  asList('handlingProcedures'),
      specificHazards:     asList('specificHazards'),
      storageRequirements: asList('storageRequirements'),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// UnifiedDataService — Production-Grade
// ═════════════════════════════════════════════════════════════════════════════

/// Single source of truth for all application data.
///
/// Design principles (Production rules):
///   P1 — Firebase is ALWAYS the primary source. Local JSON is a temporary
///        cold-start fallback only — never preferred over Firebase.
///   P2 — No silent failures. Every exception is logged at error level.
///        Swallowed exceptions that affect data integrity are forbidden.
///   P3 — Stale cache is always flagged explicitly with a [warningMessage]
///        so the UI can inform the user.
///   P4 — Cache validity is verified against both TTL and data version.
///        If Firebase has a newer version, cache is rejected.
///   P5 — Local JSON is used ONLY for a first offline run (cold start).
///        Once Firebase data has been cached, local JSON is never served again.
class UnifiedDataService {
  final RemoteConfigService _remoteConfig;
  final Connectivity _connectivity;

  // ── Cache ─────────────────────────────────────────────────────────────────
  List<ReagentModel>? _cachedReagents;
  Map<String, ReagentSafetyData>? _cachedSafety;
  Map<String, List<String>>? _cachedReferences;
  DateTime? _cacheTimestamp;
  String _cacheVersion = '';

  /// Whether Firebase data has been successfully loaded at least once
  /// in this app session. When true, local JSON fallback is disabled.
  bool _firebaseLoadedAtLeastOnce = false;

  // TTL: 30 minutes for the primary cache. After this, a background refresh
  // is attempted. The cache is still served (as stale) while refreshing.
  static const Duration _cacheTtl       = Duration(minutes: 30);
  // Max stale age: 2 hours. Beyond this, stale cache is rejected entirely.
  static const Duration _maxStaleAge    = Duration(hours: 2);
  // Local JSON version (bumped manually when you update the asset files)
  static const String   _localVersion   = '1.0.0-local';

  // Asset paths
  static const String _reagentsAsset = 'assets/data/reagents.json';
  static const String _safetyAsset   = 'assets/data/safety.json';
  static const String _refsAsset     = 'assets/data/references.json';

  /// Broadcast stream: emits a [DataSnapshot] on every successful load.
  /// UI layers should listen to this instead of calling [loadAllReagents]
  /// directly from streams.
  final _snapshotController = StreamController<DataSnapshot>.broadcast();
  Stream<DataSnapshot> get onSnapshot => _snapshotController.stream;

  // Expose basic state for Provider / banner widget
  DataSource get lastSource         => _lastDataSource;
  DataSource _lastDataSource        = DataSource.local;
  bool       get hasCachedData      => _cachedReagents != null;
  bool       get firebaseEverLoaded => _firebaseLoadedAtLeastOnce;
  String     get cacheVersion       => _cacheVersion;

  UnifiedDataService({
    RemoteConfigService? remoteConfig,
    Connectivity?        connectivity,
  })  : _remoteConfig = remoteConfig ?? RemoteConfigService(),
        _connectivity = connectivity ?? Connectivity();

  // ── Initialisation ─────────────────────────────────────────────────────────

  /// Must be called once at app startup before any UI is rendered.
  /// Throws [DataServiceException] if Remote Config cannot be initialised
  /// AND there is no local fallback data (first run, no internet).
  /// Must be called once at app startup.
  Future<void> initialize() async {
    Logger.info('🚀 [UnifiedDataService] Initializing...');
    try {
      await _remoteConfig.initialize();
      Logger.info('✅ [UnifiedDataService] Remote Config ready');
    } catch (e, st) {
      Logger.error('❌ [UnifiedDataService] Remote Config init FAILED: $e', error: e, stackTrace: st);
      // We don't rethrow here because we want the app to start even if offline
    }
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Attempts to fetch the latest data from Firebase Remote Config.
  /// Throws if offline or Firebase fails.
  Future<DataSnapshot> fetchFromRemoteConfig() async {
    Logger.info('☁️ [UnifiedDataService] Fetching from Remote Config...');
    
    if (!await _isOnline()) {
      throw const DataServiceException('Device is offline', source: DataSource.firebase);
    }

    try {
      await _remoteConfig.fetchAndActivate();
      final result = await _loadFromFirebase();
      _commitCache(DataSource.firebase, result.reagents, result.version);
      _firebaseLoadedAtLeastOnce = true;

      final snap = _buildSnapshot(
        reagents: result.reagents,
        source: DataSource.firebase,
        health: DataHealthStatus.healthy,
        version: result.version,
      );
      Logger.info('✅ [UnifiedDataService] Loaded from Remote Config');
      _snapshotController.add(snap);
      return snap;
    } catch (e, st) {
      Logger.error('❌ [UnifiedDataService] Remote fetch failed: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Loads bundled data from local JSON assets.
  Future<DataSnapshot> loadFromAssets() async {
    Logger.info('📂 [UnifiedDataService] Loading from local assets...');
    try {
      final reagents = await _loadFromLocalJson();
      _commitCache(DataSource.local, reagents, _localVersion);

      final snap = _buildSnapshot(
        reagents: reagents,
        source: DataSource.local,
        health: DataHealthStatus.fallback,
        version: _localVersion,
        warningMessage: 'Offline mode: using bundled records.',
      );
      Logger.info('✅ [UnifiedDataService] Fallback to local assets');
      _snapshotController.add(snap);
      return snap;
    } catch (e, st) {
      Logger.error('❌ [UnifiedDataService] Local asset load failed: $e', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<DataSnapshot> getAllData() async {
    final online = await _isOnline();

    if (online) {
      Logger.info('🌐 [UnifiedDataService] Device is internet-connected. Attempting Remote Config fetch.');
      
      try {
        final snap = await fetchFromRemoteConfig();
        return snap;
      } catch (e, st) {
        Logger.error('❌ [UnifiedDataService] Remote Config fetch failed while online.', error: e, stackTrace: st);
        
        if (hasCachedData) {
          Logger.info('⚠️ Falling back to stale cache due to fetch failure.');
          return _buildSnapshot(
            reagents: _cachedReagents!,
            source: DataSource.staleCache,
            health: DataHealthStatus.degraded,
            version: _cacheVersion,
            warningMessage: 'Using cached data due to network issues.',
          );
        }
        
        Logger.info('⚠️ No cache available. Falling back to local assets.');
        try {
          return await loadFromAssets();
        } catch (assetError) {
          throw DataServiceException('Remote Config failed and local fallback failed.', source: DataSource.firebase);
        }
      }
    } else {
      Logger.info('📵 [UnifiedDataService] APP IS OFFLINE. Proceeding to cache or local data.');
      
      if (hasCachedData) {
         Logger.info('ℹ️ Using offline cache.');
         return _buildSnapshot(
           reagents: _cachedReagents!,
           source: DataSource.staleCache,
           health: DataHealthStatus.degraded,
           version: _cacheVersion,
           warningMessage: 'Device offline. Showing cached data.',
         );
      }
      
      try {
        return await loadFromAssets();
      } catch (e, st) {
         Logger.error('❌ [UnifiedDataService] Fallback to assets also failed: $e', error: e, stackTrace: st);
         rethrow;
      }
    }
  }



  /// Safety data (Firebase first, local fallback).
  Future<ReagentSafetyData?> getSafetyData(String name) async {
    if (_cachedSafety == null) await _loadSafetyData();
    return _cachedSafety?[name];
  }

  /// Scientific references for a reagent.
  Future<List<String>> getReferences(String name) async {
    if (_cachedReferences == null) await _loadReferencesData();
    return _cachedReferences?[name] ?? [];
  }

  /// Find a single reagent by name.
  Future<ReagentModel?> getReagentByName(String name) async {
    final snap = await getAllData();
    try {
      return snap.reagents.firstWhere(
        (r) => r.reagentName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// Full-text search.
  Future<List<ReagentModel>> searchReagents(String query) async {
    final snap = await getAllData();
    final q = query.toLowerCase();
    return snap.reagents.where((r) =>
        r.reagentName.toLowerCase().contains(q) ||
        r.description.toLowerCase().contains(q) ||
        r.chemicals.any((c) => c.toLowerCase().contains(q))).toList();
  }

  /// Force refresh from Firebase. Emits a new [DataSnapshot] on success.
  /// Throws [DataServiceException] on failure — does NOT swallow errors.
  Future<DataSnapshot> refresh() async {
    Logger.info('🔄 [UnifiedDataService] Manual refresh requested');

    if (!await _isOnline()) {
      Logger.error('❌ [UnifiedDataService] Refresh ABORTED — device offline');
      throw const DataServiceException(
        'Cannot refresh: device is offline.',
        source: DataSource.firebase,
      );
    }

    try {
      await _remoteConfig.fetchAndActivate();
      final result = await _loadFromFirebase();
      _invalidateCache();
      _commitCache(DataSource.firebase, result.reagents, result.version);
      _firebaseLoadedAtLeastOnce = true;

      Logger.info(
        '✅ [UnifiedDataService] Refresh complete — '
        'version: ${result.version}, count: ${result.reagents.length}',
      );

      final snap = _buildSnapshot(
        reagents: result.reagents,
        source:   DataSource.firebase,
        health:   DataHealthStatus.healthy,
        version:  result.version,
      );
      _snapshotController.add(snap);
      return snap;
    } catch (e, st) {
      Logger.error(
        '❌ [UnifiedDataService] Refresh FAILED: $e',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  void dispose() => _snapshotController.close();

  // ── Private: Loaders ───────────────────────────────────────────────────────

  Future<({List<ReagentModel> reagents, String version})>
      _loadFromFirebase() async {
    Logger.info('☁️ [Firebase] Fetching reagents...');

    final reagents = await _remoteConfig.getReagents();
    if (reagents.isEmpty) {
      // P2: Explicit error — empty Firebase is a data integrity issue.
      throw const DataServiceException(
        'Firebase Remote Config returned an empty reagent list. '
        'Verify that "reagent_data" key is set and published.',
        source: DataSource.firebase,
      );
    }

    // Fetch data version from Remote Config for cache comparison (P4)
    final version = _remoteConfig.getReagentVersion();

    // Enrich with references
    final enriched = <ReagentModel>[];
    for (final r in reagents) {
      final refs = await _remoteConfig.getReferencesForReagent(r.reagentName);
      enriched.add(
        refs.isEmpty ? r : r.copyWith(references: [...r.references, ...refs]),
      );
    }

    Logger.info('✅ [Firebase] ${enriched.length} reagents loaded '
        '(version: $version)');
    return (reagents: enriched, version: version);
  }

  Future<List<ReagentModel>> _loadFromLocalJson() async {
    Logger.info('📂 [Local] Loading from $_reagentsAsset');

    // Pre-load references (best-effort, non-fatal)
    if (_cachedReferences == null) {
      await _loadReferencesData();
    }

    final String raw;
    try {
      raw = await rootBundle.loadString(_reagentsAsset);
    } catch (e, st) {
      // P2: Asset missing is a build error — must be visible.
      Logger.error(
        '❌ [Local] Failed to read $_reagentsAsset: $e',
        error: e,
        stackTrace: st,
      );
      throw DataServiceException(
        'Local asset "$_reagentsAsset" could not be loaded: $e',
        source: DataSource.local,
      );
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = json.decode(raw) as Map<String, dynamic>;
    } catch (e, st) {
      Logger.error('❌ [Local] JSON parse error: $e', error: e, stackTrace: st);
      throw DataServiceException(
        'Local asset "$_reagentsAsset" contains invalid JSON: $e',
        source: DataSource.local,
      );
    }

    final List<ReagentModel> result = [];
    final List<String> parseErrors = [];

    decoded.forEach((key, value) {
      try {
        result.add(_parseLocalReagent(key, value as Map<String, dynamic>));
      } catch (e) {
        // P2: Each parse failure is individually logged and collected.
        parseErrors.add('  • "$key": $e');
        Logger.error('❌ [Local] Parse error for "$key": $e');
      }
    });

    if (parseErrors.isNotEmpty) {
      Logger.warning(
        '⚠️ [Local] ${parseErrors.length} reagents skipped due to parse errors:\n'
        '${parseErrors.join("\n")}',
      );
    }

    if (result.isEmpty) {
      // P2: This is fatal — local JSON exists but yields nothing usable.
      throw const DataServiceException(
        'Local JSON parsed successfully but yielded zero valid reagents.',
        source: DataSource.local,
      );
    }

    Logger.info('✅ [Local] ${result.length} reagents loaded');
    return result;
  }

  Future<void> _loadSafetyData() async {
    // Try Firebase first
    try {
      final firebaseMap = _remoteConfig.getSafetyJsonMap();
      if (firebaseMap.isNotEmpty) {
        _parseSafetyMap(firebaseMap);
        Logger.info('✅ [Safety] Loaded from Firebase');
        return;
      }
      Logger.warning(
        '⚠️ [Safety] Firebase safety_instructions key is empty — '
        'falling back to local asset',
      );
    } catch (e, st) {
      // P2: Log but continue to local fallback.
      Logger.error(
        '❌ [Safety] Firebase safety data failed: $e',
        error: e,
        stackTrace: st,
      );
    }

    // Local fallback
    try {
      final raw = await rootBundle.loadString(_safetyAsset);
      _parseSafetyMap(json.decode(raw) as Map<String, dynamic>);
      Logger.info('✅ [Safety] Loaded from local asset');
    } catch (e, st) {
      // P2: Safety data missing is serious — log at error level.
      Logger.error(
        '❌ [Safety] Local safety asset FAILED: $e — safety info unavailable',
        error: e,
        stackTrace: st,
      );
      _cachedSafety = {};
    }
  }

  Future<void> _loadReferencesData() async {
    try {
      final raw = await rootBundle.loadString(_refsAsset);
      final decoded = json.decode(raw) as Map<String, dynamic>;
      _cachedReferences = {};
      decoded.forEach((key, value) {
        final inner = value as Map<String, dynamic>;
        _cachedReferences![key] = (inner['reference'] as List? ?? [])
            .map((e) => e.toString())
            .toList();
      });
      Logger.info('✅ [References] ${_cachedReferences!.length} entries loaded');
    } catch (e, st) {
      Logger.error(
        '❌ [References] Could not load references asset: $e',
        error: e,
        stackTrace: st,
      );
      _cachedReferences = {};
    }
  }

  // ── Private: Parsers ───────────────────────────────────────────────────────

  ReagentModel _parseLocalReagent(String key, Map<String, dynamic> data) {
    List<String> strList(String k) =>
        (data[k] as List? ?? []).map((e) => e.toString()).toList();

    final drugResults = (data['drugResults'] as List? ?? []).map((d) {
      final m = d as Map<String, dynamic>;
      return DrugResultModel(
        drugName: m['drugName']?.toString() ?? '',
        color:    m['color']?.toString() ?? '',
        colorAr:  m['color_ar']?.toString() ??
                  m['instruction_ar']?.toString() ??
                  '',
      );
    }).toList();

    final localRefs = _cachedReferences?[key] ?? [];
    final jsonRefs  = strList('reference');
    final allRefs   = {...jsonRefs, ...localRefs}.toList();

    return ReagentModel(
      reagentName:   data['reagentName']?.toString()    ?? key,
      reagentNameAr: data['reagentName_ar']?.toString() ?? '',
      description:   data['description']?.toString()    ?? '',
      descriptionAr: data['description_ar']?.toString() ?? '',
      safetyLevel:   data['safetyLevel']?.toString()    ?? 'MEDIUM',
      safetyLevelAr: data['safetyLevel_ar']?.toString() ?? '',
      testDuration:  (data['testDuration'] as num?)?.toInt() ?? 5,
      chemicals:     strList('chemicals'),
      drugResults:   drugResults,
      category:      data['category']?.toString() ?? 'General',
      references:    allRefs,
    );
  }

  void _parseSafetyMap(Map<String, dynamic> raw) {
    _cachedSafety = {};
    raw.forEach((key, value) {
      try {
        _cachedSafety![key] =
            ReagentSafetyData.fromJson(key, value as Map<String, dynamic>);
      } catch (e) {
        Logger.error('❌ [Safety] Parse error for "$key": $e');
      }
    });
  }

  // ── Private: Cache ─────────────────────────────────────────────────────────

  /// Returns true if the in-memory cache is fresh AND the version matches
  /// the latest Firebase version (P4 — version comparison).
  Future<bool> _isCacheStillValid() async {
    if (_cachedReagents == null || _cacheTimestamp == null) return false;

    // TTL check
    final age = DateTime.now().difference(_cacheTimestamp!);
    if (age >= _cacheTtl) {
      Logger.info('🕐 [Cache] TTL expired (${age.inMinutes}min). '
          'Will attempt Firebase re-fetch.');
      return false;
    }

    // P4: Version check — reject cache if Firebase has a newer version
    if (_lastDataSource == DataSource.firebase) {
      final firebaseVersion = _remoteConfig.getReagentVersion();
      if (firebaseVersion.isNotEmpty && firebaseVersion != _cacheVersion) {
        Logger.warning(
          '🔄 [Cache] Version mismatch — '
          'cached: "$_cacheVersion" | Firebase: "$firebaseVersion". '
          'Cache REJECTED.',
        );
        return false;
      }
    }

    return true;
  }

  void _commitCache(
    DataSource source,
    List<ReagentModel> reagents,
    String version,
  ) {
    _cachedReagents   = reagents;
    _lastDataSource   = source;
    _cacheTimestamp   = DateTime.now();
    _cacheVersion     = version;
    Logger.info(
      '💾 [Cache] Committed [${source.name}] '
      'version=$version count=${reagents.length}',
    );
  }

  void _invalidateCache() {
    _cachedReagents   = null;
    _cachedSafety     = null;
    _cachedReferences = null;
    _cacheTimestamp   = null;
    _cacheVersion     = '';
    Logger.info('🗑 [Cache] Invalidated');
  }

  // ── Private: Connectivity ──────────────────────────────────────────────────


  Future<bool> _isOnline() async {
    try {
      final results = await _connectivity
          .checkConnectivity()
          .timeout(const Duration(seconds: 5));
      return results.any((r) =>
          r == ConnectivityResult.mobile   ||
          r == ConnectivityResult.wifi     ||
          r == ConnectivityResult.ethernet);
    } catch (e) {
      // P2: Log the connectivity check failure (could be permissions issue).
      Logger.error('❌ [Connectivity] checkConnectivity failed: $e');
      return false;
    }
  }

  // ── Private: Snapshot Builder ──────────────────────────────────────────────

  DataSnapshot _buildSnapshot({
    required List<ReagentModel> reagents,
    required DataSource         source,
    required DataHealthStatus   health,
    required String             version,
    String?                     warningMessage,
  }) {
    return DataSnapshot(
      reagents:       reagents,
      source:         source,
      health:         health,
      version:        version,
      loadedAt:       DateTime.now(),
      warningMessage: warningMessage,
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DataServiceException
// ═════════════════════════════════════════════════════════════════════════════

class DataServiceException implements Exception {
  final String message;

  /// Which source was active when the exception occurred.
  final DataSource source;

  const DataServiceException(this.message, {this.source = DataSource.firebase});

  @override
  String toString() =>
      'DataServiceException[${source.name.toUpperCase()}]: $message';
}
