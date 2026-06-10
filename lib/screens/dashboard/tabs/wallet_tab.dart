// lib/screens/dashboard/tabs/wallet_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_radii.dart';
import '../../../constants/app_spacing.dart';
import '../../../models/budget_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/family_member_model.dart';
import '../../../providers/dashboard_provider.dart';

class WalletTab extends ConsumerWidget {
  const WalletTab({
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
    final familyMembersAsync = ref.watch(familyMembersProvider(member.familyId));

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CenteredMessage(
        message: 'Failed to load wallet expenses.\n$error',
      ),
      data: (expenses) {
        return budgetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CenteredMessage(
            message: 'Failed to load wallet budgets.\n$error',
          ),
          data: (budgets) {
            return familyMembersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _CenteredMessage(
                message: 'Failed to load family members.\n$error',
              ),
              data: (familyMembers) {
                final monthlyExpenses = _filterCurrentMonthExpenses(expenses);
                final totalSpent = _sumExpenseAmounts(monthlyExpenses);
                final totalBudgetLimit = _sumBudgetLimits(budgets);
                final remainingBalance = (totalBudgetLimit - totalSpent)
                    .clamp(0.0, double.infinity)
                    .toDouble();

                final memberBalances = _memberBalances(
                  expenses: monthlyExpenses,
                  familyMembers: familyMembers,
                );

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
                        'Wallet Overview',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Track your family balance and member contributions.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _TotalBalanceCard(
                        totalBalance: remainingBalance,
                        totalSpent: totalSpent,
                        totalBudgetLimit: totalBudgetLimit,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Individual Member Balances',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (familyMembers.isEmpty)
                        const _EmptyStateCard(
                          title: 'No members found',
                          subtitle: 'Member balances will appear here.',
                        )
                      else
                        SizedBox(
                          height: 170,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: familyMembers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.md),
                            itemBuilder: (context, index) {
                              final familyMember = familyMembers[index];
                              final amount =
                                  memberBalances[familyMember.uid] ?? 0.0;

                              return _MemberBalanceBubble(
                                member: familyMember,
                                amount: amount,
                                bubbleColor: _memberBubbleColor(index, isDark),
                                textColor: _memberTextColor(index, isDark),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Monthly Budget Limit',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _MonthlyBudgetLimitCard(
                        totalBudgetLimit: totalBudgetLimit,
                        totalSpent: totalSpent,
                        remainingBalance: remainingBalance,
                        isDark: isDark,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
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

  double _sumExpenseAmounts(List<ExpenseModel> expenses) {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double _sumBudgetLimits(List<BudgetModel> budgets) {
    return budgets.fold(0.0, (sum, item) => sum + item.limitAmount);
  }

  Map<String, double> _memberBalances({
    required List<ExpenseModel> expenses,
    required List<FamilyMemberModel> familyMembers,
  }) {
    final balances = <String, double>{
      for (final member in familyMembers) member.uid: 0.0,
    };

    for (final expense in expenses) {
      balances.update(
        expense.payerId,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return balances;
  }

  Color _memberBubbleColor(int index, bool isDark) {
    final lightColors = <Color>[
      const Color(0xFFE7F0F3),
      const Color(0xFFF3E8F2),
      const Color(0xFFEBF0DE),
      const Color(0xFFFFF1D6),
      const Color(0xFFE4F3EC),
      const Color(0xFFE9ECFA),
    ];

    final darkColors = <Color>[
      const Color(0xFF25343A),
      const Color(0xFF3A2D39),
      const Color(0xFF343A27),
      const Color(0xFF3D3426),
      const Color(0xFF233831),
      const Color(0xFF2C3140),
    ];

    final colors = isDark ? darkColors : lightColors;
    return colors[index % colors.length];
  }

  Color _memberTextColor(int index, bool isDark) {
    final lightColors = <Color>[
      const Color(0xFF486675),
      const Color(0xFF7A5C76),
      const Color(0xFF7C8540),
      const Color(0xFFA97816),
      const Color(0xFF3E8A6B),
      const Color(0xFF5C6FB2),
    ];

    final darkColors = <Color>[
      const Color(0xFF9BC1D2),
      const Color(0xFFD2A9CD),
      const Color(0xFFD0D68A),
      const Color(0xFFECCB74),
      const Color(0xFF8FD2B8),
      const Color(0xFFAEBBEE),
    ];

    final colors = isDark ? darkColors : lightColors;
    return colors[index % colors.length];
  }
}

class _TotalBalanceCard extends StatelessWidget {
  const _TotalBalanceCard({
    required this.totalBalance,
    required this.totalSpent,
    required this.totalBudgetLimit,
  });

  final double totalBalance;
  final double totalSpent;
  final double totalBudgetLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.xl),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6FAFC1),
            Color(0xFF3E5561),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Family Total Balance',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _currency(totalBalance),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  label: 'Spent',
                  value: _currency(totalSpent),
                ),
              ),
              Expanded(
                child: _BalanceMetric(
                  label: 'Budget',
                  value: _currency(totalBudgetLimit),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MemberBalanceBubble extends StatelessWidget {
  const _MemberBalanceBubble({
    required this.member,
    required this.amount,
    required this.bubbleColor,
    required this.textColor,
  });

  final FamilyMemberModel member;
  final double amount;
  final Color bubbleColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _initials(member.fullName, member.email);

    return SizedBox(
      width: 108,
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bubbleColor,
            ),
            child: Center(
              child: Text(
                initials,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            member.fullName.isEmpty ? member.email : member.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currency(amount),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String fullName, String email) {
    final trimmed = fullName.trim();

    if (trimmed.isNotEmpty) {
      final parts = trimmed.split(' ');
      if (parts.length == 1) {
        return parts.first.substring(0, 1).toUpperCase();
      }
      return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
          .toUpperCase();
    }

    return email.isNotEmpty ? email.substring(0, 1).toUpperCase() : 'F';
  }
}

class _MonthlyBudgetLimitCard extends StatelessWidget {
  const _MonthlyBudgetLimitCard({
    required this.totalBudgetLimit,
    required this.totalSpent,
    required this.remainingBalance,
    required this.isDark,
  });

  final double totalBudgetLimit;
  final double totalSpent;
  final double remainingBalance;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalBudgetLimit <= 0
        ? 0.0
        : (totalSpent / totalBudgetLimit).clamp(0.0, 1.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF4F8FA),
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Budget Limit',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _BudgetInfoItem(
                  label: 'Monthly Limit',
                  value: _currency(totalBudgetLimit),
                ),
              ),
              Expanded(
                child: _BudgetInfoItem(
                  label: 'Spent',
                  value: _currency(totalSpent),
                ),
              ),
              Expanded(
                child: _BudgetInfoItem(
                  label: 'Remaining',
                  value: _currency(remainingBalance),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.black.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD233),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetInfoItem extends StatelessWidget {
  const _BudgetInfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
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

String _currency(double value) {
  return 'Rs. ${value.toStringAsFixed(2)}';
}