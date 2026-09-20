# OJa-WA Institutional Production Execution Plan

## Operating rule

OJa-WA is the active development repository and institutional product source of truth. OJA-T is a separate auxiliary execution repository and must not be treated as a co-development surface for OJa-WA product work.

## Current sequence

1. Revalidate OJa-WA domain model and existing Spree foundation.
2. Establish canonical Plan / Allocation / Policy contracts.
3. Implement Plan Owner quick-onboarding and optimal plan configuration flow (not time-boxed to five minutes): progressive disclosure, sensible defaults, save-and-resume, preview-before-activate, and guided completion.
4. Implement allocation issuance, reservation, consumption, release, reversal and expiry state transitions.
5. Implement beneficiary access using QR / UUID / KYC assertion boundaries.
6. Implement vendor organization -> store -> product/category -> geography policy model.
7. Implement policy-first checkout authorization.
8. Implement provider-neutral payment orchestration contract, with Stripe as the primary adapter target.
9. Implement allocation ledger and reconciliation invariants.
10. Implement sponsor audit/reporting and CDC-compatible event contracts.
11. Add commerce/vendor adapters (Shopify/Nuvemshop), POS contracts and ERP ACL contracts only after core policy/payment tests pass; vendor onboarding must support organization -> stores -> catalog/policy scope without making external commerce systems authoritative.
12. Add 3PL/Glovo fulfillment adapters after order validation and settlement invariants are certified; delivery state may gate settlement but cannot mutate allocation accounting directly.
13. Execute load, concurrency, security, failure-recovery and reconciliation tests.
14. Enable provider sandbox certification.
15. Production canary and institutional sign-off.

## Financial invariants

`available = funded - reserved - consumed + released + reversed`

- Available allocation must never become negative.
- Reservation must be idempotent.
- Consumption cannot exceed an active reservation.
- Release/reversal cannot create value that was not previously reserved/consumed.
- Provider webhook replay must not create duplicate ledger effects.
- Every financial mutation requires an auditable correlation/idempotency key.

## Policy invariants

A checkout is eligible only when all applicable rules pass:

- active plan
- eligible beneficiary/KYC state
- active allocation
- sufficient available allocation
- purpose/category compatibility
- vendor compatibility
- store compatibility
- product compatibility
- geography compatibility
- expiry validity
- fulfillment compatibility

## Repository separation

### OJa-WA

Owns product/domain behavior, institutional contracts, management UX, policy semantics, reporting requirements and canonical integration boundaries.

### OJA-T

Remains an auxiliary execution repository. Its code may be maintained through DevOps/CI/security/dependency operations, but OJa-WA feature development must not depend on simultaneous manual co-development in OJA-T.

## Production safety

No live payment, settlement, ERP, POS or 3PL credentials are implied. Provider integrations remain sandbox/certification gates until runtime evidence is recorded.


## Current implementation checkpoint — 2026-09-20

Phase A has begun on the institutional feature branch. The first implementation slice establishes integer-unit allocation accounting, immutable allocation ledger evidence, atomic reservation/idempotency boundaries, and policy checks. The next required slice is the Plan Owner five-minute management flow and canonical API command/query contracts.

### Design and implementation boundary

- OJa-WA remains the only active feature-development surface.
- OJA-T remains auxiliary DevOps/CI/security/dependency maintenance only.
- Wix may be used as a presentation/experience layer where appropriate, but OJa-WA domain and financial policy remain authoritative.
- Stripe remains the primary payment-provider adapter target.
- On-chain execution is not a source of authorization for fiat allocation balances; any future crypto/on-chain rail must pass the same policy, idempotency, accounting and diligence gates.

### Quick-onboarding UX contract

The Plan Owner experience is optimized for low cognitive load rather than a fixed completion time. The primary flow is:

`Create Plan -> Choose objective -> Funding & currency -> Allocation rules -> Beneficiary access -> Vendor/catalog/geography rules -> Review -> Activate`

The interface uses progressive disclosure: advanced policy controls remain optional until relevant. Drafts are resumable. Every step has explicit validation, a visible completion state, and a non-destructive back action. Activation is a deliberate final command and produces an auditable plan version.

### Integration ownership

- **OJa-WA:** canonical Plan, Allocation, Policy, Order, Ledger and authorization semantics.
- **Stripe / GoCardless:** payment-collection rails; neither becomes allocation authority.
- **Shopify / Nuvemshop:** vendor/store/catalog/order adapters; external catalog identifiers are mapped into OJa-WA canonical IDs.
- **Glovo / other 3PL:** fulfillment and delivery telemetry; fulfillment evidence can gate transfer eligibility.
- **Wix:** presentation/experience surface only where used; financial policy remains in OJa-WA.
- **On-chain diligence:** proposal/evidence gate for future blockchain rails; it does not replace KYC, payment authorization, ledger controls or settlement reconciliation.

### Required next acceptance evidence

1. Plan Owner create/update/activate flow test.
2. One-access-per-beneficiary-per-plan constraint test.
3. Allocation reservation/consume/release/reverse concurrency tests.
4. Canonical payment command idempotency tests.
5. Authenticated Stripe webhook replay/out-of-order tests.
6. Vendor transfer eligibility and delivery-gated release tests.
7. Reconciliation exception fixtures.
8. Sandbox provider certification evidence.
