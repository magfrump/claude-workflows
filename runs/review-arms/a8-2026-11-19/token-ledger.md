# A8 token ledger (csp, one terminal pass, today's code-review skill)

Tokens = `subagent_tokens` from each Agent task notification (the field the 2026-08-06
baseline and E1/E3 report; I assume the same harness definition). One row per dispatched agent, appended when its notification arrived
(review-canon.md §3). Shared block: `csp/shared-block.md`, 8,755 bytes ≈ 2,189 tokens (bytes/4),
delivery mode `inline`.

| # | Stage | Agent | Model | tokens | tool_uses | duration | outcome |
|---|---|---|---|---|---|---|---|
| 1 | Stage 1 fact-check | r2 | opus | 90,196 | 9 | 484 s | 5V/0MA/0S/7I/2U |
| 2 | Stage 1 fact-check | r1 | opus | 100,755 | 13 | 488 s | 6V/4MA/0S/5I/2U |
| 3 | Stage 1 fact-check | r3 | opus | 121,024 | 35 | 504 s | 11V/2MA/0S/4I/2U (executed: next build/start + curl in its own scratch copy) |
| — | Stage 1 subtotal | 3 replicates | | 311,975 | 57 | | merged by orchestrator (not an agent): 18 claims, 5V/3MA/7I/3U, agreement 9/17 |
| 4 | Stage 2 critic | performance | opus | 78,987 | 5 | 106 s | 1 Medium (await headers() drops static prerender/cache for /) / 1 Low (404 dynamic) / 1 Info; 1 submitted claim |
| 5 | Stage 2 critic | architecture | opus | 81,399 | 6 | 117 s | 0 Structural / 2 Coupling (nonce via router-internal header copy; CSP silently constrains export + pdf.js) / 3 Minor / 1 Info |
| 6 | Stage 2 critic | test-strategy | opus | 79,690 | 8 | 131 s | advisory: 9 gaps G1-G9 (incl. G1 directive list unpinned, G3 CSP on request, G8 connect-src export) |
| 7 | Stage 2 critic | security | opus | 103,326 | 9 | 244 s | 1 Medium (Purpose: prefetch gets CSP-less HTML) / 2 Low (E1 nonce via request header; no form-action) / 7 Info (incl. E2 connect-src export at Info); 3 routed endorsement claims |
| 8 | Stage 2 critic | api-consistency | opus | 88,378 | 7 | 4,439 s (wall clock; 7 tool uses) | 1 Breaking (connect-src export + worker) / 2 Inconsistent (x-nonce contradiction; nonce via router copy) / 1 Minor / 2 Info; 2 routed claims |
| — | Stage 2 subtotal | 5 critics | | 431,780 | 35 | | parallel, one message; 4 baseline-comparable critics (sec, perf, api, arch) = 352,090 |
| 9 | Stage 2.5 submitted claims | fact-check k=1 | opus | 108,530 | 17 | 252 s | 7 entries: 5V (3 executed) / 1MA / 1U / 0I |
| — | **Core total** (Stage 1 + Stage 2) | 8 agents | | **743,755** | | | baseline csp core 358,626 (5 agents) / 424,520 with test-strategy gap-fix |
| — | **All agents** (+ Stage 2.5) | 9 agents | | **852,285** | | | under the brief's 2M stop line |

Instrument check: for every agent, the notified figure equals its transcript's last API call
(input + cache_creation + cache_read + output). First-call cache read was 18,900 tokens on all
9 agents: system prompt and tools only; no agent read the inlined shared block from another
agent's cache (each re-reads its own prefix from its second call on).
