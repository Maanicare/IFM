// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visitor_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 44 (Visitor Management): check in a visitor (generating
/// a QR pass) and check them out.

@ProviderFor(VisitorController)
final visitorControllerProvider = VisitorControllerProvider._();

/// Backs Screen 44 (Visitor Management): check in a visitor (generating
/// a QR pass) and check them out.
final class VisitorControllerProvider
    extends $NotifierProvider<VisitorController, void> {
  /// Backs Screen 44 (Visitor Management): check in a visitor (generating
  /// a QR pass) and check them out.
  VisitorControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visitorControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visitorControllerHash();

  @$internal
  @override
  VisitorController create() => VisitorController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$visitorControllerHash() => r'6ff64fffa9de81a49d23556f4df1f1769f307399';

/// Backs Screen 44 (Visitor Management): check in a visitor (generating
/// a QR pass) and check them out.

abstract class _$VisitorController extends $Notifier<void> {
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
