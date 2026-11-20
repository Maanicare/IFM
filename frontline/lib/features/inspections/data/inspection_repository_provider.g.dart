// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inspection_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inspectionRepository)
final inspectionRepositoryProvider = InspectionRepositoryProvider._();

final class InspectionRepositoryProvider
    extends
        $FunctionalProvider<
          InspectionRepository,
          InspectionRepository,
          InspectionRepository
        >
    with $Provider<InspectionRepository> {
  InspectionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inspectionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inspectionRepositoryHash();

  @$internal
  @override
  $ProviderElement<InspectionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  InspectionRepository create(Ref ref) {
    return inspectionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InspectionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<InspectionRepository>(value),
    );
  }
}

String _$inspectionRepositoryHash() =>
    r'2c3be72a0bbb697b6738835f0c8131c9f8ccf26a';
