import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reagentkit/l10n/app_localizations.dart';
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
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
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

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6), // Professional blue
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFF1E293B),
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFF1E293B), size: 24),
        systemOverlayStyle: null, // Use default system overlay
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6), // Professional blue
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        foregroundColor: Color(0xFFE2E8F0),
        centerTitle: true,
        iconTheme: IconThemeData(color: Color(0xFFE2E8F0), size: 24),
        systemOverlayStyle: null, // Use default system overlay
      ),
      scaffoldBackgroundColor: const Color(0xFF0F172A),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: const Color(0xFF1E293B),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1E293B),
      ),
    );
  }
}
