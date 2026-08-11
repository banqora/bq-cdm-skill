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
  --stdout '13 benchmarks passed' -- \
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
