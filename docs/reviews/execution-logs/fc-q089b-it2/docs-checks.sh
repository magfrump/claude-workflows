#!/usr/bin/env bash
# JSON validity of the wiring file, table cell counts in both guides, and a
# lint of the reviewer probe scripts with and without their disable lines.
# (Comment reworded after the run: a comment line opening with the linter's
# name is parsed as a directive. Behaviour unchanged.)
# $1 = probe root.
D="$1"
case "$D" in /home/node/.claude/jobs/00bcf178/tmp/fc-it2.*) ;; *) echo "bad D"; exit 1 ;; esac
export HOME="$D/home" LC_ALL=C
cd "$D/src" || exit 1
W=hooks/wiring.json
{ echo "start: $(date -u +%FT%TZ) cwd: $PWD"
  echo "\$ jq empty $W"; jq empty "$W"; echo "exit=$?"
  echo "\$ python3 json.load $W"; python3 -I -c 'import json,sys; json.load(open(sys.argv[1])); print("ok")' "$W"; echo "exit=$?"
} > "$D/logs/wiring-json.log" 2>&1

python3 -I "$D/scripts/tables.py" guides/cc-isolated-usage.md guides/devcontainer-setup.md > "$D/logs/table-cells.log" 2>&1
echo "tables exit=$?" >> "$D/logs/table-cells.log"

{ echo "start: $(date -u +%FT%TZ) cwd: $PWD $(shellcheck --version | grep ^version)"
  for f in docs/reviews/execution-logs/fc-q089b/run-bats.sh docs/reviews/execution-logs/fc-q089b/run-m3.sh \
           docs/reviews/execution-logs/fc-q089b/run-probes.sh docs/reviews/execution-logs/sec-q089b/probe.sh \
           docs/reviews/execution-logs/sec-q089b/probe2.sh; do
    echo "== $f (as committed)"; timeout 60 shellcheck "$f"; echo "exit=$?"
    grep -v '^# shellcheck disable=' "$f" > "$D/tmpd/stripped.sh"
    echo "== $f (disable line removed)"; timeout 60 shellcheck "$D/tmpd/stripped.sh"; echo "exit=$?"
    echo "== diff vs stripped (non-comment lines)"; diff <(grep -v '^[[:space:]]*#' "$f") <(grep -v '^[[:space:]]*#' "$D/tmpd/stripped.sh") && echo "identical code lines"
  done
} > "$D/logs/shellcheck-probes.log" 2>&1
