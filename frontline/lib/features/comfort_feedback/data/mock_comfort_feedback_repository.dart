import 'comfort_feedback_repository.dart';

class MockComfortFeedbackRepository implements ComfortFeedbackRepository {
  @override
  Future<void> pushFeedback(String feedbackId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
