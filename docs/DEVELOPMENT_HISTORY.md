# OJa-WA Consolidated Development History

This record reconciles the repository history with the institutional design work developed across the project.

## Repository history

- 2026-08-03 — initial OJa-WA repository commit.
- 2026-08-06 — local repository initialization commits.
- 2026-08-07 — code styling/minor bug correction.
- 2026-08-13 — README/product reintegration update.

The current OJa-WA main branch already contains the Spree multi-vendor extension plus subscription-plan, plan-allocation, coupon-payout, wallet, redemption, vendor and audit scaffolding.

## Product evolution

1. Spree multi-vendor marketplace foundation.
2. Subscription Plan and Plan Owner model.
3. Plan Allocation and receiver entitlement model.
4. Wallet/entitlement and redemption records.
5. Coupon/payout lifecycle and audit records.
6. Vendor policy and vendor-scoped commerce.
7. Allocation-aware checkout direction.
8. Institutional CSR allocation model: non-extractable, purpose-controlled entitlements.
9. Vendor/store/product/geography policy controls.
10. ERP Anti-Corruption Layer and canonical catalog/inventory events.
11. Multi-vendor and cross-vendor carting with 3PL routing.
12. Immutable ledger, reconciliation and sponsor reporting requirements.
13. Provider-neutral payment architecture with Stripe as the primary payment rail and GoCardless as an additional adapter.
14. Commerce adapters for Shopify/Nuvemshop and fulfillment adapters for Glovo/other 3PLs.
15. Institutional production gates for security, reliability, reconciliation, recovery and runtime certification.

## Revalidation rule

Historical scaffolding is retained. New institutional capabilities must be added as explicit domain modules/contracts rather than replacing historical Spree primitives without migration evidence.

## 2026-09-20 baseline

The target product is a subscription-based bulk-payment distribution and multi-vendor marketplace. Allocation is a policy-controlled entitlement, not unrestricted cash. Every purchase must be attributable to a Plan, Receiver, Allocation, Vendor/Store/Product policy, payment event and settlement/reconciliation record.
