// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checklist_response_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Writes one checklist answer locally and enqueues it for sync, in a
/// single transaction (Section 3.2: evidence-before-claims - an answer
/// must be durably recorded the instant it's given, offline or not).

@ProviderFor(ChecklistResponseController)
final checklistResponseControllerProvider =
    ChecklistResponseControllerProvider._();

/// Writes one checklist answer locally and enqueues it for sync, in a
/// single transaction (Section 3.2: evidence-before-claims - an answer
/// must be durably recorded the instant it's given, offline or not).
final class ChecklistResponseControllerProvider
    extends $NotifierProvider<ChecklistResponseController, void> {
  /// Writes one checklist answer locally and enqueues it for sync, in a
  /// single transaction (Section 3.2: evidence-before-claims - an answer
  /// must be durably recorded the instant it's given, offline or not).
  ChecklistResponseControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checklistResponseControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checklistResponseControllerHash();

  @$internal
  @override
  ChecklistResponseController create() => ChecklistResponseController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$checklistResponseControllerHash() =>
    r'24cc7581453f6c3a7edd127e9ff1d01a5a6f6b5d';

/// Writes one checklist answer locally and enqueues it for sync, in a
/// single transaction (Section 3.2: evidence-before-claims - an answer
/// must be durably recorded the instant it's given, offline or not).

abstract class _$ChecklistResponseController extends $Notifier<void> {
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
