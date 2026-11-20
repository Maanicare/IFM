import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../attachments/presentation/attachment_capture_controller.dart';
import '../domain/cleaning_task_status.dart';
import 'cleaning_task_controller.dart';

/// SCREEN 21 - Cleaning Task (detail). Fields (Area/Cleaning type/SOP/
/// Frequency/Last clean/Expected duration/Assigned employee/Materials)
/// are server-configured and read-only here; the inspection points
/// double as the completion checklist (see the doc comment on
/// [CleaningTasks] in cleaning_task_tables.dart for why).
class CleaningTaskDetailScreen extends ConsumerWidget {
  const CleaningTaskDetailScreen({super.key, required this.cleaningTaskId});

  final String cleaningTaskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final taskAsync = ref.watch(_taskStreamProvider(cleaningTaskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaning task')),
      body: taskAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (task) {
          if (task == null) return const Center(child: Text('Not found.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _FieldsCard(task: task, db: db),
              const SizedBox(height: 12),
              _InspectionSection(task: task),
              const SizedBox(height: 12),
              if (task.status != CleaningTaskStatus.completed)
                _CompletionSection(task: task),
              if (task.status == CleaningTaskStatus.completed)
                _CompletedSummary(task: task),
              const SizedBox(height: 16),
              _ActionBar(task: task),
            ],
          );
        },
      ),
    );
  }
}

class _FieldsCard extends ConsumerWidget {
  const _FieldsCard({required this.task, required this.db});
  final CleaningTask task;
  final AppDatabase db;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(_spaceProvider(task.spaceId)).value;
    final fmt = DateFormat.yMMMd().add_Hm();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(space?.name ?? task.spaceId, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _Row('Cleaning type', task.cleaningType),
            _Row('Frequency', task.frequency),
            if (task.sopNote != null) _Row('SOP', task.sopNote!),
            if (task.expectedMinutes != null) _Row('Expected duration', '${task.expectedMinutes} min'),
            if (task.lastCleanAt != null) _Row('Last clean', fmt.format(task.lastCleanAt!)),
            if (task.materialsNote != null) _Row('Materials', task.materialsNote!),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Inspection points doubling as the completion checklist - each gets a
/// Pass/Fail response once the task is in progress.
class _InspectionSection extends ConsumerWidget {
  const _InspectionSection({required this.task});
  final CleaningTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(_pointsProvider(task.id)).value ?? const [];
    final responses = ref.watch(_responsesProvider(task.id)).value ?? const [];
    final responseByPoint = {for (final r in responses) r.inspectionPointId: r};
    if (points.isEmpty) return const SizedBox.shrink();

    final canRecord = task.status == CleaningTaskStatus.inProgress;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inspection points', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final point in points)
              _InspectionPointRow(
                cleaningTaskId: task.id,
                point: point,
                existing: responseByPoint[point.id],
                enabled: canRecord,
              ),
          ],
        ),
      ),
    );
  }
}

class _InspectionPointRow extends ConsumerWidget {
  const _InspectionPointRow({
    required this.cleaningTaskId,
    required this.point,
    required this.enabled,
    this.existing,
  });

  final String cleaningTaskId;
  final CleaningTaskInspectionPoint point;
  final bool enabled;
  final CleaningTaskInspectionResponse? existing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(cleaningTaskControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(point.description)),
          ChoiceChip(
            label: const Text('Pass'),
            selected: existing?.passed == true,
            onSelected: enabled
                ? (_) => controller.recordInspectionResponse(
                      cleaningTaskId: cleaningTaskId,
                      inspectionPointId: point.id,
                      passed: true,
                    )
                : null,
          ),
          const SizedBox(width: 6),
          ChoiceChip(
            label: const Text('Fail'),
            selected: existing?.passed == false,
            onSelected: enabled
                ? (_) => controller.recordInspectionResponse(
                      cleaningTaskId: cleaningTaskId,
                      inspectionPointId: point.id,
                      passed: false,
                    )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Completion (Section 21): Photo if required, Consumables used,
/// Exception.
class _CompletionSection extends ConsumerStatefulWidget {
  const _CompletionSection({required this.task});
  final CleaningTask task;

  @override
  ConsumerState<_CompletionSection> createState() => _CompletionSectionState();
}

class _CompletionSectionState extends ConsumerState<_CompletionSection> {
  late final _consumablesController = TextEditingController(text: widget.task.consumablesNote);
  late final _exceptionController = TextEditingController(text: widget.task.exceptionNote);
  bool _capturingPhoto = false;
  bool _submitting = false;

  @override
  void dispose() {
    _consumablesController.dispose();
    _exceptionController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    setState(() => _capturingPhoto = true);
    try {
      await ref.read(attachmentCaptureControllerProvider.notifier).capturePhoto(
            entityType: 'cleaning_task',
            entityId: widget.task.id,
          );
    } finally {
      if (mounted) setState(() => _capturingPhoto = false);
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ref.read(cleaningTaskControllerProvider.notifier).submitCompletion(
            widget.task.id,
            siteId: widget.task.siteId,
            consumablesNote: _consumablesController.text.trim().isEmpty
                ? null
                : _consumablesController.text.trim(),
            exceptionNote: _exceptionController.text.trim().isEmpty
                ? null
                : _exceptionController.text.trim(),
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task.status != CleaningTaskStatus.inProgress) return const SizedBox.shrink();

    final hasPhoto = ref.watch(_hasPhotoProvider(widget.task.id)).value ?? false;
    final photoSatisfied = !widget.task.photoRequired || hasPhoto;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Completion', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (widget.task.photoRequired) ...[
              Row(
                children: [
                  Icon(
                    hasPhoto ? Icons.check_circle : Icons.camera_alt_outlined,
                    size: 18,
                    color: hasPhoto ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(child: Text('Photo required')),
                  OutlinedButton(
                    onPressed: _capturingPhoto ? null : _capturePhoto,
                    child: _capturingPhoto
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(hasPhoto ? 'Retake' : 'Capture'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _consumablesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Consumables used', isDense: true),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _exceptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Exception (optional)', isDense: true),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_submitting || !photoSatisfied) ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit completion'),
              ),
            ),
            if (!photoSatisfied)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Capture the required photo before submitting.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompletedSummary extends StatelessWidget {
  const _CompletedSummary({required this.task});
  final CleaningTask task;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_Hm();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 18),
                SizedBox(width: 6),
                Text('Completed', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            if (task.completedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(fmt.format(task.completedAt!)),
              ),
            if (task.consumablesNote != null) _Row('Consumables used', task.consumablesNote!),
            if (task.exceptionNote != null) _Row('Exception', task.exceptionNote!),
          ],
        ),
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.task});
  final CleaningTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    if (accessContext == null || task.status != CleaningTaskStatus.pending) {
      return const SizedBox.shrink();
    }
    if (!guard.can(accessContext, AppAction.manageCleaningTask, siteId: task.siteId)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => ref
            .read(cleaningTaskControllerProvider.notifier)
            .startTask(task.id, siteId: task.siteId),
        child: const Text('Start task'),
      ),
    );
  }
}

final _taskStreamProvider = StreamProvider.family<CleaningTask?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).cleaningTaskDao.watchById(id);
});

final _pointsProvider =
    FutureProvider.family<List<CleaningTaskInspectionPoint>, String>((ref, cleaningTaskId) {
  return ref.watch(appDatabaseProvider).cleaningTaskDao.inspectionPointsFor(cleaningTaskId);
});

final _responsesProvider =
    StreamProvider.family<List<CleaningTaskInspectionResponse>, String>((ref, cleaningTaskId) {
  return ref.watch(appDatabaseProvider).cleaningTaskDao.watchResponsesFor(cleaningTaskId);
});

final _spaceProvider = FutureProvider.family<Space?, String>((ref, spaceId) {
  return ref.watch(appDatabaseProvider).locationDao.spaceById(spaceId);
});

final _hasPhotoProvider = StreamProvider.family<bool, String>((ref, cleaningTaskId) {
  final db = ref.watch(appDatabaseProvider);
  return db.attachmentDao
      .watchFor('cleaning_task', cleaningTaskId)
      .map((attachments) => attachments.any((a) => a.fileType == 'photo'));
});
