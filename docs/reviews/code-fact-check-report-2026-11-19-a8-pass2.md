Commit: 3d8cabb3

# Code Fact-Check Report

**Commit:** 3d8cabb3
**Replication:** k=1 (loop pass, decision 031)
**Repository:** claude-workflows (worktree `.claude/wt-2026-11-19-a8-token-measurement`, branch `measure/a8-token-measurement`)
**Scope:** delta `123432af..3d8cabb3` of `runs/review-arms/a8-2026-11-19/{results.md,token-ledger.md,manifest.json,csp/code-review-rubric-2026-11-19-csp.md}` and `docs/working/research-2026-11-19-a8-token-measurement.md`; every changed paragraph read whole. Checked against the previous pass (`docs/reviews/code-fact-check-report-2026-11-19-a8.md`, Claims 2-16; rubric `docs/reviews/code-review-rubric-2026-11-19-measure-a8-token-measurement.md` A1-A13).
**Checked:** 2026-11-19
**Total claims checked:** 19
**Summary:** 14 verified, 4 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read; no claim below matches a logged pattern, and no fabrication was found.

Primary records used: the nine sub-agent transcripts under `/tmp/claude-1000/-workspace/a2588790-deaf-4649-9915-f641c00b3dd0/tasks/` (parsed with `python3 -I`, aggregates only: `api-request` `cacheControl`/`tail`/timestamps, `api-request-blob` block lengths, assistant `message.usage` deduped by `requestId`, `tool_use` ids), `git log`/`git show`, `csp/shared-block*.md`, the baseline ledger and the canon ledger. All recomputation was static reading plus arithmetic in `python3`; nothing in the reviewed docs is an executable guarantee.

---

## Claim 1: "`SKILL.md` last changed in 44724747; 82accdd7, its child, touched only `references/rubric.md`"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:24`, `runs/review-arms/a8-2026-11-19/manifest.json:4`, `runs/review-arms/a8-2026-11-19/results.md:16-17`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the last commit to touch `skills/code-review/SKILL.md` up to `4330e303`, the parent of 82accdd7 and 82accdd7's file list; does not establish anything about other skill files' histories.
**Legibility-target:** for-author

`git log -- skills/code-review/SKILL.md` gives `44724747 2026-11-14 docs(review): address review iteration 1` first, and `git log 82accdd7..4330e303 -- skills/code-review/SKILL.md` is empty, so 44724747 is the last change as of the measured commit. `git log -1 --format='%h %p' 82accdd7` gives `82accdd7 44724747`, so "its child" holds. But `git show --name-only 82accdd7` lists four files: `docs/working/briefs/2026-11-14-review-rules-close-gaps.md`, `docs/working/research-2026-11-14-review-rules-close-gaps.md`, `skills/code-review/references/rubric.md`, `workflows/pr-prep.md`. "Touched only `references/rubric.md`" is true only inside `skills/code-review/`. Precise version: "82accdd7, its child, did not touch `SKILL.md` (within the skill it changed only `references/rubric.md`)". The point the correction makes (82accdd7 is not the SKILL.md change) is right.

**Evidence:** `git log -- skills/code-review/SKILL.md`; `git show --name-only 82accdd7`

---

## Claim 2: "Tokens = `subagent_tokens` from each Agent task notification (the field the 2026-08-06 baseline and E1/E3 report; I assume the same harness definition)"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:40`, `runs/review-arms/a8-2026-11-19/token-ledger.md:3-4`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the field name and the baseline ledger's own naming; does not establish that the harness computed the field identically in August (the text says "I assume", which is the right hedge).
**Legibility-target:** for-author

The baseline ledger reads `Tokens = subagent_tokens from task notifications (same instrument as E1/E3).` (`runs/review-arms/baseline-2026-08-06/token-ledger.md:3`). The previous pass's Claim 5 correction (rubric A5) is applied in both places, and the ledger now carries the "I assume" hedge r2 asked for.

**Evidence:** `runs/review-arms/baseline-2026-08-06/token-ledger.md:3`

---

## Claim 3: skill texts "14.5-34 KB" and "~250 KB across the 9 prompts"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:56`, `docs/working/research-2026-11-19-a8-token-measurement.md:75`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers byte sizes of the six skill files at `4330e303` and their sum over the 9 agents (code-fact-check read by r1, r2, r3 and Stage 2.5); does not establish the token cost of reading them.
**Legibility-target:** for-author

`git show 4330e303:skills/<s>/SKILL.md | wc -c`: code-fact-check 32,228, security-reviewer 34,021, performance-reviewer 23,941, api-consistency-reviewer 22,753, architecture-review 27,564, test-strategy 14,504. Range 14.5-34.0 KB. Sum over the 9 prompts: 4×32,228 + 34,021 + 23,941 + 22,753 + 27,564 + 14,504 = 251,695 bytes, "~250 KB" (paraphrased — no quote available because the figures are command output, not file text).

**Evidence:** `skills/*/SKILL.md` at `4330e303`

---

## Claim 4: "the shared block, the thing A8 is about, stays the cacheable first part of every prompt"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:57-58` (unchanged line inside the changed paragraph at `:53-58`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the position of the shared block in the orchestrator's prompt and in the recorded API request; does not establish what a read-by-path arm would cost.
**Legibility-target:** for-author

The block is first in the orchestrator's prompt text: in every agent's first request, `messages[0].content[3]` begins `'# Review pass: shared context (identical for every agent in this pass)'` (paraphrased — no quote available because this is an aggregate over the nine transcripts' `api-request-blob` records). In the request as sent, though, `messages[0].content[0..2]` (47,023 + 1,797 + 709 characters of harness system-reminders, hash-identical across all nine agents) precede it, and block 3 holds shared block and per-agent tail in one text block, with no breakpoint at the block's end (Claim 5). So "first part of every prompt" holds for the prompt the orchestrator wrote, and "cacheable" holds only in the sense of its position. Results §2 shows it was not cacheable across agents on this path. Precise version: "stays first in every prompt, the position the skill relies on for caching (results §2: no breakpoint ends there)".

**Evidence:** transcripts' first `api-request-blob` (message 0, blocks 0-4) for r1, api, Stage 2.5, sec, r2, r3

---

## Claim 5: first-request breakpoints `system[0]`, `system[1]`, `messages[1].content[3]` ("the end of the first user turn, after the per-agent tail"); "no agent read the inlined shared block from another agent's cache"; "No cache entry ever ends at the shared block's last byte"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:95-97`, `runs/review-arms/a8-2026-11-19/manifest.json:46`, `runs/review-arms/a8-2026-11-19/results.md:65-67`, `runs/review-arms/a8-2026-11-19/results.md:71-74`, `runs/review-arms/a8-2026-11-19/token-ledger.md:24-26`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the recorded `cacheControl` paths of every request of all 9 agents, the first-call `usage` of all 9, and the block layout of the first request; does not establish the API's server-side prefix-matching rule (the write-up says so itself at `results.md:78-79`).
**Legibility-target:** for-author

The first `api-request` of all nine agents carries `'cacheControl': [{'path': ['system', 0], ...}, {'path': ['system', 1], ...}, {'path': ['messages', 1, 'content', 3], ...}]` (r1's record, transcript `a1a8fdb7b815b5808`; the same three paths on the other eight). The request's `tail` has two messages: message 0 (5 blocks: three system-reminders, the prompt, the handback reminder) and message 1 (4 blocks: a 26,004-character deferred-tool listing and three `tool_addition` blocks), so `messages[1].content[3]` is the last block of the opening user input, after the per-agent tail (paraphrased — no quote available because this is the block layout from `api-request-blob` records). Every later request's breakpoints sit at `messages[N].content[0|1]` for N ≥ 4; none is at `messages[0].content[3]`, and since the shared block and the tail share one text block, no block boundary exists at the shared block's end at all. First-call usage: `cache_read_input_tokens` 18,900 on all nine; `cache_creation_input_tokens` 32,797 (r1, r2, r3) to 33,788 (security), matching "32.8k-33.8k". The previous pass's Claims 10 and 16 (rubric A9) are applied: "never served from cache" is now "from another agent's cache", and the breakpoints are reported.

One reading note: `messages[1]` is the second recorded message (the tool listing), not the prompt message; "the end of the first user turn" is right only if the two count as one turn, which they do on the wire as consecutive user input.

**Evidence:** transcripts of all 9 agents (`api-request` `cacheControl` and `tail`; `api-request-blob`; assistant `message.usage`)

---

## Claim 6: rubric A2 "Open (= canon N1)"; "Security's `Purpose: prefetch` finding (🟡 A2) is canon N1, real and fix-confirmed at `ab4dbdb` (`docs/working/canon-issue-ledger.md:176-177`)"

**Location:** `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md:26`, `runs/review-arms/a8-2026-11-19/results.md:109-111`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the canon ledger's N1 entry and its line numbers; does not establish that the measured pass's finding text is the same defect beyond the shared description (both describe the prefetch matcher serving HTML without CSP).
**Legibility-target:** for-author

`docs/working/canon-issue-ledger.md:176-177`: "**N1** csp: middleware prefetch-skip serves real HTML with no CSP (E5; **fix-confirmed `ab4dbdb`**)". The previous pass's Claim 2 (rubric A1) is fixed: the finding is no longer called new.

**Evidence:** `docs/working/canon-issue-ledger.md:176-177`

---

## Claim 7: rubric A4 "(worker half: canon N7, refuted by E7r2; known false positive)"; results "canon N7, which E7r2 refuted with spec and WPT evidence (`:185-189`). It counts as a known false positive: the rubric's A4 should not be credited."

**Location:** `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md:28`, `runs/review-arms/a8-2026-11-19/results.md:111-114`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the canon ledger's N7 entry, its status wording and line numbers; does not establish the adjudication outcome, which the ledger leaves open.
**Legibility-target:** for-author

The ledger reads `N7 csp: no worker-src under 'strict-dynamic' — pdf.js worker blocked/degraded (E6, verifier-kept; never fixed at HEAD). **Candidate REFUTED by E7r2** with spec + WPT evidence ... — pending demotion adjudication; if demoted it also retro-corrects E6's and E7r1's credited hits.` (`docs/working/canon-issue-ledger.md:185-189`). N7 and E7r2's refutation are cited correctly, as are the line numbers. But the ledger has not demoted it: "pending demotion adjudication". "It counts as a known false positive" and "should not be credited" state the expected adjudication as settled. Precise version: "canon N7, refuted by E7r2 and pending demotion; do not credit it as a hit". Also, "the rubric's A4 should not be credited" should say "A4's worker half", as the rubric annotation does; A4's other half restates R1, which is credited.

**Evidence:** `docs/working/canon-issue-ledger.md:185-189`; `csp/code-review-rubric-2026-11-19-csp.md:28`

---

## Claim 8: "the remainder, ~97k (+27% of 359k), is per-agent growth. (The +26% in the table is a different comparison: k=1-equivalent today, +111k against the 424,520 that includes the gap-fix.)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:41-44`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arithmetic from the §1 table and the ledgers; does not establish how the remainder divides among causes.
**Legibility-target:** for-author

743,755 − 358,626 = 385,129; two extra replicates at the mean = 2 × 311,975 / 3 = 207,983; test-strategy 79,690; remainder 97,456 = 27.2% of 358,626. Table row: 535,772 − 424,520 = 111,252 = +26.2% (paraphrased — no quote available because these are python3 recomputations of figures in `token-ledger.md:10-22` and the baseline ledger). Previous Claim 8 (rubric A7) is fixed.

**Evidence:** `token-ledger.md:10-22`; `runs/review-arms/baseline-2026-08-06/token-ledger.md:16,47-49,80,82`; `results.md:31-38`

---

## Claim 9: "3×2,189 + 5×2,929 ≈ 21.2k tokens over the 8 core agents, ≈2.9% of the core total. Against the baseline that is 2.9 to 4.4 points of each agent's growth (about 4 points overall)"; ledger "8,755 bytes ≈ 2,189 tokens (bytes/4)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:46-50`, `runs/review-arms/a8-2026-11-19/token-ledger.md:5`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the block-size sum, its share of core, and the block as a share of each agent's baseline figure; does not establish the block's net cost against a self-read arm (the write-up does not claim it).
**Legibility-target:** for-author

`wc -c`: `shared-block.md` 8,755, `shared-block-stage2.md` 11,716; /4 = 2,188.75 and 2,929. 3×2,189 + 5×2,929 = 21,212; 21,212 / 743,755 = 2.85%, "≈2.9%". Block ÷ baseline per agent: fact-check 2,189/74,274 = 2.95, security 3.76, api 4.27, architecture 4.13, performance 4.37, test-strategy 4.45 points. Range 2.9-4.4 (4.45 truncated rather than rounded). Overall: 21,212 / (3×74,274 + 77,879 + 67,010 + 68,604 + 70,859 + 65,894) = 3.7%, "about 4" (paraphrased — no quote available because these are python3 recomputations). Previous Claims 3, 7 and 13 (rubric A2, A3, A12) are fixed.

**Evidence:** `csp/shared-block.md`, `csp/shared-block-stage2.md` sizes; `token-ledger.md:10-21`; baseline ledger csp rows

---

## Claim 10: skill growth "≈2.9k (code-fact-check), 2.6k (security), 0.8k (performance) and under 0.3k (the other three)"; "Each critic grew 10.5k to 25.4k tokens, so about 7.4k to 19.9k per critic is explained by neither"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:50-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers skill byte deltas between `d4e362de` (the last commit on or before 2026-08-06) and `4330e303` at bytes/4, and critic growth minus block minus skill growth; does not establish that `d4e362de` is the exact commit the baseline ran from.
**Legibility-target:** for-author

Skill deltas, bytes/4: code-fact-check 2,927, security 2,642, performance 828, api-consistency 53, architecture 255, test-strategy 43. Critic growth: architecture +10,540 to security +25,447. Residual (growth − 2,929 − skill delta): architecture 7,356, performance 8,220, test-strategy 10,824, api 16,792, security 19,876 (paraphrased — no quote available because these are command output and python3 arithmetic). "About 7.4k to 19.9k" matches. Previous Claim 9 (rubric A8) is fixed.

**Evidence:** `git show d4e362de:skills/<s>/SKILL.md` vs `4330e303`; `token-ledger.md:14-18`; baseline ledger `:47-49,80,82`

---

## Claim 11: "Every agent's first call already holds ~52k tokens before it does any work: 18.9k cached (system prompt and tools), ~3k of my prompt, and a remainder of ~30k that the transcripts record as attachments (instruction files, skill listing, environment) without per-part token counts. I found no transcripts from the August run"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:53-57`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers first-call usage totals, prompt-block size and the transcripts' attachment record types; does not establish the per-part token split (the text says it has none) or whether August transcripts exist (a first-person search report, hedged as such).
**Legibility-target:** for-author

First-call totals (input + cache creation + cache read + output): 51,790 (r2, r3) to 53,040 (api). Prompt block (`messages[0].content[3]`) is 11,856 characters for r1 and 13,697 for api, about 3.0-3.4k tokens. 52k − 18.9k − 3k ≈ 30k. r1's transcript has `attachment` records of types `instructions` (48,026 chars of JSON), `skill_listing` (26,343), `environment`, `session_context`, `deferred_tools_delta` and others, none carrying a token count (paraphrased — no quote available because these are aggregates over transcript records). Previous Claim 15 (rubric A13) is addressed by the new "remainder" and "I found no" wording.

**Evidence:** transcripts' first assistant `usage`; r1 `attachment` records; first `api-request-blob`

---

## Claim 12: "(From its second call on, each agent re-reads its own prefix from cache, block included; that happens with or without inlining.)"; ledger "(each re-reads its own prefix from its second call on)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:67-69`, `runs/review-arms/a8-2026-11-19/token-ledger.md:26-27`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers per-request `cache_read_input_tokens` on all 9 agents; does not establish the self-read counterfactual ("with or without inlining"), which this pass did not run.
**Legibility-target:** for-author

Every agent's second call reads its own prefix (r1 51,697; security 52,688; Stage 2.5 52,114; and so on), and most later calls keep reading it. Three calls break the pattern, each a final call after a gap longer than five minutes: r1's last call (17:13:08, about 5¾ min after its previous one) read 18,900 and wrote 80,128; r2's last (17:13:04, 7 min gap) read 18,900 and wrote 69,764; api's last (18:33:03, 73 min gap) read 0 and wrote 87,070 (paraphrased — no quote available because these are deduped per-request `usage` aggregates). Precise version: "from its second call on, each agent re-reads its own prefix from cache, except after a gap longer than the cache lifetime (the final calls of r1, r2 and api)".

**Evidence:** transcripts' assistant `message.usage` per `requestId` for all 9 agents

---

## Claim 13a: "Timing does not explain it. r3's first call returned about 5.5 s after r1's and r2's and still read only 18,900."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:74-75`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the send and response timestamps of the three Stage-1 first requests; does not establish when the server ran r3's cache lookup (not recorded), which is why confidence is Medium.
**Legibility-target:** for-author

The number roughly holds: r3's first response is at 17:05:10.171, 5.5 s after the end of r1's first response (17:05:04.674) and 6.0 s after r2's (17:05:04.167). The inference does not. The three first requests went out together, `api-request` timestamps r1 `17:05:01.016Z`, r3 `17:05:01.032Z`, r2 `17:05:01.034Z`: r3's was sent 16 ms after r1's and before r2's (paraphrased — no quote available because these are timestamps from three transcripts' `api-request` records). A later return time does not mean a sibling's cache entry existed when r3's prefix was looked up, so r3 cannot rule out parallel dispatch as a cause. The same holds for the five Stage-2 critics, sent between 17:19:04.748 and 17:19:04.754. Only the Stage 2.5 observation (Claim 13b) separates timing from breakpoints. The paragraph's conclusion stands on 13b; the r3 sentence should be dropped or restated as "r3 was sent with r1 and r2, so it does not test timing".

**Evidence:** transcripts r1 `a1a8fdb7b815b5808`, r2 `adbaabb0018c4f408`, r3 `ad528318415ea2cda` (`api-request` and first assistant timestamps); Stage-2 critics' first `api-request` timestamps

---

## Claim 13b: "The Stage 2.5 agent shares the first 8,745 characters with the api critic, whose last call came 59 s before Stage 2.5's first, well inside the 5-minute cache lifetime, and it too read 18,900."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:75-79`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the common prefix of the two prompt blocks, the timestamps and Stage 2.5's first-call cache read; does not establish the 5-minute lifetime from API documentation (the text says it read none).
**Legibility-target:** for-author

The common prefix of Stage 2.5's and api's `messages[0].content[3]` is 8,746 characters (`shared-block.md` is 8,745 characters; the extra one is a shared trailing character), after 49,529 characters of hash-identical blocks 0-2. api's last response is at 18:33:03.553; Stage 2.5's first `api-request` is at 18:34:02.437, 58.9 s later. Stage 2.5's first call read 18,900 (paraphrased — no quote available because these are transcript aggregates). The finding is stronger than stated: api's last call read 0 and wrote 87,070 tokens of cache, so a fresh entry holding the full shared prefix existed 59 s before Stage 2.5's request, and Stage 2.5 still matched only system + tools.

**Evidence:** transcripts api `a05902472e93b6616`, Stage 2.5 `a6a0ebd8bee725384`

---

## Claim 14: the brief "does not name `exportGraph.ts`. But two of its lines point down the routes to labelled findings: 'check the client-side code in the repo that would run under it' (the route to R1) and '(does anything read it?)' about `x-nonce` (the route to A1)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:100-104`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the text of r1's dispatched prompt (identical across the three replicates up to the per-agent tail); does not establish what a label-blind brief would have contained.
**Legibility-target:** for-author

r1's prompt block contains "check the client-side code in the repo that would run under it):" at offset 9,739 and "lets layouts read the nonce via headers() and pass it to Script tags (does anything read it?)." at offset 10,324; `exportGraph` does not occur (find = −1). Previous Claim 11 (rubric A10) is fixed.

**Evidence:** r1 transcript first `api-request-blob`, message 0 block 3

---

## Claim 15: §4 figures: "2.2k-2.9k tokens per agent (≈2.9% of core)"; "Per-agent growth since August is +15% to +40% (architecture +15%, fact-check replicate mean +40%). The inlined block is about 3 to 4 of those points"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:123-128`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers per-agent growth ratios and block-share points; does not establish attribution of the rest of the growth (the text says it is not attributable).
**Legibility-target:** for-author

Growth: architecture +14.9%, performance +17.9%, test-strategy +20.9%, api +28.8%, security +32.7%, replicate mean +40.0%. Block points 2.95-4.45 (Claim 9), "about 3 to 4", consistent with §1's "2.9 to 4.4" (paraphrased — no quote available because these are python3 recomputations). Previous Claims 3 and 12 (rubric A2, A11) are fixed.

**Evidence:** `token-ledger.md:10-18`; baseline ledger csp rows

---

## Claim 16: the rewritten §4 verdict, "The request records suggest this is structural on the Agent-tool path (§2), not bad luck ... The cost side cannot be told net ... **Verdict: the 'leave it on because it is free' claim fails on its benefit:** zero within this pass. Its cost is small in gross terms and unmeasured net."; and the probe paragraph "If the read stays at 18.9k, that confirms the breakpoint reading of §2"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:118-136`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether each verdict sentence is supported by the pass's records and is scoped to them; does not establish the structural cause itself (an inference, hedged as "suggest" and "one cell cannot confirm it"), or cross-pass reuse (stated as not exercised).
**Legibility-target:** for-author

The skill's claim is "Measured benefit is modest — single-digit-% of input cost, 0% of token count ... Leave it on because it is free" (`skills/code-review/SKILL.md:352-353` at `4330e303`), and its benefit is the cache serving "the shared block to all ~8 agents in a pass — and again on the next loop pass" (`:274-275`). The verdict now limits the benefit finding to "zero within this pass" and says separately that "Reuse across loop passes was not exercised", which matches what one terminal pass can show. The cost side drops the old "small but not zero" net claim (previous Claim 3, rubric A2) for "small in gross terms and unmeasured net", which matches the absence of a self-read arm. "Structural ... (§2)" rests on the breakpoint records (Claim 5) and Stage 2.5 (Claim 13b), both verified, and is hedged. One residue: §2's r3 sentence (Claim 13a) is part of the cited support and does not hold up; the verdict survives without it. "That would make it hold for every parallel pass" is narrower than the structural reading (it would also cover serial dispatch, as Stage 2.5 shows), so it understates rather than overstates. Medium confidence because whether the wording is adequately hedged is a judgment of degree.

**Evidence:** `results.md:118-136`; `skills/code-review/SKILL.md:270-277,352-354` at `4330e303`; Claims 5, 13a, 13b

---

## Claim 17: "The ledger's `tool_uses` values are the task notifications' figures. Each is one less than the transcript's tool-call count, on every row. Replicate r2's verdict string in the ledger copies its report header (14 claims, 5V), whose body has 15 verdicts with 6 Verified."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:149-151`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers transcript `tool_use` counts (deduped by id) against the ledger, and r2's report header and body; does not establish the notifications' own values (not available to this pass), which the ledger rows are said to copy.
**Legibility-target:** for-author

Transcript `tool_use` counts vs ledger: r2 10/9, r1 14/13, r3 36/35, performance 6/5, architecture 7/6, test-strategy 9/8, security 10/9, api 8/7, Stage 2.5 18/17, so the difference is 1 on every row (paraphrased — no quote available because these are transcript aggregates). `csp/code-fact-check-report-r2.md:8-9`: "**Total claims checked:** 14" and "**Summary:** 5 verified, 0 mostly accurate, 0 stale, 7 incorrect, 2 unverifiable"; the body has 15 `**Verdict:**` lines, 6 of them Verified. Previous Claim 14 (rubric A13) is disclosed.

**Evidence:** 9 transcripts; `csp/code-fact-check-report-r2.md:8-9`; `token-ledger.md:10-20`

---

## Claim 18: "Reviewing this write-up (3 fact-check replicates over these docs) cost 488,455 tokens, outside the measured pass."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:152-153`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the sum of the three figures the orchestrator supplied (r1 173,660, r2 158,970, r3 155,825); does not establish those figures against the notifications, which this pass did not see.
**Legibility-target:** for-author

173,660 + 158,970 + 155,825 = 488,455 (paraphrased — no quote available because the inputs come from the dispatch brief, not a file).

**Evidence:** dispatch brief figures; `results.md:152-153`

---

## Claims Requiring Attention

### Incorrect
- **Claim 13a** (`runs/review-arms/a8-2026-11-19/results.md:74-75`): r3's first request was sent at 17:05:01.032, between r1's (.016) and r2's (.034). Its later return time cannot show that timing does not explain the miss. Drop the sentence or say that r3 does not test timing; Stage 2.5 (59 s after api's last call, which wrote 87k of cache) is the evidence that does.

### Stale
- none

### Mostly Accurate
- **Claim 1** (`docs/working/research-2026-11-19-a8-token-measurement.md:24`, `manifest.json:4`, `results.md:16-17`): 82accdd7 also touched `workflows/pr-prep.md` and two `docs/working/` files. Say "did not touch `SKILL.md`" or "within the skill, only `references/rubric.md`".
- **Claim 4** (`docs/working/research-2026-11-19-a8-token-measurement.md:57-58`): the block is first in the orchestrator's prompt, but on the wire ~49.5k chars of harness reminders precede it and no breakpoint ends at it. "Cacheable" holds only for its position.
- **Claim 7** (`csp/code-review-rubric-2026-11-19-csp.md:28`, `results.md:111-114`): the canon ledger has N7 "pending demotion adjudication", not demoted. Also say "A4's worker half should not be credited", not "A4".
- **Claim 12** (`results.md:67-69`, `token-ledger.md:26-27`): the final calls of r1 and r2 (read 18,900) and of api (read 0) came after gaps longer than 5 minutes and did not re-read their own prefix. Add "except after a gap longer than the cache lifetime".

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-2026-11-19-a8-token-measurement/docs/reviews/code-fact-check-report-2026-11-19-a8-pass2.md, with `Commit: 3d8cabb3` as its first line and `**Replication:** k=1 (loop pass, decision 031)` in its header, structured per the code-fact-check skill.
- Answered: yes. All corrections for previous Claims 2-16 are applied, and their figures recompute. The fix for previous Claims 10/16 added one new error (13a). The fixes for previous Claims 2 and 4 need a qualifier (7, 1). Claims 4 and 12 are new findings in corrected paragraphs.
- Out of scope: the research doc's unchanged claim that read-by-path costs "a few hundred tokens" more than pasting (`:57`; no paste arm exists to check it); the measured pass's own review artifacts in `csp/`, beyond the two changed rubric cells.
- Escalate: nothing. Optionally, the canon ledger's N7 "pending demotion adjudication" could be settled, since this pass now relies on N7 being a false positive.
