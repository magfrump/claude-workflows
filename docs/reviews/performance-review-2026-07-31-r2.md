# Performance Review — exp/cross-model-openrouter-sweep (Stage-1 context adoption)

Commit: fbd8597

**Scope:** `git diff main...HEAD` — 10 files, +207/−7 (`scripts/cross-model-review.py`, `skills/code-review/SKILL.md`, decision/thoughts/working docs, `runs/cross-model/s1-*` raw data)
**Date:** 2026-07-31
**Based on:** docs/reviews/code-fact-check-report.md (k=3 merged)

---

### Data Flow and Hot Paths

The only executable change on this branch is in `scripts/cross-model-review.py`: a docstring rewrite plus a six-line `if not args.context_base:` branch that prints a warning to stderr on live diff-only runs. Everything else in the diff is markdown or JSON/JSONL run artifacts, which are not executed.

`cross-model-review.py` is a manually invoked CLI experiment harness. Its lifecycle per invocation is:

1. **Setup (cold, once)** — parse args, `git diff <range>` for the reviewed diff, and, when `--context-base` is set, `build_stage1_context()` assembles the sibling-branch diff plus the whole post-range contents of every touched file (one `git show` subprocess per file). One prompt string is produced.
2. **Cost guard (cold, once)** — `fetch_pricing()` (one HTTP call), a `len(prompt)/4` token estimate, a fixed 1,500-output-token assumption, and a `--max-usd` gate. The new stderr warning sits here, after the `--dry-run` early return and before the unpriced / over-cap `sys.exit`s.
3. **Sweep (the expensive part)** — a strictly sequential nested loop `for model in args.models: for r in range(1, replicates+1)`, one OpenRouter HTTP call per iteration, results flushed to `findings.jsonl` per call.
4. **Analysis (cold)** — re-read the JSONL, pairwise Jaccard, some of which invokes a judge model.

The dominant cost is step 3, and it is dominated entirely by remote model latency and per-token billing, not by local computation. Measured (fact-check, verified): 16 calls across D3+D4 cost $3.53 total, median $0.226/call, worst $0.388; latency bands Sol 48–76 s, Gemini 110–143 s, Sonnet 93–263 s, Kimi 287–636 s. Local work in steps 1, 2 and 4 is microseconds-to-milliseconds against per-call latencies measured in minutes.

Call frequency for the whole program: "a few times a day at most" (orchestrator brief). There is no hot path in this diff in the request-handler / per-item-loop sense. The genuinely performance-shaped question the branch raises is not about code speed at all — it is that the branch **changes the recommended operating mode** from diff-only to `--context-base`, which multiplies billed input tokens on every call in every sweep. That is where the findings concentrate.

---

### Findings

#### F1 — Stage-1 context has a per-file inline cap but no aggregate size budget; the only backstop is a hard `--max-usd` abort

**Severity:** Medium
**Location:** `scripts/cross-model-review.py:196-231`, guard at `scripts/cross-model-review.py:431-432`
**Move:** #2 (what's the size of N?), #9 (asymptotic behavior and cliff vs graceful degradation)
**Classification:** Macro (prompt size scales with the changeset, unbounded in aggregate) / Cold path (one-time prompt assembly in a manually invoked CLI)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** Measured — Stage-1 prompts on the validated cells were ~20k tokens (D3) and ~12k tokens (D4) vs ~4.4k tokens diff-only; per-file cap is `--max-inline-kb` default 64 (fact-check verified prompt sizes).
**Evidence:**
> ```
>     touched = [p for p in sh(
>         gitq + ["diff", "--name-only", rev_range]).splitlines() if p.strip()]
>     inlined, skipped = 0, []
>     for path in touched:
> ```
> ```
>         if len(content) > max_inline_kb * 1024:
>             skipped.append((path, len(content), "over --max-inline-kb"))
>             continue
> ```
> ```
>         if projected > args.max_usd:
>             sys.exit(f"projected ${projected:.2f} > --max-usd {args.max_usd}; raise the cap to proceed")
> ```

`--max-inline-kb` bounds each individual file at 64 KB but nothing bounds the sum. Prompt size grows linearly in the number of touched files, so a changeset touching 50 moderate files can assemble a multi-megabyte prompt (50 × 64 KB ≈ 3.2 MB ≈ 800k estimated tokens at the harness's 4-chars/token heuristic) with no per-section warning. This branch makes that the *recommended* mode, so the exposure is now the default rather than opt-in. The failure mode is a cliff, not degradation: `--max-usd` aborts the run outright with a message that names only dollars, giving no signal that context assembly was the cause or which files dominated. The validated D3/D4 cells were small, so the measured $3.53 says nothing about the large-diff case.

**Recommendation:** Add an aggregate context byte budget (a `--max-context-kb`, defaulting to something like 512 KB) enforced in `build_stage1_context`, dropping the largest files into the existing `FILES NOT INLINED` section when the budget is exhausted — the omission-is-explicit mechanism already exists and would degrade gracefully instead of hitting the cost cliff. Separately, include `ctx_stats` in the `--max-usd` exit message so an over-cap abort names context size as the driver.

---

#### F2 — The cost guard is now more load-bearing, but its fixed 1,500-output-token term under-projects reasoning models by ~56% at the worst observed call

**Severity:** Low
**Location:** `scripts/cross-model-review.py:390-396`
**Move:** #1 (count the hidden multiplications — the estimate error is paid once per model per replicate)
**Classification:** Micro (a single constant in an estimator) / Cold path (one-time projection before the sweep)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** Measured — worst actual call $0.388 (Kimi D3 r1, 636 s, reasoning-heavy) against the offline worst-call projection of $0.248, a 56% overshoot; median actual $0.226 against the 021 median trigger of ~$0.33; sweep total $3.53 against the $10 trigger. Neither 021 trigger fired (fact-check verified).
**Evidence:**
> ```
>         # cost guard: ~4 chars/token heuristic on input, assume 1.5k output tokens/run
>         pricing = fetch_pricing(key) if key else {}
>         est_in_tok = len(prompt) / 4
>         projected = 0.0
>         for m in args.models:
>             pin, pout = pricing.get(m, (0, 0))
>             projected += args.replicates * (est_in_tok * pin + 1500 * pout)
> ```

The estimator's under-projection for reasoning models is already documented and fact-check-verified, so this is not a new defect. What this branch changes is its weight: promoting `--context-base` to the recommended mode raises input tokens 2.7–4.5× (12k–20k vs 4.4k), which makes `--max-usd` the primary control on spend for a mode that is now the default recommendation. The error is multiplied by `len(models) × replicates` — 8 calls in the validated sweep — and it is one-sided (always under). At current sweep sizes the margin absorbs it comfortably ($3.53 realized vs a $10 trigger); at a large-diff sweep near the cap it would not.

**Recommendation:** Leave the estimator alone for now — the measured margin is wide and the behavior is documented. If a sweep ever lands within ~40% of `--max-usd`, replace the flat 1,500 with a per-model output assumption (reasoning families budgeted higher), or print realized-vs-projected spend at the end of the sweep so the drift is observable rather than inferred from receipts.

---

#### F3 — The sweep loop is strictly sequential, so wall time is the sum of per-call latencies, and Stage-1-by-default lengthens each call

**Severity:** Informational
**Location:** `scripts/cross-model-review.py:434-441`
**Move:** #7 (contention / one slow consumer blocking the batch), #3 (work in the right place)
**Classification:** Macro (execution structure of the batch) / Cold path (manual research sweep, a few runs per day; not latency-sensitive)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** Measured — latency bands Sol 48–76 s, Gemini 110–143 s, Sonnet 93–263 s, Kimi 287–636 s (fact-check verified). A worst-case 4-family × 2-replicate sweep at the upper bands sums to roughly 2,236 s ≈ 37 minutes; parallelized it would be bounded by the slowest single call, ≈ 636 s ≈ 11 minutes.
**Evidence:**
> ```
>         with open(findings_path, "w") as fh:
>             for model in args.models:
>                 for r in range(1, args.replicates + 1):
>                     t0 = time.time()
> ```

One slow family (Kimi, up to 636 s/call) blocks every subsequent call in the sweep. Enriched prompts add input tokens to every call, which nudges per-call latency up and therefore the sum. Per the hot-path gate this stays Informational: this is a manually invoked measurement harness, nothing waits on it, and serialization buys real properties the branch depends on — deterministic stdout ordering, incremental `fh.flush()` per call so a crashed sweep keeps its partial corpus, and no concurrent pressure on OpenRouter rate limits. The severity table would put Macro × Cold at Medium; I am deliberately calling it lower because the path is a background research script and the serialization looks intentional rather than accidental.

**Recommendation:** No change needed at current sweep sizes. If sweeps grow past ~4 families × 3 replicates and turnaround starts to matter, a bounded `ThreadPoolExecutor` (workers ≈ number of models) with a lock around the JSONL append would cut wall time to roughly the slowest single call, at the cost of interleaved progress output.

---

#### F4 — Context assembly spawns one `git show` subprocess per touched file, sequentially

**Severity:** Informational
**Location:** `scripts/cross-model-review.py:199-215`
**Move:** #1 (hidden multiplications — process spawns per item)
**Classification:** Micro (subprocess overhead, milliseconds each) / Cold path (once per invocation, before any network call)
**Confidence:** High
**Legibility-target:** for-author
**Baseline:** `no baseline available — flagged as speculative` (no measurement of context-assembly time exists; the fact-check numbers cover API latency and spend only). For scale reference, the measured per-call API latencies are 48–636 s, against which typical `git show` fork+exec cost is on the order of milliseconds.
**Evidence:**
> ```
>     for path in touched:
>         try:
>             content = sh(gitq + ["show", f"{right}:{path}"])
>         except subprocess.CalledProcessError:
> ```

N here is the number of files in the reviewed diff. Each iteration is a fork+exec, and binary/undecodable files cost a second spawn for `git cat-file -s`. This is a real per-item multiplication, but it runs exactly once per invocation and is amortized across every model × replicate call in the sweep — the correct placement per move #3. Even at a 200-file diff the assembly cost would be a rounding error against a single 636-second model call, and F1's aggregate-size problem would bind long before subprocess overhead did.

**Recommendation:** No action. If `build_stage1_context` ever needs to be faster, `git cat-file --batch` fed from the `--name-only` list replaces the whole loop with one subprocess — but do that only if profiling shows assembly time is material, which is unlikely at any realistic diff size.

---

### What Looks Good

- **The new warning itself is performance-neutral.** One boolean check and one `print(..., file=sys.stderr)` per invocation — O(1), on a cold path, executed at most a handful of times a day. It sits after the `--dry-run` early return, so no-spend dry runs pay nothing for it.
  > ```
  >         if not args.context_base:
  >             print("WARNING: diff-only mode is a recall probe with a known misattribution "
  > ```
- **Prompt assembly happens once and is reused across every model and replicate** (`prompt` built at lines 379-388, sent unchanged in the loop at 441). This is move #3 in the good direction: the expensive git work sits in setup, not per call, and the byte-identical-prompt requirement enforces it structurally.
- **`fh.flush()` after every record** trades a negligible amount of I/O for crash-resilience on a run whose wall time is measured in tens of minutes. Correct tradeoff for this workload.
- **The cost guard fails closed on unpriced models** rather than projecting $0.00, which is the right default for a mode whose token footprint just grew 2.7–4.5×.
- **Diff-only remains byte-identical to the pre-021 prompt**, so the cheaper mode stays available as an escape hatch and historical cost/latency baselines remain comparable. The branch changes the recommendation without removing the low-cost path.

---

### Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Stage-1 context has no aggregate size budget; `--max-usd` abort is a cliff, not degradation | Medium | `scripts/cross-model-review.py:196-231`, `:431-432` | High |
| F2 | Cost guard's flat 1,500-output-token term under-projects reasoning models by ~56%; now more load-bearing | Low | `scripts/cross-model-review.py:390-396` | High |
| F3 | Sequential sweep loop: wall time is the sum of per-call latencies (~37 min worst case vs ~11 min parallel) | Informational | `scripts/cross-model-review.py:434-441` | High |
| F4 | One `git show` subprocess per touched file during context assembly | Informational | `scripts/cross-model-review.py:199-215` | High |

---

### Overall Assessment

The executable surface of this branch is one stderr warning and a docstring; both are performance-neutral, and there is no hot path anywhere in the diff. The performance question worth asking is the second-order one: by promoting `--context-base` from opt-in to recommended, the branch makes a 2.7–4.5× input-token multiplier the default posture for every future sweep. The validated measurements show that is comfortably affordable at the sizes tested ($3.53 realized against a $10 trigger, median $0.226 against a ~$0.33 trigger), so nothing here blocks the merge. The one item worth fixing in place is F1 — the missing aggregate context budget means a large changeset scales prompt size linearly with touched files and hits a hard `--max-usd` abort with a message that does not name context as the cause. That is a small, local change to `build_stage1_context` plus one string, not a structural rework. F2 is a known documented estimator bias that only becomes actionable if a sweep approaches its cap; F3 and F4 are noted for completeness and need no action at current scale. No profiling is required: local computation is negligible against per-call model latencies measured in minutes, and the cost/latency numbers that do matter are already measured and recorded in the run artifacts this branch adds.

---

## Goal-Alignment Note
- Answered: yes — performance review of the branch diff, delivered as the requested report
- Out of scope: the warning's placement relative to the `unpriced` / `--max-usd` `sys.exit`s (it fires on runs that then abort) is a correctness/UX ordering question, not a performance one — flagging for whichever critic owns it; also the docstring's own third-party-data-exfiltration warning at `scripts/cross-model-review.py:35-38`, which is security's territory
- Escalate: nothing
