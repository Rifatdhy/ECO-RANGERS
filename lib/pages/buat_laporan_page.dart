import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../locator.dart';
import '../services/api_client.dart';
import '../ui/tokens.dart';

/// BuatLaporanPage bergaya Apple Camera Studio Form:
/// Pengambilan foto terarah dengan preview clean,
/// deteksi GPS instan multi-strategi (Geolocator + IP Geolocation),
/// pemilihan kategori chip elegan, dan tombol submit presisi.
class BuatLaporanPage extends StatefulWidget {
  const BuatLaporanPage({super.key});

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  final ApiClient _apiClient = locator<ApiClient>();
  final ImagePicker _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _lokasiTextController = TextEditingController();

  String _selectedCategory = 'sampah';
  XFile? _imageFile;
  double? _latitude;
  double? _longitude;

  bool _isGettingLocation = false;
  bool _isSubmitting = false;

  final List<({String key, String label, IconData icon})> _categories = [
    (key: 'sampah', label: 'Sampah', icon: Icons.delete_outline_rounded),
    (key: 'pencemaran', label: 'Pencemaran', icon: Icons.water_damage_outlined),
    (key: 'infrastruktur', label: 'Infrastruktur', icon: Icons.construction_outlined),
    (key: 'fauna', label: 'Fauna', icon: Icons.pets_outlined),
    (key: 'flora', label: 'Flora', icon: Icons.forest_outlined),
    (key: 'laimnya', label: 'Lainnya', icon: Icons.category_outlined),
  ];

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _lokasiTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _imageFile = file);
      }
    } catch (_) {}
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    double? lat;
    double? lng;
    String? city;

    // Strategi 1: GPS Hardware / Browser
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 4),
        ),
      ).timeout(const Duration(seconds: 4));

      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}

    // Strategi 2: IP Geolocation Fallback
    if (lat == null || lng == null) {
      try {
        final res = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 3));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          lat = (data['latitude'] as num?)?.toDouble();
          lng = (data['longitude'] as num?)?.toDouble();
          city = data['city'] as String?;
        }
      } catch (_) {}
    }

    // Default
    lat ??= -6.2088;
    lng ??= 106.8456;

    if (mounted) {
      setState(() {
        _latitude = lat;
        _longitude = lng;
        _lokasiTextController.text = city != null && city.isNotEmpty
            ? '$city (${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)})'
            : '${lat!.toStringAsFixed(5)}, ${lng!.toStringAsFixed(5)}';
        _isGettingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi berhasil disematkan: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await _apiClient.createReport(
        judul: _judulController.text.trim(),
        kategori: _selectedCategory,
        deskripsi: _deskripsiController.text.trim(),
        lat: _latitude,
        lng: _longitude,
        lokasiText: _lokasiTextController.text.trim().isNotEmpty
            ? _lokasiTextController.text.trim()
            : null,
        imageFile: _imageFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan Anda berhasil dikirim!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim: ${e.toString().replaceAll("Exception: ", "")}')),
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
        title: const Text('Buat Laporan Baru'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Picker Container (Apple Camera Canvas)
              _buildPhotoPicker(isDark),
              const SizedBox(height: 24),

              // Category Selector
              Text(
                'KATEGORI ISU',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final isSelected = c.key == _selectedCategory;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = c.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isDark ? const Color(0xFF52B788) : AppColors.forest)
                            : (isDark ? const Color(0xFF14201A) : AppColors.surface),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: isSelected
                              ? Colors.transparent
                              : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.line),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            c.icon,
                            size: 16,
                            color: isSelected
                                ? (isDark ? const Color(0xFF081C12) : Colors.white)
                                : (isDark ? AppColors.darkTextColor : AppColors.ink),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            c.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF081C12) : Colors.white)
                                  : (isDark ? AppColors.darkTextColor : AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Details Form Fields
              Text(
                'RINCIAN LAPORAN',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.darkMutedTextColor : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: 'Judul Masalah',
                  hintText: 'Mis: Tumpukan sampah di saluran air',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 5) {
                    return 'Judul laporan minimal 5 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _deskripsiController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Masalah',
                  hintText: 'Jelaskan kronologi, dampak lingkungan, dan lokasi pasti...',
                ),
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Deskripsi laporan minimal 10 karakter';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Location Input with GPS Quick Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lokasiTextController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat / Patokan Lokasi',
                        hintText: 'Jl. Ahmad Yani No. 12 atau titik patokan',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _isGettingLocation ? null : _getCurrentLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1B4D36) : AppColors.mintGlow,
                      foregroundColor: isDark ? Colors.white : AppColors.emerald,
                      minimumSize: const Size(54, 52),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        side: BorderSide(
                          color: AppColors.emerald.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: _isGettingLocation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.emerald),
                          )
                        : const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Action
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : const Text(
                        'Kirim Laporan Sekarang',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker(bool isDark) {
    if (_imageFile != null) {
      return Stack(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.line),
              image: DecorationImage(
                image: kIsWeb
                    ? NetworkImage(_imageFile!.path)
                    : FileImage(File(_imageFile!.path)) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: GestureDetector(
              onTap: () => setState(() => _imageFile = null),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF14201A) : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.line,
          style: BorderStyle.solid,
        ),
        boxShadow: AppShadows.luxuryCard,
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B3D2B) : AppColors.mintGlow,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.camera_alt_outlined,
              size: 26,
              color: isDark ? const Color(0xFF52B788) : AppColors.emerald,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Lampirkan Bukti Foto',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Foto yang jelas mempercepat penanganan oleh petugas',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkMutedTextColor : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Kamera'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library_rounded, size: 16),
                label: const Text('Galeri'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
