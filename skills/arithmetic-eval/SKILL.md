---
name: arithmetic-eval
description: >
  Validate and evaluate math using python3 to prevent hallucinated calculations.
  Two modes: (1) bare arithmetic with strict regex allowlist, (2) scientific computing
  with an approved-modules allowlist for scipy, numpy, pandas, etc.
  Use whenever Claude needs to perform, verify, or double-check a calculation — including
  intermediate math in fact-checks, cost estimates, t-tests, p-values, data loading,
  unit conversions, or code review.
when: Any arithmetic or scientific computation is needed
---

> On bad output, see guides/skill-recovery.md

# Arithmetic Eval

You have a tool for exact math. **Use it instead of mental math.**

## Mode 1: Bare Arithmetic

For simple numeric expressions with no imports or function calls.

1. **Sanitize** — strip to a Python-evaluable form (e.g., `^` → `**`).
2. **Validate** — confirm the expression matches: `^[0-9+\-*/^%(),.\s]+$`
3. **Evaluate**:

```bash
EXPR='<expression>'
if echo "$EXPR" | grep -qP '^[\d\s\+\-\*\/\%\^\(\)\,\.]+$'; then
  PY_EXPR=$(echo "$EXPR" | sed 's/\^/**/g')
  echo "[arithmetic-eval] $EXPR → $(python3 -c "print($PY_EXPR)")"
else
  echo "[arithmetic-eval] REJECTED — disallowed characters: $EXPR"
fi
```

## Mode 2: Scientific Computing

For imports, function calls, multi-line scripts (t-tests, CSV loading, plotting, etc.).

1. **Check imports** — only modules from the approved list below.
2. **Check for blocked constructs** — reject if any are present.
3. **Write to temp file and execute**:

```bash
cat > /tmp/arithmetic_eval.py << 'PYEOF'
<script here>
PYEOF
python3 /tmp/arithmetic_eval.py
```

### Approved modules

`math`, `statistics`, `scipy`, `numpy`, `pandas`, `sympy`, `csv`, `json`,
`fractions`, `decimal`, `datetime`, `pathlib`, `re`, `itertools`, `functools`,
`collections`, `operator`, `openpyxl`, `matplotlib`

### Blocked constructs

Reject any script containing: `exec(`, `eval(`, `compile(`, `subprocess`,
`os.system`, `os.popen`, `shutil.rmtree`, `__import__`, `importlib`,
`socket`, `http`, `urllib`, `requests`, `open(` with write/append mode
(`'w'`, `'a'`, `'x'`).

Read-mode `open()` is permitted for loading data files.

## Rules

- **Always tag output**: print `[arithmetic-eval]` so invocations are traceable.
- **Never skip validation**: even for `2+2`, run through the appropriate mode.
- **Chain for multi-step**: break complex calculations into named intermediate steps.
- **On rejection**: do NOT fall back to mental math. Fix the expression or report the error.
- **Mode choice**: if the expression has only numbers and operators, use Mode 1. If it needs imports or function calls, use Mode 2.
