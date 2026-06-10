// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:family_expense_predictor/firebase_options.dart';
import 'package:family_expense_predictor/screens/auth/login_screen.dart';
import 'package:family_expense_predictor/screens/auth/register_screen.dart';
import 'package:family_expense_predictor/screens/family/family_setup_screen.dart';
import 'package:family_expense_predictor/screens/dashboard/dashboard_screen.dart';
import 'package:family_expense_predictor/screens/splash/splash_screen.dart';
import 'package:family_expense_predictor/screens/expenses/expense_history_screen.dart';
import 'package:family_expense_predictor/theme/app_theme.dart';
import 'package:family_expense_predictor/screens/family/family_members_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:family_expense_predictor/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/family-setup',
      builder: (context, state) => const FamilySetupScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const ExpenseHistoryScreen(),
    ),
    GoRoute(
      path: '/family-members',
      builder: (context, state) => const FamilyMembersScreen(),
  ),
  ],
);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'FamForecast',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
    );
  }
}
