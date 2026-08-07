# Conformance with ISDA artefacts

Use the scenarios and examples embedded in the active `cdm-java` dependency when the release
provides them. They are stronger evidence than copied documentation because they travel with
the generated code being evaluated.

## Contents

- [Discover, do not hard-code, the corpus](#discover-do-not-hard-code-the-corpus)
- [Reproduce the release's execution pipeline](#reproduce-the-releases-execution-pipeline)
- [Compare semantics before allowing exclusions](#compare-semantics-before-allowing-exclusions)
- [Treat ingest corpora separately](#treat-ingest-corpora-separately)
- [Report the result precisely](#report-the-result-precisely)

## Discover, do not hard-code, the corpus

Inspect the supplied JAR:

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
JAR="$("$CDM_SOURCE" --jar path/to/cdm-java.jar jar)"
zipinfo -1 "$JAR" | rg '\.(json|xml)$' | cut -d/ -f1-2 | sort -u
```

Resource layout and scenario coverage change across releases: recent releases ship
`functions/` and `ingest/` at the top level; older ones ship `cdm-sample-files/` (function
scenarios under `cdm-sample-files/functions/`), `result-json-files/`, and `ingestions/`. The
`cdm/` prefix holds generated code, not scenario resources. Discover families and pair
runnable inputs with their expected outputs. Require a minimum scenario count so a path or
packaging change cannot turn the test green over an empty corpus.

Extract only the family under test into a fresh temporary directory. The prefix moves between
releases, so discover it from the JAR and fail loudly if the extraction is empty:

```bash
CDM_CORPUS_DIR="$(mktemp -d)"
FAMILY_PREFIX="$(zipinfo -1 "$JAR" | rg 'functions/repo-and-bond/$' | head -1)"
[ -n "$FAMILY_PREFIX" ] || { echo "repo-and-bond family not found in $JAR" >&2; exit 1; }
unzip -q "$JAR" "${FAMILY_PREFIX}*" -d "$CDM_CORPUS_DIR"
[ "$(find "$CDM_CORPUS_DIR" -type f | wc -l)" -gt 0 ] || { echo "empty corpus" >&2; exit 1; }
```

Remove the temporary directory when finished.

## Reproduce the release's execution pipeline

Expected output can depend on more than the visible generated function. In recent releases,
ISDA resource execution has involved:

```text
Rune JSON deserialization
  -> reference resolution
  -> generated Create_* or other function
  -> workflow post-processing
       -> key updates
       -> reference resolution
       -> qualification/taxonomy
```

Locate the release's `ResourcesUtils` helper (`zipinfo -1 "$JAR" | rg -i ResourcesUtils`) —
its package moves between releases and it is absent from the oldest lines — and the relevant
resource tests/classes in the active JAR when they exist. They are signposts for the release's mapper, dependency injection,
reference configuration, enum conversion, and post-processing. Do not assume a pipeline from
another version.

Skipping a stage can produce a structurally plausible disagreement: missing content hashes,
unresolved references, absent qualifiers, or different taxonomy. Use omission of a known
stage as a negative control so the conformance test proves it can detect the difference.

## Compare semantics before allowing exclusions

For each scenario:

1. deserialize the declared input with the release's mapper and intended root;
2. assert a content floor and distinctive input fields;
3. resolve references and run the generated function through real wiring;
4. apply the release's post-processing;
5. compare typed economic content, reference graph, keys, qualifiers, and canonical JSON;
6. execute twice independently and assert determinism when relevant.

Begin with no excluded paths. Inspect every difference and classify it as:

- provenance/build metadata;
- canonical representation with equivalent typed semantics;
- missing pipeline stage or wrong dialect/root;
- application behavior;
- genuine model/runtime disagreement.

Record each approved exclusion in one place with the exact release and proof. An exclusion
copied from another project or version is not evidence.

## Treat ingest corpora separately

An ingest example proves only the products, source format, and mapping implementation shipped
in that dependency. Discover coverage before claiming that CDM itself maps a product.

When comparing an application's mapping with an embedded ingest output, label the two owners:
ISDA's generated/packaged mapping versus the application's source normalization and policy.
Matching one example does not prove full source-format coverage.

## Report the result precisely

Include:

- exact dependency version and JAR;
- resource family and scenario stem;
- input/output root and dialect;
- generated function and runtime wiring;
- excluded paths and why;
- typed economic/reference differences;
- whether the same result reproduces outside application mapping code.

This separates “our engine disagrees with ISDA's shipped output” from “we loaded the resource
with a different pipeline.”
