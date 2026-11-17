// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_handover_dao.dart';

// ignore_for_file: type=lint
mixin _$ShiftHandoverDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $ShiftHandoversTable get shiftHandovers => attachedDatabase.shiftHandovers;
  ShiftHandoverDaoManager get managers => ShiftHandoverDaoManager(this);
}

class ShiftHandoverDaoManager {
  final _$ShiftHandoverDaoMixin _db;
  ShiftHandoverDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$ShiftHandoversTableTableManager get shiftHandovers =>
      $$ShiftHandoversTableTableManager(
        _db.attachedDatabase,
        _db.shiftHandovers,
      );
}
