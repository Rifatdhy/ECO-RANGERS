import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../locator.dart';
import '../models/kategori.dart';
import '../services/api_client.dart';
import '../ui/tokens.dart';

class BuatLaporanPage extends StatefulWidget {
  const BuatLaporanPage({super.key});

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  final _picker = ImagePicker();
  final _judulCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _kategori = 'sampah';

  int _step = 0;
  XFile? _picked;
  bool _submitting = false;

  double? _lat;
  double? _lng;
  String? _locText;
  bool _locLoading = false;

  static const _labels = ['Foto', 'Lokasi', 'Detail', 'Pratinjau'];

  @override
  void dispose() {
    _judulCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canNext => switch (_step) {
        0 => _picked != null,
        1 => true,
        2 => _judulCtrl.text.trim().length >= 5 && _descCtrl.text.trim().length >= 10,
        _ => true,
      };

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (!mounted) return;
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

      final p = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      setState(() {
        _lat = p.latitude;
        _lng = p.longitude;
        _locText = '${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}';
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
    setState(() => _submitting = true);
    try {
      final result = await locator<ApiClient>().createReport(
        judul: _judulCtrl.text.trim(),
        kategori: _kategori,
        deskripsi: _descCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        lokasiText: _locText,
        imageFile: _picked,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Laporan berhasil dikirim')));
      Navigator.pop(context, result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal kirim laporan: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (_step == 0) {
              Navigator.pop(context);
            } else {
              setState(() => _step--);
            }
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withValues(alpha: 0.06), Theme.of(context).colorScheme.surface],
          ),
        ),
        child: Column(
          children: [
            _StepIndicator(current: _step, labels: _labels),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: _buildStep(_step),
              ),
            ),
            _buildFooter(theme: Theme.of(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int step) {
    switch (step) {
      case 0:
        return _StepPanel(
          key: const ValueKey('step-photo'),
          icon: Icons.add_a_photo_outlined,
          title: 'Ambil foto dulu',
          subtitle: 'Foto bukti membantu tim memverifikasi laporan lebih cepat.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  onTap: _pickImage,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 240,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                      color: AppColors.accent.withValues(alpha: 0.08),
                    ),
                    child: _picked == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined, size: 56, color: AppColors.primary),
                              SizedBox(height: 12),
                              Text('Ketuk untuk pilih foto'),
                              SizedBox(height: 4),
                              Text('dari galeri', style: TextStyle(color: AppColors.textMuted)),
                            ],
                          )
                        : kIsWeb
                            ? Image.network(_picked!.path, fit: BoxFit.cover)
                            : Image.file(File(_picked!.path), fit: BoxFit.cover),
                  ),
                ),
              ),
            ],
          ),
        );
      case 1:
        return _StepPanel(
          key: const ValueKey('step-location'),
          icon: Icons.my_location_rounded,
          title: 'Tandai lokasi kejadian',
          subtitle: 'Koordinat membantu tim penanganan menjangkau area.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_lat == null)
                OutlinedButton.icon(
                  onPressed: _locLoading ? null : _getLocation,
                  icon: _locLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.gps_fixed_rounded),
                  label: const Text('Ambil lokasi saat ini'),
                )
              else
                _locCard(),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Lokasi opsional — kamu bisa lanjut tanpa lokasi.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        );
      case 2:
        return _StepPanel(
          key: const ValueKey('step-detail'),
          icon: Icons.edit_note_rounded,
          title: 'Jelaskan temuan',
          subtitle: 'Judul yang jelas dan deskripsi ringkas mempercepat penanganan.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _kategori,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: reportCategories
                    .map((c) => DropdownMenuItem(
                          value: c.value,
                          child: Text('${c.icon} ${c.label}'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _kategori = v ?? 'laimnya'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _judulCtrl,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(labelText: 'Judul laporan', hintText: 'Contoh: Sampah menumpuk di jalan'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _descCtrl,
                onChanged: (_) => setState(() {}),
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  hintText: 'Ceritakan kondisi lokasi secara singkat dan jelas',
                ),
              ),
            ],
          ),
        );
      default:
        return _StepPanel(
          key: const ValueKey('step-preview'),
          icon: Icons.visibility_outlined,
          title: 'Periksa kembali laporan',
          subtitle: 'Pastikan semua informasi sudah benar sebelum dikirim.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_picked != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: kIsWeb
                      ? Image.network(_picked!.path, height: 180, fit: BoxFit.cover)
                      : Image.file(File(_picked!.path), height: 180, fit: BoxFit.cover),
                ),
              const SizedBox(height: AppSpacing.md),
              _previewRow(Icons.category_outlined, 'Kategori', '${kategoriIcon(_kategori)} ${kategoriLabel(_kategori)}'),
              const Divider(),
              _previewRow(Icons.title_rounded, 'Judul', _judulCtrl.text.trim()),
              const Divider(),
              _previewRow(Icons.edit_outlined, 'Deskripsi', _descCtrl.text.trim()),
              const Divider(),
              _previewRow(Icons.location_on_outlined, 'Lokasi', _locText ?? 'Tidak tersedia'),
            ],
          ),
        );
    }
  }

  Widget _locCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(_locText ?? '', style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(onPressed: _getLocation, child: const Text('Ulangi')),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter({required ThemeData theme}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
      child: FilledButton(
        onPressed: _canNext && !_submitting ? _next : null,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _submitting
              ? const SizedBox(key: ValueKey('loading'), width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_step == 3 ? 'Kirim laporan' : 'Lanjut', key: ValueKey('text')),
        ),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.labels});

  final int current;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: i <= current ? AppColors.primary : AppColors.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            _dot(context, i),
          ],
        ],
      ),
    );
  }

  Widget _dot(BuildContext context, int i) {
    final active = i <= current;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 30 : 12,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.accent.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${i + 1}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          labels[i],
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? AppColors.primary : AppColors.textMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    if (subtitle != null)
                      Text(subtitle ?? '', style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}