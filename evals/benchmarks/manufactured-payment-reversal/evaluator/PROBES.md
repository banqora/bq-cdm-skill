# Adaptive evaluator probes

The task deliberately leaves its Java API and application-owned persistence boundary open. The
following semantic probes were frozen before any model run. Adapt each probe mechanically to an
arm's public API only after all candidate processes have exited and their deliverables are sealed.

## Baseline and generated boundary

Use one security loan whose position history establishes 100,000 shares on the dividend record
date. Process an identified EUR cash-dividend event at EUR 0.50 per share and a 0.85 all-in ratio.
Assert one EUR 42,500 borrower-to-lender payment, a positive lender-perspective signed amount, and a
genuine generated CDM 7.0.0 value at the documented boundary. If the output is a CDM transfer,
assert a positive quantity, EUR cash asset/unit, and actual borrower/lender references.

## Historical entitlement after a return

After the baseline result is committed to processing state, apply or supply a return that leaves
40,000 shares outstanding. Correct the same original corporate action to EUR 0.45. Assert one net
EUR 4,250 lender-to-borrower adjustment based on 100,000 shares. Inspect delivered state to confirm
that the correction used the stored record-date entitlement rather than a current-balance lookup.

## Replay and correction chain

Replay the identical correction event and state. Assert an explicit duplicate/no-op result with no
transfer and no state change. Then process a new correction identity changing EUR 0.45 to EUR 0.47.
Assert one EUR 1,700 borrower-to-lender adjustment: the new entitlement differs from the latest
processed EUR 38,250 by EUR 1,700, not from the original EUR 42,500 by EUR 2,550.

## Signed flow and model invariant

For the EUR 0.50 to EUR 0.45 correction, assert signed lender-perspective amount `-4250.00`, lender
as payer, and borrower as receiver. Assert that no `abs`, non-negative coercion, or zero floor erased
the sign. Where represented as `AssetFlowBase`, assert its quantity is positive because CDM 7.0.0
places direction in `payerReceiver`; require the signed application result alongside it.

## Identity scoping and fail-closed history

Use two original corporate actions sharing a security but having different stable event IDs. A
correction that names one must not suppress or alter the other. Reject an unknown original ID, a
security or currency mismatch, an ambiguous/missing record-date history, and a duplicate correction
ID reused for a different payload. Every rejection leaves processing state and prior results
unchanged.

## Ownership and replay durability

Construct public inputs and processing state from mutable collections where the API permits it.
Mutate those original collections after construction and attempt to mutate returned views. The
delivered entitlement, processed-event set, and results must remain unchanged. Reject a design whose
replay guarantee exists only in static process memory or transient object identity.
