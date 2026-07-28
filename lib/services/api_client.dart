import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../models/laporan.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  ApiException({required this.message, this.statusCode, this.data});
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException({required this.message});
  @override
  String toString() => 'NetworkException: $message';
}

class ApiClient {
  static const Duration _timeout = Duration(seconds: 15);
  static const int _maxRetries = 2;

  http.Client? _httpClient;
  set httpClient(http.Client? client) => _httpClient = client;

  Future<http.Response> _request(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final client = _httpClient ?? http.Client();
        try {
          final req = http.Request(method, uri)
            ..headers.addAll(headers ?? {})
            ..body = body ?? '';
          final res = await client.send(req).timeout(_timeout);
          return await http.Response.fromStream(res);
        } finally {
          if (_httpClient == null) client.close();
        }
      } on http.ClientException {
        if (attempt == _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      } on TimeoutException {
        if (attempt == _maxRetries) throw NetworkException(message: 'Permintaan timeout setelah ${_timeout.inSeconds} detik');
        await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
      }
    }
    throw NetworkException(message: 'Permintaan gagal setelah $_maxRetries percobaan');
  }

  String _authHeader(String? token) {
    if (token == null || token.isEmpty) return '';
    return 'Bearer $token';
  }

  Future<List<dynamic>> getReports({String? status}) async {
    final t = await AuthService.instance.getToken();

    var path = '/api/reports';
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'semua') {
      path += '?status=${status.toLowerCase()}';
    }

    final headers = {
      'Accept': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };

    final res = await _request('GET', api(path), headers: headers);
    if (res.statusCode != 200) {
      throw ApiException(message: 'Gagal memuat laporan', statusCode: res.statusCode, data: res.body);
    }
    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;
    return (decoded['data'] as List?) ?? [];
  }

  Future<Map<String, dynamic>> createReport({
    required String judul,
    required String deskripsi,
    double? lat,
    double? lng,
    String? lokasiText,
    XFile? imageFile,
  }) async {
    final t = await AuthService.instance.getToken();
    final req = http.MultipartRequest('POST', api('/api/reports'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = _authHeader(t)
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

    final sent = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(sent);
    if (res.statusCode != 201 && res.statusCode != 200) {
      throw ApiException(message: 'Gagal membuat laporan', statusCode: res.statusCode, data: res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Laporan>> fetchReportsAsModel({String? status}) async {
    final list = await getReports(status: status);
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
      ..headers['Authorization'] = _authHeader(t);

    req.fields['status'] = status.toLowerCase();
    if (namaPetugas != null) req.fields['nama_petugas'] = namaPetugas;
    if (keterangan != null) req.fields['keterangan'] = keterangan;

    if (documentationImage != null) {
      if (kIsWeb) {
        final bytes = await documentationImage.readAsBytes();
        req.files.add(http.MultipartFile.fromBytes('foto_dokumentasi', bytes, filename: documentationImage.name));
      } else {
        req.files.add(await http.MultipartFile.fromPath('foto_dokumentasi', documentationImage.path));
      }
    }

    final sent = await req.send().timeout(_timeout);
    final res = await http.Response.fromStream(sent);
    if (res.statusCode != 200) {
      throw ApiException(message: 'Gagal memperbarui status', statusCode: res.statusCode, data: res.body);
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> deleteReport(int id) async {
    final t = await AuthService.instance.getToken();
    final res = await _request(
      'DELETE',
      api('/api/reports/$id'),
      headers: {
        'Accept': 'application/json',
        if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
      },
    );
    if (res.statusCode != 200) {
      throw ApiException(message: 'Gagal menghapus laporan', statusCode: res.statusCode, data: res.body);
    }
  }

  Future<String> clearAllReports() async {
    final t = await AuthService.instance.getToken();
    final res = await _request(
      'POST',
      api('/api/admin/clear-all-reports'),
      headers: {
        'Accept': 'application/json',
        if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
      },
    );
    if (res.statusCode != 200) {
      throw ApiException(message: 'Gagal membersihkan laporan', statusCode: res.statusCode, data: res.body);
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['message'] ?? 'Proses selesai.';
  }
}
