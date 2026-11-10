Commit: de1f4bf9

# Security Review — fix/confine-tests-dash-and-fallback

**Scope:** 23ffb16c..de1f4bf9 (`scripts/confine-tests.sh`, `test/scripts/confine-tests.bats`, `guides/test-hermeticity.md`, `docs/reviews/pre-mortem-…`, `docs/working/research-…`)
**Date:** 2026-11-10
**Based on:** `docs/reviews/code-fact-check-report-2026-11-10-confine-tests-dash-and-fallback.md` (stage 1, one replicate); threat model from `git show main:docs/constraints.md` (S1, H1, H2)

Executed for this review (scratch dir `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-i1-security`):
- `timeout 300 bats test/scripts/confine-tests.bats` in the worktree: 21/21 ok, exit 0.
- `p1.sh`: `env BASH=/nonexistent bash -c 'echo "$BASH"'` prints `/usr/bin/bash` (bash resets `BASH` at startup); `BASH_ENV=FILE bash -c 'exec -- "$@"' confine-tests true` sources FILE; an exported function named `exec` is called in place of the builtin by `bash -c 'exec -- "$@"'`; an exported function named `ip` answers the body's `ip link set lo up`.
- A scratch copy of the test file with one added test: `--no-loopback -- CMD` with bwrap refused and unshare ok exits 0 and prints the "bwrap was refused here" warning ending "Run where bwrap works … to get the hardened profile", then `denying network via unshare (loopback=0)`.

## Trust Boundary Map

```
B1: [caller's test command argv]     → [unshare -rn -- "$BASH" -c STATIC_BODY confine-tests "${cmd[@]}"; body `exec -- "$@"`] → [execve of the named file inside the netns]
B2: [caller's environment (BASH_ENV, BASH_FUNC_*, PATH)] → [startup of the inner "$BASH" (new: replaces `sh`)] → [body logic: `ip link set lo up`, `exec`]
B3: [host primitive availability (bwrap/unshare probes)] → [detect_primitive, fell_back, --no-loopback switch]   → [profile chosen + which warning is printed]
B4: [script stderr (warning, banner)] → [operator / build loop reading the run's output]  → [belief about what was confined]
```

B1 is modified (interpreter and last line), B2 is new in its inner-shell half (the outer script already ran under bash), B3 and B4 are modified (new fallback warning route).

| Label | Source | Mutability | Trust per sink class |
|---|---|---|---|
| S1 | test command words after `--` | request-time (caller) | UNTRUSTED toward exec-interpretation sinks (must stay one argv element each, never parsed or read as options); honest slips (a `-`-leading name, a builtin-named file) in scope |
| S2 | caller environment: `BASH_ENV`, exported functions, `PATH` | request-time (caller-owned) | caller's own; a poisoned environment is out of scope (constraints S1). Honest values (e.g. a CI-set `BASH_ENV`) in scope for availability/behaviour |
| S3 | `$BASH` | set by bash at startup (executed: env cannot override it) | trusted toward the exec sink: it is the interpreter already running the script |
| S4 | warning headline and way-back strings passed to `warn_unshare_only` | code-constant | trusted (all sinks); printed with `echo "...$1"` and `printf '  %s\n'`, never as a format string |
| S5 | bwrap / unshare probe results, `command -v bwrap` | deploy-time (host) | trusted for selection and headline wording |

The diff hands caller text (S1) to a subprocess only as positional arguments behind a static body, and adds one new place where the caller's environment (S2) is read (the inner bash's startup). The warning function takes only code constants (S4).

## Findings

#### 1. The inner "$BASH" reads BASH_ENV and imports exported functions (`ip`, `exec`) that dash-as-sh ignored

**Severity:** Informational — out of scope (constraints S1)
**Location:** `scripts/confine-tests.sh:268-273`
**Boundary:** B2
**Move:** 1 (trust boundaries), 2 (implicit sanitization assumption)
**Confidence:** High (executed, p1.sh)
**Legibility-target:** for-author

**Evidence:**
```
  exec unshare -rn -- "$BASH" -c '
    if ! ip link set lo up; then
```
```
    exec -- "$@"' confine-tests "${cmd[@]}"
```

Executed: an exported function `ip` returning 0 makes the body report success without raising `lo`; an exported function `exec` replaces the final exec; `BASH_ENV` is sourced inside the namespace before the body. Where `sh` was dash, none of these reached the body. Only a caller who poisons its own environment reaches the `ip`/`exec` cases, which S1 puts out of scope, and the outer script (bash, `exec unshare …` at :268, `exec bwrap` at :240, `command -v ip` at :184) is already exposed to the same exported functions, so nothing new is reachable. The honest case, a CI-set `BASH_ENV` (some CI systems set one per step), is sourced inside the netns as uid 0 in the user namespace; its network calls are denied, so it costs time (pre-mortem narrative 3) and violates no confinement property. The author recorded and accepted this in the research doc's DD-1 "Stress-test mitigations"; I agree with that acceptance under S1.

**Recommendation:** No change required. If the revisit trigger in the pre-mortem fires, `"$BASH" -p -c` (skips `BASH_ENV` and function import) is the one-token fix; it does not change uid handling here because the script is not setuid.

#### 2. `--no-loopback` with bwrap refused prints a way-back line that is false while the flag stays

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:208-212`
**Boundary:** B3, B4
**Move:** 3 (error path), 11 (guardrail bypass enumeration, applied to "every route to unshare warns")
**Confidence:** High (executed, scratch test)
**Legibility-target:** for-author

**Evidence:**
```
if [[ "$fell_back" -eq 1 ]]; then
  if command -v bwrap >/dev/null 2>&1; then
    warn_unshare_only "bwrap was refused here; falling back to the unshare primitive." \
      "Run where bwrap works (a CI runner or a dev host) to get the hardened" \
      "profile."
```
(excerpt ends :212; the block runs to :217, the `else` branch for bwrap not installed — read.)

On this route the four "NOTHING ELSE" lines are printed correctly, so H2's "names what went unenforced" is met and no route reaches unshare silently. Only the way forward is incomplete: where bwrap works, `--no-loopback` still forces unshare (:163-168), so following the advice with the flag kept yields the same weak profile, now under the `--no-loopback` headline. The same holds for the "Install bwrap" line under `--no-loopback` (pinned by test 15, which asserts only that "Drop the flag" is absent). Not a security property violation; a reader acting on it is misled about how to regain the hardened profile.

**Recommendation:** When `loopback -eq 0` on the fallback route, append "and drop --no-loopback" to the way-back line (one more argument to `warn_unshare_only`), or leave it and note it in the research doc's observations.

#### 3. Fallback --probe exits 0 without naming what is unenforced (H2 reading, pre-existing, brief-mandated)

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:190-194`
**Boundary:** B3, B4
**Move:** 5 (invert the model: what does a green probe not tell its gate?)
**Confidence:** Medium (the H2 reading is the orchestrator's/owner's call)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
if [[ "$probe_only" -eq 1 ]]; then
  echo "confine-tests: primitive available: $primitive (loopback=$loopback)"
  echo "  network denial is kernel-enforced and inherited by every child process."
  exit 0
fi
```

H2 on main reads "a … degraded primitive refuses and names what went unenforced". On the fallback the run now names it (this diff); the probe still exits 0 naming only the primitive, while `--no-loopback --probe` prints the full warning. The probe's claim (network denial) is true under unshare, so no stated security property is violated, and the brief forbids changing `--probe`. The author recorded the asymmetry (research doc DD-2) and pre-mortem narrative 1 traces the realistic consequence (four uid-0 skips under a "passes confined" record). Listed so the synthesis sees the H2 question once, not as an author fix.

**Recommendation:** None in this branch. Whether H2's "degraded primitive refuses" covers the unshare fallback (and the fallback probe) is a question for the cycle, alongside the pre-mortem's "worth mitigating" item.

### Untested bypass candidates

Guardrail: "every route that reaches unshare at run time prints the unshare-only warning" (move 11). Candidates enumerated:
1. bwrap works, `--no-loopback`, unshare works → `--no-loopback` warning (tested: suite test 11/12).
2. bwrap not installed / refused, loopback=1 → fallback warning (tested: suite test 20).
3. bwrap refused, `--no-loopback` → fallback warning (tested: scratch run above; Finding 2).
4. bwrap not installed, `--no-loopback` → fallback warning (tested: suite test 15).
5. bwrap probe succeeds but the bwrap run fails → no fallback, run fails (tested: suite test 10).
6. stderr closed (`2>&-`) on a fallback run → the warning's `echo` fails under `set -e` and the run does not start. Untested by execution; read-static only. Same outcome as the pre-existing banner `echo` at :219, so no new behaviour.

Guardrail: "the body runs the named file, never an option or builtin" (B1). Candidates: `-a x CMD`, `-record -x`, `eval 'touch pwned'` (all tested by suite tests 17-19; fact-check confirmed mutants `"$@"` and `command -- "$@"` fail the eval test); an exported function named like the command (untested by execution through the script; `exec` bypasses functions for its argument, and the `exec`-named function case is Finding 1, out of scope); a command word `""` (read-static: `exec -- ""` → 127, same as the bwrap form's failure; not executed).

## Endorsement Claims

- **Claim:** On the unshare-with-loopback run form, the body passed to `"$BASH" -c` is the same byte string for two different commands, and each command word arrives at the child as its own argv element, including words starting `-`, empty words, quotes, newlines and substitutions.
  **Location:** `scripts/confine-tests.sh:267-274`; `test/scripts/confine-tests.bats:727-763`
  **Evidence:** executed
  **Verified:** suite test 16 passes at de1f4bf9 (body compared across two commands; child argv compared to TRICKY; no `pwned` file); tests 17-19 pass.
  **Not verified:** a real `unshare -rn` exec'ing `"$BASH"` inside a real user+net namespace (no namespace can be created in this container; fact-check marked it Unverifiable).
  **route: code-fact-check**

- **Claim:** `$BASH` cannot be set from the caller's environment: bash resets it at startup.
  **Location:** `scripts/confine-tests.sh:268`
  **Evidence:** executed
  **Verified:** `env BASH=/nonexistent bash -c 'echo "$BASH"'` printed `/usr/bin/bash` (bash 5.2 in this container).
  **Not verified:** other bash builds/versions on CI hosts; invocation through a non-bash interpreter (e.g. `zsh scripts/confine-tests.sh`), where `$BASH` is unset and `set -u` would stop the run at :268 after the banner.
  **route: code-fact-check**

- **Claim:** `warn_unshare_only` interpolates its arguments as data: the headline via `echo "…$1"`, the rest via `printf '  %s\n' "${@:2}"`, and the shared text from a quoted heredoc; all three call sites pass string literals.
  **Location:** `scripts/confine-tests.sh:126-135, 166-168, 210-215`
  **Evidence:** read-static
  **Verified:** read the function and its three call sites in full.
  **Not verified:** a future call site passing non-literal text (none exists in this diff).

## Primitive sweep

Primitive: process exec (in diff scope).

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/confine-tests.sh:69` `awk … "$0"` | script path | fixed program text | cleared — unchanged, no caller text |
| `scripts/confine-tests.sh:88` bwrap probe | S5 | fixed argv | cleared — unchanged |
| `scripts/confine-tests.sh:93`, `:164` unshare probes | S5 | fixed argv | cleared — unchanged |
| `scripts/confine-tests.sh:240-251` `exec bwrap … -- "${cmd[@]}"` | S1 | `--` before command | cleared — unchanged, pinned by tests 8-9 |
| `scripts/confine-tests.sh:268` `exec unshare -rn -- "$BASH" -c BODY` | S3, S2 | static body, `$BASH` not env-settable | Finding 1 (S2 at the inner bash's startup, out of scope) |
| `scripts/confine-tests.sh:269` body `ip link set lo up` | S2 (PATH, exported fn) | failure exits 3 | Finding 1 (exported `ip`, out of scope); cleared otherwise |
| `scripts/confine-tests.sh:273` body `exec -- "$@"` | S1 | `--`, positional args | cleared — tests 16-19; endorsement 1 routed |
| `scripts/confine-tests.sh:275` `exec unshare -rn -- "${cmd[@]}"` | S1 | `--` | cleared — unchanged, pinned by test 12 |
| `test/scripts/confine-tests.bats:151` `bash -c '…; exec "$@"' _ … env -i …` | test constants | first word is `env` | cleared — test harness, no `-`-leading first word |
| `test/scripts/confine-tests.bats:115, :124` stand-in `exec -- "$@"` | S1 (test-supplied) | exact-argv match first | cleared — stand-ins accept only the script's argv shapes; unshare's run case accepts any command after `-rn --`, as the real tool does |

Stand-in strictness: the new tests add no stand-in; they add the real bash/dash under the name `sh` (tests 17-18) and real recording files `-record` and `eval`. The `ip` stand-in still accepts only `link set lo up`. No stand-in became looser in this diff.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Inner "$BASH" reads BASH_ENV / exported `ip`, `exec` | Informational (out of scope, constraints S1) | B2 | `scripts/confine-tests.sh:268-273` | High |
| 2 | `--no-loopback` + bwrap refused: way-back line false while flag kept | Informational | B3, B4 | `scripts/confine-tests.sh:208-212` | High |
| 3 | Fallback `--probe` exits 0 without naming what is unenforced (H2 reading) | Informational | B3, B4 | `scripts/confine-tests.sh:190-194` | Medium |

## Overall Assessment

The change narrows exposure: the D1 fix moves the reference line to the full decision-018 pattern (static body, positional arguments, `--` before the command) under a known interpreter, and the D2 fix closes the one route that reached the weaker profile silently. The new environment exposure of the inner bash is reachable only through a caller-poisoned environment (out of scope under S1) and duplicates what the outer bash script already has. No HALT pattern matched; no finding is Low or above. No findings within the code paths read; endorsement claims pending execution verification (the first two are routed to code-fact-check, and none of them covers a real namespace run).

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/security-review-2026-11-10-confine-tests-dash-and-fallback.md, structured per the security-reviewer skill, with a first line `Commit: de1f4bf9`.
- Answered: yes
- Out of scope: hostile-environment cases (exported `ip`/`exec` functions), under constraints S1; changing `--probe`, which the brief forbids.
- Escalate: Finding 3, the H2 reading of the fallback probe, is a question for the cycle, not a fix for this branch.
