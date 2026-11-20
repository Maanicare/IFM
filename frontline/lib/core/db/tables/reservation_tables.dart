import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Reservations (Section 46, Screen 43). "Invite" and "Order services"
/// are free-text notes captured at booking time, not a real
/// invite/notification system or a service-catalogue order - no
/// employee directory or service catalogue exists in this app to back
/// either one for real. "Temperature/IAQ if available" isn't modelled
/// at all - this app has no sensor/IoT integration (same conclusion as
/// Washroom's sensor alerts and Vehicle's battery/tyre notes).
class Reservations extends Table {
  TextColumn get id => text()();
  TextColumn get spaceId => text().references(Spaces, #id)();
  TextColumn get organiserId => text()();
  TextColumn get organiserName => text()();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();
  IntColumn get attendeeCount => integer().nullable()();
  TextColumn get purpose => text().nullable()();
  TextColumn get inviteesNote => text().nullable()();
  TextColumn get servicesNote => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('confirmed'))(); // confirmed|cancelled
  BoolColumn get checkedIn => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
