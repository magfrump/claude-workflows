# Code Fact-Check Report

**Commit:** 5bd0b09
**Replication:** k=1 (loop pass, decision 031)
**Repository:** /workspace (branch `feat/crb-direction1-harness`)
**Scope:** `git diff 59733d8..HEAD -- . ':!docs/reviews'` — commits cf6e7c9 and 5bd0b09 over `docs/working/crb-direction1-setup.md`, `runs/review-arms/crb-pipeline/run-host.sh`, `scripts/crb-cell-status.py`, `scripts/crb-materialize.py`, `scripts/crb-subset-leaderboard.py`, `scripts/crb_common.py`, `test/crb-cell-status.bats`, `test/crb-containment-reset.bats`, `test/crb-subset-attrition.bats`. Partial scope: the rest of the branch is context, not under review.
**Checked:** 2026-08-19
**Total claims checked:** 33
**Summary:** 25 verified, 2 mostly accurate, 0 stale, 5 incorrect, 1 unverifiable

Hallucination-pattern log read before checking (`docs/reviews/hallucination-patterns.md`, 2 entries). Neither logged pattern recurs in this diff: the `"shortest real review … over 3 KB"` fabrication is explicitly retracted and replaced with the correct 1,208 (Claim 14a), and the `total_golden 11 vs 13` claim is not in this diff's text. Claim 14b is adjacent to the first logged pattern (a corpus count quoted as measured) and is called out as such in its verdict block.

Execution logs for all `executed` claims are under `docs/reviews/execution-logs/fc2-*.txt`.

---

## Claim 1: "The clone is reset with `crb-materialize.py --reset <slug>` after harvesting, so re-runs start from the same state"

**Location:** `docs/working/crb-direction1-setup.md:89-91`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the documented post-harvest reset command matches the one run-host.sh invokes; does not establish that the reset restores every filesystem property (Claim 2 covers behaviour).

The post-harvest call site is `--reset`:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:359
  if ! python3 "$ROOT/scripts/crb-materialize.py" --reset "$id"; then
```

**Evidence:** `docs/working/crb-direction1-setup.md:89-91`, `runs/review-arms/crb-pipeline/run-host.sh:359`

---

## Claim 2: "A commit that **descends from the reviewed head**, in a clone with **no fetch traces**, is therefore **reset** — along with staged edits, created branches/tags, and a deleted `main`. A surviving **remote**, a **fetch trace**, or a commit that does **not** descend from the head still **voids**."

**Location:** `docs/working/crb-direction1-setup.md:104-113`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the six listed behaviours as exercised by `test/crb-containment-reset.bats`; does not establish behaviour on a clone whose `.git` directory was tampered with outside git's own commands.

Command: `bats test/crb-containment-reset.bats test/crb-cell-status.bats test/crb-subset-attrition.bats`; cwd `/workspace`; exit 0; 2026-08-19 03:09 UTC; 36/36 `ok`, 0 `not ok`. The reset-vs-void split is asserted by the named cases (`an agent commit on top of the reviewed head is reset, not voided`; `a staged edit to a tracked file is undone`; `a branch the agent created is pruned`; `main is restored if the agent deletes or moves it`; `a re-added remote still VOIDS the cell`; `a commit outside the reviewed ancestry still VOIDS the cell`; `a tag pointing outside the reviewed ancestry still VOIDS the cell`) (paraphrased — no quote available because the assertion is spread over seven separate `@test` blocks and reads more clearly as a list than as seven fragments).

**Evidence:** `test/crb-containment-reset.bats:70-165`, `test/crb-containment-reset.bats:257-268`, `docs/reviews/execution-logs/fc2-bats.txt`

---

## Claim 3: "The old reset (`git checkout -- . && git clean -qfdx`) restored tracked files *from the index*, so it undid neither a commit nor a `git add`"

**Location:** `docs/working/crb-direction1-setup.md:111-116`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failure mode of the pre-cf6e7c9 reset as exercised on a fixture; does not establish the frequency with which it occurred in past sweeps.

The old module (`git show cf6e7c9:scripts/crb-materialize.py`) run over a clone carrying a fetched answer key committed on top of the head returned success where the current module voids:

```
# docs/reviews/execution-logs/fc2-old-vs-new.txt
=== mat-old.py
OK: 1 agent commit(s) on top of the head, reset
=== crb-materialize.py
VOID: fixture: FETCH_HEAD present — something fetched into this clone; 1 unreachable commit(s) …
```

Command: `bash .scratch/fc2/old_vs_new.sh`; cwd `/workspace`; exit 0; 2026-08-19 03:09 UTC.

**Evidence:** `docs/reviews/execution-logs/fc2-old-vs-new.txt`, `scripts/crb-materialize.py:285-330`

---

## Claim 4: "`git fetch <URL> <refspec>` needs no configured remote, and its objects land in `.git/FETCH_HEAD`, which `git rev-list --all` does not walk"

**Location:** `docs/working/crb-direction1-setup.md:121-126` (restated at `scripts/crb-materialize.py:204-210`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 on a shallow clone built the way `materialize()` builds one; does not establish behaviour on other git versions or on partial-clone (`--filter`) repositories.

Executed on a scratch clone with zero remotes:

```
# docs/reviews/execution-logs/fc2-fetch-attacks.txt (and the by-URL bare-fetch probe)
remotes=[]
FETCH_HEAD=1100f8f685…  branch 'answerbr' of file:///workspace/.scratch/fc2/up
rev-list --all --not head => []
answer.txt readable: ANSWER KEY: fix is to sanitize input
```

Command: `python3 drv.py`; cwd `/workspace/.scratch/fc2`; exit 0; 2026-08-19 03:12 UTC.

**Evidence:** `docs/reviews/execution-logs/fc2-fetch-attacks.txt`, `scripts/crb-materialize.py:204-210`

---

## Claim 5: "the upstream *merge* commit of the PR descends from the PR head too"

**Location:** `docs/working/crb-direction1-setup.md:127` (restated at `scripts/crb-materialize.py:250-251`)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers merge-commit merges, where the PR head is by definition a parent; does not establish the same for squash- or rebase-merged PRs, where the upstream commit does *not* descend from the head — the claim as written is true for the case it names but the guard's exposure is not limited to that case.

A merge commit's second parent is the PR head, so `git merge-base --is-ancestor <head> <merge>` returns 0 by construction — this is the same predicate `classify_strays()` uses to decide foreignness:

```python
# scripts/crb-materialize.py:246-248
    foreign = [c for c in strays
               if subprocess.run(["git", "merge-base", "--is-ancestor", head, c],
                                 cwd=dst, capture_output=True).returncode != 0]
```

**Evidence:** `scripts/crb-materialize.py:244-249`, `docs/working/crb-direction1-setup.md:127`

---

## Claim 6: "An agent that also deletes `FETCH_HEAD`, or clones elsewhere in the container filesystem, defeats it."

**Location:** `docs/working/crb-direction1-setup.md:132-134` (same assertion at `scripts/crb-materialize.py:222-224`, verdicted separately as Claim 18)
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the "deletes FETCH_HEAD" half of the disjunction; does not evaluate the "clones elsewhere in the container filesystem" half, which is correct and untested here.

Deleting `FETCH_HEAD` alone does **not** defeat the detection — the unreachable-commit check still fires. Scenario D (fetch by URL, delete the fetched ref, delete `FETCH_HEAD`) and scenario C (same, plus committing the answer content on top of `review`) both VOID:

```
# docs/reviews/execution-logs/fc2-fetch-attacks.txt
--- C: fetch, content committed on top of review, ref+FETCH_HEAD deleted
   reset_clone: VOIDED — scratch: 1 unreachable commit(s) …
--- D: fetch, ref deleted, FETCH_HEAD deleted
   reset_clone: VOIDED — scratch: 1 unreachable commit(s) …
--- E: as C, plus reflog expire + gc --prune=now
   reset_clone: PASSED (note='1 agent commit(s) on top of the head, reset')
```

What the code actually requires to be defeated git-locally is `FETCH_HEAD` removal **plus** `git reflog expire --expire=now --all` **plus** `git gc --prune=now` (scenario E). The doc understates the guard. Commands: `python3 drv.py`; cwd `/workspace/.scratch/fc2`; exit 0; 2026-08-19 03:12 UTC.

**Evidence:** `docs/reviews/execution-logs/fc2-fetch-attacks.txt`, `scripts/crb-materialize.py:229-241`

---

## Claim 7: "the two stubs are 51 and 56 chars; the shortest real review in the corpus is 1,208"

**Location:** `docs/working/crb-direction1-setup.md:143-145`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 32 checked-in `runs/review-arms/**/result.json` bodies; does not establish that a future sweep's shortest real review will exceed 1,208.

```
# docs/reviews/execution-logs/fc2-corpus-measure.txt
files: 32
min real (excl stubs/errors): 1208
```
The 51/56-char bodies are `e7-fable-3x/mfc-postfix/rep3` and `rep2` respectively. Command: `python3` inline measurement over `runs/review-arms/**/result.json`; cwd `/workspace`; exit 0; 2026-08-19 03:13 UTC.

**Evidence:** `docs/reviews/execution-logs/fc2-corpus-measure.txt`

---

## Claim 8: "two pilot instances are auth-domain (`keycloak-PR36880`, `cal_com-PR11059`)"

**Location:** `docs/working/crb-direction1-setup.md:146-147` (restated at `scripts/crb-cell-status.py:41-45` and `test/crb-cell-status.bats:8-10`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pilot membership and the PR titles; does not establish that only two of the five are auth-domain (the other three were not classified).

```
$ python3 scripts/crb-materialize.py --per-repo 1 --dry-run
  cal_com-PR11059 … discourse-graphite-PR4 … grafana-PR79265 … keycloak-PR36880 … sentry-greptile-PR5
```
Titles read out of `external/code-review-benchmark/…/benchmark_data.json`: keycloak/36880 = "Add Client resource type and scopes to authorization schema" (quoted exactly in the source comment); calcom/11059 = "OAuth credential sync and app integration enhancements" — the comment quotes this as `"OAuth credential sync"`, a truncation of the real title, not a different title. Command: `python3 scripts/crb-materialize.py --per-repo 1 --dry-run`; cwd `/workspace`; exit 0; 2026-08-19 03:11 UTC.

**Evidence:** `docs/reviews/execution-logs/fc2-corpus-measure.txt` (companion run recorded in transcript), `scripts/crb-cell-status.py:41-45`

---

## Claim 9: "8 real cells in this repo are genuine successes with `num_turns == 0` and 2.7–7.1 KB of review text"

**Location:** `docs/working/crb-direction1-setup.md:149-151` (restated at `scripts/crb-cell-status.py:24-27`)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight `e5-cc-builtin` cells; does not establish that they contain substantive review prose beyond their length.

```
# docs/reviews/execution-logs/fc2-corpus-measure.txt
e5 count/min/max: 8 2733 7121 all turns==0: True
```
2,733 chars = 2.7 KB and 7,121 = 7.1 KB, and all eight report `is_error=False, subtype=success`.

**Evidence:** `docs/reviews/execution-logs/fc2-corpus-measure.txt`

---

## Claim 10: "**On `--all`, expect to hit it** — the 50-PR estimate is $500–2000 … The default sits above the $50–200 pilot estimate below on purpose"

**Location:** `docs/working/crb-direction1-setup.md:160-165`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arithmetic relation between `SWEEP_BUDGET`'s default and the doc's own two estimates; does not establish that the cost estimates themselves are right.

```bash
# runs/review-arms/crb-pipeline/run-host.sh:68
SWEEP_BUDGET="${SWEEP_BUDGET:-250.00}"
```
```
| 5-PR pilot | **~$50–200** | …            docs/working/crb-direction1-setup.md:268
| All 50 | **~$500–2000** | …            docs/working/crb-direction1-setup.md:269
```
250 > 200 and 250 < 500, so both halves hold.

**Evidence:** `runs/review-arms/crb-pipeline/run-host.sh:68`, `docs/working/crb-direction1-setup.md:268-269`

---

## Claim 11: "`run-meta.json` is written from an `EXIT` trap, so the budget halt, a `Ctrl-C`, and a docker failure all still leave the provenance file; it previously sat after the loop and the halt skipped it"

**Location:** `docs/working/crb-direction1-setup.md:165-169`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that a bash `EXIT` trap of this shape fires on `exit 2`, on `SIGINT`, and on a `set -e` command failure, and that the pre-5bd0b09 code sat after the loop; does not establish behaviour under `SIGKILL` (where no trap can run).

A minimal reproduction of the trap shape:

```
# docs/reviews/execution-logs/fc2-exit-trap.txt
budget       run-meta written=YES
sigint       run-meta written=YES
dockerfail   run-meta written=YES
```
Command: `bash .scratch/fc2/trap_test.sh`; cwd `/workspace`; exit 0; 2026-08-19 03:11 UTC. In the shipped script the trap is installed before the loop and the budget gate exits from inside it:

```bash
# runs/review-arms/crb-pipeline/run-host.sh:220
trap 'write_run_meta; rm -rf "$PAYLOAD_SRC"' EXIT
```
The "previously sat after the loop" half is confirmed by the diff, which deletes the inline `run-meta` block from below `done` (paraphrased — no quote available because the claim is about the removal of a 40-line block, visible only as a diff hunk).

**Evidence:** `docs/reviews/execution-logs/fc2-exit-trap.txt`, `runs/review-arms/crb-pipeline/run-host.sh:150-220`, `runs/review-arms/crb-pipeline/run-host.sh:404-431`

---

## Claim 12: "The script now cross-checks the judged subset against `run-meta.json`'s `requested_instances`, names every missing cell with its reason, and repeats the warning inside `--markdown` … If it prints `attrition NOT checked`, the run-meta was not found"

**Location:** `docs/working/crb-direction1-setup.md:252-261`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four documented behaviours as pinned by `test/crb-subset-attrition.bats`; does not establish that the reason strings correctly classify every real-world failure (they are derived from `run-meta.json` fields, not observed).

```python
# scripts/crb-subset-leaderboard.py:57
    requested = meta.get("requested_instances") or sorted(cells)
```
```python
# scripts/crb-subset-leaderboard.py:176-177
        for note in ([warn] if warn else []) + ([("\n".join(att_lines))] if att_lines else []):
            print("> " + note.replace("\n", "\n> ") + "\n")
```
and the missing-file branch prints `!! subset attrition NOT checked: no run-meta.json at {run_meta_path}` (`scripts/crb-subset-leaderboard.py:50-53`). The bats suite pins all four (`no attrition warning when every attempted cell was judged`, `cells that never reached the judge are named, with a reason`, `attrition appears in the markdown body, not only on stderr`, `a missing run-meta says attrition was NOT checked rather than staying silent`) — all `ok` in the 36/36 run. Command as Claim 2.

**Evidence:** `scripts/crb-subset-leaderboard.py:40-80`, `test/crb-subset-attrition.bats`, `docs/reviews/execution-logs/fc2-bats.txt`

---

## Claim 13: "The false-COMPLETE direction has already happened in this repo's arms (e7's turns-only predicate banked a budget-exhausted cell); the false-incomplete direction is a projected risk, not yet an observed one -- e5-cc-builtin's runner had no resume predicate at all, so its eight `num_turns == 0` reviews were never re-paid."

**Location:** `scripts/crb-cell-status.py:11-17`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the two named runners' resume predicates and the artifact each claim rests on; does not establish that no *other* arm in the repo re-paid a completed cell.

E7's rep-skip predicate is turns-only:

```bash
# runs/review-arms/e7-fable-3x/run-host.sh:120-124
    if [ -s "$dest/result.json" ] && python3 -c '
…
sys.exit(0 if d.get("num_turns", 0) > 0 else 1)
' "$dest/result.json" 2>/dev/null; then
```
and the budget-exhausted cell it would bank reports `num_turns=1`, so the predicate exits 0 and skips it (`runs/review-arms/e7-fable-3x/mfc-hygiene/rep1/result.json`: `is_error=True subtype=error_max_budget_usd turns=1`, per `docs/reviews/execution-logs/fc2-corpus-measure.txt`). E5's runner contains no `result.json` existence test or skip branch at all — its only reference to `result.json` is the redirect that writes it:

```bash
# runs/review-arms/e5-cc-builtin/run-host.sh:55
    > "$OUT/$id/result.json" 2> "$OUT/$id/stderr.log" || {
```
(paraphrased — no quote available because the claim covers the *absence* of a skip branch; `grep -n "result.json\|skip\|complete"` over that file returns only the write, the summariser, and the closing echo.)

**Evidence:** `runs/review-arms/e7-fable-3x/run-host.sh:118-125`, `runs/review-arms/e5-cc-builtin/run-host.sh:40-65`, `docs/reviews/execution-logs/fc2-corpus-measure.txt`

---

## Claim 14a: "the SHORTEST REAL REVIEW IS 1,208 chars … 300 therefore clears the stubs by ~5x and the shortest real review by ~4x"

**Location:** `scripts/crb-cell-status.py:49-54`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the corpus minimum and the two ratios; does not establish that 300 is the optimal threshold.

```
# docs/reviews/execution-logs/fc2-corpus-measure.txt
min real (excl stubs/errors): 1208
300/56 = 5.357142857142857  1208/300 = 4.026666666666666
```
Both ratios round to the stated "~5x" and "~4x". Command and provenance as Claim 7.

**Evidence:** `docs/reviews/execution-logs/fc2-corpus-measure.txt`, `scripts/crb-cell-status.py:55`

---

## Claim 14b: "20 of the 32 bodies sit between 1.2 and 3.0 KB"

**Location:** `scripts/crb-cell-status.py:51-52`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of `result.json` bodies in the stated length band; does not affect the surrounding conclusion that 300 sits in an empty band, which holds either way.

The measured count is 22 (decimal KB) or 21 (binary KiB), not 20:

```
# docs/reviews/execution-logs/fc2-corpus-measure.txt
1200<=n<=3000: 22
1228.8<=n<=3072 (KiB): 21
```
Precise version: "22 of the 32 bodies sit between 1.2 and 3.0 KB". Adjacency note: this is the same *class* as the logged pattern `"shortest real review in the corpus is over 3 KB" claimed in crb-cell-status.py but the corpus minimum is 1,208 chars` (first seen 2026-08-19) — a corpus count asserted as measured. It is not the same claim and is off by 2 rather than by an order of magnitude, and the load-bearing number in the same comment (1,208) is now correct, so it does not warrant a new log entry. Command and provenance as Claim 7.

**Evidence:** `docs/reviews/execution-logs/fc2-corpus-measure.txt`, `scripts/crb-cell-status.py:49-55`

---

## Claim 15: "2 e7 cells report subtype=success, is_error=false, num_turns=0 with a 51-56 char body that is actually a quota stub -- one weekly limit (56 chars), one session limit (51 chars)"

**Location:** `scripts/crb-cell-status.py:27-30`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two stub bodies' lengths, texts, and status fields; does not establish that no other cell in the corpus is a stub of a kind not matched by `NON_REVIEW`.

```
56 "You've hit your weekly limit · resets Aug 18, 12am (UTC)"   e7-fable-3x/mfc-postfix/rep2
51 "You've hit your session limit · resets 5:10am (UTC)"        e7-fable-3x/mfc-postfix/rep3
```
Both report `is_error=False subtype=success turns=0`. Command: `python3` inline read of the two files; cwd `/workspace`; exit 0; 2026-08-19 03:08 UTC.

**Evidence:** `docs/reviews/execution-logs/fc2-corpus-measure.txt`, `runs/review-arms/e7-fable-3x/mfc-postfix/rep2/result.json`, `runs/review-arms/e7-fable-3x/mfc-postfix/rep3/result.json`

---

## Claim 16: "This was 1000 in cf6e7c9, justified by a claim that the shortest real review was 'over 3 KB' … All three k=3 fact-check replicates caught it independently"

**Location:** `scripts/crb-cell-status.py:55-60`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the prior constant, the prior justification text, and the three replicate reports' coverage of it; does not establish that the replicates were genuinely independent runs.

```python
# git show cf6e7c9:scripts/crb-cell-status.py:44,46
# is over 3 KB, so anywhere in between works; 1000 sits an order of magnitude
STUB_MAX_LEN = 1000
```
All three of `docs/reviews/code-fact-check-report-r{1,2,3}.md` contain the corrected figure `1,208`/`1208` (`grep -l` returned all three), and the pattern is logged in `docs/reviews/hallucination-patterns.md`.

**Evidence:** `scripts/crb-cell-status.py:55-60`, `docs/reviews/hallucination-patterns.md`

---

## Claim 17: "This floor is what actually rejects both stubs in the corpus (51 and 56 chars) — NON_REVIEW is never consulted for them … the division of labour is asserted in test/crb-cell-status.bats"

**Location:** `scripts/crb-cell-status.py:62-68`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the ordering of the two rules in `status()` and the tests that pin it; does not establish that no future stub would land in the 200–300 band.

The floor short-circuits before `NON_REVIEW` is reached:

```python
# scripts/crb-cell-status.py:80-86
    if len(r) < MIN_REVIEW_LEN:
        return False, f"body is {len(r)} chars, under the {MIN_REVIEW_LEN}-char floor"
    if len(r) < STUB_MAX_LEN:
        low = r.lower()
        hit = next((s for s in NON_REVIEW if s in low), None)
```
and the suite asserts each side by the reason string it produces — `the short auth stub is rejected — by the length floor` / `the short quota stub is rejected — by the length floor` assert `*floor*`, while `a mid-length auth stub is rejected by the substring rule` / `a mid-length quota stub is rejected by the substring rule` assert the substring branch. All four `ok` in the 36/36 run (command as Claim 2).

**Evidence:** `scripts/crb-cell-status.py:78-90`, `test/crb-cell-status.bats:70-105`, `docs/reviews/execution-logs/fc2-bats.txt`

---

## Claim 18: "These two checks are therefore DETECTION OF TRACES … (a) `.git/FETCH_HEAD` — written by every fetch, including a by-URL fetch … (b) unreachable commits — what a fetch-then-delete-the-ref leaves behind"

**Location:** `scripts/crb-materialize.py:212-220`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four attack shapes named or implied by the docstring (by-URL fetch; fetch-then-delete-ref; fetch-then-delete-ref-and-FETCH_HEAD; fetch-commit-on-top-then-cover); does not establish detection of an agent that fetches into a clone outside `$dst`.

```
# docs/reviews/execution-logs/fc2-fetch-attacks.txt
--- A: by-URL fetch, ref kept, FETCH_HEAD kept        → VOIDED (FETCH_HEAD present)
--- B: fetch, ref deleted, FETCH_HEAD kept            → VOIDED (FETCH_HEAD + 1 unreachable commit)
--- C: fetch, content committed on top, both deleted  → VOIDED (1 unreachable commit)
--- D: fetch, ref deleted, FETCH_HEAD deleted         → VOIDED (1 unreachable commit)
```
Command: `python3 drv.py`; cwd `/workspace/.scratch/fc2`; exit 0; 2026-08-19 03:12 UTC. Note the docstring's own bounding paragraph is separately Incorrect — see Claim 6 (same sentence, doc copy) and the mirror at `scripts/crb-materialize.py:222-224`.

**Evidence:** `docs/reviews/execution-logs/fc2-fetch-attacks.txt`, `scripts/crb-materialize.py:229-241`

---

## Claim 19a: "`--connectivity-only` keeps this cheap on 33-195 MB clones"

**Location:** `scripts/crb-materialize.py:233-234`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers only the cost half of the comment; does not establish a measured runtime difference, which would require a 33–195 MB clone that this sandbox has no network access to create.

`git fsck --connectivity-only` skips object-content parsing by documented design, which is directionally consistent with the claim (paraphrased — no quote available because the claim is about `git`'s own implementation, not about code in this repo). No real CRB clone exists under `external/crb-eval` in this sandbox and materialization requires network, so the "33-195 MB" figure and the cost saving cannot be measured here. To verify: run `git fsck --unreachable` with and without the flag on a materialized clone and compare wall time.

**Evidence:** `scripts/crb-materialize.py:233-237`

---

## Claim 19b: "[`--connectivity-only`] avoids content checks that a SHALLOW clone's boundary would otherwise trip" (restated in the test header as "`--connectivity-only` is what keeps it quiet")

**Location:** `scripts/crb-materialize.py:233-235`, `test/crb-containment-reset.bats:229-231`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `git fsck` output and exit status on shallow clones built by `git clone --depth=N file://…` under git 2.39.5; does not establish behaviour on clones with a broken/partial pack, where content checks could genuinely differ.

On a shallow clone scrubbed to the materialize baseline, `git fsck --unreachable` is silent **with or without** the flag — the shallow boundary trips neither:

```
# docs/reviews/execution-logs/fc2-shallow-fsck.txt
-- with
exit=0
-- without
exit=0
```
Command: `git -C .scratch/fc2/sh1 fsck --unreachable [--connectivity-only] --no-progress`; cwd `/workspace`; exit 0 both; 2026-08-19 03:12 UTC. The flag is therefore not load-bearing for quietness on a shallow clone; the accurate statement is the cost one (Claim 19a). The bats case `fetch-trace detection is quiet on a SHALLOW clone` asserts only `TRACES: []`, which holds with the flag removed, so the test does not pin what its header claims.

Separately observed in the same runs: a real materialized clone retains a dangling `.git/refs/remotes/origin/HEAD` symref (because `git update-ref -d` dereferences symrefs, deleting `origin/master` and leaving `origin/HEAD`), and `git fsck` then exits 2 with `error: refs/remotes/origin/HEAD: invalid sha1 pointer 0000…` in **both** modes. `fetch_traces()` passes `check=False` and filters for lines beginning `unreachable commit`, so this does not produce a false void — but it does mean the fsck call routinely exits non-zero in production.

**Evidence:** `docs/reviews/execution-logs/fc2-shallow-fsck.txt`, `scripts/crb-materialize.py:233-238`, `test/crb-containment-reset.bats:232-255`

---

## Claim 20: "`foreign` = does not descend from the reviewed head. … The expected benign case is real and common: the payload's own CLAUDE.md instructs the reviewing agent to commit its work, so voiding on any stray (the pre-cf6e7c9 behaviour) would void most cells of the sweep."

**Location:** `scripts/crb-materialize.py:244-256`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers the definition of `foreign` and the pre-cf6e7c9 void-on-any-stray behaviour; does not establish the empirical frequency ("most cells") — no sweep has been run, so that is a projection.

The pre-cf6e7c9 behaviour is the surviving `verify_containment()` path, which still voids on any stray:

```python
# scripts/crb-materialize.py:185-188
    stray = sh(["git", "rev-list", "--all", "--not", head], cwd=dst)
    stray_n = len([l for l in stray.splitlines() if l])
    if stray_n:
        raise RuntimeError(f"{slug}: {stray_n} stray commit(s) reachable outside the reviewed head")
```
Confidence is Medium because the "most cells" frequency is unmeasurable before the sweep runs.

**Evidence:** `scripts/crb-materialize.py:185-188`, `scripts/crb-materialize.py:244-256`

---

## Claim 21: "Without this, the commits `reset_clone()` just discarded would read as `unreachable` on the NEXT cell's pre-run check and void a clean cell." (repeated as "Restore the object-store baseline LAST: the commits just discarded are unreachable now, and the next cell's `fetch_traces()` would read them as a deleted fetched ref and void a clean cell")

**Location:** `scripts/crb-materialize.py:266-270`, `scripts/crb-materialize.py:319-321`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stated causal mechanism for `scrub_object_store()`'s presence in `reset_clone()`; does **not** claim the call should be removed — it still serves `materialize()` (Claim 22) and makes object-store state deterministic.

Removing the `scrub_object_store(dst)` call from `reset_clone()` in a scratch copy does not produce the described failure: the next cell's pre-run check stays clean and passes.

```
# docs/reviews/execution-logs/fc2-order-and-scrub.txt
CLAIM3 WITHOUT scrub_object_store: NEXT cell pre-run traces -> []
CLAIM3 WITHOUT scrub_object_store: NEXT cell pre-run reset PASSED
```
The reason is that `git fsck` counts reflog entries as reachability roots by default, and the discarded agent commits remain in the branch reflogs:

```
# docs/reviews/execution-logs/fc2-order-and-scrub.txt (drv3.py)
logAllRefUpdates: true
fsck --unreachable --connectivity-only (default, reflogs count as roots):
    []
fsck --unreachable --connectivity-only --no-reflogs:
    ['unreachable blob …', 'unreachable commit 8e11f2c…', 'unreachable tree …']
```
Commands: `python3 drv2.py` and `python3 drv3.py`; cwd `/workspace/.scratch/fc2`; exit 0 both; 2026-08-19 03:12 UTC. Corroborating: the full `test/crb-containment-reset.bats` suite passes 15/15 against a copy of the module with that call removed (`docs/reviews/execution-logs/fc2-noscrub-bats.txt`).

A second consequence of the same ordering: because `fetch_traces()` raises on a present `FETCH_HEAD` earlier in `reset_clone()`, the `FETCH_HEAD.unlink()` inside `scrub_object_store()` is unreachable from the `reset_clone()` path.

**Evidence:** `docs/reviews/execution-logs/fc2-order-and-scrub.txt`, `docs/reviews/execution-logs/fc2-noscrub-bats.txt`, `scripts/crb-materialize.py:266-273`, `scripts/crb-materialize.py:319-322`

---

## Claim 22: "Also deletes `.git/FETCH_HEAD`, which THIS function's own fetches wrote. Deleting it here is what makes its later presence meaningful evidence to `fetch_traces()`"

**Location:** `scripts/crb-materialize.py:369-372`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `materialize()`'s own call to `scrub_object_store()` and the resulting clean baseline; does not establish that no other harness step writes `FETCH_HEAD`.

```python
# scripts/crb-materialize.py:271-273
    sh(["git", "reflog", "expire", "--expire=now", "--all"], cwd=dst)
    sh(["git", "gc", "--quiet", "--prune=now"], cwd=dst)
    (dst / ".git" / "FETCH_HEAD").unlink(missing_ok=True)
```
The scratch clones in every experiment above were built with `git clone --depth` + `git fetch … refs/…:refs/heads/review` (the same two fetches `materialize()` performs) followed by this scrub, and `fetch_traces()` returned `[]` on all of them before any attack was applied — confirming the baseline is genuinely clean (`docs/reviews/execution-logs/fc2-fetch-attacks.txt`, each scenario's `fresh()`).

**Evidence:** `scripts/crb-materialize.py:266-273`, `scripts/crb-materialize.py:369-372`, `docs/reviews/execution-logs/fc2-fetch-attacks.txt`

---

## Claim 23a: "descent is the weaker signal: a fetched commit copied on top of the head descends from it"

**Location:** `scripts/crb-materialize.py:294-296`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fact that the descent test alone does not flag a fetched-then-copied commit; does not cover the ordering conclusion (Claim 23b).

In scenario C, `classify_strays()` reports the agent's commit as a stray but **not** foreign:

```
# docs/reviews/execution-logs/fc2-fetch-attacks.txt
--- C: fetch, content committed on top of review, ref+FETCH_HEAD deleted
   strays: 1 foreign: 0
```

**Evidence:** `docs/reviews/execution-logs/fc2-fetch-attacks.txt`, `scripts/crb-materialize.py:244-249`

---

## Claim 23b: "Checked BEFORE the descent test … [otherwise the fetched commit] would otherwise pass as benign"

**Location:** `scripts/crb-materialize.py:294-296`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether the order of the trace check and the descent test changes `reset_clone()`'s verdict; does not evaluate whether the current order is preferable for other reasons (it does change which message is reported first).

Both checks raise, so neither short-circuits to a pass — reordering them changes the error text, not the verdict. Executed with a reordered copy of `reset_clone()` on the scenario-C fixture:

```
# docs/reviews/execution-logs/fc2-order-and-scrub.txt
CLAIM2 current order (traces first):    VOIDED -> … 1 unreachable commit(s) …
CLAIM2 swapped order (descent first):   VOIDED -> TRACES void: ['1 unreachable commit(s) …']
```
Command: `python3 drv2.py`; cwd `/workspace/.scratch/fc2`; exit 0; 2026-08-19 03:12 UTC. Accurate version: the trace check is what catches the fetched-commit-on-top case at all; its *position* relative to the descent test only determines which failure is reported.

**Evidence:** `docs/reviews/execution-logs/fc2-order-and-scrub.txt`, `scripts/crb-materialize.py:289-303`

---

## Claim 24: "run-host.sh calls this via `--reset`, which resets first and then asserts this; `--verify` is the read-only form for a human"

**Location:** `scripts/crb-materialize.py:174-175`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both run-host.sh call sites and the `--verify`/`--reset` branch in `main()`; does not establish that no other caller exists outside the repo.

```python
# scripts/crb-materialize.py:449-450
                note = reset_clone(dst, slug, head, base) if resetting else ""
                n_commits, stat = verify_containment(dst, slug, head)
```
`grep -rn -- "--verify"` across the repo (excluding `docs/reviews/`, `external/`, `.git`) returns only `docs/working/crb-direction1-setup.md:28`, the documented human-facing form; both run-host.sh call sites pass `--reset` (`run-host.sh:262`, `run-host.sh:359`) (paraphrased — no quote available because the claim covers the absence of other `--verify` call sites).

**Evidence:** `scripts/crb-materialize.py:174-175`, `scripts/crb-materialize.py:436-455`, `runs/review-arms/crb-pipeline/run-host.sh:262`, `runs/review-arms/crb-pipeline/run-host.sh:359`

---

## Claim 25: "[RUN_META is] Written by run-host.sh. The leaderboard reads it to tell 'we ranked on 3 PRs' apart from 'we asked for 5 and 2 fell out'"

**Location:** `scripts/crb_common.py:28-32`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the path constant matches the writer's output path and that the leaderboard defaults to it; does not establish that the file exists on disk today (it does not — no sweep has run).

```python
# scripts/crb_common.py:32
RUN_META = WORKSPACE / "runs/review-arms/crb-pipeline/run-meta.json"
```
The writer targets `"$OUT/run-meta.json"` with `OUT="$ROOT/runs/review-arms/crb-pipeline"` (`run-host.sh:54`, `run-host.sh:164`), and the reader defaults to the constant:

```python
# scripts/crb-subset-leaderboard.py:98-100
    ap.add_argument("--run-meta", default=str(RUN_META),
```

**Evidence:** `scripts/crb_common.py:28-32`, `runs/review-arms/crb-pipeline/run-host.sh:54`, `runs/review-arms/crb-pipeline/run-host.sh:164`, `scripts/crb-subset-leaderboard.py:98-100`

---

## Claim 26: "Attrition is always measured against the PRs OUR tool was judged on, even under `--all-prs` where the displayed subset is everything"

**Location:** `scripts/crb-subset-leaderboard.py:110-112`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the argument passed to `attrition()` under both scoping modes; does not establish the correctness of the per-slug reason strings.

```python
# scripts/crb-subset-leaderboard.py:113-114
    our_urls = sorted(u for u, tools in evals.items() if args.tool in tools)
    urls = sorted(evals) if args.all_prs else our_urls
```
and the call site passes `our_urls`, not `urls`:
```python
# scripts/crb-subset-leaderboard.py:169
    att_lines, _checked = attrition(our_urls, Path(args.run_meta))
```
Pinned by `attrition is reported under --all-prs too (subset scope is not the question)`, `ok` in the 36/36 run (command as Claim 2).

**Evidence:** `scripts/crb-subset-leaderboard.py:110-119`, `scripts/crb-subset-leaderboard.py:169`, `docs/reviews/execution-logs/fc2-bats.txt`

---

## Claim 27: "the load-bearing assertions here are the two negatives — a re-added remote and a commit outside the reviewed ancestry must still fail"

**Location:** `test/crb-containment-reset.bats:14-17`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both named negative cases exist and assert a void; does not establish that they are the *only* load-bearing assertions (the suite also carries three fetch-trace negatives added in 5bd0b09, which the header does not mention).

Both cases assert `status -eq 1` and a `VOID` output (`test/crb-containment-reset.bats:145-165`), and both are `ok` in the 36/36 run (command as Claim 2). The header sentence predates 5bd0b09's fetch-trace cases and so is now an incomplete list rather than a wrong one — the "Fetch traces" block at `:167-173` documents the additions in its own comment.

**Evidence:** `test/crb-containment-reset.bats:14-17`, `test/crb-containment-reset.bats:145-165`, `docs/reviews/execution-logs/fc2-bats.txt`

---

## Claim 28: "r1's exact attack: fetch by URL, delete the ref, commit on top — VOIDS … These tests pin the detection that replaced that claim"

**Location:** `test/crb-containment-reset.bats:167-200`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the fixture voids under the current module and passes under the cf6e7c9 module, i.e. that it pins a real regression; does not establish that the fixture is byte-identical to what replicate r1 built.

Same fixture, two modules:

```
# docs/reviews/execution-logs/fc2-old-vs-new.txt
=== mat-old.py                 OK: 1 agent commit(s) on top of the head, reset   exit=0
=== crb-materialize.py         VOID: fixture: FETCH_HEAD present … ; 1 unreachable commit(s) …   exit=1
```
Command: `bash .scratch/fc2/old_vs_new.sh`; cwd `/workspace`; exit 0; 2026-08-19 03:09 UTC. Note the fixture does not delete `FETCH_HEAD`, so it is caught by trace (a) alone; the harder variant (both deleted) is separately confirmed to void in Claim 18 scenario C but is not pinned by a test.

**Evidence:** `docs/reviews/execution-logs/fc2-old-vs-new.txt`, `test/crb-containment-reset.bats:186-200`

---

## Claim 29: "if `reset_clone` did not restore the object-store baseline, the commits it just discarded would read as 'unreachable' on the NEXT cell and void a clean cell. This is the test that the detection does not eat the benign case it was carved around."

**Location:** `test/crb-containment-reset.bats:212-227`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers whether this test pins the property its comment names; does not dispute that the test is a valid regression test for the benign consecutive-cells case in general.

The entire suite — including this case — passes against a copy of `crb-materialize.py` with `scrub_object_store(dst)` removed from `reset_clone()`:

```
# docs/reviews/execution-logs/fc2-noscrub-bats.txt
NOSCRUB ok 13 consecutive benign cells stay clean — reset restores the object baseline
NOSCRUB ok 15 a tag pointing outside the reviewed ancestry still VOIDS the cell
```
(15/15 `ok`, 0 `not ok`.) Command: `bash .scratch/fc2/scrubtest.sh`; cwd `/workspace`; exit 0; 2026-08-19 03:13 UTC. The comment's premise is the same one refuted in Claim 21: reflog entries keep the discarded commits reachable, so they never read as unreachable regardless of the scrub.

**Evidence:** `docs/reviews/execution-logs/fc2-noscrub-bats.txt`, `docs/reviews/execution-logs/fc2-order-and-scrub.txt`, `test/crb-containment-reset.bats:212-227`

---

## Claim 30: "The 32 result.json files already in runs/review-arms/ are used as fixtures … pinning the verdict on every one of them is what makes a future edit to the rules visible"

**Location:** `test/crb-cell-status.bats:15-19`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test enumerates every `result.json` under `runs/review-arms/` and asserts an exact split plus the three named bad cells; does not establish that the split would remain stable if new arms were added.

```bash
# test/crb-cell-status.bats:174-177
  [[ "$output" == *"complete=29 incomplete=3"* ]]
  [[ "$output" == *"mfc-hygiene/rep1"* ]]
  [[ "$output" == *"mfc-postfix/rep2"* ]]
  [[ "$output" == *"mfc-postfix/rep3"* ]]
```
over a `glob.glob(… "runs/review-arms/**/result.json", recursive=True)` sweep (`test/crb-cell-status.bats:159-160`). Independent measurement finds exactly 32 such files, of which those three are the budget-exhausted cell and the two quota stubs (`docs/reviews/execution-logs/fc2-corpus-measure.txt`); the case is `ok` in the 36/36 run (command as Claim 2).

**Evidence:** `test/crb-cell-status.bats:152-178`, `docs/reviews/execution-logs/fc2-corpus-measure.txt`, `docs/reviews/execution-logs/fc2-bats.txt`

---

## Claims Requiring Attention

### Incorrect
- **Claim 6** (`docs/working/crb-direction1-setup.md:132-134`): "an agent that also deletes FETCH_HEAD … defeats it" — deleting FETCH_HEAD alone still voids on the unreachable-commit check; defeating both git-local checks additionally requires `reflog expire --expire=now --all` + `gc --prune=now`. Fix: name the full three-step cover-up, or drop the specificity and keep only the "clones elsewhere / egress is the real control" point.
- **Claim 19b** (`scripts/crb-materialize.py:233-235`, `test/crb-containment-reset.bats:229-231`): `--connectivity-only` is not what keeps `git fsck` quiet on a shallow clone — fsck is equally quiet without it. Fix: keep the cost rationale, drop the shallow-boundary rationale; and either make the shallow test assert something the flag actually changes, or reword its header.
- **Claim 21** (`scripts/crb-materialize.py:266-270` and `:319-321`): `scrub_object_store()`'s stated reason for existing in `reset_clone()` is refuted — `git fsck` counts reflogs as reachability roots, so the discarded commits never read as unreachable. Fix: restate the reason (deterministic object-store baseline; the `materialize()` FETCH_HEAD deletion at `:369-372` is the genuinely load-bearing use). Also note the `FETCH_HEAD.unlink()` is unreachable from the `reset_clone()` path because `fetch_traces()` raises first.
- **Claim 23b** (`scripts/crb-materialize.py:294-296`): "Checked BEFORE the descent test … would otherwise pass as benign" — both checks raise, so the order changes the reported message, not the verdict. Fix: say the trace check is what catches this shape at all, and that its position only determines which failure is named.
- **Claim 29** (`test/crb-containment-reset.bats:212-227`): the test's comment claims it pins the object-store-baseline restoration; the whole suite passes with `scrub_object_store()` removed from `reset_clone()`. Fix: reword the comment to what the test does pin (consecutive benign cells stay clean), or add an assertion that actually fails without the scrub.

### Stale
- None.

### Mostly Accurate
- **Claim 14b** (`scripts/crb-cell-status.py:51-52`): "20 of the 32 bodies sit between 1.2 and 3.0 KB" — measured count is 22 (decimal) / 21 (KiB). Tighten to 22. Adjacent to a logged hallucination pattern but off by 2, not by an order of magnitude; the load-bearing 1,208 in the same comment is correct.
- **Claim 27** (`test/crb-containment-reset.bats:14-17`): "the two negatives" is now an incomplete list — 5bd0b09 added three fetch-trace negatives that are equally load-bearing. Tighten to "the negatives".

### Verified, with a scope caveat worth carrying
- **Claim 5** (`docs/working/crb-direction1-setup.md:127`): true as written for merge-commit merges; worth adding that squash/rebase merges produce an upstream commit that does *not* descend from the head, so descent is an unreliable benign signal in both directions.

### Unverifiable
- **Claim 19a** (`scripts/crb-materialize.py:233-234`): the "cheap on 33-195 MB clones" cost claim needs a materialized CRB clone, which requires network access this sandbox does not have. Verify by timing `git fsck --unreachable` with and without `--connectivity-only` on a real clone.

---

## Goal-Alignment Note
- Answered: yes — all 11 requested claim areas checked, 8 of them by execution.
- Out of scope: R3 (container egress / `--dangerously-skip-permissions`) — a security-design finding, not a documentation-accuracy one, and already tracked on the branch rubric; code-quality judgements on the harness.
- Escalate: Claim 21 and Claim 29 together mean the `scrub_object_store()` call inside `reset_clone()` has no test and no correct stated rationale — the orchestrator should decide whether it stays (with a corrected comment) or the guard is strengthened to `--no-reflogs`, which would make the stated mechanism real. Claim 19b means the shallow-clone false-positive risk the comment worries about is not actually pinned by any test. Neither is blocking for the sweep: the shipped guard voids every attack shape tested.
