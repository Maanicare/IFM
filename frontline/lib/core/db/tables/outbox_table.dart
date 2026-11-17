import 'package:drift/drift.dart';

/// Offline mutation queue.
///
/// Every state-changing action a technician performs while offline (status
/// change, checklist answer, meter reading, attachment metadata) is first
/// written to its own local table, then enqueued here as a durable,
/// ordered record of "what needs to be told to the server". This is what
/// makes offline execution safe: the UI never has to know whether the
/// device currently has connectivity.
///
/// Sequencing & conflict detection:
///   - [sequence] is a per-device monotonic counter (not wall-clock time,
///     which can skew/jump) so mutations are always replayed to the server
///     in the exact order they were made on this device, even across app
///     restarts.
///   - [baseServerVersion] records the entity's `serverVersion` *as the
///     device last knew it* at the moment the mutation was created. When
///     the sync engine pushes this entry, the server compares its current
///     version for that entity against [baseServerVersion]; a mismatch
///     means someone else changed the record first, and the push fails
///     with a conflict rather than silently clobbering their change.
class OutboxEntries extends Table {
  /// Per-device monotonic sequence number. Declared as the SQLite
  /// INTEGER PRIMARY KEY (an alias for `rowid`) so it is guaranteed to be
  /// strictly increasing in insertion order with no gaps-vs-wall-clock
  /// ambiguity, which is what ordered replay depends on.
  IntColumn get sequence => integer().autoIncrement()();
  TextColumn get id => text().unique()(); // client-generated UUID

  TextColumn get entityType =>
      text()(); // work_order|checklist_response|meter_reading|attachment|status_history
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // create|update|status_transition

  /// JSON-encoded payload of the mutation to replay against the server API.
  TextColumn get payloadJson => text()();

  /// The entity's server version this mutation was computed against, used
  /// for optimistic-concurrency conflict detection on push. Null for
  /// pure-create operations that have no prior server state.
  IntColumn get baseServerVersion => integer().nullable()();

  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending|syncing|synced|conflict|failed
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
}
