---
name: cdm-dev
description: Develop, debug, test, upgrade, and review software using FINOS CDM, Rune DSL/source, generated distributions, or Rune runtime. Use for onboarding a Java, Python, TypeScript, JSON Schema, Excel, or other integration; modelling rates, credit, FX, equity, commodity, repo, securities-lending, bond, cash-security, digital-asset, or collateral products; mapping data; building typed objects; tracing dropped fields; migrating JSON dialects; implementing lifecycle events; running functions; diagnosing validation or qualification; testing industry artefacts; implementing DRR/regulatory reporting; or representing legal agreements, elections, clauses, and ISDA/ISLA/ICMA terms. Also use when upgrades alter generated APIs, serialization, paths, or behavior, or when separating CDM/DRR semantics, market practice, legal meaning, and application policy. This is engineering/adoption guidance, not one-off CLI lookup or legal advice.
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
3. Query the version-matched `.rosetta` source. Resolve `scripts/cdm-source` relative to this
   `SKILL.md`; it can use the matching `cdm-java` JAR purely as a source container even when
   the application uses another language. Read [Rosetta and generated code](references/rosetta.md).
4. Add or tighten the smallest test that proves the requested behavior. Assert that meaningful
   content survived, the changed economic leaf is correct, and a close negative case does not
   pass accidentally.
5. Change the narrowest owning layer. Keep source-system conversions in the application,
   model semantics in generated CDM code, and explicit business guards labelled as application
   policy.
6. Run the repository's focused check, then its normal offline suite and formatter/linter.
   Inspect data-driven inputs and snapshot diffs; do not invent a universal build command.

Use [Day-to-day workflows](references/workflows.md) for concrete routes through mapping,
object construction, lifecycle functions, validation, serialization, and upgrades.

## Load only what the task needs

- Product families: [interest rates](references/interest-rates.md),
  [credit derivatives](references/credit-derivatives.md),
  [equities](references/equities.md), [foreign exchange](references/foreign-exchange.md), and
  [commodities](references/commodities.md).
- [Securities financing](references/securities-financing.md): repo, buy/sell-back, securities
  lending, collateral, qualification, and lifecycle traps.
- [Transferable assets and cash securities](references/assets-and-cash-securities.md): cash,
  bonds, loans, listed derivatives, money-market instruments, and digital-asset boundaries.
- [Legal agreements and contracts](references/legal-contracts.md): identification, governing
  relationships, elections, collateral documents, formation, amendment, provenance, and gaps.
- [Digital regulatory reporting](references/regulatory-reporting.md): DRR acquisition and
  compatibility, translate/enrich/transform/project, policy seams, regimes, evidence, and tests.
- [Rosetta and generated code](references/rosetta.md): model declarations, generated APIs,
  metadata annotations, validators, functions, and qualifiers.
- [Day-to-day workflows](references/workflows.md): locating the owning layer and making
  ordinary mapping, document, lifecycle, validation, or upgrade changes.
- [JSON dialects](references/dialects.md): legacy/Rune detection, dropped fields, references,
  pruning, round trips, and migration.
- [Testing CDM code](references/testing.md): non-vacuous assertions, fixtures, build inputs,
  negative controls, and offline/live boundaries.
- [ISDA corpus conformance](references/conformance.md): discovering shipped scenarios and
  comparing application execution with reference outputs.
- [Getting started with CDM](references/onboarding.md): distributions, language options,
  acquisition, capability gaps, version selection, and installation smoke tests.
- [Industry-body guidance](references/industry-bodies.md): dated ISDA, ISLA, ICMA, and FpML
  market-practice sources, with freshness, access, and licensing boundaries.

## Guard against plausible wrong answers

- A valid document can still be economically wrong. Assert units, conventions, the exact
  economic leaf, and expected qualification.
- A JSON tree can contain a field that the selected mapper silently drops. Inspect the typed
  object and canonical reserialization before trusting validation or function output.
- A choice type has multiple legal routes. Search every applicable branch before claiming a
  concept is absent.
- A qualifier's existence does not prove reachability. Read its predicate and execute positive
  and negative cases.
- Optional cardinality does not override conditional rules, and an empty failure message does
  not mean no validation failure occurred. Preserve structured finding fields.
- Lifecycle legality is not implied by document validity. Keep application transition guards
  distinct from generated CDM validation.
- Record the exact CDM version with every durable finding. Re-query the active JAR during an
  upgrade instead of carrying model facts forward as timeless prose.

Before reporting a CDM defect, reproduce it with the dependency's generated artefacts,
remove application mapping/policy from the reproducer, inspect the relevant Rune
declarations and choice branches, and compare an ISDA scenario when one exists.
