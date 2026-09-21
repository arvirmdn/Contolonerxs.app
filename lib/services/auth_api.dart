import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/musikin_config.dart';

// Exception khusus biar UI bisa nampilin pesan yang jelas ke user
class AuthApiException implements Exception {
  AuthApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  AuthResult({required this.username, required this.token});
  final String username;
  final String token;
}

/// Pemanggil endpoint /api/auth/* di backend Musikin — akun (Nama + Sandi)
/// disimpan di server, jadi tidak hilang walau app di-uninstall / ganti HP.
class AuthApi {
  static final Uri _base = Uri.parse(MusikinConfig.baseUrl);

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on http.ClientException {
      throw AuthApiException('Gagal konek ke server. Cek koneksi internet kamu.');
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Terjadi kesalahan: $e');
    }
  }

  static String _errorMessage(http.Response res, String fallback) {
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    } catch (_) {
      // abaikan, pakai fallback di bawah
    }
    return fallback;
  }

  static Future<AuthResult> register({
    required String username,
    required String password,
  }) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/auth/register');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw AuthApiException(_errorMessage(res, 'Gagal daftar (${res.statusCode}).'));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return AuthResult(username: data['username'] as String, token: data['token'] as String);
    });
  }

  static Future<AuthResult> login({
    required String username,
    required String password,
  }) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/auth/login');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw AuthApiException(_errorMessage(res, 'Gagal masuk (${res.statusCode}).'));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return AuthResult(username: data['username'] as String, token: data['token'] as String);
    });
  }

  /// Validasi token sesi yang tersimpan lokal ke server. Return username
  /// kalau sesi masih valid, atau null kalau sudah tidak berlaku.
  static Future<String?> me(String token) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/auth/me', queryParameters: {'token': token});
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['username'] as String?;
    });
  }

  static Future<void> logout(String token) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/auth/logout');
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token}),
          )
          .timeout(const Duration(seconds: 15));
    });
  }

  static Future<void> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/auth/change-password');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': token,
              'old_password': oldPassword,
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw AuthApiException(_errorMessage(res, 'Gagal ubah sandi (${res.statusCode}).'));
      }
    });
  }

  static Future<String> updateUsername({
    required String token,
    required String newUsername,
  }) {
    return _guard(() async {
      final uri = _base.replace(path: '/api/auth/update-username');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'token': token, 'new_username': newUsername}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode != 200) {
        throw AuthApiException(_errorMessage(res, 'Gagal ubah nama (${res.statusCode}).'));
      }
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['username'] as String;
    });
  }
}
