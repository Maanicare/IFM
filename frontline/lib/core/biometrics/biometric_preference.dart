import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_preference.g.dart';

/// Whether biometric login is enabled, and which identifier to log in
/// as when it succeeds (Screen 01: "Biometric login after first
/// authentication"). The password itself is never stored - in mock mode
/// any password is accepted, so an empty one is used; a real backend
/// would exchange a stored long-lived device/refresh token here instead
/// (not implemented - this app has no refresh-token endpoint to call).
@Riverpod(keepAlive: true)
class BiometricPreference extends _$BiometricPreference {
  static const _storage = FlutterSecureStorage();
  static const _enabledKey = 'biometric_login_enabled';
  static const _identifierKey = 'biometric_login_identifier';

  @override
  FutureOr<({bool enabled, String? identifier})> build() async {
    final enabled = await _storage.read(key: _enabledKey) == 'true';
    final identifier = await _storage.read(key: _identifierKey);
    return (enabled: enabled, identifier: identifier);
  }

  Future<void> enable(String identifier) async {
    await _storage.write(key: _enabledKey, value: 'true');
    await _storage.write(key: _identifierKey, value: identifier);
    state = AsyncValue.data((enabled: true, identifier: identifier));
  }

  Future<void> disable() async {
    await _storage.write(key: _enabledKey, value: 'false');
    state = AsyncValue.data((enabled: false, identifier: state.value?.identifier));
  }
}
