package benchmark.issuance;

import benchmark.issuance.BdtTrancheExpander.BdtMessage;
import benchmark.issuance.BdtTrancheExpander.ExpandedSecurity;
import benchmark.issuance.BdtTrancheExpander.ExpansionResult;
import benchmark.issuance.BdtTrancheExpander.ProgrammeTerms;
import benchmark.issuance.BdtTrancheExpander.Tranche;
import benchmark.issuance.BdtTrancheExpander.ValidationCode;
import benchmark.issuance.BdtTrancheExpander.ValidationFailure;
import cdm.base.staticdata.asset.common.AssetIdTypeEnum;
import cdm.base.staticdata.asset.common.AssetIdentifier;
import cdm.base.staticdata.asset.common.AssetTypeEnum;
import cdm.base.staticdata.asset.common.CurrencyCodeEnum;
import cdm.base.staticdata.asset.common.Security;
import cdm.base.staticdata.asset.common.SecurityTypeEnum;
import cdm.base.staticdata.party.AssetPartyRoleEnum;
import cdm.base.staticdata.party.Party;
import cdm.base.staticdata.party.PartyIdentifier;
import cdm.base.staticdata.party.PartyIdentifierTypeEnum;
import cdm.legaldocumentation.common.GoverningLawEnum;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static benchmark.issuance.BdtTrancheExpander.ExpandIssuance;
import static benchmark.issuance.BdtTrancheExpander.ValidationCode.AGGREGATE_SIZE_MISMATCH;
import static benchmark.issuance.BdtTrancheExpander.ValidationCode.CONFLICTING_TAP_TERMS;
import static benchmark.issuance.BdtTrancheExpander.ValidationCode.MALFORMED_MESSAGE;
import static benchmark.issuance.BdtTrancheExpander.ValidationCode.MALFORMED_PROGRAMME;
import static benchmark.issuance.BdtTrancheExpander.ValidationCode.MALFORMED_TRANCHE;
import static benchmark.issuance.BdtTrancheExpander.ValidationCode.NON_LATER_TAP;
import static cdm.base.staticdata.asset.common.CurrencyCodeEnum.EUR;
import static cdm.base.staticdata.asset.common.CurrencyCodeEnum.GBP;
import static cdm.base.staticdata.asset.common.CurrencyCodeEnum.USD;
import static cdm.legaldocumentation.common.GoverningLawEnum.GBEN;
import static cdm.legaldocumentation.common.GoverningLawEnum.USNY;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNotSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

final class BdtTrancheExpanderEvaluatorTest {
    private static final String ISSUER_A = "54930084UKLVMY22DS16";
    private static final String ISSUER_B = "213800D1EI4B9WTWWD28";
    private static final String ISIN_1 = "GB00AAA00001";
    private static final String ISIN_2 = "GB00AAA00002";
    private static final String ISIN_3 = "GB00AAA00003";

    @Test
    void inheritanceIsIndependentAndCurrencyOverrideDoesNotLeakSideways() {
        List<Tranche> rows = List.of(
                tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)),
                tranche(ISIN_2, "0.04", "200", date(2026, 1, 11),
                        null, null, EUR),
                tranche(ISIN_3, "0.03", "300", date(2026, 1, 12)));

        ExpansionResult result = ExpandIssuance(message("600", rows));

        assertValid(result, 3);
        assertEquals(List.of(ISIN_1, ISIN_2, ISIN_3),
                result.securities().stream().map(ExpandedSecurity::isin).toList());
        assertEquals(List.of(GBP, EUR, GBP),
                result.securities().stream().map(ExpandedSecurity::currency).toList());
        assertEquals(List.of(ISSUER_A, ISSUER_A, ISSUER_A),
                result.securities().stream().map(ExpandedSecurity::issuerLei).toList());
        assertEquals(List.of(GBEN, GBEN, GBEN),
                result.securities().stream().map(ExpandedSecurity::governingLaw).toList());
        assertNotSame(result.securities().get(0).security(), result.securities().get(1).security());
        assertNotSame(result.securities().get(1).security(), result.securities().get(2).security());
        result.securities().forEach(this::assertCdmSecurity);
    }

    @Test
    void issuerAndLawOverridesAreAlsoLocalToOneRow() {
        List<Tranche> rows = List.of(
                tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)),
                tranche(ISIN_2, "0.04", "100", date(2026, 1, 11),
                        ISSUER_B, USNY, null),
                tranche(ISIN_3, "0.03", "100", date(2026, 1, 12)));

        ExpansionResult result = ExpandIssuance(message("300", rows));

        assertValid(result, 3);
        assertEquals(List.of(ISSUER_A, ISSUER_B, ISSUER_A),
                result.securities().stream().map(ExpandedSecurity::issuerLei).toList());
        assertEquals(List.of(GBEN, USNY, GBEN),
                result.securities().stream().map(ExpandedSecurity::governingLaw).toList());
        result.securities().forEach(this::assertCdmSecurity);
    }

    @Test
    void declaredTotalMismatchRejectsTheWholePartialFeed() {
        ExpansionResult result = ExpandIssuance(message("600", List.of(
                tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)),
                tranche(ISIN_2, "0.04", "200", date(2026, 1, 11)))));

        assertInvalid(result, AGGREGATE_SIZE_MISMATCH);
        ValidationFailure failure = firstFailure(result, AGGREGATE_SIZE_MISMATCH);
        assertEquals(-1, failure.trancheIndex());
    }

    @Test
    void declaredTotalIsNumericScaleInsensitiveAndIncludesMixedCurrencyRows() {
        ExpansionResult result = ExpandIssuance(message("300.0000", List.of(
                tranche(ISIN_1, "0.05", "100.0", date(2026, 1, 10)),
                tranche(ISIN_2, "0.04", "200.00", date(2026, 1, 11),
                        null, null, EUR))));

        assertValid(result, 2);
        assertEquals(List.of(GBP, EUR),
                result.securities().stream().map(ExpandedSecurity::currency).toList());
    }

    @Test
    void laterMatchingTapMergesByIsinAndPreservesFirstOccurrenceOrder() {
        Tranche first = tranche(ISIN_2, "0.04", "100", date(2026, 1, 10));
        Tranche other = tranche(ISIN_1, "0.05", "200", date(2026, 1, 11));
        Tranche tap = tranche(ISIN_2, "0.0400", "50.25", date(2026, 2, 10),
                ISSUER_A, GBEN, GBP);

        ExpansionResult result = ExpandIssuance(message("350.25", List.of(first, other, tap)));

        assertValid(result, 2);
        assertEquals(List.of(ISIN_2, ISIN_1),
                result.securities().stream().map(ExpandedSecurity::isin).toList());
        ExpandedSecurity merged = result.securities().get(0);
        assertDecimal("150.25", merged.issueSize());
        assertEquals(first.issueDate(), merged.originalIssueDate());
        assertEquals(tap.issueDate(), merged.latestIssueDate());
        assertDecimal("0.04", merged.couponRate());
        assertCdmSecurity(merged);
    }

    @Test
    void explicitOverridesEqualToInheritedTermsRemainFungible() {
        Tranche first = tranche(ISIN_1, "0.05", "100", date(2026, 1, 10));
        Tranche tap = tranche(ISIN_1, "0.0500", "25", date(2026, 3, 10),
                ISSUER_A, GBEN, GBP);

        ExpansionResult result = ExpandIssuance(message("125.000", List.of(first, tap)));

        assertValid(result, 1);
        assertDecimal("125", result.securities().getFirst().issueSize());
    }

    @Test
    void couponConflictRejectsLoudlyRatherThanLastWriterWins() {
        ExpansionResult result = conflictingTap(
                tranche(ISIN_1, "0.051", "50", date(2026, 2, 10)));

        assertInvalid(result, CONFLICTING_TAP_TERMS);
        assertEquals(1, firstFailure(result, CONFLICTING_TAP_TERMS).trancheIndex());
    }

    @Test
    void everyResolvedFungibilityTermIsCompared() {
        List<Tranche> conflicts = List.of(
                tranche(ISIN_1, "0.05", "50", date(2026, 2, 10), ISSUER_B, null, null),
                tranche(ISIN_1, "0.05", "50", date(2026, 2, 10), null, USNY, null),
                tranche(ISIN_1, "0.05", "50", date(2026, 2, 10), null, null, USD),
                new Tranche(ISIN_1, decimal("0.05"), date(2031, 1, 1), decimal("50"),
                        date(2026, 2, 10), null, null, null));

        for (Tranche conflict : conflicts) {
            assertInvalid(conflictingTap(conflict), CONFLICTING_TAP_TERMS);
        }
    }

    @Test
    void sameDayAndEarlierDuplicatesAreNotTaps() {
        Tranche first = tranche(ISIN_1, "0.05", "100", date(2026, 2, 10));
        for (LocalDate duplicateDate : List.of(date(2026, 2, 10), date(2026, 2, 9))) {
            Tranche duplicate = tranche(ISIN_1, "0.05", "50", duplicateDate);
            ExpansionResult result = ExpandIssuance(message("150", List.of(first, duplicate)));
            assertInvalid(result, NON_LATER_TAP);
            assertEquals(1, firstFailure(result, NON_LATER_TAP).trancheIndex());
        }
    }

    @Test
    void emittedSecurityUsesTheExactCdmIdentityAndIssuerTopology() {
        ExpansionResult result = ExpandIssuance(message("100", List.of(
                tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)))));

        assertValid(result, 1);
        ExpandedSecurity output = result.securities().getFirst();
        assertCdmSecurity(output);
        assertEquals(GBEN, output.governingLaw());
        assertEquals(GBP, output.currency());
        assertDecimal("0.05", output.couponRate());
        assertEquals(date(2030, 1, 1), output.maturityDate());
    }

    @Test
    void malformedTopLevelAndProgrammeDataReturnFailuresInsteadOfThrowing() {
        List<BdtMessage> malformed = Arrays.asList(
                null,
                new BdtMessage(null, List.of()),
                new BdtMessage(programme("100"), null),
                new BdtMessage(programme("100"), List.of()),
                new BdtMessage(new ProgrammeTerms("bad", GBEN, GBP, decimal("100")),
                        List.of(tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)))),
                new BdtMessage(new ProgrammeTerms(ISSUER_A, null, GBP, decimal("100")),
                        List.of(tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)))),
                new BdtMessage(new ProgrammeTerms(ISSUER_A, GBEN, null, decimal("100")),
                        List.of(tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)))),
                new BdtMessage(new ProgrammeTerms(ISSUER_A, GBEN, GBP, BigDecimal.ZERO),
                        List.of(tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)))));

        for (int index = 0; index < malformed.size(); index++) {
            ExpansionResult result = ExpandIssuance(malformed.get(index));
            assertFalse(result.valid(), "malformed case " + index);
            assertTrue(result.securities().isEmpty(), "malformed case " + index);
            assertTrue(result.failures().stream().anyMatch(failure ->
                            failure.code() == MALFORMED_MESSAGE
                                    || failure.code() == MALFORMED_PROGRAMME),
                    "malformed case " + index + " should identify message/programme scope");
            assertUsefulFailures(result);
        }
    }

    @Test
    void malformedRowsAndOverridesAreIndexedAndFailClosed() {
        List<Tranche> malformed = Arrays.asList(
                null,
                tranche(" bad ", "0.05", "100", date(2026, 1, 10)),
                tranche(ISIN_1, "-0.01", "100", date(2026, 1, 10)),
                tranche(ISIN_1, "0.05", "0", date(2026, 1, 10)),
                new Tranche(ISIN_1, decimal("0.05"), date(2026, 1, 10), decimal("100"),
                        date(2026, 1, 10), null, null, null),
                tranche(ISIN_1, "0.05", "100", date(2026, 1, 10), " bad ", null, null));

        for (int index = 0; index < malformed.size(); index++) {
            ExpansionResult result = ExpandIssuance(message("100",
                    Arrays.asList(malformed.get(index))));
            assertInvalid(result, MALFORMED_TRANCHE);
            assertEquals(0, firstFailure(result, MALFORMED_TRANCHE).trancheIndex());
        }
    }

    @Test
    void resultListsAreDefensiveUnmodifiableEvenUnderDirectConstruction() {
        ExpandedSecurity output = ExpandIssuance(message("100", List.of(
                tranche(ISIN_1, "0.05", "100", date(2026, 1, 10)))))
                .securities().getFirst();
        ValidationFailure failure = new ValidationFailure(
                MALFORMED_MESSAGE, -1, null, "test failure");
        ArrayList<ExpandedSecurity> sourceSecurities = new ArrayList<>(List.of(output));
        ArrayList<ValidationFailure> sourceFailures = new ArrayList<>(List.of(failure));

        ExpansionResult direct = new ExpansionResult(sourceSecurities, sourceFailures);
        sourceSecurities.clear();
        sourceFailures.clear();

        assertEquals(1, direct.securities().size(), "constructor must defensively copy securities");
        assertEquals(1, direct.failures().size(), "constructor must defensively copy failures");
        assertFalse(direct.valid());
        assertThrows(UnsupportedOperationException.class,
                () -> direct.securities().add(output));
        assertThrows(UnsupportedOperationException.class,
                () -> direct.failures().add(failure));
    }

    @Test
    void expansionPreservesCallerListAndProgrammeDefaults() {
        ProgrammeTerms programme = programme("300");
        Tranche first = tranche(ISIN_1, "0.05", "100", date(2026, 1, 10));
        Tranche override = tranche(ISIN_2, "0.04", "200", date(2026, 1, 11),
                ISSUER_B, USNY, EUR);
        ArrayList<Tranche> rows = new ArrayList<>(List.of(first, override));
        List<Tranche> before = List.copyOf(rows);
        BdtMessage message = new BdtMessage(programme, rows);

        ExpansionResult result = ExpandIssuance(message);

        assertValid(result, 2);
        assertEquals(before, rows);
        assertEquals(ISSUER_A, programme.issuerLei());
        assertEquals(GBEN, programme.governingLaw());
        assertEquals(GBP, programme.currency());
        rows.clear();
        assertEquals(2, result.securities().size(), "output must not alias the tranche list");
    }

    private ExpansionResult conflictingTap(Tranche second) {
        Tranche first = tranche(ISIN_1, "0.05", "100", date(2026, 1, 10));
        return ExpandIssuance(message("150", List.of(first, second)));
    }

    private void assertCdmSecurity(ExpandedSecurity expanded) {
        Security security = expanded.security();
        assertNotNull(security);
        assertEquals(AssetTypeEnum.SECURITY, security.getAssetType());
        assertEquals(SecurityTypeEnum.DEBT, security.getSecurityType());
        assertEquals(1, security.getIdentifier().size());
        AssetIdentifier identifier = security.getIdentifier().getFirst();
        assertEquals(AssetIdTypeEnum.ISIN, identifier.getIdentifierType());
        assertNotNull(identifier.getIdentifier());
        assertEquals(expanded.isin(), identifier.getIdentifier().getValue());

        assertEquals(1, security.getParty().size());
        Party issuer = security.getParty().getFirst();
        assertEquals(1, issuer.getPartyId().size());
        PartyIdentifier lei = issuer.getPartyId().getFirst();
        assertEquals(PartyIdentifierTypeEnum.LEI, lei.getIdentifierType());
        assertNotNull(lei.getIdentifier());
        assertEquals(expanded.issuerLei(), lei.getIdentifier().getValue());

        assertNotNull(security.getPartyRole());
        assertEquals(AssetPartyRoleEnum.ISSUER, security.getPartyRole().getRole());
        assertNotNull(security.getPartyRole().getPartyReference());
        assertEquals(issuer, security.getPartyRole().getPartyReference().getValue());
    }

    private static ProgrammeTerms programme(String total) {
        return new ProgrammeTerms(ISSUER_A, GBEN, GBP, decimal(total));
    }

    private static BdtMessage message(String total, List<Tranche> tranches) {
        return new BdtMessage(programme(total), tranches);
    }

    private static Tranche tranche(
            String isin,
            String coupon,
            String size,
            LocalDate issueDate) {
        return tranche(isin, coupon, size, issueDate, null, null, null);
    }

    private static Tranche tranche(
            String isin,
            String coupon,
            String size,
            LocalDate issueDate,
            String issuerOverride,
            GoverningLawEnum lawOverride,
            CurrencyCodeEnum currencyOverride) {
        return new Tranche(
                isin,
                decimal(coupon),
                date(2030, 1, 1),
                decimal(size),
                issueDate,
                issuerOverride,
                lawOverride,
                currencyOverride);
    }

    private static BigDecimal decimal(String value) {
        return new BigDecimal(value);
    }

    private static LocalDate date(int year, int month, int day) {
        return LocalDate.of(year, month, day);
    }

    private static void assertValid(ExpansionResult result, int count) {
        assertNotNull(result);
        assertNotNull(result.securities());
        assertNotNull(result.failures());
        assertTrue(result.valid(), () -> "expected valid result but got " + result.failures());
        assertTrue(result.failures().isEmpty());
        assertEquals(count, result.securities().size());
    }

    private static void assertInvalid(ExpansionResult result, ValidationCode code) {
        assertNotNull(result);
        assertNotNull(result.securities());
        assertNotNull(result.failures());
        assertFalse(result.valid());
        assertTrue(result.securities().isEmpty(), "invalid expansion must fail closed");
        assertTrue(result.failures().stream().anyMatch(failure -> failure.code() == code),
                () -> "missing " + code + " in " + result.failures());
        assertUsefulFailures(result);
    }

    private static ValidationFailure firstFailure(ExpansionResult result, ValidationCode code) {
        return result.failures().stream()
                .filter(failure -> failure.code() == code)
                .findFirst()
                .orElseThrow();
    }

    private static void assertUsefulFailures(ExpansionResult result) {
        for (ValidationFailure failure : result.failures()) {
            assertNotNull(failure);
            assertNotNull(failure.code());
            assertNotNull(failure.message());
            assertFalse(failure.message().isBlank());
        }
    }

    private static void assertDecimal(String expected, BigDecimal actual) {
        assertNotNull(actual);
        assertEquals(0, new BigDecimal(expected).compareTo(actual),
                () -> "expected " + expected + " but got " + actual);
    }
}
