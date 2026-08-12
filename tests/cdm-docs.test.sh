#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skill_dir="$repo_root/skills/cdm-dev"
cdm_docs="$skill_dir/scripts/cdm-docs"
suite_name="cdm-docs"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work

expect_ok "help defines the fixed, contamination-resistant scope" \
  --stdout 'fixed search scope is SKILL.md plus references/\*\.md' -- \
  "$cdm_docs" --help

pattern_route() {
  local output
  output="$("$cdm_docs" only exists direction identity)" || return
  rg '^references/implementation-patterns\.md[[:space:]]+PAT-003:' \
    <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "a lifecycle question routes to the matching implementation card" \
  --stdout '^# next=read-completely references/implementation-patterns\.md$' -- \
  pattern_route

expect_ok "a domain phrase routes to one focused product reference" \
  --stdout '^references/assets-and-cash-securities\.md[[:space:]]+Keep asset and settlement tokenisation separate' -- \
  "$cdm_docs" settlement tokenisation

expect_ok "output labels guidance separately from version-specific model proof" \
  --stdout '^# authority=guidance only; prove model facts with cdm-find/cdm-source$' -- \
  "$cdm_docs" settlement tokenisation

one_result_only() {
  local output result_count
  output="$("$cdm_docs" --limit 1 validation)" || return
  result_count="$(awk -F '\t' 'NF == 3 && $1 != "document" { count++ } END { print count + 0 }' \
    <<<"$output")"
  [[ "$result_count" -eq 1 ]] || return
  printf '%s\n' "$output"
}
expect_ok "the caller can lower the bounded result count" \
  --stdout 'shown=1$' -- one_result_only

bounded_default() {
  local output line_count result_count
  output="$("$cdm_docs" validation)" || return
  line_count="$(awk 'END { print NR }' <<<"$output")"
  result_count="$(awk -F '\t' 'NF == 3 && $1 != "document" { count++ } END { print count + 0 }' \
    <<<"$output")"
  [[ "$line_count" -le 10 && "$result_count" -le 5 ]] || return
  printf '%s\n' "$output"
}
expect_ok "broad guidance discovery is capped at ten output lines" \
  --stdout '^# refine=.*do not load every reference$' -- bounded_default

expect_fail "an impossible query points back to the explicit reference map" \
  --stderr 'no bundled guidance contains every search term.*reference map in SKILL.md' -- \
  "$cdm_docs" absent words never colocated

expect_fail "an invalid limit fails before reading guidance" \
  --stderr='--limit must be an integer from 1 to 8' -- \
  "$cdm_docs" --limit 9 validation

expect_fail "the search root cannot be overridden to include repository material" \
  --stderr="unknown option '--root'" -- \
  "$cdm_docs" --root "$repo_root" benchmark

copy="$work/cdm-dev"
cp -R "$skill_dir" "$copy"
mkdir -p "$copy/evals" "$copy/references/nested"
printf '# LEAKONLY benchmark review\n' >"$copy/README.md"
printf '# LEAKONLY hidden evaluator\n' >"$copy/evals/review.md"
printf '# LEAKONLY nested reference\n' >"$copy/references/nested/review.md"
expect_fail "README, evals, and nested artifacts cannot contaminate results" \
  --stderr 'no bundled guidance contains every search term' -- \
  "$copy/scripts/cdm-docs" LEAKONLY

printf '\nUNIQUELOADEDSKILLROUTE\n' >>"$copy/SKILL.md"
expect_ok "SKILL.md is available only as a fallback when no reference matches" \
  --stdout '^# next=use the already-loaded SKILL.md guidance$' -- \
  "$copy/scripts/cdm-docs" UNIQUELOADEDSKILLROUTE

printf '# escaped guidance\n' >"$work/escaped.md"
ln -s "$work/escaped.md" "$copy/references/escaped.md"
expect_fail "symlinked references cannot escape the distributable skill" \
  --stderr 'refusing symlinked reference' -- \
  "$copy/scripts/cdm-docs" escaped guidance

directory_copy="$work/cdm-dev-directory-link"
cp -R "$skill_dir" "$directory_copy"
mv "$directory_copy/references" "$directory_copy/references-real"
ln -s "$work" "$directory_copy/references"
expect_fail "the references directory itself cannot redirect the search scope" \
  --stderr 'refusing a symlinked references directory' -- \
  "$directory_copy/scripts/cdm-docs" escaped guidance

skill_link_copy="$work/cdm-dev-skill-link"
cp -R "$skill_dir" "$skill_link_copy"
mv "$skill_link_copy/SKILL.md" "$skill_link_copy/SKILL-real.md"
ln -s "$work/escaped.md" "$skill_link_copy/SKILL.md"
expect_fail "SKILL.md cannot redirect the search scope" \
  --stderr 'refusing a symlinked SKILL.md' -- \
  "$skill_link_copy/scripts/cdm-docs" escaped guidance

finish
