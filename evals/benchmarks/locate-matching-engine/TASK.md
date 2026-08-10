# Locate matching engine

Implement a small production-oriented Java locate matching engine against FINOS CDM 7.0.0.

Provide the exact public entry point `MatchLocate(locateRequest, availabilityBroadcasts)`. It takes
a borrower locate containing an ISIN, requested quantity, requesting borrower and settlement date,
plus a set of lender availability broadcasts. It returns a fill plan showing which lenders supply
which quantities, the total filled quantity, and whether/how much remains short.

Matching requirements:

- match the requested ISIN and settlement date;
- never allocate more than the requested or available quantity;
- a general broadcast is eligible for any borrower;
- a targeted broadcast is eligible only when its intended borrower is the locate's borrower;
- allocate eligible broadcasts deterministically in input order and stop when filled;
- do not mutate either input.

Add focused tests for these acceptance cases:

1. A locate for 100,000 Vodafone shares and one lender broadcasting 500,000 generally produces one
   100,000 full fill with no shortfall.
2. A locate for 100,000, with Lender X broadcasting 60,000 generally and Lender Y broadcasting
   50,000 targeted at the requesting borrower, produces fills of 60,000 plus 40,000 with no
   shortfall.
3. The same inputs, except Lender Y targets a different counterparty, produce only the 60,000 fill
   and a 40,000 shortfall. Explicitly prove the targeted inventory was not treated as general.

Use the exact 7.0.0 CDM model types for the locate, availability records, security identifier,
quantity, parties and roles wherever the model represents them. Ground every CDM path in the
version-matched Rune source or generated API; do not invent a CDM field. Matching and fill-plan
policy remain application code. If a required application fact has no direct CDM field, use the
narrowest explicit application-owned boundary for that fact and document why.

Use `org.finos.cdm:cdm-java:7.0.0`, already declared in the build. The matching binary and source
JARs are available under `lib/` for offline inspection. Keep the implementation compact and make
the exact requested entry point compile and run in a focused test. Run the tests with the available
Gradle 8+ installation using Java 21.
