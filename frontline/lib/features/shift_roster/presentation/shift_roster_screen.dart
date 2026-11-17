import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../identity/presentation/auth_controller.dart';
import '../../location/presentation/current_site_provider.dart';
import 'shift_roster_controller.dart';

/// SCREEN 25 - Shift Roster. Today's roster for the current site;
/// "Mark absence" / "Request relief" only appear on the logged-in
/// user's own row - this is a self-service action, not roster
/// management (Section 6: that belongs to a Facility/Technical Manager
/// on the desktop surface).
class ShiftRosterScreen extends ConsumerWidget {
  const ShiftRosterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteId = ref.watch(currentSiteIdProvider).value;
    final currentUserId = ref.watch(authControllerProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Shift roster')),
      body: siteId == null
          ? const Center(child: Text('No site selected.'))
          : _RosterList(siteId: siteId, currentUserId: currentUserId),
    );
  }
}

class _RosterList extends ConsumerWidget {
  const _RosterList({required this.siteId, required this.currentUserId});
  final String siteId;
  final String? currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rosterAsync = ref.watch(_rosterProvider(siteId));

    return rosterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load roster: $e')),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(child: Text('No shifts scheduled today.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _RosterTile(
            entry: entries[index],
            siteId: siteId,
            isSelf: entries[index].userId == currentUserId,
          ),
        );
      },
    );
  }
}

class _RosterTile extends ConsumerWidget {
  const _RosterTile({required this.entry, required this.siteId, required this.isSelf});

  final ShiftRosterEntry entry;
  final String siteId;
  final bool isSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFmt = DateFormat.Hm();
    final statusColor = switch (entry.attendanceStatus) {
      'present' => Colors.green,
      'absent' => Colors.red,
      'relief_requested' => Colors.orange,
      _ => Colors.grey,
    };

    return Card(
      color: isSelf ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.attendanceStatus.replaceAll('_', ' '),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('${entry.role}${entry.skill != null ? ' · ${entry.skill}' : ''}'),
            Text(
              '${timeFmt.format(entry.shiftStart)} - ${timeFmt.format(entry.shiftEnd)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (entry.replacementUserName != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Replacement: ${entry.replacementUserName}', style: const TextStyle(fontSize: 12)),
              ),
            if (isSelf && entry.attendanceStatus != 'absent') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => ref
                          .read(shiftRosterControllerProvider.notifier)
                          .markAbsent(entry.id, siteId: siteId),
                      child: const Text('Mark absent'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (entry.attendanceStatus != 'relief_requested')
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => ref
                            .read(shiftRosterControllerProvider.notifier)
                            .requestRelief(entry.id, siteId: siteId),
                        child: const Text('Request relief'),
                      ),
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

final _rosterProvider =
    StreamProvider.family<List<ShiftRosterEntry>, String>((ref, siteId) {
  final db = ref.watch(appDatabaseProvider);
  return db.shiftRosterDao.watchForSite(siteId, DateTime.now());
});
