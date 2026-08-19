# Code Fact-Check Report

**Scope:** `HEAD~1..HEAD` (commit `cf6e7c9`) — review-fix loop iteration 1 on `feat/crb-direction1-harness`
**Commit:** cf6e7c9
**Replication:** k=3
**Date:** 2026-08-18
**Total claims checked:** 20 merged clusters (45 / 30 / 30 raw claims across r1 / r2 / r3)

Merged most-severe-wins from `code-fact-check-report-r1.md`, `-r2.md`, `-r3.md` (all three
stamped `Commit: cf6e7c9`, verified distinct before merging). Evidence and reasoning are
carried from the replicate that assigned the winning verdict.

---

## Claim 1: An agent commit on top of the reviewed head cannot contain the answer key

**Location:** `scripts/crb-materialize.py:206-212` (`classify_strays()` docstring); doc twin at `docs/working/crb-direction1-setup.md:106-108`
**Claim:** "It cannot contain the answer key: the merged upstream fix is not a descendant of the PR head in this clone, and with no remote there is no route to fetch it."
**Verdict:** Incorrect
**Confidence:** High
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Legibility-target:** for-author

**Evidence.** All three replicates refuted this by execution, independently.

`git fetch <URL> <refspec>` requires no configured remote. It leaves no remote and no ref
under `refs/`, and writes its result to `.git/FETCH_HEAD` — which `git rev-list --all` does
not walk. Both guards this change relies on therefore miss it: the remote check at
`crb-materialize.py:231` and the stray check at `:210-211`.

r1 executed the complete attack path against the real code: it built a clone the way
`materialize()` does, fetched an "answer key" file with zero remotes configured, deleted the
fetched ref, and committed the content on top of `head`. `classify_strays()` returned
`foreign == []`, and `reset_clone()` reset it silently — no void, no warning.

The route is live in the arm: the review container runs with no `--network` restriction,
`--dangerously-skip-permissions`, and a read-write `/repo` mount (`run-host.sh:274-285`).

**Two refinements the replicates add, both material:**

r3: the merged fix is unreachable because it is **absent from the clone**, not because
descent fails — a merge commit of the PR *does* descend from the PR head. So descent is not
evidence of agent authorship, which is exactly the assumption the benign-reset rule rests on.

r1: "This is a genuine weakening versus the old check, which voided on any stray commit."
Fetch-and-*merge* is still caught (the fetched commits are non-descendants). Fetch-and-*copy*
is not.

**Impact:** this is the load-bearing rationale for treating descendant strays as benign, so
the rule is unenforced rather than merely undocumented. Behavioral, not doc-only.

---

## Claim 2: STUB_MAX_LEN=1000 sits an order of magnitude clear of both bands

**Location:** `scripts/crb-cell-status.py:42-46`
**Claim:** "the shortest real review in the corpus is over 3 KB, so anywhere in between works; 1000 sits an order of magnitude clear of both."
**Verdict:** Incorrect
**Confidence:** High
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Legibility-target:** for-author

**Evidence.** The corpus minimum for a real review is **1,208 chars**, not "over 3 KB".
r1 counts 15 real reviews under 2 KB; r2 counts 22 of 32 bodies between 1000 and 3000; r3
counts 20 between 1.2 and 3.0 KB. `STUB_MAX_LEN=1000` clears the stubs by ~18× but clears
real reviews by only ~20%.

**Impact:** load-bearing for pre-mortem narrative N5, which this commit exists to close. A
genuine sub-1000-char review of auth code is still rejected by `NON_REVIEW` — the exact
failure N5 describes. r1 and r3 both note the constant should be re-picked, not just
reworded. r1 logged this to `docs/reviews/hallucination-patterns.md` as the same class as
the existing `total_golden` entry: a measured value quoted from an artifact set that does
not contain it.

---

## Claim 3: run-host.sh calls verify_containment via --verify

**Location:** `scripts/crb-materialize.py:174`
**Verdict:** Stale
**Confidence:** High
**Replicate verdicts:** r1=— · r2=Stale · r3=Stale
**Legibility-target:** for-author

**Evidence.** This same commit switched both runner call sites to `--reset`
(`run-host.sh:212`, `:297`). Nothing calls `--verify` any more.

---

## Claim 4: test comment cites crb-materialize.py:221-223 for the branch -f warning

**Location:** `test/crb-containment-reset.bats:114-115`
**Verdict:** Stale
**Confidence:** High
**Replicate verdicts:** r1=— · r2=Incorrect · r3=Stale
**Legibility-target:** for-author

**Evidence.** This commit shifted that warning to `:285-287`; `:221-223` is now
`reset_clone()`'s docstring. (r2 rated this Incorrect, r3 Stale; merged at the more severe
of the two that are substantively the same defect — a citation that no longer resolves.)

---

## Claim 5: A docker failure still leaves the provenance file

**Location:** `docs/working/crb-direction1-setup.md:141-146`
**Verdict:** Incorrect
**Confidence:** Medium
**Replicate verdicts:** r1=Incorrect · r2=Mostly Accurate · r3=—
**Legibility-target:** for-author

**Evidence.** r1: the per-cell `docker run` is `||`-guarded (`run-host.sh:285-286`) so it
never exits the script; and the one unguarded docker call (`:113`) runs *before* the EXIT
trap is installed at `:220`. r2 reaches the same conclusion more narrowly (the claim holds
only for the per-cell call). Practical harm is nil — no cells have run yet — but the stated
mechanism is wrong.

---

## Claim 6: The e5 corpus bodies run 3–7 KB

**Location:** `scripts/crb-cell-status.py:20-21`; `docs/working/crb-direction1-setup.md:127-129`
**Verdict:** Mostly Accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=Mostly Accurate
**Legibility-target:** for-author

**Evidence.** Measured band is 2.7–7.1 KB. Unanimous across replicates, two locations.

---

## Claim 7: Both false-complete and false-incomplete directions have already happened in this repo's arms

**Location:** `scripts/crb-cell-status.py:10-14`
**Verdict:** Mostly Accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly Accurate · r2=— · r3=—
**Legibility-target:** for-author

**Evidence.** Only the false-*complete* direction is attested (e7's turns-only predicate
banking `mfc-hygiene/rep1`). `e5-cc-builtin`'s runner has no resume predicate at all, so its
eight `num_turns == 0` reviews were never re-paid — the false-*incomplete* direction is a
projected risk, not a historical event.

---

## Claim 8: requested_instances appears here and nowhere else

**Location:** `runs/review-arms/crb-pipeline/run-host.sh:265-268`
**Verdict:** Mostly Accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=—
**Legibility-target:** for-author

**Evidence.** `missing_cells`, written three lines below, carries the same information.

---

## Claim 9: The NON_REVIEW quota stubs are a weekly limit

**Location:** `scripts/crb-cell-status.py:30-34`
**Verdict:** Mostly Accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly Accurate · r2=Mostly Accurate · r3=—
**Legibility-target:** for-author

**Evidence.** The two corpus stubs are one *weekly* limit (56 chars) and one *session* limit
(51 chars); the comment names only the weekly form.

---

## Claim 10: Any commit reachable outside the head's ancestry voids the cell

**Location:** `scripts/crb-materialize.py` `reset_clone()` docstring
**Verdict:** Mostly Accurate
**Confidence:** High
**Replicate verdicts:** r1=Mostly Accurate · r2=— · r3=—
**Legibility-target:** for-author

**Evidence.** Should read "not descended from head" — the implemented predicate is descent,
not reachability. (This is the wording half of Claim 1's substantive defect.)

---

## Claims 11–20: Verified

All three replicates independently confirmed the following. Where a claim was nominated in
the shared brief as needing checking, the check was **executed**, not read.

| # | Claim | Location | Replicate verdicts |
|---|---|---|---|
| 11 | `complete=29 incomplete=3` over all 32 checked-in `result.json`, with exactly the three named cells (`mfc-hygiene/rep1`, `mfc-postfix/rep2`, `mfc-postfix/rep3`) | `test/crb-cell-status.bats` | r1=r2=r3=Verified |
| 12 | 8 e5-cc-builtin cells are genuine successes with `num_turns == 0` | `scripts/crb-cell-status.py:18-20` | r1=r2=r3=Verified |
| 13 | `e7-fable-3x/mfc-hygiene/rep1`: `subtype=error_max_budget_usd`, `$15.24` | `scripts/crb-cell-status.py:16-18` | r1=r2=r3=Verified |
| 14 | The 200-char floor, not the substring list, is what rejects both corpus stubs | `scripts/crb-cell-status.py:42-46` | r1=r2=r3=Verified |
| 15 | The second `trap … EXIT` replaces the first, and `PAYLOAD_SRC` cleanup survives every exit path | `run-host.sh:220` | r1=r2=r3=Verified |
| 16 | The EXIT trap runs on the budget `exit 2` **and** on an untrapped SIGINT (r1 executed under a pty; r2 on bash 5.2.15) | `run-host.sh:342-367`, `:220` | r1=r2=r3=Verified |
| 17 | `git checkout -- .` restores from the index; a staged edit and a commit both survive it (executed against `HEAD~1`'s version) | `run-host.sh` prior version | r1=r2=r3=Verified |
| 18 | `run-meta` field names agree end to end between writer and reader (`requested_instances` / `cells` / `voided_cells`); `RUN_META` path matches `$OUT` — no silent attrition under-report | `crb_common.py`, `crb-subset-leaderboard.py` | r1=r2=r3=Verified |
| 19 | Two pilot instances are auth-domain (`keycloak-PR36880`, `cal_com-PR11059`) | `runs/review-arms/crb/instances.json` | r1=r2=r3=Verified |
| 20 | `--verify` / `--reset` help text matches implemented behavior and dispatch; all 32 bats tests in the three new suites pass, exit 0 | `crb-materialize.py`, `test/` | r1=r2=r3=Verified |

---

## Reviewer-grade observations (out of fact-check scope, escalated)

Recorded by r1 under "out of scope" — not verdicted here, forwarded to Stage 2:

- `PF_HOME` and `INST_HOME` temp dirs are removed inline but not trapped, so they leak on an
  early exit.
- `reset_clone()` omits the `reflog expire` / `gc --prune=now` that `materialize()` runs, so
  the clone's object-store baseline is not restored between cells.

---

## Verdict stability

- **Total merged clusters:** 20
- **Clusters where all reporting replicates agreed:** 18
- **Clusters with disagreement:** 2
  - Claim 4 — r2=Incorrect, r3=Stale (same defect, different band for a dead line citation)
  - Claim 5 — r1=Incorrect, r2=Mostly Accurate (r1 found a second, unguarded docker call
    that r2's narrower reading missed)
- **Agreement rate:** 18/20 = **90%**

Both disagreements are adjacent-band, and in both the more severe verdict came from the
replicate that had done the wider check — consistent with §1.1's observed failure mode being
under-calling rather than over-calling, and with most-severe-wins being the right aggregator.

Note the agreement rate is high **on this diff** partly because the shared brief nominated 12
specific claims with executable checks; the two Incorrect findings were each reached
independently by all three replicates via their own executions. That is the k=3 protocol
working as designed on its blocking channel.

## Goal-Alignment Note
- Answered: yes — 20 merged clusters, 2 blocking-grade Incorrect findings, k=3 intact.
- Out of scope: whether the void/reset *policy* is correct (Stage 2 critics own that).
- Escalate: Claim 1 to `security-reviewer` alongside the still-open R3 — the answer-key
  invariant is asserted but not established.
