// lib/screens/expenses/expense_history_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_spacing.dart';
import '../../models/budget_model.dart';
import '../../models/expense_model.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/firestore_provider.dart';
import 'edit_expense_bottom_sheet.dart';

class ExpenseHistoryScreen extends ConsumerWidget {
  const ExpenseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final memberAsync = ref.watch(currentFamilyMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'All Family Spendings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: memberAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CenteredMessage(
            message: 'Failed to load family data.\n$error',
          ),
          data: (member) {
            if (member == null) {
              return const _CenteredMessage(
                message: 'No family profile found for this user.',
              );
            }

            final monthKey = _currentMonthKey();
            final expensesAsync =
                ref.watch(familyExpensesProvider(member.familyId));
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
                    final totalSpent = _sumExpenseAmounts(monthlyExpenses);
                    final totalBudget = _sumBudgetLimits(budgets);
                    final remaining = (totalBudget - totalSpent)
                        .clamp(0.0, double.infinity)
                        .toDouble();
                    final progress = totalBudget <= 0
                        ? 0.0
                        : (totalSpent / totalBudget).clamp(0.0, 1.0).toDouble();

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        AppSpacing.xl,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Showing all family members\' expenses',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _TrendSection(
                            expenses: monthlyExpenses,
                            totalSpent: totalSpent,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _BudgetSummaryCard(
                            totalBudget: totalBudget,
                            totalSpent: totalSpent,
                            remaining: remaining,
                            progress: progress,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    isDark ? 0.12 : 0.04,
                                  ),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Family Expense List',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (monthlyExpenses.isEmpty)
                                  const _EmptyExpenseListCard()
                                else
                                  ...monthlyExpenses.map(
                                    (expense) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: AppSpacing.md,
                                      ),
                                      child: _ExpenseHistoryTile(
                                        expense: expense,
                                        canEdit: expense.payerId == member.uid ||
                                            expense.createdBy == member.uid,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
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
    }).toList()
      ..sort((a, b) {
        final aDate = a.date?.toDate() ?? DateTime(2000);
        final bDate = b.date?.toDate() ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
  }

  double _sumExpenseAmounts(List<ExpenseModel> expenses) {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  double _sumBudgetLimits(List<BudgetModel> budgets) {
    return budgets.fold(0.0, (sum, item) => sum + item.limitAmount);
  }
}

class _TrendSection extends StatelessWidget {
  const _TrendSection({
    required this.expenses,
    required this.totalSpent,
  });

  final List<ExpenseModel> expenses;
  final double totalSpent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final points = _buildTrendPoints(expenses);
    final highlightValue = totalSpent > 0 ? _currency(totalSpent) : 'Rs. 0.00';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _TrendChartPainter(
                      points: points,
                      isDark: isDark,
                    ),
                  ),
                ),
                if (points.isNotEmpty)
                  Positioned(
                    top: 38,
                    left: 110,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceSoft
                            : const Color(0xFF314854),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        highlightValue,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MonthTick(label: 'Jan'),
              _MonthTick(label: 'Feb'),
              _MonthTick(label: 'Mar'),
              _MonthTick(label: 'Apr'),
            ],
          ),
        ],
      ),
    );
  }

  List<double> _buildTrendPoints(List<ExpenseModel> expenses) {
    if (expenses.isEmpty) {
      return const [0.18, 0.22, 0.20, 0.28, 0.30, 0.36, 0.32, 0.40];
    }

    final now = DateTime.now();
    final monthlyTotals = <int, double>{1: 0, 2: 0, 3: 0, 4: 0};

    for (final expense in expenses) {
      final date = expense.date?.toDate();
      if (date == null) continue;
      final relative = 4 - (now.month - date.month);
      if (relative >= 1 && relative <= 4) {
        monthlyTotals[relative] = (monthlyTotals[relative] ?? 0) + expense.amount;
      }
    }

    final values = monthlyTotals.values.toList();
    final maxValue = values.fold<double>(0, math.max);
    if (maxValue <= 0) {
      return const [0.18, 0.22, 0.20, 0.28, 0.30, 0.36, 0.32, 0.40];
    }

    return [
      0.18,
      0.18 + (monthlyTotals[1]! / maxValue) * 0.30,
      0.18 + (monthlyTotals[2]! / maxValue) * 0.30,
      0.18 + (monthlyTotals[2]! / maxValue) * 0.34,
      0.18 + (monthlyTotals[3]! / maxValue) * 0.32,
      0.18 + (monthlyTotals[4]! / maxValue) * 0.38,
      0.22 + (monthlyTotals[4]! / maxValue) * 0.28,
      0.20 + (monthlyTotals[4]! / maxValue) * 0.26,
    ];
  }
}

class _BudgetSummaryCard extends StatelessWidget {
  const _BudgetSummaryCard({
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.progress,
  });

  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF314854),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Budget for ${_monthName(DateTime.now().month)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                _currency(totalBudget > 0 ? totalBudget : totalSpent),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
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
                Color(0xFFFFD233),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _BudgetMetric(
                  label: 'Spent',
                  value: _currency(totalSpent),
                ),
              ),
              Expanded(
                child: _BudgetMetric(
                  label: 'Remaining',
                  value: _currency(remaining),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return months[month - 1];
  }
}

class _BudgetMetric extends StatelessWidget {
  const _BudgetMetric({
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
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ExpenseHistoryTile extends ConsumerWidget {
  const _ExpenseHistoryTile({
    required this.expense,
    required this.canEdit,
  });

  final ExpenseModel expense;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _categoryAccent(expense.category);
    final bg = _categoryBackground(expense.category);

    final title = expense.title.trim().isEmpty ? expense.category : expense.title;
    final payer = expense.payerName.trim().isEmpty ? 'Family' : expense.payerName;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _categoryIcon(expense.category),
              color: accent,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dateLabel(expense.date?.toDate()),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currency(expense.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (canEdit) ...[
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => _openEditSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _confirmDelete(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD94D4D).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        size: 16,
                        color: Color(0xFFD94D4D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      builder: (context) {
        return EditExpenseBottomSheet(expense: expense);
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete Expense'),
              content: const Text(
                'Are you sure you want to delete this expense?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    await ref.read(firestoreServiceProvider).deleteExpense(
          expenseId: expense.id,
        );
  }
}

class _EmptyExpenseListCard extends StatelessWidget {
  const _EmptyExpenseListCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_rounded,
            size: 38,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No expenses this month',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add expenses to see them here.',
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

class _MonthTick extends StatelessWidget {
  const _MonthTick({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter({
    required this.points,
    required this.isDark,
  });

  final List<double> points;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = isDark ? AppColors.darkBorder : const Color(0xFFE8ECEF)
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final highlightPaint = Paint()
      ..color = const Color(0xFFF4E9C7).withOpacity(isDark ? 0.85 : 1.0)
      ..style = PaintingStyle.fill;

    final highlightRect = Rect.fromLTWH(
      size.width * 0.56,
      size.height * 0.12,
      size.width * 0.14,
      size.height * 0.76,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
      highlightPaint,
    );

    final path = Path();
    final dxStep = size.width / (points.length - 1);

    for (int i = 0; i < points.length; i++) {
      final x = i * dxStep;
      final normalized = points[i].clamp(0.08, 0.92);
      final y = size.height - (size.height * normalized);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevX = (i - 1) * dxStep;
        final prevY =
            size.height - (size.height * points[i - 1].clamp(0.08, 0.92));
        final controlX = (prevX + x) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
      }
    }

    final linePaint = Paint()
      ..color = const Color(0xFF9DBDCA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()
      ..color = isDark ? AppColors.primary : const Color(0xFF314854);

    final dotX = size.width * 0.66;
    final dotY = size.height * 0.34;
    canvas.drawCircle(Offset(dotX, dotY), 5.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.isDark != isDark;
  }
}

IconData _categoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'groceries':
      return Icons.shopping_bag_rounded;
    case 'utilities':
      return Icons.flash_on_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'transport':
      return Icons.directions_car_filled_rounded;
    case 'dining':
      return Icons.restaurant_rounded;
    case 'health':
      return Icons.favorite_rounded;
    case 'entertainment':
      return Icons.movie_rounded;
    default:
      return Icons.receipt_long_rounded;
  }
}

Color _categoryAccent(String category) {
  switch (category.toLowerCase()) {
    case 'groceries':
      return const Color(0xFF7CA4B8);
    case 'utilities':
      return const Color(0xFFE0B449);
    case 'school':
      return const Color(0xFF5C6FB2);
    case 'transport':
      return const Color(0xFF4F9A8B);
    case 'dining':
      return const Color(0xFF8A6A87);
    case 'health':
      return const Color(0xFFCC5C7A);
    case 'entertainment':
      return const Color(0xFF7B68CC);
    default:
      return AppColors.primary;
  }
}

Color _categoryBackground(String category) {
  switch (category.toLowerCase()) {
    case 'groceries':
      return const Color(0xFFE8F0F3);
    case 'utilities':
      return const Color(0xFFFFF1D6);
    case 'school':
      return const Color(0xFFE9ECFA);
    case 'transport':
      return const Color(0xFFE4F3EC);
    case 'dining':
      return const Color(0xFFF3E8F2);
    case 'health':
      return const Color(0xFFF9E3EA);
    case 'entertainment':
      return const Color(0xFFE9ECFA);
    default:
      return const Color(0xFFE8F0F3);
  }
}

String _currency(double value) {
  return 'Rs. ${value.toStringAsFixed(2)}';
}

String _dateLabel(DateTime? date) {
  if (date == null) return 'No date';

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
