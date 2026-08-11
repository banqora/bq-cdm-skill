# Implementation-pattern evaluation protocol

The deterministic catalogue checks prove structure, provenance shape, and sealed evaluator
artifacts. They do not prove that a model chooses a pattern correctly or produces better code.
That evidence comes only from clean, reviewed forward runs.

## Evidence classes

Label tasks used to discover or edit a card as **regression evidence**. They can catch a backward
step, but success cannot establish that the revised catalogue generalises. Label an unseen,
pre-sealed task as **fresh evidence** only while neither arm has seen its evaluator, intended answer,
suspected failure, or a prior result. If the skill is edited in response to that task, all later
runs of the task become regression evidence.

## Seal the evaluation before any run

Freeze the model-facing task, private rubric, evaluator probes, selected CDM binary and source JAR,
and their SHA-256 values before launching an arm. Record the skill commit and catalogue SHA-256.
Keep the rubric, probes, repository history, prior outputs, sibling workspaces, and this protocol
outside the candidate workspace. Copy only the clean Java seed, the task, and verified dependency
artifacts into it.

## Run a leakage-safe A/B comparison

Use identical task and seed commits for a skill arm and a control arm. Expose `cdm-dev` only to the
skill arm. Start fresh sessions with subagents and session persistence disabled; never provide a
continuation hint. Randomise arm order, and use a unique build cache plus no shared daemon for every
workspace. Run arms sequentially unless operating-system and build-process isolation prevents all
cross-arm reads. Seal each result commit before attaching evaluator-owned probes.

Use at least two model families, including one model below the strongest available tier, and repeat
each pair three times for a promotion decision. Pin the exact model identifier and CLI version; a
marketing family name is not sufficient. Retain raw event streams where the local CLI exposes them.

## Include near-miss and non-application cases

Pair each application case with a near-miss where its tempting card must not be applied. Examples
include application-only arithmetic that needs no generated validator, a complete immutable event
history that needs no duplicate persisted window, and local identity that needs no global namespace.
Grade unnecessary CDM ceremony and forced recipes as errors, not harmless extra work.

## Record enough to reproduce a run

For every arm, save the task, rubric, probe, skill, catalogue, binary JAR, and source JAR digests;
exact vendor/model, CLI, Java, and Gradle versions; result commit; local auth mode; wall time, exposed
turns and tool calls; source-helper queries; direct JAR extractions; authored/evaluator test output;
rubric score; human review; and contamination audit. `evals/check-patterns` validates committed JSON
records in the manifest's results directory and requires complete skill/control pairs.

## Judge correctness before efficiency

Apply fatal failures first, then score behavior, CDM boundary validity, negative controls, and clean
reproducibility. Compare wall time, turns, tool calls, source queries, and JAR extractions only after
correctness. A faster arm with a correctness defect does not win; within an equal-correctness band,
prefer fewer blind searches, extractions, rebuilds, and unnecessary generated objects.

## Promotion gate

Promote a card only when all of the following are true:

1. Its rule is supported by primary/versioned material or by the same failure observed in at least
   two independent tasks; preserve the narrower claim when sources are contextual rather than
   normative.
2. Fresh A/B runs across two model families have no treatment fatal failure, no material regression
   on near-miss cases, and a reviewed correctness improvement or prevention of a repeated defect.
3. Existing discovery tasks still pass as regression checks, and negative mutation controls prove
   the new test can fail for the intended reason.
4. Efficiency is measured and explained. Large overhead without correctness benefit blocks
   promotion; overhead attached to a demonstrated correctness gain is recorded rather than hidden.
5. A human reviews raw code and traces for leakage, unsupported domain policy, validation theatre,
   and benchmark-specific wording before changing the catalogue status.

Do not promote on one lucky run, authored tests alone, aggregate speed, or a score whose evaluator
was visible to the candidate.

## Keep credentials off GitHub

Run live comparisons only from trusted local Claude Code and Codex installations using saved local
subscription authentication. Preflight the login mode and remove API-key, token, hosted-provider,
and base-URL environment overrides before launch. Never put subscription credentials or LLM secrets
in GitHub Actions. GitHub runs only deterministic catalogue, fixture, mutation, and repository tests;
sanitised scores and hashes may be committed after review.
