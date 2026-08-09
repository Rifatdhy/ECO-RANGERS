import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../locator.dart';
import '../models/laporan.dart';
import 'api_client.dart';
import 'auth_service.dart';

/// Notifikasi in-app: pantau perubahan status laporan milik user.
///
/// Pola: simpan baseline status per laporan ("terakhir dilihat"). Laporan
/// dianggap belum dilihat bila status servernya berubah dari baseline dan
/// bukan 'pending' (ada progres/admin). `fetchUnseen()` hanya membaca;
/// `markAllSeen()` menetapkan baseline baru setelah user melihat notifikasi.
class NotifikasiService {
  NotifikasiService._();
  static final NotifikasiService instance = NotifikasiService._();

  static const _baselineKey = 'notif_baseline_statuses';

  Future<Map<String, String>> _readBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_baselineKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<bool> _baselineExists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_baselineKey);
  }

  Future<void> _writeBaseline(Map<String, String> base) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baselineKey, jsonEncode(base));
  }

  Future<List<Laporan>> _fetchMine() async {
    final api = locator<ApiClient>();
    return api.fetchReportsAsModel(limit: 500);
  }

  /// Baca saja: daftar laporan dengan status berubah dari baseline
  /// (ada progres baru yang belum dilihat).
  Future<List<Laporan>> fetchUnseen() async {
    final user = await AuthService.instance.getMe();
    if (user == null) return [];

    final reports = await _fetchMine();

    // Baseline belum pernah ditulis → inisialisasi diam-diam, tanpa notif.
    if (!await _baselineExists()) {
      await _writeBaseline({
        for (final l in reports) '${l.id}': l.status.toLowerCase(),
      });
      return [];
    }

    final baseline = await _readBaseline();
    return reports.where((l) {
      final cur = l.status.toLowerCase();
      final prev = baseline['${l.id}'];
      return cur != 'pending' && prev != cur;
    }).toList();
  }

  /// Set baseline = status saat ini, sehingga notif tidak berulang.
  Future<void> markAllSeen() async {
    final reports = await _fetchMine().catchError((_) => <Laporan>[]);
    final base = <String, String>{};
    for (final l in reports) {
      base['${l.id}'] = l.status.toLowerCase();
    }
    await _writeBaseline(base);
  }
}