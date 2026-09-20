# OJa-WA Vendor Integration Contract

## Canonical model

Vendor Organization
-> Store
-> Catalog
-> Policy Scope
-> Order
-> Fulfillment
-> Settlement Evidence

OJa-WA owns canonical identifiers, allocation authorization, policy evaluation, ledger accounting and settlement eligibility.

## Vendor onboarding

A vendor may:

1. register or connect an organization;
2. create or import stores;
3. associate catalog sources;
4. configure permitted policy scopes;
5. connect POS/terminal identities;
6. connect fulfillment providers;
7. complete payment-provider onboarding where settlement is required.

Each integration is represented by an adapter/integration record with provider, external ID, status, last synchronization marker and correlation metadata.

## Shopify / Nuvemshop

Adapters synchronize:

- merchant/store identity
- products and variants
- categories/collections
- inventory projections where required
- orders and order lines
- fulfillment state

External identifiers are mapped to canonical OJa-WA identifiers.

Incoming events are authenticated, deduplicated and reconciled.

External commerce systems do not determine whether an allocation can be spent.

## POS authorization

A POS request contains:

- allocation reference
- beneficiary authorization context
- store/terminal identity
- basket lines
- requested amount
- currency
- idempotency key
- correlation ID

OJa-WA evaluates the complete basket against current allocation and policy state.

A successful response contains an authorization reference and permitted line/amount result.

The POS must not rely on a cached displayed allocation balance.

## Fulfillment / Glovo

After order authorization, the fulfillment adapter receives the eligible fulfillment request.

Events include:

- accepted
- preparing
- dispatched
- delivered
- failed
- cancelled
- returned

Fulfillment evidence is correlated to order and settlement records.

Delivery-gated plans cannot release vendor settlement until required fulfillment evidence is present.

## Settlement

Vendor settlement eligibility is evaluated by OJa-WA.

Minimum evidence can include:

- captured payment
- valid connected account
- order and line mapping
- policy authorization
- fulfillment requirement satisfied where applicable
- no unresolved reconciliation exception
- idempotent transfer command

Adapters cannot create settlement eligibility by themselves.

## Webhooks

Provider events follow:

authenticated ingress
-> immutable event evidence
-> deduplication/idempotency
-> canonical projection
-> domain command
-> reconciliation

Out-of-order and duplicate events must be safe.

## Failure handling

Synchronization failures are observable and retryable.

A provider outage must not corrupt allocation accounting.

Partial external state is reconciled against canonical OJa-WA records.

No historical ledger entry is edited to correct an integration error; compensating domain entries are used.
