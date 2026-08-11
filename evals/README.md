# Local skill evaluations

Run live trigger and answer-quality evaluations from a trusted local checkout using the
Claude Code and Codex subscriptions already signed in on that machine. GitHub Actions runs
only deterministic tests; this repository does not store model API keys or subscription tokens.

## Contents

- [Authenticate with subscriptions](#authenticate-with-subscriptions)
- [Run a two-vendor smoke test](#run-a-two-vendor-smoke-test)
- [Run the complete suite](#run-the-complete-suite)
- [Run one evaluation layer](#run-one-evaluation-layer)
- [Run implementation forward benchmarks](#run-implementation-forward-benchmarks)
- [Validate implementation patterns](#validate-implementation-patterns)
- [Interpret and promote results](#interpret-and-promote-results)
- [Why live evals stay local](#why-live-evals-stay-local)

## Authenticate with subscriptions

Install both CLIs, then use their browser login flows:

```bash
claude auth login
claude auth status --text

codex login
codex login status
```

For Claude, do not add `--console`: that selects Claude Console/API billing rather than the
Claude subscription login. For Codex, `codex login status` should say `Logged in using ChatGPT`.
The local runner verifies both modes before starting and removes `ANTHROPIC_API_KEY`,
`ANTHROPIC_AUTH_TOKEN`, `CLAUDE_CODE_OAUTH_TOKEN`, `ANTHROPIC_BASE_URL`, `OPENAI_API_KEY`,
`CODEX_API_KEY`, `CODEX_ACCESS_TOKEN`, and `OPENAI_BASE_URL` from the model subprocesses,
along with Claude's hosted-provider selectors, so inherited credentials cannot silently replace
subscription use.

Official references:

- [Claude Code authentication](https://code.claude.com/docs/en/authentication) and
  [programmatic/headless usage](https://code.claude.com/docs/en/headless)
- [Codex authentication](https://developers.openai.com/codex/auth) and
  [non-interactive mode](https://developers.openai.com/codex/noninteractive)

Check authentication without consuming a model turn:

```bash
evals/run-local --vendor all --check-auth
```

## Run a two-vendor smoke test

Run the reviewed quality case once through each local subscription:

```bash
evals/run-local --vendor all --quality-only --case price-quantity-model-api
```

This makes one model call per CLI. It is the quickest end-to-end check of skill discovery,
artifact inspection, answer capture, and deterministic grading.

## Run the complete suite

Run one trigger attempt per prompt plus the reviewed quality cases:

```bash
evals/run-local --vendor all --runs 1
```

With the current 29-prompt corpus and one quality case, that command starts 60 live sessions:
29 trigger sessions plus one quality session for each vendor. Use `--vendor claude` or
`--vendor codex` for one CLI. Increase to `--runs 3` only when promoting a baseline; live runs
consume the normal usage allowance of each local subscription and can hit its plan limits.

The quality suite needs pinned `cdm-java` 7.0.0 binary and source fixtures. Without `--jar`,
`run-local` downloads them once into
`${CDM_DEV_EVAL_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/cdm-dev-evals}` and verifies both SHA-256
digests. Supply existing copies instead:

```bash
evals/run-local --vendor codex \
  --jar /path/to/cdm-java-7.0.0.jar \
  --sources-jar /path/to/cdm-java-7.0.0-sources.jar
```

Generated `evals/results-*.json` files are ignored by Git.

## Run one evaluation layer

Trigger routing only:

```bash
evals/run-local --vendor claude --runs 3 --triggers-only
```

Reviewed answer quality only:

```bash
evals/run-local --vendor codex --quality-only
```

Run a single quality case:

```bash
evals/run-local --vendor codex --quality-only --case price-quantity-model-api
```

The lower-level runners remain available for debugging:

```bash
evals/run-triggers --vendor claude --runs 1
evals/run-quality --vendor codex \
  --jar /path/to/cdm-java-7.0.0.jar \
  --sources-jar /path/to/cdm-java-7.0.0-sources.jar
```

`run-triggers` measures whether the skill activates. `run-quality` explicitly invokes the skill,
captures the final answer, and applies deterministic reviewed checks from `quality.json`. Always
read the captured answer in the results file; a checklist is a regression signal, not a substitute
for human review.

## Run implementation forward benchmarks

Twelve implementation cases—the tokenisation classifier, locate matcher, repo settlement shaper,
CSA margin calculator, evergreen repo lifecycle engine, securities-lending month-end billing,
UTI report-sequence validator, two tranche-expander contracts, manufactured-payment reversal,
intraday repo interest, and repo fail/mini close-out—
are preserved under
[`evals/benchmarks`](benchmarks/README.md). Each package contains a model-facing `TASK.md`, a fixed
public/hidden rubric, and its observed baseline. All twelve use the shared minimal Java 21/CDM 7.0.0
Gradle seed and the same checksummed binary/source fixtures as the quality suite.

Validate the saved benchmark contract without calling a model:

```bash
evals/check-benchmarks
```

These are reviewed forward tests rather than ordinary `run-local` cases because an implementation
agent writes an entire temporary project and implementations expose different application-owned
types. Follow the isolation protocol in the benchmark README: copy only the seed and selected task
into each fresh arm, keep the rubric and historical results outside the model workspace, expose the
skill only to the treatment arm, and add evaluator-owned tests only after every agent has exited.

## Validate implementation patterns

The reusable pattern cards and their leakage-safe promotion contract are checked with:

```bash
evals/check-patterns
```

This deterministic check proves card structure, reviewed authority-link shape, mutation sensitivity,
and sealed task/rubric/probe hashes. It does not prove model lift. Follow
[`patterns/PROTOCOL.md`](patterns/PROTOCOL.md) for fresh skill/control runs, near-miss cases,
correctness-first scoring, and the evidence required before promoting a card.

## Interpret and promote results

1. Run each vendor three times from a clean checkout.
2. Inspect every false trigger, missed trigger, and quality answer rather than averaging it away.
3. Update prompts or skill instructions, then rerun the complete suite.
4. Promote thresholds in `baseline.json` only after recording a reviewed, repeatable local run.
5. Record the CLI versions and date in the baseline note when behavior is accepted.

Codex trigger detection is a proxy because its JSONL stream does not expose a dedicated skill
activation event. Treat a clean rate as supporting evidence, not proof.

## Why live evals stay local

Both vendors can reuse local subscription authentication, but GitHub-hosted runs still need a
stored secret: Codex account auth requires protecting its saved credentials, while Claude Code
requires a person-bound `CLAUDE_CODE_OAUTH_TOKEN` generated by `claude setup-token`. This project
intentionally keeps those credentials off GitHub. See the official
[Codex automation guidance](https://developers.openai.com/codex/noninteractive) and
[Claude Code GitHub Actions guidance](https://code.claude.com/docs/en/github-actions).

GitHub Actions continues to run structural checks, hermetic runner/grader tests, the released CDM
matrix, link checks, and the upstream canary. Live model behavior is an explicit local review task.
