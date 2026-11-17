// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(syncEngine)
final syncEngineProvider = SyncEngineProvider._();

final class SyncEngineProvider
    extends $FunctionalProvider<SyncEngine, SyncEngine, SyncEngine>
    with $Provider<SyncEngine> {
  SyncEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncEngineHash();

  @$internal
  @override
  $ProviderElement<SyncEngine> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SyncEngine create(Ref ref) {
    return syncEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SyncEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SyncEngine>(value),
    );
  }
}

String _$syncEngineHash() => r'3e5c40a72de004cbaffde98175f11680cc9133c4';

/// Watches connectivity and automatically drains the outbox the moment the
/// device comes back online, so a technician never has to remember to
/// manually "sync".

@ProviderFor(SyncAutoRunner)
final syncAutoRunnerProvider = SyncAutoRunnerProvider._();

/// Watches connectivity and automatically drains the outbox the moment the
/// device comes back online, so a technician never has to remember to
/// manually "sync".
final class SyncAutoRunnerProvider
    extends $NotifierProvider<SyncAutoRunner, void> {
  /// Watches connectivity and automatically drains the outbox the moment the
  /// device comes back online, so a technician never has to remember to
  /// manually "sync".
  SyncAutoRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncAutoRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncAutoRunnerHash();

  @$internal
  @override
  SyncAutoRunner create() => SyncAutoRunner();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$syncAutoRunnerHash() => r'ee3eabb5ff5378ff1f6eb3b966e58f307901b992';

/// Watches connectivity and automatically drains the outbox the moment the
/// device comes back online, so a technician never has to remember to
/// manually "sync".

abstract class _$SyncAutoRunner extends $Notifier<void> {
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
