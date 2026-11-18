import 'package:drift/drift.dart';

/// Local read-only cache of the location hierarchy (Section 27 of the IFM
/// spec: Sites -> Buildings -> Floors -> Spaces). Frontline users only ever
/// browse this data; it is synced down from the server and never mutated
/// from the device, so these tables have no outbox entries of their own.
class Sites extends Table {
  TextColumn get id => text()();
  TextColumn get code => text()();
  TextColumn get name => text()();
  TextColumn get timezone => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get operationalStatus => text()();

  // Screen 02 (Role/Site Selector): "Portfolio; Region" grouping. Not
  // modelled as their own tables here - a Frontline user only ever
  // needs to group/filter by these labels, not manage them.
  TextColumn get region => text().nullable()();
  TextColumn get portfolioName => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Buildings extends Table {
  TextColumn get id => text()();
  TextColumn get siteId => text().references(Sites, #id)();
  TextColumn get name => text()();
  IntColumn get floors => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Floors extends Table {
  TextColumn get id => text()();
  TextColumn get buildingId => text().references(Buildings, #id)();
  TextColumn get name => text()();
  TextColumn get floorNumber => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Spaces extends Table {
  TextColumn get id => text()();
  TextColumn get floorId => text().references(Floors, #id)();
  TextColumn get spaceCode => text()();
  TextColumn get name => text()();
  TextColumn get spaceType => text()();
  TextColumn get criticality => text().withDefault(const Constant('normal'))();

  @override
  Set<Column> get primaryKey => {id};
}
