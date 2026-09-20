# OJa-WA Five-Part Production Implementation Plan

## Part 1 — Plan & Marketplace Foundation

OJa-WA is the canonical product and financial/domain authority. The Plan Owner experience uses quick, progressive onboarding rather than an artificial five-minute subscription promise.

Flow:

1. Create plan
2. Define objective
3. Configure funding
4. Configure beneficiary/allocation rules
5. Configure policy
6. Review
7. Explicit activation

Advanced controls appear progressively: KYC assertion requirements, one-access-per-beneficiary, product/category restrictions, vendor/store scope, geography, expiry, fulfillment and reporting.

The Plan Owner API uses command endpoints with authenticated principal, idempotency key, correlation ID, request ID and optimistic versioning.

## Part 2 — Vendor, Catalog & Commerce Network

Canonical hierarchy:

Vendor Organization -> Connected Payment Account -> Store(s) -> Catalog/Product -> POS/Commerce -> Fulfillment.

Shopify and Nuvemshop are commerce adapters. They synchronize external identifiers and catalog/order projections but cannot override OJa-WA policy or ledger authority.

Vendor onboarding progresses through business identity, KYB/KYC, payment account, store, catalog, policy eligibility, sandbox transaction and activation.

## Part 3 — Policy-Aware Multi-Vendor Checkout & Payment

Checkout evaluates the exact basket against the beneficiary's active allocation and policy before payment execution.

The authorization decision covers:

- beneficiary/access state
- active allocation
- available balance
- purpose/category
- vendor
- store
- product/category
- geography
- expiry
- fulfillment compatibility

Payment providers are rails, not allocation authorities.

Stripe is the primary payment integration target. GoCardless is an optional collection rail. Provider webhooks are evidence entering through an authenticated gateway, followed by deduplication, persistence, projection and reconciliation.

## Part 4 — Settlement, Fulfillment, Refund & Reconciliation

Settlement is evidence-driven:

CAPTURED -> ORDER_VALID -> FULFILLMENT_PENDING -> FULFILLMENT_CONFIRMED -> SETTLEMENT_ELIGIBLE -> TRANSFER_REQUESTED -> TRANSFER_CONFIRMED -> SETTLED.

Vendor transfer eligibility requires valid payment evidence, order/line mapping, connected-account readiness, fulfillment requirements where configured, no blocking reconciliation exception and transfer idempotency.

Refunds, reversals and disputes use compensating ledger evidence; historical entries are never edited.

Every operation carries a traceable correlation chain across plan, allocation, cart, order, payment, provider transaction, ledger, settlement, payout and webhook identifiers.

## Part 5 — Institutional Scale, Intelligence & Trust

Scale is added after financial invariants and sandbox certification.

Target architecture:

OJa-WA -> API/Event Gateway -> Transaction Core + Policy Engine -> Commerce Adapters -> Financial Ledger -> Payment/Settlement -> Audit/Reporting.

Supporting capabilities include queues, Redis/cache, PostgreSQL/PostGIS, CDC/event streams, reconciliation workers, POS/ERP adapters, Shopify, Nuvemshop, Glovo/3PL, GoCardless, risk signals and institutional reporting.

Agentic helpers can explain configuration, identify missing requirements and prepare commands. They cannot bypass policy, KYC, idempotency, ledger controls or human authorization for consequential financial actions.

## Production gates

- G0 Architecture
- G1 Integration contracts
- G2 Sandbox certification
- G3 Financial integrity and reconciliation
- G4 Security/compliance
- G5 Production canary
- G6 Institutional sign-off

No live provider credential, payment movement, settlement activation or on-chain execution is implied by this implementation branch.

## Repository separation

OJa-WA remains the only active product-development surface.

OJA-T remains auxiliary: CI, dependency, security and reliability maintenance only. It must not become a parallel feature-development track.
