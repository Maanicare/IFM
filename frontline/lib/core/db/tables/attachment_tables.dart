import 'package:drift/drift.dart';

/// Attachment queue (Section 36). Photos, voice notes and signatures are
/// written to local file storage immediately so capture never blocks on
/// network, then queued here for background upload. `uploadStatus` lets the
/// UI show per-photo upload progress without re-deriving it from the
/// generic outbox queue, which deals in whole-entity mutations rather than
/// individual files.
class Attachments extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get entityType => text()(); // work_order|checklist_item|incident
  TextColumn get entityId => text()();
  TextColumn get fileType => text()(); // photo|voice|signature|document
  TextColumn get localPath => text()();
  TextColumn get remoteUrl => text().nullable()();
  TextColumn get caption => text().nullable()();
  TextColumn get uploadStatus =>
      text().withDefault(const Constant('pending'))(); // pending|uploading|uploaded|failed
  IntColumn get uploadAttempts => integer().withDefault(const Constant(0))();
  TextColumn get uploadedBy => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
