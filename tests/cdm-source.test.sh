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
    jar.writestr(
        "cdm/rosetta/function-fixture.rosetta",
        """namespace cdm.function

import cdm.event.common.*

func ReadTrade:
  inputs:
    tradeState TradeState (1..1)
  output:
    result string (1..1)
  set result:
    tradeState -> trade

func Qualify_Trade: <"Fixture qualification.">
  [qualification TradeState]
  inputs:
    tradeState TradeState (1..1)
  output:
    is_event boolean (1..1)
  set is_event:
    tradeState exists
""",
    )
    jar.writestr(
        "cdm/rosetta/ambiguous-fixture.rosetta",
        """namespace cdm.other

type TradeState:
  value string (0..1)
""",
    )
    jar.writestr(
        "cdm/rosetta/kind-collision-fixture.rosetta",
        """namespace cdm.collision

type SharedDeclaration:
  amount number (1..1)

type SharedEnvelope:
  shared SharedDeclaration (1..1)

func SharedDeclaration:
  inputs:
    envelope SharedEnvelope (1..1)
  output:
    amount number (1..1)
  set amount:
    envelope -> shared -> amount
""",
    )
    jar.writestr(
        "cdm/rosetta/grammar-fixture.rosetta",
        """namespace cdm.grammar

import external.types.* as ext

enum MixedCaseEnum:
  lowerValue
  _30E_360 displayName "30E/360"
  UpperValue

type LowerRoute:
  value string (1..1)

choice RouteChoice:
  LowerRoute

type AliasedChild extends ext.ImportedBase:
  external ext.ExternalThing (0..1)

func ComplexFunction:
  [codeImplementation]
  inputs:
    external ext.ExternalThing (0..1)
  output:
    result LowerRoute (1..1)
  add result -> children:
    external
  set result -> value:
    if external exists
    then "yes"
    else if (external is absent)
    then "no"
  post-condition ResultExists:
    result exists

func ComplexFunction(external: ext.ExternalThing -> Active):
  [calculation]
  set result -> value:
    "active"

func CommentedFunction:
  [codeImplementation]
  inputs:
    value string (1..1)
  output:
    result string (1..1)
  set result:
    value

/* A block comment between declarations is captured with the preceding block.
 * Its continuation indentation must not replace Rune body indentation.
 */
func FollowingFunction:
  output:
    result string (1..1)
  set result:
    "following"
""",
    )
    jar.writestr(
        "cdm/rosetta/external-grammar-fixture.rosetta",
        """namespace external.types

type ImportedBase:
  inheritedValue string (0..1)

type ExternalThing:
  code string (1..1)
""",
    )
    huge_fields = "\n".join(
        f"  field{index} string (0..1)" for index in range(450)
    )
    jar.writestr(
        "cdm/rosetta/huge-fixture.rosetta",
        f"namespace cdm.huge\n\ntype Huge:\n{huge_fields}\n",
    )
    exact_type_fields = "\n".join(
        f"  field{index} string (0..1)" for index in range(1190)
    )
    over_type_fields = "\n".join(
        f"  field{index} string (0..1)" for index in range(1191)
    )
    exact_member_fields = "\n".join(
        f"  field{index} string (0..1)" for index in range(393)
    )
    over_member_fields = "\n".join(
        f"  field{index} string (0..1)" for index in range(394)
    )
    jar.writestr(
        "cdm/rosetta/output-boundary-fixture.rosetta",
        "namespace cdm.boundary\n\n"
        f"type ExactTypeBound:\n{exact_type_fields}\n\n"
        f"type OverTypeBound:\n{over_type_fields}\n\n"
        f"type ExactMemberBound:\n{exact_member_fields}\n\n"
        f"type OverMemberBound:\n{over_member_fields}\n",
    )
PY

expect_ok "version reports the release parsed from the JAR filename" \
  --stdout '^version=9\.9\.9$' -- \
  "$cdm_source" --jar "$fixture_jar" version

expect_ok "version falls back to the MANIFEST when the filename has no release" \
  --stdout '^version=5\.5\.5$' -- \
  "$cdm_source" --jar "$manifest_jar" version

renamed_manifest_jar="$work/cdm-java-canary.jar"
cp "$manifest_jar" "$renamed_manifest_jar"
expect_ok "a descriptive cdm-java filename does not override the MANIFEST version" \
  --stdout '^version=5\.5\.5$' -- \
  "$cdm_source" --jar "$renamed_manifest_jar" version

mismatched_version_jar="$work/cdm-java-4.4.4.jar"
cp "$manifest_jar" "$mismatched_version_jar"
expect_fail "a filename and manifest version disagreement fails closed" \
  --stderr 'version mismatch: filename says 4\.4\.4 but manifest says 5\.5\.5' -- \
  "$cdm_source" --jar "$mismatched_version_jar" version

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

expect_fail "type rejects more than eight declarations before inspection" \
  --stderr 'type accepts at most eight declarations' -- \
  "$cdm_source" --jar "$fixture_jar" type \
  TradeState TradeState TradeState TradeState TradeState \
  TradeState TradeState TradeState TradeState

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

function_batch() {
  local output
  output="$("$cdm_source" --jar "$fixture_jar" type \
    cdm.function.ReadTrade cdm.function.Qualify_Trade)" || return
  rg '^# java=cdm\.function\.functions\.ReadTrade$' <<<"$output" >/dev/null || return
  rg '^# resolved=cdm\.function\.Qualify_Trade kind=qualification$' \
    <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "type inspects exact Rune functions and identifies qualification functions" \
  --stdout '^  \[qualification TradeState\]$' -- function_batch

kind_collision_is_explicit() {
  local stdout_file="$work/kind-collision.stdout"
  local stderr_file="$work/kind-collision.stderr"
  if "$cdm_source" --jar "$fixture_jar" type \
    cdm.collision.SharedDeclaration >"$stdout_file" 2>"$stderr_file"; then
    return 1
  fi
  [[ ! -s "$stdout_file" ]] || return
  rg '^    type:cdm\.collision\.SharedDeclaration$' "$stderr_file" >/dev/null || return
  rg '^    func:cdm\.collision\.SharedDeclaration$' "$stderr_file" >/dev/null || return
  printf '%s\n' "$(<"$stderr_file")"
}
expect_ok "same-name data and function declarations report copyable kind selectors" \
  --stdout 'declaration name is ambiguous; use a kind-qualified candidate' -- \
  kind_collision_is_explicit

expect_ok "type selector retrieves the data declaration in a same-namespace collision" \
  --stdout '^# resolved=cdm\.collision\.SharedDeclaration kind=type$' -- \
  "$cdm_source" --jar "$fixture_jar" type \
  type:cdm.collision.SharedDeclaration

expect_ok "func selector retrieves the generated function mapping without guessing" \
  --stdout '^# java=cdm\.collision\.functions\.SharedDeclaration$' -- \
  "$cdm_source" --jar "$fixture_jar" type \
  func:cdm.collision.SharedDeclaration

expect_ok "qualification selector addresses an annotated function explicitly" \
  --stdout '^# resolved=cdm\.function\.Qualify_Trade kind=qualification$' -- \
  "$cdm_source" --jar "$fixture_jar" members \
  qualification:cdm.function.Qualify_Trade

expect_fail "an unknown declaration-kind selector fails during batch preflight" \
  --stderr 'invalid declaration kind selector' -- \
  "$cdm_source" --jar "$fixture_jar" type data:cdm.collision.SharedDeclaration

enum_members() {
  "$cdm_source" --jar "$fixture_jar" members cdm.grammar.MixedCaseEnum
}
expect_ok "enum members preserve lower-camel Rune values" \
  --stdout '^  lowerValue  # cdm/rosetta/grammar-fixture\.rosetta:' -- \
  enum_members

expect_ok "enum members preserve underscore-leading Rune values" \
  --stdout '^  _30E_360 displayName "30E/360"  # cdm/rosetta/grammar-fixture\.rosetta:' -- \
  enum_members

complex_function_members() {
  local output
  output="$("$cdm_source" --jar "$fixture_jar" members \
    cdm.grammar.ComplexFunction)" || return
  ! rg 'else if' <<<"$output" >/dev/null || return
  rg '^  \[codeImplementation\]  #' <<<"$output" >/dev/null || return
  rg '^    external ext\.ExternalThing \(0\.\.1\)  #' <<<"$output" >/dev/null || return
  rg '^  add result -> children:  #' <<<"$output" >/dev/null || return
  rg '^  set result -> value:  #' <<<"$output" >/dev/null || return
  rg '^func ComplexFunction\(external: ext\.ExternalThing -> Active\):  #' \
    <<<"$output" >/dev/null || return
  rg '^  \[calculation\]  #' <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "function members retain qualified parameters and structural headers only" \
  --stdout '^  post-condition ResultExists:  #' -- complex_function_members

commented_function_members() {
  "$cdm_source" --jar "$fixture_jar" members cdm.grammar.CommentedFunction
}
expect_ok "inter-declaration block comments do not hide function headers" \
  --stdout '^  inputs:  # cdm/rosetta/grammar-fixture\.rosetta:' -- \
  commented_function_members

expect_ok "inter-declaration block comments do not hide function annotations" \
  --stdout '^  \[codeImplementation\]  # cdm/rosetta/grammar-fixture\.rosetta:' -- \
  commented_function_members

expect_ok "inter-declaration block comments do not hide function set targets" \
  --stdout '^  set result:  # cdm/rosetta/grammar-fixture\.rosetta:' -- \
  commented_function_members

expect_ok "aliased dotted extends resolves the imported base declaration" \
  --stdout '^## inherited: external\.types\.ImportedBase$' -- \
  "$cdm_source" --jar "$fixture_jar" type cdm.grammar.AliasedChild

expect_ok "path traverses a field with an aliased dotted type reference" \
  --stdout '^external\.types\.ExternalThing\.code string \(1\.\.1\)  #' -- \
  "$cdm_source" --jar "$fixture_jar" path \
  cdm.grammar.AliasedChild external.code

expect_ok "path includes fields inherited through an aliased dotted base" \
  --stdout '^external\.types\.ImportedBase\.inheritedValue string \(0\.\.1\)  #' -- \
  "$cdm_source" --jar "$fixture_jar" path \
  cdm.grammar.AliasedChild inheritedValue

expect_ok "path traverses a choice through its lower-camel generated member" \
  --stdout '^cdm\.grammar\.RouteChoice\.lowerRoute LowerRoute \(choice\) -> cdm\.grammar\.LowerRoute  #' -- \
  "$cdm_source" --jar "$fixture_jar" path \
  cdm.grammar.RouteChoice lowerRoute.value

compact_members() {
  local output
  output="$("$cdm_source" --jar "$fixture_jar" members \
    cdm.function.Qualify_Trade cdm.event.common.ContingentTransfer)" || return
  rg '^  set is_event:  # cdm/rosetta/function-fixture\.rosetta:' \
    <<<"$output" >/dev/null || return
  ! rg '^    tradeState exists' <<<"$output" >/dev/null || return
  printf '%s\n' "$output"
}
expect_ok "members gives a compact exact outline without function bodies" \
  --stdout '^## inherited-members: cdm\.event\.common\.AssetFlowBase$' -- \
  compact_members

expect_ok "path follows an exact inherited member path without dumping declarations" \
  --stdout '^cdm\.event\.common\.AssetFlowBase\.unit UnitType \(1\.\.1\) -> cdm\.base\.math\.UnitType  #' -- \
  "$cdm_source" --jar "$fixture_jar" path \
  cdm.event.common.ContingentTransfer unit.currency

expect_ok "path resolves a model field even when a same-name function exists" \
  --stdout '^cdm\.collision\.SharedDeclaration\.amount number \(1\.\.1\)  #' -- \
  "$cdm_source" --jar "$fixture_jar" path \
  cdm.collision.SharedEnvelope shared.amount

expect_ok "path accepts an explicit type selector for a colliding root" \
  --stdout '^cdm\.collision\.SharedDeclaration\.amount number \(1\.\.1\)  #' -- \
  "$cdm_source" --jar "$fixture_jar" path \
  type:cdm.collision.SharedDeclaration amount

expect_fail "path fails clearly when a requested member is absent" \
  --stderr 'member path not found at cdm\.base\.math\.UnitType\.absent' -- \
  "$cdm_source" --jar "$fixture_jar" path \
  cdm.event.common.ContingentTransfer unit.absent

member_bound_is_atomic() {
  local stdout_file="$work/member-bound.stdout"
  local stderr_file="$work/member-bound.stderr"
  if "$cdm_source" --jar "$fixture_jar" members Huge \
    >"$stdout_file" 2>"$stderr_file"; then
    return 1
  fi
  [[ ! -s "$stdout_file" ]] || return
  rg 'would emit .* lines \(limit 400\); use the path command' \
    "$stderr_file" >/dev/null || return
  printf '%s\n' "$(<"$stderr_file")"
}
expect_ok "the compact view fails atomically and points oversized types to path" \
  --stdout 'use the path command' -- member_bound_is_atomic

exact_type_bound() {
  local output line_count
  output="$("$cdm_source" --jar "$fixture_jar" type ExactTypeBound)" || return
  line_count="$(awk 'END { print NR }' <<<"$output")"
  [[ "$line_count" -eq 1200 ]] || return 1
}
expect_ok "type permits a complete report exactly at the 1200-line bound" -- \
  exact_type_bound

expect_fail "type counts appended artifact metadata in its output bound" \
  --stderr 'would emit 1201 lines \(limit 1200\)' -- \
  "$cdm_source" --jar "$fixture_jar" type OverTypeBound

type_bound_is_atomic() {
  local stdout_file="$work/type-bound.stdout"
  local stderr_file="$work/type-bound.stderr"
  if "$cdm_source" --jar "$fixture_jar" type Huge Huge Huge \
    >"$stdout_file" 2>"$stderr_file"; then
    return 1
  fi
  [[ ! -s "$stdout_file" ]] || return
  rg 'would emit .* lines \(limit 1200\); use members or path' \
    "$stderr_file" >/dev/null || return
  printf '%s\n' "$(<"$stderr_file")"
}
expect_ok "type output fails atomically above its report bound" \
  --stdout 'use members or path' -- type_bound_is_atomic

exact_member_bound() {
  local output line_count
  output="$("$cdm_source" --jar "$fixture_jar" members ExactMemberBound)" || return
  line_count="$(awk 'END { print NR }' <<<"$output")"
  [[ "$line_count" -eq 400 ]] || return 1
}
expect_ok "members permits a complete report exactly at the 400-line bound" -- \
  exact_member_bound

expect_fail "members counts appended artifact metadata in its output bound" \
  --stderr 'would emit 401 lines \(limit 400\)' -- \
  "$cdm_source" --jar "$fixture_jar" members OverMemberBound

expect_ok "path retrieves one exact member from an otherwise oversized declaration" \
  --stdout '^cdm\.huge\.Huge\.field449 string \(0\.\.1\)  #' -- \
  "$cdm_source" --jar "$fixture_jar" path Huge field449

fake_bin="$work/fake-bin"
mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 97' >"$fake_bin/unzip"
chmod +x "$fake_bin/unzip"
batch_without_extraction() {
  PATH="$fake_bin:$PATH" \
    "$cdm_source" --jar "$fixture_jar" type \
    cdm.event.common.TradeState Transfer TransferStatusEnum
}
expect_ok "a multi-declaration type batch performs no filesystem extraction" \
  --stdout '^# resolved=cdm\.event\.common\.TransferStatusEnum kind=enum$' -- \
  batch_without_extraction

search_without_extraction() {
  PATH="$fake_bin:$PATH" \
    "$cdm_source" --jar "$fixture_jar" search '^type TradeState:'
}
expect_ok "search reads embedded sources without filesystem extraction" \
  --stdout 'type TradeState:' -- search_without_extraction

bounded_search() {
  local output line_count
  output="$("$cdm_source" --jar "$fixture_jar" search '^type ')" || return
  line_count="$(awk 'END { print NR }' <<<"$output")"
  [[ "$line_count" -le 160 ]] || return
  printf '%s\n' "$output"
}
expect_ok "broad search output is capped and tells the caller to refine it" \
  --stdout '^# cdm-source: search output truncated at 160 lines; refine the regex$' -- \
  bounded_search

batch_preflight_is_atomic() {
  local stdout_file="$work/preflight.stdout"
  local stderr_file="$work/preflight.stderr"
  if "$cdm_source" --jar "$fixture_jar" type \
    cdm.event.common.ContingentTransfer Missing TradeState AlsoMissing \
    >"$stdout_file" 2>"$stderr_file"; then
    return 1
  fi
  [[ ! -s "$stdout_file" ]] || return
  rg 'declaration not found: Missing' "$stderr_file" >/dev/null || return
  rg 'TradeState: declaration name is ambiguous' "$stderr_file" >/dev/null || return
  rg 'declaration not found: AlsoMissing' "$stderr_file" >/dev/null || return
  printf '%s\n' "$(<"$stderr_file")"
}
expect_ok "batch preflight reports every unresolved or ambiguous name atomically" \
  --stdout 'declaration batch preflight failed' -- batch_preflight_is_atomic

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

unmarked="$work/unmarked/nested"
unmarked_fake_bin="$work/unmarked-fake-bin"
find_sentinel="$work/find-was-called"
mkdir -p "$unmarked" "$unmarked_fake_bin"
# shellcheck disable=SC2016  # the generated sentinel expands FIND_SENTINEL at runtime
printf '%s\n' \
  '#!/usr/bin/env bash' \
  ': >"$FIND_SENTINEL"' \
  'exit 97' >"$unmarked_fake_bin/find"
chmod +x "$unmarked_fake_bin/find"
unmarked_discovery_fails_closed() {
  local output
  if output="$(
    cd "$unmarked" &&
      PATH="$unmarked_fake_bin:$PATH" FIND_SENTINEL="$find_sentinel" \
        "$cdm_source" version 2>&1
  )"; then
    return 1
  fi
  [[ ! -e "$find_sentinel" ]] || return
  printf '%s\n' "$output"
}
expect_ok "discovery refuses to scan when no project root marker exists" \
  --stdout 'refusing an unbounded filesystem scan' -- \
  unmarked_discovery_fails_closed

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
