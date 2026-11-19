Commit: 3ab2183a

# Performance Review — measure/a8-cache-probe (loop pass 3, delta 89eb9b65..b3fb2349)

**Scope:** `git diff 89eb9b65..b3fb2349 -- docs/reviews/code-review-rubric-2026-08-07-main.md runs/ docs/working/research-2026-11-19-a8-cache-probe.md` (3 files, 14+/11-). Partial scope (loop pass, delta range); the rest of `git log main..HEAD` is context only. The three files are identical at b3fb2349 and HEAD 3ab2183a.
**Date:** 2026-11-19
**Based on:** `docs/reviews/code-fact-check-report-2026-11-19-measure-a8-cache-probe-pass3.md` (18 claims: 15 Verified, 3 Mostly accurate); measurement records `runs/review-arms/a8-2026-11-19/cache-probe.md`, `results.md`; skill text `skills/code-review/SKILL.md:268-358`.

## Data Flow and Hot Paths

The diff is prose only. No code path changes. The "path" whose cost these docs describe is the code-review pipeline's prompt assembly. Each pass fans the inlined shared block out to about 8 agents (`SKILL.md:274`), and a fix loop repeats that per pass. That makes it a warm path for token spend, though not a request path. The measured per-agent figures, from `cache-probe.md:26-34`: `cache_read_input_tokens` 18,900 (system prompt and tools only), `cache_creation_input_tokens` 31,731, input/output 2/52. Notified total 50,685 per agent. I checked the arithmetic with python3: 18,900 + 31,731 + 2 + 52 = 50,685, and 2 × 50,685 = 101,370, which matches the probe-cost line at `:98`. The "~50.6k (18,900 + 31,731)" whole-request-cache figure (`cache-probe.md:79`, research `:72`) is 50,631, so it is correct as rounded.

Measured vs. inferred, claim by claim in the changed text:
- A8 cell, "a second agent 28.5 s later, same block byte for byte, still read only 18,900 tokens": measured (`cache-probe.md:28-31`). The 28.5 s runs from A's reply, as the probe doc words it at `:28`. The cell's "later" is consistent with that.
- A8 cell, "no prompt order puts a breakpoint at the block's end": structural, read from the request records (breakpoint paths observed at `system[0]`, `system[1]` and the last block, `cache-probe.md:30`, `:44-52`). It is corroborated by B's unchanged read. The whole-block matching rule it also leans on is flagged unverified at the source (`cache-probe.md:58-61`). The cell does not repeat that caveat. It says "the probe ... shows it is structural", which the measured B-read supports, so this is acceptable.
- A8 cell, "by the same mechanism (inferred, not measured), A7's cross-pass claim": correctly labelled. This matches `cache-probe.md:88-95` ("The probe did not test reuse across loop passes ... That is inferred from the records, not measured.").
- Probe cost and ledger paragraph (`cache-probe.md:98-102`): the 101,370 figure is correct. The new omission reason matches the brief's acceptance item 4 (`docs/working/briefs/2026-11-19-a8-cache-probe.md:21`). The consequence is that `token-ledger.md` and `manifest.json` under-count this directory's spend by 101,370 tokens. The paragraph states this, and it no longer claims backing from the review canon (fact-check Claim 17). I am not filing it as a finding.

## Findings

#### The correction the Split routes lists three skill ranges, and the skill makes the same cross-agent / cross-pass saving claim in at least one more place

**Severity:** Low
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35` (A8 Status cell). Unlisted text: `skills/code-review/SKILL.md:307-310`, and the premise at `:322-323`
**Move:** Find the work that moved to the wrong place / Question the cache (hit rate)
**Classification:** Macro (a structural saving that does not occur, repeated in every pass) / Cold for this diff (prose; the cost lands in the review pipeline, not in this change)
**Confidence:** High
**Baseline:** `cache_read_input_tokens` 18,900 for the second probe agent, the same as the first (`runs/review-arms/a8-2026-11-19/cache-probe.md:31`)
**Legibility-target:** for-cycle (the `handoff: ready` marker body and whoever files the correction)

Evidence (cell, verbatim): "correcting the skill text this row cites (`SKILL.md:352-354`), its premise (`:274-277`) and, by the same mechanism (inferred, not measured), A7's cross-pass claim (`:347-351`) to the follow-up the `handoff: ready` marker of branch `measure/a8-cache-probe` asks the cycle to file". Unlisted skill text, verbatim at HEAD: `SKILL.md:307-310` "This is the bulk of the shared prefix; inlining it once and caching it / across the fan-out is where the saving comes from. It sits second-to-last because a fix / commit mutates it: parts 1–4 are stable across the whole loop, so ordering them first keeps / them a cache-warm common prefix across fix→re-review cycles." (This is a bullet in the part-5 list. The excerpt starts mid-bullet at :307; the bullet begins at :305 with "**The unified diff itself**".) Also `:322-323` "Inlining trades context-window / budget for cache reuse". The cell's three ranges are exactly the spans in known item 1, so the marker will probably copy them. A correction scoped to those ranges would leave `:307-310` still stating both the cross-agent saving (measured absent) and the cross-pass warmth (inferred absent). It would also leave the size guard's rationale (`:322-323`) pricing a reuse that the probe found does not happen. That last part affects how the 25k budget is justified, and Q-308's net-cost question already touches it. The cell is accurate as written, because it scopes itself to "the skill text this row cites". The gap is the scope of the routed follow-up, not a wrong claim.

**Recommendation:** In the marker line (or the cell), word the follow-up as "correct the Inline shared-context prefix section's cache-saving claims (at least `:274-277`, `:307-310`, `:347-351`, `:352-354`; `:322-323`'s rationale pending Q-308)". Whoever files the correction then audits the whole section, not three ranges.

#### Research doc's "Follow-up for the cycle" still states A7's cross-pass loss as a probe result

**Severity:** Low
**Location:** `docs/working/research-2026-11-19-a8-cache-probe.md:77-80` (unchanged text in an in-scope file)
**Move:** Question the cache (hit rate: measured vs. inferred)
**Classification:** Micro (wording in one doc) / Cold
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative (no cross-pass measurement exists; `cache-probe.md:88-89` "The probe did not test reuse across loop passes")
**Legibility-target:** for-author

Evidence (whole paragraph, verbatim): "The skill still says the cache "serve[s] the shared block to all ~8 agents" and "Leave it on because it is free" (`SKILL.md:274-277`, `:352-354`), and its stable-parts-first rule claims cross-pass warmth (`:347-351`, rubric row A7); the probe shows that saving does not occur on the Agent-tool path. Correcting that text is a pipeline change the brief puts out of scope, so it is for the cycle to file." The delta labelled the A7 implication "(inferred, not measured)" in the A8 cell but not here. This paragraph is the doc's own hand-off section, so the marker author is the most likely to draw on it. If they do, the cross-pass claim travels as measured. This is the same item as fact-check Claim 16 and pass-2 C11, which is still 🟢 Open. I raise it independently from the performance side because it is a measured-vs-inferred label on a cost claim.

**Recommendation:** After "(`:347-351`, rubric row A7)", add "(inferred from the same mechanism, not measured)", or split the sentence so that "the probe shows" covers only `:274-277` and `:352-354`.

#### Same row cites the same text under two line ranges with no bridge

**Severity:** Informational
**Location:** `docs/reviews/code-review-rubric-2026-08-07-main.md:35` (Finding column vs. Status cell)
**Move:** Question the cache (legibility of the claim under test)
**Classification:** Micro / Cold
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative
**Legibility-target:** for-author

Evidence: Finding column "`"Leave it on because it is free" / "0% of token count" (`SKILL.md:276-278`)`". Status cell "the skill text this row cites (`SKILL.md:352-354`)". Both are correct. `:276-278` is the range at 2f5ad0b, and the same three lines sit at `:352-354` at HEAD (fact-check Claim 3). But a reader of this one row sees "the text this row cites" given as two different ranges, and nothing in the row says which commit each refers to. The cost is only a lookup. It does not affect the performance verdict.

**Recommendation:** Optionally write "(`SKILL.md:352-354` at HEAD; `:276-278` at 2f5ad0b)".

## Endorsements

- The A8 cell separates what was measured (B's 18,900-token read 28.5 s after A's reply, block byte-identical) from what was inferred (A7's cross-pass loss, labelled "(inferred, not measured)"), and both match `cache-probe.md:26-36` and `:88-95`. `[unverified — submitted as claim]`
- The probe-cost figure "2 × 50,685 = 101,370" (`cache-probe.md:98`) is arithmetically correct, and 50,685 equals read + creation + input + output (18,900 + 31,731 + 2 + 52). The per-agent table therefore fully accounts for the notified total. `[unverified — submitted as claim]`
- The new ledger-omission reason in `cache-probe.md:100-101` restates the brief's acceptance item 4 file list faithfully, and the paragraph still discloses the 101,370-token gap in the ledger. `[unverified — submitted as claim]`
- The A8 cell names enough to find the routed follow-up: the branch `measure/a8-cache-probe` and its `handoff: ready` marker. Whether the cycle acts on it depends on the marker's wording (fact-check Claim 2, Escalate 1). `[unverified — submitted as claim]`

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Routed correction lists three ranges; `:307-310` (and the `:322-323` rationale) make the same saving claim | Low | `docs/reviews/code-review-rubric-2026-08-07-main.md:35`; `skills/code-review/SKILL.md:307-310`, `:322-323` | High |
| 2 | Research "Follow-up for the cycle" states A7 cross-pass loss as a probe result | Low | `docs/working/research-2026-11-19-a8-cache-probe.md:77-80` | High |
| 3 | Same row cites the same text as `:276-278` and `:352-354` with no commit bridge | Informational | `docs/reviews/code-review-rubric-2026-08-07-main.md:35` | High |

## Overall Assessment

The performance claims in the changed text are accurate. The measured figures (18,900 / 31,731 / 50,685 / 101,370 / 28.5 s) match the probe record, and the arithmetic holds. The delta's new label, "(inferred, not measured)" on A7's cross-pass claim, is correct and matches the probe doc. Nothing in the delta overstates a measurement. Two residuals are about where the verdict travels next. First, the research doc's hand-off paragraph still presents the cross-pass loss as measured. Second, the follow-up's three line ranges miss at least one more place in the skill that claims the same saving (`:307-310`). Both can be fixed in place with a clause each, before or in the marker body, and neither needs new measurement. A cross-pass measurement would settle the inferred half, but Q-308 or later work owns that, not this branch.

## Goal-Alignment Note

- Success criterion (restated verbatim): a critique saved to /workspace/.claude/wt-2026-11-19-a8-cache-probe/docs/reviews/performance-review-2026-11-19-measure-a8-cache-probe-pass3.md (first line `Commit: 3ab2183a`), structured per the performance-reviewer skill.
- Answered: yes. Every performance claim in the three changed hunks was checked against `cache-probe.md`, `results.md` and `SKILL.md:268-358`. Measured/inferred labels are correct in the A8 cell and the probe doc. One unlabelled inference remains, in unchanged research text (Finding 2). There are no Incorrect claims.
- Out of scope: context only, not verdicted. These are the pre-existing, unchanged parts of `cache-probe.md` and the A8 cell (the probe method, the "Why" section, and the unverified web-source wording at `cache-probe.md:58-61`), plus the branch rubric's bookkeeping. I did not count the ledger under-count (101,370 tokens absent from `token-ledger.md`/`manifest.json`) as a finding, because the paragraph states it and the brief's file list explains it.
- Escalate: Finding 1 matters for the `handoff: ready` marker the author writes next (known item 1). If the marker copies the cell's three ranges, the filed correction will be too narrow. Asked: does the A8 cell's wording identify the marker? Yes. It names the branch and the `handoff: ready` marker. Whether the cycle files it still depends on the marker's wording (fact-check Escalate 1).
- Decisions I made: I filed Finding 2 although its text is unchanged, because the scope includes the file and the fact-check report flags it as open (Claim 16, C11). I tagged every endorsement `[unverified — submitted as claim]` per the loop-pass instruction, even where a fact-check claim verifies it. I graded Finding 1 Low, not Medium, because the cell is accurate as scoped and the extra range is a completeness gap in a follow-up that has not yet been filed.
