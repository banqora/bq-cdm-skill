# cdm-dev

A portable agent skill for day-to-day engineering with the ISDA Common Domain Model,
Rosetta source, generated `cdm-java` APIs, and the Rune runtime.

The skill is deliberately application-neutral. It discovers the active project's structure,
uses that project's tests and build commands, and reads model truth from the exact
`cdm-java` JAR supplied by the project. It does not require a particular repository,
framework, mapping layer, or service architecture.

## Install

Place or symlink this repository where your agent discovers a skill named `cdm-dev`. The
repository root is the skill root, so the discovered path should end with:

```text
cdm-dev/SKILL.md
```

For a project-local skill directory, for example:

```bash
mkdir -p .claude/skills
ln -s /absolute/path/to/this/repository .claude/skills/cdm-dev
```

Use the equivalent user-level or project-level skill directory for other compatible agents.

## Inspect the active CDM model

The helper reads `.rosetta` files directly from a released `cdm-java` JAR:

```bash
scripts/cdm-source --jar path/to/cdm-java.jar version
scripts/cdm-source --jar path/to/cdm-java.jar search '^type TradeState:'
scripts/cdm-source --jar path/to/cdm-java.jar list 'event.*func'
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

Run vendor trigger evals against a headless agent CLI (paid API usage):

```bash
evals/run-triggers --vendor claude --runs 3
evals/run-triggers --vendor codex --runs 3
```

Requirements: Bash, Python 3, `rg`, `zipinfo`, and `unzip`.

## Supported CDM versions

The skill embeds no version-specific model facts; it reads the model from the JAR the
project supplies. CI proves the live contract on the latest release of every supported
major — currently 4.3.0, 5.40.0, 6.24.0, and 7.0.0 — and a weekly canary runs the same
contract against the newest published build (including dev builds) as early warning
before the next release enters the matrix.

## Layout

```text
SKILL.md                 lean workflow and reference router
references/              Rosetta, workflow, dialect, testing, and conformance guidance
scripts/cdm-source       query source embedded in an active cdm-java dependency
scripts/check-skill      static and live drift gates
tests/run                hermetic test suite for both scripts
evals/                   vendor trigger evals and behavioral-drift baseline
```
