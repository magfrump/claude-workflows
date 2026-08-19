# Performance Review — commit `197eec6` (feat/crb-direction1-harness)

**Scope:** commit `197eec6` only (partial scope). Files evaluated on the resulting code:
`runs/review-arms/crb-pipeline/run-host.sh`, `scripts/crb-materialize.py`,
`scripts/crb-harvest-artifacts.py`, `scripts/crb-audit-clone.sh`,
`runs/review-arms/crb-pipeline/docker/{Dockerfile.review,Dockerfile.proxy,tinyproxy.conf,egress-allowlist}`
**Date:** 2026-08-19
**Based on:** `docs/reviews/code-fact-check-report.md` (merged, k=3),
`docs/decisions/034-crb-egress-allowlist-and-disposable-clones.md`
**Performance frame:** dollars and sweep throughput, not milliseconds. A cell is a $10–40
headless review; a sweep is 5–50 cells under a `SWEEP_BUDGET` ceiling.

---

## Data Flow and Hot Paths

`run-host.sh` is a serial, operator-launched sweep. Once per invocation it builds two images,
creates an `--internal` docker network plus a tinyproxy sidecar, runs a three-leg egress
preflight and one paid model preflight. Then, once per instance, it: checks for a baseline tar
→ `crb-materialize.py --restore` (rmtree + sha256-verified tar extract) → copies the payload →
runs the review container → parses the transcript → `crb-harvest-artifacts.py` (tree walk +
sha256 diff against the baseline index) → launches a second, throwaway container running
`crb-audit-clone.sh` → appends to `attempts.jsonl` → re-scans every cell's ledger against
`SWEEP_BUDGET`.

**Path temperature.** Nothing here is a request handler. The per-cell loop body is the hottest
path in the system and it executes at most 50 times, gated by a review that costs $10–40 and
minutes of wall clock. `materialize()` / `--snapshot` / `--verify` are cold: once per slug,
operator-invoked. Severity is therefore driven by *dollars per occurrence*, not by CPU.

**Sizes, measured on this host (2026-08-19, `/workspace/external/crb-eval`, 5 pilot clones):**

| slug | clone (du) | `.git` | tar | `.md`/`.json` files | inodes |
|---|---|---|---|---|---|
| discourse-graphite-PR4 | 41 MB | 10 MB | 33 MB | 49 | 4,692 |
| cal_com-PR11059 | 206 MB | 75 MB | — | 358 | 5,058 |
| keycloak-PR36880 | 162 MB | 43 MB | — | 215 | — |
| grafana-PR79265 | 170 MB | 32 MB | 137 MB | 1,490 | 16,319 |
| sentry-greptile-PR5 | 243 MB | 33 MB | 210 MB | 711 | 19,601 |

**Per-cell overhead this commit adds, measured on the same clones** (Python replicas of
`snapshot_baseline`/`restore_clone`/`artifact_index`/`changed_artifacts`, and the audit's own
git commands run directly against the clones):

| step | discourse (33 MB) | grafana (137 MB) | sentry (210 MB) |
|---|---|---|---|
| sha256 over baseline tar | 0.02 s | 0.1 s | 0.1 s |
| `rm -rf` work clone | 0.04 s | 0.2 s | 0.2 s |
| `tar --extract` | 0.1 s | 0.6 s | 0.6 s |
| harvest walk + sha256 (`.md`/`.json`) | 0.02 s | 0.1 s | 0.05 s |
| audit `git fsck --connectivity-only` | 0.01 s | 0.02 s | 0.02 s |
| audit `find` for nested repos | 0.00 s | 0.02 s | 0.02 s |
| audit `rev-list --all --not HEAD` | 0.00 s | 0.00 s | 0.00 s |

Adding ~1 s for the extra `docker run` of the audit container and ~0.3 s for five short-lived
`python3` interpreters, **the commit's added per-cell overhead is ≈ 2–3 s on the largest pilot
clone**. Against the closest measured per-cell review duration on this project — 4.5–10.8
minutes per cell for the cubic CLI arm (`docs/working/archive/2026-08-19-canon-issue-ledger.md:331`)
— that is **0.3–1.1% of one cell**, or roughly 2 minutes across a 50-cell sweep. The
"seconds, not minutes × 50" question the scope asks is answered on the measured side: seconds.

**Disk.** Baselines are uncompressed tars, so the doubling in decision 034 is real
(`fact-check claim 1 — Mostly Accurate`). Measured free space on the clone filesystem is
**280 GB of 1,007 GB (71% used)**, so `--all` at ~13 GB consumes ~1.3% of remaining headroom.
Disk is not a binding constraint on this arm.

The cost risks in this commit are therefore **not** its compute. They are in the retry, budget
and liveness machinery that surrounds the paid container.

---

## Findings

#### A cell that dies before emitting a `result` event retries without bound and ledgers $0

**Severity:** High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:376-401`, `:460-470`, `:529-539`
**Move:** Count the hidden multiplications / price the deployment environment
**Classification:** Macro (unbounded retry of a priced operation) / Hot path (the per-cell loop body, the only path that spends money)
**Confidence:** High
**Baseline:** $14.60/instance measured on the canon ledger; $19–44/instance re-derived on the
E8 sweep (`docs/working/crb-direction1-setup.md:305`). `BUDGET` defaults to $25.00
(`run-host.sh:82`).

Both retry guards are nested inside the same existence test:

```
376:  if [ -s "$dest/result.json" ]; then
...
389:  if [ -s "$dest/result.json" ]; then
...
398:    if [ "$attempts" -ge "$MAX_ATTEMPTS" ]; then
399:      echo "=== $id — $attempts failed attempt(s), at MAX_ATTEMPTS — skipping (delete $dest to reset)" >&2
400:      skipped_bad=$((skipped_bad+1)); continue
```

and `result.json` is only written when a `result` event is found in the transcript:

```
466:  if res is None:
467:      print("  !! no result event — treat this instance as failed", file=sys.stderr)
468:      sys.exit(0)
```

A container that is OOM-killed, loses its API connection, or is Ctrl-C'd mid-review writes no
`result.json`, so on the next invocation the cell falls through *both* tests and re-runs — with
no attempt counter consulted, at every resume, forever. The same failure also corrupts the
ledger: the attempt record loads `result.json`, fails, and writes `{"cost_usd": 0}`
(`:529-539`), so a cell that burned up to `BUDGET` at Anthropic is recorded as free and is
invisible to `SWEEP_BUDGET` as well. This commit does not introduce the bug, but it enlarges
its blast radius: the new preconditions (a proxy sidecar, an `--internal` network, a baked
image) add failure modes whose signature is exactly "container never reaches a result event",
and Finding 3 gives one of them a mechanism that hits all 50 cells at once.

**Recommendation:** Move the `MAX_ATTEMPTS` check out of the `result.json` branch and gate it
on `attempts.jsonl` alone, and always append an attempt record — including a
`{"cost_usd": null, "subtype": "no_result_event"}` row when the transcript has no result — so
that unmeasurable spend is visibly unmeasurable rather than silently zero.

---

#### `SWEEP_BUDGET` is only evaluated after a cell is paid for, and skipped cells jump the gate

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:544-570`, with the `continue`s at `:369`, `:380`, `:400`, `:418`
**Move:** Find the work that moved to the wrong place
**Classification:** Macro (the ceiling is checked strictly after the spend it exists to prevent) / Hot path (per-cell)
**Confidence:** High
**Baseline:** `SWEEP_BUDGET` default $250.00 (`run-host.sh:86`); `--all` estimated at
$500–2000 (`docs/working/crb-direction1-setup.md:307`), i.e. the ceiling is *expected* to be
hit on a full sweep.

The aggregate gate runs at the very bottom of the loop body, so its guarantee is "stop after
the first cell that crosses the line", and the header comment concedes the overshoot
(`:84-86`: "the worst overshoot is SWEEP_BUDGET+BUDGET"). What is less visible is the resume
case: every early `continue` — missing baseline (`:369`), already-complete cell (`:380`),
`MAX_ATTEMPTS` reached (`:400`), failed `--restore` (`:418`) — returns to the top of the loop
*without* touching the gate. A sweep resumed after a `SWEEP_BUDGET` halt therefore walks past
all its completed cells for free, reaches the first unfinished one, and pays a full
$10–40 review before the gate is consulted for the first time. On `--all`, where hitting the
ceiling is the designed outcome, that is one unintended cell per resume.

**Recommendation:** Hoist the gate to the *top* of the loop body, before the baseline check, so
that the ceiling is evaluated once per iteration regardless of which path the iteration takes.
The existing bottom-of-loop check can then be deleted; the per-attempt ledger it reads is
already written before it runs.

---

#### One non-restarting proxy sidecar gates every paid cell, and liveness is checked only once

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:156-166` (`setup_egress`, `--restart no`), `:197-231` (preflight, once per invocation), `:432-446` (per-cell review container)
**Move:** Find the contention point / trace the resource lifecycle
**Classification:** Macro (single shared dependency for the whole sweep, with no per-use health check) / Hot path (per-cell)
**Confidence:** Medium
**Baseline:** no baseline available — flagged as speculative (nothing docker-shaped has been
executed; the proxy has never run).

`crb-egress-proxy` is created once, with `--restart no`, and is the only route off the
`--internal` network. The three-leg egress preflight and the paid auth preflight prove it is
healthy at t=0 and are never repeated. If the sidecar exits at any point during a multi-hour
sweep — crash, OOM, an operator's `docker system prune`, a daemon restart — every subsequent
cell launches a review container that cannot reach `api.anthropic.com`, fails within seconds,
and (per Finding 1) most likely writes no `result.json` at all. The sweep does not notice: it
proceeds through all remaining instances, `ran` increments for each, and the run ends with a
long list of cells that are simultaneously "attempted", "unledgered", and "eligible for
unbounded retry". The wall-clock loss is the whole remaining sweep; the dollar loss is small
per cell but the *recovery* cost is a full re-run of everything after the failure point.

**Recommendation:** Add a $0 liveness probe immediately before each `docker run` of the review
container — reuse `in_cell_net` (`:183-189`) with a `--max-time 10` curl to
`api.anthropic.com` — and abort the sweep on failure rather than continuing. Consider
`--restart unless-stopped` on the sidecar; the `EXIT` trap already tears it down
(`:167-170`, `:359`).

---

#### The paid auth preflight is spent once per invocation and never appears in any ledger

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:235-247`
**Move:** Price the deployment environment
**Classification:** Micro (one small model call) / Cold path (once per invocation, not per cell)
**Confidence:** High
**Baseline:** no baseline available — flagged as speculative for the preflight's own token
cost; the surrounding sweep totals are $50–200 (pilot) and $500–2000 (`--all`)
(`docs/working/crb-direction1-setup.md:306-307`).

`preflight` is a real headless `claude` invocation on `$MODEL`, made before any cell runs. Its
output goes to `$OUT/preflight.json`, which is neither an `attempts.jsonl` row nor a cell
directory, so it is counted by neither `write_run_meta`'s `total_cost_usd` (`:290-352`) nor the
`SWEEP_BUDGET` gate (`:544-570`). It is small — a "list your skills" turn — but it is paid on
*every* invocation, and this harness is designed to be resumed: a sweep halted and restarted
ten times pays it ten times, all outside the number a results doc quotes as the arm's cost.
This matters more given the fact-check's Claim 4 finding (`R6` did not dissolve): in the
repository's current state, with no baselines materialized, an operator who runs the sweep
pays the preflight and then exits 3 with every instance `skipped_bad` — a non-zero spend on a
run that reports no cells.

**Recommendation:** Parse `total_cost_usd` out of `preflight.json` and write it as a
`preflight` pseudo-cell row so it flows into both `run-meta.json` and the `SWEEP_BUDGET` sum.
Alternatively, move the paid preflight behind a "no baseline exists for any requested
instance" pre-check so the R6 state fails before spending anything.

---

#### The audit forks one `git merge-base` per stray commit, unbounded, in exactly the case it fires

**Severity:** Low
**Location:** `scripts/crb-audit-clone.sh:73-81`
**Move:** Ask "what's the size of N?"
**Classification:** Macro (per-item subprocess over an unbounded collection) / Cold path (once per cell, post-review)
**Confidence:** High
**Baseline:** `git rev-list --all --not HEAD` measured at 0.00 s on all five pilot clones
(this host, 2026-08-19) — N is 0 in the clean case.

```
73: strays=$(git rev-list --all --not "$HEAD_SHA" 2>/dev/null)
75: for c in $strays; do
77:   if ! git merge-base --is-ancestor "$HEAD_SHA" "$c" >/dev/null 2>&1; then
```

In the clean case `main` is an ancestor of the head and `strays` is empty, which is why this
costs nothing today. But the loop exists for the case where it *isn't* clean, and the most
important such case — a cell that ran `git fetch <url> <refspec>` against the upstream repo,
the answer-key retrieval this whole design targets — brings in the fork's entire remaining
history, so N becomes thousands and the loop forks one `git` process per commit. The reporting
value saturates after the first foreign commit (`:79` prints only when `n_foreign` is 1), so
every additional fork buys only a counter. The consequence is not a wrong verdict, just a slow
one at the worst moment.

**Recommendation:** Cap the examined set (e.g. `head -200`, and report ">200 stray commits"),
or replace the loop with a single set operation — `git rev-list --all --not "$HEAD_SHA"` minus
`git rev-list --ancestry-path "$HEAD_SHA"..--all` — computed in two processes instead of N.

---

#### tinyproxy's 600 s idle timeout can cost a full re-paid cell

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:6` (`Timeout 600`), consumed by `run-host.sh:432-446`
**Move:** Trace the resource lifecycle / find the contention point
**Classification:** Micro (one connection setting) / Hot path (the tunnel every paid cell depends on)
**Confidence:** Low
**Baseline:** no baseline available — flagged as speculative; the proxy has never run and no
per-cell tunnel-idle distribution exists.

Every cell's API traffic now traverses a CONNECT tunnel with a 600 s inactivity cap that did
not exist before this commit. Streaming responses keep the tunnel active, so the common case is
fine; the exposure is a long local gap between API turns (a slow subagent hand-off, a large
local tool sequence) that idles a pooled connection past ten minutes. If the CLI does not
transparently re-establish, the cell errors *after* spending most of a $10–40 review, and lands
in the retry path — which re-pays the cell in full. `MaxClients 100` / `StartServers 2`
(`tinyproxy.conf:9-10`) are comfortable for a serial sweep even with a fan-out of parallel
critic subagents, but would need re-derivation if cells are ever run concurrently.

**Recommendation:** Raise `Timeout` well above the longest plausible cell (e.g. 3600) — the
value has no security function, since the allowlist and `ConnectPort 443` do the filtering —
and record the observed per-cell tunnel behaviour from the pilot before the full sweep.

---

#### The sweep-budget gate re-reads every cell's ledger after every cell

**Severity:** Informational
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:544-570`
**Move:** Count the hidden multiplications
**Classification:** Micro (repeated small file reads) / Hot path (per-cell)
**Confidence:** High
**Baseline:** 50 cells maximum (`docs/working/crb-direction1-setup.md:307`); each
`attempts.jsonl` is ≤ `MAX_ATTEMPTS` JSON lines.

The gate re-scans `os.listdir($OUT)` and re-parses every cell's `attempts.jsonl` on each
iteration, so a 50-cell sweep performs ~1,275 ledger reads instead of 50. At these sizes the
cost is microseconds and there is nothing to fix for performance reasons — it is recorded only
because this loop is the arm's money gate, and if the ledger ever grows to per-turn records the
quadratic re-scan is where it will first be felt.

**Recommendation:** No action. If ledgers ever become large, keep a running total in the shell
and re-derive from disk only on resume.

---

#### Baselines are stored as uncompressed tars

**Severity:** Informational
**Location:** `scripts/crb-materialize.py:300-306` (`tar --create`, no compression flag)
**Move:** Price the deployment environment
**Classification:** Micro (constant-factor storage) / Cold path (once per slug)
**Confidence:** High
**Baseline:** 280 GB free of 1,007 GB on the clone filesystem, measured on this host
2026-08-19; `--all` projected at ~13 GB with baselines
(`docs/decisions/034-...:63`, `fact-check claim 1 — Mostly Accurate`).

The doubling is real and correctly documented. Compression would not recover much — the
clones are 10–75 MB of already-compressed `.git` packfiles plus a working tree — and it would
add CPU to the per-cell restore, which is currently the cheapest part of the loop (0.6 s
extract, measured). Recording this only to close the disk axis the scope raised: at 1.3% of
free space for the full sweep, disk does not constrain this arm, and the uncompressed choice is
the right one for a per-cell hot path.

**Recommendation:** No action. Note that `docs/working/crb-direction1-setup.md:27` still says
`~6-7 GB` (`fact-check claim 5 — Stale`); fixing that line is the only disk-related work
outstanding.

---

## Endorsements

- The per-cell restore verifies the baseline sha256 before extracting, and the tar is read
  twice (hash, then extract) — measured at 0.1 s + 0.6 s on the 210 MB sentry baseline on this
  host, so the integrity check is effectively free relative to the extract it guards.
  `[unverified — submitted as claim]`
- The review container's entrypoint is the baked `claude` binary
  (`docker/Dockerfile.review:18-28`), and the run command at `run-host.sh:432-446` no longer
  contains the `npx -y @anthropic-ai/claude-code@"$CC_VERSION"` that the pre-`197eec6` version
  of that command carried — so per-cell package resolution is out of the paid path, not merely
  cached. `[read: runs/review-arms/crb-pipeline/docker/Dockerfile.review:16-28 + runs/review-arms/crb-pipeline/run-host.sh:432-446]`
- R3 (nested clone) and A8 (a voided cell leaving a permanently dead clone) are closed
  structurally: the clone is left as written and the next cell's `--restore` wipes it, so no
  cell is permanently lost to a void and no operator action is needed to recover one.
  `[fact-check: claim 2 — Verified]`
- The disposable-clone design is per-slug and shares no mutable host state between cells
  (each cell touches only `$CLONES/$id`, its own `$OUT/$id`, and a private `mktemp -d` payload),
  so nothing in this commit blocks running cells concurrently against the one shared proxy —
  the serial loop is now the only thing serializing the sweep.
  `[unverified — submitted as claim]`
- `git fsck --connectivity-only --no-reflogs` in the audit measured 0.01–0.02 s across all five
  pilot clones on this host, so moving detection into a throwaway container costs container
  startup rather than analysis time. `[unverified — submitted as claim]`

---

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | No-result cells retry unboundedly and ledger `cost_usd: 0` | High | `run-host.sh:376-401,460-470,529-539` | High |
| 2 | `SWEEP_BUDGET` checked after the spend; skips jump the gate | Medium | `run-host.sh:544-570` vs `:369,380,400,418` | High |
| 3 | Non-restarting proxy sidecar, liveness checked once per sweep | Medium | `run-host.sh:156-166,197-231,432-446` | Medium |
| 4 | Paid auth preflight is unledgered and paid per invocation | Low | `run-host.sh:235-247` | High |
| 5 | Audit forks one `merge-base` per stray commit, unbounded | Low | `crb-audit-clone.sh:73-81` | High |
| 6 | tinyproxy `Timeout 600` can cost a re-paid cell | Low | `docker/tinyproxy.conf:6` | Low |
| 7 | Budget gate re-reads all ledgers per cell (O(N²)) | Informational | `run-host.sh:544-570` | High |
| 8 | Baselines stored uncompressed (disk doubling, not a constraint) | Informational | `crb-materialize.py:300-306` | High |

---

## Overall Assessment

On the question the scope actually asks — is the new per-cell overhead seconds or minutes × 50
— the measured answer is seconds: ≈ 2–3 s per cell (sha256 0.1 s, `rm -rf` 0.2 s, extract
0.6 s, harvest walk 0.1 s, audit git commands 0.05 s, plus one container launch), against a
per-cell review of 4.5–10.8 minutes and $10–40. That is under ~1% of a cell and about two
minutes across a 50-cell sweep. Disk is likewise a non-issue: ~13 GB for `--all` against 280 GB
free. The disposable-clone and egress-allowlist controls are, on the compute and storage axes,
essentially free, and the harness pays for them with a design that is also more parallelizable
than what it replaced.

The cost exposure is entirely in the money machinery around the container, and the two ambers
carried into this review are still open and are now more likely to fire, not less. Finding 1 is
the one to fix before any paid sweep: the new preconditions (a sidecar that must stay up, an
`--internal` network, a baked image) all fail in the shape "container never emits a result
event", which is precisely the shape that bypasses `MAX_ATTEMPTS` and ledgers $0. Finding 3
supplies a plausible mechanism that puts all 50 cells into that state at once, and Finding 2
means the ceiling that is supposed to bound the damage is consulted only after the next cell is
paid for. Fix 1 and 2 together — they are a few lines each and are independent of anything
docker-shaped, so both are verifiable on this host at $0 — and add the liveness probe from 3
before the pilot. No profiling is needed for any finding here; the numbers that matter are
already measured, and what remains unmeasurable is the docker layer, which the commit
deliberately defers to its own $0 preflight.

## Goal-Alignment Note
- Answered: yes — per-cell overhead quantified as seconds, cost risks located in the retry/budget path
- Out of scope: security properties of the allowlist and the audit's detection coverage (security-reviewer's); correctness of the fact-check's Incorrect verdicts (accepted as given); anything requiring docker execution
- Escalate: A6 (Finding 1) and A7 (Finding 2) are still open after three review rounds and are both few-line, $0-verifiable fixes — the orchestrator should treat them as blocking the pilot rather than as carried ambers. A8 is confirmed closed structurally by the fact-check, and I found no performance-side regression from that closure.
