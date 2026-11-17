// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_gate_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pre-work safety gate (Section 11). Records each question's answer as
/// its own row (not one JSON blob) so a future audit/analytics query can
/// ask "how often is PPE answered no" without parsing payloads.

@ProviderFor(SafetyGateController)
final safetyGateControllerProvider = SafetyGateControllerProvider._();

/// Pre-work safety gate (Section 11). Records each question's answer as
/// its own row (not one JSON blob) so a future audit/analytics query can
/// ask "how often is PPE answered no" without parsing payloads.
final class SafetyGateControllerProvider
    extends $NotifierProvider<SafetyGateController, void> {
  /// Pre-work safety gate (Section 11). Records each question's answer as
  /// its own row (not one JSON blob) so a future audit/analytics query can
  /// ask "how often is PPE answered no" without parsing payloads.
  SafetyGateControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'safetyGateControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$safetyGateControllerHash();

  @$internal
  @override
  SafetyGateController create() => SafetyGateController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$safetyGateControllerHash() =>
    r'5364d344f40c52e17b8931f707d8f1191048c249';

/// Pre-work safety gate (Section 11). Records each question's answer as
/// its own row (not one JSON blob) so a future audit/analytics query can
/// ask "how often is PPE answered no" without parsing payloads.

abstract class _$SafetyGateController extends $Notifier<void> {
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
