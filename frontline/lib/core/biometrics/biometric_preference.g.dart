// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'biometric_preference.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether biometric login is enabled, and which identifier to log in
/// as when it succeeds (Screen 01: "Biometric login after first
/// authentication"). The password itself is never stored - in mock mode
/// any password is accepted, so an empty one is used; a real backend
/// would exchange a stored long-lived device/refresh token here instead
/// (not implemented - this app has no refresh-token endpoint to call).

@ProviderFor(BiometricPreference)
final biometricPreferenceProvider = BiometricPreferenceProvider._();

/// Whether biometric login is enabled, and which identifier to log in
/// as when it succeeds (Screen 01: "Biometric login after first
/// authentication"). The password itself is never stored - in mock mode
/// any password is accepted, so an empty one is used; a real backend
/// would exchange a stored long-lived device/refresh token here instead
/// (not implemented - this app has no refresh-token endpoint to call).
final class BiometricPreferenceProvider
    extends
        $AsyncNotifierProvider<
          BiometricPreference,
          ({bool enabled, String? identifier})
        > {
  /// Whether biometric login is enabled, and which identifier to log in
  /// as when it succeeds (Screen 01: "Biometric login after first
  /// authentication"). The password itself is never stored - in mock mode
  /// any password is accepted, so an empty one is used; a real backend
  /// would exchange a stored long-lived device/refresh token here instead
  /// (not implemented - this app has no refresh-token endpoint to call).
  BiometricPreferenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'biometricPreferenceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$biometricPreferenceHash();

  @$internal
  @override
  BiometricPreference create() => BiometricPreference();
}

String _$biometricPreferenceHash() =>
    r'6b78028d2eceb4c94e599778bcb98ccee1cc4779';

/// Whether biometric login is enabled, and which identifier to log in
/// as when it succeeds (Screen 01: "Biometric login after first
/// authentication"). The password itself is never stored - in mock mode
/// any password is accepted, so an empty one is used; a real backend
/// would exchange a stored long-lived device/refresh token here instead
/// (not implemented - this app has no refresh-token endpoint to call).

abstract class _$BiometricPreference
    extends $AsyncNotifier<({bool enabled, String? identifier})> {
  FutureOr<({bool enabled, String? identifier})> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<({bool enabled, String? identifier})>,
              ({bool enabled, String? identifier})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<({bool enabled, String? identifier})>,
                ({bool enabled, String? identifier})
              >,
              AsyncValue<({bool enabled, String? identifier})>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
