import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/outbox_table.dart';

part 'outbox_dao.g.dart';

/// Access to the offline sync queue. The sync engine is the only consumer
/// that reads entries for push; everything else just enqueues.
@DriftAccessor(tables: [OutboxEntries])
class OutboxDao extends DatabaseAccessor<AppDatabase> with _$OutboxDaoMixin {
  OutboxDao(super.db);

  /// Enqueues one mutation. Called from repository methods immediately
  /// after writing the corresponding local table row, inside the same
  /// transaction, so the local write and its outbox entry can never
  /// diverge (e.g. app killed between the two).
  Future<void> enqueue({
    required String id,
    required String entityType,
    required String entityId,
    required String operation,
    required String payloadJson,
    int? baseServerVersion,
    required String createdBy,
  }) {
    return into(outboxEntries).insert(
      OutboxEntriesCompanion.insert(
        id: id,
        entityType: entityType,
        entityId: entityId,
        operation: operation,
        payloadJson: payloadJson,
        baseServerVersion: Value(baseServerVersion),
        createdBy: createdBy,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Pending entries in strict creation order (by monotonic [sequence]),
  /// which is the order the sync engine must replay them in.
  Future<List<OutboxEntry>> pendingInOrder() {
    return (select(outboxEntries)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .get();
  }

  Stream<int> watchPendingCount() {
    final countExp = outboxEntries.id.count();
    final query = selectOnly(outboxEntries)
      ..addColumns([countExp])
      ..where(outboxEntries.status.equals('pending'));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  Future<void> markSyncing(String id) =>
      _updateStatus(id, status: 'syncing');

  /// Reverts an in-flight entry back to `pending` without counting it as
  /// a failed attempt - used when a push failed purely because the device
  /// went offline mid-sync, which isn't the mutation's fault.
  Future<void> resetToPending(String id) =>
      _updateStatus(id, status: 'pending');

  Future<void> markSynced(String id) =>
      _updateStatus(id, status: 'synced');

  Future<void> markFailed(String id, String error) => (update(outboxEntries)
        ..where((t) => t.id.equals(id)))
      .write(OutboxEntriesCompanion(
        status: const Value('failed'),
        lastError: Value(error),
        lastAttemptAt: Value(DateTime.now()),
        attempts: const Value.absent(),
      ));

  Future<void> markConflict(String id, String error) =>
      (update(outboxEntries)..where((t) => t.id.equals(id))).write(
        OutboxEntriesCompanion(
          status: const Value('conflict'),
          lastError: Value(error),
          lastAttemptAt: Value(DateTime.now()),
        ),
      );

  Future<void> incrementAttempts(String id) async {
    final entry = await (select(outboxEntries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (entry == null) return;
    await (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      OutboxEntriesCompanion(
        attempts: Value(entry.attempts + 1),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _updateStatus(String id, {required String status}) {
    return (update(outboxEntries)..where((t) => t.id.equals(id))).write(
      OutboxEntriesCompanion(
        status: Value(status),
        lastAttemptAt: Value(DateTime.now()),
      ),
    );
  }

  /// Unresolved conflicts that need a human decision (shown on a dedicated
  /// "Sync Issues" screen rather than being retried automatically).
  Future<List<OutboxEntry>> conflicts() {
    return (select(outboxEntries)..where((t) => t.status.equals('conflict')))
        .get();
  }
}
