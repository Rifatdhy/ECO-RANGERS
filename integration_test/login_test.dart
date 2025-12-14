import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';
import 'package:integration_test/integration_test.dart';

import 'package:eco_rangers/main.dart' as app;
import 'steps/login_steps.dart';

// Fungsi helper untuk secara manual menemukan file .feature
Future<Iterable<String>> _findFeatureFiles() async {
  // =========================================================================
  // KUNCI SOLUSI FINAL: HARDCODE PROJECT ROOT
  // Lingkungan 'flutter test' di mesin ini tidak dapat menemukan direktori
  // proyek secara dinamis. Sebagai solusi terakhir, kita akan
  // meng-hardcode path absolutnya di sini.
  // =========================================================================
  const projectRoot = r'C:\Users\rifat\eco_rangers';
  final featuresDir = Directory(p.join(projectRoot, 'features'));

  if (!await featuresDir.exists()) {
    throw Exception('Direktori "features" tidak ditemukan di: ${featuresDir.path}');
  }

  return featuresDir
      .listSync(recursive: true)
      .where((entity) => entity is File && p.extension(entity.path) == '.feature')
      .map((entity) => entity.path);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Gherkin Tests', () {
    testWidgets('Running feature file', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      final featureFiles = await _findFeatureFiles();

      if (featureFiles.isEmpty) {
        throw Exception('Tidak ada file .feature yang ditemukan.');
      }

      final config = FlutterTestConfiguration(
        features: featureFiles,
        reporters: [
          ProgressReporter(),
          TestRunSummaryReporter(),
        ],
        stepDefinitions: [
          GivenIAmOnTheLoginPage(),
          WhenIEnterMyUsernameAndPassword(),
          WhenITapTheLoginButton(),
          ThenIShouldSeeThe(),
        ],
      );

      await GherkinRunner().execute(config);
    });
  });
}