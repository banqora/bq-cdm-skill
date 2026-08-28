# FpML ingestion fidelity audit

Implement a compact, production-oriented Java auditor that decides whether a claimed CDM
ingestion output faithfully preserves the business content of an FpML confirmation, against
FINOS CDM 7.0.0. The auditor is application-owned: it does not modify generated CDM code and it
does not re-implement or re-run the shipped ingestion pipeline. Its purpose is to catch mapping
regressions that count-based expectation tests cannot see — an output that still has the same
number of populated paths and validation failures, while a mapped value is wrong, missing, or
fabricated.

Provide this exact public API:

```java
package benchmark.fpml;

public final class FpmlMappingAuditor {

    public enum AuditFact {
        NOTIONAL_AMOUNT,
        NOTIONAL_CURRENCY,
        FIXED_RATE,
        EFFECTIVE_DATE,
        TERMINATION_DATE,
        FIXED_LEG_PAYER,
        FLOATING_RATE_INDEX,
        FLOATING_SPREAD,
        FIXED_LEG_DAY_COUNT
    }

    public enum Verdict {
        PRESERVED,
        ALTERED,
        DROPPED,
        INVENTED,
        UNAUDITABLE
    }

    public record Finding(
        AuditFact fact,
        Verdict verdict,
        String sourceEvidence,
        String outputEvidence,
        String detail) {}

    public record AuditResult(
        String sampleId,
        java.util.List<Finding> findings,
        boolean pass) {}

    public static AuditResult AuditTradeState(
        String sampleId,
        java.nio.file.Path fpmlDocument,
        java.nio.file.Path claimedCdmJson);
}
```

The fully qualified entry point is `benchmark.fpml.FpmlMappingAuditor.AuditTradeState`.

## Scope and samples

The audited instrument is a single-currency fixed/float interest rate swap confirmation. The
CDM 7.0.0 binary and source JARs under `lib/` embed the shipped ingestion corpus: FpML inputs
under `ingest/input/fpml-5-10-products-rates/`, expected typed outputs under
`ingest/output/fpml-confirmation-to-trade-state/fpml-5-10-products-rates/`, and the pairing
manifest `ingest/config/test-pack-translate-fpml-confirmation-to-trade-state-fpml-5-10-products-rates.json`.
Select at least three vanilla fixed/float single-currency swap pairs from that pack for the
faithful baseline; extract copies into the project and doctor only copies, never originals.

## Audit contract

Return exactly one `Finding` per `AuditFact`, in enum declaration order. For each fact, the
source side is the FpML document and the output side is the typed CDM object:

- `NOTIONAL_AMOUNT` and `NOTIONAL_CURRENCY`: the swap's initial notional amount and its
  currency. When both legs state a notional, the legs must agree with each other and with the
  output; a leg disagreement the output silently resolves is `ALTERED`.
- `FIXED_RATE`: the fixed leg's initial rate. FpML states it as a decimal fraction. Establish
  the CDM side's declared basis from the version-matched model source, convert exactly, and
  treat any residual — including a value one hundred times the source — as `ALTERED`.
- `EFFECTIVE_DATE` and `TERMINATION_DATE`: the swap's unadjusted effective and termination
  dates.
- `FIXED_LEG_PAYER`: the party that pays the fixed leg, resolved to a party identity within
  each document. Raw reference strings are not identity: resolve the FpML party reference to
  its party, resolve the CDM counterparty route to its party, and compare identities.
- `FLOATING_RATE_INDEX`: the floating leg's rate index designation.
- `FLOATING_SPREAD`: the floating leg's initial spread. Absent, zero, and empty are three
  distinct statements: a source spread of zero that the output omits is `DROPPED`; an output
  spread the source never states is `INVENTED`; source and output both absent is `PRESERVED`.
- `FIXED_LEG_DAY_COUNT`: the fixed leg's day count fraction.

Verdicts per fact: `PRESERVED` when the output states the same fact under each side's declared
basis and lexical rules; `ALTERED` when both sides state the fact and they differ; `DROPPED`
when the source states the fact and the output does not; `INVENTED` when the output states a
fact the source does not. Use exact decimal comparison for every numeric fact; binary floating
point comparison is not acceptable evidence.

`pass` is true only when every finding is `PRESERVED`. Populate `sourceEvidence` and
`outputEvidence` with the values actually compared, or state absence explicitly.

## Typed boundary and dialect handling

Deserialize the claimed output as typed `cdm.event.common.TradeState` using the JSON dialect
the document's own markers declare. Before auditing, assert the intended root type and a
conservative content floor. If the document cannot be read into a `TradeState` that passes that
floor — wrong dialect, wrong root, or a hollow object from a lenient mapper — return every
finding as `UNAUDITABLE` with `pass` false. A hollow read must never be reported as a set of
`DROPPED` facts: "the auditor could not see the output" and "the mapping lost the content" are
different statements.

Compare typed content, not raw JSON text. Representation differences with equal semantics —
element order, resolved versus referenced party representation of the same identity, canonical
decimal forms — are `PRESERVED`.

Reject a null `sampleId` or null path with `IllegalArgumentException`. An unreadable or
malformed input file yields the all-`UNAUDITABLE` result rather than an exception.
`AuditResult.findings` must be a defensive, unmodifiable copy; do not mutate the input files or
any CDM object.

## Required focused tests

1. **Faithful baseline:** at least three unmodified shipped pairs audit as all-`PRESERVED` with
   `pass` true.
2. **Rate basis:** a doctored output with the fixed rate multiplied by one hundred yields
   `FIXED_RATE` `ALTERED`. Include a rate whose binary floating point representation would
   falsely equal the source to prove exact decimal comparison.
3. **Silent drop:** a doctored output that omits a spread the source states as zero yields
   `FLOATING_SPREAD` `DROPPED`; a close control where the source genuinely states no spread and
   the output has none stays `PRESERVED`.
4. **Invention:** a doctored output stating a spread the source never states yields
   `FLOATING_SPREAD` `INVENTED`.
5. **Direction:** a doctored output with the fixed leg's payer and receiver swapped yields
   `FIXED_LEG_PAYER` `ALTERED`; a close control that re-represents the same party graph
   differently stays `PRESERVED`.
6. **Hollow read:** an output document doctored so a lenient or wrong-dialect read would return
   a shallow object yields the all-`UNAUDITABLE` result, never `DROPPED` findings.

Also cover result immutability, input preservation, and the null-argument contract. Keep the
implementation focused and run the tests with the available Gradle 8.10 installation using
Java 21. The matching CDM 7.0.0 binary and source JARs are available under `lib/` for offline
inspection.
