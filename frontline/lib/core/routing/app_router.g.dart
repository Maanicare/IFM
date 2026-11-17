// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Frontline navigation (Section 14): a flat five-tab shell - Home, My
/// Work, Scan, Requests, More - deliberately much simpler than the
/// enterprise 19-item navigation used by management/desktop surfaces.

@ProviderFor(appRouter)
final appRouterProvider = AppRouterProvider._();

/// Frontline navigation (Section 14): a flat five-tab shell - Home, My
/// Work, Scan, Requests, More - deliberately much simpler than the
/// enterprise 19-item navigation used by management/desktop surfaces.

final class AppRouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
  /// Frontline navigation (Section 14): a flat five-tab shell - Home, My
  /// Work, Scan, Requests, More - deliberately much simpler than the
  /// enterprise 19-item navigation used by management/desktop surfaces.
  AppRouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appRouterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appRouterHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return appRouter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$appRouterHash() => r'd3d9850a7f5defe2edd874d4ff1cd819464adde3';
