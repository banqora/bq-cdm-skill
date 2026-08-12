# cdm-dev

A portable agent skill for day-to-day engineering with the FINOS Common Domain Model,
Rune source, released language distributions, generated APIs, and the Rune runtime.

The skill is deliberately application-neutral. It discovers the active project's structure,
uses that project's tests and build commands, and reads model truth from version-matched Rune
source. The included helper uses the corresponding binary `cdm-java` JAR as a Rune source container;
that does not make Java part of a Python, schema, or other application architecture. The skill
does not require a particular repository, framework, mapping layer, or service architecture.

For a new integration, the skill routes the agent through the available Java, Python,
TypeScript, JSON Schema, Excel, and community-generator options in
[`references/onboarding.md`](skills/cdm-dev/references/onboarding.md). Dated market-practice
material from ISDA, ISLA, and ICMA is routed separately through
[`references/industry-bodies.md`](skills/cdm-dev/references/industry-bodies.md).

On-demand domain guides cover the five executable derivative asset-class families, securities
financing, transferable assets and cash securities, Digital Regulatory Reporting, and legal
agreements. Each guide records its research baseline, points back to version-matched Rune source,
and separates CDM or DRR behavior from application policy and legal interpretation.

Recurring engineering hazards are distilled into a small
[implementation-pattern catalogue](skills/cdm-dev/references/implementation-patterns.md). It is
not a library of benchmark formulas: each card says when to use or avoid it, which authority owns
the decision, the implementation shape, the proof required, common wrong turns, and what must be
rechecked on an upgrade. Agents load only the matching card, then confirm it against the active
CDM release and the consuming application's contract.

## Why use this skill?

A capable general agent can eventually reconstruct CDM behavior from raw distributions. This
skill provides a shorter, repeatable route: identify the owning layer, query version-matched Rune
source, inspect only the generated API/runtime evidence that applies, and turn the finding into a
meaningful positive test plus a close negative control.

A context-isolated A/B forward test on 2026-08-07 gave two fresh agents the same CDM 7.0.0 binary
and source JARs and the same `PriceQuantity.quantity` investigation. One agent used `cdm-dev`; the
control could not read the skill, repository documentation, eval rubric, or prior results.

| Measure | With `cdm-dev` | Without skill | Difference |
|---|---:|---:|---:|
| Reviewed quality checks | 7/7 | 7/7 | Tie |
| Tool-call batches | 12 | 42 | 71% fewer with the skill |
| Individual tool calls | 31 | 42 | 26% fewer |
| Shell commands | 33 | 84 | 61% fewer |
| Distinct files inspected | 31 | 35 | 11% fewer |

Both agents reached the correct answer in this single run. The measured benefit was efficiency:
the control needed 3.5 times as many tool-use rounds and more than twice as many shell commands to
reconstruct the workflow supplied by the skill. Counts were self-reported by the agents, so treat
this as a transparent forward-test result rather than a broad performance claim. The local eval
suite below provides the reproducible task and grading foundation for broader trials.

A second isolated A/B on 2026-08-10 asked both agents to implement a three-way tokenisation
classifier: tokenised bond, conventional Gilt repo with tokenised cash settlement, and conventional
Gilt. Both agents used the same CDM 7.0.0 artefacts and completed in one agent turn without a
follow-up.

| Measure | With `cdm-dev` | Without skill |
|---|---:|---:|
| Agent-authored tests | 4/4 pass | 4/4 pass |
| Correct CDM 7.0.0 repo topology | Yes | No |
| Hidden exact-repo-shape probe | `SETTLEMENT_LEVEL` | `NOT_TOKENISED` |
| Exact requested `ClassifyTokenisation(Trade)` method | No (`evaluate`) | Yes |
| Tool-call batches | 48 | 35 |
| Individual tool calls | 107 | 44 |
| Shell commands | 104 | 42 |
| Files read | 49 | 31 |

This run exposed a different benefit and a real cost. The skill-guided agent represented a repo
using the version-correct top-level `InterestRatePayout` and nested collateral
`AssetPayout`; the control labelled a top-level `AssetPayout` as a repo, so its own tests passed
while an independently added correct-shape probe failed. Both agents correctly kept tokenised
securities out of CDM 7.0.0 `DigitalAsset` and put the missing asset/settlement facts behind an
application-owned seam. However, the skill-guided solution took more than twice as many calls and
commands, used a broad reflective graph walk, and missed the requested public method name.

That is the practical reason to use the skill: it supplies versioned domain topology and catches
green-but-wrong CDM fixtures that ordinary implementation work can miss. It is not a guarantee of
faster or automatically better code. This single-run result also produced concrete improvements:
the asset guide now records the two-level tokenisation pattern and targeted traversal paths, while
the testing guide requires an exact requested entry point to be exercised. Counts are
self-reported; the clean 4/4 reruns and hidden probe were independently executed.

The classifier test was repeated with two isolated `claude-opus-5` sessions on 2026-08-10, using
the local Claude Max subscription and no API credential. Both arms reached the 50-turn safety cap
and completed in one continuation session.

| Measure | With `cdm-dev` | Without skill |
|---|---:|---:|
| Claude turns across two sessions | 95 | 91 |
| Wall-clock model duration | 12m 49s | 14m 36s |
| Tool calls | 110 | 91 |
| Agent-authored tests | 8/8 pass | 4/4 pass |
| Exact requested method | Yes | No |
| Correct nested-repo precedence probe | `ASSET_LEVEL` | `SETTLEMENT_LEVEL` |

The correctness result replicated: the skill arm traversed the purchased asset in the nested
collateral product, while the blind arm's self-authored repo kept both payouts at the top level and
missed that path. The skill arm also replaced the earlier reflection sweep with typed traversal and
shipped the exact API. It used more tool calls but finished sooner.

This replication is not a clean estimate of general skill lift: at test time the asset guide
contained a near-worked version of the classifier's repo path, precedence, and test matrix. An Opus
review identified the reusable causes as the versioned securities-financing topology and exact-API
testing rule; the task-specific answer material has now been removed. The same review added a
fixture-fidelity gate and a general containment-route guard. A future unrelated forward test is
needed to measure those changes without corpus overlap.

That unrelated test was run later on 2026-08-10. Four isolated sessions implemented a locate
matching engine over CDM 7.0.0 `SecurityLocate` and `AvailableInventory`: `claude-opus-5` and
`gpt-5.6-sol`, each with and without `cdm-dev`. All four used local subscriptions, received the
same binary/source JARs and task, exposed the exact `MatchLocate` entry point, and passed every
self-authored acceptance test plus independent reruns.

| Arm | Agent-authored tests | Hidden reference-scope checks | Agent work | Wall time |
|---|---:|---:|---:|---:|
| Opus 5 + `cdm-dev` | 12/12 | 2/3 | 78 turns, 77 tool calls | 13m 13s |
| Opus 5 control | 6/6 | 3/3 | 43 turns, 42 tool calls | 7m 56s |
| Codex + `cdm-dev` | 5/5 | 1/3 | 85 completed items, 64 commands | about 20m 30s |
| Codex control | 6/6 | 1/3 | 70 completed items, 54 commands | about 17m 21s |

The ordinary cases did not show a skill lift: every arm correctly separated CDM facts from the
application-owned settlement date and correctly handled inline general/targeted inventory. The
adversarial checks used CDM's actual metadata-reference form across separate roots. The Opus
control was the only implementation to resolve all three correctly. Opus with the skill resolved
valid cross-root references but treated a declared, unresolvable borrower role as absent and hence
general inventory. Codex with the skill failed closed but rejected valid external references.
Codex control compared raw root-local reference strings, causing both a false rejection and the
more serious false authorisation when different borrowers reused the same local key.

This mixed result is useful rather than promotional: the skill did not make either model faster,
and it did not guarantee correctness. It exposed a missing reusable guard. The skill now separates
reference declaration, resolution and object identity; requires resolution within the owning root;
forbids collapsing an unresolved declaration into permissive absence; and prescribes positive and
negative cross-root identity probes. These instructions were added after the run, so the table is
the honest pre-fix result, not evidence that the revision has already improved model behavior.

A third [isolated four-arm test](evals/benchmarks/repo-settlement-shaping/) on 2026-08-10 asked the
same two models to shape a repo's start-leg settlement into capped, paired DvP transfer
instructions. The arithmetic included an exact cap multiple, an under-cap case, and a cent-rounding
residual. All arms used the same pinned CDM 7.0.0 project and local subscriptions; model-authored
tests were rerun before evaluator tests were added.

| Arm | Agent-authored tests | Evaluator probes | Reviewed rubric | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Opus 5 + `cdm-dev` | 14/14 | 4/6 | 93/100 | 115 turns, 114 tool calls | 23m 55s |
| Opus 5 control | 11/11 | 2/6 | 86/100 | 94 turns, 93 tool calls | 17m 5s |
| Codex + `cdm-dev` | 4/4 | 6/6 | 98/100 | 152 completed items, 131 commands | about 29m 5s |
| Codex control | 4/4 | 4/6 | 92/100 | 108 completed items, 96 commands | about 20m 23s |

The six evaluator probes covered reordered `PriceQuantity` entries, a `HALF_EVEN` tie, start-leg
party direction, an empty unresolved party reference, an incomplete one-leg payout, and a non-DvP
near leg. The same correctness gap appeared for both vendors: each skill arm reversed the
`AssetPayout` direction for the repo's start collateral delivery and rejected the empty unresolved
party wrapper; each control emitted the far/repurchase direction and accepted the unresolved
wrapper. Every arm's own tests were green, and both control suites asserted the wrong direction,
which is exactly the kind of plausible CDM error a compile-and-test result does not expose.

This was a correctness win, not a speed win: both controls finished faster with less model work.
The pre-run skill did not contain a worked settlement-shaping answer. It routed the treatment arms
to the version-matched securities-financing topology, shipped repo examples, Rune declarations,
and fixture/negative-control checks. Run logs show both treatment arms using those sources; the Opus
arm also mutation-tested its party reversal. The result supports using the skill when model-semantic
correctness matters more than raw completion time, while remaining only one paired run per model.

The test also found two missing guards: the Opus skill arm accepted an incomplete one-leg payout
and a non-DvP near leg. After recording the baseline, the securities-financing guide was extended
to distinguish trade shaping from settlement shaping, require the ordered near/far and delivery
method checks, preserve start-leg direction, classify quantity candidates structurally, and state
the CDM 7.0.0 bond-nominal unit limitation. The generic testing guide now covers exact-decimal
partitioning and residual allocation. These revisions post-date the table and must not be credited
to it.

A fourth [four-arm benchmark](evals/benchmarks/csa-margin-call-calculator/) tested a smaller
application-owned calculation: derive a delivery, return, or no-call result from resolved CSA
threshold, MTA, independent-amount, and asymmetric rounding elections. It deliberately required
CDM `Money` and `CollateralRounding` but not a complete agreement tree or generated runtime.

| Arm | Agent-authored tests | Evaluator probes | Reviewed rubric | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Opus 5 + `cdm-dev` | 13/13 | 8/8 | 100/100 | 34 turns, 32 tool calls | 6m 17s |
| Opus 5 control | 21/21 | 6/8 | 97/100 | 22 turns, 21 tool calls | 4m 10s |
| Codex + `cdm-dev` | 10/10 | 8/8 | 100/100 | 40 completed items, 27 commands | 8m 17s |
| Codex control | 9/9 | 8/8 | 100/100 | 24 completed items, 17 commands | 5m 9s |

Every arm got the business-critical behavior right: MTA is applied before rounding, equality is
actionable, independent amount is added after flooring unsecured exposure, and a GBP 1.73m return
rounds down to GBP 1.7m rather than up to GBP 1.8m. Opus control nevertheless missed two boundary
guards: it accepted the CDM-required rounding currency as absent and validated only the increment
selected by that call. The corresponding evaluator tests failed; the other three arms passed all
eight.

The skill therefore added a small completeness/validation win for Opus, but the broad-reference
cost was not proportionate to this narrow contract. The treatment arms were 51% slower for Opus
and 61% slower for Codex. Logs made the overhead concrete: the treatment route loaded up to 873
lines from four broad references; Opus made 22 tool calls before its first edit versus 15 for
control, while Codex compiled a signature-only skeleton before inspecting the getters it needed.
Both treatment arms also performed extra mutation/check cycles after their focused suites were
green.

The skill was tightened from that evidence. A resolved-input calculation now has a self-contained
fast path: one combined declaration/builder query, one compiled vertical slice that exercises a
real getter and branch, and one focused test. Broad legal, testing, and workflow guides are reserved
for unresolved questions, and compact deterministic functions use at most one representative
mutation. Those changes post-date the table, so this benchmark is evidence for the problem and the
design of the fix—not evidence that the final fast path is already faster.

A fifth [four-arm benchmark](evals/benchmarks/evergreen-repo-lifecycle/) exercised that revised
fast path with an evergreen repo state machine: a 35-business-day crawl over a bank holiday,
permanent notice freeze, a separate 30-calendar-day LCR horizon, daily simple accrual, and an
exactly-once re-rate/month-end collision. The task supplied the precise CDM termination and
evergreen paths and kept calendars, accrual state, and resolved rate facts application-owned.

| Arm | Agent-authored tests | Evaluator probes | Reviewed rubric | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Opus 5 + `cdm-dev` | 16/16 | 8/8 | 100/100 | 50 turns, 49 tool calls | 10m 53s |
| Opus 5 control | 15/15 | 8/8 | 98/100 | 43 turns, 42 tool calls | 9m 31s |
| Codex + `cdm-dev` | 6/6 | 8/8 | 100/100 | 28 completed items, 15 commands | 11m 7s |
| Codex control | 3/3 | 8/8 | 99/100 | 23 completed items, 15 commands | 8m 50s |

The frozen evaluator was a correctness tie: all four implementations preserved the typed CDM leaf,
held the contractual tenor, froze after notice, entered the LCR horizon on the specified calendar
date, and settled the old-rate bucket once before fresh new-rate accrual. An independent
`claude-fable-5` source review and post-hoc probes found a small treatment advantage beyond those
eight tests. Opus control accepted an incomplete principal and emitted settlement `Money` with no
currency; the skill arm rejected it. Codex treatment added final-day, rejection, and immutability
tests absent from its control. Fable therefore scored the controls 98 and 99, and both treatments 100.

That modest quality lift cost time: the treatment arms were 14% slower for Opus and 26% slower for
Codex. Codex repeated generated-source inspection after `cdm-source` had answered the same API
questions. Opus used a comparatively rich payout/party/identifier fixture; it supported a required
rate-non-interference assertion, but needed several extra builder inspections and corrections. The
skill now treats exact paths as confirmation tasks, keeps generated source and `javap` as alternative
views, and proves a leaf rebuild with focused neighboring-field or whole-object comparison. These
refinements post-date the table. Controls had no skill directory, and both the original and Fable
trace audits found no skill, evaluator, rubric, repository, or sibling access before evaluator reveal.

A sixth [four-arm benchmark](evals/benchmarks/securities-lending-month-end-billing/) implemented a
month-end billing engine over typed CDM 7.0.0 securities loans. It combined strict T-1 marks,
open-inclusive/return-exclusive accrual, settlement-effective partial returns, signed negative
rebates, per-loan day-count bases, exact decimal rounding, and currency-isolated counterparty
netting. The task supplied the exact CDM boundary and kept resolved rates and event history
application-owned.

| Arm | Agent-authored tests | Evaluator probes | Reviewed rubric | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Opus 5 + `cdm-dev` | 28/28 | 14/14 | 100/100 | 29 turns, 28 tool calls | 9m 51s |
| Opus 5 control | 12/12 | 14/14 | 99/100 | 34 turns, 33 tool calls | 10m 1s |
| Codex + `cdm-dev` | 6/6 | 14/14 | 99/100 | 30 completed items, 23 commands | 10m 8s |
| Codex control | 7/7 | 14/14 | 99/100 | 53 completed items, 39 commands | 13m 58s |

The frozen evaluator was a four-way behavioral tie, so a fresh `claude-fable-5` review rebuilt it
from the sealed sources and probed gaps. Opus treatment was genuinely better at essentially equal
speed: it alone rejected a malformed choice with both `AssetPayout` and `InterestRatePayout`
populated, fully satisfying the hidden topology criterion, and its 28-test suite was the strongest.
Codex treatment was 27% faster with 40% fewer commands than its control and added three useful
fail-closed guards, although its authored suite was one test smaller. Fable found no fatal arithmetic,
timing, sign, netting, mutation, or isolation issue in any arm.

This run validates the resolved-input fast path: neither treatment opened a broad domain reference,
both compiled on their first production attempt, and correctness did not cost extra wall time.
It also exposed a narrower tooling gap. All four agents—and both treatments despite correct
routing—spent repeated commands reconstructing generated Java signatures and locating Rune runtime
support classes. The skill now ships a batched `cdm-java-api` helper, points `cdm-source` at the
binary rather than generated-source JAR, and explains when the project-resolved `rune-runtime`
classpath is needed. Those changes post-date the table and are not credited to it.

A seventh [four-arm benchmark](evals/benchmarks/uti-report-sequence-validator/) implemented an
application-owned regulatory-report sequence validator over a real CDM `TradeIdentifier`. Its
central trap was preserving separate `TERMINATED` and `CANCELLED` states so `CORRECT` remains legal
after termination but not after an error, while rejected reports leave the state and anchored UTI
unchanged and processing continues.

| Arm | Agent-authored tests | Evaluator probes | Reviewed rubric | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Opus 5 + `cdm-dev` | 16/16 | 14/14 | 100/100 | 25 turns, 24 tool calls | 4m 7s |
| Opus 5 control | 26/26 | 14/14 | 100/100 | 20 turns, 19 tool calls | 4m 32s |
| Codex + `cdm-dev` | 13/13 | 14/14 | 100/100 | 18 completed items, 10 commands | 6m 20s |
| Codex control | 10/10 | 14/14 | 100/100 | 18 completed items, 11 commands | 4m 44s |

All four implementations were correct. A fresh `claude-fable-5` rebuild and six post-hoc probes
therefore treated artifact quality separately from the saturated rubric. It rated Codex treatment
slightly better than control: exhaustive transition switches and stronger direct-constructor and
malformed-value tests, at 34% more wall time. It rated Opus treatment roughly equal to control:
the treatment was 9% faster, documented the application/CDM/DRR boundary most precisely, and was
the only arm to mutation-test its policy, but its public `ValidationResult` record copied the
decision list only on the main factory path and could alias a list supplied directly.

The useful lesson is about keeping the skill proportional. Both treatment arms correctly avoided
inventing a CDM action enum or running a DRR engine, but Opus still loaded the full regulatory guide
even though the task supplied the policy and explicitly disclaimed DRR execution. The fast path now
covers supplied application state machines, says that reporting or lifecycle vocabulary alone does
not require a DRR/workflow guide, and places collection ownership at the public constructor boundary.
Those changes post-date the table and are not credited to it.

The revised skill was then paired with the sealed control in an adaptive `claude-sonnet-5`
regression, using Claude Code 2.1.227 and the local Max subscription. This is a test of the fix on a
less-capable model, not another independent estimate: the treatment wording was informed by the
four-arm result.

| Sonnet 5 arm | Agent-authored tests | Evaluator probes | Turns / tool calls | Shell commands | Wall time |
|---|---:|---:|---:|---:|---:|
| Revised `cdm-dev` | 15/15 | 14/14 | 16 / 15 | 9 | 2m 30s |
| Control | 17/17 | 14/14 | 30 / 29 | 19 | 3m 11s |

The skill arm was 21% faster, used 48% fewer tool calls, and made its first production write after
10 calls rather than 23. It loaded no broad reference and used the batched API helper; the control
unpacked generated sources and repeatedly searched Gradle caches and JARs. Correctness was not only
a frozen-suite tie: a post-hoc probe for the contract's literal “exactly one non-null assigned
identifier” rule passed with the skill and failed in control. Both implementations still aliased a
mutable list passed directly to the public result-record constructor. Making that guard more explicit
in prose did not fix it, so the durable lesson is to add an executable constructor-boundary probe to
future evaluators rather than keep making the skill more benchmark-specific.

An eighth [four-arm benchmark](evals/benchmarks/bdt-tranche-expander/) used a focused
[ICMA BDT 2.0](https://www.icmagroup.org/News/news-in-brief/icma-publishes-version-2-0-of-the-bond-data-taxonomy-reflecting-growing-market-adoption/)-style
programme/tranche message and expanded it into one real CDM 7.0.0 `Security` per unique ISIN. The
task tested independent programme-field inheritance, an exact row-total completeness check,
fungible later taps, and hard failure on conflicting tap terms. It deliberately modelled the full
issuance fields in an application-owned resolved sidecar because CDM `Security` owns identity,
classification, and issuer topology but not that entire issuance-term set.

| Arm | Agent-authored tests | Evaluator probes | Reviewed rubric | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Sonnet 5 + `cdm-dev` | 13/13 | 14/14 | 100/100 | 50 turns, 49 tool calls | 6m 57s |
| Sonnet 5 control | 10/10 | 14/14 | 100/100 | 44 turns, 43 tool calls | 6m 10s |
| GPT-5.4 + `cdm-dev` | 8/8 | 14/14 | 100/100 in sealed workspace | 69 completed items, 32 commands | 8m 20s |
| GPT-5.4 control | 8/8 | 14/14 | 100/100 | 51 completed items, 34 commands | 6m 3s |

This benchmark is a correctness tie, not a skill win. Every arm isolated GBP/EUR/GBP inheritance,
summed all rows including taps, rejected non-later or conflicting duplicates, built the intended
ISIN/LEI/issuer-role graph, and copied public result lists. Sonnet treatment wrote three more tests
but was 13% slower. GPT-5.4 treatment used the bundled helpers to reach its first production write
after 18 commands rather than the control's 29 and produced less code, but still finished 38%
slower.

The engineering review made the GPT treatment worse overall. It replaced the fixture's working
`org.finos.cdm:cdm-java:7.0.0` dependency with paths to ignored `.tmp` copies of Rune runtime and
Guava JARs. Its live workspace passed because those transient files remained; a clean clone failed
to compile. Both Sonnet clones and GPT control passed from clean clones. The frozen behavioral
rubric remains 100/100 for transparency, while the comparative review marks that treatment
“request changes.”

That failure produced one generic skill improvement rather than a BDT-specific recipe: using a
local binary with `cdm-source` or `cdm-java-api` is inspection only and must not displace a working
project dependency or introduce ignored/cache paths into durable build files. The change post-dates
the table and is not credited to treatment. The broader result is deliberately negative evidence:
when a task already pins the complete CDM boundary and acceptance rules, `cdm-dev` may add little;
its value has to come from avoiding model-semantic mistakes, not from ritual source inspection.

A ninth [open-discovery rerun](evals/benchmarks/bdt-tranche-expander-discovery/) removed that
prescribed topology. It gave agents essentially the BDT programme/tranche use case, four business
examples, the pinned CDM 7.0.0 artefacts, and a request to choose and justify their own Java and CDM
boundary. The task did not select `Security`, `TransferableProduct`, a sidecar, builders, validation
classes, or identifier algorithms. A frozen rubric then scored the modelling choices as well as the
visible examples.

| Discovery arm | Agent-authored tests | Same-day tap probe | Fable review | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Sonnet 5 + `cdm-dev` | 26/26 | fail | 92/100 | 77 turns, 76 tool calls | 18m 08s |
| Sonnet 5 control | 9/9 | fail | 84/100 | 67 turns, 66 tool calls | 10m 35s |
| GPT-5.4 + `cdm-dev` | 6/6 | fail | 89/100 | 75 completed items, 50 commands | 9m 32s |
| GPT-5.4 control | 5/5 | fail | 70/100 | 74 completed items, 49 commands | 7m 28s |

This rerun exposes the skill's intended value. The
[FINOS product model](https://cdm.finos.org/docs/product-model/) distinguishes a minimally
identifying asset from a `TransferableProduct` carrying economic terms when the instrument
generates future transfers. GPT-5.4 treatment found that boundary and placed the supplied coupon,
maturity, issue date, currency, and size into a generated `Asset -> Instrument -> Security` plus
`EconomicTerms` and `InterestRatePayout`; generated rule probes passed. Its governing-law and
issuance-provenance facts stayed application-owned. The control instead invented `SENIOR` and
`BULLET` facts, implemented the LEI checksum incorrectly, and then generated a test fixture with
the same wrong algorithm. Treatment was nineteen review points better with essentially the same
command count, although 28% slower by wall time.

Sonnet already found a defensible conservative `Security` plus application-envelope design without
the skill. Treatment improved its typed graph, failures, tests, and design evidence by eight review
points, but was 71% slower. Its source/API pass was the clearest remaining efficiency problem:
correctness improved, but too much of the extra time was evidence gathering before the first
vertical slice.

All four arms missed one genuine business guard: they treated a same-day duplicate as a tap solely
because it appeared later in the message. That rule remains in the benchmark evaluator rather than
being taught as a BDT-specific recipe. The durable
[independent review](evals/benchmarks/bdt-tranche-expander-discovery/) instead identifies
generic improvements: test identifier code against an independently sourced valid vector, trace
every populated CDM leaf to source or a documented assumption, explain abstract product-role
elections, name the exact validation tier, and make the evidence-pass budget operational. This is
positive evidence for using `cdm-dev` when the hard part is discovering a faithful CDM boundary; it
is not evidence that every CDM-labelled coding task benefits from the extra navigation cost. The
boundary/role route, independent-vector guard, bounded source/API pass, and no-cache-scavenging
diagnostic were added after the run and are not credited in the table.

A tenth [open-design benchmark](evals/benchmarks/manufactured-payment-reversal/) implemented a
securities-lending manufactured-payment engine with issuer correction/reversal support. The task
supplied the record-date entitlement formula, signed flow and exactly-once behavior, but left the
Java state API, CDM boundary, transfer subtype, builders, inherited conditions, validation tier, and
persistence seam to each agent. This reflects the ordinary manufactured-payment context described
by [HMRC CFM74430](https://www.gov.uk/hmrc-internal-manuals/corporate-finance-manual/cfm74430).
The ECB SCoRE material treats negative cash flows as Standard 5 and corporate-action reversals as
Standard 13; those sources motivate the cases, while the benchmark's supplied rules remain the
implementation contract.

| Manufactured-payment arm | Agent-authored tests | Evaluator probes | Fable review | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Sonnet 5 + `cdm-dev` | 19/19 | 3/3 | 98/100 | 76 turns, 75 tool calls | 12m 38s |
| Sonnet 5 control | 18/18 | 2/3 | 89/100 | 99 turns, 98 tool calls | 13m 45s |
| GPT-5.4 + `cdm-dev` | 7/7 | 2/4 | 91/100 | 66 completed items, 39 commands | 9m 35s |
| GPT-5.4 control | 9/9 | 2/3 | 92/100 | 97 completed items, 69 commands | 9m 19s |

All four authored suites passed, as did every visible arithmetic, record-date, correction-chain,
replay, and signed-direction example. The adaptive checks still separated them. Sonnet treatment
emitted the coherent CDM 7.0.0 shape: corporate-action `ContingentTransfer`, `Cash` asset,
currency-unit positive quantity, settlement date, and identified payer/receiver parties. Control
instead emitted the affected security, omitted the settlement date, and inferred requiredness from
generated Java annotations. The skill gained nine review points and was 8% faster, so this is a
clear correctness-and-efficiency win rather than simply extra deliberation.

GPT-5.4 was a useful counterexample. Treatment used half as many pre-edit commands and correctly
rejected a reused correction ID carrying different economics, which control silently treated as an
idempotent replay. But the pre-run skill lacked a corporate-action movement route, and treatment
stopped at the plausible-sounding `ScheduledTransfer.DividendReturn`; it also omitted the Cash
quantity unit and party identifiers. Control explored generated rules more deeply and scored one
point higher. Skill-guided navigation reduced work but did not yet guarantee the right model choice.

The [independent review](evals/benchmarks/manufactured-payment-reversal/) therefore led to
three generic post-run changes, none credited in the table. `cdm-source type` now returns a full
declaration, inherited conditions, and sibling subtypes in one bounded query; the main workflow now
requires structural and applicable inherited data-rule checks for newly emitted CDM types and
forbids treating Java annotations as Rune cardinality; and the securities-financing guide now
deep-links manufactured income and corporate-action cash movements without teaching the benchmark's
reversal algorithm. This is the skill's intended value: faster access to version-correct model
semantics and verification traps that ordinary plausible Java does not reveal.

An eleventh [intraday-repo benchmark](evals/benchmarks/intraday-repo-interest/) tested exact elapsed
time across midnight and time zones, zero and reversed durations, day-count bases, and 24-hour
continuity. It left the Java API, CDM `Money` boundary, validation depth, arithmetic form, and
rounding policy open.

| Intraday arm | Agent-authored tests | Fixed probes | Fable review | Wall time |
|---|---:|---:|---:|---:|
| Sonnet 5 + `cdm-dev` | 15/15 | 5/6 | 96/100 | 13m 00s |
| Sonnet 5 control | 14/14 | 4/6 | 93/100 | 11m 00s |
| GPT-5.4 + `cdm-dev` | 8/8 | 4/6 | 91/100 | 8m 16s |
| GPT-5.4 control | 11/11 | 6/6 | 96/100 | 6m 22s |

Every arm got the elapsed-time economics right. The skill improved Sonnet's generated validation
by three points, but its root validator still missed a populated `UnitType` choice. GPT control's
exact-rational arithmetic and application checks beat treatment by five points. The result is mixed:
the skill helps when generated-model validation is the weak link, but it cannot replace ordinary
numeric and boundary judgment. The post-run revision made populated-child validation, validation
before zero-result shortcuts, and dependency-injection smoke checks explicit.

A twelfth [repo-fail and mini-close-out benchmark](evals/benchmarks/repo-fail-mini-closeout/)
tested selected-trade netting, same-counterparty scope isolation, negative-rate fail periods, and
offer-side replacement valuation. The contract deliberately left the CDM graph, application state,
validation traversal, and day-by-day fail-window representation for each agent to discover.

| Repo-fail arm | Agent-authored tests | Public probes | Fable review | Agent work | Wall time |
|---|---:|---:|---:|---:|---:|
| Sonnet 5 + `cdm-dev` | 21/21 | pass | **99/100** | 191 turns, 190 tool calls | 30m 50s |
| Sonnet 5 control | 20/20 | pass | **94/100** | 182 turns, 181 tool calls | 23m 47s |
| GPT-5.4 + `cdm-dev` | 6/6 | pass | **87/100** | 63 completed items, 35 commands | 10m 33s |
| GPT-5.4 control | 14/14 | pass | **93/100** | 92 completed items, 47 commands | 11m 05s |

This is a clear Sonnet correctness win, not merely more tests. Treatment was the only arm whose
complete terminated `TradeState`, every populated child, and emitted CDM `Money` all passed the
generated CDM 7.0.0 validator sweep. Control omitted required `ClosedState.activityDate`; its
root-only validation never inspected the object it changed. The skill cost 30% more wall time, and
Sonnet ignored its own bounded-query instruction, so some—not all—of that cost bought the better
graph.

GPT-5.4 treatment shows the limit. It used 42% fewer input tokens and 12 fewer commands than control,
but modeled the fail window as a current-call boolean. Skipping a failed day and landing on a
resolution day retroactively accrued the skipped day at the negative contractual rate, rewarding
the failing seller. Its CDM boundary was also an invalid identity shell. The skill improved
efficiency but not implementation quality for that model.

The durable [independent review](evals/benchmarks/repo-fail-mini-closeout/REVIEW.md) therefore led
to generic, executable improvements rather than repo-example prose: simple Java names resolve to
exact generated packages; source declarations batch in one command; five helper batches force a
boundary re-check; complete boundaries must validate every populated child and may not use hollow
shells; date-scoped policy must remain reconstructible from recorded dates; and every emitted net
amount must prove currency scale and direction. This is the reason to use `cdm-dev`: it can turn
plausible Java into version-correct CDM and expose model-specific defects a normal suite misses—but
the benchmark record also makes clear when that benefit does not materialise.

## Install

The distributable skill is the `skills/cdm-dev/` directory; everything outside it is
repository tooling. Place or symlink that directory where your agent discovers skills:

```bash
mkdir -p .claude/skills
ln -s /absolute/path/to/this/repository/skills/cdm-dev .claude/skills/cdm-dev
```

Use the equivalent location for other compatible agents (for Codex CLI, `.agents/skills/`).
Skill installers that understand the conventional `skills/<name>/` container — such as
`npx skills add <this repository's GitHub URL>` or the Codex `$skill-installer` given the
GitHub tree URL of `skills/cdm-dev` — discover the skill directly.

## Route to one bundled guide

Search the distributable guidance without loading all of its references:

```bash
skills/cdm-dev/scripts/cdm-docs only exists direction identity
```

`cdm-docs` searches only the active skill's `SKILL.md` and immediate `references/*.md`. It returns
at most five TSV rows and names one reference to read completely. Its root cannot be overridden, so
repository README, evals, reviews, and hidden benchmark material cannot enter the results. Treat the
output as guidance routing; prove version-specific model facts with the artifact helpers below.

## Inspect the active CDM model and Java API

When the declaration name is unknown, start with a small plain-word lookup:

```bash
skills/cdm-dev/scripts/cdm-find --jar path/to/cdm-java.jar repurchase date
```

`cdm-find` reads the embedded Rune source in memory and returns at most six ranked TSV rows: an
exact kind-qualified selector, its source location, and one matching line. It does not use regular
expressions, unpack the JAR, or print declaration bodies. Execute the helper rather than reading its
source; then run `cdm-source members` or `path` on one candidate. This keeps discovery output small
and prevents broad JAR listings from becoming model context.

For a normal Java task, inspect the complete bounded slice in one command:

```bash
skills/cdm-dev/scripts/cdm-inspect --jar path/to/cdm-java.jar \
  TradeState TransferState Money
```

`cdm-inspect` reports the exact CDM version, owning Rune declarations and functions, inheritance,
conditioned children, generated Java getters/builders, and relevant metadata and validator class
names. It accepts at most eight declarations and refuses output above 1,200 lines rather than
silently truncating it. The helper reads the embedded Rune files in one in-memory batch; it does not
unpack the JAR onto disk, download dependencies, or scan global caches.

Use the lower-level source helper for a source-only question. Its `type` path reads `.rosetta`
files directly from the binary `cdm-java` JAR. Do not pass the generated-Java `-sources.jar`; the
binary already embeds the Rune source:

```bash
skills/cdm-dev/scripts/cdm-source --jar path/to/cdm-java.jar version
skills/cdm-dev/scripts/cdm-source --jar path/to/cdm-java.jar type TradeState ClosedState
skills/cdm-dev/scripts/cdm-source --jar path/to/cdm-java.jar list 'event.*func'
```

The `type` command accepts a bounded batch of types, choices, enums, functions, and qualifications
and reads the archive once. It prints each complete declaration with inherited base declarations,
conditions, alternatives, and sibling subtypes, avoiding repeated line-window searches and broad
FpML ingestion matches. Use raw `search` only when the plain-word finder cannot locate a declaration.

`CDM_JAVA_JAR` can supply the path instead. Without either, the helper searches common
Gradle/Maven distribution and dependency-copy layouts under the active project. It refuses
an ambiguous match rather than choosing a version silently.

For exact generated Java getters and builders, inspect several types in one pass:

```bash
skills/cdm-dev/scripts/cdm-java-api --jar path/to/cdm-java.jar \
  TradeState Trade InterestRatePayout
```

For an unambiguous simple name, the helper prints the exact generated Java package; ambiguity lists
candidates instead of inviting a guessed import. It also includes each type's generated builder. If a
`com.rosetta.model.lib.*` support type is needed, add the project's already-resolved
`rune-runtime` JAR with `--classpath`; the helper never guesses or downloads a version.

## Validate

Run the structural gate:

```bash
scripts/check-skill --static
evals/check-patterns
```

Run the live contract against any contemporary `cdm-java` dependency:

```bash
scripts/check-skill --jar path/to/cdm-java.jar
```

The static gates check frontmatter, reference reachability, portability, script syntax, the size of
the always-loaded skill, implementation-card structure and provenance, and sealed forward-test
hashes. They do not claim model lift. The live skill gate also proves the source helper can read a
substantial Rosetta corpus and locate declarations the workflow relies on.

Run the script test suite (hermetic; builds its own fixture JARs):

```bash
tests/run
```

Check every external link in the Markdown resources:

```bash
scripts/check-links
```

The checker follows redirects and fails on definitive broken responses such as `404` or
`410`. It reports `401` and `403` as access warnings because some official association pages
are member-only or reject CI user agents. The GitHub workflow runs this live check on every
push to main, every pull request, and in the weekly drift sweep.

Run trigger and reviewed answer-quality evals locally through existing Claude Code and Codex
subscription logins:

```bash
evals/run-local --vendor all --check-auth
evals/run-local --vendor all --quality-only --case price-quantity-model-api
```

The local runner deliberately ignores API-key environment variables. Live model evals do not run
in GitHub Actions and require no repository secrets. See [Local skill evaluations](evals/README.md)
for authentication, focused commands, fixture caching, result review, and baseline promotion.
The twelve code-writing use cases are also preserved as leakage-aware
[implementation forward benchmarks](evals/benchmarks/README.md), with fixed tasks, hidden rubrics,
observed skill/control baselines, a shared CDM 7.0.0 seed, and `evals/check-benchmarks` validation.

Requirements: Bash, Python 3.10+, `rg`, `zipinfo`, and `unzip`; a JDK for generated Java API checks;
network access for the live link and release checks; local Claude Code and Codex CLIs for live
model evals.

## Supported CDM versions

The core workflow reads model truth from the JAR the project supplies. Domain references include
clearly dated CDM 7.0.0 observations where a concrete trap is useful, but require agents to rerun
the supplied source queries against the consuming project's version. CI proves the live helper
contract on the latest release of every supported major — currently 4.3.0, 5.40.0, 6.24.0, and
7.0.0 — and a weekly canary runs it against the newest published build (including dev builds) as
early warning before the next release enters the matrix.

## Layout

```text
skills/cdm-dev/          the distributable skill — everything an install ships
  SKILL.md               lean workflow and reference router
  references/            onboarding, product-family, legal, DRR, industry, Rune, workflow, and test guidance
  scripts/cdm-docs       route plain words to one bundled guidance reference
  scripts/cdm-find       rank a few declarations from plain search words
  scripts/cdm-inspect    inspect a bounded Rune/Java/validator slice in one command
  scripts/cdm-source     query source embedded in an active cdm-java dependency
  scripts/cdm-java-api   batch generated Java getters and builders with javap
scripts/check-skill      static and live drift gates (repository tooling)
scripts/check-links      verify external documentation links and redirects
tests/                   hermetic per-tool suites (driver: tests/run; shared lib.sh, fixtures.sh)
evals/                   local runners, pattern/implementation benchmarks, graders, and baselines
.github/                 hermetic lint/tests, CDM release matrix, links, and upstream canary
```
