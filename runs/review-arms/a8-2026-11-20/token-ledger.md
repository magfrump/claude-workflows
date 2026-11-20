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
