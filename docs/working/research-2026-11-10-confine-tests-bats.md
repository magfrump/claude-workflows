# Research and plan: a first bats test for `scripts/confine-tests.sh`

- **Goal**: Give `scripts/confine-tests.sh` its first test file, `test/scripts/confine-tests.bats`, pinning what the script does today wherever that is right.
- **Problem framing**: The script that decision 017 calls the real enforcement of test hermeticity has no test, and it is about to matter (the image gains `bwrap` when the cc-isolated sandbox merges). Considered and discarded: "the script has never run with a primitive, so get it a live run first". A live run needs a host or the unmerged sandbox, and it would show one profile once; it would not pin the refusals, the usage errors or the argv handling, which can all be tested here today.
- **Project state**: this branch adds one test file, this doc and its review loop's reports under `docs/reviews/` · standalone, first of the confine-tests follow-ups · not blocked (cite: docs/working/research-2026-11-07-confine-tests-situation.md)
- **Task status**: in-progress (review loop at its cap of three iterations: the third, a check of the final pass's fixes, is done and its own fixes made; the last gate and the brief's status line remain)

Brief: `docs/working/briefs/2026-11-10-confine-tests-bats.md` · Branch: `test/confine-tests-bats` from a37733cc · Date: 2026-11-10

## What exists

`scripts/confine-tests.sh` (227 lines, bash, `set -euo pipefail`) [observed, read in full]:

1. **Flags** (lines 53-71): `--probe`, `--no-loopback`, `--` (everything after it is the test command), `-h`/`--help` (prints the header comment with `awk`, exit 0). Anything else: `unknown flag`, usage line, exit 2. This runs before any primitive is tried.
2. **Detection** (79-118): `bwrap --ro-bind / / --unshare-net -- true`, then `unshare -rn true`; the first that exits 0 wins. Neither: a long message on stderr starting `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`, exit 3, for a probe and for a run alike.
3. **`--no-loopback` over bwrap** (134-152): bwrap always raises `lo`, so the flag switches to `unshare` (after its own `unshare -rn true` probe, the only unshare probe when bwrap was detected), with a warning that unshare denies the network and nothing else. When unshare does not work: refused, exit 2.
4. **`ip` check** (159-163): the unshare path with loopback needs `ip`; missing: exit 3.
5. **`--probe`** (165-169): prints `confine-tests: primitive available: NAME (loopback=N)` on stdout, exit 0. A command given with it is not run.
6. **No command** (171-174): `nothing to run`, exit 2. This comes after detection.
7. **Run** (178-227): a banner on stderr, then `exec` of one of three forms: bwrap with a fixed profile and `-- "${cmd[@]}"`; `unshare -rn -- sh -c '<static body>' sh "${cmd[@]}"` (the body raises `lo`, exits 3 if that fails, then `exec "$@"`); or, with `--no-loopback`, `unshare -rn -- "${cmd[@]}"`.

Callers: none in code. The hermeticity lint prints its name, `guides/test-hermeticity.md` documents it, and this brief, like other recent ones that require tests, asks its loop to run `--probe` (the wording for new briefs is in `docs/roadmap.md`; not every open brief has it).

In this container `scripts/confine-tests.sh --probe` exits 3 [observed 2026-11-10]. Its first line:

> `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`

So, as the brief says for exit 3, acceptance rests on `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .`, and nothing in this branch has run confined.

## Invariants

- The script is not changed (brief, out of scope). The tests run the repo's own file through its shebang, never a copy [observed: `SCRIPT="$REPO_ROOT/scripts/confine-tests.sh"`].
- The suite stays hermetic and passes `scripts/hermeticity-lint --root .` (H3). The new file spawns none of `claude`, `curl`, `gh`, `wget`, and writes only under `$BATS_TEST_TMPDIR`.
- Every `.bats` file carries `# @category fast|slow` (`scripts/run-tests.sh` header). This file is `slow`: it executes a script.
- A stub is at least as strict as its tool (repo rule; decision log row 44, where an `iptables` stub that took any argv let a syntax error reach a live container).
- No `skip` on a repo file (decision 023). The file has no `skip` at all.
- A review unit enters its review loop at or under 400 changed code lines outside `docs/` (decision log row 62). The test file was 395 lines at entry, 412 after pass 1's fixes, 419 after the final pass's and is 420 after the last check's, inside the loop's re-check limit of about 800 (`workflows/review-fix-loop.md`, size re-check).

## Prior art

- `test/scripts/run-tests.bats`: runs a script under `env -i PATH=...`, and (line 490) builds a PATH directory of symlinks to leave one tool out. The new file does the same in the other direction: a directory holding only the tools the script needs.
- `test/scripts/build-loop-orchestrator.bats`: `bats_require_minimum_version 1.5.0` and `run --separate-stderr`, used here to tell the stdout verdict from the stderr refusal.
- Decision 018 (`docs/decisions/018-argv-exec-over-shell-string-interpolation.md`) names `scripts/confine-tests.sh:220` as the reference for "static shell body, values as positional arguments". The unshare run test pins exactly that.

## Gotchas

Failure-pattern grep: FP-050, FP-052, FP-058, FP-065, FP-076, FP-155 (see Prior failures)

- The real `unshare` is in `/usr/bin`, beside `bash`. Prepending stubs to the ambient PATH cannot model "not installed", and a call the stub did not expect could fall through to a real tool. The tests use an empty environment and a PATH they build.
- `$PWD` does not pass through `env -i`; a fresh bash sets it to the physical directory. The expected `--bind`/`--chdir` values use `pwd -P`.
- A stub whose shebang is not on line 1 still runs when bash starts it (bash falls back to running the file itself) and fails when `sh` starts it. A first draft had this bug, and the "lo cannot be raised" test passed for the wrong reason. The fix is the shared stub header; the guard is the mutation run below.
- bash's `exec` takes options, and takes `--` to end them. dash 0.5.12's takes neither: it runs `--` as the command. So no one spelling of `exec` is safe under both. This is defect D1 below.
- The health check runs `shellcheck -S warning` over `.bats` files too (`scripts/health-check.sh`, `check_shellcheck`), and shellcheck cannot see that bats sets `$stderr_lines`. Without a file-level `disable=SC2154` (the form `test/hooks/claude-config-audit.bats` uses) the new file failed three tests in `test/scripts/health-check.bats`. I had run shellcheck on the file by hand before the first commit, seen this warning, and wrongly taken it for advice and not a gate. The file alone, the lint and the mutation run all passed; the whole suite is what showed the warning fails the health check.

### Prior failures

The grep was `grep -inE 'confine|hermetic|netns|unshare|bwrap|namespace|stub|argv|shim|skip-not-fail' docs/failure-patterns.md`.

- FP-058 (a bwrap failure at run time dropped the work silently): a test pins that a bwrap that fails at run time fails the run, with no fallback.
- FP-050 (an unshare tier shares the host mount namespace): the script warns about this only when `--no-loopback` forces the switch. See defect D2.
- FP-065 (a suite that skips where it should fail): the file never skips; a missing script fails every test.
- FP-052 (a too-broad write block crashed a font cache) is about the bwrap profile in real use, which stubs cannot show. FP-076 and FP-155 do not apply (a headless read limit; a doc link cycle that matched on the word "stub").

Failure-pattern skip: this branch has no fix(...) commit; it adds a test and changes no behaviour.

## Design choices

Seeded with docs/constraints.md (H1-H4, S1-S11) and the brief's own lines.

### DD-1: how to put the script in front of primitives this container does not have

| # | Candidate | Hard constraints | Notes |
|---|---|---|---|
| a | Stubs prepended to the ambient PATH | fails the brief ("no primitive" must be testable) | cannot model "not installed": the real `unshare` shares a directory with `bash`, and the image gains a real `bwrap` soon; an unexpected call can reach a real tool, which is row 44's failure |
| b | `env -i`, PATH = stub directories + a directory of symlinks to the real `bash`, `sh`, `cat`, `awk` | passes | the same result on any host, before and after the image gains `bwrap`; each test names which stand-ins are installed |
| c | Test a copy of the script edited to take injectable tool names | fails "test a check in its real default position" (repo rule, row 50) | tests the copy |
| d | Source the script and override functions | not possible | the script runs top-level and `exec`s |
| e | Only real primitives, on a host or after the sandbox merges | fails H3 (verifiable in the sandbox) | kept as the complement: see "Not covered" |

One survivor. **Path A: b.**

### DD-2: how strict the stand-ins are

| # | Candidate | Hard constraints | Notes |
|---|---|---|---|
| a | Record-only stub; the test asserts on the record | fails the brief and row 44 ("never accepts any argv") | a probe the stub wrongly accepts changes the script's path before any assertion runs |
| b | Stub accepts only the exact argv shapes the script uses today, under a mode the test names; anything else writes a marker that fails the test | passes | strictest and smallest; a profile change in the script must be made in the test too, which is the point of pinning |
| c | Stub parses the tool's real option grammar (flags and arities) | passes | accepts shapes the script never uses, and its grammar cannot be checked here (no `bwrap`, no man page): more code for no more strictness on today's script (S8) |
| d | b, and the test also asserts the recorded argv against values it computes itself | passes | the stub's own `$PWD` is not trusted to equal the test's working directory |

d contains b and costs four lines. **Path A: d.**

Other choices, one line each:

- A real-position test: one test runs the script on the ambient PATH and accepts either verdict (exit 0 with a well-formed first line, or exit 3 with a refusal and the command not run). A live-run test that skips without a primitive was not written: its green would mean nothing here (H2, present-but-inert), and the first run of its body would be on someone else's merge.
- Call records are NUL-delimited files, one per call, so an empty word and a newline inside a word are both exact.
- On failure, `teardown` prints the status, both streams and every recorded call, because bats shows only the failing line.
- Category `slow` (script execution), matching `test/scripts/run-tests.bats`.

## Plan

Approach: one bats file, written test-first is not possible in the usual sense (the script exists and is not to change), so the tests are characterization tests, checked by mutating scratch copies of the script.

1. This doc (research, design, plan), committed before the test. ~200 lines, docs.
2. `test/scripts/confine-tests.bats`: 17 tests, a new file of 395 lines at the review loop's entry.
3. Gates: the file alone, the mutation run, `scripts/hermeticity-lint --root .`, `shellcheck`, then the whole suite with `scripts/run-tests.sh`, output to a file.
4. pr-prep's failure-pattern advisory and the review-fix loop; fixes as their own commits.
5. Results into this doc; the brief's status line to done; the marker.

Implementation order: `1 → 2 → 3 → 4 → 5`.

Estimated context cost: Research ~40k, Implementation ~60k, Review ~40k.
Actual context cost (post-implementation): __

`/pre-mortem`: not triggered (no enforcement file, no trust boundary changed, under 500 lines). `/architecture-review`: not triggered (one module, `test/`).

### Test specification

`test-strategy` was not run as a separate skill: the brief is itself a test plan, and a subagent pass would restate it (S2). The gaps below are its acceptance lines plus what reading the script added.

| Gap | What was untested | Test (short name) | Level |
|---|---|---|---|
| G1 | `--probe` exit status and first line with no primitive | "neither primitive installed"; "both installed and refused" | characterization |
| G2 | the refusal to run unconfined, and that it names what went unenforced (H2) | the same two tests: exit 3, the command not run, `Your tests were NOT run`, both primitives named | characterization |
| G3 | the script in its real position | "on this machine's own PATH" | integration |
| G4 | usage errors | "unknown flag, or a command given without --"; "no command is a usage error"; "--help and -h" | characterization |
| G5 | the bwrap probe and run | "--probe reports bwrap"; "a bwrap run hands bwrap the whole profile"; "name starts with a dash, and exit status" | characterization |
| G6 | each word of the command as its own argv element, on all three run forms | the bwrap run, the `--no-loopback` run and the unshare run each pass 12 hostile words and compare the child's argv exactly | characterization |
| G7 | bwrap failing at run time (FP-058) | "a bwrap that fails at run time fails the run" | characterization |
| G8 | `--no-loopback` selection, warning and refusal | three tests | characterization |
| G9 | the unshare path: fallback, `ip` missing, `lo` failing, the static `sh` body | four tests | characterization |
| G10 | that the script `exec`s its primitive and the `sh` body `exec`s the command (added in the review loop) | `same_process` in the three run tests: the command's pid is the script's. At the `sh` body this bites only where `sh` is dash (see "Mutation run") | characterization |

Diagnostics: every failure prints the script's status, stdout, stderr and each recorded call with `%q` quoting.

### Failure modes considered

| Failure | Guard |
|---|---|
| A stand-in is too permissive and a test passes for the wrong reason | any call outside the listed shapes, or with no mode set, writes `unexpected` and fails the test in `confine()`; the mutation run |
| The suite's result depends on whether the host has `bwrap` | `env -i` and a built PATH; the one ambient test accepts either verdict |
| A reader takes green tests for proof of confinement | the file's header and "What a stub cannot show" below |
| The tests leave files or processes behind | everything is under `$BATS_TEST_TMPDIR`; nothing is backgrounded |

### Rollback

`git revert -m 1 <this branch's merge commit>` removes the test file, this doc, the review reports under `docs/reviews/` and the brief's status change. Nothing else needs undoing: `test/` is not installed by `devcontainer-config/install.sh`, and no script, hook or image file changes.

## Results

### Mutation run

Each mutant is a scratch copy of the script with one change, run against the test file (the repo's script is never edited). 20 of 21 fail at least one test:

| Mutant | Fails |
|---|---|
| bwrap run without `--unshare-net`; without `--setenv TMPDIR /tmp` | the three bwrap run tests (the stand-in refuses the argv) |
| the command spliced into the `sh` body instead of passed as `"$@"` | the unshare run test |
| the no-primitive refusal exits 0; the refusal runs the command unconfined | the two no-primitive tests and the ambient-PATH test |
| `ip link set lo up` failure swallowed | the "lo cannot be raised" test |
| the bwrap command unquoted (`${cmd[@]}`) | the bwrap run test |
| a bwrap that fails at run time falls back to running the command | the bwrap run tests, the run-fails one among them |
| `unshare -rn` run without `--` before the command | the `--no-loopback` run test and the unshare-without-ip test |
| `--no-loopback` over bwrap-only falls through to bwrap | the `--no-loopback` refusal test |
| the `ip` presence check removed | the unshare-without-ip test |
| `--probe` goes on to run the command | four probe tests |
| `--help` prints every comment in the file | the `--help` test |
| an unknown flag is skipped | the usage-error test |
| an empty command is run | the no-command test |
| the `--no-loopback` warning removed | the two `--no-loopback` tests |
| `exec` replaced by a plain call, at each of the script's four `exec`s: bwrap and `unshare ... sh -c` (each followed by `exit $?`, so the script cannot fall through to its next run form), the `sh` body, and `unshare` direct | the run test of that form, and only through `same_process`: with that one line removed from the tests, all four pass |
| `set -euo pipefail` → `set -uo pipefail` | **nothing** (see "Not covered") |

Three notes on the `exec` row, each found by the review's fact-checks and re-run here:

- Without the `exit $?`, the bwrap and `unshare ... sh -c` mutants also fail, but for another reason: the script falls through to its next `exec`, which makes a call a stand-in does not accept or runs the command a second time.
- Before `same_process` existed (the test file at 9d37c1ac), all four of the row's mutants passed every test. In the plain form without `exit $?`, two passed (the `sh` body and `unshare` direct) and the other two failed only by falling through. I first wrote here that "two of the four survived", which is true of the plain form and not of the row's; the review's last check caught it, and the same wrong sentence stands in the message of commit 7d77df6c, which cannot be changed.
- At the `sh` body the pin holds only where `sh` is dash. With `sh` on the test's PATH linked to bash, the `sh` body mutant passes every test, because bash runs the last command of a `-c` string in place whether or not it says `exec`. On such a host the two spellings behave the same, so there is nothing to tell apart.

Two more copies add a warning to every unshare fallback, which is what a fix for D2 would do: one prints it at run time after the banner, one at selection time before the `ip` check (so on probes too). Both pass every test, as intended: the warning's absence is not pinned.

### Gates

| Gate | Result |
|---|---|
| `scripts/confine-tests.sh --probe` | exit 3 (first line quoted under "What exists"): nothing in this branch ran confined |
| `timeout 300 bats test/scripts/confine-tests.bats` | 17 of 17 pass |
| `scripts/hermeticity-lint --root .` | exit 0: "143 test file(s) checked, no unstubbed network spawns" |
| `shellcheck -x -e SC1091 -s bash -S warning test/scripts/confine-tests.bats` (the health check's own command) | exit 0 |
| `scripts/run-tests.sh` (whole suite, serial) at 9d37c1ac | **red**: 2005 pass, 3 fail, all in `test/scripts/health-check.bats`, all from SC2154 in the new file (see Gotchas) |
| `scripts/run-tests.sh` (whole suite, serial) at f36108e4, after the fix | exit 0: 2008 of 2008 pass. The runner lists 50 report-dependent suites as NOT RUN, which is its own report gating and not something this branch touches |
| `scripts/lite-review.py --range 9d37c1ac..HEAD --mode fix-drift` (the fix-commit drift check) | "FINDINGS: NONE" |

The review loop's outcome is in `docs/reviews/code-review-rubric-2026-11-10-confine-tests-bats.md`.

## What a stub cannot show

No test here creates a namespace. The stand-ins exec the test command unconfined. So these tests do **not** show that:

- the network is denied, for the command or for its children;
- the real `bwrap` accepts the profile (`--dev`, `--proc`, `--tmpfs /tmp`, `--setenv`, `--unshare-pid`), or that bats can run under it;
- `lo` is up after `ip link set lo up`, or down under `--no-loopback`;
- the real `unshare -rn` maps the user and creates the network namespace;
- a nested bwrap works inside the cc-isolated Bash sandbox.

They show what the script asks for and what it does with the answer. The first live run is still to come (the 2026-11-07 research, follow-up 2: a `--probe` and one confined suite in the sandbox's live run).

## Not covered, and why

- A live confined run: no primitive here (exit 3 above).
- The exact text of the long refusal and of the header comment: the tests pin first lines and a few phrases, so wording can change.
- The second line of the probe's output ("network denial is kernel-enforced ..."): it is a claim a stub cannot back.
- D2, O3 and O4 below: behaviour I did not judge clearly right, so no test pins it. For D2 that took the review two rounds. Pass 1 found that an exact match on stderr in an unshare run test pinned the missing warning; the final pass found two more places (an empty-stderr check on the fallback `--probe`, and a first-line check on the `ip` refusal). All now only require the line they are about to be present. For O3 the last check of the review found one more pin: the no-command test counted the probes that ran before the refusal, which fixes the order O3 describes. That count is gone, and a copy of the script that refuses an empty command before detection passes every test.
- O1 and O5 below are about the argv the script hands bwrap. The stand-in pins that argv exactly as it is today (DD-2), so a change to the probe or to the profile means changing the stand-in and the expected argv in the same commit. That pins what the script asks for, not that it is the right thing to ask.
- `set -e` and `pipefail`: a copy of the script with `set -uo pipefail` passes every test. No test makes a command fail in a place where only errexit stops the script.

## Defects found (not fixed here, per the brief)

**D1. On the unshare path with loopback, a test command whose name starts with `-` is misread when `sh` is bash.** The static body ends in `exec "$@"`. bash's `exec` builtin takes options (`-c`, `-l`, `-a NAME`), so the command's first word is read as one. dash 0.5.12 (this container's `sh`) has no `exec` options, so the same calls behave correctly here. The other two run forms put `--` before the command and are fine.

Two failing cases, with the stand-ins of the test file and `sh` on PATH linked to bash:

```
confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- -record -x
status: 2
stderr:
  confine-tests: denying network via unshare (loopback=1)
  sh: line 6: exec: -r: invalid option
  exec: usage: exec [-cl] [-a name] [command [argument ...]] [redirection ...]

confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- -a x "$RECORD" one
status: 0
calls:
  child.1: one
```

The first is refused (with dash as `sh` the same call exits 0 and the command receives `-x`). The second is worse; the review's security pass found it and I reproduced it. bash reads `-a x` as "set argv[0] to x", runs `$RECORD` with the one argument `one`, and exits 0. The command the caller named, `-a`, never ran; a later word ran in its place, and the run reports success. With dash the same call exits 127 (`exec: -a: not found`), which is right. Confinement is not affected in either case: whatever runs, runs inside the namespace. What breaks is the property this line is the repo's reference for (decision 018): each word reaches the child as its own argv element.

Severity is low in practice (a test command is rarely named `-something`, and `./-something` avoids it). It matters because CLAUDE.md names this line as the reference for passing untrusted text, and the rule beside it says to put `--` or `./` before a path. `exec -- "$@"` is not the fix: dash 0.5.12 runs `--` as the command (exit 127) [observed]. The review's security passes suggest three candidate fixes, none of which I ran: `command -- "$@"` (they saw it behave correctly under both shells, at the cost of the `exec`), running the body under bash with `exec -- "$@"`, or refusing a command whose name starts with `-`. The tests pin a dash-named command on the bwrap and `--no-loopback` forms only, and dash-leading arguments (not the command name) on all three.

**D2. A plain fallback to unshare prints no warning about what unshare does not confine.** Whether this is a defect is a judgment for the cycle. I list it as one because the review's security pass read it as an H2 question (a degraded primitive should name what went unenforced), and because the script's own comment says of this loss "Say so, loudly, every time" (`scripts/confine-tests.sh:132-133`). The warning that unshare gives no read-only root, no private `/tmp`, no pid namespace and uid 0 is printed only when `--no-loopback` forces the switch from bwrap. When bwrap is missing or refused, the same weaker profile runs with one line (FP-050's shape):

```
confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one
status: 0
stderr:
  confine-tests: denying network via unshare (loopback=1)
```

The other reading: the script's contract is network denial, which unshare delivers, and the header comment documents the difference. No test pins the warning's absence: two copies of the script that add it, at run time and at selection time, pass every test ("Mutation run").

## Observations (not defects)

- **O1. `--probe` asks bwrap for less than a run does.** The probe is `--ro-bind / / --unshare-net -- true`; the run adds `--dev`, `--proc`, `--tmpfs`, `--setenv`, `--bind`, `--unshare-pid`, `--die-with-parent` and `--chdir`. A bwrap that allows the first and refuses the second (a nested sandbox that will not mount `/proc`, for one) gives probe exit 0 and a failed run. It fails closed, and a test pins that. But "probe exit 0" in brief wording then leads to a confined run that cannot start. Worth checking in the sandbox's live run.
- **O3. No primitive and no command exits 3, not 2.** Detection comes before the empty-command check.
- **O4. A command given without `--` is reported as `unknown flag: <command>`.** The refusal is right (exit 2, not run; pinned); the wording is off.
- **O5. Run from `/`, the bwrap profile may undo its own read-only root** [inferred from the argv; not run, there is no bwrap here]. `--bind "$PWD" "$PWD"` comes after `--ro-bind / /`, so with `PWD=/` it is `--bind / /`. The review's security pass raised it; one check in a live run would settle it.

(There is no O2: it became D2 in the review.)

## Docs

No doc describes the script's tests, because there were none. Two dated records say it had no test: `docs/reviews/review-fix-loop-polyglot-test-hermeticity.md` (weak seam 3) and `docs/working/research-2026-11-07-confine-tests-situation.md` (follow-up 5). Both are records of their date, outside this brief's Paths, and are left as they are. `guides/test-hermeticity.md` lists `test/hermeticity-lint.bats` under its relevant paths and says nothing about tests of this script; adding the new file there is a one-line follow-up for the cycle, outside this brief's Paths.

## Files read

Last verified: 2026-11-10
scripts/confine-tests.sh
scripts/run-tests.sh
scripts/hermeticity-lint
scripts/build-loop.sh
test/scripts/run-tests.bats
test/scripts/build-loop-orchestrator.bats
test/fixture-hermeticity.bats
test/lib/hermetic-env.bash
guides/test-hermeticity.md
docs/constraints.md
docs/failure-patterns.md
docs/decisions/log.md
docs/decisions/018-argv-exec-over-shell-string-interpolation.md
docs/reviews/review-fix-loop-polyglot-test-hermeticity.md
docs/working/research-2026-11-07-confine-tests-situation.md
docs/working/briefs/2026-11-10-confine-tests-bats.md
workflows/research-plan-implement.md
workflows/pr-prep.md
workflows/divergent-design.md
workflows/review-fix-loop.md
skills/code-review/SKILL.md
skills/code-review/references/rubric.md
scripts/health-check.sh
hooks/live-verify-gate.sh
