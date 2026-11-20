import 'package:dio/dio.dart';

import '../../../core/db/app_database.dart';
import 'comfort_feedback_repository.dart';

class HttpComfortFeedbackRepository implements ComfortFeedbackRepository {
  HttpComfortFeedbackRepository(this._dio, this._db);

  final Dio _dio;
  final AppDatabase _db;

  @override
  Future<void> pushFeedback(String feedbackId) async {
    final f = await _db.comfortFeedbackDao.byId(feedbackId);
    if (f == null) return;
    await _dio.post<void>('/v1/comfort-feedback', data: {
      'id': f.id,
      'site_id': f.siteId,
      'space_id': f.spaceId,
      'category': f.category,
      'note': f.note,
      'submitted_by': f.submittedBy,
      'created_at': f.createdAt.toIso8601String(),
    });
  }
}
