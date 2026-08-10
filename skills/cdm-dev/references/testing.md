# Testing CDM code

The most dangerous CDM test is green while exercising an empty object, stale fixture, wrong
dialect, hidden function error, or unchanged build artefact. Build tests around evidence that
the intended content and code path were actually used.

## Contents

- [Prove meaningful input arrived](#prove-meaningful-input-arrived)
- [Assert economics as well as structure](#assert-economics-as-well-as-structure)
- [Use positive and negative controls](#use-positive-and-negative-controls)
- [Discover open populations](#discover-open-populations)
- [Declare external data as build inputs](#declare-external-data-as-build-inputs)
- [Test typed round trips and references](#test-typed-round-trips-and-references)
- [Test functions through real wiring](#test-functions-through-real-wiring)
- [Separate offline and live checks](#separate-offline-and-live-checks)
- [Upgrade tests](#upgrade-tests)

## Prove meaningful input arrived

Every deserialize/round-trip/function test should assert:

- the intended root type;
- one or more distinctive required fields;
- a conservative content or leaf floor for discovered documents;
- the exact economic field under test.

Then assert validation, qualification, equality, or determinism. Two hollow objects comparing
equal is not a useful round-trip test.

When a hand-built fixture claims a product-family shape, verify that claim separately from the
code under test: run the release validator and applicable `Qualify_*` where practical. If the
fixture is intentionally partial, label it and pair it with a version-matched example or focused
source-derived path probe before treating its shape as model-conformance evidence.

## Assert economics as well as structure

Generated validation proves model conditions, not business intent. A value can be the wrong
unit, basis, sign, party role, date convention, or choice branch and still validate.

For a mapping or builder change, normally assert:

- normalized source value and units;
- typed CDM leaf and enclosing choice;
- canonical serialized representation;
- generated validation findings;
- expected qualifier or deliberate absence;
- application provenance/policy separately.

Use boundary values for decimal fractions, percentages, basis points, dates, and enum
conversions. Include a value that would remain plausible under the most likely wrong
conversion.

For a capped or partitioned economic allocation, keep the agreed total authoritative. Allocate and
round non-final pieces in the currency's minor unit, then make the final piece absorb the exact
decimal residual. Test an exact cap multiple, an under-cap input, a rounding tie, reordered source
candidates, and a deliberately inconsistent derived price; assert both per-piece bounds and exact
aggregate reconciliation without passing through binary floating point.

## Use positive and negative controls

A new check is not established until it has been observed failing for the defect it guards.
Temporarily break the relevant input or pipeline, run the focused test, verify the failure is
specific and actionable, then restore it.

Useful negative controls include:

- choose the wrong mapper and require the content-floor assertion to fail;
- omit workflow post-processing and require conformance comparison to fail;
- remove a required mapping input and require the economic assertion to fail;
- run a qualifier against a nearby non-matching event;
- alter a reference key and require resolution/lineage assertions to fail.

Where absence selects a general, default, or permissive policy branch, test three states instead
of two: truly absent, declared and resolved, and declared but unresolved. The last must not collapse
to absence. For references crossing document roots, also test that different local keys can resolve
to the same business identity and that reusing the same local key for different identities does not
create a match.

Avoid mutations that are expensive or unsafe; a focused fixture or test double is enough.

## Discover open populations

Fixtures, mapping files, Rosetta sources, generated functions, and shipped ISDA scenarios can
grow. Test a property over everything discovered and add a floor so an empty discovery set
cannot pass.

Use exact rosters only for deliberately closed sets whose new member requires an application
decision, such as an internal routing enum. Make the failure message explain whether a number
is a floor or an exact contract.

## Declare external data as build inputs

If tests read files outside conventional test-resource directories, register those paths as
inputs to the relevant build task. Otherwise a cache can report success without re-running
after a fixture or mapping edit.

For Gradle, use relative path sensitivity for relocatable repositories:

```kotlin
tasks.named<Test>("test") {
    inputs.files(fileTree("test-data"))
        .withPropertyName("cdmTestData")
        .withPathSensitivity(PathSensitivity.RELATIVE)
}
```

Adapt this to the project's actual paths and build system. Verify both directions: a data edit
must re-run the task, while an unchanged rerun should remain cacheable.

## Test typed round trips and references

For each supported root and dialect:

1. read representative bytes;
2. assert meaningful typed content;
3. serialize canonically;
4. read again;
5. compare typed economic and reference graphs;
6. require canonical idempotence where the mapper promises it.

Text equality alone is too strict for ordering and too weak for semantic loss hidden by a
normalizer. Compare typed content, then separately approve expected textual canonicalization.

## Test functions through real wiring

Generated functions can depend on injected helpers. Use the project's production-equivalent
dependency injection, reference resolver, and post-processor. Expose invocation errors while
diagnosing; do not turn exceptions into an empty qualifier list.

When the task names a public function, method, command, or wire signature, compile and invoke that
exact entry point in a focused test. A renamed class containing a more idiomatic helper is not a
substitute for the caller-visible contract; keep an alias only in addition to the requested API.

Lifecycle tests should include a sequence, not only isolated events. Assert before/after
identity, economic delta, lineage, keys/references, validation, and classification after each
step.

## Separate offline and live checks

The default suite should run without optional services. Put ledger, database, or remote API
checks behind an explicit task/tag. A live check should fail clearly when its required service
is absent rather than skip and appear green.

Run the offline suite in a network-disabled environment when practical to prove the boundary.
Do not make an ordinary CDM unit test depend on a live integration merely because production
does.

## Upgrade tests

Against both old and candidate dependencies, run:

- compile probes for generated API changes;
- model-path and choice resolution;
- mapping and typed construction;
- each supported dialect round trip;
- validation and qualifier positives/negatives;
- lifecycle sequences and reference resolution;
- the discovered ISDA corpus;
- snapshots with full diff inspection.

Record the dependency version with any expected difference. Never add an exclusion before
measuring the candidate's actual disagreement.
