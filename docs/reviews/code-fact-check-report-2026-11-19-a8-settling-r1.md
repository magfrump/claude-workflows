Commit: 1431b628

# Code Fact-Check Report

**Repository:** /workspace/.worktrees/wt-2026-11-19-a8-settling-runs (branch measure/a8-settling-runs)
**Scope:** files the orchestrator wrote since 14d450d9: `runs/review-arms/a8-2026-11-20/results.md`, `docs/working/research-2026-11-19-a8-settling-runs.md`, `runs/review-arms/a8-2026-11-20/token-ledger.md`, `manifest.json`, `csp/code-review-rubric-2026-11-19-csp.md`, `corpus/code-review-rubric-2026-11-19-corpus.md`, `csp/code-fact-check-report.md`, `corpus/code-fact-check-report.md`. The agent reports beside them were used only as evidence.
**Checked:** 2026-11-20
**Total claims checked:** 40
**Summary:** 27 verified, 10 mostly accurate, 0 stale, 2 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`, 5 entries). Claims 37 and 38 below fall in the logged class "a count cited as read from a source, but the source holds a different number" (e.g. the logged "All 85 tests … pass … but the suites hold 97"). Neither is a symbol fabrication, so nothing new is appended to the log.

Execution logs (all runs under `timeout`; cwd and UTC timestamp at the head of each log; each exited 0 unless noted):
- `logs/calc.log`: `timeout 60 python3 calc.py`, which recomputes every sum, difference and percentage from the ledgers.
- `logs/git.log`: the git precondition and skill-dir checks, run in `/workspace`.
- `logs/sizes.log`: corpus diff bytes, the part-5 reassembly, block sizes.
- `logs/transcripts.log`: `tx.py` / `tr2.py` over the 19 subagent transcripts in `/home/node/.claude/projects/-workspace/42e4626f-…/subagents/`. For each agent they give the last call's tokens, the first call's cache figures, and the size of the block Read results.
- `logs/worktrees.log`: `git worktree list` of the benchmark repo.

All log paths are relative to `/tmp/claude-1000/-workspace/42e4626f-a408-4056-99e9-68895fd49c97/scratchpad/2026-11-19-a8-settling-runs/review1/r1/`.

---

## Claim 1: "`git log -1 -- skills/code-review/SKILL.md` at 14d450d9 prints ca328816 … it is not in the first parent of d383a484 … the merge changes SKILL.md (+68/-53), and nothing under `skills/code-review/` changed between d383a484 and 14d450d9 … the skill at base is the one that merge brought in"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:17-23`
**Type:** Reference / Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every git fact in the paragraph and its conclusion, that the SKILL.md at base is the one d383a484 brought in. It does not establish that proceeding was allowed: the brief says to end blocked if the literal check is not the merge (see the Goal-Alignment Note).
**Legibility-target:** for-orchestrator-synthesis

The log shows `ca328816 docs(code-review): round 3 nit; mark the lever #3 correction brief done`, then `ca328816 in d383a484^1: exit=1`, `in ^2: exit=0`, ` 1 file changed, 68 insertions(+), 53 deletions(-)`, an empty `d383..14d4 skills/code-review:` diff, and `treesame-2nd exit=0` (`logs/git.log`). The TREESAME explanation is also right. In git's default history simplification, a merge that is TREESAME to one parent is pruned and that parent is followed (paraphrased — no quote available because this is git's documented behaviour, not repo code).

**Evidence:** `logs/git.log`; `docs/working/research-2026-11-19-a8-settling-runs.md:17-23`

---

## Claim 2: First-pass and baseline figures in "What I know"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:27-36`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the first pass's core 743,755, fc 311,975 = 100,755 / 90,196 / 121,024, critics 431,780, Stage 2.5 108,530, all 852,285 and blocks of 8,755 / 11,716 B, and the baseline's six critic figures and the 615,566 core. It does not establish the canon-label row ranges, which Claims 20 and 27 cover.
**Legibility-target:** for-orchestrator-synthesis

The first pass gives `| — | **Core total** (Stage 1 + Stage 2) | 8 agents | | **743,755** |` (`runs/review-arms/a8-2026-11-19/token-ledger.md:21`) and `"shared_block_stage2_bytes": 11716` (`runs/review-arms/a8-2026-11-19/manifest.json:41`). `wc -c` gives 8755 and 11716 for the first pass's `csp/shared-block*.md`. The baseline gives `| corpus | 93,966 |` (`baseline-2026-08-06/token-ledger.md:15`). The critic rows are at `:67,71,73,75,76,78`, and 93,966 + 521,600 = 615,566 (`logs/calc.log`).

**Evidence:** `runs/review-arms/a8-2026-11-19/token-ledger.md:10-22`, `runs/review-arms/baseline-2026-08-06/token-ledger.md:15,67-78`

---

## Claim 3: "Critic and fact-check skill files are unchanged between the first pass's base (4330e303) and 14d450d9 (`git diff --stat` over the seven skill dirs and `patterns/orchestrated-review.md` is empty)"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:37-39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers code-fact-check, security, performance, api-consistency, architecture, test-strategy, tech-debt-triage and the pattern doc. It does not establish that the dispatched prompts outside the skill files were identical (Claim 15 residue).
**Legibility-target:** for-orchestrator-synthesis

`4330e303..14d450d9 critic dirs:` is followed by no stat lines (`logs/git.log`).

**Evidence:** `logs/git.log`

---

## Claim 4: "part 5 (diff + the 15 touched files) is 123,423 bytes, about 30.9k tokens, over the 25k budget, so the block is preamble + scope label + intent + the 53,682-byte diff, 57,328 bytes in all (about 14.3k tokens)"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:73-76`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the diff size, the block size, the over-budget conclusion and the mode the ladder picks. It does not establish the exact 123,423. My plain reassembly (diff + `git show` of the 15 files) is 122,779 bytes / 122,581 chars, about 30.7k tokens. The 644-byte gap is probably per-file headers, and no assembled part-5 file was kept.
**Legibility-target:** for-orchestrator-synthesis

The log shows `53682`, then ` 15 files changed, 1166 insertions(+), 33 deletions(-)`, `122581 122779 …part5-raw.txt` and ` 57328 …corpus/shared-block.md` (`logs/sizes.log`). The skill's rule is `**Budget: 25,000 tokens, estimated as chars/4**` and `**Over budget** → degrade, don't cliff: drop the enclosing-file context and inline the **diff only**` (`skills/code-review/SKILL.md:342,349-350`).

**Evidence:** `logs/sizes.log`, `skills/code-review/SKILL.md:335-353`

---

## Claim 5: "The agent's context holds the same bytes from its first step either way; the difference is one tool call (a few hundred tokens)"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:79-82`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the 10 corpus agents' transcripts show for the first-step Read. It does not establish any effect on findings.
**Legibility-target:** for-author

The mechanism is right: every corpus agent's first tool call is `Read` of `corpus/shared-block.md` or `shared-block-stage2.md` (`logs/transcripts.log`). Two details are wrong.

First, the six Stage 2 critics needed two calls, not one. The first Read stops at line 1068, and each critic re-read with `"offset": 1069`. The first result ends `…|1069	new file mode 100644`.

Second, the context does not hold the same bytes. The Read result carries line-number prefixes: 62,753 chars in context for Stage 1 against a 57,230-char file, and 67,537 against 61,902 bytes for Stage 2. That is about 1.4k extra tokens at chars/4, not "a few hundred". Test-strategy cites "shared-block line numbers" (`corpus/test-strategy-review-2026-11-19.md:50`), which confirms the agents saw the numbered form.

The precise version: "the block reaches context at the first step as line-numbered Read output (about 1.4k tokens more than pasting); the Stage 2 critics needed a second Read for lines 1069 onward."

**Evidence:** `logs/transcripts.log`, `runs/review-arms/a8-2026-11-20/corpus/test-strategy-review-2026-11-19.md:50`

---

## Claim 6: "three of the five calls were refused by a harness working-directory check and were re-sent a minute later"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:85-87` (also `results.md:140-142`)
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing beyond the claim's own statement. Checking it needs the orchestrator's main-session transcript, which I did not read. The consequence the doc draws, that "Self-read agents share no prompt cache", matches every first call reading exactly 18,900 cached tokens (Claim 18).
**Legibility-target:** for-orchestrator-synthesis

The refusals are not recorded in any run artifact on the branch (paraphrased — no quote available because the claim covers absence: grepping for "refused" in `runs/review-arms/a8-2026-11-20/` finds only the results/research prose).

**Evidence:** `runs/review-arms/a8-2026-11-20/results.md:140-142`

---

## Claim 7: "The first A8 pass merged the same way: 4,092 lines by this count, approved by the owner."

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:96-97`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 4,092 non-`docs/` lines of merge 358c2332. It does not establish the owner's approval: the merge subject says only "build-loop approved merge".
**Legibility-target:** for-orchestrator-synthesis

The log shows `358c2332 non-docs lines 4092` (`logs/git.log`), and the merge subject is `Merge branch 'measure/a8-token-measurement' (build-loop approved merge)`.

**Evidence:** `logs/git.log`

---

## Claim 8: "Both scratch worktrees of the benchmark repo were removed … Total 2,171,680 tokens over 19 agents"

**Location:** `docs/working/research-2026-11-19-a8-settling-runs.md:104-106`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the benchmark repo's worktree list and the token total. It does not establish that no agent process is still running.
**Legibility-target:** for-orchestrator-synthesis

`git worktree list` names no `wt-csp` or `wt-corpus` under the session scratchpad; only the baseline's `runs/review-arms/baseline-2026-08-06/wt-*` remain (`logs/worktrees.log`). The sum 898,733 + 1,272,947 = 2,171,680 is in `logs/calc.log`.

**Evidence:** `logs/worktrees.log`, `logs/calc.log`

---

## Claim 9: Merged corpus report: "Total claims checked: 25", "7 verified, 6 mostly accurate, 2 stale, 6 incorrect, 4 unverifiable", "this merge keeps one row per distinct assertion"

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:8-9,13`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header arithmetic against the 25 rows, and whether every replicate assertion has a row. It does not establish anything about the critics' use of the merge.
**Legibility-target:** for-orchestrator-synthesis

The header arithmetic matches the rows: Claims 15-21 are Verified, 9-14 Mostly Accurate, 7-8 Stale, 1-6 Incorrect and 22-25 Unverifiable. "One row per distinct assertion" is not true, though. Five distinct Verified replicate assertions have no row:
- r1 Claim 14, "We only ever write Uint8Array"
- r1 Claim 22, ``"`CorpusError` is the thrown form; `CorpusWorkerError` is its postMessage-serializable twin."`` (`corpus/code-fact-check-report-r1.md`, Claim 22 heading)
- r1 Claim 23, the "'Not found' is `null`…" contract
- r2 Claim 21, "Selected once when the store's persist middleware initializes."
- r2 Claim 23, "Verifies the OFF default is unchanged…"

A grep of the merged report for `Uint8Array`, `twin`, `Selected once` and `never touched` finds none of them above the Stage 2.5 section (paraphrased — no quote available because this claim covers absence of matching rows). No Incorrect, Stale or Mostly-accurate verdict was lost, so the red/amber picture holds. The Verified count understates the distinct assertions, and those rows' Scope residues did not reach part 6.

**Evidence:** `corpus/code-fact-check-report.md:8-13`, `corpus/code-fact-check-report-r1.md` (Claims 14, 22, 23), `corpus/code-fact-check-report-r2.md` (Claims 21, 23)

---

## Claim 10: Merged corpus report verdicts follow most-severe-wins, and its "Replicate verdicts" lines are accurate

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-fact-check-report.md:15-383`
**Type:** Reference / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers all 25 merged verdicts against the replicates' verdict lines, which I extracted mechanically. It does not establish that the per-claim Scope lines were copied faithfully.
**Legibility-target:** for-orchestrator-synthesis

All 25 merged verdicts are the most severe of their replicates. For example, Claim 4 has `r1=Incorrect (compound with Claim 3) · r2=Mostly accurate · r3=Mostly accurate` and is Incorrect. Claim 9 (MA/V/MA) is MA, and Claim 22 (U/U/V) is U.

One replicate line is wrong. Claim 12 reads `**Replicate verdicts:** r1=— · r2=Mostly accurate · r3=— · single-replicate detection` (`corpus/code-fact-check-report.md:188`). But r1 verdicted the same assertion: `## Claim 6c: "enabling this starts from an EMPTY corpus and does not carry existing localStorage work over"` → Verified (`corpus/code-fact-check-report-r1.md:144`). The line should read `r1=Verified · r2=Mostly accurate · r3=—`, so it is not a single-replicate detection. The merged verdict (Mostly Accurate) is unchanged.

**Evidence:** `corpus/code-fact-check-report.md:180-192`, `corpus/code-fact-check-report-r1.md:144`, replicate verdict extraction in my scratch (the awk listing over all three replicate files)

---

## Claim 11: Corpus rubric: "1 red, 9 amber", and each row's Source attributions

**Location:** `runs/review-arms/a8-2026-11-20/corpus/code-review-rubric-2026-11-19-corpus.md:5-44`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row counts and that each cited critic finding, ID or claim exists with the stated severity. It does not establish the tier calls (for example, that A6 is amber, not red).
**Legibility-target:** for-orchestrator-synthesis

Every source the rubric cites exists in the cited report with the stated severity:
- architecture `| 1 | Store bypasses seam … | Structural |` and the `#2`/`#3` Coupling and `#4`-`#6` Minor rows (`corpus/architecture-review-2026-11-19.md` Summary Table)
- security `| 1 | Dev-only flag enforceable in production … | Medium |` and `#2`-`#5` Low (`corpus/security-review-2026-11-19.md` Summary Table)
- api F1-F12 with the stated classes, e.g. `| F10 | Hand-built \`state/\` path outside paths.ts | Minor |`
- TD1-TD7 headings (`corpus/tech-debt-triage-review-2026-11-19.md:11-253`)
- test G1-G15 (`corpus/test-strategy-review-2026-11-19.md:22-56`)
- Stage 2.5 Claims 26, 28, 30, 31 and 32, each with the cited verdict and mode

**Evidence:** the corpus critic reports' Summary Tables; `corpus/code-fact-check-submitted-claims.md:19-274`

---

## Claim 12: Merged csp report: 24 claims, "8 verified, 3 mostly accurate, 0 stale, 10 incorrect, 3 unverifiable", most-severe-wins, replicate lines

**Location:** `runs/review-arms/a8-2026-11-20/csp/code-fact-check-report.md:8-369`
**Type:** Reference / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the header arithmetic, all 24 verdicts against most-severe-wins, and each replicate-verdict cell against the replicate files. It does not establish that every replicate sub-claim has a merged row. I found none missing, but I checked headings, not every sentence.
**Legibility-target:** for-orchestrator-synthesis

Each cell matches its replicate. Examples: Claim 4 `r1=Verified · r2=Verified · r3=Incorrect (compound with Claim 3)`, where r3's `## Claim 10` heading includes "so we don't need to read x-nonce here ourselves" (`csp/code-fact-check-report-r3.md:221`); Claim 19 `r1=Unverifiable · r2=Unverifiable · r3=Incorrect` (r1 14 U, r2 17 U, r3 12 I); Claim 16 `r3=Verified (compound)`, where r3's Claim 1 Scope covers "middleware.ts builds with a deprecation warning" (`csp/code-fact-check-report-r3.md:24`).

**Evidence:** `csp/code-fact-check-report.md:15-369`, `csp/code-fact-check-report-r{1,2,3}.md`

---

## Claim 13: csp rubric: "2 red, 7 amber", and each row's Source attributions

**Location:** `runs/review-arms/a8-2026-11-20/csp/code-review-rubric-2026-11-19-csp.md:5-37`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts and that each cited finding exists at the stated severity. It does not establish the tier calls.
**Legibility-target:** for-orchestrator-synthesis

Each cited finding exists at the stated severity:
- api `#### 1. The connect-src contract breaks …` `**Severity:** Breaking` `**Confidence:** High` (`csp/api-consistency-review-2026-11-19.md:34-39`), and `#### 2.` Breaking with Medium confidence (`:66-71`)
- security `#### 4. \`connect-src 'self'\` blocks \`fetch(data:)\`` `**Severity:** Low` (`csp/security-review-2026-11-19.md:112-114`)
- architecture `| 4 | \`x-nonce\` is unused pipeline surface … | Minor |` and `| 6 | CLAUDE.md … | Informational |` (`csp/architecture-review-2026-11-19.md:195,197`)
- test-strategy G7 at `exportGraph.ts:24,37` (`csp/test-strategy-review-2026-11-19.md:24`)
- C6's "about 15 µs at 21 headers" matches `NextResponse.next({request:{headers}})           15251 ns/op` (`csp/stage25-logs/s3-cost-bench.log:6`)

**Evidence:** the csp critic reports cited; `csp/stage25-logs/s3-cost-bench.log`

---

## Claim 14: manifest.json token maps and totals

**Location:** `runs/review-arms/a8-2026-11-20/manifest.json:27-105`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every figure against the ledger and the transcripts, plus internal sums. It does not establish the `labels_hit` strings, which Claims 20 and 27 cover.
**Legibility-target:** for-orchestrator-synthesis

The stage totals 335,650 / 436,098 / 435,604 / 698,163, the cores 771,748 / 1,133,767 and the all-agents figure 2,171,680 all recompute (`logs/calc.log`). Each of the 19 per-agent figures equals one transcript's last-call total (`logs/transcripts.log`). `"part5_full_tokens_est": 30856` is 123,423/4 rounded, and `"shared_block_stage2_tokens_est": 15476` is 61,902/4.

**Evidence:** `logs/calc.log`, `logs/transcripts.log`

---

## Claim 15: "Both passes use `skills/code-review/SKILL.md` as merged by d383a484 … at base 14d450d9. The critic and fact-check skill files are byte-identical to the first pass's (no change under those skill dirs since 4330e303)."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:15-17`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the skill files. It does not establish §1's "same prompts except delivery" (`results.md:26`), because the first pass's prompts live in another session's transcripts, which I did not read.
**Legibility-target:** for-orchestrator-synthesis

The empty d383a484..14d450d9 diff under `skills/code-review/` and the empty 4330e303..14d450d9 diff over the critic dirs are both in `logs/git.log`.

**Evidence:** `logs/git.log`

---

## Claim 16: "Total 2,171,680 tokens over 19 agents … For all 19 agents it equals the transcript's last API call (input + cache creation + cache read + output)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:19-22`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 19 subagent transcripts in this session's `subagents/` directory. It does not establish the statement that the figure "measures the final context, not tokens processed", which is a definition, not a check.
**Legibility-target:** for-orchestrator-synthesis

All 19 ledger figures appear in `tx.out` as last-call sums, for example `103630 31153 18900 # Review pass: shared context…` and `139180 30342 18900 Before anything else, read the whole file…` (`logs/transcripts.log`).

**Evidence:** `logs/transcripts.log`

---

## Claim 17: csp table: +23,675 (+7.6%), +6,654 (+1.9%), +4.8% / +0.2% / −3.9% / +6.1%, −2.9%, +27,993 (+3.8%), all agents +46,448

**Location:** `runs/review-arms/a8-2026-11-20/results.md:31-39`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell against both ledgers. It does not establish the noise interpretation (Claim 19).
**Legibility-target:** for-orchestrator-synthesis

`logs/calc.log` prints `335650 311975 23675 +7.59%`, `358744 352090 6654 +1.89%`, `sec +4.82%` `perf +0.17%` `api -3.90%` `arch +6.13%`, `ts -2.93%`, `771748 743755 27993 +3.76%` and `all 898733 852285 46448`.

**Evidence:** `logs/calc.log`, `token-ledger.md:13-25`, `runs/review-arms/a8-2026-11-19/token-ledger.md:10-22`

---

## Claim 18: "Each self-read agent's first call wrote 31.2k-32.6k tokens to cache, against 32.8k-33.8k inline … Every agent in both arms read 18,900 cached tokens on its first call"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:41-43`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 9 csp transcripts (first-call cache creation 31,153-32,645, read 18,900), and the first pass as recorded in its results doc. It does not establish that the whole 1.2k-1.6k gap is the block. The self-read prompts add a section naming the files to read, so the gap is smaller than the block's ~2.2k-2.9k.
**Legibility-target:** for-orchestrator-synthesis

The csp rows in `logs/transcripts.log` run from `103630 31153 18900` to `86385 32645 18900`. For the first pass: `32.8k-33.8k fresh, shared block included. This held for all 9 agents.` (`runs/review-arms/a8-2026-11-19/results.md:67`).

**Evidence:** `logs/transcripts.log`, `runs/review-arms/a8-2026-11-19/results.md:67`

---

## Claim 19: "the first pass's three identical fact-check replicates alone spanned 90k-121k, and today's 104k-122k"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:45-47`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the ranges. It does not establish that +3.8% is statistically inside the noise; one draw per arm cannot show that.
**Legibility-target:** for-orchestrator-synthesis

The first pass's ledger has `90,196`, `100,755` and `121,024` (`runs/review-arms/a8-2026-11-19/token-ledger.md:10-12`). This pass's has `103,630`, `109,582` and `122,438` (`token-ledger.md:13-15`).

**Evidence:** both ledgers

---

## Claim 20: csp labels 6/6: R1 via "fact-check Claim 10 Incorrect 3/3, api-consistency Breaking High (so 🔴), security Low, architecture Coupling, test-strategy G7"; R2 Claim 11 3/3; A1 Claims 3 and 13, security Medium, api Breaking Medium, architecture Coupling; A2 Claim 7 3/3; A3 Claims 2 and 20 3/3, performance Medium; A4 test G1; "security re-found canon N1"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:48-55`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each cited source against the canon rows `docs/working/canon-issue-ledger.md:92-97` and `:176` (N1). It does not establish the HIT judgments beyond the cited findings naming the canon issue.
**Legibility-target:** for-orchestrator-synthesis

The canon row is `| csp-R1 | \`connect-src 'self'\` blocks the \`data:\`/blob fetch in \`exportGraph.ts\` …` (`canon-issue-ledger.md:92`). The merged Claim 10 is `r1=Incorrect · r2=Incorrect · r3=Incorrect` (`csp/code-fact-check-report.md:158`). Security's `#### 3. Matcher sends some HTML documents without CSP: unanchored \`api\` prefix and the prefetch exemption (E5)` (`csp/security-review-2026-11-19.md:85`) matches N1, `middleware prefetch-skip serves real HTML with no CSP` (`canon-issue-ledger.md:176`). The other sources are as quoted in Claims 12-13.

**Evidence:** `docs/working/canon-issue-ledger.md:92-97,176`; csp agent reports

---

## Claim 21: "no replicate ran `next build` this time (the first pass's r3 did). r2 ran vitest (221/221) and eslint; Stage 2.5 ran 4 claims on `next dev` and probes."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:56-58`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the replicates' execution records and the Stage 2.5 verification modes. It does not establish anything about the first pass beyond its ledger row.
**Legibility-target:** for-orchestrator-synthesis

The first three parts hold. r2 records `Execution is required and was blocked. \`next build\` needs network access` (`csp/code-fact-check-report-r2.md:443`), and r1 records `Blocker: no \`node_modules\`` (`csp/code-fact-check-report-r1.md:337`). The vitest log shows `Tests  221 passed (221)`, and the eslint log `exit=0`. The first pass's r3 row says `executed: next build/start + curl` (`a8-2026-11-19/token-ledger.md:12`).

"4 claims" undercounts. Stage 2.5 has five executed verdicts: Claims 25, 27b, 28, 29 and 31, all `**Verification mode:** executed` (`csp/code-fact-check-submitted-claims.md:26,134,163,198,250`). There are four probe logs because Claim 29 reused Claim 28's `next dev` run. Only Claims 28 and 29 ran on `next dev`.

The precise version: "Stage 2.5 executed 5 of its 8 entries (four probe runs; 28 and 29 on `next dev`)".

**Evidence:** `csp/r2-logs/`, `csp/stage25-logs/`, `csp/code-fact-check-submitted-claims.md`

---

## Claim 22: "scope `-- app/` (15 files, +1166/−33)" and the block sizes "53,682-byte diff, 57,328 bytes (≈14.3k tokens, 57% of budget) in Stage 1 and 61,902 bytes (≈15.5k, 62%) in Stage 2"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:62,64-69`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the file sizes and percentages. The Stage 2 block equals the Stage 1 block plus `part6.md` (57,328 + 4,574 = 61,902). It does not establish the exact 123,423 (Claim 4 residue).
**Legibility-target:** for-orchestrator-synthesis

`logs/sizes.log` shows `53682`, ` 15 files changed, 1166 insertions(+), 33 deletions(-)`, ` 57328`, ` 61902` and `  4574`, and `calc.log` gives `0.57328 0.61902`.

**Evidence:** `logs/sizes.log`, `logs/calc.log`

---

## Claim 23: "The skill's calibration note ('the largest measured cell was ~17.4k tokens …', `SKILL.md:343-345`) counts diff + fact-check summary, not diff + enclosing files, which is what the budget is measured on, so on its own measure corpus does not inline."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:69-72`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the origin of the 17.4k figure and the line citation. It does not establish what the skill's other sentence, the enclosing-file byte range at `SKILL.md:340-341`, measures.
**Legibility-target:** for-author

The citation is right: `calibrated to the 2026-08-06 canon: the largest measured cell was ~17.4k tokens, so every measured cell inlines with ~45% headroom` (`skills/code-review/SKILL.md:343-345`). The source table measures `| Cell | diff+factcheck chars | prefix tok |` with `| corpus (app/) | 69,575 | 17,394 |` (`runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:36,43`). Its heading says "IF the shared diff + fact-check **report** are inlined" (`:33`).

So the core point holds: no enclosing files are counted. The quantity, though, is diff + fact-check report, not "summary". The skill's part 6 is a summary, so the word matters to a reader comparing it with today's 15.5k Stage 2 block.

**Evidence:** `skills/code-review/SKILL.md:335-347`, `runs/review-arms/baseline-2026-08-06/levers-3-4-measurement.md:33-48`

---

## Claim 24: corpus table: ×4.64, mean 145,201 (+54.5%), 698,163 vs 521,600 (+33.9%), the per-critic percentages, core ×1.84, k=1-equivalent 843,364 (+37.0%), all agents 1,272,947

**Location:** `runs/review-arms/a8-2026-11-20/results.md:75-85`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every cell. It does not establish comparability: k, the skill texts and Stage 2.5 all differ from the baseline, which results states at `:116-118`.
**Legibility-target:** for-orchestrator-synthesis

`logs/calc.log` prints `corpus fc 435604 4.6357…`, `145201.33 +54.53%`, `698163 521600 +33.85%`, `sec +29.70%` `perf +26.51%` `api +48.22%` `arch +36.44%` `td +39.74%` `ts +22.63%`, `core 1133767 615566 1.8418`, `k1 843364.33 +37.01%` and `all 1272947`.

**Evidence:** `logs/calc.log`

---

## Claim 25: "135,849 tokens over the 9 core agents, ≈12.0% of the core. Each critic grew 19.9k-44.1k over August, so the block is at most a third to three quarters of each critic's growth."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:87-90`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the arithmetic on the stated bytes/4 basis, and the in-context size from the transcripts. It does not establish the "most of the block is bytes they also carried" inference at `:91-92` (the baseline transcripts were not read).
**Legibility-target:** for-author

The arithmetic is right: `blk 135849.0 0.1198`, and growth runs from `19931` to `44114` (`logs/calc.log`). The upper end is loose: 15,476 / 19,931 = 0.776, a bit over three quarters (and 15,476 / 44,114 = 0.351).

The block also reached context as line-numbered Read output (Claim 5): 62,753 / 67,537 chars, so (3 × 62,753 + 6 × 67,537) / 4 = 148,370 tokens, or ≈13.1% of the core.

The precise version: "≈12-13% of the core; about a third to four fifths of each critic's growth".

**Evidence:** `logs/calc.log`, `logs/transcripts.log`

---

## Claim 26: "each agent Read the byte-identical block file as its first step … The context holds the same bytes either way, plus one tool call."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:93-95`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** The same evidence as Claim 5. It covers the 10 corpus agents' first tool calls and block-read sizes.
**Legibility-target:** for-author

Every corpus agent's first tool call is `Read` of the block file (`logs/transcripts.log`). The six Stage 2 critics needed a second Read (`"offset": 1069`), and the context holds line-numbered text, about 1.4k tokens more than the file. See Claim 5.

**Evidence:** `logs/transcripts.log`

---

## Claim 27: corpus label table: cor-A1 partial (api F4 flags the type, not the name; baseline "miss (ledger: enumeration class)"), cor-A2 HIT 🟡 A4, cor-A3 HIT 🟡 A5, cor-A4 HIT 🟡 A2 ("Claims 3, 4, executed 3/3; api F1, F11"), D3 HIT 🔴 R1

**Location:** `runs/review-arms/a8-2026-11-20/results.md:97-106`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the "Today" column against the agent reports and the canon rows `:112-115,161`, and the "miss" in the baseline column. It does not establish the parenthetical "(ledger: enumeration class)" as the baseline's: that text is the canon's E4-arm column (`canon-issue-ledger.md:112`), not the 2026-08-06 baseline.
**Legibility-target:** for-orchestrator-synthesis

The canon row is `| cor-A1 | \`customTypeIds\`→\`customArtifactTypeIds\` naming inconsistency | ✓(label) | ✗ | ✗ (enumeration class) |` (`canon-issue-ledger.md:112`). api's name audit has `| \`customTypeIds: string[]\` | field | \`CustomArtifactTypeId\` | … | Inconsistent: drops the template-literal id type (F4) |` (`corpus/api-consistency-review-2026-11-19.md:35`), which is a type mismatch, not the name, so "partial" is supported. No baseline corpus report raises the name (the grep over `baseline-2026-08-06/corpus/` finds only parse/test mentions).

cor-A4's "executed 3/3" holds: r1 Claim 7, r2 Claim 8b and r3 Claim 4b are each `**Verification mode:** executed`. D3's sources are as in Claim 11.

**Evidence:** `docs/working/canon-issue-ledger.md:112-115,161`; `corpus/api-consistency-review-2026-11-19.md:35`; `runs/review-arms/baseline-2026-08-06/corpus/critic-*.md`

---

## Claim 28: "Under the baseline's own A1-A4 reading (slug collision, bare Error vs CorpusError, stale docstrings, manifest silent drop), all four hit again: security Low #5, api F2, Claims 7/8, Claim 3. The baseline's extra performance-High … is today's 🟡 A6."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:109-112`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the mapping onto the baseline's reading and today's sources. It does not establish severity parity (the baseline had the slug collision at Medium, today at Low).
**Legibility-target:** for-orchestrator-synthesis

The baseline's reading is `A1 slug-collision (security Med), A2 bare-Error/CorpusError (api), A3 stale docstrings (tech-debt), A4 manifest silent-drop (tech-debt) — **all 4 HIT** + a new perf-High (debounce drop)` (`runs/review-arms/baseline-2026-08-06/results.md:28`). Today's matching sources are `| 5 | Lossy slug: distinct titles share a directory | Low |` (corpus security Summary Table) and `| F2 | Path builders throw plain \`Error\`, not \`CorpusError\` |`.

**Evidence:** `runs/review-arms/baseline-2026-08-06/results.md:28`; corpus security and api Summary Tables

---

## Claim 29: "The pass also hit canon N-rows the baseline did not have: N11 …, N12 …, N13 …, N18 …, N23 (slug collisions), N24 …, D4 (false 'fresh ArrayBuffer' comment) and D5 (unordered writes)"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:112-116`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers N23, D4 and D5 against the baseline's corpus reports. It does not establish whether the baseline had N11, N12, N13, N18 or N24. I found no baseline sighting of N24 (no `MANIFEST_VERSION` comparison finding) and did not search exhaustively for the others.
**Legibility-target:** for-author

The baseline had at least three of the eight:
- **N23.** Baseline security: `#### Slug generation is many-to-one — distinct titles collide to one workspace directory` (`runs/review-arms/baseline-2026-08-06/corpus/critic-security.md:27`), rated `| 1 | Slug collisions map distinct titles to one workspace dir | Medium |` (`:87`). The same results paragraph credits it to the baseline two lines earlier ("slug collision … security Low #5", `results.md:110-111`).
- **D4.** Baseline fact-check: `## Claim 8: "Pass a fresh ArrayBuffer view; some implementations dislike shared buffers."` (`baseline-2026-08-06/corpus/fact-check.md:177`), recorded as `corpus | 93,966 | 6 | 11V/3MA/1Stale/1I | no (I = ArrayBuffer comment → 🟡)` (`baseline-2026-08-06/token-ledger.md:15`).
- **D5.** Baseline performance: `file with no ordering guarantee (contention / possible last-writer-wins races),` (`baseline-2026-08-06/corpus/critic-performance.md:55`). That is the same unordered-write seam, and the canon itself treats such a finding as `probable` for D5 (`canon-issue-ledger.md:163`).

What to fix: drop N23, D4 and D5 from the "baseline did not have" list (or say "re-found"), and check N11, N12, N13, N18 and N24 the same way.

**Evidence:** `runs/review-arms/baseline-2026-08-06/corpus/critic-security.md:27,87`, `…/corpus/fact-check.md:177-188`, `…/corpus/critic-performance.md:35-55`, `…/token-ledger.md:15`, `docs/working/canon-issue-ledger.md:161-163,259-266`

---

## Claim 30: "C3 (`process.env?.` inlining) is flagged Unverifiable" and "Rubric: … 1 red, 9 amber"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:116-118`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merged Claim 24 and the rubric counts. It does not establish C3's real build behaviour.
**Legibility-target:** for-orchestrator-synthesis

The merged report has `**Replicate annotations:** all: read as \`process.env?.NEXT_PUBLIC_CORPUS_FS\`; the optional chain may defeat Next's inlining` (`corpus/code-fact-check-report.md:369`), with `**Verdict:** Unverifiable` (`:364`). The rubric lists R1 and A1-A9.

**Evidence:** `corpus/code-fact-check-report.md:360-372`, `corpus/code-review-rubric-2026-11-19-corpus.md:9-29`

---

## Claim 31: A8 §3, csp sentences: "dropping the inline block saved nothing. Self-read cost 3.8% more over the 8 core agents (inside one-draw noise) … Recall did not move (6/6 both ways, gold R1 caught both ways) … the cache saving it was adopted for stays at zero"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:123-128`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers each figure and its source (§1, the first pass's results). It does not establish "neither a saving nor a cost" beyond one draw per arm, a limit the sentence itself states as noise.
**Legibility-target:** for-orchestrator-synthesis

The first pass records `6/6 hit` (`runs/review-arms/a8-2026-11-19/results.md:100`) and `**Verdict: the "leave it on because it is free" claim fails on its benefit:** zero within this pass` (`:134-135`). The +3.76% is in `logs/calc.log`.

**Evidence:** `results.md:31-55`; `runs/review-arms/a8-2026-11-19/results.md:100,134-135`

---

## Claim 32: "On corpus the 25k budget did its job. The full material (≈30.9k) was over it, the ladder fell back to diff-only (≈14-15k per agent, 12% of core), and the pass still caught the cell's structural red and 3 of 4 ambers."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:128-130`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the ladder's behaviour and the recall figures. It does not establish that the budget prevented any harm, or that diff-only cost nothing in recall: no corpus arm at full inline or self-read exists, as the same paragraph says at `:131-133`.
**Legibility-target:** for-author

The mechanics hold (Claims 4, 22, 27). "Did its job" reads as a benefit, though, and the evidence shows only that the gate fired as written and recall stayed at 3 of 4 ambers plus a partial and the red. That collides with the paragraph's own "whether the budget is set right … unmeasured". The block share is ≈12% on bytes/4, or ≈13% as delivered (Claim 25).

A tighter wording: "the ladder fired as written".

**Evidence:** `results.md:64-73,97-108,130-133`

---

## Claim 33: "No run has inlined a block between ~15k and 25k … Its calibration note in the skill describes a different quantity from the one it gates (§2)."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:131-133`
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the code-review skill's measured passes (first A8 pass ~2.2k/2.9k, this pass 14.3k/15.5k, baseline self-read). It does not establish the claim for other harnesses: `scripts/cross-model-review.py` inlines whole diffs and was not surveyed. This pass's Stage 2 block, at 15.5k by bytes/4 and ~16.9k as delivered, sits just above the "~15k" edge.
**Legibility-target:** for-orchestrator-synthesis

The figures are `"shared_block_stage2_tokens_est": 15476` (`manifest.json:60`) and the first pass's `8,755 bytes ≈ 2,189 tokens` (`a8-2026-11-19/token-ledger.md:5`). The calibration-quantity half is established in Claim 23.

**Evidence:** `manifest.json:55-61`; `runs/review-arms/a8-2026-11-19/token-ledger.md:5`

---

## Claim 34: "No `tokens` map is empty; every agent is a row in `token-ledger.md` and in `manifest.json`."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:139`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 19 agents found in the transcripts. It does not establish that no other subagent of this session belongs to the run: `tx.out` holds 50 transcripts, including the first-pass and review agents, and I matched by figure.
**Legibility-target:** for-orchestrator-synthesis

The ledger has 9 + 10 rows, and the manifest has 9 + 10 keys with values. Each of the 19 figures appears in `logs/transcripts.log`.

**Evidence:** `token-ledger.md:11-44`, `manifest.json:27-86`, `logs/transcripts.log`

---

## Claim 35: "Replicates split claims more finely (corpus: 33, 35 and 22 claims), and the merge keeps one row per distinct assertion (csp 24, corpus 25, plus Stage 2.5's 7 and 8 entries)."

**Location:** `runs/review-arms/a8-2026-11-20/results.md:143-145`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the counts and the merge's completeness. It does not establish anything about Stage 2's use of the merges.
**Legibility-target:** for-orchestrator-synthesis

The counts 33/35/22 and 24/25 are right (replicate headers, and the merge headers `csp/code-fact-check-report.md:8` and `corpus/…:8`). Two imprecisions:
- The Stage 2.5 counts are in reverse order. csp has `**Total claims checked:** 8 (7 submitted; S3 split into 27a/27b)` (`csp/code-fact-check-submitted-claims.md:8`) and corpus `7` (`corpus/code-fact-check-submitted-claims.md:8`), so the text should read "8 and 7".
- The corpus merge omits five distinct Verified assertions (Claim 9), so "one row per distinct assertion" holds for csp only.

**Evidence:** the merged and submitted-claims report headers; Claim 9

---

## Claim 36: "Stage 2.5 refuted one endorsement on csp: the performance critic's 'constant work per request' (Claim 27b, executed …). It went in as 🟢 C6." and "the two scratch worktrees of the benchmark repo are removed"

**Location:** `runs/review-arms/a8-2026-11-20/results.md:146-149`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 27b's verdict, mode and submitter, and the worktree list. It does not establish "No agent process was left running", which I did not check with `ps`.
**Legibility-target:** for-orchestrator-synthesis

The submitted-claims report has `**Submitted by:** performance-reviewer` (`csp/code-fact-check-submitted-claims.md:129`), `**Verdict:** Incorrect` (`:132`) and `**Verification mode:** executed` (`:134`). It is the only Incorrect there (`:9`), and rubric C6 carries it. Worktrees: `logs/worktrees.log`.

**Evidence:** `csp/code-fact-check-submitted-claims.md:8-9,127-134`, `logs/worktrees.log`

---

## Claim 37: csp fact-check r3 outcome "5V/2MA/0S/6I/2U (15 claims …)"

**Location:** `runs/review-arms/a8-2026-11-20/token-ledger.md:14`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row against r3's header and its verdicted sections. It does not establish anything about the token figure, which is verified in Claim 16.
**Legibility-target:** for-orchestrator-synthesis

The row copies r3's own header faithfully: `**Total claims checked:** 15` and `**Summary:** 5 verified, 2 mostly accurate, 0 stale, 6 incorrect, 2 unverifiable` (`csp/code-fact-check-report-r3.md:8-9`). r3's body, however, has 17 verdicted sections (1, 2, 3, 4a, 4b, 5a, 5b, 6-15): 6 V (1, 4a, 5a, 8, 11, 13), 2 MA (6, 7), 7 I (2, 3, 4b, 5b, 9, 10, 12) and 2 U (14, 15). The precise version notes "header says 15; body has 17 sections, 6V/2MA/7I/2U". The csp r1/r2 and all corpus replicate rows match their bodies. This matches the logged count-mismatch pattern class (header count vs source).

**Evidence:** `csp/code-fact-check-report-r3.md:8-309`

---

## Claim 38: csp Stage 2.5 outcome "8 entries (S3 split): 6V (4 executed) / 1MA / 1I (perf 'constant work' refuted, executed)"

**Location:** `runs/review-arms/a8-2026-11-20/token-ledger.md:24`
**Type:** Reference
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the verdict and mode of each of the 8 entries. It does not establish the token figure, which is verified in Claim 16.
**Legibility-target:** for-orchestrator-synthesis

The 8 entries are 6 V / 1 MA / 1 I, which is right. Only 3 of the 6 Verified were executed, though: Claims 25, 28 and 29 (`**Verification mode:** executed` at `csp/code-fact-check-submitted-claims.md:26,163,198`), while 26, 27a and 30 are `static` (`:68,105,222`). Executed overall is 5 (adding 27b at `:134` and 31 at `:250`). The corpus row's "(6 executed)" is correct by the same count.

What to fix: "6V (3 executed) / 1MA (executed) / 1I (executed)", or "5 of 8 executed". This matches the logged count-mismatch pattern class.

**Evidence:** `csp/code-fact-check-submitted-claims.md:19-250`

---

## Claim 39: corpus ledger rows: subtotals 435,604 / 698,163, tool-use subtotals 46 / 63, core 1,133,767, all 1,272,947, and the replicate and critic outcome strings

**Location:** `runs/review-arms/a8-2026-11-20/token-ledger.md:31-52`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers sums, the replicate verdict tallies (checked against the bodies: r1 15/3/2/8/5 = 33, r2 12/6/2/9/6 = 35, r3 9/4/2/5/2 = 22), the critic severity tallies against each Summary Table, and the Stage 2.5 "4V / 3MA / 0I (6 executed)". It does not establish the per-agent durations.
**Legibility-target:** for-orchestrator-synthesis

The sums are in `logs/calc.log`. Tool uses: 14 + 13 + 19 = 46, and 11 + 7 + 9 + 10 + 10 + 16 = 63. For api, the Summary Table holds 6 Inconsistent (F1, F2, F3, F9, F4, F8), 4 Minor (F6, F10, F11, F5) and 2 Informational (F12, F7), matching `0 Breaking / 6 Inconsistent / 4 Minor / 2 Info`. The csp tool-use subtotals 63 / 44 also hold.

**Evidence:** `logs/calc.log`; corpus replicate and critic reports

---

## Claim 40: "Instrument check: for every agent of both passes, the notified figure equals the transcript's last API call …, and every first call read exactly 18,900 cached tokens"

**Location:** `runs/review-arms/a8-2026-11-20/token-ledger.md:54`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers all 19 transcripts' last-call sums and first-call `cache_read_input_tokens`. It does not establish that the notification field is computed from the transcript, only that the two are equal.
**Legibility-target:** for-orchestrator-synthesis

Every one of the 19 rows in `logs/transcripts.log` has 18900 in the first-call cache-read column, and its last-call sum equals the ledger figure.

**Evidence:** `logs/transcripts.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 29** (`runs/review-arms/a8-2026-11-20/results.md:112-116`): N23 (slug collision), D4 (ArrayBuffer comment) and D5 (unordered writes) are listed as N-rows "the baseline did not have", but the baseline's security, fact-check and performance reports have all three. Drop or reword them, and check N11, N12, N13, N18 and N24.
- **Claim 38** (`runs/review-arms/a8-2026-11-20/token-ledger.md:24`): "6V (4 executed)" is wrong. 3 of the 6 Verified were executed (25, 28, 29), and 5 of the 8 entries overall.

### Mostly Accurate
- **Claim 5** (`docs/working/research-2026-11-19-a8-settling-runs.md:79-82`) and **Claim 26** (`results.md:93-95`): the Stage 2 critics needed two Reads, and the line-numbered Read output adds ~1.4k tokens, not "one tool call (a few hundred tokens)" and "the same bytes".
- **Claim 9** (`corpus/code-fact-check-report.md:13`): the merge omits five distinct Verified replicate assertions (r1 14, 22, 23; r2 21, 23), so it is not "one row per distinct assertion".
- **Claim 10** (`corpus/code-fact-check-report.md:188`): Claim 12's replicate line says "r1=—, single-replicate detection", but r1 Claim 6c verdicted the same assertion Verified.
- **Claim 21** (`results.md:57-58`): Stage 2.5 executed 5 entries, not 4 claims, and only 2 of them ran on `next dev`.
- **Claim 23** (`results.md:69-72`): the 17.4k figure counts diff + fact-check **report** (`levers-3-4-measurement.md:33,36`), not "summary".
- **Claim 25** (`results.md:87-90`): the upper ratio is 78%, not "three quarters", and the in-context block share is ≈13.1%, not 12.0%.
- **Claim 32** (`results.md:128-130`): "the 25k budget did its job" claims a benefit the evidence does not show. Say "the ladder fired as written".
- **Claim 35** (`results.md:143-145`): the Stage 2.5 counts "7 and 8" are reversed (csp 8, corpus 7), and the "one row per distinct assertion" caveat from Claim 9 applies.
- **Claim 37** (`token-ledger.md:14`): it relays r3's header (15 claims, 5V/6I), but r3's body has 17 sections, 6V/2MA/7I/2U.

### Unverifiable
- **Claim 6** (`research-2026-11-19-a8-settling-runs.md:85-87`, `results.md:140-142`): the three refused csp critic dispatches. Checking them needs the orchestrator's main-session transcript.

---

## Goal-Alignment Note

- **Success criterion:** "A code-fact-check report on the A8 settling write-up, saved to the path given, structured per the code-fact-check skill."
- **Answered:** I recomputed every number in results.md, the research doc, the ledger and the manifest with python3 (`logs/calc.log`). I checked all 19 agent figures and their first-call cache figures against the transcripts. I checked each §1/§2 label verdict against the agent reports and canon rows, and the 25k-budget reasoning and the `SKILL.md:343-345` calibration origin against `levers-3-4-measurement.md:33-48`. Both rubrics' Source attributions exist. Both merges follow most-severe-wins, with one wrong corpus replicate cell (Claim 10) and five Verified rows omitted from the corpus merge (Claim 9). I checked each A8 §3 sentence for overclaim (Claims 31-33) and re-ran the research doc's git precondition check (Claim 1).
- **Out of scope:** The agent reports themselves, used only as evidence. The first pass's prompts (another session's transcripts), so "same prompts except delivery" is not checked. Whether the baseline had N11/N12/N13/N18 was not searched exhaustively. Running processes were not checked with `ps`.
- **Escalate:** (1) The brief says to "check that `git log -1 --format=%H -- skills/code-review/SKILL.md` on your base commit is that merge, and if it is not, end with a blocked marker". The literal command prints ca328816, not d383a484. The research doc proceeded on the (correct) reading that the skill content is the merge's, but that is a call against the brief's literal stop condition. The orchestrator should confirm it rather than leave it implicit. (2) The brief's last criterion (status line open → done "in the change that merges this work") is still pending at HEAD: `Status: open`. That is expected before the merge, but should be checked at merge time.
