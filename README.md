# cdm-dev

A portable agent skill for day-to-day engineering with the FINOS Common Domain Model,
Rune source, released language distributions, generated APIs, and the Rune runtime.

The skill is deliberately application-neutral. It discovers the active project's structure,
uses that project's tests and build commands, and reads model truth from version-matched Rune
source. The included helper can use the corresponding `cdm-java` JAR as a source container;
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

## Inspect the active CDM model

The helper reads `.rosetta` files directly from a released `cdm-java` JAR, including when that
JAR is used only as the source container for a non-Java integration:

```bash
skills/cdm-dev/scripts/cdm-source --jar path/to/cdm-java.jar version
skills/cdm-dev/scripts/cdm-source --jar path/to/cdm-java.jar search '^type TradeState:'
skills/cdm-dev/scripts/cdm-source --jar path/to/cdm-java.jar list 'event.*func'
```

`CDM_JAVA_JAR` can supply the path instead. Without either, the helper searches common
Gradle/Maven distribution and dependency-copy layouts under the active project. It refuses
an ambiguous match rather than choosing a version silently.

## Validate

Run the structural gate:

```bash
scripts/check-skill --static
```

Run the live contract against any contemporary `cdm-java` dependency:

```bash
scripts/check-skill --jar path/to/cdm-java.jar
```

The static gate checks frontmatter, reference reachability, portability, script syntax, and
the size of the always-loaded skill. The live gate also proves the source helper can read a
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
The three code-writing use cases are also preserved as leakage-aware
[implementation forward benchmarks](evals/benchmarks/README.md), with fixed tasks, hidden rubrics,
observed skill/control baselines, a shared CDM 7.0.0 seed, and `evals/check-benchmarks` validation.

Requirements: Bash, Python 3, `rg`, `zipinfo`, and `unzip`; network access for the live link
and release checks; local Claude Code and Codex CLIs for live model evals.

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
  scripts/cdm-source     query source embedded in an active cdm-java dependency
scripts/check-skill      static and live drift gates (repository tooling)
scripts/check-links      verify external documentation links and redirects
tests/                   hermetic per-tool suites (driver: tests/run; shared lib.sh, fixtures.sh)
evals/                   local runners, implementation benchmarks, graders, and baselines
.github/                 hermetic lint/tests, CDM release matrix, links, and upstream canary
```
