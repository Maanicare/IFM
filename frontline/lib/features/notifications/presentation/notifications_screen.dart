import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';

/// Section 52 notification feed. Reached from the bell icon on Home.
/// Tapping a notification marks it read and, where it references a work
/// order or request, jumps straight to that record.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(appDatabaseProvider);
    final notificationsAsync = ref.watch(_notificationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => db.notificationDao.markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load notifications: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _categoryColor(n.category).withValues(alpha: 0.12),
                  child: Icon(_categoryIcon(n.category), color: _categoryColor(n.category), size: 20),
                ),
                title: Text(
                  n.title,
                  style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text('${n.body}\n${DateFormat.MMMd().add_jm().format(n.createdAt)}'),
                isThreeLine: true,
                trailing: n.read ? null : const Icon(Icons.circle, size: 8, color: Colors.blue),
                onTap: () {
                  db.notificationDao.markRead(n.id);
                  if (n.relatedEntityType == 'work_order' && n.relatedEntityId != null) {
                    context.push('/work-orders/${n.relatedEntityId}');
                  } else if (n.relatedEntityType == 'service_request' && n.relatedEntityId != null) {
                    context.push('/requests/${n.relatedEntityId}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'sla_breach':
        return Colors.red;
      case 'sla_warning':
        return Colors.orange;
      case 'assignment':
        return Colors.blue;
      case 'sync_conflict':
        return Colors.deepOrange;
      case 'approval':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'sla_breach':
        return Icons.error_outline;
      case 'sla_warning':
        return Icons.timer_outlined;
      case 'assignment':
        return Icons.assignment_ind_outlined;
      case 'sync_conflict':
        return Icons.sync_problem_outlined;
      case 'approval':
        return Icons.task_alt_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }
}

final _notificationsStreamProvider = StreamProvider<List<AppNotification>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.notificationDao.watchAll();
});
