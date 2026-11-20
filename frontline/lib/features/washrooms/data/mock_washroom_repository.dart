import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'washroom_repository.dart';

class MockWashroomRepository implements WashroomRepository {
  MockWashroomRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncForSite(String siteId) async {
    final list = await FixtureLoader.loadJson('assets/fixtures/washrooms.json') as List;

    await _db.transaction(() async {
      for (final w in list.cast<Map<String, dynamic>>()) {
        if (w['siteId'] != siteId) continue;
        await _db.washroomDao.upsertFromServer(WashroomsCompanion.insert(
          id: w['id'] as String,
          siteId: w['siteId'] as String,
          spaceId: w['spaceId'] as String,
          qrCode: w['qrCode'] as String,
          cleaningStatus: Value(w['cleaningStatus'] as String? ?? 'clean'),
          lastAttendedAt: Value(FixtureLoader.resolveOffset(w, 'lastAttended')),
          nextDueAt: Value(FixtureLoader.resolveOffset(w, 'nextDue')),
          tissueStatus: Value(w['tissueStatus'] as String? ?? 'ok'),
          soapStatus: Value(w['soapStatus'] as String? ?? 'ok'),
          sensorAlertNote: Value(w['sensorAlertNote'] as String?),
          updatedAt: DateTime.now(),
        ));
      }
    });
  }
}
