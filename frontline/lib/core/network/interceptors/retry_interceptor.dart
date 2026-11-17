import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';

import '../../config/app_config.dart';
import '../../logging/app_logger.dart';
import '../connectivity_service.dart';

/// Retries idempotent/transient failures with exponential backoff + jitter.
///
/// Only retries:
///   - connection/timeout errors (likely transient network blips), and
///   - 502/503/504 server responses.
/// Never retries 4xx (client/validation errors) since retrying a bad
/// request just repeats the same failure.
class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._connectivity, this._dio);

  final ConnectivityService _connectivity;
  final Dio _dio;
  static const _tag = 'RetryInterceptor';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final attempt = (err.requestOptions.extra['retry_attempt'] as int?) ?? 0;

    if (!_isRetryable(err) || attempt >= AppConfig.maxRetryAttempts) {
      handler.next(err);
      return;
    }

    final online = await _connectivity.isOnline();
    if (!online) {
      // No point retrying immediately if the device itself is offline;
      // let the error surface so the caller can route into the outbox.
      handler.next(err);
      return;
    }

    final backoff = _backoffDelay(attempt);
    AppLogger.instance.warning(
      _tag,
      'Retrying ${err.requestOptions.path} (attempt ${attempt + 1}) after ${backoff.inMilliseconds}ms',
    );
    await Future<void>.delayed(backoff);

    try {
      final options = err.requestOptions
        ..extra['retry_attempt'] = attempt + 1;
      final response = await _dio.fetch(options);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }

  bool _isRetryable(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final code = err.response?.statusCode;
        return code == 502 || code == 503 || code == 504;
      default:
        return false;
    }
  }

  Duration _backoffDelay(int attempt) {
    final baseMs = 400 * pow(2, attempt).toInt();
    final jitterMs = Random().nextInt(200);
    return Duration(milliseconds: baseMs + jitterMs);
  }
}
