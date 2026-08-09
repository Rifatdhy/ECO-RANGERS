import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../locator.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import '../ui/widgets/admin_charts.dart';
import '../ui/widgets/filter_chips.dart';
import '../ui/widgets/report_card.dart';
import '../ui/widgets/state_views.dart';
import 'auth_page.dart';
import 'laporan_detail_page.dart';

class DashboardAdminPage extends StatefulWidget {
  const DashboardAdminPage({super.key});

  @override
  State<DashboardAdminPage> createState() => _DashboardAdminPageState();
}

class _DashboardAdminPageState extends State<DashboardAdminPage> {
  final ApiClient _apiClient = locator<ApiClient>();
  User? _user;
  List<Laporan> _reports = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Pending', 'Diproses', 'Selesai', 'Ditolak'];
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      _user = await locator<AuthService>().getMe();
      final results = await Future.wait([
        _apiClient.fetchReportsAsModel(
          status: _selectedFilter,
          limit: 500,
          q: _searchQuery.isEmpty ? null : _searchQuery,
        ),
        _apiClient.getStats(),
      ]);
      _reports = results[0] as List<Laporan>;
      _stats = results[1] as Map<String, dynamic>;
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _searchQuery = value.trim().toLowerCase();
      _loadData();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _exportCsv() async {
    final t = await locator<AuthService>().getToken();
    if (t == null) return;
    final query = <String, String>{
      'token': t,
      if (_selectedFilter.toLowerCase() != 'semua') 'status': _selectedFilter.toLowerCase(),
      if (_searchQuery.isNotEmpty) 'q': _searchQuery,
    };
    final uri = Uri.parse('$baseUrl/api/admin/export/reports')
        .replace(queryParameters: query);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat mengekspor laporan')),
      );
    }
  }

  Future<void> _logout() async {
    await locator<AuthService>().logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _showFilterBottomSheet() {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter status',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih kategori yang ingin ditampilkan.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              ..._filterOptions.map((filter) {
                final selected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                    tileColor: selected ? AppColors.primary.withValues(alpha: 0.08) : null,
                    title: Text(
                      filter,
                      style: TextStyle(
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? AppColors.primary : AppColors.text,
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() => _selectedFilter = filter);
                      Navigator.pop(context);
                      _loadData();
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _reports;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: false,
              expandedHeight: 190,
              backgroundColor: theme.colorScheme.surface,
              surfaceTintColor: theme.colorScheme.surface,
              title: const Text('Dashboard Admin'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_rounded),
                  tooltip: 'Ekspor CSV',
                  onPressed: _exportCsv,
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Keluar',
                  onPressed: _logout,
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _isLoading
                    ? const SizedBox.shrink()
                    : Container(
                        padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Halo, Admin ${_user?.username ?? _user?.name ?? ''}',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tinjau laporan masuk, cek status, dan arahkan tindak lanjut dengan cepat.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: StatTile(
                                  label: 'Total laporan',
                                  value: '${_stats['total'] ?? _reports.length}',
                                  icon: Icons.fact_check_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatTile(
                                  label: 'Menunggu',
                                  value: '${_stats['pending'] ?? 0}',
                                  icon: Icons.hourglass_top_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              hintText: 'Cari laporan berdasarkan judul atau deskripsi',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.tune_rounded),
                                tooltip: 'Filter status',
                                onPressed: _showFilterBottomSheet,
                              ),
                            ),
                            onChanged: _onSearchChanged,
                          ),
                          const SizedBox(height: 14),
                          FilterChips(
                            options: _filterOptions,
                            selected: _selectedFilter,
                            onSelected: (option) {
                              setState(() => _selectedFilter = option);
                              _loadData();
                            },
                          ),
                          const SizedBox(height: 18),
                          _buildCharts(),
                        ],
                      ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              sliver: _isLoading
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : filtered.isEmpty
                      ? SliverToBoxAdapter(child: _buildEmptyState())
                      : SliverList.separated(
                          itemBuilder: (context, index) => _buildReportCard(filtered[index]),
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemCount: filtered.length,
                        ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildCharts() {
    final theme = Theme.of(context);
    final trend = (_stats['trend'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final kategori = Map<String, dynamic>.from(_stats['kategori'] as Map? ?? {});
    final avgH = _stats['avg_response_hours'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (avgH != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Rata-rata waktu tanggap',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      '${_formatHours(avgH)} jam',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Tren 7 Hari', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TrenChart(trend: trend),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pie_chart_outline_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.xs),
                    Text('Distribusi Kategori', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                KategoriDonut(kategori: kategori),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatHours(Object? value) {
    final h = (value as num).toDouble();
    if (h < 1) return '${(h * 60).round()} mnt';
    return h.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }

  Widget _buildEmptyState() {
    return EmptyState(
      icon: Icons.inbox_outlined,
      title: 'Belum ada laporan yang cocok',
      subtitle: _searchQuery.isNotEmpty
          ? 'Coba ubah kata kunci atau filter status.'
          : 'Laporan baru akan muncul di sini.',
    );
  }

  Widget _buildReportCard(Laporan report) {
    final isPending = report.status.toLowerCase() == 'pending';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isPending)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Laporan ini menunggu verifikasi.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ReportCard(
          laporan: report,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LaporanDetailPage(laporan: report)),
            ).then((_) => _loadData());
          },
        ),
      ],
    );
  }
}