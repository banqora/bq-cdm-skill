# CSA margin-call calculator

Implement a compact, production-oriented Java margin-call calculator against FINOS CDM 7.0.0.
This is an application-owned calculation whose executable parameters come from resolved CSA
elections.

Provide this exact public API:

```java
package benchmark.margin;

public final class MarginCallCalculator {
    public enum Direction { DELIVERY, RETURN, NONE }

    public record CsaElections(
        Money threshold,
        Money minimumTransferAmount,
        Money independentAmount,
        CollateralRounding rounding) {}

    public record MarginCallResult(Direction direction, Money amount) {}

    public static MarginCallResult ComputeMarginCall(
        Money exposure,
        Money postedCollateral,
        CsaElections csaElections);
}
```

The fully qualified entry point is
`benchmark.margin.MarginCallCalculator.ComputeMarginCall`.

`Money` is `cdm.observable.asset.Money`; `CollateralRounding` is the CDM CSA type. Every input is
in one base currency. The three `Money` values in `CsaElections` are the fixed, party-resolved
threshold, minimum transfer amount (MTA), and independent amount. Selecting a party-specific,
ratings-based, or infinity election from a complete agreement is deliberately outside this small
calculator's boundary.

Calculate, exactly with `BigDecimal`:

```text
creditSupportAmount = max(0, exposure - threshold) + independentAmount
delta = creditSupportAmount - postedCollateral
```

- If `delta` is zero, return `NONE` and zero.
- If `abs(delta) < MTA`, suppress the transfer and return `NONE` and zero. Equality with MTA is
  actionable.
- A positive delta is a `DELIVERY`; round its non-negative magnitude to the integral multiple in
  `CollateralRounding.deliveryAmount`, using `deliveryDirection`.
- A negative delta is a `RETURN`; round its absolute magnitude to the integral multiple in
  `CollateralRounding.returnAmount`, using `returnDirection`.

The result amount is always a non-negative `Money` magnitude in the input base currency; direction
carries the sign. Standard test elections use `UP` for delivery and `DOWN` for return—the legal
asymmetry must not be collapsed into one generic `round()` operation. Use the respective delivery
and return election fields even when their increments differ.

Add focused tests for:

1. Exposure GBP 12.3m, threshold GBP 10m, posted zero, IA zero, MTA GBP 500k, and GBP 100k rounding
   (`UP` delivery / `DOWN` return): `DELIVERY` GBP 2.3m.
2. Exposure GBP 10.4m with the same threshold, posted and elections: raw delta GBP 400k is strictly
   below MTA, so return `NONE` and zero—not a GBP 400k demand.
3. Exposure GBP 13.27m, threshold GBP 10m, posted GBP 5m, IA zero, MTA GBP 500k, and GBP 100k
   rounding: credit support is GBP 3.27m, so return GBP 1.73m and round **down** to a `RETURN` of
   GBP 1.7m. Explicitly prove this is not a delivery and not a GBP 1.8m over-return.

Reject null/incomplete inputs, mixed currencies, negative posted collateral or election amounts,
and non-positive rounding increments with clear exceptions. Do not mutate the CDM inputs. Do not
pass through `double` or edit generated model code.

Use `org.finos.cdm:cdm-java:7.0.0`, already declared in the build. The matching binary and source
JARs are available under `lib/` for offline inspection. Ground CDM getters/builders and rounding
semantics in the exact 7.0.0 Rune source or generated API. Keep the implementation compact and run
the focused tests with the available Gradle 8+ installation using Java 21.
