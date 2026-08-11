# Securities-loan event qualifier

Implement a production-oriented securities-loan event qualifier in Java 21 against FINOS CDM
7.0.0:

```text
QualifyEvent(beforeState, primitiveInstructions, afterState)
```

Return exactly one of `Increase`, `PartialReturn`, `FullReturn`, `ReRate`, `Substitution`, or
`Unqualified`. Deduce the result purely from what the primitives did and the relevant before/after
state; never select it from an event name, qualifier, intent, or other label.

There is one necessary Java-boundary detail. In CDM 7.0.0, intent is carried at the event-instruction
layer and is not a field on `PrimitiveInstruction`. Keep the conceptual operation above, but define
a small application-owned event input/carrier that supplies genuine generated CDM `TradeState`
before/after values, genuine generated `PrimitiveInstruction` values, and optional generated
`EventIntentEnum`. Do not edit generated classes or invent a generated primitive field. The exact
surrounding Java types are yours to design.

The classifications mean:

- `Increase`: the on-loan quantity increased.
- `PartialReturn`: it decreased but remains positive.
- `FullReturn`: it reached zero and the position is terminated.
- `ReRate`: the loan fee/rate changed while quantity and collateral did not.
- `Substitution`: collateral A was returned and distinct collateral B delivered while loan quantity
  and fee stayed unchanged.
- `Unqualified`: none of those meanings is established.

Tests:

1. Quantity change 100,000 to 60,000 gives `PartialReturn`. Quantity change 100,000 to zero with
   `closedState=Terminated` gives `FullReturn`.
2. Quantity reaches zero but closed state is absent: `Unqualified`, not `FullReturn`. Quantity
   arithmetic alone is insufficient.
3. A primitive instruction containing the zeroing quantity change plus a terms change must not
   qualify as `FullReturn`, even when the other termination facts hold. Extraneous primitives
   disqualify: this is CDM `only exists` semantics, not a “contains quantityChange” test.
4. Give the otherwise-valid full return `intent=Novation`: it must not qualify as `FullReturn` and
   should be `Unqualified`. Intent is a guard, never positive classification evidence.
5. Run all candidate qualifiers over every fixture and assert exactly one fires, or zero and the
   result is `Unqualified`. In particular, `PartialReturn` must not also fire at zero quantity.
6. Two collateral movements—return security A and deliver security B—with loan quantity and fee
   untouched give `Substitution`. This depends on what did not change as well as what did.

Include a straightforward positive case for `Increase` and `ReRate` so every result is implemented.
Use real CDM primitive and economic fields rather than parallel string tags or booleans. Treat the
primitive list as one event regardless of ordering, write focused tests, and explain any deliberately
partial CDM fixture or validation boundary in a short `DESIGN.md`.

The workspace contains pinned CDM 7.0.0 binary and generated-source JARs under `lib/`. Work offline
with the existing Gradle 8.10/Java 21 seed and run the complete test suite.
