import 'package:flutter/material.dart';

import 'pages/auth_page.dart';
import 'services/auth_service.dart';

/// Navigator key global supaya halaman non-widget (service) bisa trigger
/// navigasi ke halaman login saat sesi tak lagi valid (token 401/expired).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Panggil saat API mengembalikan 401. Hapus token lokal lalu bawa user ke
/// halaman login, hapus semua route di belakangnya.
/// ponytail: satu call-site dari ApiClient; login page push sudah didefine ulang.
Future<void> handleSessionExpired() async {
  await AuthService.instance.logout();
  final nav = rootNavigatorKey.currentState;
  if (nav == null) return;
  nav.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const AuthPage()),
    (route) => false,
  );
}