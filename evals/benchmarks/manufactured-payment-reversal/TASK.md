# Manufactured-payment reversal discovery benchmark

Implement a production-oriented manufactured-payment engine in Java 21 against FINOS CDM 7.0.0.
The engine has two caller-visible operations:

- `ProcessCorporateAction(loanPositions, caEvent)`
- `ProcessReversal(originalEvent, correctedEvent)`

Design an appropriate public input, result, and processing-state API around those operations. Use
genuine generated CDM 7.0.0 objects at a defensible input or output boundary, while keeping facts
that the model does not own in an explicit application layer. Do not edit generated CDM classes or
invent fields on them.

When a dividend record date falls while securities are on loan, the borrower owes the lender a
manufactured payment:

```text
record-date loan quantity * dividend rate per security * all-in payout ratio
```

The all-in ratio is a decimal fraction: 85% is `0.85`. Use exact decimal arithmetic. Entitlement is
always based on the position at the corporate action's record date, not the position when the event
is processed or later corrected.

The issuer may subsequently reverse or correct the corporate action. Emit only the net adjustment
needed to move from the amount already processed for the original event to the corrected
entitlement. Processing is exactly once: replaying the same original event or correction must not
emit another transfer, and a correction must have an unambiguous relationship to the event it
changes. Make the state needed to support replay safety and auditability explicit and suitable for
persistence; do not hide correctness in static process memory.

Implement these focused tests:

1. **Baseline.** 100,000 shares are on loan over the record date. A EUR 0.50 dividend with an
   all-in ratio of 0.85 produces EUR 42,500 from borrower to lender.
2. **Rate correction and replay.** Correct EUR 0.50 to EUR 0.45. Emit one EUR 4,250 adjustment from
   lender to borrower. Replaying the same correction emits nothing.
3. **Record-date snapshot.** After the original payment, 60,000 shares are returned. The correction
   still uses the original 100,000-share entitlement rather than the current 40,000 shares.
4. **Negative-flow integrity.** Expose the adjustment as negative from the lender's perspective and
   preserve the matching lender-to-borrower direction. Do not floor it, clamp it, take its absolute
   value as the signed result, or silently swap direction without retaining the economic sign.

Choose reasonable validation and failure semantics for malformed events, unknown originals,
currency or security mismatches, duplicate identities, and missing record-date history. Do not
mutate caller input, CDM objects, event values, or previously returned results. Add focused tests for
the four required cases and any close negative controls needed to defend your design.

Add a short `DESIGN.md` explaining:

- the chosen CDM 7.0.0 paths and transfer representation;
- the application-owned event identity, entitlement snapshot, and replay ledger;
- how signed application amounts relate to CDM transfer quantity and payer/receiver direction; and
- which validation tier was actually executed rather than merely assumed.

The workspace contains the pinned CDM 7.0.0 binary and source JARs under `lib/`. Work offline, keep
the existing dependency declaration unless it is genuinely broken, and run the complete suite with
Gradle 8.10 and Java 21. The HMRC and SCoRE references motivate the supplied rules but are not an
invitation to perform external legal research; treat the rules above as the focused contract.
