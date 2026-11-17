import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/shift_roster_tables.dart';

part 'shift_roster_dao.g.dart';

@DriftAccessor(tables: [ShiftRosterEntries])
class ShiftRosterDao extends DatabaseAccessor<AppDatabase>
    with _$ShiftRosterDaoMixin {
  ShiftRosterDao(super.db);

  Future<void> upsertFromServer(ShiftRosterEntriesCompanion row) =>
      into(shiftRosterEntries).insertOnConflictUpdate(row);

  /// Today's roster for a site, earliest shift first (Screen 25).
  Stream<List<ShiftRosterEntry>> watchForSite(String siteId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(shiftRosterEntries)
          ..where((t) =>
              t.siteId.equals(siteId) &
              t.shiftStart.isBiggerOrEqualValue(start) &
              t.shiftStart.isSmallerThanValue(end))
          ..orderBy([(t) => OrderingTerm.asc(t.shiftStart)]))
        .watch();
  }

  Future<void> setAttendanceStatus(String id, String status) {
    return (update(shiftRosterEntries)..where((t) => t.id.equals(id))).write(
      ShiftRosterEntriesCompanion(attendanceStatus: Value(status)),
    );
  }
}
