# Session: acting agent (simulated), Q-278

**Run:** 2026-11-18. Staged by release; `section-N.md` copied into the reader's folder, outside the repo,
before each continuation. Brief: `skills/reader-testing/references/reader-brief.md`, filled from
`docs/audiences/owner.md` archetype 4.

## Reply 1: first take (section 1 only)

**First take.** Q-278 is a decision entry sent back to the owner. They had asked to see their earlier
Q-272 decision again, this time with data. The question: when the test-confinement script
`scripts/confine-tests.sh` can't use `bwrap`, should it still run tests under its weaker tool, `unshare`,
or refuse to run? Today the script follows the owner's Q-272 answer, option [1] "to start". It runs under
`unshare` after printing a warning. The entry says this is a provisional exception to hard constraint H2,
which it glosses as "a degraded tool refuses and names what went unenforced". The exception is not
written into `docs/constraints.md`. So for now the script knowingly breaks a hard constraint, the
exception lives only in this Q thread, and the owner is being asked to confirm it or reverse it.

**A0. What is the interim, and what does it rest on?**

**Answer:** The interim: when `bwrap` is unavailable, the script runs tests under `unshare` after a
warning. It rests on the owner's Q-272 answer ([1] "to start"), and it is held as a provisional exception
to H2.

Grading:
- **The answer: yes.** "the script runs under `unshare` after a warning" (opening section, "If you say
  no" line).
- **Its status: yes.** "That is a provisional exception to hard constraint H2 ... not written into
  `docs/constraints.md`." It is clearly provisional and clearly not ratified.
- **Its conditions: partly.**
  - When it applies: yes, "When the test-confinement script ... cannot use `bwrap`".
  - When it ends or what would revoke it: **no.** "to start" implies the arrangement is temporary, but
    nothing says until when or until what.
  - Whether the warning meets H2's other half ("names what went unenforced"): **no.** The text doesn't
    say what the warning contains.

**Problems I hit as the acting agent**

1. **"If you say no" doesn't map onto the question.** The question is a two-way choice ("still run ... or
   refuse?"). It isn't yes/no. If the owner replies "no", I can't tell whether they mean "no, don't run,
   refuse" or "no, don't change my answer". The entry seems to intend the second, but the opposite
   reading is just as natural. As written, a bare "no" would force me to ask the owner, and that is my
   stop condition. I'm continuing only because no options table has appeared yet, and one may resolve
   this.
2. **"with data" hasn't arrived.** No data is shown yet, so I can't judge what might change the answer.
3. **No options, no "If the answer differs", no "Blocks".** Nothing tells me yet what to do if the owner
   picks "refuse". There's no brief target, no file to change, and no word on whether
   `docs/constraints.md` gets edited in either case.

**What I expect next:** the data the owner asked for, probably from the research doc on how often the
fallback actually fires. Then a numbered options table ([1] keep running under `unshare` with a warning,
[2] refuse when `bwrap` is missing, maybe [3] a hybrid), with cost and "if it's wrong" columns. I hope it
answers:
- what a bare "no" (and a bare "yes") means;
- what ends the "to start" interim;
- whether the current warning names what went unenforced;
- under "If the answer differs", exactly what I change and where: the script's fallback branch,
  `docs/constraints.md`, and any open brief.

## Reply 2: section 2 (the data)

**Reactions to section 2.** The research doc settled several of these for me. I read it because the
brief allows it, but a reader who only has the entry would still be stuck on them.

1. **"`--probe` exits 3 here"** (first bullet). Neither `--probe` nor "exit 3" is defined in section 2 or
   section 1. From context I guessed that `--probe` is a check-only mode and exit 3 means "no usable
   tool, refused". Section 1 did not resolve this. The research doc confirms it ("neither (exit 3)", and
   "Exit 3 comes before any command runs, at detection"). As the acting agent this matters to me, because
   the decision turns on what exit 3 means. Under "refuse", exit 3 is the refusal.
2. **"536b7082", "80b7dabe", "7caea26d"** (bullets 1 and 3). These are bare hashes. The prose mostly
   glosses them: "the image sessions run today", "main rolled the Bash sandbox back". That works well
   enough. Section 1 did not resolve them.
3. **"Q-273, on hold for Q-277"** and **"your Q-277 answer [3]"**. Q-273 is glossed only as "the release".
   Q-277 and its option [3] are glossed only through what followed ("rolled the Bash sandbox back"). I
   can't tell what Q-277 asked. For acting on Q-278 I probably don't need to know. I note it and move on.
4. **A notation change: a later bullet corrects an earlier one.** Bullet 1 says "The image after the
   release ... installs `bwrap`", and bullet 3 ("2026-11-12, one change to the first point") takes that
   back. On a single pass I read bullet 1 as current fact and then had to revise it. Nothing earlier
   warned me. The note on the last line, "nothing above has changed in practice", helps, but bullet 1 now
   reads as stale. It would be safer if bullet 1 itself carried the correction.
5. **"A refusal would have stopped 0 more runs. On exit 3 a loop already runs `scripts/run-tests.sh`
   unconfined ... That fallback is weaker than `unshare`: it loses the network denial."** (bullet 2).
   This is the most decision-relevant claim in the section. Refusing doesn't stop tests running: it sends
   them to a *less* confined path. But it sits under the heading "How much friction a refusal would
   cause", which frames it as a cost question. I could follow the step, and the research doc states it
   more plainly ("refusing loses the kernel network denial and gains no filesystem protection"). Section
   1's framing ("still run ... under `unshare`, or refuse") did not prepare me for refusal being the
   weaker option inside a loop.
6. **"the `unshare` fallback has never run and its warning has never printed"** (bullet 2) next to
   **"nothing records which tool it found"** (bullet 4). I couldn't square these two. If every full test
   run calls the real `--probe` and nobody records the result, then "has never run" holds only for the 7
   reported loop runs, not in general. The research doc admits this ("If a fallback had happened there,
   no record would show it"). Section 2 states the stronger claim and leaves me to spot the gap. Section
   1 did not resolve it.
7. **"Claude Code's own sandbox, and nobody has tried that yet"** (bullet 1). It wasn't clear why that
   matters. The research doc explains it: a nested `bwrap` might fail on its mounts while `unshare`
   works, which is the only case where this choice makes a difference. Section 2 doesn't say so in words.
8. **"Your host is not on record."** Clear. It suggests a `you: terminal` follow-up, but none is offered
   yet.

**Against my expectation.** What it did that I expected: it delivered the data, organised around the two
questions the owner presumably asked (how often, and how much friction). What I didn't expect: it showed
that the either/or in section 1 is lopsided ("refuse" in practice means unconfined plus the lint, which is
weaker than the current interim on network); it corrected its own first bullet in place instead of
rewriting it; it ended on a measurement gap, which hints at a tracking task. What it didn't do: no
options table yet; nothing fixing what a bare "no" or "yes" means (my section-1 blocker still stands);
nothing on what ends the "to start" interim; no "If the answer differs"; nothing on whether the current
warning "names what went unenforced", as H2 requires. I know from the research doc that a middle option
exists ([2]: refuse by default, with `unshare` only behind a flag), but sections 1 and 2 haven't
mentioned it.

**Continue, skim or stop?** Continue. Nothing yet forces me to ask the owner, because the actionable
parts (options, answer mapping, what to redo) haven't appeared. My section-1 worry stays open: a bare
"no" is still ambiguous. If the next section doesn't resolve it, I stop there.

**Expectation for the next section.** A numbered options table: probably [1] run and warn (the current
interim), [2] refuse by default with `unshare` behind an explicit flag, and [3] always refuse, each with
its cost and an "if it's wrong" note saying [3] loses the network denial. Then a recommendation, likely
[2] as H2's tiebreaker, plus "Blocks", "Interim" and "If the answer differs". I hope it answers: what
"no" and "yes" map to (or drops yes/no for option numbers); what ends "to start"; for each option,
exactly what I change (the script, the brief wording, a line in `docs/constraints.md`); and whether the
recording gap from bullet 4 becomes a roadmap item whichever option the owner picks.

## Reply 3: section 3 (why it's yours, Read, the table)

**A correction first.** My section-1 worry, that "If you say no" was ambiguous, is answered by the
grammar file, which I should have checked. `questions-grammar.md:36` says "each entry opens, right after
its question, with `**If you say no:** WHAT`, so the owner can read an entry cold". So "no" means the
default if the owner declines or never answers, not a reply to the run-or-refuse question. For a reader
who knows the grammar, that blocker is gone. A reader who doesn't still meets an unglossed convention.

1. **The "no" default and [1] are different outcomes, and the entry doesn't say so.** Section 1 says that
   under "no" the exception is "not written into `docs/constraints.md`". Row [1] says "the exception to H2
   gets written into `docs/constraints.md`". So "no" means the interim stays provisional with no end date,
   and [1] means it is ratified. On a first pass I took "[1] (as now)" to mean "same as no", and it isn't.
2. **"One line in the constraints file" (row [1], Cost to you).** Who writes that line, and what does it
   say? The Q-272 option it came from said "which you add to `docs/constraints.md` or ask a session to
   draft". Q-278 dropped the "or ask a session". If the owner answers a bare `[1]`, I can't tell whether I
   should draft and commit the H2 exception text, or leave it to them, nor how it is scoped (only
   `unshare`; only when `bwrap` is missing; must the warning name the missing network or filesystem
   confinement?). This is the first point where I'd have to ask.
3. **"unless a new flag asks for `unshare`; the briefs' test wording passes that flag" (row [2]).** The
   flag has no name (a low-risk call I can make). "The briefs" isn't defined; I take it to mean the dev
   cycle's brief template for test steps [from my own knowledge of how agents work in this repo]. I can't
   tell whether a flagged run still warns, or what `--probe` returns with the flag. If every brief passes
   the flag, loops behave exactly as under [1]; the entry doesn't say why that still satisfies H2 (the
   research doc does: an explicit opt-in "meets H2 without an exception").
4. **"`unshare` only behind the existing `--no-loopback` flag" (row [3]).** `--no-loopback` is never
   defined. The name suggests it turns off a loopback interface, not that it chooses `unshare`. It also
   raises a question for [2]: why a new flag, when one already reaches `unshare`?
5. **"Loops that hit the fallback lose the network denial" (row [3]).** Under [3] there's no `unshare`
   fallback anymore, so "the fallback" here means the unconfined run plus the lint. The same word now
   means a different fallback than it did in section 1.
6. **"0 such runs so far" / "0 runs would have stopped so far" (rows [1] and [2]).** Section 2 bullet 4
   showed these numbers can undercount ("nothing records which tool it found"). The table repeats the
   zeros without that caveat. The grammar warns against routing an under-counting number to
   `you: judgment` without re-validating it.
7. **"decision-log row 87" and "merged at b9c8966a" (Read line).** Bare references, unglossed.
8. **"section 3 lists six ways to track the warnings, none built" (Read line).** The only mention of
   tracking, tucked into a citation and tied to no option.

**Against my expectation.** As expected: an options table matching my guess closely, "Why it's yours" and
"Read". Not expected: [1] now ratifies the exception rather than keeping it provisional, so "no" and [1]
split apart; [2] needs a new flag instead of reusing `--no-loopback`. Missing: no recommendation (the
research doc recommends [2]); no Blocks, Interim or If the answer differs; no end condition for "to
start"; nothing on whether the warning names what went unenforced; no home for the tracking gap.

**Continue, skim or stop?** Continue. For [2] and [3] I could almost act now. For [1], item 2 (who writes
the constraints line, and what it says) would make me ask; if the next section doesn't settle it, I stop.

**Expectation for the next section.** Blocks (probably nothing urgent), Interim (the "no" outcome
restated), If the answer differs. I hope it says: under [1], whether I draft and commit the H2 exception
line or the owner writes it; under [2], the flag's name and the brief wording, and whether a flagged run
warns; what ends "to start"; whether the warning tracking goes on the roadmap whatever the owner picks.

## Reply 4: section 4 (tentative pick, Blocks, Interim, If the answer differs)

**Reactions to section 4**

1. **"[1] becomes one line in `docs/constraints.md`, which you commit."** This settles my main section-3
   blocker: the owner commits the constraints line, not me. It leaves a smaller gap: do I draft the
   wording and hand it over, or only record the answer? Does the entry stay open until the line lands?
   I'd draft the line, record the answer and close the entry, with the draft attached. Low risk.
2. **"keep [1] until the first `--probe` inside a session after the release"** and **"Interim: [1], your
   Q-272 answer."** Here "[1]" changes meaning. In the table, [1] means the exception gets written into
   `docs/constraints.md`. Here it means the current interim, which section 1 said is "not written into
   `docs/constraints.md`". So "[1]" names two different states: the interim (also what happens if the
   owner says nothing) and [1] as a ratification. A bare `Q-278: [1]` now reads two ways: ratify it, or
   leave it alone. "If the answer differs" points to ratifying, and I'd go with that.
3. **"the first `--probe` inside a session after the release"**. Section 2 bullet 3 said the release that
   was to install `bwrap` "did not ship it". So I can't tell which release this means. It's also the only
   end condition the interim has, offered as an owner choice ("if you'd rather wait"), not as a watch I'd
   file. Who runs that probe, and where its result gets recorded, isn't said.
4. **"Blocks: nothing. The script has no caller that the fallback would change today."** Against section
   2 it jars: 7 build loops ran the script, and "Every full test run already calls the real `--probe`". I
   read it as "no caller ever reaches the fallback". The wording looks carried over from Q-272 ("Nothing
   calls the script yet"), where it was true.
5. **"[2] or [3] becomes a brief for one build loop".** Enough to act on. I'd decide myself (low risk):
   the new flag's name under [2]; which brief wording passes it; whether a flagged `unshare` run still
   warns (yes, naming what's missing, per H2).
6. **The tentative pick, [2], and its reason.** The recommendation I missed in section 3. Clear.
7. **Never addressed:** the recording gap (section 2 bullet 4; research §3, "six ways to track the
   warnings, none built"). No option and no follow-up covers it.

**Against my expectation.** As expected: a recommendation, Blocks, Interim, and an If-the-answer-differs
line that says who commits the constraints line. Not expected: a fourth, unnumbered answer ("wait for
data, keep [1] until …"); "[1]" reused to mean the interim. Missing: exception wording or scope under [1];
flag name and warning behaviour under [2]; a watch for the release probe; a home for the tracking gap; a
caveat that the zero counts may undercount.

**Continue, skim or stop?** Finished without stopping. Per answer, without asking: `[2]`/`[3]`, write one
build-loop brief and record the answer; `[1]`, record, close, and give the owner a drafted H2 exception
line to commit (mild doubt about drafting); "wait", change nothing, record, and open a watch on the first
in-session `--probe` (inferred, not asked for); no answer, nothing changes. The weakest point is a bare
`Q-278: [1]`: a wrong reading would edit a hard constraint, the one thing the entry calls the owner's
alone.

**What I'd still want.** Give the interim its own name and keep "[1]" for the ratification; under [1],
the exception's wording or "the session drafts it, you commit"; under [2], the flag's name and whether a
flagged run warns; the release after which the probe runs, and "wait for data" as a filed watch; whether
warning tracking goes on the roadmap whatever the answer; a caveat on the "0 runs" figures; a gloss of
the "If you say no" convention for a reader without the grammar file.

## Reply 5: part 5 (recall, tasks, stuck log)

### 1. Recall, from memory

- **Problem:** When `bwrap` is missing, `scripts/confine-tests.sh` falls back to the weaker `unshare`
  after a warning. That breaks hard constraint H2. The exception exists only as the owner's provisional
  Q-272 answer.
- **Insight:** In practice the choice has never mattered. Every recorded run exited 3 because neither tool
  works in the current image. Refusing doesn't make a loop safer: on exit 3 it runs the tests unconfined
  plus a lint, which loses `unshare`'s network denial.
- **Key move:** A middle option, [2]. The script refuses by default and runs `unshare` only when a new
  flag asks for it, and the briefs pass that flag. That satisfies H2 without an exception and keeps the
  network denial.
- **Finding:** Refusing would have stopped 0 runs and the fallback has never fired, but nothing records
  which tool a probe found, so those zeros may undercount. The case that matters, a nested `bwrap` inside
  Claude Code's sandbox, is untested.

### 2. Tasks

**A1. `Q-278: [2]`** (assembled from §1–4 plus the grammar file).
1. Record the answer inline, set `Status: ANSWERED`, run `questions.sh archive` (from the grammar, not the
   entry).
2. Write a brief for one build loop to change `scripts/confine-tests.sh`: without `bwrap` it exits 3; a new
   flag opts into `unshare`; the test wording in the dev cycle's briefs passes that flag; the loop
   self-merges.
3. Choices left to me, noted in the brief and commit body: the flag's name; whether a flagged `unshare`
   run still warns (yes, naming what isn't enforced, per H2); whether `--probe` honours the flag; which
   brief template "the briefs" means.
4. No change to `docs/constraints.md`, since [2] needs no exception.

Relied on: §3 row [2] "Without `bwrap` the script exits 3, unless a new flag asks for `unshare`; the
briefs' test wording passes that flag" / "One self-merged build loop"; §4 "[2] or [3] becomes a brief for
one build loop"; §4 "it follows H2 as written with no exception". Not in the text: the flag name, whether
a flagged run warns, which briefs, what `--probe` does.

**A2. `Q-278: [1], but keep tracking the warnings`** (assembled from §2–4 plus the research doc).
- Record the answer and mark Q-278 answered.
- Under [1], draft the H2 exception line for `docs/constraints.md` and hand it to the owner to commit; not
  commit it myself.
- For "keep tracking", the entry offers no mechanism: only "section 3 lists six ways to track the
  warnings, none built" (§3 Read line), and "Keep" implies tracking exists while §2 bullet 4 says "nothing
  records which tool it found". From the research doc, not the entry: since 2026-11-10 briefs ask loops to
  quote the probe line on exit 3, which doesn't capture a fallback (exit 0). I'd pick the cheapest
  option there (T1: "quote the probe's output line, whatever the exit"), add it as a roadmap item, and say
  so in the commit body with `Confidence: medium`. This is where I come closest to asking the owner.
- Record: the answer; the drafted constraints line, waiting for the owner's commit; the chosen tracking
  method and that I chose it.
- Comes back to the owner: the constraints line to commit (§4 "which you commit"); possibly a reminder
  entry if it isn't committed (not in the text); what the tracking finds. The entry never says what
  result sends the question back. I'd infer a fallback-warning run, or the first in-session `--probe`
  after `bwrap` returns (§4), and file a watch in `docs/working/watching.md`. That's an inference.

Not in the text: the tracking method, who drafts the exception wording, what triggers a report back.

### 3. Stuck log

1. "If you say no: your Q-272 answer stands" (§1): either/or, not yes/no. Resolved by
   `questions-grammar.md:36`, not by the entry.
2. "to start" (§1): what ends the interim. Partly resolved in §4 ("keep [1] until the first `--probe`
   inside a session after the release"), offered as an option, not filed as a watch.
3. "`--probe` exits 3 here" (§2): undefined. Resolved only by the research doc.
4. "The image after the release ... installs `bwrap`" (§2 b1), contradicted by §2 b3. Resolved in the
   same section, but leaves §4's "after the release" ambiguous.
5. "Q-273", "Q-277 answer [3]", the hashes (§2): glossed only by what followed. Not needed; not resolved.
6. "A refusal would have stopped 0 more runs ... That fallback is weaker than `unshare`" (§2 b2): a key
   claim filed under "friction". Followable; restated in §4.
7. "the `unshare` fallback has never run" against "nothing records which tool it found" (§2 b2, b4):
   possible undercount. Never resolved in the entry.
8. "Claude Code's own sandbox, and nobody has tried that yet" (§2 b1): why it matters isn't stated.
   Resolved only by the research doc.
9. "(as now)" against "gets written into `docs/constraints.md`" (§3 row [1] against §1): the default and
   [1] are different outcomes. Resolved by comparing; made worse by §4, which uses "[1]" for the interim.
10. "One line in the constraints file" (§3): who writes it, in what words? Partly resolved in §4 ("which
    you commit"); wording still open.
11. "a new flag ... the briefs' test wording" (§3 row [2]): unnamed flag, unspecified briefs, warning
    behaviour not given. Not resolved; low risk.
12. "the existing `--no-loopback` flag" (§3 row [3]): undefined, and the name doesn't fit what it gates.
    Not resolved.
13. "Loops that hit the fallback" (§3 row [3]): "fallback" now means the unconfined run. Resolved by §2 b2.
14. "0 such runs so far" (§3): repeats the possibly undercounted zero without a caveat. Not resolved.
15. "six ways to track the warnings, none built" (§3 Read): tracking tied to no option. Not resolved.
16. "Interim: [1]" / "keep [1] until …" (§4): "[1]" names two states, so a bare `[1]` reads two ways.
    Not resolved.
17. "The script has no caller that the fallback would change today" (§4): jars with §2's 7 runs; looks
    carried over from Q-272.

### 4. Reading path

All four sections in full, once each. Searched, not read in full: `questions-grammar.md` (for "say no"),
`constraints.md` (H2, who ratifies it), `q272-your-earlier-answer.md`, and the research doc (exit 3,
`--probe`, `--no-loopback`, its options, its recommendation, its tracking table), each opened when a term
or claim stopped me.

### 5. What would have had to be true

- Without the grammar file, §1's "If you say no" would have read as a reply to the either/or question; I'd
  likely have stopped in §1.
- Without §4's "which you commit", a bare `[1]` would have left me deciding whether to edit a hard
  constraint myself; I'd have stopped there.
- With plain option numbers only, A2's "keep tracking" would not arise. Any answer that adds a request
  outside the options lands on the one topic the entry mentions but never assigns.
- Reading §4's "[1]" as the ratification rather than the interim would flip my reading of a bare `[1]`.

### 6. Protocol feedback

- Grading A0 element by element worked well: it separated "provisional" from "has an end condition".
- Say whether consulting a linked doc counts as "the post resolving it" or as outside knowledge.
- A third task with a bare `[1]` would have tested the double meaning of "[1]" directly.
