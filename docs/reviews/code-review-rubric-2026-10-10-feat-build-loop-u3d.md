Commit: e3781a2c
Loop-pass short-circuit: used at aff39758

# Code Review Rubric: feat/build-loop-u3d (U3d, --start / --prompt)

**Iteration 1 of 3** · scope: full branch `main...aff39758` (no prior rubric for this loop) · delivery mode: self-read (diff file + repo) · fact-check k=1 (loop pass, decision 031), opus · report `docs/reviews/code-fact-check-report-u3d-i1.md` (31 claims: 21 Verified, 6 Mostly Accurate, 2 Incorrect, 2 Unverifiable).

Status (iteration 1): 🔴 1 Must Fix (behavioral, short-circuited) · critics deferred to iteration 2. A1-A5 fixed in 23ba4511, e3781a2c; A6, A7 override rows.

## 🔴 Must Fix

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | `--prompt --steal` dispatches into a worktree directory that no longer exists: git never marks a **locked** worktree prunable, and `--start` always locks, so a dead loop's missing worktree reads as a live lock, and with old lock and tip times `--steal` prints `ok BRIEF BRANCH DIR` for a missing DIR. The header's "or in one that is missing" holds only for an unlocked one. | fact-check claim 8b (executed, p2.log) | Incorrect (behavioral) | `scripts/build-loop.sh:1297` `elif [[ -n "$WT_PRUNE" ]]; then x="its branch $br is checked out in $WT, which is missing (git worktree prune drops it)"` | Fixed |

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| A2 | Header says a skipped brief prints `refuse BRIEF: WHY`; it prints `skip BRIEF: WHY` (exit 2) | fact-check claim 4 (Incorrect, Low) | `scripts/build-loop.sh:290` `#             or refuse BRIEF: WHY (as --status skips it, ...` | Fixed |
| A3 | "leaving no branch" omits the failed-delete exception; "Writes nothing but" omits the new branch's reflog and --prompt's unlock/relock; a failed relock after an unlock leaves the worktree unlocked | fact-check claims 5, 9, 15 (Mostly Accurate) | `scripts/build-loop.sh:1299` `elif ! { [[ -z "$WT_LOCK" ]] \|\| git worktree unlock "$WT"; } \|\| ! git worktree lock --reason "$reason" "$WT"; then` | Fixed |
| A4 | Prompt text narrower than the code it describes: floor list (other briefs' working docs and reviews, docs/thoughts, constraints doc; self-merge only), stopped REASON (no blank at either end), blocked body (D11: after blanks, `>` and list markers) | fact-check claims 19, 21b, 21c | `scripts/build-loop.sh:1322`, `:1333-1334` | Fixed |
| A5 | The create-only `update-ref ... ""` is untested (a mutant dropping the empty old value survives) | fact-check claim 25b | `scripts/build-loop.sh:1307` | Fixed |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A6 | aff39758's Notes say a lock without a build-loop time is never taken; any reason ending " UTC TIME" is taken (hand-written included). Commit text: correct in the merge message | fact-check claim 26b | Won't-Fix (row) |
| A7 | A self-merge `--check` from the main checkout refuses while a loop worktree sits at the default `.claude/wt-STEM` inside it (untracked nested repository); D13 runs the gate from the orchestrator's own worktree | fact-check escalation (orchestrator) | Defer (row) |

## ⏭️ Skipped Core Critics

- security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review: loop-pass short-circuit (behavioral red confirmed at fact-check, A1). No enforcement file in the diff (`hooks/live-verify-gate.sh` regex), so security is not forced. They run in iteration 2.

## Considered overrides

Rows 270 and 622 (addressed by this unit), 663 (land not split; trigger names U3d's worktree discovery: for the critics in iteration 2).

## Iteration 2 of 3 (full branch at e3781a2c, k=1; critics' first run)

Scope: full branch for the critics (short-circuited in iteration 1), fact-check on the fix delta aff39758..e3781a2c. Deviation: the fact-check and critics ran in parallel (the critics took iteration 1's fact-check report), since the delta fact-check could not change their inputs. Reports: `code-fact-check-report-u3d-i2.md` (13 claims, 0 Incorrect), `security-review-2026-10-10-u3d-i2.md`, `performance-review-2026-10-10-u3d-i2.md`, `api-consistency-review-2026-10-10-u3d-i2.md`, `architecture-review-2026-10-10-u3d-i2.md`. Prior Must Fix A1: resolved (fact-check executed, mutant M1). No re-fires.

| ID | Tier | Finding | Source | Status |
|---|---|---|---|---|
| B1 | 🟡 | `--prompt` refuses every re-dispatch after a marker (blocked answered, review [3], stopped [1]): the ended loop's lock blocks it for 2 h, then needs --steal (`scripts/build-loop.sh:1300`, executed) | api-consistency 1 (Inconsistent) | Fixed: a marker tip replaces the lock without --steal; tested |
| B2 | 🟡 | Two concurrent `--prompt` runs both dispatch one branch (steal unlock/relock; two adds with different --dir; executed 1/6 and 3/4) | security 1 (Medium) | Fixed: flock on build-loop-dispatch.lock in the common dir, held from listing to ok; tested |
| B3 | 🟢 | An existing worktree's path reaches the ok line and the prompt's cd unchecked | security 2 (Low) | Fixed: readerform or refuse |
| B4 | 🟢 | A lock reason's newlines print extra lines after refuse | security 3 (Info) | Fixed: flattened |
| B5 | 🟢 | --steal with --start, or twice: wrong usage text | api-consistency 2 | Fixed |
| B6 | 🟢 | absform duplicates readerform | api-consistency 3 | Fixed: readerform |
| B7 | 🟢 | Plan Dispatch/D1 text not updated | api-consistency 4 | Fixed: plan U3d as-built note |
| B8 | 🟢 | loop_prompt reads globals dispatch rewrites (STATUS[sha]) | architecture 3 | Fixed: TIP is an argument; a tested mutant |
| B9 | 🟢 | Cap and steal age repeated | architecture 4 (part) | Fixed: DISPATCH_CAP, STEAL_AGE; rest Defer (row) |
| B10 | 🟢 | A failed add drops git's reason | architecture 7 | Fixed: first line appended |
| B11 | 🟢 | GATED's comment after the denylist change | architecture 6 | Fixed |
| B12 | 🟢 | Prompt floor list lacks "below" | fact-check i2 | Fixed |
| B13 | 🟢 | wt_of vs land (row 663), CONSTRAINTS from line text, gate_start reuse, worktree add cost, dispatched N without BRIEF, untested symlink/readerform arms, unprobed submodule.recurse / LFS | architecture 1, 2, 5; performance 1, 2; api-consistency 5; fact-check i2; security | Defer / Won't-Fix (8 override rows) |

Status (iteration 2): no Must Fix; Must Address B1, B2 fixed.

## 🧩 Composition check

- Iteration 1: no multi-source co-located clusters qualified (one source).
- Iteration 2, `scripts/build-loop.sh` dispatch's existing-worktree arm (~:1296-1302): security 1 (B2, 🟡), api-consistency 1 (B1, 🟡), security 2 (B3), fact-check i2 (symlink arm). Distinct defects: B1 is the lock rule's input (marker state), B2 its atomicity, B3 the path's form; each states its own mechanism and fix.
- Iteration 2, wt_of vs land (architecture 1, api-consistency 6): one finding raised twice, not a composition (no 🔴/🟡 fragment).

Single-sample review; absence of findings is not an attestation.
