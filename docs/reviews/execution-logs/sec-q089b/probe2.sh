#!/usr/bin/env bash
# shellcheck disable=SC2164  # recorded reviewer probe, kept as run; gate 6 only
set -u
P="$1"; [ -d "$P/src" ] || { echo "no probe dir"; exit 1; }
export HOME="$P/home" LC_ALL=C GIT_CONFIG_NOSYSTEM=1
HOOK="$P/src/hooks/live-verify-gate.sh"
payload() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
run() { local out st; out="$(timeout 20 bash "$HOOK" <<< "$(payload "$2")" 2>&1)"; st=$?
  printf '%-4s exit=%s  cmd=%s\n' "$1" "$st" "$2"; printf '%s\n' "$out" | grep -E '^BLOCKED' | sed 's/^/       /'; }
fresh() { R="$P/repo2-$1"; rm -rf "$R"; mkdir -p "$R/devcontainer-config/egress"; cd "$R" || exit 1
  git init -q; git config user.email t@e; git config user.name t; git config commit.gpgsign false
  printf 'x\n' > devcontainer-config/egress/base.txt
  printf '#!/usr/bin/env bash\necho push\n' > devcontainer-config/cc-push.sh
  printf '#!/bin/bash\necho fw\n' > devcontainer-config/init-firewall.sh
  git add -A; git commit -qm init; }

echo "== S1 shebang change on cc-push.sh (comment-only by the gate's rule)"
fresh s1; printf '#!/bin/sh\necho push\n' > devcontainer-config/cc-push.sh; git add -A
run S1 'git commit -m x'
echo "== S2 shebang change on init-firewall.sh"
fresh s2; printf '#!/bin/sh\necho fw\n' > devcontainer-config/init-firewall.sh; git add -A
run S2 'git commit -m x'

echo "== D1 cd into another repo then commit (hook cwd is elsewhere)"
fresh d1; echo widened >> devcontainer-config/egress/base.txt; git add -A; cd "$P"
run D1 "cd $P/repo2-d1 && git commit -m x"

echo "== N1 --no-renames shows both sides of a rename (candidate fix)"
fresh n1; git mv devcontainer-config/init-firewall.sh devcontainer-config/fw.sh
git diff --cached --name-only --no-renames | sed 's/^/   /'
