# Audience profile: the owner, reading agent-written entries and messages

**Status:** ratified by the author 2026-11-18 (Q-299 [2]: ratified with the author's edit, the five
calls at their interim answers). The calls stay listed under "Calls for the author"; answering one
later is a refresh. **Last verified:** 2026-11-18.
**Changes:** 2026-11-18, the author's edit: the operator's worst misreading is now a half-applied paste
or a buried remainder, with a wrong-environment run (which costs a repeat) second. The author read the
rest and called it "LGTM", then ratified it (Q-299 [2]).
**Venue:** text agents write to the owner in this repo and the repos it serves: `docs/working/questions.md`
entries (all routes), the dev cycle's final messages, and the end-of-run summary. **Evidence read:**
`docs/working/questions-archive.md` (all 277 entries, Q-001 2026-09-12 to Q-298 2026-11-14; answer lines
parsed by script, three blocks read in full); `docs/human-author/answers-*.txt` (19 files, 2026-09-17 to
2026-11-11), `feedback-10-20-26.txt`, `feedback-10-29-26.txt`, `feedback.md`; owner feedback quoted in
`docs/working/trials/2026-10-30-friction-engagement.md` and `2026-11-06-attention-and-trust.md`;
`docs/working/feedback/belegarth-herald.md` and `philosophy-research.md` (agent-written, with the owner
quoted); the live `questions.md` at `fd2da558`; the global CLAUDE.md's "Running questions document" and
"Returning to /active"; `skills/dev-cycle/SKILL.md`; 10 memory notes (listed in "Evidence notes").

**Refresh this profile when** the questions grammar or the dev cycle's message rules change; the owner
remarks on an entry's form (a complaint, praise, "I don't see what…"); an answer contradicts a prediction
below; a trial on owner-facing writing is kept or dropped; or a reader-testing run's simulated reader
disagrees with the owner.

This profile describes archetypes. All four are roles of one person, the owner, or (one of them) an agent.
That's the difference from the MAIS profile (`docs/working/mais.md`), where the readers are strangers and
the author is one reader among them.

**Scope, and the second layer.** This profile covers the owner as **engineering manager and operator**,
the same in every repo. The owner's other roles live in **per-repo profiles**: player or walkthrough
tester in a game or app repo (Behemoth Arsenal, Belegarth Herald), and the friends who playtest. A
per-repo profile adds what the owner knows of that project and links here for the rest. (Call 4.)

## The venue

**What an entry is for.** It gets one decision or one action from the owner, at the cost of one line:
"a bare `[2]` is a complete instruction, and everything needed to act on it must already be in the
entry" (global CLAUDE.md, "Answering costs one line"). The record it becomes is the answered entry in
`questions-archive.md`, which a later agent acts on.

**What a final message is for.** It tells a returning owner what needs them now and what can wait, and
gives at most two links (trials T8, T9, `docs/working/trials/2026-11-06-attention-and-trust.md:13-17`).
The owner's own word on one with two links: "great" (`2026-10-30-friction-engagement.md:37`).

**Declared reader.** The grammar addresses the owner and no one else: "It holds only what is blocked on
the user", and a judgment entry is "the only real attention spend". **Rule:** write for the decider
reading cold (archetype 1, call 1). Test against all four archetypes. When they conflict, the decider
decides, and the other need moves to a layer: the linked research doc, the commit body, or the paste
block.

**Register.** The global CLAUDE.md's "Running questions document" section is this venue's style guide:
the entry shape, the options table ("the format, not a suggestion", confirmed by Q-020), "gloss every
reference" ("Clarity outranks length"), one judgment per entry, one paste for terminal entries. The dev
cycle adds the `**If you say no:**` line (from trial T2, kept 2026-11-06). Don't restate those rules
here.

**Norms that change how an entry is read.**

- **Answers come by ID, often in batches.** "Q-181..Q-193: [1]" answered 13 entries on 2026-10-17;
  "Merge all three" answered Q-235 to Q-237. An entry is read beside others, not alone.
- **Answers arrive in bursts on answer-file dates.** Those were 09-17, 09-20, 09-23, 10-12, 10-16, 10-22,
  10-28, 11-07 and 11-11. Judgment entries take a median of 1 day (82 of 194 the same day). Terminal entries
  take a median of 2 days, and they're the ones that go stale (Q-084 is open since 2026-09-27).
- **An answer may carry a condition or a question back.** "[1] to start … return the question to me
  in a few days with some data" (Q-272). It isn't recorded until every part is acted on (memory
  `answer-files-can-ask-back`).
- **Fewer stops is a standing preference.** "your initial design had 12 points to stop for human approval,
  and I asked you to remove almost all of them" (`feedback-10-20-26.txt:8-9`). Routine landings need no
  entry ("go ahead with your recommendation and after merging ping me", Q-137).

**What has actually happened** (2026-11-18, the archive's 219 answered judgment entries):

| Shape | Count | Share |
|---|---|---|
| Bare number | about 160 | 73% |
| Number plus the owner's own condition | about 34 | 16% |
| No number | about 21 | 10% |

Of the 21 entries answered with no number, about 13 come from the era before options tables, and 8 are
reframes or refusals:
- "This feels like a false dichotomy … Run divergent design on this" (Q-059);
- "revisit in more detail" (Q-223);
- "extend a week" (Q-286);
- the premise withdrawn because the measurement "is not trustworthy" (Q-017).

Questions back are rare: two, Q-012 and Q-226. Of the 25 entries with an explicit recommendation, 5 were
declined. The stated reasons were throughput (Q-145, Q-149), evidence first (Q-272), and fixing old red
findings before new work (Q-171).

## Archetype 1: the decider

**Who.** The owner, answering `you: judgment` entries, often several at a sitting.

**The question they bring.** Is this mine to decide? What do I lose with each option? Can I answer in
one line and move on?

**Stake.** Every judgment entry spends the binding budget. One wrongly answered entry sends a build loop
the wrong way, and one they can't answer blocks it.

**What they know** (as of 2026-11-18). The harness's concepts, deeply. They correct agents on review policy
(`feedback-10-20-26.txt:13`), on the purpose of lite review, and on the canon's design. They know the
global CLAUDE.md, `docs/constraints.md` and their own past answers. They **don't** know, without a link:
- internal IDs: Q-numbers outside the entry, trial T-numbers, D-numbers, F-numbers, H/S constraint lines;
- local artifacts ("What is the handoff's probe.sh?", Q-255);
- agent-coined terms ("I'm not sure what is meant by 'structured commits'", `feedback.md:22`);
- anything only in a doc the entry doesn't link.

**How they read.** The question line, the options table and the recommendation. They skip evidence lists
and release notes: "I'm not reading the release notes thoroughly since I'm mostly tracking what's happening
in the repo via my answers to other questions" (`2026-10-30-friction-engagement.md:36`). They read the
premise and attack it when it's wrong (Q-017, Q-059, Q-274). They often answer the larger question
instead of the narrow one (Q-020, Q-050, Q-072).

**Patience budget.** Seconds per entry when batching. Long enough for a table and one linked doc when the
call is real. **Pain triggers:**
- bare references ("the biggest problem is jargon and references", `2026-10-30-friction-engagement.md:37`);
- an entry that references "a huge amount of other text without giving links/pointers" (Q-133,
  `docs/working/feedback/philosophy-research.md:58`);
- a false dichotomy;
- a "why it's yours" that doesn't match the table (Q-139);
- a stop that didn't need them.

**Wins:**
- the options table ("a big improvement … would like it in the global instructions", Q-020);
- two links for further reading;
- things fixed without being asked ("I didn't actively notice that it disappeared but I am glad you're
  looking at it").

**What they do next.** Write `Q-NNN: [n]`, sometimes with a condition. Or reject the options and ask for a
divergent-design pass.

**The worst misreading.** Picking an option whose cost column hid the real cost, or an interim that isn't
what they think it is. Second worst: answering when the call wasn't theirs. The routing rule says to check
that first, and Q-133 shows what happens when nobody does.

**Success test.** From the question line, `If you say no` and the table alone, they can answer with a bare
option number. They can also say what each option costs them and what they eat if it's wrong. Nothing
needs a lookup.

**Task templates.**

- Answer this entry with one line. Did you have to open anything to do it?
- Without rereading: what happens if you don't answer at all?
- What does option [n] cost you, and what do you eat if it's wrong?
- Why is this call yours, and not the agent's?
- Is any option you'd want missing from the table?

**Real readers available.** The owner, always. But their attention is the budget (memory
`weekly-budget-explains-dormancy`), so calibrate from answers they give anyway, and give them a dedicated
session rarely.

## Archetype 2: the operator

**Who.** The owner at their own terminal, running a `you: terminal` paste. They work on the host, outside
the container: "/workspace directory is part of the container, not relevant for me running commands usually"
(`answers-9-17-26-2.txt:43`).

**The question they bring.** What exactly do I run, where, and what tells me it worked? Will it break my
setup?

**Stake.** A setup that "has taken time" (`answers-9-27-26.txt:2`). A paste run in the wrong environment,
or one that blocks normal harness use, costs them their working setup. Q-117 was refused for that reason:
"This will block verification constantly".

**What they know** (as of 2026-11-18). Their host and their shell. They also know the harness's install
and verify tools, by name and purpose. They're unsure which environment a command is for ("I'm not
confident this is the correct environment for this command", `answers-9-17-26.txt:8`). They don't know
which files a session needs copied in (Q-255).

**How they read.** The paste block first. They run it, then paste the output back raw, typos included
(`ech`, Q-273). When steps are numbered, they report by number ("1. Works … 2. cc-push correctly refuses
…", `answers-9-30-26.txt:3-5`).

**Patience budget.** One paste per sitting. Several terminal entries are meant to be collected into one
paste. That rule isn't kept today: four open terminal entries each carry their own blocks. **Pain
triggers:**
- several blocks in one entry (Q-167 has four, (a) to (d));
- a step to run "inside the session" mixed in with host steps;
- no expected output;
- a test setup they might "forget to return" from (`answers-10-12-26.txt:5`).

**Wins:** "Workflows that group steps into one command" (`feedback.md:34`).

**What they do next.** Paste the output back, or refuse with a reason (Q-117, Q-130). The output is
sometimes missing (Q-214, Q-280), so the entry should say which lines of output the agent needs.

**The worst misreading.** A partial paste that leaves a half-changed setup, or an entry answered in part and grown by dated appends, which leaves the live remainder buried (Q-167, Q-084). Second-worst: running a paste in the wrong environment, requiring a repeat.

**Success test.** From the entry alone they can run it in one paste, in the right place, know what output
means success, and know what to send back.

**Task templates.**

- What do you run, where, and in what order?
- What output tells you it worked? What do you send back?
- What's left open in this entry, if part of it was answered before?
- Could running this disturb your normal setup? How would you undo it?

**Real readers available.** The owner. Terminal entries take a median of 2 days and go stale, so a stale
terminal entry is itself evidence that it failed this test.

## Archetype 3: the returner

**Who.** The owner coming back after hours away ("When I'm away it's often for several hours",
`answers-10-16-26.txt:47`). They read the dev cycle's final message, or the end-of-run summary, cold.

**The question they bring.** What needs me now, what can wait, and is anything burning?

**Stake.** Trust. Misjudging what happened while they were away is how a wrong merge lands or a trial goes
unnoticed. "I did trust this but it's hard to tell what my level of trust should be"
(`2026-10-30-friction-engagement.md:41`).

**What they know** (as of 2026-11-18). Whatever they answered before they left. Not what ran since. Trials
by name only when linked: "what's the expected interface for me to see what trials are happening, to know
what feedback is relevant?" (`2026-10-30-friction-engagement.md:34`).

**How they read.** The first lines ("needs you now", "can wait", per T8), then the links (at most two,
per T9). They follow the work through their answers rather than through digests: the weekly digest was
"nice to read, but … I'm following a lot of the work via my answers to questions" (`:40`).

**Patience budget.** One screen. **Pain triggers:** an unlinked trial or rubric reference, and a summary
that points to the questions doc instead of listing its open entries. **Wins:** the two links, and a
plain line per open entry.

**What they do next.** Answer the open entries, or go back to their own work.

**The worst misreading.** Thinking nothing needs them when something does, or the reverse.

**Success test.** From the first three lines they can name what needs them now and what can wait. They can
reach anything else with at most two links.

**Task templates.**

- What needs you now, and what can wait?
- Did anything land without you that you'd want to look at?
- Which trials are running, and what feedback would help them?

**Real readers available.** The owner. Final messages aren't kept (`skills/dev-cycle/SKILL.md:805`), so
the only evidence is what the owner says about them.

## Archetype 4: the acting agent (a test reader, never the write-for reader)

**Who.** The agent that reads an answered entry and has to act on it: a later dev-cycle iteration, a
build loop brief-writer, or the archive's reader. "Everything needed to act on it must already be in the
entry."

**The question they bring.** Given `Q-NNN: [2]`, what do I do, exactly, without asking?

**Stake.** An answer acted on wrongly, or not recorded. Q-255's answer was reported "not recorded" on
2026-11-11.

**What they know.** The repo, but not the conversation where the entry was written.

**How they read.** The answer line, the chosen option's row, and `If the answer differs`.

**Patience budget, pain triggers, wins.** These don't apply as they would for a person. The equivalent
of a pain trigger is an answer that carries a condition or a question back ("[1] to start … return the
question to me"), because the entry's grammar has nowhere to put either.

**What they do next.** Write a brief, commit a line, close the entry.

**The worst misreading.** Inferring an answer the owner didn't give. Two variants: a "yes" taken as an
option (`skills/dev-cycle/SKILL.md:876-880`), or an entry closed on an observation nobody made (global
CLAUDE.md, "Never close an entry by inference").

**Success test.** Given the entry and a bare answer, it can write the next action without asking anything.

**Task templates.**

- The owner answered `[n]`. What exactly do you do next, and where?
- The owner answered `[n]` with this condition. What do you record, and what comes back to them later?

**Why it's here.** It pulls against the decider: the acting agent wants detail in the entry, and the
decider wants it out. By the conflict rule, the detail moves to the linked doc and `If the answer differs`.
(Call 2.)

## Evidence notes

- **Who wrote what.** The answer and feedback files are the owner's own text. About half their bulk is
  pasted terminal output. In the trial docs, only the quoted "Feedback" lines are the owner's. The triage
  doc, `profile-feedback-run2.md` and `docs/working/feedback/*.md` are agent-written.
- **Agent wording in the archive.** Almost every answer line in `questions-archive.md` was written by an
  agent that paraphrases or quotes the owner. The counts above are of answer shapes, not of the owner's
  wording.
- **Memory notes used:**
  - from the owner: `owner-entries-clarity-not-length`, `answer-files-can-ask-back`,
    `never-block-on-user-route-async`, `no-new-human-stops-in-dev-cycle`, `merge-on-recommendation-then-ping`,
    `trial-week-friction-engagement`, `establish-motive-before-comparing-options`;
  - an owner correction an agent generalised: `terse-instructions-point-to-existing-specs`;
  - agent reflection: `weekly-budget-explains-dormancy`.
- **Not found:** any owner evidence about reading on a phone, or at a fixed time of day. Any owner remark
  on very long entries: Q-252 and Q-260 run 40 to 60 lines and still got a bare `[1]`, and the archive
  is silent on their length.

## Predictions to score against answers the owner gives anyway

Each is a credence about the next 20 judgment entries the owner answers, not a rate. They are scored
when that many have been answered, or at the next refresh, whichever comes first. Each can be checked
from the archive alone.

| # | Prediction | Credence |
|---|---|---|
| P1 | At least 12 of the 20 are answered with a bare option number. | 75% |
| P2 | At least one is answered by rejecting the options or the premise. | 60% |
| P3 | Any entry with an unlinked internal ID in its question line or table draws a remark or a question back. | 30% |
| P4 | An entry with three or more paste blocks stays open past its 7th day. | 70% |
| P5 | At least 2 of the 20 carry a condition or a request to come back later. | 65% |

## Calls for the author

Each call has options, one of which departs from the draft. Ratified 2026-11-18 with every call at its
**interim**; answering a call later is a refresh.

1. **Who is the write-for reader of an entry?** [1] the decider reading cold (*interim*). [2] the
   acting agent: entries are records first, and the owner reads a summary. [3] the decider, but final
   messages are written for the returner.
2. **Should the acting agent be a test reader?** [1] yes, as a test reader only (*interim*). [2] no:
   entries are for you, and the agent reads the linked doc. [3] yes, and the archive's record is a
   separate genre with its own profile.
3. **Is the knowledge limit right?** "Concepts deeply; IDs, local artifacts and coined terms not, without
   a link." [1] right as written (*interim*). [2] concepts are also a limit in some areas: name them.
   [3] IDs are fine once linked, so drop them from the pain triggers.
4. **Two layers?** [1] this shared owner profile, plus a per-repo profile per game or app for the
   player, walkthrough and friends roles (*interim*). [2] one profile per repo, each carrying the
   engineering-manager role too. [3] one owner profile with a section per repo.
5. **Is the operator a separate archetype?** [1] yes (*interim*). [2] no: fold it into the decider,
   with the paste rules in the venue section.

## Notes for the skill

What this run showed, for `audience-profiles`:

- **The reader can be one person in several roles.** The skill assumes strangers at a venue. Here the
  archetypes are the owner's roles plus an agent, and the tension is between roles, not between people.
  The skill should say that a role is an archetype.
- **An agent can be a reader.** The acting agent reads every answered entry. The skill should allow an
  agent archetype that is a test reader only, and say that it is never the write-for reader.
- **When the real reader is always available, calibrate on reads they do anyway.** Pre-registering
  predictions against the next N answers costs the owner nothing. The skill only knew pre-registration
  for a dedicated session.
- **There's a gap between the venue's rules and its practice.** The one-paste rule and the
  `If you say no` line are each broken by older open entries (Q-167, Q-084). Profiling surfaced it, and a
  profile could carry it as a finding.
- **The profile needs a scope line** when it is one layer of two: shared roles here, per-repo roles in each
  game or app repo. The template has no field for it.
- **Most of the archive's answer lines are agent paraphrase.** The skill's source table should warn that
  the record of a reader's words is often written by an agent.
