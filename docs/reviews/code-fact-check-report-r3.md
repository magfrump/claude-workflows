# Code Fact-Check Report

**Commit:** fbd8597
**Repository:** `/workspace` (worktree `/workspace/.claude/worktrees/cross-model-review-sweep`, branch `exp/cross-model-openrouter-sweep`)
**Scope:** `git diff main...HEAD` — 10 files, +207/−7 (`docs/decisions/021-reviewer-context-management.md`, `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md`, `runs/cross-model/s1-31e2d3a/*`, `runs/cross-model/s1-7ceba3f/*`, `scripts/cross-model-review.py`, `skills/code-review/SKILL.md`) plus the `fbd8597` commit message. The `runs/cross-model/s1-*` JSONL/JSON files are treated as machine-generated primary evidence, not as prose under check.
**Checked:** 2026-07-31
**Total claims checked:** 30
**Summary:** 16 verified, 8 mostly accurate, 0 stale, 6 incorrect, 0 unverifiable

**Hallucination pattern log:** `docs/reviews/hallucination-patterns.md` exists and its `## Patterns` section is empty (line 24: `<!-- Append entries below this line. -->`, no entries follow). No claim in this scope could be matched against a logged pattern. None of the Incorrect verdicts below is a fabrication (all are miscounts or a mis-attributed novelty claim), so no entries were appended.

---

## Claim 1: "offline cost measurement in `docs/working/stage1-context-cost-2026-07-31.md` (worst call $0.248, sweep $4.37: both guardrails hold)"

**Location:** `docs/decisions/021-reviewer-context-management.md:12-14`
**Type:** Performance / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Both figures reproduce exactly in the cited source: "**diff-only $1.95 → Stage-1 $4.37 (~2.2×)**" (`docs/working/stage1-context-cost-2026-07-31.md:69`) and "the priciest single call is $0.248 (Sol on ND2), under the ~$0.33 median band trigger; the full-sweep projection $4.37 is under the $10 trigger" (`:71-72`). The sentence also correctly labels these as an *offline* measurement, distinct from the actuals in the following sentence — the brief's conflation concern does not materialize.

Imprecision: the paragraph now sits directly next to actuals showing the projection's worst-call guardrail was overshot in practice — the priciest real call was $0.388 (Kimi D3 r1; `runs/cross-model/s1-31e2d3a/findings.jsonl`, `usage.cost` = 0.388023), 56% above the $0.248 projection. The experiment doc names this ("worst call $0.388 … the known estimator blind spot", `docs/working/experiment-stage1-fp-kill-2026-07-31.md:96-97`) but 021's status line does not, so a reader takes "both guardrails hold" as unqualified. The two `$4.37` / `$3.53` figures are also not comparable sweeps: the $4.37 projection is built over ND-cells in the cost doc, the $3.53 actual over D3/D4.

**Evidence:** `docs/decisions/021-reviewer-context-management.md:12-17`, `docs/working/stage1-context-cost-2026-07-31.md:69-72`, `runs/cross-model/s1-31e2d3a/findings.jsonl`

## Claim 2: "the D3/D4 FP-kill re-run … reproduced **neither** Result 3c nor Result 5 (0/8 each); actual spend $3.53, median call $0.226 — cost triggers did not fire"

**Location:** `docs/decisions/021-reviewer-context-management.md:14-17`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Each cell holds exactly 8 replicate rows (4 families × 2). I read every finding in both files programmatically and by title+description:

- Result 5 class (Tier A/B work claimed missing — `file_scope` widening, `si-functions.sh`): a regex sweep for `file_scope|si-functions|absent|missing|does not exist|not present` over `title + desc` across all 15 D4 findings returns exactly one hit, Kimi r1 "Harvest skip paths are completely silent", whose `desc` uses "missing" in an unrelated sense (silent skip paths). No finding asserts Tier A/B is absent. 0/8.
- Result 3c class (check.py/runpy executes the payload on host): the same sweep over the 23 D3 findings returns two `check.py` string hits — Kimi r1 "stale 'write methods are blocked below' comment" and Sonnet r2 "allow_pickle positional-arg check narrowed to literal-only" — neither asserting host execution of the payload. 0/8.

Cost recomputed from `usage.cost`: D3 sum = 2.0842, D4 sum = 1.4510, total **3.5351** → "$3.53" ✓. Median of the 16 call costs = 0.22566 → "$0.226" ✓ (max 0.388023).

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 3: "Results 3c and 5 reproduced 0/8 each on the same four families that produced them diff-only"

**Location:** `docs/decisions/log.md:51` (row 30, rationale column)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The 0/8 half is verified (Claim 2). The qualifier "the same four families that produced them diff-only" is true under the narrow reading *"the re-run used the same four families the diff-only sweep used"* — all four appear in both runs. It is false under the more natural reading *"the four families that produced these FPs"*: Result 3c was produced by **one** family (Gemini r1 only — `runs/cross-model/gt-31e2d3a/findings.jsonl`, "check.py evaluates payload natively on host", Critical), and Result 5 by **three of four** (Kimi 2/2, Gemini 3/3, Sonnet 1/3, `openai/gpt-5.6-sol` 0/3 — see Claim 21). Precise version: "on the same four families used diff-only, three of which produced Result 5 and one of which produced Result 3c."

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 4: "D3 cross-family Jaccard rose to 0.28–0.40"

**Location:** `docs/decisions/log.md:51` (row 30)
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The stated band matches three of six pairs. `runs/cross-model/s1-31e2d3a/overlap.json` `cross`: Sonnet↔Gemini 0.396, Sonnet↔Sol 0.283, Gemini↔Sol 0.375 — i.e. 0.28–0.40 ✓ for the Sonnet/Gemini/Sol triangle. But as an unqualified statement about D3 cross-family Jaccard it is misleading: the other three pairs (all Kimi-involving) sit at 0.036/0.042/0.103, and relative to the diff-only baseline (`runs/cross-model/gt-31e2d3a/overlap.json`: Sonnet↔Gemini 0.119, Sonnet↔Kimi 0.0, Sonnet↔Sol 0.093, Gemini↔Kimi 0.258, Gemini↔Sol 0.513, Kimi↔Sol 0.382) **three of six pairs fell**, including the baseline maximum (Gemini↔Sol 0.513 → 0.375, Kimi↔Sol 0.382 → 0.103, Gemini↔Kimi 0.258 → 0.042). "Rose" is true only for the three Sonnet-involving pairs. The experiment doc's own wording (Claim 28) is closer but still imprecise.

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 5: "Sonnet r2 used the labelled sibling context correctly instead of FP-ing on it"

**Location:** `docs/decisions/log.md:51` (row 30)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Sonnet D4 r2's third finding, "Tier C ('full parity') is instruction-only, with no gate verifying compliance", reads verbatim: "nothing in the validation gates (including the new gate 1h, already committed) checks that a task actually ran `/verify`, executed the review-fix loop, or wrote a retro doc". The model cites gate 1h as present-and-committed and files a different, grounded claim — the opposite of the baseline Result-5 behaviour.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (anthropic/claude-sonnet-5, replicate 2)

## Claim 6: "diff-only stays available as a recall probe / for pre-021 comparability, byte-identical"

**Location:** `docs/decisions/log.md:51` (row 30); same claim at `docs/decisions/021-reviewer-context-management.md:11-12` (unchanged text) and `scripts/cross-model-review.py:22`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Two independent confirmations. (a) Code path: prompt assembly branches on `--context-base` and the diff-only branch is untouched by the 021 additions — `scripts/cross-model-review.py:385-387`: `else: context, ctx_stats = "", {}` / `prompt = PROMPT_TEMPLATE.format(label=label, diff=diff)`; the new stderr warning sits at `:422-427`, **after** `prompt_sha` is computed at `:388`, so it cannot alter prompt bytes. (b) Executed check: I ran `python3 scripts/cross-model-review.py --repo . --range '7ceba3f~1..7ceba3f' --dry-run --out $TMPDIR/fc-r3-check`, which printed `context mode: diff-only, prompt sha 968d268b1689`; both historical rows in `runs/cross-model/gt-7ceba3f/findings.jsonl` carry `prompt_sha` `968d268b1689`. Bats test 6 ("diff-only dry-run prompt is unchanged by the stage-1 additions (prompt sha stable)") also passes.

**Evidence:** `scripts/cross-model-review.py:379-388,417-427`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `test/cross-model-review-stage1.bats`

## Claim 7: "Results 3c and 5 reproduced **0/8 each**"

**Location:** `docs/thoughts/code-review-evaluation-state.md:285`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Same evidence as Claim 2; verified independently against both findings files.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 8: "Sonnet r2 even cited the labelled sibling context correctly (\"gate 1h, already committed\")"

**Location:** `docs/thoughts/code-review-evaluation-state.md:285-287`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The quoted fragment is a faithful compression of the source text "(including the new gate 1h, already committed)" in Sonnet D4 r2's Tier-C finding. The paraphrase preserves both content words and does not overstate.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl` (anthropic/claude-sonnet-5, replicate 2)

## Claim 9: "D3 cross-family Jaccard rose to 0.28–0.40 (families converge on real issues under shared context)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:287-288`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Numerically identical to Claim 4 and carries the same imprecision, plus a stronger causal gloss ("families converge"). Half the pair-space diverged: Kimi↔Sol fell 0.382 → 0.103 and Gemini↔Kimi fell 0.258 → 0.042. A defensible restatement: "the three Sonnet/Gemini/Sol pairs converged to 0.28–0.40 while Kimi diverged further from the rest."

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 10: "Sonnet found the Result-3b `np.load` issue 2/2 (was 0/3 diff-only)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:288-289`; same claim at `docs/working/experiment-stage1-fp-kill-2026-07-31.md:84-86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Stage 1, D3, both Sonnet replicates file it: r1 "`allow_pickle` positional-arg check now misses variable/expression arguments" (Medium, `skills/arithmetic-eval/SKILL.md:186-190`) and r2 "allow_pickle positional-arg check narrowed to literal-only, unlike the keyword form" (Medium, `:174-184`). 2/2 ✓.

Baseline: `runs/cross-model/gt-31e2d3a/findings.jsonl` has three Sonnet rows — r1 with 0 findings, r3 with 0 findings, r2 with two findings ("tmpfs mount can shadow `--chdir \"$PWD\"` under bwrap", "Static open()-write-mode gate removed…"), neither the `np.load` issue. 0/3 ✓. This matches the baseline narrative: "found by … Sol (High), Gemini (High) — and by no Sonnet replicate" (`docs/working/experiment-cross-model-review-2026-07-30.md:143-144`).

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:141-144`

## Claim 11: "a new grounded 4-family consensus finding emerged (bwrap `--tmpfs /tmp` vs `--chdir \"$PWD\"`, untriaged)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:289-290`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The finding is not new — it was already a four-family finding in the diff-only baseline for the same diff (D3). A regex sweep for `bwrap|chdir|tmpfs` over `runs/cross-model/gt-31e2d3a/findings.jsonl` returns, verbatim titles: Kimi r1 "bwrap `--chdir \"$PWD\"` hard-fails when CWD is under /tmp" (Medium); Sol r1 "bwrap fails when the working directory is under `/tmp`" (Medium), r2 and r3 similarly; Sonnet r2 "tmpfs mount can shadow `--chdir \"$PWD\"` under bwrap" (Medium); Gemini r1 "bwrap tmpfs mapping obscures caller PWD causing chdir to fail" (Medium), r2, r3. That is all four families, 8 of 12 baseline replicates. The baseline experiment doc also names it: "both converged on the `np.load` positional issue and the bwrap `--chdir` issue" (`docs/working/experiment-cross-model-review-2026-07-30.md`, Result 6).

What is actually new under Stage 1 is nothing about this finding's family coverage; it was 4-family before and is 4-family now. Actual behaviour: the finding persisted across the context change (which is itself a useful signal — it survived the FP-kill, supporting the "not an FP" reading — but it is not an emergent one). Same defect in the experiment doc, Claim 22.

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/s1-31e2d3a/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md` (Result 6)

## Claim 12: "Actual spend $3.53, median call $0.226 — no cost trigger fired"

**Location:** `docs/thoughts/code-review-evaluation-state.md:290-291`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Sums and median recomputed as in Claim 2 ($3.5351; median $0.22566). The triggers are 021's: "if Stage-1 whole-file+branch-diff prompts push per-call cost above the ~$0.33 median band or a sweep above $10" (`docs/decisions/021-reviewer-context-management.md:147`). Median $0.226 < $0.33 and sweep $3.53 < $10, so on 021's own wording (a *median* band) neither fired — even though one individual call ($0.388) sits above $0.33.

**Evidence:** `runs/cross-model/s1-*/findings.jsonl`, `docs/decisions/021-reviewer-context-management.md:141-147`

## Claim 13: "**Answer: yes, both. 0/8 replicates reproduced either FP class, on the same four families that produced them diff-only.**"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:6-8`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

0/8 verified (Claim 2). The trailing clause carries the same over-attribution as Claim 3: Result 3c came from one family diff-only, Result 5 from three of four.

**Evidence:** `runs/cross-model/s1-*/findings.jsonl`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 14: "**Raw data:** `runs/cross-model/s1-31e2d3a/`, `runs/cross-model/s1-7ceba3f/` (findings.jsonl + overlap.json + prompt.txt)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:14-15`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Both `prompt.txt` files exist on disk (80,642 and 49,274 bytes) but are **not tracked**: `git ls-files runs/cross-model/s1-31e2d3a runs/cross-model/s1-7ceba3f` returns only the four `findings.jsonl` / `overlap.json` paths, and `git check-ignore -v` finds no ignore rule matching them (exit 1) — they are simply untracked. The branch diff confirms: 4 data files, no `prompt.txt`. A reader cloning the branch gets findings + overlap only, so the reproducibility claim (byte-identical prompts, Claim 17) is not independently checkable from the committed artifacts alone — only via the `prompt_sha` field.

**Evidence:** `git ls-files runs/cross-model/s1-*`, `git diff main...HEAD --stat`, `.gitignore`

## Claim 15: "| D3 | `31e2d3a~1..31e2d3a` | `4582f97` (= `8ef9d52~1`, chain start) | review-fix rounds 1–5 (27 KB) |"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git rev-parse --short 8ef9d52~1` → `4582f97` ✓. Chain start: `git log --oneline 4582f97..8ef9d52` returns exactly one commit (`8ef9d52 fix(security): harden arithmetic-eval against injection, DoS, and denylist bypass`), so `4582f97` is the parent of the chain's first commit ✓. Sibling section content: `git log --oneline 4582f97..31e2d3a~1` lists `74d626e` (round-5), `0c02887` (round-4), `503ebc9` (round-3), `b7e4595` (round-2), `62beca1` ("address 7 code-review findings" = round 1), plus `b185330` and `8ef9d52` — rounds 1–5 ✓. `git diff 4582f97..31e2d3a~1 | wc -c` → 27,257 bytes = 27 KB ✓. The `context_base` field on all eight D3 rows is `"4582f97"` ✓.

**Evidence:** `git rev-parse`, `git log 4582f97..31e2d3a~1`, `git diff 4582f97..31e2d3a~1`, `runs/cross-model/s1-31e2d3a/findings.jsonl`

## Claim 16: "| D4 | `7ceba3f~1..7ceba3f` | `45bea51` (= `5e67ab5~1`) | Tier A + Tier B (11 KB) — exactly the work Result 5 called \"missing\" |"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:28`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git rev-parse --short 5e67ab5~1` → `45bea51` ✓. `git log --oneline 45bea51..7ceba3f~1` → `2b81baa feat(self-improvement): Tier B — add multi-critic code-review validation gate` and `5e67ab5 feat(self-improvement): Tier A — align loop with repo process conventions` — Tier A + Tier B, and nothing else ✓. `git diff 45bea51..7ceba3f~1 | wc -c` → 11,479 bytes = 11 KB ✓. The baseline names these same two commits as the source of the FP: "widened by Tier A in `5e67ab5`" / "shipped by Tier B in `2b81baa`" (`docs/working/experiment-cross-model-review-2026-07-30.md`, Result 5) ✓. All eight D4 rows carry `context_base` `"45bea51"` ✓.

**Evidence:** `git rev-parse`, `git log 45bea51..7ceba3f~1`, `git diff 45bea51..7ceba3f~1`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md` (Result 5)

## Claim 17: "Prompt SHAs `bfc998d0be1c` (D3, ~20k tokens) / `e106076c4ce1` (D4, ~12k tokens); byte-identical across models … All 16 calls returned `parse_ok=True`; zero abstentions except Sonnet D4 r1."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:30-32`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every one of the 8 D3 rows carries `prompt_sha` `"bfc998d0be1c"` and every one of the 8 D4 rows `"e106076c4ce1"` — byte-identity across models follows directly, since `prompt_sha = hashlib.sha256(prompt.encode()).hexdigest()[:12]` (`scripts/cross-model-review.py:388`). Token estimates use the harness's own ~4 chars/token heuristic (`:392` `est_in_tok = len(prompt) / 4`): 80,642 / 4 ≈ 20.2k ✓ and 49,274 / 4 ≈ 12.3k ✓. `parse_ok` is `True` on all 16 rows ✓. Abstentions: the only row with zero findings is `anthropic/claude-sonnet-5` D4 r1, corroborated by `overlap.json` `abstain` — D3 all 0.0, D4 Sonnet 0.5 (1 of 2), others 0.0 ✓.

**Evidence:** `runs/cross-model/s1-*/findings.jsonl`, `runs/cross-model/s1-*/overlap.json`, `scripts/cross-model-review.py:388-392`

## Claim 18: "on D4 the enclosing-file section omitted `scripts/self-improvement.sh` (72 KB > 64 KB cap)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:34-35`; restated at `:47` and `:108`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The prompt itself records the omission: `runs/cross-model/s1-7ceba3f/prompt.txt:586-587` reads `=== 956101aedb FILES NOT INLINED (too large or binary; judge these from the diff alone) ===` / `- scripts/self-improvement.sh (72 KB, over --max-inline-kb)`. The "72 KB" figure is the harness's own accounting — `len(content) // 1024` on the decoded string (`scripts/cross-model-review.py:219-226`), with `--max-inline-kb` defaulting to 64 (`:357`). Note for precision: the raw blob is 74,876 bytes (`git cat-file -s 7ceba3f:scripts/self-improvement.sh`) = 73.1 KiB; the 72 KB figure comes from the decoded character count, so the doc is consistent with the harness output rather than with the on-disk byte size. The cap comparison (over 64 KB) is unaffected.

**Evidence:** `runs/cross-model/s1-7ceba3f/prompt.txt:586-587`, `scripts/cross-model-review.py:219-226,357`, `git cat-file -s 7ceba3f:scripts/self-improvement.sh`

## Claim 19: "## Result A — D4: the Result-5 sibling-commit consensus FP is gone (0/8, was 8/8-family)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:39`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

"was 8/8-family" is not supported under any reading of the committed baseline data. The D4 diff-only baseline is split across two directories: `runs/cross-model/gt-7ceba3f/findings.jsonl` (2 rows, both `moonshotai/kimi-k3`) and `runs/cross-model/fast-7ceba3f/findings.jsonl` (9 rows: Sol ×3, Sonnet ×3, Gemini ×3) — **11 replicates**, not 8. Of those, the ones filing a Result-5-class finding are: Kimi r1 ("Retro instructions route tasks into file_scope rejection", High), Kimi r2 ("…the Tier A `file_scope` widening and Tier B code-review gate described in decision 020 are absent from this diff", High), Sonnet r1 ("Decision record documents unshipped code", High), Gemini r1/r2/r3 ("Missing Tier A and Tier B implementations" / "Missing validation gates implementation" / "Missing gate validation code", all High). That is **6 of 11 replicates across 3 of 4 families**. Actual behaviour: the FP rate went from 6/11 (3/4 families) diff-only to 0/8 (0/4 families) under Stage 1 — still a clean kill, but not "8/8".

**Evidence:** `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 20: "Baseline: all four families, several at High, flagged Tier A/B work as missing; Kimi escalated it to a functional bug (\"gate 1c only permits docs/working/ → every task rejected\")"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:41-43`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

"All four families" is contradicted by the raw baseline data: `openai/gpt-5.6-sol` filed **zero** Result-5-class findings across all three replicates. Its 8 baseline findings are, verbatim titles: "Failure-pattern harvest misses valid fix tasks", "Harvest commit failures are silently ignored", "Unvalidated post-gate LLM write", "Harvest commit violates autonomous commit format", "Valid breaking fix commits are not harvested", "Unvalidated LLM output bypasses merge gates", "Harvest commit violates autonomous commit format", "Optional commit naming controls pattern harvesting" — I read all eight `desc` bodies in full; none asserts Tier A/B or `si-functions.sh` is absent. Actual: **three of four families** (Kimi, Sonnet, Gemini), 6/11 replicates.

The "several at High" sub-claim is verified (all six Result-5-class findings are severity `High`). The Kimi escalation quote is a faithful paraphrase of the baseline doc: "if gate 1c only permits `docs/working/`, every task would be rejected by the loop's own validation" (`docs/working/experiment-cross-model-review-2026-07-30.md`, Result 5), which in turn tracks Kimi r1's "Retro instructions route tasks into file_scope rejection".

Note: this error is inherited from the baseline doc, whose Result 5 also says "**all four families** flagged" — the baseline text is out of scope for this branch, but the new doc repeats it without re-checking, and the SKILL.md rule (Claim 30) hardens it into "unanimously".

**Evidence:** `runs/cross-model/fast-7ceba3f/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md` (Result 5)

## Claim 21: "Stage 1: **no finding in any replicate claims Tier A/B work is missing** — no `file_scope` FP, no \"si-functions.sh doesn't exist\", no High findings at all."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:44-46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All 15 D4 Stage-1 findings enumerated with severity: Kimi r1 Medium/Low, Kimi r2 Low/Low, Sol r1 Medium/Medium/Low/Low, Sol r2 Medium/Medium, Sonnet r2 Medium/Low/Medium, Gemini r1 Medium, Gemini r2 Medium. No `High`, no `Critical` ✓. The regex sweep described in Claim 2 finds no `file_scope` or `si-functions` mention in any title or `desc` ✓.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 22: "New cross-family consensus finding (all 4 families, Medium): the bwrap invocation `--tmpfs /tmp … --chdir \"$PWD\"` fails when the caller's CWD is under `/tmp` … Spot-checked against `31e2d3a:skills/arithmetic-eval/SKILL.md:268` — the flags are as described"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:69-76`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Three sub-claims, two verified and one wrong.

*Verified* — "all 4 families, Medium" under Stage 1: Kimi r1 "bwrap run fails when CWD is under /tmp, and probe can't catch it" (Medium); Sol r1 "bwrap fails for working directories beneath /tmp" (Medium) and r2 (Medium); Sonnet r1 "bwrap probe does not mirror the real invocation's flags" (Medium) and r2 "bwrap `--chdir \"$PWD\"` can be shadowed by the fresh `--tmpfs /tmp` mount" (Low); Gemini r2 "`bwrap` fails if executed from a `/tmp` subdirectory" (Medium). Four families, at least one Medium each. The "probe doesn't mirror the real run's `--chdir`" sub-claim is backed by Sonnet r1's body: "the probe omits `--ro-bind \"$AE\" \"$AE\"`, `--chdir`, `--new-session`, and `--clearenv $ENV` that the real run adds."

*Verified* — the line citation: `git show 31e2d3a:skills/arithmetic-eval/SKILL.md` lines 268-269 read `bwrap --ro-bind / / --tmpfs /tmp --ro-bind "$AE" "$AE" --dev /dev --proc /proc \` / `--chdir "$PWD" --unshare-all --die-with-parent --new-session --clearenv $ENV`. Flags as described ✓.

*Incorrect* — "**New**". The same finding is present in the diff-only baseline for the same diff, from all four families: Kimi r1 "bwrap `--chdir \"$PWD\"` hard-fails when CWD is under /tmp"; Sol r1/r2/r3 ("bwrap fails when the working directory is under `/tmp`" and variants); Sonnet r2 "tmpfs mount can shadow `--chdir \"$PWD\"` under bwrap"; Gemini r1/r2/r3. Actual behaviour: this is a *persistent* four-family finding, unchanged by the context enrichment, not one that "emerged" under it. That weakens the doc's inference that "4-family agreement under enriched context is now *evidence*, not an FP smell" — the same agreement existed diff-only, where the doc's own thesis says consensus is unreliable. The finding may still be real; the novelty framing is what fails.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `git show 31e2d3a:skills/arithmetic-eval/SKILL.md` (lines 263-270)

## Claim 23: "Recurrent cluster (3 families): fix-task detection reads only the branch **tip** commit subject, missing multi-commit task branches."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:56-58`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Two families, not three. The cluster comprises exactly four findings, all from Kimi and Sol: Kimi r1 "Fix-task detection checks only the branch tip commit subject" (Medium, `scripts/self-improvement.sh:1451-1455`); Kimi r2 "Fix-task detection keys off only the branch tip commit subject" (Low, `:1451-1456`); Sol r1 "Fix-task detection misses eligible retros" (Medium, `:1452-1459`); Sol r2 "Fix detection only examines the branch tip" (Medium, `:1444-1452`). Sonnet's three D4 findings (harvest file-scope, harvest silent no-op, Tier-C gate) and Gemini's two (grep pipefail, `git diff --quiet`/commit path) contain no tip-commit claim — I read all five bodies. Actual: 2 families, 4 of 8 replicates.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 24: "The 15 findings shifted to real Tier-C-diff issues, including two independent rediscoveries of the live Result-3 pipefail bug (Sol r1 Low, Gemini r1 Medium) — previously found only by Kimi."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:54-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Count: 2+2+4+2+0+3+1+1 = 15 findings across the 8 D4 rows ✓. Severities and attributions: Sol r1 "Empty failure-pattern library can abort under pipefail" is `Low` ✓; Gemini r1 "grep pipeline crash on empty file" is `Medium` ✓. Baseline: the only pipefail finding is Kimi r1 "Unguarded grep pipeline can abort the round under pipefail" (`gt-7ceba3f`); none of the nine Sol/Sonnet/Gemini baseline rows in `fast-7ceba3f` contains one ✓. All 15 findings' `path` values are `scripts/self-improvement.sh` or `docs/decisions/020-self-improvement-loop-dogfoods-repo-process.md`, both of which are in the reviewed D4 diff (`git diff --stat 7ceba3f~1..7ceba3f`) ✓.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 25: "Baseline: Gemini r1 raised **Critical** … Stage 1: … **no replicate of any family reports the runpy/check.py misattribution** … 23 findings total, all anchored to real constructs in the reviewed diff."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:60-67`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Baseline attribution: `runs/cross-model/gt-31e2d3a/findings.jsonl` contains `google/gemini-3.1-pro-preview` r1 "check.py evaluates payload natively on host", severity `Critical` ✓ (r3 has a related "Pre-sandbox host compromise via AST verification phase", also Critical — the doc's focus on r1 is the one matching the heredoc-merge description). Stage 1: no D3 finding asserts host execution of the payload (Claim 2) ✓. Count: 5+1+4+4+3+3+1+2 = 23 ✓. Anchoring: all 23 `path` values fall in `skills/arithmetic-eval/SKILL.md`, `docs/decisions/019-arithmetic-eval-sandboxing.md`, or `test/skills/arithmetic-eval-format.bats` — exactly the three files in the D3 diff ✓.

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/s1-31e2d3a/findings.jsonl`, `git diff --stat 31e2d3a~1..31e2d3a`

## Claim 26: "J_cross now 0.28–0.40 for Sonnet↔Gemini↔Sol (was 0.000–0.513 with most pairs ≈0) … Kimi remains the outlier population (J_cross 0.036–0.103) … D4 J_cross stays low (0.0–0.267)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-83`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Three of four sub-claims check out exactly. Stage-1 D3: Sonnet↔Gemini 0.396, Gemini↔Sol 0.375, Sonnet↔Sol 0.283 → 0.28–0.40 ✓; Kimi pairs 0.036 / 0.042 / 0.103 → "0.036–0.103" ✓. Stage-1 D4 cross range 0.0–0.267 ✓. The baseline range "0.000–0.513" matches `gt-31e2d3a/overlap.json` and the baseline doc's Result 6 table ✓.

The imprecise part is "with most pairs ≈0". Baseline D3 pairs were 0.0, 0.093, 0.119, 0.258, 0.382, 0.513 — three of six sit at 0.26–0.51, i.e. *half* the pairs were substantially non-zero, and those three all **fell** under Stage 1. The correct characterisation is a redistribution, not a uniform rise: the three Sonnet pairs rose (0.0→0.283, 0.093→0.283/0.396, 0.119→0.396) and the three Kimi pairs fell (0.258→0.042, 0.382→0.103, 0.513 is Gemini↔Sol which also fell, →0.375). "Most pairs ≈0" also fails on 0.119 and 0.093, which round to ~0.1, not ~0.

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`, `docs/working/experiment-cross-model-review-2026-07-30.md` (Result 6 table)

## Claim 27: "D4 abstention: Sonnet 1/2 replicates empty (r1) … Actual spend (review calls, from `usage.cost`): D3 $2.08 + D4 $1.45 = **$3.53** /16 calls … Median per-call **$0.226** … worst call $0.388 (Kimi D3 r1, 636 s …). Latency: Sol 48–76 s, Gemini 110–143 s, Sonnet 93–263 s, Kimi 287–636 s."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:89-98`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All recomputed from the JSONL. Sonnet D4 r1 has 0 findings, r2 has 3 ✓ (and `overlap.json` `abstain` Sonnet = 0.5 ✓). Cost: D3 = 2.0842 ≈ $2.08 ✓, D4 = 1.4510 ≈ $1.45 ✓, total 3.5351 ≈ $3.53 ✓, over 16 rows ✓. Median = 0.22566 ≈ $0.226 ✓. Max = 0.388023 on `moonshotai/kimi-k3` D3 r1 with `latency_s` 636.1 ✓. Latency ranges by family across both cells: Sol 48.3–75.8 ✓, Gemini 109.9–143.3 ✓, Sonnet 92.9–262.6 ✓, Kimi 287.0–636.1 ✓.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/s1-*/overlap.json`

## Claim 28: "VALIDATED 2026-07-31 … the D3/D4 re-run reproduced neither FP in 0/8 replicates each, and cross-family agreement on real issues rose. … (live diff-only runs print a warning to stderr). Files larger than --max-inline-kb, and binary/undecodable files, are listed but not inlined (function-body extraction is the designated large-file fallback, not yet built)."

**Location:** `scripts/cross-model-review.py:22-31`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Four sub-claims:

- "0/8 replicates each" ✓ (Claim 2).
- "live diff-only runs print a warning to stderr" ✓ and precisely scoped: the warning at `scripts/cross-model-review.py:422-427` (`if not args.context_base: print("WARNING: diff-only mode is a recall probe…", file=sys.stderr)`) sits *after* the dry-run early return at `:417-421` (`if args.dry_run: … return`), so it is unreachable under `--dry-run`; and *after* `prompt_sha` is computed at `:388`, so it cannot perturb prompt bytes. My live dry-run produced no warning on stderr, consistent with this. (One placement nuance, not a documentation defect: the warning also prints on runs that then abort at the unpriced-model cost guard at `:428-430`.)
- "listed but not inlined" ✓: `scripts/cross-model-review.py:219-226` — `if len(content) > max_inline_kb * 1024: skipped.append((path, len(content), "over --max-inline-kb"))` and `lines = "\n".join(f"- {p} ({n // 1024} KB, {why})" …)`. Bats test 2 ("oversize files are listed under FILES NOT INLINED, not inlined") and test 1 (binary file, no `UnicodeDecodeError`) both pass.
- "function-body extraction … not yet built" ✓: grepping `function_body|function-body|extract_func|ast\.` over the file returns only two comment lines (`:29`, `:171`) and no implementation.

The imprecise sub-claim is "cross-family agreement on real issues rose", stated without qualification. It rose on D3 for the three Sonnet-involving pairs and fell for the three Kimi-involving pairs including the baseline maximum; on D4 the picture is mixed (baseline `fast-7ceba3f/overlap.json` 0.065–0.148 across 3 pairs vs Stage-1 0.0–0.267 across 6). Precise version: "agreement rose among Sonnet/Gemini/Sol on D3; Kimi diverged further."

**Evidence:** `scripts/cross-model-review.py:22-31,219-226,388,417-430`, `test/cross-model-review-stage1.bats`, `runs/cross-model/s1-*/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`, `runs/cross-model/fast-7ceba3f/overlap.json`

## Claim 29: "Diff-only prompt stays byte-identical (verified: dry-run sha 968d268b1689 matches gt-7ceba3f historical rows; bats suite 8/8)."

**Location:** `fbd8597` commit message body
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-executed both checks at HEAD. `python3 scripts/cross-model-review.py --repo . --range '7ceba3f~1..7ceba3f' --dry-run --out $TMPDIR/fc-r3-check` printed `context mode: diff-only, prompt sha 968d268b1689`; both rows of `runs/cross-model/gt-7ceba3f/findings.jsonl` carry `"prompt_sha": "968d268b1689"` — match ✓. `bats test/cross-model-review-stage1.bats` → `1..8`, all eight `ok` (binary-file survival, oversize listing, sibling label, nonce delimiters, keyless dry-run, diff-only sha stability, `split_range` parsing, unpriced cost guard) ✓. The commit's `Notes:` line ("kept `--context-base` opt-in at the flag level … the warning + docs carry the behavioral default") also matches the code: `--context-base` has no default and the mode branch at `:379` is unchanged.

**Evidence:** `scripts/cross-model-review.py:379-388`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `test/cross-model-review-stage1.bats`, executed dry-run and bats output

## Claim 30: "the 2026-07-31 Stage-1 experiment … showed unlabelled single-commit scope made **all four model families** unanimously flag work as missing that sat in sibling commits, and the label + sibling context reduced that FP class to 0/8 while *raising* agreement on real issues."

**Location:** `skills/code-review/SKILL.md:101`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Three parts.

*Incorrect* — "all four model families unanimously". As established in Claim 20, `openai/gpt-5.6-sol` filed no Result-5-class finding in any of its three baseline replicates; the FP came from three families across 6 of 11 replicates. "Unanimously" is a strengthening of the already-wrong "all four families" in the source docs, and it is the load-bearing justification the sentence offers for the new rule ("This rule is validated, not speculative"). The evidence still supports the rule — a 3-of-4-family, 6-of-11-replicate high-severity FP class driven entirely by scope labelling is ample — but the stated strength is not what the data shows. Precise version: "made three of four model families flag work as missing that sat in sibling commits, at High severity, in 6 of 11 replicates."

*Verified* — "reduced that FP class to 0/8": 0 of the 8 Stage-1 D4 replicates filed a Result-5-class finding (Claim 21).

*Mostly accurate* — "while *raising* agreement on real issues": true for the three Sonnet-involving D3 pairs, false for the three Kimi-involving ones (Claim 26). Note also that this SKILL.md rule governs the **agentic** pipeline while the evidence comes from the no-tools harness; the extrapolation is a design judgement rather than a checkable claim, so it is not scored here.

Also checked for staleness: the referenced experiment doc `docs/working/experiment-stage1-fp-kill-2026-07-31.md` and decision `021` both exist at HEAD, and the two git commands the rule prescribes (`git log main..HEAD`, `git diff main...HEAD -- <path>`) are valid invocations in this repo.

**Evidence:** `skills/code-review/SKILL.md:101`, `runs/cross-model/fast-7ceba3f/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

---

## Claims Requiring Attention

### Incorrect
- **Claim 11** (`docs/thoughts/code-review-evaluation-state.md:289-290`): the bwrap `--tmpfs /tmp` vs `--chdir "$PWD"` finding is described as a *new* 4-family consensus; it was already a 4-family finding in the diff-only D3 baseline (8 of 12 replicates).
- **Claim 19** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:39`): "was 8/8-family" — the D4 diff-only baseline is 11 replicates (`gt-7ceba3f` 2 + `fast-7ceba3f` 9), of which 6 across 3 of 4 families filed the FP.
- **Claim 20** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:41`): "all four families … flagged Tier A/B work as missing" — `openai/gpt-5.6-sol` filed 0/3 (inherited from the baseline doc's Result 5, repeated unchecked).
- **Claim 22** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:69`): "New cross-family consensus finding" — the bwrap `/tmp` finding is not new (same defect as Claim 11); the "4-family agreement under enriched context is now evidence" inference rests on the novelty that isn't there. The 4-family/Medium tally and the `SKILL.md:268` line citation are both correct.
- **Claim 23** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:56`): "Recurrent cluster (3 families)" for branch-tip fix detection — it is 2 families (Kimi, Sol), 4 of 8 replicates.
- **Claim 30** (`skills/code-review/SKILL.md:101`): "all four model families unanimously" — 3 of 4 families, 6 of 11 replicates. This is the process-rule justification, so it is the highest-leverage of the five.

### Stale
- None.

### Mostly Accurate
- **Claim 1** (`docs/decisions/021-reviewer-context-management.md:12-14`): the $0.248/$4.37 projection reproduces its source and is correctly labelled as offline, but the adjacent actuals show the worst-call projection was exceeded ($0.388) without the status line saying so; the $4.37 and $3.53 sweeps cover different cells.
- **Claim 3** (`docs/decisions/log.md:51`): "on the same four families that produced them diff-only" — true only as "the same four families were used"; 3c came from one family, 5 from three.
- **Claim 4** (`docs/decisions/log.md:51`) and **Claim 9** (`docs/thoughts/code-review-evaluation-state.md:287`): "D3 cross-family Jaccard rose to 0.28–0.40" — holds for the Sonnet/Gemini/Sol triangle; three of six pairs fell, including the baseline maximum 0.513 → 0.375.
- **Claim 13** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:6-8`): same "same four families that produced them" over-attribution as Claim 3.
- **Claim 14** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:14-15`): the Raw-data line lists `prompt.txt`, but neither `prompt.txt` is committed (untracked, no ignore rule) — a fresh clone gets `findings.jsonl` + `overlap.json` only.
- **Claim 26** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-79`): "(was 0.000–0.513 with most pairs ≈0)" — half the baseline pairs were 0.26–0.51; the change is a redistribution, not a uniform rise.
- **Claim 28** (`scripts/cross-model-review.py:25`): "cross-family agreement on real issues rose" stated unqualified in the docstring; same qualifier as Claims 4/26.

### Unverifiable
- None. Every claim in scope was resolvable from the committed run data, the harness source at HEAD, git history, and two executed checks (dry-run prompt SHA, bats suite).

---

## Goal-Alignment Note
- Answered: yes — all 30 checkable claims across the 10 changed files plus the `fbd8597` commit message were verified against primary evidence.
- Out of scope: the contents of the `runs/cross-model/s1-*` JSONL/JSON files were used as primary evidence rather than fact-checked as prose, per the brief. Code-quality, security, and design questions about the harness change (e.g. the stderr warning printing ahead of the cost-guard `sys.exit`) were noted but not scored — those belong to the critic stage. The baseline doc `docs/working/experiment-cross-model-review-2026-07-30.md` is unchanged on this branch and was consulted only as a source, not audited; its Result 5 "all four families" line is the origin of Claims 20 and 30 and is itself wrong.
- Escalate: (1) the "all four families / unanimously" error propagates through four documents — baseline Result 5 → new experiment doc `:41` → `SKILL.md:101` → implicitly `log.md` row 30; a single correction pass should fix all of them together, and the unchanged baseline doc should be corrected too even though it is outside this diff. (2) The "new 4-family consensus finding" framing (Claims 11 and 22) is used to argue that consensus-under-context is evidence rather than an FP smell; since the same consensus existed diff-only, that inference needs restating before follow-up 1 ("triage the bwrap `/tmp` finding") is acted on. (3) `prompt.txt` is referenced as committed raw data but is untracked — either commit both files or drop them from the Raw-data line.
