# Code Fact-Check Report

**Commit:** e9d05ea
**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** `git diff main...HEAD` on branch `exp/cross-model-openrouter-sweep` (skills/code-review/SKILL.md, docs/decisions/log.md, docs/thoughts/code-review-evaluation-state.md, runs/dd-cross-model-2026-07-30/README.md, test/skills/code-review-factcheck-replication.bats, plus branch commit messages; immutable experiment artifacts under runs/ checked only as evidence for claims made *about* them)
**Checked:** 2026-07-30
**Total claims checked:** 24
**Summary:** 14 verified, 4 mostly accurate, 0 stale, 2 incorrect, 4 unverifiable

Checked docs/reviews/hallucination-patterns.md first: the Patterns section is empty ("Append entries below this line" with no entries), so no known suspect patterns applied.

---

## Claim 1: "Stage 1 of `code-review` runs `code-fact-check` as k=3 parallel replicates on byte-identical prompts; the orchestrator merges by claim cluster (file, ±5-line range, claim substance) taking the **most severe** verdict any replicate assigned (Incorrect-high > Incorrect-medium > Stale > Mostly Accurate > Unverifiable > Verified), records per-replicate verdicts on every merged claim, and reports the cluster agreement rate in a `## Verdict stability` section"

**Location:** `docs/decisions/log.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every element of this description is present in `skills/code-review/SKILL.md`. Stage 1 heading: "### Stage 1: Code Fact-Check (k=3 replicated)" (`skills/code-review/SKILL.md:258`). The merge procedure states "Two claims are the same claim when they cite the same file, overlapping line ranges (±5 lines), and assert substantially the same thing", "Take the most severe verdict any replicate assigned... `Incorrect (high confidence)` > `Incorrect (medium confidence)` > `Stale` > `Mostly Accurate` > `Unverifiable` > `Verified`", "Record per-replicate verdicts on every merged claim", and "End the merged report with a `## Verdict stability` section" (paraphrased with embedded quotes from the Stage 1 merge steps, `skills/code-review/SKILL.md:305-333` region as shown in the branch diff). The contract test `test/skills/code-review-factcheck-replication.bats` asserts each element and all 10 tests pass (`1..10`, `ok 1`–`ok 10` on this checkout).

**Evidence:** `skills/code-review/SKILL.md:258-333`, `test/skills/code-review-factcheck-replication.bats:1-100` (executed, 10/10 pass)

## Claim 2: "a fact-check Incorrect verdict is the pipeline's *only* 🔴-promotion channel"

**Location:** `docs/decisions/log.md:48` (also asserted at `skills/code-review/SKILL.md:27` and `skills/code-review/SKILL.md:264`; see Claims 16–17)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The claim's own cited source contradicts the word "only" in two ways. First, Result 16 — the empirical basis — names *two* channels: "Every 🔴 in all nine runs traces to a fact-check **Incorrect** verdict or an **api-consistency Breaking** finding" (`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:199-200`), and the same doc later refers to "the 🔴 monopoly held by fact-check-Incorrect / api-Breaking (Result 16)" (`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:403`). Second, the Unified Severity Mapping table in the skill itself maps five sources to 🔴: "| 🔴 Must Fix | Critical, High | Critical | Breaking | Structural | Incorrect (high confidence) |" (`skills/code-review/SKILL.md:976`). The narrower "fact-check-only" phrasing is inherited from the pre-existing state doc §1.1 line ("Per Result 16, a fact-check Incorrect verdict is the *only* thing that promotes a finding to 🔴", `docs/thoughts/code-review-evaluation-state.md:50` — unchanged on this branch) and from `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:256-257` ("the *sole* channel that can produce a 🔴"), so the sources are internally inconsistent. The substance — fact-check Incorrect is the dominant promotion channel and the unstable one — holds; "only" overstates it.

**Evidence:** `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:197-203,256-257,403`, `skills/code-review/SKILL.md:974-978`, `docs/thoughts/code-review-evaluation-state.md:50`

## Claim 3: "Result 14a showed it flipping between Incorrect and Mostly Accurate on identical input — the entire blocking channel rested on a single sample of the least stable judgment in the system (J_self on 🔴 rows 0.14–0.25)"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The state doc records exactly this: "the same `WARY_MOOD_DURATION` comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡" (`docs/thoughts/code-review-evaluation-state.md:52-53`) and "J_self restricted to 🔴 rows is **0.14–0.25**" (`docs/thoughts/code-review-evaluation-state.md:57`).

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:50-57`

## Claim 4: "Per-replicate reports (`code-fact-check-report-r1..3.md`) persist for audit and for the decision-25 Confirmed-Good cross-check, which now scans them too (an observation recorded by a single replicate still counts against a ✅ row — this is the piece decision 25 marked out of scope)"

**Location:** `docs/decisions/log.md:48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The skill's Confirmed-Good move 4 was edited on this branch to read "re-read the merged fact-check report **and each per-replicate report** (`code-fact-check-report-r*.md` — an observation recorded by only one replicate may be absent from the merged claim it lost the severity contest to, and it still counts)" (branch diff to `skills/code-review/SKILL.md`, Confirmed-Good section). The Output Locations tree lists all three `-r1..3` files as "(replicate — audit + Confirmed-Good observation scan)". The out-of-scope mapping to decision 25 is supported: row 25 states "a run whose fact-check never observed the relevant fact is not made to observe it. Closing that gap needs the k≥3 fact-check of §1.1, deliberately out of scope" (`docs/decisions/log.md:47`). Confidence Medium only because row 25's out-of-scope gap (no observation existing at all) is closed by k=3 replication *probabilistically*, not deterministically — the row's parenthetical is a fair but slightly generous restatement.

**Evidence:** `skills/code-review/SKILL.md:933-939` (Confirmed-Good move 4), `skills/code-review/SKILL.md:1062-1072` (Output Locations), `docs/decisions/log.md:47`

## Claim 5: "§1.1's falsifier stands: ≥90% agreement on a ≥20-claim cumulative sample drops k to 2"

**Location:** `docs/decisions/log.md:48` (same falsifier restated in `skills/code-review/SKILL.md` Stage 1 merge step 4 and `docs/thoughts/code-review-evaluation-state.md:198`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

State doc §1.1: "if k=3 fact-check verdicts agree ≥90% of the time on a 20-claim sample, the instability is smaller than Result 14a suggests and k can drop to 2" (`docs/thoughts/code-review-evaluation-state.md:68-69`). The "≥20" vs the source's "a 20-claim" is an immaterial tightening. The skill carries it: "If cumulative measurements across runs show ≥90% verdict agreement on a ≥20-claim sample, k can drop to 2 — that is §1.1's stated falsifier" (branch diff, Stage 1 merge step 4), and bats test 8 asserts its presence.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:68-69`, `skills/code-review/SKILL.md:327-333`, `test/skills/code-review-factcheck-replication.bats:78-81`

## Claim 6: "all four families in the 2026-07-30 DD sweep (`runs/dd-cross-model-2026-07-30/`) independently ranked this action first"

**Location:** `docs/decisions/log.md:48` (same claim at `runs/dd-cross-model-2026-07-30/README.md:31-32`, `docs/thoughts/code-review-evaluation-state.md:43-45`, and commit b6114ac)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four run artifacts carry the ★ recommendation on the k≥3/k=3 fact-check candidate: Fable "╭─ [2] k≥3 fact-check, most-severe-wins   ★ recommended" (`runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:187`); Sol "╭─ [2] Fact-check replication   ★ recommended" (`openai_gpt-5.6-sol.md:256`); Gemini "╭─ [1] k=3 incumbent fact-check   ★ recommended" (`google_gemini-3.1-pro-preview.md:119`); Kimi "╭─ [3] k≥3 fact-check, most-severe-wins   ★ recommended" (`moonshotai_kimi-k3.md:153`).

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:187,207`, `openai_gpt-5.6-sol.md:256,283`, `google_gemini-3.1-pro-preview.md:119,135`, `moonshotai_kimi-k3.md:153,171`

## Claim 7: "implemented in `skills/code-review/SKILL.md` Stage 1 exactly as shaped below (k=3, byte-identical prompts, cluster + most-severe-wins, per-replicate verdict logging, agreement rate reported per run in the merged report's `## Verdict stability` section)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:41-44`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Every item in the parenthetical is implemented (see Claim 1). The word "exactly" slightly overstates fidelity to the §1.1 shape: §1.1 says "cluster claims by (file, line-range, claim text)" (`docs/thoughts/code-review-evaluation-state.md:61-62`), while the implementation deliberately deviates — "match on (file, line-range, claim substance), not on string equality" plus an explicit ±5-line tolerance (SKILL.md Stage 1 merge step 1). The deviation is a refinement, not a contradiction of intent, but "exactly as shaped" is not literally true of the clustering key.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:61-62`, `skills/code-review/SKILL.md:310-314`

## Claim 8: "**Instrumented** (log row 26): every k=3 run now reports its cluster agreement rate in the merged report's `## Verdict stability` section. Still zero data points"

**Location:** `docs/thoughts/code-review-evaluation-state.md:198` (open question #2 status)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Log row 26 exists (`docs/decisions/log.md:48`). The skill's merge step 4 requires the section and the rate: "End the merged report with a `## Verdict stability` section: total clusters... and the resulting agreement rate" (SKILL.md Stage 1 merge step 4); bats tests 7–8 enforce it. "Still zero data points" is consistent with the same file's own admission "the first k=3 run has not executed" (`docs/thoughts/code-review-evaluation-state.md:47`) and with no merged `code-fact-check-report.md` from a k=3 run existing on this branch.

**Evidence:** `skills/code-review/SKILL.md:327-333`, `test/skills/code-review-factcheck-replication.bats:71-81`, `docs/decisions/log.md:48`

## Claim 9: "Four frontier models were given a **byte-identical prompt** (`prompt.md` in this directory)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:3-4` (also "identical bytes to all four models", README.md files table, and commit b6114ac "Same byte-identical prompt")
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

`prompt.md` exists (102,388 bytes) and embeds the three claimed inputs (see Claim 10). But no harness script, request log, or per-arm prompt hash is committed, so nothing in the repo records what bytes were actually transmitted to each of the four arms. The meta.json prompt-token counts differ across providers (23,759 / 22,737 / 22,856 — `*.meta.json`), which is consistent with identical bytes tokenized by different tokenizers but does not prove it. Paraphrased — no quote available because the transmission step left no artifact to quote.

**Evidence:** `runs/dd-cross-model-2026-07-30/prompt.md` (exists, 102388 bytes), `runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.meta.json`, `moonshotai_kimi-k3.meta.json`, `openai_gpt-5.6-sol.meta.json`

## Claim 10: "Inputs embedded in the prompt: `docs/thoughts/code-review-evaluation-state.md`, `skills/divergent-design/SKILL.md`, and the full `workflows/divergent-design.md`"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:9-11`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`prompt.md` contains all three as labeled sections: "# Input 1: docs/thoughts/code-review-evaluation-state.md" (`prompt.md:37`), "# Input 2: skills/divergent-design/SKILL.md" (`prompt.md:353`), "# Input 3: workflows/divergent-design.md" (`prompt.md:412`), and the embedded state doc's §1.1 heading matches the pre-branch version ("### 1.1 Run `code-fact-check` k≥3 times and combine, before anything downstream", `prompt.md:77`).

**Evidence:** `runs/dd-cross-model-2026-07-30/prompt.md:37,77,353,412`

## Claim 11: "All four runs are **single-response, no tools, prompt-inline** — the Result-10-comparable config of the evaluation-state doc §5.1"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:19-20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The §5.1 reference is sound: §5.1 "Comparability — the rule that governs everything" states "The **only** prior rows directly comparable to an OpenRouter sweep are **Result 10**" (`docs/thoughts/code-review-evaluation-state.md:289,296`), and the doc's config table marks Result 10 as "**headless, diff inline, no tools**" (`docs/thoughts/code-review-evaluation-state.md:215`). The three OpenRouter meta files show `"finish_reason": "stop"` and `"attempt": 1` (single response); the Fable artifact self-describes as "Single-shot, headless" (`local_claude-fable-5.md:3`) and "Prior pruning grep: not runnable in this setting" (`local_claude-fable-5.md:9`). Confidence Medium because, as with Claim 9, the run conditions themselves are attested by the artifacts rather than independently recorded.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:215,289-296`, `runs/dd-cross-model-2026-07-30/*.meta.json`, `local_claude-fable-5.md:3,9`

## Claim 12: "The local Fable arm ran inside Claude Code as a subagent but was explicitly forbidden to read any file other than the prompt, to stay comparable"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:22-25` (also commit b6114ac: "barred from reading any file beyond the prompt")
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The instruction given to the Fable subagent is not preserved anywhere in the repo, so the "explicitly forbidden" condition cannot be checked. The artifact's internals are consistent with it: "Prior-decision scan (from the material provided inline)" (`local_claude-fable-5.md:11-12`) and "Prior pruning grep: not runnable in this setting" (`local_claude-fable-5.md:9`) — the run behaves as if it had no file access. Consistent-with is not proof; the constraint itself is unrecorded.

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:3,9,11-12`; paraphrased — no quote available for the constraint itself because the subagent's launch prompt was not committed.

## Claim 13: "Per §5.2 discipline: when comparing, score on *which candidate actions and constraints each model surfaced*, not on cosmetic scoring differences"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:26-28`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

§5.2 exists and carries the analogous rule, but its actual content is about review outputs, not DD outputs: "### 5.2 Score on detection, not on tier ... Compute it over **issue identity** — same file, same underlying mechanism, band-agnostic" (`docs/thoughts/code-review-evaluation-state.md:303-307`). "Which candidate actions and constraints each model surfaced" is the README's own extension of that discipline to DD artifacts; §5.2 never mentions candidates, constraints, or scoring matrices. The citation is an apt analogy presented as a direct instruction from §5.2.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:303-309`

## Claim 14: "the strongest cross-family agreement this program has recorded on any question"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:33`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Legibility-target:** for-orchestrator-synthesis

The 4/4 convergence itself is verified (Claim 6). The superlative — strongest agreement *ever recorded by the program* — would require an exhaustive comparison against every prior cross-family measurement (the §5.0 sweep, the nine eval cells, prior experiment docs), none of which record a comparable "agreement on a question" metric. No prior 4/4 cross-family convergence was found in the state doc or experiment results docs during this check, so the claim is plausible, but the comparison class is not enumerated anywhere. Paraphrased — no quote available because no artifact defines or ranks "cross-family agreement" across the program's history.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md` §5.0–§5.4 (no comparable metric found)

## Claim 15: OpenRouter table metrics — "GPT-5.6 Sol | 155 s | 9,147 (2,233) | — | 5 | C | 78% ... Gemini 3.1 Pro | 112 s | 15,594 (11,870) | — | 4 | A | 95% ... Kimi K3 | 956 s | 32,487 (24,306) | 14 | 5 | C | 75%" and Fable "16 | 5 | C | 78%"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:37-40`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Meta files: Sol `"latency_s": 154.5` (rounds to 155), `"completion_tokens": 9147`, `"reasoning_tokens": 2233`; Gemini `"latency_s": 112.2`, `15594`, `11870`; Kimi `"latency_s": 955.9` (rounds to 956), `32487`, `24306` — all match. Candidates/survivors/path/confidence: Fable "Survivors: [2] [5] [6] [8] [9] (5 of 16)" and "confidence 78%", "Path C" (`local_claude-fable-5.md:112,207,210`); Sol "**Survivors:** [2], [3], [4], [5], [7]" (5), "confidence 78%", "Path C" (`openai_gpt-5.6-sol.md:162,283,290`); Gemini "**Surviving Candidates:** [1], [3], [4], [11]" (4), "confidence 95%", "Path A" (`google_gemini-3.1-pro-preview.md:71,135,137`); Kimi "**Candidates (14)**", "Survivors (5)", "confidence 75%", "Decision path: C" (`moonshotai_kimi-k3.md:12,105,171,176`). Fable's "~5 min" latency has no meta file — covered separately as Claim 23 note; the recommendation-column prose matches each artifact's recommendation except the Kimi runner-up (Claim 16).

**Evidence:** `runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json`, `google_gemini-3.1-pro-preview.meta.json`, `moonshotai_kimi-k3.meta.json`, `local_claude-fable-5.md:112,207,210`, `openai_gpt-5.6-sol.md:162,283,290`, `google_gemini-3.1-pro-preview.md:71,135,137`, `moonshotai_kimi-k3.md:12,105,171,176`

## Claim 16: "Kimi K3 | ... | k≥3 fact-check scoped to promotion-candidate claims (k set by pre-flight disagreement measurement); runner-up doc-order status quo"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:40`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The first half is accurate — Kimi's stress-test pass narrowed scope: "resampling scoped to promotion-candidate claims" and "k is set by a day-scale pre-flight measurement, not fixed at 3" (`moonshotai_kimi-k3.md:101,128`). But the runner-up is misattributed. Kimi's recommendation line reads "▶ recommend [3] k≥3 fact-check, most-severe-wins · confidence 75% · **runner-up [2]**, axis = assurance-now vs evidence-first" (`moonshotai_kimi-k3.md:171-172`), and candidate [2] is "**Measurement-first:** before any skill edit, run the cheap queued arms..." (`moonshotai_kimi-k3.md:17`). The doc-order status quo is candidate [0] ("Doc-as-written (status quo)", `moonshotai_kimi-k3.md:14`) — a survivor, but not the runner-up. Not a fabrication (both candidates exist); a misattribution.

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:14,17,101,128,171-172`

## Claim 17: "**Template fidelity:** all four rendered the Decision presentation block with the box-drawing scorecard, legend, ★ marker, and recommendation banner; none left unfilled `<…>` slots. All four honored the no-`AskUserQuestion` constraint."

**Location:** `runs/dd-cross-model-2026-07-30/README.md:44-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Box-drawing (`╭─`) and ★ markers appear in all four artifacts (Claim 6 quotes); the legend glyph `●` appears in all four (`rg -l '●'` matches all four output files); each has a `▶ recommend ...` banner. A search for unfilled angle-bracket template slots (`<[a-zA-Z…]...>` excluding URLs) across the four outputs returned no matches. The prompt's no-`AskUserQuestion` constraint appears 10 times in `prompt.md`; the only occurrences in the outputs are compliance statements ("no `AskUserQuestion` issued" — `moonshotai_kimi-k3.md:176`, "(No native `AskUserQuestion` is issued)" — `google_gemini-3.1-pro-preview.md:137`), and Fable/Sol contain no invocation of it.

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:187,207`, `openai_gpt-5.6-sol.md:256,283,286`, `google_gemini-3.1-pro-preview.md:119,135,137`, `moonshotai_kimi-k3.md:153,171,176`; slot/glyph greps over all four files (no unfilled slots found)

## Claim 18: "Kimi produced the most aggressive stress-test pass (scope narrowing of k≥3 to promotion decisions only; queue-volume caps on human routing) at ~9× Sol's latency"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:48-49`
**Type:** Performance
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The stress-test content is accurate: "only the **promotion decision** needs k≥3" (`moonshotai_kimi-k3.md:128`) and "queue volume capped and logged" (`moonshotai_kimi-k3.md:130`). The multiplier is wrong: 955.9 s / 154.5 s = **6.19×** Sol's latency, verified by arithmetic-eval (`[arithmetic-eval] 955.9 / 154.5 -> 6.18705501618123`). The ~9× figure matches Kimi vs *Gemini* instead (955.9 / 112.2 = 8.52 ≈ 9, `[arithmetic-eval] 955.9 / 112.2 -> 8.519607843137255`) — the ratio appears to have been computed against the wrong arm. Actual: ~6× Sol, ~8.5× Gemini.

**Evidence:** `runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json` (`"latency_s": 154.5`), `moonshotai_kimi-k3.meta.json` (`"latency_s": 955.9`), `google_gemini-3.1-pro-preview.meta.json` (`"latency_s": 112.2`); arithmetic-eval runs above

## Claim 19: "Gemini was the thinnest (~15k chars) and the only Path A / 95% call"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:49-50`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Byte counts: Gemini 15,827 vs Kimi 32,301, Sol 33,897, Fable 36,832 (`wc -c` on the four output files) — smallest, and ~15k. Paths/confidences: Gemini "Path A", "confidence 95%" (`google_gemini-3.1-pro-preview.md:135,137`); the other three are Path C at 78/78/75% (Claim 15 evidence). "Fable and Sol landed near-identical confidence (78%)" on the adjacent line also checks out (both exactly 78%).

**Evidence:** `wc -c runs/dd-cross-model-2026-07-30/*.md`, `google_gemini-3.1-pro-preview.md:135,137`, `local_claude-fable-5.md:207`, `openai_gpt-5.6-sol.md:283`, `moonshotai_kimi-k3.md:171`

## Claim 20: "Fable defers the second vendor behind 021 Stage-1 context; Gemini treats baseline stabilization as a hard prerequisite for everything; Kimi challenges the state doc's own §1 serial ordering ('content adopted, schedule rejected')"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:54-57`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Fable: "gate it behind candidate 7 (021 Stage-1 context lands first)" for "[8] Second vendor scoped to the fact-check critic" and "defer [8] until 021 Stage-1 lands" (`local_claude-fable-5.md:117,212`). Gemini: "The foundational requirement for any multi-vendor recall addition or soundness routing is a stable baseline gate... 1 must be prioritized first" (`google_gemini-3.1-pro-preview.md:137`). Kimi: "*Changed: 0's serial schedule is its disqualifier — content adopted, schedule rejected.*" (`moonshotai_kimi-k3.md:132`) — verbatim.

**Evidence:** `runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:117,212`, `google_gemini-3.1-pro-preview.md:137`, `moonshotai_kimi-k3.md:132`

## Claim 21: "API cost: $1.21 total (Kimi $0.56 · Sol $0.42 · Gemini $0.23)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:57`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Meta files record `"cost": 0.555516` (Kimi → $0.56), `"cost": 0.41725625` (Sol → $0.42), `"cost": 0.234646` (Gemini → $0.23). Sum verified by arithmetic-eval: `[arithmetic-eval] 0.234646 + 0.555516 + 0.41725625 -> 1.20741825` → $1.21. All roundings correct; the local Fable arm has no API cost, consistent with its exclusion.

**Evidence:** `runs/dd-cross-model-2026-07-30/*.meta.json` cost fields; arithmetic-eval run above

## Claim 22: Files table — "`prompt.md` ... `local_claude-fable-5.md` ... `openai_gpt-5.6-sol.md` ... `google_gemini-3.1-pro-preview.md` ... `moonshotai_kimi-k3.md` ... `*.meta.json` | Per-run latency/usage/finish_reason (OpenRouter arms)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:61-68`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Directory listing matches exactly: the five named files plus `README.md` and exactly three `.meta.json` files — one per OpenRouter arm, none for the local Fable arm, as the table's "(OpenRouter arms)" qualifier states. Each meta.json contains `latency_s`, `usage`, and `finish_reason` fields as claimed.

**Evidence:** `ls runs/dd-cross-model-2026-07-30/` (8 files), `runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.meta.json` (fields `model`, `finish_reason`, `usage`, `latency_s`, `attempt`)

## Claim 23: "The fact-check verdict is the *only* channel that promotes a finding to 🔴 (see [Unified Severity Mapping](#unified-severity-mapping)) ... on identical input, the same comment defect was rated **Incorrect** by one run and **Mostly Accurate** by another, flipping the same finding between 🔴 and 🟡 (`docs/thoughts/code-review-evaluation-state.md` §1.1, Result 14a)"

**Location:** `skills/code-review/SKILL.md:264-270` (the "only 🔴-promotion channel" phrasing also at `skills/code-review/SKILL.md:27` and in the Important Reminders edit)
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Two sub-claims. The Result-14a flip is Verified — it quotes the state doc's account near-verbatim (`docs/thoughts/code-review-evaluation-state.md:51-54`), and the anchor target exists ("### Unified Severity Mapping", `skills/code-review/SKILL.md:970`). The "only channel" assertion is the same overstatement as Claim 2 — and here it is aggravated by pointing the reader at the very table that lists four *other* 🔴 sources ("Critical, High | Critical | Breaking | Structural" alongside "Incorrect (high confidence)", `skills/code-review/SKILL.md:976`). Also present: "the observed failure mode is under-calling, not over-calling (state doc §1.1)" in the merge step — Verified against "the observed failure mode is under-calling, not over-calling" (`docs/thoughts/code-review-evaluation-state.md:64`).

**Evidence:** `skills/code-review/SKILL.md:970-978`, `docs/thoughts/code-review-evaluation-state.md:51-54,64`, `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:199-200`

## Claim 24: bats header — "Validates the k=3 fact-check replication contract in skills/code-review/SKILL.md (docs/thoughts/code-review-evaluation-state.md §1.1, decision log row 26) ... Result 14a: the same defect rated Incorrect by one run and Mostly Accurate by another, on identical input ... Same enforcement rationale as code-review-assurance-contract.bats" — and the tests themselves assert what they claim

**Location:** `test/skills/code-review-factcheck-replication.bats:2-14` (behavioral check spans the whole file)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All references resolve: SKILL.md Stage 1 exists as described; state doc §1.1 and log row 26 exist (Claims 1, 3); `test/skills/code-review-assurance-contract.bats` exists on disk; the Result 14a paraphrase matches `docs/thoughts/code-review-evaluation-state.md:51-54`. Behaviorally, the suite was executed on this checkout: `1..10`, all 10 tests pass, and the `stage1()` helper's sed range (`/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/`) matches the comment "from its heading to the next ### heading" — "### Fact-Check Gate" is indeed the next `###` heading after Stage 1 in SKILL.md. Commit e9d05ea's "Contract test: ... (10 checks)" also matches the executed count.

**Evidence:** `bats test/skills/code-review-factcheck-replication.bats` (10/10 ok), `test/skills/code-review-assurance-contract.bats` (exists), `skills/code-review/SKILL.md:258,343` region, `docs/thoughts/code-review-evaluation-state.md:51-54`

---

## Claims Requiring Attention

### Incorrect
- **Claim 16** (`runs/dd-cross-model-2026-07-30/README.md:40`): Kimi's runner-up is misattributed — the artifact names **[2] Measurement-first** as runner-up, not the doc-order status quo ([0], a survivor but not runner-up).
- **Claim 18** (`runs/dd-cross-model-2026-07-30/README.md:48-49`): "~9× Sol's latency" — actual is 6.2× Sol (955.9/154.5); ~9× would be Kimi vs Gemini (8.5×).

### Stale
- (none)

### Mostly Accurate
- **Claim 2** (`docs/decisions/log.md:48`): "only 🔴-promotion channel" — Result 16 names fact-check-Incorrect *or* api-consistency-Breaking, and the severity mapping lists five 🔴 sources.
- **Claim 7** (`docs/thoughts/code-review-evaluation-state.md:41-44`): "exactly as shaped below" — the clustering key deviates (claim substance ±5 lines vs §1.1's "claim text").
- **Claim 13** (`runs/dd-cross-model-2026-07-30/README.md:26-28`): "Per §5.2 discipline" cites a section about detection-vs-tier scoring; the candidate/constraint framing is the README's own extension.
- **Claim 23** (`skills/code-review/SKILL.md:264-270`, also `:27`): same "only channel" overstatement as Claim 2, here pointing at the severity-mapping table that contradicts it.

### Unverifiable
- **Claim 9** (`runs/dd-cross-model-2026-07-30/README.md:3-4`): byte-identical transmission to all four arms — no harness log or prompt hash committed.
- **Claim 12** (`runs/dd-cross-model-2026-07-30/README.md:22-25`): Fable arm's file-read prohibition — launch prompt not preserved; artifact internals are consistent with it.
- **Claim 14** (`runs/dd-cross-model-2026-07-30/README.md:33`): "strongest cross-family agreement this program has recorded" — no comparable historical metric exists to rank against.
- **Claim 15 note / Fable latency** (`runs/dd-cross-model-2026-07-30/README.md:37`): "~5 min" for the local Fable arm has no meta file or timing record (the row's other values are verified; tracked here so the gap is visible).

## Goal-Alignment Note
- Answered: yes
- Out of scope: claims *inside* the immutable experiment artifacts (`runs/dd-cross-model-2026-07-30/*.md` model outputs and `prompt.md`) per the scoping instruction — they were used only as evidence for claims made about them; unchanged pre-existing prose in log.md rows 21/24/25 and untouched state-doc sections.
- Escalate: the two README Incorrect findings (Claims 16, 18) are one-line fixes in a mutable file; the "only 🔴-promotion channel" phrasing (Claims 2, 23) recurs in three shipped locations and in the pre-existing state doc §1.1 — worth one coordinated wording fix ("the only channel observed to fire in practice, alongside api-consistency Breaking") rather than piecemeal edits.
