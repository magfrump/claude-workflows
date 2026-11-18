# Session: decider (simulated), Q-278

**Run:** 2026-11-18. Staged by release; `section-N.md` copied into the reader's folder, outside the repo,
before each continuation. Brief: `skills/reader-testing/references/reader-brief.md`, filled from
`docs/audiences/owner.md` archetype 1.

## Reply 1: first take (section 1 only)

**First take.** Q-278 brings Q-272 back to me, as I asked. The question is the same as before: when
`scripts/confine-tests.sh` can't use `bwrap`, should it fall back to `unshare` (which the entry calls "its
weaker tool") or refuse? For now my earlier answer [1] is in force: the script warns and then runs under
`unshare`. The entry says that is a provisional exception to H2 that was never written into
`docs/constraints.md`. The script name is glossed in passing, and H2 is glossed in brackets. I learned no
new facts. The data I asked for (how often `bwrap` is missing, and how much friction refusing would cause)
isn't in this section.

**D0. What am I asked to decide, and what happens if I don't answer?**

- **Decision: there, yes.** Quote (question line): "should it still run tests under its weaker tool,
  `unshare`, or refuse?"
- **Status: there, yes.** Quote ("If you say no"): "your Q-272 answer stands, [1] 'to start': the script
  runs under `unshare` after a warning. That is a provisional exception to hard constraint H2 ... not
  written into `docs/constraints.md`." So the interim is run-and-warn, and the exception isn't recorded
  anywhere.
- **Conditions: partly.**
  - The trigger is there, yes: "When the test-confinement script ... cannot use `bwrap`".
  - What happens if I never answer: no. Q-272 said it outright ("which is also what happens if you never
    answer"). This entry drops that clause. I have to infer that "If you say no" also covers silence.
  - How long the provisional exception lasts, or what ends it: no. Nothing says whether "provisional"
    ends on a date, on an event, or when I answer.

**Where I stumbled (not enough to stop yet):**

- "If you say no": the question is "run or refuse", which isn't a yes/no question. I can't tell what "no"
  means. Does it mean "no change"? "No, don't refuse"? "I decline to revisit"? This is the label the
  grammar uses, but against this question line it reads as a false yes/no. I'd expect it to say "If you
  don't answer" or "If you keep [1]".
- "You asked for Q-272 back with data": I'm promised data, and section 1 shows none. Whether I go on
  reading depends on the data actually turning up.
- "[1] 'to start'": I remember this from my own answer, so I follow it. A cold reader would also need the
  Q-272 option names.

**What I expect next:** the data I asked for. That means how often the fallback warning fired, or how
often `bwrap` was missing on real hosts. It also means what refusing would actually cost: which callers or
hosts would lose test runs. Then an options table I can answer by number. I hope it tells me three
things. First, whether the sandbox branch (Q-267, the condition the recommendation hinged on) has merged,
so the image now ships `bwrap`. Second, whether the friction is near zero, which would make [2] (refuse
unless a flag asks for `unshare`) an easy call. Third, what "provisional" ends on if I keep [1]. If the
next section brings back the same three options with no numbers, the premise of this return ("with data")
is broken, and I'd stop and say so.

## Reply 2: section 2 (the data)

**Section 2 reactions**

1. **"in the image sessions run today (536b7082)"**: a bare commit hash. The words "the image sessions
   run today" give me enough to carry on, so the hash adds nothing I need. Nothing earlier resolved it,
   and it didn't stop me.
2. **"The image after the release (Q-273, on hold for Q-277)"**: Q-273 is glossed as "the release".
   Q-277 isn't glossed at all. Nothing earlier resolved it. It half-resolves in point 3: "main rolled the
   Bash sandbox back (7caea26d, your Q-277 answer [3])". But that assumes I remember what my option [3]
   on Q-277 was. All this brief gives me is my Q-272 answer, so to me "[3]" is just a bare number. The
   words "rolled the Bash sandbox back" are enough to follow.
3. **A notation change, and a claim corrected after the fact.** Point 1 says the next image "installs
   `bwrap`". Point 3 ("2026-11-12, one change to the first point") then says it doesn't. I read a stale
   claim first and had to go back and re-parse it. The dated amendment is honest, but it costs me a
   re-read. Point 1 should simply have been rewritten.
4. **"`--probe` exits 3"** and **"Every run exited 3"**: the earlier passage resolved these. Q-272 says
   exit 3 means refuse and mentions the script's `--probe` check. Fine.
5. **"On exit 3 a loop already runs `scripts/run-tests.sh` unconfined, plus the hermeticity lint ...
   That fallback is weaker than `unshare`: it loses the network denial."** I stopped hard here, and it
   isn't a term problem. Nothing earlier resolved it. It changes the decision. Q-272 framed refusal as
   the H2-compliant, safe choice. It turns out a refusal doesn't stop tests: the loop falls through to a
   fully unconfined run. So "refuse" doesn't narrow access. It widens it, past what `unshare` would have
   given. The run-or-refuse choice inside the script looks like a false dichotomy. The real H2 gap is in
   the loop's handling of exit 3, and the entry hasn't asked me about that.
6. **"Your host is not on record."** Is that a question to me? It's a fact only I can supply, which is a
   terminal paste rather than a judgment call. No command is given. Not resolved.
7. **"One gap. ... nothing records which tool it found."** This explains why there's no data. Fixing it
   sounds like agent work, not mine. The entry doesn't say whether anyone will fix it.
8. **"80b7dabe"** and **"`test/scripts/confine-tests.bats:228-245`"**: a bare hash, and a code citation
   for further reading. Neither stopped me.

**Against my expectation**

- **What it did that I expected:** it delivered the data I asked for, and was candid that the data is
  mostly "none".
- **What I didn't expect:**
  - The data makes the question moot in practice. Neither tool works on any recorded host, and the
    `unshare` fallback has "never run and its warning has never printed". A refusal "would have stopped 0
    more runs".
  - Q-267 is gone. Last time the recommendation said it could wait until the sandbox branch (Q-267)
    merged, because the image would then have `bwrap`. That event has been reversed, and section 2 never
    mentions Q-267 by name. I had to infer that the rollback answers my earlier hope.
  - The unconfined exit-3 fallback in the loop is new and bigger than the question being asked.
- **What it didn't do that I expected:**
  - No statement of what the data means for the decision.
  - No options table yet.
  - No word on whether "provisional" now means anything, given the path never runs.

**Continue, skim or stop?** Continue, but on probation. My provisional read is that the premise is off.
The choice between `unshare` and refusing is between two paths that can't run anywhere today, while the
path that actually runs (exit 3, then unconfined `run-tests.sh`) is the real H2 problem. If the next
section puts the same three Q-272 options back in front of me without dealing with that, I stop and
answer "wrong question" instead of picking a number.

**Expectation for the next section**

- Say what the data implies: either "defer, nothing is exposed", or "the live gap is the loop's exit-3
  fallback".
- Give an options table that reflects that. I'd expect options like:
  - keep [1] and close it until a host actually has a working tool;
  - record the `--probe` result so data accumulates (as agent work, not my ask);
  - a separate entry on whether exit 3 should still fall through to an unconfined run.
- Give a recommendation, an interim, and a closure or re-ask trigger for "provisional".
- Show how my host gets on record: one paste-ready command, if it's needed at all.

## Reply 3: section 3 (why it's yours, Read, the table)

**Section 3 reactions**

1. **"Why it's yours: it is an exception to a hard constraint, which only you grant."** This matches
   option [1] only. [2] and [3] meet H2 as written and need no exception from me, so that part doesn't
   match the table. A better line would be "I need you because [1] needs an exception; [2] or [3] I could
   just build." Nothing earlier resolved this. Q-272 used the same line, and it fit better there, when
   refusal looked clearly safer.
2. **"decision-log row 87"**: a bare internal reference with no gloss and no path. Not resolved earlier.
   **"merged at b9c8966a"**: a bare hash, harmless.
3. **"section 3 lists six ways to track the warnings, none built"**: I stopped here. My Q-272 answer said
   "track the warnings". This half-clause tells me nobody did, and it's tucked into a reading link.
   Section 2's "One gap" (nothing records which tool `--probe` found) hinted at it but never said my
   instruction went unmet. None of the options builds the tracking, either.
4. **[2] "the briefs' test wording passes that flag"**: I stopped here too. "The briefs' test wording"
   isn't glossed. I take it to mean the build-loop briefs' instructions on how to run tests [from my own
   knowledge of the harness]. If every brief passes the flag, then in practice [2] behaves like [1] plus a
   flag. Refusal wouldn't apply to any loop run, which is the only kind of run on record. So the [1]/[2]
   split is close to a false dichotomy, and the entry doesn't say so. Nothing earlier resolved it.
5. **[3] "Loops that hit the fallback lose the network denial, as every exit 3 does today"**: this is the
   problem I found in section 2 (exit 3 drops to unconfined `run-tests.sh`), and the table confirms it.
   It means the "always refuse" option leaves the weakest confinement of the three. The option that looks
   most H2-compliant widens access in practice. Section 2's "That fallback is weaker than `unshare`" had
   already resolved it, and that's exactly why it's a problem: the table records the consequence but
   offers nothing for it.
6. **The "0 runs" figures in every "If it's wrong" cell** are consistent with section 2. They also
   confirm that no option has any observed consequence either way.

**Against my expectation**

- **What it did that I expected:** gave an options table I could answer by number, and carried the data
  into the consequence column.
- **What I expected that it didn't do:**
  - No recommendation. Q-272 had one.
  - No option that takes in what section 2 showed: no "close or defer until a host has a working tool";
    no "build the tracking you asked for"; nothing on the unconfined exit-3 fallback, which is the path
    that actually runs.
  - No re-ask trigger or end date for "provisional".
  - No terminal paste to put my host on record.
- **What it did that I didn't expect:** it put the same three Q-272 options back in front of me,
  slightly reworded, even though its own data shows that none of the three affects any run that has
  happened.

**Continue, skim or stop?** **Stop.** I set this condition after section 2 ("If the next section puts the
same three Q-272 options back in front of me without dealing with that, I stop"), and the section met
it. The premise is wrong: run versus refuse inside the script decides between paths that can't execute
anywhere on record. The live H2 gap is the loop's exit 3 falling through to an unconfined run, and no
option touches it. I won't pick a number. My one-line answer would be:

> Q-278: wrong question. Keep [1] as the interim and don't write an exception into constraints.md. Have a
> session build the `--probe` tool recording I asked for (agent work, not an entry). Open a separate
> entry on whether exit 3 should fall through to unconfined `run-tests.sh`. Bring this back when a host
> actually has a working `bwrap` or `unshare`.

**Expectation for the next section:** a recommendation, an interim line, and an "If the answer differs"
line. None of them can rescue the entry unless the recommendation itself says the question is moot and
points at the exit-3 fallback.

*Orchestrator note: the reader stopped here, so section 4 (the tentative pick, Blocks, Interim, If the
answer differs) was never released. The recommendation it missed sits in section 4, below the table.*

## Reply 4: part 5 (recall, tasks, stuck log)

### 1. Recall (from memory)

- **Problem:** when the test-confinement script can't use `bwrap`, should it keep falling back to
  `unshare` with a warning, or refuse? The current fallback is an unrecorded exception to H2.
- **Insight:** neither tool works on any recorded host. The `unshare` fallback has never run. Refusal
  (exit 3) already makes loops run tests fully unconfined, which is weaker than `unshare`.
- **Key move:** the build loop gathered the data I asked for from the repo's records. Then it put the
  same three Q-272 options back in front of me.
- **Finding:** zero runs would change under any option. The data I asked for (how often `bwrap` is
  missing) can't be collected yet, and nothing records which tool `--probe` finds.

### 2. Tasks

**D1.** "Q-278: wrong question. Keep [1] as the interim with no exception written into constraints.md,
have a session build the probe-result tracking, open a separate entry on exit 3 falling through to
unconfined `run-tests.sh`, and re-ask when a host has a working tool." Opened: only the brief's background
files before section 2 (`q272-your-earlier-answer.md`, the H2 line of `constraints.md`); none of the
entry's Read links. Relied on (assembled from S2 and S3): S2 "Every run exited 3 because neither tool
worked, so the `unshare` fallback has never run"; S2 "On exit 3 a loop already runs `scripts/run-tests.sh`
unconfined ... That fallback is weaker than `unshare`"; S3 row [3] "lose the network denial, as every exit
3 does today".

**D2.** Cost: "One self-merged build loop." If wrong: "A run without `bwrap` that does not pass the flag
stops until someone passes it; 0 runs would have stopped so far." (S3, row [2].) Caveat (assembled from
S3 and S2): the row also says "the briefs' test wording passes that flag", so every loop opts in, and in
practice [2] behaves like [1].

**D3.** The entry's reason: "it is an exception to a hard constraint, which only you grant." (S3). Also
S1: "That is a provisional exception to hard constraint H2 ... not written into `docs/constraints.md`."
Assembled from S1 and S3: the reason fits [1] only; [2] and [3] need no exception.

**D4.** Assembled from the Q-272 answer, S2 and S3. Track the warnings: **no** (S3 "six ways to track the
warnings, none built"; S2 "nothing records which tool it found"). How often `bwrap` isn't present:
**partly** (S2 "Not enough data yet", "Your host is not on record"; absent in the sandbox and the current
image). Friction of refusing: **yes** (S2 "None so far ... A refusal would have stopped 0 more runs").
Return it in a few days: **yes** (opened 2026-11-11).

**D5.** Yes, several: defer or close until a host has a working `bwrap` or `unshare`; build the tracking
I asked for; decide what exit 3 should do in loops, where today it falls through to an unconfined run; a
paste-ready command to put my host on record. Not in the text, judged from the table in S3.

### 3. Stuck log

| # | Quote | Section | Why I stopped | Resolved later? |
|---|---|---|---|---|
| 1 | "If you say no:" | S1 | The question is run-or-refuse, not yes/no, so "no" has no clear meaning; the "if you never answer" clause Q-272 had is gone | No |
| 2 | "You asked for Q-272 back with data" | S1 | Data promised, none shown | Yes, in S2 |
| 3 | "(Q-273, on hold for Q-277)" | S2 | Q-277 has no gloss | Partly: "rolled the Bash sandbox back", but "[3]" assumes I remember Q-277's options |
| 4 | "The image after the release ... installs `bwrap`" | S2 | Corrected two bullets later by a dated amendment; re-read | Yes, in S2 point 3, at the cost of a re-read |
| 5 | "On exit 3 a loop already runs `scripts/run-tests.sh` unconfined" | S2 | Turns the decision upside down: refusing widens access | No; S3 [3] confirms it but offers nothing for it |
| 6 | "Your host is not on record." | S2 | A fact only I can supply, but not asked and no command | No |
| 7 | "nothing records which tool it found" | S2 | Explains the missing data; no owner or fix named | No; S3 adds "none built" |
| 8 | "Why it's yours: ... exception to a hard constraint" | S3 | Fits [1] only | No |
| 9 | "decision-log row 87" | S3 | Bare reference, no gloss or path | No |
| 10 | "six ways to track the warnings, none built" | S3 | My instruction went unmet, mentioned only inside a link | No |
| 11 | "the briefs' test wording passes that flag" | S3 | Not glossed, and it makes [2] behave like [1] | No |
| 12 | Same three options as Q-272 | S3 | My stop condition from S2 was met | No. I stopped |

The bare hashes (536b7082, 80b7dabe, b9c8966a, 7caea26d) were harmless: the prose around them carried the
meaning.

### 4. Reading path

Read in full: S1, S2, S3. Background: `q272-your-earlier-answer.md` in full before S2; only the H2 line
of `constraints.md`; none of `questions-grammar.md` ("the format was familiar"). Skipped: all the entry's
Read links. Stopped after S3; didn't reach the recommendation, interim or If the answer differs.

### 5. What would have had to be true

- The `unshare` fallback had actually run somewhere, or the options had been built around what the data
  showed.
- Refusal had led to a real stop rather than an unconfined run.
- The tracking I asked for had been built, or its absence stated up front.
- The "why it's yours" line had applied to all three options.
- A recommendation had sat next to the table.

### 6. Protocol feedback

- Splitting at the table worked well; the stop condition I wrote after S2 was testable, and S3 tested it.
- Leaving the recommendation for a later section may make me stop before I see it. If it carries the
  reframe, the test can't credit it.
- D4 needs the Q-272 answer text. Having it in the folder was essential.
