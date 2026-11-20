/// Closed set of mobile-relevant actions a [PolicyGuard] can evaluate.
/// Kept as an enum (rather than free-form strings) so every call site is
/// checked at compile time and `PolicyGuard.can` can exhaustively switch.
enum AppAction {
  viewWorkOrder,
  acceptWorkOrder,
  startWorkOrder,
  checkInWorkOrder,
  completeWorkOrder,
  reopenWorkOrder,
  verifyWorkOrder, // supervisor QA sign-off
  reassignWorkOrder,
  escalateWorkOrder,
  createServiceRequest,
  cancelServiceRequest,
  recordMeterReading,
  recordPartsUsage,
  manageShiftHandover,
  captureAttachment,
  submitChecklistResponse,
  approveQuoteOrSpend, // gated additionally by approvalLimit
  viewClientCommercialData,
  viewOtherClientsData,
  reportIncident,
  manageFleetTrip,
  manageCleaningTask,
}

/// The flat Frontline bottom-nav tabs (Section 14). A role's app shell
/// only renders the subset [PolicyGuard.visibleTabs] returns for it.
enum AppTab { home, myWork, scan, requests, more }
