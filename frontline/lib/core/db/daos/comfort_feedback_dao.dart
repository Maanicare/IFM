import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/comfort_feedback_tables.dart';

part 'comfort_feedback_dao.g.dart';

@DriftAccessor(tables: [ComfortFeedbackEntries])
class ComfortFeedbackDao extends DatabaseAccessor<AppDatabase>
    with _$ComfortFeedbackDaoMixin {
  ComfortFeedbackDao(super.db);

  Stream<List<ComfortFeedbackEntry>> watchForSite(String siteId) {
    return (select(comfortFeedbackEntries)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<ComfortFeedbackEntry?> byId(String id) =>
      (select(comfortFeedbackEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insert(ComfortFeedbackEntriesCompanion row) =>
      into(comfortFeedbackEntries).insert(row);
}
