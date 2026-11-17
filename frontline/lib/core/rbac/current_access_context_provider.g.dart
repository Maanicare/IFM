// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_access_context_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Derives the [UserAccessContext] that [PolicyGuard] evaluates against
/// from the currently authenticated user. Null while logged out.

@ProviderFor(currentAccessContext)
final currentAccessContextProvider = CurrentAccessContextProvider._();

/// Derives the [UserAccessContext] that [PolicyGuard] evaluates against
/// from the currently authenticated user. Null while logged out.

final class CurrentAccessContextProvider
    extends
        $FunctionalProvider<
          UserAccessContext?,
          UserAccessContext?,
          UserAccessContext?
        >
    with $Provider<UserAccessContext?> {
  /// Derives the [UserAccessContext] that [PolicyGuard] evaluates against
  /// from the currently authenticated user. Null while logged out.
  CurrentAccessContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentAccessContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentAccessContextHash();

  @$internal
  @override
  $ProviderElement<UserAccessContext?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  UserAccessContext? create(Ref ref) {
    return currentAccessContext(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(UserAccessContext? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<UserAccessContext?>(value),
    );
  }
}

String _$currentAccessContextHash() =>
    r'd2b1c2bb3eda240922914fd5d2ed1e779be941d2';
