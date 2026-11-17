// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Session state for the whole app. `AsyncValue<AuthenticatedUser?>`:
///   - loading: still checking for a restored session on app start.
///   - data(null): no session - show the login screen.
///   - data(user): authenticated - show the main app shell.
///   - error: restore or login failed.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// Session state for the whole app. `AsyncValue<AuthenticatedUser?>`:
///   - loading: still checking for a restored session on app start.
///   - data(null): no session - show the login screen.
///   - data(user): authenticated - show the main app shell.
///   - error: restore or login failed.
final class AuthControllerProvider
    extends $AsyncNotifierProvider<AuthController, AuthenticatedUser?> {
  /// Session state for the whole app. `AsyncValue<AuthenticatedUser?>`:
  ///   - loading: still checking for a restored session on app start.
  ///   - data(null): no session - show the login screen.
  ///   - data(user): authenticated - show the main app shell.
  ///   - error: restore or login failed.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'04af9c6681fa40fbcbf0aa53c2792c27352c4da9';

/// Session state for the whole app. `AsyncValue<AuthenticatedUser?>`:
///   - loading: still checking for a restored session on app start.
///   - data(null): no session - show the login screen.
///   - data(user): authenticated - show the main app shell.
///   - error: restore or login failed.

abstract class _$AuthController extends $AsyncNotifier<AuthenticatedUser?> {
  FutureOr<AuthenticatedUser?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<AuthenticatedUser?>, AuthenticatedUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthenticatedUser?>, AuthenticatedUser?>,
              AsyncValue<AuthenticatedUser?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
