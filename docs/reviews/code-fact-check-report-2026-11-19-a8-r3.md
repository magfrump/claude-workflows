Commit: 123432af

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-token-measurement (branch `measure/a8-token-measurement`)
**Scope:** `docs/working/research-2026-11-19-a8-token-measurement.md`, `runs/review-arms/a8-2026-11-19/manifest.json`, `runs/review-arms/a8-2026-11-19/results.md`, `runs/review-arms/a8-2026-11-19/token-ledger.md` at HEAD 123432af (replicate r3 of 3). `csp/` artifacts, the baseline run files, the canon ledger, skill history and the nine sub-agent transcripts used as primary records only.
**Checked:** 2026-11-19
**Total claims checked:** 39 (36 numbered; 11, 20 and 36 split into a/b)
**Summary:** 25 verified, 10 mostly accurate, 0 stale, 2 incorrect, 2 unverifiable

Method. All arithmetic was redone in python3. The transcripts were parsed with `python3 -I` scripts that print only aggregates. Usage was deduped by `requestId`, and the prompt prefix is the text before `"\n---\n\n## Your role"`. Scripts and captured outputs are in `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/` (`an.py`→`an.out` usage, hashes and timestamps; `an2` prefix vs `csp/shared-block*.md`; `an3` the fact-check checklist; `an4` tool_use counts and models; `an5` cache reads on calls 2-3; `ar` the arithmetic). They ran with cwd set to that directory, all exit 0, captured 2026-11-19T18:54:01Z. The transcripts live in session-scoped `/tmp`, so this provenance can go stale. The hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) was read. Claim 15 resembles the logged class "doc cites a specific count that the source does not hold" (entries at lines 26-30) but is a derivation error, not a fabrication. I did not modify the log, since this run is read-only.

Key aggregates (from `an.out`). The last-call input+cache_creation+cache_read+output totals are r1 100,755, r2 90,196, r3 121,024, security 103,326, performance 78,987, api 88,378, architecture 81,399, test-strategy 79,690 and Stage 2.5 108,530. On the first call, every agent shows cache_read 18,900. First-call cache_creation is 32,797 (×3, Stage 1), 33,788 / 33,740 / 33,774 / 33,757 / 33,725 (Stage 2) and 33,214 (Stage 2.5). Prefix hashes are `be4a2600985537d5` for r1-r3 and Stage 2.5 (8,745 chars / 8,755 bytes) and `42374933a2ebe4a1` for the five critics (11,696 chars / 11,716 bytes).

---

## Claim 1: "Baseline per-cell core = 358,626 tokens (fc k=1 74,274 + security 77,879 + performance 67,010 + api 68,604 + architecture 70,859). The test-strategy gap-fix (65,894) ran later and is NOT in the 359k per-cell figure, but is in the 2.99M canon total."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:19-21` (also `manifest.json:5,57-58`; `results.md:30-35`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the six baseline csp figures, their sum and which total includes the gap-fix. It does not establish that the baseline notifications themselves were recorded correctly.
**Legibility-target:** for-orchestrator-synthesis

Baseline ledger rows: `| csp | 74,274 | 11 |`, `| csp | performance | 67,010 |`, `| csp | api-consistency | 68,604 |`, `| csp | architecture | 70,859 |`, `| csp | security | 77,879 |` and `| csp | test-strategy | 65,894 | advisory: 6 Consider → 🟢 (gap-fix;` (`runs/review-arms/baseline-2026-08-06/token-ledger.md`). The baseline results give "csp 359k" as the per-cell core (`baseline-2026-08-06/results.md:19`) and say "Totals above include the gap-fix" (`results.md:37`). Recomputed: 74,274+284,352 = 358,626, and +65,894 = 424,520 (`ar.out`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/token-ledger.md`, `runs/review-arms/baseline-2026-08-06/results.md:19,37`

---

## Claim 2: "2 files, +72/-1"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diffstat of `d86d2dc..d90d6bb`. It does not establish anything about the content of the hunks.
**Legibility-target:** for-orchestrator-synthesis

I ran `timeout 20 git -C /workspace/external/meta-formalism-copilot diff --shortstat d86d2dc..d90d6bb` (cwd /workspace, exit 0, 2026-11-19 about 18:50Z). Output: `2 files changed, 72 insertions(+), 1 deletion(-)` (`app/layout.tsx`, `proxy.ts`). The output is quoted here in full, with no separate log, because this run may write only this file.

**Evidence:** `/workspace/external/meta-formalism-copilot` diff `d86d2dc..d90d6bb`

---

## Claim 3: "Baseline delivery was self-read ... (levers-3-4 doc: shared prefix ~330 tokens)."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:22-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the levers doc states. It does not independently re-measure the August prompts.
**Legibility-target:** for-orchestrator-synthesis

`critic agents are given a scope spec and **self-read** the diff, enclosing files, and the fact-check report via tools. The genuinely byte-identical shared *prompt prefix* was my ~250-word instruction block (~330 tokens).` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:26-28`)

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-31`

---

## Claim 4: "Today's skill (`skills/code-review/SKILL.md`, last changed 82accdd7, 2026-11-14)"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:24` (also `manifest.json:4`; `results.md:16` "Today's skill (82accdd7)")
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the commit history of `skills/code-review/`. It does not establish whether the rubric.md change in 82accdd7 affected this run.
**Legibility-target:** for-author

`git log -1 -- skills/code-review/SKILL.md` gives `44724747 2026-11-14 docs(review): address review iteration 1`. 82accdd7 touched only `skills/code-review/references/rubric.md` among the skill files (`git show --stat 82accdd7`). 82accdd7 is the last change to the skill **directory** (`git log -1 -- skills/code-review/` → `82accdd7`), and its date of 2026-11-14 is correct. The precise wording is "skill directory last changed 82accdd7; SKILL.md last changed 44724747". results.md:16 is accurate as written.

**Evidence:** git history of `skills/code-review/SKILL.md` and `skills/code-review/`

---

## Claim 5: "adds Stage 2.5 (submitted-claims fact-check) when critics route endorsement claims; Stage 2.5 did not exist on 2026-08-06."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:26-27` (also `results.md:37`)
**Type:** Staleness / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the code-review SKILL.md text at d4e362de. It does not establish what other files of that date said.
**Legibility-target:** for-orchestrator-synthesis

Executed check (paraphrased — no quote available because this claim is about the absence of text, so there are zero grep hits to quote): `git show d4e362de:skills/code-review/SKILL.md | grep -c -i -E 'stage 2\.5|submitted claim'` returns 0, and the same grep on the current SKILL.md returns 10.

**Evidence:** `git show d4e362de:skills/code-review/SKILL.md`, `skills/code-review/SKILL.md`

---

## Claim 6: "Scratch worktree ... never in this repository's tree; removed at the end."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:34-36`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the benchmark repo's registered worktrees now. It does not establish where the worktree sat while the run was going.
**Legibility-target:** for-orchestrator-synthesis

I ran `timeout 20 git -C /workspace/external/meta-formalism-copilot worktree list` (exit 0). It lists 11 entries: the main checkout plus 10 under `runs/review-arms/baseline-2026-08-06/wt-*`. No scratchpad worktree remains (paraphrased — no quote available because the claim is about an absent entry).

**Evidence:** `git worktree list` of `/workspace/external/meta-formalism-copilot`

---

## Claim 7: "Tokens: the `total_tokens` each Agent task notification reports" / "Tokens = `total_tokens` from each Agent task notification (same instrument as E1/E3 and the 2026-08-06 baseline)"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:39-40` (also `token-ledger.md:3-4`; contrast `results.md:23`, `manifest.json:61`)
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the field name used across the four files and the baseline. It does not establish the notification's actual field name, because the notifications are not in the records available to me.
**Legibility-target:** for-author

The four files name the instrument two ways. The ledger and research doc say `total_tokens`. results.md:23 says "`subagent_tokens` from each task notification (same field as the baseline)", and the baseline ledger says "Tokens = subagent_tokens from task notifications" (`baseline-2026-08-06/token-ledger.md:3`). The values match the transcripts (Claim 10), so the substance holds, but the files should use a single field name.

**Evidence:** `token-ledger.md:3`, `results.md:23`, `manifest.json:61`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:3`

---

## Claim 8: "instead of my pasting ~25-34 KB of skill text into each prompt" / "Pasting ... costs ~60k orchestrator output tokens and risks transcription drift over 190 KB"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:55-56,73-75`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the current SKILL.md byte sizes of the six skills dispatched. It does not establish the rationale's tool-call-overhead estimate ("a few hundred tokens").
**Legibility-target:** for-author

Measured with `wc -c`: code-fact-check 32,228, security-reviewer 34,021, performance-reviewer 23,941, api-consistency-reviewer 22,753, architecture-review 27,564, test-strategy 14,504. The per-prompt range is therefore 14.5-34 KB, not 25-34 KB, because test-strategy is 14.5 KB. Pasting into all 9 prompts totals 251,695 bytes (≈62.9k tokens), consistent with "~60k". "190 KB" matches neither that total, nor the 8 core prompts (219,467 bytes), nor the distinct texts (155,011 bytes) (paraphrased — no quote available because these are sums computed in `ar`-style one-liners over `wc -c` output).

**Evidence:** `skills/{code-fact-check,security-reviewer,performance-reviewer,api-consistency-reviewer,architecture-review,test-strategy}/SKILL.md`

---

## Claim 9: "Skill versions: today's critic skills from this branch's tree (= main at 4330e303)"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:64-65`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers `skills/` at HEAD vs 4330e303. It does not establish that the agents read the files at the moment they were in that state, beyond the absence of any skills commit on the branch.
**Legibility-target:** for-orchestrator-synthesis

`git merge-base HEAD main` → `4330e303`, and `git diff 4330e303 HEAD -- skills/` is empty (0 lines). The branch's single commit is `123432af measure(a8): ...` (paraphrased — no quote available because the claim concerns an empty diff).

**Evidence:** `git diff 4330e303 HEAD -- skills/`

---

## Claim 10: "for all 9 agents the notified `subagent_tokens` equals the transcript's last API call's input + cache-creation + cache-read + output"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:91-92` (also `results.md:23-26`; `token-ledger.md:24-25`; `manifest.json:61`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equality between the ledger's per-agent figures and the deduped last-call sums in all 9 transcripts. It does not establish the notifications' own values directly (I compared against the ledger the orchestrator transcribed), nor that the August baseline used the same quantity, which the doc itself labels an assumption.
**Legibility-target:** for-orchestrator-synthesis

The last-call sums from `an.out` are 100,755 / 90,196 / 121,024 / 103,326 / 78,987 / 88,378 / 81,399 / 79,690 / 108,530, each equal to its ledger row (`token-ledger.md:10-20`). Command: `timeout 120 python3 -I an.py`, cwd `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3`, exit 0, 2026-11-19T18:54:01Z.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/an.out`, `runs/review-arms/a8-2026-11-19/token-ledger.md:10-20`

---

## Claim 11a: "Every agent's first call read 18,900 cached tokens (system + tools) and wrote 32.8k-33.8k fresh"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:94-95` (also `results.md:60-64`; `token-ledger.md:25-26`; `manifest.json:46`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first deduped API call of all 9 transcripts. It does not establish that the 18,900 are specifically system prompt + tools, which is an inference that fits the figure being identical across different prompts.
**Legibility-target:** for-orchestrator-synthesis

From `an.out`, every agent shows `cr 18900` on its first call, with cache_creation between 32,797 and 33,788, which is within 32.8k-33.8k. The first-call input_tokens is 2.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/an.out`

---

## Claim 11b: "so the inlined shared block was never served from cache" / "shared block never served from cache" / "No agent read the shared block from cache"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:95` (also `manifest.json:46`; `results.md:108`)
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cache reads on calls 1-3 of r1, performance and Stage 2.5. It does not establish that the per-agent self-cache read is attributable to lever #3, since it would occur under self-read too.
**Legibility-target:** for-author

The conclusion holds for cross-agent sharing: no agent's first call read the block. Read literally, the claim is false. From the second call on, every agent re-reads its own earlier context, shared block included, from cache. `an5.out`: `r1 [(18900, 32797), (51697, 2861), ...]`, `perf [(18900, 33740), (52640, 11693), ...]`, `s25 [(18900, 33214), (52114, 10571), ...]` (cache_read, cache_creation per call). The precise version is "never served from another agent's cache entry". ledger:26 scopes it correctly to the first call.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/an5.out`

---

## Claim 12: "Fact-check replicate r3 found a pre-installed `node_modules` ... its logs are kept under `csp/fc-r3-logs/` and `csp/stage25-logs/`. ... Total 852,285 tokens over 9 agents, under the 2M stop line."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:96-100` (also `results.md:19,38,129-131`)
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence of both log directories, the existence of `/workspace/external/cc-review-eval/mfc-csp`, and the 852,285 total. It does not establish that r3's scratch copy was deleted.
**Legibility-target:** for-orchestrator-synthesis

`ls` shows `fc-r3-logs/` holding build/start/vitest/eslint logs and `matcher.txt`, and `stage25-logs/` holding `build.log`, `proxy-invoke.log` and others. `/workspace/external/cc-review-eval/mfc-csp` exists. The total recomputes to 743,755+108,530 = 852,285 (`ar.out`).

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/fc-r3-logs/`, `runs/review-arms/a8-2026-11-19/csp/stage25-logs/`, `ar.out`

---

## Claim 13: `"shared_block_bytes": 8755, "shared_block_tokens_est": 2189` / "8,755 bytes ≈ 2,189 tokens (chars/4)" / `"shared_block_stage2_bytes": 11716`

**Location:** `runs/review-arms/a8-2026-11-19/manifest.json:13-14,41` (also `token-ledger.md:5`; `results.md:44-46,57`)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte and char counts of `csp/shared-block.md`, `csp/shared-block-stage2.md` and the dispatched prompt prefixes. It does not establish true tokenizer counts.
**Legibility-target:** for-author

From `an2.out`, `shared-block.md 8755 ... 2186.25` and `shared-block-stage2.md 11716 ... 2924.0` (bytes, chars/4). 2,189 is **bytes**/4 (2,188.75), not chars/4 (2,186.25), because the block has 8,745 chars. The ≈2.2k and ≈2.9k roundings in results.md are right either way. Only the "(chars/4)" label is off.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/an2.out`

---

## Claim 14: Token map and totals (`fc_r1` 100755 ... `stage1_total` 311975, `stage2_total` 431780, `core_total` 743755, `total_tokens` 852285; `baseline_csp_core` 358626, `_with_testgap` 424520)

**Location:** `runs/review-arms/a8-2026-11-19/manifest.json:23-36,50-58` (also `token-ledger.md:13,19,21-22`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every per-agent figure against the transcripts and every sum. It does not establish anything beyond arithmetic consistency.
**Legibility-target:** for-orchestrator-synthesis

Recomputed in `ar.out`: fc 311,975; four critics 352,090; stage 2 = 352,090+79,690 = 431,780; core 743,755; all agents 852,285. The ledger's "4 baseline-comparable critics ... = 352,090" (`token-ledger.md:19`) also matches.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/ar.out`, `an.out`

---

## Claim 15: Byte-identity: `"stage1": "be4a2600985537d5 (3/3 prompts)"`, `"stage2": "42374933a2ebe4a1 (5/5 prompts)"`; "equal to `csp/shared-block-stage2.md`"

**Location:** `runs/review-arms/a8-2026-11-19/manifest.json:42-45` (also `results.md:58-59`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sha256 (first 16 hex) of each dispatched prompt's text before `"\n---\n\n## Your role"`, and equality with both shared-block files. It does not establish byte-identity of anything sent before the user prompt (system prompt, tools).
**Legibility-target:** for-orchestrator-synthesis

`an.out` gives `be4a2600985537d5` for r1, r2 and r3 (and Stage 2.5), and `42374933a2ebe4a1` for all five critics. From `an2.out`, both `shared-block.md` and `shared-block-stage2.md` hash identically to and equal those prefixes (`eq prefix True`). The Stage 2 prefix begins with the full 8,745-char Stage 1 prefix (`s2 startswith s1: True`).

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/an.out`, `an2.out`

---

## Claim 16: A8 row description: inlining claim "zero effect on recall", "0% of token count", "leave it on because it is free", `skills/code-review/SKILL.md:276-354`; ~5.3% projection

**Location:** `runs/review-arms/a8-2026-11-19/results.md:7-12` (also `research-2026-11-19-a8-token-measurement.md:8-12`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted phrases at the cited range and the rubric row at :35. It does not establish the rubric row's own correctness.
**Legibility-target:** for-orchestrator-synthesis

`is unchanged, so it has **zero effect on recall** (decision 032 H1).` (`skills/code-review/SKILL.md:277`). `**Measured benefit is modest — single-digit-% of input cost, 0% of token count** ... Leave it on because it is free` (`SKILL.md:352-353`). The rubric row reads `| A8 | "Leave it on because it is free" / "0% of token count" ... the 5.3% figure is a pre-change projection` (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`). The levers doc states `≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost` (`levers-3-4-measurement.md:48`).

**Evidence:** `skills/code-review/SKILL.md:272-277,352-353`, `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:48`

---

## Claim 17: Setup: range `d86d2dc..d90d6bb`; 5 critics, "ui-visual not selected, as in the baseline"; "Stage 2.5 for 6 routed endorsement claims"; "All agents on opus"; "Running total peaked at 852,285 tokens"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:14-19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the transcripts' model field, the baseline gating row and the submitted-claims count. It does not establish that k=3 and the terminal-pass flag were set as the skill defines, beyond the 3 replicate transcripts.
**Legibility-target:** for-orchestrator-synthesis

`an4.out` shows the model `{'claude-opus-5-5'}` for all 9 agents. The baseline gating row reads `| csp | sec, perf, api, arch, ui | security, performance, api-consistency, architecture | ui-visual (tsx change is header/nonce plumbing` (`baseline-2026-08-06/token-ledger.md`). `**Total claims checked:** 7 (6 submitted; S5 split into 23a/23b)` (`csp/code-fact-check-submitted-claims.md:8`).

**Evidence:** `an4.out`, `runs/review-arms/baseline-2026-08-06/token-ledger.md` (gating table), `runs/review-arms/a8-2026-11-19/csp/code-fact-check-submitted-claims.md:8`

---

## Claim 18: §1 cost table (×4.20; 103,992 mean, +40%; 352,090 vs 284,352, +23.8%; per-critic +33/+18/+29/+15%; test-strategy 79,690 vs 65,894, +21%; core 743,755, ×2.07 / ×1.75; k=1-equivalent 535,772 vs 424,520, +26%; Stage 2.5 108,530; all 852,285)

**Location:** `runs/review-arms/a8-2026-11-19/results.md:28-38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every figure and ratio in the table. It does not establish whether the comparisons are like-for-like (the instrument assumption in Claim 10).
**Legibility-target:** for-orchestrator-synthesis

`ar.out`: `fc 311975 4.2003 0.4001 103991.67`; `c4 352090 284352 0.2382 [0.3268, 0.1787, 0.2882, 0.1487]`; `ts 0.2094`; `core 743755 ... 2.0739 1.7520`; `k1 535771.67 0.2621`. Every rounding matches.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/ar.out`

---

## Claim 19: "Of the +385k core increase over the 359k per-cell figure, about 208k is k=3 ..., about 80k is test-strategy now running in the first wave, and the remainder (~97k, +26% at k=1-equivalent) is per-agent growth."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:40-42`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three-way split and the parenthetical. It does not establish that "per-agent growth" is a single cause.
**Legibility-target:** for-author

The split sums correctly: `inc 385129 k3 extra 207983 rem 97456` (`ar.out`). The parenthetical, however, pairs the ~97k with a percentage from another base. "+26% at k=1-equivalent" is 535,772 vs 424,520, a difference of **111,252**. 97k is +27% of 358,626. The 80k bucket counts all of today's test-strategy as new, although the baseline also spent 65,894 on test-strategy (the gap-fix). Precise version: "remainder ~97k (+27% of the 359k); counting the baseline gap-fix, per-agent growth is ~111k (+26% at k=1-equivalent)".

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/ar.out`

---

## Claim 20a: "The inlined shared block is 8,755 bytes (≈2.2k tokens) in the Stage-1 prompts and 11,716 bytes (≈2.9k tokens ...) in the Stage-2 prompts ... ≈3% of the core total."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:44-47`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block sizes and the ~3% share (2.85% with the correct sum, 3.15% with the stated one). It does not establish the 23.4k sum (Claim 20b).
**Legibility-target:** for-orchestrator-synthesis

`an2.out`: 8,755 and 11,716 bytes. `ar.out`: `sb 21211.25 0.0285`.

**Evidence:** `an2.out`, `ar.out`

---

## Claim 20b: "23.4k tokens over the 8 core agents"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:46-47`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the sum of the shared block over the 3 Stage-1 and 5 Stage-2 agents. It does not change the ≈3% conclusion (Claim 20a).
**Legibility-target:** for-author

The core is 3 Stage-1 agents at ≈2,189 plus 5 Stage-2 agents at ≈2,929: 6,566+14,645 = **21,211** (`ar.out`: `sb 21211.25`). 23.4k is 8 × 2.93k, as if all 8 agents carried the Stage-2 block, but the three replicates' prefixes are 8,755 bytes (`an.out`: `prelen 8745 bytes 8755` for r1-r3). Fix: "≈21.2k tokens over the 8 core agents". The ≈3% holds.

**Evidence:** `ar.out`, `an.out`

---

## Claim 21: "Skill-text growth since 2026-08-06 adds ≈2.9k (code-fact-check), 2.6k (security), 0.8k (performance) and under 0.3k (the other three) per agent."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:47-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte deltas (÷4) between `git show d4e362de:skills/<name>/SKILL.md` and HEAD. It does not establish that d4e362de's text is exactly what the August agents read, nor the growth of files the skills reference.
**Legibility-target:** for-orchestrator-synthesis

The deltas in tokens are code-fact-check 20,519→32,228 (2,927), security-reviewer 23,453→34,021 (2,642), performance-reviewer 20,629→23,941 (828), api-consistency-reviewer +53, architecture-review +255 and test-strategy +43. d4e362de is dated `Thu Aug 6 22:52:51 2026` (paraphrased — no quote available because these are `wc -c` outputs, listed here in full).

**Evidence:** `git show d4e362de:skills/*/SKILL.md`, `skills/*/SKILL.md`

---

## Claim 22: "Each critic grew 10.5k to 25.4k tokens, so 5k to 20k per agent is explained by neither."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:48-49`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the five critics' growth and the residual after subtracting the Stage-2 block and the skill delta. It does not attribute the residual.
**Legibility-target:** for-author

Growth: `[25447, 11977, 19774, 10540]` plus test-strategy 13,796 (`ar.out`), so 10.5k-25.4k is correct. The residuals are security 19,876, performance 8,220, api 16,792, architecture 7,356 and test-strategy 10,824, giving a range of **7.4k-19.9k**. "5k to 20k" contains it but understates the floor.

**Evidence:** `ar.out`, Claim 21's deltas

---

## Claim 23: "Every agent's first call already holds ~52k tokens before it does any work: 18.9k of system prompt and tools, ~30k of injected session context and ~3k of my prompt."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:50-52`
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the ~52k total and the ~3k prompt (verified). It does not establish the ~30k attribution to injected session context, because the transcripts do not record the system or injected content.
**Legibility-target:** for-orchestrator-synthesis

The first-call input is 2+32,797+18,900 = 51,699 (Stage 1) to 2+33,788+18,900 = 52,690 (Stage 2). The prompts are 11,855-13,745 chars (≈3.0-3.4k tokens) (`an.out`). The ~30k is a remainder, and its contents are not visible in the records. Needed: the agent's full request payload, or a harness log of the injected blocks.

**Evidence:** `an.out`

---

## Claim 24: "Shared block 2.2k / 2.9k tokens against the 25k budget: 9% / 12% of it."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:56-57`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ratios. It does not establish how the skill counts the budget beyond chars/4.
**Legibility-target:** for-orchestrator-synthesis

`ar.out`: `budget 0.08756 0.11696`.

**Evidence:** `ar.out`

---

## Claim 25: "This held for all 9 agents ... the Stage 2.5 agent too, which was dispatched alone long after Stage 1 with the same first 8.7k characters ... Stage 2.5 rules out the first as the only cause, but its gap from Stage 1 also exceeded the default 5-minute cache lifetime."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:62-70`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the Stage 2.5 prefix identity, its dispatch time and its gap from Stage 1. It does not establish the TTL caveat against all candidate cache entries. The api-consistency critic's prompt starts with the same 8,745 chars, and its last call (18:33:03.7Z) came 59 s before Stage 2.5's first call (18:34:02.4Z), so TTL alone does not explain the Stage 2.5 miss, which favours explanation two.
**Legibility-target:** for-orchestrator-synthesis

From `an2.out`, `s25==s1 True` (the full 8,745-char prefix is identical). From `an.out`, Stage 1's last calls are at 17:13:04-17:13:24Z and Stage 2.5's first call is at 18:34:02Z, a gap of about 81 min, which is above 5 min.

**Evidence:** `an.out`, `an2.out`

---

## Claim 26: "The baseline's largest cell (corpus, ~17.4k tokens of diff + fact-check)"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:71-72` (also `:122`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the levers-doc table. It does not establish today's corpus block size under the current skill's assembly (which adds enclosing files).
**Legibility-target:** for-orchestrator-synthesis

`| corpus (app/) | 69,575 | 17,394 | 6 | 78,273 |` (`levers-3-4-measurement.md:43`), the largest row.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:36-46`

---

## Claim 27: §3 label table (canon 2R/4A; today R1→🔴 R1, R2→A6, A1→A1+A8, A2→A7, A3→A5, A4→C6; baseline HIT/miss/HIT/partial/HIT/HIT) and "6/6 hit, against 4 hits + 1 partial"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:76-87` (also `manifest.json:11,47`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping against the canon ledger, the A8 rubric, the merged fact-check report and the baseline results. It does not re-adjudicate whether each rubric item truly matches its canon label's mechanism.
**Legibility-target:** for-orchestrator-synthesis

The canon has six csp rows (`docs/working/canon-issue-ledger.md:92-97`), e.g. `| csp-R2 | \`proxy.ts:35-36\` comment claims Edge runtime; middleware defaults to Node.js |`. The rubric gives `| R1 | \`connect-src 'self'\` blocks the browser's \`fetch(dataUrl)\` ... | Breaking (api), Incorrect high behavioral (fc 3/3) |`, `| A6 | "the Edge runtime that Next proxy runs in" ... | fact-check Claim 9 (executed)`, `| A7 | "Tailwind v4 emits inline styles"` and `| C6 | Test gaps: CSP directive list not pinned (G1)` (`csp/code-review-rubric-2026-11-19-csp.md`). The merged report shows `r1=Incorrect · r2=Incorrect · r3=Incorrect` for Claims 2, 6, 8 and 9 (`csp/code-fact-check-report.md:43,109,141,166`). The baseline reads `R1 gold connect-src/\`data:\` HIT** (security Medium); R2 Edge-runtime doc **miss** | A1 ... HIT (arch **Structural 🔴** ...); A3 ... HIT (perf Medium); A2 style-src partial; A4 test-strategy HIT (gap-fix` (`baseline-2026-08-06/results.md:24`). The ledger gives `csp-A2 — unfound by any arm at any rep` (`canon-issue-ledger.md:409`).

**Evidence:** `docs/working/canon-issue-ledger.md:92-97,409`, `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md`, `csp/code-fact-check-report.md:35-170`, `runs/review-arms/baseline-2026-08-06/results.md:24`

---

## Claim 28: "The list names every comment claim in the diff (Edge, Tailwind and connect-src among them), as the skill's rich-brief rule asks. It does not name `exportGraph.ts` or any finding."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:90-93`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "Claims that particularly need checking" list in the dispatched r1 prompt. It does not establish whether the list is complete against every comment in the diff.
**Legibility-target:** for-author

`exportGraph` occurs 0 times in the prompt (`an3.out`), so that half is correct. The list does, however, carry finding-shaped pointers. It asks `the x-nonce request header lets layouts read the nonce ... (does anything read it?)`, which points at the A1/dead-x-nonce label. Its preamble also says `for a claim about what the browser will or will not need under this policy, check the client-side code in the repo that would run under it`, which is the route to the R1 `exportGraph.ts` defect. "Does not name any finding" is accurate. The precise version would add that two items are phrased toward known labels, which strengthens the threat-to-validity sentence the doc already carries.

**Evidence:** `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r3/an3.out`

---

## Claim 29: "r3's executed run shows the nonce **does** reach Next's scripts on self-hosted `next start` (15/15 tags carry it) ... Two findings are new: ... `Purpose: prefetch` ... (🟡 A2), ... no `worker-src` (🟡 A4)."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:95-100`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers agreement with the merged report and rubric, and absence from the canon's six csp rows. It does not establish the executed result independently (that is r3's own claim, logged in `fc-r3-logs/`), nor absence from every canon row outside csp.
**Legibility-target:** for-orchestrator-synthesis

`r3 (executed ...): "on \`next start\` 15 of 15 \`<script>\` tags carry the response CSP's nonce, because the router copies proxy response headers onto \`req.headers\`` (`csp/code-fact-check-report.md:60`). The rubric has `| A2 | Requests carrying \`Purpose: prefetch\` ... get the full HTML document with no CSP` and `| A4 | ... the pdf.js worker may be blocked (no \`worker-src\`` (`csp/code-review-rubric-2026-11-19-csp.md`). Neither appears in `canon-issue-ledger.md:92-97`.

**Evidence:** `csp/code-fact-check-report.md:51-60`, `csp/code-review-rubric-2026-11-19-csp.md`, `docs/working/canon-issue-ledger.md:92-97`

---

## Claim 30: "The +24-40% per-agent growth since August is real."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:110-111`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-agent growth ratios. It does not establish "real" beyond one draw per agent.
**Legibility-target:** for-author

Per agent, growth runs **+15% to +40%**: architecture +14.9%, performance +17.9%, test-strategy +20.9%, api +28.8%, security +32.7% and fact-check per replicate +40.0% (`ar.out`). +24% and +40% are slice aggregates (four-critic sum +23.8%, mean replicate +40%), so the range should not be labelled "per-agent".

**Evidence:** `ar.out`

---

## Claim 31: "Lever #3 accounts for at most 3 of those points."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:111`
**Type:** Configuration
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shared block measured as growth points against the baseline. It does not establish the net inline cost (the self-read files the block replaces), which this run did not measure.
**Legibility-target:** for-author

"Those points" are growth percentages relative to the August per-agent figures. The "≈3%" is the block's share of **today's** core total (Claim 20a), a different base. Against the baseline, the block alone is 2,189/74,274 = 2.9 points for a replicate. For critics it is 2,929/77,879 = 3.8, /67,010 = 4.4, /68,604 = 4.3, /70,859 = 4.1 and /65,894 = 4.4. At k=1-equivalent it is (2,189+5×2,929)/424,520 = 4.0 of the +26 points. Subtracting the baseline's ~330-token prefix still leaves ≈3.8 points for a critic. The upper bound "at most 3" is exceeded. Precise version: "at most ~4 of those points (gross)". The conclusion that most of the growth is unattributed survives.

**Evidence:** `ar.out`, `an2.out`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:28`

---

## Claim 32: §4 verdict: "'Free' holds roughly, but it is not 0% ... The benefit the claim counts on did not appear ... 'Zero effect on recall' cannot be told ... Verdict: fails as stated. The lever's benefit was 0 here and its token-count effect was small but not zero."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:104-114`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the paragraph's conclusions follow from the measured records. It does not establish whether the skill's claim fails in general, since one cell and one draw cannot.
**Legibility-target:** for-author

The parts the evidence supports: the first calls show no cross-agent cache reuse (Claim 11a), recall cannot be attributed, and the block is ~3% of the core. Three parts say more than the records show:

- It rounds the "at most 3 points" bound wrongly (Claim 31).
- "No agent read the shared block from cache" is literally false after call 1 (Claim 11b).
- It says both "the net token-count cost is probably near zero" (line 106-107) and "its token-count effect was small but not zero" (line 113-114). The second is the gross block size. The net figure was not measured, and the paragraph itself says this pass had no self-read arm.

The "fails as stated" headline rests mainly on one observed cache miss with two untested causes. Calling it "fails in this pass; cause untested" would match the evidence. The paragraph does already hedge with "One cell cannot tell how either scales".

**Evidence:** `results.md:104-114`, `an.out`, `an5.out`

---

## Claim 33: "The api-consistency critic took 4,439 s of wall clock for 7 tool uses (the others took 106-504 s)."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:126-128` (also `token-ledger.md:18`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the durations computed from transcript first and last timestamps. It does not establish the notified tool_uses (Claim 36b).
**Legibility-target:** for-orchestrator-synthesis

From `an.out`, api runs 17:19:04.522Z→18:33:03.685Z = 4,439 s. The others: performance 106 s, architecture 117 s, test-strategy 131 s, security 244 s, Stage 2.5 252 s, r2 484 s, r1 488 s, r3 504 s. All match the ledger's duration column.

**Evidence:** `an.out`, `token-ledger.md:10-20`

---

## Claim 34: "The baseline had no executed verdicts."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:130-131` (also `research-2026-11-19-a8-token-measurement.md:98`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the baseline csp artifacts and a grep of the baseline tree. It does not establish that no other baseline cell ran code informally.
**Legibility-target:** for-orchestrator-synthesis

Paraphrased — no quote available because the claim covers the absence of text: `grep -c -i 'verification mode'` returns 0 for all six `baseline-2026-08-06/csp/*.md` files, and `grep -rn -i executed runs/review-arms/baseline-2026-08-06/` (hunt files excluded) has no hits.

**Evidence:** `runs/review-arms/baseline-2026-08-06/csp/`

---

## Claim 35: Stage 1 / Stage 2.5 outcome columns: r2 5V/0MA/0S/7I/2U, r1 6V/4MA/0S/5I/2U, r3 11V/2MA/0S/4I/2U; merged "18 claims, 5V/3MA/7I/3U, agreement 9/17"; Stage 2.5 "7 entries: 5V (3 executed) / 1MA / 1U / 0I"

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:10-13,20`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ledger against each report's `**Summary:**` header. It does not establish that each report's own header matches its body. r2's header says 5 verified while its body carries 6 `**Verdict:** Verified` lines. That is in a csp artifact, out of scope here.
**Legibility-target:** for-orchestrator-synthesis

The report headers read `**Summary:** 5 verified, 0 mostly accurate, 0 stale, 7 incorrect, 2 unverifiable` (r2:9), `6 verified, 4 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable` (r1:9), `11 verified, 2 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable` (r3:9) and `**Total claims checked:** 18` / `5 verified, 3 mostly accurate, 0 stale, 7 incorrect, 3 unverifiable` (merged:10-11). The merged report also gives `Agreement rate: 9/17 = 53%` (merged:349). The submitted-claims report reads `5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable` (submitted:9), with three `**Verification mode:** executed` lines, all on Verified claims.

**Evidence:** `csp/code-fact-check-report-r{1,2,3}.md:8-9`, `csp/code-fact-check-report.md:10-11,349`, `csp/code-fact-check-submitted-claims.md:8-9`

---

## Claim 36a: Ledger per-agent tokens and durations (rows 1-9)

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:10-20`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tokens and duration columns against the transcripts. It does not establish the tool_uses column (36b).
**Legibility-target:** for-orchestrator-synthesis

See Claims 10 and 33. All nine token and duration cells match `an.out`.

**Evidence:** `an.out`

---

## Claim 36b: Ledger tool_uses column (9 / 13 / 35 / 5 / 6 / 8 / 9 / 7 / 17)

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:10-20` (also `results.md:126`)
**Type:** Configuration
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the distinct `tool_use` block counts in the transcripts. It does not establish the notification's value, which is not in the records available.
**Legibility-target:** for-orchestrator-synthesis

`an4.out` counts distinct tool_use ids of r2 10, r1 14, r3 36, performance 6, architecture 7, test-strategy 9, security 10, api 8 and Stage 2.5 18. Every ledger value is exactly the transcript count minus 1, on all nine rows. The offset is a uniform -1, which suggests the notification counts differently, for example by excluding one call. Verifying this needs the raw task notifications.

**Evidence:** `an4.out`

---

## Claims Requiring Attention

### Incorrect
- **Claim 20b** (`runs/review-arms/a8-2026-11-19/results.md:46-47`): "23.4k tokens over the 8 core agents" is 8×2.9k. The three replicates carry the 2.2k Stage-1 block, so the sum is ≈21.2k. The ≈3% still holds.
- **Claim 31** (`runs/review-arms/a8-2026-11-19/results.md:111`): "at most 3 of those points" mixes up share-of-today's-core with growth points against the baseline. The block is 3.8-4.4 points per critic and 4.0 points at k=1-equivalent.

### Mostly Accurate
- **Claim 4** (`docs/working/research-2026-11-19-a8-token-measurement.md:24`, `manifest.json:4`): SKILL.md last changed at 44724747. 82accdd7 is the last change to the skill directory (rubric.md).
- **Claim 7** (`research...md:40`, `token-ledger.md:3` vs `results.md:23`): the instrument is named `total_tokens` in two files and `subagent_tokens` in the others.
- **Claim 8** (`research...md:55,74`): per-prompt skill text is 14.5-34 KB, not 25-34 KB. "190 KB" matches no total (9 prompts = 252 KB; ~60k tokens is right for that).
- **Claim 11b** (`research...md:95`, `manifest.json:46`, `results.md:108`): "never served from cache" is true only cross-agent and on the first call. Calls 2+ read the block from each agent's own cache.
- **Claim 13** (`manifest.json:14`, `token-ledger.md:5`): 2,189 is bytes/4. chars/4 = 2,186.
- **Claim 19** (`results.md:40-42`): ~97k is +27% of 359k. "+26% at k=1-equivalent" is a different quantity (111k over 424.5k).
- **Claim 22** (`results.md:49`): the unexplained residual per critic is 7.4k-19.9k, not 5k-20k.
- **Claim 28** (`results.md:90-93`): the checklist does not name exportGraph.ts, but it includes "(does anything read it?)" and an instruction to check client-side code under the policy, both pointed toward canon labels.
- **Claim 30** (`results.md:110`): per-agent growth is +15% to +40%. +24% to +40% is the slice-aggregate range.
- **Claim 32** (`results.md:104-114`): the verdict paragraph inherits Claims 11b and 31, calls the net token-count cost both "probably near zero" and "not zero", and "fails as stated" rests on one cache miss with untested causes.

### Unverifiable
- **Claim 23** (`results.md:50-52`): the ~30k "injected session context" is a remainder. It would need the full request payload.
- **Claim 36b** (`token-ledger.md:10-20`): tool_uses are uniformly the transcript count minus 1. It would need the raw notifications.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-2026-11-19-a8-token-measurement/docs/reviews/code-fact-check-report-2026-11-19-a8-r3.md, with `Commit: 123432af` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: the csp/ critic and fact-check artifacts were used as evidence, not verdicted (r2's header/body count mismatch is noted only in Claim 35's scope). Execution logs are kept in the session scratchpad rather than `docs/reviews/execution-logs/`, because this run may write only this file. The hallucination-pattern log was not updated (no fabrication found; read-only run).
- Escalate: the Stage-2.5 TTL caveat (results.md:69-70) omits that the api critic held the same 8,745-char prefix 59 s before Stage 2.5's first call, which bears on which cache explanation fits (Claim 25 scope). The notification field name (total_tokens vs subagent_tokens) should be settled before the figures are compared with other runs.
