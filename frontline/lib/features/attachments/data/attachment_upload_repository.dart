/// Uploads a captured evidence file (photo/signature/voice/document) to
/// the server (Section 36). Capture-to-local-disk already happened by
/// the time this runs - this is purely the "push the bytes" half of the
/// pipeline, driven by [AttachmentDao.pendingUploads].
abstract interface class AttachmentUploadRepository {
  /// Returns the server-assigned URL for the uploaded file.
  Future<String> upload({
    required String localPath,
    required String entityType,
    required String entityId,
    required String fileType,
  });
}
