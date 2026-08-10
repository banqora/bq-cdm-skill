---
name: cdm-dev
description: Develop, debug, test, upgrade, and review FINOS Common Domain Model (CDM) software, Rune source/DSL, generated distributions, and Rune runtimes. Use for CDM onboarding or generated-API upgrades; Java, Python, TypeScript, JSON Schema, or Excel integration; FpML/data mapping, typed objects, dropped fields, serialization, and JSON dialects; lifecycle events, validation, qualification, and functions; derivatives, securities financing, collateral, DRR/regulatory reporting, or legal-agreement representation; and separating CDM semantics from application policy or ISDA/ISLA/ICMA guidance. Exclude unrelated meanings of "CDM" or "Rune", generic build debugging, CLI lookups, and legal advice.
---

# Develop with CDM

Treat a CDM task as a change through a model-backed application, not as a sequence of
lookups. First establish which layer owns the behavior.

## Choose the authority

| Question | Source of truth |
|---|---|
| What does a type, enum, condition, or function mean? | The `.rosetta` source for the project's exact CDM version, from its matching source tag or distribution |
| What API and wire metadata were generated? | The selected language distribution's generated types, signatures, and serialization metadata |
| Does an object validate, qualify, or transition this way? | The selected runtime's generated validators/functions, compared with the Java reference when parity is required |
| How does external data become CDM, and what policy applies? | The consuming project's mapping, services, configuration, fixtures, and tests |
| What is accepted market practice or the business rationale? | The relevant dated ISDA, ISLA, or ICMA source, with its version and access limits recorded |

Do not replace one authority with another. A Rune declaration expresses model intent; a
generated runtime probe establishes executable behavior; application code explains only that
application's choices.

## Follow the application path

If CDM is not installed, its distribution is unclear, or a language must be selected, read
[Getting started with CDM](references/onboarding.md) before changing the project.

1. Read the project's instructions and build files. Identify its CDM artefact and version,
   language/runtime, document root, JSON dialect, and nearest relevant test. Do not assume
   Gradle, Maven, a directory layout, or a local helper class.
2. Trace the value end to end with `rg`: external input, normalization or mapping, generated
   builder, typed CDM object, serialization, validation/functions, and downstream storage or
   API behavior. Name any project-specific stages instead of treating them as CDM.
3. Query version-matched `.rosetta` source with `scripts/cdm-source` resolved from this `SKILL.md`;
   a matching `cdm-java` JAR can be only the source container. Batch questions, open owning
   declarations, and use [Rosetta and generated code](references/rosetta.md) only for remaining
   declaration, generated-API, or runtime ambiguity. An exact caller-supplied path is a confirmation
   task; do not survey neighboring types.
4. Build or compile the smallest typed vertical slice early: exercise at least one production
   getter or builder and the first real branch. Compiling empty directories, records, or signatures
   alone is not evidence. Let errors identify API details that still need inspection.
5. Add or tighten the smallest test that proves the requested behavior. Assert that meaningful
   content survived, the changed economic leaf is correct, and a close negative case does not
   pass accidentally.
6. Change the narrowest owning layer. Keep source-system conversions in the application,
   model semantics in generated CDM code, and explicit business guards labelled as application
   policy.
7. Run the repository's focused check, then its normal offline suite and formatter/linter.
   Inspect data-driven inputs and snapshot diffs; do not invent a universal build command.

Bound the evidence pass before coding: list the input path and choices, units or direction, output
contract, and owner. Stop when each claim has one version-matched source and the smallest compile or
test confirms it. Escalate from typed construction to a rule/function probe or full runtime only when
the requested behavior depends on it; never make a partial fixture fully qualify as ceremony.

For a typed application-owned calculation with resolved values, use one combined declaration/builder
query, one real vertical slice, then its test. A product name alone does not require its guide when
exact paths and rules are supplied. Inspect only members the function reads or rebuilds. To prove a
single-leaf rebuild, assert untouched neighboring fields or rewind the leaf and compare the whole
object with the input. Use [Day-to-day workflows](references/workflows.md) only for broader routes.

## Load only what the task needs

- Product families: [interest rates](references/interest-rates.md),
  [credit derivatives](references/credit-derivatives.md),
  [equities](references/equities.md), [foreign exchange](references/foreign-exchange.md), and
  [commodities](references/commodities.md).
- [Securities financing](references/securities-financing.md): repo, buy/sell-back, securities
  lending, collateral, qualification, and lifecycle traps.
- [Transferable assets and cash securities](references/assets-and-cash-securities.md): cash,
  bonds, loans, listed derivatives, money-market instruments, and digital-asset boundaries.
- [Legal agreements and contracts](references/legal-contracts.md): use when representing, mapping,
  or resolving agreements and elections—not merely when resolved legal values feed a calculation.
- [Digital regulatory reporting](references/regulatory-reporting.md): DRR acquisition and
  compatibility, translate/enrich/transform/project, policy seams, regimes, evidence, and tests.
- [Rosetta and generated code](references/rosetta.md): model declarations, generated APIs,
  metadata annotations, validators, functions, and qualifiers.
- [Day-to-day workflows](references/workflows.md): locating the owning layer and making
  ordinary mapping, document, lifecycle, validation, or upgrade changes.
- [JSON dialects](references/dialects.md): legacy/Rune detection, dropped fields, references,
  pruning, round trips, and migration.
- [Testing CDM code](references/testing.md): use for fixture, mapping, runtime, round-trip, build,
  or corpus uncertainty; a supplied focused function contract can stay on the fast path above.
- [ISDA corpus conformance](references/conformance.md): discovering shipped scenarios and
  comparing application execution with reference outputs.
- [Getting started with CDM](references/onboarding.md): distributions, language options,
  acquisition, capability gaps, version selection, and installation smoke tests.
- [Industry-body guidance](references/industry-bodies.md): dated ISDA, ISLA, ICMA, and FpML
  market-practice sources, with freshness, access, and licensing boundaries.

## Guard against plausible wrong answers

- A valid document can still be economically wrong. Assert units, conventions, qualification,
  the exact economic leaf, and any caller-visible signature named by the task; aliases are additive.
- A JSON tree can contain a field that the selected mapper silently drops. Inspect the typed
  object and canonical reserialization before trusting validation or function output.
- Choices and containment can have multiple economic routes. Before claiming absence, enumerate
  applicable branches and root paths through payouts, collateral, nested products, and trade lots.
- A declared metadata reference is not absent merely because it did not resolve. When absence
  enables a default, general, or permissive branch, detect declaration presence first and fail
  closed on resolution failure. Resolve each reference inside its owning root, then compare the
  resolved business identifiers; raw external, scoped, or global reference strings are not
  cross-root party identity unless the application explicitly defines that shared namespace.
- A qualifier's existence does not prove reachability. Read its predicate and execute positive
  and negative cases.
- Optional cardinality does not override conditional or inherited base-type rules, and an empty
  failure message does not mean no validation failure occurred. Preserve structured finding fields.
- Lifecycle legality is not implied by document validity. Keep application transition guards
  distinct from generated CDM validation.
- Record the exact CDM version with every durable finding. Re-query the active JAR during an
  upgrade instead of carrying model facts forward as timeless prose.

Before reporting a CDM defect, reproduce it with the dependency's generated artefacts,
remove application mapping/policy from the reproducer, inspect the relevant Rune
declarations and choice branches, and compare an ISDA scenario when one exists.
