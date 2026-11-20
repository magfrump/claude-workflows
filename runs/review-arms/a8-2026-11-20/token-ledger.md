# A8 settling runs: token ledger (csp self-read, then corpus inline; 2026-11-19/20)

Tokens = `subagent_tokens` from each Agent task notification, the field the 2026-08-06
baseline and the first A8 pass (`runs/review-arms/a8-2026-11-19/token-ledger.md`) report. The
first pass checked it equals the agent's last API call (input + cache creation + cache read +
output). One row per dispatched agent, appended when its notification arrived
(`docs/working/review-canon.md` §3). Brief stop line: 2.5M tokens over both passes.

## Pass 1: csp, self-read delivery

| # | Stage | Agent | Model | tokens | tool_uses | duration | outcome |
|---|---|---|---|---|---|---|---|
| 1 | Stage 1 fact-check | r1 | opus | 103,630 | 13 | 227 s | 10V/3MA/0S/6I/3U (22 claims; static, no node_modules found) |
| 2 | Stage 1 fact-check | r3 | opus | 109,582 | 19 | 233 s | 5V/2MA/0S/6I/2U (15 claims; static, read Next 16.2.4 source in cc-review-eval/mfc-csp) |
| 3 | Stage 1 fact-check | r2 | opus | 122,438 | 31 | 334 s | 14V/2MA/0S/6I/2U (24 claims; executed vitest 221/221 + eslint; Next source read statically) |
| — | Stage 1 subtotal | 3 replicates | | 335,650 | 63 | | first pass (inline) 311,975 |
| 4 | Stage 2 critic | test-strategy | opus | 77,354 | 7 | 113 s | advisory: 9 gaps G1-G9 (G1 directive list unpinned, G3 CSP not on forwarded request, G7 connect-src export) |
| 5 | Stage 2 critic | architecture | opus | 86,385 | 7 | 127 s | 0 Structural / 2 Coupling (nonce via router header copy; one policy constrains export + pdf.js + inline styles) / 3 Minor / 2 Info |
| 6 | Stage 2 critic | performance | opus | 79,122 | 6 | 96 s | 1 Medium (await headers() drops static prerender of /) / 2 Info; 2 submitted claims |
| 7 | Stage 2 critic | api-consistency | opus | 84,931 | 10 | 151 s | 2 Breaking (connect-src blocks export fetch(dataUrl); CSP not on request) / 3 Minor / 2 Info; 3 routed claims |
| 8 | Stage 2 critic | security | opus | 108,306 | 14 | 268 s | 1 Medium (CSP only on response; nonce via router copy, E1) / 3 Low (no form-action; matcher gaps incl. prefetch and /apiary; connect-src export at Low) / 3 Info; 2 routed claims |
| — | Stage 2 subtotal | 5 critics | | 436,098 | 44 | | 4 baseline-comparable critics (sec, perf, api, arch) = 358,744; first pass (inline) 431,780 / 352,090 |
| — | **Core total** (Stage 1 + Stage 2) | 8 agents | | **771,748** | | | first pass (inline) 743,755 |
| 9 | Stage 2.5 submitted claims | fact-check k=1 | opus | 126,985 | 37 | 547 s | 8 entries (S3 split): 6V (4 executed) / 1MA / 1I (perf "constant work" refuted, executed) |
| — | **Pass 1 all agents** | 9 agents | | **898,733** | | | first pass (inline) 852,285 |

## Pass 2: corpus, inline (skill as written)

| # | Stage | Agent | Model | tokens | tool_uses | duration | outcome |
|---|---|---|---|---|---|---|---|
