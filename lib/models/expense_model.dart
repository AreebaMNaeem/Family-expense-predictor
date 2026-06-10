// lib/models/expense_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.payerId,
    required this.payerName,
    required this.splitMemberIds,
    required this.createdBy,
    required this.createdAt,
    this.note,
    this.receiptUrl,
    this.isRecurring = false,
  });

  final String id;
  final String familyId;
  final String title;
  final String category;
  final double amount;
  final Timestamp? date;
  final String payerId;
  final String payerName;
  final List<String> splitMemberIds;
  final String createdBy;
  final Timestamp? createdAt;
  final String? note;
  final String? receiptUrl;
  final bool isRecurring;

  ExpenseModel copyWith({
    String? id,
    String? familyId,
    String? title,
    String? category,
    double? amount,
    Timestamp? date,
    String? payerId,
    String? payerName,
    List<String>? splitMemberIds,
    String? createdBy,
    Timestamp? createdAt,
    String? note,
    String? receiptUrl,
    bool? isRecurring,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      payerId: payerId ?? this.payerId,
      payerName: payerName ?? this.payerName,
      splitMemberIds: splitMemberIds ?? this.splitMemberIds,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'payerId': payerId,
      'payerName': payerName,
      'splitMemberIds': splitMemberIds,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'note': note,
      'receiptUrl': receiptUrl,
      'isRecurring': isRecurring,
    };
  }

  factory ExpenseModel.fromMap(
    Map<String, dynamic> map, {
    required String documentId,
  }) {
    final rawAmount = map['amount'];

    return ExpenseModel(
      id: documentId,
      familyId: map['familyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? '',
      amount: rawAmount is int
          ? rawAmount.toDouble()
          : (rawAmount as num?)?.toDouble() ?? 0,
      date: map['date'] as Timestamp?,
      payerId: map['payerId'] as String? ?? '',
      payerName: map['payerName'] as String? ?? '',
      splitMemberIds: List<String>.from(map['splitMemberIds'] ?? const []),
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp?,
      note: map['note'] as String?,
      receiptUrl: map['receiptUrl'] as String?,
      isRecurring: map['isRecurring'] as bool? ?? false,
    );
  }

  factory ExpenseModel.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};

    return ExpenseModel.fromMap(
      data,
      documentId: doc.id,
    );
  }
}