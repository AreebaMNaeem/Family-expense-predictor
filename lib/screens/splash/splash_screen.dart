// lib/screens/splash/splash_screen.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_spacing.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final AnimationController _floatController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<Offset> _titleOffset;
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _subtitleOffset;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _buttonOffset;
  late final Animation<double> _buttonOpacity;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.78, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.00, 0.35, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.00, 0.28, curve: Curves.easeOut),
      ),
    );

    _titleOffset = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.22, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.20, 0.52, curve: Curves.easeOut),
      ),
    );

    _subtitleOffset = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.34, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.34, 0.66, curve: Curves.easeOut),
      ),
    );

    _buttonOffset = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.54, 1.00, curve: Curves.easeOutCubic),
      ),
    );

    _buttonOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.56, 0.95, curve: Curves.easeOut),
      ),
    );

    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_mainController, _floatController]),
        builder: (context, _) {
          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF7FBFC),
                  Color(0xFFEAF4F5),
                  Color(0xFFF8F6F1),
                ],
              ),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  _FloatingCircle(
                    top: -40,
                    left: -30,
                    size: 150,
                    color: const Color(0x339FD4D0),
                    offsetY: 12 * math.sin(_floatController.value * math.pi),
                  ),
                  _FloatingCircle(
                    top: 90,
                    right: -35,
                    size: 120,
                    color: const Color(0x22A8D5BA),
                    offsetY: -10 * math.sin(_floatController.value * math.pi),
                  ),
                  _FloatingCircle(
                    bottom: 140,
                    left: -45,
                    size: 130,
                    color: const Color(0x22FFD76A),
                    offsetY: 8 * math.sin(_floatController.value * math.pi),
                  ),
                  _FloatingCircle(
                    bottom: 40,
                    right: -20,
                    size: 100,
                    color: const Color(0x229FD4D0),
                    offsetY: -8 * math.sin(_floatController.value * math.pi),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        FadeTransition(
                          opacity: _logoOpacity,
                          child: ScaleTransition(
                            scale: _logoScale,
                            child: Container(
                              width: 170,
                              height: 170,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.88),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF9FD4D0)
                                        .withOpacity(0.24),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 12),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/logowhite.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        FadeTransition(
                          opacity: _titleOpacity,
                          child: SlideTransition(
                            position: _titleOffset,
                            child: Text(
                              'FamForecast',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.9,
                                color: const Color(0xFF233742),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        FadeTransition(
                          opacity: _subtitleOpacity,
                          child: SlideTransition(
                            position: _subtitleOffset,
                            child: Text(
                              'Smart family expense tracking with a clean, calm experience.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                height: 1.45,
                                color: const Color(0xFF667B86),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        FadeTransition(
                          opacity: _buttonOpacity,
                          child: SlideTransition(
                            position: _buttonOffset,
                            child: Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7CA4B8)
                                              .withOpacity(0.28),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () => context.go('/login'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF7CA4B8),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Get Started',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.arrow_forward_rounded),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Manage better. Spend smarter.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF7A8E97),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FloatingCircle extends StatelessWidget {
  const _FloatingCircle({
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.color,
    required this.offsetY,
  });

  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final Color color;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top != null ? top! + offsetY : null,
      left: left,
      right: right,
      bottom: bottom != null ? bottom! - offsetY : null,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}