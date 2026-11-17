// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_handover_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shiftHandoverRepository)
final shiftHandoverRepositoryProvider = ShiftHandoverRepositoryProvider._();

final class ShiftHandoverRepositoryProvider
    extends
        $FunctionalProvider<
          ShiftHandoverRepository,
          ShiftHandoverRepository,
          ShiftHandoverRepository
        >
    with $Provider<ShiftHandoverRepository> {
  ShiftHandoverRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftHandoverRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftHandoverRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShiftHandoverRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShiftHandoverRepository create(Ref ref) {
    return shiftHandoverRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShiftHandoverRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShiftHandoverRepository>(value),
    );
  }
}

String _$shiftHandoverRepositoryHash() =>
    r'a6f71d2ea13e4087c2b9554bfaef0b018870f271';
