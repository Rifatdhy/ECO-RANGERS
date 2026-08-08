import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _tokenKey = 'token';
  static const _userKey = 'current_user';
  // Di web tidak ada keystore OS; gunakan SharedPreferences (sama saja
  // dengan localStorage). Di platform native baru benar-benar aman.
  static const _storage = FlutterSecureStorage();
  static bool get _useSecureStorage => !kIsWeb;

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
      await _writeToken(data['token'] ?? '');
      final prefs = await SharedPreferences.getInstance();
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
      await _writeToken(data['token'] ?? '');
      final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await _deleteToken();
    _currentUser = null;
  }

  Future<String?> getToken() async {
    if (_useSecureStorage) {
      try {
        return await _storage.read(key: _tokenKey);
      } catch (_) {
        return null; // penyimpanan aman tidak tersedia → perlakukan sebagai belum login
      }
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _writeToken(String value) async {
    if (_useSecureStorage) {
      try {
        await _storage.write(key: _tokenKey, value: value);
      } catch (_) {
        // abaikan: gagal menyimpan di secure storage bukan blunder fatal
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, value);
  }

  Future<void> _deleteToken() async {
    if (_useSecureStorage) {
      try {
        await _storage.delete(key: _tokenKey);
      } catch (_) {
        // abaikan
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }
}

Map<String, dynamic> _decode(String body) {
  try {
    return jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    return {'message': body};
  }
}
