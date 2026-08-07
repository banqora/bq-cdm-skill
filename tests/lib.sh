#!/usr/bin/env bash
# Shared test harness for tests/*.test.sh; source this file, do not execute it.

suite_name="${suite_name:-tests}"
passed=0
failed=0
work=""
link_server_pid=""

setup_work() {
  for required_tool in python3 rg zipinfo unzip; do
    command -v "$required_tool" >/dev/null || {
      echo "$suite_name: required command is not installed: $required_tool" >&2
      exit 1
    }
  done
  work="$(mktemp -d "${TMPDIR:-/tmp}/cdm-skill-tests.XXXXXX")"
  trap teardown EXIT
}

teardown() {
  if [[ -n "$link_server_pid" ]]; then
    kill "$link_server_pid" 2>/dev/null || true
    wait "$link_server_pid" 2>/dev/null || true
  fi
  [[ -n "$work" ]] && rm -rf -- "$work"
}

report() {
  local status="$1" name="$2"
  if [[ "$status" == ok ]]; then
    passed=$((passed + 1))
    echo "ok   $name"
  else
    failed=$((failed + 1))
    echo "FAIL $name"
  fi
}

# expect_ok NAME [--stdout REGEX] -- CMD...
expect_ok() {
  local name="$1" stdout_regex="" output
  shift
  if [[ "$1" == --stdout ]]; then
    stdout_regex="$2"
    shift 2
  fi
  [[ "$1" == -- ]] && shift
  if output="$("$@" 2>&1)"; then
    if [[ -z "$stdout_regex" ]] || grep -qE -- "$stdout_regex" <<<"$output"; then
      report ok "$name"
      return
    fi
    echo "  expected output matching: $stdout_regex" >&2
  fi
  printf '%s\n' "$output" | sed 's/^/  /' >&2
  report fail "$name"
}

# expect_fail NAME [--stderr REGEX] -- CMD...
expect_fail() {
  local name="$1" stderr_regex="" output
  shift
  if [[ "$1" == --stderr ]]; then
    stderr_regex="$2"
    shift 2
  fi
  [[ "$1" == -- ]] && shift
  if output="$("$@" 2>&1)"; then
    echo "  expected failure but command succeeded" >&2
    printf '%s\n' "$output" | sed 's/^/  /' >&2
    report fail "$name"
    return
  fi
  if [[ -n "$stderr_regex" ]] && ! grep -qE -- "$stderr_regex" <<<"$output"; then
    echo "  expected failure output matching: $stderr_regex" >&2
    printf '%s\n' "$output" | sed 's/^/  /' >&2
    report fail "$name"
    return
  fi
  report ok "$name"
}

finish() {
  echo "$suite_name: $passed passed, $failed failed"
  [[ "$failed" -eq 0 ]]
}
