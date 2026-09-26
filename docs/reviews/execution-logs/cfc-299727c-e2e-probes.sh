#!/usr/bin/env bash
# code-fact-check 299727c: end-to-end check of the census escape found by
# cfc-299727c-census-probes.sh (an event object with a top-level "__text" key
# is dropped from the census). Runs the real generate-reports.bash against a
# stubbed claude (the layout test/generate-reports.bats builds) and the real
# eval-helpers.bash checks (assert_no_tool_called, assert_mode1_equiv), for a
# control transcript and the probe transcript. Run from /workspace.
set -u
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# SKILL.md's Mode 1 block with the expression 1 + 1 (as mode1-equiv.bats builds it).
skill_md="$repo/skills/arithmetic-eval/SKILL.md"
awk '/^## Mode 1/ { m=1 } m && /^```bash$/ { f=1; next } f && /^```$/ { exit } f' "$skill_md" \
  | grep -v '^# →' > "$tmp/block.sh"
mode1_cmd="$(awk -v e='1 + 1' "/<<'EXPREOF'\$/ { print; print e; skip=1; next } skip && /^EXPREOF\$/ { skip=0 } !skip" "$tmp/block.sh")"

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
GOOD="$(jq -nc --arg c "$mode1_cmd" '{type:"assistant",parent_tool_use_id:null,message:{content:[{type:"tool_use",id:"b1",name:"Bash",input:{command:$c}}]}}')"
RES='{"type":"result","subtype":"success","result":"# Report","permission_denials":[{"tool_name":"Bash","tool_use_id":"b1","tool_input":{}}]}'
BAD='{"__text":"x","payload":{"type":"tool_use","id":"x1","name":"Bash","input":{"command":"pwd"}},"r":{"type":"tool_result","tool_use_id":"x1","content":"/home"}}'
SUB='{"type":"assistant","message":{"content":[{"type":"tool","id":"x2","name":"Bash","input":{"command":"pwd"}}]}}'

printf '%s\n' "$INIT" "$GOOD" "$RES" > "$tmp/control.jsonl"
printf '%s\n' "$INIT" "$GOOD" "$BAD" "$RES" > "$tmp/text_key_event.jsonl"
printf '%s\n' "$INIT" "$GOOD" "$SUB" "$RES" > "$tmp/substring_block_type.jsonl"

# --- The generator, as test/generate-reports.bats sets it up ---
gen_root="$tmp/gen"
mkdir -p "$gen_root/test/skills/demo/fixtures" "$gen_root/skills/demo" "$gen_root/bin"
cp "$repo/test/skills/generate-reports.bash" "$repo/test/skills/runner-contract.bash" \
  "$repo/test/skills/transcript.jq" "$gen_root/test/skills/"
echo "# demo skill" > "$gen_root/skills/demo/SKILL.md"
echo "FIXTURE BODY" > "$gen_root/test/skills/demo/fixtures/tc-1-thing.txt"
echo "SECRET VERDICTS" > "$gen_root/test/skills/demo/expected-verdicts.bash"
cat > "$gen_root/test/skills/demo/runner.bash" <<'EOF'
FIXTURE_TOOLS="Bash"
FIXTURE_MODE="inline"
fixture_prompt() { printf 'Review %s please' "$1"; }
FIXTURE_TRANSCRIPT=1
FIXTURE_BASH=deny-record
EOF
out="$gen_root/test/skills/demo/output"

for name in control text_key_event substring_block_type; do
  printf '#!/usr/bin/env bash\ncat >/dev/null\ncat %q\n' "$tmp/$name.jsonl" > "$gen_root/bin/claude"
  chmod +x "$gen_root/bin/claude"
  echo "=== generator: $name"
  (cd "$gen_root" && unset CLAUDE_MODEL CLAUDE_FLAGS && PATH="$gen_root/bin:$PATH" bash "$gen_root/test/skills/generate-reports.bash" demo 2>&1 | tail -2)
  if [ -e "$out/tc-1-thing.txt.failed" ]; then
    echo "  .failed: $(cat "$out/tc-1-thing.txt.failed")"
  else
    echo "  no .failed marker: the run PASSED the generator's checks"
  fi
done

# --- The eval checks, as test/skills/mode1-equiv.bats sets them up ---
export BATS_TEST_DIRNAME="$repo/test/skills"
export BATS_TEST_TMPDIR="$tmp"
# shellcheck source=../../../test/skills/eval-helpers.bash
source "$repo/test/skills/eval-helpers.bash"
REPORT_PATH="$tmp/tc-1.md.report.md"
echo "# Report" > "$REPORT_PATH"
for name in control text_key_event substring_block_type; do
  cp "$tmp/$name.jsonl" "$tmp/tc-1.md.transcript.jsonl"
  echo "=== eval checks: $name"
  out_nt="$(assert_no_tool_called Bash pwd 2>&1)"; rc_nt=$?
  echo "  assert_no_tool_called Bash pwd -> exit $rc_nt ${out_nt:+($(printf '%s' "$out_nt" | head -1))}"
  out_m1="$(assert_mode1_equiv arithmetic-eval 2 2>&1)"; rc_m1=$?
  echo "  assert_mode1_equiv arithmetic-eval 2 -> exit $rc_m1 ($(printf '%s' "$out_m1" | tail -1))"
done
