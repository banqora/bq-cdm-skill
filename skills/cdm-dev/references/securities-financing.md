# Securities financing

Load this reference for repurchase agreements, buy/sell-backs, securities lending, collateral,
returns, manufactured income, billing, repricing, substitution, pair-off, shaping, partial delivery,
and repo rolls.

## Contents

- [Re-query the active release](#re-query-the-active-release)
- [Construct and qualify deliberately](#construct-and-qualify-deliberately)
- [Represent corporate-action cash movements](#represent-corporate-action-cash-movements)
- [Separate trade shaping from settlement shaping](#separate-trade-shaping-from-settlement-shaping)
- [Lifecycle and application boundary](#lifecycle-and-application-boundary)
- [Non-vacuous tests](#non-vacuous-tests)
- [Official context and freshness](#official-context-and-freshness)

## Re-query the active release

Research baseline: these anchors and runtime behaviors were checked against FINOS CDM 7.0.0 on
2026-08-07. Re-run source queries and executable probes against the consuming project's exact
dependency; this area has evolved materially between releases.

```bash
CDM_SOURCE=/path/to/cdm-dev/scripts/cdm-source
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type (AssetPayout|Collateral|CollateralPosition|CollateralPortfolio)\b'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^type (CorporateAction|ContingentTransfer|TransferBase|DividendPayoutRatio)\b'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func Qualify_(RepurchaseAgreement|BuySellBack|SecurityLending)'
"$CDM_SOURCE" --jar path/to/cdm-java.jar search '^func (Create_Return|Create_SecurityLendingInvoice|Qualify_(Reprice|Adjustment|Substitution|Renegotiation|PairOff|PartialDelivery))'
```

Follow `product-template-type.rosetta`, `product-collateral-type.rosetta`,
`event-common-type.rosetta`, and both qualification sources. Also inspect the version-matched
repo and securities-lending function examples; directory presence is not a scenario count.

## Construct and qualify deliberately

- In the 7.0.0 baseline, repo and buy/sell-back economics use a top-level
  `InterestRatePayout` plus collateral positions whose nested product contains an `AssetPayout`;
  `tradeType` distinguishes buy/sell-back. Securities lending uses a top-level `AssetPayout` for
  the asset on loan plus cash or non-cash collateral structures.
- `AssetPayout` must not be treated as a cash-underlier shortcut. Follow the `Asset`, `Product`,
  collateral-position and reference choices exactly.
- Preserve open/fixed term, purchase and repurchase dates/prices, quantity, direction, repo or
  lending rate, haircut/margin and their units, collateral eligibility and identity, settlement,
  party roles, and references. A valid, qualified trade can still omit economically essential
  source terms.
- The FINOS 7.0 securities-lending guide expresses a 10% haircut as `0.1` and a 105% margin as
  `1.05`. Verify the active declaration and source-system convention; never apply one percentage
  conversion blindly to both fields.
- Qualifiers are not guaranteed to be mutually exclusive. Evaluate the complete result set and
  assert both required and forbidden labels; do not route on the first result.

## Represent corporate-action cash movements

Keep product terms, observed events, transfer representation, and processing policy distinct:

- `AssetPayout.dividendTerms.manufacturedIncomeRequirement` carries a
  `DividendPayoutRatio`; in the 7.0.0 baseline its `totalRatio` is a resolved product fact, not an
  event identity or replay marker.
- `CorporateAction` can carry `recordDate`, `payDate`, `underlier`, and `dividendObservation`.
  Confirm the selected observation's type, value, unit, and date rather than treating any price as a
  cash dividend.
- A cash movement caused by that event fits `ContingentTransfer` with `transferType =
  CorporateAction` and `corporateActionTransferType = CashDividend`. Use a `Cash` asset, currency-unit
  quantity, settlement date, and actual payer/receiver references whose parties carry identifiers;
  do not put the affected security
  in the transfer's asset merely because it identifies the entitlement.
- In the 7.0.0 baseline, `ScheduledTransferEnum.DividendReturn` describes a synthetic dividend on an
  equity derivative; its plausible name does not make it the corporate-action cash-movement branch.
- `TransferBase` quantities are non-negative and direction belongs in `payerReceiver`. Preserve a
  separately signed application amount when callers need a directional economic result.
- Run the emitted type's structural validator plus applicable inherited `AssetFlowBase` conditions;
  generated Java annotations alone do not prove Rune cardinality or conditional validity.
- The application owns feed event IDs, correction lineage, position history, record-date snapshots,
  and an atomic durable replay ledger. Do not hide those facts in generated CDM fields or transient
  process memory.

## Separate trade shaping from settlement shaping

Inspect a function's output type and populated primitive before reusing it. A function named for
shaping can split one trade into shaped trades; that is not the same operation as splitting a
delivery into capped settlement instructions.

- For operational settlement shaping, preserve the original trade and represent each shape at the
  transfer layer. Where the application treats two legs as DvP, keep the security and opposing cash
  `TransferState` values together in one `TransferInstruction`; do not infer atomicity from the
  function name alone.
- Identify cash and collateral quantities by their observable/asset choices and reconcile them to
  the payout underlier. Require the expected security choice rather than accepting any non-cash
  asset. Repo examples can express both quantities with currency units, so list position or unit
  alone is not a safe discriminator.
- Require the ordered near/far `AssetLeg` pair, the expected delivery method on the selected leg,
  and its settlement date. Establish role direction from the active release's examples and
  functions. In the CDM 7.0.0 repo-and-bond baseline, the `AssetPayout` direction is the far
  collateral return; reverse it for the start delivery. Resolve actual party references, fail
  closed on a declared but unresolved wrapper, and make the paired cash direction exactly opposite.
- Treat a bare cap as an amount in the collateral nominal's unit and use the agreed cash quantity as
  authoritative. The 7.0.0 `AssetFlowBase.QuantityUnitExists` condition requires a financial unit
  for an Instrument transfer, while the repo example carries currency-denominated bond nominal and
  `FinancialUnitEnum` has no bond-face unit. Preserve the economics behind an explicit application
  boundary; never relabel the amount as shares merely to satisfy validation.

## Lifecycle and application boundary

CDM provides product predicates and lifecycle functions, but the application owns agreement and
eligibility rules, authorised notices, market/reference data, substitutions, settlement status,
inventory, dispute policy and operational sequencing.

Do not assume a function's name predicts its event qualifier. In the 7.0.0 baseline, a tested
collateral-substitution path can qualify as `Renegotiation` rather than `Substitution` after the
event predicate inspects the produced primitives. Execute all relevant event qualifiers and keep
an upgrade tripwire for the behavior your application relies on.

## Non-vacuous tests

- Assert every key economic leaf, its unit, the top-level and nested payout paths, collateral
  references and terms, open/fixed termination behavior, and required plus forbidden qualifiers.
- Exercise the production-equivalent function wiring. For each lifecycle step assert input
  instruction, before/after economics, exact quantity or cash delta, transfers, lineage,
  references, validation, classification, and deterministic rerun.
- Add a nearby negative for missing/changed collateral, `tradeType`, rate, payout location or
  termination terms. Demonstrate that the test fails for the plausible wrong representation.
- For an ordered near/far flow, assert which leg supplied the date, delivery method and party
  direction; mutate each independently and require the focused test to catch selection of the other
  leg or an unsupported settlement method.
- Discover complete input/output pairs in version-matched examples and require a content floor;
  do not hard-code a count from documentation or let an empty discovery set pass.

See [Testing CDM code](testing.md) for the generic test protocol.

## Official context and freshness

- [FINOS securities-lending documentation](https://cdm.finos.org/docs/securities-lending/) and
  [FINOS repo representation](https://cdm.finos.org/docs/repurchase-agreement-representation/)
  are useful implementation guides; record their displayed version and confirm paths in source.
- [HMRC CFM74430](https://www.gov.uk/hmrc-internal-manuals/corporate-finance-manual/cfm74430)
  gives dated tax context for manufactured payments; treat supplied implementation rules as the
  contract rather than inferring legal conclusions from the manual.
- The ECB SCoRE Corporate Actions standards distinguish
  [negative cash flows (Standard 5)](https://www.ecb.europa.eu/paym/groups/pdf/dimcg/ecb.dimcg210127_item3.3.en.pdf)
  from [corporate-action reversals (Standard 13)](https://www.ecb.europa.eu/paym/groups/shared/docs/04f2d-ami-seco-2023-06-16-item-4.1b-score-standards-faq.pdf).
- [ISLA's CDM hub](https://www.islagroup.org/common-domain-model/) provides dated
  securities-lending coverage and adoption material.
- [ICMA's CDM for repo and bonds hub](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/fintech/common-domain-model-cdm/)
  provides dated phase and implementation material.
- Use the [ICMA ERCC Guide landing page](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/icma-ercc-publications/icma-ercc-guide-to-best-practice-in-the-european-repo-market/)
  to select the latest effective guide. Market practice and agreement terms are context, not
  proof that the active CDM runtime enforces them.
