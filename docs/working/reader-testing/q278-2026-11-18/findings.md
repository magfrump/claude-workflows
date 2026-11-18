# Findings: reader test of Q-278 (round 1, 2026-11-18)

**Stimulus:** `post.md`, the Q-278 entry from `docs/working/questions.md` at `fd2da558`. **Profile:** `docs/audiences/owner.md` (ratified 2026-11-18). **Key:** `key.md`, written by the post's author from the records. **Previous round:** none.
**Degraded:**
- The owner's session was not staged. They read the whole entry at once, with no first take, stuck log, recall or reading path.
- The simulated decider stopped after section 3, so it never saw section 4 (the tentative pick, Blocks, Interim, If the answer differs).
- The key was written by the post's author.
- The grader (me) is fresh.

| Session | Kind | Notes |
|---|---|---|
| `sessions/decider.md` | simulated | Staged in 4 releases. Given the Q-272 answer, the H2 line and the grammar. Stopped at S3 on a stop condition it set itself in S2. Never saw the recommendation. |
| `sessions/acting-agent.md` | simulated | Read all 4 sections. Consulted the grammar file, the Q-272 answer and the research doc whenever stuck, so some of its "resolved" items were resolved outside the entry. |
| `sessions/owner.md` | real | Answered D0–D5 only. Contamination: the entry had been open since 11-11, the owner wrote the Q-272 condition, the profile calls Q-278 the strong sample, and the owner read the profile first. |

Part A (section 7 below) lists correctness and fidelity issues; Part B is everything else. **Part A blocks posting whatever Part B says.**

---

## 1. Task results

### Decider (simulated)

| Task | Result | Type | Notes |
|---|---|---|---|
| D0 · answer (opening alone) | pass | — | Quotes "should it still run tests under its weaker tool, `unshare`, or refuse?" |
| D0 · status (opening alone) | pass | — | Interim is run-and-warn; the provisional H2 exception is not written down. The ○ element is credited. |
| D0 · conditions (opening alone) | partial | misread | Says what happens on no answer is "no… I have to infer that 'If you say no' also covers silence". The inference is right, but it is hedged, and the label is the cause: the question is either/or, not yes/no. Did not fall into the negative reading (no = refuse). |
| D1 | testimony | — | "Q-278: wrong question. Keep [1] as the interim… build the probe-result tracking… separate entry on exit 3… re-ask when a host has a working tool." Opened none of the entry's Read links. Never saw the tentative pick (staging). |
| D2 | pass | — | Both ● elements quoted from row [2]. Adds a caveat that [2] "behaves like [1]" in practice. |
| D3 | pass | — | Quotes the H2-exception reason. Adds that it "fits [1] only". |
| D4 | pass | — | "Not enough data yet" found for presence. Friction: "None so far… 0 more runs". Did not treat the 7 loops as evidence that `bwrap` is present. Also found a third Q-272 part the key does not list, "track the warnings: **no**". The key's "both conditions" may be incomplete. |
| D5 | testimony | — | Defer or close (≈ the key's "wait for data" credit), build the tracking (credit), the exit-3 behaviour, a host paste. |

### Acting agent (simulated)

| Task | Result | Type | Notes |
|---|---|---|---|
| A0 · answer (opening alone) | pass | — | "runs tests under `unshare` after a warning" |
| A0 · status (opening alone) | pass | — | Provisional, not in constraints.md. |
| A0 · conditions (opening alone) | partial | missing | No end condition for "to start", and nothing on whether the warning names what went unenforced. The key does not require either. Separately, it read "If you say no" as ambiguous enough that a bare "no" reply would force it to ask (misread). It cleared this only via `questions-grammar.md:36`, not the entry. |
| A1 | pass | — | One build-loop brief: exit 3 without `bwrap` unless a new flag, the briefs pass the flag, and it self-merges. Neither ○ is credited: no row-87 update, and `--probe`'s behaviour is left as "a choice left to me". |
| A2 | pass | — | Drafts the line, the owner commits it, the condition is recorded, and it states "the entry offers no mechanism" for tracking, then files a roadmap item and a watch. It picks the tracking method (T1) itself, at medium confidence, from the research doc rather than the entry. |

### Owner (real)

The owner had no staged first take, so the opening-alone elements cannot be graded from a first-take reply. I grade them from the D0 answer instead, and that reading may have used the whole entry.

| Task | Result | Type | Notes |
|---|---|---|---|
| D0 · answer | pass | — | "run or refuse when bwrap sandbox fails". The words "bwrap sandbox" matter: see C1. |
| D0 · status, conditions | not observable | — | The interim and the no-answer default were not stated. With no staging, there is no way to tell whether they were known. |
| D1 | testimony | — | A reframe, not a number: "the sandbox is a feature proposal that needs to have more benefit than cost to release… Until sandboxing is approved as a part of the repo at all, it is not a part of the repo and is unrelated to the hard constraint." |
| D2 | partial (key contested) | contested: misread or overreach | "sessions refuse common tasks and typical workflow breaks." The "cost to you" element (one self-merged loop) is absent. The "if wrong" direction matches the key (runs stop), but the scope is far wider than the key's "a run… stops until someone passes [the flag]". If the owner is right, the table's cost column hides the real cost: overreach, and exactly the profile's worst misreading. If the owner read [2] as being about the reverted Bash sandbox, it is a misread. The session does not settle which. |
| D3 | fail against key (key likely wrong) | — (institutional) | "I mistakenly approved adding the sandboxes… I reverted the change without fully communicating the change of frame, and the agent's framing is an explicitly disallowed state." The key's ● (an H2 exception only the owner grants) is exactly the frame the owner rejects. The owner names the cause: the frame change was never written down. A key built from the records could not have known it, so this is not a reader failure. |
| D4 | partial (key contested) | — | The first ● is found ("begins with 'Not enough data yet'"). The friction ● is not mentioned. The owner's verdict, "No", contradicts the key's premise that a mostly empty return meets Q-272. The key may be what's wrong. |
| D5 | testimony | — | "the re-framing of 'do not use sandboxes' as an option with costs and benefits." Neither key credit. A real-only option. |

---

## 2. Recall

- **Decider.** Problem: matches the gist. Insight: matches ("neither tool works… fallback has never run"), and adds the exit-3 fall-through to an unconfined run. Key move: **misses the gist.** It recalls "the same three Q-272 options back", not "a refusal would have stopped 0 runs, so [2] costs nothing observed and follows H2". Finding: **misses the tentative pick.** It never saw section 4, so this is mostly a staging artifact. But it read row [2]'s "0 runs" and drew "nothing changes under any option" from it, not "[2] is free". Behaviour matches the recall: it refused to pick.
- **Acting agent.** Close to the gist on all four parts. Its key move is "[2]… satisfies H2 without an exception and keeps the network denial", the gist's key move. Its finding adds a caveat the gist lacks, "those zeros may undercount", and names the untested nested-`bwrap` case, the gist's "keep [1] until a real `--probe`".
- **Owner.** No separate recall. Their D1 shows the take they left with: confinement is an unapproved feature, so the gist's frame does not apply.

---

## 3. Candidate findings

Quotes: Dec = decider, AA = acting agent, Own = owner. A stuck-log entry is written S#n, where S# is the section the reader stopped in and n is its number in that reader's stuck log.

| # | Finding | Sessions | Mark |
|---|---|---|---|
| F1 | Owner's frame: confinement/sandboxing is an unapproved feature, so the entry's H2-exception frame does not apply, and the frame change after the revert was never recorded. | Own D1, D3 | KEEP (real-only) |
| F2 | The "0 runs" figures and the cost column understate the real cost or exposure. Own: "[2]: sessions refuse common tasks and typical workflow breaks", and "broke every repo's ability to create worktrees". AA: "'has never run' holds only for the 7 reported loop runs… The table repeats the zeros without that caveat." | Own D2, AA S2#6, S3#6, stuck 7, 14 | KEEP (AA's undercount entries merged in as DUPLICATE, both quotes kept) |
| F3 | The entry came back without the data asked for. Own: "No. I asked for more data, and the first entry under 'The Data' begins with 'Not enough data yet.'" Dec D4: presence "partly", tracking "no". | Own D4, Dec D4 | KEEP |
| F4 | Refusal falls through to an unconfined `run-tests.sh`, weaker than `unshare`, so run-or-refuse is lopsided. Dec: "refuse doesn't narrow access. It widens it… The real H2 gap is in the loop's handling of exit 3, and the entry hasn't asked me about that." AA: "it sits under the heading 'How much friction a refusal would cause', which frames it as a cost question." | Dec S2#5, S3#5, stop; AA S2#5 | KEEP |
| F5 | The owner's Q-272 "track the warnings" went unmet, and that is said only inside the Read line. No option covers it. Dec: "My instruction went unmet, mentioned only inside a link." AA: "'Keep' implies tracking exists while §2 bullet 4 says 'nothing records which tool it found'." | Dec S3#3, D4; AA S3#8, A2 | KEEP |
| F6 | "[1]" names two states: the interim (not written down) and the ratification (written into constraints.md), so a bare `[1]` reads two ways. | AA S3#1, S4#2, stuck 9, 16 | KEEP |
| F7 | "Why it's yours" fits [1] only; [2] and [3] need no exception. The owner's D3 goes further (no exception applies at all), so that part is merged into F1. | Dec S3#1, D3 | KEEP |
| F8 | "If you say no" is ambiguous against an either/or question, and Q-272's "if you never answer" clause was dropped. Dec: "it reads as a false yes/no… I'd expect 'If you don't answer'". AA: "can't tell whether they mean 'no, don't run, refuse' or 'no, don't change my answer'". | Dec S1, stuck 1; AA S1#1 | KEEP. The label is a venue convention (T2), so it bites any either/or entry, but this one's dropped never-answer clause is specific. |
| F9 | A dated amendment (the 2026-11-12 bullet) contradicts bullet 1 instead of rewriting it, so the reader meets a stale claim first. | Dec S2#3; AA S2#4 | KEEP |
| F10 | §4's end condition "the first `--probe` inside a session after the release" names a release that §2 bullet 3 says did not ship `bwrap`. | AA S4#3, stuck 4 | KEEP |
| F11 | "Blocks: nothing. The script has no caller that the fallback would change today" clashes with the 7 loop runs and "every full test run already calls the real `--probe`". It looks carried over from Q-272. | AA S4#4, stuck 17 | KEEP |
| F12 | "the briefs' test wording" is unglossed. If every brief passes the flag, [2] behaves like [1]. | Dec S3#4, stuck 11; AA S3#3 | KEEP |
| F13 | "Your host is not on record" is a fact only the owner can supply, with no command given. It belongs in a terminal entry. | Dec S2#6; AA S2#8 | KEEP |
| F14 | No end condition for "provisional" or "to start". | Dec D0, S3; AA A0, stuck 2 | KEEP (partly answered by §4) |
| F15 | "Wait for data" is a fourth, unnumbered answer in the prose under the table. | AA S4 "a fourth, unnumbered answer"; Dec D5 "defer" (never saw the prose) | KEEP |
| F16 | The Q-272 recommendation hinged on the Q-267 merge; its reversal is never connected. | Dec S2 | KEEP |
| F17 | Bare references: "decision-log row 87", "Q-277 answer [3]", "Q-273". | Dec S2#2, S3#2, stuck 3, 9; AA S2#3, S3#7 | KEEP |
| F18 | Bare hashes (536b7082, 80b7dabe, b9c8966a, 7caea26d). | Dec, AA | DROP. Both readers called them harmless. |
| F19 | `--no-loopback` is undefined, its name doesn't fit what it gates, and "why a new flag?" goes unanswered. | AA S3#4, stuck 12 | KEEP |
| F20 | `--probe` and "exit 3" are undefined in the entry. | AA S2#1, stuck 3 (Dec: resolved by the Q-272 background) | KEEP |
| F21 | "Claude Code's own sandbox, and nobody has tried that yet": why it matters is not stated. | AA S2#7 | KEEP |
| F22 | Row [1]'s "One line in the constraints file": who writes it, and in what words? Q-272's "or ask a session to draft" was dropped. | AA S3#2, stuck 10 | KEEP (partly answered by §4 "which you commit") |
| F23 | Does the warning name what went unenforced, as H2's other half requires? | AA A0, S2 | KEEP |
| F24 | The new flag is unnamed, and whether a flagged run warns is not said. | AA S3#3, stuck 11 | KEEP |
| F25 | "Fallback" shifts meaning in row [3]. | AA S3#5, stuck 13 | KEEP |
| F26 | "No recommendation" next to the table. | Dec S3 | DROP. A staging artifact: the pick sits right under the table and the cut withheld it (see Notes). |
| F27 | "A cold reader would also need the Q-272 option names." | Dec S1 | GENERIC (any returned entry, any cold reader). Drop. |

---

## 4. Convergence

These are the KEEP findings that two or more sessions hit, with each reason and the swap test.

| Finding | Reasons | Swappable? | Count |
|---|---|---|---|
| F1 / F4 · options rejected | Dec: "run versus refuse inside the script decides between paths that can't execute anywhere on record." Own: "Until sandboxing is approved… it is unrelated to the hard constraint." | No. The decider argues for *more* confinement; the owner rejects confinement as unapproved. | 2 (one real) on the outcome. The reasons diverge, so they are not convergence on a cause. |
| F2 · zeros understate | AA: measurement gap ("nothing records which tool it found"). Own: lived cost ("broke every repo's ability to create worktrees"). | No. | 2 (one real) |
| F3 · data condition unmet | Dec: "How often `bwrap` isn't present: partly… Track the warnings: no". Own: "No. I asked for more data". | No. Dec grades it part by part; the owner rejects the return. | 2 (one real) |
| F4 · exit-3 fall-through | Dec: a missing option, "the entry hasn't asked me about that". AA: placement, "it sits under the heading… friction". | No. Scope vs placement, and the readers ended in opposite places (stop vs continue). | 2 |
| F5 · tracking unmet | Dec: an unmet instruction to the owner. AA: no mechanism to act on. | No. | 2 |
| F8 · "If you say no" | Both: either/or is not yes/no, so "no" is ambiguous. | Yes. | 1 |
| F9 · dated amendment | Both: read a stale claim and re-parsed. (AA's downstream effect is split out as F10.) | Yes. | 1 |
| F12 · briefs' wording | Both: if every brief passes the flag, [2] ≈ [1]. | Yes, nearly word for word. | 1 |
| F13 · host not on record | Both: only the owner can supply it, and no command is given. | Yes. | 1 |
| F14 · no end condition | Both: "provisional" with no end. | Yes. | 1 |
| F15 · wait-for-data row | AA saw the prose option. Dec wished for a "defer" row without having seen the prose. | Not comparable: the decider's hit is confounded by staging. | 1 |
| F17 · bare refs | Both: unglossed internal ID. | Yes. | 1 |

**After the test:** 5 findings keep 2 hits (F1/F4 rejection outcome, F2, F3, F4, F5). Three of those five have the owner as the second hit. **None reaches 3, so nothing here is systemic.** The test reduced F8, F9, F12, F13, F14 and F17 from 2 hits to 1, and F15 to 1 because of the staging confound. Most simulated-pair overlaps were swappable. The two simulated readers added breadth, not confirmation.

---

## 5. Severity and kind (findings, most severe first)

| # | Sev. | Kind | Type | Finding | Sessions (after test) | Calibrated? |
|---|---|---|---|---|---|---|
| F1 | S1 | institutional | — | The entry asks inside a frame the owner has withdrawn: an H2 exception for an unapproved feature. A rejection at the venue's screen. | Own | real |
| F2 | S1 | institutional / text-surface | overreach (contested) | The cost and "0 runs" figures understate. Matches the profile's worst misreading: a cost column that hides the real cost. | Own + AA (2) | real (owner) |
| F3 | S2 | institutional | — | Returned without the data asked for, so the decider's D4 (did it bring back what I asked) fails for the real owner. | Own + Dec (2) | real |
| F6 | S2 | text-surface | misread | A bare `[1]` reads as both "ratify" and "leave alone". This is the acting agent's worst misreading (inferring an answer the owner didn't give), on a hard constraint. | AA | uncalibrated |
| F4 | S3 | text-surface | buried | The exit-3 fall-through is filed under "friction". The decider's "real H2 gap" reason is **downgraded**: the owner contradicts its direction. | Dec + AA (2) | partly contradicted |
| F5 | S3 | text-surface | buried | The tracking instruction is unmet, and that sits in the Read line only. | Dec + AA (2) | not reached by owner |
| F7 | S3 | text-surface | misread | "Why it's yours" doesn't match [2]/[3] (profile pain trigger, Q-139). | Dec | owner confirms "the reason is wrong", for a different reason |
| F8 | S3 | text-surface / institutional | misread | "If you say no" vs an either/or question; the never-answer clause was dropped. | 1 | not reached |
| F10 | S3 | text-surface | overreach | The end condition names a release that didn't ship `bwrap`. | AA | uncalibrated |
| F11 | S3 | text-surface | overreach | "Blocks: nothing… no caller" is stale. | AA | uncalibrated |
| F12 | S3 | text-surface | undefined | "the briefs' test wording"; [2] ≈ [1]. | 1 | owner's D2 implies they didn't read [2] as ≈[1] (see calibration) |
| F13 | S3 | institutional | — | Host fact belongs in a `you: terminal` entry. | 1 | not reached |
| F9 | S3 | text-surface | misread | The dated amendment instead of a rewrite. | 1 | not reached (P8) |
| F14 | S3 | text-surface | missing | No end condition for "provisional". | 1 | not reached |
| F15 | S3 | text-surface | — | "Wait for data" is an unnumbered option. | 1 | not reached (P9 miss) |
| F16 | S3 | text-surface | missing | Q-267's reversal is not tied to Q-272's recommendation. | Dec | not reached |
| F19 | S3 | text-surface | undefined | `--no-loopback`. | AA | uncalibrated |
| F21 | S3 | text-surface | buried | Why the nested sandbox matters (it is only in the research doc). | AA | uncalibrated |
| F22 | S3 | text-surface | missing | Who drafts the constraints line, and in what words. | AA | uncalibrated |
| F23 | S3 | institutional | missing | Whether the warning meets H2's naming half. | AA | uncalibrated |
| F17 | S4 | text-surface | undefined | Bare refs (row 87, Q-277 [3]). **Downgraded**: P7 was not observed and the owner raised none. | 1 | not reached |
| F20 | S4 | text-surface | undefined | `--probe` and exit 3. | AA | uncalibrated |
| F24 | S4 | text-surface | missing | Flag name, and whether a flagged run warns. | AA | uncalibrated |
| F25 | S4 | text-surface | misread | "Fallback" shifts meaning. | AA | uncalibrated |

---

## 6. Calibration

### Predictions (`predictions-owner.md`) against `sessions/owner.md`

| # | Prediction (credence) | Score | Evidence |
|---|---|---|---|
| P1 | D0 right: run-or-refuse, and no answer keeps run-and-warn (85%) | not observable | First half hit ("run or refuse when bwrap sandbox fails"); the no-answer half was not stated. |
| P2 | Bare option number (50%) | miss | Reframe, no number. |
| P3 | Picks [2] (40%) | miss | |
| P4 | Keeps [1] or waits (40%) | miss | |
| P5 | Rejects or reframes (20%) | **hit** | "reframe: the sandbox is a feature proposal…" |
| P6 | D4: both conditions answered, presence "no data" (60%) | miss | "No." The owner cited "Not enough data yet" as the failure. |
| P7 | Stop on a bare reference (55%) | not observable | No stuck log was collected, and no reference is mentioned. |
| P8 | The 11-12 paragraph is called confusing or misread (40%) | not observable | Not called confusing. Whether the owner's "sandbox" reading comes from that paragraph is unsettled (C1). |
| P9 | D5 names wait-for-data / the prose pick as a row (30%) | miss | Named "do not use sandboxes" instead. |
| P10 | Opens a linked doc before D1 (30%) | not observable | Not reported. |
| P11 | At least one point no simulated reader raised (70%) | **hit** | The frame, the worktree breakage, and the do-not-use-sandboxes option. |

Under the scoring rule, the P6 miss counts against the decider's D4 "pass" (the key's frame), and the P9 miss weakens F15.

### Simulated decider against the real owner

- **Confirmed by the owner:**
  - Neither would pick a number; both rejected the options (outcome only).
  - The "why it's yours" reason does not hold (direction only).
  - The return did not fully deliver what Q-272 asked (F3).
- **Contradicted by the owner:**
  - The decider's reason for rejecting: that the live gap is too *little* confinement on exit 3, so it wanted tracking and an exit-3 entry. The owner's reason runs the other way: confinement is unapproved, and they want a "do not use sandboxes" option.
  - The decider's D2 caveat that [2] "behaves like [1]", costless in practice. The owner reads [2] as "sessions refuse common tasks and typical workflow breaks".
  - The decider's proposed answer ("keep [1]… no exception written").
  - All three are downgraded.
- **Not reached by the owner:** F8, F9, F12, F13, F14, F15, F16, F17, the stale Q-267 hinge, and the host paste.
- **Owner-only:**
  - The sandbox is an unapproved feature needing a cost/benefit case.
  - The previous implementation "broke every repo's ability to create worktrees".
  - The frame change after the revert was never communicated.
  - "the agent's framing is an explicitly disallowed state".
  - [2]'s cost is broken workflow.
  - The missing option "do not use sandboxes".
  - The return was a "No".

### Acting agent

**Uncalibrated.** It has no real counterpart. All of its findings (F6, F10, F11, F19–F25, and its half of F2 and F4) stand on the simulation alone.

### What this implies for the decider archetype (`docs/audiences/owner.md`)

- **What they know (knowledge limit).** The field lists only what the owner *doesn't* know. This run shows the other direction matters as much: the owner holds frames that the records lack, set by action (a revert) and never written as an answer. Add: "Their current frame can postdate the records. A reverted or regretted approval may never appear as an answer." The author's call 3 options don't cover this. It is a new option, not [2] or [3].
- **How they read.** "They read the premise and attack it when it's wrong" and "often answer the larger question" were both confirmed (D1). Keep both, and add this run as evidence next to Q-017, Q-059 and Q-274.
- **Pain triggers.** Add: "an entry that treats a feature they reverted, or never approved, as standing policy or a constraint to except". The listed triggers (bare references, a "why it's yours" that doesn't match the table) were voiced only by the simulation in this run. One session can't demote them, but P7 gave them no support.
- **Worst misreading.** "Picking an option whose cost column hid the real cost" is the owner's own D2 concern, so the field is well aimed, although this owner caught it rather than being misled. Consider adding a sibling ahead of "answering when the call wasn't theirs": **being asked the wrong call**, where the options sit inside a frame the owner has withdrawn.
- **Success test.** This entry failed it: the owner gave no number.
- **Prediction base rate.** P5 at 20% was the only answer-shape hit. Entries returning on a changed frame may be a class where a reframe is the likely answer. That rests on one run, so treat it as a lead, not a rate.
- **For simulated deciders generally.** They reproduced the premise-attack *behaviour* from evidence inside the text, but they cannot see a frame held only in the owner's head, and here they pointed the opposite way. On this evidence, simulated agreement on "reject" is not calibration on "why".

---

## 7. Correctness candidates (Part A)

Not verified. The verdict column is left empty for the verifier.

| # | Finding | Raised by | Verdict | Where |
|---|---|---|---|---|
| C1 | The entry's frame is wrong: the `bwrap`/`unshare` fallback is not an H2 exception to grant, because sandboxing was never approved. "Until sandboxing is approved… it is unrelated to the hard constraint." "the agent's framing is an explicitly disallowed state." **Unsettled:** does the owner's "sandboxing" cover `scripts/confine-tests.sh`, or did §2 bullet 3 (the Bash-sandbox revert took `bwrap` out) lead the owner to read the question as about the reverted Bash sandbox? The owner's D0 says "bwrap sandbox", and the D2 "common tasks" sounds like the Bash sandbox. My credence is about even between the two readings. Ask the owner rather than infer. | Own D1, D3, D0 | | question line, If you say no, Why it's yours, tentative pick |
| C2 | The cost column understates. "One self-merged build loop" and "0 runs would have stopped" vs Own: "[2]: sessions refuse common tasks and typical workflow breaks"; "previous implementation broke every repo's ability to create worktrees". | Own D1, D2 | | table, Cost and If-wrong cells |
| C3 | "the `unshare` fallback has never run and its warning has never printed" claims more than the records show, because "nothing records which tool it found". The table repeats the zeros with no caveat. | AA S2#6, S3#6, stuck 7, 14 | | §2 bullets 2 and 4, table |
| C4 | "You asked for Q-272 back with data" implies the condition is met, but the data's first line is "Not enough data yet". The owner: "No". | Own D4; Dec D4 ("partly") | | question line, §2 bullet 1 |
| C5 | "Blocks: nothing. The script has no caller that the fallback would change today": 7 loops ran it, and every full test run calls `--probe`. Likely carried over from Q-272 ("Nothing calls the script yet"). | AA S4#4 | | Blocks |
| C6 | "keep [1] until the first `--probe` inside a session after the release": per §2 bullet 3, that release did not ship `bwrap`. | AA S4#3 | | tentative pick |
| C7 | "Why it's yours: it is an exception to a hard constraint" overreaches for [2] and [3], which need no exception. (C1 disputes the premise itself.) | Dec S3#1, D3 | | Why it's yours |
| C8 | The claim that [2] "follows H2 as written with no exception" is questioned. If the briefs pass the flag, [2] runs `unshare` like [1] (Dec: "[2] behaves like [1] plus a flag"). The entry doesn't say why opt-in satisfies H2 (AA: "the research doc does"). Also, refusing under [2]/[3] drops loops to an unconfined run, which Dec says "widens" access. | Dec S2#5, S3#4, S3#5; AA S3#3 | | row [2], row [3], tentative pick |

The key's points that the owner contradicts are also flagged for the orchestrator: key D3 (the H2 exception), key D4 (an empty return meets Q-272) and key D2 (the cost). The decider's third Q-272 part ("track the warnings") is also absent from key D4.

---

## 8. Where archetypes conflict

- **Decider vs acting agent, on detail.** The agent wants the flag name, the warning behaviour, the exception wording, a tracking mechanism, the end condition, and glosses for `--probe`, exit 3 and `--no-loopback`. The decider wants less text, and here a different question. *Profile rule:* the decider decides, and the agent's detail moves to a layer, namely the linked research doc and "If the answer differs" (call 2).
- **Decider vs operator, on the host fact.** "Your host is not on record" is a terminal ask inside a judgment entry. *Profile rule:* the other need moves to the paste block. The grammar adds one judgment per entry, and terminal asks collect into one paste, so it becomes a separate `you: terminal` entry.
- **"[1]" naming (F6).** This is not a real conflict: giving the interim its own name helps both the decider ("[1] (as now)") and the agent. The rule isn't needed.
- **Real owner vs acting agent.** The owner's answer has no option number. That is the agent's named pain trigger ("an answer that carries a condition or a question back… the entry's grammar has nowhere to put either"), and its success test ("given… a bare answer") can't run. The profile's conflict rule doesn't cover this. It resolves only by re-asking.
- **Not covered by the conflict rule: the records vs the owner.** The profile's rule assumes all archetypes share one frame. In this run the conflict was between the frame the records carry (used by the post, the key and both simulations) and the frame the owner holds. No layer fixes that. It needs the owner's frame written down (a decision record or log row), then a re-asked entry.

---

## Notes for the skill

- **The light tier was cheap and productive.** The owner's whole contribution was six short lines, and it produced the run's two S1 findings. For a single entry, one real reader outweighed both simulations put together.
- **The staging cut split the decider's reading unit.** The profile says the decider reads the question line, the table and the recommendation together. The cut released the table without the pick, and the decider stopped on its own condition before seeing it, so the post's answer to its objections was never tested (F26 dropped). Cut at the profile's reading units: release the recommendation with the table.
- **An unstaged real session leaves opening-alone elements and stop predictions ungradable.** P1, P7, P8 and P10 were unobservable because the session collected no first take, stuck log or reading path. Either ask D0 before the owner reads on, plus one line on "where did you stop?", or pre-register only predictions the session's form can check.
- **A key written by the post's author shares the post's frame.** When the real reader rejects the frame, the key can't grade (D3, D4, D2 here). Give the grade table a "key contested" outcome. Where possible, take the key's gist from a source independent of the author, or flag the frame as an assumption in the key's header.
- **The grader brief should ask for an "unsettled reading" check** whenever a real reader's answer could be either a correct reframe or a misreading the text invited (C1). These need the reader, not the verifier, to settle.
- **The acting agent asked whether a linked doc counts as "the post resolving it".** Several of its resolutions came from the grammar file and the research doc. The reader brief should say, and the grader should then treat a resolution found only in a linked doc as *buried*.
- **Its suggestion of a bare-`[1]` task is worth adopting.** It would test F6 directly, instead of through A2's conditional answer.
- **With two simulated readers, the convergent-reasons test cut most overlaps to one hit.** Every two-hit survivor except F4 and F5 had the real owner as its second hit. On a light tier, plan for the real reader to be the only independent second session.

---

## Part A status (orchestrator)

The verifier was **not run** this round. Q-278 was already answered (by reframe) and archived before
grading, so Part A no longer blocks anything. C1 is an unsettled reading that only the owner can settle,
not a check a verifier can run. C3, C5 and C6 can be checked from the repo records, and they go to
whoever writes the successor entry, as items to verify before re-asking.

## Revision brief (orchestrator, from the author's chair)

For whichever entry replaces Q-278, if one is needed after the owner's reframe:

1. **Settle the frame first (C1, F1).** Ask the owner one thing: does "sandboxing" in the Q-278 answer
   cover the test-confinement script `scripts/confine-tests.sh`, or only Claude Code's Bash sandbox,
   which was reverted? Record the frame as a decision-log row before any option is written. The records
   lacked it, and that is why the post, the key and both simulated readers shared the wrong frame.
2. **Only then, options with costs and benefits (F2, D5).** One option must be the owner's "do not use
   sandboxes". The cost column must carry the observed cost (worktree creation broke in every repo),
   not "one self-merged build loop". A "0 runs" figure needs its undercount caveat (C3).
3. **Don't return an ask before its condition is met (F3, C4).** If the requested data is "not enough
   yet", say so in one line and keep the entry closed, or file a watch. Don't present options.
4. **Smaller fixes, kept for the successor:** name the interim separately from [1] (F6); rewrite a
   corrected bullet rather than appending (F9); fix "Blocks" (C5) and the end condition (C6); move the
   host fact to a terminal entry (F13).

**Claims a revision may change:** the frame (C1), the cost column (C2), the "never run" claim (C3),
"Blocks" (C5), the end condition (C6), and "why it's yours" (C7).

## C1 settled by the owner (orchestrator, 2026-11-18)

The owner's follow-up settles C1 as a **misread the text invited**, not a reframe of the script: "I never
saw a reference to the test confinement script in the question text!" The question line names
`scripts/confine-tests.sh` once, inside a gloss. The rest of the entry talks about `bwrap`, image
releases, and "main rolled the Bash sandbox back" (§2 bullet 3). So the owner read the whole entry as
being about the reverted Bash sandbox.

What changes as a result:
- **F1 becomes a text-surface S1**: the subject of the entry was misread, a misread type. Before, it was
  an institutional finding about a withdrawn frame. The owner's frame (sandboxing must earn its place)
  still stands, but it was aimed at the Bash sandbox.
- **Q-278 is not answered.** The record of it as answered (e387ec24) was wrong. The entry is reopened, to be
  rewritten, and the rewrite is a Now item on the roadmap.
- **For the profile's decider archetype** (`docs/audiences/owner.md`): a name given once, inside a gloss,
  is missed when the rest of the entry uses a near-synonym ("sandbox" against "test confinement"). Both
  simulated readers caught the script name; the real reader didn't. That is the clearest calibration
  result of the run.
- **The calibration section above is partly wrong.** It counts "the owner rejected the frame" as a real-only
  finding about frames held off the record. Part of it was this misread. Read that section with that in
  mind.
