import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Visits (Section 47, Screen 44). "Host" is a free-text name, same
/// reasoning as Request "Assign"/Hazard "Authorised persons" - no
/// employee directory to pick a specific host from. "ID rules" is
/// captured as what was actually checked (free text) plus a verified
/// flag, not a configurable rules engine. "Generate QR pass" encodes
/// this row's own `id` as the pass payload - resolvable back to this
/// visit by Scan or a dedicated lookup, not a separate access-control
/// system integration (no turnstile/badge-system integration exists
/// here).
class Visits extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get visitorName => text()();
  TextColumn get visitorMobile => text().nullable()();
  TextColumn get visitorEmail => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get hostName => text()();
  TextColumn get purpose => text().nullable()();
  TextColumn get vehicleNumber => text().nullable()();
  BoolColumn get idVerified => boolean().withDefault(const Constant(false))();
  TextColumn get idTypeNote => text().nullable()();
  TextColumn get accessRequirementsNote => text().nullable()();
  DateTimeColumn get scheduledArrival => dateTime().nullable()();
  DateTimeColumn get actualArrival => dateTime().nullable()();
  DateTimeColumn get actualDeparture => dateTime().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('expected'))(); // expected|checked_in|checked_out
  TextColumn get passId => text()();
  TextColumn get createdBy => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
