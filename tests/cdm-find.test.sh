#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skill_dir="$repo_root/skills/cdm-dev"
cdm_find="$skill_dir/scripts/cdm-find"
suite_name="cdm-find"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"
# shellcheck source=tests/fixtures.sh
source "$script_dir/fixtures.sh"

setup_work
build_fixture_jars

python3 - "$fixture_jar" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1], "a") as jar:
    jar.writestr(
        "cdm/rosetta/find-fixture.rosetta",
        '''namespace cdm.product.template : <"Search fixture with a documented namespace.">

type EconomicTerms: <"Terms governing the economics of a product.">
  terminationDate string (0..1) <"The repurchase date for a repo transaction.">

type CorporateAction: <"An issuer event affecting a security.">
  recordDate date (1..1) <"The date used to establish an entitlement.">

type SharedDeclaration:
  value string (1..1)

func SharedDeclaration:
  output:
    value string (1..1)
  set value:
    "function"

func ResolveRepurchaseDate:
  inputs:
    economicTerms EconomicTerms (1..1)
  output:
    repurchaseDate string (0..1)
  set repurchaseDate:
    economicTerms -> terminationDate

func Qualify_Repurchase: <"True for a qualifying repurchase event.">
  [qualification EconomicTerms]
  inputs:
    economicTerms EconomicTerms (1..1)
  output:
    isEvent boolean (1..1)
  set isEvent:
    economicTerms -> terminationDate exists
''',
    )
PY

expect_ok "help documents the small plain-word interface" \
  --stdout 'capped at six candidates by default' -- \
  "$cdm_find" --help

trade_state_lookup() {
  local output
  output="$("$cdm_find" --jar "$fixture_jar" trade state)" || return
  rg '^selector[[:space:]]+location[[:space:]]+hit$' <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "CamelCase declarations are found with ordinary words" \
  --stdout '^type:cdm\.event\.common\.TradeState[[:space:]]' -- \
  trade_state_lookup

expect_ok "semantic model text finds the declaration that owns the leaf" \
  --stdout '^type:cdm\.product\.template\.EconomicTerms[[:space:]].*repurchase date' -- \
  "$cdm_find" --jar "$fixture_jar" repurchase date

expect_ok "results provide a copyable compact-inspection handoff" \
  --stdout '^# next=cdm-source members type:cdm\.event\.common\.TradeState$' -- \
  "$cdm_find" --jar "$fixture_jar" trade state

same_name_kinds() {
  local output
  output="$("$cdm_find" --jar "$fixture_jar" shared declaration)" || return
  rg '^type:cdm\.product\.template\.SharedDeclaration[[:space:]]' \
    <<<"$output" >/dev/null || return
  rg '^func:cdm\.product\.template\.SharedDeclaration[[:space:]]' \
    <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "same-name types and functions retain explicit kind selectors" \
  --stdout '^# cdm-find version=9\.9\.9 ' -- same_name_kinds

expect_ok "qualification functions are labelled separately from ordinary functions" \
  --stdout '^qualification:cdm\.product\.template\.Qualify_Repurchase[[:space:]]' -- \
  "$cdm_find" --jar "$fixture_jar" qualify repurchase

one_result_only() {
  local output result_count
  output="$("$cdm_find" --jar "$fixture_jar" --limit 1 repurchase date)" || return
  result_count="$(awk -F '\t' 'NF == 3 && $1 != "selector" { count++ } END { print count + 0 }' \
    <<<"$output")"
  [[ "$result_count" -eq 1 ]] || return
  printf '%s\n' "$output"
}
expect_ok "the caller can lower the already-small result bound" \
  --stdout 'shown=1$' -- one_result_only

bounded_default() {
  local output line_count result_count
  output="$("$cdm_find" --jar "$fixture_jar" value)" || return
  line_count="$(awk 'END { print NR }' <<<"$output")"
  result_count="$(awk -F '\t' 'NF == 3 && $1 != "selector" { count++ } END { print count + 0 }' \
    <<<"$output")"
  [[ "$line_count" -le 10 && "$result_count" -le 6 ]] || return
  printf '%s\n' "$output"
}
expect_ok "broad discovery remains bounded to ten output lines" \
  --stdout '^# refine=.*do not inspect every candidate$' -- bounded_default

expect_fail "an impossible query fails with a narrowing escape hatch" \
  --stderr 'no declaration contains every search term.*cdm-source search' -- \
  "$cdm_find" --jar "$fixture_jar" never present together

expect_fail "an invalid limit fails before searching" \
  --stderr='--limit must be an integer from 1 to 12' -- \
  "$cdm_find" --jar "$fixture_jar" --limit 13 trade

fake_bin="$work/fake-bin"
mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 97' >"$fake_bin/unzip"
chmod +x "$fake_bin/unzip"
find_without_extraction() {
  PATH="$fake_bin:$PATH" \
    "$cdm_find" --jar "$fixture_jar" trade state
}
expect_ok "lookup reads the archive in memory without filesystem extraction" \
  --stdout '^type:cdm\.event\.common\.TradeState[[:space:]]' -- \
  find_without_extraction

spaced_scripts="$work/skill scripts"
cp -R "$skill_dir/scripts" "$spaced_scripts"
expect_ok "lookup works when the installed skill path contains spaces" \
  --stdout '^type:cdm\.event\.common\.TradeState[[:space:]]' -- \
  "$spaced_scripts/cdm-find" --jar "$fixture_jar" trade state

finish
