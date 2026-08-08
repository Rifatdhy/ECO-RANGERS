import 'package:flutter/material.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import '../ui/widgets/report_card.dart';
import '../ui/widgets/section_header.dart';
import '../ui/widgets/state_views.dart';
import 'laporan_detail_page.dart';
import 'map_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.openCreateReport});

  final VoidCallback? openCreateReport;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final ApiClient _api = locator<ApiClient>();
  User? _user;
  List<Laporan> _laporanList = [];
  List<MapEntry<String, int>> _leaderboard = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _user = await locator<AuthService>().getMe();
      _laporanList = await _api.fetchReportsAsModel();
      _leaderboard = _computeLeaderboard();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<MapEntry<String, int>> _computeLeaderboard() {
    final counts = <String, int>{};
    for (final l in _laporanList) {
      final name = l.user?.name ?? l.user?.username;
      if (name == null || name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  int get _pending =>
      _laporanList.where((l) => l.status.toLowerCase() == 'pending').length;
  int get _selesai =>
      _laporanList.where((l) => l.status.toLowerCase() == 'selesai').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              if (_isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: Column(children: [
                      SkeletonReportCard(),
                      SizedBox(height: AppSpacing.sm),
                      SkeletonReportCard(),
                    ]),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetry(message: _error!, onRetry: _load),
                )
              else
                SliverToBoxAdapter(child: _buildContent()),
              const SliverToBoxAdapter(child: SizedBox(height: 96)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  (_user?.name ?? _user?.username ?? 'R').substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Halo, ${_splitName(_user?.name ?? _user?.username ?? 'Rangers')}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Lakukan aksi kecil untuk perubahan besar.',
                      style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              _heroStat(context, '${_laporanList.length}', 'Laporan', Icons.assessment_outlined),
              const SizedBox(width: AppSpacing.sm),
              _heroStat(context, '$_pending', 'Menunggu', Icons.hourglass_bottom_rounded),
              const SizedBox(width: AppSpacing.sm),
              _heroStat(context, '$_selesai', 'Selesai', Icons.check_circle_outline_rounded),
            ],
          ),
        ],
      ),
    );
  }

  String _splitName(String name) {
    final parts = name.trim().split(' ');
    return parts.length > 1 ? parts.first : name;
  }

  Widget _heroStat(BuildContext context, String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Aksi Cepat',
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          Row(
            children: [
              _quickAction('Buat Laporan', Icons.add_location_alt_rounded, AppColors.primary, widget.openCreateReport),
              const SizedBox(width: AppSpacing.sm),
              _quickAction('Lihat Peta', Icons.map_rounded, AppColors.secondary, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapPage()),
                );
              }),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Rangers Teraktif',
            subtitle: 'Berdasarkan jumlah laporan yang dikirim',
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          _buildLeaderboard(),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Laporan Terbaru',
            subtitle: '${_laporanList.length} laporan tercatat di komunitas',
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          if (_laporanList.isEmpty)
            const EmptyState(
              icon: Icons.forest_outlined,
              title: 'Belum ada laporan',
              subtitle: 'Jadilah yang pertama melaporkan kondisi lingkungan.',
              compact: true,
            )
          else
            ...[
              for (final l in _laporanList.take(4)) ...[
                ReportCard(laporan: l, onTap: () => _openDetail(l)),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final top = _leaderboard;
    if (top.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          for (var i = 0; i < top.length; i++) ...[
            if (i > 0) const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == 0 ? AppColors.warning.withValues(alpha: 0.18) : AppColors.accent.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: i == 0 ? AppColors.warning : AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        i == 0 ? Icons.emoji_events_rounded : Icons.person_rounded,
                        size: 18,
                        color: i == 0 ? AppColors.warning : AppColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          top[i].key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${top[i].value} laporan',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.text.withValues(alpha: 0.06)),
              boxShadow: AppShadows.card,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: AppSpacing.sm),
                Text(label, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(Laporan l) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaporanDetailPage(laporan: l)),
    ).then((_) => _load());
  }
}