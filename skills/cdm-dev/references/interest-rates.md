# Interest-rate products

Load this reference for swaps, cross-currency swaps, inflation products, FRAs, caps/floors,
swaptions, debt options or forwards, floating-rate resets, and rate cash-flow calculations.

## Re-query the active release

Research baseline: these anchors were checked against FINOS CDM 7.0.0 on 2026-08-07. Re-run
them against the consuming project's exact dependency; descriptions, conditions, and functions
can change between releases.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type InterestRatePayout|^type FloatingRate'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func Qualify_(InterestRate|BaseProduct_IRSwap|BaseProduct_CrossCurrency|BaseProduct_Fra|BaseProduct_Inflation)'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func (Create_Reset|CalculateReset|ApplyFloatingRateProcessing)'
```

Follow aliases into `product-asset-type.rosetta`, `observable-asset-type.rosetta`,
`product-qualification-func.rosetta`, `product-asset-floatingrate-func.rosetta`, and the shared
event functions. Read predicates, not only qualifier names.

## Construct and qualify deliberately

- Interest-rate economics are composed from `InterestRatePayout` legs and option/settlement
  structures. The same payout also represents a CDS fee leg, an equity funding leg, and some
  securities-financing economics; its presence alone does not establish this family.
- Inspect fixed, floating, inflation, cross-currency, payment-count, and option branches before
  selecting a qualifier. Base, sub-product, transaction, and product qualifiers are
  compositional rather than one exclusive label.
- Preserve index identity, tenor, day-count, reset and payment dates, business-day adjustments,
  payer/receiver direction, currency, and price/quantity references. Cardinality does not prove
  that a realistic leg satisfies its conditions.
- Define source units at the mapping boundary. Rates may be decimal fractions while another
  source supplies a spread in basis points; a plausible decimal can be economically wrong after
  a missed conversion.

## Lifecycle and application boundary

The model defines reset and calculation inputs, processing rules, and event construction. The
application must supply authorised observations, calendars, reference-data resolution, and any
eligibility or transition policy. Do not invent a fixing because a generated function needs one.

In the 7.0.0 baseline, the floating-rate processing source itself records limitations around
initial-rate, compounding, and some negative-rate treatment. Inspect the exact release and test
the required convention before treating a helper as a complete calculator.

## Non-vacuous tests

- Assert both legs, direction, currencies, schedules, index and tenor, fixed rate, spread and
  their normalized units—not merely validity or a qualifier string.
- Exercise expected qualifiers and a near miss such as the wrong payout count, underlier,
  payment count, or OIS/inflation feature.
- For a reset sequence, assert the supplied observation, calculated rate, before/after state,
  transfer, lineage and event qualification. Include boundary cases for caps, floors, negative
  rates, initial periods and rounding that the application actually supports.
- Discover version-matched conformance examples and require a meaningful floor; never let an
  empty or unmatched corpus pass.

See [Testing CDM code](testing.md) for the generic test protocol.

## Official context and freshness

- [FINOS CDM product model](https://cdm.finos.org/docs/product-model/) describes the composable
  product approach; record its displayed version and verify all paths in the active source.
- [FINOS CDM 7.0.0 source tag](https://github.com/finos/common-domain-model/tree/7.0.0) records
  this guide's research baseline, not the consuming project's implied version.
- [2021 ISDA Interest Rate Derivatives Definitions](https://www.isda.org/2021/10/04/2021-isda-interest-rate-derivatives-definitions/)
  is the maintained definitions landing page. At this guide's retrieval date it listed main-book
  version 15 dated 22 May 2026 and stated that ISDA no longer supports the 2006 Definitions;
  re-check the current version, incorporated terms, and access rights.
- [ISDA reference data](https://www.isda.org/isda-solutions-infohub/isda-reference-data/) supplies
  dated market-standard reference-data context; it is not a substitute for the active model.
