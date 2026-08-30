import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../locator.dart';
import '../models/laporan.dart';
import '../services/api_client.dart';

class UpdateStatusPage extends StatefulWidget {
  final Laporan laporan;

  const UpdateStatusPage({super.key, required this.laporan});

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();
  final _namaPetugasController = TextEditingController();
  final _keteranganController = TextEditingController();
  XFile? _documentationImage;
  String? _selectedStatus;
  bool _isLoading = false;

  final _apiClient = locator<ApiClient>();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.laporan.status.toLowerCase();
  }

  @override
  void dispose() {
    _namaPetugasController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (mounted) {
      setState(() {
        _documentationImage = pickedFile;
      });
    }
  }

  void _clearImage() {
    setState(() {
      _documentationImage = null;
    });
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.updateReportStatus(
        id: widget.laporan.id,
        status: _selectedStatus!,
        namaPetugas: _namaPetugasController.text,
        keterangan: _keteranganController.text,
        documentationImage: _documentationImage,
      );
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status laporan berhasil diperbarui'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Status Laporan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Laporan: ${widget.laporan.judul}', style: textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 24),
              _buildStatusDropdown(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _keteranganController,
                label: 'Keterangan / Catatan',
                icon: Icons.notes,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _namaPetugasController,
                label: 'Nama Petugas (Opsional)',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),
              Text('Foto Dokumentasi (Opsional)', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              _buildImagePicker(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildSubmitButton(),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status Laporan',
        prefixIcon: Icon(Icons.flag_outlined),
      ),
      items: ['pending', 'diproses', 'selesai', 'ditolak'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value[0].toUpperCase() + value.substring(1)), // Capitalize first letter
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedStatus = newValue;
        });
      },
      validator: (value) => value == null || value.isEmpty ? 'Status tidak boleh kosong' : null,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildImagePicker() {
    if (_documentationImage != null) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: kIsWeb
                ? Image.network(_documentationImage!.path, height: 200, width: double.infinity, fit: BoxFit.cover)
                : Image.file(File(_documentationImage!.path), height: 200, width: double.infinity, fit: BoxFit.cover),
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

    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 8),
              Text('Tambah Foto', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submitUpdate,
      icon: _isLoading ? Container() : const Icon(Icons.save_alt_outlined),
      label: _isLoading
          ? const SizedBox(
              height: 24, width: 24,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            )
          : const Text('Simpan Perubahan'),
    );
  }
}
