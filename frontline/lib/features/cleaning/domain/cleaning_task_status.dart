/// Screen 21 (Cleaning Task) status sequence - deliberately minimal
/// compared to [WorkOrderStatus] since the spec doesn't describe a
/// multi-step field workflow (accept/route/check-in) for this screen,
/// only "Completion".
abstract final class CleaningTaskStatus {
  static const pending = 'pending';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
}
