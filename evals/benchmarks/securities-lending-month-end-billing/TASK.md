# Securities-lending month-end billing

Implement a compact, production-oriented Java month-end billing engine for securities loans against
FINOS CDM 7.0.0. This is an application-owned calculation over typed CDM trade facts. It does not
need to invoke the generated invoice function, emit a lifecycle event, or make the deliberately
partial trade fixtures fully qualify.

Provide this exact public API:

```java
package benchmark.billing;

public final class MonthEndBilling {
    public sealed interface LoanEconomics permits FeeTerms, RebateTerms {}

    public record FeeTerms(
        BigDecimal annualFeeRate,
        DayCountFractionEnum dayCountFraction) implements LoanEconomics {}

    public record RebateTerms(
        Money cashCollateral,
        BigDecimal benchmarkRate,
        BigDecimal rebateRate,
        DayCountFractionEnum dayCountFraction) implements LoanEconomics {}

    public record Loan(
        String loanId,
        cdm.event.common.TradeState tradeState,
        String lenderId,
        String borrowerId,
        LoanEconomics economics) {}

    public sealed interface LoanEvent permits
        MarketMark, FeeReRate, BenchmarkReRate, RebateReRate, PartialReturn {}

    public record MarketMark(
        String loanId, LocalDate valuationDate, Money pricePerUnit) implements LoanEvent {}

    public record FeeReRate(
        String loanId, LocalDate effectiveDate, BigDecimal annualFeeRate) implements LoanEvent {}

    public record BenchmarkReRate(
        String loanId, LocalDate effectiveDate, BigDecimal benchmarkRate) implements LoanEvent {}

    public record RebateReRate(
        String loanId, LocalDate effectiveDate, BigDecimal rebateRate) implements LoanEvent {}

    public record PartialReturn(
        String loanId,
        LocalDate instructionDate,
        LocalDate settlementDate,
        BigDecimal returnedQuantity) implements LoanEvent {}

    public record BillingPeriod(LocalDate startInclusive, LocalDate endInclusive) {}

    public record LoanBillingRecord(
        String loanId,
        String lenderId,
        String borrowerId,
        LocalDate accrualStartInclusive,
        LocalDate accrualEndExclusive,
        int accruedDays,
        Money amount) {}

    public record CounterpartySummary(
        String lenderId,
        String borrowerId,
        String currency,
        Money netAmount) {}

    public record InvoiceResult(
        List<LoanBillingRecord> billingRecords,
        List<CounterpartySummary> counterpartySummaries) {}

    public static InvoiceResult GenerateInvoice(
        List<Loan> loans,
        List<? extends LoanEvent> events,
        BillingPeriod billingPeriod);
}
```

`Money` is `cdm.observable.asset.Money`; `DayCountFractionEnum` is
`cdm.base.datetime.daycount.DayCountFractionEnum`. The fully qualified entry point is
`benchmark.billing.MonthEndBilling.GenerateInvoice`.

## Typed CDM boundary

Each `Loan.tradeState` contains one supported securities loan at these exact paths:

```text
TradeState.trade.product.economicTerms.effectiveDate.adjustableDate.unadjustedDate
TradeState.trade.product.economicTerms.terminationDate.adjustableDate.unadjustedDate
TradeState.trade.product.economicTerms.payout[*].assetPayout
TradeState.trade.product.economicTerms.collateral.collateralProvisions.collateralType
AssetPayout.priceQuantity.resolvedQuantity
```

Require `economicTerms.payout` to contain exactly one entry and require that entry to be an
`AssetPayout` with `AssetPayoutTradeTypeEnum.SECURITY_LENDING`. Its resolved quantity must be
positive and use `FinancialUnitEnum.SHARE`. The economic effective date is the loan open date; the
termination date is the full-return settlement date. Both are direct, unadjusted dates for this
focused contract.

The CDM collateral type determines the economic style and must agree with the supplied resolved
terms:

- `NON_CASH` collateral requires `FeeTerms`;
- `CASH` collateral requires `RebateTerms`;
- `CASH_POOL` and any mismatch are unsupported.

The rates and cash-collateral amount in `LoanEconomics` are authoritative resolved application
facts. Do not search for or rewrite duplicate trade-lot prices or payout references. The event list
is the authoritative application event stream. Whole-object qualification, serialization,
generated invoice-function wiring, and lifecycle lineage are out of scope.

## Accrual interval and event timing

`BillingPeriod` is inclusive at both ends. A loan accrues on every calendar date in the intersection
of that period and `[openDate, terminationDate)`: include the open date and exclude the full-return
settlement date. Require a non-empty overlap and emit exactly one `LoanBillingRecord` per input loan.
Its `accrualStartInclusive`, `accrualEndExclusive`, and `accruedDays` must expose the dates actually
accrued: the start is the first accrued date and the end-exclusive value is one calendar day after
the last accrued date. If a partial return reduces the outstanding quantity to zero earlier, that
settlement date becomes the record's end-exclusive date. When the billing-period end binds, the
end-exclusive value is therefore `billingPeriod.endInclusive + 1 day`.

Events may be supplied in any order and are selected by `loanId`:

- A rate change takes effect at the start of its `effectiveDate`, before that date's accrual.
- A `PartialReturn` takes effect at the start of its **settlement date**, before that date's accrual.
  Its instruction date is audit data only and must not change quantity early. Require
  `instructionDate <= settlementDate`; aggregate valid returns on the same settlement date and
  reject any return that would make outstanding quantity negative.
- Initial terms apply from the CDM open date. Relevant earlier events must be applied when deriving
  the opening state for a billing period that begins mid-loan.

Reject null or unknown-loan events, duplicate marks for one loan/date, duplicate changes of the
same rate for one loan/effective date, null dates or fields, malformed amounts, and events that
contradict the loan's economic style. In particular, reject market marks, benchmark re-rates, and
rebate re-rates on fee loans, and reject market marks and fee re-rates on rebate loans. Do not
mutate the loans, CDM objects, event list, or event values.

## Fee and rebate economics

For a non-cash-collateral fee loan, each active day's accrual is:

```text
outstanding share quantity * T-1 price per share * annual fee rate / day-count basis
```

For accrual date D, T-1 means the most recent `MarketMark` whose `valuationDate` is **strictly
before** D. This carries the last available mark through weekends or other non-valuation days; a
mark dated D cannot affect D and first becomes eligible on the following day. Require an eligible
positive mark for every active fee day, and require all marks selected for a loan to use one
non-blank currency.

For a cash-collateral rebate loan, each active day's accrual is:

```text
cash collateral * (benchmark rate - rebate rate) / day-count basis
```

The cash collateral is constant in this focused engine and must be positive with a non-blank
currency. Benchmark and rebate rates are independently re-rateable. A negative spread produces a
negative billing amount; do not floor, clamp, take an absolute value, or reverse its sign.

Support exactly `ACT_360` as basis 360 and `ACT_365_FIXED` as basis 365, independently per loan.
Rates are non-negative decimal fractions such as `0.0365`; their difference may be negative. Use
`BigDecimal` only. Multiply exactly, divide each daily amount to scale 18 with `HALF_EVEN`, retain
that precision while summing the loan, and round the final billing-record amount once to two decimal
places with `HALF_EVEN`. Never pass monetary or rate arithmetic through `double` or `float`.

Positive record amounts mean the borrower owes the lender; negative amounts mean the lender owes
the borrower. Preserve that sign in `Money`.

## Counterparty netting and ordering

Group final, two-decimal billing records by `(lenderId, borrowerId, currency)` and sum their signed
amounts exactly. Do not net across currencies and do not clamp a negative loan before summing.
`CounterpartySummary.netAmount` must equal the sum of the emitted billing-record amounts in that
key, with the same currency.

Return billing records in input-loan order. Return summaries sorted by lender ID, then borrower ID,
then currency. Return unmodifiable defensive copies of both result lists.

## Required focused tests

1. **Baseline, T-1, and fencepost:** a GBP non-cash fee loan has 100,000 shares, opens 1 January
   2025, and fully returns 31 January. A GBP 10 mark on 31 December and a GBP 20 mark on 1 January
   mean 1 January accrues at 10 and 2-30 January at 20. At 3.65% ACT/365 the record is GBP 5,900.00.
   Assert 30 days, start 1 January, and end-exclusive 31 January: accrue on open, never on return.
2. **Mid-month re-rate plus partial return:** a 100,000-share GBP loan at a flat GBP 10 T-1 mark
   starts at 3.65%, re-rates to 7.30% on 12 January, and returns 50,000 shares with instruction on
   15 January but settlement on 20 January. With a 1 February termination, assert the three slices
   1-11, 12-19, and 20-31 produce GBP 3,900.00. Applying the return on instruction date or one day
   after settlement is wrong.
3. **Negative spread and signed netting:** a GBP cash-collateral loan whose rebate exceeds its
   benchmark must emit a negative record. Net it with a positive GBP fee loan for the same lender
   and borrower and assert the signed counterparty total, rather than zero or a sum of absolutes.
4. **Currency/basis split:** in one invoice, a USD fee loan uses `ACT_360` while a GBP fee loan uses
   `ACT_365_FIXED`. Choose values that accrue 10 currency units per day under their respective
   bases, assert both results, and assert separate USD and GBP summaries.

Reject incomplete CDM paths, malformed `Money`, blank identifiers, unsupported day counts,
negative rates, and invalid return quantities with clear exceptions. Keep the implementation
focused and run the tests with the available Gradle 8.10 installation using Java 21. The matching
CDM 7.0.0 binary and source JARs are available under `lib/` for offline inspection.
