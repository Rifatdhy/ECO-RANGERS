import 'package:eco_rangers/config.dart';

class ReportUpdate {
  final int id;
  final int reportId;
  final String status;
  final String? keterangan;
  final String? namaPetugas;
  final String? fotoDokumentasiPath;
  final String? fotoDokumentasiUrl;
  final DateTime createdAt;

  ReportUpdate({
    required this.id,
    required this.reportId,
    required this.status,
    this.keterangan,
    this.namaPetugas,
    this.fotoDokumentasiPath,
    this.fotoDokumentasiUrl,
    required this.createdAt,
  });

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    final docPath = json['foto_dokumentasi'] as String?;
    return ReportUpdate(
      id: (json['id'] as num?)?.toInt() ?? 0,
      reportId: (json['report_id'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'unknown',
      keterangan: json['keterangan'] as String?,
      namaPetugas: json['nama_petugas'] as String?,
      fotoDokumentasiPath: docPath,
      fotoDokumentasiUrl: docPath != null ? imageUrlFrom({'foto_path': docPath}) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
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
