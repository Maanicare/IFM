import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/identity_tables.dart';

part 'identity_dao.g.dart';

@DriftAccessor(tables: [CachedUsers])
class IdentityDao extends DatabaseAccessor<AppDatabase>
    with _$IdentityDaoMixin {
  IdentityDao(super.db);

  Future<CachedUser?> currentUser() => (select(cachedUsers)
        ..where((t) => t.isCurrentUser.equals(true)))
      .getSingleOrNull();

  Stream<CachedUser?> watchCurrentUser() => (select(cachedUsers)
        ..where((t) => t.isCurrentUser.equals(true)))
      .watchSingleOrNull();

  Future<void> setCurrentUser(CachedUsersCompanion user) async {
    await transaction(() async {
      await (update(cachedUsers)).write(
        const CachedUsersCompanion(isCurrentUser: Value(false)),
      );
      await into(cachedUsers).insertOnConflictUpdate(user);
    });
  }

  Future<void> clearCurrentUser() =>
      (update(cachedUsers)).write(
        const CachedUsersCompanion(isCurrentUser: Value(false)),
      );

  Future<CachedUser?> byId(String id) =>
      (select(cachedUsers)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Switches the active site for [userId] (Screen 02: "Switch site").
  Future<void> setCurrentSite(String userId, String siteId) {
    return (update(cachedUsers)..where((t) => t.id.equals(userId))).write(
      CachedUsersCompanion(currentSiteId: Value(siteId)),
    );
  }
}
