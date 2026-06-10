// lib/providers/ai_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/ai_forecast_result_model.dart';
import '../models/budget_model.dart';
import '../models/expense_model.dart';
import '../services/ai_service.dart';
import 'dashboard_provider.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

final aiForecastProvider = FutureProvider<AiForecastResultModel?>((ref) async {
  final member = await ref.watch(currentFamilyMemberProvider.future);

  if (member == null) {
    return null;
  }

  final expenses = await ref.watch(
    familyExpensesProvider(member.familyId).future,
  );

  final monthKey = _currentMonthKey();

  final budgets = await ref.watch(
    familyBudgetsProvider(
      (familyId: member.familyId, monthKey: monthKey),
    ).future,
  );

  final monthlyExpenses = _filterCurrentMonthExpenses(expenses);
  final currentSpend = _sumExpenseAmounts(monthlyExpenses);
  final monthlyBudget = _sumBudgetLimits(budgets);
  final categoryTotals = _buildCategoryTotals(monthlyExpenses);
  final recentExpenses = _buildRecentExpenses(monthlyExpenses);

  return ref.read(aiServiceProvider).generateForecast(
        monthlyBudget: monthlyBudget,
        currentSpend: currentSpend,
        categoryTotals: categoryTotals,
        recentExpenses: recentExpenses,
      );
});

String _currentMonthKey() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  return '${now.year}-$month';
}

List<ExpenseModel> _filterCurrentMonthExpenses(List<ExpenseModel> expenses) {
  final now = DateTime.now();

  return expenses.where((expense) {
    final timestamp = expense.date;
    if (timestamp == null) return false;
    final date = timestamp.toDate();
    return date.year == now.year && date.month == now.month;
  }).toList();
}

double _sumExpenseAmounts(List<ExpenseModel> expenses) {
  return expenses.fold(0.0, (sum, item) => sum + item.amount);
}

double _sumBudgetLimits(List<BudgetModel> budgets) {
  return budgets.fold(0.0, (sum, item) => sum + item.limitAmount);
}

Map<String, double> _buildCategoryTotals(List<ExpenseModel> expenses) {
  final totals = <String, double>{};

  for (final expense in expenses) {
    totals.update(
      expense.category,
      (value) => value + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }

  final sortedEntries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return {
    for (final entry in sortedEntries.take(5)) entry.key: entry.value,
  };
}

List<Map<String, dynamic>> _buildRecentExpenses(List<ExpenseModel> expenses) {
  final sorted = [...expenses]
    ..sort((a, b) {
      final aDate = a.date?.toDate() ?? DateTime(2000);
      final bDate = b.date?.toDate() ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });

  return sorted.take(5).map((expense) {
    return {
      'title': expense.title,
      'category': expense.category,
      'amount': expense.amount,
      'payerName': expense.payerName,
    };
  }).toList();
}