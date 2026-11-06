# Trial: less friction, less habituation (2026-10-30 to about 2026-11-06)

Started at the owner's request: "trying things for a few days to a week," followed by owner feedback on what went well or poorly. The ideas come from `docs/working/brainstorm-2026-10-29-friction-and-engagement.md`. The IDs below (A4, B7, …) are that doc's IDs.

**Method.** Each trial changes how the dev cycle and its orchestrator write things. None of them changes code, so you see it immediately and no image release is needed. Once you've given feedback, the trials you liked get built properly. Usually that means gate code, run through `divergent-design` first wherever the brainstorm flagged it. The ones you didn't like get dropped. Until you say otherwise, every dev-cycle iteration follows this doc. The roadmap's Now line points here.

## Running trials

| # | Trial | Ideas | What you'll see | What I want your feedback on |
|---|---|---|---|---|
| T1 | **Release notes, one paste** | A4, A8 | Q-227 (image-lag) is short release notes. Unreviewed self-merges come first, then what changes for you, and routine records are a count. One paste covers every host step. Each iteration rewrites it in this format, not as the full commit list. | Did you read it? Did it tell you enough to run the release? Did you miss the full commit list? |
| T2 | **Asks you can read cold** | B7 | Each owner entry starts with **If you say no:**. A gate merge also says **What an attacker would want here:**. | Did those two lines change how carefully you read, or how fast you answered? Are they noise? |
| T3 | **Batched answers** | A2 (presentation only) | When several merge entries are open, the final message gives them as one block, answerable as `Q-235..237: [1]` or `all but Q-236`. The entries stay separate, because the gate finds each one by its heading. | Was one answer for several merges good, or did batching make you skim? |
| T4 | **Stale sweep** | B5 | An entry open 21+ days gets one line in the weekly digest with a proposed fate. When an entry's own closure line is met, the cycle closes it, as with Q-074 on 2026-10-30. Most of the September entries leave `questions.md` when Q-234's migration runs (decision 040). | Is the queue easier to trust? |
| T5 | **Weekly "what changed" digest** | B3, B2, B4 | Once a week, the first iteration writes `docs/working/weekly/YYYY-MM-DD.md`. It covers behaviour changes, unreviewed self-merges, security-review findings, the ask counter (asks per week, and how often you picked the default), and one randomly sampled self-merge with "anything surprising?". The first edition is `docs/working/weekly/2026-10-30.md`. | Did you read it? Was it too long or too short? Did the sampled review feel worth five minutes? |
| T6 | **Reserved security marker** | B1 | `⚠ SECURITY` is used only for: a `--state` refusal (planted `.git` state); a High finding from a security review that still holds after its fix round; a Q-103 residual (an accepted, known risk) becoming live. When used, it comes first in the final message and is also sent as a push notification. It is never used for anything else, including "this touches security code". The weekly digest reports how often it fired (expected: zero). | At the end: did you trust that a quiet week meant nothing fired? |
| T7 | **Zero recurring warnings** | B6 | The `setlocale` warning on every shell call is fixed in the Dockerfile (branch `fix/zshrc-locale`). It shows up after the next image rebuild. Any other warning that prints on every run is filed as a bug, not lived with. | Did you notice? |

## Not in this trial (needs code or a design choice first)

- **A1 (risk tiers), A3 (merge + release in one answer), A10 (status quo):** these compete for the same job. They go to `divergent-design` after this week, seeded with what T1–T3 showed.
- **A5 (one land per iteration), A6 (harness version stamp), A7 (feedback collected at release), A9 (per-project behaviour-change notice):** gate or install code, built after feedback.
- **B8 (quarterly threat-model walk-through):** first one due 2027-01.

## How to give feedback

Write it anywhere, in any order, for example: `T2 good, T3 made me skim, T5 too long`. The cycle records your feedback in this doc, under Feedback, and turns it into roadmap changes.

## Feedback

- **2026-10-30, owner:** "Merge all three", answering T3's batched block for Q-235..Q-237. This was the first batched answer. The orchestrator recorded it as `[1]` on each entry. The skill's rule counts a merge answer only when the owner's message names the ID and an option. Here the batched block named the IDs and the message named the option, so it was taken as meeting the rule. If T3 is kept, that rule should say so explicitly.
- **2026-10-30, owner:** "Q-239..241: [1]", the second batched answer, in the `Q-NNN..NNN: [n]` form the final message offered. Recorded as `[1]` on each entry; all three merged the same hour.
- **2026-10-30, owner, on T2's attacker lines:** "a hostile code author is out of scope for this repo. Every project is asking the agent to write and test code, which involves running the agent's code. Guarding against intentional hostility doesn't create security and does add friction." This came after Q-241's first version escalated Q-106 to a 5th review round on findings that each needed a hostile branch. That is constraint S1, and the review brief had not quoted it. For T2: "What an attacker would want here" names outside parties only, never the code's own author.
- **2026-11-05, owner:** "what's the expected interface for me to see what trials are happening, to know what feedback is relevant?" The answer was this doc, and nothing brought it to the owner. Since then, each final message ends with a line naming the running trials and linking here.

## Orchestrator notes

- **2026-10-30:** the first T1 rewrite of Q-227 misstated the image's commit. It said `ba6d2ec9`, copied from the old entry text, when `.manifest` says `fe57e352`. As a result, it asked the owner for a release that had already run. From now on, the release-notes rewrite reads `.manifest` and uses no older text.
- **2026-10-30:** the merges ran as two cycle lands around three gated `--merge --approved` calls. All three merged, and the affected suites pass 329/329 on the merged main. Friction seen: `--check-write` refuses `docs/working/trials/` and `docs/working/weekly/`, so trial notes and the weekly digest need their own docs commit outside the cycle land. If T5 is kept, it needs a place the cycle may write.
- **2026-11-06:** the second weekly digest is `docs/working/weekly/2026-11-06.md`. Its last section gives each trial's observations and whether feedback exists, ready for the end-of-trial decisions. The trial week ends about today; every iteration keeps following this doc until the owner says otherwise.
