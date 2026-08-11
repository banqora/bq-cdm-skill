# Evaluator probes

Keep these checks evaluator-owned until every candidate exits and its deliverable is committed.
Adapt only public API wiring; do not change the economic contract by arm.

- Re-run the end-leg example and inspect both the result count and direction: one EUR 300,000
  buyer-to-seller payment, not two gross obligations or a signed amount with ambiguous parties.
- Snapshot all three portfolio entries deeply before mini close-out. Require only the selected entry
  to change, and mutate caller-owned input/output collections to detect retained aliases.
- Reorder the portfolio and require the same selected result; reject zero and duplicate matches
  before producing any partial output.
- Process at least two consecutive fail days at -0.50%, resolve the fail, and process a normal day.
  Require zero only in the fail window and a buyer-to-seller EUR 138.89 contractual accrual after it.
- Compare EUR 90/110 and EUR 98/102 quotes with the same mid. Require distinct EUR 1,000,000 and
  EUR 200,000 seller-to-buyer payments, then vary bid alone while holding offer fixed and require no
  change for the start-leg terminating-buyer case.
- Reject crossed or missing quotes, currency mismatch, unsupported basis/action, incoherent fail
  dates, an already-closed selected trade, and a missing or duplicated trade ID.
- Inspect the selected CDM lifecycle change and any emitted Money/transfer. Execute structural,
  inherited and populated-child conditions that apply; do not infer graph validity from a root-only
  validator.
- Re-run from a clean offline copy and inspect for binary floating point, current clock/default zone,
  gross-flow leakage, mid-price fallback, `abs()` direction repair, or mutation/static state.
