Commit: 123432af

# Code Fact-Check Report

**Commit:** 123432af
**Replication:** k=3
**Repository:** claude-workflows (branch measure/a8-token-measurement)
**Scope:** `--files` runs/review-arms/a8-2026-11-19/{results.md,token-ledger.md,manifest.json}, docs/working/research-2026-11-19-a8-token-measurement.md (self-read)
**Checked:** 2026-11-19
**Total claims checked:** 16
**Summary:** 1 verified, 10 mostly accurate, 0 stale, 3 incorrect, 2 unverifiable

Merged most-severe-wins by the orchestrator from `code-fact-check-report-2026-11-19-a8-r1.md` (35 claims), `-r2.md` (29) and `-r3.md` (39), all `Commit: 123432af`. Claims every replicate verified are collapsed into Claim 1; each other cluster keeps its own section. All verdicts are static reads of files plus python aggregates over the sub-agent transcripts.

---

## Claim 1: the measured figures (token values, sums, ratios, instrument, first-call cache figures, prompt hashes, block sizes, skill-size deltas, label table)

**Location:** `runs/review-arms/a8-2026-11-19/results.md:21-80`, `token-ledger.md`, `manifest.json`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every figure the replicates recomputed from the notifications, transcripts, shared-block files, git history and canon ledger; does not establish the August instrument's definition.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "the transcripts record cache breakpoints system[0], system[1], messages[1].content[3]"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** each replicate's Claims 1-10 equivalents

---

## Claim 2: "Two findings are new" (prefetch CSP gap, pdf.js worker-src)

**Location:** `runs/review-arms/a8-2026-11-19/results.md:98-100`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the canon ledger's N-series entries.
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=—
**Replicate annotations:** r1+r2: "prefetch = canon N1 (fix-confirmed ab4dbdb, ledger :176-177); worker-src = canon N7, refuted by E7r2 (:185-189), a known false positive"
**Legibility-target:** for-author

**Evidence:** `docs/working/canon-issue-ledger.md:176-189`

---

## Claim 3: "Lever #3 accounts for at most 3 of those points" and the §4 verdict wording

**Location:** `runs/review-arms/a8-2026-11-19/results.md:104-114`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arithmetic of the bound and whether the verdict's net-cost clause is supported.
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "the block is 2.9-4.4 points of each agent's baseline (≈4 overall), not at most 3" · r1+r2: "'small but not zero' asserts a net effect the run never measured; the benefit-was-0 half can carry the verdict" · r2: "benefit 0 holds for one terminal pass only, not across loop passes"
**Legibility-target:** for-author

**Evidence:** `token-ledger.md` rows 1-8; baseline `token-ledger.md`

---

## Claim 4: "Today's skill (82accdd7)" / "last changed 82accdd7"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:24`, `manifest.json:4`, `results.md:16`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `git log -- skills/code-review/SKILL.md`.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "SKILL.md last changed in 44724747; 82accdd7 touched only references/rubric.md"
**Legibility-target:** for-author

**Evidence:** `git log -- skills/code-review/SKILL.md`

---

## Claim 5: the instrument field is called `total_tokens`

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:40`, `token-ledger.md:3`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the notification field name.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "the ledger states 'same instrument as the baseline' without the research doc's 'I assume'"
**Legibility-target:** for-author

**Evidence:** task notifications (`<subagent_tokens>`)

---

## Claim 6: skill texts "~25-34 KB", "190 KB"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:55-56,74-75`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `wc -c` of the skill files.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "14.5-34 KB; ~250 KB over the 9 prompts"
**Legibility-target:** for-author

**Evidence:** `skills/*/SKILL.md` sizes

---

## Claim 7: "23.4k tokens over the 8 core agents"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:46-47`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the block-size sum.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Incorrect
**Replicate annotations:** r1+r2+r3: "3×2,189 + 5×2,929 ≈ 21.2k (2.85%); '≈3%' still holds"
**Legibility-target:** for-author

**Evidence:** `csp/shared-block.md`, `csp/shared-block-stage2.md` sizes

---

## Claim 8: "~97k, +26% at k=1-equivalent"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:40-42`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the remainder arithmetic.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "~97k is +27% of 359k; +26% is +111k against 424,520"
**Legibility-target:** for-author

**Evidence:** `results.md` §1 table

---

## Claim 9: residual "5k to 20k per agent"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:48-49`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers critic growth minus block minus skill growth.
**Replicate verdicts:** r1=Mostly accurate · r2=— · r3=Mostly accurate
**Replicate annotations:** r1+r3: "7.4k-19.9k per critic"
**Legibility-target:** for-author

**Evidence:** ledger rows 4-8, skill-size deltas

---

## Claim 10: "shared block never served from cache"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:95`, `manifest.json:46`, `results.md:62-70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers per-call cache figures.
**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r3: "true across agents on the first call; from call 2 each agent reads the block from its own cache (r1 reads 51,697 on its second call)" · r3: "api critic's last call came 59 s before Stage 2.5's first call with the same 8,745-char prefix, so expiry does not explain the Stage 2.5 miss" · r2: "'this run cannot tell them apart' overlooks the recorded breakpoints" · r1: "r3's first call came ~5.5 s after r1's and r2's and still read 18,900"
**Legibility-target:** for-author

**Evidence:** transcripts' `api-request` `cacheControl` records and per-call usage

---

## Claim 11: the brief "does not name exportGraph.ts or any finding"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:90-93`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the dispatched fact-check prompts.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "'check the client-side code' and '(does anything read it?)' point at the R1 and A1 routes"
**Legibility-target:** for-author

**Evidence:** `csp/code-fact-check-report-r*.md` prompts (transcript first records)

---

## Claim 12: per-agent growth "+24-40%"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:110`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers per-agent ratios.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "individual agents +15% (architecture) to +40% (replicate mean)"
**Legibility-target:** for-author

**Evidence:** ledger rows

---

## Claim 13: "2,189 tokens (chars/4)"

**Location:** `token-ledger.md:5`, `manifest.json:14`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers bytes vs characters of `csp/shared-block.md`.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "2,189 is bytes/4; chars/4 is 2,186"
**Legibility-target:** for-author

**Evidence:** `wc -c` vs `len()` of `csp/shared-block.md`

---

## Claim 14: ledger `tool_uses` and r2's verdict string

**Location:** `token-ledger.md` rows 1-9
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers transcript tool-call counts and r2's report body.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=Unverifiable
**Replicate annotations:** r2+r3: "every ledger tool_uses value is the transcript count minus 1" · r1: "ledger values match the task notifications" · r2: "r2's header says 14 claims / 5V; its body has 15 verdicts with 6 Verified; the ledger copies the header"
**Legibility-target:** for-author

**Evidence:** transcripts; `csp/code-fact-check-report-r2.md`

---

## Claim 15: the ~30k injected-context split and "the August run left no transcripts"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:50-52`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the first-call figures; does not establish what fills the remainder or whether August transcripts exist anywhere.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1+r3: "the ~30k is a remainder, not measured" · r2: "'no transcripts' needs a search of August task directories"
**Legibility-target:** for-author

**Evidence:** first-call usage records

---

## Claim 16: the cause of the cache miss

**Location:** `runs/review-arms/a8-2026-11-19/results.md:66-69`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the request records show; does not establish the API's prefix-matching rule.
**Replicate verdicts:** r1=Unverifiable · r2=Mostly accurate · r3=—
**Replicate annotations:** r1: "needs request bodies or the two-agent probe" · r2: "the recorded breakpoints bear on it"
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** transcripts' `cacheControl` records

---

## Claims Requiring Attention

### Incorrect
- Claim 2 (`results.md:98-100`): N1 and N7 already in the canon; N7 refuted.
- Claim 3 (`results.md:104-114`): "at most 3 points" wrong (≈4); net-cost clause unsupported.
- Claim 7 (`results.md:46-47`): 21.2k, not 23.4k; "≈3%" holds.

### Mostly Accurate
- Claims 4, 5, 6, 8-14 as above.

### Unverifiable
- Claims 15, 16.

## Escalations

- Rubric A4 (worker half) of the measured pass repeats canon N7, a known false positive. Raised by r1, r2. Addressee: orchestrator.
- Settle the instrument field name before comparing with other runs. Raised by r3. Addressee: orchestrator.

## Verdict stability

- Clusters: 16. Agreed among reporting replicates: 12 (Claims 1, 2, 4, 5, 6, 8, 9, 10, 11, 12, 13, 15). Disagreed: 4 (Claim 3 I/MA/I, Claim 7 MA/MA/I, Claim 14 V/MA/U, Claim 16 U/MA/—). Agreement rate: 12/16 = 75%.

## Goal-Alignment Note
- Success criterion (restated verbatim): A merged code-fact-check report (most-severe-wins over r1-r3) saved as docs/reviews/code-fact-check-report-2026-11-19-a8.md.
- Answered: yes
- Out of scope: none
- Escalate: the two entries above.
