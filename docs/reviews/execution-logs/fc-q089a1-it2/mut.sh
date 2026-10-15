#!/usr/bin/env bash
# Mutation check for the strengthened bless-failure test. $1 = probe root holding src/ (git archive b3b37e16).
# Mutant: bless moves the new boundary manifest into place as soon as compute_manifest succeeds,
# before compute_host_tools_manifest runs (so a host-tool failure leaves manifest.sha256 rewritten).
set -u
P="${1:?probe root}"; [ -d "$P/src/devcontainer-config" ] || { echo "no $P/src"; exit 99; }
export HOME="$P/home" TMPDIR="$P/tmp" LC_ALL=C CLAUDE_DEVC_CONFIG_DIR="$P/home/cfg"
M="$P/mut"; rm -rf "$M"; mkdir -p "$M"
cp -r "$P/src/devcontainer-config" "$P/src/test" "$M/"
python3 -I - "$M/devcontainer-config/cc-isolated.sh" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = '  if ! compute_manifest > "$new_m" || ! compute_host_tools_manifest > "$new_h"; then\n'
new = '  if ! compute_manifest > "$new_m" || ! { cp "$new_m" "$(manifest_path)"; compute_host_tools_manifest > "$new_h"; }; then\n'
assert s.count(old) == 1
open(p, "w").write(s.replace(old, new))
PY
grep -n 'cp "$new_m"' "$M/devcontainer-config/cc-isolated.sh"
echo "== new test (b3b37e16) vs mutant"
timeout 120 bats -f 'bless: a failure changes neither manifest' "$M/test/cc-isolated-functions.bats"; echo "[rc=$?]"
echo "== old test (f2533b33) vs mutant"
git -C /workspace/.claude/wt-q089 show f2533b33:test/cc-isolated-functions.bats > "$M/test/old.bats"
timeout 120 bats -f 'bless: a failure changes neither manifest' "$M/test/old.bats"; echo "[rc=$?]"
echo "== new test vs unmutated code"
timeout 120 bats -f 'bless: a failure changes neither manifest' "$P/src/test/cc-isolated-functions.bats"; echo "[rc=$?]"
echo "== malformed-manifest test vs mutant that drops the format check"
cp "$P/src/devcontainer-config/cc-isolated.sh" "$M/devcontainer-config/cc-isolated.sh"
python3 -I - "$M/devcontainer-config/cc-isolated.sh" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = "  if [ ! -r \"$m\" ] || grep -qvE '^[0-9a-f]{64}  [A-Za-z0-9._-]+$' \"$m\"; then\n"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "  if [ ! -r \"$m\" ]; then\n"))
PY
timeout 120 bats -f 'unreadable or malformed host manifest' "$M/test/cc-isolated-functions.bats"; echo "[rc=$?]"
echo "== same test vs mutant that drops only the readability check"
cp "$P/src/devcontainer-config/cc-isolated.sh" "$M/devcontainer-config/cc-isolated.sh"
python3 -I - "$M/devcontainer-config/cc-isolated.sh" <<'PY'
import sys
p = sys.argv[1]; s = open(p).read()
old = "  if [ ! -r \"$m\" ] || grep"
assert s.count(old) == 1
open(p, "w").write(s.replace(old, "  if grep"))
PY
timeout 120 bats -f 'unreadable or malformed host manifest' "$M/test/cc-isolated-functions.bats"; echo "[rc=$?]"
