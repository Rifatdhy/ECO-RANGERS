import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config.dart';
import '../models/laporan.dart';
import '../session.dart';
import '../utils/image_utils.dart';
import 'auth_service.dart';

class ApiClient {
  static const _timeout = Duration(seconds: 15);
  static const _maxRetries = 3;
  static const _retryDelay = Duration(milliseconds: 500);

  // Satu client HTTP di-reuse seluruh method → connexion pooling,
  // tanpa TLS/TCP handshake baru tiap request.
  final http.Client _client = http.Client();

  /// Jika token tak valid/expired, bersihkan sesi & arahkan ke halaman login.
  void _checkAuth(http.Response res) {
    if (res.statusCode == 401) {
      handleSessionExpired();
    }
  }

  /// Execute with retry logic untuk network resilience
  static Future<T> _guard<T>(Future<T> future, String op, {int maxRetries = _maxRetries}) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        return await future.timeout(_timeout);
      } on Exception catch (e) {
        if (e.toString().contains('timeout')) {
          if (attempts >= maxRetries) throw Exception('$op timeout setelah ${_timeout.inSeconds}s');
          await Future.delayed(_retryDelay * attempts);
          continue;
        }
        if (e is SocketException) {
          if (attempts >= maxRetries) throw Exception('Koneksi internet tidak tersedia');
          await Future.delayed(_retryDelay * attempts);
          continue;
        }
        rethrow;
      }
    }
  }

  Future<List<dynamic>> getReports({String? status, String? kategori, String? q, int? limit, int? offset}) async {
    final t = await AuthService.instance.getToken();

    final query = <String, String>{
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'semua')
        'status': status.toLowerCase(),
      if (kategori != null && kategori.isNotEmpty && kategori.toLowerCase() != 'semua')
        'kategori': kategori.toLowerCase(),
      if (q != null && q.isNotEmpty) 'q': q,
      if (limit != null) 'limit': '$limit',
      if (offset != null) 'offset': '$offset',
    };
    final path = query.isEmpty ? '/api/reports' : '/api/reports?${Uri(queryParameters: query).query}';

    final res = await _guard(
      _client.get(
        api(path),
        headers: {
          'Accept': 'application/json',
          if (t != null) 'Authorization': 'Bearer $t',
        },
      ),
      'GET /api/reports',
    );
    if (res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('GET /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as List;
  }

  Future<Map<String, dynamic>> createReport({
    required String judul,
    String kategori = 'laimnya',
    required String deskripsi,
    double? lat,
    double? lng,
    String? lokasiText,
    XFile? imageFile,
  }) async {
    final req = http.MultipartRequest('POST', api('/api/reports'))
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] =
          'Bearer ${(await AuthService.instance.getToken()) ?? ''}'
      ..fields.addAll({
        'judul': judul,
        'kategori': kategori,
        'deskripsi': deskripsi,
        if (lat != null) 'lat': '$lat',
        if (lng != null) 'lng': '$lng',
        if (lokasiText != null) 'lokasi_text': lokasiText,
      });

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      final resized = resizeImageBytes(bytes) ?? bytes;
      req.files.add(http.MultipartFile.fromBytes('foto', resized, filename: imageFile.name));
    }

    final sent = await _guard(_client.send(req), 'POST /api/reports');
    final res = await http.Response.fromStream(sent);

    if (res.statusCode != 201 && res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('POST /api/reports gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<Laporan>> fetchReportsAsModel({String? status, String? kategori, String? q, int? limit, int? offset}) async {
    final list = await getReports(status: status, kategori: kategori, q: q, limit: limit, offset: offset);
    return list.map<Laporan>((e) => Laporan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getStats() async {
    final t = await AuthService.instance.getToken();
    final res = await _guard(
      _client.get(
        api('/api/reports/stats'),
        headers: {
          'Accept': 'application/json',
          if (t != null) 'Authorization': 'Bearer $t',
        },
      ),
      'GET /api/reports/stats',
    );
    if (res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('GET stats gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Laporan> getReport(int id) async {
    final t = await AuthService.instance.getToken();
    final res = await _guard(
      _client.get(
        api('/api/reports/$id'),
        headers: {
          'Accept': 'application/json',
          if (t != null) 'Authorization': 'Bearer $t',
        },
      ),
      'GET /api/reports/$id',
    );
    if (res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('GET detail gagal: ${res.statusCode} ${res.body}');
    }
    return Laporan.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> toggleVote(int id) async {
    final t = await AuthService.instance.getToken();
    final res = await _guard(
      _client.post(
        api('/api/reports/$id/vote'),
        headers: {
          'Accept': 'application/json',
          if (t != null) 'Authorization': 'Bearer $t',
        },
      ),
      'POST vote',
    );
    if (res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('Vote gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> confirmReport(int id, String konfirmasi) async {
    final t = await AuthService.instance.getToken();
    final res = await _guard(
      _client.post(
        api('/api/reports/$id/confirm'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (t != null) 'Authorization': 'Bearer $t',
        },
        body: jsonEncode({'konfirmasi': konfirmasi}),
      ),
      'POST confirm',
    );
    if (res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('Konfirmasi gagal: ${res.statusCode} ${res.body}');
    }
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
    if (namaPetugas != null && namaPetugas.isNotEmpty) {
      req.fields['nama_petugas'] = namaPetugas;
    }
    if (keterangan != null && keterangan.isNotEmpty) {
      req.fields['keterangan'] = keterangan;
    }
    
    if (documentationImage != null) {
      final bytes = await documentationImage.readAsBytes();
      final resized = resizeImageBytes(bytes) ?? bytes;
      req.files.add(http.MultipartFile.fromBytes('foto_dokumentasi', resized, filename: documentationImage.name));
    }

    final sent = await _guard(_client.send(req), 'POST update status');
    final res = await http.Response.fromStream(sent);

    if (res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('POST update status gagal: ${res.statusCode} ${res.body}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Unduh CSV ekspor admin: ambil URL bertanda (signed) dulu, lalu unduh
  /// lewat header Authorization — token tidak pernah di query string.
  Future<Uint8List> downloadReportCsv({String? status, String? q}) async {
    final t = await AuthService.instance.getToken();
    final qy = <String, String>{
      if (status != null && status.toLowerCase() != 'semua')
        'status': status.toLowerCase(),
      if (q != null && q.isNotEmpty) 'q': q,
    };
    final urlRes = await _guard(
      _client.get(
        Uri.parse('$baseUrl/api/admin/export/reports/url')
            .replace(queryParameters: qy),
        headers: {
          'Accept': 'application/json',
          if (t != null) 'Authorization': 'Bearer $t',
        },
      ),
      'CSV export URL',
    );
    if (urlRes.statusCode != 200) {
      _checkAuth(urlRes);
      throw Exception('Export gagal: ${urlRes.statusCode} ${urlRes.body}');
    }
    final url = (jsonDecode(urlRes.body) as Map<String, dynamic>)['url'] as String;
    final res = await _guard(
      _client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          if (t != null) 'Authorization': 'Bearer $t',
        },
      ),
      'CSV export',
    );
    if (res.statusCode != 200) {
      _checkAuth(res);
      throw Exception('Export gagal: ${res.statusCode} ${res.body}');
    }
    return res.bodyBytes;
  }
}