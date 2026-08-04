# Pre-Mortem: SWR-Bench GT-interpretation fork (v2 judge implementation)

**Proposal:** Fork SWR-Bench to improve ground-truth interpretation — categorize non-blocking feedback (NB/OOS/VU taxonomy) and fact-verify every predicted item by default, per `docs/gemini-SWRench.md` (v2 judge spec). Chosen via DD `docs/working/dd-code-review-benchmark.md` (design [A], v2 spine).
**Date:** 2026-08-03
**Upstream what-if analysis:** none

> ℹ️ **No upstream what-if analysis provided.** Failure narratives are generated directly
> from the proposal (and the DD stress-test pass). For higher-quality narratives, run
> `what-if-analysis` first — this skill is sharpest when seeded with already-mapped
> assumptions and coupling points.

**Prior art checked:** `docs/decisions/021-reviewer-context-management.md`,
`docs/working/dd-code-review-benchmark.md`, `docs/working/swrbench-adapter-2026-07-31.md`,
the draft-review artifacts on the spec (fact-check R1, must-address A4–A7), and spec §2.2/§7.
Narratives already partially considered there are tagged.

---

## Narrative 1 — The kappa gate fails after the money is spent

**Root cause:** Implementation order — the full balanced-30 × N-arm judging runs were executed *before* §7 criterion 3 (human-adjudicated calibration), because the kappa check was treated as a reporting requirement rather than a sequencing gate.

**Chain of consequences:** The v2 judge ships and judges ~350 predicted findings per arm across 3 arms (~$60 of judge calls, reruns included). The writeup's tables are drafted from the resulting WUS/precision numbers. Then the 30-finding human adjudication pass runs and lands at Cohen's kappa 0.35 — driven by Stage 1 fact-verification errors: the judge sees only the static context slice the harness feeds it, so factually-true findings about code outside that slice get classified FP, and plausible-sounding hallucinations inside it get classified true. Every downstream number inherits the miscalibration; the tables are withdrawn; two weeks of arm comparisons are unusable because arms differ precisely in how much out-of-slice material they cite.

**Observable outcome:** `evaluation__*.json` category counts shift by >30% when re-judged with enriched context on the same generation.jsonl; the adjudication spreadsheet shows disagreement concentrated in Stage 1 (fact) rather than Stage 4 (severity).

**Plausibility:** Plausible (10–50%) · **Severity:** High
**Tag:** [PRIOR CONSIDERATION] — spec §2.2 "weights are provisional… MUST be calibrated" and §7 criterion 3 name the requirement; the failure here is *ordering*, which the spec does not fix.

**Mitigation:** In the fork's implementation plan, make §7 criterion 3 a *precondition* of any full-arm judging run: judge a stratified 30-finding pilot (drawn from the already-cached n=7 `evaluation__*.tmp.jsonl` judgments), adjudicate by hand, and hard-gate `run.sh eval` on a recorded kappa ≥ 0.6 in the run config before allowing `--sample-balanced 30`.

---

## Narrative 2 — OOS/NB become the judge's uncertainty dump

*(Revised 2026-08-03: the original draft of this narrative claimed the gentle OOS/NB
weights would let the firehose arm score near a curated arm. That was wrong twice over:
(a) the differential is the design intent — an accurate low-impact finding costs seconds
of reading, while an FP that requests a change can introduce a new bug, so they belong an
order of magnitude apart; (b) WUS's denominator is total predictions, so OOS/NB dilute
even at weight ~0 — a firehose arm at 11.6 findings/PR with 0.5 TP + 8 OOS + 3 NB lands
near WUS ≈ 0.009 vs ≈ 0.27 for a curated 1.5-findings/PR arm. The surviving risk is
misrouting *into* the cheap categories, below.)*

**Root cause:** The gentle buckets are only safe if entry into them is strict, and Stage 1's gate ("is the claim factually true?") is unfalsifiable-friendly: vague advisory findings — "consider adding validation here", "this could be more robust" — cannot be factually *false*, so a lenient judge routes them through Stage 1 and into NB at −0.1 (or OOS at 0.0) when they are epistemically FP-like: same review-and-dismiss friction as an FP, none of the verifiable content.

**Chain of consequences:** The verbose arm's output skews toward unfalsifiable advice (the observed n=7 clean-PR pattern: 12 findings, mean severity 4.35, "critical-sounding"). Stage 1 grants "true" because nothing checkable is asserted; the quote/line verification (§4) passes trivially because the quoted code exists — the *claim about it* was never falsifiable. FP counts drop not because the process improved but because the FP definition stopped seeing this class. WUS and precision both improve on paper across all arms simultaneously; the metric loses its ability to see the dominant noise class, and the friction it was built to price stays unpriced.

**Observable outcome:** In §6 audit artifacts, a large NB/OOS population whose findings contain no falsifiable claim (no predicted behavior, no concrete defect); category shares shift heavily from v1-FP to NB/OOS while human spot-checks still rate the same findings "would dismiss without action."

**Plausibility:** Plausible · **Severity:** High
**Tag:** [PRIOR CONSIDERATION] — draft-review A4/A5 flagged WUS as precision-side-only with provisional weights pending human calibration.

**Mitigation:** Tighten spec §3 Stage 1 to require a *falsifiable* factual claim as the entry condition — a finding must assert something that could be false (a concrete defect, a predicted misbehavior); unfalsifiable advisory findings route to FP or a dedicated zero-content category rather than inheriting NB's mild weight. Keep the 10-instance discrimination pilot in §7, reframed as *validation* that the intended denominator dilution separates firehose < curated as designed — not as a weights fix — and include NB/OOS-routed findings in the Narrative-1 kappa sample so misrouting is measured, not assumed.

---

## Narrative 3 — Attestation match-laxity inflates TP

**Root cause:** Stage 3 ("matches a human review comment") is a semantic-similarity judgment with no tightness standard; verbose Claude-authored findings paraphrase broadly enough that generic items ("this needs a test", "consider renaming") fuzzy-match *some* GT comment on most changed PRs.

**Chain of consequences:** Point precision jumps from 4.9% to ~60% in the fork's first report. The jump is celebrated and cited in CodeReviewWriteup.md as the payoff of GT reinterpretation. A reader (or a later self) re-runs with a stricter matcher and precision collapses to ~20%; the delta is match-laxity, not review quality. Because attestation precedes severity (A6), every lax match also skips the severity gate entirely — the laxity is maximally load-bearing.

**Observable outcome:** In §6 audit artifacts, TP findings whose quoted GT comment shares no code symbol or line range with the predicted finding; TP rate correlates with findings/PR across arms (more shots → more fuzzy matches).

**Plausibility:** Plausible · **Severity:** Medium (recoverable — regenerate judgments with a tightened matcher; cost is rework + credibility of any already-shared numbers)

**Mitigation:** Require the §6.2 Findings Detail template to emit the matched GT comment verbatim next to the predicted finding for every TP, and include ≥10 TP matches in the Narrative-1 adjudication sample scored specifically for match-tightness; define in §3 Stage 3 a minimum match standard (same file ∧ overlapping symbol/line target, not topic similarity).

---

## Narrative 4 — The human adjudication queue starves the benchmark

**Root cause:** "Assess accuracy of every predicted item by default" multiplies judge output that only a human can arbitrate: VU claims ("real bug the reviewers missed") are exactly the findings with no GT to check against, and there is one human.

**Chain of consequences:** 30 instances × 3 arms × ~10 findings ≈ 900 judged items per sweep; ~5–8% land in VU. Each VU is a claim that needs human attestation to count as the benchmark's headline win ("found real bugs humans missed"). The solo maintainer's realistic budget is ~2 h/week. The VU backlog grows monotonically; VU stays "provisional" in every report; the one category that distinguishes a *better-than-human* review process from a noisy one never converts to a citable number, and the writeup ships without its strongest claim.

**Observable outcome:** Audit reports accumulate `VU (unconfirmed)` rows across weeks; the adjudication log's last-touched date falls >1 month behind the latest evaluation run.

**Plausibility:** Likely · **Severity:** Medium

**Mitigation:** Fix a sampling contract in §7 now: human adjudication is capped at 30 findings per judge version (stratified category × arm), VU confirmation is capped at the top-5 severity VUs per sweep, and re-adjudication triggers only on judge prompt/model change — anything beyond the cap is reported as judge-classified, explicitly unconfirmed.

---

## Narrative 5 — Fork drift makes every number an island

**Root cause:** The fork accumulates load-bearing local changes (Claude-CLI transport swap, stdlib shims for PyPI-blocked deps, the `os.getenv[...]` bugfix, v2 taxonomy) scattered through upstream files rather than isolated modules.

**Chain of consequences:** Upstream SWR-Bench publishes a dataset/GT revision (or a v2 of their own judge) months later. The fork can't rebase — conflicts sit in `utils.py` and `evaluation_struct.py` where local patches interleave with upstream logic. New results in the field are computed on the new revision; the fork's numbers are permanently pinned to `d5c5` + a private judge, and the soft external-comparability goal (DD constraint S1) silently becomes unreachable rather than deliberately deferred. Solo-maintainer context evaporates: six months later, which shim mattered is archaeology.

**Observable outcome:** `git merge upstream/main` in `external/SWRench` produces conflicts in ≥3 core files; no metrics artifact records which upstream commit + dataset revision produced it.

**Plausibility:** Plausible · **Severity:** Medium (slow-burn; recoverable with effort)

**Mitigation:** Structure the fork additively — v2 judge in new files (`swrbench/judge_v2/`, `scripts/judge_claude_cli.py` already is) with upstream edits limited to entry-point hooks; extend §6.1 artifact naming to embed `{upstream_commit}__{dataset_rev}__{judge_model}` in every evaluation filename so provenance survives the maintainer's memory.

---

## Recommendations

**Must address before proceeding:**
- **Narrative 1 (sequencing):** make the kappa pilot a hard precondition of full-arm judging — it is ~2 h of human time against ~$60+ of judge spend and all downstream credibility. This is also DD design [A]'s falsifiable hypothesis; running it first is what makes the counter-evidence window short.
- **Narrative 2 (Stage-1 falsifiability):** the cheap categories must be strict at the door — require a falsifiable claim to pass Stage 1, and validate via the pre-registered arm-ordering pilot in §7 that the denominator dilution separates arms as designed.

**Worth mitigating:**
- **Narrative 3:** cheap — a template field (verbatim matched GT comment) plus 10 extra adjudication rows inside the Narrative-1 sample.
- **Narrative 4:** cheap — write the sampling caps into §7 before the queue exists.

**Acknowledged risks:**
- **Narrative 5:** acceptable for now — external comparability is a soft constraint (DD S1) and the additive-file discipline is mostly already followed; carry the provenance-naming fix as a small task rather than a blocker.
