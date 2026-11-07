# Trial: attention and trust (2026-11-06 to about 2026-11-13)

Started at the owner's request on 2026-11-06: "none of them have hurt and some have helped so let's commit them and start a new set of trials". The first set is `docs/working/trials/2026-10-30-friction-engagement.md`. All seven of its trials (T1-T7) stay, and a build loop is writing them into the dev cycle (`docs/working/briefs/2026-11-06-codify-trial-practices.md`).

**Method.** As before, each trial changes only how the dev cycle and its orchestrator write things, so you see it at once and no image release is needed. Every dev-cycle iteration follows this doc until you say otherwise. The numbering carries on from the first set.

**Where these came from.** Each one answers something you said at the end of the first set, or something the merge-approval record found (`docs/working/research-2026-11-06-merge-friction-design.md`).

## Running trials

| # | Trial | What you'll see | Why this one | What I want your feedback on |
|---|---|---|---|---|
| T8 | **Decide-first final message** | Each final message opens with what needs you, split into "needs you now" and "can wait", each with one plain line. Everything else comes after. | You follow the work through your answers, so the answers should come first. | Could you stop reading after the first section and lose nothing? |
| T9 | **Further reading** | Each final message ends with at most two links, to the docs most worth opening. | You called a message with two links for further reading "great". | Did you open them? Were they the right two? |
| T10 | **One line on the release** | While a release is pending, the final message names the one change since the installed image most worth your look, and why. | You don't read the release notes closely, yet `docs/dev-cycle.md` treats that reading as the check on scripts merged without review. | Did the line catch your eye, and did it name the right change? |
| T11 | **One deliberate look a week** | The weekly digest offers one thing to read on purpose: a self-merge or a design pick, with one question and about five minutes' estimate. It counts how many you took. | The merge-approval record found fewer asks only helps if you still look at something on purpose. That count is 0 today. | Did it feel worth five minutes? |
| T12 | **What the checks caught** | The weekly digest lists what the gates and reviews actually stopped that week, each in one plain line, and says so when the answer is nothing. | You said you trusted the quiet weeks, but it was hard to tell how much trust was right. | Does this help you judge how much to trust a quiet week? |

## Not in this trial

- **A5 (one land per iteration), A6 (harness version stamp), A7 (feedback collected at release), A9 (per-project behaviour-change notice):** these need gate or install code, so they are not writing trials.
- **Re-dispatching a loop after a merge conflict without asking:** this also needs gate code; it is in the idea log.

## How to give feedback

Write it anywhere, in any order, for example: `T8 good, T11 skip it`. The cycle records your feedback in this doc, under Feedback, and turns it into roadmap changes. Each final message ends with a line naming these trials and linking here.

## Feedback

## Orchestrator notes
