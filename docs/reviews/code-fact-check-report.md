# Code Fact-Check Report (merged, k=3 most-severe-wins)

**Commit:** 62594fb
**Replication:** k=3
**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** git diff main...HEAD (branch exp/cross-model-openrouter-sweep)
**Checked:** 2026-07-31
**Total claims checked:** 28 clusters (r1: 30 claims · r2: 28 · r3: 21; clustered by file, ±5-line range, claim substance)
**Summary:** 15 verified, 10 mostly accurate, 2 stale, 1 incorrect, 1 unverifiable (sub-claim)

Merged per `skills/code-review/SKILL.md` Stage 1 (most-severe-wins; severity order
Incorrect-high > Incorrect-med > Incorrect-low > Stale > Mostly Accurate > Unverifiable >
Verified). Per-replicate reports: `code-fact-check-report-r{1,2,3}.md`, all `Commit: 62594fb`.
Replicates ran on identical prompts (rich shared brief, step 3b) differing only in output
path. The prior merged report (Commit e9d05ea, 2026-07-30) is preserved in git history at
this path. Hallucination pattern log read by all three; no entries matched, none appended.

## Merged clusters

| # | Claim (primary location) | r1 | r2 | r3 | Merged (most-severe-wins) |
|---|---|---|---|---|---|
| M1 | oc briefs "4.5–5.1KB … claims lists … *verbatim in both oc runs*" (`experiment-md1-r1-replication…:98-102`; echoed log row 29) | **Incorrect** | **Incorrect** | **Incorrect** | **Incorrect (High)** — unanimous. Measured briefs 4,524/5,067/**3,653** chars; oc-r3 ~20% below stated floor and (r3) has no claims list; the quoted directive is verbatim only in md1-opus-r1. Mechanism claim (rich-vs-lean) survives; sizes and attribution wrong. |
| M2 | State doc open question #2 "Still zero data points" (`state doc:218`) | Stale | Stale | Stale | **Stale (High)** — this branch's own merged report (21/23 ≈ 0.91) and the MD1 cc cells (~47%) are data points; ≥20-claim threshold met. |
| M3 | State doc §1.1 status "the first k=3 run has not executed" | — | — | Stale | **Stale (High)** — the branch's own review executed it. |
| M4 | Step 3b: "a single richly-briefed run had found 3/3 times" (`SKILL.md:288-289`) | Mostly acc. | Mostly acc. | Mostly acc. | **Mostly Accurate (High)** — 3/3 is three separate k=1 runs (one find each), and one of the three was not richly briefed; reword. |
| M5 | Log row 29 echo of M1's "4.5–5.1KB" | Mostly acc. | Mostly acc. | Incorrect (folded into M1) | **Mostly Accurate (High)** — fix range to 3.7–5.1KB and drop the all-runs claims-list attribution. |
| M6 | "byte-identical" replicate prompts (cc cells; fix-r1 "7,834 bytes ×3"; q#1 row echo) | Mostly acc. | Mostly acc. | Mostly acc. | **Mostly Accurate (High)** — identical except the spec-permitted r1/r2/r3 output path (2 chars); 7,834 is chars (7,868 bytes). One wording fix clears 4 sites. |
| M7 | §5.0 "~18k–41k tokens" (`state doc:282`) | Mostly acc. | Mostly acc. | Mostly acc. | **Mostly Accurate (High)** — MD1's Stage-1 prompt is ~2.2k tokens; true of 4/5 cells. |
| M8 | Dagger footnote: MD1/ND2/ND3 "already merged into their mainlines" (`stage1-context-cost…:42-47`) | Mostly acc. | Verified | Verified | **Mostly Accurate (High)** — MD1's range end `d90d6bb` is NOT an ancestor of `integration/6.1`; its sibling section is empty because the range *starts* at a mainline commit. ND2/ND3 genuinely merged. |
| M9 | `--dry-run` "prints per-section token estimates" (`cross-model-review.py:26`) | Mostly acc. | — | Mostly acc. | **Mostly Accurate (High)** — prints per-section char counts + one aggregate token estimate. |
| M10 | build_stage1_context stats "section → char count" (`cross-model-review.py:125`) | Mostly acc. | Mostly acc. | Mostly acc. (folded) | **Mostly Accurate (High)** — `skipped_files` is a file count. |
| M11 | Binary guard: `"\x00" in content[:8192]` lists binaries as skipped (`cross-model-review.py:160`) | Mostly acc. (Med) | Mostly acc. | Mostly acc. (Med) | **Mostly Accurate (Medium)** — guard unreachable for real binaries: `sh()` is `text=True`, `UnicodeDecodeError` uncaught → a committed PNG **crashes the Stage-1 build** (r1: empirically reproduced). Latent bug, no measured cell affected. |
| M12 | "Files larger than --max-inline-kb are listed but not inlined" + default 64 | Verified | Mostly acc. | Mostly acc. (Med) | **Mostly Accurate (High)** — oversize path correct; binaries (when they don't crash, see M11) are listed under the "TOO LARGE" header, mislabelled. |
| M13 | split_range docstring + three-dot caller semantics (`cross-model-review.py:115,139,318`) | Verified | Verified | Mostly acc. (Med) | **Mostly Accurate (Medium)** — for `a...b` ranges the sibling boundary `left` ≠ the reviewed diff's merge-base baseline; all current usage is two-dot. Caller-semantics nuance, not a docstring falsehood. |
| M14 | Gate 1h comment/parsing vs SKILL merged-report format (`self-improvement.sh:1481-1516`) | Mostly acc. | Verified | Mostly acc. | **Mostly Accurate (High)** — parsing matches the instructed format (k=3/k=2 vocabulary, Commit prefix test), but the prior merged report lacked `**Replication:**` (gate would flag a genuine k=3 run as single-sample), and the SKILL mandates `Commit:` explicitly only on per-replicate reports. *This report adds the field; the SKILL-side mandate is a fix-loop item.* |
| M15 | Phantom "§1.0" anchor in 4 files (state doc:53, SKILL.md:264, factcheck bats:7, log row 27) | Mostly acc. | Verified | — | **Mostly Accurate (High)** — no `§1.0` exists; content lives in "The one-paragraph state of things". Coordinated 4-file fix or add the anchor. |
| M16 | dd-sweep "This is the runner that produced runs/…" (`dd-cross-model-sweep.py:4`) | Verified (Med) | **Unverifiable** (Med) | Verified | **Unverifiable (Medium)** — meta.json key sets match the script's output dict exactly, but the script was committed post-hoc (C20: reconstructed); original file/history unavailable. |
| M17 | 021 header: built-untested, $0.248 / $4.37, guardrails hold | Verified | Verified | Verified | Verified (High) |
| M18 | Log row 27: J_self 0.14–0.25; all four families ranked first; merge machinery | Verified | Verified | Verified | Verified (High) |
| M19 | 0/9 cc vs 3/3 oc exportGraph; Fisher p≈0.0045 (recomputed 1/220 by all three) | Verified | Verified | Verified | Verified (High) |
| M20 | Replication per-cell table (rc/elapsed/outcomes, all 7 cells) vs run artifacts | Verified | Verified | Verified | Verified (High) |
| M21 | fix-r1 validation: 3/3 replicates reached exportGraph; 🔴 R1 with toBlob; token table | Verified | Verified | Verified | Verified (High) |
| M22 | Cost-doc measured table: all 10 dry-runs re-executed and reproduce (±1–2 tok on merged-range cells); 0 files skipped | Verified | Verified | Verified | Verified (High) |
| M23 | Cost projections: $1.95→$4.37 (2.2×), worst call $0.248; prices corroborated by sweep meta.json | Verified | Verified (Med) | Verified (Med) | Verified (High) |
| M24 | README corrected M16/M17 values stand (6.2×/8.5×; runner-up "[2] measurement-first"; $1.21) | Verified | Verified | Verified | Verified (High) |
| M25 | Diff-only prompt byte-identical to pre-021 (`git show main:` template comparison + reproduced token counts) | Verified | Verified | Verified | Verified (High) |
| M26 | Kimi content:null / max_tokens 48000 cross-reference | Verified | — | Verified | Verified (High) |
| M27 | q#1 closure row (5 cells, oc 3/3, cc 1/3, channels/tiers, hint-advantaged caveat) | Verified | Verified | Verified | Verified (High) |
| M28 | bats headers (Results 14a/15, row 27/28 attributions, negative controls); soundness validation figures; log row 28 Path A/falsifier | Verified | Verified | Verified | Verified (High) |

## Verdict stability

- **Clusters with ≥2 replicate verdicts:** 26 (M3 single-replicate; M16's "runner" sub-claim reached by all three but verdicted differently).
- **Agreement rate:** 20/26 ≈ **0.77** (cluster level, second measured sample; first was 21/23 ≈ 0.91).
- **Disagreements (6):** M8, M12, M13, M14, M15, M16 — all on the Verified ↔ Mostly-Accurate/Unverifiable boundary; **no Incorrect ↔ Verified flip in this run** (contrast the first sample's two). The Incorrect cluster (M1) is unanimous 3/3.
- Most-severe-wins resolved every disagreement per the ladder; all three replicates were substantive (30/28/21 claims), so the ≥2-substantive minimum is met.

## Claims Requiring Attention

### Incorrect
- **M1** (`docs/working/experiment-md1-r1-replication-2026-07-30.md:98-102`): oc brief sizes are 4,524/5,067/3,653 chars (not "4.5–5.1KB"); claims list present in 2/3 oc briefs only; the quoted directive is verbatim only in md1-opus-r1. Fix sizes, soften the mechanism claim (oc-r3 recovered R1 with a lean brief), fix "verbatim in both oc runs".

### Stale
- **M2** (`docs/thoughts/code-review-evaluation-state.md:218`): "Still zero data points" — two samples now exist (0.91 branch review; ~47% MD1 cc cells), pointing in opposite directions; update the row.
- **M3** (state doc §1.1 status): "first k=3 run has not executed" — it has.

### Mostly Accurate
- **M4** (`skills/code-review/SKILL.md:288-289`): reword "a single richly-briefed run had found 3/3 times" → three separate k=1 runs, one not richly briefed.
- **M5** (log row 29): range 3.7–5.1KB; attribution fix as M1.
- **M6** (4 sites): "byte-identical" → "identical except the permitted replicate output path"; 7,834 chars not bytes.
- **M7** (state doc §5.0): "~2k–41k tokens (~18k–41k on the non-trivial cells)".
- **M8** (cost doc footnote): MD1 empty-sibling cause is range-starts-at-mainline, not merged.
- **M9/M10** (`cross-model-review.py:26,125`): docstring says token estimates / char counts where it means char counts / a file count.
- **M11** (`cross-model-review.py:111,153-162`): catch `UnicodeDecodeError` (or read bytes) so committed binaries are listed as skipped instead of crashing the build.
- **M12** (`cross-model-review.py:163-169`): label the skip section to cover binary files, or split the reasons.
- **M13** (`cross-model-review.py:114-119`): document the three-dot caller semantics or normalize `left` to the merge-base.
- **M14** (`skills/code-review/SKILL.md` merge step / `self-improvement.sh:1481`): mandate `**Replication:**` and `Commit:` on the *merged* report explicitly (this report complies; make the contract say so).
- **M15** (4 files): fix or anchor the phantom "§1.0" citation.

### Unverifiable
- **M16** (`scripts/dd-cross-model-sweep.py:4`): "runner that produced" — post-hoc reconstruction; would need the original job-tmp script or session history to verify identity (behavioral equivalence to the meta.json outputs is confirmed).

## Goal-Alignment Note
- Answered: yes — all ten briefed claim groups covered by all three replicates; every quantitative anchor re-executed or recomputed by at least two replicates independently.
- Out of scope: claims inside immutable `runs/` artifacts and pre-existing `docs/reviews/` reports; live OpenRouter pricing (internal consistency + meta.json corroboration substituted).
- Escalate: (1) M11 binary crash is a latent Stage-1 harness bug to fix before any live sweep on a repo with binary assets; (2) M14's contract gap (merged-report `**Replication:**` field) needs a SKILL.md line; (3) M1 propagates through log row 29 — fix at source and echoes together.
