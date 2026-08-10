# Implementation forward benchmarks

These benchmarks preserve the two implementation tasks used to forward-test `cdm-dev` against
clean CDM 7.0.0 projects. They complement `evals/quality.json`, which grades read-only answers;
these cases require an agent to write and test Java code.

## Contents

- `index.json`: benchmark and pinned-fixture manifest.
- `fixtures/java-21-cdm-7.0.0/`: shared minimal Gradle seed.
- `<benchmark>/TASK.md`: the only benchmark-specific file shown to the implementation agent.
- `<benchmark>/rubric.json`: fixed public and hidden evaluator criteria.
- `<benchmark>/baseline.json`: observed pre-revision runs, including model/skill arms and effort.

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
7. After the agent exits, independently run its authored tests. Only then add evaluator-owned tests
   derived from `rubric.json`; never leave hidden tests where a later arm can discover them.
8. Record exact CLI/model versions, auth mode, wall time, exposed turn/item counts, tool calls,
   authored-test results, hidden-check outcomes, and any harness limitations.

The historical baseline is evidence from one run, not a threshold to optimise blindly. Promote a
new baseline only after reviewing raw code and test output and noting which skill revision was under
test. Never edit a task or rubric in place merely to make a model pass; version the benchmark when
its contract changes materially.

Validate the manifest, tasks, rubrics, and baselines with:

```bash
evals/check-benchmarks
```
