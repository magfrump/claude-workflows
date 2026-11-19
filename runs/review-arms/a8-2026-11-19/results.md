# A8 results: one terminal code-review pass on the csp cell (2026-11-19)

Brief: `docs/working/briefs/2026-11-19-a8-token-measurement.md`. Method and deviations:
`docs/working/research-2026-11-19-a8-token-measurement.md`. Per-agent rows: `token-ledger.md`;
totals: `manifest.json`; review artifacts: `csp/`.

**What A8 is.** Row A8 of `docs/reviews/code-review-rubric-2026-08-07-main.md` says the
code-review skill's claim about inlining the shared review context (decision 032 lever #3:
"zero effect on recall", "0% of token count", "leave it on because it is free",
`skills/code-review/SKILL.md:276-354`) rests on a pre-restructure projection (~5.3% of input
cost, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md`), and that inlining
adds prompt tokens each agent used to fetch selectively.

**Cell and setup.** csp (the brief's default; no reason to pick another), range
`d86d2dc..d90d6bb` of meta-formalism-copilot, checked out at `d90d6bb` in a scratch worktree
outside this repo. Today's skill (82accdd7), terminal pass: k=3 fact-check, 5 critics
(security, performance, api-consistency, architecture, test-strategy; ui-visual not selected,
as in the baseline), Stage 2.5 for 6 routed endorsement claims, rubric synthesized inline.
All agents on opus. Running total peaked at 852,285 tokens, under the brief's 2M stop line.

## 1. Cost against the baseline, split so k=3 is not read as lever #3

Instrument: `subagent_tokens` from each task notification (same field as the baseline). I
checked it against the agents' transcripts: for all 9 agents it equals the **last API call's**
input + cache-creation + cache-read + output tokens. It measures the final context size, not
the tokens processed over the agent's run.

| Slice | Today | Baseline 2026-08-06 | Change |
|---|---|---|---|
| Fact-check, total | 311,975 (k=3: 100,755 / 90,196 / 121,024) | 74,274 (k=1) | ×4.20 |
| Fact-check, per replicate (mean) | 103,992 | 74,274 | +40% |
| 4 baseline-comparable critics (sec, perf, api, arch) | 352,090 | 284,352 | +23.8% |
| — security / performance / api / architecture | 103,326 / 78,987 / 88,378 / 81,399 | 77,879 / 67,010 / 68,604 / 70,859 | +33% / +18% / +29% / +15% |
| test-strategy (first wave today; gap-fix in the baseline) | 79,690 | 65,894 | +21% |
| **Core total (fact-check + critics)** | **743,755** (8 agents) | **358,626** per-cell figure (5 agents); 424,520 with the gap-fix | ×2.07 / ×1.75 |
| Core at k=1-equivalent (mean replicate + same 5 critics) | 535,772 | 424,520 | +26% |
| Stage 2.5 submitted claims (did not exist in August) | 108,530 | — | outside core |
| All agents | 852,285 (9) | — | |

Of the +385k core increase over the 359k per-cell figure, about 208k is k=3 (two extra
replicates at the mean), about 80k is test-strategy now running in the first wave, and the
remainder (~97k, +26% at k=1-equivalent) is per-agent growth.

**How much of that growth lever #3 can account for.** The inlined shared block is 8,755 bytes
(≈2.2k tokens) in the Stage-1 prompts and 11,716 bytes (≈2.9k tokens, with the fact-check
summary) in the Stage-2 prompts: 23.4k tokens over the 8 core agents, **≈3% of the core
total**. Skill-text growth since 2026-08-06 adds ≈2.9k (code-fact-check), 2.6k (security),
0.8k (performance) and under 0.3k (the other three) per agent. Each critic grew 10.5k to 25.4k
tokens, so 5k to 20k per agent is explained by neither. Candidates are more reading and
output, and a larger harness-injected context. Every agent's first call already holds ~52k
tokens before it does any work: 18.9k of system prompt and tools, ~30k of injected session
context and ~3k of my prompt. The August run left no transcripts to split this the same way.

## 2. Delivery mode and the 25k budget

- Delivery mode: **inline** (diff + enclosing files + PR intent + rules; Stage 2 adds the
  fact-check summary). Shared block 2.2k / 2.9k tokens against the 25k budget: 9% / 12% of it.
- Byte-identity held: the shared part of every prompt hashes the same (Stage 1:
  `be4a2600985537d5` ×3; Stage 2: `42374933a2ebe4a1` ×5, equal to `csp/shared-block-stage2.md`).
- **The cache never served the shared block.** Each agent's first call read exactly 18,900
  cached tokens (system prompt + tools, common to every agent) and wrote 32.8k-33.8k fresh,
  shared block included. This held for all 9 agents. It held for the five parallel critics,
  and for the Stage 2.5 agent too, which was dispatched alone long after Stage 1 with the same
  first 8.7k characters. So the benefit the "leave it on" line expects (agents 2..N reading
  the shared block at the cache-read rate) was **0** in this pass. Two explanations fit, and
  this run cannot tell them apart. One: parallel dispatch, since no sibling's cache entry
  exists yet when the others' first calls go out. Two: there is no cache breakpoint at the end
  of the shared block, because block and tail are one prompt, and a prefix can only hit at a
  breakpoint. Stage 2.5 rules out the first as the only cause, but its gap from Stage 1 also
  exceeded the default 5-minute cache lifetime.
- csp says nothing about the budget's upper edge: its block is tiny. The baseline's largest
  cell (corpus, ~17.4k tokens of diff + fact-check) is the one that would test it.

## 3. Labels hit against the canon

Canon csp labels: `docs/working/canon-issue-ledger.md:92-97` (2 red, 4 amber).

| Label | Today | Baseline |
|---|---|---|
| R1 `connect-src 'self'` blocks `fetch(data:)` in `exportGraph.ts` (gold) | **HIT**, 🔴 R1 (api Breaking + fact-check 3/3 Incorrect high; also arch, sec, test G8) | HIT, graded security Medium 🟡 |
| R2 Edge-runtime comment (Node.js in Next 16) | **HIT**, 🟡 A6 (fact-check 3/3, r3 executed) | miss |
| A1 CSP only on the response; dead `x-nonce` plumbing | **HIT**, 🟡 A1 + A8 (arch Coupling, api Inconsistent, fc) | HIT (arch Structural 🔴) |
| A2 `style-src 'unsafe-inline'` misattributed to Tailwind v4 | **HIT**, 🟡 A7 (fact-check 3/3, r3 executed) | partial (ledger: unfound by any arm before) |
| A3 `await headers()` comment misstates why | **HIT**, 🟡 A5 (fact-check 3/3) | HIT (perf, as dynamic-render cost) |
| A4 no tests pin the CSP directive list | **HIT**, 🟢 C6 (test-strategy G1) | HIT (gap-fix only) |

6/6 hit, against 4 hits + 1 partial in the baseline. This is not evidence about lever #3: k=3,
today's skill texts, Stage 2.5 and one replicate's executed build all changed together, and it
is one draw. One threat to validity: I, the orchestrator, knew the canon labels before writing
the fact-check's "claims that particularly need checking" list. The list names every
comment claim in the diff (Edge, Tailwind and connect-src among them), as the skill's
rich-brief rule asks. It does not name `exportGraph.ts` or any finding. A brief written
without the labels might still have been less pointed.

New since the canon, for whoever re-scores: r3's executed run shows the nonce **does** reach
Next's scripts on self-hosted `next start` (15/15 tags carry it), through the router copying
response headers onto the request. The A1 label's "Next.js can't extract the nonce" holds only
where that copy is absent, which is unconfirmed on Vercel. Two findings are new: security
found that `Purpose: prefetch` requests get HTML with no CSP (🟡 A2), and the pdf.js worker may
be blocked because there is no `worker-src` (🟡 A4).

## 4. Verdict on A8's claim

From one cell, the claim splits. **"Free" holds roughly, but it is not 0%.** Inlining put
2.2k-2.9k tokens into each agent's context, about 3% of the core total. On a 2-file diff a
self-reading agent would likely read the same two files anyway, so the net token-count cost
is probably near zero, but this pass had no self-read arm to show it. **The benefit the claim
counts on did not appear.** No agent read the shared block from cache, so the cost-side
saving (single-digit percent of input cost) was 0 here, not small. **"Zero effect on recall"
cannot be told:** recall rose (6/6), but too many things changed at once. The +24-40%
per-agent growth since August is real. Lever #3 accounts for at most 3 of those points. The
rest is not attributable from this run. **Verdict: fails as stated.** The lever's benefit was
0 here and its token-count effect was small but not zero. One cell cannot tell how either
scales.

Three things would tell. First, a two-agent cache probe: same shared block, dispatched one
after the other within 5 minutes, comparing first-call `cache_read_input_tokens`. If the read
stays at 18.9k, the Agent-tool path has no breakpoint at the block's end and lever #3 is inert
there. If it rises by about the block size, parallel dispatch is the cause and a staggered
first agent would recover the saving. Second, a self-read control arm on this same cell under
today's skills, to separate the inline cost from the other drift. Third, the corpus cell, the
largest block at ~17.4k tokens, to test the 25k budget and the context-window trade it guards.

## 5. Run notes

- The api-consistency critic took 4,439 s of wall clock for 7 tool uses (the others took
  106-504 s). Its token figure is in line with the other critics (88,378). I did not
  investigate the wall-clock time; it does not enter the token figures.
- r3 and the Stage 2.5 agent ran code in a scratch copy with `node_modules` from
  `/workspace/external/cc-review-eval/mfc-csp` (fonts stubbed, no network). The baseline
  had no executed verdicts. Logs: `csp/fc-r3-logs/`, `csp/stage25-logs/`.
- No `tokens` map is empty: every agent's figure is in `manifest.json` and in `token-ledger.md`.
