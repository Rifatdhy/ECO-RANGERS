import 'package:eco_rangers/ui/app_theme.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'auth_page.dart';
import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Timer? _timer;

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

    _timer = Timer(
      const Duration(seconds: 3),
      () => _navigate(),
    );
  }

  Future<void> _navigate() async {
    if (!mounted) return;
    Widget page = const AuthPage();

    final user = await AuthService.instance.getMe();
    if (mounted) {
      if (user != null) {
        page = user.isAdmin ? const DashboardAdminPage() : const DashboardUserPage();
      }
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                  // FIX: Menggunakan warna dari tema konteks
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
