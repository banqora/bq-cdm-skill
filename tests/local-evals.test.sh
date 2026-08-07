#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
runner="$repo_root/evals/run-local"
suite_name="local-evals"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work
fake_bin="$work/bin"
mkdir -p "$fake_bin"

# shellcheck disable=SC2016  # variables expand when the generated fake CLI runs
printf '%s\n' \
  '#!/usr/bin/env bash' \
  '[[ -z "${ANTHROPIC_API_KEY:-}" && -z "${ANTHROPIC_AUTH_TOKEN:-}" && -z "${ANTHROPIC_BASE_URL:-}" ]] || exit 9' \
  'printf '\''{"loggedIn":true,"authMethod":"claude.ai","subscriptionType":"max"}\n'\''' \
  >"$fake_bin/claude"
# shellcheck disable=SC2016  # variables expand when the generated fake CLI runs
printf '%s\n' \
  '#!/usr/bin/env bash' \
  '[[ -z "${OPENAI_API_KEY:-}" && -z "${CODEX_API_KEY:-}" && -z "${CODEX_ACCESS_TOKEN:-}" && -z "${OPENAI_BASE_URL:-}" ]] || exit 9' \
  'printf '\''Logged in using ChatGPT\n'\''' \
  >"$fake_bin/codex"
chmod +x "$fake_bin/claude" "$fake_bin/codex"

expect_ok "auth preflight accepts saved subscriptions and removes API overrides" \
  --stdout 'claude subscription login verified' -- \
  env PATH="$fake_bin:$PATH" ANTHROPIC_API_KEY=ignored ANTHROPIC_BASE_URL=ignored \
  OPENAI_API_KEY=ignored OPENAI_BASE_URL=ignored CODEX_ACCESS_TOKEN=ignored \
  "$runner" --vendor all --check-auth

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf '\''Logged in using an API key\n'\''' \
  >"$fake_bin/codex"
chmod +x "$fake_bin/codex"
expect_fail "auth preflight rejects API-key Codex login" \
  --stderr 'not using ChatGPT subscription auth' -- \
  env PATH="$fake_bin:$PATH" "$runner" --vendor codex --check-auth

expect_fail "runner validates run counts before model calls" \
  --stderr 'positive integer' -- \
  "$runner" --vendor claude --runs 0

expect_fail "runner requires paired custom quality artifacts" \
  --stderr 'require --jar and --sources-jar together' -- \
  "$runner" --vendor claude --quality-only --jar fixture.jar

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf '\''{"loggedIn":true,"authMethod":"claude.ai","subscriptionType":"max"}\n'\''' \
  >"$fake_bin/claude"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf '\''Logged in using ChatGPT\n'\'' >&2' \
  >"$fake_bin/codex"
chmod +x "$fake_bin/claude" "$fake_bin/codex"

runner_copy="$work/runner"
mkdir -p "$runner_copy"
cp "$runner" "$runner_copy/run-local"
cat >"$runner_copy/run-triggers" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${STUB_LOG:?}"
[[ "$*" != *"--vendor claude"* ]]
SH
chmod +x "$runner_copy/run-triggers"
vendor_log="$work/vendors.log"
expect_fail "all-vendor runs retain failure after attempting every vendor" \
  --stderr '' -- \
  env PATH="$fake_bin:$PATH" STUB_LOG="$vendor_log" \
  "$runner_copy/run-local" --vendor all --triggers-only
expect_ok "all-vendor runs continue to Codex after a Claude failure" \
  --stdout '--vendor codex' -- \
  grep -- '--vendor codex' "$vendor_log"

finish
