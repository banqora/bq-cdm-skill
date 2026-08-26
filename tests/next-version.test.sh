#!/usr/bin/env bash
# Hermetic tests for scripts/next-version: the release tag the CI tagger mints.
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
suite_name="next-version"
# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"

setup_work

next_version="$repo_root/scripts/next-version"
sandbox="$work/tag-repo"
mkdir -p "$sandbox"
git -C "$sandbox" init -q
git -C "$sandbox" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m one

run_in_sandbox() { (cd "$sandbox" && "$next_version"); }

expect_ok "an untagged history seeds v0.1.0" \
  --stdout '^v0\.1\.0$' -- run_in_sandbox

git -C "$sandbox" tag -a v0.1.0 -m t
expect_fail "an already tagged HEAD is refused" \
  --stderr "already tagged as v0.1.0" -- run_in_sandbox
(cd "$sandbox" && "$next_version" >/dev/null 2>&1)
status=$?
if [[ "$status" -eq 3 ]]; then
  report ok "the already-tagged refusal uses exit status 3"
else
  echo "  expected exit status 3; got $status" >&2
  report fail "the already-tagged refusal uses exit status 3"
fi

git -C "$sandbox" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m two
expect_ok "the patch number increments from the newest tag" \
  --stdout '^v0\.1\.1$' -- run_in_sandbox

git -C "$sandbox" tag -a v0.2.5 -m t
git -C "$sandbox" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m three
git -C "$sandbox" tag -a v0.10.2 -m t
git -C "$sandbox" -c user.name=t -c user.email=t@example.invalid commit -q --allow-empty -m four
expect_ok "tags sort by version so v0.10 beats v0.2" \
  --stdout '^v0\.10\.3$' -- run_in_sandbox

git -C "$sandbox" tag v0.10.3-notes HEAD~1
expect_ok "a non-release suffix tag does not disturb the increment" \
  --stdout '^v0\.10\.3$' -- run_in_sandbox

echo "$suite_name: $passed passed, $failed failed"
[[ "$failed" -eq 0 ]]
