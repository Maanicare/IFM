import '../domain/authenticated_user.dart';

/// Abstraction over however the device authenticates and resolves the
/// current identity. Two concrete implementations exist -
/// [MockIdentityRepository] (offline fixtures, default) and
/// [HttpIdentityRepository] (Dio-backed) - selected at DI-wiring time by
/// `AppConfig.useMock`, so feature code never knows which one is active.
abstract interface class IdentityRepository {
  /// Authenticates with credentials and returns the resolved identity.
  /// Throws [ApiError] on invalid credentials, [NetworkOfflineError] if
  /// offline and no cached session exists.
  Future<AuthenticatedUser> login({
    required String identifier, // email, mobile or employee ID
    required String password,
  });

  /// Returns the previously authenticated user from local persistence, or
  /// null if no session exists. Used on app start to skip the login screen.
  Future<AuthenticatedUser?> restoreSession();

  Future<void> logout();
}
