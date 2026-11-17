/// Error classification used across the network, repository and sync layers.
///
/// Classifying errors (rather than throwing raw Dio/Drift exceptions) lets
/// the UI show the right empty/error state and lets the sync engine decide
/// whether a failed mutation should be retried, queued, or surfaced to the
/// user as a conflict requiring a decision.
library;

/// Base type for all app-level exceptions. Carries a [message] safe to show
/// to the user and an optional [cause] for diagnostics/logging.
sealed class AppException implements Exception {
  const AppException(this.message, {this.cause, this.stackTrace});

  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType: $message';
}

/// Device has no usable network connection. Used to short-circuit HTTP calls
/// and route mutations straight into the offline outbox instead of failing
/// with a confusing socket error.
final class NetworkOfflineError extends AppException {
  const NetworkOfflineError([super.message = 'No network connection']);
}

/// Server/API responded with an error. Carries the HTTP [statusCode] and any
/// structured error [code] the backend returned, so the UI can distinguish
/// e.g. validation errors (422) from auth errors (401) from server errors.
final class ApiError extends AppException {
  const ApiError({
    required String message,
    required this.statusCode,
    this.code,
    super.cause,
    super.stackTrace,
  }) : super(message);

  final int? statusCode;
  final String? code;

  bool get isAuthError => statusCode == 401 || statusCode == 403;
  bool get isValidationError => statusCode == 422 || statusCode == 400;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}

/// Raised when a queued offline mutation is pushed to the server but the
/// server's version of the record has moved on since the mutation was
/// created locally (e.g. a supervisor already changed the work order
/// status). Per the offline spec, conflicts must be surfaced for a decision
/// rather than silently overwritten in either direction.
final class SyncConflictError extends AppException {
  const SyncConflictError({
    required String message,
    required this.entityType,
    required this.entityId,
    required this.localPayload,
    required this.remotePayload,
  }) : super(message);

  final String entityType;
  final String entityId;
  final Map<String, dynamic> localPayload;
  final Map<String, dynamic> remotePayload;
}

/// A value failed local validation before being persisted or queued.
final class ValidationError extends AppException {
  const ValidationError(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;
}

/// The current user's role/scope does not permit the attempted action.
/// Raised by [PolicyGuard] consumers as a defensive backstop even though the
/// UI should already have hidden the corresponding trigger.
final class PolicyDeniedError extends AppException {
  const PolicyDeniedError(super.message);
}

/// Unclassified / unexpected error. Used as the catch-all inside global
/// error handlers so nothing crashes the app silently.
final class UnknownAppError extends AppException {
  const UnknownAppError(super.message, {super.cause, super.stackTrace});
}
