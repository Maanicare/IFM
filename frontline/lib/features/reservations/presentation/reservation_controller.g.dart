// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 43 (Reservation): Reserve/Invite/Order services/Check
/// in. Reserve/Invite/Order services are all captured in one step at
/// booking time (see the doc comment on [Reservations] for why Invite
/// and Order services are free text, not real sub-systems).

@ProviderFor(ReservationController)
final reservationControllerProvider = ReservationControllerProvider._();

/// Backs Screen 43 (Reservation): Reserve/Invite/Order services/Check
/// in. Reserve/Invite/Order services are all captured in one step at
/// booking time (see the doc comment on [Reservations] for why Invite
/// and Order services are free text, not real sub-systems).
final class ReservationControllerProvider
    extends $NotifierProvider<ReservationController, void> {
  /// Backs Screen 43 (Reservation): Reserve/Invite/Order services/Check
  /// in. Reserve/Invite/Order services are all captured in one step at
  /// booking time (see the doc comment on [Reservations] for why Invite
  /// and Order services are free text, not real sub-systems).
  ReservationControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reservationControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reservationControllerHash();

  @$internal
  @override
  ReservationController create() => ReservationController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$reservationControllerHash() =>
    r'940b7ce5a4e85a913ecd6db3fc6d008774593767';

/// Backs Screen 43 (Reservation): Reserve/Invite/Order services/Check
/// in. Reserve/Invite/Order services are all captured in one step at
/// booking time (see the doc comment on [Reservations] for why Invite
/// and Order services are free text, not real sub-systems).

abstract class _$ReservationController extends $Notifier<void> {
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
