Commit: 1431b628

# Code Fact-Check Report

**Repository:** /workspace/.worktrees/wt-2026-11-19-a8-settling-runs (branch measure/a8-settling-runs)
**Scope:** files the orchestrator wrote since 14d450d9: runs/review-arms/a8-2026-11-20/{results.md, token-ledger.md, manifest.json, csp/code-review-rubric-2026-11-19-csp.md, corpus/code-review-rubric-2026-11-19-corpus.md, csp/code-fact-check-report.md, corpus/code-fact-check-report.md}; docs/working/research-2026-11-19-a8-settling-runs.md. Agent reports under csp/ and corpus/ used as evidence only.
**Checked:** 2026-11-19
**Total claims checked:** 30
**Summary:** 20 verified, 3 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable

Execution logs (scratch, this directory): `calc-output.txt` (python3 recomputation of every ledger sum/difference/percentage; command `timeout 30 python3 calc.py`, cwd this directory, exit 0, 2026-11-20T02:18Z), `corpus-diff-size.txt` (`git diff dc6dfb0..2dc403e -- app/ | wc -c` and `--shortstat` in /workspace/external/meta-formalism-copilot, exit 0, 2026-11-20T02:18Z). Hallucination pattern log read (`docs/reviews/hallucination-patterns.md`, 5 patterns); no claim below matches a logged pattern, though Claims 6 and 20 share the log's general "count/attribution asserted without checking the source" shape.

---

## Claim 1: "Both passes use `skills/code-review/SKILL.md` as merged by d383a484 ... The critic and fact-check skill files are byte-identical to the first pass's (no change under those skill dirs since 4330e303)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:15-17`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git ancestry/diff of the seven skill dirs plus `patterns/orchestrated-review.md` and `skills/code-review/`; does not establish that the agents were actually fed those files' bytes.
**Legibility-target:** for-orchestrator-synthesis

`git diff --stat 4330e303 14d450d9 -- skills/code-fact-check skills/security-reviewer skills/performance-reviewer skills/api-consistency-reviewer skills/architecture-review skills/test-strategy skills/tech-debt-triage patterns/orchestrated-review.md` printed nothing; `git diff --stat d383a484 14d450d9 -- skills/code-review/` printed nothing; `git merge-base --is-ancestor d383a484 14d450d9` succeeded (paraphrased — no quote available because the evidence is empty command output, run inline in this session).

**Evidence:** git history of the worktree at 1431b628

---

## Claim 2: "Total 2,171,680 tokens over 19 agents, under the 2.5M stop line"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sum of the ledger rows; does not establish the ledger rows equal the notifications (see Claim 3).
**Legibility-target:** for-orchestrator-synthesis

Ledger `| **Total** | **19** | **2,171,680** (stop line 2.5M not reached) |` (`token-ledger.md:52`); recomputed 898,733 + 1,272,947 = 2,171,680 (`calc-output.txt`, line "call 1272947 total 2171680"). Manifest `"all_agents_tokens": 2171680` agrees.

**Evidence:** `runs/review-arms/a8-2026-11-20/token-ledger.md:50-52`, `manifest.json` totals, `calc-output.txt`

---

## Claim 3: "For all 19 agents it equals the transcript's last API call ... every first call read exactly 18,900 cached tokens"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:20-22`, `:43`; `token-ledger.md:54`
**Type:** Invariant
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only that the claim is stated consistently in results, ledger and manifest; does not establish the equality, which needs the session transcripts (not in the repo).
**Legibility-target:** for-orchestrator-synthesis

The transcripts are not committed (paraphrased — no quote available because the claim covers absence of a file: no transcript or usage dump under `runs/review-arms/a8-2026-11-20/`). Needed: the 19 subagent transcripts' final `usage` blocks.

**Evidence:** `runs/review-arms/a8-2026-11-20/` file listing (`git diff --stat 14d450d9..HEAD`)

---

## Claim 4: csp table: fc +23,675 (+7.6%); 4 critics +6,654 (+1.9%); +4.8% / +0.2% / −3.9% / +6.1%; test-strategy −2.9%; core +27,993 (+3.8%); all agents +46,448

**Location:** `runs/review-arms/a8-2026-11-20/results.md:31-39`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers arithmetic against `token-ledger.md` and `a8-2026-11-19/token-ledger.md`; does not establish the underlying notification values.
**Legibility-target:** for-orchestrator-synthesis

Recomputed: `fc 335650 311975 +23,675 (+7.59%)`, `4crit 358744 352090 +6,654 (+1.89%)`, `sec +4.82% perf +0.17% api -3.90% arch +6.13%`, `ts -2.93%`, `core 771748 +27,993 (+3.76%)`, `all 898733 852285 46448` (`calc-output.txt`). First-pass inputs match `a8-2026-11-19/token-ledger.md:10-21` (e.g. `| 3 | ... r3 | opus | 121,024 |`). Stage 2.5 counts "7 claims" / "6 claims" match the routed-claim counts in the two ledgers (2+3+2 today; 1+3+2 first pass).

**Evidence:** `token-ledger.md:13-25`, `runs/review-arms/a8-2026-11-19/token-ledger.md:10-21`, `calc-output.txt`

---

## Claim 5: "Each self-read agent's first call wrote 31.2k-32.6k tokens to cache, against 32.8k-33.8k inline"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:41-42`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers presence of the figures in the repo; does not establish them (per-call cache_creation figures are only in transcripts).
**Legibility-target:** for-orchestrator-synthesis

No committed record holds per-call cache-creation numbers for either pass (paraphrased — no quote available because the claim covers absence: neither ledger nor manifest carries a cache_creation column).

**Evidence:** `token-ledger.md:11-25`, `runs/review-arms/a8-2026-11-19/token-ledger.md:8-21`

---

## Claim 6: "the inline block's ~2.2k-2.9k left the prompt, as designed"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:42-43`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte sizes of the first pass's and today's csp shared blocks; does not establish per-agent prompt sizes.
**Legibility-target:** for-author

~2.2k/~2.9k are the whole first-pass shared blocks (`a8-2026-11-19/token-ledger.md:5`: "Shared block: `csp/shared-block.md`, 8,755 bytes ≈ 2,189 tokens"; stage 2 11,716 B ≈ 2,929). The self-read prompts still carry a shared block: `wc -c` gives `4576 a8-2026-11-20/csp/shared-block.md` and `8181 a8-2026-11-20/csp/shared-block-stage2.md` (also `manifest.json` `"shared_block_bytes": 4576`, `"shared_block_stage2_bytes": 8181`). What left the prompt is 8,755−4,576 = 4,179 B (≈1.0k tokens) in Stage 1 and 11,716−8,181 = 3,535 B (≈0.9k) in Stage 2 — less than half the stated figure. The results' own cache-write ranges (32.8−31.2 = 1.6k, 33.8−32.6 = 1.2k) fit ~1k, not 2.2-2.9k. Precise version: "the diff and file contents (~1k tokens) left the prompt; the preamble, intent and (Stage 2) fact-check summary stayed".

**Evidence:** `runs/review-arms/a8-2026-11-19/token-ledger.md:5`, `runs/review-arms/a8-2026-11-20/csp/shared-block.md` (4,576 B), `csp/shared-block-stage2.md` (8,181 B), `manifest.json` csp cell

---

## Claim 7: "the first pass's three identical fact-check replicates alone spanned 90k-121k, and today's 104k-122k"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:46-47`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ledger values; does not establish that the spread is the right noise estimate for an 8-agent sum.
**Legibility-target:** for-orchestrator-synthesis

`90,196` / `100,755` / `121,024` (`a8-2026-11-19/token-ledger.md:10-12`); `103,630` / `109,582` / `122,438` (`token-ledger.md:13-15`).

**Evidence:** both ledgers, Stage 1 rows

---

## Claim 8: csp labels 6/6: R1 caught (Claim 10 Incorrect 3/3, api Breaking High, security Low, architecture Coupling, test G7); R2 Claim 11 3/3; A1 Claims 3 and 13, security Medium, api Breaking Medium, architecture Coupling; A2 Claim 7 3/3; A3 Claims 2 and 20 3/3, performance Medium; A4 test G1; security re-found N1

**Location:** `runs/review-arms/a8-2026-11-20/results.md:48-55`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited source existing with the stated verdict/severity and matching the canon row (`canon-issue-ledger.md:92-97`, N1 at `:176`); does not establish that "Breaking High" means severity (it is api Finding 1's confidence; severity is Breaking).
**Legibility-target:** for-orchestrator-synthesis

Merged csp report: `Claim 10 ... **Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect`; `Claim 11 ... r1=Incorrect · r2=Incorrect · r3=Incorrect`; `Claim 7 ... 3/3 Incorrect`; `Claim 2` and `Claim 20` Incorrect 3/3; Claim 3 is `r1=Incorrect · r2=Mostly accurate · r3=Incorrect`, Claim 13 MA 3/3. api: `| 1 | connect-src 'self' breaks graph PNG export ... | Breaking | ... | High |` and `| 2 | Nonce reaches the renderer only through the host's header copy ... | Breaking | ... | Medium |` (`csp/api-consistency-review-2026-11-19.md:208-209`). security: `#### 4. connect-src 'self' blocks fetch(data:)` `**Severity:** Low` (`:112-114`); `#### 1.` Medium (`:31-33`); `#### 3. Matcher sends some HTML documents without CSP: ... prefetch exemption` (`:85`) = N1. architecture `| 1 | ... | Coupling |`, `| 2 | Root CSP silently constrains unrelated client modules ... | Coupling |` (`:192-193`). performance `| 1 | Root layout opt-out removes static prerendering of / ... | Medium |` (`:103`). test-strategy `G1 — proxy.ts:19-31 — buildCsp directive list ... not covered`, `G7 — exportGraph.ts:24,37 — fetch(dataUrl) under connect-src 'self'` (`:18,24`).

**Evidence:** `csp/code-fact-check-report.md:30-173,300-308`; the critic reports cited; `docs/working/canon-issue-ledger.md:92-97,176`

---

## Claim 9: "no replicate ran `next build` this time (the first pass's r3 did). r2 ran vitest (221/221) and eslint ... Rubric: 2 red, 7 amber"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:56-58`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ledger outcome notes, r2 log files and rubric header; does not establish that r1/r3 never attempted a build.
**Legibility-target:** for-orchestrator-synthesis

First pass r3: `(executed: next build/start + curl in its own scratch copy)` (`a8-2026-11-19/token-ledger.md:12`). Today r2: `executed vitest 221/221 + eslint` (`token-ledger.md:15`), logs `csp/r2-logs/csp-r2-vitest.log`, `csp-r2-eslint.log`. Rubric: `Status: 2 red, 7 amber.` (`csp/code-review-rubric-2026-11-19-csp.md:5`).

**Evidence:** both ledgers; `csp/r2-logs/`; csp rubric `:5`

---

## Claim 10: "Range dc6dfb0..2dc403e, scope `-- app/` (15 files, +1166/−33)" and the diff is 53,682 bytes

**Location:** `runs/review-arms/a8-2026-11-20/results.md:62,68`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff's byte count and shortstat in the benchmark repo; does not establish the shared block's other sections.
**Legibility-target:** for-orchestrator-synthesis

`53682` and ` 15 files changed, 1166 insertions(+), 33 deletions(-)` (`corpus-diff-size.txt`).

**Evidence:** `corpus-diff-size.txt`

---

## Claim 11: "Part 5 ... is 123,423 bytes, ≈30.9k tokens at bytes/4, over the 25k budget ... 57,328 bytes (≈14.3k tokens, 57% of budget) in Stage 1 and 61,902 bytes (≈15.5k, 62%) in Stage 2"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:64-69`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the block file sizes, the division, and a reconstruction of part 5 as diff (53,682 B) + post-change contents of the 15 files (69,097 B) = 122,779 B, 644 B short of 123,423 (consistent with section headers); does not establish the exact assembled file, which is not committed.
**Legibility-target:** for-orchestrator-synthesis

`wc -c`: `61902 a8-2026-11-20/corpus/shared-block-stage2.md`, `57328 a8-2026-11-20/corpus/shared-block.md`. Recomputed `14332.0 15475.5 30855.75 0.57328 0.61902` (`calc-output.txt`). Post-change file total `files=69097` from `git show 2dc403e:<f> | wc -c` over the 15 touched files (run inline this session).

**Evidence:** `corpus/shared-block.md`, `corpus/shared-block-stage2.md`, `manifest.json` corpus cell, `calc-output.txt`

---

## Claim 12: "The skill's calibration note ('the largest measured cell was ~17.4k tokens ...', `SKILL.md:343-345`) counts diff + fact-check summary, not diff + enclosing files, which is what the budget is measured on"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:69-72`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the skill text and the lever-3 measurement table; does not establish what any other canon cell's diff + enclosing-file size is.
**Legibility-target:** for-author

`skills/code-review/SKILL.md:343-345`: "Compute after assembling the diff + enclosing-file context (`wc -c` ÷ 4). The number is calibrated to the 2026-08-06 canon: the largest measured cell was ~17.4k tokens, so every measured cell inlines with ~45% headroom". The source table: `| Cell | diff+factcheck chars | prefix tok | ...` / `| corpus (app/) | 69,575 | 17,394 | 6 | 78,273 |` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:36,43`), under "Potential #3 saving IF the shared diff + fact-check report are inlined" (`:33`). So 17.4k is diff + fact-check, and the budget is computed on diff + enclosing files.

**Evidence:** `skills/code-review/SKILL.md:336-345`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:33-46`

---

## Claim 13: corpus table: ×4.64; per-replicate mean 145,201 (+54.5%); 6 critics +33.9%; per-critic +29.7/+26.5/+48.2/+36.4/+39.7/+22.6%; core ×1.84; k=1-equivalent 843,364 (+37.0%); all agents 1,272,947

**Location:** `runs/review-arms/a8-2026-11-20/results.md:75-85`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers arithmetic against today's ledger and the baseline ledger rows; does not establish comparability of k=3 vs k=1 beyond the stated mean.
**Legibility-target:** for-orchestrator-synthesis

Recomputed: `cfc 435604 4.6357...  145201.33 54.525`, `crit 698163 521600 +176,563 (+33.85%)`, per-critic `+29.70% +26.51% +48.22% +36.44% +39.74% +22.63%`, `ccore 1133767 1.8418 615566`, `k1 843364.33 37.006` (`calc-output.txt`). Baseline inputs match `baseline-2026-08-06/token-ledger.md` corpus rows (e.g. `| corpus | security | 94,922 |`, `| corpus | 93,966 | 6 |`).

**Evidence:** `token-ledger.md:31-44`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:15,67-78`, `calc-output.txt`

---

## Claim 14: "The block is ≈14.3k tokens per fact-check agent and ≈15.5k per critic: 135,849 tokens over the 9 core agents, ≈12.0% of the core"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:87-88`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 3×14,332 + 6×15,475.5 and its share of 1,133,767; does not establish that each agent's context held the block once (it was Read as a tool result).
**Legibility-target:** for-orchestrator-synthesis

`block 135852 11.98` using the manifest's rounded 15,476; with 15,475.5 the sum is 135,849 (`calc-output.txt`).

**Evidence:** `calc-output.txt`, `manifest.json` corpus `shared_block_*_tokens_est`

---

## Claim 15: "Each critic grew 19.9k-44.1k over August, so the block is at most a third to three quarters of each critic's growth"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:88-89`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 15,476 ÷ each critic's growth; does not establish how much of the block was new context versus bytes the baseline also read.
**Legibility-target:** for-author

Growth `19931` (test-strategy) to `44114` (api) — matches. Block share per critic: `api 0.351, arch 0.483, td 0.511, sec 0.549, perf 0.703, ts 0.776` (`calc-output.txt`). The upper end is ~78%, above three quarters; precise version: "about a third to four fifths".

**Evidence:** `calc-output.txt`

---

## Claim 16: cor-A1 "**partial**: api F4 flags the field's type (`string` vs `CustomArtifactTypeId`), not its name | miss (ledger: enumeration class)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:102`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers today's api F4 and a grep of the baseline corpus reports for the field; does not establish any other arm's result.
**Legibility-target:** for-author

Today: api name-pattern audit `| customTypeIds: string[] | field | CustomArtifactTypeId | ... | Inconsistent: drops the template-literal id type (F4) |` (`corpus/api-consistency-review-2026-11-19.md:35`) — a type finding, not the naming one, so "partial" holds. Baseline "miss" holds: its corpus critics mention `customTypeIds` only for filtering/coverage (e.g. `critic-test-strategy.md:19` "`fail(\"missing or invalid field: customTypeIds\")` ... not covered"). But the parenthetical cites the wrong column: the ledger row is `| cor-A1 | ... | ✓(label) | ✗ | ✗ (enumeration class) |` (`canon-issue-ledger.md:112`), where "enumeration class" is the E4 column, not the 2026-08-06 baseline. Precise version: "miss (no naming finding in the baseline corpus reports)".

**Evidence:** `docs/working/canon-issue-ledger.md:89-90,112`, `runs/review-arms/baseline-2026-08-06/corpus/*.md`, `corpus/api-consistency-review-2026-11-19.md:35,120-141`

---

## Claim 17: cor-A2, cor-A3, cor-A4 and D3 HIT with the cited sources (Claim 6 3/3, api F10, architecture Minor, TD7; Claims 7, 8 3/3; Claims 3, 4, executed 3/3, api F1, F11; architecture Structural, security, api F9, TD4, test G12)

**Location:** `runs/review-arms/a8-2026-11-20/results.md:103-106`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers source existence and verdicts; "executed 3/3" is read as all three replicates ran the manifest codec (ledger), not as Claim 4 being Incorrect 3/3 (it is I/MA/MA).
**Legibility-target:** for-orchestrator-synthesis

Merged corpus: `Claim 6 ... r1=Incorrect · r2=Incorrect · r3=Incorrect`; Claims 7, 8 `Stale` 3/3; Claim 3 Incorrect 3/3; Claim 4 `r1=Incorrect (compound with Claim 3) · r2=Mostly accurate · r3=Mostly accurate`. api `#### F10. The corpus-backed storage hand-builds a path outside the "only source of corpus paths"`, `F1`, `F9`, `F11` (`corpus/api-consistency-review-2026-11-19.md:46,231,251,268`); architecture `| 1 | Store bypasses seam ... | Structural |` and `| 5 | state/ blob path outside layout module | Minor |` (`:214,218`); security `| 2 | Flag-on rehydrate re-runs migrateFromV2 over corpus state | Low |` (`:293`); TD4, TD7 (`tech-debt-triage-review-2026-11-19.md:293,296`); test `G12` (`test-strategy-review-2026-11-19.md:49`). Canon rows `:113-115`, D3 `:161`.

**Evidence:** `corpus/code-fact-check-report.md:45-129`; critic reports cited

---

## Claim 18: "Under the baseline's own A1-A4 reading (slug collision, bare Error vs CorpusError, stale docstrings, manifest silent drop), all four hit again: security Low #5, api F2, Claims 7/8, Claim 3. The baseline's extra performance-High ... is today's 🟡 A6"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:109-112`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the baseline results row and today's sources; does not establish severity parity.
**Legibility-target:** for-orchestrator-synthesis

Baseline: `A1 slug-collision (security Med), A2 bare-Error/CorpusError (api), A3 stale docstrings (tech-debt), A4 manifest silent-drop (tech-debt) — **all 4 HIT** + a new perf-High (debounce drop)` (`baseline-2026-08-06/results.md:28`). Today: security `| 5 | Lossy slug: distinct titles share a directory | Low |` (`corpus/security-review-2026-11-19.md:295`), api `#### F2. Path builders throw plain Error` (`:76`), rubric `A6 | Corpus setItem has no debounce ...` (`corpus/code-review-rubric-2026-11-19-corpus.md:22`).

**Evidence:** cited lines

---

## Claim 19: "The pass also hit canon N-rows the baseline did not have: N11 ..., N12 ..., N13 ..., N18 ..., N23 (slug collisions), N24 ..., D4 (false 'fresh ArrayBuffer' comment) and D5 (unordered writes)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:112-116`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the baseline corpus reports for N23, D4 and D5; does not establish whether the baseline had N11, N12, N13, N18 or N24 (not checked exhaustively) — today's sightings of all eight are confirmed.
**Legibility-target:** for-author

The baseline had at least two of these. N23: baseline security `#### Slug generation is many-to-one — distinct titles collide to one workspace directory` (`baseline-2026-08-06/corpus/critic-security.md:27`), and the results' own line 110 counts it as the baseline's A1 hit. D4: baseline fact-check `## Claim 8: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."` → Incorrect (`baseline-2026-08-06/corpus/fact-check.md:177,376`; baseline ledger `I = ArrayBuffer comment → 🟡`, `token-ledger.md:15`). D5: the canon calls the baseline-class "drops debouncing and write serialization" a probable match (`canon-issue-ledger.md:163`), and results `:111-112` itself maps the baseline perf-High to today's A6, the D5 seam. Today's sightings exist (security `| 1 | Dev-only flag enforceable in production | Medium |`, `| 3 | ... defaults-over-file after failed hydrate |`, `| 4 | close() in finally masks quota as io |`; test G8 `manifestVersion is never compared`). Also D4/D5 are D-rows, not N-rows. Precise version: drop N23 and D4 (and D5, or mark it as overlapping the baseline's perf-High).

**Evidence:** `runs/review-arms/baseline-2026-08-06/corpus/critic-security.md:27-37`, `.../corpus/fact-check.md:177-190,376`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:15,71`, `docs/working/canon-issue-ledger.md:161-163,196-226`, `corpus/security-review-2026-11-19.md:290-298`

---

## Claim 20: "Rubric: `corpus/code-review-rubric-2026-11-19-corpus.md`, 1 red, 9 amber"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:118`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric header and table rows; does not establish the tiering.
**Legibility-target:** for-orchestrator-synthesis

`Status: 1 red, 9 amber.` (`corpus/code-review-rubric-2026-11-19-corpus.md:5`), rows R1, A1-A9 (`:11-25`).

**Evidence:** corpus rubric `:5-25`

---

## Claim 21: §3 csp sentences: "the control arm gives the net cost ... Self-read cost 3.8% more over the 8 core agents (inside one-draw noise) ... Recall did not move (6/6 both ways, gold R1 caught both ways) ... 'free' holds on net tokens, while the cache saving ... stays at zero"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:123-128`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that each sentence follows from §1, the first pass and its cache probe; does not establish a net-cost estimate beyond one draw per arm, which the paragraph itself flags ("inside one-draw noise"). "neither a saving nor a cost" is supportable only as "no difference detectable at n=1".
**Legibility-target:** for-orchestrator-synthesis

§1 gives `+27,993 (+3.8%)` and 6/6; first pass `6/6 hit` (`a8-2026-11-19/results.md:100`) and the probe's "zero cross-agent" cache read (`cache-probe.md:37`).

**Evidence:** `results.md:31-58`, `runs/review-arms/a8-2026-11-19/results.md:100,135-142`, `cache-probe.md:37`

---

## Claim 22: §3 corpus sentences: "The full material (≈30.9k) was over it, the ladder fell back to diff-only (≈14-15k per agent, 12% of core), and the pass still caught the cell's structural red and 3 of 4 ambers. ... No run has inlined a block between ~15k and 25k ... Its calibration note in the skill describes a different quantity from the one it gates"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:128-133`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with Claims 11, 12, 14, 17 and the A8 run records; "no run" is checked against the A8 passes and the baseline (which self-read) only.
**Legibility-target:** for-orchestrator-synthesis

Follows from Claims 11, 12, 14, 17 above; the largest inlined blocks on record are csp 2.9k (first pass) and corpus 15.5k (today) (`manifest.json` corpus `"shared_block_stage2_tokens_est": 15476`).

**Evidence:** `results.md:64-118`, `manifest.json`

---

## Claim 23: "the merge keeps one row per distinct assertion (csp 24, corpus 25, plus Stage 2.5's 7 and 8 entries)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:143-145`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers harvested and submitted claim counts in the two merged reports and the replicate claim lists; does not establish whether the dropped assertions matter.
**Legibility-target:** for-author

Harvested counts 24 and 25 match (`**Total claims checked:** 24`, `**Total claims checked:** 25`). Stage 2.5 is reversed: csp has 8 entries (Claims 25, 26, 27a, 27b, 28, 29, 30, 31; ledger `8 entries (S3 split)`, `token-ledger.md:24`) and corpus 7 (Claims 26-32; `7 claims`, `:43`). Read in order, "7 and 8" assigns 7 to csp. Also "one row per distinct assertion" is not exact: some distinct Verified replicate assertions have no merged row, e.g. corpus r1 `## Claim 14: "We only ever write Uint8Array"`, `## Claim 22: "CorpusError is the thrown form; CorpusWorkerError is its postMessage-serializable twin"`, r2 `## Claim 21: "Selected once when the store's persist middleware initializes."`.

**Evidence:** `csp/code-fact-check-report.md:8,377-606`, `corpus/code-fact-check-report.md:8,390-645`, `corpus/code-fact-check-report-r1.md`, `-r2.md` claim headings

---

## Claim 24: "Stage 2.5 refuted one endorsement on csp: the performance critic's 'constant work per request' (Claim 27b, executed ...). It went in as 🟢 C6"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:146-147`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merged report and rubric; does not re-run the benchmark.
**Legibility-target:** for-orchestrator-synthesis

`## Claim 27b: "The proxy does a constant amount of work per request ..."` `**Verdict:** Incorrect` (`csp/code-fact-check-report.md:485-490`); rubric `C6 Stage 2.5 Claim 27b: the performance critic's "constant work" endorsement was refuted by execution` (`csp/code-review-rubric-2026-11-19-csp.md:33`). Ledger Stage 2.5 counts `6V (4 executed) / 1MA / 1I` match merged Claims 25-31.

**Evidence:** cited lines; `csp/stage25-logs/s3-cost-bench.log`

---

## Claim 25: csp merged report: Summary "8 verified, 3 mostly accurate, 0 stale, 10 incorrect, 3 unverifiable" and most-severe-wins per cluster; replicate verdict lines

**Location:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md:9,15-368,643-646`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers counts, the severity order, and every replicate-verdict line against the three replicate reports' claim headings/verdicts; compound mappings ("Verified (compound)") were checked for plausibility, not traced sentence by sentence.
**Legibility-target:** for-orchestrator-synthesis

Counts: V = 1,5,8,12,15,17,21,22; MA = 9,13,14; I = 2,3,4,6,7,10,11,18,19,20; U = 16,23,24. Every merged verdict is the most severe of its line (e.g. `Claim 16 ... Unverifiable` over `r1=Unverifiable · r2=Verified · r3=Verified`; `Claim 4 ... Incorrect` over `r1=Verified · r2=Verified · r3=Incorrect (compound with Claim 3)`). Replicate lines match the replicate headings (e.g. r1 `## Claim 7b: "... OpenAlex ..." => Mostly accurate`; r2 `## Claim 16: "style-src keeps 'unsafe-inline' ... Tailwind v4" => Incorrect` for merged Claim 18; r3 `## Claim 12: "Verified prod build ..." => Incorrect`). Stability `16 + 8 = 24` matches.

**Evidence:** `csp/code-fact-check-report.md`; `csp/code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`

---

## Claim 26: csp merged report's "Claims Requiring Attention" (Incorrect: only Claim 27b; Mostly Accurate: only Claim 31)

**Location:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md:624-632`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section's contents against the report's own verdicts; does not establish that a downstream reader used this section.
**Legibility-target:** for-orchestrator-synthesis

The only "Claims Requiring Attention" section is `(Appended by the orchestrator from code-fact-check-submitted-claims.md, Stage 2.5, k=1.)` and lists `Claim 27b` and `Claim 31`. The ten harvested Incorrect (Claims 2, 3, 4, 6, 7, 10, 11, 18, 19, 20), three MA and three Unverifiable claims the header counts are absent; the section is the skill's required summary (`skills/code-fact-check/SKILL.md:457-473`).

**Evidence:** `csp/code-fact-check-report.md:9,624-632`

---

## Claim 27: corpus merged report: Summary "7 verified, 6 mostly accurate, 2 stale, 6 incorrect, 4 unverifiable" and most-severe-wins; replicate verdict lines

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:9,15-384`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers counts and most-severe-wins on every cluster, and replicate lines other than Claim 12's (Claim 28); does not establish that every replicate assertion has a cluster (see Claim 23).
**Legibility-target:** for-orchestrator-synthesis

Counts: I = 1-6; Stale = 7, 8; MA = 9-14; V = 15-21; U = 22-25. Severity order holds (e.g. `Claim 22 ... Unverifiable` over `r1=Unverifiable · r2=Unverifiable · r3=Verified`; `Claim 9 ... Mostly Accurate` over `r1=Mostly accurate · r2=Verified · r3=Mostly accurate`, matching r2 `## Claim 22: Characterization test "locks in" ... => Verified`). Minor format note: merged verdicts are spelled `Mostly Accurate`, while the skill requires exactly `Mostly accurate` (`SKILL.md:419`).

**Evidence:** `corpus/code-fact-check-report.md`; `corpus/code-fact-check-report-r1.md`, `-r2.md`, `-r3.md`

---

## Claim 28: corpus merged Claim 12 'Enabling the flag "starts from an EMPTY corpus"': "**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection", and stability "All reporting replicates agreed: 22 ... Single-replicate detections: Claims 12, 13, 14, 25 ... 22/25 = 88%"

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:188,710-711`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers r1's claim list; the merged verdict (MA) is unaffected by most-severe-wins; does not establish r3 coverage (r3 has no such claim).
**Legibility-target:** for-orchestrator-synthesis

r1 checked the same sentence and Verified it: `## Claim 6c: "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over"` / `**Verdict:** Verified` (`corpus/code-fact-check-report-r1.md:144-148`). So the line should read `r1=Verified · r2=Mostly accurate · r3=—`, Claim 12 is a disagreement, not a single-replicate detection, and the agreement is 21/25 = 84%. The disagreement matters for the R1 red: r1's Verified rests on reading only `storeAdapter.ts` (its Scope: "does not cover what happens to the untouched localStorage blob afterwards").

**Evidence:** `corpus/code-fact-check-report-r1.md:144-156`, `corpus/code-fact-check-report.md:180-189,708-711`

---

## Claim 29: corpus merged report's "Claims Requiring Attention": "### Incorrect - None. ### Stale - None."

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:681-697`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section against the report's own header and verdicts; does not establish downstream use.
**Legibility-target:** for-orchestrator-synthesis

The header says `**Summary:** 7 verified, 6 mostly accurate, 2 stale, 6 incorrect, 4 unverifiable` (`:9`), yet the only attention section — `(Appended by the orchestrator from code-fact-check-submitted-claims.md, Stage 2.5, k=1.)` — says Incorrect "None" and Stale "None" and lists only Claims 27-29. A reader of the summary section is told the report has no Incorrect or Stale claim, while Claims 1-6 are Incorrect and 7-8 Stale.

**Evidence:** `corpus/code-fact-check-report.md:9,681-697`

---

## Claim 30: Research doc precondition: "`git log -1 -- skills/code-review/SKILL.md` at 14d450d9 prints ca328816, a commit on `fix/code-review-lever3-correction`; it is not in the first parent of d383a484 ..., the merge changes SKILL.md (+68/-53), and nothing under `skills/code-review/` changed between d383a484 and 14d450d9. Git's default path simplification never prints a merge commit that is TREESAME to its second parent, so the literal command cannot print the merge hash"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:17-23`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each git fact and the default-mode simplification; does not establish that proceeding met the brief's literal stop rule ("if it is not, end with a blocked marker"), which is a judgment for the owner; also `--first-parent` would print the merge.
**Legibility-target:** for-orchestrator-synthesis

Run inline this session (paraphrased — no quote available because the evidence is git command output): `git log -1 --format='%h %s' 14d450d9 -- skills/code-review/SKILL.md` → `ca328816 docs(code-review): round 3 nit; mark the lever #3 correction brief done`; d383a484's parents are `acbff6c6 e100fc0d`, subject "Merge branch 'fix/code-review-lever3-correction'"; `merge-base --is-ancestor ca328816 d383a484^1` fails, `... ca328816 e100fc0d` succeeds; `git diff --stat d383a484^1 d383a484 -- skills/code-review/SKILL.md` → `68 insertions(+), 53 deletions(-)`, against `^2` empty (TREESAME to the second parent); `d383a484..14d450d9 -- skills/code-review/` empty. `git log -1 --first-parent ...` prints `d383a484`. The branch ref `fix/code-review-lever3-correction` no longer exists; "a commit on" it rests on ancestry of the merge's second parent.

**Evidence:** git history at 1431b628

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`results.md:42-43`): the self-read prompts kept a 4,576 / 8,181-byte shared block, so only ~1.0k / ~0.9k tokens (diff + files) left, not "~2.2k-2.9k".
- **Claim 19** (`results.md:112-116`): N23 (baseline security slug collision) and D4 (baseline fact-check Claim 8, ArrayBuffer comment) were in the baseline; D5 overlaps the baseline perf-High the doc maps to A6. D4/D5 are D-rows.
- **Claim 26** (`csp/code-fact-check-report.md:624-632`): attention section lists only Stage 2.5 claims; the 10 harvested Incorrect, 3 MA and 3 U are missing.
- **Claim 28** (`corpus/code-fact-check-report.md:188,710-711`): Claim 12's r1 is Verified (r1 Claim 6c), not "—"; agreement is 21/25, not 22/25.
- **Claim 29** (`corpus/code-fact-check-report.md:681-697`): attention section says Incorrect/Stale "None" against 6 Incorrect and 2 Stale.

### Mostly Accurate
- **Claim 15** (`results.md:88-89`): block share of critic growth is 35%-78%; "a third to four fifths".
- **Claim 16** (`results.md:102`): baseline "miss" holds, but "enumeration class" is the canon ledger's E4 column, not the baseline.
- **Claim 23** (`results.md:143-145`): Stage 2.5 counts reversed (csp 8, corpus 7); some distinct Verified replicate assertions have no merged row.

### Unverifiable
- **Claim 3** (`results.md:20-22`): needs the 19 transcripts' final usage blocks.
- **Claim 5** (`results.md:41-42`): needs per-call cache_creation figures from transcripts.

---

## Goal-Alignment Note

- **Success criterion:** "A code-fact-check report on the A8 settling write-up, saved to the path given, structured per the code-fact-check skill."
- **Answered:** every number in results.md §1-§2 and the research doc's context block recomputed in python3 (all sums/percentages correct); each label verdict checked against agent reports and canon rows; block sizes and the 17.4k calibration reading verified; both rubrics' Source attributions spot-checked against critic summary tables (all found); merged reports' most-severe-wins verified on every cluster, with one wrong replicate line and two broken attention sections; §3 paragraph checked sentence by sentence (supported, with its own one-draw caveat); research precondition verified by git execution. Brief acceptance criterion 5's components are all present in results.md.
- **Out of scope:** the agent reports' own correctness; whether the A8 conclusion is the right policy call; per-agent transcript figures (Claims 3, 5); whether the baseline also had N11/N12/N13/N18/N24.
- **Escalate:** (1) the research doc proceeded although the brief says to end blocked if `git log -1 --format=%H` is not the merge; the git reasoning is correct, but whether that reading satisfies the brief is the owner's call. (2) Brief status is still `Status: open` (`docs/working/briefs/2026-11-19-a8-settling-runs.md:3`); criterion 7 wants it flipped in the merging change, so this is not a defect yet.
