import 'permit_repository.dart';

class MockPermitRepository implements PermitRepository {
  @override
  Future<void> pushPermit(String permitId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }

  @override
  Future<void> pushClose(String permitId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}
