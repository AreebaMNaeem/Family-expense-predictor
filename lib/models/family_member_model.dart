// lib/models/family_member_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyMemberModel {
  const FamilyMemberModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.familyId,
    required this.familyCode,
    required this.familyName,
    required this.role,
    required this.joinedAt,
  });

  final String uid;
  final String email;
  final String fullName;
  final String familyId;
  final String familyCode;
  final String familyName;
  final String role;
  final Timestamp? joinedAt;

  bool get isAdmin => role == 'admin';
  bool get isMember => role == 'member';

  FamilyMemberModel copyWith({
    String? uid,
    String? email,
    String? fullName,
    String? familyId,
    String? familyCode,
    String? familyName,
    String? role,
    Timestamp? joinedAt,
  }) {
    return FamilyMemberModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      familyId: familyId ?? this.familyId,
      familyCode: familyCode ?? this.familyCode,
      familyName: familyName ?? this.familyName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'familyId': familyId,
      'familyCode': familyCode,
      'familyName': familyName,
      'role': role,
      'joinedAt': joinedAt,
    };
  }

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map) {
    return FamilyMemberModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      familyId: map['familyId'] as String? ?? '',
      familyCode: map['familyCode'] as String? ?? '',
      familyName: map['familyName'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      joinedAt: map['joinedAt'] as Timestamp?,
    );
  }
}
