import 'package:eco_rangers/models/report_update.dart';
import 'package:eco_rangers/models/user.dart';

import '../config.dart';

class Laporan {
  final int id;
  final String judul;
  final String kategori;
  final String deskripsi;
  final String? lokasiText;
  final double? latitude;
  final double? longitude;
  final String? fotoPath;
  final String? fotoUrl;
  String status; // Status terakhir, bisa diupdate
  final DateTime createdAt;
  final User? user;
  final List<ReportUpdate> updates;

  Laporan({
    required this.id,
    required this.judul,
    this.kategori = 'laimnya',
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

  String get lokasi {
    if (latitude != null && longitude != null) {
      return '$latitude,$longitude';
    }
    return lokasiText ?? 'Lokasi tidak tersedia';
  }

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
      kategori: (json['kategori'] as String? ?? 'laimnya').toLowerCase(),
      deskripsi: json['deskripsi'] as String? ?? 'Tanpa Deskripsi',
      latitude: (json['lat'] as num?)?.toDouble(),
      longitude: (json['lng'] as num?)?.toDouble(),
      lokasiText: (json['lokasi_text'] as String?) ?? (json['lat'] != null && json['lng'] != null ? '${json['lat']}, ${json['lng']}' : null),
      fotoPath: fotoPath,
      fotoUrl: fotoPath != null ? imageUrlFrom({'foto_path': fotoPath}) : null,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updates: updatesList,
      user: user,
    );
  }

  String get createdAtLabel {
    final d = createdAt;
    final day = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final year = d.year;
    final hour = d.hour.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}
