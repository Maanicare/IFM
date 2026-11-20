// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 23 (Soft Service Inspection). Writes locally first, then
/// pushes through the outbox - same pattern as Incident/Hazard
/// reporting.

@ProviderFor(InspectionController)
final inspectionControllerProvider = InspectionControllerProvider._();

/// Backs Screen 23 (Soft Service Inspection). Writes locally first, then
/// pushes through the outbox - same pattern as Incident/Hazard
/// reporting.
final class InspectionControllerProvider
    extends $NotifierProvider<InspectionController, void> {
  /// Backs Screen 23 (Soft Service Inspection). Writes locally first, then
  /// pushes through the outbox - same pattern as Incident/Hazard
  /// reporting.
  InspectionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inspectionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inspectionControllerHash();

  @$internal
  @override
  InspectionController create() => InspectionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$inspectionControllerHash() =>
    r'1e00dea4606474ac8873843b7ac4a1c6698c6653';

/// Backs Screen 23 (Soft Service Inspection). Writes locally first, then
/// pushes through the outbox - same pattern as Incident/Hazard
/// reporting.

abstract class _$InspectionController extends $Notifier<void> {
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
