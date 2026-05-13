import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reagentkit/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/config/get_it_config.dart';
import 'core/navigation/auth_wrapper.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'features/settings/presentation/states/settings_state.dart';
import 'features/reagent_testing/data/services/remote_config_service.dart';
import 'core/utils/logger.dart';
import 'firebase_options.dart';
import 'core/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    Logger.info('Firebase initialization error: $e');
  }

  try {
    final remoteConfigService = RemoteConfigService();
    await remoteConfigService.initialize();
    Logger.info('✅ Remote Config initialized successfully in main()');
  } catch (e) {
    Logger.info('⚠️ Remote Config initialization failed in main(): $e');
  }

  await configureDependencies();

  runApp(const ProviderScope(child: ReagentTestingApp()));
}

class ReagentTestingApp extends ConsumerWidget {
  const ReagentTestingApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final settingsState = ref.watch(settingsControllerProvider);

    // Get theme mode from settings
    ThemeMode themeMode = ThemeMode.system;
    if (settingsState is SettingsLoaded) {
      themeMode = settingsState.settings.themeMode;
    }

    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'ReagentKit',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: '/',
      routes: {'/': (context) => const AuthWrapper()},
      onGenerateRoute: (settings) {
        // Handle dynamic routes here if needed
        return MaterialPageRoute(
          builder: (context) => const AuthWrapper(),
          settings: settings,
        );
      },

      debugShowCheckedModeBanner: false,
    );
  }
}
