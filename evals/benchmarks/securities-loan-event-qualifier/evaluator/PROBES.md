# Evaluator-owned probes

These probes are frozen before any model run. Keep this file, the rubric, and every derived test
outside candidate workspaces until all arms exit and their result commits are sealed. Adapt only
package names, constructors, and public API wiring; do not weaken or disclose the semantic checks.

## Boundary and fixture setup

Use the candidate's documented securities-loan fixture and actual CDM 7.0.0 paths to construct
generated `TradeState` before/after values. Construct the public immutable qualification carrier
with generated `PrimitiveInstruction` values and optional `EventIntentEnum`. Assert a meaningful
quantity, fee/rate, closed-state, collateral identity, or transfer fact reached the typed object
before invoking the qualifier; hollow fixtures are not evidence.

If the candidate claims complete roots, run the root and every populated generated child's
structural/type-format/applicable data rules. If fixtures are explicitly partial, validate the
complete nodes relied on and do not retroactively demand unrelated economics. Mutate one populated
child or primitive so the claimed validation test demonstrably fails.

## Quantity lattice and conjunction

From an otherwise identical 100,000-unit loan, probe after quantities 120,000, 60,000, one, zero,
unchanged, and a malformed negative/missing value. Require `Increase` only above the before value,
`PartialReturn` only for a lower positive value, and `FullReturn` only at zero with generated
`ClosedStateEnum.Terminated`. At zero, independently vary closed state among absent, Terminated,
Novated, Matured, and an inconsistent closed-position shell. Only the exact full-return conjunction
may qualify.

## Exact primitive population

Run the valid zero-and-Terminated case first with the admitted quantity-change primitive. Then add
each other `PrimitiveInstruction` component independently. In particular, populate `termsChange`
both alongside quantity change in one object and as a second list entry. Require `Unqualified`.
Repeat with duplicate quantity changes, an empty primitive, and reordered list entries. Verify that
the implementation reasons over all populated components rather than selecting the first object or
calling `contains(quantityChange)`.

## Intent and label independence

Run byte-for-byte equivalent primitive and before/after facts with absent intent and with
`EventIntentEnum.Novation`; require `FullReturn` then `Unqualified`. Supply a misleading string or
event qualifier wherever the candidate's surrounding fixtures make one available, and require no
change. Also pair an Increase or another seemingly compatible intent with unchanged state: intent
alone must never create a positive result.

## Re-rate negative space

Use the candidate's documented CDM loan fee/rate leaf and admitted primitive combination. Change
only that economic rate and require `ReRate`. Then hold the rate fixed while changing another term;
change rate and quantity together; change rate and collateral together; and supply the same
primitive shape with no actual rate delta. Each must be `Unqualified` unless another classification
is independently and uniquely established.

## Collateral substitution negative space

Represent a collateral return of identified security A and delivery of distinct identified security
B with loan quantity and fee/rate unchanged; require `Substitution`. Independently test only the
return, only the delivery, two returns, two deliveries, A returned and A redelivered, reordered
movements, quantity changed, and fee/rate changed. Compare resolved security identity rather than
movement-list position or display text.

## Uniqueness meta-probe

For every public and evaluator fixture, execute or instrument every candidate predicate before any
priority selection. Record the complete matching set. Require one member for each positive case and
zero for every `Unqualified` case; reject multiple matches even if `QualifyEvent` happens to return
the expected first enum. Specifically assert that the zero/Terminated fixture does not also match
`PartialReturn`, and the substitution fixture does not match a generic terms-change/re-rate rule.

If predicates are not public, adapt a package-level evaluator test or inspect the candidate's own
predicate diagnostic. Do not accept an `if/else` ordering as proof of mutual exclusivity without a
test that evaluates the underlying conditions independently.

## Ownership, aliases, and determinism

Build the carrier from a mutable primitive list, mutate the original list after construction, and
attempt mutation through every exposed collection. The result must remain unchanged. Recreate equal
generated inputs as distinct objects, reorder primitives and collateral movements, and rerun in a
new qualifier instance. Require identical results with no current-clock, default-zone, mutable
static, random, or object-identity dependency.
