# Test Strategy: CRB direction-1 harness — egress allowlist + disposable clones (197eec6)

**Scope:** commit `197eec6` on `feat/crb-direction1-harness` — `scripts/crb-materialize.py` (rewritten), `scripts/crb-audit-clone.sh` (new), `scripts/crb-harvest-artifacts.py` (new), `runs/review-arms/crb-pipeline/run-host.sh` (rewired), `docker/{Dockerfile.review,Dockerfile.proxy,tinyproxy.conf,egress-allowlist}` (new), and the four new suites (`test/crb-{disposable-clone,audit-clone,harvest-artifacts,egress-config}.bats`, 37 tests) that replaced the deleted `test/crb-containment-reset.bats`.
**Reviewed:** 2026-08-19
**Method:** read the implementations, ran the four suites (37/37 green at 197eec6), then ran **21 mutations** against a throwaway worktree of 197eec6 — **7 caught, 14 survived**. Every finding below that says "survives" was executed, not inferred.

## Test Conventions

- **Framework:** bats, one file per unit under test in `test/`, `# @category fast` header, a prose block at the top of each file explaining *why* the file exists and which rubric item it answers.
- **Hermeticity:** fixtures are throwaway git repos built in `BATS_TEST_TMPDIR`; no network, no docker, no writes outside the tmpdir. `scripts/hermeticity-lint` enforces the no-network half and is green (98 files checked).
- **Python-under-bats pattern:** load the module with `importlib.util.spec_from_file_location`, monkeypatch `DST_ROOT` / `BASELINE_ROOT` / `MANIFEST`, drive one function (`run_mat` in `crb-disposable-clone.bats:54-80`). A **second** pattern exists for CLI-level drive: rewrite the module's three root constants into a patched copy and `subprocess.run` it (`crb-disposable-clone.bats:182-200`) — this is the anti-A3 pattern and it works (control C2 below).
- **Non-vacuity tests are an established convention here**: `crb-audit-clone.bats:146` and `crb-cell-status.bats:194` both exist purely to prove another test can fail. That convention is the right home for most recommendations below.
- **Shell-script assertions** are `grep`-over-source pins (`crb-egress-config.bats`), sometimes with an embedded python heredoc that line-continuation-joins `docker run` blocks first.

## Untested Paths Touched by the Change

Mutation results are quoted per gap: **survived** = the suite stayed 37/37 green with the control removed.

- **G1** — `scripts/crb-materialize.py:225-246` — `scrub_object_store()`: the reflog-expire / `gc --prune=now` / `FETCH_HEAD` unlink that makes every later audit check non-vacuous — **not covered**. `grep -rn scrub_object_store test/` returns zero hits. Mutation: replaced the whole body with `return` → **37/37 green**. The deleted suite had a dedicated non-vacuity test for exactly this (`crb-containment-reset.bats:239`, "scrub_object_store is load-bearing"); it did not carry over.
- **G2** — `scripts/crb-materialize.py:519-523` — the `--snapshot` refusal when a baseline already exists and `--force` was not passed ("the only guard against laundering a used clone into the baseline", per its own comment) — **not covered**. Mutation: `if False:` → **37/37 green**. The suite drives `snapshot_baseline()` through `importlib` only; the CLI `--snapshot` path has no test at all. This is A3's exact shape, one function over.
- **G3** — `scripts/crb-materialize.py:502-507` — the `--verify`/`--snapshot` refusal for a slug absent from the manifest ("cannot pin the reviewed head, so containment is unverifiable"), including the deliberate `and not args.restore` carve-out — **not covered**. Mutation: `if False:` → **37/37 green**.
- **G4** — `scripts/crb-materialize.py:364-365` — `restore_clone()`'s "restored tree has no `.git` — baseline is corrupt" guard, i.e. the truncated-but-hash-matching baseline — **not covered**. Mutation: deleted → **37/37 green**.
- **G5** — `runs/review-arms/crb-pipeline/run-host.sh:209-214` — egress preflight **leg 2's accept set** (`403|000` → ok, anything else → `exit 5`) — **not covered**. Mutation: widened to `200|403|000` → **37/37 green**. `crb-egress-config.bats:110-118` pins only the *echo strings* and `grep -c 'exit 5' >= 3`, neither of which moves.
- **G6** — `runs/review-arms/crb-pipeline/run-host.sh:220-222` — leg 3's condition `[ "$direct" = "000" ]`, the leg that proves the network is `--internal` — **not covered**. Mutation: `[ -n "$direct" ]` (passes for *any* HTTP status, including 200) → **37/37 green**.
- **G7** — `runs/review-arms/crb-pipeline/run-host.sh:159` — `docker network create --internal` — **not covered**. Mutation: `--internal` removed → **37/37 green**. (Runtime leg 3 would catch it *if* leg 3's condition is intact — but G6 shows that condition is itself unpinned, so G6+G7 compose into a silent loss of the whole route control.)
- **G8** — `runs/review-arms/crb-pipeline/docker/tinyproxy.conf:20` — `ConnectPort 443` as an *exclusive* pin ("plain-HTTP proxying and every other port are refused") — **partially covered**: `crb-egress-config.bats:46` asserts the 443 line is present but nothing asserts no *other* `ConnectPort` line exists. Mutation: added `ConnectPort 80` and `ConnectPort 8080` → **37/37 green**. Note the merged fact-check already found `ConnectPort` credited with refusing plain HTTP with no leg exercising it; the config pin has the same hole from the other side.
- **G9** — `scripts/crb-harvest-artifacts.py:115-119` — the `MAX_FILES` / `MAX_TOTAL_BYTES` cap-reached branch (skip-and-break, with the "remaining artifacts NOT captured" warning) — **not covered**. Mutation: `if False:` → **37/37 green**. Only the per-file cap (`:110`) has a test.
- **G10** — `runs/review-arms/crb-pipeline/run-host.sh:413-418` — the `--restore` failure branch (`skipped_bad++; continue`) — **not covered**, and the mutation is worse than a missing test: replacing the `||` guard with `|| true` (restore failure swallowed, cell proceeds on whatever tree is there) → **37/37 green**. `crb-egress-config.bats:101-107` pins the *text* `--restore "$id"`, not that its failure stops the cell.
- **G11** — `runs/review-arms/crb-pipeline/run-host.sh:366-369` — the "no baseline → skip, `skipped_bad++`" branch, and the `ran==0 && skipped_bad>0 → exit 3` terminal at `:578-581` — **not covered**. This is not hypothetical: `external/crb-eval/.baselines` **does not exist** on this machine while five clones do, so *every* instance takes this branch today and the whole sweep's first real behaviour is an untested path.
- **G12** — `runs/review-arms/crb-pipeline/run-host.sh:493-509` — the audit-exit-code mapping. `crb-audit-clone.sh` documents three outcomes (`0` clean, `1` VOID, `2` could-not-check) and `crb-audit-clone.bats:133` pins that the script distinguishes them — but the runner's `if ! docker run ...` collapses `2` into `1`: a docker hiccup or a manifest without a `head` field marks a paid $10-40 cell `containment_failed`. **Not covered**; nothing asserts the mapping either way.
- **G13** — `runs/review-arms/crb-pipeline/run-host.sh:498` — `: > "$dest/CONTAINMENT_FAILED"`, the marker `write_run_meta` reads at `:318-319` to populate `voided_cells` — **not covered**. Mutation: marker write removed → **37/37 green**, and `run-meta.json` then reports `voided_cells: []` for a voided sweep, which is exactly the over-read the surrounding comment (`:341-348`) exists to prevent.
- **G14** — `scripts/crb-audit-clone.sh:60` — `--connectivity-only` on `git fsck`, against a **shallow** clone (production clones are `--depth 50`) — **not covered**. The deleted suite had this control (`crb-containment-reset.bats`, "fetch-trace detection is quiet on a SHALLOW clone"); the new suite's fixtures are all full clones. The audit converts any `^error:` line into a VOID (`:65-67`), so a false positive here voids *every* cell of the sweep. I built a shallow fixture by hand and a correctly-scrubbed one audits clean (exit 0) — the code is right today, but nothing holds it there.
- **G15** — `scripts/crb-materialize.py:274-276` — `artifact_index()`'s `.git` exclusion — **not covered in the direction that matters**. Mutation: exclusion removed from `artifact_index` only → **37/37 green**, because the fixture's `.git` happens to contain no `.md`/`.json`. `crb-disposable-clone.bats:153` claims to pin "skips .git" and does not. (The opposite asymmetry — harvest walking `.git` — *is* caught, by `crb-harvest-artifacts.bats:102`.)
- **G16** — `runs/review-arms/crb-pipeline/docker/Dockerfile.proxy:61-63` — the build-time fail-closed assert on `FilterDefaultDeny` / `Filter` / non-empty filter — **not covered**. Mutation: `RUN grep -qE ...` block deleted → **37/37 green**. Low severity: `crb-egress-config.bats:36-43` pins the same three facts from the repo side, so this is a redundant control losing its redundancy silently.
- **G17** — `test/crb-disposable-clone.bats:168-173` (the test itself, not the code) — `CLI --restore --dry-run destroys nothing` runs the **unpatched** script, so its roots are the real `external/crb-eval` and the real `runs/review-arms/crb/instances.json`, while its positive assertion `[ -f "$CLONE/f.txt" ]` checks a `BATS_TEST_TMPDIR` path the real CLI can never reach. It catches the A1 regression (mutation confirmed: removing the early return turns it red) but for an incidental reason — the exit status of "no baseline at .../fixture.tar". **If a real slug named `fixture` with a valid baseline ever existed, this test would silently delete that clone and still pass.** This is A5's shape (test corpus coupled to the live tree), relocated.
- **G18** — `scripts/crb-audit-clone.sh:69-81` — the tag-pointing-outside-ancestry variant of the descent check — **not covered** (the deleted suite had it at `:385`). Lower than G14: the code path is shared with the orphan-commit case, which *is* covered (`crb-audit-clone.bats:102`); only the `refs/tags` reachability half is unexercised.

### Answers to the three questions asked

1. **"Can any suite be made green by a mutation that removes the control it claims to pin?"** Yes — 14 of 21. The four highest-value survivors are G1 (the enabler of every audit check), G2 (the baseline-laundering guard), G5+G6 (the preflight's own verdicts) and G10 (a swallowed restore failure). The suites are strong where they were written to answer a named prior defect (every anti-A3, anti-A4, FETCH_HEAD, `--no-reflogs`, symlink and remote mutation was caught) and thin everywhere else — they pin the *last* review's findings rather than the new code's branch set.
2. **"Is the boundary between what `crb-egress-config.bats` pins and what the runtime preflight must prove drawn honestly?"** The *stated* boundary is honest — the file's header says plainly it cannot prove the allowlist filters. But things fall between the two halves, because the config suite pins the preflight's **existence** (echo strings, `exit 5` count) while the preflight's **verdicts** are pinned by nothing and cannot run here. G5, G6 and G7 each turn the control off while leaving every string the suite greps for intact. Concretely: a sweep can be started with a non-`--internal` network and a leg-3 test that accepts HTTP 200, with 37/37 green and all three "ok" lines printed. That is the gap the boundary is currently hiding.
3. **"Does the new baseline/index contract introduce an A5-style test-corpus collision?"** Mostly no, and I checked: `external/` (hence `.baselines/`) is gitignored; `test/cross-reference-integrity.bats` only walks `workflows|skills|guides|patterns`, so harvested `.md` artifacts under `runs/` cannot redden it; `crb-cell-status.bats:165-169`'s `LIVE` exclusion still covers the harvest's output dir; the injector's `runs.glob("*/")` (`scripts/crb-pipeline-to-benchmark.py:219`) requires `review.md`, so the newly-added `runs/review-arms/crb-pipeline/docker/` directory is skipped. Two residuals: **G17** above is a genuine live-tree coupling, and `docker/` now sits inside the sweep's output root, so the next glob written over `OUT/*/` without a content predicate will pick up a source directory.

## Recommended Tests

#### scrub_object_store is load-bearing — a stubbed scrub makes the audit void a benign cell

**Closes gaps:** G1
**Type:** unit (non-vacuity)
**Priority:** high
**File:** `test/crb-disposable-clone.bats` (new test; the deleted suite's version lived in `crb-containment-reset.bats:239` and is the template)
**What it verifies:** that the audit's FETCH_HEAD and unreachable-commit checks are only ever quiet because `scrub_object_store()` ran — i.e. removing the call makes a *clean* baseline audit VOID.
**Key cases:**
- Build the fixture clone, run `m.snapshot_baseline()` with `m.scrub_object_store` intact, extract the tar to a temp dir, run `scripts/crb-audit-clone.sh` on it → exit 0.
- Same sequence with `m.scrub_object_store = lambda dst: None` and a `git fetch`-shaped precondition (touch `.git/FETCH_HEAD`, or make a commit and `reset --hard` back without expiring reflogs before snapshot) → audit exits 1 and names `FETCH_HEAD present` / `unreachable commit`.
- Assert the first case fails when the mutation is applied, so the pair cannot both pass vacuously.

**Setup needed:** none beyond the existing `run_mat` harness plus `$AUDIT` from `crb-audit-clone.bats`; this test deliberately spans both scripts, which is the only place the coupling is visible.

#### CLI `--snapshot` refuses a second baseline without `--force`, and refuses a clone that isn't there

**Closes gaps:** G2, G3
**Type:** integration (CLI-level, using the source-rewrite pattern at `crb-disposable-clone.bats:182-200`)
**Priority:** high
**File:** `test/crb-disposable-clone.bats`
**What it verifies:** the two guards on the only surface that can launder a container-written clone into every subsequent cell's definition of "clean".
**Key cases:**
- `--snapshot fixture` on a clone with an existing baseline → non-zero exit, output contains `a baseline already exists`, and the on-disk `fixture.tar` **mtime and sha256 are unchanged**.
- Same with `--force` → exit 0 and a *new* sha256 in the manifest.
- `--verify fixture` (and `--snapshot fixture`) with `fixture` absent from the manifest → non-zero, output contains `cannot pin the reviewed head`.
- `--restore fixture` with `fixture` absent from the manifest → the *different* error (`no baseline_sha256`), pinning the deliberate `and not args.restore` carve-out at `:502`.

**Setup needed:** the existing patched-copy harness; drive the patched script with `subprocess.run` so this is CLI-level and not another importlib-only pin.

#### The egress preflight's three legs each accept only what they claim to

**Closes gaps:** G5, G6, G7
**Type:** unit, after a small extraction
**Priority:** high
**File:** `test/crb-egress-config.bats` (verdict cases) — requires extracting the three legs' verdict logic out of `run-host.sh` into e.g. `scripts/crb-egress-verdict.sh <leg> <http_code>` (exit 0 = leg passed, 5 = halt), exactly as `crb-cell-status.py` was extracted from this same runner "so they have fixtures".
**What it verifies:** that leg 1 halts only on `000`, leg 2 halts on **any** code that is not `403`/`000` (specifically 200 and 302), and leg 3 halts on anything but `000`.
**Key cases:**
- `verdict api 401` → 0; `verdict api 200` → 0; `verdict api 000` → 5.
- `verdict filter 403` → 0; `verdict filter 000` → 0; `verdict filter 200` → 5 (**the mutation that currently survives**); `verdict filter 302` → 5.
- `verdict route 000` → 0; `verdict route 200` → 5; `verdict route 403` → 5 (a *refused* answer from the proxy is not the same as no route).
- A source pin in the same file that `run-host.sh` calls the extracted verdict script for all three legs, and that `docker network create` still carries `--internal`.

**Setup needed:** the extraction. It is small (three `case`/test expressions), and without it these three legs stay verifiable only by spending money.

#### A restore failure stops the cell

**Closes gaps:** G10, G11
**Type:** integration (runner loop, with docker and the CLI stubbed via PATH shim — the pattern in `test/round-log-functions.bats`)
**Priority:** high
**File:** `test/crb-run-host-cell-loop.bats` (new; there is currently **no** test that executes any part of `run-host.sh`)
**What it verifies:** the two skip branches that every instance takes today, and that neither can be turned into a "carry on anyway".
**Key cases:**
- Manifest with one slug, no `.baselines/<slug>.tar` → the cell is skipped, `skipped_bad` increments, no `docker run` shim is invoked for a review cell, script exits **3** with `NO CELL RAN`.
- Baseline present but `crb-materialize.py --restore` stubbed to exit 1 → the review `docker run` is **never** invoked (this is the G10 mutation, and it must be the assertion, not the grep).
- Both baseline and restore succeed → the review container *is* invoked exactly once, with `--network` naming the egress net.

**Setup needed:** PATH shims for `docker` and `python3`-invoked scripts that log their argv to a file; `DRY_RUN` is not usable here since it exits before the loop. Budget: this is the largest single item in the plan, and it is the only way G10-G12 become testable at all.

#### The audit's exit code 2 is "could not check", not a void

**Closes gaps:** G12, G13
**Type:** integration (same new runner-loop file)
**Priority:** medium
**File:** `test/crb-run-host-cell-loop.bats`
**What it verifies:** the runner distinguishes the audit's documented outcomes, and records a real void where `write_run_meta` will find it.
**Key cases:**
- Audit shim exits 1 → `$dest/CONTAINMENT_FAILED` exists, `result.json` gains `"subtype": "containment_failed"`, and `run-meta.json`'s `voided_cells` names the slug (this is the G13 mutation).
- Audit shim exits 2 → the cell is **not** silently banked, but is distinguishable from contamination in the artifacts (decide the contract first — see the open question in the Summary; today both write the same marker).
- Manifest entry lacking `head` → the `head_sha=$(python3 -c ...)` substitution at `:490-492` aborts the sweep under `set -e`; assert the failure is reported rather than swallowed.

**Setup needed:** the shim harness from the previous item.

#### Harvest stops at the total-size and file-count caps

**Closes gaps:** G9
**Type:** unit
**Priority:** medium
**File:** `test/crb-harvest-artifacts.bats`
**What it verifies:** the cap-reached branch runs, warns, and leaves the already-copied artifacts intact.
**Key cases:**
- 501 small `.md` files → `harvested 500 artifact(s)`, stderr contains `harvest cap reached`, exit 0.
- Twelve 5 MB-minus-1-byte `.md` files (under the per-file cap, over the 50 MB total) → copy stops at the total cap, the warning names a byte count, exit is still 0 and the earlier files are present in `$DEST`.
- Assert `MAX_FILES` cannot be raised unnoticed, in the style of `crb-cell-status.bats:194` (a fixture that sits between the current cap and a plausible larger one).

**Setup needed:** none; `head -c … /dev/zero | tr` as already used at `crb-harvest-artifacts.bats:130`. Keep total fixture bytes modest by lowering the caps via an env override if one is added, otherwise ~55 MB of tmpdir writes per run is acceptable for a `fast` suite but should be measured.

#### The audit is quiet on a shallow clone

**Closes gaps:** G14
**Type:** unit (regression control, carried over from the deleted suite)
**Priority:** medium
**File:** `test/crb-audit-clone.bats`
**What it verifies:** `git fsck` on a `--depth`-limited clone with a `.git/shallow` graft produces no `^error:` line, so the audit does not void every cell of a sweep on a false positive.
**Key cases:**
- `git clone --depth=1 file://$UPSTREAM` of a 5-commit repo, scrubbed the way `materialize()` scrubs (remove remote, `symbolic-ref -d refs/remotes/origin/HEAD`, prune refs, expire reflogs, `gc --prune=now`, delete `FETCH_HEAD`), `review`/`main` set → audit exits 0. (I verified this passes today by hand; the point is to hold it.)
- The same fixture with `--connectivity-only` removed from the audit's fsck line asserted to be the *only* reason it stays quiet, if that turns out to be reproducible on this git version — otherwise assert the shallow case alone and note the limitation in the test's comment rather than writing a non-vacuity claim you cannot back.

**Setup needed:** a local `file://` upstream repo in `BATS_TEST_TMPDIR` — the deleted suite's `make_answer_key_repo` helper is the template and can be recovered from `git show 197eec6^:test/crb-containment-reset.bats`.

#### `ConnectPort` is 443 and nothing else

**Closes gaps:** G8
**Type:** unit (config pin)
**Priority:** medium
**File:** `test/crb-egress-config.bats`
**What it verifies:** the tunnel cannot be widened by *addition*, which is how config controls actually rot.
**Key cases:**
- `grep -cE '^[[:space:]]*ConnectPort' tinyproxy.conf` equals exactly `1`, and that one line is `443`.
- Same exactness treatment for `Allow`: exactly one `Allow` line, and it equals `$EGRESS_SUBNET` (today the subnet round-trip at `:52-53` breaks incidentally on a second `Allow`, which is luck, not a test).

**Setup needed:** none.

#### The `--dry-run` test stops depending on the live tree

**Closes gaps:** G17
**Type:** unit (test hygiene, not new coverage)
**Priority:** medium
**File:** `test/crb-disposable-clone.bats:168-173` (rewrite in place)
**What it verifies:** the same A1 regression, but through the patched-copy harness so the assertion is about a clone the test owns.
**Key cases:**
- Run the *patched* script (roots redirected into `$WORK`) with `--restore fixture --dry-run` after a successful snapshot, with the work clone deliberately dirtied → exit 0, `Nothing touched` in output, and `f.txt` still reads the dirtied value, i.e. the restore demonstrably did **not** happen.
- Keep one assertion that the real CLI never resolves a slug outside `$WORK`: assert `external/crb-eval/fixture` does not exist before and after.

**Setup needed:** none — reuse the existing patched-copy block.

#### `artifact_index` really excludes `.git`

**Closes gaps:** G15
**Type:** unit
**Priority:** low
**File:** `test/crb-disposable-clone.bats:153` (strengthen the existing test)
**What it verifies:** the exclusion, rather than the fixture's coincidence.
**Key cases:**
- Write `$CLONE/.git/hooks/notes.md` and `$CLONE/.git/x.json` before indexing; assert neither appears in the index. (Today both the `.git` filter and no filter give the same answer.)

**Setup needed:** none.

## What NOT to Test

- **Anything docker-shaped, in bats.** The images, the `--internal` network and tinyproxy are correctly out of scope for a hermetic suite, and the commit is explicit about it. The recommendation above is not "test docker" — it is "make the preflight's *verdict logic* a testable unit so the part that does not need docker stops riding on the part that does".
- **G18 (tag outside ancestry)** — the descent check's code path is already exercised by the orphan-commit case (`crb-audit-clone.bats:102`); a tag variant would pin `refs/tags` inclusion in `rev-list --all`, which is git's behaviour, not this script's. Restore it only if the audit ever grows a per-refspace filter.
- **G16 (Dockerfile.proxy build assert)** — the same three facts are pinned from the repo side by `crb-egress-config.bats:36-43`, and testing a `RUN grep` needs a docker build. Leave it; note in the Dockerfile comment that the bats file is the primary pin and the `RUN` is belt-and-braces, so a future reader does not treat it as the control.
- **`sha256_file`, `dir_mb`, `slug_for`** — either trivially covered by the round-trip cases or unchanged by this commit.
- **`write_run_meta`'s union-of-requested_instances logic** — pre-existing and covered by `test/crb-subset-attrition.bats`.

## Coverage Gaps Beyond Current Scope

**1.** `runs/review-arms/crb-pipeline/run-host.sh` has **no executing test of any kind** — 582 lines, every dollar of the sweep flows through it, and its only verification is `grep`-over-source from `crb-egress-config.bats`. The recommendation above adds the first one; the retry/`MAX_ATTEMPTS` logic (`:389-403`), the `SWEEP_BUDGET` gate (`:544-569`) and the `attempts.jsonl` ledger (`:529-539`) remain unexercised and are all money-handling code.

**2.** No test covers `crb-materialize.py`'s `materialize()` / `resolve_base()` / `verify_containment()` end-to-end against a local `file://` fork fixture. The deleted suite at least drove `verify_containment()`; nothing does now. A single `file://`-based fixture would cover the remote-removal-before-ref-pruning ordering that `:454-462` warns about at length.

**3.** The five clones in `external/crb-eval/` have no baselines and no manifest `baseline_sha256`, so the very first action of the next sweep is the untested G11 branch, ending in `exit 3`. Whether the fix is `--snapshot` on five clones that containers *have* previously run against (which G2 exists to forbid) or a re-materialize is a **decision**, not a test — but it needs making before the sweep, and today no test would tell you which state you are in.

**4.** `runs/review-arms/crb-pipeline/` is now simultaneously a source directory (`docker/`) and the sweep's output root. Nothing breaks today, but the next glob written over `OUT/*/` without a content predicate repeats A5. Consider moving the docker context out of `OUT`, or add a one-line pin that `docker/` contains no `result.json`/`review.md`.

## Summary

The highest-value single test is the **`scrub_object_store` non-vacuity pin (G1)**: it is one function whose removal leaves all 37 tests green while silently converting every audit check in the sweep into a check that cannot fire — and the deleted suite had exactly this test, so the regression is a carry-over miss rather than a new design gap. Close behind it are the preflight verdict extraction (G5/G6/G7), which is the only way the egress control becomes verifiable at $0 rather than by execution during a paid sweep, and the first executing test of `run-host.sh`'s cell loop (G10/G11), whose swallow-the-restore-failure mutation survives today and whose no-baseline branch is the path the next sweep will actually take. Mutation score for the four suites is 7/21 caught; the caught set is almost exactly the set of defects the *previous* review named (A3, A1, `--no-reflogs`, FETCH_HEAD, symlinks, remotes, allowlist size), which is a suite written to a findings list rather than to the code's branch set — good discipline, incomplete coverage. The main residual risk after this plan is executed is unchanged and correctly stated by the commit: nothing docker-shaped has run, so the allowlist's filtering behaviour is still proven only by the runtime preflight — but after these tests, the preflight's own pass/fail logic would at least be pinned, which it is not now. Two open questions the enumeration surfaced: (a) should the runner distinguish audit exit 2 ("could not check") from exit 1 ("VOID"), given that today a docker hiccup discards a $10-40 cell as contaminated; (b) the five existing clones cannot be baselined without violating the `--snapshot`-only-on-pristine rule that G2 guards, so the pre-sweep remediation path needs deciding explicitly.

## Goal-Alignment Note
- Answered: yes — mutation-probed all four new suites, answered all three named questions, report saved to `docs/reviews/test-strategy-review.md`.
- Out of scope: docker-runtime verification (deliberate, per the brief); everything on the branch before 197eec6 (context only); the fact-check's prose/doc-accuracy findings, which I used as input rather than re-verifying.
- Escalate: (1) the five existing clones have no baselines and cannot legitimately be `--snapshot`ed if any container has run against them — a pre-sweep decision, not a test; (2) `run-host.sh` has no executing test at all, which is a scope call bigger than this commit; (3) the audit-exit-2 contract (could-not-check vs void) needs deciding before it can be tested.
