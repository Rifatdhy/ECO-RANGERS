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

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => ActivityPageState();
}

class ActivityPageState extends State<ActivityPage> {
  final ApiClient _api = locator<ApiClient>();
  User? _user;
  List<Laporan> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _user = await locator<AuthService>().getMe();
      _all = await _api.fetchReportsAsModel();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Laporan> get _myReports {
    final uid = _user?.id;
    if (uid == null) return [];
    return _all.where((l) => l.user?.id == uid).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Widget build(BuildContext context) {
    final my = _myReports;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                  child: SectionHeader(
                    title: 'Aktivitas Saya',
                    subtitle: 'Riwayat laporan yang kamu buat',
                  ),
                ),
              ),
              if (_loading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (_error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetry(onRetry: _load, message: _error!),
                )
              else if (my.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.assignment_outlined,
                    title: 'Belum ada aktivitas',
                    subtitle: 'Laporan yang kamu buat akan muncul di sini.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 24),
                  sliver: SliverList.separated(
                    itemBuilder: (context, i) => ReportCard(
                      laporan: my[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LaporanDetailPage(laporan: my[i])),
                      ).then((_) => _load()),
                    ),
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemCount: my.length,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}