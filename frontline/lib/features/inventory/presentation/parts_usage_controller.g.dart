// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parts_usage_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Records a part consumed against a work order (Section 29: "parts
/// consumed"; Section 37: `inventory_transactions`). Writes the
/// transaction, decrements the local site balance, and enqueues the push
/// - same evidence-before-claims transactional pattern used for checklist
/// responses and status transitions elsewhere in this app.

@ProviderFor(PartsUsageController)
final partsUsageControllerProvider = PartsUsageControllerProvider._();

/// Records a part consumed against a work order (Section 29: "parts
/// consumed"; Section 37: `inventory_transactions`). Writes the
/// transaction, decrements the local site balance, and enqueues the push
/// - same evidence-before-claims transactional pattern used for checklist
/// responses and status transitions elsewhere in this app.
final class PartsUsageControllerProvider
    extends $NotifierProvider<PartsUsageController, void> {
  /// Records a part consumed against a work order (Section 29: "parts
  /// consumed"; Section 37: `inventory_transactions`). Writes the
  /// transaction, decrements the local site balance, and enqueues the push
  /// - same evidence-before-claims transactional pattern used for checklist
  /// responses and status transitions elsewhere in this app.
  PartsUsageControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'partsUsageControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$partsUsageControllerHash();

  @$internal
  @override
  PartsUsageController create() => PartsUsageController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$partsUsageControllerHash() =>
    r'285ed03a6167fecd5aaaf9bd0bac80e1127433a9';

/// Records a part consumed against a work order (Section 29: "parts
/// consumed"; Section 37: `inventory_transactions`). Writes the
/// transaction, decrements the local site balance, and enqueues the push
/// - same evidence-before-claims transactional pattern used for checklist
/// responses and status transitions elsewhere in this app.

abstract class _$PartsUsageController extends $Notifier<void> {
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
