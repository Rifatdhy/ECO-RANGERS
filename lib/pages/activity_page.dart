import 'package:flutter/material.dart';
import '../locator.dart';
import '../models/laporan.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import '../ui/widgets/report_card.dart';
import '../ui/widgets/state_views.dart';
import 'buat_laporan_page.dart';
import 'laporan_detail_page.dart';

/// ActivityPage bergaya Apple Activity Summary:
/// Menyajikan riwayat laporan pribadi pengguna secara terurut & clean.
class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final ApiClient _apiClient = locator<ApiClient>();
  final AuthService _authService = locator<AuthService>();

  List<Laporan> _myReports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivity();
  }

  Future<void> _loadActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getMe();
      final allReports = await _apiClient.fetchReportsAsModel(limit: 100);

      if (mounted) {
        setState(() {
          if (user != null) {
            _myReports = allReports.where((r) => r.user?.id == user.id).toList();
          } else {
            _myReports = allReports;
          }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Saya'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadActivity,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.forest))
            : _errorMessage != null
                ? ErrorStateView(message: _errorMessage!, onRetry: _loadActivity)
                : _myReports.isEmpty
                    ? EmptyStateView(
                        icon: Icons.history_rounded,
                        title: 'Belum Ada Aktivitas',
                        description: 'Semua laporan yang Anda kirimkan akan tercatat rapi di halaman ini.',
                        actionLabel: 'Mulai Lapor',
                        onAction: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BuatLaporanPage()),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _myReports.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _myReports.length) {
                            return const SizedBox(height: 80);
                          }
                          final r = _myReports[index];
                          return ReportCard(
                            report: r,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => LaporanDetailPage(reportId: r.id),
                                ),
                              );
                              _loadActivity();
                            },
                          );
                        },
                      ),
      ),
    );
  }
}
