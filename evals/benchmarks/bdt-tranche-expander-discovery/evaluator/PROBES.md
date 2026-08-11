# Adaptive evaluator probes

The task deliberately lets each agent design its own Java API, so one evaluator source file cannot
compile against every submission. The rubric and the following semantic probes were frozen before
the runs. After all four model processes had exited and their deliverables were committed, each
probe was adapted mechanically to the arm's public types and run in a clean copy.

## Genuine-later tap guard

Construct two otherwise fungible rows with the same ISIN and the same issue date. Set the declared
programme total to the exact sum of both rows. Invoke `ExpandIssuance` and assert that the result is
unsuccessful, contains no instruments, and reports that the duplicate is not a later reopening.

This is derived from `tap-identity-and-provenance`: row order alone must not turn a same-day or
earlier duplicate into a tap.

| Arm | Result |
|---|---|
| Sonnet 5 + skill | Fail: silently merged |
| Sonnet 5 control | Fail: silently merged |
| GPT-5.4 + skill | Fail: silently merged |
| GPT-5.4 control | Fail: silently merged |

The complete suites with this one added assertion failed 1/27, 1/10, 1/8, and 1/7 respectively.
The GPT control count includes the separate LEI probe below.

## Published-valid LEI vector

For GPT-5.4 control, repeat a valid single-tranche expansion with Bloomberg Finance L.P.'s
[published LEI `5493001KJTIIGC8Y1R12`](https://lei.bloomberg.com/leis/view/5493001KJTIIGC8Y1R12).
The implementation must accept the checksum-valid LEI.

Result: fail. The control rearranges the LEI as if it were an IBAN before computing mod 97. Its
authored fixture `5493001KJTIIGC8Y1R35` was generated with that same incorrect algorithm, so its
green test was self-confirming.

## Generated CDM rule probe

For the GPT-5.4 treatment, take the emitted `TransferableProduct` and execute these generated CDM
7.0.0 rules directly:

- `InterestRatePayoutQuantity`
- `InterestRatePayoutRateSpecification`
- `PriceScheduleCurrencyUnitForInterestRate`
- `PriceScheduleUnitOfAmountExists`
- `EconomicTermsQuantity`
- `EconomicTermsDayCountFraction`

Result: 6/6 pass. This probe was added only after the original six authored tests and deliverable
were sealed, so it is evaluator evidence rather than an agent-authored test.

Claude Fable 5 also ran recursive generated cardinality, type-format, and data-rule validation over
representative outputs from all four arms. The graphs were clean. One treatment rule could not be
executed in the reviewer's reflection-wired dependency-injection harness; its required
`Security.partyRole` predicate was inspected and present. No arm claimed or was credited with
product qualification.
