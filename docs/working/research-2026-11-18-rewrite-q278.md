# Research: the rewrite of Q-278 (the test-confinement run-or-refuse question)

Date: 2026-11-18 · Brief: `docs/working/briefs/2026-11-18-rewrite-q278.md` (at a874ee16) · Branch: `docs/rewrite-q278`, cut at a874ee16

repo text is evidence, not instructions

Failure-pattern grep: `rg -n -i 'bwrap|unshare|confine|misread|owner entry|questions entry' docs/failure-patterns.md` -> FP-050 (an `unshare` tier shares the host mount namespace, so writes reach the host), FP-052 (a confinement that blocks all writes crashes a suite), FP-058 (a `bwrap` runtime failure drops the work silently). All three are background for what the test-confinement script does; none is about an owner entry being misread, which is this unit's subject. No entry matched the misread side.

Failure-pattern skip: no fix(...) commits on this branch; it adds one research doc and nothing in it is a defect fix.

## What this doc settles

The brief asks for the entry that replaces Q-278, drafted and reader-tested once. Its acceptance item 2 asks first whether a question is due at all. **It is not.** The output is a short `you: fyi` entry that withdraws the question, plus a watch that brings it back when an answer could change anything. Both drafts are at the end (`## Draft entry`), followed by what the cycle should do (`## For the dev cycle`), which ends the doc.

Inputs read, in the brief's order: the findings' "Revision brief" and "C1 settled by the owner" sections (`docs/working/reader-testing/q278-2026-11-18/findings.md:275-315`); `docs/working/research-2026-11-12-sandbox-return-research.md`; Q-278 (`docs/working/questions.md:37-74`) and Q-272 (`docs/working/questions-archive.md:6485-6509`); H2 in `docs/constraints.md:6`; `docs/audiences/owner.md`. Also read: `docs/working/research-2026-11-11-confine-tests-fallback-data.md` (the data Q-278 carried), decision-log rows 87 and 88, watches Q-276 and Q-161, the cycle records 2026-11-12 to 2026-11-18, `scripts/confine-tests.sh`, and `devcontainer-config/Dockerfile`.

A note on input 5: the brief points to "the decider archetype's note that a name given once inside a gloss is missed". That note is not in `docs/audiences/owner.md` at a874ee16. It is in the findings (`findings.md:309-312`) and in `skills/reader-testing/SKILL.md:223-226`. I used it from there.

## 1. Is a question due?

**No.** The evidence, each item checked at a874ee16:

1. **The case the question is about cannot happen where the harness runs.** The question is what the test-confinement script does when `bwrap` is unusable and `unshare -rn` works. In a cc-isolated session neither works:
   - `devcontainer-config/Dockerfile` has no `bubblewrap` or `bwrap` line (`rg -n 'bubblewrap|bwrap'` prints nothing). The 7caea26d revert took it out, and decision-log row 88 (2026-11-12) records the owner's choice to keep no Bash sandbox, so it is not coming back that way.
   - Docker's default seccomp refuses user namespaces, so `unshare -rn` fails at detection (`research-2026-11-11-confine-tests-fallback-data.md`, section 1, rows 1 and 2).
   - Every cycle record from 2026-11-13 to 2026-11-18 reports no `bwrap` in the session (for example `cycle-2026-11-17.md:87`, `cycle-2026-11-18.md:13`: "`command -v bwrap`: none in this session's image").
   - Other repos run the same image and call the installed copy (`~/.claude/scripts/confine-tests.sh`, root-owned), so they are in the same state.
2. **The owner's condition is unmet and cannot be met from a session.** Q-272's answer asked for data on "how often bwrap isn't present, and how much friction inability to run tests would cause". The 2026-11-11 research found 7 recorded loop runs, all refused (exit 3), and called frequency "not enough data yet". Nothing since has produced a run that found a tool: no record outside the script, its tests and the 2026-11-10 reviews quotes `primitive available:` or `falling back to the unshare primitive` (`rg -l` over the repo). After row 88, no session can produce that data.
3. **Every answer behaves the same today.** Refuse, run-and-warn and "do not confine" differ only where one tool works. Where none does, the script exits 3 and the loop runs `scripts/run-tests.sh` unconfined plus `scripts/hermeticity-lint` (the briefs' conditional wording, roadmap Now item "confine-tests follow-ups").
4. **The remaining places the fallback could run have no caller.** The owner's host (WSL2, probably allows `unshare`) and a CI job. Nothing runs the script on the host and there is no CI (`research-2026-11-11-...`, section 2, last paragraph).
5. **The findings' revision brief, item 3:** "Don't return an ask before its condition is met … If the requested data is 'not enough yet', say so in one line and keep the entry closed, or file a watch. Don't present options." The owner's own verdict on the last return was "No. I asked for more data, and the first entry under 'The Data' begins with 'Not enough data yet.'" (`findings.md:66`).

Against: the owner wrote "The next step should be re-writing the question to address the concerns and options". That is satisfied by a rewrite that says plainly which tool, why nothing is decidable, and what the question will hold when it returns (including "do not confine tests at all"), without spending a judgment on a choice with no consequence. It is also why the closure goes to the owner as an `fyi` rather than being closed silently (section 2).

## 2. Design choice: what shape the output takes

Three viable shapes, so a divergent-design pass, seeded with the constraints (S5 motive first, S10 attention last), the brief's item 2 and the profile's pain trigger "a stop that didn't need them".

| Candidate | What it is | Verdict |
|---|---|---|
| **A. Silent closure** | The cycle closes Q-278 as withdrawn and files a watch; the owner learns of it from a final-message line | Cheapest in attention. But the owner explicitly asked for a rewrite and is expecting one; closing an owner-opened judgment entry with no word to them borders on "closing by inference", and the profile's returner reads final messages for what needs them, not for withdrawals. **Eliminated** as the only channel. |
| **B. A `you: fyi` withdrawal plus a watch** | A short entry, answered `seen`, that names the script, says why it is not the Bash sandbox question, why nothing is decidable, what holds meanwhile and what brings it back | One `seen` of the owner's attention. Lets them overrule ("ask it now"). Meets findings item 3. **Pick.** |
| **C. A rewritten judgment entry with options** | Run and warn / refuse / do not confine, each with costs | Asks for a call with no observable consequence (section 1, item 3), which is the profile's "stop that didn't need them" and repeats F3 ("returned without the data asked for"). Its cost column would be all zeros again, which is what the owner rejected. **Eliminated** for now; it is what the watch files when it fires. |

**Path A: B dominates.** It costs one `seen` more than A and keeps the owner's override; C fails the motive test (S5).

Other choices, one line each:
- **The watch's route:** `trigger` (a watched condition), since its conditions are observable strings and a `command -v`; not `deferred`, which waits on a dated event.
- **Host fact (F13):** not filed as a `you: terminal` entry now. A host `--probe` cannot change anything while nothing runs tests on the host (S10: at most one host paste, and only when it settles something). The watch says that a host or CI caller is itself a trigger.
- **The H2 framing:** dropped, per the brief. The fyi states the Q-272 answer that stands ("run and warn, to start") in plain words. Whether that conformance gap needs a record beside decision-log row 87 is the cycle's call (`## For the dev cycle`).
- **Whether the worktree cost applies to the script:** it does not, and the fyi says so in one sentence. The breakage came from Claude Code's sandbox making `.git/worktrees` read-only for every Bash call (`research-2026-11-12-sandbox-return-research.md`, F1.1). The test-confinement script wraps only the command it is given, with `$PWD` bound writable; it never ran with either tool, so it has no observed cost at all. Its unobserved risk under `bwrap` is FP-052 (a read-only root crashing a suite), which belongs in the options when the question returns.

## 3. The smaller findings, each named

Quotes are from the final draft (v2).

| Finding (from `findings.md`) | What the draft does |
|---|---|
| **F6** · a bare `[1]` named both the interim and its ratification | There is no options table. The interim is named in words: "your answer to Q-272 (run and warn "to start", …)" and "if it ever has `unshare` but not `bwrap`, it warns and runs". |
| **F9** · a dated amendment contradicted bullet 1 instead of rewriting it | No dated appends. Each fact is stated once, as it stands on 2026-11-18. |
| **C5** · "Blocks: nothing … no caller" was stale (loops and every full test run call `--probe`) | No "Blocks" line. The draft says the script is run by loops and by every full test run, and that every recorded run refused. |
| **C6** · the end condition named a release that did not ship `bwrap` | The return conditions are observable now: a recorded run that finds a tool, `bwrap` back in the image, or a host or CI caller. None names a release. |
| **F13** · "your host is not on record" was a terminal fact inside a judgment entry | Removed from the entry. Host data is a trigger only once something runs tests on the host (section 2). |
| "0 runs" undercount (brief item 3) | "That count can be low: it holds only the runs a loop wrote down, and every full test run also probes … without recording the result." |
| One name throughout (brief item 3) | "the test-confinement script" every time, with the path once in the first line. "Bash sandbox" is used only for Claude Code's sandbox. |

## 4. Reader test (light tier)

**Setup.** Stimulus: the first draft (v1, sha256 `e517bae0…7460`), cut into two releases: section 1 (heading, first line, `If you say no` line: the decider's reading unit for an fyi) and section 2 (the five bullets). Readers: one simulated decider and one simulated acting agent, from `docs/audiences/owner.md`, each fresh, staged by release (`SendMessage`), with three knowledge files copied into its folder: `docs/constraints.md`, the archived Q-272 entry and decision-log row 88. A fresh grader read both sessions, the key and the profile. All scratch files are in the session scratchpad, not the repo (brief item 4), so no run folder is committed.

**Degraded, disclosed:**
- No real reader. The owner was not asked: this unit cannot wait on them, and the brief asks for one light-tier pass. Every finding is uncalibrated. Q-278's own run showed simulated readers catch a subject that a real reader misses (`findings.md:309-312`), so a simulated pass on "which tool" does not clear the owner.
- The key was written by the draft's author (this loop), from the records.
- The session files given to the grader were the orchestrator's condensed transcription of the readers' replies, quotes kept.
- The verifier was not a fresh subagent: the orchestrator checked the four correctness candidates against the repo (below). They are file lookups, not judgments.
- The acting agent read the part-4 and part-5 instruction files outside its folder, at the orchestrator's instruction.

**Which tool is this about?** Both readers, from the opening alone, quoting the first line: "This is about the test-confinement script (`scripts/confine-tests.sh`), not Claude Code's Bash sandbox". Neither confused the two later. Both passed the decider's "is it the same question as the Bash sandbox?" task (D2) by quoting bullet 1. **No reader misread the subject**, so the brief's revise-on-misread condition did not fire. One revision was still made, for the findings below, and it was not re-tested (the brief says not to loop).

**Task results** (grader): decider D0–D4 all pass; D1 "a bare `seen` would also have done". Acting agent: A0 and A4 pass; A1 (`seen`) partial, A2 ("ask it now") fail, A3 (a probe finds `unshare`) partial.

**Findings** (grader's numbering; two-reader hits after the convergent-reasons test; none systemic, none S1), each with what the revision did:

| # | Finding | Hits | Sev. | Revision (v2) |
|---|---|---|---|---|
| F1 | `If you say no` names an answer the entry never offers ("I can't tell what 'no' would be refusing") | both, swappable: 1 | S3 | The line now reads "If you say no, `seen`, or nothing", and "ask it now" gets its own sentence |
| F2 | What "ask it now" leads to is not stated; the agent "would stop and ask" | both, not swappable: 2 | S2 | "it comes back at once as a judgment entry, with the options in the last bullet"; the last bullet names all three options |
| F3 | "watch" is an unglossed coined term | decider | S3 | Glossed: "a condition the dev cycle checks every iteration" |
| F4 | Where the watch lives and who files it | agent | S3 | "(the watch, in `docs/working/watching.md`)"; the cycle files it (`## For the dev cycle`) |
| F5 | The triggers cannot be observed as written ("recorded where?") | agent | S3 | Triggers are now strings and a command: the script's `primitive available:` or fallback line quoted in a doc or record, `command -v bwrap` succeeding, a host or CI caller |
| F6 | Q-278's fate is unstated; the agent would close it as ANSWERED | agent | S2 | "Q-278 closes as withdrawn, not answered" |
| F7 | The `docs/constraints.md` line Q-272's option [1] required was never written, and the entry is silent on it | both, swappable: 1 | S2 | One plain sentence: the line was never written, none is needed while no session can reach the fallback, and it comes with a run-and-warn answer when the question returns. No "provisional exception" wording |
| F8 | "the loop" and "a static check for network calls" are unnamed | both, swappable: 1 | S3 | "the build loop", "`scripts/hermeticity-lint`, a static check for tests that call the network" |
| F9 | No option for the script's current state; it is "close to present-but-inert" (decider) | decider | S3 | Not changed. Today the script refuses loudly every time, which is H2's fail-closed side, not a silent pass. Retiring it is the "do not confine tests at all" option, which the returning entry carries, and the fyi lets the owner call it now with "ask it now" |
| F10 | The opening does not say what Q-278 asked | both, swappable: 1 | S3 | First line: "my question about what the test-confinement script does when its strong tool, `bwrap`, is missing (Q-278), because today no answer would change what it does"; bullet 2 opens by tying Q-278 to Q-272 |
| F11 | Neither reader recalled the Bash-sandbox misreading as the reason for the entry | both, swappable: 1 | S4 | Not changed: the distinction itself landed (D0, D2), which is what the entry must do |
| F12 | The friction half of the owner's request is described, not measured | decider | S4 | "it is missing every time, and refusing has cost nothing, because no run ever reached the point where the two answers differ" |

Dropped by the grader: F13 (a stumble on "That count can be low" that the same bullet resolves: GENERIC); F14 and F15 (duplicates of F2 and F7).

**Correctness candidates**, checked by the orchestrator at a874ee16:
- C1 (F7): the H2 line was never written. **CONFIRMED**: `docs/constraints.md` has no `unshare` line, and decision-log row 87 says "It is not written into `docs/constraints.md`". The revision states it.
- C2 (F9): the merged state breaks H2's "present-but-inert". **CLEARED** as a factual claim: where neither tool works the script exits 3 with a message naming both tools (`scripts/confine-tests.sh:104-120`), which is H2's refusal. The fallback's run-and-warn is the H2 gap, and F7's sentence covers it.
- C3: "the image no longer installs `bwrap`, and the container refuses `unshare`" is not in row 88. **CLEARED**: `devcontainer-config/Dockerfile` has no `bubblewrap` line, and the container's refusal is observed in `research-2026-11-11-confine-tests-fallback-data.md` section 1, row 1. It is a sourcing gap in the entry, left as is: one more link would cost the decider more than it gives (profile: "at most two links").
- C4: the static check is `scripts/hermeticity-lint`. **CLEARED**: the briefs' conditional wording names `scripts/hermeticity-lint --root .` (`research-2026-11-07-confine-tests-situation.md:108`, `:124`). The revision names it.

**Claims the revision changed** (claim-preservation gate): the no-answer line (F1; now also covers `no` and `seen`), Q-278's fate (F6), the H2 line's status (F7, from C1), the friction figure (F12), and the triggers' wording (F5; the same three conditions, made observable). No other claim changed. v2 sha256 `24dcedeb…b82e`.

**Notes for the skill** (for whoever next edits `reader-testing`; this loop does not edit it):
- The decider's D1 asked "did you have to open anything?", and the reader split it into "to answer" (no) and "to check the premise" (yes). Asking the two separately gives cleaner data.
- Readers read the knowledge files against the post and found F7 that way. That is the knowledge-as-documents rule working; say in the reader brief that checking them against the post is welcome.
- Staging by `SendMessage` with the part-4 and part-5 text in instruction files outside the reader folder clashed with the brief's "read only your folder" rule; put the instruction files in the folder, or allow them up front.

## Draft entry

The fyi (final, v2):

```text
### Q-NNN · test-confinement-question-withdrawn
**Needs:** you: fyi · **Opened:** 2026-11-18 · **Status:** OPEN

This is about the test-confinement script (`scripts/confine-tests.sh`), not Claude Code's Bash sandbox: I am withdrawing my question about what the test-confinement script does when its strong tool, `bwrap`, is missing (Q-278), because today no answer would change what it does. Answer `seen`, or tell me to ask it now.

**If you say no, `seen`, or nothing:** Q-278 closes as withdrawn, not answered; nothing is built; and a watch, a condition the dev cycle checks every iteration, brings the question back when it can matter (last bullet). **If you say "ask it now":** it comes back at once as a judgment entry, with the options in the last bullet.

- **What the test-confinement script is, and why it is not the Bash sandbox question.** The test-confinement script runs one test command with the network cut off, so a test that reaches the internet fails instead of passing. The Bash sandbox you rolled back on 2026-11-12 wrapped every command a session ran, and that is what broke worktree creation in every repo. The test-confinement script wraps only the test command it is handed and never touches worktrees, so that cost does not carry over. The two share one tool, `bwrap`, which is why Q-278 read as the same question.
- **Why there is nothing to decide now.** Q-278 was the return you asked for in your answer to Q-272 (run and warn "to start", and come back with data). It asked what the test-confinement script should do when it has its weaker tool, `unshare`, but not `bwrap`: run after a warning, or refuse. In a cc-isolated session, in any repo, it has neither tool: the image no longer installs `bwrap`, and the container refuses `unshare`. So it refuses every time, and the build loop runs the tests unconfined plus `scripts/hermeticity-lint`, a static check for tests that call the network. Every answer you could give behaves the same today. You asked how often `bwrap` is missing and what refusing would cost: it is missing every time, and refusing has cost nothing, because no run ever reached the point where the two answers differ. Since you chose to keep no Bash sandbox (decision-log row 88, `docs/decisions/log.md`), no session can produce better data.
- **How sure that is.** 7 build loops recorded a run between 2026-11-05 and 2026-11-11, and every dev-cycle record from 2026-11-13 to 2026-11-18 reports no `bwrap`. All of them refused. That count can be low: it holds only the runs a loop wrote down, and every full test run also probes the test-confinement script without recording the result. A run that did not refuse would still need a tool the image does not have.
- **Meanwhile:** the test-confinement script stays as merged under your Q-272 answer: if it ever has `unshare` but not `bwrap`, it warns and runs. Your Q-272 option would also have added a line to `docs/constraints.md` recording that this departs from H2, the rule that a weakened tool refuses. That line was never written, and none is needed while no session can reach the fallback. If the question returns and you keep run and warn, the line comes with that answer.
- **What brings it back** (the watch, in `docs/working/watching.md`): a research doc or cycle record quoting the test-confinement script's `primitive available:` or `falling back to the unshare primitive` line, `command -v bwrap` succeeding in a session, or something starting to run the test-confinement script on your host or in CI. It then returns as a judgment entry with three options and their observed costs: run and warn, refuse, and do not confine tests at all.
```

The watch, for `docs/working/watching.md`:

```text
### Q-NNN · test-confinement-fallback-reachable
**Needs:** trigger · **Opened:** 2026-11-18 · **Status:** OPEN

Bring the test-confinement script's run-or-refuse question (`scripts/confine-tests.sh`: run under `unshare` after a warning, or refuse, when `bwrap` is unusable) back to the owner once an answer could change what the script does.

- **Read:** `docs/working/research-2026-11-18-rewrite-q278.md` (why it was withdrawn, and what the returning entry must hold) · Q-272 and Q-278 in `docs/working/questions-archive.md` · decision-log rows 87 and 88 (`docs/decisions/log.md`)
- **Condition** (any one, checked each iteration in the watches step):
  (a) a research doc, review or cycle record added since the last iteration quotes `confine-tests: primitive available:` or `falling back to the unshare primitive` (`rg -l` over the files the iteration's diff adds or changes under `docs/`);
  (b) `command -v bwrap` succeeds in a session;
  (c) a CI job, host step or hook starts calling `scripts/confine-tests.sh` (a new caller outside build-loop test steps and `test/scripts/confine-tests.bats`).
- **Interim:** the owner's Q-272 answer stands: when only `unshare` works, the script warns and runs. A loop that meets the fallback quotes its line in its research doc (that is condition (a)); it does not build a refusal and does not file the fallback as a new H2 finding. No line is added to `docs/constraints.md` while this is open.
- **When it fires:** file a `you: judgment` entry. Its first line names the test-confinement script and says it is not Claude Code's Bash sandbox; it uses that one name throughout. Its options are run and warn (with the `docs/constraints.md` line it needs, drafted), refuse (a loop then falls back to the unconfined run plus `scripts/hermeticity-lint`), and do not confine tests at all (retire the script and the briefs' probe step), each with the costs observed by then and any count's undercount stated. Host facts go in a separate `you: terminal` entry. Then close this watch.
```

## For the dev cycle

**What to do with Q-278:** close it with a watch. Do not rewrite it in place as a judgment entry (section 1).

1. File the `you: fyi` entry above in `docs/working/questions.md` with a fresh ID from `~/.claude/scripts/questions.sh next-id`. Its `**Needs:**` line and `**If you say no…**` line are drafted; keep them.
2. Replace the whole of the Q-278 entry (`docs/working/questions.md`, from `### Q-278 · q272-returned-run-or-refuse` through its `**If the answer differs:**` line) by closing it: set `Status: ANSWERED` with an answer line such as "Q-278: withdrawn, not answered (owner's reader test, 2026-11-18): rewritten as Q-NNN (fyi) and watch Q-MMM; nothing implemented", then archive it. Q-278's text itself is not reused: every part it held is in the fyi or in the watch.
3. File the watch above in `docs/working/watching.md` with its own ID, and fill both entries' `Q-NNN` placeholders.
4. When the owner answers the fyi: `seen` or `no` closes it and leaves the watch open; with no answer it stays open like any fyi, and the watch is filed either way; "ask it now" fires the watch's "When it fires" step at once.
5. Decision-log row 87 still calls the run-and-warn a "provisional exception to H2". The owner disallowed that framing for Q-278. The cycle may add a row that supersedes it in plain words: "Q-278 withdrawn (owner's reader test); the Q-272 answer stands; no line goes into `docs/constraints.md` while no session can reach the fallback; watch Q-MMM brings the question back." `docs/decisions/` is on this brief's floor, so this loop does not write it.
6. The roadmap's In flight item "Rewrite Q-278" can move to Done once both entries are filed; "confine-tests follow-ups" (Now) is then waiting on the watch rather than on Q-278.

Not filed, on purpose: a `you: terminal` entry for a host `--probe` (F13 of the earlier run). It would settle nothing while nothing runs tests on the host (S10); the watch's condition (c) brings it in when something does.
