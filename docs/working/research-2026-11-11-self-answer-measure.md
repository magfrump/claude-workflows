# Research: how many owner questions did the repo's docs already answer?

- **Goal**: Measure, from this repo's own history, how often a question filed for the owner could have been answered from a doc that already existed, and turn the result into a plan for letting models answer their own questions from a repo's docs.
- **Problem framing**: The questions doc spends the owner's attention, and at least one recent entry looked answerable from a doc on main, so the question is how large that class is before anything is designed for it. Considered and discarded: "models ask because they cannot find the doc, so build a search" (where a doc decided the question, the session had already read it and acted on it; the entry was a record that a rule required).
- **Project state**: this branch delivers one research doc, docs only · step 1 of the roadmap Now item "Models answer their own questions from the repo's docs", preparing its step 2 without building anything · not blocked (cite: docs/working/briefs/2026-11-11-self-answer-measure.md)
- **Task status**: in-progress (revised after review round 1; round 2 next)

Brief: `docs/working/briefs/2026-11-11-self-answer-measure.md` (self-merge, docs only).
Everything here was read at main's commit 963dbd4d. Sections 1 to 8 are the measurement.
The research notes and appendices after them are for agents. **The plan, what the numbers
cannot show, and the one choice that is the owner's are section 9, at the end of the file.**

Words used below.

- An **entry** is one `### Q-NNN` block in `docs/working/questions.md` (open entries, and
  answered ones not yet archived) or `docs/working/questions-archive.md` (answered): a
  question a session filed for the owner.
- Its **route** is its `Needs:` line. `you: judgment` needs the owner's taste or authority.
  `agent` is the older route for work an agent could do without the owner; since
  2026-10-29 such items live on the roadmap instead.
- A **hand-written** entry is any judgment entry that is not a merge or attestation entry.
  Those two kinds are written by a fixed step of the dev cycle, one per branch or commit.
- The **entry's commit** is the commit whose docs a reader of the question had: the commit
  that first held the entry's heading, with the exceptions in section 1.
- The four **classes**. **In full**: a doc on the entry's commit states the answer the
  owner later gave. **In part**: a doc narrows the options or names the default, without
  giving the answer. **None**: no doc answers it. **Authority**: the question asks for an
  act only the owner can perform (approving one merge, waiving a cap, changing a recorded
  decision, spending their time), so no doc could answer it whatever it said.
- A **conflict** is an entry where a doc, read plainly, pointed to a different answer than
  the one the owner gave.
- A **re-ask** is an entry that asks substantially the same question as an earlier one.
- A **self-answer** is what the roadmap item proposes: a model deciding a question from a
  doc line, quoted, without filing an entry.
- The **review caps** are the review loop's two limits: three review iterations per unit,
  and about 400 changed code lines per unit. Only the owner can waive either.
- **Gate code** is the set of files the merge gate itself runs (`scripts/build-loop.sh`,
  `scripts/questions.sh`, `skills/dev-cycle/` and a few more). A change to one goes to the
  owner as a merge entry and takes effect only at the next image release.
- H1 to H4 and S1 to S11 (there is no S9) are the hard and soft design constraints in
  `docs/constraints.md`. Each is glossed where it is used.
- `[observed]`, `[inferred]` and `[assumed]` say how a claim is known: read or run here,
  derived from what was read, or not checked.

## Summary

**The share is small. Of the 200 answered `you: judgment` entries, 4 (2%) were answered in
full by a doc that existed when they were filed. None of the four is a model that failed
to look: in each, the session had already acted on the doc or made its pick from it, and
the entry was a record that a rule told it to file.**

| Class | Entries | Share of 200 |
|---|---|---|
| In full | 4 | 2.0% |
| In part | 35 | 17.5% |
| None | 56 | 28.0% |
| Authority | 105 | 52.5% |

- **Half of everything asked was the owner's by authority**: 43 merge approvals, 25
  requests to attest that a commit on main had been reviewed, and 37 hand-written asks,
  mostly to land a unit, to go past a review cap, or to change a recorded decision. A doc
  lookup answers none of these. The attestation asks ended when the owner changed a rule
  (decision log row 74, 2026-10-20). Merge approvals have not ended: 38 of the 43 came
  after 2026-10-19, and the research of 2026-11-06 on merge approval chose to leave them.
- **The four in full were records, not questions a model could not answer.**
  - Q-154 put on record a ruling the owner had given in session ten days before.
  - Q-142 was filed after the session had merged on its own recommendation, under a
    standing instruction of the owner's. A second reader put its twin, Q-141, under
    authority.
  - Q-199 recorded a split of an oversized branch. The decision log says an agent "splits
    without asking and records the split as an interim in `questions.md`", and that is
    what the session did.
  - Q-254 came from a build loop that had picked its option by a line in the constraints
    file. It could not act on the pick (that needed another branch), and the dev-cycle
    skill files one entry for every blocked loop.
- **"In part" means the ask could have been shorter, not skipped.** The owner's answer
  was still needed in all 35, and in 9 of them it differed from the entry's own
  recommendation. A reviewer checked 24 of these entries and found 13 that did not name
  the doc that bore on them, so a lookup might have narrowed some asks.
- **Docs also pointed the wrong way.** 4 judgment entries are flagged where a doc named a
  different answer than the owner gave, and 6 entries exist only because two docs
  contradicted each other.
- **Hand-written judgment entries have fallen** from 13 to 28 a week (mid-September to
  mid-October) to 2 to 6 a week since 2026-10-19. Four things changed in the two weeks
  before, and these numbers cannot say which did how much. Of the 14 filed since, 2 were
  answered in full (Q-199 and Q-254, both above).
- **Earlier answers held the most.** Of the 39 judgment entries answered in full or in
  part, 15 rest on one of the owner's earlier answers. The constraints file holds 2; it is
  under four weeks old.
- **Two readers agreed on 21 of 24 entries** re-classed blind (17 of the 20 hand-read
  ones). Where they differed the lower class stands.
- **Cost of the measurement**: ten read-only subagent runs so far, about 2 million tokens (section 1).

**Recommendation: do not build a lookup.** No search command, no index of standing
answers, no `Looked in:` check. Where a doc decided a question, the models had already
read it. What the measurement did find is smaller: two rules that tell a session to file
something a doc has already settled, worth about one entry a month. Whether to change them
is the owner's choice, and section 9 ends with it as one options table.

## 1. Method

**The sample.** `docs/working/questions-archive.md` holds 249 entries and
`docs/working/questions.md` 9, so 258 in all [observed]. By today's route: 203
`you: judgment`, 33 `you: terminal`, 18 `agent`, 3 `trigger`, 1 `deferred`. The brief asks
for the judgment entries, with the older agent and unrouted ones counted apart, so the
sample is **221 entries: 203 judgment and 18 agent**. Nothing was sampled out: every one
of the 221 was classed. 218 are answered; three judgment entries are still open (Q-269,
Q-270, Q-272) and are reported apart, since there is no owner answer to compare with.

Left out: the 33 terminal entries (a paste on the owner's machine, not a question), the 4
watches still in the archive, the 5 entries in `docs/working/watching.md`, and 9 IDs that
are in neither questions file today. Five of the nine (Q-079, Q-097, Q-125, Q-147, Q-168)
were agent items that the migration of 2026-11-01 (aaf10eed) moved to the roadmap; that
commit dropped a sixth, Q-173, as settled by Q-238; three (Q-157, Q-158, Q-159) never
reached either file. Two IDs were reused: Q-186 and Q-241 each first held a different
entry, which is in neither file now [observed].

**Unrouted entries.** Every one of the 221 carried a `Needs:` line in the first commit
that holds its heading, and only one has changed route since (Q-090, filed as `trigger`,
now `agent`). So a table by route at filing would repeat the table by route today. The
entries that were asked with no route are the ten opened before 2026-09-17, when IDs and
routes arrived together (e96912de): Q-001 to Q-005, Q-007 to Q-009, Q-017 and Q-018.
Counted apart, they are: in part 5, none 5 (eight judgment entries, 4 and 4; two agent
entries, 1 and 1).

**The entry's commit.** A python3 pass walked every commit that touched either questions
file, oldest first, and took the first one holding the entry's heading (Appendix C). For
204 of the 221 that commit is the entry's commit. For the other 17:

- 8 entries opened on 2026-09-12 (Q-001 to Q-005, Q-007 to Q-009) got their headings five
  days later. Their commit is bd80e291, the last commit of 2026-09-12 (23:50 -07:00).
- 7 entries were first committed already answered (Q-017, Q-018, Q-113, Q-114, Q-115,
  Q-118, Q-154). Their commit is the parent of that first commit.
- 2 rule-classed entries (Q-186, Q-241) reuse an ID, so the pass found the earlier
  entry's commit. Nothing was read at either.

Docs were read with `git show COMMIT:PATH` and searched with `git grep ... COMMIT`, never
from the working tree. A doc line that only records the entry's own answer never counts.

**Two families were classed by rule, not read one by one** (68 entries), because their
question is fixed by the step that writes them:

- 43 merge entries (slug `merge-` or `merge-gate-`): "merge this branch at this commit?".
  A merge approval is the brief's first example of the owner's by authority.
- 25 attestation entries (slug `other-commit-`): "main holds a commit that is neither a
  gate merge nor a cycle land: have you reviewed it?". Only the owner knows what they
  reviewed.

All 68 were answered with option [1], the default [observed: a regex over the 68 answer
lines]. The second pass re-classed four of them blind and agreed on all four.

**The other 153 were read**, each by one of six independent readers (subagents), in
batches of 23 to 26 by date. Each reader had the entry as it reads today (with the answer),
the entry's commit, and one page of rules. The classes are the brief's four. The rules that
guard against hindsight:

1. The doc must be findable from the question: by a search on words from the question (not
   words that appear only in the answer), or because it is a standing doc every session is
   told to read, or because the entry cites it.
2. Its line must decide the question (in full) or narrow it (in part) without the answer in
   hand. If two careful readers could read the line either way, it is at most "in part". A
   general value that fits only after the fact is "none".
3. The entry's own recommendation or interim is not a doc. It counts only where it quotes
   one, and then the reader finds and quotes that doc.
4. Authority is checked first. The exception: where a doc had already granted standing
   permission for exactly that act, the entry is classed in full or in part and flagged.
5. Torn between two classes, take the lower.

Every "in full", "in part" and conflict carries the doc's path and one line copied from
it. A script then checked each of the first pass's 59 quotes, and the second pass's 8, as
an exact substring of `git show COMMIT:PATH` at the entry's commit: all matched
[observed]. Appendix A lists every hand-read entry with its class and the reason; Appendix
B lists every quote.

Readers also recorded, per entry: the owner's answer in brief, whether it matched the
entry's own recommendation or interim, whether a doc conflicted with it, and whether the
entry re-asked an earlier one. They did not record whether the entry itself named the doc
that bore on it; section 2 has a partial check.

**The second pass.** A seventh reader, with the same rules and none of the first pass's
classes, re-classed 24 entries: 20 drawn from the 153 hand-read ones and 2 from each
rule-classed family, with python3's `random.Random(20261111).sample`. Section 7 has the
agreement. Where the two passes differ, the lower class stands, in the order in full, in
part, none, authority (authority last because it is the class a self-answer may never
touch).

**Changes made in review.** Review round 1 lowered two more entries from in part to
authority (Q-246, Q-247): each is a `stopped-` entry, written by a fixed step with a fixed
question, and the dev-cycle skill reserves its answer to the owner, exactly as with merge
entries. Appendix A marks them.

**What was run.** Read-only subagents only: six first-pass readers and one second-pass
reader (169k to 220k tokens each, 1.28 million in all), three reviewers in round 1 (0.69
million) and a second round still to run. The figures are the totals each run reported when it finished;
no file holds them [observed, not reproducible]. No headless model run, no trial, no
change to any script, skill or questions file. The brief's "no model run only to measure"
is read as ruling out experiments (asking a model to answer old questions and scoring
it); reading and classing the entries is the measurement itself. That reading is this
doc's, and the brief's second pass alone would have needed one reader, not seven.

## 2. The shares

**Judgment entries, answered (200).**

| | In full | In part | None | Authority | Total |
|---|---|---|---|---|---|
| Read one by one | 4 | 35 | 56 | 37 | 132 |
| Merge entries (rule) | 0 | 0 | 0 | 43 | 43 |
| Attestation entries (rule) | 0 | 0 | 0 | 25 | 25 |
| **All** | **4 (2.0%)** | **35 (17.5%)** | **56 (28.0%)** | **105 (52.5%)** | **200** |

Leaving authority out, 95 questions remain that a doc could in principle have answered: 4
in full (4%), 35 in part (37%), 56 not at all (59%).

**The four in full**, with the line that answered each (Appendix B has the paths):

| Entry | The question | The doc line | What had happened |
|---|---|---|---|
| Q-142 | A unit past the review cap: one more narrow fix and merge, or stop? | Q-137's answer in the archive: "merges and review adjustments like this one go ahead on the recommendation without asking." | The session had already merged on its own recommendation, then filed. The second pass put its twin, Q-141, under authority. |
| Q-154 | A full dev cycle every iteration, or a light pass between? | The build-loop plan: "You answered on 2026-10-04: a full cycle every iteration for now ..." | Filed ten days after the owner ruled in session, to put the ruling on record. |
| Q-199 | A 570-line branch was split into three units: keep the split or waive the cap? | Decision log row 62: "In /away mode the agent splits without asking and records the split as an interim in `questions.md` and the commit body's `Notes:` line." | The session split without asking, then recorded the split as that line says. Its commit is titled "Q-199 records the constraints-builder split". |
| Q-254 | A build loop's question: fix the branch before the owner's host paste, or paste now and again later? | `docs/constraints.md`, S10: "at most one host paste per verification" | The loop picked by S10 (a soft constraint) and named it. The pick needed another brief's branch fixed, which a loop may not start, so it ended blocked, and the skill files one entry for each blocked loop. |

So in all four the doc had been read and followed. The entry reached the owner because a
rule said to file it: a line in the decision log (Q-199), the skill's handling of a
blocked loop (Q-254), and the practice of recording an in-session ruling or a merge
already made as an entry (Q-154, Q-142). Q-119, classed in part, has the same shape as
Q-199 under decision log row 61.

**Agent-route entries, counted apart (18).** In full 5, in part 5, none 8. These are not a
rate to rely on. The five "in full" (Q-078, Q-080, Q-089, Q-092, Q-160) are work orders of
the form "implement Q-X's answer": the doc that "answers" them is the owner's answer they
were written from. The readers also differed on how to class a work order with no
question in it (one batch said in full, another none). They are in Appendix A.

**All 218 answered entries together**: in full 9 (4.1%), in part 40 (18.3%), none 64
(29.4%), authority 105 (48.2%).

**The three open entries** (no owner answer to compare, classed on the question alone):

| Entry | Asks | Class | Why |
|---|---|---|---|
| Q-269 | Scope and timing of the deep audit | Authority | The roadmap item's own first step is "the owner confirms scope and timing". |
| Q-270 | A light pass between full dev cycles? | In part | Q-154's answer gives the direction ("once the costs are visible") but not the rule, nor whether unrecorded token costs count as visible. It also asks to replace an answer the owner gave, which another reader might class as authority. |
| Q-272 | When the test-confinement script loses its strong tool: run under the weak one, or refuse? | In part | H2 ("absent verdict or degraded primitive refuses and names what went unenforced") rules out running, unless the owner records an exception. It does not choose between refusing always and refusing unless a flag asks. |

Q-272 is the entry the roadmap item cites as answerable from H2. Read strictly it is "in
part": H2 removes one of three options, and the entry quotes H2 and says so itself. What
H2 leaves is a design choice between two ways of refusing, which a build loop could have
made. So the entry was avoidable, but not by finding H2: by not asking whether to keep
what H2 rules out (the entry itself recommends against keeping it), and leaving the choice
between the two ways of refusing to a loop.

**Did the entry name the doc that bore on it?** The readers did not record this. A
reviewer checked 24 of the in-part judgment entries at their commits: 11 named the doc
the reader credited, and 13 did not (Q-001, Q-018, Q-025, Q-033, Q-041, Q-044, Q-046,
Q-056, Q-070, Q-119, Q-121, Q-172, Q-213) [observed by the reviewer, not re-run]. Among
recent entries, Q-272 names its line and Q-213 does not. So for in-part entries a lookup
would often have told the asker something. It would not have removed the entry: the
owner's answer was needed in all 35.

**Did the owner take the entry's own recommendation?** Among the 132 hand-read judgment
entries, 98 stated a recommendation or held an interim that was one of the options. The
owner's answer matched it in 48 and differed in 50 [observed from the readers' lines].
"Differed" includes an added condition that changed the work, and an interim is a holding
position, not always a prediction, so this is not a count of wrong guesses.

| Class | Matched | Differed | No recommendation |
|---|---|---|---|
| In full | 4 | 0 | 0 |
| In part | 15 | 9 | 11 |
| None | 10 | 30 | 16 |
| Authority (read) | 19 | 11 | 7 |

Where no doc answered, the owner's answer differed from the entry's position in 30 of 40.
That is the population a self-answer must stay out of. Where a doc narrowed the question,
it still differed in 9 of 24.

## 3. By route and by month

**By route today** (answered entries).

| Route | In full | In part | None | Authority | Total | In full or in part |
|---|---|---|---|---|---|---|
| `you: judgment` | 4 | 35 | 56 | 105 | 200 | 19.5% |
| `agent` | 5 | 5 | 8 | 0 | 18 | 56% |
| All | 9 | 40 | 64 | 105 | 218 | 22% |

Route at filing differs for one entry only (section 1), and the ten entries asked before
routes existed are counted apart there.

**By month opened**, judgment entries (answered).

| Month | In full | In part | None | Authority | Total | In full or in part |
|---|---|---|---|---|---|---|
| September | 0 | 19 | 43 | 6 | 68 | 28% |
| October | 3 | 16 | 12 | 79 | 110 | 17% |
| November (to the 10th) | 1 | 0 | 1 | 20 | 22 | 5% |

Agent-route entries by month: September 13 (in full 4, in part 4, none 5), October 5 (1,
1, 3), November none.

September's questions were mostly new design and policy calls with no doc to lean on (43
of 68 "none"). October's were mostly authority: the build-loop handoff's landing and cap
asks, then the attestation and merge entries. The count answered in full never rose above
3 in a month.

**By week opened**, all 221 in-scope entries, by family [observed].

| Week of | Judgment, hand-written | Agent | Merge | Attestation |
|---|---|---|---|---|
| 09-07 | 6 | 2 | 0 | 0 |
| 09-14 | 28 | 1 | 0 | 0 |
| 09-21 | 25 | 5 | 0 | 0 |
| 09-28 | 13 | 8 | 0 | 0 |
| 10-05 | 23 | 0 | 0 | 0 |
| 10-12 | 26 | 2 | 5 | 13 |
| 10-19 | 3 | 0 | 5 | 12 |
| 10-26 | 6 | 0 | 20 | 0 |
| 11-02 | 2 | 0 | 12 | 0 |
| 11-09 (two days) | 3 | 0 | 1 | 0 |

Hand-written judgment entries fell from 13 to 28 a week to 2 to 6 a week in the week of
2026-10-19: 23 a week on average over the five full weeks to 10-12, then 14 in 23 days.
Four things changed in the two weeks before: the constraints file reached main (83b653d2,
2026-10-15; in its present form from 2620b419 on 2026-10-19); the orchestrator dispatched
its first build loops (2026-10-17), whose prompt carries the constraints and tells them to
decide a design choice themselves when one option dominates; the repo went to self-merge
(2026-10-17); and the large hand-run build-loop work, the source of most of October's
landing and cap asks, ended. Which did how much, these numbers cannot say [inferred].

**Since 2026-10-19**, the 14 hand-written judgment entries: in full 2 (Q-199, Q-254), in
part 4 (Q-213, Q-238, and the open Q-270 and Q-272), none 4 (Q-221, Q-223, Q-226, Q-256),
authority 4 (Q-200, Q-246, Q-247, and the open Q-269). Three of the 14 began as a build
loop's marker and were filed by the orchestrator (Q-246, Q-247, Q-254). Merge entries, 38
in the same period, are now the bulk of what the owner is asked.

## 4. Which docs held the answers

For the 39 judgment entries answered in full or in part (answered entries only):

| Kind of doc | In full | In part | Total |
|---|---|---|---|
| An earlier answer of the owner's, in the questions files | 1 | 14 | 15 |
| The brief, plan, audit or proposal the question came from | 1 | 5 | 6 |
| A decision record (`docs/decisions/NNN-*.md`) | 0 | 5 | 5 |
| The decision log (`docs/decisions/log.md`) | 1 | 4 | 5 |
| Another working doc (the 2026-09-17 triage, a workflow file) | 0 | 3 | 3 |
| The owner's notes and answer files (`docs/human-author/`) | 0 | 2 | 2 |
| The constraints file (`docs/constraints.md`) | 1 | 1 | 2 |
| The global instructions | 0 | 1 | 1 |

The two open "in part" entries add one earlier answer (Q-270) and one constraints line
(Q-272). The 10 agent-route entries add 7 earlier answers, and one each from the decision
log, a decision record and a proposal.

- **Earlier answers lead, and they are mostly the last answer in the same thread of
  work.** Q-081 leans on Q-070's answer of the same day, Q-063 on Q-059's of hours
  before, Q-093 on Q-091's. A lookup here would mostly have meant "re-read the owner's
  last answer on this topic".
- **The constraints file is thin in this table because it is young.** It existed for the
  last 15 hand-written entries only (Q-194 and the 14 since 2026-10-19), and bears on 3
  of them (Q-213, Q-254, Q-272).
- **The repo rules (`CLAUDE.md`) answered nothing.** They are coding rules, and no entry
  asked about one.

## 5. Where the doc and the owner's answer disagreed

Five entries are flagged as conflicts, four of them judgment entries. These are the cost
of answering from docs: a model trusting the doc would have done something the owner did
not want.

| Entry | The doc said | The owner said | Stale, or a change of mind? |
|---|---|---|---|
| Q-040 | The global instructions: on a misframing signal inside divergent design, run the `design-space-situating` skill | Divergent design's own Double Diamond first; that skill only if it fails | Two docs disagreed: the divergent-design workflow already pointed to its Double Diamond. The global instructions were the stale one, and were rewritten after the answer. |
| Q-068 | The 2026-09-17 triage marked "keep the self-improvement loop and resume it" as Drop | Resume: "this was the intent all along" | Neither: the doc was an agent's analysis and was wrong about the owner's intent. |
| Q-069 | Decision 034 rejected scanning `.git` for dangerous config keys ("the next one will be missed too") | Scan `.git` at session exit | The decision was scoped to the benchmark harness; the owner decided differently for the container launcher. (A later review found the scan could not be a guarantee, which is what 034 had argued.) |
| Q-152 | The build-loop plan's default: when every thread waits on the owner, poll every 20 to 30 minutes | Stop the loop | A change of mind on a default the plan itself had flagged as unconfirmed. |
| Q-027 (agent route) | Decision 023 named two archived docs as "the procedure for a bare host install" | The work replaced them with a new guide | Stale. |

How to count them depends on two choices, so the range is given:

- **Docs that contradicted each other.** Q-040's question was itself "two docs disagree,
  which wins?". Five more entries have that shape and are not flagged, because the readers
  counted neither side as an answer (Q-024, Q-028, Q-029, Q-039, Q-043). Treating Q-040
  like them gives 3 judgment conflicts; treating them like Q-040 gives 9. Either way, six
  judgment entries exist only because two docs disagreed, and a lookup that reads only one
  of the two can return the wrong one.
- **Authority entries.** Three of them carry the same warning in their notes: the doc as
  written pointed to the option the owner then replaced (Q-087: decision 031's "k=1"
  became k=3 on the final pass; Q-140: the approved plan's trust root was changed; Q-153:
  the owner narrowed their own global rule on branch deletion). No self-answer would have
  touched them. Counting them gives 7.

On the bar the "in full" class had to pass (the line must decide the question for a
careful reader), the count is lower. Three of the four flagged docs would not have looked
deciding: an agent's analysis, a decision scoped to another subsystem, a default flagged
as unconfirmed. Q-040's instruction was plainly worded, but the entry itself cited the
workflow that disagreed with it. So against 4 entries a doc decided, at most 1 was a
misdirection of the same strength. The looser count of 4 is the one to plan against,
because a model under no rule would not make these distinctions.

Soft constraints mislead too. Among the last 14 entries, Q-254's loop picked by S10 and
matched the owner, and Q-256's loop read S5 as favouring a later pass and the owner chose
to build now: one right, one wrong.

## 6. Re-asks

31 of the 221 entries re-ask an earlier one [observed from the readers' lines].

- **24 belong to the build-loop handoff's landing and cap asks**, 2026-10-05 to
  2026-10-30: "may this unit land", "waive the size cap", "allow a fourth review
  iteration". By the readers' links they are three threads (19 trace back to Q-100, 3 to
  Q-134, 2 to Q-095). 17 of the 24 are authority: at each of those commits the docs
  reserved the act to the owner (decision log row 62: "only the user can waive the cap";
  the review-fix-loop workflow: "only their explicit authorization permits iteration 4"),
  and each earlier answer was for that unit only. A lookup would have confirmed "you must
  ask" every time. The standing instruction in Q-137's answer (2026-10-09) did not end
  them: 10 of the 24 came after it.
- **7 are single follow-ups**: Q-048 (of Q-035), Q-063 (of Q-059), Q-093 (of Q-091),
  Q-124 (of Q-081), Q-226 (of Q-223), Q-247 (of Q-246), and the open Q-270 (of Q-154).

By class the 31 are: in full 2, in part 10, none 1, authority 18. The two in full are
Q-142, settled by an earlier answer, and Q-199, settled by the decision log. All 10 in
part rest on an earlier answer.

The merge and attestation entries are serial by construction (one per branch, one per
commit) and are not counted as re-asks here; the second reader did link them to the first
of their kind.

## 7. The second pass

| Sample | Entries | Same class | Agreement | Cohen's kappa |
|---|---|---|---|---|
| All re-classed | 24 | 21 | 88% | 0.82 |
| Hand-read only | 20 | 17 | 85% | 0.78 |
| Rule-classed only | 4 | 4 | 100% | |

On the coarser question, "did any doc answer this in full or in part?", the two passes
agree on 22 of 24.

The three disagreements, and what stands:

| Entry | First pass | Second pass | Stands | The difference |
|---|---|---|---|---|
| Q-141 | In full | Authority | Authority | Whether Q-137's "merges and review adjustments like this one go ahead on the recommendation" covers a landing past the review cap. |
| Q-145 | None | Authority | Authority | Whether a trade between merging over a flaky gate and fixing it first is a design call or an owner-only act. |
| Q-256 | None | In part | None | Whether the owner's September note on the proposal filter's shape also leaned on its timing. |

All 24, with both classes:

| ID | Family | First pass | Second pass | Stands |
|---|---|---|---|---|
| Q-020 | read | NONE | NONE | NONE |
| Q-028 | read | NONE | NONE | NONE |
| Q-038 | read | PART | PART | PART |
| Q-039 | read | NONE | NONE | NONE |
| Q-047 | read | NONE | NONE | NONE |
| Q-052 | read | PART | PART | PART |
| Q-059 | read | NONE | NONE | NONE |
| Q-081 | read | PART | PART | PART |
| Q-088 | read, agent route | NONE | NONE | NONE |
| Q-089 | read, agent route | FULL | FULL | FULL |
| Q-093 | read | PART | PART | PART |
| Q-102 | read | NONE | NONE | NONE |
| Q-111 | read | AUTH | AUTH | AUTH |
| Q-115 | read | AUTH | AUTH | AUTH |
| Q-141 | read | FULL | AUTH | AUTH |
| Q-145 | read | NONE | AUTH | AUTH |
| Q-150 | read | PART | PART | PART |
| Q-151 | read | PART | PART | PART |
| Q-187 | rule: attestation | AUTH | AUTH | AUTH |
| Q-198 | rule: merge | AUTH | AUTH | AUTH |
| Q-208 | rule: attestation | AUTH | AUTH | AUTH |
| Q-221 | read | NONE | NONE | NONE |
| Q-228 | rule: merge | AUTH | AUTH | AUTH |
| Q-256 | read | NONE | PART | NONE |

What this says about the tables above:

- **The classes are a judgment and about one entry in seven would move** under a second
  reader (3 of 20). Applied to the 153 hand-read entries, that is some 23 entries.
- **The moves do not all go one way.** One lowered "in full", one raised "none" to "in
  part", one moved between the two classes no doc can answer. There is no sign that the
  first pass over- or under-counts the answerable share.
- **The boundary between none and authority is the softest.** The six first-pass readers
  also drew it differently: one classed a change to a recorded decision as authority,
  another classed a change to an enforcement hook's scope as none. Of three entries that
  ask to revisit a recorded answer, one is authority (Q-104) and two are in part (Q-105,
  Q-270).
- **One reading carries five entries.** Q-138, Q-142, Q-143, Q-144 and Q-148 rest on the
  same standing-instruction line as Q-141. If the second reader's reading of Q-141 were
  carried to them, "in full" would be 3 and "in part" 31. Only Q-141 was in the sample, so
  only Q-141 was lowered.

## 8. What the measurement says

1. **Most asks were for permission, not information**: 105 of 200. A lookup is barred
   from them by the roadmap item's own guardrail. Only one family clearly ended by a rule
   change (the attestation asks, row 74). The landing and cap asks ended with the hand-run
   work that produced them [inferred], and merge approvals continue.
2. **Of the 95 asks for information, most had no doc**: 56. They were new design and
   policy calls, and where the entry took a position the owner's answer differed from it
   in 30 of 40.
3. **Where a doc narrowed the ask (35), the owner's answer was still needed**: to pick
   among what was left, to confirm a default the plan had flagged as unconfirmed, or to
   say whether an earlier answer reached this far. About half of those checked did not
   name the doc, so a lookup could have made some of these entries shorter or better
   informed. It would have removed none.
4. **Where a doc decided the ask (4), the session had already followed it.** What reached
   the owner was a record, filed because a rule said to file it. The avoidable entries in
   this class come from filing rules, not from missing lookups.
5. **Docs mislead and contradict each other** often enough to matter: 4 flagged conflicts
   and 6 doc-against-doc entries, against 4 entries a doc decided.
6. **The volume has already fallen** to 2 to 6 hand-written judgment entries a week, for
   reasons these numbers cannot separate.

So, at today's volume, a lookup would remove no entry and might shorten about one a week.
Changing the filing rules behind the "in full" entries would remove about one a month.
Both are small. The plan in section 9 starts from there.

## Research notes

These notes and the appendices are for agents; the plan and the owner's choice follow them.

### What exists

- `docs/working/questions.md` and `docs/working/questions-archive.md`: one `### Q-NNN ·
  slug` block per entry, with `**Needs:**`, `**Opened:**` and `**Status:**` on its second
  line, an options table, and the answer recorded inline when given. `scripts/questions.sh`
  maintains them (`check`, `index`, `archive`, `next-id`, `open`, `migrate`, `init`); it
  has no search command. The archive's generated index already carries a one-line summary
  of each entry, answer included. [observed]
- The orchestrator (the dev-cycle skill) is the only writer of the questions files inside
  the cycle. Build loops never write them: a loop's question arrives in the body of its
  `handoff: blocked` marker, or of its `handoff: ready` marker after a tentative pick. For
  a blocked or stopped loop the skill files one entry and re-dispatches only on its answer
  (`skills/dev-cycle/SKILL.md`, "The only questions writer" and step 7). [observed]
- The build-loop prompt (`scripts/build-loop.sh`, the dispatch text) quotes
  `docs/constraints.md` in full and tells the loop to run divergent design for a choice
  with three or more options: decide when one dominates, go on with a tentative pick when
  none does, end blocked only when no option survives the hard constraints or the answer is
  a fact only the owner has. It also forbids a loop to start other loops or touch another
  brief. [observed]
- Four standing lines tell a session to record a split in the questions file: decision
  log rows 61 and 62, `workflows/pr-prep.md` (step 1a) and `workflows/review-fix-loop.md`
  (the early split trigger and the size re-check): "split without asking and record the
  split as an interim in `docs/working/questions.md` and in the commit body's `Notes:`
  line". Since decision 040 (2026-10-28) that file holds only what is blocked on the
  owner. [observed]
- The global instructions' "Running questions document" section already says: "Before
  routing to `you: judgment`, check the item actually needs a human". It does not say what
  to check against. It also says a question is filed with its interim choice and work goes
  on ("Append, don't block"). [observed]
- The weekly digest (step 9 of the skill) has an ask counter: asks opened and answered,
  and how often the owner picked the default. Two trial sets govern how the cycle writes
  (`docs/working/trials/2026-10-30-friction-engagement.md`, kept, and
  `docs/working/trials/2026-11-06-attention-and-trust.md`, running to about 2026-11-13).
  A trial changes only how the cycle writes; the running trial doc sets aside anything
  that "needs gate code". [observed]
- The dev cycle's revisit step reads `## Revisit triggers` sections of decision records
  and decision-log rows. It does not read a working doc such as this one. [observed]
- Where each candidate home for a lookup sits, for cost: `scripts/build-loop.sh`,
  `scripts/questions.sh` and `skills/dev-cycle/` are gate code, `workflows/` is on this
  repo's never-self-merge line, and the global instructions are an instruction file. A
  change to any of them goes to the owner as a merge entry. `docs/constraints.md` and
  `docs/decisions/` are the owner's and the cycle's records. [observed]

### Invariants

- This unit changes two files only: this doc, and the brief's status line (the brief's
  `Paths:` line; the gate checks it).
- The questions files, `docs/working/watching.md`, the roadmap and `docs/dev-cycle.md`
  belong to the dev cycle. The options table at the end is for the cycle to file.
- Archived entries are read, never corrected. Where an entry was rewritten after filing
  (Q-149, Q-221), Appendix A says so.

### Prior art

- `docs/working/research-2026-11-06-merge-friction-design.md` sampled the 37 merge entries
  filed from 2026-10-14 to 2026-11-06, found all 37 answered with the default, and still
  decided to change nothing: the owner said they follow the work through these answers. It
  also notes that a 100% default rate fits "the owner has stopped reading" as well as "the
  loops are good". This doc's merge family (43, to 2026-11-10) agrees with it.
- `docs/working/research-2026-11-10-cycle-overhead-numbers.md` is the model for a
  measurement unit of this shape (layout, the review, the options table for the cycle to
  file).
- Decision 040 (`docs/decisions/040-questions-doc-owner-only.md`) and
  `docs/working/triage-2026-09-17-backlog.md` section 3 are the earlier passes over the
  questions doc: both sorted entries by who must act, neither asked whether a doc already
  held the answer.
- No earlier doc classes entries against the docs of their day.

### Gotchas

Failure-pattern grep: FP-088, FP-108, FP-110, FP-114, FP-153 (see Prior failures)

The grep was `grep -inE 'under-?count|denominator|hindsight|sampl|questions\.sh|questions-doc|questions-archive|pickaxe|filing-commit|git-log--S|classif|instrument|stale-doc|self-answer' docs/failure-patterns.md`.
It also matched FP-077, FP-078 and FP-099 (wrong denominators in scoring and billing code;
the same lesson as FP-110) and FP-176 (a trigger that counted its own output; nothing here
feeds on itself).

- The first commit holding an entry's heading is not always the commit that asked the
  question: 8 in-scope entries got their headings five days after they were opened, 7 were
  committed already answered, and 2 IDs were reused (section 1). The pass keys on the ID
  alone, so a reused ID finds the earlier entry.
- The extraction script first read the route at filing from `questions.md` only, and so
  reported 14 entries as unrouted that had been committed straight into the archive with a
  route. A reviewer caught it; section 1 has the corrected statement.
- Entry text is read as it stands today. Two entries were rewritten after filing (Q-149
  with a wider interim, Q-221 with a new option after the owner's notes); the readers
  classed against the filed state where they noticed. Q-181 to Q-185 now read `Opened:
  2026-10-17` and were filed as 2026-10-15.
- The constraints file and the repo rules reached main on 2026-10-15 at 22:05 (83b653d2),
  after the ten hand-read entries opened that day, and were revised on 2026-10-19
  (2620b419, "Project constraints doc").
- An `Answered` line in an agent-route entry often records work done, not an answer.
- `git grep` at an old commit searches that commit's tree, but a path that did not exist
  then prints nothing rather than failing; the quote check uses `git show`, whose failure
  is loud.
- `git rev-list --before=DAY` depends on the machine's time zone: bd80e291 was committed
  at 23:50 -07:00, which is the next day in UTC.

#### Prior failures

- FP-108, FP-110, FP-114 (a count summed what produced output, so failures left the
  denominator): every table here states its denominator (258 in the files, 221 in scope,
  218 answered, 200 judgment, 132 read), and the entries left out are listed in section 1.
- FP-153 (counts written from recollection): the numbers in sections 1 to 7 are printed by
  the analysis script from the readers' result files, and a reviewer recounted them from
  Appendix A.
- FP-088 (agreement overstated by counting replicates): the second pass is one independent
  reader on 24 entries, reported as 21 of 24, with the 4 rule-classed entries shown
  separately so they do not pad the rate.

### Design choices

The brief's own lines are the hard constraints for the measurement choices: the classes,
the entry's commit, the hindsight guard, the blind second pass, no model run only to
measure. H1 to H4 concern gates and tests and bear on none of D1 to D5. Options are pruned
only on the brief's lines or on a plain fact; soft constraints only rank. D6, where a
lookup would live, is section 9's divergent-design pass.

**D1. How much of the sample to read** (divergent design, Path A: one option dominates).

| Candidate | Brief's lines | Notes |
|---|---|---|
| A. Every in-scope entry | passes; the brief's first choice | 221 entries, 153 of them read; needs parallel readers |
| B. Every Nth entry | passes, as the brief's fallback | by-month and by-route cells get too thin to report (S7, measure before budgeting, wants the real figure) |
| C. The last 80 | passes, as the fallback | 65 of the last 80 by ID are merge or attestation entries, so it would measure almost nothing |
| D. Rule-class everything by slug | fails: the hand-written entries have free slugs | |

Pick: A. It is feasible, and it is what the brief asks for when feasible.

**D2. Which commit's docs to read, when the heading was committed late** (Path A).

| Candidate | Brief's lines | Notes |
|---|---|---|
| A. The first commit holding the heading, always | fails for 15 entries: that commit can already hold the answer, or be five days late | |
| B. The last commit before the `Opened:` day began | passes | too early: it drops docs written the same day, which the asker had |
| C. The last commit of the `Opened:` day for the 8 early entries; the parent of the first commit for the 7 committed already answered | passes | the early commit can include an answer's own edits, so "a line that only records this entry's answer never counts" was made a rule, and one reader re-checked the 2026-09-12 batch against the earlier state |

Pick: C. B loses real docs; C's risk has a named guard.

Other choices, one line each:

- D3, the merge and attestation entries: classed by rule from the slug, with four checked
  blind by the second pass, because the step that files them fixes the question. Review
  round 1 extended the same rule to the two `stopped-` entries.
- D4, the second-pass sample: 20 from the hand-read entries plus 2 from each rule-classed
  family, not 20 from all 221, so that the blind check falls on judgment calls and still
  touches both rules. This is 4 more than the brief asks for.
- D5, "the lower class stands" when one class is authority: authority is ordered last. It
  affects Q-145 only, and no answerable share.
- D7, six first-pass readers by date, not one: one reader could not hold 320 kB of
  entries and the docs of nine weeks; batches by date let each reader reuse the docs of
  one period.
- The agent-route entries are reported apart and not re-classed for consistency: the brief
  says to count them apart, and they are not owner questions.
- Where the plan sits: last in the file, ending with the owner's table, as the brief says.

### Plan and verification

No plan doc: the brief names this file as the only deliverable. Steps taken: extract the
entries and their commits by script, class the rule families, brief six readers and one
blind second reader, check every quote against git, tabulate, write, review, fix. No code
or behaviour changes, so no tests were written and `test-strategy` was not run.
Verification is the quote check, the second pass, Appendix A (from which every tally can
be recounted), and the review rounds below.

| Failure mode | Guard |
|---|---|
| A reader credits a doc that was written after the question, or because of its answer | docs read only at the entry's commit; every quote checked as a substring of the file at that commit (59 of 59) |
| A reader stretches a class because they know the answer | five written rules, "take the lower" among them; a blind second reader on 24 entries; the lower class stands |
| A tally drops entries without saying so | section 1 lists every exclusion; each table states its total |
| The doc stretches a small share into a case for building | the summary leads with 2%; the plan's tentative pick is to build nothing |
| The plan picks for the owner | section 9 ends with one options table and marks its pick as tentative |

`/pre-mortem` and `/architecture-review`: not triggered (one docs file, no trust boundary,
no module change). Rollback: `git revert -m 1` of this branch's merge commit; the change is
two docs files, nothing installed and no state.

### Review

Pending: written after the review rounds.

## Files read

Last verified: 2026-11-11

docs/working/briefs/2026-11-11-self-answer-measure.md
docs/working/questions.md
docs/working/questions-archive.md
docs/working/watching.md
docs/constraints.md
docs/roadmap.md
docs/dev-cycle.md
docs/failure-patterns.md
docs/decisions/log.md
docs/decisions/040-questions-doc-owner-only.md
docs/decisions/ (records, at each entry's commit)
docs/human-author/ (at each entry's commit)
docs/working/research-2026-11-06-merge-friction-design.md
docs/working/research-2026-11-10-cycle-overhead-numbers.md
docs/working/briefs/closed/2026-11-10-cycle-overhead-numbers.md
docs/working/trials/2026-10-30-friction-engagement.md
docs/working/trials/2026-11-06-attention-and-trust.md
docs/working/feedback/philosophy-research.md
docs/working/cycles/cycle-2026-11-11.md
docs/working/plan-build-loop-handoff.md (at the entries' commits)
docs/working/triage-2026-09-17-backlog.md (at the entries' commits)
global-instructions/CLAUDE.md
CLAUDE.md
skills/dev-cycle/SKILL.md
scripts/build-loop.sh
scripts/lib/dev-cycle-read.sh
scripts/questions.sh
workflows/research-plan-implement.md
workflows/divergent-design.md
workflows/pr-prep.md
workflows/review-fix-loop.md

## Appendix A: every hand-read entry

The 153 entries read one by one, in ID order. Route: J is `you: judgment`, A is `agent`.
Class: FULL is in full, PART in part, NONE none, AUTH authority. "Rec." says whether the
owner's answer matched the entry's own recommendation or interim (`none`: the entry gave
none; `n/a`: still open). The last column is the reader's reason, with flags first.

The 68 rule-classed entries are not in the table. All are `you: judgment`, authority,
answered [1]:

- Merge entries (43): Q-163, Q-164, Q-195, Q-197, Q-198, Q-216 to Q-220, Q-224, Q-225,
  Q-228 to Q-233, Q-235 to Q-237, Q-239 to Q-245, Q-248 to Q-251, Q-253, Q-257 to Q-260,
  Q-263, Q-265 to Q-268, Q-271.
- Attestation entries (25): Q-181 to Q-193, Q-201 to Q-212.

| ID | Opened | Route | Class | Owner's answer | Rec. | Why this class |
|---|---|---|---|---|---|---|
| Q-001 | 09-12 | J | PART | Yes, fatal: collect every missing source and exit 1. | no | Decision 017 had already rejected warn-and-continue for a loud nonzero exit in the test runner (same phrase as the question), which names the direction by precedent but is about another script, not the payload assembly. |
| Q-002 | 09-12 | J | NONE | Yes; shipped the one-line read fallback so EOF prints the Aborted line. | no | No doc on that commit speaks to how the bless prompt should behave on a closed stdin; it was a small behaviour call the session settled the same day. |
| Q-003 | 09-12 | J | PART | Correctly out of scope on substance; heading renamed, rule body exempt. | yes | The audit's own F3 evidence row lists the markers that define the finding, and the exemption was derived by checking the fourth block against them, but the audit did not itself say the block was excluded or settle the heading rename. |
| Q-004 | 09-12 | J | NONE | Won't fix; split stays unless the token cost becomes a measured problem. | yes | Whether 19 links of churn are worth a one-path token saving is a cost call no decision record or audit line on that commit settles. |
| Q-005 | 09-12 | A | NONE | Done by the agent: one helper now owns the concat idiom. | no | An agent-routed refactor the filing loop closed by doing it; no doc on that commit carries a rule on duplicated test setup. |
| Q-007 | 09-12 | J | NONE | Moot by scope; the pre-flight warning stands, harness not run here. | yes | The scope ruling that answers it (log row 48, benchmark harness out of this repo) was written by the same owner-directed answer that closed this entry, and nothing earlier scoped the harness out. |
| Q-008 | 09-12 | A | PART | Done by the agent: lite-review.py owns the grammar, with contract tests. | yes | Log row 48, written in the commit that filed this to-do, already states the grammar must be owned by lite-review.py before the harness moves; it is the session's own reasoning in the log, so it names the default rather than independently answering. |
| Q-009 | 09-12 | J | NONE | [2]: add the installed-ness test and skip the gate on comment-only diffs. | no | Log row 45 and decision 035 describe the gate and name the finding a prerequisite but say nothing on testing installed-ness or exempting comment-only diffs; narrowing a recorded gate could also be read as the owner's by authority. |
| Q-017 | 09-17 | J | PART | Measurement untrustworthy (hooks under-count); finding withdrawn as evidence. | none | The owner's own April note under the same hypothesis ID (H-01) already said the usage hook probably misses RPI reads, which is the answer's substance, but it was low-confidence and five months and several hook fixes old. |
| Q-018 | 09-17 | J | PART | Backfill; done, 164 entries harvested from the fix commits. | none | Decision 013 had chosen to preserve the failure-pattern library over deprecating it, which names backfill as the default, but its own revisit trigger (the loop visibly decays) had fired, so the record does not settle the re-ask. |
| Q-020 | 09-17 | J | NONE | Unit stands; promote the decision-card pattern into the global instructions. | yes | The only doc on the asks unit was the same-day triage draft that raised the question, and the owner answered a larger question (promote the format) that no doc anticipated. |
| Q-021 | 09-17 | J | NONE | Archive: archive is usually preferred over delete. | no | No standing archive-over-delete rule existed on that commit; the only text on DROP was the triage draft that filed the question and proposed deletion. |
| Q-022 | 09-17 | J | NONE | [2]: skip pipe-less lines; a lite-review attestation means almost nothing. | no | The answer turns on the owner's view that a clean lite review attests to nothing, which decisions 030/031 and log row 37 on the lite path do not state. |
| Q-023 | 09-18 | J | NONE | Run the fast suites first, block on red, then run slow. | no | No doc on that commit sets what the health check's bats gate must cover or trades its runtime against coverage; the owner's staged answer was not among the listed options. |
| Q-024 | 09-18 | J | NONE | Fix: add market-sizing to draft-review; it was a logical gap. | none | The question is a contradiction between two skill files, and no decision record, log row or guide says which side is intended (the sibling critics being wired is inference, not a stated rule). |
| Q-025 | 09-18 | J | PART | [1]: installed path, README links scripts; consolidate; keep no --bare. | none | Log row 23 (decision 023) had put scripts/ in the installed payload, which makes the installed path the default, but no doc covers the bare-host README gap or the questions.sh path resolution the answer also changed. |
| Q-026 | 09-18 | J | NONE | [1]: project .claude settings/hooks are SOFT for file tools; Bash still denies. | no | No doc sets the guard's tier for a project's own .claude files; the one related record the entry cites (log row 53, a different hook's gaps accepted as risk) would by analogy have suggested accepting, which the owner did not choose. |
| Q-027 | 09-18 | A | NONE | Done by the agent: new tracked bare-host wiring guide; README and 023 repointed. | yes | Conflict. An agent-routed fix; decision 023 still named the archived wire docs as the bare-host procedure, so the doc was stale and read plainly pointed at restoring them rather than at the new guide that replaced them. |
| Q-028 | 09-18 | J | NONE | Either; row 1 now fires only when neither thoughts dir nor onboarding doc exists. | none | A mismatch between the decision-tree row and the onboarding workflow with no doc saying which side should move; the owner had no preference. |
| Q-029 | 09-18 | J | NONE | [1]: Macro x Cold is Low; escalate for large data or latency-sensitive paths. | none | Two paragraphs of the same skill disagree and no decision record or log row sets a severity for cold-path algorithmic findings. |
| Q-030 | 09-18 | J | NONE | [2]: use the security review, cite its commit, label it possibly stale. | none | No doc on that commit says how one review skill should treat another review's stale output; the general doc-freshness guidance does not pick between skipping and labelling. |
| Q-031 | 09-18 | J | NONE | [1]: Disputed and Secondary-only both map to amber. | none | No decision record or log row assigns a rubric tier to these two fact-check verdicts; the gap is inside the skill the question is about. |
| Q-032 | 09-18 | J | NONE | [2]: self-eval is repo-only; stop with a clear message without the rubric. | none | No doc says whether self-eval is meant to work outside this repo; the one guide that mentions it calls it standalone, which does not decide ship-versus-scope. |
| Q-033 | 09-18 | J | PART | [1]: archive it under archive/docs. | none | The triage doc's ARCHIVE route (amended by the earlier archive-not-delete answer) makes archiving the default for an artifact with no consumer, which this never-loaded file is, but it leaves the build-it-out alternative to the owner. |
| Q-034 | 09-18 | J | NONE | [2]: README setups link global-instructions (plus skills, patterns, guides). | none | No doc on that commit says how non-Claude tools should receive the debugging defaults or whether inlining a copy is acceptable. |
| Q-035 | 09-18 | J | NONE | [1]: Bash HARD only for the global file; a bare CLAUDE.md is SOFT. | no | A security-hook scope trade-off; the cited security review and decision 023 describe the existing Bash hard-deny but neither says whether a project-level file should get it. |
| Q-036 | 09-18 | J | NONE | [2] gitignore the per-round review archive; it stays a local-only corpus | none | No doc said whether the self-improvement loop's per-round review archive should be committed or ignored; the nearest thing is a .gitignore comment and a triage aside that other loop output is local scratch, which is precedent by analogy only. |
| Q-037 | 09-18 | J | NONE | [3] delete the dead survivors carry-over feature | none | No decision record, log row or owner note mentions the survivors carry-over or says whether a silently dead loop feature should be revived or removed. |
| Q-038 | 09-18 | J | PART | [2] Path C files a questions.md entry; redirect other morning-summary references too | none | The standing instructions already named questions.md as the channel for user questions from overnight runs, which is the owner's pick, but decision 012 at the same commit called the morning summary the loop's single output channel, so the doc names the default without ruling out building the summary consumer. |
| Q-039 | 09-18 | J | NONE | Neither as posed: High needs a deep-read, abstract-only caps at Medium; say when to deep-read | none | The contradiction is inside the fact-check skill itself and no decision record or log row sets the abstract-only confidence rule; the owner's one related note (abstract and deep-read carry different confidence) fits either option. |
| Q-040 | 09-18 | J | NONE | [2] Double Diamond owns misframing; fall back to design-space-situating only if it fails | none | Conflict. The standing instructions (and AGENTS.md) told sessions to run design-space-situating on a DD misframing signal, which is option [1]; the owner chose the Double Diamond first, so the doc was stale against the owner's intent and was rewritten after the answer. |
| Q-041 | 09-18 | J | PART | [1] with a condition: only ambers lacking a discoverable TODO or revisit trigger count | none | The review-fix-loop and pr-prep workflows already let acknowledged ambers pass, which points to counting only unannotated ambers, but the owner's condition on what a qualifying note must contain was written nowhere. |
| Q-042 | 09-18 | J | NONE | [1] add an explicit contextual-critic severity mapping row | none | No decision record covers the executable-defect channel or gives contextual critics a native severity mapping; decision 028 only records the older advisory cap, which does not choose between the two options. |
| Q-043 | 09-18 | J | NONE | [1] a saved skip note satisfies rule 1(a) | none | The only docs bearing on it are the two skill passages whose disagreement is the question (the critic's skip path and the ladder's 'otherwise skipped' wording); nothing outside them settles which wins. |
| Q-044 | 09-18 | J | PART | [1] yes, orchestrator may auto-append with a new Accepted-immutable verdict | none | Decision 031 (and log row 32) had already made the override log the home for immutable-history findings, which rules out option [2]'s rubric-note route, but it does not say the orchestrator itself writes the row mid-run or what verdict value it carries. |
| Q-046 | 09-18 | J | PART | [2] delete it; carried out as a move to archive/ per Q-021 | none | The triage doc the global instructions cite routes an artifact with no consumer to ARCHIVE (a move, per the Q-021 answer), which names disposal as the default for a script nothing calls, but it is a proposal route for ledgers and does not rule out fixing a script with wrong output. |
| Q-047 | 09-18 | J | NONE | [1] add a Run column to the hypothesis log | no | No doc addresses identifying which loop run a hypothesis-log row belongs to; this was a schema choice with nothing written about it, and the owner picked against the interim. |
| Q-048 | 09-21 | J | PART | [2] exempt worktree paths; later withdrawn after three review passes found bypasses | no | Re-ask of Q-035. The owner's Q-035 and Q-026 answers three days earlier had set the lean (hard-deny only global files, project paths soft, narrow further if the over-block annoys), which points away from keeping the rule but does not choose between the worktree exemption and path-position matching. |
| Q-050 | 09-21 | J | NONE | [2] deny is intended; deprecate symlinks for blessed copies via install.sh | no | Earlier guard answers treat the checkout's global instructions as a global-tier path, which fits keeping the deny, but the substance of the owner's answer (the repo copy should be the one editable file, replace symlinks with blessed copies) was written nowhere. |
| Q-051 | 09-23 | J | NONE | [1] drop both fronting lean entries | no | No doc weighed fronting risk against the two lean hosts; log row 51 only records adding them before fronting was known, and the owner dropped them against the interim. |
| Q-052 | 09-23 | J | PART | [1] accept the residual and keep both Google Maven names | yes | Log row 19 had already recorded the whole Google front-end surface as an accepted risk of the android profile, which is the same exposure the fronting test confirmed, but that acceptance predates the SNI proxy that was expected to narrow it, so a reader could fairly re-ask. |
| Q-054 | 09-23 | J | AUTH | [2] plain run offers every target; taken as plan approval | no | The entry asks the owner to approve this particular plan at the plan gate before any code is written; the shape choice bundled with it turned on the owner's own habit (forgetting flags), which no doc held, and went against the research's 70% pick. |
| Q-055 | 09-23 | J | NONE | [2] no longer uses Gemini; drop it | no | Whether the owner still uses Gemini is a fact about the owner that no doc held; the Q-034 answer three days earlier had kept the Gemini setup in the README, which if anything suggested the opposite. |
| Q-056 | 09-23 | J | PART | [1] host targets refuse --yes and require a TTY | yes | The owner's Q-050 answer the same day required a human bless before copies reach ~/.claude, which points to refusing non-interactive installs, but the existing devcontainer bless accepts --yes, so the phrase alone does not settle it. |
| Q-057 | 09-23 | J | NONE | [1] move foreign files to the backup directory | yes | No doc says whether files the repo does not own inside install-owned directories should be moved aside or left; only the entry's own plan proposed it. |
| Q-058 | 09-23 | J | NONE | [2] install only when no agent can run; cc-isolated containers count | none | The installer's trust model was a new four-way choice raised by three review passes; decisions 035 and 037 describe the bless mechanism but not which same-uid threat model to build on. |
| Q-059 | 09-24 | J | NONE | Neither; false dichotomy, test by static equivalence, run divergent design | no | The owner rejected both offered options and supplied a third approach that no doc contained; the general rule to run divergent design on design choices fits only after the fact. |
| Q-060 | 09-24 | J | AUTH | [1] defer the orchestrator fixture sets | yes | The question is how much of the owner's compute and review time to spend on fixture coverage, which is theirs to spend; no repo doc set a budget (the plan's no-generation rule cites an agent memory, not a doc). |
| Q-061 | 09-25 | J | PART | [1] review the installed copies; the interim stands | yes | The Q-058 option the owner had picked two days earlier reads 'refuses while any claude process is running ..., then runs [1]'s checks', and [1]'s checks include staging and reviewing copies under the destination, so the earlier answer arguably already covered this; 'checks' can also be read as the hash checks only. |
| Q-062 | 09-25 | J | NONE | [2] yes, a leftover helper counts; widen the gate to checkout-cwd processes | no | It asks how far the owner's own Q-058 answer reaches; the recorded answer names Claude processes and containers only, the agent read it narrowly for its interim, and the owner chose the wider reading. |
| Q-063 | 09-25 | J | PART | [1] deny-and-record plus static equivalence | yes | Re-ask of Q-059. The owner's Q-059 answer hours earlier had already named the approach (compare the proposed command to a static script), which option [1] implements most directly and which the cited DD doc recommended at 80%, but the dry-run option also fits those words. |
| Q-064 | 09-25 | J | NONE | [2] refuse the install on any unreadable cwd | no | It asks the scope of the owner's Q-062 answer for a hiding process; the recorded Q-062 answer refuses when all of /proc is unreadable but says nothing on one unreadable cwd, and the owner accepted a standing cost (stopping ssh-agent) that no doc anticipated. |
| Q-065 | 09-26 | J | NONE | [1] delete the dead function and its 12 tests | no | No doc said whether the never-called rejected-history helper should be wired in or deleted; two earlier answers (Q-037, Q-046) deleted other dead self-improvement code, but that is an analogy, not a line about this feature. |
| Q-068 | 09-26 | J | NONE | [3] resume the loop; this was the intent all along | no | Conflict. The only doc on the retire-or-resume choice was the 2026-09-17 triage, an agent analysis that marked resume as Drop while calling the choice the owner's; the owner overrode it (the doc was wrong about the owner's intent, not stale). |
| Q-069 | 09-26 | J | NONE | [3] launcher-side scan of .git at session exit | no | Conflict. Decision 034 (scoped to the benchmark harness, cited by the entry) rejected key-enumeration sanitizing in favour of the host never reading a container-written .git, which points at the separate-clone option; the owner chose the enumeration scan, so the doc misdirects (owner decided differently for cc-isolated). |
| Q-070 | 09-26 | J | PART | [1] supply the backstops: Bash deny rules plus sandbox config; not [2] | no | Decision log row 53 already recorded the owner's position that patching the hook does not converge and that permissions.deny plus the sandbox are the boundary, which favours restoring the backstops over narrowing the hook, but it says to revisit when the sandbox is absent rather than what to do then. |
| Q-071 | 09-26 | J | NONE | [1] narrow the stamp and commit the reports | no | No doc on that commit addressed how skill-report freshness stamps should be scoped or whether reports are tracked; the only mentions are the entry itself and its audit. |
| Q-072 | 09-26 | J | NONE | Between [1] and [2]: keep canon compact; script converts, heuristic filter proposes | no | The ledger header and the evaluation thoughts doc call the ledger living but say nothing on how it is fed; the owner's answer introduced a new design principle (compact canon, filtered proposals) found in no doc. |
| Q-073 | 09-26 | J | PART | [1] front-load and trim; no de-overlap | no | The skill-format audit the entry cites (finding F4, open since April) already recommended front-loading descriptions within 250 characters and moving the rest to the body, which is option [1], but it is silent on the de-overlap choice that separates [1] from [2]. |
| Q-075 | 09-27 | A | NONE | Agent work: evidence report 2026-10-14; child confinement left open as Q-146 | none | Agent work item whose resolution is an inventory and hermetic-run finding about what the loop writes; no doc held those facts before the work was done. |
| Q-076 | 09-27 | A | PART | Built, but as a tripwire plus cc-push on a further owner decision | no | Agent work order to implement Q-069's answer, which the archive stated on that commit; the recorded resolution departs from it (review showed a scan cannot guarantee, so the owner re-decided it as a tripwire alongside cc-push), which no doc gave. |
| Q-077 | 09-27 | A | PART | Agent work: deny half built and merged; sandbox half split to Q-081 | none | Agent work order to implement Q-070's answer, stated in the archive on that commit; only the deny half matched it, because the sandbox half turned out not to run in the image, a fact no doc held. |
| Q-078 | 09-27 | A | FULL | Agent work: done as specified, merged in b7fbb2a | none | Agent work order, not an owner question: it implements Q-071's answer, which the archive on that commit states in full, and the recorded resolution is that work done. |
| Q-080 | 09-27 | A | FULL | Agent work: done as specified, merged in b7fbb2a | none | Agent work order, not an owner question: it implements Q-073's answer, which the archive on that commit states in full, and the recorded resolution is that work done. |
| Q-081 | 09-27 | J | PART | [2] spike enableWeakerNestedSandbox first | no | The owner's answer to Q-070 earlier the same day had already asked for a sandbox config in cc-isolated, which names building over accepting as the default, but nothing weighed the newly found kernel and image cost or suggested spiking the weaker mode first. |
| Q-083 | 09-27 | J | NONE | [1] separate host-tools category | no | Decision log row 45 defines the live-verify gate for container-boundary files and says nothing about host-only tools, which did not exist when it was written; no doc chose among a separate category, keeping them in the set, or unhashing them. |
| Q-085 | 09-27 | J | NONE | [3] about 400 code lines, every unit | no | The only doc with a number was the agent's own proposal (about 600, listed there as an open question for the owner); no owner-written doc stated a cap or its scope, and the owner picked a different number. |
| Q-087 | 09-28 | J | AUTH | [2] k=3 on the final confirming pass, amending decision 031 | no | The question asks to reverse part of recorded decision 031 (which chose k=1 on both clean passes), an act reserved to the owner; 031 read plainly said k=1 and the owner changed it, with no standing permission to do so. |
| Q-088 | 09-28 | A | NONE | Agent spike: failure; weaker mode still needs user namespaces | none | Agent spike whose resolution is a fact about how Claude Code's weaker nested sandbox behaves in the container; no doc held it before the spike ran. |
| Q-089 | 09-28 | A | FULL | Agent work: built and merged 2026-10-14 as specified | none | Agent work order, not an owner question: it implements Q-083's answer, which the archive on that commit states, and the recorded resolution is that work done (landing later went through a separate entry). |
| Q-090 | 09-28 | A | PART | Trigger fired 2026-09-30; --jobs built and merged same day | none | A watch, not an owner question: the proposal and Q-086 already said to add --jobs once GNU parallel is in the image, so the work was pre-decided, but whether the trigger had fired was a fact about the owner's image that no doc held. |
| Q-091 | 09-28 | J | NONE | [1] owner removed commondir on the host; host version 2.1.284 | yes | Choosing between removing the stray file and relaxing cc-push turned on the host's Claude Code version and a command run on the owner's machine; no doc held either the fact or a rule for the choice. |
| Q-092 | 09-28 | A | FULL | Agent work: done; deny reader removed, on main | none | Agent work order, not an owner question: Q-082's recorded answer on that commit already said a hook allow does not beat a deny, so the hook's deny reader is redundant and can be deleted, and the resolution is that removal done. |
| Q-093 | 09-28 | J | PART | [1] relax cc-push to accept a commondir containing only '.' | yes | Re-ask of Q-091. Q-091's recorded answer hours earlier named relaxing cc-push as the fallback if the file came back, which is the option the owner then took, but it said to reopen the question rather than to proceed, and its stated condition (an older host build) had not held. |
| Q-094 | 09-28 | J | NONE | [1] accept git's standard linked-worktree layout with a note | yes | No doc said how the new exit scan should treat worktrees left behind by a session; the trade between warning fatigue and scan strictness had not been decided anywhere. |
| Q-095 | 09-28 | J | AUTH | [1] waive the cap; review as one change (later superseded) | yes | The entry asks for a waiver of the 400-line review cap, which decision log row 62 reserves to the owner through an answered entry; no standing waiver existed (the row's default for an unattended agent was to split without asking). |
| Q-096 | 09-28 | A | NONE | Agent work: done 2026-10-15, on main; closed in session 2026-10-28 | none | Agent work order raised from a review finding; no doc on that commit decided that the documented insteadOf route should be closed, so the resolution rests on the agent's own call and the work itself. |
| Q-099 | 09-29 | J | NONE | [1] the roadmap is the one backlog | yes | Decision log row 67 mentions ideas landing in the roadmap only as this entry's own interim, which does not count; no other doc said whether the roadmap or the self-improvement loop's feature-ideas files own the backlog. |
| Q-100 | 09-29 | J | AUTH | [1] fourth full pass, merge only if clean; any finding returns to owner | none | Asks the owner to authorize a fourth review iteration or a merge past the 3-iteration cap, which workflows/review-fix-loop.md reserves for the human reviewer's explicit authorization; no standing permission existed. |
| Q-101 | 09-30 | J | AUTH | [1] cut carry-forward and Main-at handshake, fix --since, one confirming pass | yes | After the authorized fourth pass failed, it asks the owner to authorize yet another pass and a conditional merge past a spent cap, bundled with a design cut no doc had decided. |
| Q-102 | 09-30 | J | NONE | [1] parallel by default, with an env override | no | Whether the gates should run tests in parallel by default was a new speed-versus-flake trade; Q-090's record only measured the speedup and explicitly deferred this choice to Q-102. |
| Q-103 | 10-01 | J | AUTH | [2] self-merge: this single-author repo should be able to self-merge | no | Asks the owner to grant build loops standing permission to land work without the owner's review; docs/dev-cycle.md and log row 68 said this per-project policy is asked of the user at onboarding and held only the entry's own interim. |
| Q-104 | 10-02 | J | AUTH | [2] re-check size each iteration; tolerate to ~800, waiver past that | no | Asks whether to amend log row 62, a rule recorded from the owner's own Q-085 answer; the row's revisit trigger only said to revisit if units balloon during review and named no answer. |
| Q-105 | 10-02 | J | PART | [3] revisit 015: re-run step 4 (Docker vs podman) as a DD session | no | Decision 015's reversal-criteria row already paired breakage above 1/week with re-running the step-4 tradeoff, which is the answer given, but it left open whether self-inflicted boundary breakage counts, which was the question. |
| Q-106 | 10-02 | J | AUTH | [2] automate the host settings merge via link-claude-home's provenance jq | no | Asks whether to reverse decision 037's 'settings.json stays a manual merge', a sub-decision recorded from the owner's answers that governs writes to the owner's host config; 037's trigger said only to reconsider and the options already used the one merger it names. |
| Q-107 | 10-02 | A | PART | agent resolved: seam not met; seam work filed in roadmap Ideas | none | An agent-routed check, not an owner question: decision 036 states what [11]'s seam is and that it is owed once a second consumer appears, and the agent closed it from that record plus a read of install.sh, which no doc held. |
| Q-108 | 10-02 | A | NONE | agent fixed both stale lines in decision 037; merged later | yes | An agent work item with no open question (the entry already states both corrections and was filed only because decision records were outside the cycle's fix scope), so there was nothing for a doc lookup to answer. |
| Q-110 | 10-02 | A | NONE | agent found the cause and fixed it with a test; on main | yes | An agent bug-fix task whose answer (a nested test run overwriting the parent's NOT RUN count file) came from reproducing the bug in code, not from any doc. |
| Q-111 | 10-05 | J | AUTH | [1] authorize iteration 4 for U1a | none | Re-ask of Q-100. Asks the owner to authorize review iteration 4 on one unit, which review-fix-loop.md gives only to the human reviewer; Q-100's earlier grant was for one unit and said findings go back to the owner, so it was no standing permission. |
| Q-112 | 10-05 | J | NONE | [1] best effort; exact never line required for self-merge; same for constraints | yes | A design choice about how the settings reader treats near-miss lines; the build-loop plan and docs/dev-cycle.md stated the exact-line rule but not what a hidden copy or a markup-wrapped never line should do. |
| Q-113 | 10-05 | J | AUTH | waive the size cap to ~420 for U1b | yes | Re-ask of Q-095. A request to waive the 400-line cap for one unit, which log row 62 reserves to the user through an answered entry; the only earlier waiver (Q-095) lapsed with its unit and Q-104's 2x tolerance was not yet answered. |
| Q-114 | 10-05 | J | AUTH | waive the size cap to ~430 for U1c | yes | Re-ask of Q-113. A second same-day request to waive the 400-line cap for one unit, reserved to the user by log row 62, with no standing tolerance on that commit. |
| Q-115 | 10-05 | J | AUTH | narrow the claim (caller's environment trusted) and land U1b | none | Re-ask of Q-111. Asks how one unit may land after its owner-authorized fourth pass found a new red: another pass past the cap or landing without re-review, both the owner's call under the cap gate. |
| Q-116 | 10-05 | J | NONE | [2] also scan docs/working/dd-*.md for Revisit triggers | no | The only doc on the point, the gap note the entry cites, lists both options without choosing, and no rule said whether working-doc DDs carry standing triggers. |
| Q-118 | 10-05 | J | AUTH | fix plus a scoped fourth pass; extend the size waiver to ~450 | yes | Re-ask of Q-111. Asks the owner to authorize a pass beyond the 3-iteration cap and to extend the Q-114 size waiver for one unit, both reserved to the owner with no standing permission on that commit. |
| Q-119 | 10-06 | J | PART | [1] keep the split; refusing odd repo names is the right default | yes | Standing permission. Log row 61 already made splitting the /away default at the iteration-4 gate, recorded as an interim in questions.md, so the split needed no approval; the redesign's trade (refuse every unmodelled name) was not in any doc. |
| Q-120 | 10-07 | J | AUTH | [1] one more confirming pass, with a size waiver past ~800 | yes | Re-ask of Q-118. Asks the owner to authorize a pass beyond a spent review cap and a size waiver beyond the ~800 tolerance Q-104 [2] had set, both of which the docs reserve to the owner. |
| Q-121 | 10-07 | J | PART | yes, occasionally: host sessions in ~/claude-workflows when the container image breaks | no | A fact about where the owner starts sessions; the archive's Q-091/Q-093 record already showed sandboxed host sessions running in this repo's host checkout, which points to yes and the path, but not whether that is current practice or the full set. |
| Q-122 | 10-07 | J | AUTH | [1] merge now, listing the last fix commit as unreviewed | yes | Re-ask of Q-120. Asks the owner to approve landing one unit with an unreviewed fix after its waived confirming pass found new items; Q-120's answer had said any new finding returns to the owner. |
| Q-124 | 10-07 | J | PART | [1] build the sandbox with a custom seccomp profile | yes | Re-ask of Q-081. The owner had already asked for a sandbox config in cc-isolated (Q-070 [1]) and shelved the allowlist until one exists, which names the direction, but had answered the same build-or-accept question (Q-081) with 'spike first', so the user-namespace risk trade was still undecided. |
| Q-127 | 10-07 | J | NONE | closed as moot: the probe passed, no option chosen | none | A contingent fallback question that a live probe result made moot before the owner answered; no doc ranked the three fallbacks, each of which traded a different boundary. |
| Q-128 | 10-07 | J | AUTH | [1] one more confirming pass; clean means merge ask | yes | Re-ask of Q-120. Asks the owner to authorize another full pass or a merge past the spent 3-iteration cap for one unit; the Q-120 precedent it cites sent such findings back to the owner and was not a standing permission. |
| Q-129 | 10-07 | J | AUTH | [1] apply doc and test fixes, defer G1, lite check, then merge | yes | Re-ask of Q-122. Asks the owner how one unit may land after its extra confirming pass found new items, which Q-128's answer had explicitly routed back to the owner. |
| Q-131 | 10-08 | J | AUTH | [1] cap waived; lite confirming pass over unreviewed fixes, then land | yes | Re-ask of Q-120. Asks the owner to approve landing one unit whose final-pass fixes were unreviewed past the review cap; the size-waiver half (540 lines, grown from 381 during review) was already inside the ~800 growth tolerance of Q-104 [2] in the archive, which the entry overlooked. |
| Q-132 | 10-08 | J | AUTH | [1] security-only pass over the last fixes; land unless Medium or above | yes | Re-ask of Q-122. Asks how one particular over-cap unit lands after its confirming pass found a regression; the owner's own Q-131 [1] answer had routed any new finding back to them, and no standing landing permission existed yet. |
| Q-133 | 10-08 | J | AUTH | [3] land U2b1a2 as is with four reds recorded, fix in U2b1b | no | Asks for an iteration past the 3-iteration review cap and was answered by landing with open reds, both the owner's by the review-fix loop's cap rule; the plan's 'no script can contain a loop that turns hostile' line spoke only to the threat-scope half. |
| Q-134 | 10-08 | J | AUTH | [1] land it | yes | A plain request to approve one unit's merge to main, filed before any standing merge permission; the owner's earlier answers (Q-120, Q-128, Q-129) had each ended in a 'merge ask'. |
| Q-135 | 10-08 | J | AUTH | [1] land it | yes | Re-ask of Q-134. A plain request to approve one clean unit's merge to main, filed the day before the owner gave a standing merge-on-recommendation instruction. |
| Q-136 | 10-08 | J | AUTH | [1] land it | yes | Re-ask of Q-135. A plain request to approve one clean unit's merge to main, filed the day before the owner gave a standing merge-on-recommendation instruction. |
| Q-137 | 10-08 | J | AUTH | [1] land it; plus standing instruction to merge on recommendation without asking | yes | Re-ask of Q-135. A plain request to approve one clean unit's merge to main; the standing permission that would have made it unnecessary was given only in this entry's own answer. |
| Q-138 | 10-10 | J | PART | [1] one more narrow pass, then merge; [3] would block all self-merges | yes | Standing permission. Re-ask of Q-132. The previous day's standing instruction let the session land on its own recommendation (it did, as the interim), but the entry also asked a threat-model call and offered a design change that the instruction does not decide. |
| Q-139 | 10-12 | J | NONE | [1] unset core.hooksPath in the repo config; it had no effect | no | Whether to drop a host git setting or relax the gate turned on whether the setting was deliberate, a fact about the owner's machine no doc held, and no doc ruled on how far the gate trusts repo config. |
| Q-140 | 10-12 | J | AUTH | [1] always run the root-owned image copy | no | Asks to change plan decision D6's trust root (main's copy of the gate), a design the owner had walked through and approved; the plan as written pointed to the option the owner then replaced. |
| Q-141 | 10-13 | J | AUTH | [1] one more narrow fix, then merge; kept as merged | yes | Standing permission. Re-ask of Q-138. First pass FULL, second pass AUTH: the lower stands. A past-cap landing with the same three-way shape as Q-138, which the owner had answered [1] two days earlier, under the standing instruction to go ahead on the recommendation; the session in fact applied [1] and merged before the answer came. |
| Q-142 | 10-13 | J | FULL | [1] one more narrow fix, then merge; kept as merged | yes | Standing permission. Re-ask of Q-138. Same shape and same answer as Q-138 (answered [1]) under the standing merge-on-recommendation instruction; the session applied [1] as its interim and merged before the answer came. |
| Q-143 | 10-13 | J | PART | [3] rework the hold as one stop, then a confirming pass | yes | Standing permission. Re-ask of Q-138. The standing instruction allowed going ahead on the recommendation, but the recommended option was a design rework that costs the owner attention and the earlier narrow-fix precedent had failed to converge, so the docs name a default without settling it. |
| Q-144 | 10-14 | J | PART | [1] with one more security pass, then merge | yes | Standing permission. Re-ask of Q-138. The standing instruction and the Q-138 answer name narrow-fix-then-merge as the default, but two confirming passes had each introduced a Medium, a non-convergence case those lines do not clearly cover. |
| Q-145 | 10-14 | J | AUTH | [2] merge now, fix the lib later; revisit if re-runs exceed an hour | no | First pass NONE, second pass AUTH: the lower stands. A trade between fixing a flaky gate first and merging anyway; the earlier Q-102 answer priced a much lower flake rate and the session, reading it, recommended the option the owner did not pick. |
| Q-146 | 10-14 | J | NONE | [1] the script commits for the child, in a dedicated clone | no | Sets the trust boundary for unattended children of the self-improvement loop; the only earlier ruling (Q-068) said resume once trusted and said nothing on how commit rights are granted. |
| Q-148 | 10-14 | J | PART | [1] fix F1/F2, narrow check, then merge both branches | none | Standing permission. Re-ask of Q-111. An iteration-4 gate with only mechanical items left; the standing merge-on-recommendation instruction and Q-138's narrow-fix-then-merge answer named the default, but the entry stated no recommendation and the cap rule reserves iteration 4 to the owner. |
| Q-149 | 10-14 | J | PART | [2] workflows/ only, as a better interim | no | The owner-approved plan already named `workflows/` as this repo's never line but flagged it as an interim to be asked; the entry was later rewritten with a wider fail-closed interim after review findings, and the owner went back to the plan's value. |
| Q-150 | 10-14 | J | PART | [1] orchestrator only | yes | The plan the owner walked through states this as decision D11, but labels it an unconfirmed default (C1) to be filed for the owner, so it names the default without being a ruling. |
| Q-151 | 10-14 | J | PART | [1] a blocked loop frees its slot | yes | The plan the owner walked through states this in decision D9, but labels it an unconfirmed default (C2) to be filed for the owner, so it names the default without being a ruling. |
| Q-152 | 10-14 | J | NONE | [2] stop the loop when every thread waits on the owner | no | Conflict. Conflict: the plan's D12 (the C3 default, in a plan the owner had walked through) said to keep polling, and the owner chose to stop instead, so the owner overturned the documented default. |
| Q-153 | 10-14 | J | AUTH | [1] narrow the global rule: merged-branch `git branch -d` needs no approval | no | Asks to change the owner's own global instruction that branch deletion needs approval in every mode; their earlier remark that safe branch deletion need not wait conflicted with that rule as written, so only they could reconcile the two. |
| Q-154 | 10-14 | J | FULL | [1] full cycle every iteration for now; light pass later | yes | Filed already answered: the owner had ruled in session ten days earlier and the plan's D12 recorded that ruling in so many words. |
| Q-155 | 10-14 | J | AUTH | [1] done; the owner wrote docs/constraints.md | no | Asks the owner to spend their own time writing the repo's hard constraints, which the plan says must be theirs and never inferred. |
| Q-160 | 10-14 | A | FULL | done; the work is on main (no decision was asked) | none | An agent-routed build task, not a question: it implements the owner's recorded Q-104 [2] answer, which states the rule to write in full. |
| Q-165 | 10-15 | J | NONE | [1] cc-verify host tool, taking the config to verify as an argument | yes | A choice among three ways to build a new host verification tool; the owner's Q-117 answer asked for a non-blocking process but did not choose a form, and the only recommendation was the session's own design doc. |
| Q-166 | 10-15 | J | PART | [2] yes, plus a post-merge check | yes | The owner's Q-117 answer had rejected the blocking install-over-main run, which rules out [3], but no doc says whether a staged run alone counts or needs the post-merge probe. |
| Q-170 | 10-15 | J | AUTH | [A] keep Docker, amend 015, verify-before-merge; gave host-fallback facts | yes | Asks the owner to approve an amendment to decision record 015's revisit trigger (and for a fact about their host fallbacks no doc held), which only the owner can do. |
| Q-171 | 10-15 | J | AUTH | [2] hold until split units land; pre-existing reds get fixed first | no | Re-ask of Q-148. A branch at the review-fix loop's iteration-4 gate asks for a 4th iteration or a merge with reds listed, both of which the workflow reserves to the owner's explicit authorization; the owner chose to hold instead of the recommended extra iteration. |
| Q-172 | 10-15 | J | PART | [2] set a boundary | none | An earlier recorded owner decision (Q-076) already made the exit scan a tripwire, not a guarantee, with cc-push as the safe route, which argues against open-ended parity chasing but does not give the boundary rule the owner chose. |
| Q-174 | 10-15 | J | AUTH | [1] authorize iteration 4 | yes | Re-ask of Q-171. Asks the owner to authorize a 4th review iteration, which workflows/review-fix-loop.md says only their explicit authorization permits. |
| Q-175 | 10-15 | J | NONE | [1] accept it in the hooks/** class (no commit-gate coverage) | yes | Whether a moved jq merge program should stay under the live-verify commit gate is a scope call no decision row or record settled; decision 035 added install.sh to the same regex but says nothing on hooks/lib files. |
| Q-178 | 10-15 | J | AUTH | [1] land via pr-prep by a fresh session | none | Asks the owner to approve landing a branch another session wrote, which the orchestrator may not land on its own. |
| Q-179 | 10-15 | J | NONE | [1] close; workflows merged into skills answers the underlying question | none | Whether a literally-fired revisit trigger on log row 66 (4 early misses, none since) reopens the decision is a judgment the row's own text does not settle, and the owner's reason was in no doc. |
| Q-180 | 10-15 | A | NONE | no owner answer: agent work item, resolved by an agent | none | Not an owner question: a `Needs: agent` task list (re-pin and harden host pastes) that an agent closed itself, so there is no owner answer a doc could have held. |
| Q-194 | 10-17 | J | PART | [2] widen the drift check | no | Decision 031's own trigger line pre-registers the response to this miss as 'widen it or accept the full-pass cost', which names the owner's pick and one other and excludes the entry's recommended option of narrowing the trigger. |
| Q-199 | 10-19 | J | FULL | [1] keep the split | yes | Re-ask of Q-131. Decision log row 62, which the entry cites, says an over-cap unit splits and that in /away mode the agent splits without asking and records it as an interim; the owner's answer was that default, and nobody had asked for a waiver. |
| Q-200 | 10-19 | J | AUTH | [1] accept revision 3 as drafted | none | Asks the owner to ratify and commit a revision of docs/constraints.md, the file only the owner writes. |
| Q-213 | 10-20 | J | PART | [1] read it as the same-uid residual | none | The constraints file's S1 line already put a deliberately hostile same-uid loop outside what gates defend against, which points at the owner's reading, but the hardening doc's trigger written a day earlier names build loops explicitly, so a careful reader could still think it had to be asked. |
| Q-221 | 10-28 | J | NONE | [14'] watches in their own file, agent work in the roadmap | no | Where agent bookkeeping should live was an open design choice from a double diamond; the owner picked a hybrid that was not among the three options first filed (the entry recommended roadmap-only), and no doc stated it. |
| Q-223 | 10-28 | J | NONE | none of the options: revisit in more detail as a research unit | no | A fired watch asked whether to automate or drop the failure-pattern writer; the watch itself said to reopen as a judgment, and the owner asked for a closer study instead of any listed option. |
| Q-226 | 10-28 | J | NONE | [5] put both steps where build loops run, and gate-check them | no | Re-ask of Q-223. What to do with the failure-pattern library after the review was a value call; the owner chose an option added only after they asked why it was missing, and the soft constraints (S4, S6) fit it only in hindsight. |
| Q-238 | 10-30 | J | PART | [1] close it; branch stays unmerged as reference | yes | Re-ask of Q-171. The owner's earlier Q-172 answer set the boundary (close only routes needing no state planted before launch), which puts every route the held branch fixes out of scope, but it does not say whether to salvage the branch's wording and performance fixes or to end the hold the owner ordered in Q-171. |
| Q-246 | 11-01 | J | AUTH | [1] re-dispatch | none | Lowered from PART in review round 1: a step-written `stopped-` entry with a fixed question (re-dispatch or drop?) that the dev-cycle skill reserves to the owner, as with merge entries. The owner had just approved merging this exact branch (Q-244 [1]) and the merge was refused only for a conflict with a sibling unit, so 'drop' was against a recorded answer; the dev-cycle skill still required a stopped entry with re-dispatch/drop options. |
| Q-247 | 11-01 | J | AUTH | [1] re-dispatch | none | Re-ask of Q-246. Lowered from PART in review round 1: a step-written `stopped-` entry with a fixed question (re-dispatch or drop?) that the dev-cycle skill reserves to the owner, as with merge entries. Same as Q-246 for a sibling branch: the owner had just approved its merge (Q-243 [1]) and only a conflict refused it, so the earlier answer ruled out 'drop' though the skill's stopped-entry rule still asked. |
| Q-254 | 11-03 | J | FULL | [1] fix the branch first, then one paste | yes | The two options differed on one host paste versus two, and the constraints file's S10 line (at most one host paste per verification), which the build loop itself cited as its tiebreaker, picks the option the owner gave. |
| Q-256 | 11-05 | J | NONE | [2] one pass now: build the script, add 1-2 candidates | no | First pass NONE, second pass PART: the lower stands. When to run the canon proposal filter was a timing call; the owner's 2026-09-27 note fixed the filter's shape but not its timing, the loop read S5 as favouring a deferred pass, and the owner chose to build now. |
| Q-269 | 11-10 | J | AUTH | none yet | n/a | Open. Asks the owner whether to spend compute on a deep audit and at what scope, which the dev-cycle skill reserves to them ('The user confirms its scope and timing') and which leads to promoting or dropping constraints. |
| Q-270 | 11-10 | J | PART | none yet | n/a | Open. Re-ask of Q-154. Standing-permission flag removed in review round 1: no doc grants the act. The owner's Q-154 answer already said to keep a full cycle for now and move to a light pass once the costs are visible, which gives the direction and the present default but not the rule for when a full cycle returns, nor whether unrecorded token costs count as 'visible'. |
| Q-272 | 11-10 | J | PART | none yet | n/a | Open. Hard constraint H2 says a degraded primitive refuses, which rules out the merged run-and-warn behaviour unless the owner records an exception, but it does not choose between refusing always and refusing unless a flag asks for the weak mode. |

## Appendix B: the doc and the line, for every in full, in part and conflict

Each line was checked as an exact substring of the file at the commit shown (a `\|` in a
row stands for `|` in the file). Rows marked "first pass" were lowered afterwards and keep
the line the first reader quoted.

| ID | Class | Doc at the entry's commit | Kind | Line quoted |
|---|---|---|---|---|
| Q-001 | PART | `docs/decisions/017-polyglot-test-hermeticity.md` at bd80e291 | decision-record | rather than warn-and-continue. Silent degradation is H5's exact failure and the spike's pre-mortem |
| Q-003 | PART | `docs/reviews/prompt-audit-2026-09-11.md` at bd80e291 | brief-or-plan | `These rules are absolute. Do not deviate from them under any circumstances.` followed by four to six numbered rules carrying `MUST` / `MUST NOT` / `ALL` / `STOP —` / `No exceptions.` |
| Q-008 | PART | `docs/decisions/log.md` at bd80e291 | decision-log | Blocking prerequisite before the harness actually moves: `lite-review.py` must own the FINDINGS grammar outright instead of documenting it as a copy |
| Q-017 | PART | `docs/human-author/feedback.md` at 9896a5e2 | human-author | I don't observe any calls to the RPI prompt from external projects, but the data from these projects is *so* sparse that I suspect the hook isn't catching everything. |
| Q-018 | PART | `docs/decisions/013-failure-pattern-library-after-bug-diagnosis-removal.md` at 9896a5e2 | decision-record | **Option B.** Lowest cost preservation of the cumulative-pattern-learning loop. Decouples discipline from any single skill. |
| Q-025 | PART | `docs/decisions/log.md` at 308cad3a | decision-log | add `shfmt` to the Dockerfile and `scripts/` to the payload |
| Q-027 | NONE (conflict) | `docs/decisions/023-wire-hooks-from-the-image.md` at 308cad3a | decision-record | remains the procedure for a bare host install with no devcontainer. |
| Q-033 | PART | `docs/working/triage-2026-09-17-backlog.md` at 53f57c42 | working-doc | - **ARCHIVE** (named DROP in the first pass) — no consumer, or an unmet |
| Q-038 | PART | `global-instructions/CLAUDE.md` at 63c5c1d7 | global-instructions | questions for the user that don't justify stopping must not evaporate. Maintain a running questions doc at `docs/working/questions.md` |
| Q-040 | NONE (conflict) | `global-instructions/CLAUDE.md` at 63c5c1d7 | global-instructions | \| **Framing a decision before choosing** — explicit request, or DD/RPI surfaces a misframing signal (constraints contradict, no candidate fits the brief) \| `design-space-situating` \| |
| Q-041 | PART | `workflows/review-fix-loop.md` at 63c5c1d7 | working-doc | 1. **Clean convergence.** No Must Fix items remain and Must Address items are resolved or explicitly acknowledged. Proceed to Phase 2 of pr-prep. |
| Q-044 | PART | `docs/decisions/031-review-loop-tier-and-factcheck-policy.md` at 63c5c1d7 | decision-record | routed to the override log as an accepted-immutable acknowledgment, never 🔴. Behavioral |
| Q-046 | PART | `docs/working/triage-2026-09-17-backlog.md` at 63c5c1d7 | working-doc | - **ARCHIVE** (named DROP in the first pass) — no consumer, or an unmet |
| Q-048 | PART | `docs/working/questions-archive.md` at 9f593ef0 | earlier-answer | **Answered 2026-09-20: [1].** Bash HARD for CLAUDE.md only when qualified as global (`~/`, `$HOME/`, `${HOME}/`, literal home, `.claude/CLAUDE.md`, `global-instructions/CLAUDE.md`); a bare `CLAUDE.md` is SOFT. |
| Q-052 | PART | `docs/decisions/log.md` at 063181f0 | decision-log | Security review (subagent) confirmed no boundary regressions and flagged this checksum gap plus the IP-only egress admitting Google's SNI-routed frontend as an accepted, documented risk in `android.txt`. |
| Q-056 | PART | `docs/working/questions-archive.md` at e80fa0b3 | earlier-answer | the symlink connection should be deprecated in favor of edits getting checked in and propagated by copying after a human bless via install.sh. |
| Q-061 | PART | `docs/working/questions-archive.md` at c7c4e346 | earlier-answer | **Answered 2026-09-23: [2], install only when no agent can run, and cc-isolated counts.** |
| Q-063 | PART | `docs/working/questions-archive.md` at faf274bf | earlier-answer | **Answered 2026-09-25: neither.** "This feels like a false dichotomy; can we not test via something like equivalence of the proposed command to some static script? Run divergent design on this." |
| Q-068 | NONE (conflict) | `docs/working/triage-2026-09-17-backlog.md` at e7aa412d | working-doc | \| 6 \| Keep as-is and resume \| **spends most** \| **Drop.** Generated the 50-question queue that is the anti-pattern. \| |
| Q-069 | NONE (conflict) | `docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md` at e7aa412d | decision-record | \| Sanitize `.git/config` + `.git/hooks` from a stored baseline before each host git call \| Relies on enumerating every config key that can execute code. `core.fsmonitor` and the `.gitattributes` smudge filter were both missed by the reviewers' first pass at exactly this list; the next one will be missed too. |
| Q-070 | PART | `docs/decisions/log.md` at e7aa412d | decision-log | User call: the gaps are too hard to avoid. Patching constructs one at a time does not converge on a sound filter, and the hook is a convenience layer; `permissions.deny` and the sandbox are the boundary. Revisit if the hook is ever relied on as a security control or the sandbox is removed. |
| Q-073 | PART | `guides/skill-format-audit.md` at e7aa412d | brief-or-plan | **Recommendation:** Restructure each description to put the primary trigger and capability in the first 250 characters. Move secondary triggers and scope notes to the markdown body. |
| Q-076 | PART | `docs/working/questions-archive.md` at ffb5f0d0 | earlier-answer | **Answered 2026-09-27: [3] launcher-side scan.** `cc-isolated.sh` checks, at session exit, whether `.git` gained hooks, fsmonitor, filters or includes during the session, reusing install.sh's refusal list. |
| Q-077 | PART | `docs/working/questions-archive.md` at ffb5f0d0 | earlier-answer | **Answered 2026-09-27: [1] supply the backstops.** Add Bash deny rules for the credentials path, plus a sandbox config, to the cc-isolated settings merge. |
| Q-078 | FULL | `docs/working/questions-archive.md` at ffb5f0d0 | earlier-answer | **Answered 2026-09-27: [1] narrow the stamp and commit the reports.** The stamp covers only the skill's own files and the fixture, not the shared `runner-contract.bash`, and `output/*.report.md` becomes tracked. |
| Q-080 | FULL | `docs/working/questions-archive.md` at ffb5f0d0 | earlier-answer | **Answered 2026-09-27: [1] front-load and trim.** In each description, the first ~250 characters carry the trigger phrases and the "not this, use X" line, and the rest moves to the body. |
| Q-081 | PART | `docs/working/questions-archive.md` at fd40334e | earlier-answer | **Answered 2026-09-27: [1] supply the backstops.** Add Bash deny rules for the credentials path, plus a sandbox config, to the cc-isolated settings merge. |
| Q-089 | FULL | `docs/working/questions-archive.md` at 183202e3 | earlier-answer | **Answered 2026-09-28: [1] separate host-tools category.** |
| Q-090 | PART | `docs/working/proposal-2026-09-27-smaller-review-units.md` at 183202e3 | brief-or-plan | - `--jobs N` when GNU `parallel` is present (it is not in the image today; see C6). |
| Q-092 | FULL | `docs/working/questions-archive.md` at 60d87bdf | earlier-answer | So a PreToolUse hook `allow` does **not** override a matching `permissions.deny` rule. The deny won. The hook's deny reader is therefore redundant for `allow`; |
| Q-093 | PART | `docs/working/questions-archive.md` at 26f5f8a6 | earlier-answer | If a later sandboxed host session brings it back, reopen with [2]. |
| Q-105 | PART | `docs/decisions/015-cc-process-isolation-docker-devcontainer.md` at 20a462d4 | decision-record | \| **Revisit** \| >1 Docker/devcontainer breakage per week needing manual fixing, or image staleness pins CC >1 version behind for >2 weeks \| re-run the step-4 tradeoff with measured friction before further investment \| |
| Q-107 | PART | `docs/decisions/036-cc-isolated-repo-split.md` at 20a462d4 | decision-record | `if a second consumer of the claude-home payload appears (anything other than cc-isolated staging it) → [11]'s seam is owed regardless of the split, since the cp -r would then encode one consumer's layout assumption for two.` |
| Q-119 | PART | `docs/decisions/log.md` at 6f624cdf | decision-log | In /away mode splitting is the default, recorded as an interim in `questions.md`, and it is also the /away default at the iteration-4 gate when the unit is separable (`review-fix-loop.md`). |
| Q-121 | PART | `docs/working/questions-archive.md` at f29f56c5 | earlier-answer | - **The host's `claude` version is unknown.** The sandbox only runs on the host: the cc-isolated image has no bwrap (Q-081). If the host still runs an older build, any sandboxed host session in this repo can recreate `commondir`. |
| Q-124 | PART | `docs/working/questions-archive.md` at ae19e7ba | earlier-answer | **Answered 2026-09-27: [1] supply the backstops.** Add Bash deny rules for the credentials path, plus a sandbox config, to the cc-isolated settings merge. |
| Q-138 | PART | `docs/working/questions-archive.md` at 87ddfc42 | earlier-answer | Standing instruction with the answer: merges and review adjustments like this one go ahead on the recommendation without asking. |
| Q-141 | AUTH (first pass FULL) | `docs/working/questions-archive.md` at 413ce9dd | earlier-answer | Standing instruction with the answer: merges and review adjustments like this one go ahead on the recommendation without asking. |
| Q-142 | FULL | `docs/working/questions-archive.md` at 50fbcce2 | earlier-answer | Standing instruction with the answer: merges and review adjustments like this one go ahead on the recommendation without asking. |
| Q-143 | PART | `docs/working/questions-archive.md` at f50d436e | earlier-answer | Standing instruction with the answer: merges and review adjustments like this one go ahead on the recommendation without asking. |
| Q-144 | PART | `docs/working/questions-archive.md` at 000a6942 | earlier-answer | Standing instruction with the answer: merges and review adjustments like this one go ahead on the recommendation without asking. |
| Q-148 | PART | `docs/working/questions-archive.md` at 6d9a2962 | earlier-answer | Standing instruction with the answer: merges and review adjustments like this one go ahead on the recommendation without asking. |
| Q-149 | PART | `docs/working/plan-build-loop-handoff.md` at 2846f9fa | brief-or-plan | The interim is `Self-merge never: workflows/` in this repo's settings, asked as an entry in U5. |
| Q-150 | PART | `docs/working/plan-build-loop-handoff.md` at 2846f9fa | brief-or-plan | **D11. The orchestrator is the only writer of `questions.md`** (C1 default). Loops carry questions in their `blocked` marker. |
| Q-151 | PART | `docs/working/plan-build-loop-handoff.md` at 2846f9fa | brief-or-plan | Only a live dispatched loop holds a slot. A `blocked`, `ready`-awaiting-review or `stopped` item holds none (C2 default). |
| Q-152 | NONE (conflict) | `docs/working/plan-build-loop-handoff.md` at 2846f9fa | brief-or-plan | If every thread is blocked on you, a cheap check runs every 1200–1800 s. It runs a full cycle only when main's tip moved, an Asked ID was answered, or you wrote; otherwise it is a no-op wakeup. |
| Q-154 | FULL | `docs/working/plan-build-loop-handoff.md` at 92fa6e52 | brief-or-plan | The cost per iteration (F53) was C5. You answered on 2026-10-04: a full cycle every iteration for now, and a move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible. |
| Q-160 | FULL | `docs/working/questions-archive.md` at 63af3551 | earlier-answer | **Answered 2026-10-06: [2], re-check per iteration, waiver past 2×.** pr-prep re-measures the unit at each loop iteration. Growth up to ~800 lines is tolerated; past that the loop stops and asks for a waiver. |
| Q-166 | PART | `docs/human-author/answers-10-12-26.txt` at de9590ad | human-author | We need a different process for validating specific sections of code without blocking use of the harness overall |
| Q-172 | PART | `docs/working/questions-archive.md` at 7550465b | earlier-answer | Review showed that a `.git` scan can't be a guarantee, so on the user's decision it ships as a tripwire, `cc-exit-scan.sh`, alongside `cc-push`, which is now the safe way to push. |
| Q-194 | PART | `docs/decisions/031-review-loop-tier-and-factcheck-policy.md` at 78d0b15a | decision-record | `if the fix-drift lite-check misses a fix-introduced defect that a full pass then catches — the drift gate is too narrow; widen it or accept the full-pass cost.` |
| Q-199 | FULL | `docs/decisions/log.md` at 0732a759 | decision-log | Over the cap the unit splits into stacked units that merge in order, each with its own loop; only the user can waive the cap, through an answered `Q-NNN` entry the waiver cites. In /away mode the agent splits without asking and records the split as an interim in `questions.md` and the commit body's `Notes:` line. |
| Q-213 | PART | `docs/constraints.md` at 32917122 | constraints | Gates defend against honest slips by a same-uid loop, not a deliberately hostile one, and no restriction may stop all self-merges. |
| Q-238 | PART | `docs/working/questions-archive.md` at 1e277166 | earlier-answer | **Answered (docs/human-author/answers-10-22-26.txt): [2], set a boundary.** |
| Q-246 | AUTH (first pass PART) | `docs/working/questions.md` at 22ccde91 | earlier-answer | **Answered:** [1] (owner, in session 2026-11-01: "Q-243..245: [1]"; recorded by the dev cycle) |
| Q-247 | AUTH (first pass PART) | `docs/working/questions.md` at 22ccde91 | earlier-answer | **Answered:** [1] (owner, in session 2026-11-01: "Q-243..245: [1]"; recorded by the dev cycle) |
| Q-254 | FULL | `docs/constraints.md` at 585dd1a7 | constraints | S10: Spend the user's attention last: at most one host paste per verification, no new recurring host chore or trust decision, nothing left behind to clean up |
| Q-270 | PART | `docs/working/questions-archive.md` at 34721a82 | earlier-answer | **Answer (2026-10-04, in session; plan D12; filed 2026-10-14):** [1], a full cycle every iteration for now; move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible. |
| Q-272 | PART | `docs/constraints.md` at f5823c4c | constraints | H2: A gate or boundary fails closed and loudly: a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive refuses and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access. |

## Appendix C: how each entry's commit was found

Run from the repo root. It prints, for each ID, the first commit whose copy of either
questions file holds a heading with that ID.

```python
import re, subprocess
def git(*a): return subprocess.run(["git", *a], capture_output=True, text=True).stdout
HEAD = re.compile(r"^### (Q-\d+)\b")
first = {}
for path in ("docs/working/questions.md", "docs/working/questions-archive.md"):
    for sha in git("log", "--reverse", "--format=%H", "--", path).split():
        for line in git("show", f"{sha}:{path}").split("\n"):
            m = HEAD.match(line)
            if m and m.group(1) not in first:
                first[m.group(1)] = (sha, path)
for q in sorted(first, key=lambda s: int(s[2:])):
    print(q, first[q][0][:8], first[q][1])
```

The live file is walked first, so an entry seen in both is dated from the live file. It
matches on the ID alone, so for the two reused IDs (Q-186, Q-241) it prints the earlier
entry's commit. For the 15 in-scope entries read at an earlier commit, that commit is
bd80e291 for the 8 opened on 2026-09-12, and `git rev-parse COMMIT^` of the printed commit
for the 7 committed already answered (section 1 names them). Seven more entries with late
headings are outside the sample (six terminal, one trigger). The tallies in sections 2 to
6 can be recounted from Appendix A's Class, Route and Rec. columns.

## 9. The plan

The owner asked for "a plan for how models can answer their own questions based on
existing docs in a repo". The measurement makes the honest plan short: **build no lookup.**
Where a doc decided a question, the session had already read it and followed it. What
reached the owner was a record that a rule told the session to file. So the plan is about
those rules, it is small, and whether to act on it is the owner's choice (9.6).

### 9.1 Where would a lookup live? (divergent design, seeded with `docs/constraints.md`)

**Decision goal**: where, if anywhere, a "look in the docs before asking the owner" step
should live, given sections 2 to 8.

**Step 1: candidates.** Candidates 1 to 6 are the roadmap item's; 0 and 5b to 12 were
added here; 13 and 14 were added after review round 1 tested the first draft's rule
against the recent entries.

| # | Candidate | One line |
|---|---|---|
| 0 | Status quo | Nothing new. Loops get the constraints file in their prompt and decide from it; the global instructions already say to check that an item needs a human. |
| 1 | Loop-prompt step | A "look before you ask" paragraph in the build-loop prompt: search the archive and the decision log before a blocked marker or a tentative pick's question. |
| 2 | Research-phase step | A lookup sub-step in research-plan-implement's research phase, with a recorded `Asked-before grep:` line, modelled on the failure-pattern lookup. |
| 3 | `questions.sh search` | A command that ranks archive entries and decision-log rows by the question's words. |
| 4 | Index of standing answers | A file the cycle keeps, one line per answer that set a rule. |
| 5 | `Looked in:` line | Every owner entry says which docs were checked; by prose in the entry grammar. |
| 5b | `Looked in:`, enforced | `questions.sh check` refuses a judgment entry without the line. |
| 6 | Into the constraints file | Move answers that recur into `docs/constraints.md`. |
| 7 | A general self-answer rule, in the skill | Where the orchestrator files a judgment entry, it names the standing-doc line that bears on the question; a line that decides it means act, do not file, and list the self-answer for the owner. |
| 7t | The same rule as a writing trial | One paragraph in the trial doc, this repo, two weeks, no skill change. |
| 8 | Self-answers as `you: fyi` entries | File the question pre-answered and have the owner acknowledge it. |
| 9 | Propose standing permissions | When the same authority ask has drawn the default N times, propose that the owner delegate it. |
| 10 | An answerer subagent | One dispatch per would-be question, to search the docs and rule. |
| 11 | A semantic index | Embeddings over every doc, queried before asking (the ideal if effort were free). |
| 12 | Two lines in the global instructions | Extend the questions section's existing "check the item actually needs a human": quote the standing-doc line that bears on it; if it decides, act and record it. Reaches every repo and agent. |
| 13 | Stop filing records as questions | Change the four standing lines that say "record the split as an interim in `questions.md`", and the like: an action already taken under a rule a doc states is recorded in the commit body and the cycle's final message, not as an entry. |
| 14 | No unrequested exceptions | A rule where entries are written: an entry does not ask whether to keep something a hard constraint rules out, unless its writer is itself recommending the exception; otherwise the fix is briefed and the build loop chooses among what the constraint leaves. |

Generation health check. *Clustering*: candidates 1, 2, 3, 4, 10 and 11 all assume the
gap is finding the doc. Review round 1 named that assumption, and 13 and 14, which change
what gets filed and not how it is looked up, were added to break it (9 already did).
*Missing perspectives*: a do-nothing option (0), a naive one (3), and an
ideal-if-effort-were-free one (11) are present. *Dimensional anchoring*: most candidates
change agent text; 3, 5b and 11 change tooling; 9 and 13 change what is filed at all.

**Step 2: problems and constraints.** Problems, each from the measurement:

- P1. Where a doc decides the question, the session already follows it, and the entry
  that still reaches the owner is one a rule requires (Q-142, Q-154, Q-199, Q-254; section
  2). What can be removed is a filing, about one a month.
- P2. Docs mislead and contradict each other (4 flagged conflicts, 6 doc-against-doc
  entries; section 5), so anything that acts on a doc must be easy to check and to undo.
- P3. Entries are written by the orchestrator or by a hand session, never by a build
  loop; 3 of the last 14 began as a loop's marker (section 3).
- P4. In-part entries often do not name the doc that bears on them (13 of 24 checked;
  section 2). A lookup can shorten such an ask. It cannot remove one: the owner's answer
  was needed in all 35.

Hard constraints, carried from `docs/constraints.md` with their `success:` lines:

- H1: code that gates, reviews or bounds a change runs from a copy that change cannot edit.
  success: `rg -n -- '"command": ' hooks/wiring.json | rg -v -F -- '{{CLAUDE_DIR}}/hooks/'` prints nothing, and a new gate or reviewer path is added to GATE_CODE in `scripts/lib/dev-cycle-read.sh`.
- H2: a gate or boundary fails closed and loudly; nothing ships present-but-inert.
  success: each new failure path has a bats case asserting a refusal (or a fall-through to the full step) and a message naming the gap; `rg -n -- '^[^#]*command -v [^|]*\|\| *exit 0' hooks scripts` prints only the three existing lines in `hooks/live-verify-gate.sh` and `hooks/claude-config-audit.sh`.
- H3: every behavioural change is verifiable inside the sandbox with hermetic tests.
  success: `bats` passes in the sandbox with new cases for the change, and `scripts/hermeticity-lint --root .` passes (both author to run).
- H4: an LLM judgment is a detector, never an enforcement primitive: a blocking gate keys on something re-checkable from the artifact, and a new judgment-based check ships advisory.
  success: `rg -n -e '^[^#]*claude -p' -e '^[^#]*claude_headless_flags' -- scripts/build-loop.sh scripts/dev-cycle.sh scripts/lib/dev-cycle-read.sh hooks/` prints nothing; a new judgment check is capped at amber.

The roadmap item's four guardrails are the brief's own lines. The brief says to keep them
or argue against them, so they rank candidates here and prune none:

- G1: a self-answer names its doc and quotes the line.
- G2: it is never used for what is the owner's by authority.
- G3: each one is listed for the owner after the fact, one line each.
- G4: no new stop and no new entry.

Soft constraints that bear: S2 (no new mandatory dispatch per pass; at most about 30 lines
of always-loaded context), S3 (reuse the existing mechanism; one source of truth, never
restated), S4 (mechanical steps in tested scripts; prose arrives at the moment it is
needed), S5 (establish the motive; the status quo is a valid outcome), S6 (a call site
something runs, and a benefit whose observable could come out negative), S7 (measure
before budgeting a saving), S8 (small units, one revert), S10 (spend the owner's attention
last), S11 (portable where it costs little). S1 (proportionate security) does not bear.

**Step 3: match and prune.** ✓ addresses or passes, ~ partial, ✗ does not address, ⚠ makes
worse. A candidate is discarded only for a ⚠ on a hard constraint or for ✗ almost
everywhere. The P columns ask: does it remove a required filing (P1), are its results
checkable and undoable (P2), does it sit with the writer of entries (P3), does it shorten
an in-part ask (P4).

| # | P1 | P2 | P3 | P4 | H1 | H2 | H3 | H4 | Fate |
|---|---|---|---|---|---|---|---|---|---|
| 0 | ✗ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | survives (the baseline) |
| 1 | ✗ | ~ | ~ | ~ | ✓ | ✓ | ✓ | ✓ | survives |
| 2 | ✗ | ~ | ~ | ~ | ✓ | ✓ | ✓ | ✓ | survives |
| 3 | ✗ | ~ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 4 | ✗ | ⚠ | ~ | ~ | ✓ | ✓ | ✓ | ✓ | survives (P2 is not a hard constraint) |
| 5 | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 5b | ✗ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ✓ | survives |
| 6 | | | | | | | | | set aside: not a home for a lookup; see 9.2 |
| 7 | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 7t | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 8 | ~ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | survives |
| 9 | | | | | | | | | set aside: delegation, not lookup; outside the goal |
| 10 | ✗ | ~ | ~ | ✓ | ✓ | ✓ | ✓ | ~ | survives |
| 11 | ✗ | ~ | ~ | ✓ | ✓ | ✓ | ⚠ | ✓ | discarded: not testable hermetically without an embedding model (H3) |
| 12 | ~ | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 13 | ✓ | ✓ | ✓ | ✗ | ✓ | ✓ | ✓ | ✓ | survives |
| 14 | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |

Notes on cells. [4] P2: an index restates the owner's answers in an agent's words, the
kind of doc that misled in Q-068. [5b] H2: a presence check on a free-text line is inert
against boilerplate. [7t] P1: the filings a doc had settled were required by the decision
log or by the skill, and acting in place of filing needs gate code, which a writing trial
cannot change. [7] P1: it can withhold only an entry of the orchestrator's own. [10] H4:
its verdict would decide what the owner sees.

Fourteen survive, so soft constraints and the guardrails rank them, and the top five go
to step 4.

| # | For | Against | Rank |
|---|---|---|---|
| 0 | S5, S7, S8, S10: nothing to pay, nothing unmeasured | removes nothing | top five |
| 13 | S3 (fixes existing lines, adds none), S4, S6 (a session that splits runs it), S8 | S10: one merge entry, and it amends decision-log rows 61 and 62 | top five |
| 14 | S3, S4 (read where entries are written), S6, S8 | S10: one gate-code merge entry and a release | top five |
| 7t | S6 (a measure that can come out negative), S8, S10 (no merge) | G3 is weak in a trial: nothing checks the quote, and silence passes | top five |
| 7 | S4, S6 | S7 (permanent before any measure), S10 (merge and release) | top five |
| 12 | S11 (every repo), S2 (two lines) | G3: no listing outside repos that run the dev cycle; S7 | sixth |
| 5 | G1 | S10: one more line in every entry the owner reads; removes no ask | below |
| 3 | P4 | S3 (`rg` and the archive's index already do it), S6 (nothing would call it), S8 (grows a 690-line gate script), S10 | below |
| 1 | | S2 (lines in every dispatch), S3 (the prompt already carries the constraints and the rule to decide) | below |
| 2 | S11 | S2 (a step in every research phase), S4 (not at the moment a question arises) | below |
| 5b | G1 | S8, S10, and H2's ~ | below |
| 4 | | S3 (one source of truth, never restated) | below |
| 8 | G3 | G4 and S10: a new entry per record | below |
| 10 | | S2: a new dispatch per question | last |

**Step 4: tradeoffs.** Effort is given as agent work and as what the owner pays, since
every home but the trial doc is a file whose change goes to them as a merge entry.

| # | Approach | Effort | Risk | Covers | Key downside |
|---|---|---|---|---|---|
| 0 | Status quo | none | none new | P2, P3 | About one entry a month still records what a doc settled; in-part asks stay as long as they are |
| 13 | Stop filing records as questions | one small docs unit (two workflow files), under an hour of a build loop; a decision-log row by the cycle; one merge entry for the owner | medium: it removes something the owner may use to follow the work | P1, P2, P3 | The owner stops being asked to confirm a split or a recorded ruling |
| 14 | No unrequested exceptions | one sentence in the dev-cycle skill; one gate-code merge entry and an image release | low: four hard constraints, each with a checkable `success:` line | P1 in part, P2, P3, P4 | A fix for a hard-constraint breach is briefed without asking first, so an exception the owner would have granted is not offered |
| 7t | General rule, writing trial | one paragraph in the trial doc; no merge | low | P2, P3, P4 | Tested against the three recent cases it withholds none |
| 7 | General rule, in the skill | about 10 lines of skill prose; one gate-code merge entry and a release | medium: permanent before any evidence | P1 in part, P2, P3, P4 | Costs a merge and a release and, as written, withholds none of the three |

**The back-test** (added in review round 1): each top-five candidate against the three
recent entries where a doc decided or nearly decided the question.

| Entry | [0] | [13] | [14] | [7t] | [7] |
|---|---|---|---|---|---|
| Q-199 (a split, recorded as the decision log says) | filed | not filed | filed | filed: a hand session wrote it, and the log still says to record it | filed, for the same reason |
| Q-254 (a blocked loop that had picked by S10) | filed | filed | filed | filed: the skill files one entry per blocked loop, and that is gate code | filed, unless the blocked-loop rule changes too |
| Q-272 (H2 rules out one of three options) | filed | filed | not filed: the fix is briefed and the loop chooses how to refuse | filed, with two options | filed, with two options |

Nothing short of a gate-code change reaches Q-254, and its question was about a paste on
the owner's machine, which the guardrail on the owner's time arguably keeps with them.

Falsifiable hypotheses:

- [0]: if nothing changes, hand-written judgment entries stay under 6 a week through
  November and at most one a month only records what a doc settled; counter-evidence would
  be two such entries in one week.
- [13]: if the lines change, no entry in the following month records a split or a ruling
  already acted on, and the owner reverses none of the records listed in the final
  messages; counter-evidence would be a reversed split, or the owner asking where the
  records went.
- [14]: if the rule ships, no entry in the month after the release asks whether to keep
  something a hard constraint rules out while recommending against it; counter-evidence
  would be one that does, or a briefed fix the owner reverts in favour of an exception.
- [7t]: if the trial runs, the digest lists at least one self-answer in two weeks and the
  owner reverses none; counter-evidence would be none listed (the back-test predicts
  this) or one reversed.
- [7]: as [7t], within a month of the release that carries it.

**Stress tests.**

- [0]. *Invert the thesis*: the owner asked for this, and four judgment entries were filed
  on 2026-11-10. Of those four, one is a merge approval (Q-271), one is the owner's by the
  roadmap's own wording (Q-269), and two are in part (Q-270, Q-272). No lookup would have
  removed any; [14] would have removed Q-272. *Revealed preferences*: when asks piled up,
  the owner changed a rule (the attestation stop, row 74) or a policy (self-merge, Q-103),
  and said they follow the work through their answers. Both leave [0] where it was.
- [13]. *Invert the thesis*: filing with an interim and going on is the global
  instructions' own design ("Append, don't block"), and a record in the questions file is
  one of the ways the owner sees what a session did. This raised its risk from low to
  medium. *Failure-driven*: a wrong split or a misheard ruling would no longer be put in
  front of the owner. The mitigation is where the record goes: the cycle's final message,
  which the owner reads first, not only a commit body.
- [14]. *Push to extreme*: extended to soft constraints it would drop options the owner
  wants, since a soft line misread the owner once in two recent tries (Q-256). It is
  limited to the four hard constraints. *Failure-driven*: a hard constraint can be misread
  too; each has a `success:` line to check the reading against, and the briefed fix goes
  through a build loop's review like any other.
- [7t]. *Boring alternative*: the back-test is the boring check, and it shows the rule
  reaching none of the three cases. *Failure-driven*: its measure, "none reversed", is
  met by silence, on a digest whose count of deliberate looks the running trial doc gives
  as "0 today".
- [7]. *Boring alternative*: as [7t]. *Organizational survival*: ten lines of skill prose
  with no check behind them, kept alive by a digest line.

**Decision presentation.**

```
┌─ DECISION: where a look-before-you-ask step should live, if anywhere ───────────────┐
│ 14 candidates survived step-3 pruning · the top 5 by soft-line rank are scored here │
└─────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #     approach                       effort              risk       coverage     key downside
  ────  ─────────────────────────────  ──────────────────  ─────────  ───────────  ─────────────────────────────────
   0  ★ status quo                      ● none              ● none     ● 4/4 hard   ◐ about one record-entry a month
   13   stop filing records             ● one docs unit     ◐ medium   ● 4/4 hard   ◐ owner no longer confirms records (mitig.)
   14   no unrequested exceptions       ◐ merge + release   ● low      ● 4/4 hard   ◐ a fix is briefed without asking
   7t   general rule, writing trial     ● one paragraph     ● low      ● 4/4 hard   ○ back-test: withholds none of three
   7    general rule, in the skill      ◐ merge + release   ◐ medium   ● 4/4 hard   ○ permanent, and withholds none

  expand a card by naming its #

╭─ [0] status quo   ★ recommended (tentative) ─────────────────────────────────────────╮
│ effort    none (no file changes)                 risk   none new                     │
│ coverage  4/4 hard · 9/9 soft (nothing is built, so none is strained)                │
│ hypothesis  If nothing changes, hand-written judgment entries stay under 6 a week    │
│             through November and at most one a month only records what a doc         │
│             settled; counter-evidence = two such entries in one week.                │
│ stress-tests applied                                                                 │
│   · Invert the thesis → no lookup removes any of the four entries of 2026-11-10;     │
│     [14] removes one                                                                 │
│   · Revealed preferences → the owner changes rules and follows the work through      │
│     answers; ranking unchanged                                                       │
│ key downside  about one entry a month still records what a doc already settled       │
╰──────────────────────────────────────────────────────────────────────────────────────╯

▶ recommend [0] status quo · confidence 65% · runner-up [14], then [13], axis = a merge to approve now vs. about one entry a month saved
```

**Decision.** On the question as posed, where a lookup should live, the answer is
nowhere, and that part is not close: every lookup candidate (1, 2, 3, 4, 5, 5b, 10, 11,
12) ranks below the top five or fails the back-test with [7] and [7t]. What is close is
[0] against [14] and [13], which are not lookups. Each of the two costs the owner one
merge to approve now and saves about one entry a month, and [13] also changes something
the owner may value. That is a question of the owner's taste, 65% is below the 80% at
which this loop may decide alone, and so this is divergent design's Path C: no option
clearly wins, the loop goes on with a tentative pick, and the owner settles it.

The repo states a preference on each side of the axis: S10 says to spend the owner's
attention last, and S5 and S7 say to establish the motive and measure before budgeting a
saving. The tiebreaker is the brief's own line, "if the share answerable from docs is
small, say so plainly and recommend not building", backed by S5. The tentative pick is
**[0]**. Nothing in this unit depends on it: no code or prose changes either way.

See alternatives considered → the pruned candidates below.

**Pruned candidates and why.** Each entry is `[candidate]: one-line reason for discard`.
Future passes in this area can grep this section to avoid regenerating them.

- Prior pruning grep: no matches found for [question, ask, lookup, archive, standing
  answer, self-answer]. The grep (`grep -B 1 -A 20 "Pruned candidates" docs/decisions/*.md
  | rg -i ...`) prints decision 040's list, which is about where agent items are kept, and
  incidental lines from seven other records; none concerns answering a question from a
  doc. Nothing is carried or revived from a decision record.
- [11] semantic index: not testable hermetically (H3).
- [6] into the constraints file: set aside; not a home for a lookup. The path exists (the
  `constraints-builder` skill's amend run), and 9.2 names it.
- [9] propose standing permissions: set aside; delegation, not lookup. Adjacent result
  carried: `docs/working/research-2026-11-06-merge-friction-design.md` left merge
  approvals as they are.
- [10] answerer subagent: survives the hard lines, ranked last on S2.
- [8] `you: fyi` self-answers: ranked out on G4 and S10.
- [4] index of standing answers: ranked out on S3; it also restates answers in an agent's
  words (P2).
- [5b] enforced `Looked in:`: ranked out on S8 and S10, with a ~ on H2.
- [1], [2], [3], [5]: ranked out on S2, S3, S4, S6 or S10 as the ranking table says. They
  could shorten an in-part ask; none removes an entry.
- [12] lines in the global instructions: sixth; no listing outside repos that run the dev
  cycle.
- [7t], [7]: reached step 4 and fell on the back-test.

**Stress-test mitigations.** How to read: *Failure-driven* mitigation on [13]: the record
goes in the cycle's final message, which the owner reads first, not only a commit body.
How to read: *Push to extreme* mitigation on [14]: limited to the four hard constraints,
after the move showed a soft line misreading the owner. How to read: *Boring alternative*
mitigation on [7t] and [7]: the back-test was added to step 4 and lowered both below [13]
and [14].

**Consequences.** Easier: nothing is added for a session to read or run, and the
roadmap's steps 2 to 4 can close. Harder: about one entry a month keeps reaching the owner
that a doc had settled, and an in-part ask stays as long as its writer makes it.

**Revisit triggers.** Each is a condition a future reader can check. If two entries in
one week only record what a doc settled. If hand-written judgment entries rise above 10 a
week for two weeks running. If another repo that runs these workflows files more than 10
judgment entries a week with no constraints file. If the owner reverses a tentative pick
that rested on a quoted doc line.

A note for the dev cycle: its revisit step reads decision records and decision-log rows,
not a working doc. If these triggers are to be watched, the row the cycle writes when it
records the owner's answer should carry them.

### 9.2 What to build, in what order

**Now: nothing** (the tentative pick). The existing path for an answer that deserves to
become a standing rule is the `constraints-builder` skill's amend run on
`docs/constraints.md`, at the deep audit (Q-269, the open entry on that audit's scope and
timing). That is the one positive step in this plan, and it is already on the roadmap.

**If the owner picks option [2] in 9.6**, two small wording units, in this order:

1. **No unrequested exceptions** (candidate [14]). One sentence beside the dev-cycle
   skill's "Attention is the budget" rule, to the effect of:

   > An entry does not ask whether to keep something that a hard constraint in
   > `docs/constraints.md` rules out, unless its writer is recommending an exception to
   > that constraint and says why. Otherwise the fix is written as a brief, and the build
   > loop chooses among the options the constraint leaves.

   Q-272 is the case: it asks whether to keep the weak-tool run as an exception to H2
   while recommending against it.

   The skill is gate code: one merge entry, live from the next image release. It goes
   first because its risk is lower and it would have removed the entry that prompted this
   work (Q-272).
2. **Stop filing records as questions** (candidate [13]). Reword the three workflow lines
   (`workflows/pr-prep.md` step 1a; `workflows/review-fix-loop.md`, the early split
   trigger and the size re-check) from "record the split as an interim in
   `docs/working/questions.md` and in the commit body's `Notes:` line" to the commit body
   and the cycle's final message. The cycle records the change as a decision-log row
   amending rows 61 and 62. `workflows/` is on the never-self-merge line: one merge entry.
   The same wording could cover an in-session ruling and a merge already made on a
   standing instruction (the Q-154 and Q-142 shapes), which today become entries by habit,
   not by a written line.

**Not recommended: a general self-answer rule** (candidates [7t], [7], [12]). If it were
ever tried, the order would be trial, then skill, then global instructions, each gated on
the one before. But the back-test says the trial would most likely list nothing, and a
trial of it has four problems as a trial: nothing checks the quote, "none reversed" is met
by silence, "undone by one `git revert`" has no clear meaning for an orchestrator that
dispatches a brief, and the cases that matter need gate code, which the trial doc excludes.

### 9.3 Guardrails

The roadmap item's four are kept. They apply to any self-answer, so to candidate [14]
and to anything like [7] later.

- **A self-answer names its doc and quotes the line.** Kept. It is what made every class
  in this doc checkable by a script (59 quotes, 59 found).
- **Never for what is the owner's by authority.** Kept. That class is half of everything
  asked.
- **Each one is listed for the owner.** Kept, and moved: in the cycle's final message,
  which the owner reads first, as well as the weekly digest. It is the only catch for a
  stale standing line (Q-027, Q-040), and it catches nothing unless it is read.
- **No new stop or entry.** Kept. It is what ranks out the `you: fyi` variant.

Three more follow from section 5:

- **Only a hard constraint or a recorded answer of the owner's decides; a soft constraint
  only ranks.** Among the last 14 entries a soft line matched the owner once and misread
  them once.
- **The line must be about this subsystem and this question.** Decision 034 was written
  for the benchmark harness and misled on the container launcher (Q-069).
- **The action must be undone by one `git revert`.**

What these do not cover: of the five flagged conflicts, a rule against agent-written
analyses and unconfirmed defaults removes two (Q-068, Q-152) and the scope test a third
(Q-069). Nothing but the after-the-fact listing catches a standing doc that is simply
stale (Q-027, Q-040).

### 9.4 What not to build

- **No search command** (`questions.sh search`), **no semantic index**, **no answerer
  subagent**. Where a doc decided a question, the session had read it. A search could
  shorten some in-part asks (about half of those checked did not name their doc), but
  `rg` over two files and the archive's generated index already serve a session that
  looks, and no ask would be removed.
- **No index of standing answers.** It would restate the owner's answers in an agent's
  words, and an agent-written summary was one of the docs that misled.
- **No `Looked in:` line or check.** It adds a line to every entry the owner reads and
  removes no ask; as a check on free text it invites boilerplate.
- **No look-before-you-ask paragraph in the build-loop prompt, and no lookup step in
  research-plan-implement.** The prompt already carries the constraints file and the rule
  to decide when one option dominates; the one recent loop that still ended blocked
  (Q-254) had looked.
- **No harvesting of answers into `docs/constraints.md` by a loop.** That file is the
  owner's; the amend run is the path.
- **Nothing aimed at the authority class.** Those asks end when the owner delegates, and
  the 2026-11-06 research found they are also how the owner follows the work.

### 9.5 Another repo that uses these workflows

Reasoned from this repo's structure and from `docs/working/feedback/philosophy-research.md`
(another project's reports on the dev cycle), without reading any other checkout.

- **The same shape is likely, with less to look in.** A repo that runs the dev cycle has
  the same writer of questions (the orchestrator), the same entry grammar and the same
  archive; the feedback file shows that project running the cycle with its own questions
  and watching files. A younger repo has a shorter archive, and earlier answers were the
  largest source here (15 of 39). A repo with no `docs/constraints.md` lacks the doc that
  bore on 3 of this repo's last 15 hand-written entries.
- **Its authority share depends on its merge policy.** Under `Build-loop policy: review`
  every finished branch is a merge entry, so the share no lookup can touch is higher than
  here.
- **Both wording changes in 9.2 would reach it without anything per repo.** The dev-cycle
  skill and the workflow files are installed from this repo into every project. The same
  is true of the filing rules that produce record-entries today, so another repo is
  probably paying the same small cost.
- **A general self-answer rule would not carry its safeguard with it.** The listing for
  the owner exists only where the dev cycle runs. That is one more reason it is not
  recommended.
- **The measurement can be repeated there**, at about this cost: six readers for 153
  entries and a seventh for 24, about 1.28 million tokens, plus review. A cheaper first
  look: read the last 14 hand-written entries and count how many a doc decided or nearly
  decided. Here that count is 3 (Q-199, Q-254, Q-272).
- **A repo without a constraints file probably gains more from writing one** (the
  `constraints-builder` skill) than from any lookup: here the fall from about 23
  hand-written questions a week to about 4 came in the weeks the constraints file landed
  and build loops began deciding from it, though three other things changed in those
  weeks too [inferred].

### 9.6 What the numbers cannot show, and the owner's choice

**What the numbers cannot show.**

- **Questions that were never filed.** The archive holds only the times a session did
  ask. Every time a model answered its own question from a doc, nothing was written here.
  As a rough sign: 36 of the 46 research docs dated October or November mention a design
  choice settled as "Path A" (one option dominates), and 6 mention a tentative pick. So
  2% is the share of filed questions a doc would have answered, not the share of all
  questions that docs answer.
- **Tentative picks that reached the owner outside the questions files.** A self-merge
  brief's tentative pick is quoted in the cycle record and the final message, not filed.
- **"Failed to self-answer" against "was told to file".** The classes do not separate
  them. For the four in full it was checked by hand (all four were told to file); for the
  35 in part it was not.
- **Whether the entry named its doc** was checked for 24 of the in-part entries by one
  reviewer, not recorded for all.
- **Whether the owner wants to be asked.** They have said they follow the work through
  their answers. All four in-full entries were answered with the default, one in a
  batched answer, and a default taken every time fits "the entries are right" and "the
  owner has stopped reading" equally well.
- **The recent sample is 14 entries.** "About one a month" rests on one to three of them.
- **The classes are one reader's judgment per entry**, and one class per entry. A second
  reader moved 3 of 20; the readers knew the owner's answer, which pushes the answerable
  classes up, and spent a few searches per entry, which pushes them down. An entry classed
  as authority can hide a half a doc answered: Q-131's size waiver was already inside an
  earlier answer's tolerance. The conflict count moves between 3 and 9 with how
  doc-against-doc entries are treated.
- **"Differed from the entry's recommendation"** counts interims, which are holding
  positions, and added conditions. It is not a count of wrong guesses.
- **What a wrong self-answer would have cost.** The conflicts are counted, not priced.
- **Why the volume fell.** Four changes fall in the same two weeks.

**The choice that is the owner's**, for the dev cycle to file. One question: given that 4
of 200 judgment entries were answered in full by a doc, and that all four were records a
rule told the session to file, how far should this go?

The candidate numbers refer to 9.1. In this table a "record" is an entry about something
a session has already done under a rule a doc states: a split of an oversized branch, a
ruling you gave in session.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Build nothing** (candidate [0]) | The roadmap item closes at step 1. Sessions keep deciding from the constraints file and filing what the rules say to file | None | About one entry a month still asks you to confirm what a doc already settled |
| **[2] Change the two filing rules** (candidates [14], then [13]) | An entry stops asking whether to keep something a hard constraint rules out, unless its writer recommends the exception. A record goes in the commit and the cycle's final message, not in the questions file | Two merge entries, one image release; your yes also amends decision-log rows 61 and 62 | An exception you would have granted is not offered: the fix is briefed first. You are no longer asked to confirm a split or a recorded ruling, so a wrong one shows only in a final message |
| **[3] A general self-answer rule** (candidates [7t], [7], [12]) | The orchestrator acts on any ratified doc line that decides a question and lists what it did; tried for two weeks, then written into the skill and the global instructions | Reading the listed lines; later two merge entries and a release | Tested on the three recent cases it would have withheld none; a wrong reading acts before you see it, and outside dev-cycle repos nothing lists it |
| **[4] Build the lookup tools** (candidates [3], [4], [5b]) | A `questions.sh` search, a `Looked in:` check and an index of standing answers, as the roadmap listed | Three or more merge entries and a release; one more line in every entry you read | It removes no ask. Some asks get shorter |

Interim and tentative pick: [1]. Nothing is built or changed until this is answered. The
tiebreaker is the brief's own rule (a small share means recommend not building) and S5,
the soft constraint that the status quo is a valid outcome. [2] is the runner-up, and the
one to pick if a needless ask a month bothers you more than one more merge to approve
does. Its two halves are independent: "[2], first half only" is a complete answer.
Options [3] and [4] are listed because the roadmap item proposed them; 9.1 ranks both
below [2].

Not part of this choice: the half of your asks that are yours by authority. Those end
only when you change a rule, as you did with the attestation stop. This doc proposes no
new delegation.
