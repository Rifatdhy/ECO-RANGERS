import 'package:flutter/material.dart';
import '../locator.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import 'auth_page.dart';

/// ProfilePage bergaya Apple ID Profile Settings:
/// Avatar botani elegan, kartu profil minimalis, dan opsi logout cepat.
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = locator<AuthService>();
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    final user = await _authService.getMe();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari Akun?'),
        content: const Text('Anda perlu masuk kembali untuk mengirim dan memantau laporan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Pengguna'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.forest))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // User Avatar Header
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: AppColors.luxuryBrandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.forest.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Center(
                        child: Icon(Icons.person_rounded, color: Colors.white, size: 44),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _user?.name.isNotEmpty == true ? _user!.name : (_user?.username ?? 'Warga Peduli'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _user?.email ?? '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1B3D2B) : AppColors.mintGlow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      _user?.isAdmin == true ? 'ROLE: ADMIN' : 'ROLE: WARGA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: isDark ? const Color(0xFF52B788) : AppColors.emerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Info Settings Card
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                      ),
                      boxShadow: AppShadows.luxuryCard,
                    ),
                    child: Column(
                      children: [
                        _tileItem(
                          icon: Icons.shield_outlined,
                          title: 'Privasi & Autentikasi',
                          subtitle: 'Token aman via Laravel Sanctum',
                        ),
                        Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.lineLight),
                        _tileItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifikasi In-App',
                          subtitle: 'Baseline status updates',
                        ),
                        Divider(height: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.lineLight),
                        _tileItem(
                          icon: Icons.info_outline_rounded,
                          title: 'Tentang Aplikasi',
                          subtitle: 'Eco Rangers Civic Tech v1.0.0',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Logout Action
                  OutlinedButton.icon(
                    onPressed: _logout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Keluar dari Akun'),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _tileItem({required IconData icon, required String title, required String subtitle}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.sage, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      dense: true,
    );
  }
}
