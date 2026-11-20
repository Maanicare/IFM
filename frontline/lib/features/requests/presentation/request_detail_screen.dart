import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../../core/rbac/action.dart';
import '../../../core/rbac/current_access_context_provider.dart';
import '../../../core/rbac/policy_guard.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../sla/presentation/sla_chip.dart';
import 'request_controller.dart';

/// SCREEN 07 - Request Detail. Comments and Related requests/Merge
/// duplicate stay pending (see PENDING_FEATURES.md) - they need a
/// comment-thread model and duplicate-detection logic this app doesn't
/// have yet. Assign/Escalate/Cancel/Change priority are plain field
/// updates on the existing request row, so those are live here,
/// gated the same way Work Order actions are.
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(_requestStreamProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Request')),
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (r) {
          if (r == null) return const Center(child: Text('Not found.'));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(r.requestNumber, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              // Wrap (not Row+Spacer): the status label is free text from
              // the backend and can be long enough to overflow a fixed row
              // on narrow phones once the SLA chip is also present.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Chip(label: Text(r.priority.toUpperCase())),
                  Chip(label: Text(r.status.replaceAll('_', ' '))),
                  if (r.escalated) const Chip(label: Text('ESCALATED'), backgroundColor: Colors.orange),
                  if (r.safetyConcern)
                    Chip(
                      avatar: const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                      label: const Text('Safety concern'),
                      backgroundColor: Colors.red.shade50,
                    ),
                  SlaChip(target: r.resolutionDueAt),
                ],
              ),
              if (r.status == 'duplicate' && r.duplicateOfRequestId != null) ...[
                const SizedBox(height: 8),
                _DuplicateOfBanner(canonicalRequestId: r.duplicateOfRequestId!),
              ],
              const SizedBox(height: 16),
              Text(r.title, style: Theme.of(context).textTheme.titleMedium),
              if (r.description != null) ...[
                const SizedBox(height: 8),
                Text(r.description!),
              ],
              if (r.affectedPeopleCount != null) ...[
                const SizedBox(height: 8),
                Text('Affected people: ${r.affectedPeopleCount}'),
              ],
              const SizedBox(height: 16),
              _DetailsSection(request: r),
              const SizedBox(height: 12),
              _EvidenceSection(requestId: r.id),
              const SizedBox(height: 12),
              _LinkedWorkOrderSection(requestId: r.id),
              const SizedBox(height: 12),
              _TimelineSection(request: r),
              const SizedBox(height: 12),
              _CommentsSection(requestId: r.id),
              const SizedBox(height: 16),
              _ActionBar(request: r),
            ],
          );
        },
      ),
    );
  }
}

final _requestStreamProvider =
    StreamProvider.family<ServiceRequest?, String>((ref, id) {
  return ref.watch(appDatabaseProvider).requestDao.watchById(id);
});

/// Content: Requester, Location, Asset, Assigned team, Resolution.
class _DetailsSection extends ConsumerWidget {
  const _DetailsSection({required this.request});
  final ServiceRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final currentUserId = ref.watch(authControllerProvider).value?.id;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow(
              label: 'Requester',
              value: request.requesterId == null
                  ? '-'
                  : (request.requesterId == currentUserId ? 'You' : request.requesterId!),
            ),
            if (request.spaceId != null)
              FutureBuilder<Space?>(
                future: db.locationDao.spaceById(request.spaceId!),
                builder: (context, snapshot) =>
                    _DetailRow(label: 'Location', value: snapshot.data?.name ?? '...'),
              ),
            if (request.assetId != null)
              FutureBuilder<Asset?>(
                future: db.assetDao.byId(request.assetId!),
                builder: (context, snapshot) =>
                    _DetailRow(label: 'Asset', value: snapshot.data?.name ?? '...'),
              ),
            _DetailRow(label: 'Assigned team', value: request.assignedTeam ?? 'Not yet assigned'),
            if (request.resolutionNote != null)
              _DetailRow(label: 'Resolution', value: request.resolutionNote!),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _EvidenceSection extends ConsumerWidget {
  const _EvidenceSection({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attachments = ref.watch(_attachmentsProvider(requestId)).value ?? const [];
    if (attachments.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Evidence', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final a = attachments[index];
                  if (a.fileType != 'photo') {
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                      child: Icon(a.fileType == 'video' ? Icons.videocam : Icons.mic, color: Colors.grey),
                    );
                  }
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(a.localPath),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _attachmentsProvider =
    StreamProvider.family<List<Attachment>, String>((ref, requestId) {
  return ref.watch(appDatabaseProvider).attachmentDao.watchFor('service_request', requestId);
});

class _LinkedWorkOrderSection extends ConsumerWidget {
  const _LinkedWorkOrderSection({required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WorkOrder?>(
      future: ref.read(appDatabaseProvider).workOrderDao.byRequestId(requestId),
      builder: (context, snapshot) {
        final wo = snapshot.data;
        if (wo == null) return const SizedBox.shrink();
        return Card(
          child: ListTile(
            leading: const Icon(Icons.build_outlined),
            title: Text('Linked work order: ${wo.woNumber}'),
            subtitle: Text(wo.status.replaceAll('_', ' ')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/work-orders/${wo.id}'),
          ),
        );
      },
    );
  }
}

class _DuplicateOfBanner extends ConsumerWidget {
  const _DuplicateOfBanner({required this.canonicalRequestId});
  final String canonicalRequestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canonical = ref.watch(_requestStreamProvider(canonicalRequestId)).value;
    return InkWell(
      onTap: () => context.push('/requests/$canonicalRequestId'),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.merge_type, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Duplicate of ${canonical?.requestNumber ?? canonicalRequestId}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

/// Screen 07 "Comments" - append-only thread, open to anyone with site
/// access (see the doc comment on `RequestController.addComment`).
class _CommentsSection extends ConsumerStatefulWidget {
  const _CommentsSection({required this.requestId});
  final String requestId;

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ref.read(requestControllerProvider.notifier).addComment(widget.requestId, text);
      _controller.clear();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(_commentsProvider(widget.requestId)).value ?? const [];
    final currentUserId = ref.watch(authControllerProvider).value?.id;
    final fmt = DateFormat.yMMMd().add_Hm();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comments', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (comments.isEmpty)
              const Text('No comments yet.', style: TextStyle(color: Colors.grey))
            else
              for (final comment in comments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorId == currentUserId ? 'You' : comment.authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(comment.body),
                      Text(
                        fmt.format(comment.createdAt),
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                      ),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Add a comment', isDense: true),
                    minLines: 1,
                    maxLines: 3,
                  ),
                ),
                IconButton(
                  icon: _submitting
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

final _commentsProvider =
    StreamProvider.family<List<RequestComment>, String>((ref, requestId) {
  return ref.watch(appDatabaseProvider).requestDao.watchCommentsFor(requestId);
});

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.request});
  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd().add_Hm();
    final events = <(String, DateTime?)>[
      ('Created', request.createdAt),
      ('Response due', request.responseDueAt),
      ('Resolution due', request.resolutionDueAt),
      ('Closed', request.closedAt),
    ].where((e) => e.$2 != null).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timeline', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            for (final (label, time) in events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 8, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text(label)),
                    Text(fmt.format(time!), style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Actions: Assign, Escalate, Cancel, Change priority - each gated by
/// the same permission a role already has for the equivalent Work
/// Order action, since this is the same triage/escalation capability
/// applied to a request instead.
class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.request});
  final ServiceRequest request;

  static const _terminalStatuses = {'closed', 'cancelled', 'rejected', 'duplicate'};
  static const _teams = ['HVAC Team', 'Electrical Team', 'Plumbing Team', 'Housekeeping Team', 'Security Team'];
  static const _priorities = ['low', 'medium', 'high', 'critical'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessContext = ref.watch(currentAccessContextProvider);
    final guard = ref.watch(policyGuardProvider);
    if (accessContext == null || _terminalStatuses.contains(request.status)) {
      return const SizedBox.shrink();
    }

    final controller = ref.read(requestControllerProvider.notifier);
    final canTriage = guard.can(accessContext, AppAction.reassignWorkOrder, siteId: request.siteId);
    final canEscalate = guard.can(accessContext, AppAction.escalateWorkOrder, siteId: request.siteId);
    final canCancel = guard.can(accessContext, AppAction.cancelServiceRequest, siteId: request.siteId);

    if (!canTriage && !canEscalate && !canCancel) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (canTriage)
          OutlinedButton.icon(
            icon: const Icon(Icons.group_outlined, size: 18),
            label: const Text('Assign'),
            onPressed: () => _pickFromList(
              context,
              title: 'Assign to team',
              options: _teams,
              onPicked: (team) => controller.assignTeam(request.id, team),
            ),
          ),
        if (canTriage)
          OutlinedButton.icon(
            icon: const Icon(Icons.low_priority, size: 18),
            label: const Text('Change priority'),
            onPressed: () => _pickFromList(
              context,
              title: 'Change priority',
              options: _priorities,
              onPicked: (p) => controller.changePriority(request.id, p),
            ),
          ),
        if (canEscalate && !request.escalated)
          OutlinedButton.icon(
            icon: const Icon(Icons.priority_high, size: 18, color: Colors.orange),
            label: const Text('Escalate'),
            onPressed: () => controller.escalate(request.id),
          ),
        if (canTriage)
          OutlinedButton.icon(
            icon: const Icon(Icons.merge_type, size: 18),
            label: const Text('Merge duplicate'),
            onPressed: () => _mergeDuplicate(context, ref, controller),
          ),
        if (canTriage) _ConvertButton(request: request, controller: controller),
        if (canCancel)
          OutlinedButton.icon(
            icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
            label: const Text('Cancel'),
            onPressed: () => _confirmCancel(context, () => controller.cancel(request.id)),
          ),
      ],
    );
  }

  Future<void> _mergeDuplicate(
    BuildContext context,
    WidgetRef ref,
    RequestController controller,
  ) async {
    final db = ref.read(appDatabaseProvider);
    final candidates = await db.requestDao.candidateDuplicatesAtSite(request.siteId, request.id);
    if (!context.mounted) return;
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other open requests at this site to merge with.')),
      );
      return;
    }
    final picked = await showModalBottomSheet<ServiceRequest>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Merge as duplicate of...', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            for (final candidate in candidates)
              ListTile(
                title: Text(candidate.requestNumber),
                subtitle: Text(candidate.title),
                onTap: () => Navigator.of(context).pop(candidate),
              ),
          ],
        ),
      ),
    );
    if (picked != null) {
      await controller.markDuplicateOf(request.id, picked.id);
    }
  }

  Future<void> _pickFromList(
    BuildContext context, {
    required String title,
    required List<String> options,
    required void Function(String) onPicked,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            for (final option in options)
              ListTile(title: Text(option), onTap: () => Navigator.of(context).pop(option)),
          ],
        ),
      ),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _confirmCancel(BuildContext context, VoidCallback onConfirmed) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this request?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirmed == true) onConfirmed();
  }
}

/// Screen 07 action: "Convert" - only offered when no work order is
/// already linked (see doc comment on `RequestController.convertToWorkOrder`).
class _ConvertButton extends ConsumerWidget {
  const _ConvertButton({required this.request, required this.controller});
  final ServiceRequest request;
  final RequestController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<WorkOrder?>(
      future: ref.read(appDatabaseProvider).workOrderDao.byRequestId(request.id),
      builder: (context, snapshot) {
        if (snapshot.data != null) return const SizedBox.shrink();
        return OutlinedButton.icon(
          icon: const Icon(Icons.build_outlined, size: 18),
          label: const Text('Convert'),
          onPressed: () async {
            final workOrderId = await controller.convertToWorkOrder(request.id);
            if (workOrderId != null && context.mounted) {
              context.push('/work-orders/$workOrderId');
            }
          },
        );
      },
    );
  }
}
