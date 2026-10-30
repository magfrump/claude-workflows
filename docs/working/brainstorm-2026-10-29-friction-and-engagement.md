# Brainstorm 2026-10-29: harness friction, and keeping the owner engaged

Asked by the owner on 2026-10-29, after iteration 2026-10-30-0136. These are two separate brainstorms:

- **A:** where the harness creates friction, above all in merges (self-merge projects included) and harness releases.
- **B:** how to keep the owner aware of changes, so that when a real security issue surfaces, its request or warning is not one they have learned to click through.

Ideas only. Nothing here is decided. Where an area has 3+ competing approaches, it is flagged for `divergent-design` instead of being picked here.

## Signals (evidence both brainstorms draw on)

- **S1 — merge entries are always approved.**
  - The archive holds 19 `merge-*` / `merge-gate-*` entries, and none was answered [2] (drop) or [3] (change).
  - Each one still costs the owner a read and an answer.
  - Their headings are 40+ character slugs ending in a hash, such as `merge-gate-2026-10-29-questions-owner-only-unit3-6c8d949f4493`.
- **S2 — the release entry is mostly noise.**
  - Q-227 (image-lag) lists 27 first-parent commits. More than 20 of them are `chore/dev-cycle-*` lands, and every iteration lands twice.
  - The one ⚑ (an unreviewed self-merge, a36df962) is item 23 of 27.
- **S3 — a merged fix does nothing until the next release.**
  - A merged gate fix takes effect only after a host `install.sh` run. For example, Q-230's in-session answers for merge entries were merged at 014e5219, but the orchestrator follows it "once the next release" is out.
  - The release is the point that orders everything, yet nothing in a project shows which harness version it is running. philosophy-research F-001 came from exactly that: a repo migrated by newer rules while the image still lagged.
- **S4 — terminal pastes pile up.** Five `you: terminal` entries are open:
  - Q-084, from 2026-09-27;
  - Q-167, from 2026-10-15;
  - Q-222, Q-227 and Q-234, all from late October.

  The global rule says to collect them into one paste. In practice they sit apart, and one of them (Q-234) has an ordering dependency on a merge.
- **S5 — the queue holds stale entries.** It has open entries from 2026-09-26 to 2026-09-28 (Q-067, Q-074, Q-079, Q-084, Q-097, Q-098). The lesson a reader takes is that the queue can sit.
- **S6 — the same warning prints on every call.** Every D6 call, and every hardened-git script, prints `setlocale: LC_ALL: cannot change locale` (already a roadmap Idea).
- **S7 — feedback crosses projects by hand.**
  - The owner copies another project's `docs/harness-feedback.md` into this repo by hand.
  - This session, the copy landed staged at `docs/harness-feedback.md` under the wrong project name.
  - It also blocked a cycle land until the owner unstaged it.
- **S8 — finished loops leave locked worktrees.** Their locked worktrees keep 15+ merged branches from being deleted (already a roadmap Idea).

## A. Friction: merges and releases

**A1. Tier merges by risk, and stop asking about the bottom tier** (S1)

- Today, every claude-workflows branch that touches gate code gets its own `you: judgment` entry, while everything else self-merges.
- Proposal: split gate merges into two tiers.
  - **Changes enforcement:** what a gate refuses or allows.
  - **Doesn't:** docs in `skills/dev-cycle/`, test-only changes, a bug fix that its brief's acceptance criteria already pin down.
- Only the first tier stays an owner entry. The second lands as a self-merge with ⚑ and goes into the weekly digest (B3).
- *Would change:* `--check --expect`'s verdict lines and the GATE_CODE rule. The tier test itself is gate code.

**A2. One batched merge entry per cycle** (S1)

- When several merge entries are ready, file one entry whose options are:
  - [1] merge all;
  - [2] merge all but the ones listed;
  - [3] hold all.
- Each branch gets one line on what it changes and what you'd notice if it's wrong.
- Today's three entries (Q-235, Q-236, Q-237) would have been one answer.
- *Would change:* the dev-cycle skill's step 7 and `--check-answer`.

**A3. Merge and release in one answer** (S3)

- A gate merge's options gain "[1′] merge, then give me the release paste".
- The orchestrator merges, rewrites the image-lag entry for the new M, and the final message ends with that one paste.
- The owner's two actions (approve, then later run `install.sh`) become one decision and one paste, with no window in which a merged fix sits inactive.
- *Would change:* the merge entry's template, and when step 0.1 files image-lag.

**A4. Turn the release entry into release notes** (S2)

- Group commits by feature merge.
- Collapse chore lands into a count ("22 cycle lands").
- Put the ⚑ unreviewed self-merges first, each with a one-line description.
- Owners read a short list; they skim a long one.
- *Would change:* the image-lag text in `dev-cycle.sh`/the skill.

**A5. One land per iteration** (S2, S5)

- The cycle often lands twice, a record and then a fix-up, which doubles the merge commits on main and the length of the release list.
- Landing once at step 9, and folding step 10's changes into the next iteration, halves the noise.

**A6. Stamp the harness version in each project** (S3; philosophy-research F-001)

- The digest prints the image's commit and date.
- A migration records the image commit it needs, and `migrations.sh check` refuses to mark it due on an older image.
- F-001 (a repo migrated while its image could not read the result) would have been a refusal, not a silent "None open".

**A7. Collect feedback files at release time** (S7)

- `install.sh` (or a host-side companion) reads `docs/harness-feedback.md` from a configured list of project paths and copies each one, named by its `Project:` line, into `docs/working/feedback/` as a commit for the owner to review.
- The release becomes the sync point, and no owner copies files by hand.
- It reads other repos from the host, so it is a trust-boundary change, and the security review applies.

**A8. One generated paste** (S4)

- `questions.sh paste` orders every open `you: terminal` entry by its dependencies (Q-234 after Q-235's merge) and prints one script.
- Each part checks its own precondition and stops with a message instead of running half-way.
- That makes the global "collect into ONE paste" rule mechanical rather than remembered.

**A9. For self-merge projects: announce behavior changes, not commits** (S3, F-001, F-003)

- In a self-merge project such as philosophy-research, the owner never sees a merge entry. The friction there comes from a harness release changing behavior underneath the project.
- The first digest after a new image prints the release's behavior-change lines that apply to that project. Examples: "watches now live in `watching.md`"; "`check` refuses new `agent` entries from 2026-10-30".
- The project's loop then has a reason to look before it trips on the change.

**A10. Do nothing about the merge entries themselves** (S1)

- The 19-of-19 approval rate may mean the build loops are good, not that the review is empty.
- Gate code is the trust root, and a per-merge entry is cheap insurance.
- If so, the friction to cut is in the release (A3, A4, A8), not the approval.

**Flag for `divergent-design`:** A1, A2, A3 and A10 are competing answers to one question: how gate merges and releases are bundled and approved. They differ on owner time against review depth. Run DD on them, seeded with `docs/constraints.md` and B below, before building any of them. A4, A6, A7 and A8 do not depend on that choice.

## B. Engagement: not habituating the owner to warnings

The risk is a familiar one. When almost every request is routine and the right answer is always [1], the owner learns to answer [1] without reading. Then the one request that matters gets the same treatment. S1 (19 of 19 approved) and S5 (entries that sit for a month) are the two places this repo is training that habit today. The general approach is to keep requests rare, distinct and comprehensible, rather than to add more of them (memory: "no new human stops in dev-cycle").

**B1. A security channel that is used for nothing else**

- Add a route (`you: security`) or heading marker that is reserved for:
  - a confirmed security finding;
  - a `--state` refusal (planted `.git` state);
  - a residual from Q-103's list turning live.
- It goes first in the final message, in a fixed form unlike any other entry. It can also be sent as a push notification, because the session has the `PushNotification` tool.
- Its value depends on its base rate: if routine items ever use it, it becomes one more channel to ignore.
- *Flag for DD:* the options are a route, a separate file, or a notification only.

**B2. A budget for owner asks, tracked like a metric**

- Count `you: judgment` asks per week and the share answered with the default.
- When one class of entry is answered with the default 100% of the time over N weeks, the cycle proposes moving that class off the owner's desk (A1) instead of asking again.
- When the asks per week rise, the cycle says so.
- This turns habituation into a number the cycle watches, so it does not have to be noticed by feel.

**B3. A weekly "what changed in your harness" digest**

- Five to eight bullets, readable in two minutes:
  - the behavior changes that shipped;
  - the ⚑ unreviewed self-merges;
  - what the security reviews found, including what was fixed;
  - any residual that moved.
- It asks for nothing. Its purpose is that the owner's picture of the system stays current, so an anomaly looks like an anomaly.
- *Would change:* a new artifact or doc, written by the first cycle of each week.

**B4. Sampled review instead of per-item approval**

- Each week the cycle picks one self-merged or auto-tiered change at random and asks the owner to read it with one question, "anything surprising?". Expected cost: about five minutes.
- This replaces some per-merge entries (A1) rather than adding to them.
- The owner keeps reading real diffs, but rarely, and on a sample the owner did not choose. That is closer to how audits stay honest.

**B5. Stale entries expire into a decision**

- An entry open for 21+ days with no change gets one forced choice in the next final message: close, convert to a watch, or re-ask with a fresh interim.
- The queue then holds only live items, and an open entry means something again (S5: Q-067 is from 2026-09-26).

**B6. Zero recurring warnings**

- Any warning that prints on every run is a bug, filed at the same priority as a failing test.
- The `setlocale` lines (S6) and the `refuse`-looking but harmless output both qualify.
- The point is not tidiness: a warning that prints every time trains everyone, the cycle's own subagents included, to skip warnings.

**B7. Write every request so it can be read cold**

- Each owner entry names, in its first line, the one thing that would be different if you said no.
- Gate merges also name what an attacker would want from the changed code, if anything ("this file decides which script runs as the gate").
- This extends the memory "Owner entries: clarity, not length".
- A request that says why it might matter is harder to answer on reflex than one that only asks to be stamped.

**B8. A quarterly threat-model walk-through**

- A 20-minute session in which the cycle presents Q-103's residual list, the trust boundaries in `docs/constraints.md`, and what changed in them.
- The owner confirms each one is still accepted.
- An owner who has looked at the threat model recently can tell a real warning from a routine one.

**Tension to resolve.** B4 and B8 add owner time; A1, A2 and B2 remove it. The intended trade is to move attention from many routine approvals to a few deliberate looks, so the total should fall. DD on area A should treat B2's metric as the way to check that it does.

## What goes where

- Seeds for every idea above: `docs/working/idea-log.md`, under a `## Brainstorm 2026-10-29 (owner: friction and engagement)` heading.
- Roadmap Ideas: one line for each area, pointing here, plus the two DD flags.
- Nothing is briefed. Every item here is a design choice, or waits on the DD for area A.
