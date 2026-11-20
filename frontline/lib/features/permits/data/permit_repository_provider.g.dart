// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permit_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(permitRepository)
final permitRepositoryProvider = PermitRepositoryProvider._();

final class PermitRepositoryProvider
    extends
        $FunctionalProvider<
          PermitRepository,
          PermitRepository,
          PermitRepository
        >
    with $Provider<PermitRepository> {
  PermitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permitRepositoryHash();

  @$internal
  @override
  $ProviderElement<PermitRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PermitRepository create(Ref ref) {
    return permitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PermitRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PermitRepository>(value),
    );
  }
}

String _$permitRepositoryHash() => r'bf3a18cd9d7349caa7bf8fefdd8cc697185e7c2b';
