import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 2)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final String? photoUrl;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime lastLoginAt;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
  });

  // Factory constructor for creating a new user
  factory User.create({
    required String id,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    final now = DateTime.now();
    return User(
      id: id,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: now,
      lastLoginAt: now,
    );
  }

  // Copy with method for updates
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // JSON serialization for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  // JSON deserialization from Firebase
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }

  // Validation
  bool get isValid {
    return id.isNotEmpty && 
           email.isNotEmpty && 
           email.contains('@') &&
           displayName.trim().isNotEmpty;
  }

  // Helper methods
  String get initials {
    final names = displayName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  String get firstName {
    final names = displayName.split(' ');
    return names.isNotEmpty ? names[0] : displayName;
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}