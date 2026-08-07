# CDM JSON dialects

Use this reference before reading, writing, migrating, or comparing CDM JSON. Contemporary
`cdm-java` releases can expose both the older Rosetta serialization and the newer Rune JSON
serialization. Verify the classes and annotations in the active dependency; names and details
can move between releases.

## Identify the document before selecting a mapper

Common distinguishing markers are:

| Feature | Legacy Rosetta JSON | Rune JSON |
|---|---|---|
| scalar with metadata | `{"currency":{"value":"EUR"}}` | `{"currency":{"@data":"EUR"}}` |
| field-with-meta wrapper | extra nested `value` wrapper | value commonly unwraps into its parent |
| reference | object with `scope` and `value` | `@ref:scoped` or another `@ref:*` marker |
| key | `meta.globalKey` / `meta.location` | an `@key:*` marker |
| choice | nested below the alternative name | flattened with an adjacent `@type` |
| root header | commonly absent | `@model`, `@type`, and `@version` |

Mapper classes found in recent releases include:

```text
com.regnosys.rosetta.common.serialisation.RosettaObjectMapper
org.finos.rune.mapper.RuneJsonObjectMapper
```

Do not select one from its name: Rosetta is the modelling language, while
`RosettaObjectMapper` names the legacy JSON representation. Inspect the release's own resource
loader and fixtures to establish which dialect its published artefacts use.

## Make the silent failure impossible

A wrong mapper is not guaranteed to throw. In particular, a legacy Jackson mapper may accept
Rune markers as unknown properties and return a shallow or hollow typed object. Generated
functions can then compute a plausible result from missing input.

Before validation, qualification, comparison, or lifecycle execution:

1. assert the intended root type;
2. assert distinctive required content or a conservative leaf/content floor;
3. inspect typed fields after deserialization;
4. canonically reserialize and compare the affected subtree;
5. report unknown/residual content when the application can retain it.

An empty object that round-trips to an empty object proves only determinism over nothing.

Do not enable Jackson `FAIL_ON_UNKNOWN_PROPERTIES` as a universal fix. Rune `@` markers can be
handled outside ordinary bean properties, and a strict legacy mapper may reject valid Rune
documents without explaining the actual dialect mismatch.

## Derive paths from generated metadata

Do not convert JSON pointers by eye. Along the complete getter route inspect:

- `@RosettaAttribute`;
- `@RuneAttribute`;
- `@RuneMetaType`;
- `@RuneChoiceType`;
- key/reference metadata and list cardinality.

Metadata wrappers can disappear, choice alternatives can flatten, and reference objects can
become marker keys. Derive paths from the active generated dependency or the consuming
project's tested metadata walker, then resolve every path against representative documents.

## Account for pruning

Recent Rune runtimes prune empty model objects during read and write. Pruning can cascade:
an empty leaf disappears, its parent becomes empty, and validation later reports a missing
ancestor. Inspect the active runtime implementation before relying on an exact internal class
name.

Consequences:

- a type with no data-bearing attributes may not survive JSON even if an in-memory builder can
  create it;
- metadata or type markers may not count as data that preserves an otherwise empty object;
- leaf-only comparison cannot see an empty branch disappear;
- validation cannot diagnose a subtree the reader already pruned.

Test object presence as well as leaf equality when empty choices or marker-only objects are
possible.

## Migrate a corpus safely

For each document:

1. detect the source dialect from positive markers; treat marker-free input as ambiguous;
2. deserialize into the correct typed root;
3. serialize with the target mapper;
4. read the output again and compare typed object graphs and reference graphs;
5. verify attributes did not disappear, including empty branches;
6. run the migration a second time and require no further change;
7. update every application JSON pointer and fixture that depends on the old representation.

Reference scopes and global keys can be represented differently while preserving the same
graph, so compare semantics rather than raw wrapper text. Start with no exclusions. Add only
measured, named differences and keep them under test.

Mixed corpora are workable when detection occurs per document and ambiguous inputs follow an
explicit policy. Do not claim that a default was “detected.”

## Diagnose without hiding loss

When both mappers are available, comparing retained typed content can identify a likely
dialect mismatch: if one reader preserves the expected root and substantially more meaningful
content, surface that evidence. Keep this diagnostic separate from the production default.

Report:

- selected and alternative mapper;
- claimed root and detected markers;
- retained required fields or content count;
- unknown/residual paths;
- canonical round-trip differences.

This turns “validation failed later” into the actionable finding “the selected reader dropped
the instruction's before-state.”
