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

  @override
  Set<Column> get primaryKey => {id};
}
