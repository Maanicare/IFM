import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../error/exceptions.dart';
import 'action.dart';
import 'user_role.dart';

part 'policy_guard.g.dart';

/// Centralised RBAC decision engine (Section 5-6).
///
/// Every screen asks `PolicyGuard` before rendering an action trigger
/// (button, menu item, swipe action) rather than hard-coding
/// `if (role == technician)` checks scattered through widgets. This keeps
/// the access model in one auditable place and makes it possible to add a
/// new role or tighten a rule without touching UI code.
///
/// The server remains the authoritative enforcement point for every
/// mutation; this guard exists so the UI doesn't dangle controls the
/// server would reject, and as a defensive client-side backstop.
class PolicyGuard {
  const PolicyGuard();

  /// Role -> allowed actions. Roles not listed here get the empty set,
  /// i.e. the mobile app shows them nothing but read-only views.
  ///
  /// IMPORTANT: the spec (Sections 6-7) gives each role only a one-line
  /// responsibility description (e.g. "Housekeeping Supervisor |
  /// Soft-service inspections, deployment and closure") - it does not
  /// define an exact action-by-action permission matrix. This map is an
  /// implementation-level interpretation of those descriptions plus the
  /// journey/workflow sections (9-11), not a literal table copied from
  /// the document. Treat it as a draft to be confirmed by the product
  /// owner / backend team, not as spec-verified ground truth.
  static const Map<UserRole, Set<AppAction>> _rolePermissions = {
    UserRole.technician: {
      AppAction.viewWorkOrder,
      AppAction.acceptWorkOrder,
      AppAction.startWorkOrder,
      AppAction.checkInWorkOrder,
      AppAction.completeWorkOrder,
      AppAction.createServiceRequest,
      AppAction.recordMeterReading,
      AppAction.recordPartsUsage,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
      AppAction.submitChecklistResponse,
    },
    UserRole.vendorTechnician: {
      AppAction.viewWorkOrder,
      AppAction.acceptWorkOrder,
      AppAction.startWorkOrder,
      AppAction.checkInWorkOrder,
      AppAction.completeWorkOrder,
      AppAction.recordMeterReading,
      AppAction.recordPartsUsage,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
      AppAction.submitChecklistResponse,
    },
    UserRole.housekeepingEmployee: {
      AppAction.viewWorkOrder,
      AppAction.startWorkOrder,
      AppAction.completeWorkOrder,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
      AppAction.submitChecklistResponse,
      AppAction.createServiceRequest,
    },
    UserRole.housekeepingSupervisor: {
      AppAction.viewWorkOrder,
      AppAction.startWorkOrder,
      AppAction.completeWorkOrder,
      AppAction.verifyWorkOrder,
      AppAction.reassignWorkOrder,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
      AppAction.submitChecklistResponse,
      AppAction.createServiceRequest,
      AppAction.cancelServiceRequest,
    },
    UserRole.vendorSupervisor: {
      AppAction.viewWorkOrder,
      AppAction.verifyWorkOrder,
      AppAction.reassignWorkOrder,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
    },
    UserRole.siteFacilityManager: {
      AppAction.viewWorkOrder,
      AppAction.reassignWorkOrder,
      AppAction.escalateWorkOrder,
      AppAction.verifyWorkOrder,
      AppAction.reopenWorkOrder,
      AppAction.createServiceRequest,
      AppAction.cancelServiceRequest,
      AppAction.approveQuoteOrSpend,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
    },
    UserRole.technicalManager: {
      AppAction.viewWorkOrder,
      AppAction.reassignWorkOrder,
      AppAction.escalateWorkOrder,
      AppAction.verifyWorkOrder,
      AppAction.reopenWorkOrder,
      AppAction.approveQuoteOrSpend,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
    },
    UserRole.safetyEhsManager: {
      AppAction.viewWorkOrder,
      AppAction.escalateWorkOrder,
      AppAction.manageShiftHandover,
      AppAction.captureAttachment,
    },
    UserRole.helpdeskExecutive: {
      AppAction.viewWorkOrder,
      AppAction.createServiceRequest,
      AppAction.cancelServiceRequest,
      AppAction.reassignWorkOrder,
    },
    UserRole.clientFacilityAdministrator: {
      AppAction.viewWorkOrder,
      AppAction.createServiceRequest,
      AppAction.viewClientCommercialData,
    },
    UserRole.clientEmployee: {
      AppAction.createServiceRequest,
    },
    UserRole.auditor: {
      AppAction.viewWorkOrder,
    },
  };

  /// Actions that are visible for the role in principle, but also require
  /// scope (site) and in some cases an approval-limit check against the
  /// specific amount involved.
  bool can(
    UserAccessContext context,
    AppAction action, {
    String? siteId,
    double? amount,
  }) {
    final allowed = _rolePermissions[context.role] ?? const {};
    if (!allowed.contains(action)) return false;

    if (siteId != null && !context.hasSiteAccess(siteId)) return false;

    if (action == AppAction.approveQuoteOrSpend &&
        amount != null &&
        context.approvalLimit != null &&
        amount > context.approvalLimit!) {
      return false;
    }

    // Internal roles must never see another client's data; this is also
    // enforced server-side, but the client should not even render it.
    if (action == AppAction.viewOtherClientsData) return false;

    return true;
  }

  /// Which of the flat Frontline nav tabs (Section 14: Home, My Work,
  /// Scan, Requests, More) a role should even see. Derived from the same
  /// per-role action grants above rather than a second hardcoded
  /// role->tab map, so adding an action to a role automatically keeps
  /// its nav consistent with what it can actually do - a role with no
  /// work-order actions at all (e.g. a client employee, who only ever
  /// raises requests) has no reason to see "My Work" or "Scan".
  List<AppTab> visibleTabs(UserAccessContext context) {
    return [
      AppTab.home,
      if (can(context, AppAction.viewWorkOrder)) AppTab.myWork,
      if (can(context, AppAction.captureAttachment) ||
          can(context, AppAction.recordMeterReading) ||
          can(context, AppAction.recordPartsUsage))
        AppTab.scan,
      if (can(context, AppAction.createServiceRequest)) AppTab.requests,
      AppTab.more,
    ];
  }

  /// Same decision as [can], but throws [PolicyDeniedError] - used as a
  /// defensive guard immediately before firing a mutation, in case a
  /// button somehow rendered despite the role not actually being allowed
  /// (e.g. stale cached permissions).
  void ensure(
    UserAccessContext context,
    AppAction action, {
    String? siteId,
    double? amount,
  }) {
    if (!can(context, action, siteId: siteId, amount: amount)) {
      throw PolicyDeniedError(
        'Role ${context.role.name} is not permitted to perform ${action.name}'
        '${siteId != null ? ' at site $siteId' : ''}.',
      );
    }
  }
}

@Riverpod(keepAlive: true)
PolicyGuard policyGuard(Ref ref) => const PolicyGuard();
