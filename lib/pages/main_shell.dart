import 'dart:ui';
import 'package:flutter/material.dart';
import '../ui/tokens.dart';
import 'activity_page.dart';
import 'buat_laporan_page.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'profile_page.dart';

/// MainShell terinspirasi Apple iOS Tab View:
/// Menggunakan Frosted Glass Bottom Navigation Bar yang tipis dan jernih,
/// Floating Center Action Button (Lapor) ber-haptic feedback visual,
/// dan transisi halaman super mulus.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _currentIndex;
  final Set<int> _builtIndices = {0};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _builtIndices.add(_currentIndex);
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // FAB Action: Buat Laporan
      _openBuatLaporan();
      return;
    }
    setState(() {
      _currentIndex = index;
      _builtIndices.add(index);
    });
  }

  Future<void> _openBuatLaporan() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const BuatLaporanPage(),
        fullscreenDialog: true,
      ),
    );
    if (created == true && mounted) {
      setState(() {
        _currentIndex = 0; // Kembali ke Home & refresh
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = <Widget>[
      _builtIndices.contains(0) ? const HomePage() : const SizedBox.shrink(),
      _builtIndices.contains(1) ? const MapPage() : const SizedBox.shrink(),
      const SizedBox.shrink(), // Index 2 placeholder (FAB)
      _builtIndices.contains(3) ? const ActivityPage() : const SizedBox.shrink(),
      _builtIndices.contains(4) ? const ProfilePage() : const SizedBox.shrink(),
    ];

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildAppleGlassBottomNav(isDark),
    );
  }

  Widget _buildAppleGlassBottomNav(bool isDark) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xE6101B15)
                : const Color(0xE6FFFFFF),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                width: 0.8,
              ),
            ),
            boxShadow: AppShadows.bottomNav,
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda', isDark),
                  _navItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Peta', isDark),
                  _buildCenterFab(isDark),
                  _navItem(3, Icons.task_alt_rounded, Icons.task_alt_outlined, 'Aktivitas', isDark),
                  _navItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profil', isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon, String label, bool isDark) {
    final isSelected = _currentIndex == index;
    final activeColor = isDark ? const Color(0xFF52B788) : AppColors.forest;
    final inactiveColor = isDark ? AppColors.darkMutedTextColor : AppColors.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterFab(bool isDark) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: _openBuatLaporan,
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppColors.luxuryBrandGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.forest.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
