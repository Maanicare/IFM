// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safety_dao.dart';

// ignore_for_file: type=lint
mixin _$SafetyDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $IncidentsTable get incidents => attachedDatabase.incidents;
  $HazardsTable get hazards => attachedDatabase.hazards;
  SafetyDaoManager get managers => SafetyDaoManager(this);
}

class SafetyDaoManager {
  final _$SafetyDaoMixin _db;
  SafetyDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$IncidentsTableTableManager get incidents =>
      $$IncidentsTableTableManager(_db.attachedDatabase, _db.incidents);
  $$HazardsTableTableManager get hazards =>
      $$HazardsTableTableManager(_db.attachedDatabase, _db.hazards);
}
