Commit: f87a1455
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-cache-probe (branch `measure/a8-cache-probe`)
**Scope:** `git diff 8b06087719a4fd260cf692be9f5d485aee8535f1..HEAD` (commits 4363a15c, f87a1455): `docs/reviews/code-review-rubric-2026-08-07-main.md`, `docs/working/research-2026-11-19-a8-cache-probe.md`, `runs/review-arms/a8-2026-11-19/cache-probe.md`, plus both commit messages. Replicate r3 of k=3.
**Checked:** 2026-11-19
**Total claims checked:** 35
**Summary:** 28 verified, 5 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Execution logs, in the review scratch directory `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/fc3/` (called `fc3/` below). Each `*-out.txt` file starts with its command, its cwd (`fc3/`) and a UTC start time (all 2026-11-19T19:50:24Z–19:50:25Z), and ends with its exit code (all 0). The transcripts read are under `/home/node/.claude/projects/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/` (`subagents/agent-a047a7e5a841ceab4.jsonl` = A, `agent-ad0565873cbe05c85.jsonl` = B, `agent-a6a0ebd8bee725384.jsonl` = the A8 run's Stage 2.5 agent, `agent-a5e7f4589d043ec6c.jsonl` = the build-loop orchestrator that dispatched A and B). All were parsed with `python3 -I`, stdlib only.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 5 entries) read first. No claim here matches a logged pattern. The closest family is the miscounted figure ("85 tests" vs 97, "mode1-equiv 33" vs 25), and every figure below was re-derived from the records.

---

## Claim 1: "**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation (A8 split to Q-308 on 2026-11-19 after its measurement and cache probe; all other reds/ambers fixed in iterations 1–3)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`
**Type:** Invariant / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the claim that every 🔴/🟡 row at HEAD is closed (A8 by Split, every other by Fixed in iteration 1, 2 or 3) and that the line starts with the template's all-resolved text; does not establish whether the template allows the appended parenthetical (rubric.md neither allows nor forbids it), and does not cover 🟢 rows (C2, C3 and C6 are iter 4, but the line's "reds/ambers" excludes them).

The template line is `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation` (`skills/code-review/references/rubric.md:609`). The new line reproduces it verbatim and then appends a parenthetical, so the single-sample label still appears exactly once, as rubric.md requires: "Carry this label, verbatim and once" (`rubric.md:619`), "appended to the `✅ PASSES REVIEW` status line" (`rubric.md:623-624`). The repo's own parser (`rubric_parse` in `scripts/lib/rubric-check.sh:76`) run on the HEAD copy classifies every red and amber row as `fixed`, except `row amber A8 closed Split — measured 2026-11-19…` (`fc3/parse-out.txt`, third block). Iteration numbers per row: R1 `✅ Fixed (iter 1` (`:17`); A1, A2, A4, A5, A9, A10, A11, A12 `iter 1` (`:28,29,31,32,36-39`); A3 and A7 `iter 2` (`:30,:34`); A6 `iter 3` (`:33`). The iter-4 rows are all 🟢: C2 `✅ Fixed (iter 4` (`:51`), C3 (`:52`), C6 (`:55`).

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4,17,28-39,51-55`, `skills/code-review/references/rubric.md:605-625`, `fc3/parse-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: "No agent read the shared block from another's cache in the A8 pass (`results.md` §2, §4; merge approved Q-306) … a second agent 28.5 s later, same block byte for byte, still read only 18,900 tokens"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the cited sections' wording, Q-306's answer, and B's first-call cache read and timing in the transcripts; does not establish the A8 pass's per-agent figures beyond what results.md §2 states (I did not re-read all 9 A8 transcripts, only Stage 2.5's).

results.md §2 states it: "**No agent read the shared block from another agent's cache.** Each agent's first call read exactly 18,900 cached tokens" (`runs/review-arms/a8-2026-11-19/results.md:65-66`). §4 says the same: "No agent read the shared block from another agent's cache" (`:123-124`). Q-306 is answered `Q-306: [1]`, and option [1] is `**[1] merge**` (`docs/working/questions-archive.md:7552-7554`, the options table further down the same entry). For B the transcript gives `usage 2026-11-19T19:39:48.458Z … "cache_read_input_tokens": 18900` and first request `2026-11-19T19:39:44.554Z`. A's reply record is `asst ts 2026-11-19T19:39:16.055Z`, and 44.554 − 16.055 = 28.499 s (`fc3/detail-out.txt`, `fc3/arith-out.txt`). The byte-identity check is in Claim 11.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:65-72,123-126`, `docs/working/questions-archive.md:7552-7634`, `fc3/detail-out.txt`, `fc3/arith-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: "and no prompt order puts a breakpoint at the block's end"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Agent-tool path as recorded (the prompt goes out as one content block; breakpoints at `system[0]`, `system[1]` and the request's last block) in A, B and the A8 Stage 2.5 agent; does not establish behavior under other dispatch paths (headless `claude -p`, the API directly) or under future Claude Code versions.

In all three transcripts, `messages[0].content[3]` is the whole Agent-tool prompt plus one trailing `'\n'` (`blk3==prompt A False 8932 8931 '\n'`, `fc3/more-out.txt`), and it is the only block holding prompt text. Every first request carries `cacheControl` paths `[['system', 0], ['system', 1], ['messages', 1, 'content', 3]]`. In the A8 agent's later calls the third breakpoint moves to the last message (`['messages', 4, 'content', 0]`, `['messages', 6, …]`, `fc3/later-out.txt`), so it is the request's last block, not a position the prompt chooses. Since the shared block and the tail share one text block, no block boundary falls at the shared block's end.

**Evidence:** `fc3/detail-out.txt`, `fc3/more-out.txt`, `fc3/later-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: "Split — … Net inline cost and recall effect moved to Q-308"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the status word's validity for a 🟡 row, the presence of the required tracked follow-up, Q-308's existence and coverage, and the parser reading the row as closed; does not establish that Q-308 will be answered in a way that measures both remainders (its option [3] closes A8 without measuring them).

rubric.md lists `` | `Split` | 🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch) | `` (`skills/code-review/references/rubric.md:204`), and the cell carries Q-308. Q-308 is open (`### Q-308 · a8-settling-runs` … `**Status:** OPEN`, `docs/working/questions.md:166-167`). It asks for "a self-read control pass on the csp cell and a pass on the larger corpus cell", and its option [3] reads "The inline cost and recall effect stay unknown" (`questions.md:169,180`), so it covers both remainders. The cell starts with `Split`, as the Status-words rule requires (`rubric.md:192-194`), and the parser reads it as `closed` (`fc3/parse-out.txt`). Q-304 (`questions-archive.md:7485`) is the go-ahead for the A8 run. Neither changed doc cites it, and it does not bear on the closure.

**Evidence:** `skills/code-review/references/rubric.md:190-211`, `docs/working/questions.md:166-187`, `docs/working/questions-archive.md:7485-7507`, `fc3/parse-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "`api-request-shape` (system), `api-request-blob` (per-message content blocks), `api-request` (`cacheControl` paths, `tail` blob hashes, timestamp)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:15-18`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record types and their fields in the probe and A8 transcripts; does not establish the records' format in other Claude Code versions.

The `api-request-shape` record holds both the system blocks and the tool definitions: `shape keys ['system', 'tools']`, with `tools list 11` (`fc3/detail-out.txt`). The other two descriptions match: blob records carry `message.role` and `content`, and `api-request` carries `cacheControl`, `tail` and `timestamp` (`fc3/detail-out.txt`). Precise version: "`api-request-shape` (system and tools)". This matters slightly because the tools are part of the 18,900-token cached prefix (Claim 23).

**Evidence:** `fc3/detail-out.txt`
**Legibility-target:** for-author

---

## Claim 6: "In an A8 record (Stage 2.5's agent), the first request is: system (2 blocks, breakpoints on both); `messages[0]` user with 5 text blocks (…); `messages[1]` a system-role message with the skill listing and three deferred tool definitions, breakpoint on its last block."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:19-22`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agent-a6a0ebd8bee725384's identity and its first request's layout; does not establish whether role `system` is how `messages[1]` goes out on the wire (the record shows Claude Code's internal role).

The agent is Stage 2.5: its prompt opens its role section with `## Your role: code fact-check, Stage 2.5 submitted claims (k=1)`, and its last call sums to `108530`, the ledger's Stage 2.5 figure (`fc3/a8-out.txt`; `runs/review-arms/a8-2026-11-19/token-ledger.md`, row 9). The system has 2 blocks, the breakpoints are on `system[0]` and `system[1]`, `messages[0]` is `role user nblocks 5` in the stated order, and `messages[1]` is `role system nblocks 4` with its breakpoint at `['messages', 1, 'content', 3]` (`fc3/detail-out.txt`). Imprecise part: `messages[1].content[0]` is not only the skill listing. It holds three sections: "The following tools just became available and are ready to use:", "The following deferred tools are now available via ToolSearch…" and "The following skills are available…" (`fc3/more-out.txt`). Blocks [1]–[3] are `tool_addition` definitions of `mcp__claude_ai_Claude_Docs__batch`, `__guide` and `__update`. Those are the tools the notice calls ready to use, not the deferred ones (deferred tools appear only by name). Precise version: "a system-role message: the tool and skill listings, then three added tool definitions".

**Evidence:** `fc3/detail-out.txt`, `fc3/more-out.txt`, `fc3/a8-out.txt`, `runs/review-arms/a8-2026-11-19/token-ledger.md:20`
**Legibility-target:** for-author

---

## Claim 7: "Skill section under test: `skills/code-review/SKILL.md` "Inline shared-context prefix (decision 032 #3)", lines 268-358."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:23-24`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section's span at HEAD (SKILL.md is not changed by this diff); does not establish the span at any other commit.

`skills/code-review/SKILL.md:268` is `### Inline shared-context prefix (decision 032 #3)`, its last content line `:358` is "there (decision 032 H4) — see the guard note in that file's module docstring.", and `:360` is the next heading, `### Between-stage status banner`. `git diff --stat 8b060877..HEAD -- skills/` is empty (paraphrased — no quote available because the claim covers absence of a change: the command printed nothing).

**Evidence:** `skills/code-review/SKILL.md:268-360`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: "Rubric row: `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `🟡 Open`"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:25-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the row at the base commit 8b060877, where the research started; does not apply at HEAD, where the row is Split (as intended).

At base, line 35 begins `| A8 | "Leav` and contains `🟡 Open` (from `git show 8b060877:docs/reviews/code-review-rubric-2026-08-07-main.md`, copied to `fc3/rubric-base.md`). The parser reads it as `row amber A8 open 🟡 Open` (`fc3/parse-out.txt`, first block).

**Evidence:** `fc3/rubric-base.md:35`, `fc3/parse-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "Q-306: the owner approved merging the A8 results. Q-308: the owner's open question on the two larger settling runs (self-read control, corpus cell)."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:27-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both entries on the branch and on main (same line numbers); does not establish that the A8 merge itself landed (not needed by the claim).

Q-306: `**Status:** ANSWERED` / `Q-306: [1]`, where [1] is `**[1] merge**` (`docs/working/questions-archive.md:7553-7554`). Q-308: `**Status:** OPEN`, "a self-read control pass on the csp cell and a pass on the larger corpus cell" (`docs/working/questions.md:167-169`). `git show main:` lists both at the same line numbers (paraphrased — no quote available because this is a heading-line grep with identical output on both refs).

**Evidence:** `docs/working/questions-archive.md:7552-7554`, `docs/working/questions.md:166-169`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "Two `general-purpose` subagents, the A8 Stage-1 block (`csp/shared-block.md`) pasted first, then a one-line tail differing in one letter; B dispatched after A finished. A stdlib script … checked each recorded prompt starts with the block file byte for byte"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:39-42`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the dispatch calls, the tail difference, the ordering and the script's check; does not establish the script's internals beyond what probe.py shows (it compares decoded text, not raw bytes; my own raw-bytes check agrees).

The orchestrator transcript holds two Agent calls, both `general-purpose`: A at `19:39:12.855Z` and B at `19:39:44.268Z` (`fc3/dispatch-out.txt`). A's hand-back tool result is at `2026-11-19T19:39:16.656Z`, before B's dispatch (`fc3/more-out.txt`). Blocks [3] of A and B are the same length and differ in exactly one character: `A vs B blk3 diffs [(8768, 'A', 'B')] True` (`fc3/more-out.txt`). probe.py tests `prompt.startswith(block)` on the text-mode read of the file (`probe.py:3,6`). On raw bytes I got `bytes startswith True` for both (`fc3/detail-out.txt`), and the file has no CR bytes, so the two checks are equivalent.

**Evidence:** `fc3/dispatch-out.txt`, `fc3/more-out.txt`, `fc3/detail-out.txt`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/probe.py:3-6`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "Both prompts start with the block byte for byte. All user content blocks except [3] (the prompt) hash the same; the system-role message hashes the same. A: read 18,900, created 31,731. B, 28.5 s after A's reply: read 18,900, created 31,731."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:46-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first request and first usage of A and B; does not establish later calls (each agent made only one API call before its hand-back).

Hashes: A's user blocks `42844d66 e9d8ab24 cb65f80a 036e3261 2ee8513e`, B's `42844d66 e9d8ab24 cb65f80a 6c809541 2ee8513e`. The system-role blob is `14236cb7f9a8` in both. Usage for both: `"cache_creation_input_tokens": 31731, "cache_read_input_tokens": 18900` (`fc3/detail-out.txt`). The 28.5 s figure is Claim 2's.

**Evidence:** `fc3/detail-out.txt`, `fc3/arith-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12a: "Breakpoints are fixed by Claude Code at `system[0]`, `system[1]` and the request's last block. The prompt is a single content block … So no ordering inside the prompt puts a block boundary, let alone a breakpoint, at the shared block's end. Criterion 2's "no" branch: the skill stays unchanged."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:50-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the records-based part and the unchanged skill; does not establish the whole-block matching rule (Claim 12b) or other dispatch paths.

Same evidence as Claim 3: the breakpoints are identical across three agents and follow the last message in later calls (`fc3/later-out.txt`), and the prompt is one block (`fc3/more-out.txt`). The brief's criterion 2 makes "change nothing" the branch taken when no order works: "if one does, change `skills/code-review/SKILL.md`'s … section" (`docs/working/briefs/2026-11-19-a8-cache-probe.md:19`). The skill is unchanged in the diff (Claim 7).

**Evidence:** `fc3/later-out.txt`, `fc3/more-out.txt`, `docs/working/briefs/2026-11-19-a8-cache-probe.md:19`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12b: "cache matching is by whole block (Anthropic prompt-caching docs via a search summary, unverified here)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:51-52`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only whether the rule is correctly flagged; does not establish the rule itself.

The doc flags it unverified, as FP-091 requires (`docs/failure-patterns.md:233`). The sandbox has no egress, so the Anthropic page cannot be fetched. The records agree with the rule: B's read is the same 18,900 even though its blocks [0]–[2] are byte-identical to A's (`fc3/detail-out.txt`). But they cannot prove it, because no entry was written at those boundaries either way. Needed: a host fetch of the prompt-caching documentation, or a probe with a breakpoint placed by the caller.

**Evidence:** `docs/failure-patterns.md:233`, `fc3/detail-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "Minor correction to `results.md` §2: breakpoint 3 is on the system-role message after the user turn, not on the user turn's end; still after the tail. Recorded in the probe doc, not edited into the merged results"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:55-57`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers §2's wording, the record's role field and the unchanged results.md; does not establish the wire-level role (as in Claim 6).

§2 reads: "`system[0]`, `system[1]` and `messages[1].content[3]`, the end of the first user turn, after the per-agent tail" (`runs/review-arms/a8-2026-11-19/results.md:74-75`). The record shows `blob 14236cb7f9a8 role system nblocks 4` for `messages[1]` (`fc3/detail-out.txt`), so the correction is right. `results.md` is not in the diff's three files (paraphrased — no quote available because this is the absence of a path in `git diff --stat`).

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:73-83`, `fc3/detail-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: "`Split` (remaining work moved to a tracked follow-up, Q-308) and `Acknowledged` (stands with a qualifying note). `Split` fits"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:62-64`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two words' definitions as paraphrased; does not adjudicate the choice (both are valid for 🟡; Split matches "moved to another unit").

`` | `Acknowledged` | 🟡, 🟢 | stands with a [qualifying author note]… `` and `` | `Split` | 🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch) | `` (`skills/code-review/references/rubric.md:201,204`).

**Evidence:** `skills/code-review/references/rubric.md:197-206`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "with A8 split and every other row fixed, it becomes the template's all-resolved line"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:65-67`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers "every other row fixed" for 🔴/🟡 and the template prefix; does not establish that the parenthetical appended after the template text conforms (see Claim 1).

The parser marks every red and amber row except A8 `fixed` (`fc3/parse-out.txt`). The new status line begins with `rubric.md:609`'s template text verbatim (Claim 1).

**Evidence:** `fc3/parse-out.txt`, `skills/code-review/references/rubric.md:609`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "a byte-identical whole prompt with the role sent another way would let a sibling hit the whole ~31.7k prefix"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:68-70`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the figure against the records under the cache rule of Claim 12b; does not establish that such a sibling would actually hit (untested).

With a byte-identical request, the match would be at the final breakpoint, `messages[1].content[3]`. The cached prefix would then be the whole request, 18,900 + 31,731 + 2 = 50,633 tokens, of which the ~31.7k is what each agent now writes fresh (`fc3/detail-out.txt`). The 31.7k is therefore the additional saving, not the size of "the prefix". Precise version: "hit the whole request prefix, saving the ~31.7k each agent now writes fresh".

**Evidence:** `fc3/detail-out.txt`, `fc3/arith-out.txt`
**Legibility-target:** for-author

---

## Claim 17: "The skill still says the cache "serve[s] the shared block to all ~8 agents" and "Leave it on because it is free" (`SKILL.md:274-277`, `:352-354`)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:74-77`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both quotes at HEAD; does not cover the rubric row's own older citation `SKILL.md:276-278`, which is unchanged context written against 2f5ad0b (where `:276-278` does hold "0% of token count … Leave it on because it is free") and points at `:352-353` at HEAD.

`SKILL.md:274-275`: "This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a pass". `:352-353`: "**Measured benefit is modest — single-digit-% of input cost, 0% of token count** … Leave it on because it is free; do not expect" (excerpt ends :353; the bullet continues to :354, "it to move the token-count ledger." — read).

**Evidence:** `skills/code-review/SKILL.md:270-277,352-354`; `git show 2f5ad0b:skills/code-review/SKILL.md` lines 276-278
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "Question from `results.md` §4 ("Three things would tell", first item)"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:3-7`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and the question's framing; does not establish anything beyond it.

"Three things would tell. First, a two-agent cache probe: same shared block, dispatched one after the other within 5 minutes, comparing first-call `cache_read_input_tokens`" (`runs/review-arms/a8-2026-11-19/results.md:138-139`).

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:138-143`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "Shared block: `csp/shared-block.md` (8,755 bytes, the A8 pass's Stage-1 block)"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:11-12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size and its identity with the A8 Stage-1 shared part; does not cover the Stage-2 block.

`wc -c` prints `8755` (`fc3/wc-out.txt`). Its sha256 prefix is `be4a2600985537d5`, which is the Stage-1 hash results.md §2 records: "Stage 1: `be4a2600985537d5` ×3" (`results.md:63-64`).

**Evidence:** `fc3/wc-out.txt`, `runs/review-arms/a8-2026-11-19/results.md:63-64`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "a one-line minimal tail … differing only in the agent's letter … two `general-purpose` Agent-tool subagents from the same orchestrator session, same model (claude-opus-5-5), B dispatched after A had finished."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:13-17`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tail, the agent type, the model, the orchestrator and the ordering; does not establish that the tail is "one line" in a strict sense (it is `\n---\n` plus one sentence line, which is what the doc's wording implies).

The tail is `'\n---\nCache probe agent A. This is a token-measurement probe, not a review: … Hand back exactly the text: OK'` (`fc3/more-out.txt`), and it differs from B's only at index 8768 (Claim 10). The model is `requestedModel claude-opus-5-5` and `model claude-opus-5-5` for both (`fc3/detail-out.txt`). Both Agent calls come from `agent-a5e7f4589d043ec6c.jsonl` and are `general-purpose` (`fc3/dispatch-out.txt`). The ordering is in Claim 10.

**Evidence:** `fc3/more-out.txt`, `fc3/detail-out.txt`, `fc3/dispatch-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: Result table — "First request sent 19:39:13.000Z | 19:39:44.554Z (28.5 s after A's reply at 19:39:16.055Z)"; "Breakpoints `system[0]`, `system[1]`, `messages[1].content[3]` | same"; cache read 18,900 / 18,900; creation 31,731 / 31,731; input/output 2 / 52; "Notified `subagent_tokens` 50,685 | 50,685"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:26-34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell of the table (the byte-identity row is Claim 10); does not establish what `subagent_tokens` measures beyond equalling the last call's four-field sum (results.md §1's reading).

`req 2026-11-19T19:39:13.000Z` and `req 2026-11-19T19:39:44.554Z`. Both have `cacheControl` `['system', 0]`, `['system', 1]`, `['messages', 1, 'content', 3]`. Both report `{"input_tokens": 2, "cache_creation_input_tokens": 31731, "cache_read_input_tokens": 18900, "output_tokens": 52` (`fc3/detail-out.txt`). The parent notifications show `<subagent_tokens>50685</subagent_tokens>` for a047a7e5… and for ad056587… (`fc3/notif-out.txt`), and 2+31731+18900+52 = 50685 (`fc3/arith-out.txt`).

**Evidence:** `fc3/detail-out.txt`, `fc3/notif-out.txt`, `fc3/arith-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "B started 28.5 s after A, well inside the 5-minute lifetime (`promptCacheRequested: 5m`). Its cache read did not rise at all."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:36-38`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the TTL field and the unchanged read; does not establish the server-side TTL beyond the requested value (`ephemeral_5m_input_tokens: 31731` is consistent with it).

`pcr 5m` on both assistant records, and `"ephemeral_5m_input_tokens": 31731` (`fc3/detail-out.txt`). "28.5 s after A" means after A's reply (as the table states). A's request went out 31.55 s before B's.

**Evidence:** `fc3/detail-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "Breakpoints 1 and 2 sit here, and tools and system are what the 18,900 cached tokens are."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:44-45`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers consistency of 18,900 with the tools + system prefix; does not establish an exact token count (no tokenizer offline).

At the request's own chars-per-token ratio (2.903), tools + system estimate to `19771` tokens. Tools + system + `messages[0].content[0]` estimate to `36418` (`fc3/ratio-out.txt`), so 18,900 fits the `system[1]` breakpoint and no later boundary. It is also the same 18,900 for the A8 agent, whose `messages[0].content[1]` differs (`8bf9945c` vs `e9d8ab24`, `fc3/detail-out.txt`), so the cached part ends before that block. Medium confidence because the count is an estimate.

**Evidence:** `fc3/ratio-out.txt`, `fc3/detail-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "`messages[0]` (user), five text blocks: [0] the instruction files, [1] git status, [2] commit attribution, **[3] the whole prompt (shared block + tail)**, [4] the hand-off reminder. Blocks 0-2 and 4 hash the same in A and B; only block 3 differs."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:46-48`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first request of A and B; does not establish the layout for agents whose harness context differs (other sessions, other settings).

The blocks begin `'<system-reminder>\nCodebase and user instructions…'`, `"…you can use the following context:\n#"` (git status), `'<system-reminder>\nAttribution for git commits…'`, `'# Review pass: shared context…'` and `'<system-reminder>\nYour final report is delivered through SubagentHandback…'`. The hashes are as in Claim 11 (`fc3/detail-out.txt`).

**Evidence:** `fc3/detail-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: "`messages[1]` (a system-role message), four blocks: the skill listing, then three deferred tool definitions. Breakpoint 3 is on its last block, `messages[1].content[3]`: the end of the request."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:49-51`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the role, the block count, the breakpoint and "end of the request" (`tail` holds exactly the two message blobs); does not establish the wire-level role.

The record shows `role system nblocks 4`. Block [0] holds the newly-available-tools notice, the deferred-tool name list and the skill listing, and [1]–[3] are `tool_addition` definitions of the three Claude Docs tools that are "ready to use", not deferred (`fc3/more-out.txt`; same finding as Claim 6). The request's `tail` is `[user blob, system blob]`, so `messages[1]` is the last message (`fc3/detail-out.txt`). Precise version: "the tool and skill listings, then three added tool definitions".

**Evidence:** `fc3/more-out.txt`, `fc3/detail-out.txt`
**Legibility-target:** for-author

---

## Claim 26: "A small correction to `results.md` §2, which reads this path as "the end of the first user turn" … The conclusion stands: the breakpoint sits after the per-agent tail."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:53-55`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 13.

The quote matches `results.md:75` ("the end of the first user turn"). `messages[1]` has role `system` (`fc3/detail-out.txt`).

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:73-76`, `fc3/detail-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: "Prompt caching matches on whole content blocks. On each breakpoint the API checks earlier content-block boundaries (up to about 20 blocks back) for an entry an earlier request wrote there."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:57-60`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the claim is flagged unverified (it is, in the next sentence) and whether the records agree with it (they do); does not establish the rule or the "about 20 blocks" figure.

The doc says "seen through a web-search summary only; this sandbox cannot fetch it, so treat the wording as unverified" (`cache-probe.md:60-61`). There is no egress here. Needed: a host fetch of platform.claude.com/docs/en/build-with-claude/prompt-caching.

**Evidence:** `runs/review-arms/a8-2026-11-19/cache-probe.md:57-61`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: "A's entries end at `system[1]` and at the end of its own request. B's request differs from A's inside `messages[0].content[3]`, so the longest entry B can match is `system[1]`: 18,900 tokens. Nothing ever ends at the shared block's last byte"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:61-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agreement with the records (breakpoints, the first differing block, the 18,900 read); does not establish the cache rule this reasoning rests on (Claim 27). A also wrote at `system[0]`, which is a shorter prefix and does not change the conclusion.

A's breakpoints are `system[0]`, `system[1]` and `messages[1].content[3]`. The first block where A and B differ is user [3] (`036e3261` vs `6c809541`), and B read `18900` (`fc3/detail-out.txt`). The shared block and the tail share block [3] (`fc3/more-out.txt`).

**Evidence:** `fc3/detail-out.txt`, `fc3/more-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: "The Agent tool takes the prompt as one string and sends it as one content block. The breakpoints are placed by Claude Code on the system prompt and on the request's last block. The orchestrator controls neither. … Per the brief (criterion 2), the skill is unchanged."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:68-73`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As Claim 3; "controls neither" is established for the Agent tool's inputs (`subagent_type`, `description`, `prompt`, optional `model`/`run_in_background`), and does not cover other harness settings.

The Agent call's inputs carry the prompt as one string field (`'prompt': 10594` chars in the build-loop dispatch, `fc3/dispatch-out.txt`; the same shape for the probe calls). It arrives as block [3] plus `'\n'` (`fc3/more-out.txt`). The breakpoint positions are in `fc3/later-out.txt`. The skill is unchanged (Claim 7).

**Evidence:** `fc3/dispatch-out.txt`, `fc3/more-out.txt`, `fc3/later-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: "Matching would serve more than the block: B's whole prefix up to block 3 (instruction files included), roughly the 31.7k tokens each agent now writes fresh."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:77-78`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the region and the figure against the records; does not establish that a whole-prompt match would occur (untested; it depends on Claim 27).

A byte-identical request matches at its last breakpoint, `messages[1].content[3]`. That covers user blocks [0]–[4] and all of `messages[1]`, not a prefix "up to block 3". The ~31.7k figure is the size of that whole region after `system[1]` (`cache_creation_input_tokens: 31731`, `fc3/detail-out.txt`). At the ratio in `fc3/ratio-out.txt`, user blocks [0]–[3] alone come to roughly 20k (paraphrased — no quote available because the estimate is derived from the block character counts 47023+1782+709+8932 in `fc3/detail-out.txt` at 2.903 chars/token). Precise version: "B's whole request after the system prompt (instruction files, prompt and listings), the 31.7k tokens each agent now writes fresh".

**Evidence:** `fc3/detail-out.txt`, `fc3/ratio-out.txt`
**Legibility-target:** for-author

---

## Claim 31: "Decision 032 lever #3 … yields no cross-agent cache reads on the Agent-tool path, parallel or sequential. … What remains is each agent's own reuse within its run, which happens with or without inlining (`results.md` §2). The probe did not test reuse across loop passes."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:83-91`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parallel case (A8 pass, results.md §2) and the sequential case (this probe) on one session's Agent-tool path, the §2 citation, and the untested cross-pass case; does not establish behavior for later loop passes beyond the stated inference.

Parallel: "This held for all 9 agents" (`results.md:67`). Sequential: B read `18900` (`fc3/detail-out.txt`). Within-run reuse: "an agent's later calls usually re-read its own prefix from cache, block included, which happens with or without inlining" (`results.md:68-69`). Each probe agent made one API call and then handed back (`fc3/more-out.txt`), so no loop pass was exercised. The SKILL quotes and line numbers are Claim 17's.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:65-72`, `fc3/detail-out.txt`, `fc3/more-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: "Cost of the probe: 2 × 50,685 = 101,370 tokens by the notified figure. Nearly all of that is the harness context every agent starts with, not the tail."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:93-94`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic and the order of magnitude of the split; does not separate the shared block (~3k tokens at the request's ratio) from "harness context" exactly. The block is neither harness nor tail, and "nearly all" holds with it either way (~94% excluding it).

`101370` (`fc3/arith-out.txt`). The prompt is 8,931 of the request's ~147k characters, and the tail is ~180 of those (`fc3/ratio-out.txt`, `fc3/more-out.txt`).

**Evidence:** `fc3/arith-out.txt`, `fc3/ratio-out.txt`, `fc3/more-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33: Commit 4363a15c message — "carried the A8 Stage-1 shared block byte for byte, dispatched 28.5 s apart; both first calls read 18,900 cached tokens and wrote 31,731 … the prompt is one content block and Claude Code's breakpoints sit on the system prompt and the request's last block … The skill is unchanged … Rubric row A8 is Split to Q-308."

**Location:** `git show 4363a15c` (commit message body)
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure and statement against the records and the diff; "dispatched 28.5 s apart" is measured from A's reply to B's first request (the dispatch calls were 31.4 s apart: 19:39:12.855Z → 19:39:44.268Z). That is a looser reading of the same interval, not a different finding.

The figures are Claims 11 and 21. The prompt block and breakpoints are Claim 3. The unchanged skill is Claim 7, and Split to Q-308 is Claim 4. Dispatch times are in `fc3/dispatch-out.txt`.

**Evidence:** `fc3/detail-out.txt`, `fc3/dispatch-out.txt`, `fc3/parse-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: Commit f87a1455 message — "The merge check's rubric reader could not read these three rows of code-review-rubric-2026-08-07-main.md: each had 8 cells under a 9-column header."

**Location:** `git show f87a1455` (commit message body)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 🔴 and 🟡 tables at base, at 4363a15c and at HEAD, read by the repo's own `rubric_parse`; does not cover 🟢 rows (not read by the parser; all 7 cells under a 7-column header).

On base and 4363a15c copies the parser prints `bad 30 row A3 has 8 cells where its header has 9`, `bad 33 row A6 …`, `bad 34 row A7 …`. On HEAD it prints no `bad` line, and A3, A6 and A7 read as `fixed` (`fc3/parse-out.txt`). Independent count: base `30 A3 8`, `33 A6 8`, `34 A7 8`, every other amber 9, and the R1 row 8 under an 8-column header. HEAD has all ambers at 9 (`fc3/cells-out.txt`). "No status changed": the three rows' Status cells are byte-identical apart from the appended ` | — |` (diff hunk `@@ -27,12 +27,12 @@`).

**Evidence:** `fc3/parse-out.txt`, `fc3/cells-out.txt`, `scripts/lib/rubric-check.sh:135-152`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 5** (`docs/working/research-2026-11-19-a8-cache-probe.md:16-17`): `api-request-shape` holds system **and tools**, not system only.
- **Claim 6** (`docs/working/research-2026-11-19-a8-cache-probe.md:21-22`): `messages[1]` holds the tool-availability notice, the deferred-tool name list and the skill listing in block [0], then three `tool_addition` definitions of the ready-to-use Claude Docs tools. They are not "deferred tool definitions".
- **Claim 16** (`docs/working/research-2026-11-19-a8-cache-probe.md:68-69`): a whole-prompt match would hit the whole request prefix (~50.6k); the ~31.7k is the extra saving, not the prefix's size.
- **Claim 25** (`runs/review-arms/a8-2026-11-19/cache-probe.md:49-50`): same mislabel as Claim 6 ("the skill listing, then three deferred tool definitions").
- **Claim 30** (`runs/review-arms/a8-2026-11-19/cache-probe.md:77-78`): "B's whole prefix up to block 3" understates the region; the ~31.7k is everything after `system[1]` (user blocks 0–4 and `messages[1]`). Blocks 0–3 alone are ~20k.

### Unverifiable
- **Claim 12b** (`docs/working/research-2026-11-19-a8-cache-probe.md:51-52`) and **Claim 27** (`runs/review-arms/a8-2026-11-19/cache-probe.md:57-60`): the whole-block matching rule and "about 20 blocks back" come from a web-search summary and are correctly flagged unverified. Verifying them needs a host fetch of the Anthropic prompt-caching page. The verdict on A8 does not depend on them: the records alone show B read only the system + tools prefix.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "a code-fact-check report saved at the output path below, in the code-fact-check skill's report schema."
- **Answered:** Every brief item 1–12 is checked against the transcripts, the probe output, the repo's rubric parser, results.md, SKILL.md, rubric.md and the questions files: figures (Claims 2, 11, 19, 21, 32), timestamps and TTL (2, 21, 22), request layout (6, 24, 25), byte-identity (10, 11), the §2 correction (13, 26), the no-order reasoning and the 18,900 = system + tools consistency (3, 12a, 23, 28, 29), the web rule's flag (12b, 27), SKILL line refs (7, 17), Split/Q-306/Q-308/Q-304 (4, 9, 14), the status line and iterations (1, 15), cell counts (34), the commit messages (33, 34), and the cross-pass and A8-pass statements (31). No Incorrect or Stale claim was found. The five Mostly-accurate findings are wording precision on the request layout and the whole-prompt saving, and none affects the A8 verdict or the Split.
- **Out of scope:** The rubric row's unchanged text (`SKILL.md:276-278`, written against 2f5ad0b; at HEAD the quotes sit at `:352-353`, noted in Claim 17's Scope) and the A8 row's unchanged Author note ("run the post-restructure measurement once … settled"). Also the brief's "a few thousand tokens each" expectation versus the 50,685 per agent actually spent (a brief statement, not a diff claim).
- **Escalate:** none.
- **Questions:** Q-308's interim option [2] ("After the cache fix") waits on a cache fix that this probe concludes no prompt order can deliver. The cycle may want to restate that entry's options. This is not a claim in the diff.
