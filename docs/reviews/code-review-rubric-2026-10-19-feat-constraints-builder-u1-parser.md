Commit: a29344d3
Loop closed at a29344d3

# Code Review Rubric

**Branch:** `feat/constraints-builder-u1-parser` (unit 1 of 3, stacked: u2 references, u3 skill) · **Date:** 2026-10-19
**Scope:** full branch, `main...HEAD`; at iteration 1 (0732a759): 3 files, 157 changed lines, 140 counted outside `docs/` · **Pass:** iteration 1, `--loop-pass` (fact-check k=1, decision 031)
**Delivery mode:** self-read. The diff is inline-sized, but each agent ran `git diff`. The enclosing `build-loop.sh` (about 145 KiB) is over the 25k-token budget, and agents read skill files from disk rather than having them pasted.
**Critics:** security-reviewer, performance-reviewer, api-consistency-reviewer (all opus). No contextual critic was triggered: tests changed with the source, 3 files, under 500 lines, and no structural change.
**Harness note:** subagents may not write report files here, so each returned its report as text and the orchestrator saved it (condensed) under `docs/reviews/`.

## 🔴 Must Fix

None.

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | A newline in FILE prints a second line byte-equal to `--settings`' `constraints ok … on the default branch`. A path ending "on the default branch" mimics the WHERE (`build-loop.sh:641-649`, `:574`). The script's gate is unaffected; an agent reader is the exposure. | Security | Medium | security-reviewer F1 | for-author | — | ✅ Fixed | An ASCII control byte (C0 or DEL) in FILE is now bad usage (exit 1); C1 is refused only in a UTF-8 locale. Every draft WHERE reads `FILE (draft)`, so no draft line that names the file (ok, none-hard, missing, refused) can equal main's; nosuccess, dup and near name no file in either mode and exit 2. *(Corrected in iteration 2: the first wording said "no draft line", which all three final-pass replicates disproved.)* T46 covers the forged-newline case. |
| A2 | The header says the script needs a repo and a default branch; this mode needs neither (`:505-506`) | Docs | Stale | fact-check claim 9; security F3 | for-author | — | ✅ Fixed | "but for --check-constraints, which reads no repo" |
| A3 | "WHY naming FILE" is false for the nosuccess, dup and near lines (`:70-71`) | Docs | Mostly accurate | fact-check 6; api F3 | for-author | — | ✅ Fixed | "where a WHY names the file" |
| A4 | The Exit paragraph's exit-2 list omits this mode; "ok with a hard one" is redundant (`:515-520`) | Docs | Mostly accurate | fact-check 10; api F3 | for-author | — | ✅ Fixed | |
| A5 | The CONSTRAINTS_AWK comment omits odd and unbalanced, and names only docs/constraints.md (`:541-542`) | Docs | Mostly accurate | fact-check 11 | for-author | — | ✅ Fixed | |
| A6 | constraints_line's comment covers only 4 of 6 outputs; callers pre-filter (`:567-569`) | Docs | Mostly accurate | fact-check 12 | for-author | — | ✅ Fixed | |
| A7 | T46's "out of a repo" was not asserted (bats `:201`) | Tests | Mostly accurate | fact-check 16, 21 | for-author | — | ✅ Fixed | A `git` shim first on PATH for every draft run records each call in a file that T46 asserts is absent, so any git call found through PATH, even a silenced one that tolerates failure, fails the test (an absolute-path call would not; the script makes none). *(Iteration 2: the first shim reported only on stderr, and a silenced call passed; the mutation now fails T46.)* |
| A8 | "One set of messages": the odd and unbalanced texts are copies of main_file's (`:646-647` vs lib `:609-610`) | Arch/Docs | Mostly accurate | fact-check 20; api F4 | for-author | — | ✅ Fixed | Kept as copies, commented as such. T46 now runs the same fence-refused and comment-refused file through `--settings` and `--check-constraints` and compares the lines, WHERE aside. |
| A9 | Q-199: "418 of the 570 lines" does not reproduce; it is 424 (`questions.md:677`) | Docs | Mostly accurate | fact-check 4 | for-author | — | ✅ Fixed | |

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | The symlink and non-file check runs before the open and covers the last component only; the header overstated it (`:641-644`, `:68-72`) | security F2; performance F3 | Low | for-author | — | ✅ Header narrowed; the TOCTOU itself is Won't-Fix (override row 2026-10-19) |
| C2 | No size or line-length cap; mawk is superlinear on one huge line (a 200 MB single line ran past 120 s) (`:644`) | performance F1 | Low | for-author | — | Won't-Fix (override row 2026-10-19) |
| C3 | The `--check-` prefix reads like dev-cycle.sh's exit-0 check family, but the mode exits 2 (`:585`, `:650`) | api F1 | Minor | for-author | — | ✅ Fixed in the help: "exits like --check, not like dev-cycle.sh's check modes" |
| C4 | FILE resolves against $PWD, while other path args are repo-root-relative (`:637-652`) | api F2 | Minor | for-author | — | ✅ Fixed in the help |
| C5 | The "could not be read" branch is untested (`:644`) | fact-check 21 | Minor | for-author | — | Defer (override row 2026-10-19) |
| C6 | Informational, no change recommended: opencomment `split` memory, read-to-EOF after refusal, scrub_reexec ~5 ms, subshell ~0.4 ms, hoisted definitions, no dev-cycle.sh twin needed | performance F2, F4-F7; api F5 | Informational | for-orchestrator-synthesis | — | No action |

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1b` / 2026-10-05 | U1c's constraints reader should be its own function (iteration 3 C8) | 🟢 → Defer | "It is U1c's code. Revisit trigger: U1c's review." | Discharged: this diff factors it out as `constraints_line()`. |
| `feat/build-loop-u1c` / 2026-10-05 | --status reads the constraints file and never uses it (performance F3) | 🟢 → Won't-Fix | One blob read per run | Inherited, not re-flagged; the diff leaves `--status` alone. |

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The mode makes no git call before it exits, in or out of a repo | ✅ Confirmed | fact-check claim 5, executed: a logging git shim recorded `git calls: none` on 8 inputs from a non-repo dir; `--settings` under the same shim logged `git rev-parse` (positive control). Pinned by T46's call-recording shim (iteration 2). | code-fact-check | for-orchestrator-synthesis |
| `--settings`' constraints strings are unchanged by the refactor | ✅ Confirmed | fact-check claim 15, executed: T44 passes unchanged | code-fact-check | for-orchestrator-synthesis |
| A FILE like `a=b` or `-n` is read as a file, not as an awk assignment or option | ✅ Confirmed | fact-check claim 14, executed (mawk operand vs redirect); security endorsement 3, executed | code-fact-check | for-orchestrator-synthesis |

Endorsement claims routed by security (draft bytes reach output only as awk tokens; the dispatch gate cannot be set by this mode; `$c` is an awk integer) were not verdicted this pass. Stage 2.5 is skipped on a `--loop-pass`, so they stay *pending execution verification* until the final pass.

## ⚠️ Unverified Findings

None.

## ⏭️ Skipped Core Critics

None.

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `scripts/build-loop.sh:637-652` | A1, A7, A8, C1, C2, C5 | distinct defects: each states its own mechanism and fix |
| 2 | `scripts/build-loop.sh:66-72, 505-528` | A2, A3, A4, C3, C4 | distinct defects: separate wording gaps in one header |

## Iteration log

- **Iteration 1** (full scope, `--loop-pass`, k=1): 0 🔴, 9 🟡, 6 🟢. Every 🟡 was fixed in 17ffe8cb. Of the six 🟢 rows: C3 and C4 fixed; C1 fixed in its header half, with its race Won't-Fix; C2 Won't-Fix; C5 Defer (three override rows); C6 informational, no action.
- Tests after fixes: `bats test/scripts/build-loop-read.bats test/scripts/build-loop-dispatch.bats` gave 25/25 ok, and the shellcheck counts are unchanged from main (`cd scripts && shellcheck -x -f gcc build-loop.sh | wc -l`: 29 on both).

- **Iteration 2** (final confirming pass attempt, full scope, fact-check k=3 at ecc51340, 34/41/40 claims): no behavioral red. All three replicates found the same doc-level Incorrect, the "never equals --settings' line" claim in the help (`:72-73`), rubric A1 and commit 17ffe8cb's body; per tier policy T this is 🟡. They also found: the git shim missed a silenced call (Incorrect or Mostly accurate across replicates); override rows had stale line cites and a forward-looking `timeout` claim; Q-199's unit sizes were stale; the control-byte claim holds for C0 and DEL only (C1 depends on the locale); and the rubric's 🟢 tally and its "146 KB" were off. The critic panel was not run, because the pass was not clean on fact-check and a confirming pass must be. All of these were fixed in the iteration-2 fix commit. The two commit bodies are immutable and have accepted-immutable override rows. Unverifiable: b6d19a70's claim about the other repos' drafts (external history).

- **Iteration 3** (final confirming pass, full scope, fact-check k=3 at 127e55ab, 40/28/29 claims): 0 Incorrect, 0 Stale. Mostly accurate, all doc or test wording: the A1 and A7 notes; the T46 comment; the header's commit for the iteration-1 figures; the override row's capture format; 127e55ab's "the scrub strips it" (true only for UTF-8-encoded C1; the help claims nothing about C1); and 17ffe8cb's A7 sentence. Unverifiable: the replicate counts (now recorded in the reports file) and the shellcheck command (now named above). Also hardened T46: stdin from /dev/null, so an operand-for-redirect regression fails rather than hangs, and the no-argument run is shimmed. Fixed in the iteration-3 fix commit.

- **Iteration 3 critics** (full panel at a29344d3, opus):
  - security: no findings. Bypass probes all held (C0, UTF-8 C1, bidi, `/dev/fd` paths, FIFO, `-`, `a=b`, a 23-digit ID). The raw-0x80-0x9F residue is the scrub's documented gap and can't reach a line that passes for main's.
  - performance: F1 is carried as Won't-Fix. F8 (T46 is 0.4 s of 17 s), F9 and F10 are informational.
  - api-consistency: no Breaking or Inconsistent findings, and pass-1 F1-F5 all read right. 🟢 finding 2 (help: "a FILE holding" read as the contents) is fixed in the close-out commit. 🟢 findings 1 and 3 belong to u3 (step 0.3) and are fixed there, in 7d49f8f8.
  - Two security endorsements routed to code-fact-check are left *pending execution verification*: draft bytes reach stdout only as awk tokens, and `$c` is an awk numeric. Stage 2.5 was not run. The critic probed both by execution.

**Status:** Review converged in 3 iterations: 0 Must Fix; 9 + 7 Must Address resolved (iterations 1 and 2) plus iteration 3's wording; 3 Consider declined with override rows, and 2 commit bodies accepted-immutable. Single-sample review; absence of findings is not an attestation.
