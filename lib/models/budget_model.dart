// lib/models/budget_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.familyId,
    required this.category,
    required this.limitAmount,
    required this.spentAmount,
    required this.monthKey,
    required this.createdBy,
    required this.createdAt,
    this.isMonthlyOverall = false,
  });

  final String id;
  final String familyId;
  final String category;
  final double limitAmount;
  final double spentAmount;
  final String monthKey;
  final String createdBy;
  final Timestamp? createdAt;
  final bool isMonthlyOverall;

  double get remainingAmount => limitAmount - spentAmount;

  double get progress {
    if (limitAmount <= 0) return 0;
    final value = spentAmount / limitAmount;
    return value.clamp(0, 1).toDouble();
  }

  bool get isNearLimit => progress >= 0.8 && progress < 1.0;
  bool get isExceeded => progress >= 1.0;

  BudgetModel copyWith({
    String? id,
    String? familyId,
    String? category,
    double? limitAmount,
    double? spentAmount,
    String? monthKey,
    String? createdBy,
    Timestamp? createdAt,
    bool? isMonthlyOverall,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      category: category ?? this.category,
      limitAmount: limitAmount ?? this.limitAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      monthKey: monthKey ?? this.monthKey,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      isMonthlyOverall: isMonthlyOverall ?? this.isMonthlyOverall,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'category': category,
      'limitAmount': limitAmount,
      'spentAmount': spentAmount,
      'monthKey': monthKey,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'isMonthlyOverall': isMonthlyOverall,
    };
  }

  factory BudgetModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final rawLimit = map['limitAmount'];
    final rawSpent = map['spentAmount'];

    return BudgetModel(
      id: documentId,
      familyId: map['familyId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      limitAmount: rawLimit is int
          ? rawLimit.toDouble()
          : (rawLimit as num?)?.toDouble() ?? 0,
      spentAmount: rawSpent is int
          ? rawSpent.toDouble()
          : (rawSpent as num?)?.toDouble() ?? 0,
      monthKey: map['monthKey'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      isMonthlyOverall: map['isMonthlyOverall'] as bool? ?? false,
    );
  }

  factory BudgetModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return BudgetModel.fromMap(
      data,
      documentId: doc.id,
    );
  }
}