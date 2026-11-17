import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import 'shift_handover_repository.dart';

class HttpShiftHandoverRepository implements ShiftHandoverRepository {
  HttpShiftHandoverRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> syncLatestForSite(String siteId) async {
    final response = await _dio
        .get<Map<String, dynamic>>('/v1/sites/$siteId/shift-handovers/latest');
    final h = response.data;
    if (h == null) return;

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
      createdAt: DateTime.parse(h['createdAt'] as String),
      acknowledgedBy: Value(h['acknowledgedBy'] as String?),
      acknowledgedAt: Value(
        h['acknowledgedAt'] != null ? DateTime.parse(h['acknowledgedAt'] as String) : null,
      ),
      serverVersion: Value((h['serverVersion'] as num?)?.toInt() ?? 1),
    ));
  }

  @override
  Future<void> pushNewHandover(String handoverId) async {
    final h = await _db.shiftHandoverDao.byId(handoverId);
    if (h == null) return;
    await _dio.post<void>('/v1/shift-handovers', data: {
      'id': h.id,
      'site_id': h.siteId,
      'open_jobs_note': h.openJobsNote,
      'equipment_issue_note': h.equipmentIssueNote,
      'temporary_fix_note': h.temporaryFixNote,
      'vendor_expected_note': h.vendorExpectedNote,
      'safety_concern_note': h.safetyConcernNote,
      'client_commitment_note': h.clientCommitmentNote,
      'material_shortage_note': h.materialShortageNote,
      'special_instruction_note': h.specialInstructionNote,
      'created_by': h.createdBy,
      'created_at': h.createdAt.toIso8601String(),
    });
  }

  @override
  Future<void> pushAcknowledgement({
    required String handoverId,
    required String acknowledgedBy,
    required DateTime acknowledgedAt,
  }) async {
    await _dio.post<void>('/v1/shift-handovers/$handoverId/acknowledge', data: {
      'acknowledged_by': acknowledgedBy,
      'acknowledged_at': acknowledgedAt.toIso8601String(),
    });
  }
}
