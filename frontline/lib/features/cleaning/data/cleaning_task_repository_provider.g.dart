// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleaning_task_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cleaningTaskRepository)
final cleaningTaskRepositoryProvider = CleaningTaskRepositoryProvider._();

final class CleaningTaskRepositoryProvider
    extends
        $FunctionalProvider<
          CleaningTaskRepository,
          CleaningTaskRepository,
          CleaningTaskRepository
        >
    with $Provider<CleaningTaskRepository> {
  CleaningTaskRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cleaningTaskRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cleaningTaskRepositoryHash();

  @$internal
  @override
  $ProviderElement<CleaningTaskRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CleaningTaskRepository create(Ref ref) {
    return cleaningTaskRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CleaningTaskRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CleaningTaskRepository>(value),
    );
  }
}

String _$cleaningTaskRepositoryHash() =>
    r'e1a519f57edbbc15af3dfd02498d922bc49275cd';
