// lib/screens/family/family_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_spacing.dart';
import '../../providers/family_provider.dart';

class FamilySetupScreen extends ConsumerStatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  ConsumerState<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends ConsumerState<FamilySetupScreen> {
  final _createFormKey = GlobalKey<FormState>();
  final _joinFormKey = GlobalKey<FormState>();

  final _familyNameController = TextEditingController();
  final _familyCodeController = TextEditingController();

  bool _isCreateMode = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _familyNameController.dispose();
    _familyCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateGroup() async {
    if (!_createFormKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final code = await ref.read(familyServiceProvider).createFamilyGroup(
            familyName: _familyNameController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Family created successfully. Code: $code'),
          ),
        );

      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleJoinGroup() async {
    if (!_joinFormKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await ref.read(familyServiceProvider).joinFamilyGroupByCode(
            code: _familyCodeController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Joined family successfully.'),
          ),
        );

      context.go('/dashboard');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  String? _validateFamilyName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter a family name';
    }
    if (value.trim().length < 2) {
      return 'Family name is too short';
    }
    return null;
  }

  String? _validateFamilyCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter the family code';
    }
    if (value.trim().length < 6) {
      return 'Enter a valid code';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final cardColor = theme.cardColor;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            72,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Set up your family space',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Center(
                child: Text(
                  'Create a new family group or join an existing one with a code.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceSoft
                      : AppColors.lightSurfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _ModeButton(
                        label: 'Create Group',
                        isSelected: _isCreateMode,
                        onTap: () {
                          setState(() => _isCreateMode = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeButton(
                        label: 'Join Group',
                        isSelected: !_isCreateMode,
                        onTap: () {
                          setState(() => _isCreateMode = false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(AppRadii.xl),
                  border: Border.all(color: borderColor),
                ),
                child:
                    _isCreateMode ? _buildCreateForm(theme) : _buildJoinForm(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateForm(ThemeData theme) {
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create a family group',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'You will become the admin and receive a shareable family code.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _familyNameController,
            validator: _validateFamilyName,
            decoration: const InputDecoration(
              labelText: 'Family name',
              hintText: 'Enter your family name',
              prefixIcon: Icon(Icons.groups_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleCreateGroup,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Group'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinForm(ThemeData theme) {
    return Form(
      key: _joinFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Join with a family code',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Ask your family admin for the 6-character code.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            controller: _familyCodeController,
            validator: _validateFamilyCode,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Family code',
              hintText: 'Enter the code',
              prefixIcon: Icon(Icons.key_rounded),
            ),
            onChanged: (value) {
              final upper = value.toUpperCase();
              if (value != upper) {
                _familyCodeController.value = TextEditingValue(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleJoinGroup,
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Join Group'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isSelected ? Colors.white : null,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}