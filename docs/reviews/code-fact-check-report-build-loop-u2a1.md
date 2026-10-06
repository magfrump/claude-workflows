Commit: d07cc89c

# Code Fact-Check Report

**Repository:** /workspace (worktree /workspace/.claude/wt-build-loop-u2a1, branch feat/build-loop-u2a1)
**Scope:** branch diff `git diff main...HEAD` (main 900c47d0 .. d07cc89c; commits 6f624cdf, 706e0499, d48f4645, 91469367, d07cc89c): scripts/build-loop.sh, scripts/dev-cycle.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, test/lib/build-loop-fixtures.bash, test/scripts/build-loop-read.bats, test/scripts/dev-cycle.bats, test/scripts/fixture-git-env.bats (new), docs/working/plan-build-loop-handoff.md, docs/working/questions.md (Q-119), the rubric's iteration-2 section, the 2026-10-06 `feat/build-loop-u2a1` rows of docs/reviews/override-log.md, and the messages of 91469367 and d07cc89c. Earlier commits' message claims are settled by Accepted-immutable rows and were not re-verdicted; other docs/reviews/*.md artifacts were skipped by all three replicates. Merged from `code-fact-check-report-build-loop-u2a1-r1.md` (47 claims), `-r2.md` (38) and `-r3.md` (39), all at d07cc89c (iteration 3, final confirming pass).
**Commit:** d07cc89c
**Replication:** k=3
**Checked:** 2026-10-06
**Total claims checked:** 79
**Summary:** 65 verified, 12 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable (Claims 53-67 are the Stage 2.5 submitted claims: 15 verified, 1 mostly accurate)

Merge method: code-review skill, "Merging replicate verdicts (most-severe-wins)". Claims were clustered on (file, line range ±5, substance). Where any replicate verdicted a finer part of a sentence that another verdicted as one compound claim, the merged report emits the finer rows (`Na`/`Nb`/...) and records the compound verdict on each row as `(compound)`; where a compound verdict blames only a sibling part it is recorded as `(compound; carried by <sibling>)` and does not set the verdict (decision 033, as iteration 2's merge did). A replicate claim whose own Scope line names a second location (for example r3 Claim 7's "here and in override row `docs/reviews/override-log.md:327`") is recorded in both clusters as `(compound, via rN Claim M)`. Evidence and reasoning come from the replicate that assigned the winning verdict, named in each claim as "Carried from rN Claim M"; claim numbers inside carried prose are that replicate's own numbering. Paths such as `$FC/logs/...` and `$S/logs/...` are relative to that replicate's run root (see Execution provenance). No claim or evidence was added in the merge.

**Last merged claim: 52 (52e).** A Stage 2.5 submitted-claims section, if appended, numbers from Claim 53.

## Execution provenance (per replicate, as each recorded it)

- **r1:** `FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`. cwd the worktree (or a `git archive` export of a named commit under the scratch dir), `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1` wherever a fixture repo was made, every process under `timeout`, TMPDIR a `mktemp -d /tmp/u2a1i3-XXXX` directory (no dot-prefixed part), deleted at the end with the export copies and victim repos. Runs 2026-10-06T16:47Z-16:56Z, logs in `$FC/logs/`. Mutants ran only on exports of HEAD (`$FC/mutants.sh`, 13 mutants). Run table E1-E10 (suites, mutants, isclosed equivalence over 110 paths, timing, entry_why one-argument at d48f4645 and HEAD, the A10 victim runs, `--local-env-vars` timing, fixture-git-env timing, hermeticity lint, shellcheck and numstat) is in `-r1.md`. Bats 1.8.2. No process left running.
- **r2:** `FC=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc2`. Suite runs used the worktree read-only with a `mktemp -d /tmp/u2a1i3-XXXX` TMPDIR, deleted after each run. Mutants ran on copies of `scripts/` and `test/` under `$FC/copy-*` through `$FC/mut.sh`, `$FC/mut2.sh`, `$FC/mut3.sh` and `$FC/mut4.sh` (12 mutants), each copy deleted after its run. Same git config isolation; every command under `timeout`; output in `$FC/logs/`. Runs 2026-10-06T16:47Z-16:54Z. Copy-based runs of build-loop-read.bats test 4 fail in every copy because they read `$REPO_ROOT/docs/dev-cycle.md` and the copies hold no `docs/`; r2 treated that failure as environmental.
- **r3:** `S=/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc3`. Same git config isolation and `timeout`. Mutants (M1-M11) ran only on `$S/copy`, a `git archive d07cc89c` export restored with `git checkout -- .` after each. Suite runs used a `mktemp -d /tmp/u2a1i3-XXXX` TMPDIR, deleted after. Logs in `$S/logs/`. Runs 2026-10-06T16:47Z-16:56Z, from cwd the worktree unless a claim names `$S/copy` or `$S`. Victim repos (`$S/fix/`) deleted; no process left running.

All three replicates consulted `docs/reviews/hallucination-patterns.md` and compared the per-suite test-count claims (rubric and commit 91469367) against the logged patterns ("All 85 tests ... claimed in commit 59ca38f", "mode1-equiv 33 claimed in commit 37c5ea9"). Every count matched this time.

## Claims Requiring Attention (summary)

| Claim | Location | Verdict | Replicate verdicts | Gist |
|---|---|---|---|---|
| 4 | `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21` | Mostly accurate | r1=Mostly accurate · r2=Verified · r3=Verified | A8 "printed an empty reason" holds only when spliced into a line; assigned (main_file's form) the one-argument call ended the shell |
| 8 | `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27` | Mostly accurate | r1=— · r2=— · r3=Mostly accurate · single-replicate detection | "five other suites" omits test/scripts/fixture-git-env.bats, whose own setup commits into an inherited GIT_DIR |
| 9 | `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31` | Mostly accurate | r1=Mostly accurate · r2=Verified · r3=Verified (compound) | C11's measured 0.42-0.52 ms is not what the "corrected" row says (0.3-0.5 ms) |
| 11 | `docs/reviews/override-log.md:322` | Stale | r1=Stale · r2=— · r3=— · single-replicate detection | C1 row cites `scripts/dev-cycle.sh:181-183`; since d48f4645 the condition and message are at `:179-181` |
| 13 | `docs/reviews/override-log.md:325` | Mostly accurate | r1=Mostly accurate · r2=Verified · r3=Verified (compound) | subshell re-measured at 0.48-0.54 ms, at or above the 0.5 ceiling; 0.3 floor is iteration 1's |
| 15 | `docs/reviews/override-log.md:327` | Mostly accurate | r1=Verified · r2=Verified · r3=Mostly accurate (compound, via r3 Claim 7) | C7's suite list omits fixture-git-env.bats |
| 19 | `docs/working/plan-build-loop-handoff.md:125` | Incorrect | r1=Incorrect · r2=— · r3=— · single-replicate detection | F10 lists docs/thoughts/ among check_fix's denials; check_fix allows it and `:274` says so |
| 20 | `docs/working/plan-build-loop-handoff.md:273` | Mostly accurate | r1=Mostly accurate · r2=— · r3=Verified | "about twenty override rows": 26 Defer rows on main name U2 |
| 35b | `scripts/lib/dev-cycle-read.sh:283-284` | Mostly accurate | r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate | error and default arms also drop "for" when `$2` is ""; the comment states the "" case only for notfile/badform |
| 49b | `test/scripts/fixture-git-env.bats:3-6` | Mostly accurate | r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound) | header names GIT_INDEX_FILE but the victim check counts only commits and refs |
| 51b | commit 91469367 message | Mostly accurate | r1=Mostly accurate (compound; carried by 51c) · r2=Mostly accurate · r3=Mostly accurate | `${2-}` is not "like the lib's other optional arguments", which read `${2:-}` |
| 51c | commit 91469367 message | Mostly accurate | r1=Mostly accurate (compound) · r2=— · r3=Verified | Notes "about 2 s"; measured 0.71-0.73 s wall (r1), 0.964 s (r3) |
| 52d | commit d07cc89c message | Mostly accurate | r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound) | "corrected to the re-measured range": the row holds the iteration 1 and 2 union |

---

## Claim 1: "233 changed code lines after iteration 2's fixes"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:4`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the brief's counting command over main...HEAD (d07cc89c); does not establish that the count excludes non-code files outside docs/ (SKILL.md is counted, 2 lines).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the count at d07cc89c equals 91469367's because d07cc89c touches only docs/reviews/ files (r2: "paraphrased — no quote available because the claim is about which files a commit touches"). r2: "It does not cover any other way of counting." r3: "does not establish the count under any other definition of 'code line'."

Carried from r1 Claim 1. Executed (E10): the command prints `233`, from the numstat rows `6 7 scripts/build-loop.sh`, `6 8 scripts/dev-cycle.sh`, `49 35 scripts/lib/dev-cycle-read.sh`, `1 1 skills/dev-cycle/SKILL.md`, `5 0 test/lib/build-loop-fixtures.bash`, `10 4 test/scripts/build-loop-read.bats`, `55 14 test/scripts/dev-cycle.bats`, `32 0 test/scripts/fixture-git-env.bats`. d07cc89c changes no code, so the count at 91469367 is the same.

**Evidence:** E10 output (r1; the numstat rows quoted above, e.g. `scripts/lib/dev-cycle-read.sh`, `test/scripts/dev-cycle.bats`)

---

## Claim 2: "53 clusters: 44 Verified, 9 Mostly accurate, 0 Incorrect. Agreement 88.7% (47/53)" and "replicates -r1/-r2/-r3: 40, 34, 37 claims"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the figures against the merged report and the three replicate headers as committed at d07cc89c; does not re-derive the clustering.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: r2's own header (`34`) was read at d48f4645, "read before this report overwrote it"; "It does not re-verdict the merged claims." · r3: the same figures are "also stated in commit d07cc89c's body: '0 Must Fix, 0 Incorrect (53 merged claims, 88.7% replicate agreement)'" (merged Claim 52a); "does not re-derive the per-cluster agreement or re-verdict that report's claims"; r3 also found no rubric row at `:20-31` with a Must Fix severity (paraphrased — absence of a severity). · merge note: the merged report the replicates cite is the iteration-2 merge this file replaces; read it with `git show d07cc89c:docs/reviews/code-fact-check-report-build-loop-u2a1.md`.

Carried from r1 Claim 2. The merged report at d07cc89c has `**Total claims checked:** 53` and `**Summary:** 44 verified, 9 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md`, header), 53 `## Claim` headings and a verdict tally of 44/9, and states `Agreement rate: 47/53 = 88.7%` (same file, line 1135). The replicate headers (`git show HEAD:...-r1.md` etc.) read `Total claims checked:** 40`, `34`, and `37 (Claims 1-35, 36a, 36b)`. 47/53 = 0.8868.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1127-1135` (at d07cc89c), replicate headers at d07cc89c

---

## Claim 3: A7 "✅ Fixed (91469367): comment states each word's use; check_answer ends every refusal 'so no entry in $f is read'"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers entry_why's comment against its arms and check_answer's main_entry refusal arm; does not cover check_answer's other refusal lines (they already ended that way) or check_brief/main_file wording.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "It does not cover check_answer's other skip lines ('could not be read', 'more than one entry', 'in both')." r2 also notes check_answer's odd, unbalanced and quoted arms at `:584-586` end `so no entry in $f is read`. · merge note: r3 verified the same check_answer arm under its own Claim 27 (merged Claim 39), where mutant M8 failed test 9, without verdicting this rubric row.

Carried from r1 Claim 3. check_answer's case now has one refusal arm:

```bash
# scripts/lib/dev-cycle-read.sh:573-577
    case "$e" in
      absent) continue ;;
      blob) ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
    esac
```

(excerpt ends :577; enclosing check_answer() continues to :595 — read). The comment `:281-285` names each word's use of `$2` (see Claim 31). Mutant E2 `answer-ending` (that arm back to "so no entry in it is read") fails three tests (65, 67, 71).

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-295`, `:567-595`; `$FC/logs/mut-answer-ending.log`

---

## Claim 4: A8 "entry_why read `$2` bare; called with one argument under `set -u` it printed an empty reason"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`
**Type:** Behavioral / Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers d48f4645's entry_why called with one argument under `set -euo pipefail`, inline and as an assignment; does not establish any caller made such a call (none did).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2 (Verified): "It does not cover a bare (non-subshell) call at d48f4645, which would end the caller's shell under set -e." · r3 (Verified): "Covers d48f4645's entry_why spliced into an `echo` argument, the form check_brief and check_answer use; does not cover a bare `x="$(entry_why w)"` assignment, which under `set -e` ends the caller instead of printing anything." r3 executed that assignment form too: it "printed only the unbound-variable error and ended the shell". All three replicates observed the same shell-ending behaviour; r2 and r3 kept it as a scope caveat, r1 graded it against the claim.

Carried from r1 Claim 4. At d48f4645 entry_why opened with `local w="${1//$'\n'/ }" p="${2//$'\n'/ }"` (d48f4645 `scripts/lib/dev-cycle-read.sh:284`). Executed (E5): `echo "skip x: $(entry_why error)"` printed `line 284: 2: unbound variable` on stderr, then `skip x: ` and carried on (exit 0), which is the claim. But `r="$(entry_why notfile)"`, the form main_file uses (`FILE_WHY="$(entry_why ...)"`, `scripts/build-loop.sh:133`), ended the whole shell with exit 1 instead. Precise version: "printed an empty reason when spliced into a line, and ended the caller's shell when assigned". HEAD reads `p="${2-}"` (`scripts/lib/dev-cycle-read.sh:287`) and E5 at HEAD prints each one-argument reason with no error. The fix is right either way.

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-295`; d48f4645 `scripts/lib/dev-cycle-read.sh:283-292`; `$FC/logs/a8-d48.log`

---

## Claim 5: A10 "replacing it with `:` passes every test while a victim repo gains 7 and 5 commits" and "✅ Fixed: test/scripts/fixture-git-env.bats; fails on that mutant"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the d48f4645 mutant (both unset lines `:`) run normally and through the two fixture-git-env filters, and HEAD's new suite against the same mutant; does not cover a GIT_DIR-only victim (no GIT_INDEX_FILE), where the whole suite fails instead.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover the GIT_INDEX_FILE half (Claim 31b)" (merged Claim 49b). r2 also records that test 1 fails at the inner run's own status (the inner dev-cycle test fails with the victim as its repo) before it reaches the victim check, and test 2 fails at the victim check. · r3: read "every test" as test-strategy G1 measured it (dev-cycle.bats and build-loop-read.bats run normally) and "7 and 5" as the one test of each suite fixture-git-env.bats runs; "does not mean the full suites pass under an inherited GIT_DIR (they do not: run whole under a victim GIT_DIR with the mutant, dev-cycle.bats fails 75/75 and build-loop-read.bats 13/19, and the victims gain 81 and 72 commits)". r3 Decision: "Read the rubric's A10 'passes every test' as test-strategy G1 measured it ... and stated the residue in its Scope."

Carried from r1 Claim 5. Executed (E6) on a d48f4645 export with both lines `:`: a normal run of both suites gave `93 ok, 0 not ok`. The dev-cycle filter `^prints all eight sections` with GIT_DIR and GIT_INDEX_FILE at a one-commit victim left it at `victim commits 8`, and the build-loop-read filter `exact policy line is set` left another at `victim commits 6`: +7 and +5. On HEAD exports (E2) the mutant `unset-dc` fails fixture-git-env test 1 and `unset-bl` fails test 2 (`not ok 1 dev-cycle.bats fixtures stay out ...`, `not ok 2 build-loop-read.bats fixtures stay out ...`).

**Evidence:** `$FC/logs/a10c-summary.log`, `$FC/logs/mut-unset-dc.log`, `$FC/logs/mut-unset-bl.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 6: A11 "without it `--check-write 2026-01-01-x.md` prints ok (the write gate fails open)" and "✅ Fixed: new dev-cycle.bats test; fails on that mutant"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the prefix-guard mutant against the new test; does not establish what a successful --check-write would let a caller write.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover other isclosed mutants." r2 also notes that "The `closedx/` and `docs/` lines in that test do not tell the mutant apart (their prefix is not stripped either way). Only the bare name does." · r3: Scope also covers commit 91469367's "dropping isclosed's prefix guard made --check-write print ok for 2026-01-01-x.md" (merged Claim 51a); "does not cover other brief-shaped names than the three the test uses". r3 records the failing test printing `ok 2026-01-01-x.md` where it expects `skip 2026-01-01-x.md: not one of the dev cycle's own files`.

Carried from r1 Claim 6. Mutant E2 `isclosed-prefix` turns `isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief ...` into `isclosed() { isbrief ...`. The test at `test/scripts/dev-cycle.bats:1371` fails, and the run's output starts `# ok 2026-01-01-x.md`, so the mutant's --check-write prints ok.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158`; `test/scripts/dev-cycle.bats:1371-1378`; `$FC/logs/mut-isclosed-prefix.log`

---

## Claim 7a: A12 "main_entry's guard order (error before badform with no default branch) is unstated and unpinned | Low | ... ✅ Fixed: comment and one test line"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the swapped-guard mutant against the badform test. It does not cover the comment's wording (Claim 27).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (verdicted A12 with A13 as one claim): "Covers the comment text, the test line and its mutant, the check_fix comment word and the header's line widths; does not judge the reflow's wording." · r3: "Covers the comment's presence, the test line, and that the test fails when the two guards are swapped; does not cover callers, which check main_by_name themselves first." · merge note: r2's "Claim 27" in the Scope is r2's numbering (merged Claims 33-34).

Carried from r2 Claim 7. The mutant that puts `if ! pathform "$1"; then echo badform; return; fi` before the main_by_name line (`$FC/mut.sh guard-order`, exit 1) fails the test at its last expected line, `error" ] || ...` (test file line 1368). The test sets `MAIN_SHA=""; main_entry .gitattributes` (`test/scripts/dev-cycle.bats:1359`).

**Evidence:** `$FC/logs/mut-guard-order.txt`, `test/scripts/dev-cycle.bats:1356-1369`

---

## Claim 7b: A13 "Wording: \"the skip message below repeats it\" (three messages do); the lib header's :16 and :25 | ✅ Fixed: \"skip messages\"; header reflowed whole"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:26`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the check_fix comment and lib header lines 8-27. It does not cover the scrub comment's long line at `:36`, which is outside the header paragraph.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1: measured the header lines `:8-31` at 69-80 columns, "with no short line left (paraphrased — no quote available because the claim is about line lengths, measured with awk)"; "does not judge the reflow's wording". · r2: its own line-length statement is likewise paraphrased ("about 78 columns", lines 8-27).

Carried from r2 Claim 8. `scripts/dev-cycle.sh:168` reads `# is the rule, and the skip messages below repeat it.`. Lib header lines 8-27 are all filled to about 78 columns with no short line (paraphrased — no quote available because the claim is about line lengths across 20 lines).

**Evidence:** `scripts/dev-cycle.sh:167-169`, `scripts/lib/dev-cycle-read.sh:8-31`

---

## Claim 8: "Five other suites write into an inherited GIT_DIR"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the list (here and in override row `docs/reviews/override-log.md:327`) names every suite that writes into an inherited GIT_DIR among this branch's files; does not re-execute the five suites named.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3 (Escalate E1, informational, for the orchestrator): fixture-git-env.bats "does not unset the repo-local variables in its own setup (`:9-15`) ... This is the C7 class (Defer), not a regression of this unit's code; adding the same `unset` line to its setup would close it." · merge note: the same r3 claim is recorded on the override row it names (merged Claim 15), where r1 and r2 verdicted the row's cited lines Verified.

Carried from r3 Claim 7. The list omits test/scripts/fixture-git-env.bats, added in 91469367, before this rubric section was written. Its setup does not unset the repo-local variables: it runs `git init -q -b main "$V"` and `git -C "$V" ... commit -q --allow-empty -m only` with the caller's environment (`test/scripts/fixture-git-env.bats:9-15`). Run with `GIT_DIR=$S/fix/victim2/.git` (cwd worktree, 2026-10-06T16:50Z, exit 1), both its tests failed and the victim went from 1 commit to 3. The precise version is "six other suites", or the C7 row's trigger should also cover fixture-git-env.bats's own setup.

**Evidence:** `$S/logs/fge-under-gitdir.txt`, `test/scripts/fixture-git-env.bats:9-15`, `docs/reviews/override-log.md:327`

---

## Claim 9: C11 "C4 override row's timings (measured 0.42-0.52 ms, 18-37 µs)" with status "✅ Row's figures corrected; the conclusion holds"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the rubric's figures against the corrected row and against a re-measurement on this host; does not establish other hosts' timings.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2 (Verified): "Covers the fact that the row changed and that the measured range matches the merged report. It does not establish that the row now states exactly that range (Claim 37)" (r2 Claim 37 = merged Claim 52d, Mostly accurate). r2 measured 443.5 and 482.9 µs per call and pair deltas of 18.6 and 20.3 µs. · r3 (Verified, r3 Claim 8, which verdicts the C4 row and this rubric figure together): "Covers the order of magnitude and the Won't-Fix conclusion, re-measured on this host; does not establish exact figures, which moved with load (one run fell outside both stated ranges)." r3 measured 408.5 and 568.8 µs per call and deltas of 18.0 and 6.5 µs. r3 Decision: "graded the C4 and 'about 2 s' timings Verified on order of magnitude, though single runs fell outside the stated ranges, because both are marked approximate and the conclusions hold." · r1 Escalate: "Claims 8/12/46b are one timing-wording item" (merged 9, 13, 52d).

Carried from r1 Claim 8. The row now reads `entry_why adds one subshell (0.3-0.5 ms, by host) ... ~17-37 µs` (`docs/reviews/override-log.md:325`). That is not the range this rubric line quotes as measured (0.42-0.52 ms, 18-37 µs). It is that range widened to take in iteration 1's original 0.3 ms and 17 µs, with 0.52 rounded down. My re-measurement (E4: 0.48-0.54 ms per subshell, 18.7-21.5 µs per pair) sits inside the rubric's figures, apart from 0.54, and above the row's 0.5 ceiling. Precise version: "row's figures widened to 0.3-0.5 ms (iteration 1 and 2 together)". The conclusion (negligible) holds.

**Evidence:** `docs/reviews/override-log.md:325`; `$FC/logs/timing.log`

---

## Claim 10: "Tests after 91469367: 98/98 (dev-cycle 75, build-loop-read 19, fixture-git-env 2, hermeticity 2) under a TMPDIR with no dot-prefixed part; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:37`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four suites and shellcheck of the four changed shell files at d07cc89c (no code change since 91469367); does not cover shellcheck of the .bats files or the "fix-drift check".
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "`shellcheck -s bash` over the .bats files reports one SC2015 info at `test/scripts/fixture-git-env.bats:19`. The repo's shellcheck gate covers only .sh/.bash files (`scripts/health-check.sh:34`)." · r3: Scope also covers commit 91469367's "Tests: ... 98/98 ... shellcheck clean" (merged Claim 51a); .bats files are not held to shellcheck ("main's dev-cycle.bats alone has 19 findings") and "the new fixture-git-env.bats draws two info-level SC2015 notes". · all three: hallucination-pattern log consulted; the counts match no logged pattern. · r1, r2 and r3 each exclude the "fix-drift check ... found nothing" sentence.

Carried from r1 Claim 9. E1 printed `1..98` and 98 `ok` lines, exit 0. `grep -c '^@test'` gives 75, 19 and 2 for the three test/scripts suites and 2 for test/fixture-hermeticity.bats. E10 shellcheck printed nothing, exit 0. Matches no logged hallucination pattern.

**Evidence:** `$FC/logs/suite.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 11: C1 row's location "`scripts/dev-cycle.sh:181-183`"

**Location:** `docs/reviews/override-log.md:322`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the line citation only; the row's substance (constraints.md inline in check_fix, docs/thoughts/ fixable) is correct (Claims 26, 39).
**Replicate verdicts:** r1=Stale · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1 Escalate: "Claim 10 is a line-number drift in an override row" (non-blocking). · merge note: r1's "Claims 26, 39" are merged Claims 27 and 44.

Carried from r1 Claim 10. At 6f624cdf, :181-183 held check_fix's condition and the constraints.md echo. d48f4645 shortened the comment above check_fix by two lines, so at HEAD the condition and skip message are at `:179-181`:

```bash
# scripts/dev-cycle.sh:179-181
  elif [[ ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|human-author|reviews|decisions)/ \
    || "$lp" == docs/dev-cycle.md || "$lp" == docs/constraints.md || "$a" == */.* || "$low" =~ $INSTRUCTION_FILE ]]; then
    echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (...)"
```

(excerpt ends :181, message shortened; enclosing check_fix() continues to :184 — read). At HEAD, :181-183 is the echo, the import arm and its echo.

**Evidence:** `scripts/dev-cycle.sh:170-184`; `git show 6f624cdf:scripts/dev-cycle.sh` lines 179-184

---

## Claim 12: C2 "Three call sites write `isbrief X || isclosed X` themselves (lib writable, check_brief; build-loop.sh shared_branches)"

**Location:** `docs/reviews/override-log.md:323`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three named sites; does not establish that there are no other callers of isclosed (grep finds none).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 11. `... ]] || isbrief "$1" || isclosed "$1"` (`scripts/lib/dev-cycle-read.sh:161`), `if ! isbrief "$a" && ! isclosed "$a"; then` (`:348`, the same test negated) and `if ! { isbrief "$f" || isclosed "$f"; } || ...` (`scripts/build-loop.sh:318`). A grep for `isclosed` finds no other caller outside tests.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158-162`, `:348`; `scripts/build-loop.sh:318`

---

## Claim 13: C4 row "entry_why adds one subshell (0.3-0.5 ms, by host) per refused argument, and isclosed costs ~17-37 µs more per brief pair ... figures re-measured in iteration 2"

**Location:** `docs/reviews/override-log.md:325`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the per-call costs on this host; does not establish the "suite delta within run-to-run noise" sentence (not re-measured).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2 (Verified): "Covers this host's measurement, which falls inside both ranges. It does not cover the 'suite delta within run-to-run noise' clause." r2: "Timings depend on load. Medium confidence for that reason." (443.5 and 482.9 µs per call; deltas 18.6 and 20.3 µs.) · r3 (Verified, r3 Claim 8, which verdicts this row and the rubric's C11 figure together): "does not establish exact figures, which moved with load (one run fell outside both stated ranges)"; r3 found the row's figures match the iteration-2 merged report's measured range (`~0.4-0.5 ms per entry_why subshell and ~18-37 µs per pair`, `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1106` at d07cc89c). r3 Decision: graded Verified on order of magnitude. · r1 Escalate: one timing-wording item with merged 9 and 52d.

Carried from r1 Claim 12. E4 measured entry_why's `$(...)` at 0.485, 0.514 and 0.542 ms per call, and `isbrief || isclosed` on a closed/ path at 18.7-21.5 µs more than the old substitution (`$FC/logs/timing.log`). The isclosed range holds, and the subshell cost is at or just above the row's 0.5 ms ceiling. As Claim 8 says, the "re-measured" range quoted in the rubric is 0.42-0.52 ms. The row's 0.3 floor is iteration 1's figure. The conclusion (Won't-Fix, negligible against the ~1 ms git start on the same path) holds.

**Evidence:** `$FC/logs/timing.log`; `$FC/timing.sh` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 14: "91469367 reflows the header whole and states the final wording"

**Location:** `docs/reviews/override-log.md:326`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the resolution sentence of the row; the row's history claims about 706e0499/d48f4645 are Accepted-immutable and not re-verdicted.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** merge note: r2 Claim 37's Scope names this row as "the Accepted-immutable row added beside them (`:326`)" without verdicting it.

Carried from r1 Claim 13. The header `scripts/lib/dev-cycle-read.sh:8-31` has no short line left (see Claim 7). 91469367's message says `Wording: the lib header reflowed whole` and gives the final check_answer wording `ends every main_entry refusal with "so no entry in $f is read"`, which `:576` prints.

**Evidence:** `scripts/lib/dev-cycle-read.sh:8-31`, `:576`; `git log -1 91469367`

---

## Claim 15: C7 "Other suites still write fixture commits into an inherited GIT_DIR: test/merge-safety.bats:20-24 ..., and by reading test/cc-push.bats:35-36, test/scripts/archive-working-docs.bats:97,114, test/si-clean-state.bats:40, test/cc-isolated-functions.bats:1489"

**Location:** `docs/reviews/override-log.md:327`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the list (here and in override row `docs/reviews/override-log.md:327`) names every suite that writes into an inherited GIT_DIR among this branch's files; does not re-execute the five suites named.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate (compound, via r3 Claim 7)
**Replicate annotations:** r1 (Verified, Medium): "Covers that each cited line runs `git init`/`git commit` and that none of the five files unsets `GIT_DIR` or `--local-env-vars`; does not re-execute the merge-safety victim run." · r2 (Verified, Medium): "Covers the cited lines (each a `git init` or fixture commit) and the absence of any unset in those five files. It does not re-run the row's merge-safety victim execution." · r3: its claim is located at the rubric's C7 row (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27`, merged Claim 8) and its Scope names this override row; Escalate E1 (informational, for the orchestrator) as in merged Claim 8. · merge note: r1 and r2 found every cited line accurate; the Mostly accurate rests on the list's omission, not on any cited line.

Carried from r3 Claim 7. The list omits test/scripts/fixture-git-env.bats, added in 91469367, before this rubric section was written. Its setup does not unset the repo-local variables: it runs `git init -q -b main "$V"` and `git -C "$V" ... commit -q --allow-empty -m only` with the caller's environment (`test/scripts/fixture-git-env.bats:9-15`). Run with `GIT_DIR=$S/fix/victim2/.git` (cwd worktree, 2026-10-06T16:50Z, exit 1), both its tests failed and the victim went from 1 commit to 3. The precise version is "six other suites", or the C7 row's trigger should also cover fixture-git-env.bats's own setup.

**Evidence:** `$S/logs/fge-under-gitdir.txt`, `test/scripts/fixture-git-env.bats:9-15`, `docs/reviews/override-log.md:327`

---

## Claim 16: C8 "Each test's setup now starts git once for `--local-env-vars` (~1 ms, ~0.1 s per run of both suites)"

**Location:** `docs/reviews/override-log.md:328`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the per-call cost on this host, warm; does not cover a cold first call (one 200-call loop averaged 15 ms in a fresh directory).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1 Decision: "Treated one 15 ms cold `rev-parse` loop as an outlier against three ~1 ms runs." · r2 (Behavioral, static): "Covers the two setups. It does not cover the '~0.1 s per run' figure." · r3 (static): "Covers the arithmetic from the setups and the performance report's measurement; does not re-time the git call on this host" (`1,068 µs/call`, `docs/reviews/performance-reviewer-review-2026-10-06-final-build-loop-u2a1.md:24`).

Carried from r1 Claim 15. E7: three warm 200-call loops gave 1.55, 1.00 and 1.04 ms per call, against 1.13-1.80 ms for `git --version`. 94 setups × ~1 ms ≈ 0.1 s. One earlier cold loop averaged 15.5 ms. I count it as an outlier, since the same command then measured ~1 ms three times.

**Evidence:** `$FC/logs/c8.log`; `test/scripts/dev-cycle.bats:13`; `test/lib/build-loop-fixtures.bash:15`

---

## Claim 17: C9 "Untested: entry_why's newline folding of the word argument (no caller produces such a word; the mutant survives), check_brief's notdir and error words through the CLI, main_file's error reason through --settings"

**Location:** `docs/reviews/override-log.md:329`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the word-folding mutant and the absence of CLI tests for the two other cases; does not establish that no caller could ever pass such a word.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish the absence of CLI tests for every word (by reading, none feeds check_brief a notdir or error word)"; its no-newline-word inference is "paraphrased — no quote available because this is inferred from pathform at `:141-149` and main_entry at `:263-279` together". · r3: "does not cover the row's other two untested items (check_brief's notdir/error through the CLI, main_file's error through --settings), which were not mutated here"; its main_entry-words statement is likewise paraphrased (six `echo` sites, `scripts/lib/dev-cycle-read.sh:266-279`). · r1: its absence-of-tests statement is "paraphrased — no quote available because the claim covers absence of code".

Carried from r1 Claim 16. Mutant E2 `why-word-nl` (`local w="$1"`) passes the entry_why test: `1 ok, 0 not ok`. main_entry's words are fixed strings or `notdir $p`, and `$p` passed pathform (`scripts/lib/dev-cycle-read.sh:266-277`), so no caller gets a word holding a newline. A grep of both suites finds no expected line `could not be read for docs/dev-cycle.md` and no check_brief notdir line (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `$FC/logs/mut-why-word-nl.log`; `scripts/lib/dev-cycle-read.sh:263-280`

---

## Claim 18: C10 "build-loop-read.bats:84 keeps an older `git replace ... && git config` chain ... Guarded by its own `git replace -d` at :85"

**Location:** `docs/reviews/override-log.md:330`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two lines; does not judge whether the chain can fail silently.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover whether `-d` runs when the line-85 assertion fails." · r3: "does not judge whether the chain needs splitting."

Carried from r1 Claim 17.

```bash
# test/scripts/build-loop-read.bats:84-85
    git replace "$(git rev-parse main:docs/dev-cycle.md)" "$(git hash-object -w docs/dev-cycle.md)" && git config core.useReplaceRefs true
    settings_like policy "policy review set:"; git replace -d "$(git rev-parse main:docs/dev-cycle.md)"
```

**Evidence:** `test/scripts/build-loop-read.bats:84-85`

---

## Claim 19: F10 "Floor item 4 keeps the docs `check_fix` denied (`docs/decisions/`, `docs/thoughts/`, `docs/human-author/`, other briefs' working docs, cycle files)"

**Location:** `docs/working/plan-build-loop-handoff.md:125`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the attribution of `docs/thoughts/` to check_fix's denials, at HEAD and on main; this line predates the branch and is outside the diff, but the diff's own note at `:274` now says the opposite. Does not judge the floor list itself.
**Replicate verdicts:** r1=Incorrect · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r1 Decision: "verdicted plan `:125` although it is outside the diff, because it describes check_fix, the scoped code, and contradicts the new `:274`." · r1 Escalate: "Claim 18 is a pre-existing plan line outside the diff that now contradicts the diff's own `:274`" (non-blocking). · r1 attention item: "Reword to 'the docs check_fix denies plus docs/thoughts/ and constraints.md'."

Carried from r1 Claim 18. check_fix denies only `^docs/(working|human-author|reviews|decisions)/`, dev-cycle.md, constraints.md, dot parts and instruction files (`scripts/dev-cycle.sh:179-180`). docs/thoughts/ is fixable, and the branch's own test pins `"ok docs/thoughts/t.md"` (`test/scripts/dev-cycle.bats:1029`). The U2a1 note in the same plan says `docs/thoughts/ stays fixable in-cycle as a living doc, so check_fix and the floor differ there on purpose` (`docs/working/plan-build-loop-handoff.md:274`). Read together, the two lines contradict each other. Precise version: "floor item 4 keeps the docs check_fix denies (decisions/, human-author/, ...) plus docs/thoughts/ and constraints.md". The same row's "cycle files" also leaves out constraints.md, which check_fix now denies.

**Evidence:** `docs/working/plan-build-loop-handoff.md:125`, `:274`; `scripts/dev-cycle.sh:179-181`; `test/scripts/dev-cycle.bats:1016-1032`

---

## Claim 20: "U1 measured four units against a planned one, and U2 carries about twenty override rows"

**Location:** `docs/working/plan-build-loop-handoff.md:273`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers U1's unit count (U1a-U1d) and a grep count of override rows deferred to U2 on main; does not establish which rows the author counted.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Verified
**Replicate annotations:** r3 (Verified, Medium): "Covers the unit count and the order of the row count; does not fix which filter 'carries' means." r3 counted the same 26 rows (`Revisit trigger:` naming U2) and judged "About twenty" "the right order"; its count is "paraphrased — no quote available because this is a count over table rows".

Carried from r1 Claim 19. U1 landed as U1a, U1b, U1c and U1d (main's head commit: `docs(checkpoint): U1 complete (U1d landed at 4e12b03c)`). On main, `grep -E '\| Defer \|.*\bU2\b' docs/reviews/override-log.md` matches 26 rows. "About twenty" understates that. Precise version: "about twenty-five".

**Evidence:** `git log -1 900c47d0`; `git show main:docs/reviews/override-log.md`

---

## Claim 21: U2a1 bullet "`main_entry`'s `badform` word with one shared reason mapping, `entry_why` ...; one spelling of the closed/ rule, `isclosed` ...; `check_fix` also refuses `docs/constraints.md` (row 204: the user writes it, D2; `docs/thoughts/` stays fixable in-cycle ...)"

**Location:** `docs/working/plan-build-loop-handoff.md:274`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named change against the code and plan D2; does not cover the U2a2/U2b/U2c bullets (future work).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "Q-119's option [1] (`docs/working/questions.md:386`) gives the same list and is covered too."

Carried from r1 Claim 20. The changes are `if ! pathform "$1"; then echo badform; return; fi` (`scripts/lib/dev-cycle-read.sh:267`), `entry_why()` (`:286`), used by all three callers (`:358`, `:576`, `scripts/build-loop.sh:133`), and `isclosed()` (`:158`). check_fix adds `"$lp" == docs/constraints.md` (`scripts/dev-cycle.sh:180`). Plan D2 says "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`).

**Evidence:** cited lines (`scripts/lib/dev-cycle-read.sh:267`, `scripts/dev-cycle.sh:180`, `docs/working/plan-build-loop-handoff.md:50`)

---

## Claim 22: Q-119 "Split recorded in the U2a rubric and commit e8f76379 on `feat/build-loop-u2a`"

**Location:** `docs/working/questions.md:391`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commit and rubric references; does not judge the options.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 21. `git log -1 e8f76379` gives `docs(reviews): U2a iteration 3 (final pass, k=3) and the iteration-4 gate decision: split`, and `git branch --contains` lists `feat/build-loop-u2a`. That branch's rubric has `### Iteration-4 gate decision: split` at :69, with the U2a1 contents at :74.

**Evidence:** `git show feat/build-loop-u2a:docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a.md:69-74`

---

## Claim 23: "Markup that adds letters (a checked task box, a tag) can still hide a copy"

**Location:** `scripts/build-loop.sh:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers SETTINGS_AWK's copy count for a `[x]` box; does not cover other markup.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover tags made only of non-letters." · r3: "does not cover what a hidden copy does downstream."

Carried from r1 Claim 22. `s = tolower($0); gsub(/[^a-z]/, "", s)` then `if (index(s, "buildlooppolicy") == 1)` (`scripts/build-loop.sh:155-156`). `- [x] Build-loop policy:` folds to `xbuildlooppolicy` and is missed, while `- [ ]` folds to `buildlooppolicy` and is counted, as `:18-20` says. The test at `test/scripts/build-loop-read.bats:118-120` pins the checked-box case.

**Evidence:** `scripts/build-loop.sh:150-164`; `test/scripts/build-loop-read.bats:118-120`

---

## Claim 24: "A tip on a branch not ahead of main, or whose subject does not start 'handoff:', is working"

**Location:** `scripts/build-loop.sh:65-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers status_line's loop state for `ahead` 0; does not cover how check_branch counts `ahead`.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover the absent case, which prints `absent`." · r3: "does not cover marker_kind's subject parsing."

Carried from r1 Claim 23.

```bash
# scripts/build-loop.sh:352-361
  loop=working
  if [[ "$ahead" -gt 0 ]]; then
    kind="$(marker_kind "$sha")"
    ...
  fi
  echo "ok $a $st $pol $br $loop $sha $date $disp$reason"
```

(excerpt elides :355-359, the marker case; status_line() ends :362 — read). `ahead` is check_branch's count of the branch's commits not on the default branch, so a branch behind main or level with it is also 0, which fits "not ahead".

**Evidence:** `scripts/build-loop.sh:325-362`

---

## Claim 25: main_file "returns 1 with FILE_WHY 'absent' or why it was not read (main_entry, ...)", now worded by `entry_why "$e" "$f"`

**Location:** `scripts/build-loop.sh:122-134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each non-blob word's FILE_WHY and its two consumers; does not cover the error reason through --settings (untested, Claim 16).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover a badform word, which neither fixed path can produce." r2's `mainfile-why` mutant failed build-loop-read tests 3 and 8, with test 4 the environmental copy failure (see Execution provenance). · r3 (static): "does not cover main_file's error reason through `--settings`, which no test drives (override row 329)"; "Both paths pass fixed names (`docs/dev-cycle.md`, `docs/constraints.md`), so badform cannot occur there." · merge note: r1's "Claim 16" is merged Claim 17.

Carried from r1 Claim 24.

```bash
# scripts/build-loop.sh:129-134
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
  esac
```

(excerpt ends :134; main_file() continues to :141 — read). Both consumers read only `absent` as missing, and every other value is a refusal: `[[ "$FILE_WHY" == absent ]] && why="no $f ..." || why="$FILE_WHY"` (`:214`) and `constraints unreadable: $FILE_WHY` (`:265`). Mutant E2 `mainfile-why` (passing "") fails T3 and T44, which pin `docs/dev-cycle.md is not a regular file on the default branch` (`test/scripts/build-loop-read.bats:61,193`).

**Evidence:** `scripts/build-loop.sh:122-141`, `:210-218`, `:262-266`; `$FC/logs/mut-mainfile-why.log`

---

## Claim 26: shared_branches' `isbrief "$f" || isclosed "$f"` is the old `isbrief "${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}"`

**Location:** `scripts/build-loop.sh:318`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the predicate's truth value over 110 constructed paths and the T28 test; does not cover git grep's listing.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound, via r3 Claim 20)
**Replicate annotations:** r2: "Covers 25 edge paths. It does not cover paths holding bytes outside pathform's set, which git grep could list but brief_fields refuses anyway." · r3 (Claim 20, located at `scripts/lib/dev-cycle-read.sh:158`, merged Claim 31): "Covers 22 edge cases ... against both old spellings; does not prove equality over all strings."

Carried from r1 Claim 25. E3 compared the old substitution with `isbrief || isclosed` over 10 prefixes × 11 names: `cases=110 diffs=0`. The names included closed/closed/, closedx/, Closed/, a doubled slash, a trailing newline and a nested name. Mutant E2 `shared-isclosed` (`isbrief "$f"` alone) fails T28 (`not ok 16 --status: two open briefs naming one branch both skip`).

**Evidence:** `$FC/equiv.sh`, `$FC/logs/isclosed-equiv.log`, `$FC/logs/mut-shared-isclosed.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 27: --check-fix header: not "... dev-cycle.md, constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @; compared ignoring case"

**Location:** `scripts/dev-cycle.sh:50-55`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers constraints.md in any case and docs/thoughts/ fixable; does not re-verify the paragraph's other pre-existing items.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2 (located `scripts/dev-cycle.sh:52-58`): "It does not re-check the other exclusions." r2 also quotes SKILL.md as matching (`skills/dev-cycle/SKILL.md:74`; merged Claim 40). · r3: "does not cover case-insensitive filesystems beyond the lower-casing."

Carried from r1 Claim 26. `lp` is the path lower-cased by `tr` (`scripts/dev-cycle.sh:175`), and the condition tests `"$lp" == docs/constraints.md` (`:180`). E1's run of `test/scripts/dev-cycle.bats:1016` expects `skip docs/Constraints.md: in-cycle fixes edit only` and `ok docs/thoughts/t.md`. Mutant E2 `constraints` (that condition removed) fails it.

**Evidence:** `scripts/dev-cycle.sh:170-184`; `$FC/logs/mut-constraints.log`

---

## Claim 28: "An in-cycle fix edits documentation only; the header's --check-fix paragraph is the rule, and the skip messages below repeat it. constraints.md is the user's (plan D2); docs/thoughts/ stays fixable."

**Location:** `scripts/dev-cycle.sh:167-169`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the agreement of header, skip messages, SKILL.md and code; does not cover check_path's own skip lines. The messages leave out "compared ignoring case", which the header states.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2 (Architectural): "Covers the skip messages taken together against the header's list. It does not claim that any one message carries the whole rule. No message says 'compared ignoring case'." r2 cites plan D2 as `A repo with no docs/constraints.md gets no dispatch` (`docs/working/plan-build-loop-handoff.md:21`) and the U2a1 bullet's `the user writes it, D2` (`:274`). · r3: "does not cover check_path's own skip lines (tracked, plain)"; r3's Scope also covers SKILL.md (merged Claim 40).

Carried from r1 Claim 27. The three skip messages in check_fix are `one of the cycle's own files`, the list `(not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files) and README.md` and `an instruction file imports it with @` (`scripts/dev-cycle.sh:178-182`). Together they cover the header paragraph's items (`:50-55`). Plan D2 includes "Creating the doc is your work" (`docs/working/plan-build-loop-handoff.md:50`).

**Evidence:** `scripts/dev-cycle.sh:50-55`, `:167-184`

---

## Claim 29a: "A change here must pass test/scripts/dev-cycle.bats and build-loop.sh's suites (build-loop-*.bats)"

**Location:** `scripts/lib/dev-cycle-read.sh:10-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that the named suites exist and source the lib; does not name fixture-git-env.bats, which runs one test of each.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2 (with the pipefail sentence, merged 29b): "It does not cover the new fixture-git-env.bats, which the sentence does not name (it runs one test of each named suite)"; its directory-listing statement is "paraphrased — no quote available because this is a directory listing". · r3 (with the skip sentence at `:20-23`, merged 30): "does not cover the reflowed header's other sentences, which this diff only re-wrapped"; directory listing likewise paraphrased.

Carried from r1 Claim 28. `rg --files test -g 'build-loop-*.bats'` lists only `test/scripts/build-loop-read.bats`. That suite loads `../lib/build-loop-fixtures`, whose `BL="$REPO_ROOT/scripts/build-loop.sh"` sources the lib.

**Evidence:** `test/lib/build-loop-fixtures.bash:10`; `scripts/build-loop.sh:92-95`

---

## Claim 29b: "The caller sets -euo pipefail (check_answer and brief_fields also set pipefail for themselves)"

**Location:** `scripts/lib/dev-cycle-read.sh:11-12`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the suite names and the two pipefail settings. It does not cover the new fixture-git-env.bats, which the sentence does not name (it runs one test of each named suite).
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=— · single-replicate detection
**Replicate annotations:** r2: verdicted together with the suites sentence (merged 29a).

Carried from r2 Claim 23. `test/scripts/build-loop-read.bats` exists and is the only `build-loop-*.bats` (paraphrased — no quote available because this is a directory listing). `local - out l; set -o pipefail` (`:313`) and `local - a="$1" f e r hit="" where="" n why; set -o pipefail` (`:567`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:8-31,309-313,566-567`

---

## Claim 30: "check_brief, check_branch and check_answer skip every argument unless it returned 0 with main found by name (main_entry and brief_fields answer error)."

**Location:** `scripts/lib/dev-cycle-read.sh:20-23`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_entry's error with no main (including a refused form) and brief_fields' error. It does not re-verify check_branch's skip.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3 (Claim 19, with the suites sentence, merged 29a): "Covers the suites the glob names and main_entry's answer with no main by name; does not cover the reflowed header's other sentences, which this diff only re-wrapped." r3's probe printed `error` for `main_entry .gitattributes` with `MAIN_BY_NAME=""` or `MAIN_SHA=""`.

Carried from r2 Claim 24. `if ! main_by_name; then echo error; return; fi` (`:266`) runs before pathform. brief_fields sets `BRIEF_ODD=error` for any answer but `blob` (`:316`). The badform test's last line (`MAIN_SHA=""; main_entry .gitattributes` → `error`) passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-279,309-316`, `$FC/logs/suites-head.txt`

---

## Claim 31: isclosed spells the closed/ rule once for writable, check_brief and shared_branches, equal to the three old spellings

**Location:** `scripts/lib/dev-cycle-read.sh:158-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers equality with writable's and check_brief's old regex and shared_branches' substitution over 110 paths; does not cover paths with characters pathform refuses (writable is called after pathform).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Covers writable, check_brief's gate (`:348`) and shared_branches (Claim 20) on 25 paths. It does not cover locale effects, because DIGIT and SLUG are spelled out and need no locale." · r3: "Covers 22 edge cases (case, double closed/, `closedx/`, empty slug, trailing newline, a leading `x/`, `//`, non-ASCII digits, `.md.md`, `.MD`, a slash in the slug) against both old spellings; does not prove equality over all strings."

Carried from r1 Claim 29.

```bash
# scripts/lib/dev-cycle-read.sh:158
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
```

E3 compared `old_closed` (the removed regex `^docs/working/briefs/closed/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$`) with isclosed: 0 differences. SLUG has no `/`, so the stripped rest must be exactly one brief name.

**Evidence:** `scripts/lib/dev-cycle-read.sh:153-162`; `$FC/logs/isclosed-equiv.log`

---

## Claim 32: main_entry prints "blob", "absent", "notfile", "notdir PART", "badform" (a path pathform refuses) or "error" (no default branch found by name, ls-tree failed, or the tree lists a name twice)

**Location:** `scripts/lib/dev-cycle-read.sh:246-256`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each arm of main_entry and badform's no-git path; does not re-test ls-tree failure (pre-existing).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover git's own handling of a name listed twice beyond the dup check." · r3: "Covers the word set and badform's zero git calls on seven refused forms; does not cover ls-tree failure, exercised by existing tests." · r2 (Claim 27) and r3 each ran a counting `git` shim: badform printed with `git calls: 0`.

Carried from r1 Claim 30.

```bash
# scripts/lib/dev-cycle-read.sh:266-268
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
  while [[ "$rest" == */* ]]; do p="${p:+$p/}${rest%%/*}"; rest="${rest#*/}"; want+=("$p"); done
```

(excerpt ends :268; main_entry() continues to :280 with ls-tree, the dup check and the notdir/absent/blob/notfile arms — read). main_by_name is `[[ -n "$MAIN_SHA" && -n "$MAIN_BY_NAME" ]]` (`:247`) and pathform is pure bash (`:140-149`), so badform runs no git. E1's test `:1356` expects `absent` for `x`, then `badform` ×6, including `.gitattributes` and `.github/x.yml`. Mutant `badform-error` fails it.

**Evidence:** `scripts/lib/dev-cycle-read.sh:243-280`; `$FC/logs/mut-badform-error.log`

---

## Claim 33: "Only blob reads the file, and only absent means there is none: every other word is a refusal"

**Location:** `scripts/lib/dev-cycle-read.sh:256-257`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every main_entry caller (check_brief, check_answer, brief_fields, main_file) and the two that reach them (status_line, shared_branches); does not cover callers U2a2 will add.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2 (with the guard-order sentence, merged 34): "It does not cover callers outside this repo." · r3: "does not cover a future caller such as U2a2's floor."

Carried from r1 Claim 31.

- check_brief: `absent) echo "ok $a new"`, `blob) ;;`, `*) echo "skip $a: $(entry_why "$e" "")"; return` (`:355-359`).
- check_answer: `absent) continue`, `blob) ;;`, `*) echo "skip ..."; return` (`:574-577`).
- brief_fields: `[[ "$(main_entry "$1")" != blob ]]` gives `BRIEF_ODD=error; return 1` (`:316`), so it refuses absent too, which the invariant allows.
- main_file: `blob`, `absent`, `*` as in Claim 24.
- status_line runs check_brief first and passes on any non-`ok ` line (`scripts/build-loop.sh:328-329`). shared_branches skips any brief brief_fields refuses (`:318`).

No caller reads a blob for any other word.

**Evidence:** `scripts/lib/dev-cycle-read.sh:310-330`, `:341-381`, `:567-595`; `scripts/build-loop.sh:126-141`, `:305-362`

---

## Claim 34: "It runs main_by_name, then pathform, itself, before any read (so with no default branch even a refused form answers error; pathform also means ls-tree prints the name unquoted)"

**Location:** `scripts/lib/dev-cycle-read.sh:257-260`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the guard order and its test; the "unquoted" clause rests on pathform's character set (no quote-forcing characters) and was not re-executed.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2 (with the invariant sentence, merged 33): "It does not cover callers outside this repo." · r3: "does not cover pathform's 'ls-tree prints the name unquoted' clause, unchanged by this diff."

Carried from r1 Claim 32. The order is at `:266-267` (Claim 30). The test's last call `MAIN_SHA=""; main_entry .gitattributes` expects `error` (`test/scripts/dev-cycle.bats:1359,1368`). Mutant E2 `guard-order` (lines swapped) makes it print `badform` and the test fails.

**Evidence:** `scripts/lib/dev-cycle-read.sh:263-268`; `$FC/logs/mut-guard-order.log`

---

## Claim 35a: "$2 is the path asked about, or "" when the skip line already names it: notfile and badform make it the subject ("$2 is not ..."; no subject when ""), ... and notdir names only the directory above it."

**Location:** `scripts/lib/dev-cycle-read.sh:281-284`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the notfile, badform and notdir arms with and without a path; does not cover the error/default arms' "" case (Claim 24b).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1 (whole comment, r1 Claim 33): "Covers every arm with a path, with "", with one argument under `set -u`, and the path's newline folding." · r2 (whole comment, r2 Claim 28): "Covers each arm with and without a path, the newline folding, and one-argument calls. It does not cover a CR, which is not folded and which no caller passes." · merge note: r3's "Claim 24b" is merged Claim 35b.

Carried from r3 Claim 24a.

```bash
# scripts/lib/dev-cycle-read.sh:286-296 (all of entry_why)
entry_why() {
  local w="${1//$'\n'/ }" p="${2-}"
  p="${p//$'\n'/ }"
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
    notfile) echo "${p:+$p is }not a regular file on the default branch" ;;
    badform) echo "${p:+$p is }not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
  esac
}
```

The entry_why test pins all ten outputs (`test/scripts/dev-cycle.bats:1338-1354`) and passed at HEAD; mutant M9 (notfile's subject made unconditional) failed it.

**Evidence:** `$S/logs/suite-head.txt`, `$S/logs/mut-M9-entry_why-subject.txt` (r3; `$S` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc3`)

---

## Claim 35b: "error and any other word end "for $2""

**Location:** `scripts/lib/dev-cycle-read.sh:283-284`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the error and default arms; does not affect any caller's output (check_brief's "" error line is the pre-branch wording).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1 (Verified, whole comment): "The comment does not say that "" also drops "for" on error and the default arm (the code does)." r1 recorded the same gap as a scope caveat. · r2 (Verified, whole comment): "It does not cover a CR, which is not folded and which no caller passes."

Carried from r3 Claim 24b. With `$2` empty these arms drop the "for" clause too: `${p:+ for $p}` (`scripts/lib/dev-cycle-read.sh:293-294`), so `entry_why error ""` prints `the tree of the default branch could not be read` (`test/scripts/dev-cycle.bats:1350`). The comment states the "" case only for notfile and badform ("no subject when \"\""). A precise version: "error and any other word end "for $2" (nothing when \"\")".

**Evidence:** `scripts/lib/dev-cycle-read.sh:281-296`, `test/scripts/dev-cycle.bats:1349-1350`

---

## Claim 35c: "A newline in either becomes a space, so the reason stays one line."

**Location:** `scripts/lib/dev-cycle-read.sh:285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both arguments' folding by code and the path's folding by test; does not establish that the word's folding is pinned by a test (it is not: Claim 11).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "The word's folding is untested (Claim 16)" (merged Claim 17); mutant `why-path-nl` fails the test. · r2: "It does not cover a CR, which is not folded and which no caller passes." · merge note: r3's "Claim 11" is merged Claim 17.

Carried from r3 Claim 25. Both expansions fold: `local w="${1//$'\n'/ }"` and `p="${p//$'\n'/ }"` (`scripts/lib/dev-cycle-read.sh:287-288`). The test's `entry_why badform "a\nok b"` expects `a ok b is not an allowed path form` (`test/scripts/dev-cycle.bats:1340-1354`); mutant M6 (path folding removed) failed it.

**Evidence:** `$S/logs/mut-M6-path-newline.txt`, `$S/logs/mut-M11-word-newline.txt` (r3; `$S` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc3`)

---

## Claim 36: No doc, help text, SKILL.md or test still quotes a main_entry refusal wording no longer printed

**Location:** `scripts/lib/dev-cycle-read.sh:281`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers scripts/, skills/, test/, docs/dev-cycle.md and the plan; does not cover docs/reviews/ artifacts, which quote old wordings as history.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r3: the search result is "paraphrased — no quote available because the claim is an absence of matches". · merge note: r2 ran the same search inside its Claim 28 prose without verdicting it as a claim; it found only `docs/working/checkpoint-build-loop-handoff.md:29`, "a pre-U2a1 checkpoint note on main that describes the then-current `error` meaning", which r2 listed under Out of scope (see Escalations E7).

Carried from r3 Claim 28. `rg` for `default branch's tree could not be read`, `no entry in it is read`, `questions.md is not read"` and `so $f is not read` outside docs/reviews/ and archive/ found no hit in a refusal context (paraphrased — no quote available because the claim is an absence of matches). The remaining "is not read" hits (`test/scripts/dev-cycle.bats:196,237,267`) are the digest's own messages, not check_answer's.

**Evidence:** `scripts/build-loop.sh:136-139`, `test/scripts/dev-cycle.bats:196`, `test/scripts/dev-cycle.bats:1327`

---

## Claim 37: entry_why reads `${2-}`, so a one-argument call works under `set -u`

**Location:** `scripts/lib/dev-cycle-read.sh:287`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one-argument calls for all five word kinds under `set -euo pipefail`; does not cover callers, which all pass two arguments.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** merge note: r1 (E5, Claim 33 Scope) and r2 (Claim 4) also ran one-argument calls at HEAD without an error, inside other claims. · r1 (Claim 33 prose): "Mutant `why-2-unbraced` (`p="$2"`) passes all 94 tests, because no caller passes one argument"; r1 Decision: "Mutant `why-2-unbraced` surviving is reported as a scope note, not a gap: no caller passes one argument."

Carried from r3 Claim 26. Under `set -euo pipefail`, `entry_why notfile` / `badform` / `error` / `"notdir docs"` / `odd` printed `[not a regular file on the default branch]`, `[not an allowed path form]`, `[the tree of the default branch could not be read]`, `[docs is not a directory on the default branch]`, `[the default branch answered odd]`, with no unbound-variable error.

**Evidence:** `$S/logs/probe.txt` (2026-10-06T16:48Z, exit 0) (r3; `$S` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc3`)

---

## Claim 38: brief_fields' "error" covers "a path pathform refuses, any main_entry answer but blob, its error included, or the blob could not be read"

**Location:** `scripts/lib/dev-cycle-read.sh:305-308`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers brief_fields' two error paths. It does not cover the odd/unbalanced paths.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r2 Claim 29. `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi` (`:316`) and `|| { BRIEF_ODD=error; return 1; }` after the cat-file pipeline (`:326`). badform is caught by the pathform check first and, failing that, by `!= blob`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:309-335`

---

## Claim 39: check_brief uses isclosed and words main_entry refusals by `entry_why "$e" ""`; check_answer ends every main_entry refusal "so no entry in $f is read"

**Location:** `scripts/lib/dev-cycle-read.sh:348`, `:358`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the notfile line through the CLI; check_brief's notdir and error lines through the CLI are untested (C9). badform is unreachable here because `:347` runs pathform first.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: "Covers check_brief's notdir/notfile/error lines against main's text and check_answer's single refusal arm at `:576`; does not cover check_brief's badform arm, which its own pathform check (`:347`) makes unreachable." r3 found the three "" lines are main's word for word ("paraphrased — no quote available because main's lines are the removed `-` lines of the diff hunk"), and its mutant M8 (check_answer's ending changed back) failed test 9.

Carried from r1 Claim 34. `if ! pathform "$a"; then echo "skip ...: not an allowed path form"; return; fi` (`:347`) runs before main_entry, so check_brief never gets badform. `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:358`) prints `skip docs/working/briefs/2026-01-01-s.md: not a regular file on the default branch`, which `test/scripts/dev-cycle.bats:1042` expects. Mutant E2 `brief-why` (passing `"$a"`) fails test 55.

**Evidence:** `scripts/lib/dev-cycle-read.sh:341-381`; `$FC/logs/mut-brief-why.log`

---

## Claim 40: SKILL.md: --check-fix prints ok for "a tracked .md file under docs/ (not ... docs/dev-cycle.md, docs/constraints.md, a dot-directory or dotfile, an instruction file, or a file an instruction file imports with @; compared ignoring case)"

**Location:** `skills/dev-cycle/SKILL.md:72-76`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the agreement with check_fix and the header; does not cover the rest of SKILL.md.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound, via r3 Claim 18)
**Replicate annotations:** r3 (Claim 18, located `scripts/dev-cycle.sh:167-169`, merged 28): "SKILL.md lists the same set, `docs/constraints.md` included." · merge note: r2's Claim 21 prose (merged 27) also quotes `skills/dev-cycle/SKILL.md:74` as matching, without verdicting it.

Carried from r1 Claim 35. The list matches the header (`scripts/dev-cycle.sh:50-55`) and the condition `:179-180`, including `"$lp" == docs/constraints.md`.

**Evidence:** `skills/dev-cycle/SKILL.md:72-76`; `scripts/dev-cycle.sh:179-182`

---

## Claim 41: bl_setup "An inherited GIT_DIR ... would send every fixture command to that repo ...; git lists every such repo-local variable itself (GIT_CONFIG_PARAMETERS too)"

**Location:** `test/lib/build-loop-fixtures.bash:11-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the variable list and the unset's effect for one test; does not cover variables git does not list (e.g. GIT_CEILING_DIRECTORIES).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Covers git 2.39.5's list and the GIT_DIR consequence. It does not cover other git versions' lists. The same applies to `test/scripts/dev-cycle.bats:11-13`" (merged 44); "The later `export GIT_CONFIG_GLOBAL=...` lines are unaffected because GIT_CONFIG_GLOBAL is not in the list." · r3: same git 2.39.5 caveat; the same unset at `test/scripts/dev-cycle.bats:13` "makes the fixture file's header 'the same hermetic git environment as test/scripts/dev-cycle.bats' (`:3`) true."

Carried from r1 Claim 36. E7 printed the list: `GIT_ALTERNATE_OBJECT_DIRECTORIES GIT_CONFIG GIT_CONFIG_PARAMETERS GIT_CONFIG_COUNT GIT_OBJECT_DIRECTORY GIT_DIR GIT_WORK_TREE ... GIT_INDEX_FILE ... GIT_COMMON_DIR`. With `GIT_DIR=/nonexistent/x`, `git rev-parse --local-env-vars` still prints 16 names, exit 0. Without the line, a victim gains 5 commits (Claim 5).

**Evidence:** `$FC/logs/c8.log`; `$FC/logs/a10c-summary.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 42: "A marker whose message body holds a NUL byte (one commit on top of base, with its tree)."

**Location:** `test/scripts/build-loop-read.bats:297`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the object the next line builds; does not cover how check_branch counts it.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover what the test then asserts." · r3: "does not cover the assertion that follows." · merge note: r3 located this sentence at `:264` and quoted `:265-266`; r1 and r2 cite `:297-298`. Clustered on the identical quoted sentence.

Carried from r1 Claim 37. `printf 'tree %s\nparent %s\n...' "$(git rev-parse "$base^{tree}")" "$base"` (`:298`) gives a commit whose parent is base and whose tree is base's.

**Evidence:** `test/scripts/build-loop-read.bats:296-301`

---

## Claim 43: The split fixture chains, with a standalone `git replace -d` (row 317)

**Location:** `test/scripts/build-loop-read.bats:436-440`, `:466-475`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the three chains row 317 named; `:84` keeps its chain (C10).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Carried from r1 Claim 38. `git replace ...` and `git config core.useReplaceRefs true` are now separate lines (`:436-437`), followed by `git replace -d "$(git rev-parse main:docs/dev-cycle.md)"` (`:440`). The `brief p ...`/`printf`/`commit_all crlf` chain and the `mkdir`/`printf`/`commit_all odd-dir` chain are now one command per line (`:466-468`, `:473-475`). E1: build-loop-read 19/19.

**Evidence:** `test/scripts/build-loop-read.bats:430-441`, `:460-480`; `$FC/logs/suite.log`

---

## Claim 44: dev-cycle.bats setup "As bl_setup: an inherited GIT_DIR would send fixture commits to that repo."

**Location:** `test/scripts/dev-cycle.bats:11-13`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers one filtered test with GIT_DIR+GIT_INDEX_FILE set; does not cover every test's side effects.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:** r2 (Claim 30, with the bl_setup comment, merged 41): "Covers git 2.39.5's list and the GIT_DIR consequence. It does not cover other git versions' lists. The same applies to `test/scripts/dev-cycle.bats:11-13`."

Carried from r1 Claim 39. Without the line, one test added 7 commits to the victim (E6), and mutant `unset-dc` fails fixture-git-env test 1 (E2). With it, fixture-git-env passes (E1).

**Evidence:** `$FC/logs/a10c-summary.log`, `$FC/logs/mut-unset-dc.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 45: test "--check-fix refuses files an instruction file imports ..." with "# docs/constraints.md is the user's (plan D2); docs/thoughts/ stays a living doc the cycle may fix."

**Location:** `test/scripts/dev-cycle.bats:1016-1032`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two new paths; does not cover docs/thoughts/ files that an instruction file imports (refused by the import arm).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3 (Claim 31, every new or changed dev-cycle.bats test against its mutant): mutant M7 (the `constraints.md` comparison removed) fails this test; "does not cover the word-folding mutant M11, which survives".

Carried from r1 Claim 40. The test expects `"skip docs/Constraints.md: in-cycle fixes edit only" "ok docs/thoughts/t.md"` (`:1029`). It passes at HEAD (E1) and fails on mutant `constraints` (E2).

**Evidence:** `$FC/logs/suite.log`, `$FC/logs/mut-constraints.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 46: test "entry_why words each main_entry refusal on one line, naming the path only when given (U2a1)"

**Location:** `test/scripts/dev-cycle.bats:1338-1354`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the path argument's folding and all arms; the word's folding survives its mutant (C9, accepted).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3 (Claim 31, located here): "Covers mutants M3-M10 (prefix guard, guard order, badform→error, path folding, constraints.md, check_answer ending, notfile subject, writable without isclosed); does not cover the word-folding mutant M11, which survives (Claim 11, an accepted Won't-Fix)."

Carried from r1 Claim 41. The test passes at HEAD and fails on `why-path-nl` (E2). `why-word-nl` survives, as row C9 says.

**Evidence:** `$FC/logs/mut-why-path-nl.log`, `$FC/logs/mut-why-word-nl.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 47: test "main_entry answers badform for a path pathform refuses, absent for a plain missing one (U1d, U2a1)" and its comment "The last line: with no main found by name, even a refused form answers error (the header's order)."

**Location:** `test/scripts/dev-cycle.bats:1356-1369`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the positive control (row 320), the badform words and the guard order; does not cover notdir/notfile (other tests).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3 (Claim 31): mutants M4 (guard order) and M5 (badform→error) each fail this test; scope caveat as in merged Claim 46.

Carried from r1 Claim 42. The test fails on `badform-error` (all six refused forms print `error`) and on `guard-order` (the last line prints `badform`) (E2). The first expected line `absent` for `x` is the positive control.

**Evidence:** `$FC/logs/mut-badform-error.log`, `$FC/logs/mut-guard-order.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 48: test "a closed brief is a closed/ path only: a brief-shaped name elsewhere is neither writable nor a brief (U2a1)"

**Location:** `test/scripts/dev-cycle.bats:1371-1378`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the prefix-guard mutant; of the three paths, only the bare `2026-01-01-x.md` distinguishes the mutant (closedx/ and docs/ are refused by both).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3 (Claim 31): mutant M3 (prefix guard) fails this test; scope caveat as in merged Claim 46. · r2 (Claim 6 prose, merged 6) records the same point: only the bare name tells the mutant apart.

Carried from r1 Claim 43. See Claim 6: the test fails on `isclosed-prefix`, with `# ok 2026-01-01-x.md` in the output.

**Evidence:** `$FC/logs/mut-isclosed-prefix.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 49a: "each suite's setup unsets every variable `git rev-parse --local-env-vars` lists. One test of each suite runs here with both pointed at a victim repo." (mechanism; with victim_unchanged "The inner run must have run one test and passed, or this proves nothing")

**Location:** `test/scripts/fixture-git-env.bats:3-6`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the setup mechanism and that each test runs exactly one inner test with both variables set. It does not cover what the check detects (31b).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (Claim 44, the whole file `:1-32`): "`"ok 1 "` also matches `not ok 1`, but a failing inner test exits nonzero, so the status check covers that case"; "does not cover running the suite through scripts/run-tests.sh itself (it writes .bats/ in the repo, which this pass may not modify)". · r3 (Claim 32): "Covers the filters, the pass at HEAD and both mutants (also commit 91469367's 'both fail with the unset lines replaced by `:`'); does not cover the suite's own hermeticity (Claim 7)" (merged 8, 15). r3: mutant M1 failed test 1 at the inner run's status; M2 failed test 2 on the victim check. · r2 Decision: "I split the fixture-git-env header into 31a (mechanism, Verified) and 31b (coverage the header implies, Mostly accurate)." · merge note: r2's "31b" is merged Claim 49b.

Carried from r2 Claim 31a. `run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' ...` (`:25`) and `-f 'exact policy line is set'` (`:30`). Each filter matches one `@test` name in its suite (`grep '^@test' | grep -c` gives 1 and 1), and `victim_unchanged` requires `*"1..1"*"ok 1 "*` with status 0 (`:19`). Both pass at HEAD.

**Evidence:** `test/scripts/fixture-git-env.bats:1-32`, `test/scripts/dev-cycle.bats:40`, `test/scripts/build-loop-read.bats:13`, `$FC/logs/suites-head.txt`

---

## Claim 49b: "The dev-cycle and build-loop suites must keep their fixtures out of a repo named by an inherited GIT_DIR or GIT_INDEX_FILE ... One test of each suite runs here with both pointed at a victim repo." (read as: this suite checks both)

**Location:** `test/scripts/fixture-git-env.bats:3-6`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers what the victim check detects. It does not cover whether any real caller inherits GIT_INDEX_FILE without GIT_DIR.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r2 Escalate: "Claim 31b, a test gap where the GIT_INDEX_FILE half of the new suite's stated purpose is unpinned. It is low-severity, because the real unset clears both variables." · r1 (Claim 44, Verified compound) and r3 (Claim 32, Verified compound) verdicted the header sentence without this reading; r1's Claim 5 Scope separately notes "a GIT_DIR-only victim (no GIT_INDEX_FILE), where the whole suite fails instead" (merged 5).

Carried from r2 Claim 31b. The check counts only commits and refs: `[ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ]` (`:20`). A mutant that unsets only `GIT_DIR` in both setups (`$FC/mut3.sh`, exit 0, 2026-10-06T16:52:33Z) passes both tests (`ok 1`, `ok 2`). Run directly against a victim, the same mutant left the victim at 1 commit but rewrote its index from 65 to 174 bytes, which then lists `docs/dev-cycle.md`. The suite pins the GIT_DIR half. The GIT_INDEX_FILE half the header names is not detected. Precise version: "keeps their fixture commits and refs out of an inherited GIT_DIR", or add an index check (for example, the victim's index is unchanged).

**Evidence:** `test/scripts/fixture-git-env.bats:17-21`, `$FC/mut3.sh`, `$FC/logs/mut-gitdironly.txt`

---

## Claim 50: "# @category fast" — the suite is picked up by scripts/run-tests.sh and by the hermeticity lint

**Location:** `test/scripts/fixture-git-env.bats:2`
**Type:** Architectural / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers discovery by both tools. It does not cover whether the suite meets the "<1s each" wording of `--fast` (the inner bats takes about 2 s).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1 (Claim 44): per-test time under 1 s ("412 ms and 466 ms", E8); "does not cover running the suite through scripts/run-tests.sh itself (it writes .bats/ in the repo, which this pass may not modify)". · r3 (Claim 33): ran `scripts/run-tests.sh --fast test/scripts/fixture-git-env.bats` in `$S/copy` (exit 0, `ok 1`, `ok 2`; `--slow` printed `No test files matched category: slow`); "does not cover a full `run-tests.sh --all` run". · merge note: r2's "about 2 s" in its Scope conflicts with r1's per-test 412/466 ms and r3's 0.964 s whole-file run (see merged Claim 51c).

Carried from r2 Claim 32. run-tests.sh discovers with `find "$TEST_DIR" -name '*.bats' -print0` with `TEST_DIR="$REPO_ROOT/test"` (`scripts/run-tests.sh:119,213`), which is recursive, and the tag is present. The lint's bash adapter uses `"test_globs": ["test/**/*.bats", "test/*.bats"]` (`scripts/hermeticity/adapters/bash.json:5`). A python `-I` replay of `discover()` gave 127 files with `test/scripts/fixture-git-env.bats` among them. `hermeticity-lint --json` reports `"bash": 127` and `"findings": []`.

**Evidence:** `scripts/run-tests.sh:119,195-213`, `scripts/hermeticity-lint:892-898`, `scripts/hermeticity/adapters/bash.json:5-6`

---

## Claim 51a: commit 91469367 body: the bullets and "Tests: dev-cycle.bats 75, build-loop-read.bats 19, fixture-git-env.bats 2, hermeticity 2: 98/98 under a TMPDIR with no dot-prefixed part. shellcheck clean. The G1 and G2 tests each fail on their mutant."

**Location:** commit 91469367 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts, the run, shellcheck over .sh/.bash, and the G1 (`:` mutant) and G2 (prefix-guard mutant) failures. It does not cover the "about 2 s" note.
**Replicate verdicts:** r1=Mostly accurate (compound; carried by 51c) · r2=Verified · r3=Verified (compound, via r3 Claims 5, 9, 32)
**Replicate annotations:** r1 (Claim 45, the whole body): "All bullets hold against the code"; its Mostly accurate rests only on the Notes timing ("Split not used: the timing is the only divergent atom and is a Notes aside"), so per decision 033 it is recorded here but does not set this sub-claim's verdict. · r3: Claim 9's Scope covers "commit 91469367's 'Tests: ... 98/98 ... shellcheck clean'", Claim 5's covers "dropping isclosed's prefix guard made --check-write print ok for 2026-01-01-x.md", and Claim 32's covers "both fail with the unset lines replaced by `:`"; r3's .bats shellcheck caveat (two info-level SC2015 notes in fixture-git-env.bats) as in merged Claim 10.

Carried from r2 Claim 34. See Claims 5, 6 and 10: 98 ok at d07cc89c (same code), counts 75/19/2/2, shellcheck exit 0, `mut-unsetboth` 2 not ok, and `mut-isclosed-prefix` 1 not ok. The message's other bullets ("New test: ... dropping isclosed's prefix guard made --check-write print ok for 2026-01-01-x.md"; "both fail with the unset lines replaced by `:`") are the same facts.

**Evidence:** `$FC/logs/suites-head.txt`, `$FC/logs/mut-unsetboth.txt`, `$FC/logs/mut-isclosed-prefix.txt` (r2; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc2`)

---

## Claim 51b: commit 91469367 body: "entry_why's comment states each word's use of $2 (subject, \"for $2\", or unused for notdir), and reads it as ${2-} like the lib's other optional arguments"

**Location:** commit 91469367 message
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the comment and the expansion form. It does not cover behaviour, because both forms are unset-safe.
**Replicate verdicts:** r1=Mostly accurate (compound; carried by 51c) · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "History only." · r3: "The `-` form matches the lib's associative-array reads (`${m[$1]-}`, `${BRIEF[status]-}`), not its optional arguments. Commit message: immutable history." r3 Scope: "does not affect behaviour (both forms are set -u safe and default to "")". · r1 (Claim 45): "All bullets hold against the code"; r1's compound Mostly accurate rests only on the Notes timing (51c).

Carried from r2 Claim 35. The comment part holds (Claim 28). The lib's other optional arguments are read as `${2:-}`, not `${2-}`: `"${2:-file}"` (`scripts/lib/dev-cycle-read.sh:125`) and `"${2:-}" == glob` (`:142`). entry_why's `${2-}` (`:287`) is a sibling form. It behaves the same here, because an empty `p` gives no subject either way. Precise version: "reads it unset-safe, as the lib's other optional arguments do".

**Evidence:** `scripts/lib/dev-cycle-read.sh:125,142,287`

---

## Claim 51c: commit 91469367 Notes "the G1 suite runs bats inside bats (about 2 s)"

**Location:** commit 91469367 message
**Type:** Reference / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers every bullet, the counts and the mutants (all hold) and the Notes timing (does not hold here). Split not used: the timing is the only divergent atom and is a Notes aside.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=— · r3=Verified
**Replicate annotations:** r3 (Verified, Medium): "Covers the order of magnitude; does not fix the host-dependent figure." r3 measured `real 0m0.964s` for the whole file, "about a second, under the stated ~2 s and the same order"; r3 Decision: graded the "about 2 s" timing Verified on order of magnitude because it is marked approximate. · r2 did not verdict this sentence; its Claim 32 Scope itself states "the inner bats takes about 2 s" (merged 50), and its Claim 34 Scope excludes the note. · r1: "Commit history: no fix is possible, so an Accepted-immutable row fits."

Carried from r1 Claim 45. All bullets hold against the code (Claims 3, 7, 32, 33, 43, 44). The counts are 75+19+2+2 = 98 (E1), shellcheck is clean (E10), and G1/G2 fail on their mutants (E2). The Notes' "about 2 s" does not match E8 here: the whole fixture-git-env file ran in 0.71 s and 0.73 s wall (412 ms + 466 ms per test). The figure is host-dependent and roughly 3× high on this host. Commit history: no fix is possible, so an Accepted-immutable row fits.

**Evidence:** `git log -1 91469367`; `$FC/logs/fge-wall.log`, `$FC/logs/fge-timing.log` (r1; `$FC` is `/home/node/.claude/jobs/814a541d/tmp/review-u2a1-i3/fc1`)

---

## Claim 52a: commit d07cc89c "0 Must Fix, 0 Incorrect (53 merged claims, 88.7% replicate agreement)"

**Location:** commit d07cc89c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the figures and row counts; does not re-judge the merge decision.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound, via r3 Claim 2)
**Replicate annotations:** r2 (Claim 36, with the "found ..." sentence, merged 52b): "Covers agreement with the rubric and the merged report. It does not re-verdict the merged report's claims." r2: no rubric row is Must Fix ("paraphrased — no quote available because this is the absence of a severity across the table at `:18-31`"). · r3 (Claim 2, located at the rubric's `:11`, merged 2): its Scope names this commit sentence; "does not re-derive the per-cluster agreement or re-verdict that report's claims".

Carried from r1 Claim 46a. The figures match the merged report (Claim 2). Override-log rows `:327-330` are C7-C10. The merged report's Decisions bullet says it recorded those two verdicts `as (compound; carried by …)` and did not let them set the sub-claim's verdict.

**Evidence:** `docs/reviews/override-log.md:327-330`; merged report :1143 at d07cc89c

---

## Claim 52b: commit d07cc89c "found an iteration-1 regression in wording (A7: entry_why's path argument), two Medium test gaps (A10, A11; executed) and wording items, fixed in 91469367"

**Location:** commit d07cc89c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the commit's summary against the rubric rows; the gaps themselves are Claims 4 and 5.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2 (Claim 36): "It does not re-verdict the merged report's claims." r2: "A7-A13 are marked fixed in 91469367." · merge note: r3's "Claims 4 and 5" are merged Claims 5 and 6.

Carried from r3 Claim 38. The rubric rows read `| A7 | After A4, entry_why's `$2` plays a different role per word` (Minor), `| A10 | ... | Medium (test gap) |` and `| A11 | ... | Medium (test gap; executed) |` (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20,23,24`).

**Evidence:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:20-24`

---

## Claim 52c: commit d07cc89c "Four declined findings get override rows (C7-C10)"

**Location:** commit d07cc89c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the rows' existence and decisions; does not re-verdict each row (Claims 7, 8, 10, 11, 12).
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate (compound; carried by 52d) · r3=Verified (compound)
**Replicate annotations:** r2 (Claim 37): "It does not cover the Accepted-immutable row added beside them (`:326`), which the sentence does not count." r2's Mostly accurate and its precise version concern only the C4 timing clause (52d), so per decision 033 it is recorded here but does not set this sub-claim's verdict. · merge note: r3's "Claims 7, 8, 10, 11, 12" are merged Claims 8/15, 9/13, 16, 17 and 18.

Carried from r3 Claim 36. Rows `docs/reviews/override-log.md:327-330` are C7 (Defer), C8 (Won't-Fix), C9 (Won't-Fix) and C10 (Defer), matching the rubric's statuses (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27-30`). The C4 row now reads `0.3-0.5 ms, by host` and `~17-37 µs` with `figures re-measured in iteration 2` (`:325`).

**Evidence:** `docs/reviews/override-log.md:325-330`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27-31`

---

## Claim 52d: commit d07cc89c "the C4 row's timings are corrected to the re-measured range"

**Location:** commit d07cc89c message
**Type:** Reference / Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Same finding as Claims 8 and 12, as stated in the commit; does not establish other hosts' timings.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound)
**Replicate annotations:** r2 (Claim 37): "The row's range is the union with iteration 1's ~0.3 ms / ~17 µs figures, and its 0.5 ms top is below the 0.52 ms that was measured. Precise version: 'widened to cover iteration 1's and iteration 2's measurements'. The difference changes no conclusion." "History only." r2 Decision: "I graded the C4 row's correction Mostly accurate rather than Verified because the row is not the re-measured range the commit names." · r3 (Claim 36, Verified compound; and Claim 8 prose): the row's figures match the iteration-2 merged report's measured range (`~0.4-0.5 ms per entry_why subshell and ~18-37 µs per pair`, `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1106` at d07cc89c), "which d07cc89c's 'the C4 row's timings are corrected to the re-measured range' claims"; r3 Decision: Verified on order of magnitude. · r1 Escalate: one timing-wording item with merged 9 and 13. · merge note: r1's "Claims 8 and 12" are merged Claims 9 and 13.

Carried from r1 Claim 46b. The row now says `0.3-0.5 ms, by host` and `~17-37 µs` (`docs/reviews/override-log.md:325`), while the rubric's re-measured range is `0.42-0.52 ms, 18-37 µs` (rubric `:31`). The row's range spans iteration 1 and iteration 2 rather than the re-measured range. The figures I measured, 0.48-0.54 ms and 19-21 µs, sit near its top. Commit history: no fix possible.

**Evidence:** `docs/reviews/override-log.md:325`; `$FC/logs/timing.log`

---

## Claim 52e: commit d07cc89c Notes "The merge kept claims 21b and 41a Verified where a replicate's compound verdict blamed only the sibling part (decision 033), as the merged report records."

**Location:** commit d07cc89c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the merged report's record of it; does not re-verdict claims 21b and 41a.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1 (Claim 46a): "The merged report's Decisions bullet says it recorded those two verdicts `as (compound; carried by …)` and did not let them set the sub-claim's verdict"; "does not re-judge the merge decision".

Carried from r3 Claim 37. The merged report says `Claims 21b and 41a disagree only through a sibling's compound verdict` (`docs/reviews/code-fact-check-report-build-loop-u2a1.md:1135`).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a1.md:1135` (at d07cc89c)

---

## Submitted Claims

## Claim 53: "Every current consumer of main_entry (check_brief, check_answer, build-loop.sh main_file; brief_fields) refuses on every word other than `blob` and `absent` at d07cc89c, including `badform`."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:354-359`, `scripts/lib/dev-cycle-read.sh:573-577`, `scripts/build-loop.sh:129-134`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four call sites of `main_entry` in `scripts/` at d07cc89c and their handling of the words blob, absent, badform, notfile, `notdir docs/working`, error, an unknown word, an empty word and a word with a space; does not establish what `main_entry` itself answers for a given tree (that is Claims 57 and 62), and brief_fields refuses `absent` as well (it accepts only `blob`), which the claim does not contradict.

The consumer set is complete: `git grep` for `main_entry` outside comments finds only `scripts/lib/dev-cycle-read.sh:316` (brief_fields), `:354` (check_brief), `:572` (check_answer) and `scripts/build-loop.sh:129` (main_file) (paraphrased — no quote available because the claim covers absence of other call sites; repo-wide grep result). Each has a catch-all refusal:

```bash
# scripts/lib/dev-cycle-read.sh:354-359 (check_brief; enclosing function :343-380 — read)
  e="$(main_entry "$a")"
  case "$e" in
    absent) echo "ok $a new"; return ;;
    blob) ;;
    *) echo "skip $a: $(entry_why "$e" "")"; return ;;
  esac
```

```bash
# scripts/lib/dev-cycle-read.sh:572-577 (check_answer; enclosing function :567-593 — read)
    e="$(main_entry "$f")"
    case "$e" in
      absent) continue ;;
      blob) ;;
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
    esac
```

```bash
# scripts/build-loop.sh:129-134 (main_file; enclosing function :126-141 — read)
  e="$(main_entry "$f")"
  case "$e" in
    blob) ;;
    absent) FILE_WHY=absent; return 1 ;;
    *) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;
  esac
```

`scripts/lib/dev-cycle-read.sh:316` (brief_fields): `if ! pathform "$1" || [[ "$(main_entry "$1")" != blob ]]; then BRIEF_ODD=error; return 1; fi`.

Executed: `p53.sh` sources the d07cc89c lib, evals `main_file` out of the d07cc89c `build-loop.sh`, stubs `main_entry` to print each word in turn, and calls all four consumers in a fixture repo. For every word but blob/absent, check_brief and check_answer print a `skip` line, main_file returns 1 with a reason, and brief_fields returns 1 with `BRIEF_ODD=error`; badform gives `skip docs/working/briefs/2026-01-01-c.md: not an allowed path form`. For `absent`, check_brief prints `ok ... new`, check_answer moves on to the next file, main_file sets `FILE_WHY=absent`.

Command: `timeout 60 bash p53.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh c-d07cc89c/scripts/build-loop.sh fx53`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:18:01Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:316`, `scripts/lib/dev-cycle-read.sh:354-359`, `scripts/lib/dev-cycle-read.sh:572-577`, `scripts/build-loop.sh:129-134`, docs/reviews/execution-logs/u2a1-s25/c53-consumers-stubbed.txt

---

## Claim 54: "Of 11 path candidates (`closed/../`, `closed//`, `closed/closed/`, a subdirectory, a newline suffix, `Closed/`, an uppercase slug, a trailing `/`, a leading `./`, a short date, and the plain path), isclosed and writable accept only `docs/working/briefs/closed/2026-01-01-x.md` (plain shape)."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:157-162`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers exactly the 11 named candidate shapes (each built on `docs/working/briefs/closed/2026-01-01-x.md`) against `isclosed` and `writable` at d07cc89c; does not establish behaviour for shapes outside that list (other Unicode case folds, other slugs), nor that callers reach `writable`/`isclosed` only after `pathform`.

```bash
# scripts/lib/dev-cycle-read.sh:157-162
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
writable() {
  [[ "$1" =~ ^docs/roadmap\.md$|^docs/working/(questions|questions-archive|idea-log)\.md$ \
    || "$1" =~ ^docs/working/cycles/cycle-$DIGIT{4}-$DIGIT{2}-$DIGIT{2}\.md$ ]] || isbrief "$1" || isclosed "$1"
}
```

Executed (`p54.sh`): ten candidates print `isclosed=refuse writable=refuse`; only `docs/working/briefs/closed/2026-01-01-x.md` prints `isclosed=accept writable=accept`. The newline-suffixed candidate was built with `$'...\n'` and is shown `%q`-quoted in the log.

Command: `timeout 30 bash p54.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:17:36Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:157-162`, docs/reviews/execution-logs/u2a1-s25/c54-isclosed-writable.txt

---

## Claim 55: "After 91469367, check_answer has one catch-all refusal arm for every main_entry word but blob/absent, and no caller branches on a specific refusal word, so a new word needs one edit (entry_why)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:574-577`, `scripts/lib/dev-cycle-read.sh:356-359`, `scripts/build-loop.sh:130-134`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four main_entry consumers' case arms at d07cc89c and the 91469367 fold of check_answer's two arms into one; does not establish that a new word needs no edit in `main_entry` itself (which must emit it) or in its header comment, and a word with no `entry_why` arm is already refused and worded by `entry_why`'s default arm, so the one edit is needed only for a dedicated wording.

`git diff d48f4645 91469367 -- scripts/` shows check_answer's `notdir\ *)` arm and `*)` arm replaced by one arm:

```bash
# scripts/lib/dev-cycle-read.sh:576
      *) echo "skip $a: $(entry_why "$e" "$f"), so no entry in $f is read"; return ;;
```

check_brief (`:358`, `*) echo "skip $a: $(entry_why "$e" "")"; return ;;`) and main_file (`scripts/build-loop.sh:133`, `*) FILE_WHY="$(entry_why "$e" "$f")"; return 1 ;;`) likewise name only `blob` and `absent`; brief_fields (`:316`) tests only `!= blob`. No other script code compares a main_entry word (paraphrased — no quote available because the claim covers absence: `git grep` for `main_entry` in `scripts/` finds only these four call sites). The only `FILE_WHY` comparisons in build-loop.sh are to `absent` (`scripts/build-loop.sh:214`, `:217`, `:264`). Wording lives in one function:

```bash
# scripts/lib/dev-cycle-read.sh:289-295 (entry_why, enclosing :286-296 — read)
  case "$w" in
    notdir\ *) echo "${w#notdir } is not a directory on the default branch" ;;
    notfile) echo "${p:+$p is }not a regular file on the default branch" ;;
    badform) echo "${p:+$p is }not an allowed path form" ;;
    error) echo "the tree of the default branch could not be read${p:+ for $p}" ;;
    *) echo "the default branch answered $w${p:+ for $p}" ;;
  esac
```

Executed: the Claim 53 probe fed the unlisted words `odd` and `weird word` to every consumer; all four refused, worded by the default arm (`the default branch answered weird word for docs/working/questions.md`), with no consumer edit.

Command: as Claim 53 (`p53.sh`); cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:18:01Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-296`, `scripts/lib/dev-cycle-read.sh:316`, `scripts/lib/dev-cycle-read.sh:356-359`, `scripts/lib/dev-cycle-read.sh:574-577`, `scripts/build-loop.sh:130-134`, `scripts/build-loop.sh:214-217`, docs/reviews/execution-logs/u2a1-s25/c53-consumers-stubbed.txt

---

## Claim 56a: "Dependency direction is unchanged: no lib-to-script call, and entry_why [uses] no git and no globals" (and isclosed uses no git)

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:286-295`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers references from the lib to functions defined only in `scripts/dev-cycle.sh` or `scripts/build-loop.sh`, at d07cc89c and at 900c47d0, plus the bodies of `entry_why` and `isclosed` (with `isbrief`); does not cover the lib's documented reliance on the caller setting `ROOT_REAL` (a variable contract, not a call), which is unchanged.

Executed (`p56.sh`): for every function defined in either script, grep the lib for the name outside column-0 comments. At both commits, the only hits are two indented comment lines (`:417`/`:401` "the exact ref", `:461`/`:445` "matches INSTRUCTION_FILE's names"). Neither script's name appears in lib code. Function bodies, as `declare -f` printed them (`p56b.sh`):

```bash
# scripts/lib/dev-cycle-read.sh:286-288 (entry_why)
entry_why() {
  local w="${1//$'\n'/ }" p="${2-}"
  p="${p//$'\n'/ }"
```

entry_why reads only `$1`, `$2` and its locals `w` and `p` (the rest of its body is the case statement quoted in Claim 55). Neither entry_why nor isclosed/isbrief contains a `git` call (`scripts/lib/dev-cycle-read.sh:157-158`, quoted in Claim 54).

Commands: `timeout 30 bash p56.sh c-<sha>` for d07cc89c and 900c47d0 (exit 0, 2026-10-06T17:19:27Z); `timeout 30 bash p56b.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh` (exit 0, 2026-10-06T17:19:37Z); cwd `/workspace/.claude/wt-build-loop-u2a1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:157-158`, `scripts/lib/dev-cycle-read.sh:286-296`, docs/reviews/execution-logs/u2a1-s25/c56-lib-to-script.txt, docs/reviews/execution-logs/u2a1-s25/c56-isclosed-globals.txt

---

## Claim 56b: "isclosed use[s] no git and no globals"

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:158`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers isclosed's own body and its one callee, isbrief; does not establish anything about mutable state beyond the two constants named.

isclosed names no global itself, but its callee reads two lib-level globals:

```bash
# scripts/lib/dev-cycle-read.sh:155-158
DIGIT='[0123456789]'
SLUG='[abcdefghijklmnopqrstuvwxyz0123456789-]+'
isbrief() { [[ "$1" =~ ^docs/working/briefs/$DIGIT{4}-$DIGIT{2}-$DIGIT{2}-$SLUG\.md$ ]]; }
isclosed() { [[ "$1" == docs/working/briefs/closed/* ]] && isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }
```

Executed (`p56b.sh`): with the default globals, `isclosed docs/working/briefs/closed/2026-01-01-x.md` accepts. After `SLUG='[q]+'` the same call refuses, so isclosed's answer depends on a global. The claim's point holds: no git, and no runtime state such as `MAIN_SHA` or `ROOT_REAL`. A precise version: "isclosed runs no git and reads only the lib's constant patterns DIGIT and SLUG, through isbrief".

Command: `timeout 30 bash p56b.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:19:37Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:155-158`, docs/reviews/execution-logs/u2a1-s25/c56-isclosed-globals.txt

---

## Claim 57: "main_entry's comment states the guard order (main_by_name, then pathform) and that every word but blob/absent is a refusal, and the code matches."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:257-260`, `scripts/lib/dev-cycle-read.sh:267-268`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the header sentences on guard order and on refusal words, and main_entry's two guards and its output words; that consumers treat the words as refusals is Claim 53. Does not establish the header's other statements (the duplicate-name and ls-tree-failure meanings of `error`).

```bash
# scripts/lib/dev-cycle-read.sh:256-260 (comment)
# check saw, so this answers error instead). Only blob reads the file, and only
# absent means there is none: every other word is a refusal. It runs
# main_by_name, then pathform, itself, before any read (so with no default
# branch even a refused form answers error; pathform also means ls-tree prints
# the name unquoted). entry_why words the refusals. One ls-tree call lists the
```

```bash
# scripts/lib/dev-cycle-read.sh:266-267 (main_entry, enclosing :263-280 — read)
  if ! main_by_name; then echo error; return; fi
  if ! pathform "$1"; then echo badform; return; fi
```

The cited `:267-268` is off by one: the guards are at `:266-267`, and `:268` is the `want` loop. main_entry's remaining outputs are `error`, `absent`, `notdir $p`, `blob` and `notfile` (`:269-279`). Executed: test 74 (`main_entry answers badform ...`) passes at d07cc89c, and its last line checks the order (`MAIN_SHA=""; main_entry .gitattributes` answers `error`). With the guards swapped (mutant M2, Claim 67), the same line answers `badform` and the test fails.

Command: `cd c-d07cc89c && timeout 300 bats -f 'main_entry answers badform for a path pathform refuses' test/scripts/dev-cycle.bats`; exit 0; 2026-10-06T17:18:54Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:248-280`, `test/scripts/dev-cycle.bats:1356-1369`, docs/reviews/execution-logs/u2a1-s25/c67-mutants.txt

---

## Claim 58: "isclosed is the single spelling of the closed/ rule across writable, check_brief and shared_branches, and its prefix guard is pinned by a test (dropping it fails a test)."

**Submitted by:** architecture-review
**Location:** `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:161`, `scripts/lib/dev-cycle-read.sh:348`, `scripts/build-loop.sh:318`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers code under `scripts/` at d07cc89c (comments and message text excluded) and the prefix-guard mutant; does not establish that docs restating the closed/ rule (the check_brief message text `docs/working/briefs/[closed/]YYYY-MM-DD-<slug>.md`, `:349`) stay in step.

The three uses call isclosed: `:161` (`... || isbrief "$1" || isclosed "$1"`), `:348` (`if ! isbrief "$a" && ! isclosed "$a"; then`) and `scripts/build-loop.sh:318` (`if ! { isbrief "$f" || isclosed "$f"; } || ! brief_fields "$f"; then continue; fi`). `rg -n closed scripts/` with comment lines excluded finds no other closed/ path rule. The other hits are "failing closed" in self-improvement.sh, the `never closed` fence messages, and the check_brief message text (paraphrased — no quote available because the claim covers absence of other spellings; grep result). The diff from 900c47d0 removes the two earlier spellings: the closed/ regex in writable and check_brief, and `${f/#docs\/working\/briefs\/closed\//docs/working/briefs/}` in shared_branches.

Executed: mutant M1 (on a copy) drops the guard, leaving `isclosed() { isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }`. Test 75 (`a closed brief is a closed/ path only ...`) then fails because `--check-write 2026-01-01-x.md` answers `ok 2026-01-01-x.md`. The unmutated copy passes it.

Command: `cd m67a && timeout 300 bats -f 'a closed brief is a closed/ path only' test/scripts/dev-cycle.bats`; exit 1 (control on c-d07cc89c: exit 0); 2026-10-06T17:18:54Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:161`, `scripts/lib/dev-cycle-read.sh:348`, `scripts/build-loop.sh:318`, `test/scripts/dev-cycle.bats:1371-1378`, docs/reviews/execution-logs/u2a1-s25/c67-mutant-diffs.txt, docs/reviews/execution-logs/u2a1-s25/c67-mutants.txt

---

## Claim 59: "fixture-git-env.bats fails loudly if a filtered test is renamed (it requires `1..1` and `ok 1`), so its name coupling to the two suites cannot pass vacuously."

**Submitted by:** architecture-review
**Location:** `test/scripts/fixture-git-env.bats:17-20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers renaming either target test so that its `-f` filter matches nothing; does not establish failure when a filter matches 10-19 tests, since the glob `*"1..1"*"ok 1 "*` also matches `1..10`-`1..19` output whose first test passes (no current filter is close to that; Claim 64).

```bash
# test/scripts/fixture-git-env.bats:17-22 (victim_unchanged, whole function)
victim_unchanged() {
    # The inner run must have run one test and passed, or this proves nothing.
    [ "$status" -eq 0 ] && [[ "$output" == *"1..1"*"ok 1 "* ]] || { echo "$output"; return 1; }
    [ "$(git -C "$V" rev-list --all --count)" = 1 ] && [ "$(git -C "$V" for-each-ref --format=x | wc -l)" = 1 ] \
        || { git -C "$V" log --all --oneline | head; git -C "$V" for-each-ref; return 1; }
}
```

Executed on copies: `m59a` renames dev-cycle.bats's `prints all eight sections in a repo with no docs`, and `m59b` renames build-loop-read.bats's `--settings: an exact policy line is set, a trailing CR included (T1)`. In each, the matching fixture-git-env test fails at line 19, with the inner output `1..0` echoed, and the suite exits 1. The other test still passes. The unmutated copy passes both (exit 0).

Command: `cd <copy> && timeout 300 bats test/scripts/fixture-git-env.bats` for c-d07cc89c, m59a and m59b; exit 0 / 1 / 1; 2026-10-06T17:18:40Z.

**Evidence:** `test/scripts/fixture-git-env.bats:17-32`, docs/reviews/execution-logs/u2a1-s25/c59-rename-target.txt

---

## Claim 60: "No script or doc outside test/ and docs/reviews/ parses or quotes a main_entry refusal reason (entry_why output)."

**Submitted by:** api-consistency-reviewer
**Location:** repo-wide; the reason is produced at scripts/lib/dev-cycle-read.sh:286 and spliced at scripts/build-loop.sh:133
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers tracked files at d07cc89c outside `test/` and `docs/reviews/`, searched for each `entry_why` reason phrase, the old pre-U2a1 wording, and `entry_why`/`FILE_WHY` uses; does not cover consumers outside this repo that might read the scripts' printed lines, and build-loop.sh does relay the reason unparsed inside its own output lines (`never malformed: $why`, `constraints unreadable: $FILE_WHY`).

Executed `git grep -F` at d07cc89c (excluding `test/` and `docs/reviews/`) for each reason phrase: "is not a directory on the default branch", "not a regular file on the default branch", "tree of the default branch could not be read" and "default branch answered" match only entry_why's own lines (`scripts/lib/dev-cycle-read.sh:290-294`). "not an allowed path form" also matches the separate pathform skip messages at `scripts/dev-cycle.sh:146,152,162,173` and `scripts/lib/dev-cycle-read.sh:347`, which are the scripts' own messages and not entry_why output. The old wordings ("default branch's tree", "could not be read for") and the relayed prefixes ("never malformed", "constraints unreadable") appear in no doc or skill. The only non-script `entry_why` hit is a plan bullet naming the function (`docs/working/plan-build-loop-handoff.md:274`), not a reason. build-loop.sh compares `FILE_WHY` only to `absent`:

```bash
# scripts/build-loop.sh:214
    [[ "$FILE_WHY" == absent ]] && why="no $f on the default branch" || why="$FILE_WHY"
```

and interpolates the reason unparsed (`scripts/build-loop.sh:217`, `:265`). In the docs-search log the `exit=` lines are `cut`'s status; empty match lists there mean no hits.

Commands: `git grep -n -F '<phrase>' d07cc89c -- . ':!test/' ':!docs/reviews/'` (and a second set also excluding `scripts/`); cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:19:04Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:290-294`, `scripts/build-loop.sh:214-217`, `scripts/build-loop.sh:264-265`, docs/reviews/execution-logs/u2a1-s25/c60-reason-grep.txt, docs/reviews/execution-logs/u2a1-s25/c60-reason-grep-docs.txt

---

## Claim 61: "`${2-}` and `${2:-}` produce the same value of p for every argument list entry_why can receive."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286-288`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the default-value expansion for every arity (unset, set-empty, set-nonempty $2), with and without `set -u`; does not establish anything about the newline replacement on the next line, which is the same for both spellings.

```bash
# scripts/lib/dev-cycle-read.sh:287-288
  local w="${1//$'\n'/ }" p="${2-}"
  p="${p//$'\n'/ }"
```

The two forms differ only when the parameter is set but empty: `${2-}` gives the empty value and `${2:-}` gives the default. Here the default is also empty, so the results are the same. Executed (`p61.sh`): with 0, 1, 2 (empty, nonempty, newline) and 3 arguments, and again under `set -u`, every case prints `same`.

Command: `timeout 30 bash p61.sh`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:17:36Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-288`, docs/reviews/execution-logs/u2a1-s25/c61-param-expansion.txt

---

## Claim 62: "check_brief's notdir, notfile and error skip lines at d07cc89c are byte-identical to main's (900c47d0)."

**Submitted by:** api-consistency-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:354-359`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers check_brief's skip lines for one real notdir case (`docs/working/briefs/closed` stored as a symlink), one notfile case (a brief stored as a symlink) and error (forced by an unreadable `MAIN_SHA`), from the same fixture under both libs; does not cover check_answer or main_file (whose wording did change on purpose), nor the badform line, which is new.

At 900c47d0, check_brief spelled the three lines inline (`notdir\ *) echo "skip $a: ${e#notdir } is not a directory on the default branch"`; `error) echo "skip $a: the tree of the default branch could not be read"`; `*) echo "skip $a: not a regular file on the default branch"`, per `git diff 900c47d0 d07cc89c`). At d07cc89c it uses `*) echo "skip $a: $(entry_why "$e" "")"; return ;;` (`:358`), and with an empty `$2` entry_why's `${p:+...}` parts drop out. Executed (`p62.sh`) on the fixture from `fixture.sh`, under each copy's lib: the outputs (main_entry words plus the three skip lines) are the same in full (`diff` is empty and `cmp` reports the files identical), e.g. `skip docs/working/briefs/2026-01-01-b.md: not a regular file on the default branch`.

Command: `timeout 30 bash p62.sh c-<sha>/scripts/lib/dev-cycle-read.sh fx53` for d07cc89c and 900c47d0; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0 both; 2026-10-06T17:18:10Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:343-380`, docs/reviews/execution-logs/u2a1-s25/c62-check-brief-d07cc89c.txt, docs/reviews/execution-logs/u2a1-s25/c62-check-brief-900c47d0.txt

---

## Claim 63: "badform is answered before any git call, so a refused path form costs no ls-tree fork."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:267-268`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git invocations made inside main_entry for refused forms when main is found by name; does not count the `$(main_entry ...)` command-substitution subshell the callers make in any case, and does not cover callers' own earlier pathform checks.

The guards (`:266-267`, quoted in Claim 57) come before the only git call, `:269` `out="$(git ls-tree -t --full-tree "$MAIN_SHA" -- "${want[@]}" "$1" 2>/dev/null)"`. `main_by_name` (`:247`) is a pure `[[ ... ]]` test. Executed (`p63.sh`): with a logging `git` shell function, main_entry makes 0 git calls for `.gitattributes`, `../x`, `docs//x.md`, `-x` and `.github/x.yml` (all `badform`). The plain-path control makes 1 call (`git ls-tree ...`).

Command: `timeout 30 bash p63.sh c-d07cc89c/scripts/lib/dev-cycle-read.sh fx53 gitlog`; cwd `/workspace/.claude/wt-build-loop-u2a1`; exit 0; 2026-10-06T17:18:17Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:247`, `scripts/lib/dev-cycle-read.sh:263-280`, docs/reviews/execution-logs/u2a1-s25/c63-git-calls.txt

---

## Claim 64: "Each fixture-git-env `-f` filter selects exactly one test of its target suite."

**Submitted by:** performance-reviewer
**Location:** `test/scripts/fixture-git-env.bats:24-32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two filters against the suites at d07cc89c; does not establish that future test names will not also match (`exact policy line is set` is unanchored).

```bash
# test/scripts/fixture-git-env.bats:25, :30
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f '^prints all eight sections' "$REPO_ROOT/test/scripts/dev-cycle.bats"
    run env GIT_DIR="$V/.git" GIT_INDEX_FILE="$V/.git/index" bats -f 'exact policy line is set' "$REPO_ROOT/test/scripts/build-loop-read.bats"
```

Executed: `bats --count -f` prints `1` for each filter. The matching tests are `test/scripts/dev-cycle.bats:40` and `test/scripts/build-loop-read.bats:13`.

Command: `timeout 60 bats --count -f '<filter>' c-d07cc89c/test/scripts/<suite>`; exit 0 both; 2026-10-06T17:18:23Z.

**Evidence:** `test/scripts/fixture-git-env.bats:24-32`, docs/reviews/execution-logs/u2a1-s25/c64-filter-counts.txt

---

## Claim 65: "Iteration 2's changes (91469367) leave dev-cycle.bats and build-loop-read.bats wall time within run-to-run noise of d48f4645 (time both, alternating, ≥3 runs each)."

**Submitted by:** performance-reviewer
**Location:** test/scripts/dev-cycle.bats:1, test/scripts/build-loop-read.bats:1 (whole suites)
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whole-suite wall time on this 16-core host, 3 alternating runs per commit per suite, from `git archive` copies of d48f4645 and d07cc89c (whose scripts and these suites match 91469367's; d07cc89c adds only docs); does not separate script cost from test-count change (dev-cycle.bats has 74 tests at d48f4645 and 75 at d07cc89c) and is too few runs for a statistical test.

Executed (`p65.sh`, order d48f4645 then d07cc89c, repeated three times per suite; every run exit 0 with 0 failures):

| suite | d48f4645 runs (s) | d07cc89c runs (s) | median d48 / d07 |
|---|---|---|---|
| dev-cycle.bats | 18.60, 18.30, 15.29 | 15.53, 18.46, 18.39 | 18.30 / 18.39 |
| build-loop-read.bats | 9.17, 9.11, 9.03 | 9.11, 11.80, 9.11 | 9.11 / 9.11 |

The two commits' ranges overlap in both suites. Within each commit, run-to-run spread is about 3.3 s on dev-cycle.bats, and that is larger than the gap between the medians (0.09 s). The one high build-loop-read run (11.80 s) sits between two 9.11 s runs at the same commit (paraphrased — no quote available because the claim is about measured timings, not code).

Command: `timeout 3000 bash p65.sh /tmp/u2a1s25-5CMy` (each bats run under `timeout 600`); cwd `/workspace/.claude/wt-build-loop-u2a1` (runs cd into each copy); exit 0; started 2026-10-06T17:20:34Z.

**Evidence:** `docs/reviews/execution-logs/u2a1-s25/c65-timing.txt`

---

## Claim 66: "Iteration 2's script changes add no fork on any path: entry_why gains one in-function parameter expansion; check_answer's folded arm still makes one `$(entry_why …)` call before `return`."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:286-296`, `scripts/lib/dev-cycle-read.sh:567-580`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `git diff d48f4645 91469367 -- scripts/` (lib and dev-cycle.sh); does not cover forks added by earlier U2a1 commits (6f624cdf moved check_brief and main_file to `$(entry_why ...)`), which are outside iteration 2.

The iteration-2 script diff has three code changes. (1) entry_why's `local ... p="${2//$'\n'/ }"` becomes `local ... p="${2-}"` plus `p="${p//$'\n'/ }"` (`:287-288`): one extra builtin assignment with parameter expansion, and no command substitution or external command. (2) check_answer's two refusal arms, each `echo "skip $a: $(entry_why "$e" "$f"), ..."; return`, become the single `:576` arm with the same one `$(entry_why ...)` before `return`. (3) The rest is comment-only (lib header and main_entry header; `scripts/dev-cycle.sh:167` changes "message" to "messages" in a comment). The rest of check_answer (`:567-593`) was read in full and is unchanged by 91469367 (paraphrased — no quote available because the claim is about a diff; the full diff was read and is summarised above).

**Evidence:** `scripts/lib/dev-cycle-read.sh:286-296`, `scripts/lib/dev-cycle-read.sh:567-593`, `scripts/dev-cycle.sh:167-168`

---

## Claim 67: "Mutant M1 (drop isclosed's `closed/*` guard) fails the new closed-brief test; mutant M2 (swap main_entry's two guards) fails the badform/guard-order test."

**Submitted by:** test-strategy
**Location:** `test/scripts/dev-cycle.bats:1356-1378` (tests 74, 75)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two named mutants against tests 74 and 75 (run by `-f` filter), each mutant made on its own `git archive` copy with the unmutated copy as control; does not establish that other tests in the suite also catch them, or that each test catches only its own mutant (the cross results are recorded: M1 passes test 74, and M2 passes test 75).

Mutant diffs (captured): M1 changes `:158` to `isclosed() { isbrief "docs/working/briefs/${1#docs/working/briefs/closed/}"; }`, and M2 swaps `:266` and `:267`. Results:

| copy | test 75 (closed brief) | test 74 (badform / order) |
|---|---|---|
| c-d07cc89c (control) | ok (exit 0) | ok (exit 0) |
| m67a (M1) | **not ok** (exit 1): `--check-write 2026-01-01-x.md` answered `ok 2026-01-01-x.md` | ok |
| m67b (M2) | ok | **not ok** (exit 1): last line `badform` instead of `error` |

`bats --count` at d07cc89c is 75, and these are its last two `@test`s (`test/scripts/dev-cycle.bats:1356`, `:1371`), so they are tests 74 and 75.

Command: `cd <copy> && timeout 300 bats -f '<test name>' test/scripts/dev-cycle.bats` for the three copies and two tests; exits as tabled; 2026-10-06T17:18:54Z.

**Evidence:** `test/scripts/dev-cycle.bats:1356-1378`, `scripts/lib/dev-cycle-read.sh:158`, `scripts/lib/dev-cycle-read.sh:266-267`, docs/reviews/execution-logs/u2a1-s25/c67-mutant-diffs.txt, docs/reviews/execution-logs/u2a1-s25/c67-mutants.txt

---

## Claims Requiring Attention

### Incorrect
- **Claim 19** (`docs/working/plan-build-loop-handoff.md:125`): F10 lists `docs/thoughts/` among "the docs check_fix denied", but check_fix allows it (pinned by `dev-cycle.bats:1029`), and the same plan's U2a1 note (`:274`) says they differ on purpose. This line predates the branch. Reword to "the docs check_fix denies plus docs/thoughts/ and constraints.md". r1 only.

### Stale
- **Claim 11** (`docs/reviews/override-log.md:322`): the C1 row cites `scripts/dev-cycle.sh:181-183`; since d48f4645 the condition and skip message are at `:179-181`. r1 only.

### Mostly Accurate
- **Claim 4** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:21`): A8's "printed an empty reason" holds only when the call is spliced into a line. Assigned (main_file's form), d48f4645's one-argument call ended the shell (exit 1). r2 and r3 observed the same and kept it as a scope caveat.
- **Claim 8** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:27`): "five other suites" leaves out test/scripts/fixture-git-env.bats, whose own setup writes 2 commits into an inherited GIT_DIR (executed: victim 1 to 3). r3 only.
- **Claim 9** (`docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`): C11's measured range (0.42-0.52 ms) is not what the "corrected" row says (0.3-0.5 ms, the union with iteration 1). r2 and r3 graded it Verified.
- **Claim 13** (`docs/reviews/override-log.md:325`): the subshell cost re-measured at 0.48-0.54 ms (r1), at or above the row's 0.5 ceiling; the 0.3 floor is iteration 1's. The conclusion holds. r2 and r3 graded it Verified.
- **Claim 15** (`docs/reviews/override-log.md:327`): the C7 list omits fixture-git-env.bats (same finding as Claim 8). Every cited line is accurate (r1, r2).
- **Claim 20** (`docs/working/plan-build-loop-handoff.md:273`): "about twenty override rows" for U2, but 26 Defer rows on main name U2. r3 graded the order Verified.
- **Claim 35b** (`scripts/lib/dev-cycle-read.sh:283-284`): error and the default arm also drop "for" when `$2` is ""; the comment states the "" case only for notfile and badform. r1 noted the same as a scope caveat.
- **Claim 49b** (`test/scripts/fixture-git-env.bats:3-6`): the header names GIT_INDEX_FILE, but the victim check counts only commits and refs. Executed (r2), a GIT_DIR-only unset passes both tests while the victim's index is rewritten.
- **Claim 51b** (commit 91469367): "${2-} like the lib's other optional arguments". The others use `${2:-}`. History only.
- **Claim 51c** (commit 91469367): Notes "about 2 s" for fixture-git-env; measured 0.71-0.73 s wall (r1), 0.964 s (r3, graded Verified on order). History only.
- **Claim 52d** (commit d07cc89c): "corrected to the re-measured range". The row's range is the iteration 1 and 2 union, not the re-measured range. History only.

### Unverifiable
(none)

## Escalations

- **E1:** `test/scripts/fixture-git-env.bats:9-15`. The suite that pins the setups' `unset` does not unset the repo-local variables in its own setup; run under an inherited GIT_DIR it fails both tests and commits into that repo (victim 1 → 3 commits). The C7 row (`docs/reviews/override-log.md:327`) and the rubric's C7 line (`:27`) omit it. r3: "This is the C7 class (Defer), not a regression of this unit's code; adding the same `unset` line to its setup would close it." Raised by r3 (Goal-Alignment Escalate E1, informational; Claim 7). Merged Claims 8 and 15. Addressee: orchestrator ("for the orchestrator").
- **E2:** `test/scripts/fixture-git-env.bats:20` (header `:3-6`). The victim check counts only commits and refs, so the GIT_INDEX_FILE half the header names is unpinned: a GIT_DIR-only unset passes both tests while the victim's index is rewritten. r2: "low-severity, because the real unset clears both variables"; "Narrow the header, or add an index check." Raised by r2 (Goal-Alignment Escalate; Claim 31b). Merged Claim 49b. Addressee: orchestrator.
- **E3:** `docs/working/plan-build-loop-handoff.md:125`. A pre-existing plan line outside the diff that now contradicts the diff's own `:274` (docs/thoughts/ attributed to check_fix's denials). Raised by r1 (Goal-Alignment Escalate, "nothing blocking"; Claim 18). Merged Claim 19 (Incorrect). Addressee: orchestrator.
- **E4:** `docs/reviews/override-log.md:322`. The C1 row's line citation drifted (`scripts/dev-cycle.sh:181-183` → `:179-181`). Raised by r1 (Goal-Alignment Escalate; Claim 10). Merged Claim 11 (Stale). Addressee: orchestrator.
- **E5:** `docs/reviews/override-log.md:325`, `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a1.md:31`, commit d07cc89c. "One timing-wording item": the C4 row's 0.3-0.5 ms is the iteration 1 and 2 union, not the re-measured 0.42-0.52 ms the rubric and commit name. Raised by r1 (Goal-Alignment Escalate; Claims 8, 12, 46b) and r2 (Claim 37, "History only"). Merged Claims 9, 13 and 52d. Addressee: orchestrator.
- **E6:** commit 91469367 and commit d07cc89c messages. Immutable-history residues: `${2-}` "like the lib's other optional arguments" (51b), Notes "about 2 s" (51c), "corrected to the re-measured range" (52d). r1: "Commit history: no fix is possible, so an Accepted-immutable row fits" (Claim 45; Claim 46b "no fix possible"); r2: "History only" (Claims 35, 37); r3: "Commit message: immutable history" (Claim 34). Raised by r1, r2 and r3. Addressee: orchestrator.
- **E7:** `docs/working/checkpoint-build-loop-handoff.md:29` (on main, not in the diff). It still describes the pre-badform `error` meaning of main_entry. Raised by r2 (Goal-Alignment Out of scope; Claim 28 prose). Related: merged Claim 36. Addressee: orchestrator.

All three replicates' Escalate lines are non-blocking: r1 "nothing blocking", r2 "low-severity", r3 "Nothing blocking; 0 Incorrect" (r3 and r2 assigned no Incorrect; r1's one Incorrect is E3, outside the diff).

## Verdict stability

- Total clusters: 63. That is 52 multi-replicate clusters plus 11 single-replicate detections (Claims 8, 11, 12, 14, 19, 22, 29b, 36, 37, 38 and 43).
- Clusters where all reporting replicates agreed: 52 of 63. Single-replicate clusters count as agreed trivially. Among the 52 multi-replicate clusters, 41 agreed.
- Disagreeing clusters (11):
  - Claim 4 (rubric:21, A8): r1=Mostly accurate · r2=Verified · r3=Verified → Mostly accurate
  - Claim 9 (rubric:31, C11): r1=Mostly accurate · r2=Verified · r3=Verified (compound) → Mostly accurate
  - Claim 13 (override-log:325, C4): r1=Mostly accurate · r2=Verified · r3=Verified (compound) → Mostly accurate
  - Claim 15 (override-log:327, C7): r1=Verified · r2=Verified · r3=Mostly accurate (compound, via r3 Claim 7) → Mostly accurate
  - Claim 20 (plan:273): r1=Mostly accurate · r2=— · r3=Verified → Mostly accurate
  - Claim 35b (lib:283-284): r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate → Mostly accurate
  - Claim 49b (fixture-git-env:3-6, GIT_INDEX_FILE): r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound) → Mostly accurate
  - Claim 51a (commit 91469367, bullets/Tests): r1=Mostly accurate (compound; carried by 51c) · r2=Verified · r3=Verified (compound, via r3 Claims 5, 9, 32) → Verified
  - Claim 51c (commit 91469367, Notes "about 2 s"): r1=Mostly accurate (compound) · r2=— · r3=Verified → Mostly accurate
  - Claim 52c (commit d07cc89c, C7-C10): r1=Verified (compound) · r2=Mostly accurate (compound; carried by 52d) · r3=Verified (compound) → Verified
  - Claim 52d (commit d07cc89c, C4 corrected): r1=Mostly accurate · r2=Mostly accurate (compound) · r3=Verified (compound) → Mostly accurate
- Agreement rate: 52/63 = 82.5% over all clusters, and 41/52 = 78.8% over multi-replicate clusters. Claims 51a and 52c disagree only through a sibling's compound verdict; excluding those two, 43/52 = 82.7% of multi-replicate clusters agreed.
- Every disagreement sits between adjacent verdicts (Verified and Mostly accurate). The only Stale (Claim 11) and Incorrect (Claim 19) verdicts are single-replicate (r1) detections, with no replicate disagreeing.
- Five of the 11 disagreements are timing or wording-precision calls (9, 13, 51c, 52d on timing; 20 on "about twenty"), where r3 recorded a Decision to grade approximate figures on order of magnitude.

## Goal-Alignment Note
- Success criterion (restated verbatim): "A merged code-fact-check report at docs/reviews/code-fact-check-report-build-loop-u2a1.md, k=3, most-severe-wins, with per-replicate verdicts and annotation union."
- Answered: yes. The three replicates (47, 38 and 39 claims) merged into 63 clusters, emitted at the finest granularity any replicate used: 50 Verified, 11 Mostly accurate, 1 Stale and 1 Incorrect. Every cluster has its per-replicate verdicts and an annotation union. The last claim is 52e; a Stage 2.5 section numbers from 53.
- Out of scope: re-verifying any claim (mechanical collation only, with no new evidence); the per-replicate files themselves, which stay on disk for audit.
- Escalate: nothing blocking. Seven non-blocking routing entries are in `## Escalations` (E1-E7); the one Incorrect (Claim 19, E3) is a pre-existing plan line outside the diff.
- Decisions I made: (1) Two sub-claims, 51a and 52c, carry a sibling compound verdict of Mostly accurate whose replicate attributes the MA to the other sub-claim (r1's timing note; r2's C4 clause). I recorded those as `(compound; carried by …)` and did not let them set the verdict, per decision 033 as iteration 2's merge did. A strict most-severe-wins reading would make both Mostly accurate, for 13 MA in total. (2) A replicate claim whose own Scope line names a second location was recorded in that location's cluster as `(compound, via rN Claim M)`: r3 Claim 7 (rubric `:27` and override row `:327`, which makes Claim 15 Mostly accurate although r1 and r2 verified its cited lines), r3 Claim 8 (override `:325` and rubric `:31`), r3 Claims 2/5/9/32 (commit sentences), r3 Claims 18/20 (SKILL.md, shared_branches) and r2 Claim 30 (dev-cycle.bats `:11-13`). Claims whose prose alone touched another cluster got a merge note and `—`. (3) r3's NUL-marker claim, cited at `test/scripts/build-loop-read.bats:264`, was clustered with r1/r2's `:297` on the identical quoted sentence. (4) Where all replicates agreed, I carried r1's evidence unless another replicate verdicted the exact sub-claim atomically (7a, 7b, 35a, 35c, 49a, 50, 51a, 52b, 52c, 52e). (5) Evidence lines that cited only replicate-root paths (`$FC/...`, `$S/...`) carry that replicate's root as recorded in its provenance, so each claim's evidence names a concrete path; Claim 1 and Claim 21's evidence lines list paths from their carried prose.
