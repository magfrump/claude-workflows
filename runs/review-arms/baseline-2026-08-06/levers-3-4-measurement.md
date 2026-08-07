# Measuring 032 #3 (prompt-cache) and #4 (first-red short-circuit) against the baseline

**Denominator**: the current-setup baseline = **2,986,091 subagent tokens / 38 agents** over the
8-instance canon (`results.md`). **Metric available**: `subagent_tokens` (a token *count*) from
task notifications — the same instrument as E1/E3/the baseline.

**Headline**: against a single-pass baseline, **#3 and #4 produce ~0 token-count saving** — not
because they're worthless, but because neither is a token-count effect on a single pass. #3 is a
cache *billing-rate* effect (invisible to token counts); #4 is *loop-only* and its high-value
trigger fired **0/8** here. The token savings already banked come from **031 k=1** (measured) and
**032 #1 gating** (measured). Details below, with the real numbers.

---

## #3 — prompt-cache the shared context

**What it changes**: cache the shared context re-sent to a cell's critic fan-out so agents 2..N
read it at the cache rate (~0.1× input) instead of full.

**Why the token-count metric can't see it**: prompt caching does not reduce the number of tokens
*processed* — a cached token still counts. It reduces the *billing rate* of the cached portion
(cache-read ≈ 10% of input). So `subagent_tokens` (a count) shows **zero delta** whether caching
is on or off. Any honest #3 number is a **cost-equivalent**, not a token-count saving.

**Second finding — the SKILL path barely shares a prefix.** In the production loop (and in this
baseline), critic agents are given a scope spec and **self-read** the diff, enclosing files, and
the fact-check report via tools. The genuinely byte-identical shared *prompt prefix* was my
~250-word instruction block (~330 tokens). So the **realized** #3 saving on the as-run structure ≈
330 × (N−1) × 0.9 per cell ≈ **~1–1.5k cost-equiv/cell, ~8k across the canon — negligible.**
Realizing #3 requires **restructuring the SKILL to inline** the shared context into a cacheable
prefix (the model decision 032 #3 assumed) — which trades against agents' current selective reading.

**Potential #3 saving IF the shared diff + fact-check report are inlined + cached** (measured
sizes; tokens ≈ chars/4; saving = prefix_tok × (N−1) × 0.9):

| Cell | diff+factcheck chars | prefix tok | N critics | cost-equiv saving |
|---|---|---|---|---|
| csp | 15,856 | 3,964 | 5 | 14,270 |
| lean | 29,411 | 7,353 | 5 | 26,470 |
| hygiene | 18,490 | 4,623 | 4 | 12,481 |
| secdeps | 14,723 | 3,681 | 3 | 6,626 |
| fscompat | 7,663 | 1,916 | 3 | 3,449 |
| corpus (app/) | 69,575 | 17,394 | 6 | 78,273 |
| postfix | 17,597 | 4,399 | 5 | 15,838 |
| deploy | — | — | 0 | 0 (no fan-out) |
| **total** | | | | **≈157,400 cost-equiv** |

**≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost, 0% of token count** — and only if the SKILL
is restructured to inline+cache. This is **well below decision 032's 20–40% estimate**, because
that estimate was inherited from the cross-model harness, which *inlines the whole diff into the
prompt* (so its whole context is a cacheable prefix). The Agent-tool SKILL doesn't inline — agents
self-read — so the shared prefix is small. **Correction for decision 032**: on the production
(Agent-tool) loop, #3 is a low-single-digit-% cost lever, not a 20–40% one; the enclosing-source
files (the bulk) aren't a shared prefix because each critic reads different parts.

**Where #3 does earn more**: *across passes* in a fix loop, the diff+context prefix is stable
between a fix and its re-review, so the cache stays warm pass-to-pass. That's a loop-only multiplier
on the ~5% above — still cost-side, still invisible to token counts. Worth having (caching is
free to leave on), not worth a big SKILL rewrite to force-inline.

---

## #4 — first-red short-circuit

**What it changes**: on a `--loop-pass` (non-terminal loop pass), once a **behavioral 🔴** is
confirmed, stop the pass and skip the rest of the critic panel — a fix + re-review is coming anyway.

**Empirical result on the baseline — the high-value trigger fired 0/8.** The big saving is the
**fact-check-gate** variant: if fact-check alone confirms a behavioral red, the *entire* critic
panel (~300–550k) is skipped. Across all 8 cells, fact-check produced **zero** behavioral 🔴 —
every Incorrect(high) was comment/doc subject → 🟡 under tier policy T (see `token-ledger.md`
Stage-1). So on reviewed canon states the fact-check-gate short-circuit **never fires**. The
behavioral reds all came from *critics* (csp architecture Structural, secdeps security High, corpus
architecture Structural), which are dispatched in one parallel wave — so the **critic-stage**
variant has nothing to skip within a pass either.

**Net #4 saving measurable from a single pass = 0** (it is structurally a loop lever, and its
fact-check trigger is empty on these states).

**Loop estimate (from E3, the only loop data we have).** E3-loops arm2 (full-only) took **3 full
passes** to 0R+0A; passes 1–2 were red-gated. #4 would trim a red-gated pass's critic block **only
if that pass's red is visible at fact-check**. E3's blocking reds were predominantly
critic-surfaced (nonce-delivery, connect-src → security/architecture; untested-policy → test), with
only the runtime-comment / immutable-history items reachable by fact-check. So even in a loop, #4's
realized saving is **partial and gated on red provenance** — bounded above by ~one critic block per
fact-check-visible-red pass (~0.3–0.5M of a ~4M loop, i.e. up to ~10%), but **only when a behavioral
defect is the kind fact-check catches** (a wrong behavioral comment/contract), which is the minority
on these states. The mechanism is sound; the workload rarely triggers it.

**Consequence**: #4 is a safety-free option worth keeping wired (it can only help), but it is **not
a reliable token reducer** for this corpus — the reds here are structural/behavioral findings that
live in the critic panel, not fact-check-visible comment/contract lies.

---

## What actually moved the number (for contrast — these ARE token-count savings)

| Lever | measured saving | basis |
|---|---|---|
| **031 k=1 fact-check** | **~1.25M** (628k vs ~1.88M for k=3) ≈ **29%** off a k=3-baseline pipeline | this run ran k=1; k=3 = 3× the 8 fact-check agents |
| **032 #1 critic gating** | **~0.63M** (9 critic-agents skipped × ~70k) ≈ **~17%** off the ungated candidate panel | measured in `token-ledger.md` gating table |
| 032 #3 prompt-cache | ~5% cost-equiv, **0% token-count**, needs inlining | analytical, above |
| 032 #4 short-circuit | **0** on single pass; ≤~10% loop-only, red-provenance-gated | analytical, above |

**Bottom line**: the real, banked, token-count savings against the full-panel-k3 ancestor are **k=1
(~29%) + gating (~17%)**. #3 and #4 are genuine but small and off-instrument here: #3 is a ~5%
*cost* lever (cache-rate, and only if the SKILL inlines the shared prefix), #4 is a loop-only option
whose fact-check trigger is empty on reviewed states. Recommend: leave #3 caching on (free) and
document that its production-loop benefit is single-digit-%, not 20–40% (amend decision 032);
keep #4 wired for its loop safety, but don't count on it for savings on structural-defect corpora.

### Optional next step to see #4 fire
To measure #4 empirically rather than analytically, run a real `--loop-pass` on a **dirty
pre-review state whose defect is a wrong behavioral comment/contract** (fact-check-visible), and
compare the loop's critic tokens with vs without the short-circuit. None of the 8 reviewed canon
states qualify (they're clean or structurally-defective); E1's dirty states are the candidate pool.
