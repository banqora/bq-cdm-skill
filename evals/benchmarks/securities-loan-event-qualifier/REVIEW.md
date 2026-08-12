# Independent review: securities-loan event qualifier

Four sealed implementations were built from the same open-design task against Java 21 and
FINOS CDM 7.0.0. Claude Sonnet 5 and GPT-5.4 each ran once with the frozen `cdm-dev` snapshot and
once without it. Correctness was assessed after all four commits were sealed; evaluator code was
never present in a candidate workspace.

## Verification

- Every authored suite rebuilt offline from a clean copy: Sonnet treatment 19/19, Sonnet control
  9/9, GPT-5.4 treatment 8/8, and GPT-5.4 control 6/6.
- The task, rubric, evaluator probes, CDM JARs, and treatment skill snapshot retained their frozen
  SHA-256 values. Candidate production trees remained clean at their sealed commits.
- Controls had no task-local skill and could not read this repository, global skill/plugin roots,
  sibling workspaces, or evaluator files. Claude ran in safe mode with no skills, plugins, or MCP
  servers; Codex ignored user configuration and disabled skills, plugins, apps, MCP, browsing, and
  delegation. API/provider environment overrides were removed from every local-subscription run.
- Separate evaluator owners adapted the frozen probes only to each public Java API. Claude Fable 5
  then repeated the exercise in a fifth isolated, read-only review session and wrote its own tests
  without reading the first evaluators' results.
- No fatal rubric condition triggered in any arm.

## Results

The stricter evaluator scores are the durable benchmark result because those probes independently
mutated the primitive envelope, the actual transfer direction/identity payload, and the matching
before/after state. Fable's independent scores are also retained because they corroborate the
within-model treatment direction and expose where evaluator adaptation affects absolute scores.

| Arm | Strict score | Authored | Strict evaluator | Fable score |
|---|---:|---:|---:|---:|
| Claude Sonnet 5 + `cdm-dev` | **81/100** | 19/19 | 9/16 pass | **95/100** |
| Claude Sonnet 5 control | **71/100** | 9/9 | 10/19 pass | **90/100** |
| GPT-5.4 + `cdm-dev` | **78/100** | 8/8 | 10/15 pass | **82/100** |
| GPT-5.4 control | **89/100** | 6/6 | 13/16 pass | **84/100** |

### Strict rubric scores

| Criterion | Sonnet + skill | Sonnet control | GPT + skill | GPT control |
|---|---:|---:|---:|---:|
| Quantity deduction and conjunction (18) | 16 | 16 | 16 | 15 |
| Only-exists primitive semantics (18) | 15 | 15 | 14 | 18 |
| Intent as guard only (10) | 10 | 9 | 10 | 10 |
| Re-rate and substitution (20) | 16 | 12 | 13 | 17 |
| Uniqueness and Unqualified (16) | 11 | 9 | 11 | 14 |
| CDM boundary and validation (12) | 8 | 5 | 9 | 10 |
| Engineering and reproducibility (6) | 5 | 5 | 5 | 5 |
| **Total** | **81** | **71** | **78** | **89** |

## What each implementation got wrong

### Sonnet with the skill

This is materially better than its control, not merely more elaborate. It reads actual transfer
security identifiers and reconciles them with the collateral state delta, checks quantity-change
direction, exposes all matching predicates, throws on overlap, and is the only arm to run generated
validators against its relied-on CDM leaves with an honestly limited claim.

Its fixed-probe failures are still important:

- it treats a missing quantity as zero, allowing a terminated but quantity-absent state to become
  `FullReturn`;
- duplicate quantity changes collapse into one populated-kind set;
- missing fee data throws rather than returning `Unqualified`;
- it inspects only one `TransferInstruction`, so two one-leg instructions are not treated as one
  order-independent event; and
- it never reads payer/receiver direction, so two returns or two deliveries can qualify as a
  substitution.

The populated quantity-change leaf validates. The transfer leaf is deliberately partial and lacks
required payer/receiver data; its fee leaf passes structural validation but not the applicable
interest-rate currency data rule. Those limits are documented rather than presented as a valid
whole trade.

### Sonnet control

The control has sound null propagation, exact interest-rate leaf filtering, numerical
`BigDecimal.compareTo`, immutable inputs, and a complete primitive-field union. Its substitution
predicate, however, never reads a transfer payload. A transfer with no legs, one leg, two returns,
two deliveries, or securities unrelated to the before/after collateral change can qualify merely
because a transfer slot exists and the state changed. It also ignores the quantity primitive's own
direction, treats missing fee as unchanged, collapses duplicate quantity changes, and exposes a
predicate roster in which `FullReturn` still fires under Novation even though the outer operation
returns `Unqualified`. No generated validation tier is executed.

### GPT-5.4 with the skill

This arm handles absent quantity correctly, copies the caller list, evaluates an explicit match
roster, and uses genuine CDM boundaries. It does not inspect quantity-change direction. Its
substitution logic checks two distinct `Asset` objects but neither payer/receiver direction nor
resolved security identity; two same-direction or incomplete movements qualify, and two objects
representing the same ISIN can be mistaken for different collateral. Its ReRate comparison uses
whole `InterestRatePayout.equals`, so an unrelated payout-field change or a scale-only decimal
representation change can be misclassified as a fee change. It also admits quantity plus transfer
under a quantity-only shape because that slot is omitted from the exact-population check.

### GPT-5.4 control

The control has the strongest transfer-direction predicate: it requires distinct security
identifiers and reversed payer/receiver references. It also passes every compound-primitive probe.
Its quantity extractor reduces absence to zero, so a missing quantity can become `FullReturn`.
Its ReRate signature includes every `PriceSchedule`, not just an interest-rate fee; an unrelated
asset-price change therefore qualifies, and list/`BigDecimal.equals` makes a scale-only change look
economic. Its input list is immutable, but the public candidate-diagnostic `EnumMap` is mutable.

## Why Fable's absolute scores differ

Fable independently ran 50 evaluator probes for Sonnet control, 43 for Sonnet treatment, 42 for
GPT control, and 43 for GPT treatment. It found no failure in Sonnet control, one in Sonnet
treatment, three in GPT control, and four in GPT treatment. Its report nevertheless identified the
same static weaknesses: Sonnet control reads transfer shape rather than contents; Sonnet treatment
omits payer/receiver; GPT treatment ignores movement direction and compares a whole payout; GPT
control coerces absence to zero and uses an unfiltered, scale-sensitive rate signature.

The numerical difference comes from fixture adaptation. Fable represented a "return" or
"delivery" for Sonnet control through the before/after collateral set because that candidate's
transfer fixture has no meaningful legs. The stricter evaluator instead populated contradictory
real transfer payloads and required the classifier to reject a disagreement between the primitive
and the state. It also exercised split transfer instructions and duplicate primitive kinds. That
better matches the frozen requirement to deduce what the primitives did and to treat their list as
one event, so the stricter score is primary. Fable's qualitative result remains valuable and agrees
on both treatment-effect signs.

## Treatment effect and efficiency

| Pair | Correctness effect | Wall time | Navigation effect |
|---|---|---:|---|
| Sonnet 5 | **+10 strict points** (+5 Fable) | 1,056 s vs 803 s, **31% slower** | 98 vs 85 turns; treatment did much more bounded-model inspection |
| GPT-5.4 | **-11 strict points** (-2 Fable) | 563 s vs 502 s, **12% slower** | 49 vs 67 commands; 38 vs 55 commands before the first production write |

For Sonnet, the extra time bought real CDM correctness: grounded transfer identities, quantity
direction, ambiguity detection, and scoped generated validation. It also included avoidable work:
25 `cdm-inspect` and 13 `cdm-source` invocations, failed over-broad batches, and a prohibited root
scan. For GPT-5.4, the helper reduced command count and time-to-first-edit, but the narrower design
dropped semantically load-bearing direction/identity evidence; the skill did not improve the final
implementation.

The skill therefore provides value, but not reliably across models. Correctness-first use is
justified for Sonnet in this run. The GPT result is a regression and prevents claiming a general
quality lift.

## Evidence-backed skill changes after the run

These changes are not credited to either treatment arm:

1. Lifecycle classifiers now use an evidence triangle: exact primitive envelope/cardinality,
   semantic payload direction/roles and resolved identity, and the corresponding before/after state
   delta. Each column must be independently mutated. `only exists` proves populated field names,
   not payload correctness or instruction cardinality.
2. The pattern catalogue now requires typed-leaf and unit selection, fail-closed handling for
   missing or multiple values, numerical Java `BigDecimal.compareTo` rather than `equals`, and a
   scale-equivalent negative. Twenty-one deterministic catalogue/mutation tests preserve these
   obligations.
3. `cdm-source` now offers bounded `members` and inherited `path` views, exact Rune function and
   qualification inspection, batch-wide name preflight, and capped in-memory search. `cdm-inspect`
   maps functions to the generated `.functions.*` API and `$NameDefault`; `cdm-java-api` aggregates
   every simple-name error before failing. These changes directly address the large-source fallback
   seen in both treatment traces.
4. The navigation guide leads with compact member/path inspection and includes copyable function
   and qualification examples before the full vertical-slice report.

The revised guidance is mechanically guarded and the helpers pass real CDM 7.0.0 smoke tests, but
the post-run revision has not yet earned forward-model credit. It should be evaluated on a fresh,
non-securities-loan lifecycle classifier before promotion as proven general lift.

## Forward rerun: compact search helpers and evidence triangle

On 2026-08-12 the identical frozen task, rubric, evaluator contract, Java 21 seed, and CDM 7.0.0
artifacts were rerun against the revised skill at commit `1da57b2`. The revision includes the
lifecycle evidence triangle, compact `cdm-docs` search, bounded `members`/`path` views, exact
function/qualification inspection, and safer generated-API lookup. Claude Sonnet 5 and GPT-5.4 were
repeated to permit a within-model comparison with the first experiment; Claude Opus 5 was added as
a third matched pair.

All six candidates ran sequentially in isolated one-session workspaces. Controls had no skill and
could not read this repository, global skills/plugins, sibling arms, or evaluator material.
Treatments received only the exact committed task-local skill. Every authored suite and clean-copy
offline build passed before evaluator probes were revealed. No fatal rubric cap triggered.

### Correctness result

| Criterion | Sonnet + skill | Sonnet control | GPT + skill | GPT control | Opus + skill | Opus control |
|---|---:|---:|---:|---:|---:|---:|
| Quantity deduction and conjunction (18) | 15 | 15 | 17 | 16 | 18 | 16 |
| Only-exists primitive semantics (18) | 14 | 14 | 18 | 16 | 17 | 14 |
| Intent as guard only (10) | 10 | 10 | 10 | 10 | 10 | 10 |
| Re-rate and substitution (20) | 16 | 11 | 18 | 8 | 20 | 16 |
| Uniqueness and Unqualified (16) | 10 | 12 | 14 | 14 | 16 | 14 |
| CDM boundary and validation (12) | 6 | 5 | 9 | 7 | 12 | 9 |
| Engineering and reproducibility (6) | 5 | 5 | 5 | 5 | 6 | 5 |
| **Total** | **76** | **72** | **91** | **76** | **99** | **84** |

The treatment effect is positive in all three pairs: **+4 Sonnet, +15 GPT-5.4, and +15 Opus**.
That is a real quality result, but not a uniform one.

- Sonnet treatment correctly checks opposite payer/receiver roles for substitution; the control's
  positive transfer fixture contains no direction at all. Both implementations nevertheless ignore
  the quantity-change direction and amount, collapse duplicate and empty primitives into a set of
  field names, and accept transfer evidence without representing the corresponding collateral
  before/after delta. The skill therefore adds useful CDM semantics but does not make this Sonnet
  solution production-ready.
- GPT treatment is the clearest revision win. It reconciles quantity direction, amount, and unit;
  requires exact primitive cardinality; reads a typed interest-rate payout; and reconciles two real
  transfer movements against collateral identities, quantities, state delta, and opposite parties.
  GPT control models substitution as `quantityChange + termsChange` without transfer primitives at
  all. Treatment's remaining defects are scale-sensitive equality between a restated rate and the
  after-state rate, a mutable diagnostic `EnumSet`, and no executed generated-validator tier.
- Opus treatment is the strongest implementation in the benchmark. Its documented evidence table
  joins exact envelope/cardinality, semantic payload, and state delta; it resolves loan quantity by
  observable and unit, compares typed rates numerically, reconciles transfer quantities and parties,
  handles references fail-closed, and runs extensive generated validators plus negative mutations.
  Its sole focused miss is that an empty extra `PrimitiveInstruction` disappears from the envelope.
  Opus control is sophisticated and well documented, but it ignores quantity primitive payload,
  transfer direction and transfer amount; duplicate and empty primitives also collapse, and its
  public diagnostic set is mutable.

The focused evaluator additions reproduced those claims mechanically: Sonnet treatment passed 1/6
and control 0/5 close-negative probes; GPT treatment passed 0/2 deliberately selected residual
probes while control passed 0/4 central semantic probes; Opus treatment passed 1/2 while control
passed 0/5. Those small counts are not used as raw percentages—the candidate APIs differ and the
tests intentionally target suspected residual defects. Rubric points were assigned criterion by
criterion from the frozen contract, authored tests, focused probes, and source inspection.

### Context-efficiency result

| Pair | Score effect | Wall time | Context/navigation evidence |
|---|---:|---:|---|
| Sonnet 5 | **+4** | 1,060s vs 713s, **48.5% slower** | 111 vs 94 tool calls; cache-read context +45.9%; output +32.6%; first durable source write after 83 vs 60 calls |
| GPT-5.4 | **+15** | 826s vs 538s, **53.6% slower** | 47 vs 57 commands and first write after 40 vs 48, but input +19.5% and output +53.5% |
| Opus 5 | **+15** | 1,772s vs 1,096s, **61.6% slower** | first typed compile at call 31 vs 40, but 145 vs 103 calls, cache-read context +149.9%, and output +48.9% |

The helper feature works mechanically but has not yet produced an end-to-end context-efficiency
advantage. GPT treatment used fewer commands and reached production earlier. Opus treatment used the
new compact documentation search immediately and reached a typed compile earlier. Those are useful
local improvements. They were overwhelmed by continued querying and validation overwork:
treatments issued 55, 24, and 39 helper-bearing tool calls for Sonnet, GPT, and Opus respectively.
Sonnet also fell back to raw source extraction; Opus spent a long tail wiring and proving validators
after its core design was already sound.

The supported conclusion is therefore deliberately split:

1. **Correctness:** the revised skill is useful, with material gains for GPT-5.4 and Opus and a small
   gain for Sonnet on this task.
2. **Context efficiency:** not yet demonstrated. Bounded output is not enough when the agent can
   issue dozens of bounded queries. The next generic improvement should be a small inspection budget
   and a hard handoff such as “one docs query, one batched model query, one API query, then compile;
   only inspect again in response to a concrete compiler or validator failure.” Validation guidance
   likewise needs an explicit stopping tier so a partial typed fixture does not trigger full runtime
   wiring.

This rerun supersedes the earlier sentence saying the revision lacked forward evidence. It does not
retroactively alter the original four-arm scores; both experiments remain recorded in
`baseline.json` so model variance and revision effects are visible rather than averaged away.
