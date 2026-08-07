# Credit derivatives

Load this reference for single-name, index, tranche, loan or basket CDS, credit options, credit
events, and credit settlement processing.

## Re-query the active release

Research baseline: these anchors were checked against FINOS CDM 7.0.0 on 2026-08-07. Re-run
them against the consuming project's exact dependency and record the version with every durable
coverage claim.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type CreditDefaultPayout|^type (Index|Basket)?ReferenceInformation'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func Qualify_(AssetClass_Credit|CreditDefaultSwap|Credit_)'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type CreditEvents|^func Qualify_CreditEventDetermined'
```

Follow the declarations through `product-asset-type.rosetta`, the consolidated credit sources,
`observable-event-type.rosetta`, `product-qualification-func.rosetta`, and
`event-qualification-func.rosetta`. A generated qualifier roster is not a coverage statement.

## Construct and qualify deliberately

- A periodic-premium CDS normally combines one `CreditDefaultPayout` with an
  `InterestRatePayout`; the latter is the fee leg, not proof of an interest-rate product.
- Treat single-name reference information, credit-index information (including tranche terms),
  basket information, and loan references as distinct choice paths. Do not populate several
  branches to hedge uncertainty.
- Preserve reference entity or index identity, obligation identifiers and schemes, seniority,
  protection direction, fee-leg dates and rate, notional, currency, credit-event terms, and
  settlement method. Check percentage/factor ranges and units explicitly.
- Product qualifiers encode executable predicates, not the complete legal or commercial credit
  taxonomy. In the 7.0.0 baseline the credit-swaption qualifier is explicitly described as
  temporary; re-check it before using it for routing.

## Lifecycle and application boundary

CDM can record credit-event observations and construct or qualify resulting business events. It
does not decide whether the contractual standard for a credit event has legally been met. The
application must provide an authorised determination, source provenance, applicable definitions,
notices, dates, elections, reference data, and operational policy.

Keep that evidence outside or alongside the model as appropriate; do not turn a populated
`CreditEvents` branch into an unsupported legal conclusion.

## Non-vacuous tests

- Assert the exact reference branch, identifiers, protection direction, notional, fee rate,
  schedule, currency, settlement terms, and normalized units.
- Run a positive and close negative qualifier case for each supported variant. Change the
  underlier branch, tranche terms, payout count, or option structure and require the expected
  classification to disappear.
- For event processing, assert the authorised observation and provenance, before/after state,
  affected payout, transfers, lineage, validation and event qualification. Also prove that an
  otherwise similar trade without the observation does not become a credit-event determination.
- If using shipped examples, discover paired inputs and expected outputs and assert a content
  floor; the mere existence of a credit directory is not evidence of supported coverage.

See [Testing CDM code](testing.md) for the generic test protocol.

## Official context and freshness

- [FINOS CDM product model](https://cdm.finos.org/docs/product-model/) provides current model
  orientation; verify detailed claims in the active source.
- [FINOS CDM 7.0.0 source tag](https://github.com/finos/common-domain-model/tree/7.0.0) records
  this guide's research baseline.
- [2014 ISDA Credit Derivatives Definitions](https://www.isda.org/book/2014-isda-credit-derivative-definitions/)
  is the official definitions landing page. Use ISDA's [related-material index](https://www.isda.org/book-taxonomy/2014-credit-derivatives-defs/)
  to check supplements and matrices; record access limits and the material actually incorporated
  into the trade before using it as legal context.
