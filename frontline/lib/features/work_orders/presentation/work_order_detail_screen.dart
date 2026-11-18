import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../../core/theme/app_theme.dart';
import '../../assets/presentation/meter_reading_dialog.dart';
import '../../checklists/presentation/checklist_section.dart';
import '../../inventory/presentation/parts_used_section.dart';
import 'safety_gate_sheet.dart';
import 'voice_note_section.dart';
import '../../sla/presentation/sla_chip.dart';
import '../domain/work_order_status.dart';
import 'work_order_actions_controller.dart';
import 'work_order_evidence_section.dart';
import 'work_timer.dart';

/// SCREEN 09 - Work Order Detail. Sections B (asset context) and E
/// (closure/evidence) are intentionally dense since this is a management
/// read surface too; sections C/D (plan/execution) carry the one-tap
/// technician actions per Section 11's field workflow.
class WorkOrderDetailScreen extends ConsumerWidget {
  const WorkOrderDetailScreen({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final workOrderAsync = ref.watch(_workOrderStreamProvider(workOrderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Work Order')),
      body: workOrderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (wo) {
          if (wo == null) return const Center(child: Text('Not found.'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(wo: wo),
              if (wo.actualStart != null) ...[
                const SizedBox(height: 8),
                WorkTimer(workOrder: wo),
              ],
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Problem',
                child: Text(wo.problemDescription ?? 'No description provided.'),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                title: 'Asset context',
                child: FutureBuilder<Asset?>(
                  future: wo.assetId != null ? db.assetDao.byId(wo.assetId!) : Future.value(null),
                  builder: (context, snapshot) {
                    final asset = snapshot.data;
                    if (asset == null) return const Text('No linked asset.');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => context.push('/assets/${asset.id}'),
                          child: Row(
                            children: [
                              Expanded(child: Text('${asset.name} (${asset.assetCode})')),
                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                        Text('Criticality: ${asset.criticality} · Status: ${asset.status}'),
                        if (asset.repeatFailureCount > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Repeat failure radar: ${asset.repeatFailureCount} repairs recently',
                                style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                              ),
                            ),
                          ),
                        _AssetMetersRow(assetId: asset.id, workOrderId: wo.id),
                      ],
                    );
                  },
                ),
              ),
              if (wo.checklistId != null) ...[
                const SizedBox(height: 12),
                ChecklistSection(workOrderId: wo.id, checklistId: wo.checklistId!),
              ],
              const SizedBox(height: 12),
              VoiceNoteSection(workOrderId: wo.id),
              const SizedBox(height: 12),
              PartsUsedSection(workOrderId: wo.id, siteId: wo.siteId),
              const SizedBox(height: 12),
              WorkOrderEvidenceSection(workOrderId: wo.id),
              const SizedBox(height: 12),
              _ClosureSection(wo: wo),
              const SizedBox(height: 16),
              _ActionBar(wo: wo),
            ],
          );
        },
      ),
    );
  }
}

/// Section D "Execution: Readings" - lets a technician log a meter
/// reading against this specific job (Journey 11 step: "Records ...
/// meter readings"), only shown when the linked asset actually has
/// meters to read.
class _AssetMetersRow extends ConsumerWidget {
  const _AssetMetersRow({required this.assetId, required this.workOrderId});
  final String assetId;
  final String workOrderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meters = ref.watch(_metersForWoProvider(assetId)).value ?? const [];
    if (meters.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final meter in meters)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${meter.meterType.replaceAll('_', ' ')}: '
                      '${meter.currentValue ?? 'no reading'} ${meter.unit}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showMeterReadingDialog(
                      context,
                      ref,
                      meter: meter,
                      workOrderId: workOrderId,
                    ),
                    child: const Text('Record reading'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

final _metersForWoProvider = FutureProvider.family<List<AssetMeter>, String>((ref, assetId) {
  return ref.watch(appDatabaseProvider).assetDao.metersFor(assetId);
});

/// Section E (Closure): Root cause, Work performed, Remaining issue,
/// Follow-up, QA. Shown once the job is past "assigned" - a technician
/// can fill the notes any time while working, not only at submission;
/// QA is a separate control for whoever verifies (may differ from the
/// person who did the work).
class _ClosureSection extends ConsumerStatefulWidget {
  const _ClosureSection({required this.wo});
  final WorkOrder wo;

  @override
  ConsumerState<_ClosureSection> createState() => _ClosureSectionState();
}

class _ClosureSectionState extends ConsumerState<_ClosureSection> {
  late final _rootCauseController = TextEditingController(text: widget.wo.rootCauseCode);
  late final _workPerformedController = TextEditingController(text: widget.wo.resolutionCode);
  late final _remainingIssueController = TextEditingController(text: widget.wo.remainingIssueNote);
  late final _followUpController = TextEditingController(text: widget.wo.followUpNote);
  bool _saving = false;

  @override
  void dispose() {
    _rootCauseController.dispose();
    _workPerformedController.dispose();
    _remainingIssueController.dispose();
    _followUpController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(workOrderActionsControllerProvider.notifier).saveClosureDetails(
          widget.wo.id,
          rootCause: _rootCauseController.text.trim().isEmpty ? null : _rootCauseController.text.trim(),
          workPerformed: _workPerformedController.text.trim().isEmpty ? null : _workPerformedController.text.trim(),
          remainingIssue: _remainingIssueController.text.trim().isEmpty ? null : _remainingIssueController.text.trim(),
          followUp: _followUpController.text.trim().isEmpty ? null : _followUpController.text.trim(),
        );
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Closure details saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    if (accessContext == null || widget.wo.status == WorkOrderStatus.assigned) {
      return const SizedBox.shrink();
    }

    final canEditClosure = guard.can(accessContext, AppAction.completeWorkOrder, siteId: widget.wo.siteId);
    final canSetQa = guard.can(accessContext, AppAction.verifyWorkOrder, siteId: widget.wo.siteId);
    if (!canEditClosure && !canSetQa) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Closure', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (canEditClosure) ...[
              _ClosureField(label: 'Root cause', controller: _rootCauseController),
              _ClosureField(label: 'Work performed', controller: _workPerformedController),
              _ClosureField(label: 'Remaining issue', controller: _remainingIssueController),
              _ClosureField(label: 'Follow-up', controller: _followUpController),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save closure details'),
                ),
              ),
            ],
            if (canSetQa) ...[
              if (canEditClosure) const Divider(height: 20),
              Row(
                children: [
                  const Text('QA: '),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Pass'),
                    selected: widget.wo.qaStatus == 'pass',
                    onSelected: (_) => ref
                        .read(workOrderActionsControllerProvider.notifier)
                        .setQaStatus(widget.wo.id, 'pass'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Fail'),
                    selected: widget.wo.qaStatus == 'fail',
                    onSelected: (_) => ref
                        .read(workOrderActionsControllerProvider.notifier)
                        .setQaStatus(widget.wo.id, 'fail'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ClosureField extends StatelessWidget {
  const _ClosureField({required this.label, required this.controller});
  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(labelText: label, isDense: true),
      ),
    );
  }
}

final _workOrderStreamProvider =
    StreamProvider.family<WorkOrder?, String>((ref, id) {
  final db = ref.watch(appDatabaseProvider);
  return db.workOrderDao.watchById(id);
});

final _hasSignatureProvider =
    StreamProvider.family<bool, String>((ref, workOrderId) {
  final db = ref.watch(appDatabaseProvider);
  return db.attachmentDao
      .watchFor('work_order', workOrderId)
      .map((attachments) => attachments.any((a) => a.fileType == 'signature'));
});

class _Header extends StatelessWidget {
  const _Header({required this.wo});
  final WorkOrder wo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(wo.woNumber, style: Theme.of(context).textTheme.titleLarge),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: PriorityColors.of(wo.priority).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      wo.priority.toUpperCase(),
                      style: TextStyle(color: PriorityColors.of(wo.priority), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(wo.status.replaceAll('_', ' ')),
                ],
              ),
            ],
          ),
        ),
        SlaChip(target: wo.slaResolutionTarget, pauseDuration: Duration(seconds: wo.slaPauseSeconds)),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Section C/D: the next legal action for the current status, rendered
/// as a single prominent button so a technician never has to guess what
/// to do next (Section 3.4: fast, evidence-backed execution).
class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.wo});
  final WorkOrder wo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    final actions = ref.read(workOrderActionsControllerProvider.notifier);
    final hasClosureSignature = ref.watch(_hasSignatureProvider(wo.id)).value ?? false;

    if (accessContext == null || WorkOrderStatus.terminal.contains(wo.status)) {
      return const SizedBox.shrink();
    }

    Widget? primaryButton(
      String label,
      AppAction action,
      VoidCallback onPressed, {
      bool enabled = true,
    }) {
      if (!guard.can(accessContext, action, siteId: wo.siteId)) return null;
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(onPressed: enabled ? onPressed : null, child: Text(label)),
      );
    }

    // Section E (Closure) requires a signature before completion can be
    // submitted (Section 3.2: evidence before claims) - the technician is
    // told why the button is disabled rather than it silently vanishing.
    final button = switch (wo.status) {
      WorkOrderStatus.assigned => primaryButton('Accept job', AppAction.acceptWorkOrder, () => actions.accept(wo.id)),
      WorkOrderStatus.accepted => primaryButton('Start route', AppAction.startWorkOrder, () => actions.startRoute(wo.id)),
      WorkOrderStatus.enRoute => primaryButton('Check in', AppAction.checkInWorkOrder, () => _handleCheckIn(context, actions, wo.id)),
      WorkOrderStatus.checkedIn => primaryButton('Start work', AppAction.startWorkOrder, () => startWorkWithSafetyGate(context, ref, actions, wo.id)),
      WorkOrderStatus.inProgress => primaryButton(
          'Submit completion',
          AppAction.completeWorkOrder,
          () => actions.submitCompletion(wo.id),
          enabled: hasClosureSignature,
        ),
      WorkOrderStatus.blocked => primaryButton('Resume work', AppAction.startWorkOrder, () => actions.resume(wo.id)),
      WorkOrderStatus.workCompleted => primaryButton('Verify (supervisor)', AppAction.verifyWorkOrder, () => actions.verify(wo.id)),
      _ => null,
    };

    return Column(
      children: [
        ?button,
        if (wo.status == WorkOrderStatus.inProgress && !hasClosureSignature)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Capture the closure signature above before submitting.',
              style: TextStyle(fontSize: 12, color: Colors.orange),
            ),
          ),
        if (wo.status == WorkOrderStatus.inProgress || wo.status == WorkOrderStatus.checkedIn) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => _showBlockerSheet(context, actions, wo.id),
            child: const Text("I can't continue"),
          ),
        ],
      ],
    );
  }

  void _showBlockerSheet(
    BuildContext context,
    WorkOrderActionsController actions,
    String workOrderId,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('What is blocking this job?', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final reason in WorkOrderStatus.blockerReasons)
              ListTile(
                title: Text(reason.replaceAll('_', ' ')),
                onTap: () {
                  actions.reportBlocked(workOrderId, reason);
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Tries GPS first; if it's unavailable, prompts for a manual-override
  /// reason and retries with it (Section 11: "manual override with
  /// reason" - never a silent, unlocated check-in).
  Future<void> _handleCheckIn(
    BuildContext context,
    WorkOrderActionsController actions,
    String workOrderId,
  ) async {
    try {
      await actions.checkIn(workOrderId);
    } on LocationUnavailableError {
      if (!context.mounted) return;
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => _ManualLocationReasonDialog(),
      );
      if (reason == null || reason.trim().isEmpty) return;
      await actions.checkIn(workOrderId, manualOverrideReason: reason.trim());
    }
  }

}

class _ManualLocationReasonDialog extends StatefulWidget {
  @override
  State<_ManualLocationReasonDialog> createState() => _ManualLocationReasonDialogState();
}

class _ManualLocationReasonDialogState extends State<_ManualLocationReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Location unavailable'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GPS could not be obtained. Enter a reason to check in manually.'),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Reason', border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Check in'),
        ),
      ],
    );
  }
}
