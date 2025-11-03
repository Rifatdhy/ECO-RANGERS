import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import '../models/user.dart'; // Impor model User

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Method ini tidak lagi digunakan, tapi kita biarkan saja
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      api('/api/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    final data = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _storage.write(key: 'token', value: data['token']);
      return data;
    }
    throw Exception(data['message'] ?? 'Register gagal');
  }

  // Mengubah login agar mengembalikan objek User
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      api('/api/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _storage.write(key: 'token', value: data['token']);
      // Parsing data user dari respons
      return User.fromJson(data['user']);
    }
    throw Exception(data['message'] ?? 'Login gagal');
  }

  // loginAdmin tidak diperlukan lagi
  // Future<Map<String, dynamic>> loginAdmin(...) { ... }

  Future<void> logout() async {
    final t = await getToken();
    if (t != null) {
      await http.post(
        api('/api/logout'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
      );
    }
    await _storage.delete(key: 'token');
  }

  Future<String?> getToken() => _storage.read(key: 'token');
}

Map<String, dynamic> _decode(String body) {
  try {
    return jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return {'message': body};
  }
}
