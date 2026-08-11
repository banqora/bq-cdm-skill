# Evaluator probes

Keep these checks evaluator-owned until every candidate arm has exited and its deliverable has been
committed. Adapt only the public API wiring; do not change the economics by arm.

- Re-run the stated USD 500m, 5.30%, four-hour ACT/360 example and require USD 12,268.52.
- Cross midnight from 22:00Z to 01:00Z and require the exact three-hour amount.
- Express one interval with `Europe/London` and `Asia/Hong_Kong` zone IDs and compare money values
  and currencies exactly.
- Cross a London daylight-saving boundary and require actual elapsed seconds rather than local-clock
  hours.
- Check equal timestamps, a positive sub-second interval, and a one-nanosecond reversed interval;
  the first two are zero and the last rejects.
- Compare a 24-hour result to the independently calculated one-day amount under ACT/360, then show
  ACT/365 Fixed differs and matches its own independent calculation.
- Try an unsupported CDM day-count enum, missing currency/unit, zero or negative nominal, null input,
  and an invalid rate according to the candidate's documented contract.
- Inspect and, when practical, execute structural and applicable inherited validation for the CDM
  object emitted by the implementation.
- Re-run from a clean offline copy and inspect for `double`, `float`, default-zone, current-clock,
  calendar-date subtraction, premature cent rounding, or hidden mutable/static state.

## Executed adaptive probes

After all four arms were sealed, the evaluator adapted the following checks only at the public API
wiring boundary:

1. A London daylight-saving transition uses actual elapsed seconds.
2. A close one nanosecond before open rejects before whole-second truncation.
3. ACT/365 Fixed produces its distinct independently calculated amount.
4. An unresolvable ISO currency code rejects at the application boundary.
5. A `Money.unit` carrying both `currency` and `financialUnit` rejects under the generated
   `UnitType: one-of` condition.
6. A `Money` carrying inherited `datedValue` content rejects under
   `QuantityDatedValueIsAbsent`.

Claude Fable 5 independently recreated all six probes and reproduced every result. It then added
three public-contract edge checks: an unsupported basis at zero duration, an unsupported basis at
zero rate, and JPY minor-unit rounding. These reviewer-owned checks exposed fail-open basis guards
in both GPT arms and a fixed-two-decimal currency policy in the GPT treatment.
