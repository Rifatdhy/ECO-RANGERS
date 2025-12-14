import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';

class GivenIAmOnTheLoginPage extends Given {
  @override
  Future<void> executeStep() async {
    // Implementasi untuk membuka halaman login
    // Contoh: await driver.tap(find.byValueKey('login-button'));
  }

  @override
  RegExp get pattern => RegExp(r'I am on the login page');
}

class WhenIEnterMyUsernameAndPassword extends When2<String, String> {
  @override
  Future<void> executeStep(String username, String password) async {
    // Implementasi untuk memasukkan username dan password
    // Contoh: 
    // await driver.tap(find.byValueKey('username-field'));
    // await driver.enterText(username);
    // await driver.tap(find.byValueKey('password-field'));
    // await driver.enterText(password);
  }

  @override
  RegExp get pattern => RegExp(r'I enter my {string} and {string}');
}

class WhenITapTheLoginButton extends When {
  @override
  Future<void> executeStep() async {
    // Implementasi untuk menekan tombol login
    // Contoh: await driver.tap(find.byValueKey('login-button'));
  }

  @override
  RegExp get pattern => RegExp(r'I tap the login button');
}

class ThenIShouldSeeTheHomePage extends Then {
  @override
  Future<void> executeStep() async {
    // Implementasi untuk verifikasi halaman utama terlihat
    // Contoh: expect(await driver.getText(find.byValueKey('home-page-title')), 'Home Page');
  }

  @override
  RegExp get pattern => RegExp(r'I should see the home page');
}
