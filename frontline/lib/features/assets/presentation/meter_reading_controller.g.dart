// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meter_reading_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Captures a meter reading in the field (Section 33) - e.g. runtime
/// hours during a PM visit - writing it locally and queueing the push.

@ProviderFor(MeterReadingController)
final meterReadingControllerProvider = MeterReadingControllerProvider._();

/// Captures a meter reading in the field (Section 33) - e.g. runtime
/// hours during a PM visit - writing it locally and queueing the push.
final class MeterReadingControllerProvider
    extends $NotifierProvider<MeterReadingController, void> {
  /// Captures a meter reading in the field (Section 33) - e.g. runtime
  /// hours during a PM visit - writing it locally and queueing the push.
  MeterReadingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'meterReadingControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$meterReadingControllerHash();

  @$internal
  @override
  MeterReadingController create() => MeterReadingController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$meterReadingControllerHash() =>
    r'bf3c19ae0246dd505f6e9bdfd5e0a64011222f44';

/// Captures a meter reading in the field (Section 33) - e.g. runtime
/// hours during a PM visit - writing it locally and queueing the push.

abstract class _$MeterReadingController extends $Notifier<void> {
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
