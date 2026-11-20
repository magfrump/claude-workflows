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
| 1 | Stage 1 fact-check | r3 | opus | 139,167 | 14 | 332 s | 9V/4MA/2S/5I/2U (22 claims; ran manifest/paths/types under node --experimental-strip-types) |
| 2 | Stage 1 fact-check | r1 | opus | 149,652 | 13 | 351 s | 15V/3MA/2S/8I/5U (33 claims; ran paths/manifest/types/opfsAdapter under node --experimental-strip-types) |
| 3 | Stage 1 fact-check | r2 | opus | 146,785 | 19 | 384 s | 12V/6MA/2S/9I/6U (35 claims; ran manifest/paths/opfsAdapter with stubbed navigator.storage) |
| — | Stage 1 subtotal | 3 replicates | | 435,604 | 46 | | baseline corpus fc (k=1) 93,966 |
| 4 | Stage 2 critic | performance | opus | 104,995 | 11 | 137 s | 1 Medium (corpus setItem: no debounce, unordered full-blob writes) / 1 Low (quota: no backoff; close() masking) / 1 Info; 1 submitted claim |
| 5 | Stage 2 critic | test-strategy | opus | 108,020 | 7 | 146 s | advisory: 15 gaps G1-G15 (G1 OPFS success path never runs; G7/G8 manifest filters; G12 flag-on rehydrate migrateFromV2) |
| 6 | Stage 2 critic | tech-debt-triage | opus | 106,520 | 9 | 161 s | advisory: TD1-TD7 (TD1 contract never run on OPFS; TD2 manifest; TD4 migrateFromV2; TD5 stale comments; TD7 paths.ts unused) |
| 7 | Stage 2 critic | architecture | opus | 119,906 | 10 | 195 s | **1 Structural** (workspaceStore.ts:528-541 rehydrate reads localStorage, migrateFromV2 overwrites OPFS state) / 2 Coupling / 3 Minor / 1 Info |
| 8 | Stage 2 critic | security | opus | 123,116 | 10 | 211 s | 1 Medium (dev-only flag enableable in production) / 4 Low (rehydrate migrateFromV2; unawaited/unordered writes; close() masks quota; slug collisions) / 2 Info; 3 routed claims |
| 9 | Stage 2 critic | api-consistency | opus | 135,606 | 16 | 292 s | 0 Breaking / 6 Inconsistent (F1 manifest not fail-loud; F2 bare Error vs CorpusError; F3 custom-type path vs DD-009; F9 rehydrate bypass) / 4 Minor (incl. F10 state/ path outside paths.ts) / 2 Info; 3 routed claims |
| — | Stage 2 subtotal | 6 critics | | 698,163 | 63 | | baseline corpus 6 critics 521,600 |
| — | **Core total** (Stage 1 + Stage 2) | 9 agents | | **1,133,767** | | | baseline corpus core 615,566 (7 agents) |
| 10 | Stage 2.5 submitted claims | fact-check k=1 | opus | 139,180 | 20 | 386 s | 7 claims: 4V / 3MA / 0I (6 executed, zustand 5.0.13 from mfc-corpus) |
| — | **Pass 2 all agents** | 10 agents | | **1,272,947** | | | |

## Both passes

| | agents | tokens |
|---|---|---|
| Pass 1 csp self-read | 9 | 898,733 |
| Pass 2 corpus inline-diff-only | 10 | 1,272,947 |
| **Total** | **19** | **2,171,680** (stop line 2.5M not reached) |

Instrument check: for every agent of both passes, the notified figure equals the transcript's last API call (input + cache creation + cache read + output), and every first call read exactly 18,900 cached tokens (system prompt and tools).
