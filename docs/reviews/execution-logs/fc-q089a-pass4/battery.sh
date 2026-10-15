#!/usr/bin/env bash
# Re-run the commit's 15-form mutation battery and 20 clean runs against fa059477. Run: battery.sh <probe-root>
set -u
P="$1"; [ -d "$P/head" ] || exit 2
cd "$P" || exit 2
mkdir -p "$P/bat"
run_mut() {
  local name="$1" body="$2" d="$P/bat/$1"
  rm -rf "$d"; mkdir -p "$d/test"; cp -r "$P/head/devcontainer-config" "$d/"; cp "$P/head/test/cc-isolated-functions.bats" "$d/test/"
  printf '\n__probe_mut() {\n%s\n}\n' "$body" >> "$d/devcontainer-config/cc-exit-scan.sh"
  if HOME="$P/home" CLAUDE_DEVC_CONFIG_DIR="$P/cfg" TMPDIR="$P/tmp" timeout 120 \
       bats -f 'every file an entry point sources' "$d/test/cc-isolated-functions.bats" > "$P/bat/$name.out" 2>&1; then
    echo "$name: TEST PASSES (not caught)"
  else echo "$name: caught"; fi
}
run_mut b01-if-source 'if source "$EVIL"; then :; fi'
run_mut b02-elif-dot 'if false; then :; elif . "$EVIL"; then :; fi'
run_mut b03-while-source 'while source "$EVIL"; do :; done'
run_mut b04-bang-dot '! . "$EVIL"'
run_mut b05-builtin-source 'builtin source "$EVIL"'
run_mut b06-command-dot 'command . "$EVIL"'
run_mut b07-time-source 'time source "$EVIL"'
run_mut b08-eval 'eval "source \"\$EVIL\""'
run_mut b09-backtick 'x=`source "$EVIL"`'
run_mut b10-two-on-line 'source "$CC_ISOLATED_DIR/cc-gitdir.sh"; source "$EVIL"'
run_mut b11-sibling-in-comment 'source "$EVIL" # "$CC_ISOLATED_DIR/cc-gitdir.sh"'
run_mut b12-nonsibling 'source "/tmp/x/cc-gitdir.sh"'
run_mut b13-dot '  . "$EVIL"'
run_mut b14-midline 'x=1; source "$EVIL"'
run_mut b15-dynamic 'source "$CC_ISOLATED_DIR/$name.sh"'
echo "## 20 clean runs of the unmodified test"
pass=0
for i in $(seq 1 20); do
  if HOME="$P/home" CLAUDE_DEVC_CONFIG_DIR="$P/cfg" TMPDIR="$P/tmp" timeout 120 \
       bats -f 'every file an entry point sources' "$P/head/test/cc-isolated-functions.bats" > "$P/bat/clean$i.out" 2>&1; then pass=$((pass+1)); fi
done
echo "clean: $pass/20 pass"
