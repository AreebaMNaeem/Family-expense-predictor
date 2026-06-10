// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_radii.dart';
import '../../constants/app_spacing.dart';
import '../../models/ai_forecast_result_model.dart';
import '../../models/family_member_model.dart';
import '../../providers/ai_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../expenses/add_expense_bottom_sheet.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/home_tab.dart';
import 'tabs/profile_tab.dart';
import 'tabs/wallet_tab.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  Future<void> _openAddExpenseSheet(FamilyMemberModel member) async {
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
        return AddExpenseBottomSheet(
          familyId: member.familyId,
          payerId: member.uid,
          payerName: member.fullName.isEmpty ? member.email : member.fullName,
        );
      },
    );
  }

  Future<void> _openAiForecastSheet(
    BuildContext context,
    AsyncValue<AiForecastResultModel?> aiForecastAsync,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.xl),
        ),
      ),
      builder: (_) => _AiForecastBottomSheet(
        aiForecastAsync: aiForecastAsync,
      ),
    );
  }

  String _navTitle() {
    switch (_currentIndex) {
      case 1:
        return 'Calendar';
      case 3:
        return 'Wallet';
      case 4:
        return 'Profile';
      default:
        return 'Dashboard';
    }
  }

  Widget _buildCurrentTab(FamilyMemberModel member) {
    switch (_currentIndex) {
      case 1:
        return CalendarTab(member: member);
      case 3:
        return WalletTab(member: member);
      case 4:
        return ProfileTab(member: member);
      default:
        return HomeTab(member: member);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final memberAsync = ref.watch(currentFamilyMemberProvider);
    final aiForecastAsync = ref.watch(aiForecastProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _navTitle(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Icon(
            Icons.grid_view_rounded,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
        ),
      ),
      body: SafeArea(
        child: memberAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Failed to load dashboard.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (member) {
            if (member == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'No family profile found for this user.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return _buildCurrentTab(member);
          },
        ),
      ),
      bottomNavigationBar: memberAsync.when(
        data: (member) {
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              _DashboardBottomNav(
                currentIndex: _currentIndex,
                onTap: (index) {
                  if (index == 2 && member != null) {
                    _openAddExpenseSheet(member);
                    return;
                  }

                  setState(() => _currentIndex = index);
                },
              ),
              if (_currentIndex == 0)
                Positioned(
                  right: 20,
                  bottom: 86,
                  child: _AiForecastFloatingButton(
                    onTap: () => _openAiForecastSheet(context, aiForecastAsync),
                  ),
                ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }
}

class _AiForecastFloatingButton extends StatelessWidget {
  const _AiForecastFloatingButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFD233),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD233).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.auto_awesome_rounded,
                color: Colors.black87,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Forecast',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiForecastBottomSheet extends StatelessWidget {
  const _AiForecastBottomSheet({
    required this.aiForecastAsync,
  });

  final AsyncValue<AiForecastResultModel?> aiForecastAsync;

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
      child: aiForecastAsync.when(
        loading: () => SizedBox(
          height: 220,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Generating AI forecast...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        error: (error, _) => SizedBox(
          height: 220,
          child: Center(
            child: Text(
              'Failed to load AI forecast.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (result) {
          if (result == null) {
            return const SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  'No AI forecast available yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return SingleChildScrollView(
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
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF1B8),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'AI Forecast',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(AppRadii.xl),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currency(result.forecastAmount),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Predicted month-end family spending',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _AiInfoTile(
                  title: 'Insight',
                  value: result.insight,
                ),
                const SizedBox(height: AppSpacing.md),
                _AiInfoTile(
                  title: 'Warning',
                  value: result.warning,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AiInfoTile extends StatelessWidget {
  const _AiInfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _DashboardBottomNav extends StatelessWidget {
  const _DashboardBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        height: 90,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.calendar_today_outlined,
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFD233),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD233).withOpacity(0.45),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.black87,
                  size: 32,
                ),
              ),
            ),
            _NavItem(
              icon: Icons.account_balance_wallet_outlined,
              selected: currentIndex == 3,
              onTap: () => onTap(3),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              selected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          color: selected ? AppColors.primary : theme.textTheme.bodyMedium?.color,
        ),
      ),
    );
  }
}

String _currency(double value) {
  return 'Rs. ${value.toStringAsFixed(2)}';
}