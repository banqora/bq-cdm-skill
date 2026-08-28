#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
grader="$repo_root/evals/grade-quality"
runner="$repo_root/evals/run-quality"
suite_name="quality-evals"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work

good_answer="$work/good.md"
printf '%s\n' \
  'For CDM 7.0.0, observable-asset-type.rosetta declares quantity as NonNegativeQuantitySchedule (0..1).' \
  'The generated API exposes scalar FieldWithMetaNonNegativeQuantitySchedule and setQuantityValue, not a list.' \
  'The rules are NonCurrencyQuantities, PriceQuantityTriangulation, ArithmeticOperator, and InterestRateObservable.' \
  'The commodity allowance is unrepresentable through this singleton and its first clause is always satisfied.' \
  'Nested validation requires a unit, non-negative values (zero is valid), and value or datedValue via ScheduleValueExists.' \
  'Add a positive recursive validation test and a close negative test through fully wired runtime wiring.' \
  'For derivedQuantity triangulation, keep all operands populated and change only the derived quantity in the negative.' \
  'I used cdm-source on observable-asset-type.rosetta and inspected the generated PriceQuantity.java API.' \
  'This distinguishes exact model intent, generated behavior, recursive validation, and the integration mapping boundary.' \
  'Repeat the positive and negative fixtures through canonical serialization and assert the typed economic leaf survives.' \
  'A missing field must not make the triangulation test pass vacuously; the close negative should name the failed rule.' \
  'The version, source declaration, generated signature, validator name, and business consequence belong in the report.' \
  'Also cover the zero boundary, a negative amount, a missing unit, and replacement semantics when the scalar setter is called twice.' \
  'Assert the metadata wrapper and underlying value separately so a populated wrapper around an empty value cannot satisfy the content floor.' \
  'Run the same object through the canonical mapper and inspect the typed value after reading it back before trusting later validation.' \
  >"$good_answer"

expect_ok "reviewed answer passes every quality check" \
  --stdout 'price-quantity-model-api -> passed' -- \
  "$grader" --case price-quantity-model-api --answer "$good_answer"

bad_answer="$work/bad.md"
printf '%s\n' 'The field is optional. Add tests.' >"$bad_answer"
expect_fail "shallow answer fails deterministic grading" \
  --stderr '' -- \
  "$grader" --case price-quantity-model-api --answer "$bad_answer"

expect_fail "unknown case is a configuration error" \
  --stderr "exactly one quality case" -- \
  "$grader" --case absent --answer "$good_answer"

fixture_jar="$work/cdm-java-7.0.0.jar"
fixture_sources="$work/cdm-java-7.0.0-sources.jar"
python3 - "$fixture_jar" "$fixture_sources" <<'PY'
import sys
import zipfile

model_entries = [
    "cdm/rosetta/base-math-type.rosetta",
    "cdm/rosetta/observable-asset-type.rosetta",
    "cdm/rosetta/observable-common-func.rosetta",
    "cdm/rosetta/ingest-fpml-confirmation-tradestate-func.rosetta",
    "cdm/rosetta/product-template-type.rosetta",
    "cdm/rosetta/event-common-type.rosetta",
]
resource_entries = [
    "ingest/input/fpml-5-12-products-rates/ird-ex01-vanilla-swap.xml",
    "ingest/output/fpml-confirmation-to-trade-state/fpml-5-12-products-rates/ird-ex01-vanilla-swap.json",
    "ingest/config/test-pack-translate-fpml-confirmation-to-trade-state-fpml-5-12-products-rates.json",
    "ingest/input/fpml-5-12-products-repo/sbl-ex01-term-egrn-cash.xml",
    "ingest/output/fpml-confirmation-to-trade-state/fpml-5-12-products-repo/sbl-ex01-term-egrn-cash.json",
    "ingest/config/test-pack-translate-fpml-confirmation-to-trade-state-fpml-5-12-products-repo.json",
]
generated_entries = [
    "cdm/observable/asset/PriceQuantity.java",
    "cdm/observable/asset/meta/PriceQuantityMeta.java",
    "cdm/observable/asset/functions/InterestRateObservableCondition.java",
    "cdm/observable/asset/validation/PriceQuantityTypeFormatValidator.java",
    "cdm/observable/asset/validation/PriceQuantityValidator.java",
    "cdm/observable/asset/validation/datarule/PriceQuantityArithmeticOperator.java",
    "cdm/observable/asset/validation/datarule/PriceQuantityInterestRateObservable.java",
    "cdm/observable/asset/validation/datarule/PriceQuantityNonCurrencyQuantities.java",
    "cdm/observable/asset/validation/datarule/PriceQuantityPriceQuantityTriangulation.java",
    "cdm/observable/common/functions/PriceQuantityTriangulation.java",
    "cdm/base/math/Schedule.java",
    "cdm/base/math/QuantitySchedule.java",
    "cdm/base/math/NonNegativeQuantitySchedule.java",
    "cdm/base/math/meta/NonNegativeQuantityScheduleMeta.java",
    "cdm/base/math/metafields/FieldWithMetaNonNegativeQuantitySchedule.java",
    "cdm/base/math/validation/ScheduleTypeFormatValidator.java",
    "cdm/base/math/validation/QuantityScheduleTypeFormatValidator.java",
    "cdm/base/math/validation/NonNegativeQuantityScheduleTypeFormatValidator.java",
    "cdm/base/math/validation/NonNegativeQuantityScheduleValidator.java",
    "cdm/base/math/validation/datarule/ScheduleValueExists.java",
]

with zipfile.ZipFile(sys.argv[1], "w") as archive:
    for entry in model_entries:
        archive.writestr(entry, 'namespace cdm.fixture\nversion "7.0.0"\n')
    for entry in resource_entries:
        archive.writestr(entry, f"fixture resource {entry}\n")
with zipfile.ZipFile(sys.argv[2], "w") as archive:
    for entry in generated_entries:
        content = f"// fixture {entry}\n"
        if entry == "cdm/observable/asset/PriceQuantity.java":
            content += '@RosettaDataType(value="PriceQuantity", version="7.0.0")\n'
        archive.writestr(entry, content)
PY

fake_bin="$work/bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/claude" <<'SH'
#!/usr/bin/env bash
set -uo pipefail

for variable in ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_BASE_URL CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY; do
  [[ -z "${!variable:-}" ]] || exit 90
done
if [[ "${1:-}" == auth && "${2:-}" == status ]]; then
  printf '{"loggedIn":true,"authMethod":"claude.ai","subscriptionType":"fake"}\n'
  exit
fi
if [[ "${2:-}" == *"evidence/resources"* ]]; then
  [[ -f evidence/resources/ingest/input/fpml-5-12-products-repo/sbl-ex01-term-egrn-cash.xml ]] || exit 91
  [[ -f evidence/model/cdm/rosetta/ingest-fpml-confirmation-tradestate-func.rosetta ]] || exit 92
else
  [[ -f evidence/model/cdm/rosetta/base-math-type.rosetta ]] || exit 91
  [[ -f evidence/generated/cdm/base/math/metafields/FieldWithMetaNonNegativeQuantitySchedule.java ]] || exit 92
fi
[[ "$*" == *"--output-format stream-json"* ]] || exit 93
[[ "$*" == *"--tools Read,Grep,Glob"* ]] || exit 94
[[ "${2:-}" == *"Use only that bundle"* ]] || exit 95
if [[ "$*" == *"Read,Grep,Glob,Skill"* ]]; then
  [[ -d .claude/skills/cdm-dev ]] || exit 96
else
  [[ ! -d .claude/skills ]] || exit 97
fi
if [[ "${FAKE_QUALITY_MODE:-success}" == malformed ]]; then
  printf 'not-json\n'
  exit
fi
python3 - "${FAKE_QUALITY_ANSWER:?}" <<'PY'
import json, sys
from pathlib import Path
print(json.dumps({"type": "result", "subtype": "success", "is_error": False,
                  "result": Path(sys.argv[1]).read_text()}))
PY
SH

cat >"$fake_bin/codex" <<'SH'
#!/usr/bin/env bash
set -uo pipefail

for variable in OPENAI_API_KEY CODEX_API_KEY CODEX_ACCESS_TOKEN OPENAI_BASE_URL; do
  [[ -z "${!variable:-}" ]] || exit 90
done
if [[ "${1:-}" == login && "${2:-}" == status ]]; then
  printf 'Logged in using ChatGPT\n' >&2
  exit
fi
if [[ "$*" == *"evidence/resources"* ]]; then
  [[ -f evidence/resources/ingest/input/fpml-5-12-products-rates/ird-ex01-vanilla-swap.xml ]] || exit 91
else
  [[ -f evidence/model/cdm/rosetta/observable-asset-type.rosetta ]] || exit 91
  [[ -f evidence/generated/cdm/observable/asset/PriceQuantity.java ]] || exit 92
fi
[[ "$*" == *"exec --ephemeral --sandbox read-only"* ]] || exit 93
if [[ "$*" == *"cdm-dev"* ]]; then
  [[ -d .agents/skills/cdm-dev ]] || exit 96
else
  [[ ! -d .agents/skills ]] || exit 97
fi
python3 - "${FAKE_QUALITY_ANSWER:?}" <<'PY'
import sys
from pathlib import Path
print(Path(sys.argv[1]).read_text(), end="")
PY
SH
chmod +x "$fake_bin/claude" "$fake_bin/codex"

claude_results="$work/claude-results.json"
expect_ok "quality runner parses Claude JSONL and grades extracted evidence" \
  --stdout 'claude treatment 1/1 cases passed' -- \
  env PATH="$fake_bin:$PATH" FAKE_QUALITY_ANSWER="$good_answer" \
  ANTHROPIC_API_KEY=ignored ANTHROPIC_BASE_URL=ignored \
  "$runner" --vendor claude --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --case price-quantity-model-api --results "$claude_results"

codex_results="$work/codex-results.json"
expect_ok "quality runner uses Codex read-only subscription mode" \
  --stdout 'codex treatment 1/1 cases passed' -- \
  env PATH="$fake_bin:$PATH" FAKE_QUALITY_ANSWER="$good_answer" \
  OPENAI_API_KEY=ignored OPENAI_BASE_URL=ignored \
  "$runner" --vendor codex --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --case price-quantity-model-api --results "$codex_results"

expect_fail "quality runner rejects malformed Claude streams" \
  --stderr 'invalid Claude JSONL' -- \
  env PATH="$fake_bin:$PATH" FAKE_QUALITY_ANSWER="$good_answer" FAKE_QUALITY_MODE=malformed \
  "$runner" --vendor claude --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --case price-quantity-model-api

fpml_answer="$work/fpml-good.md"
printf '%s\n' \
  'Verdict: the ird-ex01 vanilla swap pair is faithful; the sbl-ex01 security lending pair cannot be trusted.' \
  'For CDM 7.0.0, evidence/resources holds both certified pairs and their test-pack assertion configs.' \
  'The vanilla swap output preserves the 0.06 fixed rate, the EUR-LIBOR-BBA floating index, the EUR 50000000 notional,' \
  'both day count fractions, the effective and termination dates, a typed InterestRatePayout, counterparty, and tradeLot.' \
  'The security lending output keeps only trade identifier, date, parties, and documentation: it has no product,' \
  'no tradeLot, and no counterparty, although all three are required fields on the trade in product-template-type.rosetta.' \
  'The dropped economics include the 0.012 fixed rebate rate, the USD 5826000 nominal, the dirty price, the loan term' \
  'settlement dates, the margin ratio, the tri-party collateral provisions, the posted cash collateral, and the lender' \
  'and borrower party roles, none of which appear anywhere in the certified output document.' \
  'The root cause is in evidence/model ingest-fpml-confirmation-tradestate-func.rosetta: MapNonTransferableProduct' \
  'switches over thirty fpml product types and fpml.SecurityLending has no route at all, so the product maps to empty.' \
  'The pack assertions record inputPathCount 83 against outputPathCount 34 and tolerate modelValidationFailures of 8,' \
  'so they only count paths and failures: they do not prove any mapped value is right, and a regenerated expectation' \
  'would bless the same hollow output. The required product, tradeLot, and counterparty violations sit inside that' \
  'tolerated failure count, which is why the build stays green over an economically empty trade state.' \
  'By contrast the rates pack asserts zero tolerated validation failures for the vanilla swap and its output survives' \
  'every business fact I checked against the FpML source, so that certification is meaningful.' \
  'Evidence used: both XML inputs, both certified JSON outputs, both test-pack configs, and the mapping and model' \
  'source files under evidence/, all from the exact CDM 7.0.0 artifact in lib.' \
  >"$fpml_answer"

expect_ok "fpml fidelity answer passes deterministic grading" \
  --stdout 'fpml-ingestion-fidelity -> passed' -- \
  "$grader" --case fpml-ingestion-fidelity --answer "$fpml_answer"

expect_fail "shallow fpml answer fails deterministic grading" \
  --stderr '' -- \
  "$grader" --case fpml-ingestion-fidelity --answer "$bad_answer"

expect_ok "treatment arm runs the fpml case with the skill installed" \
  --stdout 'claude treatment 1/1 cases passed' -- \
  env PATH="$fake_bin:$PATH" FAKE_QUALITY_ANSWER="$fpml_answer" \
  "$runner" --vendor claude --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --case fpml-ingestion-fidelity --results "$work/fpml-treatment.json"

expect_ok "control arm runs the same case without any installed skill" \
  --stdout 'claude control 1/1 cases passed' -- \
  env PATH="$fake_bin:$PATH" FAKE_QUALITY_ANSWER="$fpml_answer" \
  "$runner" --vendor claude --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --case fpml-ingestion-fidelity --arm control --results "$work/fpml-control.json"

expect_ok "codex control arm also runs without a skill directory" \
  --stdout 'codex control 1/1 cases passed' -- \
  env PATH="$fake_bin:$PATH" FAKE_QUALITY_ANSWER="$fpml_answer" \
  "$runner" --vendor codex --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --case fpml-ingestion-fidelity --arm control --results "$work/fpml-codex-control.json"

expect_fail "control arm requires a case-level control prompt" \
  --stderr 'control arm needs a control_prompt' -- \
  env PATH="$fake_bin:$PATH" FAKE_QUALITY_ANSWER="$good_answer" \
  "$runner" --vendor claude --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --case price-quantity-model-api --arm control

expect_fail "unknown arms are rejected before any model call" \
  --stderr 'must be treatment or control' -- \
  "$runner" --vendor claude --jar "$fixture_jar" --sources-jar "$fixture_sources" \
  --arm shadow

finish
