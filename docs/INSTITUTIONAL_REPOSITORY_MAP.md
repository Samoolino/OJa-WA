# OJa-WA Institutional Repository Map

## Purpose

OJa-WA is the major product repository and institutional source-of-truth for the subscription-funded, multi-vendor allocation marketplace. OJA-T is the auxiliary implementation repository for the allocation/payment/settlement execution stack.

## Repository roles

### OJa-WA — major product repository

Owns:

- product and domain architecture
- Spree multi-vendor integration
- Plan Owner, Subscription Plan and Receiver experiences
- allocation and entitlement concepts
- vendor/store/product policy
- institutional CSR allocation specification
- ERP/commerce/3PL integration contracts
- admin/storefront/API product surface
- governance, audit and production runbooks

### OJA-T — auxiliary execution repository

Owns the implementation track for:

- allocation ledger and reservations
- payment orchestration
- provider adapters
- Stripe payment boundary
- webhook verification/reconciliation
- checkout materialization
- order allocation
- vendor settlement
- fulfillment and delivery-gated settlement
- CI and focused financial/integration tests

## Source-of-truth rule

OJa-WA defines the product contract and institutional behavior. OJA-T implements reusable execution components against that contract. Features must not silently diverge between the repositories.

## Integration rule

External providers are adapters, not business authorities:

- Stripe / GoCardless = payment rails
- Shopify / Nuvemshop = commerce channels
- Glovo / other 3PLs = fulfillment channels
- SAP / NetSuite = enterprise catalog/inventory sources
- POS systems = transaction channels

The OJa-WA allocation/policy model remains authoritative.

## Production status

Architecture is defined. External live credentials, live settlement and enterprise ERP access require separate runtime certification and must remain disabled until their corresponding gates pass.
