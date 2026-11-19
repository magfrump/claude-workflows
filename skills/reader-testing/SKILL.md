---
name: reader-testing
description: >
  Test a draft post, entry or message against its venue's audience profile before it goes out. Fresh simulated readers
  read section by section, one per archetype, then do recall and goal-level tasks. A fresh
  grader marks them against a key written from the source of truth. Correctness errors go to a
  separate lane that blocks posting. Output is findings plus a revision brief; revisions go to
  new readers. Needs a profile (audience-profiles). Not a style critique (draft-review).
  Triggers: "reader-test this", "test this post on readers", "simulated readers", "would a
  maintainer follow this", "re-run the reader test".
requires:
  - name: audience-profiles
    description: >
      The venue's profile at docs/audiences/<venue>.md. Without it there are no archetypes or
      task templates; run audience-profiles first.
---

> On bad output, see guides/skill-recovery.md

# Reader Testing

Find out whether the readers a post is for can do what they came to do, before it is posted. A
"post" here is any text with a profiled reader: a public post, or a single decision entry or message
to one owner.
Simulated readers are heuristic evaluation, not testing: their findings are leads until a real
reader or a check confirms them. **The output is testimony, pass/fail per task and a revision
brief. It has no composite score.**

The worked examples are in claude-workflows: the full-tier O20 pilot, `docs/working/o20-2026-11-17/`,
and the light-tier Q-278 run, `docs/working/reader-testing/q278-2026-11-18/`. The rules come from the design notes `docs/working/audience-skill-notes.md` and the pilot's own
"Notes for the `reader-testing` skill" (its `findings.md`). Briefs to copy are in `references/`:
`reader-brief.md` (each reader), `grader-brief.md` (grading and synthesis), `verifier-brief.md`
(the correctness lane), `run-templates.md` (tasks, key, predictions, findings).

## Tiers

| Tier | For | Readers | Lanes | Cost seen so far |
|---|---|---|---|---|
| **Full** | a public post, a paper, anything with an attachment | one simulated reader per archetype, plus real readers where possible | all, including attachment tasks and the verifier | about 530k subagent tokens for five sessions (O20) |
| **Light** | one entry or message to one reader | the one or two archetypes that act on it, plus the real reader | grader, and the verifier on every candidate checkable against the repo or the sources | about 250k for two simulated sessions and a grader (Q-278: 63k, 75k and 115k subagent tokens at completion) |

On the light tier, plan for the real reader to be the only independent second session. In Q-278 the
convergent-reasons test cut most overlaps between the two simulated readers to one hit, and every
surviving two-hit finding but two had the real reader as its second hit. That is one run, so treat
it as a planning assumption, not a rate.

## Roles, and what each may see

| Role | Who | May read | Must not |
|---|---|---|---|
| **Orchestrator** (the author's chair) | this session | everything | grade tasks, count convergence, or give verdicts on correctness: it wrote the key, the briefs and maybe the draft, so it is warm. It does write the revision brief, Part A (from the verifier's verdicts), the style sweep and the notes for the skill |
| **Reader** | one fresh subagent per archetype, per round | its brief, the stimulus as it is released, and the files the brief adds (knowledge documents, attachment, linked source), all in its own folder | see the key, the repo, the web, other readers, the draft's history, or the orchestrator's worries about it. It writes only inside its own folder (unzipping an attachment) |
| **Grader** | one fresh subagent per round | everything in the run folder, including the key, and the profile | predict reader behaviour from the text, or add findings no session supports |
| **Verifier** | one fresh subagent per batch of correctness candidates | the candidates, the stimulus, the attachment and the external standards they cite | rewrite the post |
| **Real readers** | the author, and anyone else willing | the same tasks and stimulus; never the key | be counted as fresh when they aren't (record their contamination) |

## The run folder

`docs/working/reader-testing/<post-slug>-<YYYY-MM-DD>/`, holding:

- `post.md`: the frozen stimulus, with its sha256 (and the attachment's) in `tasks.md`;
- `tasks.md`, `key.md`, `predictions-<reader>.md`, `findings.md` (templates in `run-templates.md`);
- `sessions/<archetype>[-r<round>].md`, one per reader session, saved by the orchestrator.

A re-run after revision is a **new folder**, linking the one before.

## Step 1: Freeze the stimulus and choose the cuts

Copy the post (and title) to `post.md` and record both hashes. Split it into **numbered sections**
at its own headings. Then record in `tasks.md` one **release grouping per archetype**: which sections
go out together, following the profile's "How they read". The first group is that archetype's blind
cut. Release together what the reader reads together. In Q-278 one release held an options table
without the recommendation under it. The reader stopped on the table, so the post's answer to its
objection was never tested. Choose the **blind cut** deliberately: it should end where the opening ends,
so the first take measures the opening rather than whichever paragraph line 11 fell on. Write the
choice and its reason in `tasks.md`.

## Step 2: Write tasks, then the key

From the profile's task templates, write 3–6 tasks per archetype, in that archetype's reading
order. Each task is a goal the reader would bring, observable, with **positive signals,
negative signals and the section where it should be answered**. Tasks that check the opening are
graded **per element** (answer, status, conditions: each yes or no). "Partly" can't tell "the
answer is there but its conditions aren't" from "nothing is there".

For an entry an agent will act on, add one task per option whose label the text reuses elsewhere,
each giving a bare answer such as "The owner answers `[1]`". A reused label reads two ways, and only a
bare answer tests it.

Then write `key.md` **from the source of truth, not from the draft**: the research notes, the
problem page, the code. A key written from the draft inherits the draft's framing. A key the post's
author writes shares the author's frame even from other sources. Say so in the key's header, take the
gist from a source the author didn't write where one exists, and expect a real reader who rejects the
frame to contest the key (step 6). Mark required
elements ● and credit elements ○. Also write the **intended gist**: the problem, insight, key move
and finding that recall will be graded against.

## Step 3: Pre-register predictions

Before any real reader starts, write `predictions-<reader>.md`: what you expect their first take,
stops and task answers to be, each with a credence about this one run (never a rate). Commit it
before the session; the commit is the timestamp. Record known contamination at the top: if the
real reader worked on the result, or anything they were told gives an answer away, say so, and
treat those predictions as weak evidence either way.

**Predict only what the session's form can observe.** A real reader who reads the whole text and then
answers the tasks leaves no first take, stops or links opened. In Q-278 four of eleven predictions
couldn't be scored. Either collect those observations: ask the opening-alone task before they read
on, and one line on where they stopped and what they opened. Or don't predict them.

**Predict the stop first, and make the rest depend on reaching it.** A real reader may quit early,
so a prediction about a later section can't be scored. Make P1 *where this reader stops* (a
section, or "the end"). Give every other prediction the section it **needs**, and score a
prediction whose section was never reached as **not reached**, not as a miss. In the O20 pilot
the author stopped a third of the way in. Seven of nineteen predictions assumed a full read, and
the stop-count prediction (15–30) missed at 4, which said more about the assumption than about the
post.

## Step 4: Run the simulated readers

One fresh subagent per archetype, all in one message so they run in parallel. Fill in
`references/reader-brief.md` **verbatim** for each.

- **Isolation.** Copy the released files into a fresh scratch folder per reader, **outside the
  repo**, and pass file paths only, never pasted text. The brief carries the archetype from the profile (who, the
  question they bring, stake, patience budget, pain triggers, how they read) and the knowledge
  limit **as documents** copied into the folder, never a hand-written notation list. Isolation
  is advisory, and only writes can be checked afterwards, not reads. So keep `key.md` out of reach
  while readers run: write it in step 2 to the orchestrator's scratchpad, put its sha256 in
  `tasks.md`, and copy it into the run folder only after the last reader session ends. After each
  session, check that nothing was written outside its folder (the pilot's builder wrote one file
  outside).
- **Staged release, no lookahead.** An instruction not to read ahead failed in the pilot: the
  first take loaded the whole post. Release by mechanism instead: the reader's folder starts with
  the blind cut only. Record each reader's agent ID from the spawn result. When the reader ends
  its reply with its first take, its opening-alone answers and its written **expectations for
  the next section**, copy the next section in and continue the same agent by that ID
  (`SendMessage`) with part 4 of the brief. Repeat until every section is released. On
  "skim", keep releasing; on "stop", release nothing more. Either way, after the last release or
  the stop, send part 5. Without `SendMessage`, put every
  section in as its own file and instruct section-by-section reading, and **label the run
  "instruction-only staging"** in `findings.md`.
- **Quitting is a finding.** The brief says when this reader would stop (patience budget, pain
  triggers) and that stopping there is a valid result, and it never hints whether the draft is
  good or bad.
- **After the reading, before the tasks: recall from memory.** Retell the problem, the insight,
  the key move and the finding without rereading. A section called clear and then misrecalled is
  the finding.
- **Then the tasks**, each with the answer, the quoted sentences and section relied on, or "not
  in the text". The opening-alone elements were already answered at the first take, before the
  rest of the post existed in the folder. A point resolved only by a **linked doc** counts as not
  resolved by the post, and the grader marks it *missing*. A point resolved by a knowledge file is
  what this reader already knows: the reader names the file, and the grader logs it without
  grading it. The reader flags answers it **assembled from several places**, which is how
  "buried" shows. Background knowledge is tagged "[from my own knowledge]". Where the post links
  a source (a problem page), the reader answers before opening it and again after, if it opens
  it at all.
- **Attachment tasks** (builder, maintainer): from a fresh unzip, run it and report wall-clock
  times; that is how the pilot's build-time mismatch surfaced. Tell the maintainer how far to read
  the attachment: statements yes, proofs no.
- Each reader returns its report across its replies. Save them, in order, as one file under
  `sessions/`.

Cost, for budgeting: the pilot's five sessions took about 530k subagent tokens (the builder 158k,
mostly a dependency fetch).

## Step 5: Run the real readers

Same tasks, same first-take instruction, same staging where possible, no key. When a real reader
asks the orchestrator something mid-session, answer neutrally once, log it in their session file,
and mark everything after it as contaminated. Append every question a real reader asks to the
profile's evidence.

- **Mark the answers given after a stop.** Ask a real reader for one line on where they stopped,
  and which tasks they answered after it. Those answers come from a skim and their own knowledge,
  not from the post. The grader still grades them, but tags each one **post-stop**. A post-stop
  fail on a point the post makes only after the stop is *buried*, not *missing*: the point is in
  the post, but past where this reader got. In the O20 pilot the author answered E3–E6 after
  "bored".
- **A test of a live entry is testimony, not the entry's answer.** When the stimulus is still awaiting
  a decision (an open questions entry), the real reader's task answers don't answer it, even when a
  task asks "answer this in one line". Record an answer only when the reader gives it with the
  entry's own ID (`Q-NNN: …`), outside their task answers. In Q-278 the owner's answers were recorded as the
  entry's answer, and that was wrong: the owner had misread what the entry was about.
- **Settle an unsettled reading with the reader, not the verifier.** When a real answer could be
  either a deliberate reframe or a misreading the text invited, ask the reader which, in one line,
  before grading it as a frame or acting on it. If the reader is away, file that line as a
  `you: judgment` entry in the questions doc, and leave the task graded *pending reader* until it
  is answered. Never settle it from the grader's credences.
- **Ask follow-ups before showing the reader any grading.** A reply given after the reader has seen
  how they were graded is contaminated in the grading's direction. In the O20 pilot, the author
  answered the E4 and E6 follow-ups after reading the orchestrator's own grading. Send the
  follow-up questions first, and share grades only after the fresh grader has run.

## Step 6: Grade and synthesize (fresh grader)

Start one fresh subagent with `references/grader-brief.md`. It reads the run folder and returns
`findings.md` as its final message; the orchestrator saves it. If a real session arrives after
grading, **run a fresh grader again** over the whole folder: calibration only closes that way. It:

1. **Grades each task** against the key: **pass** (every ● element, nothing contradicted, status
   right), **partial**, **fail**, **key contested** (a real reader deliberately rejects the frame the
   key assumes, so the key may be what's wrong), or **pending reader** (an unsettled reading, item
   7). A key-contested task goes into the revision brief as a frame to settle with the reader. A
   pending task is re-graded by a fresh grader once the reader answers. A misreading the reader would repeat is a fail even when the
   rest is right. Each failure gets a type: *missing*, *buried*, *misread*, *undefined*,
   *overreach*, *attachment*.
2. **Grades recall** against the intended gist. Behaviour outranks words.
3. **Marks every candidate finding KEEP, GENERIC or DUPLICATE.** GENERIC means it would apply to
   any post and any reader.
4. **Runs the convergent-reasons test before counting convergence.** Every simulated reader is the
   same model, so four hits can be one prior in four vocabularies. A finding counts as convergent
   only when the readers' *reasons* can't be swapped between their entries and still read
   naturally. **Three or more sessions with non-swappable reasons is systemic**; one is a lead.
5. **Gives severity:** **S1** a misreading likely to be repeated, or a rejection at the venue's
   screen; **S2** a task this archetype exists to do can't be done; **S3** it can be done, with
   friction; **S4** cosmetic. Each finding is also tagged text-surface (most reliable), affective
   (a range of possible reactions, not a prediction) or institutional (a prompt for the author's
   judgment).
6. **Scores the predictions** against the real sessions, and compares each simulated finding with
   the real reader of that archetype. A simulated finding the real reader contradicts is
   downgraded. A real-reader-only finding is the most valuable kind. Until the real session is in,
   that archetype's findings are marked **uncalibrated**. Simulated readers may read more carefully
   than real ones. In one run (Q-278) both caught a subject named once inside a gloss, while the
   rest of the entry used a near-synonym, and the real reader missed it. So a simulated catch never
   clears a real reader's miss, and a real reader misreading the subject is S1.
7. **Lists unsettled readings**: real answers that could be either a reframe or an invited misread,
   with both readings. The orchestrator asks the reader (step 5).
8. **Lists correctness candidates** separately (step 7), without verifying them.

## Step 7: The correctness lane

Readers who check claims against an external standard (the problem statement, a spec, the code,
the attachment) find real errors, which no exposition fix repairs. In order:

1. The grader lists every finding that says **the post is wrong, or says more than its sources
   show** (step 6.8).
2. A fresh verifier, briefed with `references/verifier-brief.md`, checks each one against the
   standard it cites: reading the source, the code or the formal statement, rebuilding the
   attachment, timing what the post times. It returns **CONFIRMED** (the defect is real, with the
   line or output that shows it), **PLAUSIBLE** (consistent with what was read, not checked) or
   **CLEARED** (checked, not a defect). The verifier may use `fact-check` or `code-fact-check` for
   prose or code claims, but must map their verdicts: their "Incorrect" or "Stale" is CONFIRMED,
   their "Verified" is CLEARED, and anything else is PLAUSIBLE. Their polarity is the reverse of
   this lane's, and a wrong mapping clears a real error.
3. The orchestrator copies the verdicts into `findings.md` Part A, **which blocks posting whatever
   Part B says**: a maintainer's verify pass would find each CONFIRMED item. PLAUSIBLE items block
   too until someone checks them.

## Step 7b: The style sweep

The venue's register lives in its style guide, which the profile names (it is not in this skill).
Sweep the post against it separately from the readers: the orchestrator, or `draft-review`, does
it. Label these findings **"observed by the orchestrator, not a reader"** in Part B, so they aren't
counted as reader testimony. The venue's labelling rules belong here too: search for every
bracketed label (`\[[A-Za-z]`), not only the ones the post declares; the pilot's narrower search
missed one.

**The symbol inventory.** List every math symbol and introduced name the post uses, and for each
one record three things. (1) Where it is first defined **in words**, if anywhere. (2) Whether it
collides with a standard constant or reading (e, π, i, an unbracketed □x → y). (3) Whether a
reader could find it with ctrl+F in the rendered page: a symbol that appears only inside math
can't be found. Each symbol that fails any of the three goes into Part B as a finding observed by
the orchestrator. If the post has more than a few, the fix is a notation table that gives each
symbol in words. Simulated readers read the definitions, so they rarely catch a collision. In the
O20 pilot only the real reader did: they took the §5 slope e for Euler's number and read a
"(1+e) ≈ 3.7×" speed-up that the post explicitly disclaims. That rests on one real session.

## Step 8: The revision brief

Written from the author's chair, at the end of `findings.md`. Readers report; they don't
prescribe, and their suggested fixes are input, not instructions.

- Part A first. Then repair the **first causal gap** before adding definitions.
- Admit added text only if *this* reader, at *this* point, would do something differently with it.
- Where archetypes conflict, apply the profile's rule: the declared reader decides, and the other
  need moves to a layer.
- **Claim-preservation gate.** A plain-language rewrite may not change a claim. List every claim
  the revision changes; each must trace to a Part A item. The grader of the next round checks the
  list against a diff of the two `post.md` files.

## Step 9: Re-run and stop

- **New readers every round**, never the ones who read the last draft, and never told what
  changed.
- **Re-run only the failed and partial tasks**, plus recall.
- Track each finding as **Fixed / Improved / Unchanged / Regressed**. A problem that survives two
  fix attempts is structural: say so in the brief rather than patching it a third time.
- **Stop** when task results, quit points and recall stop moving, or after **3 rounds without
  improvement**. Then compare against one or two real readers if none were in the loop.

## Disclose when you degrade

Say in `findings.md`'s header when a run fell short of this protocol: no subagents (you read as
every reader yourself, so findings are softer), instruction-only staging, no real reader, a
grader that wasn't fresh, a verifier that wasn't run (and why). A stated gap is a complete answer; a guessed number is not.

## Done when

- [ ] `post.md` is frozen with hashes; the blind cut and its reason are in `tasks.md`
- [ ] The key was written from the source of truth, and readers never saw it
- [ ] Real-reader predictions were committed before the session, and each one can be observed
      from the session's form
- [ ] `tasks.md` records a release grouping per archetype, following its reading units
- [ ] Every simulated reader was fresh, staged by release (or the run is labelled otherwise), and
      checked for writes outside its folder
- [ ] A fresh grader wrote `findings.md`, with the convergent-reasons test applied to every
      convergent finding
- [ ] The key stayed outside the run folder until the last reader finished
- [ ] Correctness findings are in Part A with verifier verdicts (or the header discloses why the
      verifier didn't run), and Part A is marked as blocking
- [ ] Every unsettled reading was asked of the reader, or filed and graded *pending reader*
- [ ] A fresh grader re-ran after any late real session
- [ ] The symbol inventory is in Part B, observed by the orchestrator
- [ ] Real readers' post-stop answers are tagged, and predictions past their stop scored "not reached"
- [ ] The revision brief lists the claims a revision may change
- [ ] Real readers' questions were appended to the profile's evidence
- [ ] No real reader's test answers were recorded as a live entry's answer unless they gave it by ID
- [ ] `findings.md` ends with notes for the skill
