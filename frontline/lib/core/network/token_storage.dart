import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth/refresh tokens in the platform secure keystore
/// (Keychain on iOS, Keystore-backed EncryptedSharedPreferences on Android)
/// so credentials never sit in plain SharedPreferences or the Drift DB.
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'auth_access_token';
  static const _refreshTokenKey = 'auth_refresh_token';

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);
  Future<String?> readRefreshToken() => _storage.read(key: _refreshTokenKey);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }
}
