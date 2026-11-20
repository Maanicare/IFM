// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_transaction_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Screen 33 - Stock Transaction: Receive/Transfer/Return/Repair/Scrap/
/// Adjustment, each requiring a reason (Section: "Requirement: Require
/// reason and user"). `Issue` stays on [PartsUsageController]'s
/// work-order-scoped flow, not this one.

@ProviderFor(StockTransactionController)
final stockTransactionControllerProvider =
    StockTransactionControllerProvider._();

/// Screen 33 - Stock Transaction: Receive/Transfer/Return/Repair/Scrap/
/// Adjustment, each requiring a reason (Section: "Requirement: Require
/// reason and user"). `Issue` stays on [PartsUsageController]'s
/// work-order-scoped flow, not this one.
final class StockTransactionControllerProvider
    extends $NotifierProvider<StockTransactionController, void> {
  /// Screen 33 - Stock Transaction: Receive/Transfer/Return/Repair/Scrap/
  /// Adjustment, each requiring a reason (Section: "Requirement: Require
  /// reason and user"). `Issue` stays on [PartsUsageController]'s
  /// work-order-scoped flow, not this one.
  StockTransactionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stockTransactionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stockTransactionControllerHash();

  @$internal
  @override
  StockTransactionController create() => StockTransactionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$stockTransactionControllerHash() =>
    r'85ff839259cc242843df87678a2d24036c64312d';

/// Screen 33 - Stock Transaction: Receive/Transfer/Return/Repair/Scrap/
/// Adjustment, each requiring a reason (Section: "Requirement: Require
/// reason and user"). `Issue` stays on [PartsUsageController]'s
/// work-order-scoped flow, not this one.

abstract class _$StockTransactionController extends $Notifier<void> {
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
