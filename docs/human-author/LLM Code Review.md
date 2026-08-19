# LLM-driven Code Review Process

After a recent conversation where someone mentioned that they experienced multiple model lineages surfacing additional issues in code reviews, I decided to revisit the code review machinery in my agentic scaffolding, \[claude-workflows\].

I’m very glad I did this, especially because I had just gone through a similar process for updating the *security* profile of the setup, which revealed a variety of concerns, but also left me *not using my entire scaffolding setup*. Hopefully in the future the improved code review process will catch things like this.

# Possible Architecture

There are a variety of ways to run code reviews with agentic LLMs. A few of the important axes of possibility are:

1. Context  
   1. Are you providing only the diff? Neighborhoods of the diff? Full files containing diffs? Full repo access?  
   2. Larger context may be necessary to find some issues, but also tends to distract and degrade performance, as well as creating a larger space for false positives in the review  
      1. I suspect this may be an important reason that Google had trouble getting mileage out of coding agents early; the giant mono-repo means context management has been an active problem at a scope that even frontier models can’t fit into context, while an early stage git repo can fully fit in current context windows. This is purely a hunch as I haven’t been internal to Google in years.  
2. Action space  
   1. Are reviewers producing issues? Are they producing fixes? Do they have tool access to request additional code reads? Are these steps being taken within the same sessions?  
3. Reviewer instructions  
   1. How are diffs distinguished from surrounding context? Are reviewing models told to “review this code” or given specific guidelines to match a standard for the code base? Are instructions general, or scoped to specific review tasks, such as separating security review from readability review?  
4. Review models  
   1. Sonnet, Opus, Fable, Sol, Gemini, Grok, etc. etc.  
5. Review replication  
   1. Is a review being generated once, or several times? How are results from multiple reviews aggregated?  
6. Identify, Diagnose, Fix structure  
   1. If reviewers are limited to one part of the action space (2), how are the other actions organized?

These choices all interact, resulting in a huge possible space of processes with very different properties. Along many axes it is possible to spend more compute and money and get better results. The question is, what are the most efficient ways of spending money to improve code quality?

# My Architecture

Because the possibility space is high dimensional, I chose to stick to a specific core structure (points (2) and (6)), only validating against a simple null hypothesis setup, then running targeted evaluations along other dimensions to pick reasonable points. That core structure is:

Step 1: \[Code Fact-check\]  
From the skill description:

“Verify checkable claims in code comments, docstrings, commit messages, and project documentation against actual code behavior. This is the code analog of the prose \`fact-check\` skill: where \`fact-check\` checks essay claims against the world via web search, \`code-fact-check\` checks code claims against the codebase via direct file reading. For every claim about what code does, how it performs, or how it's structured, search the codebase for evidence and report findings with calibrated confidence. Produces a structured Markdown report. Use this skill when the user asks to "verify the comments", "check the docs against the code", "audit documentation accuracy", "are the docstrings still accurate", "do the comments match the code", or when upstream orchestration (e.g., the \`code-review\` skill) requests a code verification pass. Also trigger when reviewing or onboarding to a codebase and the comments or docstrings look stale, drifted, or contradict the surrounding implementation — running this skill before further work surfaces documentation rot that would otherwise mislead later changes.”

Step 2: \[Targeted Critics\]  
Dispatch parallel agents with the “fact-check” results with distinct instructions.

Always include:  
Security  
Performance  
API consistency

Based on context, orchestrator can choose to include:  
Architecture  
Test Strategy  
Technical Debt  
Dependency Upgrade  
UI Visuals

Each of the contextual reviewers has specific guidance for when it should trigger.

A coding agent interfaces with this process by calling a \[review-fix-loop\] in which it triggers full review, applies fixes, and re-triggers full review up to three times. If the third set of reviews still contains blocking issues, the agent punts back to a human–usually because this involves a design decision that is not well specified.

The overall cost of the current code review process is $10-$15 per review-fix cycle at API billing prices. This contrasts with a naive “review this code” sweep at $2-$4, but captures a wider variety of issues (and still compares favorably to spending a human SWE-hour on the task).

This was the original setup of my repo, evolved from mimicking an [essay draft review](https://github.com/tomwalczak/claude-cowork-fact-checking-skills) repo I picked up when [Abi Olvera](https://substack.com/@abio/notes) mentioned it (though I don’t remember when to find the mention).

### My Choices

A brief outline of the current state of the system

1. Context  
   1. Context for fact-check agents is a scope specification, generally \`git diff main…HEAD\` but overrideable to limit file list, PR, or commit ranges, mostly for breaking up changes \>1000 lines.  
   2. Context for topical critics includes the output of the fact-check run  
2. Actions  
   1. Fact check review is limited to producing accuracy assessments of code and code intent  
   2. Topical reviewers limited to their own topics  
   3. Code review orchestrator aggregates the results  
   4. All reviewers have access to file reads so they can curate their read context  
   5. Reviewers write their results to \`docs/reviews/\`  
3. Instructions  
   1. Clarify rules and roles for each reviewer agent  
   2. See the repo for details  
4. Review models  
   1. Default to Opus for most use cases; replicate with Fable in some cases  
5. Review replication  
   1. Run 3 instances of fact-checking step  
6. Identify/Diagnose/Fix structure  
   1. Fact-check only identifies  
   2. Topical reviewers identify, may diagnose  
   3. Review-requester creates and applies fixes

# Choice Validation

What makes choices of configuration better or worse? Fundamentally there are two values in play. One value is cost; each additional token sent to or from an LLM costs money. The other is bug identification. Every valid issue pointed out in review is an issue that doesn’t arise in production code. This is fundamentally a recall problem.

In most cases when evaluating recall, it is also important to evaluate precision, and precision was also measured across all my experiments, but the cost of a false positive issue being raised is the cost of sending those extra tokens back and forth during the review and fix process–that is, it is directly convertible to a cost in dollars.

So in designing a code review process, look at pieces of the process, and compare the compute cost of each piece with the value of bugs identified in some corpus.

We could use a standard benchmark such as [SWR-Bench](https://arxiv.org/abs/2509.01494) to evaluate this, but in practice I used the git histories of a few of my own local projects. Having a longer coherent history for a project has a handful of advantages over standalone benchmark problems; the existence of additional commits and merges in those projects means that some bugs which made it through review are identified later on; the history of the project from conception to present means that the context of changes are always accessible; the presence of the full repo in possible context demonstrates how test strategies interact with the presence of issues.

## Specific Tests

### Fact-Check Replication

Across initial tests, the biggest result was inconsistency of single-pass reviews. Code reviews without scaffolding only agreed with themselves on high severity issues at Jaccard 0.14-0.25, while topical critics were much more stable (J\_self 0.70). With three fact-check iterations, overlap across iterations has varied from 47%-91%; while k=3 is not fully settled, preliminary results suggest k=2 would see significant losses and k=4 would not see substantial gains.

Across reviews by Claude Sonnet, Opus, Haiku, and Fable, as well as unscaffolded reviews by Gemini, GPT-5.6 Sol, and Kimi K3, almost all failures to identify issues arose in the fact-check stage, where they were often noticed but assigned low severity and not followed up on by the topical reviewers.

### Rich Fact-Check briefs

When expanding to k=3 replications of the fact-check stage, a previously-identified bug in one of the repo commits stopped being identified. Re-running across a variety of configs, the factor that caused the bug to be located was a richer brief on what the fact-checking agents should be considering. This expanded their search to find this bug, which was not within the diff and missed by reviewers based on instruction changes rather than based on replication runs or model choice.

## Verification Anti-patterns

There are some ways of evaluating code review processes that I specifically did not use. I am not measuring development velocity, nor am I measuring “signal overload” from model feedback. In particular, I am excluding usage of SWR-Bench from my evaluations, after my first spot check (of [astropy pull 1010](https://github.com/astropy/astropy/pull/1010/changes)) showed a review with six accurate, non-blocking findings that was scored as ten false positives.

Of course, just my saying that the findings are accurate isn’t a replicable assessment; I am working on iterating on judge behavior in the repo, and hope to publish a fork with a superior scoring mechanism in the near future.

I am focusing on the use case in which all (or almost all) code is agent-authored. For this use case, clean PRs are not represented as a balanced subset; out of scope comments are being directed to the appropriate developer (the agent itself), and signal overload is a non-issue. These are intentional steps away from the intended use case of SWR-Bench, which is focused on surfacing only high impact feedback for human developers as part of a human code review.

# Numbers

Since my use case doesn’t match existing benchmarks well, I put together a test dataset based on my own ongoing projects. Rather than treat my existing commits and PRs alone as gold standard ground truth, I also allow ground truth if a bug is introduced by the change to be reviewed, but is fixed in a later request.

I ran a first pass with headless (non-agentic, static prompt) reviews by various models across a very wide range of commits. I identified a handful of commits where this review pass either found something not in the review, or did not consistently find issues present in the historical review.

The headline results are:

|  | Full harness review | Single Sonnet headless review | Notes |
| :---- | :---- | :---- | :---- |
| Issues found in historical review | 24/24 (8 red, 16 amber) | 6/24 (3/8 red, 3/16 amber) | 7 test-set instances; the label set is pipeline-derived, so the harness column is 24/24 by construction. Fresh harness re-runs are harsher but not deterministic — individual passes miss individual historical labels (verdicts are draws from a distribution). Headless arm: 0 confirmed false positives across all 7 instances. |
| Issues attested by later fixes | 5/6 | 2/6 | 6 labels are confirmed by later fix commits. The headless arm's 2 include one the full harness missed entirely (dev-mode `unsafe-eval` CSP relaxation, fix-confirmed in a later commit). |
| Issues apparently still present in projects | 6 | 1 | Harness (fresh re-runs on post-fix states): vacuous test regex, fails-open production guard, rehydration seam bypass, false "fresh ArrayBuffer view" comment, OPFS write race, cache-key double-storage — all six verified still live at HEAD (2026-08-13). Headless: `NEXT_PUBLIC` optional-chaining build-inlining break, still live at HEAD. |
| Cost of run | ~720k–1.06M subagent tokens per pass ≈ $10–15 per review-fix cycle | $0.075–$0.43 per instance; $0.81 for the full 8-instance sweep | Full-pass cost is findings-independent (clean/dirty ratio ≈ 1.02) and sublinear in diff size. Harness "tokens" are a raw per-agent count from task notifications with no input/output/cache split recorded; the dollar figure is session-billed, implying a blended ≈$14–20 per M tokens (between Opus input and output list rates — cumulative, partly cache-discounted input dominates the count; output dominates the bill). Prompt caching changes billing rate, not token count, and on this architecture (critics self-read rather than sharing an inlined prefix) is measured at only ~5% of cost. The headless column is exact billed cost (its calls are output-dominated: ~3.6k prompt vs 12–23k completion tokens). |

