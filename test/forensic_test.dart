import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reagent_colors_test/features/reagent_testing/data/services/remote_config_service.dart';
import 'package:reagent_colors_test/firebase_options.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Forensic Debug Run', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    print('🚀 Starting Forensic Test...');
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase Initialized');
      
      final rcService = RemoteConfigService();
      await rcService.initialize();
      
      print('--- FINAL DATA FETCH ---');
      final reagents = await rcService.getReagents();
      print('TOTAL REAGENTS LOADED: ${reagents.length}');
      
    } catch (e) {
      print('❌ Test Error: $e');
    }
  });
}
