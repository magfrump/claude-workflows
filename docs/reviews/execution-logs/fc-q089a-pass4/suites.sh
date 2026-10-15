#!/usr/bin/env bash
# Run cc-isolated-functions and cc-push suites at fa059477 (head) and 4ab9a51f (main). Run: suites.sh <probe-root> <logdir>
set -u
P="$1"; L="$2"
for t in head main; do
  for s in cc-isolated-functions cc-push; do
    date -u +%FT%TZ > "$L/$t-$s.ts"
    ( cd "$P/$t" && HOME="$P/home" CLAUDE_DEVC_CONFIG_DIR="$P/cfg" TMPDIR="$P/tmp" timeout 900 bats "test/$s.bats" ) > "$L/$t-$s.log" 2>&1
    echo $? > "$L/$t-$s.rc"
    echo "$t $s: rc=$(cat "$L/$t-$s.rc") ok=$(grep -c '^ok ' "$L/$t-$s.log") notok=$(grep -c '^not ok ' "$L/$t-$s.log") plan=$(grep -m1 -E '^1\.\.' "$L/$t-$s.log")"
  done
done
