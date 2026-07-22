# 019 — arithmetic-eval: AST evaluator + tiered runtime sandbox; static gate is a speed-bump

Status: Accepted
Date: 2026-07-21
Class: Untrusted-input evaluation — command injection (CWE-78), code execution via
deserialization/reflection (CWE-502/CWE-470), SSRF/exfiltration (CWE-918), DoS (CWE-400)

## Context

`skills/arithmetic-eval/SKILL.md` tells Claude to evaluate math via `python3`. Its
inputs are routinely **attacker-influenceable** — a number inside a document being
fact-checked, a user claim, code under review. The original skill had two defenses,
both structurally unsound:

- **Mode 1** interpolated the expression into a shell `EXPR='...'` assignment that
  the shell parsed *before* a regex validated it — a single quote broke out to RCE
  (the same class as decision [[018]]), and the "clean" result still printed.
- **Mode 2** relied on an eyeball denylist of substrings, which missed `pathlib`
  writes, `pandas.read_pickle` (pickle RCE), `sympify`, `getattr` obfuscation,
  and disclosed local files via read-mode `open()`.

A six-round adversarial review-fix loop drove the redesign and repeatedly proved
the core lesson below (one round executed real RCE via `operator.attrgetter`;
another via `sys.modules['importlib']`).

## Decision

**Mode 1 is a sound boundary; the Mode 2 static gate is a speed-bump; the OS
sandbox is Mode 2's actual boundary.**

1. **No untrusted text in shell/Python source.** Expressions/scripts reach the
   interpreter as *data* via a quoted heredoc (`<<'EOF'`), never interpolated.
   (Consistent with decision [[018]].)
2. **Mode 1 = AST allowlist.** Parse with `ast.parse(mode="eval")`, walk a numeric
   node/operator allowlist, compute via `operator`. No `eval`, no names, no calls —
   it can only produce a number. Guards: exponent cap, result bit-length cap
   (bounds nested powers *and* repeated multiplication), reject non-finite (inf/nan)
   and complex results (they are not verified real numbers), catch RecursionError.
3. **Mode 2 static gate targets code-execution surfaces only.** `check.py` enforces
   an import allowlist and rejects reflection/deserialization/eval sinks. It does
   **not** try to police filesystem writes, network, or process exec by name —
   a denylist over Python-with-scientific-modules cannot be made sound, and
   name-matching false-rejects benign code (`df.system` column, `.rename`, URL
   strings). Those operations are contained at **runtime** instead.
4. **Runtime is the boundary — tiered by what the host supports.** Each Mode 2
   script is written to a throwaway `mktemp -d`, gated, then run under the
   strongest available sandbox:
   - `bwrap`: read-only rootfs, private tmpfs, `--unshare-all` (no network),
     cleared env, helper dir bound read-only. (Probed with the real mount set so a
     present-but-broken userns degrades instead of failing.)
   - unprivileged `unshare -rn` (kernel net namespace) + `confine.py`.
   - resource-limits-only fallback + `confine.py`, with a **loud warning**.
   `confine.py` neuters, at the Python level, network egress, filesystem writes
   outside scratch, and process execution (`os.*`/`subprocess.*`).
5. **Self-contained invocations.** Claude Code does not persist shell state across
   Bash calls, so every block writes what it needs and runs it in one shot — no
   "setup once, reference `$AE_DIR` later" step (which silently broke every call
   after setup), and a fresh `mktemp -d` per run means a poisoned helper cannot
   carry into the next invocation.

## Consequences

- **Residual risk is documented, not hidden.** The static gate is not sound; a
  reflection path through an approved module can reach dangerous code. The OS
  sandbox contains it — except on the resource-limits-only fallback tier, where
  `confine.py` is best-effort and untrusted-influenced scripts should not be run
  (the runner says so on stderr). Even under `bwrap`, an approved module can read
  files on the read-only rootfs and print them: egress is blocked, but
  disclosure-to-transcript is not.
- **Mode 2 verifies numbers; it does not deliver files.** The sandbox has no
  writable access to the working directory, so `savefig`/`to_csv` to a real path is
  blocked or lands in ephemeral scratch. Results come via stdout (`[arithmetic-eval]`).
- **Static minimalism is deliberate.** `sys`/`os`/`subprocess`/`importlib` are
  unapproved (each defeats the import gate by reflection); process-exec *method
  names* are not denylisted (they collide with data columns) because runtime
  covers them. This split keeps false-rejections low without weakening containment.
- **Tests.** `test/skills/arithmetic-eval-format.bats` validates the SKILL.md
  structure against this design (AST evaluator, mktemp/`check.py`, runtime
  containment) rather than the old regex/fixed-`/tmp` shape.

## References

- Decision [[018]] — pass untrusted data through argv, never a re-parsed shell
  string (the Mode 1 injection was an instance of this class).
- `skills/arithmetic-eval/SKILL.md` — the hardened skill.
- `test/skills/arithmetic-eval-format.bats` — structure validation.
