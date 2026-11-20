// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comfort_feedback_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(comfortFeedbackRepository)
final comfortFeedbackRepositoryProvider = ComfortFeedbackRepositoryProvider._();

final class ComfortFeedbackRepositoryProvider
    extends
        $FunctionalProvider<
          ComfortFeedbackRepository,
          ComfortFeedbackRepository,
          ComfortFeedbackRepository
        >
    with $Provider<ComfortFeedbackRepository> {
  ComfortFeedbackRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'comfortFeedbackRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$comfortFeedbackRepositoryHash();

  @$internal
  @override
  $ProviderElement<ComfortFeedbackRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ComfortFeedbackRepository create(Ref ref) {
    return comfortFeedbackRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ComfortFeedbackRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ComfortFeedbackRepository>(value),
    );
  }
}

String _$comfortFeedbackRepositoryHash() =>
    r'3faae7ef27ea27be7d6c8ac8114cc1616fe4bb17';
