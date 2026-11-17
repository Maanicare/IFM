/// Primary work order status sequence (Section 10). Kept as string
/// constants rather than an enum because the server is the source of
/// truth for the full status vocabulary (including client-configurable
/// alternative states) - the app only needs to special-case a handful of
/// these for UI/action gating.
abstract final class WorkOrderStatus {
  static const newStatus = 'new';
  static const assigned = 'assigned';
  static const accepted = 'accepted';
  static const enRoute = 'technician_en_route';
  static const checkedIn = 'checked_in';
  static const inProgress = 'in_progress';
  static const blocked = 'waiting';
  static const resumed = 'resumed';
  static const workCompleted = 'work_completed';
  static const qaRequired = 'qa_required';
  static const verified = 'verified';
  static const closed = 'closed';
  static const cancelled = 'cancelled';

  static const terminal = {closed, cancelled};

  /// Blocker reasons (Section 11): the clock treats each differently per
  /// SLA pause rules, which are evaluated server-side - the device only
  /// needs to capture *which* blocker applied, with a mandatory reason.
  static const blockerReasons = [
    'part_unavailable',
    'vendor_required',
    'access_unavailable',
    'client_approval_required',
    'unsafe_condition',
    'specialist_required',
  ];
}
