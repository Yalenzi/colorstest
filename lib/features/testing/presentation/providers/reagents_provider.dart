import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../data/models/reagent_model.dart';

final remoteConfigProvider = Provider<FirebaseRemoteConfig>((ref) {
  return FirebaseRemoteConfig.instance;
});

final reagentsProvider = FutureProvider<List<ReagentModel>>((ref) async {
  final remoteConfig = ref.read(remoteConfigProvider);
  
  await remoteConfig.setConfigSettings(RemoteConfigSettings(
    fetchTimeout: const Duration(seconds: 15),
    minimumFetchInterval: kDebugMode ? Duration.zero : const Duration(hours: 1),
  ));
  
  // Set minimal fallback defaults
  await remoteConfig.setDefaults(const {
    'reagents_data_json': '{}', 
    'safety_instructions': '{}',
    'reference_list': '{}'
  });
  
  try {
    await remoteConfig.fetchAndActivate();
  } catch (_) {
    // Silently continue if fetch fails and use cache or defaults
  }

  final reagentsDataStr = remoteConfig.getString('reagents_data_json');
  final safetyStr = remoteConfig.getString('safety_instructions');
  final referenceStr = remoteConfig.getString('reference_list');

  Map<String, dynamic> reagentsJson = {};
  Map<String, dynamic> safetyJson = {};
  Map<String, dynamic> referenceJson = {};

  try {
    if (reagentsDataStr.isNotEmpty && reagentsDataStr != '{}') {
      reagentsJson = jsonDecode(reagentsDataStr);
    }
  } catch (_) {}

  try {
    if (safetyStr.isNotEmpty && safetyStr != '{}') {
      safetyJson = jsonDecode(safetyStr);
    }
  } catch (_) {}

  try {
    if (referenceStr.isNotEmpty && referenceStr != '{}') {
      referenceJson = jsonDecode(referenceStr);
    }
  } catch (_) {}
  
  List<String> reagentsList = reagentsJson.keys.toList();

  // Fallbacks if data fails
  if (reagentsList.isEmpty) {
    reagentsList = ["Marquis", "Mecke", "Mandelin", "Ehrlich", "Simon's"];
  }

  List<ReagentModel> models = [];
  
  for (final rId in reagentsList) {
    final data = (reagentsJson[rId] as Map<String, dynamic>?) ?? _getFallbackData(rId);
    final safety = (safetyJson[rId] as Map<String, dynamic>?) ?? {};

    models.add(ReagentModel.fromJson(rId, data, safety, referenceJson));
  }

  return models;
});

// Helper for local fallback data when Firebase is empty / disconnected
Map<String, dynamic> _getFallbackData(String id) {
  return {
    'reagentName': id,
    'description': 'Fallback generic reagent test.',
    'description_ar': 'اختبار كاشف عام مؤقت',
    'safetyLevel': 'MEDIUM',
    'testDuration': 1,
    'instructions': ['Add a small sample', 'Add 1 drop of reagent', 'Observe color change'],
    'equipment': ['Gloves', 'Safety glasses'],
    'specificHazards': ['Corrosive'],
    'drugResults': [
      {'drugName': 'MDMA', 'color': 'black', 'color_ar': 'أسود'},
      {'drugName': 'Amphetamine', 'color': 'orange', 'color_ar': 'برتقالي'}
    ]
  };
}
