# OJa-WA Quick Plan Onboarding & Vendor Management UX Contract

## Product intent

OJa-WA is a subscription-funded, allocation-aware multi-vendor marketplace for institutional Plan Owners. Plan creation should be quick and guided without imposing an artificial five-minute deadline.

The experience is progressive: collect only the decisions required for the next valid state, save drafts automatically, and reveal advanced controls when they become relevant.

## Part 1 — Quick Plan Onboarding

### Primary flow

1. **Create** — plan name, objective, owner identity, optional branding.
2. **Funding** — target amount, currency, one-time/recurring cadence, collection rail.
3. **Allocation** — amount/rule, distribution mode, beneficiary access mode, one active access per beneficiary per plan.
4. **Policy** — purpose/category, vendor/store, product/category, geography, expiry, fulfillment.
5. **Review** — coverage, warnings, missing requirements, beneficiary preview.
6. **Activate** — explicit confirmation, immutable version, audit/correlation identity.

### Experience rules

- One primary action per step.
- Autosave drafts and resume from any completed step.
- Show completion and blocking requirements continuously.
- Explain financial consequences before activation.
- Use integer minor units behind the UI.
- Displayed balances are informational; authorization remains server-side.
- Never expose NIN/BVN or sensitive KYC values in QR, UUID, URL or client authorization payloads.
- Activation is a domain command, not a UI-only state change.

### Progressive advanced controls

Advanced settings are collapsed by default and become visible when selected objectives require them:

- KYC assertion requirements
- per-beneficiary limits
- multiple allocation buckets
- vendor/store restrictions
- product/category restrictions
- nested geography
- expiry
- POS rules
- delivery/3PL requirements
- settlement conditions
- institutional reporting

## Part 2 — Vendor Management

Canonical hierarchy:

**Vendor Organization → Connected Payment Account → Store(s) → Catalog/Product → POS/Commerce → Fulfillment → Settlement**

Vendor onboarding:

**Apply → Business Profile → KYB/KYC → Payment Account → Store → Catalog Connection → Policy Eligibility → Sandbox Transaction → Active**

A vendor organization may operate multiple stores. Store-level geography, terminal/POS identity and operational status remain distinct while rolling up to the organization.

Vendor workspace should expose:

- onboarding status
- connected payment account
- stores and operational status
- Shopify/Nuvemshop connections
- catalog synchronization
- policy-eligible products
- pending orders
- payment/capture state
- held and settlement-eligible funds
- fulfillment state
- refunds/disputes
- transfer/payout history
- reconciliation exceptions

## Part 3 — Commerce & Checkout

Shopify and Nuvemshop are adapters for catalog, store and order projections. They do not override OJa-WA allocation policy.

POS asks:

> Can allocation X authorize this exact basket at this exact store/terminal now?

OJa-WA returns the authorization/correlation identity and permitted lines/amount. POS does not calculate authoritative allocation availability.

Cross-vendor carts may be supported when each line independently passes policy and the order split can be recorded atomically.

## Part 4 — Fulfillment & Settlement UX

The operational state is visible as:

**Captured → Order Valid → Fulfillment Pending → Fulfillment Confirmed → Settlement Eligible → Transfer Requested → Transfer Confirmed → Settled**

Glovo or another 3PL receives fulfillment-eligible information and returns authenticated delivery events. A fulfillment adapter cannot directly mutate allocation balances.

Refunds, reversals and disputes appear as compensating financial events rather than edits to historical ledger entries.

## Part 5 — Trust, Assistance & Scale

Agent assistance can:

- explain setup
- suggest non-binding defaults
- identify missing configuration
- summarize vendor/catalog policy
- prepare operational tasks

Agents cannot silently activate plans, move funds, bypass KYC/policy, authorize allocations, alter immutable ledger history or release vendor transfers.

Presentation surfaces:

- OJa-WA web app: canonical management and authorization UX.
- Wix: optional branded presentation surface.
- Shopify embedded experience: merchant-context administration linked to canonical OJa-WA records.
- Figma/Product Design: visual specification and UX validation before final UI implementation.

## Accessibility and responsive behavior

- WCAG 2.1 AA target.
- Keyboard-complete onboarding.
- Semantic form labels and validation.
- Screen-reader friendly progress and error states.
- Responsive desktop/tablet/mobile layouts.
- Clear success, warning, blocking and reconciliation states.
- Avoid modal-heavy flows; prefer progressive sections and resumable drafts.

## Implementation boundary

Visual implementation should follow the selected Product Design direction. Backend/domain/API work can proceed independently, but no visual implementation is considered final until the design direction is reviewed.

OJa-WA remains the product source of truth. OJA-T remains auxiliary DevOps only.
