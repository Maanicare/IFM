import 'package:drift/drift.dart';

import 'asset_tables.dart';
import 'location_tables.dart';
import 'request_tables.dart';

/// Work orders (Section 29) - the central unit of frontline execution.
/// `serverVersion` and `localVersion` implement optimistic concurrency: a
/// mutation queued while offline carries the `serverVersion` it was based
/// on, and if the server's current version has since moved past that when
/// the mutation is finally pushed, the sync engine raises a
/// [SyncConflictError] instead of overwriting newer server state.
class WorkOrders extends Table {
  TextColumn get id => text()();
  TextColumn get woNumber => text()();
  TextColumn get requestId => text().nullable().references(ServiceRequests, #id)();
  TextColumn get type => text()(); // reactive|planned|inspection|project
  TextColumn get assetId => text().nullable().references(Assets, #id)();
  TextColumn get spaceId => text().references(Spaces, #id)();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get priority => text()();
  TextColumn get status => text()();
  TextColumn get assignedUserId => text().nullable()();
  TextColumn get vendorId => text().nullable()();
  DateTimeColumn get scheduledStart => dateTime().nullable()();
  DateTimeColumn get scheduledEnd => dateTime().nullable()();
  DateTimeColumn get actualStart => dateTime().nullable()();
  DateTimeColumn get actualEnd => dateTime().nullable()();
  IntColumn get estimatedMinutes => integer().nullable()();
  IntColumn get actualMinutes => integer().nullable()();
  TextColumn get problemDescription => text().nullable()();
  TextColumn get failureCode => text().nullable()();
  TextColumn get rootCauseCode => text().nullable()();
  TextColumn get resolutionCode => text().nullable()();
  BoolColumn get qaRequired => boolean().withDefault(const Constant(false))();
  TextColumn get qaStatus => text().nullable()();

  // Section E (Closure): "Remaining issue" and "Follow-up" - Root cause
  // and Work performed reuse rootCauseCode/resolutionCode above (both
  // free text here, despite the "Code" name - no fixed code list exists
  // for either yet).
  TextColumn get remainingIssueNote => text().nullable()();
  TextColumn get followUpNote => text().nullable()();
  TextColumn get blockerReason => text().nullable()(); // see WorkOrderBlocker
  TextColumn get checklistId => text().nullable()();

  // Voice-to-Workflow (Section 16.12): structured fields parsed from a
  // technician's spoken note, so field reporting doesn't require typing.
  TextColumn get voiceFindingNote => text().nullable()();
  TextColumn get voiceReadingNote => text().nullable()();
  TextColumn get voiceDiagnosisNote => text().nullable()();
  TextColumn get voiceRecommendationNote => text().nullable()();

  /// SLA fields surfaced directly on the work order for fast list rendering
  /// without a join - recomputed locally from [SlaInstances] on sync.
  DateTimeColumn get slaResponseTarget => dateTime().nullable()();
  DateTimeColumn get slaResolutionTarget => dateTime().nullable()();
  IntColumn get slaPauseSeconds => integer().withDefault(const Constant(0))();

  /// Optimistic-concurrency / conflict-detection fields.
  IntColumn get serverVersion => integer().withDefault(const Constant(0))();
  BoolColumn get hasPendingLocalChanges =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Mandatory audit trail (Section 30) for SLA calculation: every status
/// transition is timestamped and reasoned, and is itself written through
/// the outbox so it survives offline execution.
class WorkOrderStatusHistory extends Table {
  TextColumn get id => text()();
  TextColumn get workOrderId => text().references(WorkOrders, #id)();
  TextColumn get fromStatus => text().nullable()();
  TextColumn get toStatus => text()();
  TextColumn get changedBy => text()();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get timestamp => dateTime()();

  // Captured specifically on check-in (Section 11: "Checks in via GPS
  // where appropriate, QR, NFC, or manual override with reason").
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get locationSource => text().nullable()(); // gps|manual_override

  @override
  Set<Column> get primaryKey => {id};
}
