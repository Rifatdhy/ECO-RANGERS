import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:eco_rangers/config.dart';
import 'package:eco_rangers/models/laporan.dart';
import 'package:eco_rangers/models/report_update.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await ensureBaseUrl();

  group('Laporan.fromJson', () {
    test('parses complete report JSON', () {
      final json = {
        'id': 1,
        'judul': 'Sampah di Sungai',
        'deskripsi': 'Banyak sampah plastik',
        'lokasi_text': 'Jakarta Selatan',
        'lat': -6.2,
        'lng': 106.8,
        'foto_path': 'reports/photo.jpg',
        'status': 'pending',
        'created_at': '2024-07-25T10:00:00',
        'updates': [],
        'user': {
          'id': 1,
          'name': 'User',
          'username': 'user1',
          'email': 'user@example.com',
          'is_admin': false,
        },
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.id, 1);
      expect(laporan.judul, 'Sampah di Sungai');
      expect(laporan.deskripsi, 'Banyak sampah plastik');
      expect(laporan.lokasiText, 'Jakarta Selatan');
      expect(laporan.latitude, -6.2);
      expect(laporan.longitude, 106.8);
      expect(laporan.fotoPath, 'reports/photo.jpg');
      expect(laporan.status, 'pending');
      expect(laporan.user, isNotNull);
      expect(laporan.user!.id, 1);
    });

    test('handles missing optional fields', () {
      final json = {
        'id': 2,
        'judul': 'Test',
        'deskripsi': 'Desc',
        'status': 'diproses',
        'created_at': '2024-07-25T10:00:00',
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.id, 2);
      expect(laporan.latitude, isNull);
      expect(laporan.longitude, isNull);
      expect(laporan.lokasiText, 'Lokasi tidak tersedia');
      expect(laporan.fotoPath, isNull);
      expect(laporan.user, isNull);
      expect(laporan.updates, isEmpty);
    });

    test('uses defaults for missing judul/deskripsi', () {
      final json = {
        'id': 3,
        'status': 'selesai',
        'created_at': '2024-07-25T10:00:00',
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.judul, 'Tanpa Judul');
      expect(laporan.deskripsi, 'Tanpa Deskripsi');
    });

    test('parses lokasi from lat/lng when lokasi_text missing', () {
      final json = {
        'id': 4,
        'judul': 'Test',
        'deskripsi': 'Desc',
        'lat': -7.5,
        'lng': 110.3,
        'status': 'pending',
        'created_at': '2024-07-25T10:00:00',
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.lokasiText, '-7.5, 110.3');
    });

    test('parses updates list', () {
      final json = {
        'id': 5,
        'judul': 'Test',
        'deskripsi': 'Desc',
        'status': 'diproses',
        'created_at': '2024-07-25T10:00:00',
        'updates': [
          {
            'id': 1,
            'report_id': 5,
            'status': 'diproses',
            'keterangan': 'Sedang ditangani',
            'nama_petugas': 'Petugas A',
            'created_at': '2024-07-26T10:00:00',
          }
        ],
      };
      final laporan = Laporan.fromJson(json);
      expect(laporan.updates.length, 1);
      expect(laporan.updates[0].keterangan, 'Sedang ditangani');
    });
  });
}