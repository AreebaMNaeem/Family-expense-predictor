import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_model.dart';
import 'firestore_provider.dart';

class ReminderIconOption {
  const ReminderIconOption({
    required this.icon,
    required this.accent,
    required this.background,
    required this.label,
  });

  final IconData icon;
  final int accent;
  final int background;
  final String label;
}

final reminderIconOptionsProvider = Provider<List<ReminderIconOption>>((ref) {
  return const [
    ReminderIconOption(
      icon: Icons.school_rounded,
      accent: 0xFF5C6FB2,
      background: 0xFFE9ECFA,
      label: 'School',
    ),
    ReminderIconOption(
      icon: Icons.flash_on_rounded,
      accent: 0xFFE0B449,
      background: 0xFFFFF1D6,
      label: 'Electricity',
    ),
    ReminderIconOption(
      icon: Icons.local_fire_department_rounded,
      accent: 0xFFCC7E5C,
      background: 0xFFFCEADF,
      label: 'Gas',
    ),
    ReminderIconOption(
      icon: Icons.water_drop_rounded,
      accent: 0xFF5A90B2,
      background: 0xFFDEEFF8,
      label: 'Water',
    ),
    ReminderIconOption(
      icon: Icons.wifi_rounded,
      accent: 0xFF6B7EC2,
      background: 0xFFEAEDFA,
      label: 'Internet',
    ),
    ReminderIconOption(
      icon: Icons.local_hospital_rounded,
      accent: 0xFFB25C5C,
      background: 0xFFF8DEDE,
      label: 'Medical',
    ),
    ReminderIconOption(
      icon: Icons.home_rounded,
      accent: 0xFF6CA87E,
      background: 0xFFDFF2E5,
      label: 'Rent',
    ),
    ReminderIconOption(
      icon: Icons.directions_car_rounded,
      accent: 0xFF8B7EC2,
      background: 0xFFEFEDFA,
      label: 'Transport',
    ),
    ReminderIconOption(
      icon: Icons.notifications_rounded,
      accent: 0xFF8A6A87,
      background: 0xFFF5E9F4,
      label: 'Other',
    ),
  ];
});

final familyRemindersProvider =
    StreamProvider.family<List<ReminderModel>, String>((ref, familyId) {
  return ref.watch(firestoreServiceProvider).watchFamilyReminders(
        familyId: familyId,
      );
});