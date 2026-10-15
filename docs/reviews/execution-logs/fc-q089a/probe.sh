#!/usr/bin/env bash
# Hermetic probes for the unit A fact-check. Everything lives under $E; HOME is redirected.
set -u
E=/home/node/.claude/jobs/00bcf178/tmp/fc-q089A.jPV8xH
[ -d "$E/A/devcontainer-config" ] || { echo "no probe dir"; exit 1; }
W="$E/w"; rm -rf "$W"; mkdir -p "$W" || exit 1
cd "$W" || exit 1
export HOME="$W/home"; mkdir -p "$HOME"
unset CLAUDE_DEVC_CONFIG_DIR; export LC_ALL=C
SRC_A="$E/A/devcontainer-config"; SRC_M="$E/M/devcontainer-config"
PAY="devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh egress"
install_from() { # src dest
  mkdir -p "$2/projects"; for i in $PAY; do rm -rf "${2:?}/$i"; cp -Rp "$1/$i" "$2/$i"; done
}
bh() { sha256sum < "$1/manifest.sha256" | cut -c1-16; }
ws="$W/ws"; mkdir -p "$ws"; git -C "$ws" init -q

echo "=== P1 upgrade: old (main) install blessed, then unit A files + install.sh's bless command"
D="$HOME/.config/claude-devcontainer"; mkdir -p "$D"
install_from "$SRC_M" "$D"
CLAUDE_DEVC_CONFIG_DIR="$D" bash "$D/cc-isolated.sh" --bless >/dev/null; echo "old bless rc=$?"
echo "old manifest lists host tools: $(grep -cE 'cc-(push|gitdir|exit-scan)\.sh' "$D/manifest.sha256")"
old_bh="$(bh "$D")"; echo "$old_bh" > "$D/verified-live.sha256"
install_from "$SRC_A" "$D"
echo "host-tools.sha256 before new bless: $([ -e "$D/host-tools.sha256" ] && echo present || echo absent)"
CLAUDE_DEVC_CONFIG_DIR="$D" "$D/cc-isolated.sh" --bless > "$W/p1-bless.out" 2>&1; echo "new bless rc=$?"
grep -E 'Blessed config|Verified live' "$W/p1-bless.out"
echo "host-tools.sha256 after: $(awk '{print $2}' "$D/host-tools.sha256" | tr '\n' ' ')"
new_bh="$(bh "$D")"; echo "blessed_hash old=$old_bh new=$new_bh changed=$([ "$old_bh" != "$new_bh" ] && echo yes || echo no)"

echo "=== P2 host-tool-only edit + re-bless: blessed_hash and receipt unchanged"
echo "$new_bh" > "$D/verified-live.sha256"
mkdir -p "$HOME/.local/bin"; ln -sf "$D/cc-isolated.sh" "$HOME/.local/bin/cc-isolated"; ln -sf "$D/cc-push.sh" "$HOME/.local/bin/cc-push"
echo '# comment edit' >> "$D/cc-exit-scan.sh"
"$HOME/.local/bin/cc-isolated" "$ws" > "$W/p2-launch.out" 2>&1; echo "launch via ~/.local/bin symlink rc=$?"; cat "$W/p2-launch.out"
for a in --probe-only "--register $ws --profile python" --help --list "--bogus"; do
  # shellcheck disable=SC2086
  "$HOME/.local/bin/cc-isolated" $a > "$W/p2-a.out" 2>&1; echo "  action [$a] rc=$? first: $(head -1 "$W/p2-a.out")"
done
"$HOME/.local/bin/cc-isolated" --bless > "$W/p2-bless.out" 2>&1; echo "rebless rc=$?"; grep -E 'Blessed config|Verified live' "$W/p2-bless.out"
echo "blessed_hash now $(bh "$D") (was $new_bh)"
"$HOME/.local/bin/cc-isolated" "$ws" > "$W/p2-launch2.out" 2>&1; echo "launch after rebless rc=$? first: $(head -1 "$W/p2-launch2.out")"

echo "=== P3 default layout opt-out attempts (dir == cfg)"
cp "$D/host-tools.sha256" "$W/ht.bak"; cp "$D/manifest.sha256" "$W/m.bak"
rm "$D/host-tools.sha256"
"$HOME/.local/bin/cc-push" --help > "$W/o.out" 2>&1; echo "delete host-tools only: cc-push rc=$? $(head -1 "$W/o.out")"
rm "$D/manifest.sha256"
"$HOME/.local/bin/cc-push" --help > "$W/o.out" 2>&1; echo "delete both, env unset: cc-push rc=$? $(head -1 "$W/o.out")"
"$HOME/.local/bin/cc-isolated" --list > "$W/o.out" 2>&1; echo "delete both, env unset: launcher --list rc=$?"
"$HOME/.local/bin/cc-isolated" "$ws" > "$W/o.out" 2>&1; echo "delete both, env unset: launcher launch rc=$? $(head -1 "$W/o.out")"
CLAUDE_DEVC_CONFIG_DIR="$D/" "$HOME/.local/bin/cc-push" --help > "$W/o.out" 2>&1; echo "delete both, env=D/ (trailing slash): cc-push rc=$? $(head -1 "$W/o.out")"
cp "$W/ht.bak" "$D/host-tools.sha256"; cp "$W/m.bak" "$D/manifest.sha256"

echo "=== P4 custom dir at install (C), env unset at run time"
C="$W/custom"; mkdir -p "$C"; install_from "$SRC_A" "$C"
CLAUDE_DEVC_CONFIG_DIR="$C" "$C/cc-isolated.sh" --bless >/dev/null 2>&1; echo "bless C rc=$?"
ln -sf "$C/cc-push.sh" "$W/cc-push-c"
printf 'touch %q\n' "$W/gitdir-ran" >> "$C/cc-gitdir.sh"
"$W/cc-push-c" --help > "$W/o.out" 2>&1; echo "tampered, manifests present, env unset: rc=$? $(head -1 "$W/o.out") ran=$([ -e "$W/gitdir-ran" ] && echo yes || echo no)"
rm -f "$C/host-tools.sha256"
"$W/cc-push-c" --help > "$W/o.out" 2>&1; echo "tampered, host-tools deleted, env unset: rc=$? ran=$([ -e "$W/gitdir-ran" ] && echo yes || echo no)"
rm -f "$C/manifest.sha256"
"$W/cc-push-c" --help > "$W/o.out" 2>&1; echo "tampered, BOTH deleted, env unset: rc=$? ran=$([ -e "$W/gitdir-ran" ] && echo yes || echo no)"
rm -f "$W/gitdir-ran"
CLAUDE_DEVC_CONFIG_DIR="$C" "$W/cc-push-c" --help > "$W/o.out" 2>&1; echo "tampered, BOTH deleted, env=C: rc=$? ran=$([ -e "$W/gitdir-ran" ] && echo yes || echo no)"
rm -f "$W/gitdir-ran"

echo "=== P5 config dir reached through a symlink (default path is a link to R)"
R="$W/real-cfg"; mkdir -p "$R"; install_from "$SRC_A" "$R"
mv "$D" "$W/d-aside"; ln -s "$R" "$D"
"$D/cc-isolated.sh" --bless >/dev/null 2>&1; echo "bless via link rc=$?"
rm -f "$R/host-tools.sha256" "$R/manifest.sha256"
"$R/cc-push.sh" --help > "$W/o.out" 2>&1; echo "both deleted, cfg is a symlink to dir: cc-push rc=$? $(head -1 "$W/o.out")"
rm "$D"; mv "$W/d-aside" "$D"

echo "=== P6 repo checkout (no manifests, not cfg): unchecked; sourcing with a failed check"
bash "$SRC_A/cc-push.sh" --help >/dev/null 2>&1; echo "repo cc-push --help rc=$?"
bash -c 'set -euo pipefail; source "$1/cc-isolated.sh"; echo "sourced ok, HOST_TOOLS_ERR=[${HOST_TOOLS_ERR}]"; type -t git_exit_scan || echo "git_exit_scan undefined"' _ "$SRC_A"
echo '# x' >> "$D/cc-gitdir.sh"
bash -c 'set -euo pipefail; source "$1/cc-isolated.sh"; echo "sourced installed copy with mismatch: survived, HOST_TOOLS_ERR=[${HOST_TOOLS_ERR}]"; type -t git_exit_scan || echo "git_exit_scan undefined"' _ "$D"
echo "=== done"
