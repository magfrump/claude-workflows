#!/usr/bin/env bash
# Upgrade probe: an install blessed by 4ab9a51f's launcher (no host-tools.sha256),
# then afe1ae59's PAYLOAD files copied over and blessed the way install.sh:607 does
# (CLAUDE_DEVC_CONFIG_DIR="$DEST" "$DEST/cc-isolated.sh" --bless). Hermetic.
set -u
BASE=/home/node/.claude/jobs/00bcf178/tmp
REPO=/workspace/.claude/wt-q089
export LC_ALL=C
d="$(mktemp -d "$BASE/fcr3-upg.XXXXXX")" || exit 1
cd "$d" || exit 1
mkdir -p old new home tmp dest stub
git -C "$REPO" archive 4ab9a51f devcontainer-config | tar -x -C old || exit 1
git -C "$REPO" archive afe1ae59 devcontainer-config | tar -x -C new || exit 1
printf '#!/usr/bin/env bash\nexit 0\n' > stub/devcontainer; chmod +x stub/devcontainer
export HOME="$d/home" TMPDIR="$d/tmp" CLAUDE_DEVC_CONFIG_DIR="$d/dest" PATH="$d/stub:$PATH"
inst() { # copy the hashed payload files (no claude-home: not needed for this probe)
  for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh \
           cc-exit-scan.sh cc-gitdir.sh cc-push.sh link-claude-home.sh; do
    cp "$1/devcontainer-config/$f" "$d/dest/$f"
  done
  rm -rf "$d/dest/egress"; cp -r "$1/devcontainer-config/egress" "$d/dest/egress"
}
echo "=== $(date -u +%FT%TZ) dir=$d"
inst old
echo "--- old bless"; timeout 60 bash "$d/dest/cc-isolated.sh" --bless >/dev/null; echo "exit=$?"
ls "$d/dest"
grep -c 'cc-push.sh' "$d/dest/manifest.sha256"
inst new
echo "--- new launcher before bless (expect refusal; launch action)"
timeout 60 bash "$d/dest/cc-isolated.sh" "$d" 2>&1 | head -12; echo "exit=${PIPESTATUS[0]}"
echo "--- install.sh-style bless"
timeout 60 bash "$d/dest/cc-isolated.sh" --bless > "$d/bless.out" 2>&1; echo "exit=$?"
grep -n 'No previous\|Changed since\|Blessed host tools\|ERROR' "$d/bless.out"
ls "$d/dest"
echo "--- --list after"
timeout 60 bash "$d/dest/cc-isolated.sh" --list 2>&1 | head -3
echo "--- cc-push --help after (installed copy)"
timeout 60 bash "$d/dest/cc-push.sh" --help >/dev/null 2>&1; echo "exit=$?"
