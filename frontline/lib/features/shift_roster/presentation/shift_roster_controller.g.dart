// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_roster_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Self-service actions on Screen 25 - Mark absence / Request relief
/// (attendance), and Swap / Replace (see the doc comments on
/// [AppDatabase.shiftRosterDao]'s `swapShifts`/`setReplacement` for
/// what those mean here given there's no synced employee directory
/// beyond today's roster).

@ProviderFor(ShiftRosterController)
final shiftRosterControllerProvider = ShiftRosterControllerProvider._();

/// Self-service actions on Screen 25 - Mark absence / Request relief
/// (attendance), and Swap / Replace (see the doc comments on
/// [AppDatabase.shiftRosterDao]'s `swapShifts`/`setReplacement` for
/// what those mean here given there's no synced employee directory
/// beyond today's roster).
final class ShiftRosterControllerProvider
    extends $NotifierProvider<ShiftRosterController, void> {
  /// Self-service actions on Screen 25 - Mark absence / Request relief
  /// (attendance), and Swap / Replace (see the doc comments on
  /// [AppDatabase.shiftRosterDao]'s `swapShifts`/`setReplacement` for
  /// what those mean here given there's no synced employee directory
  /// beyond today's roster).
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
    r'e841ebf6ddca8f5a8dbff141004602674b7f2528';

/// Self-service actions on Screen 25 - Mark absence / Request relief
/// (attendance), and Swap / Replace (see the doc comments on
/// [AppDatabase.shiftRosterDao]'s `swapShifts`/`setReplacement` for
/// what those mean here given there's no synced employee directory
/// beyond today's roster).

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
