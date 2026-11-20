import 'inspection_repository.dart';

class MockInspectionRepository implements InspectionRepository {
  @override
  Future<void> pushInspection(String inspectionId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
