# BDT 2.0 tranche-to-CDM discovery benchmark

Implement `ExpandIssuance(bdtMessage)` in Java 21 against FINOS CDM 7.0.0.

The input is a focused BDT 2.0-style structure: programme-level terms contain issuer LEI,
governing law, currency, and total issue size; the message then contains N tranches with ISIN,
coupon, maturity, issue size, issue date, and optional overrides of the programme-level fields.
Design an appropriate public Java input/result API around that shape. The output should expose one
self-contained CDM-side instrument per tranche, together with explicit validation failures. Choose
and justify the CDM representation and any application-owned boundary yourself; do not merely
invent fields on generated CDM classes.

Implement these behaviours and focused tests:

1. **Inheritance.** Three tranches are supplied and only one overrides the programme currency.
   The other two inherit the programme currency, while the override remains local to its tranche
   and cannot leak sideways into a sibling.
2. **Aggregate check.** The programme total issue size must equal the sum of the tranche rows.
   A missing tranche must produce a visible validation failure rather than partial or silent
   acceptance.
3. **Tap.** A later fourth row has the same ISIN as tranche 1 and represents a fungible reopening.
   Merge it into the existing instrument and add its issue size; do not mint a second CDM-side
   instrument with the same ISIN. The tap's economic and legal terms must match the original after
   inheritance and overrides are resolved, or expansion must fail loudly.
4. **Conflicting tap.** The same ISIN with a different coupon must be rejected. Silent
   last-writer-wins is not acceptable.

Use exact decimal arithmetic for rates and amounts. Do not mutate caller input or share mutable
state between sibling outputs. Preserve enough information to distinguish the original issue from
a later tap. Validate the identifiers and required business terms that a production boundary
reasonably should, and make malformed data caller-visible without returning misleading partial
instruments.

Add a short `DESIGN.md` explaining:

- why you chose the particular CDM 7.0.0 type or topology;
- where every supplied BDT field is represented, including any fact that cannot be represented
  faithfully in the chosen CDM object;
- what remains application-owned rather than generated-CDM behaviour; and
- how the tap retains a single ISIN identity without losing issuance provenance.

The workspace already contains the CDM 7.0.0 binary and source JARs under `lib/`. Work offline,
keep the existing dependency declaration unless it is genuinely broken, and run the complete test
suite with Gradle 8.10 and Java 21. Do not ask for a prescribed class design: make reasonable,
documented modelling decisions and deliver working code.
