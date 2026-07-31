# Code Fact-Check Report

**Commit:** e9d05ea
**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** `git diff main...HEAD` on branch `exp/cross-model-openrouter-sweep` (13 files; claims *inside* the immutable experiment artifacts under `runs/dd-cross-model-2026-07-30/` other than README.md were excluded per scope instructions, but claims *about* them were checked)
**Checked:** 2026-07-30
**Total claims checked:** 30
**Summary:** 25 verified, 0 mostly accurate, 0 stale, 2 incorrect, 3 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read before checking; it contains no entries yet ("Patterns" section is empty below its append marker, `docs/reviews/hallucination-patterns.md:24`), so no claim below is matched against a logged pattern.

---

## Claim 1: "Stage 1 of `code-review` runs `code-fact-check` as k=3 parallel replicates on byte-identical prompts; the orchestrator merges by claim cluster (file, ±5-line range, claim substance) taking the most severe verdict any replicate assigned (Incorrect-high > Incorrect-medium > Stale > Mostly Accurate > Unverifiable > Verified), records per-replicate verdicts on every merged claim, and reports the cluster agreement rate in a `## Verdict stability` section"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every element of this description matches the shipped SKILL.md. The heading is "### Stage 1: Code Fact-Check (k=3 replicated)" and the skill instructs "Spawn **three** agents with the code-fact-check skill, in parallel, on **byte-identical prompts**" (`skills/code-review/SKILL.md:257-259`). Clustering: "same file, overlapping line ranges (±5 lines), and assert substantially the same thing" (`skills/code-review/SKILL.md:319-320`). Severity order: "`Incorrect (high confidence)` > `Incorrect (medium confidence)` > `Stale` > `Mostly Accurate` > `Unverifiable` > `Verified`" (`skills/code-review/SKILL.md:323-325`). Per-replicate verdicts: "Each claim in the merged report carries a `Replicate verdicts: r1=<verdict> · r2=<verdict> · r3=<verdict>` line" (`skills/code-review/SKILL.md:330-332`). Agreement rate: "End the merged report with a `## Verdict stability` section" (`skills/code-review/SKILL.md:334-336`).

**Evidence:** `skills/code-review/SKILL.md:255-340`

## Claim 2: "Result 14a showed it flipping between Incorrect and Mostly Accurate on identical input — the entire blocking channel rested on a single sample of the least stable judgment in the system (J_self on 🔴 rows 0.14–0.25)"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The state doc's §1.1 says exactly this: "Per Result 14a, that verdict is unstable on identical input: the same `WARY_MOOD_DURATION` comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡" (`docs/thoughts/code-review-evaluation-state.md:51-54`), and "J_self restricted to 🔴 rows is **0.14–0.25**" (`docs/thoughts/code-review-evaluation-state.md:57`). The "only 🔴-promotion channel" half is also stated there: "Per Result 16, a fact-check Incorrect verdict is the *only* thing that promotes a finding to 🔴" (`docs/thoughts/code-review-evaluation-state.md:50-51`).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:50-58`

## Claim 3: "Per-replicate reports (`code-fact-check-report-r1..3.md`) persist for audit and for the decision-25 Confirmed-Good cross-check, which now scans them too … this is the piece decision 25 marked out of scope"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The SKILL.md Output Locations tree lists `code-fact-check-report-r1.md` through `-r3.md` annotated "(replicate — audit + Confirmed-Good observation scan)" (`skills/code-review/SKILL.md:1065-1068`), and the Confirmed-Good cross-check step now reads "re-read the merged fact-check report **and each per-replicate report** (`code-fact-check-report-r*.md` — an observation recorded by only one replicate … still counts)" (`skills/code-review/SKILL.md:936-939`). Decision log row 25 did mark the gap out of scope: "Closing that gap needs the k≥3 fact-check of §1.1, deliberately out of scope" (`docs/decisions/log.md:47`).

**Evidence:** `skills/code-review/SKILL.md:933-940,1062-1068`; `docs/decisions/log.md:47`

## Claim 4: "Corroboration: all four families in the 2026-07-30 DD sweep (`runs/dd-cross-model-2026-07-30/`) independently ranked this action first"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four run files place the k≥3 fact-check action first / as the ★ recommendation: Fable — "▶ recommend [2] k≥3 fact-check · confidence 78%" (`runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:207`); Sol — "▶ recommend [2] Fact-check replication · confidence 78%" (`runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.md:283`); Gemini — "▶ recommend [1] k=3 incumbent fact-check · confidence 95%" (`runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.md:135`); Kimi — "▶ recommend [3] k≥3 fact-check, most-severe-wins · confidence 75%" (`runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:171`).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:207`, `runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.md:283`, `runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.md:135`, `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:171`

## Claim 5: "implemented in `skills/code-review/SKILL.md` Stage 1 exactly as shaped below (k=3, byte-identical prompts, cluster + most-severe-wins, per-replicate verdict logging, agreement rate reported per run in the merged report's `## Verdict stability` section)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:41-45`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Compared the §1.1 "Shape" paragraph — "k=3 fact-check agents on byte-identical prompts; cluster claims by (file, line-range, claim text); take the **most severe verdict** any run assigned, not the majority … Log per-run verdicts" (`docs/thoughts/code-review-evaluation-state.md:62-67`) — against the shipped Stage 1 (see Claim 1's evidence). Every element is present, including the rejection of majority vote: "Majority vote is explicitly the wrong aggregator here" (`skills/code-review/SKILL.md:325-326`). The status note also correctly states "the first k=3 run has not executed" — no merged report or `-r*.md` replicate reports predate this run in `docs/reviews/` (paraphrased — no quote available because the assertion is about the absence of files, confirmed by directory listing).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:62-69`; `skills/code-review/SKILL.md:255-340`

## Claim 6: "**Instrumented** (log row 26): every k=3 run now reports its cluster agreement rate in the merged report's `## Verdict stability` section. Still zero data points — accumulate ≥20 clustered claims, then apply §1.1's falsifier (≥90% agreement → k=2)."

**Location:** `docs/thoughts/code-review-evaluation-state.md:198`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Matches the shipped merge step: "Report the disagreement rate. End the merged report with a `## Verdict stability` section … If cumulative measurements across runs show ≥90% verdict agreement on a ≥20-claim sample, k can drop to 2" (`skills/code-review/SKILL.md:333-340`). Log row 26 exists at `docs/decisions/log.md:48`. "Zero data points" is consistent with Claim 5's finding that no k=3 run has produced reports yet.

**Evidence:** `skills/code-review/SKILL.md:333-340`; `docs/decisions/log.md:48`

## Claim 7: "Four frontier models were given a **byte-identical prompt** (`prompt.md` in this directory)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:3`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

`prompt.md` exists (102,388 bytes) and contains all three declared inputs, but no artifact records the exact bytes actually sent to each arm (the `*.meta.json` files record usage/latency, not a prompt hash). The differing `prompt_tokens` counts (23,759 / 22,737 / 22,856) are *consistent* with one prompt tokenized by three different tokenizers, but do not prove byte identity, and the local Fable arm has no meta record at all. Nothing contradicts the claim; there is simply no artifact that could confirm it.

**Evidence:** `runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.meta.json:5`, `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json:5`, `runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json:5` (`"prompt_tokens"` fields)

## Claim 8: "Inputs embedded in the prompt: `docs/thoughts/code-review-evaluation-state.md`, `skills/divergent-design/SKILL.md`, and the full `workflows/divergent-design.md`."

**Location:** `runs/dd-cross-model-2026-07-30/README.md:9-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`prompt.md` carries all three as labeled sections: "# Input 1: docs/thoughts/code-review-evaluation-state.md" (`runs/dd-cross-model-2026-07-30/prompt.md:37`), "# Input 2: skills/divergent-design/SKILL.md" (`prompt.md:353`), "# Input 3: workflows/divergent-design.md" (`prompt.md:412`).

**Evidence:** `runs/dd-cross-model-2026-07-30/prompt.md:37,353,412`

## Claim 9: "The local Fable arm ran inside Claude Code as a subagent but was explicitly forbidden to read any file other than the prompt, to stay comparable."

**Location:** `runs/dd-cross-model-2026-07-30/README.md:22-24`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

No session transcript or invocation record for the local arm is in the repo. The run file's own header is consistent — "Model: claude-fable-5 (local arm) · Date: 2026-07-30 · Single-shot, headless, Path A/C only" (`runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:3`) — and it says "Prior pruning grep: not runnable in this setting" (`local_claude-fable-5.md:248`), which matches a no-file-access constraint. But the constraint itself (what the subagent was told) is not preserved anywhere checkable. Commit `b6114ac` repeats the same claim; both trace to the same unrecorded invocation.

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:3,248`

## Claim 10: "All four models independently converged on the **same top action: k≥3 `code-fact-check` replication with most-severe-wins (§1.1)**"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:31-33`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claim 4: all four ★ recommendations are the k≥3/k=3 fact-check replication action, and all four state most-severe/max-severity aggregation — e.g. Gemini: "Implement k=3 `code-fact-check` incumbent sampling with max-severity aggregation immediately" (`runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.md:154`); Kimi's candidate [3] is "run `code-fact-check` k≥3 on byte-identical prompts … combine most-severe-wins" (`runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:16`).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:207`, `openai_gpt-5.6-sol.md:283`, `google_gemini-3.1-pro-preview.md:135,154`, `moonshotai_kimi-k3.md:16,171`

## Claim 11: "Fable 5 (local) | ~5 min | n/a (agent)" (latency cell)

**Location:** `runs/dd-cross-model-2026-07-30/README.md:37`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The local arm has no meta.json ("Per-run latency/usage/finish_reason (OpenRouter arms)", `runs/dd-cross-model-2026-07-30/README.md:68` — the README itself scopes the meta files to the OpenRouter arms) and no other timing artifact exists for it. The "n/a (agent)" token cell is accurate by the same absence.

**Evidence:** directory listing of `runs/dd-cross-model-2026-07-30/` — no `local_*.meta.json` present (paraphrased — no quote available because the claim concerns a file that does not exist)

## Claim 12: Fable table row — "16 [candidates] | 5 [survivors] | C | 78% | Portfolio: k≥3 fact-check + evidence-bearing Confirmed Good in parallel; then MD1-R1 replication, then §1.2 escalation sub-DD; vendor-in-fact-check deferred behind 021 Stage 1"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The run file states "16 candidates generated (0–15)" and "Five survived pruning: [2] [5] [6] [8] [9]" (`runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:228`), "Decision path taken: **Path C**" (`local_claude-fable-5.md:210`), "confidence 78%" (`local_claude-fable-5.md:207`), and the portfolio ordering "do [2] and [5] now in parallel; run [9] immediately after …; start [6] once [2]'s disagreement data exists; defer [8] until 021 Stage-1 lands" (`local_claude-fable-5.md:212`) — [9] is the MD1 replication, [6] the §1.2 escalation sub-DD, [8] the vendor-in-fact-check.

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:112,207,210,212,228`

## Claim 13: Sol table row — "155 s | 9,147 (2,233) | — | 5 | C | 78% | Fact-check replication first; runner-up Confirmed-Good evidence; axis = 'unstable blocker promotion vs unsupported positive assurance'"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:38`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

meta.json: `"latency_s": 154.5` (rounds to 155), `"completion_tokens": 9147`, `"reasoning_tokens": 2233` (`runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json`). Run file: "**Survivors:** [2], [3], [4], [5], [7]" (5) (`openai_gpt-5.6-sol.md:162`), "**Path C — tradeoff unclear, no human present.**" (`openai_gpt-5.6-sol.md:290`), and the banner "▶ recommend [2] Fact-check replication · confidence 78% · runner-up [4], axis = unstable blocker promotion vs unsupported positive assurance" (`openai_gpt-5.6-sol.md:283`) — [4] is "Evidence-backed positive outputs", i.e. Confirmed-Good evidence; the axis quote matches verbatim.

**Evidence:** `runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json`; `openai_gpt-5.6-sol.md:162,209,283,290`

## Claim 14: Gemini table row — "112 s | 15,594 (11,870) | — | 4 | A | 95% | k=3 incumbent fact-check dominates; vendor addition and soundness routing are fast-follows gated on the stabilized baseline"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:39`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

meta.json: `"latency_s": 112.2`, `"completion_tokens": 15594`, `"reasoning_tokens": 11870` (`runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.meta.json`). Run file: "**Surviving Candidates:** [1], [3], [4], [11]" (4) (`google_gemini-3.1-pro-preview.md:71`), "`▶ recommend [1] k=3 incumbent fact-check · confidence 95%`" and "**Decision Path:** Path A. Candidate [1] overwhelmingly dominates … Candidates 3 and 4 are highly viable fast-follows, but 1 must be prioritized first" (`google_gemini-3.1-pro-preview.md:135-137`).

**Evidence:** `runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.meta.json`; `google_gemini-3.1-pro-preview.md:71,135-137`

## Claim 15: Kimi table row (metrics and recommendation head) — "956 s | 32,487 (24,306) | 14 | 5 | C | 75% | k≥3 fact-check scoped to promotion-candidate claims (k set by pre-flight disagreement measurement)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:40`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

meta.json: `"latency_s": 955.9` (rounds to 956), `"completion_tokens": 32487`, `"reasoning_tokens": 24306` (`runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json`). Run file: "**Candidates (14):**" (`moonshotai_kimi-k3.md:13`), "**Survivors (5): [3], [2], [7], [0], [8]**" (`moonshotai_kimi-k3.md:105`), "confidence 75%" (`moonshotai_kimi-k3.md:171`), "**Decision path: C.**" (`moonshotai_kimi-k3.md:176`), and the scoping/stress-test result "*changed: resampling scoped to promotion-candidate claims* … k is set by a day-scale pre-flight measurement, not fixed at 3" (`moonshotai_kimi-k3.md:128`).

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json`; `moonshotai_kimi-k3.md:13,105,128,171,176`

## Claim 16: Kimi table row (runner-up) — "runner-up doc-order status quo"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:40`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Kimi's runner-up is candidate **[2], "Measurement-first"**, not the doc-order status quo. The banner reads "▶ recommend [3] k≥3 fact-check, most-severe-wins · confidence 75% · runner-up [2], axis = assurance-now vs evidence-first" (`runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:171-172`), and candidate [2] is defined as "**Measurement-first:** before any skill edit, run the cheap queued arms — the §1.1 falsifier …, the MD1-R1 replication …, and the 9-cell Confirmed-Good cross-check retrospective" (`moonshotai_kimi-k3.md:16` region, candidate list item 2). The doc-order status quo is a *different* candidate, **[0]**: "**Doc-as-written (status quo):** implement §1.1 → §1.2-via-DD → §1.3 → §1.4 in the doc's order" (`moonshotai_kimi-k3.md:15` region, candidate list item 0), which appears in the scorecard as "0    doc-order verbatim" ranked fourth of five (`moonshotai_kimi-k3.md:149`). The README conflates the two; the summarized axis ("assurance-now vs evidence-first") only makes sense against measurement-first, not against the status quo. This is a misattribution, not a fabrication — both candidates exist in the source.

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:13-17,149,171-172`

## Claim 17: "**Template fidelity:** all four rendered the Decision presentation block with the box-drawing scorecard, legend, ★ marker, and recommendation banner; none left unfilled `<…>` slots. All four honored the no-`AskUserQuestion` constraint."

**Location:** `runs/dd-cross-model-2026-07-30/README.md:44-46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four files contain the box-drawing block, the legend line "legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint" (`local_claude-fable-5.md:175`, `openai_gpt-5.6-sol.md:244`, `google_gemini-3.1-pro-preview.md:108`, `moonshotai_kimi-k3.md:141`), a ★-marked recommended card, and a `▶ recommend` banner (lines cited in Claim 4). A grep for unfilled `<…>` template slots across the four output files returns none (paraphrased — no quote available because the assertion is about absence of matches). No `AskUserQuestion` call appears in any output; Gemini and Kimi state it explicitly ("(No native `AskUserQuestion` is issued)", `google_gemini-3.1-pro-preview.md:137`; "no `AskUserQuestion` issued", `moonshotai_kimi-k3.md:176`), and the Fable and Sol outputs contain no such invocation.

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:175,187`, `openai_gpt-5.6-sol.md:244,256`, `google_gemini-3.1-pro-preview.md:108,119,137`, `moonshotai_kimi-k3.md:141,153,176`

## Claim 18: "Kimi produced the most aggressive stress-test pass … at ~9× Sol's latency"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:47-49`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The recorded latencies are Kimi `"latency_s": 955.9` (`moonshotai_kimi-k3.meta.json`) and Sol `"latency_s": 154.5` (`openai_gpt-5.6-sol.meta.json`). Computed via arithmetic-eval: `955.9/154.5 -> 6.19` — approximately **6×**, not ~9×. The ~9× figure matches the Kimi-to-**Gemini** ratio instead: `955.9/112.2 -> 8.52`. Likely the wrong denominator arm was named. The qualitative content of the sentence (scope narrowing of k≥3 to promotion decisions; queue-volume caps on human routing) is accurate per `moonshotai_kimi-k3.md:128` ("resampling scoped to promotion-candidate claims") and the human-gate stress-test material, but the ratio as stated is wrong.

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json` (`"latency_s": 955.9`), `openai_gpt-5.6-sol.meta.json` (`"latency_s": 154.5`), `google_gemini-3.1-pro-preview.meta.json` (`"latency_s": 112.2`); arithmetic-eval outputs `955.9/154.5 -> 6.187`, `955.9/112.2 -> 8.520`

## Claim 19: "Gemini was the thinnest (~15k chars) and the only Path A / 95% call"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:49-50`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`wc -c`: Gemini 15,827 bytes vs Fable 36,832, Kimi 32,301, Sol 33,897 — thinnest by a wide margin, and ~15k is accurate. Path A appears only in the Gemini file ("**Decision Path:** Path A", `google_gemini-3.1-pro-preview.md:137`; the other three all state Path C), as does the 95% confidence (`google_gemini-3.1-pro-preview.md:135`).

**Evidence:** byte counts from `wc -c` over `runs/dd-cross-model-2026-07-30/*.md` (paraphrased — no quote available because the evidence is a command output, figures reproduced above); `google_gemini-3.1-pro-preview.md:135,137`

## Claim 20: "API cost: $1.21 total (Kimi $0.56 · Sol $0.42 · Gemini $0.23)."

**Location:** `runs/dd-cross-model-2026-07-30/README.md:57`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

meta.json `"cost"` fields: Kimi `0.555516` (→ $0.56), Sol `0.41725625` (→ $0.42), Gemini `0.234646` (→ $0.23). Sum verified via arithmetic-eval: `0.555516+0.234646+0.41725625 -> 1.20741825` → $1.21. All roundings correct.

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json`, `openai_gpt-5.6-sol.meta.json`, `google_gemini-3.1-pro-preview.meta.json` (`"cost"` fields); arithmetic-eval output `-> 1.20741825`

## Claim 21: Files table — "`prompt.md` | The shared prompt … `local_claude-fable-5.md` … `*.meta.json` | Per-run latency/usage/finish_reason (OpenRouter arms)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:61-68`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Directory listing matches the inventory exactly: `prompt.md`, four arm `.md` files, and exactly three `.meta.json` files — one per OpenRouter arm, none for the local arm, matching the "(OpenRouter arms)" qualifier. Each meta.json contains `latency_s`, `usage`, and `finish_reason` keys as described.

**Evidence:** `ls runs/dd-cross-model-2026-07-30/` (paraphrased — no quote available because the evidence is a directory listing; 9 files, enumerated in this report's scoping); `runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json:1-4`

## Claim 22: "its verdict is the pipeline's only 🔴-promotion channel and is measurably unstable on a single sample (state doc §1.1, Result 14a)"

**Location:** `skills/code-review/SKILL.md:27-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both halves are stated in the cited section: "Per Result 16, a fact-check Incorrect verdict is the *only* thing that promotes a finding to 🔴. Per Result 14a, that verdict is unstable on identical input" (`docs/thoughts/code-review-evaluation-state.md:50-52`). The instability is quantified ("J_self restricted to 🔴 rows is **0.14–0.25**", `docs/thoughts/code-review-evaluation-state.md:57`), supporting "measurably".

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:50-58`

## Claim 23: "on identical input, the same comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡 (`docs/thoughts/code-review-evaluation-state.md` §1.1, Result 14a)"

**Location:** `skills/code-review/SKILL.md:265-268`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Near-verbatim match to the source: "the same `WARY_MOOD_DURATION` comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡" (`docs/thoughts/code-review-evaluation-state.md:52-54`).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:51-55`

## Claim 24: "the observed failure mode is under-calling, not over-calling (state doc §1.1)" and "≥90% verdict agreement on a ≥20-claim sample, k can drop to 2 — that is §1.1's stated falsifier"

**Location:** `skills/code-review/SKILL.md:327-328,338-340`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Source states both: "the observed failure mode is under-calling, not over-calling" (`docs/thoughts/code-review-evaluation-state.md:64-65`) and "**Falsifier worth checking first:** if k=3 fact-check verdicts agree ≥90% of the time on a 20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2" (`docs/thoughts/code-review-evaluation-state.md:68-69`).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:62-69`

## Claim 25: Header comment — "Validates the k=3 fact-check replication contract in skills/code-review/SKILL.md (docs/thoughts/code-review-evaluation-state.md §1.1, decision log row 26): The fact-check verdict is the pipeline's only 🔴-promotion channel and is the least stable judgment in it (Result 14a: the same defect rated Incorrect by one run and Mostly Accurate by another, on identical input)."

**Location:** `test/skills/code-review-factcheck-replication.bats:3-9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three references resolve: the Stage 1 k=3 contract exists in SKILL.md (Claim 1), state doc §1.1 says exactly this (Claims 22-23), and decision log row 26 exists at `docs/decisions/log.md:48`. "Least stable judgment" quotes the state doc: "a single sample of the least stable judgment in it" (`docs/thoughts/code-review-evaluation-state.md:56-57`).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:50-58`; `docs/decisions/log.md:48`; `skills/code-review/SKILL.md:255`

## Claim 26: "Same enforcement rationale as code-review-assurance-contract.bats"

**Location:** `test/skills/code-review-factcheck-replication.bats:12`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The referenced file exists: `test/skills/code-review-assurance-contract.bats` is present in the test directory. The `# @category fast` tag on line 2 also matches the existing convention (used by `code-fact-check-eval.bats`, `arithmetic-eval-format.bats`, and others).

**Evidence:** `test/skills/code-review-assurance-contract.bats` (existence confirmed by directory listing; paraphrased — no quote available because the claim is about file existence)

## Claim 27: "Decision 25 marked this the out-of-scope gap; k=3 closes it only if the cross-check reads observations a losing replicate recorded."

**Location:** `test/skills/code-review-factcheck-replication.bats:95-96`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Decision log row 25: "a run whose fact-check never observed the relevant fact is not made to observe it. Closing that gap needs the k≥3 fact-check of §1.1, deliberately out of scope" (`docs/decisions/log.md:47`). The SKILL.md cross-check does now read per-replicate reports (`skills/code-review/SKILL.md:936-939`, quoted under Claim 3), which is exactly what the test's grep for `code-fact-check-report-r\*.md` asserts.

**Evidence:** `docs/decisions/log.md:47`; `skills/code-review/SKILL.md:936-939`

## Claim 28: The test file's 10 `@test` names accurately describe assertions that hold against the shipped SKILL.md (implicit behavioral claim of the test suite)

**Location:** `test/skills/code-review-factcheck-replication.bats:36-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Executed `bats test/skills/code-review-factcheck-replication.bats`: all 10 tests pass ("ok 1" through "ok 10", 0 failures). Spot-checked that the greps target real SKILL.md text rather than vacuously matching: e.g. the severity-order regex matches `skills/code-review/SKILL.md:324-325`, and the "at least **two** substantive" checkpoint text exists at `skills/code-review/SKILL.md:308-309`.

**Evidence:** bats run output, 10/10 ok (paraphrased — no quote available because the evidence is command output, reproduced in summary); `skills/code-review/SKILL.md:308-309,324-325`

## Claim 29: Commit e9d05ea — "Contract test: test/skills/code-review-factcheck-replication.bats (10 checks)" and "Decision log row 26; state doc §1.1 and open question #2 updated"

**Location:** commit `e9d05ea` (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The test file contains exactly 10 `@test` blocks (`grep -c '^@test'` → 10), all passing (Claim 28). Log row 26 (`docs/decisions/log.md:48`), the §1.1 status note (`docs/thoughts/code-review-evaluation-state.md:41-49`), and the open-question-#2 row (`docs/thoughts/code-review-evaluation-state.md:198`) are all in the diff. The remaining substantive claims in the message body (byte-identical prompts / output path only difference / most-severe-wins / Verdict stability / decision-25 gap closure) duplicate Claims 1-3 and are covered there.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:36-100`; `docs/decisions/log.md:48`; `docs/thoughts/code-review-evaluation-state.md:41-49,198`

## Claim 30: Commit b6114ac — "All four converged on k>=3 code-fact-check most-severe-wins (sec 1.1) as the top action."

**Location:** commit `b6114ac` (message body)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claims 4 and 10 — all four arm outputs recommend the k≥3/k=3 fact-check action first with most-severe/max-severity aggregation. The message's "byte-identical prompt" and Fable no-read-constraint claims duplicate Claims 7 and 9 (both Unverifiable there for lack of a recording artifact; nothing contradicts them).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:207`, `openai_gpt-5.6-sol.md:283`, `google_gemini-3.1-pro-preview.md:135,154`, `moonshotai_kimi-k3.md:16,171`

---

## Claims Requiring Attention

### Incorrect
- **Claim 16** (`runs/dd-cross-model-2026-07-30/README.md:40`): Kimi's runner-up is [2] "Measurement-first", not the doc-order status quo (that is candidate [0], ranked fourth).
- **Claim 18** (`runs/dd-cross-model-2026-07-30/README.md:47-49`): Kimi's latency is ~6× Sol's (955.9/154.5 = 6.19), not ~9×; ~9× matches the Gemini ratio (8.52×).

### Stale
- None.

### Mostly Accurate
- None.

### Unverifiable
- **Claim 7** (`runs/dd-cross-model-2026-07-30/README.md:3`): "byte-identical prompt" to all four arms — no per-arm record of sent bytes exists; token counts are consistent but not probative.
- **Claim 9** (`runs/dd-cross-model-2026-07-30/README.md:22-24`): local Fable arm "forbidden to read any file other than the prompt" — no invocation record preserved; run output is consistent with the claim.
- **Claim 11** (`runs/dd-cross-model-2026-07-30/README.md:37`): Fable arm "~5 min" latency — no timing artifact for the local arm.

## Goal-Alignment Note
- Answered: yes
- Out of scope: claims *inside* the four external-model output files and prompt.md (immutable experiment artifacts, excluded per scope instructions); pre-existing unchanged SKILL.md prose outside the diff hunks
- Escalate: the two Incorrect claims are both in `runs/dd-cross-model-2026-07-30/README.md` (secondary summary prose, not the experiment data) — a two-line fix; neither is a fabrication, so the hallucination-patterns log was left untouched
