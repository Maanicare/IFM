// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permit_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 37 (Permit to Work): issuing and closing a permit.

@ProviderFor(PermitController)
final permitControllerProvider = PermitControllerProvider._();

/// Backs Screen 37 (Permit to Work): issuing and closing a permit.
final class PermitControllerProvider
    extends $NotifierProvider<PermitController, void> {
  /// Backs Screen 37 (Permit to Work): issuing and closing a permit.
  PermitControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permitControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permitControllerHash();

  @$internal
  @override
  PermitController create() => PermitController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$permitControllerHash() => r'1d496f918c684b154b5012fabc4bebcf7e94580b';

/// Backs Screen 37 (Permit to Work): issuing and closing a permit.

abstract class _$PermitController extends $Notifier<void> {
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
