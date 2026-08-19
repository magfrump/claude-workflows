# CRB direction (1) — our pipeline on the WithMartian benchmark: run setup

**Date**: 2026-08-18 · **Status**: harness built and dry-run green; **no paid
run yet, $0 spent** · **Parent**: `docs/working/crb-arm-plan.md` (direction (1),
"Next steps") · **Benchmark**: `external/code-review-benchmark` (withmartian,
MIT; offline half)

Direction (2) — their judge on *our* canon — already ran (crb-arm-plan
§"First real-judge results"). This doc covers the other direction: run **our
review pipeline on their 50 PRs** and score it with **their** judge, so the
result is a row in a 49-tool leaderboard we did not build.

## The four stages

| Stage | Command | Where | Cost |
|---|---|---|---|
| 1. Materialize PRs | `scripts/crb-materialize.py --per-repo 1` | sandbox or host | $0 (disk) |
| 2. Run the pipeline | `runs/review-arms/crb-pipeline/run-host.sh` | **host only** (docker) | the whole cost |
| 3. Inject as a tool | `scripts/crb-pipeline-to-benchmark.py` | sandbox | $0 |
| 4. Judge + rank | benchmark steps 2/2.5/3, then `scripts/crb-subset-leaderboard.py` | either | ~$1.5 (5 PRs) – ~$17 (50) |

### 1. Materialize

```bash
scripts/crb-materialize.py --list          # 50 PRs, 173 goldens
scripts/crb-materialize.py --per-repo 1    # 5-PR pilot: one per upstream project
scripts/crb-materialize.py --all           # all 50 (~6-7 GB)
scripts/crb-materialize.py --verify <slug> # re-assert containment on a clone
```

Clones the benchmark's fork of each PR (`claude-code`'s copy — any tool's fork
holds the same code) into `external/crb-eval/<slug>/` with `review` = PR head,
`main` = merge-base with the fork default branch, then **scrubs every other ref,
the remote and the reflogs** so a reviewing agent cannot reach the upstream
future through `git log --all`. Guards assert (a) zero commits outside the
reviewed ancestry and (b) a non-empty, blob-complete diff. Same contamination
discipline as `scripts/prep-cc-review-clones.sh` for the canon instances.

Pilot already materialized (`runs/review-arms/crb/instances.json`; clones under `external/crb-eval/`, gitignored):

| slug | goldens | commits | diff | disk |
|---|---|---|---|---|
| cal_com-PR11059 | 9 | 140 | 40 files +375/-119 | 190 MB |
| discourse-graphite-PR4 | 8 | 1 | 28 files +653/-13 | 33 MB |
| grafana-PR79265 | 5 | 5 | 11 files +105/-37 | 125 MB |
| keycloak-PR36880 | 5 | 1 | 1 file +3/-3 | 127 MB |
| sentry-greptile-PR5 | 6 | 32 | 106 files +2312/-981 | 195 MB |

33 goldens over 5 PRs. Note the spread: keycloak-PR36880 is a 3-line change
with 5 goldens, sentry-greptile-PR5 is a 106-file range — per-instance cost will
vary by an order of magnitude, so do not average the pilot naively into a
50-PR projection without weighting by diff size.

### 2. Run the pipeline (host, docker, ANTHROPIC_API_KEY)

```bash
ANTHROPIC_API_KEY=sk-ant-... bash runs/review-arms/crb-pipeline/run-host.sh
# subset:            ... run-host.sh discourse-graphite-PR4
# cheaper model:     MODEL=opus BUDGET=10 ... run-host.sh
# plan only ($0):    DRY_RUN=1 bash runs/review-arms/crb-pipeline/run-host.sh
```

Per instance: `claude -p "/code-review main"` in a fresh `node:22` container
with a **copy of this repo's payload** (`skills/ workflows/ guides/ patterns/
CLAUDE.md`, via `git archive $PAYLOAD_REF`) mounted as `~/.claude`. That is what
makes this *the pipeline* rather than Claude Code's built-in reviewer — E5/E7
deliberately run `--bare` so the payload does **not** load.

**The E8 payload is `main`.** `feat/critic-evidence-discipline` was merged at
`d9234c9`, and `git diff main feat/critic-evidence-discipline -- skills
workflows CLAUDE.md` is empty as of 2026-08-18, so `PAYLOAD_REF=main` (the
default) *is* the evidence-discipline arm. `run-meta.json` records the exact
payload commit, model, CLI version and per-cell cost for every sweep.

Two preflight checks run before any instance, because both failure modes cost a
whole sweep silently:
1. **auth** — a bad credential returns exit 0 with `"Not logged in"` (E7);
2. **skill registration** — the model is asked to list its skills and the run
   aborts unless `code-review` is among them. Without this check a mis-mounted
   payload would measure the built-in reviewer under the pipeline's name, which
   is exactly the failure decision 022 was written for.

Outputs land in `runs/review-arms/crb-pipeline/<slug>/`: `transcript.jsonl`
(full stream), `result.json` (cost/turns), `review.md` (final text), and
`artifacts/` (anything the pipeline wrote into the repo — the rubric and critic
reports). `transcript.jsonl` and `stderr.log` are **gitignored**: they quote
foreign-repo file contents verbatim, the same reason `runs/**/prompt.txt` is
ignored. The clone is reset with `git checkout -- . && git clean -qfdx` after
harvesting (`-x` so gitignored files the review created do not survive), so
re-runs start from the same state.

Three guards run per cell, all added after the 2026-08-18 review:

- **Containment is re-asserted before and after every cell** via
  `crb-materialize.py --verify <slug>` — the invariant is established at
  materialize time but the clone is then mounted read-write into an agent
  container, so it is re-checked rather than assumed. A pre-run failure skips
  the cell; a post-run failure marks that cell's result void.
- **Completed cells are skipped only if they actually succeeded** —
  `num_turns > 0 AND NOT is_error AND subtype == "success"`. A cell that
  exhausted `--max-budget-usd` still records turns, and a turns-only predicate
  would bank it as done and lock it out of retry.
- **`SWEEP_BUDGET` (default $75) caps the whole sweep**, re-summed from the
  cells on disk after each instance. `BUDGET` caps one instance only; without an
  aggregate an unattended `--all` can spend `BUDGET × 50`.

**Deviations from E8-as-run, to state in any results doc:** E8 was orchestrated
stage-by-stage by a session (k=2 fact-check, per-instance critic list). Here the
skill orchestrates itself in one unattended headless invocation, so stage count,
critic selection and k are whatever `skills/code-review/SKILL.md` decides.
Hooks and `scripts/` are not in the payload (E5/E7 also ran hookless).

### 3. Inject as a benchmark tool

```bash
scripts/crb-pipeline-to-benchmark.py                    # tool: mfc-pipeline-e8
scripts/crb-pipeline-to-benchmark.py --sections fix address \
    --tool-name mfc-pipeline-e8-redamber --out runs/review-arms/crb/offline-work-50-ra
```

Writes `runs/review-arms/crb/offline-work-50/results/benchmark_data.json`: the
benchmark's own file with our tool appended to each covered PR's `reviews`, all
49 other tools preserved. One review comment per rubric finding row (🔴/🟡/🟢);
`✅ Confirmed Good` rows are never emitted (they assert the code is fine —
counting them would inflate the FP denominator). No rubric artifact ⇒ fall back
to the headless result text as one freeform comment; the benchmark's extraction
step handles freeform markdown.

It also **seeds** `results/<judge>/{candidates.json,evaluations.json}` from the
benchmark's checked-in results for that judge, and writes a `RUN.md` runbook.

**Precision warning worth pre-registering:** the 49 benchmark tools post a
median of **4** findings per PR; an E8 rubric carries ~**16** (1 red + 8 amber
+ 7 green on `mfc-csp`). Every unmatched green counts as a false positive, so
the all-sections row will look precision-poor by construction. Score
`--sections fix address` as a second tool name (judging is per-tool, so this
costs one extra judge sweep, not a new review sweep) and report both. Note it is
a **separate** judge invocation over a separate work dir — the `--out` above —
so the two variants land in different `evaluations.json` files and cannot appear
in one leaderboard table; run `crb-subset-leaderboard.py` once per work dir.

### 4. Judge and rank

**Preferred — run the generated script.** The injector writes an executable
`judge.sh` into the work dir that sets every env var, refuses to start if
`MARTIAN_BASE_URL` is not an `api.anthropic.com` endpoint, and passes `--tool`
to all three steps:

```bash
ANTHROPIC_API_KEY=sk-ant-... runs/review-arms/crb/offline-work-50/judge.sh
```

Equivalent by hand (both footguns are on you):

```bash
cd runs/review-arms/crb/offline-work-50
export PYTHONPATH=/workspace/external/code-review-benchmark/offline   # or `uv sync` in offline/
# MARTIAN_BASE_URL is NOT optional: the benchmark defaults it to
# https://api.withmartian.com/v1 (step3_judge_comments.py:106), so exporting the
# key without it sends an Anthropic credential to a third party.
export MARTIAN_API_KEY="$ANTHROPIC_API_KEY" \
       MARTIAN_BASE_URL=https://api.anthropic.com/v1/ \
       MARTIAN_MODEL=claude-opus-4-5-20251101
python -m code_review_benchmark.step2_extract_comments   --tool mfc-pipeline-e8
python -m code_review_benchmark.step2_5_dedup_candidates --tool mfc-pipeline-e8
python -m code_review_benchmark.step3_judge_comments     --tool mfc-pipeline-e8

scripts/crb-subset-leaderboard.py --tool mfc-pipeline-e8   # ranking on OUR PRs only
```

- `MARTIAN_MODEL=claude-opus-4-5-20251101` on Anthropic's OpenAI-compatible
  endpoint matches the model id of the checked-in results dir
  (`anthropic_claude-opus-4-5-20251101`), so our row is comparable to the
  published leaderboard with no judge-variance caveat. The results dir the run
  writes is named after the id verbatim (`claude-opus-4-5-20251101`), which is
  why the injector seeds *that* directory.
- **`--tool` is mandatory on all three steps** (`judge.sh` does this for you).
  Without it step 2 re-extracts the **50** `(PR, tool)` pairs missing from the
  checked-in candidates file — all `greptile-v5`; 216 pairs are absent, 166 of
  them below step 2's ≥20-char extraction gate. Step 3 itself would *not*
  re-judge them, since the seeded `evaluations.json` is already complete at 2449
  pairs; the exposure is that those new extractions flow into **step 2.5**, for
  which no `dedup_groups.json` is checked in — roughly **2233 paid LLM calls**.
  Verified: with `--tool`, the pilot needs exactly as many extractions as we
  have cells.
- `crb-subset-leaderboard.py` re-aggregates **every** tool over exactly the PRs
  our arm reviewed (micro-averaged, step 3's convention). Step 3's own table
  compares our 5 PRs against their 50 — different denominators, not a ranking.

## Cost model

| Item | Estimate | Basis |
|---|---|---|
| Pipeline review, per instance | **$10–40** | canon ledger $14.60/instance (historical pipeline); E8 sweep re-derived at ~$19–44/instance on Fable. Benchmark diffs run smaller than canon instances but the repos are much larger to navigate. |
| 5-PR pilot | **~$50–200** | above × 5, wide because of the keycloak-vs-sentry spread |
| All 50 | **~$500–2000** | do not commit to this before a pilot |
| Judge (our tool only, opus-4-5) | **~$13–22 for 50 PRs**, ~$1.5 for a 5-PR pilot | 173 goldens × ~12–20 candidates/PR ≈ 2.1k–3.5k short judge calls at $5/$25 per MTok |
| Second scoring variant (red+amber) | + one judge sweep | no extra review cost |

`--max-budget-usd` (default `BUDGET=25.00`) caps each instance; `run-meta.json`
totals the billed `total_cost_usd` across cells, which is authoritative under
API billing.

## Caveats to carry into any results doc

1. **Training-data leakage** — the benchmark's own known limitation for the
   offline half. These PRs are public and predate our models' cutoffs; a high
   score is not evidence of generalization. Their online half exists for this
   reason and needs a GitHub app, so it stays out of scope here.
2. **Non-uniform golden denominators in the checked-in evaluations** — measured
   against `results/anthropic_claude-opus-4-5-20251101/evaluations.json`:
   **24 of the 50 PRs** have a `total_golden` that differs across tools (values
   range 1–9), because goldens were revised between tool runs. **Four of the
   five pilot PRs are affected**, and the skew is systematic rather than noisy:
   28 of the 49 tools were scored against a *smaller* golden set than our arm
   will be, which inflates their recall relative to ours. Cross-tool recall is
   therefore **not** denominator-uniform. `crb-subset-leaderboard.py` prints
   each tool's `gold` column and now also emits an explicit
   `GOLDEN-DENOMINATOR SKEW` warning on stderr whenever a subset contains such
   a PR, so this cannot be missed at write-up time.
   *(Corrected 2026-08-18: this caveat previously read "the same 2 PRs … 11 vs
   13", which understated the effect ~12× and cited values that occur nowhere in
   the file — the maximum golden count on any PR is 9.)*
2b. **Dedup asymmetry, in the opposite direction** — our arm is judged **with**
   `step2_5_dedup_candidates` active, while the checked-in rows for the other 49
   tools were judged **without** any `dedup_groups.json` present. Dedup
   suppresses false positives by propagating a match to sibling candidates, so
   our *precision* is flattered by an unmeasured amount. Report both this and
   caveat 2 together; they bias in opposite directions and neither is quantified.
3. **Our arm is judged on its rubric, other tools on posted PR comments.** The
   rubric is a denser artifact than an inline comment thread; the extraction
   step normalizes both to issue lists, but the shapes differ.
4. **Category profiles**: `offline/analysis/score_profiles.py` implements
   Strict/Core/All profiles by golden category. All numbers above are
   profile-free (All). Re-cut by profile before claiming a headline number.
5. **One sample per cell.** No replication is wired here (E7 exists for that
   question). Treat a pilot row as a point estimate.

## What is verified vs assumed

**Verified in this session ($0):** materialization of all 5 pilot clones with
both guards passing; the injector against a real E8 rubric fixture (16 findings
parsed from `mfc-csp`, 9 with `--sections fix address`); the full
extract → dedup → judge chain end-to-end with the offline stub shims; that a
seeded judge dir plus `--tool` confines work to our arm; and that the
subset-leaderboard reproduces a 49-tool ranking with our row inserted.
`run-host.sh` passes `bash -n` and its `DRY_RUN=1` path builds and validates the
payload (25 skills, `code-review` present).

**Not verified (needs the host / a key):** that headless Claude Code registers
payload skills from a mounted `~/.claude` — this is what the run's skill-
registration preflight tests, and it is the single highest-risk assumption in
the chain. Run one instance first (`run-host.sh keycloak-PR36880`, the smallest
diff) and read `review.md` + `artifacts/` before launching a sweep. Also
unverified: the Anthropic-endpoint judge path with a real key (only the stub
shims have run here), and the real per-instance cost.
