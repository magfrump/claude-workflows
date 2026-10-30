Commit: 2141f7ee

# Tech-debt triage, final pass: chore/dev-cycle-2026-10-15-0357 (docs only)

Scope: `git diff main...2141f7ee`. The diff touches 12 files (+2587/−31). Of those, 5 are the
cycle docs and 7 are review artifacts or override-log rows. The change since iteration 1
(`16136a60..2141f7ee`) is 100 lines in questions.md, 4 in roadmap.md and 2 in
questions-archive.md. This pass covers only process and document debt. It is advisory.

## Status of iteration-1 items

| # | Item | Now | Better or worse |
|---|---|---|---|
| F1 | Q-162 paste had no conflict abort | **Fixed.** questions.md:90 wraps the merge in `\|\| { git merge --abort; ...; false; }`, and :85 marks it "Not runnable yet" | Better. A failed paste now leaves nothing half-merged and deletes nothing. |
| F2 | User-routed queue and its chained order (deferred, override-log) | Not changed. No entries were added or removed | Unchanged. Not re-filed. |
| F3 | Branch state copied across documents (deferred, override-log) | The four drifted strings were corrected (roadmap.md:52 `tip d25254da`; Q-162 "seven reviewed units"; Q-165 "roadmap Now"; Q-174 "built on an earlier ... 184396ea"). Hash pinning then added more copies (see F5) | Mixed. The existing drift is gone, but the number of copies has grown. F5 covers the new part. F3 is not re-filed. |
| F4 | Q-167(a) expected bless output from `--list` | **Fixed.** questions.md:208 now expects the bless output and the `--list` line separately | Better. |

## Triage Summary

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| 5 | The rebuild of the ready branch now has to re-pin 4 entries, but only Q-162 says so | Low | +3 hand-edited hashes (Q-163, Q-164, Q-169) per rebuild of `merge/ready-*` or its sibling merge branches | | Minutes | The next cycle's rebuild | Fix opportunistically |

## Findings

### F5. Hash pins multiply the re-pin work, and only Q-162 is marked "not runnable"
- **Severity:** Low
- **Location:** docs/working/questions.md:85, :90, :118, :149, :259
- **Evidence:**
  > `The next cycle rebuilds merge/ready-2026-10-15 on main, keeping both sides' appends, and replaces the hash in the paste; run it only after that.` (:85)

  > `git -c core.useReplaceRefs=false show a760a5e5057ef3f0abd13145e7d945ef500b8abd:docs/working/spike-cc-verify-q117.md` (:259, Q-169)

  > `then B=a04d97762518389f053c3c609a3dfcc4531d553b; else B=0f94bb7702073f78992b8eba25ac131473b49825; fi` (:149, Q-164)

  I ran a read-only `git merge-tree --write-tree` with each pinned target:

  | Target | vs main 7f711bfe | vs 2141f7ee (after landing) |
  |---|---|---|
  | c035f2e7 (Q-163 alone) | clean | conflict |
  | a04d9776 (Q-163/Q-164 combined) | conflict | conflict |
  | 0f94bb77 (Q-164 alone) | conflict | conflict |

  After this branch lands, each Q-163 and Q-164 paste aborts cleanly through its guard. Neither
  entry carries a note like Q-162's at :85.

  Q-169 extracts the spike from a760a5e5. When the ready branch is rebuilt, that commit is
  reachable only from the reflog, so a later `gc` can prune it. The sha256 check at :262 turns
  a missing or altered object into a stop, never a wrong run.

  The note at :85 says only "replaces the hash in the paste". It does not name the other
  three entries that need new hashes.
- **Cost of Deferral:** `+3 hand-edited hashes per rebuild`. This is bounded, not
  compounding: the entries close once their merges land.
- **Failure cost:** none material. Every pinned paste aborts or stops on mismatch and
  deletes nothing. The real cost is one wasted paste, and the user's attention spent on it.
- **Fix:** widen the :85 note to say the rebuild re-pins Q-162, Q-163, Q-164 and Q-169. Add a
  one-line "Not runnable until Q-162's rebuild" to Q-163 and Q-164, or let the next cycle do
  all of this when it rebuilds. This is a doc edit, and no RPI is needed. The stage-1
  fact-check filed the same gap as Stale.
- **Confidence:** High. merge-tree was reproduced here, and `git branch --contains a760a5e5`
  lists only `merge/ready-2026-10-15`.
- **Legibility-target:** for-orchestrator-synthesis. The orchestrator decides whether to add
  the notes before merging or to leave them to the next cycle's re-pin.
- **Recommendation:** Fix opportunistically

## Recommended Order

1. Before or at landing (optional): add the two-line notes from F5. The stage-1 Q-169
   "8 → 12 items" correction belongs in the same edit.
2. Next cycle: rebuild `merge/ready-2026-10-15`, then re-pin all four entries in one commit.
   F2 and F3 stay deferred under their override rows. F3's revisit trigger ("a later landing
   review finds the same drift class again") has not fired, because the iteration-1 drift was
   corrected. F5 is a re-pin coupling, not a stale copy.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/tech-debt-triage-review-2026-10-15-0357-final.md (first line `Commit: 2141f7ee`), structured per the tech-debt-triage skill."
- **Answered:** yes. The report has a status line for F1–F4 that says whether each got better
  or worse, and one new item (F5) with its carrying cost, `+X per Y` deferral, fix cost and one
  of the allowed recommendations. F5's merge claims were reproduced with read-only
  `git merge-tree`.
- **Out of scope:** factual errors that are not debt, such as Q-169's item count and Q-170's
  87→88; they belong to the fact-check. The content of the units behind the pins is also out
  of scope.
- **Escalate:** none blocking. No item has a destructive failure mode now that every paste
  aborts or stops on mismatch.
- **Questions/Decisions:** the orchestrator decides whether F5's notes go in before the merge
  or with the next cycle's re-pin.
