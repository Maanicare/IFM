import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/shift_handover_tables.dart';

part 'shift_handover_dao.g.dart';

@DriftAccessor(tables: [ShiftHandovers])
class ShiftHandoverDao extends DatabaseAccessor<AppDatabase>
    with _$ShiftHandoverDaoMixin {
  ShiftHandoverDao(super.db);

  Future<void> insertLocal(ShiftHandoversCompanion row) =>
      into(shiftHandovers).insert(row);

  Future<void> upsertFromServer(ShiftHandoversCompanion row) =>
      into(shiftHandovers).insertOnConflictUpdate(row);

  /// The most recent handover for a site - what an incoming shift sees
  /// (Screen 26: "Incoming Team: Must acknowledge handover").
  Stream<ShiftHandover?> watchLatestForSite(String siteId) {
    return (select(shiftHandovers)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<ShiftHandover?> byId(String id) =>
      (select(shiftHandovers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> acknowledgeLocally({
    required String id,
    required String acknowledgedBy,
    required DateTime acknowledgedAt,
  }) {
    return (update(shiftHandovers)..where((t) => t.id.equals(id))).write(
      ShiftHandoversCompanion(
        acknowledgedBy: Value(acknowledgedBy),
        acknowledgedAt: Value(acknowledgedAt),
      ),
    );
  }
}
