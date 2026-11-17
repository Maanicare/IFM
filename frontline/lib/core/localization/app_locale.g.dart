// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_locale.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persists the technician's chosen language (Screen 01: language
/// selector) in the same secure storage used for auth, so it survives
/// restarts without needing its own table/row.

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

/// Persists the technician's chosen language (Screen 01: language
/// selector) in the same secure storage used for auth, so it survives
/// restarts without needing its own table/row.
final class AppLocaleProvider
    extends $AsyncNotifierProvider<AppLocale, String> {
  /// Persists the technician's chosen language (Screen 01: language
  /// selector) in the same secure storage used for auth, so it survives
  /// restarts without needing its own table/row.
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();
}

String _$appLocaleHash() => r'ab92a651f13c235ce8c51bfcab7eadce5df03476';

/// Persists the technician's chosen language (Screen 01: language
/// selector) in the same secure storage used for auth, so it survives
/// restarts without needing its own table/row.

abstract class _$AppLocale extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
