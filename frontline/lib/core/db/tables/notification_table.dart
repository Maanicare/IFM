import 'package:drift/drift.dart';

/// In-app notification feed (Section 52). Triggers such as assignment,
/// SLA warning/breach and vendor arrival are pushed down from the server
/// (or synthesised locally for offline-relevant events like "sync
/// conflict detected") and rendered as a simple feed with an unread
/// badge on the frontline bottom nav.
class AppNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get category =>
      text()(); // assignment|sla_warning|sla_breach|approval|sync_conflict|general
  TextColumn get relatedEntityType => text().nullable()();
  TextColumn get relatedEntityId => text().nullable()();
  BoolColumn get read => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
