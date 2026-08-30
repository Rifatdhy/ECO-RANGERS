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

  // Client HTTP di-reuse untuk semua request auth (pooling koneksi).
  final http.Client _client = http.Client();

  static const _tokenKey = 'token';
  static const _userKey = 'current_user';
  static const _tokenExpiryKey = 'token_expiry';
  static const _refreshThreshold = Duration(minutes: 5);
  
  // Di web tidak ada keystore OS; gunakan SharedPreferences (sama saja
  // dengan localStorage). Di platform native baru benar-benar aman.
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainItemAccessibility.first_unlock_this_device,
    ),
  );
  static bool get _useSecureStorage => !kIsWeb;

  User? _currentUser;
  DateTime? _tokenExpiry;
  
  User? get currentUser => _currentUser;

  /// Check if token is expired or about to expire
  bool get isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!.subtract(_refreshThreshold));
  }

  Future<T> _to<T>(Future<T> f) => f.timeout(const Duration(seconds: 15));

  // FIX: Mengembalikan implementasi fungsi register
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (username.trim().length < 3) throw Exception('Username minimal 3 karakter');
    if (!_isValidEmail(email)) throw Exception('Format email tidak valid');
    if (password.length < 8) throw Exception('Password minimal 8 karakter');

    final res = await _to(_client.post(
      api('/api/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': username,
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': password,
      }),
    ));
    final data = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _writeToken(data['token'] ?? '');
      await _writeUser(data['user']);
      await _writeTokenExpiry();
      _currentUser = User.fromJson(data['user']);
      return data;
    }
    throw Exception(data['message'] ?? 'Registrasi gagal');
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    if (!_isValidEmail(email)) throw Exception('Format email tidak valid');
    if (password.isEmpty) throw Exception('Password tidak boleh kosong');

    final res = await _to(_client.post(
      api('/api/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    ));
    final data = _decode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      await _writeToken(data['token'] ?? '');
      await _writeUser(data['user']);
      await _writeTokenExpiry();
      _currentUser = User.fromJson(data['user']);
      return _currentUser!;
    }
    throw Exception(data['message'] ?? 'Login gagal — periksa email dan password');
  }

  /// Ensure token is valid before API call - auto-refresh if needed
  Future<void> ensureTokenValid() async {
    if (isTokenExpired) {
      await _refreshTokenIfNeeded();
    }
  }

  /// Refresh token from server
  Future<void> _refreshTokenIfNeeded() async {
    final t = await getToken();
    if (t == null) return;

    try {
      final res = await _client.post(
        api('/api/token/refresh'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $t',
        },
      ).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = _decode(res.body);
        if (data['token'] != null) {
          await _writeToken(data['token']);
          await _writeTokenExpiry();
        }
      }
    } catch (_) {
      // Refresh failed — logout user gracefully
      await logout();
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  }

  Future<void> _writeTokenExpiry() async {
    // Default 7 hari dari sekarang (sesuai Sanctum default)
    final expiry = DateTime.now().add(const Duration(days: 7));
    _tokenExpiry = expiry;
    if (!_useSecureStorage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_tokenExpiryKey, expiry.millisecondsSinceEpoch);
    } else {
      try {
        await _storage.write(key: _tokenExpiryKey, value: expiry.millisecondsSinceEpoch.toString());
      } catch (_) {}
    }
  }

  Future<DateTime?> _readTokenExpiry() async {
    if (!_useSecureStorage) {
      final prefs = await SharedPreferences.getInstance();
      final ms = prefs.getInt(_tokenExpiryKey);
      return ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    }
    try {
      final val = await _storage.read(key: _tokenExpiryKey);
      return val != null ? DateTime.fromMillisecondsSinceEpoch(int.parse(val)) : null;
    } catch (_) {
      return null;
    }
  }

  Future<User?> getMe() async {
    final t = await getToken();
    if (t == null) return null;

    if (_currentUser != null) return _currentUser;

    try {
      final res = await _to(_client.get(
        api('/api/me'),
        headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
      ));
      if (res.statusCode == 200) {
        _currentUser = User.fromJson(_decode(res.body));
        return _currentUser;
      }
      if (res.statusCode == 401) {
        // Token basi — bersihkan agar tidak berulang hit `/api/me` 401.
        await _deleteToken();
        await _deleteUser();
        _currentUser = null;
        return null;
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
        await _to(_client.post(
          api('/api/logout'),
          headers: {'Accept': 'application/json', 'Authorization': 'Bearer $t'},
        ));
      } catch (e) {
        // Abaikan error
      }
    }
    await _deleteUser();
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
    final prefs = await SharedPreferences.getInstance().catchError((_) => null);
    if (prefs == null) return null;
    return prefs.getString(_tokenKey);
  }

  Future<void> _writeUser(dynamic userJson) async {
    final value = jsonEncode(userJson);
    if (_useSecureStorage) {
      try {
        await _storage.write(key: _userKey, value: value);
      } catch (_) {
        // abaikan
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance().catchError((_) => null);
    if (prefs == null) return;
    await prefs.setString(_userKey, value);
  }

  Future<void> _deleteUser() async {
    if (_useSecureStorage) {
      try {
        await _storage.delete(key: _userKey);
      } catch (_) {
        // abaikan
      }
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
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
