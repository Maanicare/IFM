import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Shift Handover (Screen 26; Section 16.14 "Digital Shift Memory").
/// Converts informal end-of-shift memory into an auditable record: the
/// outgoing team's open items, and an explicit acknowledgement from
/// whoever picks up the next shift - rather than a verbal handover that
/// leaves no trace if something was missed.
class ShiftHandovers extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();

  // Outgoing Team Records (Screen 26). Kept as free-text fields rather
  // than a rigid structure - a shift handover is inherently a narrative
  // briefing, not a form with enforceable business rules.
  TextColumn get openJobsNote => text().nullable()();
  TextColumn get equipmentIssueNote => text().nullable()();
  TextColumn get temporaryFixNote => text().nullable()();
  TextColumn get vendorExpectedNote => text().nullable()();
  TextColumn get safetyConcernNote => text().nullable()();
  TextColumn get clientCommitmentNote => text().nullable()();
  TextColumn get materialShortageNote => text().nullable()();
  TextColumn get specialInstructionNote => text().nullable()();

  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();

  // Incoming Team: Must acknowledge handover (Screen 26).
  TextColumn get acknowledgedBy => text().nullable()();
  DateTimeColumn get acknowledgedAt => dateTime().nullable()();

  IntColumn get serverVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
