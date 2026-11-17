// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_dao.dart';

// ignore_for_file: type=lint
mixin _$IdentityDaoMixin on DatabaseAccessor<AppDatabase> {
  $CachedUsersTable get cachedUsers => attachedDatabase.cachedUsers;
  IdentityDaoManager get managers => IdentityDaoManager(this);
}

class IdentityDaoManager {
  final _$IdentityDaoMixin _db;
  IdentityDaoManager(this._db);
  $$CachedUsersTableTableManager get cachedUsers =>
      $$CachedUsersTableTableManager(_db.attachedDatabase, _db.cachedUsers);
}
