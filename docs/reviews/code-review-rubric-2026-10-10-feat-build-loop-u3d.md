Commit: aff39758
Loop-pass short-circuit: used at aff39758

# Code Review Rubric: feat/build-loop-u3d (U3d, --start / --prompt)

**Iteration 1 of 3** · scope: full branch `main...aff39758` (no prior rubric for this loop) · delivery mode: self-read (diff file + repo) · fact-check k=1 (loop pass, decision 031), opus · report `docs/reviews/code-fact-check-report-u3d-i1.md` (31 claims: 21 Verified, 6 Mostly Accurate, 2 Incorrect, 2 Unverifiable).

Status: 🔴 1 Must Fix (behavioral, short-circuited) · critics deferred to iteration 2.

## 🔴 Must Fix

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | `--prompt --steal` dispatches into a worktree directory that no longer exists: git never marks a **locked** worktree prunable, and `--start` always locks, so a dead loop's missing worktree reads as a live lock, and with old lock and tip times `--steal` prints `ok BRIEF BRANCH DIR` for a missing DIR. The header's "or in one that is missing" holds only for an unlocked one. | fact-check claim 8b (executed, p2.log) | Incorrect (behavioral) | `scripts/build-loop.sh:1297` `elif [[ -n "$WT_PRUNE" ]]; then x="its branch $br is checked out in $WT, which is missing (git worktree prune drops it)"` | Open |

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| A2 | Header says a skipped brief prints `refuse BRIEF: WHY`; it prints `skip BRIEF: WHY` (exit 2) | fact-check claim 4 (Incorrect, Low) | `scripts/build-loop.sh:290` `#             or refuse BRIEF: WHY (as --status skips it, ...` | Open |
| A3 | "leaving no branch" omits the failed-delete exception; "Writes nothing but" omits the new branch's reflog and --prompt's unlock/relock; a failed relock after an unlock leaves the worktree unlocked | fact-check claims 5, 9, 15 (Mostly Accurate) | `scripts/build-loop.sh:1299` `elif ! { [[ -z "$WT_LOCK" ]] \|\| git worktree unlock "$WT"; } \|\| ! git worktree lock --reason "$reason" "$WT"; then` | Open |
| A4 | Prompt text narrower than the code it describes: floor list (other briefs' working docs and reviews, docs/thoughts, constraints doc; self-merge only), stopped REASON (no blank at either end), blocked body (D11: after blanks, `>` and list markers) | fact-check claims 19, 21b, 21c | `scripts/build-loop.sh:1322`, `:1333-1334` | Open |
| A5 | The create-only `update-ref ... ""` is untested (a mutant dropping the empty old value survives) | fact-check claim 25b | `scripts/build-loop.sh:1307` | Open |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A6 | aff39758's Notes say a lock without a build-loop time is never taken; any reason ending " UTC TIME" is taken (hand-written included). Commit text: correct in the merge message | fact-check claim 26b | Open |
| A7 | A self-merge `--check` from the main checkout refuses while a loop worktree sits at the default `.claude/wt-STEM` inside it (untracked nested repository); D13 runs the gate from the orchestrator's own worktree | fact-check escalation (orchestrator) | Open |

## ⏭️ Skipped Core Critics

- security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review: loop-pass short-circuit (behavioral red confirmed at fact-check, A1). No enforcement file in the diff (`hooks/live-verify-gate.sh` regex), so security is not forced. They run in iteration 2.

## Considered overrides

Rows 270 and 622 (addressed by this unit), 663 (land not split; trigger names U3d's worktree discovery: for the critics in iteration 2).

## 🧩 Composition check

No multi-source co-located clusters qualified (one source this pass).

Single-sample review; absence of findings is not an attestation.
