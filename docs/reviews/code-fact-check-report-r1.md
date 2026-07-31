# Code Fact-Check Report

**Commit:** e9d05ea
**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** `git diff main...HEAD` (branch `exp/cross-model-openrouter-sweep` vs `main`) — changed files: `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md`, `runs/dd-cross-model-2026-07-30/README.md`, `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`. Immutable experiment artifacts under `runs/dd-cross-model-2026-07-30/` (model outputs, `prompt.md`, `*.meta.json`) were used as evidence only; claims *about* them were checked, claims *inside* them were not.
**Checked:** 2026-07-30
**Total claims checked:** 26
**Summary:** 19 verified, 1 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) was read first; it contains no entries yet, so no claim below is matched against a logged pattern. None of the Incorrect verdicts below is a fabrication (no nonexistent symbol/API is claimed), so the log is left untouched.

---

## Claim 1: "Stage 1 of `code-review` runs `code-fact-check` as k=3 parallel replicates on byte-identical prompts; the orchestrator merges by claim cluster (file, ±5-line range, claim substance) taking the most severe verdict any replicate assigned … records per-replicate verdicts on every merged claim, and reports the cluster agreement rate in a `## Verdict stability` section"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every element of this description of the skill exists in `skills/code-review/SKILL.md`. The Stage 1 heading declares replication ("### Stage 1: Code Fact-Check (k=3 replicated)", `skills/code-review/SKILL.md:258`); byte-identical prompts are required ("on **byte-identical prompts**", :260-262); clustering matches on "(file, line-range, claim substance)" with "overlapping line ranges (±5 lines)" (:319-322); the aggregator is "**Take the most severe verdict any replicate assigned**" (:323); every merged claim "carries a `Replicate verdicts: r1=<verdict> · r2=<verdict> · r3=<verdict>` line" (:331); and the merged report must "End … with a `## Verdict stability` section" reporting "the resulting agreement rate" (:334-337).

**Evidence:** `skills/code-review/SKILL.md:258-262,319-337`

## Claim 2: "a fact-check Incorrect verdict is the pipeline's *only* 🔴-promotion channel"

**Location:** `docs/decisions/log.md:48` (row 26)
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

Same overstated claim as Claim 21 (which appears three times in `skills/code-review/SKILL.md` and once in the new bats test). The skill's own Unified Severity Mapping assigns 🔴 Must Fix to five sources, not one: "| 🔴 Must Fix | Critical, High | Critical | Breaking | Structural | Incorrect (high confidence) |" (`skills/code-review/SKILL.md:976`), and the empirical source itself (Result 16) names two channels, not one: "Every 🔴 in all nine runs traces to a fact-check **Incorrect** verdict or an api-consistency **Breaking** finding" (`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:199-200`). Confidence Medium rather than High for this instance because a decision-log rationale cell is compressed prose and may be read as shorthand for the (still two-channel) empirical result; the full analysis is under Claim 21.

**Evidence:** `skills/code-review/SKILL.md:974-978,992`, `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:197-201`

## Claim 3: "Result 14a showed it flipping between Incorrect and Mostly Accurate on identical input (J_self on 🔴 rows 0.14–0.25)"

**Location:** `docs/decisions/log.md:48` (row 26)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The state doc records both figures: "Per Result 14a, that verdict is unstable on identical input: the same `WARY_MOOD_DURATION` comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡" (`docs/thoughts/code-review-evaluation-state.md:51-54`) and "J_self restricted to 🔴 rows is **0.14–0.25**" (:57).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:51-57`

## Claim 4: "Per-replicate reports (`code-fact-check-report-r1..3.md`) persist for audit and for the decision-25 Confirmed-Good cross-check, which now scans them too … this is the piece decision 25 marked out of scope"

**Location:** `docs/decisions/log.md:48` (row 26)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The Confirmed-Good cross-check in the skill now reads "the merged fact-check report **and each per-replicate report** (`code-fact-check-report-r*.md` — an observation recorded by only one replicate may be absent from the merged claim it lost the severity contest to, and it still counts)" (`skills/code-review/SKILL.md:936-939`), and the Output Locations tree lists `code-fact-check-report-r1.md` through `-r3.md` as persisted files (:1066-1068). Decision row 25 does mark the gap out of scope: "Closing that gap needs the k≥3 fact-check of §1.1, deliberately out of scope" (`docs/decisions/log.md:47`).

**Evidence:** `skills/code-review/SKILL.md:936-939,1065-1068`, `docs/decisions/log.md:47`

## Claim 5: "§1.1's falsifier stands: ≥90% agreement on a ≥20-claim cumulative sample drops k to 2"

**Location:** `docs/decisions/log.md:48` (row 26)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The state doc's §1.1 states: "if k=3 fact-check verdicts agree ≥90% of the time on a 20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2" (`docs/thoughts/code-review-evaluation-state.md:68-69`), and the skill carries it (`skills/code-review/SKILL.md:337-340`). "≥20-claim cumulative" is a faithful rendering of "a 20-claim sample" accumulated across runs.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:68-69`, `skills/code-review/SKILL.md:337-340`

## Claim 6: "all four families in the 2026-07-30 DD sweep (`runs/dd-cross-model-2026-07-30/`) independently ranked this action first"

**Location:** `docs/decisions/log.md:48` (row 26); also asserted at `docs/thoughts/code-review-evaluation-state.md:43-44` and `runs/dd-cross-model-2026-07-30/README.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four run artifacts put fact-check replication first, with the ★ recommendation marker: Fable "▶ recommend [2] k≥3 fact-check · confidence 78%" (`runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:207`); Sol "▶ recommend [2] Fact-check replication · confidence 78%" (`openai_gpt-5.6-sol.md:283`); Gemini "▶ recommend [1] k=3 incumbent fact-check · confidence 95%" (`google_gemini-3.1-pro-preview.md:135`) and "**Implement k=3 `code-fact-check` sampling with most-severe-wins aggregation (incumbent only).**" (:5); Kimi "▶ recommend [3] k≥3 fact-check, most-severe-wins · confidence 75%" (`moonshotai_kimi-k3.md:171`).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:207`, `openai_gpt-5.6-sol.md:283`, `google_gemini-3.1-pro-preview.md:5,135`, `moonshotai_kimi-k3.md:171`

## Claim 7: "implemented in `skills/code-review/SKILL.md` Stage 1 exactly as shaped below (k=3, byte-identical prompts, cluster + most-severe-wins, per-replicate verdict logging, agreement rate reported per run in the merged report's `## Verdict stability` section)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:41-45`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

All five named elements are implemented (see Claim 1 evidence). "Exactly as shaped below" slightly overstates fidelity on one detail: the shape says "cluster claims by (file, line-range, claim **text**)" (`docs/thoughts/code-review-evaluation-state.md:61-62`), while the implementation deliberately departs from text matching — "Clustering is semantic — replicates word the same claim differently; match on (file, line-range, claim substance), not on string equality" (`skills/code-review/SKILL.md:321-322`) — and adds a ±5-line tolerance the shape does not specify. The departure is an improvement, but "exactly" is not literally true.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:61-62`, `skills/code-review/SKILL.md:319-322`

## Claim 8: "**Instrumented** (log row 26): every k=3 run now reports its cluster agreement rate in the merged report's `## Verdict stability` section. Still zero data points"

**Location:** `docs/thoughts/code-review-evaluation-state.md:198` (open question #2)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The skill requires the section (`skills/code-review/SKILL.md:334-340`), and decision log row 26 exists (`docs/decisions/log.md:48`). "Still zero data points" is consistent with the same doc's "the first k=3 run has not executed" (:46-47) and with the absence of any `code-fact-check-report-r*.md` in `docs/reviews/` prior to this run.

**Evidence:** `skills/code-review/SKILL.md:334-340`, `docs/decisions/log.md:48`, `docs/thoughts/code-review-evaluation-state.md:46-47`

## Claim 9: "Four frontier models were given a **byte-identical prompt** (`prompt.md` in this directory)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:3-4`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

`prompt.md` exists (102,388 bytes) and embeds the three claimed inputs (see Claim 10). But the repo contains no send-side transcript or script log proving the identical bytes were delivered to all four arms — the `*.meta.json` files record response-side usage only. Weak corroboration: prompt token counts across the three OpenRouter arms are similar but not equal (23,759 / 22,737 / 22,856 per the meta.json files), which is consistent with identical text under different tokenizers, but is not proof. Paraphrased — no quote available because the claim is about the send operation, which left no artifact in the repo.

**Evidence:** `runs/dd-cross-model-2026-07-30/prompt.md` (exists), `google_gemini-3.1-pro-preview.meta.json`, `moonshotai_kimi-k3.meta.json`, `openai_gpt-5.6-sol.meta.json` (prompt_tokens fields)

## Claim 10: "Inputs embedded in the prompt: `docs/thoughts/code-review-evaluation-state.md`, `skills/divergent-design/SKILL.md`, and the full `workflows/divergent-design.md`"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:9-10`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`prompt.md` carries all three as labeled sections: "# Input 1: docs/thoughts/code-review-evaluation-state.md" (`runs/dd-cross-model-2026-07-30/prompt.md:37`), "# Input 2: skills/divergent-design/SKILL.md" (:353), "# Input 3: workflows/divergent-design.md" (:412).

**Evidence:** `runs/dd-cross-model-2026-07-30/prompt.md:5-7,37,353,412`

## Claim 11: "All four runs are **single-response, no tools, prompt-inline** — the Result-10-comparable config of the evaluation-state doc §5.1"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:19-21`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The referenced section exists and defines that config: "### 5.1 Comparability — the rule that governs everything … runs **diff inline, no tools, single pass**" (`docs/thoughts/code-review-evaluation-state.md:289-292`), and §5.0 uses the identical label for the same configuration: "**diff-inline / no-tools / single-pass** — the Result-10-comparable config of §5.1" (:225-226). The section reference and terminology check out; whether the runs actually executed with no tools is send-side and shares Claim 9's evidentiary limit (hence Medium), though the OpenRouter meta.json files' single `attempt: 1` / `finish_reason: "stop"` records are consistent with single-response.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:225-226,289-292`, `runs/dd-cross-model-2026-07-30/*.meta.json` (`"attempt": 1`, `"finish_reason": "stop"`)

## Claim 12: "All four models independently converged on the **same top action: k≥3 `code-fact-check` replication with most-severe-wins (§1.1)**"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:29-31`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

See Claim 6 for the four top-ranked recommendations. Most-severe-wins is named by all four: Fable's card is titled "[2] k≥3 fact-check, most-severe-wins" (`local_claude-fable-5.md:187`); Gemini's top action is "k=3 `code-fact-check` sampling with most-severe-wins aggregation" (`google_gemini-3.1-pro-preview.md:5`); Kimi's is "[3] k≥3 fact-check, most-severe-wins" (`moonshotai_kimi-k3.md:153`); Sol's candidate 2 is "Fact-check replication" whose fix sketch adopts the same aggregation (survivor section, `openai_gpt-5.6-sol.md:140-162`).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:187`, `google_gemini-3.1-pro-preview.md:5`, `moonshotai_kimi-k3.md:153`, `openai_gpt-5.6-sol.md:140-162,283`

## Claim 13: Results table — latencies (155 s / 112 s / 956 s), completion tokens 9,147 (2,233) / 15,594 (11,870) / 32,487 (24,306), candidates 16 (Fable) / 14 (Kimi), survivors 5/5/4/5, paths C/C/A/C, confidence 78/78/95/75

**Location:** `runs/dd-cross-model-2026-07-30/README.md:35-40`
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every meta-backed cell matches: Sol `"latency_s": 154.5`, `"completion_tokens": 9147`, `"reasoning_tokens": 2233` (`openai_gpt-5.6-sol.meta.json`); Gemini `"latency_s": 112.2`, `15594`, `11870` (`google_gemini-3.1-pro-preview.meta.json`); Kimi `"latency_s": 955.9`, `32487`, `24306` (`moonshotai_kimi-k3.meta.json`) — rounding to 155/112/956 is correct. Run-file cells match: Fable "16 candidates generated (0–15) … Five survived pruning: [2] [5] [6] [8] [9]" (`local_claude-fable-5.md:228`) and "Decision path taken: **Path C**" (:210), confidence 78% (:207); Sol "**Survivors:** [2], [3], [4], [5], [7]" (`openai_gpt-5.6-sol.md:162`), "**Path C**" (:290), 78% (:283); Gemini "4 candidates survived step-3 pruning" (`google_gemini-3.1-pro-preview.md:105`), "Path A" (:137), 95% (:135); Kimi "14 candidates" (`moonshotai_kimi-k3.md:37`), "**Survivors (5): [3], [2], [7], [0], [8]**" (:105), "**Decision path: C.**" (:176), 75% (:171). The "—" candidate cells for Sol and Gemini are consistent with those files not stating a generation count in the same form. The Fable "~5 min" latency cell is addressed separately in Claim 14.

**Evidence:** `runs/dd-cross-model-2026-07-30/*.meta.json`, `local_claude-fable-5.md:207,210,228`, `openai_gpt-5.6-sol.md:162,283,290`, `google_gemini-3.1-pro-preview.md:105,135,137`, `moonshotai_kimi-k3.md:37,105,171,176`

## Claim 14: Fable arm — "~5 min" latency; "ran inside Claude Code as a subagent but was explicitly forbidden to read any file other than the prompt"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:22-25,37`
**Type:** Configuration / Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The local arm has no `.meta.json` (consistent with the README's own "*.meta.json … (OpenRouter arms)" scoping) and no transcript of the launching prompt is in the repo, so neither the wall-clock figure nor the read-restriction instruction can be traced. The run file's self-description is consistent — "Model: claude-fable-5 (local arm) … Single-shot, headless" (`runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:3`) — but self-attestation inside the artifact is not independent evidence. Paraphrased — no quote available because the harness invocation left no artifact in the repo.

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:3`; absence of `local_claude-fable-5.meta.json`

## Claim 15: "all four rendered the Decision presentation block with the box-drawing scorecard, legend, ★ marker, and recommendation banner; none left unfilled `<…>` slots. All four honored the no-`AskUserQuestion` constraint."

**Location:** `runs/dd-cross-model-2026-07-30/README.md:44-46`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Box-drawing cards (`╭─ … ★ recommended`) and `▶ recommend` banners with ★ appear in all four files (`local_claude-fable-5.md:187,207`; `openai_gpt-5.6-sol.md:256,283`; `google_gemini-3.1-pro-preview.md:119,135`; `moonshotai_kimi-k3.md:153,171`); a legend/glyph key matches in all four (rg for legend/glyph markers hit all four files). A sweep for angle-bracket placeholder slots (`<[a-zA-Z]…>`) across the four output files returned zero matches. No file contains an issued `AskUserQuestion`: Fable and Sol never mention the tool; Gemini and Kimi each mention it exactly once, in a compliance note — "(No native `AskUserQuestion` is issued)" (`google_gemini-3.1-pro-preview.md:137`), "no `AskUserQuestion` issued" (`moonshotai_kimi-k3.md:176`).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:187,207`, `openai_gpt-5.6-sol.md:256,283,286`, `google_gemini-3.1-pro-preview.md:119,135,137`, `moonshotai_kimi-k3.md:153,171,176`

## Claim 16: "Kimi produced the most aggressive stress-test pass … at ~9× Sol's latency"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:47-49`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The meta files give Kimi `"latency_s": 955.9` and Sol `"latency_s": 154.5`; 955.9 / 154.5 = **6.19×**, not ~9×. The README's own table on the same page (155 s vs 956 s) yields the same ~6.2×. The ~9× figure matches a different comparison: Kimi vs **Gemini** is 955.9 / 112.2 = 8.52× ≈ ~9×. Most likely the multiplier was computed against the wrong arm. The qualitative half of the sentence (most aggressive stress-test pass — scope narrowing, queue caps) is supported by the Kimi artifact and is not disputed.

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json` (`"latency_s": 955.9`), `openai_gpt-5.6-sol.meta.json` (`"latency_s": 154.5`), `google_gemini-3.1-pro-preview.meta.json` (`"latency_s": 112.2`); ratios computed 6.19 and 8.52

## Claim 17: "Gemini was the thinnest (~15k chars) and the only Path A / 95% call"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:49-50`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`wc -c` over the four output files: Gemini 15,827 bytes — the smallest (Fable 36,832; Kimi 32,301; Sol 33,897) and ≈15k. Gemini is the only Path A ("**Decision Path:** Path A", `google_gemini-3.1-pro-preview.md:137`; the other three all declare Path C) and the only 95% confidence (others 78/78/75).

**Evidence:** byte counts via `wc -c runs/dd-cross-model-2026-07-30/*.md`; `google_gemini-3.1-pro-preview.md:135,137`; path/confidence lines cited under Claim 13

## Claim 18: "Fable defers the second vendor behind 021 Stage-1 context; Gemini treats baseline stabilization as a hard prerequisite for everything; Kimi challenges the state doc's own §1 serial ordering ('content adopted, schedule rejected')"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:51-54`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Fable: "defer [8] until 021 Stage-1 lands" where [8]/vendor-in-fact-check is the second-vendor candidate (`local_claude-fable-5.md:212`, and the table row 37 "vendor-in-fact-check deferred behind 021 Stage 1"). Gemini: "The foundational requirement for any multi-vendor recall addition or soundness routing is a stable baseline gate … 1 must be prioritized first" (`google_gemini-3.1-pro-preview.md:137`). Kimi: the quoted phrase appears verbatim — "*Changed: 0's serial schedule is its disqualifier — content adopted, schedule rejected.*" (`moonshotai_kimi-k3.md:132`).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:212`, `google_gemini-3.1-pro-preview.md:137`, `moonshotai_kimi-k3.md:103,132,149`

## Claim 19: "API cost: $1.21 total (Kimi $0.56 · Sol $0.42 · Gemini $0.23)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:57`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Meta cost fields: Kimi `"cost": 0.555516` → $0.56; Sol `"cost": 0.41725625` → $0.42; Gemini `"cost": 0.234646` → $0.23. Sum 1.20741825 → $1.21. All three per-arm roundings and the total check out (computed: 0.555516 + 0.41725625 + 0.234646 = 1.20741825).

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json`, `openai_gpt-5.6-sol.meta.json`, `google_gemini-3.1-pro-preview.meta.json` (usage.cost fields)

## Claim 20: Files table — five listed artifacts plus "`*.meta.json` | Per-run latency/usage/finish_reason (OpenRouter arms)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:59-68`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Directory listing matches exactly: `prompt.md`, `local_claude-fable-5.md`, `openai_gpt-5.6-sol.md`, `google_gemini-3.1-pro-preview.md`, `moonshotai_kimi-k3.md`, and three `.meta.json` files — one per OpenRouter arm, none for the local Fable arm, exactly as the "(OpenRouter arms)" qualifier states. Each meta.json contains `latency_s`, `usage`, and `finish_reason` fields as described.

**Evidence:** directory listing of `runs/dd-cross-model-2026-07-30/`; `*.meta.json` field names

## Claim 21: "its verdict is the pipeline's only 🔴-promotion channel" / "The fact-check verdict is the *only* channel that promotes a finding to 🔴 (see [Unified Severity Mapping](#unified-severity-mapping))" / "a single fact-check sample is a coin flip on the pipeline's only blocking channel"

**Location:** `skills/code-review/SKILL.md:27`, `skills/code-review/SKILL.md:264-265`, `skills/code-review/SKILL.md:1142`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The claim is contradicted by the very table it cites. The Unified Severity Mapping maps **five** critic outputs to 🔴 Must Fix: "| 🔴 Must Fix | Critical, High | Critical | Breaking | Structural | Incorrect (high confidence) |" (`skills/code-review/SKILL.md:976`) — i.e., Security Critical/High, Performance Critical, API-Consistency Breaking, and Architecture Structural all produce 🔴 rows without any fact-check involvement. The same file says so in prose twice: architecture-review "declares its own severity-to-rubric mapping (Structural → 🔴 …)" (:36) and "can produce blocking (🔴) findings" (:992). Even the empirical source being compressed — Result 16 — names two channels, not one: "Every 🔴 in all nine runs traces to a fact-check **Incorrect** verdict or an api-consistency **Breaking** finding" (`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:199-200`), and the state doc elsewhere calls it "the 🔴 monopoly held by fact-check-Incorrect / api-Breaking". The narrower true statements are: (a) fact-check Incorrect is the only *fact-check* verdict that reaches 🔴, and (b) among the Escalation Rule's corroboration options, fact-check Incorrect is one of three (failing test, fact-check Incorrect, human confirmation — `skills/code-review/SKILL.md:1005-1007`). Under no reading of "promotion channel" supported by the skill's own text is "only" correct. The core motivation for k=3 (the blocking channel is unstable, Result 14a) is unaffected — this is an overstatement of exclusivity, not a fabricated mechanism, so no hallucination-log entry is warranted. The same overstatement appears in `docs/decisions/log.md:48` (Claim 2) and `test/skills/code-review-factcheck-replication.bats:6` (Claim 24); the state doc's pre-existing line 50 ("Per Result 16, a fact-check Incorrect verdict is the *only* thing that promotes a finding to 🔴") is the upstream source but is not part of this branch's diff.

**Evidence:** `skills/code-review/SKILL.md:36,974-978,992,1005-1007`, `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:197-201,380-382`

## Claim 22: "on identical input, the same comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡 (`docs/thoughts/code-review-evaluation-state.md` §1.1, Result 14a)" and "the observed failure mode is under-calling, not over-calling (state doc §1.1)"

**Location:** `skills/code-review/SKILL.md:266-268,325-328`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both statements reproduce the cited section faithfully: "the same `WARY_MOOD_DURATION` comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡" (`docs/thoughts/code-review-evaluation-state.md:52-54`); "take the **most severe verdict** any run assigned, not the majority … the observed failure mode is under-calling, not over-calling" (:62-65). Per the Unified Severity Mapping, Incorrect-high → 🔴 and Mostly Accurate → 🟡, so the 🔴/🟡 flip characterization is also internally consistent (`skills/code-review/SKILL.md:976-977`).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:51-65`, `skills/code-review/SKILL.md:976-977`

## Claim 23: Severity order "`Incorrect (high confidence)` > `Incorrect (medium confidence)` > `Stale` > `Mostly Accurate` > `Unverifiable` > `Verified`" (as the definition of "most severe")

**Location:** `skills/code-review/SKILL.md:323-325`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The order is consistent with the tier mapping the pipeline consumes: Incorrect-high is the sole fact-check verdict in 🔴; Incorrect-medium, Stale, and Mostly Accurate all map to 🟡; Unverifiable to 🟢 ("| 🟡 Must Address | … | Incorrect (medium confidence), Stale, Mostly Accurate |", "| 🟢 Consider | … | Unverifiable |", `skills/code-review/SKILL.md:977-978`). The intra-🟡 ordering (Stale above Mostly Accurate) is a new convention introduced here, not contradicted by anything else in the repo.

**Evidence:** `skills/code-review/SKILL.md:974-978`

## Claim 24: bats header — "The fact-check verdict is the pipeline's only 🔴-promotion channel and is the least stable judgment in it (Result 14a: the same defect rated Incorrect by one run and Mostly Accurate by another, on identical input)"

**Location:** `test/skills/code-review-factcheck-replication.bats:6-8`
**Type:** Architectural / Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

Split verdict driven by the more severe half: the "only 🔴-promotion channel" clause is the same overstatement analyzed in Claim 21 (the mapping table's 🔴 row lists five sources; Result 16 itself names fact-check Incorrect *or* api-consistency Breaking). The Result 14a half is accurate (see Claim 22 evidence). Confidence Medium for this instance because it is a comment paraphrasing the design rationale rather than normative skill text — but it propagates the same false exclusivity and should be corrected alongside Claim 21's instances.

**Evidence:** `skills/code-review/SKILL.md:974-978`, `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:199-200`, `docs/thoughts/code-review-evaluation-state.md:51-54`

## Claim 25: bats header — "Same enforcement rationale as code-review-assurance-contract.bats: an unenforced prose instruction does not execute."

**Location:** `test/skills/code-review-factcheck-replication.bats:12-14`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The referenced file exists at `test/skills/code-review-assurance-contract.bats` and states the same rationale: "this repo's standing evidence (the override log that went unwritten for nine runs because only prose asked for it) is that an unenforced instruction does not execute. These tests are the enforcement." (`test/skills/code-review-assurance-contract.bats:14-17`).

**Evidence:** `test/skills/code-review-assurance-contract.bats:14-17`

## Claim 26: The test file's assertions match the skill text they claim to enforce ("These tests assert the contract is stated")

**Location:** `test/skills/code-review-factcheck-replication.bats:12-14,25-100`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Executed: `bats test/skills/code-review-factcheck-replication.bats` — all 10 tests pass against the current `skills/code-review/SKILL.md` (output: "ok 1" through "ok 10", including "ok 5 the severity order is stated and runs Incorrect-high first, Verified last" and "ok 10 the Confirmed-Good cross-check scans the per-replicate reports too"). Each grep target was independently confirmed present in the skill during Claims 1, 4, 5, and 23.

**Evidence:** bats run output (10/10 ok), `skills/code-review/SKILL.md:258-345,936-939,1065-1068`

---

## Claims Requiring Attention

### Incorrect
- **Claim 2** (`docs/decisions/log.md:48`): row 26 repeats "the pipeline's *only* 🔴-promotion channel" — the skill's own mapping table lists five 🔴 sources; Result 16 names two.
- **Claim 16** (`runs/dd-cross-model-2026-07-30/README.md:49`): "~9× Sol's latency" — actual ratio is 6.2× (955.9/154.5); ~9× matches Kimi-vs-Gemini (8.5×), likely the wrong arm.
- **Claim 21** (`skills/code-review/SKILL.md:27,264,1142`): "only 🔴-promotion channel / only blocking channel" contradicted by the Unified Severity Mapping it cites (Security Critical/High, Performance Critical, API Breaking, Architecture Structural also → 🔴).
- **Claim 24** (`test/skills/code-review-factcheck-replication.bats:6`): same exclusivity overstatement propagated into the test file's header comment.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`docs/thoughts/code-review-evaluation-state.md:41`): "implemented … exactly as shaped below" — implementation deliberately diverges from the shape's "claim text" clustering (semantic substance + ±5-line tolerance instead); "exactly" overstates.

### Unverifiable
- **Claim 9** (`runs/dd-cross-model-2026-07-30/README.md:3`): byte-identical delivery of `prompt.md` to all four arms — no send-side artifact exists; response-side token counts are consistent but not probative.
- **Claim 14** (`runs/dd-cross-model-2026-07-30/README.md:22-25,37`): Fable arm's ~5 min latency and read-restriction instruction — no meta.json or invocation transcript for the local arm.

## Goal-Alignment Note
- Answered: yes
- Out of scope: claims *inside* the immutable model-output artifacts and `prompt.md` (per scope spec, external model outputs are not this repo's claims); pre-existing unchanged lines such as `docs/thoughts/code-review-evaluation-state.md:50` (the upstream source of the "only 🔴-promotion channel" wording) — noted as upstream context under Claim 21 but not verdicted, since it is not in this branch's diff.
- Escalate: the four "only 🔴-promotion channel" instances (Claims 2, 21, 24) share one upstream source — the state doc's pre-existing Result-16 compression at `docs/thoughts/code-review-evaluation-state.md:50`, which drops api-consistency Breaking. Fixing only the in-diff instances will leave the source to re-propagate; the orchestrator may want a follow-up touching that line even though it is outside this diff.
