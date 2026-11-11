# Research: how many owner questions did the repo's docs already answer?

- **Goal**: Measure, from this repo's own history, how often a question filed for the owner could have been answered from a doc that already existed, and turn the result into a plan for letting models answer their own questions from a repo's docs.
- **Problem framing**: The questions doc spends the owner's attention, and at least one recent entry looked answerable from a doc on main, so the question is how large that class is before anything is designed for it. Considered and discarded: "models ask because they cannot find the doc, so build a search" (in the three recent cases where a doc decided or nearly decided the question, the entry itself cited the line).
- **Project state**: this branch delivers one research doc, docs only · step 1 of the roadmap Now item "Models answer their own questions from the repo's docs", preparing its step 2 without building anything · not blocked (cite: docs/working/briefs/2026-11-11-self-answer-measure.md)
- **Task status**: in-progress (measured and written; review next)

Brief: `docs/working/briefs/2026-11-11-self-answer-measure.md` (self-merge, docs only).
Everything here was read at main's commit 963dbd4d. Sections 1 to 8 are the measurement,
the research notes and appendices are for agents, and the last section is the plan, what
the numbers cannot show, and the one choice that is the owner's.

Words used below.

- An **entry** is one `### Q-NNN` block in `docs/working/questions.md` (open) or
  `docs/working/questions-archive.md` (answered): a question a session filed for the owner.
- Its **route** is its `Needs:` line. `you: judgment` needs the owner's taste or authority.
  `agent` is the older route for work an agent could do without the owner; since
  2026-10-29 such items live on the roadmap instead.
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
- H1 to H4 and S1 to S11 are the hard and soft design constraints in `docs/constraints.md`.
  Each is glossed where it is used.
- `[observed]`, `[inferred]` and `[assumed]` say how a claim is known: read or run here,
  derived from what was read, or not checked.

## Summary

**The share is small. Of the 200 answered `you: judgment` entries, 4 (2%) were answered in
full by a doc that existed when they were filed, and only 2 of those 4 were real asks.**

| Class | Entries | Share of 200 |
|---|---|---|
| In full | 4 | 2.0% |
| In part | 37 | 18.5% |
| None | 56 | 28.0% |
| Authority | 103 | 51.5% |

- **Half of everything asked was the owner's by authority.** 43 merge approvals, 25
  requests to attest that a commit on main had been reviewed, and 35 hand-written asks to
  land a unit, waive a review cap or change a recorded decision. A doc lookup answers none
  of these. What removed them, each time, was a rule the owner changed: the attestation
  stop was dropped on 2026-10-20 (decision log row 74), this repo went to self-merge on
  2026-10-17 (Q-103, the entry that set the build-loop merge policy), and a standing
  instruction of 2026-10-09 let clean units merge on the recommendation (in Q-137's answer).
- **The four "in full".** Q-154 was filed already answered (the plan it came from recorded
  the owner's ruling). Q-142 rests on that standing instruction, and a second reader put
  its twin, Q-141, under authority. The two real ones are Q-199 (the decision log said an
  over-cap unit splits without asking; the entry asked anyway) and Q-254 (a soft
  constraint, S10, "at most one host paste per verification", picked the option).
- **In both real cases the asker already had the line.** Q-199 cites the log row and Q-254
  names S10 as its tiebreaker. So does the open Q-272, the entry that prompted this work:
  it quotes H2 ("a degraded primitive refuses"). Finding the doc was not the gap. Acting on
  it was.
- **"In part" means the ask got shorter, not that it could be skipped.** In 9 of the 37
  the owner still chose against the entry's own recommendation.
- **Docs also pointed the wrong way.** In 4 judgment entries a doc, read plainly, named a
  different answer than the owner gave, as many as were answered in full. One of the four
  docs was the global instructions.
- **The class a lookup would act on has already shrunk.** Hand-written judgment entries
  ran at 13 to 28 a week from mid-September to mid-October and at 2 to 6 a week since
  2026-10-19, after the constraints file landed and build loops began deciding design
  choices from it. Of the 14 filed since then, 2 were answered in full.
- **Earlier answers held the most.** Of the 41 judgment entries answered in full or in
  part, 17 rest on one of the owner's earlier answers in the questions archive; the
  constraints file holds 2, because it has existed for only the last three and a half weeks.
- **Two readers agreed on 21 of 24 entries** re-classed blind (17 of the 20 hand-read
  ones), and where they differed the lower class stands.

**Recommendation: do not build a lookup.** No search command, no index of standing
answers, no `Looked in:` check. The plan in the last section says what the numbers do
support (one rule about acting on a line the asker already holds, tried as a writing trial
if the owner wants it) and ends with that choice as one options table.

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
are in neither questions file today. Six of those nine (Q-079, Q-097, Q-125, Q-147, Q-168,
Q-173) were agent or deferred items that the migration of 2026-11-01 (aaf10eed) moved to
the roadmap; three (Q-157, Q-158, Q-159) never reached either file [observed].

**No entry is unrouted today**, but 14 of the 221 had no `Needs:` line when first
committed (12 now judgment, 2 now agent). Section 3 gives the classes by route at filing
as well.

**The entry's commit.** A python3 pass walked every commit that touched either questions
file, oldest first, and took the first one holding the entry's heading (Appendix C). For
206 of the 221 that commit is the entry's commit. For 15 it is not, and an earlier commit
was used so that the docs read are the ones the asker had:

- 10 entries opened between 2026-09-12 and 2026-09-17, before IDs existed (their headings
  were first committed on 2026-09-17, some already answered): the last commit on main's
  history up to the end of the day in the entry's `Opened:` line.
- 5 entries first committed straight into the archive, already answered (Q-113, Q-114,
  Q-115, Q-118, Q-154): the parent of that commit.

Docs were read with `git show COMMIT:PATH` and searched with `git grep ... COMMIT`, never
from the working tree. A doc line that only records the entry's own answer never counts.

**Two families were classed by rule, not read one by one** (68 entries), because their
question is fixed by the script or step that writes them:

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
an exact substring of `git show COMMIT:PATH` at the entry's commit: all matched [observed]. Appendix A lists
every hand-read entry with its class and the reason; Appendix B lists every quote.

Readers also recorded, per entry: the owner's answer in brief, whether it matched the
entry's own recommendation or interim, whether a doc conflicted with it, and whether the
entry re-asked an earlier one.

**The second pass.** A seventh reader, with the same rules and none of the first pass's
classes, re-classed 24 entries: 20 drawn from the 153 hand-read ones and 2 from each
rule-classed family, with python3's `random.Random(20261111).sample`. Section 7 has the
agreement. Where the two passes differ, the lower class stands, in the order in full, in
part, none, authority (authority last because it is the class a self-answer may never
touch).

**What was run.** Seven read-only subagents, about 1.28 million tokens in all (the sum of
the seven runs' reported totals) [observed]. No headless model run, no trial, no change to
any script, skill or questions file. The brief's "no model run only to measure" is read as
ruling out experiments (asking a model to answer old questions and scoring it); reading
and classing the entries is the measurement itself.

## 2. The shares

**Judgment entries, answered (200).**

| | In full | In part | None | Authority | Total |
|---|---|---|---|---|---|
| Read one by one | 4 | 37 | 56 | 35 | 132 |
| Merge entries (rule) | 0 | 0 | 0 | 43 | 43 |
| Attestation entries (rule) | 0 | 0 | 0 | 25 | 25 |
| **All** | **4 (2.0%)** | **37 (18.5%)** | **56 (28.0%)** | **103 (51.5%)** | **200** |

Leaving authority out, 97 questions remain that a doc could in principle have answered: 4
in full (4%), 37 in part (38%), 56 not at all (58%).

**The four in full**, with the line that answered each (Appendix B has the paths):

| Entry | The question | The doc line | How strong |
|---|---|---|---|
| Q-142 | A unit past the review cap: one more narrow fix and merge, or stop? | Q-137's answer in the archive: "merges and review adjustments like this one go ahead on the recommendation without asking." | Weak. The session had already merged on its interim. The second pass put its twin, Q-141, under authority. |
| Q-154 | A full dev cycle every iteration, or a light pass between? | The build-loop plan: "You answered on 2026-10-04: a full cycle every iteration for now ..." | Not a real ask: filed ten days after the owner ruled in session, to put the ruling on record. |
| Q-199 | A 570-line branch was split into three units: keep the split or waive the cap? | Decision log row 62: "In /away mode the agent splits without asking and records the split as an interim ..." | Real. The entry cites row 62 for "only you can waive the cap" and overlooks its next sentence. |
| Q-254 | A build loop's blocked question: fix the branch before the owner's host paste, or paste now and again later? | `docs/constraints.md`, S10: "at most one host paste per verification" | Real, but S10 is a soft constraint. The loop named it as its tiebreaker and picked the option the owner then gave. |

**Agent-route entries, counted apart (18).** In full 5, in part 5, none 8. These are not a
rate to rely on. The five "in full" (Q-078, Q-080, Q-089, Q-092, Q-160) are work orders of
the form "implement Q-X's answer": the doc that "answers" them is the owner's answer they
were written from. The readers also differed on how to class a work order with no
question in it (one batch said in full, another none). They are in Appendix A.

**All 218 answered entries together**: in full 9 (4.1%), in part 42 (19.3%), none 64
(29.4%), authority 103 (47.2%).

**The three open entries** (no owner answer to compare, classed on the question alone):

| Entry | Asks | Class | Why |
|---|---|---|---|
| Q-269 | Scope and timing of the deep audit | Authority | The roadmap item's own first step is "the owner confirms scope and timing". |
| Q-270 | A light pass between full dev cycles? | In part | Q-154's answer gives the direction ("once the costs are visible") but not the rule, nor whether unrecorded token costs count as visible. |
| Q-272 | When the test-confinement script loses its strong tool: run under the weak one, or refuse? | In part | H2 ("a degraded primitive refuses and names what went unenforced") rules out running, unless the owner records an exception. It does not choose between refusing always and refusing unless a flag asks. |

Q-272 is the entry the roadmap item cites as answerable from H2. Read strictly it is "in
part": H2 removes one of three options, and the entry says so itself. What H2 leaves is a
design choice between two ways of refusing, which a build loop could have made without the
owner. So the entry was avoidable, but by acting on H2 and delegating the rest, not by
finding H2.

**Did the owner take the entry's own recommendation?** Among the 132 hand-read judgment
entries, 98 stated a recommendation or took an interim that was one of the options. The
owner's answer matched it in 48 and differed in 50 [observed from the readers' lines; "differed"
includes an added condition that changed the work].

| Class | Matched | Differed | No recommendation |
|---|---|---|---|
| In full | 4 | 0 | 0 |
| In part | 15 | 9 | 13 |
| None | 10 | 30 | 16 |
| Authority (read) | 19 | 11 | 5 |

Where no doc answered, the asker's own guess was wrong three times in four. That is the
population a self-answer must stay out of. Where a doc narrowed the question, the guess was
still wrong 9 times in 24.

## 3. By route and by month

**By route today** (answered entries).

| Route | In full | In part | None | Authority | Total | In full or in part |
|---|---|---|---|---|---|---|
| `you: judgment` | 4 | 37 | 56 | 103 | 200 | 20% |
| `agent` | 5 | 5 | 8 | 0 | 18 | 56% |
| All | 9 | 42 | 64 | 103 | 218 | 23% |

**By route when first committed.**

| Route at filing | In full | In part | None | Authority | Total |
|---|---|---|---|---|---|
| `you: judgment` | 3 | 33 | 53 | 98 | 187 |
| `agent` | 5 | 3 | 7 | 1 | 16 |
| `trigger` | 0 | 1 | 0 | 0 | 1 |
| No `Needs:` line | 1 | 5 | 4 | 4 | 14 |

**By month opened**, judgment entries (answered).

| Month | In full | In part | None | Authority | Total | In full or in part |
|---|---|---|---|---|---|---|
| September | 0 | 19 | 43 | 6 | 68 | 28% |
| October | 3 | 16 | 12 | 79 | 110 | 17% |
| November (to the 10th) | 1 | 2 | 1 | 18 | 22 | 14% |

Agent-route entries by month: September 13 (in full 4, in part 4, none 5), October 5 (1,
1, 3), November none.

September's questions were mostly new design and policy calls with no doc to lean on (43
of 68 "none"). October's were mostly authority: the build-loop handoff's landing and cap
asks, then the attestation and merge entries. The share answered in full never rose above
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
2026-10-19. Several things changed in the two weeks before: the constraints file landed
(first committed 2026-10-15, in its present form from 2620b419 on 2026-10-19); the
orchestrator began dispatching build loops (2026-10-16), whose prompt carries the
constraints and tells them to decide a design choice themselves when one option dominates;
the repo went to self-merge (2026-10-17); and the large hand-run build-loop work, the
source of most of October's landing and cap asks, ended. Which did how much, these numbers
cannot say [inferred].

**Since 2026-10-19**, the 14 hand-written judgment entries: in full 2 (Q-199, Q-254), in
part 6 (Q-213, Q-238, Q-246, Q-247, and the open Q-270 and Q-272), none 4 (Q-221, Q-223,
Q-226, Q-256), authority 2 (Q-200, and the open Q-269). That is three and a half weeks, so
about one entry a fortnight was answered in full. Merge entries, 38 in the same period,
are now the bulk of what the owner is asked.

## 4. Which docs held the answers

For the 41 judgment entries answered in full or in part (answered entries only):

| Kind of doc | In full | In part | Total |
|---|---|---|---|
| An earlier answer of the owner's, in the questions archive | 1 | 16 | 17 |
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
  work.** Q-081 leans on Q-070's answer of the day before, Q-063 on Q-059's of hours
  before, Q-093 on Q-091's. A lookup here would mostly have meant "re-read the owner's
  last answer on this topic".
- **The constraints file is thin in this table because it is young**, not because it is
  weak. It existed for the last 14 hand-written entries only, and bears on 3 of them
  (Q-213, Q-254, Q-272).
- **The repo rules (`CLAUDE.md`) answered nothing.** They are coding rules, and no entry
  asked about one.

## 5. Where the doc and the owner's answer disagreed

Five entries are flagged as conflicts, four of them judgment entries. These are the cost
of answering from docs: a model trusting the doc would have done something the owner did
not want.

| Entry | The doc said | The owner said | Stale, or a change of mind? |
|---|---|---|---|
| Q-040 | The global instructions: on a misframing signal inside divergent design, run the `design-space-situating` skill | Divergent design's own Double Diamond first; that skill only if it fails | Stale. The instruction was rewritten after the answer. The plainest case: a ratified, always-loaded doc pointed the wrong way. |
| Q-068 | The 2026-09-17 triage marked "keep the self-improvement loop and resume it" as Drop | Resume: "this was the intent all along" | Neither: the doc was an agent's analysis and was wrong about the owner's intent. |
| Q-069 | Decision 034 rejected scanning `.git` for dangerous config keys ("the next one will be missed too") | Scan `.git` at session exit | The decision was scoped to the benchmark harness; the owner decided differently for the container launcher. (A later review found the scan could not be a guarantee, which is what 034 had argued.) |
| Q-152 | The build-loop plan's default: when every thread waits on the owner, poll every 20 to 30 minutes | Stop the loop | A change of mind on a default the plan itself had flagged as unconfirmed. |
| Q-027 (agent route) | Decision 023 named two archived docs as "the procedure for a bare host install" | The work replaced them with a new guide | Stale. |

Three authority entries carry the same warning in their notes: the doc as written pointed
to the option the owner then replaced (Q-087: decision 031's "k=1" became k=3 on the final
pass; Q-140: the approved plan's trust root was changed; Q-153: the owner narrowed their
own global rule on branch deletion). They are authority, so no self-answer would have
touched them, but they show that recorded decisions get reversed at about the rate they
get re-confirmed.

Against the 4 judgment entries answered in full, then, stand 4 where the doc misdirected.
A careful reader would not have called most of those four docs deciding (an agent's
triage, a decision scoped elsewhere, a default flagged unconfirmed). Q-040 is the one that
would have passed any rule: a standing instruction, plainly worded, wrong.

## 6. Re-asks

31 of the 221 entries re-ask an earlier one [observed from the readers' lines].

- **24 are one chain**: the build-loop handoff's "may this unit land", "waive the size
  cap" and "allow a fourth review iteration" asks between 2026-10-05 and 2026-10-30
  (Q-111 to Q-148, then Q-171, Q-174, Q-199, Q-238). 17 of the 24 are authority: at each of
  those commits the docs reserved the act to the owner (decision log row 62: "only the
  user can waive the cap"; the review-fix-loop workflow: "only their explicit authorization
  permits iteration 4"), and each earlier answer was for that unit only. A lookup would
  have confirmed "you must ask" every time. What ended the chain was the standing
  instruction in Q-137's answer and the size rule in Q-104's.
- **7 are single follow-ups**: Q-048 (of Q-035), Q-063 (of Q-059), Q-093 (of Q-091),
  Q-124 (of Q-081), Q-226 (of Q-223), Q-247 (of Q-246), and the open Q-270 (of Q-154).

By class the 31 are: in full 2, in part 11, none 1, authority 17. So an earlier entry
settled a re-ask twice (Q-142 and Q-199, both discussed above) and narrowed it 11 times.

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
  reader (3 of 20). Applied to 132 hand-read judgment entries, that is some 20 entries.
- **The moves do not all go one way.** One lowered "in full", one raised "none" to "in
  part", one moved between the two classes no doc can answer. There is no sign that the
  first pass over- or under-counts the answerable share.
- **The boundary between none and authority is the softest.** The six first-pass readers
  also drew it differently: one classed a change to a recorded decision as authority,
  another classed a change to an enforcement hook's scope as none. It moves no entry into
  or out of "in full" or "in part".
- **One reading carries five entries.** Q-138, Q-142, Q-143, Q-144 and Q-148 rest on the
  same standing-instruction line as Q-141. If the second reader's reading of Q-141 were
  carried to them, "in full" would be 3 and "in part" 33. Only Q-141 was in the sample, so
  only Q-141 was lowered.

## 8. What the measurement says

1. **Most asks were for permission, not information.** 103 of 200. They ended when the
   owner delegated: self-merge, the standing instruction, the dropped attestation stop,
   the per-iteration size rule. No lookup would have ended them, and a lookup is barred
   from them by the roadmap item's own guardrail.
2. **Of the asks for information, most had no doc.** 56 of 97. They were new design and
   policy calls, and the asker's own guess was wrong three times in four.
3. **Where a doc narrowed the ask (37), the owner's answer was still needed**: to pick
   among what was left, to confirm a default the plan had flagged as unconfirmed, or to
   say whether an earlier answer reached this far. These entries could have been shorter.
   Some recent ones already are: Q-272 quotes H2 and says which option it rules out.
4. **Where a doc decided the ask (2 real cases, a third in part), the asker held the line
   and filed anyway.** Q-199 read "only you can waive the cap" and stopped reading. Q-254's
   loop picked by S10 and still ended blocked. Q-272 quotes H2 and asks whether to follow
   it.
5. **A doc that decides is about as common as a doc that misleads** (4 and 4), and the
   misleading kinds are nameable: an agent-written analysis, a default flagged as
   unconfirmed, a decision scoped to another subsystem. One was none of these (Q-040).
6. **The volume has already fallen** to 2 to 6 hand-written judgment entries a week. The
   mechanisms that did it are the ones a lookup would duplicate: the constraints file in
   the loop prompt, and divergent design deciding from it.

So the measured benefit of answering from docs, at today's volume, is about one entry a
fortnight, with a wrong answer about as likely as a right one unless the kinds of doc are
restricted. That is small. The plan in the last section starts from there.

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
  `handoff: blocked` marker, or of its `handoff: ready` marker after a tentative pick, and
  the orchestrator files or quotes it (`skills/dev-cycle/SKILL.md`, "The only questions
  writer" and step 7). [observed]
- The build-loop prompt (`scripts/build-loop.sh`, the dispatch text) quotes
  `docs/constraints.md` in full and tells the loop to run divergent design for a choice
  with three or more options: decide when one dominates, go on with a tentative pick when
  none does, end blocked only when no option survives the hard constraints or the answer is
  a fact only the owner has. [observed]
- The global instructions' "Running questions document" section already says: "Before
  routing to `you: judgment`, check the item actually needs a human". It does not say what
  to check against. [observed]
- The weekly digest (step 9 of the skill) has an ask counter: asks opened and answered,
  and how often the owner picked the default. Two trial sets govern how the cycle writes
  (`docs/working/trials/2026-10-30-friction-engagement.md`, kept, and
  `docs/working/trials/2026-11-06-attention-and-trust.md`, running). A trial changes only
  how the cycle writes, so it needs no merge and no image release. [observed]
- Where each candidate home for a lookup sits, for cost: `scripts/build-loop.sh`,
  `scripts/questions.sh` and `skills/dev-cycle/` are gate code, `workflows/` is on this
  repo's never-self-merge line, and the global instructions are an instruction file. A
  change to any of them goes to the owner as a merge entry, and gate code also waits for an
  image release before it runs. `docs/constraints.md` is the owner's own record. [observed]

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
  decided to change nothing: the owner said they follow the work through these answers.
  This doc's merge family (43, to 2026-11-10) agrees with it, and candidate [9] below is
  set aside on its strength.
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
  question: 17 early entries got their headings five days after they were opened, and 5
  were committed already answered. Section 1 says which commit was used instead.
- Entry text is read as it stands today. Two entries were rewritten after filing (Q-149
  with a wider interim, Q-221 with a new option after the owner's notes); the readers
  classed against the filed state where they noticed.
- The constraints file and the repo rules were first committed on 2026-10-15 (83b653d2)
  and were on main by 78d0b15a (2026-10-17), before the commit titled "Project constraints
  doc" (2620b419, 2026-10-19). The five entries filed on 2026-10-15 predate them.
- An `Answered` line in an agent-route entry often records work done, not an answer.
- `git grep` at an old commit searches that commit's tree, but a path that did not exist
  then prints nothing rather than failing; the quote check uses `git show`, whose failure
  is loud.

#### Prior failures

- FP-108, FP-110, FP-114 (a count summed what produced output, so failures left the
  denominator): every table here states its denominator (258 in the files, 221 in scope,
  218 answered, 200 judgment, 132 read), and the entries left out are listed in section 1.
- FP-153 (counts written from recollection): every number in sections 1 to 7 is printed by
  the analysis script from the readers' result files; Appendix A lets a reader recount them.
- FP-088 (agreement overstated by counting replicates): the second pass is one independent
  reader on 24 entries, reported as 21 of 24, with the 4 rule-classed entries shown
  separately so they do not pad the rate.

### Design choices

The brief's own lines are the hard constraints for the measurement choices: the classes,
the entry's commit, the hindsight guard, the blind second pass, no model run only to
measure. H1 to H4 concern gates and tests and bear on none of D1 to D5. Options are pruned
only on the brief's lines or on a plain fact; soft constraints only rank. D6, where a
lookup would live, is the last section's divergent-design pass.

**D1. How much of the sample to read** (divergent design, Path A).

| Candidate | Brief's lines | Notes |
|---|---|---|
| A. Every in-scope entry | passes; the brief's first choice | 221 entries, 153 of them read; needs parallel readers |
| B. Every Nth entry | passes, as the brief's fallback | by-month and by-route cells get too thin to report (S7, measure before budgeting, wants the real figure) |
| C. The last 80 | passes, as the fallback | 65 of the last 80 by ID are merge or attestation entries, so it would measure almost nothing |
| D. Rule-class everything by slug | fails: the hand-written entries have free slugs | |

Pick: A. It is feasible, and it is what the brief asks for when feasible. One option
dominates.

**D2. Which commit's docs to read, when the heading was committed late** (Path A).

| Candidate | Brief's lines | Notes |
|---|---|---|
| A. The first commit holding the heading, always | fails for 22 entries: that commit can already hold the answer, or be five days late | |
| B. The last commit before the `Opened:` day began | passes | too early: it drops docs written the same day, which the asker had |
| C. The last commit up to the end of the `Opened:` day; the parent, for entries committed already answered | passes | can include the answer's own edits, so "a line that only records this entry's answer never counts" was made a rule, and one reader re-checked the 2026-09-12 batch against the earlier state |

Pick: C. B loses real docs; C's risk has a named guard. One option dominates.

Other choices, one line each:

- D3, the merge and attestation entries: classed by rule from the slug, with four checked
  blind by the second pass, because the step that files them fixes the question.
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
| The plan picks for the owner | the last section gives one options table and marks its pick as tentative |

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
| Q-081 | 09-27 | J | PART | [2] spike enableWeakerNestedSandbox first | no | The owner's answer to Q-070 the day before had already asked for a sandbox config in cc-isolated, which names building over accepting as the default, but nothing weighed the newly found kernel and image cost or suggested spiking the weaker mode first. |
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
| Q-246 | 11-01 | J | PART | [1] re-dispatch | none | The owner had just approved merging this exact branch (Q-244 [1]) and the merge was refused only for a conflict with a sibling unit, so 'drop' was against a recorded answer; the dev-cycle skill still required a stopped entry with re-dispatch/drop options. |
| Q-247 | 11-01 | J | PART | [1] re-dispatch | none | Re-ask of Q-246. Same as Q-246 for a sibling branch: the owner had just approved its merge (Q-243 [1]) and only a conflict refused it, so the earlier answer ruled out 'drop' though the skill's stopped-entry rule still asked. |
| Q-254 | 11-03 | J | FULL | [1] fix the branch first, then one paste | yes | The two options differed on one host paste versus two, and the constraints file's S10 line (at most one host paste per verification), which the build loop itself cited as its tiebreaker, picks the option the owner gave. |
| Q-256 | 11-05 | J | NONE | [2] one pass now: build the script, add 1-2 candidates | no | When to run the canon proposal filter was a timing call; the owner's 2026-09-27 note fixed the filter's shape but not its timing, the loop read S5 as favouring a deferred pass, and the owner chose to build now. |
| Q-269 | 11-10 | J | AUTH | none yet | n/a | Open. Asks the owner whether to spend compute on a deep audit and at what scope, which the dev-cycle skill reserves to them ('The user confirms its scope and timing') and which leads to promoting or dropping constraints. |
| Q-270 | 11-10 | J | PART | none yet | n/a | Open. Standing permission. Re-ask of Q-154. The owner's Q-154 answer already said to keep a full cycle for now and move to a light pass once the costs are visible, which gives the direction and the present default but not the rule for when a full cycle returns, nor whether unrecorded token costs count as 'visible'. |
| Q-272 | 11-10 | J | PART | none yet | n/a | Open. Hard constraint H2 says a degraded primitive refuses, which rules out the merged run-and-warn behaviour unless the owner records an exception, but it does not choose between refusing always and refusing unless a flag asks for the weak mode. |

## Appendix B: the doc and the line, for every in full, in part and conflict

Each line was checked as an exact substring of the file at the commit shown.

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
| Q-246 | PART | `docs/working/questions.md` at 22ccde91 | earlier-answer | **Answered:** [1] (owner, in session 2026-11-01: "Q-243..245: [1]"; recorded by the dev cycle) |
| Q-247 | PART | `docs/working/questions.md` at 22ccde91 | earlier-answer | **Answered:** [1] (owner, in session 2026-11-01: "Q-243..245: [1]"; recorded by the dev cycle) |
| Q-254 | FULL | `docs/constraints.md` at 585dd1a7 | constraints | S10: Spend the user's attention last: at most one host paste per verification, no new recurring host chore or trust decision, nothing left behind to clean up |
| Q-270 | PART | `docs/working/questions-archive.md` at 34721a82 | earlier-answer | **Answer (2026-10-04, in session; plan D12; filed 2026-10-14):** [1], a full cycle every iteration for now; move to a light pass of steps 7, 8 and 10 between full cycles once the costs are visible. |
| Q-272 | PART | `docs/constraints.md` at f5823c4c | constraints | H2: A gate or boundary fails closed and loudly: a missing dependency, unparseable or unmodelled input, absent verdict or degraded primitive refuses and names what went unenforced; nothing ships present-but-inert, and degradation only ever narrows access. |

## Appendix C: how each entry's commit was found

Run from the repo root. It prints, for each ID, the first commit whose copy of either
questions file holds the entry's heading. Section 1 says which 22 entries then use an
earlier commit.

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

The live file is walked first, so an entry seen in both is dated from the live file. The
earlier commit for the 22 exceptions is `git rev-list -1 --before=OPENED-DAYT23:59:59
963dbd4d` for the 17 early entries, and `git rev-parse COMMIT^` for the 5 committed
already answered. The tallies in sections 2 to 6 can be recounted from Appendix A's Class,
Route and Rec. columns.

## 9. The plan

The owner asked for "a plan for how models can answer their own questions based on
existing docs in a repo". The measurement says the honest plan is short: **build no
lookup; the models already find the docs.** What is left is one small rule about acting on
a line the asker already holds, and whether to try it is the owner's choice (9.6).

### 9.1 Where would a lookup live? (divergent design, seeded with `docs/constraints.md`)

**Decision goal**: where, if anywhere, a "look in the docs before asking the owner" step
should live, given sections 2 to 8.

**Prior pruning grep.** `grep -B 1 -A 20 "Pruned candidates" docs/decisions/*.md | rg -i
"question|ask|lookup|archive|standing answer|self-answer"` returns only decision 040's
list, which is about where agent items are kept, not about answering questions. Prior
pruning grep: no matches found for a lookup; nothing is carried or revived from a decision
record. One adjacent result outside `docs/decisions/` is carried:
`docs/working/research-2026-11-06-merge-friction-design.md` decided to leave merge
approvals as they are (see candidate [9]).

**Step 1: candidates.** The first six are the roadmap item's; the rest are added here.

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
| 7 | Filing-time rule, in the skill | Where the orchestrator files a judgment entry (it is the only questions writer), it names the standing-doc line that bears on the question; a line that decides it means act, do not file, and list the self-answer in the weekly digest. |
| 7t | The same rule as a writing trial | One paragraph in the running trial doc, this repo, two weeks, no skill change. |
| 8 | Self-answers as `you: fyi` entries | File the question pre-answered and have the owner acknowledge it. |
| 9 | Propose standing permissions | When the same authority ask has drawn the default N times, propose that the owner delegate it. |
| 10 | An answerer subagent | One dispatch per would-be question, to search the docs and rule. |
| 11 | A semantic index | Embeddings over every doc, queried before asking (the ideal if effort were free). |
| 12 | Two lines in the global instructions | Extend the questions section's existing "check the item actually needs a human": quote the standing-doc line that bears on it; if it decides, act and record it. Reaches every repo and agent. |

**Step 2: problems and constraints.** Problems, from the measurement:

- P1. The asker holds a line that decides the question and files anyway (Q-199, Q-254,
  half of Q-272). About one entry a fortnight.
- P2. A doc can misdirect (4 judgment conflicts), so a self-answer must be easy to check
  and to undo.
- P3. The population is small and has one main writer: 2 to 6 hand-written judgment
  entries a week, filed by the orchestrator or by a hand session, never by a build loop.
- P4. Finding the doc is not the gap: in all three recent cases the entry cites the line.

Hard constraints (repo lines keep their labels; B lines are the brief's guardrails):

- H1: code that gates a change runs from a copy the change cannot edit.
  success: a new check, if any, is in `GATE_CODE` in `scripts/lib/dev-cycle-read.sh` and runs from the image.
- H2: a gate fails closed and loudly, and nothing ships present-but-inert.
  success: each new failure path has a bats case asserting a refusal and a message naming the gap.
- H3: every behavioural change is verifiable in the sandbox with hermetic tests.
  success: `bats` passes with new cases for any script change, and `scripts/hermeticity-lint --root .` passes.
- H4: an LLM judgment is a detector, never an enforcement primitive; a new judgment-based check ships advisory, and anything that blocks keys on something re-checkable (a verbatim quote with file and line).
  success: every self-answer line carries a path and a quoted line that `grep -F` finds in that file, and nothing refuses or merges on a model's reading of it.
- B1: a self-answer is never used for what is the owner's by authority.
  success: no self-answer line concerns a merge entry, a release, a change or exception to a hard constraint or recorded decision, or a spend of the owner's time or money.
- B2: no new stop and no new kind of entry.
  success: `questions.sh open` lists no new route or slug family, and the dev-cycle skill gains no stop.
- B3: each self-answer is listed for the owner after the fact, one line each.
  success: the weekly digest file under `docs/working/weekly/` has a self-answer part, saying "none" when empty.

Soft constraints that bear: S2 (no new mandatory dispatch per pass; at most about 30 lines
of always-loaded context), S3 (reuse the existing mechanism; one source of truth, never
restated), S4 (mechanical steps in tested scripts; prose arrives at the moment it is
needed), S5 (establish the motive; the status quo is a valid outcome), S6 (a call site
something runs, and a benefit whose observable could come out negative), S7 (measure
before budgeting a saving), S8 (small units, one revert), S10 (spend the owner's attention
last), S11 (portable where it costs little). S1 (proportionate security) does not bear.

**Step 3: match and prune.** ✓ addresses or passes, ~ partial, ✗ does not address, ⚠ makes
worse. A candidate is discarded for a ⚠ on a hard line or for missing the measured
problems (P1 to P4, plain facts). Soft lines only rank what is left.

| # | P1 acts on a held line | P2 checkable, undoable | P3 sits where questions are written | P4 not a search | H1-H3 | H4 | B1 | B2 | B3 | Fate |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives (the baseline) |
| 1 | ~ | ~ | ✗ loops do not file | ✗ | ✓ | ✓ | ✓ | ✓ | ~ | discarded: P3, P4 |
| 2 | ✗ | ~ | ✗ wrong phase, wrong writer | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | discarded: P1, P3, P4 |
| 3 | ✗ | ~ | ~ | ✗ | ✓ with tests | ✓ | ✓ | ✓ | ✗ | discarded: P1, P4 |
| 4 | ✗ | ⚠ an agent's summary of the owner's answers is the kind of doc that misled in Q-068 | ~ | ✗ | ✓ | ✓ | ✓ | ✓ | ✗ | discarded: P1, P2, P4 |
| 5 | ~ shows the line, does not act on it | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | survives |
| 5b | ~ | ✓ | ✓ | ✓ | ~ a presence check on free text is inert against boilerplate (H2) | ✓ | ✓ | ✓ | ~ | survives, ranked last |
| 6 | ✗ | ✓ | ✗ | ✓ | ✓ | ✓ | ⚠ the constraints file is the owner's; a loop may only propose | ✓ | ✗ | set aside: not a home for a lookup, and the path exists (the `constraints-builder` skill's amend run) |
| 7 | ✓ | ✓ | ✓ | ✓ | ✓ prose only | ✓ quote, advisory | ✓ by the rule's wording | ✓ | ✓ | survives |
| 7t | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | survives |
| 8 | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ⚠ a new entry per self-answer | ✓ | discarded: B2 |
| 9 | ✗ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ it asks the owner | ⚠ a new kind of entry | ✗ | discarded: B2; also outside the goal (it is delegation, not lookup) and carried from the 2026-11-06 research, which left merge approvals alone |
| 10 | ~ | ~ | ~ | ✗ | ✓ | ~ | ✓ | ✓ | ~ | discarded: P4 |
| 11 | ✗ | ~ | ~ | ✗ | ⚠ not hermetic without a model or an index package (H3) | ✓ | ✓ | ✓ | ✗ | discarded: H3, P4 |
| 12 | ✓ | ~ no digest outside repos that run the dev cycle | ✓ and hand sessions too | ✓ | ✓ prose only | ✓ | ✓ | ✓ | ~ | survives |

Six survive: [0], [7t], [7], [12], [5], [5b]. [5] is folded into [7] and [7t] from here on:
the filing-time rule already has the writer name the line, which is all [5] asks. [5b]
stays as the enforcement variant.

**Step 4: tradeoffs.** Effort and cost are stated in what the owner pays, since every
home but the trial doc is a file whose change goes to them as a merge entry.

| # | Approach | Effort | Risk | Covers | Key downside |
|---|---|---|---|---|---|
| 0 | Status quo | none | none new | P2, P3, P4; not P1 | An asker holding the deciding line still files: about one avoidable entry a fortnight |
| 7t | Rule as a writing trial | one paragraph in the trial doc; no merge, no release | low: about one self-answer a fortnight, each listed and each revert-clean | P1 to P4 | May yield nothing in two weeks, and so prove nothing |
| 7 | Rule in the dev-cycle skill | about 10 lines of skill prose; one gate-code merge entry and one image release | medium: permanent before any evidence | P1 to P4 | Costs the owner a merge and a release to save under one ask a week |
| 12 | Lines in the global instructions | 2 or 3 lines; one merge entry and an install; every repo | medium to high: reaches repos with no weekly digest, where a wrong self-answer goes unseen | P1, P3, P4; P2 in part | No after-the-fact check outside dev-cycle repos |
| 5b | Enforced `Looked in:` | a check, tests, a gate-code merge and a release | low | P3, P4; P1 in part | Adds a line to every entry the owner reads and removes no ask |

Falsifiable hypotheses:

- [0]: if nothing changes, hand-written judgment entries stay near 3 a week through
  November and at most one a week cites a doc line that decides it; counter-evidence would
  be two or more such entries in one week.
- [7t]: if the trial runs, then within two weeks the digest lists 1 to 3 self-answers, the
  owner reverses none, and hand-written judgment entries a week do not rise;
  counter-evidence would be a reversed self-answer, or none listed at all (the rule is
  inert).
- [7]: as [7t], within a month of the release that carries it; counter-evidence the same.
- [12]: if the lines ship, another repo's questions archive shows an entry citing its own
  deciding line less often than this one did (3 in the last 14); counter-evidence would be
  a self-answer the owner reverses in a repo with no digest to list it.
- [5b]: if the check ships, every new entry names a doc or says none; counter-evidence
  would be boilerplate ("Looked in: constraints, nothing") in most entries within a month.

**Stress tests.**

- *Boring alternative* (on [7t] and [7]). Is there something simpler with most of the
  benefit? Yes: [0]. The loop prompt already tells a loop to decide when one option
  dominates, and the measured gap is one entry a fortnight. This raised [0] from "the
  baseline" to a real contender.
- *Invert the thesis* (on [0]: argue for building). The owner asked for this, and four
  judgment entries were filed on 2026-11-10. Of those four, one is a merge approval
  (Q-271), one is the owner's by the roadmap's own wording (Q-269), and two are "in part"
  (Q-270, Q-272). None would have been removed by a lookup; Q-272 would have lost one of
  its three options. What survives of the case for building is P1, and only P1.
- *Revealed preferences*. When asks piled up, what did the owner do? Each time they
  changed a rule: dropped the attestation stop (row 74), chose self-merge (Q-103), gave
  the standing instruction (Q-137), let an in-session answer count (Q-230). They also said
  they follow the work through their answers (the 2026-11-06 research). So the lever the
  owner reaches for is delegation, which is theirs, and they do not treat every ask as
  waste. This lowers the value of removing an occasional ask and leaves the ranking as it
  was.
- *Failure-driven* (on [7], [7t], [12]). The new failure is a wrong self-answer from a
  doc that misleads. Section 5 names the kinds: an agent's analysis, a default flagged
  unconfirmed, a decision scoped elsewhere. A rule can exclude those. It cannot exclude
  Q-040, a standing instruction that was simply stale. So the after-the-fact listing (B3)
  carries real weight, and it works only if the owner reads it; the running trial doc says
  the count of deliberate looks is "0 today". This raised [12]'s risk to medium to high and
  added two guardrails in 9.3 (the action must be revert-clean; only owner-ratified docs
  decide).

**Decision presentation.**

```
┌─ DECISION: where a look-before-you-ask step should live, if anywhere ───────────────┐
│ 5 candidates survived step-3 pruning · scored on the step-4 axes                    │
└─────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint

   #     approach                     effort              risk       coverage     key downside
  ────  ───────────────────────────  ──────────────────  ─────────  ───────────  ──────────────────────────────
   0  ★ status quo                    ● none              ● none     ● 7/7 hard   ◐ one avoidable entry a fortnight
   7t   rule as a writing trial       ● one paragraph     ● low      ● 7/7 hard   ◐ may yield nothing in two weeks
   7    rule in the dev-cycle skill   ◐ merge + release   ◐ medium   ● 7/7 hard   ○ permanent before any evidence
   12   lines in global instructions  ◐ merge + install   ○ med-high ◐ 6/7 hard   ○ no listing outside cycle repos (mitig.)
   5b   enforced `Looked in:`         ○ check + release   ● low      ◐ 6/7 hard   ○ removes no ask

  expand a card by naming its #

╭─ [0] status quo   ★ recommended (tentative) ─────────────────────────────────────────╮
│ effort    none (no file changes)                 risk   none new                     │
│ coverage  7/7 hard · soft: S5, S7, S8, S10 met; S6 not applicable                    │
│ hypothesis  If nothing changes, hand-written judgment entries stay near 3 a week     │
│             through November and at most one a week cites a doc line that decides    │
│             it; counter-evidence = two or more such entries in one week.             │
│ stress-tests applied                                                                 │
│   · Boring alternative → [0] is itself the boring version of [7t]; raised to a      │
│     real contender                                                                   │
│   · Invert the thesis → the case for building reduces to P1, one entry a fortnight   │
│   · Revealed preferences → the owner's lever has been delegation; ranking unchanged  │
│ key downside  an asker holding the deciding line still files, about once a fortnight │
╰──────────────────────────────────────────────────────────────────────────────────────╯

▶ recommend [0] status quo · confidence 60% · runner-up [7t], axis = fewer asks vs. the owner's own check on a model's reading
```

**Decision: Path C, a tentative pick.** [0] and [7t] are within a cell of each other, and
60% is below the 80% that would let this loop decide. The axis is how much the owner wants
an occasional ask removed against how much they want to be the one who reads the doc. The
repo states a preference on each side: S10 says to spend the owner's attention last, and
S5 and S7 say to establish the motive and measure before budgeting a saving. The
tiebreaker is the brief's own line, "if the share answerable from docs is small, say so
plainly and recommend not building", backed by S5. So the tentative pick is **[0]**, and
the choice between [0] and [7t] goes to the owner in 9.6. Nothing in this unit depends on
the pick: no code or prose changes either way.

**Pruned candidates and why.** Each entry is `[candidate]: one-line reason for discard`.
Future passes in this area can grep this section to avoid regenerating them.

- [1] loop-prompt step: build loops do not write questions, and the gap is not search.
- [2] research-phase step: the wrong phase and the wrong writer; the gap is not search.
- [3] `questions.sh search`: the gap is not search; `rg` over two files and the archive's
  generated index already do it.
- [4] index of standing answers: restates the owner's answers in an agent's words, the
  kind of doc that misled in Q-068.
- [6] into the constraints file: the owner's file; not a home for a lookup; the amend run
  already exists.
- [8] `you: fyi` self-answers: a new entry per self-answer (B2).
- [9] propose standing permissions: a new kind of entry (B2); delegation, not lookup;
  carried from `research-2026-11-06-merge-friction-design.md`, which left merge approvals
  alone.
- [10] answerer subagent: the gap is not search.
- [11] semantic index: not hermetic (H3); the gap is not search.
- [5] folded into [7] and [7t]. [5b], [7] and [12] survive step 3 and rank below [0] and
  [7t]; they are the later steps in 9.2 if the trial earns them.

**Stress-test mitigations.** How to read: *Failure-driven* mitigation: added the
revert-clean and owner-ratified-doc guardrails to 9.3 after the move showed that a rule
excluding weak docs still lets a stale standing instruction through. How to read: *Boring
alternative* mitigation: promoted the status quo from baseline to the tentative pick after
the move showed the loop prompt already covers the build-loop half.

**Revisit triggers.** Each is a condition a future reader can check. If two or more
hand-written judgment entries in one week cite a doc line that decides them. If
hand-written judgment entries rise above 10 a week for two weeks running. If another repo
that runs these workflows files more than 10 judgment entries a week with no constraints
file. If the owner reverses a tentative pick that rested on a quoted doc line.

### 9.2 What to build, in what order

Nothing, unless the owner picks the trial. If they do, the order is:

1. **A two-week writing trial of one rule** (candidate [7t]), added to the running trial
   set as its next number. The rule, as it would be written:

   > Before filing a `you: judgment` entry of its own, the orchestrator names the line
   > that bears on the question in a doc the owner has ratified: `docs/constraints.md`,
   > a decision record or decision-log row, an earlier recorded answer of the owner's, or
   > the global instructions. If that line decides the question and the action is undone
   > by one `git revert`, it does not file: it acts on the line and writes
   > `Self-answered: QUESTION · PATH: "LINE" · did WHAT` in the cycle record and in the
   > weekly digest. If the line only narrows the question, it files as now, quotes the
   > line, and drops the options the line rules out. Never for a merge entry, a release,
   > a change or exception to a hard constraint or a recorded decision, or a spend of the
   > owner's time or money.

   Two weeks, not one: at one entry a fortnight a single week would most likely show
   nothing. The measure can come out negative: a self-answer the owner reverses ends the
   trial; no self-answer in two weeks means the rule is inert and is dropped.
2. **Only if the trial lists two or more self-answers and none is reversed**: write the
   rule into the dev-cycle skill beside its "Attention is the budget" rule (candidate
   [7]). One small unit; it is gate code, so one merge entry and it runs from the next
   image release.
3. **Only after that has run for a month without a reversal**: the two-line form in the
   global instructions' questions section (candidate [12]), which is what carries it to
   hand sessions and to other repos. One unit, one merge entry.

The narrowing half of the rule (quote the line, drop the options it rules out) is where
most of the measured overlap is: 37 "in part" against 4 "in full". It removes no ask. It
makes an entry shorter, and recent entries mostly do it already.

### 9.3 Guardrails

The roadmap item's four are kept, with the reasons the measurement gives, and two are
added.

- **A self-answer names its doc and quotes the line.** Kept. This is what made every
  class in this doc checkable by a script (59 quotes, 59 found), and it is H4's "something
  re-checkable from the artifact".
- **Never for what is the owner's by authority.** Kept, and it matters more than it looks:
  that class is half of everything asked.
- **The weekly digest lists each one.** Kept, with a warning: it is the only catch for a
  stale standing doc (Q-040), and it catches nothing unless it is read.
- **No new stop or entry.** Kept. It is what rules out the `you: fyi` and enforced-check
  variants.
- **Added: only a doc the owner has ratified can decide.** An agent's analysis, a plan
  default flagged as unconfirmed, and a decision scoped to another subsystem each misled
  once (Q-068, Q-152, Q-069). Such a doc may narrow a question; it may not close one.
- **Added: the action must be undone by one `git revert`.** A self-answer is a model's
  reading. If the reading is wrong, the cost should be one revert and one line in the
  digest.

### 9.4 What not to build

- **No search command** (`questions.sh search`), **no semantic index**, **no answerer
  subagent**. In every recent case where a doc decided or nearly decided the question,
  the entry already cited the line.
- **No index of standing answers.** It would restate the owner's answers in an agent's
  words, and agent-written summaries were among the docs that misled. The archive's
  generated index already lists each answer in one line.
- **No `Looked in:` check** in `questions.sh`. It adds a line to every entry the owner
  reads, removes no ask, and a presence check on free text invites boilerplate.
- **No look-before-you-ask paragraph in the build-loop prompt, and no lookup step in
  research-plan-implement.** Build loops do not write questions; their prompt already
  carries the constraints file and tells them to decide when one option dominates.
- **No harvesting of answers into `docs/constraints.md` by a loop.** That file is the
  owner's. Where an answer deserves to become a constraint, the `constraints-builder`
  skill's amend run is the existing path, and the deep audit (Q-269, open) is where it is
  due to run.
- **Nothing aimed at the authority class.** Those asks end when the owner delegates, and
  the 2026-11-06 research found they are also how the owner follows the work.

### 9.5 Another repo that uses these workflows

Reasoned from this repo's structure and from `docs/working/feedback/philosophy-research.md`
(another project's reports on the dev cycle), without reading any other checkout.

- **The same shape is likely, with less to look in.** A repo that runs the dev cycle has
  the same writer of questions (the orchestrator), the same entry grammar and the same
  archive; the feedback file shows that project running the cycle with its own questions
  and watching files. A younger repo has a shorter archive, and earlier answers were the
  largest source here (17 of 41). A repo with no `docs/constraints.md` lacks the doc that
  bore on 3 of this repo's last 14 entries.
- **Its authority share depends on its merge policy.** Under `Build-loop policy: review`
  every finished branch is a merge entry, so the share no lookup can touch is higher than
  here.
- **What carries over is the rule, not a tool.** Steps 2 and 3 of 9.2 are the portable
  forms: the dev-cycle skill reaches every repo that runs the cycle from the image, and
  the global instructions reach every session. Neither needs anything per repo.
- **The listing does not carry over by itself.** The weekly digest exists only where the
  dev cycle runs. In a repo without it, a self-answer would be recorded in the commit
  body's `Notes:` line, which nobody is asked to read. That is why step 3 waits for
  evidence, and why it is the riskiest step.
- **The measurement can be repeated there for about what it cost here**: 153 entries read
  by seven subagents, about 1.28 million tokens. A cheaper first look is the count this
  doc ends on: how many of the last 14 hand-written entries cite a doc line that decides
  them. That takes one read of 14 entries.
- **Before any of this, a repo without a constraints file probably gains more from
  writing one** (the `constraints-builder` skill) than from a lookup: here the fall from
  about 25 hand-written questions a week to about 3 came in the weeks the constraints file
  landed and build loops began deciding from it, though other things changed in those
  weeks too [inferred].

### 9.6 What the numbers cannot show, and the owner's choice

**What the numbers cannot show.**

- **Questions that were never filed.** The archive holds only the times a session did
  ask. Every time a model answered its own question from a doc, nothing was written here.
  As a rough sign of how often that happens: 36 of the 46 research docs dated October or
  November mention a design choice settled as "Path A" (one option dominates), and 6
  mention a tentative pick. So the 2% is the share of *failures to self-answer* that a doc
  would have fixed, not the share of all questions that docs answer.
- **Tentative picks that reached the owner outside the questions files.** A self-merge
  brief's tentative pick is quoted in the cycle record and the final message, not filed.
  Those are not in the sample.
- **Whether a model would have trusted the line.** No model was run on old questions; the
  brief rules that out. The classes say a careful reader could have answered. The two real
  cases suggest finding was never the problem.
- **The classes are one reader's judgment per entry.** A second reader moved 3 of 20. The
  readers knew the owner's answer, which pushes "in full" and "in part" up if anything;
  they spent a few searches per entry, which pushes them down. Neither effect is measured.
- **The boundary between none and authority** moves with the reader, and the agent-route
  rows were classed inconsistently. Neither moves the 2% or the 18.5%.
- **Entries are read as they stand today**, and 15 use an estimated commit (section 1).
- **What a wrong self-answer would have cost.** The conflicts are counted, not priced.
- **Why the volume fell.** The constraints file, build loops deciding for themselves,
  self-merge, and the end of the large hand-run build-loop work all fall in the same two
  weeks.
- **The recent sample is 14 entries.** "One a fortnight" rests on 2.
- **Whether the owner wants to be asked.** They have said they follow the work through
  their answers. An ask a doc could have answered may still be worth its minute to them.

**The choice that is the owner's**, for the dev cycle to file. One question: how far to
take self-answering, given that 4 of 200 judgment entries were answered in full by a doc.

A "self-answer" here means: the orchestrator holds a line in a doc the owner has ratified,
the line decides the question, and it acts on the line without filing an entry, listing
what it did in the weekly digest.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Build nothing** | The roadmap item closes at step 1. Models keep deciding from the constraints file as they do now, and file what they are unsure of | None | About one entry a fortnight keeps reaching you although a doc already decided it |
| **[2] Two-week writing trial** | The rule in 9.2 joins the running trial set. No code, no merge; each self-answer is one line in the weekly digest | Reading that line, and saying so if one is wrong | A wrong reading acts before you see it; each is one `git revert`. The trial may also show nothing |
| **[3] Write the rule in now** | The rule goes into the dev-cycle skill and the global instructions without a trial | Two merge entries and an image release | It reaches every repo before any evidence, including repos with no digest to list a wrong one |
| **[4] Build the lookup tools** | A `questions.sh` search, a `Looked in:` check and an index of standing answers, as the roadmap listed | Three or more merge entries and a release; one more line in every entry you read | The effort goes where the measurement found no gap: askers already cite the line |

Interim and tentative pick: [1]. Nothing is built or changed until this is answered. The
tiebreaker is the brief's own rule (a small share means recommend not building) and S5,
the soft constraint that the status quo is a valid outcome. [2] is the runner-up, and the
one to pick if an occasional needless ask bothers you more than an occasional wrong
reading would.

Not part of this choice: the half of your asks that are yours by authority. Those end
only when you delegate, as you did with self-merge and the standing instruction. This doc
proposes no new delegation.
