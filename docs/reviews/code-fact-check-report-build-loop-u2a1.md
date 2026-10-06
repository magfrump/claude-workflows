Commit: d48f4645

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d48f4645, commits 6f624cdf, 706e0499, d48f4645): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, docs/working/plan-build-loop-handoff.md, docs/working/questions.md (Q-119), the rubric `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md`, the five new `feat/build-loop-u2a1` rows of docs/reviews/override-log.md, and the messages of 6f624cdf, 706e0499 and d48f4645. Other docs/reviews/*.md artifacts were skipped by all three replicates. Merged from `code-fact-check-report-build-loop-u2a1-r1.md` (40 claims), `-r2.md` (34) and `-r3.md` (37), all at d48f4645.
**Commit:** d48f4645
**Replication:** k=3
**Checked:** 2026-10-06
**Total claims checked:** 53
**Summary:** 44 verified, 9 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Merge method: code-review skill, "Merging replicate verdicts (most-severe-wins)". Claims were clustered on (file, line range ±5, substance). Where any replicate split a sentence that another verdicted as one compound claim, the merged report emits the finer rows (`Na`/`Nb`) and records the compound verdict on each row as `(compound)`. Evidence and reasoning come from the replicate that assigned the winning verdict, named in each claim as "carried from rN Claim M". Paths such as `$FC/logs/...` and `logs/...` are relative to that replicate's own run root (see Execution provenance). No claim or evidence was added in the merge.

## Execution provenance (per replicate, as each recorded it)

- **r1:** `FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/fc1`. It ran against a `git archive` export of d48f4645 at `$FC/copy` and of main 900c47d0 at `$FC/maincopy`, with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and `TMPDIR=$FC/tmp`. Test 25 alone used a `mktemp -d /tmp/u2a1fc-XXXX` TMPDIR, deleted afterwards. Every command ran under `timeout`, with logs in `$FC/logs/`. Runs took place 2026-10-06T16:18Z-16:25Z. Mutants ran only on throwaway copies (`$FC/mut-*`, deleted). No process was left running, and the victim repos were deleted.
- **r2:** `FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/fc2`. It used exports of d48f4645 (`$FC/copy`), main 900c47d0 (`$FC/maincopy`) and 6f624cdf (`$FC/c1`), with the same git config isolation and TMPDIR `$FC/tmp`, or `/tmp/u2a1fc-XXXX` (deleted) for runs that include test 25. Probe scripts are in `$FC/bin/` and logs in `$FC/logs/`. Runs took place 2026-10-06T16:19Z-16:30Z. No process was left running.
- **r3:** `S=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-final/fc3/wt` (an export of d48f4645), with logs in `fc3/logs/`. Mutants ran on `fc3/mut-*` copies, removed after each run. Git config was isolated as above and every process ran under `timeout`. Its E1-E15 run table is in `-r3.md`.

All three replicates consulted `docs/reviews/hallucination-patterns.md`. They matched the per-suite test-count claims against the logged pattern ("All 85 tests ... claimed in commit 59ca38f", "mode1-equiv 33 claimed in commit 37c5ea9"), and every count matched this time.

## Claims Requiring Attention (summary)

| Claim | Location | Verdict | Replicate verdicts | Gist |
|---|---|---|---|---|
| 3 | `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:17` | Mostly accurate | r1=— · r2=Verified · r3=Mostly accurate | "the diff addresses each" row, except row 319's short-line residue at lib `:25` |
| 7 | `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26` | Mostly accurate | r1=MA · r2=MA (compound) · r3=MA | A6 "Fixed: reflowed" is partial: lib `:25` is still 52 columns and `:16` is now 96 |
| 13 | `docs/reviews/override-log.md:325` | Mostly accurate | r1=MA · r2=MA · r3=Verified | measured ~0.4-0.5 ms per subshell and ~18-37 µs per pair, against the stated ~0.3 ms and ~17 µs |
| 21a | `scripts/dev-cycle.sh:167-168` | Mostly accurate | r1=MA · r2=MA (compound) · r3=MA | "the skip message below repeats it": it takes three skip messages to do so |
| 25a | `scripts/lib/dev-cycle-read.sh:280-281` | Mostly accurate | r1=V (compound) · r2=V (compound) · r3=MA | "$2 is the path, named in the reason": the notdir arm ignores `$2` |
| 37 | commit 6f624cdf message | Mostly accurate | r1=MA · r2=MA · r3=— | "the lib's check_fix": check_fix is in `scripts/dev-cycle.sh:170` (already Accepted-immutable) |
| 38a | commit 706e0499 message | Mostly accurate | r1=V (compound) · r2=MA · r3=V (compound) | "4 Minor" counts A6, which is a fact-check Mostly accurate |
| 41b | commit d48f4645 message | Mostly accurate | r1=MA (compound) · r2=MA · r3=MA | the Notes line "old sentences come back except where a path is now named" understates the rewording |
| 42 | commit d48f4645 message | Mostly accurate | r1=MA · r2=MA · r3=MA (compound) | "A6: ... short lines reflowed": the same residue as Claim 7 |

---

## Claim 1a: "`code-fact-check-report-build-loop-u2a1.md`: k=1. 24 claims: 20 Verified, 3 Mostly accurate, 1 Unverifiable, 0 Incorrect."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the tally against the iteration-1 report's header. It does not re-verdict that report's 24 claims.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: "It does not establish that those reports' own findings are correct." · merge note: the iteration-1 report that r1 and r3 cite is the k=1 report this merged file replaces. Read it as `git show d48f4645:docs/reviews/code-fact-check-report-build-loop-u2a1.md`.

Carried from r1 Claim 1. The iteration-1 report's header reads `**Total claims checked:** 24` and `**Summary:** 20 verified, 3 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:8-9` at d48f4645). r3 counted the `**Verdict:**` lines in the same report and got 20 Verified, 3 Mostly accurate and 1 Unverifiable.

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`, `d48f4645:docs/reviews/code-fact-check-report-build-loop-u2a1.md:8-9`

---

## Claim 1b: "1 Medium, 1 Low, 2 Informational" / "2 Informational" / "3 Minor, 1 Informational" / "0 Structural, 0 Coupling, 1 Minor, 3 Informational" (the other four critics' tallies)

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:12-15`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-report tallies against each report's severity lines. It does not establish that those reports' own findings are correct.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

Carried from r3 Claim 1. The security summary table rows are `| 1 | … | Medium |`, `| 2 | … | Low |`, `| 3 | … | Informational |` and `| 4 | … | Informational |` (`security-reviewer-review-2026-10-06-build-loop-u2a1.md:188-191`). Performance has two `Informational` rows (`performance-reviewer-…:102-103`). The api-consistency severities read `Minor, Minor, Informational, Minor`. The architecture summary table has `| 1 | … | Minor |` followed by three `Informational` rows (`architecture-review-…:141-144`).

**Evidence:** `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a1.md:184-191`, `docs/reviews/performance-reviewer-review-2026-10-06-build-loop-u2a1.md:98-103`, `docs/reviews/architecture-review-review-2026-10-06-build-loop-u2a1.md:137-144`

---

## Claim 2: "Executed: badform with 0 git calls; isclosed equal to all three old spellings on 23 edge cases; the positive control and the split chains each fail their mutants."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this replicate's own re-run of each of the four probes at d48f4645, with its own mutants and cases. It does not re-run iteration 1's original commands.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** merge note: r1 and r3 verified the same four facts in their own claims without verdicting this rubric sentence (see Claims 23a, 24c, 32 and 35).

Carried from r2 Claim 1. `$FC/bin/probe.sh` (cwd `$FC/tmp/probe`, exit 0, 2026-10-06T16:21:50Z) put a logging `git` shim first on PATH. It printed `badform` for `.gitattributes`, `.github/x.yml`, `../x`, `a<LF>b` and `docs//x.md`, then `git calls during badform probes: 0`. Probe 2 compared `isclosed`, `isbrief || isclosed` and `writable` against the three old spellings on 23 paths and printed `cases=23 mismatches=0`. The mutants are in r2 Claim 27 (merged Claims 32, 34 and 35).

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-266`, `$FC/logs/probes.log`, `$FC/bin/probe.sh` (r2)

---

## Claim 3: "rows 228, 292, 306, 314, 317-320 are Defer rows whose triggers this unit meets, and the diff addresses each"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:17`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers each listed row against the HEAD code. Rows 228, 292, 306, 314, 317, 318 and 320 are fully addressed, and 319 is addressed except for its short-line residue. It does not check rows 202, 203, 233, 284, 298 or 312, which stay with later units.
**Replicate verdicts:** r1=— · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r2: "Covers that 'row N' means line N of override-log.md and that each row's subject has a matching hunk. It does not cover whether row 319's short-line residue is fully reflowed (Claim 33)." r2 graded that residue separately (merged Claim 42) rather than against this sentence. · r2 decision: it read "row N" as override-log.md line N, which matches every cited row's subject.

Carried from r3 Claim 2. These rows are addressed in full:
- Row 228 (shared mapping): `entry_why` (`scripts/lib/dev-cycle-read.sh:283-292`) is called by all three former case blocks (`:354`, `:573-574`, `scripts/build-loop.sh:133`).
- Row 292: `isclosed` at `:158`.
- Row 306: `if ! pathform "$1"; then echo badform; return; fi` (`:266`).
- Row 314: `unset $(git rev-parse --local-env-vars)` (`test/lib/build-loop-fixtures.bash:15`).
- Rows 317, 318 and 320: the split chains, the T7 comment and the `x` → `absent` control (merged Claims 32, 31 and 35).

Row 319 named "the lib header's 'once that second caller lands' … with short lines". The phrase is gone, but the header still has a short line at `:25` (52 characters: `# scrub, read it as \`out="$(check_brief ...)"\` under`), and the reflow added a 96-character line at `:16`. A precise version is "…addresses each, except row 319's short-line wrap at lib :25".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`, `docs/reviews/override-log.md:228,292,306-320`

---

## Claim 4: A1 "setup() did not clear an inherited `GIT_DIR`: executed, the suite wrote 2 commits and branch f1 into a victim repo ... ✅ Fixed: both setups run `unset $(git rev-parse --local-env-vars)`; checked, the victim keeps 1 commit"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the pre-fix damage (main's suite, the security reviewer's `trunk` victim and test filter) and the post-fix result for a valid inherited GIT_DIR across both full suites. It does not cover other inherited variables that are not repo-local (GIT_CONFIG_KEY_n without a COUNT, GIT_EXEC_PATH) or hermeticity-lint's static rules.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not re-run the security reviewer's filtered command, which produced the '2 commits and branch f1' figure." r2 sourced that figure from `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a1.md:63`. · r3: "It does not establish protection from non-local variables such as `GIT_CEILING_DIRECTORIES` or `GIT_CONFIG_GLOBAL` (which setup overrides anyway)." · r2+r3: in a mutant with both unset lines deleted, whole-suite runs wrote about 80 and then 152 commits (plus branches) into the victim.

Carried from r1 Claim 2. Before the fix, `GIT_DIR=$V/.git timeout 300 bats -f 'check-fix refuses files an instruction file imports' test/scripts/dev-cycle.bats` in `$FC/maincopy`, with `$V` a one-commit repo on `trunk`, printed `exit=1 victim_commits=3 branches=f1,trunk,` (2026-10-06T16:24:13Z). That is 2 new commits and branch f1. After the fix, both full suites in `$FC/copy` with `GIT_DIR=$V/.git` printed `victim_commits=1 branches=main, status=0` (2026-10-06T16:19:38Z; dev-cycle.bats exited 1 only for the environmental test 25, build-loop-read.bats exited 0). Both setups have the line `unset $(git rev-parse --local-env-vars)` (`test/scripts/dev-cycle.bats:13`, `test/lib/build-loop-fixtures.bash:15`). r3 reproduced the filtered figure exactly on a mutant copy (3 commits plus `refs/heads/f1`).

**Evidence:** `test/scripts/dev-cycle.bats:8-22`, `test/lib/build-loop-fixtures.bash:7-23`, `$FC/logs/victim-main-trunk.log`, `$FC/logs/victim-full.log`, `$FC/logs/victim.log` (r1)

---

## Claim 5: "A2 | `entry_why` echoed the raw path … ✅ Fixed: entry_why turns newlines into spaces; new test"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:22`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the newline translation of both arguments and the new test's pinning of a newline in the path. It does not establish that the test pins a newline in the word, because that mutant survives (see Claim 34). The word cannot carry a newline today, because only pathform-clean paths reach `notdir PART`.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** merge note: r1 and r2 checked the same code and test under the entry_why comment and test claims (merged Claims 25b and 34).

Carried from r3 Claim 4. The code is `local w="${1//$'\n'/ }" p="${2//$'\n'/ }"` (`scripts/lib/dev-cycle-read.sh:284`). Run directly (E12), `entry_why $'notdir a\nok b' x` printed `a ok b is not a directory on the default branch` on one line. The test's `entry_why badform "a\nok b"` expects `a ok b is not an allowed path form` (`test/scripts/dev-cycle.bats:1341-1353`), and the mutant that reverts both translations fails it (logs/mut-nl-word.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:280-292`, `test/scripts/dev-cycle.bats:1338-1354`, logs/entry_why-direct.log, logs/mut-nl-word.log (r3)

---

## Claim 6: "A3 … ✅ Fixed: the error arm names the path when given" / "A4 … check_brief passes ""; check_answer says 'so no entry in it is read' (in `$f` after notdir)"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:23-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the skip line each caller prints for notdir, notfile and error. Badform is unreachable from all three callers today (check_brief runs pathform first, and the other two pass fixed paths), so it was checked only through entry_why directly.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** merge note: r1 and r2 checked the same skip lines under the main_file and check_answer claims (merged Claims 19 and 28).

Carried from r3 Claim 5. The code:
- `error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;` (`scripts/lib/dev-cycle-read.sh:289`).
- check_brief: `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:354`).
- check_answer: `notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"` and `*) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"` (`:573-574`).

E10 printed `constraints unreadable: the tree of the default branch could not be read for docs/constraints.md`, `… docs/constraints.md is not a regular file on the default branch` and `… docs is not a directory on the default branch`. E1's tests at `dev-cycle.bats:1198`, `:1203`, `:1327` and `:1042` assert the check_answer and check_brief lines and pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:339-355`, `scripts/lib/dev-cycle-read.sh:563-575`, `scripts/build-loop.sh:126-140`, logs/probe3.log, logs/dev-cycle.log (r3)

---

## Claim 7: A6 "Row 319 residue: short lines in the lib header (`:13`, `:25`) ... ✅ Fixed: reflowed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the line lengths of the lib header (lines 8-32) at 6f624cdf and d48f4645. It does not judge whether row 319 requires any particular width.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Mostly accurate
**Replicate annotations:** r2: wording only, no behaviour. Row 319 itself named ":12, :14, :26" (on main: 36, 18 and 41 characters), and all three of those are gone. · r3: "It does not assess whether the wrap matters." At 6f624cdf, `:13` was 27 characters and `:25` was 41.

Carried from r1 Claim 3. `awk 'NR>=8 && NR<=32 {print NR": "length($0)}' scripts/lib/dev-cycle-read.sh` (worktree, 2026-10-06T16:19Z) shows that `:13` went from 27 characters at 6f624cdf to 79, so it was reflowed. Line 25 is still short, at 52 characters:

```
# scripts/lib/dev-cycle-read.sh:25
# scrub, read it as `out="$(check_brief ...)"` under
```

The reflow also made line 16 96 characters long, the only header line over 79:

```
# scripts/lib/dev-cycle-read.sh:16
# ROOT_REAL is set, is the current directory and is a repository's top level; while ROOT_REAL is
```

A precise version would be "reflowed :12-15; :25 is still short and :16 now runs to 96 columns".

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`

---

## Claim 8: "Tests after the fixes: 95/95 (dev-cycle 74 with the new entry_why test, build-loop-read 19, hermeticity 2); shellcheck clean. Size after the fixes: 165 changed code lines."

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three suites, shellcheck over the four changed shell files, and the numstat count at d48f4645. It does not cover other suites in the repo.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: the claim also covers C6, "Resolved: 95/95 with test 25 run under a TMPDIR with no dot-prefixed part". r3 ran the whole dev-cycle suite under `/tmp/u2a1fc-*` (74/74 ok). · r1+r2: test 25 fails under the dotted `$FC/tmp` TMPDIR and passes alone under a non-dotted TMPDIR; r1 recorded counting it as passing, per the dispatch.

Carried from r1 Claim 4. `timeout 900 bats test/scripts/dev-cycle.bats` in `$FC/copy` gave 73 ok and `not ok 25 an origin/HEAD naming an option-like branch cannot make git write a file`. Run alone with a non-dotted TMPDIR, the same test printed `ok 1 an origin/HEAD naming an option-like branch ...`, exit 0 (2026-10-06T16:19:04Z). That makes 74/74. build-loop-read.bats gave 19 ok, exit 0, and test/fixture-hermeticity.bats gave 2 ok, exit 0. `grep -c '^@test'` gives 74, 19 and 2, for a total of 95. `git diff --numstat main...HEAD -- ':(top)' ':(top,exclude)docs/' | awk '{n+=$1+$2} END{print n}'` printed `165`. shellcheck on scripts/dev-cycle.sh, scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh and test/lib/build-loop-fixtures.bash exited 0.

**Evidence:** `$FC/logs/dev-cycle.log`, `$FC/logs/dc-test25.log`, `$FC/logs/build-loop-read.log`, `$FC/logs/fixture-hermeticity.log`, `$FC/logs/counts.log` (r1), suites counted: `test/scripts/dev-cycle.bats`, `test/scripts/build-loop-read.bats`, `test/fixture-hermeticity.bats`

---

## Claim 9: "Commit 6f624cdf's Notes say 'the lib's check_fix keeps reading the IMPORTED cache'; check_fix is in scripts/dev-cycle.sh and reads the lib's cache"

**Location:** `docs/reviews/override-log.md:321`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers where check_fix is defined and what it reads. It does not cover U2a2's planned `isimported`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: the cache is declared in the lib, `IMPORTED=$'\n'; IMPORTED_DONE=""` (`scripts/lib/dev-cycle-read.sh:444`).

Carried from r1 Claim 5. `check_fix() {` is at `scripts/dev-cycle.sh:170`, and the function reads the cache: `elif [[ "$IMPORTED" == *$'\n'"$lp"$'\n'* ]]; then` (`scripts/dev-cycle.sh:182`). `rg -n "check_fix\(\)" scripts/lib/` finds no definition (paraphrased; no quote is possible because the claim is about absent code).

**Evidence:** `scripts/dev-cycle.sh:170-185`

---

## Claim 10: "check_fix adds constraints.md inline ... This row closes 204: constraints.md is refused, docs/thoughts/ stays fixable on purpose ... (architecture F1, `scripts/dev-cycle.sh:181-183`)"

**Location:** `docs/reviews/override-log.md:322`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers today's check_fix behaviour for constraints.md and docs/thoughts/. It does not establish what U2a2's floor will list (future work).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the cited range `:181-183` is correct at 6f624cdf, the commit the architecture review read. At d48f4645 the same lines are `:179-181`, because d48f4645 shortened the comment above by two lines. · r2: plan floor item 4 lists `docs/constraints.md`, `docs/decisions/`, `docs/thoughts/` and `docs/human-author/` (`docs/working/plan-build-loop-handoff.md:72`). · r3: the mutant that removes `|| "$lp" == docs/constraints.md` fails the test at `test/scripts/dev-cycle.bats:1029`.

Carried from r1 Claim 6. The test is inline in check_fix: `|| "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* ...` (`scripts/dev-cycle.sh:180`). Run against a throwaway repo, `--check-fix` printed `skip docs/constraints.md: in-cycle fixes edit only ...` and the same for `docs/CONSTRAINTS.MD` and `docs/Constraints.md`. It printed `ok docs/thoughts/t.md` and `ok docs/thoughts/constraints.md` (2026-10-06T16:21:39Z).

**Evidence:** `scripts/dev-cycle.sh:170-185`, `$FC/logs/probe.log` (r1)

---

## Claim 11: "Three call sites write `isbrief X || isclosed X` themselves (lib writable, check_brief; build-loop.sh shared_branches)"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the call sites of isclosed in scripts/. It does not cover tests.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish that no other site exists in unchanged files, beyond the grep below." · r3: it does not cover U2b's planned fourth caller.

Carried from r1 Claim 7. `rg -n isclosed scripts/` finds exactly three callers:
- `... ]] || isbrief "$1" || isclosed "$1"` at `scripts/lib/dev-cycle-read.sh:161`.
- `if ! isbrief "$a" && ! isclosed "$a"; then` (the negated form) at `:344`.
- `if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi` at `scripts/build-loop.sh:318`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158-162,344`, `scripts/build-loop.sh:318`

---

## Claim 12: "so `.github/x.yml` is refused under D5's dot rule rather than as badform" (its premise: main_entry answers badform for `.github/x.yml` and `.gitattributes` today)

**Location:** `docs/reviews/override-log.md:324`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the premise that main_entry answers badform for `.github/x.yml` and `.gitattributes` today. It does not cover the floor's future ordering, which is a deferred requirement.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: the rest of the row is a prescription for U2a2 and cannot be checked yet. · r2: the cause is pathform's `"$c" != [.][gG][iI][tT]*` (`scripts/lib/dev-cycle-read.sh:146`). · r3: 0 git calls for each of the two paths.

Carried from r1 Claim 8. The probe printed `.github/x.yml -> badform` and `.gitattributes -> badform`. The new test pins both: `for p in x "a\"b.md" "../x" "-x" "docs//x.md" .gitattributes .github/x.yml; do main_entry "$p"; done` (`test/scripts/dev-cycle.bats:1358`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:264-266`, `test/scripts/dev-cycle.bats:1356-1366`, `$FC/logs/probe.log` (r1)

---

## Claim 13: "entry_why adds one subshell (~0.3 ms) per refused argument, and isclosed costs ~17 µs more per brief pair in shared_branches than the old substitution"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the cost of each construct on this machine, with 2000 iterations and two runs. It does not cover other hosts or the "within run-to-run noise" suite claim.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: three runs gave 523, 417 and 435 µs per entry_why call and a delta of 19.6, 19.1 and 21.1 µs per pair. "Timings depend on load." It does not cover the row's "suite delta within run-to-run noise", which would need repeated full-suite timings. · r3 (graded Verified on order of magnitude): about 0.46 ms per subshell (1000 runs, 0.468 s) and about 18 µs more per pair (5000 pairs, 0.211 s against 0.300 s). It "does not establish the exact figure, which depends on the machine". · r2 decision: graded Mostly accurate because the figures are about 40% and 15% under this host's measurements.

Carried from r1 Claim 9. `timeout 120 env LC_ALL=C bash perf.sh copy/scripts/lib/dev-cycle-read.sh` (cwd `$FC`, 2026-10-06T16:22:28Z, exit 0) printed `entry_why in $(...): 489.0 us/call` and `490.8 us/call`. Per pair (isbrief||isclosed against the old `${f/#.../}` substitution) it printed `delta 19.0 us` and `delta 36.9 us`. Both costs are the order the row states, and both are still negligible next to the git call each refusal path makes. But they measure ~0.5 ms and ~19-37 µs here, not ~0.3 ms and ~17 µs. A precise version is "~0.3-0.5 ms" and "tens of µs".

**Evidence:** `$FC/perf.sh`, `$FC/logs/perf.log` (r1), `scripts/lib/dev-cycle-read.sh:158,283-292`, `scripts/build-loop.sh:318`

---

## Claim 14: "U1 measured four units against a planned one, and U2 carries about twenty override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the U1 unit count in main's log and the count of Defer rows whose revisit trigger names U2. It does not assign rows to sub-units.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1: paraphrased; no quote is possible because the claim is a count over table rows.

Carried from r1 Claim 10. `git log --oneline main | rg -i "U1[a-d]"` shows `ba465de2 docs(checkpoint): U1 landed (U1a-U1c); U1d built ...` and `4e12b03c Merge branch 'feat/build-loop-u1d'`, which makes four units. `awk '/^\| 20/ && /Defer/ && /Revisit trigger:[^|]*U2/' docs/reviews/override-log.md | wc -l` prints 26 at HEAD. Three of those are this branch's new rows (C1-C3, `:322-324`), so 23 existed when the note was written. That is "about twenty".

**Evidence:** `docs/working/plan-build-loop-handoff.md:273`, `docs/reviews/override-log.md:322-324`

---

## Claim 15: "U2a1: `main_entry`'s `badform` word with one shared reason mapping, `entry_why` (rows 228, 306); one spelling of the closed/ rule, `isclosed` (row 292); `check_fix` also refuses `docs/constraints.md` (row 204: the user writes it, D2; `docs/thoughts/` stays fixable in-cycle ..., so `check_fix` and the floor differ there on purpose)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the match between the bullet and this diff, and D2's ownership statement. It does not cover the U2a2/U2b/U2c bullets (future work).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: floor item 4 lists `docs/thoughts/` (`docs/working/plan-build-loop-handoff.md:72`), while check_fix answers `ok docs/thoughts/t.md`. That is the "differ there on purpose" the bullet names.

Carried from r1 Claim 11. The named pieces exist: `if ! pathform "$1"; then echo badform; return; fi` (`scripts/lib/dev-cycle-read.sh:266`), `entry_why() {` (`:283`), `isclosed() { ... }` (`:158`) and `|| "$lp" == docs/constraints.md` (`scripts/dev-cycle.sh:180`). D2 says "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:43-51,72,273-279`, `scripts/lib/dev-cycle-read.sh:158,266,283`, `scripts/dev-cycle.sh:180`

---

## Claim 16: Q-119 "Interim: [1]. Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`."

**Location:** `docs/working/questions.md:390-391`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the commit, its branch and the split record. It does not judge the split.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: Q-119 leaves the split to the user. · r3: also covers "Blocks: nothing" (`docs/working/questions.md:376-392`) and the questions-doc structure check: `bash scripts/questions.sh check` printed `✓ questions: structure valid, indexes current` (E14). · placement: r1 cites `:391`, r2 `:390`, r3 `:376-392`.

Carried from r1 Claim 12. `git log -1 --format='%h %s' e8f76379` gives `e8f76379 docs(reviews): U2a iteration 3 (final pass, k=3) and the iteration-4 gate decision: split`, and `git branch --contains e8f76379` gives `feat/build-loop-u2a`. On that branch the U2a rubric has `### Iteration-4 gate decision: \`split\`` (line 69) and a `**U2a1**` bullet (line 74).

**Evidence:** `docs/working/questions.md:376-393`, `feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:69-74`

---

## Claim 17: "Markup that adds letters (a checked task box, a tag) can still hide a copy; only an exact line ever sets a value."

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the copy count in SETTINGS_AWK. It does not cover fences, which are skipped separately.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: it does not re-test the unchanged "a tag" example. · r3: it does not test tags. The `<` start is refused by FENCE_AWK, so only a tag that is not first on the line applies. · r2+r3 (executed): a `- [x] Build-loop policy: …` copy beside an exact line was hidden (`policy … set`), and a `- [ ]` copy was counted (`more than one line starts "Build-loop policy:"`).

Carried from r1 Claim 13. The copy test drops every non-letter, then checks the prefix: `s = tolower($0); gsub(/[^a-z]/, "", s); k = ""` and `if (index(s, "buildlooppolicy") == 1) k = "policy"` (`scripts/build-loop.sh:155-156`). So `- [x] Build-loop policy:` becomes `xbuildlooppolicy` and is missed, while `- [ ]` adds no letter and is counted. That matches line 18's "an unchecked task box" (counted) and line 20's "a checked task box" (missed).

**Evidence:** `scripts/build-loop.sh:14-21,42-46,150-165`

---

## Claim 18: "A tip on a branch not ahead of main, or whose subject does not start 'handoff:', is working."

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers status_line's loop state for an existing branch. It does not cover absent branches or refused branch names.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** placement: r1 and r2 cite `:65-66`; r3 cites `:73-74` for the same sentence. · r2 (executed): a branch behind main whose tip is a `handoff: ready` commit logged `ahead: 0` and printed `... feat/x working ...`. It does not re-test the subject rule, which is unchanged. · r3: it does not cover marker_kind's bad arms.

Carried from r1 Claim 14. `ahead` is check_branch's `$(git rev-list --count "$MAIN_SHA..$sha")` (`scripts/lib/dev-cycle-read.sh:396`). status_line sets `loop=working` and reads a marker only under `if [[ "$ahead" -gt 0 ]]; then` (`scripts/build-loop.sh:352-353`). marker_kind answers `working` when `[[ "$subj" == handoff:* ]]` fails (`:286`). A branch level with main, or behind it, has `ahead` 0, so "not ahead" is the exact condition.

**Evidence:** `scripts/build-loop.sh:280-301,326-358`, `scripts/lib/dev-cycle-read.sh:396`

---

## Claim 19: main_file "returns 1 with FILE_WHY 'absent' or why it was not read (main_entry, ...)"; every word but blob/absent is a refusal worded by entry_why

**Location:** `scripts/build-loop.sh:122-134`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_file's three arms and their reasons for notfile, notdir and error, as observed in --settings. It does not cover badform, which main_file's two constant paths cannot reach.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the consumers print the reason without naming the file again (`POLICY_LINE="policy review unset: $why"`, `:214-215`; `CONSTRAINTS_LINE="constraints unreadable: $FILE_WHY"`, `:265`), so `"$f"` is the right argument. · r3: for dev-cycle.md, any FILE_WHY other than absent also gives `NEVER_LINE="never malformed: $why"` (`:215-217`), which turns self-merge off. The plan dispatches only on `ok`.

Carried from r1 Claim 15.

```
# scripts/build-loop.sh:129-134
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
  esac
```
(excerpt ends :134; the enclosing main_file() continues to :141, read)

`timeout 120 bash probe2.sh` (cwd `$FC`, 2026-10-06T16:21:57Z, exit 0) printed `constraints unreadable: docs is not a directory on the default branch` (docs a symlink on main) and `constraints unreadable: the tree of the default branch could not be read for docs/constraints.md` (a tree listing `docs` twice). `bats` gave notfile as `constraints unreadable: docs/constraints.md is not a regular file on the default branch` (`test/scripts/build-loop-read.bats:193`, passing). Every non-`absent` FILE_WHY reaches an "unset", "malformed" or "unreadable" line (`scripts/build-loop.sh:213-217,263-265`).

**Evidence:** `scripts/build-loop.sh:121-141,210-218,262-266`, `$FC/logs/probe2.log`, `$FC/logs/build-loop-read.log` (r1)

---

## Claim 20: "--check-fix ... (not the cycle's own files, working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @; compared ignoring case)"

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the new constraints.md item, its case folding and the docs/thoughts/ residue. The other items are unchanged by this diff and were not re-probed.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: also probed `ok docs/sub/constraints.md` and `ok docs/notes.md`. · r3: it does not cover the import walk; r3 also matched the skip message (`:181`) and SKILL.md (`skills/dev-cycle/SKILL.md:74`) against the condition. · placement: r2 cites `:49-54` and r3 `:50-54`.

Carried from r1 Claim 16. `lp` is the lower-cased path (`lp="$(printf '%s' "$a" | tr 'ABC...Z' 'abc...z')"`, `scripts/dev-cycle.sh:175`), and the test is `"$lp" == docs/constraints.md` (`:180`). The probe refused `docs/constraints.md`, `docs/CONSTRAINTS.MD` and `docs/Constraints.md`, and accepted `docs/thoughts/t.md`.

**Evidence:** `scripts/dev-cycle.sh:50-55,170-185`, `$FC/logs/probe.log` (r1)

---

## Claim 21a: "the header's --check-fix paragraph is the rule, and the skip message below repeats it"

**Location:** `scripts/dev-cycle.sh:167-168`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the agreement of the header paragraph, the skip messages and SKILL.md with check_fix's conditions. It does not cover check_path's own skip lines (tracked, plain).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Mostly accurate
**Replicate annotations:** r3: it does not cover SKILL.md, which matches the header (merged Claim 29). · r1+r2+r3: each states the same precise version, "the skip messages below repeat it".

Carried from r1 Claim 17. The second skip message lists `not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files` (`scripts/dev-cycle.sh:181`). That matches the header's list minus two items, the header's "the cycle's own files" and "a file an instruction file imports with @" (`:51-54`). Those two have skip messages of their own: `one of the cycle's own files (use --check-write)` (`:178`) and `an instruction file imports it with @ ...` (`:183`). So no single "skip message below" repeats the rule; the three messages do together. Every item in the header, the messages and SKILL.md (`skills/dev-cycle/SKILL.md:72-76`) has a matching condition in check_fix, and none is missing. A precise version is "the three skip messages below repeat it".

**Evidence:** `scripts/dev-cycle.sh:50-55,167-185`, `skills/dev-cycle/SKILL.md:72-76`

---

## Claim 21b: "constraints.md is the user's (plan D2); docs/thoughts/ stays fixable."

**Location:** `scripts/dev-cycle.sh:168-169`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers D2's ownership statement and check_fix's thoughts/ outcome. It does not cover the floor's planned treatment of thoughts/.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate (compound; carried by sub-claim 21a) · r3=—
**Replicate annotations:** merge note: r2 Claim 16 verdicted the whole comment at `:167-169` as one compound claim. Its Mostly accurate rests only on the "skip message" wording (21a), and its prose says "The header paragraph and code agree". Per decision 033's intra-claim rule, a compound takes its most severe part's verdict, so r2's MA is recorded here but not counted against this sibling.

Carried from r1 Claim 18. D2 says "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`). check_fix's regex excludes only `^docs/(working|human-author|reviews|decisions)/` (`scripts/dev-cycle.sh:179`), and the probe printed `ok docs/thoughts/t.md`.

**Evidence:** `scripts/dev-cycle.sh:168-185`, `docs/working/plan-build-loop-handoff.md:50`, `$FC/logs/probe.log` (r1)

---

## Claim 22: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)."

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the existence of the named suites and that they pass at d48f4645. It does not cover suites that other scripts may add later.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: it does not establish that any gate or CI enforces the rule. · r2: build-loop-read.bats loads `test/lib/build-loop-fixtures.bash`, which sets `BL="$REPO_ROOT/scripts/build-loop.sh"` (`:10`), and build-loop.sh sources the lib (`scripts/build-loop.sh:92-95`). · r3: the stale "once that second caller lands" wording is gone.

Carried from r1 Claim 19. `ls test/scripts/build-loop-*.bats` lists only `test/scripts/build-loop-read.bats`. Both it and dev-cycle.bats pass (Claim 8). The plural "suites" looks ahead: today the glob matches the one suite that exists (paraphrased; no quote is possible because this is a directory listing).

**Evidence:** `scripts/lib/dev-cycle-read.sh:10-11`, `$FC/logs/dev-cycle.log`, `$FC/logs/build-loop-read.log` (r1)

---

## Claim 23a: `isclosed` "spells the closed/ brief path rule once" and equals writable's regex and check_brief's regex

**Location:** `scripts/lib/dev-cycle-read.sh:158`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers equivalence with both removed regexes on the 23 paths of Claim 23b. Character classes are listed one by one, so locale does not matter.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1 (27 cases, `cases=27 diffs=0`): "It is not an exhaustive proof, although the static argument below covers the general case." Its cases included a trailing newline, a nested `closed/closed/`, `closed/sub/`, a `2026-10-0closed` directory, a doubled `docs/working/briefs` prefix, upper case, `//` and a full-width digit. · r2 (23 cases): "It does not cover a caller shell with `nocasematch` set, which would change the old and new forms alike." · r1+r2: by construction, SLUG and DIGIT hold no `/` or newline, so the stripped remainder must be a single `DATE-SLUG.md` file name, which is the old anchored regex.

Carried from r3 Claim 22. The old regex `^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$` was compared with `isclosed` in E8 (`old_writable_closed` and old check_brief), with 0 differences.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-162`, `scripts/lib/dev-cycle-read.sh:344`, logs/probe1.log (r3)

---

## Claim 23b: shared_branches' `isbrief "$f" || isclosed "$f"` equals the old `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"`

**Location:** `scripts/build-loop.sh:318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 23 edge-case paths compared under both spellings: a doubled closed/, a newline inside and at the end, an Arabic-Indic digit, é, an upper-case W, a trailing slash, globs and the empty string. It does not cover the files git grep happens to list.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2: verified within their isclosed claims (r1 Claim 20, r2 Claim 18), with the same caveats as Claim 23a.

Carried from r3 Claim 18. E8 prints `isclosed cases: 23, differences: 0` for the old shared_branches substitution, the old writable/check_brief regex and the new predicates. `isclosed` is `[[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"` (`scripts/lib/dev-cycle-read.sh:158`), and é is refused under C, en_US.UTF-8 and C.UTF-8.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-162`, `scripts/build-loop.sh:305-324`, logs/probe1.log (r3)

---

## Claim 24a: main_entry prints … "badform" (a path pathform refuses: a .git* part such as .gitattributes, say) or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice …)

**Location:** `scripts/lib/dev-cycle-read.sh:252-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every return path of main_entry (`:262-279`). With no main found by name, a badform path answers `error`, because main_by_name runs first. The comment does not say otherwise.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: the precedence is not stated in the comment's word list; with no default branch found by name, a refused path answers `error`, not `badform` (r1 probe: `no main + bad path -> error`; r2: `.gitattributes (main not by name) -> error`). r2 adds that the comment implies this order ("main_by_name and pathform") but does not state it.

Carried from r3 Claim 23. The returns are:
```bash
# scripts/lib/dev-cycle-read.sh:265-268
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
  out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)" || { echo error; return; }
```
(excerpt ends :268; the enclosing main_entry() continues to :279, read. The dup check `[[ -z "$dup" ]] || { echo error; return; }` is at :274.) In E8, `.gitattributes`, `.github/x.yml`, `../x`, `a b`, `a\nb` and `docs//x.md` all give `badform`, and with `MAIN_BY_NAME=""`, `.gitattributes` gives `error`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:248-279`, logs/probe1.log (r3)

---

## Claim 24b: "Only blob reads the file, and only absent means there is none: every other word is a refusal." (and every caller treats it so)

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every main_entry caller in scripts/ (four) and the two build-loop paths that reach it through them. It does not cover callers outside scripts/; `rg main_entry` finds only tests and docs there.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: brief_fields treats absent as a refusal too, "which is stricter than the comment and consistent with it". · r2+r3: shared_branches reaches main_entry only through brief_fields and runs `continue` on a refusal, so a refused brief is not counted. That is the pre-existing row 293/308 behaviour and the floor's concern. r3: "It does not establish fail-closed behaviour for F31's duplicate-branch count." · r3: the test with an `odd` word (`dev-cycle.bats:1351-1352`) shows that an unknown word gets the default arm's wording, and no arm anywhere maps a word other than blob to a read.

Carried from r2 Claim 20.
- `check_brief`: `absent) echo "ok $a new"`, `blob) ;;`, then `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:352-354`).
- `check_answer`: `absent) continue ;;` and `blob) ;;`, with both other arms `echo "skip $a: ..."; return` (`:570-574`).
- `brief_fields`: `[[ "$(main_entry "$1")" != blob ]]` → `BRIEF_ODD=error; return 1` (`:312`).
- `main_file`: the same shape (Claim 19).
- `status_line` passes only `ok ` lines from check_brief (`[[ "$out" == "ok "* ]] || { echo "$out"; return; }`, `scripts/build-loop.sh:328`) and refuses on a failed brief_fields (`:332`).
- `shared_branches` reaches main_entry only through brief_fields. On a refusal it runs `continue` (`:318`), so the brief is not counted. That is the pre-existing row-308 behaviour, and the floor's concern, not this claim's.

**Evidence:** `scripts/lib/dev-cycle-read.sh:312,350-355,568-575`, `scripts/build-loop.sh:126-134,306-332`

---

## Claim 24c: "It runs main_by_name and pathform itself, before any read"; badform is answered before any git call

**Location:** `scripts/lib/dev-cycle-read.sh:257-259`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the six refused path shapes probed and one valid path. It does not cover git calls made by resolve_main, which runs before main_entry.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2+r3: `main_by_name` is a variable test (`[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]`, `:247`). · r3: it counted calls with a `git` function shim: 0 for each badform path and 1 for each of `x` and `docs/x.md` (absent). · r3: the quoted comment continues "(pathform also means ls-tree prints the name unquoted)".

Carried from r1 Claim 22.
```
# scripts/lib/dev-cycle-read.sh:265-266
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
```
(excerpt ends :266; the enclosing main_entry() continues to :278, read; the first git call is ls-tree at :268)

With a PATH shim logging every git call, six refused paths (`.gitattributes`, `.github/x.yml`, `../x`, `a"b`, `docs//x.md`, `-x`) each printed `badform`, and the log showed `git calls for 6 refused paths: 0`. One valid path then printed `blob` after 1 call (2026-10-06T16:21:39Z, exit 0). Mutant M4 (pathform check deleted) fails the pinning test.

**Evidence:** `scripts/lib/dev-cycle-read.sh:262-279`, `$FC/probe.sh`, `$FC/logs/probe.log`, `$FC/logs/mutants.log` (r1)

---

## Claim 25a: "$2 is the path, named in the reason; pass "" when the skip line already names it."

**Location:** `scripts/lib/dev-cycle-read.sh:280-281`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers all five arms of entry_why with an empty and a non-empty `$2`. It does not cover callers.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1 (graded Verified): "The notdir arm names the directory from `$1`, not `$2`, so its reason is the same with or without a path. The test pins this (`test/scripts/dev-cycle.bats:1340`, expected lines 1343-1344)." · r1: it does not cover a CR or other control characters, which the comment does not claim to handle (scrub handles them downstream). · r1+r2: check_brief passes `""`, and main_file and check_answer pass the path.

Carried from r3 Claim 26. The notfile, badform, error and default arms name `$2` when it is non-empty: `${p:+$p is }` and `${p:+ for $p}` (`:287-290`). The notdir arm ignores it: `notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;` (`:286`). E12 and the test (`dev-cycle.bats:1343-1344`) print the same line with and without a path. check_answer's comment at `:572` documents this. A precise version is "…named in the reason, except after notdir, which names the directory instead". The `empty-path` mutant (`notfile) echo "$p is …`) fails the new test (logs/mut-empty-path.log).

**Evidence:** `scripts/lib/dev-cycle-read.sh:280-292`, `test/scripts/dev-cycle.bats:1338-1354`, logs/mut-empty-path.log (r3)

---

## Claim 25b: "A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:281-282`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers newlines in `$1` and `$2`. It does not cover other control characters, which scrub removes at output.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: a newline in the word is covered by reading the code only (`w="${1//$'\n'/ }"`), since no test feeds one. · r1: mutant M1 (newline fold removed) fails the new test. · r3: see Claim 34 for the surviving word-only mutant.

Carried from r3 Claim 27. The code is `local w="${1//$'\n'/ }" p="${2//$'\n'/ }"` (`:284`). In E12, `entry_why $'odd\nok' ""` gives `the default branch answered odd ok` and `entry_why $'notdir a\nok b' x` gives `a ok b is not a directory …`, each on one line.

**Evidence:** `scripts/lib/dev-cycle-read.sh:283-292`, logs/entry_why-direct.log (r3)

---

## Claim 26: no doc, help text, SKILL.md or test still quotes a skip wording that is no longer printed

**Location:** `scripts/lib/dev-cycle-read.sh:283-292`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the removed wordings "the default branch's tree could not be read", check_answer's "…, so <file> is not read" and "could not be read, so". The search excluded docs/reviews, archive and runs. It does not cover wordings that review artifacts quote.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** merge note: r1 (Claim 23: "`rg` over skills/, docs/working/, docs/*.md and scripts/ finds no doc or help text quoting an old wording") and r2 (Claim 22: a grep "over scripts, skills, test and the plan finds none") ran the same search inside other claims and found no hits.

Carried from r3 Claim 29. `rg "default branch's tree|so docs/working/questions.md is not read|could not be read, so"` found no hits outside docs/reviews, archive and runs (paraphrased; no quote is possible because the claim is about absent matches). The remaining "is not read" matches are other, unchanged messages (`build-loop.sh:138-139`, `lib:358-360`). The dev-cycle.sh --check-answer header ("a default branch whose tree or file could not be read", `scripts/dev-cycle.sh:67-68`) still describes the new lines.

**Evidence:** `scripts/dev-cycle.sh:55-68`, `scripts/build-loop.sh:136-139`, `scripts/lib/dev-cycle-read.sh:356-361`

---

## Claim 27: brief_fields' "error (no default branch found by name, a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read)"

**Location:** `scripts/lib/dev-cycle-read.sh:302-305`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers brief_fields' refusal paths with the new badform word. It does not cover the odd/unbalanced arms, which are unchanged.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 24. `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`scripts/lib/dev-cycle-read.sh:312`). badform falls under "any main_entry answer but blob". pathform runs first, so main_entry never answers badform here. The read failure is `|| { BRIEF_ODD=error; return 1; }` (`:322`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:293-330`

---

## Claim 28: check_answer's `# "it" is $f, except after notdir, whose reason names a directory above it.` and the skip lines of check_answer and check_brief

**Location:** `scripts/lib/dev-cycle-read.sh:572-574`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the notdir, notfile and error lines, as observed in passing tests. It does not cover badform, which check_answer's two constant paths cannot reach, although the `*)` arm would word it.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: check_brief cannot reach badform either, because it runs pathform first (`:343`). It also covers check_brief's line `skip docs/working/briefs/2026-01-01-s.md: not a regular file on the default branch` (`test/scripts/dev-cycle.bats:1042`). · r3: unknown words are unreachable here because the paths are fixed. The mutant that changes the notdir tail fails the check-answer tests (logs/mut-check-answer-wording.log).

Carried from r1 Claim 25.
```
# scripts/lib/dev-cycle-read.sh:572-574
      # "it" is $f, except after notdir, whose reason names a directory above it.
      notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"; return ;;
```
(excerpt ends :574; the enclosing check_answer() continues to :591, read)

The passing tests pin each line:
- notdir: `skip Q-1: docs/working is not a directory on the default branch, so no entry in docs/working/questions.md is read` (`test/scripts/dev-cycle.bats:1203`).
- error: `skip Q-1: the tree of the default branch could not be read for docs/working/questions.md, so no entry in it is read` (`:1327`).
- notfile: `... docs/working/questions.md is not a regular file on the default branch, so no entry in it is read` (`:1198`).

In each `*)` line, "it" follows the path that entry_why named.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-591`, `test/scripts/dev-cycle.bats:1198,1203,1327`, `$FC/logs/dev-cycle.log` (r1)

---

## Claim 29: "`--check-fix '<path>'` prints `ok` for: a tracked `.md` file under `docs/` (not ... `docs/dev-cycle.md`, `docs/constraints.md`, a dot-directory or dotfile, ...)"

**Location:** `skills/dev-cycle/SKILL.md:72-78`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the agreement of the SKILL.md list with check_fix and the script header. It does not cover the rest of SKILL.md.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: it was verified inside its dev-cycle.sh claim (r3 Claim 19), citing `skills/dev-cycle/SKILL.md:74`. · placement: r1 cites `:72-76`, r2 `:72-78` and r3 `:72-79`.

Carried from r1 Claim 26. SKILL.md's list matches the header item for item (`scripts/dev-cycle.sh:50-55`), including the new `docs/constraints.md`, and each item has its condition in check_fix (`scripts/dev-cycle.sh:178-183`; Claim 21a).

**Evidence:** `skills/dev-cycle/SKILL.md:72-76`, `scripts/dev-cycle.sh:50-55,170-185`

---

## Claim 30a: "a throwaway repo ... with a main branch, the same hermetic git environment as test/scripts/dev-cycle.bats"

**Location:** `test/lib/build-loop-fixtures.bash:2-4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the git-related environment of both setups. It does not cover LC_ALL, which bl_setup sets to C and dev-cycle.bats' setup does not (a locale setting, not a git one).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2+r3: same LC_ALL caveat ("It does not mean the two setups are identical"). · r3: "The scope does not establish behaviour with other git versions."

Carried from r1 Claim 27. Both setups run `unset $(git rev-parse --local-env-vars)` (`test/lib/build-loop-fixtures.bash:15`, `test/scripts/dev-cycle.bats:13`). Both export `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` and the same author and committer, and both set HOME under `$BATS_TEST_TMPDIR` (`test/lib/build-loop-fixtures.bash:16-20`, `test/scripts/dev-cycle.bats:14-19`).

**Evidence:** `test/lib/build-loop-fixtures.bash:1-23`, `test/scripts/dev-cycle.bats:8-22`

---

## Claim 30b: "An inherited GIT_DIR (a run from a git hook, say) would send every fixture command to that repo ...; git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)."

**Location:** `test/lib/build-loop-fixtures.bash:11-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers git 2.39.5's list, both suites with a valid inherited GIT_DIR, and one test with an invalid GIT_DIR. It does not cover GIT_CONFIG_KEY_n/VALUE_n, which git does not list. No test relies on them being inherited: the build-loop tests pass GIT_CONFIG_COUNT per command with `env`.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: GIT_CONFIG_KEY_n and VALUE_n "are inert once GIT_CONFIG_COUNT is unset"; `git rev-parse --local-env-vars` printed the same list with `GIT_DIR=/nonexistent`, exit 0. · r3: it works with a broken `GIT_CONFIG_COUNT=1` (E15: rc 0, victim untouched), and it does not establish behaviour with other git versions.

Carried from r1 Claim 28. `git rev-parse --local-env-vars` prints 16 names, including `GIT_DIR`, `GIT_WORK_TREE`, `GIT_INDEX_FILE`, `GIT_CONFIG_PARAMETERS` and `GIT_CONFIG_COUNT`, plus the earlier list's six (paraphrased; no quote is possible because this is command output, not repo text). Claim 4 shows the damage before the fix and none after it, for both suites. With `GIT_DIR=/nonexistent/x`, `prints all eight sections ...` still passed, so a broken GIT_DIR does not stop the setup. The build-loop-read tests that pass `env GIT_CONFIG_COUNT=1 ...` per command still pass (`test/scripts/build-loop-read.bats:438,483`; Claim 8).

**Evidence:** `test/lib/build-loop-fixtures.bash:11-15`, `$FC/logs/victim.log`, `$FC/logs/victim-full.log` (r1)

---

## Claim 30c: "# As bl_setup: an inherited GIT_DIR would send fixture commits to that repo."

**Location:** `test/scripts/dev-cycle.bats:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers dev-cycle.bats with and without the line. It does not cover suites outside these two.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2: verified within their fixtures-comment claim (r1 Claim 28, r2 Claim 25), which names the same comment at `test/scripts/dev-cycle.bats:11`.

Carried from r3 Claim 33. Without the line (E6/E7), the victim receives fixture commits and branches. With it (E5/E7), the victim keeps 1 commit (see Claim 4).

**Evidence:** `test/scripts/dev-cycle.bats:8-23`, logs/victim-filter-mut1.log, logs/victim-head.log (r3)

---

## Claim 31: "# A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the hand-made object's tree and parent. It does not cover the assertion that follows.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: it does not cover the test's other objects. · r3: it does not cover marker_kind's verdict on the object.

Carried from r1 Claim 29. `printf 'tree %s\nparent %s\n...' "$(git rev-parse "$base^{tree}")" "$base"` (`test/scripts/build-loop-read.bats:298`): one parent, which is base, and base's tree.

**Evidence:** `test/scripts/build-loop-read.bats:296-301`

---

## Claim 32: the split fixture chains (row 317) make a failed fixture step fail the test

**Location:** `test/scripts/build-loop-read.bats:436-440`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three chains row 317 names (:436, the CRLF overwrite at :466-468 and the closed-directory file at :473-475). It does not cover the older chain at :84, which row 317 does not name, or a step that succeeds but does the wrong thing.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: the older `:84` chain (`git replace … && git config core.useReplaceRefs true`) is still unsplit. Row 317 did not list it, and r2 notes its own `git replace -d` at `:85` guards it (see Escalation E3). · r2: the `repl` mutant (`git replace --bogus`) fails at `:436` with status 129.

Carried from r1 Claim 30. The mutants, each run on a copy:
- M7b, `git replace 0000000000000000000000000000000000000000 ...` at :436, gave `not ok 1 --settings: deferred cases ...`.
- M8, a CRLF write to `/nonexistent/b` at :467, gave `not ok 2 --status: deferred cases ...`.
- M9, a closed-dir write to `/nonexistent/c` at :474, gave `not ok 2`.

All three are in `$FC/logs/mutants.log` (2026-10-06T16:20:57Z-16:21:17Z). The standalone `git replace -d` at :440 also fails when the replace never happened: M7c, which restores the old `&&` chain with the bad replace, still fails, at the `-d`.

**Evidence:** `test/scripts/build-loop-read.bats:414-441,451-476`, `$FC/mut.sh`, `$FC/logs/mutants.log` (r1)

---

## Claim 33: "# docs/constraints.md is the user's (plan D2); docs/thoughts/ stays a living doc the cycle may fix." with the extended --check-fix test

**Location:** `test/scripts/dev-cycle.bats:1026`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the test pins the constraints.md refusal. Beyond the one `ok docs/thoughts/t.md` line, it does not pin docs/thoughts/ against a future over-broad refusal.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** merge note: r3 (Claim 9) and r2 (Claim 15) cite the same test (`test/scripts/dev-cycle.bats:1019-1029`) as evidence for their override-log and check-fix claims, and r3 ran the same constraints mutant.

Carried from r1 Claim 31. The test passes, and mutant M6 (`|| "$lp" == docs/constraints.md` deleted) gives `not ok 1 --check-fix refuses files an instruction file imports, and compares paths ignoring case` (2026-10-06T16:20:54Z).

**Evidence:** `test/scripts/dev-cycle.bats:1016-1032`, `$FC/logs/mutants.log` (r1)

---

## Claim 34: "entry_why words each main_entry refusal on one line, naming the path only when given (U2a1)"

**Location:** `test/scripts/dev-cycle.bats:1338-1354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the newline fold and the empty-path forms. It does not test a newline in the word `$1` alone; the newline case puts it in `$2`.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: the `nl-word-only` mutant `local w="$1"` passes (bats exit 0, 0 failing), because no input word holds a newline. That input is unreachable from main_entry, whose words come from paths that pathform has cleared (see Escalation E1). · r2: its `nl` mutant splits the output into `a` / `ok b is not an allowed path form`, and its `emptyp` mutant outputs ` is not a regular file ...`.

Carried from r1 Claim 32. The test passes. M1 (newline fold removed) and M2 (notfile ignores the empty path) each fail it. The newline case is `entry_why badform "a\nok b"`, expecting `a ok b is not an allowed path form` (`test/scripts/dev-cycle.bats:1341-1353`, input at :1341-1342, expectation at :1353).

**Evidence:** `test/scripts/dev-cycle.bats:1338-1354`, `$FC/logs/mutants.log` (r1)

---

## Claim 35: "main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a)" (the positive control, row 320)

**Location:** `test/scripts/dev-cycle.bats:1356-1366`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the reverts and fixture loss this test should catch. The test name says "U2a", while the unit is U2a1 (a label, not a behaviour).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r3: it does not cover a mutant that reorders main_by_name and pathform. · r2: its `ctrl` mutant (`if true || ! pathform`) gives seven `badform`, and only the `x` line catches it.

Carried from r1 Claim 33. Three mutants each fail the test:
- M3 (badform reverted to error).
- M4 (the pathform guard deleted).
- M5 (the fixture renames main to trunk before `resolve_main || true`, so main is not found by name and every line answers `error`). This is the vacuous-pass case row 320 named, and the first line, `x` → `absent`, is the control that catches it.

**Evidence:** `test/scripts/dev-cycle.bats:1356-1366`, `$FC/logs/mutants.log` (r1)

---

## Claim 36a: commit 6f624cdf "Tests: dev-cycle.bats 73, build-loop-read.bats 19, hermeticity 2 pass. 128 changed code lines."

**Location:** commit 6f624cdf message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three suites at 6f624cdf, run under a non-dotted TMPDIR, and the line count for main..6f624cdf. It does not cover the other bullets, which later claims cover or which d48f4645 superseded.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "The suites were run here only at d48f4645, not at 6f624cdf (the iteration-1 report ran them there)." It counted `^@test` at 6f624cdf (73, 19 and 2) and numstat gave 128. · r3: the same `@test` counts at 6f624cdf, and E4 gives 128.

Carried from r2 Claim 28. `$FC/logs/c1-suites.log` (cwd `$FC/c1`, 2026-10-06T16:24:06Z) shows `1..73` with exit 0, `1..19` with exit 0 and `1..2` with exit 0. `git diff --numstat main 6f624cdf -- ':(top)' ':(top,exclude)docs/' | awk ...` printed `128`.

**Evidence:** `$FC/logs/c1-suites.log` (r2), suites counted at 6f624cdf: `test/scripts/dev-cycle.bats`, `test/scripts/build-loop-read.bats`, `test/fixture-hermeticity.bats`

---

## Claim 36b: commit 6f624cdf's carried-row list (314, 317-320, 228, 292, 306, 204), each with its change in the diff

**Location:** commit 6f624cdf message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each named row's change is in the diff. It does not re-verdict the rows' own text.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: at 6f624cdf, bl_setup has `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES` (row 314), the same line r1 quotes.

Carried from r1 Claim 34. Each named row's change is present:
- 306/228 → badform and entry_why (Claims 24a-25b).
- 292 → isclosed (Claim 23a).
- 204 → constraints.md (Claim 20).
- 314 → bl_setup's unset (at 6f624cdf, `unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES`).
- 317 → the three split chains (Claim 32).
- 318 → T7's comment (Claim 31).
- 319 → the header wording (Claims 17, 18 and 22).
- 320 → the positive control (Claim 35).

**Evidence:** `6f624cdf:test/lib/build-loop-fixtures.bash:11-13`, `$FC/logs/counts.log` (r1)

---

## Claim 37: commit 6f624cdf Notes "the lib's check_fix keeps reading the IMPORTED cache until U2a2's isimported."

**Location:** commit 6f624cdf message
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers where check_fix lives. It is already recorded as an Accepted-immutable override row (`docs/reviews/override-log.md:321`), and this report does not ask for any change.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=—
**Replicate annotations:** r2: "The commit is immutable"; "the mechanism is right and the file is wrong". · r3: it did not verdict the commit line itself; its Claim 36a scope says "6f624cdf's own Notes line is already logged as Accepted-immutable (Claim 8)", where r3 Claim 8 is merged Claim 9, Verified.

Carried from r1 Claim 35. check_fix is defined at `scripts/dev-cycle.sh:170`, not in the lib, and it reads the lib's `IMPORTED` (`:182`). A precise version is "dev-cycle.sh's check_fix keeps reading the lib's IMPORTED cache" (see Claim 9).

**Evidence:** `scripts/dev-cycle.sh:170-185`, `docs/reviews/override-log.md:321`

---

## Claim 38a: commit 706e0499 "0 Must Fix; 1 Medium (dev-cycle.bats inherits GIT_DIR), 1 Low, 4 Minor, mostly wording. Four declined findings get override rows (C1-C4), and row 204 is closed by C1's row."

**Location:** commit 706e0499 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the commit's tally against the rubric table. It does not judge the severities themselves.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1 (graded Verified): "The Minor count is api 3 + architecture 1 (`:14-15`)", which counts Minor by critic-report severities rather than by rubric A-rows. · r3 (graded Verified): "The rubric rows A3, A4, A5 and C1 are the 4 Minor; A1 is Medium and A2 is Low (`rubric:21-27`)." · r2: "The commit does not mention the fifth new row, the Accepted-immutable one at `:321`."

Carried from r2 Claim 30. The rubric's A rows are as follows. A1 is `Medium` and A2 is `Low`. A3 is `Minor`. A4 is `Minor, Informational`, and A5 is `Mostly accurate, Minor, Informational`. A6 is `Mostly accurate` with source `fact-check`, so it is not a Minor-severity finding (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21-26`). "4 Minor" is really 3 Minor plus 1 fact-check Mostly accurate. C1-C4 do have four override rows (`docs/reviews/override-log.md:322-325`), and C1's row says "This row closes 204".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21-34`, `docs/reviews/override-log.md:321-325`

---

## Claim 38b: commit 706e0499 "213 KB of enclosing files is over the inline budget"

**Location:** commit 706e0499 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the byte count of the changed scripts/ and test/ files at 6f624cdf. It does not establish what the "inline budget" is.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 36. The changed non-docs files other than SKILL.md at 6f624cdf total 213,119 bytes (`git cat-file -s`): build-loop.sh 21,775, dev-cycle.sh 29,961, lib 35,165, fixtures 3,722, build-loop-read.bats 35,321 and dev-cycle.bats 87,175.

**Evidence:** `6f624cdf:scripts/build-loop.sh`, `6f624cdf:test/scripts/dev-cycle.bats`

---

## Claim 39: commit d48f4645 "Tests: dev-cycle.bats 74 ..., build-loop-read.bats 19, hermeticity 2, all pass; test 25 passes run with a TMPDIR that has no dot-prefixed part. shellcheck clean. 165 changed code lines against main."

**Location:** commit d48f4645 message
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** The same runs as Claim 8. It does not cover other suites.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: `@test` counts at d48f4645 are `dc=74 bl=19 fh=2`.

Carried from r1 Claim 37. See Claim 8: 73 plus test 25 under `/tmp/u2a1fc-RUQO` makes 74, 19 and 2 pass, shellcheck exits 0 and numstat prints 165.

**Evidence:** `$FC/logs/dev-cycle.log`, `$FC/logs/dc-test25.log`, `$FC/logs/build-loop-read.log`, `$FC/logs/fixture-hermeticity.log`, `$FC/logs/counts.log` (r1), suites counted: `test/scripts/dev-cycle.bats`, `test/scripts/build-loop-read.bats`, `test/fixture-hermeticity.bats`

---

## Claim 40: commit d48f4645 "With GIT_DIR pointing at a victim repo, the suite no longer writes into it (checked: 1 commit before and after)."

**Location:** commit d48f4645 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** As Claim 4.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: against 80 and 72 more commits in the mutant without the unset. · r3: reproduced in E7 (filtered test) and E5 (both suites).

Carried from r1 Claim 38. Both full suites with an inherited GIT_DIR left the victim at `victim_commits=1 branches=main, status=0`.

**Evidence:** `$FC/logs/victim-full.log` (r1), `test/scripts/dev-cycle.bats:13`

---

## Claim 41a: commit d48f4645 A4 bullet "check_answer goes back to 'so no entry in it is read' (in $f after notdir ...)"

**Location:** commit d48f4645 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers A1-A5 against the code. A6 is Claim 42, and the Notes line is Claim 41b.
**Replicate verdicts:** r1=Mostly accurate (compound; carried by sub-claim 41b) · r2=— · r3=Verified (compound)
**Replicate annotations:** r1: "The commit's A4 bullet ('goes back to "so no entry in it is read"') is right relative to 6f624cdf." r1 Claim 39's Mostly accurate rests on the Notes sentence (41b), so per decision 033's intra-claim rule it is recorded here but not counted against this sibling.

Carried from r3 Claim 36a. r3 checked A1-A5 of d48f4645 against the code. check_answer's arms read `notdir\ *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"` and `*) echo "skip $a: $(entry_why "$e" "$f"), so no entry in it is read"` (`scripts/lib/dev-cycle-read.sh:573-574`; r3 Claim 5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:563-575`, `test/scripts/dev-cycle.bats:1198,1203,1327`

---

## Claim 41b: commit d48f4645 Notes "the old, pre-U2a1 sentences come back except where a path is now named"

**Location:** commit d48f4645 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers check_answer's three skip sentences on main and at d48f4645. It does not cover check_brief or main_file, which do keep main's sentences (check_brief verbatim; main_file's notdir/notfile verbatim, error reworded).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: main_file's error reason was `the default branch's tree could not be read for $f` on main and is now `the tree of the default branch could not be read for $f` (through entry_why's `error` arm, `:289`). "Both changes come from the shared mapping and the sibling wording, so they are deliberate. The note understates them." · r3: three sentences changed even though main's versions already named the path: check_answer notdir, check_answer error and main_file error. Its precise version is "check_brief's and the notfile sentences come back; the notdir and error sentences take the shared wording". · r1+r3: no doc quotes the old endings, so nothing drifted (Claim 26).

Carried from r1 Claim 39. Only the notfile sentence is main's verbatim. On main, two sentences ended differently:

```
# main:scripts/lib/dev-cycle-read.sh (check_answer, notdir and error arms)
notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch, so $f is not read"; return ;;
error) echo "skip $a: the tree of the default branch could not be read, so $f is not read"; return ;;
```

At d48f4645 both end "so no entry in ... is read" (`scripts/lib/dev-cycle-read.sh:573-574`). The changed test expectations confirm it, for example `... so no entry in docs/working/questions.md is read` (`test/scripts/dev-cycle.bats:1203`, formerly `... so docs/working/questions.md is not read`). For notdir no path was newly named, yet the sentence changed. The Notes sentence is right only for notfile.

**Evidence:** `scripts/lib/dev-cycle-read.sh:568-575`, `main:scripts/lib/dev-cycle-read.sh` (check_answer), `test/scripts/dev-cycle.bats:1203,1327`

---

## Claim 42: commit d48f4645 "A6: the lib header's short lines reflowed (row 319's residue)."

**Location:** commit d48f4645 message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers line lengths in the lib header (`:8-32`) at d48f4645 against main. It is wording only, with no behaviour.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r1: lines 12-15 were reflowed (as Claim 7). · r3: verdicted together with the rubric's A6 (r3 Claim 6). Its decision recorded the row-319 residue twice, under the rubric's "addresses each" (Claim 3) and under A6, as separate statements. · r2 decision: graded Mostly accurate because the three named lines are fixed and the residue is cosmetic.

Carried from r2 Claim 33. Row 319 named "short lines at :12, :14, :26". On main those lines were 36, 18 and 41 characters, and all three are gone. One short line remains: `:25` is `# scrub, read it as \`out="$(check_brief ...)"\` under`, at 52 characters. The reflow also left `:16` at 96 characters (`# ROOT_REAL is set, is the current directory and is a repository's top level; while ROOT_REAL is`), where its neighbours are 70 to 79. Lengths were measured with `awk '{print length($0)}'` (paraphrased; no quote is possible because this summarises per-line lengths).

**Evidence:** `scripts/lib/dev-cycle-read.sh:12-27`, `docs/reviews/override-log.md:319`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 3** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:17`): "the diff addresses each" holds for every row except row 319's short-line residue (lib header `:25` is still 52 characters). r2=Verified, r3=Mostly accurate.
- **Claim 7** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`): A6 "Fixed: reflowed" is partial. `scripts/lib/dev-cycle-read.sh:25` is still 52 columns, and `:16` now runs to 96.
- **Claim 13** (`docs/reviews/override-log.md:325`): measured at ~0.4-0.5 ms per entry_why subshell and ~18-37 µs per pair, not ~0.3 ms and ~17 µs. The figures are the same order, and the Won't-Fix reasoning holds. r3 graded it Verified on order of magnitude.
- **Claim 21a** (`scripts/dev-cycle.sh:167-168`): "the skip message below repeats it". It takes the three skip messages (`:178`, `:181`, `:183`) together.
- **Claim 25a** (`scripts/lib/dev-cycle-read.sh:280-281`): "$2 is the path, named in the reason". The notdir arm ignores `$2` and names the directory. Only r3 graded it Mostly accurate; r1 recorded the same fact as Verified.
- **Claim 37** (commit 6f624cdf message): check_fix is in `scripts/dev-cycle.sh:170`, not the lib. This is already an Accepted-immutable row (`docs/reviews/override-log.md:321`).
- **Claim 38a** (commit 706e0499 message): "4 Minor" counts A6, which is a fact-check Mostly accurate with no Minor severity. The fifth new override row (`:321`) is not mentioned. Only r2 graded it Mostly accurate.
- **Claim 41b** (commit d48f4645 message, Notes): "the old sentences come back except where a path is now named". check_answer's notdir and error sentences and main_file's error sentence are reworded, although main's versions already named the path.
- **Claim 42** (commit d48f4645 message): A6 has the same residue as Claim 7.

### Unverifiable
(none)

## Escalations

- **E1:** `test/scripts/dev-cycle.bats:1338-1354` (with `scripts/lib/dev-cycle-read.sh:284`). The word-newline arm of entry_why is unpinned: the `nl-word-only` mutant `local w="$1"` survives. It is unreachable today, because main_entry's words come from pathform-cleared paths. Raised by r3 (Goal-Alignment Escalate; Claim 34). Addressee: orchestrator. Non-blocking.
- **E2:** `test/scripts/build-loop-read.bats:84-85`. The older `git replace … && git config core.useReplaceRefs true` chain is still unsplit. Row 317 did not list it, and its own `git replace -d` at `:85` guards it. Raised by r2 (Goal-Alignment Out of scope), with r1 (Claim 30 scope) and r3 (Claim 32 scope, and its decision to count it "as outside row 317 rather than as a defect"). Addressee: orchestrator.
- **E3:** `scripts/build-loop.sh:318`. shared_branches skips a brief whose brief_fields refuses (`continue`), so a refused brief is not counted toward the duplicate-branch count (F31). This is pre-existing row 293/308 behaviour that r2 calls "the floor's concern". Raised by r2 (Claim 20 prose) and r3 (Claim 24 scope: "It does not establish fail-closed behaviour for F31's duplicate-branch count"). Addressee: orchestrator (U2a2 floor).
- **E4:** wording and history residues (merged Claims 3, 7, 13, 21a, 25a, 37, 38a, 41b and 42). All three replicates' Escalate lines read "nothing blocking". r1 named Claims 3/40 and 17 (merged 7/42 and 21a) as wording-only, r2 called all six of its non-Verified claims "wording or history", and r3 called all five of its own "wording-only". Raised by r1, r2 and r3. Addressee: orchestrator. Non-blocking.

## Verdict stability

- Total clusters: 53. That is 44 multi-replicate clusters plus 9 single-replicate detections (Claims 1b, 2, 5, 6, 14, 26, 27, 33 and 38b).
- Clusters where all reporting replicates agreed: 47 of 53. Single-replicate clusters count as agreed trivially. Among the 44 multi-replicate clusters, 38 agreed.
- Disagreeing clusters (6):
  - Claim 3 (rubric:17): r1=— · r2=Verified · r3=Mostly accurate → Mostly accurate
  - Claim 13 (override-log:325): r1=Mostly accurate · r2=Mostly accurate · r3=Verified → Mostly accurate
  - Claim 21b (dev-cycle.sh:168-169): r1=Verified · r2=Mostly accurate (compound; carried by 21a) · r3=— → Verified
  - Claim 25a (lib:280-281): r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate → Mostly accurate
  - Claim 38a (commit 706e0499): r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound) → Mostly accurate
  - Claim 41a (commit d48f4645, A4): r1=Mostly accurate (compound; carried by 41b) · r2=— · r3=Verified (compound) → Verified
- Agreement rate: 47/53 = 88.7% over all clusters, and 38/44 = 86.4% over multi-replicate clusters. Claims 21b and 41a disagree only through a sibling's compound verdict. Excluding those two, 40/44 = 90.9% of multi-replicate clusters agreed.
- In every disagreement the verdicts sit next to each other on the scale (Verified and Mostly accurate). No replicate assigned Incorrect, Stale or Unverifiable.

## Goal-Alignment Note
- Success criterion (restated verbatim): "A merged code-fact-check report at docs/reviews/code-fact-check-report-build-loop-u2a1.md, k=3, most-severe-wins, with per-replicate verdicts and annotation union."
- Answered: yes. The three replicates (40, 34 and 37 claims) merged into 53 clusters, emitted at the finest granularity any replicate used: 44 Verified and 9 Mostly accurate. Every cluster has its per-replicate verdicts and an annotation union.
- Out of scope: re-verifying any claim (mechanical collation only, with no new evidence), and the per-replicate files themselves, which stay on disk for audit.
- Escalate: nothing blocking. The four non-blocking routing entries are in `## Escalations` (E1-E4).
- Decisions I made: (1) Two sub-claims, 21b and 41a, have a sibling compound verdict of Mostly accurate whose replicate attributes the MA to the other sub-claim and calls this part correct. I recorded that verdict as `(compound; carried by …)` and did not let it set the sub-claim's verdict, following the code-review merge step's stated aim ("keeps a sub-claim's severe verdict from swallowing a sibling sub-claim's clean one") and decision 033's intra-claim rule. A strict reading of most-severe-wins would make both Mostly accurate, for 11 MA in total. (2) Where all replicates agreed on Verified, I carried r1's evidence unless another replicate had verdicted the exact sub-claim atomically. (3) The rubric's `:11` line holds two distinct sentences, the critic tallies (Claims 1a/1b) and the "Executed:" summary (Claim 2), so they are separate clusters.
