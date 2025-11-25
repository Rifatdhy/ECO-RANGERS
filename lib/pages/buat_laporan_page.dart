import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../locator.dart';
import '../ui/app_theme.dart';

class BuatLaporanPage extends StatefulWidget {
  const BuatLaporanPage({super.key});

  @override
  State<BuatLaporanPage> createState() => _BuatLaporanPageState();
}

class _BuatLaporanPageState extends State<BuatLaporanPage> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  
XFile? _pickedImage;
  Position? _currentPosition;
  bool _isFetchingLocation = false;
  bool _isSending = false;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(
      source: ImageSource.gallery, // Diubah ke galeri untuk kemudahan di emulator
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (xfile != null) {
      setState(() {
        _pickedImage = xfile;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _pickedImage = null;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Layanan lokasi tidak aktif.")));
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
      });
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Foto laporan tidak boleh kosong."), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lokasi laporan tidak boleh kosong."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      await locator<ApiClient>().createReport(
        judul: _judulController.text,
        deskripsi: _deskripsiController.text,
        lokasiText: '${_currentPosition!.latitude}, ${_currentPosition!.longitude}',
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        imageFile: _pickedImage,
      );
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil dikirim!"), backgroundColor: Colors.green),
      );
      
      Navigator.pop(context);

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal mengirim laporan: $e")));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Laporan Baru"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildDetailsCard(textTheme),
              _buildPhotoCard(textTheme),
              _buildLocationCard(textTheme),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _isSending ? null : _submitReport,
          icon: _isSending ? Container() : const Icon(Icons.send_outlined),
          label: _isSending
              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
              : const Text("Kirim Laporan"),
        ),
      ),
    );
  }

  Widget _buildDetailsCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. Detail Laporan', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _judulController,
              decoration: const InputDecoration(labelText: "Judul Laporan", prefixIcon: Icon(Icons.title)),
              validator: (v) => (v == null || v.isEmpty) ? 'Judul tidak boleh kosong' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deskripsiController,
              decoration: const InputDecoration(labelText: "Deskripsi Singkat", prefixIcon: Icon(Icons.description_outlined)),
              maxLines: 4,
              validator: (v) => (v == null || v.isEmpty) ? 'Deskripsi tidak boleh kosong' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2. Foto Laporan', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            _pickedImage != null ? _buildImagePreview() : _buildImagePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FIX: Menggunakan warna dari tema konteks
              Icon(Icons.add_a_photo_outlined, size: 40, color: Theme.of(context).textTheme.bodyMedium?.color),
              const SizedBox(height: 8),
              Text('Ambil atau Pilih Foto', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: kIsWeb
              ? Image.network(_pickedImage!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
              : Image.file(File(_pickedImage!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
        ),
        Positioned(
          top: -10,
          right: -10,
          child: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.black54,
              child: Icon(Icons.close, color: Colors.white, size: 20),
            ),
            onPressed: _clearImage,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard(TextTheme textTheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3. Lokasi', style: textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_currentPosition != null)
              _buildLocationInfo(textTheme)
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                  icon: _isFetchingLocation ? Container() : const Icon(Icons.my_location),
                  label: _isFetchingLocation
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Dapatkan Lokasi Saat Ini'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lokasi berhasil didapatkan', 
              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _getCurrentLocation,
          )
        ],
      ),
    );
  }
}
