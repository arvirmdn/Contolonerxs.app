import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api.dart';

export 'auth_api.dart' show AuthApiException;

// ---------------------------------------------------------------------------
// AuthService — akun (Nama + Sandi) sekarang disimpan di BACKEND
// (lihat auth_api.dart), jadi tidak hilang lagi walau app di-uninstall
// atau ganti HP. Token sesi login di-cache lokal (SharedPreferences)
// cuma supaya tau siapa yang lagi login & buat proses "Keluar".
// ---------------------------------------------------------------------------
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const String _tokenKey = 'contolonerxs_session_token';
  static const String _usernameKey = 'contolonerxs_session_username';

  /// Daftar akun baru lewat backend. Melempar [AuthApiException] kalau
  /// nama sudah dipakai, input tidak valid, atau gagal konek ke server.
  Future<void> register({
    required String username,
    required String password,
  }) async {
    final result = await AuthApi.register(username: username, password: password);
    await _saveSession(result.username, result.token);
  }

  /// Cek kombinasi nama + sandi ke backend. Return true kalau cocok.
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    final result = await AuthApi.login(username: username, password: password);
    await _saveSession(result.username, result.token);
    return true;
  }

  Future<void> _saveSession(String username, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
  }

  /// Nama pengguna dari sesi yang di-cache lokal (tanpa panggil server).
  Future<String?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  /// Cek ke server apakah sesi yang di-cache lokal masih valid. Berguna
  /// misalnya kalau nanti mau bikin app langsung masuk tanpa login ulang.
  Future<String?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;

    final username = await AuthApi.me(token);
    if (username == null) {
      await _clearSession();
      return null;
    }
    return username;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token != null) {
      try {
        await AuthApi.logout(token);
      } catch (_) {
        // Tetap hapus sesi lokal walau gagal kontak server.
      }
    }
    await _clearSession();
  }

  /// Ubah sandi akun yang lagi login. Melempar [AuthApiException] kalau
  /// sandi lama salah, sandi baru terlalu pendek, atau sesi tidak valid.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      throw AuthApiException('Sesi tidak valid, silakan masuk lagi');
    }
    await AuthApi.changePassword(
      token: token,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  /// Ganti nama akun yang lagi login. Cache nama lokal ikut diperbarui.
  Future<String> updateUsername(String newUsername) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) {
      throw AuthApiException('Sesi tidak valid, silakan masuk lagi');
    }
    final updated = await AuthApi.updateUsername(token: token, newUsername: newUsername);
    await prefs.setString(_usernameKey, updated);
    return updated;
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
  }
}
