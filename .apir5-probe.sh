#!/usr/bin/env bash
# Temporary review harness (api-consistency r5). Not committed.
set -euo pipefail
export LC_ALL=C
T="${TMPDIR:-/tmp}/apir5"
rm -rf "$T"; mkdir -p "$T/cfg"
SRC=/workspace/devcontainer-config
for f in devcontainer.json Dockerfile init-firewall.sh cc-sni-proxy.py cc-isolated.sh link-claude-home.sh; do
  cp "$SRC/$f" "$T/cfg/"
done
cp -r "$SRC/egress" "$T/cfg/egress"
cp -r "$SRC/claude-home" "$T/cfg/claude-home"
mkdir -p "$T/cfg/projects"
# exercise the symlink branch: a link inside the walked tree
ln -s ../guides "$T/cfg/claude-home/skills/zz-linked-guides"
ln -s ./patterns "$T/cfg/claude-home/aa-linked-patterns"

run_bless() {
  CLAUDE_DEVC_CONFIG_DIR="$T/cfg" bash "$T/cfg/cc-isolated.sh" --bless
}

echo "=== STATE 1: projects/ EMPTY ==="
set +e
run_bless > "$T/bless-empty.txt" 2> "$T/bless-empty.err"
echo "exit=$?"
set -e
head -1 "$T/bless-empty.txt"
echo "body lines: $(( $(wc -l < "$T/bless-empty.txt") - 1 ))"
echo "claude-home entries: $(grep -c ' claude-home/' "$T/bless-empty.txt" || true)"
echo "symlink entries:"; grep -n 'zz-linked-guides\|aa-linked-patterns' "$T/bless-empty.txt" || echo "  (none)"
echo "--- stderr ---"; cat "$T/bless-empty.err"

echo
echo "=== STATE 2: one .profile present ==="
printf 'python\n' > "$T/cfg/projects/abc123abc123.profile"
set +e
run_bless > "$T/bless-one.txt" 2> "$T/bless-one.err"
echo "exit=$?"
set -e
head -1 "$T/bless-one.txt"
echo "body lines: $(( $(wc -l < "$T/bless-one.txt") - 1 ))"
echo "claude-home entries: $(grep -c ' claude-home/' "$T/bless-one.txt" || true)"
echo "--- stderr ---"; cat "$T/bless-one.err"

echo
echo "=== manifest file itself (state 2) ==="
echo "manifest lines: $(wc -l < "$T/cfg/manifest.sha256")"
echo "two-space separator violations: $(grep -cvE '^[0-9a-f]{64}  [^ ]' "$T/cfg/manifest.sha256" || true)"
echo "sample symlink rows:"; grep 'zz-linked-guides\|aa-linked-patterns' "$T/cfg/manifest.sha256"
echo "first 3 rows:"; head -3 "$T/cfg/manifest.sha256"

echo
echo "=== sha256sum -c compatibility ==="
cd "$T/cfg"
set +e
sha256sum -c --quiet manifest.sha256 > "$T/check.out" 2> "$T/check.err"
echo "sha256sum -c exit=$?"
set -e
echo "--- check stdout (first 5) ---"; head -5 "$T/check.out"
echo "--- check stderr (first 5) ---"; head -5 "$T/check.err"

echo
echo "=== stability across runs (state 2) ==="
cd /workspace
for i in 1 2 3; do
  CLAUDE_DEVC_CONFIG_DIR="$T/cfg" bash -c 'source "$0"; compute_manifest' "$T/cfg/cc-isolated.sh" > "$T/m$i.txt"
done
if cmp -s "$T/m1.txt" "$T/m2.txt" && cmp -s "$T/m2.txt" "$T/m3.txt"; then echo "STABLE across 3 runs"; else echo "UNSTABLE"; diff "$T/m1.txt" "$T/m2.txt" | head; fi
echo "sorted -k2 check: $(cmp -s <(cut -d' ' -f3- "$T/m1.txt") <(cut -d' ' -f3- "$T/m1.txt" | LC_ALL=C sort) && echo yes || echo NO)"

echo
echo "=== duplicate-hash collation probe (does -k2 tie-break on field 1?) ==="
cut -d' ' -f3- "$T/m1.txt" | LC_ALL=C sort -c && echo "path column is in LC_ALL=C sort order" || echo "path column NOT sorted"
echo "duplicate paths: $(cut -d' ' -f3- "$T/m1.txt" | sort | uniq -d | wc -l)"
echo "duplicate hashes: $(cut -d' ' -f1 "$T/m1.txt" | sort | uniq -d | wc -l)"

echo
echo "=== empty-list guard ==="
mkdir -p "$T/empty"
set +e
CLAUDE_DEVC_CONFIG_DIR="$T/empty" bash "$T/cfg/cc-isolated.sh" --bless > "$T/bless-nothing.txt" 2> "$T/bless-nothing.err"
echo "exit=$?"
set -e
echo "--- stdout ---"; cat "$T/bless-nothing.txt"
echo "--- stderr ---"; cat "$T/bless-nothing.err"
echo "manifest file left behind: $([ -f "$T/empty/manifest.sha256" ] && echo yes || echo no) size=$(wc -c < "$T/empty/manifest.sha256" 2>/dev/null || echo n/a)"
