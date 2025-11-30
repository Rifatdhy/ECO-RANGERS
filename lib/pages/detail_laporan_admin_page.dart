import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Impor paket url_launcher

import '../models/laporan.dart';
import '../services/api_client.dart';
import '../config.dart';
import '../locator.dart';

class DetailLaporanAdminPage extends StatefulWidget {
  final Laporan laporan;
  final Function(Laporan, String) onUpdate;
  const DetailLaporanAdminPage({
    super.key,
    required this.laporan,
    required this.onUpdate,
  });

  @override
  State<DetailLaporanAdminPage> createState() => _DetailLaporanAdminPageState();
}

class _DetailLaporanAdminPageState extends State<DetailLaporanAdminPage> {
  late String _status;
  final _api = locator<ApiClient>();
  bool _saving = false;
  final _statusOptions = ['Pending', 'Diproses', 'Selesai', 'Ditolak'];

  @override
  void initState() {
    super.initState();
    _status = _statusOptions.firstWhere(
      (s) => s.toLowerCase() == widget.laporan.status.toLowerCase(),
      orElse: () => 'Pending', 
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _api.updateReportStatus(id: widget.laporan.id, status: _status);
      widget.onUpdate(widget.laporan, _status);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal update: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Fungsi untuk membuka lokasi di Google Maps
  Future<void> _openMap(String location) async {
    // Hapus spasi dan pastikan formatnya benar (lat,lng)
    final sanitizedLocation = location.replaceAll(' ', '');
    final uri = Uri.tryParse('https://www.google.com/maps/search/?api=1&query=$sanitizedLocation');

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak bisa membuka peta untuk lokasi: $location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? imgUrl =
        widget.laporan.fotoUrl ??
        (widget.laporan.fotoPath != null && widget.laporan.fotoPath!.isNotEmpty
            ? '$baseUrl/storage/${widget.laporan.fotoPath}'
            : null);
    
    // Cek apakah lokasi mengandung koma, yang menandakan itu adalah koordinat
    final bool isCoordinate = widget.laporan.lokasi.contains(',');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Laporan Admin'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.laporan.judul,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Deskripsi: ${widget.laporan.deskripsi}'),
            const SizedBox(height: 8),
            
            // Widget lokasi yang bisa diklik
            InkWell(
              onTap: isCoordinate ? () => _openMap(widget.laporan.lokasi) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: isCoordinate ? Theme.of(context).colorScheme.primary : Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.laporan.lokasi,
                        style: TextStyle(
                          color: isCoordinate ? Theme.of(context).colorScheme.primary : Colors.black,
                          decoration: isCoordinate ? TextDecoration.underline : TextDecoration.none,
                        ),
                      ),
                    ),
                    if(isCoordinate) const Icon(Icons.open_in_new, size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // TAMPILKAN GAMBAR DARI SERVER
            if (imgUrl != null)
              Image.network(
                imgUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, color: Colors.grey, size: 100),
              ),

            const SizedBox(height: 24),
            DropdownButton<String>(
              value: _status,
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) => setState(() => _status = val!),
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Update Status'),
            ),
          ],
        ),
      ),
    );
  }
}
