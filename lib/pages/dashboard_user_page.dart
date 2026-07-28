import 'package:flutter/material.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/app_theme.dart';
import 'auth_page.dart';
import 'buat_laporan_page.dart';
import 'laporan_detail_page.dart';

class DashboardUserPage extends StatefulWidget {
  const DashboardUserPage({super.key});

  @override
  State<DashboardUserPage> createState() => _DashboardUserPageState();
}

class _DashboardUserPageState extends State<DashboardUserPage> {
  final ApiClient _apiClient = locator<ApiClient>();
  User? _user;
  List<Laporan> _laporanList = [];
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
      _laporanList = await _apiClient.fetchReportsAsModel(status: _selectedFilter);
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
      backgroundColor: theme.colorScheme.surface,
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
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih kategori yang ingin ditampilkan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 16),
              ..._filterOptions.map((filter) {
                final selected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: selected
                        ? AppTheme.industrialSilver.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: Text(
                        filter,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppTheme.industrialBlack : null,
                        ),
                      ),
                      trailing: selected
                          ? const Icon(Icons.check_circle, color: AppTheme.industrialBlack)
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
    if (_searchQuery.isEmpty) return _laporanList;
    return _laporanList.where((laporan) {
      return laporan.judul.toLowerCase().contains(_searchQuery) ||
          laporan.deskripsi.toLowerCase().contains(_searchQuery);
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
               expandedHeight: MediaQuery.of(context).size.height * 0.3,
               backgroundColor: theme.colorScheme.surface,
               surfaceTintColor: theme.colorScheme.surface,
              title: Text(
                'Eco Rangers',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'Keluar',
                  onPressed: _logout,
                ),
              ],
               flexibleSpace: LayoutBuilder(
                 builder: (context, constraints) {
                   final isCompact = constraints.maxWidth < 420;
                   return FlexibleSpaceBar(
                     background: _isLoading
                         ? const SizedBox.shrink()
                         : Container(
                             padding: EdgeInsets.fromLTRB(20, isCompact ? 64 : 72, 20, 20),
                             decoration: BoxDecoration(
                               gradient: LinearGradient(
                                 begin: Alignment.topLeft,
                                 end: Alignment.bottomRight,
                                 colors: [
                                   AppTheme.industrialBlack,
                                   AppTheme.industrialCharcoal,
                                   AppTheme.industrialSteel.withValues(alpha: 0.95),
                                 ],
                               ),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                 Align(
                                   alignment: Alignment.topRight,
                                   child: Wrap(
                                     spacing: 8,
                                     runSpacing: 8,
                                     alignment: WrapAlignment.end,
                                     children: [
                                       _AccentOrb(
                                         label: 'Realtime',
                                         icon: Icons.bolt_rounded,
                                       ),
                                       _AccentOrb(
                                         label: 'Precision',
                                         icon: Icons.sensors_rounded,
                                       ),
                                     ],
                                   ),
                                 ),
                                 SizedBox(height: isCompact ? 12 : 18),
                                 Text(
                                   'Halo, ${_user?.username ?? _user?.name ?? 'Rangers'}',
                                   maxLines: 2,
                                   overflow: TextOverflow.ellipsis,
                                   style: theme.textTheme.headlineSmall?.copyWith(
                                     fontWeight: FontWeight.w800,
                                     letterSpacing: -0.3,
                                     color: Colors.white,
                                   ),
                                 ),
                                 const SizedBox(height: 8),
                                 Text(
                                   'Lihat laporan terbaru, cari isu tertentu, atau kirim temuan baru dari lapangan.',
                                   style: theme.textTheme.bodyMedium?.copyWith(
                                     color: Colors.white.withValues(alpha: 0.74),
                                   ),
                                 ),
                                 const SizedBox(height: 18),
                                 Wrap(
                                   spacing: 10,
                                   runSpacing: 10,
                                   children: const [
                                     _FeaturePill(label: 'Foto + lokasi'),
                                     _FeaturePill(label: 'Status real-time'),
                                     _FeaturePill(label: 'Tindak lanjut cepat'),
                                   ],
                                 ),
                               ],
                             ),
                           ),
                   );
                 },
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
                           LayoutBuilder(
                             builder: (context, constraints) {
                               final isNarrow = constraints.maxWidth < 360;
                               if (isNarrow) {
                                 return Column(
                                   children: [
                                     _StatTile(
                                       label: 'Total tampilan',
                                       value: '${_laporanList.length}',
                                       icon: Icons.assessment_outlined,
                                     ),
                                     const SizedBox(height: 12),
                                     _StatTile(
                                       label: 'Filter aktif',
                                       value: _selectedFilter,
                                       icon: Icons.tune_rounded,
                                     ),
                                   ],
                                 );
                               }
                               return Row(
                                 children: [
                                   Expanded(
                                     child: _StatTile(
                                       label: 'Total tampilan',
                                       value: '${_laporanList.length}',
                                       icon: Icons.assessment_outlined,
                                     ),
                                   ),
                                   const SizedBox(width: 12),
                                   Expanded(
                                     child: _StatTile(
                                       label: 'Filter aktif',
                                       value: _selectedFilter,
                                       icon: Icons.tune_rounded,
                                     ),
                                   ),
                                 ],
                               );
                             },
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
                                  selectedColor: AppTheme.industrialSilver.withValues(alpha: 0.16),
                                  labelStyle: TextStyle(
                                    color: selected ? AppTheme.industrialBlack : null,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: selected ? AppTheme.industrialSilver : Colors.black12,
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
                          itemBuilder: (context, index) => _buildLaporanCard(filtered[index]),
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemCount: filtered.length,
                        ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BuatLaporanPage()),
          ).then((_) => _loadData());
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat laporan'),
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
                color: AppTheme.industrialSilver.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 44,
                color: AppTheme.industrialSilver.withValues(alpha: 0.85),
              ),
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
                  : 'Mulai dari laporan pertama untuk mengisi beranda.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLaporanCard(Laporan laporan) {
    final statusColor = _getStatusColor(laporan.status);

    return Card(
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LaporanDetailPage(laporan: laporan),
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
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.report_problem_outlined,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          laporan.judul,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          laporan.deskripsi,
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
                    label: Text(laporan.status),
                    labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    backgroundColor: statusColor,
                    side: BorderSide.none,
                  ),
                  const Spacer(),
                  Text(
                    laporan.createdAtLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.64),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'diproses':
        return AppTheme.industrialSilver;
      case 'selesai':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppTheme.industrialSilver.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.industrialBlack),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.68),
                      ),
                ),
              ],
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
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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

class _AccentOrb extends StatelessWidget {
  const _AccentOrb({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
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