# Baseline results — current 031+032 full pipeline over the whole canon (2026-08-06)

**Setup**: k=1 fact-check (031) + Stage-1.5-gated critic panel (032 #1) + rich shared brief
(029) + Stage-1 context / commit-pinned worktrees (021), **single pass, no fix loop**. This
is the cost + recall baseline the 032 H3 ≥15% claim and future loop runs measure against.
Method mirrors E1 (per-agent tokens from task notifications; artifacts stamped with commit SHA;
`manifest.json` + `token-ledger.md` ledgers). Scoring is adjudicate-against-code (anti-SWR-Bench);
label reference = `review-canon.md` v1 + the per-instance breakdown in `review-arm-ideas-2026-08-06.md` / E2.

## 1. Cost (measured subagent tokens)

| Stage | tokens | agents | notes |
|---|---|---|---|
| Stage 1 — fact-check (k=1) | 627,745 | 8 | ~78k/cell; **⅔ cheaper than k=3** would be (~1.9M) |
| Stage 2 — critics (gated) | 2,358,346 | 30 | see per-cell ledger (incl. csp test-strategy gap-fix) |
| **Core pipeline total** | **2,986,091** | **38** | fact-check + critics |
| Stage 3 — rubric | inline | — | synthesized by orchestrator; E1's agentized rubric was ~90–160k/cell → a fully-agentized run adds ~0.8–1.3M |

- **Gating (#1) skipped 9 critic-agents** vs the full candidate panel — deploy (3: all core), fscompat/hygiene (1 perf each), lean (1 test), secdeps (2: perf+api), csp (1 ui-visual) — a measured saving of ~0.6M tokens (≈9×~70k), concentrated on the copy-only/config cells. On genuine code cells gating skipped little, which is correct: #1 only removes signal-less critics.
- **Per-cell core cost** (fc+critics): deploy 67k (fact-check only — the gating win), fscompat 271k, hygiene 386k, secdeps 271k, csp 359k, postfix 458k, lean 495k, corpus 616k. Cost tracks **critic-count × diff size**, findings-independent (reconfirms E1).

## 2. Recall vs canon labels (adjudicate-against-code)

| Cell | labels (R/A) | reds hit | ambers hit | headline |
|---|---|---|---|---|
| **csp** | 2R/4A | **R1 gold connect-src/`data:` HIT** (security Medium); R2 Edge-runtime doc **miss** | A1 nonce-dead-plumbing HIT (arch **Structural 🔴** + api + fc); A3 await-headers dynamic-render HIT (perf Medium); A2 style-src partial; A4 test-strategy HIT (gap-fix, 6 gaps incl. nonce/CSP propagation) | **Caught the gold R1 the E2 lite arm missed** — Stage-1 enclosing-file context read `exportGraph.ts` (outside the diff) |
| **secdeps** | 1R/1A | R1 no-danger=warn guardrail inert **HIT** (security **High** + fc + arch) | A1 trust:true selector gaps **HIT** (fc MA + arch coupling) | both labels hit; guardrail-fails-loudly caught 3 ways |
| **corpus** | 0R/4A | (E1 corpus-dirty carried 4 structural R) rehydration-seam **HIT** (arch **Structural 🔴**, matches E1 R1) | A1 slug-collision (security Med), A2 bare-Error/CorpusError (api), A3 stale docstrings (tech-debt), A4 manifest silent-drop (tech-debt) — **all 4 HIT** + a new perf-High (debounce drop) | strongest cell; caught the structural seam defect + full amber cluster |
| **postfix** | 1R/8A | R1 fail-open NODE_ENV eval gate **HIT** (security Low) | partial (orphan-margin, debounce-dup, buildCsp) | R1 surfaced (graded Low vs canon amber) |
| **hygiene** | 1R/1A | R1 SSE JSDoc `{error,details}` drift **HIT** (fc Stale + api Inconsistent) | A1 logging asymmetry — **HIT-adjacent** (security Low + arch Coupling found the stream/non-stream `details` egress asymmetry) | both hit |
| **lean** | 2R/1A | R2 non-2xx body-discard partial (api Inconsistent on reason/detail); **R1 stale README/ARCHITECTURE docs miss** (cross-file, docs outside diff) | A1 client drops reason/detail **HIT** (api Inconsistent + arch minor) | A1 + partial R2; cross-file doc red missed |
| **fscompat** | 1R/4A | R1 dangling cross-branch README ref **HIT** (fc Incorrect) | A1–A4 (Vercel-model reasoning / convention survey / test) **mostly miss** — not in-diff-derivable | R1 hit; reasoning-class ambers need repo-wide context |
| **deploy** | 2R/0A | R1+R2 both **miss** (fact-check-only cell; docs verified accurate against code) | — | **gating trade-off**: docs-only diff → all critics skipped (67k) but the 2 cross-file behavioral reds went unadjudicated (see §4) |

**Red-recall headline**: the full pipeline surfaced a behavioral red in **7 of 8 cells** (all but deploy), including two that E2's cheap lite arm structurally could not reach — **csp's gold connect-src/`data:` defect** and **corpus's rehydration-seam structural red** — both caught only because Stage-1 context fed the critics the enclosing files outside the diff. This is the concrete evidence for why the expensive pipeline exists: cross-file reds are its differentiator over diff-only lite review.

## 3. Where reds landed by tier under policy T (031)

- Fact-check produced **zero behavioral 🔴** — every Incorrect(high) was comment/doc subject → 🟡 under T (as designed). On a reviewed state, fact-check is a doc-drift detector; T routes it to amber correctly.
- All behavioral 🔴 came from **critics**: architecture-review Structural (csp nonce pipeline, corpus rehydration seam) and security High (secdeps guardrail). The gold csp connect-src defect landed at security **Medium → 🟡**, not 🔴 — a **severity-calibration gap**: a real XSS-control-defeating + export-breaking defect graded Medium. Worth noting for tier policy (the finding is correct; the severity is light).

## 4. Threats to validity / run caveats (honest)

1. **csp under-selected test-strategy (resolved).** csp's initial candidate set omitted test-strategy though proxy.ts/layout.tsx changed with no test file. Caught during scoring and **dispatched as a gap-fix** (65,894 tokens; canon csp A4 now HIT). Lesson for the orchestrator: source-without-tests must trigger test-strategy at Step-5 selection even when a security/architecture story dominates the diff. Totals above include the gap-fix.
2. **deploy gating trade-off is real.** Skipping all critics on the docs-only diff saved ~0.2M but left deploy's 2 cross-file behavioral reds unadjudicated — the fact-check verified the deploy-doc claims against code (6V) and did not flag them. Either the canon reds are contestable or fact-check-only is too thin for a docs diff that *asserts* cross-file behavior. Flag: a docs diff making behavioral claims may warrant keeping security/architecture on.
3. **Severity calibration**, not recall, is the soft spot: the gold csp defect and postfix fail-open both surfaced but graded below their canon tier. Recall (did the defect surface at all) is strong; grading is noisier.
4. Single pass, single replicate (k=1), n=1 per cell. Verdicts are draws (0.14–0.25 red-band self-agreement, per E1); a second pass would move some 🟡/🔴 gradings. Rubric synthesized inline (not an independent agent), so no rubric-stage token measurement this run.
5. Corpus scoped to `app/` (E1-comparable); the 13 md files were context-only.

## 5. Baseline numbers to carry forward

- **Core pipeline per canon pass ≈ 2.99M tokens** (fc k=1 628k + gated critics 2.36M), 38 agents, 8 instances. Per-cell mean ≈ 373k (range 67k deploy → 616k corpus).
- **This is the denominator for 032 H3**: a ≥15% saving means ≥~450k off this figure. #3 prompt-cache (shared context re-sent to the ~3–6 agents/cell) and #4 short-circuit (loop-only, not exercised here) are the levers; measuring their delta is the next step.
- **Recall baseline**: behavioral red surfaced in 7/8 cells; the 2 cross-file reds (csp gold, corpus seam) are the full pipeline's margin over lite/diff-only review.
