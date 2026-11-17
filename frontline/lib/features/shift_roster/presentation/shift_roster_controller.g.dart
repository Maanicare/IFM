// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_roster_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Self-service attendance changes on Screen 25 - "Mark absence" and
/// "Request relief". Full roster authoring (Swap/Replace another
/// employee's entry) stays a manager action outside this mobile app.

@ProviderFor(ShiftRosterController)
final shiftRosterControllerProvider = ShiftRosterControllerProvider._();

/// Self-service attendance changes on Screen 25 - "Mark absence" and
/// "Request relief". Full roster authoring (Swap/Replace another
/// employee's entry) stays a manager action outside this mobile app.
final class ShiftRosterControllerProvider
    extends $NotifierProvider<ShiftRosterController, void> {
  /// Self-service attendance changes on Screen 25 - "Mark absence" and
  /// "Request relief". Full roster authoring (Swap/Replace another
  /// employee's entry) stays a manager action outside this mobile app.
  ShiftRosterControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftRosterControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftRosterControllerHash();

  @$internal
  @override
  ShiftRosterController create() => ShiftRosterController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$shiftRosterControllerHash() =>
    r'7d6740b04d85436b6481e0c8e4680632d64ebde7';

/// Self-service attendance changes on Screen 25 - "Mark absence" and
/// "Request relief". Full roster authoring (Swap/Replace another
/// employee's entry) stays a manager action outside this mobile app.

abstract class _$ShiftRosterController extends $Notifier<void> {
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
