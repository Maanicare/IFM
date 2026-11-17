import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/db/app_database.dart';
import '../../../core/media/evidence_capture.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/util/id_generator.dart';

part 'attachment_capture_controller.g.dart';

/// Captures a photo or signature to local storage and records it as an
/// [Attachments] row against whatever entity it belongs to (a work order,
/// a checklist item, an incident, ...). The actual upload-to-server step
/// is a separate concern (`AttachmentDao.pendingUploads` already exposes
/// what's queued) - this controller's job ends at "durably captured and
/// recorded locally" (Section 3.2: evidence before claims).
@riverpod
class AttachmentCaptureController extends _$AttachmentCaptureController {
  @override
  void build() {}

  /// Opens the camera and, if a photo was taken, saves it. Returns the
  /// local file path (for immediate display), or null if the technician
  /// cancelled.
  Future<String?> capturePhoto({
    required String entityType,
    required String entityId,
    String? caption,
  }) async {
    final path = await EvidenceCapture.capturePhoto();
    if (path == null) return null;
    return _save(
      entityType: entityType,
      entityId: entityId,
      fileType: 'photo',
      localPath: path,
      caption: caption,
    );
  }

  /// Opens a signature pad and, if signed, saves it. Returns the local
  /// file path, or null if cancelled/left blank.
  Future<String?> captureSignature(
    BuildContext context, {
    required String entityType,
    required String entityId,
    String title = 'Sign here',
    String? caption,
  }) async {
    final path = await EvidenceCapture.captureSignature(context, title: title);
    if (path == null) return null;
    return _save(
      entityType: entityType,
      entityId: entityId,
      fileType: 'signature',
      localPath: path,
      caption: caption,
    );
  }

  Future<String> _save({
    required String entityType,
    required String entityId,
    required String fileType,
    required String localPath,
    String? caption,
  }) async {
    final db = ref.read(appDatabaseProvider);
    final guard = ref.read(policyGuardProvider);
    final accessContext = ref.read(currentAccessContextProvider);
    if (accessContext == null) {
      throw StateError('No authenticated user to attribute this evidence to.');
    }
    guard.ensure(accessContext, AppAction.captureAttachment);

    await db.attachmentDao.add(AttachmentsCompanion.insert(
      id: IdGenerator.newId(),
      entityType: entityType,
      entityId: entityId,
      fileType: fileType,
      localPath: localPath,
      caption: Value(caption),
      uploadedBy: accessContext.userId,
      createdAt: DateTime.now(),
    ));
    return localPath;
  }
}
