Commit: 9d37c1ac

# Security Review — test/confine-tests-bats

**Scope:** `git diff a37733cc...HEAD` (`test/scripts/confine-tests.bats`, `docs/working/research-2026-11-10-confine-tests-bats.md`), with `scripts/confine-tests.sh` read in full as context (unchanged by the branch)
**Date:** 2026-11-10
**Based on:** `docs/reviews/code-fact-check-report-2026-11-10-confine-tests-bats.md` (Stage 1, k=1)
**Threat model:** docs/constraints.md at a37733cc, H1/H2/S1 as pasted in the brief. A deliberately hostile branch author or loop is out of scope (S1).

No HALT block: no escalation pattern matched.

## Trust Boundary Map

```
B1: [test command words, S1]        → [script flag loop, cmd=("$@")]           → [primitive argv: bwrap/unshare -- cmd] → [child argv]
B2: [primitive verdict, S2]         → [detect_primitive / --no-loopback switch] → [run confined | refuse exit 2/3]
B3: [sh identity on the host, S5]   → [static body `exec "$@"` (unshare+lo)]    → [which program runs inside the netns]
B4: [test-controlled words, S3] (new) → [stand-ins + recorder, NUL-delimited]   → [files under $BATS_TEST_TMPDIR]
B5: [ambient PATH, S4] (new)        → [the one real-position test]              → [real bwrap/unshare probes]
```

| Label | Source | Mutability | Trust classification |
|---|---|---|---|
| S1 | test command words passed after `--` | request-time (operator-shaped) | UNTRUSTED toward exec/shell-parse sinks (decision 018); trusted for nothing |
| S2 | exit status of the real (or stand-in) `bwrap`/`unshare`/`ip` probe | runtime (host/kernel) | trusted for the confinement verdict only when it fails closed; an exit 0 from the probe is not proof the run's profile works (O1) |
| S3 | the TRICKY word list, `$RECORD`, PROFILE (test constants) | code-constant | trusted for code paths; deliberately hostile toward the exec sinks they are fed to |
| S4 | the ambient PATH of whoever runs bats | deploy-time | trusted for availability; a PATH-planted primitive is a hostile-author case (out of scope, S1) |
| S5 | what `sh` resolves to (dash here, bash on many hosts) | deploy-time | trusted for availability; changes how the body parses S1 (Finding 1) |

S1 crosses into a static shell body and two `exec` forms in the script; S3 feeds generated stand-ins whose bodies are built from code constants and a quoted heredoc. The diff adds B4 and B5; B1-B3 are the script's own boundaries, which the tests pin from the outside.

## Findings

#### 1. The `exec "$@"` body runs a different program than the one named when `sh` is bash (D1 is not only a refusal)

**Severity:** Medium
**Location:** `scripts/confine-tests.sh:225` (escalation; script not changed by this branch) and `docs/working/research-2026-11-10-confine-tests-bats.md:185`
**Boundary:** B1, B3
**Move:** 2 (implicit sanitization assumption), 11 (bypass enumeration)
**Evidence:**
> `    exec "$@"' sh "${cmd[@]}"` (scripts/confine-tests.sh:225)
>
> `The same call with dash as `sh` exits 0 and the command receives `-x`. Severity is low (a test command is rarely named `-something`, and `./-something` avoids it), and it fails closed.` (research doc :185)
**Confidence:** High (mechanism); Low that a real command is ever named `-a`
**Legibility-target:** for-author

The research doc reports D1 as a refusal ("it fails closed"). That holds for `-r`/`-x`, but bash's `exec -a NAME CMD...` consumes the first two words and runs the third: the command line `-a x "$RECORD" one` exits 0 having run `$RECORD`, not `-a`. Words of the command are re-interpreted as options, which is the property decision 018 holds this line up as the reference for. Network confinement is unaffected (it still runs inside `unshare -rn`), so this is argv integrity, not egress. Reachable on any host where `sh` is bash and only the unshare path is usable.

Command (stand-ins from the test file, `sh` linked to bash, then dash):
```
confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- -a x "$RECORD" one
bash: status=0  child.1 argv: [one]
dash: status=127  sh: 6: exec: -a: not found
```
And without the script:
```
$ PATH="$D/pb:$PATH" bash -c 'exec "$@"' sh -a x echo one     # $D/pb/-a exists
one
$ PATH="$D/pb:$PATH" bash -c 'command -- "$@"' sh -a x echo one
ran -a: x echo one
```

**Recommendation:** In the doc, replace "it fails closed" with "a `-r`/`-x`-style name fails closed; `-a NAME CMD` under bash runs CMD instead". For the script follow-up, `command -- "$@"` (observed correct under both dash and bash, above) is one candidate; it gives up the `exec` (sh stays as parent), which the follow-up should weigh.

#### 2. A plain fallback to unshare runs the weaker profile with no warning (O2), contrary to H2's "names what went unenforced"

**Severity:** Medium
**Location:** `scripts/confine-tests.sh:178` (escalation; script not changed by this branch)
**Boundary:** B2
**Move:** 3 (error path), 5 (invert the model)
**Evidence:**
> `echo "confine-tests: denying network via $primitive (loopback=$loopback)" >&2`
**Confidence:** Medium (whether filesystem confinement is part of the script's contract is a judgement; the network guarantee holds)
**Legibility-target:** for-author

When bwrap is missing or refused, the script selects unshare and prints only the banner above. The script's own comment (lines 127-133) says the unshare profile has no read-only rootfs, no private `/tmp`, and uid 0 in a user namespace, "Say so, loudly, every time", but it says so only when `--no-loopback` forces the switch. A host without bwrap therefore degrades silently from the hardened profile to network-only. That is the H2 shape (a degraded primitive must name what went unenforced). The research doc records it as O2 and does not judge it; it should go to a follow-up as an H2 question, not stay an observation.

**Recommendation:** Follow-up on the script: print the same "NOTHING ELSE" warning whenever the unshare path runs, not only on the `--no-loopback` switch. Finding 3 is the test change that follow-up would need.

#### 3. A test pins O2's silence, while the doc says observations are not pinned

**Severity:** Low
**Location:** `test/scripts/confine-tests.bats:366`, `docs/working/research-2026-11-10-confine-tests-bats.md:168`
**Boundary:** B2
**Move:** 5
**Evidence:**
> `  [ "$stderr" = "confine-tests: denying network via unshare (loopback=1)" ]` (bats :366, in a run with only `unshare ip` stand-ins installed, :364)
>
> `- Observations O1 to O4 below: behaviour I did not judge clearly right, so it is not pinned.` (doc :168)
**Confidence:** High
**Legibility-target:** for-author

The exact-stderr assertion in the unshare-run test fails as soon as the script warns on the plain unshare fallback, so the test cements the behaviour Finding 2 questions, and the doc's claim that O2 is not pinned is wrong. Command: a scratch copy of the script with a warning added before the run banner, then `timeout 300 bats test/scripts/confine-tests.bats`:
```
O2fix exit=1 failing=1
not ok 16 an unshare run raises lo, then execs the command: a static sh body, every word a positional argument
#   `[ "$stderr" = "confine-tests: denying network via unshare (loopback=1)" ]' failed
```

**Recommendation:** Assert `[ "${stderr_lines[-1]}" = "confine-tests: denying network via unshare (loopback=1)" ]` (as the `--no-loopback` run test does at :308) so the test is neutral on O2, or keep the exact match and correct the doc to say O2 is pinned on purpose.

#### 4. Mutation survivors: none security-relevant; one converges with the fact-check

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:225`, `test/scripts/confine-tests.bats:362`
**Boundary:** B1
**Move:** 11
**Evidence:**
> `@test "an unshare run raises lo, then execs the command: a static sh body, every word a positional argument" {`
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Of 19 mutants of a scratch copy, three survived: `exec "$@"` → `"$@"` (same as the fact-check's finding on the test name), `set -euo pipefail` → `set -u`, and a hypothetical env-var bypass (`CONFINE_BYPASS`) that `env -i` hides by construction. None changes what is confined; the first is a naming accuracy point the fact-check already owns. Listed for convergence, not as a fix round.

#### 5. Out of scope (constraints S1)

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:80-81`
**Boundary:** B5
**Move:** 1
**Evidence:**
> `  if command -v bwrap >/dev/null 2>&1 &&`
> `     bwrap --ro-bind / / --unshare-net -- true >/dev/null 2>&1; then`
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

A PATH-planted `bwrap` that exits 0 and execs its tail would make the script run tests unconfined while reporting confinement. Reaching that needs a deliberately planted binary: out of scope (constraints S1). Not ranked.

## Untested bypass candidates

- **`--bind "$PWD" "$PWD"` with PWD `/` (or a parent of most of the tree)** (`scripts/confine-tests.sh:205`): binding `/` read-write after `--ro-bind / /` would undo the read-only rootfs, and possibly the `/tmp` tmpfs. Not tested: no bwrap here, and stand-ins cannot show mount semantics. Network denial would be unaffected. Worth one line in the sandbox's live run.
- **O1, probe-vs-run profile mismatch**: covered as fail-closed by the bats test at :284 against stand-ins; whether the real bwrap refuses or partially applies the larger profile is unverifiable here.

## Endorsement Claims

- **Claim:** With no usable primitive, the script refuses (exit 3) and the test command is not run; mutants that fall through to an unconfined `exec`, or let `--probe` print a verdict, are each failed by the suite.
  **Location:** `test/scripts/confine-tests.bats:172-193`
  **Evidence:** executed
  **Verified:** mutants M1 (fallback `exec "${cmd[@]}"` after `explain_unavailable`) and M9 (probe lies) on a scratch copy: 3 and 2 tests fail.
  **Not verified:** the real kernel refusal on a host where `unshare -rn` is permitted but bwrap is absent.
  **route: code-fact-check**
- **Claim:** A bwrap run-time failure produces no fallback: mutants that fall back to the unconfined command or to `unshare` after a failed bwrap run are each failed.
  **Location:** `test/scripts/confine-tests.bats:284-289`
  **Evidence:** executed
  **Verified:** mutants M2b, M2c (`|| exec "${cmd[@]}"`), M2d (`|| exec unshare -rn -- ...`): each fails tests 9/10.
  **Not verified:** the real bwrap's exit status when it refuses `--proc` in a nested sandbox.
  **route: code-fact-check**
- **Claim:** The run argv is pinned exactly: dropping `--unshare-net` from the bwrap profile, `-n` from the unshare+lo run, or `--` from the `--no-loopback` run is each failed.
  **Location:** `test/scripts/confine-tests.bats:261-274, 303-316, 362-387`
  **Evidence:** executed
  **Verified:** mutants M5, M15, M7: 3, 2 and 2 tests fail.
  **Not verified:** that the real bwrap accepts the pinned profile.
  **route: code-fact-check**
- **Claim:** The unshare+lo body is static: splicing the command into the body (`exec ${cmd[*]}`) is failed, and swallowing an `ip` failure (`|| true`, `exit 0`, unchecked) is failed.
  **Location:** `test/scripts/confine-tests.bats:362-395`
  **Evidence:** executed
  **Verified:** mutants M4, M3, M14, M16: each fails at least one test.
  **Not verified:** that `lo` is actually up inside a real namespace.
  **route: code-fact-check**
- **Claim:** The stand-ins, recorder and helpers build no shell string from test-controlled text: generated scripts are `printf '%s\n'` of code constants plus a quoted heredoc, calls are recorded NUL-delimited via `printf "%s\0" "$@"`, and the words reach `exec -- "$@"` as argv; every recorded write goes to `$STUB_LOG`, set to `$BATS_TEST_TMPDIR/log`.
  **Location:** `test/scripts/confine-tests.bats:33-37, 54, 91-128, 133-142`
  **Evidence:** read-static
  **Verified:** read every generated body and helper; the TRICKY words' `touch pwned` was checked absent in the work dir by the tests and by the suite's green runs here.
  **Not verified:** the `$RECORD` script has no `set -u`, so a future test that runs it without `STUB_LOG` would write `/child.N`; no current test does.
- **Claim:** The one ambient-PATH test reaches real primitives only through the script's own probes (`bwrap ... -- true`, `unshare -rn true`); on exit 0 it runs nothing further, and on exit 3 it runs the command only through the script, which re-detects and refuses.
  **Location:** `test/scripts/confine-tests.bats:195-211`
  **Evidence:** read-static (exit-3 branch executed here)
  **Verified:** read the test and script paths; suite run here took the exit-3 branch.
  **Not verified:** the exit-0 branch on a host where a primitive works.
- **Claim:** The research doc's "What a stub cannot show" is accurate about what the tests do not show (network denial, real bwrap profile acceptance, `lo` state, real `unshare` mapping).
  **Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:151-161`
  **Evidence:** read-static
  **Verified:** compared against the stand-in bodies, which create no namespace.
  **Not verified:** the doc's O2 "not pinned" line, which Finding 3 shows is wrong.

## Primitive sweep

Primitive: process exec / shell parse

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/confine-tests.sh:199-210` `exec bwrap ... -- "${cmd[@]}"` | S1 | argv + `--` | cleared — pinned exactly (M5) |
| `scripts/confine-tests.sh:220-225` `sh -c '<static>' sh "${cmd[@]}"` | S1 | static body, positional args | cleared for injection (M4); Finding 1 for `exec "$@"` |
| `scripts/confine-tests.sh:227` `exec unshare -rn -- "${cmd[@]}"` | S1 | argv + `--` | cleared — pinned (M7) |
| `scripts/confine-tests.sh:62` `awk ... "$0"` | code-constant | static program | cleared |
| `scripts/confine-tests.sh:80-86` probes | S4 | fixed argv | Finding 5 (out of scope) |
| `test/scripts/confine-tests.bats:107,116` stand-in `exec -- "$@"` | S3 | argv + `--` | cleared |
| `test/scripts/confine-tests.bats:139-140` `env -i ... "$SCRIPT" "$@"` | S3 | argv | cleared |
| `test/scripts/confine-tests.bats:199,205` ambient `"$SCRIPT"` | S3, S4 | argv | cleared (endorsement 6) |
| `test/scripts/confine-tests.bats:74` `xargs -0 printf ' %q'` | S3 (records) | NUL-delimited, `%q` | cleared |
| `test/scripts/confine-tests.bats:135,227,295` unquoted word-splits | S3 | code constants only | cleared |
| `test/scripts/confine-tests.bats:54,92` generated script bodies | S3 | constants + quoted heredoc | cleared |

Primitive: file write

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `test/scripts/confine-tests.bats:37` recorder `> "$STUB_LOG/$name.$n"` | S3 | `$STUB_LOG` = `$BATS_TEST_TMPDIR/log` | cleared (note in endorsement 5) |
| `test/scripts/confine-tests.bats:125` `>> "$STUB_LOG/unexpected"` | S3 | same, stub has `set -u` | cleared |
| `test/scripts/confine-tests.bats:42-58` setup writes | S3 | under `$BATS_TEST_TMPDIR` | cleared |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | `exec "$@"` under bash runs a different program for `-a NAME CMD`; doc says D1 fails closed | Medium | B1, B3 | `scripts/confine-tests.sh:225`, research doc :185 | High |
| 2 | Plain unshare fallback degrades silently (O2, H2) | Medium | B2 | `scripts/confine-tests.sh:178` | Medium |
| 3 | Test pins O2's silence; doc says it is not pinned | Low | B2 | `test/scripts/confine-tests.bats:366` | High |
| 4 | Mutation survivors (none security-relevant) | Informational | B1 | `test/scripts/confine-tests.bats:362` | High |
| 5 | PATH-planted primitive (out of scope, constraints S1) | Informational | B5 | `scripts/confine-tests.sh:80-81` | High |

## Overall Assessment

The branch adds no attack surface: the test file reaches no network, the only real primitives it touches are the script's own `true` probes in the one ambient test, and every write lands under `$BATS_TEST_TMPDIR`. The tests are strong where a security reader cares most: 16 of 19 security-shaped mutants (unconfined fallbacks, dropped `--unshare-net`/`-n`/`--`, spliced shell body, swallowed `ip` failure, lying probe) each fail at least one test. Both Medium findings are about the unchanged script and go to follow-ups. In this diff, Finding 3 (one assertion and one doc line) and the doc correction in Finding 1 can be fixed in place. Most important: decide O2 as an H2 question rather than leave it cemented by an exact-stderr match. No findings block the merge within the code paths read; endorsement claims are executed against stand-ins and pending a live confined run.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/security-review-2026-11-10-confine-tests-bats.md, structured per the security-reviewer skill.
- Answered: yes
- Out of scope: a PATH-planted primitive (hostile author, constraints S1); live confinement (no bwrap, unshare refused in this container)
- Escalate: script follow-ups for Finding 1 (`exec "$@"` option parsing under bash, candidate `command -- "$@"`) and Finding 2 (warn on every unshare run, an H2 question); one live-run check of `--bind "$PWD"` with PWD `/`
