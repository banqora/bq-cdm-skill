#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skill_dir="$repo_root/skills/cdm-dev"
cdm_inspect="$skill_dir/scripts/cdm-inspect"
suite_name="cdm-inspect"

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
        "cdm/rosetta/inspect-fixture.rosetta",
        """namespace cdm.inspect

type Amount:
  value number (1..1)
  condition Positive:
    value > 0

type Base:
  amount Amount (1..1)

type Envelope extends Base:
  label string (1..1)
  code string (0..1)
  condition:
    one-of

type EnvelopeDetail:
  detail string (1..1)

type Scheduled:
  value string (1..1)

type Unscheduled:
  value string (1..1)

choice Transfer:
  Scheduled
  Unscheduled

enum Mode:
  Gross
  Netted
""",
    )
    jar.writestr(
        "cdm/rosetta/inspect-ambiguous-fixture.rosetta",
        """namespace cdm.other

type TradeState:
  value string (0..1)
""",
    )
    huge_fields = "\n".join(
        f"  field{index} string (0..1)" for index in range(1201)
    )
    jar.writestr(
        "cdm/rosetta/inspect-bound-fixture.rosetta",
        f"namespace cdm.inspect\n\ntype Huge:\n{huge_fields}\n",
    )
PY

mkdir -p \
  "$work/api-src/cdm/inspect" \
  "$work/api-src/cdm/inspect/meta" \
  "$work/api-src/cdm/inspect/validation/exists" \
  "$work/api-src/cdm/inspect/validation/datarule" \
  "$work/api-classes"

printf '%s\n' \
  'package cdm.inspect;' \
  'public interface Envelope {' \
  '  String getLabel();' \
  '  interface EnvelopeBuilder extends Envelope {' \
  '    EnvelopeBuilder setLabel(String value);' \
  '  }' \
  '}' >"$work/api-src/cdm/inspect/Envelope.java"
printf '%s\n' \
  'package cdm.inspect;' \
  'public interface Transfer {' \
  '  String getScheduled();' \
  '  interface TransferBuilder extends Transfer {' \
  '    TransferBuilder setScheduled(String value);' \
  '  }' \
  '}' >"$work/api-src/cdm/inspect/Transfer.java"
printf '%s\n' \
  'package cdm.inspect;' \
  'public enum Mode { GROSS, NETTED }' >"$work/api-src/cdm/inspect/Mode.java"
printf '%s\n' \
  'package cdm.inspect;' \
  'public interface EnvelopeDetail {' \
  '  String getDetail();' \
  '}' >"$work/api-src/cdm/inspect/EnvelopeDetail.java"
printf '%s\n' \
  'package cdm.inspect;' \
  'public interface Huge {}' >"$work/api-src/cdm/inspect/Huge.java"
printf '%s\n' \
  'package cdm.inspect.meta;' \
  'class EnvelopeMeta {' \
  '  cdm.inspect.validation.datarule.EnvelopeOneOf0 anonymousRule;' \
  '}' \
  'class EnvelopeDetailMeta {' \
  '  cdm.inspect.validation.datarule.EnvelopeDetailSpecific specificRule;' \
  '}' \
  'class BaseMeta {}' \
  'class AmountMeta {' \
  '  cdm.inspect.validation.datarule.AmountPositive positiveRule;' \
  '}' \
  'class TransferMeta {' \
  '  cdm.inspect.validation.datarule.TransferChoice choiceRule;' \
  '}' >"$work/api-src/cdm/inspect/meta/Support.java"
printf '%s\n' \
  'package cdm.inspect.validation;' \
  'class EnvelopeValidator {}' \
  'class EnvelopeTypeFormatValidator {}' \
  'class BaseValidator {}' \
  'class BaseTypeFormatValidator {}' \
  'class AmountValidator {}' \
  'class AmountTypeFormatValidator {}' \
  'class TransferValidator {}' \
  'class TransferTypeFormatValidator {}' >"$work/api-src/cdm/inspect/validation/Support.java"
printf '%s\n' \
  'package cdm.inspect.validation.exists;' \
  'class EnvelopeOnlyExistsValidator {}' \
  'class BaseOnlyExistsValidator {}' \
  'class AmountOnlyExistsValidator {}' \
  'class TransferOnlyExistsValidator {}' >"$work/api-src/cdm/inspect/validation/exists/Support.java"
for rule_class in AmountPositive EnvelopeDetailSpecific EnvelopeOneOf0 TransferChoice; do
  printf '%s\n' \
    'package cdm.inspect.validation.datarule;' \
    "public class $rule_class {}" \
    >"$work/api-src/cdm/inspect/validation/datarule/$rule_class.java"
done

javac -d "$work/api-classes" \
  "$work/api-src/cdm/inspect/"*.java \
  "$work/api-src/cdm/inspect/meta/"*.java \
  "$work/api-src/cdm/inspect/validation/"*.java \
  "$work/api-src/cdm/inspect/validation/exists/"*.java \
  "$work/api-src/cdm/inspect/validation/datarule/"*.java
jar --update --file "$fixture_jar" -C "$work/api-classes" .

inspect_slice() {
  "$cdm_inspect" --jar "$fixture_jar" Envelope EnvelopeDetail Transfer Mode
}

expect_ok "the report records the exact selected CDM version" \
  --stdout '^# cdm-inspect version=9\.9\.9 jar=' -- inspect_slice

expect_ok "one invocation prints an exact Rune inheritance slice" \
  --stdout '^## inherited: cdm\.inspect\.Base$' -- inspect_slice

expect_ok "one invocation exposes conditioned child declarations" \
  --stdout '^cdm\.inspect\.Base\.amount -> cdm\.inspect\.Amount$' -- inspect_slice

# shellcheck disable=SC2016  # the dollar sign is part of javap's nested-type name
expect_ok "one invocation prints generated getters and builders" \
  --stdout 'public interface cdm\.inspect\.Envelope\$EnvelopeBuilder' -- inspect_slice

expect_ok "one invocation resolves choices and their implicit data rule" \
  --stdout '^data_rule=cdm\.inspect\.validation\.datarule\.TransferChoice$' -- inspect_slice

expect_ok "one invocation lists exact child data-rule classes" \
  --stdout '^data_rule=cdm\.inspect\.validation\.datarule\.AmountPositive$' -- inspect_slice

expect_ok "anonymous Rune conditions use the exact generated numbered data-rule class" \
  --stdout '^data_rule=cdm\.inspect\.validation\.datarule\.EnvelopeOneOf0$' -- \
  inspect_slice

longest_owner_assignment() {
  local output envelope_block detail_block
  output="$(inspect_slice)" || return
  envelope_block="$(
    awk '
      /^### cdm\.inspect\.Envelope$/ { active = 1; next }
      /^### / && active { exit }
      active
    ' <<<"$output"
  )"
  detail_block="$(
    awk '
      /^### cdm\.inspect\.EnvelopeDetail$/ { active = 1; next }
      /^### / && active { exit }
      active
    ' <<<"$output"
  )"
  ! rg 'EnvelopeDetailSpecific' <<<"$envelope_block" >/dev/null || return
  rg 'EnvelopeDetailSpecific' <<<"$detail_block"
}
expect_ok "a rule is assigned through its exact generated Meta registration" \
  --stdout '^data_rule=cdm\.inspect\.validation\.datarule\.EnvelopeDetailSpecific$' -- \
  longest_owner_assignment

expect_ok "one invocation lists exact metadata and structural validators" \
  --stdout '^structural_validator=cdm\.inspect\.validation\.EnvelopeValidator$' -- \
  inspect_slice

fake_bin="$work/fake-bin"
mkdir -p "$fake_bin"
printf '%s\n' '#!/usr/bin/env bash' 'exit 97' >"$fake_bin/unzip"
chmod +x "$fake_bin/unzip"
inspect_without_extraction() {
  PATH="$fake_bin:$PATH" \
    "$cdm_inspect" --jar "$fixture_jar" Envelope EnvelopeDetail Transfer Mode
}
expect_ok "the one-shot batch succeeds when archive extraction is forbidden" \
  --stdout '^# resolved=cdm\.inspect\.Mode kind=enum$' -- inspect_without_extraction

expect_fail "ambiguous Rune names fail rather than guessing a Java package" \
  --stderr 'declaration name is ambiguous' -- \
  "$cdm_inspect" --jar "$fixture_jar" TradeState

expect_fail "the request bound rejects an over-broad slice before inspection" \
  --stderr 'at most 8 declarations' -- \
  "$cdm_inspect" --jar "$fixture_jar" \
  Filler0 Filler1 Filler2 Filler3 Filler4 Filler5 Filler6 Filler7 Filler8

output_bound_is_atomic() {
  local stdout_file="$work/output-bound.stdout"
  local stderr_file="$work/output-bound.stderr"
  if "$cdm_inspect" --jar "$fixture_jar" Huge >"$stdout_file" 2>"$stderr_file"; then
    return 1
  fi
  [[ ! -s "$stdout_file" ]] || return 1
  rg 'exact inspection would emit .* lines \(limit 1200\)' "$stderr_file"
}
expect_ok "the output bound fails without leaking a truncated partial report" \
  --stdout 'exact inspection would emit .* lines \(limit 1200\)' -- \
  output_bound_is_atomic

finish
