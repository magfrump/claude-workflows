Commit: f87a1455

# Performance Review — measure/a8-cache-probe

**Scope:** `git diff 8b06087719a4fd260cf692be9f5d485aee8535f1..HEAD` (commits 4363a15c, f87a1455; 3 docs files)
**Date:** 2026-11-19
**Based on:** `docs/reviews/code-fact-check-report-2026-11-19-measure-a8-cache-probe.md` (k=3 merged; 0 Incorrect, 0 Stale). Its Mostly-accurate clusters (Claims 1-7) are already tiered and are not re-filed here; Claims 3 and 4 (the "~31.7k" span and prize) are referenced only.

## Data Flow and Hot Paths

The diff is docs-only. The performance subject is the code-review pipeline's inline shared-context lever (decision 032 #3, `skills/code-review/SKILL.md:268-358`): one shared block placed first in every agent prompt so siblings read it from the prompt cache. Path temperature: **hot for cost** — the block is sent to every agent of every pass (~8 agents per pass, up to 3 loop passes plus a terminal pass). Measured sizes: block 8,755 bytes (≈2.2k tokens) at Stage 1 and 11,716 bytes (≈2.9k) at Stage 2 on csp; ≈21.2k tokens per pass over 8 core agents, ≈2.9% of the 743,755-token core (`runs/review-arms/a8-2026-11-19/results.md:46-49`). Each agent's first call carries 50,633 input-side tokens, of which 18,900 are cache reads (system + tools) and 31,731 are cache writes (probe-out.txt; fact-check Claim 9 Verified).

**Answers to the focus questions, in short.**

1. *No cross-agent cache reads on the Agent-tool path; no prompt order can fix it.* Supported for the within-pass, cross-agent case on this Claude Code version. The probe isolates timing (B 28.5 s after A's reply, inside the 5 m TTL), the prompt-prefix identity is executed (Claim 10), and the breakpoint layout is executed (Claim 11). The "no order" argument does not depend on the unverified web rule (Claim 8): the prompt arrives as one text block and A writes entries only at `system[1]` and at its own request end, so no entry exists at the block's end for B to match. Two limits: it holds for the breakpoint placement observed (Finding 5), and it says nothing direct about cross-pass reuse (Finding 3).
2. *Closing A8 as Split to Q-308.* Sound for the benefit half. Not complete: the false skill text and the cross-pass half of the claim have no tracked follow-up, and the same mechanism voids a sibling row that the rubric still lists as Fixed (Findings 1, 2, 3).
3. *Cost claims that mislead.* None is wrong in number. Two framings can mislead a reader weighing lever #3: the token-count instrument against a claim stated in input *cost* (Finding 4), and "harness context, not the tail" leaving the block's own share unstated (Finding 6).
4. *Missing for closure.* A tracked item to correct `SKILL.md:274-277`, `:347-351`, `:352-354`, and an assignment for cross-pass reuse (Findings 1-3).

## Findings

#### 1. The probe's mechanism voids rubric row A7's fix and `SKILL.md:347-351`, but the branch leaves both standing

**Severity:** Medium
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:88-90`; `docs/reviews/code-review-rubric-2026-08-07-main.md:34`; `docs/working/research-2026-11-19-a8-cache-probe.md:74-77`; `skills/code-review/SKILL.md:347-351`
**Move:** Question the cache (hit rate)
**Classification:** Macro (cache layout with zero hit rate) / Hot path (every agent of every pass)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** 18,900 `cache_read_input_tokens` on B's first call, the same as A's (probe-out.txt, 2026-11-19; fact-check Claim 9 Verified)

Evidence, the probe's own inference (`cache-probe.md:88-90`):
> "The probe did not test reuse across loop passes. By the same mechanism, a later pass's agent hits only if its whole prompt is byte-identical to an earlier one's, and every fix commit changes the block's diff part."

Evidence, the row it bears on (`code-review-rubric-2026-08-07-main.md:34`):
> "| A7 | Prefix ordering forfeits cross-pass cache warmth: the diff sits at shared-block position 2, ahead of four parts stable across the whole loop, so every fix commit invalidates essentially the entire cacheable prefix. Reorder stable-parts-first. | Performance | Medium | performance-reviewer #3 | for-author | — | ✅ Fixed (iter 2 — shared block reordered stable-parts-first, diff+enclosing now part 5 of 6; pinned by contract test 10) | — |"

Evidence, the skill text that carries A7's premise (`SKILL.md:347-351`):
> "- Across loop passes, the block's prefix stays cache-warm up to the first part that changed: parts 1–4 are stable across the whole fix→re-review loop; [...] Ordering stable-parts-first is what preserves a cacheable common prefix across passes even when the diff changes." (truncated mid-bullet; the elided middle names parts 5 and 6.)

Evidence, the follow-up list, which omits `:347-351` (`research-2026-11-19-a8-cache-probe.md:74-77`):
> "The skill still says the cache "serve[s] the shared block to all ~8 agents" and "Leave it on because it is free" (`SKILL.md:274-277`, `:352-354`); the probe shows that saving does not occur on the Agent-tool path. Correcting that text is a pipeline change the brief puts out of scope, so it is for the cycle to file."

If no cache entry ends inside the prompt block, a stable-parts-first order buys no partial-prefix reuse across passes either: the earliest entry a later pass can match is still `system[1]`. A7's fix (and contract test 10, which pins the order) then delivers 0 tokens of cross-pass warmth, while the rubric lists it ✅ Fixed and the skill tells orchestrators the order "is what preserves a cacheable common prefix". The cost of the order itself is nil; the harm is a reader (or a future lever decision) counting a saving that the branch's own mechanism rules out.

**Recommendation:** Add `SKILL.md:347-351` and rubric row A7 to the follow-up the research doc hands to the cycle, worded as "premise voided by the 2026-11-19 probe's mechanism (inference, untested across passes)". Do not reopen A7 on this branch (it is outside the brief); name it so the cycle's item covers it.

#### 2. `Split` closes A8 while the claim it was about stays live in the skill, with no tracked item for the correction

**Severity:** Medium
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `docs/working/research-2026-11-19-a8-cache-probe.md:74-77`; `skills/code-review/SKILL.md:352-354`; `skills/code-review/references/rubric.md:204`
**Move:** Find the work that moved to the wrong place (cost now paid with no offsetting benefit)
**Classification:** Macro (default-on cost with zero measured benefit) / Hot path (every pass)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** ≈21.2k tokens of inlined block per csp pass over 8 core agents, ≈2.9% of the core total (`runs/review-arms/a8-2026-11-19/results.md:46-49`)

Evidence (`SKILL.md:352-354`):
> "- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect it to move the token-count ledger."

Evidence (`references/rubric.md:204`):
> "| `Split` | 🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch) |"

Evidence, the closing cell's last clause (`code-review-rubric-2026-08-07-main.md:35`, Status cell, final sentence):
> "Net inline cost and recall effect moved to Q-308"

The tracked follow-up, Q-308, covers two settling runs (net cost and recall). The other remaining work — correcting a skill line that tells every orchestrator to "Leave it on because it is free" when its benefit measured 0 — is handed "for the cycle to file" in a working doc and tracked nowhere. With A8 closed, the rubric no longer carries any open signal for it; the skill keeps the lever default-on and keeps paying the ≈2.9%-of-core gross cost per pass on an unproven net. This builds on the fact-check escalation that Q-308's interim option "[2] After the cache fix" (`main:docs/working/questions.md`, Q-308 options table) now waits on a fix the probe says cannot exist by prompt order; together they leave Q-308's interim pointing at nothing and the skill-text correction untracked.

**Recommendation:** Before merge, name a tracked follow-up for the skill-text correction (a roadmap item, cited in the A8 cell next to Q-308), or have the cycle file it in the same merge; and have the cycle restate Q-308's option [2] (the existing escalation). The default-on decision itself stays the owner's under Q-308.

#### 3. Cross-pass reuse, half of the claim A8 quotes, is untested and assigned to no unit

**Severity:** Low
**Location:** `skills/code-review/SKILL.md:274-276`; `runs/review-arms/a8-2026-11-19/cache-probe.md:88-90`; `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Move:** Question the cache (hit rate across passes)
**Classification:** Macro / Hot path (fix→re-review loop)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** no baseline available — flagged as speculative

Evidence (`SKILL.md:274-276`):
> "This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a pass — and again on the next loop pass while it is unchanged — at the cache-read rate instead of re-billing full input per agent."

The probe measured one 2-agent first call; `results.md` §4 says "Reuse across loop passes was not exercised". The cross-pass conclusion in `cache-probe.md:88-90` is a stated inference, and it is a strong one: beyond the byte-identity requirement, the 5 m TTL (`promptCacheRequested: 5m`) is shorter than typical pass spacing (the A8 api critic alone ran 4,439 s, `results.md` §5). But Q-308 names only net cost and recall, so the cross-pass half of the "free" claim leaves the rubric as neither measured nor tracked.

**Recommendation:** Add one clause to the A8 cell or the cycle's follow-up: "cross-pass reuse: inferred 0 (byte-identity + 5 m TTL), not measured". No new run is needed unless the owner asks.

#### 4. The closure speaks in token counts; the claim it closes is about input cost

**Severity:** Low
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `runs/review-arms/a8-2026-11-19/cache-probe.md:93-94`; `skills/code-review/SKILL.md:352`
**Move:** Price the deployment environment
**Classification:** Micro (pricing weight per token) / Hot path
**Confidence:** Medium
**Legibility-target:** for-author
**Baseline:** 18,900 cache-read + 31,731 cache-write + 2 uncached input tokens on each probe agent's first call (probe-out.txt, 2026-11-19)

Evidence (`cache-probe.md:93-94`):
> "Cost of the probe: 2 × 50,685 = 101,370 tokens by the notified figure. Nearly all of that is the harness context every agent starts with, not the tail."

The skill's claim is "single-digit-% of input cost, 0% of token count" (`SKILL.md:352`), i.e. a billing-rate claim, but every figure in the closure is a raw count (`subagent_tokens` sums reads and writes at weight 1). The "benefit = 0" verdict holds under any weighting, so the conclusion is safe. The magnitude a reader weighs is not: at the cache multipliers I recall (write 1.25×, read 0.1× base input for a 5 m TTL — `[unverified — submitted as claim]`, not fetched; no egress), each first call is ≈41.6k base-input-equivalent rather than 50.6k, and the forgone saving is ≈2.2k × (1.25 − 0.1) × 7 siblings ≈ 17.6k equivalent per 8-agent Stage-1-sized pass (python3; uses the 2,189-token Stage-1 block estimate, `results.md:47-48`). That is ≈5% of first-call input cost — the same order as the August 5.3% projection. So the projection's size was plausible; it was the mechanism that failed. A reader seeing only counts may conclude the lever was always worth ~nothing, which matters if a different mechanism (Claim 4's byte-identical prompt) is weighed next.

**Recommendation:** In the probe doc or the cycle's follow-up, add one price-weighted line (with the multipliers marked unverified until a host check) so the lost saving and the gross cost are stated in the unit the skill's claim uses.

#### 5. "No prompt order" rests on breakpoint placement by the observed Claude Code version; nothing re-checks it

**Severity:** Informational
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:68-70`; `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Move:** Price the deployment environment (harness semantics as a performance input)
**Classification:** Macro / Hot path
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis
**Baseline:** breakpoints at `system[0]`, `system[1]`, `messages[1].content[3]` on both probe agents' first requests (probe-out.txt, 2026-11-19)

Evidence (`cache-probe.md:68-70`):
> "No. The Agent tool takes the prompt as one string and sends it as one content block. The breakpoints are placed by Claude Code on the system prompt and on the request's last block. The orchestrator controls neither."

The fact-check scopes Claim 11 to these records ("Does not establish Claude Code behaviour in other versions"), and r2+r3 note the third breakpoint moves to the last message on later calls. The rubric cell states the result categorically ("no prompt order puts a breakpoint at the block's end"). If a later harness splits the prompt into blocks or adds a breakpoint, lever #3 could start working with no one noticing, or keep failing after a re-design that assumed otherwise.

**Recommendation:** When the cycle files the skill correction, attach a revisit trigger: re-read one agent's first-request `cacheControl` paths after a Claude Code upgrade (the probe script already prints them).

#### 6. "Harness context, not the tail" leaves the shared block's own share unstated

**Severity:** Informational
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:93-94`
**Move:** Count the hidden multiplications
**Classification:** Micro / Cold path (one-off probe)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** 50,685 notified tokens per probe agent (fact-check Claim 9 Verified)

Evidence: as quoted in Finding 4. The prompt is 8,931 chars, of which the block is 8,755 (98%); at chars/4 the whole prompt is ≈2.2k tokens, ≈4.4% of 50,685 (python3). The sentence is accurate, but it contrasts the harness with "the tail" (a one-liner), not with the block, which is what a reader weighing lever #3 wants sized. Stated plainly, it is also the more useful performance fact: the fixed ≈48k per-agent harness context, written fresh at the cache-write rate by every sibling, is ~20× the lever's whole payload — the real per-agent cost, and the prize Claim 4 sizes at ~50.6k.

**Recommendation:** Optional: "the shared block is ≈2.2k of the 50.7k; the rest is harness context every agent writes fresh".

## Endorsements

- The probe isolates timing correctly: B's first request went out 28.5 s after A's reply, inside the 5 m TTL, with a prompt identical to A's up to one character in the tail, and B's cache read stayed at 18,900 `[fact-check: claim 9 — Verified]` `[fact-check: claim 10 — Verified]`.
- The "no prompt order" conclusion follows from the executed breakpoint layout and the single-block prompt, and does not depend on the unverified web caching rule `[fact-check: claim 11 — Verified]`.
- Within-run reuse of an agent's own prefix happens whether the block is inlined or self-read, so it is not a benefit attributable to lever #3 (`cache-probe.md:87-88`) `[unverified — submitted as claim]` (`runs/review-arms/a8-2026-11-19/cache-probe.md:87-88`; `results.md:67-71` reports the observation for inline only — no self-read arm was run).
- Closing on the benefit half while moving net cost and recall to an owner question keeps the closure from claiming more than one cell measured `[unverified — submitted as claim]` (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Probe mechanism voids A7's fix and `SKILL.md:347-351`; branch leaves both standing and the follow-up list omits them | Medium | `runs/review-arms/a8-2026-11-19/cache-probe.md:88-90`; rubric `:34`; research `:74-77` | High |
| 2 | `Split` closes A8 with no tracked item for the skill-text correction; Q-308 interim waits on a fix ruled out | Medium | rubric `:35`; research `:74-77`; `SKILL.md:352-354` | High |
| 3 | Cross-pass reuse untested and assigned to no unit | Low | `SKILL.md:274-276`; `cache-probe.md:88-90` | Medium |
| 4 | Closure in token counts; claim is about input cost (forgone ≈5% price-weighted, multipliers unverified) | Low | rubric `:35`; `cache-probe.md:93-94` | Medium |
| 5 | "No prompt order" is version-dependent; no revisit trigger | Informational | `cache-probe.md:68-70` | Medium |
| 6 | Block's own share of the 50,685 unstated | Informational | `cache-probe.md:93-94` | High |

## Overall Assessment

The measurement is sound and well isolated: the evidence supports "no cross-agent cache reads on the Agent-tool path, and no in-prompt order can create one" for the observed harness. The weakness is in what the closure leaves behind, not in the probe. The same mechanism that defeats lever #3 within a pass defeats A7's stable-parts-first ordering across passes, and the branch closes A8 while leaving A7 ✅ Fixed, `SKILL.md:347-354` unchanged, and the correction untracked. Q-308 covers the net-cost and recall runs but not the text, and its interim points at a fix the probe rules out. Both Mediums are fixable with one tracked follow-up (named in the A8 cell) that lists `SKILL.md:274-277`, `:347-351`, `:352-354` and row A7. No further profiling is needed to merge; a price-weighted line (Finding 4) needs a host check of the cache multipliers.

## Goal-Alignment Note

**Success criterion (verbatim):** "a performance-reviewer report saved at the output path below, structured per the performance-reviewer skill."

- **Answered:** all four focus questions (Data Flow section, items 1-4), with six findings, each carrying Severity, Location, Evidence, Confidence, Baseline and Legibility-target; endorsements tagged per the skill.
- **Out of scope:** editing the skill, Q-308 or rubric row A7 (outside the brief's doc list); re-filing fact-check Claims 1-7; verifying cache price multipliers (no egress).
- **Escalate:** (orchestrator) Findings 1 and 2 need one tracked follow-up before or at merge, covering `SKILL.md:274-277`, `:347-351`, `:352-354` and row A7; it joins the fact-check's existing Q-308 option-[2] escalation. (host check) The 1.25× / 0.1× cache multipliers in Finding 4 are from memory.
- **Questions / Decisions:** whether the follow-up should be a roadmap item cited in the A8 cell (my reading of `rubric.md:204`'s "tracked follow-up") or filed by the cycle in the same merge is the orchestrator's call.
