# Independent review: repo fail and mini close-out

Claude Fable 5 independently reviewed the four sealed implementations, authored tests, design
notes, fixed task and rubric, evaluator probes, execution traces, and the pre-run `cdm-dev`
snapshot. It changed no candidate workspace. All evaluator additions lived in separate clones.

## Verification

- All four committed candidates rebuilt offline with Java 21, Gradle 8.10, and pinned CDM 7.0.0:
  Sonnet treatment 21/21, Sonnet control 20/20, GPT-5.4 treatment 6/6, and GPT-5.4 control 14/14.
- Fable adapted the fixed probes only to each public API and then reran every authored suite. All
  evaluator and authored tests passed after the probes were added.
- Every arm produced the required single EUR 300,000 end-leg net payment, isolated the selected
  trade, floored negative interest during the tested fail days, resumed at EUR 138.89, and used the
  offer for the start-leg EUR 1,000,000/EUR 200,000 replacement examples.
- Generated CDM 7.0.0 validators were run directly against each returned lifecycle object and any
  emitted CDM `Money`; validator findings were not inferred from candidate documentation.
- Static checks found no `double`/`float`, current-clock/default-zone dependency, `Math.abs`
  direction repair, or random state in any arm.
- No fatal rubric cap triggered and no task, rubric, probe, skill, or sibling-arm content leaked
  into a control. One shared Gradle daemon exposed sibling path names only, after the design was
  written; future arms now use a private `GRADLE_USER_HOME` and no daemon.

## Results

| Arm | Score | Fixed public probes | Authored tests | Wall time |
|---|---:|---:|---:|---:|
| Claude Sonnet 5 + `cdm-dev` | **99/100** | pass | 21/21 | 1,850 s |
| Claude Sonnet 5 control | **94/100** | pass | 20/20 | 1,427 s |
| GPT-5.4 + `cdm-dev` | **87/100** | pass | 6/6 | ~633 s |
| GPT-5.4 control | **93/100** | pass | 14/14 | ~665 s |

| Rubric criterion | Sonnet + skill | Sonnet control | GPT + skill | GPT control |
|---|---:|---:|---:|---:|
| Single net close-out payment (20) | 20 | 20 | 20 | 20 |
| Failed-trade scope isolation (22) | 22 | 22 | 22 | 22 |
| Negative-rate fail economics (22) | 22 | 22 | 18 | 22 |
| Offer-side valuation (18) | 18 | 18 | 17 | 18 |
| CDM lifecycle boundary (12) | 12 | 7 | 6 | 6 |
| Validation and engineering (6) | 5 | 5 | 4 | 5 |

### Claude Sonnet 5 with the skill

This was the strongest implementation. Its returned `TradeState`, populated children, terminated
`ClosedState`, and emitted CDM `Money` all passed the generated validator sweep. The CDM graph
contains real repo economics, parties, an ISIN security, ordered asset legs, and the required
`ClosedState.activityDate`. It also ran structural, type-format, and registered data-rule
validation per populated node.

The remaining defect is in the validation harness: it string-matches null-injection failure text
and skips those generated rules. Although the skipped rules and limitation are documented, matching
exception wording can hide a genuine failure. Final score: **99**.

### Claude Sonnet 5 control

The control was economically excellent and especially strong on immutable inputs, explicit
rejection types, and negative tests. Its lifecycle output is nevertheless invalid in CDM 7.0.0:
every terminated `ClosedState` omits the required `activityDate`. Its five root validators do not
invoke `ClosedStateValidator`, so its validation claim misses exactly the child it changes. Repo
economics also remain outside CDM. Final score: **94**.

### GPT-5.4 with the skill

This arm was efficient and passed the visible cases, but its fail-window state has a real temporal
bug. It accrues the whole gap since the last call using only the current call's `failResolved` flag.
If processing skips a still-failed day and lands on a resolved day, the skipped fail day is accrued
at the unfloored contractual negative rate: the probe emitted EUR 277.78 to the failing seller.
Resolution also clears the fail state, leaving no public path for later normal processing.

Its direct-value start-leg examples use the correct offer, but its end-leg quote path chooses bid.
The CDM boundary is an identity shell: accepted and returned `Trade` objects fail required
`product`, `tradeLot`, `counterparty`, and `tradeDate` cardinalities. The `ClosedState` it creates is
valid and explicitly validated, but the failing `TradeValidator` is never run. Close-out amounts
also lack a final currency-scale rounding step. Final score: **87**.

### GPT-5.4 control

The control's day-by-day state makes the skipped-window bug structurally impossible and records
resolution as a date. It passed every economic probe. Its CDM boundary is still hollow: an empty
`NonTransferableProduct` and empty counterparties satisfy parent presence checks while failing
their own validators. Its validation also rejects any portfolio operation when an unrelated
bystander trade is outside its date window, which is an over-broad guard for a selected-trade
operation. Final score: **93**.

## Treatment effect

The skill's effect differs by model:

- For Sonnet, it produced a genuinely better CDM implementation: **+5 points**, entirely from the
  model boundary and generated validation. The price was 30% more wall time, 56% more reported
  subscription-accounted spend, and about 50 source/API helper calls despite the skill's bounded
  query instruction. Here the extra work bought correctness, but much of the browsing was avoidable.
- For GPT-5.4, the skill cut input tokens by about 42% and reduced commands from 47 to 35, but the
  implementation scored **6 points lower** than control. The benefit was efficiency, not quality;
  the per-call flag design introduced the experiment's only fail-period economic bug.

The helpers themselves were useful: treatment arms resolved generated types without unpacking the
JAR, while controls used full source extraction or repeated raw JAR inspection. The remaining
efficiency problem was an unenforced query budget in the Sonnet treatment and insufficient boundary
judgment in the GPT treatment.

## Evidence-backed skill changes

The post-run skill revision is not credited to either treatment arm. It makes these generic changes:

1. `cdm-source type` accepts a bounded batch, while `cdm-java-api` resolves unambiguous simple names
   to exact packages and reports ambiguous candidates. After the initial pair, agents batch only
   compiler-named symbols once per compile cycle; five helper batches trigger a boundary re-check.
2. A boundary claimed complete must pass its root validator and every populated generated child's
   validator. Empty generated shells added only to satisfy a parent's cardinality are explicitly a
   validation smell. Intentionally partial typed fixtures remain allowed when labelled honestly.
3. The Rosetta guide now gives a mechanical graph-validation recipe and requires the visited
   validator/type set to be asserted, addressing both missed-child failures in this run.
4. Generated-rule exceptions or missing dependency injection can no longer be called success by
   matching error text. The dependency must be wired, a dependency-free rule selected with source
   evidence, or the validation claim narrowed.
5. Date-scoped application policy must be recorded as reconstructible start/end state and evaluated
   per processed date, with tests that skip dates and continue after closure. This directly targets
   the generic state-model failure behind the GPT treatment bug.
6. Every emitted amount, including a netted result, must assert currency, direction, and the
   supported minor-unit scale after one final rounding step.
7. The securities-financing guide now separates transaction-level settlement remedies from a full
   counterparty close-out and keeps fail policy, valuation side, and direction application-owned
   unless the active model or project actually executes them.

These changes preserve the skill's intended boundary: it teaches agents how to discover and prove
version-correct CDM integration and how to expose application policy explicitly; it does not teach
the benchmark's EUR examples or prescribe a mini close-out implementation.
