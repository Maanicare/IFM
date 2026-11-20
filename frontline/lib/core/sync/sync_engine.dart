import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/assets/data/asset_repository_provider.dart';
import '../../features/attachments/data/attachment_upload_repository_provider.dart';
import '../../features/checklists/data/checklist_repository_provider.dart';
import '../../features/cleaning/data/cleaning_task_repository_provider.dart';
import '../../features/fleet/data/fleet_repository_provider.dart';
import '../../features/inventory/data/inventory_repository_provider.dart';
import '../../features/requests/data/request_repository_provider.dart';
import '../../features/safety/data/safety_repository_provider.dart';
import '../../features/shift_handover/data/shift_handover_repository_provider.dart';
import '../../features/safety_gate/presentation/safety_gate_controller.dart';
import '../../features/work_orders/presentation/voice_note_controller.dart';
import '../../features/work_orders/presentation/work_order_actions_controller.dart';
import '../../features/shift_roster/data/shift_roster_repository_provider.dart';
import '../../features/work_orders/data/work_order_repository_provider.dart';
import '../db/app_database.dart';
import '../error/exceptions.dart';
import '../logging/app_logger.dart';
import '../network/connectivity_service.dart';

part 'sync_engine.g.dart';

/// Drains the offline outbox in strict sequence order, replaying each
/// mutation against whichever repository owns its `entityType`.
///
/// Conflicts are never auto-resolved (Section 57: "Sync conflicts shall be
/// surfaced rather than silently overwritten") - a [SyncConflictError]
/// marks the entry `conflict` and stops processing it; everything else in
/// the queue still proceeds so one disputed record cannot block the rest
/// of a technician's day.
class SyncEngine {
  SyncEngine(this._ref, this._db);

  final Ref _ref;
  final AppDatabase _db;
  static const _tag = 'SyncEngine';

  bool _isRunning = false;

  Future<void> drainQueue() async {
    if (_isRunning) return;
    _isRunning = true;
    try {
      final pending = await _db.outboxDao.pendingInOrder();
      for (final entry in pending) {
        await _processOne(entry);
      }
      await _uploadPendingAttachments();
    } finally {
      _isRunning = false;
    }
  }

  /// Uploads every captured-but-not-yet-uploaded photo/signature/voice
  /// file (Section 36). Separate from the outbox loop above because
  /// attachments track their own per-file status (`pending`/`uploading`/
  /// `uploaded`/`failed`) rather than a single queued mutation - a
  /// technician can see which specific photo failed to upload, not just
  /// that "something" did.
  Future<void> _uploadPendingAttachments() async {
    final pending = await _db.attachmentDao.pendingUploads();
    final repo = _ref.read(attachmentUploadRepositoryProvider);

    for (final attachment in pending) {
      await _db.attachmentDao.markStatus(attachment.id, 'uploading');
      try {
        final url = await repo.upload(
          localPath: attachment.localPath,
          entityType: attachment.entityType,
          entityId: attachment.entityId,
          fileType: attachment.fileType,
        );
        await _db.attachmentDao.setRemoteUrl(attachment.id, url);
      } catch (e) {
        await _db.attachmentDao.markFailed(attachment.id, attachment.uploadAttempts);
        AppLogger.instance.error(
          _tag,
          'Attachment upload failed for ${attachment.id}',
          error: e,
        );
      }
    }
  }

  Future<void> _processOne(OutboxEntry entry) async {
    await _db.outboxDao.markSyncing(entry.id);
    try {
      switch (entry.entityType) {
        case 'work_order_status':
          await _pushWorkOrderStatus(entry);
          break;
        case 'checklist_response':
          await _pushChecklistResponse(entry);
          break;
        case 'meter_reading':
          await _pushMeterReading(entry);
          break;
        case 'inventory_transaction':
          await _pushInventoryTransaction(entry);
          break;
        case 'shift_handover':
          await _pushShiftHandover(entry);
          break;
        case 'shift_roster_attendance':
          await _pushRosterAttendance(entry);
          break;
        case 'safety_gate_response':
          await _ref.read(safetyGateControllerProvider.notifier)
              .push(jsonDecode(entry.payloadJson) as Map<String, dynamic>);
          break;
        case 'work_order_voice_note':
          await _ref.read(voiceNoteControllerProvider.notifier)
              .push(entry.entityId, jsonDecode(entry.payloadJson) as Map<String, dynamic>);
          break;
        case 'work_order_closure':
          await _ref.read(workOrderActionsControllerProvider.notifier)
              .pushClosure(entry.entityId);
          break;
        case 'service_request':
          await _pushServiceRequest(entry);
          break;
        case 'incident':
          await _ref.read(safetyRepositoryProvider).pushIncident(entry.entityId);
          break;
        case 'hazard':
          await _ref.read(safetyRepositoryProvider).pushHazard(entry.entityId);
          break;
        case 'fleet_trip':
          await _pushFleetTrip(entry);
          break;
        case 'cleaning_task_completion':
          await _ref.read(cleaningTaskRepositoryProvider).pushCompletion(entry.entityId);
          break;
        default:
          AppLogger.instance.warning(
            _tag,
            'Unknown outbox entityType: ${entry.entityType}',
          );
      }
      await _db.outboxDao.markSynced(entry.id);
    } on SyncConflictError catch (e) {
      AppLogger.instance.error(_tag, 'Sync conflict on ${entry.entityType}:${entry.entityId}', error: e);
      await _db.outboxDao.markConflict(entry.id, e.message);
    } on NetworkOfflineError {
      // Leave as pending (not failed) - will be retried on next connectivity
      // change or manual trigger without penalising retry-attempt count.
      await _db.outboxDao.resetToPending(entry.id);
    } catch (e) {
      await _db.outboxDao.incrementAttempts(entry.id);
      await _db.outboxDao.markFailed(entry.id, e.toString());
      AppLogger.instance.error(_tag, 'Push failed for ${entry.entityType}:${entry.entityId}', error: e);
    }
  }

  Future<void> _pushWorkOrderStatus(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final repo = _ref.read(workOrderRepositoryProvider);
    final result = await repo.pushStatusChange(
      workOrderId: entry.entityId,
      newStatus: payload['status'] as String,
      reason: payload['reason'] as String?,
      baseServerVersion: entry.baseServerVersion,
      changedBy: entry.createdBy,
      actualStart: payload['actualStart'] != null
          ? DateTime.parse(payload['actualStart'] as String)
          : null,
      actualEnd: payload['actualEnd'] != null
          ? DateTime.parse(payload['actualEnd'] as String)
          : null,
      actualMinutes: (payload['actualMinutes'] as num?)?.toInt(),
      latitude: (payload['latitude'] as num?)?.toDouble(),
      longitude: (payload['longitude'] as num?)?.toDouble(),
      locationSource: payload['locationSource'] as String?,
    );
    await (_db.update(_db.workOrders)..where((t) => t.id.equals(entry.entityId)))
        .write(WorkOrdersCompanion(
      serverVersion: Value(result.newServerVersion),
      hasPendingLocalChanges: const Value(false),
    ));
  }

  Future<void> _pushChecklistResponse(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    await _ref.read(checklistRepositoryProvider).pushResponse(
          workOrderId: payload['workOrderId'] as String,
          itemId: payload['itemId'] as String,
          responseJson: payload['response'] as String,
          capturedBy: payload['capturedBy'] as String,
          capturedAt: DateTime.parse(payload['capturedAt'] as String),
        );
  }

  Future<void> _pushMeterReading(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    await _ref.read(assetRepositoryProvider).pushMeterReading(
          meterId: payload['meterId'] as String,
          value: (payload['value'] as num).toDouble(),
          capturedAt: DateTime.parse(payload['capturedAt'] as String),
          capturedBy: payload['capturedBy'] as String,
          workOrderId: payload['workOrderId'] as String?,
        );
  }

  Future<void> _pushInventoryTransaction(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    await _ref.read(inventoryRepositoryProvider).pushIssue(
          transactionId: entry.entityId,
          itemId: payload['itemId'] as String,
          workOrderId: payload['workOrderId'] as String,
          quantity: (payload['quantity'] as num).toDouble(),
          userId: payload['userId'] as String,
          timestamp: DateTime.parse(payload['timestamp'] as String),
        );
  }

  Future<void> _pushShiftHandover(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final repo = _ref.read(shiftHandoverRepositoryProvider);
    if (entry.operation == 'acknowledge') {
      await repo.pushAcknowledgement(
        handoverId: entry.entityId,
        acknowledgedBy: payload['acknowledgedBy'] as String,
        acknowledgedAt: DateTime.parse(payload['acknowledgedAt'] as String),
      );
    } else {
      await repo.pushNewHandover(entry.entityId);
    }
  }

  Future<void> _pushRosterAttendance(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    await _ref.read(shiftRosterRepositoryProvider).pushAttendanceChange(
          rosterEntryId: entry.entityId,
          status: payload['status'] as String,
        );
  }

  Future<void> _pushServiceRequest(OutboxEntry entry) async {
    final payload = jsonDecode(entry.payloadJson) as Map<String, dynamic>;
    final repo = _ref.read(requestRepositoryProvider);
    final requestId = payload['requestId'] as String;
    if (entry.operation == 'update') {
      await repo.pushUpdate(requestId);
    } else {
      await repo.pushNewRequest(requestId);
    }
  }

  Future<void> _pushFleetTrip(OutboxEntry entry) async {
    await _ref.read(fleetRepositoryProvider).pushTrip(entry.entityId);
  }
}

@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return SyncEngine(ref, db);
}

/// Watches connectivity and automatically drains the outbox the moment the
/// device comes back online, so a technician never has to remember to
/// manually "sync".
@Riverpod(keepAlive: true)
class SyncAutoRunner extends _$SyncAutoRunner {
  @override
  void build() {
    ref.listen(isOnlineProvider, (previous, next) {
      final cameOnline = next.value == true && previous?.value != true;
      if (cameOnline) {
        ref.read(syncEngineProvider).drainQueue();
      }
    });
  }
}
