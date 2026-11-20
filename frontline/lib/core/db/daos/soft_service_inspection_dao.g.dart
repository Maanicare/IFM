// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soft_service_inspection_dao.dart';

// ignore_for_file: type=lint
mixin _$SoftServiceInspectionDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $SoftServiceInspectionsTable get softServiceInspections =>
      attachedDatabase.softServiceInspections;
  SoftServiceInspectionDaoManager get managers =>
      SoftServiceInspectionDaoManager(this);
}

class SoftServiceInspectionDaoManager {
  final _$SoftServiceInspectionDaoMixin _db;
  SoftServiceInspectionDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$SoftServiceInspectionsTableTableManager get softServiceInspections =>
      $$SoftServiceInspectionsTableTableManager(
        _db.attachedDatabase,
        _db.softServiceInspections,
      );
}
