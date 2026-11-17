import 'package:dio/dio.dart';

import '../../error/exceptions.dart';
import '../connectivity_service.dart';

/// Converts raw [DioException]s into the app's own [AppException]
/// hierarchy so every calling layer (repositories, sync engine, UI) can
/// `switch` on a small closed set of error types instead of inspecting
/// Dio-specific fields everywhere.
///
/// This is the last interceptor in the chain (after auth + retry), so by
/// the time it runs, retries are exhausted and auth refresh has already
/// been attempted.
class ErrorClassifyingInterceptor extends Interceptor {
  ErrorClassifyingInterceptor(this._connectivity);

  final ConnectivityService _connectivity;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final appException = await _classify(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        error: appException,
        response: err.response,
        type: err.type,
        stackTrace: err.stackTrace,
      ),
    );
  }

  Future<AppException> _classify(DioException err) async {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout) {
      final online = await _connectivity.isOnline();
      if (!online) return const NetworkOfflineError();
    }

    final response = err.response;
    if (response != null) {
      final data = response.data;
      final code = data is Map ? data['error_code'] as String? : null;
      final message = data is Map
          ? (data['message'] as String? ?? 'Request failed')
          : (response.statusMessage ?? 'Request failed');
      return ApiError(
        message: message,
        statusCode: response.statusCode,
        code: code,
        cause: err,
        stackTrace: err.stackTrace,
      );
    }

    return UnknownAppError(
      err.message ?? 'Unexpected network error',
      cause: err,
      stackTrace: err.stackTrace,
    );
  }
}
