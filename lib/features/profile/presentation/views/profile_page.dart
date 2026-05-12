import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/states/auth_state.dart';
import '../../../../core/widgets/notification_demo_widget.dart';

import '../../../../l10n/app_localizations.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
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

  void _signOut() {
    final authController = ref.read(authControllerProvider.notifier);
    authController.signOut();
    _clearTextFields();
  }

  void _clearTextFields() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _usernameController.clear();

    // Reset form validation state
    _formKey.currentState?.reset();

    // Reset password visibility states
    setState(() {
      _isPasswordVisible = false;
      _isConfirmPasswordVisible = false;
    });
  }

  void _showPasswordResetDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final resetEmailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.lock_reset, color: Color(0xFF3B82F6), size: 24),
              const SizedBox(width: 12),
              Text(
                l10n.resetPasswordTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.resetPasswordDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                // Security Notice
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.security,
                        size: 16,
                        color: Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reset links expire in 1 hour and can only be used once for security.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: resetEmailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    hintText: l10n.enterEmailToReset,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.pleaseEnterEmail;
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value)) {
                      return l10n.pleaseEnterValidEmail;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                l10n.backToLogin,
                style: TextStyle(
                  color: isLoading ? Colors.grey : const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      final email = resetEmailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.pleaseEnterEmail),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() {
                        isLoading = true;
                      });

                      try {
                        await ref
                            .read(authControllerProvider.notifier)
                            .sendPasswordResetEmail(email);

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.passwordResetEmailSent),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() {
                          isLoading = false;
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(l10n.sendResetEmail),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    // Set context for the auth controller
    WidgetsBinding.instance.addPostFrameCallback((_) {

      // Show top notification for errors and success messages
      if (authState is AuthError) {
        TopNotificationOverlay.show(
          message: authState.message,
          isError: true,
        );
      } else if (authState is AuthSuccess) {
        TopNotificationOverlay.show(
          message: authState.message,
          isError: false,
        );
      }
    });

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildModernAppBar(authState, theme),
      body: _buildBody(authState, theme),
    );
  }

  PreferredSizeWidget _buildModernAppBar(AuthState authState, ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF3B82F6), // Blue
              Color(0xFF8B5CF6), // Purple
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(HeroIcons.beaker, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Text(
            _getAppBarTitle(authState),
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: const [],
    );
  }

  String _getAppBarTitle(AuthState authState) {
    final l10n = AppLocalizations.of(context)!;
    if (authState is AuthAuthenticated) {
      return l10n.laboratoryProfile;
    }
    return _isLoginMode ? l10n.labAccess : l10n.joinLaboratory;
  }

  Widget _buildBody(AuthState authState, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (authState is AuthAuthenticated) {
      return _buildModernProfileView(authState.user, theme);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModernWelcomeSection(l10n, theme),
          const SizedBox(height: 24),
          _buildModernAuthForm(authState, l10n, theme),
          const SizedBox(height: 20),
          _buildModernGoogleSignInButton(authState, l10n, theme),
          const SizedBox(height: 20),
          _buildToggleAuthModeButton(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildModernProfileView(user, ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user, l10n, theme),
          const SizedBox(height: 24),
          _buildRecentActivity(l10n, theme),
          const SizedBox(height: 24),
          _buildSafetySection(l10n, theme),
          const SizedBox(height: 24),
          _buildAccountSection(user, l10n, theme),
          const SizedBox(height: 24),
          _buildSignOutButton(l10n, theme),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user, AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6), // Blue
            Color(0xFF8B5CF6), // Purple
            Color(0xFF06B6D4), // Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: user.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(user.photoUrl!, fit: BoxFit.cover),
                  )
                : Center(
                    child: Text(
                      user.username.isNotEmpty
                          ? user.username[0].toUpperCase()
                          : 'L',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.laboratoryTechnician,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user.isEmailVerified
                            ? HeroIcons.shield_check
                            : HeroIcons.clock,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        user.isEmailVerified ? l10n.verified : 'Member',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recentActivity,
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildActivityItem(
                'Marquis Test',
                'MDMA Sample',
                '2 hours ago',
                const Color(0xFF10B981), // Green
                theme,
              ),
              _buildActivityItem(
                'Ehrlich Test',
                'LSD Sample',
                '1 day ago',
                const Color(0xFF3B82F6), // Blue
                theme,
              ),
              _buildActivityItem(
                'Scott Test',
                'Cocaine Sample',
                '2 days ago',
                const Color(0xFF8B5CF6), // Purple
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    String reagent,
    String sample,
    String time,
    Color color,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reagent,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  sample,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFECEC), // Light red
            Color(0xFFFFF3E0), // Light orange
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  HeroIcons.exclamation_triangle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.safetyReminder,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.safetyReminderText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(user, AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.accountInformation,
          style: theme.textTheme.titleLarge?.copyWith(
            color: const Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(
                HeroIcons.user,
                l10n.username,
                user.username,
                theme,
              ),
              const Divider(height: 32),
              _buildInfoRow(HeroIcons.envelope, l10n.email, user.email, theme),
              const Divider(height: 32),
              _buildInfoRow(
                HeroIcons.calendar,
                l10n.memberSince,
                _formatDate(user.registeredAt),
                theme,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(AppLocalizations l10n, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withOpacity(0.3),
        ),
      ),
      child: TextButton.icon(
        onPressed: _signOut,
        icon: const Icon(
          HeroIcons.arrow_right_on_rectangle,
          color: Color(0xFFFF6B6B),
        ),
        label: Text(
          l10n.signOut,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: const Color(0xFFFF6B6B),
            fontWeight: FontWeight.w600,
          ),
        ),
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildModernWelcomeSection(AppLocalizations l10n, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isLoginMode ? HeroIcons.beaker : HeroIcons.user_plus,
              size: 48,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _isLoginMode ? l10n.welcomeBack : l10n.joinOurLab,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLoginMode ? l10n.accessYourLab : l10n.startYourJourney,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModernAuthForm(
    AuthState authState,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isLoading = authState is AuthLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_isLoginMode) ...[
              _buildModernTextField(
                controller: _usernameController,
                label: l10n.username,
                icon: HeroIcons.user,
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
              const SizedBox(height: 20),
            ],
            _buildModernTextField(
              controller: _emailController,
              label: l10n.emailAddress,
              icon: HeroIcons.envelope,
              keyboardType: TextInputType.emailAddress,
              enabled: !isLoading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.pleaseEnterEmail;
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value.trim())) {
                  return l10n.pleaseEnterValidEmail;
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildModernTextField(
              controller: _passwordController,
              label: l10n.password,
              icon: HeroIcons.lock_closed,
              obscureText: !_isPasswordVisible,
              enabled: !isLoading,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? HeroIcons.eye_slash : HeroIcons.eye,
                  color: const Color(0xFF64748B),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
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
              const SizedBox(height: 20),
              _buildModernTextField(
                controller: _confirmPasswordController,
                label: l10n.confirmPassword,
                icon: HeroIcons.lock_closed,
                obscureText: !_isConfirmPasswordVisible,
                enabled: !isLoading,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? HeroIcons.eye_slash
                        : HeroIcons.eye,
                    color: const Color(0xFF64748B),
                  ),
                  onPressed: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                ),
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
            if (_isLoginMode) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _showPasswordResetDialog(context),
                  child: Text(
                    l10n.forgotPassword,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF3B82F6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isLoginMode
                                ? l10n.signingIn
                                : l10n.creatingAccount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _isLoginMode
                            ? l10n.accessLaboratory
                            : l10n.joinLaboratory,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1E293B)),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildModernGoogleSignInButton(
    AuthState authState,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final isLoading = authState is AuthLoading;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: const Color(0xFFE2E8F0)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.orContinueWith,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: const Color(0xFFE2E8F0)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextButton.icon(
              onPressed: isLoading ? null : _signInWithGoogle,
              icon: Image.asset(
                'assets/images/google_logo.png',
                height: 24,
                width: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    HeroIcons.globe_americas,
                    size: 24,
                    color: Color(0xFF4285F4),
                  );
                },
              ),
              label: Text(
                _isLoginMode ? l10n.signInWithGoogle : l10n.signUpWithGoogle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleAuthModeButton(AppLocalizations l10n, ThemeData theme) {
    return TextButton(
      onPressed: _toggleAuthMode,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
          children: [
            TextSpan(
              text: _isLoginMode
                  ? "${l10n.dontHaveLabAccess} "
                  : "${l10n.alreadyHaveLabAccess} ",
            ),
            TextSpan(
              text: _isLoginMode ? l10n.joinNow : l10n.signIn,
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
