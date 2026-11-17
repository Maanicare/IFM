// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(identityRepository)
final identityRepositoryProvider = IdentityRepositoryProvider._();

final class IdentityRepositoryProvider
    extends
        $FunctionalProvider<
          IdentityRepository,
          IdentityRepository,
          IdentityRepository
        >
    with $Provider<IdentityRepository> {
  IdentityRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'identityRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$identityRepositoryHash();

  @$internal
  @override
  $ProviderElement<IdentityRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  IdentityRepository create(Ref ref) {
    return identityRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdentityRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdentityRepository>(value),
    );
  }
}

String _$identityRepositoryHash() =>
    r'ecc1fc9d478287c58e98deab8080727ce5ff9681';
