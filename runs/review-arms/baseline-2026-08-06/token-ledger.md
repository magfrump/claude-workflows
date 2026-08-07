# Baseline token ledger (current 031+032 setup, single pass, k=1)

Tokens = subagent_tokens from task notifications (same instrument as E1/E3). Append as stages land.

## Stage 1 — fact-check (k=1, one replicate per cell) — COMPLETE

| Cell | tokens | tool_uses | verdicts | behavioral 🔴 under T? |
|---|---|---|---|---|
| deploy | 67,024 | 8 | 6V/1MA/2U | no (docs-only) |
| fscompat | 64,481 | 9 | 3V/1I/1U | no (I is dead doc ref → 🟡) |
| hygiene | 78,493 | 8 | 7V/1Stale | no (SSE JSDoc drift → 🟡) |
| lean | 90,355 | 11 | 12V/3MA | no (all comment/doc drift) |
| postfix | 87,118 | 15 | 7V/2U | no (clean) |
| secdeps | 72,034 | 12 | 5V/4MA/2U | no; 2 MA are **behavioral** guardrail gaps (react/no-danger=warn + no --max-warnings 0; trust:true selector misses string-key/fn-form) → 🟡 |
| corpus | 93,966 | 6 | 11V/3MA/1Stale/1I | no (I = ArrayBuffer comment → 🟡) |
| csp | 74,274 | 11 | 6V/2MA/1I/1U | no (I = nonce auto-tag lifecycle, comment/doc → 🟡; proxy x-nonce dead-plumbing = behavioral MA → 🟡) |
| **Stage-1 total** | **627,745** | | | k=1; ≈78k/cell |

Note: NO cell produced a fact-check behavioral 🔴 — every Incorrect(high) was comment/doc subject (→🟡 under tier policy T). On these reviewed states the behavioral labels come from the critic panel, not fact-check. (This is itself a baseline finding: fact-check's role on a reviewed state is doc-drift detection; T correctly routes all of it to amber.)

## Gating decisions (Stage 1.5, #1) — per cell

| Cell | candidates | RAN | SKIPPED (reason) |
|---|---|---|---|
| deploy | security, perf, api | — | ALL (copy-only md; zero domain evidence) |
| fscompat | sec, perf, api, arch | security, api-consistency, architecture | performance (no loop/query/data-struct/dep evidence) |
| hygiene | sec, perf, api, arch, test | security, api-consistency, architecture, test-strategy | performance (no perf-domain evidence) |
| lean | sec, perf, api, arch, ui, test | security, performance, api-consistency, architecture, ui-visual | test-strategy (diff adds its own tests) |
| postfix | sec, perf, api, arch, ui | security, performance, api-consistency, architecture, ui-visual | — (full panel) |
| secdeps | sec, perf, api, arch, dep | security, dependency-upgrade, architecture | performance + api-consistency (config-only, no perf/public-API surface) |
| corpus | sec, perf, api, arch, techdebt, test | security, performance, api-consistency, architecture, tech-debt-triage, test-strategy | — (full panel; large diff) |
| csp | sec, perf, api, arch, ui | security, performance, api-consistency, architecture | ui-visual (tsx change is header/nonce plumbing, no visual/layout code) |

Gating skipped 3 whole critics on deploy + 1 each on fscompat/hygiene/lean/csp + 2 on secdeps = **9 critic-agents skipped** vs the ungated full candidate panel. That saving IS the #1 measurement.

## Stage 2 — critics (append as they land)

| Cell | critic | tokens | result (severity → rubric) |
|---|---|---|---|
| fscompat | api-consistency | 68,686 | 0 breaking / 1 minor / 2 info → 🟢 |
| fscompat | security | 67,357 | 0 high / 2 low / 1 info → 🟢 (dataDir no containment guard, preventive) |
| fscompat | architecture | 67,988 | 0 structural / 2 green → 🟢 (clean centralization) |
| hygiene | security | 79,360 | 0 high / 1 low / 2 info → 🟢 (egress asymmetry: non-stream path still forwards provider body) |
| hygiene | api-consistency | 71,770 | 0 breaking / 1 Inconsistent (SSE JSDoc details, doc-only) → 🟡/🟢 |
| hygiene | architecture | 82,451 | 0 structural / 1 Coupling → 🟡 (stream vs non-stream details asymmetry) / 2 green |
| hygiene | test-strategy | 74,669 | advisory: 6 Consider → 🟢 |
| csp | performance | 67,010 | 0 high / 1 Medium / 1 Low → 🟡/🟢 (await headers() app-wide dynamic render) |
| csp | api-consistency | 68,604 | 0 breaking / 1 Inconsistent (x-nonce contract no consumer) → 🟡 |
| csp | architecture | 70,859 | **1 Structural 🔴** (proxy.ts:37-47 + layout.tsx:22-31 nonce pipeline composed but not wired end-to-end) / 1 Coupling 🟡 / 1 minor |
| lean | security | 75,261 | 0 high / 1 low / 1 info → 🟢 (net security improvement; fail-closed unavailable) |

| lean | performance | 74,439 | 0 high / 1 low / 2 info → 🟢 (retry bails on unavailable; Re-verify+35s abort DoS-ish Low) |
| secdeps | security | 67,621 | **1 High** (react/no-danger=warn, no --max-warnings 0 → dangerouslySetInnerHTML not blocked) / 1 med / 1 low / 1 info |
| secdeps | architecture | 68,420 | 0 structural / 3 Coupling 🟡 (guardrail coherence gap) / 1 minor |
| secdeps | dependency-upgrade | 62,731 | 0 blocking / 1 med (lodash minor mislabeled "patch") / 2 low → 🟢 advisory |
| postfix | ui-visual | 71,503 | 0 blocking / 1 info (orphan mt-1 margin) → 🟢 |
| postfix | performance | 72,884 | 0 high / 2 info → 🟢 |

| lean | ui-visual | 77,322 | advisory: 3 Consider (amber/red hue distinction) → 🟢 |
| postfix | security | 74,086 | 0 high / 1 Low (NODE_ENV eval gate fails open for non-"production") / 1 info → matches postfix A1 fail-open class |

| postfix | api-consistency | 74,000 | 0 breaking / 2 info → 🟢 (buildCsp allowUnsafeEval backward-compatible) |

| lean | architecture | 81,011 | 0 structural / 1 Coupling 🟡 (hand-encoded status subsets) / 2 minor |

| postfix | architecture | 77,825 | 0 structural / 1 Coupling 🟡 (debounce dup evidenceStore↔storeAdapter, pre-existing) / 1 minor / 1 info |
| corpus | tech-debt-triage | 76,227 | advisory: 6 Consider → 🟢 (dup path-safety, dead code, stale docstrings, silent manifest filter) |

| lean | api-consistency | 97,116 | 0 breaking / 3 Inconsistent 🟡 (reason/detail dropped; detail vs details naming; unavailable→none collapse) / 1 minor / 2 info |

| corpus | performance | 82,991 | 1 High 🟡 (storeAdapter.ts:52-68 corpus path drops write debounce — full-blob OPFS write per change; gated behind default-off flag) / 2 low / 1 info |

| corpus | security | 94,922 | 0 high / 1 Medium 🟡 (workspaceSlug many-to-one → title collisions before S4) / 1 low / 2 info |

| corpus | test-strategy | 88,089 | advisory: 15 Consider → 🟢 (residual branch gaps; G15 writeFile aliasing hides fake-vs-OPFS divergence) |
| corpus | architecture | 87,879 | **1 Structural 🔴** (workspaceStore.ts:528-543 rehydration seam bypasses CorpusFS → migrateFromV2 re-fires on wrong substrate = write-through data-loss; gated default-off) / 1 Coupling / 1 minor |

| corpus | api-consistency | 91,492 | 0 breaking / 2 Inconsistent 🟡 (paths.ts bare Error bypasses CorpusError contract; manifest docstring advertises unthrown kind) / 1 minor / 2 info |

| csp | security | 77,879 | 2 Medium 🟡 (nonce never on request CSP → strict-dynamic blocks Next scripts, control inert; **connect-src 'self' blocks fetch(data:) in exportGraph.ts:24,37 — the cross-file GOLD defect, canon csp R1**) / 1 low (x-nonce dead) / 1 info |

**Stage-2 critics total = 2,292,452 tokens / 29 critic agents. Stage-1 = 627,745. Core pipeline (fact-check + critics) = 2,920,197 tokens across 37 agents.** (Rubric synthesis done inline by orchestrator, not a separate measured subagent stage; E1's rubric stage was ~90–160k/cell → a fully-agentized run would add ~0.8–1.3M.)
