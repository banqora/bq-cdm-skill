# Rosetta source and generated CDM code

Use this reference when a task depends on what CDM declares, what the generated Java API
exposes, or what the runtime actually does.

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

## Read a type

For every field involved, record:

- Rosetta name and declared type;
- cardinality (`0..1`, `1..1`, `0..*`, or `1..*`);
- inherited fields and parent conditions;
- metadata such as `reference`, `key`, or `scheme`;
- enclosing choice types and each applicable alternative;
- descriptions that establish units, conventions, or intended meaning.

Cardinality and conditions answer different questions. A structurally optional field can be
required when another field is present. Conversely, a validator result on an empty builder
does not establish every condition that applies to a realistic object.

Descriptions are evidence of intent, especially for units and market conventions, but use a
generated validator or function probe before claiming runtime behavior.

## Inspect generated APIs and wire metadata

Search existing compiled usage first. When necessary, inspect the dependency directly with
`jar`, `javap`, an IDE, or a small compile test. Generated APIs can change between releases;
do not recall a builder or function signature from another version.

Relevant annotations commonly include:

- `@RosettaAttribute` for the legacy property name;
- `@RuneAttribute` for the Rune property name;
- `@RuneMetaType` where a metadata wrapper is represented at its parent;
- `@RuneChoiceType` where alternatives flatten and use `@type`.

Follow annotations along the complete generated getter path. Lists, metadata wrappers,
references, inheritance, and choices can all change the wire path. Do not hard-code a
project-wide path resolver from this skill; use the project's implementation when it has one,
or derive and test the path against the active generated classes.

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

## Turn uncertainty into a focused probe

When the API, mapper, validator, or function behavior is uncertain:

1. Find the project's active dependency declaration and existing usage.
2. Inspect the relevant Rosetta declaration and generated class metadata.
3. Write the smallest typed compile/runtime probe in the project's normal test framework.
4. Assert meaningful input survived and include a close negative control.
5. Keep the probe as a regression test if the behavior is load-bearing; otherwise move its
   conclusion into the owning production test or report.

Never edit generated dependency classes. Change the application's integration, its pinned
CDM version, or the upstream model through the appropriate contribution process.
