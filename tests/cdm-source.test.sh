#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skill_dir="$repo_root/skills/cdm-dev"
cdm_source="$skill_dir/scripts/cdm-source"
suite_name="cdm-source"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"
# shellcheck source=tests/fixtures.sh
source "$script_dir/fixtures.sh"

setup_work
build_fixture_jars

expect_ok "version reports the release parsed from the JAR filename" \
  --stdout '^version=9\.9\.9$' -- \
  "$cdm_source" --jar "$fixture_jar" version

expect_ok "version falls back to the MANIFEST when the filename has no release" \
  --stdout '^version=5\.5\.5$' -- \
  "$cdm_source" --jar "$manifest_jar" version

expect_ok "jar prints the canonical path" \
  --stdout 'cdm-java-9\.9\.9\.jar$' -- \
  "$cdm_source" --jar "$fixture_jar" jar

expect_ok "list filters Rosetta entries by regex" \
  --stdout '^cdm/rosetta/event-common-type\.rosetta$' -- \
  "$cdm_source" --jar "$fixture_jar" list 'event-common'

expect_ok "search locates a declaration with context" \
  --stdout 'type TradeState:' -- \
  "$cdm_source" --jar "$fixture_jar" search '^type TradeState:'

expect_ok "show dumps a named Rosetta source" \
  --stdout 'namespace cdm\.event\.common' -- \
  "$cdm_source" --jar "$fixture_jar" show cdm/rosetta/event-common-type.rosetta

expect_fail "show rejects an entry that is not in the JAR" \
  --stderr "is not a Rosetta source" -- \
  "$cdm_source" --jar "$fixture_jar" show cdm/rosetta/absent.rosetta

expect_fail "a JAR without embedded Rosetta sources is rejected" \
  --stderr "contains no embedded cdm/rosetta sources" -- \
  "$cdm_source" --jar "$no_rosetta_jar" version

expect_fail "a missing --jar path is rejected" \
  --stderr "JAR does not exist" -- \
  "$cdm_source" --jar "$work/absent.jar" version

env_select() {
  (cd "$work" && CDM_JAVA_JAR="$fixture_jar" "$cdm_source" version)
}
expect_ok "CDM_JAVA_JAR selects the JAR when --jar is absent" \
  --stdout '^version=9\.9\.9$' -- env_select

flag_beats_env() {
  CDM_JAVA_JAR="$no_rosetta_jar" "$cdm_source" --jar "$fixture_jar" version
}
expect_ok "--jar takes precedence over CDM_JAVA_JAR" \
  --stdout '^version=9\.9\.9$' -- flag_beats_env

project="$(make_project_sandbox discovery)"
discover_single() {
  (cd "$project" && "$cdm_source" version)
}
expect_ok "discovery finds a single project JAR" \
  --stdout '^version=9\.9\.9$' -- discover_single

pruned="$(make_project_sandbox pruned)"
mkdir -p "$pruned/.claude/stash"
cp "$fixture_jar" "$pruned/.claude/stash/cdm-java-7.7.7.jar"
discover_pruned() {
  (cd "$pruned" && "$cdm_source" version)
}
expect_ok "discovery ignores JARs under agent config directories" \
  --stdout '^version=9\.9\.9$' -- discover_pruned

# shellcheck disable=SC2016  # the inner bash -c expands these, not this shell
expect_ok "discovery ignores sources/javadoc companions" \
  --stdout '^version=9\.9\.9$' -- \
  bash -c \
  'cp "$1/lib/cdm-java-9.9.9.jar" "$1/lib/cdm-java-9.9.9-sources.jar" && cd "$1" && "$2" version' \
  _ "$project" "$cdm_source"

# shellcheck disable=SC2016  # the inner bash -c expands these, not this shell
expect_fail "discovery refuses to choose between two candidate JARs" \
  --stderr "multiple cdm-java JARs" -- \
  bash -c \
  'cp "$1/lib/cdm-java-9.9.9.jar" "$1/lib/cdm-java-8.8.8.jar" && cd "$1" && "$2" version' \
  _ "$project" "$cdm_source"

finish
