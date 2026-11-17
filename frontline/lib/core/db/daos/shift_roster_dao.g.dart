// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_roster_dao.dart';

// ignore_for_file: type=lint
mixin _$ShiftRosterDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $ShiftRosterEntriesTable get shiftRosterEntries =>
      attachedDatabase.shiftRosterEntries;
  ShiftRosterDaoManager get managers => ShiftRosterDaoManager(this);
}

class ShiftRosterDaoManager {
  final _$ShiftRosterDaoMixin _db;
  ShiftRosterDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$ShiftRosterEntriesTableTableManager get shiftRosterEntries =>
      $$ShiftRosterEntriesTableTableManager(
        _db.attachedDatabase,
        _db.shiftRosterEntries,
      );
}
