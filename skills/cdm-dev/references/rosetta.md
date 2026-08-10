# Rosetta source and generated CDM code

Use this reference when a task depends on what CDM declares, what the generated Java API
exposes, or what the runtime actually does.

## Contents

- [Keep four artefacts distinct](#keep-four-artefacts-distinct)
- [Query the exact dependency](#query-the-exact-dependency)
- [Read a type](#read-a-type)
- [Inspect generated APIs and wire metadata](#inspect-generated-apis-and-wire-metadata)
- [Read a function or qualifier](#read-a-function-or-qualifier)
- [Turn uncertainty into a focused probe](#turn-uncertainty-into-a-focused-probe)

## Keep four artefacts distinct

1. The **Rosetta DSL** declares types, inheritance, fields, cardinalities, conditions, enums,
   functions, aliases, metadata, and qualification logic.
2. **Generated Java** exposes interfaces, immutable implementations, builders, validators,
   functions, and serialization annotations.
3. The **Rosetta/Rune runtime** supplies object mappers, dependency injection, reference
   resolution, pruning, validation orchestration, and post-processing.
4. The **consuming application** selects mappings, roots, functions, policies, storage, and
   error handling.

A Java getter name is not proof of a Rune JSON path. A `0..1` cardinality is not proof that
the field is always semantically optional. A qualifier class existing is not proof that its
predicate is reachable.

## Query the exact dependency

Released `cdm-java` JARs embed their `.rosetta` inputs. Read those rather than cloning a
possibly different CDM branch or copying model prose into the skill.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar version
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type TradeState:'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search 'func Qualify_'
"$CDM_SOURCE" --jar path/to/cdm-java.jar list 'event.*func'
"$CDM_SOURCE" --jar path/to/cdm-java.jar show cdm/rosetta/event-common-type.rosetta
```

The helper also accepts `CDM_JAVA_JAR` and can discover an unambiguous JAR in common build
layouts. If the project has several versions or copies, pass the one resolved by its build.
The helper never downloads a replacement.

Use `search` to locate a declaration before opening a consolidated model file. Record the
reported version and JAR path in bug reports and upgrade evidence.

Bound the evidence pass before opening generated sources. Inspect the owning declaration, its
inheritance chain, its conditions and direct function callees, the generated interface/builder,
then the type's `Meta` registry and only the validators or functions registered there. Batch
independent reads and stop once each reported claim maps to an authoritative artefact; do not
inventory neighboring generated classes without a question they can answer.

Compile after that first pass. Use the compiler to name the remaining generated-API uncertainty,
then inspect only that interface or builder section. Prefer one combined source query and one
focused compile over a sequence of whole-file dumps; repeated reads of the same generated type are
a signal to narrow the question or keep a small probe.

## Read a type

For every field involved, record:

- Rosetta name and declared type;
- cardinality — lower and upper bounds, commonly `0..1`, `1..1`, `0..*`, or `1..*`, but
  arbitrary bounds such as `0..2` or `2..2` also occur;
- inherited fields and parent conditions;
- metadata such as `reference`, `key`, or `scheme`;
- enclosing choice types and each applicable alternative;
- descriptions that establish units, conventions, or intended meaning.

Cardinality and conditions answer different questions. A structurally optional field can be
required when another field is present. Conversely, a validator result on an empty builder
does not establish every condition that applies to a realistic object.

Descriptions are evidence of intent, especially for units and market conventions, but use a
generated validator or function probe before claiming runtime behavior.

For `[metadata key]`, Rune's `globalKey` is a deep content hash, so identical terms do not provide
distinct instruction or leg identity. `externalKey` is supplied by an external source; Rune does
not guarantee that source's uniqueness or lifetime. State those assumptions before joining an
application overlay to either key, and use an application-owned identity when durable distinction
is required.

Reference declaration, reference resolution, and referenced-object identity are three separate
facts. A role or field with an unresolved `ReferenceWithMeta*` value is still declared; never turn
that resolution failure into semantic absence when absence selects a general, default, or
permissive path. Resolve a reference against the keys in its own enclosing root before comparing
objects. Across roots, compare resolved domain identifiers such as party identifiers, or a
documented application identity. Do not compare raw `externalReference`, `scopedReference`, or
`globalReference` strings across roots unless the producer contract defines a shared namespace;
two roots may reuse a local key, while the same object may have different local keys.

## Inspect generated APIs and wire metadata

Search existing compiled usage first. When necessary, inspect the dependency directly with
`jar`, `javap`, an IDE, or a small compile test. Generated APIs can change between releases;
do not recall a builder or function signature from another version.

Which annotations the generated code carries depends on the release; enumerate them from the
active JAR instead of assuming. Older releases (4.x) generate only type-level annotations such
as `@RosettaClass`, `@RosettaMeta`, and `@RosettaDataRule`; the legacy mapper derives wire
names from bean naming conventions, so there is no per-attribute annotation to follow. Recent
releases (5.x+) annotate attributes; relevant annotations include:

- `@RosettaAttribute` for the legacy property name;
- `@RuneAttribute` for the Rune property name;
- `@RuneMetaType` where a metadata wrapper is represented at its parent;
- `@RuneChoiceType` where alternatives flatten and use `@type` (appears from 6.x, once the
  model declares `choice` types).

Where attribute annotations exist, follow them along the complete generated getter path;
where they do not, derive the wire path from the mapper's conventions and confirm with a
round-trip against representative documents. Lists, metadata wrappers, references,
inheritance, and choices can all change the wire path. Do not hard-code a project-wide path
resolver from this skill; use the project's implementation when it has one, or derive and
test the path against the active generated classes.

## Read a function or qualifier

Read the whole declaration and follow its aliases and helper functions. For lifecycle work,
normally inspect:

- the input/instruction type;
- the orchestration `Create_*` function;
- primitive functions called by that orchestration;
- relevant `Qualify_*` functions;
- reference resolution and workflow post-processing expected by the release.

A qualifier roster proves only that generated functions exist. Its Rosetta body explains the
predicate; a typed positive case and a close negative case establish reachability and
specificity. Search every branch of a choice before concluding the model lacks a route.

Generated functions may rely on injected dependencies. Instantiate them through the same
wiring the consuming project uses, or reproduce the release's own test/resource wiring.
Direct construction that leaves dependencies null is not a model result.

Wire that runtime only when the generated function's behavior is part of the requested path. For
application-owned selection, arithmetic, or mechanical construction, prove the model boundary and
test the application code directly. Do not invoke qualifiers, full-root validation, or dependency
injection as general ceremony; use a targeted rule or function probe when it is the smallest
executable evidence for a specific claim.

## Turn uncertainty into a focused probe

When the API, mapper, validator, or function behavior is uncertain:

1. Find the project's active dependency declaration and existing usage.
2. Batch the relevant Rosetta declarations, conditions, and direct callees into one bounded pass.
3. Build the smallest typed object and compile immediately; inspect generated metadata only for
   questions the compiler or wire contract leaves open.
4. Add the narrowest runtime step needed: no generated runtime for application-only behavior, one
   data rule for a condition, one function for a transformation, or full project wiring only for an
   end-to-end runtime claim.
5. Assert meaningful input survived and include a close negative control. For cross-root
   references, include both different local keys resolving to the same domain identity and the
   same local key resolving to different identities. Where absence changes policy, also exercise a
   declared but unresolved reference and require the application to fail closed.
6. Keep the probe as a regression test if the behavior is load-bearing; otherwise move its
   conclusion into the owning production test or report.

Never edit generated dependency classes. Change the application's integration, its pinned
CDM version, or the upstream model through the appropriate contribution process.
