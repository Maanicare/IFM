import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../core/db/app_database.dart';
import '../../../core/network/token_storage.dart';
import '../../../core/rbac/user_role.dart';
import '../domain/authenticated_user.dart';
import 'identity_repository.dart';

class HttpIdentityRepository implements IdentityRepository {
  HttpIdentityRepository(this._dio, this._db, this._tokenStorage);

  final Dio _dio;
  final AppDatabase _db;
  final TokenStorage _tokenStorage;

  @override
  Future<AuthenticatedUser> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
    );
    final data = response.data!;

    await _tokenStorage.saveTokens(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
    );

    final user = _toAuthenticatedUser(data['user'] as Map<String, dynamic>);
    await _persist(user);
    return user;
  }

  @override
  Future<AuthenticatedUser?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    final cached = await _db.identityDao.currentUser();
    if (token == null || cached == null) return null;
    return _fromCached(cached);
  }

  @override
  Future<void> logout() async {
    await _tokenStorage.clear();
    await _db.identityDao.clearCurrentUser();
  }

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
