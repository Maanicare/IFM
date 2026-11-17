import '../../../core/util/id_generator.dart';
import 'attachment_upload_repository.dart';

class MockAttachmentUploadRepository implements AttachmentUploadRepository {
  @override
  Future<String> upload({
    required String localPath,
    required String entityType,
    required String entityId,
    required String fileType,
  }) async {
    // Mock mode has no backend to receive the bytes - simulate latency
    // and hand back a plausible-looking remote URL so the "uploaded"
    // state and local path keep behaving the same as the real thing.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return 'https://storage.onemaanicare.example.com/$entityType/$entityId/${IdGenerator.newId()}-$fileType';
  }
}
