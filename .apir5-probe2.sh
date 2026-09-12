#!/usr/bin/env bash
set -uo pipefail
export LC_ALL=C
T="${TMPDIR:-/tmp}/apir5"
CFG="$T/cfg"

echo "=== stability across runs (state 2), via a sourcing shim ==="
cat > "$T/shim.sh" <<'EOF'
source /tmp/apir5/cfg/cc-isolated.sh
compute_manifest
EOF
for i in 1 2 3; do
  CLAUDE_DEVC_CONFIG_DIR="$CFG" bash "$T/shim.sh" > "$T/m$i.txt" 2> "$T/m$i.err"
  echo "run $i exit=$? lines=$(wc -l < "$T/m$i.txt") stderr=$(wc -c < "$T/m$i.err")"
done
if cmp -s "$T/m1.txt" "$T/m2.txt" && cmp -s "$T/m2.txt" "$T/m3.txt"; then echo "STABLE across 3 runs"; else echo "UNSTABLE"; diff "$T/m1.txt" "$T/m2.txt" | head; fi

echo
echo "=== is the path column in LC_ALL=C sort order? ==="
cut -c67- "$T/m1.txt" > "$T/paths.txt"
if LC_ALL=C sort -c "$T/paths.txt" 2>"$T/sorterr"; then echo "yes"; else echo "NO"; cat "$T/sorterr"; fi
echo "duplicate paths: $(sort "$T/paths.txt" | uniq -d | wc -l)"

echo
echo "=== does sort -k2 see the whole path as one key? (space in a path) ==="
mkdir -p "$CFG/claude-home/dir with space"
printf 'x\n' > "$CFG/claude-home/dir with space/a b.md"
CLAUDE_DEVC_CONFIG_DIR="$CFG" bash "$T/shim.sh" > "$T/m_space.txt" 2> "$T/m_space.err"
echo "exit=$? lines=$(wc -l < "$T/m_space.txt")"
grep -n 'dir with space' "$T/m_space.txt" || echo "  (no row)"
echo "stderr:"; cat "$T/m_space.err"
rm -rf "$CFG/claude-home/dir with space"

echo
echo "=== empty-list guard ==="
mkdir -p "$T/empty"
CLAUDE_DEVC_CONFIG_DIR="$T/empty" bash "$CFG/cc-isolated.sh" --bless > "$T/bless-nothing.txt" 2> "$T/bless-nothing.err"
echo "exit=$?"
echo "--- stdout ---"; cat "$T/bless-nothing.txt"
echo "--- stderr ---"; cat "$T/bless-nothing.err"
echo "manifest left behind: $([ -f "$T/empty/manifest.sha256" ] && echo "yes size=$(wc -c < "$T/empty/manifest.sha256")" || echo no)"

echo
echo "=== check_manifest against a repointed symlink ==="
CLAUDE_DEVC_CONFIG_DIR="$CFG" bash "$CFG/cc-isolated.sh" --bless > /dev/null 2>&1
rm "$CFG/claude-home/aa-linked-patterns"; ln -s ./guides "$CFG/claude-home/aa-linked-patterns"
cat > "$T/shim2.sh" <<'EOF'
source /tmp/apir5/cfg/cc-isolated.sh
check_manifest
EOF
CLAUDE_DEVC_CONFIG_DIR="$CFG" bash "$T/shim2.sh" > "$T/chk.out" 2> "$T/chk.err"
echo "check_manifest exit=$?"
head -8 "$T/chk.err"

echo
echo "=== --print-entries through the real entrypoint ==="
cd /workspace/devcontainer-config || exit 1
CC_EGRESS_DIR=/workspace/devcontainer-config/egress CC_EGRESS_PROFILE_FILE=/dev/null bash ./init-firewall.sh --print-entries > "$T/pe.out" 2> "$T/pe.err"
echo "base-only exit=$? lines=$(wc -l < "$T/pe.out")"
cat "$T/pe.out" | cat -A | head -8
echo "stderr:"; cat "$T/pe.err"
printf 'python\n' > "$T/prof"
CC_EGRESS_DIR=/workspace/devcontainer-config/egress CC_EGRESS_PROFILE_FILE="$T/prof" bash ./init-firewall.sh --print-entries > "$T/pe2.out" 2> "$T/pe2.err"
echo "base+python exit=$? lines=$(wc -l < "$T/pe2.out")"
echo "stderr:"; cat "$T/pe2.err"
printf 'nosuch\n' > "$T/prof3"
CC_EGRESS_DIR=/workspace/devcontainer-config/egress CC_EGRESS_PROFILE_FILE="$T/prof3" bash ./init-firewall.sh --print-entries > "$T/pe3.out" 2> "$T/pe3.err"
echo "unknown-profile exit=$? stdout_lines=$(wc -l < "$T/pe3.out")"
cat "$T/pe3.err"
