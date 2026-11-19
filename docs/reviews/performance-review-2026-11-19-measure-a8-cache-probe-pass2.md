Commit: 89eb9b65

# Performance Review — measure/a8-cache-probe, pass 2 (delta f87a1455..139aeedd)

**Scope:** `git diff f87a1455..139aeedd` (docs only): `docs/reviews/code-review-rubric-2026-08-07-main.md`, `docs/working/research-2026-11-19-a8-cache-probe.md`, `runs/review-arms/a8-2026-11-19/cache-probe.md`. Partial scope (loop pass); other branch commits are context only.
**Date:** 2026-11-19
**Based on:** `docs/reviews/code-fact-check-report-2026-11-19-measure-a8-cache-probe-pass2.md` (Claims 10, 14, 15 Verified); previous rubric `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md` rows A2, A5.

Evidence runs (cwd `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review2/perf`, exit 0, no process left running):
- P1: `timeout 60 python3 -I bp.py <transcript>` on `agent-a6a0ebd8bee725384.jsonl` (A8 Stage 2.5 agent, 18 requests) and `agent-ad0565873cbe05c85.jsonl` (probe B). It prints every `api-request` `cacheControl` and every distinct first-turn usage.
- P2: first-record timestamps of the subagent transcripts that name `measure-a8-cache-probe` (this branch's two review passes).

## Data Flow and Hot Paths

These are docs only, so no code path runs. The cost they reason about is the review loop's own spend. Each review pass dispatches about 8 Agent-tool subagents, and each one's first request is about 50.6k input tokens (`probe-out.txt`: input 2 + creation 31,731 + read 18,900). This is a hot path in the cost sense: every agent in every pass pays it. The docs claim that the inlined shared block gets no cross-agent cache reads, and infer that it gets no cross-pass reads either.

P1 shows how breakpoints are placed. Every request in the 18-request A8 agent carries exactly three breakpoints: `system[0]`, `system[1]`, and the request's last message block (`messages[1].content[3]` first, then `messages[4].content[0]`, `[6]`, … `[24]`). No request carries a breakpoint inside `messages[0]`. Within one agent, the lookback does reach the previous request's end. The second request read 52,114 = 18,900 + 33,214, which is the first request's full write. So the lookback finds entries written at earlier breakpoints and nothing else.

## Answers to the brief's questions

1. **A2: partly resolved.** `cache-probe.md:91-95` records the A7 implication and marks it "inferred from the records, not measured". That part is correct and sufficient. The A8 cell and the research doc's follow-up both state the A7 consequence flatly, with no marker (Finding 1). So the previous rubric's Status for A2, "cache-probe.md and A8's cell record the A7 implication, marked inferred", is true only for cache-probe.md.
2. **A5: resolved.** `probe-out.txt` B usage is `'input_tokens': 2, 'cache_creation_input_tokens': 31731, 'cache_read_input_tokens': 18900`. That makes 50,631 cacheable tokens out of 50,633 input. The final breakpoint is the request's last block (`messages[1].content[3]`), so a request byte-identical to A's would match A's entry at that point. Two uncached input tokens remain. "whole request … about 50.6k" is therefore accurate to 2 tokens, and the span (system + tools + `messages[0]` + `messages[1]`, "instruction files and listings included") is right. The figure holds for the literal case of a request identical to A's. Finding 2 sets out a limit on the hypothetical delivery it is attached to.
3. **The A7 inference is sound, and the caveat is adequate.** By P1, the only breakpoints are `system[1]` and each request's last block. A later pass's agent diverges from every earlier request inside `messages[0].content[3]`, because the diff part changed. The 20-block lookback (unverified source, per `cache-probe.md:58-62`) can only find entries that an earlier request wrote at one of its own breakpoints. None of those sits between `system[1]` and the divergence point, so no partial reuse past 18,900 is possible. A partial hit would need a breakpoint that ends at part 4. P1 shows the harness never places one there, and the orchestrator cannot place one (`cache-probe.md:69-71`). There is also a second, measured reason that the docs omit: the TTL (Finding 3).
4. **New errors:** the fixes introduce no wrong figure. The one new mechanism wording that overstates is the unhedged A7 statement (Finding 1).

## Findings

#### 1. A7's cross-pass consequence is stated as established in the A8 cell and the research follow-up, not marked inferred

**Severity:** Low
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `docs/working/research-2026-11-19-a8-cache-probe.md:75-76`
**Move:** Question the cache (hit-rate claim vs evidence)
**Classification:** Micro (wording of one claim) / Cold path (docs)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

Evidence: `code-review-rubric-2026-08-07-main.md:35` "Still open: the skill text this row cites (`SKILL.md:274-277`, `:352-354`) and A7's cross-pass claim (`:347-351`) now describe a saving that does not occur". `research-2026-11-19-a8-cache-probe.md:75-76` "its stable-parts-first rule claims cross-pass warmth (`:347-351`, rubric row A7); the probe shows that saving does not occur on the Agent-tool path". Compare `cache-probe.md:89-90` "The probe did not test reuse across loop passes" and `:94-95` "That is inferred from the records, not measured."

The previous A2 fix asked for the A7 implication to be recorded "marked inferred". The previous rubric's Status for A2 says both cache-probe.md and A8's cell do this. Only cache-probe.md does. The cell and the follow-up say the cross-pass saving "does not occur" / "the probe shows", which counts an untested path as measured. The inference is sound (answer 3), so the risk is limited to provenance. Someone acting on the follow-up would treat A7 as measured-false and not re-check it.

**Recommendation:** In both places, qualify the A7 half, e.g. "and, by inference from the same records (not measured), A7's cross-pass claim (`:347-351`)".

#### 2. The ~50.6k whole-prompt saving needs the per-agent part kept out of the first request, not just placed after the shared part

**Severity:** Informational
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:76-80`; `docs/working/research-2026-11-19-a8-cache-probe.md:68-69`
**Move:** Question the cache (hit rate of the proposed alternative)
**Classification:** Macro (cache-key structure) / Hot path (every agent's first request in every pass)
**Confidence:** Medium
**Baseline:** 18,900 cache-read tokens on B's first request (`probe-out.txt`, B usage 2026-11-19T19:39:48.458Z)
**Legibility-target:** for-author

Evidence: `cache-probe.md:76-79` "Only a byte-identical whole prompt would match, with the per-agent part delivered some other way. … B would read its whole request from cache, about 50.6k tokens (18,900 + 31,731) instead of 18,900". P1 shows that each request writes an entry only at `system[0]`, `system[1]` and its own last block, and that the lookback finds earlier entries only at those points (the second A8 request read 52,114 = 18,900 + 33,214, the first request's write). Suppose the per-agent part were sent as a separate block later in the same first request. A's entry would then end after A's per-agent block, no entry would end at the common part's end, and B would read 18,900 again. The 50.6k figure holds only if the first request is identical across agents and the per-agent part arrives in a later turn, for example through a tool read. "Some other way" leaves this open, and a reader weighing lever #3 could pick a delivery that saves nothing. This rests on the unverified lookback description plus the P1 breakpoint pattern, hence Medium confidence.

**Recommendation:** Add a clause: "(the first request must be identical across agents; per-agent content in the same request, even as a separate block, would get no breakpoint at the common end)".

#### 3. The cross-pass inference omits an independent, measured cause: passes are further apart than the 5-minute cache lifetime

**Severity:** Informational
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:89-95`
**Move:** Price the deployment environment (cache TTL vs call cadence)
**Classification:** Macro (cache lifetime vs pass cadence) / Hot path (every pass)
**Confidence:** High
**Baseline:** 36 min 15 s between this branch's pass-1 critic dispatch (first record 2026-11-19T19:56:02.541Z, `agent-a54d042e4e4c2064f.jsonl`) and pass-2 critic dispatch (2026-11-19T20:32:17.529Z, `agent-a0d7aac289f1f4b73.jsonl`), P2
**Legibility-target:** for-author

Evidence: `cache-probe.md:36` "well inside the 5-minute lifetime (`promptCacheRequested: 5m`)"; `cache-probe.md:90-91` "a later pass's agent hits only if its whole prompt is byte-identical to an earlier one's". Transcript B carries `"promptCacheRequested":"5m"`. On this branch, a fix → re-review cycle took about 36 minutes, roughly 7× the lifetime. Even a breakpoint at the end of part 4, or a fully byte-identical prompt, would find pass 1's entries expired. The 5m lifetime counts from last use, so pass-1 agents finishing later would narrow the gap, but not under 5m when the fix commit itself landed 20:24Z. This is a second reason the `SKILL.md:274-277` / `:347-351` cross-pass claim fails, and unlike the breakpoint argument it is measured. It matters for the follow-up: fixing breakpoint placement alone would still not restore cross-pass reuse without a longer TTL.

**Recommendation:** Add one sentence to the A7 paragraph and the cycle follow-up: "separately, passes on this branch were ~36 min apart, past the 5m cache lifetime, so cross-pass reuse would also need a longer TTL."

## Endorsements

- B's cacheable span is 50,631 of 50,633 input tokens. The final breakpoint is the request's last block, so "whole request … about 50.6k (18,900 + 31,731)" is the right span (A5 fix). [fact-check: claim 14 — Verified]
- No breakpoint ends at parts 1-4, because parts 1-4 sit inside `messages[0].content[3]` and the breakpoints are `system[0]`, `system[1]` and the last block. P1 shows the same three-point pattern on all 18 requests of a multi-turn agent. [fact-check: claim 15 — Verified]

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A7 consequence stated as established, not marked inferred, in A8 cell and follow-up | Low | `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `docs/working/research-2026-11-19-a8-cache-probe.md:75-76` | High |
| 2 | ~50.6k saving needs an identical first request, not just per-agent part placed after the shared part | Informational | `runs/review-arms/a8-2026-11-19/cache-probe.md:76-80` | Medium |
| 3 | Passes ~36 min apart exceed the 5m TTL, an independent measured cause the A7 inference omits | Informational | `runs/review-arms/a8-2026-11-19/cache-probe.md:89-95` | High |

## Overall Assessment

The cache reasoning in 139aeedd holds up. A5's figure and span are right to within 2 uncached tokens, and the A7 inference follows from the breakpoint pattern, which P1 confirms holds across all 18 requests of a multi-turn agent, not just first requests. A2 is resolved in cache-probe.md but not where the previous rubric says it also is. The A8 cell and the research follow-up drop the "inferred" marker (Finding 1). This is the only item that misstates provenance, and it is a one-clause fix in each place. Findings 2 and 3 add completeness for whoever corrects the skill text: the whole-prompt alternative has a delivery condition, and cross-pass reuse also fails on TTL. No further measurement is needed to act on any of them.

## Goal-Alignment Note

The goal is to confirm that 139aeedd's fixes are accurate and complete before merge. On accuracy, every figure checks against `probe-out.txt` and the transcripts, and the mechanism claims match the recorded breakpoint layout. On completeness, A5 is fully resolved. A2 is resolved in the probe doc but overstated in two places (Finding 1, Low). Two Informational additions would make the hand-off to the cycle more precise. None of them blocks the merge. Scope was the delta range. I read the changed paragraphs whole together with their sections, `SKILL.md:268-358`, and the previous rubric's rows A2 and A5.
