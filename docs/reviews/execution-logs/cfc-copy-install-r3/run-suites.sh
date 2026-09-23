#!/usr/bin/env bash
# Run install-host.bats at HEAD and at dcf4a6d (tests vs the pre-change install.sh), plus link-claude-home-wiring at HEAD.
set -u
FC=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-r3
WT=/workspace/.claude/wt-copyinstall
LOG="$FC/logs"; mkdir -p "$LOG"; : > "$LOG/exits.txt"
export TMPDIR="$FC/tmp"; mkdir -p "$TMPDIR"
unset CLAUDECODE CLAUDE_CONFIG_DIR
for rev in d0fdd04 dcf4a6d; do
  d="$FC/tree-$rev"; rm -rf "$d"; mkdir -p "$d"
  git -C "$WT" archive "$rev" | tar -x -C "$d"
done
date -u +%FT%TZ > "$LOG/timestamp.txt"
( cd "$FC/tree-d0fdd04" && bats test/install-host.bats ) > "$LOG/head-install-host.txt" 2>&1; echo "head install-host exit=$?" >> "$LOG/exits.txt"
( cd "$FC/tree-dcf4a6d" && bats test/install-host.bats ) > "$LOG/dcf4a6d-install-host.txt" 2>&1; echo "dcf4a6d install-host exit=$?" >> "$LOG/exits.txt"
( cd "$FC/tree-d0fdd04" && bats test/link-claude-home-wiring.bats ) > "$LOG/head-lchw.txt" 2>&1; echo "head lchw exit=$?" >> "$LOG/exits.txt"
( cd "$FC/tree-d0fdd04" && bats test/cc-isolated-functions.bats ) > "$LOG/head-ccif.txt" 2>&1; echo "head ccif exit=$?" >> "$LOG/exits.txt"
echo done >> "$LOG/exits.txt"
