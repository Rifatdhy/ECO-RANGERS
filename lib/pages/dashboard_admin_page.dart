import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import '../ui/widgets/filter_chips.dart';
import '../ui/widgets/report_card.dart';
import '../ui/widgets/section_header.dart';
import '../ui/widgets/state_views.dart';
import '../utils/save_file.dart';
import 'auth_page.dart';
import 'laporan_detail_page.dart';

/// DashboardAdminPage bergaya Apple Executive Operations Console:
/// KPI Bento Cards 4-Status, Grafik Bar 7-Hari Interaktif,
/// Donut chart distribusi kategori, Server-side search & filtering,
/// dan Export CSV Signed URL 60s.
class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final ApiClient _apiClient = locator<ApiClient>();
  final AuthService _authService = locator<AuthService>();

  Map<String, dynamic>? _stats;
  List<Laporan> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedStatus = 'semua';
  final _searchController = TextEditingController();

  final List<String> _statusOptions = [
    'semua',
    'pending',
    'diproses',
    'selesai',
    'ditolak',
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stats = await _apiClient.getStats();
      final reports = await _apiClient.fetchReportsAsModel(
        status: _selectedStatus == 'semua' ? null : _selectedStatus,
        q: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
        limit: 50,
      );

      if (mounted) {
        setState(() {
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

  Future<void> _exportCsv() async {
    try {
      final bytes = await _apiClient.downloadReportCsv(
        status: _selectedStatus == 'semua' ? null : _selectedStatus,
        q: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );
      await saveCsvFile(bytes, 'rekap-laporan-lingkungan.csv');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File CSV berhasil diunduh')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal export CSV: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EXECUTIVE CONSOLE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
                color: isDark ? const Color(0xFF52B788) : AppColors.sage,
              ),
            ),
            const Text(
              'Dashboard Admin',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV',
            onPressed: _exportCsv,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Keluar',
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4 Status Bento KPI Grid
              _buildBentoStatusGrid(isDark),
              const SizedBox(height: 20),

              // 7 Days Trend Chart (Apple Fitness Style)
              _buildTrendSection(isDark),
              const SizedBox(height: 24),

              // Search & Filter Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _loadDashboardData(),
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan judul, deskripsi, lokasi...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded),
                      onPressed: _loadDashboardData,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              FilterChips<String>(
                options: _statusOptions,
                selected: _selectedStatus,
                onSelected: (st) {
                  setState(() => _selectedStatus = st);
                  _loadDashboardData();
                },
                labelBuilder: (st) => st == 'semua' ? 'Semua Status' : st[0].toUpperCase() + st.substring(1),
              ),
              const SizedBox(height: 20),

              // Reports Table / Card View
              SectionHeader(
                title: 'Daftar Laporan Warga',
                subtitle: '${_reports.length} laporan ditemukan',
              ),
              const SizedBox(height: 8),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.forest),
                  ),
                )
              else if (_errorMessage != null)
                ErrorStateView(message: _errorMessage!, onRetry: _loadDashboardData)
              else if (_reports.isEmpty)
                const EmptyStateView(
                  icon: Icons.inbox_outlined,
                  title: 'Tidak Ada Laporan',
                  description: 'Tidak ada laporan yang sesuai dengan kriteria filter saat ini.',
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: _reports.map((r) {
                      return ReportCard(
                        report: r,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => LaporanDetailPage(reportId: r.id)),
                          );
                          _loadDashboardData();
                        },
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoStatusGrid(bool isDark) {
    final pending = _stats?['pending'] ?? 0;
    final diproses = _stats?['diproses'] ?? 0;
    final selesai = _stats?['selesai'] ?? 0;
    final ditolak = _stats?['ditolak'] ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              _kpiCard('Pending', pending, AppColors.pendingText, AppColors.pendingBg, isDark),
              const SizedBox(width: 12),
              _kpiCard('Diproses', diproses, AppColors.diprosesText, AppColors.diprosesBg, isDark),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _kpiCard('Selesai', selesai, AppColors.selesaiText, AppColors.selesaiBg, isDark),
              const SizedBox(width: 12),
              _kpiCard('Ditolak', ditolak, AppColors.ditolakText, AppColors.ditolakBg, isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, dynamic count, Color textColor, Color bgColor, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
                color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: isDark ? Colors.white : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendSection(bool isDark) {
    final trendList = (_stats?['trend'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (trendList.isEmpty) return const SizedBox.shrink();

    final recent7 = trendList.length >= 7 ? trendList.sublist(trendList.length - 7) : trendList;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF14201A) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
          ),
          boxShadow: AppShadows.luxuryCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TREN LAPORAN 7 HARI TERAKHIR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 15,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: const FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(recent7.length, (i) {
                    final total = (recent7[i]['total'] as num?)?.toDouble() ?? 0.0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: total > 0 ? total : 0.8,
                          color: isDark ? const Color(0xFF52B788) : AppColors.forest,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
