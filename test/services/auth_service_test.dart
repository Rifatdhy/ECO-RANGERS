import 'package:flutter_test/flutter_test.dart';
import 'package:eco_rangers/services/auth_service.dart';
import 'package:eco_rangers/config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    setUp(() async {
      await dotenv.load(fileName: ".env");
      await ensureBaseUrl();
      SharedPreferences.setMockInitialValues({'token': 'test_token'});
      AuthService.instance.httpClient = MockClient((request) async {
        if (request.url.path == '/api/login') {
          return http.Response(jsonEncode({
            'token': 'login_token',
            'user': {'id': 1, 'name': 'Test', 'username': 'test', 'email': 'test@test.com', 'is_admin': false}
          }), 200);
        }
        if (request.url.path == '/api/register') {
          return http.Response(jsonEncode({
            'token': 'reg_token',
            'user': {'id': 2, 'name': 'New', 'username': 'new', 'email': 'new@test.com', 'is_admin': false}
          }), 201);
        }
        return http.Response('Not found', 404);
      });
    });

    tearDown(() {
      AuthService.instance.httpClient = null;
    });

    test('login returns user on valid credentials', () async {
      final user = await AuthService.instance.login(
        email: 'test@test.com',
        password: 'password123',
      );
      expect(user.id, 1);
      expect(user.email, 'test@test.com');
      expect(user.isAdmin, false);
    });

    test('login throws on invalid credentials', () async {
      AuthService.instance.httpClient = MockClient((_) async {
        return http.Response(jsonEncode({'message': 'Email atau password salah'}), 401);
      });
      expect(
        () => AuthService.instance.login(email: 'x@x.com', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('register returns data on success', () async {
      final result = await AuthService.instance.register(
        username: 'newuser',
        email: 'new@test.com',
        password: 'password123',
      );
      expect(result['token'], 'reg_token');
    });

    test('getToken returns stored token', () async {
      final token = await AuthService.instance.getToken();
      expect(token, 'test_token');
    });

    test('getMe returns null when no token', () async {
      SharedPreferences.setMockInitialValues({});
      final user = await AuthService.instance.getMe();
      expect(user, isNull);
    });
  });
}
