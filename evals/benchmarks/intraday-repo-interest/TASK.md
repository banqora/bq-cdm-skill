# Intraday repo interest discovery benchmark

Implement a production-oriented intraday repo interest calculator in Java 21 against FINOS CDM
7.0.0:

```text
ComputeIntradayInterest(openTimestamp, closeTimestamp, nominal, rate, basis)
```

Design an appropriate public Java API around that operation. Use genuine generated CDM 7.0.0
objects at a defensible input or output boundary, while keeping any behavior the model does not own
in an explicit application layer. Do not edit generated CDM classes or invent fields on them.

Interest accrues on actual elapsed time:

```text
nominal * rate * (elapsed whole seconds / 86,400) / day-count basis
```

Rates are decimal fractions, so 5.30% is `0.053`. Use exact decimal arithmetic and round the final
cash result to the currency's cent. Timestamps represent real instants and include enough offset or
zone information to make cross-border comparisons unambiguous. A positive duration shorter than one
whole second accrues zero. A close before open is invalid and must fail visibly.

Implement these focused tests:

1. **Baseline.** USD 500,000,000 for exactly four hours at 5.30%, ACT/360 produces USD 12,268.52.
2. **Midnight trap.** Opening at 22:00 UTC and closing at 01:00 UTC the next day accrues three hours,
   not one calendar day.
3. **Cross-border normalisation.** Express the same opening and closing instants once in London local
   time and once in Hong Kong local time. Both representations produce exactly the same interest.
4. **Degenerate duration.** Opening and closing within the same second produces zero, never a
   negative amount or `NaN`; closing before opening hard-fails.
5. **Continuity.** A full 24-hour trade produces exactly the same rounded result as one day of
   conventional overnight interest under the selected basis.

Support ACT/360 and ACT/365 Fixed, reject unsupported conventions, and preserve the nominal's
currency in the result. Choose reasonable validation and failure semantics for missing values,
non-positive nominal, invalid rates or unsupported units. Do not mutate caller input or CDM objects.
Add focused tests for the five required cases and close negative controls that defend the design.

Add a short `DESIGN.md` explaining the chosen CDM 7.0.0 boundary, the ownership of the intraday
elapsed-time rule, the precision and rounding policy actually used, and which generated validation
was executed rather than assumed.

The workspace contains the pinned CDM 7.0.0 binary and source JARs under `lib/`. Work offline, keep
the existing dependency declaration unless it is genuinely broken, and run the complete suite with
Gradle 8.10 and Java 21.
