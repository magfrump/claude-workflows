Commit: 123432af

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-token-measurement (branch measure/a8-token-measurement)
**Scope:** `runs/review-arms/a8-2026-11-19/results.md`, `docs/working/research-2026-11-19-a8-token-measurement.md`, `runs/review-arms/a8-2026-11-19/token-ledger.md`, `runs/review-arms/a8-2026-11-19/manifest.json` (replicate r1 of 3)
**Checked:** 2026-11-19
**Total claims checked:** 35
**Summary:** 22 verified, 9 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Primary records used: the 9 sub-agent transcripts (JSONL under `/tmp/claude-1000/-workspace/a2588790-deaf-4649-9915-f641c00b3dd0/tasks/`), the orchestrator transcript's task notifications (`/home/node/.claude/projects/-workspace/711f86df-792b-492f-9d5e-95022839ec2c.jsonl`), the baseline files under `runs/review-arms/baseline-2026-08-06/`, `docs/working/canon-issue-ledger.md`, the measured pass's `csp/` artifacts, and `git show d4e362de:skills/<name>/SKILL.md`. No hallucination-pattern log exists in this repo (`docs/reviews/hallucination-patterns.md` absent), so no pattern comparison applies.

Captured outputs (all three commands ran at 2026-11-19T18:54:52Z, each exit 0):
- `python3 -I /tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/agg.py <tasks dir>` (cwd: the tasks dir). It dedupes `message.usage` by `requestId` and hashes each first prompt before `"\n---\n\n## Your role"`. Output: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`
- `rg -o '<subagent_tokens>…<duration_ms>[0-9]+' 711f86df-….jsonl | sort -u` (cwd: `/home/node/.claude/projects/-workspace/`). Output: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-notifications.txt`
- an arithmetic recomputation run with `python3 -I -c` (cwd: the worktree). Output: `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`

---

## Claim 1: "Rubric row A8 (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`) says … rests on a pre-change projection (~5.3%, …levers-3-4-measurement.md), and that inlining the enclosing files adds prompt tokens each agent previously fetched selectively."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:8-12`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's location and its content. Does not establish that row A8 reads the skill's "0% of token count" line correctly (see Claim 29b).
**Legibility-target:** for-orchestrator-synthesis

Row 35 reads: `is not established for the newly inlined enclosing-file half — inlining adds real prompt tokens each agent previously fetched selectively; the 5.3% figure is a pre-change projection` (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`). The levers doc gives `≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost, 0% of token count` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:48`).

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:33-48`

---

## Claim 2: "range `d86d2dc..d90d6bb` … 2 files, +72/-1. Baseline per-cell core = 358,626 tokens (fc k=1 74,274 + security 77,879 + performance 67,010 + api 68,604 + architecture 70,859). The test-strategy gap-fix (65,894) … is NOT in the 359k per-cell figure, but is in the 2.99M canon total." / "Baseline delivery was self-read … shared prefix ~330 tokens"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:17-23`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the diff stat, the five baseline figures and their sum, where the gap-fix is counted, and the self-read delivery. Does not establish that baseline agents read exactly the same files as today's inlined block.
**Legibility-target:** for-orchestrator-synthesis

`git diff --shortstat d86d2dc..d90d6bb` in `/workspace/external/meta-formalism-copilot` prints `2 files changed, 72 insertions(+), 1 deletion(-)`. Baseline ledger rows: `| csp | 74,274 | 11 |` (`runs/review-arms/baseline-2026-08-06/token-ledger.md:16`), `| csp | performance | 67,010 |` (`:47`), `| csp | api-consistency | 68,604 |` (`:48`), `| csp | architecture | 70,859 |` (`:49`), `| csp | security | 77,879 |` (`:80`), `| csp | test-strategy | 65,894 | advisory: 6 Consider → 🟢 (gap-fix;` (`:82`). They sum to 358,626, which matches `csp 359k` (`results.md:20`). On the gap-fix: `Totals above include the gap-fix` (`runs/review-arms/baseline-2026-08-06/results.md:44`). On delivery: `critic agents are given a scope spec and **self-read** the diff … (~330 tokens)` (`levers-3-4-measurement.md:26-28`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/token-ledger.md:16,47-49,80-84`, `runs/review-arms/baseline-2026-08-06/results.md:20,44`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-28`

---

## Claim 3: "Today's skill (`skills/code-review/SKILL.md`, last changed 82accdd7, 2026-11-14)"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:24` (same claim at `runs/review-arms/a8-2026-11-19/manifest.json:4` and `runs/review-arms/a8-2026-11-19/results.md:16`)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which commit last changed `skills/code-review/SKILL.md`. Does not establish whether the author meant the skill directory, where 82accdd7 is the last change.
**Legibility-target:** for-author

`git log -- skills/code-review/SKILL.md` names `44724747 docs(review): address review iteration 1` (2026-11-14 11:20) as the last commit to touch the file. `82accdd7` is its child, four minutes later. Its stat touches `skills/code-review/references/rubric.md`, `workflows/pr-prep.md` and two docs, not `SKILL.md`. `git diff 82accdd7 HEAD -- skills/code-review/SKILL.md` is empty, so the content the agents ran is the same either way. The precise wording would be "SKILL.md last changed 44724747; skill directory last changed 82accdd7".

**Evidence:** `skills/code-review/SKILL.md` (git log), commit `82accdd7` (git show --stat)

---

## Claim 4: "Tokens: the `total_tokens` each Agent task notification reports"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:40`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field's name in the task notifications. Does not establish anything about the values (Claim 33 covers those).
**Legibility-target:** for-author

The notifications carry `<usage><subagent_tokens>90196</subagent_tokens><tool_uses>9</tool_uses><duration_ms>483954`, and there is no `total_tokens` field. `results.md:23` and `manifest.json:61` name the field correctly as `subagent_tokens`, and so does the baseline (`Tokens = subagent_tokens from task notifications`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:3`). The instrument is the same; only the name is wrong here.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-notifications.txt`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:3`

---

## Claim 5: "instead of my pasting ~25-34 KB of skill text into each prompt" / "Pasting … costs ~60k orchestrator output tokens and risks transcription drift over 190 KB"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:55-56,74-75`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the current byte sizes of the six skill files the 9 agents read. Does not establish what the "190 KB" figure was meant to count.
**Legibility-target:** for-author

`wc -c` gives code-fact-check 32,228, security-reviewer 34,021, performance-reviewer 23,941, api-consistency-reviewer 22,753, architecture-review 27,564 and test-strategy 14,504 bytes. The per-prompt range is therefore 14.5-34 KB, not 25-34 KB. Pasting into all 9 prompts would come to 251,695 bytes (≈63k tokens at chars/4), and the six distinct texts total 155,011 bytes. The "~60k" fits the 9-prompt total, but "190 KB" matches neither count (paraphrased — no quote available because these are byte counts from `wc -c`, recorded in `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`).

**Evidence:** `skills/code-fact-check/SKILL.md`, `skills/security-reviewer/SKILL.md`, `skills/performance-reviewer/SKILL.md`, `skills/api-consistency-reviewer/SKILL.md`, `skills/architecture-review/SKILL.md`, `skills/test-strategy/SKILL.md`

---

## Claim 6: "for all 9 agents the notified `subagent_tokens` equals the transcript's last API call's input + cache-creation + cache-read + output … Every agent's first call read 18,900 cached tokens … and wrote 32.8k-33.8k fresh"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:91-95`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claims 12 and 21. Does not establish how the baseline's figures were produced, beyond the baseline ledger naming the same field.
**Legibility-target:** for-orchestrator-synthesis

See Claims 12 and 21. On the hedge "I assume the baseline's figures came from the same field": the baseline ledger states it outright (`Tokens = subagent_tokens from task notifications`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:3`).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-notifications.txt`

---

## Claim 7: "Scratch worktree … removed at the end" / "the Stage 2.5 agent reused that copy … its logs are kept under `csp/fc-r3-logs/` and `csp/stage25-logs/`"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:34-36,96-99`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that no scratch worktree of meta-formalism-copilot is still registered and that both log directories exist. Does not establish that r3's own scratch copy was deleted (it lived outside any tracked tree).
**Legibility-target:** for-orchestrator-synthesis

`git -C /workspace/external/meta-formalism-copilot worktree list` shows only the main checkout and the baseline's `wt-*` worktrees, with none in a scratchpad. `csp/fc-r3-logs/` holds 15 files (build, start, vitest, eslint, html captures) and `csp/stage25-logs/` holds 4 (paraphrased — no quote available because this claim is about directory layout).

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/fc-r3-logs/`, `runs/review-arms/a8-2026-11-19/csp/stage25-logs/`

---

## Claim 8: manifest `tokens` map and `totals` (fc 100,755 / 90,196 / 121,024; stage1 311,975; critics; stage2 431,780; stage 2.5 108,530; core 743,755; total 852,285; agents 9; baseline 358,626 / 424,520)

**Location:** `runs/review-arms/a8-2026-11-19/manifest.json:23-37,50-59`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every figure against the task notifications and the baseline ledger, plus every sum. Does not establish that the notification field measures cost (see Claim 12).
**Legibility-target:** for-orchestrator-synthesis

Each of the 9 notified values appears in the orchestrator's notifications (`<subagent_tokens>100755` … `<subagent_tokens>108530`). The sums recompute exactly: 311,975, 431,780 (with test-strategy), 743,755 and 852,285. 358,626 + 65,894 = 424,520.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-notifications.txt`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`

---

## Claim 9: `"shared_block_bytes": 8755`, `"shared_block_stage2_bytes": 11716`, `"prompt_prefix_sha256_16"` (be4a2600985537d5 3/3; 42374933a2ebe4a1 5/5), `"first_call_cache_read_tokens": "18,900 on all 9 agents"`

**Location:** `runs/review-arms/a8-2026-11-19/manifest.json:13,41-46`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence as Claims 20 and 21. Does not establish the "system+tools only" attribution of the 18,900 (see Claim 18).
**Legibility-target:** for-orchestrator-synthesis

See Claims 20 and 21. `wc -c` gives `8755 …/csp/shared-block.md` and `11716 …/csp/shared-block-stage2.md`.

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/shared-block.md`, `runs/review-arms/a8-2026-11-19/csp/shared-block-stage2.md`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`

---

## Claim 10: "Row A8 … says the code-review skill's claim about inlining the shared review context (decision 032 lever #3: "zero effect on recall", "0% of token count", "leave it on because it is free", `skills/code-review/SKILL.md:276-354`) rests on a pre-restructure projection (~5.3% of input cost …)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:7-12`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the three quoted phrases sit inside `SKILL.md:276-354` and that the row says what is attributed to it. Does not establish that "0% of token count" is a claim about the inlining's cost; in the skill it describes the caching benefit (see Claim 29b).
**Legibility-target:** for-orchestrator-synthesis

`is unchanged, so it has **zero effect on recall** (decision 032 H1).` (`skills/code-review/SKILL.md:277`). `**Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a billing-rate effect, not a token-count reduction). Leave it on because it is free;` (`skills/code-review/SKILL.md:352-353`).

**Evidence:** `skills/code-review/SKILL.md:268-354`, `docs/reviews/code-review-rubric-2026-08-07-main.md:35`

---

## Claim 11: "k=3 fact-check, 5 critics (…; ui-visual not selected, as in the baseline), Stage 2.5 for 6 routed endorsement claims … All agents on opus."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:16-19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the agent roster, the models and the count of routed claims. Does not establish that the Stage 1.5 gating decisions were correct.
**Legibility-target:** for-orchestrator-synthesis

Every assistant record in all 9 transcripts carries `"model":"claude-opus-5-5"`. The submitted-claims report has `**Submitted by:** security-reviewer` ×3, `performance-reviewer` ×1 and `api-consistency-reviewer` ×3 entries, of which one (S5) is split into 23a/23b. That makes 6 submitted claims: `**Total claims checked:** 7 (6 submitted; S5 split into 23a/23b)` (`csp/code-fact-check-submitted-claims.md:8`). In the baseline, ui-visual was a candidate and was gated out: `| csp | … | ui-visual (tsx change is header/nonce plumbing…)` (`runs/review-arms/baseline-2026-08-06/token-ledger.md:32`).

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/code-fact-check-submitted-claims.md:8-216`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:32`

---

## Claim 12: "for all 9 agents it equals the **last API call's** input + cache-creation + cache-read + output tokens. It measures the final context size, not the tokens processed over the agent's run."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:23-26`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 9 agents' last deduplicated API call against their notified figure. Does not establish that the same identity held for the August baseline, which left no transcripts.
**Legibility-target:** for-orchestrator-synthesis

After deduplicating by `requestId`, each agent's last call sums to its notified value: r1 100755, r2 90196, r3 121024, security 103326, performance 78987, api 88378, architecture 81399, test-strategy 79690, stage-2.5 108530. Each value is also that agent's maximum per-call total, so it is the final context and not a sum over calls (paraphrased — no quote available because these are aggregates computed over large JSONL transcripts that must not be printed).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`

---

## Claim 13: §1 table: fact-check 311,975 ×4.20; per-replicate 103,992 +40%; 4 critics 352,090 vs 284,352 +23.8%; per-critic +33/+18/+29/+15%; test-strategy 79,690 vs 65,894 +21%; core 743,755 vs 358,626 / 424,520 ×2.07 / ×1.75; k=1-equivalent 535,772 vs 424,520 +26%; Stage 2.5 108,530; all 852,285

**Location:** `runs/review-arms/a8-2026-11-19/results.md:28-38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell's arithmetic against the notified and baseline figures. Does not establish that the baseline and today's counts measure the same thing per agent, given the delivery and skill changes.
**Legibility-target:** for-orchestrator-synthesis

The recomputed values are 4.2003, 103,991.7, 1.4001, 1.2382, [1.3268, 1.1787, 1.2882, 1.1487], 1.2094, 2.0739, 1.7520, 535,771.7 and 1.2621 (paraphrased — no quote available because these are computed values, recorded in `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:16,47-49,80,82`

---

## Claim 14: "Of the +385k core increase over the 359k per-cell figure, about 208k is k=3 …, about 80k is test-strategy now running in the first wave, and the remainder (~97k, +26% at k=1-equivalent) is per-agent growth."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:40-42`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three-way split and the parenthetical's percentage. Does not establish a causal attribution of the growth.
**Legibility-target:** for-author

The split figures recompute as 385,129, 207,983 and 97,456. The parenthetical "+26% at k=1-equivalent", however, belongs to a different quantity. The k=1-equivalent comparison (table row `:36`) is 535,772 − 424,520 = +111,252 (+26.2%), and that comparison includes test-strategy's own growth (+13,796). The ~97k remainder excludes that growth, because it books all 79,690 test-strategy tokens as new. Against the 358,626 base it is +27.2%. The precise version would read "~97k (+27% of the 359k per-cell figure; ~111k / +26% if the baseline's test-strategy gap-fix is counted)".

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`, `runs/review-arms/a8-2026-11-19/results.md:36`

---

## Claim 15: "The inlined shared block is 8,755 bytes (≈2.2k tokens) in the Stage-1 prompts and 11,716 bytes (≈2.9k tokens, with the fact-check summary) in the Stage-2 prompts: 23.4k tokens over the 8 core agents, **≈3% of the core total**."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:44-47`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block sizes and the sum over the 8 core agents. Does not establish the net token effect of inlining compared with self-reading.
**Legibility-target:** for-author

The byte sizes are right (Claim 9). The 8 core agents are 3 Stage-1 replicates on the 8,755-byte block and 5 Stage-2 critics on the 11,716-byte block: 3×2,189 + 5×2,929 = 21,211 tokens, 2.85% of 743,755. The stated 23.4k is 8×2,929 = 23,432, which applies the Stage-2 size to the three replicates as well. "≈3%" still holds (2.85% vs 3.15%), but the 23.4k figure should read ≈21.2k.

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/shared-block.md`, `runs/review-arms/a8-2026-11-19/csp/shared-block-stage2.md`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`

---

## Claim 16: "Skill-text growth since 2026-08-06 adds ≈2.9k (code-fact-check), 2.6k (security), 0.8k (performance) and under 0.3k (the other three) per agent."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:47-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the SKILL.md byte deltas between d4e362de and HEAD at chars/4. Does not establish growth in the skills' reference files or in the code-review skill itself (+865 tokens), which the orchestrator reads, not the agents.
**Legibility-target:** for-orchestrator-synthesis

`git show d4e362de:skills/<name>/SKILL.md | wc -c` compared with the current file gives code-fact-check 20,519→32,228 (+2,927 tok), security-reviewer 23,453→34,021 (+2,642), performance-reviewer 20,629→23,941 (+828), api-consistency-reviewer +53, architecture-review +255 and test-strategy +43 (paraphrased — no quote available because these are byte counts from `wc -c`, not file text).

**Evidence:** `skills/code-fact-check/SKILL.md`, `skills/security-reviewer/SKILL.md`, `skills/performance-reviewer/SKILL.md`, `skills/api-consistency-reviewer/SKILL.md`, `skills/architecture-review/SKILL.md`, `skills/test-strategy/SKILL.md` (vs `d4e362de`)

---

## Claim 17: "Each critic grew 10.5k to 25.4k tokens, so 5k to 20k per agent is explained by neither."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:48-49`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the critics' growth and the residue after subtracting the Stage-2 block and each skill's growth. Does not establish the fact-check replicates' residue, which is larger.
**Legibility-target:** for-author

The growth figures recompute as security +25,447, performance +11,977, api +19,774, architecture +10,540 and test-strategy +13,796, so "10.5k to 25.4k" is right. Subtracting 2,929 (block) and each skill's growth leaves 19,876 / 8,220 / 16,792 / 7,356 / 10,824. The precise range is ≈7.4k-19.9k, not 5k-20k. The fact-check replicates, at a mean +29.7k minus 2.2k and 2.9k, leave ≈24.6k unexplained, above the stated top.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`

---

## Claim 18: "Every agent's first call already holds ~52k tokens before it does any work: 18.9k of system prompt and tools, ~30k of injected session context and ~3k of my prompt."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:50-52`
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the first-call totals and the prompt length. Does not establish how the 18.9k and ~30k break down, because the transcripts do not contain the system prompt or the injected context.
**Legibility-target:** for-orchestrator-synthesis

The first-call input recomputes as 2 + 18,900 + 32,797…33,788, which is 51.7k-52.7k, and the dispatched prompts are 11,855-13,745 characters (≈3.0-3.4k tokens). Both match. The attribution of 18,900 to "system prompt and tools" and ~30k to "injected session context" is an inference: the JSONL records only usage counts for those parts. Confirming it would need the request bodies or a token count of the system prompt (paraphrased — no quote available because these are aggregates computed from transcripts that must not be printed).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`

---

## Claim 19: "Shared block 2.2k / 2.9k tokens against the 25k budget: 9% / 12% of it."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:56-57`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arithmetic. Note that the skill's budget gates part-5 material only, so whole-block ratios slightly overstate budget use. Does not establish anything beyond the arithmetic.
**Legibility-target:** for-orchestrator-synthesis

2,189/25,000 = 8.8% and 2,929/25,000 = 11.7%. The budget is stated as `Budget: 25,000 tokens, estimated as chars/4` (`skills/code-review/SKILL.md:328`).

**Evidence:** `skills/code-review/SKILL.md:328`

---

## Claim 20: "the shared part of every prompt hashes the same (Stage 1: `be4a2600985537d5` ×3; Stage 2: `42374933a2ebe4a1` ×5, equal to `csp/shared-block-stage2.md`)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:58-59`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first 16 hex characters of the sha256 of each first prompt before `"\n---\n\n## Your role"`, for all 9 agents. Does not establish identity beyond that marker.
**Legibility-target:** for-orchestrator-synthesis

The hashes are r1/r2/r3 `be4a2600985537d5` and security/performance/api/architecture/test-strategy `42374933a2ebe4a1`. Stage 2.5 hashes to `be4a2600985537d5`, the Stage-1 block. The whole-file sha256 of `csp/shared-block-stage2.md` starts `42374933a2ebe4a1`, and of `csp/shared-block.md` starts `be4a2600985537d5`. The Stage-2 block begins with the full 8,745-character Stage-1 block, so all 9 prompts share their first 8,745 characters.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`, `runs/review-arms/a8-2026-11-19/csp/shared-block.md`, `runs/review-arms/a8-2026-11-19/csp/shared-block-stage2.md`

---

## Claim 21: "Each agent's first call read exactly 18,900 cached tokens … and wrote 32.8k-33.8k fresh, shared block included. This held for all 9 agents. … and for the Stage 2.5 agent too, which was dispatched alone long after Stage 1 with the same first 8.7k characters."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:60-65`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each agent's first deduplicated call. Does not establish why the cache missed (Claim 22a). One detail weakens a pure parallel-dispatch reading: r3's first call returned about 5.5 s after r1's and r2's (17:05:10 vs 17:05:04), and it also read only 18,900.
**Legibility-target:** for-orchestrator-synthesis

The first-call values are `cache_read` 18,900 on all 9 agents and `cache_creation` 32,797 (r1, r2, r3), 33,788 (security), 33,740 (performance), 33,774 (api), 33,757 (architecture), 33,725 (test-strategy) and 33,214 (stage 2.5). Stage 2.5's first call came at 18:34:06, after the last critic had finished (api, 18:33:03), and its prompt prefix is the 8,745-character Stage-1 block (paraphrased — no quote available because these are aggregates computed from transcripts that must not be printed).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`

---

## Claim 22a: "Two: there is no cache breakpoint at the end of the shared block, because block and tail are one prompt, and a prefix can only hit at a breakpoint."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:66-69`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about where the Agent-tool path places breakpoints. Does not establish either explanation, as the file itself says.
**Legibility-target:** for-orchestrator-synthesis

Breakpoint placement on the Agent-tool request path is not visible in the transcripts. Testing it would need the request bodies or the two-agent probe that `results.md:116-119` proposes (paraphrased — no quote available because the claim concerns external API behavior, not code in this repo).

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:116-119`

---

## Claim 22b: "Stage 2.5 rules out the first as the only cause, but its gap from Stage 1 also exceeded the default 5-minute cache lifetime."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:69-70`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timing gap. Does not establish the cache TTL the harness actually used (the 5-minute default is general API knowledge, not checked here).
**Legibility-target:** for-orchestrator-synthesis

Stage 1's last call was at 17:13:24 and Stage 2.5's first at 18:34:06, a gap of about 81 minutes. The Stage-2 critics started at 17:19:07, about 5m43s after Stage 1's last call (paraphrased — no quote available because these are transcript timestamps from aggregates).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`

---

## Claim 23: "The baseline's largest cell (corpus, ~17.4k tokens of diff + fact-check)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:71-72`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the measured diff+fact-check size. Does not establish the corpus cell's size with enclosing files under today's assembly.
**Legibility-target:** for-orchestrator-synthesis

`| corpus (app/) | 69,575 | 17,394 | 6 | 78,273 |` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:43`), the largest row in that table.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:36-46`

---

## Claim 24: §3 label table (R1-A4: today's rubric item, sources, replicate agreement; baseline hit/miss)

**Location:** `runs/review-arms/a8-2026-11-19/results.md:76-85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row against canon lines 92-97, today's rubric, the merged fact-check report and the baseline results. Does not establish that the canon's csp label set is limited to these six (see Claim 28: N1 and N7 are also csp rows).
**Legibility-target:** for-orchestrator-synthesis

Canon: `| csp-R1 | \`connect-src 'self'\` blocks the \`data:\`/blob fetch in \`exportGraph.ts\`` … `| csp-A4 | No tests pin the CSP directive list |` (`docs/working/canon-issue-ledger.md:92-97`). The rubric maps today's items as R1 → `| R1 | … | Breaking (api), Incorrect high behavioral (fc 3/3) |` (`csp/code-review-rubric-2026-11-19-csp.md:15`), A6 Edge (`:30`), A7 Tailwind (`:31`), A5 layout comment (`:29`), A1 and A8 (`:25,32`), and C6 G1 (`:49`). In the merged report the replicate verdicts are `r1=Incorrect · r2=Incorrect · r3=Incorrect` for Claims 8, 9, 6 and 2 (`csp/code-fact-check-report.md:141,166,109,43`). The baseline gives `R1 gold connect-src/\`data:\` HIT** (security Medium); R2 Edge-runtime doc **miss**`, A1 `arch **Structural 🔴**`, A3 `(perf Medium)`, `A2 style-src partial` and A4 `(gap-fix…)` (`runs/review-arms/baseline-2026-08-06/results.md:26`). For "unfound by any arm before": `csp-A2 — unfound by any arm at any rep` (`docs/working/canon-issue-ledger.md:409`).

**Evidence:** `docs/working/canon-issue-ledger.md:92-97,409`, `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md:15-49`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md:43,109,141,166`, `runs/review-arms/baseline-2026-08-06/results.md:26`

---

## Claim 25: "6/6 hit, against 4 hits + 1 partial in the baseline."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:87`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the Stratum-A six only. The baseline count includes A4 via the gap-fix. Does not establish recall on the canon's graduated csp N-rows.
**Legibility-target:** for-orchestrator-synthesis

Baseline: R1 HIT, R2 miss, A1 HIT, A2 partial, A3 HIT, A4 HIT (gap-fix), per `runs/review-arms/baseline-2026-08-06/results.md:26`. That makes 4 hits and 1 partial.

**Evidence:** `runs/review-arms/baseline-2026-08-06/results.md:26`

---

## Claim 26: "The list names every comment claim in the diff (Edge, Tailwind and connect-src among them), as the skill's rich-brief rule asks. It does not name `exportGraph.ts` or any finding."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:89-93`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the three Stage-1 prompts' "Claims that particularly need checking" list. Does not establish that the list covers every comment claim in the diff (not enumerated independently here).
**Legibility-target:** for-author

None of the three fact-check prompts contains `exportGraph`. The list does include `Edge runtime`, `Tailwind v4` and `connect-src 'self' is sufficient`. But the list also carries `proxy.ts: the x-nonce request header lets layouts read the nonce … (does anything read it?)` and a framing rule, `for a claim about what the browser will or will not need under this policy, check the client-side code in the repo that would run under it` (r1's dispatched prompt). Those two lines point at the A1/A8 finding and toward R1's client-side site. "does not name any finding" is therefore slightly too strong. The paragraph's own closing caveat ("might still have been less pointed") covers the spirit of this.

**Evidence:** first record of `a1a8fdb7b815b5808.output`, `adbaabb0018c4f408.output`, `ad528318415ea2cda.output` (tasks dir above)

---

## Claim 27: "r3's executed run shows the nonce **does** reach Next's scripts on self-hosted `next start` (15/15 tags carry it)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:95-98`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the captured `/` response body from r3's run. Does not establish Vercel behavior or other routes.
**Legibility-target:** for-orchestrator-synthesis

A regex count of `<script…>` tags in `csp/fc-r3-logs/root-body.html` gives 15 tags, all 15 with `nonce=`. The no-`headers()` build's body gives 18 tags with 0 nonced, matching the merged report's `a static \`/\` still got a fresh CSP header, with 0/18 scripts nonced` (`csp/code-fact-check-report.md:44`).

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/fc-r3-logs/root-body.html`, `runs/review-arms/a8-2026-11-19/csp/fc-r3-logs/noheaders-body.html`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md:44,60`

---

## Claim 28: "New since the canon … Two findings are new: security found that `Purpose: prefetch` requests get HTML with no CSP (🟡 A2), and the pdf.js worker may be blocked because there is no `worker-src` (🟡 A4)."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:95,98-100`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the two findings already sit in the canon ledger. Does not establish the findings' current truth on the code.
**Legibility-target:** for-author

Both findings are already canon csp rows. The canon ledger also records the second one as a refuted false positive:

```
- **N1** csp: middleware prefetch-skip serves real HTML with no CSP (E5; **fix-confirmed
  `ab4dbdb`**)
...
- N7 csp: no `worker-src` under `'strict-dynamic'` — pdf.js worker blocked/degraded (E6,
  verifier-kept; never fixed at HEAD). **Candidate REFUTED by E7r2** with spec + WPT
  evidence (w3c/webappsec-csp#200: `'strict-dynamic'` blesses worker creation; ...
```
(`docs/working/canon-issue-ledger.md:176-177,185-189`). And at `:70-71`: `it also collected its first confirmed false-positive credit (cubic CLI's csp worker-src claim, 2026-08-18)`. So A2 re-finds graduated N1, and A4 re-asserts the refuted N7, which the ledger scores against an arm as a false positive. Neither is new, and a re-scorer reading this note would credit A4 as a new hit.

**Evidence:** `docs/working/canon-issue-ledger.md:66-72,83,176-177,185-189`, `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md:26,28`

---

## Claim 29a: "The benefit the claim counts on did not appear. No agent read the shared block from cache, so the cost-side saving (single-digit percent of input cost) was 0 here"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:108-109`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cross-agent cache reuse of the shared block on each agent's first call in this one pass. Does not establish loop-pass reuse (the skill's other promised benefit) or within-agent caching on later calls, which reads the block from cache but is not the cross-agent saving.
**Legibility-target:** for-orchestrator-synthesis

See Claim 21. The first-call cache read was 18,900 on all 9 agents, the same figure whatever the prompt, and each first call wrote the 8.7k-character common prefix fresh (cache_creation 32.8k-33.8k). No agent's first call read any of the shared block from cache (paraphrased — no quote available because these are aggregates computed from transcripts that must not be printed).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`

---

## Claim 29b: "**"Free" holds roughly, but it is not 0%.** Inlining put 2.2k-2.9k tokens into each agent's context … **Verdict: fails as stated.** The lever's benefit was 0 here and its token-count effect was small but not zero."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:104-114`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "not 0% / token-count effect not zero" half of the verdict against the skill text and this run's evidence. Does not dispute the "benefit was 0 here" half (Claim 29a), which alone can carry "fails as stated" for the "measured benefit" line.
**Legibility-target:** for-author

In the skill, "0% of token count" describes the caching benefit, not the inlining's cost: `**Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect it to move the token-count ledger.` (`skills/code-review/SKILL.md:352-354`). A measured gross block size of 2.2k-2.9k per agent does not contradict that sentence. The paragraph also concedes that the net token-count effect was not measured: `the net token-count cost is probably near zero, but this pass had no self-read arm to show it` (`results.md:106-107`). The closing "its token-count effect was small but not zero" asserts the very net effect the paragraph just called unmeasured. The precise version: the gross inlined size is ≈21k tokens (2.85% of core), and the net token-count effect against self-read is unmeasured. The verdict rests on the 0 cross-agent cache benefit. The misreading comes from rubric row A8 (Claim 1), which the research doc repeats (`docs/working/research-2026-11-19-a8-token-measurement.md:9`).

**Evidence:** `skills/code-review/SKILL.md:276-277,352-354`, `runs/review-arms/a8-2026-11-19/results.md:104-114`, `docs/reviews/code-review-rubric-2026-08-07-main.md:35`

---

## Claim 30: "The +24-40% per-agent growth since August is real. Lever #3 accounts for at most 3 of those points."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:110-111`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-agent growth range and the inlined block's size in points of each agent's baseline. Does not establish the net effect of inlining compared with self-reading.
**Legibility-target:** for-author

"+24-40%" spans two aggregates: the 4-critic sum at +23.8% and the fact-check per-replicate mean at +40%. Individual critics grew +15% (architecture) to +33% (security), and test-strategy +21%. Measured in points of each agent's August figure, the block is 2.95 for fact-check (2,189/74,274) but 3.76-4.37 for the critics (2,929 over 77,879 / 67,010 / 68,604 / 70,859), or 4.12 for the 4-critic aggregate. "At most 3 points" holds for the fact-check only. For the critics the bound is about 4-4.4 points. The "≈3%" from Claim 15 is a share of today's total, not points of growth over the baseline.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-arith.txt`, `runs/review-arms/a8-2026-11-19/results.md:31-34`

---

## Claim 31: "The api-consistency critic took 4,439 s of wall clock for 7 tool uses (the others took 106-504 s)." / "The baseline had no executed verdicts."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:126-131`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the notified durations and tool counts. "No executed verdicts" is checked only against the baseline's results and ledger text (`results.md:47` says single pass, static). Does not establish the cause of the long wall clock.
**Legibility-target:** for-orchestrator-synthesis

The api notification shows `<subagent_tokens>88378</subagent_tokens><tool_uses>7</tool_uses><duration_ms>4439191`. The other agents range from 105,706 ms (performance) to 503,686 ms (r3). The api transcript runs from 17:19:09 to 18:33:03.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-notifications.txt`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-transcript-aggregates.txt`

---

## Claim 32: "Tokens = `total_tokens` from each Agent task notification (same instrument as E1/E3 and the 2026-08-06 baseline)." / "8,755 bytes ≈ 2,189 tokens (chars/4)"

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:3-5`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field name and the size estimate. Does not establish anything about the values (Claim 33).
**Legibility-target:** for-author

The notification field is `subagent_tokens` (Claim 4), the same field as the baseline (`Tokens = subagent_tokens`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:3`), so "same instrument" holds but the name is wrong. The block is 8,755 bytes but 8,745 characters (it contains multi-byte characters), so chars/4 = 2,186. The 2,189 figure is bytes/4. That is a negligible difference, but the label is wrong.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-notifications.txt`, `runs/review-arms/a8-2026-11-19/csp/shared-block.md`

---

## Claim 33: ledger rows 1-9 and subtotals (tokens, tool_uses, durations, outcomes; Stage 1 subtotal 311,975 / 57 tools, merged 18 claims 5V/3MA/7I/3U, agreement 9/17; Stage 2 subtotal 431,780 / 35 tools; Stage 2.5 7 entries 5V (3 executed)/1MA/1U/0I)

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:8-22`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every row's tokens, tool uses and duration against the notifications, each outcome cell against the replicate and critic reports' summary lines and severity headings, and the subtotals. Does not establish internal consistency inside r2's own report (its summary line, which the row copies, counts 14 claims while the body has 15 verdicts with 6 Verified).
**Legibility-target:** for-orchestrator-synthesis

The notification triples match all 9 rows: r2 90196/9/483,954 ms, r1 100755/13/488,300, r3 121024/35/503,686, performance 78987/5/105,706, architecture 81399/6/117,435, test-strategy 79690/8/131,477, security 103326/9/243,721, api 88378/7/4,439,191, stage 2.5 108530/17/252,349. Report summaries: r1 `6 verified, 4 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable`, r2 `5 verified, 0 mostly accurate, 0 stale, 7 incorrect, 2 unverifiable`, r3 `11 verified, 2 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable`, merged `**Total claims checked:** 18` / `5 verified, 3 mostly accurate, 0 stale, 7 incorrect, 3 unverifiable` / `Agreement rate: 9/17` (`csp/code-fact-check-report.md:10-11,349`), Stage 2.5 `5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable` with 3 `executed` modes. The critic severity headings match the ledger: security 1 Medium, 2 Low, 7 Informational; api 1 Breaking, 2 Inconsistent, 1 Minor, 2 Informational; architecture 2 Coupling, 3 Minor, 1 Informational; test-strategy G1-G9.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/a8-r1-notifications.txt`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report-r1.md:8-9`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report-r2.md:8-9`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report-r3.md:8-9`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md:10-11,346-349`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-submitted-claims.md:8-9`, `runs/review-arms/a8-2026-11-19/csp/security-review-2026-11-19.md:33-234`, `runs/review-arms/a8-2026-11-19/csp/api-consistency-review-2026-11-19.md:33-149`, `runs/review-arms/a8-2026-11-19/csp/architecture-review-2026-11-19.md:21-150`, `runs/review-arms/a8-2026-11-19/csp/test-strategy-review-2026-11-19.md:18-26`

---

## Claims Requiring Attention

### Incorrect
- **Claim 28** (`runs/review-arms/a8-2026-11-19/results.md:98-100`): The Purpose:prefetch and worker-src findings are not new. They are canon N1 (graduated, fix-confirmed) and N7, which E7r2 refuted and the ledger scores as a false positive (`canon-issue-ledger.md:176-189`). Rewrite the note as "re-found N1; re-asserted refuted N7".
- **Claim 29b** (`runs/review-arms/a8-2026-11-19/results.md:104-114`): The skill's "0% of token count" describes the caching benefit, not the inlining cost, and the run did not measure the net token-count effect. Rest "fails as stated" on the 0 cross-agent cache benefit alone, and call the token effect unmeasured, not "not zero".

### Stale
- none

### Mostly Accurate
- **Claim 3** (`docs/working/research-2026-11-19-a8-token-measurement.md:24`, also `manifest.json:4`, `results.md:16`): `SKILL.md` last changed at 44724747; 82accdd7 changed only the skill's references (content identical).
- **Claim 4** (`docs/working/research-2026-11-19-a8-token-measurement.md:40`): the notification field is `subagent_tokens`, not `total_tokens`.
- **Claim 5** (`docs/working/research-2026-11-19-a8-token-measurement.md:55-56,74-75`): skill texts are 14.5-34 KB each, and the totals are 251.7 KB (9 prompts) or 155 KB (distinct); "190 KB" re-derives from neither.
- **Claim 14** (`runs/review-arms/a8-2026-11-19/results.md:40-42`): the ~97k remainder is +27% of 359k; "+26% at k=1-equivalent" is the +111k comparison against 424,520.
- **Claim 15** (`runs/review-arms/a8-2026-11-19/results.md:46`): the block summed over the 8 core agents is ≈21.2k (3×2,189 + 5×2,929), not 23.4k (8×2,929); ≈3% holds.
- **Claim 17** (`runs/review-arms/a8-2026-11-19/results.md:48-49`): the unexplained residue per critic is ≈7.4k-19.9k, not 5k-20k.
- **Claim 26** (`runs/review-arms/a8-2026-11-19/results.md:91-92`): the brief does not name exportGraph.ts, but "(does anything read it?)" and the client-side-code rule point at A1/A8 and R1.
- **Claim 30** (`runs/review-arms/a8-2026-11-19/results.md:110-111`): +24-40% mixes two aggregates (critics individually +15-33%), and the block is ≈4-4.4 points of critic growth, not "at most 3".
- **Claim 32** (`runs/review-arms/a8-2026-11-19/token-ledger.md:3-5`): field name `subagent_tokens`; 2,189 is bytes/4 (chars/4 = 2,186).

### Unverifiable
- **Claim 18** (`runs/review-arms/a8-2026-11-19/results.md:50-52`): the 18.9k/~30k/~3k split of the first call's input needs the request bodies or a system-prompt token count.
- **Claim 22a** (`runs/review-arms/a8-2026-11-19/results.md:66-69`): breakpoint placement on the Agent-tool path needs the request bodies or the proposed two-agent probe.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-2026-11-19-a8-token-measurement/docs/reviews/code-fact-check-report-2026-11-19-a8-r1.md, with `Commit: 123432af` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: the csp/ review artifacts' own correctness (context only; r2's 14-vs-15 summary miscount noted in Claim 33's scope, not verdicted); the A8 rubric row's reading of "0% of token count" (the row is not under review; flagged via Claim 29b).
- Escalate: (1) Claim 28: the rubric's A4 (pdf.js worker-src) re-asserts canon N7, which the ledger records as refuted and false-positive-scored. Whoever re-scores this pass should treat A4 as an FP candidate, not a new hit. (2) Claim 29b: the §4 verdict should rest on the 0 cross-agent cache benefit, and the skill's "0% of token count" line is not refuted by this run.
