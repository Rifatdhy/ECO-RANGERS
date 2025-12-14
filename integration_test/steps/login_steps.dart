import 'package:flutter_gherkin/flutter_gherkin.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gherkin/gherkin.dart';

class GivenIAmOnTheLoginPage extends Given {
  @override
  Future<void> executeStep() async {
    // Implementasi untuk membuka halaman login
  }

  @override
  RegExp get pattern => RegExp(r'I am on the login page');
}

class WhenIEnterMyUsernameAndPassword extends When2<String, String> {
  @override
  Future<void> executeStep(String username, String password) async {
    // Implementasi untuk memasukkan username dan password
  }

  @override
  RegExp get pattern => RegExp(r'I enter my {string} and {string}');
}

class WhenITapTheLoginButton extends When {
  @override
  Future<void> executeStep() async {
    // Implementasi untuk menekan tombol login
  }

  @override
  RegExp get pattern => RegExp(r'I tap the login button');
}

class ThenIShouldSeeThe extends Then1<String> {
  @override
  Future<void> executeStep(String outcome) async {
    if (outcome == 'home page') {
      // Verifikasi bahwa halaman utama terlihat
    } else if (outcome == 'error message') {
      // Verifikasi bahwa pesan error terlihat
    }
  }

  @override
  RegExp get pattern => RegExp(r'I should see the {string}');
}
