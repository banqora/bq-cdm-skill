# Transferable assets and cash securities

Load this reference for cash, bonds and other securities, loans, listed derivatives, money-market
instruments, direct asset trades, bond forwards, and early digital-asset exploration.

## Contents

- [Re-query the active release](#re-query-the-active-release)
- [Keep the taxonomies separate](#keep-the-taxonomies-separate)
- [Choose the product boundary](#choose-the-product-boundary)
- [Keep asset and settlement tokenisation separate](#keep-asset-and-settlement-tokenisation-separate)
- [Application boundary](#application-boundary)
- [Non-vacuous tests](#non-vacuous-tests)
- [Official context and freshness](#official-context-and-freshness)

## Re-query the active release

Research baseline: these anchors were checked against FINOS CDM 7.0.0 on 2026-08-07. Re-run
them against the consuming project's exact dependency; do not project a current enum or working
group proposal onto a different release.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^choice (Asset|Instrument|Product)|^type (Security|TransferableProduct|EconomicTerms|PayerReceiver|AssetIdentifier)\b|^enum AssetClassEnum'
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

## Choose the product boundary

Start with the official [FINOS product-model distinction](https://cdm.finos.org/docs/product-model/#transferableproduct),
then confirm it in the active Rune source. `Security` minimally identifies and classifies an asset;
`TransferableProduct` associates that asset with `EconomicTerms` for future transfers.

| Caller-visible need | Narrow boundary |
|---|---|
| Identity or security-master reference only | `Asset -> Instrument -> Security` |
| A transferable asset plus supplied, representable future-transfer economics | `TransferableProduct` containing that asset and `EconomicTerms` |
| An executed purchase, sale, or settlement | Add the applicable trade, payout, price/quantity, and settlement structures |

Do not reject `TransferableProduct` merely because a payout uses `CounterpartyRoleEnum`:
`productPartyRole` and `PayerReceiver` are abstract role indirection, not concrete trade parties.
The role election still needs a model-mandated meaning, source fact, or documented application
assumption. Likewise, do not force sparse source data into a payout by inventing schedule,
convention, seniority, principal, or party facts; keep unsupported facts in an explicit application
envelope and state the limitation.

For this boundary decision, use the combined declaration query above and at most one combined Java
API query when the project runtime classpath is already resolved, then compile the first real
builder path. Let compiler errors name any remaining support type; do not survey neighboring Bond,
FpML-ingestion, quantity, rate, enum, validator, or runtime classes before that slice exists.

## Keep asset and settlement tokenisation separate

In the 7.0.0 baseline, classify a native unbacked `DigitalAsset` at asset level, but keep a
tokenised bond as `Asset -> Instrument -> Security`; an application-owned security-master fact
must say that the conventional asset has a token representation. `SettlementTerms` has no ledger,
transfer-rail, or settlement-asset field in that release, so an on-chain cash leg likewise needs an
explicit application-owned fact associated with the relevant settlement instruction.

Inspect the economic paths, not every model object reachable by reflection. For a direct asset
trade, follow `SettlementPayout.underlier` through its `Observable -> Asset` or
`Product -> TransferableProduct -> asset` choice and inspect that payout's settlement terms. For a
product-family shape such as repo, use the version-matched encoding in
[Securities financing](securities-financing.md), not a path inferred from a convenient fixture.
If both asset and settlement evidence exist, their precedence is application policy: state it and
test both sides explicitly.

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
