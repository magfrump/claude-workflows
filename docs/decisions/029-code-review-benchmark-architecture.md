# 029 — Code-review benchmark architecture: SWR-Bench GT-interpretation fork (v2 spine)

- **Goal**: Decide the architecture of the benchmark used to evaluate and compare LLM-agent code-review process configurations.
- **Project state**: SWRBench adapter live with first judged numbers (n=7) · feeds CodeReviewWriteup and the review-quality thread · not blocked.
- **Task status**: complete (decision made; implementation sequenced by pre-mortem gates)

## Context

First judged SWRBench numbers exposed that the stock v1 metrics are vacuous for this
process: point precision 4.9%, PR-level recall 1.0 with tn=0 (the review never says
"clean"), because the agentic orchestrator emits ~11.6 findings/PR of mostly
factually-true-but-noisy material that v1 scores as FP. A double-diamond DD was run
(`docs/working/dd-code-review-benchmark.md`): Diamond 1 converged on the framing
*"decision instrument ranking review configs by verified-bug recall per dollar, with
clean-PR specificity and a human-calibrated judge as hard validity preconditions"*;
Diamond 2 evaluated benchmark architectures against it. User selected the direction at
the Path-B gate.

## Options considered

15 candidates (working doc §1.1), pruned to four composite designs:
**[A]** v2 spine — SWR-Bench fork with GT-reinterpreting judge (`docs/gemini-SWRench.md`):
TP/VU/OOS/NB/FP taxonomy, fact-verification of every predicted item by default,
attestation-before-severity, WUS reported beside legacy P/R/F1, human-calibration subset,
clean-PR specificity axis, per-instance cost capture. **[B]** A + own-repo historical GT
leg. **[C]** A + injected-bug leg. **[D]** paired-preference ranking harness only.

## Decision and rationale

**Chosen: [A] — implement the v2 judge spec as a SWR-Bench fork, GT-side emphasis**:
categorize non-blocking GT feedback (NB/OOS separation) and assess accuracy of every
predicted item by default, so factually-true-but-noisy findings stop being scored
identically to hallucinations. Rationale: the spec is already written and draft-reviewed,
the adapter is live, and A's falsifiable hypothesis has the shortest counter-evidence
window — the §7.3 judge–human kappa gate either validates the whole instrument or halts
spend within ~2 weeks. [D]'s mechanism is absorbed as a cheap screening layer for future
multi-arm sweeps (confirm frontiers with the full judge); [B] is the queued hedge against
GT incompleteness, entered after A's kappa gate passes.

Implementation is sequenced by the pre-mortem (`docs/reviews/pre-mortem.md`):
kappa pilot **before** any full-arm judging (must-address 1); pre-registered
arm-ordering discrimination pilot added to spec §7 (must-address 2); verbatim-GT-match
audit field + adjudication sampling caps (worth-mitigating 3–4).

Falsifiable hypothesis: *if chosen, judge–human kappa ≥ 0.6 on 30 stratified findings and
diff-only vs agentic arms separate beyond bootstrap CI within 2 weeks; counter-evidence =
kappa < 0.4 or overlapping CIs at n=30.*

See alternatives considered → Pruned candidates below.

## Pruned candidates and why

How to read: each entry is `[candidate-ID]: one-line reason for discard`. Future DDs in
adjacent areas can grep this section to avoid regenerating already-pruned approaches.
`[0/1 status-quo v1 metrics]: fails judge-validity constraint; already produced vacuous numbers.` `[4 own-repo leg]: not pruned — deferred behind A's kappa gate (+1–2 wk GT mining, unshareable GT).` `[5 injected-bug leg]: deferred — synthetic mutant recall may not predict real recall; revisit for arm-sweep statistical power.` `[6 paired-preference]: no absolute numbers for the writeup; absorbed into A as screening layer.` `[7 live acceptance telemetry]: cannot discriminate arms in any near-term window; kept as long-run revisit trigger.` `[8 executable downstream eval]: ⚠ cost (multiplies $14.6/instance mean) and confounds review quality with fix ability.` `[11 expert panel]: ⚠ cost ceiling.` `[12 cross-benchmark composite]: marginal comparability gain for engineering cost, no judge-validity gain.` `[14 do-nothing]: fails the chosen framing.` `[021#6 on-demand file read]: [carried from 021-reviewer-context-management: per-provider tool plumbing + model/retrieval confound].` `[021#10 judge-side enrichment]: [carried from 021-reviewer-context-management: folded into spec as downstream variant].`

## Stress-test mitigations

- How to read: *Boring alternative* mitigation — [D] paired-preference absorbed into [A] as a screening layer for multi-arm sweeps rather than competing as a design; changed A's effort note.
- How to read: *Invert the thesis* mitigation — GT-incompleteness objection ("better reviews score worse") confirmed attestation/WUS as load-bearing and queued [B] own-repo leg as the structural hedge; raised B's long-run priority.
- How to read: *Failure-driven* mitigation — added second-judge-model robustness check (pending OPENROUTER key fix) and second repo slice before any published numbers; stratify kappa sample across arms to avoid calibrating on Claude-authored reviews only.

## Consequences

Easier: arm comparisons become internally meaningful (noise categorized, not FP-scored);
clean-PR specificity and cost live in the same report; the writeup gets calibrated
numbers with a stated validity bound (kappa). Harder: external comparability to published
SWRBench tables weakens (forked judge + pinned Claude judge); a standing human
adjudication duty exists (capped at 30 findings/judge-version); out-of-diff bug class
stays unmeasured until leg [B].

## Revisit triggers

How to read: each entry is a concrete, observable condition that should prompt
re-evaluating this decision; grep here when context changes.
`if kappa < 0.4 on the pilot (A's counter-evidence — halt, revisit [C]/[D]).` `if WUS fails to rank firehose < curated < diff-only on the 10-instance discrimination pilot.` `if arm CIs still overlap at n=30 (need [C]'s injected power or larger n).` `if ≥3 real config decisions get made on gut feel despite the benchmark existing (instrument not load-bearing — revisit [D] screening-only).` `if upstream SWR-Bench publishes a GT/dataset revision (rebase cost, narrative 5).` `if VU backlog exceeds the §7 sampling cap for 2 consecutive sweeps.`
