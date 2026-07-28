import 'dart:ui';

import 'package:eco_rangers/ui/app_theme.dart';
import 'package:flutter/material.dart';

import '../locator.dart';
import '../services/auth_service.dart';
import 'dashboard_admin_page.dart';
import 'dashboard_user_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();

  final _registerNameController = TextEditingController();
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();

  bool _isLoading = false;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != _currentTabIndex) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerNameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = await locator<AuthService>().login(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text,
      );
      _handleLoginSuccess(user.isAdmin);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!_registerFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await locator<AuthService>().register(
        username: _registerNameController.text.trim(),
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );
      final user = await locator<AuthService>().login(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text,
      );
      _handleLoginSuccess(user.isAdmin);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _handleLoginSuccess(bool isAdmin) {
    if (!mounted) return;
    final pageRoute = MaterialPageRoute(
      builder: (_) => isAdmin ? const DashboardAdminPage() : const DashboardUserPage(),
    );
    Navigator.pushReplacement(context, pageRoute);
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.85, -0.95),
            radius: 1.25,
            colors: [
              AppTheme.industrialSteel.withValues(alpha: 0.45),
              AppTheme.industrialBlack,
              const Color(0xFF0D1016),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    return Material(
                      color: Colors.transparent,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 48,
                                  offset: const Offset(0, 28),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  blurRadius: 18,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(isWide ? 28 : 16),
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(flex: 11, child: _buildHeroPanel(context, isWide: true)),
                                        const SizedBox(width: 24),
                                        Expanded(flex: 10, child: _buildAuthCard(context, isWide: true)),
                                      ],
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildHeroPanel(context, isWide: false),
                                        const SizedBox(height: 16),
                                        _buildAuthCard(context, isWide: false),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroPanel(BuildContext context, {required bool isWide}) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 24 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.industrialBlack,
            AppTheme.industrialCharcoal,
            AppTheme.industrialSteel.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: isWide
          ? Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -12,
                  top: -12,
                  child: _OrbitBadge(
                    icon: Icons.construction_outlined,
                    label: 'Industrial flow',
                    accent: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                Positioned(
                  left: -18,
                  bottom: -18,
                  child: _OrbitBadge(
                    icon: Icons.shield_outlined,
                    label: 'Verified reports',
                    accent: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.eco_outlined, color: Colors.white, size: 34),
                    const SizedBox(height: 28),
                    Text(
                      'Satu layar untuk melaporkan masalah lingkungan.',
                      style: textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Masuk untuk memantau laporan, kirim foto kondisi lapangan, dan lanjutkan tindakan tanpa menunggu.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _FeaturePill(label: 'Foto + lokasi'),
                        _FeaturePill(label: 'Status laporan'),
                        _FeaturePill(label: 'Admin & warga'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Laporan yang lebih cepat dibaca.',
                                  style: textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Jalur masuk yang ringan, jelas, dan siap dipakai di lapangan.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.86),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.eco_outlined, color: Colors.white, size: 30),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _OrbitBadge(
                      icon: Icons.construction_outlined,
                      label: 'Industrial flow',
                      accent: Color.fromRGBO(255, 255, 255, 0.10),
                    ),
                    _OrbitBadge(
                      icon: Icons.shield_outlined,
                      label: 'Verified reports',
                      accent: Color.fromRGBO(255, 255, 255, 0.08),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Satu layar untuk melaporkan masalah lingkungan.',
                  style: textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.12,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Masuk untuk memantau laporan, kirim foto kondisi lapangan, dan lanjutkan tindakan tanpa menunggu.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _FeaturePill(label: 'Foto + lokasi'),
                    _FeaturePill(label: 'Status laporan'),
                    _FeaturePill(label: 'Admin & warga'),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporan yang lebih cepat dibaca.',
                              style: textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Jalur masuk yang ringan, jelas, dan siap dipakai di lapangan.',
                              style: textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAuthCard(BuildContext context, {required bool isWide}) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWide ? 24 : 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masuk ke Eco Rangers',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Kelola atau kirim laporan dalam beberapa langkah.',
            style: textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              labelColor: AppTheme.primaryColor,
              unselectedLabelColor: Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              tabs: const [
                Tab(text: 'Masuk'),
                Tab(text: 'Daftar'),
              ],
            ),
          ),
          const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _currentTabIndex == 0 ? _buildLoginForm(context) : _buildRegisterForm(context),
            ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _loginFormKey,
      child: Column(
        key: const ValueKey('login-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _loginEmailController,
            decoration: _fieldDecoration(
              label: 'Email',
              icon: Icons.alternate_email,
              hint: 'nama@contoh.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _loginPasswordController,
            decoration: _fieldDecoration(
              label: 'Password',
              icon: Icons.lock_outline,
              hint: 'Masukkan password Anda',
            ),
            obscureText: true,
            validator: (v) => (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Gunakan akun yang sudah terverifikasi.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _handleLogin,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey('login-loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Masuk',
                      key: ValueKey('login-text'),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Form(
      key: _registerFormKey,
      child: Column(
        key: const ValueKey('register-form'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _registerNameController,
            decoration: _fieldDecoration(
              label: 'Nama pengguna',
              icon: Icons.person_outline,
              hint: 'Nama tampilan Anda',
            ),
            validator: (v) => (v == null || v.trim().length < 3) ? 'Minimal 3 karakter' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _registerEmailController,
            decoration: _fieldDecoration(
              label: 'Email',
              icon: Icons.alternate_email,
              hint: 'nama@contoh.com',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (v) => (v == null || !v.contains('@')) ? 'Email tidak valid' : null,
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _registerPasswordController,
            decoration: _fieldDecoration(
              label: 'Password',
              icon: Icons.lock_outline,
              hint: 'Minimal 8 karakter',
            ),
            obscureText: true,
            validator: (v) => (v == null || v.length < 8) ? 'Minimal 8 karakter' : null,
          ),
          const SizedBox(height: 12),
          Text(
            'Akun baru langsung masuk ke alur laporan setelah registrasi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _handleRegister,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey('register-loading'),
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Buat akun',
                      key: ValueKey('register-text'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _OrbitBadge extends StatelessWidget {
  const _OrbitBadge({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}