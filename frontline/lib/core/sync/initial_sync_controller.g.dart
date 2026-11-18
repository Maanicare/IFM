// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'initial_sync_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Pulls down everything the frontline app needs to work offline the
/// instant a session is established: location hierarchy, assets,
/// checklist templates, assigned work orders and open requests for the
/// user's primary site. Runs once per login; the [SyncAutoRunner] and
/// pull-to-refresh actions keep things fresh after that.

@ProviderFor(InitialSyncController)
final initialSyncControllerProvider = InitialSyncControllerProvider._();

/// Pulls down everything the frontline app needs to work offline the
/// instant a session is established: location hierarchy, assets,
/// checklist templates, assigned work orders and open requests for the
/// user's primary site. Runs once per login; the [SyncAutoRunner] and
/// pull-to-refresh actions keep things fresh after that.
final class InitialSyncControllerProvider
    extends $NotifierProvider<InitialSyncController, void> {
  /// Pulls down everything the frontline app needs to work offline the
  /// instant a session is established: location hierarchy, assets,
  /// checklist templates, assigned work orders and open requests for the
  /// user's primary site. Runs once per login; the [SyncAutoRunner] and
  /// pull-to-refresh actions keep things fresh after that.
  InitialSyncControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialSyncControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialSyncControllerHash();

  @$internal
  @override
  InitialSyncController create() => InitialSyncController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$initialSyncControllerHash() =>
    r'b90f9a9a13f91b038374e88de0b89849ca9aa2db';

/// Pulls down everything the frontline app needs to work offline the
/// instant a session is established: location hierarchy, assets,
/// checklist templates, assigned work orders and open requests for the
/// user's primary site. Runs once per login; the [SyncAutoRunner] and
/// pull-to-refresh actions keep things fresh after that.

abstract class _$InitialSyncController extends $Notifier<void> {
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
