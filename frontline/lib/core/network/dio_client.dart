import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/app_config.dart';
import 'connectivity_service.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_classifying_interceptor.dart';
import 'interceptors/retry_interceptor.dart';
import 'token_storage.dart';

part 'dio_client.g.dart';

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return TokenStorage(const FlutterSecureStorage());
}

/// Builds the single shared [Dio] instance used by every HTTP repository.
///
/// Interceptor order matters:
///   1. Auth - attaches/refreshes the bearer token.
///   2. Retry - retries transient failures with backoff.
///   3. ErrorClassifying - converts whatever is left into an [AppException].
/// Interceptors run in registration order on the request path and in
/// reverse order on the response/error path, so placing ErrorClassifying
/// last means it sees the error only after auth-refresh and retries have
/// already had their chance to resolve it.
@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: AppConfig.apiTimeout,
      receiveTimeout: AppConfig.apiTimeout,
      sendTimeout: AppConfig.apiTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  final tokenStorage = ref.watch(tokenStorageProvider);
  final connectivity = ref.watch(connectivityServiceProvider);

  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage, dio),
    RetryInterceptor(connectivity, dio),
    ErrorClassifyingInterceptor(connectivity),
  ]);

  return dio;
}
