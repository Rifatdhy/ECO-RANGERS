import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../locator.dart';
import '../models/laporan.dart';
import '../services/api_client.dart';
import '../ui/tokens.dart';

/// UpdateStatusPage khusus Admin untuk merubah status laporan dan melampirkan dokumentasi pengerjaan.
class UpdateStatusPage extends StatefulWidget {
  final Laporan report;

  const UpdateStatusPage({super.key, required this.report});

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  final ApiClient _apiClient = locator<ApiClient>();
  final ImagePicker _picker = ImagePicker();

  late String _status;
  final _petugasController = TextEditingController();
  final _keteranganController = TextEditingController();
  XFile? _docImage;
  bool _isSubmitting = false;

  final List<String> _statuses = ['pending', 'diproses', 'selesai', 'ditolak'];

  @override
  void initState() {
    super.initState();
    _status = widget.report.status.toLowerCase();
  }

  @override
  void dispose() {
    _petugasController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pickDocImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) setState(() => _docImage = file);
    } catch (_) {}
  }

  Future<void> _submitStatusUpdate() async {
    setState(() => _isSubmitting = true);

    try {
      await _apiClient.updateReportStatus(
        id: widget.report.id,
        status: _status,
        namaPetugas: _petugasController.text.trim().isNotEmpty ? _petugasController.text.trim() : null,
        keterangan: _keteranganController.text.trim().isNotEmpty ? _keteranganController.text.trim() : null,
        documentationImage: _docImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status laporan berhasil diperbarui')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perbarui Status'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Report Overview
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14201A) : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ID LAPORAN: #${widget.report.id}',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.report.judul,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Status Selector
            const Text(
              'PILIH STATUS BARU',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statuses.map((st) {
                final isSelected = st == _status;
                return GestureDetector(
                  onTap: () => setState(() => _status = st),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? (isDark ? const Color(0xFF52B788) : AppColors.forest) : (isDark ? const Color(0xFF14201A) : AppColors.surface),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: Border.all(color: isSelected ? Colors.transparent : AppColors.line),
                    ),
                    child: Text(
                      st.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : AppColors.ink),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Form Inputs
            TextFormField(
              controller: _petugasController,
              decoration: const InputDecoration(
                labelText: 'Nama Petugas / Tim Penangan',
                hintText: 'Mis: Tim Reaksi Cepat DLH',
              ),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: _keteranganController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan & Kronologi Tindak Lanjut',
                hintText: 'Jelaskan hasil pekerjaan di lapangan...',
              ),
            ),
            const SizedBox(height: 20),

            // Documentation Photo
            const Text(
              'FOTO BUKTI PENANGANAN (OPSIONAL)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            if (_docImage != null)
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.line),
                      image: DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(_docImage!.path)
                            : FileImage(File(_docImage!.path)) as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() => _docImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDocImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded, size: 16),
                      label: const Text('Ambil Foto'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickDocImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded, size: 16),
                      label: const Text('Pilih Galeri'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitStatusUpdate,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Simpan Pembaruan Status'),
            ),
          ],
        ),
      ),
    );
  }
}
