import 'package:eco_rangers/ui/app_theme.dart';
import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../models/laporan.dart';
import 'laporan_detail_page.dart';
import 'package:intl/intl.dart';

class DaftarLaporanPage extends StatefulWidget {
  const DaftarLaporanPage({super.key});

  @override
  State<DaftarLaporanPage> createState() => _DaftarLaporanPageState();
}

class _DaftarLaporanPageState extends State<DaftarLaporanPage> {
  late Future<List<Laporan>> _reportsFuture;
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reportsFuture = _apiClient.fetchReportsAsModel();
    });
  }

  void _navigateToDetail(Laporan laporan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LaporanDetailPage(laporan: laporan),
      ),
    );

    if (result == true) {
      _loadReports();
    }
  }

  // Helper untuk mendapatkan warna dan ikon berdasarkan status
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

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadReports(),
        child: FutureBuilder<List<Laporan>>(
          future: _reportsFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Gagal memuat data: ${snap.error}', textAlign: TextAlign.center),
                ),
              );
            }
            final data = snap.data ?? [];
            if (data.isEmpty) {
              return const Center(child: Text('Belum ada laporan untuk ditampilkan.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: data.length,
              itemBuilder: (_, i) => _buildReportCard(data[i], textTheme),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReportCard(Laporan laporan, TextTheme textTheme) {
    final statusInfo = _getStatusInfo(laporan.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToDetail(laporan),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Gambar Laporan
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: laporan.fotoUrl != null
                    ? Image.network(
                        laporan.fotoUrl!,
                        width: 80, height: 80, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
              const SizedBox(width: 16),
              // Info Laporan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(laporan.judul, style: textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                      laporan.deskripsi,
                      style: textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('dd MMM yyyy').format(laporan.createdAt),
                          // FIX: Menggunakan warna dari tema konteks
                          style: textTheme.bodySmall,
                        ),
                        Chip(
                          avatar: Icon(statusInfo.icon, color: Colors.white, size: 16),
                          label: Text(statusInfo.text),
                          backgroundColor: statusInfo.color,
                          labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    )
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
      width: 80, height: 80,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      // FIX: Menggunakan warna dari tema konteks
      child: Center(
        child: Icon(Icons.image, color: Theme.of(context).textTheme.bodyMedium?.color, size: 40),
      ),
    );
  }
}
