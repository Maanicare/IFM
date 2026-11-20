// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comfort_feedback_dao.dart';

// ignore_for_file: type=lint
mixin _$ComfortFeedbackDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $BuildingsTable get buildings => attachedDatabase.buildings;
  $FloorsTable get floors => attachedDatabase.floors;
  $SpacesTable get spaces => attachedDatabase.spaces;
  $ComfortFeedbackEntriesTable get comfortFeedbackEntries =>
      attachedDatabase.comfortFeedbackEntries;
  ComfortFeedbackDaoManager get managers => ComfortFeedbackDaoManager(this);
}

class ComfortFeedbackDaoManager {
  final _$ComfortFeedbackDaoMixin _db;
  ComfortFeedbackDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$BuildingsTableTableManager get buildings =>
      $$BuildingsTableTableManager(_db.attachedDatabase, _db.buildings);
  $$FloorsTableTableManager get floors =>
      $$FloorsTableTableManager(_db.attachedDatabase, _db.floors);
  $$SpacesTableTableManager get spaces =>
      $$SpacesTableTableManager(_db.attachedDatabase, _db.spaces);
  $$ComfortFeedbackEntriesTableTableManager get comfortFeedbackEntries =>
      $$ComfortFeedbackEntriesTableTableManager(
        _db.attachedDatabase,
        _db.comfortFeedbackEntries,
      );
}
