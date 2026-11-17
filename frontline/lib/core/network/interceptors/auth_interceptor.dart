import 'package:dio/dio.dart';

import '../token_storage.dart';

/// Attaches the current bearer access token to every outgoing request, and
/// transparently refreshes it on a 401 before retrying the original request
/// exactly once. If the refresh itself fails, the 401 is passed through so
/// the error interceptor / repository layer can force a re-login.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage, this._dio);

  final TokenStorage _tokenStorage;
  final Dio _dio;

  bool _isRefreshing = false;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried_auth'] == true;

    if (!isUnauthorized || alreadyRetried || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      if (refreshToken == null) {
        handler.next(err);
        return;
      }

      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      final newAccessToken = refreshResponse.data?['access_token'] as String?;
      final newRefreshToken =
          refreshResponse.data?['refresh_token'] as String?;
      if (newAccessToken == null) {
        handler.next(err);
        return;
      }

      await _tokenStorage.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken ?? refreshToken,
      );

      final retriedOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccessToken'
        ..extra['retried_auth'] = true;
      final retryResponse = await _dio.fetch(retriedOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
