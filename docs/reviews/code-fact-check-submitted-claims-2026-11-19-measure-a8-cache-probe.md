Commit: f87a1455

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-2026-11-19-a8-cache-probe (branch `measure/a8-cache-probe`)
**Scope:** `git diff 8b06087719a4fd260cf692be9f5d485aee8535f1..HEAD` (4363a15c, f87a1455; 3 docs files). Submitted claims only (code-review terminal pass, Stage 2.5, k=1); no claims harvested.
**Checked:** 2026-11-19
**Total claims checked:** 6
**Summary:** 5 verified, 1 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Hallucination-pattern log (`docs/reviews/hallucination-patterns.md`, 30 lines) read; no logged pattern concerns rubric parsing, cache behaviour or status words, and no claim below matches one.

Execution provenance shared by Claims 17 and 18. Script `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/sub/run-parse.sh` extracts the rubric and `scripts/lib/rubric-check.sh` at f87a1455, 4363a15c and 8b060877 with `git show` into scratch copies, sources each parser copy and runs `rubric_parse` on the rubric copy from the same commit. Command: `cd /workspace/.claude/wt-2026-11-19-a8-cache-probe && timeout 120 bash .../review/sub/run-parse.sh > .../review/sub/run-parse.log 2>&1`. The script `cd`s into the scratch dir `.../review/sub/`. Exit 0. Timestamp 2026-11-19T20:01:45Z. Captured output: `.../review/sub/run-parse.log`, plus per-commit `parse-<sha>.out` in the same directory. The parser file is byte-identical at f87a1455 and 8b060877 (`cmp` printed "parser identical"). Nothing in the repo was written.

---

## Submitted Claims

## Claim 15: "Within-run reuse of an agent's own prefix happens whether the block is inlined or self-read, so it is not a benefit attributable to lever #3."

**Submitted by:** performance-reviewer
**Location:** `runs/review-arms/a8-2026-11-19/cache-probe.md:87-88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the following. An inlined agent re-reads its whole first-call prefix (block included) on its next call. The cache read on each later call grows by the previous call's cache write, whatever that content was (tool results included), so content an agent self-reads is reused the same way. It does not establish that the reused token counts are equal in the two arms (no self-read arm exists for this cell; Q-308's control run would measure that). It also does not cover the long-gap exceptions `results.md` §2 records, or reuse across loop passes.

The cited lines say: "What remains is each agent's own reuse within its run, which happens with or without inlining (`results.md` §2)" (`runs/review-arms/a8-2026-11-19/cache-probe.md:86-88`). The source passage says: "(Within a run, an agent's later calls usually re-read its own prefix from cache, block included, which happens with or without inlining. The exceptions are calls after a long gap ...)" (`runs/review-arms/a8-2026-11-19/results.md:67-71`, excerpt ends :71; the enclosing §2 bullet continues to :72, which is read).

Executed check on the A8-run agent transcript `agent-a6a0ebd8bee725384.jsonl`, deduplicated by message id, printing `cache_read` / `cache_creation` per call (`python3 -I`, output `.../review/sub/a8-agent-usage.txt`, exit 0, 2026-11-19 ~20:05Z). The first lines are:

```
2026-11-19T18:34:05.766Z 18900 33214 2
2026-11-19T18:34:10.976Z 52114 10571 2
2026-11-19T18:34:23.334Z 62685 4279 2
```

The second call's read, 52,114, is exactly 18,900 + 33,214: the first call's whole prefix, inlined block included. The third call's read, 62,685, is 52,114 + 10,571: content first sent on call 2 (after tool use) is read back on call 3. Reuse therefore keys on prior request content, not on how that content arrived. A self-read file arriving as a tool result is reused the same way, so the reuse is not specific to lever #3. The equal-magnitude reading is not established (paraphrased — no quote available because the claim covers absence of evidence: no self-read arm was run on this cell, per `results.md:129-130` "this pass had no self-read arm to show the net").

**Evidence:** `runs/review-arms/a8-2026-11-19/cache-probe.md:86-88`, `runs/review-arms/a8-2026-11-19/results.md:67-72`, `runs/review-arms/a8-2026-11-19/results.md:129-130`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/sub/a8-agent-usage.txt`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: "Closing on the benefit half while moving net cost and recall to an owner question keeps the closure from claiming more than one cell measured."

**Submitted by:** performance-reviewer
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers three things. The A8 cell asserts only the measured benefit result and the probe's structural result. It names net cost and recall as moved, not as settled. Q-308 exists, is OPEN, and asks for exactly those runs. It does not establish two things. First, that the cell's "no prompt order puts a breakpoint at the block's end" stands on measurement alone: it is reasoned from request records plus a web source the probe doc marks unverified. Second, that the benefit half's remedy is tracked anywhere: the SKILL text that still says "Leave it on because it is free" (`skills/code-review/SKILL.md:352-354`) is left "for the cycle to file" and is named by no Q-ID or roadmap item in the cell.

The cell (`docs/reviews/code-review-rubric-2026-08-07-main.md:35`, Status column) reads: "Split — measured 2026-11-19: the claim fails on its benefit. ... the two-agent probe ... shows it is structural: a second agent 28.5 s later, same block byte for byte, still read only 18,900 tokens, and no prompt order puts a breakpoint at the block's end. Net inline cost and recall effect moved to Q-308" (elided middle read). Its basis is in `results.md:121-136`: "**The cost side cannot be told net.** ... **'Zero effect on recall' cannot be told** ... One cell cannot tell how either scales". The probe table records "`cache_read_input_tokens` | 18,900 | **18,900**" (`runs/review-arms/a8-2026-11-19/cache-probe.md:28`). Q-308 at HEAD and on main (`docs/working/questions.md:166-180` at HEAD) reads "**Status:** OPEN ... Run the two larger measurements that would settle the A8 question ...: a self-read control pass on the csp cell and a pass on the larger corpus cell?", and its option [3] says "The inline cost and recall effect stay unknown". The "no prompt order" sentence rests partly on "Prompt caching matches on whole content blocks ... seen through a web-search summary only; ... treat the wording as unverified" (`cache-probe.md:54-58`). The cell carries no such hedge, but the cited probe doc does. The SKILL text is unchanged on this branch (`git diff --stat 8b060877..HEAD` lists only the 3 docs files). `docs/working/research-2026-11-19-a8-cache-probe.md:76-79` says "Correcting that text is a pipeline change the brief puts out of scope, so it is for the cycle to file".

**Evidence:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `runs/review-arms/a8-2026-11-19/results.md:121-136`, `runs/review-arms/a8-2026-11-19/cache-probe.md:28`, `runs/review-arms/a8-2026-11-19/cache-probe.md:54-58`, `docs/working/questions.md:166-180`, `skills/code-review/SKILL.md:352-354`, `docs/working/research-2026-11-19-a8-cache-probe.md:76-79`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: "At HEAD the rubric parser reads every 🔴/🟡 row as closed and reports no bad lines (R1 fixed, A1–A7 and A9–A12 fixed, A8 closed); at base 8b060877 it reported rows A3/A6/A7 as having 8 cells."

**Submitted by:** api-consistency-reviewer
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:20-38`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `rubric_parse` (`scripts/lib/rubric-check.sh:76-199`) output on the rubric at f87a1455 and at 8b060877, with the parser identical at both. It does not establish the full `rubric_lines` gate verdict. That function also checks Q-IDs only for `qref` reds (A8 is an amber, closed by the presence of a Q-ID keyword even though Q-308 is OPEN) and adds a stale-fix-commit check that was not run here.

Run output at f87a1455 (`parse-f87a1455.out`): 13 `row` records and no `bad` or `none` line. The records include `row	red	R1	fixed ...`, `row	amber	A3	fixed ...`, `row	amber	A6	fixed ...`, `row	amber	A7	fixed ...` and `row	amber	A8	closed	Split — measured 2026-11-19: ...	Q-306 Q-308`. A1–A7 and A9–A12 are all `fixed`. At 8b060877 (`parse-8b060877.out`):

```
row	amber	A8	open	🟡 Open	-
bad	30	row A3 has 8 cells where its header has 9
bad	33	row A6 has 8 cells where its header has 9
bad	34	row A7 has 8 cells where its header has 9
```

A3, A6 and A7 had no row records there. The intermediate commit 4363a15c gives A8 `closed` and the same three `bad` lines, so f87a1455 is the commit that clears them. A8 reads as closed through the amber branch of `classify`: `return ("closed", $qids) if $qids ne "-" || $ovr || ...` (`scripts/lib/rubric-check.sh:114`, excerpt ends :114; enclosing `classify` continues to :117, which is read). That branch checks only that a Q-ID is present, not whether it is answered, which is the residue named in Scope.

**Evidence:** `scripts/lib/rubric-check.sh:76-199`, `scripts/lib/rubric-check.sh:114`, `docs/reviews/code-review-rubric-2026-08-07-main.md:15-39`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/sub/run-parse.log`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/sub/parse-f87a1455.out`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/sub/parse-8b060877.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "R1's first word is Fixed (emoji skipped), with none of the parser's negation words; the 🔴 table's 8 columns match its header."

**Submitted by:** api-consistency-reviewer
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:20`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers R1's Status cell against `classify`'s first-word rule, its `$NEG` list and its first-clause not/open/still rule, plus the cell count of the R1 row against the header at f87a1455. It does not establish anything about R1's substance (whether the three SKILL sites really cross-reference Step 1). The submitted location `:20` is a line inside the diff hunk, not the file line: the R1 row is file line 17 and its header is line 15.

The parser takes the first word as `my $first = ($w =~ /([a-z][a-z-]*)/) ? $1 : "";` (`scripts/lib/rubric-check.sh:105`). The ✅ emoji is not `[a-z]`, so the first word of "✅ Fixed (iter 1 — all three sites now cross-reference Step 1's conditional rule; guarded by new `test/skills/code-review-context-delivery.bats`)" is `fixed`. That cell contains none of the `$NEG` words at `scripts/lib/rubric-check.sh:85` (no unresolved/partly/.../tbd, no "next PR", no "for ... only"). Its first clause, cut at the em dash by `:106`, holds no not/open/still. The executed parse printed `row	red	R1	fixed` and no `bad` line for line 17. A separate `python3 -I` cell count (same `\|` handling as `cells()`, `:89`) gave `15 8` and `17 8`, the header and R1 both at 8, and 9 for the amber header (26) and rows A3/A6/A7 (30, 33, 34).

**Evidence:** `scripts/lib/rubric-check.sh:85`, `scripts/lib/rubric-check.sh:89`, `scripts/lib/rubric-check.sh:102-108`, `docs/reviews/code-review-rubric-2026-08-07-main.md:15-17`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/sub/parse-f87a1455.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 19: "The new status line uses the all-resolved template verbatim, carries the single-sample label once, adds only a parenthetical (which has precedent), and is justified: no 🔴/🟡 row is open."

**Submitted by:** api-consistency-reviewer
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:4`; `skills/code-review/references/rubric.md:605-624`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four things: the line matches the template up to its appended parenthetical, the label occurs exactly once in the file, a prior rubric has the same parenthetical form, and every 🔴/🟡 row is Fixed or a Split carrying a tracked Q-ID per the Status words table. It does not establish that the parenthetical's own wording is accurate (that is Claim 16's ground), and it does not cover the "Reviewed: 2026-08-07" date and "Commit: 2f5ad0b" header fields, which the branch left unchanged.

The template is "All red and amber resolved: `**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation`" (`skills/code-review/references/rubric.md:609`). Line 4 reads "**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation (A8 split to Q-308 on 2026-11-19 after its measurement and cache probe; all other reds/ambers fixed in iterations 1–3)" (`docs/reviews/code-review-rubric-2026-08-07-main.md:4`): the template verbatim plus one parenthetical. `rg -c "absence of findings is not an attestation"` on the file returns `1`, which satisfies "verbatim and once" (`rubric.md:619`) and "never more than once" (`rubric.md:623`). Precedent: "**Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation (after 4 passes. ...)" (`docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:5`). Split is defined as "| `Split` | 🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch) |" (`rubric.md:204`), and the A8 cell names Q-308. All other 🔴/🟡 rows parse as `fixed` (Claim 17's executed run).

**Evidence:** `skills/code-review/references/rubric.md:605-624`, `skills/code-review/references/rubric.md:204`, `docs/reviews/code-review-rubric-2026-08-07-main.md:4`, `docs/reviews/code-review-rubric-2026-09-24-ans-copy-install-q058.md:5`, `/tmp/claude-1000/-workspace/711f86df-792b-492f-9d5e-95022839ec2c/scratchpad/2026-11-19-a8-cache-probe/review/sub/parse-f87a1455.out`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: "Split is the right word among Split / Deferred / Acknowledged for the part of A8 it describes: Deferred would need an override-log row; Acknowledged would mean the row stands as it is."

**Submitted by:** api-consistency-reviewer
**Location:** `skills/code-review/references/rubric.md:190-211`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the three words' definitions in the Status words table and whether the A8 cell carries what Split requires. It does not establish that Split covers all of A8. The part not moved (correcting the SKILL text the measurement refuted) has no tracked follow-up in the cell. It also does not establish that Acknowledged was unavailable.

Split fits the moved part. "| `Split` | 🔴, 🟡 | moved to another unit | the tracked follow-up (Q-ID, roadmap item or branch) |" (`rubric.md:204`), and net cost and recall go to Q-308, which is OPEN and asks for those runs (`docs/working/questions.md:166-169`). Two of the claim's glosses need tightening:

- Deferred. The table reads "| `Won't-Fix` / `Deferred` | all | declined or postponed | its override-log row (where the log cannot be edited, its Reason in the Author note); ... |" (`rubric.md:202`). So Deferred needs an override-log row, with an Author-note Reason as an alternative the claim leaves out.
- Acknowledged. The table reads "| `Acknowledged` | 🟡, 🟢 | stands with a [qualifying author note](#qualifying-author-note) | the note |" (`rubric.md:201`). That is "stands with a qualifying note", not "stands as it is". A Q-ID is a qualifying note (`rubric.md:178-180`: "a tracked follow-up entry (issue, `docs/working/questions.md` entry, or similar) the note links to"; excerpt ends :180, enclosing "Qualifying author note" section runs :170-186 — read), so the A8 cell would also qualify for Acknowledged. The research doc itself calls it viable: "two viable words, `Split` ... and `Acknowledged` (stands with a qualifying note)" (`docs/working/research-2026-11-19-a8-cache-probe.md:62-65`).

The precise version: Split is the better fit because the unmeasured part has moved to Q-308's unit. Acknowledged was a valid but weaker alternative, not a misreading. The benefit half's remedy (the "Leave it on because it is free" text at `skills/code-review/SKILL.md:352-354`, unchanged on the branch) is left "for the cycle to file" (`research-2026-11-19-a8-cache-probe.md:76-79`), and the Split cell does not name a follow-up for it.

**Evidence:** `skills/code-review/references/rubric.md:170-211`, `docs/reviews/code-review-rubric-2026-08-07-main.md:35`, `docs/working/questions.md:166-180`, `docs/working/research-2026-11-19-a8-cache-probe.md:62-65`, `docs/working/research-2026-11-19-a8-cache-probe.md:76-79`, `skills/code-review/SKILL.md:352-354`
**Legibility-target:** for-author

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 20** (`skills/code-review/references/rubric.md:201-204`): Split is the better fit, but Acknowledged means "stands with a qualifying note" and was also valid (the research doc says so). Deferred can carry an Author-note Reason instead of a log row. The unmoved benefit-half remedy (SKILL text) has no tracked follow-up in the cell.

### Unverifiable
(none)

## Goal-Alignment Note

The goal was to confirm the docs-only branch is accurate before it merges. All six submitted endorsements hold, five fully and one with tightened glosses. The executed parser runs confirm the mechanical part: rows A3, A6 and A7 are fixed at f87a1455 and A8 reads as closed. One residue recurs across Claims 16 and 20 and is worth the orchestrator's synthesis. The branch closes A8 while `skills/code-review/SKILL.md:274-277` and `:352-354` still assert the cache saving the probe refuted, and no Q-ID or roadmap item in the rubric cell tracks that correction. The research doc leaves it "for the cycle to file". That is outside these claims' wording, but a reader taking the closed row as "A8 handled" would miss it. Claim 17's A8 `closed` reading also rests on the presence of a Q-ID keyword, with Q-308 still OPEN.
