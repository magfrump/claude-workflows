Commit: f87a1455

# Code Fact-Check Report

**Commit:** f87a1455
**Replication:** k=3
**Repository:** claude-workflows (worktree wt-2026-11-19-a8-cache-probe)
**Scope:** `git diff 8b06087719a4fd260cf692be9f5d485aee8535f1..HEAD` (branch measure/a8-cache-probe, commits 4363a15c, f87a1455)
**Checked:** 2026-11-19
**Total claims checked:** 14 merged clusters (r1: 26 claims, r2: 33, r3: 35)
**Summary:** 0 Incorrect, 0 Stale, 6 Mostly accurate, 1 Unverifiable, 7 Verified (clusters). Merged most-severe-wins from `code-fact-check-report-2026-11-19-measure-a8-cache-probe-r{1,2,3}.md`; per-claim evidence and execution logs are in those reports and in the replicates' scratch directories (`.../2026-11-19-a8-cache-probe/review/fc{1,2,3}/`).

---

## Claim 1: A8-record `messages[1]` described as "the skill listing and three deferred tool definitions"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:21-22`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the first request of agent-a6a0ebd8bee725384 (A8 Stage 2.5) and the probe agents; does not establish the on-the-wire role (records show Claude Code's internal role).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "block [0] holds the tools-ready notice, the deferred-tool name list and the skill listing (r1: also an '# Environment' section; skill listing starts at offset 2687); blocks [1]-[3] are `tool_addition` definitions of the Claude_Docs batch/guide/update tools, announced as ready to use, not deferred." Structure (2 system blocks, user 5 blocks, `messages[1]` role system with 4 blocks, breakpoint on its last block) is otherwise correct.
**Legibility-target:** for-author

Precise version: "a system-role message: tool and skill listings in one block, then three added (ready-to-use) tool definitions".

---

## Claim 2: Probe doc's `messages[1]` layout, "four blocks: the skill listing, then three deferred tool definitions"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:49-50`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both probe agents' first requests; the breakpoint path `messages[1].content[3]` and role `system` are verified.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: same mislabel as Claim 1 (the three definitions are the ready-to-use Claude_Docs tools; block [0] is more than the skill listing).
**Legibility-target:** for-author

---

## Claim 3: "B's whole prefix up to block 3 (instruction files included), roughly the 31.7k tokens each agent now writes fresh"

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:77-78`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** chars/4 and the request's own chars-per-token ratio estimates; no tokenizer count.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r2+r3: "31,731 created tokens are everything after `system[1]` (user blocks 0-4 and the whole system-role message); blocks 0-3 alone are ~20-21k." The span named and the figure do not match.
**Legibility-target:** for-author

---

## Claim 4: "a byte-identical whole prompt ... would let a sibling hit the whole ~31.7k prefix"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:68-69`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** estimate from usage records.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** r3: "a whole-prompt match would hit the whole request prefix (~50.6k); the ~31.7k is the extra saving over today's 18,900, not the prefix's size."
**Legibility-target:** for-author

---

## Claim 5: FP-089 note — "the probe doc and the rubric cell cite the same figures (18,900; 31,731; 28.5 s)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:31-32`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** compares the A8 Status cell (`code-review-rubric-2026-08-07-main.md:35`) with cache-probe.md.
**Replicate verdicts:** r1=Verified · r2=Mostly accurate · r3=—
**Replicate annotations:** r2: "the rubric cell cites only 18,900 and 28.5 s, not 31,731." The figures it does cite match.
**Legibility-target:** for-author

---

## Claim 6: `api-request-shape` described as "(system)"

**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:16-17`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** record format in the probe and A8 transcripts only.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Mostly accurate
**Replicate annotations:** r3: "`api-request-shape` holds keys ['system','tools'] (11 tools); tools are part of the 18,900 cached prefix."
**Legibility-target:** for-author

---

## Claim 7: Commit 4363a15c message, "dispatched 28.5 s apart"

**Location:** commit 4363a15c message, line 1 of body
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** transcript timestamps.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1+r2+r3: "28.5 s (28.499 s) runs from A's reply (19:39:16.055Z) to B's first request (19:39:44.554Z); dispatch to dispatch and request to request were ~31.4-31.5 s." The probe doc itself words it correctly ("28.5 s after A's reply").
**Legibility-target:** for-author

---

## Claim 8: Web-sourced caching rule (whole-block matching, ~20-block lookback)

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:57-61`; `docs/working/research-2026-11-19-a8-cache-probe.md:51-52`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** no egress; both docs already flag it unverified. Does not bear on the verdict: records alone show B read only the system+tools prefix.
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r1+r2+r3: "needs a host fetch of the Anthropic prompt-caching page; records are consistent with it."
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: Probe figures and timing (18,900 / 31,731 both agents; input 2 / output 52; 50,685 each; 2 × 50,685 = 101,370; 8,755 bytes; 19:39:13.000Z, 19:39:16.055Z, 19:39:44.554Z; 28.5 s; `promptCacheRequested: 5m`)

**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:11-36,93-94`; research doc `:45-47`; rubric `:35`; commit 4363a15c
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** both probe transcripts, probe-out.txt, `wc -c` of `csp/shared-block.md` (sha256 prefix be4a2600985537d5 = A8 Stage-1 block).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "50,685 equals the last call's four-field usage sum." r3: "brief expected 'a few thousand tokens each'; actual 50,685 per agent (brief statement, not a diff claim)."
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: Byte-for-byte prefix and block hashes ("All user content blocks except [3] hash the same; the system-role message hashes the same")

**Location:** research doc `:43-44`; cache-probe.md `:29,44-48`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** byte comparison of each recorded prompt against the block file and per-block hashing.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "A and B differ at a single character (index 8768)."
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: Breakpoints at `system[0]`, `system[1]`, `messages[1].content[3]` (end of request); `messages[1]` role system; correction to `results.md` §2; "no prompt order puts a breakpoint at the block's end"; "longest entry B can match is `system[1]`: 18,900"

**Location:** cache-probe.md `:30,39-68`; research doc `:48-56`; rubric `:35`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** first requests of both probe agents and the A8 Stage-2.5 agent; the prompt arrives as one text block. 18,900 = system+tools is consistent by estimate only (~19.8k by the request's chars/token ratio). Does not establish Claude Code behaviour in other versions.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: "in later calls the third breakpoint moves to the last message." r3: "18,900 = system + tools is an estimate, not a tokenizer count."
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: SKILL.md line references (`:274-277`, `:352-354`, section `268-358`; rubric row's original `:276-278`)

**Location:** research doc `:24-25,77-78`; cache-probe.md `:86-87`; rubric `:35`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** `skills/code-review/SKILL.md` at HEAD; the row's `:276-278` is correct at 2f5ad0b (the commit that rubric reviewed).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r3: "quotes sit at :274-275 and :352-353 (ranges include them)."
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: Rubric closure — `Split` status word, Q-308 and Q-306, status line and "all other reds/ambers fixed in iterations 1–3"

**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4,35`; research doc `:26-28,60-66`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** rubric.md "Status words" and "Rubric Status Line"; questions.md Q-308 (open; covers net inline cost and recall); Q-306 answered [1]; every 🔴/🟡 row closed, the iter-4 rows are all 🟢.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "status line appends a parenthetical after the verbatim label; template neither allows nor forbids (`rubric.md:609,619-624`)." r1+r2+r3: "Q-308's interim option [2] 'After the cache fix' now waits on a fix this probe says cannot exist via prompt order — for the cycle to restate (questions files out of this brief's scope)." r3 (out of scope): "A8 row's unchanged Author note still reads 'run the post-restructure measurement once … settled'."
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14: Commit f87a1455 — rows A3, A6, A7 had 8 cells under a 9-column header; now 9

**Location:** commit f87a1455; rubric `:30,33,34`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** cell counts at base, 4363a15c and HEAD; r3 ran the repo's `rubric_parse`, which flags the three rows before and nothing at HEAD. The 🔴 table has 8 columns throughout.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none
**Legibility-target:** for-orchestrator-synthesis

---

## Submitted Claims

Stage 2.5 (k=1, opus), Claims 15-20, in full in `code-fact-check-submitted-claims-2026-11-19-measure-a8-cache-probe.md`: 15 Verified (executed; performance-reviewer), 16 Verified (static; performance-reviewer), 17 Verified (executed; api-consistency-reviewer, `rubric_parse` in `scripts/lib/rubric-check.sh` at f87a1455/4363a15c/8b060877), 18 Verified (executed; api-consistency; R1 is file line 17, not :20), 19 Verified (executed; api-consistency), 20 Mostly accurate (static; api-consistency: Split fits the moved part; Acknowledged also valid; the SKILL-text remedy has no tracked follow-up).

## Escalations

- `docs/working/briefs/2026-11-19-a8-cache-probe.md:3` — brief still reads `Status: open`; acceptance criteria require "open → done" in the change that merges this work (research doc Plan step 3 lists it as pending). Raised by r1 (also r3 out-of-scope note). Addressee: orchestrator.
- `docs/working/questions.md` Q-308 — interim option "[2] After the cache fix" presumes a fix the probe rules out. r1+r2+r3. Addressee: orchestrator (cycle; outside this brief's scope).

## Verdict stability

- Clusters: 14. All reporting replicates agreed: 10 (Claims 1, 2, 3, 8, 9, 10, 11, 12, 13, 14). Disagreed: 3 — Claim 5 (r1=Verified · r2=Mostly accurate), Claim 6 (r1=Verified (compound) · r2=Verified · r3=Mostly accurate), Claim 7 (r1=Mostly accurate · r2=Mostly accurate · r3=Verified (compound)). Single-replicate: 1 (Claim 4).
- Agreement among multi-replicate clusters: 10/13 (77%).
