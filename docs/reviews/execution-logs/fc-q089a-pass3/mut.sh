#!/usr/bin/env bash
# Mutation probe for the source-set test (fact-check pass 3). Run: mut.sh <probe-root>
set -u
P="$1"; [ -d "$P/head" ] || { echo "no $P/head"; exit 2; }
cd "$P" || exit 2
run_mut() {
  local name="$1" body="$2" d
  d="$P/mut/$name"
  rm -rf "$d"; mkdir -p "$d/test"
  cp -r "$P/head/devcontainer-config" "$d/"
  cp "$P/head/test/cc-isolated-functions.bats" "$d/test/"
  # appended inside a never-called function so sourcing the file runs nothing
  printf '\n__probe_mut() {\n%s\n}\n' "$body" >> "$d/devcontainer-config/cc-exit-scan.sh"
  if HOME="$P/home" CLAUDE_DEVC_CONFIG_DIR="$P/cfg" TMPDIR="$P/tmp" timeout 120 \
       bats -f 'every file an entry point sources' "$d/test/cc-isolated-functions.bats" > "$P/mut/$name.out" 2>&1; then
    echo "$name: TEST PASSES (form not caught)"
  else
    echo "$name: test fails (caught)"
  fi
}
mkdir -p "$P/mut"
run_mut C1-control-linestart 'source "$EVIL"'
run_mut C2-control-dot-in-fn '  . "$EVIL"'
run_mut C3-line-continuation 'source \
  "$EVIL"'
run_mut M1-builtin-source 'builtin source "$EVIL"'
run_mut M2-command-dot 'command . "$EVIL"'
run_mut M3-eval 'eval "source \"\$EVIL\""'
run_mut M4-if-source 'if source "$EVIL"; then :; fi'
run_mut M5-bang-dot '! . "$EVIL"'
run_mut M6-while-source 'while source "$EVIL"; do :; done'
run_mut M7-elif-dot 'if false; then :; elif . "$EVIL"; then :; fi'
run_mut M8-backtick 'x=`source "$EVIL"`'
run_mut M9-second-on-line 'source "$D/cc-gitdir.sh"; source "$EVIL"'
run_mut M10-nonsibling-path 'source "/tmp/x/cc-gitdir.sh"'
run_mut M11-trailing-comment 'source "$EVIL" # was "$D/cc-gitdir.sh"'
run_mut M12-time-source 'time source "$EVIL"'
run_mut M13-newfile-sibling 'source "$D/cc-evil.sh"'
run_mut F1-prose-undo 'echo "to undo . that, rerun"'
run_mut F2-prose-semicolon 'echo "the manifest; source of truth"'
run_mut F3-heredoc 'cat <<TXT
then . is not a command here
TXT'
