import 'dart:async';

import 'package:flutter/material.dart';

import '../domain/sla_status.dart';

/// Small countdown chip showing SLA state, re-evaluated once a minute so
/// an on-screen job card visibly ages from green -> amber -> red without
/// requiring a full data refresh.
class SlaChip extends StatefulWidget {
  const SlaChip({super.key, required this.target, this.pauseDuration = Duration.zero});

  final DateTime? target;
  final Duration pauseDuration;

  @override
  State<SlaChip> createState() => _SlaChipState();
}

class _SlaChipState extends State<SlaChip> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = SlaStatus.from(widget.target, pauseDuration: widget.pauseDuration);
    if (status.urgency == SlaUrgency.none) return const SizedBox.shrink();

    final (bg, fg, icon) = switch (status.urgency) {
      SlaUrgency.breached => (
          Colors.red.shade50,
          Colors.red.shade700,
          Icons.error_outline,
        ),
      SlaUrgency.atRisk => (
          Colors.orange.shade50,
          Colors.orange.shade800,
          Icons.timer_outlined,
        ),
      SlaUrgency.onTrack => (
          Colors.green.shade50,
          Colors.green.shade700,
          Icons.check_circle_outline,
        ),
      SlaUrgency.none => (Colors.grey.shade100, Colors.grey, Icons.circle),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status.label(),
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
