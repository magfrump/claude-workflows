# Research and plan: two fixes in `scripts/confine-tests.sh` (a dash-named command, a silent fallback)

- **Goal**: Fix the two defects the script's first tests recorded: a test command whose name starts with `-` is misread on the `unshare` path when `sh` is bash (D1), and a plain fallback from `bwrap` to `unshare` runs without saying what `unshare` does not confine (D2); and list the test file in the guide.
- **Problem framing**: The script the repo rules name as the reference for passing untrusted text to a subprocess hands the command to whatever `sh` is, and what `exec "$@"` means depends on that shell; and it warns about the weaker `unshare` profile on one of the two routes that reach it. Considered and discarded: "D1 is a missing `--`, so add it to the `sh` body". dash's `exec` runs `--` as the command, so no one spelling of the last line is right under both shells; the problem is the choice of interpreter, not the spelling.
- **Project state**: this branch changes the script's `unshare` run form and its warning, the test file and one guide · second of the confine-tests follow-ups, after `test/confine-tests-bats` (merged at 9d6d6101) · not blocked (cite: docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md)
- **Task status**: in-progress (implemented; two review passes done and their fixes in; a check of the last fixes next)

Brief: `docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md` · Branch: `fix/confine-tests-dash-and-fallback` from 23ffb16c · Date: 2026-11-10

This one file holds the research, the design record and the plan, as the first unit's did (`docs/working/research-2026-11-10-confine-tests-bats.md`): the brief names it as this unit's record, and a decision record under `docs/decisions/` is outside the brief's Paths.

## What exists

`scripts/confine-tests.sh` at 23ffb16c (227 lines, bash, `set -euo pipefail`) [observed, read in full]. The first unit's research doc describes all of it; the parts this unit changes:

1. **Detection** (lines 79-118): `detect_primitive` prints `bwrap` when `bwrap --ro-bind / / --unshare-net -- true` exits 0, else `unshare` when `unshare -rn true` does, else fails and the script refuses with exit 3. After it, `primitive` is `unshare` only because bwrap is not installed or its probe failed: that is the plain fallback.
2. **The `--no-loopback` switch** (134-152): with `primitive=bwrap` and the flag, the script switches to `unshare` and prints a seven-line warning (six `echo`s after the headline) that unshare "denies the network and NOTHING ELSE". This is the only place that text is printed. It runs before `--probe` answers, so a `--no-loopback --probe` prints it too.
3. **The run** (176-227): a one-line banner, then one of three `exec`s. bwrap and `--no-loopback` put `--` before the command. The third, `unshare` with loopback, is `exec unshare -rn -- sh -c '<static body>' sh "${cmd[@]}"`; the body raises `lo`, exits 3 if that fails, and ends in `exec "$@"`.

`test/scripts/confine-tests.bats` (420 lines, 17 tests) runs the script under `env -i` on a PATH of stand-ins for `bwrap`, `unshare` and `ip` plus symlinks to the real `bash`, `sh`, `cat` and `awk`. It pins a dash-named command on the bwrap and `--no-loopback` forms only, and leaves the fallback warning's absence unpinned on purpose (three assertions were loosened for it in the first unit's review).

Callers: none in code [observed: `grep -rn confine-tests` over `*.sh`, `*.bats`, `*.py`]. Decision 018 (`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117`) cites `scripts/confine-tests.sh:220`, and `CLAUDE.md` names the script without a line, as the reference for "static shell body, values as positional arguments".

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

Reproduction: in the test file's harness, `confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one` exits 0 with one line on stderr, `confine-tests: denying network via unshare (loopback=1)` [observed in the first unit's doc; at 23ffb16c this unit's test 15 fails on the missing warning, and test 20, the fallback warning's own test, fails earlier there because the built PATH has no `sh`]. Root cause: the warning is inside the `primitive == bwrap && loopback == 0` branch (line 134), so the route "bwrap missing or refused" never reaches it. Location: lines 134-143.

## Invariants

- Which primitive is chosen, every exit status other than D1's, and `--probe` (stdout, stderr and status, for every input) do not change (brief). The tests pin this: the selection tests keep their status, verdict and call-count assertions (two gained checks of stderr), the fallback probe's stderr is pinned empty, and the `--no-loopback` probe's stderr is compared with the whole old warning, byte for byte. Three statuses for a command that cannot be run, or could not be, do move outside the dash-named cases; see "Exit statuses" under Results.
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
- `$BASH` is the path of the bash running the script: `<PATH dir>/bash` when the script starts through its shebang, the interpreter's path when started as `bash script` [observed, probe 2]. `"$BASH" -c '... exec -- "$@"'` keeps the pid, returns the command's status, and exits 127 for a name not on PATH (`-a` among them) and 126 for a directory given as a path [observed, probe 2].
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

Prior pruning grep (`exec|argv|dash|unshare|confine` over the lines after each `Pruned candidates` heading in `docs/decisions/*.md`): eight lines match, in decisions 014, 015, 017, 028, 030, 035 and 037. One names this script: decision 017's `[4 bwrap confine-tests as an in-session gate]`, pruned there because a session has no primitive. It is about where the runner runs, not how its body hands over a command, and is not a candidate here [carried from 017-polyglot-test-hermeticity: primitive absent in a session]. The other lines match a keyword inside candidates about other subjects (review cost, install gating, tool guidance, process isolation). None is about how a shell body execs its arguments; decision 018 chose the static-body pattern and is carried as candidate 0.

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
| 5 | ✗ | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ~ | pruned: a name holding `=` is read as an assignment (`a=b z` set a variable and tried to run `z`) |
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

**Pruned candidates and why.** How to read: each entry is `[candidate]: one-line reason for discard`; a later design pass on shell bodies can grep this section. `[0]: is the defect.` `[1]: leaves -a x CMD running CMD with exit 0.` `[3], [4]: command and a bare "$@" run builtins, so eval as a first word executes the rest as shell code.` `[5]: env reads NAME=VALUE words as assignments.` `[6]: per-shell special cases, untestable beyond bash and dash.` `[7], [8], [14]: change exit statuses or the primitive, which the brief forbids.` `[9]: more code and a changed argv[0] for the same result.` `[10]: hidden flag and second entry point.` `[11]: new file outside Paths.` `[12]: unshare has no such option.` `[13]: a second PATH lookup for the interpreter already running.` Prior pruning grep: matches in seven decisions, one of them naming this script (`[4 bwrap confine-tests as an in-session gate]`, carried from 017-polyglot-test-hermeticity: primitive absent in a session), none about how a body execs its arguments; see the opening of DD-1.

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

- One source for the text: a function `warn_unshare_only HEADLINE FIRST-WORDS LINE...` that prints the headline, the shared text, then the way back to bwrap's profile, which differs by route ("Drop the flag" against "Install bwrap"). The way back starts on the shared text's last line, as it always did in the `--no-loopback` warning, so its first words are an argument of their own. A variable holding the text, or a mode argument, would do the same with more indirection.
- The fallback headline says whether bwrap is not installed or is unusable (`command -v bwrap`, which runs nothing): the two need different actions from the reader ("Install bwrap" against "Run on a host where bwrap works"). "Unusable here" is the script's existing word for a primitive that does not work (its `--no-loopback` refusal says `unshare -rn` "is unusable here"); a first version said "refused", which the script keeps for its own refusals (review pass 1, API finding 3).
- `--no-loopback` with bwrap unavailable prints the fallback warning, not the `--no-loopback` one: dropping the flag there would not bring bwrap's profile back, so "Drop the flag" would be false. Getting bwrap back would not either while the flag stays, so on that route the way back names both steps ("Install bwrap (bubblewrap) and drop --no-loopback", or "Run on a host where bwrap works and drop --no-loopback"; review pass 1, security finding 2). At 23ffb16c that route printed no warning at all.
- The `--no-loopback` warning is byte for byte what it was. A first version re-wrapped it so the shared sentences ended on line boundaries; review pass 1 showed that this changed the stderr of a `--no-loopback --probe`, which the brief's "no change to `--probe`" forbids, so the line breaks went back and the function took the shape above.
- The body's `$0` is `confine-tests: unshare body`, so bash's own errors read `confine-tests: unshare body: line 6: exec: -a: not found`: the script's prefix, then where the line number counts from (the body, not the file; review pass 1, API finding 4).
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
| G4 (D1) | the unshare call's argv | `-rn -- <the script's bash> -c BODY 'confine-tests: unshare body' CMD...`, BODY the same for two commands | characterization | the same |
| G5 (D2) | a fallback run, bwrap not installed; bwrap installed and unusable (the stand-in's `refused` mode) | the warning first, its headline naming the cause, then the banner; the child runs; status unchanged | regression | the same |
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
- Decision 018 cites `scripts/confine-tests.sh:220`; the line moves (`CLAUDE.md` names only the file, so nothing there goes stale). The decision record is outside this brief's Paths and on the self-merge floor. Recorded under "Follow-ups".
- Deferred coverage: `set -e` and `pipefail` in the script are still unpinned (first unit's "Not covered"); out of this unit's scope.

### Rollback

`git revert -m 1 <this branch's merge commit>` restores the script, the test file, the guide, this doc's absence and the brief's status line. Nothing else needs undoing: the script has no caller in code, `test/` is not installed, and the guide reaches `~/.claude/guides/` only through the next install, which a revert before it makes a no-op and a revert after it undoes at the following install.

## Probes

Both are bash script files run under `timeout` from a scratch directory they create and enter themselves; neither touches the repo.

Probe 1 (`probe1.sh`): a directory with recording commands named `-rec`, `rec`, `eval` and `a=b` first on PATH; for `sh` linked to bash and to dash, `SH -c BODY sh WORDS...` for each BODY in `exec "$@"`, `exec -- "$@"`, `command -- "$@"`, `"$@"`, `exec env -- "$@"` and each WORDS in `-rec -x`, `-a x rec one`, `eval echo hi`, `-nonexistent y`, `a=b z`. Results are in the tables above. (Its status column was wrong, a `PIPESTATUS` read inside a command substitution; the conclusions rest on the output text.)

Probe 2 (`probe2.sh`): a script with the shebang `#!/usr/bin/env bash` that prints `$BASH` and its pid, then `exec "$BASH" -c 'echo ...; exec -- "$@"' bash "$@"`, run under `env -i` on a PATH holding a symlink to bash. Results are under "Gotchas".

## Results

### What the branch changes

- `scripts/confine-tests.sh`: the `unshare`-with-loopback body runs under `"$BASH"` and ends `exec -- "$@"` (D1); `warn_unshare_only` holds the warning's text once and is called from the `--no-loopback` switch and, on a run, from the fallback (D2); the header comment says both.
- `test/scripts/confine-tests.bats`: 17 tests become 21. Four are new (a dash-named command with `sh` as bash and as dash, a command named like a builtin, the fallback's warning); the unshare tests that had left the warning's absence unpinned now pin where it appears and where it does not.
- `guides/test-hermeticity.md`: the `Relevant paths:` line and a paragraph on the fallback.

### Exit statuses

On the `unshare`-with-loopback form, by what `sh` was at 23ffb16c [observed: the tests, probe 1, and the old-against-new runs of both review passes, the final pass's on up to 4,536 runs per reviewer; a row marked * was run by a reviewer and not by me]:

| Command | 23ffb16c, `sh` is bash | 23ffb16c, `sh` is dash | This branch, any `sh` |
|---|---|---|---|
| `-record -x` (a file `-record` is on PATH) | 2, refused (`exec: -r: invalid option`) | the command's own | the command's own |
| `-a x CMD one` | CMD's own: **CMD ran** | 127 | 127 |
| `-- CMD` (the name is `--`) * | CMD's own: **CMD ran** | 127 | 127 |
| `-p CMD` * | 2 | 127 | 127 |
| `-nonexistent y` | 2 | 127 | 127 |
| `''` (an empty name) | 127 | 126 (`exec: : Permission denied`) | 127 |
| a bare name that matches a directory found through PATH * | 127 | 126 (`exec: adir: Permission denied`) | 127 (`exec: adir: not found`) |
| any command, on a host with no `sh` on PATH * | 127 (`unshare` cannot start `sh`) | the same | the command's own |

A directory given as a path, and a file without the execute bit, exit 126 before and after.

The first five rows are D1: names that start with "-". The last three are statuses that move outside the dash-named cases. The brief allows no status change "other than D1's". I count these three as D1's consequences: each follows from the fix itself (the body no longer runs under `sh`), the old status was whatever that host's `sh` gave (bash as `sh` already gave 127 for the empty name and the directory), and no fix that takes `sh` out keeps a status only dash gave. Keeping dash's two 126s would mean imitating dash's PATH search inside the bash body, which DD-1 pruned as candidate 9's kind of code. The review found all three (pass 1's API critic the empty name; the final pass's fact-check the directory and the API critic the host with no `sh`).

One disagreement remains between run forms, and it is in the second of those rows: for a bare name that matches a directory on PATH, the loopback form now exits 127 where a real `unshare` on the `--no-loopback` form would exit 126 (the final pass's API critic modelled the real tools' `execvp`; the test file's stand-ins exec through bash and cannot show it). Every other input the two passes compared, on every route, exits as before, and every `--probe` is byte for byte the same in stdout, stderr and status.

### Mutation run

Each mutant is a scratch copy of the script with one change, run against the repo's test file from a scratch tree (the repo's script is never edited). On the final script, 24 of 24 fail at least one test, and the unchanged script passes 21 of 21:

| Mutant | Fails tests |
|---|---|
| the body under `sh` again, `exec --` kept | 16, 18, 19, 20, 21 (17, `sh` is bash, passes: bash as `sh` takes `--`) |
| the old line: `sh -c`, `exec "$@"` | 16, 17, 18, 19, 20, 21 |
| `exec "$@"` without `--`, under `"$BASH"` | 17, 18 |
| a bare `"$@"`; `command -- "$@"` | 17, 18, 19 (each) |
| `bash` by name in place of `"$BASH"` | 16 |
| the body's `$0` back to `confine-tests` | 16, 17, 18 |
| the fallback warning removed | 15, 20 |
| the fallback warning at selection time (so on probes and before refusals) | 14, 15, 20 |
| the fallback warning on stdout | 15, 16, 17, 18, 20, 21 |
| the fallback warning after the banner | 15, 16, 20 |
| the fallback warning printed twice | 20 |
| the test for an installed bwrap negated, so the two fallback headlines and ways back swap | 15, 20 |
| the `--no-loopback` warning removed | 11, 12, 20 |
| `--no-loopback` without bwrap prints the flag's warning | 15, 20 |
| an extra line printed on the fallback routes, between the shared text and the rest of the way back | 15, 20 |
| the fallback refuses (exit 3) after warning | 15, 16, 17, 18, 19, 20, 21 |
| the shared text loses its uid 0 clause | 11, 15, 20 |
| the way back's later lines dropped | 11, 15, 20 |
| the way back's first words dropped | 11, 20 |
| the shared sentence ends its own line, the way back starting on the next (one of the first version's line breaks) | 11, 15, 20 |
| neither fallback route says to drop `--no-loopback` | 15, 20 |
| only the unusable-bwrap route omits it | 20 |
| only the not-installed route omits it | 15 |

Test numbers are positions in the file: 11, 12 and 13 are the `--no-loopback` tests (13, the flag's refusal, fails under no mutant here: none touches that branch), 14 the fallback probe, 15 unshare without `ip`, 16 the unshare run's argv, 17 and 18 the dash-named command with `sh` as bash and as dash, 19 the builtin's name, 20 the fallback's warning, 21 `lo` not raised.

Three runs came before this one. In the first, a mutant that printed one extra line on the fallback route (the run's log names it "the shared text differs on the fallback route"; its code was replaced when the warning changed shape) passed every test: the comparison of shared text stopped at its fourth line. The test was strengthened (ca6cf3be), and the second run had no survivor (19 of 19). After review pass 1 changed the warning's shape, the mutants were rewritten for it and three were added (22 of 22). The final pass's security critic then showed that removing the flag note from the unusable-bwrap route alone passed every test; test 20 gained that route and the last two mutants were added.

The test of the whole `--no-loopback` warning (test 11) also passes against the script at 23ffb16c: the text it compares is the old text, which is what "no change to `--probe`" means on that route.

### Gates

| Gate | Result |
|---|---|
| `scripts/confine-tests.sh --probe` | exit 3 (first line quoted under "What exists"): nothing in this branch ran confined |
| `timeout 300 bats test/scripts/confine-tests.bats` | 21 of 21 pass (the dash test runs here; it would skip on a host without dash) |
| `scripts/hermeticity-lint --root .` | exit 0: "143 test file(s) checked, no unstubbed network spawns" |
| `shellcheck -x -e SC1091 -s bash -S warning` on the script and the test file (the health check's command) | exit 0 |
| `scripts/run-tests.sh` (whole suite, output to a file; one file at a time, the runner's default) at ca6cf3be, before review | exit 0: 2012 `ok` lines and no `not ok`. Two of the 2012 are skips that are not this branch's (tests 1190 and 1191: "settings file has no permissions.allow array"), and the runner lists 50 report-dependent suites as NOT RUN, which is its own report gating |
| `scripts/lite-review.py --range de1f4bf9..bd312d15 --mode fix-drift` (the drift check on review pass 1's fixes) | "FINDINGS: NONE" |

### Review

`docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md` has every finding of the three iterations and what was done with it.

Pass 1 (iteration 1 of 3) at de1f4bf9: one fact-check, then security, performance and API-consistency critics. No red. What it found, and what changed:

- The first version re-wrapped the `--no-loopback` warning, so a `--no-loopback --probe` printed the same words with different line breaks: a change to `--probe`, which the brief forbids. Fixed in code (the old line breaks are back; a test compares the whole text). The API critic advised correcting the claim and keeping the re-wrap; the brief's line is the stricter reading and costs one function argument, so I took it.
- With `--no-loopback` and no usable bwrap, the fallback's way back ("Install bwrap") was not enough while the flag stayed. It now says to drop the flag too.
- "refused here" became "unusable here", the script's own word for a primitive that does not work; the body's `$0` became `confine-tests: unshare body`; the header's sentence on when `--no-loopback` warns now says "where bwrap works"; the guide says "the first line of its stdout".
- Four wrong or loose sentences in this doc and the pre-mortem (that the repo rules file cites a line number; "ran `z`"; "238 code lines"; the invariant about `--probe`).

The final confirming pass (iteration 2 of 3) at bd312d15, on the whole branch: three fact-check replicates, then the three critics. No red, and nothing wrong in what the script does: each replicate ran the old script against the new on 1,650 to 2,268 inputs (the largest set is 4,536 runs, counting both scripts) and found every `--probe` byte-identical and the primitive unchanged. It found:

- One amber that no change on this branch settles (security, Medium): constraint H2 says a degraded primitive "refuses and names what went unenforced", and the fallback to unshare runs and names. The brief keeps the run and puts a refusal out of scope, so the code stays; the question is in the marker for the owner (see "Observations for the cycle").
- This doc's record of exit statuses was short by three cases (the directory through PATH, two more dash-named inputs, a host with no `sh`). The table above now has them.
- The "and drop --no-loopback" wording was tested on one of its two routes. Test 20 now runs the other, and two mutants pin each.
- The unusable-bwrap warning sent a reader on a CI runner "where bwrap works (a CI runner or a dev host)", and its headline ran to 101 characters. Both are reworded.
- Twelve wrong, stale or loose sentences in this doc and the pre-mortem, among them two search results reported as narrower than they were (the pre-mortem's prior-art grep, DD-1's prior-pruning grep), the test-plan row that still named the old `$0`, and the whole-suite count given without its two skips.

Pass 3 (iteration 3 of 3) at 6276e42c: one fact-check scoped to the final pass's fix commit, which also gave verdicts on the eight claims the critics had routed (that no word of the command is spliced into the body, that every route to unshare warns first and a warning that cannot be written stops the run, that the stand-ins accept only the script's own calls, and five more). The drift check had declined that commit for size (339 KB with six review reports in it), so this was the fuller path. Nothing wrong in the script or the tests, and the routed claims held wherever they could be run. It found:

- One miscount, in four places: ten tests, not four, skip as uid 0 under the fallback. One of the four locations I had listed is a helper that seven tests call.
- Four smaller points: a count of the reviewers' runs given in mixed units; the guide's "prints the same warning" (the flag's warning has its own headline); a test comment's "the test above" (it is four tests up); no status assertion on test 20's new route.

All are fixed in the commit after the pass-3 report. This is the cap. No fourth pass was started, so the cap's decision gate did not arise: after iteration 3 no red remained, and the one open amber is the owner question below, which no change on this branch settles. The last fixes were checked by re-running the test file and by the drift check over that commit alone.

Sentences in commit messages cannot be changed and stand as written. Each is listed in the rubric: d03a3078 says each of its seven failing tests fails "for the reason it names" (the fallback test fails earlier there, on `exec: sh: not found`); 6465a156 says `--probe` is unchanged for every input (true from bd312d15 on) and paraphrases H2 without "refuses"; ca6cf3be says the way back "must now start on the sixth line" (true until bd312d15); bd312d15's Notes name only the empty name among the statuses that moved; 6276e42c gives the reviewers' runs as "1,650 to 4,536" (the first counts one script's runs, the second both scripts').

No row was added to `docs/reviews/override-log.md` for what was not changed: that file is outside this brief's Paths and on the self-merge floor. The rubric lists each one.

### The first doc's smaller observations

The brief keeps three of them out of scope and asks whether a fix here touches one. None does: the probe still asks bwrap for less than a run does (O1; the stand-in's two accepted argv shapes are unchanged), no primitive and no command still exits 3 (O3; pinned nowhere, as before), and the bwrap profile is untouched (O5).

## What a stub cannot show

As in the first unit: no test here creates a namespace. In particular nothing shows that a real `unshare -rn` starts `"$BASH"`, that `unshare -r` makes the tests uid 0, or what a real bwrap or unshare exits with when the command cannot be run (the test file's stand-ins exec it themselves; the final pass's API critic modelled bwrap as exiting 1 and unshare as 127 or 126, which is a model, not a run).

## Observations for the cycle

- **Constraint H2 and the fallback.** `docs/constraints.md` H2 reads: "a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive refuses and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access." When bwrap is unusable the script falls back to unshare, which confines less, and runs. This branch adds the naming; the brief says the run "still goes ahead" and lists "a refusal in place of the fallback" as out of scope, and the brief's own sentence about H2 leaves "refuses" out. The final pass's security critic rates the gap Medium: a run on that tier can write to the host as uid 0 and exit green. Whether the unshare tier should refuse, refuse unless asked for, or stand as a recorded exception to H2 is the owner's call; the question is in this branch's marker.
- **A fallback `--probe` says nothing about the weaker profile.** It prints `primitive available: unshare (loopback=1)` and exits 0. The brief keeps `--probe` unchanged, so this unit did not touch it (DD-2). It belongs to the same question: moving the warning's call to selection time is one line, and would also make a `--no-loopback` probe and a fallback probe behave alike.
- **Under the unshare fallback the suite runs as uid 0**, so ten tests here skip on the guard `[ "$(id -u)" -ne 0 ] || skip`: one each at `test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889` and `test/install-host.bats:680`, and the seven that call the helper `not_root()` (`test/cc-isolated-functions.bats:1970`). An eleventh probably skips too, for another reason (`test/scripts/build-loop-orchestrator.bats:394` checks an owner uid that `unshare -r` leaves unmapped; inferred by a reviewer, not run). A "passes confined" from that tier covers fewer tests than the unconfined gate (pre-mortem, narrative 1).
- **The test file is 527 lines**, past the 500-line guideline and the plan's "no file passes 500": the review's fixes added the whole-warning constant, exact comparisons and one more route. It is one cohesive file; splitting it would duplicate the harness at its top.

## Question for the owner (also in the ready marker)

The choice is a divergent-design Path C: no option wins on the constraints alone (H2, a hard constraint, favours a refusal; the brief, which binds this unit, keeps the run), so the branch proceeds on the brief's pick and asks.

What the script does. `scripts/confine-tests.sh` runs a test command with the network cut off. It has two ways to do that. bwrap also makes the root filesystem read-only and gives the tests a private `/tmp`. unshare cuts the network and nothing else: the tests run as uid 0 and can write to the real filesystem. When bwrap is not installed or does not work, the script falls back to unshare and runs the tests.

What this branch did. The fallback used to run without a word. It now prints a warning first that names what unshare does not confine. That is what the brief asked for: it says the run still goes ahead, and it lists a refusal as out of scope.

What the review found. Hard constraint H2 in `docs/constraints.md` (the rule that a gate fails closed) reads: "a ... degraded primitive refuses and names what went unenforced ... degradation only ever narrows access". A fallback that runs with less confinement names, and does not refuse. The gap is older than this branch; the branch narrows it and does not close it. The security reviewer rated it Medium: a run on a host without bwrap can write to the host and still report a pass.

The question: when bwrap is unusable, should the script keep running under unshare, or refuse?

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| [1] Run and warn (picked) | As merged. Record unshare as a stated exception to H2. | None now; a loop writes the exception. | A host without bwrap gets a pass from a run that could write to it. |
| [2] Refuse unless asked | Without bwrap: exit 3, unless a new flag asks for unshare. | One small follow-up brief. | Hosts with only unshare lose confined runs until the flag is passed. |
| [3] Always refuse | Without bwrap: exit 3. unshare stays only behind `--no-loopback`. | One small follow-up brief. | As [2], with no way to opt in. |

Tentative pick: [1]. Tiebreaker: the brief chose it, and nothing calls the script yet, so no run is exposed while the question is open. The same answer settles one smaller point: on a fallback, `--probe` exits 0 and prints no warning; under [2] or [3] it would refuse too. Interim: [1], as merged. If the answer differs: one small brief changes the fallback and its tests; nothing in this branch is redone.

## Follow-ups (outside this brief's Paths)

- `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43,117` cite `scripts/confine-tests.sh:220`, which is no longer the pattern's line. The comment above the body now opens "Decision 018's reference pattern", a phrase a citation can name without a line number.
- `docs/roadmap.md:49` words the probe step for new briefs as "exit 0: tests pass confined". Once a probe names `unshare`, the step should also ask for the run's first stderr line.
- The first live run (the sandbox's, when it merges) should confirm that `"$BASH"` starts under a real `unshare -rn`, and count which tests skip as uid 0 on the unshare tier (ten are known by their guard, an eleventh is likely).
- A failure-pattern entry for D1's shape (bash's `exec` reads a command's dash-leading first word as an option; dash's `exec` takes no `--`; so `exec "$@"` under `sh` is host-dependent) may be worth the cycle's adding: this unit could not write `docs/failure-patterns.md`.

## Docs

The script's header comment (which `--help` prints) and `guides/test-hermeticity.md` describe the fallback and its warning. The guide's `Last verified:` date is not moved: only its lines about `confine-tests.sh` were checked against the code.

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
