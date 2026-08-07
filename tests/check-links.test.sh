#!/usr/bin/env bash
set -uo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"
skill_dir="$repo_root/skills/cdm-dev"
check_links="$repo_root/scripts/check-links"
suite_name="check-links"

# shellcheck source=tests/lib.sh
source "$script_dir/lib.sh"
# shellcheck source=tests/fixtures.sh
source "$script_dir/fixtures.sh"

setup_work
start_link_server

links_ok="$work/links-ok.md"
printf '%s\n' \
  "[working](http://127.0.0.1:$link_port/ok)" \
  "[redirect](http://127.0.0.1:$link_port/redirect)" \
  "[restricted](http://127.0.0.1:$link_port/restricted)" >"$links_ok"
links_broken="$work/links-broken.md"
printf '%s\n' "[missing](http://127.0.0.1:$link_port/missing)" >"$links_broken"
links_none="$work/links-none.md"
printf '# No links here\n\nJust prose.\n' >"$links_none"

expect_ok "link checker follows redirects and reports restricted sources" \
  --stdout '0 broken, 1 access/rate warnings' -- \
  "$check_links" --retries 0 "$links_ok"

expect_fail "link checker rejects a definitive 404" \
  --stderr 'BROKEN.*HTTP 404' -- \
  "$check_links" --retries 0 "$links_broken"

expect_fail "link checker can make restricted sources fatal" \
  --stderr 'restricted.*HTTP 403' -- \
  "$check_links" --retries 0 --strict-restricted "$links_ok"

expect_fail "link checker reports when no external links are found" \
  --stderr 'no external HTTP\(S\) links found' -- \
  "$check_links" --retries 0 "$links_none"

finish
