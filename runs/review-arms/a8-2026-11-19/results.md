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
outside this repo. Today's skill (`SKILL.md` last changed in 44724747; 82accdd7, its child,
touched only `references/rubric.md`), terminal pass: k=3 fact-check, 5 critics
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
remainder, ~97k (+27% of 359k), is per-agent growth. (The +26% in the table is a different
comparison: k=1-equivalent today, +111k against the 424,520 that includes the gap-fix.)

**How much of that growth lever #3 can account for.** The inlined shared block is 8,755 bytes
(≈2.2k tokens at bytes/4) in the Stage-1 prompts and 11,716 bytes (≈2.9k tokens, with the
fact-check summary) in the Stage-2 prompts: 3×2,189 + 5×2,929 ≈ 21.2k tokens over the 8 core
agents, **≈2.9% of the core total**. Against the baseline that is 2.9 to 4.4 points of each
agent's growth (about 4 points overall). Skill-text growth since 2026-08-06 adds ≈2.9k
(code-fact-check), 2.6k (security), 0.8k (performance) and under 0.3k (the other three) per
agent. Each critic grew 10.5k to 25.4k tokens, so about 7.4k to 19.9k per critic is explained
by neither. Candidates are more reading and output, and a larger harness-injected context.
Every agent's first call already holds ~52k tokens before it does any work: 18.9k cached
(system prompt and tools), ~3k of my prompt, and a remainder of ~30k that the transcripts
record as attachments (instruction files, skill listing, environment) without per-part
token counts. I found no transcripts from the August run to split its figures the same way.

## 2. Delivery mode and the 25k budget

- Delivery mode: **inline** (diff + enclosing files + PR intent + rules; Stage 2 adds the
  fact-check summary). Shared block 2.2k / 2.9k tokens against the 25k budget: 9% / 12% of it.
- Byte-identity held: the shared part of every prompt hashes the same (Stage 1:
  `be4a2600985537d5` ×3; Stage 2: `42374933a2ebe4a1` ×5, equal to `csp/shared-block-stage2.md`).
- **No agent read the shared block from another agent's cache.** Each agent's first call read
  exactly 18,900 cached tokens (system prompt + tools, common to every agent) and wrote
  32.8k-33.8k fresh, shared block included. This held for all 9 agents. (From its second call
  on, each agent re-reads its own prefix from cache, block included; that happens with or
  without inlining.) So the benefit the "leave it on" line expects (agents 2..N reading the
  shared block at the cache-read rate) was **0** in this pass.
- **Why: the request records point to where the cache breakpoints sit.** Every agent's first
  request carries three breakpoints: `system[0]`, `system[1]` and `messages[1].content[3]`,
  the end of the first user turn, after the per-agent tail. No cache entry ever ends at the
  shared block's last byte, so a sibling has nothing to match there. Timing does not explain
  it. r3's first call returned about 5.5 s after r1's and r2's and still read only 18,900. The
  Stage 2.5 agent shares the first 8,745 characters with the api critic, whose last call came
  59 s before Stage 2.5's first, well inside the 5-minute cache lifetime, and it too read
  18,900. I did not read API documentation on prefix matching inside one content block, so
  this explanation is an inference from the records, not a confirmed mechanism.
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
rich-brief rule asks, and does not name `exportGraph.ts`. But two of its lines point down the
routes to labelled findings: "check the client-side code in the repo that would run under
it" (the route to R1) and "(does anything read it?)" about `x-nonce` (the route to A1). A
brief written without the labels might have been less pointed.

For whoever re-scores. r3's executed run shows the nonce **does** reach Next's scripts on
self-hosted `next start` (15/15 tags carry it), through the router copying response headers
onto the request. The A1 label's "Next.js can't extract the nonce" holds only where that copy
is absent, which is unconfirmed on Vercel. Beyond the six labels, the pass re-found two
items the ledger already holds. Security's `Purpose: prefetch` finding (🟡 A2) is canon N1,
real and fix-confirmed at `ab4dbdb` (`docs/working/canon-issue-ledger.md:176-177`). The
pdf.js `worker-src` finding (🟡 A4, worker half) is canon N7, which E7r2 refuted with spec and
WPT evidence (`:185-189`). It counts as a known false positive: the rubric's A4 should not be
credited.

## 4. Verdict on A8's claim

From one cell, the claim splits. **The benefit the claim counts on did not appear.** No
agent read the shared block from another agent's cache, so the within-pass saving the skill
describes ("single-digit-% of input cost") was 0 here, not small. The request records
suggest this is structural on the Agent-tool path (§2), not bad luck. That would make it hold
for every parallel pass, though one cell cannot confirm it. **The cost side cannot be told
net.** The gross addition is the block itself, 2.2k-2.9k tokens per agent (≈2.9% of core).
On a 2-file diff a self-reading agent would likely read the same two files anyway, but this
pass had no self-read arm to show the net. **"Zero effect on recall" cannot be told:** recall
rose (6/6), but too many things changed at once. Per-agent growth since August is +15% to
+40% (architecture +15%, fact-check replicate mean +40%). The inlined block is about 3 to 4
of those points; the rest is not attributable from this run. Reuse across loop passes was not
exercised, since this was one terminal pass. **Verdict: the "leave it on because it is free"
claim fails on its benefit:** zero within this pass. Its cost is small in gross terms and
unmeasured net. One cell cannot tell how either scales.

Three things would tell. First, a two-agent cache probe: same shared block, dispatched one
after the other within 5 minutes, comparing first-call `cache_read_input_tokens`. If the read
stays at 18.9k, that confirms the breakpoint reading of §2 and lever #3 is inert on this
path. If it rises by about the block size, timing was the cause after all. Second, a self-read control arm on this same cell under
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
- The ledger's `tool_uses` values are the task notifications' figures. Each is one less than
  the transcript's tool-call count, on every row. Replicate r2's verdict string in the ledger
  copies its report header (14 claims, 5V), whose body has 15 verdicts with 6 Verified.
- Reviewing this write-up (3 fact-check replicates over these docs) cost 488,455 tokens,
  outside the measured pass.
