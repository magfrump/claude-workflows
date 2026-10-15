#!/usr/bin/env bash
# shellcheck disable=SC2164  # recorded reviewer probe, kept as run; gate 6 only
# Security bypass probes for hooks/live-verify-gate.sh at 9001bf80.
set -u
P="$1"; [ -d "$P/src" ] || { echo "no probe dir"; exit 1; }
export HOME="$P/home" LC_ALL=C GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
HOOK="$P/src/hooks/live-verify-gate.sh"
payload() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
run() { # $1 label, $2 command
  local out st
  out="$(timeout 20 bash "$HOOK" <<< "$(payload "$2")" 2>&1)"; st=$?
  printf '%-4s exit=%s  cmd=%s\n' "$1" "$st" "$2"
  printf '%s\n' "$out" | grep -E '^BLOCKED' | sed 's/^/       /'
}
fresh() {
  R="$P/repo-$1"; rm -rf "$R"; mkdir -p "$R/devcontainer-config/egress"; cd "$R" || exit 1
  git init -q; git config user.email t@e; git config user.name t; git config commit.gpgsign false
  printf 'x\n' > devcontainer-config/egress/base.txt
  for f in init-firewall.sh cc-push.sh cc-gitdir.sh cc-exit-scan.sh Dockerfile; do printf 'echo %s\n' "$f" > "devcontainer-config/$f"; done
  git add -A; git commit -qm init
}

echo "== R1 rename a boundary file away (init-firewall.sh -> fw.sh)"
fresh r1; git mv devcontainer-config/init-firewall.sh devcontainer-config/fw.sh
git diff --cached --name-only | sed 's/^/   name-only: /'
run R1 'git commit -m x'

echo "== R2 rename a host tool away (cc-push.sh -> x.sh)"
fresh r2; git mv devcontainer-config/cc-push.sh devcontainer-config/x.sh
git diff --cached --name-only | sed 's/^/   name-only: /'
run R2 'git commit -m x'

echo "== R3 delete a host tool"
fresh r3; git rm -q devcontainer-config/cc-push.sh
run R3 'git commit -m x'

echo "== R4 move host tool content into a boundary file path? (rename cc-push.sh over a new name in egress/)"
fresh r4; git mv devcontainer-config/cc-push.sh devcontainer-config/egress/new.txt
git diff --cached --name-only | sed 's/^/   name-only: /'
run R4 'git commit -m x -m "Host-tool-tested: no"'

echo "== P1 pathspec commit of an unstaged boundary change (not -a)"
fresh p1; echo widened >> devcontainer-config/egress/base.txt
run P1 'git commit -m x devcontainer-config/egress/base.txt'
run P1b 'git commit -m x -- devcontainer-config/cc-push.sh'
echo "== P2 --include / -o variants with unstaged host change"
echo 'echo y' >> devcontainer-config/cc-push.sh
run P2 'git commit -o -m x devcontainer-config/cc-push.sh'
run P2b 'git commit -i -m x devcontainer-config/cc-push.sh'

echo "== T1 one trailer value names the other (cross-satisfaction)"
fresh t1; echo widened >> devcontainer-config/egress/base.txt; echo 'echo y' >> devcontainer-config/cc-push.sh; git add -A
run T1 'git commit -m x -m "Host-tool-tested: no — see Live-verified: later"'
run T1b 'git commit -m x -m "Live-verified:Host-tool-tested: x"'
echo "== T2 trailer in an earlier chained command, not the message"
run T2 'echo "Live-verified: Host-tool-tested:" >/dev/null; git commit -m x'

echo "== C1 both sets touched, both comment-only"
fresh c1; echo '# note' >> devcontainer-config/egress/base.txt; echo '# note' >> devcontainer-config/cc-push.sh; git add -A
run C1 'git commit -m x'
echo "== C2 boundary comment-only + host substantive, no trailer"
fresh c2; echo '# note' >> devcontainer-config/egress/base.txt; echo 'echo y' >> devcontainer-config/cc-push.sh; git add -A
run C2 'git commit -m x'
run C2b 'git commit -m x -m "Host-tool-tested: no"'
echo "== C3 host comment edit that also comments OUT a real host line"
fresh c3; printf '# echo cc-push.sh\n' > devcontainer-config/cc-push.sh; git add -A
run C3 'git commit -m x'

echo "== K1 case variant of host tool path (not a real tool on Linux)"
fresh k1; echo 'echo y' > devcontainer-config/CC-PUSH.sh; git add -A
run K1 'git commit -m x'

echo "== G1 git -C other-repo commit from a different cwd"
fresh g1; echo widened >> devcontainer-config/egress/base.txt; git add -A; cd "$P"
run G1 "git -C $P/repo-g1 commit -m x"
