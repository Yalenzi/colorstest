import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/data/models/user_model.dart';
import '../utils/logger.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for user profiles to reduce database calls
  final Map<String, UserModel> _userCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Collection reference for users
  CollectionReference get _usersCollection => _firestore.collection('users');

  // Clear cache for a specific user
  void _clearUserCache(String uid) {
    _userCache.remove(uid);
    _cacheTimestamps.remove(uid);
  }

  // Check if cache is valid for a user
  bool _isCacheValid(String uid) {
    final timestamp = _cacheTimestamps[uid];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheExpiry;
  }

  // Create user profile in Firestore
  Future<void> createUserProfile(UserModel user) async {
    try {
      final userData = user.toFirestore();
      
      // Use Firebase UID as the document ID
      await _usersCollection.doc(user.uid).set(userData);

      // Cache the user profile immediately
      _userCache[user.uid] = user;
      _cacheTimestamps[user.uid] = DateTime.now();

      Logger.info('✅ FirestoreService: Profile created for ${user.uid}');
    } catch (e) {
      Logger.info('❌ FirestoreService: Error creating profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Get user profile from Firestore by Firebase UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      // Check cache first
      if (_isCacheValid(uid) && _userCache.containsKey(uid)) {
        return _userCache[uid];
      }

      // Direct document access is fastest
      final doc = await _usersCollection.doc(uid).get();

      if (doc.exists) {
        final userModel = UserModel.fromFirestore(doc);

        // Cache the result
        _userCache[uid] = userModel;
        _cacheTimestamps[uid] = DateTime.now();

        return userModel;
      }
      return null;
    } catch (e) {
      Logger.info('❌ FirestoreService: Error getting profile: $e');
      return null;
    }
  }

  // Get user profile from Firestore by username
  Future<UserModel?> getUserProfileByUsername(String username) async {
    try {
      final query = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final userModel = UserModel.fromFirestore(query.docs.first);
        return userModel;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile by username: $e');
    }
  }

  // Update user profile in Firestore
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      _clearUserCache(uid);
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Update last sign-in time
  Future<void> updateUserLastSignIn(String uid) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastSignInAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      Logger.info('⚠️ FirestoreService: Failed to update last sign-in: $e');
    }
  }

  // Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final query = await _usersCollection
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return query.docs.isEmpty;
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile(String uid) async {
    try {
      _clearUserCache(uid);
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user profile: $e');
    }
  }

  // Stream user profile changes by Firebase UID
  Stream<UserModel?> streamUserProfile(String uid) {
    return _usersCollection
        .where('uid', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final userModel = UserModel.fromFirestore(snapshot.docs.first);

            // Update cache when streaming
            _userCache[uid] = userModel;
            _cacheTimestamps[uid] = DateTime.now();

            return userModel;
          }
          return null;
        });
  }

  // Clear all cache (useful for logout)
  void clearAllCache() {
    _userCache.clear();
    _cacheTimestamps.clear();
  }

  // Debug method to test Firestore connectivity
  Future<void> testFirestoreConnection() async {
    try {
      Logger.info('🔧 FirestoreService: Testing Firestore connection...');

      // Test write
      final testData = {
        'test': true,
        'timestamp': Timestamp.now(),
        'message': 'Firestore connection test',
      };

      await _firestore.collection('test').doc('connection_test').set(testData);
      Logger.info('✅ FirestoreService: Test write successful');

      // Test read
      final doc = await _firestore
          .collection('test')
          .doc('connection_test')
          .get();
      if (doc.exists) {
        Logger.info('✅ FirestoreService: Test read successful: ${doc.data()}');
      } else {
        Logger.info('❌ FirestoreService: Test read failed - document not found');
      }

      // Clean up test document
      await _firestore.collection('test').doc('connection_test').delete();
      Logger.info('✅ FirestoreService: Test cleanup successful');
    } catch (e) {
      Logger.info('❌ FirestoreService: Connection test failed: $e');
      throw Exception('Firestore connection test failed: $e');
    }
  }
}
