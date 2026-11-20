import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Screen 23 - Soft Service Inspection. The spec's "Record" list is a
/// single overall Score plus a few plain fields, not a per-item
/// checklist (unlike Screen 21's "Checklist") - so this is one row per
/// inspection, not a template/items/responses structure like
/// [Checklists]. Corrective task/Owner/Due date are captured directly
/// on the row rather than creating a real trackable task entity - no
/// task-assignment/notification workflow exists for it, same
/// simplification as a Work Order's closure fields.
class SoftServiceInspections extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().nullable().references(Spaces, #id)();
  TextColumn get template =>
      text()(); // housekeeping|pantry|pest|horticulture|mailroom|concierge
  RealColumn get score => real()(); // 0-100
  TextColumn get nonConformanceNote => text().nullable()();
  TextColumn get correctiveTaskNote => text().nullable()();
  TextColumn get correctiveOwnerName => text().nullable()();
  DateTimeColumn get correctiveDueDate => dateTime().nullable()();
  // Still no task-assignment/notification workflow (see the class doc
  // above) - but Screen 34's "Corrective actions overdue" needs to
  // know when one's actually done, not just past its due date, so this
  // one completion flag exists without the rest of a task entity.
  BoolColumn get correctiveCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get inspectedBy => text()();
  DateTimeColumn get inspectedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
