# Research: the small constraint-drift audit

**Goal**: read the Path A design records the dev cycle flagged for constraint drift and prepare, with the `constraints-builder` skill's amend mode, one owner call per flagged line of `docs/constraints.md` (promote, keep soft, drop, or a new line).
**Problem framing**: the drift check (step 4 of `skills/dev-cycle/SKILL.md`) flags a soft line that pruned an option, or a rule outside the file that decided a pick. Considered and discarded: "every flag means the file is wrong". Each flag is tested here for whether the soft line changed the outcome or only the record's wording.
**Project state**: this doc is the whole deliverable · from the roadmap Now item "Agent: scoped deep audit, constraint drift", scoped by the owner's Q-269 [1] (the small audit now, not the full one) · not blocked (cite: docs/working/briefs/2026-11-11-constraint-drift-audit.md)
**Task status**: complete

Mode (constraints-builder Step 1): **amend**, over the flagged cases only. The baseline is `docs/constraints.md` at ee637249 (last changed 2620b419, 2026-10-19, by the owner), which parses: `constraints ok 4-hard 10-soft: docs/constraints.md (draft)` from the installed `~/.claude/scripts/build-loop.sh --check-constraints`. No other source was re-read (the brief puts the full audit out of scope).

## The records

The roadmap item names "seven flagged Path A records"; they resolve to six research docs, since the Q-259 and Q-260 skill changes are the merges aeab6745 and 85080263 themselves (their merge commits carry `Build-loop-approved: Q-259` and `Q-260`). All six were found, force-added by their loops:

| Merge | Owner entry | Record (on ee637249) | Why flagged |
|---|---|---|---|
| 605d4c18 | self-merge | `docs/working/research-2026-11-05-canon-proposal-filter.md` | drift: soft line pruned; unwritten rule decided |
| 85080263 | Q-260 | `docs/working/research-2026-11-06-free-merged-loop-worktrees.md` | drift: soft line shared a prune; skill changed |
| aeab6745 | Q-259 | `docs/working/research-2026-11-05-d6-block-into-image.md` | drift: soft line shared a prune; skill changed |
| 546788f2 | Q-265 | `docs/working/research-2026-11-03-q125-verify-check.md` | drift: soft line pruned beside a hard one |
| 3dbf43cb | Q-266 | `docs/working/research-2026-11-06-codify-trial-practices.md` | skill changed (step 4b trigger) |
| 1f14e270 | Q-271 | `docs/working/research-2026-11-10-dev-cycle-skill-held-fixes.md` | skill changed (step 4b trigger) |

The last two were flagged as substantial skill changes, not drift findings, so they were read for the same two drift signals.

## Case by case

Verdicts: **acted as hard** (a soft line removed an option that would otherwise have competed), **label only** (the record says "pruned" but the option lost on the ranking soft lines are for, or on a hard or brief line too), **unwritten rule decided**, **false alarm**.

### 1. 605d4c18, the canon proposal filter's script home

- `research-2026-11-05-canon-proposal-filter.md:257`: "Path A: **the fork.** The archive README and the handoff doc both put instrument code there, and the recall runner must move there anyway [...] a checklist fails S4, because the scrub is the step a person gets wrong."
- The S4 line (mechanical steps in tested scripts) removed the checklist: **label only**. A checklist for the step "a person gets wrong" loses on the S4 line as a ranking, and three script homes remained.
- Among the three script homes, the fork won on "instrument code lives in the SWRBench fork": **unwritten rule decided**. Its sources are `archive/README.md:18-19` ("the living home for benchmark work is the SWRBench fork"; blame b1e38997, by the owner with an agent co-author, so **mixed** provenance) and the archived fork handoff. The auto-memory note "SWRBench fork is a separate project" says the same thing; memory notes rank lowest as evidence.
- The rule is real and has an author source, but it is a project-scope boundary, not a design criterion. It bears only on benchmark or review-instrument work, which is one roadmap item in the window. The skill's sort ("keep a line only if designs across many features would trip on it") points to leaving it out of the file.

### 2. 85080263 (Q-260), where finished-worktree removal lives

- `research-2026-11-06-free-merged-loop-worktrees.md:65`: "D. Prose in step 1 (`git worktree unlock`, `remove`) | Yes | S4: mechanical rule in prose; H1: the rule would be judged by the orchestrator | pruned".
- The brief (`docs/working/briefs/closed/2026-11-06-free-merged-loop-worktrees.md:18`) offered three homes, all code; the loop added D itself. B (a new script mode) beats D on the S4 line as a ranking, and line 68 says "B dominates". **Label only**: the pick is the one the file's ranking gives.
- The H1 part is a stretch. The H1 line covers code that "gates, reviews or bounds a change"; removing a merged loop's worktree is housekeeping. The record's line 77 does apply the H1 line's real point correctly (nothing that decides removal is read from the worktree's own files). No change is proposed for the H1 line; it is noted so the full audit can check whether loops read it too widely.

### 3. aeab6745 (Q-259), where the D6 script lives

- `research-2026-11-05-d6-block-into-image.md:49`: "`bin/d6` [...] grows `install.sh` (S8), touches enforcement files (Live-verified, a host probe) | pruned".
- `research-2026-11-05-d6-block-into-image.md:50`: "`/usr/local/bin/d6` by `COPY` [...] a PATH lookup would let PATH choose (H1) | pruned". This is the H1 line's core case (the environment choosing the gate): correct.
- Line 53: "of the options that keep R6f's scrub, it alone needs no enforcement-file change". The pick needed no installer or Dockerfile change at all, so `bin/d6` lost on cost whatever the S8 line said. **Label only**.

### 4. 546788f2 (Q-265), how the Q-125 check file reaches the sandboxed Bash path

- `research-2026-11-03-q125-verify-check.md:53`: "A. `claude -p` with a real login | [...] | Fails S10: the owner at a prompt mid-run [...] A real LLM also decides whether to run the script (H4)."
- The brief did not exclude A. It lists it ("a headless `claude -p` asking for the script to run is one option; it needs a login in the fresh verify volume") and keeps the owner at the prompt as a fallback ("If no way works without the owner at the prompt, [...] a short walkthrough"), `docs/working/briefs/closed/2026-11-03-q125-verify-check.md:18`. It does prefer a non-interactive route and one host paste whose exit status is the verdict (`:10`), which has the same conditional shape as the S10 clause. [corrected in review: an earlier draft said the brief excluded A]
- A also failed a hard line in the same cell: "A real LLM also decides whether to run the script (H4)". B then dominated on every axis (line 58). **False alarm**: the H4 line and B's dominance decide the pick without the S10 citation.
- This is the one case where a soft line read as hard on its own terms. The S10 clause "no merge or loop that waits on the user's manual action when a fail-closed alternative exists" is worded as a prohibition with a condition a design can be checked against before it is chosen, which is the shape of a hard line.

### 5. 3dbf43cb (Q-266), the first trial set's practices in the skill

- `research-2026-11-06-codify-trial-practices.md:51-58` scores the D1 candidates in pass/fail columns headed by soft lines (S3, S10, S8). Line 62: "**Decision: [2], Path A.**" [2] passes every column, so no soft column removed an option that could have won. **False alarm** for drift. Scoring soft lines as pass/fail is the mirror of what the skill warns about for hard lines (`skills/constraints-builder/SKILL.md:228-229`, "Hard lines are pass/fail"), and here it changed nothing.
- Line 93: "the T4 and 'weekly due' checks stay prose rather than digest code (S4 weighed [...])". The S4 line was **traded away** here, which is evidence that it is soft.

### 6. 1f14e270 (Q-271), three held dev-cycle fixes

- `research-2026-11-10-dev-cycle-skill-held-fixes.md:135`: "8 | [...] | ~ | pruned: grows `install.sh` (S8), an enforcement file, for a prose fix". The B4 column (the brief: "no new owner stop, entry or host chore", line 119) is already `~` for 8, and survivors 3, 4 and 5 pass every hard line. The S8 line ranked 8 below them. **Label only**.
- Line 138: "11 | [...] | ✗ (a worktree to clean up, S10) | pruned". The ✗ is under B4, the brief's own line, and the row also carries a ⚠ under B3/H1, the mark that pruned rows 2, 10 and 12. **False alarm**.
- Line 121 lists the S4 line as soft with the brief's own override ("the brief asks for prose unless prose cannot state the fix"): S4 traded away a second time.

### What the six add up to

- One real drift: an unwritten rule decided a pick (case 1). Its rule is narrow.
- One wording question: a soft clause phrased as a prohibition (the S10 clause, case 4), the line a loop is most likely to read as hard.
- Four "pruned on a soft line" flags were wording. The option lost on the ranking the file asks soft lines to do, or on a brief line. The drift check cannot tell the difference, because records say "pruned" for both. That is a note for the cycle, outside this unit's paths (a skill change): the check could count a soft-line prune only when the pruned option would otherwise have won.
- Evidence on hardness. The S4 line was traded away twice (cases 5 and 6). The S8 line's "no growth of the 500-plus-line files" was traded four times since the file was written, each time in a merge the owner approved: `devcontainer-config/install.sh` grew +177/−27 in 086f08c8 (Q-241 [1]), and `cc-isolated.sh` grew in c80fec22 (Q-195), 37b24c02 (Q-217) and 3cd6d9bb (Q-267) (`git log --first-parent --numstat` from 2026-10-19). Under the skill's rule ("soft when [...] traded away at least once"), neither is hard.

## Gotchas

- Failure-pattern grep: no matches found
  - Grep run: `grep -inE 'constraints\.md|soft-constraint|soft-line|prun|hard-line|unwritten' docs/failure-patterns.md`.
- The retired ID `S9` (removed in 2620b419) is not reused. A new line takes S12, so a record that cites the old S9 is never misread.
- Tests: none run. The unit is docs only, and the brief needs none.

## Design choices

One-line note: this unit has no design choice with three or more options. Its output shape (one questions-entry table per flagged line) is set by the brief.

## Proposed amendment (constraints-builder amend mode)

Recommended: **no change to the file.** Each flagged line keeps its ID and wording (calls A to D below). The alternatives the calls offer, drafted so they can be pasted as they stand:

```diff
 H4: An LLM judgment is a detector, never an enforcement primitive: [...unchanged...]
 success: [...unchanged...]
 
+H5: No merge, loop or check waits on the owner's manual action when a fail-closed alternative exists; a design that adds an owner step names the alternative it rejected and why.
+success: `rg -n -e '/dev/tty' -e '\bread +-[a-zA-Z]*p' -- scripts/build-loop.sh scripts/dev-cycle.sh scripts/lib/` prints nothing, and the research doc of a change that adds an owner step quotes the rejected fail-closed alternative.
+
-S10: Spend the user's attention last: at most one host paste per verification, no new recurring host chore or trust decision, nothing left behind to clean up, no merge or loop that waits on the user's manual action when a fail-closed alternative exists, and no safety that depends on the user remembering a flag.
+S10: Spend the user's attention last: at most one host paste per verification, no new recurring host chore or trust decision, nothing left behind to clean up, and no safety that depends on the user remembering a flag.
 [...]
+S12: Benchmark and review-instrument code (recall runners, scrubbed-clone preparation, arm runs) lives in the SWRBench fork, not here; a design that puts it in this repo says why the fork cannot hold it.
```

Checks on the alternatives:

- Parse: the baseline with the H5 and S12 lines inserted (scratch copy) prints `constraints ok 5-hard 11-soft: <scratch>/draft-alt.md (draft)`, exit 0, from the installed `--check-constraints`. Removing the S10 clause changes only the text of one line.
- The H5 grep, against today's tree at ee637249: no output (exit 1); again over tracked files with ignores off (`git ls-files -z | xargs -0 rg -n --no-ignore ...`): no output. Planted `read -rp "merge? " ans` into a `git archive` copy of `scripts/dev-cycle.sh`: caught (`scripts/dev-cycle.sh:621`). Its second half (the research doc quotes the rejected alternative) is a review check, not a grep.
- The S8 rewording in call B is a single-line text change with no new ID.

## Questions for the owner (one per flagged line, for the cycle to file)

Each is a `you: judgment` call. A [1] on all four leaves `docs/constraints.md` as it is. Any other answer is a change only the owner commits, since no build loop may land one.

### Call A: the S4 line (mechanical steps go in tested scripts, not prose)

Flagged at 605d4c18 and 85080263. In both, the option it "pruned" lost on the ranking soft lines exist for. It was traded away twice (3dbf43cb, 1f14e270), so it is soft in practice.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep soft, unchanged (recommended)** | no edit | none | loops keep writing "pruned" for a soft-line loss; the drift check keeps flagging it |
| **[2] Promote to hard** | needs a `success:` line, e.g. a bats case per new mechanical step | one commit by you | the two units that rightly kept prose would have been refused |
| **[3] Drop** | the S3 and S6 lines still rank most of these | one commit | prose-only mechanical steps come back unranked |

### Call B: the S8 line's "no growth of the 500-plus-line files" clause

Flagged at aeab6745 (and pruned again at 1f14e270). Both times the pick needed no installer change, so it changed no outcome. The clause has been broken in four merges since 2026-10-19, all four approved by you (one was Q-241 [1], +177/−27 to `install.sh`).

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep soft, unchanged (recommended)** | no edit | none | loops keep reading "no growth" as a prune |
| **[2] Reword as a preference** | "prefer no growth of [...]", which says it ranks | one commit | none known; a softer word might let growth through more often |
| **[3] Promote to hard** | split into its own hard line with a `numstat` success line | one commit | the Q-106 host-settings work would have been refused |

### Call C: the S10 clause "no merge or loop that waits on the user's manual action when a fail-closed alternative exists"

Flagged at 546788f2, a false alarm: the pruned option also failed the H4 line (an LLM must not be the enforcement), and the pick beat it on every axis. It is still the soft clause most worded like a hard one, and it matches your standing rule against new owner stops. Option [2] is the H5 line in the diff above.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Keep soft, unchanged (recommended)** | no edit | none | a loop may again treat it as a prune; no outcome has changed yet |
| **[2] Promote to a new hard line (H5) and trim the S10 line** | owner-waiting designs are pruned before choosing | one commit; one more line in every loop prompt | a needed owner step must argue past it; its grep misses waits via a questions entry |
| **[3] Drop the clause** | the S10 line's other clauses still rank owner cost | one commit | designs that wait on you lose their explicit counterweight |

### Call D: the unwritten rule "instrument code lives in the SWRBench fork"

It decided 605d4c18's script home. Its source is `archive/README.md:18-19` (you directed it, an agent co-wrote it). It bears only on benchmark or review-instrument work. Option [2] is the S12 line in the diff above.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Leave it out of the file (recommended)** | the archive README stays its home; loops find it as they did | none | a future recall-run loop might miss it and put instrument code here |
| **[2] Add it as a soft line (S12)** | every loop prompt carries it | one commit; one line in every prompt | a line nearly every design ignores costs context for no gain |
| **[3] Add it as a hard line** | instrument code here is refused | one commit, plus a `success:` path grep | a small helper that belongs here gets refused |

## Notes for the skill (constraints-builder)

- In amend mode, the most common "soft line pruned" flag was the record's wording, not a decision. A step that asks "would the pruned option have won without this line?" separates the two faster than re-reading the constraint.
- Brief-level and other hard lines (B1 to B4 in 1f14e270, the H4 line in 546788f2) often did the pruning that a soft repo line was cited for. Reading the unit's brief beside its record was needed to tell.

## Files read

Last verified: 2026-11-11
docs/working/briefs/2026-11-11-constraint-drift-audit.md
docs/constraints.md
docs/roadmap.md (the constraint-drift Now item)
skills/constraints-builder/SKILL.md
skills/dev-cycle/SKILL.md (steps 4 and 4b)
the six research docs in the table above
docs/working/briefs/closed/2026-11-03-q125-verify-check.md
docs/working/briefs/closed/2026-11-06-free-merged-loop-worktrees.md
archive/README.md
