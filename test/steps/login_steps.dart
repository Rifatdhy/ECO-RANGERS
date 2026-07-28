import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';
import 'package:flutter/material.dart';
import 'package:eco_rangers/pages/dashboard_user_page.dart' as dashboard;
import 'package:eco_rangers/main.dart' as app;

class GivenIAmOnTheLoginPage extends GivenWithWorld<FlutterWidgetTesterWorld> {
  @override
  Future<void> executeStep() async {
    final tester = world.rawAppDriver;
    await tester.pumpWidget(const app.EcoRangersApp());
  }

  @override
  RegExp get pattern => RegExp(r'I am on the login page');
}

class WhenIEnterMyUsernameAndPassword extends When2WithWorld<String, String, FlutterWidgetTesterWorld> {
  @override
  Future<void> executeStep(String username, String password) async {
    final tester = world.rawAppDriver;
    await tester.enterText(
      find.byKey(const ValueKey('login-email')),
      username,
    );
    await tester.enterText(
      find.byKey(const ValueKey('login-password')),
      password,
    );
  }

  @override
  RegExp get pattern => RegExp(r'I enter my {string} and {string}');
}

class WhenITapTheLoginButton extends WhenWithWorld<FlutterWidgetTesterWorld> {
  @override
  Future<void> executeStep() async {
    final tester = world.rawAppDriver;
    await tester.tap(find.byKey(const ValueKey('login-text')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  @override
  RegExp get pattern => RegExp(r'I tap the login button');
}

class ThenIShouldSeeThe extends Then1WithWorld<String, FlutterWidgetTesterWorld> {
  @override
  Future<void> executeStep(String outcome) async {
    if (outcome == 'home page') {
      expect(find.byType(dashboard.DashboardUserPage), findsOneWidget);
    } else if (outcome == 'error message') {
      expect(find.text('Login gagal'), findsOneWidget);
    }
  }

  @override
  RegExp get pattern => RegExp(r'I should see the {string}');
}
