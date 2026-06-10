// lib/screens/expenses/add_expense_bottom_sheet.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_radii.dart';
import '../../constants/app_spacing.dart';
import '../../models/expense_model.dart';
import '../../providers/firestore_provider.dart';

class AddExpenseBottomSheet extends ConsumerStatefulWidget {
  const AddExpenseBottomSheet({
    super.key,
    required this.familyId,
    required this.payerName,
    required this.payerId,
  });

  final String familyId;
  final String payerName;
  final String payerId;

  @override
  ConsumerState<AddExpenseBottomSheet> createState() =>
      _AddExpenseBottomSheetState();
}

class _AddExpenseBottomSheetState
    extends ConsumerState<AddExpenseBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = 'Groceries';
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  final List<String> _categories = const [
    'Groceries',
    'Utilities',
    'School',
    'Transport',
    'Dining',
    'Health',
    'Entertainment',
    'Other',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text.trim());
      final currentUser = FirebaseAuth.instance.currentUser;

      final expense = ExpenseModel(
        id: '',
        familyId: widget.familyId,
        title: _titleController.text.trim(),
        category: _selectedCategory,
        amount: amount,
        date: Timestamp.fromDate(_selectedDate),
        payerId: widget.payerId,
        payerName: widget.payerName,
        splitMemberIds: [widget.payerId],
        createdBy: currentUser?.uid ?? widget.payerId,
        createdAt: Timestamp.now(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        receiptUrl: null,
        isRecurring: false,
      );

      await ref.read(firestoreServiceProvider).addExpense(expense);

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Expense added successfully.'),
          ),
        );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter expense title';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter amount';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Add Expense',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Save a new family expense.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _titleController,
                validator: _validateTitle,
                decoration: const InputDecoration(
                  labelText: 'Expense title',
                  hintText: 'Milk, bill, school fee',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _amountController,
                validator: _validateAmount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: 'Enter amount',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                  ),
                  child: Text(
                    _formatDate(_selectedDate),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Optional note',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
}