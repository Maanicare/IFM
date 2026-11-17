// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_roster_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(shiftRosterRepository)
final shiftRosterRepositoryProvider = ShiftRosterRepositoryProvider._();

final class ShiftRosterRepositoryProvider
    extends
        $FunctionalProvider<
          ShiftRosterRepository,
          ShiftRosterRepository,
          ShiftRosterRepository
        >
    with $Provider<ShiftRosterRepository> {
  ShiftRosterRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shiftRosterRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shiftRosterRepositoryHash();

  @$internal
  @override
  $ProviderElement<ShiftRosterRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ShiftRosterRepository create(Ref ref) {
    return shiftRosterRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShiftRosterRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ShiftRosterRepository>(value),
    );
  }
}

String _$shiftRosterRepositoryHash() =>
    r'6332110c22da990892c22c5c4e5af88062d1f066';
