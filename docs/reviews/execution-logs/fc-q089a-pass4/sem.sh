#!/usr/bin/env bash
# Does each form that passed the strict test actually source a file in bash? Run: sem.sh <probe-root>
set -u
P="$1"; S="$P/sem"; rm -rf "$S"; mkdir -p "$S" || exit 2
printf 'echo SOURCED\n' > "$S/evil.sh"
export EVIL="$S/evil.sh"
t() { local out; out="$(cd "$S" && timeout 10 bash -c "set -euo pipefail; $2" 2>&1)"; case "$out" in *SOURCED*) echo "$1: sources EVIL";; *) echo "$1: does NOT source ($out)";; esac; }
t O1-backslash-dot '\. "$EVIL"'
t O2-quoted-dot '"." "$EVIL"'
t O3-squoted-source "s'o'urce \"\$EVIL\""
t O4-dquote-split 'so""urce "$EVIL"'
t O5-assign-prefix-dot 'FOO=1 . "$EVIL"'
t O6-case-arm-dot 'case x in x) . "$EVIL" ;; esac'
t O7-time-p-dot 'time -p . "$EVIL"'
t O8-command-p-dot 'command -p . "$EVIL"'
t O9-ansi-c "\$'\\x73ource' \"\$EVIL\""
t O10-var-cmd 'c=sour; c+=ce; $c "$EVIL"'
t O11-hash-line-in-string 'x="
#"; . "$EVIL"'
t O12-coproc-dot 'coproc . "$EVIL"; wait'
echo "--- C7: the scan's canonical-spelled \$CC_PUSH_DIR, launcher context (unset), under set -u"
t C7-unset 'source "$CC_PUSH_DIR/evil.sh"'
CC_PUSH_DIR="$S" t C7-exported 'source "$CC_PUSH_DIR/evil.sh"'
