import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/config/get_it_config.dart';
import '../states/auth_state.dart';
import '../../domain/entities/user_entity.dart';
import '../../data/models/user_model.dart';
import '../../../../core/utils/logger.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthInitial()) {
    _initializeAuthState();
  }

  // Helper method to extract clean error messages without Exception prefix
  String _extractErrorMessage(dynamic error) {
    String errorMessage = error.toString();
    if (errorMessage.startsWith('Exception: ')) {
      return errorMessage.substring(11);
    }
    return errorMessage;
  }


  // Initialize auth state by listening to auth changes
  void _initializeAuthState() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        try {
          // Retry logic for loading user profile
          UserModel? userProfile;
          int retryCount = 0;
          const maxRetries = 3;

          while (userProfile == null && retryCount < maxRetries) {
            try {
              userProfile = await _authService.getUserProfile(user.uid);
              if (userProfile != null) {
                break;
              }
            } catch (e) {
              Logger.info(
                '⚠️ AuthController: Profile load attempt ${retryCount + 1} failed: $e',
              );
            }

            retryCount++;
            if (retryCount < maxRetries) {
              await Future.delayed(Duration(milliseconds: 500 * retryCount));
            }
          }

          if (userProfile != null) {
            state = AuthAuthenticated(userProfile.toEntity());
          } else {
            Logger.info(
              '❌ AuthController: Could not load user profile after $maxRetries attempts',
            );
            state = const AuthUnauthenticated();
          }
        } catch (e) {
          Logger.info('❌ AuthController: Error in auth state change: $e');
          state = AuthError('Failed to load user profile: $e');
        }
      } else {
        // User signed out - clear all data
        await _clearAllLocalDataOnAuthChange();
        state = const AuthUnauthenticated();
      }
    });
  }

  // Clear all local data when authentication state changes
  Future<void> _clearAllLocalDataOnAuthChange() async {
    try {
      // Clear SharedPreferences directly to avoid dependency issues
      // This is safer than trying to inject the repository
      final prefs = await SharedPreferences.getInstance();

      // Clear test results
      await prefs.remove('test_result_history');

      // Clear sync queue
      await prefs.remove('sync_queue');

      // Clear last sync timestamp
      await prefs.remove('last_firestore_sync');

      Logger.info(
        '✅ AuthController: All local data cleared on auth state change',
      );
    } catch (e) {
      Logger.info(
        '❌ AuthController: Failed to clear local data on auth change: $e',
      );
      // Don't throw error, auth state change should still proceed
    }
  }

  // Sign in with email and password - OPTIMIZED
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result?.user != null) {
        // Get user profile immediately without artificial delays
        final userProfile = await _authService.getUserProfile(
          result!.user!.uid,
        );
        if (userProfile != null) {
          // Show login success notification
          NotificationService.showLoginSuccess(
            username: userProfile.username,
          );

          state = AuthAuthenticated(userProfile.toEntity());
        } else {
          state = const AuthError('User profile not found');
        }
      }
    } catch (e) {
      // Extract clean error message without Exception prefix
      String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    }
  }

  // Create user with email and password - OPTIMIZED
  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  }) async {
    state = const AuthLoading();
    try {
      Logger.info('🔧 AuthController: Starting user registration');
      Logger.info('🔧 AuthController: Email: $email');
      Logger.info('🔧 AuthController: Username: $username');

      Logger.info(
        '🔧 AuthController: Calling AuthService.createUserWithEmailAndPassword...',
      );
      final result = await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
      );
      Logger.info('🔧 AuthController: AuthService call completed');

      if (result?.user != null) {
        Logger.info(
          '✅ AuthController: Firebase Auth user created: ${result!.user!.uid}',
        );

        Logger.info(
          '🔧 AuthController: Loading user profile from Firestore...',
        );
        // Load user profile immediately without delays
        final userProfile = await _authService.getUserProfile(result.user!.uid);

        if (userProfile != null) {
          Logger.info('✅ AuthController: User profile loaded successfully');

          // Show success notification
          NotificationService.showRegistrationSuccess(
            username: userProfile.username,
          );

          state = AuthAuthenticated(userProfile.toEntity());
        } else {
          Logger.info('❌ AuthController: User profile NOT found in Firestore');
          state = const AuthError('Failed to create user profile');
        }
      } else {
        Logger.info(
          '❌ AuthController: Firebase Auth user creation returned null',
        );
      }
    } catch (e, stackTrace) {
      Logger.info('❌ AuthController: Error during registration: $e');
      Logger.info('❌ AuthController: Stack trace: $stackTrace');

      // Show error notification
      NotificationService.showError(
        title: '❌ Registration Failed',
        message: 'Unable to create account. Please try again.',
      );

      // Extract clean error message without Exception prefix
      String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    }
  }

  // Sign in with Google - OPTIMIZED
  Future<void> signInWithGoogle() async {
    state = const AuthLoading();
    try {
      Logger.info('🔧 AuthController: Starting Google Sign-In');
      final result = await _authService.signInWithGoogle();

      if (result?.user != null) {
        Logger.info(
          '✅ AuthController: Google Sign-In successful for ${result!.user!.uid}',
        );

        // Wait a moment for authentication state to propagate
        await Future.delayed(const Duration(milliseconds: 200));

        // Get user profile with retry logic
        UserModel? userProfile;
        int retryCount = 0;
        const maxRetries = 3;

        while (userProfile == null && retryCount < maxRetries) {
          try {
            userProfile = await _authService.getUserProfile(result.user!.uid);
            if (userProfile != null) {
              Logger.info('✅ AuthController: User profile loaded successfully');
              break;
            }
          } catch (e) {
            Logger.info(
              '⚠️ AuthController: Attempt ${retryCount + 1} failed: $e',
            );
          }

          retryCount++;
          if (retryCount < maxRetries) {
            await Future.delayed(Duration(milliseconds: 300 * retryCount));
          }
        }

        if (userProfile != null) {
          // Show Google sign-in success notification
          NotificationService.showSuccess(
            title: '🚀 Google Sign-In Success',
            message:
                'Welcome ${userProfile.username}! Ready to continue testing?',
          );

          state = AuthAuthenticated(userProfile.toEntity());
        } else {
          Logger.info(
            '❌ AuthController: Could not load user profile after $maxRetries attempts',
          );
          // For new Google users, the profile might not exist yet - this is OK
          // The user is still authenticated, we just don't have a profile
          state = const AuthError(
            'Profile not found. Please try signing in again.',
          );
        }
      } else {
        // User canceled sign-in
        Logger.info('⚠️ AuthController: User canceled Google Sign-In');
        state = const AuthUnauthenticated();
      }
    } catch (e) {
      Logger.info('❌ AuthController: Google Sign-In error: $e');
      // Extract clean error message without Exception prefix
      String errorMessage = _extractErrorMessage(e);
      state = AuthError('Google Sign-In failed: $errorMessage');
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _authService.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      // Extract clean error message without Exception prefix
      String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AuthLoading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AuthSuccess(
        '📧 Password reset email sent! Check your inbox.',
      );
    } catch (e) {
      // Extract clean error message without Exception prefix
      String errorMessage = _extractErrorMessage(e);
      state = AuthError(errorMessage);
    }
  }

  // Clear error state
  void clearError() {
    if (state is AuthError || state is AuthSuccess) {
      state = const AuthUnauthenticated();
    }
  }

  // Show temporary success message then return to authenticated state
  void showSuccessMessage(String message, UserEntity user) async {
    state = AuthSuccess(message);
    // Brief success message display
    await Future.delayed(const Duration(milliseconds: 800));
    state = AuthAuthenticated(user);
  }
}

// Provider for AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(getIt<AuthService>());
  },
);
