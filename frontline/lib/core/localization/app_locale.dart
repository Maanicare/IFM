import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_locale.g.dart';

const supportedLanguages = {'en': 'English', 'hi': 'हिन्दी'};

/// Persists the technician's chosen language (Screen 01: language
/// selector) in the same secure storage used for auth, so it survives
/// restarts without needing its own table/row.
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  static const _storage = FlutterSecureStorage();
  static const _key = 'preferred_language';

  @override
  FutureOr<String> build() async {
    return await _storage.read(key: _key) ?? 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    await _storage.write(key: _key, value: languageCode);
    state = AsyncValue.data(languageCode);
  }
}
