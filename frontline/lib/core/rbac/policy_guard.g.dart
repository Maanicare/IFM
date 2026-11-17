// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_guard.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(policyGuard)
final policyGuardProvider = PolicyGuardProvider._();

final class PolicyGuardProvider
    extends $FunctionalProvider<PolicyGuard, PolicyGuard, PolicyGuard>
    with $Provider<PolicyGuard> {
  PolicyGuardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'policyGuardProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$policyGuardHash();

  @$internal
  @override
  $ProviderElement<PolicyGuard> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PolicyGuard create(Ref ref) {
    return policyGuard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PolicyGuard value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PolicyGuard>(value),
    );
  }
}

String _$policyGuardHash() => r'b22f3a14db70c160c2226a9aca75d0d1636e5d33';
