#!/bin/bash
# Narrow code-fact-check probe for 88994fe9. Usage: fcnarrow-probe.sh <repo>
set -u
REPO="$1"
BASE=/home/node/.claude/jobs/00bcf178/tmp
W="$(mktemp -d "$BASE/fcnarrow.XXXXXX")" || exit 1
[ -n "$W" ] && [ -d "$W" ] || exit 1
cd "$W" || exit 1
mkdir -p home tmp clones cfg logs stubbin
printf '#!/usr/bin/env bash\nexit 0\n' > stubbin/devcontainer; chmod +x stubbin/devcontainer
export HOME="$W/home" TMPDIR="$W/tmp" CC_PUSH_CLONES_DIR="$W/clones" CLAUDE_DEVC_CONFIG_DIR="$W/cfg" LC_ALL=C
export PATH="$W/stubbin:$PATH"
echo "workdir $W"

mk() { # mk <name>: fresh tree from the commit
  mkdir -p "$W/$1" && git -C "$REPO" archive 88994fe9 | tar -x -C "$W/$1"
}
runb() { # runb <tree> <suite> <log>
  ( cd "$W/$1" && timeout 600 bats "test/$2" ) > "$W/logs/$3" 2>&1
  echo "rc=$? $3: $(grep -cE '^ok ' "$W/logs/$3") ok / $(grep -cE '^not ok ' "$W/logs/$3") not ok; plan $(head -1 "$W/logs/$3")"
}

date -u +%FT%TZ
mk base
runb base cc-isolated-functions.bats base-cci.log
runb base cc-push.bats base-push.log

# M1: drop the config-dir clause in both copies.
mk m1
for f in cc-isolated.sh cc-push.sh; do
  python3 -I - "$W/m1/devcontainer-config/$f" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
old=' && [ "$dir" != "$cfg" ]; then'
assert s.count(old)==1, p
open(p,'w').write(s.replace(old,'; then'))
EOF
done
grep -c '"$dir" != "$cfg"' "$W/m1/devcontainer-config/cc-isolated.sh" "$W/m1/devcontainer-config/cc-push.sh"
runb m1 cc-isolated-functions.bats m1-cci.log
grep -E '^not ok' "$W/logs/m1-cci.log"

# M2: the no-entry branch prints "changed" (both copies, so parity holds).
mk m2
for f in cc-isolated.sh cc-push.sh; do
  python3 -I - "$W/m2/devcontainer-config/$f" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
old='echo "host-tool manifest $m has no entry, or more than one, for $f"'
assert s.count(old)==1, p
open(p,'w').write(s.replace(old,'echo "$dir/$f changed since the last bless"'))
EOF
done
runb m2 cc-isolated-functions.bats m2-cci.log
grep -E '^not ok' "$W/logs/m2-cci.log"

# M3: --list reports cc-push as CHANGED whenever lerr is set (scan-only change).
mk m3
python3 -I - "$W/m3/devcontainer-config/cc-isolated.sh" <<'EOF'
import sys
p=sys.argv[1]; s=open(p).read()
old='    if [ -n "$perr" ]; then printf'
assert s.count(old)==1, p
open(p,'w').write(s.replace(old,'    perr="${perr:-$lerr}"\n    if [ -n "$perr" ]; then printf'))
EOF
runb m3 cc-isolated-functions.bats m3-cci.log
grep -E '^not ok' "$W/logs/m3-cci.log"

# Pre-fix control: the old tests (3164f1d5) against each mutant, to show they were unfailable.
git -C "$REPO" show 3164f1d5:test/cc-isolated-functions.bats > "$W/old.bats"
for m in m1 m2 m3; do
  cp "$W/old.bats" "$W/$m/test/old-cci.bats"
  runb $m old-cci.bats $m-old.log
  grep -E '^not ok' "$W/logs/$m-old.log"
done
date -u +%FT%TZ
echo "real HOME untouched check: $(ls -d /home/node/.config/claude-devcontainer 2>/dev/null || echo none)"
