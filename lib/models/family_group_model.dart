// lib/models/family_group_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroupModel {
  const FamilyGroupModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
    required this.memberIds,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String code;
  final String createdBy;
  final List<String> memberIds;
  final Timestamp createdAt;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': createdAt,
    };
  }

  factory FamilyGroupModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FamilyGroupModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      code: data['code'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? const []),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }
}