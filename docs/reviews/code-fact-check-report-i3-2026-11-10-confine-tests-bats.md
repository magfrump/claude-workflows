Commit: 7d77df6c

# Code Fact-Check Report

**Repository:** claude-workflows, worktree `/workspace/.claude/wt-2026-11-10-confine-tests-bats`, branch `test/confine-tests-bats`
**Scope:** `27b5e861..7d77df6c`: the changed lines of `docs/working/research-2026-11-10-confine-tests-bats.md` and `test/scripts/confine-tests.bats`, and the message of commit 7d77df6c. Unchanged lines are context only.
**Replication:** k=1 (loop pass, decision 031)
**Checked:** 2026-11-10
**Total claims checked:** 37
**Summary:** 31 verified, 2 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

**Execution provenance (applies to every `executed` claim).** Tools: bash 5.2.15, dash 0.5.12 (`/bin/sh` → `/usr/bin/dash`), bats 1.8.2, shellcheck as installed. The brief allows one repo write, so captured output is under the scratch root `/tmp/claude-1000/-workspace/ef8b0455-8f52-48b8-9dd3-f1af8e1680d1/scratchpad/2026-11-10-confine-tests-bats/fc-i3/` (written `FC/` below), not under `docs/reviews/execution-logs/`. Mutants and test-file variants were built by `FC/mutate.py`. It asserts that each edit's anchor text matches exactly once, copies `scripts/confine-tests.sh` and `test/scripts/confine-tests.bats` into `FC/runs/<mutant>__<testvariant>/` with the repo layout, and runs `timeout 300 bats --tap` there. Each run's full output is in that directory's `bats-output.txt`. Test-file variants: `head` (the file at 7d77df6c); `nosp-bwrap`, `nosp-direct`, `nosp-shc` (one `same_process` call line removed, from tests 8, 12 and 16 in that order); `nosp-all` (all three removed); `old-9d37c1ac` (`git show 9d37c1ac:test/scripts/confine-tests.bats`); `sh-bash` (setup links `$TOOLS/sh` to bash). An unmutated control (`orig`) passes 17 of 17 against every variant (`FC/logs/exec-variants.txt`). The harness runs exited 0 and print each mutant's bats rc. Timestamps (-08:00): baseline 12:56:23; 21 mutants 12:58:09; `exec` variants 12:59:07; warning copies 13:00:51; O3/O4 copies 13:01:54 and 13:02:23; warning copies against 27b5e861, about 13:03; shellcheck 13:06:00; named suites 13:06:33 to 13:09:55; bash/dash `-c` probe 13:10:34.

No claim matches an entry in `docs/reviews/hallucination-patterns.md`. No fabricated symbol was found, so nothing is added to the log, and the brief allows no second write anyway.

---

## Claim 1: Project state: "this branch adds one test file, this doc and its review loop's reports under `docs/reviews/`"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:5`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the set of files `a37733cc...HEAD` adds. Does not establish the brief's status change, which by the brief's own rule lands in the merge change and is not on the branch yet.
**Legibility-target:** for-orchestrator-synthesis

`git diff --stat a37733cc...HEAD` (cwd the worktree, exit 0, 13:05) lists 11 files, all additions: nine `docs/reviews/*-2026-11-10-confine-tests-bats.md` reports, `docs/working/research-2026-11-10-confine-tests-bats.md` (291 lines) and `test/scripts/confine-tests.bats` (419 lines). `11 files changed, 5185 insertions(+)`.

**Evidence:** `git diff --stat a37733cc...HEAD` output (transcribed above; the full stat is short)

---

## Claim 2: Task status: "the final full pass is done and its fixes made; a check of those fixes is next"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:6`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop's position as the rubric and the commit record it. Does not establish whether this check will be the last pass.
**Legibility-target:** for-orchestrator-synthesis

The rubric header says: "0 red; the final pass's findings are fixed in the next commit, and a check of that commit is still to run" (`docs/reviews/code-review-rubric-2026-11-10-confine-tests-bats.md:5`). The commit message ends: "A check of this commit's own prose follows as iteration 3."

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-bats.md:5`; `git log -1 7d77df6c`

---

## Claim 3: "Callers: ... briefs whose acceptance includes tests (this one among them) ask their loop to run `--probe`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:22`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the open briefs in `docs/working/briefs/` and the 45 under `closed/`. Does not establish what future briefs will say.
**Legibility-target:** for-author

Two open briefs carry the line: `docs/working/briefs/2026-11-10-confine-tests-bats.md:22` "Run `scripts/confine-tests.sh --probe`: on exit 0 the tests also pass confined; on exit 3 quote its first line ..." and the same sentence at `docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md:29`. But the open brief `docs/working/briefs/2026-11-07-canon-instances-pass.md`, whose acceptance requires tests (`:19` "... with bats tests that fail on each refusal's absence"), has no `--probe` line. No closed brief has the instruction either (0 files match `confine-tests.sh --probe`). The practice comes from `docs/roadmap.md:48-49`: "in briefs whose acceptance names tests, use its conditional wording (run `scripts/confine-tests.sh --probe`; ...". So it is a rule for writing new briefs, not something every such brief carries. A precise version: "briefs written since the 2026-11-07 research whose acceptance includes tests (this one among them) ask their loop to run `--probe`". Two of the three open briefs whose acceptance names tests do this.

**Evidence:** `docs/working/briefs/2026-11-10-confine-tests-bats.md:22`, `docs/working/briefs/2026-11-10-dev-cycle-skill-held-fixes.md:29`, `docs/working/briefs/2026-11-07-canon-instances-pass.md:16-24`, `docs/roadmap.md:45-50`

---

## Claim 4: "The test file was 395 lines at entry, 412 after pass 1's fixes and is 419 after the final pass's, inside the loop's re-check limit of about 800"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:37`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file's line count at 9d37c1ac, f36108e4 and 7d77df6c and the ~800 limit. Does not establish line counts of other non-docs files, of which there are none.
**Legibility-target:** for-orchestrator-synthesis

`git show <c>:test/scripts/confine-tests.bats | wc -l` gives 9d37c1ac 395, f36108e4 412, 27b5e861 412, 7d77df6c 419. `workflows/review-fix-loop.md:57`: "The unit's limit is ~800 lines (twice the entry cap) until a waiver sets another."

**Evidence:** `workflows/review-fix-loop.md:57`; the per-commit counts above (cwd the worktree, exit 0)

---

## Claim 5a: Gotchas: the health check's shellcheck flags the file without the `disable=SC2154` line, because shellcheck cannot see that bats sets `$stderr_lines`

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the health check's exact shellcheck command on the file as it was at 9d37c1ac. Does not re-run `test/scripts/health-check.bats` at 9d37c1ac (the "three tests" count is unchanged text).
**Legibility-target:** for-orchestrator-synthesis

The health check runs `shellcheck -x -e SC1091 -s bash -S warning "$f"` on every `.bats` file too (`scripts/health-check.sh:525`; the `.bats` collection is at `:503-507`). On the 9d37c1ac file that command exits 1 with one finding: `[ "${stderr_lines[0]}" = "$2" ]` → `SC2154 (warning): stderr_lines is referenced but not assigned.` The 9d37c1ac file has no `disable=SC2154` line. Its header goes straight from `# @category slow` to the description.

**Evidence:** `scripts/health-check.sh:503-525`; `FC/logs/shellcheck-9d37c1ac.txt` (cmd `timeout 60 shellcheck -x -e SC1091 -s bash -S warning sc/at-9d37c1ac.bats`, cwd `FC/`, rc 1, 13:06:00)

---

## Claim 5b: "I had run shellcheck on the file by hand before the first commit, seen this warning, and wrongly taken it for advice and not a gate."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:53`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's consistency with Claim 5a. The author's own account of a hand run leaves no trace in the repo.
**Legibility-target:** for-orchestrator-synthesis

paraphrased — no quote available because the claim concerns an action outside the repository. It is consistent with Claim 5a: the warning is what shellcheck prints on that file. Checking it would need the session's transcript.

**Evidence:** `docs/working/research-2026-11-10-confine-tests-bats.md:53`

---

## Claim 6: "FP-050 ... the script warns about this only when `--no-loopback` forces the switch. See defect D2."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:60`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the target of the pointer. Does not re-judge whether D2 is a defect.
**Legibility-target:** for-orchestrator-synthesis

D2 exists and is the plain-fallback warning: `:241` "**D2. A plain fallback to unshare prints no warning about what unshare does not confine.**" The warning echoes are only inside `if [[ "$primitive" == "bwrap" && "$loopback" -eq 0 ]]` (`scripts/confine-tests.sh:134-143`). `:259` "(There is no O2: it became D2 in the review.)"

**Evidence:** `docs/working/research-2026-11-10-confine-tests-bats.md:241,259`; `scripts/confine-tests.sh:134-143`

---

## Claim 7: G10: "`same_process` in the three run tests: the command's pid is the script's. At the `sh` body this bites only where `sh` is dash"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:132`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three call sites and the dash/bash split at the `sh` body under bash 5.2.15 and dash 0.5.12. Does not establish behaviour under other `sh` implementations (busybox ash, ksh) or other bash versions.
**Legibility-target:** for-orchestrator-synthesis

`same_process` is called at `test/scripts/confine-tests.bats:288` (bwrap run), `:332` (`--no-loopback` run) and `:395` (unshare run). It compares `$LOG/script-pid` with `$LOG/child-pid` (`:155`). The `sh` body mutant (m18) fails test 16 through `same_process` with the `head` file, and passes all 17 with `sh-bash` (Claim 13).

**Evidence:** `test/scripts/confine-tests.bats:154-156,288,332,395`; `FC/logs/exec-variants.txt`

---

## Claim 8: Rollback: "`git revert -m 1 <this branch's merge commit>` removes the test file, this doc, the review reports under `docs/reviews/` and the brief's status change."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:147`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the merge will carry, per the branch's contents and the brief's merge rule. Does not run the revert.
**Legibility-target:** for-orchestrator-synthesis

The branch adds the test file, this doc and nine reports (Claim 1). The brief requires the status change in the merge change: `docs/working/briefs/2026-11-10-confine-tests-bats.md:26` "In the change that merges this work, change this brief's status line from open to done." Today it reads `Status: open` (`:3`).

**Evidence:** `docs/working/briefs/2026-11-10-confine-tests-bats.md:3,26`; Claim 1

---

## Claim 9: "20 of 21 fail at least one test" (beside the redefined `exec` row)

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 21 mutants rebuilt from the table's descriptions (my reading of each; the `exec` four as the row now defines them, with `exit $?` after bwrap and `unshare ... sh -c`). Does not establish that the author's copies were byte-identical to mine.
**Legibility-target:** for-orchestrator-synthesis

Against the `head` file, m01–m20 each fail at least one test and m21 (`set -uo pipefail`) fails none. Each mutant's failing tests match its row: m01/m02/m08 fail 8, 9, 10; m03 fails 16; m04/m05 fail 1, 2, 3; m06 fails 17; m07 fails 8; m09 fails 12 and 15; m10 fails 13; m11 fails 15; m12 fails 7, 11, 14, 15 ("four probe tests"); m13 fails 6; m14 fails 4; m15 fails 5; m16 fails 11 and 12; m17 fails 8; m18 and m19 fail 16; m20 fails 12.

**Evidence:** `FC/logs/mutants-head.txt`; `FC/mutate.py` (dict `M`, keys m01–m21)

---

## Claim 10: The `exec` row: with a plain call (plus `exit $?` at bwrap and `unshare ... sh -c`), each of the four fails "the run test of that form, and only through `same_process`: with that one line removed from the tests, all four pass"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:171`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers m17–m20 against `head` and against each one-line removal. Does not establish anything about the mutants without `exit $?` (Claim 11) or under bash as `sh` (Claim 13).
**Legibility-target:** for-orchestrator-synthesis

Against `head`, each mutant fails exactly one test, at `same_process`. m17 fails test 8 at line 288. m18 and m19 fail test 16 at line 395. m20 fails test 12 at line 332. With the matching line removed, each passes 17 of 17: m17 with `nosp-bwrap`, m18 and m19 with `nosp-shc`, m20 with `nosp-direct`. With a different line removed, each still fails (for example, m17 with `nosp-shc` fails test 8).

**Evidence:** `FC/logs/exec-variants.txt`; `FC/runs/m17-exec-bwrap__head/bats-output.txt`, `FC/runs/m19-exec-shc__head/bats-output.txt`, `FC/runs/m20-exec-direct__head/bats-output.txt`

---

## Claim 11: Note (b): "Without the `exit $?`, the bwrap and `unshare ... sh -c` mutants also fail, but for another reason: the script falls through to its next `exec`, which makes a call a stand-in does not accept or runs the command a second time."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:176`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers x17 (bwrap, no `exit`) and x19 (`sh -c`, no `exit`) against `head`, `nosp-all` and `old-9d37c1ac`. Does not establish other fall-through shapes.
**Legibility-target:** for-orchestrator-synthesis

x17 fails test 8 at `confine`'s `[[ ! -e "$LOG/unexpected" ]]` (`:146`). The script fell through to the `unshare ... sh -c` form, and its `ip` call under no mode was logged: `stub ip: unexpected call under STUB_IP=unset: 4: link set lo up`. x19 fails test 16 with `child was called 2 time(s), want 1`. The script fell through to `unshare -rn -- CMD` (`unshare.3`). Both fail with `same_process` removed and against the 9d37c1ac file too.

**Evidence:** `FC/logs/noexit.txt`; `FC/runs/x17-exec-bwrap-noexit__head/bats-output.txt`, `FC/runs/x19-exec-shc-noexit__head/bats-output.txt`

---

## Claim 12: Note (c): "Before `same_process` existed (the test file at 9d37c1ac), two of the four survived: the `sh` body and `unshare` direct."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:177`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four `exec` mutants in both forms against the 9d37c1ac file. The note is true only for the earlier form without `exit $?`. For the form the row above it now defines, it is false.
**Legibility-target:** for-author

The row at `:171` defines the four mutants with `exit $?` after bwrap and `unshare ... sh -c`, and note (a) says that each then fails only through `same_process`. The 9d37c1ac file has no `same_process` (no match in `git show 9d37c1ac:test/scripts/confine-tests.bats`). So the row's own logic predicts that all four survive there, and they do: m17, m18, m19 and m20 each pass 17 of 17 against `old-9d37c1ac`. Two of four survive only for the form note (b) describes, without `exit $?`, where the bwrap and `sh -c` mutants fail by fall-through (x17 and x19 fail test 8 and test 16 against `old-9d37c1ac`). A reader of the note under the row takes it to say the old tests caught the bwrap and `sh -c` mutants as defined. They did not; they caught only a fall-through. Precise version: "Before `same_process` existed (9d37c1ac), all four survived in the row's form; without the `exit $?`, two survived (the `sh` body and `unshare` direct), the other two failing only by falling through."

**Evidence:** `FC/logs/exec-variants.txt` (lines `m17..m20 [old-9d37c1ac] rc=0 fails=0`); `FC/logs/noexit.txt` (lines `x17/x19 [old-9d37c1ac] rc=1`); `docs/working/research-2026-11-10-confine-tests-bats.md:171,176-177`

---

## Claim 13: Note (d): "With `sh` on the test's PATH linked to bash, the `sh` body mutant passes every test, because bash runs the last command of a `-c` string in place whether or not it says `exec`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:178`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers bash 5.2.15 and dash 0.5.12 here. Does not establish older bash releases, which may fork the last command of a multi-command `-c` string (not tested; no older bash here).
**Legibility-target:** for-orchestrator-synthesis

m18 against `sh-bash` passes 17 of 17. m17, m19 and m20 still fail under `sh-bash`. A direct probe runs the body's shape, `if ! true; then exit 3; fi` then `"$@"`, under each shell with `bash -c 'echo "child=$$ parent=$PPID"'` as the command. Under bash, the shell's pid 2519336 is the child's (`child=2519336`), so it ran in place. Under dash, shell 2519337 forked child 2519338.

**Evidence:** `FC/logs/exec-variants.txt` (`m18-exec-shbody [sh-bash] rc=0`); `FC/shprobe.sh`, `FC/logs/shprobe.txt` (cmd `timeout 20 bash shprobe.sh`, cwd `FC/`, rc 0, 13:10:34)

---

## Claim 14: "Two more copies add a warning to every unshare fallback ... one prints it at run time after the banner, one at selection time before the `ip` check (so on probes too). Both pass every test"

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:180`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two-line stderr warnings at seven placements. Does not cover a warning on stdout at run time, which fails three tests, nor a fix that refuses the fallback instead of warning.
**Legibility-target:** for-orchestrator-synthesis

w1 (after the banner, `:178`) and w2 (before the `ip` check, `:154`, so on probes too) print two stderr lines whenever the primitive is unshare and `--no-loopback` did not force the switch. Both pass 17 of 17 against `head`, and again with `sh-bash`. To try to break the claim I added five more placements, all on stderr: before the banner (w3), inside `detect_primitive`'s unshare branch (w4), after the `ip` check and before `--probe` (w5), inside the `sh` body (w6), and on every unshare run including the forced one (w7). All pass 17 of 17, as does a stdout second line on the probe (w8). The only placement that fails is a stdout line at run time (w9). It fails tests 12, 16 and 17 on `[ -z "$output" ]`. The script prints its existing `--no-loopback` warning to stderr (`scripts/confine-tests.sh:137-143`), so a D2 fix would most likely use stderr too.

**Evidence:** `FC/logs/warnings.txt`; `FC/mutate.py` (keys w1–w9); `FC/runs/w9-stdout-run__head/bats-output.txt`

---

## Claim 15a: Not covered: "D2 ... behaviour I did not judge clearly right, so no test pins it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stderr placements of Claim 14. Does not cover a stdout warning at run time (w9 fails).
**Legibility-target:** for-orchestrator-synthesis

See Claim 14: seven stderr placements of a fallback warning pass every test.

**Evidence:** `FC/logs/warnings.txt`

---

## Claim 15b: Not covered: "... O3 ... below: behaviour I did not judge clearly right, so no test pins it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:213`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers two O3 fixes. Test 5 pins the order that O3 names as its cause; no test pins O3's exit status.
**Legibility-target:** for-author

O3 reads: "No primitive and no command exits 3, not 2. Detection comes before the empty-command check." (`:255`). No test asserts exit 3 for no primitive and no command. But test 5 pins the order: it runs with no command and a primitive available, and requires the probes to have run, `calls bwrap 3 unshare 1` (`test/scripts/confine-tests.bats:247-248`, "Probes only ... nothing was asked to run"). A fix that moves the empty-command check (probe exempt) before detection (`o3-fix`) fails test 5 with `bwrap was called 0 time(s), want 3`. A fix that keeps detection first and returns exit 2 for a missing command only inside the no-primitive branch (`o3-fix-inrefusal`) passes 17 of 17. Precise version: "O3's exit status is not pinned; test 5 pins detection before the empty-command check, so a fix that reorders them must change test 5."

**Evidence:** `test/scripts/confine-tests.bats:238-249`; `FC/logs/o3-o4.txt`; `FC/runs/o3-fix__head/bats-output.txt`

---

## Claim 15c: Not covered: "... O4 below: behaviour I did not judge clearly right, so no test pins it."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:213`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the wording of the first line, which is O4's subject. Does not establish freedom to drop the second line: test 4 requires stderr's second line to start `Usage: `, so a one-line rewording fails.
**Legibility-target:** for-orchestrator-synthesis

For a command given without `--`, test 4 checks only `[ "$status" -eq 2 ]` and `[[ "${stderr_lines[1]}" == "Usage: "* ]]` (`test/scripts/confine-tests.bats:232-234`), not the `unknown flag:` text. A copy that prints `confine-tests: a test command goes after --: <word>` for a word not starting with `-`, and keeps the usage line (`o4-fix`), passes 17 of 17. A one-line version (`o4-fix-oneline`) fails test 4. Medium confidence because whether "pins it" covers the line count is a matter of reading.

**Evidence:** `test/scripts/confine-tests.bats:228-236`; `FC/logs/o3-o4.txt`

---

## Claim 16: "For D2 that took the review two rounds. Pass 1 found that an exact match on stderr in an unshare run test pinned the missing warning; the final pass found two more places (an empty-stderr check on the fallback `--probe`, and a first-line check on the `ip` refusal). All now only require the line they are about to be present."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:213`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the attribution to the two rounds' reports, the two assertions at 27b5e861, and the assertions now. Does not establish which replicate found each item first.
**Legibility-target:** for-orchestrator-synthesis

Pass 1: `docs/reviews/security-review-2026-11-10-confine-tests-bats.md:93` "The exact-stderr assertion in the unshare-run test fails as soon as the script warns on the plain unshare fallback". Final pass: `docs/reviews/code-fact-check-report-final-r2-2026-11-10-confine-tests-bats.md:562` names test 14's `[ -z "$stderr" ]` and test 15's `refused 3 "$NO_IP"`, and `docs/reviews/security-review-final-2026-11-10-confine-tests-bats.md:35` names the first. Re-run: the selection-time copy w2 against the 27b5e861 file fails 14 (`[ -z "$stderr" ]' failed`) and 15 (`refused 3 "$NO_IP"' failed`), and the run-time copy w1 passes. Now the assertions are `[[ "$stderr" == *"$NO_IP"* ]]` (`test/scripts/confine-tests.bats:364,368`) and the banner glob (`:389`), and test 14 checks only stdout's first line (`:351,355`).

**Evidence:** the three report lines above; `FC/logs/warn-at-27b5e861.txt`; `test/scripts/confine-tests.bats:348-369,389`

---

## Claim 17: "O1 and O5 below are about the argv the script hands bwrap. The stand-in pins that argv exactly as it is today (DD-2), so a change to the probe or to the profile means changing the stand-in and the expected argv in the same commit."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:214`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe and run argv of bwrap. Does not establish anything about the real bwrap.
**Legibility-target:** for-orchestrator-synthesis

The stand-in accepts only exact argv: `is() { [[ "$(q "${argv[@]}")" == "$(q "$@")" ]]; }` (`test/scripts/confine-tests.bats:98`). bwrap's probe must be `is --ro-bind / / --unshare-net -- true` (`:106`) and its run the fixed `profile` plus the command (`:103-108`). The tests hold their own copies, `call bwrap 1 --ro-bind / / --unshare-net -- true` (`:199,272`) and `PROFILE=(...)` (`:63-65`). Dropping `--unshare-net` or `--setenv TMPDIR /tmp` from the run (m01, m02) fails tests 8–10.

**Evidence:** `test/scripts/confine-tests.bats:63-65,98-113,199,272`; `FC/logs/mutants-head.txt`

---

## Claim 18: D1: "The review's security passes suggest three candidate fixes, none of which I ran: `command -- "$@"` (they saw it behave correctly under both shells, at the cost of the `exec`), running the body under bash with `exec -- "$@"`, or refusing a command whose name starts with `-`."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:239`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the attribution of each fix to the security reports and what they say about it. "None of which I ran" is the author's own account and cannot be checked (see the note on the `command --` evidence).
**Legibility-target:** for-orchestrator-synthesis

Pass 1: `docs/reviews/security-review-2026-11-10-confine-tests-bats.md:63` "`command -- "$@"` (observed correct under both dash and bash, above) is one candidate; it gives up the `exec`". The final pass names the other two: `docs/reviews/security-review-final-2026-11-10-confine-tests-bats.md:90` "run the body with bash explicitly (`unshare -rn -- bash -c '... exec -- "$@"' bash "${cmd[@]}"` ...), or refuse a `cmd[0]` beginning with `-` with exit 2". So the attribution is right. One note: the transcript pass 1 shows "above" (`:55-60`) runs `command --` under bash only. I ran it under both: with a `-a` on PATH, `dash -c 'command -- "$@"' sh -a x echo one` and the bash equivalent each print `ran -a: x echo one` and exit 0. So the report's statement holds.

**Evidence:** `docs/reviews/security-review-2026-11-10-confine-tests-bats.md:55-63`; `docs/reviews/security-review-final-2026-11-10-confine-tests-bats.md:90,188`; the `command --` probe (cwd `FC/`, about 13:05, rc 0 both; output transcribed above)

---

## Claim 19: D2: "No test pins the warning's absence: two copies of the script that add it, at run time and at selection time, pass every test ("Mutation run")."

**Location:** `docs/working/research-2026-11-10-confine-tests-bats.md:250`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As for Claim 14: stderr warnings; not a stdout warning at run time.
**Legibility-target:** for-orchestrator-synthesis

w1 and w2 pass 17 of 17 (Claim 14).

**Evidence:** `FC/logs/warnings.txt`

---

## Claim 20: confine(): "Fails the test when a stand-in got a call it does not accept."

**Location:** `test/scripts/confine-tests.bats:135-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers calls the stand-in rejects (argv not listed, or the mode has no case for it). Does not cover a call the stand-in accepts and answers with failure, such as `refused`, which by design does not fail the test.
**Legibility-target:** for-orchestrator-synthesis

Any call that reaches the stand-in's tail is logged: `printf 'stub %s: unexpected call ...' >> "$STUB_LOG/unexpected"; exit 99` (`:128-129`). That covers an unlisted argv, and also a listed argv whose mode has no case (the `case` statements fall through). `confine` ends with `[[ ! -e "$LOG/unexpected" ]]` (`:146`). x17 shows it firing: test 8 fails at line 146 on `stub ip: unexpected call under STUB_IP=unset`.

**Evidence:** `test/scripts/confine-tests.bats:94-147`; `FC/runs/x17-exec-bwrap-noexit__head/bats-output.txt`

---

## Claim 21: same_process: "(The stand-in execs the command too; what a real primitive does with it is not tested.)"

**Location:** `test/scripts/confine-tests.bats:151-152`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bwrap and unshare stand-ins' run branches. No test uses a real primitive's run (the ambient test only probes, or runs on a refusal).
**Legibility-target:** for-orchestrator-synthesis

bwrap: `ok) shift "${#profile[@]}"; exec -- "$@" ;;` (`:110`). unshare: `shift 2; exec -- "$@"` (`:119`). The one test without stand-ins runs `--probe`, and runs a command only on exit 3, where the script refuses (`:214-223`).

**Evidence:** `test/scripts/confine-tests.bats:108-120,209-226`

---

## Claim 22: same_process: "Where sh is bash this cannot see the sh body's exec: bash runs the last command of a -c string in place with or without it."

**Location:** `test/scripts/confine-tests.bats:152-153`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As for Claim 13: bash 5.2.15. Does not establish older bash releases.
**Legibility-target:** for-orchestrator-synthesis

See Claim 13: m18 passes every test with `sh-bash`, and the probe shows bash running the last command in its own pid.

**Evidence:** `FC/logs/exec-variants.txt`; `FC/logs/shprobe.txt`

---

## Claim 23: "The refusal need not be stderr's first line: a fallback to unshare may come to warn before it (research doc, D2), and that is not pinned here."

**Location:** `test/scripts/confine-tests.bats:360-361`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this test's two refusal checks. Does not cover the other tests (Claim 14 covers those).
**Legibility-target:** for-orchestrator-synthesis

The checks are `[[ "$stderr" == *"$NO_IP"* ]]` (`:364`) and `[[ "$stderr" == *"$NO_IP"* && "$stderr" == *"--no-loopback"* ]]` (`:368`). w2 and w4, which warn before the `ip` check, pass this test (17 of 17). Against the 27b5e861 file, w2 failed it at `refused 3 "$NO_IP"`.

**Evidence:** `test/scripts/confine-tests.bats:359-381`; `FC/logs/warnings.txt`; `FC/logs/warn-at-27b5e861.txt`

---

## Claim 24: The two loosened tests' names: "--probe reports unshare when bwrap is not installed, or is installed and refused" and "unshare without ip is refused (exit 3), probe or run, and serves --no-loopback"

**Location:** `test/scripts/confine-tests.bats:348`, `:359`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each name against its body as it now stands. Does not judge test strength.
**Legibility-target:** for-orchestrator-synthesis

Test 14: `confine "unshare ip" STUB_UNSHARE=ok -- --probe` (no bwrap) and `confine "bwrap unshare ip" STUB_BWRAP=refused STUB_UNSHARE=ok -- --probe` each give exit 0 and `lines[0]` = `... primitive available: unshare (loopback=1)` (`:349-355`). Test 15: probe and run each give `status -eq 3`, `$NO_IP` in stderr and empty stdout, with `calls child 0` (`:362-370`). Then `--no-loopback --probe` and `--no-loopback -- -record -x` each give exit 0, and the child runs with `-x` (`:371-380`).

**Evidence:** `test/scripts/confine-tests.bats:348-381`

---

## Claim 25: Commit message: "the final confirming pass (full branch at 27b5e861, k=3 fact-check, security and performance critics) found no red and nothing wrong in the test code's behaviour. Its findings were prose in the research doc, two comments, and two assertions."

**Location:** commit 7d77df6c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric's summary. Does not re-derive each replicate's findings.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/code-review-rubric-2026-11-10-confine-tests-bats.md:11` "Pass 2 (iteration 2 of 3, the final confirming pass, full branch at 27b5e861 ...): k=3 fact-check"; `:19` "No replicate found anything wrong in the test code ... they are 🟡, not 🔴"; `:5` "0 red". The two assertions are A11 (`:45`) and the two comments are in A13 and C8.

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-bats.md:5,11,19,45,47`

---

## Claim 26: Commit message: "A11: the fallback --probe test no longer requires an empty stderr, and the unshare-without-ip test no longer requires the ip refusal to be stderr's first line. Both pinned the missing fallback warning (D2) while the doc said nothing did."

**Location:** commit 7d77df6c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff and a selection-time warning against the 27b5e861 file. A run-time warning did not trip either assertion.
**Legibility-target:** for-orchestrator-synthesis

The diff removes `[ -z "$stderr" ]` from test 14 and replaces `refused 3 "$NO_IP"` (whose `stderr_lines[0]` check is at `:182`) with glob checks. w2 against the 27b5e861 file fails both. The doc at 27b5e861 read "No test pins the warning's absence." (removed line in the `:250` hunk).

**Evidence:** `git diff 27b5e861..7d77df6c`; `FC/logs/warn-at-27b5e861.txt`

---

## Claim 27: Commit message: "Copies of the script that warn at run time and at selection time now pass all 17 tests."

**Location:** commit 7d77df6c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As for Claim 14.
**Legibility-target:** for-orchestrator-synthesis

w1 and w2 pass 17 of 17 (`rc=0 fails=0`).

**Evidence:** `FC/logs/warnings.txt`

---

## Claim 28: Commit message: "C8, A13: the same_process comment drops a claim about the real bwrap that cannot be checked here and says the sh-body pin holds only where sh is dash; confine()'s comment no longer says 'refused'."

**Location:** commit 7d77df6c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff of the two comments. The comment says "where sh is bash" it cannot see the exec; it says nothing about other shells, which is a slightly narrower statement than "only where sh is dash".
**Legibility-target:** for-orchestrator-synthesis

Removed: `# the command. (A stand-in execs the command too; the real bwrap forks it.)` and `Fails the test when a stand-in refused a call.` Added: `what a real primitive does with it is not tested.) Where sh is bash this cannot see the sh body's exec` and `Fails the test when a stand-in got a call it does not accept.`

**Evidence:** `git diff 27b5e861..7d77df6c -- test/scripts/confine-tests.bats`; `test/scripts/confine-tests.bats:135-136,151-153`

---

## Claim 29: Commit message: "(A10: the four mutants are written so nothing falls through and fail only through same_process; two survived before it, not one; dash-only at the sh body)"

**Location:** commit 7d77df6c message
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "two survived before it" part. The other two parts (fail only through `same_process`; dash-only at the `sh` body) are verified in Claims 10 and 13.
**Legibility-target:** for-author

This is the same fault as Claim 12. In this sentence "the four mutants" are the ones "written so nothing falls through", and all four of those survive against the 9d37c1ac file (m17–m20 `[old-9d37c1ac] rc=0`). Two survived only in the form that falls through (x17 and x19 fail there).

**Evidence:** `FC/logs/exec-variants.txt`; `FC/logs/noexit.txt`

---

## Claim 30: Commit message: research doc changes: "the dangling O2 pointer (A12); what O1 and O5 do pin; the review reports named in Project state and Rollback; how the shellcheck warning was first missed."

**Location:** commit 7d77df6c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed change's presence in the diff. Their accuracy is in Claims 1, 5, 6, 8 and 17.
**Legibility-target:** for-orchestrator-synthesis

The diff changes `See observation O2.` → `See defect D2.`, adds the O1/O5 bullet at `:214`, adds the reports to `:5` and `:147`, and adds the hand-run sentence at `:53`.

**Evidence:** `git diff 27b5e861..7d77df6c -- docs/working/research-2026-11-10-confine-tests-bats.md`

---

## Claim 31: Commit message: "Size: 419 code lines against a37733cc"

**Location:** commit 7d77df6c message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the brief's numstat command. Does not cover docs, which the count excludes by rule.
**Legibility-target:** for-orchestrator-synthesis

`git diff --numstat a37733cc...HEAD -- ':(top)' ':(top,exclude)docs/'` (cwd the worktree, exit 0) prints exactly `419	0	test/scripts/confine-tests.bats`.

**Evidence:** command output transcribed above (one line)

---

## Claim 32: Commit message: "the affected suites (health-check, confine-tests, fixture-hermeticity) pass, 59 of 59"

**Location:** commit 7d77df6c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three suites at 7d77df6c in this container. Does not cover the whole suite.
**Legibility-target:** for-orchestrator-synthesis

No other `bats`/`run-tests` process was running beforehand (`ps`), so the lock was free. `timeout 590 scripts/run-tests.sh test/scripts/health-check.bats test/scripts/confine-tests.bats test/fixture-hermeticity.bats`, cwd the worktree, started 13:06:33 and ended 13:09:55 with rc 0. Output: 59 lines `ok`, 0 `not ok`. Nothing was left running afterwards.

**Evidence:** `FC/logs/suites.txt`, `FC/logs/suites.ts`

---

## Claim 33: Commit message: "all 21 mutants and the two warning copies were re-run against this test file"

**Location:** commit 7d77df6c message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether the results the doc reports reproduce. Whether the author ran them is not checkable, and the copies were not committed.
**Legibility-target:** for-orchestrator-synthesis

My rebuild reproduces every result the doc gives for the 21 mutants and the two warning copies against this file (Claims 9, 10, 14). The one result it does not reproduce is the 9d37c1ac survivor count in the row's form (Claim 12). That suggests the 9d37c1ac run used the copies without `exit $?`. To verify the act itself, the author's scratch copies or logs are needed.

**Evidence:** `FC/logs/mutants-head.txt`, `FC/logs/warnings.txt`, `FC/logs/exec-variants.txt`

---

## Claim 34: Commit message: "No override-log rows, for the reason the rubric gives."

**Location:** commit 7d77df6c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric stating a reason. Does not judge the reason.
**Legibility-target:** for-orchestrator-synthesis

`docs/reviews/code-review-rubric-2026-11-10-confine-tests-bats.md:68` "Override-log rows: none written. `docs/reviews/override-log.md` is not one of this brief's files and sits on the self-merge floor ..."

**Evidence:** `docs/reviews/code-review-rubric-2026-11-10-confine-tests-bats.md:68`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12** (`docs/working/research-2026-11-10-confine-tests-bats.md:177`): "two of the four survived" at 9d37c1ac holds only without the `exit $?`. In the row's own form, all four pass the 9d37c1ac file. State both forms.
- **Claim 29** (commit 7d77df6c message): "two survived before it, not one" has the same fault as Claim 12, because the same sentence defines the four as written so nothing falls through.

### Mostly Accurate
- **Claim 3** (`docs/working/research-2026-11-10-confine-tests-bats.md:22`): not every brief whose acceptance includes tests asks for `--probe`. The open `2026-11-07-canon-instances-pass.md` brief requires bats tests and has no such line. Say "briefs written since the 2026-11-07 research".
- **Claim 15b** (`docs/working/research-2026-11-10-confine-tests-bats.md:213`): O3's exit status is not pinned, but test 5 (`test/scripts/confine-tests.bats:248`) pins detection before the empty-command check, which is O3's stated cause. A reordering fix fails test 5.

### Unverifiable
- **Claim 5b** (`docs/working/research-2026-11-10-confine-tests-bats.md:53`): the author's hand-run shellcheck. It is consistent with the warning shellcheck gives, but needs the session transcript.
- **Claim 33** (commit 7d77df6c message): that the re-runs were done. The results reproduce except for the 9d37c1ac count; the act needs the author's logs.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-2026-11-10-confine-tests-bats/docs/reviews/code-fact-check-report-i3-2026-11-10-confine-tests-bats.md, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: unchanged lines and earlier commits (context only); bash versions other than 5.2.15 for the `-c` in-place claim (none here); a whole-suite run (only the three named suites were run, as briefed). Execution logs are in the scratch directory, not `docs/reviews/execution-logs/`, because the brief allows one repo write.
- Escalate: nothing
