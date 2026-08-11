# Evaluator-owned probes

Keep these probes outside both candidate workspaces until their processes have exited and their
result commits are sealed. Adapt only public API wiring; do not change the transition contract by
arm.

- Create three same-counterparty entries whose CDM values and application histories are distinct.
  Reorder them before selecting the middle identifier. Deep-compare all bystanders and every old
  snapshot field after the update.
- Build input and result lists from mutable collections, mutate each caller collection after the
  call, and attempt mutation through every exposed accessor. Require stable old/new snapshots and
  audit history without relying only on an unmodifiable wrapper around a retained alias.
- Replay an accepted update after reconstructing the processor from returned state. Require no new
  line. Then reuse the ID while varying target, timestamp, status, and reason independently; every
  conflicting variant must reject without mutation.
- Run every transition-table edge, including repair from FAILED to MATCHED and all transitions from
  SETTLED. Supply blank, missing, and non-blank failure reasons. Exercise equal, increasing, and
  decreasing timestamps at the selected entry's boundary.
- Provide zero, one, and two matches for the requested trade identifier. For rejection paths,
  compare the complete book and audit state before and after and look for mutations performed before
  validation completed.
- Capture the CDM TradeState before operational MATCHED, SETTLED, and FAILED updates. Require its
  lifecycle, economics, and populated generated graph to remain unchanged; operational status must
  not be encoded as a fabricated ClosedState or invented generated field.
- Inspect DESIGN.md and executable tests for the claimed validation tier. If the root is described
  as complete, run applicable root and populated-child validators through working wiring and mutate
  one populated child. If it is deliberately partial, require honest labelling and validate only
  complete nodes actually relied on.
- Rebuild from a clean offline copy with a unique Gradle cache and no daemon. Count helper source/API
  queries and direct JAR extraction commands from the raw trace; check for clocks, default time
  zones, mutable statics, swallowed validation errors, and process-local replay stores.
