import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/user_model.dart';
import 'firestore_service.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final FirestoreService _firestoreService = FirestoreService();

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 CRITICAL: Clear any existing local data before signing in existing user
      await _clearAllLocalData();

      // Update last sign-in time
      if (result.user != null) {
        await _updateUserLastSignIn(result.user!.uid);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    String? preferredLanguage,
    String? timezone,
  }) async {
    try {
      // Check if username is available
      final isUsernameAvailable = await _firestoreService.isUsernameAvailable(
        username,
      );
      if (!isUsernameAvailable) {
        throw Exception('Username is already taken');
      }

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 CRITICAL: Clear any existing local data before creating new user
      await _clearAllLocalData();

      // Create user profile in Firestore
      if (result.user != null) {
        Logger.info(
          '🔧 AuthService: Creating user profile for ${result.user!.uid}',
        );
        Logger.info('🔧 AuthService: User email: ${result.user!.email}');
        Logger.info('🔧 AuthService: Username: $username');

        try {
          final userModel = UserModel.fromFirebaseUser(
            uid: result.user!.uid,
            email: email,
            username: username,
            photoUrl: result.user!.photoURL,
            displayName: result.user!.displayName ?? username,
            isEmailVerified: result.user!.emailVerified,
            phoneNumber: result.user!.phoneNumber,
            signInMethods: ['password'],
            preferredLanguage: preferredLanguage,
            timezone: timezone,
          );

          Logger.info('🔧 AuthService: User model created successfully');
          Logger.info(
            '🔧 AuthService: Calling FirestoreService.createUserProfile...',
          );

          await _firestoreService.createUserProfile(userModel);
          Logger.info(
            '✅ AuthService: User profile created successfully in Firestore',
          );
        } catch (e, stackTrace) {
          Logger.info('❌ AuthService: Error creating user profile: $e');
          Logger.info('❌ AuthService: Stack trace: $stackTrace');
          // Don't throw here, let the user be created in Auth even if Firestore fails
          Logger.info(
            '⚠️ AuthService: User created in Firebase Auth but Firestore profile creation failed',
          );
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw Exception('Google token null');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );

      // Check if this is a new user and create profile if needed
      if (result.user != null) {
        // First, check if user profile exists in Firestore
        Logger.info(
          '🔧 AuthService: Checking if user profile exists for ${result.user!.uid}',
        );
        final existingProfile = await _firestoreService.getUserProfile(
          result.user!.uid,
        );

        if (existingProfile == null) {
          // No profile exists - create one (could be new or existing user without profile)
          Logger.info(
            '🔧 AuthService: No profile found, creating profile for ${result.user!.uid}',
          );
          Logger.info('🔧 AuthService: User email: ${result.user!.email}');

          // 🔥 CRITICAL: Clear any existing local data before creating new user profile
          await _clearAllLocalData();

          try {
            // Generate username from display name (first name + last name)
            String username = _generateUsernameFromDisplayName(
              result.user!.displayName ?? result.user!.email ?? '',
            );
            Logger.info('🔧 AuthService: Generated username: $username');

            final userModel = UserModel.fromFirebaseUser(
              uid: result.user!.uid,
              email: result.user!.email ?? '',
              username: username,
              photoUrl: result.user!.photoURL,
              displayName: result.user!.displayName,
              isEmailVerified: result.user!.emailVerified,
              phoneNumber: result.user!.phoneNumber,
              signInMethods: ['google.com'],
            );

            Logger.info(
              '🔧 AuthService: User model created, calling FirestoreService.createUserProfile...',
            );
            await _firestoreService.createUserProfile(userModel);
            Logger.info(
              '✅ AuthService: Google user profile created successfully in Firestore',
            );
          } catch (e, stackTrace) {
            Logger.info(
              '❌ AuthService: Error creating Google user profile: $e',
            );
            Logger.info('❌ AuthService: Stack trace: $stackTrace');
            // Don't throw here, let the user be signed in even if Firestore fails
            Logger.info(
              '⚠️ AuthService: Google user signed in but Firestore profile creation failed',
            );
          }
        } else {
          Logger.info(
            '🔧 AuthService: Existing Google user with profile, updating last sign-in time',
          );

          // 🔥 CRITICAL: Clear any existing local data before signing in existing user
          await _clearAllLocalData();

          // Update last sign in time for existing users
          await _updateUserLastSignIn(result.user!.uid);
        }
      }

      return result;
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear Firestore cache on logout
      _firestoreService.clearAllCache();

      // 🔥 CRITICAL: Clear all local storage to prevent data bleeding between users
      await _clearAllLocalData();

      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Clear all local data on logout to prevent user data bleeding
  Future<void> _clearAllLocalData() async {
    try {
      // Import and clear test results local storage
      // Note: We can't directly import TestResultHistoryRepository here due to circular dependency
      // So we'll clear the SharedPreferences keys directly
      final prefs = await SharedPreferences.getInstance();

      // Clear test results
      await prefs.remove('test_result_history');

      // Clear sync queue
      await prefs.remove('sync_queue');

      // Clear last sync timestamp
      await prefs.remove('last_firestore_sync');

      Logger.info('✅ AuthService: All local data cleared on logout');
    } catch (e) {
      Logger.info('❌ AuthService: Failed to clear local data: $e');
      // Don't throw error, logout should still proceed
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Validate email format before sending request
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email address');
      }

      Logger.info('🔐 AuthService: Password reset requested');
      
      // Trim email as requested
      await _auth.sendPasswordResetEmail(email: email.trim());

      Logger.info('✅ AuthService: Password reset email sent successfully');
    } on FirebaseAuthException catch (e) {
      Logger.info('❌ AuthService: Password reset failed - ${e.code}');

      switch (e.code) {
        case 'user-not-found':
          throw Exception('No user found for that email address.');
        case 'invalid-email':
          throw Exception('The email address is badly formatted.');
        case 'network-request-failed':
          throw Exception('Network error. Please check your internet connection.');
        case 'too-many-requests':
          throw Exception('Too many reset attempts. Please wait before trying again.');
        case 'user-disabled':
          throw Exception('This account has been disabled.');
        default:
          throw Exception(e.message ?? 'Failed to send password reset email. Please try again.');
      }
    } catch (e) {
      Logger.info('❌ AuthService: Password reset error: $e');
      throw Exception('An unexpected error occurred. Please try again later.');
    }
  }

  // Get user profile from Firestore
  Future<UserModel?> getUserProfile(String uid) async {
    return await _firestoreService.getUserProfile(uid);
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile(String uid) {
    return _firestoreService.streamUserProfile(uid);
  }

  // Helper method to generate username from display name (first name + last name)
  String _generateUsernameFromDisplayName(String displayName) {
    if (displayName.isEmpty) {
      return 'user${DateTime.now().millisecondsSinceEpoch}';
    }

    // Split display name into parts (first name, last name, etc.)
    final nameParts = displayName.trim().split(' ');

    if (nameParts.length >= 2) {
      // Use first name + underscore + last name format
      final firstName = nameParts[0].toLowerCase();
      final lastName = nameParts[1].toLowerCase();

      // Clean the names (remove special characters, keep only letters)
      final cleanFirstName = firstName.replaceAll(RegExp(r'[^a-z]'), '');
      final cleanLastName = lastName.replaceAll(RegExp(r'[^a-z]'), '');

      if (cleanFirstName.isNotEmpty && cleanLastName.isNotEmpty) {
        // Capitalize first letter of each name
        final formattedFirstName =
            cleanFirstName[0].toUpperCase() +
            (cleanFirstName.length > 1 ? cleanFirstName.substring(1) : '');
        final formattedLastName =
            cleanLastName[0].toUpperCase() +
            (cleanLastName.length > 1 ? cleanLastName.substring(1) : '');

        return '${formattedFirstName}_$formattedLastName';
      }
    }

    // Fallback: use the whole display name, cleaned up
    final cleanedName = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();

    if (cleanedName.isNotEmpty) {
      // Capitalize first letter
      return cleanedName[0].toUpperCase() +
          (cleanedName.length > 1 ? cleanedName.substring(1) : '');
    }

    return 'user${DateTime.now().millisecondsSinceEpoch}';
  }

  // Helper method to update user's last sign-in time
  Future<void> _updateUserLastSignIn(String uid) async {
    try {
      await _firestoreService.updateUserLastSignIn(uid);
    } catch (e) {
      Logger.info('⚠️ AuthService: Failed to update last sign-in time: $e');
    }
  }

  // Handle Firebase Auth exceptions with security best practices
  String _handleAuthException(FirebaseAuthException e) {
    Logger.info(
      '🔥 AuthService: Firebase Auth Error - Code: ${e.code}, Message: ${e.message}',
    );

    // Follow OWASP Authentication Security Best Practices:
    // Use generic error messages to prevent user enumeration attacks
    // and avoid revealing technical details about the authentication system

    switch (e.code) {
      // Authentication failures - use generic message
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Invalid email or password. Please try again.';

      // Account creation conflicts
      case 'email-already-in-use':
        // Generic message for account creation to prevent email enumeration
        return 'If this email is not already registered, an account will be created.';

      // Password policy violations
      case 'weak-password':
        return 'Password must be at least 6 characters long.';

      // Account status issues
      case 'user-disabled':
        return 'This account has been temporarily disabled. Please contact support.';

      // Rate limiting
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a few minutes before trying again.';

      // Service configuration issues
      case 'operation-not-allowed':
        return 'This sign-in method is currently unavailable. Please try again later.';

      // Network or service issues
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';

      // Credential expiration/malformation (the error you encountered)
      case 'credential-already-in-use':
      case 'auth-domain-config-required':
      default:
        // Generic fallback message - never expose technical Firebase errors
        return 'Unable to sign in at this time. Please try again later.';
    }
  }
}
