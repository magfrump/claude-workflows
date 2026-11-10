# Research and plan: two fixes in `scripts/confine-tests.sh` (a dash-named command, a silent fallback)

- **Goal**: Fix the two defects the script's first tests recorded: a test command whose name starts with `-` is misread on the `unshare` path when `sh` is bash (D1), and a plain fallback from `bwrap` to `unshare` runs without saying what `unshare` does not confine (D2); and list the test file in the guide.
- **Problem framing**: The script the repo rules name as the reference for passing untrusted text to a subprocess hands the command to whatever `sh` is, and what `exec "$@"` means depends on that shell; and it warns about the weaker `unshare` profile on one of the two routes that reach it. Considered and discarded: "D1 is a missing `--`, so add it to the `sh` body". dash's `exec` runs `--` as the command, so no one spelling of the last line is right under both shells; the problem is the choice of interpreter, not the spelling.
- **Project state**: this branch changes the script's `unshare` run form and its warning, the test file and one guide · second of the confine-tests follow-ups, after `test/confine-tests-bats` (merged at 9d6d6101) · not blocked (cite: docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md)
- **Task status**: in-progress (research and plan written; tests next)

Brief: `docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md` · Branch: `fix/confine-tests-dash-and-fallback` from 23ffb16c · Date: 2026-11-10

This one file holds the research, the design record and the plan, as the first unit's did (`docs/working/research-2026-11-10-confine-tests-bats.md`): the brief names it as this unit's record, and a decision record under `docs/decisions/` is outside the brief's Paths.

## What exists

`scripts/confine-tests.sh` at 23ffb16c (227 lines, bash, `set -euo pipefail`) [observed, read in full]. The first unit's research doc describes all of it; the parts this unit changes:

1. **Detection** (lines 79-118): `detect_primitive` prints `bwrap` when `bwrap --ro-bind / / --unshare-net -- true` exits 0, else `unshare` when `unshare -rn true` does, else fails and the script refuses with exit 3. After it, `primitive` is `unshare` only because bwrap is not installed or its probe failed: that is the plain fallback.
2. **The `--no-loopback` switch** (134-152): with `primitive=bwrap` and the flag, the script switches to `unshare` and prints a seven-line warning (six `echo`s after the headline) that unshare "denies the network and NOTHING ELSE". This is the only place that text is printed. It runs before `--probe` answers, so a `--no-loopback --probe` prints it too.
3. **The run** (176-227): a one-line banner, then one of three `exec`s. bwrap and `--no-loopback` put `--` before the command. The third, `unshare` with loopback, is `exec unshare -rn -- sh -c '<static body>' sh "${cmd[@]}"`; the body raises `lo`, exits 3 if that fails, and ends in `exec "$@"`.

`test/scripts/confine-tests.bats` (420 lines, 17 tests) runs the script under `env -i` on a PATH of stand-ins for `bwrap`, `unshare` and `ip` plus symlinks to the real `bash`, `sh`, `cat` and `awk`. It pins a dash-named command on the bwrap and `--no-loopback` forms only, and leaves the fallback warning's absence unpinned on purpose (three assertions were loosened for it in the first unit's review).

Callers: none in code [observed: `grep -rn confine-tests` over `*.sh`, `*.bats`, `*.py`]. `CLAUDE.md` and decision 018 (`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`) cite `scripts/confine-tests.sh:220` as the reference for "static shell body, values as positional arguments".

In this container `scripts/confine-tests.sh --probe` exits 3 [observed 2026-11-10, at 23ffb16c and again on this branch's final tree]. Its first line:

> `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`

So, as the brief says for exit 3, acceptance rests on `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .`; nothing in this branch has run confined.

### D1, reproduced

Reproduction: `timeout 120 bash probe1.sh` (the probe is quoted under "Probes"): for each of `sh` linked to bash, `sh` linked to dash 0.5.12, it runs `SH -c BODY sh COMMAND...` with five candidate last lines and five commands. With the body's current last line [observed]:

| `sh` is | `-rec -x` | `-a x rec one` | `eval echo hi` (a file named `eval` is on PATH) | `-nonexistent y` |
|---|---|---|---|---|
| bash 5.2.15 | refused: `exec: -r: invalid option` | **runs `rec` with `one`** | runs the file `eval` | refused: `exec: -n: invalid option` |
| dash 0.5.12 | runs `-rec` with `-x` | `exec: -a: not found` | runs the file `eval` | `exec: -nonexistent: not found` |

Root cause: bash's `exec` builtin takes options (`-c`, `-l`, `-a NAME`) and the body gives it the command's words with nothing to end them; dash's takes none. Location: `scripts/confine-tests.sh:225`. Why the tests did not catch it: this container's `sh` is dash, where the line is right, and the first unit was told to pin, not fix.

### D2, reproduced

Reproduction: in the test file's harness, `confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one` exits 0 with one line on stderr, `confine-tests: denying network via unshare (loopback=1)` [observed in the first unit's doc and by this unit's new test failing at 23ffb16c]. Root cause: the warning is inside the `primitive == bwrap && loopback == 0` branch (line 134), so the route "bwrap missing or refused" never reaches it. Location: lines 134-143.

## Invariants

- Which primitive is chosen, every exit status other than D1's, and `--probe` (stdout, stderr and status, for every input) do not change (brief). The tests pin this: the selection tests are untouched, and the fallback probe's stderr is now pinned empty.
- Each word of the test command reaches the child as its own argv element; no part of it is spliced into text a shell parses (repo rule; decision 018). The body stays one static single-quoted string [observed: the unshare run test compares the body across two different commands].
- The suite stays hermetic and passes `scripts/hermeticity-lint --root .` (H3). The test file spawns none of `claude`, `curl`, `gh`, `wget`.
- A stand-in is at least as strict as its tool (repo rule; decision log row 44). The stand-ins for `sh` in the new tests are the real bash and the real dash under the name `sh`.
- The run still goes ahead under `unshare` after the warning (brief: this unit adds the warning, it does not refuse).
- The script is not an enforcement file for `hooks/live-verify-gate.sh` [observed: its `enforcement` and `host_tools` patterns match only `devcontainer-config/`], so no `Live-verified:` trailer and no bypass-family pre-mortem is required.
- No test starts an interactive shell (every shell here is `bash -c` or a script), so the brief's `HISTFILE` line has nothing to act on.

## Prior art

- The other two run forms of the same script: `exec bwrap ... -- "${cmd[@]}"` and `exec unshare -rn -- "${cmd[@]}"`. Both put `--` before the command and pass a dash-named command through (pinned by "a bwrap run passes a command whose name starts with a dash" and the `--no-loopback` case). The fixed third form should behave the same.
- `explain_unavailable()` in the same script: a function that prints one multi-line message from a quoted heredoc. The shared warning follows that shape.
- Decision 018 item 4: "Defeat option injection at the argv layer: prefix a relative path with `./` and/or pass `--` before it". The fix is that rule applied to the reference line itself.

## Gotchas

Failure-pattern grep: FP-044, FP-050, FP-057, FP-058 (see Prior failures)

- `exec -- "$@"` is right under bash, in posix mode too (bash started as `sh`), and wrong under dash, which runs `--` as the command [observed, probe 1].
- `command -- "$@"` and a bare `"$@"` both run a shell builtin in place of a file of the same name: `eval echo hi` prints `hi` under both shells [observed, probe 1]. With `eval` as the command's first word, the rest is parsed as shell code. So neither is a fix: it trades one misreading for another.
- `$BASH` is the path of the bash running the script: `<PATH dir>/bash` when the script starts through its shebang, the interpreter's path when started as `bash script` [observed, probe 2]. `"$BASH" -c '... exec -- "$@"'` keeps the pid, returns the command's status, and exits 127 for a name not on PATH (`-a` among them) and 126 for a directory [observed, probe 2].
- bash runs the last command of a `-c` string in place whether or not it says `exec` (first unit's doc, mutation notes). With the body under bash everywhere, the pid check (`same_process`) no longer tells `exec -- "$@"` from `"$@"` on any host. A test with a command named `eval` tells them apart by behaviour instead.
- The tool's own shell is zsh; a probe that word-splits must be a bash script file, not an inline command (my first probe was inline and printed nonsense).

### Prior failures

The grep was `grep -inE 'confine|netns|unshare|bwrap|namespace|argv|exec |dash|posix|fallback|degrad|silent|warning' docs/failure-patterns.md`, then `grep -inE 'leading-dash|option|misread|builtin|bash-vs|dash-|/bin/sh|shell-'` over the same file. Of the entries the two returned, four bear on this work:

- FP-050 (an `unshare` tier shares the host's mount namespace, so writes land on the host): the fact D2's warning states. The fix there was to install the stronger primitive; here the run goes on and says so.
- FP-044 and FP-057 (a fallback tier ran with less confinement than its caller assumed): the same shape as D2. They argue for the warning naming each thing that is absent, which the existing text does.
- FP-058 (a bwrap failure at run time dropped the work silently): the existing test "a bwrap that fails at run time fails the run" stays as it is; this unit adds no fallback at run time.

The second grep's hits (FP-025, FP-032, FP-046, FP-067, FP-118, FP-134) are about other mechanisms (a `#` read as a comment, a quote in an interpolated expression, shell state across calls, a skill named like a builtin, pipeline status under errexit, an exit trap). None records a shell's `exec` reading a command name as an option.

Failure-pattern skip: both causes were diagnosed and written up before this unit (D1 and D2 in docs/working/research-2026-11-10-confine-tests-bats.md), D2 repeats FP-050's shape, and docs/failure-patterns.md is outside this brief's Paths, so D1's shape is offered to the cycle in the marker instead of written here.

## Design choices

Seeded with `docs/constraints.md` (H1-H4, S1-S11, as quoted in the dispatch) and the brief's own lines.

### DD-1: how the `unshare` run form hands over a command whose name starts with `-`

Prior pruning grep: no matches found for [exec, argv, dash, unshare, confine] (the `Pruned candidates` sections of `docs/decisions/*.md` hold nothing about how a shell body execs its arguments; decision 018 chose the static-body pattern and is carried as candidate 0).

**Candidates** (one line each, no evaluation):

0. Status quo, decision 018's reference line: `sh -c '...; exec "$@"' sh CMD...`.
1. Do nothing in code; document "name the command `./-name`".
2. Run the body under the bash that runs the script: `"$BASH" -c '...; exec -- "$@"' NAME CMD...`.
3. Keep `sh`; end the body with `command -- "$@"`.
4. Keep `sh`; end the body with a bare `"$@"`.
5. Keep `sh`; end the body with `exec env -- "$@"`.
6. Keep `sh`; have the body detect bash (`${BASH_VERSION:+--}`) and add `--` only there.
7. Refuse a dash-named command on this run form (exit 2, "name it `./-name`").
8. Refuse a dash-named command on all three run forms.
9. Resolve the name in the outer script (`type -P`), and hand the body a path, prefixed `./` when the path itself starts with `-`.
10. No inline body: the script re-runs itself inside the namespace under a hidden flag, raises `lo` and execs the command from bash.
11. A helper file (`scripts/lib/raise-lo-exec`) that raises `lo` and execs its arguments.
12. Ideal if effort were free: `unshare` itself raises `lo` (as bwrap does), so no shell stands between it and the command.
13. As 2, but find bash by name on PATH (`bash -c ...`).
14. Drop the `unshare`-with-loopback form: refuse when bwrap is unavailable.

Health check: 3-6 are one cluster (keep `sh`, change the last line); 7, 8 and 14 change the interface, 9 moves the work to the outer script, 10-12 remove the inline body, 1 is the do-nothing option, 4 the naive one, 12 the free-effort one. Added 13 after noticing 2 fixed an unstated choice (which bash).

**Constraints.** Hard: C1 each word reaches the child as its own argv element, whatever `sh` is (brief; decision 018). C2 a name that cannot be run fails and nothing else runs in its place (brief). C3 no change to the primitive chosen, to other exit statuses, or to `--probe` (brief). C4 fails closed, saying why (H2). C5 testable here with stand-ins (H3). C6 inside the brief's Paths. Soft: C7 one static body with positional arguments, one code path (S3, decision 018). C8 small, no new dependency (S8). C9 the same result as the bwrap and `--no-loopback` forms: the named file runs, with the name as given. C10 portable where cheap (S11).

**Match** (✓ meets, ~ partly, ✗ fails, ⚠ makes worse; evidence is probe 1 unless noted):

| # | C1 | C2 | C3 | C4 | C5 | C6 | C7 | C8 | C9 | C10 | Outcome |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | ~ | pruned: the defect |
| 1 | ✗ | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | ~ | pruned: `-a x CMD` still runs `CMD` and exits 0 |
| 2 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | survives |
| 3 | ⚠ | ⚠ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | pruned: `eval ...` runs the builtin, and the `exec` is lost |
| 4 | ⚠ | ⚠ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | pruned: as 3 |
| 5 | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ~ | pruned: a name holding `=` is read as an assignment (`a=b z` ran `z`) |
| 6 | ~ | ~ | ✓ | ~ | ~ | ✓ | ~ | ✓ | ✓ | ✗ | pruned: right for bash and dash only; busybox ash, ksh and zsh as `sh` each have their own `exec` and cannot be tested here |
| 7 | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | pruned: where `sh` is dash a dash-named command runs today, so this turns exit 0 into exit 2 there, and the fallback would refuse what bwrap runs |
| 8 | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | pruned: changes the bwrap and `--no-loopback` statuses, which tests pin |
| 9 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ~ | ✓ | survives: the child's `argv[0]` becomes a path, and three cases need code (not on PATH, a PATH entry starting `-`, a path given starting `-`) |
| 10 | ✓ | ✓ | ~ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ | ~ | survives, weakly: a second entry point and a hidden flag that the flag parser must refuse from outside |
| 11 | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ~ | ✗ | ✓ | ~ | pruned: a new file outside Paths, under the gate's own `scripts/lib/` |
| 12 | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ | ✗ | ✓ | ✗ | pruned: util-linux `unshare` has no such option |
| 13 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | survives: differs from 2 only when `bash` on PATH is not the bash running the script |
| 14 | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | pruned: changes the primitive chosen; the brief's out-of-scope list names it |

C10 is `~` for 2 and 13 because the body needs bash, but the script already does (its shebang, its arrays and `[[`), so no host loses anything; `sh` stops being a dependency of the script at all.

**Tradeoff** (survivors 2, 13, 9, 10):

```
┌─ DECISION: how the unshare run form execs a command named "-something" ┐
│ 4 candidates survived step-3 pruning · scored on the step-4 axes       │
└────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #    approach                    effort        risk     coverage     key downside
  ───  ──────────────────────────  ────────────  ───────  ───────────  ──────────────────────────────
   2 ★ "$BASH" -c, exec -- "$@"    ● 2 lines     ● low    ● 6/6 hard   ● bash reads BASH_ENV and
                                                                          exported functions (mitig.)
   13   bash -c by name            ● 2 lines     ◐ med    ● 6/6 hard   ◐ a second PATH lookup that
                                                                          can find another bash or none
   9    resolve the name outside   ◐ ~15 lines   ◐ med    ● 6/6 hard   ◐ argv[0] changes; three edge
                                                                          cases to get right
   10   re-run self in namespace   ○ ~25 lines   ◐ med    ◐ 5/6 hard   ○ a hidden flag and a second
                                                                          entry point

╭─ [2] "$BASH" -c, exec -- "$@"   ★ recommended ─────────────────────────╮
│ effort    2 changed lines in the script (plus the comment)   risk low  │
│ coverage  6/6 hard · 3/4 soft (C10 partly: the body needs bash)        │
│ hypothesis  If chosen, the new tests show the same argv and the same   │
│             127 for `-record -x` and `-a x CMD one` with sh linked to  │
│             bash and to dash, within this unit; counter-evidence = any │
│             difference between the two, or a mutant that restores      │
│             `sh -c` or drops `--` passing every test.                  │
│ stress-tests applied                                                   │
│   · Boring alternative → 3 and 4 are simpler and were pruned on probe  │
│     evidence (they run builtins); 2 is the simplest that is right      │
│   · Invert the thesis → the case for keeping sh is portability; the    │
│     script is bash already, so nothing is given up                     │
│   · Failure-driven → bash -c reads BASH_ENV and imports exported       │
│     functions, sh (dash) does not; see the downside                    │
│ key downside  an exported function named `ip`, or a BASH_ENV file,     │
│               now also acts inside the body. The outer script is bash  │
│               and already runs under both, and the caller owns the     │
│               environment and the command, so nothing new is exposed.  │
╰────────────────────────────────────────────────────────────────────────╯

▶ recommend [2] "$BASH" -c, exec -- "$@" · confidence 90% · runner-up [13], axis = which bash
```

To see another candidate's card, name its number; the rows above carry each one's worst residual.

**Decision: Path A, candidate 2.** It is the only candidate that passes every hard constraint with no new code path, and probe 2 shows it does what the other two run forms do. Between 2 and 13 the axis is "which bash": `$BASH` is the interpreter already running the script, so it exists and is the one the script's own behaviour was tested with; a name on PATH is a second lookup that can fail or find another build. The project's stated preference is S3 (one path per job), which picks 2.

See alternatives considered → Pruned candidates.

**Pruned candidates and why.** How to read: each entry is `[candidate]: one-line reason for discard`; a later design pass on shell bodies can grep this section. `[0]: is the defect.` `[1]: leaves -a x CMD running CMD with exit 0.` `[3], [4]: command and a bare "$@" run builtins, so eval as a first word executes the rest as shell code.` `[5]: env reads NAME=VALUE words as assignments.` `[6]: per-shell special cases, untestable beyond bash and dash.` `[7], [8], [14]: change exit statuses or the primitive, which the brief forbids.` `[9]: more code and a changed argv[0] for the same result.` `[10]: hidden flag and second entry point.` `[11]: new file outside Paths.` `[12]: unshare has no such option.` `[13]: a second PATH lookup for the interpreter already running.` Prior pruning grep: no matches found for [exec, argv, dash, unshare, confine].

**Stress-test mitigations.** How to read: *Failure-driven* mitigation — the BASH_ENV and exported-function exposure was weighed and accepted, not designed against: the outer script has it already, and S1 (gates defend against honest slips, not a hostile caller) puts a caller who poisons its own environment out of scope. `bash -p` would close it and was not used: it also changes how bash treats `SHELLOPTS` and the effective uid, which is more behaviour to reason about than the exposure removes.

**Consequences.** Easier: the reference line now shows the whole of decision 018's rule (static body, positional arguments, `--` before the command), and the script no longer needs `sh`. Harder: nothing found; a host with bash and no `sh` now works where it did not.

**Revisit triggers.** How to read: each entry is an observable condition that should prompt re-evaluating this choice. `if the script's shebang stops being bash. if a second shell body appears in the script. if a live run shows "$BASH" unusable inside unshare -rn (a bash outside the namespace's view).`

### DD-2: when the plain fallback's warning is printed

| # | Candidate | Hard constraints | Notes |
|---|---|---|---|
| a | At run time only, before the banner; `--no-loopback`'s stays where it is (selection time, so on probes too) | passes | `--probe` unchanged for every input; one warning per run on every route to unshare |
| b | At selection time for both, so a fallback `--probe` warns too | fails the brief ("no change to ... `--probe`") | consistent between the two routes, and the reading a CI job gating on the probe might want |
| c | Move both to run time | fails the brief (a `--no-loopback --probe` loses its warning; a test pins it) | |

One survivor. **Path A: a.** The asymmetry it leaves (a `--no-loopback` probe warns, a fallback probe does not) is recorded under "Observations" for the cycle; moving the call is one line if the owner prefers b.

Other choices, one line each:

- One source for the text: a function `warn_unshare_only HEADLINE WAY-BACK...` that prints the headline, the four shared lines from a quoted heredoc, then the way back to bwrap's profile, which differs by route ("Drop the flag" against "Install bwrap"). A variable holding the text, or a mode argument, would do the same with more indirection.
- The fallback headline says whether bwrap is not installed or was refused (`command -v bwrap`, which runs nothing): the two need different actions from the reader.
- `--no-loopback` with bwrap unavailable prints the fallback warning, not the `--no-loopback` one: dropping the flag there would not bring bwrap's profile back, so "Drop the flag" would be false. Today that route prints no warning at all.
- The `--no-loopback` warning is re-wrapped so the shared sentences end on line boundaries: its words are unchanged, its line breaks are not. Its first line, which the tests and any reader key on, is byte-identical.
- The body's `$0` is `confine-tests`, so bash's own errors read `confine-tests: line 6: exec: -a: not found`, like the script's other messages.
- `sh` leaves the tests' built PATH: the script no longer needs it, and an absent `sh` is the strictest stand-in (a call fails the run). The two D1 tests put the real bash and the real dash there under that name.
- The dash test skips, loudly, on a host without dash: dash is not a file in this repo (decision 023 is about those), and the bash test and every other unshare test still run there.

## Plan

Approach: tests first, against the unfixed script, so each new assertion is seen to fail for the reason it names; then the two fixes as one commit each; then the docs. The body moves from `sh` to `"$BASH"` with `exec -- "$@"` (DD-1), and the warning becomes one function called from two places (DD-2).

Steps:

1. This doc. ~250 lines, docs.
2. `test/scripts/confine-tests.bats`: new tests for D1 (`sh` as bash, `sh` as dash, a command named like a builtin) and D2 (fallback warning on a run, both causes; one source; nothing on a probe; refusals unwarned), and the existing unshare tests moved to the fixed behaviour. ~70 lines added, the file to ~490.
3. `scripts/confine-tests.sh`, D1: the body under `"$BASH"`, `exec -- "$@"`. ~10 lines with the comment.
4. `scripts/confine-tests.sh`, D2: `warn_unshare_only`, its two call sites, the header comment. ~35 lines.
5. `guides/test-hermeticity.md`: the `Relevant paths:` line, and a paragraph on the fallback. ~6 lines.
6. Gates: the file alone, a mutation run on scratch copies, the hermeticity lint, shellcheck, the whole suite to a file.
7. pr-prep's failure-pattern advisory and the review-fix loop; results into this doc; the brief's status line; the marker.

Implementation order: `1 → 2 → [3, 4] → 5 → 6 → 7`.

Size estimate: about 120 changed code lines outside `docs/`, under the ~400 entry cap. No file passes 500 lines.

Estimated context cost: Research ~60k, Implementation ~40k, Review ~40k of this session's own tokens (review agents' totals are reported apart).
Actual context cost (post-implementation): __

`/pre-mortem`: not triggered (not an enforcement file, under 500 lines, no irreversible step). The change does sit at a trust boundary in the sense of decision 018 (text handed to a subprocess), so "Failure modes considered" below is filled in. `/architecture-review`: not triggered (one script and its test; no module boundary moves).

### Test specification

`test-strategy` was not run as a separate skill: the brief's acceptance lines are the test plan, and a subagent pass would restate them (S2: no new dispatch without a stated gain). No gaps surfaced by `test-strategy` — manual test specification follows.

| Gap | Test case | Expected behaviour | Level | On failure shows |
|---|---|---|---|---|
| G1 (D1) | `-- -record -x` on the unshare form, `sh` linked to bash, and again linked to dash | the file `-record` runs with `-x`, exit status is the child's, same pid | characterization, then regression | status, both streams, every stand-in's argv (`teardown`) |
| G2 (D1) | `-- -a x RECORD one`, both shells | exit 127, `exec: -a: not found`, the child not run | regression | the same |
| G3 (D1) | `-- eval 'touch pwned'` with a file named `eval` on PATH | the file runs with that one argument; no `pwned` | regression | the same |
| G4 (D1) | the unshare call's argv | `-rn -- <the script's bash> -c BODY confine-tests CMD...`, BODY the same for two commands | characterization | the same |
| G5 (D2) | a fallback run, bwrap not installed; bwrap installed and refused | the warning first, its headline naming the cause, then the banner; the child runs; status unchanged | regression | the same |
| G6 (D2) | the shared lines | identical between the fallback warning and the `--no-loopback` one; printed once, on stderr | regression | both texts |
| G7 (D2) | `--probe` on a fallback; `--no-loopback --probe` with bwrap unavailable | stderr empty, verdict unchanged | characterization | the same |
| G8 (D2) | `--no-loopback` with bwrap working | its own warning first, not the fallback's | characterization | the same |
| G9 (D2) | fallback and no `ip`; fallback and no command | the refusal alone, no warning | characterization | the same |

### Failure modes considered

| Failure | Guard |
|---|---|
| The fix is right under this container's `sh` and wrong under another | G1 and G2 run with `sh` as bash and as dash; the body no longer runs under `sh` at all, and with no `sh` on the built PATH any call of it fails every unshare test |
| The new last line runs a builtin or a function in place of the named file | G3 |
| The warning changes a probe's output and a brief that gates on `--probe` reads it differently | G7 pins the fallback probe's stderr empty |
| The two warnings drift apart in a later edit | G6 compares their shared lines; the text exists once in the script |
| A test passes because a stand-in accepts too much | the stand-ins are unchanged (any unlisted argv fails the test); the mutation run |

### Risks

- No live run: a real `unshare -rn` has not started `"$BASH"` here. The path is the one the kernel already ran the script from, and `-r` maps the caller to root in the namespace, so reading it cannot be refused by a permission the caller had; that is inference, not observation [inferred].
- Decision 018 and `CLAUDE.md` cite `scripts/confine-tests.sh:220`; the line moves. Both files are outside this brief's Paths (a decision record and an instruction file, both on the self-merge floor). Recorded under "Follow-ups".
- Deferred coverage: `set -e` and `pipefail` in the script are still unpinned (first unit's "Not covered"); out of this unit's scope.

### Rollback

`git revert -m 1 <this branch's merge commit>` restores the script, the test file, the guide, this doc's absence and the brief's status line. Nothing else needs undoing: the script has no caller in code, `test/` is not installed, and the guide reaches `~/.claude/guides/` only through the next install, which a revert before it makes a no-op and a revert after it undoes at the following install.

## Probes

Both are bash script files run under `timeout` from a scratch directory they create and enter themselves; neither touches the repo.

Probe 1 (`probe1.sh`): a directory with recording commands named `-rec`, `rec`, `eval` and `a=b` first on PATH; for `sh` linked to bash and to dash, `SH -c BODY sh WORDS...` for each BODY in `exec "$@"`, `exec -- "$@"`, `command -- "$@"`, `"$@"`, `exec env -- "$@"` and each WORDS in `-rec -x`, `-a x rec one`, `eval echo hi`, `-nonexistent y`, `a=b z`. Results are in the tables above. (Its status column was wrong, a `PIPESTATUS` read inside a command substitution; the conclusions rest on the output text.)

Probe 2 (`probe2.sh`): a script with the shebang `#!/usr/bin/env bash` that prints `$BASH` and its pid, then `exec "$BASH" -c 'echo ...; exec -- "$@"' bash "$@"`, run under `env -i` on a PATH holding a symlink to bash. Results are under "Gotchas".

## Files read

Last verified: 2026-11-10
scripts/confine-tests.sh
test/scripts/confine-tests.bats
guides/test-hermeticity.md
guides/doc-freshness.md
docs/working/research-2026-11-10-confine-tests-bats.md
docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md
docs/constraints.md
docs/failure-patterns.md
docs/decisions/log.md
docs/decisions/018-argv-exec-over-shell-string-interpolation.md
workflows/research-plan-implement.md
workflows/pr-prep.md
workflows/review-fix-loop.md
workflows/divergent-design.md
scripts/build-loop.sh
scripts/lib/dev-cycle-read.sh
scripts/run-tests.sh
scripts/health-check.sh
hooks/live-verify-gate.sh
