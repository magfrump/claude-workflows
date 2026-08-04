# DD — Benchmark for evaluating LLM-agent-driven code review (Double Diamond)

- **Goal**: Decide the architecture of the benchmark used to evaluate and compare configurations of the LLM-agent code-review process.
- **Project state**: SWRBench adapter wired with first judged numbers · feeds the CodeReviewWriteup and the review-quality SI thread · not blocked.
- **Task status**: complete (decision 029 recorded; pre-mortem at docs/reviews/pre-mortem.md)

Invoked with explicit double-diamond framing. Diamond 1 entry condition (a)/(c) holds:
the triggering artifacts describe the problem in incompatible terms — the writeup wants
"efficient $ → code quality" numbers, the SWRBench thread wants comparability to published
tables, and the v2 judge spec treats judge validity as the blocker. These imply different
benchmarks.

## Diamond 1 — Purpose

### 1a. Candidate framings

1. **Config-comparison instrument** — the benchmark exists to tell us which review-process configuration (context mode, k, model, critic set) finds more real bugs per dollar.
2. **Public leaderboard placement** — the benchmark exists to measure this process against published SWRBench baselines so the writeup carries externally credible numbers.
3. **Regression guard** — the benchmark exists as a CI-style gate so future process changes can't silently degrade review quality.
4. **Precision crisis** — the real problem is the false-positive firehose (4.9% point precision, 0/4 clean PRs identified); the benchmark must primarily quantify specificity.
5. **Judge-validity meta-problem** — no benchmark number means anything until the LLM judge is calibrated against human judgment; the benchmark *is* the calibration apparatus.
6. **Downstream outcomes** — review-text scoring is a proxy trap; only measure whether the review-fix loop produces better final code (tests pass, fewer later reverts).
7. **Null framing** — SWRBench + the committed v2 judge spec already *is* the benchmark; the remaining task is implementation, not design.
8. **Publication instrument** — the benchmark exists to make the CodeReviewWriteup's claims reproducible by a reader.

Health check: framings cover ≥2 stakeholders (maintainer: 1,3,4,7 · external reader: 2,8 · meta: 5,6) and ≥2 scopes (sub-problem: 3,4 · system: 1,2,7,8 · meta: 5,6). No clustering flag.

### 2a. Diagnosis matrix

| # | Success criterion | Implied solutions | Leaves out | Stakeholder | Scope |
|---|---|---|---|---|---|
| 1 | Two arms rank confidently on recall/$ | fixed instance set + cost accounting | external credibility | maintainer | system |
| 2 | Numbers comparable to SWRBench tables | stock metrics, Gemini judge | own-repo realism, cost axis | reader | system |
| 3 | Alert fires on quality regression | small cheap repeated suite | discovery of *better* configs | maintainer | sub |
| 4 | Says-clean rate & FP density measured | clean-PR-heavy set, severity-weighted FP | recall side | maintainer | sub |
| 5 | Judge–human kappa known | human adjudication subset | everything the judge then measures | maintainer | meta |
| 6 | Post-fix code measurably better | executable eval, long horizon | attribution, cost explodes | user | meta |
| 7 | balanced-30 run judged & reported | none (finish work) | v1 metric was vacuous (recall 1.0, tn=0) | maintainer | system |
| 8 | Reader can rerun and get same numbers | pinned artifacts, published harness | improvement loop | reader | system |

Redundancy: 2≈8 (external credibility). 4 and 5 are *validity preconditions* of 1, not
rivals — a config-comparison that can't score clean PRs or trust its judge is the vacuous
v1 result already observed. 3 is a cheap downstream reuse of whatever 1 builds. 6's
"leaves out" list (attribution, cost) contains hard concerns from the triggering situation.
7's "leaves out" contains the observed vacuity — disqualifying as sole framing.

### 3a. Chosen framing record

> **Chosen framing**: The benchmark is a decision instrument that ranks review-process
> configurations by verified-bug recall per dollar, with two validity preconditions
> promoted to hard constraints: it must score clean-PR specificity meaningfully, and its
> LLM judge must be human-calibrated. We selected this over *public leaderboard placement*
> (comparability is a soft constraint — the writeup's core question is $-efficiency, not
> rank) and over the *null framing* (the v1 metrics already produced a vacuous result:
> recall 1.0 with tn=0, precision 4.9% — the design gap is real). Diamond 2 evaluates
> benchmark architectures against this framing; candidates that primarily serve
> leaderboard placement or downstream-outcome measurement are out-of-scope, not
> alternatives.

## Diamond 2 — Solution

### 1.0 Pre-generation grep

`grep -B1 -A20 "Pruned candidates" docs/decisions/*.md | rg -i "benchmark|judge|eval|metric"` →
two hits, both in `021-reviewer-context-management.md`:

- `[6] on-demand file read` — pruned for per-provider tool plumbing + model/retrieval confound. **Carried forward** — that pruning concerned *arm design*, not benchmark design; it stays pruned and is out of scope here.
- `[10] judge-side enrichment folded into #9 as downstream variant` — **carried forward**; judge-side context enrichment remains a variant inside the v2 judge spec, not a separate benchmark candidate.

### 1.1 Candidates

0. **Status quo** — finish balanced-30 with the pinned Claude-CLI judge and stock v1 P/R/F1 metrics.
1. **Minimal** — status quo plus a cost column; no judge changes; call it done.
2. **v2 WUS judge on SWRBench** — implement the committed `gemini-SWRench.md` spec (WUS precision-side, attestation-before-severity, quote/line verification) over the existing adapter.
3. **Human-adjudication calibration subset** — hand-label a stratified sample of judged findings; report Cohen's kappa alongside all metrics (spec §7.3). *(component)*
4. **Own-repo historical leg** — mine own projects' git histories for bugs that escaped review and were fixed later; replay arms at the pre-fix commit; human-attested GT, includes out-of-diff bugs.
5. **Injected-bug leg** — plant known bugs (mutation-style + agent-authored subtle bugs) into GT-clean commits; perfect recall GT, controllable difficulty and n.
6. **Paired-arm preference judging** — judge compares two arms' reviews of the same instance head-to-head; relative ranking without absolute judge calibration.
7. **Live acceptance telemetry** — instrument the real review-fix loop; GT = which findings the author accepts/fixes; accrues over months.
8. **Executable downstream eval** — run the full review-fix loop on benchmark instances and score the resulting diff (tests, later-revert rate).
9. **Clean-PR specificity axis** — ≥40% GT-clean instances; says-clean rate + severity-weighted FP density as first-class reported metrics. *(component)*
10. **Cost-frontier reporting layer** — per-instance $ capture, recall-vs-$ Pareto frontier across arms. *(component; adapter already logs cost)*
11. **Ideal-if-free** — multi-hundred-PR human expert panel across several repos, blind-labeled.
12. **Cross-public-benchmark composite** — add other public review benchmarks alongside SWRBench.
13. **Self-play adversarial planting** — red-team agent plants subtle bugs, review arms hunt them (dynamic variant of 5; folded into 5).
14. **Reframe/do-nothing** — skip benchmarking, keep iterating on qualitative smoke observations.

Health check: initial list clustered on *GT source* (0,1,2,4,5,11,12 all vary where truth
comes from); added 6, 7, 8 to move on the *judging-method* and *outcome-layer* dimensions.
3, 9, 10 are components that fold into any spine, flagged as such, evaluated as parts of
composites in step 3. 13 folded into 5.

### 2. Diagnose — constraints

Hard:
- **H1 arm discrimination.** success: diff-only vs full-agentic arms separate beyond a 95% bootstrap CI on the primary metric at n ≤ 30 instances per arm.
- **H2 specificity is measured.** success: the metric report includes says-clean rate and severity-weighted FP density computed over GT-clean instances comprising ≥40% of the set.
- **H3 judge validity.** success: judge-vs-human Cohen's kappa ≥ 0.6 on ≥30 stratified sampled findings, reported alongside every metrics table (v2 spec §7.3).
- **H4 cost ceiling.** success: one full arm evaluation ≤ $350 measured from harness logs, with per-instance $ captured (agentic mean is $14.6 × 30 ≈ $440 → agentic arm may need n<30 or the balanced-30 subset reused; harness must log this, not estimate it).
- **H5 pinned reproducibility.** success: re-judging an identical generation.jsonl reproduces metrics exactly via the id-keyed judgment cache; judge model pinned per run.

Soft:
- **S1 external comparability** to published SWRBench tables (Gemini judge, stock metrics as a secondary report).
- **S2 out-of-diff bug coverage** — the rich-brief finding showed the highest-value class of caught bugs lives outside the diff; SWRBench GT (review comments on the diff) cannot contain these.
- **S3 incremental engineering ≤ ~1 week** on the existing adapter.
- **S4 GT-completeness robustness** — a true finding absent from GT must not be automatically scored FP (the attestation mechanism).

### 3. Match and prune

| # | Candidate | H1 | H2 | H3 | H4 | H5 | S1 | S2 | S3 | S4 |
|---|---|---|---|---|---|---|---|---|---|---|
| 0 | status quo v1 | ~ | ~ | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |
| 1 | minimal +cost | ~ | ~ | ✗ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ |
| 2+3+9+10 | **v2 spine** | ~ | ✓ | ✓ | ✓ | ✓ | ~ | ✗ | ✓ | ✓ |
| 4 | own-repo leg | ~ | ✓ | ✓ | ✓ | ✓ | ✗ | ✓ | ✗ | ✓ |
| 5 | injected leg | ✓ | ✓ | ~ | ✓ | ✓ | ✗ | ~ | ~ | ✓ |
| 6 | paired preference | ✓ | ~ | ~ | ✓ | ✓ | ✗ | ✗ | ✓ | ~ |
| 7 | live telemetry | ✗ | ~ | ✓ | ✓ | ~ | ✗ | ✓ | ~ | ✓ |
| 8 | executable eval | ~ | ~ | ~ | ⚠ | ~ | ✗ | ~ | ✗ | ✓ |
| 11 | expert panel | ✓ | ✓ | ✓ | ⚠ | ✓ | ✗ | ✓ | ✗ | ✓ |
| 12 | cross-benchmark | ~ | ~ | ✗ | ~ | ~ | ✓ | ✗ | ✗ | ✗ |
| 14 | do nothing | ✗ | ✗ | ✗ | ✓ | — | ✗ | ✗ | ✓ | ✗ |

Pruned: 0/1 (fail H3; v1 already produced the vacuous result), 7 (fails H1 in any
near-term window — becomes a revisit trigger, not a benchmark), 8 (⚠ H4: full fix loop
per instance multiplies the $14.6 mean; also confounds review quality with fix ability),
11 (⚠ H4), 12 (fails H3 and S3 for marginal S1 gain), 14 (fails the framing).

Fixable weaknesses: v2 spine's H1 is `~` (n=30 may not separate arms) — fix: bootstrap CIs
in the metrics script + option to extend n on the deciding metric only. 5's H3 is `~`
(FP side still needs the judge) — fix: run injected instances through the same v2 judge so
only the *recall* side leans on perfect GT.

Survivors, composed as whole-benchmark designs (components 3/9/10 fold into every spine):

- **[A]** v2 spine alone — SWRBench balanced-30 + v2 WUS judge + human-calibration subset + clean-PR axis + cost frontier.
- **[B]** v2 spine + own-repo historical leg (4).
- **[C]** v2 spine + injected-bug leg (5).
- **[D]** paired-preference harness (6) with the cost layer — no absolute metrics.

### 4. Tradeoff matrix

| Design | Effort | Risk | Coverage (hard) | Key downside |
|---|---|---|---|---|
| A | 3–5 d (spec written, adapter live) | med — kappa gate may fail | 5/5 | blind to out-of-diff bugs; astropy-only |
| B | A + 1–2 wk GT mining | med — GT yield unknown | 5/5 + S2 | own-repo GT is small-n, not shareable |
| C | A + 3–5 d | med — mutant realism | 5/5 (H1 strongest) | synthetic recall may not predict real recall |
| D | 2–3 d | low for ranking / high for claims | 3/5 (H2,H3 partial) | no absolute numbers; writeup can't cite it |

Falsifiable hypotheses:
- **A**: If chosen, judge–human kappa ≥ 0.6 on 30 findings and diff-only vs agentic arms separate beyond bootstrap CI within 2 weeks; counter-evidence = kappa < 0.4, or overlapping CIs at n=30.
- **B**: If chosen, ≥15 usable escaped-bug GT instances mined from own repos within 1 week, ≥2 of them out-of-diff; counter-evidence = <8 usable GT bugs or extraction exceeding 2 weeks.
- **C**: If chosen, 20 injected bugs across 10 instances in ≤2 days and arm recall separates; counter-evidence = all arms detect >90% of mutants (ceiling — no discrimination).
- **D**: If chosen, preference judge ranks 3 arms with >80% pairwise consistency within 1 week; counter-evidence = preference cycles / inconsistency >20%.

Predicted implementation cost (soft): A ≈ 3–5 days + ~$50 judging + ~2h human adjudication;
B adds ~1–2 wk mostly human/agent mining time; C adds ~3–5 d + generation $ per injected set;
D ≈ 2–3 d + cents per comparison.

### Stress-test pass (moves applied)

- **Boring alternative** (vs A): D gets 80% of *arm-ranking* value at ~20% of cost — but the chosen framing's hard constraints H2/H3 demand absolute, calibrated numbers (the writeup cites precision, not just rank). Mitigation adopted: keep D's mechanism as a cheap *screening* layer inside A for future arm sweeps — screen many configs pairwise, confirm the frontier with the full judge. (Matrix change: A's effort note gains a screening path; D absorbed rather than competing.)
- **Invert the thesis** (against A): "SWRBench GT is itself incomplete — reviews that find real bugs the original reviewers missed get scored FP, so a *better* review looks *worse*." This is the strongest objection and is exactly what the v2 spec's attestation-before-severity and WUS address; residual risk is that attestation load falls on one human. B is the structural hedge (GT = bugs proven real by later fixes). Raises B's long-run value; doesn't displace A as first move.
- **Failure-driven** (new failure modes): (i) Claude-judging-Claude bias — mitigate: fix the empty `OPENROUTER_API_KEY` and add a second judge model as a robustness check before publishing numbers; (ii) astropy-only overfit — mitigate: hold out a second repo slice before drawing conclusions in the writeup; (iii) calibrating the judge on Claude-authored reviews only — stratify the kappa sample across arms.
- **Push to extreme** (many arms): at $350/arm, sweeping 10 configs = $3.5k — confirms the screening-layer mitigation from the boring-alternative move; the full benchmark is the confirmation instrument, not the search instrument.

Tie note: A, B, C score within ~1 cell. **Axis of disagreement: validity breadth vs time-to-first-number** — B buys GT the judge can't fake (out-of-diff, human-attested) at +1–2 weeks; C buys statistical power on recall at the risk of measuring mutant-detection; A defers both and gets calibrated numbers this week. No stated project preference on this axis → consulting user (Path B).

### Decision

Path B consult resolved: user selected the **[A]-direction** in their own words — "improve
the ground truth interpretation of the SWR-Bench data in a fork, especially by categorizing
non-blocking feedback and assessing accuracy of items by default" — i.e., the v2 spine with
GT-side emphasis (NB/OOS categorization + Stage-1 fact-verification of every predicted item).
User also asked for a pre-mortem on that task → `docs/reviews/pre-mortem.md` (5 narratives;
2 must-address: kappa-pilot-first sequencing, arm-ordering discrimination pilot).
Archived as `docs/decisions/029-code-review-benchmark-architecture.md`.
