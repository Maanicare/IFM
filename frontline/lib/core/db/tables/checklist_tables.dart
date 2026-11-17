import 'package:drift/drift.dart';

import 'work_order_tables.dart';

/// Checklist templates (Section 35) attached to a work order's job plan.
/// Templates themselves are read-only reference data synced from the
/// server; only [ChecklistResponses] are mutated on-device.
class Checklists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get version => integer()();
  TextColumn get category => text()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistItems extends Table {
  TextColumn get id => text()();
  TextColumn get checklistId => text().references(Checklists, #id)();
  IntColumn get sequence => integer()();
  TextColumn get question => text()();
  TextColumn get inputType =>
      text()(); // boolean|number|text|photo|signature|choice
  BoolColumn get required => boolean().withDefault(const Constant(true))();
  RealColumn get minValue => real().nullable()();
  RealColumn get maxValue => real().nullable()();
  TextColumn get failureAction => text().nullable()(); // e.g. block_close

  @override
  Set<Column> get primaryKey => {id};
}

/// Technician-entered answers. `response` is stored as a JSON-encoded
/// string to accommodate the heterogeneous input types (boolean, number,
/// text, photo reference, signature reference) without a column per type.
class ChecklistResponses extends Table {
  TextColumn get id => text()(); // client-generated UUID
  TextColumn get workOrderId => text().references(WorkOrders, #id)();
  TextColumn get itemId => text().references(ChecklistItems, #id)();
  TextColumn get responseJson => text()();
  TextColumn get capturedBy => text()();
  DateTimeColumn get capturedAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
