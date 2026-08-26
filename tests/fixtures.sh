#!/usr/bin/env bash
# Fixture builders for tests/*.test.sh; source after lib.sh.
# Callers provide $work (from setup_work), $repo_root, and $skill_dir; builders
# set $fixture_jar, $manifest_jar, $no_rosetta_jar, $link_port for callers and
# $link_server_pid for lib.sh teardown.
# shellcheck disable=SC2154,SC2034

# A fixture JAR shaped like a real cdm-java release: enough Rosetta sources to
# clear the live gate's floor, containing the anchor declarations it asserts.
# Also builds a JAR with no Rosetta sources, and one whose filename carries no
# version so the MANIFEST fallback is exercised.
build_fixture_jars() {
  python3 - "$work" <<'PY'
import sys
import zipfile
from pathlib import Path

work = Path(sys.argv[1])

def write_rosetta(jar):
    jar.writestr(
        "cdm/rosetta/event-common-type.rosetta",
        """namespace cdm.event.common

import cdm.base.math.*

type TradeState:
  trade Trade (1..1)

type AssetFlowBase:
  quantity number (1..1)
  unit UnitType (1..1)
  condition PositiveQuantity:
    quantity > 0

type TransferBase extends AssetFlowBase:
  payer string (1..1)

type ScheduledTransfer extends TransferBase:
  schedule string (1..1)

type ContingentTransfer extends TransferBase:
  event string (1..1)
  condition EventExists:
    event exists
""",
    )
    jar.writestr(
        "cdm/rosetta/base-math-type.rosetta",
        """namespace cdm.base.math

type UnitType:
  currency string (0..1)
  financialUnit string (0..1)
  condition UnitType:
    one-of
""",
    )
    jar.writestr(
        "cdm/rosetta/event-qualification-func.rosetta",
        "namespace cdm.event.qualification\n\nfunc Qualify_Fixture:\n  output: is_event boolean (1..1)\n",
    )
    for index in range(58):
        jar.writestr(
            f"cdm/rosetta/filler-{index:02d}-type.rosetta",
            f"namespace cdm.fixture\n\ntype Filler{index}:\n  value string (0..1)\n",
        )
    jar.writestr(
        "cdm-sample-files/functions/repo-and-bond/roll-output.json", "{}\n"
    )

with zipfile.ZipFile(work / "cdm-java-9.9.9.jar", "w") as jar:
    write_rosetta(jar)
    jar.writestr("META-INF/MANIFEST.MF", "Manifest-Version: 1.0\n")

with zipfile.ZipFile(work / "model-dist.jar", "w") as jar:
    write_rosetta(jar)
    jar.writestr(
        "META-INF/MANIFEST.MF",
        "Manifest-Version: 1.0\nImplementation-Version: 5.5.5\n",
    )

with zipfile.ZipFile(work / "no-rosetta.jar", "w") as jar:
    jar.writestr("META-INF/MANIFEST.MF", "Manifest-Version: 1.0\n")
    jar.writestr("com/example/Empty.class", b"\xca\xfe\xba\xbe")
PY
  fixture_jar="$work/cdm-java-9.9.9.jar"
  manifest_jar="$work/model-dist.jar"
  no_rosetta_jar="$work/no-rosetta.jar"
}

# A discovery sandbox shaped like a built project: $work/<name>/.git plus the
# fixture JAR under lib/. Prints the sandbox path.
make_project_sandbox() {
  local sandbox="$work/$1"
  mkdir -p "$sandbox/.git" "$sandbox/lib"
  cp "$fixture_jar" "$sandbox/lib/cdm-java-9.9.9.jar"
  printf '%s\n' "$sandbox"
}

# A mutable copy of the repo shape for static-gate negative tests.
fresh_copy() {
  local copy="$work/copy-$1"
  rm -rf -- "$copy"
  mkdir -p "$copy/skills" "$copy/evals/benchmarks"
  cp -R "$repo_root/README.md" "$repo_root/scripts" "$repo_root/.claude-plugin" "$copy/"
  cp "$repo_root/evals/README.md" "$copy/evals/README.md"
  cp "$repo_root/evals/benchmarks/README.md" "$copy/evals/benchmarks/README.md"
  cp -R "$skill_dir" "$copy/skills/cdm-dev"
  printf '%s\n' "$copy"
}

# A local HTTP fixture makes link-check behavior hermetic. It includes a
# redirect, an access-controlled endpoint, and a definitively broken link.
# Sets $link_port; the server pid lands in $link_server_pid for teardown.
start_link_server() {
  local link_port_file="$work/link-port"
  python3 - "$link_port_file" <<'PY' &
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/ok":
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"ok")
        elif self.path == "/redirect":
            self.send_response(302)
            self.send_header("Location", "/ok")
            self.end_headers()
        elif self.path == "/restricted":
            self.send_response(403)
            self.end_headers()
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, _format, *_args):
        pass


server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
Path(sys.argv[1]).write_text(str(server.server_address[1]))
server.serve_forever()
PY
  link_server_pid=$!
  for _ in $(seq 1 50); do
    [[ -s "$link_port_file" ]] && break
    sleep 0.05
  done
  if [[ ! -s "$link_port_file" ]]; then
    echo "$suite_name: local link fixture did not start" >&2
    exit 1
  fi
  link_port="$(<"$link_port_file")"
}
