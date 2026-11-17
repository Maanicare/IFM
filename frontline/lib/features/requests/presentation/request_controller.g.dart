// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs "Report an Issue" (Journey 1 / SCREEN 06). Creating a request is
/// itself treated as an offline-first mutation: the repository writes the
/// row locally and returns a ticket number instantly, and this controller
/// enqueues the outbox entry that pushes it to the server.

@ProviderFor(RequestController)
final requestControllerProvider = RequestControllerProvider._();

/// Backs "Report an Issue" (Journey 1 / SCREEN 06). Creating a request is
/// itself treated as an offline-first mutation: the repository writes the
/// row locally and returns a ticket number instantly, and this controller
/// enqueues the outbox entry that pushes it to the server.
final class RequestControllerProvider
    extends $NotifierProvider<RequestController, void> {
  /// Backs "Report an Issue" (Journey 1 / SCREEN 06). Creating a request is
  /// itself treated as an offline-first mutation: the repository writes the
  /// row locally and returns a ticket number instantly, and this controller
  /// enqueues the outbox entry that pushes it to the server.
  RequestControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requestControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requestControllerHash();

  @$internal
  @override
  RequestController create() => RequestController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$requestControllerHash() => r'49508b312fb81ff5815bb6b96f08b6abcf6e5082';

/// Backs "Report an Issue" (Journey 1 / SCREEN 06). Creating a request is
/// itself treated as an offline-first mutation: the repository writes the
/// row locally and returns a ticket number instantly, and this controller
/// enqueues the outbox entry that pushes it to the server.

abstract class _$RequestController extends $Notifier<void> {
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
