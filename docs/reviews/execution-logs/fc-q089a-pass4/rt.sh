#!/usr/bin/env bash
# Runtime probes, fact-check pass 4 (q089a, fa059477). Run: rt.sh <probe-root>. Everything under <probe-root>/rt.
set -u
P="$1"; [ -d "$P/head/devcontainer-config" ] || { echo "no tree"; exit 2; }
R="$P/rt"; rm -rf "$R"; mkdir -p "$R/bin" "$R/home" "$R/tmp" || exit 2
export HOME="$R/home" TMPDIR="$R/tmp"
printf '#!/usr/bin/env bash\nexit 0\n' > "$R/bin/devcontainer"; chmod +x "$R/bin/devcontainer"
PATH="$R/bin:$PATH"
SRC="$P/head/devcontainer-config"
mk() { # mk <dir>: installed layout
  local d="$1"; rm -rf "$d"; mkdir -p "$d/egress"
  echo '{"name":"x"}' > "$d/devcontainer.json"; echo 'FROM node:22' > "$d/Dockerfile"
  echo '#!/bin/bash' > "$d/init-firewall.sh"; echo '#!/usr/bin/python3' > "$d/cc-sni-proxy.py"
  echo '#!/usr/bin/env bash' > "$d/link-claude-home.sh"; echo 'api.anthropic.com' > "$d/egress/base.txt"
  cp "$SRC/cc-isolated.sh" "$SRC/cc-exit-scan.sh" "$SRC/cc-gitdir.sh" "$SRC/cc-push.sh" "$d/"
  CLAUDE_DEVC_CONFIG_DIR="$d" bash "$d/cc-isolated.sh" --bless >/dev/null
}
ws="$R/ws"; mkdir -p "$ws"; git -C "$ws" init -q
D="$R/cfg"; export CLAUDE_DEVC_CONFIG_DIR="$D"
list() { bash "$D/cc-isolated.sh" --list > "$R/l.out" 2>&1; echo "--list exit=$?"; sed -n '/Host tools/,/^$/p' "$R/l.out"; }

echo "### L0: nothing changed"; mk "$D"; list
echo "### L1: scan only"; mk "$D"; echo '# a' >> "$D/cc-exit-scan.sh"; list
echo "### L2: gitdir only"; mk "$D"; echo '# b' >> "$D/cc-gitdir.sh"; list
echo "### L3: push only"; mk "$D"; echo '# c' >> "$D/cc-push.sh"; list
echo "### L4: push + scan"; mk "$D"; echo '# d' >> "$D/cc-push.sh"; echo '# d' >> "$D/cc-exit-scan.sh"; list
echo "### L5: all three"; mk "$D"; for f in cc-push.sh cc-exit-scan.sh cc-gitdir.sh; do echo '# e' >> "$D/$f"; done; list
echo "### L6: host-tools.sha256 missing"; mk "$D"; rm "$D/host-tools.sha256"; list
echo "### L7: cc-push.sh missing"; mk "$D"; rm "$D/cc-push.sh"; list
echo "### L8: config dir whose parent does not exist (var unset, HOME/.config absent)"
( unset CLAUDE_DEVC_CONFIG_DIR; L="$R/custom8"; mk "$L"; unset CLAUDE_DEVC_CONFIG_DIR
  bash "$L/cc-isolated.sh" --list > "$R/l8.out" 2>&1; echo "--list exit=$?"; cat "$R/l8.out"
  echo "--- same at d2fe61bb"; cp "$P/d2/devcontainer-config/cc-isolated.sh" "$L/cc-isolated.sh"; bash "$L/cc-isolated.sh" --list > "$R/l8b.out" 2>&1; echo "--list exit=$?"; cat "$R/l8b.out" )
echo "### L8-parent: same --list at d2fe61bb's form (statement inside if)"
bash -c 'set -euo pipefail; if x="$(echo "$(readlink -f -- /nonexist/a/b)")"; then echo "if-form: continues, dir=[$x]"; fi'
bash -c 'set -euo pipefail; y="$(readlink -f -- /nonexist/a/b)"; echo "assign-form: continues"'; echo "assign-form exit=$?"
echo "### L9: custom install dir, var unset, scan changed in launcher dir; --list reads config_dir (default)"
( unset CLAUDE_DEVC_CONFIG_DIR; mkdir -p "$HOME/.config"; L="$R/custom9"; mk "$L"; unset CLAUDE_DEVC_CONFIG_DIR; echo '# g' >> "$L/cc-exit-scan.sh"
  bash "$L/cc-isolated.sh" --list 2>&1 | sed -n '/Host tools/,/^$/p'
  bash "$L/cc-isolated.sh" "$ws" >/dev/null 2>"$R/l9.err"; echo "launch exit=$?"; head -1 "$R/l9.err"; rm -rf "$HOME/.config" )

echo "### B1: bless_cmd with a dir containing a space and a quote; \$0 with a space"
SP="$R/my cfg's dir"; mk "$SP"
( export CLAUDE_DEVC_CONFIG_DIR="$SP"; rm "$SP/manifest.sha256"
  bash "$SP/cc-isolated.sh" "$ws" >/dev/null 2>"$R/b1.err"; echo "launch exit=$?"; cat "$R/b1.err" )
echo "--- run the hint's command line verbatim (eval of the printed text, after a re-mk)"
mk "$SP"; echo 'FROM evil' >> "$SP/Dockerfile"
( export CLAUDE_DEVC_CONFIG_DIR="$SP"; bash "$SP/cc-isolated.sh" "$ws" >/dev/null 2>"$R/b1b.err"; echo "launch exit=$?"; cat "$R/b1b.err" )
hint="$(grep -- '--bless' "$R/b1b.err" | head -1 | sed 's/^ *//')"; echo "hint: [$hint]"
( unset CLAUDE_DEVC_CONFIG_DIR; eval "$hint" >/dev/null 2>&1; echo "eval hint exit=$?" )
( export CLAUDE_DEVC_CONFIG_DIR="$SP"; bash "$SP/cc-isolated.sh" "$ws" >/dev/null 2>"$R/b1c.err"; echo "relaunch exit=$? (boundary refusal gone?)"; grep -c 'installed config changed' "$R/b1c.err" )
echo "--- var unset: hint form"
( unset CLAUDE_DEVC_CONFIG_DIR; bash -c 'source "$1"; bless_cmd; echo' _ "$SRC/cc-isolated.sh" )
echo "--- var set to empty"
( export CLAUDE_DEVC_CONFIG_DIR=""; bash -c 'source "$1"; bless_cmd; echo; config_dir' _ "$SRC/cc-isolated.sh" )

echo "### B2: refusal path, custom dir var unset: scan + Dockerfile changed: both bless commands"
( unset CLAUDE_DEVC_CONFIG_DIR; L="$R/custom-b2"; mk "$L"; unset CLAUDE_DEVC_CONFIG_DIR; echo '# g' >> "$L/cc-exit-scan.sh"; echo 'FROM evil' >> "$L/Dockerfile"; echo '# p' >> "$L/cc-push.sh"
  bash "$L/cc-isolated.sh" "$ws" >/dev/null 2>"$R/b2.err"; echo "launch exit=$?"; cat "$R/b2.err" )
echo "### B3: launch-time check_manifest (main), var set to D, Dockerfile changed"
mk "$D"; echo 'FROM evil' >> "$D/Dockerfile"
bash "$D/cc-isolated.sh" "$ws" >/dev/null 2>"$R/b3.err"; echo "launch exit=$?"; head -4 "$R/b3.err"
echo "### B4: --register: does it print a bless hint?"
mk "$D"; bash "$D/cc-isolated.sh" --register "$ws" > "$R/b4.out" 2>&1; echo "register exit=$?"; grep -c -- '--bless' "$R/b4.out"
echo "### done"
