import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_radii.dart';
import '../../../constants/app_spacing.dart';
import '../../../models/family_member_model.dart';
import '../../../providers/theme_provider.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({
    super.key,
    required this.member,
  });

  final FamilyMemberModel member;

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    final backgroundTop =
        isDark ? const Color(0xFF234047) : const Color(0xFF9FD4D0);

    final cardColor = theme.cardColor;
    final isDarkEnabled = themeMode == ThemeMode.dark;

    return SingleChildScrollView(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _ProfileHeaderBackground(
                color: backgroundTop,
                onFamilyMembersTap: () => context.push('/family-members'),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -52,
                child: Center(
                  child: _ProfileAvatar(
                    initials: _initials(member.fullName, member.email),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 70),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                Text(
                  member.fullName.isEmpty ? 'Family Member' : member.fullName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Column(
                    children: [
                      _ProfileInfoRow(
                        icon: Icons.person_rounded,
                        label: 'Full Name',
                        value: member.fullName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProfileInfoRow(
                        icon: Icons.groups_rounded,
                        label: 'Family Name',
                        value: member.familyName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProfileInfoRow(
                        icon: Icons.key_rounded,
                        label: 'Family Code',
                        value: member.familyCode,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProfileInfoRow(
                        icon: Icons.badge_rounded,
                        label: 'Role',
                        value: member.role.toUpperCase(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ProfileInfoRow(
                        icon: Icons.email_rounded,
                        label: 'E-Mail',
                        value: member.email,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceSoft
                        : AppColors.lightSurfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shield_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Family Access',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              member.role == 'admin'
                                  ? 'You manage this family workspace.'
                                  : 'You are linked as a family member.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
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
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDarkEnabled
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isDarkEnabled
                                  ? 'Dark theme is enabled'
                                  : 'Light theme is enabled',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: isDarkEnabled,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).state =
                              value ? ThemeMode.dark : ThemeMode.light;
                        },
                        activeColor: AppColors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => _logout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE5E5),
                      foregroundColor: const Color(0xFFD94D4D),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                      ),
                    ),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFD94D4D),
                    ),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Color(0xFFD94D4D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
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

    if (email.isNotEmpty) {
      return email.substring(0, 1).toUpperCase();
    }

    return 'F';
  }
}

class _ProfileHeaderBackground extends StatelessWidget {
  const _ProfileHeaderBackground({
    required this.color,
    required this.onFamilyMembersTap,
  });

  final Color color;
  final VoidCallback onFamilyMembersTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(44),
          bottomRight: Radius.circular(44),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -30,
            top: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -10,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 18,
            right: 18,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onFamilyMembersTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Members',
                        style: TextStyle(
                          color: Color(0xFF2F4A56),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFFE8F0F3),
        ),
        child: Center(
          child: Text(
            initials,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceSoft : const Color(0xFFF3F7F8),
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '-' : value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}