import 'dart:ui';
import 'package:flutter/material.dart';
import '../locator.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import 'dashboard_admin_page.dart';
import 'main_shell.dart';

/// AuthPage bergaya Apple Luxury ID Portal:
/// Glassmorphism hero dengan botanical gradient yang megah,
/// segment tab mulus tanpa flicker, form field ultra-clean,
/// dan transisi masuk yang effortless.
class AuthPage extends StatefulWidget {
  final bool initialIsRegister;

  const AuthPage({super.key, this.initialIsRegister = false});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final AuthService _authService = locator<AuthService>();

  late bool _isRegister;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
    // Default testing fill untuk kemudahan review cepat
    _emailController.text = 'admin@gmail.com';
    _passwordController.text = '12345678';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegister) {
        await _authService.register(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await _authService.login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }

      final user = await _authService.getMe();
      if (!mounted) return;

      if (user?.isAdmin == true) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardAdminPage()),
          (route) => false,
        );
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShell()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Botanical Glow
          Positioned(
            top: -100,
            right: -80,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? const Color(0xFF1B4D36) : AppColors.sand).withValues(alpha: 0.35),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Apple Brand Signature
                      Center(
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            gradient: AppColors.luxuryBrandGradient,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.forest.withValues(alpha: 0.28),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1.5,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.park_rounded,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'ECO RANGERS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: isDark ? const Color(0xFF74C69D) : AppColors.sage,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRegister ? 'Buat Akun Baru' : 'Selamat Datang',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isRegister
                            ? 'Daftar untuk mulai mengawal dan menjaga lingkungan bersama warga.'
                            : 'Masuk ke portal civic tech untuk memantau status laporan Anda.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13.5,
                          color: isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Segment Switcher (Apple Segment Control Style)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF14201A) : AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                          ),
                        ),
                        child: Row(
                          children: [
                            _segmentButton('Masuk', !_isRegister, () {
                              if (_isRegister) setState(() => _isRegister = false);
                            }, isDark),
                            _segmentButton('Daftar', _isRegister, () {
                              if (!_isRegister) setState(() => _isRegister = true);
                            }, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Card Form Container
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                          ),
                          boxShadow: AppShadows.luxuryCard,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.ditolakBg,
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                    border: Border.all(color: AppColors.ditolakBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.ditolakText),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                            color: AppColors.ditolakText,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              if (_isRegister) ...[
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                                    hintText: 'Minimal 3 karakter',
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().length < 3) {
                                      return 'Username minimal 3 karakter';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],

                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Alamat Email',
                                  prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                                  hintText: 'nama@domain.com',
                                ),
                                validator: (v) {
                                  if (v == null || !v.contains('@') || !v.contains('.')) {
                                    return 'Format email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Kata Sandi',
                                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.length < 8) {
                                    return 'Password minimal 8 karakter';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),

                              // Submit Action Button
                              ElevatedButton(
                                onPressed: _isLoading ? null : _submit,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(_isRegister ? 'Daftar Sekarang' : 'Masuk ke Aplikasi'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Quick Helper
                      Center(
                        child: Text(
                          'Eco Rangers Civic Technology Platform • 2026',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
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

  Widget _segmentButton(String title, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF1B4D36) : AppColors.surface)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.full),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.ink)
                  : (isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
