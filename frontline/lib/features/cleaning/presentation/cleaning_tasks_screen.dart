import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/db/app_database.dart';
import '../../identity/presentation/auth_controller.dart';
import '../domain/cleaning_task_status.dart';

/// SCREEN 21 - Cleaning Task (list). A Housekeeping Employee's assigned
/// tasks, most overdue/soonest first.
class CleaningTasksScreen extends ConsumerWidget {
  const CleaningTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).value?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Cleaning tasks')),
      body: userId == null
          ? const SizedBox.shrink()
          : _TaskList(userId: userId),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(_tasksProvider(userId));

    return tasksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Could not load tasks: $e')),
      data: (tasks) {
        if (tasks.isEmpty) {
          return const Center(child: Text('No cleaning tasks assigned.'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) => _TaskCard(task: tasks[index]),
        );
      },
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task});
  final CleaningTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final space = ref.watch(_spaceProvider(task.spaceId)).value;
    final statusColor = switch (task.status) {
      CleaningTaskStatus.completed => Colors.green,
      CleaningTaskStatus.inProgress => Colors.orange,
      _ => Colors.grey,
    };

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/cleaning-tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      space?.name ?? task.spaceId,
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
                      task.status.replaceAll('_', ' '),
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${task.cleaningType} · ${task.frequency}'),
              Text(
                DateFormat.Hm().format(task.scheduledDate),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _tasksProvider = StreamProvider.family<List<CleaningTask>, String>((ref, userId) {
  return ref.watch(appDatabaseProvider).cleaningTaskDao.watchAssignedTo(userId);
});

final _spaceProvider = FutureProvider.family<Space?, String>((ref, spaceId) {
  return ref.watch(appDatabaseProvider).locationDao.spaceById(spaceId);
});
