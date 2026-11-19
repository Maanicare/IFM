# Pending Features (deferred, deliberately)

Tracking doc for Frontline app gaps that need real new data modelling
before they can be built - not just a missing screen/button on top of
data that already exists. Each one was flagged during the Screen
Contract (Section 15) audit and confirmed as "do later" rather than
rushed.

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

## Screen 10 - My Work (job card)

- Card doesn't show Location/Asset/Estimated duration, only priority/
  WO number/description/SLA/status.

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
