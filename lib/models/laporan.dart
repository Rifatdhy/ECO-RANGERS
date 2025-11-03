import '../config.dart';

class Laporan {
  int id;
  String judul;
  String deskripsi;
  String lokasi;
  String fotoPath;
  String? fotoUrl;
  String status;
  DateTime tanggal;

  Laporan({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.lokasi,
    required this.fotoPath,
    this.fotoUrl,
    required this.status,
    required this.tanggal,
  });

  // Factory constructor untuk membuat instance Laporan dari JSON
  factory Laporan.fromJson(Map<String, dynamic> m) {
    return Laporan(
      id: m['id'] as int,
      judul: m['judul'] as String? ?? '-',
      deskripsi: m['deskripsi'] as String? ?? '-',
      lokasi: (m['lokasi_text'] as String?) ??
          ((m['lat'] != null && m['lng'] != null)
              ? '${m['lat']}, ${m['lng']}'
              : '-'),
      fotoPath: m['foto_path'] as String? ?? '',
      fotoUrl: imageUrlFrom(m), // Fungsi dari config.dart
      status: m['status'] as String? ?? 'Pending',
      tanggal: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
