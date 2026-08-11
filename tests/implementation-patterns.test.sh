#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
checker="$repo_root/evals/check-patterns"
suite_name="implementation-patterns"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work

expect_ok "catalogue and sealed forward candidate pass their structural contract" \
  --stdout '5 patterns and 1 forward candidate.* passed' -- \
  "$checker"

fresh_fixture() {
  rm -rf -- "$work/fixture"
  mkdir -p "$work/fixture/skills/cdm-dev/references" "$work/fixture/evals"
  cp "$repo_root/skills/cdm-dev/references/implementation-patterns.md" \
    "$work/fixture/skills/cdm-dev/references/implementation-patterns.md"
  cp -R "$repo_root/evals/patterns" "$work/fixture/evals/patterns"
}

run_fixture() {
  "$checker" \
    --catalogue "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" \
    --patterns-dir "$work/fixture/evals/patterns"
}

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
text = text.replace("**Avoid when:**", "**Do not use:**", 1)
path.write_text(text)
PY
expect_fail "every card retains the complete ordered label contract" \
  --stderr "PAT-001 must contain 'Avoid when' exactly once" -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text().replace("## PAT-002:", "## PAT-001:", 1)
path.write_text(text)
PY
expect_fail "pattern identifiers remain unique and contiguous" \
  --stderr 'pattern ids must be unique and contiguous' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
start = text.index("## PAT-001:")
end = text.index("## PAT-002:")
card = text[start:end]
card = re.sub(r"https://[^)]+", "https://example.com/cdm", card, count=1)
path.write_text(text[:start] + card + text[end:])
PY
expect_fail "authority links use the reviewed primary-source allowlist" \
  --stderr 'PAT-001 Authority uses an unapproved source URL' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
start = text.index("## PAT-003:")
end = text.index("## PAT-004:")
card = text[start:end]
bullets = list(re.finditer(r"(?m)^- .+\n", card))
assert len(bullets) >= 2
victim = bullets[-1]
card = card[:victim.start()] + card[victim.end():]
path.write_text(text[:start] + card + text[end:])
PY
expect_fail "each card preserves two independent wrong-turn mutations" \
  --stderr 'PAT-003 Wrong turns must contain at least two Markdown bullets' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
start = text.index("## PAT-001:")
end = text.index("## PAT-002:")
card = text[start:end]
card = re.sub(
    r"(?m)^\*\*Upgrade tripwire:\*\*.*$",
    "**Upgrade tripwire:** When things change, look at them again.",
    card,
    count=1,
)
text = text[:start] + card + text[end:]
path.write_text(text)
PY
expect_fail "upgrade tripwires retain an explicit versioned trigger" \
  --stderr 'PAT-001 Upgrade tripwire must identify a versioned change' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
start = text.index("## PAT-002:")
end = text.index("## PAT-003:")
card = text[start:end]
card = re.sub(
    r"(?m)^\*\*Proof:\*\*.*$",
    "**Proof:** Describe the expected outcome in the design notes.",
    card,
    count=1,
)
path.write_text(text[:start] + card + text[end:])
PY
expect_fail "proof fields keep an executable check rather than prose assurance" \
  --stderr 'PAT-002 Proof must name executable evidence' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import re, sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
start = text.index("## PAT-004:")
end = text.index("## PAT-005:")
card = text[start:end]
use = re.search(r"(?m)^\*\*Use when:\*\* (.+)$", card)
assert use
card = re.sub(r"(?m)^\*\*Avoid when:\*\* .+$", f"**Avoid when:** {use.group(1)}", card, count=1)
path.write_text(text[:start] + card + text[end:])
PY
expect_fail "each card retains a distinct non-application boundary" \
  --stderr 'PAT-004 Use when and Avoid when must distinguish application from near-miss' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "primitive envelope and cardinality"
assert old in text
path.write_text(text.replace(old, "primitive envelope", 1))
PY
expect_fail "PAT-003 keeps primitive cardinality as independent classifier evidence" \
  --stderr 'PAT-003 Pattern must require primitive-envelope cardinality evidence' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "semantic payload direction/roles and identity"
assert old in text
path.write_text(text.replace(old, "semantic payload direction/roles", 1))
PY
expect_fail "PAT-003 keeps semantic identity alongside payload direction" \
  --stderr 'PAT-003 Pattern must require semantic direction/role and identity evidence' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "the corresponding before/after state delta"
assert old in text
path.write_text(text.replace(old, "the resulting state", 1))
PY
expect_fail "PAT-003 keeps before/after state delta as the third evidence class" \
  --stderr 'PAT-003 Pattern must require corresponding before/after state-delta evidence' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "; CDM `only exists` constrains populated field names, not payload correctness or instruction cardinality"
assert old in text
path.write_text(text.replace(old, "", 1))
PY
expect_fail "PAT-003 does not equate only-exists with payload or cardinality proof" \
  --stderr 'PAT-003 Pattern must clarify that only-exists is field-presence, not payload/cardinality proof' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "For a classifier, independently mutate the envelope, payload direction/identity, and state delta and require each disagreement to fail closed."
assert old in text
path.write_text(text.replace(old, "For a classifier, test representative positive and negative examples.", 1))
PY
expect_fail "PAT-003 keeps independent fail-closed mutations across all three evidence classes" \
  --stderr 'PAT-003 Proof must independently mutate envelope, direction/identity, and state delta and fail closed' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "Select the intended typed economic leaf"
assert old in text
path.write_text(text.replace(old, "Select an economic value", 1))
PY
expect_fail "PAT-005 keeps typed-leaf selection coupled to unit handling" \
  --stderr 'PAT-005 Pattern must select an intended typed economic leaf and its unit' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "fail closed when it is missing or ambiguous"
assert old in text
path.write_text(text.replace(old, "use zero when it is missing or the first value when ambiguous", 1))
PY
expect_fail "PAT-005 keeps missing and multiple-value handling fail closed" \
  --stderr 'PAT-005 Pattern must fail closed for missing or multiple typed values' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "In Java, compare economic `BigDecimal` values numerically with `compareTo` after checking their units rather than using scale-sensitive `equals`."
assert old in text
new = "In Java, compare economic `BigDecimal` values with scale-sensitive `equals` after checking their units."
path.write_text(text.replace(old, new, 1))
PY
expect_fail "PAT-005 keeps numeric BigDecimal compareTo semantics rather than equals" \
  --stderr 'PAT-005 Pattern must prefer Java BigDecimal.compareTo over equals' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/skills/cdm-dev/references/implementation-patterns.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text()
old = "scale-equivalent decimals"
assert old in text
path.write_text(text.replace(old, "representative decimals", 1))
PY
expect_fail "PAT-005 proof retains a scale-equivalent decimal case" \
  --stderr 'PAT-005 Proof must include an executable scale-equivalent decimal case' -- \
  run_fixture

fresh_fixture
printf '\nmodel-visible evaluator detail\n' >> \
  "$work/fixture/evals/patterns/forward/settlement-status-reconciliation/TASK.md"
expect_fail "sealed forward tasks fail after an unrecorded mutation" \
  --stderr 'task differs from its sealed SHA-256' -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/evals/patterns/PROTOCOL.md" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text().replace("## Judge correctness before efficiency", "## Compare aggregate score")
path.write_text(text)
PY
expect_fail "the promotion protocol keeps correctness ahead of speed" \
  --stderr "protocol must contain exactly one '## Judge correctness before efficiency'" -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/evals/patterns" <<'PY'
import json, sys
from pathlib import Path

base = Path(sys.argv[1])
manifest = json.loads((base / "manifest.json").read_text())
candidate = manifest["forward_tests"][0]
results = base / "results"
results.mkdir(exist_ok=True)
common = {
    "schema_version": 1,
    "candidate_id": candidate["id"],
    "pair_id": "forbidden-auth-pair",
    "recorded_at": "2026-08-11",
    "evidence_class": "fresh-forward",
    "task_sha256": candidate["task_sha256"],
    "rubric_sha256": candidate["rubric_sha256"],
    "probes_sha256": candidate["probes_sha256"],
    "catalogue_sha256": "a" * 64,
    "skill_sha256": "b" * 64,
    "source": {"cdm_version": "7.0.0", "binary_sha256": "c" * 64, "sources_sha256": "d" * 64},
    "result_commit": "e" * 40,
    "correctness": {"fatal_pass": True, "score": 100, "total": 100, "human_reviewed": True},
    "efficiency": {"wall_seconds": 1, "turns": 1, "tool_calls": 1, "source_queries": 1, "jar_extractions": 0},
    "contamination_audit": {"rubric_hidden": True, "sibling_access_blocked": True, "workspace_clean": True},
}
for arm in ("skill", "control"):
    value = dict(common)
    value["arm"] = arm
    value["environment"] = {
        "vendor": "fixture",
        "model": "fixture-model-1",
        "cli_version": "1.0.0",
        "java_version": "21",
        "gradle_version": "8.10",
        "auth_mode": "local-subscription",
    }
    if arm == "control":
        value["api_key"] = "must-never-be-recorded"
    (results / f"{arm}.json").write_text(json.dumps(value, indent=2) + "\n")
PY
expect_fail "saved evidence rejects credential-like fields" \
  --stderr "contains forbidden credential-like key 'api_key'" -- \
  run_fixture

fresh_fixture
python3 - "$work/fixture/evals/patterns" <<'PY'
import json, sys
from pathlib import Path

base = Path(sys.argv[1])
manifest = json.loads((base / "manifest.json").read_text())
candidate = manifest["forward_tests"][0]
value = {
    "schema_version": 1,
    "candidate_id": candidate["id"],
    "pair_id": "incomplete-pair",
    "recorded_at": "2026-08-11",
    "arm": "skill",
    "evidence_class": "fresh-forward",
    "task_sha256": candidate["task_sha256"],
    "rubric_sha256": candidate["rubric_sha256"],
    "probes_sha256": candidate["probes_sha256"],
    "catalogue_sha256": "a" * 64,
    "skill_sha256": "b" * 64,
    "source": {"cdm_version": "7.0.0", "binary_sha256": "c" * 64, "sources_sha256": "d" * 64},
    "environment": {"vendor": "fixture", "model": "fixture-model-1", "cli_version": "1.0.0", "java_version": "21", "gradle_version": "8.10", "auth_mode": "local-subscription"},
    "result_commit": "e" * 40,
    "correctness": {"fatal_pass": True, "score": 100, "total": 100, "human_reviewed": True},
    "efficiency": {"wall_seconds": 1, "turns": 1, "tool_calls": 1, "source_queries": 1, "jar_extractions": 0},
    "contamination_audit": {"rubric_hidden": True, "sibling_access_blocked": True, "workspace_clean": True},
}
results = base / "results"
results.mkdir(exist_ok=True)
(results / "skill.json").write_text(json.dumps(value, indent=2) + "\n")
PY
expect_fail "saved evidence is not accepted as an unpaired arm" \
  --stderr 'must contain exactly one skill and one control arm' -- \
  run_fixture

finish
