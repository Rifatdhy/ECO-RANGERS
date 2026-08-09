import 'dart:typed_data';

/// Tidak ada jalur simpan file native; web adalah target utama.
Future<void> saveCsvFile(Uint8List bytes, String filename) =>
    throw UnsupportedError('Unduhan CSV hanya didukung di web');