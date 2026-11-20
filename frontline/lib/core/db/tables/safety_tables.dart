import 'package:drift/drift.dart';

import 'location_tables.dart';

/// Incidents (Section 41, Screen 35). The field-reportable subset of the
/// spec's incident model - investigation workflow / root-cause closure
/// is a manager/desktop concern, this app only needs to capture what a
/// Security Supervisor (or anyone else) witnesses on the ground.
class Incidents extends Table {
  TextColumn get id => text()();
  TextColumn get incidentNumber => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().nullable().references(Spaces, #id)();
  TextColumn get type => text()();
  TextColumn get severity => text()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get reportedBy => text()();
  TextColumn get description => text()();
  TextColumn get assetId => text().nullable()();
  BoolColumn get injury => boolean().withDefault(const Constant(false))();
  TextColumn get immediateAction => text().nullable()();
  // Free-text names, not links to CachedUsers rows - this app has no
  // synced employee directory to pick specific people from (same
  // reasoning as Request "Assign" and Shift Roster "Replace").
  TextColumn get peopleInvolved => text().nullable()();
  TextColumn get witnesses => text().nullable()();
  TextColumn get investigationStatus =>
      text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Hazards / Near Misses (Section 42, Screen 36) - deliberately a
/// separate, lighter entity from Incidents: a hazard hasn't caused harm
/// yet, so it only needs a risk score and an owner/target date, not an
/// investigation workflow.
class Hazards extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get spaceId => text().nullable().references(Spaces, #id)();
  TextColumn get category => text()();
  TextColumn get description => text()();
  IntColumn get riskProbability => integer()(); // 1-5
  IntColumn get riskConsequence => integer()(); // 1-5
  IntColumn get riskScore => integer()(); // probability x consequence
  TextColumn get reportedBy => text()();
  TextColumn get status => text().withDefault(const Constant('open'))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
