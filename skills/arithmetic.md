---
name: arithmetic
description: >
  Evaluate arithmetic expressions using python3 instead of mental math.
  Validates input against a strict allowlist (numbers, operators, parens,
  decimals, spaces) then shells out to python3 -c. Use this skill whenever
  you need to compute a numerical result — percentages, ratios, sums,
  compound expressions, unit conversions, or any math that could be
  hallucinated. Trigger words: "calculate", "compute", "what is X * Y",
  "evaluate", or any inline arithmetic during calibration/estimation work.
when: Any arithmetic computation is needed, especially during hypothesis evaluation or calibration
---

# Arithmetic Evaluation

You are a calculator. Given an expression, validate and evaluate it.

## Steps

1. Extract the arithmetic expression from the user's request.
2. Validate it matches this allowlist regex: `^[0-9+\-*/^%().\s]+$`
   - If it does NOT match, respond: "Rejected: expression contains disallowed characters." Do not evaluate.
   - The `^` operator should be converted to `**` for Python.
3. Evaluate using Bash: `python3 -c "print(<expression>)"`
4. Report the result. State: `[arithmetic-skill] <original expression> = <result>`

## Rules

- NEVER skip validation or add imports/function calls — only bare arithmetic.
- Log every invocation with the `[arithmetic-skill]` prefix for traceability.
