Commit: 27b5e861

# Security Review — test/confine-tests-bats (final confirming pass)

**Scope:** `git diff a37733cc...HEAD` limited to `test/scripts/confine-tests.bats` and `docs/working/research-2026-11-10-confine-tests-bats.md`; `scripts/confine-tests.sh` (unchanged) read in full as context
**Date:** 2026-11-10
**Based on:** the brief's merged k=3 code-fact-check results at 27b5e861; threat model H1, H2, S1 as pasted from `docs/constraints.md` at a37733cc

## Trust Boundary Map

```
B1: test command words (cmd[@])      → script argv parsing, then exec form     → the child inside the primitive (bwrap / unshare / unshare+sh -c)
B2: primitive verdict (probe exit)   → detect_primitive / --no-loopback switch → the run profile chosen and the warning (or none) shown to the operator
B3: test-built PATH + env -i          → command -v / PATH lookup in the script  → which bwrap, unshare, ip, sh the script actually runs (stand-in vs real tool)
B4: ambient host PATH (one test)      → the real script in its default position → a real primitive, if the host has one
```

Input sources:

```
S1: test command words (TRICKY, -record, $RECORD) — code-constant in the tests, operator-shaped in real use
                                                   — UNTRUSTED toward the exec / sh -c sinks
S2: stand-in mode vars (STUB_BWRAP/UNSHARE/IP)    — code-constant per test — trusted (selects stand-in behaviour only)
S3: ambient PATH and host tools (B4 test only)    — deploy-time — trusted for availability; the test must not
                                                   depend on which verdict the host gives
S4: $PWD / $BATS_TEST_TMPDIR                       — request-time (bats) — trusted for path construction (bats-owned)
```

What enters from outside is the test command (S1), which the script must hand to the child as discrete argv on every run form; the tests replace the primitives (B3) so they can observe that hand-off and the refusals, and one test (B4) touches the host as it is. The diff's main trust assumption is that a stand-in is no more permissive than its tool, so a green cannot come from a call the real tool would refuse.

## Findings

Status vs the first pass (at 9d37c1ac): Finding 1 is a repeat, partially open (first-pass Finding 3's class, a sibling assertion); Finding 2 is a repeat escalation of first-pass Finding 1 (script, still open, not this diff's to fix); Finding 3 is new at this pass (coverage note); Finding 4 repeats first-pass Finding 5 (out of scope).

#### 1. The plain-fallback `--probe` test still pins D2's silence, and the doc says the absence is not pinned

**Severity:** Low
**Location:** `test/scripts/confine-tests.bats:349`, `docs/working/research-2026-11-10-confine-tests-bats.md:243`
**Boundary:** B2
**Move:** 5 (invert the model: what the test prevents)
**Evidence:**
> `  [ -z "$stderr" ]` (bats :349, in `--probe reports unshare when bwrap is not installed, or is installed and refused`)
>
> `The other reading: the script's contract is network denial, which unshare delivers, and the header comment documents the difference. No test pins the warning's absence.` (doc :243)
**Confidence:** High
**Legibility-target:** for-author

Pass 1 loosened the two run tests so a D2 fix (a warning when the script falls back to unshare's weaker profile, an H2 "name what went unenforced" question) would not break them. The `--probe` path was left exact: test 14 asserts an empty stderr for the plain unshare fallback, so a fix that warns at selection time (where the `--no-loopback` warning already lives, and where a `--probe` gate in CI would see it) turns the suite red, and a fix placed before the `ip` check also breaks test 15's `refused 3 "$NO_IP"`. The doc's line 174 (a 22nd copy warning on every unshare *run* passes) is true only for a run-time warning. The risk is an honest slip: the D2 fix author sees red, reads the doc's "not pinned", and backs the warning out or moves it to the run banner only, where `--probe` users never see it.

Command (scratch copy of the script and test under `secfinal/m2/`, warning inserted just before `if [[ "$probe_only" -eq 1 ]]`, guarded by `primitive == unshare && loopback == 1`), then `timeout 300 bats m2/test/scripts/confine-tests.bats`:
```
m2exit=1
not ok 14 --probe reports unshare when bwrap is not installed, or is installed and refused
#   `[ -z "$stderr" ]' failed
```
Same warning inserted before the `ip` check (`secfinal/m1/`):
```
m1exit=1
not ok 14 --probe reports unshare when bwrap is not installed, or is installed and refused
#   `[ -z "$stderr" ]' failed
not ok 15 unshare without ip is refused (exit 3), probe or run, and serves --no-loopback
#   `refused 3 "$NO_IP"' failed
```

**Recommendation:** Replace `[ -z "$stderr" ]` at :349 with a check neutral on D2 (for example that no stderr line is the `NO_PRIMITIVE` or `NO_IP` refusal), or keep it and change doc :243 and :174 to say the `--probe` silence is pinned on purpose and a D2 fix must update test 14 (and test 15 if it warns before the `ip` check).

#### 2. Escalation (script, not this diff): the `sh -c` body's `exec "$@"` runs a different program when `sh` is bash

**Severity:** Medium
**Location:** `scripts/confine-tests.sh:220-225`
**Boundary:** B1
**Move:** 2 (implicit sanitization assumption)
**Evidence:**
> `  exec unshare -rn -- sh -c '`
> `    if ! ip link set lo up; then`
> `      echo "confine-tests: failed to bring loopback up inside the namespace." >&2`
> `      exit 3`
> `    fi`
> `    exec "$@"' sh "${cmd[@]}"`
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Repeat of first-pass Finding 1, still open, and correctly out of this branch's scope (the brief forbids changing the script). Where `/bin/sh` is bash, `exec` parses a leading `-a NAME` as its own option: the test command `-a x CMD ...` runs `CMD` instead of `-a` and the run reports success, a false green on the line CLAUDE.md names as the reference pattern for decision 018. Confinement holds (whatever runs, runs inside the namespace). The research doc's D1 now describes this accurately, including that the second case exits 0. Minimal reproduction of the shell behaviour (scratch dir, this container: dash 0.5.12-2):
```
$ dash -c 'exec "$@"' sh -a x echo hi ; bash -c 'exec "$@"' sh -a x echo hi ; dash -c 'exec -- "$@"' sh echo hi
sh: 1: exec: -a: not found        (dash, rc=127: correct)
hi                                (bash, rc=0: ran echo, not -a)
sh: 1: exec: --: not found        (dash, rc=127: `exec --` is not a portable fix)
```
**Recommendation (follow-up, not this branch):** run the body with bash explicitly (`unshare -rn -- bash -c '... exec -- "$@"' bash "${cmd[@]}"`; the script already requires bash), or refuse a `cmd[0]` beginning with `-` with exit 2. Then add the unshare+loopback dash-named-command case the tests currently leave out.

#### 3. `same_process` and the mutation table hold only where `sh` is dash

**Severity:** Informational
**Location:** `test/scripts/confine-tests.bats:148-153`, `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Boundary:** B1
**Move:** 11 (bypasses of the guard)
**Evidence:**
> `# same_process: the test command ran as the process the script was. No step`
> `# between them forked: the script execs its primitive, and its sh body execs`
> `# the command. (A stand-in execs the command too; the real bwrap forks it.)`
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

New at this pass, converging with the fact-check's "mostly accurate" item. `TOOLS/sh` links to the host's `sh`; bash runs the last command of a `-c` string in place, so on a bash-as-`sh` host the "sh body `exec` removed" mutant survives `same_process`, while on that same host D1's behaviour is the live one. Not a security defect of the tests; the coverage claim in G10 and the mutation table is host-dependent and should say so. Recommendation: one sentence in the doc's mutation table, or link `TOOLS/sh` to dash explicitly when present.

#### 4. PATH-planted or hostile primitive (out of scope, constraints S1)

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:80-81`
**Boundary:** B3
**Move:** 5
**Evidence:**
> `  if command -v bwrap >/dev/null 2>&1 &&`
> `     bwrap --ro-bind / / --unshare-net -- true >/dev/null 2>&1; then`
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The script trusts whatever `bwrap`/`unshare` PATH yields, so a planted stand-in like this file's own would make a run "confined" with nothing confined. Reaching it needs a deliberately hostile same-uid author: out of scope (constraints S1). Repeat of first-pass Finding 5; listed once, not ranked.

## Prior-pass fixes, checked at HEAD

- Doc no longer calls D1 fail-closed: holds (doc :230, "The second is worse ... exits 0").
- Exact stderr match pinning the missing warning in run tests: holds for the two run tests (:321 and :382 are substring matches); the `--probe` sibling remains (Finding 1).
- `exec` vs plain call distinguishable: holds via `same_process` (:151-153, used at :285, :329, :388), with Finding 3's dash caveat.
- Ambient-PATH test time-bounded: holds (`timeout 60` at :211 and :217).
- Recorder `set -u`: holds (:56 for the child; :95 for the stand-ins).

## Untested bypass candidates

None for the stand-ins' strictness guard (`confine()`'s `unexpected` marker). Candidates enumerated and traced by reading: (a) a call with the mode unset or unknown falls through every `case` to the marker; (b) a bwrap run whose profile differs by one element or comes from a different `$PWD` fails `is` and is also cross-checked against the test-computed `WORK` (:63-65, :279); (c) an `unshare -rn -- CMD` call in a non-`ok` mode hits the `&& "$mode" == ok` guard and falls to the marker; (d) a real tool reached by PATH fallback: under `env -i` the PATH is only the stub dirs plus four symlinks, so `/usr/bin/unshare` is unreachable. (a)-(d) were exercised by the suite run and the two mutants above, not individually.

## Endorsement Claims

- **Claim:** Under `confine()`, the script can resolve no `bwrap`, `unshare` or `ip` other than the test's stand-ins.
  **Location:** `test/scripts/confine-tests.bats:47-52, 137-146`
  **Evidence:** executed
  **Verified:** read the PATH construction (`env -i PATH="$path"`, `$path` = named stub dirs + `$TOOLS` of four symlinks); `timeout 300 bats test/scripts/confine-tests.bats` exit 0, 17/17.
  **Not verified:** `#!/usr/bin/env bash` in the stand-ins resolving to a different bash on a host where `type -P bash` is itself a wrapper.
- **Claim:** The test file spawns none of `curl`, `wget`, `gh`, `claude`; the repo's lint agrees.
  **Location:** `test/scripts/confine-tests.bats`
  **Evidence:** executed
  **Verified:** `grep -nE '\b(curl|wget|gh|claude|nc|ssh)\b'` on the file: no matches; `timeout 120 scripts/hermeticity-lint --root .` rc=0, "143 test file(s) checked, no unstubbed network spawns."
  **Not verified:** a confined run (`scripts/confine-tests.sh` exits 3 here), which is the ground truth.
- **Claim:** Writes made by the tests, the stand-ins and the test command land under `$BATS_TEST_TMPDIR` (the injection canaries' `touch pwned` would land in `$WORK`).
  **Location:** `test/scripts/confine-tests.bats:40-67, 37-38`
  **Evidence:** read-static
  **Verified:** every write path is `$LOG`, `$TOOLS`, `$T/...` or the cwd `$WORK`; `HOME` and `TMPDIR` are `$T`.
  **Not verified:** the ambient test's status-0 branch on a host with a real `bwrap`/`unshare` (the probe's own behaviour there).
  **route: code-fact-check**
- **Claim:** The `confine()` helper itself follows decision 018: a static `bash -c` body with values as positional arguments.
  **Location:** `test/scripts/confine-tests.bats:143-144`
  **Evidence:** read-static
  **Verified:** body `'echo "$$" > "$1"; shift; exec "$@"'` with `_ "$LOG/script-pid" env -i ...` as argv; first exec'd word is `env`.
  **Not verified:** a `$SCRIPT` path containing `=`, which `env` would read as an assignment (would fail loudly, not run unconfined).

## Primitive sweep

Primitive: process exec / `sh -c` (the engaged primitive)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/confine-tests.sh:199-210` (exec bwrap ... -- cmd) | S1 | `--` before cmd | cleared — pinned by the dash-named bwrap test (:289-295) |
| `scripts/confine-tests.sh:220-225` (sh -c static body, `exec "$@"`) | S1 | static body; no `--` | Finding 2 (D1, script follow-up) |
| `scripts/confine-tests.sh:227` (exec unshare -rn -- cmd) | S1 | `--` before cmd | cleared — pinned at :367-371 |
| `test/scripts/confine-tests.bats:143` (bash -c helper) | S4, S1 | static body | cleared — Endorsement 4 |
| `test/scripts/confine-tests.bats:110` (stand-in bwrap `exec -- "$@"`) | S1 | `--`, bash only | cleared — stand-in runs under bash |
| `test/scripts/confine-tests.bats:119` (stand-in unshare `exec -- "$@"`) | S1 | `--`, bash only | cleared — same |
| `test/scripts/confine-tests.bats:211, 217` (ambient `timeout 60 ... $SCRIPT`) | S3 | timeout; status-3 branch asserts the child did not run | cleared — B4, probe only when a primitive exists |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `--probe` fallback test pins D2's silence; doc says not pinned (repeat, sibling of pass-1 #3) | Low | B2 | `test/scripts/confine-tests.bats:349` | High |
| 2 | Escalation: `exec "$@"` under bash-as-sh runs a different program (D1, repeat, script) | Medium | B1 | `scripts/confine-tests.sh:225` | High |
| 3 | `same_process` / mutation table hold only with dash as `sh` (new, coverage) | Informational | B1 | `test/scripts/confine-tests.bats:148-153` | Medium |
| 4 | PATH-planted primitive, out of scope (constraints S1) (repeat) | Informational | B3 | `scripts/confine-tests.sh:80-81` | High |

## Overall Assessment

The test file is sound as a security artefact: its stand-ins are strict, it cannot reach a real primitive except in the one deliberate real-position probe, it spawns no network tool, and its writes stay in the bats temp dir. Every first-pass fix holds at HEAD. One small item remains in the diff (Finding 1): the `--probe` sibling of the assertion pass 1 loosened still pins D2's silence while the doc says it does not; fix the assertion or the doc before merge. The script's D1 (Finding 2) is the most important security item, and it belongs to a follow-up on the script, not to this branch. No findings within the code paths read beyond these; the third endorsement claim is pending execution verification.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/security-review-final-2026-11-10-confine-tests-bats.md, structured per the security-reviewer skill.
- Answered: yes
- Out of scope: changes to `scripts/confine-tests.sh` (brief forbids; D1 reported as escalation); hostile-author bypasses (constraints S1); the other review reports under `docs/reviews/`; whole-suite run (forbidden by the rules)
- Escalate: D1 fix in `scripts/confine-tests.sh:220-225` as a follow-up (run the body under bash with `exec --`, or refuse a dash-leading `cmd[0]`); the D2 warning decision for the cycle
