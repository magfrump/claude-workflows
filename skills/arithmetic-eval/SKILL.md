---
name: arithmetic-eval
description: >
  Validate and evaluate math using python3 to prevent hallucinated calculations.
  Two modes: (1) bare arithmetic (numbers + operators only) evaluated through a
  safe AST allowlist — no shell interpolation, no eval; (2) scientific computing
  (imports, scripts, dataframes) gated by a machine-enforced static checker over an
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

## Security model (read once)

The expression or script you evaluate is often **attacker-influenceable** — it comes from a document being fact-checked, a user claim, or code under review. Treat it as untrusted data. Two rules make that safe:

1. **Never interpolate untrusted text into shell or Python source.** Feed it as *data* through a **quoted heredoc** (`<<'EOF'`), which disables all shell expansion of the body. Do not paste an expression into an `EXPR='...'` assignment — a single quote in the input breaks out and executes as shell.
2. **Enforcement is by machine, not by eye.** Mode 1 evaluates through an AST allowlist (no `eval`); Mode 2 runs a static checker that rejects non-approved imports and dangerous call patterns. Both run under `timeout` + `ulimit`.

> **Residual risk (Mode 2):** the static checker is defense-in-depth, not a sandbox. Approved modules can still read local files (and print them) and have edge-case exec paths. If the script is influenced by genuinely untrusted input, additionally run it under OS confinement — `bwrap --unshare-net --ro-bind / /` with rlimits — or don't run it.

## One-time setup (per session)

Write the two helpers to unpredictable temp paths (`mktemp` respects `$TMPDIR` and avoids the fixed-`/tmp` symlink/TOCTOU footgun):

```bash
AE_DIR=$(mktemp -d "${TMPDIR:-/tmp}/arith.XXXXXX")
```

## Mode 1: Bare Arithmetic

Simple numeric expressions, no imports or function calls. Evaluated through an AST allowlist — the expression can only ever produce a number; it can never call, import, or exec.

```bash
# Write the evaluator once per session:
cat > "$AE_DIR/eval.py" <<'PYEOF'
import ast, sys, operator
OPS = {ast.Add:operator.add, ast.Sub:operator.sub, ast.Mult:operator.mul,
       ast.Div:operator.truediv, ast.FloorDiv:operator.floordiv,
       ast.Mod:operator.mod, ast.Pow:operator.pow,
       ast.USub:operator.neg, ast.UAdd:operator.pos}
MAX_EXP = 1000  # cap exponents so 9**9**9 can't exhaust CPU/memory
def ev(n):
    if isinstance(n, ast.Expression): return ev(n.body)
    if isinstance(n, ast.Constant):
        if isinstance(n.value, (int, float, complex)): return n.value
        raise ValueError("non-numeric literal")
    if isinstance(n, ast.UnaryOp) and type(n.op) in OPS:
        return OPS[type(n.op)](ev(n.operand))
    if isinstance(n, ast.BinOp) and type(n.op) in OPS:
        if isinstance(n.op, ast.Pow) and abs(ev(n.right)) > MAX_EXP:
            raise ValueError("exponent too large")
        return OPS[type(n.op)](ev(n.left), ev(n.right))
    raise ValueError(f"disallowed: {type(n).__name__}")
src = sys.stdin.read().replace("^", "**")
print(f"[arithmetic-eval] {src.strip()} → {ev(ast.parse(src, mode='eval'))}")
PYEOF

# Evaluate — the expression is INERT stdin (quoted heredoc = no interpolation):
timeout 5 python3 "$AE_DIR/eval.py" <<'EXPREOF'
<expression here>
EXPREOF
```

On a disallowed character or oversized exponent the evaluator raises and prints nothing to stdout — that is a rejection, not a result. Do NOT fall back to mental math; fix the expression or report the error.

## Mode 2: Scientific Computing

Imports, function calls, multi-line scripts (t-tests, CSV loading, plotting, etc.). The script is written via a quoted heredoc (inert), passed through a static checker, and only then executed under resource limits.

```bash
# Write the target script (quoted heredoc — body is never shell-expanded):
cat > "$AE_DIR/script.py" <<'PYEOF'
<script here>
PYEOF

# Write the static gate once per session:
cat > "$AE_DIR/check.py" <<'PYEOF'
import ast, sys
ALLOWED_MODULES = {
    "math","statistics","scipy","numpy","pandas","sympy","csv","json",
    "fractions","decimal","datetime","pathlib","re","itertools","functools",
    "collections","operator","openpyxl","matplotlib",
}
BAD_NAMES = {"eval","exec","compile","__import__","getattr","setattr","delattr",
             "globals","locals","vars","input","breakpoint","memoryview"}
BAD_ATTRS = {
    "system","popen","spawn","spawnl","spawnv","fork","execl","execv",
    "read_pickle","to_pickle","load","loads",              # pickle / np.load RCE
    "sympify","parse_expr",                                # sympy eval paths
    "write_text","write_bytes","unlink","rmtree","rmdir","mkdir",
    "rename","replace","chmod","symlink_to","touch",       # filesystem writes
    "check_output","run","call","Popen","getoutput",       # subprocess
}
def fail(msg, node=None):
    ln = f" (line {node.lineno})" if getattr(node, "lineno", None) else ""
    print(f"[arithmetic-eval] REJECTED — {msg}{ln}", file=sys.stderr); sys.exit(1)
src = open(sys.argv[1]).read()
try:
    tree = ast.parse(src)
except SyntaxError as e:
    fail(f"syntax error: {e}")
for node in ast.walk(tree):
    if isinstance(node, ast.Import):
        for a in node.names:
            if a.name.split(".")[0] not in ALLOWED_MODULES:
                fail(f"import of non-approved module '{a.name}'", node)
    elif isinstance(node, ast.ImportFrom):
        root = (node.module or "").split(".")[0]
        if node.level or root not in ALLOWED_MODULES:
            fail(f"import from non-approved module '{node.module}'", node)
    elif isinstance(node, ast.Name) and node.id in BAD_NAMES:
        fail(f"use of banned name '{node.id}'", node)
    elif isinstance(node, ast.Attribute):
        if node.attr in BAD_ATTRS:
            fail(f"dangerous attribute/method '.{node.attr}'", node)
        if node.attr.startswith("__") and node.attr.endswith("__"):
            fail(f"dunder access '.{node.attr}'", node)
    elif isinstance(node, ast.Call):
        f = node.func
        is_open = (isinstance(f, ast.Name) and f.id == "open") or \
                  (isinstance(f, ast.Attribute) and f.attr == "open")
        if is_open:
            mode = None
            if len(node.args) >= 2 and isinstance(node.args[1], ast.Constant):
                mode = node.args[1].value
            for kw in node.keywords:
                if kw.arg == "mode" and isinstance(kw.value, ast.Constant):
                    mode = kw.value.value
            if isinstance(mode, str) and mode not in ("r","rb","rt") \
               and any(c in mode for c in "waxr+"):
                fail(f"open() in non-readonly mode '{mode}'", node)
        for kw in node.keywords:
            if kw.arg == "allow_pickle" and getattr(kw.value, "value", False) is True:
                fail("allow_pickle=True (deserialization RCE)", node)
sys.exit(0)
PYEOF

# Gate, then run under CPU + address-space + wall-clock limits:
if python3 "$AE_DIR/check.py" "$AE_DIR/script.py"; then
  ( ulimit -t 10 -v 2000000; timeout 10 python3 "$AE_DIR/script.py" )
fi
```

### Approved modules (enforced by `check.py`)

`math`, `statistics`, `scipy`, `numpy`, `pandas`, `sympy`, `csv`, `json`,
`fractions`, `decimal`, `datetime`, `pathlib`, `re`, `itertools`, `functools`,
`collections`, `operator`, `openpyxl`, `matplotlib`

### Blocked patterns (enforced by `check.py`, not by eyeballing)

Non-approved imports; the names `eval`/`exec`/`compile`/`__import__`/`getattr`/`setattr`/`globals`/`locals`; deserialization sinks (`read_pickle`, `np.load(..., allow_pickle=True)`, `sympify`); filesystem-write methods (`write_text`, `unlink`, `rmtree`, `touch`, `rename`, …); subprocess entry points; dunder attribute access; and `open()` in any non-read mode.

Read-mode `open()` is permitted for loading data files — but remember it can disclose local secrets to output. Do not read paths outside the data you were asked to compute over.

## Rules

- **Always tag output**: print `[arithmetic-eval]` so invocations are traceable.
- **Never interpolate untrusted text into a command.** Always feed expressions/scripts via a quoted heredoc (`<<'EOF'`).
- **Never skip validation**: even for `2+2`, run through the appropriate mode.
- **Chain for multi-step**: break complex calculations into named intermediate steps.
- **On rejection**: do NOT fall back to mental math. Fix the expression or report the error.
- **Mode choice**: only numbers and operators → Mode 1. Needs imports or function calls → Mode 2.

## Examples

### Example 1 — Mode 1: cost estimate inside a fact-check

User claim: "We spent ~$3,600 last month on inference at $0.003/1K tokens."

```bash
timeout 5 python3 "$AE_DIR/eval.py" <<'EXPREOF'
3600 / 0.003 * 1000
EXPREOF
# → [arithmetic-eval] 3600 / 0.003 * 1000 → 1200000000.0
# Interpretation: ~1.2B tokens. Sanity-check this against logged usage.
```

### Example 2 — Mode 2: t-test for a benchmark claim

User claim: "Variant B is significantly faster than variant A (p < 0.05)."

```bash
cat > "$AE_DIR/script.py" <<'PYEOF'
from scipy import stats
a = [102, 98, 105, 101, 99, 103, 100, 104]
b = [92,  95,  91,  94,  93,  90,  96,  92]
t, p = stats.ttest_ind(a, b)
print(f"[arithmetic-eval] t={t:.3f}, p={p:.5f}")
PYEOF
if python3 "$AE_DIR/check.py" "$AE_DIR/script.py"; then
  ( ulimit -t 10 -v 2000000; timeout 10 python3 "$AE_DIR/script.py" )
fi
# → [arithmetic-eval] t=8.062, p=0.00001
# Interpretation: claim supported at p < 0.05.
```

### Example 3 — When NOT to mental-math

Bad: writing "1.2M users × $4 ARPU = $4.8M/mo" without running the math.
Good: run `1.2e6 * 4` through Mode 1, then write the verified number.

Running this skill costs ~one bash invocation. A wrong number in a fact-check or cost estimate costs much more. When in doubt, run it.
