import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:reagentkit/features/reagent_testing/data/services/remote_config_service.dart';
import 'package:flutter/widgets.dart';

/// A Fake implementation of FirebaseRemoteConfig for testing without native dependencies.
class FakeFirebaseRemoteConfig extends Fake implements FirebaseRemoteConfig {
  final Map<String, String> _mockValues = {
    'reagents_data': json.encode({
      "Marquis Test": {
        "description": "Standard alkaloid test",
        "description_ar": "اختبار القلويدات القياسي",
        "safetyLevel": "High",
        "safetyLevel_ar": "عالي",
        "testDuration": 30,
        "chemicals": ["Formaldehyde", "Sulfuric acid"],
        "drugResults": [
          {
            "drugName": "MDMA",
            "color": "#Purple",
            "color_ar": "أرجواني"
          }
        ]
      }
    }),
    'reagent_version': '1.0.0',
  };

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {}

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}

  @override
  Future<bool> fetchAndActivate() async => true;

  @override
  Future<bool> activate() async => true;

  @override
  String getString(String key) => _mockValues[key] ?? '';

  @override
  Stream<RemoteConfigUpdate> get onConfigUpdated => const Stream.empty();
}

void main() {
  group('RemoteConfigService Smoke Test', () {
    late RemoteConfigService rcService;
    late FakeFirebaseRemoteConfig fakeRC;

    setUp(() {
      fakeRC = FakeFirebaseRemoteConfig();
      rcService = RemoteConfigService(remoteConfig: fakeRC);
    });

    test('Service initializes and fetches mock data', () async {
      debugPrint('🚀 Starting Remote Config smoke test (Mocked)...');

      // Note: We don't call Firebase.initializeApp() here because we are injecting a fake.
      await rcService.initialize();
      
      final reagents = await rcService.getReagents();
      
      debugPrint('TOTAL REAGENTS LOADED: ${reagents.length}');
      for (var r in reagents) {
        debugPrint(' - Loaded Reagent: ${r.reagentName}');
      }

      expect(reagents, isNotEmpty, reason: 'Should have loaded at least one reagent from mock data');
      expect(reagents.first.reagentName, equals('Marquis Test'));
      expect(rcService.getReagentVersion(), equals('1.0.0'));
    });
  });
}
