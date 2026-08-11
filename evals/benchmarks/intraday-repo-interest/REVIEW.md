# Independent review: intraday repo interest

Claude Fable 5 independently reviewed the four sealed implementations, their authored tests and
design notes, the fixed task and rubric, execution traces, evaluator probes, and the pre-run
`cdm-dev` snapshot. It modified no candidate or benchmark contract.

## Verification

- All four authored suites passed again from clean offline Java 21/Gradle 8.10 copies:
  Sonnet treatment 15/15, Sonnet control 14/14, GPT-5.4 treatment 8/8, and GPT-5.4 control 11/11.
- The reviewer independently recreated the six adaptive probes and reproduced the recorded matrix
  exactly.
- The pinned CDM 7.0.0 artefacts confirm that `Money` inherits the quantity conditions and that
  `UnitType` declares a `one-of` condition. The generated `UnitTypeUnitType.Default` rule rejects a
  unit carrying both `currency` and `financialUnit`.
- No production arm uses `double`, `float`, the current clock, the default time zone, `LocalDate`,
  or calendar-date subtraction for elapsed interest.
- No fatal rubric cap triggered and the traces show no benchmark, oracle, rubric, sibling-arm, or
  control-to-skill leakage.

## Results

| Arm | Score | Fixed probes | Authored tests | Wall time |
|---|---:|---:|---:|---:|
| Claude Sonnet 5 + skill | **96/100** | 5/6 | 15/15 | 780 s |
| Claude Sonnet 5 control | **93/100** | 4/6 | 14/14 | 660 s |
| GPT-5.4 + skill | **91/100** | 4/6 | 8/8 | 496 s |
| GPT-5.4 control | **96/100** | 6/6 | 11/11 | 382 s |

All four got the core economics right: the hand calculation, midnight crossing, cross-border
normalisation, daylight-saving interval, reversed/sub-second guards, ACT/360 versus ACT/365 Fixed,
and 24-hour continuity.

### Claude Sonnet 5 with the skill

The treatment ran the strongest generated-validation wiring: root structural validation and every
registered `Money` data rule on both input and output, through a real `CdmRuntimeModule`. It detected
that the resolved Guice version silently failed to inject the generated factory and repaired the
runtime environment. It also used the currency's actual minor unit and validated unsupported basis
before zero-result shortcuts.

It lost three CDM-boundary points because root validation did not recurse into `Money.unit`; a
mixed currency/financial unit therefore passed despite the child `UnitType: one-of` condition. Its
rate-validation policy was also undocumented. Final score: **96**.

### Claude Sonnet 5 control

The control used genuine CDM `Money` and generated day-count leaves, normalized timestamps to
instants, and documented the domain-correct decision to permit negative repo rates. It independently
found the same injection problem and bypassed only the broken DI layer by constructing simple
generated leaves directly.

It ran only `MoneyValidator` plus manual currency checks, so it missed both the inherited
`QuantityDatedValueIsAbsent` rule and the nested `UnitType` choice. Final score: **93**.

### GPT-5.4 with the skill

The treatment explicitly ran structural, type-format, currency-unit, schedule, quantity, and
inherited validation on input and output. Its elapsed-time implementation is correct and remains
application-owned.

It missed the nested `UnitType` choice, accepted unresolvable currency `ZZZ`, hardcoded two decimal
places for every currency, and returned zero before checking an unsupported basis for a zero-length
interval. Final score: **91**.

### GPT-5.4 control

The control produced the strongest numeric implementation: an exact rational numerator and
denominator followed by one final currency-scale division, avoiding even theoretical DECIMAL128
double rounding. It alone passed all six fixed probes by combining generated validation with manual
unit exclusivity, ISO currency resolution, and currency minor-unit handling.

It did not re-run generated validation against the constructed output and its zero-duration or
zero-rate shortcuts bypassed unsupported-basis validation. Its blanket negative-rate rejection is
economically questionable for repo, but the public task allowed the rate policy to be chosen, so it
was advisory rather than scored. Final score: **96**.

## Treatment effect

The skill was a real but non-uniform benefit:

- For Sonnet it improved correctness by 3 points, principally by making inherited data-rule
  execution explicit. It cost 18% more total wall time, although the many cheap source queries meant
  its first production write actually arrived sooner: 290 seconds versus 355 seconds.
- For GPT-5.4 it reduced correctness by 5 points and cost 30% more wall time plus 2.8 times the input
  tokens. The generated-validation checklist displaced useful application-boundary judgment rather
  than complementing it.

This is therefore a mixed benchmark, not evidence that the skill universally improves an already
strong model. It does show more value for the less reliable CDM implementation path: Sonnet gained
the inherited rule that its control missed.

## Evidence-backed skill improvements

The post-run revision makes four generic changes, none containing the benchmark solution:

1. It requires validation of every populated generated child because root validators and
   `Meta.dataRules()` do not recurse. This directly addresses the model-invalid `UnitType` accepted
   by both treatment arms.
2. `cdm-source type` now lists conditioned direct-field types across the requested type's
   inheritance chain, so a `Money` query exposes the child `UnitType: one-of` rule in the same pass.
3. It turns the existing evidence budget into an early hard handoff: one declaration query, one
   combined API query, then a populated compile. The helper prints the same compile-next cue.
4. It requires a positive/negative injection smoke test and requires all options to validate before
   zero, empty, replay, or no-op shortcuts.

The reviewer also noted that negative repo rates are economically possible. The securities-financing
guide now warns against inventing a non-negative-rate rule without a caller or model contract.

## Reviewer-added checks

Beyond the frozen six-probe matrix, Fable tested unsupported bases at zero duration and zero rate,
plus JPY minor-unit rounding. Both GPT arms failed at least the zero-duration basis check; GPT control
also failed it for zero rate, and GPT treatment returned hundredths of a yen. These checks are saved
as evaluator guidance rather than retroactively changing the fixed task or rubric.
