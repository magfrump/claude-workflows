---
name: arithmetic-eval
description: >
  Validate and evaluate math using python3 to prevent hallucinated calculations.
  Two modes: (1) bare arithmetic (numbers + operators only) with a strict regex
  allowlist, (2) scientific computing (imports, scripts, dataframes) with an
  approved-modules allowlist for scipy, numpy, pandas, sympy, statistics, etc.
  Use whenever performing, verifying, or double-checking ANY calculation, including:
  intermediate math inside a fact-check ("does 2.3M / 41 ≈ 56k?"), cost estimates
  ("$0.003 × 1.2M tokens"), unit conversions, percentage changes, t-tests, p-values,
  confidence intervals, CSV/JSON aggregations, regression coefficients, and sanity
  checks in code review. Default to using this skill — mental math is the exception,
  not the rule. Trigger phrases: "compute", "calculate", "what's X% of Y", "how many",
  "verify this number", "check the math", "is this right", or any expression with
  operators (+, -, *, /, %, **) on non-trivial operands.
when: Any arithmetic or scientific computation is needed (default on, not opt-in)
---

> On bad output, see guides/skill-recovery.md

# Arithmetic Eval

Exact-math tool available. **Use it instead of mental math.** Writing a number that is a calculation result — even "simple" like `12 * 365` or `15% of 240` — run it through this skill first. Mental arithmetic is the most common source of hallucinated facts in otherwise-careful work.

## Mode 1: Bare Arithmetic

Simple numeric expressions, no imports or function calls.

1. **Sanitize** — strip to Python-evaluable form (e.g., `^` → `**`).
2. **Validate** — confirm expression matches: `^[0-9+\-*/^%(),.\s]+$`
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

Imports, function calls, multi-line scripts (t-tests, CSV loading, plotting, etc.).

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
- **Mode choice**: only numbers and operators → Mode 1. Needs imports or function calls → Mode 2.

## Examples

### Example 1 — Mode 1: cost estimate inside a fact-check

User claim: "We spent ~$3,600 last month on inference at $0.003/1K tokens."

```bash
EXPR='3600 / 0.003 * 1000'
if echo "$EXPR" | grep -qP '^[\d\s\+\-\*\/\%\^\(\)\,\.]+$'; then
  PY_EXPR=$(echo "$EXPR" | sed 's/\^/**/g')
  echo "[arithmetic-eval] $EXPR → $(python3 -c "print($PY_EXPR)")"
fi
# → [arithmetic-eval] 3600 / 0.003 * 1000 → 1200000000.0
# Interpretation: ~1.2B tokens. Sanity-check this against logged usage.
```

### Example 2 — Mode 2: t-test for a benchmark claim

User claim: "Variant B is significantly faster than variant A (p < 0.05)."

```bash
cat > /tmp/arithmetic_eval.py << 'PYEOF'
from scipy import stats
a = [102, 98, 105, 101, 99, 103, 100, 104]
b = [92,  95,  91,  94,  93,  90,  96,  92]
t, p = stats.ttest_ind(a, b)
print(f"[arithmetic-eval] t={t:.3f}, p={p:.5f}")
PYEOF
python3 /tmp/arithmetic_eval.py
# → [arithmetic-eval] t=8.062, p=0.00001
# Interpretation: claim supported at p < 0.05.
```

### Example 3 — When NOT to mental-math

Bad: writing "1.2M users × $4 ARPU = $4.8M/mo" without running the math.
Good: run `1.2e6 * 4` through Mode 1, then write the verified number.

Running this skill costs ~one bash invocation. A wrong number in a fact-check or cost estimate costs much more. When in doubt, run it.
