# Performance Review — exp/cross-model-openrouter-sweep

**Scope:** `git diff main...HEAD` (13 files, +2375/−20). Substantive surface: `skills/code-review/SKILL.md`, `test/skills/code-review-factcheck-replication.bats`, `docs/` updates. `runs/dd-cross-model-2026-07-30/*` other than `README.md` are immutable data artifacts (read for context, not reviewed).
**Date:** 2026-07-30
**Commit:** e9d05ea
**Based on:** Stage-1 code-fact-check report (k=3, merged most-severe-wins), supplied by the orchestrator. Its findings are treated as established and are not re-verified here.

---

## Data Flow and Hot Paths

The reviewed change modifies an **orchestration process skill**, not runtime code. Its "performance" is the token, latency, and agent-count economics of a `code-review` run — a cost this repo treats as first-class (`docs/decisions/021-reviewer-context-management.md` scores candidates against a hard constraint H4, "stay in the cost/latency envelope", and discards multi-sample configs on it).

The pipeline is three serial stages with parallel fan-out inside each:

```
Stage 1  fact-check  ──►  Stage 1.5 gating ──►  Stage 2 critics  ──►  Stage 3 synthesis
  (was 1 agent)                                  (N parallel)          (orchestrator only)
  (now 3 parallel + orchestrator merge)
```

Call frequency: once per code-review invocation — a per-branch/per-PR operation, not a request handler. Under this skill's own hot-path gate that makes most of the pipeline a **cold path**; the exception is Stage 1, which every run executes and every run *blocks on* before any critic starts, and Stage 3, which every run executes before either deliverable is written. I tag those two as hot within the pipeline and everything else cold, and say so per finding.

Data sizes on this branch: the reviewed diff is +2375 lines, of which `runs/dd-cross-model-2026-07-30/prompt.md` alone is 1004 lines and the four model-output artifacts are 179–354 lines each. `skills/code-review/SKILL.md` is now 1178 lines and `skills/code-fact-check/SKILL.md` is 380 lines — the latter is pasted verbatim into each Stage-1 agent prompt (`skills/code-review/SKILL.md:274-275`).

**Baseline availability:** the repo holds no measured latency, token, or dollar figure for an agentic `code-review` run. The figures that do exist — `$1.21` total and 112–956 s per arm in `runs/dd-cross-model-2026-07-30/README.md:35-57`, and the `~$0.33 median band` in `docs/decisions/021-reviewer-context-management.md:141` — measure the **single-response, no-tools OpenRouter sweep arms**, explicitly "not the agentic pipeline" (`runs/dd-cross-model-2026-07-30/README.md:18-21`). They are therefore not a baseline for anything below. `docs/thoughts/code-review-evaluation-state.md:32-33` states the k=3 path itself is unmeasured: "Not yet measured: the first k=3 run has not executed". Findings are labelled accordingly.

---

## Findings

#### Orchestrator holds four fact-check reports in context for the rest of the run, and the merge is uncapped

**Severity:** High
**Location:** `skills/code-review/SKILL.md:311-344`, `skills/code-review/SKILL.md:936-940`
**Move:** Trace the memory lifecycle (context held longer than needed) / work moved to the wrong place
**Classification:** Macro (context growth scales with k × report size, with no cap or release point) / Hot path (Stage 1 blocks Stage 2; Stage 3 blocks both deliverables)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

**Evidence** — the merge requires the orchestrator to ingest all three replicate reports:

> ```
> Produce the canonical `docs/reviews/code-fact-check-report.md` yourself by merging the
> replicate reports. This is mechanical collation, not analysis — you are combining verdicts
> the replicates already produced, never adding claims or evidence of your own (Mandatory
> Execution Rule 1 still stands).
> ```
> (`skills/code-review/SKILL.md:313-316`)

and they are then explicitly retained rather than released:

> ```
> per-replicate reports stay on disk for audit and for the Confirmed-Good cross-check's
> observation scan.
> ```
> (`skills/code-review/SKILL.md:344`)

with Stage 3 re-entering all four:

> ```
> For each candidate ✅ row, re-read the merged fact-check report **and each per-replicate
> report** (`code-fact-check-report-r*.md` — an observation recorded by only one replicate
> may be absent from the merged claim it lost the severity contest to, and it still counts)
> ```
> (`skills/code-review/SKILL.md:937-940`)

The orchestrator previously carried one fact-check report through Stages 1.5→3 alongside N critic outputs, the rubric, and the synthesis. It now carries four, and there is no instruction anywhere permitting it to drop the replicate reports from context after the merge — Stage 3 needs them again, so it cannot. This is a **structural** context cost, not a per-call constant: it scales with k and with report length, and the retention window is the whole run.

This contradicts the file's own stated performance invariant, applied twice elsewhere for exactly this reason:

> ```
> Do not paste the full diff into agent prompts. Pass the scope specification so each agent runs its own `git diff` — this avoids context budget issues with large diffs.
> ```
> (`skills/code-review/SKILL.md:100`; restated at `:1144`)

The same discipline — keep bulk artifacts out of the orchestrator's window, pass pointers — is not applied to the replicate reports, which are now the largest bulk artifact the orchestrator holds. Decision 021's whole subject is reviewer context management; this change moves in the opposite direction without noting it.

Secondary, same location: the merge's step 1 is a semantic cluster across three unordered claim lists —

> ```
> 1. **Cluster claims across replicates.** Two claims are the same claim when they cite the
>    same file, overlapping line ranges (±5 lines), and assert substantially the same thing.
>    Clustering is semantic — replicates word the same claim differently; match on
>    (file, line-range, claim substance), not on string equality.
> ```
> (`skills/code-review/SKILL.md:319-322`)

Semantic matching on (file, ±5-line range, substance) is pairwise: with n claims per replicate it is O(k·n²) comparisons in the worst case, executed as in-context reasoning rather than code. For n≈10–20 claims this is tens to low hundreds of comparisons — tractable, but it is new **serial** work inserted between Stage 1 and Stage 2, on the one path every run blocks on. Neither the report size nor the claim count is bounded anywhere in the spec.

**Recommendation:** Add an explicit context-release rule — either (a) require the merge to carry forward, per cluster, the single-replicate observations that lost the severity contest (they are the only reason Stage 3 needs the replicate files at all, per `:938-939`), so the replicate reports can be dropped from context after Stage 1 and Stage 3 reads only the merged report; or (b) state that Stage 3's cross-check re-reads the replicate files **from disk on demand**, per ✅ row, rather than holding them resident. Option (a) is strictly better and preserves the decision-25 gap-closure that motivated the scan. Also cap replicate report length (e.g. "claims only, no restated diff context") so the merge input is bounded. Before merging, capture one k=3 run's orchestrator token usage so the context cost is a number rather than an argument.

---

#### Stage-1 fact-check agent spend and file-read work triple on every run

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:214`, `skills/code-review/SKILL.md:258-262`, `skills/code-review/SKILL.md:303-304`
**Move:** Count the hidden multiplications
**Classification:** Micro (fixed ×3 constant factor per run, not data-dependent) / Hot path (Stage 1 runs on every invocation and blocks Stage 2) — escalated from Low because the constant is large and lands on the most expensive stage
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

**Evidence:**

> ```
> Spawn **three** agents with the code-fact-check skill, in parallel, on **byte-identical
> prompts** — same skill text, same scope spec, same instructions, differing only in the
> output path each is told to write.
> ```
> (`skills/code-review/SKILL.md:260-262`)

> ```
> - Total agent count (3 fact-check replicates + N critics)
> ```
> (`skills/code-review/SKILL.md:214`)

Each replicate independently executes the full Stage-1 prompt: the 380-line `skills/code-fact-check/SKILL.md` pasted inline (`:274-275`), plus its own `git diff main...HEAD` and its own file reads across the diff (`:100`). On a diff the size of this branch (+2375 lines, including a 1004-line artifact) that read work is paid three times instead of once, as is the input-token cost of the pasted skill text. Latency is *not* tripled — see What Looks Good — but token spend and per-agent tool-call volume are.

This is the deliberate, decision-recorded cost of the change (`docs/decisions/log.md` row 26), not a defect. It is recorded here so it is visible as a number rather than a footnote, and because nothing in the diff bounds it: the k-reduction path requires cumulative data that does not exist yet (see the next finding).

**Recommendation:** Accept, but instrument. Add the per-run agent count and, if obtainable, Stage-1 token usage to the merged report's `## Verdict stability` section alongside the agreement rate — the section already exists (`:328-337`) and is the natural place to make the cost as visible as the benefit. Capture the first k=3 run's numbers before the second, so the ~3× is measured rather than assumed.

---

#### Confirmed-Good cross-check scan grows from N×1 to N×4 report passes

**Severity:** Medium
**Location:** `skills/code-review/SKILL.md:936-940`
**Move:** Count the hidden multiplications (loop body × new inner dimension)
**Classification:** Macro (work = ✅ rows × (k+1) reports; grows on both axes) / Hot path (Stage 3, runs on every review before either deliverable is published)
**Confidence:** Medium
**Baseline:** 82 `✅ Confirmed Good` rows across 11 archived evaluation cells ≈ 7.5 rows per run — measured, `docs/thoughts/code-review-evaluation-state.md:138` ("**0 of 82** Confirmed Good rows across all archived cells carried a checkable citation before this change") and `docs/decisions/log.md` row 25.

**Evidence:**

> ```
> **4. Cross-check every ✅ row against the fact-check reports (Stage 3, before publishing).**
> For each candidate ✅ row, re-read the merged fact-check report **and each per-replicate
> report** (`code-fact-check-report-r*.md` — an observation recorded by only one replicate
> may be absent from the merged claim it lost the severity contest to, and it still counts)
> ```
> (`skills/code-review/SKILL.md:936-939`)

The pre-change instruction was "re-read the fact-check report" — one document per ✅ row. It is now four. At the measured ~7.5 ✅ rows per run that is ~30 report passes per Stage 3 instead of ~7.5. The inner dimension is `k`, so the cost tracks whatever `k` is set to; the outer dimension is the ✅-row count, which the rubric does not cap.

The impact is attention and context, not I/O — these are in-context re-scans, and re-scanning the same four documents 7–8 times is exactly the pattern where an orchestrator starts skipping. The correctness risk (a missed contradiction) is the security/correctness reviewers' concern; the performance concern is that the instruction as written scales multiplicatively on the pipeline's last blocking step.

**Recommendation:** Invert the loop. Build the observation index **once** — a single pass over merged + replicate reports producing a flat list of (file, symbol, observation, source-replicate) — then match each ✅ row against that index. That converts N×(k+1) document passes into (k+1) + N cheap lookups, preserves the decision-25 semantics exactly, and composes with the previous finding's recommendation (a) since the index is precisely the "carry forward the losing single-replicate observations" artifact.

---

#### No adaptive path: k stays at 3 until a cumulative ≥20-claim sample exists, and the sweep's own scope-narrowing proposal is unimplemented

**Severity:** Low
**Location:** `skills/code-review/SKILL.md:334-337`, `docs/thoughts/code-review-evaluation-state.md:198`
**Move:** Question the cache / asymptotic behaviour (when does the expensive path stop being paid?)
**Classification:** Micro (fixed ×3 until a manual threshold trips) / Cold path (the reduction decision is an out-of-band judgment, not per-run) — Informational by matrix, raised to Low because it governs how long the Medium finding above is paid
**Confidence:** High
**Baseline:** 0 measured k=3 runs to date — `docs/thoughts/code-review-evaluation-state.md:33` ("Not yet measured: the first k=3 run has not executed; the noise floor is still unquantified") and `:198` ("Still zero data points — accumulate ≥20 clustered claims, then apply §1.1's falsifier").

**Evidence:**

> ```
> across runs show ≥90% verdict agreement on a ≥20-claim sample, k can drop to 2 — that
> is §1.1's stated falsifier; record the observed rate either way.
> ```
> (`skills/code-review/SKILL.md:336-337`)

The reduction trigger is cumulative and manual: it needs ≥20 clustered claims across runs and a human to notice and act. Until then every run pays full k=3 on every claim. There is no per-run adaptive path — no pre-flight cheap pass, and no scoping of replication to the claims that could actually be promoted.

Notably, the sweep this branch archives proposed exactly that narrowing and it was not adopted:

> ```
> | Kimi K3 | 956 s | 32,487 (24,306) | 14 | 5 | C | 75% | k≥3 fact-check scoped to promotion-candidate claims (k set by pre-flight disagreement measurement); runner-up doc-order status quo |
> ```
> (`runs/dd-cross-model-2026-07-30/README.md:40`)

Only fact-check verdicts of `Incorrect` at high confidence promote to 🔴 (`skills/code-review/SKILL.md:264-265`; Fact-Check Gate at `:349-351`). Claims that no replicate rates worse than `Verified` consume the full 3× and change nothing downstream. Replicating only promotion-candidate claims would preserve the entire stated benefit at a fraction of the cost — but it also requires a first pass to identify candidates, which is a real design tradeoff, not a free win.

**Recommendation:** Leave k=3 for now — the design is deliberate and the falsifier is honest. But make the reduction *mechanical* rather than aspirational: state where the cumulative agreement tally lives (a running count in `docs/thoughts/code-review-evaluation-state.md` open question #2 is the obvious home) and who checks it, so k actually drops when the data says it can. Record the scoped-replication variant as a deferred follow-up with its own falsifier rather than leaving it only in the archived sweep.

---

#### Three simultaneous byte-identical prompts cannot share a prompt-cache entry

**Severity:** Informational
**Location:** `skills/code-review/SKILL.md:260-262`, `skills/code-review/SKILL.md:303-304`
**Move:** Question the cache (hit rate)
**Classification:** Micro (per-run input-token constant) / Hot path (Stage 1) — Informational because it is not actionable at this layer
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative

**Evidence:**

> ```
> 7. Launch via the Agent tool with `subagent_type: "general-purpose"` — all three replicates
>    in a single message so they run in parallel and cannot see each other's output.
> ```
> (`skills/code-review/SKILL.md:303-304`)

The two requirements interact in a way worth recording. Byte-identical prompts (`:261`) are the ideal prompt-cache case — a cache read costs roughly a tenth of a full-price input token, against a ~1.25× premium on the write. But a cache entry only becomes readable once the first response has begun; concurrent requests with identical prefixes all miss and all pay full price. Because the spec mandates launching all three in a single message, the replicates race: each of the three pays the full input cost of the pasted 380-line `code-fact-check` skill and scope block. Staggering them would let two read the first one's cache — at the cost of serialising Stage 1, which is the wrong trade (see What Looks Good).

I am flagging this as **not actionable here**: the orchestrator dispatches via the Agent tool and does not control sub-agent request caching, and the parallel launch is correct for latency and for the independence the measurement requires. It is recorded so that a future reader does not "optimise" by staggering the launches, and so the input-token cost of the pasted skill text is understood to be paid three times in full.

**Recommendation:** No change. Optionally note in the Stage-1 prose that the parallel launch is deliberate and trades cache-sharing for wall-clock and independence, so the tradeoff is not re-litigated later.

---

#### bats suite re-reads and re-`sed`s a 1178-line file on every test

**Severity:** Informational
**Location:** `test/skills/code-review-factcheck-replication.bats:17-34`
**Move:** Count the hidden multiplications
**Classification:** Micro (constant-factor process spawns) / Cold path (test suite, `@category fast`, no agent or network calls)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative

**Evidence:**

> ```bash
> setup() {
>   REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
>   SKILL="$REPO_ROOT/skills/code-review/SKILL.md"
>   [ -f "$SKILL" ] || skip "code-review SKILL.md not found at $SKILL"
>   SKILL_CONTENT=$(tr -d '\r' < "$SKILL")
> }
> ```
> (`test/skills/code-review-factcheck-replication.bats:17-22`)

> ```bash
> stage1() {
>   echo "$SKILL_CONTENT" | sed -n '/^### Stage 1: Code Fact-Check/,/^### Fact-Check Gate/p'
> }
> ```
> (`test/skills/code-review-factcheck-replication.bats:27-29`)

bats runs `setup()` per test, so the 1178-line file is read and `tr`-filtered 10 times. `stage1()` re-derives the section with a fresh `sed` on every call and is invoked ~13 times across the suite (twice in several tests, plus `stage1_flat` which pipes it through `tr` twice more). Total: ~10 file reads and ~35 process spawns over a 1178-line file.

At this file size that is milliseconds, and memoising across tests is not possible in bats without a `setup_file`-scoped export. This is recorded only to note it was considered and dismissed — it is not worth changing.

**Recommendation:** None. If the suite grows well past 10 tests or the skill file past a few thousand lines, hoist the read into `setup_file()` and export the extracted Stage-1 section once. Not warranted today.

---

## What Looks Good

- **Stage-1 latency is not tripled.** `skills/code-review/SKILL.md:303-304` mandates all three replicates in a single message, so Stage-1 wall-clock is `max(r1,r2,r3)`, not their sum. This is the single most important performance decision in the change and it is correct — and it is enforced by prose that a test asserts (`test/skills/code-review-factcheck-replication.bats:36-41`).
- **The scope-not-diffs invariant survives.** `skills/code-review/SKILL.md:100` and `:1144` are unchanged; the diff is still not pasted into agent prompts, so the 3× fan-out multiplies per-agent read work but not orchestrator prompt size at Stage 1.
- **Graceful degradation instead of a hard block.** The k=2 fallback (`:306-310`) means one failed replicate costs a footnote, not a re-run of the whole stage — the cheap failure path, correctly chosen.
- **The expensive path has a documented exit.** `:334-337` states a concrete, measurable condition (≥90% agreement on ≥20 claims → k=2) under which the cost halves. Most "add replication" changes ship without one.
- **Everything downstream consumes the merged report** (`:342-343`), so the 3× stops at Stage 1 rather than propagating into Stage 2 critic prompts — the fan-out is contained to one stage by design.
- **Tests are grep-only and `@category fast`** — no agent invocation, no network, no `claude -p`. Adding 10 tests costs the suite essentially nothing.

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Orchestrator holds 4 fact-check reports for the whole run; merge input uncapped | High | `skills/code-review/SKILL.md:311-344`, `:936-940` | High |
| 2 | Stage-1 agent spend and per-agent read work triple on every run | Medium | `skills/code-review/SKILL.md:214`, `:258-262` | High |
| 3 | Confirmed-Good cross-check scan grows N×1 → N×4 report passes | Medium | `skills/code-review/SKILL.md:936-940` | Medium |
| 4 | No adaptive path; k=3 paid until a manual cumulative threshold trips | Low | `skills/code-review/SKILL.md:334-337` | High |
| 5 | Simultaneous byte-identical prompts cannot share a prompt cache | Informational | `skills/code-review/SKILL.md:260-262`, `:303-304` | Medium |
| 6 | bats suite re-reads/re-`sed`s a 1178-line file per test | Informational | `test/skills/code-review-factcheck-replication.bats:17-34` | High |

**Legibility-target** for every finding above: `for-author` (each names a specific edit to `skills/code-review/SKILL.md` prose). Findings 1 and 3 are additionally `for-orchestrator-synthesis` — they concern the orchestrator's own context budget and interact with decision 021, so the synthesis step should carry them forward rather than treating them as isolated edits. No finding is `for-automated-gate`: none is mechanically checkable by the existing bats contract suite, and none should block on a lint.

---

## Overall Assessment

The performance posture is **acceptable and deliberate at Stage 1, under-considered at Stage 3 and in the orchestrator's context budget.** The headline 3× on fact-check agents is a decision-recorded tradeoff with a documented exit condition, and the crucial call — parallel launch, so latency does not triple — is correct. That part needs no rework.

The finding worth acting on before merge is #1: the change quietly makes the orchestrator carry four fact-check reports from Stage 1 through Stage 3, with no release point, in a file whose own stated invariant (`:100`, `:1144`) is to keep bulk artifacts out of the orchestrator's window, and in a repo whose most recent decision (021) is specifically about reviewer context management. Findings #1 and #3 share a fix: build the cross-replicate observation index once during the merge, carry it in the merged report, and let Stage 3 read only that. This is an in-place prose edit, not a structural rework — roughly a paragraph in the merge step and a rewrite of cross-check item 4.

Nothing here needs a profiler, but the whole review rests on structure rather than measurement: no k=3 run has executed, and the state doc says so plainly. The highest-value next step is not another prose change — it is running the pipeline once at k=3 and recording orchestrator token usage, Stage-1 wall-clock, and agent count, so findings #1 and #2 can be argued from numbers instead of from reading.

---

## Goal-Alignment Note

- **Answered:** yes — performance review of the branch diff, delivered as a structured report
- **Out of scope:** correctness of the merge semantics, whether most-severe-wins is the right aggregator, the fact-check findings themselves (supplied and not re-verified), and `runs/` artifacts other than `README.md`
- **Escalate:** nothing blocking — but finding #1 interacts directly with decision 021's Stage-1 context scope and is worth a look from whoever owns that decision before merge
