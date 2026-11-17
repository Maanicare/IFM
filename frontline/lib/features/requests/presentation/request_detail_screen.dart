import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../sla/presentation/sla_chip.dart';

/// SCREEN 07 - Request Detail (read-focused subset for the frontline
/// app; assignment/escalation/merge actions belong to the helpdesk/
/// manager surface per the role model in Section 6). Evidence (photos
/// captured at creation), a simple timeline, and the linked work order
/// are shown - comments/related-requests stay with the manager surface.
class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Request')),
      body: FutureBuilder<ServiceRequest?>(
        future: db.requestDao.byId(requestId),
        builder: (context, snapshot) {
          final r = snapshot.data;
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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
                  if (r.safetyConcern)
                    Chip(
                      avatar: const Icon(Icons.warning_amber, size: 16, color: Colors.red),
                      label: const Text('Safety concern'),
                      backgroundColor: Colors.red.shade50,
                    ),
                  SlaChip(target: r.resolutionDueAt),
                ],
              ),
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
              _EvidenceSection(requestId: r.id),
              const SizedBox(height: 12),
              _LinkedWorkOrderSection(requestId: r.id),
              const SizedBox(height: 12),
              _TimelineSection(request: r),
            ],
          );
        },
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
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(attachments[index].localPath),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                  ),
                ),
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
