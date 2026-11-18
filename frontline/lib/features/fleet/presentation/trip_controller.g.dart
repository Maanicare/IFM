// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 48's driver-facing subset: start a trip (capturing the
/// start odometer), end it later (end odometer, optional fuel used).
/// Same offline-first write-then-outbox pattern as every other mutation
/// in this app.

@ProviderFor(TripController)
final tripControllerProvider = TripControllerProvider._();

/// Backs Screen 48's driver-facing subset: start a trip (capturing the
/// start odometer), end it later (end odometer, optional fuel used).
/// Same offline-first write-then-outbox pattern as every other mutation
/// in this app.
final class TripControllerProvider
    extends $NotifierProvider<TripController, void> {
  /// Backs Screen 48's driver-facing subset: start a trip (capturing the
  /// start odometer), end it later (end odometer, optional fuel used).
  /// Same offline-first write-then-outbox pattern as every other mutation
  /// in this app.
  TripControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripControllerHash();

  @$internal
  @override
  TripController create() => TripController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$tripControllerHash() => r'd4b42d9752a8d22a2bc8e473893a5a2fe0f13251';

/// Backs Screen 48's driver-facing subset: start a trip (capturing the
/// start odometer), end it later (end odometer, optional fuel used).
/// Same offline-first write-then-outbox pattern as every other mutation
/// in this app.

abstract class _$TripController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
