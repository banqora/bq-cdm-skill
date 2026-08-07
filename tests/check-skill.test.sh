#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skill_dir="$repo_root/skills/cdm-dev"
check_skill="$repo_root/scripts/check-skill"
suite_name="check-skill"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"
# shellcheck source=tests/fixtures.sh
source "$script_dir/fixtures.sh"

setup_work
build_fixture_jars

expect_ok "static gate passes on this repository" \
  --stdout 'static contract passed' -- \
  "$check_skill" --static

copy="$(fresh_copy missing-ui-metadata)"
rm -- "$copy/skills/cdm-dev/agents/openai.yaml"
expect_fail "static gate requires agents/openai.yaml" \
  --stderr "agents/openai.yaml is missing" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy unquoted-ui-metadata)"
python3 - "$copy/skills/cdm-dev/agents/openai.yaml" <<'PY'
import sys
from pathlib import Path

metadata = Path(sys.argv[1])
metadata.write_text(metadata.read_text().replace(
    '  display_name: "FINOS CDM Development"',
    '  display_name: FINOS CDM Development'))
PY
expect_fail "static gate requires quoted UI strings" \
  --stderr "interface values must be quoted strings" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy short-ui-description)"
python3 - "$copy/skills/cdm-dev/agents/openai.yaml" <<'PY'
import sys
from pathlib import Path

metadata = Path(sys.argv[1])
metadata.write_text(metadata.read_text().replace(
    '  short_description: "Build and debug FINOS CDM integrations"',
    '  short_description: "Too short"'))
PY
expect_fail "static gate enforces the UI description length" \
  --stderr "short_description must be 25-64" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy incomplete-default-prompt)"
python3 - "$copy/skills/cdm-dev/agents/openai.yaml" <<'PY'
import sys
from pathlib import Path

metadata = Path(sys.argv[1])
metadata.write_text(metadata.read_text().replace(
    '  default_prompt: "Use $cdm-dev to build, debug, or review this FINOS CDM integration."',
    '  default_prompt: "Review this FINOS CDM integration."'))
PY
# shellcheck disable=SC2016  # grep receives the escaped literal dollar sign
expect_fail "static gate requires the skill name in the default prompt" \
  --stderr 'default_prompt must mention \$cdm-dev' -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy multi-sentence-default-prompt)"
python3 - "$copy/skills/cdm-dev/agents/openai.yaml" <<'PY'
import sys
from pathlib import Path

metadata = Path(sys.argv[1])
metadata.write_text(metadata.read_text().replace(
    '  default_prompt: "Use $cdm-dev to build, debug, or review this FINOS CDM integration."',
    '  default_prompt: "Use $cdm-dev. Review this FINOS CDM integration."'))
PY
expect_fail "static gate requires a one-sentence default prompt" \
  --stderr "default_prompt must be one sentence" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy extra-ui-field)"
printf '  icon_small: "./assets/icon.png"\n' >>"$copy/skills/cdm-dev/agents/openai.yaml"
expect_fail "static gate rejects unrequested UI fields" \
  --stderr "interface keys must be" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy broken-link)"
printf '\nSee [missing](references/absent.md).\n' >>"$copy/skills/cdm-dev/SKILL.md"
expect_fail "static gate catches a broken reference link" \
  --stderr "missing Markdown references" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy orphan)"
printf '# Orphan\n\n1\n2\n3\n4\n5\n6\n7\n8\n' >"$copy/skills/cdm-dev/references/orphan.md"
expect_fail "static gate catches an orphan reference" \
  --stderr "orphan references" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy missing-reference-contents)"
python3 - "$copy/skills/cdm-dev/references/conformance.md" <<'PY'
import sys
from pathlib import Path

reference = Path(sys.argv[1])
lines = reference.read_text().splitlines()
start = lines.index("## Contents")
end = next(index for index in range(start + 1, len(lines))
           if lines[index].startswith("## "))
reference.write_text("\n".join(lines[:start] + lines[end:]) + "\n")
PY
expect_fail "static gate requires Contents in long references" \
  --stderr "references over 100 lines need one ## Contents" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy stale-reference-contents)"
python3 - "$copy/skills/cdm-dev/references/conformance.md" <<'PY'
import sys
from pathlib import Path

reference = Path(sys.argv[1])
reference.write_text(reference.read_text().replace(
    "(#report-the-result-precisely)", "(#stale-target)"))
PY
expect_fail "static gate catches stale Contents targets" \
  --stderr "Contents targets do not match level-two headings" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy forbidden-path)"
printf '\nDebug notes live in /Users/example/notes.md.\n' >>"$copy/skills/cdm-dev/references/testing.md"
expect_fail "static gate catches an absolute user path" \
  --stderr "absolute user path" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy pinned-jar)"
printf '\nTested against cdm-java-9.9.9.jar only.\n' >>"$copy/skills/cdm-dev/references/testing.md"
expect_fail "static gate catches a hard-coded cdm-java release" \
  --stderr "hard-codes a released cdm-java filename" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy long-description)"
python3 - "$copy/skills/cdm-dev" <<'PY'
import sys
from pathlib import Path

skill = Path(sys.argv[1]) / "SKILL.md"
lines = skill.read_text().splitlines()
for index, line in enumerate(lines):
    if line.startswith("description:"):
        lines[index] = "description: " + "cdm development guidance " * 60
        break
skill.write_text("\n".join(lines) + "\n")
PY
expect_fail "static gate enforces the 1024-character description cap" \
  --stderr "1024" -- \
  "$copy/scripts/check-skill" --static

copy="$(fresh_copy oversized)"
for _ in $(seq 60); do printf 'Padding line to inflate the always-loaded skill.\n' >>"$copy/skills/cdm-dev/SKILL.md"; done
expect_fail "static gate enforces the SKILL.md line budget" \
  --stderr "move detail to references" -- \
  "$copy/scripts/check-skill" --static

expect_ok "live gate passes against the fixture JAR" \
  --stdout 'live contract passed' -- \
  "$check_skill" --jar "$fixture_jar"

expect_fail "live gate rejects a JAR without Rosetta sources" -- \
  "$check_skill" --jar "$no_rosetta_jar"

finish
