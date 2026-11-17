// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_site_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The site a multi-site user is currently operating against (Screen 02:
/// Role/Site Selector). Falls back to the first assigned site until the
/// technician has explicitly switched at least once, so every other
/// screen that needs "my site right now" (Create Request, My Work) has a
/// single source of truth rather than each re-deriving `siteIds.first`.

@ProviderFor(currentSiteId)
final currentSiteIdProvider = CurrentSiteIdProvider._();

/// The site a multi-site user is currently operating against (Screen 02:
/// Role/Site Selector). Falls back to the first assigned site until the
/// technician has explicitly switched at least once, so every other
/// screen that needs "my site right now" (Create Request, My Work) has a
/// single source of truth rather than each re-deriving `siteIds.first`.

final class CurrentSiteIdProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// The site a multi-site user is currently operating against (Screen 02:
  /// Role/Site Selector). Falls back to the first assigned site until the
  /// technician has explicitly switched at least once, so every other
  /// screen that needs "my site right now" (Create Request, My Work) has a
  /// single source of truth rather than each re-deriving `siteIds.first`.
  CurrentSiteIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentSiteIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentSiteIdHash();

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    return currentSiteId(ref);
  }
}

String _$currentSiteIdHash() => r'1a305a0761327bebc70378e030ec27099d3d84e2';
