import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../locator.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import '../ui/widgets/filter_chips.dart';
import '../ui/widgets/report_card.dart';
import '../ui/widgets/section_header.dart';
import '../ui/widgets/state_views.dart';
import 'buat_laporan_page.dart';
import 'laporan_detail_page.dart';
import 'notifikasi_page.dart';

/// HomePage mewah bergaya Apple News / Apple Health Dashboard:
/// Hero greeting personal dengan visual clean,
/// Bento KPI Card yang elegan, pill filter kategori halus,
/// dan daftar laporan foto-first.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiClient _apiClient = locator<ApiClient>();
  final AuthService _authService = locator<AuthService>();

  User? _user;
  Map<String, dynamic>? _stats;
  List<Laporan> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategory = 'semua';

  final List<String> _categories = [
    'semua',
    'sampah',
    'pencemaran',
    'infrastruktur',
    'fauna',
    'flora',
    'laimnya',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getMe();
      final stats = await _apiClient.getStats().catchError((_) => <String, dynamic>{});
      final reports = await _apiClient.fetchReportsAsModel(
        kategori: _selectedCategory == 'semua' ? null : _selectedCategory,
        limit: 10,
      );

      if (mounted) {
        setState(() {
          _user = user;
          _stats = stats;
          _reports = reports;
          _isLoading = false;
        });
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

  void _onCategorySelected(String cat) {
    if (_selectedCategory == cat) return;
    setState(() => _selectedCategory = cat);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // Apple Large Title App Bar with Glass Effect
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: isDark
                ? const Color(0xE60B1410)
                : const Color(0xE6F9FAF9),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16, right: 20),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ECO RANGERS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: isDark ? const Color(0xFF52B788) : AppColors.sage,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Beranda',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: isDark ? Colors.white : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      // Notification Button
                      IconButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NotifikasiPage()),
                        ),
                        icon: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B2B22) : AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 18,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Pull to refresh
          CupertinoSliverRefreshControl(
            onRefresh: _loadData,
          ),

          // Body Content
          SliverToBoxAdapter(
            child: _isLoading
                ? _buildLoadingSkeleton(isDark)
                : _errorMessage != null
                    ? ErrorStateView(message: _errorMessage!, onRetry: _loadData)
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Apple Luxury Greeting Card
                          _buildGreetingHero(isDark),
                          const SizedBox(height: 18),

                          // Bento KPI Overview
                          _buildBentoKpi(isDark),
                          const SizedBox(height: 24),

                          // Category Filter Section
                          SectionHeader(
                            title: 'Jelajahi Isu Lingkungan',
                            subtitle: 'Filter berdasarkan topik pelaporan warga',
                          ),
                          const SizedBox(height: 6),
                          FilterChips<String>(
                            options: _categories,
                            selected: _selectedCategory,
                            onSelected: _onCategorySelected,
                            labelBuilder: (c) => c == 'semua'
                                ? 'Semua Kategori'
                                : c[0].toUpperCase() + c.substring(1),
                          ),
                          const SizedBox(height: 20),

                          // Recent Reports Section
                          SectionHeader(
                            title: 'Laporan Terbaru',
                            subtitle: 'Pantau dan dukung penyelesaian di sekitar Anda',
                          ),
                          const SizedBox(height: 8),

                          // Reports List
                          if (_reports.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: EmptyStateView(
                                icon: Icons.park_outlined,
                                title: 'Belum Ada Laporan',
                                description: 'Jadilah yang pertama melaporkan masalah lingkungan di lingkungan Anda.',
                                actionLabel: 'Buat Laporan',
                                onAction: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const BuatLaporanPage()),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                children: _reports.map((report) {
                                  return ReportCard(
                                    report: report,
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => LaporanDetailPage(reportId: report.id),
                                        ),
                                      );
                                      _loadData();
                                    },
                                    onVote: () async {
                                      try {
                                        await _apiClient.toggleVote(report.id);
                                        _loadData();
                                      } catch (_) {}
                                    },
                                  );
                                }).toList(),
                              ),
                            ),

                          const SizedBox(height: 100), // Safe bottom margin for floating nav
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingHero(bool isDark) {
    final name = _user?.name.isNotEmpty == true ? _user!.name : (_user?.username ?? 'Warga Peduli');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF14261D), Color(0xFF1A3326)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : AppColors.heroCardGradient,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
          ),
          boxShadow: AppShadows.luxuryCard,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF264032)
                          : AppColors.mintGlow,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'CIVIC ACTION HUB',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? const Color(0xFF74C69D) : AppColors.emerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Halo, $name',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Suara dan aksi Anda menjaga ekosistem tetap bersih dan lestari.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.luxuryBrandGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forest.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.eco_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoKpi(bool isDark) {
    final total = _stats?['total'] ?? 0;
    final selesai = _stats?['selesai'] ?? 0;
    final diproses = _stats?['diproses'] ?? 0;
    final pending = _stats?['pending'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left Main KPI Card
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                ),
                boxShadow: AppShadows.luxuryCard,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL LAPORAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$total',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      height: 1.0,
                      color: isDark ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$selesai selesai dituntaskan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Right Mini KPI Stack
          Expanded(
            flex: 5,
            child: Column(
              children: [
                _miniStatCard('Diproses', diproses, AppColors.diprosesText, AppColors.diprosesBg, isDark),
                const SizedBox(height: 10),
                _miniStatCard('Pending', pending, AppColors.pendingText, AppColors.pendingBg, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(String label, dynamic count, Color textColor, Color bgColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14201A) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
        ),
        boxShadow: AppShadows.luxuryCard,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: isDark ? Colors.white : AppColors.ink,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? textColor.withValues(alpha: 0.18) : bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.trending_up_rounded,
              size: 14,
              color: isDark ? Colors.white : textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingSkeleton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          3,
          (index) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 240,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF14201A) : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.line,
              ),
            ),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: isDark ? const Color(0xFF52B788) : AppColors.forest,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
