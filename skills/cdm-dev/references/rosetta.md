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

Released binary `cdm-java` JARs embed their `.rosetta` inputs. Read those rather than cloning a
possibly different CDM branch or passing the generated-Java `-sources.jar`.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar version
"$CDM_SOURCE" --jar path/to/cdm-java.jar members TradeState PrimitiveInstruction
"$CDM_SOURCE" --jar path/to/cdm-java.jar path TradeState trade.product.economicTerms
"$CDM_SOURCE" --jar path/to/cdm-java.jar type Qualify_FullReturn
"$CDM_SOURCE" --jar path/to/cdm-java.jar list 'event.*func'
"$CDM_SOURCE" --jar path/to/cdm-java.jar show cdm/rosetta/event-common-type.rosetta
```

The helper also accepts `CDM_JAVA_JAR` and can discover an unambiguous JAR in common build
layouts. If the project has several versions or copies, pass the one resolved by its build.
The helper never downloads a replacement.

Use `members` first when you need exact fields, cardinalities, conditions, function inputs/output,
or generated Java names without a whole declaration. Use `path` for one inherited member route and
`type` for the complete declaration. `type` and `members` accept at most eight declarations, and
`type` refuses a combined report above 1,200 lines. All three resolve simple names against the
embedded model and preflight a batch before emitting a report. If a type and function share a Rune name, use the
copyable `type:fully.qualified.Name` or `func:fully.qualified.Name` candidate printed by the helper.
`search` is a capped discovery fallback; refine its regular expression when it prints the
truncation marker rather than opening a consolidated model file. Record the reported version and
JAR path in bug reports and upgrade evidence.

Bound the evidence pass before opening generated sources. Inspect the owning declaration, its
inheritance chain, its conditions and direct function callees, the generated interface/builder,
then the type's `Meta` registry and only the validators or functions registered there. Batch
independent reads and stop once each reported claim maps to an authoritative artefact; do not
inventory neighboring generated classes without a question they can answer.

Compile after that first declaration/API pass even if questions remain. Use the compiler to name
the remaining generated-API uncertainty,
then inspect only that interface or builder section. Prefer one combined source query and one
focused compile over a sequence of whole-file dumps; repeated reads of the same generated type are
a signal to narrow the question or keep a small probe. Generated source and `javap` are alternative
views for most member-signature questions; do not use both after either one has already established
the getter or builder contract you need.

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

Search existing compiled usage first. When necessary, batch exact types through the portable
helper, which prints each public API and matching generated builder in one `javap` pass:

```bash
CDM_API=/path/to/cdm-dev/scripts/cdm-java-api
"$CDM_API" --jar path/to/cdm-java.jar \
  TradeState Trade InterestRatePayout

/path/to/cdm-dev/scripts/cdm-inspect --jar path/to/cdm-java.jar \
  TradeState PrimitiveInstruction Qualify_FullReturn
```

`cdm-inspect` accepts Rune types, choices, enums, functions, and qualification functions. For a
function it prints the exact Rune body, generated abstract API, and generated `$NameDefault`
implementation; for model types it also reports relevant generated metadata and validators. Use
the compact `members`/`path` views first so this full vertical-slice report stays one bounded batch.

Use unqualified names when the owning Rune declaration is known but its generated Java package is
not: the helper prints the one exact fully qualified match. If more than one class shares the name,
it lists candidates and requires a fully qualified choice rather than guessing a package.
After the initial declaration and API batches, compile. Batch only the unresolved symbols named by
that compile once per cycle; if five helper batches have not exposed a viable vertical slice, stop
and re-check the boundary and validation claim instead of continuing symbol-by-symbol exploration.

Generated CDM types and `com.rosetta.model.metafields.*` are in the selected binary. A
`com.rosetta.model.lib.*` support type belongs to the project's resolved Rune runtime; pass that
existing JAR with `--classpath` rather than scanning caches or guessing a version. An IDE, the
generated source JAR, or a small compile test remains an alternative when source detail matters.
Generated APIs can change between releases; do not recall a builder or function signature from
another version.

Validation is an object-graph obligation, not a root-type checkbox. A generated structural
validator and the root `Meta.dataRules()` cover only the type on which they are registered; they do
not recursively execute conditions declared by populated child types. For each accepted or emitted
boundary that is claimed complete:

1. run its structural, type-format, and applicable inherited data rules;
2. enumerate every populated generated child and run that child's registered conditions, including
   choice or `one-of` rules; and
3. retain application-boundary checks that the model deliberately leaves open, such as whether a
   schemed identifier resolves in the application's accepted code set.

Query the child's declaration when its condition is not already shown by `cdm-source type`; do not
guess the generated rule name. Validate the complete caller contract before taking a zero, empty,
replay, or no-op shortcut, because an unrelated result value must not make an unsupported choice
valid.

An intentionally partial generated root is different: label it as a typed fixture, validate the
complete child nodes and lifecycle leaves actually relied on, and do not claim the whole root
qualifies or validates. Expanding a partial trade merely to make unrelated required branches pass
adds risk without strengthening an application-owned calculation.

A claimed-complete boundary has a minimum floor: the root's own validator and the validators of
every populated generated child must pass. Do not add an empty generated shell merely to satisfy a
parent cardinality; either populate and validate that branch or expose a narrower, honestly partial
boundary. A practical graph walk should visit each `RosettaModelObject` identity once and, for every
visited type, execute its generated structural validator, type-format validator, and
`RosettaMetaData.dataRules()`. Assert the visited validator/type set so a newly populated child
cannot silently escape coverage.

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

Generated functions and validation factories may rely on injected dependencies. Instantiate them
through the same wiring the consuming project uses, or reproduce the release's own test/resource
wiring. Before trusting the result, run one trivial positive/negative smoke evaluation that proves
injection happened; a constructed object with null injected fields is not a model result and can
silently skip registered rules. If project wiring is unavailable, instantiate a concrete generated
leaf only after version-matched source shows it has no injected dependencies, and document the
narrower claim. Do not guess or pin a different runtime merely to make injection appear successful.
Never catch a null dependency failure or string-match a generated failure reason and classify the
rule as passed. Either provide the production-equivalent dependency and prove it with a negative
control, select a source-proven dependency-free implementation, or narrow the validation claim.

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
