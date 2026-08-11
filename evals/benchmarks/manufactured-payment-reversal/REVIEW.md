# Reviewed result

This open-design benchmark asked each arm to implement the supplied manufactured-payment and
correction behavior against FINOS CDM 7.0.0, while choosing its own Java API, generated CDM
boundary, transfer representation, validation tier, entitlement snapshot, and replay-persistence
seam. The task did not name `ContingentTransfer`, `ScheduledTransfer`, any generated builder or
validator, or the application state shape.

Four isolated, sequential arms ran from local Claude Max or ChatGPT subscriptions. Controls could
not read `cdm-dev`, this repository, historical benchmarks, or sibling workspaces. Every candidate
process exited and its deliverable was committed before evaluator probes were added. All four
authored suites and fresh-clone offline builds passed.

## Independent score

Claude Fable 5 independently read the frozen task and rubric, inspected all sources, tests, design
notes, and traces, and reviewed the adaptive probe results.

| Rank | Arm | Rubric | Authored tests | Evaluator probes | Agent work | Wall time |
|---:|---|---:|---:|---:|---:|---:|
| 1 | Sonnet 5 + `cdm-dev` | 98/100 | 19/19 | 3/3 | 76 turns, 75 tool calls | 12m 38s |
| 2 | GPT-5.4 control | 92/100 | 9/9 | 2/3 | 97 completed items, 69 commands | 9m 19s |
| 3 | GPT-5.4 + `cdm-dev` | 91/100 | 7/7 | 2/4 | 66 completed items, 39 commands | 9m 35s |
| 4 | Sonnet 5 control | 89/100 | 18/18 | 2/3 | 99 turns, 98 tool calls | 13m 45s |

Probe denominators differ only because the GPT treatment's two independent CDM defects were kept as
separate assertions. No arm hit a fatal cap. Every arm passed the requested arithmetic, historical
entitlement, replay, and signed-direction examples; the score differences come from adaptive
correction-identity and generated-model checks that the authored suites did not all contain.

## What the implementations got right

Every implementation computes EUR 42,500 using exact decimal arithmetic, persists the 100,000-share
record-date entitlement, emits the EUR 4,250 correction in the lender-to-borrower direction, and
suppresses an identical replay. Every implementation also supports a later distinct correction from
EUR 0.45 to EUR 0.47 as a EUR 1,700 adjustment from the latest settled entitlement rather than from
the original amount. State is explicit through an injected ledger or immutable caller-owned state;
none hides correctness in a static map or generated CDM field.

The strongest treatment, Sonnet with `cdm-dev`, couples that application design to the correct CDM
7.0.0 movement: a corporate-action `ContingentTransfer`, `Cash` asset, currency-unit positive
quantity, settlement date, and identified payer/receiver parties. It executes the generated
structural validator and content-compares event payloads before classifying a repeated identifier as
an idempotent replay.

## What the adaptive probes found

- Sonnet control uses the affected security as the transfer asset for a cash payment, omits the
  required settlement date, and combines an Instrument asset with a currency quantity unit. Its
  design note incorrectly inferred optionality from absent Java `@Required` annotations; the Rune
  declaration and generated validator are authoritative instead.
- GPT-5.4 treatment uses `ScheduledTransfer.DividendReturn`, whose CDM 7.0.0 definition is a
  synthetic dividend on an equity derivative, not the corporate-action movement in this task. It
  also omits the Cash quantity's currency unit and builds parties without their required identifiers.
- GPT-5.4 control has the strongest generated-validator coverage, but checks only whether a
  correction event ID already exists. Reusing that ID with different economics is silently returned
  as `REPLAYED` instead of failing, so its exactly-once identity is not content-scoped.
- Sonnet treatment's in-memory ledger is a single-node reference adapter rather than an atomic
  production store, and its design overstates the data-rule coverage of the structural validator.
  Those are documented engineering limitations, not failures of the required sequential behavior.

## What value the skill supplied

For Sonnet, the skill produced a nine-point correctness gain and was also faster: 23 fewer tool
calls, 11 fewer calls before the first production write, and 8% less wall time. The gain is not
generic Java style. It is concentrated in CDM ownership, inherited quantity/unit/date invariants,
the correct transfer choice, generated validation, and a mutation-backed negative test.

For GPT-5.4, the pre-run skill produced a mixed result. It substantially reduced navigation work
(39 versus 69 commands and 33 versus 66 commands before the first production edit) and its explicit
state passed the conflicting-replay probe that control missed. But the old securities-financing
reference did not cover corporate-action transfers, and windowed source reading let the model stop
at the first plausible enum name. The control independently explored validators more deeply and
scored one point higher. This is useful negative evidence: a skill only helps if its fast path leads
to the complete owning declaration and inherited rules rather than substituting for them.

## Post-run skill revision

The recorded treatments used the pre-revision snapshot, so none receives credit for these changes:

1. `cdm-source type <fully.qualified.Type>` now prints the complete declaration, inherited base
   declarations and conditions, and sibling subtypes in one bounded query. For
   `ContingentTransfer`, one command exposes `ScheduledTransfer` as an alternative plus the inherited
   required settlement date and `AssetFlowBase.QuantityUnitExists` rule.
2. The main workflow now requires a structural validator and applicable inherited data rules for
   each newly emitted CDM type, and explicitly forbids inferring Rune requiredness from generated
   Java annotations.
3. The securities-financing guide now deep-links manufactured income and corporate-action cash
   movements: product/event/application ownership, `ContingentTransfer`, Cash and unit coherence,
   positive quantity plus payer/receiver direction, party identifiers, settlement date, and the
   application-owned snapshot/replay boundary. It records the `DividendReturn` near-miss without
   teaching the benchmark's correction formula.

These are reusable CDM navigation and model-boundary improvements. Reflection ladders and ordinary
check-then-act concurrency races remain generic Java/application concerns rather than being added to
the CDM skill.
