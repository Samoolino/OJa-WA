# Institutional Payment & Allocation Contract

## Authority split

OJa-WA owns the business decision:

1. Plan eligibility.
2. Beneficiary/KYC assertion.
3. Allocation availability and reservation.
4. Vendor/store/product/geography/fulfillment policy.
5. Ledger mutation and audit correlation.
6. When a vendor transfer becomes eligible.

Stripe is a payment rail/provider boundary. Stripe payment state is evidence that OJa-WA projects into its local state machine; it does not become the allocation ledger.

## Allocation arithmetic

For one currency:

`available = funded - reserved - consumed + released + reversed`

All monetary values are integer minor units with an explicit ISO currency. No floating point is permitted for financial postings.

The reservation decision, row lock, idempotency claim, allocation mutation and ledger entry are one database transaction.

## Idempotency

A financial operation is scoped by:

`tenant/principal + operation_type + target_resource + idempotency_key + canonical_input_fingerprint`

A repeated equivalent operation returns the stored result. Reusing the same key for different semantic input is a critical error. Provider identities are persisted separately from local operation identities.

## Payment state

OJa-WA keeps these states distinct:

- CREATED
- REQUIRES_METHOD
- REQUIRES_AUTH
- PROCESSING
- AUTHORIZED
- CAPTURED
- FAILED
- CANCELLED
- REFUNDED
- DISPUTED
- SETTLED

A successful client redirect is not payment evidence. Webhook/provider evidence is authenticated, deduplicated and reconciled before financial mutation.

## Stripe marketplace mapping

For a multi-vendor cart or delivery-gated settlement, the target pattern is Stripe Connect **separate charges and transfers**. The platform creates the payment on its account and transfers vendor portions only after OJa-WA's release condition is met. This is appropriate where one payment must be split across multiple connected accounts or where transfer timing is controlled.

For Plan Owner subscription fees paid to OJa-WA itself, use Stripe Billing subscriptions. These subscription payments are separate from beneficiary allocation balances.

Vendor onboarding/management should use Connect capabilities/embedded components where available. OJa-WA remains the policy and ledger authority.

## Webhook contract

Provider -> authenticated webhook endpoint -> immutable event record -> idempotency/deduplication -> event projection -> allocation/payment/ledger command.

Never mutate allocation balances directly from an unauthenticated callback. Late or out-of-order events are retained and reconciled against the current payment state.

## Settlement

Transfer eligibility requires:

- captured payment evidence;
- valid vendor connected account;
- order/line-item mapping;
- fulfillment condition satisfied where the plan requires it;
- no unresolved policy or reconciliation exception;
- transfer idempotency identity available.

Refunds, reversals and disputes create compensating evidence; historical ledger entries are never edited.

## Production gate

This contract is sandbox architecture only. Live Stripe credentials, transfers and payouts remain disabled until integration, financial-integrity, security, reconciliation and runtime certification evidence exists.
