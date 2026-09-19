#!/usr/bin/env bats
# @category fast
# Parse and analysis coverage for scripts/cross-model-review.py: the FINDINGS
# accept spec it copies from scripts/lite-review.py, header tolerance, and the
# overlap analysis's exclusion of runs that produced no parseable block.
# Keyless throughout: --analyze-only with OPENROUTER_API_KEY unset makes no
# network calls (stage-1-only overlap).

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  SCRIPT="$REPO_ROOT/scripts/cross-model-review.py"
  export SCRIPT
}

# Run a python snippet with the harness imported as module `m`.
py_with_module() {
  python3 -c "
import importlib.util
spec = importlib.util.spec_from_file_location('cmr', '$SCRIPT')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
$1"
}

@test "FINDING_RE is byte-identical to the owner's in lite-review.py" {
  own=$(sed -n '/^FINDING_RE = re.compile(/,/^)/p' "$REPO_ROOT/scripts/lite-review.py")
  copy=$(sed -n '/^FINDING_RE = re.compile(/,/^)/p' "$SCRIPT")
  [ -n "$own" ]
  [ "$own" = "$copy" ]
}

@test "numbered line followed by a long whitespace run parses fast (no backtracking)" {
  run timeout 5 bash -c "$(declare -f py_with_module); SCRIPT='$SCRIPT'; py_with_module '
rows, ok = m.parse_findings(\"FINDINGS:\n1.\" + \" \" * 5000)
assert rows == [], rows
rows, ok = m.parse_findings(\"FINDINGS:\n1.\" + \" \" * 5000 + \"|\")
assert rows == [], rows
print(\"OK\")
'"
  [ "$status" -eq 0 ]
  [[ "$output" == *OK* ]]
}

@test "bold-wrapped **FINDINGS:** header opens the block" {
  run py_with_module '
rows, ok = m.parse_findings("**FINDINGS:**\n1. a.py:3 | High | security | t | d")
assert ok, ok
assert len(rows) == 1 and rows[0]["path"] == "a.py" and rows[0]["line_start"] == 3, rows
rows, ok = m.parse_findings("**FINDINGS:** NONE")
assert ok and rows == [], (rows, ok)
print("OK")
'
  [ "$status" -eq 0 ]
  [[ "$output" == *OK* ]]
}

@test "analysis excludes parse_ok=false runs instead of scoring them as J=1.0 agreement" {
  out="$BATS_TEST_TMPDIR/out"
  mkdir -p "$out"
  {
    echo '{"model":"m","replicate":1,"parse_ok":false,"findings":[],"prompt_sha":"x"}'
    echo '{"model":"m","replicate":2,"parse_ok":false,"findings":[],"prompt_sha":"x"}'
  } > "$out/findings.jsonl"
  run env -u OPENROUTER_API_KEY python3 "$SCRIPT" --out "$out" --analyze-only
  [ "$status" -eq 0 ]
  [[ "$output" == *"2 unparseable runs"* ]]
  run python3 -c "
import json
r = json.load(open('$out/overlap.json'))
assert r['self'] == {}, r
assert r['excluded']['unparseable'] == 2, r
print('OK')
"
  [ "$status" -eq 0 ]
  [[ "$output" == *OK* ]]
}
