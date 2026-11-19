Commit: f87a1455

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-cache-probe (branch measure/a8-cache-probe)
**Scope:** `git diff 8b06087719a4fd260cf692be9f5d485aee8535f1..HEAD` (commits 4363a15c, f87a1455): `docs/reviews/code-review-rubric-2026-08-07-main.md`, `docs/working/research-2026-11-19-a8-cache-probe.md`, `runs/review-arms/a8-2026-11-19/cache-probe.md`, plus both commit messages; replicate r1
**Checked:** 2026-11-19
**Total claims checked:** 26
**Summary:** 21 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Execution provenance. All executed checks ran on 2026-11-19, start 19:48:56Z, each under `timeout 120`, every exit code 0. Each command's output, with its command line, working directory, start time and exit code in the header, is in its own log under `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/fc1/` (called `fc1/` below):
- `fc1/inspect.log`: `python3 -I inspect.py a047a7e5a841ceab4 ad0565873cbe05c85`. Prints record types, blob roles and block lengths, the `api-request` records (cacheControl, tail, model) and the first `assistant` usage.
- `fc1/inspect2.log`: `python3 -I inspect2.py …`. Shows that `messages[0].content[3]` starts with `csp/shared-block.md`, the blocks of `messages[1]`, and `promptCacheRequested`.
- `fc1/inspect3.log`: `python3 -I inspect3.py`. Shows the A8 Stage-2.5 record's first-request breakpoints and the parent session's `<subagent_tokens>` notifications.
- `fc1/inspect4.log`: `python3 -I inspect4.py`. Gives the parent-session queue timestamps, the time deltas and the token sums.
- `fc1/cells.log`: `python3 -I cells.py rub-8b060877.md rub-4363a15c.md rub-HEAD.md`. Counts the cells in each rubric table row at base, at 4363a15c and at HEAD. The inputs came from `git show <rev>:docs/reviews/code-review-rubric-2026-08-07-main.md`.
- `fc1/block.log`: `wc -c` and `sha256sum` of `runs/review-arms/a8-2026-11-19/csp/shared-block.md`, run from the worktree root.

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`) read first. No claim here matches a logged pattern. The closest class is "a specific measured value quoted from an artifact set that does not contain it", and every figure below was found in its source records.

---

## Claim 1: "**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation (A8 split to Q-308 on 2026-11-19 after its measurement and cache probe; all other reds/ambers fixed in iterations 1–3)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`
**Type:** Invariant / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers three things: the line matches the template's all-resolved form; every 🔴/🟡 row at HEAD carries a closing status word; and each non-A8 red or amber was closed in iteration 1, 2 or 3. It does not establish that the appended parenthetical is sanctioned (the template neither allows nor forbids it), or anything about 🟢 rows.

The template line is `- All red and amber resolved: `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation`` (`skills/code-review/references/rubric.md:609`). The line at :4 reproduces it verbatim, then appends a parenthetical. The label rule asks for the label "verbatim and once" on this line (`rubric.md:619-624`). The label appears once. The template does not address a trailing parenthetical.

The closing words and iterations by row: R1 "✅ Fixed (iter 1 …" (:17); A1, A2, A4, A5, A9, A10, A11 and A12 "✅ Fixed (iter 1 …" (:28, :29, :31, :32, :36-39); A3 "✅ Fixed (iter 2 …" (:30); A6 "✅ Fixed (iter 3 …" (:33); A7 "✅ Fixed (iter 2 …" (:34); A8 "Split — measured 2026-11-19 …" (:35). The only "iter 4" cells are 🟢 rows: C2 (:51), C3 (:52) and C6 (:55). So "iterations 1–3" holds for every red and amber. (Unit read: the whole file, :1-102.)

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4,17,28-39,51-55`, `skills/code-review/references/rubric.md:605-628`

---

## Claim 2: "each had 8 cells under a 9-column header" (rows A3, A6, A7; commit f87a1455) and the fix gives each "their empty Author note cell"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:30,33,34` (commit f87a1455 message)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pipe-delimited cell count of every row in the 🔴, 🟡 and 🟢 tables at base, at 4363a15c and at HEAD. It does not establish how the build-loop rubric reader parses rows (`scripts/build-loop.sh` was not run). A cell containing a literal `|` would also throw off a naive split, but none of these rows has one.

From `fc1/cells.log`: at base, the 🟡 header (line 26) has 9 cells, A3, A6 and A7 have 8, and every other 🟡 row has 9. At 4363a15c the counts are unchanged. At HEAD, every 🟡 row (A1-A12) has 9. The 🔴 table has an 8-column header and its R1 row has 8 cells at every revision, so it was never mismatched. The diff adds ` — |` to the end of the A3, A6 and A7 rows and nothing else in those rows (shared-block diff, rubric hunk lines 37-38 and 41-45).

**Evidence:** `fc1/cells.log`, `docs/reviews/code-review-rubric-2026-08-07-main.md:15-17,26-39`

---

## Claim 3: "No agent read the shared block from another's cache in the A8 pass (`runs/review-arms/a8-2026-11-19/results.md` §2, §4; merge approved Q-306)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers two things: what the cited sections say, and the existence and answer of Q-306. It does not re-derive the A8 pass's nine per-agent usage figures; the probe agents and the Stage-2.5 record were checked, not all nine.

`results.md:65-66` says "**No agent read the shared block from another agent's cache.** Each agent's first call read exactly 18,900 cached tokens", and `results.md:123-124` (§4) says "No agent read the shared block from another agent's cache". Q-306 is at `docs/working/questions-archive.md:7552-7554`: "**Status:** ANSWERED / Q-306: [1] / Merge the A8 token measurement's results … into main?" The A8 Stage-2.5 record's first call also read 18,900 (`fc1/inspect3.log`: `'cache_read_input_tokens': 18900`).

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:59-85,121-143`, `docs/working/questions-archive.md:7552-7570`

---

## Claim 4: "a second agent 28.5 s later, same block byte for byte, still read only 18,900 tokens"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the read figure, byte identity and the 28.5 s interval, which runs from A's reply to B's first request (as `cache-probe.md:28` defines it). It does not establish an interval from A's start: A's first request to B's first request is 31.6 s.

From `fc1/inspect4.log`: "B-req minus A-reply 28.499" and "B-req minus A-req 31.554". From `fc1/inspect.log`, B's first `assistant` usage is `'cache_read_input_tokens': 18900`. From `fc1/inspect2.log`, both agents' `[3] startswith block True`.

**Evidence:** `fc1/inspect.log`, `fc1/inspect2.log`, `fc1/inspect4.log`

---

## Claim 5: "no prompt order puts a breakpoint at the block's end"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the request layout recorded for Claude Code 2.1.328's `general-purpose` Agent-tool path: the prompt arrives as one text block, and breakpoints sit only on `system[0]`, `system[1]` and the request's last block. It does not establish behaviour in other Claude Code versions, other agent types, or a delivery path other than one prompt string. Medium confidence, because breakpoint placement is inferred from three records rather than read from Claude Code's source.

All three first requests examined (probe A, probe B and the A8 Stage-2.5 agent) carry `'cacheControl': [{'path': ['system', 0] …}, {'path': ['system', 1] …}, {'path': ['messages', 1, 'content', 3] …}]` (`fc1/inspect.log`, `fc1/inspect3.log`: `A8 first req … [['system', 0], ['system', 1], ['messages', 1, 'content', 3]]`). The whole prompt is the single block `messages[0].content[3]` (8,932 chars in each probe, starting with the shared block, `fc1/inspect2.log`). No breakpoint sits inside or at the end of that block, and no text order can move one there.

**Evidence:** `fc1/inspect.log`, `fc1/inspect2.log`, `fc1/inspect3.log`

---

## Claim 6: Status word `Split`, "Net inline cost and recall effect moved to Q-308"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers four things: that `Split` is a valid 🟡 word, that the cell carries the tracked follow-up Q-ID, that Q-308 exists and is open, and that Q-308 is the unit for the two remaining unknowns. It does not establish that `Split` beats `Acknowledged`, which is a judgment; it is consistent with the defined meanings.

The table at `skills/code-review/references/rubric.md:204` defines `Split` as "🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch)". The cell starts with `Split` and names Q-308. Q-308 (`docs/working/questions.md:166-187`, "**Status:** OPEN") asks about "a self-read control pass on the csp cell and a pass on the larger corpus cell". Its option [3] reads "The inline cost and recall effect stay unknown", so Q-308 is the open unit for both. `Acknowledged` ("stands with a qualifying author note", `rubric.md:201`) would fit a claim left standing, which is not the case here. Q-304 (`questions-archive.md:7485`) is the owner's go-ahead for the measurement; the cell does not need it.

**Evidence:** `skills/code-review/references/rubric.md:190-211`, `docs/working/questions.md:166-187`, `docs/working/questions-archive.md:7485-7507`

---

## Claim 7: "In an A8 record (Stage 2.5's agent), the first request is: system (2 blocks, breakpoints on both); `messages[0]` user with 5 text blocks (instructions, git status, attribution, the prompt, the hand-off reminder); `messages[1]` a system-role message with the skill listing and three deferred tool definitions, breakpoint on its last block."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:19-22`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the block counts, roles, order and breakpoints of the record in `agent-a6a0ebd8bee725384.jsonl`'s first request. It does not establish that every A8 agent has the same layout (one record was read).

Confirmed: the shape holds `nsystem 2`. Breakpoints are on `system[0]`, `system[1]` and `messages[1].content[3]`. `messages[0]` is the user role with five text blocks, and block [3] carries "## Your role: code fact-check, Stage 2.5 submitted claims (k=1)" (`fc1/inspect2.log`, `fc1/inspect3.log`). `messages[1]` is `role system` with `['text', 'tool_addition', 'tool_addition', 'tool_addition']`.

The description of `messages[1]` is imprecise in two ways. First, block [0] (26,004 chars) is not only the skill listing. It opens with "The following tools just became available and are ready to use:" and the deferred-tool name list, contains an "# Environment" section at offset 984, and only reaches "The following skills are available for use with the Skill tool:" at offset 2687 (`fc1/inspect2.log`, plus a section-heading scan of block [0]). Second, the three `tool_addition` blocks are definitions of `mcp__claude_ai_Claude_Docs__batch/guide/update`, the tools announced as "ready to use", not the ToolSearch-deferred ones. Precise version: "a system-role message: one text block (tool-availability notices, environment, skill listing), then three added tool definitions". This does not change the breakpoint conclusion.

**Evidence:** `fc1/inspect2.log`, `fc1/inspect3.log`

---

## Claim 8: "Skill section under test: `skills/code-review/SKILL.md` "Inline shared-context prefix (decision 032 #3)", lines 268-358."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:23-24`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section span at HEAD. It does not establish the span at other revisions.

`SKILL.md:268` is `### Inline shared-context prefix (decision 032 #3)`, and the next heading is `SKILL.md:360` `### Between-stage status banner`. The section's last text line is :358, followed by a blank :359.

**Evidence:** `skills/code-review/SKILL.md:266-360`

---

## Claim 9: "Rubric row: `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `🟡 Open`"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:25-26`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row's line number and its status at base 8b060877. It does not establish the status after this branch, which is now `Split`.

At base, `fc1/rub-8b060877.md` line 35 is the A8 row, whose Status cell is "🟡 Open" (also the diff's removed line, rubric hunk line 43). The line number is unchanged at HEAD.

**Evidence:** `fc1/cells.log`, `docs/reviews/code-review-rubric-2026-08-07-main.md:35`

---

## Claim 10: "Q-306: the owner approved merging the A8 results. Q-308: the owner's open question on the two larger settling runs (self-read control, corpus cell)."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:27-28`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what each entry says and its status in the worktree and on main (both are identical at these headings). It does not establish anything about entries opened after main's current tip.

Q-306 reads "**Status:** ANSWERED / Q-306: [1] / Merge the A8 token measurement's results … into main?" (`questions-archive.md:7552-7556`). Q-308 reads "**Status:** OPEN / Run the two larger measurements …: a self-read control pass on the csp cell and a pass on the larger corpus cell?" (`questions.md:166-169`). `git show main:` finds both headings at the same line numbers.

**Evidence:** `docs/working/questions.md:166-187`, `docs/working/questions-archive.md:7552-7570`

---

## Claim 11: "FP-089 (count claims drift across citing documents) … FP-091 (a stale note inverts a premise)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:30-35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two IDs and their glosses. It does not establish that the doc's mitigations were applied; the copied-figure discipline is checked separately in Claims 13 and 18.

`docs/failure-patterns.md:231` reads "**FP-089** 2026-07-31 symptom:count-claims-drift-across-four-citing-documents", and `:233` reads "**FP-091** 2026-08-06 symptom:stale-pricing-note-inverts-cheap-arm-premise". The glosses are faithful generalizations.

**Evidence:** `docs/failure-patterns.md:231,233`

---

## Claim 12: "Both prompts start with the block byte for byte. All user content blocks except [3] (the prompt) hash the same; the system-role message hashes the same." (also commit 4363a15c: "carried the A8 Stage-1 shared block byte for byte")

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:46-47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first request of each probe agent. It does not establish identity of later requests, which were not inspected.

From `fc1/inspect2.log`: `[3] startswith block True` for both agents, checked against the API blob, not only the transcript's user record. From the scratchpad `probe-out.txt`, the per-block hashes are A `['42844d66', 'e9d8ab24', 'cb65f80a', '036e3261', '2ee8513e']` and B `['42844d66', 'e9d8ab24', 'cb65f80a', '6c809541', '2ee8513e']`, so only [3] differs. Both requests have the system blob `14236cb7f9a8 system ['af851756', '5e0b9708', 'fc45f571', 'ed602d38']`. The shared block's sha256 prefix `be4a2600985537d5` (`fc1/block.log`) equals the Stage-1 hash in `results.md:64` ("`be4a2600985537d5` ×3"), which confirms it is the Stage-1 block.

**Evidence:** `fc1/inspect2.log`, `fc1/block.log`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/probe-out.txt`, `runs/review-arms/a8-2026-11-19/results.md:63-64`

---

## Claim 13: "A: read 18,900, created 31,731. B, 28.5 s after A's reply: read 18,900, created 31,731."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:48`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first-call usage of both agents and the interval. It does not establish usage of any other call (each agent made one API call).

From `fc1/inspect.log`, both first `assistant` records show `'cache_creation_input_tokens': 31731, 'cache_read_input_tokens': 18900`. The interval is 28.499 s (`fc1/inspect4.log`).

**Evidence:** `fc1/inspect.log`, `fc1/inspect4.log`

---

## Claim 14: "Breakpoints are fixed by Claude Code at `system[0]`, `system[1]` and the request's last block. The prompt is a single content block … So no ordering inside the prompt puts a block boundary, let alone a breakpoint, at the shared block's end." (also `cache-probe.md:68-73`: "The Agent tool takes the prompt as one string and sends it as one content block. The breakpoints are placed by Claude Code … The orchestrator controls neither.")

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:50-54`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Same as Claim 5: three first-request records on Claude Code 2.1.328 (`'version': '2.1.328'`). It does not establish that placement is fixed in Claude Code's source, or that it holds across versions. The "cache matching is by whole block" half rests on the web source and is verdicted in Claim 21.

In all three records, `'tail'` has two blobs (one user message and one system-role message), so `messages[1].content[3]` is the last block of the request. The prompt is one text block (`fc1/inspect.log`, `fc1/inspect2.log`, `fc1/inspect3.log`).

**Evidence:** `fc1/inspect.log`, `fc1/inspect2.log`, `fc1/inspect3.log`

---

## Claim 15: "Minor correction to `results.md` §2: breakpoint 3 is on the system-role message after the user turn, not on the user turn's end; still after the tail."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:55-57`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what §2 says and the role of `messages[1]` in the probe and Stage-2.5 records. It does not establish whether `results.md` was or should be edited (it was not; that is outside the brief).

`results.md:73-76` reads: "Every agent's first request carries three breakpoints: `system[0]`, `system[1]` and `messages[1].content[3]`, the end of the first user turn, after the per-agent tail." In the records, `messages[1]` has role `system`, while `messages[0]` is the user turn (`fc1/inspect2.log`: `blob role system ['text', 'tool_addition', 'tool_addition', 'tool_addition']`). The correction is right.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:73-76`, `fc1/inspect2.log`

---

## Claim 16: "The skill still says the cache "serve[s] the shared block to all ~8 agents" and "Leave it on because it is free" (`SKILL.md:274-277`, `:352-354`)" (same citation at `cache-probe.md:85-86`)

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:74-75`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotes and line spans at HEAD. It does not establish the original rubric row's `SKILL.md:276-278`, which this branch did not change; that range matches the text at 2f5ad0b (`:276-277`), not at HEAD.

`SKILL.md:274` reads "**after** it. This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a", continuing to :277 "is unchanged, so it has **zero effect on recall**". `SKILL.md:352-354` reads "**Measured benefit is modest — … 0% of token count** … Leave it on because it is free; do not expect / it to move the token-count ledger." In 2f5ad0b, the same "Leave it on" text sits at :276-277, so A8's original locator was right when written.

**Evidence:** `skills/code-review/SKILL.md:268-358`

---

## Claim 17: "Shared block: `csp/shared-block.md` (8,755 bytes, the A8 pass's Stage-1 block), pasted verbatim as the start of each prompt."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:11-12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte count, the Stage-1 identity (by hash) and the prefix match. It does not establish Stage-2 identity, which uses a different block.

`fc1/block.log` shows `8755 runs/review-arms/a8-2026-11-19/csp/shared-block.md`, with sha256 prefix `be4a2600985537d5`, matching `results.md:64` and `manifest.json:43` ("`be4a2600985537d5 (3/3 prompts)`"). The prefix match is as in Claim 12.

**Evidence:** `fc1/block.log`, `runs/review-arms/a8-2026-11-19/manifest.json:43`

---

## Claim 18: "Dispatch: two `general-purpose` Agent-tool subagents from the same orchestrator session, same model (claude-opus-5-5), B dispatched after A had finished."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:16-17`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers agent type, session, model and ordering as recorded. It does not establish the orchestrator-side tool-call timestamps, which were not read; ordering is shown by A's completion and B's first record.

Both `api-request` records show `'sessionId': '711f86df-…'`, `'querySource': 'agent:builtin:general-purpose'` and `'model': 'claude-opus-5-5'` (`fc1/inspect.log`). A's tool result came at 19:39:16.656Z (its hand-off) and the parent queue event at 19:39:16.667Z. B's first user record is at 19:39:44.466Z (`fc1/inspect2.log`, `fc1/inspect4.log`).

**Evidence:** `fc1/inspect.log`, `fc1/inspect2.log`, `fc1/inspect4.log`

---

## Claim 19: Result table, every figure: first requests 19:39:13.000Z / 19:39:44.554Z, "28.5 s after A's reply at 19:39:16.055Z"; breakpoints; cache read 18,900 / 18,900; creation 31,731 / 31,731; input/output 2 / 52; notified `subagent_tokens` 50,685 / 50,685

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:26-34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell of the table (unit read in full, :26-34). It does not establish that "A's reply" means anything other than A's first `assistant` record timestamp, which is how it is read here.

From `fc1/inspect.log`: A `'timestamp': '2026-11-19T19:39:13.000Z'`, assistant `2026-11-19T19:39:16.055Z`; B `'timestamp': '2026-11-19T19:39:44.554Z'`; both `{'input_tokens': 2, 'cache_creation_input_tokens': 31731, 'cache_read_input_tokens': 18900, 'output_tokens': 52}`. The parent session's notifications for both agents carry `<subagent_tokens>50685</subagent_tokens>` (`fc1/inspect3.log`). The sum 2+18,900+31,731+52 = 50,685 and the delta 28.499 s are in `fc1/inspect4.log`.

**Evidence:** `fc1/inspect.log`, `fc1/inspect3.log`, `fc1/inspect4.log`

---

## Claim 20: "B started 28.5 s after A, well inside the 5-minute lifetime (`promptCacheRequested: 5m`)."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:36`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the presence of the 5m setting and the interval. It does not establish the server-side TTL beyond what the record states. "After A" here means after A's reply, per :28.

Both probe `assistant` records carry `"promptCacheRequested": "5m"` (`fc1/inspect2.log`), and usage reports `'ephemeral_5m_input_tokens': 31731` (`fc1/inspect.log`).

**Evidence:** `fc1/inspect.log`, `fc1/inspect2.log`

---

## Claim 21: "Prompt caching matches on whole content blocks. On each breakpoint the API checks earlier content-block boundaries (up to about 20 blocks back) for an entry an earlier request wrote there."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:57-61`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the doc flags the rule as unverified (it does) and whether the records contradict it (they do not). It does not establish the API rule itself, which needs the Anthropic prompt-caching page and is blocked by no egress.

The doc itself says, at :59-61: "seen through a web-search summary only; this sandbox cannot fetch it, so treat the wording as unverified". The research doc flags it the same way (:51-52). The observations are consistent with the rule: neither agent read beyond `system[1]`, and A wrote no entry at any boundary inside `messages[0]`. Verifying the rule needs a fetch of the cited page from a host with egress.

**Evidence:** `runs/review-arms/a8-2026-11-19/cache-probe.md:57-64`, `docs/working/research-2026-11-19-a8-cache-probe.md:50-52`

---

## Claim 22: "`messages[0]` (user), five text blocks: [0] the instruction files, [1] git status, [2] commit attribution, [3] the whole prompt (shared block + tail), [4] the hand-off reminder. Blocks 0-2 and 4 hash the same in A and B; only block 3 differs. `messages[1]` (a system-role message), four blocks: the skill listing, then three deferred tool definitions. Breakpoint 3 is on its last block, `messages[1].content[3]`: the end of the request."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:46-51`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the probe agents' first-request layout. It does not establish layout for later calls.

The `messages[0]` half is exact. Blocks [0]-[4] start with "<system-reminder>\nCodebase and user instructions…", "…following context:\n# gitStatus" (block [1]), "Attribution for git commits…", "# Review pass: shared context…" and "Your final report is delivered through SubagentHandback…". The hashes differ only at [3] (`fc1/inspect2.log`, `probe-out.txt`). The breakpoint and end-of-request part is exact (the `tail` has two blobs).

The `messages[1]` description has the same imprecision as Claim 7. Block [0] holds tool-availability notices, the deferred-tool name list and an "# Environment" section before the skill listing (offset 2687). The three `tool_addition` blocks are the "ready to use" Claude_Docs tools, not the deferred ones. Tighten to "a text block (tool notices, environment, skill listing), then three added tool definitions".

**Evidence:** `fc1/inspect2.log`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/probe-out.txt`

---

## Claim 23: "`system[0]`, `system[1]` … tools and system are what the 18,900 cached tokens are" and "the longest entry B can match is `system[1]`: 18,900 tokens"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:44-45,62-64`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers consistency of the 18,900 figure with a cache entry ending at `system[1]`. Agents with entirely different prompts (the probes and the A8 Stage-2.5 agent) all read exactly 18,900, and that breakpoint is the only one before the messages. It does not establish an independent token count of tools plus system (no tokenizer was run), so the equality is inferred, not measured. Medium confidence for that reason.

The A8 Stage-2.5 first call read `'cache_read_input_tokens': 18900` with a different `messages[0]` blob (`8c4206ac…`, `fc1/inspect3.log`). Both probes read 18,900 (`fc1/inspect.log`). The request shape holds `['system', 'tools']` with 11 tools and 2 system blocks (`fc1/inspect2.log`).

**Evidence:** `fc1/inspect.log`, `fc1/inspect2.log`, `fc1/inspect3.log`, `runs/review-arms/a8-2026-11-19/results.md:65-67`

---

## Claim 24: "Only a byte-identical whole prompt would match … Matching would serve more than the block: B's whole prefix up to block 3 (instruction files included), roughly the 31.7k tokens each agent now writes fresh."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:75-79`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers whether the 31.7k figure matches the span named. It does not establish the hypothetical mechanism, which is untested and explicitly "not proposed". The same idea at `research-…:123-125` ("hit the whole ~31.7k prefix") names no span and is fine.

The 31,731 created tokens (`fc1/inspect.log`) are everything after the `system[1]` entry, through the last breakpoint at `messages[1].content[3]`. That is all of `messages[0]` (blocks [0]-[4]) plus the system-role `messages[1]` (a 26,004-char text block and three tool definitions, `fc1/inspect2.log`). "Up to block 3" names a shorter span. Blocks [0]-[3] are about 58k chars, roughly half the 31.7k at 4 chars/token. That count is paraphrased (no quote available, because it is a chars/4 estimate from the block lengths in `fc1/inspect2.log`, not a tokenizer count). So the figure is right for the whole request after the system prompt but not for "up to block 3". Tighten to "B's whole request after the system prompt (instruction files, block 4 and the system-role message included), the 31.7k tokens each agent now writes fresh".

**Evidence:** `fc1/inspect.log`, `fc1/inspect2.log`

---

## Claim 25: "What remains is each agent's own reuse within its run, which happens with or without inlining (`results.md` §2). The probe did not test reuse across loop passes."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:87-89`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and the probe's design. It does not establish the cross-pass inference that follows (a later pass hits only on a byte-identical whole prompt), which is reasoning from Claims 5 and 21, not a measurement.

`results.md:67-69` reads "(Within a run, an agent's later calls usually re-read its own prefix from cache, block included, which happens with or without inlining." The probe ran two agents in one pass, each with one API call (`fc1/inspect.log`: one `api-request` per agent), so no cross-pass reuse was exercised.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:65-72`, `fc1/inspect.log`

---

## Claim 26: "Cost of the probe: 2 × 50,685 = 101,370 tokens by the notified figure. Nearly all of that is the harness context every agent starts with, not the tail." (commit 4363a15c: "dispatched 28.5 s apart")

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:93-94`; commit 4363a15c message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic, the harness-dominance statement and the commit's timing wording. It does not establish the token size of the tail alone, which was not tokenized.

The cost part checks out: `fc1/inspect4.log` gives `sum 50685 101370`. The whole prompt block is 8,932 chars, a small share of the 50,685 (paraphrased — no quote available, because this is a chars-to-tokens comparison from `fc1/inspect2.log` lengths, not a tokenizer count), so "nearly all … harness context" holds. This claim is pooled with the commit message's wording, and that wording is what carries the verdict. The 4363a15c message says the agents were "dispatched 28.5 s apart". The 28.5 s runs from A's reply to B's first request. Dispatch to dispatch (first user records 19:39:12.927Z → 19:39:44.466Z) and request to request (31.554 s, `fc1/inspect4.log`) are both about 31.5 s. Precise version: "B dispatched 28.5 s after A replied".

**Evidence:** `fc1/inspect2.log`, `fc1/inspect4.log`

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`docs/working/research-2026-11-19-a8-cache-probe.md:21-22`): `messages[1]` is one text block (tool notices, environment and skill listing) plus three added tool definitions, which are the "ready to use" Claude_Docs tools, not deferred ones. **Legibility-target:** for-author
- **Claim 22** (`runs/review-arms/a8-2026-11-19/cache-probe.md:49-50`): same wording issue as Claim 7 ("the skill listing, then three deferred tool definitions"). **Legibility-target:** for-author
- **Claim 24** (`runs/review-arms/a8-2026-11-19/cache-probe.md:77-78`): 31.7k is the whole request after `system[1]` (block 4 and the system-role message included), not "up to block 3". **Legibility-target:** for-author
- **Claim 26** (commit 4363a15c message): "dispatched 28.5 s apart" should read "B dispatched 28.5 s after A replied"; dispatch to dispatch was about 31.5 s. The probe doc's own arithmetic is right. **Legibility-target:** for-author

### Unverifiable
- **Claim 21** (`runs/review-arms/a8-2026-11-19/cache-probe.md:57-61`): the API's whole-block matching and ~20-block lookback rule needs a fetch of the Anthropic prompt-caching page from a host with egress. The doc already flags it as unverified, and the records are consistent with it. **Legibility-target:** for-orchestrator-synthesis

### Legibility-target, all claims
- for-author: Claims 7, 22, 24, 26.
- for-orchestrator-synthesis: Claims 1, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 23, 25.

---

## Goal-Alignment Note

- **Success criterion (verbatim):** "a code-fact-check report saved at the output path below, in the code-fact-check skill's report schema."
- **Answered:** All 12 items in the fact-check brief were checked against the probe and A8 transcripts, `probe-out.txt`, `results.md`, `SKILL.md`, `rubric.md` and the questions files. Every figure, timestamp, hash, breakpoint path and line reference in the diff matches its source, and the rubric status line and cell counts hold. There are no Incorrect or Stale claims. The four Mostly-accurate claims are wording precision issues; none changes the conclusion that cross-agent cache reads are structurally zero on this path.
- **Out of scope:** Whether the closing reasoning is a good design argument (critics' domain). Behaviour on other Claude Code versions or agent types. The A8 pass's other eight agents' usage, which was not re-derived. The rubric parser in `scripts/build-loop.sh`, which was not run.
- **Escalate:** None blocking. One note for the orchestrator: the brief's acceptance item "change this brief's status line from open to done" is still pending (`docs/working/briefs/2026-11-19-a8-cache-probe.md:3` reads `Status: open`). The research doc's Plan step 3 lists it as still to do, so it is not a claim error, but it must land before merge.
- **Questions / Decisions:**
  - The status line adds a parenthetical after the verbatim single-sample label. The template neither allows nor forbids this (`rubric.md:609,619-624`); treated as acceptable.
  - Q-308's interim is "[2] After the cache fix". The probe now says no prompt-order fix exists, so Q-308's framing may need a refresh by the cycle. That is outside this diff, and the questions files are excluded by the brief.
