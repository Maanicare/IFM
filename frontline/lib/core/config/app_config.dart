/// Build-time configuration resolved from `--dart-define` flags.
///
/// Run with mock data (default, no backend required):
///   flutter run --dart-define=USE_MOCK=true
/// Run against a live API:
///   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=https://api.example.com
class AppConfig {
  AppConfig._();

  /// When true, all repositories are backed by local JSON fixtures instead
  /// of the Dio-backed HTTP client. This lets the whole P0 experience (UI,
  /// offline sync, RBAC, checklist flows) be exercised without any backend.
  static const bool useMock = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: true,
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.onemaanicare.example.com',
  );

  /// Logical environment name, surfaced in diagnostics exports.
  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static const Duration apiTimeout = Duration(seconds: 20);
  static const int maxRetryAttempts = 3;
}
