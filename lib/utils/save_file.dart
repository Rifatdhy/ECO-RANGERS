import 'dart:typed_data';

import 'save_file_stub.dart'
    if (dart.library.html) 'save_file_web.dart' as impl;

Future<void> saveCsvFile(Uint8List bytes, String filename) =>
    impl.saveCsvFile(bytes, filename);