import 'package:drift/drift.dart';

import 'work_order_tables.dart';

/// Pre-work safety gate (Section 11: "System asks relevant safety
/// questions" before the technician starts the work timer). Kept
/// separate from the checklist model (Section 35) - this always applies
/// regardless of whether the work order carries a checklist, and is
/// about immediate go/no-go safety, not task evidence.
class SafetyGateResponses extends Table {
  TextColumn get id => text()();
  TextColumn get workOrderId => text().references(WorkOrders, #id)();
  TextColumn get question => text()();
  BoolColumn get answer => boolean()();
  TextColumn get confirmedBy => text()();
  DateTimeColumn get confirmedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
