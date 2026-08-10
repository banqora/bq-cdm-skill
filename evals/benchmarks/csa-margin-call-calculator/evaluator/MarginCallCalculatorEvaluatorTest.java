package benchmark.margin;

import cdm.base.math.RoundingModeEnum;
import cdm.base.math.UnitType;
import cdm.base.staticdata.asset.common.ISOCurrencyCodeEnum;
import cdm.legaldocumentation.csa.CollateralRounding;
import cdm.observable.asset.Money;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;

import static benchmark.margin.MarginCallCalculator.ComputeMarginCall;
import static benchmark.margin.MarginCallCalculator.Direction.DELIVERY;
import static benchmark.margin.MarginCallCalculator.Direction.NONE;
import static benchmark.margin.MarginCallCalculator.Direction.RETURN;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

final class MarginCallCalculatorEvaluatorTest {
    @Test
    void independentAmountIsAddedAfterExposureFloor() {
        var result = ComputeMarginCall(
                gbp("9000000"),
                gbp("0"),
                elections(gbp("10000000"), gbp("500000"), gbp("750000"),
                        "100000", RoundingModeEnum.UP, "100000", RoundingModeEnum.DOWN));

        assertResult(result, DELIVERY, "800000", "GBP");
    }

    @Test
    void mtaEqualityIsActionableForDeliveryAndReturn() {
        var delivery = ComputeMarginCall(
                gbp("10500000"),
                gbp("0"),
                standardElections(gbp("10000000"), gbp("500000"), gbp("0")));
        assertResult(delivery, DELIVERY, "500000", "GBP");

        var returned = ComputeMarginCall(
                gbp("14500000"),
                gbp("5000000"),
                standardElections(gbp("10000000"), gbp("500000"), gbp("0")));
        assertResult(returned, RETURN, "500000", "GBP");
    }

    @Test
    void exactZeroIsNoneEvenWhenMtaIsZero() {
        var result = ComputeMarginCall(
                gbp("10000000"),
                gbp("0"),
                standardElections(gbp("10000000"), gbp("0"), gbp("0")));

        assertResult(result, NONE, "0", "GBP");
    }

    @Test
    void deliveryAndReturnUseTheirOwnIncrementAndDirection() {
        var unusual = elections(
                gbp("10000000"), gbp("0"), gbp("0"),
                "100000", RoundingModeEnum.DOWN,
                "250000", RoundingModeEnum.UP);

        var delivery = ComputeMarginCall(gbp("10251000"), gbp("0"), unusual);
        assertResult(delivery, DELIVERY, "200000", "GBP");

        var returned = ComputeMarginCall(gbp("13249000"), gbp("5000000"), unusual);
        assertResult(returned, RETURN, "2000000", "GBP");
    }

    @Test
    void rejectsMixedCurrencies() {
        var elections = elections(
                gbp("10000000"), gbp("500000"), gbp("0"),
                "100000", RoundingModeEnum.UP, "100000", RoundingModeEnum.DOWN);

        assertThrows(IllegalArgumentException.class,
                () -> ComputeMarginCall(money("12300000", "USD"), gbp("0"), elections));
    }

    @Test
    void rejectsNegativeResolvedAmountsAndNonPositiveIncrements() {
        assertThrows(IllegalArgumentException.class,
                () -> ComputeMarginCall(gbp("12300000"), gbp("-1"),
                        standardElections(gbp("10000000"), gbp("500000"), gbp("0"))));

        assertThrows(IllegalArgumentException.class,
                () -> ComputeMarginCall(gbp("12300000"), gbp("0"),
                        elections(gbp("10000000"), gbp("500000"), gbp("0"),
                                "0", RoundingModeEnum.UP, "100000", RoundingModeEnum.DOWN)));
    }

    @Test
    void rejectsMissingRequiredRoundingCurrency() {
        var incompleteRounding = CollateralRounding.builder()
                .setDeliveryAmount(new BigDecimal("100000"))
                .setDeliveryDirection(RoundingModeEnum.UP)
                .setReturnAmount(new BigDecimal("100000"))
                .setReturnDirection(RoundingModeEnum.DOWN)
                .build();
        var elections = new MarginCallCalculator.CsaElections(
                gbp("10000000"), gbp("500000"), gbp("0"), incompleteRounding);

        assertThrows(RuntimeException.class,
                () -> ComputeMarginCall(gbp("12300000"), gbp("0"), elections));
    }

    @Test
    void rejectsInvalidIncrementEvenWhenTheOtherDirectionIsSelected() {
        var invalidReturn = elections(
                gbp("10000000"), gbp("500000"), gbp("0"),
                "100000", RoundingModeEnum.UP, "0", RoundingModeEnum.DOWN);
        assertThrows(IllegalArgumentException.class,
                () -> ComputeMarginCall(gbp("12300000"), gbp("0"), invalidReturn));

        var invalidDelivery = elections(
                gbp("10000000"), gbp("500000"), gbp("0"),
                "0", RoundingModeEnum.UP, "100000", RoundingModeEnum.DOWN);
        assertThrows(IllegalArgumentException.class,
                () -> ComputeMarginCall(gbp("13270000"), gbp("5000000"), invalidDelivery));
    }

    private static MarginCallCalculator.CsaElections standardElections(
            Money threshold, Money mta, Money independentAmount) {
        return elections(threshold, mta, independentAmount,
                "100000", RoundingModeEnum.UP, "100000", RoundingModeEnum.DOWN);
    }

    private static MarginCallCalculator.CsaElections elections(
            Money threshold,
            Money mta,
            Money independentAmount,
            String deliveryIncrement,
            RoundingModeEnum deliveryDirection,
            String returnIncrement,
            RoundingModeEnum returnDirection) {
        return new MarginCallCalculator.CsaElections(
                threshold,
                mta,
                independentAmount,
                CollateralRounding.builder()
                        .setDeliveryAmount(new BigDecimal(deliveryIncrement))
                        .setDeliveryDirection(deliveryDirection)
                        .setReturnAmount(new BigDecimal(returnIncrement))
                        .setReturnDirection(returnDirection)
                        .setCurrency(ISOCurrencyCodeEnum.GBP)
                        .build());
    }

    private static Money gbp(String value) {
        return money(value, "GBP");
    }

    private static Money money(String value, String currency) {
        return Money.builder()
                .setValue(new BigDecimal(value))
                .setUnit(UnitType.builder().setCurrencyValue(currency).build())
                .build();
    }

    private static void assertResult(
            MarginCallCalculator.MarginCallResult result,
            MarginCallCalculator.Direction direction,
            String amount,
            String currency) {
        assertEquals(direction, result.direction());
        assertEquals(0, new BigDecimal(amount).compareTo(result.amount().getValue()));
        assertEquals(currency, result.amount().getUnit().getCurrency().getValue());
    }
}
