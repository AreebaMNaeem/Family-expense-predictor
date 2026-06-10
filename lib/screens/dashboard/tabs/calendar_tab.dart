import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_radii.dart';
import '../../../constants/app_spacing.dart';
import '../../../models/budget_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/family_member_model.dart';
import '../../../models/reminder_model.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/firestore_provider.dart';
import '../../../providers/reminder_provider.dart';

class CalendarTab extends ConsumerWidget {
  const CalendarTab({
    super.key,
    required this.member,
  });

  final FamilyMemberModel member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    final expensesAsync = ref.watch(familyExpensesProvider(member.familyId));
    final budgetsAsync = ref.watch(
      familyBudgetsProvider(
        (familyId: member.familyId, monthKey: monthKey),
      ),
    );
    final remindersAsync = ref.watch(familyRemindersProvider(member.familyId));

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _CalendarErrorView(
        message: 'Failed to load calendar.\n$error',
      ),
      data: (expenses) {
        return budgetsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CalendarErrorView(
            message: 'Failed to load budgets.\n$error',
          ),
          data: (budgets) {
            final monthlyExpenses = _filterCurrentMonthExpenses(expenses);
            final totalSpent = _sumExpenseAmounts(monthlyExpenses);
            final totalBudget = _sumBudgetLimits(budgets);
            final budgetRatio = totalBudget <= 0
                ? 0.0
                : (totalSpent / totalBudget).clamp(0.0, 2.0);

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
                    'Calendar Overview',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Track budget alerts and family reminders.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _MonthHeaderCard(monthLabel: _monthLabel(now)),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'Budget Alerts',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BudgetAlertOverviewCard(
                    totalSpent: totalSpent,
                    totalBudget: totalBudget,
                    progress: budgetRatio,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _BudgetAlertChips(
                    budgetRatio: budgetRatio,
                    totalBudget: totalBudget,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Upcoming Reminders',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _AddReminderButton(familyId: member.familyId),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Tap Add to create reminders for important family payments.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  remindersAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => _CalendarErrorView(
                      message: 'Could not load reminders.\n$error',
                    ),
                    data: (reminders) {
                      if (reminders.isEmpty) {
                        return _EmptyRemindersWidget(
                          familyId: member.familyId,
                        );
                      }

                      return Column(
                        children: reminders
                            .map(
                              (reminder) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.md),
                                child: _ManualReminderTile(
                                  reminder: reminder,
                                  familyId: member.familyId,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AddReminderButton extends StatelessWidget {
  const _AddReminderButton({
    required this.familyId,
  });

  final String familyId;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showReminderSheet(context, familyId),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.24),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showReminderSheet(
  BuildContext context,
  String familyId, {
  ReminderModel? existing,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReminderFormSheet(
      familyId: familyId,
      existing: existing,
    ),
  );
}

class _ReminderFormSheet extends ConsumerStatefulWidget {
  const _ReminderFormSheet({
    required this.familyId,
    this.existing,
  });

  final String familyId;
  final ReminderModel? existing;

  @override
  ConsumerState<_ReminderFormSheet> createState() => _ReminderFormSheetState();
}

class _ReminderFormSheetState extends ConsumerState<_ReminderFormSheet> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _amountController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _isSaving = false;
  late ReminderIconOption _selectedIcon;

  @override
  void initState() {
    super.initState();
    final options = _reminderIconOptions;
    _selectedIcon = options.first;

    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing.title;
      _subtitleController.text = existing.subtitle;
      _amountController.text = existing.amount.toStringAsFixed(0);
      _dueDate = existing.dueDate;
      _selectedIcon = options.firstWhere(
        (option) => option.icon.codePoint == existing.iconCodePoint,
        orElse: () => options.last,
      );
    }
  }

  List<ReminderIconOption> get _reminderIconOptions =>
      ref.read(reminderIconOptionsProvider);

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (title.isEmpty || amount == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Please fill title and amount.')),
        );
      return;
    }

    setState(() => _isSaving = true);

    final reminder = ReminderModel(
      id: widget.existing?.id ?? '',
      title: title,
      subtitle: _subtitleController.text.trim(),
      dueDate: _dueDate,
      amount: amount,
      iconCodePoint: _selectedIcon.icon.codePoint,
      accentColor: _selectedIcon.accent,
      backgroundColorValue: _selectedIcon.background,
    );

    try {
      final service = ref.read(firestoreServiceProvider);

      if (widget.existing != null) {
        await service.updateReminder(
          familyId: widget.familyId,
          reminder: reminder,
        );
      } else {
        await service.addReminder(
          familyId: widget.familyId,
          reminder: reminder,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final softSurface =
        isDark ? AppColors.darkSurfaceSoft : AppColors.lightSurfaceSoft;
    final mutedBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.existing != null ? 'Edit Reminder' : 'Add Reminder',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Category',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _reminderIconOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, index) {
                      final option = _reminderIconOptions[index];
                      final selected = option == _selectedIcon;

                      return InkWell(
                        onTap: () => setState(() => _selectedIcon = option),
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 62,
                          decoration: BoxDecoration(
                            color: selected
                                ? Color(option.background)
                                : softSurface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? Color(option.accent)
                                  : mutedBorder,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                option.icon,
                                color: Color(option.accent),
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                child: Text(
                                  option.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: Color(option.accent),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _FormField(
                  label: 'Title',
                  controller: _titleController,
                  hint: 'e.g. School Fee',
                ),
                const SizedBox(height: 12),
                _FormField(
                  label: 'Note (optional)',
                  controller: _subtitleController,
                  hint: 'e.g. Due for children this month',
                ),
                const SizedBox(height: 12),
                _FormField(
                  label: 'Amount (Rs.)',
                  controller: _amountController,
                  hint: 'e.g. 12000',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                Text(
                  'Due Date',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: softSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mutedBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _dateLabel(_dueDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.existing != null
                                      ? 'Save Changes'
                                      : 'Add Reminder',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final softSurface =
        isDark ? AppColors.darkSurfaceSoft : AppColors.lightSurfaceSoft;
    final mutedBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium,
            filled: true,
            fillColor: softSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mutedBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: mutedBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ManualReminderTile extends StatelessWidget {
  const _ManualReminderTile({
    required this.reminder,
    required this.familyId,
  });

  final ReminderModel reminder;
  final String familyId;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(firestoreServiceProvider).deleteReminder(
            familyId: familyId,
            reminderId: reminder.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer(
      builder: (context, ref, _) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(AppRadii.xl),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: reminder.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  reminder.icon,
                  color: reminder.accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (reminder.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.subtitle,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _dueLabel(reminder.dueDate),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _dueLabelColor(reminder.dueDate),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currency(reminder.amount),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dateLabel(reminder.dueDate),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _showReminderSheet(
                          context,
                          familyId,
                          existing: reminder,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
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
                        onTap: () => _delete(context, ref),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD94D4D).withOpacity(0.1),
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _dueLabelColor(DateTime date) {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDue = DateTime(date.year, date.month, date.day);
    final diff = normalizedDue.difference(normalizedToday).inDays;

    if (diff < 0) return const Color(0xFFD94D4D);
    if (diff <= 3) return const Color(0xFFE0B449);
    return const Color(0xFF4F9A8B);
  }
}

class _EmptyRemindersWidget extends StatelessWidget {
  const _EmptyRemindersWidget({
    required this.familyId,
  });

  final String familyId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 52,
            color: isDark ? AppColors.darkTextSecondary : Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'No reminders yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? null : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap Add to create reminders for your family payments.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: () => _showReminderSheet(context, familyId),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                '+ Add First Reminder',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarErrorView extends StatelessWidget {
  const _CalendarErrorView({
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

class _MonthHeaderCard extends StatelessWidget {
  const _MonthHeaderCard({
    required this.monthLabel,
  });

  final String monthLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  monthLabel,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Budget alerts and reminder planner',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceSoft
                  : const Color(0xFFEAF3F8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'This month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertOverviewCard extends StatelessWidget {
  const _BudgetAlertOverviewCard({
    required this.totalSpent,
    required this.totalBudget,
    required this.progress,
  });

  final double totalSpent;
  final double totalBudget;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final safeProgress = progress.clamp(0.0, 1.0);
    final percent = (safeProgress * 100).toStringAsFixed(0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
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
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: CircularProgressIndicator(
                    value: safeProgress,
                    strokeWidth: 16,
                    backgroundColor: isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE8ECEF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      safeProgress >= 1
                          ? const Color(0xFFD94D4D)
                          : safeProgress >= 0.9
                              ? const Color(0xFFE0B449)
                              : const Color(0xFF4F9A8B),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Budget Used',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$percent%',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _currency(totalSpent),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceSoft : const Color(0xFF202225),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _BottomLegend(color: Color(0xFF4F9A8B), label: '80%'),
                _BottomLegend(color: Color(0xFFE0B449), label: '90%'),
                _BottomLegend(color: Color(0xFFD94D4D), label: '100%'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _MiniBudgetInfo(
                  label: 'Spent',
                  value: _currency(totalSpent),
                ),
              ),
              Expanded(
                child: _MiniBudgetInfo(
                  label: 'Budget',
                  value: totalBudget > 0 ? _currency(totalBudget) : 'Not set',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetAlertChips extends StatelessWidget {
  const _BudgetAlertChips({
    required this.budgetRatio,
    required this.totalBudget,
  });

  final double budgetRatio;
  final double totalBudget;

  @override
  Widget build(BuildContext context) {
    final alerts = <_AlertChipData>[];

    if (totalBudget <= 0) {
      alerts.add(
        const _AlertChipData(
          label: 'No monthly budget set',
          color: Color(0xFF8A6A87),
        ),
      );
    } else {
      if (budgetRatio >= 0.8) {
        alerts.add(
          const _AlertChipData(
            label: '80% budget reached',
            color: Color(0xFF4F9A8B),
          ),
        );
      }
      if (budgetRatio >= 0.9) {
        alerts.add(
          const _AlertChipData(
            label: '90% budget reached',
            color: Color(0xFFE0B449),
          ),
        );
      }
      if (budgetRatio >= 1.0) {
        alerts.add(
          const _AlertChipData(
            label: 'Budget exceeded',
            color: Color(0xFFD94D4D),
          ),
        );
      }
      if (alerts.isEmpty) {
        alerts.add(
          const _AlertChipData(
            label: 'Budget is in safe range',
            color: Color(0xFF6C99B2),
          ),
        );
      }
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: alerts
          .map(
            (alert) => Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: alert.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                alert.label,
                style: TextStyle(
                  color: alert.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MiniBudgetInfo extends StatelessWidget {
  const _MiniBudgetInfo({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BottomLegend extends StatelessWidget {
  const _BottomLegend({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AlertChipData {
  const _AlertChipData({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;
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
  return expenses.fold(0.0, (total, item) => total + item.amount);
}

double _sumBudgetLimits(List<BudgetModel> budgets) {
  return budgets.fold(0.0, (total, item) => total + item.limitAmount);
}

String _currency(double value) => 'Rs. ${value.toStringAsFixed(2)}';

String _monthLabel(DateTime date) {
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
  return '${months[date.month - 1]} ${date.year}';
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

String _dueLabel(DateTime date) {
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final normalizedDue = DateTime(date.year, date.month, date.day);
  final diff = normalizedDue.difference(normalizedToday).inDays;

  if (diff < 0) return 'Overdue by ${diff.abs()} day(s)';
  if (diff == 0) return 'Due today';
  if (diff == 1) return 'Due tomorrow';
  return 'Due in $diff day(s)';
}