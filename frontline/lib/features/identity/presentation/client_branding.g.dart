// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_branding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clientBranding)
final clientBrandingProvider = ClientBrandingFamily._();

final class ClientBrandingProvider
    extends
        $FunctionalProvider<
          AsyncValue<ClientBranding?>,
          ClientBranding?,
          FutureOr<ClientBranding?>
        >
    with $FutureModifier<ClientBranding?>, $FutureProvider<ClientBranding?> {
  ClientBrandingProvider._({
    required ClientBrandingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clientBrandingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clientBrandingHash();

  @override
  String toString() {
    return r'clientBrandingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<ClientBranding?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ClientBranding?> create(Ref ref) {
    final argument = this.argument as String;
    return clientBranding(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientBrandingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clientBrandingHash() => r'8e42ee6815818af74340abd094bc82c95468cf1e';

final class ClientBrandingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<ClientBranding?>, String> {
  ClientBrandingFamily._()
    : super(
        retry: null,
        name: r'clientBrandingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ClientBrandingProvider call(String identifier) =>
      ClientBrandingProvider._(argument: identifier, from: this);

  @override
  String toString() => r'clientBrandingProvider';
}
