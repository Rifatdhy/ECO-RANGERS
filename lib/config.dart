import 'package:flutter_dotenv/flutter_dotenv.dart'; // Impor dotenv

// Baris ini bisa Anda aktifkan jika butuh pengujian cepat,
// namun lebih baik gunakan file .env
// const String? FORCE_BASE = 'http://192.168.0.116:8000';

late String baseUrl;

// ensureBaseUrl sekarang hanya membaca dari dotenv
Future<void> ensureBaseUrl() async {
  // Ambil nilai dari .env, lalu fallback aman untuk desktop jika kosong
  final envBaseUrl = dotenv.env['API_BASE_URL']?.trim();

  if (envBaseUrl != null && envBaseUrl.isNotEmpty) {
    baseUrl = envBaseUrl;
    return;
  }

  baseUrl = Uri.base.host.isNotEmpty ? 'http://${Uri.base.host}:8000' : 'http://localhost:8000';
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

// Bangun URL gambar yang aman untuk semua platform (Web & Mobile)
String? imageUrlFrom(Map<String, dynamic> r) {
  final raw = (r['foto_url'] as String?)?.trim();
  final path = (r['foto_path'] as String?)?.trim();
  String? finalPath;

  // Prioritas 1: Gunakan `foto_path` jika tersedia, karena ini adalah path relatif yang bersih.
  if (path != null && path.isNotEmpty) {
    finalPath = path;
  }
  // Prioritas 2: Jika tidak ada, coba ekstrak path dari `foto_url`.
  else if (raw != null && raw.isNotEmpty) {
    try {
      final u = Uri.parse(raw);
      // Cek apakah URL ini menunjuk ke path storage lama.
      if (u.path.startsWith('/storage/')) {
        // Ekstrak path relatifnya. Contoh: '/storage/reports/img.jpg' -> 'reports/img.jpg'
        finalPath = u.path.substring('/storage/'.length);
      }
    } catch (_) {
      // Abaikan jika URL tidak valid. `finalPath` akan tetap null.
    }
  }

  // Jika kita berhasil mendapatkan path relatif (dari salah satu sumber di atas),
  // bangun URL menggunakan rute proxy API yang baru.
  if (finalPath != null && finalPath.isNotEmpty) {
    return '$baseUrl/api/files/$finalPath';
  }

  // Fallback terakhir: Jika `foto_url` adalah URL absolut yang valid
  // dan bukan URL storage (misalnya dari CDN atau domain publik lain), kembalikan apa adanya.
  if (raw != null && Uri.tryParse(raw)?.hasAbsolutePath == true && !raw.contains('/storage/')) {
      return raw;
  }

  // Jika tidak ada sumber yang valid, kembalikan null.
  return null;
}
