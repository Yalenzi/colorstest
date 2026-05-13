import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../features/auth/data/models/user_model.dart';
import 'firestore_service.dart';
import '../utils/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // 🔑 CRITICAL FIX: GoogleSignIn must NOT hardcode clientId on iOS.
  // On iOS, GoogleSignIn SDK reads CLIENT_ID from GoogleService-Info.plist
  // automatically via FirebaseApp.configure(). Hardcoding clientId here
  // causes a CONFLICT that results in an instant crash on real devices.
  //
  // On Android/Web, serverClientId may be needed — but NOT on iOS.
  GoogleSignIn get _googleSignIn {
    if (Platform.isIOS || Platform.isMacOS) {
      // iOS: let GoogleSignIn read clientId from GoogleService-Info.plist
      // DO NOT pass clientId here — it causes native crash
      return GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    } else {
      // Android / other platforms
      return GoogleSignIn(
        scopes: ['email', 'profile'],
      );
    }
  }

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

      // Clear any existing local data before signing in
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

      await _clearAllLocalData();

      // Create user profile in Firestore
      if (result.user != null) {
        Logger.info(
          '🔧 AuthService: Creating user profile for ${result.user!.uid}',
        );

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

          await _firestoreService.createUserProfile(userModel);
          Logger.info(
            '✅ AuthService: User profile created successfully in Firestore',
          );
        } catch (e, stackTrace) {
          Logger.info('❌ AuthService: Error creating user profile: $e');
          Logger.info('❌ AuthService: Stack trace: $stackTrace');
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
  // 🔥 PRODUCTION-SAFE implementation:
  //    - No hardcoded clientId (iOS reads from GoogleService-Info.plist)
  //    - Catches PlatformException (native iOS crash source)
  //    - Handles user cancellation gracefully
  //    - Validates tokens before use
  Future<UserCredential?> signInWithGoogle() async {
    // Get a fresh GoogleSignIn instance (no cached clientId conflict)
    final googleSignIn = _googleSignIn;

    // Stage 1: Clear any stale Google session to prevent token reuse errors
    try {
      await googleSignIn.signOut();
      Logger.info('🔐 AuthService: Cleared stale Google session');
    } catch (e) {
      // Non-fatal: ignore if no session existed
      Logger.info('⚠️ AuthService: signOut pre-clean (non-fatal): $e');
    }

    // Stage 2: Launch Google account picker UI
    GoogleSignInAccount? googleUser;
    try {
      Logger.info('🔐 AuthService: Launching Google Sign-In UI...');
      googleUser = await googleSignIn.signIn();
    } on PlatformException catch (e) {
      // 🚨 This is the most common iOS crash source:
      //    PlatformException(sign_in_failed, ...) when clientId is wrong
      Logger.info('❌ AuthService: PlatformException during signIn: ${e.code} — ${e.message}');
      debugPrint('PlatformException details: ${e.details}');
      throw Exception('Google Sign-In failed (${e.code}). Check GoogleService-Info.plist configuration.');
    } catch (e, stack) {
      Logger.info('❌ AuthService: Unexpected error during Google signIn: $e');
      debugPrint('Stack: $stack');
      throw Exception('Google Sign-In is unavailable. Please try again.');
    }

    // Stage 3: Handle user cancellation
    if (googleUser == null) {
      Logger.info('🔐 AuthService: Google Sign-In cancelled by user');
      return null;
    }

    Logger.info('✅ AuthService: Google user selected: ${googleUser.email}');

    // Stage 4: Exchange for auth tokens
    GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
      Logger.info('✅ AuthService: Google tokens retrieved');
    } on PlatformException catch (e) {
      Logger.info('❌ AuthService: PlatformException getting tokens: ${e.code}');
      try { await googleSignIn.signOut(); } catch (_) {}
      throw Exception('Failed to retrieve Google auth tokens (${e.code}).');
    } catch (e) {
      Logger.info('❌ AuthService: Failed to get Google auth tokens: $e');
      try { await googleSignIn.signOut(); } catch (_) {}
      throw Exception('Failed to authenticate with Google. Please try again.');
    }

    // Stage 5: Validate tokens
    if (googleAuth.accessToken == null && googleAuth.idToken == null) {
      Logger.info('❌ AuthService: Both Google tokens are null');
      try { await googleSignIn.signOut(); } catch (_) {}
      throw Exception('Google authentication returned invalid tokens.');
    }

    Logger.info('✅ AuthService: Tokens valid — accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}');

    // Stage 6: Sign in to Firebase with Google credential
    UserCredential result;
    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      Logger.info('🔐 AuthService: Signing into Firebase with Google credential...');
      result = await _auth.signInWithCredential(credential);
      Logger.info('✅ AuthService: Firebase Auth success — uid: ${result.user?.uid}');
    } on FirebaseAuthException catch (e) {
      Logger.info('❌ AuthService: FirebaseAuthException: ${e.code} — ${e.message}');
      try { await googleSignIn.signOut(); } catch (_) {}
      throw _handleAuthException(e);
    } catch (e) {
      Logger.info('❌ AuthService: Firebase sign-in with Google credential failed: $e');
      try { await googleSignIn.signOut(); } catch (_) {}
      throw Exception('Failed to sign in with Google. Please try again.');
    }

    if (result.user == null) {
      Logger.info('❌ AuthService: Firebase returned null user after Google sign-in');
      return null;
    }

    final user = result.user!;
    Logger.info('🔐 AuthService: Firebase Auth successful for ${user.uid}');

    // Stage 7: Create or update Firestore user profile
    try {
      final existingProfile = await _firestoreService.getUserProfile(user.uid);

      if (existingProfile == null) {
        Logger.info('🔧 AuthService: No profile found, creating one...');

        final username = _generateUsernameFromDisplayName(
          user.displayName ?? user.email ?? 'User',
        );

        final userModel = UserModel.fromFirebaseUser(
          uid: user.uid,
          email: user.email ?? '',
          username: username,
          photoUrl: user.photoURL,
          displayName: user.displayName,
          isEmailVerified: user.emailVerified,
          phoneNumber: user.phoneNumber,
          signInMethods: ['google.com'],
          provider: 'google.com',
        );

        await _firestoreService.createUserProfile(userModel);
        Logger.info('✅ AuthService: Google user profile created successfully');
      } else {
        Logger.info('🔧 AuthService: Profile exists, updating activity');
        await _updateUserLastSignIn(user.uid);

        // Sync profile photo/name from Google if changed
        if (existingProfile.photoUrl != user.photoURL ||
            existingProfile.displayName != user.displayName) {
          await _firestoreService.updateUserProfile(user.uid, {
            'photoUrl': user.photoURL,
            'displayName': user.displayName,
            'lastSignInAt': firestore.FieldValue.serverTimestamp(),
          });
        }
      }

      // Clear local data AFTER profile is safely loaded/created
      await _clearAllLocalData();
    } catch (e) {
      Logger.info('⚠️ AuthService: Profile creation/update failed (non-fatal): $e');
      // Don't throw — user is already authenticated in Firebase
    }

    return result;
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _firestoreService.clearAllCache();
      await _clearAllLocalData();
      // Sign out from both Firebase and Google
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Clear all local data on logout to prevent user data bleeding
  Future<void> _clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('test_result_history');
      await prefs.remove('sync_queue');
      await prefs.remove('last_firestore_sync');
      Logger.info('✅ AuthService: All local data cleared on logout');
    } catch (e) {
      Logger.info('❌ AuthService: Failed to clear local data: $e');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Please enter a valid email address');
      }

      Logger.info('🔐 AuthService: Password reset requested');
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

  // Generate username from display name
  String _generateUsernameFromDisplayName(String displayName) {
    if (displayName.isEmpty) {
      return 'user${DateTime.now().millisecondsSinceEpoch}';
    }

    final nameParts = displayName.trim().split(' ');

    if (nameParts.length >= 2) {
      final firstName = nameParts[0].toLowerCase();
      final lastName = nameParts[1].toLowerCase();
      final cleanFirstName = firstName.replaceAll(RegExp(r'[^a-z]'), '');
      final cleanLastName = lastName.replaceAll(RegExp(r'[^a-z]'), '');

      if (cleanFirstName.isNotEmpty && cleanLastName.isNotEmpty) {
        final formattedFirst = cleanFirstName[0].toUpperCase() +
            (cleanFirstName.length > 1 ? cleanFirstName.substring(1) : '');
        final formattedLast = cleanLastName[0].toUpperCase() +
            (cleanLastName.length > 1 ? cleanLastName.substring(1) : '');
        return '${formattedFirst}_$formattedLast';
      }
    }

    final cleanedName = displayName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '')
        .trim();

    if (cleanedName.isNotEmpty) {
      return cleanedName[0].toUpperCase() +
          (cleanedName.length > 1 ? cleanedName.substring(1) : '');
    }

    return 'user${DateTime.now().millisecondsSinceEpoch}';
  }

  // Update user's last sign-in time
  Future<void> _updateUserLastSignIn(String uid) async {
    try {
      await _firestoreService.updateUserLastSignIn(uid);
    } catch (e) {
      Logger.info('⚠️ AuthService: Failed to update last sign-in time: $e');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    Logger.info(
      '🔥 AuthService: Firebase Auth Error - Code: ${e.code}, Message: ${e.message}',
    );

    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'invalid-email':
        return 'Invalid email or password. Please try again.';
      case 'email-already-in-use':
        return 'If this email is not already registered, an account will be created.';
      case 'weak-password':
        return 'Password must be at least 6 characters long.';
      case 'user-disabled':
        return 'This account has been temporarily disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please wait a few minutes before trying again.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently unavailable. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'credential-already-in-use':
      case 'auth-domain-config-required':
      default:
        return 'Unable to sign in at this time. Please try again later.';
    }
  }
}
