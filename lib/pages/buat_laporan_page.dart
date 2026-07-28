import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../locator.dart';
import '../services/api_client.dart';
import '../ui/app_theme.dart';

class BuatLaporanPage extends StatefulWidget {
  const BuatLaporanPage({super.key});

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  XFile? _picked;
  bool _loading = false;

  double? _lat;
  double? _lng;
  String? _locText;
  bool _locLoading = false;

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (x != null) setState(() => _picked = x);
  }

  Future<void> _getLocation() async {
    setState(() => _locLoading = true);
    try {
      final service = await Geolocator.isLocationServiceEnabled();
      if (!service) throw 'Layanan lokasi belum aktif';

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) throw 'Izin lokasi ditolak permanen';
      if (perm == LocationPermission.denied) throw 'Izin lokasi ditolak';

      final p = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
        _locText = 'Lat: ${p.latitude.toStringAsFixed(6)}, Lng: ${p.longitude.toStringAsFixed(6)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lokasi gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _locLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final result = await locator<ApiClient>().createReport(
        judul: _judulCtrl.text.trim(),
        deskripsi: _descCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        lokasiText: _locText,
        imageFile: _picked,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan berhasil dikirim')),
      );
      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal kirim laporan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Bantuan',
            onPressed: () async {
              final url = Uri.parse('https://wa.me/6281234567890?text=Halo%20saya%20butuh%20bantuan%20laporan');
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.08),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 52,
                        width: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Laporkan temuan lapangan',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sertakan judul, deskripsi, foto, dan lokasi agar lebih mudah ditindaklanjuti.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                TextFormField(
                  controller: _judulCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Judul laporan',
                    hintText: 'Contoh: Sampah menumpuk di jalan',
                  ),
                  validator: (v) => (v == null || v.trim().length < 5) ? 'Judul terlalu pendek' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    hintText: 'Ceritakan kondisi lokasi secara singkat dan jelas',
                  ),
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Deskripsi terlalu pendek' : null,
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Foto pendukung',
                  subtitle: 'Unggah foto agar laporan lebih mudah diverifikasi.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.image_outlined),
                        label: Text(_picked == null ? 'Pilih foto dari galeri' : 'Ganti foto'),
                      ),
                      if (_picked != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: kIsWeb
                              ? Image.network(_picked!.path, height: 220, fit: BoxFit.cover)
                              : Image.file(File(_picked!.path), height: 220, fit: BoxFit.cover),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _SectionCard(
                  title: 'Lokasi saat ini',
                  subtitle: 'Gunakan titik lokasi agar tim lebih cepat menemukan area.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _locLoading ? null : _getLocation,
                        icon: _locLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded),
                        label: Text(_lat == null ? 'Ambil lokasi saat ini' : 'Lokasi tersimpan'),
                      ),
                      if (_locText != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _locText!,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _loading
                        ? const SizedBox(
                            key: ValueKey('submit-loading'),
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Kirim laporan',
                            key: ValueKey('submit-text'),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}