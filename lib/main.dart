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

import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set a custom ErrorWidget to show rendering errors
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        child: Container(
          color: Colors.red,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              details.exceptionAsString() + '\n' + (details.stack?.toString() ?? ''),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      );
    };

    // Initialize Firebase with try/catch to show on screen if it fails
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    } catch (e, stack) {
      runApp(MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.red,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Firebase Init Error:\n$e\n$stack",
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ));
      return;
    }

    // Initialize Remote Config FIRST to ensure API keys are available
    try {
      final remoteConfigService = RemoteConfigService();
      await remoteConfigService.initialize();
      Logger.info('✅ Remote Config initialized successfully in main()');
    } catch (e) {
      Logger.info('⚠️ Remote Config initialization failed in main(): $e');
      // Continue without Remote Config - app will use fallbacks
    }

    // Configure dependencies (now Remote Config is ready)
    await configureDependencies();

    runApp(const ProviderScope(child: ReagentTestingApp()));
  }, (error, stack) {
    // Catch any other uncaught errors and show them
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              "Uncaught App Error:\n$error\n$stack",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    ));
  });
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
      cardTheme: CardThemeData(
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
      cardTheme: CardThemeData(
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
