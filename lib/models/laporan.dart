import 'package:eco_rangers/models/report_update.dart';
import '../config.dart';

// Model sederhana untuk merepresentasikan data pengguna
class User {
  final int id;
  final String nama;
  final String email;

  User({required this.id, required this.nama, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      nama: json['name'] as String,
      email: json['email'] as String,
    );
  }
}


class Laporan {
  final int id;
  final String judul;
  final String deskripsi;
  final String? lokasiText;
  final double? latitude;
  final double? longitude;
  final String? fotoPath;
  final String? fotoUrl;
  String status; // Status terakhir, bisa diupdate
  final DateTime createdAt;
  final User? user; // Tambahkan properti user

  // DIUBAH: Gunakan List dari ReportUpdate
  final List<ReportUpdate> updates;

  Laporan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    this.lokasiText,
    this.latitude,
    this.longitude,
    this.fotoPath,
    this.fotoUrl,
    required this.status,
    required this.createdAt,
    this.updates = const [], // Default ke list kosong
    this.user, // Tambahkan di konstruktor
  });

  factory Laporan.fromJson(Map<String, dynamic> json) {
    final fotoPath = json['foto_path'] as String?;
    
    // Parsing list `updates` dari JSON
    var updatesList = <ReportUpdate>[];
    if (json['updates'] != null) {
      updatesList = (json['updates'] as List)
          .map((i) => ReportUpdate.fromJson(i as Map<String, dynamic>))
          .toList();
    }
    
    // Parsing data `user` dari JSON
    final userJson = json['user'];
    final User? user = userJson != null ? User.fromJson(userJson as Map<String, dynamic>) : null;

    return Laporan(
      id: json['id'] as int,
      judul: json['judul'] as String? ?? 'Tanpa Judul',
      deskripsi: json['deskripsi'] as String? ?? 'Tanpa Deskripsi',
      latitude: (json['lat'] as num?)?.toDouble(),
      longitude: (json['lng'] as num?)?.toDouble(),
      lokasiText: (json['lokasi_text'] as String?) ?? (json['lat'] != null && json['lng'] != null ? '${json['lat']}, ${json['lng']}' : null),
      fotoPath: fotoPath,
      fotoUrl: fotoPath != null ? imageUrlFrom({'foto_path': fotoPath}) : null,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updates: updatesList,
      user: user,
    );
  }
}
