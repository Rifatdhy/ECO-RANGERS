import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/laporan.dart';
import 'auth_service.dart';

class ApiClient {
  // Mengembalikan List<Map<String, dynamic>> mentah
  Future<List<dynamic>> getReports() async {
    final t = await AuthService.instance.getToken();
    final res = await http.get(
      api('/api/reports'),
      headers: {
        'Accept': 'application/json',
        if (t != null) 'Authorization': 'Bearer $t',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('GET /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as List;
  }

  Future<Map<String, dynamic>> createReport({
    required String judul,
    required String deskripsi,
    double? lat,
    double? lng,
    String? lokasiText,
    String? imagePath, // path file lokal (Android)
  }) async {
    final req = http.MultipartRequest('POST', api('/api/reports'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] =
          'Bearer ' + ((await AuthService.instance.getToken()) ?? '')
      ..fields.addAll({
        'judul': judul,
        'deskripsi': deskripsi,
        if (lat != null) 'lat': '$lat',
        if (lng != null) 'lng': '$lng',
        if (lokasiText != null) 'lokasi_text': lokasiText,
      });

    if (imagePath != null && imagePath.isNotEmpty) {
      req.files.add(await http.MultipartFile.fromPath('foto', imagePath));
    }

    final sent = await req.send();
    final res = await http.Response.fromStream(sent);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('POST /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ===== Perbaikan baru untuk Admin =====

  /// Ambil list laporan dan langsung dipetakan ke model [Laporan]
  Future<List<Laporan>> fetchReportsAsModel() async {
    final list = await getReports();
    // Gunakan Laporan.fromJson untuk parsing
    return list.map<Laporan>((e) => Laporan.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Ubah status laporan (Pending/Diproses/Selesai)
  Future<Map<String, dynamic>> updateStatus(int id, String status) async {
    final t = await AuthService.instance.getToken();
    final res = await http.patch(
      api('/api/reports/$id/status'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (t != null) 'Authorization': 'Bearer $t',
      },
      body: jsonEncode({'status': status.toLowerCase()}),
    );
    if (res.statusCode != 200) {
      throw Exception('PATCH status gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Hapus laporan
  Future<void> deleteReport(int id) async {
    final t = await AuthService.instance.getToken();
    final res = await http.delete(
      api('/api/reports/$id'),
      headers: {
        'Accept': 'application/json',
        if (t != null) 'Authorization': 'Bearer $t',
      },
    );
    if (res.statusCode != 200) {
      throw Exception('DELETE gagal: ${res.statusCode} ${res.body}');
    }
  }
}
