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
run_mut C4-midline-source ': ok; source "$EVIL"'
