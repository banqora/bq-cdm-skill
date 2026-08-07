#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
runner="$repo_root/evals/run-triggers"
prompts="$repo_root/evals/prompts.json"
suite_name="run-triggers"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work

fake_bin="$work/bin"
fake_log="$work/cli.log"
mkdir -p "$fake_bin"

cat >"$fake_bin/claude" <<'SH'
#!/usr/bin/env bash
set -uo pipefail

[[ -z "${ANTHROPIC_API_KEY:-}" ]] || {
  echo "fake claude: ANTHROPIC_API_KEY leaked" >&2
  exit 90
}
[[ -z "${ANTHROPIC_AUTH_TOKEN:-}" ]] || {
  echo "fake claude: ANTHROPIC_AUTH_TOKEN leaked" >&2
  exit 91
}
[[ -z "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]] || {
  echo "fake claude: CLAUDE_CODE_OAUTH_TOKEN leaked" >&2
  exit 92
}
[[ -z "${ANTHROPIC_BASE_URL:-}" ]] || {
  echo "fake claude: ANTHROPIC_BASE_URL leaked" >&2
  exit 93
}
printf 'claude\t%s\n' "$*" >>"${FAKE_CLI_LOG:?}"

if [[ "${1:-}" == auth && "${2:-}" == status ]]; then
  if [[ "${FAKE_AUTH_FAIL:-0}" == 1 ]]; then
    printf '{"loggedIn":false}\n'
  elif [[ "${FAKE_AUTH_MODE:-subscription}" == api ]]; then
    printf '{"loggedIn":true,"authMethod":"apiKey","subscriptionType":null}\n'
  else
    printf '{"loggedIn":true,"authMethod":"claude.ai","subscriptionType":"fake"}\n'
  fi
  exit 0
fi

case "${FAKE_MODEL_MODE:-classify}" in
  fail)
    echo "synthetic model failure" >&2
    exit 42
    ;;
  malformed)
    echo "this is not JSONL"
    exit 0
    ;;
esac

prompt="${2:-}"
expect="$(python3 - "${FAKE_PROMPTS_FILE:?}" "$prompt" <<'PY'
import json
import sys

entries = json.load(open(sys.argv[1]))
matches = [entry["expect"] for entry in entries if entry["prompt"] == sys.argv[2]]
if len(matches) != 1:
    raise SystemExit("fake claude: prompt was not found exactly once")
print(matches[0])
PY
)"
if [[ "$expect" == trigger ]]; then
  printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"cdm-dev"}}]}}'
else
  printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"text","text":"No matching skill."}]}}'
fi
SH

cat >"$fake_bin/codex" <<'SH'
#!/usr/bin/env bash
set -uo pipefail

[[ -z "${OPENAI_API_KEY:-}" ]] || {
  echo "fake codex: OPENAI_API_KEY leaked" >&2
  exit 90
}
[[ -z "${CODEX_API_KEY:-}" ]] || {
  echo "fake codex: CODEX_API_KEY leaked" >&2
  exit 91
}
[[ -z "${CODEX_ACCESS_TOKEN:-}" ]] || {
  echo "fake codex: CODEX_ACCESS_TOKEN leaked" >&2
  exit 92
}
[[ -z "${OPENAI_BASE_URL:-}" ]] || {
  echo "fake codex: OPENAI_BASE_URL leaked" >&2
  exit 93
}
printf 'codex\t%s\n' "$*" >>"${FAKE_CLI_LOG:?}"

if [[ "${1:-}" == login && "${2:-}" == status ]]; then
  if [[ "${FAKE_AUTH_FAIL:-0}" == 1 ]]; then
    exit 1
  elif [[ "${FAKE_AUTH_MODE:-subscription}" == api ]]; then
    echo "Logged in using an API key" >&2
  else
    echo "Logged in using ChatGPT" >&2
  fi
  exit
fi

case "${FAKE_MODEL_MODE:-classify}" in
  fail)
    echo "synthetic model failure" >&2
    exit 42
    ;;
  malformed)
    echo "this is not JSONL"
    exit 0
    ;;
esac

prompt="${!#}"
expect="$(python3 - "${FAKE_PROMPTS_FILE:?}" "$prompt" <<'PY'
import json
import sys

entries = json.load(open(sys.argv[1]))
matches = [entry["expect"] for entry in entries if entry["prompt"] == sys.argv[2]]
if len(matches) != 1:
    raise SystemExit("fake codex: prompt was not found exactly once")
print(matches[0])
PY
)"
if [[ "$expect" == trigger ]]; then
  printf '%s\n' '{"type":"item.completed","item":{"type":"command_execution","command":"sed -n 1,80p .agents/skills/cdm-dev/SKILL.md"}}'
else
  printf '%s\n' '{"type":"item.completed","item":{"type":"agent_message","text":"No matching skill."}}'
fi
SH
chmod +x "$fake_bin/claude" "$fake_bin/codex"

check_prompt_boundaries() {
  python3 - "$prompts" <<'PY'
import json
import sys

entries = json.load(open(sys.argv[1]))
by_expect = {
    expectation: {entry["id"] for entry in entries if entry["expect"] == expectation}
    for expectation in ("trigger", "no-trigger")
}
positive_boundaries = {
    "python-onboarding",
    "typescript-generated-api",
    "rune-runtime-function",
    "isda-conformance",
}
negative_boundaries = {
    "microsoft-cdm",
    "omop-cdm",
    "customer-data-model",
    "go-runes",
    "runescape-runes",
    "isda-legal-advice",
    "generic-repo-explanation",
    "generic-bond-pricer",
    "disaster-recovery-drr",
    "generic-reg-reporting",
    "fpml-element-lookup",
}
assert positive_boundaries <= by_expect["trigger"]
assert negative_boundaries <= by_expect["no-trigger"]
assert len(by_expect["trigger"]) == 13
assert len(by_expect["no-trigger"]) == 16
PY
}

make_fixture() {
  local mode="$1" destination="$2" fixture_runs="$3"
  python3 - "$prompts" "$destination" "$mode" "$fixture_runs" <<'PY'
import json
import sys
from pathlib import Path

prompts_path, output_path, mode, runs = sys.argv[1:5]
entries = json.load(open(prompts_path))
runs = int(runs)
lines = []
for entry in entries:
    correct = "triggered" if entry["expect"] == "trigger" else "quiet"
    verdict = correct if mode == "perfect" else ("quiet" if correct == "triggered" else "triggered")
    lines.extend(f"{entry['id']}\t{verdict}" for _ in range(runs))
Path(output_path).write_text("\n".join(lines) + "\n")
PY
}

assert_perfect_summary() {
  python3 - "$1" <<'PY'
import json
import sys

result = json.load(open(sys.argv[1]))
assert result["runs_per_prompt"] == 2
assert result["trigger_rate"] == 1.0
assert result["false_trigger_rate"] == 0.0
assert result["accuracy"] == 1.0
assert result["counts"] == {
    "prompts": 29,
    "trigger_prompts": 13,
    "no_trigger_prompts": 16,
}
PY
}

expect_ok "help documents subscription and no-model modes" \
  --stdout 'already-authenticated local' -- \
  "$runner" --help

expect_fail "vendor is required" \
  --stderr '--vendor is required' -- \
  "$runner" --dry-run

expect_fail "unknown vendors are rejected" \
  --stderr "unsupported vendor 'other'" -- \
  "$runner" --vendor other --dry-run

expect_fail "missing option values are rejected" \
  --stderr '--runs needs a value' -- \
  "$runner" --vendor claude --runs

expect_fail "run count must be positive" \
  --stderr 'positive integer' -- \
  "$runner" --vendor claude --runs 0 --dry-run

expect_fail "no-model modes are mutually exclusive" \
  --stderr 'mutually exclusive' -- \
  "$runner" --vendor claude --dry-run --check-auth

expect_ok "corpus contains positive boundaries and adversarial near misses" -- \
  check_prompt_boundaries

expect_ok "dry-run validates the plan without needing a CLI" \
  --stdout '29 prompts \(13 trigger, 16 no-trigger\)' -- \
  "$runner" --vendor claude --runs 2 --dry-run

perfect_fixture="$work/perfect.tsv"
perfect_results="$work/perfect-results.json"
make_fixture perfect "$perfect_fixture" 2
expect_ok "fixture mode scores a complete perfect corpus" \
  --stdout 'trigger_rate=1.00 false_trigger_rate=0.00 accuracy=1.00' -- \
  "$runner" --vendor claude --runs 2 \
  --fixture "$perfect_fixture" --results "$perfect_results"
expect_ok "fixture result records rates and corpus counts" -- \
  assert_perfect_summary "$perfect_results"

incomplete_fixture="$work/incomplete.tsv"
printf 'map-fpml-tradestate\ttriggered\n' >"$incomplete_fixture"
expect_fail "fixture mode rejects incomplete observations" \
  --stderr 'observations need exactly 1 run\(s\) per prompt' -- \
  "$runner" --vendor claude --fixture "$incomplete_fixture" \
  --results "$work/incomplete-results.json"

unknown_fixture="$work/unknown.tsv"
cp "$perfect_fixture" "$unknown_fixture"
printf 'not-a-prompt\tquiet\n' >>"$unknown_fixture"
expect_fail "fixture mode rejects unknown prompt ids" \
  --stderr 'unknown prompt id' -- \
  "$runner" --vendor claude --runs 2 --fixture "$unknown_fixture" \
  --results "$work/unknown-results.json"

drift_fixture="$work/drift.tsv"
make_fixture inverse "$drift_fixture" 1
expect_fail "baseline scoring rejects behavioral drift" \
  --stderr 'behavioral drift detected' -- \
  "$runner" --vendor claude --fixture "$drift_fixture" \
  --results "$work/drift-results.json"

auth_env=(
  env
  PATH="$fake_bin:$PATH"
  FAKE_CLI_LOG="$fake_log"
  FAKE_PROMPTS_FILE="$prompts"
  ANTHROPIC_API_KEY=must-not-reach-cli
  ANTHROPIC_AUTH_TOKEN=must-not-reach-cli
  CLAUDE_CODE_OAUTH_TOKEN=must-not-reach-cli
  ANTHROPIC_BASE_URL=must-not-reach-cli
  OPENAI_API_KEY=must-not-reach-cli
  CODEX_API_KEY=must-not-reach-cli
  CODEX_ACCESS_TOKEN=must-not-reach-cli
  OPENAI_BASE_URL=must-not-reach-cli
)

expect_ok "Claude auth preflight uses a local login without API env vars" \
  --stdout 'local subscription login is ready.*no model call' -- \
  "${auth_env[@]}" "$runner" --vendor claude --check-auth

expect_ok "Codex auth preflight uses a local login without API env vars" \
  --stdout 'local subscription login is ready.*no model call' -- \
  "${auth_env[@]}" "$runner" --vendor codex --check-auth

expect_fail "Claude preflight rejects a logged-out local session" \
  --stderr "run 'claude auth login'.*API credentials are not supported" -- \
  "${auth_env[@]}" FAKE_AUTH_FAIL=1 \
  "$runner" --vendor claude --check-auth

expect_fail "Codex preflight rejects a logged-out local session" \
  --stderr "run 'codex login'.*API credentials are not supported" -- \
  "${auth_env[@]}" FAKE_AUTH_FAIL=1 \
  "$runner" --vendor codex --check-auth

expect_fail "Claude preflight rejects an API-authenticated CLI" \
  --stderr 'not using a Claude.ai subscription' -- \
  "${auth_env[@]}" FAKE_AUTH_MODE=api \
  "$runner" --vendor claude --check-auth

expect_fail "Codex preflight rejects an API-authenticated CLI" \
  --stderr 'not using a ChatGPT subscription' -- \
  "${auth_env[@]}" FAKE_AUTH_MODE=api \
  "$runner" --vendor codex --check-auth

fake_claude_results="$work/fake-claude.json"
expect_ok "Claude detector recognizes only explicit Skill tool calls" \
  --stdout 'trigger_rate=1.00 false_trigger_rate=0.00 accuracy=1.00' -- \
  "${auth_env[@]}" FAKE_MODEL_MODE=classify \
  "$runner" --vendor claude --results "$fake_claude_results"

fake_codex_results="$work/fake-codex.json"
expect_ok "Codex proxy recognizes cdm-dev resource touches" \
  --stdout 'trigger_rate=1.00 false_trigger_rate=0.00 accuracy=1.00' -- \
  "${auth_env[@]}" FAKE_MODEL_MODE=classify \
  "$runner" --vendor codex --results "$fake_codex_results"

expect_fail "model CLI failure is not scored as a quiet result" \
  --stderr 'invocation failed for map-fpml-tradestate \(exit 42\)' -- \
  "${auth_env[@]}" FAKE_MODEL_MODE=fail \
  "$runner" --vendor claude --results "$work/failed-call.json"

expect_fail "malformed model JSONL is not scored as a quiet result" \
  --stderr 'could not parse codex JSONL for map-fpml-tradestate' -- \
  "${auth_env[@]}" FAKE_MODEL_MODE=malformed \
  "$runner" --vendor codex --results "$work/malformed-call.json"

finish
