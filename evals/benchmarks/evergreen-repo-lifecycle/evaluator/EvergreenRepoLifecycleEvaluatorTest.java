package benchmark.evergreen;

import benchmark.evergreen.EvergreenRepoLifecycle.BusinessCalendar;
import benchmark.evergreen.EvergreenRepoLifecycle.DayResult;
import benchmark.evergreen.EvergreenRepoLifecycle.EvergreenTradeState;
import benchmark.evergreen.EvergreenRepoLifecycle.LifecycleEvent;
import benchmark.evergreen.EvergreenRepoLifecycle.ReRate;
import benchmark.evergreen.EvergreenRepoLifecycle.SettlementTrigger;
import benchmark.evergreen.EvergreenRepoLifecycle.TerminationNotice;
import cdm.base.datetime.AdjustableDate;
import cdm.base.datetime.AdjustableOrRelativeDate;
import cdm.base.datetime.BusinessDayAdjustments;
import cdm.base.datetime.BusinessDayConventionEnum;
import cdm.base.datetime.DayTypeEnum;
import cdm.base.datetime.PeriodEnum;
import cdm.base.datetime.RelativeDateOffset;
import cdm.base.math.UnitType;
import cdm.event.common.State;
import cdm.event.common.Trade;
import cdm.event.common.TradeState;
import cdm.event.position.PositionStatusEnum;
import cdm.observable.asset.Money;
import cdm.product.template.EconomicTerms;
import cdm.product.template.EvergreenProvision;
import cdm.product.template.NonTransferableProduct;
import cdm.product.template.TerminationProvision;
import com.rosetta.model.lib.records.Date;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import static benchmark.evergreen.EvergreenRepoLifecycle.ProcessDay;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class EvergreenRepoLifecycleEvaluatorTest {
    private static final LocalDate SUMMER_BANK_HOLIDAY = LocalDate.of(2025, 8, 25);
    private static final Set<LocalDate> HOLIDAYS = Set.of(SUMMER_BANK_HOLIDAY);

    @Test
    void readsTenorFromCdmAndPreservesTheTypedTradeState() {
        var original = state(
                LocalDate.of(2025, 8, 21),
                LocalDate.of(2025, 9, 30),
                10,
                "1000000",
                "0.0365",
                "0",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));

        DayResult result = ProcessDay(original, LocalDate.of(2025, 8, 22), List.of());

        assertEquals(LocalDate.of(2025, 9, 8), repurchaseDate(result.tradeState()));
        assertEquals(LocalDate.of(2025, 9, 30), repurchaseDate(original),
                "the immutable input CDM object must remain unchanged");
        assertNotSame(original.tradeState(), result.tradeState().tradeState());
        assertEquals(PositionStatusEnum.EXECUTED,
                result.tradeState().tradeState().getState().getPositionState());
        assertEquals(Boolean.TRUE, economicTerms(result.tradeState()).getNonStandardisedTerms());
        assertEquals(BusinessDayConventionEnum.NONE,
                economicTerms(result.tradeState()).getTerminationDate().getAdjustableDate()
                        .getDateAdjustments().getBusinessDayConvention());
    }

    @Test
    void constantTenorSurvivesWeekendHolidayAndMonthEnd() {
        EvergreenTradeState current = state(
                LocalDate.of(2025, 8, 21),
                LocalDate.of(2025, 10, 1),
                35,
                "1000000",
                "0.0365",
                "0",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));
        LocalDate previousEnd = repurchaseDate(current);

        for (LocalDate date = LocalDate.of(2025, 8, 22);
             !date.isAfter(LocalDate.of(2025, 9, 2));
             date = date.plusDays(1)) {
            current = ProcessDay(current, date, List.of()).tradeState();
            LocalDate end = repurchaseDate(current);

            assertEquals(35, businessDaysBetween(date, end, HOLIDAYS),
                    "constant tenor failed on " + date);
            if (isBusinessDay(date, HOLIDAYS)) {
                assertEquals(addBusinessDays(date, 35, HOLIDAYS), end);
            } else {
                assertEquals(previousEnd, end,
                        "a weekend or holiday must not crawl on " + date);
            }
            previousEnd = end;
        }
    }

    @Test
    void noticeFreezesAndLcrFirstEntersThirtyCalendarDaysOnAugustTwentieth() {
        EvergreenTradeState current = state(
                LocalDate.of(2025, 7, 30),
                LocalDate.of(2025, 9, 1),
                35,
                "1000000",
                "0.0365",
                "0",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));

        current = ProcessDay(current, LocalDate.of(2025, 7, 31),
                List.of(new TerminationNotice("Party A"))).tradeState();
        LocalDate locked = LocalDate.of(2025, 9, 19);
        assertEquals(locked, repurchaseDate(current));
        assertEquals(35, businessDaysBetween(LocalDate.of(2025, 7, 31), locked, HOLIDAYS));

        for (LocalDate date = LocalDate.of(2025, 8, 1);
             !date.isAfter(LocalDate.of(2025, 8, 20));
             date = date.plusDays(1)) {
            current = ProcessDay(current, date, List.of()).tradeState();
            assertEquals(locked, repurchaseDate(current), "crawl continued after notice on " + date);
            long lcrDays = ChronoUnit.DAYS.between(date, locked);
            if (date.isBefore(LocalDate.of(2025, 8, 20))) {
                assertTrue(lcrDays > 30, "entered the LCR horizon too early on " + date);
            } else {
                assertEquals(30, lcrDays);
            }
        }
    }

    @Test
    void rerateAndMonthEndSettleExactlyOnceAtOldRateThenStartFreshBucket() {
        EvergreenTradeState current = state(
                LocalDate.of(2025, 7, 27),
                LocalDate.of(2025, 9, 30),
                35,
                "1000000",
                "0.0365",
                "0",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));

        for (LocalDate date = LocalDate.of(2025, 7, 28);
             !date.isAfter(LocalDate.of(2025, 8, 3));
             date = date.plusDays(1)) {
            DayResult day = ProcessDay(current, date, List.of());
            assertTrue(day.interestSettlements().isEmpty());
            current = day.tradeState();
        }
        assertAmount("700", current.accruedInterest());

        DayResult collision = ProcessDay(current, LocalDate.of(2025, 8, 4),
                List.of(new ReRate(new BigDecimal("0.0730"))));

        assertEquals(1, collision.interestSettlements().size());
        var payment = collision.interestSettlements().getFirst();
        assertMoney("700.00", "GBP", payment.amount());
        assertEquals(Set.of(SettlementTrigger.RERATE, SettlementTrigger.MONTH_END), payment.triggers());
        assertAmount("0.0730", collision.tradeState().annualRate());
        assertAmount("200", collision.tradeState().accruedInterest());
        assertFalse(collision.tradeState().terminated());
    }

    @Test
    void simpleAccrualUsesPrincipalOnEveryCalendarDayWithoutCompounding() {
        EvergreenTradeState current = state(
                LocalDate.of(2025, 8, 21),
                LocalDate.of(2025, 10, 1),
                35,
                "1000000",
                "0.0365",
                "50",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));

        for (LocalDate date = LocalDate.of(2025, 8, 22);
             !date.isAfter(LocalDate.of(2025, 8, 25));
             date = date.plusDays(1)) {
            current = ProcessDay(current, date, List.of()).tradeState();
        }

        assertAmount("450", current.accruedInterest());
        assertAmount("1000000", current.principal().getValue());
        assertAmount("0.0365", current.annualRate());
    }

    @Test
    void standaloneMonthEndAndFinalRepurchaseHaveDistinctFreshBucketSemantics() {
        EvergreenTradeState monthly = state(
                LocalDate.of(2025, 7, 27),
                LocalDate.of(2025, 9, 30),
                35,
                "1000000",
                "0.0365",
                "0",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));
        for (LocalDate date = LocalDate.of(2025, 7, 28);
             !date.isAfter(LocalDate.of(2025, 8, 3));
             date = date.plusDays(1)) {
            monthly = ProcessDay(monthly, date, List.of()).tradeState();
        }
        DayResult monthEnd = ProcessDay(monthly, LocalDate.of(2025, 8, 4), List.of());
        assertEquals(1, monthEnd.interestSettlements().size());
        assertEquals(Set.of(SettlementTrigger.MONTH_END),
                monthEnd.interestSettlements().getFirst().triggers());
        assertMoney("700.00", "GBP", monthEnd.interestSettlements().getFirst().amount());
        assertAmount("100", monthEnd.tradeState().accruedInterest());

        EvergreenTradeState finalDay = state(
                LocalDate.of(2025, 7, 31),
                LocalDate.of(2025, 8, 1),
                35,
                "1000000",
                "0.0365",
                "500",
                LocalDate.of(2025, 6, 13),
                false,
                new BusinessCalendar(HOLIDAYS));
        DayResult closed = ProcessDay(finalDay, LocalDate.of(2025, 8, 1), List.of());
        assertEquals(1, closed.interestSettlements().size());
        assertEquals(Set.of(SettlementTrigger.FINAL_REPURCHASE),
                closed.interestSettlements().getFirst().triggers());
        assertMoney("500.00", "GBP", closed.interestSettlements().getFirst().amount());
        assertAmount("0", closed.tradeState().accruedInterest());
        assertTrue(closed.tradeState().terminated());
        assertThrows(RuntimeException.class,
                () -> ProcessDay(closed.tradeState(), LocalDate.of(2025, 8, 2), List.of()));
    }

    @Test
    void eventOrderIsIrrelevantAndMalformedTransitionsFailClosed() {
        EvergreenTradeState first = state(
                LocalDate.of(2025, 7, 30),
                LocalDate.of(2025, 9, 1),
                35,
                "1000000",
                "0.0365",
                "300",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));
        EvergreenTradeState second = state(
                LocalDate.of(2025, 7, 30),
                LocalDate.of(2025, 9, 1),
                35,
                "1000000",
                "0.0365",
                "300",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));
        var notice = new TerminationNotice("Party B");
        var rerate = new ReRate(new BigDecimal("0.0730"));

        DayResult noticeFirst = ProcessDay(first, LocalDate.of(2025, 7, 31), List.of(notice, rerate));
        DayResult rerateFirst = ProcessDay(second, LocalDate.of(2025, 7, 31), List.of(rerate, notice));
        assertEquals(repurchaseDate(noticeFirst.tradeState()), repurchaseDate(rerateFirst.tradeState()));
        assertAmount(noticeFirst.tradeState().annualRate().toPlainString(),
                rerateFirst.tradeState().annualRate());
        assertAmount(noticeFirst.tradeState().accruedInterest().toPlainString(),
                rerateFirst.tradeState().accruedInterest());
        assertMoney("300.00", "GBP", noticeFirst.interestSettlements().getFirst().amount());

        assertThrows(RuntimeException.class,
                () -> ProcessDay(first, LocalDate.of(2025, 8, 1), List.of()));
        assertThrows(RuntimeException.class,
                () -> ProcessDay(first, LocalDate.of(2025, 7, 31),
                        List.of(rerate, new ReRate(BigDecimal.ONE))));

        EvergreenTradeState holidayNotice = state(
                LocalDate.of(2025, 8, 24),
                LocalDate.of(2025, 10, 1),
                35,
                "1000000",
                "0.0365",
                "0",
                null,
                false,
                new BusinessCalendar(HOLIDAYS));
        assertThrows(RuntimeException.class,
                () -> ProcessDay(holidayNotice, SUMMER_BANK_HOLIDAY,
                        List.of(new TerminationNotice("Party A"))));
    }

    @Test
    void calendarAndInputCollectionsCannotBeChangedBehindTheStateMachine() {
        Set<LocalDate> mutableHolidays = new HashSet<>();
        mutableHolidays.add(SUMMER_BANK_HOLIDAY);
        BusinessCalendar calendar = new BusinessCalendar(mutableHolidays);
        EvergreenTradeState current = state(
                LocalDate.of(2025, 8, 21),
                LocalDate.of(2025, 10, 1),
                35,
                "1000000",
                "0.0365",
                "0",
                null,
                false,
                calendar);
        mutableHolidays.clear();
        List<LifecycleEvent> events = new ArrayList<>();

        DayResult result = ProcessDay(current, LocalDate.of(2025, 8, 22), events);

        assertEquals(LocalDate.of(2025, 10, 13), repurchaseDate(result.tradeState()));
        assertTrue(events.isEmpty());
        assertTrue(result.interestSettlements().isEmpty());
    }

    private static EvergreenTradeState state(
            LocalDate lastProcessed,
            LocalDate termination,
            int tenor,
            String principal,
            String rate,
            String accrued,
            LocalDate noticeDate,
            boolean terminated,
            BusinessCalendar calendar) {
        return new EvergreenTradeState(
                cdmTradeState(termination, tenor),
                money(principal, "GBP"),
                new BigDecimal(rate),
                new BigDecimal(accrued),
                lastProcessed,
                noticeDate,
                calendar,
                terminated);
    }

    private static TradeState cdmTradeState(LocalDate termination, int tenor) {
        var noticePeriod = RelativeDateOffset.builder()
                .setPeriodMultiplier(tenor)
                .setPeriod(PeriodEnum.D)
                .setDayType(DayTypeEnum.BUSINESS)
                .setBusinessDayConvention(BusinessDayConventionEnum.NONE)
                .build();
        var evergreen = EvergreenProvision.builder()
                .setNoticePeriod(noticePeriod)
                .build();
        var terminationDate = AdjustableOrRelativeDate.builder()
                .setAdjustableDate(AdjustableDate.builder()
                        .setUnadjustedDate(toCdmDate(termination))
                        .setDateAdjustments(BusinessDayAdjustments.builder()
                                .setBusinessDayConvention(BusinessDayConventionEnum.NONE)
                                .build())
                        .build())
                .build();
        var terms = EconomicTerms.builder()
                .setTerminationDate(terminationDate)
                .setTerminationProvision(TerminationProvision.builder()
                        .setEvergreenProvision(evergreen)
                        .build())
                .setNonStandardisedTerms(true)
                .build();

        return TradeState.builder()
                .setTrade(Trade.builder()
                        .setProduct(NonTransferableProduct.builder()
                                .setEconomicTerms(terms)
                                .build())
                        .build())
                .setState(State.builder()
                        .setPositionState(PositionStatusEnum.EXECUTED)
                        .build())
                .build();
    }

    private static EconomicTerms economicTerms(EvergreenTradeState state) {
        return state.tradeState().getTrade().getProduct().getEconomicTerms();
    }

    private static LocalDate repurchaseDate(EvergreenTradeState state) {
        Date date = economicTerms(state).getTerminationDate().getAdjustableDate().getUnadjustedDate();
        return LocalDate.of(date.getYear(), date.getMonth(), date.getDay());
    }

    private static Date toCdmDate(LocalDate date) {
        return Date.of(date.getYear(), date.getMonthValue(), date.getDayOfMonth());
    }

    private static Money money(String value, String currency) {
        return Money.builder()
                .setValue(new BigDecimal(value))
                .setUnit(UnitType.builder().setCurrencyValue(currency).build())
                .build();
    }

    private static boolean isBusinessDay(LocalDate date, Set<LocalDate> holidays) {
        return date.getDayOfWeek() != DayOfWeek.SATURDAY
                && date.getDayOfWeek() != DayOfWeek.SUNDAY
                && !holidays.contains(date);
    }

    private static LocalDate addBusinessDays(LocalDate date, int days, Set<LocalDate> holidays) {
        LocalDate result = date;
        int remaining = days;
        while (remaining > 0) {
            result = result.plusDays(1);
            if (isBusinessDay(result, holidays)) {
                remaining--;
            }
        }
        return result;
    }

    private static int businessDaysBetween(LocalDate start, LocalDate end, Set<LocalDate> holidays) {
        int count = 0;
        for (LocalDate date = start.plusDays(1); !date.isAfter(end); date = date.plusDays(1)) {
            if (isBusinessDay(date, holidays)) {
                count++;
            }
        }
        return count;
    }

    private static void assertMoney(String expected, String currency, Money actual) {
        assertAmount(expected, actual.getValue());
        assertEquals(currency, actual.getUnit().getCurrency().getValue());
    }

    private static void assertAmount(String expected, BigDecimal actual) {
        assertEquals(0, new BigDecimal(expected).compareTo(actual));
    }
}
