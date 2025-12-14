import 'dart:async';
import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:gherkin/gherkin.dart';
import 'package:glob/glob.dart';
import 'package:integration_test/integration_test.dart';

import 'steps/login_steps.dart';

Future<void> main() {
  final config = FlutterIntegrationTestConfiguration()
    ..features = [Glob(r"features/**.feature")]
    ..reporters = [
      ProgressReporter(),
      TestRunSummaryReporter(),
    ]
    ..stepDefinitions = [
      GivenIAmOnTheLoginPage(),
      WhenIEnterMyUsernameAndPassword(),
      WhenITapTheLoginButton(),
      ThenIShouldSeeTheHomePage(),
    ]
    ..restartAppBetweenScenarios = true;

  return GherkinRunner().execute(config);
}
