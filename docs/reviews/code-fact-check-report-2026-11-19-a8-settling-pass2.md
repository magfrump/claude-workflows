Commit: 791ca9d7
**Replication:** k=1 (loop pass, decision 031)

# Code Fact-Check Report

**Repository:** /workspace/.worktrees/wt-2026-11-19-a8-settling-runs (branch measure/a8-settling-runs)
**Scope:** `git diff 1431b628..HEAD` (fix commit 791ca9d7 only): the research doc, results.md, token-ledger.md, the corpus rubric, and the two merged fact-check reports. Unchanged text in those files was checked for consistency with the fix.
**Checked:** 2026-11-19
**Total claims checked:** 23
**Summary:** 17 verified, 4 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Hallucination log (`docs/reviews/hallucination-patterns.md`, 8 entries) read. No claim here matches a logged pattern, and no fabrication was found, so the log needs no new entry. The repo is read-only for this pass in any case.

Paths below are relative to the repo root. `R1` is the prior pass's r1 report and its transcript log, at `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review1/r1/`. Executed claims ran from `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review2/` at 2026-11-20T02:31:24Z. Their output is in `git-precondition.log` and `calc.log` in that directory, and every command exited 0.

---

## Claim 1: "The brief asks me to check that `git log -1 --format=%H -- skills/code-review/SKILL.md` on the base commit is the merge made under Q-315 … and to end blocked if it is not."

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:17-19`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the doc restates the brief's check and its stop condition. It does not establish that proceeding was correct (Claim 3).
**Legibility-target:** for-owner

The brief says: "check that `git log -1 --format=%H -- skills/code-review/SKILL.md` on your base commit is that merge, and if it is not, end with a blocked marker saying so" (`docs/working/briefs/2026-11-19-a8-settling-runs.md:14`). This resolves the prior r2 Claim 2 finding, which said the doc had turned a literal check into a content check.

**Evidence:** `docs/working/briefs/2026-11-19-a8-settling-runs.md:14`

---

## Claim 2: "`git log -1 -- skills/code-review/SKILL.md` at 14d450d9 prints ca328816 … the literal command cannot print the merge hash (`--first-parent` would)."

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:20-24`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what both commands print at 14d450d9. It does not establish git's path-simplification rule in general, only its result here.

Running the commands shows `git log -1 --format=%h 14d450d9 -- skills/code-review/SKILL.md` → `ca328816`, and the same command with `--first-parent` → `d383a484`. `d383a484` is "Merge branch 'fix/code-review-lever3-correction'" with parents `acbff6c6 e100fc0d`.

Provenance: commands as quoted, cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review2` (repo addressed with `git -C`), exit 0 for both, 2026-11-20T02:31:24Z.

**Evidence:** `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review2/git-precondition.log`

---

## Claim 3: "That reads the brief's stop condition by its purpose, not its letter, so the ready marker asks the owner to confirm it."

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:25-27`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers whether the claimed owner ask can be found on the branch. It does not establish what the marker will say.

No ready marker exists on the branch yet (paraphrased — no quote available because the claim covers absence: there is no marker file under the repo, and none of the branch's run files mention a "ready marker"). The ask is a forward reference to the build loop's handoff note, so checking it needs that note. The admission that the doc reads the stop condition "by its purpose, not its letter" is now explicit, which answers prior r2 Claim 2.

**Evidence:** `docs/working/research-2026-11-19-a8-settling-runs.md:24-27`

---

## Claim 4: "the difference is the Read calls (one for a Stage-1 agent; two for each Stage-2 critic, whose first Read stopped at line 1068), the Read tool's line numbers (about 1.4k tokens)"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:84-88`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the corpus agents' first-step Reads as the prior pass's transcript extract records them. It does not establish anything about the transcripts beyond that extract.

The transcript extract shows each critic's two Reads, `shared-block-stage2.md"}` then `shared-block-stage2.md", "offset": 1069}`. It also shows the first result ending `…|1069	new file mode 100644` (R1 `logs/transcripts.log:54-55`). The in-context sizes are 62,753 chars against a 57,328-byte Stage 1 file and 67,537 against a 61,902-byte Stage 2 file. That is about 5.5k chars, roughly 1.4k tokens at chars/4. Prior r1 Claims 5 and 26 are resolved.

**Evidence:** R1 `logs/transcripts.log:54-78`; `review1/r1/code-fact-check-report.md:100-102`

---

## Claim 5: "this merge keeps one row per assertion, so its count is lower than the largest replicate's. Five single-replicate Verified assertions have no row here (r1 Claims 14, 22, 23; r2 Claims 21, 23); every non-Verified verdict has one."

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:13`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the exception list and the non-Verified coverage, checked against every replicate verdict line. It does not establish that the clustering of the remaining Verified assertions into rows is right.

The exception list is right. r1 Claims 14 ("We only ever write Uint8Array"), 22 (CorpusError twin) and 23 ("'Not found' is `null`…"), and r2 Claims 21 ("Selected once…") and 23 ("Verifies the OFF default is unchanged…"), are all `**Verdict:** Verified`, and none of the merged rows' `Replicate verdicts` lines map to them. Every non-Verified replicate verdict maps to a row: r2 Claim 30 goes to Claim 25 and r2 Claim 31 to Claim 1 (paraphrased — no quote available because the check spans 90 verdict lines across three replicate reports).

The imprecision is in the sentence itself. It still asserts "keeps one row per assertion" without qualification, and the very next sentence names five assertions with no row. The fix dropped "distinct" but left the universal in place. A precise version would say: "keeps one row per assertion that a non-Verified verdict or two or more replicates reached; five single-replicate Verified assertions have no row…". One related detail: r1 has two claims for the seam assertion, Claim 16 Verified and Claim 21 Mostly accurate. Merged Claim 11 records `r1=Mostly accurate` and does not mention r1 Claim 16. That is most-severe-wins inside one replicate, not a missing row. Prior r1 Claim 9 and r2 Claim 8 are substantively resolved.

**Evidence:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:13`, `corpus/code-fact-check-report-r1.md` and `-r2.md` verdict lines, merged `Replicate verdicts` lines (Claims 1-25)

---

## Claim 6: "**Replicate verdicts:** r1=Verified (r1 Claim 6c) · r2=Mostly accurate · r3=—"

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:188`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the replicate attribution of merged Claim 12. It does not re-adjudicate the assertion.

r1 Claim 6c is `"enabling this starts from an EMPTY corpus and does not carry existing localStorage work over"`, `**Verdict:** Verified`. r2 Claim 6, the same text, is `Mostly accurate`, and r3 has no matching claim. The row's verdict stays Mostly Accurate under most-severe-wins, so the header Summary (`7 verified, 6 mostly accurate, 2 stale, 6 incorrect, 4 unverifiable`, `:9`) still matches the 25 row verdicts. Prior r1 Claim 10, r2 Claim 9 and r3 Claim 28 are resolved.

**Evidence:** `corpus/code-fact-check-report-r1.md` (Claim 6c), `corpus/code-fact-check-report-r2.md` (Claim 6), `corpus/code-fact-check-report.md:9,188`

---

## Claim 7: "All reporting replicates agreed: 21. Disagreed: 4 — Claim 4 …, 9 …, 12 (V/MA/—), 22 …. Single-replicate detections: Claims 13, 14, 25 (all r2). Agreement rate: 21/25 = 84%."

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:694-695`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the tally against the 25 merged `Replicate verdicts` lines. It does not establish that the clustering behind them is right.

The only rows whose reporting replicates differ are 4 (`r1=Incorrect (compound with Claim 3) · r2=Mostly accurate · r3=Mostly accurate`), 9 (`MA · V · MA`), 12 (`V · MA · —`) and 22 (`U · U · V`). Rows 13, 14 and 25 are the only `single-replicate detection` rows, all r2. 25 − 4 = 21, and 21/25 = 0.84. Prior r2 Claim 10 and r3 Claim 28 are resolved.

**Evidence:** `corpus/code-fact-check-report.md` `Replicate verdicts` lines, Claims 1-25

---

## Claim 8: A2 source "fact-check Claim 3 (executed 3/3), Claim 4 (I/MA/MA)"

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-review-rubric-2026-11-19-corpus.md:18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the citation against the merged report's rows 3 and 4. It does not establish the rubric's tiering.

Merged Claim 3 is `r1=Incorrect · r2=Incorrect · r3=Incorrect`, and prior r1 Claim 27 confirmed that it is executed 3/3. Merged Claim 4 is `r1=Incorrect (compound with Claim 3) · r2=Mostly accurate · r3=Mostly accurate`. Prior r2 Claim 12 is resolved here and in results.md:109 (Claim 17).

**Evidence:** `corpus/code-fact-check-report.md` Claims 3-4; `corpus/code-review-rubric-2026-11-19-corpus.md:18`

---

## Claim 9: "the diff and the two files (4,179 bytes in Stage 1, 3,535 in Stage 2, about 1.0k and 0.9k tokens) left the prompt, as designed; the preamble, intent and Stage-2 fact-check summary stay inline in both arms"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:42-45`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte arithmetic on the first-pass and self-read csp shared blocks. It does not establish the per-call cache-write figures (31.2k-32.6k vs 32.8k-33.8k), which need transcripts.

The two numbers are the net shrinkage of the shared block: `net S1 4179 net S2 3535`. They are not the size of "the diff and the two files". In both stages that material is about 5.0k bytes (`inline diff+files S1 5012 S2 5013`), and an 837-byte self-read section replaced it (`self-read section 837`). Stage 2 nets less because the self-read pass's fact-check summary is 645 bytes longer than the first pass's (`summary old/new 2960 3605`: 24 claims against 18). So the "fact-check summary stays inline in both arms", but it is not the same summary. A precise version: "the diff and the two files (about 5.0k bytes, 1.25k tokens) left the prompt, replaced by an 837-byte read instruction; the block shrank by 4,179 bytes in Stage 1 and 3,535 in Stage 2, where this pass's fact-check summary is 645 bytes longer". The fix still corrects the prior figure: prior r3 Claim 6's "~2.2k-2.9k" was the whole inline block. That finding is resolved in direction, with this residual imprecision.

Provenance: `timeout 60 python3 -I calc.py /workspace/.worktrees/wt-2026-11-19-a8-settling-runs`, cwd `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review2`, exit 0, 2026-11-20T02:31:24Z.

**Evidence:** `runs/review-arms/a8-2026-11-19/csp/shared-block.md:37-142`, `runs/review-arms/a8-2026-11-19/csp/shared-block-stage2.md:193`, `runs/review-arms/a8-2026-11-20/csp/shared-block.md:37-44`, `runs/review-arms/a8-2026-11-20/csp/shared-block-stage2.md:46`; `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review2/calc.log`

---

## Claim 10: "Self-read agents spend tool calls fetching the diff and the two files, so the same bytes reach their context as tool results."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:46-47`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers consistency with the fix's own corpus wording. It does not establish, from csp transcripts, which tool each csp agent used for the two files.

This line is unchanged, but the fix now contradicts it. For corpus, the fix replaced "the same bytes" with "the same content", because the Read tool's output is line-numbered (`results.md:91`, `:96-99`; research doc `:84-86`). The csp self-read block tells agents to read `proxy.ts` and `app/layout.tsx` "in full" (`csp/shared-block.md:42`). Read on those files returns line-numbered text, the same mechanism the fix records for corpus (paraphrased — no quote available because csp transcripts were not in the prior pass's extract, so the per-agent tool choice is inferred). Only the `git diff` output through Bash arrives byte-identical. Precise version: "the same content reaches their context as tool results (line-numbered where read with Read)".

**Evidence:** `runs/review-arms/a8-2026-11-20/results.md:46-47,91,96-99`; `runs/review-arms/a8-2026-11-20/csp/shared-block.md:39-42`

---

## Claim 11: "Stage 2.5 executed 5 of its 8 entries in 4 probe runs (Claims 28 and 29 on `next dev`)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:59-60`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the verification-mode fields and the logs directory of csp Stage 2.5. It does not re-run the probes.

`**Verification mode:** executed` appears on Claims 25, 27b, 28, 29 and 31, and static on 26, 27a and 30, so 5 of 8. There are four runs (`s1-nonce-probe.log`, `s3-cost-bench.log`, `s4-next-dev-server.log` with `s4-prefetch-curl.log`, `s7-directive-diff.log`). Claim 29 says "Executed: same run as Claim 28", and its scope says "the observed fact that `next dev` loads and runs the file". Prior r1 Claim 21 and r2 Claim 20 are resolved.

**Evidence:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-submitted-claims.md` (Claims 25-31); `csp/stage25-logs/`

---

## Claim 12: the skill's calibration note "counts diff + fact-check report, not diff + enclosing files"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:73`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the source of the 17.4k figure. It does not establish the figure itself.

The baseline measurement's heading is "Potential #3 saving IF the shared diff + fact-check report are inlined + cached", with the column `diff+factcheck chars` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:33,36`). Prior r1 Claim 23 is resolved.

**Evidence:** `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:33-36`; `skills/code-review/SKILL.md:343-345`

---

## Claim 13: "135,849 tokens over the 9 core agents, ≈12.0% of the core (≈13.1% as delivered …). Each critic grew 19.9k-44.1k over August, so the block is at most 35% to 78% of each critic's growth."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:89-92`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic from the table at `:79-85` and the Read-output sizes in the transcript extract. It does not establish the "at most" bound's interpretation.

The script prints `growth [28194, 22004, 44114, 32027, 30293, 19931]` and `share [0.549, 0.703, 0.351, 0.483, 0.511, 0.776]`, which gives 35%-78%. It also prints `block share 0.1198… as delivered 0.1309…`. Prior r1 Claim 25, r2 Claim 23 and r3 Claim 15 are resolved.

Provenance: as Claim 9 (same `calc.py` run, exit 0, 2026-11-20T02:31:24Z).

**Evidence:** `runs/review-arms/a8-2026-11-20/results.md:79-85`; `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review2/calc.log`

---

## Claim 14: "plus the Read calls (two for each Stage-2 critic, whose first Read stopped at line 1068) and the Read tool's line numbers, about 1.4k tokens per agent"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:96-99`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Same evidence as Claim 4. It covers the corpus agents only.

See Claim 4. The two locations now agree.

**Evidence:** R1 `logs/transcripts.log:54-78`

---

## Claim 15: cor-A1 baseline "miss (no naming finding in the baseline reports; the canon ledger's E4 column calls it enumeration class)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:106`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers a grep of the baseline corpus reports for the field names and the ledger row. It does not establish that no baseline report raises the issue in other words.

The canon row is `| cor-A1 | … naming inconsistency | ✓(label) | ✗ | ✗ (enumeration class) |` (`docs/working/canon-issue-ledger.md:112`). In `baseline-2026-08-06/corpus/`, `customTypeIds` appears only in test cases and parse mentions (`critic-test-strategy.md:19,58-61`, `critic-performance.md:137`), never as a naming finding. Prior r2 Claim 25, r3 Claim 16 and the r1 Claim 27 scope note are resolved.

**Evidence:** `docs/working/canon-issue-ledger.md:112`; `runs/review-arms/baseline-2026-08-06/corpus/critic-test-strategy.md:19`

---

## Claim 16: cor-A2 baseline "miss on this reading: the baseline architecture critic called `paths.ts` 'the sole producer of corpus paths' (`baseline-2026-08-06/corpus/critic-architecture.md:81`)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:107`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the quote and its line. It does not establish whether another baseline report flagged the `state/` path.

The quoted line reads "**Path safety is well-bounded:** `paths.ts` is the sole producer of corpus paths…" (`runs/review-arms/baseline-2026-08-06/corpus/critic-architecture.md:81`). Prior r2 Claim 25 is resolved.

**Evidence:** `runs/review-arms/baseline-2026-08-06/corpus/critic-architecture.md:81`

---

## Claim 17: cor-A4 today "**HIT**, 🟡 A2 (Claim 3 executed 3/3; Claim 4 I/MA/MA; api F1, F11)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:109`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** As Claim 8.

The citation matches merged Claims 3 and 4 and rubric row A2 (see Claim 8).

**Evidence:** `corpus/code-fact-check-report.md` Claims 3-4; `corpus/code-review-rubric-2026-11-19-corpus.md:18`

---

## Claim 18: "The pass also hit these canon rows: N11 … N23 … D4 … D5 …. The baseline also had N23 (its security Medium), D4 (its fact-check Claim 8) and D5 (its performance report's last-writer-wins race); I did not adjudicate the others against the baseline's reports."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:115-123`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three named baseline sightings. It does not establish today's hits on N11-N24, which the reviewed commits own and this fix did not change.

The baseline evidence for each of the three:
- N23: `#### Slug generation is many-to-one …` with `**Severity:** Medium` (`baseline-2026-08-06/corpus/critic-security.md:27-29`).
- D4: `## Claim 8: "Pass a fresh ArrayBuffer view…"` (`baseline-2026-08-06/corpus/fact-check.md:177`).
- D5: "overlapping `createWritable`/`write`/`close` cycles on the same file with no ordering guarantee (contention / possible last-writer-wins races)" (`baseline-2026-08-06/corpus/critic-performance.md:53-55`).

The wrong "the baseline did not have" wording is gone, so prior r1 Claim 29, r2 Claim 27 and r3 Claim 19 are resolved.

**Evidence:** `runs/review-arms/baseline-2026-08-06/corpus/critic-security.md:27-29`, `fact-check.md:177`, `critic-performance.md:53-55`; `docs/working/canon-issue-ledger.md:162-163`

---

## Claim 19: "On corpus the ladder applied as written."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:134`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claim that the mode follows the ladder from the measured size. It does not establish that the budget is well set, which `:136-139` says remains untested.

`results.md:66-68` records 123,423 bytes, "≈30.9k tokens at bytes/4, over the 25k budget", so the ladder "degrades to **inline-diff-only**". This is a description of the ladder, not a claim about benefit, which resolves prior r1 Claim 32.

**Evidence:** `runs/review-arms/a8-2026-11-20/results.md:66-75,134-139`

---

## Claim 20: "the merge keeps one row per assertion (csp 24, corpus 25, plus Stage 2.5's 8 and 7 entries). On corpus, five single-replicate Verified assertions have no row …; every non-Verified verdict has one."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:149-152`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts and the corpus exception list. It does not establish csp's row coverage beyond prior r2 Claim 26a, which found it holds.

The counts are right. The csp submitted-claims file has 8 claim headings (25, 26, 27a, 27b, 28-31), and corpus has 7 (26-32). The replicate counts are r1 33, r2 35 and r3 22 verdict sections. The 8/7 order is now correct, which resolves prior r1 Claim 35, r2 Claim 26b and r3 Claim 23. The remaining imprecision is the one in Claim 5: an unqualified "keeps one row per assertion" sits next to the five exceptions it names. Prior r2 Claim 26a is resolved in substance.

**Evidence:** `csp/code-fact-check-submitted-claims.md`, `corpus/code-fact-check-submitted-claims.md` (`## Claim` headings); `corpus/code-fact-check-report-r{1,2,3}.md` verdict lines

---

## Claim 21: r3 row "5V/2MA/0S/6I/2U per its header (15 claims; its body verdicts 17 sections, 6V/2MA/7I/2U …)"

**Location:** `runs/review-arms/a8-2026-11-20/token-ledger.md:14`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers csp r3's header and its body verdict counts.

In csp r3, the header reads `**Total claims checked:** 15` and `**Summary:** 5 verified, 2 mostly accurate, 0 stale, 6 incorrect, 2 unverifiable` (`csp/code-fact-check-report-r3.md:8-9`). The body has 17 `**Verdict:**` lines: 6 Verified, 2 Mostly accurate, 7 Incorrect, 2 Unverifiable. Prior r1 Claim 37 is resolved.

**Evidence:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-report-r3.md:8-9`

---

## Claim 22: "8 entries (S3 split): 6V / 1MA / 1I; 5 executed (3 of the 6 V, plus 27b and 31)"

**Location:** `runs/review-arms/a8-2026-11-20/token-ledger.md:24`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the csp Stage 2.5 verdict and mode fields.

The verdicts are Verified for 25, 26, 27a, 28, 29 and 30, Incorrect for 27b and Mostly accurate for 31. The executed entries are 25, 27b, 28, 29 and 31, so 3 of the 6 Verified entries were executed. Prior r1 Claim 38 and r2 Claim 29 are resolved.

**Evidence:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-submitted-claims.md` (Claims 25-31)

---

## Claim 23: commit 791ca9d7 body "k=3 fact-check over the write-up (620,695 tokens): all arithmetic recomputed"

**Location:** `791ca9d7` (commit message)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers only whether the token figure is recorded anywhere on the branch. The list of fixes in the same body is verified by Claims 1-22.

The review pass's token figure is not in any branch file (paraphrased — no quote available because the claim covers absence: the token ledger records the measured agents, not the review agents). Checking it needs the three review notifications.

**Evidence:** `git show 791ca9d7`

---

## Prior findings, status

| Prior finding (pass 1) | Status |
|---|---|
| N23/D4/D5 "baseline did not have" (r1 29, r2 27, r3 19) | Resolved (Claim 18) |
| "6V (4 executed)" (r1 38, r2 29) | Resolved (Claim 22) |
| one tool call / few hundred tokens / same bytes, corpus (r1 5, 26) | Resolved (Claims 4, 14). The same wording survives for csp at results.md:47 (Claim 10). |
| "one row per distinct assertion" (r1 9, r2 8, r2 26a, r3 23) | Resolved in substance: exceptions named. The wording still holds the universal (Claims 5, 20). |
| Claim 12 r1=— (r1 10, r2 9, r3 28) | Resolved (Claim 6) |
| Stability tally 22/25 (r2 10, r3 28) | Resolved (Claim 7) |
| Stage 2.5 "ran 4 claims" (r1 21, r2 20) | Resolved (Claim 11) |
| 17.4k "summary" vs report (r1 23) | Resolved (Claim 12) |
| "a third to three quarters" / 12.0% (r1 25, r2 23, r3 15) | Resolved (Claim 13) |
| "the 25k budget did its job" (r1 32) | Resolved (Claim 19) |
| Stage 2.5 "7 and 8" swapped (r1 35, r2 26b, r3 23) | Resolved (Claim 20) |
| r3 ledger header vs body (r1 37) | Resolved (Claim 21) |
| Precondition restated as content check (r2 2) | Resolved (Claims 1-3). The marker ask is still forward-looking. |
| "Claims 3, 4 (executed 3/3)" (r2 12) | Resolved (Claims 8, 17) |
| cor-A1/cor-A2 baseline column (r2 25, r3 16) | Resolved (Claims 15, 16) |
| Prompt size "~2.2k-2.9k left" (r3 6) | Resolved in direction. The new figures are net block shrinkage, not diff+files size (Claim 9). |
| csp attention section incomplete (r3 26); corpus attention "None" (r3 29) | Resolved by removing both sections. The wrong lists are gone. The merged reports no longer have the `## Claims Requiring Attention` section that the code-fact-check output format calls for. The critics' prompts already carried the non-Verified summary (`*/shared-block-stage2.md:46` csp, `:1327` corpus), so no record of what the critics saw is lost. |
| Unverifiable: refused dispatches (r1 6), transcript usage (r3 3, 5) | Unchanged. The fix did not touch these. |

---

## Claims Requiring Attention

### Incorrect
- None.

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:13`): "keeps one row per assertion" is still unqualified, and the next sentence names five assertions with no row. Qualify the universal.
- **Claim 9** (`runs/review-arms/a8-2026-11-20/results.md:42-45`): 4,179 / 3,535 bytes are the net block shrinkage. The diff and files are about 5.0k bytes in both stages, replaced by an 837-byte read instruction, and Stage 2 nets less because this pass's fact-check summary is 645 bytes longer.
- **Claim 10** (`runs/review-arms/a8-2026-11-20/results.md:46-47`): unchanged "the same bytes reach their context" now conflicts with the fix's corpus wording ("same content", line-numbered Read output).
- **Claim 20** (`runs/review-arms/a8-2026-11-20/results.md:149-152`): same unqualified "one row per assertion" as Claim 5. The counts are correct.

### Unverifiable
- **Claim 3** (`docs/working/research-2026-11-19-a8-settling-runs.md:25-27`): needs the ready marker, which is not written yet.
- **Claim 23** (`791ca9d7` message): the review pass's 620,695 tokens need the review agents' notifications.

---

## Goal-Alignment Note

- **Success criterion:** "A k=1 code-fact-check report on the A8 write-up's fix commit, saved to the path given."
- **Answered:** Yes. 23 claims from the 1431b628..791ca9d7 diff were checked. All 18 prior Incorrect and Mostly accurate finding groups were assessed: every one is resolved, three with a small leftover imprecision (Claims 5/20, 9, 10). Unchanged text in the six touched files was checked for consistency with the fix. The canon ledger and both rubrics have no other text that conflicts.
- **Out of scope:** The agents' own reports (measured data), the claims of the commits before 1431b628 that the fix did not touch, and re-running any Stage 2.5 probe. Whether removing the merged reports' attention sections, rather than completing them, is acceptable under the code-fact-check output format is a format call for the author, not a fact-check verdict.
- **Escalate:** None blocking. For the author: decide between restoring complete `## Claims Requiring Attention` sections in the two merged reports and noting their removal.
