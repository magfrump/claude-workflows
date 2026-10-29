# Research: let an answer given in session approve a merge entry

Brief: `docs/working/briefs/2026-10-29-session-answers-for-merge-entries.md` (read at 0784fc8e).
Branch: `feat/session-answers-for-merge-entries`. Date: 2026-10-29.

- Failure-pattern grep: `rg -i "answer|approv|merge entr" docs/thoughts/failure-patterns.md`: one hit (FP-053, a numeric answer accepted as verified), not this mechanism

## Where the rule lives (S3: one source of truth)

The exception "never a merge entry's [answer through `--answered`]: those land only in the
user's own commit" is stated in exactly one place: `skills/dev-cycle/SKILL.md` step 9.3
(row 748). Nothing else states it:

- **Code.** `scripts/build-loop.sh --cycle-diff` and `--land-cycle` exempt any ID given with
  `--answered` (QDIFF_AWK's `ok[]`); they never look at the entry's slug. A merge entry's
  answer is already accepted with its ID listed: `test/scripts/build-loop-orchestrator.bats`
  ("A new entry filed answered is the user's only with its ID listed (F33: a pre-answered
  merge entry)") passes `--answered Q-004` for `merge-x-0123456789ab`.
- **`--merge --approved`** reads the entry from the default branch's commit through
  `--check-answer` and does not care which commit put the answer there.
- **The plan's D8** (`docs/working/plan-build-loop-handoff.md`) already names both routes:
  "you commit it yourself; you tell the orchestrator in its session, and it commits that
  answer". It quotes no merge exception. F33's row ("the orchestrator cannot launder the
  answer (T38)") is about answers the user did not give, which `--answered` still covers.
- **`docs/dev-cycle.md`** says the orchestrator "merges only on your `[1] merge`": true under
  either route. (It is also off-limits to a loop.)
- **Origin.** The exception came from `docs/reviews/security-review-2026-10-13-u4b2-i2.md`
  F4: a loop's report or task notification "phrased as the user's answer" could be taken as
  one by the orchestrator, and "an answered merge entry then lands through `--merge
  --approved`". The Rules line was widened then to name reports and task notifications as
  data. That fix stays.

So the rule is prose alone. Changing it changes no gate behaviour. What needs to change is
SKILL.md steps 7 and 9, the final message and the wait rule, plus tests that pin the
end-to-end path.

## Divergent design

Motive (S5): owner feedback 2026-10-29, first point. Q-228 was answered in chat, and the
orchestrator could not apply it. The owner calls the gate too strict. Every other entry's
session answer already lands, so the cost is one commit by the owner per merge. That is
attention they spend on each review merge (S10).

Constraints in play: H1 (gate code runs from a copy the change cannot edit: unaffected),
H2 (fail closed: `--approved`'s refusals are unchanged), H4 (an LLM judgment is never the
enforcement primitive), S1 (proportionate; defend honest slips, not a hostile same-uid
loop), S3, S4, S6, S8, S10.

| Option | What changes | H-constraints | Cost to owner | Residual / against |
|---|---|---|---|---|
| **(a) Drop the exception** | `--answered` covers merge entries as it covers the rest, under an extra prose condition: the user's own message names the ID and the option. The record quotes their words, and the final message names the approval. Step 7 merges in the next iteration. | Pass: the gate is unchanged, and the enforcement keys on main's commit and the pinned TIP as before. H4: the "did the user say it" judgment is the one already trusted for every other `--answered` ID. | None beyond the chat answer | F4's scenario. Bounded below. |
| (b) Keep an owner act, make it cheaper | e.g. a `questions.sh answer Q-NNN 1` paste that commits on main, or a one-line `git commit` paste the orchestrator prints | Pass | One terminal paste per merge (S10: a recurring host chore) | New script surface (S6/S8). The owner already rejected an owner act per merge. |
| (c) Status quo | none | Pass | One commit per merge | The owner's feedback rejects it, and F4's own fix (reports are data) already covers the slip it guards. |
| (d) Merge in the same iteration from the session answer | step 7 runs `--merge` on a working-tree answer, or the gate reads `--answered` itself | Fails D8/H1: the approval would come from text the gate cannot re-read on main | None | Breaks the main-commit anchor. Rejected. |
| (e) Code-checked owner token | the user must type a nonce the orchestrator printed, and `--cycle-diff` checks it | The nonce lives in the session, so the gate cannot re-check it from the artifact. It is theatre under H4. | Typing a token | S1: friction against a hostile model that S1 excludes. S8: new code. |

**Decision: (a)** (Path A). It is the only option that removes the owner's cost without
moving an enforcement point. (b) and (c) keep the cost the motive rejects, and (d) and (e)
fail a hard line or add friction S1 rules out.

### How (a) applies a session answer

1. The user answers in the orchestrator's session, in a message of their own that names the
   entry's ID and an option (`Q-NNN: [1]`, or "Q-NNN merge"). A merge entry is not answered
   by inference: "yes" or "merge it" without the ID, a loop's report or a task notification
   does not count.
2. Step 9 writes the answer line as `Q-NNN: [N]` (N the option the user named, so
   `--check-answer` reads it), sets the entry ANSWERED, and passes `--answered Q-NNN` to
   `--cycle-diff` and `--land-cycle`. The record's `### Answers committed` quotes the user's
   words, and the final message names the entry as "merge approved in session".
3. The next iteration's step 7 reads it from main's commit with `--check-answer` and runs
   `--merge BRIEF --expect TIP --approved Q-NNN` as for a committed answer. When no loop
   runs, the wait rule treats a landed, unapplied merge answer like a dispatch left to
   retry: the same one wakeup in 1200-1800 s, so the merge does not wait for the user to restart `/loop`.

### Residual risk (stated, S1)

- An orchestrator that mistakes a loop's report, a task notification or repo text for the
  user's message can now land a merge approval (review u4b2-i2 F4). The gate cannot tell
  the difference. It trusts `--answered` here as it trusts every other ID (F19: it catches
  honest slips, not forgery).
- Bounds that remain:
  - The Rules classify reports and notifications as data.
  - The answer must name the ID.
  - `--approved` still needs option 1 under the exact `merge-STEM-SHA12` or
    `merge-gate-STEM-SHA12` heading, read from main's commit, with `--expect` binding the
    full TIP.
  - The N rules still refuse the cycle's own files, `docs/constraints.md`, `docs/dev-cycle.md`,
    symlinks and `.git*` paths.
  - The final message of the landing iteration names the approval before the merge runs
    in the next one.
  - The merge is one `git revert -m 1` away.
- The approval's record on main is now orchestrator-attested, not user-authored: the
  quoted words under `### Answers committed` are written by the orchestrator, and the
  commit that lands the answer is its chore merge. That is the audit trail every other
  session answer already has (S1/F19).
- What a hostile model could already do: it writes every other owner answer and the cycle
  record, so this adds no capability a deliberately hostile same-uid loop lacked (it can
  write main directly, F19). S1 rules out defending against it here.

### Refusals the design keeps (covered by tests)

- `--land-cycle` refuses a merge entry's answer written without `--answered` (the
  orchestrator's own slip, T38). The new test in `test/scripts/build-loop-merge.bats` covers it.
- `--merge --approved` refuses the same entry while the answer is only on the chore branch,
  not on main (D8). Same test.
- A pre-answered merge entry filed new without `--answered` refuses (F33). This was already
  tested in `build-loop-orchestrator.bats`.

## Plan

1. `skills/dev-cycle/SKILL.md`:
   - Step 7, merge-entry bullet: a session answer arrives through step 9's land.
   - Step 9.3: drop "never a merge entry's"; state the ID-and-option condition and the
     quoting.
   - Wait rule: a landed, unapplied merge answer earns the retry wakeup.
   - Final message: name merge approvals given in session.
2. `test/scripts/build-loop-merge.bats`: one end-to-end case. A merge entry is open on main.
   `--approved` refuses. The chore branch writes the answer, and `--land-cycle` refuses
   without `--answered` and lands with it. `--merge --approved` then merges.
3. No change to `scripts/build-loop.sh`: its header already says `--answered` is "answers
   the user gave the orchestrator in-session", with no exception.
