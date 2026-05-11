import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/safety_instructions_model.dart';
import 'remote_config_service.dart';
import '../../../../core/utils/logger.dart';

const _kSafetyAsset = 'assets/data/safety.json';

class SafetyInstructionsService {
  final RemoteConfigService _remoteConfigService;
  Map<String, SafetyInstructionsModel>? _cachedSafetyInstructions;

  SafetyInstructionsService({RemoteConfigService? remoteConfigService})
    : _remoteConfigService = remoteConfigService ?? RemoteConfigService();

  /// Initialize the service (sets up Remote Config)
  Future<void> initialize() async {
    try {
      await _remoteConfigService.initialize();
      Logger.info('✅ SafetyInstructionsService initialized with Remote Config');
    } catch (e) {
      Logger.info(
        '⚠️ Remote Config initialization failed for safety instructions: $e',
      );
    }
  }

  /// Create default safety instructions for any reagent
  SafetyInstructionsModel _createDefaultSafetyInstructions(String reagentName) {
    return SafetyInstructionsModel(
      reagentName: reagentName,
      equipment: const [
        "Chemical-resistant safety goggles",
        "Chemical-resistant gloves (nitrile or neoprene)",
        "Lab coat with long sleeves",
        "Closed-toe chemical-resistant shoes",
        "Respirator when necessary",
      ],
      equipmentAr: const [
        "ضع نظارات أمان مقاومة للمواد الكيميائية",
        "قفازات مقاومة للمواد الكيميائية (نيتريل أو نيوبرين)",
        "معطف مختبر بأكمام طويلة",
        "أحذية مغلقة مقاومة للمواد الكيميائية",
        "جهاز تنفس عند الضرورة",
      ],
      handlingProcedures: const [
        "Work under fume hood mandatory",
        "Wear acid-resistant gloves",
        "Use safety goggles and face shield",
        "Keep sodium bicarbonate handy for neutralization",
        "Use only small drops",
        "Never mix reagent directly with water",
      ],
      handlingProceduresAr: const [
        "العمل تحت غطاء الدخان إجباري",
        "ارتداء قفازات مقاومة للأحماض",
        "استخدام نظارات الأمان وواقي الوجه",
        "الاحتفاظ ببيكربونات الصوديوم للتحييد",
        "استخدام قطرات صغيرة فقط",
        "عدم خلط الكاشف مباشرة مع الماء",
      ],
      specificHazards: const [
        "Highly corrosive - contains concentrated sulfuric acid",
        "Causes severe chemical burns",
        "Dangerous fumes - formaldehyde",
        "Exothermic reaction",
      ],
      specificHazardsAr: const [
        "شديد التآكل - يحتوي على حمض الكبريتيك المركز",
        "يسبب حروق كيميائية شديدة",
        "أبخرة خطيرة - الفورمالديهايد",
        "تفاعل طارد للحرارة",
      ],
      storage: const [
        "Store in cool, dry place",
        "Away from flammable materials",
        "In dedicated acid storage cabinet",
        "Label with clear warning",
      ],
      storageAr: const [
        "التخزين في مكان بارد وجاف",
        "بعيداً عن المواد القابلة للاشتعال",
        "في خزانة تخزين أحماض مخصصة",
        "وضع ملصق تحذيري واضح",
      ],
      instructions: const [
        "Prepare a small sample of the substance to test",
        "Add 1-2 drops of Marquis reagent to the sample",
        "Observe the color change for 1 minutes",
        "Compare the resulting color with expected results below",
        "Record your observations and dispose of materials safely",
      ],
      instructionsAr: const [
        "تحضير عينة صغيرة من المادة للاختبار",
        "إضافة 1-2 قطرة من كاشف ماركيز إلى العينة",
        "مراقبة تغير اللون لمدة دقيقة واحدة",
        "مقارنة اللون الناتج مع النتائج المتوقعة",
        "تسجيل الملاحظات والتخلص من المواد بأمان",
      ],
    );
  }

  /// Load all safety instructions (Remote Config first, then local fallback)
  Future<Map<String, SafetyInstructionsModel>>
  loadAllSafetyInstructions() async {
    try {
      // Try Remote Config first via getSafetyJsonMap()
      if (_remoteConfigService.hasSafetyInstructions()) {
        Logger.info('📡 Loading safety instructions from Remote Config...');
        final rawMap = _remoteConfigService.getSafetyJsonMap();
        if (rawMap.isNotEmpty) {
          final remoteSafetyInstructions = _parseSafetyJsonMap(rawMap);
          if (remoteSafetyInstructions.isNotEmpty) {
            _cachedSafetyInstructions = remoteSafetyInstructions;
            Logger.info(
              '✅ Loaded ${remoteSafetyInstructions.length} safety instructions from Remote Config',
            );
            return remoteSafetyInstructions;
          }
        }
      }

      // Fallback to local assets/data/safety.json
      Logger.info('📁 Falling back to local safety.json...');
      return await _loadSafetyInstructionsFromAssets();
    } catch (e) {
      Logger.info('❌ Error in loadAllSafetyInstructions: $e');
      return await _loadSafetyInstructionsFromAssets();
    }
  }

  /// Parse a raw safety JSON map (from Remote Config) into model objects.
  Map<String, SafetyInstructionsModel> _parseSafetyJsonMap(
    Map<String, dynamic> rawMap,
  ) {
    final result = <String, SafetyInstructionsModel>{};
    rawMap.forEach((key, value) {
      try {
        result[key] = SafetyInstructionsModel.fromJson(
            key, value as Map<String, dynamic>);
      } catch (e) {
        Logger.error('❌ [Safety] Remote parse error for "$key": $e');
      }
    });
    return result;
  }

  /// Load safety instructions for a specific reagent
  Future<SafetyInstructionsModel?> loadSafetyInstructionsByReagent(
    String reagentName,
  ) async {
    try {
      // Try Remote Config first
      if (_remoteConfigService.hasSafetyInstructions()) {
        final rawMap = _remoteConfigService.getSafetyJsonMap();
        final entry = rawMap[reagentName];
        if (entry != null) {
          final remoteSafety = SafetyInstructionsModel.fromJson(
              reagentName, entry as Map<String, dynamic>);
          Logger.info(
            '✅ Loaded safety instructions for $reagentName from Remote Config',
          );
          return remoteSafety;
        }
      }

      // Fallback to cached data or local assets
      if (_cachedSafetyInstructions != null) {
        final cachedSafety = _cachedSafetyInstructions![reagentName];
        if (cachedSafety != null) return cachedSafety;
      }

      // Load all and return specific one
      final allSafetyInstructions = await loadAllSafetyInstructions();
      final safetyFromAll = allSafetyInstructions[reagentName];
      if (safetyFromAll != null) return safetyFromAll;

      // Final fallback: generic defaults
      Logger.info(
        '⚠️ No safety instructions found for $reagentName, using defaults',
      );
      return _createDefaultSafetyInstructions(reagentName);
    } catch (e) {
      Logger.info('❌ Error loading safety instructions for $reagentName: $e');
      return _createDefaultSafetyInstructions(reagentName);
    }
  }

  /// Get localized equipment list for a reagent
  Future<List<String>> getEquipmentForReagent(
    String reagentName, {
    bool isArabic = false,
  }) async {
    final safety = await loadSafetyInstructionsByReagent(reagentName);
    if (safety == null) {
      // Return default equipment if safety is null (shouldn't happen now)
      final defaultSafety = _createDefaultSafetyInstructions(reagentName);
      return defaultSafety.getEquipment(isArabic);
    }

    return safety.getEquipment(isArabic);
  }

  /// Get localized handling procedures for a reagent
  Future<List<String>> getHandlingProceduresForReagent(
    String reagentName, {
    bool isArabic = false,
  }) async {
    final safety = await loadSafetyInstructionsByReagent(reagentName);
    if (safety == null) {
      // Return default handling procedures if safety is null (shouldn't happen now)
      final defaultSafety = _createDefaultSafetyInstructions(reagentName);
      return defaultSafety.getHandlingProcedures(isArabic);
    }

    return safety.getHandlingProcedures(isArabic);
  }

  /// Get localized specific hazards for a reagent
  Future<List<String>> getSpecificHazardsForReagent(
    String reagentName, {
    bool isArabic = false,
  }) async {
    final safety = await loadSafetyInstructionsByReagent(reagentName);
    if (safety == null) {
      // Return default specific hazards if safety is null (shouldn't happen now)
      final defaultSafety = _createDefaultSafetyInstructions(reagentName);
      return defaultSafety.getSpecificHazards(isArabic);
    }

    return safety.getSpecificHazards(isArabic);
  }

  /// Get localized storage instructions for a reagent
  Future<List<String>> getStorageForReagent(
    String reagentName, {
    bool isArabic = false,
  }) async {
    final safety = await loadSafetyInstructionsByReagent(reagentName);
    if (safety == null) {
      // Return default storage instructions if safety is null (shouldn't happen now)
      final defaultSafety = _createDefaultSafetyInstructions(reagentName);
      return defaultSafety.getStorage(isArabic);
    }

    return safety.getStorage(isArabic);
  }

  /// Get localized test instructions for a reagent
  Future<List<String>> getInstructionsForReagent(
    String reagentName, {
    bool isArabic = false,
  }) async {
    final safety = await loadSafetyInstructionsByReagent(reagentName);
    if (safety == null) {
      // Return default test instructions if safety is null (shouldn't happen now)
      final defaultSafety = _createDefaultSafetyInstructions(reagentName);
      return defaultSafety.getInstructions(isArabic);
    }

    return safety.getInstructions(isArabic);
  }

  /// Load safety instructions from [assets/data/safety.json] (local fallback).
  Future<Map<String, SafetyInstructionsModel>>
  _loadSafetyInstructionsFromAssets() async {
    try {
      final raw = await rootBundle.loadString(_kSafetyAsset);
      final Map<String, dynamic> decoded = json.decode(raw);
      final result = <String, SafetyInstructionsModel>{};

      decoded.forEach((key, value) {
        try {
          final m = value as Map<String, dynamic>;
          result[key] = SafetyInstructionsModel(
            reagentName:          key,
            equipment:            List<String>.from(m['requiredEquipment'] as List? ?? []),
            equipmentAr:          const [],
            handlingProcedures:   List<String>.from(m['handlingProcedures'] as List? ?? []),
            handlingProceduresAr: const [],
            specificHazards:      List<String>.from(m['specificHazards'] as List? ?? []),
            specificHazardsAr:    const [],
            storage:              List<String>.from(m['storageRequirements'] as List? ?? []),
            storageAr:            const [],
            instructions:         const [],
            instructionsAr:       const [],
          );
        } catch (e) {
          Logger.error('❌ [Safety] Parse error for "$key": $e');
        }
      });

      Logger.info('✅ [Safety] Loaded ${result.length} entries from $_kSafetyAsset');
      return result;
    } catch (e, st) {
      Logger.error('❌ [Safety] Could not load $_kSafetyAsset: $e',
          error: e, stackTrace: st);
      return {};
    }
  }

  /// Refresh data from Remote Config
  Future<bool> refreshFromRemoteConfig() async {
    try {
      final updated = await _remoteConfigService.fetchAndActivate();
      if (updated) {
        _cachedSafetyInstructions = null; // Clear cache to force reload
        Logger.info('✅ Safety instructions refreshed from Remote Config');
      }
      return updated;
    } catch (e) {
      Logger.info(
        '❌ Error refreshing safety instructions from Remote Config: $e',
      );
      return false;
    }
  }

  /// Check if using Remote Config data
  bool isUsingRemoteConfig() {
    return _remoteConfigService.hasSafetyInstructions();
  }

  /// Get current data source version
  String getDataVersion() {
    if (isUsingRemoteConfig()) {
      return 'Remote Config v${_remoteConfigService.getReagentVersion()}';
    } else {
      return 'Local Assets v1.0.0';
    }
  }

  /// Listen for real-time Remote Config updates
  Stream<void> onDataUpdated() async* {
    await for (final update in _remoteConfigService.onConfigUpdated()) {
      Logger.info('🔄 Safety instructions updated: ${update.updatedKeys}');
      if (update.updatedKeys.contains('safety_instructions')) {
        // Activate the new config and clear cache
        await _remoteConfigService.activate();
        _cachedSafetyInstructions = null;
        yield null; // Emit update signal
      }
    }
  }

  /// Clear cached data
  void clearCache() {
    _cachedSafetyInstructions = null;
  }
}
