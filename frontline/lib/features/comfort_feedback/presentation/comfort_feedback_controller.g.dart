// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comfort_feedback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Backs Screen 46 (Comfort Feedback): a one-tap submission, no
/// confirmation dialog or multi-step form - that's the point of
/// "One-Touch".

@ProviderFor(ComfortFeedbackController)
final comfortFeedbackControllerProvider = ComfortFeedbackControllerProvider._();

/// Backs Screen 46 (Comfort Feedback): a one-tap submission, no
/// confirmation dialog or multi-step form - that's the point of
/// "One-Touch".
final class ComfortFeedbackControllerProvider
    extends $NotifierProvider<ComfortFeedbackController, void> {
  /// Backs Screen 46 (Comfort Feedback): a one-tap submission, no
  /// confirmation dialog or multi-step form - that's the point of
  /// "One-Touch".
  ComfortFeedbackControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comfortFeedbackControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comfortFeedbackControllerHash();

  @$internal
  @override
  ComfortFeedbackController create() => ComfortFeedbackController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$comfortFeedbackControllerHash() =>
    r'acf09b6dcd52f83c3153099888d8c48b26a47a46';

/// Backs Screen 46 (Comfort Feedback): a one-tap submission, no
/// confirmation dialog or multi-step form - that's the point of
/// "One-Touch".

abstract class _$ComfortFeedbackController extends $Notifier<void> {
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
