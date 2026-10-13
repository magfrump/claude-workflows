Commit: 4aad0f9c

# Security Review — feat/build-loop-u3c (final confirming pass)

**Scope:** `git diff main...HEAD` (main dafc0e74, HEAD 4aad0f9c): scripts/build-loop.sh (--cycle-diff, QKEYS_AWK, QDIFF_AWK, ROADMAP_AWK, cyc_blob, cycle_diff, raw_records), scripts/health-check.sh (take_lock), scripts/lib/dev-cycle-read.sh (comment), T38/T43, the plan bullet, the eight override rows appended to docs/reviews/override-log.md
**Date:** 2026-10-12
**Based on:** docs/reviews/code-fact-check-report-2026-10-12-u3c-final-r{1,2,3}.md (k=3 at ec9dace7) and the shared brief's Stage-1 summary; 4aad0f9c reviewed directly

## Trust Boundary Map

```
B1: [orchestrator's staged index (chore worktree)] → [--cycle-diff: QKEYS_AWK/QDIFF_AWK vs BASE] → [chore commit on chore/dev-cycle-*]
B2: [chore branch tip + main at land]               → [git's merge (all merge bases)]           → [main's questions files]
B3: [main's questions files]                         → [check_answer / ANSWER_AWK]               → [--approved, a brief's Asked: unblock]
B4: [chore commit's other paths (briefs, scripts)]  → [not judged (row 722, re-keyed to U4)]    → [main: gate code, brief machine lines]
B5 (new): [concurrent gate runs, same uid]           → [take_lock: flock on <common dir>/health-check.lock] → [one health check at a time]
```

Input sources:

```
S1: staged index (questions, roadmap, idea log)  — request-time (orchestrator writes) — UNTRUSTED toward the answer reader (the point of the check is the orchestrator's slip)
S2: --answered IDs                               — request-time (orchestrator CLI)   — trusted by design for the IDs it names (unrecorded: override row, deferred to U4)
S3: BASE = git merge-base HEAD MAIN_SHA          — derived from repo history the orchestrator also writes — UNTRUSTED as a stand-in for the land's merge base
S4: MAIN_SHA's questions files                   — runtime-mutable (user answers, gates) — trusted as the user's record
S5: HEALTH_CHECK_LOCK_HELD, lock path            — environment / same-uid common dir — trusted for availability only
```

What crosses: the orchestrator's index (S1) reaches main through a merge whose result --check-answer then reads as the user's (S4 → B3). --cycle-diff judges S1 against one merge base (S3) and assumes the land's merge result equals the index for the questions files whenever main's questions equal that base's. That assumption holds only when the land's merge has a single merge base (Finding 1).

## Findings

#### 1. A criss-cross history lets the land's merge build an answer that neither the index nor main reads (B1 rule defeated)

**Severity:** Medium
**Location:** `scripts/build-loop.sh` cycle_diff, the `git merge-base HEAD "$MAIN_SHA"` line and the ls-tree comparison below it
**Boundary:** B1, B2, B3
**Move:** 11 (bypass enumeration for the main-changed rule), 4 (check vs. use: the check reads one base, the land's merge uses all of them)
**Confidence:** Medium (mechanism executed; the history shape it needs is uncommon in the planned flow)

`git merge-base` without `--all` returns one of the best common ancestors. When HEAD and main have two (a criss-cross: main landed an older chore commit while the chore branch went on to merge an older main), --cycle-diff compares the index against the one it got, and the B1 rule compares main's questions files with that same one. git's merge at the land, and merge-tree in log_class's clean_merge, instead uses a virtual base built from all of them. If that virtual base differs from the chosen base, the merge is no longer "take the index", and it can combine free body edits from the index (fence lines removed) with main's hunks (a line that was fenced) into a file where an answer line is outside any fence. Executed in a fixture under my scratch dir (`crisscross.sh`): with two merge bases, --cycle-diff printed `ok` with no --answered, and `git merge-tree --write-tree main chore` gave a questions file for which the lib's FENCE_AWK+ANSWER_AWK reads `keep`, while main's own copy reads `drop`. Preconditions: two merge bases between the chore tip and main, the chosen one's questions blob equal to main's, and a virtual base differing from it in the right region. The impact is the one this mode exists to stop: an answer the user did not give reaching main and unblocking `--approved` or a brief's `Asked:`. The roadmap and idea-log rules rest on the same assumption.

**Recommendation:** Refuse when `git merge-base --all HEAD MAIN_SHA` prints more than one commit (cheap and fail-closed; the refusal can say "merge the default branch into HEAD"). Alternatively, judge what actually lands: run the questions comparison on `git merge-tree --write-tree MAIN_SHA <tree of the index>`'s result against MAIN_SHA. Add the criss-cross case to T38.

#### 2. The row-722 deferral (other staged paths not judged) covers two answer-laundering shapes its rationale does not address

**Severity:** Low
**Location:** `docs/reviews/override-log.md` (the first U3c row, re-keying row 722); `scripts/build-loop.sh` cycle_diff's `*) continue` arm
**Boundary:** B4, B3
**Move:** 5 (invert the access model: what the guard leaves uncovered), 1
**Confidence:** Medium (read-static; the consumers are U4's, so not reachable on this branch)

The re-keyed row argues that a path list would misfire because step 1 may stage in-cycle fixes. That holds for arbitrary paths, but two narrower classes decide what "the user's answer" means and could be refused without misfiring. (a) GATE_CODE paths (`scripts/build-loop.sh`, `scripts/lib/`, `scripts/questions.sh`, `skills/dev-cycle/`): a chore commit can change ANSWER_AWK itself, and main's copy is what the next `--approved` runs. The floor already says gate code lands only through a merge-gate-review entry, but a chore land is not a gate merge, so neither the floor nor --cycle-diff reads it. (b) A brief's `Asked: Q-NNN@SHA` line, which the orchestrator writes on the chore branch (plan D4/F41). Retargeting it to an ID that already reads `keep` re-uses another question's answer to unblock a brief. Neither class is named in the deferred row, so U4 could close row 722 with a cycle-record path listing and leave both open.

**Recommendation:** Either refuse GATE_CODE paths in --cycle-diff now (one existing regex), or amend the deferred row to name both classes explicitly as U4's duties: GATE_CODE refused in chore commits, and an `Asked:` line only gaining IDs filed as new entries in the same index, never being retargeted.

#### 3. Lock exemption inherited by every descendant of a locked run (informational)

**Severity:** Informational
**Location:** `scripts/health-check.sh` take_lock (`export HEALTH_CHECK_LOCK_HELD=1`)
**Boundary:** B5
**Move:** 8
**Confidence:** High (read-static; documented in the header)

Every process check 5 starts inherits `HEALTH_CHECK_LOCK_HELD=1`, so a health check one of them runs against another repository or worktree sharing the common dir takes no lock. This is an availability and serialization property, not a laundering path, and the header states that any caller setting the variable skips the lock. No change needed beyond what the existing row records. The unbounded wait, the FIFO swap and the 127 exit are the deferred take_lock row, which is correctly scoped as same-uid (Q-103) or availability.

## Untested bypass candidates

- **Land with a non-default merge (rerere autoupdate, `-X`, a merge driver from a `.gitattributes` the chore commit stages).** Not tested. log_class's chore class requires clean_merge (merge-tree's default merge), and git takes one side without invoking a driver when the other is unchanged. U4's land has not been written yet.
- **Rename detection across questions.md and questions-archive.md at the land.** Not tested. With one merge base and main unchanged the merge takes the index, but under Finding 1's history it would interact with the virtual base.
- **HEAD moving between --cycle-diff and the commit (a merge made after the check).** Not tested. This is covered in substance by the "commit takes the index as read" row deferred to U4.
- **Unmerged (conflict-stage) index entries.** Read-static only: raw_records' `[AMDT]` status pattern returns 1, so the expected result is `refuse index`. Not executed.

Because of these entries and Finding 1, the B1 rule ("a questions change refuses while main changed them") does not appear in Endorsement Claims.

## Endorsement Claims

- **Claim:** QKEYS_AWK's fenced-heading test (`infence && /^### Q-[0-9]+ /`, before `fence($0)`) uses the same regex and the same position as ANSWER_AWK's `quoted` test, and --cycle-diff refuses when either the base copy or the index copy reports `quoted`.
  **Location:** `scripts/build-loop.sh` QKEYS_AWK lines 1-3 and cycle_diff's `grep -qv '^Q-'` refusal; `scripts/lib/dev-cycle-read.sh` ANSWER_AWK
  **Evidence:** read-static
  **Verified:** read both awk programs side by side, plus T38's two cases (index-side `quoted 13`, base-side `quoted 2`) in the diff
  **Not verified:** T38 not re-run at 4aad0f9c by me (the fixer's run is the evidence); an `odd` line arriving after a quoted heading (output then names odd, still a refusal)
  **route: code-fact-check**
- **Claim:** For one ID in a file not refused whole, ANSWER_AWK's result is fully determined by the ordered sequence of that ID's heading lines, `**Needs:**` lines and answer-labelled lines. QKEYS_AWK tags a superset of those (every `Q-N:` line, every Needs line), so in a single-merge-base land a changed result implies changed key lines.
  **Location:** `scripts/build-loop.sh` QKEYS_AWK, QDIFF_AWK; `scripts/lib/dev-cycle-read.sh` ANSWER_AWK
  **Evidence:** read-static
  **Verified:** heading match (`[ \t]|$` vs `h == id`, `id " "`, `id "\t"`), entry end on `^(#|##|###) `, CR strip before fence(), `- ` strip, the label regex, dup and both-files (the heading count is kept because every heading is a key line, and per-ID concatenation ignores the file)
  **Not verified:** the multi-merge-base land (Finding 1 refutes the end-to-end property there); awk implementations other than the one the suites run
  **route: code-fact-check**
- **Claim:** A new entry carrying any Status-ANSWERED Needs field or any answer line refuses without --answered, which is stricter than ANSWER_AWK (first Needs line only, last Status field).
  **Location:** `scripts/build-loop.sh` QDIFF_AWK `answered()`
  **Evidence:** read-static
  **Verified:** field split on ` · `, trimming on both sides, `an[id]` set from any n or a line on the index side
  **Not verified:** a new ID that also appears, renamed, in the other questions file on the base (the `o[id]` branch handles it, but I did not run it)
- **Claim:** take_lock runs the locked check as flock's child with the descriptor closed (`-o`), so a process the run leaves behind does not keep the lock; the exemption is the exported variable alone.
  **Location:** `scripts/health-check.sh` take_lock
  **Evidence:** read-static (T43's second test asserts it; not re-run by me)
  **Verified:** the flock flags, the 75 retry, and the plain-file test before the open
  **Not verified:** flock itself killed by a caller's timeout while its child runs (the child then runs unlocked)

## Primitive sweep

Primitive: process exec / path open on repo-controlled data

| Call site | Source | Guard | Disposition |
|---|---|---|---|
| `scripts/build-loop.sh` cycle_diff `git diff-index --cached` (checkout's git) | S1 | state_gate ran; `--raw` output only | cleared: no textconv or external diff applies to `--raw` |
| `scripts/build-loop.sh` cyc_blob `gate_git cat-file blob` | S1, S3 | mode 100644 only | cleared |
| `scripts/build-loop.sh` cycle_diff `gate_git ls-tree` (B1 rule) | S3, S4 | none | Finding 1 (single base) |
| `scripts/health-check.sh` take_lock `flock ... bash "$REPO_ROOT/scripts/health-check.sh"` | S5 | plain-file test (TOCTOU deferred) | cleared: same trust as the first exec; the swap is in the deferred row |

## Summary Table

| # | Finding | Severity | Boundary | Location | Confidence |
|---|---------|----------|----------|----------|------------|
| 1 | Criss-cross merge bases defeat the B1 rule; the land builds `keep` from a `drop` main | Medium | B1, B2, B3 | `scripts/build-loop.sh` cycle_diff (merge-base, ls-tree) | Medium |
| 2 | Row-722 deferral leaves GATE_CODE edits and `Asked:` retargeting in chore commits unnamed | Low | B4, B3 | override-log.md U3c row 1; cycle_diff `*)` arm | Medium |
| 3 | Lock exemption inherited by every descendant | Informational | B5 | `scripts/health-check.sh` take_lock | High |

## Overall Assessment

The 4aad0f9c fix closes the fenced-heading bypass on both sides. For a single merge base, the questions rule's key-line comparison matches what --check-answer reads, as far as I read it. The remaining laundering path is structural: --cycle-diff judges the index against one merge base, while the land's merge uses all of them. A criss-cross history therefore lets a clean land produce an answer that neither the index nor main reads (executed). The fix is small: refuse when there is more than one merge base, or judge the merge-tree result against main. Do it, with a T38 case, before U4 builds the land on this mode. Among the iteration-2 deferrals, the take_lock, hooks, --answered, compare-and-swap and preamble rows are scoped correctly. The row-722 re-key should name GATE_CODE paths and brief `Asked:` lines as U4 duties (or --cycle-diff should refuse GATE_CODE now). Endorsement claims are read-static and pending execution verification. This is not a categorical all-clear.
