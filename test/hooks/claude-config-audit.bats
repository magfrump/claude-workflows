#!/usr/bin/env bats
# @category fast
# Tests for the PostToolUse config-audit hook (hooks/claude-config-audit.sh)
#
# Central use cases:
#   1. HIGH-severity findings in an edited policy file → exit 2, findings on stderr
#   2. Clean policy file → silent exit 0 (auditor runs, nothing reported)
#   3. Policy-file gate: settings*.json, CLAUDE.md, .claude/ and skills/ files
#      are audited; ordinary source files are not
#   4. Non-edit tools, malformed payloads, missing auditor, and auditor crashes
#      all degrade to silent exit 0 — the hook never breaks ordinary editing
#   5. Integration against the real auditor (skipped if not installed locally)
#
# Most tests use a stub auditor so they don't depend on the private script at
# ~/private_reviews/claude_config_audit.py; the integration tests at the bottom
# skip when it is absent.

HOOK="$BATS_TEST_DIRNAME/../../hooks/claude-config-audit.sh"
REAL_AUDIT="$HOME/private_reviews/claude_config_audit.py"

setup() {
  TEST_DIR=$(mktemp -d)
  STUB_LOG="$TEST_DIR/stub-invocations.log"
  STUB="$TEST_DIR/stub_audit.py"
  cat > "$STUB" <<'PY'
import os, sys
with open(os.environ["STUB_LOG"], "a") as f:
    f.write(" ".join(sys.argv[1:]) + "\n")
mode = os.environ.get("STUB_MODE", "clean")
if mode == "high":
    print("stub finding line")
    print("HIGH-severity — review these first (1):")
    sys.exit(1)
if mode == "crash":
    print("Traceback (most recent call last): boom")
    sys.exit(1)
sys.exit(0)
PY
  export STUB_LOG
  export CLAUDE_CONFIG_AUDIT_SCRIPT="$STUB"
  export STUB_MODE=clean
  unset CLAUDE_CONFIG_AUDIT_DISABLE
}

teardown() {
  rm -rf "$TEST_DIR"
}

# --- Helpers ---

edit_payload() {
  local tool="$1" file="$2"
  jq -n -c --arg t "$tool" --arg f "$file" \
    '{tool_name: $t, tool_input: {file_path: $f}}'
}

make_file() {
  local rel="$1"
  local path="$TEST_DIR/$rel"
  mkdir -p "$(dirname "$path")"
  printf '{}\n' > "$path"
  printf '%s' "$path"
}

stub_invoked_on() {
  [ -f "$STUB_LOG" ] && grep -qF "$1" "$STUB_LOG"
}

# --- Core behavior (stub auditor) ---

@test "HIGH finding in settings.json → exit 2 with findings on stderr" {
  export STUB_MODE=high
  f=$(make_file "settings.json")
  run bash "$HOOK" < <(edit_payload Edit "$f")
  [ "$status" -eq 2 ]
  [[ "$output" == *"SECURITY AUDIT: HIGH-severity finding"* ]]
  [[ "$output" == *"stub finding line"* ]]
}

@test "clean policy file → silent exit 0, auditor was invoked" {
  f=$(make_file "settings.local.json")
  run bash "$HOOK" < <(edit_payload Write "$f")
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  stub_invoked_on "$f"
}

@test "auditor crash without HIGH banner → silent exit 0 (no false alarm)" {
  export STUB_MODE=crash
  f=$(make_file "settings.json")
  run bash "$HOOK" < <(edit_payload Edit "$f")
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# --- Policy-file gate ---

@test "gate accepts CLAUDE.md, .claude/ files, skills markdown, .mdc rules" {
  for rel in "CLAUDE.md" "proj/.claude/notes.md" "proj/skills/foo/SKILL.md" \
             "proj/rules/base.mdc" "AGENTS.md"; do
    f=$(make_file "$rel")
    run bash "$HOOK" < <(edit_payload Edit "$f")
    [ "$status" -eq 0 ]
    stub_invoked_on "$f" || {
      echo "auditor not invoked for policy file: $rel"
      return 1
    }
  done
}

@test "gate skips ordinary source files, even inside skills dirs" {
  for rel in "src/main.py" "proj/app.ts" "proj/skills/foo/helper.py"; do
    f=$(make_file "$rel")
    run bash "$HOOK" < <(edit_payload Edit "$f")
    [ "$status" -eq 0 ]
    [ -z "$output" ]
  done
  [ ! -s "$STUB_LOG" ]
}

# --- Robustness: the hook must never break ordinary editing ---

@test "non-edit tool (Bash) → silent exit 0, auditor not invoked" {
  f=$(make_file "settings.json")
  run bash "$HOOK" < <(jq -n -c --arg f "$f" \
    '{tool_name: "Bash", tool_input: {command: ("cat " + $f)}}')
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  [ ! -s "$STUB_LOG" ]
}

@test "malformed payload → silent exit 0" {
  run bash "$HOOK" <<< "not json"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "missing file_path / nonexistent file → silent exit 0" {
  run bash "$HOOK" <<< '{"tool_name":"Edit","tool_input":{}}'
  [ "$status" -eq 0 ]
  run bash "$HOOK" < <(edit_payload Edit "$TEST_DIR/does-not-exist-settings.json")
  [ "$status" -eq 0 ]
}

@test "missing auditor script → silent exit 0" {
  export CLAUDE_CONFIG_AUDIT_SCRIPT="$TEST_DIR/nope.py"
  f=$(make_file "settings.json")
  run bash "$HOOK" < <(edit_payload Edit "$f")
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "CLAUDE_CONFIG_AUDIT_DISABLE=1 → silent exit 0, auditor not invoked" {
  export CLAUDE_CONFIG_AUDIT_DISABLE=1
  export STUB_MODE=high
  f=$(make_file "settings.json")
  run bash "$HOOK" < <(edit_payload Edit "$f")
  [ "$status" -eq 0 ]
  [ ! -s "$STUB_LOG" ]
}

# --- Integration with the real auditor (skipped when not installed) ---

@test "real auditor: bypassPermissions directive in settings.json → exit 2" {
  [ -f "$REAL_AUDIT" ] || skip "real auditor not installed at $REAL_AUDIT"
  export CLAUDE_CONFIG_AUDIT_SCRIPT="$REAL_AUDIT"
  f="$TEST_DIR/settings.json"
  # Payload split across args so this test file never flags in audit sweeps;
  # the fixture written to disk is the real directive.
  printf '%s%s\n' '{"permissionMode": "bypass' 'Permissions"}' > "$f"
  run bash "$HOOK" < <(edit_payload Edit "$f")
  [ "$status" -eq 2 ]
  [[ "$output" == *"ESCAPE"* ]]
}

@test "real auditor: hidden bidi override in CLAUDE.md → exit 2" {
  [ -f "$REAL_AUDIT" ] || skip "real auditor not installed at $REAL_AUDIT"
  export CLAUDE_CONFIG_AUDIT_SCRIPT="$REAL_AUDIT"
  f="$TEST_DIR/CLAUDE.md"
  printf '# Notes\nrun tests \xe2\x80\xaeplain text\n' > "$f"   # U+202E RLO
  run bash "$HOOK" < <(edit_payload Edit "$f")
  [ "$status" -eq 2 ]
  [[ "$output" == *"bidi"* ]]
}

@test "real auditor: benign settings.json → silent exit 0" {
  [ -f "$REAL_AUDIT" ] || skip "real auditor not installed at $REAL_AUDIT"
  export CLAUDE_CONFIG_AUDIT_SCRIPT="$REAL_AUDIT"
  f="$TEST_DIR/settings.json"
  printf '{"model": "opus", "theme": "dark"}\n' > "$f"
  run bash "$HOOK" < <(edit_payload Write "$f")
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
