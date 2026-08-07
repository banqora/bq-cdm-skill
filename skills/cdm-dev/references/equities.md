# Equity products

Load this reference for equity swaps and forwards, total- or price-return products, dividend,
variance, volatility or correlation products, equity options, and stock-split processing.

## Re-query the active release

Research baseline: these anchors were checked against FINOS CDM 7.0.0 on 2026-08-07. Re-run
them against the consuming project's exact dependency because underlier choices, return terms,
conditions, and qualifier predicates can move.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type PerformancePayout|^choice ReturnTerms|^type .*ReturnTerms'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func Qualify_(AssetClass_Equity|Equity|BaseProduct_Equity|SecurityTypeEquity)'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func (Create_StockSplit|Qualify_StockSplit)'
```

Read `product-template-type.rosetta`, `product-asset-type.rosetta`,
`base-staticdata-asset-common-type.rosetta`, both qualification sources, and the shared event
functions. Underlier typing and return-term combinations are more reliable than desk labels.

## Construct and qualify deliberately

- Equity return economics use `PerformancePayout`; swaps often add an `InterestRatePayout`
  funding leg or a `FixedPricePayout`, forwards use settlement economics, and options wrap an
  underlier. None of those payout types is exclusive to equities.
- Distinguish a single security, an equity index, and a basket in the actual underlier choice.
  Preserve identifiers and schemes instead of inferring the type from a ticker-like string.
- Price return, dividend return, variance, volatility and correlation terms have different
  combinations and conditions. A total-return structure needs both its price and dividend
  economics; a basket or dispersion structure needs constituent-level evidence.
- Preserve payer/receiver direction, quantity, currency, initial/final valuation terms,
  averaging, disruption provisions, funding terms, settlement, and corporate-action treatment.

## Lifecycle and application boundary

The model defines corporate-action observations and event transformations such as stock splits.
The application must obtain the authoritative action, ex/effective dates, ratios, affected
security, price observations, elections and operational policy. A function applies supplied
facts; it does not discover or legally validate the action.

## Non-vacuous tests

- Assert underlier choice and identity, units, direction, prices, quantities, return-term branch,
  funding leg, dates and settlement. Require the intended qualifier and forbid nearby labels.
- Change a security to an index or basket, remove a required return term, or alter the payout
  composition and require qualification to change.
- For a stock split, assert the exact input observation and ratio, unchanged economic currency
  amount where required, reciprocal price/quantity adjustment, before/after references, lineage,
  validation and `StockSplit` qualification. Include a wrong-ratio negative case.
- Discover conformance examples and require meaningful typed content; validity alone cannot
  detect a dropped underlier or a plausible but inverted quantity.

See [Testing CDM code](testing.md) for the generic test protocol.

## Official context and freshness

- [FINOS CDM product model](https://cdm.finos.org/docs/product-model/) explains payout
  composition and qualification at a high level; it may track a release other than yours.
- [FINOS CDM 7.0.0 source tag](https://github.com/finos/common-domain-model/tree/7.0.0) records
  this guide's research baseline.
- [2002 ISDA Equity Derivatives Definitions](https://www.isda.org/book/2002-isda-equity-derivatives-definitions/)
  is the official definitions landing page. The [Equity Definitions VE InfoHub](https://www.isda.org/2025/03/05/equity-definitions-ve-infohub/)
  currently targets 26 October 2026 for industry go-live of the Versionable Edition. As of this
  guide's retrieval date that transition is still prospective: check the live timetable, edition,
  protocol or bilateral adoption, access rights, and terms actually incorporated into the trade.
