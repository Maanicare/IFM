// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dio_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tokenStorage)
final tokenStorageProvider = TokenStorageProvider._();

final class TokenStorageProvider
    extends $FunctionalProvider<TokenStorage, TokenStorage, TokenStorage>
    with $Provider<TokenStorage> {
  TokenStorageProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tokenStorageProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tokenStorageHash();

  @$internal
  @override
  $ProviderElement<TokenStorage> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TokenStorage create(Ref ref) {
    return tokenStorage(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TokenStorage value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TokenStorage>(value),
    );
  }
}

String _$tokenStorageHash() => r'4b5616ca72c6a8ac2c6f4826a9a412192f500d8d';

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

@ProviderFor(dioClient)
final dioClientProvider = DioClientProvider._();

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

final class DioClientProvider extends $FunctionalProvider<Dio, Dio, Dio>
    with $Provider<Dio> {
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
  DioClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dioClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dioClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return dioClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Dio>(value),
    );
  }
}

String _$dioClientHash() => r'6dae17153a1c1900d0008ff6a4dc9c525e8a4fe7';
