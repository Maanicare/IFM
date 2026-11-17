import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'meter_reading_controller.g.dart';

/// Captures a meter reading in the field (Section 33) - e.g. runtime
/// hours during a PM visit - writing it locally and queueing the push.
@riverpod
class MeterReadingController extends _$MeterReadingController {
  @override
  void build() {}

  Future<void> recordReading({
    required String meterId,
    required double value,
    String? workOrderId,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    guard.ensure(accessContext, AppAction.recordMeterReading);

    final id = IdGenerator.newId();
    final now = DateTime.now();

    await db.transaction(() async {
      await db.assetDao.recordReading(MeterReadingsCompanion.insert(
        id: id,
        meterId: meterId,
        workOrderId: Value(workOrderId),
        value: value,
        capturedAt: now,
        capturedBy: accessContext.userId,
      ));
      await db.assetDao.updateMeterCurrentValue(
        meterId: meterId,
        value: value,
        updatedAt: now,
      );
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'meter_reading',
        entityId: id,
        operation: 'create',
        payloadJson: jsonEncode({
          'meterId': meterId,
          'value': value,
          'capturedAt': now.toIso8601String(),
          'capturedBy': accessContext.userId,
          'workOrderId': workOrderId,
        }),
        createdBy: accessContext.userId,
      );
    });
  }
}
