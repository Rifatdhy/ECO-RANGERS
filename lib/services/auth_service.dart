import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'token';
  static const _userKey = 'current_user';

  User? _currentUser;
  User? get currentUser => _currentUser;

  http.Client? _httpClient;
  set httpClient(http.Client? client) => _httpClient = client;
  http.Client get _client => _httpClient ?? http.Client();

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] ?? '');
      await prefs.setString(_userKey, jsonEncode(data['user']));
      _currentUser = User.fromJson(data['user']);
      return data;
    }
    throw Exception(data['message'] ?? 'Register gagal');
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      api('/api/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, data['token'] ?? '');
      await prefs.setString(_userKey, jsonEncode(data['user']));
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
      final res = await _client.get(
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
        await _client.post(
          api('/api/logout'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
        );
      } catch (e) {
        // Abaikan error
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _currentUser = null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
}

Map<String, dynamic> _decode(String body) {
  try {
    return jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return {'message': body};
  }
}
