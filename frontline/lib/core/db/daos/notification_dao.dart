import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/notification_table.dart';

part 'notification_dao.g.dart';

@DriftAccessor(tables: [AppNotifications])
class NotificationDao extends DatabaseAccessor<AppDatabase>
    with _$NotificationDaoMixin {
  NotificationDao(super.db);

  Stream<List<AppNotification>> watchAll() {
    return (select(appNotifications)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Unread notifications of one category - backs the Home screen's
  /// "Safety alerts" row (Section 8: Technician Home) without a second
  /// notification model just for safety.
  Stream<List<AppNotification>> watchUnreadByCategory(String category) {
    return (select(appNotifications)
          ..where((t) => t.category.equals(category) & t.read.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<int> watchUnreadCount() {
    final countExp = appNotifications.id.count();
    final query = selectOnly(appNotifications)
      ..addColumns([countExp])
      ..where(appNotifications.read.equals(false));
    return query.map((row) => row.read(countExp) ?? 0).watchSingle();
  }

  Future<void> add(AppNotificationsCompanion row) =>
      into(appNotifications).insertOnConflictUpdate(row);

  Future<void> markRead(String id) => (update(appNotifications)
        ..where((t) => t.id.equals(id)))
      .write(const AppNotificationsCompanion(read: Value(true)));

  Future<void> markAllRead() => (update(appNotifications))
      .write(const AppNotificationsCompanion(read: Value(true)));
}
