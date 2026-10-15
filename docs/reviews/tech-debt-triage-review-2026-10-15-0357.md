Commit: 16136a60

# Tech-debt triage: chore/dev-cycle-2026-10-15-0357 (docs only)

Scope: `git diff main...HEAD` (5 files, +572/−31: questions.md, questions-archive.md,
roadmap.md, idea-log.md, cycles/cycle-2026-10-14.md). This is process and document debt that
the diff adds or makes worse. It is not an audit of the repo. Advisory only.

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 1 | Q-162's paste has no conflict abort and depends on landing order | Medium | +0 once this branch lands; +1 hand-resolved half-merge in `/workspace` per rebuild of `merge/ready-*` that lags main | Med × Med: the shared checkout is left mid-merge and the cleanup loop is skipped | Hours (one line) | Imminent (the next paste) | Fix now |
| 2 | Open asks routed to the user grow from 2 to 15, many chained to each other | High | +6.5 user-routed entries per cycle day (13 added over 2026-10-14..15) | | Hours to days | Already past what one sitting can clear | Fix opportunistically |
| 3 | Branch state is copied across 3–4 documents, with hashes and positional refs | Medium | +1 stale cross-ref per unit that joins or leaves the ready branch (Q-162 was edited in 6 of the 14 commits) | | Hours | None | Fix opportunistically |
| 4 | Q-167(a) expects output that `--list` does not print | Low | +0 (inert) | | Minutes | When Q-167 runs | Fix now (trivial) |

## Findings

### F1. Q-162's paste conflicts on today's main and has no abort guard
- **Severity:** Medium
- **Location:** docs/working/questions.md:86-88 (the paste); compare :115 and :145
- **Evidence:**
  > `git merge --no-ff merge/ready-2026-10-15 -m "Merge branch 'merge/ready-2026-10-15': ..." && \`
  > `for u in u3a1 u3a2 ... u4c; do git worktree remove .claude/wt-build-loop-$u && git branch -d feat/build-loop-$u; done`

  Q-163 and Q-164's pastes in the same diff do wrap the merge:
  > `{ git merge --no-ff "$B" -m "..." || { git merge --abort; echo "conflict: merge aborted; the loop rebuilds this entry's branch against main"; }; }`

  `git merge-tree --write-tree main merge/ready-2026-10-15` (run read-only by this critic)
  exits 1 with CONFLICT in roadmap.md, idea-log.md, questions-archive.md and questions.md.
  Against HEAD (16136a60) the same command exits 0.
- **Cost of Deferral:** `+0` if this branch lands before anyone runs Q-162. Otherwise each run
  leaves the shared `/workspace` checkout mid-merge, and the user has to back it out by hand.
  The `&&` also skips the worktree and branch cleanup.
- **Fix:** add the same `|| { git merge --abort; ... }` wrapper Q-163 and Q-164 use. A
  one-line edit; no RPI needed.
- **Confidence:** High (merge-tree reproduced it; the stage-1 fact-check found the same).
- **Legibility-target:** for-orchestrator-synthesis (it decides whether this lands as a
  pre-merge fix or the note "land this branch before Q-162" goes into the merge message).
- **Recommendation:** Fix now

### F2. The user-routed queue grows sevenfold, and its entries are chained
- **Severity:** Medium
- **Location:** docs/working/questions.md:25-60 (index); chains at :185, :201, :245, :320, :387
- **Evidence:** open entries by route:

  | Route | main | branch |
  |---|---|---|
  | you: judgment | 1 | 10 |
  | you: terminal | 1 | 5 |

  The chains are written as prose preconditions:
  > `If Q-165 picks [1], [2] or [3], does a passing staged run ... count` (Q-166)
  > `After Q-162's paste lands, run ./devcontainer-config/install.sh` (Q-167)
  > `Run only if Q-165 is answered [1], [2] or [3], after Q-162's paste has landed the doc on main.` (Q-169)
  > `Waits on Q-172` (Q-173) · `When Q-176 is answered: merge Q-092's two units` (Q-177)
- **Carrying cost:** High. Under the attention-budget rule, judgment entries are the only real
  spend, and this diff takes them from 1 to 10. The paste order the user must follow
  (Q-162 → Q-167; Q-165 → Q-166/Q-169; Q-176 → Q-177; Q-172 → Q-173; Q-162 before Q-163/164)
  exists only in each entry's prose. The generated index sorts by route, not by dependency,
  so it does not show that order.
- **Cost of Deferral:** `+6.5 user-routed entries per cycle day` at this branch's rate. Each
  new unit stopped at a cap or gate adds one.
- **Fix:** (a) fold Q-166 into Q-165 as a sub-choice, since it is conditional on Q-165 and
  already has an interim; (b) give the questions file a short hand-written "answer in this
  order" line above the index, or let `questions.sh index` print a `Blocks:` column. (b)
  touches `scripts/questions.sh`, so it is RPI-sized.
- **Confidence:** High on the counts; Medium on the rate (two days of data).
- **Legibility-target:** for-orchestrator-synthesis
- **Recommendation:** Fix opportunistically. This does not block landing. Surface the 10
  judgment IDs to the user on landing, as the global rule requires.

### F3. Branch state is duplicated, and the copies have already drifted
- **Severity:** Low
- **Location:** docs/roadmap.md:14-56 (Now); docs/working/questions.md:83-99 (Q-162 text and Read), :161, :178, :328
- **Evidence:** the same unit, hash and waiting-on Q-id are restated in the roadmap's Now
  list, Q-162's Read bullets and the cycle record. The drift is already visible in this diff:
  > `That branch is main plus five reviewed units` (Q-162; seven are listed)
  > `(roadmap Next 3: Q-117, Q-125/Q-130 and Q-098 wait on this)` (Q-165; the roadmap now lists it under Now, "was Next 3")
  > `Q-106 [2] is built (feat/q106-host-settings-merge, c6d7544f, on merge/ready-2026-10-15)` (Q-174; built on an older ready commit, per the stage-1 fact-check)
  > roadmap.md:51 `docs/branch-verify-without-install`, `22a4bb1f` (the branch tip is d25254da, per the stage-1 fact-check)
- **Cost of Deferral:** `+1 stale cross-ref per unit that joins or leaves merge/ready-*`.
  Six of this branch's 14 commits re-edited Q-162 and the roadmap together.
- **Fix:** refer to roadmap items by name, not by position ("Next 3"). Have roadmap Now
  entries cite only the Q-id and leave hashes and status to the question entry. Correct
  the four drifted strings above when this lands.
- **Confidence:** Medium (the hash and Q-174 claims rely on stage 1; the "five", "Next 3"
  and edit counts were checked here).
- **Legibility-target:** for-author
- **Recommendation:** Fix opportunistically

### F4. Q-167(a) expects bless output from `--list`
- **Severity:** Low
- **Location:** docs/working/questions.md:203
- **Evidence:**
  > `` `cc-isolated --list` should show "Verified live: NO" and `Next: cc-isolated --probe-only <repo>` alone on its line ``

  Those two strings are printed by the bless path (`cc-isolated.sh` on merge/ready-2026-10-15,
  :328-329). `list_projects` (:495+) prints
  `Blessed config $b — verified live: NO (run: cc-isolated --probe-only <repo>)`. The probe's
  `grep -i 'verified live'` still matches, so the probe runs. But the line the rebuild-hint
  fix changed (the `Next:` line losing its `# …` note) is not on `--list`'s output, so this
  probe does not exercise it.
- **Cost of Deferral:** `+0 — inert` until Q-167 runs. Then the user sees a mismatch, or
  records a live-verify that never checked the changed line.
- **Fix:** point (a) at the install's bless output, which shows the `Next:` line, or change
  the expected `--list` text. A one-line doc fix.
- **Confidence:** High
- **Legibility-target:** for-author
- **Recommendation:** Fix now (trivial; fix in place)

## Recommended Order

1. Land this branch before anyone runs Q-162. Optionally add F1's abort guard in the same
   pass. Both are one-line doc edits, with F4.
2. At landing, list the 10 `you: judgment` entries by ID to the user (F2).
3. F3's corrections and the "refer to items by name" rule fit the next roadmap loop.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/tech-debt-triage-review-2026-10-15-0357.md (first line `Commit: 16136a60`), structured per the tech-debt-triage skill."
- **Answered:** yes. There are four items, each with carrying cost, `+X per Y` deferral,
  fix cost and one of the four allowed recommendations. F1 was reproduced with a read-only
  `git merge-tree`, and F4 was checked against the ready branch's `cc-isolated.sh`.
- **Out of scope:** whether the units Q-162 bundles are themselves sound. The repo-wide
  exit-scan growth is Q-172's question, not this diff's. The roadmap Ideas this diff adds are
  recorded signals, not debt the diff creates.
- **Escalate:** none blocking. F1 is the only item with a landing-order consequence, and
  landing this branch first removes it.
- **Questions/Decisions:** whether F1's guard goes in before the merge or as a follow-up is
  the orchestrator's call.
