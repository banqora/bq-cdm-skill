#!/usr/bin/env bash
# The committed README graphics must be exactly what the renderer produces,
# must parse as XML, and must be the files the README actually embeds.
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
suite_name="render-benchmark-summary"
# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work

renderer="$repo_root/scripts/render-benchmark-summary"
expect_ok "the renderer writes both theme variants" \
  --stdout 'benchmark-summary-dark\.svg' -- \
  python3 "$renderer" "$work/render"

for mode in light dark; do
  committed="$repo_root/assets/benchmark-summary-$mode.svg"
  rendered="$work/render/benchmark-summary-$mode.svg"
  if cmp -s "$committed" "$rendered"; then
    report ok "committed $mode graphic matches the renderer output"
  else
    echo "  assets/benchmark-summary-$mode.svg drifted from scripts/render-benchmark-summary" >&2
    echo "  regenerate with: scripts/render-benchmark-summary assets" >&2
    report fail "committed $mode graphic matches the renderer output"
  fi
  expect_ok "$mode graphic is well-formed XML" -- \
    python3 -c "import sys, xml.etree.ElementTree as ET; ET.parse(sys.argv[1])" "$rendered"
done

expect_ok "README embeds the light graphic" \
  --stdout 'assets/benchmark-summary-light\.svg' -- \
  grep -o 'assets/benchmark-summary-light\.svg' "$repo_root/README.md"
expect_ok "README embeds the dark graphic" \
  --stdout 'assets/benchmark-summary-dark\.svg' -- \
  grep -o 'assets/benchmark-summary-dark\.svg' "$repo_root/README.md"

echo "$suite_name: $passed passed, $failed failed"
[[ "$failed" -eq 0 ]]
