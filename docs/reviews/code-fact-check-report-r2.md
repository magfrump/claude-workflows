# Code Fact-Check Report

**Commit:** fbd8597
**Repository:** `/workspace` (worktree `/workspace/.claude/worktrees/cross-model-review-sweep`, branch `exp/cross-model-openrouter-sweep`)
**Scope:** `git diff main...HEAD` — 10 files, +207/−7. Prose/code claims in `docs/decisions/021-reviewer-context-management.md`, `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md`, `scripts/cross-model-review.py`, `skills/code-review/SKILL.md`, plus the commit messages of `fbd8597` and `8c23b7e`. The `runs/cross-model/s1-*` JSONL/JSON files are treated as machine-generated primary evidence, not as prose under check.
**Checked:** 2026-07-31
**Total claims checked:** 36
**Summary:** 26 verified, 7 mostly accurate, 1 stale, 2 incorrect, 0 unverifiable

**Hallucination-pattern log:** `docs/reviews/hallucination-patterns.md` exists; its `## Patterns` section is empty (no entries appended to date). No claim below could be matched against a logged pattern, and none of the Incorrect verdicts below is a fabrication (both are miscounts), so no new entries are warranted.

---

## Claim 1: "offline cost measurement in `docs/working/stage1-context-cost-2026-07-31.md` (worst call $0.248, sweep $4.37: both guardrails hold)"

**Location:** `docs/decisions/021-reviewer-context-management.md:12-14`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both figures match the cited source verbatim. `docs/working/stage1-context-cost-2026-07-31.md:71-72` reads: "the priciest single call is $0.248 (Sol on ND2), under the ~$0.33 median band trigger; the full-sweep projection $4.37 is under the $10 trigger." Line 69 of the same doc gives "**diff-only $1.95 → Stage-1 $4.37 (~2.2×)**".

Brief item 9 asks whether the record conflates this projection with the new actuals. It does not: the sentence containing $0.248/$4.37 is explicitly introduced as "offline cost measurement in `docs/working/stage1-context-cost-2026-07-31.md`", while the following sentence is introduced as "actual spend $3.53, median call $0.226". Projection and measurement are separately labelled and separately sourced.

**Evidence:** `docs/decisions/021-reviewer-context-management.md:11-17`, `docs/working/stage1-context-cost-2026-07-31.md:59,69,71-72`

## Claim 2: "the D3/D4 FP-kill re-run ... reproduced **neither** Result 3c nor Result 5 (0/8 each); actual spend $3.53, median call $0.226 — cost triggers did not fire"

**Location:** `docs/decisions/021-reviewer-context-management.md:14-17`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Verified against the run artifacts directly (see Claims 13, 21, 25, 30 for the underlying checks). Recomputing from `usage.cost` across all 16 rows of the two `findings.jsonl` files gives D3 $2.0842, D4 $1.4510, total $3.5351, median $0.225656 — i.e. "$3.53" (as the sum of the rounded per-cell figures) and "$0.226". The `--context-base` and `--replicates` structure of the JSONL (4 model ids × 2 replicates per cell) confirms "0/8 each" is per-cell.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl` (`usage.cost` fields, all 16 rows)

## Claim 3: "Results 3c and 5 reproduced 0/8 each on the same four families that produced them diff-only"

**Location:** `docs/decisions/log.md:51` (row 30, Why column)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The "0/8 each" half is verified (Claims 21 and 25). The qualifier "the same four families that produced them" is loose in one direction: the same four families were *re-run*, but they did not jointly *produce* both FPs diff-only. Result 3c was produced by a single family — the baseline doc states "Gemini r1 on D3 reported **Critical**: 'check.py evaluates payload natively on host'" (`docs/working/experiment-cross-model-review-2026-07-30.md:178`), and the committed baseline data shows the Critical only under `google/gemini-3.1-pro-preview` in `runs/cross-model/gt-31e2d3a/findings.jsonl`. Result 5 was the multi-family one (and see Claim 34 for how many families actually filed it).

Precise version: "the same four families that were re-run diff-only, one of which produced 3c and most of which produced 5".

**Evidence:** `docs/working/experiment-cross-model-review-2026-07-30.md:176-189,218-239`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 4: "D3 cross-family Jaccard rose to 0.28–0.40"

**Location:** `docs/decisions/log.md:51` (row 30)
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`runs/cross-model/s1-31e2d3a/overlap.json` `cross` block: Sonnet↔Gemini `0.396`, Sonnet↔Sol `0.283`, Gemini↔Sol `0.375`. The range 0.283–0.396 rounds to the stated 0.28–0.40. Row 30 correctly scopes the claim to D3 (unlike the SKILL.md wording — Claim 35).

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`

## Claim 5: "Sonnet r2 used the labelled sibling context correctly instead of FP-ing on it"

**Location:** `docs/decisions/log.md:51` (row 30)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The Sonnet D4 r2 finding "Tier C ('full parity') is instruction-only, with no gate verifying compliance" reads, verbatim from `runs/cross-model/s1-7ceba3f/findings.jsonl`: "nothing in the validation gates (including the new gate 1h, already committed) checks that a task actually ran `/verify`, executed the review-fix loop, or wrote a retro doc". The parenthetical treats gate 1h as existing-and-committed, which is the opposite of the Result-5 failure mode.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (row `anthropic/claude-sonnet-5`, replicate 2, third finding)

## Claim 6: "`cross-model-review.py` documents `--context-base` as the recommended mode and warns on live diff-only runs (diff-only stays available as a recall probe / for pre-021 comparability, byte-identical)"

**Location:** `docs/decisions/log.md:51` (row 30, Decision column)
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three sub-claims hold. Docstring: "`--context-base` is therefore the RECOMMENDED mode for any review-quality use; run diff-only only as a deliberate recall probe or for comparability with pre-021 measurements" (`scripts/cross-model-review.py:25-27`). Warning: `scripts/cross-model-review.py:422-427` (see Claim 32). Byte-identical: confirmed empirically — `python3 scripts/cross-model-review.py --repo . --range '7ceba3f~1..7ceba3f' --dry-run` printed `context mode: diff-only, prompt sha 968d268b1689`, matching the `prompt_sha` field on every row of `runs/cross-model/gt-7ceba3f/findings.jsonl` (see Claim 36).

**Evidence:** `scripts/cross-model-review.py:16-28,417-427`, `runs/cross-model/gt-7ceba3f/findings.jsonl`

## Claim 7: "**FP-kill validation ran 2026-07-31** ... Results 3c and 5 reproduced **0/8 each**"

**Location:** `docs/thoughts/code-review-evaluation-state.md:283-285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Same underlying verification as Claims 21 and 25 — I read all 23 D3 findings and all 15 D4 findings and found no member of either FP class. The heading change on line 278 ("Stage 1 built and validated 2026-07-31", replacing "built 2026-07-31, untested") is consistent with the run artifacts existing and being non-empty.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `docs/thoughts/code-review-evaluation-state.md:278-291`

## Claim 8: "Sonnet r2 even cited the labelled sibling context correctly (\"gate 1h, already committed\")"

**Location:** `docs/thoughts/code-review-evaluation-state.md:285-286`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 10 asks specifically whether this quote paraphrase survives comparison with the raw finding text. It does, as an exact substring: the finding contains "(including the new gate 1h, already committed)". The quoted fragment "gate 1h, already committed" appears verbatim in `runs/cross-model/s1-7ceba3f/findings.jsonl`.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (row `anthropic/claude-sonnet-5`, replicate 2)

## Claim 9: "D3 cross-family Jaccard rose to 0.28–0.40 (families converge on real issues under shared context)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:287-288`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Same numbers as Claim 4. The state doc scopes it to D3 explicitly, which is the precise scoping the data supports (D4 did not rise — see Claim 27 and Claim 35).

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`

## Claim 10: "Sonnet found the Result-3b `np.load` issue 2/2 (was 0/3 diff-only)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:288-289`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 4. Numerator: both Sonnet D3 replicates in `runs/cross-model/s1-31e2d3a/findings.jsonl` file the issue — r1 "`allow_pickle` positional-arg check now misses variable/expression arguments" and r2 "allow_pickle positional-arg check narrowed to literal-only, unlike the keyword form". 2/2. Denominator: the baseline `runs/cross-model/gt-31e2d3a/findings.jsonl` Sonnet rows are r1 `n_findings: 0`, r2 two findings ("tmpfs mount can shadow `--chdir \"$PWD\"` under bwrap", "Static open()-write-mode gate removed, weakening the already-weak fallback tier" — neither is the np.load issue), r3 `n_findings: 0`. 0/3. This matches the baseline narrative: "Found by **three families across seven replicates** — Kimi K3 3/3, Sol 3/3 (High), Gemini (High) — and by no Sonnet replicate" (`docs/working/experiment-cross-model-review-2026-07-30.md:143-144`).

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:141-144`

## Claim 11: "a new grounded 4-family consensus finding emerged (bwrap `--tmpfs /tmp` vs `--chdir \"$PWD\"`, untriaged)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:289-290`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four families file it on D3: Kimi r1 "bwrap run fails when CWD is under /tmp, and probe can't catch it" (Medium); Sol r1 "bwrap fails for working directories beneath /tmp" (Medium) and r2 "bwrap execution fails when the working directory is under `/tmp`" (Medium); Sonnet r1 "bwrap probe does not mirror the real invocation's flags" (Medium) and r2 "bwrap `--chdir \"$PWD\"` can be shadowed by the fresh `--tmpfs /tmp` mount" (Low); Gemini r2 "`bwrap` fails if executed from a `/tmp` subdirectory" (Medium). "Untriaged" is consistent with follow-up 1 in the experiment doc ("Triage the bwrap `/tmp`-CWD consensus finding").

Note one nuance not affecting the verdict: the same issue also appears in the *baseline* diff-only D3 run (Kimi r1 "bwrap `--chdir \"$PWD\"` hard-fails when CWD is under /tmp"; Sol/Gemini/Sonnet equivalents in `gt-31e2d3a`), so "new" is best read as "newly at 4-family consensus", not "newly discovered".

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl` (all 4 model ids), `runs/cross-model/gt-31e2d3a/findings.jsonl`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md:106-107`

## Claim 12: "Actual spend $3.53, median call $0.226 — no cost trigger fired"

**Location:** `docs/thoughts/code-review-evaluation-state.md:290-291`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Recomputed sum over all 16 `usage.cost` values is $3.5351 and the median is $0.2256558. Minor rounding note (not a defect): the exact total rounds to $3.54 at two decimals; "$3.53" is the sum of the two rounded per-cell figures ($2.08 + $1.45), which is how the experiment doc presents it. Triggers: median $0.226 < the ~$0.33 band trigger, total $3.54 < the $10 trigger (both trigger thresholds per `docs/working/stage1-context-cost-2026-07-31.md:71-72`).

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `docs/working/stage1-context-cost-2026-07-31.md:71-72`

## Claim 13: "**Answer: yes, both. 0/8 replicates reproduced either FP class, on the same four families that produced them diff-only.**"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:7-8`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 1, checked exhaustively. I read every one of the 38 findings across both cells.

(a) Result-3c class (check.py/runpy executes the payload on host): absent from all 8 D3 replicates. The closest D3 findings are Kimi r1's "confine.py exec-neutering misses the underlying spawn primitive" (about `_posixsubprocess.fork_exec` reachability, an in-sandbox claim) and Sol r1/r2's process-containment findings — none asserts that `check.py` itself executes the payload via `runpy` on the host.

(b) Result-5 class (Tier A/B work missing — `file_scope` widening, `si-functions.sh`): absent from all 8 D4 replicates. No finding mentions `si-functions.sh`, `parse_code_review_red`, `code_review_gate_verdict`, or a `file_scope` gap. The one D4 finding whose title contains "file-scope" — Sonnet r2's "Harvest `claude -p` call has no file-scope restriction" — is the *opposite* claim: it says "Unlike the per-task implement prompt (which enforces an explicit FILE SCOPE CONSTRAINT), the post-merge harvest prompt only tells the model to 'append...'", i.e. it correctly reads the sibling-committed Tier A work as present and contrasts a *different* code path against it.

One adjacency worth recording (does not change the verdict, since it is neither named FP class): Kimi D4 r2 filed "`BRANCH_TIP_SHAS` population is unverifiable from the provided material", reasoning that "no assignment to this array appears in the diff or the committed context". That is a context-limit artifact of the same family the experiment's own follow-up 2 anticipates (the 72 KB `self-improvement.sh` was above the inline cap), though the finding is hedged as "unverifiable ... Confirm it is populated" rather than asserted as missing work.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl` (23 findings), `runs/cross-model/s1-7ceba3f/findings.jsonl` (15 findings)

## Claim 14: "**Raw data:** `runs/cross-model/s1-31e2d3a/`, `runs/cross-model/s1-7ceba3f/` (findings.jsonl + overlap.json + prompt.txt)."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:14-15`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

The `prompt.txt` files exist on disk (80,642 B and 49,274 B) but are **not committed** — `git status --short` lists them as untracked (`?? runs/cross-model/s1-31e2d3a/prompt.txt`, `?? runs/cross-model/s1-7ceba3f/prompt.txt`), and `git diff main...HEAD --stat` shows only `findings.jsonl` and `overlap.json` for each `s1-*` directory. A reader who clones the branch gets two of the three named artifacts.

The sibling commit message states the correct scope: `8c23b7e` says "Raw data in runs/cross-model/s1-*/ (prior convention: findings+overlap only)" — so the omission is deliberate and the doc line is the part that drifted. Current state: findings.jsonl + overlap.json committed; prompt.txt local-only (and reproducible — see Claim 17).

**Evidence:** `git status --short`, `git diff main...HEAD --stat`, `git log -1 --format=%B 8c23b7e`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md:14-15`

## Claim 15: "D3 | `31e2d3a~1..31e2d3a` | `4582f97` (= `8ef9d52~1`, chain start) | review-fix rounds 1–5 (27 KB)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The ref identity and the size are exact. `git rev-parse 8ef9d52~1` and `git rev-parse 4582f97` both return `4582f975c79708a6156ed3eaca57f2e30950b85f`. The regenerated D3 stage-1 prompt reports `sibling diff 27,128` chars = 26.5 KiB, i.e. "27 KB". The `context_base` field on all 8 D3 rows is `"4582f97"`.

The imprecision is in the sibling-section description. `git log --oneline 4582f97..31e2d3a~1` returns **seven** commits, of which two are not review-fix rounds: `8ef9d52 fix(security): harden arithmetic-eval...` (the chain start itself) and `b185330 feat(security): add tiered OS confinement...`. The remaining five (`62beca1`, `b7e4595`, `503ebc9`, `0c02887`, `74d626e`) are the review-fix rounds. Precise version: "chain start + tiered-confinement feature + review-fix rounds 1–5".

**Evidence:** `git rev-parse 8ef9d52~1 4582f97`, `git log --oneline 4582f97..31e2d3a~1`, `runs/cross-model/s1-31e2d3a/findings.jsonl` (`context_base`), regenerated dry-run stats

## Claim 16: "D4 | `7ceba3f~1..7ceba3f` | `45bea51` (= `5e67ab5~1`) | Tier A + Tier B (11 KB) — exactly the work Result 5 called \"missing\""

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:28`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git rev-parse 5e67ab5~1` and `git rev-parse 45bea51` both return `45bea515cf8f014cc1363485b902e293a6cab775`. `git log --oneline 45bea51..7ceba3f~1` returns exactly two commits: `2b81baa feat(self-improvement): Tier B — add multi-critic code-review validation gate` and `5e67ab5 feat(self-improvement): Tier A — align loop with repo process conventions`. "Exactly the work Result 5 called missing" is precise: the baseline names `5e67ab5` for the `file_scope` widening and `2b81baa` for `si-functions.sh` ("widened by Tier A in `5e67ab5`" / "shipped by Tier B in `2b81baa`", `docs/working/experiment-cross-model-review-2026-07-30.md:230,232`). Size: regenerated prompt reports `sibling diff 11,442` chars = 11.2 KiB.

**Evidence:** `git rev-parse 5e67ab5~1 45bea51`, `git log --oneline 45bea51..7ceba3f~1`, `docs/working/experiment-cross-model-review-2026-07-30.md:229-232`

## Claim 17: "Prompt SHAs `bfc998d0be1c` (D3, ~20k tokens) / `e106076c4ce1` (D4, ~12k tokens); byte-identical across models"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:30-31`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Reproduced offline. `python3 scripts/cross-model-review.py --repo . --range '31e2d3a~1..31e2d3a' --context-base 4582f97 --dry-run` printed `context mode: stage1(base=4582f97), prompt sha bfc998d0be1c` and `prompt size: 80,313 chars, ~20,078 tokens`. The D4 equivalent printed `prompt sha e106076c4ce1` and `~12,259 tokens`. Both SHAs and both token figures match the doc. Byte-identical-across-models: every one of the 8 rows per cell carries the same `prompt_sha` value (`bfc998d0be1c` ×8, `e106076c4ce1` ×8).

**Evidence:** regenerated `--dry-run` output for both cells; `prompt_sha` fields in `runs/cross-model/s1-31e2d3a/findings.jsonl` and `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 18: "All 16 calls returned `parse_ok=True`; zero abstentions except Sonnet D4 r1."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:32`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 5. All 16 JSONL rows across the two cells carry `"parse_ok": true`. Abstentions: `n_findings` is ≥1 on 15 of 16 rows; the single zero is `anthropic/claude-sonnet-5` replicate 1 in `runs/cross-model/s1-7ceba3f/findings.jsonl`. The overlap files corroborate: `s1-31e2d3a/overlap.json` has `abstain` 0.0 for all four models, `s1-7ceba3f/overlap.json` has `"anthropic/claude-sonnet-5": 0.5` and 0.0 for the rest.

**Evidence:** both `s1-*/findings.jsonl` (`parse_ok`, `n_findings`), both `s1-*/overlap.json` (`abstain`)

## Claim 19: "on D4 the enclosing-file section omitted `scripts/self-improvement.sh` (72 KB > 64 KB cap)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:34-35`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 8's file-size sub-claim. `git cat-file -p 7ceba3f:scripts/self-improvement.sh` is 74,876 bytes / 74,721 decoded characters = **72.97 KiB of characters** (73.12 KiB of bytes). The harness measures decoded characters, so "72 KB" is its own accounting and rounds correctly. The regenerated D4 dry-run confirms the omission actually occurred: `enclosing files 18,437, **1 skipped**` (D3, by contrast: `0 skipped`). The 64 KB cap is the documented default (`--max-inline-kb 64`, cited on line 11 of the same doc).

**Evidence:** `git cat-file -p 7ceba3f:scripts/self-improvement.sh` (size), regenerated D4 `--dry-run` output, `docs/working/experiment-stage1-fp-kill-2026-07-31.md:10-11`

## Claim 20: "## Result A — D4: the Result-5 sibling-commit consensus FP is gone (0/8, was 8/8-family)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:39`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

The "0/8" half is verified (Claim 21). "was 8/8-family" is not supported by any committed artifact and does not correspond to the baseline's replicate structure. The baseline D4 evidence lives in two directories: `runs/cross-model/gt-7ceba3f/findings.jsonl` (Kimi only, 2 rows) and `runs/cross-model/fast-7ceba3f/findings.jsonl` (Sol, Sonnet, Gemini × 3 rows each, 9 rows) — **11 baseline replicates, not 8**. Of those 11, the Result-5 claim appears in: Kimi r1 ("Retro instructions route tasks into file_scope rejection") and r2 ("the Tier A file_scope widening and Tier B code-review gate described in decision 020 are absent from this diff"); Gemini r1/r2/r3 ("Missing Tier A and Tier B implementations", "Missing validation gates implementation", "Missing gate validation code"); and Sonnet r1 ("Decision record documents unshipped code"). That is **6/11 replicates across 3 of 4 families** — none of Sol's three replicates filed it (I read all eight Sol baseline finding descriptions; they concern harvest eligibility, commit format, and unvalidated LLM writes).

Actual figure: 0/8 now, versus 6/11 baseline replicates across 3 families.

**Evidence:** `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 21: "**no finding in any replicate claims Tier A/B work is missing** — no `file_scope` FP, no \"si-functions.sh doesn't exist\", no High findings at all."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:45-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All three sub-claims check out against all 15 D4 findings. No finding asserts Tier A/B absence (detailed in Claim 13(b), including why Sonnet r2's "no file-scope restriction" finding is not a counterexample). No occurrence of `si-functions.sh` anywhere in the D4 JSONL. Severities present are Medium (8) and Low (7) only — no High, no Critical.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (all 15 findings, `sev` fields)

## Claim 22: "Sonnet r2's decision-020 finding *cites* gate 1h as \"already committed\" and instead makes the sharper (grounded) claim that no gate verifies Tier-C compliance"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:49-52`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both halves match the raw text quoted in Claim 5/8. The finding's title is "Tier C (\"full parity\") is instruction-only, with no gate verifying compliance" and it is filed against `docs/decisions/020-self-improvement-loop-dogfoods-repo-process.md / scripts/self-improvement.sh`, so "decision-020 finding" and "no gate verifies Tier-C compliance" are both accurate.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (row `anthropic/claude-sonnet-5`, replicate 2)

## Claim 23: "The 15 findings shifted to real Tier-C-diff issues, including two independent rediscoveries of the live Result-3 pipefail bug (Sol r1 Low, Gemini r1 Medium) — previously found only by Kimi."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:54-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Count: 2+2+4+2+0+3+1+1 = 15 findings across the 8 D4 rows. Attribution: Sol r1 filed "Empty failure-pattern library can abort under pipefail" at **Low** ("If the library has no `FP-[0-9]+` entries, `grep` returns nonzero; with `pipefail`/`errexit`, the assignment can terminate the script"); Gemini r1 filed "grep pipeline crash on empty file" at **Medium** ("Under `set -eo pipefail`, this command substitution failure will crash the script"). Severities and replicate indices are as stated. "Previously found only by Kimi": the baseline Kimi row includes "Unguarded grep pipeline can abort the round under pipefail" and no Sol/Sonnet/Gemini baseline title or description covers it.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 24: "Recurrent cluster (3 families): fix-task detection reads only the branch **tip** commit subject, missing multi-commit task branches."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:56-57`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The cluster is **2 families**, not 3. It appears in four D4 findings, all from Kimi and Sol: Kimi r1 "Fix-task detection checks only the branch tip commit subject", Kimi r2 "Fix-task detection keys off only the branch tip commit subject", Sol r1 "Fix-task detection misses eligible retros" ("Harvesting examines only the branch tip subject"), Sol r2 "Fix detection only examines the branch tip". Neither Sonnet replicate nor either Gemini replicate filed it — Sonnet r2's three findings concern harvest file-scope, silent no-op, and Tier-C enforcement; Gemini r1/r2 filed the grep-pipefail crash and a `git diff --quiet`/staged-changes issue.

Note the count is 3 families in the *baseline* D4 data (Kimi, Sol, and Gemini r3 "Tip commit filter causes missed failure patterns"), which may be the source of the transposition.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (all 15 findings), `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 25: "**no replicate of any family reports the runpy/check.py misattribution**. Gemini's findings are now the real `np.load` positional fail-open (Result 3b; High in r2) and the bwrap `/tmp` CWD issue. 23 findings total"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:64-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 1(a). No D3 finding mentions `runpy` or asserts host-side payload execution by `check.py` (detailed in Claim 13(a)). Gemini's three D3 findings are exactly as described: r1 "`np.load` 3rd positional argument check fails open for non-constants" (Medium); r2 "`numpy.load` static check fails open for non-constant 3rd arguments" (**High**) and "`bwrap` fails if executed from a `/tmp` subdirectory" (Medium). Count: 5+1+4+4+3+3+1+2 = 23.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl` (all 23 findings)

## Claim 26: "New cross-family consensus finding (all 4 families, Medium): the bwrap invocation `--tmpfs /tmp … --chdir \"$PWD\"` fails when the caller's CWD is under `/tmp` ... and the probe doesn't mirror the real run's `--chdir`."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:69-72`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All four families are represented and each has at least one instance at Medium (per-finding severities listed in Claim 11; Sonnet's r1 instance is Medium, r2 is Low). Both halves of the description are present in the raw text — the `--chdir` failure (Gemini r2: "the subsequent `--chdir \"$PWD\"` command will fail with 'No such file or directory'") and the probe-mirroring gap (Sonnet r1: "the probe omits `--ro-bind \"$AE\" \"$AE\"`, `--chdir`, `--new-session`, and `--clearenv $ENV` that the real run adds"). As in Claim 11, "new" means newly at 4-family consensus; the issue also appears in the baseline D3 run.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl` (all four model ids), `runs/cross-model/gt-31e2d3a/findings.jsonl`

## Claim 27: "D3: J_cross now 0.28–0.40 for Sonnet↔Gemini↔Sol (was 0.000–0.513 with most pairs ≈0) ... Kimi remains the outlier population (J_cross 0.036–0.103) ... D4 J_cross stays low (0.0–0.267)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-82`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Brief item 3. Three of the four figures are exact. New D3 Sonnet↔Gemini↔Sol: 0.283 / 0.375 / 0.396 → "0.28–0.40" ✔. New D3 Kimi pairs: 0.036 / 0.042 / 0.103 → "0.036–0.103" ✔. D4 all pairs: 0.0 / 0.0 / 0.0 / 0.062 / 0.104 / 0.267 → "0.0–0.267" ✔.

The imprecision is "with most pairs ≈0". The baseline D3 `cross` block is 0.0, 0.093, 0.119, 0.258, 0.382, 0.513 — the min and max justify "0.000–0.513", but only one of six pairs is literally 0 and the median is ~0.19; three pairs are ≥0.258. Precise version: "was 0.000–0.513, with the three Sonnet-involving pairs at 0.000–0.119". (Under that narrower reading — the three pairs the new figure is actually comparable to — the point stands.)

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 28: "**Sonnet found the Result-3b `np.load` positional issue in 2/2 D3 replicates** — diff-only, no Sonnet replicate found it (0/3)."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:84-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Same verification as Claim 10, with the additional detail that this phrasing ("no Sonnet replicate found it") matches the baseline doc's own wording ("and by no Sonnet replicate", `docs/working/experiment-cross-model-review-2026-07-30.md:144`) and the baseline data (Sonnet r1 and r3 returned zero findings; r2's two findings are unrelated).

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:141-144`

## Claim 29: "D4 abstention: Sonnet 1/2 replicates empty (r1) — the abstention-rate line (follow-up 4 fix) now surfaces this instead of scoring it J_self=1.0."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:89-90`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Sonnet D4 r1 has `"n_findings": 0` and an empty `findings` array; r2 has 3. The new `overlap.json` schema carries an `abstain` block — `"anthropic/claude-sonnet-5": 0.5` in `s1-7ceba3f/overlap.json` — and Sonnet's `self` entry there is `0.0` rather than being inflated by the empty run. The contrast with the old behavior is visible in the baseline file: `gt-31e2d3a/overlap.json` has **no `abstain` key at all**, and Sonnet's `self` is `0.333` — consistent with two empty runs (r1, r3) pairing to J_self=1.0 and averaging (1.0+0+0)/3 = 0.333. That is exactly the artifact the claim describes.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 30: "D3 $2.08 + D4 $1.45 = **$3.53** /16 calls ... Median per-call **$0.226** ... worst call $0.388 (Kimi D3 r1, 636 s ...). Latency: Sol 48–76 s, Gemini 110–143 s, Sonnet 93–263 s, Kimi 287–636 s."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:94-98`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 2, recomputed from the `usage.cost` and `latency_s` fields. D3 sum $2.0842 → $2.08 ✔. D4 sum $1.4510 → $1.45 ✔. 16 calls ✔. Median of the 16 sorted costs = $0.2256558 → $0.226 ✔. Max = $0.388023, on the `moonshotai/kimi-k3` replicate-1 row of `s1-31e2d3a` with `"latency_s": 636.1` ✔. Latencies by family across both cells: Sol 48.3–75.8 ✔; Gemini 109.9–143.3 ✔; Sonnet 92.9–262.6 → "93–263" ✔; Kimi 287.0–636.1 ✔. (See Claim 12 for the $3.5351-vs-$3.53 rounding note.)

**Evidence:** both `s1-*/findings.jsonl` (`usage.cost`, `latency_s` on all 16 rows)

## Claim 31: "VALIDATED 2026-07-31 ...: the D3/D4 re-run reproduced neither FP in 0/8 replicates each, and cross-family agreement on real issues rose."

**Location:** `scripts/cross-model-review.py:22-25`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The FP half is verified (Claims 21, 25). "Cross-family agreement on real issues rose" is unqualified and holds only on D3. On D4, agreement *fell* on every comparable pair: baseline `fast-7ceba3f/overlap.json` gives Sonnet↔Gemini 0.106, Sonnet↔Sol 0.148, Gemini↔Sol 0.065; the Stage-1 `s1-7ceba3f/overlap.json` gives 0.0, 0.104, 0.062 respectively. The experiment doc itself is precise about this ("D4 J_cross stays low (0.0–0.267)", line 81-82), as is decisions log row 30 ("D3 cross-family Jaccard rose"). Precise version: "cross-family agreement on real issues rose on D3 (0.28–0.40 for the three non-Kimi pairs, from 0.09–0.12); D4 was unchanged-to-slightly-lower."

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`, `runs/cross-model/fast-7ceba3f/overlap.json`

## Claim 32: "(live diff-only runs print a warning to stderr)"

**Location:** `scripts/cross-model-review.py:27-28` (docstring); implementation at `scripts/cross-model-review.py:422-427`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 6, first half. The word "live" is load-bearing and correct — the guard sits **after** the dry-run early return:

```python
        if args.dry_run:
            with open(os.path.join(args.out, "prompt.txt"), "w") as fh:
                fh.write(prompt)
            print(f"dry run: prompt written to {os.path.join(args.out, 'prompt.txt')}; no calls made")
            return
        if not args.context_base:
            ...
            print("WARNING: diff-only mode is a recall probe with a known misattribution "
                  ..., file=sys.stderr)
```
(`scripts/cross-model-review.py:417-427`)

So `--dry-run` returns before the branch is reachable — confirmed empirically: my diff-only dry-run of `7ceba3f~1..7ceba3f` (stderr merged into stdout via `2>&1`) emitted only the three normal status lines and no WARNING. The condition `not args.context_base` correctly scopes it to diff-only. Destination is `sys.stderr`, so it cannot contaminate the stdout status lines other tooling parses.

**Evidence:** `scripts/cross-model-review.py:417-427`; observed output of `python3 scripts/cross-model-review.py --repo . --range '7ceba3f~1..7ceba3f' --dry-run --out $TMPDIR/fc-r2-check 2>&1`

## Claim 33: "Diff-only prompt stays byte-identical (verified: dry-run sha 968d268b1689 matches gt-7ceba3f historical rows; bats suite 8/8)."

**Location:** commit message `fbd8597`; corresponding docstring claim at `scripts/cross-model-review.py:19-22` ("byte-identical across models")
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Brief item 6, second half — both sub-claims are offline-verifiable and both reproduce.

SHA: `python3 scripts/cross-model-review.py --repo . --range '7ceba3f~1..7ceba3f' --dry-run --out $TMPDIR/fc-r2-check` printed `context mode: diff-only, prompt sha 968d268b1689`. Every row of `runs/cross-model/gt-7ceba3f/findings.jsonl` carries `"prompt_sha": "968d268b1689"`. Exact match.

Bats: `bats test/cross-model-review-stage1.bats` returned `1..8` with all 8 `ok`, including the directly relevant `ok 6 diff-only dry-run prompt is unchanged by the stage-1 additions (prompt sha stable)`.

Mechanically, the warning cannot affect prompt assembly: the prompt and its SHA are built at `scripts/cross-model-review.py:379-397`, well before the warning branch at line 422, and the warning only calls `print(..., file=sys.stderr)` with no assignment.

**Evidence:** `scripts/cross-model-review.py:379-397,422-427`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `test/cross-model-review-stage1.bats` (8/8 pass), `git log -1 --format=%B fbd8597`

## Claim 34: "the 2026-07-31 Stage-1 experiment ... showed unlabelled single-commit scope made **all four model families** unanimously flag work as missing that sat in sibling commits"

**Location:** `skills/code-review/SKILL.md:101`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Brief item 7. Two separable imprecisions.

(a) **Attribution.** The unlabelled/diff-only result is from the *2026-07-30 baseline* sweep, not the 2026-07-31 Stage-1 experiment. The 2026-07-31 experiment measured only the enriched condition; its Result A merely restates the baseline ("Baseline: all four families, several at High, flagged Tier A/B work as missing", `docs/working/experiment-stage1-fp-kill-2026-07-31.md:41-42`). The cited doc is the right pointer for the *fix*, the wrong pointer for the *diff-only finding*, whose home is `docs/working/experiment-cross-model-review-2026-07-30.md:218-239`.

(b) **"all four ... unanimously".** SKILL.md faithfully restates its source — the baseline doc says "On D4, **all four families** flagged, several at High" (line 220) and "Diff-only review manufactures confident, **unanimous**, high-severity findings" (line 236). But the committed run data is weaker: as detailed in Claim 20, the Result-5 claim appears in 6 of 11 baseline D4 replicates across 3 of 4 families, with `openai/gpt-5.6-sol` filing it in 0/3 replicates (I read all eight Sol baseline descriptions). Sonnet filed it in 1/3. So "unanimously" — which strengthens the source's already-generous "all four families" — is not supported by the artifacts in `runs/`.

The *rule* SKILL.md states is unaffected; only the strength of its cited warrant is. Precise version: "made three of four model families flag work as missing that sat in sibling commits (6 of 11 diff-only replicates, several at High)".

**Evidence:** `skills/code-review/SKILL.md:101`, `docs/working/experiment-cross-model-review-2026-07-30.md:218-239`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 35: "the label + sibling context reduced that FP class to 0/8 while *raising* agreement on real issues"

**Location:** `skills/code-review/SKILL.md:101`
**Type:** Behavioral / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Brief item 3's second half. "Reduced that FP class to 0/8" is verified (Claim 21). The emphasised "*raising* agreement on real issues" is unqualified but is a D3-only result — and the sentence's subject is the D4 FP class, so the two clauses describe different cells without saying so. On D4, the cell this sentence is actually about, cross-family agreement did not rise: baseline `fast-7ceba3f/overlap.json` 0.106 / 0.148 / 0.065 → Stage-1 `s1-7ceba3f/overlap.json` 0.0 / 0.104 / 0.062 for the same three pairs. The rise (0.283–0.396, from 0.093–0.119 on the comparable pairs) is D3.

Precise version: "... reduced that FP class to 0/8, and on the other cell raised cross-family agreement on real issues to J≈0.28–0.40."

**Evidence:** `skills/code-review/SKILL.md:101`, `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/fast-7ceba3f/overlap.json`, `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 36: "kept `--context-base` opt-in at the flag level (021 requires the diff-only default byte-identical for historical comparability); the warning + docs carry the behavioral default instead."

**Location:** commit message `fbd8597` (Notes line)
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Accurate self-description of the diff. `--context-base` remains a plain optional argument with no default (the code path is guarded by `if args.context_base:` at `scripts/cross-model-review.py:379`), so omitting it still produces the pre-021 prompt — confirmed by the SHA match and bats test 6 in Claim 33. The behavioral steer is carried entirely by the docstring (`:22-28`) and the stderr warning (`:422-427`), neither of which alters assembly. The docstring's opening line was correspondingly softened from "opt-in via --context-base" to "via --context-base" while the flag stayed optional — consistent with, not contradicted by, this note.

**Evidence:** `scripts/cross-model-review.py:16-28,379-397,422-427`, `git log -1 --format=%B fbd8597`, `test/cross-model-review-stage1.bats`

---

## Claims Requiring Attention

### Incorrect
- **Claim 20** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:39`): "was 8/8-family" — baseline D4 had 11 committed replicates, of which 6 across 3 of 4 families filed the Result-5 FP (Sol: 0/3). No artifact supports 8/8.
- **Claim 24** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:56-57`): "Recurrent cluster (3 families)" — the branch-tip fix-detection cluster is 2 families (Kimi, Sol) in the Stage-1 D4 data; 3 families is the *baseline* count.

### Stale
- **Claim 14** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:14-15`): "Raw data ... (findings.jsonl + overlap.json + prompt.txt)" — the two `prompt.txt` files are untracked and not on the branch; commit `8c23b7e` states the actual convention (findings+overlap only).

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:51`): "the same four families that produced them diff-only" — Result 3c was produced by one family (Gemini), not four.
- **Claim 15** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`): D3 sibling section described as "review-fix rounds 1–5"; it is 7 commits (chain start + a feature commit + rounds 1–5). Size (27 KB) and ref identity are exact.
- **Claim 27** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:79`): "(was 0.000–0.513 with most pairs ≈0)" — only 1 of 6 baseline D3 pairs was ≈0; median ~0.19.
- **Claim 31** (`scripts/cross-model-review.py:24-25`): "cross-family agreement on real issues rose" — true on D3; agreement fell slightly on D4 for all three comparable pairs.
- **Claim 34** (`skills/code-review/SKILL.md:101`): attributes the diff-only FP result to the 2026-07-31 experiment (it is the 2026-07-30 baseline), and "all four model families unanimously" overstates the data (3 of 4 families, 6/11 replicates).
- **Claim 35** (`skills/code-review/SKILL.md:101`): "while *raising* agreement on real issues" is unqualified but is a D3 result; the D4 cell the sentence is about saw no rise.

### Unverifiable
- None.

---

## Goal-Alignment Note
- Answered: yes — all 36 checkable claims in the branch diff verified against run artifacts, git history, and re-executed harness/test commands.
- Out of scope: the contents of the `runs/cross-model/s1-*` JSONL/JSON files themselves (treated as machine-generated primary evidence per the brief); pre-existing unchanged prose in `docs/decisions/021`, the state doc, and the harness docstring outside the diff hunks; code-quality/security judgments about the harness change.
- Escalate: (1) Claims 20 and 24 are arithmetic errors in the experiment doc's own summary lines and should be corrected before this doc is cited further — Claim 24's "3 families" in particular is the kind of number that propagates. (2) Claim 34 is a cross-report issue: the "all four families unanimously" figure originates in `docs/working/experiment-cross-model-review-2026-07-30.md:220,236` (unchanged on this branch, so out of my scope to verdict) and is now load-bearing for a normative rule in `skills/code-review/SKILL.md`; the orchestrator may want a separate pass on the baseline doc. (3) The untracked `runs/cross-model/s1-*/prompt.txt` files are a commit/no-commit decision, not a text fix — either commit them or amend the doc line.
