#!/usr/bin/env bash
# architecture-review 299727c: do the transcript suites still pass with the
# proposed minimal fix (fixB in arch-299727c-marker-property.sh: ignored lines
# dropped by `events`, no has("__text"), IN(...) for the type allowlists)?
# Runs in a `git archive HEAD` copy; the working tree is not touched.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
echo "started $(date -u +%Y-%m-%dT%H:%M:%SZ) jq=$(jq --version) head=$(git -C "$repo" rev-parse --short HEAD)"
git -C "$repo" archive HEAD test skills scripts | tar -x -C "$tmp"
python3 - "$tmp/test/skills/transcript.jq" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
for old, new in [
    ('{"__unparsed": $line} else {"__text": $line} end', '{"__unparsed": $line} else empty end'),
    ('select(has("__text") | not) | ', ''),
    ('  elif has("__text") then empty\n', ''),
    ('([.type] | inside(["system", "assistant", "user", "result", "rate_limit_event"]) | not)',
     '(.type | IN("system", "assistant", "user", "result", "rate_limit_event") | not)'),
    ('([.type] | inside(["text", "thinking", "redacted_thinking", "tool_use"]) | not)',
     '(.type | IN("text", "thinking", "redacted_thinking", "tool_use") | not)'),
    ('([.type] | inside(["tool_result", "text"]) | not)', '(.type | IN("tool_result", "text") | not)'),
]:
    assert old in s, old
    s = s.replace(old, new)
open(p, 'w').write(s)
PY
cd "$tmp" || exit 1
for f in test/generate-reports.bats test/skills/mode1-equiv.bats test/skills/eval-helpers-transcript.bats \
         test/skills/eval-helpers-empty-report.bats; do
  out="$(bats --tap "$f" 2>&1)"; rc=$?
  echo "$f exit=$rc plan=$(printf '%s\n' "$out" | grep -m1 '^1\.\.') ok=$(printf '%s\n' "$out" | grep -c '^ok ') not_ok=$(printf '%s\n' "$out" | grep -c '^not ok ')"
  printf '%s\n' "$out" | grep '^not ok ' || true
done
echo "done $(date -u +%Y-%m-%dT%H:%M:%SZ)"
