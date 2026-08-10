package benchmark.reporting;

import benchmark.reporting.UtiReportSequenceValidator.LifecycleState;
import benchmark.reporting.UtiReportSequenceValidator.Report;
import benchmark.reporting.UtiReportSequenceValidator.ReportAction;
import benchmark.reporting.UtiReportSequenceValidator.ReportDecision;
import benchmark.reporting.UtiReportSequenceValidator.RejectionReason;
import benchmark.reporting.UtiReportSequenceValidator.ValidationResult;
import cdm.base.staticdata.identifier.AssignedIdentifier;
import cdm.base.staticdata.identifier.TradeIdentifierTypeEnum;
import cdm.event.common.TradeIdentifier;
import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static benchmark.reporting.UtiReportSequenceValidator.ValidateReportSequence;
import static benchmark.reporting.UtiReportSequenceValidator.LifecycleState.ALIVE;
import static benchmark.reporting.UtiReportSequenceValidator.LifecycleState.CANCELLED;
import static benchmark.reporting.UtiReportSequenceValidator.LifecycleState.NEVER_EXISTED;
import static benchmark.reporting.UtiReportSequenceValidator.LifecycleState.TERMINATED;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.CORRECT;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.ERROR;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.MARGIN_UPDATE;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.MODIFY;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.NEW;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.POSITION_COMPONENT;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.REVIVE;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.TERMINATE;
import static benchmark.reporting.UtiReportSequenceValidator.ReportAction.VALUATION;
import static benchmark.reporting.UtiReportSequenceValidator.RejectionReason.ACTION_NOT_ALLOWED_IN_STATE;
import static benchmark.reporting.UtiReportSequenceValidator.RejectionReason.FIRST_REPORT_MUST_BE_NEW;
import static benchmark.reporting.UtiReportSequenceValidator.RejectionReason.MALFORMED_REPORT;
import static benchmark.reporting.UtiReportSequenceValidator.RejectionReason.NONE;
import static benchmark.reporting.UtiReportSequenceValidator.RejectionReason.UTI_MISMATCH;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class UtiReportSequenceValidatorEvaluatorTest {
    private static final String UTI_A = "54930084UKLVMY22DS16-UTI-000000000000000000000001";
    private static final String UTI_B = "54930084UKLVMY22DS16-UTI-000000000000000000000002";

    @Test
    void ordinaryClosureRejectsADeadTradeModification() {
        TradeIdentifier uti = uti(UTI_A, 1);

        ValidationResult result = ValidateReportSequence(reports(uti,
                NEW, MODIFY, TERMINATE, MODIFY));

        assertSequence(result,
                accepted(ALIVE),
                accepted(ALIVE),
                accepted(TERMINATED),
                rejected(TERMINATED, ACTION_NOT_ALLOWED_IN_STATE));
        assertEquals(TERMINATED, result.finalState());
        assertEquals(uti, result.uti());
    }

    @Test
    void reviveAfterFatFingerTerminationReopensBeforeModify() {
        ValidationResult result = ValidateReportSequence(reports(uti(UTI_A, 1),
                NEW, TERMINATE, REVIVE, MODIFY));

        assertSequence(result,
                accepted(ALIVE),
                accepted(TERMINATED),
                accepted(ALIVE),
                accepted(ALIVE));
        assertEquals(ALIVE, result.decisions().get(2).resultingState(),
                "REVIVE must reopen before the following report is evaluated");
    }

    @Test
    void leadingReviveIsRejectedButDoesNotPoisonALaterNew() {
        TradeIdentifier uti = uti(UTI_A, 1);

        ValidationResult result = ValidateReportSequence(List.of(
                new Report(uti, REVIVE),
                new Report(uti, NEW),
                new Report(uti, MODIFY)));

        assertSequence(result,
                rejected(NEVER_EXISTED, FIRST_REPORT_MUST_BE_NEW),
                accepted(ALIVE),
                accepted(ALIVE));
        assertEquals(uti, result.uti());
    }

    @Test
    void errorMeansCorrectMustWaitForRevive() {
        ValidationResult result = ValidateReportSequence(reports(uti(UTI_A, 1),
                NEW, ERROR, CORRECT, REVIVE, CORRECT));

        assertSequence(result,
                accepted(ALIVE),
                accepted(CANCELLED),
                rejected(CANCELLED, ACTION_NOT_ALLOWED_IN_STATE),
                accepted(ALIVE),
                accepted(ALIVE));
    }

    @Test
    void correctAfterTerminationIsValidButDoesNotReopenTheTrade() {
        ValidationResult result = ValidateReportSequence(reports(uti(UTI_A, 1),
                NEW, TERMINATE, CORRECT, MODIFY));

        assertSequence(result,
                accepted(ALIVE),
                accepted(TERMINATED),
                accepted(TERMINATED),
                rejected(TERMINATED, ACTION_NOT_ALLOWED_IN_STATE));
    }

    @Test
    void valuationAndMarginUpdateUseTheAliveGateIndependently() {
        ValidationResult result = ValidateReportSequence(reports(uti(UTI_A, 1),
                NEW, VALUATION, TERMINATE, MARGIN_UPDATE));

        assertSequence(result,
                accepted(ALIVE),
                accepted(ALIVE),
                accepted(TERMINATED),
                rejected(TERMINATED, ACTION_NOT_ALLOWED_IN_STATE));
    }

    @Test
    void positionComponentUsesTheExplicitFocusedAlivePolicy() {
        ValidationResult result = ValidateReportSequence(reports(uti(UTI_A, 1),
                NEW, POSITION_COMPONENT, TERMINATE, POSITION_COMPONENT));

        assertSequence(result,
                accepted(ALIVE),
                accepted(ALIVE),
                accepted(TERMINATED),
                rejected(TERMINATED, ACTION_NOT_ALLOWED_IN_STATE));

        ValidationResult first = ValidateReportSequence(List.of(
                new Report(uti(UTI_A, 1), POSITION_COMPONENT)));
        assertSequence(first, rejected(NEVER_EXISTED, FIRST_REPORT_MUST_BE_NEW));
    }

    @Test
    void errorWorksFromEveryEstablishedStateAndRemainsDistinct() {
        ValidationResult result = ValidateReportSequence(reports(uti(UTI_A, 1),
                NEW, TERMINATE, ERROR, ERROR, REVIVE));

        assertSequence(result,
                accepted(ALIVE),
                accepted(TERMINATED),
                accepted(CANCELLED),
                accepted(CANCELLED),
                accepted(ALIVE));
    }

    @Test
    void sameUtiVersionChangeIsAcceptedButMismatchIsRejectedAndProcessingContinues() {
        TradeIdentifier first = uti(UTI_A, 1);
        TradeIdentifier other = uti(UTI_B, 1);
        TradeIdentifier laterVersion = uti(UTI_A, 2);
        List<Report> input = List.of(
                new Report(first, NEW),
                new Report(other, MODIFY),
                new Report(laterVersion, MODIFY));

        ValidationResult result = ValidateReportSequence(input);

        assertSequence(result,
                accepted(ALIVE),
                rejected(ALIVE, UTI_MISMATCH),
                accepted(ALIVE));
        assertEquals(first, result.uti(), "the first accepted NEW must remain the result UTI");
        assertEquals(Integer.valueOf(1),
                result.uti().getAssignedIdentifier().getFirst().getVersion());
    }

    @Test
    void repeatedNewAndReviveWhileAliveCannotResetHistory() {
        ValidationResult result = ValidateReportSequence(reports(uti(UTI_A, 1),
                NEW, NEW, REVIVE, MODIFY));

        assertSequence(result,
                accepted(ALIVE),
                rejected(ALIVE, ACTION_NOT_ALLOWED_IN_STATE),
                rejected(ALIVE, ACTION_NOT_ALLOWED_IN_STATE),
                accepted(ALIVE));
    }

    @Test
    void malformedReportsAreRejectedIndividuallyBeforeAValidNew() {
        TradeIdentifier wrongType = TradeIdentifier.builder()
                .setIdentifierType(TradeIdentifierTypeEnum.UNIQUE_SWAP_IDENTIFIER)
                .addAssignedIdentifier(assigned(UTI_A, 1))
                .build();
        TradeIdentifier blank = TradeIdentifier.builder()
                .setIdentifierType(TradeIdentifierTypeEnum.UNIQUE_TRANSACTION_IDENTIFIER)
                .addAssignedIdentifier(assigned("   ", 1))
                .build();
        TradeIdentifier padded = TradeIdentifier.builder()
                .setIdentifierType(TradeIdentifierTypeEnum.UNIQUE_TRANSACTION_IDENTIFIER)
                .addAssignedIdentifier(assigned(" " + UTI_A, 1))
                .build();
        TradeIdentifier multiple = TradeIdentifier.builder()
                .setIdentifierType(TradeIdentifierTypeEnum.UNIQUE_TRANSACTION_IDENTIFIER)
                .addAssignedIdentifier(assigned(UTI_A, 1))
                .addAssignedIdentifier(assigned(UTI_B, 1))
                .build();
        TradeIdentifier badVersion = uti(UTI_A, 0);
        TradeIdentifier valid = uti(UTI_A, 1);
        List<Report> input = Arrays.asList(
                null,
                new Report(null, NEW),
                new Report(wrongType, NEW),
                new Report(blank, NEW),
                new Report(padded, NEW),
                new Report(multiple, NEW),
                new Report(badVersion, NEW),
                new Report(valid, null),
                new Report(valid, NEW),
                new Report(valid, MODIFY));

        ValidationResult result = ValidateReportSequence(input);

        assertEquals(input.size(), result.decisions().size());
        for (int index = 0; index < 8; index++) {
            assertDecision(result.decisions().get(index), false, NEVER_EXISTED, MALFORMED_REPORT);
        }
        assertDecision(result.decisions().get(8), true, ALIVE, NONE);
        assertDecision(result.decisions().get(9), true, ALIVE, NONE);
        assertEquals(valid, result.uti());
    }

    @Test
    void malformedOrMismatchedItemsDoNotAlterAnEstablishedState() {
        TradeIdentifier valid = uti(UTI_A, 1);
        List<Report> input = Arrays.asList(
                new Report(valid, NEW),
                null,
                new Report(uti(UTI_B, 1), TERMINATE),
                new Report(valid, VALUATION));

        ValidationResult result = ValidateReportSequence(input);

        assertSequence(result,
                accepted(ALIVE),
                rejected(ALIVE, MALFORMED_REPORT),
                rejected(ALIVE, UTI_MISMATCH),
                accepted(ALIVE));
        assertEquals(valid, result.uti());
    }

    @Test
    void emptyAndNullTopLevelInputsHaveExplicitBehavior() {
        ValidationResult empty = ValidateReportSequence(List.of());

        assertNull(empty.uti());
        assertNotNull(empty.decisions());
        assertTrue(empty.decisions().isEmpty());
        assertEquals(NEVER_EXISTED, empty.finalState());
        assertThrows(IllegalArgumentException.class, () -> ValidateReportSequence(null));
    }

    @Test
    void outputIsDefensiveUnmodifiableAndInputIsPreserved() {
        TradeIdentifier typedUti = uti(UTI_A, 1);
        Report first = new Report(typedUti, NEW);
        ArrayList<Report> input = new ArrayList<>(List.of(first));
        List<Report> before = List.copyOf(input);

        ValidationResult result = ValidateReportSequence(input);

        assertEquals(before, input, "validation must not mutate caller input");
        assertEquals(typedUti, first.uti(), "validation must not rewrite the CDM value");
        input.add(new Report(typedUti, TERMINATE));
        assertEquals(1, result.decisions().size(), "result must not alias the caller list");
        assertThrows(UnsupportedOperationException.class,
                () -> result.decisions().add(result.decisions().getFirst()));
    }

    private static List<Report> reports(TradeIdentifier uti, ReportAction... actions) {
        return Arrays.stream(actions).map(action -> new Report(uti, action)).toList();
    }

    private static TradeIdentifier uti(String value, Integer version) {
        return TradeIdentifier.builder()
                .setIdentifierType(TradeIdentifierTypeEnum.UNIQUE_TRANSACTION_IDENTIFIER)
                .setIssuerValue("LEI:54930084UKLVMY22DS16")
                .addAssignedIdentifier(assigned(value, version))
                .build();
    }

    private static AssignedIdentifier assigned(String value, Integer version) {
        return AssignedIdentifier.builder()
                .setIdentifierValue(value)
                .setVersion(version)
                .build();
    }

    private static ExpectedDecision accepted(LifecycleState state) {
        return new ExpectedDecision(true, state, NONE);
    }

    private static ExpectedDecision rejected(LifecycleState state, RejectionReason reason) {
        return new ExpectedDecision(false, state, reason);
    }

    private static void assertSequence(ValidationResult result, ExpectedDecision... expected) {
        assertNotNull(result);
        assertNotNull(result.decisions());
        assertEquals(expected.length, result.decisions().size());
        for (int index = 0; index < expected.length; index++) {
            ExpectedDecision item = expected[index];
            assertDecision(result.decisions().get(index),
                    item.accepted(), item.state(), item.reason());
        }
        LifecycleState expectedFinal = expected.length == 0
                ? NEVER_EXISTED
                : expected[expected.length - 1].state();
        assertEquals(expectedFinal, result.finalState());
    }

    private static void assertDecision(
            ReportDecision actual,
            boolean accepted,
            LifecycleState state,
            RejectionReason reason) {
        assertNotNull(actual);
        assertEquals(accepted, actual.accepted());
        assertEquals(state, actual.resultingState());
        assertEquals(reason, actual.rejectionReason());
        if (accepted) {
            assertTrue(actual.accepted());
            assertEquals(NONE, actual.rejectionReason());
        } else {
            assertFalse(actual.accepted());
            assertFalse(actual.rejectionReason() == NONE);
        }
    }

    private record ExpectedDecision(
            boolean accepted,
            LifecycleState state,
            RejectionReason reason) {}
}
