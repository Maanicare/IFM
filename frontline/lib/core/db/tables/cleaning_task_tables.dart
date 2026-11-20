import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Screen 21 - Cleaning Task (Section 20's Housekeeping workflow). A
/// scheduled soft-service job against one Space ("Area"), distinct from
/// a reactive Work Order - configured server-side (SOP, frequency,
/// expected duration) and executed by a Housekeeping Employee.
///
/// "Inspection points" (the spec's Fields list) and "Checklist" (the
/// spec's Completion list) are modelled as a single structure here,
/// not two: the predefined inspection points *are* what gets checked
/// off at completion. The spec names them separately but doesn't
/// describe two distinct data concepts, and this is the simplest
/// reading that doesn't invent a second parallel checklist system on
/// top of the one [Checklists] already provides for work orders.
///
/// "Consumables used" is a free-text note, not a real inventory
/// deduction - wiring this into [InventoryTransactions] would need
/// the same schema work already tracked as a Screen 33 gap in
/// PENDING_FEATURES.md (that table only supports the "issue" type
/// today, hard-FK'd to WorkOrders).
class CleaningTasks extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().references(Spaces, #id)(); // "Area"
  TextColumn get cleaningType => text()();
  TextColumn get sopNote => text().nullable()();
  TextColumn get frequency => text()(); // daily|weekly|monthly|...
  DateTimeColumn get lastCleanAt => dateTime().nullable()();
  IntColumn get expectedMinutes => integer().nullable()();
  TextColumn get assignedUserId => text().nullable()();
  TextColumn get materialsNote => text().nullable()();
  BoolColumn get photoRequired => boolean().withDefault(const Constant(false))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get scheduledDate => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  // Completion fields.
  TextColumn get consumablesNote => text().nullable()();
  TextColumn get exceptionNote => text().nullable()();

  BoolColumn get hasPendingLocalChanges =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Predefined inspection points for a cleaning task (read-only on the
/// device, configured server-side) - see the class doc on
/// [CleaningTasks] for why this doubles as the completion checklist.
class CleaningTaskInspectionPoints extends Table {
  TextColumn get id => text()();
  TextColumn get cleaningTaskId => text().references(CleaningTasks, #id)();
  IntColumn get sequence => integer()();
  TextColumn get description => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A technician's pass/fail (+ optional note) against one inspection
/// point, recorded at completion time.
class CleaningTaskInspectionResponses extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get cleaningTaskId => text().references(CleaningTasks, #id)();
  TextColumn get inspectionPointId =>
      text().references(CleaningTaskInspectionPoints, #id)();
  BoolColumn get passed => boolean()();
  TextColumn get note => text().nullable()();
  TextColumn get capturedBy => text()();
  DateTimeColumn get capturedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
