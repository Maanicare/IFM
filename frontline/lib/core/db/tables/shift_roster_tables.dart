import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Shift Roster (Screen 25). Read-mostly cache of who is scheduled where -
/// the frontline app's own role in this is self-service (mark myself
/// absent, request relief), not full roster authoring, which stays a
/// manager/desktop concern.
class ShiftRosterEntries extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get userId => text()();
  TextColumn get userName => text()(); // denormalised for display without a join
  TextColumn get role => text()();
  DateTimeColumn get shiftStart => dateTime()();
  DateTimeColumn get shiftEnd => dateTime()();
  TextColumn get attendanceStatus =>
      text().withDefault(const Constant('scheduled'))(); // scheduled|present|absent|relief_requested
  TextColumn get skill => text().nullable()();
  TextColumn get replacementUserName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
