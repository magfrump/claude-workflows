#!/usr/bin/env bash
# Security review pass 4 (2026-09-25): every probe of this pass, against
# install.sh at f5e3029 (/workspace/.claude/wt-q058p2). Writes one log per
# harness next to this script:
#   links-probe.log          new: links_in missing item / find failure, 3 sites
#   hookkeys-probe.log       new: hook.* key spellings vs the gate's read
#   rerun-pass2-probes.log   regression: pass-2 probe.bats, unchanged
#   newroutes-probe.log      regression: pass-3 probe, regex read from install.sh
#   global-filter-probe.log  regression: pass-3 probe, regex read from install.sh
#   install-host-suite.log   the author's suite at f5e3029
# Hermetic: each harness pins HOME/TMPDIR/git config into temp dirs (see each).
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
wt=/workspace/.claude/wt-q058p2
stamp() { date -u +%Y-%m-%dT%H:%M:%SZ; git -C "$wt" rev-parse --short HEAD; git --version; }

bash "$here/run-links.sh" >/dev/null
bash "$here/hookkeys-probe.sh" >/dev/null
{ stamp; bats --verbose-run "$here/../secrev-q058p2/probe.bats" 2>&1; echo "bats exit=$?"; } \
  > "$here/rerun-pass2-probes.log" 2>&1
bash "$here/newroutes-probe.sh" >/dev/null
bash "$here/global-filter-probe.sh" >/dev/null
{ stamp; bats "$wt/test/install-host.bats" 2>&1; echo "bats exit=$?"; } \
  > "$here/install-host-suite.log" 2>&1
for f in links-probe rerun-pass2-probes install-host-suite; do
  printf '%s: ' "$f"; grep -E '^bats exit=' "$here/$f.log"
done
