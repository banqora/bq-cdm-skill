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
