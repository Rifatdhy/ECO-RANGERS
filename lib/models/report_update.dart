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
      id: json['id'],
      reportId: json['report_id'],
      status: json['status'] ?? 'unknown',
      keterangan: json['keterangan'] as String?,
      namaPetugas: json['nama_petugas'] as String?,
      fotoDokumentasiPath: docPath,
      fotoDokumentasiUrl: docPath != null ? imageUrlFrom({'foto_path': docPath}) : null,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}
