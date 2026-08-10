# Evergreen repo lifecycle engine

Implement a compact, production-oriented Java state machine for a crawling evergreen repo against
FINOS CDM 7.0.0. This is application-owned temporal orchestration over typed CDM economic terms;
it does not need to emit a CDM `BusinessEvent` or make a deliberately partial trade fixture fully
qualify.

Provide this exact public API:

```java
package benchmark.evergreen;

public final class EvergreenRepoLifecycle {
    public enum SettlementTrigger { FINAL_REPURCHASE, RERATE, MONTH_END }

    public sealed interface LifecycleEvent permits TerminationNotice, ReRate {}
    public record TerminationNotice(String servingParty) implements LifecycleEvent {}
    public record ReRate(BigDecimal newAnnualRate) implements LifecycleEvent {}

    public record BusinessCalendar(Set<LocalDate> holidays) {}

    public record EvergreenTradeState(
        cdm.event.common.TradeState tradeState,
        Money principal,
        BigDecimal annualRate,
        BigDecimal accruedInterest,
        LocalDate lastProcessedDate,
        LocalDate noticeDate,
        BusinessCalendar calendar,
        boolean terminated) {}

    public record InterestSettlement(
        LocalDate settlementDate,
        Money amount,
        Set<SettlementTrigger> triggers) {}

    public record DayResult(
        EvergreenTradeState tradeState,
        List<InterestSettlement> interestSettlements) {}

    public static DayResult ProcessDay(
        EvergreenTradeState tradeState,
        LocalDate date,
        List<? extends LifecycleEvent> events);
}
```

`Money` is `cdm.observable.asset.Money`. The fully qualified entry point is
`benchmark.evergreen.EvergreenRepoLifecycle.ProcessDay`.

## Typed CDM boundary

Read the current repurchase date from this exact CDM path:

```text
TradeState.trade.product.economicTerms.terminationDate.adjustableDate.unadjustedDate
```

Read the evergreen tenor from:

```text
economicTerms.terminationProvision.evergreenProvision.noticePeriod
```

The supported notice period has a positive `periodMultiplier`, `PeriodEnum.D`, and
`DayTypeEnum.BUSINESS`. Do not hard-code 35: the main fixtures use 35 business days, while callers
may supply another positive business-day tenor. Reject missing paths, relative or adjusted-only
termination-date choices, and unsupported notice-period units/day types clearly.

When the repurchase date changes, return a newly built CDM `TradeState` with only that unadjusted
termination-date leaf changed. Preserve the rest of the product, trade, state, histories, and
metadata, and do not mutate any input. The notice date, accrued bucket, application calendar, and
processing cursor deliberately remain in `EvergreenTradeState`; do not invent generated CDM fields
for them or wire a full lifecycle runtime.

`principal` and `annualRate` are likewise the authoritative, already-resolved application facts for
this focused engine. Do not search for or rewrite a second rate or principal inside trade lots or
payout references when processing a re-rate; the returned record carries the new resolved rate.

`BusinessCalendar.holidays` is the deterministic application-supplied holiday data. A business day
is Monday through Friday excluding that set. Copy or otherwise protect the supplied set from later
caller mutation. CDM business-centre codes alone are not a holiday-data service for this task.

## Day processing and crawl

`ProcessDay` is called once for every **calendar day**, including weekends and holidays. Require
`date == lastProcessedDate.plusDays(1)` so no accrual day can be silently skipped or processed
twice.

- Before notice, on every business day set the repurchase date to `date + tenor business days`.
  On non-business days leave it unchanged. The number of business days strictly after `date` up to
  and including the repurchase date therefore remains exactly the tenor throughout the crawl.
- A valid `TerminationNotice` must be served on a business day. On notice day D, set `noticeDate`
  and lock the repurchase date at `D + tenor business days`. Every later call must leave that CDM
  date unchanged while residual maturity decays.
- Either party may serve notice; require only a non-blank `servingParty` at this application
  boundary. Reject a second notice, duplicate event types on one date, unknown/null events, and all
  processing after final termination. Event-list order must not change the result.

Count contractual business-day tenor by excluding the starting date and including the resulting
business date. Keep the regulatory LCR horizon separate: for the LCR property, residual maturity is
the **calendar-day** count `ChronoUnit.DAYS.between(date, repurchaseDate)`. Before notice a crawling
35-business-day repo must remain outside the `<= 30` calendar-day horizon. After notice, its locked
date eventually enters that horizon even though its contractual business-day count is different.

## Accrual and interest settlement

Accrue one calendar day's simple interest on every successful non-final call, including weekends
and holidays, always against the original principal—not principal plus accrued interest:

```text
dailyInterest = principal.value * annualRate / 365
```

`annualRate` is a non-negative decimal fraction such as `0.0365`. Use `BigDecimal` throughout,
divide to scale 18 with `HALF_EVEN`, and retain that precision in the accrued bucket. When a
settlement is emitted, round its `Money` value to two decimal places with `HALF_EVEN` and preserve
the principal currency. Never pass through `double` or `float`.

`accruedInterest` in the incoming state contains interest through `lastProcessedDate`. Determine
the day's triggers before adding the current day's accrual. Settle and reset that incoming bucket
when any of these triggers occurs:

1. the current date is the locked final repurchase date;
2. a `ReRate` event occurs; or
3. the current date is the second business day strictly after the preceding calendar month-end.

All triggers on the same date are atomic: emit at most one `InterestSettlement`, containing the
union of its `SettlementTrigger` reasons, and reset the bucket exactly once. Only after that
settlement apply a re-rate's non-negative `newAnnualRate`. If the date is not the final repurchase
date, accrue the current calendar day into the fresh bucket at the resulting rate; with no trigger,
simply add the current day's accrual to the existing bucket. The final repurchase date is the
accrual end and is exclusive: settle the bucket through the prior day, mark the state terminated,
and do not add final-day interest. This ordering pays all pre-collision accrual once at the old rate
and starts fresh accrual at the new rate on the collision date.
Emit the single trigger record even when the incoming accrued bucket happens to be zero.

## Required focused tests

Use a calendar whose holiday set includes Monday 25 August 2025 and a 35-business-day CDM notice
period.

1. **Constant-tenor invariant:** process successive calendar dates across the holiday and the
   31 August month-end. Before notice, assert residual maturity is exactly 35 business days on
   every date; business days crawl and non-business dates do not move the repurchase date.
2. **LCR property and freeze:** serve notice on Thursday 31 July 2025. With the 25 August holiday,
   the CDM repurchase date must lock at Friday 19 September 2025 and never move again. Its LCR
   calendar-day residual is 31 on Tuesday 19 August and first equals 30 on Wednesday 20 August.
   Also assert the distinct contractual business-day residual is 35 on notice day.
3. **Coincident triggers:** with GBP 1m principal, a 3.65% rate, no opening accrual, and processing
   beginning on Monday 28 July, place a re-rate to 7.30% on Monday 4 August 2025—the second business
   day after Thursday month-end. Seven old-rate accrual days through 3 August total GBP 700.00.
   Assert exactly one settlement for GBP 700.00 with both `RERATE` and `MONTH_END`, the new rate,
   and a fresh GBP 200.00 accrued bucket for 4 August. This must not become a GBP 900 payment, two
   payments, or a zero fresh bucket.

Reject null/incomplete state, a non-positive principal, negative rates or accrued interest,
non-sequential dates, invalid calendars, and malformed events with clear exceptions. Keep the
implementation focused and run the tests with the available Gradle 8.10 installation using Java
21. The matching CDM 7.0.0 binary and source JARs are available under `lib/` for offline inspection.
