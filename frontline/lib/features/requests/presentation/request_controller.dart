import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';
import '../data/request_repository_provider.dart';

part 'request_controller.g.dart';

/// Backs "Report an Issue" (Journey 1 / SCREEN 06). Creating a request is
/// itself treated as an offline-first mutation: the repository writes the
/// row locally and returns a ticket number instantly, and this controller
/// enqueues the outbox entry that pushes it to the server.
@riverpod
class RequestController extends _$RequestController {
  @override
  void build() {}

  Future<String> createRequest({
    required String siteId,
    String? spaceId,
    String? assetId,
    required String categoryId,
    required String title,
    String? description,
    required String priority,
    int? affectedPeopleCount,
    bool safetyConcern = false,
    List<String> photoPaths = const [],
    List<String> videoPaths = const [],
    String? voiceNotePath,
  }) async {
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('Cannot create a request without a logged-in user.');
    }
    guard.ensure(accessContext, AppAction.createServiceRequest, siteId: siteId);

    final repo = ref.read(requestRepositoryProvider);
    final db = ref.read(appDatabaseProvider);

    final requestId = await repo.createRequest(
      siteId: siteId,
      spaceId: spaceId,
      assetId: assetId,
      categoryId: categoryId,
      title: title,
      description: description,
      priority: priority,
      requesterId: accessContext.userId,
      source: 'mobile',
      affectedPeopleCount: affectedPeopleCount,
      safetyConcern: safetyConcern,
    );

    Future<void> saveAttachment(String path, String fileType) {
      return db.attachmentDao.add(AttachmentsCompanion.insert(
        id: IdGenerator.newId(),
        entityType: 'service_request',
        entityId: requestId,
        fileType: fileType,
        localPath: path,
        uploadedBy: accessContext.userId,
        createdAt: DateTime.now(),
      ));
    }

    for (final path in photoPaths) {
      await saveAttachment(path, 'photo');
    }
    for (final path in videoPaths) {
      await saveAttachment(path, 'video');
    }
    if (voiceNotePath != null) {
      await saveAttachment(voiceNotePath, 'voice');
    }

    await db.outboxDao.enqueue(
      id: IdGenerator.newId(),
      entityType: 'service_request',
      entityId: requestId,
      operation: 'create',
      payloadJson: jsonEncode({'requestId': requestId}),
      createdBy: accessContext.userId,
    );

    return requestId;
  }

  Future<void> _updateAndQueue(
    String requestId,
    AppAction action,
    Future<void> Function() applyLocally,
  ) async {
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) return;
    final db = ref.read(appDatabaseProvider);
    final request = await db.requestDao.byId(requestId);
    if (request == null) return;
    guard.ensure(accessContext, action, siteId: request.siteId);

    await db.transaction(() async {
      await applyLocally();
      await db.outboxDao.enqueue(
        id: IdGenerator.newId(),
        entityType: 'service_request',
        entityId: requestId,
        operation: 'update',
        payloadJson: jsonEncode({'requestId': requestId}),
        createdBy: accessContext.userId,
      );
    });
  }

  /// Screen 07 action: "Assign" - to a team/trade (Section 6: Helpdesk
  /// Executive's "ticket triage" function), not an individual.
  Future<void> assignTeam(String requestId, String team) {
    final db = ref.read(appDatabaseProvider);
    return _updateAndQueue(
      requestId,
      AppAction.reassignWorkOrder,
      () => db.requestDao.assignTeam(requestId, team),
    );
  }

  /// Screen 07 action: "Escalate" - also bumps priority if it wasn't
  /// already at the top, since an escalation that leaves priority
  /// unchanged wouldn't actually change how it's triaged.
  Future<void> escalate(String requestId) {
    final db = ref.read(appDatabaseProvider);
    return _updateAndQueue(
      requestId,
      AppAction.escalateWorkOrder,
      () => db.requestDao.escalate(requestId, bumpedPriority: 'critical'),
    );
  }

  /// Screen 07 action: "Change priority".
  Future<void> changePriority(String requestId, String priority) {
    final db = ref.read(appDatabaseProvider);
    return _updateAndQueue(
      requestId,
      AppAction.reassignWorkOrder,
      () => db.requestDao.changePriority(requestId, priority),
    );
  }

  /// Screen 07 action: "Cancel".
  Future<void> cancel(String requestId) {
    final db = ref.read(appDatabaseProvider);
    return _updateAndQueue(
      requestId,
      AppAction.cancelServiceRequest,
      () => db.requestDao.cancel(requestId),
    );
  }
}
