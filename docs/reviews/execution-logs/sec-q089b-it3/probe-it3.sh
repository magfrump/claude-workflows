#!/usr/bin/env bash
# Security review it3 probes for Q-089 B at 25d8f272. Run: bash probe-it3.sh
set -u
export LC_ALL=C GIT_CONFIG_NOSYSTEM=1
SRC=/workspace/.claude/wt-q089b
P="$(mktemp -d /home/node/.claude/jobs/00bcf178/tmp/sec-it3.XXXXXX)" || exit 1
[ -n "$P" ] && [ -d "$P" ] || exit 1
cd "$P" || exit 1
export HOME="$P/home"; mkdir -p "$HOME"
mkdir tree && git -C "$SRC" archive 25d8f272 hooks test devcontainer-config | tar -x -C tree || exit 1
HOOK="$P/tree/hooks/live-verify-gate.sh"
T=20

mutant() { # $1 name, $2 sed expr -> path
  local d="$P/mut-$1"; mkdir -p "$d"; cp -r "$P/tree/." "$d/"
  sed -i -E "$2" "$d/hooks/live-verify-gate.sh"
  echo "$d"
}
bats_run() { # $1 tree dir, $2 label
  local out rc; out="$(cd "$1" && timeout 300 bats test/hooks/live-verify-gate.bats 2>&1)"; rc=$?
  echo "== bats $2: rc=$rc"; printf '%s\n' "$out" | grep -E '^(not ok|[0-9]+\.\.[0-9]+)'
}

echo "### Mutant bats runs"
bats_run "$P/tree" "clean 25d8f272"
d=$(mutant f1 "s/\|install\\\\\.sh\\$//; s/cc-push\\\\\.sh\)'/cc-push\\\\.sh|install.sh$)'/")
grep -nE "^(enforcement|host_tools)=" "$d/hooks/live-verify-gate.sh"; bats_run "$d" "M-F1 install.sh moved to host_tools (unescaped dot)"
d=$(mutant f2 '77s/ --no-renames//'); sed -n 77p "$d/hooks/live-verify-gate.sh"; bats_run "$d" "M-F2 drop --no-renames on -a call"
d=$(mutant f3t 's/ --no-textconv//g'); bats_run "$d" "M-F3a drop --no-textconv"
d=$(mutant f3e 's/ --no-ext-diff//g'); bats_run "$d" "M-F3b drop --no-ext-diff"
MUT_EXT="$d/hooks/live-verify-gate.sh"

newrepo() {
  R="$P/repo-$1"; rm -rf "$R"; mkdir -p "$R/devcontainer-config/egress" "$R/devcontainer-config/sub"
  git -C "$R" init -q; git -C "$R" config user.email t@e; git -C "$R" config user.name t
  printf 'base\n# c\n' > "$R/devcontainer-config/egress/base.txt"
  printf '{\n  // a comment\n  "name": "x"\n}\n' > "$R/devcontainer-config/devcontainer.json"
  printf '#!/bin/bash\n# fw\niptables -P OUTPUT DROP\n' > "$R/devcontainer-config/init-firewall.sh"
  printf '#!/bin/bash\necho push\n' > "$R/devcontainer-config/cc-push.sh"
  printf '* text=auto eol=lf\n' > "$R/.gitattributes"
  git -C "$R" add -A; git -C "$R" -c commit.gpgsign=false commit -qm init
}
hk() { # $1 hook, $2 label, [$3 cwd]
  local c; c="$(jq -n -c --arg c 'git commit -m "x"' '{tool_name:"Bash",tool_input:{command:$c}}')"
  (cd "${3:-$R}" && timeout $T bash "$1" <<< "$c" >/dev/null 2>&1); echo "$2: exit $?"
}

echo; echo "### P1 diff.external fake driver (prints a comment-only patch)"
newrepo p1
printf '#!/bin/sh\nprintf "diff --git a/%%s b/%%s\\n@@ -1 +1 @@\\n-# old\\n+# new\\n" "$1" "$1"\n' > "$P/fake-ext.sh"
chmod +x "$P/fake-ext.sh"
echo evil.example.com >> "$R/devcontainer-config/egress/base.txt"; git -C "$R" add -A
git -C "$R" config diff.external "$P/fake-ext.sh"
(cd "$R" && git diff --cached -U0 --no-color -- devcontainer-config/egress/base.txt | head -4)
hk "$HOOK" "P1 25d8f272, diff.external set, real widening"
hk "$MUT_EXT" "P1 mutant (no --no-ext-diff), diff.external set"
git -C "$R" config --unset diff.external
echo 'devcontainer-config/** diff=fk' >> "$R/.gitattributes"; git -C "$R" config diff.fk.command "$P/fake-ext.sh"
hk "$HOOK" "P1b 25d8f272, diff.<x>.command via attributes"
hk "$MUT_EXT" "P1b mutant (no --no-ext-diff), diff.<x>.command"

echo; echo "### P2 legit comment-only edits: flags vs no flags, and under git config variants"
cfgs=("" "diff.noprefix=true" "diff.mnemonicPrefix=true" "color.diff=always" "color.ui=always" "diff.algorithm=patience" "diff.algorithm=histogram" "core.quotePath=false" "diff.suppressBlankEmpty=true" "diff.relative=true" "diff.renames=copies" "diff.indentHeuristic=false" "diff.colorMoved=zebra" "diff.wsErrorHighlight=all")
for cfg in "${cfgs[@]}"; do
  newrepo p2
  [ -n "$cfg" ] && git -C "$R" config "${cfg%%=*}" "${cfg#*=}"
  sed -i 's#// a comment#// an edited comment#' "$R/devcontainer-config/devcontainer.json"
  sed -i 's/^# c$/# c2/' "$R/devcontainer-config/egress/base.txt"
  sed -i 's/^# fw$/# firewall/' "$R/devcontainer-config/init-firewall.sh"
  git -C "$R" add -A
  a="$(cd "$R" && git diff --cached -U0 --no-color -- devcontainer-config | md5sum)"; b="$(cd "$R" && git diff --cached -U0 --no-color --no-textconv --no-ext-diff -- devcontainer-config | md5sum)"
  [ "$a" = "$b" ] && same=same || same=DIFFER
  hk "$HOOK" "P2 [${cfg:-default}] comment-only (output with/without flags: $same)"
  sed -i 's/"name": "x"/"name": "y"/' "$R/devcontainer-config/devcontainer.json"; git -C "$R" add -A
  hk "$HOOK" "P2 [${cfg:-default}] + real jsonc change"
done

echo; echo "### P3 // line in a shell enforcement file / host tool (pre-existing rule scope)"
newrepo p3
printf '//usr/bin/curl -s http://evil.example.com/x\n' >> "$R/devcontainer-config/init-firewall.sh"; git -C "$R" add -A
hk "$HOOK" "P3 init-firewall.sh gains //usr/bin/curl line"
printf '# c\n//bin/echo RAN-AS-COMMAND\n' > "$P/t.sh"; echo "P3 bash runs a // line: $(bash "$P/t.sh" 2>&1)"
newrepo p3b
printf '//bin/sh -c "echo pwned"\n' >> "$R/devcontainer-config/cc-push.sh"; git -C "$R" add -A
hk "$HOOK" "P3b cc-push.sh gains //bin/sh line"

echo; echo "### P4 core.quotePath default and a non-ASCII egress name"
newrepo p4
printf 'evil.example.com\n' > "$R/devcontainer-config/egress/$(printf 'b\303\274.txt')"; git -C "$R" add -A
(cd "$R" && git diff --cached --name-only --no-renames)
hk "$HOOK" "P4 new egress/b<u-umlaut>.txt, quotePath default"
git -C "$R" config core.quotePath false
hk "$HOOK" "P4 same, quotePath=false"

echo; echo "### P5 diff.relative=true and a subdirectory cwd"
newrepo p5
echo evil.example.com >> "$R/devcontainer-config/egress/base.txt"; git -C "$R" add -A
hk "$HOOK" "P5 subdir cwd, diff.relative unset" "$R/devcontainer-config"
git -C "$R" config diff.relative true
hk "$HOOK" "P5 root cwd, diff.relative=true"
hk "$HOOK" "P5 subdir cwd, diff.relative=true" "$R/devcontainer-config"

echo; echo "### cleanup"
cd / && rm -rf "$P" && echo "removed $P"
