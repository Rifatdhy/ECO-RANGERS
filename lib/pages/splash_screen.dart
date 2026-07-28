import 'package:eco_rangers/config.dart';
import 'package:eco_rangers/ui/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import '../locator.dart';
import '../services/auth_service.dart';
import 'auth_page.dart';
import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutQuart,
    ));

    _controller.forward();

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await dotenv.load(fileName: ".env");
    setupLocator();
    await ensureBaseUrl();

    final token = await AuthService.instance.getToken();
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      try {
        final user = await AuthService.instance.getMe();
        if (!mounted) return;
        if (user != null && user.isAdmin) {
          _navigate(const DashboardAdminPage());
        } else if (user != null) {
          _navigate(const DashboardUserPage());
        } else {
          _navigate(const AuthPage());
        }
      } catch (_) {
        _navigate(const AuthPage());
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) _navigate(const AuthPage());
    }
  }

  void _navigate(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.eco_outlined, size: 80, color: AppTheme.primaryColor),
                const SizedBox(height: 20),
                Text(
                  "Eco Rangers",
                  style: textTheme.headlineMedium?.copyWith(color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  "Lapor, Lacak, Lindungi.",
                  style: textTheme.bodyLarge?.copyWith(color: textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
