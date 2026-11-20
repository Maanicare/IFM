# Pending Features (deferred, deliberately)

Tracking doc for Frontline app gaps that need real new data modelling
before they can be built - not just a missing screen/button on top of
data that already exists. Each one was flagged during the Screen
Contract (Section 15) audit and confirmed as "do later" rather than
rushed.

## Screen 25 - Shift Roster

- **Swap / Replace** — spec lists these alongside Mark absence/Request
  relief; only the two self-service actions (on the logged-in user's
  own row) are built. Swap/Replace mean assigning a *different*
  employee to a shift, which is roster authoring, not self-service -
  needs an employee picker and is arguably a manager/desktop action,
  but the spec does list it under this screen so it should be
  confirmed rather than assumed out of scope.

## Screen 48 - Vehicle Profile (My Vehicle)

Trip history list — fixed (data already existed via
`watchTripsForDriver`, just wasn't rendered).

Still pending:
- **VIN**, **Battery**, **Tyres** — spec lists these fields; the
  `Vehicles` table has no columns for them at all. Needs new columns
  (schema bump) + fixture/repository updates, not just a UI add.

## Screen 32 - Inventory Item

No dedicated "Inventory Item" profile screen exists at all - only a
quick-info sheet from Scan and the inline "Add part" picker on a Work
Order. The `InventoryItems`/`InventoryBalances` tables only cover
SKU, Name, Category, Unit, Cost, Reorder level, and per-site Quantity.
Missing entirely: **Warehouse**, **Reserved** quantity (vs. on-hand),
**Min level** (distinct from Reorder level), **Supplier**,
**Expiry**, **Serial/batch**. Needs new columns plus an actual
profile screen, not a quick fix.

## Screen 33 - Stock Transaction

Only the "Issue" transaction type is implemented (via Work Order
"Add part"), hardcoded in `InventoryDao.recordIssue`. The spec lists
Receive/Issue/Transfer/Return/Repair/Scrap/Adjustment, and a required
"reason" field that doesn't exist in `InventoryTransactions` at all
(only `transactionType`, `quantity`, `userId`, `timestamp`). Needs a
`reason` column plus six more transaction-type flows - a bigger
feature than exists today, not a toggle to flip on.

## Screen 35 - Incident Report

Type, Severity, Injury, Description, Immediate action are captured.
Missing: **Location** (only the current site is captured, not a
specific space/location picker), **People involved**, **Asset**
link, **Photos**, **Witnesses**. "System creates investigation
workflow" also doesn't exist - an incident is just stored as a record,
nothing downstream is generated.

## Screen 36 - Hazard / Near Miss

Hazard type and Location(site-level) are captured. **Photo** and
**Voice** (both listed as "Optional") aren't wired into this screen
at all - no evidence-capture integration here, unlike the Work Order
evidence flow.

## Screen 11 - Scan

- **NFC input** — spec lists QR/Barcode/NFC; only QR/Barcode are
  implemented (`mobile_scanner` package). NFC needs a separate plugin
  (e.g. `nfc_manager`), platform entitlements, and a decision on what
  format is written to the tags - not a trivial add-on to the existing
  scan flow.

## Screen 07 - Request Detail

- **Comments** — no comment-thread data model exists for requests
  (needs a `RequestComments` table: id, requestId, authorId, body,
  createdAt). Needs: table + DAO + controller + UI thread + outbox
  sync case.
- **Related requests / Merge duplicate** — needs a duplicate-detection
  concept (a `duplicate_links` table: requestId, duplicateOfRequestId,
  mergedBy, mergedAt) and a UI to find/pick a candidate duplicate.
  Nothing in the current schema links one request to another.
- **Convert (to Work Order)** — manually creating a full Work Order
  (with checklist, scheduling, assignment) from a Request that wasn't
  auto-converted server-side. Needs a WO-creation form reusing the
  admin/manager-level fields (checklist assignment, scheduling) that
  don't have a mobile UI anywhere yet.

## Screen 09 - Work Order Detail — DONE

**Section E (Closure)** — Root cause, Work performed, Remaining
issue, Follow-up (editable text fields, `completeWorkOrder`-gated) and
QA Pass/Fail (`verifyWorkOrder`-gated) are wired up with outbox sync.
Signature was already done.

**Section A** — the Problem card now links back to the originating
Request (`requestId`) when one exists.

**Section B (Asset Context)** — Health score, Warranty, Last
maintenance and Manuals are now shown directly in the Asset context
card (previously only reachable one tap away on the Asset Profile
screen).

**Section C (Work Plan)** — Tools (`requiredToolsNote`) and planned
Parts (new `WorkOrderPlannedParts` table, distinct from Section D's
"parts consumed") are now shown in a Work Plan card; Permit
requirement is shown as a flag/type only (`permitRequired`/
`permitType` on the Work Order) — the full Permit-to-Work workflow
(Screen 37) is still not built. Safety controls remain only partially
covered by the generic 3-question Safety Gate, not a per-WO controls
list.

## Screens not yet built at all (App-relevant, confirmed earlier)

- Screen 21 — Cleaning Task
- Screen 22 — Washroom Experience
- Screen 23 — Soft Service Inspection
- Screen 34 — Safety Home
- Screen 37 — Permit to Work
- Screen 42 — Workplace Experience
- Screen 43 — Reservation
- Screen 44 — Visitor Management
- Screen 46 — Comfort Feedback
- Screen 53 — AI Assistant (explicitly deferred - "AI later")

## Other known gaps (from earlier audits)

- SSO: UI only, no real identity provider.
- Biometric: works end-to-end in mock mode only; a real backend needs
  a refresh-token endpoint, not a password re-submit.
- Voice-to-workflow parser: keyword-based, not NLP.
- Localisation: only Login/nav/Home are translated; rest of the app is
  English-only. Marathi/Tamil/Telugu/Kannada/Bengali not started
  (spec marks these "Future", not initial scope).
- Voice input locale isn't tied to the in-app language selector (uses
  device system locale only).
