#!/usr/bin/env bash
# architecture-review 299727c (iteration 6): does the insertion property, once
# it also varies the module's own vocabulary, reach Claim 24 (the "__text"
# marker) and Claim 25b (substring "allowlists")? And does the minimal
# structural fix close both without breaking the table or the controls?
#
# Modules compared (all read the same inputs, jq only, no claude, no network):
#   HEAD  test/skills/transcript.jq as committed
#   fixA  ignored (bracket-free, unparsable) lines are DROPPED by `events`
#         instead of represented as {"__text": ...}; every has("__text") test
#         is deleted. No in-band marker can then mean "ignore".
#   fixB  fixA + the two type allowlists use IN(...) (equality) instead of
#         inside/1 (substring for strings).
# Run from anywhere; writes only under a mktemp dir.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "started $(date -u +%Y-%m-%dT%H:%M:%SZ) jq=$(jq --version) repo=$repo"

mkdir -p "$tmp/HEAD" "$tmp/fixA" "$tmp/fixB"
cp "$repo/test/skills/transcript.jq" "$tmp/HEAD/transcript.jq"
python3 - "$repo/test/skills/transcript.jq" "$tmp/fixA/transcript.jq" "$tmp/fixB/transcript.jq" <<'PY'
import sys
src = open(sys.argv[1]).read()
a = src
for old, new in [
    ('{"__unparsed": $line} else {"__text": $line} end', '{"__unparsed": $line} else empty end'),
    ('select(has("__text") | not) | ', ''),
    ('  elif has("__text") then empty\n', ''),
]:
    assert old in a, old
    a = a.replace(old, new)
assert '__text' not in a.split('# The events, in order.')[1].split('def _is_str')[1]
open(sys.argv[2], 'w').write(a)
b = a
for old, new in [
    ('([.type] | inside(["system", "assistant", "user", "result", "rate_limit_event"]) | not)',
     '(.type | IN("system", "assistant", "user", "result", "rate_limit_event") | not)'),
    ('([.type] | inside(["text", "thinking", "redacted_thinking", "tool_use"]) | not)',
     '(.type | IN("text", "thinking", "redacted_thinking", "tool_use") | not)'),
    ('([.type] | inside(["tool_result", "text"]) | not)',
     '(.type | IN("tool_result", "text") | not)'),
]:
    assert old in b, old
    b = b.replace(old, new)
open(sys.argv[3], 'w').write(b)
PY
MODULES=(HEAD fixA fixB)

verdict_len() { # <module> <file>: number of deny_record failures, or "ERR"
  jq -rR -n -L "$tmp/$1" 'import "transcript" as t; t::events | t::deny_record_failures | length' "$2" 2>/dev/null || echo ERR
}
problems_len() {
  jq -rR -n -L "$tmp/$1" 'import "transcript" as t; t::events | t::problems | length' "$2" 2>/dev/null || echo ERR
}
census_len() {
  jq -rR -n -L "$tmp/$1" 'import "transcript" as t; t::events | t::tool_uses | length' "$2" 2>/dev/null || echo ERR
}

# The good transcript of test/generate-reports.bats's property test.
good="$tmp/good.jsonl"
printf '%s\n' '{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}' \
  '{"type":"assistant","message":{"content":[{"type":"text","text":"x"},{"type":"tool_use","id":"g1","name":"Bash","input":{"command":"echo good"}}]}}' \
  '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"g1","content":"denied","is_error":true}]}}' \
  '{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"g1","tool_input":{}}]}' > "$good"

echo "== controls (expect 0 failures everywhere)"
{ head -1 "$good"; echo 'Warning: some CLI notice on stdout'; tail -n +2 "$good"; } > "$tmp/warning_line.jsonl"
for m in "${MODULES[@]}"; do
  echo "$m good=$(verdict_len "$m" "$good") warning_line=$(verdict_len "$m" "$tmp/warning_line.jsonl")"
done

echo "== the 13-shape table (expect every shape to fail in every module)"
# shellcheck source=../../../test/skills/malformed-transcripts.bash
source "$repo/test/skills/malformed-transcripts.bash"
write_malformed_transcripts "$tmp/table" 'echo good' >/dev/null
for m in "${MODULES[@]}"; do
  pass=0
  for f in "$tmp"/table/*.jsonl; do [ "$(verdict_len "$m" "$f")" = 0 ] && pass=$((pass + 1)); done
  echo "$m table_shapes=${#MALFORMED_SHAPES[@]} passed_wrongly=$pass"
done

# The module's own vocabulary, derived from its source, not typed here: every
# key it tests with has("..."). A new marker is covered without editing this.
mapfile -t vocab < <(grep -o 'has("[^"]*")' "$repo/test/skills/transcript.jq" | sed 's/^has("//; s/")$//' | sort -u)
echo "== vocabulary from has(): ${vocab[*]}"

echo "== property 1: insert an undenied Bash call at every container, with and without each vocabulary key added at the event root or at the insertion container"
# Variant kinds: key "" = the committed property (no key); otherwise the key is
# added with a string value at the root ("root") or at the container ("here").
# Census locality is checked too: the census must grow by exactly one.
jq -rR -n --args '
  [inputs] as $lines
  | {"type":"tool_use","id":"inserted1","name":"Bash","input":{"command":"pwd"}} as $call
  | range(0; $lines | length) as $i
  | ($lines[$i] | fromjson) as $ev
  | ([$ev | paths(type == "object" or type == "array")] + [[]])[] as $p
  | ($ev | getpath($p)) as $v
  | ($ev | setpath($p; if ($v | type) == "array" then $v + [$call] else $v + {"x_inserted": $call} end)) as $ins
  | ([["", "none"]] + [$ARGS.positional[] | [., "root"], [., "here"]])[] as [$k, $where]
  | (if $k == "" then $ins
     elif $where == "root" then $ins + {($k): "x"}
     elif ($ins | getpath($p) | type) == "object" then $ins | setpath($p + [$k]; "x")
     else empty end) as $new
  | "\($k)|\($where)|\($i)|\($p | tojson)\u001f" + ([$lines[0:$i][], ($new | tojson), $lines[$i + 1:][]] | join("\u001e"))' \
  "${vocab[@]}" < "$good" > "$tmp/variants.txt"
total=$(grep -c '' "$tmp/variants.txt")
base_census=$(census_len HEAD "$good")
for m in "${MODULES[@]}"; do
  esc=0 nonlocal=0 n=0
  while IFS=$'\x1f' read -r label body; do
    n=$((n + 1))
    printf '%s\n' "$body" | tr '\036' '\n' > "$tmp/v.jsonl"
    if [ "$(verdict_len "$m" "$tmp/v.jsonl")" = 0 ]; then
      esc=$((esc + 1)); echo "  $m ESCAPE: $label"
    fi
    if [ "$(census_len "$m" "$tmp/v.jsonl")" != "$((base_census + 1))" ]; then
      nonlocal=$((nonlocal + 1))
      [ "$nonlocal" -le 3 ] && echo "  $m census not +1: $label"
    fi
  done < "$tmp/variants.txt"
  echo "$m variants=$n (of $total) escapes=$esc census_not_plus_one=$nonlocal"
done

echo "== property 2: every content-block or event type outside the allowlist is a problem"
# Mutant types are derived from the allowlist literals in the module's source:
# every prefix and suffix (the empty string included), upper case, and a
# trailing space, minus the allowed names themselves.
mapfile -t allowed < <(grep -o 'inside(\[[^]]*\])' "$repo/test/skills/transcript.jq" | grep -o '"[^"]*"' | tr -d '"' | sort -u)
echo "allowlist literals: ${allowed[*]}"
mapfile -t mutants < <(printf '%s\n' "${allowed[@]}" | python3 -c '
import sys
names = [l.strip() for l in sys.stdin if l.strip()]
out = set()
for n in names:
    for i in range(len(n)):
        out.add(n[:i]); out.add(n[i + 1:] if i else n[1:])
    out.add(n.upper()); out.add(n + " ")
for m in sorted(out - set(names)):
    print(m)
')
echo "mutant types: ${#mutants[@]}"
for m in "${MODULES[@]}"; do
  accepted=0 tried=0 examples=""
  for t in "${mutants[@]}"; do
    # one variant per event line (event type) and per content block (block type)
    while IFS= read -r variant; do
      tried=$((tried + 1))
      printf '%s\n' "$variant" | tr '\036' '\n' > "$tmp/t.jsonl"
      if [ "$(problems_len "$m" "$tmp/t.jsonl")" = 0 ]; then
        accepted=$((accepted + 1))
        [ "${#examples}" -lt 120 ] && examples="$examples \"$t\""
      fi
    done < <(jq -rR -n --arg t "$t" '
      [inputs] as $lines | range(0; $lines | length) as $i | ($lines[$i] | fromjson) as $ev
      | ([["type"]] + [$ev | paths(objects | has("type")) | select(length > 0) | . + ["type"]
           | select(.[0] == "message")])[] as $p
      | [$lines[0:$i][], ($ev | setpath($p; $t) | tojson), $lines[$i + 1:][]] | join("\u001e")' "$good")
  done
  echo "$m type_mutants_tried=$tried accepted_without_problem=$accepted examples:$examples"
done

echo "== Claim 24's shape from the fact-check, under each module"
printf '%s\n' "$(head -1 "$good")" "$(sed -n 2p "$good")" \
  '{"__text":"x","a":{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}},"r":{"type":"tool_result","tool_use_id":"x1","content":"/"}}' \
  "$(tail -1 "$good")" > "$tmp/claim24.jsonl"
for m in "${MODULES[@]}"; do
  echo "$m claim24_failures=$(verdict_len "$m" "$tmp/claim24.jsonl")"
  jq -rR -n -L "$tmp/$m" 'import "transcript" as t; t::events | t::deny_record_failures | .[]' "$tmp/claim24.jsonl" | sed 's/^/    /'
done
echo "done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
