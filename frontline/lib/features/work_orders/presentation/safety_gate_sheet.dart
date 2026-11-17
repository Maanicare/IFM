import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../safety_gate/presentation/safety_gate_controller.dart';
import 'work_order_actions_controller.dart';

/// Shared by both the Work Order Detail screen and My Work's one-swipe
/// "Start work" action (Section 10/11) - the safety gate must fire the
/// same way regardless of where "start work" was triggered from.
Future<void> startWorkWithSafetyGate(
  BuildContext context,
  WidgetRef ref,
  WorkOrderActionsController actions,
  String workOrderId,
) async {
  final db = ref.read(appDatabaseProvider);
  final alreadyAnswered = await db.safetyGateDao.hasAnsweredFor(workOrderId);
  if (alreadyAnswered) {
    await actions.startWork(workOrderId);
    return;
  }

  if (!context.mounted) return;
  final answers = await showModalBottomSheet<Map<String, bool>>(
    context: context,
    isScrollControlled: true,
    builder: (context) => const SafetyGateSheet(),
  );
  if (answers == null) return;

  await ref.read(safetyGateControllerProvider.notifier).recordAnswers(workOrderId, answers);
  await actions.startWork(workOrderId);
}

/// Section 11: "System asks relevant safety questions" before the timer
/// starts - asked once per job, answers all required true.
class SafetyGateSheet extends StatefulWidget {
  const SafetyGateSheet({super.key});

  @override
  State<SafetyGateSheet> createState() => _SafetyGateSheetState();
}

class _SafetyGateSheetState extends State<SafetyGateSheet> {
  static const _questions = [
    'PPE worn (gloves, goggles, etc.)?',
    'Area isolated / LOTO applied if required?',
    'Tools and parts available?',
  ];

  final Map<String, bool> _answers = {for (final q in _questions) q: false};

  bool get _allConfirmed => _answers.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Before you start', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Confirm each item to start work.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            for (final q in _questions)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _answers[q],
                title: Text(q),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (v) => setState(() => _answers[q] = v ?? false),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _allConfirmed ? () => Navigator.of(context).pop(_answers) : null,
                child: const Text('Confirm & start work'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
