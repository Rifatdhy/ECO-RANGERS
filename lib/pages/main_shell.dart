import 'package:flutter/material.dart';

import '../ui/tokens.dart';
import 'activity_page.dart';
import 'buat_laporan_page.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _homeKey = GlobalKey<HomePageState>();
  final _mapKey = GlobalKey<MapPageState>();
  final _activityKey = GlobalKey<ActivityPageState>();
  final _profileKey = GlobalKey<ProfilePageState>();
  // Lazy-build: tab hanya di-build saat pertama kali dipilih.
  final Set<int> _built = {0};
  int _index = 0;

  void _openCreateReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BuatLaporanPage()),
    ).then((_) {
      if (mounted) setState(() {});
      _homeKey.currentState?.refresh();
    });
  }

  void _onDestinationSelected(int i) {
    setState(() {
      _built.add(i);
      _index = i;
    });
    switch (i) {
      case 0:
        _homeKey.currentState?.refresh();
      case 1:
        _mapKey.currentState?.refresh();
      case 3:
        _activityKey.currentState?.refresh();
      case 4:
        _profileKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(key: _homeKey, openCreateReport: _openCreateReport),
          _built.contains(1) ? MapPage(key: _mapKey) : const SizedBox.shrink(),
          const SizedBox.shrink(), // slot FAB tengah (tidak ada halaman)
          _built.contains(3) ? ActivityPage(key: _activityKey) : const SizedBox.shrink(),
          _built.contains(4) ? ProfilePage(key: _profileKey) : const SizedBox.shrink(),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 120,
        height: 112,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: _openCreateReport,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Peta',
          ),
          NavigationDestination(
            icon: SizedBox.shrink(),
            label: '',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Aktivitas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}