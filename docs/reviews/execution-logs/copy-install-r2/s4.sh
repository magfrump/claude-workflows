#!/bin/bash
W=/workspace/.claude/wt-copyinstall
SP=/tmp/claude-1000/-workspace/d516ca2c-2abb-4732-a34a-041aa98280c8/scratchpad
unset CLAUDECODE CLAUDE_CONFIG_DIR
echo "#### old-README per-file hooks present in repo at d0fdd04?"
for h in log-usage.sh log-usage-post.sh dd-routing-reminder.sh batch-feedback-routing-reminder.sh claude-config-audit.sh guard-trusted-writes.py web-taint-mark.py auto-approve-allowed-commands.sh live-verify-gate.sh; do
  git -C "$W" cat-file -e d0fdd04:hooks/$h 2>/dev/null && echo "present $h" || echo "MISSING $h"
done
echo "#### e5b final dest"; ls -A "$SP/fc/exp/e5b/home/.claude"
echo "#### 712c626 vs 1514518: closed-stdin, --yes, --help, --yes extra"
T=$SP/fc/exp/cmp; rm -rf "$T"; mkdir -p "$T"
for rev in 712c626 1514518; do
  R=$T/$rev; mkdir -p "$R"; git -C "$W" archive $rev | tar -x -C "$R"
  git -C "$R" init -q 2>/dev/null; git -C "$R" add -A; git -C "$R" -c user.email=t@t -c user.name=t commit -qm x
  # stub cc-isolated so --bless is harmless
  printf '#!/usr/bin/env bash\necho "BLESS-STUB $*"\n' > "$R/devcontainer-config/cc-isolated.sh"
  export HOME=$R/home CLAUDE_DEVC_CONFIG_DIR=$R/home/cd CLAUDE_DEVC_BIN_DIR=$R/home/bin TMPDIR=$R/tmp; mkdir -p $HOME $TMPDIR
  for args in "" "--yes" "--help" "--yes extra"; do
    rm -rf "$R/home/cd" "$R/home/bin"
    bash "$R/devcontainer-config/install.sh" $args </dev/null 2>&1 | grep -v -e '^diff\|^---\|^+++\|^@@\|^[-+ ]' | sed "s#$R#<R>#g" > "$T/$rev.$(echo $args|tr ' ' _).out"; echo "rc=${PIPESTATUS[0]}" >> "$T/$rev.$(echo $args|tr ' ' _).out"
  done
done
for a in "" --yes --help --yes_extra; do echo "== args[$a]"; diff "$T/712c626.$a.out" "$T/1514518.$a.out" && echo SAME; done
