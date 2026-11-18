// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_switch_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Switching the active site (Screen 02: "Switch site") isn't just a UI
/// preference - everything the offline cache holds (assets, requests,
/// work orders, parts) was pulled for one site at [InitialSyncController]
/// time. Switching must re-pull for the newly-selected site so the rest
/// of the app (Create Request, My Work, Parts Used) is working against
/// the right data, not stale/missing data from the previous site.

@ProviderFor(SiteSwitchController)
final siteSwitchControllerProvider = SiteSwitchControllerProvider._();

/// Switching the active site (Screen 02: "Switch site") isn't just a UI
/// preference - everything the offline cache holds (assets, requests,
/// work orders, parts) was pulled for one site at [InitialSyncController]
/// time. Switching must re-pull for the newly-selected site so the rest
/// of the app (Create Request, My Work, Parts Used) is working against
/// the right data, not stale/missing data from the previous site.
final class SiteSwitchControllerProvider
    extends $NotifierProvider<SiteSwitchController, void> {
  /// Switching the active site (Screen 02: "Switch site") isn't just a UI
  /// preference - everything the offline cache holds (assets, requests,
  /// work orders, parts) was pulled for one site at [InitialSyncController]
  /// time. Switching must re-pull for the newly-selected site so the rest
  /// of the app (Create Request, My Work, Parts Used) is working against
  /// the right data, not stale/missing data from the previous site.
  SiteSwitchControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'siteSwitchControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$siteSwitchControllerHash();

  @$internal
  @override
  SiteSwitchController create() => SiteSwitchController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$siteSwitchControllerHash() =>
    r'164cc291f96b9aef4b64e083a22ca5deb767ed0d';

/// Switching the active site (Screen 02: "Switch site") isn't just a UI
/// preference - everything the offline cache holds (assets, requests,
/// work orders, parts) was pulled for one site at [InitialSyncController]
/// time. Switching must re-pull for the newly-selected site so the rest
/// of the app (Create Request, My Work, Parts Used) is working against
/// the right data, not stale/missing data from the previous site.

abstract class _$SiteSwitchController extends $Notifier<void> {
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
