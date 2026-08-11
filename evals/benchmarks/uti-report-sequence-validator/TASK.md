# UTI report-sequence validator

Implement a compact, production-oriented Java validator for the lifecycle of regulatory reports
for one UTI against FINOS CDM 7.0.0. This is an application-owned reporting state machine inspired
by DRR lifecycle processing. It does not determine a legal reporting obligation, generate a DRR
report, or require a separately licensed DRR runtime.

Provide this exact public API:

```java
package benchmark.reporting;

public final class UtiReportSequenceValidator {
    public enum ReportAction {
        NEW,
        MODIFY,
        CORRECT,
        TERMINATE,
        ERROR,
        REVIVE,
        MARGIN_UPDATE,
        VALUATION,
        POSITION_COMPONENT
    }

    public enum LifecycleState {
        NEVER_EXISTED,
        ALIVE,
        TERMINATED,
        CANCELLED
    }

    public enum RejectionReason {
        NONE,
        MALFORMED_REPORT,
        UTI_MISMATCH,
        FIRST_REPORT_MUST_BE_NEW,
        ACTION_NOT_ALLOWED_IN_STATE
    }

    public record Report(
        cdm.event.common.TradeIdentifier uti,
        ReportAction actionType) {}

    public record ReportDecision(
        Report report,
        boolean accepted,
        LifecycleState resultingState,
        RejectionReason rejectionReason) {}

    public record ValidationResult(
        cdm.event.common.TradeIdentifier uti,
        java.util.List<ReportDecision> decisions,
        LifecycleState finalState) {}

    public static ValidationResult ValidateReportSequence(
        java.util.List<Report> reports);
}
```

The fully qualified entry point is
`benchmark.reporting.UtiReportSequenceValidator.ValidateReportSequence`.

## Typed CDM boundary

Every `Report` carries a real `cdm.event.common.TradeIdentifier`. Accept it as a UTI only when:

- `TradeIdentifier.identifierType` is
  `cdm.base.staticdata.identifier.TradeIdentifierTypeEnum.UNIQUE_TRANSACTION_IDENTIFIER`;
- `TradeIdentifier.assignedIdentifier` contains exactly one non-null
  `cdm.base.staticdata.identifier.AssignedIdentifier`;
- that assigned identifier's `identifier.value` is non-null, non-blank, and already trimmed; and
- an optional assigned-identifier `version`, when present, is positive.

The assigned identifier's string value is the UTI identity for this focused validator. Later
reports may carry a different positive `AssignedIdentifier.version`; compare the UTI value, not
whole-object equality. Preserve the complete `TradeIdentifier` from the first accepted `NEW` in
the `ValidationResult`. Reject a valid but different UTI with `UTI_MISMATCH`, without changing the
anchored UTI or lifecycle state.

`cdm.event.common.ActionEnum` is deliberately **not** the report-action type: in CDM 7.0.0 it only
contains workflow-level `NEW`, `CORRECT`, and `CANCEL`, so it cannot faithfully encode this closed
regulatory-action roster. `ReportAction` is the narrow application-owned boundary. Do not invent
fields in generated CDM classes, edit generated model code, or claim this state machine is a DRR
rule implementation.

The list order is the authoritative report order. Do not sort it or add an unstated timestamp
policy.

## Per-report validation

Start in `NEVER_EXISTED` with no anchored UTI. Return exactly one `ReportDecision` for each input
element, in input order. Accepted transitions are:

| Current state | Action | Resulting state |
|---|---|---|
| `NEVER_EXISTED` | `NEW` | `ALIVE` |
| `ALIVE` | `MODIFY`, `VALUATION`, or `MARGIN_UPDATE` | `ALIVE` |
| `ALIVE` | `POSITION_COMPONENT` | `TERMINATED` |
| `ALIVE` or `TERMINATED` | `CORRECT` | unchanged |
| `ALIVE` | `TERMINATE` | `TERMINATED` |
| any established state (`ALIVE`, `TERMINATED`, or `CANCELLED`) | `ERROR` | `CANCELLED` |
| `TERMINATED` or `CANCELLED` | `REVIVE` | `ALIVE` |

All other state/action pairs are rejected with `ACTION_NOT_ALLOWED_IN_STATE` and leave the state
unchanged. In particular:

- no action other than `NEW` can be accepted while `NEVER_EXISTED`; reject it with
  `FIRST_REPORT_MUST_BE_NEW`;
- a rejected leading action does not poison the sequence, so a later valid `NEW` may establish the
  UTI and create the trade;
- a second `NEW` is rejected rather than resetting history;
- `MODIFY`, `VALUATION`, `MARGIN_UPDATE`, and `POSITION_COMPONENT` all require `ALIVE`;
- `CORRECT` is permitted while `TERMINATED`, because that trade existed, and leaves it terminated;
  it is forbidden while `CANCELLED`, because `ERROR` means the trade should never have been
  reported; and
- `REVIVE` re-opens either a terminated trade or an erroneous/cancelled report. A wrongly matured
  trade belongs to the same closed-but-once-existed `TERMINATED` projection for this deliberately
  four-state API; do not add a fifth public state.

For this focused benchmark, `POSITION_COMPONENT` on an alive UTI closes the individual trade-level
report into the position and therefore produces `TERMINATED`. This is an explicit supplied policy
for the miniature, not a claim that every regime uses that sequence: real position-component
creation, aggregation, and reporting scope require facts not supplied by this API. While
`NEVER_EXISTED`, the `FIRST_REPORT_MUST_BE_NEW` rule still takes precedence; while closed, the
action is rejected with `ACTION_NOT_ALLOWED_IN_STATE`.

An accepted decision has `RejectionReason.NONE`. A rejected decision has the exact non-`NONE`
reason above and reports the unchanged state. Continue evaluating later reports after every
rejection; a rejection is not an exception and is not a stream-level failure.

## Malformed input and immutability

Reject a null `Report`, null action, or malformed UTI as a per-item `MALFORMED_REPORT`; leave the
state and anchored UTI unchanged and continue. If the top-level `reports` list itself is null,
throw `IllegalArgumentException`. An empty list is valid and returns a null result UTI, no
decisions, and `NEVER_EXISTED`.

Return the first accepted `NEW` report's typed UTI even when the final state is `CANCELLED`.
`ValidationResult.decisions` must be a defensive, unmodifiable copy. Do not mutate the input list,
its reports, or any CDM object.

## Required focused tests

Use a well-formed typed CDM UTI throughout each sequence.

1. **Ordinary closure:** `NEW -> MODIFY -> TERMINATE` is accepted throughout and ends
   `TERMINATED`; a following `MODIFY` is rejected and leaves the state `TERMINATED`.
2. **Fat-finger termination:** `NEW -> TERMINATE -> REVIVE -> MODIFY` is accepted throughout.
   Assert that the state immediately after `REVIVE` is `ALIVE`, allowing the final `MODIFY`.
3. **Nothing to resurrect:** a first-ever `REVIVE` is rejected as
   `FIRST_REPORT_MUST_BE_NEW`, remains `NEVER_EXISTED`, and does not stop a later valid `NEW`.
4. **Error is not termination:** for `NEW -> ERROR -> CORRECT`, reject `CORRECT` and leave the
   state `CANCELLED`. Then prove the prescribed `REVIVE -> CORRECT` continuation succeeds. Include
   a close control showing `CORRECT` is accepted after `TERMINATE` but does not reopen the trade.
5. **Action-specific gates:** accept `VALUATION` on an alive trade, terminate it, then reject
   `MARGIN_UPDATE` and leave it terminated.

Also cover a mismatched UTI followed by a valid report for the anchored UTI, malformed entries,
version changes that retain the same UTI value, repeated `NEW`, `POSITION_COMPONENT` gating,
empty input, result immutability, and input preservation. Keep the implementation focused and run
the tests with the available Gradle 8.10 installation using Java 21. The matching CDM 7.0.0 binary
and source JARs are available under `lib/` for offline inspection.
