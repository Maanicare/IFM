// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_capture_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Captures a photo or signature to local storage and records it as an
/// [Attachments] row against whatever entity it belongs to (a work order,
/// a checklist item, an incident, ...). The actual upload-to-server step
/// is a separate concern (`AttachmentDao.pendingUploads` already exposes
/// what's queued) - this controller's job ends at "durably captured and
/// recorded locally" (Section 3.2: evidence before claims).

@ProviderFor(AttachmentCaptureController)
final attachmentCaptureControllerProvider =
    AttachmentCaptureControllerProvider._();

/// Captures a photo or signature to local storage and records it as an
/// [Attachments] row against whatever entity it belongs to (a work order,
/// a checklist item, an incident, ...). The actual upload-to-server step
/// is a separate concern (`AttachmentDao.pendingUploads` already exposes
/// what's queued) - this controller's job ends at "durably captured and
/// recorded locally" (Section 3.2: evidence before claims).
final class AttachmentCaptureControllerProvider
    extends $NotifierProvider<AttachmentCaptureController, void> {
  /// Captures a photo or signature to local storage and records it as an
  /// [Attachments] row against whatever entity it belongs to (a work order,
  /// a checklist item, an incident, ...). The actual upload-to-server step
  /// is a separate concern (`AttachmentDao.pendingUploads` already exposes
  /// what's queued) - this controller's job ends at "durably captured and
  /// recorded locally" (Section 3.2: evidence before claims).
  AttachmentCaptureControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attachmentCaptureControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attachmentCaptureControllerHash();

  @$internal
  @override
  AttachmentCaptureController create() => AttachmentCaptureController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$attachmentCaptureControllerHash() =>
    r'7185aa97b087f26b2b2d487e27de903e89efe887';

/// Captures a photo or signature to local storage and records it as an
/// [Attachments] row against whatever entity it belongs to (a work order,
/// a checklist item, an incident, ...). The actual upload-to-server step
/// is a separate concern (`AttachmentDao.pendingUploads` already exposes
/// what's queued) - this controller's job ends at "durably captured and
/// recorded locally" (Section 3.2: evidence before claims).

abstract class _$AttachmentCaptureController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
