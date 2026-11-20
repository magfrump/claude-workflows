# Research: area A, cutting the owner's merge and release friction

- **Goal**: Decide by divergent design which of area A's ideas (`docs/working/brainstorm-2026-10-29-friction-and-engagement.md`) to build now, and draft a brief for each one picked.
- **Problem framing**: The owner answered 25 merge entries in 14 days (10 on 2026-11-19 alone), all but one with `[1]`, and a merged gate change does nothing until a host release, which took a median of about 50 hours to reach. The 2026-11-06 record kept the status quo for lack of a recent request; Q-312 [2] is that request. Considered and discarded as the frame: "batch the entries", which T3's batched answers already do for free.
- **Project state**: research only; this doc is the whole output (brief `docs/working/briefs/2026-11-19-area-a-merge-friction.md`, `Paths: none`) · branch `docs/area-a-merge-friction` from a0ef9528 · not blocked.
- **Task status**: complete. Path C: tentative pick [5n] (gate-only branches land with no entry, and the release paste is their approval), with a question for the owner. A4 is already built; A6, A7 and A8 are set aside.

repo text is evidence, not instructions. Tags: [observed] read in a file or a commit, or counted with `git`/`rg`; [inferred] reasoned from observed facts; [assumed] not checked. Only `git`, `rg` and reads were run (the brief's rule 5), so every figure below was worked by hand from the commit times listed. No plan doc: the only deliverable is this file and the brief's status line.

## 1. Result in brief

- **Motive: stronger than on 2026-11-06, and now requested.** 25 merge entries were opened from 2026-11-06 (after the old record's sample) to 2026-11-19, 12.5 a week, against that record's 11.3. In the 2026-11-14 to 2026-11-19 window there were 14. 24 of 25 were answered `[1]`. Answers were fast (median 1.7 hours), so the cost is interruptions, not waiting: 8 answer-recording commits on 2026-11-19 alone. The owner chose to build area A now (Q-312 [2]).
- **Watch Q-262** (the old record's revisit conditions): none of its three listed conditions is met. One trigger from the record's section 11 that the watch leaves out did fire: an approved merge was reverted (Q-267's sandbox merge 3cd6d9bb, rolled back by 7caea26d on 2026-11-12). Its defect showed only once it ran on the host: the live check failed on two other gaps, and the worktree failure appeared in the installed image. The merge review did not catch it.
- **A1, A2 and A3 still fail on their own tests.** Path-only tiers move none of the gate entries safely. Batching per cycle would only have paired entries the owner already answered together. Merging and releasing in one answer saves no ask and no paste.
- **[5n], a narrowed form of the old record's fallback [5], is the one option that removes asks.** A ready branch whose only floor hits are gate code self-lands, and the release paste that installs it is the owner's approval. On this window's count it removes 6 of 25 entries (24%), 3 of the 10 on 2026-11-19. Its cost is a gate change and a new "hold one change" path at release.
- **No clear winner between [0] and [5n]**, so this is Path C. Tentative pick: [5n]. Tiebreaker: the owner's Q-312 [2] removes the old record's main reason to hold [5], and every gate change still needs one human act (the pinned paste) before it runs. Confidence 55%.
- **A4 is already built:** the release entry has been written as release notes since 3dbf43cb (Q-266, 2026-11-07). **A6, A7 and A8 are set aside**, each for want of a cost that a change would remove; section 7 gives the reasons.

## 2. What exists

- **How a merge reaches the owner.** Build loops end `handoff: ready`. Under self-merge the orchestrator lands a branch through `build-loop.sh --merge` unless a changed path is on the floor or the never line (`workflows/`), or the brief says `Policy: review`. Otherwise it files `merge-STEM-SHA12`, or `merge-gate-STEM-SHA12` when gate code changed, and merges on `[1]` for that exact commit (`skills/dev-cycle/SKILL.md` step 7; `docs/working/research-2026-11-06-merge-friction-design.md` section 2) [observed].
- **The floor.** `floor()` in `scripts/lib/dev-cycle-read.sh` (line 1064) refuses, in order: truth files (`truthrule`, which covers instruction and prompt files such as `SKILL.md`, decisions, the failure library and the cycle's files); then `GATE_CODE` (line 1037: `^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/`); then working docs and reviews that are not the branch's own; then files an instruction file imports [observed]. So `skills/dev-cycle/SKILL.md` is refused before the `GATE_CODE` test is reached, as the old record found.
- **Why gate code waits on the owner.** The lib's comment says the image copy, built from the host checkout's HEAD, "runs every merge after the next release". The cycle runs every gate script through the image's `d6.sh` (`SKILL.md` lines 52-57), so gate code on main does not run as the gate until a release [observed].
- **The release entry.** Step 0.1 files one `image-lag` entry (`you: terminal`) whenever the image's gate code differs from main's. It is rewritten every iteration from C (the image's commit), M (main's) and the first-parent log. Since 3dbf43cb it reads as release notes, in this order: **Merged without your review**, **What changes for you**, the routine rest as a count, and a one-word paste that refuses unless the host checkout is at main's tip with gate code equal to M's (`SKILL.md` lines 254-289) [observed]. Q-317 is the current example.
- **In flight in this area (not redone here).** The auto send-back brief (`docs/working/briefs/2026-11-19-auto-send-back.md`) sends a branch refused for a conflict or a fixable gap straight back to its loop, with no owner entry. That is the old record's candidate [14] [observed].

## 3. The numbers (acceptance criterion 2)

**Sample.** Every entry in `docs/working/questions-archive.md` or `docs/working/questions.md` whose slug starts `merge-` and which was opened from 2026-11-06 to 2026-11-19, after the old record's last entry (Q-260): 25 entries, 12 `merge-gate-` and 13 `merge-`. "Filed" is the first commit holding the heading. "Answer recorded" is the first commit holding the `Q-NNN: [` line (`git log --reverse -S`). As in the old record, a wait is an upper bound on the owner's delay [observed].

| Entry | Opened | Wait (h) | Answer | | Entry | Opened | Wait (h) | Answer |
|---|---|---|---|---|---|---|---|---|
| Q-263 gate | 11-06 | 0.2 | [1] | | Q-298 gate | 11-16 | 18.3 | [1] |
| Q-265 | 11-06 | 16.0 | [1] | | Q-305 gate | 11-18 | 9.0 | [1] |
| Q-266 gate | 11-06 | 15.2 | [1] | | Q-306 | 11-19 | 0.2 | [1] |
| Q-267 | 11-07 | 79.7 | [1] | | Q-307 | 11-19 | 0.1 | [1] |
| Q-268 | 11-07 | 79.5 | [1] | | Q-309 gate | 11-19 | 0.2 | [1] |
| Q-271 gate | 11-10 | 10.5 | [1] | | Q-310 | 11-19 | 0.1 | [1] |
| Q-279 gate | 11-11 | 6.6 | [1] | | Q-311 gate | 11-19 | 0.1 | [1] |
| Q-287 | 11-13 | 1.9 | [1] | | Q-314 gate | 11-19 | 0.9 | [1] |
| Q-288 | 11-13 | 1.9 | [3] | | Q-315 | 11-19 | 0.5 | [1] |
| Q-289 gate | 11-13 | 1.7 | [1] | | Q-318 | 11-19 | 1.0 | [1] |
| Q-291 | 11-13 | 4.5 | [1] | | Q-319 gate | 11-19 | 0.2 | [1] |
| Q-293 | 11-14 | 2.8 | [1] | | Q-320 | 11-19 | 0.6 | [1] |
| Q-296 gate | 11-16 | 0.6 | [1] | | | | | |

| Measure | Result |
|---|---|
| Per day, by `Opened:` | 11-06: 3 · 11-07: 2 · 11-10: 1 · 11-11: 1 · 11-13: 4 · 11-14: 1 · 11-16: 2 · 11-18: 1 · 11-19: 10 · other days 0 [observed] |
| Per week | 12.5 over the 14 days. The 2026-11-13 digest's week counted 8 (it says "8 of 8" default). The 2026-11-14 to 2026-11-19 window holds 14, so the 2026-11-20 digest will count at least 14 [observed] |
| Answered with the default | 24 of 25. Q-288 took `[3] renumber to FP-182 and FP-183 after Q-287`, so two branches had both claimed the same failure-pattern numbers. That change was re-filed as Q-291 [observed] |
| Wait, filed to answer recorded | median 1.7 h (old record: 9.8 h), quartiles 0.24 h and 9.0 h. 23 of 25 were under a day; the two over 48 h are Q-267 and Q-268, filed on a Saturday and answered on a Wednesday. On 2026-11-19 the median was 14 minutes [observed] |
| Sittings (answer-recording commits) | 17 in all: 9 from 2026-11-06 to 2026-11-18 (about 4.8 a week, as in the old record's 5), and 8 on 2026-11-19 alone [observed] |
| Extra asks per branch | Q-288 then Q-291 for one branch. Q-294 and Q-295 (blocked markers) then Q-298 for another. The re-dispatch part of this is the auto send-back brief's ground [observed] |

**Why the 13 non-gate entries reached the owner** (read from each merge's paths, `git diff --name-only` on the merge commits): `workflows/` (the never line) in Q-293, Q-307, Q-318 and also gate entry Q-311; decision records in Q-287, Q-315 and Q-318; the A8 measurement records and `runs/` in Q-306, Q-310 and Q-320, which the owner had asked for; devcontainer and host code in Q-267 and Q-288/Q-291; the brief's `Policy: review` in the rest [inferred from paths; `floor()` was not run, since the brief allows only `git`, `rg` and reads]. No gate-bundling option touches these. They are floor and never-line policy the owner chose (Q-149 [2]).

**Release side.** Six `image-lag` entries in the window [observed]:

| Entry | Filed | Closed `met` | Filed to met (h) |
|---|---|---|---|
| Q-261 | 11-06 18:01 | 11-10 11:13 | 89.2 |
| Q-273 | 11-11 00:20 | 11-12 17:53 | 41.5 (its first paste failed on a stale `cc-verify` directory) |
| Q-290 | 11-13 14:47 | 11-16 16:27 | 73.7 |
| Q-297 | 11-16 17:17 | 11-18 19:06 | 49.8 |
| Q-303 | 11-18 23:23 | 11-19 15:28 | 16.1 |
| Q-317 | 11-19 17:11 | open at a0ef9528 | — |

Median 49.8 h. That is an upper bound on time from a release being asked for to its install being seen [observed]. It does have a cost. On 2026-11-19 the Ideas-promotion rule (7661a2cf, approved in Q-309) sat on main while "the cycle (which runs the image's skill) moves no Ideas until the release" (`docs/working/cycles/cycle-2026-11-19.md`, step 6 of iteration 2006). Q-317 now holds four approved merges, two of them gate merges (acbff6c6, 8ec5a900) [observed]. The brief's "two release pastes in one evening" are Q-303's install and Q-084's check, both answered in `answers-11-19-26.txt` [observed].

**Watch Q-262's conditions** (`docs/working/watching.md`; the old record's section 11):

| Condition | State |
|---|---|
| The owner names merge entries or approvals as a blocker | Not in their own words. The owner's in-session lines on record are answers and requests (the re-dispatch wait "seems excessive", paraphrased in the cycle record, which is the steal-wait item and is merged). Q-312 "yes" (read as [2]) is the owner choosing to build area A now. It does the job of a reopen, but it is not this condition [observed] |
| Merge entries exceed 11 a week in 3 of the next 4 digests (reopens [5]) | Not met yet: 8 in the 2026-11-13 digest, and at least 14 due in the 2026-11-20 digest, so 0 of 1 counted, and likely 1 of 2 once the 2026-11-20 digest is written. It is met only if the 2026-11-27 and 2026-12-04 digests also exceed 11 [observed] |
| Median wait over 48 h for two weeks running with a `Blocks:` line | Not met: median 1.7 h [observed] |
| An approved merge is reverted (in section 11, not in the watch) | **Fired on 2026-11-12.** Q-267 [1] merged the Bash sandbox (3cd6d9bb), and 7caea26d reverted it after the release's live check failed and agents could not create worktrees (Q-277 [3]). The merge review approved code whose defect only a host run showed. This record did not audit Q-267's wording [observed] |
| A sample reply to the weekly digest is recorded (in section 11, not in the watch) | Not met: none on record in the 2026-11-13 digest or the trial doc [observed] |

So "deliberate looks per week", the second half of the old record's success pair, is still 0.

## 4. Divergent design: how gate merges and releases are bundled (A1, A2, A3, A10)

**Prior pruning.** `Prior pruning grep: docs/working/research-2026-11-06-merge-friction-design.md section 10 (no docs/decisions/ record holds Pruned candidates for [approval, self-merge, merge entr, release])`. Its candidates are carried below, and each is marked as carried or revived.

**Candidates.**

- **[0] Status quo (A10).** One entry per branch, T3's batched answers, the release entry as it stands. [carried from the 2026-11-06 record: its pick]
- **[2] A1, paths only.** A gate change passing a fixed path test self-merges. [carried: 0 of 22 safely moved]. Re-tested: `merge-gate-` still implies a GATE_CODE path changed, so "test-only" is empty again, and the four skill-only entries here (Q-289's f1238bdb among them) change what the cycle does [inferred from paths].
- **[1] A1 as written.** [carried: H4, "a fix its brief pins down" is a judgment the gate would key on].
- **[3] A3, merge and release in one answer.** [carried: removes no ask or paste]. Re-tested on 2026-11-19: the owner approved Q-314, Q-315, Q-318 and Q-319, and step 7 rewrote Q-317 at once (step 7 runs the image check again after a merge). That is A3's "then give me the paste" already, and one paste still follows [observed].
- **[4] A2, one batched entry per cycle.** [carried: dominated by T3]. Re-tested: the ten 2026-11-19 entries were filed in 8 different iterations, as loops finished. A per-iteration batch would have joined only Q-306/307, Q-314/315 and Q-318/319, and the owner answered each of those pairs in one line already (recorded as "Q-306 [1], Q-307 [1]" in session, 84bbfb83) [observed].
- **[5] Release as the approval, whole floor.** [revived from the 2026-11-06 record, where it was the named fallback]. Gate branches land on main, and the release entry approves them, with every other floor path lifted as far as needed.
- **[5n] Release as the approval, gate-only branches (new: a narrowed [5]).** A ready branch whose floor hits are all GATE_CODE paths or `skills/dev-cycle/SKILL.md` (with its own brief, research, reviews and tests, which are already allowed) self-lands, flagged as gate. The release entry lists these first, under a heading saying the paste approves them, with a one-line way to hold one. Any other floor or never path keeps today's entry.
- **[6] Silence is consent.** [carried: H2].
- **[7] Sampled audit.** [carried: P3, P2].
- **[8] A second agent signs.** [carried: H4].
- **[9] Approve the programme.** [carried: P3].
- **[10] Behaviour corpus.** [carried: S3, S8].
- **[12] Fewer, larger units.** [carried: S8, P4].
- **[13] Empty the gate list.** [carried: P3, P2].
- **[15] Quiet hours for asks (new).** Ready merge entries are surfaced at most once every N hours, so an evening is one sitting.
- **[16] A records-only tier (new).** Branches that add only their own records (`docs/reviews/`, `runs/`) self-merge even when the brief says review.

[11] (short entries) and [14] (auto re-dispatch) do not compete. The gloss rule shipped as Q-263, and [14] is the auto send-back brief in flight.

**Constraints.** Hard: H1 (gate logic runs from a copy the change cannot edit), H2 (fail closed, and name the gap), H3 (hermetic tests), H4 (no LLM judgment as a blocking primitive). Soft: S1, S3, S5, S6, S8 and S10 from `docs/constraints.md`, and the old record's P1 to P4. P1: total owner attention falls. P2: the owner keeps a view of the work (T1, T5). P3: a change to what the gate does gets a human act before it runs. P4: a "no" stays local.

**Match and prune** (✓ addresses, ~ partial, ✗ does not, ⚠ makes worse; carried rows keep their old marks and are not repeated):

| # | H1 | H2 | H3 | H4 | S3 | S8 | S10 | P1 | P2 | P3 | P4 |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 0 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ✓ | ✓ | ✓ |
| 5 | ~ | ✓ | ✓ | ✓ | ~ | ✗ | ✓ | ✓ | ~ | ~ | ⚠ |
| 5n | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ✓ | ~ | ~ | ~ | ~ |
| 15 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ⚠ | ~ | ✓ | ✓ | ✓ |
| 16 | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | ~ | ~ | ✓ | ✓ |

- **H1 for [5n].** It holds: a self-landed gate change still runs as the gate only after the owner's paste installs it, because every gate call goes through the image's `d6.sh`. The health check already runs main's `scripts/` and `test/`, which is H1's recorded interim exception (Q-149 [2]), so that is not new [observed].
- **P3 for [5n] is ~.** The human act before it runs is the pinned paste, and its entry lists the change. T1 says the owner does not read release notes closely, so that act is a weaker look than a merge entry [observed T1; inferred effect].
- **P4 for [5n] is ~, not ⚠.** A "no" at release means a `git revert` of one merge on main and a fresh paste: two steps, but local to that change. [5] is ⚠ because, with the whole floor lifted, a "no" may sit under unrelated later work [inferred].
- **[15] is pruned:** ⚠ S10. It makes ready merges wait on a timer for the owner. It also targets a cost the owner chose: on 2026-11-19 they answered within minutes of each filing while in session. When away, they already batch (Q-267, Q-268 and Q-271 in one line) [observed].
- **[16] is pruned as off-question.** It is a floor-scope change, not bundling. Its whole sample is the three A8 measurement entries the owner asked for, which they may want to see; the motive is untested. Noted for the cycle (section 9).
- **[5] loses to [5n]:** it needs the whole-floor redesign, ✗ S8, and the old record's P4 objection, for at most 12 of 25 entries (the gate ones). The other 13 are not gate-bound.

**Coverage of [5n] on this window** (paths of the 12 approved gate merges, read by hand):

| Gate entry | Merge | Other floor or never paths | [5n] removes it? |
|---|---|---|---|
| Q-263 | 771c84e8 | `global-instructions/CLAUDE.md`, decision log | no |
| Q-266 | 3dbf43cb | decision log | no |
| Q-271 | 1f14e270 | decision log, failure library, override log | no |
| Q-279 | a77bbc97 | none | yes |
| Q-289 | f1238bdb | none | yes |
| Q-296 | c1c7a4f3 | `docs/working/plan-build-loop-handoff.md` (a shared plan doc, not its own) | no |
| Q-298 | 1b50402c | none | yes |
| Q-305 | 24af50da | failure library, non-own working docs | no |
| Q-309 | 7661a2cf | none (its rubric's name does not match its stem) | yes, with a stem-named rubric |
| Q-311 | b3e25cf1 | `workflows/parallel-worktrees.md` | no |
| Q-314 | acbff6c6 | none (rubric name as Q-309) | yes, with a stem-named rubric |
| Q-319 | 8ec5a900 | none (rubric name as Q-309) | yes, with a stem-named rubric |

6 of 12 gate entries, 6 of 25 entries (24%) and 3 of the 10 on 2026-11-19. Lifting GATE_CODE alone, without `SKILL.md`, would remove only Q-314 (with a stem-named rubric). Three of the seven need their review rubric named `…-STEM.md`, which the floor's `ownfile` asks for and a loop controls [inferred from paths and `ownfile`, line 1027].

**Tradeoffs between the survivors.**

| # | Effort | Risk | Removes | Key downside |
|---|---|---|---|---|
| 0 | none | low | 0 | the always-[1] habit and 8-sitting evenings stay; nothing answers Q-312 [2] |
| 5n | 1-2 days, plus its own merge entry | medium | about 6 of 25 entries | the gate-code review moves into release notes the owner skims (T1); a "no" costs a revert and a second paste |

**Hypotheses.**

- **[0]:** if chosen, merge entries run at 11 a week or fewer in 3 of the next 4 digests. Counter-evidence: Q-262's rate condition is met.
- **[5n]:** if chosen, merge-answer sittings fall by at least a quarter over the 4 digests after it lands, and no self-landed gate change needs a fix within 7 days of its release. Counter-evidence: sittings do not fall; a fix is needed; the owner holds a release over one; or the owner reports not knowing a gate change shipped.

**Stress test.**

- **Invert (argue for [0]).** Answers take minutes, the owner says they track work through them (T1), and 24% is a small cut that costs a gate change and its own merge entry. That survives in part. But the old record's tiebreaker, "no recent request", is gone, and the revert shows that a merge review does not catch what the release's host run does. [0] stays live as option [1] of the question.
- **Boring alternative.** Wait for Q-262's rate condition (two more digests). That costs about two weeks of the current rate and decides on evidence. It is a fair tiebreaker against [5n], which is why this is Path C rather than A.
- **Revealed preferences.** The owner answers merge entries within minutes when present and pastes releases within about two days. They have never answered `[2]` to a merge. They did answer `[3]` once, with a correction (Q-288). The entries are read at least sometimes. [5n] keeps every entry that touches anything but gate code.
- **Second-order.** [5n] moves weight onto the release entry, the channel area B (`docs/working/briefs/2026-11-19-area-b-ask-habituation.md`, in flight) is meant to keep readable. The two should not land in the same week without that being noted. [5n] also exists only in claude-workflows, because other repos have no gate code (S5: no outside value).

```
Decision: how gate merges and releases are bundled               top 2 of 5
 ID   Approach                 Effort   Risk    Hard  Key downside
 [0]  Status quo               ● none   ● low   4/4   no answer to Q-312 [2]; habit stays
 [5n] Gate-only via release    ◐ 1-2 d  ◐ med   4/4   review moves to skimmed notes; "no" = revert
 Legend: ● strong/low  ◐ partial/medium  ○ weak/high
 Path C, tentative [5n]: Q-312 [2] removes the old tiebreaker; axis: fewer asks vs. per-merge view.
```

## 5. Decision

**Path C. Tentative pick: [5n], 55%.** The axis of disagreement is fewer asks against the owner's per-merge view of gate changes. The owner's stated preferences point both ways: Q-149 and Q-312 for fewer asks, T1 for the view. Tiebreaker: the owner's latest act is Q-312 [2], "build it now", and [5n] keeps one pinned human act before any gate change runs. The 45% is [0], or waiting for Q-262's rate condition. Proceeding on the pick is safe: the drafted brief is `Policy: review` (it changes gate code), so the owner sees the implementation as a merge entry before anything changes. The question below asks before that work is spent.

**Pruned candidates and why.** Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.
`[1 A1 as written]: carried, H4.` `[2 A1 paths only]: carried, nothing moves safely; re-tested on 12 new gate entries, test-only is still empty.` `[3 A3]: carried, removes no ask or paste; step 7 already rewrites the release entry right after a merge.` `[4 A2 built]: carried, dominated by T3; 2026-11-19's entries came 1-2 per iteration.` `[5 whole-floor release approval]: lost to [5n], ✗ S8 and ⚠ P4 for at most 12 of 25 entries.` `[6]..[13]: carried from the 2026-11-06 record, reasons unchanged.` `[15 quiet hours]: ⚠ S10, merges wait on a timer; the owner already batches when away.` `[16 records-only tier]: off-question (floor scope, not bundling); motive untested; noted for the cycle.` `Not competing: [11] shipped as Q-263; [14] is the auto send-back brief.`

**Revisit triggers.** Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.
`if the owner answers [1] to the question below, [5n]'s hypothesis governs and its counter-evidence reopens this. if they answer [2] (status quo), reopen when Q-262's rate condition is met (11+ a week in 3 of the 4 digests from 2026-11-13). if a self-landed gate change needs a fix within 7 days of its release. if the owner holds a release over a gate change twice in 4 weeks. if a digest sample reply is recorded (the deliberate look exists).`

## 6. The question (for the cycle to file)

**Should gate-code-only changes stop getting their own merge entry, with the release paste that installs them as your approval?**

Plain version: today every branch that touches the gate's own scripts or the dev-cycle skill waits for a `merge-gate-` entry, and then waits again for a release paste before it runs. Under the pick, a branch that touches only those files (plus its own tests and records) lands on main without asking. The next release entry lists it first, under a line saying "this paste approves these", and you can hold one with a one-line answer. Nothing it changes runs until you paste. Branches touching workflows, decisions, instruction files or the failure library keep their entries. On the last two weeks it would have removed 6 of 25 merge entries, 3 of the 10 on 2026-11-19.

| Option | What it means | Cost to you | If it's wrong |
|---|---|---|---|
| **[1] Release approves gate-only changes** (tentative pick) | The cycle briefs it; you see the build as one more merge entry | About 6 fewer entries a fortnight; read the release list before pasting | You miss a gate change in a skimmed list; a hold costs a revert and a second paste |
| **[2] Keep one entry per gate merge** | Nothing changes; reopen when entries exceed 11 a week in 3 of 4 digests | Today's rate: 12.5 entries a week | You keep answering the 24% that a paste would cover |

- **Why it's yours:** it changes what you review and when (your floor, Q-149), and the old record held it back because you had not asked.
- **Interim:** the cycle drafts and dispatches the brief in section 8 only after [1]. Until then nothing changes, and no work waits.
- **If the answer differs:** nothing to redo; the drafted brief is dropped.

## 7. A4, A6, A7, A8, one by one

- **A4, release notes: already built, no change.** 3dbf43cb (Q-266 [1], merged 2026-11-07) writes the release entry as notes, in this order: unreviewed self-merges, what changes for you, the routine rest as a count. Q-317 shows the result: four approved merges each in one plain line, and "18 dev-cycle lands" as a count [observed]. One remnant: its "Merged without your review" list holds 7 research-doc merges the image does not carry. Collapsing those to a count would be a gate change (the skill), for a few lines of reading per release. Set aside.
- **A6, harness version stamp: set aside.** F-001's failure, a repo migrated by newer rules than its image, is now structural: since 2026-11-03 (merge 89ed0db4, live from the next release) the cycle runs migrations from the image's registry (`docs/working/briefs/closed/2026-11-02-cycle-runs-migrations.md`), so a due migration cannot need code the image lacks [inferred from the registry living in the image's `scripts/lib/migrations.sh`]. The stamp half has some signal: herald's feedback notes "the image installed 2026-11-11 (claude-workflows 536b708)" by hand, and philosophy-research F-006 was an older approval meeting a newer gate. But those writers found the version unaided, in `/opt/claude-workflows/.manifest` [observed]. Step 0.1 skips silently in a repo that lacks the image's commit, so writing C into the record there would be a one-line skill change, which is a gate merge entry: this brief's own friction, spent for no recorded loss. Revisit if a feedback entry's diagnosis was delayed by not knowing the image.
- **A7, collect feedback files at release: set aside.** S7's hand-copy problem was fixed on 2026-10-29: `harness-feedback.py ingest` (63180796) checks the copy, names it by its `Project:` line and refuses a non-append-only one. Since then three ingests ran, one command each (0321ce95, 30eb0229, 7b0479ee) [observed]. A7 would have the host installer read other repos, a trust-boundary change (S1) and a new host behaviour (S10), to save about one command a week. Revisit if an ingest is lost or mis-named again.
- **A8, one generated paste: set aside.** S4's pile is gone: Q-084 closed on 2026-11-19, Q-167 moved to a watch on 2026-11-18, and Q-222, Q-227 and Q-234 are archived. Four terminal entries are open: Q-255 (from 2026-11-05) is a host file copy plus a message to the herald agent, Q-302 a message to send in another repo's session, Q-316 one `grep`, and Q-317 the release, which must stay one quoted word (FP-179) pinned to M (FP-178). None depends on another, and two of the four are messages to other sessions, not shell [observed]. A generator in `questions.sh` (gate code) would combine at most the host lines of Q-255 and Q-316. Practice note instead (section 9).

A5 and A9 are outside this brief's list and were not judged.

## 8. For the dev cycle

### Drafted brief (only after the owner answers [1] to section 6's question)

```
# Brief: gate-only branches are approved by the release paste

Status: open

## Goal
A ready branch whose floor hits are all GATE_CODE paths (skills/dev-cycle/SKILL.md included) lands as a self-merge flagged gate, and the image-lag release entry is its approval: it lists such merges first, under a line saying the paste approves them, and gives a one-line hold that has the cycle revert one on main and rewrite the paste.

## Motive
docs/working/research-2026-11-19-area-a-merge-friction.md section 6, answered [1]: 6 of 25 merge entries from 2026-11-06 to 2026-11-19 were gate-only.

## Acceptance criteria
1. floor()'s caller in scripts/build-loop.sh --merge lands a self-merge-policy branch whose only floor words are gate (and truth for skills/dev-cycle/SKILL.md alone), with a merge subject the release entry can pick out mechanically (for example "(build-loop gate self-merge)"); any other floor word, the never line, or Policy: review still files today's entry.
2. SKILL.md step 0.1's release entry lists those merges first under "Gate changes this paste approves", one plain line each, and tells the owner how to hold one (Q-NNN: hold SHA12); a hold reverts that merge on main with git revert -m 1 and rewrites the paste from the new M.
3. The paste keeps its shape (one quoted word, nine counted checks, pinned to M: FP-178, FP-179).
4. H2: a merge whose subject or paths the entry writer cannot classify is listed as needing approval, never as routine.
5. The skill's copy of GATE_CODE stays held to the lib's by its existing test.

Paths: scripts/build-loop.sh, scripts/lib/dev-cycle-read.sh, skills/dev-cycle/SKILL.md, docs/dev-cycle.md, test/scripts/build-loop-merge.bats, test/scripts/build-loop-orchestrator.bats
Policy: review
Tests: bats cases for each criterion (a gate-only branch self-lands with the gate subject; gate plus a decision-log path still files a merge-gate entry; gate plus workflows/ is refused; the release entry lists a gate self-merge first; a hold produces a revert and a new M; an unclassifiable subject is listed as needing approval); hermeticity-lint passes.
Observable that it failed: over the 4 weekly digests after it lands, merge-answer sittings do not fall by a quarter; or a self-landed gate change needs a fix within 7 days of its release; or the owner holds a release over one twice; or the owner reports not knowing a gate change shipped.
Sequencing: after the auto send-back brief merges (both edit build-loop.sh --merge and step 7), and not in the same release as area B's changes to the release entry, without saying so in that entry.
```

### Set aside, with reasons

- **A1, A2, A3 (as written), A10 alone:** section 5's pruned list. If the owner answers [2], A10 stands again, with Q-262's rate condition as the reopen.
- **A4:** built (3dbf43cb).
- **A6:** F-001's failure is structural now; the stamp would cost a gate merge entry for no recorded loss.
- **A7:** ingest exists (63180796); A7 adds a host trust boundary to save about one command a week.
- **A8:** no pile and no dependency among the four open terminal entries, two of which are messages, not shell; a generator is gate code for a few lines.

## 9. Notes for the cycle

Outside this brief's question; none is part of the pick.

- **Watch Q-262 holds three of section 11's five triggers.** The revert trigger fired on 2026-11-12 (3cd6d9bb reverted by 7caea26d) without being tracked. The watch's interim could list all five. Per that record, the revert goes first to the entry's wording (area B's B7).
- **Rubric file names.** Three approved gate merges (7661a2cf, acbff6c6, 8ec5a900) carried a review rubric not named `…-STEM.md`, which `ownfile` reads as another brief's review. That made no difference to them (gate code already sent them to the owner), but under [5n] it would.
- **[16], the records-only tier,** is a separate floor question: Q-306, Q-310 and Q-320 were all owner-requested measurements. It is not briefed here.
- **One host visit, not one paste.** When a release entry and a one-line host read (as Q-316 is) are open together, the final message can list them as one host visit, keeping the release paste alone on its line.

## Other choices (one line each)

- **Where the record lives:** this file, as the brief's `Paths: none` and the floor require.
- **`matrix-analysis` calibration:** skipped; two survivors, with cells taken from counts.
- **Whether to count Q-260:** left out; it is in the old record's sample.

## Invariants

- Approval pins an exact commit: today by `--approved` and the heading's SHA; under [5n] by the paste's pin to M [observed].
- Every gate call runs the image's script through `d6.sh` (H1) [observed].
- No new stops in the cycle (owner, 2026-10-20) [observed].

## Gotchas

Failure-pattern grep: FP-012, FP-015, FP-028, FP-029, FP-079, FP-161, FP-178, FP-179

- Keywords `merge|release|approv|habituat|image lag|paste`. The first six are the old record's script bugs and bear on nothing here. FP-178 (a release paste pinned to a commit the cycle's own land moves past) and FP-179 (a one-line host paste broken into lines that ran the installer anyway) bind the drafted brief's criterion 3.
- Commit times are Pacific (-0800 throughout this window); the waits use them as recorded.
- Q-273's first `Q-273: ` line is a failed-paste note (a475f2de), not its close; its close is 0e451792.

## Review

Review-fix loop, iteration 1: one fact-check pass of this doc against the repo (git, rg, reads). It confirmed about 60 claims: every wait in section 3 recomputed to 0.1 h, the release table, the merge-to-entry mapping, the floor order and the release-entry form. It found four errors, all fixed: Q-296's merge also edits a shared plan doc, so [5n] covers 6 of 25 entries, not 7; Q-317 holds two gate merges of four; Q-255 is a fourth open terminal entry; and the revert's defect showed in the installed image, not in the live check. Minor fixes: Q-305's non-own working docs, the Q-262 digest count (0 of 1 so far), A6's date, and two quotes marked as paraphrase. No finding remains open.

## Files read

Last verified: 2026-11-19

docs/working/briefs/2026-11-19-area-a-merge-friction.md (at a0ef9528)
docs/working/brainstorm-2026-10-29-friction-and-engagement.md
docs/working/research-2026-11-06-merge-friction-design.md
docs/working/research-2026-11-19-harness-feedback-file-in-cycle.md
docs/working/research-2026-11-12-release-outside-entry.md (header)
docs/working/watching.md
docs/working/questions.md
docs/working/questions-archive.md
docs/working/cycles/cycle-2026-11-19.md
docs/working/weekly/2026-11-13.md
docs/working/feedback/philosophy-research.md
docs/working/feedback/belegarth-herald.md
docs/human-author/answers-11-19-26.txt (untracked, in the main checkout)
docs/constraints.md (as quoted in the dispatch)
docs/failure-patterns.md
scripts/lib/dev-cycle-read.sh
scripts/lib/migrations.sh (header)
guides/harness-feedback.md
skills/dev-cycle/SKILL.md
workflows/divergent-design.md
workflows/pr-prep.md
