# Test Strategy: CRB direction-1 harness, review-fix iteration 2

**Scope:** `git diff 59733d8..HEAD -- . ':!docs/reviews'` — commits cf6e7c9, 5bd0b09, 46a5f17
**Under test:** `test/crb-cell-status.bats`, `test/crb-containment-reset.bats`, `test/crb-subset-attrition.bats` and the sources they pin (`scripts/crb-cell-status.py`, `scripts/crb-materialize.py`, `scripts/crb-subset-leaderboard.py`, `runs/review-arms/crb-pipeline/run-host.sh`)
**Reviewed:** 2026-08-18
**Method:** read + 30 source mutations executed against a scratch copy at `/workspace/.scratch/ts-mut` (repo never modified)

All findings are **advisory (Consider tier)** unless explicitly marked otherwise. Two are marked
`Soundness-Contradiction` because a comment in the diff asserts something the same diff's other
comment measures as false, and because a named guard is provably not held by the test that claims
to hold it.

---

## Test Conventions

- **Framework:** bats, one `.bats` file per concern in `test/`, discovered by `scripts/run-tests.sh`
  via a mandatory `# @category fast|slow` header comment. All three new suites are tagged `fast`
  and are picked up correctly.
- **Hermeticity (decision 017):** tmpdir-only writes (`BATS_TEST_TMPDIR`), no network, no mutation
  of tracked files. All three suites comply on writes. Two of them *read* mutable checked-in
  artifacts (`runs/review-arms/**/result.json`, `runs/review-arms/crb/instances.json`) — see G1/G2.
- **Python-under-test:** the repo has no pytest harness; python is exercised from bats either by
  CLI invocation or by `importlib.util.spec_from_file_location` + direct function call. Both
  patterns pre-exist; the inconsistency is not novel, but where it lands matters (G3).
- **Style:** long "why this exists" header comments naming the pre-mortem narrative each suite
  closes. Good practice, and the source of one of the defects below (a header comment that is
  factually contradicted by the source it guards).

---

## Mutation results — the requested deliverable

30 mutations applied one at a time to a scratch copy; all 38 tests re-run per mutation.
**22 caught, 10 missed.** Missed mutations, worst first:

| # | Mutation | Result | Why it matters |
|---|---|---|---|
| M31 | `crb-materialize.py:489` — `note = reset_clone(...) if resetting else ""` → `note = ""` (i.e. `--reset` no longer resets) | **MISSED — 38/38 green** | The entire CLI surface `run-host.sh` actually calls is uncovered. G4 |
| M18 | `crb-cell-status.py:62` — `STUB_MAX_LEN = 300` → `1000` (verbatim the cf6e7c9 bug that all three k=3 replicates caught) | **MISSED** | The suite's own headline regression is re-introducible silently. G5 |
| M32 | `crb-materialize.py:482` — drop the `resetting and not base` guard | MISSED | New error branch, zero coverage. G6 |
| M4 | `crb-materialize.py:261` — delete the `git fsck` error-trace check | MISSED | Test 15 asserts only the *heal*, never the *detect*. G7 |
| M23 | `crb-cell-status.py:98` — delete the non-dict guard | MISSED | Test asserts exit 1; an uncaught traceback is also exit 1. G8 |
| M29 | `crb-subset-leaderboard.py:69` — delete the "no cell produced" reason branch | MISSED | The pre-run-containment-failure / missing-clone drop is never exercised. G9 |
| M5 | `crb-materialize.py:329-331` — delete `reset_clone`'s remote VOID | MISSED | Verdict is still VOID (held by `verify_containment`), so the *behaviour* is safe; the *named* guard is not pinned. G10 |
| M8 | `crb-materialize.py:349` — delete `git reset --hard` | MISSED | Provably redundant with `checkout --force -B`; the comment claims it is what fixes staged edits. G11 |
| M15 | `crb-materialize.py:312` — delete the `FETCH_HEAD.unlink()` in `scrub_object_store` | MISSED | Unreachable from the reset path (a fetch raises first); load-bearing only in `materialize()`, which has no tests. G12 |
| M14 | `crb-materialize.py:247` — drop `--connectivity-only` | MISSED | Benign (perf flag) — but the bats comment claims it is what keeps fsck quiet on shallow clones, which `crb-materialize.py:243-245` measures as false. G13 |

Caught (22, no action needed): FETCH_HEAD presence check; `--no-reflogs` removal; unreachable-commit
check removal; foreign-commit VOID removal; `git clean -x`; ref-pruning loop; `main` restore;
`scrub_object_store` call removal; dangling-symref heal; `STUB_MAX_LEN → 100000`; length-floor
removal; `is_error`; `subtype`; `NON_REVIEW` list removal and partial truncation; voided-reason
branch; `our_urls` → `urls`; markdown attrition block; silent missing-run-meta; stderr attrition
emission; `classify_strays` neutering; dirty-path note.

The suite is, on the whole, **not vacuous** — 22/30 is a good mutation score for hand-written
guards, and the two negative-control tests (re-added remote, foreign commit) plus the explicit
`scrub_object_store` non-vacuity test do real work. The misses cluster in one place: **the CLI /
wiring layer that production actually invokes**, as opposed to the library functions.

---

## Untested Paths Touched by the Change

### G1 — corpus pin breaks on the first cell of the sweep it guards
- **Severity:** High (advisory)
- **Location:** `test/crb-cell-status.bats:152-178`
- **Evidence:**
  ```
  for p in sorted(glob.glob(os.path.join(root, "runs/review-arms/**/result.json"),
                            recursive=True)):
  ...
  [[ "$output" == *"complete=29 incomplete=3"* ]]
  ```
  and `runs/review-arms/crb-pipeline/run-host.sh:54`:
  ```
  OUT="$ROOT/runs/review-arms/crb-pipeline"
  ```
  `runs/review-arms/crb-pipeline/` is **not** in `.gitignore` (`git check-ignore` → not ignored).
- **Reproduced:** wrote one synthetic `runs/review-arms/crb-pipeline/<slug>/result.json` into the
  scratch copy; test 32 fails immediately (`complete=29 incomplete=3` no longer matches).
- **Answering the direct question — good test or brittle?** *Both, and the brittleness is fatal in
  this specific layout.* The idea (pin verdicts on the corpus the rules were derived from) is right
  and it is the only test that would catch a rule change moving a real cell across the line. The
  execution couples a hard-coded count to a directory the harness under test writes into. The
  first `$10-40` cell of the real sweep turns this suite red, and a red suite during a live sweep
  is a suite people start ignoring — exactly when the predicate's verdicts matter most.
- **Fix (cheap):** restrict the glob to the fixed historical arms (`runs/review-arms/e*/`,
  `mfc-*`, `fc-model-sweep`, …) or exclude `crb-pipeline/`; better, assert the split *per known
  path* (the three named INCOMPLETE files, plus "no other file is INCOMPLETE") rather than a total
  count, so adding cells is not a failure but a *new* incomplete cell is.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G2 — attrition suite breaks when the manifest grows past 5 (i.e. at `--all`)
- **Severity:** Medium (advisory)
- **Location:** `test/crb-subset-attrition.bats:22, 68-99`
- **Evidence:**
  ```
  export MANIFEST="$REPO_ROOT/runs/review-arms/crb/instances.json"
  ...
  [[ "$output" == *"5 PR(s)"* ]]
  [[ "$output" == *"SUBSET ATTRITION: 2 of 5"* ]]
  ```
  The manifest currently holds 5 entries; the setup doc's target is 50.
- **Reproduced:** added 6 synthetic manifest entries in the scratch copy → tests 1, 2 and 4 fail.
- **Fix:** synthesize the manifest in `BATS_TEST_TMPDIR` and point the script at it, or derive the
  expected counts from `len(manifest)` instead of literals. The header comment defends reading the
  real manifest as "the same coupling the script has in production" — true for the *mapping*, not
  for the *cardinality*.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G3 — importlib vs CLI: the inconsistency is only harmful where it hides the wiring
- **Severity:** Medium (advisory) — this is the direct answer to the third question asked
- **Location:** `test/crb-containment-reset.bats:47-61` (importlib only);
  `test/crb-cell-status.bats:29-33` (CLI) vs `:152-170` (importlib);
  `test/crb-subset-attrition.bats:62-66` (CLI only)
- **Assessment:** the inconsistency per se is harmless — `crb-cell-status.bats` deliberately uses
  CLI for exit-code semantics and importlib for the bulk corpus sweep, which is the right split.
  It becomes harmful in exactly one place: `crb-containment-reset.bats` never invokes
  `crb-materialize.py --reset` at all, so `main()`'s reset wiring is untested (G4, G6), while
  `run-host.sh` calls **only** that path. Secondary cost: the corpus-pin harness re-implements
  `main()`'s `unreadable` handling (`except Exception: incomplete.append((p, "unreadable"))`)
  rather than calling it, so the two can drift.
- **Confidence:** High
- **Legibility-target:** for-orchestrator-synthesis

### G4 — `crb-materialize.py:489` — `--reset` branch that calls `reset_clone` — not covered
- **Severity:** High (advisory); this is the mutation the requester most wanted found
- **Evidence:**
  ```python
  note = reset_clone(dst, slug, head, base) if resetting else ""
  n_commits, stat = verify_containment(dst, slug, head)
  ```
  Replacing the first line with `note = ""` leaves all 38 tests green. The harness would then
  behave as if `run-host.sh` still called `--verify`, i.e. the entire fix in cf6e7c9 would be
  inert while the suite reports success.
- **Blast radius:** every cell of the sweep starts from an un-reset clone; agent commits accumulate;
  the first cell's commit voids every subsequent cell of that slug (the exact pre-mortem narrative-1
  failure). Silent — voided cells only show up as attrition in the leaderboard.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G5 — `crb-cell-status.py:62,82` — the 300–1000 char band — not covered
- **Severity:** High (advisory)
- **Evidence:**
  ```python
  STUB_MAX_LEN = 300
  ...
  if len(r) < STUB_MAX_LEN:
      low = r.lower()
      hit = next((s for s in NON_REVIEW if s in low), None)
  ```
  Every "long review" test in the suite builds a body of ~2,600–3,000 chars
  (`test/crb-cell-status.bats:56-57`, `64-65`, `46-48`). Nothing sits between the 300 floor and
  ~2.6 KB, so reverting `STUB_MAX_LEN` to its cf6e7c9 value of 1000 — the defect all three k=3
  replicates independently caught, and the reason this file's longest comment exists — passes the
  suite unchanged.
- **Cost model:** a 400–900 char genuine review of an auth PR (two of five pilot instances are
  auth-domain) is judged incomplete → re-paid at $10-40 → dropped at `MAX_ATTEMPTS` → the PR leaves
  the judged subset. That is precisely the biasing failure narrative 5 describes.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G6 — `crb-materialize.py:482` — `resetting and not base` error branch — not covered
- **Severity:** Low-Medium (advisory)
- **Evidence:** `if not head or (resetting and not base):` — no manifest entry currently lacks
  `base` (checked: 0 of 5), so the branch is unreachable from the real manifest and only fires on a
  partially-written or hand-edited manifest. Removing the `resetting and not base` clause leaves
  38/38 green; `reset_clone(dst, slug, head, None)` would then run `git branch -f main None`.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G7 — `crb-materialize.py:261-264` — the `git fsck` error trace — not covered
- **Severity:** Medium (advisory)
- **Evidence:** the test that names this behaviour asserts only the second half of it —
  `test/crb-containment-reset.bats:265-279`:
  ```
  @test "a dangling origin/HEAD symref is detected, and scrub heals it" {
  ...
  print("BEFORE:", m.fetch_traces(dst))
  ...
  [[ "$output" == *"AFTER: []"* ]]
  ```
  `BEFORE:` is printed and never asserted. I ran `fetch_traces` on that fixture directly: it
  returns `['git fsck reported 1 error(s), first: error: refs/remotes/origin/HEAD: invalid sha1
  pointer … — cannot certify containment']`, so the detection is real — just unpinned. Deleting
  `if errors:` leaves 38/38 green.
- **Why it matters:** this check is the "a containment check that silently could-not-run" guard.
  Its failure mode is *inverted* from the rest: if it stops firing, contamination goes unreported;
  if it over-fires, every cell of a $50-2000 sweep voids. Both directions deserve a pin.
- **Fix:** one added line — `[[ "$output" == *"BEFORE:"*"fsck reported"* ]]`. Verified this would
  catch M4.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G8 — `crb-cell-status.py:98-100` — non-dict guard — asserted vacuously
- **Severity:** Low (advisory)
- **Evidence:** `test/crb-cell-status.bats:145-148`
  ```
  @test "a JSON array (not an object) is rejected, not crashed on" {
    check '[]'
    [ "$status" -eq 1 ]
  }
  ```
  A raw `AttributeError` traceback also exits 1, so the "not crashed on" half is unasserted; the
  guard can be deleted with the suite green. The sibling test at `:139-143` gets this right by
  asserting `*unreadable*`.
- **Fix:** `[[ "$output" == *"not an object"* ]]`.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G9 — `crb-subset-leaderboard.py:69-72` — the `missing_cells` and unmapped-slug reasons — not covered
- **Severity:** Medium (advisory)
- **Evidence:**
  ```python
  elif slug not in cells:
      why = "no cell produced (missing clone, or pre-run containment failure)"
  elif not url:
      why = f"not in {MANIFEST.name} — cannot map the slug to a PR"
  ```
  `make_run_meta` (`test/crb-subset-attrition.bats:47-60`) always emits a `cells` entry for every
  requested slug, so `slug not in cells` never holds in any test. Deleting the branch is green.
- **Cost model:** this is the *highest-signal* attrition class — a slug that never produced a cell
  is a pre-run containment failure or a missing clone, i.e. a systematic harness fault, not a
  per-PR one. Mis-attributing it to "ran, but has no judged row" would send the reader looking at
  the reviewer instead of the harness.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G10 — `crb-materialize.py:329-331` — `reset_clone`'s own remote VOID — not pinned by the test that claims it
- **Severity:** Low (advisory) — behaviour is safe, the label is wrong
- **Tier:** `Soundness-Contradiction` on the test's stated claim
- **Evidence:** `test/crb-containment-reset.bats:14-17` says "the load-bearing assertions here are
  the two negatives — a re-added remote and a commit outside the reviewed ancestry must still
  fail". Deleting `reset_clone`'s remote check leaves test 9 ("a re-added remote still VOIDS the
  cell") **passing**, because `reset_and_verify` also calls `verify_containment`, whose identical
  check at `crb-materialize.py:189-191` fires. The verdict is preserved; the layer is not.
- **Why it is not zero:** with `reset_clone`'s check gone, the reset runs *first* — discarding the
  agent's commits and `gc --prune=now`-ing the objects — and only then does `verify_containment`
  void. The cell is still voided, but the forensic evidence of what the agent did is destroyed
  before anyone can look at it. That ordering is deliberate in the source (`# Checked before the
  descent test so the VOID message names the fetch`) and worth an explicit test.
- **Fix:** assert the reason string is `reset_clone`'s (`*"answer-key containment is broken"*`
  before the reset happens), or call `reset_clone` alone in one dedicated test.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G11 — `crb-materialize.py:349` — `git reset --hard` is redundant; its comment says otherwise
- **Severity:** Low (advisory)
- **Tier:** `Soundness-Contradiction` (comment vs measured behaviour)
- **Evidence:**
  ```python
  # -B moves `review` back onto the pinned head from wherever HEAD now is;
  # --force discards worktree state; the explicit reset --hard then guarantees
  # the index matches too (a staged edit is what `checkout -- .` used to keep).
  sh(["git", "checkout", "--force", "--quiet", "-B", "review", head], cwd=dst)
  sh(["git", "reset", "--hard", "--quiet", head], cwd=dst)
  ```
  Deleting the `reset --hard` line leaves all 38 green, including "a staged edit to a tracked file
  is undone" — because `git checkout --force -B` already rewrites the index. The comment credits
  the wrong line for the fix.
- **Recommendation:** keep the line (belt-and-braces on a $50-2000 run is cheap), fix the comment
  to say so, or drop it. Do not leave a comment asserting a causal role the code does not have —
  this is the same class as the two prior findings this loop already produced.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G12 — `materialize()` has no test at all; `FETCH_HEAD` deletion at materialize time is the premise of check (a)
- **Severity:** Medium (advisory)
- **Location:** `scripts/crb-materialize.py:312` (`unlink`), `:414-417` (the `scrub_object_store`
  call inside `materialize()`)
- **Evidence:** `fetch_traces` docstring: *"materialize() deletes it after its own fetches so its
  later presence is meaningful."* Deleting the `unlink` leaves 38/38 green, because in the reset
  path a present `FETCH_HEAD` raises before `scrub_object_store` is ever reached — the unlink is
  only load-bearing in `materialize()`, which no test exercises. If it ever regressed, **every**
  cell of the sweep would void on a leftover `FETCH_HEAD` from materialization.
- **Feasible to test hermetically:** yes — `materialize()` clones from a URL, and a local
  `file://$BATS_TEST_TMPDIR/upstream` repo is a URL. The suite already builds one
  (`make_answer_key_repo`).
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G13 — `test/crb-containment-reset.bats:282-284` — the shallow test's stated premise is contradicted by the source it guards
- **Severity:** Low (advisory)
- **Tier:** `Soundness-Contradiction`
- **Evidence:** test comment:
  ```
  # Real clones are SHALLOW (--depth 50). git fsck on a shallow repo can complain
  # about the grafted boundary; --connectivity-only is what keeps it quiet.
  ```
  same-diff source comment, `scripts/crb-materialize.py:243-245`:
  ```python
  # --connectivity-only skips object content validation; on a 33-195 MB clone
  # that is the expensive half. (It is NOT what keeps fsck quiet on a shallow
  # clone — measured: fsck is equally quiet on a --depth=1 clone without it.)
  ```
  Confirmed by mutation: removing `--connectivity-only` leaves the shallow test green. The *test*
  is still worth keeping (it pins "no false-positive void on a shallow clone", which is the real
  risk); only its comment is wrong.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G14 — `scripts/crb-materialize.py:236-241` — "FETCH_HEAD removed but objects left unreachable" — not covered
- **Severity:** Medium (advisory)
- **Evidence:** the docstring makes a specific security claim —
  *"Defeating both checks requires removing FETCH_HEAD **and** expiring the reflogs **and** running
  `gc --prune=now` — deleting FETCH_HEAD alone still voids."* No test exercises "delete FETCH_HEAD
  alone". Mutation M1 (removing the FETCH_HEAD check) was caught by only one test, and M3
  (removing the unreachable-commit check) by only the indirect non-vacuity test — meaning the two
  checks currently cover each other's fixtures rather than each having its own.
- **Confidence:** High (executed)
- **Legibility-target:** for-author

### G15 — `runs/review-arms/crb-pipeline/run-host.sh:159-224` — `write_run_meta` — not covered, and it is the producer of the schema the attrition suite consumes
- **Severity:** Medium (advisory) — this is the answer to the "untestable under docker" question
- **Evidence:** no bats file references `run-host.sh` (`rg -l 'run-host.sh' test/` → only
  `crb-subset-attrition.bats`, and only in a comment). The attrition suite builds its own
  `run-meta.json` with `requested_instances` / `cells` / `voided_cells`; `write_run_meta` emits
  those keys at `run-host.sh:206-212`. Nothing checks the two agree. A producer-side rename passes
  every test and the leaderboard then reports "attrition NOT checked" or, worse, silently reports
  zero attrition.
- **What is genuinely docker-bound vs merely entangled:**
  - *Docker-bound (do not test):* the `docker run` cell invocation, the preflight container, the
    npm-cache chown.
  - *Not docker-bound, currently untested:* `write_run_meta` (pure python over a directory tree);
    the `SWEEP_BUDGET` aggregate gate at `:404-429` (pure python over `attempts.jsonl`); the
    `MAX_ATTEMPTS` counting at `:238-252` (pure bash, and it carries a scar comment about a
    `grep -c` bug that already bit once); the artifact-harvest traversal guard at `:324-344` (pure
    bash + `git status`, and it is the security control for untrusted third-party paths).
  - *The specific behaviour cf6e7c9 added and nothing pins:* run-meta is now written **from an EXIT
    trap** so that the `SWEEP_BUDGET` `exit 2` (which happens *inside* the loop) still produces
    provenance. That is the fix's whole point and it has no test.
- **Confidence:** High
- **Legibility-target:** for-orchestrator-synthesis

### G16 — `scripts/crb-subset-leaderboard.py:87` — the `checked` return value is discarded
- **Severity:** Low (advisory)
- **Evidence:** `att_lines, _checked = attrition(our_urls, Path(args.run_meta))` — `_checked` is
  never read. The "not checked" state reaches the reader only as prose inside `att_lines`, so a
  future caller (e.g. an automated gate on the results doc) has no machine-readable signal.
  Test 6 pins the prose, which is the right thing given the current design, but the dead return
  value invites a false assumption that the state is available.
- **Confidence:** High
- **Legibility-target:** for-author

---

## Recommended Tests

#### T1 — Pin the 300–1000 char band with an auth-domain review
**Closes gaps:** G5
**Type:** unit · **Priority:** high
**File:** `test/crb-cell-status.bats`
**What it verifies:** a genuine but short review of auth code is COMPLETE, so `STUB_MAX_LEN` cannot
drift back up without a red test.
**Key cases:**
- 450-char body containing `"logged in"` → exit 0 (would fail at `STUB_MAX_LEN=1000`)
- 950-char body containing `"log in"` → exit 0
- exactly 299-char body containing `"log in"` → exit 1, reason `non-review stub`
- exactly 300-char body containing `"log in"` → exit 0 (boundary, pins the `<` vs `<=`)
**Setup needed:** none beyond the existing `check` helper.

#### T2 — Drive `crb-materialize.py --reset` through the CLI
**Closes gaps:** G4, G6, G3
**Type:** integration · **Priority:** high
**File:** `test/crb-containment-reset.bats`
**What it verifies:** the path `run-host.sh` actually invokes resets, verifies, and reports.
**Key cases:**
- agent commit present → `--reset <slug>` exits 0, stdout contains `containment ok` **and**
  `[1 agent commit(s) …]`, and `git rev-parse review == $HEAD_SHA` afterwards (catches M31)
- re-added remote → exits non-zero, stderr `CONTAINMENT CHECK FAILED`
- manifest entry with `head` but no `base` → exits non-zero with the "cannot pin" message
  (catches M32)
**Setup needed:** the script resolves `DST_ROOT` and `MANIFEST` from module constants, so this
needs either a `--clones-root`/env override or a temporary manifest + clone dir. Adding one env
override to `crb-materialize.py` is the smaller change and makes the whole CLI testable. This is
the single highest-value item in the plan.

#### T3 — Assert the *detection* half of the fsck-error check
**Closes gaps:** G7
**Type:** unit · **Priority:** high (one line)
**File:** `test/crb-containment-reset.bats:265-279`
**What it verifies:** `fetch_traces` reports a non-clean fsck rather than silently passing.
**Key cases:** add `[[ "$output" == *"BEFORE:"*"fsck reported"*"cannot certify containment"* ]]`.
Verified this catches M4.

#### T4 — De-brittle the corpus pin
**Closes gaps:** G1
**Type:** snapshot · **Priority:** high
**File:** `test/crb-cell-status.bats:152-178`
**What it verifies:** the predicate's verdict on the historical corpus, without breaking when the
sweep writes new cells.
**Key cases:**
- exclude `runs/review-arms/crb-pipeline/` from the glob (or list the historical arm dirs)
- assert the INCOMPLETE **set** equals exactly the three named paths, rather than a total count
- keep a `complete >= 29` lower bound so a rule change that mass-rejects still fires
**Setup needed:** none.

#### T5 — Contract test between `write_run_meta` and `attrition`
**Closes gaps:** G15, G9
**Type:** contract · **Priority:** high
**File:** new `test/crb-run-meta.bats`
**What it verifies:** the JSON `run-host.sh` writes is the JSON the leaderboard reads.
**Key cases:**
- build a fake `$OUT` tree (two cells with `result.json` + `attempts.jsonl`, one with
  `CONTAINMENT_FAILED`, one requested slug with **no** directory at all), source the
  `write_run_meta` function out of `run-host.sh`, run it, then feed the produced `run-meta.json`
  straight into `crb-subset-leaderboard.py`
- assert the missing slug is reported as `no cell produced` (closes G9 with the *real* producer)
- assert the `CONTAINMENT_FAILED` cell is reported as `voided by a post-run containment failure`
- assert `cost_usd` sums over `attempts.jsonl`, not over `result.json`
**Setup needed:** `run-host.sh` currently does all its work at top level; extracting the two python
heredocs (`write_run_meta`, the sweep-budget gate) into `scripts/` — as cf6e7c9 already did for the
cell-status predicate — is the pattern to repeat. Alternatively source the function with the
top-level body guarded, but extraction is cleaner and consistent with this diff's own precedent.

#### T6 — `materialize()` end-to-end against a `file://` upstream
**Closes gaps:** G12
**Type:** integration · **Priority:** medium
**File:** `test/crb-containment-reset.bats` (or a new `crb-materialize.bats`)
**What it verifies:** the post-materialize baseline that every later check assumes.
**Key cases:** materialize from a local `file://` repo with two branches and a tag → afterwards
`git remote` is empty, refs are exactly `refs/heads/{review,main}`, `.git/FETCH_HEAD` does not
exist, and `fetch_traces()` returns `[]`.
**Setup needed:** the same env override as T2 for `DST_ROOT`; a local bare repo as the "fork".

#### T7 — FETCH_HEAD deleted, objects left behind
**Closes gaps:** G14
**Type:** integration · **Priority:** medium
**File:** `test/crb-containment-reset.bats`
**What it verifies:** the docstring's stated bar — that removing FETCH_HEAD alone does not defeat
containment.
**Key cases:** fetch by URL into `refs/heads/stolen`, `update-ref -d` it, `rm .git/FETCH_HEAD`,
then `reset_and_verify` → VOID with `unreachable` in the reason. Gives check (b) a fixture of its
own instead of relying on check (a).

#### T8 — Synthesize the manifest in the attrition suite
**Closes gaps:** G2
**Type:** unit · **Priority:** medium
**File:** `test/crb-subset-attrition.bats`
**What it verifies:** attrition arithmetic, independent of how many PRs are currently materialized.
**Key cases:** write a 5-slug manifest into `BATS_TEST_TMPDIR`, point the script at it
(needs a `--manifest` flag or an env override on `crb_common.MANIFEST`), and keep the existing
assertions. Second case: 50-slug manifest, 3 judged → `SUBSET ATTRITION: 47 of 50`.

#### T9 — Assert the reason, not just the verdict, on the two negative controls
**Closes gaps:** G10, G8
**Type:** unit · **Priority:** medium (two lines each)
**File:** `test/crb-containment-reset.bats:145-151`, `test/crb-cell-status.bats:145-148`
**What it verifies:** that the named guard, not a downstream one, produced the refusal.
**Key cases:** call `reset_clone` alone (no `verify_containment`) in the remote test and assert
`answer-key containment is broken`; assert `not an object` in the JSON-array test.

#### T10 — Sweep-budget gate and MAX_ATTEMPTS counting
**Closes gaps:** G15 (partial)
**Type:** unit · **Priority:** medium
**File:** new `test/crb-run-meta.bats`
**What it verifies:** the two cost controls that stand between this harness and an unbounded bill.
**Key cases:**
- `attempts.jsonl` with 3 lines totalling $260 against `SWEEP_BUDGET=250` → gate exits 1
- a cell dir with `result.json` but no `attempts.jsonl` (pre-ledger) → its `total_cost_usd` counts
- empty `attempts.jsonl` → `attempts=0`, cell is retried (the `grep -c` scar at `run-host.sh:239`)
- `attempts.jsonl` with `MAX_ATTEMPTS` lines → cell skipped, `skipped_bad` incremented
**Setup needed:** extraction of the gate heredoc into `scripts/`, as in T5.

---

## What NOT to Test

- **The `docker run` cell invocation, the preflight container, and the npm-cache chown**
  (`run-host.sh:113-131`, `:274-287`). Genuinely host/docker-bound, and the existing repo
  convention (E5/E7 arms) is that these are exercised by running the arm, not by tests. Mocking
  docker here would test the mock.
- **`--connectivity-only`** (G13). It is a performance flag with no behavioural contract; fix the
  comment, do not add a test.
- **`git reset --hard`** (G11). Provably redundant. Do not write a test to pin a line that has no
  effect — fix the comment or delete the line.
- **`crb-cell-status.py`'s `main()` usage/argv error** (`:91-92`). Trivial, single branch,
  no cost consequence.
- **The `elif not url` branch** in `attrition` (`crb-subset-leaderboard.py:71`) beyond what T5
  covers incidentally — it requires a run-meta and manifest that disagree, which the T5 fixture
  produces for free but which is not worth its own test.
- **`fetch_traces`' behaviour under a hostile agent that clones elsewhere in the container.** The
  docstring already says this is out of reach of anything git-local; the control is the egress
  allowlist (tracked as R3). A test here would encode a false sense of coverage.

---

## Coverage Gaps Beyond Current Scope

**1.** `run-host.sh`'s artifact-harvest loop (`:324-344`) is the only place third-party,
agent-influenced path strings cross onto the host filesystem, and the traversal guard
(`case "$f" in /*|*..*)`) has no test. It is pure bash over `git status --porcelain -z` output and
is straightforwardly testable in a tmpdir repo. Highest-risk untested code in the arm that this
diff did not touch.

**2.** The post-VOID state transition is undocumented and untested: when post-run `--reset` raises,
`reset_clone` raises *before* restoring anything, so the clone stays contaminated and every later
cell for that slug fails its pre-run check. That is probably the right quarantine semantics, but
nothing states it and nothing pins it — and it interacts with `MAX_ATTEMPTS` to silently and
permanently drop a PR from the judged subset.

**3.** `verify_containment` (`:171-196`) predates this diff and has no direct test; the new suite
exercises it only as the second half of `reset_and_verify`. Its remote check is currently what
makes the G10 mutation harmless, which means an untested function is load-bearing for a tested one.

**4.** No test asserts that a containment-voided `result.json` (rewritten with
`is_error=true, subtype=containment_failed` at `run-host.sh:362-371`) is judged INCOMPLETE by
`crb-cell-status.py`. The two were written in the same commit and the coupling is real: if the
predicate ever stopped honouring `is_error`, a voided cell would be banked as complete and shipped
to the judge. `crb-cell-status.bats` test 9 covers `is_error` generically but not this subtype.

---

## Summary

The three new suites are substantially better than vacuous: 22 of 30 source mutations were caught,
the two "must still VOID" negative controls do real work, and the explicit `scrub_object_store`
non-vacuity test (46a5f17) is exactly the right response to the earlier vacuity finding. The
misses cluster in one identifiable place — **the CLI and wiring layer that production actually
calls**. The single highest-value test to add is **T2**: `crb-materialize.py --reset` can be made a
no-op and all 38 tests stay green, which would silently revert the entire cf6e7c9 fix while the
suite reports success. Close behind is **T1**: reverting `STUB_MAX_LEN` from 300 to 1000 — the
exact defect three fact-check replicates caught — is also invisible to the suite, because every
"long review" fixture is ~2.6 KB and nothing occupies the 300–1000 band the constant governs. On
the corpus-pin question: the idea is sound but the execution is fatally brittle in this layout —
`runs/review-arms/crb-pipeline/` is both the glob's search space and the sweep's output directory,
so the first paid cell turns the suite red (reproduced). The main residual risk after this plan is
`run-host.sh` itself: `write_run_meta` produces the schema `attrition` consumes, neither side is
tested against the other, and the EXIT-trap behaviour that cf6e7c9 added specifically so a
budget halt still yields provenance has no test at all. The open question the enumeration surfaced
is whether the post-VOID quarantine (gap 2 above) is intended permanent exclusion or an
oversight — that decision changes whether attrition from a contaminated clone is a bug or a
feature.

---

## Goal-Alignment Note
- **Answered:** yes — mutation-tested all three suites; 10 missed mutations listed with reproduction
- **Out of scope:** the docker-bound cell invocation and preflight (correctly untestable on the
  host); `docs/human-author/LLM Code Review.md` and `docs/working/crb-direction1-setup.md`
  (documentation, no test surface); pre-existing suites outside the diff
- **Escalate:** (a) G1 — the corpus pin will go red on the first paid cell of the sweep; decide
  before spending, not during. (b) G4/G5 — two silent-revert holes in the highest-cost controls;
  both are cheap to close and worth closing before the sweep. (c) Coverage gap 2 — the post-VOID
  quarantine semantics need a decision, not a test.
