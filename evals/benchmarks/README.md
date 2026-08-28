# Implementation forward benchmarks

These benchmarks preserve the implementation tasks used to forward-test `cdm-dev` against
clean CDM 7.0.0 projects. They complement `evals/quality.json`, which grades read-only answers;
these cases require an agent to write and test Java code.

## Cases

- [Settlement-level tokenisation classifier](settlement-tokenisation-classifier/)
- [Locate matching engine](locate-matching-engine/)
- [Repo settlement shaping](repo-settlement-shaping/)
- [CSA margin-call calculator](csa-margin-call-calculator/)
- [Evergreen repo lifecycle engine](evergreen-repo-lifecycle/)
- [Securities-lending month-end billing](securities-lending-month-end-billing/)
- [UTI report-sequence validator](uti-report-sequence-validator/)
- [BDT-style tranche-to-CDM expander (prescribed contract)](bdt-tranche-expander/)
- [BDT tranche-to-CDM expander (open discovery)](bdt-tranche-expander-discovery/)
- [Manufactured-payment engine with reversal support](manufactured-payment-reversal/)
- [Intraday repo interest calculator](intraday-repo-interest/)
- [Repo fail and mini close-out engine](repo-fail-mini-closeout/)
- [Securities-loan event qualifier](securities-loan-event-qualifier/)
- [DRR ISO 20022 projection seam](drr-iso20022-projection/): the CDM-to-ISO-20022 serialisation
  seam with the four classic break-generators as tests. The recorded baseline is an
  author-orchestrated Sonnet 5 pair, author-scored and then independently re-scored by a fresh
  session given only the sealed materials; deviations from the four-arm protocol are disclosed
  in the baseline note, and GPT arms remain open. Its frozen task quotes the decimal-fraction
  example from the [CDM 7.0.0 Rune source](https://github.com/finos/common-domain-model/blob/7.0.0/rosetta-source/src/main/rosetta/base-math-type.rosetta#L42-L44); this citation is kept outside
  the sealed agent input so its digest remains unchanged.
- [FpML ingestion fidelity audit (designed; arms not yet run)](fpml-ingestion-fidelity-audit/):
  distills the reported CDM-contribution hazard — count-based FpML expectation assertions that a
  regenerated expectation file can bless — into an auditable mapping-fidelity seam over the
  ingest corpus shipped inside the pinned CDM 7.0.0 JAR. The task and rubric are frozen here for
  a future run; the case stays out of `index.json` until skill and control arms are recorded,
  because the manifest requires an observed baseline.

## Contents

- `index.json`: benchmark, sealed-task SHA-256, and pinned-fixture manifest.
- `fixtures/java-21-cdm-7.0.0/`: shared minimal Gradle seed.
- `<benchmark>/TASK.md`: the only benchmark-specific file shown to the implementation agent.
- `<benchmark>/rubric.json`: fixed public and hidden evaluator criteria.
- `<benchmark>/evaluator/`: evaluator-owned tests copied in only after an arm is sealed, when saved.
- `<benchmark>/baseline.json`: observed model/skill runs, effort, reviews, and any labelled post-revision regression.
- `<benchmark>/REVIEW.md`: a durable comparative review when modelling judgment cannot be reduced to one shared test API.

## Isolation protocol

1. Create a new temporary directory for every arm and copy the shared seed into it.
2. Copy only the selected `TASK.md` into that directory. Place the pinned binary and source JARs
   under `lib/`, verifying the SHA-256 values in `index.json`.
3. Initialise a fresh Git repository so each arm starts from the same snapshot.
4. For a treatment arm, expose only `skills/cdm-dev/`; for a control arm, expose no CDM skill.
5. Explicitly prohibit reading this benchmark directory, repository documentation, prior results,
   sibling workspaces, or another arm. Disable subagents and session persistence.
6. Run each arm once from its saved local Claude Code or Codex subscription login, with API-key
   environment variables removed. Do not send continuation hints or the rubric.
7. After the agent exits, independently run its authored tests and seal the deliverable output.
8. Repeat the authored tests from a clean clone or copy that excludes ignored temp/cache files, so
   a warmed workspace cannot hide missing dependencies. Only then add evaluator-owned tests derived
   from `rubric.json`; never leave hidden tests where a later arm can discover them.
9. Give every arm a private build cache (for Gradle, a unique `GRADLE_USER_HOME`) and use
   `--no-daemon` or stop daemons between arms. An OS sandbox does not isolate a shared build daemon.
10. Record exact CLI/model versions, auth mode, wall time, exposed turn/item counts, tool calls,
    authored-test results, hidden-check outcomes, and any harness limitations.

The historical baseline is evidence from one run, not a threshold to optimise blindly. Promote a
new baseline only after reviewing raw code and test output and noting which skill revision was under
test. Never edit a task or rubric in place merely to make a model pass; version the benchmark when
its contract changes materially.

Raw model workspaces and account traces are not distributed with this repository; a baseline says
so where only local ephemeral evidence was retained. Benchmark people, organisations, trades, and
events are synthetic test fixtures unless a public validation vector is explicitly named and
linked. A checksum-valid identifier that resolves to a real organisation is used only as test data
and does not imply that organisation's participation in or endorsement of this project.

Validate the manifest, tasks, rubrics, and baselines with:

```bash
evals/check-benchmarks
```
