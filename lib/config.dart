// lib/config.dart
import 'dart:io';
import 'package:flutter/foundation.dart';

// Kalau pakai HP fisik, ISI IP KOMPUTER kamu di sini, contoh: 'http://192.168.0.111:8000'
// Kalau pakai emulator Android Studio, ubah ke null (biar pakai 10.0.2.2)
const String? FORCE_BASE = 'http://192.168.0.111:8000';

late String baseUrl;

Future<void> ensureBaseUrl() async {
  if (FORCE_BASE != null) {
    baseUrl = FORCE_BASE!;
    return;
  }
  if (kIsWeb) {
    baseUrl = 'http://127.0.0.1:8000';
    return;
  }
  if (Platform.isAndroid) {
    // emulator Android
    baseUrl = 'http://10.0.2.2:8000';
  } else {
    // iOS sim / desktop
    baseUrl = 'http://127.0.0.1:8000';
  }
}

Uri api(String path, [Map<String, dynamic>? query]) {
  final uri = Uri.parse(baseUrl + path);
  return (query == null || query.isEmpty)
      ? uri
      : uri.replace(queryParameters: {
    ...uri.queryParameters,
    ...query.map((k, v) => MapEntry(k, '$v')),
  });
}

// Bangun URL gambar yang aman dipakai di HP (ganti host 127.0.0.1/localhost → baseUrl)
String? imageUrlFrom(Map<String, dynamic> r) {
  final raw = (r['foto_url'] as String?)?.trim();
  final path = (r['foto_path'] as String?)?.trim();

  if (raw != null && raw.isNotEmpty) {
    try {
      final u = Uri.parse(raw);
      // jika API mengembalikan 127.0.0.1 / localhost, ganti host-nya dengan host dari baseUrl
      if (u.host == '127.0.0.1' || u.host == 'localhost') {
        return '$baseUrl${u.path}';
      }
      return raw; // sudah benar
    } catch (_) {
      /* ignore parse error */
    }
  }

  // fallback ke path storage
  if (path != null && path.isNotEmpty) {
    return '$baseUrl/storage/$path';
  }
  return null;
}
