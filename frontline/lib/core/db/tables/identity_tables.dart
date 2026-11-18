import 'package:drift/drift.dart';

/// Local cache of the current (and any recently-seen co-worker) user
/// records, used to resolve display names for assignments/handovers
/// without a network call, and to persist the logged-in identity + role
/// across app restarts.
class CachedUsers extends Table {
  TextColumn get id => text()();
  TextColumn get employeeId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get mobile => text().nullable()();
  TextColumn get designation => text().nullable()();
  TextColumn get roleType => text()(); // see UserRole enum
  TextColumn get organisationId => text()();
  TextColumn get siteScopeJson =>
      text().withDefault(const Constant('[]'))(); // list of assigned site ids
  RealColumn get approvalLimit => real().nullable()();
  BoolColumn get isCurrentUser =>
      boolean().withDefault(const Constant(false))();

  /// Which of the user's assigned sites is "active" right now (Screen 02:
  /// Role/Site Selector). Null until the technician has switched at least
  /// once; callers fall back to the first assigned site.
  TextColumn get currentSiteId => text().nullable()();

  /// Screen 02's second, distinct action: "Set default" - the site to
  /// land on at the *next* login, independent of whatever
  /// [currentSiteId] is mid-session. Kept as its own column rather than
  /// overloading [currentSiteId], so confirming a default doesn't
  /// silently change what the rest of the app is currently looking at.
  TextColumn get defaultSiteId => text().nullable()();

  /// Screen 02: "Recent site" - a JSON array of site ids, most recent
  /// first, capped at 3 by [IdentityDao.pushRecentSite]. Tracks sites
  /// switched *away from*, so it surfaces "where was I before this"
  /// rather than just restating the current site.
  TextColumn get recentSiteIdsJson =>
      text().withDefault(const Constant('[]'))();

  @override
  Set<Column> get primaryKey => {id};
}
