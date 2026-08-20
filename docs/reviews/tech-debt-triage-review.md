# Tech Debt Triage: CRB direction-1 harness, egress allowlist + disposable clones (`197eec6`)

**Scope reviewed:** commit `197eec6` only (16 files, +1676/-757). Sibling commits on
`feat/crb-direction1-harness` read as context, not reviewed.
**Verification performed:** the four new bats suites were run (37/37 green: `crb-audit-clone`,
`crb-disposable-clone`, `crb-egress-config`, `crb-harvest-artifacts`); the on-disk state of
`external/crb-eval/` and `runs/review-arms/crb/instances.json` was read directly; the A20
arm-lifetime statistic was recomputed from `git log` at both `e159618` and `HEAD`.
**Standing:** advisory (🟢 Consider tier). Nothing here blocks merge. D1 and D2 are marked
**pre-sweep** because they fire before or during the first paid cell; everything else is
explicitly post-pilot or never.
**Not treated as a defect:** nothing docker-shaped has been executed. That is declared in the
commit message and in decision 034, and it is the premise of D2 rather than a finding.

---

## Summary ranking

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| D1 | No baseline exists for any of the 5 pilot clones; the only path to one is a manual `--snapshot`, which is also the last surviving host-git-on-a-work-clone | High | +0 — inert, but a hard stop at cell 0 | Low × High — a `--snapshot` on a clone a container *has* touched launders contamination into the definition of "clean" | ~20 min | **Imminent — fires before cell 1** | Fix now |
| D2 | No mode stops after the egress preflight; `DRY_RUN=1` exits before docker exists | Medium | +0 — inert | Low × Med — the "verified at $0" claim has no operator-reachable form | ~5 lines | **Imminent — fires on first run** | Fix now |
| D3 | Three void cases dropped in the test migration, incl. the `scrub_object_store` non-vacuity pin | Medium | +0 — inert | Low × Med — the FETCH_HEAD/unreachable checks can go silently inert again | ~30 min | On next change to `scrub_object_store` | Fix opportunistically |
| D4 | Baseline-path contract restated across the bash/python boundary (A12's failure mode, new instance); subnet restated twice | Medium | +1 hand-copied constant per contract change | | ~30 min | On next layout change | Fix opportunistically |
| D5 | Doc rot: `~6-7 GB` vs `~13 GB`, "the tree reset below" with no reset below, a usage example that would not run | Low | +0 — inert | | Minutes | Before `--all` | Fix opportunistically |
| D6 | Egress machinery is arm-local under `crb-pipeline/docker/` though the control is general | Low | +1 copy per new container-running arm (~1 arm per 2-4 days at current cadence) | | Days | Second arm that needs it | Defer and monitor |
| D7 | `setup_egress` unconditionally destroys any existing proxy/network — a second concurrent sweep kills the first's egress | Low | +0 — inert | Low × Med — a running $10-40 cell loses API access mid-flight | ~10 min | Only if sweeps ever run concurrently | Carry intentionally |
| D8 | `PROXY_IMAGE` tagged from `git rev-parse --short HEAD` claims commit provenance a dirty tree does not have; no image pruning | Low | +1 stale image per commit that touches the arm | | ~10 min | None | Carry intentionally |
| D9 | Prior-review carried items A12/A13/A16/C2/C4/C6 still open; A16's own correction is now stale | Low | +0 — inert | | Hours (all six) | None | Carry intentionally |
| D10 | Disk doubles (pilot ~670 MB → ~1.3 GB; `--all` ~6.5 → ~13 GB); baseline tars are uncompressed | Low | +1 clone-sized tar per materialized slug | | Hours | Only at `--all` on a constrained disk | Carry intentionally |

### Recommended order

**D1, then D2, then stop before the sweep.** Both are minutes of work, both land at $0, and both
sit directly on the path the pilot has to walk. D3 and D5 can ride along with whatever commit
closes D1 (they are a test file and three comment lines). D4 is the only item worth a deliberate
half-hour and it should wait until after the pilot, because it edits the exact code the sweep is
about to exercise — the A20 tradeoff applies to it and to nothing else in this list. D6–D10 are
explicitly **not** worth doing before the sweep.

---

## Does A20's carry argument still hold after this diff?

**Answer: the statistic it rests on flipped, and this commit is what flipped it — but the carry
still holds, for a different reason than the one recorded.**

A20's evidence was that arms in `runs/review-arms/` are single-use as code (identical first and
last commit dates), so refactor risk lands inside the sweep window while the benefit lands in a
maintenance phase history says will not occur. The 2026-08-19 rubric's A16 corrected the count
from 13-of-15 to 10-of-15. Recomputed at this commit:

```
$ for rev in e159618 HEAD; do ... done
== at e159618
identical: 10 of 15
== at HEAD
identical: 9 of 15

$ (per-directory diff, e159618 vs HEAD)
runs/review-arms/crb-pipeline: was 2026-08-18->2026-08-18 now 2026-08-18->2026-08-19
```

`crb-pipeline/` is the directory that moved, and `197eec6` is the commit that moved it. The arm is
now at 8 commits spanning two days, in the same class as `e7-fable-3x` (11 commits, 4 days) and
`crb` (8 commits, 4 days) — the two long-lived arms C1 already identified as the two with the most
machinery. So the arm this diff modifies has, by this diff, left the population A20 generalised
from. C1's proposed retightening ("revisit before the second full `--all` sweep") is the right
trigger and should be adopted; A16's "10 of 15" needs a second correction to **9 of 15**, and the
sentence is more useful stated as *"the arms that survive are the arms with machinery"* than as a
bare ratio that this branch will keep moving.

What A20 still buys, though, is unchanged and I would not overturn it: the carry was always about
**not refactoring the arm's logic during the sweep window**, and that is exactly why D4 (the real
architectural item in this diff) is filed as "after the pilot" rather than "now". The distinction
that matters is that D1/D2/D3/D5 are not refactors at all — they are a missing migration step, a
missing early-exit, a missing test, and three wrong comments. A20 never argued for carrying those.

---

## D1 — No pilot clone has a baseline, and the only way to make one is the last host-git path

**Severity:** High (blocking, and the sole residual instance of the pattern this commit exists to
remove)
**Location:** `external/crb-eval/` (no `.baselines/`), `runs/review-arms/crb/instances.json`,
`runs/review-arms/crb-pipeline/run-host.sh:366-418`, `scripts/crb-materialize.py:225-247`,
`scripts/crb-materialize.py:513-534`
**Confidence:** High — on-disk state and manifest read directly; the `--snapshot` code path read
in full.
**Legibility-target:** for-author

**Evidence (verbatim, shell):**

```
$ ls external/crb-eval/.baselines/
ls: cannot access 'external/crb-eval/.baselines/': No such file or directory

$ python3 -c "import json; m=json.load(open('runs/review-arms/crb/instances.json')); ..."
5
cal_com-PR11059 False
discourse-graphite-PR4 False
grafana-PR79265 False
keycloak-PR36880 False
sentry-greptile-PR5 False        # ('baseline_sha256' in record)
```

**Evidence (verbatim, `run-host.sh:366-371`):**

```
  [ -f "$CLONES/.baselines/$id.tar" ] || {
    echo "$id: no baseline — run scripts/crb-materialize.py --slug $id (or --snapshot $id" >&2
    echo "    if the clone already exists and no container has run against it)" >&2
    skipped_bad=$((skipped_bad+1)); continue; }
```

**Evidence (verbatim, `crb-materialize.py:236-247`, `scrub_object_store` docstring):**

```
    Runs on a clone this script just built from the fork, before any container
    has seen it, which is the only reason it is safe to run host `git` here.
```

**Evidence (verbatim, `crb-materialize.py:525-529`, the `--snapshot` CLI path):**

```
                    # Clears materialize()'s own FETCH_HEAD and any dangling
                    # origin/HEAD, so the baseline starts from the same state a
                    # freshly materialized clone would.
                    scrub_object_store(dst)
                    n_commits, stat = verify_containment(dst, slug, head)
```

**Nature:** migration debt, plus one residual instance of the structural debt the commit removed
everywhere else.

Two things are true at once. First, operationally: the sweep as committed skips all five pilot
instances and does nothing, because the precondition moved from "a clone exists" to "a baseline
exists" and no baseline was ever built. The runbook (`docs/working/crb-direction1-setup.md`)
documents `--snapshot` as a mode but does not name it as a required one-time migration step, and
`run-host.sh`'s message routes the operator to it only after the skip has already happened. The
fact-check independently reached this ("the five existing clones have no baseline, so the sweep
skips every instance"); this triage confirms it against disk.

Second, structurally: `--snapshot` is the one place where host `git` still runs against a
work clone. `scrub_object_store()` executes `reflog expire`, `gc --prune=now` and
`symbolic-ref -d` in `$CLONE`, and `verify_containment()` follows with `rev-list` and `remote` —
precisely the command family the 2026-08-19 review executed five host-side code-execution paths
out of. Its safety rests entirely on the operator honouring a docstring (`ONLY EVER CALL THIS ON A
CLONE NO CONTAINER HAS TOUCHED`) and a `--force` prompt. **Today that is fine**: `ls
runs/review-arms/crb-pipeline/` contains only `docker/` and `run-host.sh` — no cell has ever run,
so the five clones are pristine and the snapshot is safe. The debt is that the invariant is
enforced by prose at exactly the moment an operator is under time pressure to start a sweep.

**Cost of Deferral:** `+0 — inert`. The blockage does not worsen and the clones do not get dirtier
on their own. It is a step-function, not a slope: everything is fine until the operator runs the
sweep, at which point nothing happens at all.

**Failure Cost:** `Low × High` — probability is low (the clones are demonstrably untouched and the
window closes once baselines exist), but if a `--snapshot` is ever run on a used clone the result
is not a visible error: the contaminated tree *becomes* the definition of clean for every
subsequent cell, and the audit that is supposed to catch contamination is now diffing against it.
That is the same "plausibly high score, no obvious error" failure the void machinery exists for.

### Fix Cost
- **Scope:** localized — one runbook section, optionally ~10 lines in `crb-materialize.py`.
- **Effort:** ~20 minutes, of which most is running the five snapshots.
- **Risk:** low — additive; the round-trip is already pinned by
  `test/crb-disposable-clone.bats:82` ("snapshot then restore is a byte-identical round trip").
- **Incremental?** yes.

### Urgency Triggers
- Fires at cell 0 of the pilot. There is no version of the sweep that runs without this.
- The safety window for `--snapshot` closes permanently the first time any cell runs.

### Recommendation

**Recommendation:** Fix now

Do the five snapshots while the clones are provably pristine, and promote the step from a mode in
a usage list to a numbered migration step in the runbook, with the "no container has run against
it" precondition stated where the operator will be standing. If ten minutes are available beyond
that, have `--snapshot` refuse when the clone shows any of the audit's own signals (a remote, a
`FETCH_HEAD`, an unreachable commit) — not because that is a complete detector, which decision 034
correctly argues it cannot be, but because it converts the one prose-enforced invariant left in the
design into a check that fails closed. This is a trivial fix by the skill's own routing (one file,
under 50 LOC); no RPI handoff.

---

## D2 — The preflight that makes the design honest cannot be run without starting a sweep

**Severity:** Medium
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:133-136`, `:144-230`
**Confidence:** High — control flow read in full; `DRY_RUN` appears at `:66`, `:91`, `:133` and
nowhere after.
**Legibility-target:** for-author

**Evidence (verbatim, `run-host.sh:133-136`):**

```
if [ -n "$DRY_RUN" ]; then
  echo "DRY_RUN=1 — payload built and verified, no container started, \$0 spent."
  exit 0
fi
```

**Evidence (verbatim, `run-host.sh:144-148`) — everything docker-shaped is downstream of that
exit:**

```
echo "=== images"
docker build --quiet --build-arg CC_VERSION="$CC_VERSION" \
  -f "$DOCKER_DIR/Dockerfile.review" -t "$REVIEW_IMAGE" "$DOCKER_DIR" >/dev/null
```

**Evidence (verbatim, decision 034, "Consequences"):**

```
- **Not verified here**: everything docker-shaped. ... The allowlist is
  verified on the host by its own preflight, at $0, before the first cell — a
  control whose only honest verification is execution.
```

**Nature:** verification-affordance debt.

The design's answer to "none of this has ever run" is that the preflight executes it at $0 before
any paid cell. That answer is correct about ordering — the three egress legs and the CLI preflight
all precede the first cell, and each exits non-zero on failure. What is missing is a way to
*stop there*. `DRY_RUN=1` returns before the images are built, so it exercises none of the new
machinery; the only way to reach the egress preflight is to run the real script, which then
proceeds into the auth preflight (a real, billed CLI call) and then into the sweep. The operator's
only brake is Ctrl-C, and the two assumptions the commit message flags as unsettled — that Claude
Code honours `HTTPS_PROXY`, and that docker's embedded DNS resolves on an `--internal` network —
are exactly the ones that want a repeatable, interruption-free rehearsal loop while they are being
debugged.

**Cost of Deferral:** `+0 — inert`. The gap does not widen; it is simply present on every run.

**Failure Cost:** `Low × Med` — no data or money is directly at risk (the preflight does exit 5
before cells), but debugging docker networking by repeatedly launching the sweep script is how an
operator ends up disabling a leg to "get past it", which is the failure mode the three-leg design
was written against.

### Fix Cost
- **Scope:** localized — one `if` in `run-host.sh`.
- **Effort:** ~5 lines.
- **Risk:** low — an early `exit 0` after the third leg; the `EXIT` trap already tears the network
  down.
- **Incremental?** yes.

### Urgency Triggers
- Fires the first time anyone runs the egress stack, which is by construction the next thing that
  happens on this branch.

### Recommendation

**Recommendation:** Fix now

Add `PREFLIGHT_ONLY=1` (or extend `DRY_RUN` to a second level) that builds the images, sets up
egress, runs the three legs, prints the verdict and exits before `[ -n "$ANTHROPIC_API_KEY" ]`
matters. Five lines, no behaviour change on the normal path, and it is what turns "verified at $0
before the first cell" from an ordering property into something the operator can actually invoke.

---

## D3 — Three void cases were dropped in the test migration, including the one that keeps the audit non-vacuous

**Severity:** Medium
**Location:** `test/crb-audit-clone.bats` (10 tests), deleted `test/crb-containment-reset.bats`,
`scripts/crb-materialize.py:225`
**Confidence:** High — the fact-check identified the three; `grep -rn scrub_object_store test/`
confirms zero hits.
**Legibility-target:** for-author

**Evidence (verbatim, shell):**

```
$ grep -rn "scrub_object_store" test/ scripts/
scripts/crb-materialize.py:225:def scrub_object_store(dst: Path):
scripts/crb-materialize.py:416:    scrub_object_store(dst)
scripts/crb-materialize.py:527:                    scrub_object_store(dst)
```

**Evidence (verbatim, `scripts/crb-materialize.py:229-235`):**

```
    Load-bearing for the AUDIT, not for the reset (there is no reset any more).
    scripts/crb-audit-clone.sh voids a cell on a leftover `.git/FETCH_HEAD` and
    on unreachable commits under `git fsck --no-reflogs`. materialize()'s own
    fetches write both, so unless they are cleared here EVERY baseline would
    carry them and EVERY cell would void — and the checks would mean nothing.
```

**Evidence (verbatim, `docs/reviews/code-fact-check-report.md`, Claim 24):**

```
Three did not carry over: the **`scrub_object_store` non-vacuity case** (`grep -rn
scrub_object_store test/` returns zero hits, while Claim 21 establishes the function is still
load-bearing), the tag-outside-ancestry variant of the descent case (mechanism covered by the
branch variant), and the shallow-clone false-positive control.
```

**Nature:** testing debt — a coverage regression taken during a rewrite, on the one function whose
removal would make two of the audit's five checks silently inert.

The migration is otherwise good: `test/crb-audit-clone.bats:146` still pins `--no-reflogs`
non-vacuity, and the remaining eight cases cover every void path. The gap is specifically that
`scrub_object_store` now has no test anywhere, while its own docstring says every baseline and
therefore every cell depends on it. Of the other two, the tag variant is genuinely redundant with
the branch variant and I would not re-add it; the shallow-clone false-positive control is worth
one test, because every clone in this arm is `--depth 50` and a false positive there voids real
cells.

**Cost of Deferral:** `+0 — inert`. Coverage does not decay on its own; the risk materialises only
when someone edits `scrub_object_store`, which nobody is scheduled to do.

**Failure Cost:** `Low × Med` — if the function is ever weakened, `FETCH_HEAD` and
unreachable-commit detection go quiet rather than loud, and a quiet audit is exactly what the
runbook warns must never be read as cleanliness.

### Fix Cost
- **Scope:** localized — one bats file.
- **Effort:** ~30 minutes for two tests (stub `scrub_object_store`, assert the audit voids; a
  shallow clone that must audit clean).
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- Any change to `scrub_object_store` or to `materialize()`'s fetch sequence.
- None imminent.

### Recommendation

**Recommendation:** Fix opportunistically

The non-vacuity test is cheap and it is the difference between an evidence layer and a decorative
one. But it guards a maintenance risk, not a sweep risk — the function is correct today and
nothing on the pilot path touches it. Add it with whatever commit closes D1; do not hold the sweep
for it.

---

## D4 — The baseline layout is a new inter-module contract stated in three places

**Severity:** Medium
**Location:** `scripts/crb-materialize.py:73`, `runs/review-arms/crb-pipeline/run-host.sh:70`,
`:366`, `:479`; and separately `run-host.sh:99` vs
`runs/review-arms/crb-pipeline/docker/tinyproxy.conf:16`
**Confidence:** High — all four sites read directly.
**Legibility-target:** for-author

**Evidence (verbatim, `scripts/crb-materialize.py:73`):**

```
BASELINE_ROOT = DST_ROOT / ".baselines"
```

**Evidence (verbatim, `run-host.sh:70`, `:366`, `:479`):**

```
CLONES="$ROOT/external/crb-eval"
...
  [ -f "$CLONES/.baselines/$id.tar" ] || {
...
    "$clone" "$CLONES/.baselines/$id.index.json" "$dest/artifacts" || {
```

**Evidence (verbatim, `run-host.sh:99` and `docker/tinyproxy.conf:14-16`):**

```
EGRESS_SUBNET="${EGRESS_SUBNET:-172.31.250.0/24}"
```
```
# The proxy is reachable only from the internal `crb-inner` network, whose
# subnet run-host.sh pins so this line can be exact. ...
Allow 172.31.250.0/24
```

**Nature:** structural/coupling debt — the same failure A12 named, in new code.

A12 flagged that `crb_common.py`'s boundary is "holding in kind, broken in effect" because the
run-dir path is stated three times, the bash writer being unable to import it. This commit adds a
second contract with the same shape: the `.baselines/<slug>.tar` and `.baselines/<slug>.index.json`
layout is authoritative in `crb-materialize.py:73`, and hand-copied into two `run-host.sh` string
concatenations. `crb-harvest-artifacts.py` is the counter-example done right — it takes the index
path as an argument and asserts on it (`no baseline index at {index_path}`), so it has no opinion
about the layout at all.

The subnet is a milder instance with a sharper failure: `EGRESS_SUBNET` is overridable by env, but
`tinyproxy.conf`'s `Allow` line is baked into the image. Overriding the env var produces a proxy
that refuses every client, which the positive preflight leg catches — so it **fails closed**, and
that is the right direction. But the failure message will be "api.anthropic.com unreachable
through the proxy", which does not name the cause.

**Cost of Deferral:** `+1 hand-copied constant per contract change` — one more site to keep in
agreement each time the baseline layout or the network moves. At the arm's current cadence
(8 commits in 2 days) that is not hypothetical, but it is also bounded: the arm has a short life.

### Fix Cost
- **Scope:** cross-cutting but small — either a tiny `--baseline-path <slug>` query mode on
  `crb-materialize.py` that `run-host.sh` calls, or the same four-value treatment `crb_common.py`
  already got. The subnet half is one `grep`-style assertion in `test/crb-egress-config.bats`
  comparing the two files.
- **Effort:** ~30 minutes.
- **Risk:** medium — it edits the exact per-cell path the sweep is about to exercise, and the
  failure mode of getting it wrong is a sweep that skips every instance (D1's symptom).
- **Incremental?** yes — the subnet assertion is independent and near-free.

### Urgency Triggers
- Any change to `BASELINE_ROOT`, to `DST_ROOT`, or to the index filename.
- A second consumer of the baselines (an audit runner, a re-verification pass).
- None imminent.

### Recommendation

**Recommendation:** Fix opportunistically — after the pilot

This is the one item in this list where A20's carry argument applies on its own terms: the benefit
is maintenance-phase, the risk lands inside the sweep window, and the code is correct as written.
Do the subnet cross-check now if it is being touched anyway (a two-line bats assertion that the
`Allow` line matches the `EGRESS_SUBNET` default costs nothing and names a confusing failure), and
leave the path contract until the pilot has run.

---

## D5 — Three comments and a runbook line describe the pre-`197eec6` design

**Severity:** Low
**Location:** `docs/working/crb-direction1-setup.md:27`,
`runs/review-arms/crb-pipeline/run-host.sh:425`, `scripts/crb-audit-clone.sh:10-13`
**Confidence:** High — all three confirmed against the current code; the first two were
independently flagged Stale by the k=3 fact-check.
**Legibility-target:** for-author

**Evidence (verbatim, `docs/working/crb-direction1-setup.md:27`):**

```
scripts/crb-materialize.py --all           # all 50 (~6-7 GB)
```

against `scripts/crb-materialize.py:38`:

```
  scripts/crb-materialize.py --all                      # all 50 (~13 GB w/ baselines)
```

**Evidence (verbatim, `run-host.sh:423-425`):**

```
  # The clone is mounted read-write on purpose: the code-review skill writes its
  # rubric to docs/reviews/ in the repo under review. Artifacts are harvested
  # and the tree reset below, so re-runs start from the same state.
```

There is no tree reset below any more — the restore happens *above* (`:413`), and the block below
explicitly says "The clone is left as the container wrote it".

**Evidence (verbatim, `scripts/crb-audit-clone.sh:10-12`):**

```
#   docker run --rm --network none -v "$clone":/repo -v .../crb-audit-clone.sh:/audit.sh:ro \
#     <image> bash /audit.sh /repo <head-sha>
```

against the real invocation at `run-host.sh:493-496`, which adds `-u node` and
`--entrypoint bash` — without which `bash` is passed as an argument to the image's
`ENTRYPOINT ["claude"]` and the example does not run.

**Nature:** documentation debt.

**Cost of Deferral:** `+0 — inert`. These are wrong now and will stay equally wrong.

The disk line is the one that matters: it is in the runbook, in the section an operator reads
while deciding whether to run `--all`, and it understates the requirement by roughly half at the
moment the branch's own decision record says the footprint doubled.

### Fix Cost
- **Scope:** localized — three edits, none behavioural.
- **Effort:** minutes.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- Before anyone runs `--all` on a machine where 13 GB is a question.

### Recommendation

**Recommendation:** Fix opportunistically

Ride along with D1's commit. The `~6-7 GB` line should be corrected before the pilot expands, the
other two whenever the files are next opened.

---

## D6 — The egress allowlist is arm-local, but the control is not arm-specific

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/docker/` (4 files),
`runs/review-arms/crb-pipeline/run-host.sh:152-230`; compare
`runs/review-arms/e5-cc-builtin/run-host.sh`, `runs/review-arms/e6-ultra/run-host.sh`,
`runs/review-arms/e7-fable-3x/run-host.sh`, `scripts/prep-cc-review-clones.sh`
**Confidence:** Medium — the sibling runners were enumerated and their clone-prep read; I did not
read each sibling's container invocation line by line.
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim, `docker/egress-allowlist:4-8`):**

```
# EXACTLY ONE ENTRY IS INTENDED. Every addition widens the channel through which
# a reviewing agent could reach the answer key -- the merged upstream PR -- and
# through which repository-controlled content could exfiltrate ANTHROPIC_API_KEY.
```

**Evidence (verbatim, `scripts/prep-cc-review-clones.sh:8-12`) — the sibling clone-prep relies on
object-store pruning alone, with no egress control anywhere:**

```
#   - NO other refs, NO origin remote, and descendant objects (the later fix
#     commits — the answer key) pruned from the object store, so an agentic
#     reviewer cannot read the future via `git log --all` / `git show`.
```

**Nature:** placement debt — a general-purpose security control living inside a single experiment
directory.

The E5/E6/E7 arms review `meta-formalism-copilot` clones, whose "answer key" is pruned out of the
object store rather than merely unreferenced, and whose upstream is not a public GitHub PR. So
their exposure genuinely is lower, and the allowlist is not urgently missing there. But the *key
exfiltration* half of the threat applies identically to any arm that mounts a repo read-write into
a `--dangerously-skip-permissions` container with `ANTHROPIC_API_KEY` set, and that is most of
them. The four docker files are ~90 lines and have no `crb`-specific content beyond their comments;
the arm-specific part is entirely in `run-host.sh`.

**Cost of Deferral:** `+1 copy per new container-running arm`. At the observed cadence
(15 arm directories created over 13 days) that is roughly one arm every two to four days, though
most are cheap variants that would inherit rather than re-derive.

### Fix Cost
- **Scope:** cross-cutting — move `docker/` to `scripts/egress/` or similar, parameterise the
  allowlist, update `run-host.sh` and `test/crb-egress-config.bats`'s path assertions.
- **Effort:** ~half a day including re-verification, and the re-verification requires docker, which
  is not available in this session.
- **Risk:** medium — it moves files the sweep depends on, and the tests that would catch a mistake
  are static-config tests, not execution tests.
- **Incremental?** no — a half-moved allowlist is worse than either end state.

### Urgency Triggers
- **A second arm that runs an agent container against a third-party repo.** That is the trigger to
  extract; before it, extraction is speculative generality.
- Any decision to publish the CRB numbers alongside E5/E7 numbers, where the reviewer will ask why
  one arm was contained and the others were not.

### Recommendation

**Recommendation:** Defer and monitor

Leave it in the arm. It has run zero times; extracting an unexecuted control into a shared location
generalises from one unverified data point, and the extraction cost lands squarely in the sweep
window. Revisit at the trigger above — and note in the arm's README, if one is written, that
`docker/` is a candidate for extraction rather than arm-specific by design, so the next arm's
author finds it instead of rebuilding it.

---

## D7 — A second concurrent sweep silently destroys the first one's egress

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:156-166`
**Confidence:** High — read directly; the names are fixed constants at `:96-98`.
**Legibility-target:** for-author

**Evidence (verbatim, `run-host.sh:156-160`):**

```
setup_egress() {
  docker rm -f "$PROXY_NAME" >/dev/null 2>&1 || true
  docker network rm "$EGRESS_NET" >/dev/null 2>&1 || true
  docker network create --internal --subnet "$EGRESS_SUBNET" "$EGRESS_NET" >/dev/null
```

with `EGRESS_NET="crb-inner"` and `PROXY_NAME="crb-egress-proxy"` — both unconditional constants,
not per-run names.

**Nature:** concurrency debt.

`docker rm -f` on a fixed container name is the right idempotence for a single-operator loop and
the wrong one for two. A second `run-host.sh` started while the first is mid-cell tears down the
proxy the first cell is authenticating through; that cell then fails on API unreachability
partway into a $10-40 review, and `teardown_egress` in the second run's `EXIT` trap removes the
network again on the way out. The repo's own `guides/parallel-sessions.md` describes running
concurrent sessions, so the shape is plausible even if this specific script has only ever been run
by hand.

**Cost of Deferral:** `+0 — inert`. Nothing accumulates; the hazard exists only during overlap.

**Failure Cost:** `Low × Med` — one wasted paid cell and a confusing failure, no data loss, and the
resume predicate correctly declines to bank a cell with no review.

### Fix Cost
- **Scope:** localized — suffix both names with `$$` or the sweep timestamp, or take a lock file.
- **Effort:** ~10 minutes.
- **Risk:** low, but non-zero: the names appear in `test/crb-egress-config.bats` assertions and in
  the `docker logs crb-proxy` audit-trail claim in `Dockerfile.proxy`.
- **Incremental?** yes.

### Urgency Triggers
- Any decision to run two arms, or two subsets of this arm, at once.
- None imminent — the pilot is five sequential cells.

### Recommendation

**Recommendation:** Carry intentionally

Single-operator, sequential-by-design, and the fix touches names that three other files assert on.
Document it in the runbook as "do not run two sweeps on one host" and move on. Revisit only if the
sweep is ever parallelised, which would be a larger change anyway.

---

## D8 — The proxy image tag claims provenance a dirty tree does not have

**Severity:** Low
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:94`,
`runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:3-5`
**Confidence:** High
**Legibility-target:** for-author

**Evidence (verbatim, `run-host.sh:94`):**

```
PROXY_IMAGE="crb-egress-proxy:$(git -C "$ROOT" rev-parse --short HEAD)"
```

**Evidence (verbatim, `docker/Dockerfile.proxy:3-5`):**

```
# Own image rather than a third-party proxy image: the allowlist IS the control,
# so its configuration must be reviewable in this repo and pinned to this
# repo's commit rather than to whatever a public tag points at today.
```

**Nature:** provenance debt.

`rev-parse --short HEAD` names the commit, not the working tree. An uncommitted edit to
`egress-allowlist` — the single file whose contents are the control — builds into an image tagged
with the last clean commit, and a later `docker inspect` reports a provenance that does not match
what is running. The Dockerfile's build-time `grep` assertions still fire (they check
`FilterDefaultDeny`, the `Filter` path, and non-emptiness), so an *added host* would not be caught
by them, only by `test/crb-egress-config.bats:25`, which pins the count in the committed file
rather than the built one. Separately, nothing prunes old `crb-egress-proxy:<sha>` images, so each
commit that touches the arm leaves one behind.

**Cost of Deferral:** `+1 stale image per commit touching the arm` — 8 so far had they been built.

### Fix Cost
- **Scope:** localized — append `-dirty` when `git status --porcelain` is non-empty; optionally
  `docker image prune` by label in `teardown_egress`.
- **Effort:** ~10 minutes.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- Publishing a numbers write-up that cites the proxy image tag as evidence of what ran.
- None imminent.

### Recommendation

**Recommendation:** Carry intentionally

The gap is real but the mitigation already exists at the layer that matters: the allowlist is
tested in the repo, and the three-leg preflight tests the *running* proxy by execution on every
sweep. A wrong tag on an image whose behaviour is proven at run time is a labelling problem, not a
control problem. Add the `-dirty` suffix if the file is open for another reason.

---

## D9 — Six prior-review items still open, one of which is now doubly stale

**Severity:** Low
**Location:** `docs/reviews/code-review-rubric-2026-08-19-feat-crb-direction1-harness.md:122-139`
**Confidence:** High for the recount; Medium on the others, which were not re-verified in this pass
beyond confirming `197eec6` does not touch them.
**Legibility-target:** for-author

**Evidence (verbatim, rubric rows A13 and A16):**

```
| A13 | `missing_cells` is written and read by nobody — the leaderboard re-derives the same set,
and the test fixture writes a contradictory `[]` and still passes. | ...
| A16 | A20's supporting statistic is **10 of 15**, not 13 of 15 — could not be reproduced at 13.
Two-word edit to the 2026-08-18 rubric. | ...
```

**Evidence (verbatim, shell — the recount at this commit):**

```
== at e159618
identical: 10 of 15
== at HEAD
identical: 9 of 15
```

**Nature:** carried review debt.

None of A12, A13, A16, C2, C4 or C6 is touched by `197eec6`, and none of them is made worse by it
except A12 — whose failure mode this commit reproduces in new code, filed separately as D4. The
notable movement is A16: its own correction to "10 of 15" is stale at this commit, because this
commit is what moved `crb-pipeline/` out of the identical-dates set. That is not a reason to
re-edit the number a third time; it is a reason to replace the ratio with the claim it was
standing in for (see the A20 section above), since the denominator keeps moving under it.

C4 (`write_run_meta` is a function but not a mode, so provenance is not re-derivable after a lost
run, ~3 lines) is the only one of the six with a concrete pre-sweep argument: run-meta is written
by an `EXIT` trap, and a sweep that dies in a way the trap does not survive loses the provenance
for cells that were paid for. It is three lines and it is worth doing if D1's commit is already
open. The rest are ergonomic.

**Cost of Deferral:** `+0 — inert` for all six. They have survived three review passes without
spreading.

### Fix Cost
- **Scope:** localized, six independent small edits.
- **Effort:** hours for all six; minutes each for A16 and C4.
- **Risk:** low.
- **Incremental?** yes.

### Urgency Triggers
- None. A12's family grows by one site per contract change (tracked as D4).

### Recommendation

**Recommendation:** Carry intentionally

Six items that three review passes have declined to close, none of which affects the sweep. Take
C4 opportunistically if D1's commit is open. Do not spend a pre-sweep session on this set.

---

## D10 — Disk doubles, and the baseline tars are uncompressed

**Severity:** Low
**Location:** `scripts/crb-materialize.py:301-306`, `:437-444`;
`docs/decisions/034-...:Consequences`
**Confidence:** High on the mechanism; Medium on the magnitudes, which are the decision record's
figures — no baseline exists on disk to measure (see D1).
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim, `scripts/crb-materialize.py:301-303`):**

```
    # `-C dst .` so the archive holds clone-relative paths: extraction then does
    # not depend on where the clone lived when it was made.
    sh(["tar", "--create", "--file", str(part), "-C", str(dst), "."])
```

— `tar --create` with no compression flag, so the baseline is approximately the clone's own size.

**Evidence (verbatim, `scripts/crb-materialize.py:440-443`):**

```
    # taken from a tree that has just been proven contained. Doubles the disk
    # cost of the arm (pilot ~670 MB -> ~1.3 GB; --all ~6.5 -> ~13 GB), which is
    # the price of never running host git against a container-written .git.
```

**Nature:** resource debt, deliberately incurred.

Is this a carrying cost anyone will notice? At the pilot, no — 1.3 GB is noise. At `--all`, 13 GB
is the kind of number that matters on a laptop or a small cloud box, and it is the number the
runbook currently understates (D5). The uncompressed choice is defensible and I would not change
it: the clone is mostly a git object store, which is already zlib-compressed, so `-z` would buy
little and would add CPU to a per-cell extraction that is on the critical path of a $10-40 cell.
The genuinely cheap saving, if disk ever becomes the binding constraint, is to delete work clones
after the sweep and keep only the baselines — the baselines are the authoritative copy and
`--restore` reconstructs the clone in seconds.

**Cost of Deferral:** `+1 clone-sized tar per materialized slug` — grows only when new slugs are
materialized, which is a deliberate operator action, not a background process.

### Fix Cost
- **Scope:** localized (a cleanup mode) or none (accept).
- **Effort:** hours for a cleanup mode; zero to accept.
- **Risk:** low, but a cleanup that deletes the wrong side is unrecoverable without re-cloning
  50 forks.
- **Incremental?** yes.

### Urgency Triggers
- Expanding from the 5-PR pilot to `--all` on a machine with less than ~20 GB free.
- None imminent.

### Recommendation

**Recommendation:** Carry intentionally

The cost is understood, bounded, and paid deliberately in exchange for the property the whole
commit exists to establish. Fix the runbook's stale figure (D5) so the operator sizes the disk from
the right number, and otherwise leave it. If `--all` ever hits a disk wall, delete work clones
rather than compressing baselines.

---

## What happens to this machinery after the pilot

Three distinguishable fates, and they should be recorded before the sweep rather than argued about
after:

1. **The four `docker/` files and the `setup_egress`/preflight block** are the part with a life
   beyond this arm. They encode a control — one reachable host for an agent container — that
   applies to any future arm running an agent against a repo it does not own. Keep them in place
   for now (D6), but flag them as extraction candidates rather than arm-private, so the next arm's
   author finds them.
2. **`scripts/crb-materialize.py`, `crb-harvest-artifacts.py`, `crb-audit-clone.sh`** are
   CRB-specific and will die with the arm. They already live in `scripts/` rather than under the
   arm directory, which is the wrong side of the line if they are single-use — but moving them now
   is exactly the kind of refactor A20 argues against, and moving them later costs the same.
   Leave them.
3. **The 37 tests** are the durable artifact regardless of which way 1 and 2 go. They are the
   reason this commit reads as debt paydown rather than debt accumulation: `+1676` lines of which
   `632` are executable tests, against a deleted 396-line suite whose subject no longer exists.

The honest summary of A20 after this diff: the arm is now the kind of arm A20 said this repo does
not build. That does not invalidate the carry — it relocates the argument. The reason not to
refactor `crb-pipeline/` this week is no longer "arms are single-use"; it is "a paid sweep is
about to run against this exact code, and none of the docker path has ever executed". That is a
stronger argument with a clearer expiry date: it ends when the pilot completes.

---

## Goal-Alignment Note
- **Answered:** yes — ten debt items triaged with carry/fix/urgency, plus explicit answers on
  A20's continued validity, the post-pilot fate of the machinery, and the disk footprint.
- **Out of scope:** the security adequacy of the allowlist itself (DNS side channel, HTTPS_PROXY
  honouring) — those are execution questions the preflight answers, not debt; and any re-litigation
  of decision 034's rejected alternatives.
- **Escalate:** D1 is not really debt — it is a missing migration step that stops the pilot at cell
  zero, and it should be handed to whoever runs the sweep rather than filed. D2 is the same shape
  one level down. Both are advisory by this review's standing, but the orchestrator should decide
  whether "advisory" is the right tier for a finding that means the sweep does nothing.
