# Institutional CSR Allocation Engine — Production Baseline v2

## Mission

Build a multi-tenant subscription-funded marketplace in which sponsors/Plan Owners fund policy-controlled allocations for verified beneficiaries and those allocations can be redeemed only through authorized commerce and fulfillment channels.

## Canonical flow

```text
Sponsor / Plan Owner
  -> Plan
  -> Funding
  -> Allocation Engine
  -> Beneficiary Access (QR / UUID / KYC assertion)
  -> Policy Engine
  -> Catalog / Cart
  -> Checkout Authorization
  -> Payment Provider
  -> Immutable Allocation Ledger
  -> Vendor Settlement
  -> 3PL Fulfillment
  -> Reconciliation / Sponsor Reporting
```

## Allocation invariants

- Allocation is an entitlement and is not automatically unrestricted cash.
- No P2P transfer unless a separately authorized product policy permits it.
- NIN/BVN are KYC inputs and must never be exposed as allocation secrets.
- QR/UUID values are opaque access references and require server-side authorization.
- Product, vendor, store, category, geography and expiry rules are evaluated before checkout authorization.
- Reservations cannot exceed available allocation balance.
- Consumption occurs only after the configured payment/order transition succeeds.
- Refunds/reversals create compensating ledger entries; historical ledger records are not mutated.

## Institutional domains

1. Plan Management
2. Allocation/Entitlement Engine
3. Beneficiary Identity and KYC boundary
4. Vendor Organization / Store / Product registry
5. Nested PostGIS geography policy
6. Allocation-aware checkout
7. Payment orchestration
8. Immutable ledger and reconciliation
9. ERP/catalog Anti-Corruption Layer
10. Commerce adapters (Shopify/Nuvemshop/POS)
11. Fulfillment adapters (Glovo/other 3PL)
12. Sponsor audit and reporting
13. Observability, security and disaster recovery

## ERP integration boundary

Enterprise ERP data is translated through an Anti-Corruption Layer. The core domain must not depend directly on SAP IDoc or another retailer's proprietary schema. Normalized events should carry a trace ID, vendor identity, canonical SKU, branch/store identity, location, inventory and pricing context.

## Multi-store hierarchy

```text
Vendor Organization
  -> Store / Branch
      -> Geo identity
      -> POS identity
      -> Inventory source
      -> Product availability
```

A vendor may own many stores, but every physical transaction remains attributable to the actual store and terminal where applicable.

## Cross-vendor checkout

A Receiver may combine eligible allocations in a cart. A cross-vendor cart produces a parent order with vendor-specific order/settlement records. If a 3PL is used, fulfillment and settlement must remain separately attributable even when the customer sees one checkout.

## Payment boundary

Stripe is the primary payment rail. GoCardless and other providers implement the same provider-neutral adapter contract. Payment authorization/execution, provider webhooks and internal reconciliation are separate stages.

## Production gates

### G0 — Domain contract
Plans, allocations, receivers, vendors and rules are defined.

### G1 — Financial invariants
Append-only ledger, reservation/consumption/release and compensating reversal behavior are tested.

### G2 — Checkout policy
Vendor/store/product/category/geography/KYC/expiry policies are enforced before authorization.

### G3 — Payment providers
Stripe adapter and webhook reconciliation are tested in provider test environments.

### G4 — Commerce/ERP
ERP ACL, Nuvemshop/Shopify/POS adapters pass contract tests.

### G5 — Fulfillment
3PL routing, callback authentication, delivery state and settlement gating pass tests.

### G6 — Reliability
Load, failover, backup/restore, RPO/RTO and observability tests produce evidence.

### G7 — Institutional certification
Security review, independent architecture review, reconciliation evidence and production canary are complete.

## Non-goals

This document does not assert that any retailer, payment provider, KYC provider or 3PL has granted production credentials or approved the integration. Those are external onboarding and certification steps.
