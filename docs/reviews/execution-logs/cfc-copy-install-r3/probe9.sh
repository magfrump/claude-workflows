#!/usr/bin/env bash
# P9: top-level CLAUDE.md symlink dangling (e.g. checkout moved). Hermetic, under probe/p9.
set -u
FC=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad/cfc-r3
# shellcheck source=/dev/null
source <(sed -n '/^setenv()/,/^hr()/p' "$FC/probe.sh")
B="$FC/probe"; export SHELL=/bin/bash; unset CLAUDECODE CLAUDE_CONFIG_DIR
hr "P9 top-level CLAUDE.md dangling"; rm -rf "$B/p9"; setenv p9; fake_repo "$B/install-head.sh"
mkdir -p "$CLAUDE_HOME_DIR"; ln -s "$C/old-checkout/global-instructions/CLAUDE.md" "$CLAUDE_HOME_DIR/CLAUDE.md"
pty 'n\ny\n' "env -u CLAUDECODE $INSTALL" | sed -n '/Changes this/,$p' | grep -v '^[-+@ ]\|^diff -ruN'
ls -A "$CLAUDE_HOME_DIR"
