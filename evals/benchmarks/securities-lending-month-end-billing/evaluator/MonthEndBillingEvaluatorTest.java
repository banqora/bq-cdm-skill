package benchmark.billing;

import static benchmark.billing.MonthEndBilling.GenerateInvoice;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import benchmark.billing.MonthEndBilling.BenchmarkReRate;
import benchmark.billing.MonthEndBilling.BillingPeriod;
import benchmark.billing.MonthEndBilling.CounterpartySummary;
import benchmark.billing.MonthEndBilling.FeeReRate;
import benchmark.billing.MonthEndBilling.FeeTerms;
import benchmark.billing.MonthEndBilling.InvoiceResult;
import benchmark.billing.MonthEndBilling.Loan;
import benchmark.billing.MonthEndBilling.LoanBillingRecord;
import benchmark.billing.MonthEndBilling.LoanEvent;
import benchmark.billing.MonthEndBilling.MarketMark;
import benchmark.billing.MonthEndBilling.PartialReturn;
import benchmark.billing.MonthEndBilling.RebateReRate;
import benchmark.billing.MonthEndBilling.RebateTerms;
import cdm.base.datetime.AdjustableDate;
import cdm.base.datetime.AdjustableOrRelativeDate;
import cdm.base.datetime.daycount.DayCountFractionEnum;
import cdm.base.math.FinancialUnitEnum;
import cdm.base.math.Quantity;
import cdm.base.math.UnitType;
import cdm.event.common.Trade;
import cdm.event.common.TradeState;
import cdm.observable.asset.Money;
import cdm.product.collateral.Collateral;
import cdm.product.collateral.CollateralProvisions;
import cdm.product.collateral.CollateralTypeEnum;
import cdm.product.common.settlement.ResolvablePriceQuantity;
import cdm.product.template.AssetPayout;
import cdm.product.template.AssetPayoutTradeTypeEnum;
import cdm.product.template.EconomicTerms;
import cdm.product.template.NonTransferableProduct;
import cdm.product.template.Payout;
import cdm.product.asset.InterestRatePayout;
import com.rosetta.model.lib.records.Date;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

class MonthEndBillingEvaluatorTest {
    private static final LocalDate JAN_1 = LocalDate.of(2025, 1, 1);
    private static final BillingPeriod JANUARY =
            new BillingPeriod(JAN_1, LocalDate.of(2025, 1, 31));

    @Test
    void baselineUsesTMinusOneAndOpenInclusiveReturnExclusiveFencepost() {
        Loan loan = feeLoan("baseline", "LENDER", "BORROWER", JAN_1,
                LocalDate.of(2025, 1, 31), "100000", "0.0365",
                DayCountFractionEnum.ACT_365_FIXED);
        List<LoanEvent> events = List.of(
                mark("baseline", "2024-12-31", "10", "GBP"),
                mark("baseline", "2025-01-01", "20", "GBP"),
                mark("baseline", "2025-01-31", "100", "GBP"));

        InvoiceResult result = GenerateInvoice(List.of(loan), events, JANUARY);

        assertEquals(1, result.billingRecords().size());
        LoanBillingRecord record = result.billingRecords().getFirst();
        assertEquals(JAN_1, record.accrualStartInclusive());
        assertEquals(LocalDate.of(2025, 1, 31), record.accrualEndExclusive());
        assertEquals(30, record.accruedDays());
        assertMoney("5900.00", "GBP", record.amount());
        assertEquals(1, result.counterpartySummaries().size());
        assertMoney("5900.00", "GBP", result.counterpartySummaries().getFirst().netAmount());
    }

    @Test
    void rerateAndPartialReturnSegmentAtEffectiveAndSettlementDates() {
        Loan loan = feeLoan("segmented", "LENDER", "BORROWER", JAN_1,
                LocalDate.of(2025, 2, 1), "100000", "0.0365",
                DayCountFractionEnum.ACT_365_FIXED);
        List<LoanEvent> events = List.of(
                new PartialReturn("segmented", LocalDate.of(2025, 1, 15),
                        LocalDate.of(2025, 1, 20), bd("50000")),
                mark("segmented", "2024-12-31", "10", "GBP"),
                new FeeReRate("segmented", LocalDate.of(2025, 1, 12), bd("0.0730")));

        LoanBillingRecord record = GenerateInvoice(List.of(loan), events, JANUARY)
                .billingRecords().getFirst();

        assertEquals(JAN_1, record.accrualStartInclusive());
        assertEquals(LocalDate.of(2025, 2, 1), record.accrualEndExclusive());
        assertEquals(31, record.accruedDays());
        assertMoney("3900.00", "GBP", record.amount());
    }

    @Test
    void negativeRebateRecordNetsSignedAgainstPositiveFee() {
        Loan rebate = rebateLoan("rebate", "LENDER", "BORROWER", JAN_1,
                LocalDate.of(2025, 1, 11), "100", "365000", "0.02", "0.03",
                "GBP", DayCountFractionEnum.ACT_365_FIXED);
        Loan fee = feeLoan("fee", "LENDER", "BORROWER", JAN_1,
                LocalDate.of(2025, 1, 11), "100000", "0.0365",
                DayCountFractionEnum.ACT_365_FIXED);

        InvoiceResult result = GenerateInvoice(
                List.of(rebate, fee),
                List.of(mark("fee", "2024-12-31", "10", "GBP")),
                JANUARY);

        assertMoney("-100.00", "GBP", result.billingRecords().get(0).amount());
        assertMoney("1000.00", "GBP", result.billingRecords().get(1).amount());
        assertEquals(1, result.counterpartySummaries().size());
        assertMoney("900.00", "GBP", result.counterpartySummaries().getFirst().netAmount());
    }

    @Test
    void dayCountBasisAndCurrencyAreIndependentPerLoan() {
        Loan usd = feeLoan("usd", "LENDER", "BORROWER", JAN_1,
                LocalDate.of(2025, 1, 11), "36000", "0.01", DayCountFractionEnum.ACT_360);
        Loan gbp = feeLoan("gbp", "LENDER", "BORROWER", JAN_1,
                LocalDate.of(2025, 1, 11), "36500", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);

        InvoiceResult result = GenerateInvoice(
                List.of(usd, gbp),
                List.of(
                        mark("gbp", "2024-12-31", "10", "GBP"),
                        mark("usd", "2024-12-31", "10", "USD")),
                JANUARY);

        assertMoney("100.00", "USD", result.billingRecords().get(0).amount());
        assertMoney("100.00", "GBP", result.billingRecords().get(1).amount());
        assertEquals(List.of("GBP", "USD"), result.counterpartySummaries().stream()
                .map(CounterpartySummary::currency).toList());
        assertMoney("100.00", "GBP", result.counterpartySummaries().get(0).netAmount());
        assertMoney("100.00", "USD", result.counterpartySummaries().get(1).netAmount());
    }

    @Test
    void priorPeriodEventsEstablishOpeningStateAndInputOrderIsIrrelevant() {
        Loan loan = feeLoan("opening", "LENDER", "BORROWER", LocalDate.of(2024, 12, 1),
                LocalDate.of(2025, 2, 1), "100000", "0.0365",
                DayCountFractionEnum.ACT_365_FIXED);
        BillingPeriod twoDays = new BillingPeriod(JAN_1, LocalDate.of(2025, 1, 2));
        List<LoanEvent> chronological = List.of(
                new FeeReRate("opening", LocalDate.of(2024, 12, 15), bd("0.0730")),
                new PartialReturn("opening", LocalDate.of(2024, 12, 10),
                        LocalDate.of(2024, 12, 20), bd("20000")),
                mark("opening", "2024-12-31", "10", "GBP"));
        List<LoanEvent> reversed = new ArrayList<>(chronological);
        java.util.Collections.reverse(reversed);

        InvoiceResult first = GenerateInvoice(List.of(loan), chronological, twoDays);
        InvoiceResult second = GenerateInvoice(List.of(loan), reversed, twoDays);

        assertEquals(JAN_1, first.billingRecords().getFirst().accrualStartInclusive());
        assertEquals(LocalDate.of(2025, 1, 3),
                first.billingRecords().getFirst().accrualEndExclusive());
        assertMoney("320.00", "GBP", first.billingRecords().getFirst().amount());
        assertMoney("320.00", "GBP", second.billingRecords().getFirst().amount());
        assertMoney(first.counterpartySummaries().getFirst().netAmount().getValue().toPlainString(),
                "GBP", second.counterpartySummaries().getFirst().netAmount());
    }

    @Test
    void validBenchmarkAndRebateReratesBothSegmentCashAccrual() {
        BillingPeriod threeDays = new BillingPeriod(JAN_1, LocalDate.of(2025, 1, 3));
        Loan rebate = rebateLoan("cash-rerates", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 4), "1", "360000", "0.01", "0.01", "GBP",
                DayCountFractionEnum.ACT_360);

        LoanBillingRecord record = GenerateInvoice(List.of(rebate), List.of(
                        new RebateReRate("cash-rerates", LocalDate.of(2025, 1, 3), bd("0.04")),
                        new BenchmarkReRate("cash-rerates", LocalDate.of(2025, 1, 2), bd("0.03"))),
                threeDays).billingRecords().getFirst();

        assertEquals(3, record.accruedDays());
        assertMoney("10.00", "GBP", record.amount());
    }

    @Test
    void cdmOpenDateBoundsAStartInsideTheBillingPeriod() {
        Loan loan = feeLoan("mid-open", "L", "B", LocalDate.of(2025, 1, 15),
                LocalDate.of(2025, 1, 18), "36500", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);

        LoanBillingRecord record = GenerateInvoice(List.of(loan),
                List.of(mark("mid-open", "2025-01-14", "10", "GBP")), JANUARY)
                .billingRecords().getFirst();

        assertEquals(LocalDate.of(2025, 1, 15), record.accrualStartInclusive());
        assertEquals(LocalDate.of(2025, 1, 18), record.accrualEndExclusive());
        assertEquals(3, record.accruedDays());
        assertMoney("30.00", "GBP", record.amount());
    }

    @Test
    void fullPartialReturnEndsTheRecordOnItsSettlementDate() {
        Loan loan = feeLoan("early-full", "L", "B", JAN_1,
                LocalDate.of(2025, 2, 1), "36500", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);

        LoanBillingRecord record = GenerateInvoice(List.of(loan), List.of(
                        mark("early-full", "2024-12-31", "10", "GBP"),
                        new PartialReturn("early-full", LocalDate.of(2025, 1, 2),
                                LocalDate.of(2025, 1, 3), bd("36500"))), JANUARY)
                .billingRecords().getFirst();

        assertEquals(JAN_1, record.accrualStartInclusive());
        assertEquals(LocalDate.of(2025, 1, 3), record.accrualEndExclusive());
        assertEquals(2, record.accruedDays());
        assertMoney("20.00", "GBP", record.amount());
    }

    @Test
    void halfEvenRecordRoundingAndSummaryOfRoundedRecordsBothHold() {
        BillingPeriod fiveDays = new BillingPeriod(JAN_1, LocalDate.of(2025, 1, 5));
        Loan fee = feeLoan("round-fee", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 6), "365", "0.005",
                DayCountFractionEnum.ACT_365_FIXED);
        Loan rebate = rebateLoan("round-rebate", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 6), "1", "365", "0", "0.005", "GBP",
                DayCountFractionEnum.ACT_365_FIXED);
        Loan firstReconciling = feeLoan("reconcile-a", "L2", "B2", JAN_1,
                LocalDate.of(2025, 1, 4), "365", "0.005",
                DayCountFractionEnum.ACT_365_FIXED);
        Loan secondReconciling = feeLoan("reconcile-b", "L2", "B2", JAN_1,
                LocalDate.of(2025, 1, 4), "365", "0.005",
                DayCountFractionEnum.ACT_365_FIXED);

        InvoiceResult result = GenerateInvoice(
                List.of(fee, rebate, firstReconciling, secondReconciling),
                List.of(
                        mark("round-fee", "2024-12-31", "1", "GBP"),
                        mark("reconcile-a", "2024-12-31", "1", "GBP"),
                        mark("reconcile-b", "2024-12-31", "1", "GBP")),
                fiveDays);

        assertMoney("0.02", "GBP", result.billingRecords().get(0).amount());
        assertMoney("-0.02", "GBP", result.billingRecords().get(1).amount());
        assertMoney("0.02", "GBP", result.billingRecords().get(2).amount());
        assertMoney("0.02", "GBP", result.billingRecords().get(3).amount());
        assertMoney("0.00", "GBP", result.counterpartySummaries().getFirst().netAmount());
        assertMoney("0.04", "GBP", result.counterpartySummaries().get(1).netAmount());
    }

    @Test
    void nonTerminatingDailyDivisionRetainsAccrualPrecision() {
        Loan loan = feeLoan("precision", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 31), "1000", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);

        LoanBillingRecord record = GenerateInvoice(List.of(loan),
                List.of(mark("precision", "2024-12-31", "1", "GBP")), JANUARY)
                .billingRecords().getFirst();

        assertEquals(30, record.accruedDays());
        assertMoney("0.82", "GBP", record.amount());
    }

    @Test
    void cdmTopologyAndCollateralStyleAreValidated() {
        Loan cashWithFee = new Loan("mismatch-a",
                trade(JAN_1, LocalDate.of(2025, 1, 11), "100", CollateralTypeEnum.CASH,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.SHARE, 1),
                "L", "B", new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_365_FIXED));
        Loan nonCashWithRebate = new Loan("mismatch-b",
                trade(JAN_1, LocalDate.of(2025, 1, 11), "100", CollateralTypeEnum.NON_CASH,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.SHARE, 1),
                "L", "B", new RebateTerms(money("100", "GBP"), bd("0.01"), bd("0.01"),
                        DayCountFractionEnum.ACT_365_FIXED));
        Loan wrongTradeType = new Loan("wrong-type",
                trade(JAN_1, LocalDate.of(2025, 1, 11), "100", CollateralTypeEnum.NON_CASH,
                        AssetPayoutTradeTypeEnum.REPO, FinancialUnitEnum.SHARE, 1),
                "L", "B", new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_365_FIXED));
        Loan extraPayout = new Loan("extra",
                trade(JAN_1, LocalDate.of(2025, 1, 11), "100", CollateralTypeEnum.NON_CASH,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.SHARE, 2),
                "L", "B", new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_365_FIXED));
        Loan extraOtherPayout = new Loan("extra-other",
                withExtraInterestPayout(trade(JAN_1, LocalDate.of(2025, 1, 11), "100",
                        CollateralTypeEnum.NON_CASH,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.SHARE, 1)),
                "L", "B", new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_365_FIXED));
        Loan wrongUnit = new Loan("unit",
                trade(JAN_1, LocalDate.of(2025, 1, 11), "100", CollateralTypeEnum.NON_CASH,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.CONTRACT, 1),
                "L", "B", new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_365_FIXED));

        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(cashWithFee),
                        List.of(mark("mismatch-a", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(nonCashWithRebate), List.of(), JANUARY));
        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(wrongTradeType),
                        List.of(mark("wrong-type", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(extraPayout),
                        List.of(mark("extra", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(extraOtherPayout),
                        List.of(mark("extra-other", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(wrongUnit),
                        List.of(mark("unit", "2024-12-31", "1", "GBP")), JANUARY));
    }

    @Test
    void invalidMarksReturnsAndEventRoutingFailClosed() {
        Loan fee = feeLoan("guard-fee", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 11), "100", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);
        Loan rebate = rebateLoan("guard-rebate", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 11), "100", "100", "0.01", "0.02", "GBP",
                DayCountFractionEnum.ACT_365_FIXED);

        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(fee), List.of(), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(fee), List.of(
                mark("guard-fee", "2024-12-31", "1", "GBP"),
                mark("guard-fee", "2024-12-31", "2", "GBP")), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(fee), List.of(
                mark("guard-fee", "2024-12-31", "1", "GBP"),
                new PartialReturn("guard-fee", LocalDate.of(2025, 1, 5),
                        LocalDate.of(2025, 1, 4), bd("1"))), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(fee), List.of(
                mark("guard-fee", "2024-12-31", "1", "GBP"),
                new PartialReturn("guard-fee", LocalDate.of(2025, 1, 4),
                        LocalDate.of(2025, 1, 5), bd("101"))), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(fee), List.of(
                mark("guard-fee", "2024-12-31", "1", "GBP"),
                new BenchmarkReRate("guard-fee", LocalDate.of(2025, 1, 2), bd("0.01"))),
                JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(rebate), List.of(
                new FeeReRate("guard-rebate", LocalDate.of(2025, 1, 2), bd("0.01"))),
                JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(rebate), List.of(
                mark("guard-rebate", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(rebate), List.of(
                new RebateReRate("unknown", LocalDate.of(2025, 1, 2), bd("0.01"))),
                JANUARY));
    }

    @Test
    void duplicateRatesInvalidMoneyAndUnsupportedBasisFailClosed() {
        Loan fee = feeLoan("duplicates", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 11), "100", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);
        List<LoanEvent> duplicateRates = List.of(
                mark("duplicates", "2024-12-31", "1", "GBP"),
                new FeeReRate("duplicates", LocalDate.of(2025, 1, 2), bd("0.02")),
                new FeeReRate("duplicates", LocalDate.of(2025, 1, 2), bd("0.03")));
        Loan unsupportedBasis = new Loan("basis", fee.tradeState(), "L", "B",
                new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_ACT_ISDA));
        Loan malformedCash = new Loan("cash", rebateLoan("cash-source", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 11), "100", "100", "0.01", "0.02", "GBP",
                DayCountFractionEnum.ACT_365_FIXED).tradeState(), "L", "B",
                new RebateTerms(Money.builder().setValue(bd("100")).build(), bd("0.01"),
                        bd("0.02"), DayCountFractionEnum.ACT_365_FIXED));
        Loan negativeRate = new Loan("negative", fee.tradeState(), "L", "B",
                new FeeTerms(bd("-0.01"), DayCountFractionEnum.ACT_365_FIXED));
        Loan cashPool = new Loan("pool",
                trade(JAN_1, LocalDate.of(2025, 1, 11), "100", CollateralTypeEnum.CASH_POOL,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.SHARE, 1),
                "L", "B", new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_365_FIXED));
        Loan blankId = new Loan("", fee.tradeState(), "L", "B",
                new FeeTerms(bd("0.01"), DayCountFractionEnum.ACT_365_FIXED));
        Loan noOverlap = feeLoan("future", "L", "B", LocalDate.of(2025, 2, 1),
                LocalDate.of(2025, 2, 2), "100", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);
        Loan mixedCurrency = feeLoan("mixed", "L", "B", JAN_1,
                LocalDate.of(2025, 1, 3), "100", "0.01",
                DayCountFractionEnum.ACT_365_FIXED);

        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(fee), duplicateRates, JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(unsupportedBasis),
                List.of(mark("basis", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class,
                () -> GenerateInvoice(List.of(malformedCash), List.of(), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(negativeRate),
                List.of(mark("negative", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(cashPool),
                List.of(mark("pool", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(blankId),
                List.of(mark("", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(fee, fee),
                List.of(mark("duplicates", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(fee),
                List.of(mark("duplicates", "2024-12-31", "1", "GBP")),
                new BillingPeriod(LocalDate.of(2025, 1, 2), JAN_1)));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(noOverlap),
                List.of(mark("future", "2024-12-31", "1", "GBP")), JANUARY));
        assertThrows(RuntimeException.class, () -> GenerateInvoice(List.of(mixedCurrency), List.of(
                mark("mixed", "2024-12-31", "1", "GBP"),
                mark("mixed", "2025-01-01", "1", "USD")), JANUARY));
    }

    @Test
    void resultCollectionsAreImmutableAndSummaryOrderingIsDeterministic() {
        Loan zUsd = feeLoan("z-usd", "Z", "B", JAN_1, LocalDate.of(2025, 1, 2),
                "360", "0.01", DayCountFractionEnum.ACT_360);
        Loan aUsd = feeLoan("a-usd", "A", "C", JAN_1, LocalDate.of(2025, 1, 2),
                "360", "0.01", DayCountFractionEnum.ACT_360);
        Loan aGbp = feeLoan("a-gbp", "A", "B", JAN_1, LocalDate.of(2025, 1, 2),
                "365", "0.01", DayCountFractionEnum.ACT_365_FIXED);
        List<Loan> loans = new ArrayList<>(List.of(zUsd, aUsd, aGbp));
        List<LoanEvent> events = new ArrayList<>(List.of(
                mark("z-usd", "2024-12-31", "1", "USD"),
                mark("a-usd", "2024-12-31", "1", "USD"),
                mark("a-gbp", "2024-12-31", "1", "GBP")));

        InvoiceResult result = GenerateInvoice(loans, events,
                new BillingPeriod(JAN_1, LocalDate.of(2025, 1, 1)));

        assertEquals(List.of("z-usd", "a-usd", "a-gbp"), result.billingRecords().stream()
                .map(LoanBillingRecord::loanId).toList());
        assertEquals(List.of("A/B/GBP", "A/C/USD", "Z/B/USD"),
                result.counterpartySummaries().stream()
                        .map(s -> s.lenderId() + "/" + s.borrowerId() + "/" + s.currency())
                        .toList());
        assertThrows(UnsupportedOperationException.class,
                () -> result.billingRecords().add(result.billingRecords().getFirst()));
        assertThrows(UnsupportedOperationException.class,
                () -> result.counterpartySummaries().add(result.counterpartySummaries().getFirst()));
        assertEquals(3, loans.size());
        assertEquals(3, events.size());
    }

    private static Loan feeLoan(String id, String lender, String borrower, LocalDate open,
            LocalDate termination, String shares, String rate, DayCountFractionEnum basis) {
        return new Loan(id,
                trade(open, termination, shares, CollateralTypeEnum.NON_CASH,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.SHARE, 1),
                lender, borrower, new FeeTerms(bd(rate), basis));
    }

    private static Loan rebateLoan(String id, String lender, String borrower, LocalDate open,
            LocalDate termination, String shares, String cash, String benchmark, String rebate,
            String currency, DayCountFractionEnum basis) {
        return new Loan(id,
                trade(open, termination, shares, CollateralTypeEnum.CASH,
                        AssetPayoutTradeTypeEnum.SECURITY_LENDING, FinancialUnitEnum.SHARE, 1),
                lender, borrower,
                new RebateTerms(money(cash, currency), bd(benchmark), bd(rebate), basis));
    }

    private static TradeState trade(LocalDate open, LocalDate termination, String shares,
            CollateralTypeEnum collateralType, AssetPayoutTradeTypeEnum tradeType,
            FinancialUnitEnum quantityUnit, int assetPayoutCount) {
        AssetPayout assetPayout = AssetPayout.builder()
                .setTradeType(tradeType)
                .setPriceQuantity(ResolvablePriceQuantity.builder()
                        .setResolvedQuantity(Quantity.builder()
                                .setValue(bd(shares))
                                .setUnit(UnitType.builder().setFinancialUnit(quantityUnit).build())
                                .build())
                        .build())
                .build();
        EconomicTerms.EconomicTermsBuilder economics = EconomicTerms.builder()
                .setEffectiveDate(directDate(open))
                .setTerminationDate(directDate(termination))
                .setCollateral(Collateral.builder()
                        .setCollateralProvisions(CollateralProvisions.builder()
                                .setCollateralType(collateralType)
                                .build())
                        .build());
        for (int i = 0; i < assetPayoutCount; i++) {
            economics.addPayout(Payout.builder().setAssetPayout(assetPayout).build());
        }
        return TradeState.builder()
                .setTrade(Trade.builder()
                        .setProduct(NonTransferableProduct.builder()
                                .setEconomicTerms(economics.build())
                                .build())
                        .build())
                .build();
    }

    private static AdjustableOrRelativeDate directDate(LocalDate date) {
        return AdjustableOrRelativeDate.builder()
                .setAdjustableDate(AdjustableDate.builder()
                        .setUnadjustedDate(Date.of(date))
                        .build())
                .build();
    }

    private static TradeState withExtraInterestPayout(TradeState input) {
        EconomicTerms modifiedTerms = input.getTrade().getProduct().getEconomicTerms().toBuilder()
                .addPayout(Payout.builder()
                        .setInterestRatePayout(InterestRatePayout.builder().build())
                        .build())
                .build();
        NonTransferableProduct modifiedProduct = input.getTrade().getProduct().toBuilder()
                .setEconomicTerms(modifiedTerms)
                .build();
        return input.toBuilder()
                .setTrade(input.getTrade().toBuilder().setProduct(modifiedProduct).build())
                .build();
    }

    private static MarketMark mark(String loanId, String date, String value, String currency) {
        return new MarketMark(loanId, LocalDate.parse(date), money(value, currency));
    }

    private static Money money(String value, String currency) {
        return Money.builder()
                .setValue(bd(value))
                .setUnit(UnitType.builder().setCurrencyValue(currency).build())
                .build();
    }

    private static BigDecimal bd(String value) {
        return new BigDecimal(value);
    }

    private static void assertMoney(String value, String currency, Money actual) {
        assertEquals(0, bd(value).compareTo(actual.getValue()), "money value");
        assertEquals(currency, actual.getUnit().getCurrency().getValue(), "money currency");
    }
}
