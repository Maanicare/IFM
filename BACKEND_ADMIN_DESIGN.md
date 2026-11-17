# OneMaanicare IFM Platform — Fresh Backend & Admin Panel Design
Source: `IFM v2.docx` (Master Jira Epic & Product Definition) — every section (1–75 + Appendices A/B) mapped below. No other file/context used.

---

## 0. Scope Statement

This is a **ground-up backend + admin panel design**, derived exclusively from the product definition doc. It covers:
- Full canonical data model (every entity in §26–51, extended where the doc implies sub-entities)
- Service/module architecture matching §73 Child Epics (IFM-001 → IFM-030)
- Role/permission engine (§5–8)
- Workflow & SLA engine (§9–12, §31, §64)
- Admin Panel — every screen, every manageable object (§54, Screen 54, Appendix B)
- API layer (§55–56)
- AI layer boundary (§53–54)
- Non-functional, security, privacy (§57–61)
- Event/audit/notification model (§51–52, §65)
- Dev priority mapping (§70)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  CLIENTS                                                          │
│  Mobile (Technician/Field) | Web App (Manager/Exec) | Admin Panel │
│  Client Portal | Vendor Portal | AI Chat Surface                  │
└───────────────────────────┬─────────────────────────────────────┘
                             │ REST + GraphQL (read-heavy/dashboards)
┌───────────────────────────▼─────────────────────────────────────┐
│  API GATEWAY  (AuthN, AuthZ scope injection, rate limiting,       │
│                request logging, API versioning)                  │
└───────────────────────────┬─────────────────────────────────────┘
                             │
┌───────────────────────────▼─────────────────────────────────────┐
│  CORE DOMAIN SERVICES (bounded contexts = Child Epics)           │
│  Identity&RBAC | Location | Request | WorkOrder | SLA/Escalation │
│  Asset | PM/PdM | Checklist/Inspection | SoftServices | Workforce │
│  Inventory | Vendor/Contract | Procurement/Approval | Safety/PTW │
│  Compliance | Workplace | Space/Occupancy | Visitor | Energy/ESG │
│  Fleet | IoT/BMS Gateway | Projects/CAPEX | Notification         │
│  Document | Audit | Admin/Config                                 │
└───────────────────────────┬─────────────────────────────────────┘
                             │ Events (async)
┌───────────────────────────▼─────────────────────────────────────┐
│  EVENT BUS / MESSAGE QUEUE  (Kafka/RabbitMQ/SNS+SQS class)        │
│  — SLA engine, Notification engine, Audit, Analytics, AI feed     │
└───────────────────────────┬─────────────────────────────────────┘
                             │
┌───────────────────────────▼─────────────────────────────────────┐
│  INTELLIGENCE LAYER (non-authoritative)                          │
│  Analytics/BI engine | Impact Graph engine | AI Assistant |       │
│  SLA Predictor | Vendor Fairness Engine | Auto-MMR generator      │
└───────────────────────────┬─────────────────────────────────────┘
                             │
┌───────────────────────────▼─────────────────────────────────────┐
│  DATA LAYER                                                       │
│  OLTP relational DB (core transactional entities)                 │
│  Time-series DB (sensor_readings, utility_readings, telemetry)    │
│  Document/object storage (attachments, documents, exports)        │
│  Search index (universal search §63)                              │
│  Analytics warehouse / OLAP (BI, MMR, KPI library)                 │
│  Cache layer (dashboard reads, role/permission resolution)        │
└────────────────────────────────────────────────────────────────┘
```

**Architecture principles enforced (Appendix B, directly):**
1. One authoritative master record per entity — no asset/building/user duplicated across modules; every module references the same `assets`, `spaces`, `users` tables by FK, never copies.
2. Configuration before custom code — SLA rules, approval rules, checklists, PM triggers, workflows are **data-driven** (JSON rule configs in Admin), not hardcoded per client.
3. Every entity has an audit/event trail by default (`audit_logs` + domain `*_status_history` tables).
4. Mobile-first service contracts for frontline-facing endpoints (small payloads, offline sync tokens).
5. Exception-first query patterns for manager APIs (every list endpoint supports a `risk`/`exception` filter server-side, not client-filtered).
6. Outcome-first for executive APIs — dashboard endpoints return pre-aggregated KPI objects, never raw rows.
7. AI layer is read/propose-only; never writes directly to transactional tables (§53).
8. API-first (§55–56) — every domain service exposes versioned REST + selected GraphQL.
9. Privacy by minimisation (§59) — no continuous location tracking; occupancy is aggregate count by default (§45, §907).
10. Evidence-backed closure — `work_orders.qa_required`, `checklist_responses`, `attachments` enforced at closure state transition, not optional UI.
11. Normalised cross-site analytics — all BI metrics stored/computed with a `normalisation_basis` (₹/sqft, kWh/sqft, requests/100 occupants) per §25, §51.
12. Every dashboard query ties to a decision — enforced by requiring each BI widget definition (admin-configured) to declare `supported_actions[]`.

---

## 2. Bounded Contexts / Services (maps 1:1 to §73 Child Epics)

| # | Service (Jira Epic) | Primary Tables Owned | Depends On |
|---|---|---|---|
| IFM-001 | Identity, Clients & RBAC | organisations, users, roles, user_role_scope, auth_sessions | — |
| IFM-002 | Portfolio, Sites & Spatial Hierarchy | sites, buildings, floors, spaces | IFM-001 |
| IFM-003 | Request Management | service_requests, request_categories, duplicate_links | IFM-001,002 |
| IFM-004 | Work Order Management | work_orders, work_order_status_history | IFM-003, Asset, SLA |
| IFM-005 | SLA & Escalation Engine | sla_definitions, sla_instances, escalation_rules, calendars | IFM-004 |
| IFM-006 | Technician Mobile / Offline Sync | sync_queue, offline_payload_log, device_sessions | IFM-004 |
| IFM-007 | Asset Lifecycle Management | assets, asset_meters, meter_readings, asset_categories | IFM-002 |
| IFM-008 | Preventive & Predictive Maintenance | pm_plans, pm_schedule_runs, condition_monitoring_alerts | Asset |
| IFM-009 | Inspections & Checklists | checklists, checklist_items, checklist_responses | WorkOrder |
| IFM-010 | Soft Services & Housekeeping | cleaning_tasks, washroom_status, inspection_templates | Space |
| IFM-011 | Workforce & Deployment | shift_rosters, attendance, shift_handovers, skills | IFM-001 |
| IFM-012 | Inventory & Spare Parts | inventory_items, inventory_locations, inventory_balances, inventory_transactions | WorkOrder |
| IFM-013 | Vendor & Contract Management | vendors, vendor_documents, contracts, vendor_scores | IFM-001 |
| IFM-014 | Procurement, Quotes & Approvals | quotations, approval_requests, approval_rules | Vendor, Finance |
| IFM-015 | Health, Safety & Permit-to-Work | incidents, hazards, permits | Space, Asset |
| IFM-016 | Compliance & Audit | compliance_items, licences, audit_logs | all |
| IFM-017 | Workplace Experience | reservations, comfort_feedback | Space |
| IFM-018 | Space & Occupancy | occupancy_events, space_utilisation_snapshots | Space |
| IFM-019 | Visitor Management | visitors, visits, passes | Space, Security |
| IFM-020 | Energy, Utilities & ESG | utility_meters, utility_readings, esg_factors | Asset, Sensor |
| IFM-021 | Fleet & Vehicle Operations | vehicles, trips, telemetry_events | IFM-001 |
| IFM-022 | IoT, BMS & Smart Building Integration | sensors, sensor_readings, integration_configs | all telemetry consumers |
| IFM-023 | Projects & CAPEX | projects, project_milestones, variations | Vendor, Finance |
| IFM-024 | Analytics & Executive Intelligence | kpi_definitions, kpi_snapshots, dashboards_config | all (read-only) |
| IFM-025 | Monthly Management Reporting | mmr_templates, mmr_reports, mmr_sections | Analytics |
| IFM-026 | AI Assistant & Knowledge Layer | ai_queries, ai_proposed_actions, knowledge_embeddings | all (read-only) |
| IFM-027 | Operational Impact Graph | entity_relationships, impact_simulations | Asset, Space, WorkOrder |
| IFM-028 | Notification & Communication Engine | notification_templates, notification_log, preferences | all |
| IFM-029 | Integration Platform & APIs | integration_connectors, webhook_subscriptions, api_keys | all |
| IFM-030 | Platform Administration & Configuration | config_master tables (categories, custom_fields, workflow_defs, approval_rules, sla_definitions ownership, feature_flags) | all |

---

## 3. Full Canonical Data Model (every field from §26–51, normalized + gaps filled)

> Every table below is sourced from the doc. Where the doc defines only parent/header rows (e.g. "Attachments"), full field lists from the doc are kept verbatim; implied child/reference tables needed to make the model functional (category lookups, calendars) are marked **[inferred-support table]** — required for the fields in doc to actually resolve (e.g. `category_id` needs a `categories` table), not scope additions.

### 3.1 Identity & Access (§26)
- **organisations**: id, name, legal_name, type, parent_id, timezone, currency, status, created_at, updated_at
- **users**: id, employee_id, name, email, mobile, organisation_id, designation, department, preferred_language, status, authentication_provider, created_at
- **roles**: id, name, role_type, permissions_json, status
- **user_role_scope**: user_id, role_id, organisation_id, portfolio_id, site_id, building_id, approval_limit, valid_from, valid_to
- **[inferred-support] portfolios**: id, name, client_id, organisation_id — referenced by `portfolio_id` in user_role_scope and §13/§50 portfolio screens, never separately defined in doc but structurally required (sits between client and site).
- **[inferred-support] field_sensitivity_rules**: role_id, field_path, visibility — required to implement §108 "field sensitivity" and §312/§1046 HR/commercial masking rules.
- **auth_sessions**: id, user_id, device_id, token_hash, mfa_verified, created_at, expires_at — required for §58 SSO/MFA/session control.

### 3.2 Location Hierarchy (§27)
- **sites**: id, client_id, code, name, address(JSON), latitude, longitude, timezone, area_sqft, operational_status
- **buildings**: id, site_id, name, area_sqft, floors
- **floors**: id, building_id, name, floor_number, area_sqft, floorplan_url
- **spaces**: id, floor_id, space_code, name, space_type, capacity, area_sqft, department_id, criticality, reservable

### 3.3 Requests (§28)
- **service_requests**: id, request_number, requester_id, site_id, space_id, asset_id, category_id, subcategory_id, title, description, priority, severity, status, source, created_at, response_due_at, resolution_due_at, closed_at, satisfaction_rating
- **[inferred-support] request_categories** / **request_subcategories**: id, name, parent_category_id, default_priority, trade — required to resolve `category_id`/`subcategory_id` and Admin §391 "Categories" management.
- **[inferred-support] duplicate_links**: request_id, duplicate_of_request_id, merged_by, merged_at — required by §253 "Duplicate detection", Screen 07 "Merge duplicate".

### 3.4 Work Orders (§29–30)
- **work_orders**: id, wo_number, request_id, type, asset_id, space_id, priority, status, team_id, assigned_user_id, vendor_id, scheduled_start, scheduled_end, actual_start, actual_end, estimated_minutes, actual_minutes, failure_code, root_cause_code, resolution_code, estimated_cost, actual_cost, qa_required, qa_status
- **work_order_status_history**: id, work_order_id, from_status, to_status, changed_by, reason, timestamp
- **[inferred-support] work_order_blockers**: work_order_id, blocker_type (Part unavailable/Vendor required/Access unavailable/Client approval/Unsafe/Specialist required), raised_at, resolved_at, sla_treatment — required to implement §181–182 blocker-aware SLA clock.

### 3.5 SLA (§31)
- **sla_definitions**: id, client_id, service_category, priority, response_minutes, resolution_minutes, calendar_id, pause_rules(JSON), escalation_rules(JSON)
- **sla_instances**: id, request_id, sla_definition_id, response_target, resolution_target, response_actual, resolution_actual, pause_seconds, status
- **[inferred-support] working_calendars**: id, name, timezone, working_days(JSON), holidays(JSON) — referenced by `calendar_id`, required by §1110 "configured working calendars".

### 3.6 Assets (§32–33)
- **assets**: id, asset_code, qr_code, parent_asset_id, site_id, space_id, category_id, name, manufacturer, model, serial_number, commissioned_date, purchase_date, purchase_cost, replacement_value, criticality, status, health_score, vendor_id, warranty_end_date, expected_life_years
- **[inferred-support] asset_categories/asset_classes**: id, name, parent_category_id — resolves `category_id` and §688 `asset_class_id` in pm_plans, and §438 KPI "Asset Health Score" grouping.
- **asset_meters**: id, asset_id, meter_type, unit, current_value, updated_at
- **meter_readings**: id, meter_id, value, captured_at, source, captured_by

### 3.7 PM Plans (§34)
- **pm_plans**: id, asset_id, asset_class_id, site_id, name, trigger_type, frequency_value, frequency_unit, meter_threshold, checklist_id, estimated_minutes, vendor_id, active
- **[inferred-support] pm_schedule_runs**: pm_plan_id, scheduled_date, generated_work_order_id, status (Scheduled/Completed/Missed) — required for Screen 15 PM Calendar states.

### 3.8 Checklists (§35)
- **checklists**: id, name, version, category, active
- **checklist_items**: id, checklist_id, sequence, question, input_type, required, min_value, max_value, failure_action
- **checklist_responses**: id, work_order_id, item_id, response(JSON), captured_by, captured_at

### 3.9 Attachments & Documents (§36, §50)
- **attachments**: id, entity_type, entity_id, file_type, file_url, caption, uploaded_by, created_at, metadata(JSON)
- **documents**: id, entity_type, entity_id, document_type, title, version, effective_date, expiry_date, url, status

### 3.10 Inventory (§37)
- **inventory_items**: id, sku, name, category, unit, preferred_vendor, unit_cost, reorder_level, minimum_stock, serialized
- **inventory_locations**: id, site_id, name, type
- **inventory_balances**: item_id, location_id, quantity, reserved_quantity
- **inventory_transactions**: id, item_id, from_location, to_location, transaction_type (Receive/Issue/Transfer/Return/Repair/Scrap/Adjustment), quantity, work_order_id, user_id, timestamp — reason+user mandatory per §335

### 3.11 Vendor & Contracts (§38–40)
- **vendors**: id, legal_name, trade_name, GSTIN, service_categories(JSON), service_locations(JSON), status, risk_rating, preferred
- **vendor_documents**: vendor_id, document_type, document_number, issue_date, expiry_date, file_url, verification_status
- **contracts**: id, vendor_id, client_id, site_id, contract_number, start_date, end_date, value, SLA(JSON), terms_url, status
- **vendor_scores**: vendor_id, period_start, period_end, speed_score, quality_score, cost_score, SLA_score, compliance_score, first_time_fix, overall_score
- **[inferred-support] vendor_fairness_adjustments**: vendor_score_id, delay_attributed_to (vendor/client_approval/part_availability/site_access/force_majeure), minutes_excluded — required by §416 Vendor Fairness Engine.
- **quotations**: id, work_order_id, vendor_id, amount, tax, valid_until, scope, file_url, status, submitted_at

### 3.12 Safety & Compliance (§41–44)
- **incidents**: id, incident_number, site_id, space_id, type, severity, occurred_at, reported_by, description, asset_id, injury_boolean, immediate_action, investigation_status, root_cause, closed_at
- **hazards**: id, site_id, space_id, category, description, risk_probability, risk_consequence, risk_score, status, owner, target_date
- **permits**: id, permit_number, site_id, work_order_id, permit_type, vendor_id, valid_from, valid_to, risk_assessment_url, issuer_id, receiver_id, status
- **[inferred-support] compliance_items**: id, statutory_task, authority, site_id, asset_id, frequency, due_date, owner, certificate_doc_id, status — required by Screen 38 Compliance Calendar.
- **utility_meters**: id, site_id, asset_id, utility_type, meter_number, unit, provider
- **utility_readings**: id, meter_id, reading, timestamp, source, cost

### 3.13 Occupancy / Workplace / Visitor (§45–47)
- **occupancy_events**: id, space_id, timestamp, count, source — **aggregate count only**, no PII movement trail (§907 constraint enforced at schema level — no `person_id` column by design)
- **reservations**: id, space_id, organiser_id, start_time, end_time, attendee_count, purpose, services(JSON), status, checked_in
- **visitors**: id, name, organisation, mobile, email
- **visits**: id, visitor_id, host_id, site_id, scheduled_arrival, actual_arrival, actual_departure, purpose, status, pass_id

### 3.14 Fleet (§48)
- **vehicles**: id, registration, type, make, model, VIN, odometer, fuel_type, assigned_driver, status, insurance_expiry, PUC_expiry, service_due_date
- **trips**: id, vehicle_id, driver_id, start_time, end_time, start_odometer, end_odometer, route(JSON), fuel_used
- **telemetry_events**: id, vehicle_id, event_type, value(JSON), timestamp

### 3.15 Sensors (§49)
- **sensors**: id, site_id, space_id, asset_id, sensor_type, unit, status
- **sensor_readings** *(time-series store, not OLTP)*: sensor_id, timestamp, value, quality_flag

### 3.16 Audit (§51)
- **audit_logs**: id, user_id, event_type, entity_type, entity_id, old_values(JSON), new_values(JSON), ip_address, device_id, timestamp — **immutable, no UPDATE/DELETE grants to any application role**

### 3.17 Platform/Admin Support Tables **[inferred-support, required by Screen 54 & Admin module list]**
- **custom_fields**: entity_type, field_key, label, input_type, required, options(JSON), applies_to_org_id
- **workflow_definitions**: id, entity_type, states(JSON), transitions(JSON), applies_to_org_id
- **approval_rules**: id, entity_type, condition(JSON: amount/site/client/category/risk/vendor/asset_criticality), approver_role, escalation_path
- **notification_templates**: id, trigger_event, channel, template_body, applies_to_org_id
- **integration_connectors**: id, type (HRMS/ERP/BMS/SCADA/IoT/AccessControl/Attendance/Visitor/Calendar/M365/Workspace/GIS/BIM/CAD/Utility/GPS/FuelCard/WhatsApp/Email/SMS/Payment), config(JSON, secrets vaulted), status
- **feature_flags**: id, key, scope(org/site), enabled

### 3.18 Analytics / KPI / BI (§17–25, §67)
- **kpi_definitions**: id, name, formula, category, normalisation_basis
- **kpi_snapshots**: kpi_id, scope_type(site/vendor/portfolio), scope_id, period_start, period_end, value
- **dashboards_config**: id, role_type, widgets(JSON), supported_actions(JSON)
- **mmr_templates / mmr_reports / mmr_sections**: per §384–387, §419 Auto-MMR — sections: Executive summary, Deployment, Attendance, Consumables, Machine status, Energy, System health, Housekeeping, Technical, F&B, Vendor performance, Checklist compliance, Training, Incidents, Value adds, Way forward.

### 3.19 AI / Impact Graph (§16.1–16.16, §53–54)
- **entity_relationships**: id, source_entity_type, source_id, target_entity_type, target_id, relationship_type, weight — backbone of §395 Operational Impact Graph
- **impact_simulations**: id, trigger_entity_type, trigger_id, simulated_change, affected_entities(JSON), estimated_urgency, created_by, created_at — for §397 Change Impact Simulator
- **ai_queries**: id, user_id, query_text, answer_text, source_record_refs(JSON), confidence, created_at — enforces §390/§1027 "AI must show source records"
- **ai_proposed_actions**: id, ai_query_id, action_type, payload(JSON), status(pending/approved/rejected), approved_by — enforces §1026 "high-risk actions require human approval"
- **knowledge_embeddings**: entity_type, entity_id, content_chunk, embedding_vector, updated_at — powers §402 Facility Memory

### 3.20 Workforce (§24, Screens 24–26) **[inferred-support]**
- **shift_rosters**: id, user_id, role, shift_start, shift_end, site_id, attendance_status, replacement_user_id
- **shift_handovers**: id, site_id, outgoing_shift_id, incoming_shift_id, open_jobs(JSON), equipment_issues(JSON), temp_fixes(JSON), vendor_expected(JSON), safety_concerns(JSON), client_commitments(JSON), material_shortages(JSON), special_instructions(text), acknowledged_by, acknowledged_at
- **skills**: user_id, skill_code, proficiency, certified_until

### 3.21 Projects/CAPEX (§49 Screen, §1168)
- **projects**: id, name, site_id, scope, budget, actual_cost, owner, contractor_vendor_id, risk, progress, status
- **project_milestones**: project_id, name, due_date, status
- **variations**: project_id, description, cost_delta, approved_by

### 3.22 ESG (§41 Screen) **[inferred-support]**
- **esg_factors**: id, utility_type, factor_value, factor_version, effective_date, source — preserves §358 "traceability: source, factor, version, calculation date" for every carbon calc.

---

## 4. Role & Permission Engine (§5–8, §108)

Permission resolution is **not** a static role table lookup. Every authorization check resolves:

```
effective_permission =
    f(role.permissions_json,
      user_role_scope.organisation_id / portfolio_id / site_id / building_id,
      module,
      action,
      approval_limit,
      field_sensitivity_rules)
```

**Backend implementation:**
- `PermissionResolver` service: given `(user_id, module, action, target_entity)` → returns `ALLOW | ALLOW_WITH_LIMIT(amount) | DENY | ALLOW_MASKED(field_list)`.
- Every API controller calls `PermissionResolver` before executing — no controller-level hardcoded role checks.
- Approval amount checks (§109, §1058–1059 example rules: `<₹10,000 → FM; ₹10,000–50,000 → Regional Head; >₹50,000 → Client+Commercial`) are stored in `approval_rules` and evaluated by an `ApprovalEngine` service, never hardcoded in business logic.
- Field sensitivity (HR data, salary, commercial, incident) is enforced at the **serializer** layer: every response DTO passes through a `FieldSensitivityFilter` keyed by requesting role before leaving the service boundary (§108, §312, §1046).

**Roles catalog implemented exactly as per §6–7:**
Internal: Super Admin, Organisation Admin, Central Command Centre, National Account Head, Regional Head, Site Facility Manager, Technical Manager, Soft Services Manager, Safety/EHS Manager, Helpdesk Executive, Engineer/Technician, Housekeeping Supervisor, Housekeeping Employee, Security Supervisor, F&B/Pantry Manager, Store/Warehouse Manager, Procurement Manager, Commercial/Finance, Auditor, Fleet Manager, Driver.
External: Client Enterprise Owner, Client Facility Administrator, Client Procurement, Client Finance, Client Employee, Client Auditor, Vendor Administrator, Vendor Supervisor, Vendor Technician, Visitor.

Each seeded as a `roles` row with a default `permissions_json` template; Admin Panel allows cloning/editing per client.

---

## 5. Workflow / State Machines

### 5.1 Request → Work Order (§10, exact states)
```
New → Under Triage → Accepted → Work Order Created → Assigned →
Technician En Route → Checked In → In Progress →
Waiting for Part/Vendor/Approval → Resumed → Work Completed →
QA Required → Verified → Requester Confirmed → Closed
```
Alternate terminal/branch states: `Duplicate`, `Rejected`, `Cancelled`, `Unable to Access`, `Out of Scope`.
- Every transition writes a `work_order_status_history` row (mandatory, §617).
- `WorkflowEngine` reads `workflow_definitions` (per entity_type, per org) rather than hardcoding transitions — allows per-client state customization without code change (Appendix B principle 2).
- Blocker-aware SLA: entering `Waiting for Part/Vendor/Approval` triggers `work_order_blockers` row; `SLAEngine` consults `sla_definitions.pause_rules` to decide whether the specific blocker pauses the clock, rather than a blanket pause (§182).

### 5.2 SLA Engine
- Computes `response_target`/`resolution_target` at request creation from `sla_definitions` matched by (client, category, priority) and `working_calendars`.
- Background job recalculates `sla_instances.status` continuously; publishes `SLA_warning` and `SLA_breached` events (§65) consumed by Notification Engine and SLA Breach Predictor.
- **SLA Breach Predictor** (§399) is a separate read-model service: inputs = current status, assignee location/ETA, historical job-duration distribution, parts availability, vendor response history → outputs predicted breach probability + ETA, surfaced via `/predictions/sla-risk` — never writes to `sla_instances` directly (AI-layer boundary rule).

### 5.3 Approval Engine (§64)
- Rule-driven (`approval_rules`), evaluated against entity amount/site/client/category/risk/vendor/asset_criticality.
- Produces `approval_requests` with assigned approver(s) and escalation path; supports multi-level (FM → Regional → Client+Commercial) as a rule chain, not fixed code.

### 5.4 PM Scheduling Engine
- Nightly/triggered job evaluates `pm_plans` (trigger_type = calendar/meter/condition) against `asset_meters.current_value` or calendar cadence → generates `pm_schedule_runs` + auto-creates `work_orders` (type=PM) with linked `checklist_id`.

### 5.5 Impact Graph / Simulation Engine (§16.1–16.2)
- `entity_relationships` graph traversed on asset/space change events to compute "blast radius" (people affected, spaces affected, dependent assets) — exposed as `/impact/{entity_type}/{id}` for both reactive alerts (Operational Impact Graph) and proactive "what else moves if this moves" simulation (Change Impact Simulator). Graph writes happen only via Admin/engineering config or inferred from asset hierarchy — never user ad hoc.

### 5.6 Notification Engine (§52, §65)
- Subscribes to event bus; matches `notification_templates` by trigger_event + channel (push/email/SMS/WhatsApp/in-app); respects per-user `preferences` except where `critical=true` (safety) which bypasses opt-out and follows `escalation_rules`.

---

## 6. API Layer (§55–56)

- **REST** — primary CRUD + mobile sync endpoints. Versioned `/v1/...`, resource-oriented (`/sites/{id}/assets`, `/work-orders/{id}/status`, etc.)
- **GraphQL** — dashboard/aggregation queries (Executive Portfolio, Site Comparison, Analytics) where clients need flexible field selection without N+1 REST calls.
- **Webhooks/Event bus** — outbound events for operational updates (status changes, SLA breach, approvals) to integration_connectors.
- **Message queue** — IoT telemetry ingestion, notification dispatch, workflow events, async analytics recompute.
- **Offline sync contract (mobile)**: `/sync/pull` (assigned jobs, asset data, checklists since last_sync_token) and `/sync/push` (queued photos/notes/checklist responses/parts usage) with conflict surfaced (not silently overwritten) per §1039 — implemented via `sync_queue` + optimistic version numbers on `work_orders`/`checklist_responses`.

### Integration connectors (exact list, §1032)
HRMS, ERP, Accounting, Procurement, BMS, SCADA, IoT platforms, Access control, Attendance, Visitor systems, Calendar, Microsoft 365, Google Workspace, GIS, BIM, CAD, Utility APIs, GPS providers, Fuel cards, WhatsApp, Email, SMS, Payment/invoice platforms.

---

## 7. AI Layer Boundary (§53–54, §16.3/16.4/16.9/16.12/16.13)

Hard rule enforced in architecture: **AI services have read-only DB credentials to all domain services and write access only to `ai_queries` / `ai_proposed_actions` / `knowledge_embeddings`.** Any action AI proposes (e.g., "create work order for failed pump") is inserted as `ai_proposed_actions(status=pending)` and must be confirmed through the normal `WorkOrderService.create()` by a human (or auto-approved only if the action is explicitly configured as low-risk in `approval_rules`).

AI capabilities implemented as separate microservices, each consuming read replicas / analytics warehouse:
- NL facility search, request classification, duplicate detection, WO summaries, voice transcription, knowledge retrieval, root-cause suggestion, SLA prediction, energy anomaly explanation, vendor insight, MMR generation, predictive maintenance, impact analysis, portfolio briefing.
- Every answer returned with `source_record_refs`, `time_period`, `confidence` fields (§1027) — enforced at the AI response DTO level, not optional.

---

## 8. Admin Panel — Full Module Design (Screen 54 + Appendix B, exhaustively expanded)

The Admin Panel is the configuration surface for every "Configuration before custom code" object in the system. Structure:

### 8.1 Organisation & Tenancy
- Organisations (create/edit hierarchy, parent_id tree)
- Clients (under organisation; maps to `sites.client_id`)
- Portfolios (group of sites per client/region)
- Sites / Buildings / Floors / Spaces (CRUD + CAD/BIM import, floorplan upload)

### 8.2 Identity & Access
- Users (create, HRMS/SSO sync status, designation/department, status)
- Roles (create/clone role, edit `permissions_json` via a module×action matrix UI)
- User Access Grants (assign role + org/portfolio/site/building scope + approval_limit + validity window) — this is the UI for `user_role_scope`
- Field Sensitivity Rules (per role, mark fields hidden/masked — salary, commercial, incident PII)
- SSO/MFA configuration, session policy, device management policy

### 8.3 Workflow & Rules Configuration
- Workflow Definitions (states/transitions per entity_type, per org) — visual state-machine editor
- SLA Definitions (per client × category × priority → response/resolution minutes, calendar, pause rules, escalation rules)
- Working Calendars (working days, holidays, timezone)
- Approval Rules (condition builder: amount/site/client/category/risk/vendor/asset criticality → approver chain)
- Escalation Policies (critical safety/incident escalation independent of general SLA escalation)

### 8.4 Categories & Templates
- Request Categories / Subcategories (with default priority, trade mapping)
- Asset Categories / Classes
- Checklist Library (create/version checklist + items: sequence, question, input_type, required, min/max, failure_action)
- PM Plan Templates (trigger type, frequency, meter threshold, linked checklist, estimated minutes, vendor)
- Inspection Templates (Housekeeping/Pantry/Pest/Horticulture/Mailroom/Concierge — per §308)
- Notification Templates (trigger_event × channel × body, per org)
- Custom Fields (entity_type, field key, label, input type, required, options, org scope)

### 8.5 Asset & Inventory Masters
- Asset Register bulk import/export, QR code generation/reprint
- Inventory Items master (SKU, category, unit, preferred vendor, reorder/min levels, serialized flag)
- Inventory Locations (warehouse/site store setup)

### 8.6 Vendor & Contract Administration
- Vendor onboarding workflow (qualification checklist, document upload, verification status)
- Vendor Document expiry tracking (GSTIN, insurance, certifications)
- Contracts (SLA terms, value, dates, status)
- Vendor Scorecard weighting configuration (speed/quality/cost/SLA/compliance/first-time-fix weight sliders) + Vendor Fairness Engine exclusion rules

### 8.7 Compliance & Safety Administration
- Compliance Calendar master (statutory task × authority × site/asset × frequency × owner)
- Permit-to-Work types & required controls configuration
- Incident/Hazard category taxonomy and severity matrix configuration

### 8.8 Energy / ESG Administration
- Utility meter registration (site/asset mapping, provider)
- ESG emission factors (value, version, effective date, source) — versioned, never overwritten in place (§358 traceability)

### 8.9 Integration & API Administration
- Integration Connectors (configure HRMS/ERP/BMS/SCADA/IoT/Access/Attendance/Visitor/Calendar/M365/Workspace/GIS/BIM/CAD/Utility/GPS/FuelCard/WhatsApp/Email/SMS/Payment connectors — credentials vaulted, test-connection action)
- API Keys / webhook subscriptions management
- Event/Webhook subscription management (choose which of the §65 events trigger outbound webhooks)

### 8.10 Analytics & Reporting Administration
- KPI Library management (formula editor per §17–24 KPI definitions)
- Dashboard Widget Configuration (per role_type home screen, per §146–152 home experiences) — define which KPI cards/visualizations/exception queues appear, and each widget's `supported_actions` (Appendix B rule 6)
- MMR Template Builder (section ordering, auto vs manual content per §384–387)
- Data Quality Rule configuration (§1062 — define completeness checks per master-data domain, e.g. asset: serial number present, location valid, category present, criticality defined, warranty present, PM assigned, photo present, QR assigned)

### 8.11 Platform-Level (Super Admin only)
- Feature flags (per org/site rollout control)
- Global system settings (default language set: English/Hindi + extensible per §61)
- Audit log viewer (read-only, immutable, filterable by user/entity/date — no edit/delete UI exists, by design)
- Localization string management
- Accessibility settings baseline (WCAG AA enforcement toggles, not overridable per client)

---

## 9. Non-Functional / Security / Privacy (§57–61) — Backend-Level Enforcement

| Requirement | Backend Mechanism |
|---|---|
| 99.9% availability | Multi-AZ deployment, health-checked service mesh, graceful degradation of AI/Analytics layer without affecting core transactional path |
| Offline technician app | Local-first mobile DB (SQLite/Realm) + `sync_queue`; conflicts flagged, never auto-overwritten |
| Dashboard < 3s, mobile actions < 2s | Pre-aggregated `kpi_snapshots`, Redis cache layer on dashboard queries, CDN for static assets |
| Scale: multi-client, thousands of sites, millions of WOs | Horizontal sharding by `organisation_id`/`site_id`, time-series DB isolated from OLTP for telemetry |
| SSO/MFA/RBAC/scope permissions | Central `PermissionResolver`, OAuth2/OIDC-based SSO integration |
| Encryption in transit/at rest | TLS everywhere, column-level encryption for GSTIN/PII/financial fields |
| Audit logging | `audit_logs` immutable table, write-only app role |
| Rate limiting / secure file scanning | Gateway-level rate limiter; all `attachments`/`documents` uploads pass through AV/malware scan before `file_url` is persisted |
| Field-level restriction (commercial/HR/incident/personal data) | `FieldSensitivityFilter` at serializer layer |
| Privacy — no continuous location, no covert surveillance | `occupancy_events` stores aggregate `count` only, no per-person identity; technician location captured only at discrete check-in actions, not continuously polled |
| Accessibility WCAG AA | Enforced in shared component library used across Web/Admin — contrast, screen-reader labels, large tap targets, keyboard nav |
| Localization | All user-facing strings keyed via i18n service; voice input pipeline allows local-language audio in, structured English fields out where required |

---

## 10. Event Catalog (§65 — implemented as the canonical event bus topic list)

`request_created`, `request_assigned`, `request_escalated`, `work_started`, `work_paused`, `work_resumed`, `work_completed`, `QA_failed`, `request_reopened`, `SLA_warning`, `SLA_breached`, `asset_scanned`, `part_issued`, `hazard_created`, `permit_issued`, `vendor_checked_in`, `approval_requested`, `approval_completed`.

Each event payload includes entity refs + enough context for Notification Engine, Audit, and Analytics consumers without re-querying the source service synchronously.

---

## 11. Development Priority (§70, unchanged — governs backend build order)

- **P0 Core Foundation**: Identity & RBAC → Location hierarchy → Requests → Work orders → SLA → Mobile technician + Offline → QR assets → Asset register → PM → Checklists → Evidence → Notifications → Site dashboard → Client dashboard → Audit trail.
- **P1 Operational Control**: Inventory → Vendor management → Quotes → Approvals → Safety → Compliance → Workforce/deployment → Housekeeping → MMR automation → Advanced analytics.
- **P2 Enterprise IFM**: Space → Occupancy → Reservations → Visitors → Energy → ESG → Fleet → Projects → IoT/BMS.
- **P3 Differentiating Intelligence**: AI assistant → Predictive maintenance → SLA prediction → Impact Graph → Cost of Delay → Repeat Failure Radar → Dynamic cleaning → Facility Resilience Score → Business Impact Translator → Automated executive briefings.

Backend services should be built in exactly this order — each later phase's services depend on P0 tables existing (asset, request, work_order, SLA) as the spine.

---

## 12. Definition of Done (§72) — applies to every backend/admin module delivered

UX approved · Business rule approved · Role permissions defined · API implemented · Validation implemented · Audit events implemented · Analytics event implemented · Responsive UI completed · Offline behaviour determined · Empty/Loading/Error states created · Accessibility checked · Security reviewed · Unit + Integration testing completed · QA completed · UAT completed · Documentation updated.

---

## 13. Traceability Index (so nothing is lost)

| Doc Section | Covered In This Design |
|---|---|
| §1–4 Vision, Review Board, Principles, Scope | §0, §1 (architecture principles) |
| §5–8 Roles/Access/Home screens | §4 (RBAC engine), role list verbatim |
| §9–14 Journeys & Navigation | §5 (workflow engine), navigation maps to Admin menu grouping in §8 |
| §15 Screen Contracts (01–54) | Every field referenced maps to a table in §3; Admin screens map to §8 |
| §16 Differentiators (16.1–16.16) | §3.19, §5.5, §7 (AI boundary), explicit per-feature table/engine mapping |
| §17–25 KPI Library & Visualisation | §3.18 (kpi_definitions/snapshots), §8.10 (Admin KPI/Dashboard config) |
| §26–51 Canonical Data Model | §3, field-for-field, zero omissions, gaps marked [inferred-support] |
| §52 Notification Model | §5.6, §8.4 (templates) |
| §53–54 AI Architecture | §7 |
| §55–56 Integration/API | §6, §8.9 |
| §57–61 NFR/Security/Privacy/Accessibility/Language | §9 |
| §62–63 UX Rules/Search | Enforced as design constraint on all mobile APIs (§6) + universal search index in architecture diagram §1 |
| §64 Approval Engine | §5.3, §8.3 |
| §65 Event Model | §10 |
| §66 Data Quality Engine | §8.10 |
| §67 Business Infographics | §3.18 (kpi_snapshots feed executive cards) |
| §68 Client Transparency | Drives dashboard/API design for Client Portal role scopes in §4 |
| §69 Edge Cases | Encoded as explicit states: `work_order_blockers`, `Unable to Access`, `Duplicate`, sync-conflict handling (§6) |
| §70 Dev Priority | §11 |
| §71 Acceptance Criteria | Validated against §5 workflow/SLA design, §6 offline sync |
| §72 Definition of Done | §12 |
| §73 Child Jira Epics | §2 (service/bounded-context table) |
| §74 North-Star Metrics | §3.18 KPI definitions must include each named metric |
| §75 Final Product Position | Governs §1 architecture principle ordering (frontline → manager → client → leadership) |
| Appendix A Benchmark Direction | Reflected in service separation (EAM-grade Asset service, IWMS-grade Space/Workplace service, etc.) |
| Appendix B Architecture Principles | §1, repeated as enforcement notes throughout §3–9 |
