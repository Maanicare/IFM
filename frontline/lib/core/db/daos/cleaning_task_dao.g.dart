// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cleaning_task_dao.dart';

// ignore_for_file: type=lint
mixin _$CleaningTaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $CleaningTasksTable get cleaningTasks => attachedDatabase.cleaningTasks;
  $CleaningTaskInspectionPointsTable get cleaningTaskInspectionPoints =>
      attachedDatabase.cleaningTaskInspectionPoints;
  $CleaningTaskInspectionResponsesTable get cleaningTaskInspectionResponses =>
      attachedDatabase.cleaningTaskInspectionResponses;
  CleaningTaskDaoManager get managers => CleaningTaskDaoManager(this);
}

class CleaningTaskDaoManager {
  final _$CleaningTaskDaoMixin _db;
  CleaningTaskDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$CleaningTasksTableTableManager get cleaningTasks =>
      $$CleaningTasksTableTableManager(_db.attachedDatabase, _db.cleaningTasks);
  $$CleaningTaskInspectionPointsTableTableManager
  get cleaningTaskInspectionPoints =>
      $$CleaningTaskInspectionPointsTableTableManager(
        _db.attachedDatabase,
        _db.cleaningTaskInspectionPoints,
      );
  $$CleaningTaskInspectionResponsesTableTableManager
  get cleaningTaskInspectionResponses =>
      $$CleaningTaskInspectionResponsesTableTableManager(
        _db.attachedDatabase,
        _db.cleaningTaskInspectionResponses,
      );
}
