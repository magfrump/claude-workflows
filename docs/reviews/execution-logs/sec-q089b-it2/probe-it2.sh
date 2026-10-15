#!/usr/bin/env bash
# shellcheck disable=SC2164  # recorded reviewer probe, kept as run; gate 6 only
# Security review it2 probes for 79f22357's live-verify-gate.sh. $1 = probe dir
# holding src/ (git archive 79f22357 hooks/live-verify-gate.sh) and empty mut/.
set -u
P="$1"; [ -d "$P/src" ] || { echo "no probe dir"; exit 1; }
export HOME="$P/home" LC_ALL=C GIT_CONFIG_NOSYSTEM=1; mkdir -p "$HOME"
HOOK="$P/src/hooks/live-verify-gate.sh"
pl() { jq -n -c --arg c "$1" '{"tool_name":"Bash","tool_input":{"command":$c}}'; }
run() { local label="$1" c="$2" hook="${3:-$HOOK}"; timeout 20 bash "$hook" <<< "$(pl "$c")" >/dev/null 2>&1; echo "$label: exit $?"; }
fresh() {
  R="$P/repo-$1"; rm -rf "$R"; mkdir -p "$R/devcontainer-config/egress"; cd "$R" || exit 1
  git init -q; git config user.email t@e; git config user.name t; git config commit.gpgsign false
  echo base > devcontainer-config/egress/base.txt; echo 'echo push' > devcontainer-config/cc-push.sh
  git add -A; git commit -qm init
}
# R1: -a with intent-to-add rename (the -a call's --no-renames)
fresh r1
mv devcontainer-config/egress/base.txt devcontainer-config/base-moved.txt
git add -N devcontainer-config/base-moved.txt
echo "R1 worktree name-only (renames on):"; git diff --name-only | sed 's/^/  /'
echo "R1 worktree name-only --no-renames:"; git diff --name-only --no-renames | sed 's/^/  /'
run "R1 hook 79f22357, commit -a, no trailer" 'git commit -am x'
sed 's/git diff --name-only --no-renames/git diff --name-only/' "$HOOK" > "$P/mut/hook-mut-a.sh"
run "R1 mutant (no --no-renames on -a call), commit -a" 'git commit -am x' "$P/mut/hook-mut-a.sh"
# R2: textconv makes a real egress change read as comment-only
fresh r2
echo 'devcontainer-config/** diff=cm' > .gitattributes; git add .gitattributes; git commit -qm attrs
git config diff.cm.textconv "sed s/^/#/"
echo evil.example.com >> devcontainer-config/egress/base.txt; git add devcontainer-config/egress/base.txt
run "R2 textconv, real egress widening, no trailer" 'git commit -m x'
git config --unset diff.cm.textconv
run "R2 control (textconv removed), no trailer" 'git commit -m x'
# R3: install.sh moved to host_tools in a spelling the extractor misses
fresh r3
sed -e 's/|install\\.sh\$//' -e "s/^host_tools='\(.*\))'$/host_tools='\1|install.sh$)'/" "$HOOK" > "$P/mut/hook-mut-i.sh"
grep -E "^(enforcement|host_tools)=" "$P/mut/hook-mut-i.sh" | sed 's/^/  /'
echo 'echo hi' > devcontainer-config/install.sh; git add devcontainer-config/install.sh
run "R3 mutant, install.sh, no trailer" 'git commit -m x' "$P/mut/hook-mut-i.sh"
run "R3 mutant, install.sh, Host-tool-tested only" 'git commit -m x -m "Host-tool-tested: no"' "$P/mut/hook-mut-i.sh"
run "R3 original, install.sh, Host-tool-tested only" 'git commit -m x -m "Host-tool-tested: no"'
# R3b: the regex-names extractor on the mutant
echo "R3b extractor on mutant host_tools line:"; grep -E "^host_tools='" "$P/mut/hook-mut-i.sh" | grep -oE '[a-z-]+\\\.sh' | sed 's/\\\././;s/^/  /'
# R4: un-anchored host regex: sibling gated
fresh r4
echo x > devcontainer-config/cc-push.sh.orig; git add devcontainer-config/cc-push.sh.orig
run "R4 cc-push.sh.orig, Live-verified only" 'git commit -m x -m "Live-verified: no"'
run "R4 cc-push.sh.orig, Host-tool-tested only" 'git commit -m x -m "Host-tool-tested: no"'
cd "$P"; rm -rf "$P"/repo-*
