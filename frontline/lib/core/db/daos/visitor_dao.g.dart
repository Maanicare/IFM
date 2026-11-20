// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visitor_dao.dart';

// ignore_for_file: type=lint
mixin _$VisitorDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $VisitsTable get visits => attachedDatabase.visits;
  VisitorDaoManager get managers => VisitorDaoManager(this);
}

class VisitorDaoManager {
  final _$VisitorDaoMixin _db;
  VisitorDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$VisitsTableTableManager get visits =>
      $$VisitsTableTableManager(_db.attachedDatabase, _db.visits);
}
