# DRR ISO 20022 projection seam

Implement a production-oriented regulatory projection layer in miniature, in Java 21 against
FINOS CDM 7.0.0. Digital Regulatory Reporting pipelines model this as a formal step: Project
takes a CDM report object and applies mapping and projection rules to produce the ISO 20022 XML
file trade repositories and regulators require. The industry's observed failure mode sits
precisely at this seam — schema rejections and numerical reconciliation breaks concentrated in
how numbers and absences serialise — so this benchmark isolates it.

Provide the exact public entry points:

```text
Project(cdmReport) -> auth.030-style XML string
Parse(xml)        -> cdmReport
```

The report input is application-assembled, but its values must be genuine generated CDM 7.0.0
types: the fixed rate as `cdm.observable.asset.Price` with `priceType` InterestRate, a currency
unit, and the value held as a decimal fraction exactly as the Rune definition states ("An initial
rate of 5% would be represented as 0.05"); the notional as `cdm.base.math.NonNegativeQuantity`
with a currency unit; the UTI as `cdm.event.common.TradeIdentifier` with `identifierType`
UniqueTransactionIdentifier; the price-expression classification as
`cdm.observable.asset.PriceExpressionEnum`; and the reporting timestamp as a zoned date-time.
The XML vocabulary is a bounded auth.030-style fragment you define: one element per fact, fixed
element order, declared decimal limits of eighteen total digits and five fraction digits for
amounts. Parse must reconstruct typed CDM values from that XML, because the round trip is where
the truth lives.

Behavioral contract:

- Project expresses the CDM decimal-fraction rate as an ISO percentage and Parse inverts it
  exactly: 0.0525 projects as 5.25 and parses back to 0.0525; a zero rate survives the round
  trip as an explicit 0, not an absence; -0.005 projects as -0.5 with its sign intact.
- Absent is not zero and is not empty. An optional CDM fact with no value produces no element at
  all — never a zero-valued element, which is a false economic statement, and never an empty
  element, which is a schema violation. Parse must distinguish all three states.
- Every projected decimal is schema-canonical: no scientific notation regardless of how the
  value is held (1.23E7 serialises as 12300000), and a value that cannot fit the declared
  total-digits/fraction-digits limits must fail Project before any output is produced, never
  silently truncate or round.
- Every timestamp serialises in UTC with the Z designator, not a +00:00 offset.
- Every CDM-enum-to-ISO-code mapping is bijective, and a CDM value with no ISO code fails
  Project visibly rather than borrowing a neighbouring code.
- For every valid report r, Project(Parse(Project(r))) is byte-identical to Project(r).

Add focused tests for these acceptance cases:

1. The 100x rate basis: 0.0525 -> 5.25 and back; zero survives as explicit zero; -0.005 -> -0.5.
2. The three-way absence distinction, one test per arm: absent fact -> no element; a zero-valued
   element for an absent fact is never emitted; an empty element is never emitted and is rejected
   by Parse.
3. Decimal canonicalisation: a value held as 1.23E7 serialises as 12300000, and an
   over-limit value hard-fails Project with no partial output.
4. Round-trip idempotence as a property over a fixture set of at least four distinct reports,
   byte-identical, exercising UTC normalisation and every mapped enum value in both directions.

Keep projection and parsing policy in application code; CDM semantics stay in the generated
types, and populated relied-on CDM nodes must pass their generated validation. Ground every CDM
path in version-matched Rune source or the generated API; do not invent a CDM field. DRR itself
stays out of scope: do not embed, download, or execute ISDA DRR rule content or a DRR runtime —
this benchmark exercises only the CDM-to-ISO-20022 seam with an application-defined mapping.

Use `org.finos.cdm:cdm-java:7.0.0`, already declared in the build. The matching binary and
source JARs are available under `lib/` for offline inspection. Keep the implementation compact,
make the exact requested entry points compile and run in focused tests, and run the tests with
the available Gradle 8+ installation using Java 21.
