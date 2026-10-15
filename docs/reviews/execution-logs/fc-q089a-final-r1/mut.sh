#!/bin/bash
# usage: mut.sh <P> <name> <perl-expr> <file> <bats-filter>
set -u
P="$1"; name="$2"; expr="$3"; file="$4"; filt="$5"
W="$(mktemp -d "$P/_tmp/mut-$name.XXXXXX")" || exit 9
[ -d "$W" ] || exit 9
cd "$W" || exit 9
cp -r "$P/devcontainer-config" "$P/test" . 
perl -0pi -e "$expr" "devcontainer-config/$file"
if cmp -s "$P/devcontainer-config/$file" "devcontainer-config/$file"; then echo "MUTATION DID NOT APPLY"; exit 9; fi
env HOME="$P/_home" TMPDIR="$P/_tmp" CLAUDE_DEVC_CONFIG_DIR="$P/_cfg" CC_PUSH_CLONES_DIR="$P/_clones" LC_ALL=C timeout 600 bats -f "$filt" test/cc-isolated-functions.bats 2>&1 | grep -v setlocale
echo "bats exit=${PIPESTATUS[0]}"
