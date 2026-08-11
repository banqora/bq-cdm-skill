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
- [BDT-style tranche-to-CDM expander](bdt-tranche-expander/)

## Contents

- `index.json`: benchmark and pinned-fixture manifest.
- `fixtures/java-21-cdm-7.0.0/`: shared minimal Gradle seed.
- `<benchmark>/TASK.md`: the only benchmark-specific file shown to the implementation agent.
- `<benchmark>/rubric.json`: fixed public and hidden evaluator criteria.
- `<benchmark>/evaluator/`: evaluator-owned tests copied in only after an arm is sealed, when saved.
- `<benchmark>/baseline.json`: observed model/skill runs, effort, reviews, and any labelled post-revision regression.

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
9. Record exact CLI/model versions, auth mode, wall time, exposed turn/item counts, tool calls,
   authored-test results, hidden-check outcomes, and any harness limitations.

The historical baseline is evidence from one run, not a threshold to optimise blindly. Promote a
new baseline only after reviewing raw code and test output and noting which skill revision was under
test. Never edit a task or rubric in place merely to make a model pass; version the benchmark when
its contract changes materially.

Validate the manifest, tasks, rubrics, and baselines with:

```bash
evals/check-benchmarks
```
