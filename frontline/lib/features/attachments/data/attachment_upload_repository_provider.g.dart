// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_upload_repository_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(attachmentUploadRepository)
final attachmentUploadRepositoryProvider =
    AttachmentUploadRepositoryProvider._();

final class AttachmentUploadRepositoryProvider
    extends
        $FunctionalProvider<
          AttachmentUploadRepository,
          AttachmentUploadRepository,
          AttachmentUploadRepository
        >
    with $Provider<AttachmentUploadRepository> {
  AttachmentUploadRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentUploadRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentUploadRepositoryHash();

  @$internal
  @override
  $ProviderElement<AttachmentUploadRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AttachmentUploadRepository create(Ref ref) {
    return attachmentUploadRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AttachmentUploadRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AttachmentUploadRepository>(value),
    );
  }
}

String _$attachmentUploadRepositoryHash() =>
    r'be7e7aff9f03dc7aedea221f6a25fc47ebfbfe80';
