# Pilot run — not a counted arm

This benchmark is authored but has no counted skill/control arms yet, so it is deliberately
absent from `index.json` (the manifest schema requires an observed baseline with both arms).
This file records the single pilot run that proves the task is well-posed, executable, and
discriminating. The pilot was performed on 2026-08-26 by the same session that authored the
task and rubric, with the `cdm-dev` skill active and this repository readable, so it is
contaminated by construction and must never be scored or compared against future arms.

## Environment

- macOS, Claude Code session; JDK 21.0.12.1 (Homebrew openjdk@21), Gradle 9.7.1.
- `org.finos.cdm:cdm-java:7.0.0` from Maven Central, SHA-256 verified against the pinned
  fixture digest in `index.json`; rune-runtime 10.2.2 resolved transitively.
- CDM paths grounded with the bundled helpers before implementation: `cdm-find` located the
  declarations, `cdm-source type` confirmed `Price` (decimal-fraction rate, mandatory
  `priceType`, `CurrencyUnitForInterestRate`), `NonNegativeQuantity`, `TradeIdentifier`, and
  the four `PriceExpressionEnum` values, and `cdm-java-api` confirmed the generated builders
  and validator classes in two batched queries.

## What ran

A reference implementation of the full contract (`Project`/`Parse` over a bounded
auth.030-style fragment) plus a deliberately naive projection committing the four classic
breaks (no rate-basis conversion, absence emitted as zero, `Double.toString` reaching the
wire, offset timestamps, and a percentage-family enum collapse). One JUnit 5 suite exercises
both: 23 tests in 6 groups, all passing.

| Group | Tests | Result |
|---|---:|---|
| Rate basis (100x seam, zero, sign) | 3 | pass |
| Absence three-way distinction | 4 | pass |
| Decimal canonicalisation and digit limits | 4 | pass |
| Round-trip idempotence, UTC, enum bijectivity | 5 | pass |
| CDM boundary fidelity (generated validation) | 2 | pass |
| Break matrix (naive fails every family) | 5 | pass |

Verified concrete behavior: `0.0525` projects as `<FxdRate>5.25</FxdRate>` and parses back
exactly; a notional held as `1.23E7` serialises as `12300000`; the naive arm emits
`<FxdRate>0.0525</FxdRate>`, `<NtnlAmt Ccy="EUR">1.23E7</NtnlAmt>`,
`<OthrPmtAmt Ccy="EUR">0.0</OthrPmtAmt>`, a `+00:00` timestamp, and collapses
`ParValueFraction` onto the `PercentageOfNotional` code — and the suite detects every one.

## Findings that harden future evaluation

- `com.rosetta.model.lib.validation.ValidatorFactory.Default` (rune-runtime 10.2.2) is not
  bare-constructible: `PriceMeta.validator(new ValidatorFactory.Default())` raises a
  NullPointerException inside `create`. The working injection-free route is the generated
  per-type validators (`cdm.observable.asset.validation.PriceValidator`) and the generated
  data-rule `Default` classes
  (`...validation.datarule.PriceScheduleCurrencyUnitForInterestRate.Default`), all of which
  have public no-arg constructors. Evaluator probes should use that route.
- A naive "no scientific notation" probe on the whole document false-positives on `E` in
  currency codes and UTI text; the probe must match digit-adjacent exponents.
- Under Gradle 9 the fixture needs `testRuntimeOnly("org.junit.platform:junit-platform-launcher")`;
  Gradle 8 (the version the task names) does not.

## What this does not claim

No skill-versus-control comparison, no score, no baseline. Counted arms must follow the
standard protocol: isolated sessions, controls unable to read this repository or the skill,
and evaluator reveal only after every arm exits.
