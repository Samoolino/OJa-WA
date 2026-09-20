# OJa-WA Plan Owner API Command Contract

## Scope

This contract defines the canonical management boundary for Plan Owner onboarding. The API is command-oriented for mutations and query-oriented for read models.

The API does not authorize money movement by itself. Payment-provider actions remain behind provider adapters and must produce canonical payment evidence.

## Command model

All mutating commands require:

- authenticated principal
- plan-owner authorization
- idempotency key
- correlation ID
- request ID
- optimistic version where applicable

Every command returns the resulting resource version and correlation ID.

### Create plan

POST /api/v1/plan-owners/plans

Request:

- name
- objective
- currency
- plan_type: one_time | recurring
- funding_target_minor
- optional branding
- optional initial policy draft

Result:

- plan_id
- status=draft
- version
- onboarding_state
- missing_requirements[]

### Update plan

PATCH /api/v1/plan-owners/plans/:id

Permitted while draft, subject to version check.

Changes may include:

- name/objective
- branding
- funding configuration
- allocation configuration
- access configuration
- policy configuration
- fulfillment requirements

The server recalculates onboarding_state and missing_requirements.

### Configure allocation

POST /api/v1/plan-owners/plans/:id/allocation

Defines:

- allocation amount/rule
- distribution mode
- beneficiary access mode
- expiry
- per-beneficiary constraints

The server validates that the resulting allocation policy is internally consistent.

### Configure policy

POST /api/v1/plan-owners/plans/:id/policy

Policy dimensions:

- purpose/category
- vendor organization
- store
- product/category
- geography
- fulfillment
- beneficiary/KYC assertion requirements
- expiry

Advanced fields are optional but become required when the selected objective requires them.

### Review plan

POST /api/v1/plan-owners/plans/:id/review

Returns:

- ready: boolean
- missing_requirements[]
- policy_warnings[]
- funding_summary
- allocation_summary
- vendor_scope_summary
- beneficiary_access_summary
- proposed_plan_version

Review does not activate the plan.

### Activate plan

POST /api/v1/plan-owners/plans/:id/activate

Activation requires:

- plan is valid
- mandatory policy requirements pass
- required funding/payment prerequisite passes
- no blocking reconciliation exception
- explicit authenticated command
- idempotency key

Activation creates an immutable plan version and audit event.

## Onboarding state

Suggested states:

DRAFT -> CONFIGURING -> REVIEW_READY -> ACTIVATION_PENDING -> ACTIVE

Failure or correction remains non-destructive:

- validation failure: state remains unchanged
- review changes: return to CONFIGURING
- activation failure: remain ACTIVATION_PENDING or CONFIGURING according to failure class

## Query model

GET /api/v1/plan-owners/plans/:id

Returns canonical plan summary.

GET /api/v1/plan-owners/plans/:id/onboarding

Returns:

- current_step
- completed_steps[]
- next_step
- completion_ratio
- missing_requirements[]
- warnings[]
- draft_version

GET /api/v1/plan-owners/plans/:id/vendors

Returns canonical vendor organizations and stores available to the plan owner.

GET /api/v1/plan-owners/plans/:id/catalog

Returns policy-filterable catalog projections, not an independent authorization source.

## Error model

Errors are stable machine-readable codes, for example:

- PLAN_NOT_FOUND
- PLAN_VERSION_CONFLICT
- PLAN_INVALID_STATE
- FUNDING_CONFIGURATION_REQUIRED
- ALLOCATION_CONFIGURATION_REQUIRED
- POLICY_CONFIGURATION_REQUIRED
- BENEFICIARY_ACCESS_CONFIGURATION_REQUIRED
- VENDOR_SCOPE_INVALID
- CURRENCY_MISMATCH
- ACTIVATION_BLOCKED
- IDEMPOTENCY_CONFLICT

Responses must not expose internal provider secrets or sensitive KYC values.

## Vendor integration boundary

External vendor systems use adapters. Canonical OJa-WA IDs are authoritative.

Shopify/Nuvemshop external IDs, POS terminal IDs and fulfillment IDs are mapped through integration records and correlation IDs.

No external adapter may directly modify the allocation ledger.

## Agent command boundary

An agent may prepare a draft command or explain missing requirements. Consequential commands use the same authenticated command endpoint, idempotency key and audit trail as human actions.

Agent assistance therefore improves onboarding without creating a privileged financial execution path.
