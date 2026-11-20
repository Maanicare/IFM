import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../domain/comfort_category.dart';

part 'comfort_feedback_controller.g.dart';

/// Backs Screen 46 (Comfort Feedback): a one-tap submission, no
/// confirmation dialog or multi-step form - that's the point of
/// "One-Touch".
@riverpod
class ComfortFeedbackController extends _$ComfortFeedbackController {
  @override
  void build() {}

  Future<void> submit({
    required String siteId,
    String? spaceId,
    required ComfortCategory category,
    String? note,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot submit feedback without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.createServiceRequest, siteId: siteId);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.comfortFeedbackDao.insert(ComfortFeedbackEntriesCompanion.insert(
        id: id,
        siteId: siteId,
        spaceId: Value(spaceId),
        category: category.name,
        note: Value(note),
        submittedBy: accessContext.userId,
        createdAt: now,
      ));
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'comfort_feedback',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({'feedbackId': id}),
        createdBy: accessContext.userId,
      );
    });
  }
}
