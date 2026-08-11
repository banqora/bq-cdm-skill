# Settlement-status reconciliation forward candidate

Implement a production-oriented Java 21 component against FINOS CDM 7.0.0 with this caller-visible
operation:

```text
ReconcileSettlementStatus(book, update)
```

The application receives asynchronous settlement updates for trades already represented by genuine
generated CDM `TradeState` values. Design the application-owned book entry, update, result, and audit
types needed around that CDM boundary. Do not edit generated classes or invent generated fields.

Each book entry has a stable external trade identifier and one settlement status:
`AWAITING_MATCH`, `MATCHED`, `SETTLED`, or `FAILED`. An update has a stable event identifier, target
trade identifier, effective timestamp, resulting status, and optional failure reason. Accept these
transitions:

- `AWAITING_MATCH` to `MATCHED` or `FAILED`;
- `MATCHED` to `SETTLED` or `FAILED`;
- `FAILED` to `MATCHED` when a later operational repair is confirmed.

`SETTLED` is terminal. Identical replay of an accepted event returns the existing result without a
second audit entry. Reuse of an event identifier with different content is an error. Reject a
back-dated update relative to the selected entry's accepted history, an unknown or duplicated trade
identifier, an unsupported transition, and a failure without a non-blank reason. No partial update
may escape on rejection.

The operation returns a new book snapshot and at most one new application audit entry. It must be
safe for callers to retain both the old and new snapshots and their exposed collections. Operational
settlement status is not itself a contractual termination instruction: reaching `SETTLED` or
`FAILED` must not silently terminate the CDM trade or change its economics.

Write focused tests covering:

1. A three-entry same-counterparty book where one target advances from `AWAITING_MATCH` to `MATCHED`;
   only that entry and the one audit line change.
2. Identical replay produces no second line, while conflicting reuse of the same event ID fails.
3. A failed entry can be repaired to `MATCHED`, but a settled entry rejects every later transition.
4. A rejected back-dated or invalid update leaves both the original snapshot and every entry
   unchanged.

Use exact timestamps supplied by the caller and deterministic value semantics. Add a concise
`DESIGN.md` explaining the selected CDM boundary, which facts remain application-owned, what
generated validation was actually executed, identity/replay semantics, and how collection ownership
is enforced. Work offline with the pinned CDM 7.0.0 binary and generated-source JARs in `lib/`; run
the complete suite with Gradle 8.10 and Java 21.
