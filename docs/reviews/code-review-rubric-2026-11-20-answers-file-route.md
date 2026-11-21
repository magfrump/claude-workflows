# Code Review Rubric

**Scope:** feat/answers-file-route vs main at 5627e74c (full branch) | **Reviewed:** 2026-11-20 | **Status: 🟢 PASS** — iteration 1 found 0 red, 1 amber, 7 low; fixed in a2b7158f. Iteration 2 found nothing blocking; its nits were fixed in 63b2ee23. Touched suites 377/377, hermeticity lint and health check pass.

Iteration 1: one fresh general-purpose reviewer, single pass (k=1), no sub-critic panel. It covered correctness, fail-open paths, other consumers of `ANSWER_AWK` and `check_answer` (questions.sh counts, board.sh, `--cycle-diff`, rubric-check) and comment accuracy. It also probed `git log -z` parsing and real-repo data. Iteration 2: a second fresh reviewer re-checked the fixes. It diffed `--check-answer` over all 330 IDs on main before and after the fix commit, and the two outputs were byte-identical.

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|

None.

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | A line appended to an answers file added before the entry's Opened: date was ignored without notice, while `--main-log` classed the append commit `answers` | correctness / H2 | medium | reviewer i1 | owner | none | Fixed in a2b7158f: a named skip for an open entry; bats case added | the window still dates a file by its add, against ID collisions |

## 🟢 Consider

| # | Finding | Source | Status |
|---|---|---|---|
| C1 | An undated unreadable row lost its reason, because tab is IFS whitespace. | reviewer i1 | Fixed: split by parameter expansion |
| C2 | The `ANS_FOR` cache key was not cleared before a re-read. | reviewer i1 | Fixed |
| C3 | rubric-check and board.sh matched `check_answer`'s line whole, so the ` from ` suffix broke the match. | reviewer i1 | Fixed: `answer_word` in the lib, used by approval and rubric-check; board names the file |
| C4 | A merge bringing in an answers file, or a mixed commit, is classed `other`. | reviewer i1 | Documented in build-loop.sh header and SKILL step 0.2 |
| C5 | Dates are in the writer's own zone on both sides. | reviewer i1 | Documented as a residual |
| C6 | The edited-old-file skip also fired for answered entries. | reviewer i2 | Fixed: open entries only |
| C7 | board.sh `answer` refused when the file's line was prose. | reviewer i2 | Fixed: writes through; bats case |
| C8 | Rename or copy dates a file at its new name. | reviewer i2 | Documented as a known limit |
| C9 | An entry recorded as prose meeting a file option is a skip (11 archived IDs here). | reviewer i1, i2 | Kept on purpose: neither source alone reads as that option; commented |

## ⏭️ Skipped Core Critics

- security-reviewer, performance-reviewer, api-consistency-reviewer as separate dispatches: the reviewer covered the trust question (who can write `docs/human-author/`, which is the owner's Q-345 [1] pick), the cost (two `git log` calls per main commit) and the output contract change (one suffix on one line).
