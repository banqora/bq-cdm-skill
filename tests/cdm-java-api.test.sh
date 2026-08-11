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
javac -d "$work/api-classes" "$work/api-src/cdm/fixture/Widget.java"
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

expect_fail "at least one Java type is required" \
  --stderr 'provide at least one Java type' -- \
  "$cdm_api" --jar "$fixture_jar"

expect_fail "malformed type names are rejected before javap" \
  --stderr 'invalid Java type' -- \
  "$cdm_api" --jar "$fixture_jar" cdm/fixture/Widget

finish
