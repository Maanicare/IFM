// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'washroom_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(washroomRepository)
final washroomRepositoryProvider = WashroomRepositoryProvider._();

final class WashroomRepositoryProvider
    extends
        $FunctionalProvider<
          WashroomRepository,
          WashroomRepository,
          WashroomRepository
        >
    with $Provider<WashroomRepository> {
  WashroomRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'washroomRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$washroomRepositoryHash();

  @$internal
  @override
  $ProviderElement<WashroomRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WashroomRepository create(Ref ref) {
    return washroomRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WashroomRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WashroomRepository>(value),
    );
  }
}

String _$washroomRepositoryHash() =>
    r'b4ed0cdc133dfb60e104a9915950cd1969f97a7d';
