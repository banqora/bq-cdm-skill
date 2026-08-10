# Day-to-day CDM development workflows

Use this reference to find the owning layer and the tests that should travel with an ordinary
CDM change. Project names differ, but the evidence path is stable.

## Contents

- [Orient in an unfamiliar project](#orient-in-an-unfamiliar-project)
- [Add or change an input mapping](#add-or-change-an-input-mapping)
- [Build or change a CDM document](#build-or-change-a-cdm-document)
- [Implement an application-owned calculation](#implement-an-application-owned-calculation)
- [Implement or change a lifecycle event](#implement-or-change-a-lifecycle-event)
- [Debug a dropped or changed value](#debug-a-dropped-or-changed-value)
- [Change validation or qualification handling](#change-validation-or-qualification-handling)
- [Upgrade the CDM dependency](#upgrade-the-cdm-dependency)
- [Review or report a finding](#review-or-report-a-finding)

## Orient in an unfamiliar project

Start from the user-visible behavior, failing test, endpoint, event, or field. Read project
instructions and build files before running commands.

Establish:

- the resolved `cdm-java` version and whether the project wraps or shades it;
- the language, generated-code bindings, and dependency-injection mechanism;
- the document root (`TradeState`, `BusinessEvent`, `WorkflowStep`, or another type);
- the input and output JSON dialect;
- the closest fixture and focused test;
- which stages are generated CDM behavior and which are application behavior.

Trace with `rg` rather than assuming filenames. A common path is:

```text
external payload
  -> source-specific parsing and normalization
  -> application mapping
  -> generated CDM builder / typed object
  -> canonical serialization
  -> generated validation, qualification, or lifecycle functions
  -> application persistence, messaging, or API
```

The project may omit, combine, or rename stages. Describe its real path.

## Add or change an input mapping

1. Locate the source schema, mapping rule, normalization code, representative fixture, and
   test that already handles a neighboring field.
2. Confirm source units, signs, calendars, identifiers, enum vocabulary, and omission
   semantics. Plausible numeric conversions are the most dangerous mapping errors.
3. Locate the target type and field in the active Rosetta source. Check cardinality,
   conditions, metadata, choices, and documented convention.
4. Inspect the generated builder and its serialization annotations in the active dependency
   (Rosetta-era markers such as `@RosettaClass` on 4.x, where attribute-level wire annotations
   are absent; `@RosettaAttribute` plus the `@Rune*` family from 5.x onward). Confirm the
   actual typed route instead of copying a JSON pointer from an example.
5. Keep source-specific selection and conversion in the application's mapping layer. Do not
   present it as an ISDA rule.
6. Assert the typed economic leaf, canonical serialization, validation, expected
   qualification, and provenance. Cover absent and malformed input where omission matters.

If the source represents several economic concepts with one field, make the branch explicit
and test each route. Do not default into a convenient CDM choice merely because it validates.

## Build or change a CDM document

1. Identify the intended root type and existing builder/factory convention.
2. Follow Rosetta inheritance and choices before adding a field.
3. Build a typed object early. A hand-built JSON tree can contain fields that no CDM type
   accepts.
4. Serialize with the project's canonical mapper, read it back into the same root, and compare
   typed economic content.
5. Run generated validation and qualification, but assert the economic leaf separately. A
   structurally valid object can still encode the wrong unit, party role, payout, or date.
6. For references, assert both target resolution and stable identity through the round trip.

When output snapshots change, inspect the complete semantic diff. Refreshing a baseline is
the last step, not the diagnosis.

## Implement an application-owned calculation

1. Lock the caller-visible signature and identify the smallest typed input facts and output
   invariants. Separate facts read from CDM from parameters, policy, and result types owned by the
   application.
2. Batch one model-source and generated-builder pass for the relevant paths, choices,
   cardinalities, units, signs, and descriptions. If the task already names its CDM types and
   fields, query those exact declarations rather than reading surrounding files. Record any fact
   the active release cannot represent instead of searching for a convenient neighboring field.
3. Build the smallest representative input and compile a production vertical slice immediately.
   It must exercise a real getter or builder and one branch; an empty signature-only skeleton does
   not test the API. Use compiler errors to drive any remaining generated-builder inspection.
4. Implement the calculation with exact numeric types and explicit boundary behavior. Do not call a
   generated function with a similar name unless its declared input, output, and semantics match.
5. Test the clean case, every branch boundary, sign or direction asymmetry, invalid parameters, and
   a plausible wrong implementation. Assert that the input is unchanged.
6. Run a targeted CDM rule or generated function only for a model claim it owns. Use full dependency
   injection, qualification, serialization, or whole-root validation only if the production path or
   acceptance contract requires it.

## Implement or change a lifecycle event

1. Find the Rosetta instruction type, orchestration `Create_*` function, primitive functions,
   and intended `Qualify_*` predicates.
2. Reuse generated functions for CDM-defined transformations. Application code should select
   and populate the instruction, enforce application transition policy, and record lineage.
3. Preserve the before-state reference, event/effective dates, identifiers, parties/accounts,
   and keys required by the release's post-processing pipeline.
4. Execute through the project's dependency injection and reference-resolution wiring.
5. Assert the before state, after state, exact economic delta, lineage, validation findings,
   and qualifier output.
6. Include a close negative qualifier case and a sequential event from the prior after-state.
   Independent one-event tests miss stale references and state propagation defects.

Document validity does not prove a transition is legally allowed. If the model has no
precondition for a closed or otherwise ineligible state, implement the guard as explicit
application policy and test it separately.

## Debug a dropped or changed value

Work in this order:

1. Preserve the original bytes and determine the claimed root type.
2. Identify the dialect from document markers and the mapper selected by the application.
3. Deserialize to the typed root and assert a content floor before running business logic.
4. Canonically reserialize and compare the affected typed subtree, not only JSON text.
5. Inspect annotations on the generated getter path, including metadata and choice wrappers.
6. Compare residue or unknown content and try another available mapper only as a diagnostic.
7. Run validators/functions after proving the relevant input survived.

See [JSON dialects](dialects.md). A function computing a plausible result from a hollow object
is a reader failure, not evidence about CDM semantics.

## Change validation or qualification handling

Separate generated findings from application findings in types, logs, API responses, and
tests.

- For a CDM condition, cite its Rosetta declaration and execute the generated validator on a
  failing and passing typed object.
- For an application rule, state why it is outside the model and never relabel it as a
  generated finding.
- Preserve structured validation fields even when a human-readable reason is blank.
- For qualification, expose invocation errors and candidate counts while diagnosing. An
  empty match list with hidden function failures is not a negative result.
- Test specificity: a qualifier that matches every nearby case is broken even if the desired
  case matches.

Do not weaken generated validation to accept application output. Either construct conforming
CDM, surface the finding, or make a named application policy decision.

## Upgrade the CDM dependency

1. Resolve and record both old and candidate JARs without changing the production pin first.
2. Diff relevant `.rosetta` declarations: roots, fields, inheritance, cardinalities,
   conditions, enums, functions, metadata, and choices.
3. Compile against the candidate to expose generated API changes.
4. Run mapping/build tests, dialect round trips, validation and qualification probes,
   lifecycle sequences, and reference resolution.
5. Discover and run the candidate's shipped conformance corpus with no pre-emptive exclusions.
6. Inspect every snapshot/baseline diff and dependency-runtime change.
7. Update durable findings with candidate evidence; delete claims that no longer reproduce.

Do not assume a dependency upgrade is only a schema change. Generated function wiring,
serialization, pruning, runtime libraries, and reference post-processing can change too.

## Review or report a finding

State four things separately:

1. what the exact Rosetta model declares;
2. what the generated runtime does on the smallest typed reproducer;
3. what the consuming application adds or chooses;
4. the resulting business consequence.

Include CDM version, root type, dialect, function/validator name, relevant choice branch, and
reproduction. “The model rejects this,” “the mapper dropped this,” “the generated function
did not qualify this,” and “the application mapped this incorrectly” have different owners.
