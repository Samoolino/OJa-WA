# OJa-WA — Institutional Subscription Allocation Marketplace

OJa-WA is the **major product repository** for an institutional-grade, subscription-funded, multi-vendor allocation marketplace built on Spree Commerce primitives.

## Product model

```text
Plan Owner / Sponsor
  -> Subscription Plan
  -> Funding
  -> Policy-Controlled Allocation
  -> Receiver
  -> Catalog / Cart
  -> Checkout Policy
  -> Payment
  -> Ledger / Settlement
  -> Vendor / 3PL Fulfillment
  -> Sponsor Reporting
```

Allocations are bounded entitlements. They are not automatically unrestricted cash balances. A Plan Owner can define amount, purpose, eligible beneficiaries, vendors, stores, products/categories, geography, expiry, KYC tier and fulfillment rules.

## Repository responsibilities

**OJa-WA** is the product and institutional architecture source of truth.

**OJA-T** is the auxiliary execution repository for payment, ledger, checkout, fulfillment and settlement implementation components. See `docs/INSTITUTIONAL_REPOSITORY_MAP.md`.

## Institutional capabilities

- multi-tenant Plan Owner management
- subscription funding and allocation strategies
- QR / UUID / verified KYC access boundaries
- vendor organization and multi-store identity
- product/category/vendor/store/geography policy controls
- allocation-aware multi-vendor checkout
- immutable allocation ledger and reconciliation
- Stripe-centered provider-neutral payment boundary
- GoCardless payment adapter target
- Shopify and Nuvemshop commerce adapter targets
- Glovo and other 3PL fulfillment adapter targets
- SAP/NetSuite Anti-Corruption Layer for enterprise catalog/inventory feeds
- sponsor audit and item-level reporting
- operational, security, reliability and production certification gates

## Current repository history

The repository began as a Spree multi-vendor extension and subsequently accumulated subscription plans, plan allocations, coupon/payout lifecycle, wallet/entitlement, redemption, audit, vendor and storefront/admin API scaffolding. The institutional production baseline now consolidates those capabilities into the Plan → Allocation → Policy → Checkout → Payment → Ledger → Settlement model.

See:

- `docs/DEVELOPMENT_HISTORY.md`
- `docs/INSTITUTIONAL_PRODUCTION_BASELINE.md`
- `docs/INSTITUTIONAL_REPOSITORY_MAP.md`

## Production status

Architecture and contracts are being consolidated. **Live payment, settlement, ERP and third-party production credentials are not implied by the architecture documents.** Each provider must pass its own integration, security, reconciliation and runtime certification gates before production activation.

## Spree foundation

This project builds on the Spree multi-vendor ecosystem. Spree remains responsible for commerce primitives such as products, variants, carts, orders, inventory, payment integration points and fulfillment primitives; OJa-WA adds the institutional allocation/policy domain.

## License

Spree Multi-Vendor extension licensing remains governed by the repository `LICENSE` file.
