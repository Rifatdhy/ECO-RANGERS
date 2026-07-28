import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:eco_rangers/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('EcoRangers app launches', (WidgetTester tester) async {
    await tester.pumpWidget(const app.EcoRangersApp());
    expect(find.byType(app.EcoRangersApp), findsOneWidget);
  });
}