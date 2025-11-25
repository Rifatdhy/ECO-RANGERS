import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _currentUser;
  User? get currentUser => _currentUser;

  // FIX: Mengembalikan implementasi fungsi register
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
      _currentUser = User.fromJson(data['user']);
      return data;
    }
    throw Exception(data['message'] ?? 'Register gagal');
  }

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
      _currentUser = User.fromJson(data['user']);
      return _currentUser!;
    }
    throw Exception(data['message'] ?? 'Login gagal');
  }

  Future<User?> getMe() async {
    final t = await getToken();
    if (t == null) return null;

    if (_currentUser != null) return _currentUser;

    try {
      final res = await http.get(
        api('/api/me'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
      );
      if (res.statusCode == 200) {
        _currentUser = User.fromJson(_decode(res.body));
        return _currentUser;
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<void> logout() async {
    final t = await getToken();
    if (t != null) {
      try {
        await http.post(
          api('/api/logout'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
        );
      } catch (e) {
        // Abaikan error
      }
    }
    await _storage.delete(key: 'token');
    _currentUser = null;
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
