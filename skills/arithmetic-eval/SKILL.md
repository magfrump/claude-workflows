---
name: arithmetic-eval
description: >
  Validate and evaluate math using python3 to prevent hallucinated calculations.
  Two modes: (1) bare arithmetic (numbers + operators only) via a safe AST
  evaluator — no shell interpolation, no eval; (2) scientific computing (imports,
  scripts, dataframes) gated by a machine-enforced static checker over an
  approved-modules allowlist for scipy, numpy, pandas, sympy, statistics, etc.,
  then run under OS confinement. Use whenever performing, verifying, or
  double-checking ANY calculation, including: intermediate math inside a
  fact-check ("does 2.3M / 41 ≈ 56k?"), cost estimates ("$0.003 × 1.2M tokens"),
  unit conversions, percentage changes, t-tests, p-values, confidence intervals,
  CSV/JSON aggregations, regression coefficients, and sanity checks in code review.
  Default to using this skill — mental math is the exception, not the rule.
  Trigger phrases: "compute", "calculate", "what's X% of Y", "how many",
  "verify this number", "check the math", "is this right", or any expression with
  operators (+, -, *, /, %, **) on non-trivial operands.
when: Any arithmetic or scientific computation is needed (default on, not opt-in)
---

> On bad output, see guides/skill-recovery.md

# Arithmetic Eval

Exact-math tool available. **Use it instead of mental math.** Writing a number that is a calculation result — even "simple" like `12 * 365` or `15% of 240` — run it through this skill first. Mental arithmetic is the most common source of hallucinated facts in otherwise-careful work.

## Security model (read once)

The expression or script you evaluate is often **attacker-influenceable** — it comes from a document being fact-checked, a user claim, or code under review. Treat it as untrusted data.

1. **Never interpolate untrusted text into shell or Python source.** Feed it as *data* through a **quoted heredoc** (`<<'EOF'`), which disables all shell expansion of the body. Never paste an expression into an `EXPR='...'` assignment — a single quote in the input breaks out and executes as shell.
2. **Each invocation is self-contained.** Shell state (variables) does **not** survive between separate command runs, so every block below writes what it needs and runs it in one shot — there is no "setup once, use later" step to forget. Mode 2 uses a fresh `mktemp -d` per run and deletes it after, so a poisoned helper can never carry into the next call.
3. **Mode 1 is sound; the Mode 2 static gate is only a speed-bump.** Mode 1 evaluates through an AST allowlist that can *only* produce a number — no calls, names, or imports — a hard boundary. Mode 2's `check.py` raises the bar (rejects non-approved imports and dangerous patterns) but a denylist over Python-with-scientific-modules **cannot be made sound**. The **OS sandbox is Mode 2's actual boundary**; the gate is defense-in-depth in front of it.

> **Residual risk (Mode 2):** even under `bwrap`, an approved module can read files visible on the read-only rootfs and print them — network exfiltration is blocked, disclosure-to-transcript is not. Do not point Mode 2 at paths outside the data you were asked to compute over. If the runner prints the "no OS sandbox available" warning, only the static gate (not sound) plus a best-effort Python-level net+write block stand between an untrusted script and the host — **do not run untrusted-influenced scripts on that tier.**

## Mode 1: Bare Arithmetic

Simple numeric expressions, no imports or function calls. The expression is inert stdin (quoted heredoc); the evaluator is a fixed program that can only walk a numeric AST. Self-contained — paste and run:

```bash
( ulimit -t 5 -v 1000000 2>/dev/null; timeout 5 python3 -c '
import ast, sys, operator
if hasattr(sys, "set_int_max_str_digits"): sys.set_int_max_str_digits(60000)
OPS = {ast.Add:operator.add, ast.Sub:operator.sub, ast.Mult:operator.mul,
       ast.Div:operator.truediv, ast.FloorDiv:operator.floordiv,
       ast.Mod:operator.mod, ast.Pow:operator.pow,
       ast.USub:operator.neg, ast.UAdd:operator.pos}
MAX_EXP = 1000      # per-operation exponent cap
MAX_BITS = 100000   # ~30k digits; caps RESULT size so nested a**b**c cannot blow up
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
            if abs(r) > MAX_EXP: raise ValueError("exponent too large")
            if isinstance(l, int) and isinstance(r, int) and r > 0 \
               and l not in (0, 1, -1) and r * l.bit_length() > MAX_BITS:
                raise ValueError("result too large")
        return OPS[type(n.op)](l, r)
    raise ValueError(f"disallowed: {type(n).__name__}")
src = sys.stdin.read().replace("^", "**")
try:
    result = ev(ast.parse(src, mode="eval"))
    out = f"[arithmetic-eval] {src.strip()} -> {result}"   # str(result) inside try
except (ValueError, SyntaxError, TypeError, ZeroDivisionError, OverflowError) as e:
    print(f"[arithmetic-eval] REJECTED — {e}"); sys.exit(1)
print(out)
' ) <<'EXPREOF'
3600 / 0.003 * 1000
EXPREOF
# → [arithmetic-eval] 3600 / 0.003 * 1000 -> 1200000000.0
```

A rejection prints a tagged `[arithmetic-eval] REJECTED — …` and exits non-zero — never a bare traceback. Do NOT fall back to mental math; fix the expression or report the error.

## Mode 2: Scientific Computing

Imports, function calls, multi-line scripts (t-tests, CSV loading, plotting). One self-contained block: it writes the script and two helpers into a throwaway `mktemp -d`, statically gates the script, runs it under the strongest OS sandbox available, and cleans up. Replace `<script here>`:

```bash
AE=$(mktemp -d "${TMPDIR:-/tmp}/aeval.XXXXXX"); trap 'rm -rf "$AE"' EXIT

cat > "$AE/script.py" <<'PYEOF'
<script here>
PYEOF

cat > "$AE/check.py" <<'PYEOF'
import ast, sys
# pathlib is approved for READS; its write methods are blocked below and at runtime.
# operator is intentionally NOT approved (attrgetter/methodcaller reflection → RCE).
ALLOWED_MODULES = {
    "math","statistics","scipy","numpy","pandas","sympy","csv","json",
    "fractions","decimal","datetime","pathlib","re","itertools","functools",
    "collections","openpyxl","matplotlib",
}
BAD_NAMES = {"eval","exec","compile","__import__","__builtins__","getattr","setattr",
             "delattr","globals","locals","vars","input","breakpoint","memoryview"}
# Attribute names specific enough NOT to collide with core scipy/pandas/json APIs.
# Generic names (load/rename/replace) are excluded — they'd reject json.load /
# df.rename; their dangerous cases are handled by the positional-load and
# allow_pickle checks below and by the OS sandbox / runtime confine layer.
BAD_ATTRS = {
    "system","popen","spawn","spawnl","spawnv","fork","execl","execv",
    "read_pickle","to_pickle",                             # pandas pickle RCE
    "sympify","parse_expr","eval","query",                # expression-eval surfaces
    "write_text","write_bytes","unlink","rmtree","rmdir","mkdir",
    "chmod","symlink_to","hardlink_to","touch",           # filesystem writes
    "check_output","Popen","getoutput",                    # subprocess
}
# Dunder strings used in reflection escapes — blocked as string literals so
# getattr(x, "__globals__")-style access can't sneak through. __main__/__name__
# are allowed (the standard entry idiom).
BAD_DUNDER_STRINGS = {
    "__globals__","__builtins__","__import__","__class__","__bases__",
    "__subclasses__","__mro__","__dict__","__getattribute__","__getattr__",
    "__code__","__closure__","__func__","__self__","__loader__","__base__",
    "__reduce__","__reduce_ex__","__subclasshook__","__init_subclass__",
}
def fail(msg, node=None):
    ln = f" (line {node.lineno})" if getattr(node, "lineno", None) else ""
    print(f"[arithmetic-eval] REJECTED — {msg}{ln}", file=sys.stderr); sys.exit(1)
try:
    src = open(sys.argv[1]).read()
except OSError as e:
    fail(f"cannot read script: {e}")
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
    elif isinstance(node, ast.Constant) and isinstance(node.value, str):
        if node.value in BAD_DUNDER_STRINGS:
            fail(f"dangerous dunder string literal '{node.value}'", node)
        if "://" in node.value:
            fail(f"URL literal not allowed: {node.value[:40]!r}", node)
    elif isinstance(node, ast.Attribute):
        if node.attr in BAD_ATTRS:
            fail(f"dangerous attribute/method '.{node.attr}'", node)
        if node.attr.startswith("__") and node.attr.endswith("__"):
            fail(f"dunder access '.{node.attr}'", node)
    elif isinstance(node, ast.Call):
        f = node.func
        # numpy allow_pickle via 3rd positional: np.load(file, mmap_mode, allow_pickle)
        if isinstance(f, ast.Attribute) and f.attr == "load" and len(node.args) >= 3:
            fail("load() with 3rd positional arg (numpy allow_pickle RCE)", node)
        is_open = (isinstance(f, ast.Name) and f.id == "open") or \
                  (isinstance(f, ast.Attribute) and f.attr == "open")
        if is_open:
            mode_node = node.args[1] if len(node.args) >= 2 else None
            for kw in node.keywords:
                if kw.arg == "mode": mode_node = kw.value
            # No mode → read default. Any mode present must be a literal read mode;
            # a variable mode is unprovable, so fail closed.
            if mode_node is not None:
                ok = isinstance(mode_node, ast.Constant) and mode_node.value in ("r","rb","rt")
                if not ok: fail("open() with non-read-only or non-literal mode", node)
        for kw in node.keywords:
            if kw.arg == "allow_pickle":   # fail closed: anything not literal False
                safe = isinstance(kw.value, ast.Constant) and kw.value.value is False
                if not safe: fail("allow_pickle not provably False (deserialization RCE)", node)
sys.exit(0)
PYEOF

cat > "$AE/confine.py" <<'PYEOF'
# Best-effort Python-level confinement for the no-OS-sandbox fallback tier:
# neuter network egress AND filesystem writes before running the target script.
import builtins, io, socket, os, sys, runpy
_real_open = builtins.open
def _ro_open(file, mode="r", *a, **k):
    m = mode if isinstance(mode, str) else "r"
    if any(c in m for c in "wax+"):
        raise PermissionError(f"write-mode open blocked (fallback tier): {file!r}")
    return _real_open(file, mode, *a, **k)
builtins.open = _ro_open
io.open = _ro_open                         # pathlib/Path.write_text route through here
def _no_net(*a, **k):
    raise OSError("network disabled (fallback tier)")
try:
    socket.socket.connect = _no_net        # also affects `from socket import socket`
    socket.socket.connect_ex = _no_net
except (TypeError, AttributeError):
    pass
socket.create_connection = _no_net
socket.getaddrinfo = _no_net               # kills hostname resolution → most egress
def _no_fs(*a, **k):
    raise PermissionError("filesystem write blocked (fallback tier)")
_real_osopen = os.open
def _ro_osopen(path, flags, *a, **k):
    if flags & (os.O_WRONLY | os.O_RDWR | os.O_CREAT | os.O_APPEND | os.O_TRUNC):
        raise PermissionError("os.open write blocked (fallback tier)")
    return _real_osopen(path, flags, *a, **k)
os.open = _ro_osopen
for _n in ("remove","unlink","rename","replace","rmdir","removedirs",
           "mkdir","makedirs","chmod","symlink","link","truncate"):
    if hasattr(os, _n): setattr(os, _n, _no_fs)
runpy.run_path(sys.argv[1], run_name="__main__")
PYEOF

# Gate, then run under the strongest available OS confinement.
if python3 "$AE/check.py" "$AE/script.py"; then
  s="$AE/script.py"
  LIM='ulimit -t 10 -v 8000000 -f 51200 2>/dev/null'   # CPU/addr-space/file-size caps
  export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1
  ENV='--setenv PATH /usr/bin:/bin:/usr/local/bin --setenv HOME /tmp --setenv MPLCONFIGDIR /tmp/mpl --setenv OMP_NUM_THREADS 1 --setenv OPENBLAS_NUM_THREADS 1 --setenv MKL_NUM_THREADS 1 --setenv NUMEXPR_NUM_THREADS 1'
  # bwrap is PROBED for a working userns (present-but-broken must degrade, not fail).
  if command -v bwrap >/dev/null 2>&1 && bwrap --ro-bind / / --unshare-all --die-with-parent true 2>/dev/null; then
    # helper dir mounted READ-ONLY (script can't poison check.py); CWD is writable tmpfs.
    bwrap --ro-bind / / --ro-bind "$AE" "$AE" --dev /dev --proc /proc --tmpfs /tmp \
      --chdir /tmp --unshare-all --die-with-parent --new-session --clearenv $ENV \
      bash -c "$LIM"'; exec timeout 10 python3 "$0"' "$s"
  elif unshare -rn true 2>/dev/null; then
    unshare -rn bash -c "$LIM"'; exec timeout 10 python3 "$0"' "$s"
  else
    echo "[arithmetic-eval] WARNING: no OS sandbox (bwrap/unshare) available — resource limits + a best-effort Python-level net+write block only; the static gate is not sound. Do NOT run untrusted-influenced scripts here." >&2
    bash -c "$LIM"'; exec timeout 10 python3 "$1/confine.py" "$2"' _ "$AE" "$s"
  fi
else
  echo "[arithmetic-eval] NOT EVALUATED (script rejected) — do NOT use an unverified number" >&2
fi
```

### Approved modules (enforced by `check.py`)

`math`, `statistics`, `scipy`, `numpy`, `pandas`, `sympy`, `csv`, `json`,
`fractions`, `decimal`, `datetime`, `pathlib`, `re`, `itertools`, `functools`,
`collections`, `openpyxl`, `matplotlib`

(`operator` is deliberately **not** approved — `attrgetter`/`methodcaller` give a reflection path to RCE. `pathlib` is approved for reads; its write methods are blocked.)

### Blocked patterns (enforced by `check.py`, not by eyeballing)

Non-approved imports; the names `eval`/`exec`/`compile`/`__import__`/`__builtins__`/`getattr`/`setattr`/`delattr`/`globals`/`locals`/`vars`/`input`/`breakpoint`/`memoryview`; expression-eval surfaces (`.eval`, `.query`, `sympify`, `parse_expr`); deserialization sinks (`read_pickle`; `np.load` with `allow_pickle` truthy **or** via a 3rd positional arg); filesystem-write methods (`write_text`, `unlink`, `rmtree`, `touch`, …); subprocess entry points; dunder attribute *and* string-literal access (e.g. `"__globals__"`); URL string literals (`…://…`); and `open()` with any mode that is not a literal read mode (a variable mode fails closed).

Read-mode `open()` is permitted for loading data files — but it can disclose local secrets to output. Do not read paths outside the data you were asked to compute over.

## Rules

- **Always tag output**: print `[arithmetic-eval]` so invocations are traceable.
- **Never interpolate untrusted text into a command.** Always feed expressions/scripts via a quoted heredoc (`<<'EOF'`).
- **Never skip validation**: even for `2+2`, run through the appropriate mode.
- **Each block is self-contained** — there is no persistent setup; paste the whole block every time.
- **On rejection**: do NOT fall back to mental math. Fix the expression or report the error.
- **Mode choice**: only numbers and operators → Mode 1. Needs imports or function calls → Mode 2.

## Examples

### Example 1 — Mode 1: cost estimate inside a fact-check

User claim: "We spent ~$3,600 last month on inference at $0.003/1K tokens." → run the Mode 1 block with `3600 / 0.003 * 1000` as the heredoc body → `1200000000.0` (~1.2B tokens; sanity-check against logged usage).

### Example 2 — Mode 2: t-test for a benchmark claim

User claim: "Variant B is significantly faster than variant A (p < 0.05)." → run the Mode 2 block with this `<script here>`:

```python
from scipy import stats
a = [102, 98, 105, 101, 99, 103, 100, 104]
b = [92,  95,  91,  94,  93,  90,  96,  92]
t, p = stats.ttest_ind(a, b)
print(f"[arithmetic-eval] t={t:.3f}, p={p:.5f}")
```

→ `[arithmetic-eval] t=8.062, p=0.00001` — claim supported at p < 0.05.

### Example 3 — When NOT to mental-math

Bad: writing "1.2M users × $4 ARPU = $4.8M/mo" without running the math.
Good: run `1.2e6 * 4` through Mode 1, then write the verified number.

Running this skill costs ~one bash invocation. A wrong number in a fact-check or cost estimate costs much more. When in doubt, run it.
