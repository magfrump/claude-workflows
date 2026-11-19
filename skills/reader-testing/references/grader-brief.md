# Grader brief

Send this to one fresh subagent per round, with the `{…}` fields filled in. The grader may read
everything in the run folder, including the key. It must not predict how a reader would behave
from the text: every finding cites a session. It returns `findings.md` as its final message, and
the orchestrator saves it.

---

You are grading a reader test of a draft post. You did not write the post, the tasks or the key.

**Read:** `{RUN_DIR}/tasks.md`, `key.md`, `post.md`, every file in `sessions/`, every
`predictions-*.md`, and the profile `{PROFILE}`. For a re-run, also the previous round's
`findings.md` at `{PREVIOUS_FINDINGS}` and the claim-change list at `{CLAIM_CHANGES}`.

**Write `findings.md`** with the sections of the template in `run-templates.md`, in this order:

1. **Task results.** Grade each task, for each session, against `key.md`: **pass** (every ●
   element, nothing contradicted, the status right), **partial**, or **fail**. A misreading the
   reader would repeat counts as a fail even when the rest is right. Give each non-pass a type:
   *missing* (not in the post), *buried* (in the post, outside where this archetype reads),
   *misread* (the text invites a wrong reading), *undefined* (a term used before it is defined),
   *overreach* (the text claims more than the body shows), *attachment* (the attachment doesn't
   match the post). Grade the opening-alone elements one by one, from the first-take reply only
   (the reader had nothing else then). Where a real reader deliberately rejects the frame the key
   assumes, grade **key contested** rather than fail, and say why. Where you can't tell a deliberate
   reframe from a misreading the text invited, grade **pending reader** and list it under item 7.
   Don't grade it key contested. A point resolved only from a linked doc is *missing*. A point
   resolved from a knowledge file is logged, not graded. Tag every answer a reader gave after
   they stopped reading as **post-stop**. A post-stop failure on a point the post makes only after
   the stop is *buried*, not *missing*.
2. **Recall.** Compare each reader's recall with the key's intended gist. A section the reader
   called clear and then misrecalled is a finding, whatever the reader said about it.
3. **Candidate findings.** Gather every stop, failure and complaint across sessions. Mark each
   **KEEP**, **GENERIC** (it would apply to any post and any reader: drop it) or **DUPLICATE**
   (merge it into the one it repeats, and keep both sessions' quotes).
4. **Convergence.** For each KEEP finding hit by two or more sessions, quote each session's
   reason, then ask: could one reader's reason be swapped into another's entry and still read
   naturally? If yes, it counts as **one** hit, since every simulated reader is the same model.
   Report the count after this test, and say which findings it reduced. Three or more
   non-swappable hits is systemic.
5. **Severity and kind.** A real reader misreading what the text is about is S1, whatever the
   simulated readers caught. S1 (a misreading likely to be repeated, or a rejection at the venue's
   screen), S2 (a task this archetype exists to do can't be done), S3 (doable with friction), S4
   (cosmetic). Kind: text-surface, affective or institutional.
6. **Calibration.** A simulated reader's catch never clears a real reader's miss of the same point. Score every prediction against the real session it names: hit, miss, **not
   reached** (the session stopped before the section the prediction needs), or not observable.
   A "not reached" is evidence of nothing. For each archetype with a real session, list the simulated findings the real reader
   confirmed, contradicted, or didn't reach, and the real-only findings. Mark each archetype
   without a real session **uncalibrated**.
7. **Unsettled readings.** List every real-reader answer that could be either a deliberate reframe
   or a misreading the text invited, with both readings and your credence in each. The orchestrator
   asks the reader; don't settle it yourself.
8. **Correctness candidates.** List every finding that says the post is wrong, or claims more than
   its sources show, with the reader's evidence. Don't verify them: the orchestrator sends them
   to a verifier, and Part A is filled in from its verdicts.
9. **Across rounds** (re-runs only). Each earlier finding is Fixed, Improved, Unchanged or
   Regressed. Check `{CLAIM_CHANGES}` against the difference between the two `post.md` files, and
   list any claim that changed without a Part A item behind it.
10. **Where archetypes conflict.** Name each conflict and what the profile's conflict rule says.

Leave Part A's verdict column empty, and leave findings labelled "observed by the orchestrator"
as they are, outside your counts.

Counts describe this run's sessions only. Any number you give is your credence about this run,
not a rate. Don't write the revision brief: the orchestrator writes it from the author's chair.
