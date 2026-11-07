Commit: cbd189ef
Loop closed at cbd189ef

# Code Review Rubric

**Scope:** refactor/free-merged-loop-worktrees, `2ecca919..cbd189ef` (full branch) | **Reviewed:** 2026-11-06 | **Status: 🟢 PASSES** — 0 red, 0 open amber; single-sample review; absence of findings is not an attestation

Pass 1 (`--loop-pass`, k=1 fact-check at 7bbb8109, critics at 5a063f0e), then the final confirming pass (iteration 2 of 3: k=3 fact-check at 5b37a25e, one confirming security and API critic on `5a063f0e..cbd189ef`). Delivery mode: self-read.

**Deviation from the skill.** The final pass did not re-run the full panel: security and API ran as one agent on the fixes only, and performance and architecture did not re-run. The final k=3 fact-check covered the whole branch, and two of its replicates replayed the mode on a clone of the 35 real locks (21.4 s and 26.4 s). The reports live in the session's scratchpad, not in `docs/reviews/`: two critics and all three final replicates returned text only, because the harness refused their report files.

Final fact-check, k=3: 50, 45 and 40 claims; 1 Incorrect in two replicates, on the same research-doc sentence; 2 Stale. No replicate refuted a claim about what the code does to a worktree. Self-eval skipped: the skill change is 8 lines in step 1, not a substantial modification. Considered overrides: no prior overrides matched this diff.

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| R1 | `status.showUntrackedFiles=no` hid an untracked file from `git worktree remove`'s clean check, so the run printed `freed` and the file was lost. Location: `scripts/build-loop.sh`, `free_one` | Security | Medium, executed | security-reviewer F1 | for-author | — | 🟢 Fixed in 5b37a25e | Test 10 fails with `freed` on 5a063f0e |
| R2 | A worktree nested in a finished one's ignored `.claude/` was destroyed with it, while the same run printed `hold` for it. Location: `free_one` | Security | Medium, executed | security-reviewer F2 | for-author | — | 🟢 Fixed in 5b37a25e | Test 11 |
| R3 | A live loop that fast-forwarded to main passed "tip past lock" under a closed brief. Location: `free_one` | Security | Medium, executed | security-reviewer F3 | for-author | — | 🟢 Fixed in 5b37a25e: a handoff marker is required | Test 12 |
| R4 | A caller's `GIT_DIR` freed worktrees in that other repository; the plan's claim that the state gate stops this was false. Location: plan row "Wrong repository" | Behaviour | Incorrect, executed | code-fact-check 7a | for-author | — | 🟢 Fixed in 5a063f0e: `caller_gate` runs for this mode | Test 9 |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | "Any `refuse` line ... the step goes on" read as carrying on past `refuse d6:`. Location: `skills/dev-cycle/SKILL.md` step 1 | API | Inconsistent, High | api-consistency F1 | for-author | — | 🟢 Fixed in 5b37a25e and cbd189ef | — |
| A2 | The lock grammar sat in two regexes beside the writer. Location: `lock_behind`, `free_one` | Architecture | Coupling | architecture A1 | for-author | — | 🟢 Fixed in 5b37a25e: `LOCK_RE`, `LOCK_TIME` | — |
| A3 | "the worktree list every import walk reads" is false since brief 2026-11-03-import-walk-plain. Location: research doc | Docs | Incorrect | final fact-check, 2 of 3 | for-author | — | 🟢 Fixed in cbd189ef | The brief's motive repeats it; the `branch -d` half stands |
| A4 | "three independent signals" and the live-loop invariant predated the marker check. Location: research doc | Docs | Stale | final fact-check | for-author | — | 🟢 Fixed in cbd189ef | — |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `assume-unchanged` and `skip-worktree` hide an edit from the clean check; nothing here sets them | confirming critic C1 | Low likelihood | for-author | — | 🟢 Plan residual added; Won't-Fix: override-log row |
| C2 | "a live loop may hold it" also covers a bad marker, whose own WHY is dropped | confirming critic C2 | Minor | for-author | — | 🟢 Won't-Fix: override-log row |
| C3 | `steal` keeps its own copy of the time pattern | confirming critic C3, fact-check | Info | for-author | — | 🟢 Defer: override-log row |
| C4 | A run killed between unlock and remove leaves one worktree unlocked and unnamed | performance F1, security F4 | Low | for-author | — | 🟢 Won't-Fix: plan residual, override-log row |
| C5 | The call has no time bound, and a timeout is a stop | performance F2 | Info | for-author | — | 🟢 Won't-Fix: 21 to 26 s at the tip against 120 s; override-log row |
| C6 | `kept` lines name no remedy, and they recur each iteration | api-consistency F3 | Minor | for-author | — | 🟢 Defer: override-log row |
| C7 | A dropped or squash-landed brief's worktree reads `hold` with no report | fact-check | Minor | for-author | — | 🟢 Defer: research doc, override-log row |
| C8 | Commit 5b37a25e's "4 to 18 s" reads low | final fact-check | Minor | for-author | — | 🟢 Corrected in the plan and in cbd189ef's body; history not rewritten |

---

## 🧩 Composition check

- `scripts/build-loop.sh`, `free_one`'s removal lines: security F1, F2, F4 and fact-check claims on the header. Distinct defects: each states its own mechanism and fix.
- `free_one`'s lock test: architecture A1 and confirming critic C3. Distinct defects: C3 is an older copy outside the regex A1 merged.
