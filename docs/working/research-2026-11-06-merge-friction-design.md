# Research: does merge approval need changing? (ideas A1, A3, A10)

- **Goal**: Record a divergent-design decision on how gate merges and image releases are bundled and approved, testing first whether anything needs to change.
- **Problem framing**: Every change to the gate's own code costs the owner a merge entry, all 37 sampled entries were answered with the default, and a merged gate change does nothing until a host release, so the question is whether that cost buys anything the owner wants. Considered and discarded: "the owner approves too much, so cut the number of approvals", which assumes the entries are pure cost, when the owner says they follow the work through these answers.
- **Project state**: design record only, no code · brief `docs/working/briefs/2026-11-06-merge-friction-design.md`, from the area A flag in the 2026-10-29 brainstorm · not blocked (cite: 62687b97)
- **Task status**: complete (Path A: status quo; nothing changes, so no owner question)

Tags: [observed] checked by reading or running; [inferred] derived from observed facts; [assumed] not checked. DD's step output is folded in here, as DD allows inside RPI. The record stays in this file rather than `docs/decisions/`, because the brief's `Paths:` line and the self-merge floor keep that directory out of reach. No plan doc: the only deliverable is this file and the brief's status line.

## 1. Result in brief

- **Pick: [0], which is A10.** Leave the merge entries alone. No gate code, skill text, entry format or release step changes. T3's batched answers stay as the presentation they already are.
- **Motive test: weak, not absent.** The owner's latest words are that batching is "fine, but it's not targetting a big blocker" and that they follow the repo through these answers. The owner's founding purpose does point at fewer asks, so the motive stands as a general goal. But the sample's cost is modest, and no option delivers that goal cheaply and safely.
- **A1 fails on its own test.** Of the 22 gate entries, a path-only tier safely moves none, and the wider tier needs a judgment the gate may not key on (constraint H4).
- **A3 saves no ask and no paste.** The owner still answers once and pastes once, and one release covering several merges is already better than one each.
- **The one real rival is new: [5], release as the approval.** It would remove between 3 and 22 of the 37 entries, depending on how much of the floor it also lifts. It is held back as the named fallback, with thresholds in section 11, because there is no recent request for it and it moves the review to a channel the owner says they do not read closely.
- **Confidence 85%, Path A.** No question goes to the owner.

## 2. What exists

- **How a merge reaches the owner.** Build loops end `handoff: ready`. Under `Build-loop policy: self-merge` the orchestrator lands a branch through `build-loop.sh --merge`, unless a changed path is on the floor or the never line, or the brief says `Policy: review`. Then it files a merge entry, `merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when the change touches gate code, and merges only on `[1]` for the exact commit (`docs/dev-cycle.md`; `skills/dev-cycle/SKILL.md` step 7) [observed].
- **The floor.** `floor()` in `scripts/lib/dev-cycle-read.sh` refuses instruction and prompt files, dot paths, `docs/decisions/`, `docs/human-author/`, the failure-pattern library, the cycle's own files, other briefs' working docs and reviews, and GATE_CODE: `^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/`. The never line here is `workflows/` [observed].
- **Why gate code is on the floor.** The lib's comment: the image copy, built from the host checkout's HEAD, runs every merge after the next release, and `SKILL.md` "states the call". So a gate change takes effect only at a host release, a second human action [observed].
- **The owner already chose this shape.** Q-103 [2] (self-merge, 2026-10-17) and Q-149 [2] ("I don't want this much merging blocked on my manual actions"): only `workflows/` on the never line, with named risks accepted, such as a self-merged script running in the next health check. Q-149's options covered only the never line, so the floor was left in place rather than chosen [observed].
- **Release path.** The cycle files one `image-lag` entry (`you: terminal`) with release notes and one paste. It closes itself once the image holds main's gate code (Q-251). The paste needs every session stopped first (Q-261) [observed].
- **Already shipped in this area.** Q-230: an in-session answer counts, after the owner's 10-29 note that the gate was too strict. T3: batched answers such as `Q-239..241: [1]`. T2: `If you say no:` lines. T5: the weekly digest with B2's counter. All stay, by the roadmap's reading of the trial [observed].

## 3. The answers on record

**Sample.** Every entry at 62687b97 whose heading slug starts `merge-` and whose `Opened:` date is 2026-10-14 or later. All are in `docs/working/questions-archive.md`; `questions.md` holds none. That rule was chosen because it is the class B2's counter uses and it is mechanical. It gives 37 entries: 22 `merge-gate-`, 15 `merge-`. They cover 34 branches, because three were re-filed at a new commit (Q-231 as Q-233, Q-243 as Q-249, Q-244 as Q-248). Appendix A lists each one.

Left out, as not being a merge approval of one branch: Q-148 (a review-cap decision), Q-162 (a cleanup paste), Q-175 (test coverage), Q-177 (see below), Q-246 and Q-247 (re-dispatch after a conflict), and the `image-lag` entries.

**How the numbers were made.** A python3 pass over the 137 first-parent commits since 10-10 touching the two questions files. "Filed" is the first of those commits holding the heading; "answered" is the first showing `Status: ANSWERED`. Both are commit times, so a wait is an upper bound on the owner's delay: the answer comes before the next iteration records it. Q-163 and Q-164 first appear a day after their `Opened:` date, so theirs may be low. All of this is an estimate of attention, not a measure of it: nothing records whether an entry was read.

| Measure | Result |
|---|---|
| Answered with the default option | 37 of 37, all `[1]` [observed] |
| Filed per week | 11.3 over 23 days, but uneven: 7 (10-14 to 10-20), 3 (to 10-27), 23 (to 11-03), 4 (to 11-06) [observed] |
| Wait, filed to answer recorded | median 9.8 h, quartiles 1.4 h and 41.4 h, maximum 185.6 h (Q-217); 25 under a day, 9 over two days [observed] |
| Wait, by when the answer was recorded | median 66.9 h for the 10 recorded by the morning of 10-28, 3.1 h for the 27 after [observed]. The drop came before Q-230 landed: the 7 entries filed just before it have a median of 1.2 h. So waits track when the owner sits down, and no one change explains them [inferred] |
| Recording commits holding merge answers | 17, about 5 a week and 2.2 entries each: a proxy for sittings [inferred] |
| Entry length | 18,886 words in all, 510 on average [observed] |
| Reading time | about 29 minutes a week if every word is read, about 6 if only about 100 words per entry are, at 200 words a minute [assumed rate] |
| Answer messages with the owner's own words beyond ID and option | 2: "probably worth merging Q-233 before the release" and "Merge all three" (Q-235 to Q-237) [observed] |
| Reverts of an approved merge | 0 since 10-14 [observed] |

**What the 37 were for.** Two programmes make up 12 of them: decision 040's units (Q-224, Q-229, Q-235) and the seven-unit restriction audit (Q-243, Q-244, Q-245, Q-248, Q-249, Q-250, Q-251, Q-253, Q-259). Both are finished: the digest calls Q-235 the last build unit, and Q-259 calls itself the audit's last unit [observed]. Without those 12 the rate is still 7.6 a week, and the last 3 days ran at about 9 a week, while nothing shows that no new gate programme will start. So the peak should pass, but the rate may not fall much below that [inferred].

**Do these entries ever carry a decision?** On the record, a few do:

- At least seven carry a loop's own design call or departure for the owner to accept (Q-219, Q-228, Q-229, Q-231, Q-244, Q-250, Q-259), and Q-163 a residual the security critic asked the owner to confirm [observed].
- Q-241's first version drew the owner's ruling that a hostile code author is out of scope. That ruling changed review briefs from then on, and the trial doc records it, yet the entry reads as a plain [1] [observed].
- Q-177, left out above, is a merge question with options, which the owner answered [3] [observed].

In the other direction, Q-237 fixed a false refusal in `scripts/lib/migrations.sh`, filed about 2.5 hours after the approved Q-233 landed that file, so an approval does not act as a bug check [inferred].

**Do the entries block work?** A branch waiting on the owner does not hold a build slot (`docs/dev-cycle.md`, Slots). `Blocks:` lines name waiting work in 12 of the 37, mostly later units that edit the same files [observed]. Those lines undercount: Q-259 says it blocks nothing else in the audit, yet `docs/working/cycles/cycle-2026-11-06.md` records other work held until Q-259 and Q-260 were answered [observed]. The worst cost was at a conflict: Q-243 and Q-244 were approved, refused on a conflict, and came back through Q-246 to Q-249, six asks for two branches [observed].

**Release side.** The image commits on record since 10-14 number six (fbe67674, fe57e352, 46929c81, 42295bd9, c214970a, dff98910) against 34 branches [observed], and that list may be incomplete. Of the 18 gate merges with a landing commit found, 16 reached one of those images by 11-06; Q-259 and Q-260 wait on Q-261. The image commit came a median 7.7 hours after the merge (maximum 217.6 h, Q-197). That is a lower bound on time to live, as the install runs after the commit [observed]; the real lag is unmeasured. It does have a cost: Q-259's interim bars briefs touching `scripts/d6.sh` until a release [observed].

## 4. Motive test (S5)

Does the problem exist, in the owner's terms?

| Evidence | Reads as |
|---|---|
| 2026-10-09, Q-137 (memory note): "For review adjustments and merges like this, go ahead with your recommendation"; the landing questions cost attention with no decision in them | For change. Those were gate units, which self-merge has never covered |
| 2026-10-20 feedback, the founding purpose of the dev cycle: agents saying "should I merge this?", with the answer "yes, with this review process" available without the owner's input | For change, and the strongest line here: a standing goal, not a complaint |
| 2026-10-17, Q-149: "I don't want this much merging blocked on my manual actions" | For change, but it was about the never line; the floor was not on offer |
| 2026-10-20 feedback: "a larger amount of process blockage"; the skill "stops to ask for permission at far more stages" | For change, about stops in general |
| 2026-10-29: asks where the harness creates friction, above all in merges (brainstorm); "can't merge from a chat answer ... the gate is too strict" | For change, and Q-230 fixed that one the same day |
| 2026-11-06, T3: "this is fine, but it's not targetting a big blocker" | Against, within limits: the latest word, but it judges a bundling display, not options that remove asks |
| 2026-11-06, T1: "I'm mostly tracking what's happening in the repo via my answers to other questions" | Against: an entry is also the owner's view of the work |
| 2026-11-06, T5: the digest "will be more helpful as work requires less intervention from me" | Mild for: fewer asks would be welcome, though it is a condition, not a request |
| 2026-11-06, T2: "the biggest problem is jargon and references" | Elsewhere: legibility, already briefed as `2026-11-06-owner-entry-gloss-rule` |

**Verdict.** The goal of fewer asks is real and long-standing. There is no recent request about merge approval, though, and the owner names something else as the biggest problem. The benefit of change is an estimated 6 to 29 minutes a week, and the owner values part of that as tracking. That does not rule out a change, but a change has to be cheap, safe and clearly better. Section 8 tests whether any is.

## 5. The Tension paragraph and B2's metric

The brainstorm says B4 and B8 add owner time while A1, A2 and B2 remove it, that the intended trade is many routine approvals for a few deliberate looks, and that B2's metric checks the total falls.

- **B2 as written fires.** Merge entries have been answered with the default every time for over three weeks (11 of 11 and 17 of 17 in the digests, 37 of 37 here), so "the cycle proposes moving that class off the owner's desk". This record is that proposal's test, not a reason to skip it.
- **The default rate cannot tell the two readings apart.** 100% fits "the loops are good" (A10) and "the owner has stopped reading" (the brainstorm's area B) equally. The digest's first edition read it as the habit, because other judgment answers were 0 of 3 default. Its second found them 3 of 3 default, but two of those were re-dispatch calls and the two real choices were still unanswered, so the contrast is untested, not refuted.
- **The count overstates asks.** Three entries are re-files of an approved branch, and a batch of three is one sitting. Sittings, about 5 a week, are nearer the cost than entries.
- **The receiving side of the trade does not exist yet.** B4's sample has run twice with no reply on record, and T5's feedback, though warm about the digest, does not mention it. B8 is not due until 2027-01. Moving approvals off the desk today would cut the owner's total time, but not by the intended trade: routine looks would stop and no deliberate look would replace them. The metric would read as success either way.
- **So the metric needs its second half.** The check that the total fell and attention moved is two numbers together: merge-answer sittings per week, and deliberate looks per week (replies to the digest's sample). Section 11 uses that pair.

## 6. Step 1: candidates

`Prior pruning grep: no matches found for [approval, self-merge, merge entr, release, owner ask]` (the one hit, in decision 036's list, is about repo splitting). Candidate 0 is the prior decision: plan D5, Q-103 [2] and Q-149 [2].

- **[0] Status quo (A10).** One entry per branch, batched presentation, release entry as it stands.
- **[1] A1 as written.** Three classes leave the owner: docs in `skills/dev-cycle/`, test-only changes, a bug fix its brief's criteria pin down.
- **[2] A1, paths only.** The same split with no judgment: a gate-code change whose paths pass a fixed path test self-merges.
- **[3] A3.** A merge entry's option becomes "merge, then give me the release paste".
- **[4] A2, built.** One real batched entry per cycle in gate code (the baseline; T3 ran its presentation).
- **[5] Release as the approval (new).** Gate-code branches self-land on main, where they cannot run as the gate. The release entry becomes the one approval, with a list of what it carries. `SKILL.md` is refused as an instruction file before GATE_CODE is tested, so [5] must lift that too, and most gate branches touch other floor paths as well.
- **[6] Silence is consent (new, feels wrong).** A merge entry lands after N hours with no objection.
- **[7] Sampled audit (new; B4 in place of approval).** Gate merges self-land, and a random one in N gets an owner entry.
- **[8] A second agent signs (new, naive).** An independent review agent approves in the owner's place.
- **[9] Approve the programme (new).** The owner approves a brief or plan once, and its units land when `--check` passes.
- **[10] Behaviour corpus as the tier test (new, ideal if effort were free).** Replay a frozen set of gate decisions against the branch: unchanged verdicts means enforcement is unchanged, which is the mechanical test A1 lacks.
- **[11] Short entries (new).** Three lines and a link in place of about 510 words.
- **[12] Fewer, larger gate units (new).** Bundle gate work so there are fewer branches to approve.
- **[13] Empty the gate list (new, feels wrong).** Gate code self-merges like any other script.
- **[14] Auto re-dispatch (new).** After an approved merge refuses on a conflict, the cycle re-dispatches without asking (Q-246, Q-247).

Health check: the first pass clustered on who approves, so [11], [12] and [14] were added on other levers (what is shown, unit size, conflict handling). Lenses covered: technical [10], interface [3][11], procedural [5][6][7][9], organisational [8], time-shifted [5][12], reframe [0].

## 7. Step 2: constraints

Hard, with the repo's `success:` lines as quoted to this loop:

- **H1** Gate logic runs from a copy the change cannot edit. success: a new gate path is added to GATE_CODE, and wiring points at `{{CLAUDE_DIR}}/hooks/`.
- **H2** A gate fails closed: an absent verdict refuses. success: each new failure path has a bats case asserting a refusal.
- **H3** Verifiable in the sandbox with hermetic tests. success: `bats` and `scripts/hermeticity-lint --root .` pass with new cases.
- **H4** An LLM judgment is never an enforcement primitive; a blocking gate keys on something re-checkable. success: the `rg` for `claude -p` in the gate prints nothing, and a new judgment check is capped at amber.

Soft: S1 (proportionate restriction; gates defend against honest slips), S2 (no new mandatory dispatch), S3 (reuse the existing mechanism), S5 (motive first), S6 (an observable that could come out negative), S8 (small units), S10 (spend the user's attention last, and no merge waits on the user when a fail-closed alternative exists).

Decision-specific, soft:

- **P1** Total owner attention falls, by section 5's pair.
- **P2** The owner keeps a working view of the work (T1, T5).
- **P3** A change to what the gate refuses or allows still gets a human look before it runs.
- **P4** A "no" stays local: refusing one change does not hold up others.

## 8. Step 3: match and prune

✓ addresses well, ~ partial, ✗ does not, ⚠ makes worse. S1, S2, S5 and S6 separate few candidates and are weighed in section 9. H1 is ~ wherever the gate still runs from the image but GATE_CODE stops meaning "never self-merges".

| # | Approach | H1 | H2 | H3 | H4 | S3 | S8 | S10 | P1 | P2 | P3 | P4 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | Status quo | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✓ | ✓ | ✓ |
| 1 | A1 as written | ~ | ~ | ✓ | ⚠ | ~ | ~ | ✓ | ~ | ~ | ~ | ✓ |
| 2 | A1, paths only | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✗ | ✓ | ~ | ✓ |
| 3 | A3 | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✗ | ✓ | ✓ | ✓ |
| 4 | A2 built | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ~ | ✗ | ✓ | ~ | ~ |
| 5 | Release as approval | ~ | ✓ | ✓ | ✓ | ~ | ✗ | ✓ | ~ | ~ | ~ | ⚠ |
| 6 | Silence is consent | ✓ | ⚠ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ |
| 7 | Sampled audit | ~ | ~ | ✓ | ✓ | ~ | ~ | ✓ | ~ | ✗ | ✗ | ✓ |
| 8 | Second agent signs | ~ | ~ | ✗ | ⚠ | ✗ | ✗ | ✓ | ✓ | ✗ | ✗ | ✓ |
| 9 | Approve the programme | ~ | ~ | ✓ | ✓ | ~ | ~ | ✓ | ~ | ~ | ✗ | ~ |
| 10 | Behaviour corpus | ✓ | ~ | ✓ | ✓ | ✗ | ✗ | ✓ | ~ | ~ | ~ | ✓ |
| 11 | Short entries | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ~ | ✓ | ✓ |
| 12 | Fewer, larger units | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ~ | ~ | ✓ | ~ | ⚠ |
| 13 | Empty the gate list | ~ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✗ | ✗ | ✓ |
| 14 | Auto re-dispatch | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ✓ | ✓ | ✓ |

**Testing A1 against the sample.** The 22 gate entries, by the brainstorm's three classes:

- **Test-only:** none, and none can be: `merge-gate-` means a GATE_CODE path changed [observed].
- **Docs in `skills/dev-cycle/`:** four entries change only `SKILL.md` among gate paths (Q-230, Q-239, Q-243, Q-249), and that directory holds no other file. None is only documentation: Q-230 loosens an approval rule, Q-239 moves where the health check runs, and Q-243 and Q-249 drop the hardened-git wrapper [observed]. `SKILL.md` is the orchestrator's program, so a path test would put approval-rule changes in the bottom tier.
- **Bug fix pinned by its criteria:** Q-237 and Q-240, and Q-239 again; Q-163 is a fix too, but it carries a residual for the owner to confirm [observed]. Any brief has criteria, so deciding that they "pin it down" is a judgment.

So a path-only tier safely moves 0 of 22. The wider tier moves at most 6 (Q-230, Q-237, Q-239, Q-240, Q-243, Q-249), and every one rests on a judgment or a misreading of `SKILL.md`. Testing A1's definition instead of its examples ("what a gate refuses or allows") needs that same judgment. `^scripts/lib/` does over-match Q-197's `si-commit.sh`, but narrowing it would spare nothing, because that branch also changes a working doc the floor refuses [observed].

**Testing [5] the same way.** Lifting GATE_CODE alone clears 3 entries (Q-224, Q-229, Q-237); also exempting `SKILL.md` clears 7. Reaching 22 means lifting the other floor paths those branches touch: `workflows/`, instruction files, the decision log and plan notes, many of them incidental [observed by a reviewer running the real `floor()` with the import walk stubbed, against today's floor].

**Survivors:** six break no hard line: [0], [2], [3], [5], [7], [13]. The first four go to step 4. [7] and [13] are dominated by [5]: they share its risks and drop the one approval it keeps, so they are ✗ on P3. The pruned list is in section 10. [2] and [3] survive only because they break no hard line. [11] and [14] do not compete with the choice: they could sit on top of any survivor, and [11]'s real motive is already briefed, so they are left to their own routes.

## 9. Step 4: tradeoffs

| # | Effort | Risk | Coverage of the sample | Key downside |
|---|---|---|---|---|
| 0 | None | Low | 0 of 37 removed | The always-[1] habit stays, with T2's and T6's mitigations only |
| 2 | About a day, plus its own merge entry | Low to medium | 0 of 22 safely | A gate change that buys nothing in this sample |
| 3 | About a day, plus its own merge entry | Low | No ask or paste removed | The paste can only follow the merge, and needs every session stopped |
| 5 | Several days of gate and floor redesign | High | 3 to 22 of 37 removed, by how much of the floor it lifts | A "no" at release blocks everything behind it, and the review moves to notes the owner skims |

Effort figures are [assumed].

**Hypotheses.**

- **[0]** If chosen, merge entries run at about 8 a week or fewer across the next 4 weekly digests, the sample's rate without the two programmes; counter-evidence is more than 11 a week, the sample's full rate, in 3 of those 4.
- **[2]** If chosen, gate entries fall at all; counter-evidence is no change in the B2 counter over 4 digests, which this sample predicts.
- **[3]** If chosen, the time from merge to live falls by at least a third over 4 releases; counter-evidence is no change, which the owner-timed paste suggests, though the real lag is unmeasured.
- **[5]** If chosen, sittings halve within 4 weeks with no fix within 7 days to a released gate change; counter-evidence is a held release, or a gate defect the owner says the old entry would have shown.

**Stress test.**

- **Invert the thesis (argue for [5]).** Gate code only runs from the image, so a merge to main is not the moment of risk; the release is. The owner already acts at every release, the review would cover the batch that will actually run, merges would stop waiting, and S10 asks for this when a fail-closed alternative exists. What survives: all of that is true, and it is why [5] is the fallback. What does not: today a "no" drops one unmerged branch at no cost (P4), and a revert is the rare case after an approval proves wrong. With [5] every "no" is a revert on main under later work, or a hold on every release behind it. It would also take away the gate entries the owner tracks work through, leaving the 15 non-gate ones and the digest (P2), and put the only review in release notes that T1 says are not read closely (P3). Most of its saving also needs the wider floor changes in section 8. And S10 is soft: it ranks survivors and does not force a redesign of the approval path against a stated "not a big blocker". Mitigation: [5] is named as the fallback in section 11.
- **Boring alternative.** Is anything simpler than a tier? Only living with the rate, about 8 a week once the peak passes, and that is checkable, so [0]'s hypothesis says so. Section 8's count moved [2] from "cheap win" to "not worth its own merge entry".
- **Revealed preferences.** Since an in-session answer has counted, the owner answers these in a median of hours, ran about five releases in eight days without complaint [inferred from image commits], and has not replied to either digest sample. They use the entries and the releases, and they read the digest, but they have not taken up its sampled look. That counts against a design leaning on the sample to replace an entry, for now.
- **Does [0] accept the habituation risk?** Yes, knowingly. A real problem could get a reflex [1]. What limits it: approval pins an exact commit, a merge that proves wrong is one `git revert`, a reserved `⚠ SECURITY` marker exists, and entries that carry a true choice state the pick. Removing entries would lower the number of reflex answers without making the remaining ones read more carefully.

```
Decision: how gate merges and image releases are bundled and approved     top 4 of 6
 ID  Approach             Effort   Risk   Hard   Key downside
 [0] Status quo           ● none   ● low  4/4    always-[1] habit stays
 [2] A1, paths only       ◐ 1 day  ◐ l-m  4/4    buys nothing in this sample
 [3] A3                   ◐ 1 day  ● low  4/4    removes no ask or paste
 [5] Release as approval  ○ days   ○ high 4/4    a "no" blocks every release; review moves to skimmed notes
 Legend: ● strong/low  ◐ partial/medium  ○ weak/high
 Recommended: [0]. Evidence: T3, T1; A1 moves 0 of 22 safely; A3 removes nothing.
```

## 10. Decision

**[0], status quo (A10). Path A, 85%.** Nothing changes: not GATE_CODE, the floor, the entry form, the release entry or T3's presentation. [0] dominates because the alternatives do not deliver, not because the goal of fewer asks is wrong: the two briefed ones fail when tested against the sample, and the one that could deliver saves little without wide floor changes and trades away what the owner says they use, with no recent request for it. The owner's founding purpose counts for change and [5]'s smaller saving counts against it, so the two roughly offset. The remaining 15% is mostly that the owner might prefer [5] if shown it, which section 11 reopens on evidence rather than by spending an ask now.

See alternatives considered → below.

**Pruned candidates and why.** Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[1 A1 as written]: ⚠ H4, its "bug fix the brief pins down" class is a judgment a blocking gate would key on; without it, it is [2].` `[2 A1, paths only]: survived hard lines, lost in step 4, 0 of 22 safely moved.` `[3 A3]: survived hard lines, lost in step 4, removes no ask or paste; Q-251 and the release notes already cover the rest.` `[4 A2 built]: dominated by [0], T3 gives the same one-line answer with no gate change, and the owner says it is not a big blocker.` `[5 release as approval]: survived hard lines, lost in step 4 on motive, P2 and P4; kept as the named fallback.` `[6 silence is consent]: ⚠ H2, an absent verdict would land a merge.` `[7 sampled audit]: dominated by [5], ✗ P3 for unsampled merges, and the sample has no replies so far.` `[8 second agent signs]: ⚠ H4, an LLM verdict as the enforcement primitive.` `[9 approve the programme]: ✗ P3, approval cannot pin a commit not yet built; best case 9 entries to 1 for one audit.` `[10 behaviour corpus]: ✗ S3, S8, a second large mechanism, and SKILL.md prose is outside any replay.` `[12 fewer, larger units]: ✗ S8, against the ~400-line cap; ⚠ P4.` `[13 empty the gate list]: dominated by [5], ✗ P3, it keeps no approval point at all.` `Not competing: [11 short entries], the gloss brief holds its motive; [14 auto re-dispatch], 2 asks in the sample, a small gate change noted in section 12.` `Prior pruning grep: no matches found for [approval, self-merge, merge entr, release, owner ask].`

**Consequences.** Easier: no gate code moves, nothing to release, nothing to confirm. Harder: the always-[1] pattern stays visible in every digest, and this record has to be cited when B2's rule next fires.

## 11. The observable, and what reopens this

**What would show a change helped** (S6, for [5] or any later candidate). Two numbers read together from the weekly digest, over the 4 weeks before and after:

- merge-answer sittings per week (baseline: about 5), which should halve;
- deliberate looks per week (baseline: 0), which should rise above 0 if the aim is the Tension's trade.

**It came out negative if** sittings do not fall, because gate work still routes to the owner, or if they fall and a released gate change needs a fix within 7 days, or the owner reports not knowing about something that shipped. Falling sittings with zero deliberate looks is not a success: it means attention was removed, not moved.

The digest prints entry counts and sample replies today; sittings need one more count from the same answer lines.

**Revisit triggers.** Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

`if the owner names merge entries or approvals as a blocker. if merge entries exceed 11 a week in 3 of the next 4 digests, which reopens at [5]. if the median wait exceeds 48 hours for two weeks running with a Blocks: line naming waiting work. if an approved merge is reverted, which goes first to the entry's wording (B7), and then here. if a T5 sample reply is recorded, since the deliberate look then exists and [5]'s main objection weakens.`

Nothing here adds a stop or a chore. The cycle decides where the triggers are kept.

## 12. Notes for the cycle

Observations outside this brief's question. None is part of the pick, and none proposes a rule change here.

- **T1 reaches further than this decision.** `docs/dev-cycle.md` says reviewing the release entry is the check on self-merged scripts, including `install.sh`. T1 says the owner does not read those notes thoroughly. So that check is weaker than the file assumes, today, under any option. Whether that matters is the owner's call.
- **Four merge entries had no floor or never path:** Q-195, Q-198, Q-225 and Q-257 (11% of the sample), which reached the owner through `Policy: review` alone [observed against the current floor; each date's floor was not rebuilt]. This is what the brief-writing rule produces when paths are not known in advance (`else Policy: review`, SKILL.md step 8), and Q-198's brief also predates the self-merge policy. No saving is claimed.
- **One entry overstates the floor.** Q-220 says the floor would have refused `devcontainer-config/cc-exit-scan.sh`, but GATE_CODE and `truthrule` do not name it. The entry did have floor paths, its review files.
- **T3's answer rule is still open.** The trial doc says that if T3 is kept, the merge-answer rule should say batched answers count explicitly. T3 is kept, and the skill has no such text.
- **[14] is the cheapest idea left.** The worst waste in the sample was six asks for two branches after a conflict. Re-dispatching without asking would remove two of them; it is a small gate change for the roadmap, not this record.

## Other choices (one line each)

- **Where the record lives:** this file, as the brief's Paths: line requires.
- **Trigger-bound variant:** not used; the evidence is on the table, and ordinary revisit triggers cover what comes later.
- **`matrix-analysis` calibration:** skipped; [0] dominates and its cells are not the ones in dispute.

## Invariants

- Approval pins an exact commit: `--approved` takes the heading's SHA, so any bundling keeps that [observed].
- `--approved` accepts only the `merge-gate-` heading for gate paths, and a test holds the skill's copy of GATE_CODE to the lib's [observed].
- No new stops in the cycle (owner, 2026-10-20) [observed].

## Prior art

Q-103 and Q-149 set the current shape. Decision 040 and Q-251 removed owner steps by moving them to the cycle, the pattern a change here would follow. Log row 75 shows how a policy question is filed once.

## Gotchas

Failure-pattern grep: FP-012, FP-015, FP-028, FP-029, FP-079, FP-161

- Keywords `merge|release|approv|habituat`. All six are script-level bugs (merge-state handling, a tarball checksum, a dead link, a wiring merge). None concerns approval design, so none bears on this decision.
- B2's digest counter and this sample differ by a few entries because they use different windows.
- The brainstorm's "19 of 19" predates this count; use 37 of 37.
- Commit dates are Pacific and the offset changes on 11-01; waits were computed with offsets.

## Files read

Last verified: 2026-11-06

docs/working/briefs/2026-11-06-merge-friction-design.md
docs/working/brainstorm-2026-10-29-friction-and-engagement.md
docs/working/trials/2026-10-30-friction-engagement.md
docs/working/questions-archive.md
docs/working/questions.md
docs/working/weekly/2026-10-30.md
docs/working/weekly/2026-11-06.md
docs/working/cycles/cycle-2026-11-06.md
docs/dev-cycle.md
docs/roadmap.md
docs/decisions/log.md
docs/failure-patterns.md
docs/human-author/feedback-10-29-26.txt
docs/human-author/feedback-10-20-26.txt (untracked, in the main checkout)
docs/human-author/answers-10-16-26.txt
docs/human-author/answers-10-22-26.txt
docs/human-author/answers-10-28-26.txt
scripts/lib/dev-cycle-read.sh
scripts/build-loop.sh
skills/dev-cycle/SKILL.md
workflows/divergent-design.md
workflows/research-plan-implement.md
workflows/pr-prep.md
workflows/review-fix-loop.md

## Appendix A: the sample

"Brief" means no floor or never path: the entry came from the brief's `Policy: review` line alone. Every answer was `[1]`.

| Entry | Opened | Filed to answer recorded (hours) | Words | Why it reached the owner |
|---|---|---|---|---|
| Q-163 | 10-14 | 26.7 | 661 | gate code |
| Q-164 | 10-14 | 26.7 | 725 | gate code |
| Q-195 | 10-17 | 73.7 | 310 | brief |
| Q-197 | 10-17 | 73.6 | 450 | gate code |
| Q-198 | 10-17 | 73.6 | 293 | brief |
| Q-216 | 10-20 | 67.9 | 356 | floor: records |
| Q-217 | 10-20 | 185.6 | 600 | floor: a working doc only |
| Q-218 | 10-25 | 65.9 | 317 | floor: records |
| Q-219 | 10-25 | 65.7 | 502 | floor: workflows, records |
| Q-220 | 10-25 | 64.9 | 803 | floor: review files |
| Q-224 | 10-28 | 1.0 | 423 | gate code |
| Q-225 | 10-28 | 0.9 | 465 | brief |
| Q-228 | 10-29 | 17.6 | 566 | gate code |
| Q-229 | 10-29 | 1.4 | 456 | gate code |
| Q-230 | 10-29 | 1.4 | 480 | gate code |
| Q-231 | 10-29 | 1.2 | 581 | gate code (re-filed as Q-233) |
| Q-232 | 10-29 | 0.9 | 515 | floor: instruction file |
| Q-233 | 10-29 | 0.2 | 461 | gate code |
| Q-235 | 10-29 | 6.0 | 543 | gate code |
| Q-236 | 10-29 | 5.6 | 479 | floor: failure library |
| Q-237 | 10-29 | 5.5 | 466 | gate code |
| Q-239 | 10-30 | 18.2 | 474 | gate code |
| Q-240 | 10-30 | 18.1 | 479 | gate code |
| Q-241 | 10-30 | 8.2 | 347 | floor: a decision record |
| Q-242 | 10-31 | 21.6 | 556 | gate code |
| Q-243 | 11-01 | 1.4 | 636 | gate code (re-filed as Q-249) |
| Q-244 | 11-01 | 1.1 | 730 | floor: instruction files (re-filed as Q-248) |
| Q-245 | 11-01 | 1.0 | 729 | gate code |
| Q-248 | 11-01 | 1.7 | 348 | floor: instruction files |
| Q-249 | 11-01 | 1.6 | 405 | gate code |
| Q-250 | 11-02 | 9.8 | 586 | gate code |
| Q-251 | 11-02 | 28.6 | 537 | gate code |
| Q-253 | 11-03 | 54.1 | 583 | gate code |
| Q-257 | 11-05 | 3.1 | 383 | brief |
| Q-258 | 11-05 | 2.5 | 385 | floor: review files |
| Q-259 | 11-05 | 17.9 | 736 | gate code |
| Q-260 | 11-06 | 15.8 | 520 | gate code |
