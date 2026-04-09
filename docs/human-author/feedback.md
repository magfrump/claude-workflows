# Human Feedback

Observations about workflow/skill usage, effectiveness, and impact from actual
project work. Append entries as you have them — no need to be comprehensive or
certain.

## Format

Each entry: date, what you observed, how confident you are. Optionally reference
a hypothesis ID (H-01, etc.) or task ID if one is relevant, but don't feel
obligated to look them up.

## Entries

<!-- Append new entries below this line -->

2026-04-08
H-01
I don't observe any calls to the RPI prompt from external projects, but the data from these projects is *so* sparse that I suspect the hook isn't catching everything. My desire/expectation is that the workflows will trigger contextually without my needing to explicitly invoke them; if this isn't true then we need to review the structure of the project. Low confidence. Medium confidence that the patterns seen so far are not actually relevant to whether the RPI prompt is useful, but are instead relevant to how workflows are triggered in sessions.

H-02
I haven't been developing in any repos that don't use docs/thoughts and docs/decisions. I'm not sure what is meant by "structured commits".

H-03
I haven't explicitly used the bug-diagnosis workflow, but it was created after resolving the biggest set of bugs I was working on. I also haven't found much difficulty just pasting bugs into claude code--this is often enough context to fix the bug on its own. low confidence, but some evidence the workflow isn't used.

H-04
I invoke divergent design all the time. This is part of the reason I suspect the hook logging isn't working. I specifically used it in meta-formalism-copilot for backed state management, and ended up picking the 12th out of the 12 generated hypotheses. Very high confidence, 99%. I used a similar pattern in web chat that inspired the recent epistemic version of the feature. The diverge/evaluate pattern is the number one best piece of prompting I use, regularly surfacing ideas neither I nor Claude would have considered otherwise and has enough transparency that I can often correct constraint/priority scoring and head off future problems by correcting.

H-05
usage.jsonl contains no data on skills being used, which again I think is a logging bug, as I have definitely invoked skills in other repos. I spent a full day running ui-visual-review on Behemoth Arsenal over and over until it got through every UI problem it could find.

H-06
I have no idea what the length of any workflow text I invoke is. I don't think line count is an interesting metric for evaluating whether a workflow is useful, the question is whether it enables behavior that would otherwise require more work. This makes flows like divergent design or user testing valuable, as the alternative to get their results would involve a lot of manual work effectively reconstructing the prompts. It also makes coordination workflows like RPI, PR prep, and review-fix-loop convenient because they group multi-step processes into one command instead of five single word instructions. But it leaves bug-diagnosis unused, because just copy-pasting a bug is enough for claude to diagnose and fix bugs without further intervention (unless bug-diagnosis is being used in the background in these cases, in which case it's working amazing)

task-description-linter
Lint problems are good to minimize in that they are failures that aren't related to implementation difficulty or feature efficacy. However I don't think the gate-failure rate is the right thing to track. The question is whether, for a given feature, a linting script causes the feature to be implemented passing lint checks *while using fewer LLM tokens* than without the linting script. In this case the gate failure is catching errors before they make it to prod, so it isn't reducing external error rate. If the script creates extra information and results in more tokens being sent to the LLM, this could be a disadvantage. If the script causes lint failures to be caught and fixed more consistently, resulting in fewer rounds of LLM review, this could be a major advantage. This is related to but distinct from the existing hypothesis about gate failure rates--the more important question is counterfactual review processes.