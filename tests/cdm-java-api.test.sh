#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skill_dir="$repo_root/skills/cdm-dev"
cdm_api="$skill_dir/scripts/cdm-java-api"
suite_name="cdm-java-api"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"
# shellcheck source=tests/fixtures.sh
source "$script_dir/fixtures.sh"

setup_work
build_fixture_jars

mkdir -p "$work/api-src/cdm/fixture" "$work/api-classes"
printf '%s\n' \
  'package cdm.fixture;' \
  'public interface Widget {' \
  '  String getValue();' \
  '  interface WidgetBuilder extends Widget {' \
  '    WidgetBuilder setValue(String value);' \
  '  }' \
  '}' >"$work/api-src/cdm/fixture/Widget.java"
printf '%s\n' \
  'package cdm.fixture;' \
  'public interface Calculate {' \
  '  String evaluate(String input);' \
  '  class CalculateDefault implements Calculate {' \
  '    public String evaluate(String input) { return input; }' \
  '  }' \
  '}' >"$work/api-src/cdm/fixture/Calculate.java"
{
  printf '%s\n' 'package cdm.fixture;' 'public interface ExactApiBound {'
  for index in $(seq 1 1197); do
    printf '  void method%s();\n' "$index"
  done
  printf '%s\n' '}'
} >"$work/api-src/cdm/fixture/ExactApiBound.java"
{
  printf '%s\n' 'package cdm.fixture;' 'public interface OverApiBound {'
  for index in $(seq 1 1198); do
    printf '  void method%s();\n' "$index"
  done
  printf '%s\n' '}'
} >"$work/api-src/cdm/fixture/OverApiBound.java"
javac -d "$work/api-classes" \
  "$work/api-src/cdm/fixture/Widget.java" \
  "$work/api-src/cdm/fixture/Calculate.java" \
  "$work/api-src/cdm/fixture/ExactApiBound.java" \
  "$work/api-src/cdm/fixture/OverApiBound.java"
jar --update --file "$fixture_jar" -C "$work/api-classes" .

mkdir -p "$work/api-src/cdm/other"
printf '%s\n' \
  'package cdm.other;' \
  'public interface Duplicate {}' >"$work/api-src/cdm/other/Duplicate.java"
printf '%s\n' \
  'package cdm.fixture;' \
  'public interface Duplicate {}' >"$work/api-src/cdm/fixture/Duplicate.java"
javac -d "$work/api-classes" \
  "$work/api-src/cdm/other/Duplicate.java" "$work/api-src/cdm/fixture/Duplicate.java"
jar --update --file "$fixture_jar" -C "$work/api-classes" .

mkdir -p "$work/runtime-src/com/rosetta/model/lib/records" "$work/runtime-classes"
printf '%s\n' \
  'package com.rosetta.model.lib.records;' \
  'public final class Date {' \
  '  private Date() {}' \
  '  public static Date of(int year, int month, int day) { return new Date(); }' \
  '}' >"$work/runtime-src/com/rosetta/model/lib/records/Date.java"
javac -d "$work/runtime-classes" "$work/runtime-src/com/rosetta/model/lib/records/Date.java"
runtime_jar="$work/rune-runtime-fixture.jar"
jar --create --file "$runtime_jar" -C "$work/runtime-classes" .

# shellcheck disable=SC2016  # the dollar sign is part of javap's nested-type name
expect_ok "one pass prints a generated type and its matching builder" \
  --stdout 'public interface cdm\.fixture\.Widget\$WidgetBuilder' -- \
  "$cdm_api" --jar "$fixture_jar" cdm.fixture.Widget

expect_ok "the generated getter is visible" \
  --stdout 'public abstract java\.lang\.String getValue\(\)' -- \
  "$cdm_api" --jar "$fixture_jar" cdm.fixture.Widget

# shellcheck disable=SC2016  # the dollar sign is part of javap's nested-type name
expect_ok "a generated function includes its matching default implementation" \
  --stdout 'public class cdm\.fixture\.Calculate\$CalculateDefault' -- \
  "$cdm_api" --jar "$fixture_jar" cdm.fixture.Calculate

expect_ok "an unambiguous simple name resolves to its exact Java package" \
  --stdout '^# requested=Widget resolved=cdm\.fixture\.Widget$' -- \
  "$cdm_api" --jar "$fixture_jar" Widget

expect_fail "an ambiguous simple name lists candidates instead of guessing a package" \
  --stderr 'Java type name is ambiguous; use a fully qualified name' -- \
  "$cdm_api" --jar "$fixture_jar" Duplicate

expect_fail "an absent simple name fails before javap" \
  --stderr 'Java type not found in selected JAR: Missing' -- \
  "$cdm_api" --jar "$fixture_jar" Missing

env_jar() {
  CDM_JAVA_JAR="$fixture_jar" "$cdm_api" cdm.fixture.Widget
}
# shellcheck disable=SC2016  # the dollar sign is part of javap's nested-type name
expect_ok "CDM_JAVA_JAR works without an explicit --jar on Bash 3.2" \
  --stdout 'public interface cdm\.fixture\.Widget\$WidgetBuilder' -- env_jar

expect_ok "an explicit project runtime classpath resolves support types" \
  --stdout 'public static com\.rosetta\.model\.lib\.records\.Date of\(int, int, int\)' -- \
  "$cdm_api" --jar "$fixture_jar" --classpath "$runtime_jar" \
  com.rosetta.model.lib.records.Date

env_classpath() {
  CDM_JAVA_CLASSPATH="$runtime_jar" \
    "$cdm_api" --jar "$fixture_jar" com.rosetta.model.lib.records.Date
}
expect_ok "CDM_JAVA_CLASSPATH supplies project-resolved runtime dependencies" \
  --stdout 'com\.rosetta\.model\.lib\.records\.Date' -- env_classpath

expect_fail "a missing Rune runtime type gets an actionable classpath hint" \
  --stderr 'add the project.s resolved rune-runtime JAR with --classpath' -- \
  "$cdm_api" --jar "$fixture_jar" com.rosetta.model.lib.records.Date

expect_fail "a missing runtime forbids global-cache scavenging" \
  --stderr 'do not search global caches or guess a runtime version' -- \
  "$cdm_api" --jar "$fixture_jar" com.rosetta.model.lib.records.Date

stub_bin="$work/stub-bin"
mkdir -p "$stub_bin"
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'echo "Unable to locate a Java Runtime." >&2' \
  'exit 1' >"$stub_bin/javap"
chmod +x "$stub_bin/javap"
javap_stub_gets_jdk_guidance() {
  local output
  if output="$(PATH="$stub_bin:$PATH" \
    "$cdm_api" --jar "$fixture_jar" cdm.fixture.Widget 2>&1)"; then
    return 1
  fi
  ! rg 'add the project.s resolved rune-runtime' <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "a platform javap launcher without a JDK gets configuration guidance" \
  --stdout 'install a JDK, then set JAVA_HOME' -- javap_stub_gets_jdk_guidance

expect_fail "at least one Java type is required" \
  --stderr 'provide at least one Java type' -- \
  "$cdm_api" --jar "$fixture_jar"

expect_fail "more than eight requested Java types are rejected before inspection" \
  --stderr 'at most 8 Java types' -- \
  "$cdm_api" --jar "$fixture_jar" \
  Widget Widget Widget Widget Widget Widget Widget Widget Widget

expect_fail "malformed type names are rejected before javap" \
  --stderr 'invalid Java type' -- \
  "$cdm_api" --jar "$fixture_jar" cdm/fixture/Widget

api_preflight_is_atomic() {
  local stdout_file="$work/api-preflight.stdout"
  local stderr_file="$work/api-preflight.stderr"
  if "$cdm_api" --jar "$fixture_jar" \
    Widget Missing Duplicate bad/name AlsoMissing \
    >"$stdout_file" 2>"$stderr_file"; then
    return 1
  fi
  [[ ! -s "$stdout_file" ]] || return
  rg 'Java type not found in selected JAR: Missing' "$stderr_file" >/dev/null || return
  rg 'Java type name is ambiguous.*Duplicate' "$stderr_file" >/dev/null || return
  rg 'invalid Java type: bad/name' "$stderr_file" >/dev/null || return
  rg 'Java type not found in selected JAR: AlsoMissing' "$stderr_file" >/dev/null || return
  printf '%s\n' "$(<"$stderr_file")"
}
expect_ok "type preflight reports every bad simple name without partial API output" \
  --stdout 'type batch preflight failed' -- api_preflight_is_atomic

exact_api_bound() {
  local output line_count
  output="$("$cdm_api" --jar "$fixture_jar" cdm.fixture.ExactApiBound)" || return
  line_count="$(awk 'END { print NR }' <<<"$output")"
  [[ "$line_count" -eq 1200 ]] || return 1
}
expect_ok "API inspection permits exact output at the 1200-line bound" -- \
  exact_api_bound

api_output_bound_is_atomic() {
  local stdout_file="$work/api-output-bound.stdout"
  local stderr_file="$work/api-output-bound.stderr"
  if "$cdm_api" --jar "$fixture_jar" cdm.fixture.OverApiBound \
    >"$stdout_file" 2>"$stderr_file"; then
    return 1
  fi
  [[ ! -s "$stdout_file" ]] || return 1
  rg 'exact API inspection would emit 1201 lines \(limit 1200\)' \
    "$stderr_file" >/dev/null || return 1
  printf '%s\n' "$(<"$stderr_file")"
}
expect_ok "API output above the bound fails without partial output" \
  --stdout 'output was not truncated' -- api_output_bound_is_atomic

finish
