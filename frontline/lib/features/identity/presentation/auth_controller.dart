import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/logging/app_logger.dart';
import '../data/identity_repository_provider.dart';
import '../domain/authenticated_user.dart';

part 'auth_controller.g.dart';

/// Session state for the whole app. `AsyncValue<AuthenticatedUser?>`:
///   - loading: still checking for a restored session on app start.
///   - data(null): no session - show the login screen.
///   - data(user): authenticated - show the main app shell.
///   - error: restore or login failed.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  static const _tag = 'AuthController';

  @override
  FutureOr<AuthenticatedUser?> build() {
    return ref.watch(identityRepositoryProvider).restoreSession();
  }

  Future<void> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await ref
          .read(identityRepositoryProvider)
          .login(identifier: identifier, password: password);
      AppLogger.instance.info(_tag, 'Login succeeded', context: {
        'userId': user.id,
        'role': user.role.name,
      });
      state = AsyncValue.data(user);
    } catch (error, stackTrace) {
      AppLogger.instance.warning(_tag, 'Login failed: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> logout() async {
    await ref.read(identityRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}
