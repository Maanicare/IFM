import 'safety_repository.dart';

class MockSafetyRepository implements SafetyRepository {
  @override
  Future<void> pushIncident(String incidentId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushHazard(String hazardId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
