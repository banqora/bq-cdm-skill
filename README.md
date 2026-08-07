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

Run vendor trigger evals against a headless agent CLI (paid API usage):

```bash
evals/run-triggers --vendor claude --runs 3
evals/run-triggers --vendor codex --runs 3
```

Requirements: Bash, Python 3, `rg`, `zipinfo`, and `unzip`; network access for the live link
and release checks.

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
evals/                   vendor trigger evals and behavioral-drift baseline
.github/                 lint, static, test, CDM release matrix, canary, and eval jobs
```
