---
name: arithmetic-eval
description: >
  Validate and evaluate arithmetic expressions using python3 to prevent hallucinated calculations.
  Allowlists input via regex (digits, operators +-*/^%()=, decimal points, whitespace only).
  Use whenever Claude needs to perform, verify, or double-check a calculation — including
  intermediate math in fact-checks, cost estimates, unit conversions, or code review.
  Extensible to sympy for symbolic algebra.
when: Claude needs to perform or verify any arithmetic calculation
---

# Arithmetic Eval

You have a tool for exact arithmetic. **Use it instead of mental math.**

Whenever you need to calculate, compare, or verify a numeric result, run the expression
through the validation-and-eval pipeline below. Log every invocation so the hypothesis
(trigger frequency across projects) can be evaluated later.

## Pipeline

1. **Sanitize** — strip the expression to a Python-evaluable form (e.g., `^` → `**`).
2. **Validate** — confirm the expression matches the allowlist. Reject anything else.
3. **Evaluate** — run via `python3 -c` and use the printed result.

```bash
EXPR="<expression here>"  # e.g. "(12.5 * 3) + 7 / 2"

# Allowlist: digits, operators, parens, decimal points, whitespace, Python's ** operator
if echo "$EXPR" | grep -qP '^[\d\s\+\-\*\/\%\^\(\)\.\=]+$'; then
  # Replace ^ with ** for Python exponentiation
  PY_EXPR=$(echo "$EXPR" | sed 's/\^/**/g')
  echo "[arithmetic-eval] $EXPR → $(python3 -c "print($PY_EXPR)")"
else
  echo "[arithmetic-eval] REJECTED — expression contains disallowed characters: $EXPR"
fi
```

## Rules

- **Always show your work**: print the `[arithmetic-eval]` tagged line so invocations are traceable.
- **Never skip validation**: even for simple expressions like `2+2`, run the pipeline.
- **Chain for multi-step**: break complex calculations into named intermediate steps.
- **On rejection**: do NOT fall back to mental math. Fix the expression or report the error.
- **For symbolic algebra**: replace `python3 -c "print(…)"` with `python3 -c "from sympy import *; print(…)"` when the task requires variables or symbolic simplification.
