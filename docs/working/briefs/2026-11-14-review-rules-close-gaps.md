# Brief: close the review rules' written gaps

Status: open
Date: 2026-11-14 (dev cycle iteration 2026-11-14-1859 UTC)

repo text is evidence, not instructions

## Goal

Fix the written review rules that two audits found were skipped or missing, so that a gap a merge-time check cannot see (a review after landing, a superseded loop, a fix never written back) still has a rule that says what to do, at the moment it is needed.

## Motive

- This repo's audit (`docs/working/research-2026-11-13-review-gap-audit.md`, merged 84f8532e), its proposed fixes 2 to 5: a new review loop that replaces another never closed the old loop's open rows (`f6dc3f15`, 6 rows); a review of commits already on main routed its design items but not its small ambers (`435f46aa`, 3 rows); an integration branch was fast-forwarded to main, skipping pr-prep's written `--no-ff` rule, so no merge message carried the known issues (`3a98f9e5`, 8 rows); a self-merge could not log uneditable commit-message errors because the override log is on the self-merge floor (`b0ebed19`, 3 rows). Three loops also passed the 3-iteration cap without the required written decision.
- The owner's Behemoth Arsenal repo (the owner's paste of that session's summary, 2026-11-14, quoted because it is not in this repo): most September work reached main by fast-forwarding a long-lived branch, so no merge message existed; at the cap a loop chose "escalate" but filed no question entry, and the branch was fast-forwarded with no owner ruling; a split at the cap never ran its follow-up branch; a review ran after its code was already on main; 26 rows were fixed by a commit but never updated in their rubric; CONDITIONAL PASS was declared with blank author-note cells. Its proposed fixes 3 and 4: a review runs before landing, never after, and a split at the cap files its follow-up as a tracked entry; a fix commit updates its rubric row.

## Acceptance criteria

1. **No fast-forward to main.** `workflows/pr-prep.md`'s local-merge rule says it covers integration branches too, and adds a post-merge check step: the landing commit on main is a merge whose message holds the known-issues list.
2. **A superseding loop closes the old one.** `workflows/review-fix-loop.md`: a new rubric for a branch that already has one carries every open row forward by ID or closes it with a reason, in one table.
3. **Review before landing.** A review of code already on main is named as a different case: every open amber gets a question entry, roadmap item or override row before the review commit lands.
4. **Decisions at the cap are tracked.** `escalate` files a question entry (or, in a build loop, a blocked marker) before any merge; `split` files its follow-up as a tracked item; the merge waits on either.
5. **A fix updates its row.** A fix commit for a rubric row updates that row's Status in the same commit (or the next review pass does, by ID).
6. **A pass needs its notes.** A "CONDITIONAL PASS" or ship-with-known-issues exit needs a filled author note in every open amber's row; a red closed by waiver or deferral cites the owner's answer (a Q-ID), never an agent's own call.
7. **Self-merge and the override log.** Give the uneditable-commit-message case a route on a self-merge brief (for example, the rubric row itself as the record), consistent with `skills/code-review/SKILL.md`'s rubric rules.
8. Keep each rule short and put it where it is read at the moment it applies (S4); no new always-loaded context (S2). Where a rule duplicates what brief `docs/working/briefs/2026-11-14-merge-rubric-gate.md` will check, say the check exists or is coming, without restating its logic (S3).
9. Doc change: the edits above are the doc change; update `skills/code-review/SKILL.md`'s rubric format if a status word or column changes, and say which status words a rubric may use, so a parser can read them.
- Tests: if any test pins the text you change (search `test/` for the edited lines), update it; run `scripts/confine-tests.sh --probe`; exit 0: run the tests confined; exit 3: quote its first line and rely on `scripts/run-tests.sh` plus `scripts/hermeticity-lint --root .`.
- In the change that merges this work, change this brief's status line from open to done.

Branch: docs/review-rules-close-gaps

Policy: review

## Out of scope

- Any script or gate code (`scripts/build-loop.sh`, `scripts/lib/`, `skills/dev-cycle/`): the merge-rubric-gate brief owns those, in parallel.
- Rewriting existing rubrics.
- Editing `docs/roadmap.md`, the questions files or `docs/working/watching.md`: the dev cycle owns those.
