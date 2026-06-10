// lib/providers/dashboard_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/family_member_model.dart';
import 'firestore_provider.dart';

final currentFamilyMemberProvider =
    StreamProvider.autoDispose<FamilyMemberModel?>((ref) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(null);
  }

  return ref
      .watch(firestoreServiceProvider)
      .watchCurrentFamilyMember(uid: user.uid);
});

final familyExpensesProvider =
    StreamProvider.autoDispose.family<List<ExpenseModel>, String>(
  (ref, familyId) {
    return ref
        .watch(firestoreServiceProvider)
        .watchFamilyExpenses(familyId: familyId);
  },
);

final familyBudgetsProvider = StreamProvider.autoDispose
    .family<List<BudgetModel>, ({String familyId, String monthKey})>(
  (ref, args) {
    return ref.watch(firestoreServiceProvider).watchFamilyBudgets(
          familyId: args.familyId,
          monthKey: args.monthKey,
        );
  },
);

final familyMembersProvider =
    StreamProvider.autoDispose.family<List<FamilyMemberModel>, String>(
  (ref, familyId) {
    return ref
        .watch(firestoreServiceProvider)
        .watchFamilyMembers(familyId: familyId);
  },
);