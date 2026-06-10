import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.dueDate,
    required this.amount,
    required this.iconCodePoint,
    required this.accentColor,
    required this.backgroundColorValue,
  });

  final String id;
  final String title;
  final String subtitle;
  final DateTime dueDate;
  final double amount;
  final int iconCodePoint;
  final int accentColor;
  final int backgroundColorValue;

  IconData get icon =>
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  Color get accent => Color(accentColor);
  Color get background => Color(backgroundColorValue);

  factory ReminderModel.fromMap(String id, Map<String, dynamic> data) {
    return ReminderModel(
      id: id,
      title: (data['title'] as String?) ?? '',
      subtitle: (data['subtitle'] as String?) ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      iconCodePoint:
          (data['iconCodePoint'] as int?) ?? Icons.notifications_rounded.codePoint,
      accentColor: (data['accentColor'] as int?) ?? 0xFF5C6FB2,
      backgroundColorValue:
          (data['backgroundColorValue'] as int?) ?? 0xFFE9ECFA,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'dueDate': Timestamp.fromDate(dueDate),
      'amount': amount,
      'iconCodePoint': iconCodePoint,
      'accentColor': accentColor,
      'backgroundColorValue': backgroundColorValue,
    };
  }
}