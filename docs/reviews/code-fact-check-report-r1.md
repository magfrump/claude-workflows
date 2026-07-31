# Code Fact-Check Report

**Commit:** fbd8597
**Repository:** `/workspace/.claude/worktrees/cross-model-review-sweep` (branch `exp/cross-model-openrouter-sweep`)
**Scope:** branch diff `git diff main...HEAD` — 10 files, +207/−7. Prose/doc/docstring claims in `docs/decisions/021-reviewer-context-management.md`, `docs/decisions/log.md`, `docs/thoughts/code-review-evaluation-state.md`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md`, `scripts/cross-model-review.py`, `skills/code-review/SKILL.md`. The `runs/cross-model/s1-*` JSONL/JSON artifacts are treated as machine-generated primary evidence, not as prose under check.
**Checked:** 2026-07-31
**Total claims checked:** 27
**Summary:** 16 verified, 6 mostly accurate, 0 stale, 5 incorrect, 0 unverifiable

**Hallucination pattern log:** `docs/reviews/hallucination-patterns.md` exists; its `## Patterns` section is empty (line 24 is the append marker with no entries below it). No logged pattern could match, so no claim in this run is flagged as a repeat pattern.

---

## Claim 1: "**Validated 2026-07-31**: the D3/D4 FP-kill re-run (…4 families × 2 replicates/cell) reproduced **neither** Result 3c nor Result 5 (0/8 each); actual spend $3.53, median call $0.226 — cost triggers did not fire."

**Location:** `docs/decisions/021-reviewer-context-management.md:14-17`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The run artifacts contain exactly 16 rows (8 per cell), 4 distinct `model` values × 2 `replicate` values in each of `runs/cross-model/s1-31e2d3a/findings.jsonl` and `runs/cross-model/s1-7ceba3f/findings.jsonl` — matching "4 families × 2 replicates/cell".

Result-3c class (the `check.py`/`runpy` host-execution misattribution): I read all 23 D3 findings. None asserts that `check.py` executes the payload on the host. The nearest D3 security claims are Kimi r1 `"confine.py exec-neutering misses the underlying spawn primitive"` (about `_posixsubprocess.fork_exec`) and Sol r1 `"Process confinement is trivially bypassable outside bwrap"` (about `numpy.ctypeslib.ctypes.CDLL(None).system(...)`) — both anchored to real constructs, neither the heredoc merge. 0/8 confirmed.

Result-5 class (Tier A/B work claimed missing): I read all 15 D4 findings. None claims `file_scope` widening or `si-functions.sh` is absent. The one finding that mentions file scope is Sonnet r2's `"Harvest \`claude -p\` call has no file-scope restriction…"`, which explicitly *contrasts* the harvest prompt with `"the per-task implement prompt (which enforces an explicit FILE SCOPE CONSTRAINT)"` — i.e. it affirms the Tier-A work exists. 0/8 confirmed.

Cost: recomputed from `usage.cost` — D3 sum $2.08417, D4 sum $1.45096, total $3.53512; median of the 16 values $0.22566. "$3.53" and "$0.226" both hold (the total is the sum of the two rounded cell figures; the unrounded total rounds to $3.54 — immaterial).

**Evidence:** `docs/decisions/021-reviewer-context-management.md:11-17`, `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 2: "offline cost measurement in `docs/working/stage1-context-cost-2026-07-31.md` (worst call $0.248, sweep $4.37: both guardrails hold)" — sitting immediately beside the new actuals

**Location:** `docs/decisions/021-reviewer-context-management.md:11-17`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The two number sets are separately attributed and not conflated: the projection is introduced as "offline cost measurement in `docs/working/stage1-context-cost-2026-07-31.md`", the actuals as "actual spend $3.53, median call $0.226". Both match their sources. The cost doc states `"the priciest single call is $0.248 (Sol on ND2), under the ~$0.33 median band trigger; the full-sweep projection $4.37 is under the $10 trigger"` (`docs/working/stage1-context-cost-2026-07-31.md:71-72`).

One unstated tension worth the author's attention (not an inaccuracy in the text as written): the actual worst call was $0.388 (Kimi D3 r1), 56% above the $0.248 projection. The experiment doc does record this ("worst call $0.388 … the known estimator blind spot"); the 021 status line does not, so a reader skimming only 021 sees "worst call $0.248" with no signal that the live worst exceeded it.

**Evidence:** `docs/decisions/021-reviewer-context-management.md:11-17`, `docs/working/stage1-context-cost-2026-07-31.md:69-72`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md:94-97`, `runs/cross-model/s1-31e2d3a/findings.jsonl` (`usage.cost` = 0.388023, `latency_s` = 636.1 for Kimi r1)

## Claim 3: "Results 3c and 5 reproduced 0/8 each on the same four families that produced them diff-only"

**Location:** `docs/decisions/log.md:51`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The 0/8 halves are verified (Claim 1). "the same four families" is accurate as a statement about which families were re-run — the baseline sweep and the s1 re-run both used `moonshotai/kimi-k3`, `openai/gpt-5.6-sol`, `anthropic/claude-sonnet-5`, `google/gemini-3.1-pro-preview`.

It is imprecise as a statement about which families *produced* the two FPs. Result 3c was produced by **one replicate of one family** — the baseline record is a single Gemini r1 row, `"Critical | check.py evaluates payload natively on host"` (`runs/cross-model/gt-31e2d3a/findings.jsonl`), and the baseline doc says so: `"Gemini r1 on D3 reported **Critical: \"check.py evaluates payload natively on host\"**"` (`docs/working/experiment-cross-model-review-2026-07-30.md:178-180`). Result 5 was produced by three of the four families (see Claim 12). Precise version: "on the same four families that were swept diff-only, three of which produced Result 5 and one of which produced Result 3c."

**Evidence:** `docs/decisions/log.md:51`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:176-186`

## Claim 4: "D3 cross-family Jaccard rose to 0.28–0.40"

**Location:** `docs/decisions/log.md:51`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`runs/cross-model/s1-31e2d3a/overlap.json` `cross` values: Sonnet↔Gemini 0.396, Sonnet↔Sol 0.283, Gemini↔Sol 0.375, plus the three Kimi pairs at 0.036/0.042/0.103. The 0.28–0.40 band exactly brackets the three non-Kimi pairs, and the log row correctly scopes the claim to D3 (unlike the SKILL.md and docstring phrasings — Claims 24 and 21).

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`

## Claim 5: "Sonnet r2 used the labelled sibling context correctly instead of FP-ing on it"

**Location:** `docs/decisions/log.md:51`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The Sonnet D4 r2 finding reads: `"nothing in the validation gates (including the new gate 1h, already committed) checks that a task actually ran /verify, executed the review-fix loop, or wrote a retro doc"` (`runs/cross-model/s1-7ceba3f/findings.jsonl`, `anthropic/claude-sonnet-5` replicate 2, third finding). It treats gate 1h as present-and-committed and makes a different, grounded claim — the inversion the row describes.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 6: "`code-review` SKILL Step 1 gains a partial-scope rule — `--range`/`--staged`/`--files` reviews must label out-of-scope branch work"

**Location:** `docs/decisions/log.md:51`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`skills/code-review/SKILL.md:101` contains exactly that rule, added in this diff, in the Step 1 scope-determination section (it follows the "Accept user overrides" / "Do not paste the full diff into agent prompts" paragraphs and precedes "#### Large diff triage").

**Evidence:** `skills/code-review/SKILL.md:98-103`, `docs/decisions/log.md:51`

## Claim 7: "Sonnet r2 even cited the labelled sibling context correctly (\"gate 1h, already committed\")"

**Location:** `docs/thoughts/code-review-evaluation-state.md:285-287`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The quoted fragment is verbatim-contiguous in the source finding: `"(including the new gate 1h, already committed)"` (`runs/cross-model/s1-7ceba3f/findings.jsonl`, Sonnet replicate 2). The paraphrase is faithful.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 8: "Sonnet found the Result-3b `np.load` issue 2/2 (was 0/3 diff-only)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:288-289`; duplicated at `docs/working/experiment-stage1-fp-kill-2026-07-31.md:84-85`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Both Sonnet D3 replicates in the s1 run file an `allow_pickle` positional finding: r1 `"\`allow_pickle\` positional-arg check now misses variable/expression arguments"`, r2 `"allow_pickle positional-arg check narrowed to literal-only, unlike the keyword form"` (`runs/cross-model/s1-31e2d3a/findings.jsonl`). 2/2 confirmed.

The 0/3 baseline is confirmed directly from the raw diff-only data rather than only from the narrative: `runs/cross-model/gt-31e2d3a/findings.jsonl` has three Sonnet rows — r1 with zero findings, r2 with two findings (`"tmpfs mount can shadow --chdir \"$PWD\" under bwrap"`, `"Static open()-write-mode gate removed…"`), r3 with zero findings. No `np.load` finding in any. This corroborates the baseline narrative `"Found by three families across seven replicates … and by no Sonnet replicate"` (`docs/working/experiment-cross-model-review-2026-07-30.md:143-144`).

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/gt-31e2d3a/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:141-144`

## Claim 9: "a **new** grounded 4-family consensus finding emerged (bwrap `--tmpfs /tmp` vs `--chdir \"$PWD\"`, untriaged)"

**Location:** `docs/thoughts/code-review-evaluation-state.md:289-290`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

The 4-family agreement under enriched context is real, but the finding is **not new** — all four families already reported it in the diff-only baseline on the same commit. From `runs/cross-model/gt-31e2d3a/findings.jsonl`:

- Kimi r1: `"bwrap \`--chdir \"$PWD\"\` hard-fails when CWD is under /tmp"` (Medium)
- Sol r1/r2/r3: `"bwrap fails when the working directory is under \`/tmp\`"` / `"bwrap hides working directories under /tmp"` ×2 (Medium)
- Sonnet r2: `"tmpfs mount can shadow \`--chdir \"$PWD\"\` under bwrap"` (Medium)
- Gemini r1/r2/r3: `"bwrap tmpfs mapping obscures caller PWD causing chdir to fail"` (Medium), `"Sandbox start failure when execution runs within \`/tmp\`"` (Medium), `"Bwrap crashes when executing from within host's \`/tmp\`"` (Low)

Actual behavior: the finding *persisted* across both context modes with 4-family agreement in each. That is arguably a stronger result for the "consensus under enriched context is evidence" argument, but "new" is contradicted by the baseline artifact. The same error appears in the experiment doc (Claim 19).

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/s1-31e2d3a/findings.jsonl`, `docs/thoughts/code-review-evaluation-state.md:287-291`

## Claim 10: "Actual spend $3.53, median call $0.226 — no cost trigger fired."

**Location:** `docs/thoughts/code-review-evaluation-state.md:290-291`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Recomputed sums and median as in Claim 1. The two live triggers named by the cost doc are a ~$0.33 *median* band trigger and a $10 sweep trigger (`docs/working/stage1-context-cost-2026-07-31.md:71-72`); median $0.2257 and sweep $3.535 clear both. (The worst single call, $0.388, exceeds $0.33, but that threshold is defined on the median, so "no cost trigger fired" holds as written.)

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `docs/working/stage1-context-cost-2026-07-31.md:69-72`

## Claim 11: "`4582f97` (= `8ef9d52~1`, chain start)" and "`45bea51` (= `5e67ab5~1`)"; sibling sections of 27 KB / 11 KB

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:27-28`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git rev-parse --short=7` resolves `8ef9d52~1` → `4582f97` and `5e67ab5~1` → `45bea51` (paraphrased — no quote available because this is command output, not file text). `git log --oneline 4582f97..31e2d3a` shows `8ef9d52` as the oldest commit in the chain, so "chain start" holds. Sibling diff sizes: `git diff 4582f97..31e2d3a~1` = 27,257 bytes (26.6 KiB → "27 KB"); `git diff 45bea51..7ceba3f~1` = 11,479 bytes (11.2 KiB → "11 KB"). Both stamped `context_base` fields in the JSONL agree (`4582f97` on all 8 D3 rows, `45bea51` on all 8 D4 rows).

**Evidence:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:25-28`, `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, git history

## Claim 12: "sibling section contains … Tier A + Tier B (11 KB) — exactly the work Result 5 called \"missing\""

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:28`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`git log --oneline 45bea51..7ceba3f` yields exactly three commits: `5e67ab5 feat(self-improvement): Tier A — align loop with repo process conventions`, `2b81baa feat(self-improvement): Tier B — add multi-critic code-review validation gate`, `7ceba3f` (the reviewed commit). The sibling range `45bea51..7ceba3f~1` is therefore precisely Tier A + Tier B. Baseline Result 5 names those two commits as the location of the supposedly-missing work: `"widened by Tier A in \`5e67ab5\`"` and `"shipped by Tier B in \`2b81baa\`"` (`docs/working/experiment-cross-model-review-2026-07-30.md:230-232`).

**Evidence:** git history, `docs/working/experiment-cross-model-review-2026-07-30.md:227-233`

## Claim 13: "sibling section contains … review-fix rounds 1–5 (27 KB)" (D3)

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The D3 sibling range `4582f97..31e2d3a~1` contains seven commits, of which five are review-fix rounds (`62beca1 fix(security): address 7 code-review findings…`, `b7e4595 … close round-2 findings`, `503ebc9 … close round-3 findings`, `0c02887 … close round-4 findings`, `74d626e fix(correctness): close round-5 findings`) and two are the original feature commits (`8ef9d52 fix(security): harden arithmetic-eval…`, `b185330 feat(security): add tiered OS confinement…`). Precise version: "the two original hardening commits plus review-fix rounds 1–5". The 27 KB figure is verified (Claim 11).

**Evidence:** git history (`git log --oneline 4582f97..31e2d3a`), `docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`

## Claim 14: "Prompt SHAs `bfc998d0be1c` (D3, ~20k tokens) / `e106076c4ce1` (D4, ~12k tokens); byte-identical across models"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:30-31`
**Type:** Configuration / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All 8 D3 rows carry `"prompt_sha": "bfc998d0be1c"` and all 8 D4 rows carry `"prompt_sha": "e106076c4ce1"` — a single sha per cell across all four models is exactly the byte-identity invariant. Token estimate: the harness uses a 4-chars/token heuristic (`scripts/cross-model-review.py:390` comment `"cost guard: ~4 chars/token heuristic on input"`); `runs/cross-model/s1-31e2d3a/prompt.txt` is 80,642 bytes → ~20.2k tokens, `runs/cross-model/s1-7ceba3f/prompt.txt` is 49,274 bytes → ~12.3k tokens. Both match.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/s1-*/prompt.txt`, `scripts/cross-model-review.py:388-400`

## Claim 15: "All 16 calls returned `parse_ok=True`; zero abstentions except Sonnet D4 r1."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:32`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All 16 rows have `"parse_ok": true`. Exactly one row has zero findings — `anthropic/claude-sonnet-5` replicate 1 in `s1-7ceba3f` (`n_findings` 0). The judge-side `abstain` map corroborates: D3 all four families 0.0; D4 `"anthropic/claude-sonnet-5": 0.5` with the other three at 0.0 (`runs/cross-model/s1-7ceba3f/overlap.json`).

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/s1-7ceba3f/overlap.json`

## Claim 16: "on D4 the enclosing-file section omitted `scripts/self-improvement.sh` (72 KB > 64 KB cap)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:34-35`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The omission is real and the reported size matches the prompt verbatim: `runs/cross-model/s1-7ceba3f/prompt.txt:586-587` reads `=== 956101aedb FILES NOT INLINED (too large or binary; judge these from the diff alone) ===` / `- scripts/self-improvement.sh (72 KB, over --max-inline-kb)`. The 64 KB cap is the documented default: `ap.add_argument("--max-inline-kb", type=int, default=64, …)` (`scripts/cross-model-review.py:357`).

The imprecision: the harness's "KB" is *decoded characters* ÷ 1024, not bytes — `f"- {p} ({n // 1024} KB, {why})"` where `n = len(content)` (`scripts/cross-model-review.py:220-227`). The file at `7ceba3f` is 74,876 bytes (73.1 KiB) per `git cat-file -s`; the 72 KB figure reflects ~1,100 multi-byte characters. Immaterial to the conclusion (either measure exceeds the 64 KB cap), but the doc reads as if 72 KB were the file size.

**Evidence:** `runs/cross-model/s1-7ceba3f/prompt.txt:586-587`, `scripts/cross-model-review.py:217-229`, `scripts/cross-model-review.py:357`, git object size at `7ceba3f:scripts/self-improvement.sh`

## Claim 17: "Baseline: all four families, several at High, flagged Tier A/B work as missing" / "the Result-5 sibling-commit consensus FP is gone (0/8, was 8/8-family)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:39-43`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

**Three** of four families flagged it, not four. The D4 diff-only baseline is split across `runs/cross-model/gt-7ceba3f/findings.jsonl` (Kimi r1–r2) and `runs/cross-model/fast-7ceba3f/findings.jsonl` (Sol, Sonnet, Gemini r1–r3) — 12 replicates total. Missing-work findings:

- Kimi r1 High `"Retro instructions route tasks into file_scope rejection"`; Kimi r2 High `"…the Tier A file_scope widening and Tier B code-review gate described in decision 020 are absent from this diff"`
- Sonnet r1 High `"Decision record documents unshipped code"` — desc: `"…none of which appear in this diff"`
- Gemini r1 High `"Missing Tier A and Tier B implementations"`; r2 High `"Missing validation gates implementation"`; r3 High `"Missing gate validation code"`

**Sol filed no such finding in any of its three replicates.** Its eight D4 baseline findings are all about the harvest step (fix-detection prefix matching, unvalidated LLM writes, autonomous-commit-format violations); I read every description and none asserts Tier A/B is absent.

So the baseline rate is 6/12 replicates across 3/4 families, not "all four families". "was 8/8-family" is separately unsupported: the baseline had 12 replicates, not 8, and 6 of them carried the FP. The "several at High" sub-claim is verified (six High findings above). The "0/8" half is verified (Claim 1).

Precise version: "Baseline: three of four families (Kimi, Sonnet, Gemini), 6/12 replicates, all at High, flagged Tier A/B work as missing."

**Evidence:** `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`, `docs/working/experiment-cross-model-review-2026-07-30.md:218-233`

## Claim 18: "no High findings at all" (D4 under Stage 1) and "The 15 findings shifted to real Tier-C-diff issues"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:45-54`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

D4 finding count: 2+2+4+2+0+3+1+1 = 15. Severity census across those 15: nine Medium, six Low — no Critical or High. (Paraphrased — no quote available because this is an aggregate over the `sev` field of 15 JSON objects.)

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`

## Claim 19: "New cross-family consensus finding (all 4 families, Medium): the bwrap invocation `--tmpfs /tmp … --chdir \"$PWD\"` …"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:69-76`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Same defect as Claim 9, in the source document. All four families reported this issue in the diff-only baseline for the same commit (full citation list in Claim 9). It is a *persistent* 4-family consensus finding, not a new one. The follow-up item that depends on it ("Triage the bwrap `/tmp`-CWD consensus finding", line 105) is unaffected in substance — the finding is real either way — but the "new under enriched context" framing is contradicted by `runs/cross-model/gt-31e2d3a/findings.jsonl`.

Two secondary imprecisions in the same sentence: (a) "all 4 families, Medium" — Sonnet's r2 instance is `"sev": "Low"` (`"bwrap \`--chdir \"$PWD\"\` can be shadowed by the fresh \`--tmpfs /tmp\` mount"`), and Sonnet r1's instance is framed as probe/real-invocation flag mismatch (`"bwrap probe does not mirror the real invocation's flags"`) rather than the `/tmp` CWD failure specifically; (b) the "Spot-checked against `31e2d3a:skills/arithmetic-eval/SKILL.md:268` — the flags are as described" sub-claim is Verified: `git show 31e2d3a:skills/arithmetic-eval/SKILL.md` carries both `--tmpfs /tmp` and `--chdir "$PWD"` in the bwrap invocation around that line.

**Evidence:** `runs/cross-model/gt-31e2d3a/findings.jsonl`, `runs/cross-model/s1-31e2d3a/findings.jsonl`, `31e2d3a:skills/arithmetic-eval/SKILL.md:255-268`

## Claim 20: "two independent rediscoveries of the live Result-3 pipefail bug (Sol r1 Low, Gemini r1 Medium) — previously found only by Kimi"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:54-56`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Stage 1: Sol r1 `"Empty failure-pattern library can abort under pipefail"` with `"sev": "Low"`; Gemini r1 `"grep pipeline crash on empty file"` with `"sev": "Medium"` — severities as stated. Baseline: the only pipefail finding across all 12 D4 diff-only replicates is Kimi r1 `"Unguarded grep pipeline can abort the round under pipefail"` (Low); no Sol, Sonnet, or Gemini replicate filed one.

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 21: "Recurrent cluster (3 families): fix-task detection reads only the branch **tip** commit subject"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:56-58`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Legibility-target:** for-author

Two families, not three. In the Stage-1 D4 run the cluster members are:

- Kimi r1 `"Fix-task detection checks only the branch tip commit subject"`; Kimi r2 `"Fix-task detection keys off only the branch tip commit subject"`
- Sol r1 `"Fix-task detection misses eligible retros"` (desc: `"Harvesting examines only the branch tip subject…"`); Sol r2 `"Fix detection only examines the branch tip"`

Sonnet's three findings are about harvest file-scope, silent-failure swallowing, and Tier-C enforcement; Gemini's two are the pipefail grep and `git diff --quiet` staging semantics. Neither family filed a tip-detection finding.

Confidence is Medium rather than High only because the cluster boundary is judge-assigned and `overlap.json` does not export per-cluster membership, so a judge that merged Gemini r2's `"\`git diff --quiet\` ignores staged changes…"` into this cluster is conceivable — but on the finding text these are different defects. Precise version: "Recurrent cluster (2 families, 4/8 replicates)".

**Evidence:** `runs/cross-model/s1-7ceba3f/findings.jsonl`, `runs/cross-model/s1-7ceba3f/overlap.json`

## Claim 22: "23 findings total, all anchored to real constructs in the reviewed diff." (D3)

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:67`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium
**Legibility-target:** for-author

The count is verified: 5+1+4+4+3+3+1+2 = 23. Every finding's `path` resolves to a file touched by `31e2d3a~1..31e2d3a` or to `docs/decisions/019-arithmetic-eval-sandboxing.md` (Kimi r1's Low), and I found no misattribution of the Result-3c class.

"all anchored to real constructs" is a stronger claim than I can fully confirm by static reading, because it asserts a negative over 23 findings' internal reasoning (e.g. Kimi r1's `_posixsubprocess.fork_exec` reachability argument and Sol r1's `numpy.ctypeslib.ctypes.CDLL(None).system(...)` chain are plausible-but-unexecuted claims about the sandbox). The verifiable version — no replicate reports a construct that does not exist in the reviewed files — holds.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`

## Claim 23: "J_cross now 0.28–0.40 for Sonnet↔Gemini↔Sol (was 0.000–0.513 with most pairs ≈0)"; "Kimi remains the outlier population (J_cross 0.036–0.103)"; "D4 J_cross stays low (0.0–0.267)"

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-83`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Every stated range is numerically correct. New D3: Sonnet↔Gemini 0.396, Gemini↔Sol 0.375, Sonnet↔Sol 0.283 → 0.28–0.40 ✓; Kimi pairs 0.036/0.042/0.103 → 0.036–0.103 ✓. New D4: 0.0/0.062/0.104/0.267 (plus Kimi pairs) → 0.0–0.267 ✓. Baseline D3 (`runs/cross-model/gt-31e2d3a/overlap.json`): 0.0, 0.093, 0.119, 0.258, 0.382, 0.513 → the 0.000–0.513 range ✓.

The imprecise part is "with most pairs ≈0". Of the six baseline D3 pairs, three are ≥0.258 (Gemini↔Kimi 0.258, Kimi↔Sol 0.382, Gemini↔Sol 0.513). "Most pairs ≈0" holds only for the three Sonnet-involving pairs (0.0, 0.093, 0.119) — which is the relevant subset for the "Sonnet stops abstaining" story, but not what the sentence says. Also unmentioned: **Gemini↔Sol fell**, 0.513 → 0.375, so the rise is not uniform across the cited trio. Precise version: "the two Sonnet pairs rose from ≈0.1 to 0.28/0.40 while Gemini↔Sol fell from 0.513 to 0.375."

**Evidence:** `runs/cross-model/s1-31e2d3a/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/gt-31e2d3a/overlap.json`

## Claim 24: "Median per-call **$0.226** — under the ~$0.33 band trigger; worst call $0.388 (Kimi D3 r1, 636 s…). Latency: Sol 48–76 s, Gemini 110–143 s, Sonnet 93–263 s, Kimi 287–636 s."

**Location:** `docs/working/experiment-stage1-fp-kill-2026-07-31.md:93-98`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Median of the 16 `usage.cost` values = 0.22566. Max = 0.388023, on the `moonshotai/kimi-k3` replicate-1 row of `s1-31e2d3a`, whose `"latency_s": 636.1` and `completion_tokens_details.reasoning_tokens` = 20,788 support "reasoning-heavy". Latency ranges by family across both cells: Sol 48.3–75.8, Gemini 109.9–143.3, Sonnet 92.9–262.6, Kimi 287.0–636.1 — all four stated ranges match to the rounding shown. The $0.33 band trigger is confirmed at `docs/working/stage1-context-cost-2026-07-31.md:71-72`.

**Evidence:** `runs/cross-model/s1-31e2d3a/findings.jsonl`, `runs/cross-model/s1-7ceba3f/findings.jsonl`, `docs/working/stage1-context-cost-2026-07-31.md:69-72`

## Claim 25: "VALIDATED 2026-07-31 …: the D3/D4 re-run reproduced neither FP in 0/8 replicates each, and cross-family agreement on real issues rose. … (live diff-only runs print a warning to stderr)"

**Location:** `scripts/cross-model-review.py:21-28`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The 0/8 half is verified (Claim 1). The stderr-warning half is verified — see Claim 26.

"cross-family agreement on real issues rose" is unqualified and true only for D3. On D4 all three baseline-comparable pairs **fell**: Sonnet↔Gemini 0.106 → 0.0, Sonnet↔Sol 0.148 → 0.104, Gemini↔Sol 0.065 → 0.062 (`runs/cross-model/fast-7ceba3f/overlap.json` vs `runs/cross-model/s1-7ceba3f/overlap.json`). The experiment doc itself scopes the claim correctly (`"D4 J_cross stays low (0.0–0.267)"`, line 82) and the decision-log row scopes it to D3 (Claim 4); this docstring and SKILL.md (Claim 27) are the two places where the qualifier is dropped. Precise version: "cross-family agreement on real issues rose on D3."

**Evidence:** `scripts/cross-model-review.py:16-32`, `runs/cross-model/fast-7ceba3f/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`, `runs/cross-model/s1-31e2d3a/overlap.json`, `docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-83`

## Claim 26: "live diff-only runs print a warning to stderr" — and the implied invariant that the diff-only prompt stays byte-identical to pre-021

**Location:** `scripts/cross-model-review.py:27-28` (docstring) and `scripts/cross-model-review.py:422-427` (implementation); echoed in `docs/decisions/log.md:51` ("warns on live diff-only runs … byte-identical")
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The warning is gated on the live path only. The dry-run branch returns before it:

```python
            print(f"dry run: prompt written to {os.path.join(args.out, 'prompt.txt')}; no calls made")
            return
        if not args.context_base:
            # Decision 021 + the 2026-07-31 FP-kill validation: diff-only manufactures
            # sibling-commit/flattened-boundary FPs; Stage-1 context is the review-quality mode.
            print("WARNING: diff-only mode is a recall probe with a known misattribution "
```
(`scripts/cross-model-review.py:418-427`)

Confirmed empirically: `python3 scripts/cross-model-review.py --repo . --range '7ceba3f~1..7ceba3f' --dry-run --out …` emitted only `context mode: diff-only, prompt sha 968d268b1689` / `prompt size: 17,680 chars, ~4,420 tokens (diff 17,160 chars)` / `dry run: prompt written to …` — no WARNING line. `sys` is imported at `scripts/cross-model-review.py:72`, so `file=sys.stderr` resolves.

The warning does not touch prompt assembly: it sits after the prompt is built, hashed, printed, and (in dry-run) written. Both offline checks the commit message asserts pass:

- **Prompt-sha stability:** the dry run printed `968d268b1689`, which is exactly the `prompt_sha` on both rows of `runs/cross-model/gt-7ceba3f/findings.jsonl` and on all nine rows of `runs/cross-model/fast-7ceba3f/findings.jsonl` — i.e. byte-identical to the pre-021 historical prompt for that range.
- **bats suite 8/8:** `bats test/cross-model-review-stage1.bats` → `ok 1` … `ok 8`, including `ok 6 diff-only dry-run prompt is unchanged by the stage-1 additions (prompt sha stable)`.

**Evidence:** `scripts/cross-model-review.py:415-430`, `scripts/cross-model-review.py:72`, `test/cross-model-review-stage1.bats`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`

## Claim 27: "the 2026-07-31 Stage-1 experiment … showed unlabelled single-commit scope made **all four model families** unanimously flag work as missing that sat in sibling commits, and the label + sibling context reduced that FP class to 0/8 while *raising* agreement on real issues."

**Location:** `skills/code-review/SKILL.md:101`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Three separate problems, one of them load-bearing for the rule's stated justification:

1. **"all four model families"** — three of four. Sol filed zero missing-work findings across its three D4 diff-only replicates (full census in Claim 17).
2. **"unanimously"** — not supported even within the three families that did flag it. The rate is 6/12 replicates: Kimi 2/2 (only two Kimi replicates exist in `gt-7ceba3f`), Gemini 3/3, Sonnet 1/3 (r2 and r3 filed other findings and no missing-work claim). "Unanimous" holds only for Gemini.
3. **"while *raising* agreement on real issues"** — unqualified, and false for the cell this rule is derived from. D4's three baseline-comparable J_cross pairs all fell (Claim 25). Agreement rose on D3 only.

The "reduced that FP class to 0/8" half is verified (Claim 1). Note the sourcing chain: this sentence inherits problems 1 and 2 from the baseline doc's own Result 5 line (`"On D4, **all four families** flagged, several at High…"`, `docs/working/experiment-cross-model-review-2026-07-30.md:220`), which is itself contradicted by that experiment's raw data — so the fix should probably land in both places.

This is not a hallucination-log candidate: no symbol, API, or construct is fabricated — the error is a miscount and a dropped qualifier over real run data.

**Evidence:** `skills/code-review/SKILL.md:101`, `runs/cross-model/gt-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/findings.jsonl`, `runs/cross-model/fast-7ceba3f/overlap.json`, `runs/cross-model/s1-7ceba3f/overlap.json`, `docs/working/experiment-cross-model-review-2026-07-30.md:218-233`

---

## Claims Requiring Attention

### Incorrect
- **Claim 9** (`docs/thoughts/code-review-evaluation-state.md:289-290`): the bwrap `--tmpfs /tmp` / `--chdir "$PWD"` consensus finding is described as "new", but all four families already filed it in the diff-only baseline (`gt-31e2d3a`); it is persistent, not new.
- **Claim 17** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:39-43`): "all four families … flagged Tier A/B work as missing" and "was 8/8-family" — actually 3/4 families and 6/12 replicates; Sol filed no missing-work finding.
- **Claim 19** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:69`): same "New cross-family consensus finding" error as Claim 9, at its source; also "all 4 families, Medium" — Sonnet's instance is Low.
- **Claim 21** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:56`): "Recurrent cluster (3 families)" for tip-commit fix detection — only Kimi and Sol filed it (2 families, 4/8 replicates).
- **Claim 27** (`skills/code-review/SKILL.md:101`): "all four model families unanimously" (3/4 families, 6/12 replicates, unanimous only within Gemini) and "while *raising* agreement on real issues" (D4 agreement fell on all three comparable pairs).

### Stale
- None.

### Mostly Accurate
- **Claim 3** (`docs/decisions/log.md:51`): "the same four families that produced them diff-only" — Result 3c came from a single Gemini replicate; Result 5 from three families.
- **Claim 13** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:27`): D3 sibling section is the two original hardening commits *plus* review-fix rounds 1–5, not rounds 1–5 alone.
- **Claim 16** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:34-35`): "72 KB" is the harness's chars÷1024 figure; the file is 74,876 bytes (73.1 KiB). Conclusion unaffected.
- **Claim 22** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:67`): "all anchored to real constructs" asserts a negative over 23 findings' reasoning; the verifiable version (no non-existent construct referenced) holds.
- **Claim 23** (`docs/working/experiment-stage1-fp-kill-2026-07-31.md:78-80`): "most pairs ≈0" — 3 of 6 baseline D3 pairs were ≥0.258, and Gemini↔Sol fell (0.513 → 0.375).
- **Claim 25** (`scripts/cross-model-review.py:24-25`): "cross-family agreement on real issues rose" needs the D3 qualifier; D4 fell.

### Unverifiable
- None. (Nearest: Claim 21's cluster-family count is inferred from finding text because per-cluster membership is not exported by `overlap.json`. The inference is strong enough for an Incorrect verdict at Medium confidence, but is not machine-confirmable from the committed data.)

---

## Goal-Alignment Note
- Answered: yes — all 10 briefed claim groups checked against run artifacts, harness source, and git history.
- Out of scope: quality/design assessment of the harness change and of the review process itself (code-fact-check is verification only); the substantive correctness of the individual model findings inside the JSONL (treated as machine evidence per the brief, not as prose under check).
- Escalate: (a) the "3/4 families, not all four" miscount originates in the **baseline** doc `docs/working/experiment-cross-model-review-2026-07-30.md:220` (out of this branch's diff) and propagates into `SKILL.md:101` and the new experiment doc — a fix confined to this branch leaves the source uncorrected; (b) the "new 4-family consensus finding" error (Claims 9/19) weakens the state doc's "side signals" list but arguably *strengthens* the underlying argument, so the author may want to reframe rather than delete; (c) actual worst call $0.388 exceeded the $0.248 offline projection by 56% — the estimator blind spot is noted in the experiment doc but not in 021's status line, where a future reader will look for the guardrail.
