Commit: 380ed01b
# Code Fact-Check Report

**Commit:** 380ed01b
**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` at 380ed01b (last code commit 4b7f2357) plus the commit messages of main..HEAD: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2b), `docs/reviews/override-log.md` (rows 457-460 added in 4b7f2357), and the factual claims about the code in the rubric's "Iteration 3 of 3" section. Other `docs/reviews/*u2a3c*` files are history and were not verdicted. Replicate fc1 of 3 (final confirming pass).
**Checked:** 2026-10-07
**Total claims checked:** 35
**Summary:** 31 verified, 2 mostly accurate, 0 stale, 1 incorrect, 1 unverifiable

Hallucination-pattern log read (`docs/reviews/hallucination-patterns.md`). Three entries are test counts or measured values quoted from an artifact set. Every count and timing on this branch was re-run (suites, `grep -c '^@test'`, timings, xtrace counts, realpath counts). None matches a logged pattern. The one Incorrect (Claim 3b) is a wrong prediction about a test, not a fabricated symbol, so it is not logged.

**Execution provenance (all executed claims).** Scratch dir `/tmp/u2a3c-i4-fc1-PaRf/` (scripts `*.sh`, logs `*.log`). The brief allows only this report to be written in the worktree, so the logs stay in the scratch dir and are not copied to `docs/reviews/execution-logs/`. Old libs come from `git show <rev>:scripts/lib/dev-cycle-read.sh` (`lib-<rev>.sh`). Suites against old libs and mutants ran in `$S/repo`, a `git archive HEAD` copy. Host: bash 5.2.15, mawk 1.3.4, uid 1000 (not root, so the chmod cases are real). All runs were on 2026-10-07 between 21:57 and 22:09 UTC.

Suites at HEAD (cwd `/workspace/.claude/wt-build-loop-u2a3c`, `LC_ALL=C bats ...`):
- build-loop-check: 66/66, exit 0, under a 22-character TMPDIR (`blc-short.log`, 21:57:49Z) and a 76-character one (`blc-long.log`, 21:58:13Z).
- dev-cycle: 78/78, exit 0. build-loop-read: 19/19, exit 0. fixture-hermeticity: 2/2, exit 0 (`dev-cycle.bats.log`, `build-loop-read.bats.log`, `fixture-hermeticity.bats.log`, 21:58:38Z).

---

## Claim 1a: "Tests after fixes (4b7f2357): build-loop-check 66/66 under a 17- and a 74-character TMPDIR, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:82`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every suite count at HEAD (whose code equals 4b7f2357's) under a 22- and a 76-character TMPDIR, and shellcheck at the project's gate severity. It does not establish the exact 17- and 74-character runs, or a default-severity shellcheck, which reports SC2004, SC2015 and SC2016 info/style notes (main's lib is also non-clean at that severity).

Executed: the four suites gave 66/66, 78/78, 19/19 and 2/2, all exit 0 (see header). `shellcheck -S warning scripts/lib/dev-cycle-read.sh` exited 0, which matches the health check's own invocation: `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:480`). A bare `shellcheck` exits 1 on info/style notes only.

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

Execution required but not run. Gate 5 runs the whole test runner (paraphrased — no quote available because the gate spans `scripts/health-check.sh:354-410` and calls `run-tests.sh`), and this replicate ran the four in-scope suites instead.

**Evidence:** `scripts/health-check.sh:354-410`, `scripts/health-check.sh:427-480`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 2: D1 — "4,000 deep absent tokens: 44.6 s here … `${x[0]@a}` is O(1) and gives the same answers (empty, large, indexed, scalar, unset checked). 2.5 s now, main 0.9 s. A 20 s-timeout test fails at 3a35c8b9 (it catches on hosts up to ~2x faster)."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:92`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three timings on this host, the type answers for the eight variable shapes probed, O(1) against linear cost, and test 66 failing at 3a35c8b9. It does not establish the critic's 85 s run or the 50k-entry-tree figures, which were not re-run.

Command `bash many.sh 4000` (cwd: a fresh fixture repo under the scratch dir, 22:00:54Z, exit 0): `HEAD ok 2.44`, `3a35c8b9 ok 41.93`, `main ok 0.92` (`many.log`). 41.93 / 20 ≈ 2.1, which gives the "~2x". Type answers (`attr.sh`) are identical for `${r[0]@a}` and `${r@a}` through a nameref: empty assoc `A`, 1,000-key assoc `A`, assoc with key 0 `A`, declared-unset assoc `A`, `-iA` `Ai`, `-rA` `Ar`, indexed and empty indexed `a`, scalar and nonexistent ``. Cost (`t.sh`, 2,000 checks): `[0]@a` took 0.004 s at 100, 10,000 and 40,000 keys, while `@a` took 0.011 s, 2.176 s and 9.139 s. With the HEAD test file, 3a35c8b9's lib fails test 66 with status 124, a timeout (`old-3a35c8b9.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:741`; `/tmp/u2a3c-i4-fc1-PaRf/many.log`, `/tmp/u2a3c-i4-fc1-PaRf/attr.sh`, `/tmp/u2a3c-i4-fc1-PaRf/t.sh`, `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3a: D2 — "main_checkout memoized a checkout directory at PATH as d without checking ENT[PATH] … (and `x.md` main stores as a gitlink answered 0). Unreachable from main_imports … Fixed (4b7f2357) … Guard: main's link or gitlink at PATH answers 1"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 3a35c8b9's PATH memo, the guard at HEAD, and both main_imports call sites. It does not establish safety for a PATH main stores as a blob (Claim 22 and Escalations).

3a35c8b9 has no PATH mode check before its final shape tests. HEAD adds one:

```bash
# scripts/lib/dev-cycle-read.sh:743
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
```

Both main_imports calls are guarded by absence from `ent`: `[[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f"` (`:833`, where a `t:` candidate is added only when `[[ -n "${ent[$f]+set}" ]]` fails, `:826`) and `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:877`). Test 65 at 3a35c8b9 prints `l 2 / l/f.md 0 / g 2 / g/f.md 0`, which is the fail-open case. At HEAD it prints `l 1 / l/f.md 1 / g 1 / g/f.md 1` (`old-3a35c8b9.log`, `blc-short.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `:826`, `:833`, `:877`; `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 3b: D2 author note — "a broad "any ENT path" guard would break T1's blob row"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers a PATH-only broad guard and an ancestor-only broad guard, each run against the full HEAD test file. It does not establish whether the author meant a guard over ancestors, which is the one reading under which the note holds.

T1 never calls main_checkout with a PATH that its ENT holds. Its ENT is `declare -A E=([lnk]=120000 [gl]=160000 [nd2/m/l]=120000 [f.md]=100644)` and its PATH list is `d/r.md nx.md nd/x.md f.md/x.md d u d/n.md sf.md dg.md sd ff.md u/x.md sd/nx.md dgd/x.md lnk/x.md gl/x.md nd2/m/l/x.md` (`test/scripts/build-loop-check.bats:858-859`). A PATH guard that refuses any ENT path cannot reach the `f.md` blob row.

Executed: the mutant replacing `:743` with `[[ -z "${mc_e[$3]+set}" ]] || return 1` passes all 66 tests (`broad.log`, exit 0). Only a broad guard applied to ancestors (`:749` → `[[ -z "${mc_e[$c]+set}" ]] || return 1`) breaks T1, at `f.md/x.md 1`. The stated reason for the narrow form is therefore not something T1 pins, and no test separates the narrow guard from the PATH-wide one (Escalations).

**Evidence:** `test/scripts/build-loop-check.bats:854-883`; `scripts/lib/dev-cycle-read.sh:743`, `:749`; `/tmp/u2a3c-i4-fc1-PaRf/broad.log`
**Legibility-target:** for-author

---

## Claim 4: D3 — "Test 59 (T3) fixed IMPORT_WORK_MAX=1000 while w grows with the fixture root's length: red under a TMPDIR over ~27 characters … Caps derived from w"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 3a35c8b9's test 59 at TMPDIR lengths 22-40 and the HEAD test at 22 and 76. It does not establish the threshold on a bats version with a differently sized run directory.

Command `bash t3.sh` (cwd `/tmp/u2a3c-i4-fc1-PaRf/repo3a`, a `git archive 3a35c8b9` copy, 22:02:07Z, exit 0). It passes at lengths 22, 25, 26 and 27, and fails at 28, 29, 30 and 40 (`t3.log`). HEAD derives the caps from w: `m=$((10 * w)); IMPORT_WORK_MAX=$m` (`test/scripts/build-loop-check.bats:909`), and passes under both TMPDIRs.

**Evidence:** `test/scripts/build-loop-check.bats:898-914`; `/tmp/u2a3c-i4-fc1-PaRf/t3.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 5: D4 — "the walk reads main's blob for every path main stores, so an edited tracked instruction file's imports go unread (test 77 pins this as intended)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read arm chosen for a path in `ent` and the test at line 77 (bats test 4, so "test 77" is a line number). It does not establish U2b's enforcement, which is not built.

The arm is chosen by `case "${ent[$f]-checkout}" in`, and a stored blob reads `git cat-file blob "$MAIN_SHA:$f"` (`scripts/lib/dev-cycle-read.sh:843-846`). The test at `test/scripts/build-loop-check.bats:77` edits the checkout's instruction file to `printf 'Rules: @docs/wt-only.md\n' > CLAUDE.md` and expects `docs/wt-only.md` to be `-` (`:83-88`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:843-846`; `test/scripts/build-loop-check.bats:77-96`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 6: E2 — "A deep token through directories the checkout holds still costs about D³ in realpath (D=1000: 14 s; 21b35ebf 34 s; main over 120 s)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:102`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the three timings at D=1000 on this host. It does not establish the D³ exponent, which was not fitted (one D only), and the HEAD and 21b35ebf runs shared the CPU with a concurrent bats run, so they may be inflated.

Command `bash deep.sh 1000 "HEAD 21b35ebf"` (fixture under the scratch dir, 22:05:06Z, exit 0): `HEAD ok 11.67`, `21b35ebf ok 31.51` (`deep.log`). `bash deep.sh 1000 main` (22:06:40Z): main had not finished at 150.28 s and was killed by `timeout 150` (`deep-main.log`).

**Evidence:** `/tmp/u2a3c-i4-fc1-PaRf/deep.sh`, `/tmp/u2a3c-i4-fc1-PaRf/deep.log`, `/tmp/u2a3c-i4-fc1-PaRf/deep-main.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 7: Confirmed Good — "For PATHs ENT lacks, main_checkout returns 21b35ebf's code under any call order on one MEMO"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:112`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 12,000 random-order calls over 300 random fixtures, at depth ≤ 4 with three names per level, including ENT blob/link/gitlink entries at ancestors and at PATH. It does not establish deeper paths, case-insensitive filesystems, or a checkout that changes between calls.

Command `LC_ALL=C bash fuzz.sh 300 40` (cwd scratch, 22:04:02Z, exit 0). Each fixture mixes absent nodes, searchable and unsearchable directories, readable and mode-000 files, links to siblings, dangling links and FIFOs. Each call runs HEAD's and 21b35ebf's main_checkout on separate MEMOs. Result: `calls=12000 unexpected_diffs=0 expected_link_PATH_diffs=657`. Every difference is a PATH that ENT holds as 120000/160000, where HEAD answers 1. That includes PATHs that ENT holds as a blob: they matched 21b35ebf. The same harness against 3a35c8b9's main_checkout gives 36 unexpected diffs (`fuzz3a.sh`), so it is sensitive to the defect fixed in 4b7f2357.

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`; `/tmp/u2a3c-i4-fc1-PaRf/fuzz.sh`, `/tmp/u2a3c-i4-fc1-PaRf/fuzz.log`, `/tmp/u2a3c-i4-fc1-PaRf/fuzz3a.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 8: override row — "capped_read drains only when the blob arm passes `drain` (since 2fbd929b), and the test row 453 names is "main walk reads an untracked start that a main file also imports once, through the checkout""

**Location:** `docs/reviews/override-log.md:457`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the drain argument, its one caller and when it was introduced, and that the named test exists. It does not establish row 453's other content.

`capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }` (`scripts/lib/dev-cycle-read.sh:710`). Only the blob arm passes it: `git cat-file blob "$MAIN_SHA:$f" | capped_read drain` (`:846`). `git show 2fbd929b` adds that body (diff line `+capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }`). The test is at `test/scripts/build-loop-check.bats:923`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:710`, `:846`; `test/scripts/build-loop-check.bats:923`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 9: override row — "A deep token through directories the checkout holds still costs about D³ in realpath (D=1000: 14.3 s; 21b35ebf 33.7 s; main over 120 s) … IMPORT_OUT_MAX caps D near 2,000"

**Location:** `docs/reviews/override-log.md:458`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the timings (Claim 6) and the D cap derived from the parser's dedup and print charge. It does not establish the exponent, or the "`! -L` would do" design suggestion.

Timings as in Claim 6: 11.67 s, 31.51 s, and over 150 s. The cap: each emitted prefix of `a/a/…/x.md` resolves to one of about D distinct outputs, because `if (out in seen) return` dedups them (`scripts/lib/dev-cycle-read.sh:597`), and each is charged `printed += length(out) + 1` (`:599`). The lengths are about 2k for k ≤ D, which sums to about D², and that passes 4,000,000 near D = 2,000 (paraphrased — no quote available because the bound is an arithmetic consequence of `:597-599` and `IMPORT_OUT_MAX=4000000`, `:503`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:503`, `:597-599`; `/tmp/u2a3c-i4-fc1-PaRf/deep.log`, `/tmp/u2a3c-i4-fc1-PaRf/deep-main.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 10: override row — "The walk's caller contract lives in two places (the lib block comment for the cache rules, the plan's U2b bullet for the rest) … A5 now names which part lives where"

**Location:** `docs/reviews/override-log.md:459`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the presence of each part in each place. It does not establish completeness of the contract.

The lib comment holds the cache rules: "a caller whose checkout may have changed (a file added or edited) sets IMPORTED_MAIN_DONE="" to walk again … A caller that changes HOME clears both" (`scripts/lib/dev-cycle-read.sh:487-491`). The U2b bullet holds "owes the walk four things" (`docs/working/plan-build-loop-handoff.md:279`). A5 says "the lib's block comment above `IMPORTED=` holds the cache rules; the plan's U2b bullet holds the rest" (`docs/working/known-issues-dev-cycle.md:18`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:485-498`; `docs/working/plan-build-loop-handoff.md:279`; `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 11: override row — "The Incorrect was unreachable from main_imports; every critic weighed it; fixed in code (guard + test)"

**Location:** `docs/reviews/override-log.md:460`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers reachability through both call sites, the guard, and test 65. It does not establish "every critic weighed it", a process claim.

As in Claim 3a: both call sites skip paths in `ent` (`scripts/lib/dev-cycle-read.sh:833`, `:877`), the guard sits at `:743`, and test 65 fails at 3a35c8b9 and passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:743`, `:833`, `:877`; `test/scripts/build-loop-check.bats:973-980`; `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 12: A5 — "the plan's U2b bullet holds the rest of what a caller owes the walk: a clean worktree at MAIN_SHA, empty `ls-files` stderr, the git environment, `LC_ALL=C`"; plus the checkout-phase refusal list

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed duty's presence in the U2b bullet, and the refusal list against `main_checkout`/`checkout_md`. It does not establish that U2b enforces any of them (not built).

The U2b bullet names "a clean worktree at MAIN_SHA", "a git that prints nothing on stderr for `ls-files`", "the git environment the override log hands the caller", and "runs the walk under `LC_ALL=C`" (`docs/working/plan-build-loop-handoff.md:279`). `LC_ALL=C` sits outside its "four things", but it is in the bullet. The refusals match the code: an ancestor main stores as a link or gitlink, or an ancestor that is not a searchable plain directory, returns 1 (`scripts/lib/dev-cycle-read.sh:749-752`). An unreadable file gives `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` (`:758`). Anything else gives `plaindir "$c" || return 1` (`:759`). Any listing stderr fails through `checkout_md` (`:717`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`; `scripts/lib/dev-cycle-read.sh:717`, `:735-762`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 13: F11 — "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, an unreadable file, or anything but a plain file or directory … the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the admission list, which is now complete with "an unreadable file", and the parenthetical list of caller duties. It does not establish anything else in the F11 row.

The admission list matches the code (Claim 12). The parenthetical names three duties, but 4b7f2357 made the U2b bullet "four things" by putting "that checkout a clean worktree at MAIN_SHA" first, and the bullet also requires `LC_ALL=C` (`docs/working/plan-build-loop-handoff.md:279`). A5 lists all four (`docs/working/known-issues-dev-cycle.md:18`). Precise version: "(a clean worktree at MAIN_SHA, cache clear, empty `ls-files` stderr, the git environment, `LC_ALL=C`)", or drop the list and point to the bullet.

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `:279`; `docs/working/known-issues-dev-cycle.md:18`
**Legibility-target:** for-author

---

## Claim 14: U2b bullet — "owes the walk four things: that checkout a clean worktree at MAIN_SHA (the walk reads main's blob for every path main stores, so an edited tracked instruction file's own imports go unread …) … A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too) and a PATH main lacks or stores as a blob (a link or gitlink there answers 1)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count of four, the blob-read mechanism, the MEMO-skip statement and the PATH answer. It does not establish that a blob PATH whose checkout holds a directory is a safe input (Escalations).

There are four duties, each introduced by a semicolon, in the bullet. The mechanism is Claim 5. The MEMO hit stops the bottom-up loop before the ancestor's mode is tested: `if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi` (`scripts/lib/dev-cycle-read.sh:746`). A link or gitlink at PATH answers 1 (`:743`; test 65 executed). A blob at PATH answers by the checkout's shape (fuzz, Claim 7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:743`, `:746`, `:843-846`; `/tmp/u2a3c-i4-fc1-PaRf/fuzz.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 15: lib header — "main_imports reads main's commit first and then the working tree (the checkout's start files and imported files main lacks, which can only add imports or fail it; it needs resolve_main to have found main by name); imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:36-39`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the read order, the append-only phase, and the main_by_name dependency. It does not establish ROOT_REAL handling beyond need_root.

`main_by_name || return 1` (`:815`). Phase 2 starts only when the queue empties: `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:840`). Records only append: `IMPORTED_MAIN+="$i"$'\n'` (`:873`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:808-882`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 16: lib main-walk comment — "a checkout path it would walk … that lies under a directory main stores as a symlink or gitlink or under an unsearchable directory, or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included), or a checkout listing git prints any stderr for, fail the walk … A linked worktree's .git file and files under .git are checkout files like any other."

**Location:** `scripts/lib/dev-cycle-read.sh:470-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the refusal shapes (T1, test 65, fuzz) and the .git rule through tests 411/657/700. It does not establish the case-insensitive or submodule cases, which are listed as not covered.

The refusals are as in Claim 12. The removed U2a3b special case leaves `.git` to main_checkout like any path main lacks (paraphrased — no quote available because the claim rests on the deletion of the `if [[ "$p" == .git ]]` block in the branch diff). The tests at lines 411, 657 and 700 pass at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `:874-881`; `test/scripts/build-loop-check.bats:411`, `:657`, `:700`; `/tmp/u2a3c-i4-fc1-PaRf/blc-short.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 17: work-unit comment — "the parser's work (the candidate and comment-splice characters it scans and each resolved spelling it joins, which carries ROOT_REAL, so a longer root buys less; the unit of its per-file bound of 50,000,000, about 5 s for a many-component name) … /workspace's walks spend about 8,100 each (2026-10-07)"

**Location:** `scripts/lib/dev-cycle-read.sh:504-509`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the charge sites, the /workspace figure (both walks), and the order of magnitude of the per-file bound's time. It does not establish 5 s exactly: the time depends on shape and host, and 6,000 `a/` components reached the bound in 3.9 s here.

Charges: `work += length(c)` in `emit` (`:567`), in `put` after `c = root "/" dir "/" c` (`:582-585`), and `work += length(r)` in `splice` (`:618`). Executed (`work.sh`, wrapping `import_work`, 22:02:25Z, exit 0): `/workspace` (on `main`) gave `tree ok work=8110` and `main ok work=8110`. The worktree gave 5,075 each (`work.log`). Per-file bound (`many-comp.sh`, `IMPORT_LEFT` raised so the print budget does not stop first): 6,000 `a/` components gave rc=1 in 3.91 s; `./` gave 1.13 s and `a/../` 1.3 s (`many-comp2.log`, `many-comp3.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-618`; `/tmp/u2a3c-i4-fc1-PaRf/work.log`, `/tmp/u2a3c-i4-fc1-PaRf/many-comp3.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 18: "IMPORT_LEFT (what may still be printed; IMPORT_OUT_MAX when unset or empty, and as awk reads a number otherwise: its leading digits, or 0, so the first name fails it) and IMPORT_WORK_LEFT (… Unset or empty: no trailer and only the per-file bound; otherwise read as IMPORT_LEFT is). Both walks pass numbers."

**Location:** `scripts/lib/dev-cycle-read.sh:524-529`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers mawk 1.3.4's string-to-number conversion of `ENVIRON[...] + 0`, the unset/empty handling and both walks' arguments. It does not establish another awk's conversion.

"As awk reads a number" is right: `left = ENVIRON["IT_LEFT"] + 0` and `if (trail && ENVIRON["IT_WORK"] + 0 < wmax) wmax = ENVIRON["IT_WORK"] + 0` (`:626-627`). The gloss "its leading digits, or 0" is narrower than what mawk does. Executed: `12abc`→12, ` 12`→12, `1e3`→1000, `-5`→-5, `0x10`→16, `+7`→7, `.5`→0.5, `abc`→0. mawk reads a leading numeric prefix with blanks, sign, decimal point, exponent and even hex. "So the first name fails it" holds for 0: `printed += length(out) + 1; if (printed - 1 > left) exit 3` (`:599`). Both walks pass `$((… - …))`, which is never negative because `import_work` and the `used` check keep the totals at or under their maxima (`:682`, `:785`, `:871`). Precise version: "its leading number as strtod reads it (sign, exponent, hex), or 0".

**Evidence:** `scripts/lib/dev-cycle-read.sh:524-529`, `:599`, `:624-628`, `:672`; command `X=<v> mawk 'BEGIN{print ENVIRON["X"]+0}'` (cwd scratch, 22:03Z, exit 0; output reproduced above)
**Legibility-target:** for-author

---

## Claim 19: import_work — "strips the parser's work trailer (its last line, "/N", printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with /) from the variable OUT, and adds N to the variable TOTAL. It returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:674-683`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the strip, the charge and both failures (test at line 843), and that put's output never begins with "/". It does not establish behaviour on a non-integer trailer, which mawk never prints for integral work.

`END { if (trail) print "/" (work + 0) }` (`:630`). `[[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1` (`:680`), then `(( (iw_t += iw_w) <= IMPORT_WORK_MAX ))` (`:682`). put prints `out = substr(out, length(pre) + 1)` after `index(out, pre) != 1 || length(out) <= length(pre)` returns (`:595-596`), so the output has no leading "/". The test at line 843 passes. Note: `exit 3` in a main rule still runs END, so a failed parse also prints a trailer, but awk's status 3 makes `import_targets` return 1 first (`:672`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:595-596`, `:630`, `:672`, `:678-683`; `test/scripts/build-loop-check.bats:843-852`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 20: capped_read — "the first 4 MiB + 1 bytes of stdin … With the word drain (after git cat-file) it reads the rest, so the writer never dies of SIGPIPE … The drain is time the work bound does not charge"

**Location:** `scripts/lib/dev-cycle-read.sh:702-710`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte count, the drain and the uncharged drain. It does not establish Claude Code's own 4 MiB limit, which is carried from main.

`head -c 4194305` is 4 × 1,048,576 + 1 (`:710`). The drain runs only on the blob arm (Claim 8). The drain is outside awk, so it adds nothing to `work`. Test 811 (4 MiB blob under pipefail) passes at HEAD.

**Evidence:** `scripts/lib/dev-cycle-read.sh:710`, `:846`; `test/scripts/build-loop-check.bats:811`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 21: checkout_md — "fails when git exits nonzero or prints anything on stderr, since an unreadable directory goes unlisted with only a warning"

**Location:** `scripts/lib/dev-cycle-read.sh:714-717`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers both failure conditions and the caller's `|| return 1`. It does not establish which git versions warn rather than fail on an unreadable directory.

`{ e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]`: stdout goes to fd 3 and only stderr lands in `e`, and the assignment's status is git's. The caller is `nul_list recs checkout_md || return 1` (`:825`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:717`, `:825`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 22: main_checkout comment — "MEMO … d for a plain searchable directory, 2 for one absent or a plain file (nothing below it loads), set only once its own and every higher ancestor's main mode passed (PATH's own mode is checked first: main's link or gitlink at PATH answers 1). A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT. main_imports calls it only for paths main lacks."

**Location:** `scripts/lib/dev-cycle-read.sh:718-734`
**Type:** Invariant / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the memo's values and write conditions, the order of the PATH check, and both call sites. It does not establish that "2 for one absent or a plain file" names every 2 entry: entries below such an ancestor are also 2 (they are absent, or ENOTDIR under a file).

The ancestor loop checks the mode before the write: `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1 … mc_m[$c]="$st"` (`:749-754`). The PATH write `[[ ! -x "$c" ]] || mc_m[$c]=d` (`:760`) runs only after the guard at `:743`. T1's memo is `d=d f.md=2 nd2/m=2 nd2=2 nd=2`, where nd2/m is a 2 below an absent ancestor. Fuzz (Claim 7): 0 unexpected diffs from 21b35ebf. Call sites: Claim 3a.

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `:833`, `:877`; `/tmp/u2a3c-i4-fc1-PaRf/fuzz.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 23: "${x@a} on an empty array is an unbound-variable error under set -u … ${x[0]@a}, not ${x@a}, which costs time linear in the array's size"

**Location:** `scripts/lib/dev-cycle-read.sh:737-741`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both statements and the restoration of `set -u` on return. It does not establish bash versions other than 5.2.15.

`bash -c 'set -u; declare -A e=(); echo "[${e@a}]"'` fails with `e: unbound variable`. Under `set -u`, `${e[0]@a}` also fails for an empty array, and for any array lacking key 0 (`e[0]: unbound variable`), so `set +u` before the test is load-bearing. It is in place, `set +u; [[ "${mc_e[0]@a}" == *A* …` (`:741`), and `local -` restores the options. After a call, `$-` is `ehuBc` and an unset variable still errors. Cost: Claim 2.

**Evidence:** `scripts/lib/dev-cycle-read.sh:736-741`; `/tmp/u2a3c-i4-fc1-PaRf/attr.sh`, `/tmp/u2a3c-i4-fc1-PaRf/t.sh`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 24: "Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:806-807`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the loop's handoff and the arm choice. It does not establish ordering among phase-2 items.

`while [[ ${#queue[@]} -gt 0 || ${#tq[@]} -gt 0 ]]; do [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:839-840`). `case "${ent[$f]-checkout}" in checkout) out="$(capped_read < "$f" | …` (`:843-844`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:839-846`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 25: test 54 comment and cap — "Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (10 at 2fbd929b; 18 without its memo of a prefix candidate's own directory)"; cap `-le 14`

**Location:** `test/scripts/build-loop-check.bats:822-832`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers 74, 10 and 18, and that the cap of 14 fails 21b35ebf. It does not establish the 102 figure, which belongs to an unmemoized mutant that was not rebuilt.

Command `bash t54.sh` (realpath shim, fixture under the scratch dir, 22:02:52Z, exit 0): HEAD 10, the no-PATH-memo mutant 18, 3a35c8b9 10, 2fbd929b 10, 21b35ebf 18, 3e58eb9c 74 (`t54.log`). Test 54 fails at 21b35ebf with HEAD's test file (`old-21b35ebf.log`).

**Evidence:** `test/scripts/build-loop-check.bats:821-833`; `/tmp/u2a3c-i4-fc1-PaRf/t54.log`, `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 26: T1 title — "memoizes plain searchable directories as d and absent or plain-file ancestors as 2"

**Location:** `test/scripts/build-loop-check.bats:854`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the full memo print and the pass at HEAD. It does not establish a PATH-level guard pin (Claim 3b).

The test prints `echo "$k=${M[$k]}"` for every key and expects `memo d=d f.md=2 nd2/m=2 nd2=2 nd=2` (`:861`, `:880`). It passes at HEAD and fails at 21b35ebf (`old-21b35ebf.log`).

**Evidence:** `test/scripts/build-loop-check.bats:854-883`; `/tmp/u2a3c-i4-fc1-PaRf/blc-short.log`, `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 27: T3 — "The caps derive from w: each candidate is charged its resolved spelling, so w grows with the fixture root."

**Location:** `test/scripts/build-loop-check.bats:908-909`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the reason and the fix under 22- and 76-character TMPDIRs. It does not establish which arm mutants it kills (not re-run here).

put charges `length(c)` after prefixing `root "/" dir "/"` (`scripts/lib/dev-cycle-read.sh:582-585`). The old fixed cap fails from TMPDIR length 28 (Claim 4), and the HEAD test passes at 22 and 76.

**Evidence:** `test/scripts/build-loop-check.bats:898-914`; `scripts/lib/dev-cycle-read.sh:582-585`; `/tmp/u2a3c-i4-fc1-PaRf/t3.log`, `/tmp/u2a3c-i4-fc1-PaRf/blc-long.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 28: test 63 — "A git shim logs each `git cat-file blob` object name: the long link must fail with no read of its blob."

**Location:** `test/scripts/build-loop-check.bats:944-956`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the test kills the no-size-cap mutant and passes at HEAD. It does not establish what a `git` reached by an absolute path would do, since the shim only intercepts lookups through PATH.

Mutant (cwd `$S/repo`, `sed` deletes `:850`'s `git cat-file -s` line, 22:03Z): the test fails with `walk: ok / link blob read / walk: ok / link blob read`. Without the cap, the 4,097-byte link text is read and the walk succeeds. The same mutant result appears in 21b35ebf's run (`old-21b35ebf.log`, test 63).

**Evidence:** `scripts/lib/dev-cycle-read.sh:848-850`; `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 29: test 64 — "Linear work gives a ratio of about 4 (4.0 at 3a35c8b9); 21b35ebf's top-down rescan of every absent ancestor gives about 16 (15.6). A count, so no host is fast enough to hide it."

**Location:** `test/scripts/build-loop-check.bats:958-971`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at HEAD, 3a35c8b9 and 21b35ebf, and the test's failure at 21b35ebf. It does not establish that the test catches the `${x@a}` regression: xtrace counts commands, not their cost, so 3a35c8b9 passes it (that case is test 66's).

Command `bash xt.sh` (22:01:48Z, exit 0): HEAD 4,901 → 19,601 (4.0), 3a35c8b9 4,701 → 18,801 (4.0), 21b35ebf 72,704 → 1,130,804 (15.55) (`xt.log`). With HEAD's file, test 64 fails at 21b35ebf (`old-21b35ebf.log`).

**Evidence:** `test/scripts/build-loop-check.bats:958-971`; `/tmp/u2a3c-i4-fc1-PaRf/xt.log`, `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 30: test 65 — "main_checkout refuses a PATH main stores as a link or gitlink, so a plain checkout directory there never passes a path below it"

**Location:** `test/scripts/build-loop-check.bats:973-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four rows at HEAD and the failure at 3a35c8b9 (the fail-open) and 21b35ebf (`l 2`). It does not establish a pin separating the link-only guard from a PATH-wide one (Claim 3b).

HEAD: `l 1 / l/f.md 1 / g 1 / g/f.md 1`. 3a35c8b9: `l 2 / l/f.md 0 / g 2 / g/f.md 0`. 21b35ebf: `l 2 / l/f.md 1 / g 2 / g/f.md 1` (`old-*.log`).

**Evidence:** `test/scripts/build-loop-check.bats:973-980`; `/tmp/u2a3c-i4-fc1-PaRf/old-3a35c8b9.log`, `/tmp/u2a3c-i4-fc1-PaRf/old-21b35ebf.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 31: test 66 — "stays near linear in the number of import tokens main lacks … about 2.5 s here; at 3a35c8b9 … (44.6 s), so this catches it on hosts up to about 2x faster"

**Location:** `test/scripts/build-loop-check.bats:982-991`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timings, the 2x margin, and linearity at 1k-8k tokens. It does not establish freedom from flakes on a host more than about 8x slower (2.4 s against a 20 s timeout). The test itself checks only the timeout, not linearity.

The timings and margin are as in Claim 2. Scaling at HEAD (`many-scale.log`): 1,000 tokens 0.61 s, 2,000 1.21 s, 4,000 2.41 s, 8,000 4.83 s, which is linear.

**Evidence:** `test/scripts/build-loop-check.bats:982-991`; `/tmp/u2a3c-i4-fc1-PaRf/many.log`, `/tmp/u2a3c-i4-fc1-PaRf/many-scale.log`
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 32: commit 4b7f2357 message — "main_imports never passes such a PATH"; "4,000 deep tokens 44.6 s at 3a35c8b9, 2.5 s now, main 0.9 s. Test added; it fails at 3a35c8b9"; "T3's caps derived from w (it failed under a TMPDIR over ~27 characters)"; "66/66 under a 17- and a 74-character TMPDIR; 78/19/2"; "the many-token test's 20 s timeout catches the regression only on hosts up to about 2x faster"

**Location:** `git show 4b7f2357` (commit message)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed number and statement (Claims 1a, 2, 3a, 4, 31). It does not establish the exact TMPDIR lengths 17 and 74, for which 22 and 76 were used.

All reproduced, as cited in the claims named in Scope. "Override rows: corrections to 449/453; performance F2 and architecture F2 deferred; the unpaused Fact-Check Gate recorded" matches the four rows at `docs/reviews/override-log.md:457-460`.

**Evidence:** `docs/reviews/override-log.md:457-460`; logs as cited in Claims 1a, 2, 4
**Legibility-target:** for-orchestrator-synthesis

---

## Claim 33: commit 380ed01b message — "Merged fact-check (64 clusters, 1 Incorrect, agreement 78.1%), five critic reports, Stage 2.5 submitted claims (at 4b7f2357)"

**Location:** `git show 380ed01b` (commit message)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the merged report's header counts and the files the commit adds. It does not establish the agreement metric's inputs beyond 50/64.

The merged report header reads `**Total claims checked:** 64` and `**Summary:** 41 verified, 14 mostly accurate, 2 stale, 1 incorrect, 6 unverifiable`, and its `**Verdict:**` lines tally the same. 50/64 = 78.125%. The commit adds five `*-final.md` critic reports and `code-fact-check-submitted-claims-build-loop-u2a3c.md` (`Commit: 4b7f2357`).

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md:1-10`; `docs/reviews/code-fact-check-submitted-claims-build-loop-u2a3c.md:1-8`
**Legibility-target:** for-orchestrator-synthesis

---

## Claims Requiring Attention

### Incorrect
- **Claim 3b** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`): a PATH-wide "any ENT path" guard passes all 66 tests, because T1 never calls a PATH that ENT holds. Only an ancestor-wide guard breaks T1's `f.md/x.md` row. Say "would break T1's `f.md/x.md` row if applied to ancestors" or drop the reason.

### Mostly Accurate
- **Claim 13** (`docs/working/plan-build-loop-handoff.md:126`): F11's parenthetical caller contract lists three duties. The U2b bullet now holds four plus `LC_ALL=C`, and the clean-worktree duty is missing.
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:524-529`): "its leading digits, or 0" understates mawk's conversion, which also reads blanks, sign, decimals, exponents and hex (`0x10` → 16).

### Unverifiable
- **Claim 1b** (rubric:82): the health check was not run, because it runs the full test runner. The shellcheck gate within it was run.

## Escalations

- **test-strategy**: no test separates 4b7f2357's link/gitlink-only PATH guard from a PATH-wide guard (`[[ -z "${mc_e[$3]+set}" ]] || return 1` passes 66/66, `broad.log`), so a blob PATH answering by the checkout's shape is unpinned. Also, test 64 (xtrace) cannot catch the `${x@a}` class: 3a35c8b9 passes it at 4.0, so only test 66's 20 s timeout guards D1, with about 2x margin on faster hosts.
- **security-reviewer**: the U2b bullet permits "a PATH main … stores as a blob" for a second caller. With such a PATH and a plain searchable checkout directory there, main_checkout memoizes PATH as d and later admits checkout files below it (executed: blob PATH diffs match 21b35ebf, so this is not a regression). Its safety rests on U2b's clean-worktree-at-MAIN_SHA duty. Confirm that this precondition is meant to stand in for a mode check.
- **api-consistency-reviewer**: F11's caller-contract parenthetical (Claim 13) drifted from A5 and the U2b bullet. That is three statements of one contract, as override row 459 anticipates.
- **performance-reviewer**: nothing new. The settled D³ row reproduces (HEAD 11.7 s, 21b35ebf 31.5 s, main over 150 s at D=1000).

## Goal-Alignment Note
- Success criterion (restated verbatim): no `Success criterion` line in the goal preamble; its task line reads "the final confirming pass (no `--loop-pass`: k=3 fact-check, full panel, Stage 2.5) over the full branch diff `git diff main...HEAD` (HEAD = 380ed01b; the last code commit is 4b7f2357). Clean → merge; any new finding goes back to the user."
- Answered: yes. All six focus areas were checked by execution. 4b7f2357's guard and `${x[0]@a}` change behave as stated, and its tests pass under both TMPDIRs and fail on the libs they target. There are three wording findings (one Incorrect in a rubric author note, two Mostly accurate) and no code defect.
- Out of scope: the full health check (cost), the iteration-1/2 report files (history), exact 17/74-character TMPDIR runs (22/76 used).
- Escalate: Claim 3b (rubric reason that no test pins) and the blob-PATH precondition to test-strategy/security, per Escalations.
- Decisions I made: read "test 77" in D4 as the test at line 77, and "any ENT path" as a guard on PATH only (its ancestor reading is noted in Claim 3b's Scope).
