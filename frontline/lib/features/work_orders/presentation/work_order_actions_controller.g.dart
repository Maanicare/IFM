// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_actions_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every technician-initiated status transition (Section 11: Accept ->
/// En Route -> Checked In -> In Progress -> ... -> Work Completed) goes
/// through here. Each method:
///   1. Checks the action against [PolicyGuard].
///   2. Applies the change to the local [WorkOrders] row immediately
///      (optimistic UI - the technician never waits on network).
///   3. Writes an audit row to [WorkOrderStatusHistory].
///   4. Enqueues an outbox entry so the sync engine replays it to the
///      server as soon as connectivity allows.
/// Steps 2-4 run inside one Drift transaction so the device is never left
/// in a state where the local status changed but no outbox entry exists
/// to push it (or vice versa).

@ProviderFor(WorkOrderActionsController)
final workOrderActionsControllerProvider =
    WorkOrderActionsControllerProvider._();

/// Every technician-initiated status transition (Section 11: Accept ->
/// En Route -> Checked In -> In Progress -> ... -> Work Completed) goes
/// through here. Each method:
///   1. Checks the action against [PolicyGuard].
///   2. Applies the change to the local [WorkOrders] row immediately
///      (optimistic UI - the technician never waits on network).
///   3. Writes an audit row to [WorkOrderStatusHistory].
///   4. Enqueues an outbox entry so the sync engine replays it to the
///      server as soon as connectivity allows.
/// Steps 2-4 run inside one Drift transaction so the device is never left
/// in a state where the local status changed but no outbox entry exists
/// to push it (or vice versa).
final class WorkOrderActionsControllerProvider
    extends $NotifierProvider<WorkOrderActionsController, void> {
  /// Every technician-initiated status transition (Section 11: Accept ->
  /// En Route -> Checked In -> In Progress -> ... -> Work Completed) goes
  /// through here. Each method:
  ///   1. Checks the action against [PolicyGuard].
  ///   2. Applies the change to the local [WorkOrders] row immediately
  ///      (optimistic UI - the technician never waits on network).
  ///   3. Writes an audit row to [WorkOrderStatusHistory].
  ///   4. Enqueues an outbox entry so the sync engine replays it to the
  ///      server as soon as connectivity allows.
  /// Steps 2-4 run inside one Drift transaction so the device is never left
  /// in a state where the local status changed but no outbox entry exists
  /// to push it (or vice versa).
  WorkOrderActionsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workOrderActionsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workOrderActionsControllerHash();

  @$internal
  @override
  WorkOrderActionsController create() => WorkOrderActionsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$workOrderActionsControllerHash() =>
    r'8424791076115dc128a16aa756feeb8a60dc9ad8';

/// Every technician-initiated status transition (Section 11: Accept ->
/// En Route -> Checked In -> In Progress -> ... -> Work Completed) goes
/// through here. Each method:
///   1. Checks the action against [PolicyGuard].
///   2. Applies the change to the local [WorkOrders] row immediately
///      (optimistic UI - the technician never waits on network).
///   3. Writes an audit row to [WorkOrderStatusHistory].
///   4. Enqueues an outbox entry so the sync engine replays it to the
///      server as soon as connectivity allows.
/// Steps 2-4 run inside one Drift transaction so the device is never left
/// in a state where the local status changed but no outbox entry exists
/// to push it (or vice versa).

abstract class _$WorkOrderActionsController extends $Notifier<void> {
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
