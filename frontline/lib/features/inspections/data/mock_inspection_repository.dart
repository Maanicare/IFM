import 'inspection_repository.dart';

class MockInspectionRepository implements InspectionRepository {
  @override
  Future<void> pushInspection(String inspectionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushCorrectiveComplete(String inspectionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
