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

  /// This user's own shift entry for today (Screen 03: "Current
  /// shift") - a scoped-down version of [watchForSite], which lists
  /// everyone's shift rather than just the logged-in technician's own.
  Stream<ShiftRosterEntry?> watchMyShiftToday(String siteId, String userId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(shiftRosterEntries)
          ..where((t) =>
              t.siteId.equals(siteId) &
              t.userId.equals(userId) &
              t.shiftStart.isBiggerOrEqualValue(start) &
              t.shiftStart.isSmallerThanValue(end))
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> setAttendanceStatus(String id, String status) {
    return (update(shiftRosterEntries)..where((t) => t.id.equals(id))).write(
      ShiftRosterEntriesCompanion(attendanceStatus: Value(status)),
    );
  }

  Future<ShiftRosterEntry?> byId(String id) =>
      (select(shiftRosterEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Screen 25 action: "Swap" - the two entries trade shift times.
  /// Identity (who's on the roster) stays put; only when each works
  /// changes. There's no synced employee directory to pick a swap
  /// partner from outside today's roster, so the candidate pool is
  /// "everyone else scheduled at this site today" (see
  /// [candidatesForSwap]).
  Future<void> swapShifts(String entryIdA, String entryIdB) async {
    final a = await byId(entryIdA);
    final b = await byId(entryIdB);
    if (a == null || b == null) return;
    await transaction(() async {
      await (update(shiftRosterEntries)..where((t) => t.id.equals(entryIdA))).write(
        ShiftRosterEntriesCompanion(shiftStart: Value(b.shiftStart), shiftEnd: Value(b.shiftEnd)),
      );
      await (update(shiftRosterEntries)..where((t) => t.id.equals(entryIdB))).write(
        ShiftRosterEntriesCompanion(shiftStart: Value(a.shiftStart), shiftEnd: Value(a.shiftEnd)),
      );
    });
  }

  /// Screen 25 action: "Swap" candidates - other roster entries at the
  /// same site today, excluding the requesting one.
  Future<List<ShiftRosterEntry>> candidatesForSwap(String siteId, String excludingId, DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return (select(shiftRosterEntries)
          ..where((t) =>
              t.siteId.equals(siteId) &
              t.id.equals(excludingId).not() &
              t.shiftStart.isBiggerOrEqualValue(start) &
              t.shiftStart.isSmallerThanValue(end)))
        .get();
  }

  /// Screen 25 action: "Replace" - recorded as a plain name, not a link
  /// to another [CachedUsers] row, since no synced employee directory
  /// exists to pick a specific person from outside today's roster.
  Future<void> setReplacement(String id, String? replacementName) {
    return (update(shiftRosterEntries)..where((t) => t.id.equals(id))).write(
      ShiftRosterEntriesCompanion(replacementUserName: Value(replacementName)),
    );
  }
}
