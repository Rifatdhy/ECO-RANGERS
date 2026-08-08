import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:eco_rangers/main.dart' as app;
import 'package:eco_rangers/pages/auth_page.dart';
import 'package:eco_rangers/pages/splash_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App boot: splash ditampilkan lalu halaman login tampil saat belum login',
      (tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());

    // Splash screen tampil pertama (tanpa menunggu api/me timeout lama).
    expect(find.byType(SplashScreen), findsOneWidget);

    // Lemparkan beberapa frame sampai navigasi splash selesai (token kosong → AuthPage).
    // getMe() mengembalikan null cepat (tanpa token) sehingga AuthPage segera tampil.
    await tester.pumpAndSettle(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 5));

    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('Masuk ke Eco Rangers'), findsOneWidget);
  });
}