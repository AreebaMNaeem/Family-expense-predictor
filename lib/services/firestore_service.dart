// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../models/family_group_model.dart';
import '../models/family_member_model.dart';
import '../models/reminder_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _families =>
      _firestore.collection('families');

  CollectionReference<Map<String, dynamic>> get _expenses =>
      _firestore.collection('expenses');

  CollectionReference<Map<String, dynamic>> get _budgets =>
      _firestore.collection('budgets');

  CollectionReference<Map<String, dynamic>> _familyReminders(String familyId) =>
      _families.doc(familyId).collection('reminders');

  Future<FamilyMemberModel?> getCurrentFamilyMember({
    required String uid,
  }) async {
    final doc = await _users.doc(uid).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return FamilyMemberModel.fromMap(doc.data()!);
  }

  Stream<FamilyMemberModel?> watchCurrentFamilyMember({
    required String uid,
  }) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return FamilyMemberModel.fromMap(doc.data()!);
    });
  }

  Future<FamilyGroupModel?> getFamilyGroup({
    required String familyId,
  }) async {
    final doc = await _families.doc(familyId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return FamilyGroupModel.fromDoc(doc);
  }

  Stream<FamilyGroupModel?> watchFamilyGroup({
    required String familyId,
  }) {
    return _families.doc(familyId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return FamilyGroupModel.fromDoc(doc);
    });
  }

  Stream<List<FamilyMemberModel>> watchFamilyMembers({
    required String familyId,
  }) {
    return _users
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FamilyMemberModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> addExpense(ExpenseModel expense) async {
    final docRef =
        expense.id.isEmpty ? _expenses.doc() : _expenses.doc(expense.id);

    await docRef.set({
      ...expense.toMap(),
      'createdAt': expense.createdAt ?? FieldValue.serverTimestamp(),
      'date': expense.date ?? Timestamp.now(),
    });
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    if (expense.id.isEmpty) {
      throw Exception('Expense ID is required for update.');
    }

    await _expenses.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense({
    required String expenseId,
  }) async {
    await _expenses.doc(expenseId).delete();
  }

  Stream<List<ExpenseModel>> watchFamilyExpenses({
    required String familyId,
  }) {
    return _expenses
        .where('familyId', isEqualTo: familyId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ExpenseModel.fromDoc(doc)).toList();
    });
  }

  Future<void> addBudget(BudgetModel budget) async {
    final docRef = budget.id.isEmpty ? _budgets.doc() : _budgets.doc(budget.id);

    await docRef.set({
      ...budget.toMap(),
      'createdAt': budget.createdAt ?? FieldValue.serverTimestamp(),
    });
  }

  Future<void> setBudget(BudgetModel budget) async {
    final docRef = budget.id.isEmpty ? _budgets.doc() : _budgets.doc(budget.id);

    await docRef.set({
      ...budget.toMap(),
      'createdAt': budget.createdAt ?? FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateBudget(BudgetModel budget) async {
    if (budget.id.isEmpty) {
      throw Exception('Budget ID is required for update.');
    }

    await _budgets.doc(budget.id).update(budget.toMap());
  }

  Stream<List<BudgetModel>> watchFamilyBudgets({
    required String familyId,
    required String monthKey,
  }) {
    return _budgets
        .where('familyId', isEqualTo: familyId)
        .where('monthKey', isEqualTo: monthKey)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => BudgetModel.fromDoc(doc)).toList();
    });
  }

  Stream<List<ReminderModel>> watchFamilyReminders({
    required String familyId,
  }) {
    return _familyReminders(familyId).orderBy('dueDate').snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => ReminderModel.fromMap(doc.id, doc.data()))
            .toList();
      },
    );
  }

  Future<void> addReminder({
    required String familyId,
    required ReminderModel reminder,
  }) async {
    await _familyReminders(familyId).add(reminder.toMap());
  }

  Future<void> updateReminder({
    required String familyId,
    required ReminderModel reminder,
  }) async {
    if (reminder.id.isEmpty) {
      throw Exception('Reminder ID is required for update.');
    }

    await _familyReminders(familyId).doc(reminder.id).update(reminder.toMap());
  }

  Future<void> deleteReminder({
    required String familyId,
    required String reminderId,
  }) async {
    await _familyReminders(familyId).doc(reminderId).delete();
  }
}