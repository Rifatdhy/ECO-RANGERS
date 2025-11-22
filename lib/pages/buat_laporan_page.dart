import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import '../locator.dart';

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
  String? _lokasi; 
  bool _isSending = false;

  Future<void> _ambilFoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );

    if (xfile != null) {
      setState(() {
        _pickedImage = xfile;
      });
    }
  }

  Future<void> _ambilLokasi() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lokasi tidak aktif")));
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _lokasi = "${pos.latitude}, ${pos.longitude}";
    });
  }

  Future<void> _kirimLaporan() async {
    if (!_formKey.currentState!.validate() || _pickedImage == null || _lokasi == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data terlebih dahulu")),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      double? lat;
      double? lng;
      if (_lokasi != null && _lokasi!.contains(',')) {
        final parts = _lokasi!.split(',');
        lat = double.tryParse(parts[0].trim());
        lng = double.tryParse(parts[1].trim());
      }

      await locator<ApiClient>().createReport(
        judul: _judulController.text,
        deskripsi: _deskripsiController.text,
        lokasiText: _lokasi,
        lat: lat,
        lng: lng,
        imageFile: _pickedImage,
      );
      
      if (!mounted) return; // Cek sebelum menampilkan SnackBar dan navigasi

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Laporan berhasil dikirim!")),
      );
      
      // DIUBAH: Kembali ke halaman sebelumnya (Dashboard)
      Navigator.pop(context);

    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal kirim: $e")));
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Buat Laporan"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                  labelText: "Judul Laporan",
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(
                  labelText: "Deskripsi",
                ),
                maxLines: 3,
                validator: (v) => (v == null || v.isEmpty) ? 'Deskripsi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              if (_pickedImage != null)
                kIsWeb
                  ? Image.network(_pickedImage!.path, height: 150)
                  : Image.file(File(_pickedImage!.path), height: 150)
              else 
                const Text("Belum ada foto"),

              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _ambilFoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text("Ambil Foto"),
              ),
              const SizedBox(height: 16),
              _lokasi != null
                  ? Text("Lokasi: $_lokasi")
                  : const Text("Belum ada lokasi"),
              ElevatedButton.icon(
                onPressed: _ambilLokasi,
                icon: const Icon(Icons.location_on),
                label: const Text("Ambil Lokasi"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSending ? null : _kirimLaporan,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: _isSending 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("Kirim Laporan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
