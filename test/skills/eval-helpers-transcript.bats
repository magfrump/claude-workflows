#!/usr/bin/env bats
# @category fast
# Unit tests for eval-helpers.bash's transcript checks (tool_called:,
# subagents_min:), against a synthetic stream-json transcript shaped like a real
# `claude -p --output-format stream-json --verbose` run: top-level events carry
# "parent_tool_use_id": null, and a sub-agent's own events carry its parent's id
# (checked against real runs, 2026-09-24).

load eval-helpers

bats_require_minimum_version 1.5.0

setup() {
  TEST_TMPDIR=$(mktemp -d)
  REPORT_PATH="$TEST_TMPDIR/tc-1.md.report.md"
  echo "# Report" > "$REPORT_PATH"
  T="$TEST_TMPDIR/tc-1.md.transcript.jsonl"
  cat > "$T" <<'EOF'
{"type":"system","subtype":"init"}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"text","text":"reading"},{"type":"tool_use","id":"t1","name":"Read","input":{"file_path":"/tmp/x/workflows/divergent-design.md"}}]}}
{"type":"assistant","parent_tool_use_id":null,"message":{"content":[{"type":"tool_use","id":"t2","name":"Agent","input":{"description":"criterion: cost","prompt":"score cost"}},{"type":"tool_use","id":"t3","name":"Agent","input":{"description":"criterion: risk","prompt":"score risk"}}]}}
{"type":"assistant","parent_tool_use_id":"t2","message":{"content":[{"type":"tool_use","id":"t4","name":"Agent","input":{"description":"nested","prompt":"x"}},{"type":"tool_use","id":"t5","name":"Bash","input":{"command":"python3 -c 'print(1)'"}}]}}
{"type":"result","subtype":"success","result":"# Report"}
EOF
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

@test "tool_called passes on a matching input" {
  run assert_tool_called Read 'workflows/divergent-design\.md'
  [ "$status" -eq 0 ]
}

@test "tool_called fails on a non-matching input and shows what was called" {
  run assert_tool_called Read 'skills/other\.md'
  [ "$status" -ne 0 ]
  [[ "$output" == *"No Read call with input matching"* ]]
  [[ "$output" == *"divergent-design.md"* ]]
}

@test "tool_called fails for a tool never called" {
  run assert_tool_called Grep '.'
  [ "$status" -ne 0 ]
  [[ "$output" == *"Grep calls seen: 0"* ]]
}

@test "tool_called sees sub-agents' calls too" {
  run assert_tool_called Bash 'python3'
  [ "$status" -eq 0 ]
}

@test "subagents_min counts top-level dispatches only" {
  run assert_subagents_min 2
  [ "$status" -eq 0 ]
  run assert_subagents_min 3
  [ "$status" -ne 0 ]
  [[ "$output" == *"found 2"* ]]
}

@test "a missing transcript fails (not skips) and says how to fix it" {
  rm "$T"
  run assert_subagents_min 1
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXTURE_TRANSCRIPT=1"* ]]
  run assert_tool_called Read '.'
  [ "$status" -ne 0 ]
  [[ "$output" == *"FIXTURE_TRANSCRIPT=1"* ]]
}

@test "a non-JSON line in the transcript does not blind the checks" {
  # e.g. a CLI warning printed to stdout mid-stream
  sed -i '2i Warning: something printed to stdout' "$T"
  run assert_tool_called Read 'divergent-design'
  [ "$status" -eq 0 ]
  run assert_subagents_min 2
  [ "$status" -eq 0 ]
}
