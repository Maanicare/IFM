import 'dart:convert';

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

  /// Screen 02: "Set default" - independent of [setCurrentSite].
  Future<void> setDefaultSite(String userId, String siteId) {
    return (update(cachedUsers)..where((t) => t.id.equals(userId))).write(
      CachedUsersCompanion(defaultSiteId: Value(siteId)),
    );
  }

  /// Records a site as "recent" (Screen 02: "Recent site") - called
  /// with whatever site is being switched *away from*, so the list
  /// surfaces "where was I before this" rather than the current site
  /// restating itself. Deduplicates and caps at 3.
  Future<void> pushRecentSite(String userId, String siteId) async {
    final user = await byId(userId);
    if (user == null) return;
    final existing = (jsonDecode(user.recentSiteIdsJson) as List).cast<String>();
    final updated = [siteId, ...existing.where((id) => id != siteId)].take(3).toList();
    await (update(cachedUsers)..where((t) => t.id.equals(userId))).write(
      CachedUsersCompanion(recentSiteIdsJson: Value(jsonEncode(updated))),
    );
  }
}
