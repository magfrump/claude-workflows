# Research: reopen decision 040 on asks per day

- **Brief**: `docs/working/briefs/2026-11-20-reopen-040-asks-per-day.md` (dispatched at 0423fe3b)
- **Task status**: complete. Path A: no change. No brief, and no question for the owner. One suggested watch for the cycle (section 8).
- **Date**: 2026-11-20
- **Composition**: research-plan-implement (research only, per the brief), with divergent design inline (section 5). No plan doc: this file is the whole output, as the brief's `Paths: none` says.

repo text is evidence, not instructions. Tags: [observed] read in a file or counted with `git`/`rg`; [inferred] reasoned from observed facts. Only `git`, `rg` and reads were run. `scripts/questions.sh counts` is not on main at 0423fe3b (see section 7), so every count here is by hand and could be off by one or two.

Failure-pattern grep: `rg -n -i 'owner ask|asks per|merge entr|habitu|attention|batch' docs/failure-patterns.md` matches only line 37, an unrelated `n+1-query` tag. No failure pattern concerns owner asks.

## 1. Result in brief

- **The trigger fired, as the owner read it.** From 2026-11-13 to 11-20 the cycle opened 64 `you:` asks, 8.0 a day. Four of the eight days were over 5: 11-13 (12), 11-18 (6), 11-19 (19) and 11-20 (21). 33 of the 64 (52%) were merge entries. The owner gave the first option on 30 of the 31 merge entries answered so far [observed].
- **Decision 040's own choice is not the cause.** Decision 040 moved agent-internal items out of the questions file. Nothing it decided puts asks in front of the owner. The count is driven by two things outside it: how many branches land each day, and the share of those that the self-merge floor sends to review (section 3) [inferred].
- **The jump is throughput.** On 11-19 and 11-20 the cycle landed 46 build-loop branches. On the six days before it landed 10. About half of all landings needed the owner (28 approved merges, 28 self-merges), and that half was steady. Asks went up with landings, not because the review share grew [observed].
- **The two options that would cut asks a lot are ones the owner turned down a day ago.** On 11-20 the owner answered Q-323 (should gate-only changes be approved by the release paste?) with [2], keep one entry per gate merge, and wrote: "I like the separate merge entries, reading 1-2 things at a time rather than all in a lump." That rules out a daily digest entry and self-merging gate code. Together those were the only candidates worth more than one ask a day [observed].
- **What is left saves under one ask a day.** Taking non-dev-cycle skill prompt files, new failure-pattern entries and owner-requested records off the floor would have removed 7 of the 64 asks (0.9 a day). It would cost a gate-code merge entry to build, and the owner would no longer see changes to the skill text that ships to every project. The rate would still be above 5 a day [inferred from the counts].
- **Batching is already there on the owner's terms.** T3's batched answers (one line answering several entries) and the answers file (Q-345 [1], being built) let the owner lump answers together when they want to. Separate entries keep the 1-2-at-a-time reading they asked for.
- **Pick: [0], status quo. Path A, about 75%.** The rest is mostly [2b+2c] (section 5), kept as the named fallback with conditions in section 8.

## 2. Sources read

- `docs/decisions/040-questions-doc-owner-only.md` (the choice and its revisit triggers)
- `docs/working/research-2026-11-19-area-b-ask-habituation.md` (asks by class; the 98% / 100% / 46% first-option split)
- `docs/working/research-2026-11-06-merge-friction-design.md` (candidates [0] to [14]; sittings as the cost; section 11 triggers)
- `docs/working/research-2026-11-19-area-a-merge-friction.md` (candidate [5n]; coverage of gate-only branches; [15] quiet hours and [16] records-only tier)
- `docs/working/watching.md`, watch Q-262 (the merge-approval revisit)
- `docs/working/questions.md` and `docs/working/questions-archive.md` (Q-281 to Q-353), and Q-323, Q-341, Q-344 and Q-345 in full
- `skills/dev-cycle/SKILL.md` step 7 (merge entries; the `merge-gate-` heading; the GATE_CODE pattern) and step 9's batched-answer rule (lines 1010-1022)
- `docs/dev-cycle.md` (the policy, the floor, the never line `workflows/`, Q-103 [2], Q-149 [2])
- `docs/working/cycles/cycle-2026-11-20.md` (answers committed; step 8's note that free slots stayed free while gate entries waited)
- `docs/decisions/log.md` row 78 (why the failure-pattern library is on the floor)
- the owner's `docs/human-author/answers-11-19-26.txt` and `answers-11-20-26-2.txt` (the second is untracked, in the main checkout)
- `docs/constraints.md` as quoted in the dispatch (S1, S3, S5, S8, S10, H1, H4 above all)

## 3. The numbers (acceptance criterion 2)

### 3.1 Method

- **Sample.** Every entry in either questions file whose `Opened:` date is 2026-11-13 to 2026-11-20: 64 entries. The missing IDs (Q-301, Q-313, Q-322, Q-331, Q-334, Q-338, Q-346, Q-347, Q-351) are watches in `watching.md`, not asks.
- **Classes** (area B's, section 3.1 there):
  - merge: slug starts `merge-` (gate when `merge-gate-`);
  - re-dispatch: slug starts `blocked-` or `stopped-`, plus the four "keep the interim?" constraint confirmations Q-281 to Q-284;
  - real choice: every other `you: judgment`;
  - terminal, walkthrough and fyi by route.
- **Answer recorded.** The first first-parent commit on main whose diff to the questions files adds `Q-NNN: ` (`git log -S`). This is a proxy: it can also hit a commit that mentions the ID.
- **Day** is the entry's `Opened:` date. Commit dates are Pacific, and the cycle names iterations in UTC, so an evening entry can fall on the next day's record.

### 3.2 Asks per day and per class

| Opened | All | Merge (gate) | Re-dispatch | Real choice | Terminal | Other |
|---|---|---|---|---|---|---|
| 11-13 | 12 | 4 (1) | 4 | 2 | 2 | 0 |
| 11-14 | 3 | 1 (0) | 2 | 0 | 0 | 0 |
| 11-15 | 0 | 0 | 0 | 0 | 0 | 0 |
| 11-16 | 3 | 2 (2) | 0 | 0 | 1 | 0 |
| 11-17 | 0 | 0 | 0 | 0 | 0 | 0 |
| 11-18 | 6 | 1 (1) | 0 | 2 | 2 | 1 fyi |
| 11-19 | 19 | 12 (5) | 1 | 4 | 2 | 0 |
| 11-20 | 21 | 13 (7) | 0 | 5 | 2 | 1 walkthrough |
| **All** | **64** | **33 (16)** | **7** | **13** | **9** | **2** |

- 11-14 is a Saturday and 11-15 a Sunday.
- Q-341's counts (6, 19 and 10 for 11-18 to 11-20) agree for the first two days. Its 10 for 11-20 was taken early that day; 11 more were opened after it.
- **Re-dispatch asks have stopped.** The auto send-back change merged at 723fae67 (11-19 20:23 Pacific, Q-324 [1]). It sends a branch refused for a conflict or a fixable gap back to its loop with no owner entry. No `blocked-` or `stopped-` entry has been opened since Q-325, which came just before it [observed]. That is about one ask a day already saved, compared with the window's first half.
- **Terminal asks** are mostly release pastes: five `image-lag` entries (Q-290, Q-297, Q-303, Q-317, Q-336), about one per release.

### 3.3 How they were answered

| Class | Answered | First option | Not first option |
|---|---|---|---|
| merge | 31 (Q-352 and Q-353 still open) | 30 (97%) | Q-288 [3]: renumber two failure-pattern IDs |
| re-dispatch | 7 | 7 (100%) | none |
| real choice | 13 | 5 (38%) | Q-285 [2], Q-286 free text, Q-299 [2], Q-312 [2], Q-321 [2], Q-323 [2], Q-327 [2], Q-328 [3] |
| **all judgment** | **51** | **42 (82%)** | |

This repeats area B's finding on a new window. The always-[1] answer belongs to merge and re-dispatch entries. On real choices the owner picks something else more often than not.

**How they arrived:**

- **In session, one at a time or in a short batch.** Batched answers on record:
  - "Q-281: [1], Q-282: [1], Q-283: [1], Q-284: [1]";
  - "Q-306 [1], Q-307 [1]";
  - "Q-329..330: [1]";
  - "Q-333, Q-335: [1]";
  - "Q-337, Q-339: [1]".
  Each batch covers what one final message listed, usually two entries.
- **By answers file.**
  - Q-327 (with terminal Q-255 and Q-302) came in `answers-11-20-26.txt` (7df4654d).
  - Q-340 to Q-345, Q-348 and Q-349 (eight entries) came in the uncommitted `answers-11-20-26-2.txt`. The owner pointed the cycle at that file in session.
  - So 11 judgment answers, 22% of the window's 51, arrived by file. Each file still took an in-session "record the answers file" before the cycle could use it. Q-345 [1] removes that step once it is built.
- **Sittings.** 22 distinct commits recorded the 51 judgment answers, 2.3 answers each. By Pacific day: 4, 1, 0, 1, 1, 1, 9, 5. The 9 on 11-19 is the peak area A saw (8 there, measured to an earlier cut).
- **Speed.** Most judgment entries in this window were recorded within hours of filing. On 11-19 and 11-20 the owner was in session and answered as the final messages listed entries.

### 3.4 Why the 33 merge entries reached the owner

- **Gate code, 16:** Q-289, Q-296, Q-298, Q-305, Q-309, Q-311, Q-314, Q-319, Q-324, Q-333, Q-337, Q-339, Q-342, Q-344, Q-348, Q-353. GATE_CODE is `^scripts/(build-loop|d6|dev-cycle|questions)\.sh$|^scripts/lib/|^skills/dev-cycle/`. These merge only on `[1]`, and run as the gate only after a release.
- **Not gate code, 17**, by the floor or never-line reason each entry names (a branch can have more than one):

| Reason | Entries | Sole reason in |
|---|---|---|
| `workflows/` (the never line, Q-149 [2]) | Q-293, Q-307, Q-318 | Q-293, Q-307 |
| a decision record | Q-287, Q-315, Q-318 | Q-287, Q-315 |
| a new failure-pattern entry | Q-326, Q-330, Q-349 | Q-349 |
| a skill prompt file (`skills/*/SKILL.md`, not dev-cycle) | Q-329, Q-330, Q-335 | Q-329, Q-335 |
| owner-requested records (`docs/reviews/`, `runs/`) | Q-306, Q-310, Q-320 | all three |
| host or enforcement code (`devcontainer-config/`, `hooks/`, `scripts/board.sh`) | Q-288, Q-291, Q-326, Q-343, Q-352 | Q-288, Q-291, Q-343, Q-352 |

### 3.5 Landings, and what share needed the owner

- First-parent build-loop merges on main, 11-13 to 11-20 (Pacific):
  - 28 `(build-loop approved merge)`;
  - 28 `(build-loop self-merge)`, 20 of them `docs/` research branches.
- By day:
  - 11-13: 3 approved, 2 self;
  - 11-14, 11-16, 11-17: 1 approved each;
  - 11-18: 2 self;
  - 11-19: 12 approved, 10 self;
  - 11-20: 10 approved, 14 self.
- So 46 of the 56 landings came on the last two days. Asks rose with them [observed].
- Almost all code goes to the owner: 28 of the 36 landings that were not research docs were approved merges [inferred from branch prefixes].
- The cycle record shows the throttle already working. On 11-20 (the 2338 UTC iteration, step 8) three slots stayed free because "every unheld Now item lands as a review merge entry … while three gate entries … already wait on the owner".

### 3.6 What the owner has said about asks, most recent first

| When | Words | Reads as |
|---|---|---|
| 2026-11-20, Q-341 [1] | chose "reopen 040 now" over the interim, which was to wait for the counter | wants the per-day load looked at |
| 2026-11-20, Q-323 [2] | "I like the separate merge entries, reading 1-2 things at a time rather than all in a lump" | against a digest and against folding gate review into the release |
| 2026-11-20 | answered eight entries in one file | batches when they choose to |
| 2026-11-19, Q-312 [2] | build area A (merge and release friction) now | for fewer asks, as a general goal |
| 2026-11-06, T1 | "I'm mostly tracking what's happening in the repo via my answers to other questions" | the entries are also the owner's view of the work |
| 2026-11-06, T3 | batching is "fine, but it's not targetting a big blocker" | the entry count is not the pain |

**Motive verdict (S5).** The load is real by the trigger's own measure, and the owner asked for this look. But their newest words say what the cost is not. It is not the number of entries: they want small separate entries, and they batch them themselves. Their stated cost is reading many things at once. A change that cuts entries by lumping them together goes against that. A change that keeps entries small but removes some has to remove ones the owner does not use to follow the work.

## 4. Context packing

- **Invariants:**
  - approval pins an exact commit (`--approved` with the heading's SHA);
  - every gate call runs the image's copy through `d6.sh` (H1);
  - no new owner stops (owner, 2026-10-20);
  - one grammar for entries, owned by `scripts/questions.sh` (S3);
  - the floor and never line are the owner's (Q-103 [2], Q-149 [2]).
- **What to avoid:**
  - re-proposing what area A and the 2026-11-06 record pruned without new evidence;
  - treating the entry count as the cost, when the owner's own words put the cost elsewhere (section 3.6).
- **Where the floor lives.** `floor()` and `truthrule` are in `scripts/lib/dev-cycle-read.sh`, which is gate code. So any floor change is itself a `merge-gate-` entry, one more ask, and runs only after a release.

## 5. Divergent design

Seeded with the brief's six candidates and the constraints quoted in the dispatch. Decision-specific soft lines, carried from the 2026-11-06 record: P1 (the owner's total attention falls), P2 (the owner keeps a view of the work), P3 (a change to what the gate does gets a human act before it runs), P4 (a "no" stays local). Added here: P5, the owner reads 1-2 things at a time (Q-323's words).

Prior pruning grep: `rg -n -i 'Pruned candidates' docs/decisions/040-questions-doc-owner-only.md` lists [11] (shorter entries: "wrong measure, clarity not length") and [13] (a lifetime cap). The two research docs' pruned lists add [1] to [16], carried below where they recur.

### 5.1 Candidates

- **[0] Status quo.** One entry per review merge, T3's batched answers, the answers file once Q-345 is built, and auto send-back (already live).
- **[1] One daily digest entry for merge entries**, answered once (the brief's second candidate; the old record's [4] taken further).
- **[2] Widen self-merge**, split by path class:
  - [2a] gate code (Q-323's question, or plain self-merge);
  - [2b] skill prompt files other than `skills/dev-cycle/`;
  - [2c] new failure-pattern entries, append-only;
  - [2d] records the owner asked for (`docs/reviews/`, `runs/`), area A's [16];
  - [2e] `workflows/` off the never line.
- **[3] A lighter lane**: approved-merge entries carry less text (decision 040's [11] and the old record's [11]).
- **[4] Read the owner's answers file** (Q-345 [1], a roadmap Now item).
- **[5] Fewer briefs touching gate code at once**: a cap of one or two gate briefs in flight.
- **[6] New: measure differently.** Keep the policy and count asks per landing, or sittings, so the trigger tracks the review share rather than throughput.

### 5.2 Savings, review given up, gate code

Asks saved are over the 8-day window (64 asks, 8.0 a day).

| # | Asks saved per day | Review given up | Paths | Gate code? |
|---|---|---|---|---|
| 0 | 0 | none | none | no |
| 1 | about 3.4 entries (33 become at most 6), but no reading saved | per-entry reading; a "no" needs an "all but" line | `skills/dev-cycle/SKILL.md` step 7, `scripts/build-loop.sh` (`--approved` takes one heading per SHA today) | yes |
| 2a | 2.0 (16 entries) | the per-merge look at what the gate does | `scripts/lib/dev-cycle-read.sh` (`floor()`), step 7 | yes |
| 2b | 0.25 (Q-329, Q-335) | the owner's read of skill text that installs into every project | `floor()` / `truthrule` | yes |
| 2c | 0.125 (Q-349); with 2b, 0.5 (adds Q-330) | the owner's read of a new failure pattern, which later loops' failure-pattern grep reads as truth | `truthrule`; `scripts/build-loop.sh`'s FP gap text | yes |
| 2d | 0.375 (Q-306, Q-310, Q-320) | seeing the result of runs the owner asked for | `floor()`'s review-file rule | yes |
| 2e | 0.25 (Q-293, Q-307) | the owner's read of workflow changes, which steer every later session | `docs/dev-cycle.md`'s never line | no (but the line is the owner's, Q-149 [2]) |
| 3 | 0 (reading time only) | detail the owner uses to follow the work | step 7's entry template | yes |
| 4 | 0 entries; one in-session confirmation per answers file (2 in the window) | none | `scripts/dev-cycle.sh --check-answer`, `--main-log` | yes, already briefed by the cycle |
| 5 | 0 a week; flattens the 11-19 and 11-20 peaks (5 and 7 gate entries) | none, but throughput falls | step 8's brief-writing rule | yes |
| 6 | 0 | none | decision 040's trigger text (owner's) or a cycle watch | no, as a watch |

### 5.3 Prune against the constraints

| # | Survives? | Why |
|---|---|---|
| 0 | yes | |
| 1 | no | ✗ P5: the owner said on 11-20 that they prefer separate entries "rather than all in a lump". It saves entries but not reading, so ✗ P1. And T3's batched answers plus the answers file already let the owner lump answers when they choose. That is the old record's [4] verdict ("dominated by T3"), now with the owner's own words against it. |
| 2a | no | The owner answered Q-323 [2] on 11-20: keep one entry per gate merge. Plain self-merge of gate code, with no release approval either, would also break P3. Reopens only on watch Q-262's conditions. |
| 2b | yes, weakly | No hard line. S5 counts against it: these skills are the product other repos install, so the human read has value outside this repo. Saves 2 asks in 8 days, against one gate-code merge entry to build. |
| 2c | yes, weakly | No hard line. The one non-[1] merge answer in two windows was a failure-pattern fix (Q-288 [3], renumbering). Since then, a duplicate number in the tree is a gate gap (`scripts/build-loop.sh` header) and a cross-branch clash merges as a conflict, which auto send-back returns to the loop. So that catch is now mechanical. Saves 1 ask in 8 days. |
| 2d | no | ✗ P2. The owner asked for these runs (Q-308 [1]), and the entry is how they see the result. Area A pruned the same idea as untested ([16]), and nothing here tests it. |
| 2e | no | The never line is the owner's choice (Q-149 [2], "since workflow changes steer every later session"). There is no new evidence, and 0.25 a day saved. |
| 3 | no | Pruned twice before (decision 040 [11], the 2026-11-06 record [11]), and the gloss rule (Q-263) asks for clarity, not length. Saves 0 asks. |
| 4 | not competing | Already chosen (Q-345 [1]) and on the roadmap. It saves a confirmation step, not an ask, and fits P5: the owner batches by file when they want to. |
| 5 | no | ⚠ S10 and S8's spirit: it slows every gate unit to cut a per-day count while the weekly count stays the same. The cycle's slots already wait on open gate entries (section 3.5), so pacing exists without a rule. Area A pruned [15] (quiet hours) for the same reason. |
| 6 | not competing | A measurement, not a policy. It goes to section 8 as the cycle's watch. |

Survivors: [0], [2b], [2c] (taken together as [2b+2c]).

### 5.4 Tradeoffs between the survivors

| # | Effort | Asks removed | Key downside |
|---|---|---|---|
| 0 | none | 0 (auto send-back already took about 1 a day) | the trigger stays fired on every busy day |
| 2b+2c | about a day, plus its own `merge-gate-` entry and a release | 4 of 64 (0.5 a day; 7.5 a day remain) | the owner stops seeing skill-text changes before they ship to other repos; the floor's "prompt file" rule gets an exception |

**Hypotheses.**

- **[0]:** if chosen, the per-day count tracks landings. Asks per landing stay near this window's share. 64 asks for 56 landings is 1.14 per landing, about half of them merge entries. The owner keeps answering within hours and does not name asks as a burden. Counter-evidence: judgment entries waiting over 48 hours with a `Blocks:` line for a week, or the owner saying the asks are too many.
- **[2b+2c]:** if chosen, merge entries for skill-only or FP-only branches fall to zero, and no self-merged skill change is reverted or fixed within 7 days. Counter-evidence: such a fix, or the owner saying they missed a skill change.

**Stress test.**

- **Invert (argue for [2b+2c]).** Skill prompt changes in this window were eval-format fixes (F2 to F7, F8 to F12), checked by the skills' own report suites. The owner answered every one [1]. `skills/` files other than `SKILL.md` already self-merge (accepted in `docs/dev-cycle.md`). A failure-pattern entry is one line. What survives: all true. What does not: the saving is 0.5 a day, below what the trigger can see, and building it costs a gate entry, a release and a floor exception. Also, the floor's prompt-file rule is what makes Q-329's tentative-pick question reach the owner as part of a merge entry. Under self-merge it would go only to a final message and a roadmap item.
- **Boring alternative.** Wait. Throughput on 11-19 and 11-20 was 23 landings a day, against 1.7 a day for the six days before. Whether that pace lasts is unknown. If it does, watch Q-262 (merge entries over 11 a week in 3 of 4 digests) will fire on evidence and reopen the merge question at area A's [5n].
- **Revealed preferences.** The owner answers fast and in small batches. They used the answers file for eight entries at once, picked non-first options on 8 of 13 real choices, and turned down the one structural cut offered. They are spending attention where they choose to, not skimming everything.
- **Does [0] accept the trigger staying fired?** Yes. Under the per-day reading, at about 1.1 asks per landing, any day with more than about 4 landings goes over 5. A trigger that fires on every busy day can no longer tell an overload from a productive day. Section 8 gives the cycle a watch that can: asks per landing, waits, and the owner's own word.

```
Decision: fewer owner asks per day, merge entries first        top 2 of 11
 ID      Approach                    Effort   Risk   Hard  Key downside
 [0]     Status quo                  ● none   ● low  4/4   trigger fires on busy days
 [2b+2c] Skill + FP entries off floor ◐ 1 day  ◐ l-m  4/4   0.5 asks/day; skill text ships unread
 Legend: ● strong/low  ◐ partial/medium  ○ weak/high
 Recommended: [0]. Evidence: Q-323 [2] and its words; [2b+2c] removes 4 of 64.
```

## 6. Decision

**[0], status quo. Path A, about 75%.** Nothing changes: not decision 040's routes, the floor, the never line or the entry form.

[0] dominates because:
- the two options that would cut the count materially ([1] and [2a]) are the ones the owner turned down on 11-20, in words that name their real cost;
- the survivors save half an ask a day and cost an ask, a release and the owner's read of product text;
- the big rise in asks follows a rise in throughput, which is the cycle doing more work, not a policy getting worse;
- the parts of asking that were pure waste are already fixed or chosen: re-dispatch asks by auto send-back (live), and the answers-file confirmation by Q-345 [1].

The other 25% is mostly that [2b+2c] is worth its cost if this pace lasts and skill-only branches become a larger share. Section 8's watch reopens it on that evidence.

**Pruned candidates and why.** Each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in adjacent areas can grep this section to avoid regenerating already-pruned approaches.

`[1 daily digest entry]: ✗ P5, the owner prefers separate entries "rather than all in a lump" (Q-323, 2026-11-20); saves entries not reading; T3 and the answers file batch on the owner's terms.` `[2a gate code self-merges]: owner answered Q-323 [2] on 2026-11-20; reopens only via watch Q-262.` `[2b skill prompt files]: survived, lost in step 4: 2 asks in 8 days against a gate entry and the owner's read of shipped skill text; fallback with [2c].` `[2c failure-pattern entries]: survived, lost in step 4: 1 ask in 8 days; Q-288's catch is now mechanical; fallback with [2b].` `[2d owner-requested records]: ✗ P2, the entry is how the owner sees runs they asked for; untested (area A [16]).` `[2e workflows/ off the never line]: the owner's line (Q-149 [2]); no new evidence; 0.25 a day.` `[3 lighter entries]: pruned twice before (decision 040 [11]; 2026-11-06 [11]); clarity not length (Q-263).` `[4 answers file]: not competing, already chosen (Q-345 [1]).` `[5 fewer gate briefs at once]: ⚠ S10, slows gate units for a per-day count while the weekly count holds; slots already wait on open entries.` `[6 measure per landing]: not competing; a watch (section 8).`

**Revisit triggers.** Each entry is a concrete, observable condition that should prompt re-evaluating this decision. Future readers can grep this section when their context changes to see whether earlier decisions still apply.

`if the owner names asks, or reading them, as a burden. if asks per landing exceed 1.5 over a weekly digest's window (baseline 1.14, 64 asks for 56 landings, 2026-11-13 to 11-20), which means the review share grew rather than throughput. if a judgment entry with a Blocks: line waits over 48 hours, three times in a week. if skill-only and FP-only merge entries together exceed 5 in a week, which reopens at [2b+2c]. if watch Q-262's conditions are met, which reopens the merge question at area A's [5n].`

## 7. Other choices (one line each)

- **Use of `questions.sh counts`:** not run. Q-344 [1] approved it on 11-20, but at 0423fe3b `scripts/questions.sh` has no `counts` (its newest change is 82f38f86, 2026-10-31), and the brief allows it only "if it has merged". So the counts are by hand.
- **Q-281 to Q-284 counted as re-dispatch:** as in area B, each asked "keep the interim?".
- **Day boundary:** the entry's `Opened:` date, not the commit time, so it matches how Q-341 counted.
- **Whether to ask the owner to reword decision 040's trigger:** no. A watch the cycle owns can carry the better measure without an ask (S10), and the record's text is the owner's to change when 040 next changes for another reason.

## 8. Gotchas

- **The trigger will keep reading "fired".** Under the per-day reading at this pace, every iteration's trigger pass will find it fired. This record is the answer to it until a revisit trigger in section 6 is met. Citing this record avoids a second reopen.
- **A count from an instrument with drift.** These counts are by hand, as area B's were. The global instructions say never to route a number from such an instrument to the owner without checking it again. Before citing them in an owner entry, re-run them with `questions.sh counts` once it is on main.
- **Landing counts use Pacific commit dates.** Ask counts use `Opened:` dates. On 11-19 and 11-20 an evening's work can fall on either side.
- **"Approved merge" includes non-gate review merges.** The 28 approved merges are not all gate code; 16 of the 33 merge entries were gate.

## For the dev cycle

**No change**, with the reason in short: the owner's 11-20 answer to Q-323 (separate merge entries, read 1-2 at a time) rules out the two options that would cut asks a lot. The remaining options save about half an ask a day, at the cost of a gate-code change and the owner's read of skill text that ships to other repos. The rise to 19 and 21 asks a day followed a rise to about 23 landings a day. About half of landings went to review throughout, so the review share did not grow.

No brief, and no owner question.

**Suggested watch** (the cycle owns `docs/working/watching.md`; this doc does not write it). A `trigger` entry, slug for example `decision-040-asks-per-day`, that holds this record's baseline and section 6's revisit triggers:
- asks per landing over 1.5 in a weekly digest's window (baseline 1.14);
- a judgment entry with a `Blocks:` line waiting over 48 hours, three times in a week;
- skill-only plus FP-only merge entries over 5 in a week, which reopens [2b+2c];
- the owner names asks, or reading them, as a burden.

Its interim: decision 040's per-day trigger is answered by this record, and the trigger pass cites it rather than reopening. Once `questions.sh counts` is on main, the watch reads its numbers from it.

**For the final message:** Q-341 [1] (the owner's "reopen 040 now") is answered by this record. It found no change. The main reason is the owner's own Q-323 words.

## Files read

Last verified: 2026-11-20

Relevant paths: docs/decisions/040-questions-doc-owner-only.md, docs/working/questions.md, docs/working/questions-archive.md, docs/working/watching.md, docs/dev-cycle.md, skills/dev-cycle/SKILL.md, scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/questions.sh, docs/working/cycles/cycle-2026-11-20.md
