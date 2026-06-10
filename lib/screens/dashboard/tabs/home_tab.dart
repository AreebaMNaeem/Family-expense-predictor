// lib/screens/dashboard/tabs/home_tab.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_radii.dart';
import '../../../constants/app_spacing.dart';
import '../../../models/budget_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/family_member_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/firestore_provider.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({
    super.key,
    required this.member,
  });

  final FamilyMemberModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthKey = _currentMonthKey();

    final expensesAsync = ref.watch(familyExpensesProvider(member.familyId));
    final budgetsAsync = ref.watch(
      familyBudgetsProvider(
        (familyId: member.familyId, monthKey: monthKey),
      ),
    );
    

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CenteredMessage(
        message: 'Failed to load expenses.\n$error',
      ),
      data: (expenses) {
        return budgetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CenteredMessage(
            message: 'Failed to load budgets.\n$error',
          ),
          data: (budgets) {
            final monthlyExpenses = _filterCurrentMonthExpenses(expenses);
            final myMonthlyExpenses = _filterMyExpenses(monthlyExpenses);
            final totalMonthlySpend = _sumExpenseAmounts(monthlyExpenses);
            final totalBudgetLimit = _sumBudgetLimits(budgets);
            final remainingBalance = (totalBudgetLimit - totalMonthlySpend)
                .clamp(0.0, double.infinity)
                .toDouble();
            final budgetProgress = totalBudgetLimit <= 0
                ? 0.0
                : (totalMonthlySpend / totalBudgetLimit)
                    .clamp(0.0, 1.0)
                    .toDouble();

            final monthlyBudget = budgets.isEmpty ? null : budgets.first;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                120,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${_firstName(member.fullName)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FamilyNameBadge(familyName: member.familyName),
                  const SizedBox(height: AppSpacing.lg),
                  _WalletCard(
                    availableBalance: remainingBalance,
                    familyCode: member.familyCode,
                    role: member.role,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BudgetHighlightCard(
                    totalBudgetLimit: totalBudgetLimit,
                    totalMonthlySpend: totalMonthlySpend,
                    progress: budgetProgress,
                    isAdmin: member.role == 'admin',
                    onBudgetTap: () => _openBudgetSheet(
                      context: context,
                      familyId: member.familyId,
                      existingBudget: monthlyBudget,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _GoalCard(
                    monthlyExpensesCount: myMonthlyExpenses.length,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Quick Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          icon: Icons.receipt_long_rounded,
                          value: myMonthlyExpenses.length.toString(),
                          label: 'My Expenses',
                          backgroundColor: isDark
                              ? const Color(0xFF2E3428)
                              : const Color(0xFFEBF0DE),
                          iconBackgroundColor: const Color(0xFFA0A85A),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MiniStatCard(
                          icon: Icons.pie_chart_rounded,
                          value:
                              '${(budgetProgress * 100).toStringAsFixed(0)}%',
                          label: 'Budget Used',
                          backgroundColor: isDark
                              ? const Color(0xFF26303A)
                              : const Color(0xFFDCE8F0),
                          iconBackgroundColor: const Color(0xFF6C99B2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStatCard(
                          icon: Icons.badge_rounded,
                          value: member.role == 'admin' ? 'Admin' : 'Member',
                          label: 'Role',
                          backgroundColor: isDark
                              ? const Color(0xFF342A35)
                              : const Color(0xFFE9E1EA),
                          iconBackgroundColor: const Color(0xFF8A6A87),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _MiniStatCard(
                          icon: Icons.account_balance_wallet_rounded,
                          value: _currency(_sumExpenseAmounts(myMonthlyExpenses)),
                          label: 'My Spend',
                          backgroundColor: isDark
                              ? const Color(0xFF1F3130)
                              : const Color(0xFFDDEBE6),
                          iconBackgroundColor: const Color(0xFF4F9A8B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Transactions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/expenses'),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (myMonthlyExpenses.isEmpty)
                    _EmptyTransactionsCard(isDark: isDark)
                  else
                    ...myMonthlyExpenses.take(4).map(
                          (expense) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _TransactionTile(expense: expense),
                          ),
                        ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openBudgetSheet({
    required BuildContext context,
    required String familyId,
    required BudgetModel? existingBudget,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      builder: (_) {
        return _BudgetSheet(
          familyId: familyId,
          memberUid: member.uid,
          existingBudget: existingBudget,
        );
      },
    );

    if (!context.mounted || result != true) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            existingBudget == null
                ? 'Budget set successfully.'
                : 'Budget updated successfully.',
          ),
        ),
      );
  }

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Member';
    return trimmed.split(' ').first;
  }

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

  List<ExpenseModel> _filterMyExpenses(List<ExpenseModel> expenses) {
    return expenses.where((expense) => expense.payerId == member.uid).toList();
  }

  double _sumExpenseAmounts(List<ExpenseModel> expenses) {
    return expenses.fold(0.0, (runningTotal, item) => runningTotal + item.amount);
  }

  double _sumBudgetLimits(List<BudgetModel> budgets) {
    return budgets.fold(
      0.0,
      (runningTotal, item) => runningTotal + item.limitAmount,
    );
  }
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet({
    required this.familyId,
    required this.memberUid,
    required this.existingBudget,
  });

  final String familyId;
  final String memberUid;
  final BudgetModel? existingBudget;

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.existingBudget == null
          ? ''
          : widget.existingBudget!.limitAmount.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final amount = double.parse(_controller.text.trim());

      final budget = BudgetModel(
        id: widget.existingBudget?.id ?? '',
        familyId: widget.familyId,
        category: 'monthly_total',
        limitAmount: amount,
        spentAmount: widget.existingBudget?.spentAmount ?? 0,
        monthKey: monthKey,
        createdBy: widget.memberUid,
        createdAt: widget.existingBudget?.createdAt ?? Timestamp.now(),
      );

      if (widget.existingBudget == null) {
        await ref.read(firestoreServiceProvider).addBudget(budget);
      } else {
        await ref.read(firestoreServiceProvider).updateBudget(budget);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.existingBudget == null ? 'Set Budget' : 'Update Budget',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Enter the family budget for this month.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter budget amount';
                  }
                  final parsed = double.tryParse(value.trim());
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Budget amount',
                  hintText: 'Enter monthly budget',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBudget,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.existingBudget == null
                              ? 'Save Budget'
                              : 'Update Budget',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _FamilyNameBadge extends StatelessWidget {
  const _FamilyNameBadge({
    required this.familyName,
  });

  final String familyName;

  @override
  Widget build(BuildContext context) {
    final displayName = familyName.trim().isEmpty ? 'My Family' : familyName;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0F3),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_rounded,
            size: 16,
            color: Color(0xFF6C99B2),
          ),
          const SizedBox(width: 8),
          Text(
            displayName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF47616F),
                ),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.availableBalance,
    required this.familyCode,
    required this.role,
  });

  final double availableBalance;
  final String familyCode;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3E5561),
            Color(0xFF324854),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -18,
            bottom: -10,
            child: Icon(
              Icons.auto_graph_rounded,
              size: 96,
              color: const Color(0xFFF8C63D).withOpacity(0.20),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Available balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                _currency(availableBalance),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 34,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    'Group $familyCode',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7C93E),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetHighlightCard extends StatelessWidget {
  const _BudgetHighlightCard({
    required this.totalBudgetLimit,
    required this.totalMonthlySpend,
    required this.progress,
    required this.isAdmin,
    required this.onBudgetTap,
  });

  final double totalBudgetLimit;
  final double totalMonthlySpend;
  final double progress;
  final bool isAdmin;
  final VoidCallback onBudgetTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = (totalBudgetLimit - totalMonthlySpend)
        .clamp(0.0, double.infinity)
        .toDouble();
    final hasBudget = totalBudgetLimit > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF97BED2),
            Color(0xFF7BA6BD),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget for this month',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        hasBudget
                            ? 'Spent ${_currency(totalMonthlySpend)}'
                            : 'No budget set yet',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      if (hasBudget) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Remaining ${_currency(remaining)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  _currency(totalBudgetLimit),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFDD33C),
              ),
            ),
          ),
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onBudgetTap,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF3E5561),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  hasBudget ? 'Update Budget' : 'Set Budget',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.monthlyExpensesCount,
  });

  final int monthlyExpensesCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My expense activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  monthlyExpensesCount == 0
                      ? 'Your personal expenses will start appearing here after you add one.'
                      : 'You added $monthlyExpensesCount expense(s) this month.',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF97BED2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.savings_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.backgroundColor,
    required this.iconBackgroundColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color backgroundColor;
  final Color iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconBackgroundColor,
            child: Icon(
              icon,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactionsCard extends StatelessWidget {
  const _EmptyTransactionsCard({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSoft : AppColors.lightSurfaceSoft,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 34,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No personal transactions yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your own added expenses will appear here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.expense,
  });

  final ExpenseModel expense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final date = expense.date?.toDate();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0F3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_bag_rounded,
              color: Color(0xFF7CA4B8),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title.isEmpty ? expense.category : expense.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category} • ${expense.payerName.isEmpty ? 'Unknown payer' : expense.payerName}',
                  style: theme.textTheme.bodyMedium,
                ),
                if (date != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _dateLabel(date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            _currency(expense.amount),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

String _currency(double value) {
  return 'Rs. ${value.toStringAsFixed(2)}';
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}