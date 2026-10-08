Commit: 380ed01b
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` (merge base e5d0f838, HEAD 380ed01b; last code commit 4b7f2357) plus the commit messages of main..HEAD (3e58eb9c, cb9723c3, 27364085, 80cc6224, 61e2e734, 21b35ebf, 2fbd929b, 3a35c8b9, 4b7f2357, 380ed01b). Code: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`. Docs: `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c and U2b bullets), `docs/reviews/override-log.md` (rows added on the branch), and the factual claims about the code in `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md` ("Iteration 3 of 3"). Other `docs/reviews/*u2a3c*` files are history and were not verdicted. Merged from three replicates (`code-fact-check-report-build-loop-u2a3c-r1.md`, `-r2.md`, `-r3.md`, each `Commit: 380ed01b`) by most-severe-wins; final confirming pass.
**Checked:** 2026-10-07
**Commit:** 380ed01b
**Replication:** k=3
**Total claims checked:** 58
**Summary:** 48 verified, 8 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Merge notes. Claims were clustered by file, overlapping line range (±5) and substance, and emitted at the finest granularity any replicate used; a replicate that verdicted only a compound carries its verdict on each sub-claim row, marked `(compound)`. Each merged claim carries the winning replicate's evidence (ties: most specific `Scope:`, then lowest replicate). Every replicate read `docs/reviews/hallucination-patterns.md` and found no claim matching a logged pattern. Execution provenance per replicate: r1 scratch `/tmp/u2a3c-i4-fc1-PaRf/`, r2 scratch `/tmp/u2a3c-i4-fc2-hpCT/` (logs under `logs/`), r3 scratch `/tmp/u2a3c-i4-fc3-G9S7/`; all on bash 5.2.15, mawk 1.3.4, git 2.39, uid 1000, 2026-10-07 between 21:57Z and 22:30Z. Captured output stays in those scratch dirs (each brief forbade writing elsewhere in the worktree), so none is copied to `docs/reviews/execution-logs/`. Suites at HEAD, all exit 0: build-loop-check 66/66 under TMPDIRs of 22 and 76 (r1), 22 and 73 (r2), 23, 86 and 182 characters (r3); dev-cycle 78/78; build-loop-read 19/19; fixture-hermeticity 2/2.

---

## Claim 1a: "Tests after fixes (4b7f2357): build-loop-check 66/66 under a 17- and a 74-character TMPDIR, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every suite count at HEAD (whose code equals 4b7f2357's) under a 22- and a 76-character TMPDIR, and shellcheck at the project's gate severity. It does not establish the exact 17- and 74-character runs, or a default-severity shellcheck, which reports SC2004, SC2015 and SC2016 info/style notes (main's lib is also non-clean at that severity).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: "does not establish the exact 17/74-character lengths" (r1 used 22/76, r2 22/73, r3 23/86/182) · r1+r2+r3: "default-level shellcheck prints info/style notes only (SC2015, SC2016, SC2004); the gate runs `-S warning`" · r2+r3: "does not establish `scripts/health-check.sh` passing (not run)" (see Claim 1b) · r2+r3: shellcheck `-S warning` also clean on `test/scripts/build-loop-check.bats` (r3: and `test/scripts/dev-cycle.bats`)

Executed (r1): the four suites gave 66/66, 78/78, 19/19 and 2/2, all exit 0. `shellcheck -S warning scripts/lib/dev-cycle-read.sh` exited 0, which matches the health check's own invocation: `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:480`). A bare `shellcheck` exits 1 on info/style notes only.

**Evidence:** `scripts/health-check.sh:480`; `/tmp/u2a3c-i4-fc1-PaRf/blc-short.log`, `/tmp/u2a3c-i4-fc1-PaRf/blc-long.log`, `/tmp/u2a3c-i4-fc1-PaRf/dev-cycle.bats.log`, `/tmp/u2a3c-i4-fc1-PaRf/build-loop-read.bats.log`, `/tmp/u2a3c-i4-fc1-PaRf/fixture-hermeticity.bats.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 1b: "`scripts/health-check.sh` passed at 3a35c8b9 and at 4b7f2357"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:82`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers nothing beyond its shellcheck gate (Claim 1a). It does not establish the other gates, which were not run.
**Replicate verdicts:** r1=Unverifiable · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r2: "It does not establish `scripts/health-check.sh` passing (not run)" (scope note on its Claim 5) · r3: "Does not cover the full `scripts/health-check.sh`" (scope note on its Claim 8) · r1: out of scope "the full health check (cost)"

Execution required but not run (r1). Gate 5 runs the whole test runner (paraphrased — no quote available because the gate spans `scripts/health-check.sh:354-410` and calls `run-tests.sh`), and the replicate ran the four in-scope suites instead.

**Evidence:** `scripts/health-check.sh:354-410`, `scripts/health-check.sh:427-480`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: D1 — "`${x[0]@a}` is O(1) and gives the same answers (empty, large, indexed, scalar, unset checked). 2.5 s now, main 0.9 s. A 20 s-timeout test fails at 3a35c8b9 (it catches on hosts up to ~2x faster)."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:92`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three timings on this host, the type answers for the eight variable shapes probed, O(1) against linear cost, and test 66 failing at 3a35c8b9. It does not establish the critic's 85 s run or the 50k-entry-tree figures, which were not re-run.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish timings on other hosts or variables with other attributes (readonly, exported)" · r3: "Does not establish timings on any other host"; r3 additionally checked `-i`, `-r`, `-x` and readonly `-A` (identical answers) · r2: many-token timing used AGENTS.md as the start file in place of the test's CLAUDE.md (a hook blocks shell writes to CLAUDE.md) · measured 3a35c8b9 times: r1 41.93 s, r2 39.1 s, r3 42.33 s (all ≈ 2x the 20 s timeout)

Command `bash many.sh 4000` (r1; cwd a fresh fixture repo under the scratch dir, 22:00:54Z, exit 0): `HEAD ok 2.44`, `3a35c8b9 ok 41.93`, `main ok 0.92` (`many.log`). 41.93 / 20 ≈ 2.1, which gives the "~2x". Type answers (`attr.sh`) are identical for `${r[0]@a}` and `${r@a}` through a nameref: empty assoc `A`, 1,000-key assoc `A`, assoc with key 0 `A`, declared-unset assoc `A`, `-iA` `Ai`, `-rA` `Ar`, indexed and empty indexed `a`, scalar and nonexistent ``. Cost (`t.sh`, 2,000 checks): `[0]@a` took 0.004 s at 100, 10,000 and 40,000 keys, while `@a` took 0.011 s, 2.176 s and 9.139 s. With the HEAD test file, 3a35c8b9's lib fails test 66 with status 124, a timeout (`old-3a35c8b9.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:741`; `/tmp/u2a3c-i4-fc1-PaRf/many.log`, `/tmp/u2a3c-i4-fc1-PaRf/attr.sh`, `/tmp/u2a3c-i4-fc1-PaRf/t.sh`, `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3a: D2 — "main_checkout memoized a checkout directory at PATH as d without checking ENT[PATH] … (and `x.md` main stores as a gitlink answered 0). Unreachable from main_imports … Fixed (4b7f2357) … Guard: main's link or gitlink at PATH answers 1"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 3a35c8b9's PATH memo, the guard at HEAD, and both main_imports call sites. It does not establish safety for a PATH main stores as a blob (Claim 17b and Escalations).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: "Does not establish reachability from main_imports, which never makes this call"; r3 verdicted only the 3a35c8b9 fail-open part (a gitlink `x.md` held as a readable file has no ancestors and reaches `rawfile`, returning 0) · r2: its D2 claim is scoped to the parenthetical's reason only and "does not touch the guard that shipped, which is right"

3a35c8b9 has no PATH mode check before its final shape tests. HEAD adds one (r1):

```bash
# scripts/lib/dev-cycle-read.sh:743
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
```

Both main_imports calls are guarded by absence from `ent`: `[[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f"` (`:833`, where a `t:` candidate is added only when `[[ -n "${ent[$f]+set}" ]]` fails, `:826`) and `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:877`). Test 65 at 3a35c8b9 prints `l 2 / l/f.md 0 / g 2 / g/f.md 0`, which is the fail-open case. At HEAD it prints `l 1 / l/f.md 1 / g 1 / g/f.md 1` (`old-3a35c8b9.log`, `blc-short.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `scripts/lib/dev-cycle-read.sh:826`, `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:877`; `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3b: D2 author note — "a broad "any ENT path" guard would break T1's blob row"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a guard that refuses any ENT entry at PATH (`[[ -z "${mc_e[$3]+set}" ]] || return 1`) run against T1 and the other main_checkout tests. Does not establish what a guard over every ancestor's ENT entry would do: that reading would change T1's `f.md/x.md 2` row, but it is not a guard "at PATH".
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Incorrect
**Replicate annotations:** r1+r2+r3: the note holds only if "broad" also covers ancestors; an ancestor-wide mutant (`:749` → `[[ -z "${mc_e[$c]+set}" ]] || return 1`) breaks T1 at `f.md/x.md 1` (r1 executed, r2 m8 executed) · r1+r2: the PATH-wide mutant passes the whole suite, 66/66 (`broad.log`, `mut-broad-full.log`) · r1: "no test separates the narrow guard from the PATH-wide one (Escalations)" · r2+r3: the shipped narrow guard is still right; only the stated reason fails · r2: "This is a history doc, so the fix is a correction note, not a code change" · r3: the real difference is that "the broad guard would also refuse a blob PATH, which the U2b bullet allows" · r1+r3 decision: read "any ENT path" as a guard on PATH only · r1, r2 confidence Medium; r3 High · r2's report omits the `Verification mode` field on this claim

T1 never passes a PATH that ENT holds (r3). Its ENT is `declare -A E=([lnk]=120000 [gl]=160000 [nd2/m/l]=120000 [f.md]=100644)` and its PATH list is `d/r.md nx.md nd/x.md f.md/x.md d u d/n.md sf.md dg.md sd ff.md u/x.md sd/nx.md dgd/x.md lnk/x.md gl/x.md nd2/m/l/x.md` (`test/scripts/build-loop-check.bats:858-859`). The blob `f.md` appears only as an ancestor of `f.md/x.md`. With the broad guard in place of `[[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1` (`scripts/lib/dev-cycle-read.sh:743`), T1 still passes.

- Command: `./runwith.sh $PWD/lib-m5-broad.sh 'main_checkout' at-m5.log`
- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit code: 0 (ok=3, notok=0), 2026-10-07T22:12Z

The narrow guard is still the right fix, since main_imports never passes a PATH that ENT holds (Claim 25b). The stated reason for choosing it is what does not hold.

**Evidence:** `test/scripts/build-loop-check.bats:854-880`, `scripts/lib/dev-cycle-read.sh:743`, `/tmp/u2a3c-i4-fc3-G9S7/at-m5.log`, `/tmp/u2a3c-i4-fc3-G9S7/lib-m5-broad.sh`
**Legibility-target:** for-author

---

## Claim 4: D3 — "Test 59 (T3) fixed IMPORT_WORK_MAX=1000 while w grows with the fixture root's length: red under a TMPDIR over ~27 characters … Caps derived from w"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 3a35c8b9's test 59 at TMPDIR lengths 22-40 and the HEAD test at 22 and 76. It does not establish the threshold on a bats version with a differently sized run directory.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The ~27-character threshold is derived, not bisected" (w = 4R+28; bats adds 29 characters, giving TMPDIR ≈ 27) · r2+r3: "The 17- and 74-character runs themselves were not repeated" · r3: old T3 passes at 27 and fails at 28, 30, 40; new T3 passes at 23, 86 and 182

Command `bash t3.sh` (r1; cwd `/tmp/u2a3c-i4-fc1-PaRf/repo3a`, a `git archive 3a35c8b9` copy, 22:02:07Z, exit 0). It passes at lengths 22, 25, 26 and 27, and fails at 28, 29, 30 and 40 (`t3.log`). HEAD derives the caps from w: `m=$((10 * w)); IMPORT_WORK_MAX=$m` (`test/scripts/build-loop-check.bats:909`), and passes under both TMPDIRs.

**Evidence:** `test/scripts/build-loop-check.bats:898-914`; `/tmp/u2a3c-i4-fc1-PaRf/t3.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: D4 — "the walk reads main's blob for every path main stores, so an edited tracked instruction file's imports go unread (test 77 pins this as intended)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the behaviour and the test reference. Does not cover other test numberings (for example a multi-file bats run).
**Replicate verdicts:** r1=Verified · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: read "test 77" as the test at line 77 of build-loop-check.bats ("bats test 4, so 'test 77' is a line number") and verdicted Verified on that reading; "does not establish U2b's enforcement, which is not built" · r3: the number comes from `security-reviewer-review-2026-10-07-build-loop-u2a3c-final.md:87`; fix is to cite the test by its title

The behaviour holds (r3). A path main stores is read through main's blob arm, ``100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | capped_read drain | ...`` (`scripts/lib/dev-cycle-read.sh:846`), and only paths ENT lacks become checkout candidates: `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:826`).

The test reference is wrong. The pinning test is build-loop-check's test 4, "main walk: main's instruction files start it; a working-tree edit does not count; ..." (`blc-short.log` line 5). Test 77 in build-loop-check.bats does not exist (the file has 66 tests), and dev-cycle.bats test 77 is "main_entry answers badform ...". The fix: cite the test by its title.

**Evidence:** `scripts/lib/dev-cycle-read.sh:826`, `scripts/lib/dev-cycle-read.sh:846`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`, `/tmp/u2a3c-i4-fc3-G9S7/dev-cycle.bats.log`
**Legibility-target:** for-author

---

## Claim 6: D4 — "Restored as the first of four caller duties."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the U2b bullet's wording and count. It does not establish that any caller performs the duties (none exists yet).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

The bullet reads "owes the walk four things: that checkout a clean worktree at MAIN_SHA (…); that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared (…); a git that prints nothing on stderr for `ls-files` (…); and the git environment the override log hands the caller" (`docs/working/plan-build-loop-handoff.md:279`). The clean-worktree duty is first of four (r2).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 7a: E1 — "The deep-token test's `timeout 6` catches its regression only on hosts under ~1.8x faster"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:103-104`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this host's timings for a 1,000-deep token whose directories the checkout holds. Does not establish the ratios on other hosts.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** none

E1's 1.8x is 10.7 / 6, from 2fbd929b's message (r3; paraphrased — no quote available because the ratio is arithmetic over two cited numbers). With the directories absent (`deep.sh LIB 1000 0`), HEAD took 0.61 s.

**Evidence:** `test/scripts/build-loop-check.bats:934-942`, `/tmp/u2a3c-i4-fc3-G9S7/deep.log`, `/tmp/u2a3c-i4-fc3-G9S7/deep.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7b: E2 — "A deep token through directories the checkout holds still costs about D³ in realpath (D=1000: 14 s; 21b35ebf 34 s; main over 120 s)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:102`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the three timings at D=1000 on this host. It does not establish the D³ exponent, which was not fitted (one D only), and the HEAD and 21b35ebf runs shared the CPU with a concurrent bats run, so they may be inflated.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: "Does not establish the ratios on other hosts"; r3 measured HEAD 12.22 s, 21b35ebf 31.31 s, main timed out at 200.43 s · r2 (on the identical override row 458, Claim 11): measured growth per doubling is 3.8x to 5.7x at D ≤ 1000, below D³'s 8x

Command `bash deep.sh 1000 "HEAD 21b35ebf"` (r1; fixture under the scratch dir, 22:05:06Z, exit 0): `HEAD ok 11.67`, `21b35ebf ok 31.51` (`deep.log`). `bash deep.sh 1000 main` (22:06:40Z): main had not finished at 150.28 s and was killed by `timeout 150` (`deep-main.log`).

**Evidence:** `/tmp/u2a3c-i4-fc1-PaRf/deep.sh`, `/tmp/u2a3c-i4-fc1-PaRf/deep.log`, `/tmp/u2a3c-i4-fc1-PaRf/deep-main.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: E5 — "A non-numeric `git cat-file -s` output would abort the caller under set -u rather than return 1"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:105`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers `[[ "$i" -le 4096 ]]` with `i=abc` under `set -u`, inside a function with an `||` handler. Does not test a real git producing such output.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r3: output inline in the session only; no log file

`bash -c 'set -u; f(){ i=abc; [[ "$i" -le 4096 ]] || { echo ret1; return 1; }; }; f || echo ...; echo after'` printed `abc: unbound variable` and exited 127, with neither the handler nor `after` running (r3; cwd `/tmp/u2a3c-i4-fc3-G9S7`, 2026-10-07T22:11Z). This is the shape of `i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:850`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:850`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: Confirmed Good — "For PATHs ENT lacks, main_checkout returns 21b35ebf's code under any call order on one MEMO"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:112`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 12,000 random-order calls over 300 random fixtures, at depth ≤ 4 with three names per level, including ENT blob/link/gitlink entries at ancestors and at PATH. It does not establish deeper paths, case-insensitive filesystems, or a checkout that changes between calls.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "does not cover … ENT shapes main_imports' duplicate check would refuse (ENT here may hold both `p` and `p/x`)"; r2's fuzz: `mismatches=0 allowed_link_at_PATH=983`, and 62 non-allowed mismatches against 2fbd929b · r1: harness against 3a35c8b9 gives 36 unexpected diffs · r3 ran a comparable fuzz (21,000 calls, 0 unexpected) but cited it on the lib comment (Claim 25a), not on this rubric line

Command `LC_ALL=C bash fuzz.sh 300 40` (r1; cwd scratch, 22:04:02Z, exit 0). Each fixture mixes absent nodes, searchable and unsearchable directories, readable and mode-000 files, links to siblings, dangling links and FIFOs. Each call runs HEAD's and 21b35ebf's main_checkout on separate MEMOs. Result: `calls=12000 unexpected_diffs=0 expected_link_PATH_diffs=657`. Every difference is a PATH that ENT holds as 120000/160000, where HEAD answers 1. That includes PATHs that ENT holds as a blob: they matched 21b35ebf. The same harness against 3a35c8b9's main_checkout gives 36 unexpected diffs (`fuzz3a.sh`), so it is sensitive to the defect fixed in 4b7f2357.

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`; `/tmp/u2a3c-i4-fc1-PaRf/fuzz.sh`, `/tmp/u2a3c-i4-fc1-PaRf/fuzz.log`, `/tmp/u2a3c-i4-fc1-PaRf/fuzz3a.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: override row — "capped_read drains only when the blob arm passes `drain` (since 2fbd929b), and the test row 453 names is "main walk reads an untracked start that a main file also imports once, through the checkout""

**Location:** `docs/reviews/override-log.md:457`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers capped_read's drain condition, its one `drain` caller, and the test title. Does not re-verify rows 449 and 453 themselves.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2: "does not establish row 453's other content" · r2: the checkout arm (`:844`) and the tree walk (`:782`) call capped_read bare · r1: `git show 2fbd929b` adds that body

The reader is ``capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }`` (`scripts/lib/dev-cycle-read.sh:710`), and only the blob arm passes `drain` (`:846`). The test exists at `test/scripts/build-loop-check.bats:923`. Dropping `drain` (m6) fails the 4 MiB test: `./runwith.sh lib-m6-nodrain.sh '4 MiB' at-m6.log` in `/tmp/u2a3c-i4-fc3-G9S7` exited 1, 2026-10-07T22:13Z (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:710`, `scripts/lib/dev-cycle-read.sh:846`, `test/scripts/build-loop-check.bats:923`, `/tmp/u2a3c-i4-fc3-G9S7/at-m6.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: override row — "A deep token through directories the checkout holds still costs about D³ in realpath (D=1000: 14.3 s; 21b35ebf 33.7 s; main over 120 s) … IMPORT_OUT_MAX caps D near 2,000"

**Location:** `docs/reviews/override-log.md:458`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the mechanism (one realpath per distinct prefix, each linear in depth with per-component lookups) and the D=250/500/1000 timings at HEAD and 21b35ebf on this host. It does not establish the asymptotic exponent: measured growth per doubling is 3.8x to 5.7x at D ≤ 1000, below D³'s 8x. The main lib did not finish within a 300 s timeout (consistent with "over 120 s").
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish the exponent, or the '`! -L` would do' design suggestion"; HEAD and 21b35ebf runs shared the CPU (r1 Claim 6) · r3: "Does not measure the exponent" · measured D=1000: r1 HEAD 11.67 s / 21b35ebf 31.51 s / main > 150 s; r2 10.9 / 30.3 / > 300 s; r3 12.2 / 31.3 / > 200 s

Per distinct prefix candidate, `main_checkout` finds the parent memoized `d` and runs `plaindir "$c"` at PATH, which is `realpath -e` over a k-component path (`scripts/lib/dev-cycle-read.sh:759`, `:106`). That makes Σk² path lookups, about D³/3. Measured with `deep.sh` (r2; token `@a/…/x.md` through D present untracked directories, AGENTS.md start): D=250 0.5 s, D=500 1.9 s, D=1000 10.9 s at HEAD; 21b35ebf D=1000 30.3 s; main killed by `timeout 300` at 300.6 s (`logs/deep.log`, `logs/deep-present-old.log`). These are 10.9 s against the row's 14.3 s and 30.3 s against 33.7 s, which is host variance.

On the D cap (paraphrased — no quote available because the figure is arithmetic over the printed names): the distinct names printed are about D paths of length about 2k, so the printed sum is about D², and 4,000,000 gives D ≈ 2,000.

**Evidence:** `scripts/lib/dev-cycle-read.sh:756-761`, `scripts/lib/dev-cycle-read.sh:106`, `/tmp/u2a3c-i4-fc2-hpCT/deep.sh`, `/tmp/u2a3c-i4-fc2-hpCT/logs/deep.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/deep-present-old.log`

---

## Claim 12: override row — "The walk's caller contract lives in two places (the lib block comment for the cache rules, the plan's U2b bullet for the rest) … A5 now names which part lives where"

**Location:** `docs/reviews/override-log.md:459`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three texts' current content. It does not establish that the U2b bullet holds only "the rest": it repeats the cache-clear duty as well.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "It does not establish completeness of the contract" · r3: "Does not judge whether the split is a good design" (r3 verdicted rows 459-460 as one claim)

The lib comment holds the cache rules: "the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout, … so a caller whose checkout may have changed … sets IMPORTED_MAIN_DONE="" to walk again" (`scripts/lib/dev-cycle-read.sh:486-491`). A5 reads "the lib's block comment above `IMPORTED=` holds the cache rules; the plan's U2b bullet holds the rest of what a caller owes the walk" (`docs/working/known-issues-dev-cycle.md:18`) (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-496`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 13: override row — "The Incorrect was unreachable from main_imports; every critic weighed it; fixed in code (guard + test)"

**Location:** `docs/reviews/override-log.md:460`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reachability through both call sites, the guard, and test 65. It does not establish "every critic weighed it", a process claim.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r2: "every critic weighed it" is a process claim and was not checked · r3: reachability via its Claim 21 (static, both call sites)

As in Claim 3a (r1): both call sites skip paths in `ent` (`scripts/lib/dev-cycle-read.sh:833`, `:877`), the guard sits at `:743`, and test 65 fails at 3a35c8b9 and passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:743`, `scripts/lib/dev-cycle-read.sh:833`, `scripts/lib/dev-cycle-read.sh:877`; `test/scripts/build-loop-check.bats:973-980`; `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 14a: A5 — "a checkout path it would walk that lies under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git prints any stderr for fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the listed fail cases and one unlisted one. Every listed case fails as stated. The list omits a path that lies under a non-plain checkout ancestor (a symlinked directory, a dangling link, a FIFO), which fails even when nothing is at the path. It does not establish Claude Code's behaviour there.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: "does not establish that U2b enforces any of them (not built)" · r3: "Does not cover the 'Not covered' items, which are untraced gaps by design"; the `.git` tests (build-loop-check 6-8, 51, 57, 58) pass · r2: "The omission fails closed, and iteration 1's rubric C8 records the stricter shape as intended"

The ancestor test fails on anything but a plain searchable directory: `elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi` (`scripts/lib/dev-cycle-read.sh:752`). An executed fixture (r2) had a committed `AGENTS.md` holding `see @sl/x.md` and an untracked `sl -> d` with `d/x.md`. `main_imports` printed `failed` and `main_checkout E M sl/x.md` returned `mc=1` (cwd `/tmp/u2a3c-i4-fc2-hpCT/sl`, inline run, exit 0). T1 pins the same shape with nothing at PATH: `sd/nx.md 1` and `dgd/x.md 1` (`test/scripts/build-loop-check.bats:875-876`).

Read literally, A5's "anything but a plain file or directory there (or nothing)" lets `sd/nx.md` pass ("nothing" there). The precise version adds "or under a checkout directory that is not plain (a link, a FIFO)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:747-755`, `test/scripts/build-loop-check.bats:854-883`, `docs/working/known-issues-dev-cycle.md:18`

---

## Claim 14b: A5 — "the lib's block comment above `IMPORTED=` holds the cache rules; the plan's U2b bullet holds the rest of what a caller owes the walk: a clean worktree at MAIN_SHA, empty `ls-files` stderr, the git environment, `LC_ALL=C`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of each named item in the named place. It does not establish that the U2b bullet holds only the rest (it also states the cache clear).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1: "`LC_ALL=C` sits outside its 'four things', but it is in the bullet"; "does not establish that U2b enforces any of them (not built)"

The U2b bullet holds "a clean worktree at MAIN_SHA", "a git that prints nothing on stderr for `ls-files`", "the git environment the override log hands the caller" and "runs the walk under `LC_ALL=C` (A5)" (`docs/working/plan-build-loop-handoff.md:279`). The block comment above `IMPORTED=` holds the cache key and clear rules (`scripts/lib/dev-cycle-read.sh:486-491`) (r2).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:486-496`

---

## Claim 15: F11 — "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, an unreadable file, or anything but a plain file or directory, and a checkout listing git prints any stderr for fails the walk; the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers F11's admission list against `main_checkout` and its contract parenthetical against the U2b bullet. Both halves are right in what they name but incomplete. The admission list omits the non-plain checkout ancestor (Claim 14a). The parenthetical names three duties where the U2b bullet now lists four plus `LC_ALL=C`.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r1: verdict rests on the parenthetical only (admission list judged complete); "It does not establish anything else in the F11 row"; precise version "(a clean worktree at MAIN_SHA, cache clear, empty `ls-files` stderr, the git environment, `LC_ALL=C`)", or drop the list and point to the bullet · r3: "Does not establish completeness: absence is not a refusal …, and the list omits the clean-worktree duty, though it does not claim to be exhaustive"

`main_checkout` returns 1 for an ancestor main stores as a link or gitlink (`:749`), an unsearchable or non-plain ancestor (`:752`), an unreadable plain file (`if rawfile "$c"; then [[ -r "$c" ]]; return; fi`, `:758`) and anything else at PATH (`plaindir "$c" || return 1`, `:759`). `checkout_md` fails on any stderr (`:717`) (r2).

4b7f2357 added "a clean worktree at MAIN_SHA" as the U2b bullet's first duty (`docs/working/plan-build-loop-handoff.md:279`), and it edited F11 in the same commit ("F11 lists the unreadable file"). F11's "(cache clear, empty `ls-files` stderr, the git environment)" was not extended to name it.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:717`, `scripts/lib/dev-cycle-read.sh:747-761`

---

## Claim 16: U2a3c bullet — "Built 2026-10-07 after the rebase onto U2a3b: the fail rules as stated (…), `capped_read`, the work bound `IMPORT_WORK_MAX` (reported by the parser's trailer, charged by `import_work`), `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)."

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and wiring of each named piece. Their correctness is verdicted in the lib claims below.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: "A non-plain node … fails" matches `:752` and `:759`, which also cover the non-plain ancestor that A5 and F11 omit (Claims 14a, 15) · r3: the `.git` special case is gone from the import loop (`:875-881`)

The pieces are all present and wired (r2). `capped_read` is at `:710`. `IMPORT_WORK_MAX=50000000` is at `:512`. The trailer is `END { if (trail) print "/" (work + 0) }` (`:630`), and `import_work` is called at `:783`, `:845` and `:847`. The memo is the `mc_m` writes at `:754` and `:760`. `nul_list low lower_all "${cand[@]}"` is at `:827`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:510-512`, `scripts/lib/dev-cycle-read.sh:630`, `scripts/lib/dev-cycle-read.sh:701-710`, `scripts/lib/dev-cycle-read.sh:752-760`, `scripts/lib/dev-cycle-read.sh:827`

---

## Claim 17a: U2b bullet — "owes the walk four things: that checkout a clean worktree at MAIN_SHA (the walk reads main's blob for every path main stores, so an edited tracked instruction file's own imports go unread …) …"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the arm choice for paths ENT holds. It does not establish that U2b enforces cleanliness (not built).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: four duties, each introduced by a semicolon · r3: cache key ``[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]]`` (`:813`) has no checkout component; "Does not establish that U2b will enforce the duties (unbuilt)"

The read arm is chosen by `case "${ent[$f]-checkout}" in`. A path ENT holds as `100644|100755` is read with `git cat-file blob "$MAIN_SHA:$f"`, and only an ENT-absent path reads the checkout (`scripts/lib/dev-cycle-read.sh:843-847`). Starts that main stores are queued from `m:` candidates without any checkout check (`:832-834`) (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:829-847`

---

## Claim 17b: U2b bullet — "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too) and a PATH main lacks or stores as a blob (a link or gitlink there answers 1)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the MEMO-hit skip, the 1 at a link or gitlink PATH, and a blob PATH being answered by the checkout's shape. On safety, a blob PATH whose checkout holds a searchable directory is memoized `d`, the same treatment ancestors that ENT holds as blobs already get (`:749` tests link and gitlink modes only), so it opens nothing 21b35ebf did not. That is safe only under the bullet's clean-worktree duty.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "It does not establish that a blob PATH whose checkout holds a directory is a safe input (Escalations)" · r3: "A PATH main stores as a blob answers by the checkout's shape alone, exactly as 21b35ebf did … That answer is safe only under the first duty: a dirty checkout holding a directory where main stores a blob gets that directory memoized as d" · r1+r2+r3 escalate this blob-PATH allowance (Escalations, entry 2)

A memo hit sets `st` without a mode check: `if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi` (`:746`). The PATH guard `[[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1` (`:743`) refuses only link and gitlink modes. The fuzz in Claim 9 found no difference from 21b35ebf for blob-mode PATHs (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:741-760`, `/tmp/u2a3c-i4-fc2-hpCT/fuzz.log`

---

## Claim 18: lib header — "main_imports reads main's commit first and then the working tree (the checkout's start files and imported files main lacks, which can only add imports or fail it …)"

**Location:** `scripts/lib/dev-cycle-read.sh:36-39`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of working-tree access in main_imports. "Only add or fail" holds.
**Replicate verdicts:** r1=Verified · r2=— · r3=Mostly accurate
**Replicate annotations:** r1: verdicted the read order, the append-only phase (`IMPORTED_MAIN+="$i"$'\n'`, `:873`) and the `main_by_name || return 1` dependency (`:815`) as Verified; "does not establish ROOT_REAL handling beyond need_root"

Only checkout file *contents* are read after main's walk (r3): `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:840`). The working tree is still consulted before and during main's phase:
- `nul_list recs checkout_md` runs before the walk (`:825`).
- `main_checkout ent pok "$f"` stats checkout starts before the walk (`:832`).
- The import loop admits imports main lacks during phase 1 (`:877`).
- The symlink arm tests `! -L "$p"` in the checkout (`:863`).

A precise version: "lists and stats the working tree throughout, and reads checkout file contents only after main's walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:825`, `scripts/lib/dev-cycle-read.sh:832`, `scripts/lib/dev-cycle-read.sh:840`, `scripts/lib/dev-cycle-read.sh:863`, `scripts/lib/dev-cycle-read.sh:877`
**Legibility-target:** for-author

---

## Claim 19a: lib main-walk comment — "a checkout path it would walk (a start or an import main lacks) that lies under a directory main stores as a symlink or gitlink or under an unsearchable directory, or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included), or a checkout listing git prints any stderr for, fail the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:470-475`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the same rule set as Claim 14a, for the lib's own comment. It does not cover main_checkout's function comment, which does name "an ancestor that is anything else but a plain searchable directory" (`:729-730`) and is accurate.
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=—
**Replicate annotations:** r1: "does not establish the case-insensitive or submodule cases, which are listed as not covered"

Same omission as Claim 14a (r2). A path under a checkout symlinked directory (or a dangling link, or a FIFO) with nothing at the path fails, as `sl/x.md` → `failed` and T1's `sd/nx.md 1` and `dgd/x.md 1` show. The block comment's "or nothing" says that case passes. The precise version adds "or under a checkout node that is not a plain directory".

**Evidence:** `scripts/lib/dev-cycle-read.sh:471-477`, `scripts/lib/dev-cycle-read.sh:727-731`, `scripts/lib/dev-cycle-read.sh:752`, `test/scripts/build-loop-check.bats:875-876`

---

## Claim 19b: lib — "A linked worktree's .git file and files under .git are checkout files like any other."; commit 3e58eb9c — "The top-level .git special case is gone: the .git directory passes main_checkout as a plain directory, and a linked worktree's gitfile is read as a checkout file"

**Location:** `scripts/lib/dev-cycle-read.sh:476-477`; commit 3e58eb9c message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main_checkout's answer for `.git` in a linked worktree and in the main checkout, and `.git/HEAD`. Whether Claude Code reads a gitfile is Q-126's host probe and was not checked here.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** r1: rests on the deletion of the `if [[ "$p" == .git ]]` block in the branch diff (paraphrased) · r3 (on the U2a3c bullet, Claim 16): the `.git` special case is gone from the import loop

Inline runs with the lib (r2), each exit 0, with ENT and MEMO empty:
- In the worktree, `main_checkout E M .git` → `0` (a readable plain file).
- In /workspace, `.git` → `2` with memo `d`, and `.git/HEAD` → `0`.

Tests at `:411`, `:657` and `:700` pin these shapes and pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476-477`, `scripts/lib/dev-cycle-read.sh:756-761`, `test/scripts/build-loop-check.bats:411`, `test/scripts/build-loop-check.bats:657`, `test/scripts/build-loop-check.bats:700`

---

## Claim 20a: work-unit comment — "the parser's work (the candidate and comment-splice characters it scans and each resolved spelling it joins, which carries ROOT_REAL, so a longer root buys less …)"

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers emit, put and splice charging. Does not cover the uncharged scan, which the comment states separately.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r2: "A `~/` name's resolved spelling carries the home, not ROOT_REAL" (stated in its Verified scope) · r2: `scan` skips non-`@` characters uncharged (`:605`) · r1+r2: charge sites `:567`, `:582-585`, `:618` confirmed

`put` prefixes the root only for relative names (r3): `if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` and then `work += length(c)` (`:582-584`). An absolute name, and a `~/` name joined to the home at `:574-577`, is charged its own spelling, which need not carry ROOT_REAL. A precise version: "each resolved spelling it joins (a relative name's carries ROOT_REAL ...)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-600`, `scripts/lib/dev-cycle-read.sh:617-624`
**Legibility-target:** for-author

---

## Claim 20b: work-unit comment — "the unit of its per-file bound of 50,000,000, about 5 s for a many-component name"

**Location:** `scripts/lib/dev-cycle-read.sh:506-507`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers two single-file shapes run to the per-file bound on this host. Does not cover the worst shape or other hosts.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "It does not establish 5 s exactly: the time depends on shape and host, and 6,000 `a/` components reached the bound in 3.9 s here" (`./` 1.13 s, `a/../` 1.3 s) · r2: "The 'about 5 s' per bound is carried from U2a3b and was not re-measured" · r3 also covers the override row (21b35ebf) "one bound still costs about 5 s"

`bound.sh` (r3) ran `import_targets ""` with no IMPORT_WORK_LEFT, and both shapes failed at the bound (rc=1):

| Shape | Lines printed | Time to the bound |
|---|---|---|
| `@` + 12,000 × `../` | 0 | 1.13 s |
| `@` + 12,000 × `a/`, IMPORT_LEFT lifted | 3,529 | 3.93 s |

So one bound costs about 1–4 s here, depending on shape. "About 5 s" is the right order but on the high side for this host.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-600`, `/tmp/u2a3c-i4-fc3-G9S7/bound.log`, `/tmp/u2a3c-i4-fc3-G9S7/bound.sh`
**Legibility-target:** for-author

---

## Claim 20c: work-unit comment — "/workspace's walks spend about 8,100 each (2026-10-07)"

**Location:** `scripts/lib/dev-cycle-read.sh:509`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's checkout as of 22:07Z. The figure drifts with the checkout.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2: tree 8,110 and main 8,110; the worktree root gives 5,075 each · r1: /workspace was on `main` at measurement time

`wsw.sh /workspace lib-head.sh` (r3; read-only: sources HEAD's lib, wraps import_work to sum the trailer) printed `tree: ok work=8110 secs=1.15` and `main: ok work=8110 secs=1.4` (cwd `/workspace`, exit 0, 2026-10-07T22:07:18Z).

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/wsw.log`, `/tmp/u2a3c-i4-fc3-G9S7/wsw.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: "IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset or empty, and as awk reads a number otherwise: its leading digits, or 0, so the first name fails it) and IMPORT_WORK_LEFT (… Unset or empty: no trailer and only the per-file bound; otherwise read as IMPORT_LEFT is). Both walks pass numbers."

**Location:** `scripts/lib/dev-cycle-read.sh:524-529`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4's reading of `ENVIRON[...] + 0` for 14 inputs and the unset/empty/trailer rules. "As awk reads a number" is right. The gloss "its leading digits, or 0" is not: mawk reads a sign, an exponent, hex, and `inf`/`nan`. The walks are unaffected, since both pass `$((…))` integers (`:782`, `:844-846`).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r1+r3: "does not establish another awk's conversion" (r3: gawk, busybox awk) · r1: both walks' `$((… - …))` arguments are never negative because `import_work` and the `used` check keep totals at or under their maxima · r1 precise version: "its leading number as strtod reads it (sign, exponent, hex), or 0"; r3: "its leading numeric prefix (sign, decimal point, exponent; hex under mawk)" · r2: `inf`/`nan` remove the print bound (escalated, entry 8)

The code is `left = ENVIRON["IT_LEFT"] + 0` and `if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0` (`:626-627`). Executed (r2) in `/tmp/u2a3c-i4-fc2-hpCT/pl` (output 77 bytes, 11 names):
- `IMPORT_LEFT=1e3` → ok (read as 1000, not 1).
- `0x1000` → ok (read as 4096, not 0).
- `inf` and `nan` → ok, so the print cap is gone.
- `+500`, `.5e4` and `500 ` → ok.
- `5abc`, `abc`, ` 7`, `-3` and `1.5` → failed.
- empty → ok with no trailer (`ok[abcdefgh.md]`).
- `IMPORT_WORK_LEFT=inf` keeps wmax at 50,000,000 (`inf < wmax` is false).

The precise version is "as awk reads a number (a leading decimal, exponent or hex numeral, `inf`/`nan`; otherwise 0)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:520-530`, `scripts/lib/dev-cycle-read.sh:624-630`, inline runs recorded in this claim (cwd `/tmp/u2a3c-i4-fc2-hpCT/pl`)

---

## Claim 22: import_work — "strips the parser's work trailer (its last line, "/N", printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with /) from the variable OUT, and adds N to the variable TOTAL. It returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:674-683`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the strip, the charge and both failures (test at line 843), and that put's output never begins with "/". It does not establish behaviour on a non-integer trailer, which mawk never prints for integral work.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover a trailer with leading zeros, which bash would read as octal; awk's `"/" (work + 0)` never prints one"; equality with IMPORT_WORK_MAX passes · r3: the regex plus anchored match rejects a last name like `docs/123` · r1: `exit 3` in a main rule still runs END, so a failed parse also prints a trailer, but awk's status 3 makes `import_targets` return 1 first (`:672`)

`END { if (trail) print "/" (work + 0) }` (`:630`). `[[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1` (`:680`), then `(( (iw_t += iw_w) <= IMPORT_WORK_MAX ))` (`:682`). put prints `out = substr(out, length(pre) + 1)` after `index(out, pre) != 1 || length(out) <= length(pre)` returns (`:595-596`), so the output has no leading "/". The test at line 843 passes (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:595-596`, `scripts/lib/dev-cycle-read.sh:630`, `scripts/lib/dev-cycle-read.sh:672`, `scripts/lib/dev-cycle-read.sh:678-683`; `test/scripts/build-loop-check.bats:843-852`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: capped_read — "the first 4 MiB + 1 bytes of stdin … With the word drain (after git cat-file) it reads the rest, so the writer never dies of SIGPIPE … an argument, not a [[ -p /dev/stdin ]] test, which needs /proc. The drain is time the work bound does not charge"

**Location:** `scripts/lib/dev-cycle-read.sh:702-710`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte count, the three call sites and the drain condition. The suite's 4 MiB tests pass. "Claude Code skips a file over 4 MiB" is carried from main and not re-checked here. Link blobs are not read through capped_read (they go through the 4096-byte check, Claim 29).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r1: "It does not establish Claude Code's own 4 MiB limit, which is carried from main"; the drain is outside awk, so it adds nothing to `work`

The function is `head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null` (`:710`). 4194305 = 4·1024² + 1. Its callers are the tree walk (`:782`), the checkout arm (`:844`) and the blob arm with `drain` (`:846`). There is no `/dev/stdin` test anywhere in the function (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:702-710`, `scripts/lib/dev-cycle-read.sh:782`, `scripts/lib/dev-cycle-read.sh:844-847`, `/tmp/u2a3c-i4-fc2-hpCT/logs/blc-short.log`

---

## Claim 24: checkout_md — "fails when git exits nonzero or prints anything on stderr, since an unreadable directory goes unlisted with only a warning"

**Location:** `scripts/lib/dev-cycle-read.sh:714-717`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both failure conditions and the caller's `|| return 1`. It does not establish which git versions warn rather than fail on an unreadable directory.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`{ e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]`: stdout goes to fd 3 and only stderr lands in `e`, and the assignment's status is git's. The caller is `nul_list recs checkout_md || return 1` (`:825`) (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:717`, `scripts/lib/dev-cycle-read.sh:825`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25a: main_checkout comment — "MEMO … set only once its own and every higher ancestor's main mode passed (PATH's own mode is checked first: main's link or gitlink at PATH answers 1). A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT"

**Location:** `scripts/lib/dev-cycle-read.sh:719-725`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers random checkouts of depth ≤3 over names {a,b} and calls of depth 1–4, seven calls per shared MEMO. Shapes: dirs (some chmod 600), files (some 000), symlinks to dirs and files, FIFOs, absent nodes. ENT entries: 120000, 160000 or 100644 at random paths and ancestors. Does not cover deeper paths, case-insensitive file systems, root (for whom `-r`/`-x` always pass), or a MEMO shared across ENTs (excluded by contract).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "It does not establish that '2 for one absent or a plain file' names every 2 entry: entries below such an ancestor are also 2 (they are absent, or ENOTDIR under a file)" · r2: "It does not establish behaviour when a caller reuses a MEMO across ENTs (documented as unsupported)"; the PATH memo is pinned (m3 raises the realpath count to 18 and fails `-le 14`)

`fuzz.sh SEED 1500` (r3) compares HEAD's `main_checkout` with 21b35ebf's (`mc_old`), each on its own MEMO over the same call sequence. The expected HEAD code is 21b35ebf's, except 1 wherever ENT[PATH] matches `^1[26]0000$`.

| Seed | Calls | HEAD differs from 21b35ebf | Unexpected |
|---|---|---|---|
| 7 | 10,500 | 541 | 0 |
| 4242 | 10,500 | 493 | 0 |

So every difference is the intended guard. Statically, the mode check `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` runs for each ancestor before `mc_m[$c]="$st"` (`:749-754`), whatever `st` is. PATH's own mode is checked at `:743` before `mc_m[$c]=d` at `:760` (cwd `/tmp/u2a3c-i4-fc3-G9S7`, exit 0 both, 2026-10-07T22:00Z and 22:10Z).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz.sh`, `/tmp/u2a3c-i4-fc3-G9S7/fns.sh`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz-7.log`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz-4242.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25b: main_checkout comment — "main_imports calls it only for paths main lacks"

**Location:** `scripts/lib/dev-cycle-read.sh:726`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both call sites in main_imports, and the absence of any other caller (grep: `main_checkout ` appears only at `:832` and `:877` in scripts/). Does not cover future callers.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

Start loop (r3): `t:` candidates are only those with `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:826`), and `[[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f"` (`:832`). Import loop: `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:877`). So the guard at `:743` never fires for main_imports.

**Evidence:** `scripts/lib/dev-cycle-read.sh:826`, `scripts/lib/dev-cycle-read.sh:832`, `scripts/lib/dev-cycle-read.sh:877`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: main_checkout return codes — "0 for a readable plain checkout file to walk, 2 when nothing there loads (absent, below an absent ancestor or a plain file, or a plain directory), 1 to fail the walk: an ancestor main stores as a link or gitlink, an ancestor that is anything else but a plain searchable directory, an unreadable plain file, ENT or MEMO not an associative array, or anything else at PATH"

**Location:** `scripts/lib/dev-cycle-read.sh:727-731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every listed shape via T1, test 65 and the fuzz. The does-not-cover limits are as in Claim 25a.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r2 (on Claim 19a): this function comment "does name 'an ancestor that is anything else but a plain searchable directory' (`:729-730`) and is accurate"

T1 (`test/scripts/build-loop-check.bats:854-880`) passes at HEAD, including `ent-indexed 1` and `memo-indexed 1` (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `test/scripts/build-loop-check.bats:854-880`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: "${x@a} on an empty array is an unbound-variable error under set -u … ${x[0]@a}, not ${x@a}, which costs time linear in the array's size"

**Location:** `scripts/lib/dev-cycle-read.sh:737-741`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both statements and the restoration of `set -u` on return. It does not establish bash versions other than 5.2.15.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The set -u error itself was not re-executed here; `set +u` precedes both expansions, so the point is moot at HEAD" · r1+r3: under `set -u` without `+u`, `${x[0]@a}` also errors on an empty array or one lacking key 0, so the local `set +u` (restored by `local -`, `:736`) is load-bearing

`bash -c 'set -u; declare -A e=(); echo "[${e@a}]"'` fails with `e: unbound variable` (r1). Under `set -u`, `${e[0]@a}` also fails for an empty array, and for any array lacking key 0 (`e[0]: unbound variable`), so `set +u` before the test is load-bearing. It is in place, `set +u; [[ "${mc_e[0]@a}" == *A* …` (`:741`), and `local -` restores the options. After a call, `$-` is `ehuBc` and an unset variable still errors. Cost: Claim 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:736-741`; `/tmp/u2a3c-i4-fc1-PaRf/attr.sh`, `/tmp/u2a3c-i4-fc1-PaRf/t.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: "Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:806-807`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop's handoff and the arm choice. It does not establish ordering among phase-2 items.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`while [[ ${#queue[@]} -gt 0 || ${#tq[@]} -gt 0 ]]; do [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:839-840`). `case "${ent[$f]-checkout}" in checkout) out="$(capped_read < "$f" | …` (`:843-844`) (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:839-846`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: "Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below."

**Location:** `scripts/lib/dev-cycle-read.sh:849-850`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 4,097-byte link blob on main. Does not cover a link blob exactly 4,096 bytes long (allowed by `-le 4096`, although the kernel's limit is 4,095).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish Claude Code's own limit" · r1 verdicted the same shim test on the test file (Claim 33)

The cat-file shim test passes at HEAD (r3). On mutant m1 (the `-s` check removed), the walk reads the blob and passes (`walk: ok`, `link blob read` on both iterations), so the test fails.

- Command: `./runwith.sh lib-m1-nosize.sh 'U2a3c' at-m1-nosize.log`
- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit code: 1 (only test 21 of the filter fails), 2026-10-07T22:12Z

**Evidence:** `scripts/lib/dev-cycle-read.sh:849-855`, `test/scripts/build-loop-check.bats:944-956`, `/tmp/u2a3c-i4-fc3-G9S7/at-m1-nosize.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: test 54 comment and cap — "Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (10 at 2fbd929b; 18 without its memo of a prefix candidate's own directory)"; cap `-le 14`

**Location:** `test/scripts/build-loop-check.bats:822-832`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 74, 10 and 18, and that the cap of 14 fails 21b35ebf. It does not establish the 102 figure, which belongs to an unmemoized mutant that was not rebuilt.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the "102 unmemoized" figure was not re-run · r2+r3: the no-PATH-memo mutant gives 18 and fails `-le 14`, so the cap pins the PATH memo

Command `bash t54.sh` (r1; realpath shim, fixture under the scratch dir, 22:02:52Z, exit 0): HEAD 10, the no-PATH-memo mutant 18, 3a35c8b9 10, 2fbd929b 10, 21b35ebf 18, 3e58eb9c 74 (`t54.log`). Test 54 fails at 21b35ebf with HEAD's test file (`old-21b35ebf.log`).

**Evidence:** `test/scripts/build-loop-check.bats:821-833`; `/tmp/u2a3c-i4-fc1-PaRf/t54.log`, `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: T1 title — "memoizes plain searchable directories as d and absent or plain-file ancestors as 2"

**Location:** `test/scripts/build-loop-check.bats:854`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the printed MEMO `d=d f.md=2 nd2/m=2 nd2=2 nd=2` (`:880`). Does not establish that T1 pins the PATH memo: on m2, T1 still passes, because `d` is memoized as an ancestor of `d/r.md` first. Test 54's count pins it (Claim 30).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "It does not establish a PATH-level guard pin (Claim 3b)"; T1 fails at 21b35ebf · r2: "`nd2/m=2` is an absent ancestor below an absent one, which the title's 'absent' covers"

The test prints `echo "$k=${M[$k]}"` for every key and expects `memo d=d f.md=2 nd2/m=2 nd2=2 nd=2` (`:861`, `:880`) (r1, r3). It passes at HEAD; on r3's m2 mutant (PATH memo removed) T1 still passes (`at-m2-nopathmemo.log`).

**Evidence:** `test/scripts/build-loop-check.bats:854-880`, `/tmp/u2a3c-i4-fc3-G9S7/at-m2-nopathmemo.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: T3 — "The caps derive from w: each candidate is charged its resolved spelling, so w grows with the fixture root."

**Location:** `test/scripts/build-loop-check.bats:907-909`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason and the fix under 22- and 76-character TMPDIRs. It does not establish which arm mutants it kills (not re-run here).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not establish the comment's 'each candidate' for `~/` names, whose spelling carries the home instead" · r3: "Does not cover a fixture with an absolute name (Claim 20a)"; the four top-level fixture files are all relative names

put charges `length(c)` after prefixing `root "/" dir "/"` (`scripts/lib/dev-cycle-read.sh:582-585`). The old fixed cap fails from TMPDIR length 28 (Claim 4), and the HEAD test passes at 22 and 76 (r1).

**Evidence:** `test/scripts/build-loop-check.bats:898-914`; `scripts/lib/dev-cycle-read.sh:582-585`; `/tmp/u2a3c-i4-fc1-PaRf/t3.log`, `/tmp/u2a3c-i4-fc1-PaRf/blc-long.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33: test 63 — "A git shim logs each `git cat-file blob` object name: the long link must fail with no read of its blob."

**Location:** `test/scripts/build-loop-check.bats:944-956`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test kills the no-size-cap mutant and passes at HEAD. It does not establish what a `git` reached by an absolute path would do, since the shim only intercepts lookups through PATH.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "At 3a35c8b9 it passes (it pins behaviour 2fbd929b added, not a 4b7f2357 fix)" · r3 ran the same mutant against the lib comment (Claim 29)

Mutant (r1; cwd `$S/repo`, `sed` deletes `:850`'s `git cat-file -s` line, 22:03Z): the test fails with `walk: ok / link blob read / walk: ok / link blob read`. Without the cap, the 4,097-byte link text is read and the walk succeeds. The same mutant result appears in 21b35ebf's run (`old-21b35ebf.log`, test 63).

**Evidence:** `scripts/lib/dev-cycle-read.sh:848-850`; `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 34: test 64 — "Linear work gives a ratio of about 4 (4.0 at 3a35c8b9); 21b35ebf's top-down rescan of every absent ancestor gives about 16 (15.6). A count, so no host is fast enough to hide it."

**Location:** `test/scripts/build-loop-check.bats:958-971`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD, 3a35c8b9 and 21b35ebf, and the test's failure at 21b35ebf. It does not establish that the test catches the `${x@a}` regression: xtrace counts commands, not their cost, so 3a35c8b9 passes it (that case is test 66's).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1+r2+r3: the test does not catch D1 (`${x@a}`); it passes at 3a35c8b9 (r3: and on the `${x@a}` mutant m4); the many-token test is D1's only guard (escalated, entry 3)

Command `bash xt.sh` (r1; 22:01:48Z, exit 0): HEAD 4,901 → 19,601 (4.0), 3a35c8b9 4,701 → 18,801 (4.0), 21b35ebf 72,704 → 1,130,804 (15.55) (`xt.log`). With HEAD's file, test 64 fails at 21b35ebf (`old-21b35ebf.log`).

**Evidence:** `test/scripts/build-loop-check.bats:958-971`; `/tmp/u2a3c-i4-fc1-PaRf/xt.log`, `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 35: test 65 — "main_checkout refuses a PATH main stores as a link or gitlink, so a plain checkout directory there never passes a path below it"

**Location:** `test/scripts/build-loop-check.bats:973-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four rows at HEAD and the failure at 3a35c8b9 (the fail-open) and 21b35ebf (`l 2`). It does not establish a pin separating the link-only guard from a PATH-wide one (Claim 3b).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "It does not cover a PATH that main stores as a link whose checkout holds a file" · r3: "Does not cover a gitlink or link PATH that the checkout holds as a file (the fuzz covers it: Claim 25a)" · r2+r3: the guard-removed mutant (r2 m5, r3 m3) fails it

HEAD: `l 1 / l/f.md 1 / g 1 / g/f.md 1`. 3a35c8b9: `l 2 / l/f.md 0 / g 2 / g/f.md 0`. 21b35ebf: `l 2 / l/f.md 1 / g 2 / g/f.md 1` (r1, `old-*.log`).

**Evidence:** `test/scripts/build-loop-check.bats:973-980`; `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`, `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 36: test 66 — "stays near linear in the number of import tokens main lacks … about 2.5 s here; at 3a35c8b9 … (44.6 s), so this catches it on hosts up to about 2x faster"

**Location:** `test/scripts/build-loop-check.bats:982-991`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timings, the 2x margin, and linearity at 1k-8k tokens. It does not establish freedom from flakes on a host more than about 8x slower (2.4 s against a 20 s timeout). The test itself checks only the timeout, not linearity.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "On a host about 6x slower than this one, HEAD would approach the 20 s timeout, a possible flake on loaded CI" (HEAD 3.5 s under bats) · r3: "a false red needs a host about 8x slower, or heavy parallel load. Not observed in the four HEAD runs here" · r2, r3 confidence Medium; r1 High

The timings and margin are as in Claim 2 (r1). Scaling at HEAD (`many-scale.log`): 1,000 tokens 0.61 s, 2,000 1.21 s, 4,000 2.41 s, 8,000 4.83 s, which is linear.

**Evidence:** `test/scripts/build-loop-check.bats:982-991`; `/tmp/u2a3c-i4-fc1-PaRf/many.log`, `/tmp/u2a3c-i4-fc1-PaRf/many-scale.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 37: dev-cycle.bats inventory lists `md_ls checkout_md main_checkout lower_all capped_read import_work` as functions the lib defines

**Location:** `test/scripts/dev-cycle.bats:1107`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the functions' existence. The inventory test is not a behaviour test.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

dev-cycle 78/78 passes, and each name is defined, e.g. `main_checkout() {` (`scripts/lib/dev-cycle-read.sh:735`) (r3).

**Evidence:** `test/scripts/dev-cycle.bats:1105-1110`, `/tmp/u2a3c-i4-fc3-G9S7/dev-cycle.bats.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 38: Commit 27364085 — "a mutant without the drain fails the 4 MiB test (walk failed)"

**Location:** commit 27364085 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers HEAD's `drain` arg, removed from the blob arm (m6). 27364085's own `-p /dev/stdin` drain was not re-run.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

m6 fails "main walk reads only the first 4 MiB + 1 ..." (`at-m6.log`, exit 1) (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:846`, `/tmp/u2a3c-i4-fc3-G9S7/at-m6.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 39: Commit 2fbd929b — "performance F1: D=1000 took 10.7 s at 21b35ebf, 0.6 s now, main 0.5 s"

**Location:** commit 2fbd929b message
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers one absent token D=1000 levels deep (`deep2.sh 1000 <lib> absent`, started 2026-10-07T22:24:05Z) on this host: HEAD (same main_checkout as 2fbd929b plus the guard and `[0]@a`), 21b35ebf and main.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "21b35ebf's 10.7 s was not re-run for the absent case; its 15.6x command ratio … is consistent with it"; HEAD 0.61 s

HEAD 0.6 s, 21b35ebf 10.2 s, main 0.5 s, all `ok` (`logs/deep-absent.log`) (r2).

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/deep2.sh`, `/tmp/u2a3c-i4-fc2-hpCT/logs/deep-absent.log`

---

## Claim 40: Commit 380ed01b — "Merged fact-check (64 clusters, 1 Incorrect, agreement 78.1%), five critic reports, Stage 2.5 submitted claims (at 4b7f2357)"

**Location:** commit 380ed01b message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merged report's header counts and the files the commit adds. It does not establish the agreement metric's inputs beyond 50/64.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "The merge's arithmetic was not re-derived" · r3: "Does not re-verdict the merged claims"; the previous merged report's body reads "Agreement rate: 78.1% (50/64)" (its line 1253) · all three read the previous merged report, which this file now replaces (it is in git history)

The merged report header reads `**Total claims checked:** 64` and `**Summary:** 41 verified, 14 mostly accurate, 2 stale, 1 incorrect, 6 unverifiable`, and its `**Verdict:**` lines tally the same. 50/64 = 78.125%. The commit adds five `*-final.md` critic reports and `code-fact-check-submitted-claims-build-loop-u2a3c.md` (`Commit: 4b7f2357`) (r1).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md:1-10` (as of 380ed01b); `docs/reviews/code-fact-check-submitted-claims-build-loop-u2a3c.md:1-8`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 41a: Commit 4b7f2357 — "main_checkout answers 1 when main stores PATH as a link or gitlink, before a checkout directory there is memoized as d … main_imports never passes such a PATH."

**Location:** commit 4b7f2357 message
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard's position before the memo write and the 3a35c8b9 fail-open (`l/f.md 0`). Reachability is static (Claim 25b).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "Does not cover future callers" (its claim joins this with lib `:726`)

The guard is at `:743`, before any write at `:754` or `:760`. At 3a35c8b9 the precondition test shows `l/f.md 0` (admitted under main's link) (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:743`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-pre-3a35.log`

---

## Claim 41b: Commit 4b7f2357 — "(performance F1: 4,000 deep tokens 44.6 s at 3a35c8b9, 2.5 s now, main 0.9 s). Test added; it fails at 3a35c8b9."

**Location:** commit 4b7f2357 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this host's 39.1 / 2.3 / 0.9 s and the test failing at 3a35c8b9. Exact seconds vary by host.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** measured 3a35c8b9 / HEAD / main: r1 41.93 / 2.44 / 0.92 s; r2 39.1 / 2.3 / 0.9 s; r3 42.33 / 2.34-2.51 / 0.90 s

See Claims 2 and 36 (r2).

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-many-3a35.log`

---

## Claim 41c: Commit 4b7f2357 — "T3's caps derived from w (it failed under a TMPDIR over ~27 characters)"; "66/66 under a 17- and a 74-character TMPDIR; 78/19/2"

**Location:** commit 4b7f2357 message
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed number and statement (Claims 1a, 4). It does not establish the exact TMPDIR lengths 17 and 74, for which 22 and 76 were used.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: used 22- and 73-character TMPDIRs · r3: "Does not cover the exact 17/74-character runs"; used 23, 86 and 182

All reproduced, as cited in the claims named in Scope (r1).

**Evidence:** `/tmp/u2a3c-i4-fc1-PaRf/t3.log`, `/tmp/u2a3c-i4-fc1-PaRf/blc-short.log`, `/tmp/u2a3c-i4-fc1-PaRf/blc-long.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 41d: Commit 4b7f2357 — "a host-independent xtrace-count test for the deep-token cost, a cat-file shim pinning that link text over 4096 is never read, the PATH memo pinned, T1 prints the whole MEMO, the precondition test"

**Location:** commit 4b7f2357 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each test's target mutant or old lib (Claims 29, 30, 31, 34, 35). "The PATH memo pinned" is pinned by test 54's realpath count, not by T1. The xtrace test covers the i2 deep-absent regression, not D1.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "The PATH memo pin is the realpath bound tightened from 30 to 14, which the message does not spell out" (diff `3a35c8b9..4b7f2357 -- test/` changes `[ "$n" -le 30 ]` to `[ "$n" -le 14 ]`)

Each named test fails on the mutant or old lib it targets and passes at HEAD (r3; paraphrased — no quote available because the mapping spans five tests and their logs, cited in the claims above).

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/at-m1-nosize.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m2-nopathmemo.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m3-noguard.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-21b3.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 41e: Commit 4b7f2357 Notes — "the many-token test's 20 s timeout catches the regression only on hosts up to about 2x faster than this one"

**Location:** commit 4b7f2357 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 39-44.6 s against 20 s margin and the xtrace test's power against 21b35ebf. "The deep case" means the top-down rescan, not D1; the xtrace test passes at 3a35c8b9.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=—
**Replicate annotations:** r1: margin from 41.93 / 20 ≈ 2.1

See Claims 34 and 36 (r2).

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-21b3.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-3a35.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`

---

## Claim 41f: Commit 4b7f2357 Notes — "the xtrace test covers the deep case host-independently"

**Location:** commit 4b7f2357 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the 39-44.6 s against 20 s margin and the xtrace test's power against 21b35ebf. "The deep case" means the top-down rescan, not D1; the xtrace test passes at 3a35c8b9.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: "The xtrace test covers the i2 deep-absent regression, not D1"

See Claims 34 and 36 (r2).

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-21b3.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-xt-3a35.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/manytoken-timing.log`

---

## Claim 42: Commit 61e2e734 — "Measured 2026-10-07: /workspace's walks spend about 8,100 each (1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout, which failed closed before U2a3c)."

**Location:** commit 61e2e734 message
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers today's /workspace checkout with HEAD's lib: work 8,110 each, tree 1.0 s, main 1.2 s, both `ok`. "Failed closed before U2a3c" was not re-run.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "The figure drifts with the checkout"; r3 measured tree 1.15 s, main 1.4 s

See Claim 20c (r2).

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/workspace-work.log`

---

## Claim 43: Commit 80cc6224 — "A test's realpath count: 18, against 102 unmemoized and 74 at 3e58eb9c."

**Location:** commit 80cc6224 message
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers 18 (21b35ebf, whose `main_checkout` is byte-identical to 80cc6224's: `diff` of the two functions printed `same`) and 74 at 3e58eb9c. The 102 figure was not re-run.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

r2: realpath counts as in Claim 30.

**Evidence:** `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-21b3.log`, `/tmp/u2a3c-i4-fc2-hpCT/logs/mut-cnt-3e58.log`

---

## Claim 44: Commit 80cc6224 — "${x@a} on an empty associative array is an unbound-variable error under set -u"

**Location:** commit 80cc6224 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the `set -u` error. 21b35ebf's 10.7 s (the other half of the replicate's compound claim) is merged into Claim 39.
**Replicate verdicts:** r1=— · r2=— · r3=Verified (compound) · single-replicate detection
**Replicate annotations:** r1 (on lib `:737-741`, Claim 27) reproduced the same error

`bash -c 'set -u; declare -A a=(); echo "[${a@a}]"'` printed `a: unbound variable` (r3).

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/attr.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`): a PATH-wide "any ENT path" guard does not break T1 (the broad mutant passes 66/66), because T1 never passes an ENT path as PATH. Only an ancestor-wide guard breaks T1's `f.md/x.md` row. Drop the reason or say "if applied to ancestors". This is history prose, so the fix is a correction note. (All three replicates.)

### Stale
- None.

### Mostly Accurate
- **Claim 5** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`): "Test 77" is build-loop-check test 4 ("a working-tree edit does not count"). Cite the test by its title. (r3; r1 read it as a line number.)
- **Claim 14a** (`docs/working/known-issues-dev-cycle.md:18`): A5's fail list omits a path under a non-plain checkout ancestor (symlinked directory, dangling link, FIFO), which fails even with nothing at the path. Fails closed. (r2.)
- **Claim 15** (`docs/working/plan-build-loop-handoff.md:126`): F11's caller-contract parenthetical leaves out the clean-worktree duty and `LC_ALL=C`; its admission list has the same non-plain-ancestor omission as A5. (r1, r2.)
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:36-39`): main_imports lists and stats the working tree before and during main's walk; only checkout file contents are read after it. (r3.)
- **Claim 19a** (`scripts/lib/dev-cycle-read.sh:470-475`): the block comment's "or nothing" passes a case that fails (nothing at a path under a checkout link or FIFO ancestor). main_checkout's own comment (`:729-730`) is accurate. (r2.)
- **Claim 20a** (`scripts/lib/dev-cycle-read.sh:504-506`): only a relative name's resolved spelling carries ROOT_REAL; absolute and `~/` names do not. (r3.)
- **Claim 20b** (`scripts/lib/dev-cycle-read.sh:506-507`): one per-file bound costs about 1-4 s here (1.1 s for `../`, 3.9 s for `a/`), not about 5 s. (r3.)
- **Claim 21** (`scripts/lib/dev-cycle-read.sh:524-529`): "its leading digits, or 0" understates awk's conversion, which reads sign, decimal point, exponent, hex (mawk) and `inf`/`nan`. (All three replicates.)

### Unverifiable
- **Claim 1b** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:82`): the full health check was not run, because it runs the full test runner; its shellcheck gate was run (Claim 1a). (r1.)

## Escalations

1. **No test separates the link/gitlink-only PATH guard from a PATH-wide guard.** `scripts/lib/dev-cycle-read.sh:743`, `test/scripts/build-loop-check.bats:854-883`. A PATH-wide mutant passes 66/66, so a blob PATH answering by the checkout's shape is unpinned. Raised by: r1. Addressee: **test-strategy**.
2. **The U2b bullet lets a second caller pass a blob PATH.** `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:743`. With a plain searchable checkout directory there, main_checkout memoizes PATH as d and later admits checkout files below it. This is not a regression (it matches 21b35ebf) and main_imports cannot reach it. Its safety rests on the clean-worktree-at-MAIN_SHA duty. The open question: is that precondition meant to stand in for a mode check, should the link be stated, or should main_checkout refuse a blob PATH that the checkout holds as a directory? Raised by: r1 (security-reviewer), r3 (api-consistency-reviewer / security-reviewer); r2 records the same residue in Claim 17b's Scope without routing it. Addressee: **security-reviewer**, **api-consistency-reviewer**.
3. **D1 (`${x@a}`'s linear cost) has only a timing guard.** `test/scripts/build-loop-check.bats:958-971`, `test/scripts/build-loop-check.bats:982-991`. Test 64's xtrace count cannot catch it: 3a35c8b9 and the `${x@a}` mutant both pass. Only test 66's 20 s timeout guards it, with about a 2x margin, so it goes blind on a host about 2x faster. A count-based guard would make it host-independent. Raised by: r1, r2, r3. Addressee: **test-strategy**.
4. **The many-token test can flake on a slow host.** `test/scripts/build-loop-check.bats:982-991`. At HEAD it runs 2.3-3.5 s against `timeout 20`, so a host or CI runner about 6x slower (r2) or about 8x slower (r1, r3, in Scope only) would go red falsely. Raised by: r2. Addressee: **test-strategy**.
5. **The differential fuzz could be kept as a property test.** `scripts/lib/dev-cycle-read.sh:735-762`. It ran 12,000 random-order calls with 0 unintended differences, and found 62 differences against 2fbd929b. Raised by: r2. Addressee: **test-strategy**.
6. **F11's caller-contract parenthetical has drifted from A5 and the U2b bullet** (Claim 15). `docs/working/plan-build-loop-handoff.md:126`. That makes three statements of one contract, as override row 459 anticipates. Raised by: r1. Addressee: **api-consistency-reviewer**.
7. **The written fail rules omit one refusal** (Claims 14a, 15, 19a). `scripts/lib/dev-cycle-read.sh:471-475`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`. The lib block comment, A5 and F11 leave out main_checkout's refusal of any path under a non-plain checkout ancestor, even when nothing is at the path. The code fails closed and T1 pins it, so there is no exposure; this is a docs-precision item for whoever owns A5. Raised by: r2. Addressee: **security-reviewer**.
8. **`IMPORT_LEFT` accepts more than the comment's "leading digits"** (Claim 21). `scripts/lib/dev-cycle-read.sh:524-529`. A direct caller passing `IMPORT_LEFT=inf` or `nan` gets no print bound, and `1e3` and `0x…` read as numbers. Neither walk can reach this (both pass `$((…))`). Informational. Raised by: r2. Addressee: **api-consistency-reviewer**.
9. **The rubric D2 author note gives a reason that does not hold for a PATH-level guard** (Claim 3b). `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`. It is history prose, so a correction note in the next rubric section or an override correction row would close it. Raised by: r2, r3 (orchestrator); r1 routed the same claim to test-strategy/security-reviewer in its Goal-Alignment `Escalate:` line (see entry 1). Addressee: **orchestrator**.
10. **Nothing new for performance-reviewer.** `docs/reviews/override-log.md:458`. Row 458's D³ mechanism reproduces (r1: HEAD 11.7 s, 21b35ebf 31.5 s, main over 150 s at D=1000). r2 measured 3.8-5.7x growth per doubling at D ≤ 1000. Informational; no action requested. Raised by: r1, r2. Addressee: **performance-reviewer**.

## Verdict stability

- **Total clusters:** 58 (counted at sub-claim granularity).
- **Agreed** (every replicate that surfaced the cluster gave the same verdict): 51. Of these, 11 were surfaced by only one replicate (Claims 1b, 6, 7a, 8, 24, 26, 28, 37, 38, 43, 44), so they agree trivially.
- **Disagreed:** 7.
  - Claim 5 (rubric:95, D4 test 77): r1=Verified · r2=— · r3=Mostly accurate
  - Claim 14a (A5 fail list): r1=Verified (compound) · r2=Mostly accurate · r3=Verified
  - Claim 15 (F11): r1=Mostly accurate · r2=Mostly accurate · r3=Verified
  - Claim 18 (lib:36-39): r1=Verified · r2=— · r3=Mostly accurate
  - Claim 19a (lib:470-475): r1=Verified (compound) · r2=Mostly accurate · r3=—
  - Claim 20a (lib:504-506): r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
  - Claim 20b (lib:506-507): r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
- **Agreement rate:** 51/58 = 87.9%. Counting only the 47 clusters that two or more replicates surfaced, it is 40/47 = 85.1%.
- Every disagreement is Verified against Mostly accurate, with a single replicate finding a precision gap. The one Incorrect (Claim 3b) and the one Mostly accurate that all three replicates reported (Claim 21) were unanimous.
