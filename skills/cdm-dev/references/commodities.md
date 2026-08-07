# Commodity products

Load this reference for commodity swaps, basis swaps, forwards, options, swaptions, commodity
observations, averaging, delivery profiles, and settlement.

## Re-query the active release

Research baseline: these anchors were checked against FINOS CDM 7.0.0 on 2026-08-07. Re-run
them against the consuming project's exact dependency; current web prose and qualifier
descriptions can lag executable predicates.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type (CommodityPayout|Commodity|CommodityReferenceFramework)\b'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func Qualify_(AssetClass_Commodity|Commodity_)'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type (AssetDeliveryPeriods|CalculationScheduleDeliveryPeriods|AveragingCalculation)\b'
```

Follow `base-staticdata-asset-common-type.rosetta`, `product-asset-type.rosetta`, the consolidated
commodity sources, `product-template-type.rosetta`, and `product-qualification-func.rosetta`.
Compare each qualifier's body with its description before relying on either.

## Construct and qualify deliberately

- The transferable `Commodity` asset and `CommodityPayout` are different concepts. A fixed-float
  swap combines floating commodity and fixed-price payouts; a basis swap uses two commodity
  payouts; forwards use settlement plus pricing economics; options wrap an underlier.
- Preserve the commodity/reference-price identity and scheme, unit of measure, currency,
  quantity, pricing dates, averaging method, calculation period, delivery profile and intervals,
  location, settlement type, calendars, disruption and fallback provisions.
- Unit, location and delivery-period mismatches can leave a structurally valid but economically
  wrong document. Never infer a conversion or logistics convention from a commodity name.
- Qualifier coverage does not prove input-format coverage. A model can represent economics that
  a selected FpML view, mapper, or fixture corpus does not ingest.

## Lifecycle and application boundary

The model owns typed commodity, payout, observation, averaging, delivery and settlement
structures plus their declared calculations. The application supplies authorised reference-price
and market data, unit conversions, calendars, location normalization, operational logistics,
fallback selection and any physical-delivery policy.

## Non-vacuous tests

- Assert identity and scheme, unit, currency, quantity, pricing schedule, averaging, delivery
  intervals/location and settlement—not only payout count or validation.
- Run every claimed qualifier with a positive and close negative product. Change the underlier,
  payout composition, unit or settlement route and require a specific failure or different result.
- For calculated prices, assert the exact observations used, weighting/averaging result and
  provenance. Include boundary intervals and a missing-observation case.
- Discover only complete, paired conformance inputs and outputs and require a floor. An empty
  family directory or unpaired examples must fail or be reported as unsupported, not pass.

See [Testing CDM code](testing.md) for the generic test protocol.

## Official context and freshness

- [FINOS CDM product model](https://cdm.finos.org/docs/product-model/) explains common product
  composition but may not enumerate current commodity qualifier coverage.
- [FINOS CDM 7.0.0 source tag](https://github.com/finos/common-domain-model/tree/7.0.0) records
  this guide's research baseline; active source wins when web documentation differs.
- [2005 ISDA Commodity Definitions User's Guide](https://www.isda.org/book/2005-isda-commodity-definitions-users-guide/)
  is the official landing page but is an old base publication. ISDA's [revised Sub-Annex A page](https://www.isda.org/2025/05/02/revised-sub-annex-a-to-the-2005-isda-commodity-definitions/)
  listed version 7, published 29 June 2026, at this guide's retrieval date. Check the current
  commodity-reference-price version, supplements, access terms and material actually
  incorporated into the trade.
