#!/usr/bin/env bash
# API-consistency probes for b22a026 (review iteration 6, HEAD 299727c).
# Read-only against the repo: every transcript is written under a temp dir.
# Run from the repo root: bash docs/reviews/execution-logs/acr-299727c-probes.sh
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MOD="$REPO/test/skills"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/acr-299727c.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

# shellcheck source=../../../test/skills/eval-helpers.bash
source "$MOD/eval-helpers.bash"

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
RESULT_NONE='{"type":"result","subtype":"success","result":"# R","permission_denials":[]}'

# The generator's own invocation (generate-reports.bash:287-289), all lines.
gen_verdict() {
  jq -rR -n -L "$MOD" "import \"transcript\" as t; t::events | t::$2 | t::print_verdict" "$1" 2>/dev/null
}

probe() {
  local name="$1" file="$2" def="$3" rc=0 out
  echo "=== $name ($def)"
  echo "--- module lines (what the generator joins into .failed):"
  gen_verdict "$file" "$def" | sed 's/^/    /'
  echo "--- eval side, transcript_verdict:"
  out="$(transcript_verdict "$file" "$def")" || rc=$?
  echo "    rc=$rc: $out"
}

date -u +%Y-%m-%dT%H:%M:%SZ
jq --version

# P1: no init event + an undenied Bash call. The generator records both; the
# eval side prints only the first line.
f="$TMP/p1.jsonl"
printf '%s\n' \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"u1","name":"Bash","input":{"command":"pwd"}}]}}' \
  "$RESULT_NONE" > "$f"
probe "P1 no init + undenied Bash call" "$f" deny_record_failures

# P2: three tool_uses without an id: one unaggregated string per object.
f="$TMP/p2.jsonl"
{ printf '%s\n' "$INIT"
  printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","name":"Bash","input":{"command":"a"}},{"type":"tool_use","name":"Bash","input":{"command":"b"}},{"type":"tool_use","name":"Bash","input":{"command":"c"}}]}}'
  printf '%s\n' "$RESULT_NONE"; } > "$f"
probe "P2 three id-less tool_uses" "$f" deny_record_failures

# P3: one Read call, denied as Read: three distinct conditions, and the
# "Bash tripwire:" label on two that the module comment lists separately.
f="$TMP/p3.jsonl"
{ printf '%s\n' "$INIT"
  printf '%s\n' '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"r1","name":"Read","input":{"file_path":"x"}}]}}'
  printf '%s\n' '{"type":"result","subtype":"success","result":"# R","permission_denials":[{"tool_name":"Read","tool_use_id":"r1"}]}'; } > "$f"
probe "P3 a Read call denied as Read" "$f" deny_record_failures

# P4: a malformed line under deny-record: which strings carry the CLI version.
f="$TMP/p4.jsonl"
printf '%s\n' "$INIT" '{"type":"assistant","message":"oops"}' "$RESULT_NONE" > "$f"
probe "P4 malformed event, CLI 9.9.9 in init" "$f" deny_record_failures

# P5: unreadable transcript, and a caller typo in the verdict name.
probe "P5a missing file" "$TMP/nope.jsonl" transcript_failures
f="$TMP/p5.jsonl"
printf '%s\n' "$INIT" "$RESULT_NONE" > "$f"
probe "P5b a misspelled verdict def (caller bug, good transcript)" "$f" deny_record_failure

# P6: the same good transcript through each verdict def, for the control.
probe "P6 control, good transcript" "$f" deny_record_failures

# P7: an init-only stream with an undenied Bash call as a separate line: what
# transcript_failures says versus the generator's result-event rule.
f="$TMP/p7.jsonl"
printf '%s\n' "$INIT" > "$f"
probe "P7 init-only stream (no result event)" "$f" transcript_failures
jq -rR -n -L "$MOD" 'import "transcript" as t;
  t::events | [.[] | objects | select(.type == "result")] | last
  | if . == null then "none" elif .is_error == true then "error" else "ok" end' "$f" \
  | sed 's/^/    generator result_state (generate-reports.bash:258-261): /'

# P8: which public defs the consumers import (static inventory).
echo "=== P8 public defs vs consumer references"
for d in $(sed -n 's/^def \([a-z][a-z_]*\):.*/\1/p' "$MOD/transcript.jq"); do
  # Dynamic references (t::$def, t::$verdict_def) are listed separately below.
  n="$(cat "$MOD/generate-reports.bash" "$MOD/eval-helpers.bash" | rg -o "t::$d\\b" | wc -l)"
  echo "    $d: $n literal reference(s) in generate-reports.bash + eval-helpers.bash"
done
echo "    dynamic: $(cat "$MOD/generate-reports.bash" "$MOD/eval-helpers.bash" | rg -o 't::\$[a-z_]+' | sort | uniq -c | tr '\n' ' ')"
echo "=== P8b literal sentinel occurrences outside the module"
rg -n --no-heading '__VERDICT_COMPLETE__' "$MOD/generate-reports.bash" "$MOD/eval-helpers.bash" | sed 's/^/    /'

# P9: marker objects in t::events. tool_uses/tool_results skip objects with a
# "__text" key; the other public defs (denials, init) and the generator's own
# result-event reads do not. A placed, undenied Bash call plus a denial that
# sits only in a "__text"-keyed result event:
f="$TMP/p9.jsonl"
printf '%s\n' "$INIT" \
  '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"u1","name":"Bash","input":{"command":"pwd"}}]}}' \
  '{"type":"result","subtype":"success","result":"# real","permission_denials":[]}' \
  '{"__text":"x","type":"result","result":"# from marker","permission_denials":[{"tool_name":"Bash","tool_use_id":"u1"}]}' > "$f"
probe "P9 denial only in a __text-keyed result event" "$f" deny_record_failures
jq -rR -n -L "$MOD" 'import "transcript" as t; t::events
  | "    denials: \(t::denials | tojson)",
    "    generator report text (generate-reports.bash:252-254): \([.[] | objects | select(.type == "result")] | last | .result)"' "$f"
