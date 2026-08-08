import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Terapkan maksimum dimensi gambar + kompresi JPEG sebelum upload,
/// supaya request tetap kecil & sesuai limit server (4MB).
///
/// ponytail: resize sederhana (aspek dipertahankan). Kalau butuh thumbnail
/// multi-ukuran atau format pilihan per platform, tambahkan di sini.
Uint8List? resizeImageBytes(Uint8List bytes, {int maxDimension = 1600, int quality = 85}) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final width = decoded.width;
    final height = decoded.height;
    final longest = width > height ? width : height;
    if (longest <= maxDimension) {
      return img.encodeJpg(decoded, quality: quality);
    }

    final scale = maxDimension / longest;
    final resized = img.copyResize(
      decoded,
      width: (width * scale).round(),
      height: (height * scale).round(),
      interpolation: img.Interpolation.linear,
    );
    return img.encodeJpg(resized, quality: quality);
  } catch (_) {
    return null;
  }
}