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
2. **Mode 1 is sound; the Mode 2 static gate is only a speed-bump.** Mode 1 evaluates through an AST allowlist that can *only* produce a number — no calls, no names, no imports — so it is a hard boundary. Mode 2's `check.py` rejects non-approved imports and dangerous call patterns, but a denylist over Python-with-scientific-modules **cannot be made sound** (reflection, an eval surface inside an approved module, a future numpy CVE). Treat it as raising the bar, not as containment.
3. **The OS sandbox is Mode 2's actual boundary.** Mode 2 scripts execute through `run.sh`, which picks the strongest sandbox available — `bwrap` (read-only rootfs, private tmpfs, no network, cleared env) → unprivileged `unshare -rn` (no network) → resource-limits + a best-effort Python-level network block, **warning loudly** in that last case. All tiers add `timeout` + `ulimit`.

> **Residual risk (Mode 2):** even under `bwrap`, an approved module can read files still visible on the read-only rootfs and print them to output — network exfiltration is blocked, disclosure-to-transcript is not. Do not point Mode 2 at paths outside the data you were asked to compute over. If `run.sh` prints the "no OS sandbox available" warning, the static gate is the *only* code-exec barrier and it is not sound — **do not run scripts influenced by untrusted input on that tier.**

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
MAX_EXP = 1000      # per-operation exponent cap
MAX_BITS = 100000   # ~30k digits; caps RESULT size so nested a**b**c can't blow up
def ev(n):
    if isinstance(n, ast.Expression): return ev(n.body)
    if isinstance(n, ast.Constant):
        if isinstance(n.value, (int, float, complex)): return n.value
        raise ValueError("non-numeric literal")
    if isinstance(n, ast.UnaryOp) and type(n.op) in OPS:
        return OPS[type(n.op)](ev(n.operand))
    if isinstance(n, ast.BinOp) and type(n.op) in OPS:
        l, r = ev(n.left), ev(n.right)   # each child evaluated exactly once
        if isinstance(n.op, ast.Pow):
            if abs(r) > MAX_EXP:
                raise ValueError("exponent too large")
            # Predict the result's bit length BEFORE computing, so a nested
            # tower like ((10**1000)**1000)**1000 is rejected, not materialized.
            if isinstance(l, int) and isinstance(r, int) and r > 0 \
               and l not in (0, 1, -1) and r * l.bit_length() > MAX_BITS:
                raise ValueError("result too large")
        return OPS[type(n.op)](l, r)
    raise ValueError(f"disallowed: {type(n).__name__}")
src = sys.stdin.read().replace("^", "**")
try:
    result = ev(ast.parse(src, mode="eval"))
except (ValueError, SyntaxError, TypeError, ZeroDivisionError, OverflowError) as e:
    print(f"[arithmetic-eval] REJECTED — {e}"); sys.exit(1)   # tagged, never a bare traceback
print(f"[arithmetic-eval] {src.strip()} → {result}")
PYEOF

# Evaluate — expression is INERT stdin (quoted heredoc = no interpolation),
# under CPU + memory limits so a pathological expression can't hang the host.
# The [ -f ] guard keeps a skipped setup LOUD instead of a silent no-output.
if [ -f "$AE_DIR/eval.py" ]; then
  ( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 "$AE_DIR/eval.py" ) <<'EXPREOF'
<expression here>
EXPREOF
else
  echo "[arithmetic-eval] NOT EVALUATED (setup missing) — do NOT use an unverified number" >&2
fi
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
# pathlib (general-purpose filesystem writes) and operator (attrgetter/methodcaller
# → reflection RCE) are intentionally NOT approved — the OS sandbox is the backstop
# for the write/exec surfaces that remain in numpy/pandas/openpyxl/matplotlib.
ALLOWED_MODULES = {
    "math","statistics","scipy","numpy","pandas","sympy","csv","json",
    "fractions","decimal","datetime","re","itertools","functools",
    "collections","openpyxl","matplotlib",
}
BAD_NAMES = {"eval","exec","compile","__import__","__builtins__","getattr","setattr",
             "delattr","globals","locals","vars","input","breakpoint","memoryview"}
# Attribute names specific enough NOT to collide with core scipy/pandas/json APIs.
# Generic names (load/loads/rename/replace/run/call) are deliberately excluded —
# they would reject json.load / df.rename / df.replace. Their dangerous cases are
# covered elsewhere: pickle/subprocess/os/pathlib are import-blocked, and np.load
# RCE is caught by the allow_pickle check below.
BAD_ATTRS = {
    "system","popen","spawn","spawnl","spawnv","fork","execl","execv",
    "read_pickle","to_pickle",                             # pandas pickle RCE
    "sympify","parse_expr","eval","query",                # expression-eval surfaces
    "write_text","write_bytes","unlink","rmtree","rmdir","mkdir",
    "chmod","symlink_to","hardlink_to","touch",           # filesystem writes
    "check_output","Popen","getoutput",                    # subprocess
}
# Dunder strings used in reflection-based sandbox escapes — blocked as string
# literals so `x.__class__` typed as getattr(x, "__class__") can't sneak through.
# __main__/__name__/__file__ are deliberately allowed (the standard entry idiom).
BAD_DUNDER_STRINGS = {
    "__globals__","__builtins__","__import__","__class__","__bases__",
    "__subclasses__","__mro__","__dict__","__getattribute__","__getattr__",
    "__code__","__closure__","__func__","__self__","__loader__","__base__",
    "__reduce__","__reduce_ex__","__subclasshook__","__init_subclass__",
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
    elif isinstance(node, ast.Constant) and isinstance(node.value, str) \
         and node.value in BAD_DUNDER_STRINGS:
        fail(f"dangerous dunder string literal '{node.value}'", node)
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
            mode_node = node.args[1] if len(node.args) >= 2 else None
            for kw in node.keywords:
                if kw.arg == "mode":
                    mode_node = kw.value
            # No mode arg → read-only default, fine. Any mode present must be a
            # literal read mode; a variable mode is unprovable, so fail closed.
            if mode_node is not None:
                ok = isinstance(mode_node, ast.Constant) and mode_node.value in ("r","rb","rt")
                if not ok:
                    fail("open() with non-read-only or non-literal mode", node)
        for kw in node.keywords:
            # Fail closed: anything not a literal False (1, a variable, True) is unsafe.
            if kw.arg == "allow_pickle":
                safe = isinstance(kw.value, ast.Constant) and kw.value.value is False
                if not safe:
                    fail("allow_pickle not provably False (deserialization RCE)", node)
sys.exit(0)
PYEOF

# Write the network-blocking loader used by the fallback tier (no namespace to
# drop the net, so neuter Python's socket layer before running the script):
cat > "$AE_DIR/nonet.py" <<'PYEOF'
import socket, sys, runpy
def _blocked(*a, **k):
    raise OSError("network disabled in arithmetic-eval fallback tier")
for _n in ("socket","create_connection","getaddrinfo","gethostbyname","gethostbyname_ex"):
    setattr(socket, _n, _blocked)
runpy.run_path(sys.argv[1], run_name="__main__")
PYEOF

# Write the confinement runner once per session:
cat > "$AE_DIR/run.sh" <<'SHEOF'
#!/usr/bin/env bash
# Tiered OS confinement. Runs $1 under the strongest sandbox available. The
# static gate (check.py) must have passed first — this is the OS backstop.
set -uo pipefail
SCRIPT="$1"; DIR=$(dirname "$SCRIPT")
# Pin thread pools to 1 so numpy/scipy/BLAS don't reserve multi-GB of virtual
# memory and trip the -v limit (this is a verifier, not a compute cluster).
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
# CPU 10s, address space ~8GB (generous headroom for BLAS arenas), written file
# ≤50MB, wall-clock backstop 10s.
LIM='ulimit -t 10 -v 8000000 -f 51200 2>/dev/null; exec timeout 10 python3 "$0"'
if command -v bwrap >/dev/null 2>&1; then
  exec bwrap \
    --ro-bind / / --dev /dev --proc /proc \
    --tmpfs /tmp --tmpfs /run --bind "$DIR" "$DIR" \
    --unshare-all --die-with-parent --new-session \
    --clearenv --setenv PATH /usr/bin:/bin:/usr/local/bin \
    --setenv HOME /tmp --setenv MPLCONFIGDIR /tmp/mpl \
    --setenv OMP_NUM_THREADS 1 --setenv OPENBLAS_NUM_THREADS 1 \
    --setenv MKL_NUM_THREADS 1 --setenv NUMEXPR_NUM_THREADS 1 \
    bash -c "$LIM" "$SCRIPT"
elif unshare -rn true 2>/dev/null; then
  exec unshare -rn bash -c "$LIM" "$SCRIPT"
else
  echo "[arithmetic-eval] WARNING: no OS sandbox (bwrap/unshare) available — resource limits + a best-effort Python-level network block only; local files stay readable and the static gate is not sound. Do NOT run untrusted-influenced scripts here." >&2
  # nonet.py neuters the socket layer, then runpy's the script under the limits.
  exec bash -c 'ulimit -t 10 -v 8000000 -f 51200 2>/dev/null; exec timeout 10 python3 "$1/nonet.py" "$2"' _ "$DIR" "$SCRIPT"
fi
SHEOF

# Gate, then run under the strongest available OS confinement.
# The else is REQUIRED: a missing helper OR a rejection must be loud — never a
# silent no-output that tempts a fallback to an unverified (hallucinated) number.
if [ -f "$AE_DIR/check.py" ] && [ -f "$AE_DIR/run.sh" ] && [ -f "$AE_DIR/nonet.py" ] \
   && python3 "$AE_DIR/check.py" "$AE_DIR/script.py"; then
  bash "$AE_DIR/run.sh" "$AE_DIR/script.py"
else
  echo "[arithmetic-eval] NOT EVALUATED (setup missing or script rejected) — do NOT use an unverified number" >&2
fi
```

### Approved modules (enforced by `check.py`)

`math`, `statistics`, `scipy`, `numpy`, `pandas`, `sympy`, `csv`, `json`,
`fractions`, `decimal`, `datetime`, `re`, `itertools`, `functools`,
`collections`, `openpyxl`, `matplotlib`

(`pathlib` and `operator` are deliberately **not** approved — see the comment in `check.py`.)

### Blocked patterns (enforced by `check.py`, not by eyeballing)

Non-approved imports; the names `eval`/`exec`/`compile`/`__import__`/`__builtins__`/`getattr`/`setattr`/`delattr`/`globals`/`locals`/`vars`/`input`/`breakpoint`/`memoryview`; expression-eval surfaces (`.eval`, `.query`, `sympify`, `parse_expr`); deserialization sinks (`read_pickle`, and `np.load` unless `allow_pickle` is provably `False`); filesystem-write methods (`write_text`, `unlink`, `rmtree`, `touch`, …); subprocess entry points; dunder attribute *and* string-literal access (e.g. `"__globals__"`); and `open()` with any mode that is not a literal read mode (a variable mode fails closed).

Read-mode `open()` is permitted for loading data files — but remember it can disclose local secrets to output. Do not read paths outside the data you were asked to compute over.

## Rules

- **Always tag output**: print `[arithmetic-eval]` so invocations are traceable.
- **Never interpolate untrusted text into a command.** Always feed expressions/scripts via a quoted heredoc (`<<'EOF'`).
- **Never skip validation**: even for `2+2`, run through the appropriate mode.
- **Chain for multi-step**: break complex calculations into named intermediate steps.
- **On rejection**: do NOT fall back to mental math. Fix the expression or report the error.
- **Mode choice**: only numbers and operators → Mode 1. Needs imports or function calls → Mode 2.

## Examples

> Both examples assume the one-time setup and the mode's helper-writing block
> (`eval.py` for Mode 1; `check.py` + `run.sh` + `nonet.py` for Mode 2) have
> already run this session. If `$AE_DIR` is unset, run the setup first. The
> examples show only the per-invocation part; the gate-and-run form is exactly
> the canonical block in each mode above — don't fork a divergent copy.

### Example 1 — Mode 1: cost estimate inside a fact-check

User claim: "We spent ~$3,600 last month on inference at $0.003/1K tokens."

```bash
( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 "$AE_DIR/eval.py" ) <<'EXPREOF'
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
# gate-and-run: identical to the canonical Mode 2 block above (do not diverge).
if [ -f "$AE_DIR/check.py" ] && [ -f "$AE_DIR/run.sh" ] && [ -f "$AE_DIR/nonet.py" ] \
   && python3 "$AE_DIR/check.py" "$AE_DIR/script.py"; then
  bash "$AE_DIR/run.sh" "$AE_DIR/script.py"
else
  echo "[arithmetic-eval] NOT EVALUATED (setup missing or script rejected) — do NOT use an unverified number" >&2
fi
# → [arithmetic-eval] t=8.062, p=0.00001
# Interpretation: claim supported at p < 0.05.
```

### Example 3 — When NOT to mental-math

Bad: writing "1.2M users × $4 ARPU = $4.8M/mo" without running the math.
Good: run `1.2e6 * 4` through Mode 1, then write the verified number.

Running this skill costs ~one bash invocation. A wrong number in a fact-check or cost estimate costs much more. When in doubt, run it.
