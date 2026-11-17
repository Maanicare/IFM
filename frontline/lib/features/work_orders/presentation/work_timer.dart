import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/db/app_database.dart';
import '../domain/work_order_status.dart';

/// Live elapsed-time display while a job is `in_progress` (Section 11:
/// "Technician starts work timer"). Purely a read-model over
/// `work_orders.actual_start` / `actual_minutes` - the timer doesn't own
/// any state of its own, so it survives app restarts and backgrounding
/// without special handling.
class WorkTimer extends StatefulWidget {
  const WorkTimer({super.key, required this.workOrder});

  final WorkOrder workOrder;

  @override
  State<WorkTimer> createState() => _WorkTimerState();
}

class _WorkTimerState extends State<WorkTimer> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (widget.workOrder.status == WorkOrderStatus.inProgress) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    }
  }

  @override
  void didUpdateWidget(WorkTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final running = widget.workOrder.status == WorkOrderStatus.inProgress;
    if (running && _ticker == null) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else if (!running && _ticker != null) {
      _ticker!.cancel();
      _ticker = null;
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wo = widget.workOrder;
    if (wo.actualStart == null) return const SizedBox.shrink();

    final isRunning = wo.status == WorkOrderStatus.inProgress;
    final elapsed = isRunning
        ? DateTime.now().difference(wo.actualStart!)
        : Duration(minutes: wo.actualMinutes ?? 0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isRunning ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRunning ? Icons.timer_outlined : Icons.timer_off_outlined,
            size: 16,
            color: isRunning ? Colors.green.shade700 : Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            _format(elapsed),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isRunning ? Colors.green.shade700 : Colors.grey.shade700,
            ),
          ),
          if (isRunning) ...[
            const SizedBox(width: 4),
            const Text('elapsed', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
