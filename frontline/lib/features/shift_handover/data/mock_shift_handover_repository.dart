import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/fixtures/fixture_loader.dart';
import 'shift_handover_repository.dart';

class MockShiftHandoverRepository implements ShiftHandoverRepository {
  MockShiftHandoverRepository(this._db);

  final AppDatabase _db;

  @override
  Future<void> syncLatestForSite(String siteId) async {
    final list = await FixtureLoader.loadJson(
      'assets/fixtures/shift_handovers.json',
    ) as List;

    await _db.transaction(() async {
      for (final h in list.cast<Map<String, dynamic>>()) {
        if (h['siteId'] != siteId) continue;
        await _db.shiftHandoverDao.upsertFromServer(ShiftHandoversCompanion.insert(
          id: h['id'] as String,
          siteId: h['siteId'] as String,
          openJobsNote: Value(h['openJobsNote'] as String?),
          equipmentIssueNote: Value(h['equipmentIssueNote'] as String?),
          temporaryFixNote: Value(h['temporaryFixNote'] as String?),
          vendorExpectedNote: Value(h['vendorExpectedNote'] as String?),
          safetyConcernNote: Value(h['safetyConcernNote'] as String?),
          clientCommitmentNote: Value(h['clientCommitmentNote'] as String?),
          materialShortageNote: Value(h['materialShortageNote'] as String?),
          specialInstructionNote: Value(h['specialInstructionNote'] as String?),
          createdBy: h['createdBy'] as String,
          createdAt: FixtureLoader.resolveOffset(h, 'createdAt') ?? DateTime.now(),
        ));
      }
    });
  }

  @override
  Future<void> pushNewHandover(String handoverId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushAcknowledgement({
    required String handoverId,
    required String acknowledgedBy,
    required DateTime acknowledgedAt,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
