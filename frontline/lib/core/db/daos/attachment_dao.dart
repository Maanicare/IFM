import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/attachment_tables.dart';

part 'attachment_dao.g.dart';

@DriftAccessor(tables: [Attachments])
class AttachmentDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentDaoMixin {
  AttachmentDao(super.db);

  Future<void> add(AttachmentsCompanion row) =>
      into(attachments).insert(row);

  Stream<List<Attachment>> watchFor(String entityType, String entityId) {
    return (select(attachments)
          ..where((t) =>
              t.entityType.equals(entityType) & t.entityId.equals(entityId)))
        .watch();
  }

  Future<List<Attachment>> pendingUploads() {
    return (select(attachments)
          ..where((t) => t.uploadStatus.isIn(const ['pending', 'failed'])))
        .get();
  }

  Future<void> markStatus(String id, String status) {
    return (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(uploadStatus: Value(status)),
    );
  }

  Future<void> setRemoteUrl(String id, String url) {
    return (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        remoteUrl: Value(url),
        uploadStatus: const Value('uploaded'),
      ),
    );
  }

  /// Marks an upload attempt failed and bumps the retry counter - mirrors
  /// [OutboxDao.incrementAttempts]'s pattern so a stuck upload doesn't
  /// retry forever without the technician ever seeing it's struggling.
  Future<void> markFailed(String id, int previousAttempts) {
    return (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        uploadStatus: const Value('failed'),
        uploadAttempts: Value(previousAttempts + 1),
      ),
    );
  }
}
