import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Screen 22 - Washroom Experience. One row per washroom (a Space with
/// `spaceType == 'washroom'`), carrying the status fields the spec
/// lists for the Display section. "Complaints" isn't a field stored
/// here - it's computed from open [ServiceRequests] at the washroom's
/// space, since the spec's "QR Options" (Cleaning/Tissue/Soap/Odour/
/// Plumbing/Other) are exactly a quick-pick category for the existing
/// Create Request flow, not a separate reporting system worth
/// inventing in parallel. Server-configured/read-only on this device,
/// same as Work Order planned parts/tools.
class Washrooms extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().references(Spaces, #id)();
  TextColumn get qrCode => text()();
  TextColumn get cleaningStatus =>
      text().withDefault(const Constant('clean'))(); // clean|needs_attention|overdue
  DateTimeColumn get lastAttendedAt => dateTime().nullable()();
  DateTimeColumn get nextDueAt => dateTime().nullable()();
  TextColumn get tissueStatus => text().withDefault(const Constant('ok'))(); // ok|low|out
  TextColumn get soapStatus => text().withDefault(const Constant('ok'))(); // ok|low|out
  // "Sensor alerts where available" - this app has no IoT/sensor
  // integration (Section 49's `sensors`/`sensor_readings` are a
  // Web/BMS concern), so this is just whatever note the server
  // chooses to surface, if anything.
  TextColumn get sensorAlertNote => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
