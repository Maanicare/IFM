import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../attachments/presentation/attachment_capture_controller.dart';

/// Section E — Closure evidence (Section 15, Screen 09: "before/after
/// evidence ... digital signature"). Independent of the checklist's own
/// photo/signature items, since a work order may carry general before/
/// after evidence and a closure signature even when its checklist
/// doesn't ask for either.
class WorkOrderEvidenceSection extends ConsumerWidget {
  const WorkOrderEvidenceSection({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(_attachmentsProvider(workOrderId)).value ?? const [];
    final photos = attachments.where((a) => a.fileType == 'photo').toList();
    final signature = attachments.where((a) => a.fileType == 'signature').lastOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evidence', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final photo in photos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(photo.localPath),
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  _AddPhotoTile(workOrderId: workOrderId),
                ],
              ),
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Closure signature',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (signature != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      color: Colors.grey.shade100,
                      child: Image.file(
                        File(signature.localPath),
                        width: 48,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.draw_outlined, size: 18),
                  label: Text(signature != null ? 'Re-sign' : 'Sign'),
                  onPressed: () => ref
                      .read(attachmentCaptureControllerProvider.notifier)
                      .captureSignature(
                        context,
                        entityType: 'work_order',
                        entityId: workOrderId,
                        title: 'Technician confirms work completed',
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends ConsumerWidget {
  const _AddPhotoTile({required this.workOrderId});
  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => ref
          .read(attachmentCaptureControllerProvider.notifier)
          .capturePhoto(entityType: 'work_order', entityId: workOrderId),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
      ),
    );
  }
}

final _attachmentsProvider =
    StreamProvider.family<List<Attachment>, String>((ref, workOrderId) {
  final db = ref.watch(appDatabaseProvider);
  return db.attachmentDao.watchFor('work_order', workOrderId);
});
