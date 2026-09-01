import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../ui/tokens.dart';
import '../ui/widgets/status_badge.dart';
import 'photo_viewer_page.dart';
import 'update_status_page.dart';

/// LaporanDetailPage bergaya Apple Editorial Feature:
/// Foto Full-Bleed dengan Translucent Floating Pill,
/// Timeline status penyelesaian berbasis garis waktu rapi,
/// dan konfirmasi penyelesaian warga satu ketukan.
class LaporanDetailPage extends StatefulWidget {
  final int reportId;

  const LaporanDetailPage({super.key, required this.reportId});

  @override
  State<LaporanDetailPage> createState() => _LaporanDetailPageState();
}

class _LaporanDetailPageState extends State<LaporanDetailPage> {
  final ApiClient _apiClient = locator<ApiClient>();
  final AuthService _authService = locator<AuthService>();

  Laporan? _report;
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.getMe();
      final report = await _apiClient.getReport(widget.reportId);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _report = report;
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

  Future<void> _toggleVote() async {
    if (_report == null) return;
    try {
      final res = await _apiClient.toggleVote(_report!.id);
      setState(() {
        _report = _report!.copyWith(
          voteCount: res['votes'] as int?,
          votedByMe: res['voted'] as bool?,
        );
      });
    } catch (_) {}
  }

  Future<void> _confirmResolution(String statusConfirm) async {
    try {
      await _apiClient.confirmReport(widget.reportId, statusConfirm);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi Anda berhasil dicatat')),
      );
      _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal konfirmasi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.forest),
        ),
      );
    }

    if (_errorMessage != null || _report == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage ?? 'Laporan tidak ditemukan'),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _loadDetail, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    final r = _report!;
    final isOwner = _currentUser != null && r.user != null && _currentUser!.id == r.user!.id;
    final isAdmin = _currentUser?.isAdmin == true;
    final canConfirm = isOwner && r.status == 'selesai' && !isAdmin;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Hero Image Header (Apple Full Bleed)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: r.fotoUrl != null
                  ? GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PhotoViewerPage(
                            imageUrl: r.fotoUrl!,
                          ),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: r.fotoUrl!,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 4),
                                  Text(
                                    'Perbesar Foto',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
                      color: isDark ? const Color(0xFF14201A) : AppColors.backgroundSecondary,
                      child: const Center(
                        child: Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textMuted),
                      ),
                    ),
            ),
          ),

          // Detail Body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status & Category Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      StatusBadge(status: r.status),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1C2C23) : AppColors.mintGlow,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          r.kategori.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF74C69D) : AppColors.emerald,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    r.judul,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Reporter & Date Meta
                  Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        r.user?.name.isNotEmpty == true ? r.user!.name : (r.user?.username ?? 'Anonim'),
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        r.createdAtLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Description Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                      ),
                      boxShadow: AppShadows.luxuryCard,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DESKRIPSI MASALAH',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          r.deskripsi,
                          style: TextStyle(
                            fontSize: 14.5,
                            height: 1.5,
                            color: isDark ? Colors.white : AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line,
                      ),
                      boxShadow: AppShadows.luxuryCard,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B3D2B) : AppColors.mintGlow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: isDark ? const Color(0xFF52B788) : AppColors.emerald,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LOKASI KEJADIAN',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.0,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                r.lokasiText ?? (r.latitude != null ? '${r.latitude}, ${r.longitude}' : 'Lokasi terlampir'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        if (r.latitude != null && r.longitude != null)
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 18),
                            onPressed: () {
                              launchUrl(
                                Uri.parse('https://www.google.com/maps/search/?api=1&query=${r.latitude},${r.longitude}'),
                                mode: LaunchMode.externalApplication,
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Citizen Confirmation Card
                  if (canConfirm) ...[
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF142B20) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.selesaiBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Konfirmasi Penyelesaian Masalah',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Petugas menandai laporan ini telah selesai. Apakah masalah lingkungan ini sudah tuntas diselesaikan?',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _confirmResolution('sesuai'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                  child: const Text('Sesuai & Tuntas ✅', style: TextStyle(fontSize: 12.5)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _confirmResolution('tidak_tuntas'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                    side: const BorderSide(color: AppColors.error),
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                  ),
                                  child: const Text('Belum Tuntas ❌', style: TextStyle(fontSize: 12.5)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Status Updates Timeline
                  Text(
                    'RIWAYAT PENANGANAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (r.updates.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: const Center(
                        child: Text(
                          'Laporan baru diterima. Menunggu tindak lanjut dari petugas terkait.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    Column(
                      children: r.updates.map((u) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StatusBadge(status: u.status, compact: true),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (u.namaPetugas != null && u.namaPetugas!.isNotEmpty)
                                      Text(
                                        'Petugas: ${u.namaPetugas}',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                      ),
                                    if (u.keterangan != null && u.keterangan!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          u.keterangan!,
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    const SizedBox(height: 4),
                                    Text(
                                      u.createdAtLabel,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF101B15) : Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _toggleVote,
                icon: Icon(
                  r.votedByMe ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                  color: r.votedByMe ? AppColors.emerald : null,
                  size: 18,
                ),
                label: Text('Dukung (${r.voteCount})'),
              ),
            ),
            if (isAdmin) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UpdateStatusPage(report: r),
                      ),
                    );
                    _loadDetail();
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 20),
                  label: const Text('Ubah Status'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
