# Experiment results: code-review pipeline, 2026-07-29

**Companion docs:** `research-agentic-review-evidence-vs-repo-setup.md` (proposals §4/§5),
`research-code-review-corpus-analysis.md` (historical corpus).
**What ran:** §5.1 stability run, §5.3 abstention probe, quote-check retro on the historical
corpus, and a blinded model-adjudication of the 43 historical findings. All four proposed
in the companion doc; all runnable without the measurement harness.

## Setup

- **Stability run:** 3 real historical diffs — D1 `45bea51` (shell hardening, 11+/3−),
  D2 `2b81baa` (code-review gate, +147), D3 `9adc642` (Rust toolchain Dockerfile, +122).
  Per diff: `security-reviewer` ×3 with **byte-identical prompts** (variance is purely
  sampling), plus `performance-reviewer` ×1. Agents read the skill file and applied it;
  compact findings format; no artifacts written.
- **Abstention probe:** 3 constructed negative-control branches with no plausible security
  surface — NC1 prose reword in a critique doc, NC2 bats test-title reword, NC3 script
  comment reword. `security-reviewer` dispatched at each, Stage 1.5 gate bypassed by
  construction (direct dispatch).
- **Finding matching:** two-stage per the companion doc — same file + line ranges within
  ±3, then same-underlying-issue judgment by me with fixed criteria (same mechanism AND
  same consequence = same issue; bundled sub-claims counted once under the primary claim).
  One judge, applied to all pairs in one sitting.

**Deviations from production, stated up front:** compact output format instead of the full
critique structure (boundary map etc.); skill file read by the agent rather than pasted;
context read from current checkout, not a historical worktree (minor leakage for D1/D2,
none material observed); the same-issue judge is me, not a pinned external prompt.

---

## Result 1 — Stability (J_self): findings are ~70% stable at issue level, but severity and verdict are not

Issue-level clustering across the three same-prompt security runs per diff:

| Diff | Distinct issues found (union) | Found by 3/3 runs | J pairwise | J_self mean |
|---|---|---|---|---|
| D1 `45bea51` | 4 (CDPATH; TMPDIR perms/relocation; `-w` non-dir; TMPDIR symlink) | 1 | 1.00 / 0.25 / 0.25 | **0.50** |
| D2 `2b81baa` | 4 (reviewer-in-worktree; sentinel spoof; fail-open; missing-binary) | 3 | 0.75 / 1.00 / 0.75 | **0.83** |
| D3 `9adc642` | 3 (same-origin checksum; CARGO_HOME redirect; stale decision-log claim) | 2 | 0.67 / 1.00 / 0.67 | **0.78** |
| **Mean** | | | | **0.70** |

Three sub-results that matter more than the headline number:

1. **The most severe finding is the most stable.** D2's High finding
   (reviewer-runs-inside-the-worktree-it-reviews) appeared in 3/3 runs. Every finding that
   any run rated High appeared in all runs of that diff. Instability concentrates in the
   Low/Informational band — exactly the band the rubric maps to 🟢.
2. **Severity is unstable where presence is stable.** The same same-origin-checksum issue
   was rated Medium / Low / Low across D3's three runs; D1's CDPATH issue was Low in one
   run and Informational in another. Under the unified severity mapping, Medium→🟡 vs
   Low→🟢 — i.e. **the same issue lands in different rubric tiers on identical prompts.**
3. **Verdict polarity can flip outright.** On D3's CARGO_HOME issue, run 2 concluded the
   documented immutability claim is "weaker than documented" (actionable); run 3
   investigated further (checked PATH) and concluded "No action needed." Same issue, same
   evidence available, opposite dispositions.

**On D1's low 0.50:** run 3 missed the CDPATH issue entirely; runs 1–2 missed the symlink
issue. On an 11-line diff, single runs of this critic miss real candidate issues about a
third of the time. This is the recall-variance the aggregation literature predicts, on our
own data: **k=1 critic runs are unreliable at the finding level even when the diff is
tiny.**

## Result 2 — Cross-role convergence (J_cross): rare, which cuts against my own §2.1 framing

Security-vs-performance pairs on the same diff:

| Diff | Strict J_cross | Notes |
|---|---|---|
| D1 | 0.00 | perf returned NONE |
| D2 | 0.00 strict / ~0.15 lenient | one borderline region-overlap: perf's "no timeout on `claude -p`" vs security's fail-open cluster (same lines 1240–1246, different claim) |
| D3 | 0.00 | both domains touched CARGO_HOME lines 237–240 with **non-overlapping concerns** (cache reuse vs compiler redirect) — the escalation rule's "overlapping concern" test correctly would not fire |

**Honest scoring against my prediction.** §2.1 argued cross-critic convergence is largely
correlated-sampling noise, implying it would be common and unreliable. Observed:
convergence is **rare** (0–1 borderline case in 3 diffs, ~14 issue clusters). The roles
genuinely partition the space rather than resampling it. That *weakens* the "convergence
is noise" argument — you can't generate much noise from events that almost never occur —
and partially rehabilitates the escalation rule's premise, while also meaning the rule
almost never has anything to act on. Combined with the historical n=4 (3 escalations that
were one repeated bug + 1 waived 3-critic convergence), the honest position is:
**the escalation rule is neither vindicated nor refuted; it is nearly inert**, and the
§4.2 demotion is now motivated less by "convergence is noise" and more by "one automatic
blocking path should not rest on an untested n≈5 mechanism."

**Caveat:** J_cross between *different-domain roles* is not the same quantity SWR-Bench
measured (same task, different models). Low J_cross here partly reflects deliberate domain
partitioning, which is the design working as intended.

## Result 3 — Abstention probe: the role-split precision tax is not live. §4.5 closes.

| Probe | Diff content | security-reviewer output |
|---|---|---|
| NC1 | prose reword, critique doc | `FINDINGS: NONE` |
| NC2 | bats test-title reword | `FINDINGS: NONE` |
| NC3 | script comment reword | `FINDINGS: NONE` |

3/3 clean abstentions, with correct one-line rationales, despite the Stage 1.5 gate being
bypassed. The CR-Agent-derived worry — that a role-prompted critic manufactures findings
in its lane on empty input — **does not reproduce** with this repo's critic prompts on
this model. The `non-goals` blocks appear to be doing their job. Consequences:

- **§4.5 (restructure the critic panel) closes: do not restructure.** The one unverified
  benchmark number arguing for it is now also contradicted locally.
- Stage 1.5's evidence gate is belt-and-braces, not load-bearing. Its "when in doubt, run
  the critic" default is fine.
- Caveat: n=3, one critic, one model, and the probes were unambiguous no-surface diffs. A
  *plausible-surface-but-clean* diff (e.g. auth-adjacent refactor with no actual issue) is
  the harder abstention test and wasn't run.

## Result 4 — Quote-check retro: zero hallucinated paths, but 86% of findings are mechanically unanchorable

Against the 43 historical findings:

- **6/43** contain a mechanically checkable file reference at all.
- **6/6** of those resolve to real files at the cited commit — the two initial failures
  (`test-strategy.md`, `full-evaluation.md`) are basename shorthand for files that exist
  (verified at `f58db84`). **0 hallucinated locations.**
- **37/43** cite no path in a checkable format.

So the §4.1 quote-grounding proposal's value here is **not** hallucination suppression
(none observed) — it is that the current output format makes findings unauditable by
machine. The `Evidence:` field is still worth adding, but justified as *making the corpus
measurable* (and any checker must normalize shorthand paths before scoring).

## Result 5 — Blinded adjudication of the 43 historical findings

_Model-adjudicated (single blinded agent, tier and convergence stripped, order
randomized), not human-adjudicated — treat as a floor-quality estimate pending your pass.
The override log remains the human channel._

Raw verdicts: **27 valid / 16 invalid / 0 unsure → 63% precision-at-cited-commit.** But the
adjudicator's own escalation note identifies the right correction: 12 of the 16 invalids
are **temporal artifacts** — the rubric commits also contain the fixes, so the cited
defect is absent from the very tree the finding points at. Those 12 were accepted-and-fixed
by the author, i.e. true positives at review time. Corrected:

> **Precision at review time ≈ 39/43 ≈ 91%.**

The four genuine false positives, unblinded:

| ID | Tier | What went wrong |
|---|---|---|
| `f58db84` C2 | 🟢 | claimed a PII caveat was added; it wasn't (landed later) |
| `2b49452` C2 | 🟢 | claimed findings survive "only in git history"; they're still in-tree |
| `8ea4dab` C6 | 🟢 | self-declared benign, no action — a non-finding |
| `06f53b2` C2 | 🟢 | suggestion already satisfied by the existing text |

**Precision by tier at review time: 🔴 1/1 · 🟡 10/10 · 🟢 28/32 (87.5%).** Every genuine
false positive was in the advisory tier. Combined with Result 1's finding that severity
*assignment* is unstable, the picture is coherent: the pipeline is factually reliable
(91%, far above SWR-Bench's ~17% ballpark — different domain, mostly-markdown diffs,
so don't over-read the comparison), and its weakness is tiering/attention, not truth.

**The escalated-findings cross-tab, which is what §4.2 wanted:** all 4
convergence-escalated findings were factually valid at review time (2 fixed in-commit,
2 verified in-tree). The one the human waived (`f58db84` A4) the blinded adjudicator
scored **valid** — the human override was a *values* call ("metadata adds no value for
ephemeral artifacts"), not a factual refutation. So on n=4: convergence escalated only
factually-true findings, and the failure mode it produced was not a hallucination but a
**true-but-unwanted** finding promoted to blocking. That is a different defect than §2.1
predicted, and it points at the same remedy: convergence can prioritize, but promotion to
blocking should require corroboration the *author's values* can't dispute (a failing test)
or a human call.

**Method caveats:** single model adjudicator (not human — the override log remains the
human channel); the temporal correction assumes fixed-in-same-commit implies
valid-at-review-time (safe here: the author chose to fix them); blinding removed tier and
convergence but the adjudicator could sometimes infer commit context.

## Result 6 — External-repo corpus (added later same day): 287 findings, 99.0% valid — and why that number mostly isn't measuring the reviewer

Three work repos were cloned read-only into `external/`. Two carry format-compatible
rubric history (`nature_photographer`: 27 rubric commits, Jun 19–26; 
`meta-formalism-copilot`: 13 distinct rubrics incl. 6 per-branch, Apr–Jun — its pre-skill
era filters out automatically since extraction keys on rubric files). `threadwork` has no
code-review rubrics (only a spec-critic artifact in a different format) and is excluded.

Extraction: 287 findings (15 🔴 / 78 🟡 / 194 🟢 — 5/27/68%, near-identical to this
repo's 2/23/74 tier mix). Blinded adjudication (tier stripped, shuffled, 4 parallel
agents, temporal rule encoded from Result 5's lesson):

| | valid | invalid | precision |
|---|---|---|---|
| 🔴 (n=15) | 15 | 0 | 100% |
| 🟡 (n=78) | 78 | 0 | 100% |
| 🟢 (n=194) | 191 | 3 | 98.5% |
| **total** | **284** | **3** | **99.0%** |

The 3 invalids are all 🟢-tier factual errors (claimed SVG overflow that never existed;
"10 constants spread across files" when 5 exist in one file; a falsified "only
non-verb-first export" uniqueness claim). Consistent with Result 5: **every genuine false
positive across all four repos, n=330, sits in the advisory tier.** Blocking-tier
precision is 16/16 across all repos.

**The saturation caveat — flagged independently by 3 of the 4 adjudicators.** These
rubrics were committed *alongside their own fixes*. A finding the author judged wrong
would likely not produce a fix-and-commit-the-rubric event; discarded reviews (the Gate
1h pattern) and rejected findings are absent from this corpus by construction. So ~99%
is the precision of **author-accepted, persisted output** — an upper bound heavily
filtered by acceptance, not raw reviewer precision. The corpus is also useless for the
convergence question for the same reason: with verdicts saturated at valid,
precision(converged) = precision(single-critic) trivially. (Census for when better data
exists: 17 explicitly escalated + 17 convergent-but-unescalated findings — so the rule's
inconsistent application replicates in both external repos.)

**What this actually establishes:**

1. **Raw-precision measurement requires pre-triage capture.** The only way to measure
   what the reviewer emits (vs. what the author accepts) is to persist findings *before*
   the fix pass — which is precisely the date-stamping + worktree-copy + override-log
   fixes already queued. The retrospective route is exhausted.
2. **Path-anchoring needs basename resolution.** 54/287 findings carry checkable file
   refs; only 8 resolve as written — ~46 are basename shorthand (`genetics.ts` for
   `packages/sim-core/src/genetics.ts`), 1 cites a file that never existed. A mechanical
   `Evidence:` checker without basename resolution would false-positive on ~85% of
   citations.
3. **The domain-transfer caveat is retired.** np/mfc are real TS/TSX codebases and the
   tier mix, factual-accuracy profile, FP-lives-in-🟢 pattern, and
   inconsistent-escalation pattern all replicate.
4. **nature_photographer's override log: present, zero rows, 27 sessions** — the
   orphaned-write-path diagnosis replicates in a second repo.

## Incidental finding that outranks the experiments — the Gate 1h security cluster

All three D2 security runs independently converged (3/3, rated High/High/Med) on the same
finding about the **current** self-improvement review gate, and it compounds the
worktree-teardown issue already diagnosed:

> `self-improvement.sh` Gate 1h runs `cd "$WT_DIR" && claude -p ...` — the reviewing agent
> executes **inside the worktree of the branch it is reviewing**, so the branch under
> review controls the reviewer's `CLAUDE.md`, `.claude/` config, and the
> `skills/code-review/SKILL.md` the prompt tells it to load. A task branch can neuter or
> instruct its own reviewer.

Plus, stable across runs: the `CODE_REVIEW_RED:` sentinel is **last-match-wins over
merged stdout+stderr with no nonce**, so diff content containing the literal string (as
`test/code-review-gate.bats` itself does) or a prompt injection can plant a passing
verdict; and the gate **fails open** on unparseable output, `claude` crash (`|| true`),
or missing binary. This is the tracker's Thread 3 "review output is untrusted input"
scenario instantiated in the repo's own autonomous loop — the GitInject config-loading
issue, except self-inflicted. It should be fixed independently of everything else in this
program: read skill/config from the base ref (or `--setting-sources` pinning), nonce the
sentinel, and fail closed.

## Decision table after these results

| Proposal | Status after experiments |
|---|---|
| §4.1 quote-grounding / `Evidence:` field | **Adopt, reframed** — for auditability, not hallucination (none found). Normalize shorthand paths. |
| §4.2 demote escalation rule | **Adopt, re-justified** — rule is near-inert (convergence rare) and untested at n≈5, not demonstrably noisy. |
| §4.3 verifier pass | **Deprioritize.** At 91% review-time precision there is little false-positive mass for a keep/drop verifier to remove; BitsAI-CR's 17%→57% context doesn't exist here. Reconsider only if precision drops on harder (code-heavy) diffs. |
| §4.4 reviewer model ≠ fixer | Unaffected; still cheap, still supported. |
| §4.5 restructure role critics | **Closed: keep the role split.** Abstention is clean; roles partition rather than duplicate. |
| §4.6 ordering experiment | Not run (needs paired A/B against seeded bugs). |
| NEW: fix Gate 1h (reviewer-in-worktree, sentinel nonce, fail-closed) | **Do first.** 3/3-stable High finding on live autonomous infrastructure. |
| NEW: severity-band instability | Any future gate that keys on 🟡-vs-🟢 tier is keying on the *least* stable part of the output. Gates should key on issue identity or High-band findings, which are stable. |
| NEW (Result 6): retrospective precision measurement is exhausted | Persisted rubrics are acceptance-filtered (~99% valid by construction). Raw precision and the convergence question now *require* pre-triage capture — raising the priority of the worktree-copy and override-log fixes from "data hygiene" to "only remaining measurement path." |

## Reproduction

- Corpus/matching inputs: scratchpad `corpus.tsv`, `blinded-findings.md`, `blind-key.tsv`,
  `runs/summary-so-far.md`, `adjudication.tsv`.
- Negative-control branches: `exp/nc1-docs-reword`, `exp/nc2-test-rename`,
  `exp/nc3-comment-reword` (safe to delete after reading).
- Stability diffs: `45bea51~1..45bea51`, `2b81baa~1..2b81baa`, `9adc642~1..9adc642`.

## Limitations

Small n everywhere (3 diffs, 3 replicates, 3 probes, 1 model, 1 same-issue judge — me,
unblinded for the Jaccard matching). Directional evidence for design decisions, not
significance. The two results I'd trust most are the ones with the least judgment in them:
the 3/3 abstentions and the 3/3-stable Gate 1h High finding.
