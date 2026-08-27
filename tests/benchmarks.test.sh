#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
checker="$repo_root/evals/check-benchmarks"
suite_name="benchmarks"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work

expect_ok "saved implementation benchmarks pass their structural contract" \
  --stdout '14 benchmarks passed' -- \
  "$checker"

fixture="$work/evals"
mkdir -p "$fixture"
cp -R "$repo_root/evals/benchmarks" "$fixture/benchmarks"

python3 - "$fixture/benchmarks/index.json" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
value = json.loads(path.read_text())
value["benchmarks"][0]["task"] = "../outside/TASK.md"
path.write_text(json.dumps(value, indent=2) + "\n")
PY
expect_fail "benchmark paths cannot escape the evals directory" \
  --stderr 'task settlement-tokenisation-classifier escapes' -- \
  "$checker" --evals-dir "$fixture"

rm -rf -- "$fixture"
mkdir -p "$fixture"
cp -R "$repo_root/evals/benchmarks" "$fixture/benchmarks"
python3 - "$fixture/benchmarks/index.json" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
value = json.loads(path.read_text())
benchmark = value["benchmarks"][0]
directory = "benchmarks/settlement-tokenisation-classifier"
benchmark["task"] = directory
benchmark["rubric"] = directory
benchmark["baseline"] = directory
path.write_text(json.dumps(value, indent=2) + "\n")
PY
directory_manifest_paths_fail_closed() {
  local output
  if output="$($checker --evals-dir "$fixture" 2>&1)"; then
    return 1
  fi
  rg 'task settlement-tokenisation-classifier must be a file' <<<"$output" >/dev/null || return
  rg 'rubric settlement-tokenisation-classifier must be a file' <<<"$output" >/dev/null || return
  rg 'baseline settlement-tokenisation-classifier must be a file' <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "benchmark artifact paths cannot use directories to bypass validation" \
  --stdout 'baseline settlement-tokenisation-classifier must be a file' -- \
  directory_manifest_paths_fail_closed

rm -rf -- "$fixture"
mkdir -p "$fixture"
cp -R "$repo_root/evals/benchmarks" "$fixture/benchmarks"
python3 - "$fixture/benchmarks/locate-matching-engine/rubric.json" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
value = json.loads(path.read_text())
value["criteria"][0]["weight"] += 1
path.write_text(json.dumps(value, indent=2) + "\n")
PY
expect_fail "rubric weights must retain the fixed 100-point contract" \
  --stderr 'criterion weights total 101' -- \
  "$checker" --evals-dir "$fixture"

rm -rf -- "$fixture"
mkdir -p "$fixture"
cp -R "$repo_root/evals/benchmarks" "$fixture/benchmarks"
python3 - "$fixture/benchmarks/drr-iso20022-projection/TASK.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
path.write_text(path.read_text() + "\nUnsealed mutation.\n")
PY
expect_fail "sealed task digests reject in-place benchmark changes" \
  --stderr 'task drr-iso20022-projection digest differs' -- \
  "$checker" --evals-dir "$fixture"

rm -rf -- "$fixture"
mkdir -p "$fixture"
cp -R "$repo_root/evals/benchmarks" "$fixture/benchmarks"
python3 - "$fixture/benchmarks/index.json" <<'PY'
import json, sys
from pathlib import Path
path = Path(sys.argv[1])
value = json.loads(path.read_text())
value["benchmarks"][1]["id"] = value["benchmarks"][0]["id"]
path.write_text(json.dumps(value, indent=2) + "\n")
PY
expect_fail "benchmark identifiers must be unique" \
  --stderr 'repeats id settlement-tokenisation-classifier' -- \
  "$checker" --evals-dir "$fixture"

finish
