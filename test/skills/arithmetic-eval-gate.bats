#!/usr/bin/env bats
# @category fast
# Deterministic tests of arithmetic-eval's two pieces of executable code, which
# live only as heredocs inside skills/arithmetic-eval/SKILL.md:
#   - the Mode 1 evaluator (the `python3 -c '...'` AST walker), and
#   - the Mode 2 static gate (check.py, between <<'AE_CHECK_EOF' and AE_CHECK_EOF).
# Both are extracted from SKILL.md at test time, so these tests exercise exactly
# what a model would paste. No LLM runs here: whether the model *uses* the
# evaluator is a separate question (plan-skill-fixtures-batch4 step 5, Q-059).
#
# The OS confinement tiers (bwrap / unshare / confine.py) are out of scope; the
# gate is defense-in-depth in front of them (SKILL.md "Security model").

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
  SKILL="$REPO_ROOT/skills/arithmetic-eval/SKILL.md"
  TEST_TMPDIR=$(mktemp -d)
  MODE1="$TEST_TMPDIR/mode1.py"
  CHECK="$TEST_TMPDIR/check.py"
  # Mode 1: the body of `timeout 5 python3 -c '` up to the `' ) <<'EXPREOF'` line.
  awk "/timeout 5 python3 -c '\$/ { f=1; next } /^' \\) <<'EXPREOF'\$/ { f=0 } f" \
    "$SKILL" > "$MODE1"
  # check.py: exact delimiter lines, per FP-080 (no loose matching).
  awk "/^cat > \"\\\$AE\\/check.py\" <<'AE_CHECK_EOF'\$/ { f=1; next } /^AE_CHECK_EOF\$/ { f=0 } f" \
    "$SKILL" > "$CHECK"
}

teardown() {
  rm -rf "$TEST_TMPDIR"
}

# mode1 <expression> — run the extracted evaluator on stdin.
mode1() {
  printf '%s\n' "$1" | python3 "$MODE1"
}

# gate <python source> — write a script and run the extracted check.py on it.
gate() {
  printf '%s\n' "$1" > "$TEST_TMPDIR/script.py"
  python3 "$CHECK" "$TEST_TMPDIR/script.py"
}

# --- Extraction (a silent empty extraction would pass every reject test) ---

@test "Mode 1 evaluator extracts from SKILL.md and is real code" {
  [ "$(wc -l < "$MODE1")" -ge 20 ] || { echo "Mode 1 extraction: $(wc -l < "$MODE1") lines — did the python3 -c / EXPREOF lines change?"; return 1; }
  grep -q 'def ev(' "$MODE1"
}

@test "check.py extracts from SKILL.md and is real code" {
  [ "$(wc -l < "$CHECK")" -ge 40 ] || { echo "check.py extraction: $(wc -l < "$CHECK") lines — did the AE_CHECK_EOF delimiter lines change?"; return 1; }
  grep -q 'ALLOWED_MODULES' "$CHECK"
}

@test "the three Mode 2 heredoc delimiters are distinct and no body line equals one" {
  # FP-080: a body line equal to a delimiter closes the heredoc early and runs
  # the rest as shell. The shipped bodies must never contain one.
  local d
  for d in AE_SCRIPT_EOF AE_CHECK_EOF AE_CONFINE_EOF; do
    [ "$(grep -c "<<'$d'\$" "$SKILL")" -eq 1 ] || { echo "$d opens $(grep -c "<<'$d'\$" "$SKILL") heredocs"; return 1; }
    [ "$(grep -cx "$d" "$SKILL")" -eq 1 ] || { echo "$d appears $(grep -cx "$d" "$SKILL") times as a bare line"; return 1; }
  done
}

# --- Mode 1: computes ---

@test "Mode 1 computes SKILL.md's worked example" {
  run mode1 '3600 / 0.003 * 1000'
  [ "$status" -eq 0 ]
  [ "$output" = "[arithmetic-eval] 3600 / 0.003 * 1000 -> 1200000000.0" ]
}

@test "Mode 1 strips thousands separators and treats ^ as power" {
  run mode1 '1,200,000 * 2^3'
  [ "$status" -eq 0 ]
  [[ "$output" == *"-> 9600000" ]]
}

@test "Mode 1 handles unary minus, floor division and modulo" {
  run mode1 '-(7 // 2) + 7 % 3'
  [ "$status" -eq 0 ]
  [[ "$output" == *"-> -2" ]]
}

# --- Mode 1: rejects, tagged, never a traceback ---

@test "Mode 1 rejects names, calls and attribute access" {
  local e
  for e in 'x + 1' '__import__("os")' 'abs(-1)' '(1).real'; do
    run mode1 "$e"
    [ "$status" -ne 0 ] || { echo "accepted: $e"; return 1; }
    [[ "$output" == "[arithmetic-eval] REJECTED — "* ]] || { echo "untagged for $e: $output"; return 1; }
    [[ "$output" != *"Traceback"* ]]
  done
}

@test "Mode 1 rejects an oversized power before computing it" {
  run mode1 '2 ** 1000000'
  [ "$status" -ne 0 ]
  [[ "$output" == *"REJECTED — result too large"* ]]
}

@test "Mode 1 rejects complex and non-finite results, and division by zero" {
  local e
  for e in '(-8) ** 0.5' '1e308 * 10' '1 / 0'; do
    run mode1 "$e"
    [ "$status" -ne 0 ] || { echo "accepted: $e -> $output"; return 1; }
    [[ "$output" == "[arithmetic-eval] REJECTED — "* ]] || { echo "untagged for $e: $output"; return 1; }
  done
}

@test "Mode 1 rejects string and boolean literals" {
  run mode1 '"a" * 3'
  [ "$status" -ne 0 ]
  run mode1 'True + 1'
  [ "$status" -ne 0 ]
  [[ "$output" == *"non-numeric literal"* ]]
}

# --- check.py: accepts ordinary scientific scripts ---

@test "gate accepts approved imports and ordinary computation" {
  run gate $'import statistics, math\nfrom scipy import stats\nimport numpy as np\nimport pandas as pd\nprint(statistics.mean([1, 2, 3]), math.sqrt(2))'
  [ "$status" -eq 0 ]
}

@test "gate allows the harmless dunders and pandas method names SKILL.md promises" {
  run gate $'import numpy as np\nprint(np.__version__)\nif __name__ == "__main__":\n    pass'
  [ "$status" -eq 0 ]
  run gate $'import json\nd = json.load(open("data.json"))\nprint(d)'
  [ "$status" -eq 0 ]
}

# --- check.py: rejects the listed code-execution surfaces ---

@test "gate rejects non-approved imports, including sys and importlib" {
  local s
  for s in 'import os' 'import sys' 'import subprocess' 'from importlib import import_module' 'import socket' 'from . import x'; do
    run gate "$s"
    [ "$status" -ne 0 ] || { echo "accepted: $s"; return 1; }
    [[ "$output" == *"REJECTED"* ]]
  done
}

@test "gate rejects banned builtins" {
  local s
  for s in 'eval("1")' 'exec("x=1")' 'getattr(1, "real")' '__import__("os")' 'globals()' 'compile("1","f","eval")'; do
    run gate "$s"
    [ "$status" -ne 0 ] || { echo "accepted: $s"; return 1; }
  done
}

@test "gate rejects reflection dunders as attributes and as string literals" {
  local s
  for s in 'x = (1).__class__' 'f = lambda: 0\nf.__globals__' 'k = "__subclasses__"'; do
    run gate "$(printf "$s")"
    [ "$status" -ne 0 ] || { echo "accepted: $s"; return 1; }
  done
}

@test "gate rejects sympy eval paths, operator reflection and pickle sinks" {
  local s
  for s in 'import sympy\nsympy.sympify("1")' 'import operator\noperator.attrgetter("x")' \
           'import pandas as pd\npd.read_pickle("f")' 'import numpy as np\nnp.load("f", allow_pickle=True)' \
           'import numpy as np\nnp.load("f", None, True)'; do
    run gate "$(printf "$s")"
    [ "$status" -ne 0 ] || { echo "accepted: $s"; return 1; }
  done
}

@test "gate fails closed on allow_pickle that is not a literal False" {
  run gate $'import numpy as np\nflag = False\nnp.load("f", allow_pickle=flag)'
  [ "$status" -ne 0 ]
  run gate $'import numpy as np\nnp.load("f", allow_pickle=False)'
  [ "$status" -eq 0 ]
}

@test "gate rejects a syntax error with a tagged message" {
  run gate 'def ('
  [ "$status" -ne 0 ]
  [[ "$output" == *"[arithmetic-eval] REJECTED — syntax error"* ]]
}
