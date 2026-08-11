# CDM implementation patterns

Load only the card matching the failure risk. Treat each as a reusable proof pattern, not a
business recipe; confirm the active CDM release and the consuming application's contract first.

## PAT-001: Declare a complete or deliberately partial boundary

**Use when:** Accepting or emitting generated CDM objects at an application boundary.
**Avoid when:** Keeping all data in application types and making no CDM validity, qualification, or interoperability claim.
**Authority:** Use the active [FINOS CDM source](https://github.com/finos/common-domain-model), generated artefact, and caller contract; follow [Rosetta and generated code](rosetta.md) and [testing](testing.md).
**Pattern:** Declare the boundary before coding. Populate and recursively validate a complete root; otherwise expose the narrowest labelled partial fixture, validate every complete node relied on, and never claim whole-root validity.
**Proof:** Compile a populated vertical slice; assert a distinctive typed leaf and run one passing validation plus one close negative against the declared tier.
**Wrong turns:** Reject these:
- Add empty generated children or invented economics merely to satisfy parent cardinality.
- Treat “uses a generated type” or an empty builder's result as proof of a valid CDM document.
**Upgrade tripwire:** On every CDM release or generated-artefact change, re-query root inheritance, choices, cardinalities, and conditions, then rerun the focused probe.

## PAT-002: Validate every populated node through real wiring

**Use when:** Claiming generated validation, qualification, or function behavior for a populated object graph.
**Avoid when:** Testing application-owned arithmetic or selection that makes no generated-runtime claim; do not add dependency injection as ceremony.
**Authority:** Follow FINOS [Rune data validation](https://rune.finos.org/docs/modelling-components/data-validation/), the active generated metadata/runtime, [Rosetta wiring](rosetta.md), and [runtime tests](testing.md#test-functions-through-real-wiring).
**Pattern:** Walk each populated generated object once by identity; execute its structural, type-format, and registered/inherited rules. Obtain dependency-bearing validators and functions through production-equivalent wiring and smoke-test that wiring first.
**Proof:** Assert the visited type/validator set, validate a known-good graph, and prove that a deliberately invalid populated child or choice fails specifically.
**Wrong turns:** Reject these:
- Run only the root validator even though child conditions are non-recursive.
- Catch injection exceptions, string-match failure text, or infer requiredness from Java annotations.
**Upgrade tripwire:** When the CDM/Rune runtime, generated metadata, or injection module version changes, inspect registrations and rerun positive, negative, and child-choice probes.

## PAT-003: Resolve identity, own collections, and constrain scope

**Use when:** Matching references across roots, retaining caller collections, or changing one selected trade, leg, event, or instruction.
**Avoid when:** Identity is genuinely local to one root and never crosses its boundary; do not manufacture a global namespace.
**Authority:** Use Rune's [serialization and reference contract](https://rune.finos.org/docs/serialization/), the producer's identity contract, and [Rosetta reference guidance](rosetta.md#read-a-type); apply [workflow scope checks](workflows.md).
**Pattern:** Resolve references inside their owning root, then compare stable domain identifiers—including scheme/type where the contract distinguishes them—or a documented shared application identity. Defensively copy mutable inputs/outputs and key mutations to the explicitly selected entity. For a lifecycle classifier, reconcile the exact primitive envelope and cardinality, semantic payload direction/roles and identity, and the corresponding before/after state delta; CDM `only exists` constrains populated field names, not payload correctness or instruction cardinality.
**Proof:** Test declared-but-unresolved references, equal business identities with different local keys or object instances, reused values under different identity schemes, caller-list mutation, reordering, and untouched bystanders. For a classifier, independently mutate the envelope, payload direction/identity, and state delta and require each disagreement to fail closed.
**Wrong turns:** Reject these:
- Treat an unresolved declaration as absence or compare raw scoped/global reference strings across roots.
- Retain mutable aliases, infer direction from list position, accept an envelope without checking its payload, or widen an entity-level remedy into a portfolio/counterparty operation.
**Upgrade tripwire:** On a Rune serialization/CDM release or producer identity-contract change, recheck key semantics and rerun resolution, aliasing, ordering, and scope-isolation tests.

## PAT-004: Persist temporal windows and replay meaning

**Use when:** Behavior depends on lifecycle state, effective dates, policy windows, retries, corrections, or reversals.
**Avoid when:** Each result is a pure function of the complete immutable event history supplied on every call; do not persist derivable duplicate state.
**Authority:** Use the FINOS [CDM Event Model](https://cdm.finos.org/docs/event-model/) for state/lineage, and keep transition eligibility, calendars, and idempotency in the documented application layer; follow [lifecycle workflows](workflows.md#implement-or-change-a-lifecycle-event).
**Pattern:** Record explicit start/end/effective dates, prior/after identity, and replay identity plus content. Derive policy for every processed interval, preserve closed windows, and distinguish identical replay from an identifier reused with different economics.
**Proof:** Execute a sequence across both boundaries, skip processing dates, continue after closure, replay identical content, reject conflicting reuse, and assert each before/after state and lineage.
**Wrong turns:** Reject these:
- Apply one current-call flag to an elapsed interval or use current state for a historical entitlement.
- Treat document validity as transition legality or an event identifier alone as exactly-once semantics.
**Upgrade tripwire:** When the CDM event-model release, calendar/time-zone data, or persistence schema changes, inspect transition assumptions and rerun sequence, skipped-date, boundary, and replay tests.

## PAT-005: Preserve exact monetary direction and reconciliation

**Use when:** Calculating, allocating, rounding, netting, or emitting money, rates, prices, quantities, or signed transfers.
**Avoid when:** Choosing the economic formula, quote side, or market convention; establish those from the agreement/caller and dated guidance before applying this mechanical pattern.
**Authority:** Use active Rune/CDM unit declarations plus the caller/agreement; treat the dated [ISLA handbook](https://www.islagroup.org/isla-best-practice-handbook/) and [ICMA ERCC Guide](https://www.icmagroup.org/market-practice-and-regulatory-policy/repo-and-collateral-markets/icma-ercc-publications/icma-ercc-guide-to-best-practice-in-the-european-repo-market/) as contextual guidance subject to status/access terms, not executable or legal authority; follow [testing](testing.md#assert-economics-as-well-as-structure).
**Pattern:** Carry exact decimals with explicit units, currency, perspective, and payer/receiver direction. Select the intended typed economic leaf and fail closed when it is missing or ambiguous; never turn absence into zero or silently choose the first value. In Java, compare economic `BigDecimal` values numerically with `compareTo` after checking their units rather than using scale-sensitive `equals`. Round once at the supported currency scale; for partitions, round non-final pieces and assign the exact residual to the final piece.
**Proof:** Assert the selected typed leaf and unit, signed direction and scale, missing and multiple-value negatives, scale-equivalent decimals, asymmetric positive/negative cases, a rounding tie, and exact aggregate reconciliation; mutate quote side, unit, or sign so the focused test demonstrably fails.
**Wrong turns:** Reject these:
- Use binary floating point, `abs()`, one symmetric `round()`, or clamp a legitimate negative flow to zero.
- Treat missing as zero, pick the first unfiltered amount, compare `BigDecimal` economics with `equals`, round every component independently, infer currency scale from an example, or emit two gross flows when the contract requires one net amount.
**Upgrade tripwire:** When the CDM/Rune release, currency minor-unit source, agreement version, or cited market-guidance edition changes, re-verify conventions and rerun signed, scale, boundary, and reconciliation tests.
