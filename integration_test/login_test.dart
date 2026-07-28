import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:eco_rangers/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App launches and shows splash then auth page', (WidgetTester tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const ValueKey('login-form')), findsOneWidget);
  });

  testWidgets('Login form shows email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.byKey(const ValueKey('login-email')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
    expect(find.byKey(const ValueKey('login-text')), findsOneWidget);
  });

  testWidgets('Can switch between login and register tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await tester.tap(find.text('Buat akun'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('register-form')), findsOneWidget);
  });
}
