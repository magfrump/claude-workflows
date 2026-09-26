#!/usr/bin/env bash
# Claim 25 probe: run the real test/skills/generate-reports.bash (HEAD copy) end to end
# against a stub `claude` that prints a crafted stream-json transcript, and print
# whether the run was voided (.failed written) and why. Same layout as test/generate-reports.bats.
set -uo pipefail
REPO=/workspace
T=$(mktemp -d "${TMPDIR:-/tmp}/c25.XXXX")
trap 'rm -rf "$T"' EXIT
mkdir -p "$T/test/skills/demo/fixtures" "$T/skills/demo" "$T/bin"
cp "$REPO/test/skills/generate-reports.bash" "$REPO/test/skills/runner-contract.bash" "$T/test/skills/"
echo "# demo" > "$T/skills/demo/SKILL.md"
echo "BODY" > "$T/test/skills/demo/fixtures/tc-1-thing.txt"
cat > "$T/test/skills/demo/runner.bash" <<'R'
FIXTURE_TOOLS="Bash"
FIXTURE_MODE="inline"
FIXTURE_TRANSCRIPT=1
FIXTURE_BASH=deny-record
fixture_prompt() { printf 'Review %s' "$1"; }
R
cat > "$T/bin/claude" <<'S'
#!/usr/bin/env bash
cat >/dev/null
cat "$STREAM"
exit "${STUB_RC:-0}"
S
chmod +x "$T/bin/claude"
unset CLAUDE_MODEL CLAUDE_FLAGS
export PATH="$T/bin:$PATH"
cd "$T" || exit 1
OUT="$T/test/skills/demo/output/tc-1-thing.txt.failed"

INIT='{"type":"system","subtype":"init","claude_code_version":"9.9.9","tools":["Bash"]}'
call() { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":%s,"name":"Bash","input":{"command":"echo hi"}}]}}' "$1"; }
res()  { printf '{"type":"result","subtype":"success","result":"# Report","permission_denials":%s}' "$1"; }
D_B1='[{"tool_name":"Bash","tool_use_id":"b1","tool_input":{}}]'

probe() {  # probe <label> <lines...>
  local label="$1"; shift
  printf '%s\n' "$@" > "$T/stream.jsonl"
  STREAM="$T/stream.jsonl" bash "$T/test/skills/generate-reports.bash" demo >/dev/null 2>&1
  local grc=$?
  if [ -f "$OUT" ]; then printf '%-58s gen_rc=%s VOIDED: %s\n' "$label" "$grc" "$(cat "$OUT")"
  else printf '%-58s gen_rc=%s NOT VOIDED\n' "$label" "$grc"; fi
}

echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)  jq: $(jq --version)  bash: $BASH_VERSION  HEAD: $(git -C $REPO rev-parse --short HEAD)"
probe "A01 clean: init Bash, call b1, denial b1"               "$INIT" "$(call '"b1"')" "$(res "$D_B1")"
probe "A02 call b1 undenied (denials [])"                     "$INIT" "$(call '"b1"')" "$(res '[]')"
probe "A03 call b1 denied only under tool_name Read"          "$INIT" "$(call '"b1"')" "$(res '[{"tool_name":"Read","tool_use_id":"b1"}]')"
probe "A04 call with null id, denial b1"                      "$INIT" "$(call null)" "$(res "$D_B1")"
probe "A05 Bash denial b2 names unseen id (call b1 denied)"   "$INIT" "$(call '"b1"')" "$(res '[{"tool_name":"Bash","tool_use_id":"b1"},{"tool_name":"Bash","tool_use_id":"b2"}]')"
probe "A06 Bash denial with null tool_use_id"                 "$INIT" "$(call '"b1"')" "$(res '[{"tool_name":"Bash","tool_use_id":"b1"},{"tool_name":"Bash"}]')"
probe "A07 no init event"                                     "$(call '"b1"')" "$(res "$D_B1")"
probe "A08 init tools []"                                     '{"type":"system","subtype":"init","tools":[]}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A09 init without tools key"                            '{"type":"system","subtype":"init"}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A10 init tools [\"Bash(**)\"] (element not exactly Bash)" '{"type":"system","subtype":"init","tools":["Bash(**)"]}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A11 init tools [\"bash\"] (lowercase)"                 '{"type":"system","subtype":"init","tools":["bash"]}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A12 init tools [\"Read\",\"Bash\"]"                    '{"type":"system","subtype":"init","tools":["Read","Bash"]}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A13 two inits: first [] then [Bash]"                   '{"type":"system","subtype":"init","tools":[]}' "$INIT" "$(call '"b1"')" "$(res "$D_B1")"
probe "A14 init tools is STRING \"NotBash\" (not an array)"   '{"type":"system","subtype":"init","tools":"NotBash"}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A15 init tools is an object"                '{"type":"system","subtype":"init","tools":{"a":1}}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A16 event with string message (jq error expected)"              "$INIT" '{"type":"assistant","message":"x"}' "$(call '"b1"')" "$(res "$D_B1")"
probe "A17 empty stream"
probe "A18 claude exits 3 + call undenied"                    "$INIT" "$(call '"b1"')" "$(res '[]')"
STUB_RC=3 probe "A18b (same, stub rc 3)"                       "$INIT" "$(call '"b1"')" "$(res '[]')"
probe "A19 undenied Bash tool_use inside a type:user event"   "$INIT" '{"type":"user","message":{"content":[{"type":"tool_use","id":"u1","name":"Bash","input":{}}]}}' "$(res '[]')"
probe "A20 undenied Bash tool_use in a sub-agent event"       "$INIT" '{"type":"assistant","parent_tool_use_id":"t0","message":{"content":[{"type":"tool_use","id":"s1","name":"Bash","input":{}}]}}' "$(res '[]')"
probe "A21 call id 1 (number) vs denial id \"1\" (string)"     "$INIT" "$(call 1)" "$(res '[{"tool_name":"Bash","tool_use_id":"1"}]')"
probe "A22 init only at END of stream"                        "$(call '"b1"')" "$(res "$D_B1")" "$INIT"
probe "A23 undenied call line holds lone surrogate (F3)"      "$INIT" '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"b1","name":"Bash","input":{"command":"echo \ud800"}}]}}' "$(res '[]')"
probe "A24 undenied call off-path (.message.blocks), no denial (F2)" "$INIT" '{"type":"assistant","message":{"blocks":[{"type":"tool_use","id":"b1","name":"Bash","input":{}}]}}' "$(res '[]')"
probe "A25 permission_denials is an object of denials"        "$INIT" "$(call '"b1"')" '{"type":"result","result":"# R","permission_denials":{"x":{"tool_name":"Bash","tool_use_id":"b1"}}}'
# --- addendum for Claim 26: do the generator's checks see an undenied call carried by a mode1-equiv skip shape?
GOOD_CALL=$(call '"t1"'); GOOD_RES=$(res '[{"tool_name":"Bash","tool_use_id":"t1"}]')
probe "G1 good + array-wrapped undenied call event (C1)"       "$INIT" "$GOOD_CALL" '[{"type":"assistant","message":{"content":[{"type":"tool_use","id":"t2","name":"Bash","input":{"command":"x"}}]}}]' "$GOOD_RES"
probe "G2 good + string message holding undenied call (C2)"   "$INIT" "$GOOD_CALL" '{"type":"assistant","message":"{\"content\":[{\"type\":\"tool_use\",\"id\":\"t2\",\"name\":\"Bash\",\"input\":{\"command\":\"x\"}}]}"}' "$GOOD_RES"
probe "G3 good + string content holding undenied call (C3)"   "$INIT" "$GOOD_CALL" '{"type":"assistant","message":{"content":"[{\"type\":\"tool_use\",\"id\":\"t2\",\"name\":\"Bash\",\"input\":{\"command\":\"x\"}}]"}}' "$GOOD_RES"
