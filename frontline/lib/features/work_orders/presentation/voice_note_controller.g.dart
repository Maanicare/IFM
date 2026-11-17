// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_note_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Persists the (technician-reviewed) structured fields from a voice
/// note (Section 16.12) - writes locally first, then outboxes the push,
/// same pattern as every other field mutation in this app.

@ProviderFor(VoiceNoteController)
final voiceNoteControllerProvider = VoiceNoteControllerProvider._();

/// Persists the (technician-reviewed) structured fields from a voice
/// note (Section 16.12) - writes locally first, then outboxes the push,
/// same pattern as every other field mutation in this app.
final class VoiceNoteControllerProvider
    extends $NotifierProvider<VoiceNoteController, void> {
  /// Persists the (technician-reviewed) structured fields from a voice
  /// note (Section 16.12) - writes locally first, then outboxes the push,
  /// same pattern as every other field mutation in this app.
  VoiceNoteControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voiceNoteControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voiceNoteControllerHash();

  @$internal
  @override
  VoiceNoteController create() => VoiceNoteController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$voiceNoteControllerHash() =>
    r'8c55f82d1eef6882dbb09cee54a4266ceb496ca8';

/// Persists the (technician-reviewed) structured fields from a voice
/// note (Section 16.12) - writes locally first, then outboxes the push,
/// same pattern as every other field mutation in this app.

abstract class _$VoiceNoteController extends $Notifier<void> {
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
