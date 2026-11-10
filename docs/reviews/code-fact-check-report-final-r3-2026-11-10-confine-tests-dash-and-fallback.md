Commit: bd312d15

# Code Fact-Check Report

**Commit:** bd312d15
**Repository:** claude-workflows, worktree `/workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback`, branch `fix/confine-tests-dash-and-fallback`
**Scope:** 23ffb16c..bd312d15 (final confirming pass, replicate 3): `scripts/confine-tests.sh`, `test/scripts/confine-tests.bats`, `guides/test-hermeticity.md`, `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md`, `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md`, and the commit messages of `git log 23ffb16c..bd312d15`
**Checked:** 2026-11-10
**Total claims checked:** 55
**Summary:** 45 verified, 8 mostly accurate, 0 stale, 2 incorrect, 0 unverifiable

---

## How the runs were made

All experiments ran from the scratch directory
`/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-final-fc-r3`
(written `$X` below; every log named is a file under `$X/logs/`). Bash 5.2.15, dash 0.5.12
(`/usr/bin/sh -> dash`), Bats 1.8.2. Times are UTC, 2026-11-10. Nothing in the worktree was edited.
Each script under test was copied (`$X/old` = `git show 23ffb16c:scripts/confine-tests.sh`,
`$X/new` = the worktree's file, `$X/at-<commit>` = that commit's script and test file).

The main experiments:

- **Old against new** (`$X/diff.sh`, started 22:28:36, cwd `$X/h/work`, exit 0; output
  `$X/logs/diff-results.txt`, classified by `$X/classify.py` into `$X/logs/classify.txt`): 1650 runs of
  each script on a built PATH (bash, cat, awk, permissive stand-ins for bwrap, unshare and ip). It used 11
  primitive setups (bwrap ok / refused / missing × unshare ok / refused / missing × ip ok / missing /
  fails, and none), `sh` linked to dash, to bash, or absent, the flag sets `--probe`,
  `--no-loopback --probe`, `--probe --no-loopback`, none, `--no-loopback`, `--bogus` and `-h`, and 15
  commands: `rec one`, `-record -x`, `-a x rec one`, `-nonexistent y`, `''`, `adir` (a directory on PATH),
  `noexec` (a file without the execute bit), `nosuch z`, `eval echo hi`, `-- x`, `-c echo hi`, `-a- q`,
  `-l rec`, no command, and `--help`. Result: 1281 identical, 369 different. All 99 `--probe` runs are
  identical. Every bwrap-ok route is identical except `-h`. The banner line (`denying network via ...`)
  is the same in all 369 differing runs.
- **Mutation run** (`timeout 590 python3 mutate.py <worktree> $X/mut`, started 22:26:37, cwd `$X`, exit 0;
  `$X/logs/mut-run.txt`).
- **Test file per commit** (`$X/atcommits.sh`; `$X/logs/bats-at-*.txt`) and the final test file against
  the 23ffb16c script (`$X/logs/bats-newtests-oldscript.txt`, 22:27:29).

---

## Claim 1: "pr-prep's fallback check fired on a count of 539 changed lines, 301 of them the research doc; 238 lines change outside `docs/` (227 in the script and its test, 11 in the guide), none in an enforcement file"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the line counts at ca6cf3be (the pre-mortem's stated proposal end) and the enforcement-file statement; does not establish the counts at bd312d15, which are larger.
**Legibility-target:** for-orchestrator-synthesis

`git diff --shortstat 23ffb16c..ca6cf3be` gives `4 files changed, 490 insertions(+), 49 deletions(-)` = 539.
`--numstat` gives research doc `301 0`, script `61 13`, test `119 34` (227), guide `9 2` (11): 238 outside
`docs/`. The live-verify gate's patterns cover only `devcontainer-config/`:
`enforcement='^devcontainer-config/(Dockerfile|...` (`hooks/live-verify-gate.sh:83`).
Command run in the worktree at 22:25 (exit 0); output quoted here (paraphrased — no quote available because the output was read from the terminal, not saved to a file; the three numbers can be regenerated with the command).

**Evidence:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:12`, `hooks/live-verify-gate.sh:83`, `hooks/live-verify-gate.sh:91`

---

## Claim 2: "Prior art: `grep -ril -e 'BASH_ENV' -e 'uid 0' -e 'warning fatigue' -e 'unshare -r' docs/decisions/ docs/working/` returns decision 017, the two earlier confine-tests research docs and this unit's own."

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the grep's result list at de1f4bf9 (the commit that added the pre-mortem) and in the worktree; does not judge whether the extra hits are relevant prior art.
**Legibility-target:** for-author

`git grep -il -e 'BASH_ENV' -e 'uid 0' -e 'warning fatigue' -e 'unshare -r' de1f4bf9 -- docs/decisions/ docs/working/`
(cwd the worktree, 22:34, exit 0) lists 17 files, not 4: besides decision 017 and the three confine-tests
research docs, it also returns `docs/decisions/019-arithmetic-eval-sandboxing.md`, both confine-tests
briefs, five cycle logs, `diagnosis-cc-isolated-login-dns.md`, `plan-build-loop-handoff.md`,
`questions-archive.md`, `research-2026-11-01-restriction-audit.md` and
`research-2026-11-05-d6-block-into-image.md` (paraphrased — no quote available because the list was read from the terminal; the command regenerates it). The sentence reads as the grep's whole output. Precise version: "returns 17 files; of them, decision 017 and the confine-tests research docs bear on this", or name the files that were judged relevant.

**Evidence:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`; command above

---

## Claim 3: Narrative 1: a fallback `--probe` "prints `primitive available: unshare (loopback=1)` and exits 0, with no warning"; a run "prints the new warning as the file's first six lines"; the file "starts with `confine-tests: WARNING — bwrap is installed but unusable here`"; four tests begin `[ "$(id -u)" -ne 0 ] || skip` at `test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889`, `test/install-host.bats:680`, `test/cc-isolated-functions.bats:1970`; `docs/roadmap.md:49` reads "exit 0: tests pass confined"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:20-24`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script's output on stand-ins and the four file:line references; does not establish the uid a real `unshare -r` gives (no namespace here) or that those four are the only root-sensitive tests (others branch on uid without skipping, e.g. `test/scripts/build-loop-check.bats:103`).
**Legibility-target:** for-orchestrator-synthesis

In `$X/logs/diff-results.txt` every fallback `--probe` (bwrap refused or missing, unshare ok, ip ok) is
identical to 23ffb16c, and test 14 pins `[ -z "$stderr" ]` (`test/scripts/confine-tests.bats:373,378`).
`warn_unshare_only` prints one `echo` headline, three heredoc lines, one `echo` line and one `printf` line
per way-back argument (`scripts/confine-tests.sh:131-140`); both fallback calls pass one further argument
(`:222-228`), so six lines. The headline is
`"bwrap is installed but unusable here; falling back to the unshare primitive."` (`:222`).
`rg -n 'id -u\)" -ne 0 \] \|\| skip' test/` returns exactly the four lines named. `docs/roadmap.md:49`
holds `exit 0: tests pass confined`.

**Evidence:** `scripts/confine-tests.sh:131-140`, `scripts/confine-tests.sh:216-230`, `test/scripts/confine-tests.bats:367-380`, `docs/roadmap.md:49`; `$X/logs/diff-results.txt`

---

## Claim 4: Narrative 2: "before, it was the banner `confine-tests: denying network via unshare (loopback=1)`"; "the log shows the banner on line seven"; the header "now says the warning comes first on stderr"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:29-34`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old and new first stderr lines on a fallback run and the header wording; does not establish anything about external callers.
**Legibility-target:** for-orchestrator-synthesis

At 23ffb16c the first stderr line of a fallback run is the banner
(`echo "confine-tests: denying network via $primitive (loopback=$loopback)" >&2`, old `:178`, the first
output of the run block). In the new script the six-line warning comes first and the banner is line 7
(test 20's exact comparison, `test/scripts/confine-tests.bats:491-494`, passes). The header says
"and says first, on stderr, what that leaves unconfined" (`scripts/confine-tests.sh:33-34`).

**Evidence:** `scripts/confine-tests.sh:29-35`, `scripts/confine-tests.sh:216-232`; `$X/logs/bats-new.txt`

---

## Claim 5: "no caller exists in this repo, and `grep -rn confine-tests` over code finds none"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:33`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `*.sh`, `*.bats`, `*.py` in the worktree; does not cover callers outside this repo.
**Legibility-target:** for-orchestrator-synthesis

`rg -n confine-tests -g '*.sh' -g '*.bats' -g '*.py'`, excluding the script and its test, returns one
line, a comment: `# namespace: scripts/confine-tests.sh -- scripts/run-tests.sh --all`
(`test/fixture-hermeticity.bats:15`). No line runs the script.

**Evidence:** `test/fixture-hermeticity.bats:15`

---

## Claim 6: "a non-interactive bash sources the file `BASH_ENV` names; the `sh` it replaces does not, whether it is dash or bash started as `sh`"

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12 with `-c`; does not establish the timing narrative that follows.
**Legibility-target:** for-orchestrator-synthesis

`bash $X/benv/p.sh $X/benv` (22:33, exit 0) prints `bash -c: SOURCED` then `body`, `dash -c: body`, and
`bash-as-sh -c: body`. The quoted script line is `exec unshare -rn -- "$BASH" -c '`
(`scripts/confine-tests.sh:285`).

**Evidence:** `scripts/confine-tests.sh:285`; `$X/logs/bashenv.txt`

---

## Claim 7: Narrative 4: the dash test begins `dash="$(type -P dash)" || skip ...`; four other tests fail with `exec: sh: not found`; the mutant "body under sh again" fails 16, 18, 19, 20 and 21, and without dash would still fail 16, 19, 20 and 21; `setup()` links only `bash`, `cat` and `awk`

**Location:** `docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:46-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the mutation result and the failure message on this host; the "without dash" figure is inferred from test 18 being the only one that needs dash, not run on a host without dash.
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/mut-run.txt`: `m01 body under sh again (exec -- kept): exit 1; failing tests: 16, 18, 19, 20, 21`.
At d03a3078 the same `sh -c` body with no `sh` on PATH fails tests 16, 19, 20 and 21 with
`stub/unshare/unshare: line 29: exec: sh: not found` (`$X/logs/bats-at-d03a3078.txt`). `setup()` runs
`for tool in bash cat awk; do ln -s ...` (`test/scripts/confine-tests.bats:65-67`). The test's first line is
`local dash`, and the line quoted is its second (`:462-463`); "begins" is loose by one declaration.

**Evidence:** `test/scripts/confine-tests.bats:65-67`, `test/scripts/confine-tests.bats:461-465`; `$X/logs/mut-run.txt`, `$X/logs/bats-at-d03a3078.txt`

---

## Claim 8: What exists: the script at 23ffb16c is 227 lines; Detection is lines 79-118, the `--no-loopback` switch 134-152 (a seven-line warning, six `echo`s after the headline), the run 176-227; D1's location is `:225`, D2's lines 134-143; the old test file has 420 lines and 17 tests

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:16-20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line numbers and counts in the 23ffb16c files; does not cover the first unit's doc that this section defers to.
**Legibility-target:** for-orchestrator-synthesis

`wc -l` gives 227 and 420; `grep -c '^@test'` gives 17. Old `:79` is `detect_primitive() {`, `:115-118`
the `if ! primitive=... exit 3 fi` block; `:134` opens `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]`
and `:152` closes it, with `echo` lines at `:137-143`; `:176` is `# --- run ---`, `:225` is
`    exec "$@"' sh "${cmd[@]}"`, and `:227` the last line.

**Evidence:** `git show 23ffb16c:scripts/confine-tests.sh` lines 79-227 (copy at `$X/old/scripts/confine-tests.sh`)

---

## Claim 9: "Callers: none in code"; decision 018 (`:43,117`) cites `scripts/confine-tests.sh:220`; `CLAUDE.md` names the script without a line

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:22`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three references; does not cover other docs that may cite a line of the script.
**Legibility-target:** for-orchestrator-synthesis

`docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43`:
"(`scripts/confine-tests.sh:220` is the reference for this pattern.)"; `:117`:
"- `scripts/confine-tests.sh:220` — reference argv-passthrough pattern." `CLAUDE.md:9` ends
"the reference pattern is in `scripts/confine-tests.sh`". Callers: as Claim 5.

**Evidence:** `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43`, `:117`, `CLAUDE.md:9`

---

## Claim 10: "In this container `scripts/confine-tests.sh --probe` exits 3 ... Its first line: `confine-tests: NO CONFINEMENT PRIMITIVE AVAILABLE — refusing to run.`"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:24-28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this container at bd312d15; does not establish behaviour on a host that can create namespaces.
**Legibility-target:** for-orchestrator-synthesis

`timeout 60 scripts/confine-tests.sh --probe` (cwd the worktree, 22:31:02, exit 3); first line as quoted.

**Evidence:** `$X/logs/probe.txt`

---

## Claim 11: The D1 table: with `sh` as bash, `-rec -x` is refused (`exec: -r: invalid option`), `-a x rec one` runs `rec` with `one`, `eval echo hi` runs the file, `-nonexistent y` is refused (`exec: -n: invalid option`); with `sh` as dash, `-rec` runs with `-x`, and `-a ...` and `-nonexistent ...` are "not found"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:34-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12, run directly and through the old script on stand-ins; does not cover other shells as `sh`.
**Legibility-target:** for-orchestrator-synthesis

The author's `probe1.sh`, copied to `$X` and run (`timeout 120 bash ./probe1.sh`, 22:33, exit 0), and the
old-script runs in `$X/logs/diff-results.txt` agree: old, sh=bash: `-record -x` exit 2, `-a x rec one`
exit 0 with `child[.../rec]: <one>`, `-nonexistent y` exit 2; old, sh=dash: `-record -x` exit 0, the
other two 127.

**Evidence:** `$X/logs/probe1.out`, `$X/logs/diff-results.txt`

---

## Claim 12: D2 reproduced: "`confine "unshare ip" STUB_UNSHARE=ok STUB_IP=ok -- -- "$RECORD" one` exits 0 with one line on stderr, `confine-tests: denying network via unshare (loopback=1)` [observed in the first unit's doc and by this unit's new test failing at 23ffb16c]"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:43`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the old script's output on that route with `sh` on PATH and how this unit's tests fail at 23ffb16c; does not cover the first unit's doc.
**Legibility-target:** for-author

The behaviour holds where `sh` is on PATH: in `$X/logs/diff-results.txt` the old script, sh=dash, bwrap
missing, `rec one` exits 0 with the banner as its only stderr line. The provenance is loose. This unit's
test of that exact command, test 20, fails at 23ffb16c on `[ "$status" -eq 7 ]` with status 127 (no `sh` on
the built PATH), not on the missing warning (`$X/logs/bats-newtests-oldscript.txt`). The test that does fail
at 23ffb16c on the missing warning is test 15, on the `--no-loopback` fallback route:
`` `[ "${stderr_lines[0]}" = "$NO_BWRAP_WARNING" ]' failed `` with `status: 0`. Precise version: "...and
by this unit's test 15 failing at 23ffb16c (the `--no-loopback` route); test 20 fails there earlier, on the
missing `sh`".

**Evidence:** `test/scripts/confine-tests.bats:395-401`, `test/scripts/confine-tests.bats:489-494`; `$X/logs/bats-newtests-oldscript.txt`, `$X/logs/diff-results.txt`

---

## Claim 13: Invariants: "The tests pin this: the selection tests are untouched, the fallback probe's stderr is pinned empty, and the `--no-loopback` probe's stderr is compared with the whole old warning, byte for byte."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which tests the branch's diff touches and what tests 11 and 14 assert; does not establish that the tests pin every probe input (the old-against-new runs do that, Claim 39).
**Legibility-target:** for-author

The second and third parts hold: test 14 adds `[ -z "$stderr" ]` twice (`test/scripts/confine-tests.bats:373,378`)
and test 11 asserts `[ "$stderr" = "$LO_WARNING_TEXT" ]` (`:334`), which passes against 23ffb16c (Claim 26).
"The selection tests are untouched" is loose: tests 11 and 14, both primitive-selection tests, are the
ones the branch changed to add those pins (diff hunks at `@@ -312,8` and `@@ -347,33`). Their
status, verdict and call-count assertions are unchanged. Precise version: "the selection tests' status,
verdict and call assertions are untouched; tests 11 and 14 gain the stderr pins".

**Evidence:** `test/scripts/confine-tests.bats:327-336`, `test/scripts/confine-tests.bats:367-380`; `git diff 23ffb16c..bd312d15 -- test/scripts/confine-tests.bats`

---

## Claim 14: Further invariants: the body stays one static single-quoted string (compared across two commands); the test file spawns none of `claude`, `curl`, `gh`, `wget`; the stand-ins for `sh` are the real bash and dash; the script is not an enforcement file (patterns match only `devcontainer-config/`); no test starts an interactive shell

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:48-54`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test file and gate patterns at bd312d15; does not establish the security reading of decision 018 beyond the static-body property.
**Legibility-target:** for-orchestrator-synthesis

Test 16 asserts `[ "${first[4]}" = "${second[4]}" ]` and that the body holds neither command
(`test/scripts/confine-tests.bats:433-435`); it passes (`$X/logs/bats-new.txt`). `rg 'curl|wget|\bgh\b|claude'`
over the test file finds nothing. `dash_named_on_unshare` runs `ln -s "$1" "$TOOLS/sh"` with
`$(type -P bash)` or `$(type -P dash)` (`:444`, `:458`, `:464`). `hooks/live-verify-gate.sh:83,91`: both
patterns start `^devcontainer-config/`. The lint passes (Claim 27).

**Evidence:** `test/scripts/confine-tests.bats:409-465`, `hooks/live-verify-gate.sh:83`, `hooks/live-verify-gate.sh:91`

---

## Claim 15: Prior failures: FP-050 is the unshare tier sharing the host's mount namespace; FP-044 and FP-057 a fallback tier with less confinement; FP-058 a bwrap run-time failure dropping the work silently; FP-025, FP-032, FP-046, FP-067, FP-118, FP-134 are about other mechanisms

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:71-81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each entry's one-line summary; does not reread each entry's full write-up.
**Legibility-target:** for-orchestrator-synthesis

`docs/failure-patterns.md:192`: `FP-050 ... symptom:unshare-tier-shares-host-mount-namespace-host-writes`;
`:186` FP-044 `fallback-tier-ran-with-network-intact`; `:199` FP-057
`fallback-tier-blocks-writes-but-not-reads-disclosure`; `:200` FP-058
`bwrap-runtime-failure-drops-the-computation-silently`. The six others are `#` read as a comment (FP-025),
a quote in an interpolated expression (FP-032), shell state across calls (FP-046), a builtin's name
(FP-067), pipeline status under errexit (FP-118), and an exit trap (FP-134), as the doc says.

**Evidence:** `docs/failure-patterns.md:167`, `:174`, `:186`, `:188`, `:192`, `:199`, `:200`, `:209`, `:260`, `:276`

---

## Claim 16: Gotchas: `exec -- "$@"` is right under bash, in posix mode too, and wrong under dash; `command -- "$@"` and bare `"$@"` run the builtin (`eval echo hi` prints `hi`); `$BASH` is `<PATH dir>/bash` under the shebang and the interpreter's path under `bash script`; `"$BASH" -c` keeps the pid, returns the status, exits 127 for a name not on PATH and 126 for a directory; bash runs the last command of a `-c` string in place

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:65-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12; the 126 holds for a directory given as a path, while a bare name that matches a directory on PATH gives 127 under bash (see Claim 21).
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/dash-exec-dashdash.txt`: `dash: 1: exec: --: not found` with 127; bash and bash-as-`sh` print `hi`.
`$X/logs/probe1.out`: `command -- "$@" | eval echo hi -> 0 | hi` and `"$@" | eval echo hi -> 0 | hi` under
both shells. `$X/logs/bashenv.txt`: under `env -i PATH=<dir>` and the shebang, `BASH=<dir>/bash`; under
`bash ./s.sh`, `BASH=/usr/bin/bash`. `$X/logs/p3.txt`: `[./d] ... bash-new=126`, `[nosuch] ... bash-new=127`.
In-place last command: mutant m04 (bare `"$@"`) still passes test 16's `same_process`, so the pid survives
without `exec` (`$X/logs/mut-run.txt`).

**Evidence:** `$X/logs/dash-exec-dashdash.txt`, `$X/logs/probe1.out`, `$X/logs/bashenv.txt`, `$X/logs/p3.txt`, `$X/logs/mut-run.txt`

---

## Claim 17: DD-1 match evidence: candidate 5 "a name holding `=` is read as an assignment (`a=b z` set a variable and tried to run `z`)"; 3 and 4 run `eval` as a builtin; 12 "util-linux `unshare` has no such option"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:113-132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe-backed cells; the ✓/✗ judgements on soft constraints are design rationale and were not checked.
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/probe1.out`: `exec env -- "$@" | a=b z -> 0 | env: ‘z’: No such file or directory` under both
shells. `unshare --help` lists `-n, --net[=<file>]` and no loopback option (run at 22:33).

**Evidence:** `$X/logs/probe1.out`; `/usr/bin/unshare --help`

---

## Claim 18: "Other choices, one line each" (DD-2): the function's shape `warn_unshare_only HEADLINE FIRST-WORDS LINE...`; the headline names the cause via `command -v bwrap`, "unusable here" being the script's word; `--no-loopback` without bwrap prints the fallback warning with "and drop --no-loopback", and at 23ffb16c that route printed no warning; the `--no-loopback` warning is byte for byte what it was; the body's `$0` gives `confine-tests: unshare body: line 6: exec: -a: not found`; `sh` leaves the built PATH and the two D1 tests add bash and dash under that name; the dash test skips loudly without dash

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:203-211`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each sentence against the code and runs at bd312d15; does not judge the design preferences stated.
**Legibility-target:** for-orchestrator-synthesis

`warn_unshare_only() { echo "confine-tests: WARNING — $1" >&2 ... echo "  with EROFS will succeed against the real filesystem. $2" >&2; printf '  %s\n' "${@:3}" >&2; }`
(`scripts/confine-tests.sh:131-140`). `if command -v bwrap >/dev/null 2>&1; then warn_unshare_only "bwrap is installed but unusable here; ...`
(`:221-228`); `and_flag=" and drop --no-loopback"` when `loopback -eq 0` (`:217-220`). The refusal says
`which is unusable here` (`:178`). Old, `--no-loopback` with bwrap missing: the banner only
(`$X/logs/diff-results.txt`, old stderr of `sh=dash bw-missing,us-ok,ip-ok flags=[--no-loopback]`). The
byte-for-byte claim: Claims 26 and 39. Error text: new stderr for `-a x rec one`, sh=dash, reads
`confine-tests: unshare body: line 6: exec: -a: not found` (`$X/logs/diff-results.txt`). Line 6 of the body
is `exec -- "$@"`: the string opens with a newline (`:285-290`). `setup()` links `bash cat awk` only
(`test/scripts/confine-tests.bats:65`); the skip is `|| skip "dash is not installed on this machine"` (`:463`).

**Evidence:** `scripts/confine-tests.sh:131-140`, `scripts/confine-tests.sh:168-182`, `scripts/confine-tests.sh:216-230`, `scripts/confine-tests.sh:285-290`, `test/scripts/confine-tests.bats:65`, `test/scripts/confine-tests.bats:461-465`; `$X/logs/diff-results.txt`

---

## Claim 19: Results: "17 tests become 21. Four are new (a dash-named command with `sh` as bash and as dash, a command named like a builtin, the fallback's warning)"; the script, test and guide changes listed

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:283-287`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the test count and the list of changes; does not restate per-test assertions (Claim 44).
**Legibility-target:** for-orchestrator-synthesis

`grep -c '^@test'` gives 17 at 23ffb16c and 21 now; the new ones are tests 17-20
(`test/scripts/confine-tests.bats:457`, `:461`, `:467`, `:476`).

**Evidence:** `test/scripts/confine-tests.bats:457-508`

---

## Claim 20: The "Exit statuses" table: `-record -x` 2 / own / own; `-a x CMD one` CMD's own (CMD ran) / 127 / 127; `-nonexistent y` 2 / 127 / 127; `''` 127 / 126 (`exec: : Permission denied`) / 127

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:293-297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each cell on the unshare-with-loopback route with stand-ins, `sh` as bash and as dash (and absent for the new script); does not establish the statuses under a real `unshare`.
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/diff-results.txt`, route bw-missing/us-ok/ip-ok: sh=bash old `-record -x` 2, new 0 (the command's
own); `-a x rec one` old 0 with the child run, new 127; `-nonexistent y` old 2, new 127; `''` old 127, new 127.
sh=dash old: `-record -x` 0, `-a ...` 127, `-nonexistent` 127, `''` 126 with `sh: 6: exec: : Permission denied`;
new 127 with `confine-tests: unshare body: line 6: exec: : not found`. The new script gives the same with
`sh` absent.

**Evidence:** `$X/logs/diff-results.txt`, `$X/logs/classify.txt`

---

## Claim 21: "Every other input the review compared, on every route, exits as before, and so does every `--probe`." (and bd312d15's Notes: "On a host where sh is dash, an empty command name now exits 127 where it exited 126")

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:299`; commit bd312d15 message, Notes
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 1650 old-against-new runs (inputs listed under "How the runs were made"); the residual is a second status move on dash hosts that neither the sentence nor the Notes record.
**Legibility-target:** for-author

As worded, the sentence is true. The pass-1 API probe gave its directory as an absolute path
(`case "$cmdset" in ADIR) args=("$S/adir");;`, `review-i1-api/probe.sh:19`), and a path still gives 126.
Every `--probe` is identical (99 of 99). The residual: where `sh` is dash, a bare command name that
matches a **directory on PATH** moved from 126 to 127. Old: `sh: 6: exec: adir: Permission denied`, exit 126.
New: `confine-tests: unshare body: line 6: exec: adir: not found`, exit 127
(`$X/logs/diff-results.txt`, `sh=dash bw-missing,us-ok,ip-ok flags=[] -- [adir]`, and the same with bwrap
refused; direct check `$X/logs/p3.txt`: `[adir] dash-old=126 bash-new=127`, `[./d] dash-old=126 bash-new=126`).
The mechanism is the empty name's: bash's PATH search skips non-executables and directories, while dash
tries `execve` and reports EACCES. A file without the execute bit keeps 126 on both, with a two-line
message under bash. On a host where `sh` is bash nothing outside the dash-named cases moves. Precise
version: "...except a bare name that matches a directory on PATH, which on a dash host also moves from 126
to 127, for the empty name's reason".

**Evidence:** `scripts/confine-tests.sh:285-290`; `$X/logs/diff-results.txt`, `$X/logs/classify.txt`, `$X/logs/p3.txt`; `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-i1-api/probe.sh:19`

---

## Claim 22: Mutation run: "22 of 22 fail at least one test, and the unchanged script passes 21 of 21", and each row's failing tests

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:303-328`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 22 rows against a re-run of the author's `mutate.py`, and that each mutant does what its name says (one exception in wording, Claim 23); does not establish that the mutant set is complete.
**Legibility-target:** for-orchestrator-synthesis

The re-run (`timeout 590 python3 mutate.py /workspace/.claude/wt-... $X/mut`, cwd `$X`, 22:26:37, exit 0)
matches every row: m01 `16, 18, 19, 20, 21` through m22 `11, 20`, `SURVIVORS: none`, control `NONE`. Reading
`mutate.py`: m01 and m02 swap `"$BASH" -c` for `sh -c` (m02 also `exec "$@"` and `$0 sh`); m03-m05 change
the last line; m06 `bash -c`; m07 `$0` `confine-tests`. m08-m12 remove, move (after `SET_FELL`, i.e. before
selection, ip refusal and probe), redirect (`fi 2>&1`), reorder or double the `FELL` block. m13 negates
`command -v bwrap`; m14 removes `LO_WARN`; m15 prints `LO_WARN` on the fallback with the flag. m16 adds an
echo before the way-back lines, skipped when `$1` starts `--no-loopback`. m17 adds `exit 3`; m18 removes the
uid-0 clause; m19 removes the `printf`; m21 removes ` and drop --no-loopback`; m22 drops `$2`. Each is what
its name says.

**Evidence:** `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/review-final-fc-r3/mutate.py`; `$X/logs/mut-run.txt`, `$X/logs/mut-start.txt`

---

## Claim 23: Mutation row "the `--no-loopback` warning re-wrapped (the first version's line breaks)"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:326`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what m20 prints against what 6465a156 printed; does not affect the row's failing tests, which match.
**Legibility-target:** for-author

m20 replaces the EROFS line with `echo "  with EROFS will succeed against the real filesystem." >&2` and
`echo "  $2" >&2` (`mutate.py`, m20), so the way back runs `  Drop the flag to` / `  get the hardened profile
(loopback is not egress — the namespace has` / `  no route off the host).`. The first version (6465a156)
printed `  Drop the flag to get the hardened profile (loopback is not egress — the` /
`  namespace has no route off the host).` (`diff $X/logs/p6.old.err $X/logs/p6.at-6465a156.err`). Both
end the shared sentence on its own line, but m20 does not reproduce the first version's later breaks.
`mutate.py` names it "(shared sentence ends its line)". Precise version: as `mutate.py` says.

**Evidence:** `$X/mutate.py` (m20); `$X/logs/p6.old.err`, `$X/logs/p6.at-6465a156.err`

---

## Claim 24: Test-number key: "11 and 12 are the `--no-loopback` tests, 14 the fallback probe, 15 unshare without `ip`, 16 the unshare run's argv, 17 and 18 the dash-named command with `sh` as bash and as dash, 19 the builtin's name, 20 the fallback's warning, 21 `lo` not raised"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:329`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the positions of tests 11-21 in the file; does not affect the mutation table.
**Legibility-target:** for-author

Positions 14-21 match (`test/scripts/confine-tests.bats:367`, `:382`, `:409`, `:457`, `:461`, `:467`, `:476`, `:510`).
Test 13 is also a `--no-loopback` test: `@test "--no-loopback is refused (exit 2), probe or run, when bwrap works and unshare does not"`
(`:354`). Precise version: "11 and 12 are the `--no-loopback` switch tests (13, its refusal, fails under no mutant)".

**Evidence:** `test/scripts/confine-tests.bats:327`, `:338`, `:354`, `:367-510`

---

## Claim 25: History: "In the first, the 'extra line' mutant passed every test ... The test was strengthened (ca6cf3be), and the second run had no survivor (19 of 19)."

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:331`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the author's run logs; the first run's mutant body is not saved, so that it was an "extra line" rests on the commit message, not on its code.
**Legibility-target:** for-orchestrator-synthesis

`mutation-run-1.txt`: `m16 the shared text differs on the fallback route: exit 0; failing tests: NONE` and
`SURVIVORS: ['m16 the shared text differs on the fallback route']`. `mutation-run-2.txt`: 20 result lines
(control plus 19) and `SURVIVORS: none`. `mutation-run-3.txt`: 23 lines (control plus 22).

**Evidence:** `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/mutation-run-1.txt`, `mutation-run-2.txt`, `mutation-run-3.txt` (same directory)

---

## Claim 26: "The test of the whole `--no-loopback` warning (test 11) also passes against the script at 23ffb16c" (also bd312d15: "passes against the script at 23ffb16c too"; the LO_WARNING_TEXT comment, "byte for byte what the script printed before")

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:333`; `test/scripts/confine-tests.bats:29-31`; commit bd312d15 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers test 11 (both flag orders, `--probe`) against the 23ffb16c script; does not cover `--no-loopback` runs (Claim 39 does).
**Legibility-target:** for-orchestrator-synthesis

`cd $X/old && timeout 300 bats test/scripts/confine-tests.bats` (old script, final test file, 22:27, exit 1):
`ok 11 --no-loopback switches from bwrap to unshare and warns about what is lost, in either flag order`
(tests 1-14 pass, 15-21 fail). `LO_WARNING_TEXT` (`:32-38`) matches old `:137-143` line for line.

**Evidence:** `test/scripts/confine-tests.bats:29-38`, `test/scripts/confine-tests.bats:327-336`; `$X/logs/bats-newtests-oldscript.txt`

---

## Claim 27: Gates: `--probe` exit 3; `timeout 300 bats test/scripts/confine-tests.bats` 21 of 21; `scripts/hermeticity-lint --root .` exit 0 with "143 test file(s) checked, no unstubbed network spawns"; `shellcheck -x -e SC1091 -s bash -S warning` (the health check's command) exit 0; the whole suite at ca6cf3be exit 0, 2012 of 2012

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:337-343`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four gates re-run at bd312d15; the suite row rests on the author's files, which were read, not re-run, and are for ca6cf3be, not bd312d15.
**Legibility-target:** for-orchestrator-synthesis

Probe: Claim 10. Bats, `cd $X/new && timeout 300 bats test/scripts/confine-tests.bats` (22:27:29, exit 0),
21 `ok`. Lint, cwd the worktree (22:31, exit 0):
`hermeticity-lint: 143 test file(s) checked, no unstubbed network spawns.` Shellcheck on both files (exit 0,
empty output); the health check runs `shellcheck -x -e SC1091 -s bash -S warning "$f"`
(`scripts/health-check.sh:525`). `suite-1.head` holds `ca6cf3be`; `suite-1.txt` holds `1..2012`, 2012 `ok`, 0
`not ok`, and ends `exit=0`.

**Evidence:** `scripts/health-check.sh:525`; `$X/logs/probe.txt`, `$X/logs/bats-new.txt`, `$X/logs/lint.txt`, `$X/logs/shellcheck.txt`; `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/suite-1.txt`, `suite-1.head`

---

## Claim 28: Review: pass 1 at de1f4bf9, one fact-check then security, performance and API critics, no red; the re-wrap fixed in code with the API pass's advice declined; the way back with the flag; "unusable here", the body's `$0`, the header and guide wording; four doc sentences; two commit sentences that stand; no override-log row

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:345-356`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the rubric and the current code; does not re-adjudicate the pass-1 findings.
**Legibility-target:** for-orchestrator-synthesis

The rubric's header says `0 red; 8 amber`. A1 is the re-wrap (fixed); C1 (S 2) the way back, "Fixed";
C2 (A 3) "unusable"; C3 (A 4) the body `$0`; A2 and C4 the header and guide. A3, A6, A7 and A1's research-doc
part are the four doc sentences; A4 and A5 the two commit sentences, "Stands". All match the code
(`scripts/confine-tests.sh:45-48`, `:217-228`, `:290`). `git diff --stat 23ffb16c..bd312d15 -- docs/reviews/override-log.md`
is empty.

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:1-119`

---

## Claim 29: Observations: under the fallback the four `|| skip` tests skip as root (same four locations); "The test file is 516 lines"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:369-371`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the count and locations; that a real `unshare -r` yields uid 0 is not observable here.
**Legibility-target:** for-orchestrator-synthesis

`wc -l test/scripts/confine-tests.bats` gives 516; the four lines as in Claim 3.

**Evidence:** `test/scripts/confine-tests.bats:1-516`, `test/cc-push.bats:417`, `test/hooks/guard-trusted-writes.bats:889`, `test/install-host.bats:680`, `test/cc-isolated-functions.bats:1970`

---

## Claim 30: Follow-ups: decision 018 `:43,117` cite `:220`, "no longer the pattern's line"; the comment above the body opens "Decision 018's reference pattern"; `docs/roadmap.md:49` words the step "exit 0: tests pass confined"

**Location:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:375-376`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citations and the comment's opening words.
**Legibility-target:** for-orchestrator-synthesis

Script `:220` is now `  fi`, inside the fallback-warning block (`:216-230`), not the body, which is at `:284-291`.
`:274` reads `# Decision 018's reference pattern (a static body, values as positional`.

**Evidence:** `scripts/confine-tests.sh:274`, `scripts/confine-tests.sh:284-291`, `docs/decisions/018-argv-exec-over-shell-string-interpolation.md:43`, `:117`, `docs/roadmap.md:49`

---

## Claim 31: Guide: "`bwrap` adds a read-only root, a private `/tmp` and a pid namespace to the network namespace. When `bwrap` is not installed or is unusable, a run falls back to `unshare -rn` ... The run goes ahead, and first prints a warning on stderr that names what is absent. `--probe` names the primitive it found (`bwrap` or `unshare`) on the first line of its stdout."

**Location:** `guides/test-hermeticity.md:59-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the profile, the warning's position and the probe's first stdout line on stand-ins; "the primitive it found" with `--no-loopback` and a working bwrap is the selected `unshare`, not the detected bwrap; the uid-0 sentence is not observable here.
**Legibility-target:** for-orchestrator-synthesis

Profile: `--ro-bind / / --dev /dev --proc /proc --tmpfs /tmp ... --unshare-net --unshare-pid` (`scripts/confine-tests.sh:253-264`).
Probe: `echo "confine-tests: primitive available: $primitive (loopback=$loopback)"` is the first stdout line
(`:196-200`); tests 7, 11, 14 pin it. The warning comes first on stderr (Claim 4).

**Evidence:** `scripts/confine-tests.sh:196-200`, `scripts/confine-tests.sh:253-264`; `$X/logs/bats-new.txt`

---

## Claim 32: Known gaps: "On the `unshare` fallback writes are not confined either (see 'Triage vs. ground truth')."

**Location:** `guides/test-hermeticity.md:183-184`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cross-reference and the code path (no mount isolation on the unshare forms); a real write is not observable here.
**Legibility-target:** for-orchestrator-synthesis

The section `## Triage vs. ground truth` (`guides/test-hermeticity.md:42`) holds the new paragraph (`:59-63`). Both unshare
run forms pass only `-rn` (`scripts/confine-tests.sh:285`, `:292`).

**Evidence:** `guides/test-hermeticity.md:42`, `guides/test-hermeticity.md:59-63`, `scripts/confine-tests.sh:285-292`

---

## Claim 33: Header: "A weaker primitive is a warning, on every run ... When bwrap is not installed or is unusable, the run falls back to unshare and goes ahead, and says first, on stderr, what that leaves unconfined. A --probe that falls back prints its verdict, which names the primitive, and not this warning."

**Location:** `scripts/confine-tests.sh:29-35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers runs that reach the run block on both fallback causes, with and without `--no-loopback`, and every fallback probe; runs refused before the run block (no `ip`, no command) print no warning, which the header's "the run ... goes ahead" implies.
**Legibility-target:** for-orchestrator-synthesis

All 1650 runs: every fallback run that reaches the run block prints the warning first (`warn` in each
category of `$X/logs/classify.txt`), and every fallback probe is identical to 23ffb16c.

**Evidence:** `scripts/confine-tests.sh:147-152`, `scripts/confine-tests.sh:196-232`; `$X/logs/diff-results.txt`, `$X/logs/classify.txt`

---

## Claim 34: LOOPBACK: "Where bwrap works, the script says so, in the fallback warning's words, on a run and on a --probe, and refuses outright when unshare is unusable. Where bwrap does not work, the flag changes nothing about the primitive, and a run prints the fallback's warning."

**Location:** `scripts/confine-tests.sh:42-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both flag orders with bwrap ok, refused and missing and unshare ok, refused and missing; "in the fallback warning's words" holds for the shared lines only (headline and way back differ by design).
**Legibility-target:** for-orchestrator-synthesis

Bwrap ok, unshare ok: the warning on `--no-loopback --probe` and on a run (tests 11 and 20). Unshare
refused: exit 2 with `--no-loopback is not supported by the bwrap primitive.` (test 13, `:176-181`). Bwrap
refused or missing: detection already chose unshare (`:142-152`); the selection block needs
`primitive == bwrap` (`:168`); a run prints the fallback headline (test 15, `:400`).

**Evidence:** `scripts/confine-tests.sh:142-183`, `scripts/confine-tests.sh:216-230`; `$X/logs/bats-new.txt`, `$X/logs/diff-results.txt`

---

## Claim 35: warn_unshare_only's comment: "$2 is its first words, which finish the last shared line, and each further argument is a line of its own. That split keeps the --no-loopback warning byte for byte what it was before the text was shared, so no --probe prints anything it did not print before."

**Location:** `scripts/confine-tests.sh:124-130`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 99 probe runs (bwrap ok / refused / missing × unshare ok / refused / missing × ip ok / missing / fails, none, flags `--probe`, `--no-loopback --probe`, `--probe --no-loopback`, `sh` dash / bash / absent) and all `--no-loopback` runs with a working bwrap; does not cover `-h`, whose text changed (not a probe).
**Legibility-target:** for-orchestrator-synthesis

The 99 probe runs in `$X/logs/diff-results.txt` are all `SAME` (stdout, stderr and status). With bwrap ok,
every route except `-h` is `SAME` (441 of 450). `cmp $X/logs/p6.old.err $X/logs/p6.new.err` succeeds.

**Evidence:** `scripts/confine-tests.sh:131-140`, `scripts/confine-tests.sh:171-174`; `$X/logs/diff-results.txt`, `$X/logs/p6.new.err`

---

## Claim 36: "Detection settled for unshare: bwrap is not installed, or its probe failed. A run says so before it starts"

**Location:** `scripts/confine-tests.sh:147-148`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `detect_primitive`'s two branches; does not cover a bwrap that is on PATH but not executable (then `command -v` does not find it and the "not installed" headline is printed).
**Legibility-target:** for-orchestrator-synthesis

`if command -v bwrap >/dev/null 2>&1 && bwrap --ro-bind / / --unshare-net -- true ...; then echo "bwrap"`, else the unshare branch (`scripts/confine-tests.sh:88-100`).

**Evidence:** `scripts/confine-tests.sh:88-100`, `scripts/confine-tests.sh:149-152`

---

## Claim 37: The run block's comment: "only a run that is about to start prints it: --probe's output and the refusals above are unchanged. `command -v` runs nothing. ... bwrap cannot keep `lo` down, so the flag would switch to unshare again"

**Location:** `scripts/confine-tests.sh:209-215`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe, the no-`ip` refusal (exit 3), the `--no-loopback` refusal (exit 2) and no command (exit 2) on every setup; the later in-body refusal (`ip` fails inside the namespace, exit 3) does print the warning first, as it comes after this block ("above" excludes it).
**Legibility-target:** for-orchestrator-synthesis

All no-command, no-`ip` and `--no-loopback`-refusal cases are `SAME` in `$X/logs/diff-results.txt`. `command -v`
is the bash builtin lookup. The selection block switches to unshare whenever `primitive == bwrap` and
`loopback -eq 0` (`:168-170`).

**Evidence:** `scripts/confine-tests.sh:168-205`, `scripts/confine-tests.sh:216-230`; `$X/logs/diff-results.txt`

---

## Claim 38: The body's comment: "`--` ends exec's options so a command named `-a` is run (or not found), never read as one. It runs under "$BASH", the bash already running this script ... bash's exec takes options and needs the `--`, dash's takes none and would run `--` as the command ... bash's own errors read "confine-tests: unshare body: line N: ...", N a line of the body and not of this file."

**Location:** `scripts/confine-tests.sh:274-283`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12 and the stand-in unshare; does not establish that a real `unshare -rn` can start `"$BASH"`.
**Legibility-target:** for-orchestrator-synthesis

`exec unshare -rn -- "$BASH" -c '...exec -- "$@"' "confine-tests: unshare body" "${cmd[@]}"` (`:285-290`).
Dash: `dash: 1: exec: --: not found` (`$X/logs/dash-exec-dashdash.txt`). Error text, with N = 6 (the body's
`exec` line, its line 1 being empty): `confine-tests: unshare body: line 6: exec: adir: not found`
(`$X/logs/diff-results.txt`). `$BASH`: Claim 16.

**Evidence:** `scripts/confine-tests.sh:274-291`; `$X/logs/dash-exec-dashdash.txt`, `$X/logs/diff-results.txt`, `$X/logs/bashenv.txt`

---

## Claim 39: The brief's invariant as the branch claims it: no change to which primitive is chosen or to `--probe`

**Location:** `scripts/confine-tests.sh:142-205` (behaviour); claimed at `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:47`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 1650 stand-in runs (inputs as listed above, including an empty name, a directory, a non-executable file, a missing name and names starting `-`, with `sh` as dash, as bash and absent); the exit-status half of the invariant is Claim 21.
**Legibility-target:** for-orchestrator-synthesis

All 99 probes `SAME`; in all 369 differing runs the banner naming the primitive is identical old and new
(checked by script over `$X/logs/diff-results.txt`: `DIFFER blocks 369 banner mismatches 0`). The
differences are: the help text (33), the added warning (all fallback runs reaching the run block), body
error prefixes, the D1 statuses where `sh` is bash (`-record -x`, `-a x rec one`, `-nonexistent y`,
`-- x`, `-c echo hi`, `-a- q`, `-l rec`, `--help` as a command), and on dash hosts `''` and a
directory on PATH (Claim 21). Where `sh` is absent the old script fails every unshare-loopback run (127) and the new one works.

**Evidence:** `$X/logs/diff-results.txt`, `$X/logs/classify.txt`

---

## Claim 40: Test header: "Every test but one runs the script on a PATH built here: the real bash, cat and awk, plus stand-ins ... (no sh: the script runs none, and two tests add one to show it makes no difference)"

**Location:** `test/scripts/confine-tests.bats:8-11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the setup and the two tests that add `sh`; test 18 skips without dash.
**Legibility-target:** for-orchestrator-synthesis

`for tool in bash cat awk` (`:65`); test 3 runs the script on the ambient PATH (`:233`); only
`dash_named_on_unshare` adds `sh` (`:444`), used by tests 17 and 18. The new script runs every unshare
route with no `sh` (`$X/logs/diff-results.txt`, sh=none).

**Evidence:** `test/scripts/confine-tests.bats:55-83`, `test/scripts/confine-tests.bats:228-245`, `test/scripts/confine-tests.bats:443-465`

---

## Claim 41: LO_WARNING_TEXT comment: "byte for byte what the script printed before the fallback came to share its text: a --probe prints it too"

**Location:** `test/scripts/confine-tests.bats:29-31`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 26.
**Legibility-target:** for-orchestrator-synthesis

See Claim 26: test 11 passes against 23ffb16c.

**Evidence:** `$X/logs/bats-newtests-oldscript.txt`

---

## Claim 42: confine(): "Fails the test when ... -STATUS is given and is not the exit status (bats' `run -N`; it warns about a 127 it was not told to expect)"

**Location:** `test/scripts/confine-tests.bats:149-154`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Bats 1.8.2; does not cover other bats versions.
**Legibility-target:** for-orchestrator-synthesis

`if [[ "$1" == -[0-9]* ]]; then want=("$1"); shift; fi` and `run "${want[@]}" --separate-stderr ...`
(`:157`, `:162`). A two-test bats file (`$X/dq/n.bats`): `run -126 bash -c 'exit 127'` fails with
`expected exit code 126, got 127`; `run -127` passes. Without `-127`, the d03a3078 run shows `BW01: ... exited with code 127 ... Use run's return code checks, e.g. run -127`.

**Evidence:** `test/scripts/confine-tests.bats:155-165`; `$X/logs/bats-runN.txt`, `$X/logs/bats-at-d03a3078.txt`

---

## Claim 43: same_process: "This cannot see the body's own exec: the body runs under bash, which runs the last command of a -c string in place with or without it. The test with a command named eval sees it."

**Location:** `test/scripts/confine-tests.bats:167-172`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and the three last-line mutants; does not cover other bash versions' last-command optimisation.
**Legibility-target:** for-orchestrator-synthesis

m04 (bare `"$@"`) and m05 (`command -- "$@"`) each fail 17, 18 and 19 and pass 16, whose `same_process`
(`:419`) therefore did not see the missing `exec`. Test 19 (`:467-474`) fails under both. m03 (no `--`)
fails 17 and 18 (`$X/logs/mut-run.txt`).

**Evidence:** `test/scripts/confine-tests.bats:173-175`, `test/scripts/confine-tests.bats:467-474`; `$X/logs/mut-run.txt`

---

## Claim 44: New or changed test names and their in-test comments against their bodies (tests 11, 14, 15, 16, 17-20; the comments at `:368-369`, `:383-384`, `:397-399`, `:402`, `:420-423`, `:440-442`, `:450`, `:468`, `:478`, `:481-482`, `:487-488`, `:504`)

**Location:** `test/scripts/confine-tests.bats:327-508`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each name and comment against the assertions that follow it and the test run; does not claim the names list every assertion (test 20 also checks the `--no-loopback` route and a no-command run).
**Legibility-target:** for-orchestrator-synthesis

Test 15: the refusal is `stderr_lines[0]` (`refused 3 "$NO_IP"`, `:386`, `:388`), and m09 (warning at
selection) fails it. `stderr_lines[5]` is the second way-back line (headline, three heredoc lines, the EROFS
line, then `:401`). `calls unshare 5` is four probes plus the run. Test 16: `"$TOOLS/bash"` is what `$BASH`
is under the shebang on the built PATH (Claim 16). 17/18: `-a` names no file and the child count stays 1
(`:451-454`). 19: `call child 1 'touch pwned'`, `[ ! -e pwned ]`. 20: exact stderr equality on both
causes, `[ -z "$output" ]` on the first, the warning before the banner. All 21 pass
(`$X/logs/bats-new.txt`), and the mutants show each assertion can fail.

**Evidence:** `test/scripts/confine-tests.bats:327-508`; `$X/logs/bats-new.txt`, `$X/logs/mut-run.txt`

---

## Claim 45: bd312d15: "A test now compares the whole --no-loopback warning, and passes against the script at 23ffb16c too"; "Tests: 21 of 21; 22 of 22 mutants fail at least one test"; "Size: 270 code lines against 23ffb16c"; the fixed and not-changed lists with their finding numbers

**Location:** commit bd312d15 message
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts, the test, and agreement of each finding number with the rubric; the Notes' empty-name sentence is treated in Claim 21.
**Legibility-target:** for-orchestrator-synthesis

Test 11 against 23ffb16c: Claim 26. 21 of 21 and 22 of 22: Claims 22 and 27. `git diff --shortstat 23ffb16c..bd312d15 -- . ':!docs'`:
`3 files changed, 219 insertions(+), 51 deletions(-)` = 270. FC 22/35 and API 2 are rubric A1 and
cluster 2; Security 2 is C1; API 3 C2; API 4 C3; FC 3, API 1, API 6 are A2 and C4; FC 33b, 39, 45 are A3, A6,
A7; security 1 is C6 and security 3 C7; API 5 is A8 (rubric rows A1-A8, C1-C7, and its composition-check cluster 2).

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md:1-119`; `$X/logs/bats-newtests-oldscript.txt`, `$X/logs/mut-run.txt`

---

## Claim 46: ca6cf3be: a scratch copy "that printed one extra line on the fallback route, after the four shared lines, passed every test ... Each route's way back to bwrap's profile must now start on the sixth line ... 19 of 19 mutants now fail at least one test; the unchanged script passes 21 of 21."

**Location:** commit ca6cf3be message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 21 of 21 at ca6cf3be and 19 of 19 in the author's second log; the surviving mutant's code is not saved (its logged name is "the shared text differs on the fallback route"), and "sixth line" refers to that commit's warning shape, which bd312d15 changed.
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/bats-at-ca6cf3be.txt`: 21 `ok`, exit 0. `mutation-run-2.txt`: `SURVIVORS: none` with 19 mutants. At
ca6cf3be the warning was the headline plus four shared lines, so the way back started on line six
(`git show ca6cf3be:scripts/confine-tests.sh`, read).

**Evidence:** `$X/logs/bats-at-ca6cf3be.txt`; `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-dash-and-fallback/mutation-run-2.txt`

---

## Claim 47: de1f4bf9: "fired on 539 changed lines (301 of them the research doc; 238 code lines, no enforcement file, no high-risk path)"; "Size: 238 code lines against 23ffb16c"

**Location:** commit de1f4bf9 message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts; the imprecision is already recorded in the rubric as A7.
**Legibility-target:** for-author

The numbers are right (Claim 1), but 238 includes the guide's 11 lines, which are prose. Script and test
are 227. Recorded in the rubric as A7 ("the commit message stands (immutable)"). The pre-mortem was
corrected to "238 lines change outside `docs/` (227 in the script and its test, 11 in the guide)".

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md` (row A7); `git diff --numstat 23ffb16c..de1f4bf9`

---

## Claim 48: 7ecf6ee3: Relevant paths gains the test file; a paragraph on the fallback; "Last verified stays 2026-07-13"

**Location:** commit 7ecf6ee3 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the guide's diff; the paragraph's wording was changed once later (Claim 31 checks the current one).
**Legibility-target:** for-orchestrator-synthesis

`Relevant paths: ..., test/hermeticity-lint.bats, test/scripts/confine-tests.bats` and `Last verified: 2026-07-13`
(`guides/test-hermeticity.md:7-8`).

**Evidence:** `guides/test-hermeticity.md:7-8`, `guides/test-hermeticity.md:59-63`

---

## Claim 49a: 6465a156: "(constraint H2 in docs/constraints.md: a degraded primitive names what went unenforced)"

**Location:** commit 6465a156 message (same paraphrase in the brief, `docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md:13`, and test 20's name "(H2)")
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the paraphrase against H2's text; does not decide whether the brief's choice not to refuse is right (the brief requires the run to go ahead).
**Legibility-target:** for-author

H2 reads: "a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive
**refuses and names** what went unenforced" (`docs/constraints.md:6`). The paraphrase drops "refuses",
and refusing is exactly what this fallback does not do (the brief: "it does not turn the fallback into a
refusal", brief `:24`). Precise version: "H2 asks a degraded primitive to refuse and name what went
unenforced; the brief keeps the run going, so this does the naming half".

**Evidence:** `docs/constraints.md:6`, `docs/working/briefs/2026-11-10-confine-tests-dash-and-fallback.md:13`, `:24`

---

## Claim 49b: 6465a156: "--probe is unchanged for every input: the fallback's warning is printed only by a run that is about to start, after the refusals."

**Location:** commit 6465a156 message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script at 6465a156; the claim is true of bd312d15 (Claim 35), and the error is already recorded (rubric A5, bd312d15's message, research doc "Review").
**Legibility-target:** for-author

`--no-loopback --probe` with bwrap ok: `diff $X/logs/p6.old.err $X/logs/p6.at-6465a156.err` shows lines 5-7
changed (`with EROFS will succeed against the real filesystem.` / `Drop the flag to get the hardened profile ...`),
while old and bd312d15 compare equal (`$X/p6.sh`, 22:33, exit 0). Recorded in the rubric as A5 ("Stands (immutable)").

**Evidence:** `$X/logs/p6.old.err`, `$X/logs/p6.at-6465a156.err`, `$X/logs/p6.new.err`

---

## Claim 49c: 6465a156, the rest: the fallback warns first on stderr, its headline saying which cause, then goes ahead; the text is in one function called from both routes; "its line breaks moved"; "Tests: 21 of 21 pass"; the Notes on `--no-loopback` without bwrap

**Location:** commit 6465a156 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the script and tests at 6465a156; the line-break sentence describes that commit and was undone by bd312d15.
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/bats-at-6465a156.txt`: 21 `ok`, exit 0. Line breaks moved: Claim 49b's diff.

**Evidence:** `$X/logs/bats-at-6465a156.txt`, `$X/logs/p6.at-6465a156.err`

---

## Claim 50: bd657ce8: where sh is bash, `-- -a x CMD one` ran CMD and exited 0 and `-- -record -x` was refused; where dash, the line was right and `exec -- "$@"` is wrong; a name that is no file now exits 127; "The script no longer needs sh"; "Tests: 19 of 21 pass; the two left are the fallback warning"

**Location:** commit bd657ce8 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers stand-in runs; "not run under a real unshare" is stated by the commit itself.
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/bats-at-bd657ce8.txt`: 19 `ok`, failing 15 and 20, both on the fallback warning. Behaviours:
Claims 11, 16, 20; sh absent: Claim 39.

**Evidence:** `$X/logs/bats-at-bd657ce8.txt`, `$X/logs/diff-results.txt`

---

## Claim 51a: d03a3078: "7 of the 21 fail at this commit"; sh=bash refuses `-record -x` (exit 2, `exec: -r: invalid option`); "With sh linked to dash the same test fails only on the name bash's error will carry after the fix"; the unshare tests no longer put sh on the built PATH

**Location:** commit d03a3078 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the test file of d03a3078 against the 23ffb16c script.
**Legibility-target:** for-orchestrator-synthesis

`$X/logs/bats-at-d03a3078.txt` (and the same test file against `git show 23ffb16c:scripts/confine-tests.sh`):
failing 15-21, 14 `ok`. Test 17: `status: 2`, `sh: line 6: exec: -r: invalid option`. Test 18 fails at its
`$BODY_NAME`-style stderr check (line 440) with `sh: 6: exec: -a: not found` after the status checks pass.

**Evidence:** `$X/logs/bats-at-d03a3078.txt`, `$X/logs/bats-at-d03a3078-tests-old-script.txt`

---

## Claim 51b: d03a3078: the 7 failing tests fail "each for the reason it names"

**Location:** commit d03a3078 message
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure points at d03a3078; already recorded (rubric A4, research doc "Review").
**Legibility-target:** for-author

Tests 16, 19, 20 and 21 fail with `stub/unshare/unshare: line 29: exec: sh: not found`. That cause is named
in the message's third bullet, but test 20, the fallback-warning test, fails there on status 127 before its
warning assertion (`$X/logs/bats-at-d03a3078.txt`). Rubric A4 records this.

**Evidence:** `$X/logs/bats-at-d03a3078.txt`; `docs/reviews/code-review-rubric-2026-11-10-confine-tests-dash-and-fallback.md` (row A4)

---

## Claim 52: d28501cf: DD-1 picks `"$BASH"` with `exec -- "$@"`; DD-2 prints the fallback warning at run time only, the one candidate the brief leaves

**Location:** commit d28501cf message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the research doc and the code; not the decision's merits.
**Legibility-target:** for-orchestrator-synthesis

Research doc "Decision: Path A, candidate 2" and DD-2 "One survivor. **Path A: a.**"; code at `scripts/confine-tests.sh:216-230`, `:285-290`.

**Evidence:** `docs/working/research-2026-11-10-confine-tests-dash-and-fallback.md:181`, `:201`, `scripts/confine-tests.sh:216-230`, `scripts/confine-tests.sh:285-290`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/reviews/pre-mortem-2026-11-10-confine-tests-dash-and-fallback.md:14`): the prior-art grep returns 17 files at de1f4bf9, not the four named; say "returns 17 files, of which ..." or name only the relevant ones as a selection.
- **Claim 49b** (commit 6465a156): "--probe is unchanged for every input" was false at that commit (the re-wrap); already recorded (rubric A5), true from bd312d15.

### Stale
- None.

### Mostly Accurate
- **Claim 12** (research doc `:43`): D2's behaviour holds, but "this unit's new test failing at 23ffb16c" for that command is test 20, which fails there on the missing `sh` (127); test 15 is the one that fails on the warning.
- **Claim 13** (research doc `:47`): "the selection tests are untouched": tests 11 and 14 were changed to add the stderr pins; their selection assertions are untouched.
- **Claim 21** (research doc `:299`; bd312d15 Notes): true of what the review compared, but on a dash host a bare name matching a directory on PATH also moves 126 → 127, for the empty name's reason; neither the table nor the Notes say so.
- **Claim 23** (research doc `:326`): mutant m20 is "shared sentence ends its line", not "the first version's line breaks" (6465a156 broke the later lines differently).
- **Claim 24** (research doc `:329`): test 13 is also a `--no-loopback` test; the key's "11 and 12 are the `--no-loopback` tests" leaves it out.
- **Claim 47** (commit de1f4bf9): "238 code lines" includes the guide's 11; already recorded (rubric A7).
- **Claim 49a** (commit 6465a156; brief `:13`; test 20's "(H2)"): H2 says a degraded primitive "refuses and names"; the paraphrase drops "refuses", which this fallback by design does not do.
- **Claim 51b** (commit d03a3078): "each for the reason it names"; already recorded (rubric A4).

### Unverifiable
- None. (That a real `unshare -rn` starts `"$BASH"` is not claimed as fact anywhere on the branch; it is listed as a follow-up.)

Hallucination-pattern log: no Incorrect verdict here is a fabricated symbol, API or option, so nothing
qualifies for `docs/reviews/hallucination-patterns.md`. Claim 2 resembles the logged count/result-list
misstatements (e.g. "All 85 tests ... but the suites hold 97") in kind, not as a fabrication. The log
was not edited: this pass may write only this report.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-dash-and-fallback/docs/reviews/code-fact-check-report-final-rN-2026-11-10-confine-tests-dash-and-fallback.md (N your replicate number), structured per the code-fact-check skill, with a first line `Commit: bd312d15` and a bolded `**Commit:** bd312d15` header field.
- Answered: yes
- Out of scope: the whole-suite gate was not re-run (the brief says to read suite-1.txt and suite-1.head); nothing ran under a real namespace (this container exits 3 on `--probe`); the hallucination log was not edited (the pass may write only this report).
- Escalate: Claim 21's residual (on dash hosts, a bare command name that matches a directory on PATH now exits 127, not 126) is a second exit-status move outside the dash-named cases. It falls under the brief's "no change to exit statuses other than D1's" on the same footing as the recorded empty-name case. Route it to the api-consistency critic, or record it beside API 5 / rubric A8.
- Decisions I made: I counted the brief's invariant (primitive and `--probe` unchanged) as a claim the branch makes, citing the research doc's Invariants line. I treated sentences already recorded as wrong in the rubric (A4, A5, A7) as claims and gave them verdicts, noting where they are recorded. I split the 6465a156 message into three claims because its parts earn different verdicts.
