#!/usr/bin/env bash
# Run one b4fd792 install-host.bats test against an OLDER install.sh.
# usage: prefix.sh <old-commit> <bats -f filter>
# Hermetic: the tree is a git-archive copy under $TMPDIR; the tests pin HOME,
# CLAUDE_HOME_DIR, CLAUDE_DEVC_* and TMPDIR into BATS_TEST_TMPDIR and stub
# pgrep/docker on PATH.
set -u
old="$1" filter="$2"
T="$(mktemp -d "${TMPDIR:-/tmp}/prefix.XXXXXX")"
git -C /workspace archive b4fd792 -- test/install-host.bats devcontainer-config docs/decisions docs/working/plan-copy-install-bare-host.md README.md guides/bare-host-hook-wiring.md hooks scripts | tar -xf - -C "$T"
git -C /workspace show "$old:devcontainer-config/install.sh" > "$T/devcontainer-config/install.sh"
echo "install.sh from $old: $(wc -l < "$T/devcontainer-config/install.sh") lines"
cd "$T" && bats -f "$filter" test/install-host.bats
rc=$?
echo "bats_exit=$rc"
rm -rf "$T"
