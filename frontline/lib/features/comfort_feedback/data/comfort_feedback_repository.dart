/// Pushes comfort feedback submitted on this device (Screen 46). This
/// app only ever creates these, never syncs a list down - trend
/// analysis/reporting is a manager/desktop concern.
abstract interface class ComfortFeedbackRepository {
  Future<void> pushFeedback(String feedbackId);
}
