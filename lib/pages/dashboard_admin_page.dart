import 'package:flutter/material.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
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
  bool _isLoading = true;
  String _selectedFilter = 'Semua';
  final List<String> _filterOptions = ['Semua', 'Pending', 'Diproses', 'Selesai', 'Ditolak'];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _user = await locator<AuthService>().getMe();
      _reports = await _apiClient.fetchReportsAsModel(status: _selectedFilter);
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

  List<Laporan> get _filteredReports {
    if (_searchQuery.isEmpty) return _reports;
    return _reports.where((report) {
      return report.judul.toLowerCase().contains(_searchQuery) ||
          report.deskripsi.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filteredReports;

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
                                  value: '${_reports.length}',
                                  icon: Icons.fact_check_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: StatTile(
                                  label: 'Menunggu',
                                  value: '${_reports.where((r) => r.status.toLowerCase() == 'pending').length}',
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
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
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