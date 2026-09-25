#!/bin/bash
# T60 (b4fd792 test) against fa69656's install.sh (the commit before dfa5791).
SP=/tmp/claude-1000/-workspace/7630264d-3947-4203-a0ec-b9ffcc3a4e06/scratchpad/x
L=/workspace/docs/reviews/execution-logs/q058-r1-prefix-replays.log
rm -rf "$SP/tree-fa69656"; mkdir -p "$SP/tree-fa69656/test"
git -C /workspace archive fa69656 | tar -xf - -C "$SP/tree-fa69656"
git -C /workspace show b4fd792:test/install-host.bats \
  | sed "s|^  CONFIG_SRC=.*|  CONFIG_SRC=\"$SP/tree-fa69656/devcontainer-config\"|" > "$SP/tree-fa69656/test/t60.bats"
{
  echo
  echo "## $(date -u +%FT%TZ) T60 against fa69656 install.sh, LC_ALL=C, cwd $SP/tree-fa69656"
  cd "$SP/tree-fa69656" && env LC_ALL=C LANG=C LANGUAGE= bats -f 'T60' test/t60.bats
  echo "exit=$?"
} >> "$L" 2>&1
sed -n '/T60 against fa69656/,$p' "$L"
