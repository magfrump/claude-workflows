Commit: 8152e60e

# Code Fact-Check Report

**Commit:** 8152e60e
**Replication:** k=1 (loop pass, decision 031)
**Repository:** claude-workflows (worktree `.claude/wt-2026-11-19-a8-token-measurement`, branch `measure/a8-token-measurement`)
**Scope:** delta `3d8cabb3..8152e60e` of `runs/review-arms/a8-2026-11-19/{results.md,token-ledger.md,manifest.json,csp/code-review-rubric-2026-11-19-csp.md}` and `docs/working/research-2026-11-19-a8-token-measurement.md`; every changed paragraph read whole. Checked against the previous pass (`docs/reviews/code-fact-check-report-2026-11-19-a8-pass2.md`, Claims 1, 4, 7, 12, 13a).
**Checked:** 2026-11-19
**Total claims checked:** 9
**Summary:** 8 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read. The nearest logged class is "a specific measured value quoted from an artifact set that does not contain it". Claim 5 below is checked against that class: the values exist in the transcripts, and one is rounded loosely. Nothing in the delta is fabricated.

Primary records: the nine sub-agent transcripts under `/tmp/claude-1000/-workspace/a2588790-deaf-4649-9915-f641c00b3dd0/tasks/`, parsed with `python3 -I` for aggregates only: `api-request` timestamps and `cacheControl`, the first `api-request-blob` block lengths, and assistant `message.usage` deduped by `requestId`. Also `git show 82accdd7` and `docs/working/canon-issue-ledger.md:174-189`. All of this is static reading plus arithmetic. None of the reviewed text is an executable guarantee.

---

## Claim 1: "82accdd7, its child, changed only `references/rubric.md` under `skills/code-review/`" (and the equivalent wording in the manifest and results)

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:24`, `runs/review-arms/a8-2026-11-19/manifest.json:4`, `runs/review-arms/a8-2026-11-19/results.md:16-17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers 82accdd7's parent, date and file list, and the last `SKILL.md` change before it. Does not establish whether any commit between 82accdd7 and `4330e303` touched other files under `skills/code-review/`; the claim does not assert that.
**Legibility-target:** for-author

`git show --name-only --format='%h %p %ad %s' --date=short 82accdd7` gives `82accdd7 44724747 2026-11-14` and four files. `skills/code-review/references/rubric.md` is the only one under `skills/code-review/`; the others are `docs/working/briefs/...`, `docs/working/research-...` and `workflows/pr-prep.md`. `git log 82accdd7..4330e303 -- skills/code-review/SKILL.md` is empty, and `44724747` is the last `SKILL.md` commit. All three wordings ("changed only ... under `skills/code-review/`" and "changed `references/rubric.md` and nothing else under `skills/code-review/`") match this. They apply the precise version pass 2 asked for.

**Evidence:** `git show --name-only 82accdd7`; `git log -- skills/code-review/SKILL.md`

---

## Claim 2: "stays the first part of every prompt I write (the harness puts its own context ahead of it in the request, and no cache breakpoint ends at it; results §2)"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:58-60`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the position of the shared block in the first request and the breakpoint paths. Does not establish whether a read-by-path arm would cost differently: the paragraph's "a few hundred tokens" estimate is unchanged and was not re-measured.
**Legibility-target:** for-author

In the api critic's first `api-request-blob`, the user message's blocks are: 0 (47,023 chars, `'<system-reminder>\nCodebase and user instructions...'`), 1 (1,797 chars), 2 (709 chars), 3 (13,697 chars, `'# Review pass: shared context (identical for every agent in this pass)'`) and 4 (419 chars, a system-reminder). That is paraphrased, with no quote available because these are block lengths and prefixes aggregated from a JSONL record. So harness context does come ahead of the block in the request. Every first request's `cacheControl` lists `system[0]`, `system[1]` and `messages[1].content[3]`, and block 3 holds the 8,745-char shared block plus the per-agent tail. So no breakpoint ends at the shared block. This replaces "cacheable", which pass 2 Claim 4 flagged, and the paragraph's opening sentence ("each agent's prompt opens with the byte-identical shared block", `:54`) remains consistent because it says "prompt", not "request".

**Evidence:** api transcript `a05902472e93b6616` first `api-request-blob`; `api-request` `cacheControl` for all 9 agents

---

## Claim 3: rubric A4 "(worker half: canon N7, refuted by E7r2, demotion pending; not creditable)"

**Location:** `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md:28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the annotation against the ledger's N7 status. Does not establish how the adjudication will turn out; the ledger leaves it open.
**Legibility-target:** for-author

The ledger reads `**Candidate REFUTED by E7r2** with spec + WPT evidence ... — pending demotion adjudication` (`docs/working/canon-issue-ledger.md:185-189`). "Demotion pending" matches this. "Not creditable" is a scoring instruction for this pass, not a statement that N7 has been demoted, so it does not restate the settled-adjudication error pass 2 Claim 7 flagged.

**Evidence:** `docs/working/canon-issue-ledger.md:185-189`

---

## Claim 4: "Within a run, an agent's later calls usually re-read its own prefix from cache, block included ... The exceptions are calls after a long gap"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:66-69`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every deduped call across the 9 agents, checking whether any non-first call read less than 90% of the previous call's read+write. Does not establish the "with or without inlining" counterfactual, which this pass did not run.
**Legibility-target:** for-author

Across all calls, only three non-first calls have a read that falls below the previous call's prefix: r1 call 14 (read 18,900, write 80,128), r2 call 9 (18,900 / 69,764) and api call 7 (0 / 87,070). r3, security, performance, architecture, test-strategy and Stage 2.5 have none. That is paraphrased, with no quote available because these are per-`requestId` `usage` aggregates over nine JSONL files. So the listed exceptions are complete, and each one is the agent's final call.

**Evidence:** assistant `message.usage` per `requestId`, all 9 transcripts

---

## Claim 5: "the final calls of r1 and r2, after about 6-7 minutes, read only 18,900, and the api critic's final call, after 73 minutes, read 0"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:69-71`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the request-to-request and response-to-request gaps and the cache reads of the three final calls. Does not establish the server-side cache lifetime; the doc does not claim to have read it.
**Legibility-target:** for-author

The reads are exact: r1 18,900, r2 18,900, api 0. api's previous request was at `17:19:49.488Z` and its final one at `18:32:51.398Z`, a gap of 73.0 min. r1's gap is shorter than stated. Its previous request was at `17:07:05.940Z` and its final one at `17:12:49.938Z`, a gap of 5.73 min, or 4.1 min from the end of the previous response at `17:08:44.583Z`. r2's previous request was at `17:06:05.114Z` and its final one at `17:12:48.412Z`, a gap of 6.72 min, or 5.4 min from the end of the previous response at `17:07:21.641Z`. That is paraphrased, with no quote available because these are `api-request` and assistant timestamps from three transcripts. Pass 2 had "about 5¾ min" for r1 and "7 min" for r2, so "6-7 minutes" rounds r1 up. Precise version: "after about 5¾ and 6¾ minutes". Both gaps still exceed five minutes, so the point the sentence makes holds.

**Evidence:** transcripts r1 `a1a8fdb7b815b5808`, r2 `adbaabb0018c4f408`, api `a05902472e93b6616` (last 10 events each)

---

## Claim 6: "Within Stages 1 and 2 the agents' first requests went out within milliseconds of each other, so those stages cannot separate timing from breakpoints"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:76-78`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the first `api-request` timestamps of the 3 Stage-1 and 5 Stage-2 agents. Does not establish cross-stage reuse; that is moot because the two stages' shared blocks hash differently (`results.md:62-63`, unchanged).
**Legibility-target:** for-author

Stage 1 first requests went out at r1 `17:05:01.016Z`, r3 `.032Z` and r2 `.034Z`, an 18 ms span. Stage 2 went out at security `17:19:04.748Z`, test-strategy `.750Z`, performance `.751Z`, api `.753Z` and architecture `.754Z`, a 6 ms span. That is paraphrased, with no quote available because these are timestamps from eight transcripts' first `api-request` records. This replaces the r3 "5.5 s" argument that pass 2 Claim 13a found Incorrect, and draws the conclusion pass 2 asked for.

**Evidence:** first `api-request` record in each of the 8 Stage-1/2 transcripts

---

## Claim 7: "the api critic, whose last call (which had just written its full prefix to cache) came 59 s before Stage 2.5's first request, well inside the 5-minute cache lifetime, and Stage 2.5 still read only 18,900"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:78-82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers api's last call (its timing and usage) and Stage 2.5's first request and read. Does not establish the cache lookup rule; the paragraph labels its breakpoint explanation as an inference.
**Legibility-target:** for-author

api's last call was sent at `18:32:51.398Z`, returned at `18:33:03.553Z`, read 0 and wrote 87,070 with 2 uncached input tokens. So the whole prompt, shared block included, was written to cache, and "had just written its full prefix" holds. Stage 2.5's first `api-request` is at `18:34:02.437Z`: 58.9 s after api's response and 71.0 s after api's request. Either figure is well inside five minutes. Stage 2.5's first call read 18,900. All of this is paraphrased, with no quote available because these are transcript aggregates. "59 s" is measured from the end of api's call. "Came 59 s before" reads naturally that way, and the 12 s difference does not affect the argument. The ~8,745-char common prefix was verified by pass 2 (Claim 13b) and is unchanged here.

**Evidence:** transcripts api `a05902472e93b6616`, Stage 2.5 `a6a0ebd8bee725384`

---

## Claim 8: "canon N7, which E7r2 refuted with spec and WPT evidence (`:185-189`); the ledger still lists its demotion as pending adjudication. So the worker half of the rubric's A4 should not be credited as a hit (the rest of A4, the export coupling, is R1's)."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:115-119`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the N7 ledger status, the line range, and A4's composition in the rubric. Does not establish the final scoring of A4; that belongs to whoever re-scores.
**Legibility-target:** for-author

The ledger reads `— pending demotion adjudication` (`docs/working/canon-issue-ledger.md:188-189`), within the cited `:185-189`. The rubric's A4 reads `besides R1, the pdf.js worker may be blocked` and cites `architecture #2` (`csp/code-review-rubric-2026-11-19-csp.md:28`). R1's row cites the same `architecture #2 (Coupling)` for the graph export (`:15`). So "the rest of A4, the export coupling, is R1's" holds. Both of pass 2 Claim 7's fixes landed: the adjudication is described as pending, and the instruction is scoped to the worker half.

**Evidence:** `docs/working/canon-issue-ledger.md:185-189`; `csp/code-review-rubric-2026-11-19-csp.md:15,28`

---

## Claim 9: "(an agent's later calls usually re-read its own prefix; results §2 lists the exceptions)"

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:27-28`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the same per-call aggregate as Claim 4, and confirms that §2 holds the exceptions list (`results.md:69-71`). Does not re-verify the gap durations; Claim 5 covers those.
**Legibility-target:** for-author

The aggregate in Claim 4 supports the sentence, and §2 lists the three exceptions (paraphrased, with no quote available because the support is the per-call aggregate described in Claim 4). It replaces the unqualified "from its second call on" wording that pass 2 Claim 12 flagged.

**Evidence:** as Claim 4; `runs/review-arms/a8-2026-11-19/results.md:69-71`

---

## Claims Requiring Attention

### Mostly accurate
- **Claim 5** (`runs/review-arms/a8-2026-11-19/results.md:70`): "after about 6-7 minutes" for the final calls of r1 and r2. r1's gap is 5.73 min request-to-request, and r2's is 6.72 min. Precise version: "after about 5¾ and 6¾ minutes". This is cosmetic: both gaps are over five minutes, so the argument holds.

No Incorrect, Stale or Unverifiable claims. All five corrections from pass 2 (Claims 1, 4, 7, 12 and 13a) are applied accurately, and Claim 5 is the only new imprecision they introduce.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-2026-11-19-a8-token-measurement/docs/reviews/code-fact-check-report-2026-11-19-a8-pass3.md, with `Commit: 8152e60e` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: lines outside the `3d8cabb3..8152e60e` delta, which earlier passes already covered; the API's prefix-matching rule, which needs documentation the sandbox cannot fetch and which the doc labels as an inference
- Escalate: nothing
