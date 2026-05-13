import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';
import '../states/auth_state.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../../settings/presentation/providers/theme_provider.dart';
import '../../../../l10n/app_localizations.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _isLoginMode = true;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  // Password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
      _formKey.currentState?.reset();
      _emailController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _usernameController.clear();
    });
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final authController = ref.read(authControllerProvider.notifier);

    if (_isLoginMode) {
      authController.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      authController.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );
    }
  }

  void _signInWithGoogle() {
    final authController = ref.read(authControllerProvider.notifier);
    authController.signInWithGoogle();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(_isLoginMode ? l10n.labAccess : l10n.joinLaboratory),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggleTheme(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E1B4B),
                  ]
                : [
                    const Color(0xFFE0E7FF),
                    const Color(0xFFF3E8FF),
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Animated Language Switcher
                  Align(
                    alignment: Alignment.center,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: () {
                            final newLanguage = locale.languageCode == 'en' ? 'ar' : 'en';
                            ref.read(settingsControllerProvider.notifier).updateLanguage(newLanguage);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.language, color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  child: Text(
                                    locale.languageCode == 'en' ? 'العربية' : 'English',
                                    key: ValueKey<String>(locale.languageCode),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildGlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            _isLoginMode ? Icons.science : Icons.person_add,
                            size: 64,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isLoginMode ? l10n.welcomeBack : l10n.joinOurLab,
                            style: theme.textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLoginMode ? l10n.accessYourLab : l10n.startYourJourney,
                            style: theme.textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildAuthForm(authState, l10n),
                          const SizedBox(height: 24),
                          _buildGoogleSignInButton(authState, l10n),
                          const SizedBox(height: 16),
                          _buildToggleAuthModeButton(l10n),
                        ],
                      ),
                    ),
                  ),
                  if (authState is AuthError) ...[
                    const SizedBox(height: 20),
                    _buildErrorMessage(authState.message),
                  ],
                  if (authState is AuthSuccess) ...[
                    const SizedBox(height: 20),
                    _buildSuccessMessage(authState.message),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildAuthForm(AuthState authState, AppLocalizations l10n) {
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_isLoginMode) ...[
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: l10n.username,
                prefixIcon: const Icon(Icons.person),
              ),
              enabled: !isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterUsername;
                }
                if (value.trim().length < 3) {
                  return l10n.usernameMinLength;
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                  return l10n.usernameInvalidChars;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: l10n.email,
              prefixIcon: const Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.pleaseEnterEmail;
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return l10n.pleaseEnterValidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: l10n.password,
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
            ),
            obscureText: !_isPasswordVisible,
            enabled: !isLoading,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return l10n.pleaseEnterPassword;
              }
              if (!_isLoginMode && value.length < 6) {
                return l10n.passwordMinLength;
              }
              return null;
            },
          ),

          if (!_isLoginMode) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: !_isConfirmPasswordVisible,
              enabled: !isLoading,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.pleaseConfirmPassword;
                }
                if (value != _passwordController.text) {
                  return l10n.passwordsDoNotMatch;
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: isLoading ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Text(
                    _isLoginMode ? l10n.signIn : l10n.signUp,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleSignInButton(AuthState authState, AppLocalizations l10n) {
    final isLoading = authState is AuthLoading;
    final theme = Theme.of(context);

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: theme.dividerColor)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.orContinueWith,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
            Expanded(child: Divider(color: theme.dividerColor)),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: isLoading ? null : _signInWithGoogle,
          icon: Image.asset(
            'assets/images/google_logo.png',
            height: 24,
            width: 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.g_mobiledata, size: 28, color: theme.colorScheme.onSurface);
            },
          ),
          label: Text(
            _isLoginMode ? l10n.signInWithGoogle : l10n.signUpWithGoogle,
            style: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 24,
            ),
            backgroundColor: theme.colorScheme.surface,
            side: BorderSide(
              color: theme.dividerColor,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleAuthModeButton(AppLocalizations l10n) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: _toggleAuthMode,
      style: TextButton.styleFrom(
        foregroundColor: theme.colorScheme.primary,
      ),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium,
          children: [
            TextSpan(
              text: _isLoginMode
                  ? '${l10n.dontHaveAccount} '
                  : '${l10n.alreadyHaveAccount} ',
            ),
            TextSpan(
              text: _isLoginMode ? l10n.signUp : l10n.signIn,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.error),
            onPressed: () {
              ref.read(authControllerProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String message) {
    final theme = Theme.of(context);
    final successColor = const Color(0xFF10B981); // Emerald Green
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: successColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: successColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: successColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: successColor),
            onPressed: () {
              ref.read(authControllerProvider.notifier).clearError();
            },
          ),
        ],
      ),
    );
  }
}
