// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Chooses the mock or HTTP implementation at the single point every other
/// provider depends on, per `--dart-define=USE_MOCK`. This is the pattern
/// repeated identically for every other feature's repository provider.

@ProviderFor(locationRepository)
final locationRepositoryProvider = LocationRepositoryProvider._();

/// Chooses the mock or HTTP implementation at the single point every other
/// provider depends on, per `--dart-define=USE_MOCK`. This is the pattern
/// repeated identically for every other feature's repository provider.

final class LocationRepositoryProvider
    extends
        $FunctionalProvider<
          LocationRepository,
          LocationRepository,
          LocationRepository
        >
    with $Provider<LocationRepository> {
  /// Chooses the mock or HTTP implementation at the single point every other
  /// provider depends on, per `--dart-define=USE_MOCK`. This is the pattern
  /// repeated identically for every other feature's repository provider.
  LocationRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'locationRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$locationRepositoryHash();

  @$internal
  @override
  $ProviderElement<LocationRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LocationRepository create(Ref ref) {
    return locationRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LocationRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LocationRepository>(value),
    );
  }
}

String _$locationRepositoryHash() =>
    r'9d4f503a7b518075e4e6bd95dce5802841d5e0c1';
