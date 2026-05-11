import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../models/reagent_model.dart';
import '../../../../core/utils/logger.dart';

// ═════════════════════════════════════════════════════════════════════════════
// RemoteConfigService — Production-Grade
//
// Firebase Remote Config key contract:
//   • reagents_data         — JSON object: { "Marquis Test": { … }, … }
//   • safety_instructions   — JSON object: { "Marquis Test": { … }, … }
//   • references_data       — JSON object: { "Marquis Test": { "reference": […] }, … }
//   • reagent_version       — String: semantic version ("1.2.0")
//   • gemini_api_key        — String: Gemini AI key (blank = use env var)
//
// ALL keys default to empty JSON so that the app never crashes if Remote
// Config has not been published yet — it falls through to local assets.
// ═════════════════════════════════════════════════════════════════════════════

class RemoteConfigService {
  // ── Key constants ──────────────────────────────────────────────────────────
  static const String _reagentsDataKey      = 'reagents_data';
  static const String _safetyKey            = 'safety_instructions';
  static const String _referencesDataKey    = 'references_data';
  static const String _reagentVersionKey    = 'reagent_version';
  static const String _geminiApiKeyKey      = 'gemini_api_key';

  final FirebaseRemoteConfig _remoteConfig;

  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout:           const Duration(minutes: 1),
          minimumFetchInterval:   const Duration(hours: 1),
        ),
      );

      // Defaults ensure the app boots cleanly with no published config.
      await _remoteConfig.setDefaults({
        _reagentsDataKey:   '{}',
        _safetyKey:         '{}',
        _referencesDataKey: '{}',
        _reagentVersionKey: '1.0.0',
        _geminiApiKeyKey:   '',
      });

      await fetchAndActivate();
      Logger.info('✅ [RemoteConfig] Initialized successfully');
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] Initialization failed: $e',
          error: e, stackTrace: st);
      rethrow;
    }
  }

  // ── Fetch ──────────────────────────────────────────────────────────────────

  Future<bool> fetchAndActivate() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      if (updated) {
        Logger.info('🔄 [RemoteConfig] New values activated');
      }
      return updated;
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] fetchAndActivate failed: $e',
          error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool> activate() async {
    try {
      return await _remoteConfig.activate();
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] activate failed: $e',
          error: e, stackTrace: st);
      return false;
    }
  }

  // ── Reagent Data ───────────────────────────────────────────────────────────

  /// Returns true only when `reagents_data` has non-empty content.
  bool hasReagentData() {
    final raw = _remoteConfig.getString(_reagentsDataKey);
    return raw.isNotEmpty && raw != '{}';
  }

  /// Parse and return all reagents from `reagents_data`.
  ///
  /// The value must be a JSON object keyed by test name, e.g.:
  ///   { "Marquis Test": { "reagentName": "Marquis Test", … }, … }
  ///
  /// Returns an empty list (not an error) when the key is unpublished,
  /// letting [UnifiedDataService] fall back to local JSON.
  Future<List<ReagentModel>> getReagents() async {
    final raw = _remoteConfig.getString(_reagentsDataKey);

    if (raw.isEmpty || raw == '{}') {
      Logger.info('⚠️ [RemoteConfig] reagents_data is empty — using local fallback');
      return [];
    }

    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      final List<ReagentModel> reagents = [];
      final List<String> parseErrors = [];

      decoded.forEach((key, value) {
        try {
          if (value is! Map<String, dynamic>) {
            throw FormatException('Expected object for "$key"');
          }
          // Inject the key as reagentName when the field is absent
          final Map<String, dynamic> entry = {
            'reagentName': key,
            ...value,
          };
          reagents.add(ReagentModel.fromJson(entry));
          Logger.info('✅ [RemoteConfig] Parsed reagent: $key');
        } catch (e) {
          parseErrors.add('  • "$key": $e');
          Logger.error('❌ [RemoteConfig] Parse error for "$key": $e');
        }
      });

      if (parseErrors.isNotEmpty) {
        Logger.warning(
          '⚠️ [RemoteConfig] ${parseErrors.length} reagents skipped:\n'
          '${parseErrors.join("\n")}',
        );
      }

      Logger.info('📊 [RemoteConfig] Loaded ${reagents.length} reagents');
      return reagents;
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] Failed to decode reagents_data: $e',
          error: e, stackTrace: st);
      return [];
    }
  }

  /// Get a single reagent by name.
  Future<ReagentModel?> getReagentByName(String name) async {
    final all = await getReagents();
    try {
      return all.firstWhere(
        (r) => r.reagentName.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      Logger.info('⚠️ [RemoteConfig] Reagent "$name" not found');
      return null;
    }
  }

  // ── References Data ────────────────────────────────────────────────────────

  /// Returns scientific references for [reagentName] from Remote Config.
  ///
  /// The `references_data` key should hold:
  ///   { "Marquis Test": { "reference": ["…", "…"] }, … }
  Future<List<String>> getReferencesForReagent(String reagentName) async {
    final raw = _remoteConfig.getString(_referencesDataKey);
    if (raw.isEmpty || raw == '{}') return [];

    try {
      final Map<String, dynamic> decoded = json.decode(raw);
      final entry = decoded[reagentName];
      if (entry == null) return [];

      final refs = (entry as Map<String, dynamic>)['reference'];
      if (refs == null) return [];
      return List<String>.from(refs as List);
    } catch (e, st) {
      Logger.error(
        '❌ [RemoteConfig] getReferencesForReagent("$reagentName") failed: $e',
        error: e,
        stackTrace: st,
      );
      return [];
    }
  }

  // ── Safety Data ────────────────────────────────────────────────────────────

  /// Returns the raw safety JSON map from Remote Config, or `{}` on error.
  ///
  /// Used by [UnifiedDataService._loadSafetyData()] to parse safety data
  /// without coupling it to [SafetyInstructionsModel].
  Map<String, dynamic> getSafetyJsonMap() {
    final raw = _remoteConfig.getString(_safetyKey);
    if (raw.isEmpty || raw == '{}') return {};

    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (e, st) {
      Logger.error('❌ [RemoteConfig] getSafetyJsonMap failed: $e',
          error: e, stackTrace: st);
      return {};
    }
  }

  bool hasSafetyInstructions() {
    final raw = _remoteConfig.getString(_safetyKey);
    return raw.isNotEmpty && raw != '{}';
  }

  // ── Version ────────────────────────────────────────────────────────────────

  String getReagentVersion() => _remoteConfig.getString(_reagentVersionKey);

  // ── Gemini API Key ─────────────────────────────────────────────────────────

  String getGeminiApiKey() {
    final key = _remoteConfig.getString(_geminiApiKeyKey);
    if (key.isNotEmpty) {
      Logger.info('🔑 [RemoteConfig] Gemini API key loaded');
    } else {
      Logger.info('⚠️ [RemoteConfig] No Gemini API key in Remote Config');
    }
    return key;
  }

  bool hasGeminiApiKey() =>
      _remoteConfig.getString(_geminiApiKeyKey).isNotEmpty;

  /// Returns the Gemini key from Remote Config, falling back to the
  /// compile-time GEMINI_API_KEY environment variable.
  String getGeminiApiKeyWithFallback() {
    final remote = getGeminiApiKey();
    if (remote.isNotEmpty) return remote;

    const env = String.fromEnvironment('GEMINI_API_KEY');
    if (env.isNotEmpty) {
      Logger.info('🔑 [RemoteConfig] Using Gemini key from env variable');
      return env;
    }

    Logger.error('❌ [RemoteConfig] No Gemini API key found');
    return '';
  }

  // ── Real-time updates ──────────────────────────────────────────────────────

  Stream<RemoteConfigUpdate> onConfigUpdated() =>
      _remoteConfig.onConfigUpdated;
}
