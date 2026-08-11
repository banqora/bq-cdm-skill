# BDT-style tranche-to-CDM expander

Implement a compact, production-oriented Java expansion boundary for a Bond Data Taxonomy (BDT)
2.0-style issuance message against FINOS CDM 7.0.0. The focused input below represents the
programme/tranche seam; it is not a claim to reproduce the complete ICMA BDT XSD and does not
require a BDT library or network access.

Provide this exact public API:

```java
package benchmark.issuance;

public final class BdtTrancheExpander {
    public enum ValidationCode {
        MALFORMED_MESSAGE,
        MALFORMED_PROGRAMME,
        MALFORMED_TRANCHE,
        AGGREGATE_SIZE_MISMATCH,
        NON_LATER_TAP,
        CONFLICTING_TAP_TERMS
    }

    public record ProgrammeTerms(
        String issuerLei,
        cdm.legaldocumentation.common.GoverningLawEnum governingLaw,
        cdm.base.staticdata.asset.common.CurrencyCodeEnum currency,
        java.math.BigDecimal declaredTotalIssueSize) {}

    public record Tranche(
        String isin,
        java.math.BigDecimal couponRate,
        java.time.LocalDate maturityDate,
        java.math.BigDecimal issueSize,
        java.time.LocalDate issueDate,
        String issuerLeiOverride,
        cdm.legaldocumentation.common.GoverningLawEnum governingLawOverride,
        cdm.base.staticdata.asset.common.CurrencyCodeEnum currencyOverride) {}

    public record BdtMessage(
        ProgrammeTerms programme,
        java.util.List<Tranche> tranches) {}

    public record ExpandedSecurity(
        cdm.base.staticdata.asset.common.Security security,
        String isin,
        String issuerLei,
        cdm.legaldocumentation.common.GoverningLawEnum governingLaw,
        cdm.base.staticdata.asset.common.CurrencyCodeEnum currency,
        java.math.BigDecimal couponRate,
        java.time.LocalDate maturityDate,
        java.math.BigDecimal issueSize,
        java.time.LocalDate originalIssueDate,
        java.time.LocalDate latestIssueDate) {}

    public record ValidationFailure(
        ValidationCode code,
        int trancheIndex,
        String isin,
        String message) {}

    public record ExpansionResult(
        java.util.List<ExpandedSecurity> securities,
        java.util.List<ValidationFailure> failures) {
        public boolean valid() {
            return failures.isEmpty();
        }
    }

    public static ExpansionResult ExpandIssuance(BdtMessage bdtMessage);
}
```

The fully qualified entry point is
`benchmark.issuance.BdtTrancheExpander.ExpandIssuance`.

## Programme inheritance and validation

Resolve each tranche independently. A null override inherits the programme value; a non-null
override replaces it for that tranche only. An override must never modify the programme defaults,
another tranche, or a CDM object already emitted. Preserve input order for the first occurrence of
each ISIN.

For this focused boundary:

- an issuer LEI must already be trimmed and match `[A-Z0-9]{20}`; LEI checksum validation is out of
  scope;
- an ISIN must already be trimmed and match `[A-Z0-9]{12}`; ISIN checksum validation is out of
  scope;
- programme governing law and currency are required;
- declared total and every tranche issue size must be positive;
- coupon rate must be non-negative and is a decimal fraction (`0.05` means 5%);
- issue date and maturity date are required, with issue date strictly before maturity; and
- the message must contain at least one non-null tranche.

A null message, missing programme, null/empty tranche list, or invalid programme field produces at
least one failure with `MALFORMED_MESSAGE` or `MALFORMED_PROGRAMME`. A null or invalid tranche or
override produces `MALFORMED_TRANCHE`. Programme-level failures use `trancheIndex = -1`; row
failures use the zero-based input index. A failure's message must be non-blank.

`declaredTotalIssueSize` is deliberately a source-message completeness checksum: compare it, by
exact decimal numeric value, with the sum of `issueSize` across **every input row**, including tap
rows and rows whose resolved currencies differ. It is not an FX-converted valuation. A mismatch
must produce `AGGREGATE_SIZE_MISMATCH`; never silently expand a partial feed.

Validation is fail-closed. If any validation failure exists, return an empty securities list and
one or more useful failures. Do not throw for data-quality failures described above.

## Tap consolidation

The first occurrence of an ISIN creates one output instrument. A later row with that ISIN is a
fungible re-opening (tap) only when:

- its issue date is strictly later than the latest accepted row for that ISIN; and
- its fully resolved issuer LEI, governing law, currency, coupon rate, and maturity date match the
  existing instrument.

Compare decimal coupon values numerically, so `0.050` and `0.05` are the same term. Issue size and
issue date are not matching terms: add each tap's size exactly, retain the first row's issue date as
`originalIssueDate`, and update `latestIssueDate`. A same-day or earlier duplicate produces
`NON_LATER_TAP`. Any resolved-term mismatch produces `CONFLICTING_TAP_TERMS`. Either failure makes
the entire result invalid and empty; never use last-writer-wins and never emit two securities with
one ISIN.

An explicit override equal to an inherited value is a match. Resolve first, then compare.

## Typed CDM output boundary

Emit one `ExpandedSecurity` per unique ISIN. Its `security` must be a real CDM 7.0.0
`cdm.base.staticdata.asset.common.Security` containing:

- exactly one `AssetIdentifier` with the output ISIN and `AssetIdTypeEnum.ISIN`;
- `AssetTypeEnum.SECURITY` and `SecurityTypeEnum.DEBT`;
- exactly one issuer `Party` containing exactly one LEI `PartyIdentifier`; and
- an `AssetPartyRole` of `ISSUER` whose party reference resolves to that issuer party.

CDM 7.0.0 `Security` is the canonical identifier/classification and issuer representation, but it
does not contain exact leaves for this complete set of issue size, issue date, maturity, coupon,
currency, and governing-law facts. Keep those resolved facts in `ExpandedSecurity`; do not invent
generated-model fields, edit generated CDM code, or force issuance economics into unrelated debt
classification fields. The sidecar is an explicit application boundary, not a substitute security
model.

Use `BigDecimal` throughout without `double` or `float`. Do not mutate inputs or CDM objects.
`ExpansionResult.securities` and `failures` must be defensive, unmodifiable copies, including when
someone directly constructs the public record.

## Required focused tests

1. **Independent inheritance:** expand three unique tranches where only the middle tranche
   overrides GBP with EUR. Assert GBP/EUR/GBP in order and prove the override does not leak into a
   sibling. Also inspect the typed ISIN and issuer on each CDM security.
2. **Aggregate completeness:** make the declared programme total differ from the rows' sum as if a
   tranche was omitted. Assert an invalid, empty result containing
   `AGGREGATE_SIZE_MISMATCH`.
3. **Fungible tap:** add a fourth row with tranche 1's ISIN, matching resolved terms, a later issue
   date, and additional size. Assert only three securities are emitted, tranche 1's size is the
   exact sum, and its original/latest dates are correct.
4. **Conflicting tap:** repeat an ISIN with a different coupon and assert an invalid, empty result
   containing `CONFLICTING_TAP_TERMS`.

Also cover a non-later duplicate, effective-term comparison after inheritance, malformed fields,
deterministic ordering, direct-result immutability, and input preservation. Run the tests with the
available Gradle 8.10 installation using Java 21. Matching CDM 7.0.0 binary and source JARs are
available under `lib/` for offline inspection.
