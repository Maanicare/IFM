import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/util/id_generator.dart';

part 'safety_gate_controller.g.dart';

/// Pre-work safety gate (Section 11). Records each question's answer as
/// its own row (not one JSON blob) so a future audit/analytics query can
/// ask "how often is PPE answered no" without parsing payloads.
@riverpod
class SafetyGateController extends _$SafetyGateController {
  @override
  void build() {}

  Future<void> recordAnswers(String workOrderId, Map<String, bool> answers) async {
    final db = ref.read(appDatabaseProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    final now = DateTime.now();

    await db.transaction(() async {
      for (final entry in answers.entries) {
        final id = IdGenerator.newId();
        await db.safetyGateDao.insertLocal(SafetyGateResponsesCompanion.insert(
          id: id,
          workOrderId: workOrderId,
          question: entry.key,
          answer: entry.value,
          confirmedBy: accessContext.userId,
          confirmedAt: now,
        ));
        await db.outboxDao.enqueue(
          id: IdGenerator.newId(),
          entityType: 'safety_gate_response',
          entityId: id,
          operation: 'create',
          payloadJson: jsonEncode({
            'workOrderId': workOrderId,
            'question': entry.key,
            'answer': entry.value,
            'confirmedBy': accessContext.userId,
            'confirmedAt': now.toIso8601String(),
          }),
          createdBy: accessContext.userId,
        );
      }
    });
  }

  /// Pushes one answer to the server - called by the sync engine per
  /// queued row. Mock mode just simulates latency.
  Future<void> push(Map<String, dynamic> payload) async {
    if (AppConfig.useMock) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return;
    }
    await ref.read(dioClientProvider).post<void>('/v1/safety-gate-responses', data: payload);
  }
}
