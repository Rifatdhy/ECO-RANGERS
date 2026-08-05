import 'package:flutter/material.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/app_theme.dart';
import '../ui/status_info.dart';
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
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih kategori yang ingin ditampilkan.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ..._filterOptions.map((filter) {
                final selected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text(
                        filter,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.primaryColor : null,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                          : const Icon(Icons.chevron_right),
                      onTap: () {
                        setState(() => _selectedFilter = filter);
                        Navigator.pop(context);
                        _loadData();
                      },
                    ),
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
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF14532D).withValues(alpha: 0.14),
                              const Color(0xFFF6FDF8),
                            ],
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
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tinjau laporan masuk, cek status, dan arahkan tindak lanjut dengan cepat.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
                                child: _StatTile(
                                  label: 'Total laporan',
                                  value: '${_reports.length}',
                                  icon: Icons.fact_check_outlined,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatTile(
                                  label: 'Status aktif',
                                  value: _selectedFilter,
                                  icon: Icons.filter_alt_outlined,
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
                          SizedBox(
                            height: 42,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemBuilder: (context, index) {
                                final option = _filterOptions[index];
                                final selected = option == _selectedFilter;
                                return ChoiceChip(
                                  label: Text(option),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() => _selectedFilter = option);
                                    _loadData();
                                  },
                                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.14),
                                  labelStyle: TextStyle(
                                    color: selected ? AppTheme.primaryColor : null,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: selected ? AppTheme.primaryColor : Colors.black12,
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(width: 8),
                              itemCount: _filterOptions.length,
                            ),
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
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Center(
        child: Column(
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inbox_outlined, size: 44, color: AppTheme.primaryColor.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 18),
            Text(
              'Belum ada laporan yang cocok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Coba ubah kata kunci atau filter status.'
                  : 'Laporan baru akan muncul di sini.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Laporan report) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LaporanDetailPage(laporan: report),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: statusColor(report.status).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                      child: Icon(
                        report.status.toLowerCase() == 'selesai'
                            ? Icons.verified_rounded
                            : Icons.report_problem_outlined,
                        color: statusColor(report.status),
                      ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                report.judul,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                            ),
                            if (report.status.toLowerCase() == 'selesai') ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.verified, color: Colors.blue, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          report.deskripsi,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Chip(
                    label: Text(report.status),
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    backgroundColor: statusColor(report.status),
                    side: BorderSide.none,
                  ),
                  const Spacer(),
                    Text(
                      report.createdAtLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                    ),
                ],
              ),
              if (report.status.toLowerCase() != 'selesai' && report.fotoUrl != null && report.fotoUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.16)),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}