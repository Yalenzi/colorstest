import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel {
  final String uid;
  final String email;
  final String username;
  final DateTime registeredAt;
  final String? photoUrl;
  final String? displayName;
  final bool isEmailVerified;

  // Additional recommended fields based on Firebase best practices
  final String? phoneNumber; // From Firebase Auth
  final List<String> signInMethods; // Track how user signed in (email, google, etc.)
  final String? preferredLanguage; // For localization
  final String? provider; // e.g., 'google.com', 'password'
  final DateTime? lastSignInAt; // Track last login
  final Map<String, dynamic>? customClaims; // For role-based access
  final bool isActive; // Account status
  final String? timezone; // User timezone
  final Map<String, dynamic>? preferences; // User app preferences

  const UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.registeredAt,
    this.photoUrl,
    this.displayName,
    this.isEmailVerified = false,
    this.phoneNumber,
    this.signInMethods = const [],
    this.preferredLanguage,
    this.provider,
    this.lastSignInAt,
    this.customClaims,
    this.isActive = true,
    this.timezone,
    this.preferences,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      registeredAt: (data['registeredAt'] as Timestamp).toDate(),
      photoUrl: data['photoUrl'],
      displayName: data['displayName'],
      isEmailVerified: data['isEmailVerified'] ?? false,
      phoneNumber: data['phoneNumber'],
      signInMethods: List<String>.from(data['signInMethods'] ?? []),
      preferredLanguage: data['preferredLanguage'],
      provider: data['provider'],
      lastSignInAt: data['lastSignInAt'] != null ? (data['lastSignInAt'] as Timestamp).toDate() : null,
      customClaims: data['customClaims'],
      isActive: data['isActive'] ?? true,
      timezone: data['timezone'],
      preferences: data['preferences'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'registeredAt': Timestamp.fromDate(registeredAt),
      'photoUrl': photoUrl,
      'displayName': displayName,
      'isEmailVerified': isEmailVerified,
      'phoneNumber': phoneNumber,
      'signInMethods': signInMethods,
      'preferredLanguage': preferredLanguage,
      'provider': provider,
      'lastSignInAt': lastSignInAt != null ? Timestamp.fromDate(lastSignInAt!) : null,
      'customClaims': customClaims,
      'isActive': isActive,
      'timezone': timezone,
      'preferences': preferences,
    };
  }

  UserEntity toEntity() {
    return UserEntity(
      uid: uid,
      email: email,
      username: username,
      registeredAt: registeredAt,
      photoUrl: photoUrl,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
      phoneNumber: phoneNumber,
      signInMethods: signInMethods,
      preferredLanguage: preferredLanguage,
      customClaims: customClaims,
      isActive: isActive,
      timezone: timezone,
      preferences: preferences,
    );
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      email: entity.email,
      username: entity.username,
      registeredAt: entity.registeredAt,
      photoUrl: entity.photoUrl,
      displayName: entity.displayName,
      isEmailVerified: entity.isEmailVerified,
      phoneNumber: entity.phoneNumber,
      signInMethods: entity.signInMethods,
      preferredLanguage: entity.preferredLanguage,
      provider: entity.provider,
      lastSignInAt: entity.lastSignInAt,
      customClaims: entity.customClaims,
      isActive: entity.isActive,
      timezone: entity.timezone,
      preferences: entity.preferences,
    );
  }

  // Helper method to create from Firebase User
  factory UserModel.fromFirebaseUser({
    required String uid,
    required String email,
    required String username,
    String? photoUrl,
    String? displayName,
    bool isEmailVerified = false,
    String? phoneNumber,
    List<String> signInMethods = const [],
    String? preferredLanguage,
    String? provider,
    DateTime? lastSignInAt,
    String? timezone,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      username: username,
      registeredAt: now,
      photoUrl: photoUrl,
      displayName: displayName,
      isEmailVerified: isEmailVerified,
      phoneNumber: phoneNumber,
      signInMethods: signInMethods,
      preferredLanguage: preferredLanguage,
      provider: provider,
      lastSignInAt: lastSignInAt ?? now,
      isActive: true,
      timezone: timezone,
    );
  }

  // Copy method for updates
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    DateTime? registeredAt,
    String? photoUrl,
    String? displayName,
    bool? isEmailVerified,
    String? phoneNumber,
    List<String>? signInMethods,
    String? preferredLanguage,
    String? provider,
    DateTime? lastSignInAt,
    Map<String, dynamic>? customClaims,
    bool? isActive,
    String? timezone,
    Map<String, dynamic>? preferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      registeredAt: registeredAt ?? this.registeredAt,
      photoUrl: photoUrl ?? this.photoUrl,
      displayName: displayName ?? this.displayName,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      signInMethods: signInMethods ?? this.signInMethods,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      provider: provider ?? this.provider,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      customClaims: customClaims ?? this.customClaims,
      isActive: isActive ?? this.isActive,
      timezone: timezone ?? this.timezone,
      preferences: preferences ?? this.preferences,
    );
  }
}
