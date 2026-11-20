import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'shift_roster_repository.dart';

class HttpShiftRosterRepository implements ShiftRosterRepository {
  HttpShiftRosterRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncForSite(String siteId) async {
    final response = await _dio.get<List<dynamic>>('/v1/sites/$siteId/shift-roster/today');
    final list = response.data ?? const [];

    await _db.transaction(() async {
      for (final r in list.cast<Map<String, dynamic>>()) {
        await _db.shiftRosterDao.upsertFromServer(ShiftRosterEntriesCompanion.insert(
          id: r['id'] as String,
          siteId: r['siteId'] as String,
          userId: r['userId'] as String,
          userName: r['userName'] as String,
          role: r['role'] as String,
          skill: Value(r['skill'] as String?),
          shiftStart: DateTime.parse(r['shiftStart'] as String),
          shiftEnd: DateTime.parse(r['shiftEnd'] as String),
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
    await _dio.patch<void>('/v1/shift-roster/$rosterEntryId/attendance', data: {
      'status': status,
    });
  }

  @override
  Future<void> pushSwap({required String entryIdA, required String entryIdB}) async {
    await _dio.post<void>('/v1/shift-roster/swap', data: {
      'entry_id_a': entryIdA,
      'entry_id_b': entryIdB,
    });
  }

  @override
  Future<void> pushReplacement(String rosterEntryId) async {
    final entry = await _db.shiftRosterDao.byId(rosterEntryId);
    if (entry == null) return;
    await _dio.patch<void>('/v1/shift-roster/$rosterEntryId/replacement', data: {
      'replacement_user_name': entry.replacementUserName,
    });
  }
}
