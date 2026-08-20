# CRB 5-PR pilot — step-by-step runbook

**Date**: 2026-08-19 · **Merged at**: `f6dc3f1` on `main` · **Design**:
`docs/working/crb-direction1-setup.md` · **Decisions**: `034`, log `#36`

Run our review pipeline on 5 PRs from the WithMartian Code Review Benchmark and
score the result with *their* judge, producing a row in a 49-tool leaderboard we
did not build.

> **Run every command from the WSL host terminal, never from inside a Claude
> Code session.** Docker cannot run inside a session — same constraint as
> E5/E7/cc-isolated.

**Expect to spend** roughly **$50–200** on the review sweep and **~$1.50** on
the judge. Steps 0–3 cost one billed auth turn in total.

---

## Before you start

| Prerequisite | Check | If missing |
|---|---|---|
| Docker running | `docker ps` | start Docker Desktop / `sudo service docker start` |
| Anthropic **API key** (not a subscription login) | `echo ${ANTHROPIC_API_KEY:0:7}` → `sk-ant-` | create one at console.anthropic.com |
| ~2 GB free disk | `df -h .` | the pilot needs ~1.3 GB (clones + baselines) |
| On `main` at the merge | `git -C /workspace log --oneline -1` → `f6dc3f1` or later | `git checkout main` |
| Tests green | `bats test/*.bats 2>&1 \| grep -c "^not ok"` → `0` (and `1..451` at the top) | stop and investigate |

**Why an API key specifically.** Under API billing each cell's `result.json`
carries an authoritative `total_cost_usd`, which is what `run-meta.json` totals
and what `SWEEP_BUDGET` gates on. A subscription login reports no usable cost
and hits a quota wall mid-sweep instead of a ceiling you chose.

```bash
cd /workspace
export ANTHROPIC_API_KEY=sk-ant-...
```

---

## Step 0 — See the plan without touching anything ($0)

```bash
bash runs/review-arms/crb-pipeline/prepare-sweep.sh --dry-run
```

Prints which of the 5 clones have baselines, whether your key is set, and what
the next two steps would do. Nothing is downloaded, built, or spent.

Expected today: **all five need a rebuild** (they were materialized before the
disposable-clone design and carry no baseline).

---

## Step 1 — Prepare: baselines, images, and prove the egress allowlist

```bash
bash runs/review-arms/crb-pipeline/prepare-sweep.sh
```

This does three things and then stops:

1. **Rebuilds any clone lacking a baseline.** This is a *re-clone*, not a
   repair: there is deliberately no mode that baselines an existing clone in
   place, because that path ran host `git` against a `.git` an agent container
   had written. Expect ~670 MB of download for all five. Idempotent — Ctrl-C
   and re-run is safe.
2. **Builds two images and proves the egress allowlist by execution** — the
   review image (`node:22` + pinned CLI) and the tinyproxy sidecar, then five
   preflight legs plus auth and skill registration. **Costs one billed auth
   turn.**
3. **Stops** and tells you the one-cell command.

**If `HTTPS_PROXY` turns out not to be honoured by Claude Code, this is where
you find out — for one turn, before any $10–40 cell.** That is the single
biggest unverified assumption in the chain.

### What "pass" looks like

```
== 2. Building images and PROVING the egress allowlist (one billed auth turn)
=== egress preflight
  ok  network created --internal
  ok  api.anthropic.com reachable through the proxy (HTTP 401)
  ok  non-allowlisted host refused (filter-blocks, HTTP 403)
  ok  non-allowlisted host refused (plain-http, HTTP 403)
  ok  non-allowlisted host unroutable without the proxy (network is --internal)
=== preflight
  preflight OK — auth good, code-review skill registered, egress constrained
```

`HTTP 403` is tinyproxy refusing by filter; **`HTTP 000` on those two legs is
also a pass** — the same refusal seen at connect level, before any status line.
The distinction between "refused" and "proxy is dead" is carried by leg 1, which
runs first and accepts no `000`.

Any leg failing exits **5** and spends nothing further. Do not work around it —
a failing leg means a review cell could reach github.com, where the answer key
lives, which invalidates the whole measurement.

### Useful variants

```bash
# only one instance
bash runs/review-arms/crb-pipeline/prepare-sweep.sh keycloak-PR36880

# baselines already built and you know it — skip straight to preflight
bash runs/review-arms/crb-pipeline/prepare-sweep.sh --skip-rebuild

# preflight on its own, any time (re-provable, one auth turn)
PREFLIGHT_ONLY=1 bash runs/review-arms/crb-pipeline/run-host.sh
```

---

## Step 2 — Run ONE cell and read it

```bash
bash runs/review-arms/crb-pipeline/run-host.sh keycloak-PR36880
```

`keycloak-PR36880` is deliberate: a 3-line diff with 5 goldens exercises the
whole chain for the least money (~$10–25, 5–10 min).

**Then read, in this order:**

```bash
less runs/review-arms/crb-pipeline/keycloak-PR36880/review.md      # did it review?
ls -R runs/review-arms/crb-pipeline/keycloak-PR36880/artifacts/    # did it write a rubric?
jq . runs/review-arms/crb-pipeline/run-meta.json                   # what did it cost?
```

**The rubric under `artifacts/` is the thing the injector scores.** No rubric
means the arm falls back to freeform result text — a different measurement.
This is the highest-risk assumption in the chain and one cell settles it. Do not
skip this read.

---

## Step 3 — Sweep the remaining four

```bash
bash runs/review-arms/crb-pipeline/run-host.sh
```

With no arguments it runs every instance in the manifest; the completed
`keycloak-PR36880` is skipped automatically (a cell is "complete" only if it
actually produced a review — see `scripts/crb-cell-status.py`).

Progress lands in `runs/review-arms/crb-pipeline/<slug>/`: `review.md`,
`result.json`, `artifacts/`, `attempts.jsonl`. `transcript.jsonl` and
`stderr.log` are gitignored — they quote foreign-repo contents verbatim.

### Options you may actually want

```bash
# CONTINUE PAST A CONTAINMENT VOID — the one policy decision.
# Default: a void HALTS the sweep (exit 7). A void means the containment control
# was observed FAILING on real work, so every later cell's number is suspect.
# Set this if you would rather collect the remaining cells and adjudicate
# voided_cells at write-up time. Costs $10-40/cell into a sweep whose central
# claim is already in doubt.
CONTINUE_ON_VOID=1 bash runs/review-arms/crb-pipeline/run-host.sh

# RAISE THE SWEEP CEILING. Caps total spend across all cells; default $250.
# The $50-200 pilot estimate fits under the default, so you should not need
# this for the pilot — raise it deliberately for --all (50 PRs: $500-2000).
SWEEP_BUDGET=400 bash runs/review-arms/crb-pipeline/run-host.sh

# CAP ONE INSTANCE. Default $25.00. Lower it to fail fast on a runaway cell.
BUDGET=15 bash runs/review-arms/crb-pipeline/run-host.sh

# CHEAPER MODEL. Default claude-fable-5 (matches E8, keeps the row comparable
# to the canon ledger). Opus is ~half the per-token price.
MODEL=opus BUDGET=10 bash runs/review-arms/crb-pipeline/run-host.sh

# RETRY BUDGET PER CELL. Default 2. A cell at MAX_ATTEMPTS is skipped, not
# re-paid; delete its directory to reset it deliberately.
MAX_ATTEMPTS=3 bash runs/review-arms/crb-pipeline/run-host.sh

# SUBSET, in any combination
bash runs/review-arms/crb-pipeline/run-host.sh grafana-PR79265 cal_com-PR11059

# PLAN ONLY, $0 — builds and validates the payload, starts no container
DRY_RUN=1 bash runs/review-arms/crb-pipeline/run-host.sh
```

Two more that exist but you should not normally set: `CC_VERSION` (default
`2.1.232`, pinned for reproducibility) and `PAYLOAD_REF` (default `main`, which
*is* the E8 arm). **Do not set `EGRESS_SUBNET`** — it takes effect on one side
only; the proxy's `Allow` is baked into its image, so a desync makes tinyproxy
refuse everything while the preflight still passes.

### Exit codes

| Code | Meaning | What to do |
|---|---|---|
| 0 | every requested cell ran or was already complete | proceed to step 4 |
| 1 | bad invocation / missing prerequisite | read the message; nothing spent |
| 2 | `SWEEP_BUDGET` reached | raise it and re-run — resumable |
| 3 | no cell ran and something was unusable | usually missing baselines → step 1 |
| 4 | a **check could not run** (cell-status, harvest, or audit) | investigate; the harness refused to guess |
| 5 | the egress allowlist could not be proven | do not work around it |
| 6 | finished, but ≥1 cell is VOID | read `voided_cells` before quoting any number |
| 7 | halted mid-sweep on a void | adjudicate, then `CONTINUE_ON_VOID=1` to resume |

### Resuming

Just re-run the same command. Completed cells are skipped, spend is ledgered per
*attempt* in `attempts.jsonl` so the budget gate survives a resume, and the gate
is checked *before* each cell rather than after.

---

## Step 4 — Inject as a benchmark tool ($0)

```bash
python3 scripts/crb-pipeline-to-benchmark.py
```

Writes `runs/review-arms/crb/offline-work-50/` with our tool appended to each
covered PR's `reviews`, all 49 other tools preserved, plus a seeded judge dir, a
`RUN.md`, and an executable `judge.sh`.

One review comment per 🔴 Must Fix / 🟡 Must Address row. **🟢 Consider is
excluded by decision (log #36)** — advisory rows rarely match a human PR
comment, and the benchmark scores `precision = TP / total_candidates`, so each
unmatched green would be a false positive. `✅ Confirmed Good` and
`Considered Overrides` are excluded too.

```bash
python3 scripts/crb-pipeline-to-benchmark.py --stats     # report only, write nothing
python3 scripts/crb-pipeline-to-benchmark.py --slug grafana-PR79265
```

Cells voided by the containment audit are refused here, by design.

---

## Step 5 — Judge and rank (~$1.50)

```bash
ANTHROPIC_API_KEY=sk-ant-... runs/review-arms/crb/offline-work-50/judge.sh
```

`judge.sh` sets every variable, passes `--tool` to all three benchmark steps,
and **refuses to start unless `MARTIAN_BASE_URL` is an `api.anthropic.com`
endpoint** — the benchmark otherwise defaults it to `api.withmartian.com`, which
would send your Anthropic key to a third party.

`--tool` is not optional decoration: without it, step 2.5 does roughly **2,233
paid LLM calls** instead of a handful. `judge.sh` handles this; if you run the
steps by hand, both footguns are yours.

Then the ranking over exactly the PRs our arm reviewed:

```bash
python3 scripts/crb-subset-leaderboard.py --tool mfc-pipeline-e8
python3 scripts/crb-subset-leaderboard.py --tool mfc-pipeline-e8 --markdown   # for a results doc
```

**Read the `SUBSET ATTRITION` line before quoting any number.** A cell that was
voided, budget-killed, or dropped at `MAX_ATTEMPTS` leaves the denominator
silently, and the cells that fail are the ones the pipeline struggled on — so
what remains is selected *for* pipeline success. If it prints
`attrition NOT checked`, fix that before believing the table.

---

## Caveats to carry into any results doc

1. **Training-data leakage** — the benchmark's own known limitation. These PRs
   are public and predate the models' cutoffs; a high score is not evidence of
   generalization. No container control touches this.
2. **Non-uniform golden denominators** — 24 of 50 PRs (4 of our 5) have a
   `total_golden` that differs across tools; 28 of 49 tools were scored against
   a *smaller* golden set than ours, inflating their recall relative to ours.
3. **Dedup asymmetry, opposite direction** — our arm is judged with
   `step2_5_dedup_candidates` active; the checked-in rows for the other 49 were
   not. This flatters our precision by an unmeasured amount.
4. **🟢 exclusion (log #36)** — a scoring choice that helps us, made before any
   judge run. Report it next to 2 and 3, which hurt us; naming only one
   direction would not be honest.
5. **Our arm is judged on its rubric, other tools on posted PR comments.**
   Different artifact shapes normalized by the same extraction step.
6. **One sample per cell.** No replication is wired here. A pilot row is a point
   estimate.
7. **Containment is prevention plus evidence.** Network retrieval of the answer
   key is *prevented* by the allowlist. `voided_cells: []` still means only
   "nothing was detected" — `run-meta.json` says so in its own
   `voided_cells_meaning` field. Unclosed: a DNS side channel through docker's
   embedded resolver, and retrieval that never touches the repository.

---

## Known rough edges

- **A cell whose container dies ledgers `cost_usd: 0`**, so `SWEEP_BUDGET` can
  under-count real spend. Bounded (it cannot retry forever) but reads low in the
  unsafe direction. Fine for a 5-cell pilot; worth fixing before a 50-cell run.
- **Nothing docker-shaped has ever executed** in development — no image built,
  no network created, no proxy run. Step 1 is the first execution of any of it.
  If something breaks, it will most likely break there, at one auth turn.

## If something goes wrong

```bash
# see what the sweep thinks happened
jq '{cells: (.cells | keys), voided: .voided_cells, missing: .missing_cells, total: .total_cost_usd}' \
   runs/review-arms/crb-pipeline/run-meta.json

# re-prove the egress control on its own
PREFLIGHT_ONLY=1 bash runs/review-arms/crb-pipeline/run-host.sh

# re-check one baseline without touching the work clone (read-only)
python3 scripts/crb-materialize.py --verify keycloak-PR36880

# rebuild one clone and its baseline from scratch
python3 scripts/crb-materialize.py --slug keycloak-PR36880 --force

# reset one cell to re-run it deliberately
rm -rf runs/review-arms/crb-pipeline/keycloak-PR36880

# tear down the egress network/proxy by hand (the runner does this on exit)
docker rm -f crb-egress-proxy; docker network rm crb-inner
```
