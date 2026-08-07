import 'package:eco_rangers/models/report_update.dart';
import 'package:eco_rangers/pages/photo_viewer_page.dart';
import 'package:eco_rangers/services/auth_service.dart';
import 'package:eco_rangers/ui/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../locator.dart';
import '../models/laporan.dart';
import '../ui/status_info.dart';
import '../ui/tokens.dart';
import 'update_status_page.dart';

class LaporanDetailPage extends StatefulWidget {
  final Laporan laporan;

  const LaporanDetailPage({super.key, required this.laporan});

  @override
  State<LaporanDetailPage> createState() => _LaporanDetailPageState();
}

class _LaporanDetailPageState extends State<LaporanDetailPage> {
  late Laporan _currentLaporan;
  final _authService = locator<AuthService>();

  @override
  void initState() {
    super.initState();
    _currentLaporan = widget.laporan;
  }

  void _navigateToUpdatePage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateStatusPage(laporan: _currentLaporan),
      ),
    );
    if (result == true) {
      if (!mounted) return;
      Navigator.pop(context, true);
    }
  }

  void _openPhotoViewer(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoViewerPage(imageUrl: imageUrl),
      ),
    );
  }

  void _openGoogleMaps(double latitude, double longitude) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka Google Maps')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isAdmin = _authService.currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentLaporan.judul),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentLaporan.fotoUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: GestureDetector(
                  onTap: () => _openPhotoViewer(_currentLaporan.fotoUrl!),
                  child: Hero(
                    tag: _currentLaporan.fotoUrl!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.network(
                        _currentLaporan.fotoUrl!,
                        fit: BoxFit.cover,
                        height: 220,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : Container(
                                height: 220,
                                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 220,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          child: const Icon(Icons.broken_image_outlined, size: 48, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            _buildInfoCard(textTheme),
            _buildDescriptionCard(textTheme),
            _buildHistorySection(textTheme),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _navigateToUpdatePage,
              label: const Text('Tambah Progres'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildInfoCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusBadge(status: _currentLaporan.status),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person_outline, 'Pelapor', '${_currentLaporan.user?.name ?? _currentLaporan.user?.username ?? 'N/A'} (${_currentLaporan.user?.email ?? 'N/A'})', textTheme),
            const Divider(height: 24),
            _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Laporan', DateFormat('dd MMMM yyyy, HH:mm').format(_currentLaporan.createdAt), textTheme),
            const Divider(height: 24),
            _buildLocationRow(textTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationRow(TextTheme textTheme) {
    final lat = _currentLaporan.latitude;
    final lng = _currentLaporan.longitude;
    final hasCoordinates = lat != null && lng != null;

    return InkWell(
      onTap: hasCoordinates ? () => _openGoogleMaps(lat, lng) : null,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on_outlined, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lokasi', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  _currentLaporan.lokasiText ?? 'Lokasi tidak tersedia',
                  style: textTheme.bodyLarge?.copyWith(
                    color: hasCoordinates ? const Color(0xFF2E7D32) : null,
                    decoration: hasCoordinates ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
          ),
          if(hasCoordinates) const Icon(Icons.open_in_new, color: Color(0xFF2E7D32), size: 18),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deskripsi Laporan', style: textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(_currentLaporan.deskripsi, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Progres', style: textTheme.titleMedium),
            const SizedBox(height: 16),
            if (_currentLaporan.updates.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text('Belum ada progres terbaru.', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _currentLaporan.updates.length,
              itemBuilder: (context, index) {
                final update = _currentLaporan.updates[index];
                final isLast = index == _currentLaporan.updates.length - 1;
                return _buildHistoryTile(update, isLast, textTheme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTile(ReportUpdate update, bool isLast, TextTheme textTheme) {
    final info = statusInfo(update.status);

    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: info.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.surface, width: 3),
                ),
              ),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.grey[300])),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${update.status.toUpperCase()}', style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: info.color)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd MMMM yyyy, HH:mm').format(update.createdAt), style: textTheme.bodySmall),
                  if (update.keterangan != null && update.keterangan!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('"${update.keterangan}"', style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                    ),
                  if (update.namaPetugas != null && update.namaPetugas!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Petugas: ${update.namaPetugas}', style: textTheme.bodyMedium),
                    ),
                  if (update.fotoDokumentasiUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: GestureDetector(
                        onTap: () => _openPhotoViewer(update.fotoDokumentasiUrl!),
                        child: Hero(
                          tag: update.fotoDokumentasiUrl!,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(update.fotoDokumentasiUrl!),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
