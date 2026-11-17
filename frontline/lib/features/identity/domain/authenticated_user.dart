import '../../../core/rbac/user_role.dart';

/// Immutable snapshot of the logged-in identity, held in memory for the
/// session and mirrored into [CachedUsers] for persistence across restarts.
class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.organisationId,
    required this.siteIds,
    this.employeeId,
    this.designation,
    this.approvalLimit,
  });

  final String id;
  final String? employeeId;
  final String name;
  final String? email;
  final UserRole role;
  final String? designation;
  final String organisationId;
  final List<String> siteIds;
  final double? approvalLimit;

  UserAccessContext toAccessContext() => UserAccessContext(
        userId: id,
        role: role,
        organisationId: organisationId,
        siteIds: siteIds,
        approvalLimit: approvalLimit,
      );
}
