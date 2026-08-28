# FpML ingestion and mapping verification

Use this reference when testing FpML-to-CDM ingestion, reviewing or contributing a change to the
model's FpML mapping, or verifying that a mapping preserves source semantics rather than merely
passing a test harness. CDM ships its own FpML mapping; a consuming application's source
normalization and policy remain application-owned. [Conformance](conformance.md) covers corpus
discovery and pipeline reproduction generally; this reference covers the FpML mapping seam,
where a mapping edit can keep a build green while the mapped content becomes wrong.

## Contents

- [Locate the shipped mapping and corpus](#locate-the-shipped-mapping-and-corpus)
- [Read the mapping as model source](#read-the-mapping-as-model-source)
- [Execute the release pipeline, not a re-implementation](#execute-the-release-pipeline-not-a-re-implementation)
- [Expectation counts are not fidelity](#expectation-counts-are-not-fidelity)
- [Verify fidelity with source-derived probes](#verify-fidelity-with-source-derived-probes)
- [Review a mapping contribution](#review-a-mapping-contribution)
- [State the verified claim precisely](#state-the-verified-claim-precisely)

## Locate the shipped mapping and corpus

Dated CDM 7.0.0 observations; rerun the discovery against the active dependency before relying
on any of them:

- The FpML mapping is declared as Rune functions in `cdm/rosetta/ingest-fpml-confirmation-*-func.rosetta`
  under the `cdm.ingest.fpml.confirmation.*` namespaces, embedded in the binary `cdm-java` JAR.
- Generated executable entry points include
  `cdm.ingest.fpml.confirmation.message.functions.Ingest_FpmlConfirmationToTradeState` and
  `Ingest_FpmlConfirmationToWorkflowStep`.
- The corpus ships in the same JAR: `ingest/input/<pack>/*.xml` FpML samples across several FpML
  5.x versions, `ingest/output/<pipeline>/<pack>/*.json` expected CDM documents, and
  `ingest/config/test-pack-*.json` files pairing each input with its expected output.

Earlier majors mapped FpML through synonym annotations and shipped different resource layouts
(`ingestions/`, `cdm-sample-files/`); discover the active release's layout as in
[conformance](conformance.md) rather than assuming this one. Packs whose names carry an
`incomplete-` prefix mark known-partial coverage: never cite one as proof that CDM maps a
product, and never average its results into a fidelity claim.

## Read the mapping as model source

The bundled helpers read the mapping declarations directly from the active JAR:

```bash
scripts/cdm-find --jar path/to/cdm-java.jar ingest fpml price quantity
scripts/cdm-source --jar path/to/cdm-java.jar list 'ingest-fpml.*pricequantity'
scripts/cdm-source --jar path/to/cdm-java.jar type cdm.ingest.fpml.confirmation.pricequantity.MapNetPriceToPriceWithLocation
```

Audit the mapping with targeted queries like these. Do not let broad FpML ingestion matches leak
into an unrelated model task, and do not read a mapping function's intent from its name: read the
declaration, its inputs, and the conditions under which each output leaf is set.

## Execute the release pipeline, not a re-implementation

Test the mapping by running the release's own generated ingest functions through the release's
wiring — XML reading, injection, reference resolution, and post-processing — located from the
resource-test signposts described in [conformance](conformance.md). A re-implementation of the
mapping logic tests the re-implementation.

Expected outputs are dialect-marked documents. CDM 7.0.0 ingest outputs carry Rune markers
(`@model`, `@type`, `@data`); select the mapper from the document's markers as in
[JSON dialects](dialects.md), then assert the intended root type and a content floor before any
comparison. A wrong mapper can return a hollow typed object without throwing, and every
downstream check then measures nothing.

## Expectation counts are not fidelity

CDM 7.0.0 test packs record per-sample assertions of the form `inputPathCount`,
`outputPathCount`, `modelValidationFailures`, and `runtimeError`. Passing them proves the mapping
still produces the same volume of output and the same number of validation failures — not that
any mapped value is right. Two consequences:

- Regenerated expectations bless whatever the mapping now emits. Treat a regenerated expectation
  file or a changed count as a diff to review, and classify every changed leaf as an intended new
  mapping, lost content, a moved representation, or a masked failure — before accepting it.
- A tolerated nonzero `modelValidationFailures` is a standing debt list. Know which rules fail on
  that sample and why before accepting any change that moves the number in either direction; a
  decrease can mean a fix or content that no longer reaches the validator.

A dated CDM 7.0.0 example of how far this can go: the securities-borrowing-and-lending samples
(`sbl-ex01`/`sbl-ex02` in the `fpml-5-12-products-repo` and `fpml-5-13-incomplete-products-repo`
packs) are certified with 8 and 10 tolerated failures while their expected outputs contain no
product, trade lot, or counterparty at all — `MapNonTransferableProduct` has no
`fpml.SecurityLending` or `fpml.Repo` route, so the certified `TradeState` is an identity shell
that fails the generated required-field validators at its root. Do not conclude from the packs'
existence that CDM 7.0.0 ingests FpML securities-financing products; rerun the route check
against the active release.

## Verify fidelity with source-derived probes

The contract that makes a tokenistic mapping unable to pass:

1. Derive every assertion from the source document and the dated FpML version and view recorded
   for the corpus ([industry bodies](industry-bodies.md)) — never from the mapping's current
   output. An expectation regenerated from output is not an assertion.
2. Compare each probed business fact with exact decimal arithmetic under each side's declared
   basis and lexical rules. Keep absent, zero, and empty as three distinct statements in both
   directions. Resolve party and direction facts to identities within the document; raw reference
   strings are not identity.
3. Run the generated validation tiers that apply to the typed result. Type validators, data
   rules, and type-format validators are distinct sweeps; passing one is not passing all
   ([testing](testing.md)).
4. Account for every source element and attribute: mapped to a typed leaf, explicitly skipped
   with a recorded reason, or reported as residual. Silent loss is a failure, not a default.
5. Run one mutation control: perturb a mapped source value and require the typed output leaf to
   move; leave the assertion set unchanged and require it to fail. Regenerating expectations
   after the mutation destroys the control.

## Review a mapping contribution

For a model change that forces mapping edits — the common contribution case — require:

- no constant or placeholder output where the source document carries data;
- no wholesale expectation regeneration without the per-leaf classification above;
- proof that a plausible target leaf is the semantically owning leaf: a name that looks
  equivalent is not a mapping, and the owning declaration's conditions must be satisfied;
- the evidence trio for each touched fact: a source-quoted probe, the applicable validation
  sweeps, and one mutation control;
- the exact CDM version, FpML version and view, and pack names recorded with the review.

A reviewer who cannot obtain this evidence should say the mapping is unverified, not that it is
wrong; an unverified mapping that ships green is the failure mode this reference exists to stop.

## State the verified claim precisely

"The mapping is correct" is not a verifiable claim; a bounded contract is. Report which packs
and samples ran, which facts were probed against source, the accounting result (mapped, skipped
with reason, residual), which validation tiers ran and what they found, and which mutation
controls ran. A 100% claim is achievable and meaningful only against an enumerated contract:
100% of source content accounted for, 100% of probed facts preserved, 100% of applicable
validators executed. An unscoped 100% claim reproduces the failure it is meant to prevent —
green tests standing in for absent evidence.
