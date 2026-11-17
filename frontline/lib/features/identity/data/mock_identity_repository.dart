import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/error/exceptions.dart';
import '../../../core/fixtures/fixture_loader.dart';
import '../../../core/rbac/user_role.dart';
import '../domain/authenticated_user.dart';
import 'identity_repository.dart';

/// Demo login: any password is accepted for a known identifier (matched
/// against email, mobile, or employee ID) in `assets/fixtures/users.json`.
/// This lets every P0 role be exercised end-to-end without a backend.
class MockIdentityRepository implements IdentityRepository {
  MockIdentityRepository(this._db);

  final AppDatabase _db;

  @override
  Future<AuthenticatedUser> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final list =
        await FixtureLoader.loadJson('assets/fixtures/users.json') as List;
    final match = list.cast<Map<String, dynamic>>().firstWhere(
          (u) =>
              u['email'] == identifier ||
              u['mobile'] == identifier ||
              u['employeeId'] == identifier,
          orElse: () => const {},
        );

    if (match.isEmpty) {
      throw const ApiError(
        message: 'No account found for that email, mobile or employee ID.',
        statusCode: 401,
        code: 'invalid_credentials',
      );
    }

    final user = _toAuthenticatedUser(match);
    await _persist(user);
    return user;
  }

  @override
  Future<AuthenticatedUser?> restoreSession() async {
    final cached = await _db.identityDao.currentUser();
    if (cached == null) return null;
    return _fromCached(cached);
  }

  @override
  Future<void> logout() => _db.identityDao.clearCurrentUser();

  AuthenticatedUser _toAuthenticatedUser(Map<String, dynamic> json) {
    return AuthenticatedUser(
      id: json['id'] as String,
      employeeId: json['employeeId'] as String?,
      name: json['name'] as String,
      email: json['email'] as String?,
      role: UserRole.fromWire(json['role'] as String),
      designation: json['designation'] as String?,
      organisationId: json['organisationId'] as String,
      siteIds: (json['siteIds'] as List).cast<String>(),
      approvalLimit: (json['approvalLimit'] as num?)?.toDouble(),
    );
  }

  AuthenticatedUser _fromCached(CachedUser row) {
    final siteIds = (jsonDecode(row.siteScopeJson) as List).cast<String>();
    return AuthenticatedUser(
      id: row.id,
      employeeId: row.employeeId,
      name: row.name,
      email: row.email,
      role: UserRole.fromWire(row.roleType),
      designation: row.designation,
      organisationId: row.organisationId,
      siteIds: siteIds,
      approvalLimit: row.approvalLimit,
    );
  }

  Future<void> _persist(AuthenticatedUser user) {
    return _db.identityDao.setCurrentUser(CachedUsersCompanion.insert(
      id: user.id,
      employeeId: Value(user.employeeId),
      name: user.name,
      email: Value(user.email),
      designation: Value(user.designation),
      roleType: user.role.name,
      organisationId: user.organisationId,
      siteScopeJson: Value(jsonEncode(user.siteIds)),
      approvalLimit: Value(user.approvalLimit),
      isCurrentUser: const Value(true),
    ));
  }
}
