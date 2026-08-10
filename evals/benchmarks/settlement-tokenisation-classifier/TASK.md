# Settlement-level tokenisation classifier

Implement a Java function `ClassifyTokenisation(trade)` that inspects a FINOS CDM 7.0.0 trade and
returns exactly one of `ASSET_LEVEL`, `SETTLEMENT_LEVEL`, or `NOT_TOKENISED`:

- if the underlying `Asset` itself is a digital/token instrument, return `ASSET_LEVEL`;
- if the asset is conventional but its `SettlementTerms` specify on-chain transfer—for example, a
  cash leg settling as a deposit token—return `SETTLEMENT_LEVEL`;
- otherwise return `NOT_TOKENISED`.

Add focused tests for:

1. a security-token bond -> `ASSET_LEVEL`;
2. a plain UK Gilt repo with a tokenised cash settlement leg -> `SETTLEMENT_LEVEL`, with an explicit
   assertion that it is not `ASSET_LEVEL`;
3. a vanilla Gilt with conventional settlement -> `NOT_TOKENISED`.

Use `org.finos.cdm:cdm-java:7.0.0`, already declared in the Gradle build. Ground every CDM
field/path in the exact 7.0.0 Rune source or generated API. Do not silently invent a CDM field. If
the pinned model cannot directly express a required fact, preserve `Trade` as the classifier input
and introduce the narrowest explicit application-owned seam needed to represent that fact;
document the boundary and its precedence. Keep the implementation small and production-oriented.

The matching binary and source JARs are available under `lib/` for offline inspection. Run the
focused tests with the available Gradle 8+ installation using Java 21.
