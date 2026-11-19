Commit: 89eb9b65

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-cache-probe (claude-workflows), branch `measure/a8-cache-probe`
**Scope:** `git diff f87a1455..139aeedd` (commit 139aeedd): `docs/reviews/code-review-rubric-2026-08-07-main.md`, `docs/working/research-2026-11-19-a8-cache-probe.md`, `runs/review-arms/a8-2026-11-19/cache-probe.md`, plus the commit message. Partial scope (loop pass, delta range); 4363a15c, f87a1455 and 89eb9b65 are context only.
**Checked:** 2026-11-19
**Replication:** k=1 (loop pass, decision 031)
**Total claims checked:** 18
**Summary:** 14 verified, 3 mostly accurate, 1 stale, 0 incorrect, 0 unverifiable

Evidence runs (executed, cwd `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review2/fc`, all exit 0, 2026-11-19T20:20-20:30Z):
- E1 transcript parse: `timeout 60 python3 -I b0.py <transcript>` and `python3 -I s25.py <transcript>` for `agent-a047a7e5a841ceab4` (probe A), `agent-ad0565873cbe05c85` (probe B) and `agent-a6a0ebd8bee725384` (the A8 run's Stage 2.5 agent, prompt output path `.../a8-2026-11-19/csp/code-fact-check-submitted-claims.md`, first request 2026-11-19T18:34:02.437Z). Output: `.../review2/fc/transcripts.txt` (run 2026-11-19T20:29:53Z). Usage figures from `.../2026-11-19-a8-cache-probe/probe-out.txt`.
- E2 rubric parser: `timeout 60 bash -c 'source scripts/lib/rubric-check.sh && rubric_parse docs/reviews/code-review-rubric-2026-08-07-main.md'`, cwd the worktree, exit 0, 2026-11-19T20:28:24Z. Output: `.../review2/fc/parse.txt`. Same parser on `main`'s and 4363a15c's copy of the file for comparison (A8 = `open` on main, `closed` at 4363a15c).

---

## Claim 1: "1 amber item awaiting resolution (A8: measured 2026-11-19, ...; all other reds/ambers fixed in iterations 1–3)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of non-Fixed 🔴/🟡 rows by their Status cells; does not establish how the repo's advisory gate reads A8 (see Escalations: it reads it closed).

E2 lists R1 and A1-A7, A9-A12 as `fixed`; A8's Status cell begins `🟡 Open — measured 2026-11-19: the claim fails on its benefit` (`:35`). A8 is the only 🔴/🟡 row not starting `✅ Fixed`.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:17`, `:28-39`; `.../review2/fc/parse.txt`

---

## Claim 2: Status-line form `**Status: 🟡 CONDITIONAL PASS** — 1 amber item awaiting resolution (...)` follows the template

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the line against `rubric.md`'s Rubric Status Line rule; does not establish any parser dependence on the exact wording (the rubric parser reads tables, not the status line).

The template is `` `**Status: 🟡 CONDITIONAL PASS** — [N] amber item(s) awaiting resolution or justification` `` (`skills/code-review/references/rubric.md:608`). The file drops "or justification" and adds a parenthetical. This is the same form `main` already had (`... — 1 amber item awaiting resolution (A8, blocked on the post-restructure measurement; ...)`, `git show main:` line 4), so the commit restores it rather than inventing it. Precise version: "1 amber item(s) awaiting resolution or justification (A8: ...)". Cosmetic.

**Evidence:** `skills/code-review/references/rubric.md:606-609`; `main:docs/reviews/code-review-rubric-2026-08-07-main.md:4`

---

## Claim 3a: A8 cell quotes match HEAD lines: "`SKILL.md:274-277`, `:352-354`" and "A7's cross-pass claim (`:347-351`)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers line numbers at HEAD of `skills/code-review/SKILL.md` (unchanged on this branch, `git diff main HEAD -- skills/code-review/SKILL.md` empty); does not establish line stability after later SKILL.md edits.

`skills/code-review/SKILL.md:274-277`: "This lets the Anthropic prompt cache serve the shared block to all ~8 agents in a / pass — and again on the next loop pass while it is unchanged — at the cache-read rate ...". `:352-354`: "**Measured benefit is modest — single-digit-% of input cost, 0% of token count** ... Leave it on because it is free". `:347-351`: "Across loop passes, the block's prefix stays cache-warm up to the first part that changed: ... Ordering stable-parts-first is what preserves a cacheable common prefix across passes even when the diff changes."

**Evidence:** `skills/code-review/SKILL.md:274-277`, `:347-351`, `:352-354`

---

## Claim 3b: "the skill text this row cites (`SKILL.md:274-277`, `:352-354`)"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the row's own Finding cell cites; does not affect the cell's substance (both spans do state the now-measured-false saving).

The row's Finding cites only `` "Leave it on because it is free" / "0% of token count" (`SKILL.md:276-278`) ``; at 2f5ad0b those lines are "- **Measured benefit is modest — single-digit-% of input cost, 0% of token count** ... Leave it on because it is free" (`git show 2f5ad0b:skills/code-review/SKILL.md` :276-278), i.e. today's `:352-354`. `:274-277` ("serve the shared block to all ~8 agents") is extra text the row did not cite. Precise version: "the skill text this row cites (now `SKILL.md:352-354`) and its premise at `:274-277`". Same imprecision in `cache-probe.md` is not present (it quotes both without "this row cites").

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `2f5ad0b:skills/code-review/SKILL.md:276-278`

---

## Claim 4: A8 cell figures "a second agent 28.5 s later, same block byte for byte, still read only 18,900 tokens"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures against the probe records; "28.5 s later" is measured from A's reply (A's first-request to B's first-request gap is ~31.5 s), which the cell leaves implicit and `cache-probe.md:28` states.

`probe-out.txt`: A "usage 2026-11-19T19:39:16.055Z {... 'cache_read_input_tokens': 18900 ...}"; B "first request 2026-11-19T19:39:44.554Z" and "'cache_read_input_tokens': 18900"; 44.554 − 16.055 = 28.499 s. "B prompt starts with block: True".

**Evidence:** `.../2026-11-19-a8-cache-probe/probe-out.txt`; `runs/review-arms/a8-2026-11-19/cache-probe.md:28-31`

---

## Claim 5: "`api-request-shape` (system and tools)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:16-17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record's `shape` keys in all three transcripts read; does not establish the record format of other Claude Code versions (records are `version: 2.1.328`).

E1: "shape keys ['system', 'tools']", "system list 2", "tools list 11" for probe A, probe B and the Stage 2.5 agent.

**Evidence:** `.../review2/fc/transcripts.txt`

---

## Claim 6: A8 Stage-2.5 record: "`messages[1]` a system-role message with the tool, deferred-name, environment and skill listings, then three newly ready tool definitions, breakpoint on its last block"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:19-22`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the Stage 2.5 agent's (`agent-a6a0ebd8bee725384`) first system-role blob and first `api-request`'s `cacheControl`; does not establish that every A8 agent had the same Claude Docs additions (only this one record is cited).

E1 for that agent: "role system nblocks 4"; block [0] section heads in order "The following tools just became available and are ready to use:", "The following deferred tools are now available via ToolSearch.", "# Environment", "The following skills are available for use with the Skill tool:"; blocks [1]-[3] `{"type": "tool_addition", ... "name": "mcp__claude_ai_Claude_Docs__batch"` / `__guide` / `__update`; cacheControl `[["system",0],["system",1],["messages",1,"content",3]]`. Order and content match the wording. Block [0] also ends with a date line ("Today's date is 2026-11-19.", paraphrased — no quote available because only the probe B blob tail was printed; the section-head order is identical in both), which the wording omits harmlessly.

**Evidence:** `.../review2/fc/transcripts.txt`; `/home/node/.claude/projects/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/subagents/agent-a6a0ebd8bee725384.jsonl`

---

## Claim 7: FP-089 note "the probe doc and the rubric cell cite the same figures (18,900; 28.5 s)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:31-32`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the numeric figures in the A8 cell vs `cache-probe.md`; does not establish the probe doc's other figures (31,731; 50,685), which the cell does not cite.

A8 cell: "a second agent 28.5 s later, ... still read only 18,900 tokens" (`code-review-rubric-2026-08-07-main.md:35`); `cache-probe.md:28` "28.5 s after A's reply", `:31` "**18,900**". No other figure appears in the cell besides dates.

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `runs/review-arms/a8-2026-11-19/cache-probe.md:28-34`

---

## Claim 8: "`Split` (to Q-308) was the first pick, but review found Q-308 covers only the settling runs"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:62-64`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers Q-308's text in `docs/working/questions.md`; does not establish whether the cycle has since filed the skill-text correction elsewhere.

`docs/working/questions.md:166-169`: "### Q-308 · a8-settling-runs ... Run the two larger measurements that would settle the A8 question ...: a self-read control pass on the csp cell and a pass on the larger corpus cell?" Its options (`:176-180`) are run both / after the cache fix / don't run; nothing about correcting SKILL.md text.

**Evidence:** `docs/working/questions.md:166-186`

---

## Claim 9: "`Acknowledged` needs a tracked follow-up or a revisit trigger for the same reason"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:65-66`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric.md definition; does not establish how the parser reads a cell (it closes an amber on a Q-ID keyword whatever its first word; see Escalations).

`skills/code-review/references/rubric.md:201` "`Acknowledged` | 🟡, 🟢 | stands with a [qualifying author note]"; `:178-183` "(a) A discoverable TODO — ... or a tracked follow-up entry ... (b) A concrete revisit trigger".

**Evidence:** `skills/code-review/references/rubric.md:170-186`, `:197-206`

---

## Claim 10: "would let a sibling read its whole request (~50.6k) from cache"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:68-69`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Same as Claim 14; covers the figure, not the hypothetical mechanism's feasibility.

See Claim 14: 18,900 + 31,731 = 50,631 cacheable tokens of a 50,633-token input.

**Evidence:** `.../2026-11-19-a8-cache-probe/probe-out.txt`

---

## Claim 11: Follow-up cites "`SKILL.md:274-277`, `:352-354`" and "its stable-parts-first rule claims cross-pass warmth (`:347-351`, rubric row A7)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:74-75`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quotes and line numbers at HEAD and A7's subject; does not establish that the cycle has filed the follow-up.

Quotes as in Claim 3a. Row A7: "Prefix ordering forfeits cross-pass cache warmth ... Reorder stable-parts-first. | ... | ✅ Fixed (iter 2 — shared block reordered stable-parts-first ...)" (`code-review-rubric-2026-08-07-main.md:34`).

**Evidence:** `skills/code-review/SKILL.md:274-277`, `:347-354`; `docs/reviews/code-review-rubric-2026-08-07-main.md:34`

---

## Claim 12: Title "Research: A8 cache probe and the closing note for rubric row A8"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:1`
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the title line (unchanged by 139aeedd, but left behind by it); no other stale Split/closure wording was found in the three files (`rg -n -i "split|clos|PASSES|resolved"` hits only this title, line 62's deliberate history, and unrelated rubric rows).

The doc now records that A8 is not closed: "So the row stays open until the cycle files the correction" (`:66`). The title still calls the A8 cell a "closing note". Precise version: e.g. "... and the measured verdict for rubric row A8". Leftover from 4363a15c, low impact.

**Evidence:** `docs/working/research-2026-11-19-a8-cache-probe.md:1`, `:62-67`

---

## Claim 13: "`messages[1]` (a system-role message), four blocks: [0] the tool, deferred-tool-name, environment and skill listings; [1]-[3] the definitions of three tools that became ready to use (the Claude Docs connector)"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:49-52`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both probe agents' first-request system-role blob (same hash `14236cb7f9a8` in A and B) and breakpoint path; does not establish that "connector" is the harness's own term (the blocks name `mcp__claude_ai_Claude_Docs__*` tools).

`probe-out.txt`: "blob 14236cb7f9a8 system ['af851756', '5e0b9708', 'fc45f571', 'ed602d38']" for both A and B; breakpoints `['messages', 1, 'content', 3]`. E1 (probe B): block [0] starts "The following tools just became available and are ready to use:\nmcp__claude_ai_Claude_Docs__batch ...", with "deferred" at char 182, "# Environment" at 985, "skills are available" at 2702, ending "...Today's date is 2026-11-19."; blocks [1]-[3] are `"type": "tool_addition"` for `mcp__claude_ai_Claude_Docs__batch`, `__guide`, `__update`. Order and content are right.

**Evidence:** `.../2026-11-19-a8-cache-probe/probe-out.txt`; `.../review2/fc/transcripts.txt`

---

## Claim 14: "B would read its whole request from cache, about 50.6k tokens (18,900 + 31,731) instead of 18,900, instruction files and listings included"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:78-79`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic and which spans the cacheable tokens include; does not establish that the hypothetical byte-identical delivery would hit (untested), and "whole request" is approximate by 2 uncached input tokens.

`probe-out.txt` B usage: "'input_tokens': 2, 'cache_creation_input_tokens': 31731, 'cache_read_input_tokens': 18900, 'output_tokens': 52". python3: 18,900 + 31,731 = 50,631; total input 50,633; with output 50,685 = the notified figure. So "about 50.6k" is fair, and it is correctly distinct from the notified 50,685 (which adds output). The last breakpoint is the request's last block (`messages[1].content[3]`), so a byte-identical request would match up to the end; only the 2-token remainder stays uncached. The 31,731 created span covers `messages[0]` (instruction files etc.) and `messages[1]` (listings), so "instruction files and listings included" holds.

**Evidence:** `.../2026-11-19-a8-cache-probe/probe-out.txt`; `runs/review-arms/a8-2026-11-19/cache-probe.md:30-34`

---

## Claim 15: "rubric row A7 ... (marked Fixed): its stable-parts-first order (`SKILL.md:347-351`) keeps parts 1-4 a common prefix, but no breakpoint ends there either, so by this mechanism it buys no cross-pass cache hit. That is inferred from the records, not measured."

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:91-95`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers A7's status, the line cite and consistency with the recorded breakpoint layout; the cross-pass result itself is (as the text says) inferred, not measured.

A7 Status "✅ Fixed (iter 2 — shared block reordered stable-parts-first, diff+enclosing now part 5 of 6 ...)" (`code-review-rubric-2026-08-07-main.md:34`). `SKILL.md:348` "parts 1–4 are stable across the whole fix→re-review loop". Breakpoints are `system[0]`, `system[1]`, `messages[1].content[3]` (`cache-probe.md:30`), and parts 1-4 sit inside `messages[0].content[3]` (`:46-47`), so no breakpoint ends at part 4. The "inferred, not measured" label is accurate (`:89-90` "The probe did not test reuse across loop passes").

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:34`; `skills/code-review/SKILL.md:347-351`; `runs/review-arms/a8-2026-11-19/cache-probe.md:30`, `:46-47`, `:89-95`

---

## Claim 16: "These two agents are not rows in `token-ledger.md` or `manifest.json` ... (the omission `docs/working/review-canon.md:131` asks a results doc to state)"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:99-102`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what `review-canon.md:112-131` says; does not establish whether the owner accepts a stated omission in place of ledger rows for this probe.

The "not rows" half holds (`rg` of the two files: no probe agent IDs; paraphrased — no quote available because the claim is about absence). `:131` reads "A run that nonetheless finishes with empty `tokens` maps must state the omission explicitly in its results doc." That clause is the fallback for empty manifest `tokens` maps. The rule that covers this case is `:112-117`: "any run or sub-run that reports per-agent token figures MUST (a) append one row per agent to a `token-ledger.md` ... and (b) register the sub-run's agents and totals in the run's `manifest.json`". The probe reports per-agent figures (`cache-probe.md:34` "50,685 | 50,685"). Citing `:131` reads as if stating the omission satisfies the canon. It is the fallback that the previous pass's A3 offered ("state the omission explicitly in `cache-probe.md`, which the amendment allows"), not something the canon requires of this probe. Precise version: "(the convention at `review-canon.md:112-117` asks for ledger rows; following its amendment's fallback at `:130-131`, the omission is stated here instead)".

**Evidence:** `docs/working/review-canon.md:112-131`; `runs/review-arms/a8-2026-11-19/cache-probe.md:34`, `:98-102`; `docs/reviews/code-review-rubric-2026-11-19-measure-a8-cache-probe.md:28`

---

## Claim 17: Commit 139aeedd message (A1-A7 summary and Notes)

**Location:** `139aeedd` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed change against `git diff f87a1455..139aeedd`; does not re-verdict each change's accuracy (Claims 1-16 do that).

"A1: A8 stays Open with the measured verdict instead of Split" matches `:35` `🟡 Open — measured 2026-11-19`. "The 2026-08-07 rubric keeps its conditional-pass line" matches `:4`. "A2: record that the mechanism also voids row A7's cross-pass claim (inferred)" matches `cache-probe.md:91-95`. "A3: state why the probe agents are not ledger rows" matches `:99-102`. "A4-A7: correct the messages[1] labels, the whole-prompt figure (~50.6k, not 31.7k), the FP-089 note and the api-request-shape description" matches `cache-probe.md:49-52`, `:78-79`, research `:31-32`, `:16-17`, `:68-69`. The diffstat (3 files) matches.

**Evidence:** `git show 139aeedd`; files cited above

---

## Escalations

- **The repo's rubric parser reads A8 as closed, contradicting the status line's "1 amber item awaiting resolution".** E2 at HEAD: `row	amber	A8	closed	🟡 Open — measured 2026-11-19 ...`; on `main` the same row parsed `open`. The cause is the parser's documented rule, `scripts/lib/rubric-check.sh:62-67`: "An amber, whatever its first word, closes on a qualifying author note ... found by keyword: a Q-ID". The A8 cell names Q-306 and Q-308. The advisory merge-rubric check (`build-loop.sh --check/--merge`) will therefore not report A8 as open, which is the gap the previous pass's A1 flagged ("The parser still reads the row as closed, so no gate catches it"). Under rubric.md's definition (`rubric.md:178-180`, a note linking a tracked `questions.md` entry qualifies), the parser's reading is also arguable, because the cell routes part of A8 (net cost, recall) to Q-308. Not a fact-check verdict on a sentence. For the orchestrator: either accept this (the gate is advisory) or reword the cell so it no longer carries a bare Q-ID that reads as closure.

## Claims Requiring Attention

### Incorrect
(none)

### Stale
- **Claim 12** (`docs/working/research-2026-11-19-a8-cache-probe.md:1`): the title still says "closing note for rubric row A8". The row is now Open, so retitle it.

### Mostly Accurate
- **Claim 2** (`docs/reviews/code-review-rubric-2026-08-07-main.md:4`): the status line drops the template's "or justification" (`rubric.md:608`). The form is inherited from main and the drift is cosmetic.
- **Claim 3b** (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`): "the skill text this row cites (`:274-277`, `:352-354`)". The row cites only the text now at `:352-354` (2f5ad0b `:276-278`). `:274-277` is its premise.
- **Claim 16** (`runs/review-arms/a8-2026-11-19/cache-probe.md:101-102`): `review-canon.md:131` is the empty-`tokens`-map fallback. For a sub-run that reports per-agent figures, the canon (`:112-117`) asks for ledger and manifest rows. Name it as the fallback being used.

### Unverifiable
(none)

## Goal-Alignment Note

The goal is to confirm that 139aeedd's fixes are accurate and complete before merge. All seven prior ambers' corrections check out against the primary records:
- the probe transcripts and the A8 Stage 2.5 transcript;
- SKILL.md at HEAD;
- Q-308;
- rubric.md.

Three Mostly-accurate wording items and one stale title remain, all low impact. The one thing that bears on "complete" is the escalation. A8 is meant to stay visibly open, but the repo's own rubric parser now classifies it `closed` because the cell cites Q-IDs, so only the status line and the Status word carry the open state. Scope was the delta range only. I read the whole changed paragraphs and their sections, not the rest of the branch.
