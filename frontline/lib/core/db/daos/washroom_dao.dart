import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/washroom_tables.dart';

part 'washroom_dao.g.dart';

@DriftAccessor(tables: [Washrooms])
class WashroomDao extends DatabaseAccessor<AppDatabase> with _$WashroomDaoMixin {
  WashroomDao(super.db);

  Stream<List<Washroom>> watchForSite(String siteId) {
    return (select(washrooms)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([(t) => OrderingTerm.asc(t.cleaningStatus)]))
        .watch();
  }

  Stream<Washroom?> watchById(String id) =>
      (select(washrooms)..where((t) => t.id.equals(id))).watchSingleOrNull();

  /// Screen 11 (Scan): resolves a scanned washroom QR.
  Future<Washroom?> byQrCode(String code) =>
      (select(washrooms)..where((t) => t.qrCode.equals(code))).getSingleOrNull();

  Future<void> upsertFromServer(WashroomsCompanion row) =>
      into(washrooms).insertOnConflictUpdate(row);
}
