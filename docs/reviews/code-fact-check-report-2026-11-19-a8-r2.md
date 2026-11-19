Commit: 123432af

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-token-measurement (branch measure/a8-token-measurement)
**Scope:** explicit file list at HEAD 123432af: `docs/working/research-2026-11-19-a8-token-measurement.md`, `runs/review-arms/a8-2026-11-19/manifest.json`, `runs/review-arms/a8-2026-11-19/results.md`, `runs/review-arms/a8-2026-11-19/token-ledger.md` (replicate r2 of 3)
**Checked:** 2026-11-19
**Total claims checked:** 29 (28 numbered; Claim 24 split into 24a/24b)
**Summary:** 18 verified, 8 mostly accurate, 0 stale, 1 incorrect, 2 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. Closest prior pattern: "specific counts misstated against the data they describe" (entries at `:26-30`, e.g. "All 85 tests ... but the suites hold 97"). Claim 11 (a figure attributed to 8 agents that is a 9-agent sum) resembles it; no fabricated symbol or API was found, so nothing is added to the log.

Execution provenance (applies to every `executed` claim below). Working directory `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/r2`, run 2026-11-19T18:54:14Z, all exit 0:
- `timeout 120 python3 -I t.py` → `out-t.py.txt`: per agent, dedupes assistant records by `requestId`, prints first-call `cache_read_input_tokens` / `cache_creation_input_tokens`, last-call input+cache_creation+cache_read+output, sha256[:16] and byte/char length of the first record's content before `"\n---\n\n## Your role"`.
- `timeout 120 python3 -I s4.py` → `out-s4.py.txt`: first/last timestamp span and tool_use block count per transcript.
- `timeout 120 python3 -I s2.py`, `s3.py` → `out-s2.py.txt`, `out-s3.py.txt`: the `cacheControl` breakpoint paths on the `api-request` records and the attachment list.
- `cmp` of the extracted r1 and security prompt prefixes against `csp/shared-block.md` and `csp/shared-block-stage2.md` → `out-cmp.txt` (`stage1-identical`, `stage2-identical`).
- Arithmetic re-derivations were run with `python3 -I -c` in the same session (figures quoted inline below).

All paths for captured output are in the directory above.

---

## Claim 1: "Baseline cell csp: range `d86d2dc..d90d6bb` ... 2 files, +72/-1. Baseline per-cell core = 358,626 tokens (fc k=1 74,274 + security 77,879 + performance 67,010 + api 68,604 + architecture 70,859). The test-strategy gap-fix (65,894) ran later and is NOT in the 359k per-cell figure, but is in the 2.99M canon total."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:17-21`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff stat, the five per-agent baseline figures, their sum and the gap-fix's inclusion in the 2.99M total; does not establish how the baseline's 359k "per-cell" rounding was computed beyond this sum.
**Legibility-target:** for-orchestrator-synthesis

`git -C /workspace/external/meta-formalism-copilot diff --shortstat d86d2dc..d90d6bb` printed `2 files changed, 72 insertions(+), 1 deletion(-)`. The baseline ledger rows: `| csp | 74,274 | 11 |` (`runs/review-arms/baseline-2026-08-06/token-ledger.md:16`), `| csp | performance | 67,010 |` (`:47`), `| csp | api-consistency | 68,604 |` (`:48`), `| csp | architecture | 70,859 |` (`:49`), `| csp | security | 77,879 |` (`:80`), `| csp | test-strategy | 65,894 | advisory ... (gap-fix ...` (`:82`). Sum of the five = 358,626 (python). Baseline `results.md:20` gives "csp 359k" and `:44` says "Totals above include the gap-fix".

**Evidence:** `runs/review-arms/baseline-2026-08-06/token-ledger.md:16,47-49,80,82`, `runs/review-arms/baseline-2026-08-06/results.md:20,44`

---

## Claim 2: "Baseline delivery was self-read: critics got a scope spec and read the diff and files with tools (levers-3-4 doc: shared prefix ~330 tokens)."

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:22-23`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the baseline's own measurement doc records about its delivery; does not establish what the baseline agents actually read (no baseline transcripts examined).
**Legibility-target:** for-orchestrator-synthesis

`critic agents are given a scope spec and **self-read** the diff, enclosing files, and the fact-check report via tools. The genuinely byte-identical shared *prompt prefix* was my ~250-word instruction block (~330 tokens)` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:26-28`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:25-31`

---

## Claim 3: "Today's skill (`skills/code-review/SKILL.md`, last changed 82accdd7, 2026-11-14)" (also `manifest.json:4` "last changed 82accdd7", `results.md:16` "Today's skill (82accdd7)")

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:24`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which commit last changed `skills/code-review/SKILL.md` and whether its content differs between 82accdd7 and 4330e303; does not establish anything about the critic skills' versions.
**Legibility-target:** for-author

`git show --stat 82accdd7` lists `skills/code-review/references/rubric.md | 2 +-` and three docs/workflow files, not `skills/code-review/SKILL.md`; `git log -1 -- skills/code-review/SKILL.md` returns `44724747 Sat Nov 14 11:20:28 2026` (82accdd7's parent), and the first-parent history shows it landing via `21097afa Merge branch 'docs/review-rules-close-gaps'`. `git diff --quiet 44724747 82accdd7 -- skills/code-review/SKILL.md` and `git diff --quiet 82accdd7 4330e303 -- ...` both report identical content. So the SKILL.md used is the one at 82accdd7 and the date is right, but 82accdd7 is the last change to the skill directory (its `references/rubric.md`), not to `SKILL.md`. Precise version: "SKILL.md last changed 44724747 (skill directory 82accdd7), 2026-11-14".

**Evidence:** `skills/code-review/SKILL.md` (git history), `skills/code-review/references/rubric.md` (82accdd7)

---

## Claim 4: "instead of my pasting ~25-34 KB of skill text into each prompt" / "Pasting ... costs ~60k orchestrator output tokens and risks transcription drift over 190 KB"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:55-56,73-75`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the byte sizes of the six `SKILL.md` files at HEAD and their sum over the dispatched prompts; does not establish whether the author also counted `references/` files.
**Legibility-target:** for-author

`wc -c` at HEAD: code-fact-check 32,228; security-reviewer 34,021; performance-reviewer 23,941; api-consistency-reviewer 22,753; architecture-review 27,564; test-strategy 14,504. The range is 14.5-34 KB, not 25-34 KB (test-strategy is under half the stated floor). Pasted into the 8 core prompts (fact-check ×3 + 5 critics) the total is 219,467 bytes (251,695 with the Stage 2.5 prompt; 155,011 for the six distinct files), none of which is 190 KB; ~60k output tokens is consistent with 219 KB/4 ≈ 55k. The design reasoning (pasting is large; read-by-path keeps the prefix) holds; the size figures are loose.

**Evidence:** `skills/code-fact-check/SKILL.md`, `skills/security-reviewer/SKILL.md`, `skills/performance-reviewer/SKILL.md`, `skills/api-consistency-reviewer/SKILL.md`, `skills/architecture-review/SKILL.md`, `skills/test-strategy/SKILL.md` (byte counts)

---

## Claim 5: "The instrument: for all 9 agents the notified `subagent_tokens` equals the transcript's last API call's input + cache-creation + cache-read + output." (same claim at `results.md:23-26`, `token-ledger.md:24-25`, `manifest.json:61`)

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:91-92`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers equality between the last deduped API call's four usage fields and the ledger/manifest figure for all 9 transcripts; does not establish what the notification itself printed (notifications not available to me; compared against the ledger values instead).
**Legibility-target:** for-orchestrator-synthesis

From `out-t.py.txt`, last-call sums: r1 100,755; r2 90,196; r3 121,024; security 103,326; performance 78,987; api 88,378; arch 81,399; test-strategy 79,690; stage 2.5 108,530. Each equals the corresponding `manifest.json:24-34` value (`"fc_r1": 100755` ... `"stage2_5_submitted_claims": 108530`). The research doc's own hedge, `I assume the baseline's figures came from the same field` (`:92-93`), is accurate; see Claim 25 for the ledger stating it unhedged.

**Evidence:** `runs/review-arms/a8-2026-11-19/manifest.json:24-34`, `out-t.py.txt`

---

## Claim 6: "Today's skill ... inlines diff + enclosing files as a byte-identical shared prefix within a 25k-token budget, runs k=3 fact-check on a terminal pass" / "Fact-check k=3 (terminal pass, decision log 63)"

**Location:** `docs/working/research-2026-11-19-a8-token-measurement.md:24-26,51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the skill text and decision log row 63 say this; does not establish that the orchestrator followed every other step of the skill.
**Legibility-target:** for-orchestrator-synthesis

`- **Budget: 25,000 tokens, estimated as chars/4 (i.e. ~100 KB of assembled part-5 material).**` (`skills/code-review/SKILL.md:328`); `| 63 | 2026-09-28 | **A review-fix loop's final confirming pass runs the fact-check at k=3 (merged most-severe-wins), not decision 031's k=1.**` (`docs/decisions/log.md:86`).

**Evidence:** `skills/code-review/SKILL.md:137,322-328`, `docs/decisions/log.md:86`

---

## Claim 7: shared-block figures in the manifest: `"shared_block_bytes": 8755`, `"shared_block_tokens_est": 2189`, `"shared_block_stage2_bytes": 11716`, `"stage1": "be4a2600985537d5 (3/3 prompts)"`, `"stage2": "42374933a2ebe4a1 (5/5 prompts)"`

**Location:** `runs/review-arms/a8-2026-11-19/manifest.json:13-14,41-45`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte sizes, the 16-hex prefixes of sha256 over the prompt text before `"\n---\n\n## Your role"` for all 9 prompts, and byte-identity with the saved block files; does not establish the chars/4 basis (see Claim 25: 2,189 is bytes/4).
**Legibility-target:** for-orchestrator-synthesis

`out-t.py.txt`: r1, r2, r3 → `hash be4a2600985537d5 ... bytes 8755`; security, performance, api, arch, ts → `hash 42374933a2ebe4a1 ... bytes 11716`; Stage 2.5 → `be4a2600985537d5`, 8,755 bytes. `out-cmp.txt`: `stage1-identical`, `stage2-identical` (extracted prefixes are byte-identical to `csp/shared-block.md` and `csp/shared-block-stage2.md`), and sha256 of those files gives the same prefixes. The Stage 2.5 prompt carries the Stage-1 hash too (4 prompts in all); the manifest's "3/3" counts only Stage 1.

**Evidence:** `runs/review-arms/a8-2026-11-19/manifest.json:13-14,41-45`, `runs/review-arms/a8-2026-11-19/csp/shared-block.md`, `runs/review-arms/a8-2026-11-19/csp/shared-block-stage2.md`, `out-t.py.txt`, `out-cmp.txt`

---

## Claim 8: manifest totals: `"stage1_total": 311975`, `"stage2_total": 431780`, `"core_total": 743755`, `"total_tokens": 852285`, `"agents": 9`, `"baseline_csp_core": 358626`, `"baseline_csp_core_with_testgap": 424520`

**Location:** `runs/review-arms/a8-2026-11-19/manifest.json:27-36,50-58`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that each total is the sum of its per-agent figures and that those match the transcripts; does not establish anything about agents not dispatched.
**Legibility-target:** for-orchestrator-synthesis

Python: 100,755+90,196+121,024 = 311,975; 103,326+78,987+88,378+81,399+79,690 = 431,780; sum 743,755; +108,530 = 852,285; 358,626+65,894 = 424,520. Nine transcripts exist, one per listed agent, each matching (Claim 5).

**Evidence:** `runs/review-arms/a8-2026-11-19/manifest.json:23-58`, `out-t.py.txt`

---

## Claim 9: "Row A8 ... says the code-review skill's claim about inlining the shared review context (decision 032 lever #3: "zero effect on recall", "0% of token count", "leave it on because it is free", `skills/code-review/SKILL.md:276-354`) rests on a pre-restructure projection (~5.3% of input cost ...), and that inlining adds prompt tokens each agent used to fetch selectively."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:7-12`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric row's content and that the three quoted phrases sit in the cited SKILL.md range at HEAD; does not establish that the rubric row's own line cite (`SKILL.md:276-278`, written 2026-08-07) still points at the same lines.
**Legibility-target:** for-orchestrator-synthesis

Rubric row: `"Leave it on because it is free" / "0% of token count" (`SKILL.md:276-278`) is not established for the newly inlined enclosing-file half — inlining adds real prompt tokens each agent previously fetched selectively; the 5.3% figure is a pre-change projection` (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`). Skill: `is unchanged, so it has **zero effect on recall** (decision 032 H1).` (`skills/code-review/SKILL.md:277`); `- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a` / `billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect` (`:352-353`). Baseline: `**≈157k cost-equivalent ÷ 2.99M ≈ 5.3% of input cost, 0% of token count**` (`levers-3-4-measurement.md:48`).

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `skills/code-review/SKILL.md:270-277,352-353`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:48`

---

## Claim 10: "terminal pass: k=3 fact-check, 5 critics (...; ui-visual not selected, as in the baseline), Stage 2.5 for 6 routed endorsement claims ... All agents on opus. Running total peaked at 852,285 tokens, under the brief's 2M stop line."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:16-19`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the agent roster, the model of every assistant record, the routed-claim count and the stop line; does not establish the Stage 1.5 gating reasoning.
**Legibility-target:** for-orchestrator-synthesis

Every assistant record in the 9 transcripts has `model` `claude-opus-5-5` (a few records have none, e.g. 1 in r3). Routed claims: ledger rows say `1 submitted claim` (perf), `3 routed endorsement claims` (security), `2 routed claims` (api) (`token-ledger.md:14,17,18`) = 6, matching `**Total claims checked:** 7 (6 submitted; S5 split into 23a/23b)` (`csp/code-fact-check-submitted-claims.md:8`). Baseline: `| csp | sec, perf, api, arch, ui | security, performance, api-consistency, architecture | ui-visual` (`baseline-2026-08-06/token-ledger.md:32`). Brief: `If the pass's running total passes 2M tokens, stop it` (`docs/working/briefs/2026-11-19-a8-token-measurement.md:23`).

**Evidence:** `runs/review-arms/a8-2026-11-19/token-ledger.md:14,17,18`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-submitted-claims.md:8`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:32`, `docs/working/briefs/2026-11-19-a8-token-measurement.md:23`

---

## Claim 11: "The inlined shared block is 8,755 bytes (≈2.2k tokens) in the Stage-1 prompts and 11,716 bytes (≈2.9k tokens, with the fact-check summary) in the Stage-2 prompts: 23.4k tokens over the 8 core agents, **≈3% of the core total**."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:44-47`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block sizes and the arithmetic of the 23.4k figure and its share; does not establish the net token effect against a self-read arm (none was run).
**Legibility-target:** for-author

Sizes verified (Claim 7). Python: 3 × 2,189 + 5 × 2,929 = 21,212 tokens over the 8 core agents = 2.85% of 743,755. The stated 23.4k is 23,401 = that sum plus the Stage 2.5 agent's 2,189, i.e. 9 agents, and Stage 2.5 is outside the core total (`results.md:37` "outside core"). Against the core total, 23.4k is 3.15%. "≈3%" survives either way; the 23.4k / "8 core agents" pairing does not re-derive.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:35-37,44-47`, `runs/review-arms/a8-2026-11-19/manifest.json:13-14,41`

---

## Claim 12: "Skill-text growth since 2026-08-06 adds ≈2.9k (code-fact-check), 2.6k (security), 0.8k (performance) and under 0.3k (the other three) per agent."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:47-48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `SKILL.md` byte growth between d4e362de and HEAD at bytes/4; does not establish growth in files the skills reference.
**Legibility-target:** for-orchestrator-synthesis

`git show d4e362de:skills/<name>/SKILL.md | wc -c` vs HEAD: code-fact-check +11,709 B (2,927 tok); security-reviewer +10,568 (2,642); performance-reviewer +3,312 (828); api-consistency-reviewer +212 (53); architecture-review +1,023 (255); test-strategy +172 (43).

**Evidence:** `skills/*/SKILL.md` at d4e362de and 123432af (byte counts)

---

## Claim 13: "Each critic grew 10.5k to 25.4k tokens, so 5k to 20k per agent is explained by neither."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:48-49`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers per-critic deltas against the baseline and the residual after subtracting the Stage-2 block and the skill growth; does not establish that the inlined block is additive (a self-read agent also reads those files).
**Legibility-target:** for-orchestrator-synthesis

Python deltas: security +25,447, api +19,774, test-strategy +13,796, performance +11,977, architecture +10,540. Residual after 2,929 (block) and the skill growth from Claim 12: security 19.9k, api 16.6k, test-strategy 10.8k, performance 8.2k, architecture 7.4k. All fall in the stated 5k-20k band (the band's floor is looser than the 7.4k minimum).

**Evidence:** `runs/review-arms/a8-2026-11-19/token-ledger.md:14-18`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:47-49,80,82`

---

## Claim 14: "Every agent's first call already holds ~52k tokens before it does any work: 18.9k of system prompt and tools, ~30k of injected session context and ~3k of my prompt."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:50-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the first-call totals and the arithmetic split (cache read; creation minus prompt); does not establish the exact composition of the ~30k, which is inferred, not measured per block.
**Legibility-target:** for-orchestrator-synthesis

`out-t.py.txt` first-call totals: 51,790-53,040 across the 9 agents, cache read 18,900 each. Prompt lengths 11,855 chars (Stage 1) to 13,745 (security) ≈ 3.0-3.4k tokens at chars/4, so creation (32,797-33,788) minus prompt ≈ 29.8-30.4k. `out-s2.py.txt` shows the first records carry `instructions` (48,026 chars), `skill_listing` (26,343) and other attachments, consistent with injected session context (paraphrased — no quote available because the attachment bodies are large serialized JSON; only their types and sizes were printed). Breakpoints `["system", 0]`, `["system", 1]` (`out-s3.py.txt`) are consistent with the 18.9k read being tools + system.

**Evidence:** `out-t.py.txt`, `out-s2.py.txt`, `out-s3.py.txt`

---

## Claim 15: "The August run left no transcripts to split this the same way."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:52`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond noting the baseline directory holds no JSONL; does not establish absence elsewhere (August session task directories under /tmp were not searched).
**Legibility-target:** for-orchestrator-synthesis

The baseline run directory holds only markdown/JSON artifacts (paraphrased — no quote available because the claim is about absence of files; `ls runs/review-arms/baseline-2026-08-06/` shows `corpus csp deploy ... token-ledger.md` and no transcript files). Verifying needs a search of the August session's task directories, which were not in scope.

**Evidence:** `runs/review-arms/baseline-2026-08-06/` (directory listing)

---

## Claim 16: "Shared block 2.2k / 2.9k tokens against the 25k budget: 9% / 12% of it." / "Byte-identity held: the shared part of every prompt hashes the same (Stage 1: `be4a2600985537d5` ×3; Stage 2: `42374933a2ebe4a1` ×5, equal to `csp/shared-block-stage2.md`)."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:56-59`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the budget ratios and hash identity for all 9 prompts; does not establish byte-identity of the tails (they differ by design).
**Legibility-target:** for-orchestrator-synthesis

2,189/25,000 = 8.8%; 2,929/25,000 = 11.7%. Hashes as in Claim 7 (`out-t.py.txt`, `out-cmp.txt`).

**Evidence:** `out-t.py.txt`, `out-cmp.txt`, `skills/code-review/SKILL.md:328`

---

## Claim 17: "Each agent's first call read exactly 18,900 cached tokens (system prompt + tools, common to every agent) and wrote 32.8k-33.8k fresh, shared block included. This held for all 9 agents." (also `token-ledger.md:25-26`, `manifest.json:46`, research `:94-95`)

**Location:** `runs/review-arms/a8-2026-11-19/results.md:60-63`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers first-call `cache_read_input_tokens` and `cache_creation_input_tokens` for all 9 deduped transcripts; does not establish later calls' cache behaviour.
**Legibility-target:** for-orchestrator-synthesis

`out-t.py.txt`: `first cr 18900` for all 9; `cc` 32,797 (r1, r2, r3), 33,214 (Stage 2.5), 33,725-33,788 (five critics); `in 2` each. Range 32.8k-33.8k holds.

**Evidence:** `out-t.py.txt`

---

## Claim 18: "the Stage 2.5 agent too, which was dispatched alone long after Stage 1 with the same first 8.7k characters ... Two explanations fit, and this run cannot tell them apart ... Stage 2.5 rules out the first as the only cause, but its gap from Stage 1 also exceeded the default 5-minute cache lifetime."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:63-70`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers dispatch timing, prefix identity, and what the transcripts record about cache breakpoints; does not establish which block `messages[1].content[3]` is, so it does not decide between the two explanations.
**Legibility-target:** for-author

`out-s4.py.txt`: Stage 1 ran 17:05:00-17:13:24, the five critics all started 17:19:04 (parallel), Stage 2.5 started 18:34:02 alone, more than 80 min after Stage 1 ended. Its prompt prefix is 8,745 chars and hashes `be4a2600985537d5`, the same as Stage 1 (`out-t.py.txt`). The transcripts do record breakpoint placement, which the "cannot tell them apart" sentence does not mention: the first `api-request` carries `[{"path": ["system", 0], ...}, {"path": ["system", 1], ...}, {"path": ["messages", 1, "content", 3], "value": {"type": "ephemeral"}}]` and `promptCacheRequested` `"5m"` (`out-s3.py.txt`, `out-s2.py.txt`). That bears directly on explanation two (where the breakpoints sit) and is evidence the run holds but did not examine. The facts stated are right; "this run cannot tell them apart" is too strong without checking that record.

**Evidence:** `out-s4.py.txt`, `out-t.py.txt`, `out-s2.py.txt`, `out-s3.py.txt`

---

## Claim 19: "The baseline's largest cell (corpus, ~17.4k tokens of diff + fact-check) is the one that would test it."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:71-72`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the baseline's measured prefix sizes; does not establish the corpus cell's size under today's enclosing-file assembly.
**Legibility-target:** for-orchestrator-synthesis

`| corpus (app/) | 69,575 | 17,394 | 6 | 78,273 |` and no larger row (`levers-3-4-measurement.md:43`, table `:36-46`).

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:36-46`

---

## Claim 20: the §3 label table and "6/6 hit, against 4 hits + 1 partial in the baseline"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:76-87`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each row's today-mapping to the rubric and fact-check reports, and the baseline column against baseline `results.md`; does not adjudicate the findings against the code, and A4 is counted as a hit at 🟢 Consider tier (as the baseline also did).
**Legibility-target:** for-orchestrator-synthesis

Canon: `csp-R1 ... connect-src 'self' blocks the data:/blob fetch in exportGraph.ts` through `csp-A4 | No tests pin the CSP directive list` (`docs/working/canon-issue-ledger.md:92-97`). Today: rubric R1 `Breaking (api), Incorrect high behavioral (fc 3/3)` with `architecture #2 (Coupling); security #5 (Info); test-strategy G8` (`csp/code-review-rubric-2026-11-19-csp.md:15`); merged Claim 8 `r1=Incorrect · r2=Incorrect · r3=Incorrect`, `**Confidence:** High` (`csp/code-fact-check-report.md:138,141`). R2 → rubric A6 `fact-check Claim 9 (executed)` (`rubric:30`), merged Claim 9 3/3 Incorrect, mode executed (`code-fact-check-report.md:164,166`). A1 → rubric A1 + A8 (`rubric:25,32`). A2 → rubric A7, merged Claim 6 3/3 Incorrect, executed (`rubric:31`; `code-fact-check-report.md:107,109`). A3 → rubric A5, merged Claim 2 3/3 Incorrect (`rubric:29`; `code-fact-check-report.md:43`). A4 → rubric C6 `CSP directive list not pinned (G1)` (`rubric:49`). Baseline column: `R1 gold connect-src/data: HIT (security Medium); R2 Edge-runtime doc miss | A1 ... HIT (arch Structural 🔴 + api + fc); A3 ... HIT (perf Medium); A2 style-src partial; A4 test-strategy HIT (gap-fix` (`baseline-2026-08-06/results.md:26`). "unfound by any arm before": `csp-A2 — unfound by any arm at any rep` (`canon-issue-ledger.md:409`).

**Evidence:** `docs/working/canon-issue-ledger.md:92-97,409`, `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md:15,25-32,49`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md:35-43,101-109,133-141,158-166`, `runs/review-arms/baseline-2026-08-06/results.md:26`

---

## Claim 21: "The list names every comment claim in the diff (Edge, Tailwind and connect-src among them), as the skill's rich-brief rule asks. It does not name `exportGraph.ts` or any finding."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:90-92`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the text of the fact-check prompts' "Claims that particularly need checking" list as dispatched; does not establish whether a label-blind author would have written it differently.
**Legibility-target:** for-author

The r1 prompt contains no `exportGraph` (count 0), so that half holds. But the list's preamble says `for a claim about what the browser will or will not need under this policy, check the client-side code in the repo that would run under it`, and one item reads `proxy.ts: the x-nonce request header lets layouts read the nonce via headers() and pass it to Script tags (does anything read it?)` (r1 transcript, first record). These point at the R1 route (client-side fetch under connect-src) and the A1 finding (nothing reads x-nonce). "Or any finding" is too strong; the paragraph's own caveat (`:92-93`) is the accurate reading.

**Evidence:** r1 transcript `a1a8fdb7b815b5808.output` first record (dispatched prompt)

---

## Claim 22: "r3's executed run shows the nonce **does** reach Next's scripts on self-hosted `next start` (15/15 tags carry it), through the router copying response headers onto the request."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:95-97`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that r3's report and logs say this; does not re-execute `next start` or read `resolve-routes.js`.
**Legibility-target:** for-orchestrator-synthesis

`Observed on next start: 15 of 15 <script> tags in / carry nonce="NmY5MzIy…"` (`csp/code-fact-check-report-r3.md:81`); merged annotation: `the router copies proxy response headers onto req.headers (next/dist/server/lib/router-utils/resolve-routes.js:443-446)` (`csp/code-fact-check-report.md:60`). `csp/fc-r3-logs/root-body.html` and `root-headers.txt` exist.

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report-r3.md:81`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md:60`, `runs/review-arms/a8-2026-11-19/csp/fc-r3-logs/`

---

## Claim 23: "New since the canon, for whoever re-scores: ... Two findings are new: security found that `Purpose: prefetch` requests get HTML with no CSP (🟡 A2), and the pdf.js worker may be blocked because there is no `worker-src` (🟡 A4)."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:95,98-100`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers whether the canon ledger already records both findings; does not adjudicate either finding against the code.
**Legibility-target:** for-author

Both are already on the canon ledger, outside the `:92-97` Stratum-A rows the results cite. Prefetch: `- **N1** csp: middleware prefetch-skip serves real HTML with no CSP (E5; **fix-confirmed** `ab4dbdb`**)` (`docs/working/canon-issue-ledger.md:176-177`). Worker: `- N7 csp: no worker-src under 'strict-dynamic' — pdf.js worker blocked/degraded (E6, verifier-kept; never fixed at HEAD). **Candidate REFUTED by E7r2** with spec + WPT evidence (w3c/webappsec-csp#200: 'strict-dynamic' blesses worker creation; ...)` (`:185-189`), and a later arm's re-assertion was scored `**1 confirmed** (csp's worker-src finding re-asserts N7's already-refuted claim)` false positive (`:372`, also `:276`). So neither is new. Worse for a re-scorer, rubric A4 (worker-src) repeats a claim the canon scores as refuted, so crediting it would add a known false positive.

**Evidence:** `docs/working/canon-issue-ledger.md:176-177,185-189,276,372`, `runs/review-arms/a8-2026-11-19/csp/code-review-rubric-2026-11-19-csp.md:26,28`

---

## Claim 24a: "Of the +385k core increase over the 359k per-cell figure, about 208k is k=3 (two extra replicates at the mean), about 80k is test-strategy now running in the first wave"

**Location:** `runs/review-arms/a8-2026-11-19/results.md:40-41`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic of the first two parts of the split; does not establish the third (Claim 24b).
**Legibility-target:** for-orchestrator-synthesis

Python: 743,755 − 358,626 = 385,129; 2 × 103,991.7 = 207,983; test-strategy 79,690.

**Evidence:** `runs/review-arms/a8-2026-11-19/manifest.json:24-35`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:16,47-49,80`

---

## Claim 24b: "and the remainder (~97k, +26% at k=1-equivalent) is per-agent growth."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:41-42`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the remainder figure and which percentage it corresponds to; does not establish the attribution of the growth.
**Legibility-target:** for-author

The remainder is 385,129 − 207,983 − 79,690 = 97,456, which is +27.2% of the five-agent 358,626 base. The "+26%" is a different comparison: the k=1-equivalent row, 535,772 vs 424,520 (`results.md:36`), a delta of 111,252, which includes test-strategy's own growth (13,796). Precise version: "~97k (+27% on the 5-agent baseline core)". The two figures are both right on their own bases; pairing them in one parenthetical makes them look like the same quantity.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:35-36,40-42`

---

## Claim 25: "Tokens = `total_tokens` from each Agent task notification (same instrument as E1/E3 and the 2026-08-06 baseline) ... Shared block: `csp/shared-block.md`, 8,755 bytes ≈ 2,189 tokens (chars/4)"

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:3-5`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the field naming across the four files, the baseline's recorded instrument and the chars/4 arithmetic; does not establish what the notification payload named the field (not available to me).
**Legibility-target:** for-author

Field name: this ledger and research `:40` say `total_tokens`; `results.md:23`, `manifest.json:61` and the baseline say `subagent_tokens` (`Tokens = subagent_tokens from task notifications (same instrument as E1/E3)`, `baseline-2026-08-06/token-ledger.md:3`). "Same instrument as the baseline" is asserted here without the research doc's hedge (`I assume the baseline's figures came from the same field`, research `:92-93`). Arithmetic: the file has 8,745 characters and 8,755 bytes (`out-t.py.txt` `prelen 8745 bytes 8755`); chars/4 = 2,186, bytes/4 = 2,189. The 3-token gap is immaterial; the label is not what was computed.

**Evidence:** `runs/review-arms/a8-2026-11-19/token-ledger.md:3-5`, `docs/working/research-2026-11-19-a8-token-measurement.md:40,92-93`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:3`, `out-t.py.txt`

---

## Claim 26: per-agent ledger rows and subtotals (tokens, tool_uses, durations, outcome strings; Stage 1 subtotal 311,975 / 57 tool uses; Stage 2 431,780 / 35; 4 comparable critics 352,090; merged 18 claims, 5V/3MA/7I/3U, agreement 9/17; Stage 2.5 "7 entries: 5V (3 executed) / 1MA / 1U / 0I")

**Location:** `runs/review-arms/a8-2026-11-19/token-ledger.md:10-22`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers token figures, durations, sums, and outcome strings against each report's header; does not establish the notifications' tool_uses counts (transcripts count one more tool_use for every agent, e.g. api 8 vs 7, r3 36 vs 35), and r2's own header (14 claims, 5V) under-counts its body (15 verdict lines, 6 Verified), which the ledger copies.
**Legibility-target:** for-orchestrator-synthesis

Durations from `out-s4.py.txt`: r1 488, r2 484, r3 504, security 244, performance 106, api 4,439, arch 117, test-strategy 131, Stage 2.5 252 s, all equal to the ledger. Sums: 13+9+35 = 57; 5+6+8+9+7 = 35; 103,326+78,987+88,378+81,399 = 352,090. Headers: `**Summary:** 6 verified, 4 mostly accurate, 0 stale, 5 incorrect, 2 unverifiable` (r1 `:9`), `5 verified, 0 mostly accurate, 0 stale, 7 incorrect, 2 unverifiable` (r2 `:9`), `11 verified, 2 mostly accurate, 0 stale, 4 incorrect, 2 unverifiable` (r3 `:9`), merged `**Total claims checked:** 18` / `5 verified, 3 mostly accurate, 0 stale, 7 incorrect, 3 unverifiable` (`code-fact-check-report.md:10-11`), `- Agreement rate: 9/17 = 53%` (`:349`), submitted `5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable` with 3 `executed` mode lines (`code-fact-check-submitted-claims.md:9`). The `results.md:126-128` restatement (api 4,439 s for 7 tool uses; others 106-504 s) carries the same tool_uses caveat.

**Evidence:** `runs/review-arms/a8-2026-11-19/token-ledger.md:10-22`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report-r1.md:9`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report-r2.md:8-9,15-328`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report-r3.md:9`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-report.md:10-11,349`, `runs/review-arms/a8-2026-11-19/csp/code-fact-check-submitted-claims.md:8-9`, `out-s4.py.txt`

---

## Claims in the verdict paragraph (§4)

The §4 claims are numbered after Claim 26 so that harvested-claim numbering stays sequential. Their locations are in `results.md`.

## Claim 27: "The +24-40% per-agent growth since August is real. Lever #3 accounts for at most 3 of those points."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:110-111`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the per-agent growth range and the block's size as points of each agent's baseline figure; does not establish the block's net (vs self-read) cost.
**Legibility-target:** for-author

Per agent, growth runs from +15% (architecture) and +18% (performance) to +40% (fact-check per replicate) (`results.md:31,33`); +24% is the four-critic aggregate, not a per-agent floor. As points of each agent's baseline, the inlined block is fact-check 2,189/74,274 = 2.9, security 3.8, api 4.3, architecture 4.1, performance 4.4, test-strategy 4.4 points, and ≈4.0 points at the k=1-equivalent aggregate (16,834/424,520). "At most 3 points" conflates "≈3% of today's core total" with points of growth over the baseline and understates the bound. The conclusion (lever #3 is a minor share of the growth) holds.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:30-36`, `runs/review-arms/a8-2026-11-19/manifest.json:13-14,41`

---

## Claim 28: "**Verdict: fails as stated.** The lever's benefit was 0 here and its token-count effect was small but not zero."

**Location:** `runs/review-arms/a8-2026-11-19/results.md:112-114`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** The "benefit was 0 here" half is established for this single terminal pass by Claim 17 (no first-call cache read of the shared block on any of 9 agents); this does not establish the loop-pass reuse the skill also claims (`SKILL.md:274-275` "and again on the next loop pass"). The "token-count effect ... not zero" half is not established.
**Legibility-target:** for-orchestrator-synthesis

The same section says the opposite of the second half: `On a 2-file diff a self-reading agent would likely read the same two files anyway, so the net token-count cost is probably near zero, but this pass had no self-read arm to show it.` (`results.md:105-107`). The measured 2.2k-2.9k is the gross size of the inlined block. The SKILL's "0% of token count" is a net claim against self-read delivery, and this run has no control for it, so "small but not zero" is stated as a finding without the evidence to back it. Needed to verify: the self-read control arm the results themselves propose (`:120-121`). "Fails as stated" rests soundly only on the benefit half, and only for one terminal pass on one cell. The paragraph's last sentence (`One cell cannot tell how either scales`) is accurate.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:104-121`, `skills/code-review/SKILL.md:274-277,352-353`

---

## Claims Requiring Attention

### Incorrect
- **Claim 23** (`runs/review-arms/a8-2026-11-19/results.md:98-100`): the "new since the canon" prefetch and worker-src findings are canon N1 (graduated, fix-confirmed `ab4dbdb`) and N7 (refuted by E7r2; re-assertion scored as a false positive) at `canon-issue-ledger.md:176-189,372`. Rubric A4 repeats a refuted claim. Drop "new" and flag A4 as a known false positive for re-scoring.

### Mostly Accurate
- **Claim 3** (`docs/working/research-2026-11-19-a8-token-measurement.md:24`; also `manifest.json:4`, `results.md:16`): `SKILL.md` last changed in 44724747; 82accdd7 touched only `references/rubric.md`. The content is identical.
- **Claim 4** (`docs/working/research-2026-11-19-a8-token-measurement.md:55,73-75`): the skill files are 14.5-34 KB, not 25-34 KB. The pasted total would be 219 KB (or 251 KB with Stage 2.5), not 190 KB.
- **Claim 11** (`runs/review-arms/a8-2026-11-19/results.md:46-47`): 23.4k is the 9-agent sum including Stage 2.5. The 8 core agents carry 21.2k (2.85%). "≈3%" survives either way.
- **Claim 18** (`runs/review-arms/a8-2026-11-19/results.md:65-70`): "cannot tell them apart" overlooks the transcripts' recorded `cacheControl` breakpoints (`system[0]`, `system[1]`, `messages[1].content[3]`), which bear on explanation two.
- **Claim 21** (`runs/review-arms/a8-2026-11-19/results.md:91-92`): the brief does not name `exportGraph.ts`, but it does steer toward the client-side code under connect-src and asks "(does anything read it?)" for x-nonce. Drop "or any finding".
- **Claim 24b** (`runs/review-arms/a8-2026-11-19/results.md:41-42`): the ~97k remainder is +27% on the 5-agent base. The +26% is the separate k=1-equivalent delta of 111k.
- **Claim 25** (`runs/review-arms/a8-2026-11-19/token-ledger.md:3-5`): the field is called `total_tokens` here but `subagent_tokens` elsewhere. Baseline identity is asserted without the research doc's "I assume". 2,189 is bytes/4; chars/4 is 2,186.
- **Claim 27** (`runs/review-arms/a8-2026-11-19/results.md:110-111`): per-agent growth runs +15% to +40%. The block is 2.9-4.4 points of each agent's baseline (≈4 in aggregate), not "at most 3".

### Unverifiable
- **Claim 15** (`runs/review-arms/a8-2026-11-19/results.md:52`): checking it needs a search of the August session task directories for transcripts.
- **Claim 28** (`runs/review-arms/a8-2026-11-19/results.md:112-114`): "token-count effect ... not zero" needs the self-read control arm. §4 itself says the net cost is probably near zero. The benefit-0 half holds for this single pass only.

## Goal-Alignment Note
- Success criterion (restated verbatim): A code-fact-check report saved to /workspace/.claude/wt-2026-11-19-a8-token-measurement/docs/reviews/code-fact-check-report-2026-11-19-a8-r2.md, with `Commit: 123432af` as its first line, structured per the code-fact-check skill.
- Answered: yes
- Out of scope: Adjudicating the csp findings against the benchmark code. Re-running r3's `next start`. Reading the notifications' tool_uses field, which I could not access.
- Escalate: (1) Claim 23: rubric A4 (worker-src) repeats canon N7, which E7r2 refuted. Any re-score crediting it adds a known false positive. (2) Claim 18: inspecting what `messages[1].content[3]` is in the recorded `cacheControl` may answer the cache-breakpoint question without a new probe.
