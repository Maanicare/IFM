// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_order_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(workOrderRepository)
final workOrderRepositoryProvider = WorkOrderRepositoryProvider._();

final class WorkOrderRepositoryProvider
    extends
        $FunctionalProvider<
          WorkOrderRepository,
          WorkOrderRepository,
          WorkOrderRepository
        >
    with $Provider<WorkOrderRepository> {
  WorkOrderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workOrderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workOrderRepositoryHash();

  @$internal
  @override
  $ProviderElement<WorkOrderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WorkOrderRepository create(Ref ref) {
    return workOrderRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WorkOrderRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WorkOrderRepository>(value),
    );
  }
}

String _$workOrderRepositoryHash() =>
    r'0943be91454ee7d1dadf91a866afdebbba301f91';
