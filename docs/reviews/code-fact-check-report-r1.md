# Code Fact-Check Report

**Commit:** 62594fb
**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** git diff main...HEAD (branch exp/cross-model-openrouter-sweep); replicate r1 of 3
**Checked:** 2026-07-31
**Total claims checked:** 30
**Summary:** 17 verified, 11 mostly accurate, 1 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read before checking:
its `## Patterns` section is empty, so no claim below is matched against a prior pattern.
Immutable experiment evidence (`runs/dd-cross-model-2026-07-30/*`, pre-existing reports
under `docs/reviews/`) was used only as evidence for claims *about* it.

Reproduction commands were re-executed for the stage-1 cost doc (all five dry-run cells,
both modes) and the md1 replication doc (status files, report greps, transcript prompt
extraction); arithmetic (Fisher p, cost projections, growth ratios) was re-computed in
python3.

---

## Claim 1: Stage 1 "built 2026-07-31 … diff-only default byte-identical to pre-021 … worst call $0.248, sweep $4.37: both guardrails hold … Not yet validated against any model"

**Location:** `docs/decisions/021-reviewer-context-management.md:10-16`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four sub-claims check out. Byte-identity: see Claim 19. The cost figures reproduce
from the re-run dry-runs plus the implied per-Mtok prices: worst call = Sol on ND2,

```text
40,587 tok × $5/Mtok + 1,500 tok × $30/Mtok = $0.248
```

(recomputed in python3; the per-Mtok prices are corroborated by
`runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json` — completions cost
`0.27441 / 9147 tok` = exactly $30/Mtok). Full-sweep recompute gives $4.37 (stage-1)
vs $1.95 (diff-only). The guardrails match 021's own revisit triggers:

```text
# docs/decisions/021-reviewer-context-management.md:145
if Stage-1 whole-file+branch-diff prompts push per-call cost above the ~$0.33 median band or a sweep above $10.
```

$0.248 < $0.33 and $4.37 < $10, so "both guardrails hold" is correct.

**Evidence:** `docs/decisions/021-reviewer-context-management.md:10-16,145`, `docs/working/stage1-context-cost-2026-07-31.md:51-68`, `runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.meta.json`

---

## Claim 2: Log row 27 — k=3 fact-check design, "J_self on 🔴 rows 0.14–0.25", "all four families in the 2026-07-30 DD sweep independently ranked this action first"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The J_self band matches the cited experiment doc:

```text
# docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:341-342
| opus | 1 (`WARY_MOOD_DURATION`) | 7 | **0.14** |
| fable | 1 (timer docblock) | 4 | **0.25** |
```

The cross-family corroboration matches the sweep README:

```text
# runs/dd-cross-model-2026-07-30/README.md:33-35
All four models independently converged on the **same top action: k≥3
`code-fact-check` replication with most-severe-wins (§1.1)** — unanimous
cross-family agreement on the #1 pick
```

The described merge machinery (cluster by file/±5-line/substance, most-severe-wins,
per-replicate verdicts, `## Verdict stability`) matches `skills/code-review/SKILL.md`
Stage 1's merge steps 1–4 (paraphrased — no quote available because the merge spec spans
~50 lines at `skills/code-review/SKILL.md:304-360` and is quoted piecemeal in Claims 26-27).
Row 27's "(§1.0: …)" parenthetical shares the wrong section anchor covered in Claim 4.

**Evidence:** `docs/decisions/log.md:48`, `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:332-342`, `runs/dd-cross-model-2026-07-30/README.md:33-36`, `skills/code-review/SKILL.md:304-360`

---

## Claim 3: Log row 29 — "original-config orchestrators wrote 4.5–5.1KB briefs … while all three k=3 orchestrators wrote 2.3–3.0KB generic prompts", "0/9 … vs 3/3 … Fisher one-sided p≈0.0045", fix validated with "7.8KB brief byte-identically into all three replicate prompts, fact-check examined exportGraph.ts 3/3"

**Location:** `docs/decisions/log.md:50`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The 0/9-vs-3/3 counts, p≈0.0045 (recomputed: C(3,3)·C(9,0)/C(12,3) = 1/220 ≈ 0.00455),
the cc range 2.3–3.0KB (measured replicate prompts: 2,328 / 2,691 / 3,010 chars), the
7.8KB fix brief (7,834 chars ×3), and the 3/3 exportGraph.ts hits all verify (see Claims
9, 11, 12, 13). The one imprecision is inherited from the replication doc: the
original-config fact-check briefs measure 4,524 (r1), 5,067 (oc-r2), and **3,653 (oc-r3)**
chars — extracted from the cells' transcript `Agent` dispatches (paraphrased — no quote
available because the prompts live inside transcript JSONL under
`/home/node/.claude/projects/-home-node-cr-eval-runs-*/`, extracted programmatically).
"4.5–5.1KB" describes two of the three oc briefs; oc-r3's is ~3.7KB, ~20% below the
stated floor. The qualitative mechanism (rich claims-list briefs vs lean generic ones)
holds for all three: oc-r3's 3.7KB brief still contains an eight-item claims list with a
connect-src entry ("verify no browser-side fetch to a third-party origin exists").

**Evidence:** `docs/decisions/log.md:50`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:96-114,189-205`, transcript JSONL under `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-*-repo/`

---

## Claim 4: "one of the two verdict-driven promotions to 🔴 (§1.0: fact-check Incorrect or api-consistency Breaking)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:52-53` (same citation at `skills/code-review/SKILL.md:263-264`, `test/skills/code-review-factcheck-replication.bats:6-7`, `docs/decisions/log.md:48`)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The *content* is real but the *anchor* is not: the state doc has no §1.0. Its heading
list runs `## The one-paragraph state of things` → `## 1. Definitely needed` → `### 1.1`
(paraphrased — no quote available because the claim covers absence of a heading; grep for
`### 1.0` returns zero hits, while `### 5.0` exists at line 243, showing the doc does use
N.0 numbering when a section exists). The substance lives unnumbered:

```text
# docs/thoughts/code-review-evaluation-state.md:30-31
The single gate that converts a finding into a blocker — a `code-fact-check` verdict of
Incorrect, or an api-consistency Breaking — is both unstable run-to-run and structurally
```

and the SKILL's own severity mapping confirms both channels land 🔴
(`skills/code-review/SKILL.md:1035`: `| 🔴 Must Fix | Critical, High | Critical |
Breaking | Structural | Incorrect (high confidence) |`). A reader grepping "§1.0" or
"1.0" in the state doc finds nothing; either add a `### 1.0` anchor or cite "the
one-paragraph state of things". Four files on this branch repeat the phantom anchor.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:26-39,52-53`, `skills/code-review/SKILL.md:263-264,1035`, `test/skills/code-review-factcheck-replication.bats:6-7`, `docs/decisions/log.md:48`

---

## Claim 5: Open question #1 closure row — "5 fresh opus cells", oc 3/3 vs cc 1/3, "0/9 cc fact-check replicates reached exportGraph.ts vs 3/3 oc runs (p≈0.0045)", fix "validated n=1 … brief written (7.8KB ×3, byte-identical …), fact-check reached exportGraph.ts 3/3 replicates … R1 recovered at 🔴"

**Location:** `docs/thoughts/code-review-evaluation-state.md:217`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Consistent with the replication doc and with the run artifacts directly (Claims 8, 9, 12,
13). The one recovery's channel matches the cell's own stdout:

```text
# /home/node/cr-eval/runs/md1-opus-cc-r4/stdout.txt:38
The highest-value *single* finding, though, is one only architecture-review surfaced, and it survived a cross-check rather than a critic: **A1**.
```

and the fix cell's 🔴/`toBlob` outcome matches `/home/node/cr-eval/runs/md1-opus-fix-r1/stdout.txt:89`
(R2 row, 🔴 Unresolved, `fact-check(Incorrect, high conf, 3/3)`). "7.8KB ×3,
byte-identical" carries the same minor imprecision as Claim 12 (identical except the
`r1/r2/r3` output-path digit — which is the SKILL-permitted difference), and the
hint-advantaged caveat is stated here consistently with the replication doc's caveat
section. Rounding 7,834 → "7.8KB" is fine at this row's precision.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:217`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:49-56,185-214`, `/home/node/cr-eval/runs/md1-opus-cc-r4/stdout.txt:38`, `/home/node/cr-eval/runs/md1-opus-fix-r1/stdout.txt:22,89`

---

## Claim 6: Open question #2 — "**Instrumented** (log row 27) … **Still zero data points** — accumulate ≥20 clustered claims"

**Location:** `docs/thoughts/code-review-evaluation-state.md:218`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

Data points now exist on this very branch. The committed merged report carries a measured
sample larger than the row's own ≥20 threshold:

```text
# docs/reviews/code-fact-check-report.md:130
- **Agreement rate:** 21/23 ≈ **0.91** (cluster level, first measured sample).
```

and the replication experiment recorded more:

```text
# docs/working/experiment-md1-r1-replication-2026-07-30.md:174-175
cc k=3 verdict-agreement rates ran well below the ≥90% k-reduction threshold (cc-r4 reports
47%), consistent with §1.1's premise
```

"Still zero data points" was true when written but is contradicted by two later artifacts
committed on the same branch. The row should now say the first samples exist (0.91 on 23
clusters here; ~47% on the MD1 cc cells) and note they point in opposite directions.

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:218`, `docs/reviews/code-fact-check-report.md:122-130`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:174-175`

---

## Claim 7: §5.0 bullet — "prompts grow 2–6× to ~18k–41k tokens; worst call $0.248, full 4-model×2 sweep $4.37 — both 021 guardrails hold"

**Location:** `docs/thoughts/code-review-evaluation-state.md:276-283`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

"2–6×" matches the reproduced growth ratios (2.1 / 3.5 / 2.2 / 4.8 / 5.6), and the dollar
figures verify (Claim 1). But "~18k–41k tokens" does not cover all five measured cells:
the reproduced MD1 stage-1 dry-run reports

```text
prompt size: 8,607 chars, ~2,151 tokens (diff 3,610 chars, sibling diff 0, enclosing files 3,579, 0 skipped)
```

(re-executed `scripts/cross-model-review.py --repo …/meta-formalism-copilot --range
'd86d2dc..d90d6bb' --context-base integration/6.1 --dry-run`). Four of five cells land in
18k–41k; MD1's stage-1 prompt is ~2.2k tokens. Precise phrasing: "to ~2k–41k tokens
(~18k–41k on the non-trivial cells)".

**Evidence:** `docs/thoughts/code-review-evaluation-state.md:282`, `docs/working/stage1-context-cost-2026-07-31.md:34-40`, reproduced dry-runs (Claim 14)

---

## Claim 8: Replication doc per-cell table — rc, elapsed, outcomes for the six cells

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:49-56`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every rc/elapsed pair matches the run artifacts exactly, e.g.:

```text
# /home/node/cr-eval/runs/md1-opus-cc-r2/status.txt
rc=0 elapsed=1414s
```

All seven cells (incl. fix-r1's `rc=0 elapsed=1720s`) match (paraphrased — no quote
available because the remaining six status files are one-line each and identical in form;
all were read). Outcome/tier spot-checks against stdout: cc-r2's ✅ Confirmed-Good row
certifying `connect-src 'self'` "breaks no current client fetch" is at
`/home/node/cr-eval/runs/md1-opus-cc-r2/stdout.txt:154`; cc-r4's A1-at-🟡
architecture-led recovery at `stdout.txt:38-40`; fix-r1's 🔴 R2 with 3/3 fact-check
convergence and `toBlob` at `stdout.txt:22,89`.

**Evidence:** `/home/node/cr-eval/runs/md1-opus-{r1,cc-r2,cc-r3,cc-r4,oc-r2,oc-r3,fix-r1}/status.txt`, `/home/node/cr-eval/runs/md1-opus-cc-r2/stdout.txt:53,154`, `/home/node/cr-eval/runs/md1-opus-cc-r4/stdout.txt:38-61`, `/home/node/cr-eval/runs/md1-opus-fix-r1/stdout.txt:22,89`

---

## Claim 9: "Under **cc**, **0/9 fact-check replicates** (3 runs × k=3) surfaced `exportGraph.ts` at all … (3/3 oc fact-check samples hit vs 0/9 cc replicates; Fisher exact one-sided p ≈ 0.0045)"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:85-92`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-executed: `grep -l exportGraph` over the nine cc replicate reports
(`md1-opus-cc-{r2,r3,r4}/repo/docs/reviews/code-fact-check-report-r{1,2,3}.md`, 9 files
confirmed present) returns **zero** files, while the three oc reports all hit
(paraphrased — no quote available because the claim covers absence of grep matches across
nine files). The oc side: `grep -l exportGraph` matches
`md1-opus-r1/…/code-fact-check-report.md`, `md1-opus-oc-r2/…`, and `md1-opus-oc-r3/…` —
3/3. Fisher one-sided recomputed in python3: `comb(3,3)*comb(9,0)/comb(12,3)` =
0.004545 ≈ 0.0045.

**Evidence:** `/home/node/cr-eval/runs/md1-opus-cc-{r2,r3,r4}/repo/docs/reviews/code-fact-check-report-r*.md`, `/home/node/cr-eval/runs/md1-opus-{r1,oc-r2,oc-r3}/repo/docs/reviews/code-fact-check-report.md`

---

## Claim 10: "oc orchestrators wrote **rich fact-check briefs (4.5–5.1KB)** containing a 'Claims that particularly need checking' list, including, **verbatim in both oc runs**: *'`connect-src 'self'` is sufficient because … — verify against actual client-side fetch/network code in the app.'*"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:98-102`
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Two mismatches against the transcripts. (1) Size: the three oc fact-check briefs measure
4,524 (r1), 5,067 (oc-r2), and 3,653 (oc-r3) chars — oc-r3 is well outside "4.5–5.1KB"
(paraphrased — no quote available because the prompts were extracted programmatically
from the cells' transcript JSONL `Agent` dispatches). (2) "Verbatim in both oc runs": the
quoted tail appears verbatim only in **md1-opus-r1**'s brief —

```text
# md1-opus-r1 transcript, fact-check Agent dispatch
- "`connect-src 'self'` is sufficient because Anthropic / OpenAlex / OpenRouter calls are server-to-server" — verify against actual client-side fetch/network code in the app.
```

oc-r2's entry ends differently ("— verify by searching the client-side code for any
browser-originated fetch to a no[n-self origin]…") and oc-r3's reads "verify no
browser-side fetch to a third-party origin exists". Whichever pair "both oc runs" denotes,
at most one brief carries the quoted text verbatim. The doc's *mechanism* claim (all oc
briefs contain a claims list aiming at client-side fetch enumeration; all cc replicate
prompts contain none) survives — it is the sizes and the "verbatim" attribution that are
wrong.

**Evidence:** transcript JSONL under `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-{r1,oc-r2,oc-r3}-repo/`

---

## Claim 11: "cc orchestrators wrote **lean, generic replicate prompts (2.3–3.0KB, byte-identical across replicates, no claims list)** in all three cc runs"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:103-104`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Measured replicate-prompt lengths: cc-r3 2,328 · cc-r2 2,691 · cc-r4 3,010 chars — the
"2.3–3.0KB" range is exact at its endpoints (paraphrased — no quote available because the
prompts were extracted programmatically from transcript JSONL). "No claims list"
confirmed: cc-r2's replicate prompt contains only goal/scope/output-requirements sections
("Run your own `git diff d86d2dc..d90d6bb` … Read the full current contents of any
changed file" — no per-claim enumeration). "Byte-identical across replicates" is
imprecise: within each cell the three prompts differ in the `r1/r2/r3` output-path digit
(unified-diff of r1-vs-r2 prompts shows exactly the two path lines changing), which is
the difference the k=3 spec itself mandates. "Identical except the output path" is the
precise phrasing.

**Evidence:** transcript JSONL under `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-cc-{r2,r3,r4}-repo/`

---

## Claim 12: "all three replicate prompts are 7,834 bytes (vs 2,328–3,010 in the pre-fix cc cells), byte-identical across replicates, containing a numbered claims list and the exercising-code directive"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:191-198`
**Type:** Behavioral / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Measured: all three fix-r1 replicate prompts are 7,834 **characters** (7,868 bytes UTF-8)
and identical except the `r1/r2/r3` digit in the two output-path lines (paraphrased — no
quote available because the prompts were extracted programmatically from
`md1-opus-fix-r1`'s transcript JSONL; the r1-vs-r2 unified diff shows only the two
path lines). The 2,328–3,010 comparison range is exact (Claim 11). So: numbers right in
chars (mislabelled "bytes"), and "byte-identical" holds only modulo the SKILL-permitted
path difference. The claims-list and exercising-code-directive content is present as
described.

**Evidence:** transcript JSONL under `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-fix-r1-repo/`

---

## Claim 13: "**Fact-check replicates reached `exportGraph.ts`: 3/3** (vs 0/9 pre-fix)"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:199`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-executed: `grep -l exportGraph` over
`md1-opus-fix-r1/repo/docs/reviews/code-fact-check-report-r{1,2,3}.md` matches all three
files (paraphrased — no quote available because the evidence is a grep hit-list across
three files). The 0/9 pre-fix baseline is Claim 9. The downstream synthesis matches:
`/home/node/cr-eval/runs/md1-opus-fix-r1/stdout.txt:22` reads "security,
api-consistency, and 3/3 replicates. The browser-side `fetch(dataUrl)` at
`exportGraph.ts:24` and `:37` is blocked."

**Evidence:** `/home/node/cr-eval/runs/md1-opus-fix-r1/repo/docs/reviews/code-fact-check-report-r{1,2,3}.md`, `/home/node/cr-eval/runs/md1-opus-fix-r1/stdout.txt:22`

---

## Claim 14: Stage-1 cost doc measured table — five cells' diff-only/stage-1 token counts, sibling/enclosing sizes, growth multipliers, "No cell hit the --max-inline-kb fallback (0 files skipped everywhere)"

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:32-49`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All ten dry-runs were re-executed. Diff-only tokens reproduce exactly (1,037 / 11,758 /
8,088 / 6,637 / 6,010); stage-1 threadwork cells reproduce exactly, e.g.:

```text
# re-run: --repo …/threadwork --range '689e93c~1..689e93c' --context-base origin/master --dry-run
prompt size: 135,376 chars, ~33,844 tokens (diff 23,511 chars, sibling diff 68,350, enclosing files 41,845, 0 skipped)
```

(D3 likewise: 31,945 tokens, sibling 55,002, enclosing 44,929, 0 skipped — matching the
table's 55 KB / 45 KB). MD1/ND2/ND3 stage-1 runs (base = each repo's default branch,
`integration/6.1` / `feat/tree-obstacles`) reproduce within 1–2 tokens (2,151 / 40,589 /
18,017 vs the doc's 2,150 / 40,587 / 18,015) — the residue is the base-ref name's length
appearing in the empty-sibling placeholder line, i.e. the doc's runs used a
slightly-shorter base ref spelling; sibling diff = 0 and enclosing sizes (3,579 / 113,647
/ 38,409 chars ≈ 3.6 / 114 / 38 KB) match. "0 files skipped" reproduced in all five
stage-1 cells. Growth multipliers recomputed: 2.1 / 3.5 / 2.2 / 4.8 / 5.6 — matching the
table.

**Evidence:** `docs/working/stage1-context-cost-2026-07-31.md:34-49`, re-executed `scripts/cross-model-review.py … --dry-run` for all five cells in both modes

---

## Claim 15: Dagger footnote — "The MD1/ND2/ND3 ranges are already merged into their repos' mainlines, so `base...range-left` collapses to the merge-base and the sibling section is empty"

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:42-47`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The mechanism and the empty-sibling observation reproduce (Claim 14). But "the ranges are
already merged" is not true of MD1: `git merge-base --is-ancestor d90d6bb
integration/6.1` in `/workspace/external/meta-formalism-copilot` exits 1 — the reviewed
range's *end* commit is not on the mainline; only the range *start* is (`… --is-ancestor
d86d2dc integration/6.1` exits 0) (paraphrased — no quote available because the evidence
is exit codes of executed git ancestry checks). ND2 and ND3 are genuinely merged (both
`2d0ee3c` and `319f229` are ancestors of `feat/tree-obstacles`). The sibling section is
empty for MD1 because the range *starts at* a mainline commit, not because the range is
merged. The doc's practical conclusion (historical-repo artifact; expect the D3/D4 shape
live) is unaffected.

**Evidence:** `docs/working/stage1-context-cost-2026-07-31.md:42-47`, git ancestry checks in `/workspace/external/meta-formalism-copilot` and `/workspace/external/nature_photographer`

---

## Claim 16: Projected-cost tables — per-call D4 figures for four models, "diff-only $1.95 → Stage-1 $4.37 (~2.2×)", "priciest single call is $0.248 (Sol on ND2)"

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:51-68`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Internally consistent and consistent with independently-observed pricing. Solving the
table's own pairs gives $2/$12 (Gemini), $5/$30 (Sol), $3/$15 (Kimi, Sonnet) per Mtok —
and three of those four are directly corroborated by the immutable sweep meta.json files,
e.g. `moonshotai_kimi-k3.meta.json`: `0.068211 / 22737` prompt tokens = $3.00/Mtok and
`0.487305 / 32487` completion tokens = $15.00/Mtok (paraphrased — no quote available
because the arithmetic is a computed ratio over quoted JSON fields). Recomputing every
table cell with those prices and the doc's stated assumptions (1,500 output tokens/call,
5 cells × 4 models × 2 replicates = 40 calls) reproduces each per-call figure ($0.030 /
$0.086, $0.075 / $0.214, $0.041 / $0.124 ×2), the sweep totals ($1.95 → $4.37, ratio
2.24 ≈ 2.2×), and the $0.248 worst call. Guardrail comparison verified in Claim 1.

**Evidence:** `docs/working/stage1-context-cost-2026-07-31.md:51-68`, `runs/dd-cross-model-2026-07-30/{moonshotai_kimi-k3,google_gemini-3.1-pro-preview,openai_gpt-5.6-sol}.meta.json`, python3 recomputation

---

## Claim 17: Sweep README corrected values — latency/token/cost table, "~6× Sol's latency (and ~8.5× Gemini's)", Kimi "runner-up [2] measurement-first", "API cost: $1.21 total"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:38-60`
**Type:** Reference / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Checking only what the 2026-07-30 review's M16/M17 fixes left in place: every numeric
cell matches the meta.json files (Sol 155s/9,147(2,233); Gemini 112s/15,594(11,870);
Kimi 956s/32,487(24,306)), e.g.:

```json
// runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json
"completion_tokens": 32487, … "reasoning_tokens": 24306, … "latency_s": 955.9
```

Ratios recomputed: 955.9/154.5 = 6.2 and 955.9/112.2 = 8.5 — the corrected "~6× Sol's
(and ~8.5× Gemini's)" stands. The corrected Kimi recommendation matches the Kimi
artifact: `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:171` reads "▶ recommend
[3] k≥3 fact-check, most-severe-wins · confidence 75% · runner-up [2]," where candidate
[2] is "measurement-first" (`moonshotai_kimi-k3.md:147`). Cost sum: 0.5555 + 0.4173 +
0.2346 = $1.21.

**Evidence:** `runs/dd-cross-model-2026-07-30/README.md:38-60`, `runs/dd-cross-model-2026-07-30/*.meta.json`, `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:147,171`

---

## Claim 18: "Files larger than --max-inline-kb are listed but not inlined" and "--max-inline-kb (default 64)"

**Location:** `scripts/cross-model-review.py:20-22` (docstring), `scripts/cross-model-review.py:301-302` (argparse)
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The argparse default matches:

```python
# scripts/cross-model-review.py:301-302
ap.add_argument("--max-inline-kb", type=int, default=64, help="Stage 1: files larger than "
                "this are listed but not inlined")
```

and the oversize path appends to `skipped` and emits the listing block:

```python
# scripts/cross-model-review.py:163-169
if len(content) > max_inline_kb * 1024:
    skipped.append((path, len(content), "over --max-inline-kb"))
    continue
…
parts.append("\n=== FILES TOO LARGE TO INLINE (context unavailable; judge these "
             "from the diff alone) ===\n" + lines + "\n")
```

**Evidence:** `scripts/cross-model-review.py:20-22,158-169,301-302`

---

## Claim 19: "Without --context-base the prompt is byte-identical to the pre-021 harness, so historical numbers stay comparable"

**Location:** `scripts/cross-model-review.py:22-24`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Programmatically compared `PROMPT_TEMPLATE` between `git show main:scripts/cross-model-review.py`
and HEAD: identical (paraphrased — no quote available because the comparison was an
executed string-equality check over the two extracted template literals). The diff-only
code path formats it the same way as main's single path:

```python
# scripts/cross-model-review.py:326-328 (HEAD)
else:
    context, ctx_stats = "", {}
    prompt = PROMPT_TEMPLATE.format(label=label, diff=diff)
```

with `label` built identically to main (`f"{os.path.basename(args.repo)} {args.rev_range}"`).
Same template + same substitutions ⇒ byte-identical prompt. (Also spot-confirmed by
Claim 14: all five diff-only dry-run token counts match the doc's pre-measured values.)

**Evidence:** `scripts/cross-model-review.py:60-72,318-328`, `git show main:scripts/cross-model-review.py`

---

## Claim 20: "--dry-run builds the prompt, writes it to <out>/prompt.txt, and prints per-section token estimates and projected per-model cost WITHOUT sending anything (pricing fetch is skipped if OPENROUTER_API_KEY is unset)"

**Location:** `scripts/cross-model-review.py:25-27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The write, the no-send exit, and the key-gated pricing fetch all check out:

```python
# scripts/cross-model-review.py:333
pricing = fetch_pricing(key) if key else {}
```

and the dry-run branch writes `prompt.txt` then `return`s before any model call
(`scripts/cross-model-review.py:349-355`). The imprecision: the printout gives
per-section **character** counts and a single whole-prompt token estimate, not
"per-section token estimates":

```python
# scripts/cross-model-review.py:340-345
print(f"prompt size: {len(prompt):,} chars, ~{int(est_in_tok):,} tokens "
      f"(diff {len(diff):,} chars"
      + (f", sibling diff {ctx_stats.get('sibling_diff', 0):,}, enclosing files …
```

Per-model cost lines print only when `args.models` is given and pricing is available
(`scripts/cross-model-review.py:346-351`), which matches the docstring's conditional
framing.

**Evidence:** `scripts/cross-model-review.py:25-27,333-355`

---

## Claim 21: split_range docstring — "Return (left, right) of a git range like 'a..b' / 'a...b'; right defaults to HEAD"

**Location:** `scripts/cross-model-review.py:114-119`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The implementation does exactly this:

```python
# scripts/cross-model-review.py:116-118
parts = re.split(r"\.{2,3}", rev_range, maxsplit=1)
left = parts[0].strip()
right = parts[1].strip() if len(parts) > 1 and parts[1].strip() else "HEAD"
```

`a..b`/`a...b` → (`a`,`b`); `a..` and bare `a` → right=`HEAD`. One caller-semantics note
(not a defect in this docstring): for a three-dot range the UNDER-REVIEW diff
(`git diff a...b`) starts at merge-base(a,b), while `build_stage1_context` builds the
sibling section as `context_base...left` — so commits between merge-base(a,b) and `a`
would appear in the reviewed diff's base rather than the sibling section. All ranges used
by the branch's docs are two-dot, where left is exactly the range start (paraphrased — no
quote available because the observation is about which section a commit falls into across
two git invocations at `scripts/cross-model-review.py:139,318`).

**Evidence:** `scripts/cross-model-review.py:114-119,139,318`

---

## Claim 22: build_stage1_context docstring — "Returns (context_text, stats) where stats maps section -> char count for the dry-run report"

**Location:** `scripts/cross-model-review.py:122-133`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Two of the three stats keys are char counts; the third is a file count:

```python
# scripts/cross-model-review.py:171-172
stats["enclosing_files"] = inlined
stats["skipped_files"] = len(skipped)
```

(`sibling_diff` is `len(sibling)`, a char count, at line 140). The dry-run printer
consumes exactly these three keys (`ctx_stats.get('sibling_diff'…'enclosing_files'…
'skipped_files'` at `scripts/cross-model-review.py:342-344`), so the docstring/printer
key agreement the doc implies is exact — only the "char count" description of
`skipped_files` is off (it prints as "N skipped", a count).

**Evidence:** `scripts/cross-model-review.py:122-133,138-172,340-345`

---

## Claim 23: Binary-file skip — `if "\x00" in content[:8192]: skipped.append((path, len(content), "binary"))` (binary files are detected and listed rather than inlined)

**Location:** `scripts/cross-model-review.py:160-162`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The guard as written checks the first 8,192 *decoded characters*, but for a typical
binary file execution never reaches it: `sh()` runs subprocess with `text=True`
(`scripts/cross-model-review.py:111`), so `git show` of non-UTF-8 content raises
`UnicodeDecodeError` — and the only exception caught around the `git show` call is
`CalledProcessError`:

```python
# scripts/cross-model-review.py:153-155
try:
    content = sh(["git", "-C", repo, "show", f"{right}:{path}"])
except subprocess.CalledProcessError:
```

Empirically confirmed: emulating `sh()` on a committed 10 KB blob of bytes 0x00–0xFF
raises `UnicodeDecodeError: 'utf-8' codec can't decode byte 0x80 in position 128` before
the NUL check can run (paraphrased — no quote available because the evidence is an
executed reproduction in a throwaway git repo). So the "binary" skip fires only for
NUL-containing content that happens to decode as UTF-8; a repo with an ordinary committed
PNG/font crashes the stage-1 build instead of producing the "listed, not inlined" entry.
None of the five measured cells contains such a file, so the measured docs are unaffected.

**Evidence:** `scripts/cross-model-review.py:111,153-162`, executed binary-blob reproduction

---

## Claim 24: dd-cross-model-sweep.py provenance — "This is the runner that produced runs/dd-cross-model-2026-07-30/ (the fourth arm, local Fable, ran as a Claude Code subagent … — no script). Committed per tech-debt finding C20 of the 2026-07-30 review: the sweep README's results table was hand-transcribed from the *.meta.json files this script writes, and hand transcription is where both of that README's data errors came from"

**Location:** `scripts/dd-cross-model-sweep.py:3-9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

C20 exists as a rubric row sourced from the tech-debt review:

```text
# docs/reviews/code-review-rubric-2026-07-30-exp-cross-model-openrouter-sweep.md:62
| C20 | DD-sweep harness not committed (`run_dd_sweep.py` lived in job tmp); README table hand-transcribed — which is where R2/R3 arose | tech-debt-triage #5 | … | ✅ Fixed (`scripts/dd-cross-model-sweep.py`, …) |
```

and the tech-debt review itself names both errors as arising "in exactly that table"
(`docs/reviews/tech-debt-triage-review-2026-07-30.md:441-444`: "the README's `Results at
a glance` table is hand-transcribed … Stage 1's fact-check found two errors in exactly
that table (the Kimi runner-up attribution and the '~9×' latency figure)"). The script's
MODELS list and outputs match the three OpenRouter artifact/meta pairs in the run
directory, and no `local_claude-fable-5.meta.json` exists — consistent with the
no-script fourth arm (paraphrased — no quote available because the claim is about
directory contents). Confidence Medium only because "hand transcription" loosely covers
M16, which arose from misreading the Kimi artifact's banner rather than the meta.json —
the cited review itself uses the same framing, so the docstring faithfully reports its
source.

**Evidence:** `scripts/dd-cross-model-sweep.py:3-9,26`, `docs/reviews/code-review-rubric-2026-07-30-exp-cross-model-openrouter-sweep.md:62`, `docs/reviews/tech-debt-triage-review-2026-07-30.md:438-446`, `runs/dd-cross-model-2026-07-30/`

---

## Claim 25: "kimi-k3 spends budget inside the reasoning trace and returns content:null if max_tokens is too low (see scripts/cross-model-review.py) — be generous" with `"max_tokens": 48000`

**Location:** `scripts/dd-cross-model-sweep.py:33-36`
**Type:** Behavioral / Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cross-reference resolves: the harness documents the same failure mode and handles it:

```python
# scripts/cross-model-review.py:384 (comment) and 396
# Reasoning models (e.g. kimi-k3) return message.content = null when the
…
"error": f"empty-content finish_reason={finish}",
```

`max_tokens` is literally 48000 (`scripts/dd-cross-model-sweep.py:36`), and the empirical
plausibility is corroborated by the immutable run metadata — Kimi's actual completion
used 32,487 tokens of which 24,306 were reasoning (`moonshotai_kimi-k3.meta.json`), i.e.
a low cap would indeed have been consumed by the reasoning trace.

**Evidence:** `scripts/dd-cross-model-sweep.py:31-36`, `scripts/cross-model-review.py:384-400`, `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json`

---

## Claim 26: Gate 1h comment — "Stage 1 runs fact-check as k=3 replicates and stamps the merged report with a `**Replication:**` header field plus a `Commit:` line; without this check a degraded k=2 run (or a stale report …) is invisible here"

**Location:** `scripts/self-improvement.sh:1481-1487` (parsing at 1490-1516)
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The parsing does match the format the skill specifies. SKILL.md instructs the merged
report to add "`**Replication:** k=3` … (or `**Replication:** k=2 (one replicate
failed)` on the degraded path)" (`skills/code-review/SKILL.md:370-372`), which the gate's
`sed -n 's/^\*\*Replication:\*\* *//p'` extracts and its `case` vocabulary (`k=3*` pass /
`""` missing / `*` degraded — so `k=2 (one replicate failed)` lands in the degraded arm)
handles correctly; the `Commit:` line is instructed for every saved artifact
("include a `Commit: <hash>` metadata line at the top of each file",
`skills/code-review/SKILL.md:1207`) and the prefix test
`[ "${CR_COMMIT#"$CR_FC_COMMIT"}" = "$CR_COMMIT" ]` correctly detects a short-SHA
non-prefix. The caveat: the one merged report actually produced under this SKILL
(`docs/reviews/code-fact-check-report.md`, `Commit: e9d05ea`) titles itself
"(merged, k=3 most-severe-wins)" but contains **no** `**Replication:**` field anywhere
(paraphrased — no quote available because the claim covers absence of a grep match in
that file) — the SKILL's merge step names the field but the orchestrator that wrote the
existing report omitted it, so on this artifact the gate's `""` arm would advisory-log a
genuine k=3 run as "single-sample fact-check, not full k=3". The comment accurately
describes the *instructed* contract; the observed artifact stream does not yet honor it.

**Evidence:** `scripts/self-improvement.sh:1481-1516`, `skills/code-review/SKILL.md:359-372,1207`, `docs/reviews/code-fact-check-report.md:1-15`

---

## Claim 27: Step 3b — "the MD1-R1 replication … measured what happens when orchestrators read the uniformity clause as license for lean generic prompts — 0/9 replicates reached the cross-file evidence a single richly-briefed run had found 3/3 times"

**Location:** `skills/code-review/SKILL.md:285-290`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The 0/9 and 3/3 numbers are real (Claim 9), but the phrase "a single richly-briefed run
had found 3/3 times" misstates the experiment's shape: the 3/3 is **three separate runs**
(md1-opus-r1, oc-r2, oc-r3), each dispatching **one** fact-check agent with its own
independently-authored rich brief — not one run observed three times. The source doc
states it as runs:

```text
# docs/working/experiment-md1-r1-replication-2026-07-30.md:82-84
- Under **oc**, the (single) fact-check agent found GT-R1 itself in **3/3 runs** (r1, oc-r2,
  oc-r3), rating the `connect-src`-sufficiency commit claim **Incorrect**
```

Precise phrasing: "…evidence that single-agent richly-briefed runs had found 3/3" (or
"k=1 runs found 3 times out of 3 runs"). As written, a reader could take "3/3" as a
within-run replicate rate, which is exactly the k=3-vs-k=1 distinction this paragraph
exists to teach.

**Evidence:** `skills/code-review/SKILL.md:285-290`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:82-92`

---

## Claim 28: Soundness-channel validation status in SKILL.md — "8 of 19 trigger fires were rows already promoted by existing channels", "recall 1/1 on the ND2 reconstruction; ~1.3% clear-false-lift rate before the … tightening, 0 after it; md1 `proxy.ts:14` held non-vacuously … ND3's `sim.ts:625-628` control was vacuous" (and the matching summary in decision 028)

**Location:** `skills/code-review/SKILL.md:1128-1157`; `docs/decisions/028-escalation-second-channel.md:176`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Each figure matches the validation doc it cites:

```text
# docs/working/validation-soundness-channel-2026-07-30.md:160
| **— false lifts (clear)** | **4** (nd2 opus-r2 security #2; nd3 fable tdt #3, opus arch #2, opus api F5) — **rate 4/315 ≈ 1.3%** |
```

```text
# docs/working/validation-soundness-channel-2026-07-30.md:200
qualifying finding already at 🔴 keeps its band (8 of 19 fires in this corpus are
```

Corpus size 315 (11 cells, ~27 reports) at `validation-soundness-channel-2026-07-30.md:27,154`;
the md1-non-vacuous / ND3-vacuous control characterization matches 028's own validation
addendum ("md1 `proxy.ts:14` 0 lifts across 7 probes, precision guard held; ND3
`sim.ts:625-628` 0 lifts but **vacuous**", `028-escalation-second-channel.md:176`). The
`[is]`-bracket rationale for the verbatim definition also matches
(`validation-soundness-channel-2026-07-30.md` recalibration items, paraphrased — no quote
available because the item list spans the doc's closing section and is quoted in 028:176).

**Evidence:** `skills/code-review/SKILL.md:1128-1157`, `docs/decisions/028-escalation-second-channel.md:176`, `docs/working/validation-soundness-channel-2026-07-30.md:27,154-162,190-205`

---

## Claim 29: factcheck-replication.bats header — Result 14a description, "one of the two verdict-driven blocking channels … the only one reachable by documentation-class findings", decision log row 27 attribution

**Location:** `test/skills/code-review-factcheck-replication.bats:3-13`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Result 14a exists and says what the header says:

```text
# docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:227
## Result 14a — ND2 replication (n=2)
```

with the Incorrect-vs-Mostly-Accurate flip on identical input documented in the state doc
§1.1 (`docs/thoughts/code-review-evaluation-state.md:55-59`: "the same
`WARY_MOOD_DURATION` comment defect was rated **Incorrect** by one run and **Mostly
Accurate** by another, flipping the same finding between 🔴 and 🟡"). Log row 27 exists
and matches (Claim 2). The header's "(state doc §1.0: …)" citation shares the phantom
anchor flagged in Claim 4; content is otherwise correct, so the header stands with that
one cross-reference fix.

**Evidence:** `test/skills/code-review-factcheck-replication.bats:3-13`, `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:227-264`, `docs/thoughts/code-review-evaluation-state.md:52-59`, `docs/decisions/log.md:48`

---

## Claim 30: soundness-crosscheck.bats header — ND2 story ("a reviewer that reached the ground-truth defect … still filed it 🟢 (Results 15/14a), while the human panel filed the same finding 🟡"), channel contract summary, and the named negative controls (ND3 fixed docstring / md1 proxy.ts:14)

**Location:** `test/skills/code-review-soundness-crosscheck.bats:3-16,120`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Result 15 exists and is on point:

```text
# docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:173
## Result 15 — ND2's A1 is missed by all three tiers, and the mechanism is legible
```

The 🟢-filed / human-🟡 account matches state doc §1.2 and decision 028's rationale
(log row 28: "the human panel filed the same finding 🟡 and gated the merge"), and the
contract summary (terminal at 🟡, excluded from escalation corroboration, the one
contextual-critic exception) matches the SKILL's channel section
(`skills/code-review/SKILL.md:1136-1141`: "**🟡 is the terminal tier for this channel.**
… does not count as corroboration under the [Escalation Rule]"). The controls named in
the test's failure message (`test/skills/code-review-soundness-crosscheck.bats:120`:
"the negative controls (ND3 fixed docstring / md1 proxy.ts:14) are not named") match the
falsifier locations in 028 and the validation doc (Claim 28).

**Evidence:** `test/skills/code-review-soundness-crosscheck.bats:3-16,120`, `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:173-185`, `skills/code-review/SKILL.md:1128-1141`, `docs/decisions/log.md:49`

---

## Claims Requiring Attention

### Incorrect
- **Claim 10** (`docs/working/experiment-md1-r1-replication-2026-07-30.md:98-102`): oc fact-check briefs measure 4,524 / 5,067 / **3,653** chars (oc-r3 well below "4.5–5.1KB"), and the quoted connect-src directive is verbatim only in md1-opus-r1's brief — not "verbatim in both oc runs". Fix the range and the attribution; the rich-vs-lean mechanism itself survives.

### Stale
- **Claim 6** (`docs/thoughts/code-review-evaluation-state.md:218`): "Still zero data points" — the branch's own merged report records agreement 21/23 ≈ 0.91 and the MD1 cc cells recorded ~47%; the row predates both.

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:50`): inherits Claim 10's "4.5–5.1KB" floor (oc-r3 is ~3.7KB).
- **Claim 4** (`docs/thoughts/code-review-evaluation-state.md:53` + 3 more files): "§1.0" does not exist in the state doc; the cited content lives in "The one-paragraph state of things". Add the anchor or fix the citation in state doc, SKILL.md:264, factcheck bats:7, log row 27.
- **Claim 7** (`docs/thoughts/code-review-evaluation-state.md:282`): "~18k–41k tokens" excludes MD1's ~2.2k-token stage-1 prompt; true of 4/5 cells only.
- **Claim 11** (`experiment-md1-r1-replication…:103`): "byte-identical" cc replicate prompts differ in the r1/r2/r3 output path (the spec-permitted difference); say "identical except the output path".
- **Claim 12** (`experiment-md1-r1-replication…:191`): 7,834 is the char count (7,868 bytes); same "byte-identical modulo path" nuance.
- **Claim 15** (`docs/working/stage1-context-cost-2026-07-31.md:42`): MD1's range is *not* merged into `integration/6.1` (d90d6bb is not an ancestor); the sibling section is empty because the range *starts* at a mainline commit. ND2/ND3 are genuinely merged.
- **Claim 20** (`scripts/cross-model-review.py:26`): dry-run prints per-section **char** counts plus one aggregate token estimate, not "per-section token estimates".
- **Claim 22** (`scripts/cross-model-review.py:125`): `stats` maps sections to char counts except `skipped_files`, which is a file count.
- **Claim 23** (`scripts/cross-model-review.py:160`): the `"\x00"` binary guard is unreachable for real binaries — `sh()` uses `text=True` and `UnicodeDecodeError` is uncaught, so a committed PNG crashes the stage-1 build instead of being listed as skipped.
- **Claim 26** (`scripts/self-improvement.sh:1481`): the gate's parsing matches the SKILL-instructed format, but the one real merged report (`Commit: e9d05ea`) lacks the `**Replication:**` field, so the gate would advisory-flag that genuine k=3 run as single-sample.
- **Claim 27** (`skills/code-review/SKILL.md:288`): "a single richly-briefed run had found 3/3 times" — the 3/3 is three separate single-agent runs, not one run sampled three times; reword to keep the k=1-vs-k=3 comparison honest.

### Unverifiable
- (none)

---

## Hallucination-pattern-log check

No Incorrect verdict in this run asserts a fabricated symbol, method, API, or library
parameter (Claim 10 is a mis-measured size range and a wrong verbatim attribution; the
§1.0 anchor in Claim 4 is a wrong section number for content that genuinely exists —
a stale-reference class, per the log's exclusion rules). No entry appended to
`docs/reviews/hallucination-patterns.md`.

## Goal-Alignment Note

- Answered: yes — all ten briefed claim groups checked, including full re-execution of the stage-1 dry-runs, the md1 cell artifacts, transcript prompt extraction, and python3 recomputation of every quoted number.
- Out of scope: claims *inside* the immutable `runs/dd-cross-model-2026-07-30/` artifacts and pre-existing `docs/reviews/` reports (per brief); noted in passing that the tech-debt review's line "Decision-log row 26 cites this sweep" appears to mean row 27, but that file is immutable evidence.
- Escalate: (1) the phantom "§1.0" anchor is repeated in four branch files — one coordinated fix; (2) `scripts/cross-model-review.py` stage-1 crashes on any committed binary file (uncaught `UnicodeDecodeError`) — worth a fix before a live sweep on a repo with images/fonts; (3) the merged fact-check report format on this branch omits the `**Replication:**` field Gate 1h and SKILL.md both expect.
- Questions I would have asked: whether "both oc runs" in the replication doc was intended to include the prior-art r1 cell — the verbatim-quote claim fails under every reading, but the fix wording depends on the intent.
