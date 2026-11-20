Commit: 1431b628

# Code Fact-Check Report

**Repository:** /workspace/.worktrees/wt-2026-11-19-a8-settling-runs (branch measure/a8-settling-runs)
**Scope:** orchestrator-written files since 14d450d9: runs/review-arms/a8-2026-11-20/{results.md, token-ledger.md, manifest.json, csp/code-review-rubric-2026-11-19-csp.md, corpus/code-review-rubric-2026-11-19-corpus.md, csp/code-fact-check-report.md, corpus/code-fact-check-report.md}, docs/working/research-2026-11-19-a8-settling-runs.md
**Checked:** 2026-11-20
**Total claims checked:** 31 (30 numbered; Claim 26 split into 26a/26b)
**Summary:** 19 verified, 6 mostly accurate, 0 stale, 6 incorrect, 0 unverifiable

Replicate r2 of a k=3 fact-check. Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here asserts a fabricated symbol. Claim 29 (a miscounted tally in a ledger outcome cell) is close to the logged count-claim patterns (e.g. "mode1-equiv 33 claimed in commit 37c5ea9's test tally but the file holds 25"). The log was not updated: this pass has read-only scope.

Execution logs (scratch, beside this report): `logs/calc.log` (all arithmetic), `logs/git-precondition.log`, `logs/corpus-sizes.log`, `logs/transcripts.log` (per-subagent first/last API usage from `/home/node/.claude/projects/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/subagents/*.jsonl`). All logs were run 2026-11-20T02:20Z with exit 0. The cwd and command are recorded in each log's header.

---

## Claim 1: "`git log -1 -- skills/code-review/SKILL.md` at 14d450d9 prints ca328816, a commit on `fix/code-review-lever3-correction`; it is not in the first parent of d383a484 … the merge changes SKILL.md (+68/-53), and nothing under `skills/code-review/` changed between d383a484 and 14d450d9. Git's default path simplification never prints a merge commit that is TREESAME to its second parent"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:18-23`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each git fact in the sentence. It does not establish that proceeding met the brief's stop condition (see Claim 2).

Executed (cwd the worktree, `logs/git-precondition.log`): `git log -1 14d450d9 -- skills/code-review/SKILL.md` prints `ca328816 docs(code-review): round 3 nit; mark the lever #3 correction brief done`. `merge-base --is-ancestor ca328816 d383a484^1` returns rc=1, and against `d383a484^2` it returns rc=0. `d383a484^2` is `e100fc0d`, whose parent is ca328816. `git diff --stat d383a484^1 d383a484 -- skills/code-review/SKILL.md` gives "68 insertions(+), 53 deletions(-)". `git diff --quiet d383a484^2 d383a484 -- SKILL.md` gives rc=0, so the merge is TREESAME to its second parent. `git diff --stat d383a484 14d450d9 -- skills/code-review/` is empty. Under default history simplification git follows a TREESAME parent and drops the merge, so the literal command cannot print d383a484 (paraphrased — no quote available because this is git's documented simplification behavior, confirmed by the observed output rather than by a source file). The branch `fix/code-review-lever3-correction` no longer exists locally (`git branch -a --list '*lever3-correction*'` is empty). "a commit on" is historical, and d383a484's subject names that branch.

**Evidence:** `logs/git-precondition.log`; `docs/working/research-2026-11-19-a8-settling-runs.md:18-23`

---

## Claim 2: "The brief asks that `skills/code-review/SKILL.md` on the base commit be the version merged under Q-315"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:17-18`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers what the brief's Motive asks. It does not judge whether the reinterpretation is acceptable; that is escalated.

The brief at 14d450d9 asks for a literal command check with a stop condition: "check that `git log -1 --format=%H -- skills/code-review/SKILL.md` on your base commit is that merge, and if it is not, end with a blocked marker saying so" (`git show 14d450d9:docs/working/briefs/2026-11-19-a8-settling-runs.md`, Motive). The research doc restates this as a check on the file's content ("be the version merged"). That content condition holds (Claim 1). But the literal check fails, and the restatement drops the stop condition. A precise version would say: "The brief's literal check (command output equals the merge) fails, because git cannot print a TREESAME merge. I read it as a content check and proceeded."

**Evidence:** brief at `14d450d9:docs/working/briefs/2026-11-19-a8-settling-runs.md` (Motive); `docs/working/research-2026-11-19-a8-settling-runs.md:17-23`

---

## Claim 3: csp first-pass figures ("core 743,755 … fc 311,975 = 100,755 / 90,196 / 121,024; critics 431,780 … Stage 2.5 108,530, all 852,285; 6/6 … 8,755 B / 11,716 B") and corpus baseline figures ("fc 93,966 + 6 critics … = 615,566 core")

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:27-36`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers each number against the comparator ledgers and manifests. It does not re-derive the comparators' own figures from their transcripts.

`runs/review-arms/a8-2026-11-19/manifest.json:24-36` gives `"fc_r1": 100755, "fc_r2": 90196, "fc_r3": 121024, "stage1_total": 311975 … "stage2_total": 431780, "stage2_5_submitted_claims": 108530, "core_total": 743755, "total_tokens": 852285`, with `"shared_block_bytes": 8755` (`:13`) and `"shared_block_stage2_bytes": 11716` (`:41`). The baseline ledger has `| corpus | 93,966 |` (`runs/review-arms/baseline-2026-08-06/token-ledger.md:15`), and the six corpus critic rows are at `:67,71,73,75,76,78`. `logs/calc.log` sums them: 93,966 + 521,600 = 615,566.

**Evidence:** `runs/review-arms/a8-2026-11-19/manifest.json:13-41`; `runs/review-arms/baseline-2026-08-06/token-ledger.md:15,67-78`; `logs/calc.log`

---

## Claim 4: "Critic and fact-check skill files are unchanged between the first pass's base (4330e303) and 14d450d9 (`git diff --stat` over the seven skill dirs and `patterns/orchestrated-review.md` is empty)"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:37-39` (also `results.md:16-17`, `manifest.json:4`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the seven critic/fact-check skill dirs and the pattern file. It does not cover `skills/code-review/` or `skills/dev-cycle/`, which did change (the first is intended).

The diff over those paths is empty (`logs/git-precondition.log`). Over all of `skills/` it touches only `skills/code-review/SKILL.md` and `skills/dev-cycle/SKILL.md` (paraphrased — no quote available because the claim covers absence of changes: an empty diff).

**Evidence:** `logs/git-precondition.log`

---

## Claim 5: "part 5 (diff + the 15 touched files) is 123,423 bytes, about 30.9k tokens … the block is preamble + scope label + intent + the 53,682-byte diff, 57,328 bytes in all (about 14.3k tokens). Pasting that into 10 Agent prompts by hand would cost me about 143k output tokens"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:73-77` (same figures at `results.md:64-68`, `manifest.json:55-60`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the diff bytes, the block files' bytes, the block's section structure and the chars/4 arithmetic. It does not establish the 123,423 total byte for byte: diff plus raw file contents is 122,779, and the remaining 644 bytes are consistent with per-file headers that the assembled part-5 file (not committed) would carry.

Executed (`logs/corpus-sizes.log`): `git diff dc6dfb0..2dc403e -- app/ | wc -c` gives 53682, and `--shortstat` gives "15 files changed, 1166 insertions(+), 33 deletions(-)". Post-change contents of the 15 files total 69,097 bytes. `wc -c` gives `corpus/shared-block.md` 57,328, `shared-block-stage2.md` 61,902 and `part6.md` 4,574 (61,902 − 57,328 = 4,574). The block's headings are the preamble at `corpus/shared-block.md:1`, "## What this PR is trying to accomplish" at `:13` and "## The diff (git diff dc6dfb0..2dc403e -- app/)" at `:19`, with the partial-scope label at `:11`. `logs/calc.log` gives 123,423/4 = 30,855.75, 57,328/4 = 14,332 (57.3% of 25k) and 61,902/4 = 15,475.5 (61.9%). 10 × 14,332 = 143,320.

**Evidence:** `logs/corpus-sizes.log`; `logs/calc.log`; `runs/review-arms/a8-2026-11-20/corpus/shared-block.md:1-19`

---

## Claim 6: "three of the five calls were refused by a harness working-directory check and were re-sent a minute later"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:85-87` (also `results.md:140-142`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers dispatch timing from the transcripts. It does not establish the refusal's cause (a harness message not in the subagent transcripts).

Transcript first-message timestamps (`logs/transcripts.log`): architecture and test-strategy started at `2026-11-20T01:29:16`, and security, performance and api-consistency at `01:30:50`, about 94 s later ("about a minute" is loose but fine).

**Evidence:** `logs/transcripts.log`

---

## Claim 7: "The first A8 pass merged the same way: 4,092 lines by this count, approved by the owner."

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:96-97`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the non-`docs/` line count of merge 358c2332. "Approved by the owner" rests on the merge subject "(build-loop approved merge)" and the A8 rubric row's "merge approved Q-306", not on a record of the owner's answer.

`git diff --numstat 358c2332^1 358c2332`, excluding `docs/`, gives `non-docs lines 4092` (`logs/git-precondition.log`). The rubric row reads "merge approved Q-306" (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`).

**Evidence:** `logs/git-precondition.log`; `docs/reviews/code-review-rubric-2026-08-07-main.md:35`

---

## Claim 8: "Merged by the orchestrator from … (33 claims), -r2.md (35) and -r3.md (22) … this merge keeps one row per distinct assertion"

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:13` (repeated in `results.md:143-145`, see Claim 26a)
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers whether every replicate assertion has a merged row. The replicate counts (33/35/22) are right (`code-fact-check-report-r1.md:8`, `-r2.md:8`, `-r3.md:8`). Every omitted assertion is a Verified one, so no Incorrect/Stale/MA finding was lost.

Several single-replicate assertions have no merged row. They are r1 Claim 14 `"We only ever write Uint8Array"` (`corpus/code-fact-check-report-r1.md:365`, `opfsAdapter.ts:25-29`, Verified), r1 Claim 22 `"CorpusError is the thrown form; CorpusWorkerError is its postMessage-serializable twin"` (`:501-503`, `types.ts:27-30`, Verified), r1 Claim 23 `"'Not found' is null from readFile/stat and [] from readdir …"` (`:517-519`, `types.ts:18-19,110-125`, Verified), and r2 Claim 21 `"Selected once when the store's persist middleware initializes."` (`-r2.md`, `storeAdapter.ts:70`, Verified). No merged `**Location:**` line cites `types.ts` or `opfsAdapter.ts:25-29` (merged report `:17-377`). Single-replicate MA/U assertions were kept as rows (Claims 12-14, 25 at `:188,203,218,383`). So the merge drops single-replicate Verified assertions; it does not keep one row per distinct assertion. This understates the merged Verified count (7 at `:9`) and feeds the agreement rate (Claim 10).

**Evidence:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:9,13,17-377`; `corpus/code-fact-check-report-r1.md:365,501-519`; `corpus/code-fact-check-report-r2.md` (Claim 21)

---

## Claim 9: Claim 12 `**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection`

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:188`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the r1 entry of this replicate line. The merged verdict (Mostly accurate) is still right under most-severe-wins.

r1 verdicted the same sentence: `## Claim 6c: "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over"` … `**Verdict:** Verified` (`corpus/code-fact-check-report-r1.md:144-148`). The line should read `r1=Verified · r2=Mostly accurate · r3=—`. It is a two-replicate disagreement, not a single-replicate detection.

**Evidence:** `corpus/code-fact-check-report-r1.md:144-156`; `corpus/code-fact-check-report-r2.md` Claim 6

---

## Claim 10: "All reporting replicates agreed: 22. Disagreed: 3 — Claim 4 …, 9 …, 22 …. Single-replicate detections: Claims 12, 13, 14, 25 (all r2). Agreement rate: 22/25 = 88%."

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:710-711`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the stability tally given the replicate lines as corrected in Claim 9. It does not re-define agreement. The report counts single-replicate rows as "agreed"; that convention is kept here.

With Claim 12 at r1=Verified / r2=Mostly accurate (Claim 9), the disagreements are Claims 4, 9, 12 and 22. Agreement is at most 21/25 = 84%, and the single-replicate detections are Claims 13, 14 and 25. The four omitted Verified rows (Claim 8) would change the denominator again. The other 24 replicate lines map correctly onto the replicate reports (checked row by row, e.g. Claim 4 `r1=Incorrect (compound with Claim 3)` against r1 Claim 7 executed Incorrect, and r2 8a / r3 4a Mostly accurate).

**Evidence:** `corpus/code-fact-check-report.md:68,143,188,338,710-711`; replicate reports r1/r2/r3 (per-claim verdict lines)

---

## Claim 11: Corpus merged header "Total claims checked: 25 / Summary: 7 verified, 6 mostly accurate, 2 stale, 6 incorrect, 4 unverifiable", and verdicts follow most-severe-wins over the replicate lines

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:8-9`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the count against the 25 harvested rows and most-severe-wins on each row's stated replicate verdicts. It does not cover coverage of the replicates (Claim 8) or Stage 2.5 rows 26-32 (reported separately, not in the 25).

Rows 1-6 are Incorrect, 7-8 Stale, 9-14 Mostly Accurate, 15-21 Verified and 22-25 Unverifiable (`:19-379`). Each row's verdict is the most severe of its replicate line. For example, Claim 22 (`r1=Unverifiable · r2=Unverifiable · r3=Verified`, `:338`) is Unverifiable, which is correct, since Unverifiable outranks Verified.

**Evidence:** `corpus/code-fact-check-report.md:8-9,19-383`

---

## Claim 12: corpus rubric A2 source "fact-check Claims 3, 4 (executed 3/3)" (and `results.md:105` "Claims 3, 4, executed 3/3")

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-review-rubric-2026-11-19-corpus.md:18`; `runs/review-arms/a8-2026-11-20/results.md:105`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the replicate verdicts and modes for merged Claims 3 and 4. It does not challenge the other A2 sources (api F1, F11; architecture Minor #6; TD2; G7, G8), which all exist.

Merged Claim 3 (FAIL-LOUD) was executed and Incorrect in all three replicates: r1 Claim 7, r2 Claim 8b and r3 Claim 4b are each `Incorrect | executed`. Merged Claim 4 (error kinds) is `r1=Incorrect (compound with Claim 3) · r2=Mostly accurate · r3=Mostly accurate` (`corpus/code-fact-check-report.md:68`), and r3's Claim 4a is `Mostly accurate | static`. "3/3" holds for Claim 3 only. A precise version: "Claim 3 (Incorrect, executed 3/3); Claim 4 (I/MA/MA)".

**Evidence:** `corpus/code-fact-check-report.md:53,68`; replicate reports' verdict and verification-mode lines (r1 Claim 7, r2 Claims 8a/8b, r3 Claims 4a/4b)

---

## Claim 13: corpus rubric row Source attributions (R1, A1, A3-A9, C1-C7, Confirmed Good)

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-review-rubric-2026-11-19-corpus.md:11-41`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each cited finding exists at the cited number and severity. Security "Low #n" follows that report's Summary Table numbering (`security-review-2026-11-19.md:292-298`), not its heading order. The rubric does not say which numbering it uses.

Architecture: `#### 1. … Structural`, `2. … Coupling`, `3. … Coupling`, `4./5./6. … Minor` (`corpus/architecture-review-2026-11-19.md:23-160`). Security table: `| 2 | Flag-on rehydrate re-runs migrateFromV2 … | Low`, `| 3 | Unhandled write rejections …| Low`, `| 4 | close() in finally masks quota as io | Low`, `| 5 | Lossy slug … | Low` (`:293-296`). Performance: `| 1 | … no debounce … | Medium`, `| 2 | Quota … | Low`, `| 3 | Per-op getDirectory() … | Informational` (`performance-review-2026-11-19.md:108-110`). API F1-F12 are at `api-consistency-review-2026-11-19.md:319-330` (F8 Inconsistent, F10 Minor). TD1-TD7 are at `tech-debt-triage-review-2026-11-19.md:290-296`. G1, G3, G6-G8 and G12 are at `test-strategy-review-2026-11-19.md:22-49`. "200,019 inputs" matches `S5 fuzz inputs: 200019 x2 fns; violations: 0` (`corpus/stage25-logs/s2-s5-s7.log:6`). Stage 2.5 "7 routed claims" matches the submitted report's `**Total claims checked:** 7` (`corpus/code-fact-check-submitted-claims.md:8`).

**Evidence:** files and lines above

---

## Claim 14: csp merged report header "24 … 8 verified, 3 mostly accurate, 0 stale, 10 incorrect, 3 unverifiable", replicate verdict lines, most-severe-wins and "Agreement rate: 16/24 = 67%"

**Location:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md:8-9,23-368,645-646`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers all 24 replicate lines against the three replicate reports (every replicate claim maps to a merged row), the header counts and the stability tally. It does not re-verdict the underlying code claims.

Each replicate claim maps to a row with the stated verdict. Examples: Claim 16 `r1=Unverifiable · r2=Verified · r3=Verified (compound)`, where r2 Claim 12 quotes the `warnOnce(… file convention is deprecated …)` text and r3 Claim 1's scope includes "middleware.ts builds with a deprecation warning". Most-severe-wins gives Unverifiable (`:244`). Claim 4 is `r3=Incorrect (compound with Claim 3)`, and r3 Claim 10's quote is "…so we don't need to read x-nonce here ourselves" with `**Verdict:** Incorrect` (`csp/code-fact-check-report-r3.md:221-225`). Counts are V {1,5,8,12,15,17,21,22} = 8, MA {9,13,14} = 3, I {2,3,4,6,7,10,11,18,19,20} = 10 and U {16,23,24} = 3. Disagreements are {3,4,6,9,14,16,19,23} = 8, so 16/24 = 66.7%.

**Evidence:** `csp/code-fact-check-report.md`; `csp/code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (verdict lines)

---

## Claim 15: csp rubric "2 red, 7 amber … Stage 2.5 on 7 routed claims" and row Source attributions

**Location:** `runs/review-arms/a8-2026-11-20/csp/code-review-rubric-2026-11-19-csp.md:5-40`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each cited source exists at the cited number and severity. C6's "about 15 µs at 21 headers" is the dominant `NextResponse.next` step, not the per-request total (about 18.7 µs). Header-count growth is the fact-check's inference from a single 21-header measurement.

R1 and R2 cite `| 1 | connect-src 'self' breaks graph PNG export … | Breaking | … | High |` and `| 2 | Nonce reaches the renderer only through the host's header copy … | Breaking | … | Medium |` (`csp/api-consistency-review-2026-11-19.md:208-209`). Security `| 4 | connect-src 'self' breaks fetch(data:) … | Low` (`csp/security-review-2026-11-19.md:255`) and `| 1 | … | Medium` (`:252`). Architecture `| 1 | … | Coupling`, `| 2 | … | Coupling`, `| 3/4/5 | … | Minor`, `| 6 | … | Informational` (`csp/architecture-review-2026-11-19.md:192-197`). Test G3, G6 and G7 are at `csp/test-strategy-review-2026-11-19.md:20-24`. The 7 routed claims are perf 2 + api 3 + security 2 (`token-ledger.md:19-21`). Probe logs: `"N": 20000, "unique": 20000` (`csp/stage25-logs/s1-nonce-probe.log`) and `NextResponse.next({request:{headers}}) 15251 ns/op` at "request header count: 21" (`csp/stage25-logs/s3-cost-bench.log`).

**Evidence:** files and lines above

---

## Claim 16: manifest.json token figures, block sizes and totals

**Location:** `runs/review-arms/a8-2026-11-20/manifest.json:15-16,27-46,55-61,71-105`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers agreement with the ledger, the transcripts and the block files. Its `labels_hit` strings are covered under Claims 19 and 23.

`logs/calc.log` reproduces every subtotal (335,650, 436,098, 771,748, 898,733, 435,604, 698,163, 1,133,767, 1,272,947, 2,171,680). `wc -c` gives `csp/shared-block.md` 4,576 and `csp/shared-block-stage2.md` 8,181 (`logs/corpus-sizes.log` run; same `wc` call). The 19 transcript last-call totals equal the per-agent figures (`logs/transcripts.log`).

**Evidence:** `logs/calc.log`; `logs/transcripts.log`; `logs/corpus-sizes.log`

---

## Claim 17: "Total 2,171,680 tokens over 19 agents … For all 19 agents it equals the transcript's last API call (input + cache creation + cache read + output)" and "Every agent in both arms read 18,900 cached tokens on its first call"; "Each self-read agent's first call wrote 31.2k-32.6k tokens to cache, against 32.8k-33.8k inline"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:19-22,41-43` (also `token-ledger.md:54`, `manifest.json:108`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers this session's 19 subagent transcripts. The inline arm's 32.8k-33.8k rests on the first pass's own record (`runs/review-arms/a8-2026-11-19/results.md:66-67`), not on its transcripts.

`logs/transcripts.log` lists the 19 agents whose last-call totals equal the ledger rows (e.g. `agent-a365f5d5c2a1ca 31153 18900 103630`). Every first call has `cache_read` 18900. The csp self-read first-call `cache_creation` values run from 31,153 to 32,645. The first pass recorded "wrote 32.8k-33.8k fresh, shared block included" (`a8-2026-11-19/results.md:66-67`). Pass 1 agents started 01:19-01:36Z and pass 2 agents 01:46-02:00Z, so the passes ran one after the other.

**Evidence:** `logs/transcripts.log`; `runs/review-arms/a8-2026-11-19/results.md:66-67`

---

## Claim 18: csp table: "+23,675 (+7.6%)", "358,744 | 352,090 | +6,654 (+1.9%)", "+4.8% / +0.2% / −3.9% / +6.1%", "−2.9%", "771,748 … 743,755 … +27,993 (+3.8%)", "898,733 | 852,285 | +46,448"; noise ranges "90k-121k, and today's 104k-122k"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:31-39,45-47`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the arithmetic and inputs. It does not establish the "inside the noise of one draw" judgment statistically. It is an informal range comparison (stated as such).

`logs/calc.log`: fc +23,675 (+7.59%), 4 critics +6,654 (+1.89%), sec +4.82%, perf +0.17%, api −3.90%, arch +6.13%, ts −2.93%, core +27,993 (+3.76%), all +46,448. The "(7 claims)/(6 claims)" Stage 2.5 counts match `csp/code-fact-check-submitted-claims.md:8` "8 (7 submitted; S3 split …)" and `a8-2026-11-19/csp/code-fact-check-submitted-claims.md:8` "7 (6 submitted; …)".

**Evidence:** `logs/calc.log`; ledgers cited above

---

## Claim 19: csp labels: "6/6 … R1 … caught: fact-check Claim 10 Incorrect 3/3, api-consistency Breaking High (so 🔴), security Low, architecture Coupling, test-strategy G7. R2 … Claim 11 3/3; A1 … Claims 3 and 13, security Medium, api Breaking Medium, architecture Coupling; A2 … Claim 7 3/3; A3 … Claims 2 and 20 3/3, performance Medium; A4 … test G1. … security re-found canon N1"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:48-55`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers each cited agent finding against the canon labels at `canon-issue-ledger.md:92-97` and N1 at `:176`. "Breaking High/Medium" pairs severity with *confidence* (the api table's last column), which the sentence does not say.

The merged csp report gives Claim 10 `r1=Incorrect · r2=Incorrect · r3=Incorrect` (`csp/code-fact-check-report.md:158`), with Claims 11, 7, 2 and 20 Incorrect 3/3 (`:173,113,38,308`) and Claim 13 MA 3/3 (`:203`). Canon: "csp-A3 | `layout.tsx:27-30` comment misstates why `await headers()` is needed" (`docs/working/canon-issue-ledger.md:96`). Security finding 3 covers "`purpose: prefetch` … document has no CSP" (`csp/security-review-2026-11-19.md:202`), and canon N1 reads "middleware prefetch-skip serves real HTML with no CSP" (`canon-issue-ledger.md:176`). Test G1/G7 are at `csp/test-strategy-review-2026-11-19.md:18,24`.

**Evidence:** files and lines above

---

## Claim 20: "Stage 2.5 ran 4 claims on `next dev` and probes"; "r2 ran vitest (221/221) and eslint"; "no replicate ran `next build` this time (the first pass's r3 did)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:56-58`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the execution modes recorded in the Stage 2.5 and replicate reports. It does not re-run them.

Five Stage 2.5 entries are `**Verification mode:** executed`: Claims 25, 27b, 28, 29 and 31 (`csp/code-fact-check-submitted-claims.md`). They ran as four runs (s1, s3, s4 shared by Claims 28 and 29, s7). Claim 29's evidence says "Executed: same run as Claim 28". So "4 runs" or "5 claims" would be precise, and "4 claims" is not. The vitest log has `Tests  221 passed (221)` (`csp/r2-logs/csp-r2-vitest.log:35`), and the eslint log has `exit=0`. All three replicates' verdicts on "Verified prod build…" are U/U/I with no build run. The first pass's r3 was "executed: next build/start + curl" (`a8-2026-11-19/token-ledger.md:12`).

**Evidence:** `csp/code-fact-check-submitted-claims.md` (Claims 25-31 mode lines); `csp/r2-logs/`; `runs/review-arms/a8-2026-11-19/token-ledger.md:12`

---

## Claim 21: "The skill's calibration note ('the largest measured cell was ~17.4k tokens, so every measured cell inlines with ~45% headroom', `SKILL.md:343-345`) counts diff + fact-check summary, not diff + enclosing files, which is what the budget is measured on, so on its own measure corpus does not inline." Also "This is the first cell measured above the budget."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:69-72`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the 17.4k figure counts and what the budget gates. The quoted text is at `SKILL.md:344-345` (`:343` is the line before), within the cited range. It does not test the skill's own "~45% headroom" arithmetic, which is the skill's claim (25k − 17.4k is 30% of the budget, or 44% above the cell).

The skill says "the largest measured cell was ~17.4k tokens, so every measured cell inlines with ~45% headroom" (`skills/code-review/SKILL.md:344-345`). The budget is computed "after assembling the diff + enclosing-file context" (`:343`). The source table's column is `| Cell | diff+factcheck chars | prefix tok |`, with row `| corpus (app/) | 69,575 | 17,394 |` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:37,43`). So 17.4k is diff plus fact-check report, a different quantity. On the gated quantity corpus is 30.9k (Claim 5). "First cell measured above the budget" holds for the cells with recorded part-5 measurements (csp 8,755 B first pass, corpus now).

**Evidence:** `skills/code-review/SKILL.md:342-352`; `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:34-46`

---

## Claim 22: corpus table: "×4.64", "145,201 … +54.5%", "698,163 | 521,600 | +33.9%", "+29.7% / +26.5% / +48.2% / +36.4%", "+39.7% / +22.6%", "×1.84", "843,364 | 615,566 | +37.0%"; "135,849 tokens over the 9 core agents, ≈12.0% of the core"; "Each critic grew 19.9k-44.1k over August"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:75-89`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the arithmetic. 135,849 is bytes/4 over the 9 agents (3×57,328 + 6×61,902)/4. Summing the rounded token estimates gives 135,852.

`logs/calc.log`: 435,604/93,966 = 4.636, mean 145,201.3 (+54.53%), critics +33.85%, per-critic +29.70/+26.51/+48.22/+36.44/+39.74/+22.63%, 1,133,767/615,566 = 1.842, k=1-equivalent 843,364.3 (+37.01%), block 135,849 = 11.98% of core, critic growth 19,931-44,114.

**Evidence:** `logs/calc.log`

---

## Claim 23: "so the block is at most a third to three quarters of each critic's growth"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:89-90`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers the ratio of the Stage 2 block (15,476) to each critic's growth over the baseline.

`logs/calc.log`: 15,476 divided by each critic's growth is api 0.35, arch 0.48, td 0.51, sec 0.55, perf 0.70 and test-strategy 0.78. The upper end is about four fifths, not three quarters. A precise version: "about a third to four fifths".

**Evidence:** `logs/calc.log`

---

## Claim 24: corpus label table rows (cor-A1 "partial: api F4 flags the field's type …, not its name"; cor-A2/A3/A4 and D3 HIT with listed sources) and canon citations `:112-115`, `:161`

**Location:** `runs/review-arms/a8-2026-11-20/results.md:97-106` (Today column)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the Today column against the agent reports and the canon rows (cor-A4's "3/3" nuance is Claim 12). The Baseline column is Claim 25.

Canon: `| cor-A1 | customTypeIds→customArtifactTypeIds naming inconsistency` (`canon-issue-ledger.md:112`), through `| cor-A4 | Manifest codec docstring drift …` (`:115`), and `| D3 | Rehydration seam bypass …` (`:161`). Today's API row reads `| customTypeIds: string[] | field | CustomArtifactTypeId | … | Inconsistent: drops the template-literal id type (F4) |` (`corpus/api-consistency-review-2026-11-19.md:35`), which is about type, not name, so partial is right. Merged Claim 6 is I 3/3 (`corpus/code-fact-check-report.md:98`), Claims 7 and 8 are Stale 3/3 (`:113,128`), and architecture `#### 1. … Severity: Structural` is at `corpus/architecture-review-2026-11-19.md:23-25`.

**Evidence:** files and lines above

---

## Claim 25: Baseline column: cor-A1 "miss (ledger: enumeration class)"; cor-A2 "reported HIT (baseline results used a different A1-A4 reading)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:102-103`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers what the baseline's reports show for the canon cor-A1/cor-A2 readings. The baseline's own A-label reading is covered at `results.md:108-111` (accurate).

cor-A1: the baseline missed it. No baseline corpus report mentions `customArtifactTypeIds` (paraphrased — no quote available because the claim covers absence: zero grep hits in `runs/review-arms/baseline-2026-08-06/corpus/*.md`). But "(enumeration class)" is the ledger's E4-arm column (`canon-issue-ledger.md:112`, "✗ (enumeration class)"), not a baseline record. cor-A2: under the canon reading the baseline also missed it. Its architecture critic endorsed the opposite: "**Path safety is well-bounded:** `paths.ts` is the sole producer of corpus paths" (`baseline-2026-08-06/corpus/critic-architecture.md:81`). The baseline's own "A2" was "bare-Error/CorpusError (api)" (`baseline-2026-08-06/results.md:28`). The parenthetical discloses the different reading, but a reader comparing columns sees HIT/HIT on cor-A2, while the evidence gives HIT/miss. A precise cell would read "miss on the canon reading (baseline architecture called paths.ts the sole path producer); its own A2 was a different issue".

**Evidence:** `runs/review-arms/baseline-2026-08-06/corpus/critic-architecture.md:81`; `runs/review-arms/baseline-2026-08-06/results.md:28`; `docs/working/canon-issue-ledger.md:112-113`

---

## Claim 26a: "The merged fact-check reports are cluster-level … the merge keeps one row per distinct assertion (csp 24, corpus 25 …)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:143-145`
**Type:** Architectural
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** True for csp (every replicate claim maps, Claim 14). False for corpus (Claim 8).

The corpus merge omits r1 Claims 14, 22 and 23 and r2 Claim 21, all Verified single-replicate assertions (see Claim 8 for quotes and lines). A precise version: "csp keeps one row per distinct assertion; the corpus merge drops four single-replicate Verified assertions".

**Evidence:** `corpus/code-fact-check-report-r1.md:365,501-519`; `corpus/code-fact-check-report.md:17-377`

## Claim 26b: "… plus Stage 2.5's 7 and 8 entries"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:145`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the order of the two counts against "csp 24, corpus 25" in the same parenthesis.

csp Stage 2.5 has 8 entries: `**Total claims checked:** 8 (7 submitted; S3 split into 27a/27b)` (`csp/code-fact-check-submitted-claims.md:8`). Corpus has 7: `**Total claims checked:** 7` (`corpus/code-fact-check-submitted-claims.md:8`). Read in order, the parenthesis gives csp 7 and corpus 8, which is swapped. It should read "8 and 7".

**Evidence:** `csp/code-fact-check-submitted-claims.md:8`; `corpus/code-fact-check-submitted-claims.md:8`

---

## Claim 27: "The pass also hit canon N-rows the baseline did not have: N11 …, N12 …, N13 …, N18 …, N23 (slug collisions), N24 …, D4 (false 'fresh ArrayBuffer' comment) and D5 (unordered writes)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:112-116`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers N23, D4 and D5 against the baseline corpus reports. For N11, N12, N13, N18 and N24, a grep of the baseline reports (`NODE_ENV|in production|unhandled|close()|finally|MANIFEST_VERSION`) found no matching finding. That supports "baseline did not have" for those five, narrowly, without a full read of every baseline report.

The baseline had three of the listed rows. N23: the baseline's security Medium was "workspaceSlug many-to-one → title collisions" (`baseline-2026-08-06/token-ledger.md:73`). `results.md:110` itself credits "security Low #5" with re-hitting the baseline's "slug collision". D4: the baseline fact-check gave "I = ArrayBuffer comment" (`baseline-2026-08-06/token-ledger.md:15`), and its security critic writes "the comment says 'Pass a fresh ArrayBuffer view' but `await w.write(bytes)` passes the untouched parameter" (`baseline-2026-08-06/corpus/critic-security.md:59`). D5: the baseline performance critic found a full-blob write per change "with no ordering guarantee (contention / possible last-writer-wins races)" (`baseline-2026-08-06/corpus/critic-performance.md:55`). That is the same seam `results.md:111-112` already maps to today's A6. Precise version: drop N23, D4 and D5 from the "baseline did not have" list.

**Evidence:** `runs/review-arms/baseline-2026-08-06/token-ledger.md:15,73`; `runs/review-arms/baseline-2026-08-06/corpus/critic-security.md:59`; `runs/review-arms/baseline-2026-08-06/corpus/critic-performance.md:55`; `runs/review-arms/a8-2026-11-20/results.md:110`

---

## Claim 28: The A8 paragraph: csp net cost ("dropping the inline block saved nothing … 3.8% more … inside one-draw noise … Recall did not move (6/6 both ways, gold R1 caught both ways)"); corpus ("the 25k budget did its job … ladder fell back to diff-only (≈14-15k per agent, 12% of core), and the pass still caught the cell's structural red and 3 of 4 ambers"); open question ("No run has inlined a block between ~15k and 25k … calibration note … describes a different quantity")

**Location:** `runs/review-arms/a8-2026-11-20/results.md:122-135`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers each sentence's support in this pass's records. "The budget did its job" is established only in the narrow sense that the ladder applied as written and the run finished with its red found. Corpus had no self-read or full-inline arm, so nothing here shows the budget *caused* the recall (the paragraph says so in its last sentences). "Saved nothing" rests on one draw per arm.

The csp figures are Claim 18, the labels Claim 19, and first-pass labels `"labels_hit": "6/6 (R1,R2,A1,A2,A3,A4)"` (`a8-2026-11-19/manifest.json:47`). The corpus figures are Claims 5 and 22, and the labels Claim 24. The no-15k-25k-run claim holds for the A8 records (csp 2.2k/2.9k, corpus 14.3k/15.5k). The calibration point is Claim 21. "Fails as the skill once worded it" matches the pre-d383a484 text: "This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a pass" (`git show d383a484^1:skills/code-review/SKILL.md`, line 274). The current text reads "**It buys no prompt-cache saving across agents.**" (`skills/code-review/SKILL.md:282`).

**Evidence:** `runs/review-arms/a8-2026-11-19/manifest.json:47`; `skills/code-review/SKILL.md:282-289`; `d383a484^1:skills/code-review/SKILL.md:274-275`

---

## Claim 29: Pass 1 Stage 2.5 outcome "8 entries (S3 split): 6V (4 executed) / 1MA / 1I (perf 'constant work' refuted, executed)"

**Location:** `runs/review-arms/a8-2026-11-20/token-ledger.md:24`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the executed count inside the outcome cell. 8 entries, 6V/1MA/1I and the refuted perf claim are right.

Verdict/mode pairs in `csp/code-fact-check-submitted-claims.md`: 25 V executed, 26 V static, 27a V static, 27b I executed, 28 V executed, 29 V executed, 30 V static and 31 MA executed. Three of the six Verified were executed, not four, and five entries were executed in all. Precise version: "6V (3 executed) / 1MA (executed) / 1I (executed)". This is close to the logged count-claim patterns (miscounted tallies), though not a fabrication.

**Evidence:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-submitted-claims.md` (verdict and mode lines of Claims 25-31)

---

## Claim 30: "Stage 2.5 refuted one endorsement on csp: the performance critic's 'constant work per request' (Claim 27b, executed: cost grows with request header count). It went in as 🟢 C6."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:146-147`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the verdict, mode and rubric placement. Header-count growth is inferred from one 21-header benchmark plus the critic's "per-header serialization" reading, not measured across header counts.

`## Claim 27b: "The proxy does a constant amount of work per request …"` has `**Verdict:** Incorrect` and is executed (`csp/code-fact-check-submitted-claims.md:485-490`). It is the only Incorrect among the 8 entries. Its placement is the rubric line "C6 Stage 2.5 Claim 27b: the performance critic's 'constant work' endorsement was refuted by execution" (`csp/code-review-rubric-2026-11-19-csp.md:33`).

**Evidence:** `csp/code-fact-check-submitted-claims.md:485-512`; `csp/code-review-rubric-2026-11-19-csp.md:33`

---

## Claims Requiring Attention

### Incorrect
- **Claim 8** (`corpus/code-fact-check-report.md:13`): "one row per distinct assertion" is false. r1 Claims 14, 22, 23 and r2 Claim 21 (Verified, single-replicate) have no merged row.
- **Claim 9** (`corpus/code-fact-check-report.md:188`): Claim 12's `r1=—` should be `r1=Verified` (r1 Claim 6c). It is a disagreement, not a single-replicate detection.
- **Claim 10** (`corpus/code-fact-check-report.md:710-711`): stability tally. Claim 12 disagrees (V/MA), so agreement is at most 21/25 = 84% and the single-replicate list is 13, 14, 25.
- **Claim 26a** (`results.md:143-145`): "one row per distinct assertion" holds for csp, not corpus.
- **Claim 27** (`results.md:112-116`): N23, D4 and D5 are listed as rows "the baseline did not have", but the baseline found all three (`baseline token-ledger.md:15,73`; `critic-performance.md:55`). `results.md:110` itself credits the baseline's slug collision.
- **Claim 29** (`token-ledger.md:24`): "6V (4 executed)" should be 6V (3 executed). Five of 8 entries were executed.

### Stale
- none

### Mostly Accurate
- **Claim 2** (`research-2026-11-19-a8-settling-runs.md:17-18`): the brief asks for a literal command check with a blocked-marker stop, not a content check. The doc restates it as a content check (see Escalations).
- **Claim 12** (`corpus rubric:18`; `results.md:105`): "Claims 3, 4 (executed 3/3)". Claim 4 is I/MA/MA, and r3 verdicted it statically.
- **Claim 20** (`results.md:58`): "Stage 2.5 ran 4 claims": 5 claims were executed, over 4 runs.
- **Claim 23** (`results.md:89-90`): "a third to three quarters" is 0.35-0.78 by the numbers, so about four fifths at the top.
- **Claim 25** (`results.md:102-103`): baseline cor-A1 miss cites the ledger's E4 column. Baseline cor-A2 "reported HIT" is a miss on the canon reading (`baseline critic-architecture.md:81` calls paths.ts the sole path producer).
- **Claim 26b** (`results.md:145`): "Stage 2.5's 7 and 8 entries" is swapped. It is csp 8, corpus 7.

### Unverifiable
- none

## Escalations

- **Precondition reading (Claim 2).** The brief's stop condition was literal: "if it is not, end with a blocked marker". The research doc shows correctly that the literal check can never pass for a TREESAME merge, and that the content condition holds. Proceeding on that reading is a call for the orchestrator or owner, not a fact the write-up can settle. If the reading stands, the doc could say plainly that the literal check failed and why it was set aside.

## Goal-Alignment Note

- **Success criterion:** "A code-fact-check report on the A8 settling write-up, saved to the path given, structured per the code-fact-check skill."
- **Answered:** Every number in results.md, the research doc, ledger and manifest was recomputed with python3 (`logs/calc.log`), and the ledger figures and instrument claims were checked against the 19 subagent transcripts. Every csp and corpus label verdict was checked against the agent reports and canon rows. The block sizes were re-measured from the benchmark repo, and the 17.4k calibration was traced to the levers table's "diff+factcheck chars". Rubric sources were checked in both cells. Both merged reports were checked against all replicate verdict lines and most-severe-wins. The A8 paragraph was checked sentence by sentence, and the git precondition by execution.
- **Out of scope:** The agent reports' own findings (measured data, not reviewed). Whether the review was good. The hallucination-pattern log was not updated (read-only scope).
- **Escalate:** The precondition reading (Claim 2, above). The corpus merge's coverage and stability tally (Claims 8-10) feed the cluster counts quoted in results §4.
