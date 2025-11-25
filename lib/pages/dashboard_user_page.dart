import 'package:eco_rangers/models/laporan.dart';
import 'package:eco_rangers/services/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart';
import '../locator.dart';
import 'buat_laporan_page.dart';
import 'auth_page.dart';
import '../ui/app_theme.dart';
import 'laporan_detail_page.dart';
import 'package:intl/intl.dart';

class DashboardUserPage extends StatefulWidget {
  const DashboardUserPage({super.key});

  @override
  State<DashboardUserPage> createState() => _DashboardUserPageState();
}

class _DashboardUserPageState extends State<DashboardUserPage> {
  late Future<List<Laporan>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reportsFuture = locator<ApiClient>().fetchReportsAsModel();
    });
  }

  void _navigateToDetail(Laporan laporan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LaporanDetailPage(laporan: laporan)),
    );
    if (result == true) {
      _loadReports();
    }
  }

  void _navigateToBuatLaporan() async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const BuatLaporanPage())
    );
    _loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Dasbor"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Logout',
            onPressed: () async {
              await locator<AuthService>().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Laporan>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerContent(); // EFEK SHIMMER
          }
          if (snapshot.hasError) {
            return Center(child: Text("Gagal memuat data: ${snapshot.error}"));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return _buildEmptyState();
          }
          return _buildDashboardContent(reports);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToBuatLaporan,
        label: const Text('Lapor Sekarang'),
        icon: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Widget _buildShimmerContent() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(width: 200, height: 24.0, color: Colors.white),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 120, color: Colors.white,)),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 120, color: Colors.white,)),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 120, color: Colors.white,)),
            ],
          ),
          const SizedBox(height: 24),
          Container(width: 150, height: 24.0, color: Colors.white),
          const SizedBox(height: 8),
          Container(height: 95, color: Colors.white, margin: const EdgeInsets.symmetric(vertical: 6)),
          Container(height: 95, color: Colors.white, margin: const EdgeInsets.symmetric(vertical: 6)),
          Container(height: 95, color: Colors.white, margin: const EdgeInsets.symmetric(vertical: 6)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.outbox_rounded, size: 80, color: theme.textTheme.bodyMedium?.color),
            const SizedBox(height: 16),
            Text('Belum Ada Laporan', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Anda belum membuat laporan apa pun. Mari jaga lingkungan bersama!', style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _navigateToBuatLaporan,
              icon: const Icon(Icons.add),
              label: const Text('Buat Laporan Pertama'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(List<Laporan> reports) {
    final theme = Theme.of(context);
    final int total = reports.length;
    final int diproses = reports.where((r) => r.status == 'diproses').length;
    final int selesai = reports.where((r) => r.status == 'selesai').length;

    return RefreshIndicator(
      onRefresh: () async => _loadReports(),
      child: AnimationLimiter(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              Text('Ringkasan Laporan Anda', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildSummaryCard('Total Laporan', total.toString(), Icons.receipt_long, Colors.blue)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard('Diproses', diproses.toString(), Icons.hourglass_bottom, Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSummaryCard('Selesai', selesai.toString(), Icons.check_circle, Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Laporan Terbaru', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              ...reports.take(5).map((laporan) => _buildReportCard(laporan, theme.textTheme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3))
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

    Widget _buildReportCard(Laporan laporan, TextTheme textTheme) {
    final statusInfo = _getStatusInfo(laporan.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _navigateToDetail(laporan),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: laporan.fotoUrl != null
                    ? Image.network(
                        laporan.fotoUrl!,
                        width: 70, height: 70, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(laporan.judul, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMMM yyyy').format(laporan.createdAt),
                      style: textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                     Chip(
                          avatar: Icon(statusInfo.icon, color: Colors.white, size: 14),
                          label: Text(statusInfo.text),
                          backgroundColor: statusInfo.color,
                          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70, height: 70,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Center(
        child: Icon(Icons.image_not_supported_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 30),
      ),
    );
  }

   ({Color color, IconData icon, String text}) _getStatusInfo(String status) {
    switch (status.toLowerCase()) {
      case 'selesai':
        return (color: Colors.green, icon: Icons.check_circle, text: 'Selesai');
      case 'diproses':
        return (color: Colors.orange, icon: Icons.hourglass_bottom, text: 'Diproses');
      case 'ditolak':
        return (color: Colors.red, icon: Icons.cancel, text: 'Ditolak');
      default: // pending
        return (color: Colors.grey, icon: Icons.pending, text: 'Pending');
    }
  }
}
