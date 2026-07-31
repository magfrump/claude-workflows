# Code Fact-Check Report

**Commit:** fbd8597
**Replication:** k=3
**Repository:** `/workspace` (worktree `/workspace/.claude/worktrees/cross-model-review-sweep`, branch `exp/cross-model-openrouter-sweep`)
**Scope:** `git diff main...HEAD` — 10 files, +207/−7, plus the `fbd8597`/`8c23b7e` commit messages. The `runs/cross-model/s1-*` JSONL/JSON files are machine-generated primary evidence, not prose under check.
**Checked:** 2026-07-31
**Total claims checked:** 24
**Summary:** 10 verified, 8 mostly accurate, 1 stale, 5 incorrect, 0 unverifiable

Merged most-severe-wins from `code-fact-check-report-r1.md` (27 claims), `-r2.md` (36), `-r3.md` (30); clustering is semantic (file, ±5 lines, claim substance). Evidence below is carried from the replicate that assigned the winning verdict; see the per-replicate reports for full traces.

---

## Claim 1: "the 2026-07-31 Stage-1 experiment … showed unlabelled single-commit scope made **all four model families** unanimously flag work as missing … while *raising* agreement on real issues"

**Location:** `skills/code-review/SKILL.md:101`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Mostly accurate · r3=Incorrect

Three defects in the sentence justifying the new partial-scope rule ("validated, not speculative"): (a) **"all four model families"** — `openai/gpt-5.6-sol` filed zero Result-5-class findings in all three diff-only baseline replicates (r3 read all eight Sol descriptions verbatim; they concern harvest eligibility, commit format, unvalidated LLM writes). Actual: 3 of 4 families, 6 of 11 baseline replicates (Kimi 2/2, Gemini 3/3, Sonnet 1/3). (b) **"unanimously"** — unanimous only within Gemini. (c) **"while *raising* agreement on real issues"** — D3-only; on D4, the cell the sentence is about, all three baseline-comparable J_cross pairs fell (0.106/0.148/0.065 → 0.0/0.104/0.062, `runs/cross-model/fast-7ceba3f/overlap.json` vs `s1-7ceba3f/overlap.json`). r2 additionally notes the attribution defect: the diff-only result belongs to the 2026-07-30 baseline sweep, not the 2026-07-31 experiment. The rule itself remains amply supported (a 3-family, 6/11-replicate High-severity FP class); the stated strength is not what the data shows. "Reduced that FP class to 0/8" is verified (Claim 15).

**Evidence:** `skills/code-review/SKILL.md:101`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`

## Claim 2: "Baseline: all four families, several at High, flagged Tier A/B work as missing" / "(0/8, was 8/8-family)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:39-43`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

Unanimous 3/3. The D4 diff-only baseline is 11 replicates (`gt-7ceba3f` 2 Kimi + `fast-7ceba3f` 9 Sol/Sonnet/Gemini), not 8; the Result-5 FP appears in 6 of them across 3 of 4 families — Kimi r1/r2 (`"…the Tier A file_scope widening and Tier B code-review gate described in decision 020 are absent from this diff"`), Sonnet r1 (`"Decision record documents unshipped code"`), Gemini r1/r2/r3 (`"Missing Tier A and Tier B implementations"` etc.). Sol: 0/3. "was 8/8-family" is supported by no artifact. "Several at High" is verified (all six FP findings are High). Precise version: "0/8, was 6/11 replicates across 3 of 4 families, all at High". The "all four families" wording is inherited from the baseline doc's own Result 5 (`experiment-cross-model-review-2026-07-30.md:220`), which the raw data also contradicts.

**Evidence:** `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 3: "New cross-family consensus finding (all 4 families, Medium): the bwrap invocation `--tmpfs /tmp … --chdir \"$PWD\"` …"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:69-76`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Verified · r3=Incorrect

The finding is **not new** — it was already a four-family finding in the diff-only D3 baseline (8 of 12 replicates: Kimi r1 `"bwrap --chdir \"$PWD\" hard-fails when CWD is under /tmp"`, Sol r1/r2/r3, Sonnet r2 `"tmpfs mount can shadow --chdir \"$PWD\" under bwrap"`, Gemini r1/r2/r3 — `runs/cross-model/gt-31e2d3a/findings.jsonl`), and the baseline doc's Result 6 names it as a convergence point. It is a *persistent* four-family finding, which undercuts the doc's inference that "4-family agreement **under enriched context** is now evidence, not an FP smell" — the same agreement existed diff-only. (r2 read "new" charitably as "newly at 4-family consensus" and verified; the charitable reading is also false — it was 4-family in the baseline.) Secondary imprecision (r1): "all 4 families, Medium" — Sonnet's r2 instance is Low. The `31e2d3a:skills/arithmetic-eval/SKILL.md:268` flag citation is verified correct; persistence across both context modes still supports the finding being real.

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/s1-31e2d3a/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md` (Result 6)

## Claim 4: "a new grounded 4-family consensus finding emerged (bwrap `--tmpfs /tmp` vs `--chdir \"$PWD\"`, untriaged)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:289-290`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Verified · r3=Incorrect

State-doc echo of Claim 3; same evidence, same defect ("new"/"emerged" vs. the baseline's existing 4-family instance). "Untriaged" is accurate.

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/s1-31e2d3a/findings.jsonl`

## Claim 5: "Recurrent cluster (3 families): fix-task detection reads only the branch **tip** commit subject"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:56-58`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect

Unanimous 3/3. The Stage-1 D4 cluster is **2 families** (Kimi r1/r2, Sol r1/r2 — 4 of 8 replicates); neither Sonnet nor Gemini replicate filed it (all five of their finding bodies read). r2 identifies the likely transposition source: the count is 3 families in the *baseline* D4 data (Kimi, Sol, plus Gemini r3 `"Tip commit filter causes missed failure patterns"`).

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 6: "**Raw data:** `runs/cross-model/s1-31e2d3a/`, `runs/cross-model/s1-7ceba3f/` (findings.jsonl + overlap.json + prompt.txt)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:14-15`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=— · r2=Stale · r3=Mostly accurate

Both `prompt.txt` files exist on disk but are untracked (`git ls-files` returns only the four findings/overlap paths; no ignore rule matches). The sibling commit message `8c23b7e` states the actual convention: "Raw data in runs/cross-model/s1-*/ (prior convention: findings+overlap only)". A reader cloning the branch gets two of the three named artifacts; the prompts remain reproducible via `--dry-run` + `prompt_sha`.

**Evidence:** `git ls-files runs/cross-model/s1-*`, `git diff main...HEAD --stat`, `git log -1 --format=%B 8c23b7e`

## Claim 7: 021 status line — "offline cost measurement … (worst call $0.248, sweep $4.37: both guardrails hold)" adjacent to the new actuals

**Location:** `docs/decisions/021-reviewer-context-management.md:12-14`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate

Both figures reproduce exactly in the cited cost doc, and projection vs. actuals are separately labelled (no conflation). r3's imprecision stands: the actual worst call ($0.388, Kimi D3 r1) overshot the $0.248 worst-call projection by 56%, which the experiment doc flags but 021's status line — where a reader looks for the guardrail — does not; and $4.37 (ND-cells projection) vs $3.53 (D3/D4 actual) are not comparable sweeps.

**Evidence:** `docs/decisions/021-reviewer-context-management.md:12-17`, `docs/working/stage1-context-cost-2026-07-31.md:69-72`, `runs/cross-model/s1-31e2d3a/findings.jsonl`

## Claim 8: "Results 3c and 5 reproduced 0/8 each on the same four families that produced them diff-only" (log row 30; echoed in the experiment doc's Answer line)

**Location:** `docs/decisions/log.md:51`; `docs/working/experiment-stage1-fp-kill-2026-07-31.md:7-8`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

"0/8 each" verified (Claim 15). "The same four families that produced them" over-attributes: Result 3c came from a single Gemini replicate (`gt-31e2d3a`, `"check.py evaluates payload natively on host"`, Critical); Result 5 from three of four families. Precise version: "on the same four families swept diff-only, three of which produced Result 5 and one of which produced Result 3c."

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:176-186`

## Claim 9: "D3 cross-family Jaccard rose to 0.28–0.40" (log row 30; state doc adds "families converge on real issues under shared context")

**Location:** `docs/decisions/log.md:51`; `docs/thoughts/code-review-evaluation-state.md:287-288`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Mostly accurate

0.283/0.375/0.396 for the Sonnet↔Gemini↔Sol triangle is exact. r3's qualifier: as an unqualified statement about D3 cross-family Jaccard it is a redistribution, not a rise — the three Kimi-involving pairs *fell* (0.258→0.042, 0.382→0.103) and so did the baseline maximum Gemini↔Sol (0.513→0.375). Defensible restatement: "the Sonnet/Gemini/Sol pairs converged to 0.28–0.40 while Kimi diverged further."

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 10: "J_cross now 0.28–0.40 … (was 0.000–0.513 with most pairs ≈0)" and companion ranges (experiment doc Result C)

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-83`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

Every numeric range is correct (new D3 0.28–0.40 and Kimi 0.036–0.103; D4 0.0–0.267; baseline 0.000–0.513). "With most pairs ≈0" is wrong: only one of six baseline D3 pairs is 0, median ~0.19, three pairs ≥0.258. It holds only for the three Sonnet-involving pairs — the relevant comparison set, but not what the sentence says. Gemini↔Sol fell 0.513→0.375, unmentioned.

**Evidence:** `runs/cross-model/gt-31e2d3a/overlap.json`, `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`

## Claim 11: harness docstring "VALIDATED 2026-07-31 …: reproduced neither FP in 0/8 replicates each, and cross-family agreement on real issues rose"

**Location:** `scripts/cross-model-review.py:22-25`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate

Unanimous 3/3. The 0/8 and warning halves are verified. "Cross-family agreement on real issues rose" is unqualified and true only on D3 (and there only for the non-Kimi triangle); on D4 all three baseline-comparable pairs fell. Precise version: "agreement rose among Sonnet/Gemini/Sol on D3."

**Evidence:** `scripts/cross-model-review.py:16-32`, `runs/cross-model/fast-7ceba3f/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/s1-31e2d3a/overlap.json`

## Claim 12: D3 setup row — "`4582f97` (= `8ef9d52~1`, chain start) | review-fix rounds 1–5 (27 KB)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified

Ref identity, chain-start, 27 KB size, and the stamped `context_base` fields are all exact. The sibling-section description is imprecise: `4582f97..31e2d3a~1` holds seven commits — the chain-start hardening commit `8ef9d52`, the tiered-confinement feature `b185330`, plus review-fix rounds 1–5 — not rounds 1–5 alone.

**Evidence:** `git log --oneline 4582f97..31e2d3a~1`, `runs/cross-model/s1-31e2d3a/findings.jsonl`

## Claim 13: "on D4 the enclosing-file section omitted `scripts/self-improvement.sh` (72 KB > 64 KB cap)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:34-35`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified

The omission is real and matches the prompt verbatim (`s1-7ceba3f/prompt.txt:586-587`), and the 64 KB default is confirmed. r1's imprecision: "72 KB" is the harness's decoded-characters÷1024 accounting; the file blob is 74,876 bytes (73.1 KiB). Either measure exceeds the cap; the doc reads as if 72 KB were the file size.

**Evidence:** `runs/cross-model/s1-7ceba3f/prompt.txt:586-587`, `scripts/cross-model-review.py:219-226,357`, `git cat-file -s 7ceba3f:scripts/self-improvement.sh`

## Claim 14: "23 findings total, all anchored to real constructs in the reviewed diff" (D3), with Result B's baseline attribution and Gemini description

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:60-67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified

Count (23), the absence of any runpy/check.py misattribution, Gemini's actual findings (np.load fail-open, High in r2; bwrap `/tmp`), and the path-anchoring of all findings to the three D3-diff files are verified. r1's caveat: "all anchored to real constructs" also asserts a negative over 23 findings' internal reasoning (e.g. Kimi's `_posixsubprocess.fork_exec` reachability chain is plausible-but-unexecuted); the verifiable version — no replicate cites a construct that does not exist in the reviewed files — holds.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `git diff --stat 31e2d3a~1..31e2d3a`

## Claim 15: "0/8 each" — the FP-kill core, in 021, the state doc, and the experiment doc's Results A/B detail lines

**Location:** `docs/decisions/021-reviewer-context-management.md:14-17`; `docs/thoughts/code-review-evaluation-state.md:285`; `docs/working/experiment-stage1-fp-kill-2026-07-31.md:44-46,64-66`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

All three replicates independently read every one of the 38 findings in both cells. No D3 finding asserts host-side payload execution by `check.py`; no D4 finding asserts Tier A/B absence (no `file_scope` FP, no `si-functions.sh` mention; Sonnet r2's "no file-scope restriction" finding explicitly contrasts against the Tier-A constraint as *present*). D4 has no High/Critical findings (9 Medium + 6 Low per r1; r3 tallies 8/7 — a Medium/Low boundary difference on one finding, immaterial to "no High").

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl` (23 findings), `runs/cross-model/s1-7ceba3f/findings.jsonl` (15 findings)

## Claim 16: cost and latency numbers — "$2.08 + $1.45 = $3.53 /16 calls, median $0.226, worst $0.388 (Kimi D3 r1, 636 s)", latency bands, "no cost trigger fired"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:94-98`; echoed in 021 and the state doc
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Recomputed by all three replicates from `usage.cost`/`latency_s`: sums $2.0842/$1.4510, median $0.22566, max $0.388023 on Kimi D3 r1 (636.1 s). Latency bands Sol 48.3–75.8, Gemini 109.9–143.3, Sonnet 92.9–262.6, Kimi 287.0–636.1 — all as stated. The 021 triggers are defined on the *median* band (~$0.33) and sweep total ($10); neither fired. (Rounding note: exact total $3.5351 → "$3.53" is the sum of rounded per-cell figures.)

**Evidence:** `runs/cross-model/s1-*/findings.jsonl`, `docs/decisions/021-reviewer-context-management.md:141-147`

## Claim 17: "Sonnet r2 … cites gate 1h as 'already committed'" — the labelled-context inversion, in log row 30, the state doc, and the experiment doc

**Location:** `docs/decisions/log.md:51`; `docs/thoughts/code-review-evaluation-state.md:285-287`; `docs/working/experiment-stage1-fp-kill-2026-07-31.md:49-52`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

The quoted fragment is verbatim-contiguous in the Sonnet D4 r2 finding: `"nothing in the validation gates (including the new gate 1h, already committed) checks that a task actually ran /verify…"`. The finding treats sibling-committed work as present and files a distinct grounded claim.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (anthropic/claude-sonnet-5, replicate 2)

## Claim 18: "Sonnet found the Result-3b `np.load` issue 2/2 (was 0/3 diff-only)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:288-289`; `docs/working/experiment-stage1-fp-kill-2026-07-31.md:84-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Both Stage-1 Sonnet D3 replicates file the allow_pickle positional issue; the baseline's three Sonnet rows (0, 2 unrelated, 0 findings) contain none — matching the baseline narrative "by no Sonnet replicate".

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:141-144`

## Claim 19: D4 setup row — "`45bea51` (= `5e67ab5~1`) | Tier A + Tier B (11 KB) — exactly the work Result 5 called 'missing'"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:28`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Ref identity exact; `45bea51..7ceba3f~1` is exactly `5e67ab5` (Tier A) + `2b81baa` (Tier B); 11,479-byte sibling diff; the baseline names those two commits as the "missing" work's location.

**Evidence:** `git log --oneline 45bea51..7ceba3f~1`, `docs/working/experiment-cross-model-review-2026-07-30.md:229-232`

## Claim 20: "Prompt SHAs `bfc998d0be1c` / `e106076c4ce1` … byte-identical across models; ~20k/~12k tokens; all 16 calls parse_ok=True; zero abstentions except Sonnet D4 r1"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:30-32`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

One `prompt_sha` per cell across all 8 rows each; r2 regenerated both Stage-1 prompts offline and reproduced both SHAs and token estimates. 16/16 `parse_ok`; the single zero-findings row is Sonnet D4 r1, corroborated by the `abstain` blocks.

**Evidence:** `runs/cross-model/s1-*/findings.jsonl`, `runs/cross-model/s1-*/overlap.json`, regenerated `--dry-run` output (r2)

## Claim 21: "two independent rediscoveries of the live Result-3 pipefail bug (Sol r1 Low, Gemini r1 Medium) — previously found only by Kimi"; "15 findings"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:54-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Severities, replicate indices, the 15-count, and the baseline's Kimi-only attribution all check out against the three JSONL files.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 22: "live diff-only runs print a warning to stderr" + diff-only byte-identity ("dry-run sha 968d268b1689 matches gt-7ceba3f historical rows; bats suite 8/8") + commit-notes "opt-in at the flag level"

**Location:** `scripts/cross-model-review.py:27-28,417-427`; commit message `fbd8597`; `docs/decisions/log.md:51`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

All three replicates independently re-executed the offline checks. The warning sits after the `--dry-run` early return (unreachable in dry-run — confirmed empirically by warning-free dry-runs) and after `prompt_sha` is computed, so it cannot perturb prompt bytes; destination `sys.stderr`. Dry-run reproduces `968d268b1689`, matching every historical `gt-7ceba3f`/`fast-7ceba3f` row; `bats test/cross-model-review-stage1.bats` 8/8 including the sha-stability test. `--context-base` remains optional with no default. r3's placement nuance (advisory, not a defect): the warning also prints on live runs that then abort at the cost guard.

**Evidence:** `scripts/cross-model-review.py:379-397,417-430`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `test/cross-model-review-stage1.bats`

## Claim 23: "D4 abstention: Sonnet 1/2 replicates empty (r1) — the abstention-rate line (follow-up 4 fix) now surfaces this instead of scoring it J_self=1.0"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:89-90`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified

The new `overlap.json` schema carries `abstain` (Sonnet 0.5 on D4) and Sonnet's `self` is 0.0 rather than empty-inflated; the baseline `gt-31e2d3a/overlap.json` has no `abstain` key and a 0.333 Sonnet `self` consistent with the old empty-vs-empty artifact.

**Evidence:** `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 24: remaining structural/reference claims — row-30 harness description; state-doc "validated" heading flip; "no High findings at all" (D4); Kimi escalation paraphrase

**Location:** `docs/decisions/log.md:51`; `docs/thoughts/code-review-evaluation-state.md:278`; `docs/working/experiment-stage1-fp-kill-2026-07-31.md:41-46`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified

Row 30's three-part description of the change matches the diff; the state-doc heading flip to "built and validated" is consistent with the artifacts; D4 has no High/Critical findings; the Kimi escalation quote is a faithful paraphrase of the baseline doc's Result 5, which in turn tracks Kimi r1's actual finding.

**Evidence:** `docs/decisions/log.md:51`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md` (Result 5)

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`skills/code-review/SKILL.md:101`): "all four model families unanimously" (3/4 families, 6/11 replicates) + unqualified "raising agreement" (D4 fell) + misattributed to the 2026-07-31 experiment. Highest-leverage: it is the stated warrant for the new process rule.
- **Claim 2** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:39-43`): "all four families" and "was 8/8-family" — actual: 6/11 replicates, 3/4 families (Sol 0/3); baseline had 11 replicates, not 8. Unanimous 3/3.
- **Claim 3** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:69-76`): the bwrap `/tmp` consensus finding is persistent (4-family in the baseline too), not "new"; the novelty-based "consensus is now evidence" inference needs restating. Sonnet instance is Low, not Medium.
- **Claim 4** (`docs/thoughts/code-review-evaluation-state.md:289-290`): state-doc echo of Claim 3.
- **Claim 5** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:56-58`): "Recurrent cluster (3 families)" is 2 families (Kimi, Sol); 3 is the baseline count. Unanimous 3/3.

### Stale
- **Claim 6** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:14-15`): Raw-data line lists `prompt.txt`, which is untracked; commit or drop from the line.

### Mostly Accurate
- **Claim 7** (`docs/decisions/021-reviewer-context-management.md:12-14`): worst-call projection overshoot ($0.388 vs $0.248) unflagged in 021's status line; $4.37/$3.53 are different cell-sets.
- **Claim 8** (`docs/decisions/log.md:51` + experiment doc Answer line): "same four families that produced them" — 3c was one Gemini replicate.
- **Claim 9** (`docs/decisions/log.md:51`, state doc): "D3 J_cross rose" — redistribution; Kimi pairs and the baseline max fell.
- **Claim 10** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-83`): "most pairs ≈0" false (1 of 6; median ~0.19).
- **Claim 11** (`scripts/cross-model-review.py:22-25`): docstring "agreement rose" needs the D3/non-Kimi qualifier.
- **Claim 12** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`): D3 sibling section is 7 commits, not "rounds 1–5" alone. (Also: Claim 13's "72 KB" is chars÷1024, file is 74,876 B; Claim 14's "all anchored to real constructs" holds only in its verifiable form.)

### Unverifiable
- None.

---

## Verdict stability

24 clusters. All three replicates surfaced 21 of them; Claim 6 and Claim 23 were two-replicate detections (r1 —), no single-replicate clusters.

- **Full agreement among reporting replicates:** 15/24 clusters — 10 Verified (incl. Claim 23's two-replicate V/V), 2 Incorrect (Claims 2, 5), 3 Mostly accurate (Claims 8, 10, 11).
- **Disagreements (7 clusters):**
  - Claim 1: r1=Incorrect · r2=Mostly accurate · r3=Incorrect → **Incorrect**
  - Claim 3: r1=Incorrect · r2=Verified · r3=Incorrect → **Incorrect**
  - Claim 4: r1=Incorrect · r2=Verified · r3=Incorrect → **Incorrect**
  - Claim 6: r2=Stale · r3=Mostly accurate → **Stale**
  - Claim 7: r1=Verified · r2=Verified · r3=Mostly accurate → **Mostly accurate**
  - Claim 9: r1=Verified · r2=Verified · r3=Mostly accurate → **Mostly accurate**
  - Claim 12: r1=Mostly accurate · r2=Mostly accurate · r3=Verified → **Mostly accurate** (likewise Claims 13, 14: MA/V/V → Mostly accurate)

Agreement rate: **15/24 (62.5%)** — below the ≥90% falsifier threshold of the state doc's §1.1, consistent with keeping k=3. The characteristic disagreement is Verified-vs-qualifier (one replicate accepting a range or framing that another scopes more tightly), plus r2's charitable reading of "new" on Claims 3/4.

## Goal-Alignment Note
- Answered: yes — all 10 briefed claim groups checked by all three replicates against run artifacts, harness source, git history, and re-executed offline checks.
- Out of scope: `runs/cross-model/s1-*` JSONL/JSON as prose (used as primary evidence per brief); code-quality/security/design judgments (critic stage); the unchanged baseline doc (consulted as source only).
- Escalate: (1) the "all four families/unanimously" error originates in the unchanged baseline doc (`experiment-cross-model-review-2026-07-30.md:220,236`) and propagates through the experiment doc, SKILL.md, and log row 30 — fix as one pass including the out-of-diff source; (2) the "new consensus = evidence" inference (Claims 3/4) needs restating before follow-up 1 (bwrap triage) is acted on — persistence across context modes is the defensible framing; (3) `prompt.txt`: commit both files or amend the Raw-data line; (4) the $0.388 worst-call overshoot of 021's $0.248 projection is noted in the experiment doc but absent from 021's status line.
