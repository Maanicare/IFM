// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_handover_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 26 (Shift Handover): the outgoing team's briefing, and
/// the incoming team's acknowledgement. Both are offline-first writes -
/// a shift ending with no connectivity must still hand over cleanly.

@ProviderFor(ShiftHandoverController)
final shiftHandoverControllerProvider = ShiftHandoverControllerProvider._();

/// Backs Screen 26 (Shift Handover): the outgoing team's briefing, and
/// the incoming team's acknowledgement. Both are offline-first writes -
/// a shift ending with no connectivity must still hand over cleanly.
final class ShiftHandoverControllerProvider
    extends $NotifierProvider<ShiftHandoverController, void> {
  /// Backs Screen 26 (Shift Handover): the outgoing team's briefing, and
  /// the incoming team's acknowledgement. Both are offline-first writes -
  /// a shift ending with no connectivity must still hand over cleanly.
  ShiftHandoverControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftHandoverControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftHandoverControllerHash();

  @$internal
  @override
  ShiftHandoverController create() => ShiftHandoverController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$shiftHandoverControllerHash() =>
    r'57e7ead927e10e45c3791c5193eeb8730c7ff6a5';

/// Backs Screen 26 (Shift Handover): the outgoing team's briefing, and
/// the incoming team's acknowledgement. Both are offline-first writes -
/// a shift ending with no connectivity must still hand over cleanly.

abstract class _$ShiftHandoverController extends $Notifier<void> {
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
