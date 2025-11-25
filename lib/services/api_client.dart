import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../models/laporan.dart';
import 'auth_service.dart';

class ApiClient {
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
    XFile? imageFile,
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

    if (imageFile != null) {
      if (kIsWeb) {
        final bytes = await imageFile.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes('foto', bytes, filename: imageFile.name));
      } else {
        req.files.add(await http.MultipartFile.fromPath('foto', imageFile.path));
      }
    }

    final sent = await req.send();
    final res = await http.Response.fromStream(sent);

    if (res.statusCode != 201 && res.statusCode != 200) {
      throw Exception('POST /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Laporan>> fetchReportsAsModel() async {
    final list = await getReports();
    return list.map<Laporan>((e) => Laporan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> updateReportStatus({
    required int id,
    required String status,
    String? namaPetugas,
    String? keterangan,
    XFile? documentationImage,
  }) async {
    final t = await AuthService.instance.getToken();
    final req = http.MultipartRequest('POST', api('/api/reports/$id/status'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer ${t ?? ''}';

    req.fields['status'] = status.toLowerCase();
    if (namaPetugas != null) {
      req.fields['nama_petugas'] = namaPetugas;
    }
    if (keterangan != null) {
      req.fields['keterangan'] = keterangan;
    }
    
    if (documentationImage != null) {
      if (kIsWeb) {
        final bytes = await documentationImage.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes('foto_dokumentasi', bytes, filename: documentationImage.name));
      } else {
        req.files.add(await http.MultipartFile.fromPath('foto_dokumentasi', documentationImage.path));
      }
    }

    final sent = await req.send();
    final res = await http.Response.fromStream(sent);

    if (res.statusCode != 200) {
      throw Exception('POST update status gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

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

  Future<String> clearAllReports() async {
    final t = await AuthService.instance.getToken();
    final res = await http.post(
      api('/api/admin/clear-all-reports'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${t ?? ''}',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Gagal membersihkan laporan: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['message'] ?? 'Proses selesai.';
  }
}
