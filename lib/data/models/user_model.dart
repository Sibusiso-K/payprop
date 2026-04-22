import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum UserRole { tenant, agent, homeowner }

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String? phone;
  final String displayName;
  final UserRole role;
  final bool profileComplete;
  final String? photoUrl;
  final String? fcmToken;
  final DateTime createdAt;

  const UserModel({
    required this.uid,
    required this.email,
    this.phone,
    required this.displayName,
    required this.role,
    required this.profileComplete,
    this.photoUrl,
    this.fcmToken,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      displayName: map['displayName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == map['role'],
        orElse: () => UserRole.tenant,
      ),
      profileComplete: map['profileComplete'] as bool? ?? false,
      photoUrl: map['photoUrl'] as String?,
      fcmToken: map['fcmToken'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'phone': phone,
        'displayName': displayName,
        'role': role.name,
        'profileComplete': profileComplete,
        'photoUrl': photoUrl,
        'fcmToken': fcmToken,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? displayName,
    String? phone,
    bool? profileComplete,
    String? photoUrl,
    String? fcmToken,
  }) =>
      UserModel(
        uid: uid,
        email: email,
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
        role: role,
        profileComplete: profileComplete ?? this.profileComplete,
        photoUrl: photoUrl ?? this.photoUrl,
        fcmToken: fcmToken ?? this.fcmToken,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [uid, email, role, profileComplete];
}
