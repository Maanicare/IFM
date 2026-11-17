import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'shift_roster_repository.dart';

class MockShiftRosterRepository implements ShiftRosterRepository {
  MockShiftRosterRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncForSite(String siteId) async {
    final list = await FixtureLoader.loadJson('assets/fixtures/shift_roster.json') as List;

    await _db.transaction(() async {
      for (final r in list.cast<Map<String, dynamic>>()) {
        if (r['siteId'] != siteId) continue;
        await _db.shiftRosterDao.upsertFromServer(ShiftRosterEntriesCompanion.insert(
          id: r['id'] as String,
          siteId: r['siteId'] as String,
          userId: r['userId'] as String,
          userName: r['userName'] as String,
          role: r['role'] as String,
          skill: Value(r['skill'] as String?),
          shiftStart: FixtureLoader.resolveOffset(r, 'shiftStart') ?? DateTime.now(),
          shiftEnd: FixtureLoader.resolveOffset(r, 'shiftEnd') ?? DateTime.now(),
          attendanceStatus: Value(r['attendanceStatus'] as String? ?? 'scheduled'),
        ));
      }
    });
  }

  @override
  Future<void> pushAttendanceChange({
    required String rosterEntryId,
    required String status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
