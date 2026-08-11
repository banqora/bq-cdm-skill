# Repo fail and mini close-out discovery benchmark

Implement a production-oriented Java 21 engine against FINOS CDM 7.0.0 around this caller-visible
operation:

```text
ProcessFail(portfolio, failedTradeId, marketData, action)
```

Support two actions for one failed repo: continue to accrue under the fail-period economics, or
terminate and value that repo through a mini close-out. Design the public Java API and application
state needed to make repeated day-by-day processing explicit. Use genuine generated CDM 7.0.0
objects at a defensible boundary and do not edit generated classes or invent fields on them.

For this task, **repo seller** means the original securities seller/cash borrower and **repo buyer**
means the original securities buyer/cash lender. On the start leg the seller delivers collateral and
the buyer pays the purchase price. On the end leg the buyer returns collateral and the seller pays
the repurchase price.

Mini close-out is a remedy for the selected failed transaction only, not an event-of-default
close-out of every trade with the counterparty. Terminate the selected trade, value its two remaining
obligations, and emit their difference as at most one directional cash payment. Do not emit two gross
payments that merely happen to net economically.

Continue-to-accrue retains the contractual repo economics except that fail-period interest is
floored at zero from the failing party's perspective: a party must not earn negative-rate repo
interest by continuing its own delivery fail. The floor applies only to dates inside the fail window.
Once the fail settles and the repo runs normally, its contractual rate—including a negative
rate—applies again. Use exact decimal arithmetic, the trade's day-count basis, and one final currency
rounding step.

Implement focused tests for these cases:

1. **End-leg netting.** The buyer fails to return collateral. The seller's repurchase-price
   obligation is EUR 10,200,000 and the undelivered collateral is worth EUR 10,500,000 under the
   applicable close-out methodology. Emit exactly one EUR 300,000 payment from buyer to seller and
   terminate the failed trade. There must not be two gross cash flows.
2. **Scope isolation.** Put three live repos with the same counterparty into the portfolio and invoke
   mini close-out for one ID. The other two repos, their CDM trade states, economics, histories, and
   application state must remain untouched. Inputs must not be mutated.
3. **Negative-rate fail window.** Use a EUR 10,000,000 start-leg repo at -0.50% on ACT/360 with the
   seller failing. During each failed day, seller-perspective payable interest is exactly zero, not a
   negative amount that rewards the seller. Resolve the fail and process the next normal day: the
   contractual negative rate resumes, so EUR 138.89 flows from buyer to seller for that day. Prove
   that only the fail window was floored.
4. **Valuation side of market.** On a start-leg seller fail, the terminating buyer replaces 100,000
   undelivered securities at the offer against a EUR 10,000,000 purchase-price obligation. Compare
   quotes EUR 90/110 and EUR 98/102; both have a EUR 100 mid, but the net seller-to-buyer payments
   must be EUR 1,000,000 and EUR 200,000 respectively. A mid-price implementation would return the
   same result and is wrong.

Reject missing or duplicate trade identity, incoherent dates, currencies or quotes, unsupported
actions/bases, and attempts to process a repo that is already closed. Preserve direction explicitly;
do not clamp negative economics or hide direction behind `abs()`.

Add a concise `DESIGN.md` explaining the selected CDM 7.0.0 boundary, which state and calculations
remain application-owned, the close-out netting/sign convention, the fail-window transition, and
which generated validation was executed rather than assumed.

The workspace contains pinned CDM 7.0.0 binary and generated-source JARs under `lib/`. Work offline,
keep the existing dependency declaration unless it is genuinely broken, and run the complete suite
with Gradle 8.10 and Java 21.
