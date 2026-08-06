# DD — Lightweight code review path (cheap enough for looping & benchmarking)

- **Goal**: Choose a lightweight code-review path usable (a) inside iteration loops
  (review-fix, SI loop) and (b) as benchmark arms in the SWR-Bench fork, replacing the
  deep agentic `code-review` orchestrator wherever its ~$14.6/instance mean cost is
  prohibitive.
- **Project state**: Follows 021 (reviewer context management, Stage 1 built+validated)
  and 029 (benchmark architecture, v2 judge spine) · feeds the SWRBench fork arms and the
  local review-fix loop · not blocked.
- **Task status**: complete (decision archived as 030)

## Step 1.0 — Pre-generation grep

Grep of `docs/decisions/*.md` "Pruned candidates" for `review|benchmark|cheap|lightweight|cost`
surfaced directly relevant prior pruning:

- **021 [6] on-demand file read** — pruned: per-provider tool plumbing (H2), model/retrieval
  confound (H3). → **Carry forward** — unchanged reasons apply here verbatim.
- **021 [7] full agentic as sweep config** — pruned: fails portability/confound/cost; is the
  production endpoint. → **Carry forward** — it is precisely the thing this DD routes around.
- **021 [8] ideal-if-free: agentic + multi-sample union** — pruned on cost/latency. →
  **Carry forward** (kept as this DD's ideal-if-free slot, not re-proposed as viable).
- **029 [8] executable downstream eval** — pruned: multiplies the $14.6/instance mean. →
  **Carry forward**.
- **029 [11] expert panel** — pruned: cost ceiling. → **Carry forward**.
- **029 [6] paired-preference ranking** — absorbed into 029-A as a *screening layer*. →
  **Carry forward as complement**: it is a cheap comparator for lightweight-path outputs,
  not itself a review path.

## Step 1 — Diverge (14 candidates)

Candidate 0 is the prior-decision status quo per the workflow's candidate-0 rule.

0. **021 Stage-1 harness, promoted** — adopt `scripts/cross-model-review.py` with
   `--context-base` (labelled branch diff + whole enclosing files, single chat-completions
   call, no tools) as *the* lightweight path, promoted from experiment harness to named
   review path.
1. **Do nothing** — keep the deep agentic path; just invoke it less often in loops.
2. **Single-shot single-model prompt** — one Claude call over diff+context, no
   orchestration, no sweep (candidate 0 minus the multi-model machinery).
3. **Small-model arm** — same single-shot shape but pinned to Haiku 4.5 (or Sol-class
   OpenRouter model) as the cost floor.
4. **Static-analysis pre-filter** — linters/semgrep/tests first; LLM sees only flagged
   hunks (or nothing, if clean).
5. **Cascade / tiered escalation** — cheap single-shot always; escalate to the deep
   agentic path only when the cheap pass emits ≥1 High-severity or low-confidence finding.
6. **Trimmed orchestrator** — run the `code-review` skill but with a critic subset
   (fact-check + one critic) at low effort.
7. **k-sample consensus** — k=3 samples of the cheap single-shot; keep only findings that
   ≥2 samples agree on (precision filter without agentic verify). The harness already
   supports k=3.
8. **Rubric/checklist single call** — fixed checklist scored per item with structured JSON
   output, rather than open-ended finding generation; maximally deterministic and
   judge-parseable.
9. **Delta review** — in loops, review only hunks changed since the previous iteration's
   review; carry prior findings forward.
10. **Ideal-if-free** — full agentic multi-sample union with adversarial verification
    [carried from 021 [8]: cost/latency].
11. **No-LLM gate** — lint + test results + diff stats only; naive, zero marginal LLM cost.
12. **Paired-preference screener** — don't emit findings at all; cheaply compare two
    candidate reviews/patches [carried from 029 [6]: complement, not a review path].
13. **Prompt-cache loop layout** — restructure loop prompts so the base context is cached
    across iterations and only the delta is uncached (cost lever, orthogonal to path shape).
14. **On-demand constrained file read** [carried from 021 [6] — listed for completeness,
    not re-proposed].

### Generation health check

- **Clustering**: 0/2/3/7/8 all assume "one cheap completion call" — named; 4, 11, 12, 13
  violate that assumption (non-LLM, comparator, and caching levers), so the space is not
  single-region. OK.
- **Missing perspectives**: do-nothing = 1; naive = 11; newcomer suggestion = 4
  (run a linter first); ideal-if-free = 10. Present.
- **Vagueness**: each candidate names a concrete mechanism. OK.
- **Dimensional anchoring**: dimensions covered — context shape (0), model choice (3),
  sampling (7), output contract (8), dispatch/escalation (5, 6), scope (9), non-LLM (4, 11),
  cost plumbing (13). ≥3 dimensions. OK.

## Step 2 — Diagnose (7 constraints: 4 hard · 3 soft)

- **H1 (hard) — loop/benchmark-affordable.**
  success: median per-review cost ≤ $0.35 (021's pinned band) and a 30-instance benchmark
  sweep ≤ $15 total — i.e. ~40× under the agentic path's $14.6/instance mean.
- **H2 (hard) — benchmark-pluggable and confound-controlled.**
  success: runs headless via plain chat-completions with a byte-identical prompt per
  instance (no tools, no retrieval variance), so it slots into the SWRBench-fork adapter
  as an arm and model identity stays attributable (same bar as 021 H2/H3).
- **H3 (hard) — does not reproduce the sibling-commit FP class.**
  success: D3/D4 FP-kill re-run stays 0/8 for Results 3c and 5 (already holds for the
  Stage-1 context base; any candidate that abandons that context must re-pass it).
- **H4 (hard) — judge-parseable output.**
  success: findings emitted in the v2 judge's expected structured shape (file, line,
  severity, claim) with zero manual munging on a 10-instance dry run.
- **S1 (soft) — near-zero new build effort** (harness and adapter exist; prefer ≤ half a
  day before first numbers).
- **S2 (soft) — dual-use**: same entry point serves the local review-fix loop and the
  benchmark arm (one config, two consumers).
- **S3 (soft) — recall measurably close enough to the deep path to be worth looping on.**
  success (cheap to name): the benchmark's WUS/verified-recall for the lightweight arm is
  reported beside the agentic arm's; no fixed threshold — the instrument decides.

Non-obvious constraints: (a) 021's secret-screening revisit trigger — the harness ships
whole files + branch diff to third-party APIs; fine for operator-owned repos, gate before
pointing elsewhere. (b) Benchmark work lives in the SWRBench fork project, not /workspace;
this decision defines the *path/config*, the fork consumes it. (c) The deep agentic critic
remains the production re-verify authority (021 Stage 3) — the lightweight path must not
be positioned as replacing that gate.

## Step 3 — Match and prune

| # | Candidate | H1 cost | H2 pluggable | H3 FP class | H4 parseable | S1 effort | S2 dual-use |
|---|-----------|---------|--------------|-------------|--------------|-----------|-------------|
| 0 | Stage-1 harness promoted | ✓ | ✓ | ✓ (validated) | ~ (needs schema pass) | ✓ | ✓ |
| 1 | do nothing | ✗ | ✗ | ✓ | ✗ | ✓ | ✗ |
| 2 | single-shot single-model | ✓ | ✓ | ✓ (if it keeps Stage-1 context) | ~ | ✓ | ✓ |
| 3 | small-model arm | ✓ | ✓ | ~ (model-dependent) | ~ | ✓ | ✓ |
| 4 | static-analysis pre-filter | ✓ | ~ (tool outputs vary per repo/lang) | ✓ | ~ | ~ (per-language setup) | ~ |
| 5 | cascade escalation | ~ (worst case = agentic cost) | ✗ (escalation is agentic, non-portable) | ✓ | ~ | ~ | ✓ |
| 6 | trimmed orchestrator | ✗ (still multi-agent, ~$2–5) | ✗ (Claude-Code-bound, non-deterministic) | ✓ | ✗ (freeform) | ✓ | ~ |
| 7 | k-sample consensus | ✓ (3× ~$0.23 ≈ $0.7… ~ on strict band) | ✓ | ✓ | ~ | ✓ (k exists) | ✓ |
| 8 | rubric single call | ✓ | ✓ | ✓ (inherits context base) | ✓ (schema-native) | ~ (checklist design) | ✓ |
| 9 | delta review | ✓ | ✗ (stateful; not per-instance reproducible) | ~ (delta reintroduces boundary flattening) | ~ | ~ | ~ (loop-only) |
| 10 | ideal-if-free | ✗ | ✗ | ✓ | ✗ | ✗ | ✗ |
| 11 | no-LLM gate | ✓ | ~ | ✓ | ✗ (no findings to judge) | ✓ | ~ |
| 12 | paired-preference | ✓ | ✓ | n/a | ✗ (no absolute findings) | ✓ | ✗ |
| 13 | prompt-cache layout | ✓ | ~ (cache is provider-specific) | ✓ | n/a | ~ | ~ (loop-only lever) |
| 14 | on-demand read | ✓ | ✗ | ~ | ~ | ✗ | ~ |

**Pruned**: 1, 6, 10, 12, 14 (hard-constraint ✗s); 5 pruned *as the primary path* (its
escalation leg fails H2 for benchmarking) but its trigger logic is trivially recoverable
later as a loop-only policy on top of the winner; 9 and 13 reclassified as **loop-only
optimizations** layered on any winner, not standalone paths; 11 folded into 4; 4 deferred
(per-language setup cost vs. this repo being mostly bash/markdown — revive in a
code-heavy consumer repo).

**Fix sketches for survivors**: 0/2 — add a JSON findings schema to the prompt + a
parse-validate step (~1–2 h) to turn H4 `~` into `✓`. 3 — must re-pass the D3/D4 FP-kill
check per model before trusting H3. 7 — H1 strictly read is 3× median ≈ $0.70/review;
acceptable for benchmark arms, use k=1 in tight loops.

**Survivors → step 4**: [0] (with [2] folded in as its single-model default), [3], [7], [8].

## Step 4 — Tradeoff matrix

| # | Approach | Effort | Risk | Coverage (hard) | Key downside |
|---|----------|--------|------|-----------------|--------------|
| 0 | Stage-1 promoted + JSON schema | ~2 h | low | 4/4 (after schema pass) | recall ceiling: no cross-file interaction bugs (MD1 R1 class) |
| 8 | rubric single call | ~4 h | med | 4/4 | checklist blinds it to off-checklist bug classes |
| 7 | k=3 consensus | ~1 h | low | 4/4 (H1 at 3× median) | 3× cost; consensus can amplify shared-context FPs (Result 5 lesson) |
| 3 | small-model arm | ~1 h | med | 3/4 (H3 unvalidated per model) | weakest recall; per-model FP re-validation duty |

**Falsifiable hypotheses**

- **[0]** If chosen, the promoted harness produces judge-parseable findings on a
  10-instance SWRBench dry run at median ≤ $0.35/call within 1 week; counter-evidence =
  schema parse failures >10% of calls or median cost above the band.
- **[8]** If added as an arm, rubric output beats [0] on precision (lower FP per the v2
  judge taxonomy) on the same 10 instances within 2 weeks; counter-evidence = precision
  no better while missing ≥2 verified bugs [0] caught.
- **[7]** If added as an arm, k=3 consensus cuts FP-class findings ≥30% vs k=1 on the same
  instances; counter-evidence = FP reduction <15% or consensus-amplified FPs reappear.
- **[3]** If added as an arm, Haiku-class models retain ≥60% of [0]'s verified-bug recall
  at ≤⅓ the cost; counter-evidence = recall <40% or a new FP class the D3/D4 check catches.

**Stress-test pass** (moves: boring alternative, invert the thesis, revealed preferences,
failure-driven)

- *Boring alternative* → [0] **is** the boring alternative; the move instead demoted [8]
  from co-equal spine to benchmark arm: its checklist-design effort isn't justified before
  the instrument shows [0]'s open-ended precision is actually a problem.
- *Invert the thesis* ("keep looping on the deep path — cheap review isn't worth its
  recall loss") → survives only if lightweight recall is near-zero; that is exactly what
  029's benchmark measures, and 021 Result 4 already showed cheap families catching High
  bugs the incumbent missed 0/6. Assumption defended; but it hardened the requirement
  that the deep agentic critic stays the production re-verify gate (021 Stage 3) — the
  lightweight path feeds it, never replaces it.
- *Revealed preferences* → the 2026-07-31 validation runs already used [0]'s config for
  real measurements ($3.53/sweep, 0/8 FP reproduction); the project has been using this
  path when it needs cheap signal. Matrix unchanged, confidence up.
- *Failure-driven* → new failure category for [0] as a *loop* reviewer: looping the same
  prompt invites finding-churn (same finding re-worded each iteration, or oscillating
  advice). Mitigation queued as a loop policy, not a build-blocker: pass the prior
  iteration's findings in-context labelled "previously reported" (bounded, cacheable —
  composes with pruned #13). Also re-affirmed 021's secret-screening trigger for any
  non-operator-owned repo.

Axis check: [0] vs [7]/[3]/[8] are not within ~1 cell — [0] dominates on effort+risk with
equal coverage; the others are *arms*, not rivals. No tie to adjudicate.

## Decision

**Path A** (one approach dominates, confidence ~90%, non-interactive session):
**[0] promote the 021 Stage-1 harness to be the lightweight review path**, with a small
JSON-schema pass for judge parseability, and queue **[3], [7], [8] as cheap benchmark
arms** to be ranked by the 029 v2 judge — they are exactly the "ideas we can test
cheaply" the ask requested, and the benchmark is the instrument built to rank them.

Archived as `docs/decisions/030-lightweight-review-path.md`.
