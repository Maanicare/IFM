import 'visitor_repository.dart';

class MockVisitorRepository implements VisitorRepository {
  @override
  Future<void> pushVisit(String visitId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushCheckOut(String visitId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
