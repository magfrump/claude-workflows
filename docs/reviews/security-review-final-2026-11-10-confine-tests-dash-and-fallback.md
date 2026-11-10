Commit: bd312d15

# Security Review — fix/confine-tests-dash-and-fallback (final confirming pass)

**Scope:** `git diff 23ffb16c..bd312d15` — `scripts/confine-tests.sh`, `test/scripts/confine-tests.bats`, `guides/test-hermeticity.md`, `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md`, `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md`
**Date:** 2026-11-10
**Based on:** code-fact-check-report-final-r1/-r2/-r3-2026-11-10-confine-tests-dash-and-fallback.md (as summarized in the final critic brief); threat model from `git show main:docs/constraints.md` (H1, H2, S1)

The script was read in full (lines 1-292 at bd312d15), and so was the test file (1-516). `timeout 300 bats test/scripts/confine-tests.bats` gave 21 of 21 ok. I also ran my own probes on scratch copies (see "Executed probes").

## Trust Boundary Map

```
B1: caller argv after `--` (test command words) → bash array cmd → `exec bwrap ... -- "${cmd[@]}"` / `exec unshare -rn -- "${cmd[@]}"` / `"$BASH" -c '<static body>' NAME "${cmd[@]}"` → `exec -- "$@"` in the body   (moved: the body's interpreter and its last line changed)
B2: caller environment (PATH, BASH_ENV, exported functions, BASHOPTS) → outer bash script → inner `"$BASH" -c` body inside the namespace   (new: at 23ffb16c the body ran under `sh`, which ignores BASH_ENV and BASH_FUNC_*)
B3: host state (is bwrap installed, does it work, does unshare work) → detect_primitive / fell_back / `command -v bwrap` → which primitive runs, and which warning goes to stderr   (new: the fallback warning, and the second `command -v bwrap` at run time)
B4: script stderr/stdout → a human or a wrapper/CI step that reads it → the decision "the suite passed confined"   (moved: on fallback, stderr's first line is now the WARNING and not the banner)
```

Input-source classification:

```
S1: test command words (argv after --)       — request-time  — UNTRUSTED toward exec/shell-parse sinks (operator-shaped text, repo rule; decision 018); trusted only as "what the caller wants run"
S2: caller environment (BASH_ENV, BASH_FUNC_*, PATH, BASHOPTS) — request-time, the caller's own — out of scope toward exec sinks when the caller poisons it (S1); an honest slip in it stays in scope
S3: host primitive availability (bwrap/unshare/ip on PATH and their probe exits) — deploy-time / host — trusted for selection; its *consequence* (weaker profile) has to reach S4's reader
S4: warning/headline/way-back strings passed to warn_unshare_only, and and_flag — code-constant — trusted (all sinks)
S5: $BASH                                      — set by bash at startup (an environment BASH is overridden; executed) — trusted for the exec sink
```

What enters from outside is the command (S1) and the caller's environment (S2). S1 now crosses into a shell body only as positional parameters of a static string, and B1's three run forms all put `--` before it. The diff's one new assumption is that it is acceptable for S2 to act inside the namespace body (B2). The author recorded and accepted that assumption, and it is out of scope under S1. B3/B4 carry the security-relevant message: the run went ahead on a weaker primitive.

## Findings

#### 1. The fallback runs with a degraded primitive, but H2 says it "refuses"; the branch writes the opposite rule into the reference script and paraphrases H2 without "refuses"

**Severity:** Medium
**Location:** `scripts/confine-tests.sh:29-35`, `scripts/confine-tests.sh:216-232`; `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:111` (C4) and the Observations section (:369)
**Boundary:** B3, B4
**Move:** 5 (invert the model: what does the fallback allow?), 3 (degraded path)
**Confidence:** Medium. The behaviour is executed and certain. What is uncertain is whether H2's "degraded primitive" is meant to cover the unshare tier, and that is the owner's call.
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
#   A weaker primitive is a warning, on every run. The script has two
#   primitives: bwrap, and `unshare`, which denies the network and nothing
...
#   falls back to unshare and goes ahead, and says first, on stderr, what
```
```
if [[ "$fell_back" -eq 1 ]]; then
```
(excerpt ends :216; the block runs to :230, and the banner and `exec unshare` follow at :232-292. Read.)
From `git show main:docs/constraints.md`, line 6:
```
H2: A gate or boundary fails closed and loudly: a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive refuses and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access.
```

On a host where bwrap is missing or unusable and `unshare -rn` works, the run goes ahead with a writable real root filesystem, the host's `/tmp` and no pid namespace. It exits with the suite's status, so a stray write by a test lands on the host and the run can still be green. This is FP-050's shape. Both halves of H2 cover this case. "Refuses and names" is only half met: the branch adds the naming. "Degradation only ever narrows access" is not met: relative to bwrap, the fallback widens filesystem access. The behaviour is pre-existing, and the brief rules out a refusal in so many words ("Out of scope: … a refusal in place of the fallback"). So for the code, the answer to the brief's question is: **the H2 paraphrase does not change what this branch's code must do. It does change what the branch's text may say.** The branch now writes "A weaker primitive is a warning, on every run" as the policy of the file that CLAUDE.md names as the reference pattern. The brief, commit 6465a156 and the research doc (C4 "fails closed, saying why (H2)"; Observations, which quotes H2 with "refuses" elided as "...") all paraphrase H2 as "names what went unenforced". A later unit seeded from these docs will read "warn" as H2-compliant. The diff strictly narrows the pre-existing gap (silent fallback becomes a loud one), so this is not a regression.

**Recommendation:** No code change on this branch. In the research doc, quote H2 verbatim where C4 and the Observations cite it, and state that the fallback still does not meet "refuses" or "only ever narrows access" as a known, pre-existing H2 gap the brief deferred. Route the decision to the cycle as one `you: judgment` question: refuse on fallback (perhaps with an explicit opt-in flag such as `--allow-unshare`), or record an H2 exception for the unshare tier in decision 017. The fallback `--probe`'s exit 0 belongs in the same question.

#### 2. The fixed way-back line for "bwrap installed but unusable" under `--no-loopback` is not pinned: a mutant that drops it passes every test

**Severity:** Informational
**Location:** `scripts/confine-tests.sh:221-224`; `test/scripts/confine-tests.bats:496-502` and `:395-401`
**Boundary:** B4
**Move:** 11 (bypass enumeration for "every route to unshare warns, with a true way back")
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```
  if command -v bwrap >/dev/null 2>&1; then
    warn_unshare_only "bwrap is installed but unusable here; falling back to the unshare primitive." \
      "Run where bwrap works" \
      "(a CI runner or a dev host)$and_flag to get the hardened profile."
```
(excerpt ends :224; the block runs to :230, the `else` for bwrap not installed. Read.)

The previous pass's finding 2 led to `and_flag`. That fix is right on both routes (executed: with `--no-loopback`, both way-back lines end "… and drop --no-loopback to get the hardened profile."). Only the not-installed route is pinned, by test 15's `stderr_lines[5]` assertion. Test 20 exercises the unusable route only with loopback on. I made a scratch mutant that removes `$and_flag` from line 224 only, and 21 of 21 tests still pass. The warning's security content (the "NOTHING ELSE" lines) is still printed on that route, so no property is violated. The gap is in the advice, which is the very thing the earlier finding was about.

**Recommendation:** In test 15 or 20, add one run with `STUB_BWRAP=refused STUB_UNSHARE=ok -- --no-loopback -- "$RECORD" one` and assert `stderr_lines[0]` = `$BWRAP_UNUSABLE_WARNING` and `stderr_lines[5]` = `  (a CI runner or a dev host) and drop --no-loopback to get the hardened profile.`

#### 3. The body under "$BASH" honours BASH_ENV and exported functions, including a function named `exec`

**Severity:** Informational — out of scope (constraints S1)
**Location:** `scripts/confine-tests.sh:284-290`
**Boundary:** B2
**Move:** 1 (trust boundaries), 2 (implicit sanitization)
**Confidence:** High (executed)
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
  exec unshare -rn -- "$BASH" -c '
```
(excerpt ends :285; the block runs to :291. Read.)

Executed on a scratch copy. `BASH_ENV=FILE` is sourced by the body inside the namespace, as well as by the outer script, the stand-ins and the child. `BASH_FUNC_ip%%` replaces `ip` in the body, so `lo` is "raised" by a function and the run continues. `BASH_FUNC_exec%%` replaces `exec` in **both** the outer script (line 285's own `exec unshare`) and the body. The outer-script exposure exists at 23ffb16c as well, so the only new reach is the body. Each case needs the caller to poison its own environment, which S1 puts out of scope. An honest `BASH_ENV` costs time, not confinement: the namespace is already in place when the body starts (pre-mortem narrative 3). I agree with the earlier pass's finding 1 and with the author's acceptance in DD-1.

**Recommendation:** None on this branch. If the pre-mortem's trigger fires, `"$BASH" -p -c` is the narrow fix there.

### Untested bypass candidates

Guardrail A: "every route that reaches unshare prints the unshare-only warning, with a true way back, before the run" (move 11). Every candidate was tested:
1. bwrap works, `--no-loopback`, unshare works: the `--no-loopback` warning, byte for byte (suite tests 11, 12, 20).
2. bwrap absent, loopback on: fallback warning, "Install bwrap" (test 20; executed).
3. bwrap refused, loopback on: "installed but unusable" (test 20).
4. bwrap absent with `--no-loopback`: fallback warning, "and drop --no-loopback" (test 15).
5. bwrap refused with `--no-loopback`: fallback warning with the and_flag. Executed and correct, but unpinned (finding 2).
6. stderr closed, or a closed pipe: the warning's `echo` fails under `set -e` and the script exits 1 or 141 **before** the run (executed). So the run cannot go ahead with the warning silently lost. `2>/dev/null` discards it by the caller's choice.
7. A fallback `--probe`: no warning, exit 0. That is by design and pinned (test 14). It belongs to finding 1's H2 question.
8. The way-back wording depends on a second `command -v bwrap` at run time (B3, a time-of-check to time-of-use gap against detection). A bwrap installed between the two calls changes only the headline's wording, never whether a warning prints, because `fell_back` was set at detection.

Guardrail B: "each word of the command reaches the child as its own argv element and nothing else runs in its place" (B1). Every candidate was tested: `-a x CMD one` gives 127 and CMD does not run, with sh as bash and as dash (tests 17, 18). A command named `--`, `-p` or `-a` gives 127 `exec: --: not found` (executed). `eval 'touch pwned'` runs the file `eval` (test 19). The TRICKY words (spaces, `$(...)`, backticks, `;`, a glob, a quote, a newline, an empty word) arrive unchanged and the body is identical across commands (test 16). `BASH=/nonexistent` in the environment is overridden by bash at startup (executed). A relative interpreter path (`./bash script`) works because the script never changes directory (executed).

Untested: under a real `unshare -rn` (none can be created in this container), whether `"$BASH"` is reachable and executable inside the namespace. The stand-ins exec the command themselves.

## Endorsement Claims

- **Claim:** On the unshare-with-loopback form, no word of the test command is spliced into text bash parses: the body passed to `-c` is byte-identical across two different commands, and the command arrives as positional parameters after `--`.
  **Location:** `scripts/confine-tests.sh:284-290`; `test/scripts/confine-tests.bats:409-438`
  **Evidence:** executed
  **Verified:** test 16 passed (21 of 21 run, `bats.txt` in scratch). I read the body: it is one single-quoted literal with no `$` expansion of `cmd`.
  **Not verified:** the same property under a real util-linux `unshare`, which the stand-in replaces. Its own argv handling after `--` is not exercised.
  **route: code-fact-check**

- **Claim:** A first word starting with `-` is never read as an option of `exec` in the body. `-a x CMD one` exits 127 and does not run CMD, whichever shell `sh` is.
  **Location:** `scripts/confine-tests.sh:290`; `test/scripts/confine-tests.bats:440-465`
  **Evidence:** executed
  **Verified:** tests 17 and 18 (sh as bash 5.2, sh as dash) pass. My probe showed `--` and `-p` as command names exit 127 with `exec: <name>: not found`.
  **Not verified:** bash versions other than the one installed here (5.2.15 per the fact-check), and whether every option bash's `exec` takes is ended by `--` there.
  **route: code-fact-check**

- **Claim:** At run time, every route that ends in `exec unshare` passes a call to `warn_unshare_only` first, and a failure to write the warning stops the script before the run.
  **Location:** `scripts/confine-tests.sh:142-232`
  **Evidence:** executed
  **Verified:** I traced every assignment of `primitive` (:142, :170). `fell_back` is set iff detection returned unshare (:149-152). The switch at :170 warns at :171, and in that case `fell_back` is 0, so nothing prints twice. Probe candidates 1-6 above.
  **Not verified:** a caller-exported `BASH_FUNC_echo%%` or `BASH_FUNC_cat%%` shadowing the commands inside `warn_unshare_only` (out of scope under S1, and not executed). The script's own definition at :131 should replace an imported function of the same name, but I did not execute that either.
  **route: code-fact-check**

- **Claim:** The test stand-ins for `bwrap`, `unshare` and `ip` accept only the exact argv shapes the script uses, and any other call fails the test.
  **Location:** `test/scripts/confine-tests.bats:110-165`
  **Evidence:** read-static
  **Verified:** I read `write_stub` and `confine()`. Every unmatched argv writes `$STUB_LOG/unexpected` and exits 99, and `confine` fails when that file exists. `sh` is absent from the built PATH.
  **Not verified:** that the stand-ins match real tool exit statuses for a command that cannot be executed. The stand-ins `exec -- "$@"` under bash, so 126 and 127 come from bash, not from unshare or bwrap.
  **route: code-fact-check**

## Primitive sweep

Primitive: process exec / shell `-c` body (command injection, option injection)

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/confine-tests.sh:71` `awk '…' "$0"` | S5-like (script path) | static program | cleared: no S1 input |
| `scripts/confine-tests.sh:90` `bwrap --ro-bind / / --unshare-net -- true` | S3 | constant argv | cleared |
| `scripts/confine-tests.sh:95` and `:169` `unshare -rn true` | S3 | constant argv | cleared |
| `scripts/confine-tests.sh:221` `command -v bwrap` | S3 | builtin, runs nothing | cleared (wording time-of-check to time-of-use gap only, candidate 8) |
| `scripts/confine-tests.sh:253-264` `exec bwrap … -- "${cmd[@]}"` | S1 | `--`, array expansion | cleared (tests 8, 9) |
| `scripts/confine-tests.sh:285-290` `exec unshare -rn -- "$BASH" -c '<static>' NAME "${cmd[@]}"`, body `exec -- "$@"` | S1, S2, S5 | static body, `--` at both levels | cleared for S1 (tests 16-19). S2 reach is finding 3 (out of scope) |
| body `ip link set lo up` | S2 (PATH/functions) | constant argv; failure gives exit 3 | cleared for S1. S2 is finding 3 |
| `scripts/confine-tests.sh:292` `exec unshare -rn -- "${cmd[@]}"` | S1 | `--` | cleared (tests 12, 15) |
| `scripts/confine-tests.sh:132`, `:138` `echo "… $1"`, `"… $2"` | S4 | code-constant arguments; each string starts with non-dash text, so it cannot be an echo option | cleared. No backslashes, so the `xpg_echo` setting via an inherited BASHOPTS does not matter |
| `scripts/confine-tests.sh:139` `printf '  %s\n' "${@:3}"` | S4 | constant format | cleared (every call site passes at least 3 arguments) |
| test harness `confine()` `bash -c 'echo "$$" > "$1"; shift; exec "$@"' _ …` (`.bats:162`) | test constants | static body | cleared. `$1` after `shift` is always `env`, which does not start with a dash |

## Executed probes

Scratch directory: `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-final-security/`
- `probe.sh`: a scratch copy of the script on a built PATH with permissive unshare/ip stand-ins. It tried `BASH=` override, `BASH_ENV`, `BASH_FUNC_exec%%`, `BASH_FUNC_ip%%`, command names `--` and `-p`, `./bash` invocation, stderr closed (exit 1, child not run) and stderr to a closed pipe (141, child not run).
- `mut.sh`: one mutant (`$and_flag` dropped from line 224). The repo's test file passed 21 of 21 against it (finding 2).
- `bats.txt`: the repo test file at bd312d15, 21 of 21 ok.

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Fallback proceeds on a degraded primitive against H2's "refuses" / "only narrows". The branch writes "a weaker primitive is a warning" as policy and paraphrases H2 without "refuses" | Medium | B3, B4 | `scripts/confine-tests.sh:29-35`, `:216-232`; research doc :111, :369 | Medium |
| 2 | Way-back with and_flag on the "installed but unusable" route is unpinned (mutant survives) | Informational | B4 | `scripts/confine-tests.sh:221-224`; `.bats:496-502` | High |
| 3 | Inner `"$BASH"` honours BASH_ENV / exported functions (out of scope, constraints S1) | Informational | B2 | `scripts/confine-tests.sh:284-290` | High |

## Earlier pass (de1f4bf9), fixes checked

- Its finding 1 (BASH_ENV / exported functions), no change: I agree. It is re-confirmed here as finding 3, including an exported `exec` that also reaches the outer script.
- Its finding 2 (way back false under `--no-loopback`), fixed with `and_flag`: the fix is right on both routes (executed). The pin covers only the not-installed route (finding 2 here).
- Its finding 3 (fallback probe, H2), Informational, no change: I would rate the underlying H2 gap Medium by the floor rule. It names a concrete mechanism in a reachable environment: a write to the host filesystem that exits green. I would also widen it from the probe to the run. Still no code change on this branch (finding 1 here).

## Overall Assessment

The D1 fix is the right shape for decision 018's reference pattern. The body is a static literal under the interpreter already running the script. `--` ends exec's options at every level, and a command's words reach the child only as positional parameters. The tests and my probes found no S1 route to option injection, to shell parsing, or to a builtin running in the named file's place. The D2 warning reaches every run that ends in unshare, and it cannot be skipped while the run proceeds. The two warnings share one source of text. The issues are fixable in place and none of them blocks the merge. The single most important item is finding 1. It needs no code change on this branch. What it does need is for the research doc's H2 citations to be corrected to quote "refuses", and for the refuse-or-warn decision on the unshare fallback to go to the owner, so that "a weaker primitive is a warning" is not read later as H2-compliant. Finding 2 is a one-assertion test addition. No findings within the code paths read rise above Medium. The endorsement claims are pending execution verification (routed to code-fact-check), and nothing ran under a real bwrap or unshare.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/security-review-final-2026-11-10-confine-tests-dash-and-fallback.md, structured per the security-reviewer skill, with a first line `Commit: bd312d15`.
- Answered: yes
- Out of scope: caller-poisoned environment (BASH_ENV, BASH_FUNC_*), per constraints S1, reported once as Informational. The exit-status contract changes, which were escalated to api-consistency, not security.
- Escalate: finding 1. The owner should get one `you: judgment` question on H2 and the unshare fallback (refuse with an opt-in flag, or a recorded exception in decision 017), plus a doc-text correction to the research doc's H2 citations.
- Decisions I made: I rated the pre-existing H2 gap Medium (the floor rule) while recommending no code change on this branch, because the brief puts refusal out of scope and the diff narrows the gap.
