# Contributing

Issues and pull requests are welcome. Before a substantial change, open an issue so the intended
scope and compatibility contract can be agreed without wasted work.

Keep the distributable skill under `skills/cdm-dev/` portable and application-neutral. Do not add
private paths, credentials, proprietary implementation names, downloaded CDM artefacts, or other
third-party content that this repository is not entitled to redistribute. Claims about a specific
CDM release must be dated and checked against that release's Rune source or generated API.

Run the local gates before opening a pull request:

```bash
tests/run
scripts/check-skill --static
evals/check-patterns
evals/check-benchmarks
scripts/check-links
```

The test suite requires Bash, Python 3.10+, `rg`, `zipinfo`, `unzip`, and a working JDK. CI also
runs ShellCheck and `shfmt -d -i 2 -ci` over the shell entry points. Benchmark changes must preserve
the isolation and disclosure rules in `evals/benchmarks/README.md`; do not revise a task or hidden
rubric merely to improve a recorded result.

Unless explicitly stated otherwise, a contribution intentionally submitted for inclusion is
provided under the [Apache License 2.0](LICENSE), including the contribution terms in section 5.
Only submit work that you have the right to license on those terms.
