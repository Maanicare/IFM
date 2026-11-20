// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_report_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 35 (Incident Report) and Screen 36 (Hazard/Near Miss).
/// Both write locally first - a safety report must never be lost to a
/// dropped connection - then push through the same repository-call
/// pattern used everywhere else in this app.

@ProviderFor(SafetyReportController)
final safetyReportControllerProvider = SafetyReportControllerProvider._();

/// Backs Screen 35 (Incident Report) and Screen 36 (Hazard/Near Miss).
/// Both write locally first - a safety report must never be lost to a
/// dropped connection - then push through the same repository-call
/// pattern used everywhere else in this app.
final class SafetyReportControllerProvider
    extends $NotifierProvider<SafetyReportController, void> {
  /// Backs Screen 35 (Incident Report) and Screen 36 (Hazard/Near Miss).
  /// Both write locally first - a safety report must never be lost to a
  /// dropped connection - then push through the same repository-call
  /// pattern used everywhere else in this app.
  SafetyReportControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safetyReportControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safetyReportControllerHash();

  @$internal
  @override
  SafetyReportController create() => SafetyReportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$safetyReportControllerHash() =>
    r'5e6ca9c3cdb30053a80fb2481adcb6922ce75862';

/// Backs Screen 35 (Incident Report) and Screen 36 (Hazard/Near Miss).
/// Both write locally first - a safety report must never be lost to a
/// dropped connection - then push through the same repository-call
/// pattern used everywhere else in this app.

abstract class _$SafetyReportController extends $Notifier<void> {
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
