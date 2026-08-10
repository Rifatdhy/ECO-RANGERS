import 'package:cached_network_image/cached_network_image.dart';
import 'package:eco_rangers/models/kategori.dart';
import 'package:eco_rangers/models/report_update.dart';
import 'package:eco_rangers/pages/photo_viewer_page.dart';
import 'package:eco_rangers/services/api_client.dart';
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
  bool _voting = false;
  bool _confirming = false;
  final _authService = locator<AuthService>();
  final _apiClient = locator<ApiClient>();

  @override
  void initState() {
    super.initState();
    // Salin, jangan merujuk objek list parent → snapshot mandiri.
    _currentLaporan = widget.laporan.copyWithLaporan();
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    if (!mounted) return;
    try {
      final fresh = await _apiClient.getReport(_currentLaporan.id);
      if (!mounted || _voting) return;
      setState(() => _currentLaporan = fresh);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat detail terbaru')),
        );
      }
    }
  }

  Future<void> _toggleVote() async {
    if (_voting) return;
    setState(() => _voting = true);
    try {
      final result = await _apiClient.toggleVote(_currentLaporan.id);
      if (mounted) {
        setState(() {
          _currentLaporan.voteCount = (result['votes'] as num?)?.toInt() ?? _currentLaporan.voteCount;
          _currentLaporan.votedByMe = result['voted'] == true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengubah vote')),
        );
      }
    } finally {
      if (mounted) setState(() => _voting = false);
    }
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

  Future<void> _confirm(String konfirmasi) async {
    if (_confirming) return;
    setState(() => _confirming = true);
    try {
      await _apiClient.confirmReport(_currentLaporan.id, konfirmasi);
      if (!mounted) return;
      setState(() => _currentLaporan.konfirmasiUser = konfirmasi);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih atas konfirmasimu')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan konfirmasi')),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
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
                      child: CachedNetworkImage(
                        imageUrl: _currentLaporan.fotoUrl!,
                        fit: BoxFit.cover,
                        height: 220,
                        placeholder: (_, __) => Container(
                          height: 220,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
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
            if (_isReporter && _currentLaporan.status.toLowerCase() == 'selesai')
              _buildConfirmationCard(textTheme),
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

  bool get _isReporter =>
      !(_authService.currentUser?.isAdmin ?? false) &&
      _currentLaporan.user?.id == _authService.currentUser?.id;

  Widget _buildConfirmationCard(TextTheme textTheme) {
    final done = _currentLaporan.konfirmasiUser;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Konfirmasi Penyelesaian', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (done != null)
              Row(
                children: [
                  Icon(
                    done == 'sesuai' ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                    color: done == 'sesuai' ? AppColors.success : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      done == 'sesuai'
                          ? 'Kamu menandai laporan ini sudah tuntas.'
                          : 'Kamu menandai penanganan belum tuntas.',
                      style: textTheme.bodyMedium,
                    ),
                  ),
                ],
              )
            else ...[
              Text(
                'Apakah penanganan laporan ini sudah sesuai?',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: _confirming ? null : () => _confirm('sesuai'),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Sudah sesuai'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirming ? null : () => _confirm('tidak_tuntas'),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Belum tuntas'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge(status: _currentLaporan.status),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${kategoriIcon(_currentLaporan.kategori)} ${kategoriLabel(_currentLaporan.kategori)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ActionChip(
                  avatar: Icon(
                    _currentLaporan.votedByMe ? Icons.arrow_upward_rounded : Icons.arrow_upward_outlined,
                    size: 18,
                    color: _currentLaporan.votedByMe ? AppColors.primary : AppColors.textMuted,
                  ),
                  label: Text('${_currentLaporan.voteCount}'),
                  tooltip: _currentLaporan.votedByMe ? 'Batal dukung' : 'Dukung isu ini',
                  onPressed: _voting ? null : _toggleVote,
                  backgroundColor: _currentLaporan.votedByMe
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surface,
                ),
              ],
            ),
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
    final lineColor = Theme.of(context).dividerColor.withValues(alpha: 0.5);

    return IntrinsicHeight(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, t, child) {
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - t)),
              child: child,
            ),
          );
        },
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
                  child: Icon(
                    info.icon,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                if (!isLast) Expanded(child: Container(width: 2, color: lineColor)),
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
                              child: CachedNetworkImage(imageUrl: update.fotoDokumentasiUrl!),
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
      ),
    );
  }
}