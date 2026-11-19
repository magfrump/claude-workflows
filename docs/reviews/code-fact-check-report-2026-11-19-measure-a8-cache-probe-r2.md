Commit: f87a1455

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-cache-probe (branch measure/a8-cache-probe)
**Scope:** `git diff 8b06087719a4fd260cf692be9f5d485aee8535f1..HEAD` (commits 4363a15c, f87a1455): `docs/reviews/code-review-rubric-2026-08-07-main.md`, `docs/working/research-2026-11-19-a8-cache-probe.md`, `runs/review-arms/a8-2026-11-19/cache-probe.md`, plus both commit messages
**Checked:** 2026-11-19
**Total claims checked:** 33
**Summary:** 26 verified, 5 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 8 entries) read first; no claim matches a logged pattern.

Execution provenance (shared by every `executed` claim below). All commands ran in cwd `/workspace/.claude/wt-2026-11-19-a8-cache-probe`, exit 0, between 2026-11-19T19:45:51Z and 19:48:36Z, stdlib `python3 -I` only. Scripts and captured output live in `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/fc2/` (abbreviated `FC2/` below):
- E1: `timeout 60 python3 -I FC2/inspect2.py a047a7e5a841ceab4 ad0565873cbe05c85` → `FC2/inspect2-out.txt` (per-record dump of both probe transcripts: blobs with role, per-block length and sha256, cacheControl, usage, model).
- E2: `timeout 60 python3 -I FC2/inspect3.py` → `FC2/inspect3-out.txt` (promptCacheRequested, shape system/tools counts, byte-level `startswith` against `csp/shared-block.md`, content of `messages[1]`).
- E3: `timeout 60 python3 -I FC2/inspect2.py a6a0ebd8bee725384` → `FC2/inspect-a8.txt`, and `timeout 60 python3 -I FC2/inspect4.py` (A8 Stage 2.5 record layout, later-request breakpoints, section headers in `messages[1].content[0]`; output inline in session, summarized in claims 7 and 24).
- E4: `python3 -I -c` arithmetic plus `wc -c runs/review-arms/a8-2026-11-19/csp/shared-block.md` → `FC2/arith-out.txt`.
- E5: `git show <rev>:docs/reviews/code-review-rubric-2026-08-07-main.md | python3 -I FC2/cells.py` for 8b060877 and HEAD → `FC2/cells-out.txt` (cells per table row, backtick spans masked).
- E6: `rg` over the orchestrator session transcript `/home/node/.claude/projects/-workspace/711f86df-792b-492f-9d5e-95022839ec2c.jsonl` for the task notifications of both probe agents (output inline in session; quoted in claim 22).

No process was left running.

---

## Claim 1: "**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation (A8 split to Q-308 on 2026-11-19 after its measurement and cache probe; all other reds/ambers fixed in iterations 1–3)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the line's prefix matches the rubric.md all-resolved template verbatim, that the single-sample label appears once, and that every 🔴/🟡 row (R1, A1-A12) other than A8 carries `Fixed` with an iteration in 1-3; does not establish whether an appended parenthetical is permitted by the template (rubric.md neither allows nor forbids it, and the prior line also carried one), nor anything about the 🟢 rows.

The template line is `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation` (`skills/code-review/references/rubric.md:609`), and the new line begins with exactly that text. The label rule says it appears "appended to the `✅ PASSES REVIEW` status line above" and "never more than once in each" (`rubric.md:623-624`); it appears once. Red/amber status cells: R1 `✅ Fixed (iter 1 …` (`:17`); A1, A2, A4, A5, A9-A12 `✅ Fixed (iter 1 …`; A3 and A7 `✅ Fixed (iter 2 …`; A6 `✅ Fixed (iter 3 …` (`:28-39`); A8 `Split — …` (`:35`). The only `iter 4` cells are 🟢 rows C2, C3, C6 (`:51`, `:52`, `:55`), which the line does not cover.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4,17,28-39,51-55`, `skills/code-review/references/rubric.md:605-628`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: A8 Status cell: "Split — measured 2026-11-19: the claim fails on its benefit. No agent read the shared block from another's cache in the A8 pass (`results.md` §2, §4; merge approved Q-306), and the two-agent probe … shows it is structural: a second agent 28.5 s later, same block byte for byte, still read only 18,900 tokens, and no prompt order puts a breakpoint at the block's end. Net inline cost and recall effect moved to Q-308"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the status word's legality (first word `Split`, 🟡 tier, carries a Q-ID), the citations to results.md §2/§4, Q-306's answer and Q-308's coverage; the probe figures are verified separately in claims 20-21 and the no-order reasoning in claim 27; does not establish that `Split` is preferable to `Acknowledged` as a judgment (both are legal for 🟡), nor that Q-308 will be answered.

rubric.md: "A Status cell in a new rubric starts with one of these words … so a parser reads the first word" and `| \`Split\` | 🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch) |` (`skills/code-review/references/rubric.md:192-193,204`). The cell starts `Split` and names Q-308. results.md §2: "**No agent read the shared block from another agent's cache.**" (`runs/review-arms/a8-2026-11-19/results.md:65`); §4: "**The benefit the claim counts on did not appear.** No agent read the shared block from another agent's cache" (`:123-124`); "**Verdict: the "leave it on because it is free" claim fails on its benefit:**" (`:134-135`). Q-306 is answered `Q-306: [1]` with option `**[1] merge**` (`docs/working/questions-archive.md:7552-7554`, option table at the end of that entry). Q-308 asks for "a self-read control pass on the csp cell and a pass on the larger corpus cell" with option [3] "The inline cost and recall effect stay unknown" (`docs/working/questions.md:166-181`), so it covers "net inline cost and recall effect". "28.5 s later" means after A's reply (claim 20); see claim 32 for the commit message's looser wording.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `skills/code-review/references/rubric.md:190-206`, `runs/review-arms/a8-2026-11-19/results.md:59-83,121-143`, `docs/working/questions-archive.md:7552-7634`, `docs/working/questions.md:166-184`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3: A8 row's unchanged Finding text "\"Leave it on because it is free\" / \"0% of token count\" (`SKILL.md:276-278`)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation at the reviewed commit 2f5ad0b (the rubric's own `Commit:`); does not establish the line numbers at HEAD, where the same text sits at `:352-354` (the new probe and research docs cite that position correctly, claim 16).

At 2f5ad0b, `git show 2f5ad0b:skills/code-review/SKILL.md` lines 276-278 read: "- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a / billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect / it to move the token-count ledger." This text was not changed by the diff; it is cited here only because the brief asked.

**Evidence:** `skills/code-review/SKILL.md:276-278` (at 2f5ad0b), `skills/code-review/SKILL.md:352-354` (HEAD)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 4: Commit f87a1455: "each had 8 cells under a 9-column header. An empty Author note cell is what their text implies." / "format-only; no status changed."

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:30,33,34`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers cell counts of every row of the 🔴 table and the 🟡 table at 8b060877 and HEAD, and that A3/A6/A7 differ only by an appended `| — |`; does not establish how the merge-check parser treats `—` versus a truly empty cell (it is the convention every other 🟡 row uses).

E5 output (`FC2/cells-out.txt`): at 8b060877 the 🟡 header (`:26`) has 9 cells and rows A3 (`:30`), A6 (`:33`), A7 (`:34`) have 8; all other 🟡 rows have 9. At HEAD every 🟡 row has 9. The 🔴 table has 8 header cells and R1 has 8 at both revisions. The diff hunk changes those three lines only by appending ` | — |` (shared-block diff, `-| A3 … contract tests 7–9) |` → `+| A3 … contract tests 7–9) | — |`), so no Status cell text changed.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:15-39`, `FC2/cells-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: "Brief: `docs/working/briefs/2026-11-19-a8-cache-probe.md` (at 8b060877)." / "The A8 measurement (`results.md` §2) found that no review agent read the inlined shared block from another agent's cache, and inferred from the request records that breakpoints sit after the per-agent tail. Stages 1 and 2 could not separate that from timing (agents launched within milliseconds)."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:58,63-66`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the brief's existence at 8b060877 and the paraphrase of results.md §2; does not establish the §2 inference itself (the probe tests that, claims 20-27).

`git show 8b060877:docs/working/briefs/2026-11-19-a8-cache-probe.md` exists ("# Brief: A8 follow-ups: the prompt-cache probe, and closing rubric row A8"). results.md §2: "**No agent read the shared block from another agent's cache.**" (`:65`); "the end of the first user turn, after the per-agent tail. No cache entry ever ends at the shared block's last byte" (`:75-76`); "Within Stages 1 and 2 the agents' first requests went out within milliseconds of each other, so those stages cannot separate timing from breakpoints." (`:76-78`).

**Evidence:** `docs/working/briefs/2026-11-19-a8-cache-probe.md` (at 8b060877), `runs/review-arms/a8-2026-11-19/results.md:59-83`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: "Request records live in each subagent's transcript … `api-request-shape` (system), `api-request-blob` (per-message content blocks), `api-request` (`cacheControl` paths, `tail` blob hashes, timestamp)."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:70-73`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record types and fields present in the two probe transcripts and the A8 Stage 2.5 transcript; does not establish that every Claude Code version writes these records (both runs are version 2.1.328). Minor: `api-request-shape` holds `tools` as well as `system`.

E1/E2: each probe transcript has `'api-request-blob': 2, 'api-request-shape': 1, 'api-request': 1, 'assistant': 1`; the shape record's keys are `['system', 'tools']`; the api-request record carries `"tail": ["5790a1d8…", "14236cb7…"]`, `"cacheControl": [{"path": ["system", 0], …}, …]` and `"timestamp"`.

**Evidence:** `FC2/inspect2-out.txt`, `FC2/inspect3-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: "In an A8 record (Stage 2.5's agent), the first request is: system (2 blocks, breakpoints on both); `messages[0]` user with 5 text blocks (instructions, git status, attribution, the prompt, the hand-off reminder); `messages[1]` a system-role message with the skill listing and three deferred tool definitions, breakpoint on its last block."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:74-77`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the position, role, count and order of every block in agent a6a0ebd8bee725384's first request and its breakpoints; the imprecision is in the labels of `messages[1]`'s contents only, which do not affect the breakpoint conclusion.

E3: the record is Stage 2.5's (its prompt names `csp/code-fact-check-submitted-claims.md` as output). First request: `cacheControl` `[['system', 0], ['system', 1], ['messages', 1, 'content', 3]]`; blob `role= user n= 5` with blocks starting `<system-reminder>\nCodebase and user instructions…`, `…following context:\n#`, `…Attribution for git commits…`, `# Review pass: shared context…`, `…Your final report is delivered through SubagentHandback…`; then blob `role= system n= 4`: `[0] text len 26004 … 'The following tools just became available and are ready to use:\nmcp__claude_ai_Claude_Docs'`, `[1]-[3] tool_addition`. Two labels are imprecise. Block [0] holds more than the skill listing: its headers are "The following tools just became available and are ready to use:", "The following deferred tools are now available via ToolSearch…", "# Environment", "The following skills are available for use with the Skill tool:". The three `tool_addition` blocks are the definitions of `mcp__claude_ai_Claude_Docs__batch`, `__guide`, `__update`, which block [0] lists as "just became available and are ready to use". Block [0] contrasts those with the deferred tools, whose "schemas are NOT loaded". So they are not deferred tools. Precise version: "the tool and skill listings, then three mid-conversation tool definitions (the Claude Docs tools)".

**Evidence:** `FC2/inspect-a8.txt` (lines 5-16), `FC2/inspect3-out.txt`
**Legibility-target:** for-author

---

## Claim 8: "Skill section under test: `skills/code-review/SKILL.md` \"Inline shared-context prefix (decision 032 #3)\", lines 268-358."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:78-79`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the section span at HEAD (SKILL.md is unchanged on the branch: `git diff --stat 8b060877 HEAD -- skills/` is empty); does not establish anything about the section's content.

`skills/code-review/SKILL.md:268` is `### Inline shared-context prefix (decision 032 #3)`; the next heading is `:360` `### Between-stage status banner`; `:358` is the section's last content line ("there (decision 032 H4) — see the guard note in that file's module docstring."), and `:359` is blank.

**Evidence:** `skills/code-review/SKILL.md:268-360`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: "Rubric row: `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `🟡 Open`; status words in `skills/code-review/references/rubric.md` \"Status words\"."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:80-81`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row position and status at base 8b060877 (the state the research describes) and the section name; does not establish the row's state at HEAD (now `Split`, claim 2).

At 8b060877, line 35 of the rubric is the A8 row ending `| for-author | — | 🟡 Open | User decision 2026-08-07: …` (shared-block diff, the `-| A8 |` line). `skills/code-review/references/rubric.md:190` is `### Status words`.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35` (at 8b060877), `skills/code-review/references/rubric.md:190`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: "Q-306: the owner approved merging the A8 results. Q-308: the owner's open question on the two larger settling runs (self-read control, corpus cell)."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:82-83`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both entries' text at HEAD (identical on main); does not establish anything about Q-304, which the brief cites as the go-ahead for the measurement itself and which the diff does not mention.

`### Q-306 · merge-2026-11-19-a8-token-measurement-30bb30d43a60` / `**Status:** ANSWERED` / `Q-306: [1]`, with `**[1] merge**` meaning "The gate merges tip 30bb30d4" (`docs/working/questions-archive.md:7552-7554`). `### Q-308 · a8-settling-runs` / `**Status:** OPEN` / "a self-read control pass on the csp cell and a pass on the larger corpus cell?" (`docs/working/questions.md:166-169`).

**Evidence:** `docs/working/questions-archive.md:7552-7634`, `docs/working/questions.md:166-184`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: "FP-089 …: the probe doc and the rubric cell cite the same figures (18,900; 31,731; 28.5 s); keep them copied from the probe output"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:85-87`
**Type:** Reference / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers FP-089/FP-091's existence and which figures each doc carries; the figures' values themselves are verified in claim 20.

FP-089 and FP-091 exist (`docs/failure-patterns.md:231,233`). The probe doc carries all three figures (`runs/review-arms/a8-2026-11-19/cache-probe.md:172-176`). The rubric cell carries "28.5 s later" and "18,900 tokens" but not 31,731 (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`, full cell read). Precise version: "the rubric cell cites two of them (18,900; 28.5 s)". The values that are shared do match.

**Evidence:** `docs/failure-patterns.md:231-233`, `runs/review-arms/a8-2026-11-19/cache-probe.md:170-178`, `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Legibility-target:** for-author

---

## Claim 12: "Both prompts start with the block byte for byte. All user content blocks except [3] (the prompt) hash the same; the system-role message hashes the same."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:101-102`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers byte-level prefix equality of each agent's prompt with `csp/shared-block.md` and per-block sha256 equality across A and B; does not establish equality of the `system`/`tools` shape beyond its shared `shapeHash` (`fc254839…` in both).

E2: `bytes startswith: True` for both agents (the user prompt `.encode()` against the file's raw bytes), and `block[3] == user str? True`. E1 hashes: A `[0] 42844d66 [1] e9d8ab24 [2] cb65f80a [3] 036e3261 [4] 2ee8513e`; B identical except `[3] 6c809541`. `messages[1]` blob hash `14236cb7f9a8` in both, with identical block hashes `af851756 5e0b9708 fc45f571 ed602d38`.

**Evidence:** `FC2/inspect2-out.txt`, `FC2/inspect3-out.txt`, `runs/review-arms/a8-2026-11-19/csp/shared-block.md`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: "A: read 18,900, created 31,731. B, 28.5 s after A's reply: read 18,900, created 31,731. Timing was not the cause; the zero cross-agent reads are structural."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:103-104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two usage records and the interval; "structural" holds for this Claude Code version and Agent-tool path, one sequential pair; does not establish behavior with a 1h cache TTL or other harness versions.

E1: A `ASST 2026-11-19T19:39:16.055Z … "cache_creation_input_tokens": 31731, "cache_read_input_tokens": 18900`; B `ASST 2026-11-19T19:39:48.458Z … 31731 … 18900`; B's first request `2026-11-19T19:39:44.554Z`. E4: 19:39:44.554 − 19:39:16.055 = 28.499 s.

**Evidence:** `FC2/inspect2-out.txt`, `FC2/arith-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14a: "Breakpoints are fixed by Claude Code at `system[0]`, `system[1]` and the request's last block. The prompt is a single content block … So no ordering inside the prompt puts a block boundary, let alone a breakpoint, at the shared block's end."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:105-109`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the breakpoint paths in both probe requests and in the A8 Stage 2.5 agent's first four requests, and that the whole Agent-tool prompt lands in one text block; does not establish breakpoint placement in other Claude Code versions or entrypoints, nor whether the orchestrator could move the shared text into a different block by other means (e.g. instruction files), which the doc correctly treats as not a prompt order.

E1: both probe requests carry `"cacheControl": [{"path": ["system", 0]…}, {"path": ["system", 1]…}, {"path": ["messages", 1, "content", 3]…}]`, and `messages[1]` has 4 blocks (index 3 is its last; `tail` lists exactly two blobs, so it is the request's last block). The A8 agent's later requests move the third breakpoint to each new last message: `['messages', 4, 'content', 0]`, `['messages', 6, 'content', 0]`, `['messages', 8, 'content', 0]` (E3). The prompt: user string of 8931 chars, equal to `messages[0].content[3]` (`block[3] == user str? True`, E2), containing both block and tail (`tail '\n---\nCache probe agent A. …'` in `probe-out.txt`).

**Evidence:** `FC2/inspect2-out.txt`, `FC2/inspect3-out.txt`, `FC2/inspect-a8.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14b: "cache matching is by whole block (Anthropic prompt-caching docs via a search summary, unverified here)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:106-108`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the claim is correctly flagged as unverified and that the records agree with it (B read only the `system[1]` entry despite sharing 8,755 leading bytes of block [3]); does not establish the API rule itself.

No network in this sandbox (WebFetch fails), so the external page cannot be read. The records are consistent with the rule: both agents read exactly 18,900 (claim 13) despite identical leading bytes. The doc labels the source "unverified here", as the brief's criterion 2 requires ("a web source flagged unverified"). To verify it, someone would need to read platform.claude.com/docs/en/build-with-claude/prompt-caching from a host with egress.

**Evidence:** `FC2/inspect2-out.txt`, `docs/working/briefs/2026-11-19-a8-cache-probe.md` (at 8b060877, criterion 2)
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: "Minor correction to `results.md` §2: breakpoint 3 is on the system-role message after the user turn, not on the user turn's end; still after the tail. Recorded in the probe doc, not edited into the merged results (outside the brief's doc list)."

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:110-112`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what §2 says, the role recorded for `messages[1]`, that results.md is untouched on the branch, and the brief's doc list; does not establish how the API treats a system-role entry in `messages` beyond what the records show.

results.md §2: "`system[0]`, `system[1]` and `messages[1].content[3]`, the end of the first user turn, after the per-agent tail" (`runs/review-arms/a8-2026-11-19/results.md:74-75`). E1/E3: the blob holding `messages[1]` is `role= system n= 4`, in the probe and A8 records alike, so §2's "end of the first user turn" is wrong and the correction is right. `git diff 8b060877 HEAD -- runs/review-arms/a8-2026-11-19/results.md` is empty. Brief criterion 4 lists "the probe doc, the rubric row, any skill change, and your research doc" (at 8b060877).

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:73-83`, `FC2/inspect2-out.txt`, `FC2/inspect-a8.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "The skill still says the cache \"serve[s] the shared block to all ~8 agents\" and \"Leave it on because it is free\" (`SKILL.md:274-277`, `:352-354`)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:129-131`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quoted text and line positions at HEAD; does not establish whether the brief, rather than the cycle, should own the correction (a scope question, not a fact).

`skills/code-review/SKILL.md:274-277`: "This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a / pass — and again on the next loop pass while it is unchanged — at the cache-read rate instead of / re-billing full input per agent. It is a pure transport optimization: the content each agent sees / is unchanged, so it has **zero effect on recall** (decision 032 H1)." (excerpt ends :277; enclosing section continues to :358 — read). `:352-354`: "- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** (caching is a / billing-rate effect, not a token-count reduction). Leave it on because it is free; do not expect / it to move the token-count ledger."

**Evidence:** `skills/code-review/SKILL.md:268-358`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "Question from `results.md` §4 (\"Three things would tell\", first item): when two review agents carry the same inlined shared block and the second starts inside the cache lifetime, does the second read the block from the prompt cache?"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:3-7` (diff lines 147-151)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation; does not establish the probe's result (claims 20-27).

results.md §4: "Three things would tell. First, a two-agent cache probe: same shared block, dispatched one after the other within 5 minutes, comparing first-call `cache_read_input_tokens`. If the read stays at 18.9k, that confirms the breakpoint reading of §2 … If it rises by about the block size, timing was the cause after all." (`runs/review-arms/a8-2026-11-19/results.md:138-141`).

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:121-143`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "Shared block: `csp/shared-block.md` (8,755 bytes, the A8 pass's Stage-1 block), pasted verbatim as the start of each prompt."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:11-12`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file size and the verbatim prefix; "Stage-1 block" rests on results.md's own statement, not on a re-hash against the Stage-1 transcripts.

E4: `8755 runs/review-arms/a8-2026-11-19/csp/shared-block.md`. results.md: "The inlined shared block is 8,755 bytes … in the Stage-1 prompts" (`results.md:46-47`). Prefix equality: claim 12.

**Evidence:** `FC2/arith-out.txt`, `runs/review-arms/a8-2026-11-19/results.md:46-48`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "Tail: … differing only in the agent's letter (\"Cache probe agent A.\" / \"Cache probe agent B.\" …). Dispatch: two `general-purpose` Agent-tool subagents from the same orchestrator session, same model (claude-opus-5-5), B dispatched after A had finished."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:13-19`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the tails, agent type, session, model and ordering from the transcripts; does not establish that the tails differ in exactly one character beyond what the visible endings show (both prompts are 8931 chars).

E1: A's prompt ends "Cache probe agent A. This is a token-measurement probe, not a review: … Hand back exactly the text: OK"; B's the same with "B". Both requests: `"querySource": "agent:builtin:general-purpose"`, `"sessionId": "711f86df-…"`, `"model": "claude-opus-5-5"`. A's final record (tool_result for its hand-off) is at `19:39:16.656Z`; B's first record is at `19:39:44.466Z`.

**Evidence:** `FC2/inspect2-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: Result table: A first request 19:39:13.000Z; B 19:39:44.554Z "(28.5 s after A's reply at 19:39:16.055Z)"; breakpoints `system[0]`, `system[1]`, `messages[1].content[3]`; `cache_read_input_tokens` 18,900 / 18,900; `cache_creation_input_tokens` 31,731 / 31,731; input/output 2 / 52.

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:26-33`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell except the notified-tokens row (claim 22) and the byte-for-byte row (claim 12); "A's reply" is the timestamp of A's first assistant record.

E1: A `REQ … "timestamp": "2026-11-19T19:39:13.000Z"`, `ASST 2026-11-19T19:39:16.055Z … {"input_tokens": 2, "cache_creation_input_tokens": 31731, "cache_read_input_tokens": 18900, "output_tokens": 52`; B `REQ … "2026-11-19T19:39:44.554Z"`, usage identical. E4: 28.499 s.

**Evidence:** `FC2/inspect2-out.txt`, `FC2/arith-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "B started 28.5 s after A, well inside the 5-minute lifetime (`promptCacheRequested: 5m`)."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:36`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the field's presence in both transcripts and the 5m write tier in usage; does not establish the server-side TTL beyond what the records report.

E2: `promptCacheRequested occurrences: ['"promptCacheRequested":"5m"']` in each transcript. E1 usage: `"cache_creation": {"ephemeral_1h_input_tokens": 0, "ephemeral_5m_input_tokens": 31731}`.

**Evidence:** `FC2/inspect3-out.txt`, `FC2/inspect2-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: "Notified `subagent_tokens` 50,685 / 50,685" and "Cost of the probe: 2 × 50,685 = 101,370 tokens by the notified figure. Nearly all of that is the harness context every agent starts with, not the tail."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:34,93-94`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the notification figures, the product, and that the prompt block (~8.9k chars incl. the 8,755-byte shared block) is a small share of 50,685; does not establish a per-part token split (no per-block token counts in the records).

E6: both task notifications contain `<usage><subagent_tokens>50685</subagent_tokens><tool_uses>0</tool_uses>` (agents a047a7e5… and ad056587…). E4: `2x50685 101370`; 2+31,731+18,900+52 = 50,685, so the figure equals the single call's total. Block [3] is 8,932 chars against ~145k chars of request content (E1/E2 block lengths plus 54,119 chars of tools).

**Evidence:** `/home/node/.claude/projects/-workspace/711f86df-792b-492f-9d5e-95022839ec2c.jsonl` (task notifications), `FC2/arith-out.txt`, `FC2/inspect2-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "`system[0]`, `system[1]`: the agent's system prompt. Breakpoints 1 and 2 sit here, and tools and system are what the 18,900 cached tokens are." … "the longest entry B can match is `system[1]`: 18,900 tokens."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:44-45,62-63`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that `system[1]` is the only breakpoint before A and B diverge, and that the 18,900 read is consistent with the tools+system prefix by size; does not establish an exact token count of tools+system (no tokenizer offline), and Medium because the identification is an inference from the records.

E2: shape `system blocks 2 [90, 3187]`, `tools 11 54119` (JSON chars). The only breakpoints are `system[0]`, `system[1]` and the last block (claim 14a), and A and B first differ inside `messages[0].content[3]` (claim 12). So `system[1]` is the last breakpoint position they share. Both agents (and all 9 A8 agents, `results.md:65-67`) read exactly 18,900. By size: tools+system are ~57.4k chars against 18,900 tokens, and the fresh part is ~87.0k chars against 31,731 tokens. That is a similar chars/token ratio (≈3.0 vs ≈2.7).

**Evidence:** `FC2/inspect3-out.txt`, `FC2/inspect2-out.txt`, `runs/review-arms/a8-2026-11-19/results.md:65-67`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "`messages[0]` (user), five text blocks: [0] the instruction files, [1] git status, [2] commit attribution, **[3] the whole prompt (shared block + tail)**, [4] the hand-off reminder. Blocks 0-2 and 4 hash the same in A and B; only block 3 differs. `messages[1]` (a system-role message), four blocks: the skill listing, then three deferred tool definitions. Breakpoint 3 is on its last block, `messages[1].content[3]`: the end of the request."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:46-51`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers order, count, role, hashes and breakpoint position (all right); the imprecision is the labelling of `messages[1]`'s blocks, the same as in claim 7, and it does not touch the conclusion.

E1 (both agents): `role= user n= 5` with blocks beginning "Codebase and user instructions…", "…following context:\n# gitStatus…" (git status), "Attribution for git commits…", "# Review pass: shared context…", "…Your final report is delivered through SubagentHandback…". Hashes match except [3]. `role= system n= 4`; breakpoint `['messages', 1, 'content', 3]`; the `tail` lists two blobs, so this is the last block. E3: `messages[1].content[0]` holds the "just became available" tool list, the deferred-tool list, "# Environment" and the skill listing. The three `tool_addition` blocks define `mcp__claude_ai_Claude_Docs__batch/guide/update`, which that text calls "ready to use", not deferred. Precise version: "the tool, environment and skill listings, then three tool definitions added mid-conversation".

**Evidence:** `FC2/inspect2-out.txt`, `FC2/inspect3-out.txt`
**Legibility-target:** for-author

---

## Claim 25: "A small correction to `results.md` §2, which reads this path as \"the end of the first user turn\": `messages[1]` is the system-role message after the user turn, so breakpoint 3 is the last block of the request. The conclusion stands"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:53-55`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same evidence and limits as claim 15.

results.md:74-75 reads "`messages[1].content[3]`, the end of the first user turn, after the per-agent tail"; the records give `messages[1]` `role= system` (E1, E3). The breakpoint is still after block [3], so §2's conclusion stands.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:73-76`, `FC2/inspect2-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: "Prompt caching matches on whole content blocks. On each breakpoint the API checks earlier content-block boundaries (up to about 20 blocks back) for an entry an earlier request wrote there. (Source: … seen through a web-search summary only; … treat the wording as unverified.)"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:57-61`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers that the claim is explicitly flagged unverified and is consistent with the records; does not establish the API's matching rule or the ~20-block lookback figure.

There is no egress, so the source cannot be fetched. The records agree with it: A wrote entries only at its breakpoints, and B, sharing blocks up to `messages[0].content[2]` plus 8,755 leading bytes of [3], read only the 18,900 of `system[1]` (claims 12, 13). Verification needs a fetch of the cited page from a host with network access.

**Evidence:** `FC2/inspect2-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: "The Agent tool takes the prompt as one string and sends it as one content block. The breakpoints are placed by Claude Code on the system prompt and on the request's last block. The orchestrator controls neither. Reordering text inside the prompt cannot make a block boundary at the shared block's end"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:66-72`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Agent-tool path in Claude Code 2.1.328 as recorded (first and later requests); does not establish other harness versions, nor mechanisms outside the prompt string (which the doc itself sets aside as "a different mechanism").

The evidence is the same as claim 14a. The prompt string equals `messages[0].content[3]` exactly (`block[3] == user str? True`). The breakpoints are always `system[0]`, `system[1]` and the request's last block, across the probe requests and the A8 agent's later requests (`['messages', 4, 'content', 0]`, …). Anything an orchestrator writes into the prompt stays inside that one block, so no reordering of it creates a block boundary.

**Evidence:** `FC2/inspect2-out.txt`, `FC2/inspect3-out.txt`, `FC2/inspect-a8.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: "Matching would serve more than the block: B's whole prefix up to block 3 (instruction files included), roughly the 31.7k tokens each agent now writes fresh."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:77-79`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the relation between "prefix up to block 3" and the 31,731 fresh write. Medium because the split below is a chars-proportional estimate with no per-block token counts.

The 31,731 fresh tokens cover everything after `system[1]`: all five `messages[0]` blocks and the four `messages[1]` blocks (E1 lengths: 47,023 + 1,782 + 709 + 8,932 + 419 chars, then 26,004 + 532 + 623 + 1,014). E4 apportions by characters: through `messages[0].content[3]` ≈ 21.3k tokens, and `messages[1]` ≈ 10.3k. So "the prefix up to block 3" is about two-thirds of the 31.7k. Only a match on the whole request (through `messages[1].content[3]`, the only later breakpoint) would serve ~31.7k. The direction ("more than the block") is right. Precise version: "up to the end of the request, roughly the 31.7k …", or "up to block 3, roughly 21k of the 31.7k".

**Evidence:** `FC2/inspect2-out.txt`, `FC2/arith-out.txt`
**Legibility-target:** for-author

---

## Claim 29: "The skill's \"This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a pass\" and \"Leave it on because it is free\" (`skills/code-review/SKILL.md:274-277`, `:352-354`) describe a saving that does not occur."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:83-87`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotes and line numbers (as claim 16) and the within-pass, cross-agent saving on the Agent-tool path; does not establish the cross-pass half of `:275` ("and again on the next loop pass"), which the probe doc says it did not test (claim 30).

The quotes match `skills/code-review/SKILL.md:274-275` and `:353` verbatim (see claim 16 for the lines). The "does not occur" conclusion rests on claims 13 and 27 and on results.md §2 for the parallel case.

**Evidence:** `skills/code-review/SKILL.md:274-277,352-354`, `runs/review-arms/a8-2026-11-19/results.md:65-72`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: "What remains is each agent's own reuse within its run, which happens with or without inlining (`results.md` §2). The probe did not test reuse across loop passes."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:87-89`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation and the probe's design (one session, no fix commit between agents); the following sentence's cross-pass prediction ("hits only if its whole prompt is byte-identical") is an inference from the same mechanism, not measured.

results.md §2: "(Within a run, an agent's later calls usually re-read its own prefix from cache, block included, which happens with or without inlining." (`results.md:67-69`). The probe ran two agents in one pass with the same block and no intervening commit (cache-probe.md Method, claim 19), so no cross-pass case was exercised.

**Evidence:** `runs/review-arms/a8-2026-11-19/results.md:65-72`, `FC2/inspect2-out.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: Commit 4363a15c: "both first calls read 18,900 cached tokens and wrote 31,731 … the prompt is one content block and Claude Code's breakpoints sit on the system prompt and the request's last block, so no prompt order makes the block cacheable. The skill is unchanged (brief criterion 2). Rubric row A8 is Split to Q-308." / Notes: "the rubric's status line moved to the all-resolved form."

**Location:** commit `4363a15c` message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures, the breakpoint layout, the empty skill diff, the A8 cell and the status line; the "dispatched 28.5 s apart" phrase is checked separately (claim 32).

The figures and layout are as in claims 13, 14a and 27. `git diff --stat 8b060877 HEAD -- skills/` is empty. The A8 cell starts `Split` and names Q-308 (claim 2). The status line matches the template (claim 1).

**Evidence:** `FC2/inspect2-out.txt`, `docs/reviews/code-review-rubric-2026-08-07-main.md:4,35`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: Commit 4363a15c: "Two Agent-tool subagents carried the A8 Stage-1 shared block byte for byte, dispatched 28.5 s apart"

**Location:** commit `4363a15c` message
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the interval named; the byte-for-byte half is Verified (claim 12).

28.5 s is the gap from A's reply (`19:39:16.055Z`) to B's first request (`19:39:44.554Z`), as the probe doc states it. The two dispatches were further apart. A's first prompt record is `19:39:12.927Z` and B's is `19:39:44.466Z`, 31.5 s apart, and their first requests (`19:39:13.000Z` / `19:39:44.554Z`) are 31.6 s apart (E1). Precise version: "B dispatched 28.5 s after A's reply". This is immaterial to the conclusion, because either interval is well inside the 5-minute TTL.

**Evidence:** `FC2/inspect2-out.txt`
**Legibility-target:** for-author

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 7** (`docs/working/research-2026-11-19-a8-cache-probe.md:74-77`): the three `tool_addition` blocks in `messages[1]` are the immediately-loaded Claude Docs tools, not "deferred tool definitions"; block [0] holds the tool, environment and skill listings, not only "the skill listing".
- **Claim 11** (`docs/working/research-2026-11-19-a8-cache-probe.md:86-87`): the rubric cell cites 18,900 and 28.5 s but not 31,731.
- **Claim 24** (`runs/review-arms/a8-2026-11-19/cache-probe.md:49-50`): same mislabel as Claim 7 ("the skill listing, then three deferred tool definitions").
- **Claim 28** (`runs/review-arms/a8-2026-11-19/cache-probe.md:77-79`): "B's whole prefix up to block 3 … roughly the 31.7k". The prefix through `messages[0].content[3]` is ~21k by a chars-proportional estimate; ~31.7k needs a match through the end of the request.
- **Claim 32** (commit `4363a15c`): "dispatched 28.5 s apart". The gap is 28.5 s from A's reply to B's first request; the dispatches were ~31.5 s apart.

### Unverifiable
- **Claim 14b** (`docs/working/research-2026-11-19-a8-cache-probe.md:106-108`) and **Claim 26** (`runs/review-arms/a8-2026-11-19/cache-probe.md:57-61`): the whole-block matching rule and ~20-block lookback come from a web-search summary. Both docs flag it as unverified and it agrees with the records. Checking it needs a fetch of the Anthropic prompt-caching page from a host with egress.

---

## Goal-Alignment Note

- **Success criterion:** a code-fact-check report saved at the output path below, in the code-fact-check skill's report schema.
- **Answered:** yes. All 12 brief items were checked against the transcripts, the task notifications, results.md, SKILL.md, rubric.md and the questions files, giving 33 claims: 26 Verified, 5 Mostly accurate, 2 Unverifiable, 0 Incorrect or Stale. The load-bearing result (no cross-agent cache read, and no prompt order can create one on this path) holds on the records.
- **Out of scope:** whether `Split` is a better judgment than `Acknowledged` (both are legal for 🟡; the cell meets Split's carry rule); whether an appended parenthetical on the status line is allowed (rubric.md is silent; the prior line had one); the brief's own `Status: open` line (the brief says the merging change flips it, and the brief is not in this diff); Q-304 (not cited by the diff).
- **Escalate:** nothing blocking. The five Mostly-accurate items are wording fixes for the author. Q-308's interim option "[2] After the cache fix" assumes a prompt-layout fix may exist, and this probe shows no prompt order fixes it. That is for the cycle to note when Q-308 is next surfaced; it is not a defect in this diff.
