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

python3 - "$fixture_jar" <<'PY'
import sys
import zipfile

with zipfile.ZipFile(sys.argv[1], "a") as jar:
    jar.writestr(
        "cdm/rosetta/event-choice-enum-fixture.rosetta",
        """namespace cdm.event.common

type CashTransfer:
  amount number (1..1)

type SecurityTransfer:
  identifier string (1..1)

choice Transfer:
  CashTransfer
  SecurityTransfer

enum TransferStatusEnum:
  Pending
  Settled
""",
    )
PY

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

expect_ok "type prints the complete requested declaration and its condition" \
  --stdout 'condition EventExists:' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.event.common.ContingentTransfer

expect_ok "type follows the inheritance chain" \
  --stdout '## inherited: cdm\.event\.common\.AssetFlowBase' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.event.common.ContingentTransfer

expect_ok "type lists sibling alternatives instead of encouraging a first-name match" \
  --stdout 'type ScheduledTransfer extends TransferBase:' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.event.common.ContingentTransfer

expect_ok "type exposes conditions on direct fields inherited from a parent" \
  --stdout 'AssetFlowBase\.unit -> cdm\.base\.math\.UnitType' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.event.common.ContingentTransfer

expect_ok "type warns that parent validation does not recurse into child conditions" \
  --stdout 'UnitType conditions: UnitType' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.event.common.ContingentTransfer

expect_ok "type hands off to a combined API query and populated compile" \
  --stdout '^# next=use one cdm-inspect batch, then compile a populated slice$' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.event.common.ContingentTransfer

batch_types() {
  local output
  output="$("$cdm_source" --jar "$fixture_jar" type \
    cdm.event.common.TradeState cdm.event.common.ContingentTransfer)" || return
  rg '^# requested=cdm\.event\.common\.TradeState$' <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "type accepts a bounded batch without a broad source search" \
  --stdout '^# requested=cdm\.event\.common\.ContingentTransfer$' -- batch_types

choice_and_enum_batch() {
  local output
  output="$("$cdm_source" --jar "$fixture_jar" type Transfer TransferStatusEnum)" || return
  rg '^# resolved=cdm\.event\.common\.Transfer kind=choice$' <<<"$output" >/dev/null || return
  rg '^cdm\.event\.common\.CashTransfer  #' <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "one batch resolves Rune choices and enums as well as types" \
  --stdout '^# resolved=cdm\.event\.common\.TransferStatusEnum kind=enum$' -- \
  choice_and_enum_batch

fake_bin="$work/fake-bin"
mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 97' >"$fake_bin/unzip"
chmod +x "$fake_bin/unzip"
batch_without_extraction() {
  PATH="$fake_bin:$PATH" \
    "$cdm_source" --jar "$fixture_jar" type TradeState Transfer TransferStatusEnum
}
expect_ok "a multi-declaration type batch performs no filesystem extraction" \
  --stdout '^# resolved=cdm\.event\.common\.TransferStatusEnum kind=enum$' -- \
  batch_without_extraction

expect_fail "type rejects an unknown declaration clearly" \
  --stderr 'declaration not found: cdm\.event\.common\.Absent' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.event.common.Absent

expect_ok "show dumps a named Rosetta source" \
  --stdout 'namespace cdm\.event\.common' -- \
  "$cdm_source" --jar "$fixture_jar" show cdm/rosetta/event-common-type.rosetta

expect_fail "show rejects an entry that is not in the JAR" \
  --stderr "is not a Rosetta source" -- \
  "$cdm_source" --jar "$fixture_jar" show cdm/rosetta/absent.rosetta

expect_fail "a JAR without embedded Rosetta sources is rejected" \
  --stderr "contains no embedded cdm/rosetta sources" -- \
  "$cdm_source" --jar "$no_rosetta_jar" version

sources_named_jar="$work/cdm-java-9.9.9-sources.jar"
cp "$fixture_jar" "$sources_named_jar"
expect_fail "an explicit generated-Java sources JAR gets a binary-JAR correction" \
  --stderr "pass the binary cdm-java JAR" -- \
  "$cdm_source" --jar "$sources_named_jar" version

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
