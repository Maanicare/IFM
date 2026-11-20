import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Service requests (Section 28) - the "Employee reports an issue" entry
/// point (Journey 1). Frontline users mostly consume these as the origin
/// of a work order, plus can create new requests on behalf of a client
/// employee encountered in the field.
class ServiceRequests extends Table {
  TextColumn get id => text()();
  TextColumn get requestNumber => text()();
  TextColumn get requesterId => text().nullable()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().nullable().references(Spaces, #id)();
  TextColumn get assetId => text().nullable()();
  TextColumn get categoryId => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get priority => text()(); // low|medium|high|critical
  TextColumn get status => text()();
  TextColumn get source => text()(); // mobile|web|qr|api|email|iot|ai
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get responseDueAt => dateTime().nullable()();
  DateTimeColumn get resolutionDueAt => dateTime().nullable()();
  DateTimeColumn get closedAt => dateTime().nullable()();

  // Screen 06 "Optional" fields.
  IntColumn get affectedPeopleCount => integer().nullable()();
  BoolColumn get safetyConcern => boolean().withDefault(const Constant(false))();

  // Screen 07 actions: Assign, Escalate, Change priority, Resolution
  // content. "Assign" targets a team/trade rather than an individual -
  // this app has no synced user directory to pick a person from.
  TextColumn get assignedTeam => text().nullable()();
  BoolColumn get escalated => boolean().withDefault(const Constant(false))();
  TextColumn get resolutionNote => text().nullable()();

  // Screen 07 "Merge duplicate": a single self-reference rather than a
  // separate many-to-many `duplicate_links` table - "merge" in the
  // spec's one-line description reads as one request pointing at the
  // canonical one it duplicates, not an arbitrary link graph.
  TextColumn get duplicateOfRequestId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Screen 07 "Comments" - a plain threaded log against a request. No
/// edit/delete: comments are an append-only record of what was
/// communicated, matching Section 51's "audit records shall not be
/// editable" principle applied to this lighter-weight entity.
class RequestComments extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get requestId => text().references(ServiceRequests, #id)();
  TextColumn get authorId => text()();
  TextColumn get authorName => text()();
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
