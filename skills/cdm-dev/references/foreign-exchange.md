# Foreign-exchange products

Load this reference for FX spot and forwards, swaps, non-deliverable forwards or swaps, vanilla
and non-deliverable options, and FX variance, volatility or correlation structures.

## Re-query the active release

Research baseline: these anchors were checked against FINOS CDM 7.0.0 on 2026-08-07. Re-run
them against the consuming project's exact dependency and record the applicable market
definitions separately.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type SettlementPayout|^type ForeignExchangeRateIndex|^type CashSettlementTerms'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func Qualify_(AssetClass_ForeignExchange|ForeignExchange_)'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func MapFx(SingleLeg|Swap|Option|VarianceSwap|VolatilitySwap)'
```

Start in `product-template-type.rosetta`, `product-common-settlement-type.rosetta`,
`observable-asset-type.rosetta`, and `product-qualification-func.rosetta`; then follow the exact
option or performance-return branch in the active release.

## Construct and qualify deliberately

- Deliverable spot/forward economics use `SettlementPayout` with cash underliers; a swap has
  near and far settlement legs. Non-deliverable products are distinguished by their cash
  settlement terms. Options and performance products use different nested structures.
- `Qualify_ForeignExchange_Spot_Forward` intentionally combines spot and forward because the
  boundary depends on local market convention. Do not invent a CDM distinction the predicate
  does not make.
- Preserve both currencies, base/quoted orientation, payer/receiver direction, quantities,
  quoted rate, valuation and settlement dates, settlement currency, fixing source, calendars,
  and near/far ordering. Triangulate rate and both quantities; an inversion often looks valid.
- Treat qualification as evidence about economic structure, not confirmation that a trade is
  deliverable in a jurisdiction or meets a venue's cut-off convention.

## Lifecycle and application boundary

The model owns the typed payout, settlement, observation, calculation and event structures. The
application owns current currency and market conventions, spot cut-offs, holiday centres,
approved fixing sources, observation provenance, sanctions/eligibility rules, and operational
settlement policy.

## Non-vacuous tests

- Assert currency orientation, direction, both quantities, rate, dates and settlement branch.
  Include a quote inversion and swapped-currency negative control that would still look plausible.
- For swaps, assert distinct near/far legs and their directions; for NDF/NDS, assert valuation
  inputs and the sole settlement currency rather than merely the absence of physical delivery.
- Execute the expected qualifier and a nearby negative variant, such as removing cash settlement
  terms or changing the payout count.
- For observations or settlement events, assert source provenance, before/after state, exact
  transfer, reference resolution, lineage, validation and event qualification.

See [Testing CDM code](testing.md) for the generic test protocol.

## Official context and freshness

- [FINOS CDM product model](https://cdm.finos.org/docs/product-model/) is technical orientation;
  use the active source for exact choices and predicates.
- [FINOS CDM 7.0.0 source tag](https://github.com/finos/common-domain-model/tree/7.0.0) records
  this guide's research baseline.
- [2026 FX Definitions](https://www.isda.org/book/2026-fx-definitions/) is the official landing
  page. ISDA and EMTA [announced publication in March 2026](https://www.isda.org/2026/03/03/isda-and-emta-publish-revised-definitions-for-fx-derivatives-market/)
  with implementation planned for 22 November 2027. As of this guide's retrieval date the
  market is in transition; record whether a trade incorporates the 1998 or 2026 definitions and
  re-check the implementation timetable.
