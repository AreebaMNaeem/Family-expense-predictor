// lib/screens/family/family_members_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_spacing.dart';
import '../../models/family_member_model.dart';
import '../../providers/dashboard_provider.dart';

class FamilyMembersScreen extends ConsumerWidget {
  const FamilyMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMemberAsync = ref.watch(currentFamilyMemberProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Family Members',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: currentMemberAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _CenteredMessage(
            message: 'Failed to load family member data.\n$error',
          ),
          data: (currentMember) {
            if (currentMember == null) {
              return const _CenteredMessage(
                message: 'No family profile found for this user.',
              );
            }

            final familyMembersAsync =
                ref.watch(familyMembersProvider(currentMember.familyId));

            return familyMembersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _CenteredMessage(
                message: 'Failed to load family members.\n$error',
              ),
              data: (members) {
                if (members.isEmpty) {
                  return const _CenteredMessage(
                    message: 'No family members found.',
                  );
                }

                final familyName = currentMember.familyName.trim().isEmpty
                    ? 'My Family'
                    : currentMember.familyName;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Family Group',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'See everyone connected to this family account.',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _FamilyNameBadge(familyName: familyName),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Text(
                            'Group Code: ${currentMember.familyCode}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          _RoleBadge(role: currentMember.role),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Members',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${members.length} total',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(AppRadii.xl),
                        ),
                        child: Column(
                          children: List.generate(
                            members.length,
                            (index) {
                              final familyMember = members[index];
                              final isLast = index == members.length - 1;

                              return _FamilyMemberRow(
                                member: familyMember,
                                isCurrentUser:
                                    familyMember.uid == currentMember.uid,
                                showDivider: !isLast,
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
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
            familyName,
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

class _FamilyMemberRow extends StatelessWidget {
  const _FamilyMemberRow({
    required this.member,
    required this.isCurrentUser,
    required this.showDivider,
  });

  final FamilyMemberModel member;
  final bool isCurrentUser;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        member.fullName.isEmpty ? 'Family Member' : member.fullName;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: isCurrentUser
                    ? const Color(0xFFE4F3EC)
                    : const Color(0xFFE8F0F3),
                child: Text(
                  _initials(displayName, member.email),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isCurrentUser
                        ? const Color(0xFF4F9A8B)
                        : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE4F3EC),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'You',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF4F9A8B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.email,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _RoleBadge(role: member.role),
            ],
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Divider(
              height: 1,
              color: Colors.black.withOpacity(0.06),
            ),
          ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({
    required this.role,
  });

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = role.toLowerCase() == 'admin';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isAdmin ? const Color(0xFFFFF1D6) : const Color(0xFFEAF1F5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Member',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: isAdmin ? const Color(0xFFB27D12) : const Color(0xFF47616F),
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

String _initials(String fullName, String email) {
  final parts = fullName.trim().split(' ').where((e) => e.isNotEmpty).toList();

  if (parts.isNotEmpty) {
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