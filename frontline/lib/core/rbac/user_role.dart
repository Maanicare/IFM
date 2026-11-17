/// Primary internal and external roles (Sections 6-7 of the IFM spec).
/// The P0 frontline app is primarily used by Technician/Engineer and
/// Housekeeping Employee roles, with Supervisor/Site Facility Manager
/// roles using the same app for verification and triage actions.
enum UserRole {
  superAdmin,
  organisationAdmin,
  centralCommandCentre,
  nationalAccountHead,
  regionalHead,
  siteFacilityManager,
  technicalManager,
  softServicesManager,
  safetyEhsManager,
  helpdeskExecutive,
  technician,
  housekeepingSupervisor,
  housekeepingEmployee,
  securitySupervisor,
  vendorTechnician,
  vendorSupervisor,
  clientFacilityAdministrator,
  clientEmployee,
  auditor;

  static UserRole fromWire(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name.toLowerCase() == value.toLowerCase(),
      orElse: () => UserRole.technician,
    );
  }
}

/// The full permission model is `Role + organisation + portfolio/site scope
/// + module + action + approval limit + field sensitivity` (Section 5).
/// On a mobile frontline client we evaluate a trimmed version of that:
/// role + site scope + action + approval limit - the rest is assumed
/// already enforced server-side and is irrelevant to what the device UI
/// needs to decide locally.
class UserAccessContext {
  const UserAccessContext({
    required this.userId,
    required this.role,
    required this.organisationId,
    required this.siteIds,
    this.approvalLimit,
  });

  final String userId;
  final UserRole role;
  final String organisationId;

  /// Empty list means "all sites" (used by roles like Regional Head).
  final List<String> siteIds;
  final double? approvalLimit;

  bool hasSiteAccess(String siteId) =>
      siteIds.isEmpty || siteIds.contains(siteId);
}
