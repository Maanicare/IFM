# Pending Features (deferred, deliberately)

Tracking doc for Frontline app gaps that need real new data modelling
before they can be built - not just a missing screen/button on top of
data that already exists. Each one was flagged during the Screen
Contract (Section 15) audit and confirmed as "do later" rather than
rushed.

## Screen 25 - Shift Roster — DONE

- **Swap** — trades shift times between two of today's roster entries
  at the same site; picker lists other employees scheduled today
  (there's no synced employee directory to pick from beyond that).
- **Replace** — `replacementUserName` (already existed as a read-only
  display field) is now settable from the device as plain text, not
  linked to a specific employee record, for the same reason.

## Screen 48 - Vehicle Profile (My Vehicle) — DONE

Trip history list, VIN, Battery and Tyres are all shown now. Battery/
Tyres are free-text condition notes (e.g. "72%", "Replace rear left"),
not sensor-fed precise values - no telematics integration exists in
this app.

## Screen 32 - Inventory Item — DONE

New dedicated profile screen (`/inventory/:id`), reached from Scan's
inventory result sheet and from Home's "Required parts" row. Shows
SKU/Name/Category/Unit/Warehouse/Site(current)/Quantity/Reserved/
Available/Min level/Reorder level/Supplier/Cost/Expiry/Serial-batch,
plus transaction history. "Warehouse" is a plain name field, not a
full multi-location balance model - this app still tracks one balance
per item per site, not per warehouse (documented in
`inventory_tables.dart`). "Reserved" is tracked but nothing in this
app currently writes to it (no reservation workflow exists here).

## Screen 33 - Stock Transaction — DONE

Receive/Transfer/Return/Repair/Scrap/Adjustment are now recordable
from the new Inventory Item screen, each requiring a reason
(`InventoryTransactions.reason`, new column). `Issue` is unchanged -
still the Work Order "Add part" flow, with its reason implicit (the
linked work order) rather than re-typed. `Transfer` only decrements
this site's balance (no second-location balance to credit, since
there's no multi-site destination picker) - closer to "stock sent
out" than a true transfer.

## Screen 35 - Incident Report — DONE

Type, Severity, Injury, Description, Immediate action, **Location**
(space picker, not just site), **Asset** link, **People involved**,
**Witnesses** (both free-text, no employee directory to pick from)
and **Photo** are all captured now. "System creates investigation
workflow" is treated as satisfied by `investigationStatus` defaulting
to `'open'` on creation - full investigation case management (owner
assignment, findings, closure) is a manager/desktop concern with no
mobile UI anywhere in this app.

## Screen 36 - Hazard / Near Miss — DONE

Hazard type, Location (space picker), **Photo** and **Voice** are now
all captured, using the same evidence-capture flow as Create Request.

## Screen 11 - Scan — DONE

NFC added via `nfc_manager`. Reads the tag's raw hardware UID (hex)
and resolves it through the same Asset/Space/Inventory/Vehicle lookup
path as a scanned QR/barcode - no NDEF content format has been
decided for OneMaanicare tags, so nothing is written to or expected
on the tag beyond its built-in UID.

**Manual step still needed on macOS/Xcode**: `ios/Runner/Runner.entitlements`
was added with the NFC reader-session entitlement, but wiring a new
entitlements file into an Xcode project's `CODE_SIGN_ENTITLEMENTS`
build setting isn't safe to do blind by editing `project.pbxproj` as
text from Windows - open the project in Xcode and add the "Near Field
Communication Tag Reading" capability under Signing & Capabilities
(it will pick up this file automatically), or point
`CODE_SIGN_ENTITLEMENTS` at it manually.

## Screen 07 - Request Detail — DONE

- **Comments** — `RequestComments` table (id, requestId, authorId,
  authorName, body, createdAt), append-only thread, pushed via its own
  `request_comment` outbox entity type. Open to any user with site
  access, not gated by a triage-specific action.
- **Related requests / Merge duplicate** — simplified to a single
  self-reference (`ServiceRequests.duplicateOfRequestId`) rather than
  a many-to-many `duplicate_links` table, since "merge" reads as one
  request pointing at the canonical one it duplicates. Picker lists
  other open requests at the same site.
- **Convert (to Work Order)** — creates a minimal Work Order directly
  (type/asset/space/site/priority/problem description from the
  request) via a new `work_order_create` outbox entity type.
  Deliberately leaves out checklist assignment and scheduling, which
  stay admin/manager-level fields with no mobile UI anywhere in this
  app - those are expected to be filled in server-side or by a
  manager after conversion.

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

## Screen 21 - Cleaning Task — DONE (with documented interpretations)

Fields (Area/Cleaning type/SOP/Frequency/Last clean/Expected duration/
Assigned employee/Materials) and Completion (Checklist/Photo if
required/Consumables used/Exception) are built. Two deliberate
interpretations, since the spec doesn't define the exact data shape:

- **Inspection points (Fields) and Checklist (Completion) are one
  structure**, not two — the predefined inspection points are what
  get checked off (Pass/Fail) at completion, rather than building a
  second parallel checklist system alongside the one [Checklists]
  already provides for work orders.
- **Consumables used is a free-text note**, not a real inventory
  deduction — wiring it into `InventoryTransactions` needs the same
  schema work already tracked above as the Screen 33 gap.

Access gated by a new `manageCleaningTask` action, granted to
Housekeeping Employee and Housekeeping Supervisor (another
interpretation — the spec doesn't name roles per screen).

## Screen 22 - Washroom Experience — DONE (with documented interpretation)

Cleaning status, Last attended, Next due, Consumables (Tissue/Soap),
Sensor alerts (free-text note, no IoT integration exists) are all
shown. **"Complaints" and the "QR Options" (Cleaning/Tissue/Soap/
Odour/Plumbing/Other) are not a separate reporting model** - the QR
options create a normal Create Request entry against the washroom's
space, and "Complaints" is just the open requests at that space. This
reuses the existing Request pipeline (tracking, SLA) instead of
building a second, parallel one.

## Screen 23 - Soft Service Inspection — DONE (with documented interpretation)

Templates (Housekeeping/Pantry/Pest/Horticulture/Mailroom/Concierge)
and Record fields (Score, Non-conformance, Photo, Corrective task,
Owner, Due date) are all captured. **One row per inspection with a
single overall Score**, not a per-item checklist with template/items/
responses like [Checklists] - the spec's "Record" list names a score,
not itemized checks, unlike Screen 21's explicit "Checklist". Owner
is a free-text name (no employee directory), and the corrective task
has no assignment/notification workflow - it's a captured field, not
a trackable task entity.

## Screen 34 - Safety Home — DONE (with documented interpretation)

Active incidents, Open hazards, Near misses, Corrective actions
overdue, Inspection score, Days without lost-time incident are all
computed client-side from the existing Incident/Hazard/Inspection
streams. **"PTW active" always shows "N/A"** - Permit to Work
(Screen 37) isn't built, so there's no Permits table to count from;
shown honestly rather than faking a zero.

"Corrective actions overdue" combines two sources: `Hazards.targetDate`
(new column, matches the canonical model, but nothing in this app's
UI sets it yet - no triage/assignment screen exists) and
`SoftServiceInspections.correctiveDueDate` (settable from Screen 23,
so this is the source that actually drives the count today). Added
`correctiveCompleted` to Soft Service Inspections and a "Done" action
here so the count doesn't grow forever.

## Screen 37 - Permit to Work — DONE (with documented interpretations)

Types (Hot work/Height/Confined space/Electrical/Excavation/Lifting/
Other) and Display fields (Risk assessment, Authorised persons,
Start/end, Controls, Isolation, Approvals) are all covered. New
`managePermit` action granted to Safety/EHS Manager, Site Facility
Manager and Technical Manager. Linked from Screen 09's Work Plan card
(an "Issue" shortcut when `permitRequired` and none exists yet, a
link to the issued permit otherwise).

- **Vendor** is a free-text name, not a link to a Vendor directory
  (this app has none).
- **Authorised persons** and **Approvals** (Issuer/Receiver) are free
  text, not links to specific employee records (no employee
  directory, same reasoning used throughout this app).
- **Risk assessment** is a text note plus an optional photo, not a
  document-management attachment.
- This app only creates/closes permits locally and pushes them - it
  never syncs a permit list down from the server.

## Screens not yet built at all (App-relevant, confirmed earlier)

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
