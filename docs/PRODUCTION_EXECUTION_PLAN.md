# OJa-WA Institutional Production Execution Plan

## Operating rule

OJa-WA is the active development repository and institutional product source of truth. OJA-T is a separate auxiliary execution repository and must not be treated as a co-development surface for OJa-WA product work.

## Current sequence

1. Revalidate OJa-WA domain model and existing Spree foundation.
2. Establish canonical Plan / Allocation / Policy contracts.
3. Implement Plan Owner management and five-minute plan configuration flow.
4. Implement allocation issuance, reservation, consumption, release, reversal and expiry state transitions.
5. Implement beneficiary access using QR / UUID / KYC assertion boundaries.
6. Implement vendor organization -> store -> product/category -> geography policy model.
7. Implement policy-first checkout authorization.
8. Implement provider-neutral payment orchestration contract, with Stripe as the primary adapter target.
9. Implement allocation ledger and reconciliation invariants.
10. Implement sponsor audit/reporting and CDC-compatible event contracts.
11. Add commerce adapters (Shopify/Nuvemshop), POS contracts and ERP ACL contracts only after core policy/payment tests pass.
12. Add 3PL/Glovo fulfillment adapters after order validation and settlement invariants are certified.
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
