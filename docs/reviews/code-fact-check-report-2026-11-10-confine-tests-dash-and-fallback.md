Commit: de1f4bf9

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback (branch fix/confine-tests-dash-and-fallback)
**Scope:** branch diff 23ffb16c..de1f4bf9: scripts/confine-tests.sh, test/scripts/confine-tests.bats, guides/test-hermeticity.md, docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md, docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md, and the seven commit messages (`git log 23ffb16c..de1f4bf9`)
**Checked:** 2026-11-10
**Commit:** de1f4bf9
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 53
**Summary:** 45 verified, 6 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`) read first; no claim below matches a logged pattern. The one Incorrect (Claim 33b) is a mis-attributed citation, not a fabricated symbol, and the log was not edited (this pass may write only this report).

## Execution provenance

All runs from the scratch directory `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-i1-factcheck` (written `$X` below; every log is a file under it). Bash 5.2.15, dash 0.5.12 (`/usr/bin/sh -> dash`), Bats 1.8.2. Timestamps UTC, 2026-11-10. No experiment edited the worktree; scripts were copied into `$X`.

| Log | Command | cwd | Exit | Time |
|---|---|---|---|---|
| `$X/shells.out` | `bash $X/shells.sh $X` (bash, bash linked as `sh`, dash; `exec "$@"` vs `exec -- "$@"`) | `$X/sh-probe` | 0 | ~21:59Z |
| `$X/bats-head.out` | `timeout 300 bats test/scripts/confine-tests.bats` | worktree | 0 (21/21 ok) | 22:01:11Z |
| `$X/bats-<commit>.out` | `bash $X/atcommit.sh $X d03a3078 bd657ce8 6465a156 7ecf6ee3 ca6cf3be` (each commit's script + test file copied to `$X/at-<commit>`, then bats) | `$X/at-<commit>` | 1, 1, 0, 0, 0 | ~22:01Z |
| `$X/mut.out` | `timeout 580 python3 -I $X/mutate.py <worktree> $X/mut` (copy of the author's mutate.py, unmodified) | `$X` | 0 | started 22:02:05Z |
| `$X/m16-at-7ecf6ee3.out` | `bash $X/m16old.sh $X` (mutant m16 against the test file at 7ecf6ee3) | `$X/m16-at-7ecf6ee3` | 0 (mutant survives) | ~22:04Z |
| `$X/compare.out` | `timeout 300 bash $X/compare.sh $X` (old script at 23ffb16c vs new, 11 stand-in configurations x 12 argument sets x sh in {dash, bash}, stand-in copied from the test file's `write_stub`) | `$X/cmp/work` | 0 | ~22:03Z |
| `$X/bw.out` | `timeout 60 bats t.bats` (bats BW01 on an unexpected 127) | `$X/bw` | 1 (test c fails by design) | ~22:04Z |
| `$X/probes/probe1.out`, `$X/probes/probe2.out` | `timeout 120 bash $X/probes/probe1.sh`, `... probe2.sh` (copies of the author's probes) | `$X/probes` | 0, 0 | ~22:05Z |
| (inline) | `bash $X/bashenv.sh $X` (BASH_ENV under bash -c, bash-as-sh -c, dash -c) | `$X/be` | 1 (zsh tail error after output) | ~22:05Z |
| (inline) | `timeout 60 scripts/confine-tests.sh --probe` | worktree | 3 | ~22:06Z |

---

## Claim 1: "A weaker primitive is a warning, on every run ... When bwrap is not installed or is refused, the run falls back to unshare and goes ahead, and says first, on stderr, what that leaves unconfined."

**Location:** `scripts/confine-tests.sh:29-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every route that runs under unshare in the stand-in matrix (bwrap missing, bwrap refused, --no-loopback over a working bwrap, each with and without --no-loopback); does not establish behaviour under a real unshare.
**Legibility-target:** for-orchestrator-synthesis

The only two ways `primitive` becomes `unshare` are detection (`fell_back=1`, `scripts/confine-tests.sh:144-147`) and the --no-loopback switch (`:163-168`, which calls `warn_unshare_only`). The fallback block runs before the banner:

```bash
# scripts/confine-tests.sh:208-219
if [[ "$fell_back" -eq 1 ]]; then
  if command -v bwrap >/dev/null 2>&1; then
    warn_unshare_only "bwrap was refused here; ..."
  ...
fi
echo "confine-tests: denying network via $primitive (loopback=$loopback)" >&2
```

In `$X/compare.out` every new-script run that reached unshare printed a `confine-tests: WARNING —` headline as stderr line 1, followed by the banner, and then ran the command.

**Evidence:** `scripts/confine-tests.sh:142-219`; `$X/compare.out`

---

## Claim 2: "A --probe that falls back prints its verdict, which names the primitive, and not this warning."

**Location:** `scripts/confine-tests.sh:34-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `--probe` and `--no-loopback --probe` with bwrap missing or refused; does not cover `--no-loopback --probe` with bwrap usable, which is not a fallback and still prints the flag's warning (see Claim 3).
**Legibility-target:** for-orchestrator-synthesis

`--probe` exits at `scripts/confine-tests.sh:190-194`, before the fallback block at `:208`. In `$X/compare.out` all fallback probe cases are `SAME` between old and new (stdout `confine-tests: primitive available: unshare (loopback=N)`, empty stderr). Test 14 pins `[ -z "$stderr" ]` (`test/scripts/confine-tests.bats:363,368`).

**Evidence:** `scripts/confine-tests.sh:190-194,208`; `test/scripts/confine-tests.bats:357-370`; `$X/compare.out`

---

## Claim 3: "The script says so, in the fallback warning's words, on a run and on a --probe, and refuses outright when unshare is unusable."

**Location:** `scripts/confine-tests.sh:45-46`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the --no-loopback routes with bwrap usable (warns on run and probe; exit 2 when unshare is refused) and with bwrap missing or refused; does not establish anything under a real kernel.
**Legibility-target:** for-author

True where the paragraph's premise holds (bwrap usable, so the flag "forces" unshare): the warning is printed at selection (`scripts/confine-tests.sh:163-168`), before `--probe` answers, and `bwrap ok, unshare refused` exits 2 (`:169-175`). It does not hold on the other --no-loopback route: with bwrap missing or refused, `--no-loopback --probe` prints only its verdict with empty stderr (pinned by `test/scripts/confine-tests.bats:381-384`: `[ -z "$stderr" ]`), and only a run warns, with the fallback's headline. Also, the flag's warning shares the four middle lines with the fallback warning but has its own headline and way-back line, so "in the fallback warning's words" is true of the middle only. Precise version: "says so on a run and, where bwrap works, on a --probe too".

**Evidence:** `scripts/confine-tests.sh:163-176`; `test/scripts/confine-tests.bats:381-390`; `$X/compare.out` (cases `unshare|STUB_UNSHARE=ok [--no-loopback --probe]`)

---

## Claim 4: "What unshare does not confine, in one place for both routes that reach it: --no-loopback switching away from bwrap, and bwrap being unavailable."

**Location:** `scripts/confine-tests.sh:122-123`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every assignment of `primitive` in the script and both call sites of `warn_unshare_only`; does not establish the text is unique in other files (guide, tests).
**Legibility-target:** for-orchestrator-synthesis

`primitive` is assigned only at `scripts/confine-tests.sh:137` (`primitive="$(detect_primitive)"`) and `:165` (`primitive="unshare"`). The first route sets `fell_back=1` (`:145-146`) and is warned at `:208-217`; the second calls `warn_unshare_only` at `:166`. A bwrap that fails at run time does not reach unshare (`exec bwrap` at `:240`; pinned by `test/scripts/confine-tests.bats:309-314`). No third route exists; `rg -n 'NOTHING ELSE' scripts/confine-tests.sh` finds the heredoc only (paraphrased — no quote available because the claim covers absence of other routes, established by the two assignments above).

**Evidence:** `scripts/confine-tests.sh:126-147,163-168,208-217`; `$X/compare.out`

---

## Claim 5: "Detection settled for unshare: bwrap is not installed, or its probe failed."

**Location:** `scripts/confine-tests.sh:142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `detect_primitive`'s two branches; does not cover a bwrap whose probe passes but whose run fails (that route never sets `fell_back`).
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:86-98
detect_primitive() {
  if command -v bwrap >/dev/null 2>&1 &&
     bwrap --ro-bind / / --unshare-net -- true >/dev/null 2>&1; then
    echo "bwrap"; return 0 ...
  if command -v unshare ... && unshare -rn true ...; then
    echo "unshare" ...
```
(excerpt ends :98; the function ends there — read)

**Evidence:** `scripts/confine-tests.sh:86-98,142-147`

---

## Claim 6: "It is printed here and not at selection, so only a run that is about to start prints it: --probe's output and the refusals above are unchanged. `command -v` runs nothing."

**Location:** `scripts/confine-tests.sh:205-207`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what this block adds: compared with 23ffb16c on identical inputs, it changes no probe output, no refusal (no primitive, no ip, --no-loopback over bwrap, nothing to run, unknown flag) and no stand-in call count; does not cover the separate re-wrap of the --no-loopback warning (Claim 22), which changes a probe's stderr from the selection block, not from this one.
**Legibility-target:** for-orchestrator-synthesis

The block sits after the `--probe` exit (`:190-194`) and the empty-command refusal (`:196-199`). In `$X/compare.out`, every refusal case differs between old and new only in the `$0` path inside the usage text (an artefact of the two copies' names, `old.sh`/`new.sh`). The stand-in records no extra `bwrap` call on any fallback run: the only call-log differences across the whole matrix are `unshare.2` (the body argv) and `child.1` (the D1 cases). `command -v` is a shell builtin lookup.

**Evidence:** `scripts/confine-tests.sh:190-219`; `$X/compare.out`

---

## Claim 7: "The body is static; the command reaches it as positional arguments, and `--` ends exec's options so a command named `-a` is run (or not found), never read as one."

**Location:** `scripts/confine-tests.sh:261-263`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15's exec with `--` and the script's body as run by the stand-in; does not establish behaviour inside a real `unshare -rn`.
**Legibility-target:** for-orchestrator-synthesis

```bash
# scripts/confine-tests.sh:267-274
if [[ "$loopback" -eq 1 ]]; then
  exec unshare -rn -- "$BASH" -c '
    ...
    exec -- "$@"' confine-tests "${cmd[@]}"
fi
```

`$X/compare.out`: new script, `-- -a x rec one` exits 127 with `confine-tests: line 6: exec: -a: not found` and no child call; `-- -rec -x` runs `-rec` with `-x`.

**Evidence:** `scripts/confine-tests.sh:261-274`; `$X/compare.out`; `$X/shells.out`

---

## Claim 8: "bash's exec takes options and needs the `--`, dash's takes none and would run `--` as the command, so no one spelling is right under both"

**Location:** `scripts/confine-tests.sh:264-266`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash (as bash and linked as `sh`) and dash 0.5.12 with the two spellings `exec "$@"` and `exec -- "$@"`; does not cover other `sh` implementations (busybox, ksh, mksh).
**Legibility-target:** for-orchestrator-synthesis

From `$X/shells.out`: bash and bash-as-sh with `exec "$@"`: `-rec -x` → `exec: -r: invalid option` (2), `-a x rec one` → runs `rec` with `one` (0); with `exec -- "$@"` both right. dash with `exec "$@"` right; with `exec -- "$@"` every case → `exec: --: not found` (127).

**Evidence:** `$X/shells.out`; `$X/probes/probe1.out`

---

## Claim 9: "the real bash, cat and awk, plus stand-ins ... (no sh: the script runs none, and two tests add one to show it makes no difference)"

**Location:** `test/scripts/confine-tests.bats:8-11`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's own invocations and setup()'s PATH; does not establish that no tool the script runs (bwrap, unshare, ip) uses sh on a real host.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:54`: `for tool in bash cat awk; do`. The two tests at `:445-453` link `sh` via `dash_named_on_unshare` (`:432` `ln -s "$1" "$TOOLS/sh"`). All 21 tests pass with no `sh` on the PATH except those two (`$X/bats-head.out`), and the script contains no `sh` call (paraphrased — no quote available because the claim covers absence; `rg -n '\bsh\b -c|exec sh' scripts/confine-tests.sh` finds none).

**Evidence:** `test/scripts/confine-tests.bats:54,428-453`; `$X/bats-head.out`

---

## Claim 10: "One copy has a space in its path; two are on PATH, under a name starting "-" and under the name of a shell builtin."

**Location:** `test/scripts/confine-tests.bats:58-59`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers setup() lines 46-66; does not cover the stand-ins.
**Legibility-target:** for-orchestrator-synthesis

`:46` `RECORD="$T/my cmds/record argv"`, `:62` `cp "$RECORD" "$TOOLS/-record"`, `:63` `cp "$RECORD" "$TOOLS/eval"`.

**Evidence:** `test/scripts/confine-tests.bats:44-72`

---

## Claim 11: "or when -STATUS is given and is not the exit status (bats' `run -N`; it warns about a 127 it was not told to expect)"

**Location:** `test/scripts/confine-tests.bats:141-142`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bats 1.8.2's `run -N` and its BW01 warning; does not cover other bats versions beyond the file's declared minimum 1.5.0.
**Legibility-target:** for-orchestrator-synthesis

`confine()` forwards it: `:146` `if [[ "$1" == -[0-9]* ]]; then want=("$1"); shift; fi`, `:151` `run "${want[@]}" --separate-stderr ...`. `$X/bw.out`: `run -127` on exit 0 fails ("expected exit code 127, got 0"); plain `run` on 127 prints `BW01: ... exited with code 127, indicating 'Command not found'`.

**Evidence:** `test/scripts/confine-tests.bats:138-154`; `$X/bw.out`

---

## Claim 12: "This cannot see the body's own exec: the body runs under bash, which runs the last command of a -c string in place with or without it. The test with a command named eval sees it."

**Location:** `test/scripts/confine-tests.bats:159-161`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers removing `exec` (mutants m04 bare `"$@"`, m05 `command -- "$@"`); does not claim the eval test catches dropping only the `--` (m03 passes it and is caught by tests 17, 18).
**Legibility-target:** for-orchestrator-synthesis

`$X/mut.out`: `m04 bare "$@" in the body: failing tests: 17, 18, 19`; `m05 command -- "$@": 17, 18, 19`. Test 16 (which calls `same_process`) passes under both, confirming the pid check cannot see the missing exec; test 19 (eval, `:455-462`) fails, so it does.

**Evidence:** `test/scripts/confine-tests.bats:156-164,455-462`; `$X/mut.out`

---

## Claim 13: "unshare -rn -- BASH -c BODY confine-tests COMMAND..., where BASH is the bash that runs the script (here the one on the built PATH) ... The command's exit status comes back through bash."

**Location:** `test/scripts/confine-tests.bats:409-416`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-in's recorded argv and status 7; does not establish a real unshare passes the status the same way.
**Legibility-target:** for-orchestrator-synthesis

`:413` `call unshare 2 -rn -- "$TOOLS/bash" -c "${first[4]}" confine-tests ...` and `:418` `[ "$status" -eq 7 ]` pass (`$X/bats-head.out`). `$X/probes/probe2.out` shows `$BASH` = the built PATH's `tools/bash` under a shebang start.

**Evidence:** `test/scripts/confine-tests.bats:398-426`; `$X/bats-head.out`; `$X/probes/probe2.out`

---

## Claim 14: "bash's exec takes options (-a NAME sets argv[0]) and dash's takes none, so a body that ends `exec "$@"` under sh runs `-a x CMD one` as CMD where sh is bash."

**Location:** `test/scripts/confine-tests.bats:428-430`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12; does not cover other shells.
**Legibility-target:** for-orchestrator-synthesis

`$X/shells.out`: `sh(…/b2/sh) | exec "$@" | -a x rec one => [0] ran …/bin/rec with: one`; dash → `exec: -a: not found` (127).

**Evidence:** `$X/shells.out`; `$X/probes/probe1.out`

---

## Claim 15: Each new or changed test's name describes what its body asserts (tests 14 "--probe reports unshare ...", 15 "unshare without ip is refused ...", 16 "... a static bash body, every word a positional argument", 17/18 "... passes a command whose name starts with a dash, and fails on one that names no file: sh is bash / dash", 19 "... execs the file the command names, not a shell builtin of that name", 20 "a run that falls back to unshare first warns what unshare does not confine, in --no-loopback's words (H2)")

**Location:** `test/scripts/confine-tests.bats:357-497`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name against its own assertions and against the mutants that should fail it; does not claim the names are complete descriptions (test 15 also pins the fallback warning on a --no-loopback run).
**Legibility-target:** for-orchestrator-synthesis

Test 16 pins `"$TOOLS/bash" -c` and an identical body across two commands (`:413-423`); 17/18 assert status 7 with child `-x`, then `confine -127` with `exec: -a: not found` and no second child call (`:433-442`); 19 asserts the file `eval` received `touch pwned` and no `pwned` file (`:457-461`); 20 asserts headline first, four shared lines equal across the three routes, way-back line at index 5, one `NOTHING ELSE`, banner last (`:469-496`). Each fails under the matching mutant in `$X/mut.out` (m01/m02 → 16; m03 → 17, 18; m04/m05 → 19; m08, m11-m13, m16, m18, m19 → 20).

**Evidence:** `test/scripts/confine-tests.bats:357-497`; `$X/mut.out`

---

## Claim 16: Test comments on the new behaviour: "The refusal is stderr's first line: nothing is about to run, so the fallback's warning is not printed before it"; "The flag did not cause the weaker profile here ..., so the warning is the fallback's"; "the way back to bwrap's profile (which starts on the sixth line: the text between is the same on every route)"; "With nothing to run there is nothing to warn about."

**Location:** `test/scripts/confine-tests.bats:373-374,387-388,466-468,493`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-in runs; does not cover a real primitive.
**Legibility-target:** for-orchestrator-synthesis

`refused 3 "$NO_IP"` (`:376,378`) checks `stderr_lines[0]`; the NO_IP refusal at `scripts/confine-tests.sh:184-188` precedes the fallback block at `:208`. `$X/compare.out` shows the three way-back lines start at stderr line 6 on every route, and `-- --` on a fallback exits 2 with the usage line alone.

**Evidence:** `test/scripts/confine-tests.bats:372-396,464-497`; `scripts/confine-tests.sh:184-219`; `$X/compare.out`

---

## Claim 17: "Written before the fixes, so 7 of the 21 fail at this commit"

**Location:** commit d03a3078 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers d03a3078's script and test file run together; does not cover the rest of the suite.
**Legibility-target:** for-orchestrator-synthesis

`$X/bats-d03a3078.out`: `1..21`, `not ok` for 15, 16, 17, 18, 19, 20, 21.

**Evidence:** `$X/bats-d03a3078.out`; `$X/at-d03a3078/`

---

## Claim 18: "... each for the reason it names"

**Location:** commit d03a3078 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first failing assertion of each of the 7 tests against the three reasons the message lists; does not judge whether a test would fail for its own reason once the earlier assertion is fixed (bd657ce8 shows test 20 then does).
**Legibility-target:** for-author

Tests 16, 19 and 21 fail on the missing `sh` (`stub/unshare/unshare: line 29: exec: sh: not found`, status 127), the message's third reason; 17 fails on `sh: line 6: exec: -r: invalid option` (D1); 18 on the error's name (Claim 19); 15 on `[ "${stderr_lines[0]}" = "$NO_BWRAP_WARNING" ]` (D2). Test 20, whose name is the fallback warning, fails first at `test/scripts/confine-tests.bats:477` (`[ "$status" -eq 7 ]`, status 127) on the missing `sh`, before any warning assertion runs; so at this commit it does not fail for the reason its name gives, though it does fail for one of the three reasons listed. Precise version: "each for one of these reasons".

**Evidence:** `$X/bats-d03a3078.out` (lines 16-115)

---

## Claim 19: "With sh linked to dash the same test fails only on the name bash's error will carry after the fix."

**Location:** commit d03a3078 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 18 at d03a3078; the remaining two assertions after the failing one (`:441-442`) were checked against the recorded calls, not executed.
**Legibility-target:** for-orchestrator-synthesis

Test 18 passes its first half (`child.1: -x`, status 7) and fails at `:440`, the `"confine-tests: "*"exec: -a: not found"` match, with stderr `sh: 6: exec: -a: not found`; stdout is empty and there is one child call, so `:441-442` would pass.

**Evidence:** `$X/bats-d03a3078.out` (lines 58-75)

---

## Claim 20: "Tests: 19 of 21 pass; the two left are the fallback warning (next commit)."

**Location:** commit bd657ce8 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bd657ce8's files; does not cover the full suite.
**Legibility-target:** for-orchestrator-synthesis

`$X/bats-bd657ce8.out`: `not ok 15`, `not ok 20` only; both are fallback-warning assertions. 6465a156, 7ecf6ee3 and ca6cf3be pass 21/21 (`$X/bats-6465a156.out` etc.).

**Evidence:** `$X/bats-bd657ce8.out`, `$X/bats-6465a156.out`, `$X/bats-ca6cf3be.out`

---

## Claim 21: "Where sh is bash, exec read the command's first word as an option: `-- -a x CMD one` ran CMD and exited 0, and `-- -record -x` was refused. Where sh is dash the same line was right, and `exec -- "$@"` is wrong there ... a name that is no file exits 127 with nothing run in its place. The script no longer needs sh."

**Location:** commit bd657ce8 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old and new script under the stand-ins with sh as bash and as dash; does not cover a real unshare.
**Legibility-target:** for-orchestrator-synthesis

`$X/compare.out`, old vs new, sh=bash: `-- -rec -x` status 2 → 0; `-- -a x rec one` status 0 (child ran `one`) → 127. sh=dash: both `SAME` in status. The suite passes with no `sh` on PATH (Claim 9).

**Evidence:** `$X/compare.out`; `$X/shells.out`; `$X/bats-head.out`

---

## Claim 22: "--probe is unchanged for every input: the fallback's warning is printed only by a run that is about to start, after the refusals."

**Location:** commit 6465a156 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 24 probe inputs (12 configurations x `--probe`, `--no-loopback --probe`, sh as bash and dash) diffed old vs new; does not cover inputs outside the matrix.
**Legibility-target:** for-author

stdout and status are unchanged for every probe input, and the fallback warning never appears on a probe. stderr is not: `--no-loopback --probe` with a usable bwrap (and with a bwrap that passes the probe but fails at run time) prints the flag's warning with lines 5-7 re-wrapped:

```
old:  with EROFS will succeed against the real filesystem. Drop the flag to
      get the hardened profile (loopback is not egress — the namespace has
new:  with EROFS will succeed against the real filesystem.
      Drop the flag to get the hardened profile (loopback is not egress — the
```

The same message says the line breaks moved, so the change is disclosed, but "unchanged for every input" is not literally true of a probe's stderr. Precise version: "--probe's stdout and status are unchanged for every input; the --no-loopback warning it prints is re-wrapped". The same holds for the brief's invariant ("no change to ... --probe") — see Escalate.

**Evidence:** `$X/compare.out` (the four `DIFF ... [--no-loopback --probe]` entries); `scripts/confine-tests.sh:126-135,166-168`

---

## Claim 23: "Tests: 21 of 21 pass" and "with --no-loopback and no usable bwrap the run prints the fallback's warning, not the flag's ...; that route printed no warning before."

**Location:** commit 6465a156 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 6465a156's files and the old/new matrix; does not cover the full suite.
**Legibility-target:** for-orchestrator-synthesis

`$X/bats-6465a156.out` 21/21. `$X/compare.out`: `[unshare|STUB_UNSHARE=ok] [--no-loopback -- rec a]` old stderr is the banner alone; new adds the `bwrap is not installed` warning.

**Evidence:** `$X/bats-6465a156.out`; `$X/compare.out`

---

## Claim 24: "A scratch copy of the script that printed one extra line on the fallback route, after the four shared lines, passed every test ... 19 of 19 mutants now fail at least one test; the unchanged script passes 21 of 21."

**Location:** commit ca6cf3be message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the author's 19 mutants, re-run unmodified into this pass's scratch; does not establish the mutant set covers every plausible regression.
**Legibility-target:** for-orchestrator-synthesis

`$X/mut.out`: control passes, every one of m01-m19 fails at least one test, `SURVIVORS: none`. Mutant m16 (`echo "  Extra fallback-only line."` after the heredoc on non-flag routes) run against the 7ecf6ee3 test file passes 21/21 (`$X/m16-at-7ecf6ee3.out`), and fails test 20 against HEAD.

**Evidence:** `$X/mut.out`; `$X/m16-at-7ecf6ee3.out`

---

## Claim 25: Brief invariant repeated in commits: no change to which primitive is chosen, nor to exit statuses other than D1's.

**Location:** commits bd657ce8, 6465a156; `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 264 old/new runs (11 stand-in configurations x 12 argument sets x 2 shells); does not cover real primitives or inputs outside the matrix. The --probe part is Claim 22/35.
**Legibility-target:** for-orchestrator-synthesis

Status differs in exactly four cases, all D1 with sh=bash (`-- -rec -x` 2→0 and `-- -a x rec one` 0→127, each on the bwrap-refused and bwrap-missing configurations). Call logs differ only in `unshare.2` (body argv `sh -c …` → `…/bash -c …`) and `child.1` in those D1 cases: no change in which stand-in is probed or execed.

**Evidence:** `$X/compare.out`

---

## Claim 26: "`bwrap` adds a read-only root, a private `/tmp` and a pid namespace to the network namespace. When `bwrap` is not installed or is refused, a run falls back to `unshare -rn`, which denies the network and nothing else: the tests run as uid 0 against the real filesystem. The run goes ahead, and first prints a warning on stderr that names what is absent. `--probe` names the primitive it found (`bwrap` or `unshare`) on its first line."

**Location:** `guides/test-hermeticity.md:59-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the bwrap profile, the fallback route and the probe's stdout first line; "first line" is stdout's (with `--no-loopback` and a working bwrap, stderr's first line is the warning and the "found" primitive is the one switched to).
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:240-251`: `--ro-bind / /`, `--tmpfs /tmp`, `--unshare-net`, `--unshare-pid`. `:191` `echo "confine-tests: primitive available: $primitive (loopback=$loopback)"` is the probe's first stdout line. Fallback warning: Claim 1.

**Evidence:** `scripts/confine-tests.sh:190-194,208-219,240-251`; `$X/compare.out`

---

## Claim 27: "**Reads are not confined** by the runner — `--unshare-net` denies network and nothing else. On the `unshare` fallback writes are not confined either (see "Triage vs. ground truth")."

**Location:** `guides/test-hermeticity.md:183-184`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the fallback and the cross-reference (the new paragraph is under `## Triage vs. ground truth`, `guides/test-hermeticity.md:42`); does not mention that the --no-loopback route is equally unconfined for writes (true, but not claimed).
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:275` `exec unshare -rn -- "${cmd[@]}"` and `:268` have no mount options; `--ro-bind / /` permits reads on the bwrap path.

**Evidence:** `guides/test-hermeticity.md:42,59-63,183-184`; `scripts/confine-tests.sh:240-275`

---

## Claim 28: "`scripts/confine-tests.sh` at 23ffb16c (227 lines ...)" and "`test/scripts/confine-tests.bats` (420 lines, 17 tests)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:14,20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the files at 23ffb16c.
**Legibility-target:** for-orchestrator-synthesis

`git show 23ffb16c:scripts/confine-tests.sh | wc -l` → 227; test file → 420 lines, `grep -c '^@test'` → 17.

**Evidence:** `git show 23ffb16c:test/scripts/confine-tests.bats`

---

## Claim 29: Line references into 23ffb16c: detection 79-118, the --no-loopback switch 134-152 ("a seven-line warning (six `echo`s after the headline)", "the only place that text is printed", "It runs before --probe answers"), the run 176-227.

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:16-18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cited ranges at 23ffb16c.
**Legibility-target:** for-orchestrator-synthesis

At 23ffb16c: `:79 detect_primitive() {` through `:118 fi` (the exit-3 refusal); `:134 if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]; then` through `:152 fi`, with seven `echo`s at `:137-143`; `:176 # --- run` through `:227 exec unshare -rn -- "${cmd[@]}"`.

**Evidence:** `git show 23ffb16c:scripts/confine-tests.sh` lines 79-118, 134-152, 176-227

---

## Claim 30: The D1 table (bash 5.2.15: `-rec -x` refused `-r: invalid option`; `-a x rec one` runs `rec` with `one`; `eval echo hi` runs the file; `-nonexistent y` refused `-n`. dash 0.5.12: runs `-rec`; `-a: not found`; runs the file `eval`; `-nonexistent: not found`)

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:32-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `exec "$@"` row of probe 1 re-run from a copy; the probe's status column is broken (the doc says so; all show 0), so the verdict rests on output text.
**Legibility-target:** for-orchestrator-synthesis

`$X/probes/probe1.out`, `== sh-bash`/`== sh-dash`, `exec "$@"` lines match each cell.

**Evidence:** `$X/probes/probe1.out`

---

## Claim 31: "bash's `exec` builtin takes options (`-c`, `-l`, `-a NAME`) ... Location: `scripts/confine-tests.sh:225`."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:39`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line at 23ffb16c and bash's usage text.
**Legibility-target:** for-orchestrator-synthesis

23ffb16c `:225` is `    exec "$@"' sh "${cmd[@]}"`. `$X/shells.out`: `exec: usage: exec [-cl] [-a name] [command [argument ...]]`.

**Evidence:** `git show 23ffb16c:scripts/confine-tests.sh:225`; `$X/shells.out`

---

## Claim 32: "Callers: none in code [observed: `grep -rn confine-tests` over `*.sh`, `*.bats`, `*.py`]."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers invocations in `*.sh`, `*.bats`, `*.py` outside archive/; mentions in `scripts/hermeticity-lint` (prints the command) and `test/fixture-hermeticity.bats:15` (a comment) are not callers; the script's own test file is its test, not a caller.
**Legibility-target:** for-orchestrator-synthesis

`rg -l confine-tests -g '*.sh' -g '*.bats' -g '*.py'` → the script, its test file, `test/fixture-hermeticity.bats` (comment only: `# namespace: scripts/confine-tests.sh -- scripts/run-tests.sh --all`).

**Evidence:** `test/fixture-hermeticity.bats:15`; `scripts/hermeticity-lint:29,935,1019`

---

## Claim 33a: "decision 018 (`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`) cite[s] `scripts/confine-tests.sh:220`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22,265`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers decision 018's two lines; the citation now points at a comment line (the body moved to `scripts/confine-tests.sh:268`), which the doc records as a follow-up.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43`: "(`scripts/confine-tests.sh:220` is the reference for this pattern.)"; `:117`: "- `scripts/confine-tests.sh:220` — reference argv-passthrough pattern." At 23ffb16c `:220` is `  exec unshare -rn -- sh -c '`.

**Evidence:** `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`

---

## Claim 33b: "`CLAUDE.md` and decision 018 ... cite `scripts/confine-tests.sh:220`" / "Decision 018 and `CLAUDE.md` cite `scripts/confine-tests.sh:220`; the line moves."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22,265`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers CLAUDE.md at 23ffb16c and HEAD and its history; does not affect the decision-018 half (Claim 33a).
**Legibility-target:** for-author

`CLAUDE.md:9` (same at 23ffb16c) cites the file with no line: "(record 018; the reference pattern is in `scripts/confine-tests.sh`)". `git log -S'confine-tests.sh:220' -- CLAUDE.md AGENTS.md global-instructions/` returns nothing: CLAUDE.md never held the line number. So CLAUDE.md needs no follow-up for the moved line; only decision 018 does. Fix: drop CLAUDE.md from both sentences (and from the follow-up it feeds).

**Evidence:** `CLAUDE.md:9`; `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`

---

## Claim 34: "In this container `scripts/confine-tests.sh --probe` exits 3 ... Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:24-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container at de1f4bf9 (22:06Z); time-varying with the container's kernel and seccomp policy.
**Legibility-target:** for-orchestrator-synthesis

`timeout 60 scripts/confine-tests.sh --probe` in the worktree: exit 3, first line as quoted (captured in the session's tool output; not copied to a log file).

**Evidence:** `scripts/confine-tests.sh:100-120,137-140`

---

## Claim 35: "Which primitive is chosen, every exit status other than D1's, and `--probe` (stdout, stderr and status, for every input) do not change (brief). The tests pin this: the selection tests are untouched, and the fallback probe's stderr is now pinned empty."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same 264-run matrix as Claim 25; does not cover inputs outside it.
**Legibility-target:** for-author

Primitive choice and statuses: as Claim 25. `--probe` stderr: the `--no-loopback --probe` warning over a usable bwrap is re-wrapped (Claim 22), which the same doc records at `:208` ("its words are unchanged, its line breaks are not"), so the invariant as written ("stderr ..., for every input") contradicts the doc's own DD-2 note. No test pins that probe's stderr past line 1 (`test/scripts/confine-tests.bats:323-324` checks the headline and a substring). Precise version: "stdout and status for every input; stderr except the re-wrap of the --no-loopback warning".

**Evidence:** `$X/compare.out`; `test/scripts/confine-tests.bats:316-326`

---

## Claim 36: "The script is not an enforcement file for `hooks/live-verify-gate.sh` [observed: its `enforcement` and `host_tools` patterns match only `devcontainer-config/`]"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two patterns; does not check other gates.
**Legibility-target:** for-orchestrator-synthesis

`hooks/live-verify-gate.sh:83` `enforcement='^devcontainer-config/(Dockerfile|...)'`; `:91` `host_tools='^devcontainer-config/(cc-exit-scan\.sh|...)'`.

**Evidence:** `hooks/live-verify-gate.sh:83,91`

---

## Claim 37: Failure-pattern entries: FP-050 (unshare tier shares host mount namespace; fix was to install the stronger primitive), FP-044 and FP-057 (a fallback tier ran with less confinement), FP-058 (a bwrap run-time failure dropped work silently); the second grep's hits FP-025, FP-032, FP-046, FP-067, FP-118, FP-134 are other mechanisms; "None records a shell's `exec` reading a command name as an option."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:63,73-79`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two quoted greps re-run and each named entry; the first grep returns 24 entries, of which the doc selects four (a judgment, not checked).
**Legibility-target:** for-orchestrator-synthesis

`docs/failure-patterns.md:192` `FP-050 ... symptom:unshare-tier-shares-host-mount-namespace-host-writes ... fix:install-the-dependency`; `:186` `FP-044 ... fallback-tier-ran-with-network-intact`; `:199` `FP-057 ... fallback-tier-blocks-writes-but-not-reads-disclosure`; `:200` `FP-058 ... bwrap-runtime-failure-drops-the-computation-silently`. The second grep returns exactly FP-025, 032, 046, 067, 118, 134, with symptoms matching the doc's glosses (`:167,174,188,209,260,276`). `rg -i 'exec.*option|leading.dash|dash-named'` returns nothing.

**Evidence:** `docs/failure-patterns.md:167,174,186,188,192,199,200,209,260,276`

---

## Claim 38: Gotchas: "`command -- "$@"` and a bare `"$@"` both run a shell builtin ...: `eval echo hi` prints `hi` under both shells"; "`$BASH` is ... `<PATH dir>/bash` when the script starts through its shebang, the interpreter's path when started as `bash script`"; "`"$BASH" -c '... exec -- "$@"'` keeps the pid, returns the command's status, and exits 127 for a name not on PATH ... and 126 for a directory"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:65-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12.
**Legibility-target:** for-orchestrator-synthesis

`$X/probes/probe1.out`: `command -- "$@" | eval echo hi -> hi` and `"$@" | eval echo hi -> hi` under sh-bash and sh-dash. `$X/probes/probe2.out`: shebang start `BASH=…/probe2/tools/bash`, same pid inner and child, status 7; `-a` → 127; directory → 126; `bash script` → `BASH=/usr/bin/bash`.

**Evidence:** `$X/probes/probe1.out`; `$X/probes/probe2.out`

---

## Claim 39: DD-1 match-table evidence for candidates 3-5: 3 and 4 "`eval ...` runs the builtin"; 5 "a name holding `=` is read as an assignment (`a=b z` ran `z`)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:120-122`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe-1 rows for these candidates; the scoring marks (✓/~/✗) are judgments and not checked.
**Legibility-target:** for-author

3 and 4: as Claim 38. 5: `$X/probes/probe1.out` shows `exec env -- "$@" | a=b z -> env: ‘z’: No such file or directory`: env took `a=b` as an assignment (the mechanism is right) and then tried to run `z`, which is not a file in the probe; nothing ran. Precise version: "`a=b z` tried to run `z`" (or "ran `z` in place of the file `a=b`").

**Evidence:** `$X/probes/probe1.out`

---

## Claim 40: "bash -c reads BASH_ENV and imports exported functions, sh (dash) does not"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:146,168`; pre-mortem `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:39` ("the `sh` it replaces does not, whether it is dash or bash started as `sh`")
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `BASH_ENV` with `-c` under bash, bash-as-sh and dash, and an exported function under bash and dash; does not cover `ENV`.
**Legibility-target:** for-orchestrator-synthesis

`$X/bashenv.sh` output: `/usr/bin/bash: SOURCED body`, `…/be/sh: body`, `/usr/bin/dash: body`; `bash -c f: FUNC`, `dash -c f: dash: 1: f: not found`.

**Evidence:** `$X/bashenv.sh` (output in session; re-runnable)

---

## Claim 41: "The `--no-loopback` warning is re-wrapped ...: its words are unchanged, its line breaks are not. Its first line ... is byte-identical."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:208`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old and new text as printed.
**Legibility-target:** for-orchestrator-synthesis

`$X/compare.out` diffs for `--no-loopback --probe` touch only lines 10-12 of the record (warning lines 5-7); joined, the words are identical, and line 1 (`confine-tests: WARNING — --no-loopback forces the unshare primitive.`) is unchanged.

**Evidence:** `$X/compare.out`; `git show 23ffb16c:scripts/confine-tests.sh:137-143`; `scripts/confine-tests.sh:126-135,166-168`

---

## Claim 42: "The body's `$0` is `confine-tests`, so bash's own errors read `confine-tests: line 6: exec: -a: not found`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:209`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-in run.
**Legibility-target:** for-orchestrator-synthesis

`$X/compare.out`, new script, `[unshare ip|...] [-- -a x rec one] sh=bash`: `> confine-tests: line 6: exec: -a: not found`.

**Evidence:** `$X/compare.out`

---

## Claim 43: "Decision 018 item 4: 'Defeat option injection at the argv layer: prefix a relative path with `./` and/or pass `--` before it'"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:59`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote (the source italicises *option*).
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:46-47`: "4. Defeat *option* injection at the argv layer: prefix a relative path with `./` and/or pass `--` before it".

**Evidence:** `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:46-47`

---

## Claim 44: "No live run: a real `unshare -rn` has not started `"$BASH"` here. ... `-r` maps the caller to root in the namespace, so reading it cannot be refused by a permission the caller had [inferred]."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:264`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The doc itself labels it inferred; does not establish that `"$BASH"` is reachable inside a real namespace.
**Legibility-target:** for-orchestrator-synthesis

Execution required and blocked: this container cannot create a user or network namespace (`--probe` exits 3, Claim 34). Needs one confined run on a host where `unshare -rn` works.

**Evidence:** `scripts/confine-tests.sh:267-274`

---

## Claim 45: "pr-prep's fallback check fired on a count of 539 changed lines, 301 of them the research doc; the code change is 238 lines"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`; commit de1f4bf9 ("238 code lines")
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git diff --numstat 23ffb16c ca6cf3be`.
**Legibility-target:** for-author

539 = 490 insertions + 49 deletions, research doc 301: right. The 238 is script 74 + test 153 + guide 11: it counts the guide (prose) as code; script and test alone are 227. Precise version: "238 lines outside the research doc (227 of them code)".

**Evidence:** `git diff --numstat 23ffb16c ca6cf3be`

---

## Claim 46: "--probe on a host with unshare and no usable bwrap prints `primitive available: unshare (loopback=1)` and exits 0, with no warning"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:16`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stand-ins.
**Legibility-target:** for-orchestrator-synthesis

Test 14 (`test/scripts/confine-tests.bats:357-370`) and `$X/compare.out`.

**Evidence:** `test/scripts/confine-tests.bats:357-370`; `$X/compare.out`

---

## Claim 47: "the four tests that begin `[ "$(id -u)" -ne 0 ] || skip` (`test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889`, `test/install-host.bats:680`, `test/cc-isolated-functions.bats:1970`) skip"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the four lines and a repo-wide search for other skip-as-root tests (none); `install-host.bats:680` begins `need_script;` before the check, a cosmetic difference; does not cover tests that branch on uid without skipping (`test/scripts/build-loop-check.bats:103,305`, `test/cc-isolated-functions.bats:1229`).
**Legibility-target:** for-orchestrator-synthesis

`test/cc-push.bats:417` `[ "$(id -u)" -ne 0 ] || skip "root ignores directory permissions"`; `test/hooks/guard-trusted-writes.bats:889` `... || skip "root reads through chmod 000"`; `test/install-host.bats:680` `need_script; [ "$(id -u)" -ne 0 ] || skip ...`; `test/cc-isolated-functions.bats:1970` `... || skip "running as root: ..."`.

**Evidence:** the four file:line locations above

---

## Claim 48: "`docs/roadmap.md:49`: 'exit 0: tests pass confined'"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21,26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line as of de1f4bf9.
**Legibility-target:** for-orchestrator-synthesis

`docs/roadmap.md:49`: "wording (run `scripts/confine-tests.sh --probe`; exit 0: tests pass confined; exit 3: ..."

**Evidence:** `docs/roadmap.md:49`

---

## Claim 49: "The run prints the new warning as the file's first seven lines" (bwrap refused) and "the log shows the banner on line seven" (no bwrap)

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:21,32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two routes' line counts.
**Legibility-target:** for-orchestrator-synthesis

Refused route: headline + 4 shared + 2 way-back lines = 7 (`scripts/confine-tests.sh:210-212`); not-installed route: 6 lines, banner on line 7 (`:214-215`). Both seen in `$X/compare.out`.

**Evidence:** `scripts/confine-tests.sh:126-135,208-219`; `$X/compare.out`

---

## Claim 50: "the mutant 'body under sh again' fails tests 16, 18, 19, 20 and 21, and on a host without dash it would still fail 16, 19, 20 and 21"; "four other tests fail with `exec: sh: not found`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers m01 in this pass's run; the without-dash case is inferred from test 18 being the only dash test (it skips there), not executed.
**Legibility-target:** for-orchestrator-synthesis

`$X/mut.out`: `m01 body under sh again (exec -- kept): failing tests: 16, 18, 19, 20, 21`. Tests 16, 19, 20, 21 build no `sh`, and at d03a3078 (same body interpreter) they fail with `exec: sh: not found` (`$X/bats-d03a3078.out`).

**Evidence:** `$X/mut.out`; `$X/bats-d03a3078.out`

---

## Claim 51: "`setup()` links only `bash`, `cat` and `awk` into `$TOOLS`" and "the argv pin in the unshare run test names `"$TOOLS/bash"`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:50,52`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers setup() and test 16.
**Legibility-target:** for-orchestrator-synthesis

`test/scripts/confine-tests.bats:54` `for tool in bash cat awk; do`; `:413` `call unshare 2 -rn -- "$TOOLS/bash" -c ...`.

**Evidence:** `test/scripts/confine-tests.bats:54,413`

---

## Claim 52: "header, under 'WHY IT NEVER DEGRADES QUIETLY', now says the warning comes first on stderr"; "`--no-loopback`'s has always come first"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:35`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header and the 23ffb16c order.
**Legibility-target:** for-orchestrator-synthesis

`scripts/confine-tests.sh:22,33`: "# WHY IT NEVER DEGRADES QUIETLY" … "and says first, on stderr, what". At 23ffb16c the flag's warning (`:137-143`) precedes the banner (`:178`).

**Evidence:** `scripts/confine-tests.sh:22-35`; `git show 23ffb16c:scripts/confine-tests.sh:134-178`

---

## Claims Requiring Attention

### Incorrect
- **Claim 33b** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22,265`): CLAUDE.md does not cite `scripts/confine-tests.sh:220` (it names the file only, `CLAUDE.md:9`, and never held the line number); only decision 018 does. Drop CLAUDE.md from both sentences and from the follow-up.

### Stale
- none

### Mostly Accurate
- **Claim 3** (`scripts/confine-tests.sh:45-46`): --no-loopback warns on a --probe only where bwrap works; with bwrap missing or refused its probe prints no warning (pinned at `test/scripts/confine-tests.bats:381-384`).
- **Claim 18** (commit d03a3078): test 20 fails at that commit on the missing `sh` (`:477`, status 127), not on the warning its name gives; "each for one of these reasons" is precise.
- **Claim 22** (commit 6465a156): "--probe is unchanged for every input" holds for stdout and status; `--no-loopback --probe` over a usable bwrap now prints the flag's warning re-wrapped on stderr.
- **Claim 35** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`): the invariant lists probe stderr "for every input", which the doc's own `:208` re-wrap contradicts; no test pins it.
- **Claim 39** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:122`): `a=b z` under `exec env --` tried to run `z` (not found), it did not run it.
- **Claim 45** (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`, commit de1f4bf9): "238 code lines" includes the guide's 11; script + test are 227.

### Unverifiable
- **Claim 44** (`docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:264`): `"$BASH"` starting inside a real `unshare -rn` needs one confined run on a host where unshare works; this container cannot create a namespace.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/code-fact-check-report-2026-11-10-confine-tests-dash-and-fallback.md, structured per the code-fact-check skill, with a first line `Commit: de1f4bf9`, a bolded `**Commit:** de1f4bf9` header field and `**Replication:** k=1 (loop pass, decision 031)`.
- Answered: yes
- Out of scope: the research doc's judgments (match-table marks, effort/risk scores, plan size estimates) and the pre-mortem's plausibility labels, which are opinion, not checkable claims; behaviour under a real bwrap/unshare (no namespace in this container); updating `docs/reviews/hallucination-patterns.md` (this pass may write only the report; 33b is a mis-attributed citation, not a fabricated symbol).
- Escalate: (1) the brief's "no change to --probe" invariant is broken in one place by design: `--no-loopback --probe` over a usable bwrap prints its warning with lines 5-7 re-wrapped (stdout and status unchanged). For api-consistency or the orchestrator: accept and correct the wording in 6465a156 / research `:47`, or keep the old line breaks. (2) decision 018's `scripts/confine-tests.sh:220` citation now lands on a comment (the body is at `:268`); the research doc already lists it as a follow-up outside Paths. Nothing for security or performance beyond the BASH_ENV exposure the author recorded and accepted under S1.
- Decisions I made: execution logs are kept in the scratch directory, not under `docs/reviews/execution-logs/`, because the pass forbids other writes to the worktree; I counted the compare matrix's `$0`-path differences in usage text as harness artefacts (the two copies had different names), after reading each one.
