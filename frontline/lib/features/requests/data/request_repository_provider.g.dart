// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(requestRepository)
final requestRepositoryProvider = RequestRepositoryProvider._();

final class RequestRepositoryProvider
    extends
        $FunctionalProvider<
          RequestRepository,
          RequestRepository,
          RequestRepository
        >
    with $Provider<RequestRepository> {
  RequestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestRepositoryHash();

  @$internal
  @override
  $ProviderElement<RequestRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RequestRepository create(Ref ref) {
    return requestRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RequestRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RequestRepository>(value),
    );
  }
}

String _$requestRepositoryHash() => r'6541f8a68d8005032bce2e888618c11cec460352';
