# Transferable assets and cash securities

Load this reference for cash, bonds and other securities, loans, listed derivatives, money-market
instruments, direct asset trades, bond forwards, and early digital-asset exploration.

## Re-query the active release

Research baseline: these anchors were checked against FINOS CDM 7.0.0 on 2026-08-07. Re-run
them against the consuming project's exact dependency; do not project a current enum or working
group proposal onto a different release.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^enum AssetClassEnum|^choice (Asset|Instrument|Product)'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type (Security|TransferableProduct|AssetIdentifier)\b'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func Qualify_AssetClass_|^func Qualify_.*Debt'
```

Start with `base-staticdata-asset-common-enum.rosetta`,
`base-staticdata-asset-common-type.rosetta`, `product-template-type.rosetta`, and
`product-qualification-func.rosetta`; then follow settlement, payout and event choices used by
the actual trade.

## Keep the taxonomies separate

- `AssetClassEnum` is a classification taxonomy; `Asset` is a transferable-thing choice. In the
  7.0.0 baseline the former includes `MoneyMarket`, while the latter chooses cash, commodity,
  digital asset or instrument. An instrument then chooses listed derivative, loan or security.
- There is no `MoneyMarket` asset-class qualifier in that baseline. Commercial paper or a
  certificate of deposit must be represented through its actual asset/security fields and
  application taxonomy; do not infer a missing product-family API from the enum value.
- `DigitalAsset` is an `Asset` alternative, not a derivative asset-class qualifier and not the
  digital representation of another asset. Tokenized-securities proposals must not be mistaken
  for production model behavior.
- A cash security is normally an `Asset -> Instrument -> Security` inside a
  `TransferableProduct`, with economic terms. Direct or forward settlement adds payout and
  settlement structures. A bond forward may qualify under an interest-rate debt-forward
  predicate; that does not make the bond itself an interest-rate payout.

## Application boundary

CDM owns the typed asset, identifier-with-scheme, taxonomy, issuer roles, economic terms,
settlement and transfer structures. The application owns security-master resolution, issuer and
instrument classification, symbology licences, venue and depository data, settlement eligibility,
corporate-action feeds, and whether an external token represents another asset. Never derive
issuer, type, currency or legal status from an identifier string alone.

## Non-vacuous tests

- Assert the exact asset and instrument choice, identifier value and scheme, asset type, issuer
  roles, currency, price and quantity units, economic terms, settlement centres and direction.
- Round-trip the typed reference graph and prove that product, asset, quantity and transfer
  references resolve after serialization.
- Add a wrong-choice or wrong-scheme negative control and, for direct trades, assert exact asset
  transfer plus cash consideration rather than only document validity.
- If examples share a repo/bond directory, discover and classify them by meaningful content;
  their location does not prove broad bond, money-market or digital-asset coverage.

See [Testing CDM code](testing.md) for the generic test protocol.

## Official context and freshness

- [FINOS CDM product model](https://cdm.finos.org/docs/product-model/) explains transferable and
  non-transferable product composition; exact choices come from the active source.
- [FINOS CDM 7.0.0 source tag](https://github.com/finos/common-domain-model/tree/7.0.0) records
  this guide's research baseline.
- [ICMA's CDM for repo and bonds hub](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/fintech/common-domain-model-cdm/)
  supplies dated bond and repo implementation context, not a live type inventory.
- The FINOS [Tokenized Assets Working Group page](https://cdm.finos.org/docs/next/cdm-tokenized-assets-wg/)
  is under `next` and describes proposals or work in progress. Treat it as pre-release context
  until the required behavior appears in the project's pinned source and runtime.
