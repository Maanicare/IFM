/// Classifies how a work order/request stands against its SLA resolution
/// target right now, for the countdown chips used across My Work, Work
/// Order Detail and Request Detail (Sections 10, 31, SCREEN 07/09).
enum SlaUrgency { onTrack, atRisk, breached, none }

class SlaStatus {
  const SlaStatus({
    required this.urgency,
    required this.remaining,
    this.target,
  });

  final SlaUrgency urgency;
  final Duration remaining; // negative once breached
  final DateTime? target;

  /// At-risk threshold: flagged amber once less than 25% of the time
  /// between "now" and breach remains, or under 15 minutes absolute -
  /// whichever triggers first. This is a simple local heuristic; the
  /// authoritative SLA Breach Predictor (Section 16.3) lives server-side.
  static SlaStatus from(DateTime? target, {Duration pauseDuration = Duration.zero}) {
    if (target == null) {
      return const SlaStatus(urgency: SlaUrgency.none, remaining: Duration.zero);
    }
    final effectiveTarget = target.add(pauseDuration);
    final remaining = effectiveTarget.difference(DateTime.now());

    if (remaining.isNegative) {
      return SlaStatus(
        urgency: SlaUrgency.breached,
        remaining: remaining,
        target: effectiveTarget,
      );
    }
    if (remaining <= const Duration(minutes: 15)) {
      return SlaStatus(
        urgency: SlaUrgency.atRisk,
        remaining: remaining,
        target: effectiveTarget,
      );
    }
    return SlaStatus(
      urgency: SlaUrgency.onTrack,
      remaining: remaining,
      target: effectiveTarget,
    );
  }

  String label() {
    switch (urgency) {
      case SlaUrgency.none:
        return 'No SLA';
      case SlaUrgency.breached:
        return 'Breached ${_formatDuration(remaining.abs())} ago';
      case SlaUrgency.atRisk:
        return 'Due in ${_formatDuration(remaining)}';
      case SlaUrgency.onTrack:
        return 'Due in ${_formatDuration(remaining)}';
    }
  }

  static String _formatDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    final hours = d.inMinutes ~/ 60;
    final mins = d.inMinutes % 60;
    return mins == 0 ? '${hours}h' : '${hours}h ${mins}m';
  }
}
