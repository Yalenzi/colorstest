import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reagentkit/features/reagent_testing/data/services/remote_config_service.dart';
import 'package:reagentkit/firebase_options.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Remote Config smoke test', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🚀 Starting Remote Config smoke test...');

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ Firebase Initialized');

      final rcService = RemoteConfigService();
      await rcService.initialize();

      debugPrint('--- FINAL DATA FETCH ---');
      final reagents = await rcService.getReagents();
      debugPrint('TOTAL REAGENTS LOADED: ${reagents.length}');
    } catch (e) {
      debugPrint('❌ Test Error: $e');
    }
  });
}
