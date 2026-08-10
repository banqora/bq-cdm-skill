# Repo settlement shaping

Implement a small production-oriented Java settlement shaper against FINOS CDM 7.0.0.

Provide this exact public entry point (an additional idiomatic alias is fine):

```java
public static List<PrimitiveInstruction> ShapeSettlement(Trade trade, BigDecimal maxShapeSize)
```

`trade` is a single-lot repo. Shape its collateral **start-leg settlement**, not the trade itself:
split the collateral nominal into ordered settlement shapes no larger than `maxShapeSize`. Every
returned `PrimitiveInstruction` must populate `transfer`; its `TransferInstruction` must contain
the paired collateral and cash `TransferState` objects for that one DvP shape. Preserve the
underlying security, cash currency, settlement date, and opposing payer/receiver directions.

The fixtures follow the CDM 7.0.0 repo representation used by the distribution's
`functions/repo-and-bond` examples: one `TradeLot` contains the currency cash `PriceQuantity` and
the security-observable collateral `PriceQuantity`; the repo collateral product contains the
`AssetPayout` and its ordered near/far `AssetLeg` entries. Use the exact model/source to resolve the
generated Java paths. The agreed start-leg cash quantity is authoritative; do not recompute it
from a rounded price.

For each non-final shape, allocate cash pro rata to the shape's collateral nominal and round USD
cash to cents with `RoundingMode.HALF_EVEN`. Set the final shape's cash amount to the original cash
total minus all earlier rounded shapes, so the result reconciles exactly. Use `BigDecimal`
throughout; do not pass through `double`.

Do not call CDM's `Create_ShapingInstruction`: that function splits a trade into shaped trades and
is a different lifecycle operation. Do not mutate the input `Trade`. Reject a non-positive cap and
fail clearly when the input is not the unambiguous repo shape described above.

Add focused tests for:

1. Collateral nominal `170,000,000`, cash `168,734,567.89`, cap `50,000,000`: four shapes with
   collateral `50m / 50m / 50m / 20m`; every shape has both DvP transfers; collateral and cash sum
   exactly to the input, with the final cash transfer absorbing the cent-rounding residual.
2. Collateral nominal `100,000,000`, cash `99,250,000.00`, cap `50,000,000`: exactly two `50m`
   shapes and no zero-sized remainder instruction.
3. Collateral nominal `30,000,000`, cash `29,775,000.33`, cap `50,000,000`: one instruction whose
   collateral/cash economics and settlement details are identical to the unshaped start leg.

Use `org.finos.cdm:cdm-java:7.0.0`, already declared in the build. Ground every CDM field/path in
the exact 7.0.0 Rune source or generated API; do not invent a CDM field or edit generated code. If
the pinned model cannot faithfully express a required settlement fact, keep the caller signature
and economic invariants intact, introduce only the narrowest explicit application-owned boundary,
and document the limitation instead of silently relabelling units.

The matching binary and source JARs are available under `lib/` for offline inspection. Keep the
implementation compact. Run the focused tests with the available Gradle 8+ installation using
Java 21.
