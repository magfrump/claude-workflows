# What-If Analysis: running the CRB direction-(1) sweep

**Proposal:** `docs/working/crb-direction1-setup.md` — materialize the WithMartian
benchmark's PRs, run our review pipeline on them headlessly, inject the output as a 50th
tool, judge it with the benchmark's own judge, and read our row against the published
leaderboard.
**Date:** 2026-08-19
**Upstream critiques:** none supplied as an argument. The Prior Art Check found three live
review artifacts on this same tree and they are treated as the already-examined baseline
(see below), so findings are tagged `[NOVEL]` relative to *those*, not relative to nothing.

> ℹ️ **No upstream critique was passed in.** The baseline used instead is
> `docs/reviews/pre-mortem-crb-direction1-sweep-2026-08-18.md` and the two code-review
> rubrics (`…-2026-08-18-…`, `…-2026-08-19-…`). Everything they cover is deliberately
> *not* re-derived here.

## Prior Art Check

Keywords swept over `docs/decisions/` (33 records) and `docs/working/`: *containment,
voided, attrition, denominator, leakage, egress, sweep budget, run-meta, benchmark,
golden, judge, payload, hypothesis, pre-registration*.

| Artifact | What it already covers — not re-derived here |
|---|---|
| `pre-mortem-crb-direction1-sweep-2026-08-18.md` | void-on-commit, staged-file carryover, subset attrition, `exit 2` provenance loss, the `logged in` substring |
| `code-review-rubric-2026-08-19-…` | R1/R2/R4 host-side git trust boundary (escalated, undecided), R5 run-meta contract, A6–A15 |
| `docs/decisions/015` | process isolation: default-deny egress, no host credentials inside the boundary |
| `docs/decisions/022` | the payload must load or the built-in reviewer is measured under the pipeline's name |
| `docs/decisions/012` | the repo's hypothesis grammar — adversarial framing, declared evaluator, preconditions |
| `docs/working/crb-arm-plan.md` | direction (2) is the *stated priority*; direction (1) is the secondary arm |

Two prior conclusions are carried forward and re-tagged below because the present proposal
does not carry them: decision 012's pre-registration convention (§Assumptions A1) and
crb-arm-plan's priority ordering (§Cost of Success).

---

## Assumptions Examined

**A1. Someone will act differently depending on the number.**
*Source:* implicit — the doc describes how to produce a leaderboard row and never says what
any value of it changes.
*If wrong:* **full retreat.** $50–200 (pilot) or $500–2000 (`--all`) buys a narrative
rather than a decision.
*Tag:* `[NOVEL]` `[PRIOR CONSIDERATION — docs/decisions/012]`. The repo has a hypothesis
grammar requiring adversarial framing, a declared evaluator, and preconditions, and
`grep -i crb docs/working/hypothesis-{log,backlog}.md` returns **nothing**. This arm is the
most expensive measurement in the repo's history and the only one with no pre-registered
claim. Concretely unanswerable today: *is a top-10 row a pass and a bottom-10 row a fail, or
is any row a "leakage-caveated point estimate" either way?* If it is the second, the
question is what the money buys.

**A2. One rubric row ⇒ one review comment ⇒ roughly one scored candidate.**
*Source:* explicit — "One review comment per rubric finding row"; the precision warning
counts **16** findings against a benchmark median of 4.
*If wrong:* **redesign of the precision framing.**
*Tag:* `[NOVEL]`. Verified in the vendored code: `step2_extract_comments.py`'s
`EXTRACT_PROMPT` instructs the model to "extract each distinct code issue… mentioned" from
each comment. Our rubric rows are not one-liners — R1 on the 2026-08-19 rubric enumerates
*five* execution paths in a single cell. Each such row becomes several candidates, and every
unmatched one is an independent false positive. The doc's stated ratio (16 findings vs 4)
is a lower bound on the real candidate count, and `--sections fix address` (9 rows) does not
reduce it proportionally because the reds and ambers are the *densest* rows.
Correction to the doc while here: the benchmark's median is **3** comments per (PR, tool)
over 2,449 pairs, not 4.

**A3. The 5-PR pilot is a scaled-down 50-PR sweep.**
*Source:* implicit in the cost model ("above × 5") and in "run a pilot before committing".
*If wrong:* **redesign of the extrapolation** (the pilot stays useful as a smoke test).
*Tag:* `[NOVEL]`. `crb-materialize.py:126,136-138` selects `--per-repo N` as "the N PRs
with the **most golden comments** in each source repo". The pilot is therefore the
golden-richest tail by construction: **33 goldens over 5 PRs = 6.6/PR**, against a
population of 173 over 50 = 3.46 mean, median 3, range 1–9. Since our arm emits a roughly
fixed ~16 findings regardless of PR size, precision is bounded near `goldens / candidates`:
the pilot's ceiling is ~2× the median PR's. **A good pilot precision is not evidence for the
full sweep, and a bad one is worse than it looks.** The doc warns about weighting by *diff
size*; the selection bias is on *golden count*, and runs the other way.

**A4. `BUDGET=25.00` is a safety net.**
*Source:* explicit default at `run-host.sh:61`.
*If wrong:* **tweak**, but it is load-bearing on attrition.
*Tag:* `[NOVEL]`. The doc's own cost model puts the pipeline at **$19–44/instance** (E8
triangulation, `e8-results-2026-08-18.md:29-30`). The per-instance cap sits *inside* that
band, so budget-kill is a designed-in outcome for roughly the upper half of the
distribution, not an edge case — and the largest instance in the pilot
(`sentry-greptile-PR5`, 106 files, +2312/-981) is the one most likely to hit it. Each hit
costs the cap, produces a truncated or absent rubric, triggers a retry (`MAX_ATTEMPTS=2`),
and then leaves the denominator via the attrition path the pre-mortem already named. The
interaction — *the cap is what generates the attrition the leaderboard warns about* — is
not stated anywhere.

**A5. Skill registration ⇒ the pipeline ran.**
*Source:* explicit — the preflight "aborts unless `code-review` is among them", described as
covering "the single highest-risk assumption in the chain".
*If wrong:* **redesign.**
*Tag:* `[NOVEL]` `[PRIOR CONSIDERATION — docs/decisions/022]`. Registration is checked once,
before any instance; nothing checks *per cell* that the multi-stage pipeline actually
executed. E8-as-run was session-orchestrated (staged fact-check, per-instance critic list);
here one headless `claude -p "/code-review main"` must self-orchestrate — the doc flags this
as a deviation to disclose, not as something to verify. A cell where the skill loaded but
degraded to a single-pass read still produces a plausible `review.md`, and
`crb-pipeline-to-benchmark.py:174-178` **silently** accepts it via the freeform fallback.
Decision 022 exists to stop the built-in reviewer being measured under the pipeline's name;
the preflight closes the *mounting* half of that and leaves the *execution* half open.

**A6. The judging work dir can be re-run when the pipeline improves.**
*Source:* implicit — nothing says otherwise, and `judge.sh` is presented as the repeatable
entry point.
*If wrong:* **redesign of the artifact's lifecycle.**
*Tag:* `[NOVEL]` — see `[REVERSIBILITY CLIFF]` below. Verified: `step3_judge_comments.py`'s
`EvaluationState.is_done(golden_url, tool)` skips any already-scored pair, step 2 does the
same for candidates, and the injector prints `Kept existing …` rather than re-seeding.
`judge.sh` passes no `--force`. A second sweep under the same tool name into the same
`--out` therefore reproduces the **first** sweep's scores, with no warning, under the new
payload's name.

**A7. Matching the judge's model id makes our row comparable to the published one.**
*Source:* explicit and emphasized ("no judge-variance caveat").
*If wrong:* **tweak** — one more caveat, alongside the two already carried.
*Tag:* partly `[NOVEL]`. `MARTIAN_MODEL` is read by all three steps
(`step2:71,88`, `step3:95,112`), so it names the *extractor* and *deduper* as well as the
judge. This is mostly saved by the results dir being keyed on that same id — the seeded
`candidates.json` was extracted with the same model. What is not covered: the vendored
extraction/judge **prompts and code** are today's, while the checked-in candidates were
produced by whatever version the benchmark authors ran. The doc's comparability claim is
argued for the model and silently extended to the pipeline.

**A8. The 50 PRs are one population.**
*Source:* implicit throughout; caveat 1 treats leakage as uniform.
*If wrong:* **tweak** to the reporting, but it changes how the headline reads.
*Tag:* `[NOVEL]`. Counted from `benchmark_data.json`: **15 of 50** PRs live under the
`ai-code-review-evaluation` org (benchmark-authored), the other 35 under
calcom/grafana/keycloak/getsentry (real upstream history). Caveat 1's "these PRs are public
and predate our models' cutoffs" is a strong claim about the 35 and a weak one about the 15.
The pilot contains two of the benchmark-authored kind (`discourse-graphite-PR4`,
`sentry-greptile-PR5`) and three real ones, so the mix is a live driver of a 5-PR number.

**A9. `parse_location`'s "judging is text-only" claim.**
*Verified true* — `JUDGE_PROMPT` receives `{golden_comment}` and `{candidate}` and nothing
else; no path, no line, no diff. Not a finding, but it has an unstated consequence: a
finding that names the right symptom in the wrong file still scores as a true positive. That
cuts *in our favour* and belongs next to caveat 3, which currently frames the artifact-shape
difference as if it were only a handicap.

---

## Consequence Chains

**Chain 1 — the harvest, the commit, and the shape of the measurement**

```
→ First-order: the agent reviews the PR and writes a rubric into the clone
  → Second-order: the payload's own CLAUDE.md (mounted into every container, §Commit
    triggers, /away default) tells it to commit — so on the diligent cells the rubric is
    COMMITTED, and `git status --porcelain` at run-host.sh:377 reports a clean tree
    → Third-order: the harvest loop copies nothing; `artifacts/` is empty; the injector's
      rubric path finds no `*rubric*.md` and falls back to review.md as ONE freeform comment
      → Fourth-order: the "✅ Confirmed Good rows are never emitted" protection is defeated
        for that cell — the freeform chat summary contains the confirmed-good prose, step 2
        extracts some of it as "issues", and each becomes a guaranteed false positive
      → Fourth-order (alt): the sweep silently mixes two measurement instruments —
        rubric-derived cells and freeform-derived cells — and nothing aggregates by
        `source_provenance`, which is the only field that records which one you got
```

This survives the 2026-08-18 pre-mortem's fix. That fix stopped a committed rubric from
*voiding* the cell; it did not make a committed rubric *harvestable*, because the harvest
runs before the reset and keys on `git status`, which is relative to the moved HEAD. The
bias is systematic and pointed the wrong way: the cells that lose their rubric are the ones
where the agent followed the payload's instructions most faithfully.

**Chain 2 — the precision floor and what it tempts**

```
→ First-order: ~16 rubric rows are injected per PR against a median of 3 goldens
  → Second-order: step 2 splits the dense rows further, so scored candidates exceed 16;
    micro-averaged precision lands far below the 49-tool field
    → Third-order: the row is read as "the pipeline is precision-poor", and the obvious
      remedy is to make the pipeline emit fewer findings
      → Fourth-order: that is a direct trade against what E8 was built for (0 confirmed
        FPs at 87% recall on the living ledger). Tuning finding-density to a 5-PR benchmark
        row optimizes the artifact the repo has explicitly decided is NOT the goal.
    → Third-order (alt): the `--sections fix address` variant is read as the "fair" row and
      the all-sections row as noise — but neither is a like-for-like comparison, because the
      other 49 tools post inline PR comments and ours posts a rubric, and the injector's two
      variants land in different work dirs that cannot appear in one table.
```

**Chain 3 — the pilot that authorizes the sweep**

```
→ First-order: the pilot returns a defensible-looking row on 5 PRs
  → Second-order: `--all` is authorized at $500–2000 on a precision figure computed on the
    golden-richest 5 PRs in the corpus (A3) and a recall figure computed only on the cells
    that survived (attrition, already known)
    → Third-order: the full sweep returns a materially worse row, and the difference is
      read as variance or as a pipeline regression rather than as the pilot's selection
      bias — because nothing in the output records that `--per-repo` ranked on golden count
    → Third-order: 50 clones (~6–7 GB) and a 2,000-line harness with an escalated,
      undecided trust-boundary question become standing infrastructure
```

---

## Coupling Analysis

| Coupling | Visible? | Note |
|---|---|---|
| `MARTIAN_MODEL` → extractor **and** deduper **and** judge | Invisible (one env var, three roles) | A7. The comparability argument covers one of the three. |
| Tool name (`mfc-pipeline-e8`) → `benchmark_data.json`, `candidates.json`, `evaluations.json`, `run-meta.json`, leaderboard `--tool` | Visible as a string, invisible as an identity | **Nothing binds a scored row to the payload sha.** The sha lives only in `run-meta.json`, which the writer overwrites per invocation. Two sweeps of two different payloads produce indistinguishable rows. `[HIDDEN COUPLING]` |
| Payload `CLAUDE.md` → harvest completeness | Invisible | Chain 1. The pre-mortem mapped this edge to *containment*; the *artifact-capture* edge was missed by both. |
| `BUDGET` → truncation → retry → attrition → recall bias | Invisible (four subsystems, one constant) | A4. |
| `--per-repo` ranking key → precision ceiling | Invisible | A3. A materialization flag silently sets the metric's ceiling. |
| Judged results dir → write-once per (PR, tool) | Invisible | A6. |
| `docs/working/` results doc → future sessions | Invisible, and this repo demonstrably does it | The repo's own working docs are read as fact by later sessions; the 2026-08-18 caveat-2 correction ("understated the effect ~12×, cited values that occur nowhere in the file") is the existence proof. |

No finding on the run-meta ↔ leaderboard contract: that is rubric R5, already fixed.

---

## Confidence Inversions

**"The skill-registration preflight is the single highest-risk assumption in the chain."**
Inverted: suppose registration is the *easy* half. The container is `node:22` with a mounted
`~/.claude`; the skill either appears in the list or it does not, and the preflight is
binary, cheap, and fails closed. The hard half is whether the registered skill, invoked once
headlessly with no session orchestrating it, executes the multi-stage pipeline that E8
measured — a graded outcome with no check at all, and a silent acceptance path in the
injector (A5). The doc's stated top risk is the one that fails loudly; the unstated one
fails quietly and produces a number.

**"The E8 payload is `main` — the diff is empty, so `PAYLOAD_REF=main` *is* the
evidence-discipline arm."**
The claim is about file contents and is true as stated (verified 2026-08-18). It is being
used, though, to license a stronger claim — that this measures E8. E8 was a *process*: k=2
fact-check, per-instance critic selection, staged orchestration, evidence capture. The
payload is E8's text; the run is not E8's procedure, and the doc says so in one line under
"Deviations". If the row is later cited as "the E8 pipeline scored X on CRB", the deviation
paragraph is the only thing standing between that sentence and a category error.

**"Seeding plus `--tool` makes the judge cost bounded and the comparison clean."**
Both halves are verified and hold. Inverted on the *second* run rather than the first: the
same seeding that bounds the cost is what makes the work dir write-once (A6). The mechanism
that protects the budget is the mechanism that silently serves stale scores.

**"A pilot de-risks the sweep."**
Inverted: given A3, the pilot is the single most flattering 5-PR subset the corpus admits
for precision, and given attrition it is the most flattering surviving subset for recall.
A pilot can only fail *loudly* (harness broken, cells voided) — it cannot fail
*quantitatively*, because there is no value it could return that would honestly predict the
50-PR row. It is a smoke test priced like an experiment. That is fine, if it is called that.

---

## Adversarial Scenarios

**S1 — The diligent agent (realistic worst case, ~30–50% of cells).**
Every cell's agent follows the mounted `CLAUDE.md` and commits its rubric. Containment now
resets rather than voids (the pre-mortem's fix landed), so nothing looks wrong: cells
succeed, `voided_cells` is empty, `run-meta.json` reports a healthy total. But `artifacts/`
is empty on those cells, every one falls back to freeform `review.md`, and the sweep's
headline is computed over a mixture of two instruments — with the confirmed-good prose
counted as findings on the freeform half. Observable only by reading `source_provenance` per
cell, which nothing aggregates. **Severity: high** — it corrupts the measurement rather than
the run, and it does so most on the best-behaved cells.

**S2 — The expensive tail (likely on `--all`, plausible on the pilot).**
`sentry-greptile-PR5` and its 50-PR equivalents exceed `BUDGET=25` (A4). Each burns the cap,
retries, burns it again, and exits the denominator. The surviving subset is the small-diff
PRs; recall rises; the SUBSET ATTRITION line fires and correctly names them, and the results
doc quotes the number above it anyway because the line reads as bookkeeping. **Severity:
medium-high**, and fully mitigated by raising `BUDGET` before the first paid cell.

**S3 — The improved pipeline, re-measured (near-certain if the arm is used twice).**
Three weeks later the pipeline improves and the sweep is re-run under the same tool name into
the same work dir. `judge.sh` runs to completion, prints a table, costs almost nothing —
because step 2 and step 3 skip every already-scored pair. The new row is the old row. The
cheapness is the tell, and the only thing that would surface it is noticing that a paid step
was suspiciously fast. **Severity: high** — it produces a *confidently wrong* comparative
claim ("the change moved us from X to Y" / "no change"), which is worse than producing
nothing.

---

## Reversibility Map

| Horizon | Reversal cost |
|---|---|
| **1 week** | Near-free. The work dir is a copy; `external/code-review-benchmark` is untouched; clones are gitignored; `--reset` restores them. Only the spend is gone. |
| **1 month** | **Cliff 1 — the judged work dir is write-once.** `evaluations.json` now holds our tool's rows and every later run skips them (A6). Reversal means knowing to delete the results dir or pass `--force`, and neither `judge.sh`, `RUN.md`, nor the setup doc mentions it. **Cliff 2 — the number is in `docs/working/`** and is being read by later sessions as fact; retracting it means finding every citation, which this repo has already had to do once (caveat 2's ~12× correction). |
| **6 months** | **Cliff 3 — Goodhart.** If the pipeline has been tuned toward the row (Chain 2), reversal is not deleting a file, it is unwinding skill changes whose justification was a benchmark number computed on 5 golden-rich PRs. **Cliff 4 —** if `--all` ran, ~6–7 GB of clones and the containment/trust-boundary design (rubric R1/R2/R4, escalated and undecided) are standing infrastructure with a maintenance obligation. |

The gradient is **steep and early**: it is flat for about a week and then hits Cliff 1, which
is invisible and mechanical. Cliff 1 is cheap to remove today (a staleness check in
`judge.sh`) and expensive to detect later.

---

## Cost of Success

Suppose everything works: containment holds, no cell voids, the sweep costs $150, the judge
costs $1.50, and `mfc-pipeline-e8` lands mid-table on 5 PRs with both caveat directions
honestly reported.

- **Complexity.** The repo now owns ~2,000 lines across four scripts, 398 tests, a
  containment mechanism whose review loop hit its 3-iteration cap and was *escalated*
  undecided, and a payload/trust-boundary design that only this arm needs. That is carried
  for one row in someone else's table.
- **Opportunity.** `crb-arm-plan.md:9` states that **direction (2) is the priority** — their
  judge on our canon, where we control the goldens and the leakage story is clean. Direction
  (1) is the secondary arm and has now consumed six commits, three review passes, a
  pre-mortem, and this analysis. `[SUCCESS COST]` `[PRIOR CONSIDERATION]`
- **Maintenance.** `external/code-review-benchmark` is a vendored third-party repo. Every
  future comparison needs it pinned at this revision, because the checked-in candidates were
  produced by *its* code at *its* time (A7). A `git pull` there silently invalidates the
  comparability argument.
- **Optionality.** The strongest cost. A mid-table row on a 49-tool leaderboard is a legible
  number in a project whose other metrics are hand-adjudicated living ledgers. Legible
  numbers win arguments against illegible ones regardless of which is more valid, and this
  one is the least valid metric the repo owns: n=5, leakage-caveated, non-uniform
  denominators, dedup-asymmetric, and computed on a golden-rich subset. Success makes it the
  default reference point.

---

## Findings Summary

| # | Tag | Finding |
|---|---|---|
| F1 | `[SECOND-ORDER EFFECT]` `[HIDDEN COUPLING]` `[NOVEL]` | A **committed** rubric is invisible to the harvest (`git status --porcelain` at `run-host.sh:377` is relative to the moved HEAD), so the cell silently falls back to freeform `review.md` — defeating the confirmed-good exclusion and mixing two measurement instruments in one sweep. The pre-mortem's fix stopped the *void*, not the *loss*. |
| F2 | `[UNEXAMINED ASSUMPTION]` `[NOVEL]` | No pre-registered decision rule or hypothesis exists for the most expensive measurement in the repo, against decision 012's own convention. |
| F3 | `[UNEXAMINED ASSUMPTION]` `[NOVEL]` | `--per-repo` selects the **golden-richest** PRs (6.6/PR vs a population median of 3), so the pilot is the most precision-flattering subset the corpus admits. Neither the doc nor the leaderboard records this. |
| F4 | `[UNEXAMINED ASSUMPTION]` `[NOVEL]` | Registration ≠ execution: nothing verifies per cell that the multi-stage pipeline actually ran, and the injector's freeform fallback silently accepts a degraded run. |
| F5 | `[REVERSIBILITY CLIFF]` `[NOVEL]` | The judged work dir is write-once per (PR, tool): `is_done()` makes a re-run under the same tool name reproduce the old scores, cheaply and silently. `judge.sh` passes no `--force`. |
| F6 | `[SECOND-ORDER EFFECT]` `[NOVEL]` | Step 2 splits each dense rubric row into several candidates, so the real FP denominator exceeds the "16 findings" the precision warning is based on; `--sections fix address` does not reduce it proportionally. (Also: the benchmark's median is 3 comments per (PR, tool), not 4.) |
| F7 | `[HIDDEN COUPLING]` `[NOVEL]` | `BUDGET=25` sits inside the doc's own $19–44/instance band, so budget-kill is a designed-in generator of the attrition the leaderboard warns about. |
| F8 | `[HIDDEN COUPLING]` `[NOVEL]` | Nothing binds a scored row to the payload sha; it lives only in `run-meta.json`, which is overwritten per invocation. |
| F9 | `[UNEXAMINED ASSUMPTION]` `[NOVEL]` | 15 of 50 PRs are benchmark-authored (`ai-code-review-evaluation`); the leakage caveat applies unevenly, and the pilot mixes both populations 2:3. |
| F10 | `[UNEXAMINED ASSUMPTION]` | `MARTIAN_MODEL` drives extraction and dedup as well as judging; comparability was argued for the judge role only. Mostly covered by the per-model results dir, not by code/prompt drift in the vendored repo. |
| F11 | `[SUCCESS COST]` `[PRIOR CONSIDERATION]` | Direction (2) is the stated priority in `crb-arm-plan.md`; direction (1) has absorbed six commits and three review passes. A legible mid-table row also becomes the default reference point over the repo's more valid but less legible ledger metrics. |
| F12 | `[SUCCESS COST]` | Comparability is pinned to `external/code-review-benchmark` at its current revision; updating it silently invalidates the argument. |

---

## Recommendations

### Must address before proceeding

1. **F1 — harvest relative to the manifest head, not `git status`.** Collect
   `git diff --name-only --diff-filter=d <manifest_head> HEAD` **plus** the existing
   untracked/modified records, then dedupe, keeping the existing extension and path-traversal
   guards. Without this, the cells where the agent behaves best are the cells whose rubric is
   lost, and the loss is only visible in a per-cell `source_provenance` string nothing reads.
   *Cheap check that this is happening:* after the first paid cell, if `artifacts/` is empty
   while `git -C <clone> log --oneline <manifest_head>..HEAD` is not, F1 fired.
2. **F4 — assert per cell that the pipeline ran.** After harvest, require a rubric artifact
   with at least the section headings the skill emits, and record a `pipeline_signature`
   field (rubric present / critic count / stage count) per cell in `run-meta.json`. Make the
   injector's freeform fallback **opt-in** (`--source result`) rather than the silent default
   for `auto`, so a degraded cell fails loudly instead of contributing a differently-shaped
   row. This is the execution half of decision 022.
3. **F2 — write the hypothesis before spending.** One entry in `docs/working/hypothesis-log.md`
   in the decision-012 grammar, adversarially framed, naming the evaluator and what result
   would change what. Free, and it is what separates this from a $150 anecdote.
4. **F3 + F5 + F9 — a fixed reporting block, decided now rather than at write-up.** Any
   results doc must carry, in the same block as the headline: the SUBSET ATTRITION lines, the
   golden-denominator skew warning, "the pilot PRs were selected as the golden-richest per
   repo, which raises the precision ceiling relative to the 50-PR population", the
   benchmark-authored-vs-upstream split of the subset, and **absolute tp/fp/fn** rather than a
   rank alone — at n=5 and 33 goldens a leaderboard *position* is not identifiable and should
   not be quoted. Adding the selection-bias sentence to `crb-subset-leaderboard.py`'s
   `--markdown` output is the mechanical version and costs ~10 lines.

### Worth mitigating

5. **F5 — a staleness guard in `judge.sh`.** Before step 2, if `evaluations.json` already
   contains rows for `--tool`, print the payload sha they were produced under and refuse
   unless `CRB_REJUDGE=1` (which then passes `--force`). ~8 lines, and it prevents the one
   scenario (S3) that yields a confidently wrong comparative claim.
   *Watch signal:* a judge run that finishes far faster or cheaper than the ~$1.5 estimate.
6. **F7 — raise `BUDGET` above the E8 band before the first paid cell** (≥$50), or state
   explicitly that budget-kill is an accepted attrition source and record cap-hits in
   `run-meta.json` as a distinct reason string, so §4's block can name them.
7. **F8 — put the payload sha in the tool name** (`mfc-pipeline-e8-<sha8>`) or in a
   `payload_sha` field written into the injected review entry. The tool name is the only
   identity that survives into `evaluations.json`; making it self-describing removes both F5
   and F8 at once.
8. **F6 — measure it instead of estimating it.** After the first cell, run step 2 alone and
   count candidates per injected comment. If a rubric row averages >1.5 candidates, the
   precision pre-registration in §4 should use the measured ratio, not "16 vs 3".

### Acknowledged risks

- **The host-side git trust boundary (rubric R1/R2/R4) and the egress control (R3).** Already
  escalated to a recorded human decision; deliberately not re-litigated here. Note only that
  F1's fix adds one more host-side git invocation against a container-written `.git`, so it
  should be written to be sequenced *after* whatever sanitization that decision produces.
- **n=5 rank instability.** Carried knowingly, and cheap to carry once §4's reporting block
  forbids quoting a rank. The pilot's job is to prove the harness, not to estimate the score.
- **F10 / F12 — vendored-benchmark drift.** Low probability over the arm's lifetime; pin the
  revision in the results doc and move on.

If the pre-mortem's failure narratives are wanted for F1 or F5 specifically, they are the two
findings here whose failure mode is a *silent wrong number* rather than a visible break, and
so the two most worth turning into narratives.
