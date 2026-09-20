Reintegration Plan: Agentic Subscription Marketplace

1. Product vision
Build a multi-vendor subscription marketplace where:

Plan Owners create subscription plans for members or employees.
Vendors supply products and fulfill plan-linked demand.
AI agents orchestrate inventory, plan allocation, and fulfillment.
A one-time coupon payout can be issued to users who activate or redeem a coupon.
This plan is designed to sit on top of the cloned Spree multi-vendor extension, which already provides vendor, vendor-user, commission, and vendor-scoped product concepts.

2. Recommended architecture
Core domain objects
Plan Owner
Creates and manages subscription plans.
Owns plan rules, pricing, eligibility, and payout rules.
Vendor
Existing Spree vendor abstraction can be reused.
Supplies products and fulfillment capacity.
Subscription Plan
Defines recurring or one-time access for members/employees.
Can be linked to vendors, products, and eligibility rules.
Plan Allocation
Associates a plan owner, a vendor, and a user/member with an entitlement.
Coupon / Payout Claim
One-time reward that can be issued to users after activation or redemption.
Fulfillment Job
AI-orchestrated job that tracks product allocation, stock reservation, and shipping.
Suggested data model extensions
Add a new table for subscription plans.
Add a plan allocation table linking plan owners, users, vendors, and plan records.
Add coupon payout records to track issuance, redemption, and status.
Reuse the existing Spree vendor model and vendor-user join table where possible.
3. Reintegration approach inside the current repo
A. Reuse existing Spree multi-vendor primitives
The current extension already supports:

Vendors
Vendor-user membership
Vendor-scoped products/stock locations
Commission tracking
These are directly relevant for:

Vendor onboarding
Vendor-managed catalog
Vendor-specific payout or commission logic
B. Introduce marketplace-specific modules
Create new modules under the extension or host app, for example:

app/models/spree/subscription_plan.rb
app/models/spree/plan_allocation.rb
app/models/spree/coupon_payout.rb
app/controllers/spree/admin/subscription_plans_controller.rb
app/controllers/spree/api/v2/storefront/subscription_plans_controller.rb
C. Add admin and storefront flows
Admin UI for Plan Owners to create plans.
Admin UI for Vendors to see assigned plan allocations and fulfillment jobs.
Storefront API to expose available plans and user entitlements.
4. Suggested database design
Subscription plans
id
plan_owner_id
name
description
plan_type
currency
price_cents
billing_frequency
status
eligibility_rule_json
payout_rule_json
created_at / updated_at
Plan allocations
id
plan_id
user_id
vendor_id
status
allocated_at
expires_at
metadata
Coupon payouts
id
user_id
plan_id
vendor_id
coupon_code
payout_amount_cents
currency
status
issued_at
redeemed_at
metadata
Fulfillment jobs
id
plan_allocation_id
vendor_id
status
payload_json
created_at / updated_at
5. Payment and payout logic
One-time coupon payout flow
User is eligible for a coupon or reward.
System issues a single-use payout record.
The payout is marked as issued and linked to the user and plan.
The user redeems or activates the coupon once.
The payout transitions to completed or failed.
Reuse Spree-inspired pricing concepts
Keep amounts in cents for reliability.
Use a dedicated payout ledger table if you need auditing.
Build payout status transitions explicitly: pending -> issued -> redeemed -> completed/failed.
6. AI-agent orchestration scope
The AI layer can be introduced as a service layer rather than being embedded into core business logic.

Suggested services
Inventory orchestration service
Checks vendor stock availability.
Reserves stock for the plan allocation.
Plan allocation service
Chooses the best vendor or bundle for a plan.
Fulfillment orchestration service
Creates shipping or dispatch actions.
Coupon payout service
Evaluates eligibility and issues one-time rewards.
7. API shape
Admin APIs
GET /admin/subscription_plans
POST /admin/subscription_plans
PATCH /admin/subscription_plans/:id
GET /admin/plan_allocations
Storefront APIs
GET /api/v2/storefront/subscription_plans
GET /api/v2/storefront/plan_allocations
POST /api/v2/storefront/coupon_payouts/claim
8. Suggested implementation phases
Phase 1 — foundation
Add subscription plan and allocation models.
Add coupon payout model.
Wire admin routes and controllers.
Create seed data for sample vendors and plans.
Phase 2 — entitlement and access
Link users to plans.
Restrict plan content based on allocation status.
Add API endpoints for current entitlements.
Phase 3 — fulfillment automation
Introduce AI orchestration service for inventory and fulfillment.
Add webhook or background job support.
Phase 4 — payouts and analytics
Track coupon payout lifecycle.
Add reporting for vendor commissions, plan usage, and payout completion.
9. Risks and considerations
The current repo is an extension, not a full standalone app; it needs to be mounted into a Spree host application.
Subscription logic is not native to this extension, so it should be introduced as a separate domain layer.
Coupon payout should be implemented as an auditable event system rather than a simple one-off field.
If you want multi-tenant vendor segregation, keep vendor scoping central to all plan and allocation logic.
10. Recommended next step
The next implementation step should be to scaffold the core domain objects for subscriptions and coupon payouts, then wire them into the admin and storefront APIs in a way that reuses Spree vendors and stock locations.

11. Current implementation status
The following features are now scaffolded in the extension:

Subscription plans with plan owner, vendor, and policy links.
Plan allocations with allocation codes and status tracking.
Coupon payouts with issue/redeem lifecycle support.
Wallet accounts for customers, vendors, and plan owners.
Allocation redemptions with redemption codes and status transitions.
Audit records for plan allocations, redemptions, and wallet transfers.
Admin controllers and routes for all new models.
Storefront API routes for plan listings, allocations, coupon payouts, wallet accounts, redemptions, and wallet transfers.
Service objects for allocate-plan, redeem-allocation, and issue-coupon-payout flows.
12. Audit feature and production build plan
Audit and governance features
Spree::AllocationAudit captures all allocation, payout, and wallet-transfer actions.
PlanOwnerPolicy stores vendor-targeting and governance rules for plan owners.
WalletAccount#transfer_to! enforces non-withdrawal transfers to verified vendor wallets only.
Redemptions are recorded separately and linked to allocations, enabling QR/code validation.
All actions are auditable through admin views and API records.
Production build plan
Ensure the environment has the correct Ruby and Rails versions.
The dummy app uses Rails 8.1.3.1 and SQLite.
The workspace has ruby 4.0.6 available.
Install dependencies from spec/dummy:
cd spree_multi_vendor/spec/dummy
bundle config set --local path vendor/bundle
bundle install
Prepare the database:
bundle exec rails db:prepare
Run a simple application check:
bundle exec rails runner "puts 'ok'"
Seed or create sample data:
vendors
plan owners
subscription plans
wallet accounts
Validate end-to-end flows:
create a subscription plan with vendor targeting and policy rules
allocate a plan using customer wallet funds
transfer wallet funds to a verified vendor wallet
issue and redeem coupon payouts
verify audit records for every transaction step
Add integration/test coverage:
model specs for SubscriptionPlan, PlanAllocation, CouponPayout, WalletAccount, AllocationRedemption, AllocationAudit
controller/API specs for storefront flow
admin controller specs for policy and wallet management
Deploy the extension:
run migrations in the production host app
mount the engine and configure admin routes
add production monitoring for payout and redemption actions
13. Conclusion and validation required
To fully validate vendor integration and transaction flows, the following end-to-end tests are required:

vendor onboarding and vendor-user membership are intact
plan owners can create plans and assign vendor-specific policies
customers can onboard with wallet accounts and receive plan balance allocations
wallet transfers to verified vendors are allowed while withdrawal is blocked
allocation redemptions succeed only with valid codes and record status transitions
coupon payouts are issued to user wallets and audited properly
audit trails are visible in admin views
This project is now at the next practical stage: the code scaffolding exists, and the final validation is a proper Rails dummy app run and targeted integration tests in spec/dummy. The next work item is to convert these scaffolds into working admin forms and integration tests, then execute the flows against the dummy Spree app.












> [!IMPORTANT]
>
> We're in the process of moving Multi Vendor logic into Spree Core, you can track progress here: https://github.com/spree/spree/issues/13323

# Spree Commerce Multi Vendor Marketplace Open Source

This is a Spree Commerce open-source [multi vendor marketplace](https://spreecommerce.org/marketplace-ecommerce/) extension. It's a great starting point if you're building a marketplace on top of [Spree](https://spreecommerce.org). Our goal was flexibility to allow you to tweak it to your needs.

## License

Spree Multi-Vendor extension is free software, and may be redistributed under the terms specified in the
[LICENCE](LICENSE) file.

[LICENSE]: https://github.com/spree-contrib/spree_multi_vendor/blob/main/LICENSE


## Current dual-repository implementation status — 2026-09-20

OJa-WA and OJA-T are **competitive/parallel implementations of the same OJa-WA product and transaction functionality**. They are not intentionally divided into “product” versus “execution” ownership. Each repository is expected to converge on the same functional behavior and production-gate evidence, even where the internal implementation differs.

See `docs/DUAL_REPO_PARITY_CONTRACT.md` for the shared acceptance contract.

The historical scaffold/reintegration sections above are retained as repository history. They must not be used as the current implementation-state definition.

Current re-entry rule:

`re-baseline -> identify parity gap -> implement -> test -> CI evidence -> advance production gate`

No live payment movement, custody, KYC/AML processing, or production settlement is inferred from source-code presence alone.
