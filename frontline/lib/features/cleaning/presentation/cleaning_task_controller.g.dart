// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleaning_task_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Screen 21 actions: start a task, record an inspection-point response,
/// and submit completion (Consumables used / Exception notes).

@ProviderFor(CleaningTaskController)
final cleaningTaskControllerProvider = CleaningTaskControllerProvider._();

/// Screen 21 actions: start a task, record an inspection-point response,
/// and submit completion (Consumables used / Exception notes).
final class CleaningTaskControllerProvider
    extends $NotifierProvider<CleaningTaskController, void> {
  /// Screen 21 actions: start a task, record an inspection-point response,
  /// and submit completion (Consumables used / Exception notes).
  CleaningTaskControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cleaningTaskControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cleaningTaskControllerHash();

  @$internal
  @override
  CleaningTaskController create() => CleaningTaskController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$cleaningTaskControllerHash() =>
    r'145d97d5c45e438fb678c07dbad3908d18970d5b';

/// Screen 21 actions: start a task, record an inspection-point response,
/// and submit completion (Consumables used / Exception notes).

abstract class _$CleaningTaskController extends $Notifier<void> {
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
