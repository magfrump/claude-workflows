# Tech Debt Triage: CRB direction-1 harness, cumulative fix work (59733d8..HEAD)

**Scope reviewed:** `git diff 59733d8..HEAD -- . ':!docs/reviews'` — commits cf6e7c9, 5bd0b09,
46a5f17. 1,294 insertions / 102 deletions across 10 files.
**Verification performed:** all three new bats suites run green (38/38); the corpus claims in
`crb-cell-status.py` were re-measured independently (32 `result.json` files; stubs at 51 and 56
chars; shortest real review 1,208 chars — all three confirmed); the A20 arm-lifetime evidence
was re-counted from `git log`; the `EXIT`-trap-on-SIGINT claim was confirmed by execution.

**Standing:** advisory (Consider tier) except where marked. D1 is raised above advisory because it
is a control introduced in this diff that fails during the operation the diff exists to enable.

---

## Summary ranking

| # | Debt Item | Carrying Cost | Cost of Deferral | Failure Cost | Fix Cost | Urgency | Recommendation |
|---|-----------|:---:|:---:|:---:|:---:|:---:|---|
| D1 | Corpus-pinned bats assertion is invalidated by the sweep it guards | High | +1 false test failure per cell run | Low × Med — a red suite mid-sweep trains the operator to ignore the suite that also guards containment | ~15 min | **Imminent — fires on cell 1** | Fix now |
| D2 | `run-meta.json` is clobbered by a subset re-run, silently narrowing the attrition denominator | Medium | +0 until the first subset re-run, then step-change | Low × High — the published recall number loses the bias caveat this diff was written to add | ~30 min | On first subset re-run | Fix now |
| D3 | A20's carry rationale rests on a miscounted statistic (10 of 15, not 13 of 15) | Low | +0 — inert | | Minutes | None | Fix opportunistically |
| D4 | Measured constants duplicated across script comment, bats comment, and runbook | Low | +1 divergence risk per corpus change | | Hours (or ~15 min for the cheap form) | On next corpus change | Carry intentionally |
| D5 | `attrition()` returns a `checked` flag no caller uses | Low | +0 — inert | | Minutes | None | Carry intentionally |
| D6 | Two full `git gc --prune=now` per cell on 33–195 MB clones | Low | +0 — inert | | — | None | Carry intentionally — do not touch |

### Recommended order

D1, then D2, then stop. D1 and D2 are both single-file, test-covered, and land *before* money is
spent; everything below them is cosmetic relative to a $50–2,000 sweep. D3 is a two-word edit to a
rubric row and can ride along with whatever commit closes D1. D4–D6 are explicitly **not** worth
doing before the sweep.

---

## D1 — The corpus pin in `crb-cell-status.bats` is invalidated by running the sweep

**Severity:** High (above advisory — soundness contradiction: a control added in this diff fails
during the operation this diff exists to enable)
**Location:** `test/crb-cell-status.bats:152-178`; `.gitignore` (absence of a rule for
`runs/review-arms/crb-pipeline/*/result.json`)
**Confidence:** High — the glob path, the hard-coded assertion, and the write path were each
checked directly; `git check-ignore` confirms the sweep's `result.json` files are not ignored.
**Legibility-target:** for-author

**Evidence (verbatim, `test/crb-cell-status.bats:159-174`):**

```
for p in sorted(glob.glob(os.path.join(root, "runs/review-arms/**/result.json"),
                          recursive=True)):
...
  # 32 cells, of which exactly 3 are known-bad: one budget exhaustion and two
  # quota stubs. Any other split means the predicate moved.
  [[ "$output" == *"complete=29 incomplete=3"* ]]
```

**Evidence (verbatim, `run-host.sh:226` and `:294`):**

```
  dest="$OUT/$id"
...
  python3 - "$dest/transcript.jsonl" "$dest/result.json" "$dest/review.md" <<'EOF'
```

with `OUT="$ROOT/runs/review-arms/crb-pipeline"` (`run-host.sh:54`).

**Evidence (verbatim, shell):**

```
$ git check-ignore -v runs/review-arms/crb-pipeline/grafana-PR79265/result.json
NOT IGNORED
```

**Nature:** testing debt — a fixture corpus defined by a live glob but asserted with a frozen count.

**Cost of Deferral:** `+1 false test failure per cell run` — the assertion breaks on the first
completed cell and stays broken, drifting further with every cell.

**Failure Cost:** `Low × Med` — no data is corrupted, but the operator learns during a paid sweep
that `test/crb-*.bats` is red-by-design, and the same suite directory holds
`crb-containment-reset.bats`, which is the non-vacuity pin on the containment guard. A suite the
operator has been trained to ignore is a suite that will not be believed when it fires for real.

### Carrying Cost: High

The debt does not cost anything *today* — the suite is green right now, which is precisely why it
is easy to miss. It costs the moment the branch is used for its purpose. The sweep writes
`runs/review-arms/crb-pipeline/<slug>/result.json` for every cell, into the exact glob the test
walks, and those files are tracked. A 5-PR pilot takes the count from `complete=29 incomplete=3`
to something like `complete=34 incomplete=3`; `--all` takes it to ~79. Every one of those is a
*correct* verdict from the predicate — the test fails for a reason that has nothing to do with the
predicate moving, which is the failure mode the comment above the assertion explicitly disclaims
("Any other split means the predicate moved").

There is a second-order harm specific to this arm: a voided or budget-killed cell writes a
`result.json` that the predicate correctly calls incomplete, so `incomplete` grows too, and the
named-path assertions (`mfc-postfix/rep2`, etc.) keep passing while the counts drift. The test will
therefore fail with a message that looks like the predicate regressed, during the window where the
operator is least able to spend time on it.

### Fix Cost
- **Scope:** localized — one bats file, one assertion plus the glob.
- **Effort:** ~15 minutes.
- **Risk:** low — the fix is to scope the corpus, not to change the predicate.
- **Incremental?** yes.

Cheapest form: exclude the arm under construction from the glob
(`if "crb-pipeline" in p: continue`) and say why in the comment. Slightly better: assert on the
*set of incomplete paths* rather than on `complete=N`, since the incomplete set is the load-bearing
claim (the counts are only a proxy for it) and it is stable under corpus growth in a way the totals
are not. Either is well under the "trivial fix, fix in place" bar.

### Urgency Triggers
- The first completed cell of any run, pilot or sweep. This is not a horizon — it is the next
  command the branch is for.

### Recommendation

**Recommendation:** Fix now

This is the one item where the carry argument does not apply. A20's reasoning is that refactor risk
lands inside the sweep window while the benefit lands in a maintenance phase that will not occur —
but here the *cost* lands inside the sweep window too, and the fix is fifteen minutes in a test
file that cannot affect the sweep's behaviour. There is no version of the A20 tradeoff that favours
carrying this.

---

## D2 — `run-meta.json` is rewritten with the current invocation's argv, so a subset re-run erases the attrition denominator

**Severity:** Medium-High
**Location:** `runs/review-arms/crb-pipeline/run-host.sh:160-220` (the `write_run_meta` function and
its `EXIT` trap); `scripts/crb-subset-leaderboard.py:59`
**Confidence:** High on the mechanism (both halves read directly and traced end to end);
Medium on how often it bites, since it requires a subset invocation — which is documented in the
script's own usage block.
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim, `run-host.sh:163-166`):**

```
  python3 - "$OUT/run-meta.json" "$PAYLOAD_REF" "$PAYLOAD_SHA" "$MODEL" \
           "$CC_VERSION" "$OUT" "${INSTANCES[*]}" <<'EOF' || true
import json, os, sys
meta_path, ref, sha, model, ccv, out, requested = sys.argv[1:8]
```

**Evidence (verbatim, `run-host.sh:206-210`):**

```
req = requested.split()
json.dump({"arm": "crb-pipeline", "payload_ref": ref, "payload_commit": sha,
           "model": model, "cc_version": ccv, "cells": cells,
           "requested_instances": req,
           "missing_cells": [s for s in req if s not in cells],
```

**Evidence (verbatim, `scripts/crb-subset-leaderboard.py:57-59`):**

```
    cells = meta.get("cells") or {}
    requested = meta.get("requested_instances") or sorted(cells)
    voided = set(meta.get("voided_cells") or [])
```

**Evidence (verbatim, `run-host.sh:46` — subset invocation is the documented workflow):**

```
#   ... run-host.sh discourse-graphite-PR4 grafana-PR79265     # subset
```

**Nature:** structural — a provenance file with whole-sweep semantics is written with
per-invocation scope, and the consumer has no way to tell the two apart.

**Cost of Deferral:** `+0 until the first subset re-run` — then a step change, because from that
point on every leaderboard the operator prints is missing the attrition warning entirely.

**Failure Cost:** `Low × High` — probability is low-ish (needs a subset re-run before the
leaderboard is generated) but severity is high and *silent*. The attrition warning exists because
"failed cells drop out of the denominator — which biases the numbers below in our favour"
(`crb-subset-leaderboard.py:78-81`). After a subset re-run, `requested_instances` shrinks to the
one or two slugs just retried, every one of which is now judged, so `lost` is empty and
`attrition()` returns `([], True)` — the warning prints *nothing*. Absence of the warning is
indistinguishable from "no attrition", which is exactly the reading the warning was added to
prevent. The `attrition NOT checked` fallback does not fire either, because the file exists.

### Carrying Cost: Medium

Today: nothing. The hazard is entirely in the interaction between two things this diff added in
different files. The realistic sequence is ordinary and documented: run `--all`, hit
`SWEEP_BUDGET` (the runbook now says to *expect* this — `crb-direction1-setup.md:173`), see two or
three cells voided or at `MAX_ATTEMPTS`, re-run just those with
`run-host.sh keycloak-PR36880 cal_com-PR11059`, then generate the leaderboard. The re-run's `EXIT`
trap overwrites `run-meta.json` with `requested_instances: ["keycloak-PR36880",
"cal_com-PR11059"]`, while `cells` still contains all 50 (it is rebuilt from `os.listdir($OUT)`).
The file is internally inconsistent — 50 cells, 2 requested — and the consumer trusts the
2-element field.

Note the irony worth naming for the author: making `write_run_meta` a trap (a genuine improvement,
and the SIGINT behaviour it claims is real — I confirmed bash runs the `EXIT` trap on `SIGINT` to a
non-interactive script) *increased* the number of code paths that clobber the file. The full-sweep
resume path is fine; it is the narrow retry that loses information.

### Fix Cost
- **Scope:** localized, but touches both the writer and the reader if done properly.
- **Effort:** ~30 minutes.
- **Risk:** low, and `test/crb-subset-attrition.bats` already has the fixture shape to pin the new
  behaviour (`make_run_meta`, lines 46-56, builds `requested_instances` from an explicit slug list).
- **Incremental?** yes.

Three options, cheapest first:

1. **Union with the previous file** (~10 lines in `write_run_meta`): read the existing
   `run-meta.json` if present and merge `requested_instances`. Cheap, no consumer change, and it
   makes the field mean "everything this output directory was ever asked to do" — which is what
   the leaderboard actually wants.
2. **Write per-invocation meta to a timestamped name** and have the leaderboard glob them. More
   correct, more moving parts, more to get wrong before a paid run.
3. **Do nothing in code; add a runbook line** telling the operator to re-run the *full* instance
   list after any subset retry so the meta is regenerated whole. Nearly free, and it is the
   honest fallback if the fix budget is zero — but it is a procedural control on a failure that is
   silent, which is the weakest kind.

I would take (1). It is a self-contained change to a function this diff just wrote, and it fails
safe: a union can only ever make the attrition list longer, never shorter.

### Urgency Triggers
- The first subset re-run — which the runbook's own budget-halt guidance makes likely on `--all`.
- Any leaderboard generated after a partial resume.

### Recommendation

**Recommendation:** Fix now

Carrying cost is medium and the fix is cheap, but what moves this above "fix opportunistically" is
that the failure is silent and lands on the *published number*. This diff spent real effort adding
a bias caveat that "survives the copy-paste into a results doc"
(`crb-subset-leaderboard.py:165-168`); a control that can be voided by the most ordinary recovery
action is worth thirty minutes before the money is spent, not after.

---

## D3 — A20's carry rationale rests on a statistic I could not reproduce

**Severity:** Low (advisory; correction to a prior rubric row, not to this diff's code)
**Location:** `docs/reviews/code-review-rubric-2026-08-18-feat-crb-direction1-harness.md:70`
**Confidence:** High — re-counted directly from `git log` per directory.
**Legibility-target:** for-orchestrator-synthesis

**Evidence (verbatim, rubric A20):**

```
Deliberate, on tech-debt evidence: 13 of 15 `runs/review-arms/` dirs have identical first/last commit dates
```

**Evidence (measured, `git log --reverse --format=%ad --date=short -- <dir>` per directory):**

```
baseline-2026-08-06/  first=2026-08-06 last=2026-08-07 commits=7
crb/                  first=2026-08-14 last=2026-08-18 commits=8
e4-opus-k3/           first=2026-08-13 last=2026-08-14 commits=3
e7-fable-3x/          first=2026-08-14 last=2026-08-18 commits=11
e8-evidence-pipeline/ first=2026-08-17 last=2026-08-18 commits=4
```

Five of fifteen directories span more than one day, so the identical-date count is **10 of 15**,
not 13.

**Nature:** documentation debt in a decision record — the conclusion survives, the evidence as
stated does not.

**Cost of Deferral:** `+0 — inert`. The number is quoted in one rubric row and nowhere else.

### Carrying Cost: Low

The directional claim is intact and I would not overturn A20 on this: ten of fifteen arms are
single-day, the median arm lifetime is under a day, and nothing in the history looks like
maintenance. But the correction is not purely cosmetic, because *which* arms got revisited is
informative in a way the aggregate hides. The two longest-lived directories are `e7-fable-3x`
(11 commits over 4 days) and `crb/` (8 commits over 4 days) — the arms with the most machinery are
the arms that came back. `crb-pipeline/` already has 6 commits, and this diff is its third fix
round in one day. That is a weak signal in the same direction as the user's own instinct, and it
should be stated alongside the count rather than left implicit.

### Fix Cost
- **Scope:** one rubric cell.
- **Effort:** minutes.
- **Risk:** none.
- **Incremental?** yes.

### Urgency Triggers
- None identified. The row is already `🟡 Carried`; the correction does not change the verdict.

### Recommendation

**Recommendation:** Fix opportunistically

Change "13 of 15" to "10 of 15" and add the qualifier that the two longest-lived arms are the two
with the most machinery. Do it in whatever commit closes D1; do not open work for it.

---

## D4 — Measured constants live in three places with no cross-check

**Severity:** Low (advisory)
**Location:** `scripts/crb-cell-status.py:20-32` and `:47-64`; `test/crb-cell-status.bats:15`,
`:89`, `:172-177`; `docs/working/crb-direction1-setup.md:150-165`
**Confidence:** High on the duplication (all three sites read); Medium on the rot rate, since the
one-day base rate is a small sample.
**Legibility-target:** for-author

**Evidence (verbatim, `scripts/crb-cell-status.py:49-53`):**

```
# Above this length a body is a review, not a stub, and NON_REVIEW no longer
# applies. Measured on the 32-cell corpus, NOT estimated: the two stubs are 51
# and 56 chars; the SHORTEST REAL REVIEW IS 1,208 chars, and 20 of the 32 bodies
# sit between 1.2 and 3.0 KB. 300 therefore clears the stubs by ~5x and the
# shortest real review by ~4x, roughly centred in the empty band.
```

**Evidence (verbatim, `docs/working/crb-direction1-setup.md:152-154`):**

```
  The non-review signatures apply **only below 300 chars** (the two stubs are 51
  and 56 chars; the shortest real review in the corpus is 1,208): "logged in" is
```

**Evidence (verbatim, `test/crb-cell-status.bats:88-89`):**

```
# real review is 1,208 chars). This is the only case where the substring list is
```

I re-measured all three claims against the 32 checked-in `result.json` files and all three are
currently **correct**: `n=32`, stubs at 51 and 56 chars, shortest real body 1,208 chars.

**Nature:** documentation debt — the same measured facts asserted in three artifacts with different
lifecycles.

**Cost of Deferral:** `+1 divergence risk per corpus change` — and the corpus changes when the
sweep runs, which is imminent.

**Failure Cost:** blank — the constants are pinned by an executable test (D1 notwithstanding), so a
divergence is a misleading comment, not a wrong verdict.

### Carrying Cost: Low

This is the item the user's third question is really about, so it deserves a direct answer rather
than a rating. **This is not the debt.** The two comments that rotted within a day rotted because
they made *causal claims about mechanism* that were never executed — "with no remote there is no
route to fetch it" and the original `scrub_object_store()` rationale. Both were reasoning, not
measurement, and both were refuted by running the thing. The long comments that replaced them are a
different species: they record what was measured, what refuted the previous version, and what the
mechanism explicitly does *not* establish. `fetch_traces()`'s docstring ends "Treat a fired check as
proof of contamination, never a quiet pass as proof of cleanliness" — that is the single most
valuable line in the diff, and it exists only because someone wrote down the refutation instead of
just fixing the code.

For a single-use arm whose durable product is the reasoning, 47% comment density (226 of 476 added
non-doc lines) is the right shape, not a defect. The correct read of the one-day base rate is not
"comments rot, write fewer" — it is "*unexecuted causal claims* rot, so mark them". The one thing
worth adopting is a convention rather than a refactor: constants that came from a measurement
should say which command produced them, so the next reader can re-run it in one line instead of
re-deriving the corpus. `crb-cell-status.py` almost does this already by naming
`test/crb-cell-status.bats` as the assertion site; the runbook copy does not.

### Fix Cost
- **Scope:** cross-cutting (three files) if de-duplicated properly; localized if only the runbook
  copy is replaced by a pointer.
- **Effort:** hours for the real fix; ~15 minutes for the cheap form.
- **Risk:** low, but non-zero: mechanically extracting the numbers into a shared constant would
  *reduce* legibility, because the value of these comments is that they are readable in place.
- **Incremental?** yes.

### Urgency Triggers
- The next corpus change — i.e. the sweep. But note the numbers are historical claims about a
  32-file corpus that existed on 2026-08-18; they do not become false when the corpus grows, only
  less current, provided the text says "the 32-cell corpus" rather than "the corpus". It already
  does, in the script and the bats file; the runbook says "the corpus".

### Recommendation

**Recommendation:** Carry intentionally

Do not de-duplicate. If anything is done here, it is a one-word edit to
`crb-direction1-setup.md:153` — "the corpus" → "the 2026-08-18 32-cell corpus" — which pins the
claim to the sample it was measured on and costs nothing. That is the whole fix I would endorse.

---

## D5 — `attrition()` returns a `checked` flag no caller uses

**Severity:** Low (advisory)
**Location:** `scripts/crb-subset-leaderboard.py:48-79`, consumed at `:169`
**Confidence:** High.
**Legibility-target:** for-author

**Evidence (verbatim, `scripts/crb-subset-leaderboard.py:169`):**

```
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
```

**Evidence (verbatim, the two return sites, `:51` and `:76-79`):**

```
        return ([f"!! subset attrition NOT checked: no run-meta.json at {run_meta_path} "
...
    return ([f"!! SUBSET ATTRITION: {len(lost)} of {len(requested)} attempted cell(s) are NOT "
```

**Nature:** dead interface — a two-tuple where a list would do.

**Cost of Deferral:** `+0 — inert`.

### Carrying Cost: Low

Genuinely inert. The flag is the natural hook for a future `--fail-on-attrition` exit code, which
would be a real improvement — but adding one now would be new behaviour before a paid run, not
debt paydown. Leaving the underscore is the honest signal that the hook is deliberate.

### Fix Cost
- **Scope:** localized. **Effort:** minutes. **Risk:** none. **Incremental?** yes.

### Urgency Triggers
- None identified.

### Recommendation

**Recommendation:** Carry intentionally

---

## D6 — Two `git gc --prune=now` per cell

**Severity:** Low (advisory; noted so it is on the record as *deliberately not* actioned)
**Location:** `scripts/crb-materialize.py`, `scrub_object_store()`, called from `reset_clone()`
which `run-host.sh` invokes at `:262` (pre-run) and `:359` (post-run)
**Confidence:** Medium — I did not benchmark `gc` on the 33–195 MB clones.
**Legibility-target:** for-author

**Evidence (verbatim, `scripts/crb-materialize.py`, `scrub_object_store()`):**

```
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
```

**Nature:** runtime cost, not structural debt.

**Cost of Deferral:** `+0 — inert`.

### Carrying Cost: Low

Two full `gc` runs per cell, 100 for a 50-cell sweep, on shallow depth-50 clones. Against a sweep
whose per-cell cost is minutes of model time and $10–40 of billing, this is noise. More
importantly, `test/crb-containment-reset.bats` proves the call is load-bearing — the benign
two-cell sequence VOIDs when `scrub_object_store()` is stubbed out — so any "optimisation" here is
a change to a containment guard for no measurable benefit.

### Fix Cost / Urgency Triggers
- Not applicable; no fix proposed.

### Recommendation

**Recommendation:** Carry intentionally

Listed explicitly as the thing I would **not** do at all. It is the most tempting-looking cleanup
in the diff and the one with the worst risk-to-benefit ratio before a paid run.

---

## Direct answers to the four questions

**1. Does the A20 carry still hold?**

Yes, with one correction and one narrowing. The correction is D3: the statistic is 10 of 15, not
13 of 15. The narrowing is that A20 was scoped to a *specific* refactor — the four bash heredocs
and the injector's independent re-derivation of the cell layout — and that refactor is still the
wrong trade. Nothing in this diff touched the heredoc duplication; the ~180 new lines in
`crb-materialize.py` went into a containment mechanism that now has 32 executable tests, and the
new script is an *extraction* that gave a previously untestable predicate fixtures. That is debt
paydown, not accumulation. The diff moved the arm in the direction A20 declined to move it, at
lower risk, by extracting rather than restructuring.

What has changed is the *evidence base* for the carry, not the verdict. Three fix rounds in one day
and six commits on the directory is the profile of `e7-fable-3x` and `crb/` — the two arms history
shows *did* get revisited. So A20's "revisit if this arm is re-run more than twice" trigger is
closer than it looks. I would leave A20 carried and tighten its trigger to: **revisit before the
second full `--all` sweep**, not after the second re-run.

**2. Is the comment density documentation debt, or the right form?**

The right form — see D4 for the full argument. The one-day rot base rate is real but it does not
generalise the way it first appears: both rotted comments were unexecuted *causal* claims
("with no remote there is no route…", the original `scrub_object_store()` rationale). The comments
that replaced them are measurements plus explicit negative results, and those are the durable
product of this branch. The refutation record in `fetch_traces()` and the "what this does NOT
establish" block in the runbook are worth more than the code they annotate, because they are what
stops the next session from re-deriving a control that was already proven inadequate. The only
adjustment worth making is pinning measured constants to their sample ("the 2026-08-18 32-cell
corpus"), which the script already does and the runbook does not.

**3. Anything that makes the sweep harder to re-run or to interpret?**

Two things, and they are D1 and D2 — which is why they are the only Fix-now items. D1 makes the
guard suite go red on the first completed cell, during the run, for a reason unrelated to what the
guard guards. D2 makes the attrition warning — this diff's own defence against a favourably-biased
recall number — disappear silently after the most ordinary recovery action, a subset re-run. Both
are re-run/interpretation failures specifically, which is the class the repo says it cares about,
and both were introduced by this diff rather than inherited.

**4. Cheapest thing on the list, and what would you not do at all?**

Cheapest with real value: **D1**, about fifteen minutes in a test file, zero effect on sweep
behaviour, and it removes a guaranteed mid-sweep distraction. Cheapest overall: D3, a two-word
rubric edit. Would not do at all: **D6** (the `gc` calls — tempting, load-bearing, no benefit) and
the de-duplication half of **D4** (mechanically extracting the measured constants into a shared
module would make the comments less readable in place, which is the entire property that makes
them worth having).

---

## Goal-Alignment Note
- Answered: yes — carry holds with a corrected statistic and a tightened trigger; two Fix-now
  re-runnability items found.
- Out of scope: the containment design's residual gap (an agent cloning elsewhere in the container
  filesystem, addressed only by the R3 egress allowlist) — the diff documents it honestly and it is
  a security-control question, not a tech-debt one. Also out of scope: whether `SWEEP_BUDGET=250`
  is the right default against the $500–2,000 `--all` estimate, which is a spend decision rather
  than debt.
- Escalate: **D1** should be actioned before any cell is run — it is the only finding in this pass
  that fails during the operation the branch exists to enable, and it is fifteen minutes. **D2**
  should be actioned before any leaderboard is published. Both are single-file and test-covered.
  Neither is a reason to delay the pilot beyond the time it takes to make the edits.
