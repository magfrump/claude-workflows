Commit: 380ed01b

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` (merge base e5d0f838, HEAD 380ed01b; last code commit 4b7f2357) plus the commit messages of main..HEAD: `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c, U2b), `docs/reviews/override-log.md` (rows added), and the factual claims about the code in `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md` ("Iteration 3 of 3"). Other `docs/reviews/*u2a3c*` files are history and were not checked.
**Checked:** 2026-10-07
**Commit:** 380ed01b
**Replicate:** r3 (role tag fc3)
**Total claims checked:** 38
**Summary:** 32 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Execution provenance. Every executed claim ran in a scratch copy of HEAD (`git archive 380ed01b`, extracted to `/tmp/u2a3c-i4-fc3-G9S7/repo`) or against lib versions extracted with `git show <commit>:scripts/lib/dev-cycle-read.sh` into `/tmp/u2a3c-i4-fc3-G9S7/lib-<commit>.sh`. The worktree was not modified. Mutant libs are `lib-m1-nosize.sh` (the `git cat-file -s` cap removed), `lib-m2-nopathmemo.sh` (`mc_m[$c]=d` at PATH removed), `lib-m3-noguard.sh` (the 4b7f2357 PATH guard removed), `lib-m4-slowattr.sh` (`${x@a}` restored), `lib-m5-broad.sh` (the guard widened to "any ENT entry at PATH"), and `lib-m6-nodrain.sh` (`drain` dropped from the blob arm). Mutant runs go through `/tmp/u2a3c-i4-fc3-G9S7/runwith.sh LIB FILTER LOG`, which copies LIB into the scratch repo, runs `bats -f FILTER test/scripts/build-loop-check.bats` under a fresh TMPDIR and `LC_ALL=C`, then restores HEAD's lib. All runs: bash 5.2.15, mawk, git 2.39, uid 1000 (not root), 2026-10-07 between 21:59Z and 22:14Z. Captured output is in `/tmp/u2a3c-i4-fc3-G9S7/*.log`. I read `docs/reviews/hallucination-patterns.md`, and no claim here matches a logged pattern.

Suites at HEAD (scratch copy, exit 0 each): build-loop-check 66/66 under TMPDIRs of 23, 86 and 182 characters (`blc-short.log`, `blc-long.log`, `blc-vlong.log`), dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2 (`dev-cycle.bats.log`, `build-loop-read.bats.log`, `fixture-hermeticity.bats.log`).

---

## Claim 1: "Guard: main's link or gitlink at PATH answers 1 (test-strategy's form; a broad "any ENT path" guard would break T1's blob row)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`
**Type:** Behavioral
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers a guard that refuses any ENT entry at PATH (`[[ -z "${mc_e[$3]+set}" ]] || return 1`) run against T1 and the other main_checkout tests. Does not establish what a guard over every ancestor's ENT entry would do: that reading would change T1's `f.md/x.md 2` row, but it is not a guard "at PATH".

T1 never passes a PATH that ENT holds. Its ENT is `declare -A E=([lnk]=120000 [gl]=160000 [nd2/m/l]=120000 [f.md]=100644)` and its PATH list is `d/r.md nx.md nd/x.md f.md/x.md d u d/n.md sf.md dg.md sd ff.md u/x.md sd/nx.md dgd/x.md lnk/x.md gl/x.md nd2/m/l/x.md` (`test/scripts/build-loop-check.bats:858-859`). The blob `f.md` appears only as an ancestor of `f.md/x.md`. With the broad guard in place of `[[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1` (`scripts/lib/dev-cycle-read.sh:743`), T1 still passes.

- Command: `./runwith.sh $PWD/lib-m5-broad.sh 'main_checkout' at-m5.log`
- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit code: 0 (ok=3, notok=0), 2026-10-07T22:12Z

The narrow guard is still the right fix, since main_imports never passes a PATH that ENT holds (Claim 21). The stated reason for choosing it is what does not hold.

**Evidence:** `test/scripts/build-loop-check.bats:854-880`, `scripts/lib/dev-cycle-read.sh:743`, `/tmp/u2a3c-i4-fc3-G9S7/at-m5.log`, `/tmp/u2a3c-i4-fc3-G9S7/lib-m5-broad.sh`

---

## Claim 2: D2: at 3a35c8b9 "a caller passing a PATH main stores as a link or gitlink opens every later path below it (and `x.md` main stores as a gitlink answered 0)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 3a35c8b9's main_checkout for a link or gitlink PATH that the checkout holds as a plain searchable directory or as a readable file. Does not establish reachability from main_imports, which never makes this call (Claim 21).

The new precondition test, run against 3a35c8b9's lib, prints `l 2`, `l/f.md 0`, `g 2`, `g/f.md 0`: the directory at PATH is memoized as d, and the path below it is admitted.

- Command: `./runwith.sh lib-3a35c8b9.sh 'U2a3c' at-3a35.log`
- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit code: 1 (tests 23 and 24 fail), 2026-10-07T22:01Z

A gitlink `x.md` that the checkout holds as a readable file has no ancestors, so 3a35c8b9 reaches `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` and returns 0 (paraphrased — no quote available because the 3a35c8b9 function is not in the HEAD file; it is `lib-3a35c8b9.sh`, main_checkout's final lines).

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/at-3a35.log`, `/tmp/u2a3c-i4-fc3-G9S7/lib-3a35c8b9.sh`

---

## Claim 3: D1: "`${x[0]@a}` is O(1) and gives the same answers (empty, large, indexed, scalar, unset checked). 2.5 s now, main 0.9 s. A 20 s-timeout test fails at 3a35c8b9 (it catches on hosts up to ~2x faster)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:92`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the type answers and their cost in bash 5.2.15, and the 4,000-token fixture on this host. Does not establish timings on any other host.

The type answers were identical for both spellings:

| Variable | `${x[0]@a}` | `${x@a}` |
|---|---|---|
| empty associative | A | A |
| non-empty associative | A | A |
| key 0 present | A | A |
| declared but unassigned `-A` | A | A |
| associative through a nameref | A | A |
| empty indexed | a | a |
| non-empty indexed | a | a |
| scalar | (empty) | (empty) |
| unset | (empty) | (empty) |
| `-i`, `-r`, `-x`, readonly `-A` | i, r, x, Ar | i, r, x, Ar |

Cost on a 200,000-key array: 2,000 evaluations of `${big[0]@a}` took 0.005 s, while 20 of `${big@a}` took 0.46 s.

The many-token fixture (`many.sh`, the test's own fixture without the 20 s timeout) took:

| Lib | Time |
|---|---|
| HEAD | 2.34 s and 2.51 s |
| main | 0.90 s |
| 3a35c8b9 | 42.33 s |

So 42.3 / 20 ≈ 2.1x, which matches "~2x". The test times out (status 124) at 3a35c8b9 and on the m4 mutant (`${x@a}` restored), and passes at HEAD.

- Commands: `bash attr.sh`, `bash attr2.sh`, `./many.sh $PWD/lib-<head|main|3a35c8b9>.sh`, `./runwith.sh lib-m4-slowattr.sh 'U2a3c' at-m4-slowattr.log`
- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit codes: 0, 0, 0 each; runwith exit 1 (only test 24 fails)
- Times: 2026-10-07T21:58Z–22:04Z

**Evidence:** `scripts/lib/dev-cycle-read.sh:741`, `/tmp/u2a3c-i4-fc3-G9S7/many.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m4-slowattr.log`, `/tmp/u2a3c-i4-fc3-G9S7/attr.sh`, `/tmp/u2a3c-i4-fc3-G9S7/attr2.sh`

---

## Claim 4: D3: "Test 59 (T3) fixed IMPORT_WORK_MAX=1000 while w grows with the fixture root's length: red under a TMPDIR over ~27 characters"; fix "verified under 17- and 74-character TMPDIRs"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:94`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 3a35c8b9's T3 under TMPDIR lengths 27 to 40 against HEAD's lib, and HEAD's T3 under 23, 86 and 182 characters. Does not cover the exact 17- or 74-character runs the rubric cites.

T3 is test 59 in the full file (`ok 59 each walk caps ...` in `blc-short.log`). 3a35c8b9's version passes at TMPDIR lengths 27, 27 and 27, and fails at 28, 30 and 40. HEAD's version derives its caps from w (`m=$((10 * w)); IMPORT_WORK_MAX=$m`, `test/scripts/build-loop-check.bats:909`) and passes at all three lengths.

**Evidence:** `test/scripts/build-loop-check.bats:898-914`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`, `/tmp/u2a3c-i4-fc3-G9S7/blc-long.log`, `/tmp/u2a3c-i4-fc3-G9S7/blc-vlong.log`

---

## Claim 5: D4: "an edited tracked instruction file's imports go unread (test 77 pins this as intended)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the behaviour and the test reference. Does not cover other test numberings (for example a multi-file bats run).

The behaviour holds. A path main stores is read through main's blob arm, ``100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | capped_read drain | ...`` (`scripts/lib/dev-cycle-read.sh:846`), and only paths ENT lacks become checkout candidates: `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:826`).

The test reference is wrong. The pinning test is build-loop-check's test 4, "main walk: main's instruction files start it; a working-tree edit does not count; ..." (`blc-short.log` line 5). Test 77 in build-loop-check.bats does not exist (the file has 66 tests), and dev-cycle.bats test 77 is "main_entry answers badform ...". The number comes from the security report this item cites (`security-reviewer-review-2026-10-07-build-loop-u2a3c-final.md:87`). The fix: cite the test by its title.

**Evidence:** `scripts/lib/dev-cycle-read.sh:826`, `scripts/lib/dev-cycle-read.sh:846`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`, `/tmp/u2a3c-i4-fc3-G9S7/dev-cycle.bats.log`

---

## Claim 6: E1: "The deep-token test's `timeout 6` catches its regression only on hosts under ~1.8x faster"; E2: "D=1000: 14 s; 21b35ebf 34 s; main over 120 s"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:103-104`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this host's timings for a 1,000-deep token whose directories the checkout holds. Does not establish the ratios on other hosts.

`deep.sh LIB 1000 1` gave HEAD 12.22 s, 21b35ebf 31.31 s, and main a timeout at 200.43 s (status 124). With the directories absent (`deep.sh LIB 1000 0`), HEAD took 0.61 s. E1's 1.8x is 10.7 / 6, from 2fbd929b's message (paraphrased — no quote available because the ratio is arithmetic over two cited numbers).

**Evidence:** `test/scripts/build-loop-check.bats:934-942`, `/tmp/u2a3c-i4-fc3-G9S7/deep.log`, `/tmp/u2a3c-i4-fc3-G9S7/deep.sh`

---

## Claim 7: E5: "A non-numeric `git cat-file -s` output would abort the caller under set -u rather than return 1"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:105`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers `[[ "$i" -le 4096 ]]` with `i=abc` under `set -u`, inside a function with an `||` handler. Does not test a real git producing such output.

`bash -c 'set -u; f(){ i=abc; [[ "$i" -le 4096 ]] || { echo ret1; return 1; }; }; f || echo ...; echo after'` printed `abc: unbound variable` and exited 127, with neither the handler nor `after` running. This is the shape of `i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:850`).

- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit code: 127, 2026-10-07T22:11Z (output inline in this session only; no log file)

**Evidence:** `scripts/lib/dev-cycle-read.sh:850`

---

## Claim 8: "Tests after fixes (4b7f2357): build-loop-check 66/66 under a 17- and a 74-character TMPDIR, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2; shellcheck clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:82`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers 380ed01b's tree, which has the same code as 4b7f2357: the four suites, and shellcheck as the health check runs it (`-S warning`). Does not cover the full `scripts/health-check.sh`, or the exact 17/74 lengths.

All four suites passed (see the header). Three files ran clean, each exit 0: `shellcheck -S warning scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`. The default level reports only info and style notes (SC2015, SC2016, SC2004), and the gate excludes those: `shellcheck -x -e SC1091 -s bash -S warning "$f"` (`scripts/health-check.sh:480`).

**Evidence:** `scripts/health-check.sh:475-485`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`, `/tmp/u2a3c-i4-fc3-G9S7/blc-long.log`

---

## Claim 9: Override row: "Corrects rows 449 and 453: capped_read drains only when the blob arm passes `drain` (since 2fbd929b), and the test row 453 names is "main walk reads an untracked start that a main file also imports once, through the checkout""

**Location:** `docs/reviews/override-log.md:457`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers capped_read's drain condition, its one `drain` caller, and the test title. Does not re-verify rows 449 and 453 themselves.

The reader is ``capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }`` (`scripts/lib/dev-cycle-read.sh:710`), and only the blob arm passes `drain` (`:846`). The test exists at `test/scripts/build-loop-check.bats:923`. Dropping `drain` (m6) fails the 4 MiB test: `./runwith.sh lib-m6-nodrain.sh '4 MiB' at-m6.log` in `/tmp/u2a3c-i4-fc3-G9S7` exited 1, 2026-10-07T22:13Z.

**Evidence:** `scripts/lib/dev-cycle-read.sh:710`, `scripts/lib/dev-cycle-read.sh:846`, `test/scripts/build-loop-check.bats:923`, `/tmp/u2a3c-i4-fc3-G9S7/at-m6.log`

---

## Claim 10: Override row: "A deep token through directories the checkout holds still costs about D³ in realpath (D=1000: 14.3 s; 21b35ebf 33.7 s; main over 120 s) ... IMPORT_OUT_MAX caps D near 2,000"

**Location:** `docs/reviews/override-log.md:458`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the timings (12.2 s / 31.3 s / over 200 s here; Claim 6) and the cap arithmetic. Does not measure the exponent.

The prefixes of `@a/a/.../x.md` print about D distinct names of lengths 1, 3, 5, …, 2D-1, about D² characters in all. Against `IMPORT_OUT_MAX=4000000` (`scripts/lib/dev-cycle-read.sh:503`), that puts D near 2,000 (paraphrased — no quote available because this is arithmetic over the parser's `put` dedup at `:586-600`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:503`, `scripts/lib/dev-cycle-read.sh:586-600`, `/tmp/u2a3c-i4-fc3-G9S7/deep.log`

---

## Claim 11: Override rows: "The walk's caller contract lives in two places (the lib block comment for the cache rules, the plan's U2b bullet for the rest) ... A5 now names which part lives where"; "The Incorrect was unreachable from main_imports"

**Location:** `docs/reviews/override-log.md:459-460`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the text of A5 and of the U2b bullet, and the two main_checkout call sites. Does not judge whether the split is a good design.

A5 reads: "the lib's block comment above `IMPORTED=` holds the cache rules; the plan's U2b bullet holds the rest of what a caller owes the walk" (`docs/working/known-issues-dev-cycle.md:18`). For unreachability, see Claim 21.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`, `scripts/lib/dev-cycle-read.sh:832`, `scripts/lib/dev-cycle-read.sh:877`

---

## Claim 12: A5: the checkout phase "walks, and only appends ... a checkout path it would walk that lies under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git prints any stderr for fail it; a linked worktree's `.git` file is read like any checkout file"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers main_checkout's codes, checkout_md's stderr rule, and the .git tests. Does not cover the "Not covered" items, which are untraced gaps by design.

checkout_md fails on any stderr: ``{ e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]`` (`scripts/lib/dev-cycle-read.sh:717`). A code-1 refusal fails the walk: `[[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }` (`:878`). The tests for each of these shapes, including the linked-worktree `.git` test (build-loop-check 6-8, 51, 57, 58), pass at HEAD (`blc-short.log`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:717`, `scripts/lib/dev-cycle-read.sh:735-762`, `scripts/lib/dev-cycle-read.sh:832-834`, `scripts/lib/dev-cycle-read.sh:877-880`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`

---

## Claim 13: F11: "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, an unreadable file, or anything but a plain file or directory, and a checkout listing git prints any stderr for fails the walk; the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the refusals listed and the U2b references. Does not establish completeness: absence is not a refusal (it answers 2, as A5's "(or nothing)" says), and the list omits the clean-worktree duty, though it does not claim to be exhaustive.

An unreadable plain file answers 1 through `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` (`scripts/lib/dev-cycle-read.sh:758`), and the U2b bullet holds all three named duties (`docs/working/plan-build-loop-handoff.md:279`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 14: U2a3c bullet: "Built 2026-10-07 ...: the fail rules as stated (a readable plain file main lacks is walked; a non-plain node, an unreadable file, or a path under main's link or gitlink or under an unsearchable directory fails), `capped_read`, the work bound `IMPORT_WORK_MAX` (reported by the parser's trailer, charged by `import_work`), `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each named element's presence and use. Behaviour is covered by Claims 12 and 19-26.

The elements are in place:
- The trailer: `END { if (trail) print "/" (work + 0) }` (`scripts/lib/dev-cycle-read.sh:630`).
- `import_work` (`:678-683`), called after each parser run at `:782`, `:845` and `:847`.
- N1: `nul_list low lower_all "${cand[@]}"` (`:827`).
- The `.git` special case is gone from the import loop (`:875-881`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:630`, `scripts/lib/dev-cycle-read.sh:678-683`, `scripts/lib/dev-cycle-read.sh:827`, `scripts/lib/dev-cycle-read.sh:875-881`

---

## Claim 15: U2b bullet: owes the walk "four things: that checkout a clean worktree at MAIN_SHA (the walk reads main's blob for every path main stores ...); that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared ...; a git that prints nothing on stderr for `ls-files` (any stderr fails the walk closed); and the git environment ... A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too) and a PATH main lacks or stores as a blob (a link or gitlink there answers 1)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the walk behaviours each duty depends on and main_checkout's answers for each kind of PATH. Does not establish that U2b will enforce the duties (unbuilt). A PATH main stores as a blob answers by the checkout's shape alone, exactly as 21b35ebf did (fuzz, Claim 22). That answer is safe only under the first duty: a dirty checkout holding a directory where main stores a blob gets that directory memoized as d.

- Clean worktree: see Claim 5 (`:826`, `:846`).
- Cache key: ``[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]]`` (`scripts/lib/dev-cycle-read.sh:813`) has no checkout component.
- ls-files stderr: Claim 12.
- MEMO-hit skip: in the ancestor loop, `if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi` (`:746`) stops before any mode check above the memoized ancestor.
- Link or gitlink at PATH answers 1: Claims 21 and 22, and the precondition test (`test/scripts/build-loop-check.bats:973-980`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:743-761`, `scripts/lib/dev-cycle-read.sh:813`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz-7.log`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz-4242.log`

---

## Claim 16: "main_imports reads main's commit first and then the working tree (the checkout's start files and imported files main lacks, which can only add imports or fail it ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:36-38`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers the order of working-tree access in main_imports. "Only add or fail" holds.

Only checkout file *contents* are read after main's walk: `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:840`). The working tree is still consulted before and during main's phase:
- `nul_list recs checkout_md` runs before the walk (`:825`).
- `main_checkout ent pok "$f"` stats checkout starts before the walk (`:832`).
- The import loop admits imports main lacks during phase 1 (`:877`).
- The symlink arm tests `! -L "$p"` in the checkout (`:863`).

A precise version: "lists and stats the working tree throughout, and reads checkout file contents only after main's walk".

**Evidence:** `scripts/lib/dev-cycle-read.sh:825`, `scripts/lib/dev-cycle-read.sh:832`, `scripts/lib/dev-cycle-read.sh:840`, `scripts/lib/dev-cycle-read.sh:863`, `scripts/lib/dev-cycle-read.sh:877`

---

## Claim 17: "the parser's work (the candidate and comment-splice characters it scans and each resolved spelling it joins, which carries ROOT_REAL, so a longer root buys less ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-author
**Scope:** Covers emit, put and splice charging. Does not cover the uncharged scan, which the comment states separately.

`put` prefixes the root only for relative names: `if (substr(c, 1, 1) != "/") c = root "/" dir "/" c` and then `work += length(c)` (`:582-584`). An absolute name, and a `~/` name joined to the home at `:574-577`, is charged its own spelling, which need not carry ROOT_REAL. A precise version: "each resolved spelling it joins (a relative name's carries ROOT_REAL ...)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-600`, `scripts/lib/dev-cycle-read.sh:617-624`

---

## Claim 18: "the unit of its per-file bound of 50,000,000, about 5 s for a many-component name"; override row (21b35ebf) "one bound still costs about 5 s"

**Location:** `scripts/lib/dev-cycle-read.sh:506-507`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers two single-file shapes run to the per-file bound on this host. Does not cover the worst shape or other hosts.

`bound.sh` ran `import_targets ""` with no IMPORT_WORK_LEFT, and both shapes failed at the bound (rc=1):

| Shape | Lines printed | Time to the bound |
|---|---|---|
| `@` + 12,000 × `../` | 0 | 1.13 s |
| `@` + 12,000 × `a/`, IMPORT_LEFT lifted | 3,529 | 3.93 s |

So one bound costs about 1–4 s here, depending on shape. "About 5 s" is the right order but on the high side for this host.

- cwd: scratch repo `/tmp/u2a3c-i4-fc3-p*`
- 2026-10-07T22:06Z

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-600`, `/tmp/u2a3c-i4-fc3-G9S7/bound.log`, `/tmp/u2a3c-i4-fc3-G9S7/bound.sh`

---

## Claim 19: "/workspace's walks spend about 8,100 each (2026-10-07)"; 61e2e734: "(1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout ...)"

**Location:** `scripts/lib/dev-cycle-read.sh:509`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers /workspace's checkout as of 22:07Z. The figure drifts with the checkout.

`wsw.sh /workspace lib-head.sh` (read-only: sources HEAD's lib, wraps import_work to sum the trailer) printed `tree: ok work=8110 secs=1.15` and `main: ok work=8110 secs=1.4`.

- cwd: `/workspace`
- Exit code: 0, 2026-10-07T22:07:18Z

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/wsw.log`, `/tmp/u2a3c-i4-fc3-G9S7/wsw.sh`

---

## Claim 20: IMPORT_LEFT is read "as awk reads a number otherwise: its leading digits, or 0, so the first name fails it"; IMPORT_WORK_LEFT "otherwise read as IMPORT_LEFT is"

**Location:** `scripts/lib/dev-cycle-read.sh:524-529`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers mawk's string-to-number conversion of `ENVIRON[...] + 0` (`:626-627`). Does not cover gawk or busybox awk.

"As awk reads a number" is right, and so is "or 0, so the first name fails it": with left=0, `printed - 1 > left` exits on the first name (`:599`). The gloss "its leading digits" is narrower than what awk does:

| Input | mawk value |
|---|---|
| `12abc` | 12 |
| `abc` | 0 |
| ` 12` | 12 |
| `1e3` | 1000 |
| `-5` | -5 |
| `0x10` | 16 |
| `+7` | 7 |
| `1.9` | 1.9 |

A precise version: "its leading numeric prefix (sign, decimal point, exponent; hex under mawk)". This has no effect in practice: "Both walks pass numbers" holds at `:782`, `:844` and `:846`.

- Command: `IT_LEFT=<v> awk 'BEGIN{print ENVIRON["IT_LEFT"]+0}'`
- Exit code: 0, 2026-10-07T22:05Z (output inline; no log file)

**Evidence:** `scripts/lib/dev-cycle-read.sh:599`, `scripts/lib/dev-cycle-read.sh:626-627`

---

## Claim 21: "main_imports calls it only for paths main lacks"; 4b7f2357: "main_imports never passes such a PATH"

**Location:** `scripts/lib/dev-cycle-read.sh:726`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both call sites in main_imports, and the absence of any other caller (grep: `main_checkout ` appears only at `:832` and `:877` in scripts/). Does not cover future callers.

Start loop: `t:` candidates are only those with `[[ -n "${ent[$f]+set}" ]] || cand+=("t:$f")` (`:826`), and `[[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f"` (`:832`). Import loop: `[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"` (`:877`). So the guard at `:743` never fires for main_imports.

**Evidence:** `scripts/lib/dev-cycle-read.sh:826`, `scripts/lib/dev-cycle-read.sh:832`, `scripts/lib/dev-cycle-read.sh:877`

---

## Claim 22: MEMO "set only once its own and every higher ancestor's main mode passed (PATH's own mode is checked first: main's link or gitlink at PATH answers 1). A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT"; with the guard, every call order matches 21b35ebf's codes except the intended 1

**Location:** `scripts/lib/dev-cycle-read.sh:719-725`
**Type:** Invariant / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers random checkouts of depth ≤3 over names {a,b} and calls of depth 1–4, seven calls per shared MEMO. Shapes: dirs (some chmod 600), files (some 000), symlinks to dirs and files, FIFOs, absent nodes. ENT entries: 120000, 160000 or 100644 at random paths and ancestors. Does not cover deeper paths, case-insensitive file systems, root (for whom `-r`/`-x` always pass), or a MEMO shared across ENTs (excluded by contract).

`fuzz.sh SEED 1500` compares HEAD's `main_checkout` with 21b35ebf's (`mc_old`), each on its own MEMO over the same call sequence. The expected HEAD code is 21b35ebf's, except 1 wherever ENT[PATH] matches `^1[26]0000$`.

| Seed | Calls | HEAD differs from 21b35ebf | Unexpected |
|---|---|---|---|
| 7 | 10,500 | 541 | 0 |
| 4242 | 10,500 | 493 | 0 |

So every difference is the intended guard. Statically, the mode check `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1` runs for each ancestor before `mc_m[$c]="$st"` (`:749-754`), whatever `st` is. PATH's own mode is checked at `:743` before `mc_m[$c]=d` at `:760`.

- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit code: 0 both, 2026-10-07T22:00Z and 22:10Z

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz.sh`, `/tmp/u2a3c-i4-fc3-G9S7/fns.sh`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz-7.log`, `/tmp/u2a3c-i4-fc3-G9S7/fuzz-4242.log`

---

## Claim 23: main_checkout return codes: "0 for a readable plain checkout file to walk, 2 when nothing there loads (absent, below an absent ancestor or a plain file, or a plain directory), 1 to fail the walk: an ancestor main stores as a link or gitlink, an ancestor that is anything else but a plain searchable directory, an unreadable plain file, ENT or MEMO not an associative array, or anything else at PATH"

**Location:** `scripts/lib/dev-cycle-read.sh:727-731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers every listed shape via T1, test 65 and the fuzz. The does-not-cover limits are as in Claim 22.

T1 (`test/scripts/build-loop-check.bats:854-880`) passes at HEAD, including `ent-indexed 1` and `memo-indexed 1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:735-762`, `test/scripts/build-loop-check.bats:854-880`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`

---

## Claim 24: "${x[0]@a}, not ${x@a}, which costs time linear in the array's size"; and the type check runs under a local `set +u`

**Location:** `scripts/lib/dev-cycle-read.sh:737-741`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers bash 5.2.15. Whether key "0" exists does not matter under `set +u`, since both a0 and absent-key arrays give `A`. Under `set -u` without `+u`, `${big[0]@a}` errors on an absent key, so the local `set +u` (with `local -` at `:736` restoring it) is load-bearing.

See Claim 3 for the timings and answers. The empty-array failure that `set +u` guards against (80cc6224's message) still occurs: `bash -c 'set -u; declare -A a=(); echo "[${a@a}]"'` printed `a: unbound variable`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:736-741`, `/tmp/u2a3c-i4-fc3-G9S7/attr.sh`

---

## Claim 25: "Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below"

**Location:** `scripts/lib/dev-cycle-read.sh:849-850`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a 4,097-byte link blob on main. Does not cover a link blob exactly 4,096 bytes long (allowed by `-le 4096`, although the kernel's limit is 4,095).

The cat-file shim test passes at HEAD. On mutant m1 (the `-s` check removed), the walk reads the blob and passes (`walk: ok`, `link blob read` on both iterations), so the test fails.

- Command: `./runwith.sh lib-m1-nosize.sh 'U2a3c' at-m1-nosize.log`
- cwd: `/tmp/u2a3c-i4-fc3-G9S7`
- Exit code: 1 (only test 21 of the filter fails), 2026-10-07T22:12Z

**Evidence:** `scripts/lib/dev-cycle-read.sh:849-855`, `test/scripts/build-loop-check.bats:944-956`, `/tmp/u2a3c-i4-fc3-G9S7/at-m1-nosize.log`

---

## Claim 26: import_work: "strips the parser's work trailer (its last line, "/N" ...; a repo-relative name never starts with /) ... returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX"

**Location:** `scripts/lib/dev-cycle-read.sh:674-683`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the strip and charge logic and put's print form. Execution is covered by the import_work test (build-loop-check 56, passing).

`put` prints `substr(out, length(pre) + 1)` (`:596`), where `out` is built as `"/" st[i]` over non-empty parts and `pre` ends in `/`, so a printed name never starts with `/`. The regex `^[0123456789]+$` together with `"$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w"` (`:680`) rejects a last name like `docs/123`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:589-600`, `scripts/lib/dev-cycle-read.sh:678-683`

---

## Claim 27: Test comment: "Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (10 at 2fbd929b; 18 without its memo of a prefix candidate's own directory)"

**Location:** `test/scripts/build-loop-check.bats:822-826`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the counts at 3e58eb9c, 2fbd929b (identical to 3a35c8b9's lib), HEAD, 21b35ebf and the m2 mutant. Does not re-run the unmemoized 102.

A copy of the test with its threshold set to 0 (to print the count) gave:

| Lib | realpath calls |
|---|---|
| HEAD | 10 |
| 3a35c8b9 | 10 |
| 3e58eb9c | 74 |
| 21b35ebf (no memo of PATH) | 18 |
| m2 mutant | 18 |

The real test's `[ "$n" -le 14 ]` (`:832`) therefore pins the PATH memo, and m2 fails it (`at-m2-nopathmemo.log`).

**Evidence:** `test/scripts/build-loop-check.bats:821-833`, `/tmp/u2a3c-i4-fc3-G9S7/at-m2-nopathmemo.log`

---

## Claim 28: T1 title: "... memoizes plain searchable directories as d and absent or plain-file ancestors as 2"

**Location:** `test/scripts/build-loop-check.bats:854`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the printed MEMO `d=d f.md=2 nd2/m=2 nd2=2 nd=2` (`:880`). Does not establish that T1 pins the PATH memo: on m2, T1 still passes, because `d` is memoized as an ancestor of `d/r.md` first. Test 54's count pins it (Claim 27).

**Evidence:** `test/scripts/build-loop-check.bats:854-880`, `/tmp/u2a3c-i4-fc3-G9S7/at-m2-nopathmemo.log`

---

## Claim 29: "The caps derive from w: each candidate is charged its resolved spelling, so w grows with the fixture root"

**Location:** `test/scripts/build-loop-check.bats:908`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four top-level fixture files, which all cost w (same lengths, all relative names). Does not cover a fixture with an absolute name (Claim 17).

The relative names are prefixed with the root before charging (`scripts/lib/dev-cycle-read.sh:582-584`). The old fixed cap fails past a 27-character TMPDIR, and the new one passes at 23, 86 and 182 characters (Claim 4).

**Evidence:** `test/scripts/build-loop-check.bats:898-914`, `scripts/lib/dev-cycle-read.sh:582-584`

---

## Claim 30: xtrace test: "Linear work gives a ratio of about 4 (4.0 at 3a35c8b9); 21b35ebf's top-down rescan of every absent ancestor gives about 16 (15.6). A count, so no host is fast enough to hide it"

**Location:** `test/scripts/build-loop-check.bats:958-971`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers command counts at HEAD, 3a35c8b9 and 21b35ebf. Does not detect the D1 regression (`${x@a}`), which costs time rather than commands. The test passes at 3a35c8b9 and on m4; the many-token test is the one that catches D1.

| Lib | Commands at depth 100 | Commands at depth 400 | Ratio |
|---|---|---|---|
| HEAD | 4,901 | 19,601 | 4.0 |
| 3a35c8b9 | 4,701 | 18,801 | 4.0 |
| 21b35ebf | 72,704 | 1,130,804 | 15.55 |

21b35ebf fails `[ "$b" -le $((6 * a)) ]` (`at-21b3.log`).

**Evidence:** `test/scripts/build-loop-check.bats:958-971`, `/tmp/u2a3c-i4-fc3-G9S7/xt.sh`, `/tmp/u2a3c-i4-fc3-G9S7/at-21b3.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m4-slowattr.log`

---

## Claim 31: Precondition test title: "main_checkout refuses a PATH main stores as a link or gitlink, so a plain checkout directory there never passes a path below it"

**Location:** `test/scripts/build-loop-check.bats:973-980`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers HEAD, 3a35c8b9, 21b35ebf and m3. Does not cover a gitlink or link PATH that the checkout holds as a file (the fuzz covers it: Claim 22).

The test passes at HEAD and fails at 3a35c8b9 (`l 2 / l/f.md 0 / g 2 / g/f.md 0`), at 21b35ebf, and on m3 (the guard removed).

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/at-3a35.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-21b3.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m3-noguard.log`

---

## Claim 32: Many-token test: "about 2.5 s here; at 3a35c8b9 ... (44.6 s), so this catches it on hosts up to about 2x faster"

**Location:** `test/scripts/build-loop-check.bats:982-991`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers this host. On flakiness: HEAD runs at 2.3–2.5 s against a 20 s timeout, so a false red needs a host about 8x slower, or heavy parallel load. Not observed in the four HEAD runs here.

HEAD took 2.34 s and 2.51 s, and 3a35c8b9 took 42.33 s (Claim 3). The test times out at 3a35c8b9 and on m4.

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/many.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-3a35.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m4-slowattr.log`

---

## Claim 33: dev-cycle.bats inventory lists `md_ls checkout_md main_checkout lower_all capped_read import_work` as functions the lib defines

**Location:** `test/scripts/dev-cycle.bats:1107`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the functions' existence. The inventory test is not a behaviour test.

dev-cycle 78/78 passes, and each name is defined, e.g. `main_checkout() {` (`scripts/lib/dev-cycle-read.sh:735`).

**Evidence:** `test/scripts/dev-cycle.bats:1105-1110`, `/tmp/u2a3c-i4-fc3-G9S7/dev-cycle.bats.log`

---

## Claim 34: Commit 4b7f2357: "${x[0]@a} replaces ${x@a} ... (performance F1: 4,000 deep tokens 44.6 s at 3a35c8b9, 2.5 s now, main 0.9 s). Test added; it fails at 3a35c8b9"; "T3's caps derived from w (it failed under a TMPDIR over ~27 characters)"; "66/66 under a 17- and a 74-character TMPDIR; 78/19/2"

**Location:** commit 4b7f2357 message
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each figure, on this host and at nearby TMPDIR lengths (Claims 3, 4, 8, 32). Does not cover the exact 17/74-character runs.

The measured figures agree with the message: 42.3 s, 2.3–2.5 s and 0.9 s; the old T3 fails from 28 characters; 66/66 at 23, 86 and 182 characters; 78/19/2 (paraphrased — no quote available because each figure is verdicted in the claim cited beside it).

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/many.log`, `/tmp/u2a3c-i4-fc3-G9S7/blc-short.log`, `/tmp/u2a3c-i4-fc3-G9S7/blc-long.log`, `/tmp/u2a3c-i4-fc3-G9S7/blc-vlong.log`

---

## Claim 35: Commit 4b7f2357: "a host-independent xtrace-count test for the deep-token cost, a cat-file shim pinning that link text over 4096 is never read, the PATH memo pinned, T1 prints the whole MEMO, the precondition test"; Notes: "the xtrace test covers the deep case host-independently"

**Location:** commit 4b7f2357 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each test's target mutant or old lib (Claims 25, 27, 28, 30, 31). "The PATH memo pinned" is pinned by test 54's realpath count, not by T1. The xtrace test covers the i2 deep-absent regression, not D1.

Each named test fails on the mutant or old lib it targets and passes at HEAD (paraphrased — no quote available because the mapping spans five tests and their logs, cited in the claims above).

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/at-m1-nosize.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m2-nopathmemo.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-m3-noguard.log`, `/tmp/u2a3c-i4-fc3-G9S7/at-21b3.log`

---

## Claim 36: Commit 380ed01b: "Merged fact-check (64 clusters, 1 Incorrect, agreement 78.1%) ... Stage 2.5 submitted claims (at 4b7f2357)"

**Location:** commit 380ed01b message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the report headers. Does not re-verdict the merged claims.

The merged report's header says `**Total claims checked:** 64` and `**Summary:** 41 verified, 14 mostly accurate, 2 stale, 1 incorrect, 6 unverifiable`, and its body says "Agreement rate: 78.1% (50/64)" (`docs/reviews/code-fact-check-report-build-loop-u2a3c.md:1253`). The submitted-claims report's first line is `Commit: 4b7f2357`.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md:1-12`, `docs/reviews/code-fact-check-report-build-loop-u2a3c.md:1253`, `docs/reviews/code-fact-check-submitted-claims-build-loop-u2a3c.md:1-8`

---

## Claim 37: Commit 2fbd929b: "D=1000 took 10.7 s at 21b35ebf, 0.6 s now"; commit 80cc6224: "${x@a} on an empty associative array is an unbound-variable error under set -u"

**Location:** commits 2fbd929b and 80cc6224 messages
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers HEAD's 0.61 s for the 1,000-deep absent token and the `set -u` error. 21b35ebf's 10.7 s was not re-run for the absent case; its 15.6x command ratio (Claim 30) is consistent with it.

**Evidence:** `/tmp/u2a3c-i4-fc3-G9S7/deep.log`, `/tmp/u2a3c-i4-fc3-G9S7/attr.sh`

---

## Claim 38: Commit 27364085: "a mutant without the drain fails the 4 MiB test (walk failed)"

**Location:** commit 27364085 message
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers HEAD's `drain` arg, removed from the blob arm (m6). 27364085's own `-p /dev/stdin` drain was not re-run.

m6 fails "main walk reads only the first 4 MiB + 1 ..." (`at-m6.log`, exit 1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:846`, `/tmp/u2a3c-i4-fc3-G9S7/at-m6.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 1** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:93`): The rubric says a broad "any ENT path" guard at PATH would break T1's blob row. It does not: T1 never passes an ENT path as PATH, and the broad mutant passes T1. Drop the reason, or name the real difference: the broad guard would also refuse a blob PATH, which the U2b bullet allows.

### Mostly Accurate
- **Claim 5** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`): "Test 77" is build-loop-check test 4 ("a working-tree edit does not count"). Cite the test by its title.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:36-38`): main_imports lists and stats the working tree before and during main's walk. Only checkout file contents are read after it.
- **Claim 17** (`scripts/lib/dev-cycle-read.sh:504-506`): Only a relative name's resolved spelling carries ROOT_REAL. Absolute and `~/` names do not.
- **Claim 18** (`scripts/lib/dev-cycle-read.sh:506-507`): One per-file bound costs about 1–4 s here (1.1 s for `../`, 3.9 s for `a/`), not about 5 s.
- **Claim 20** (`scripts/lib/dev-cycle-read.sh:524-529`): Awk reads a leading numeric prefix (sign, decimal point, exponent; mawk also reads hex), not just "leading digits".

## Escalations

- **test-strategy:** The xtrace-count test (build-loop-check 64) does not guard D1. It passes at 3a35c8b9 and on the `${x@a}` mutant. D1's only guard is the many-token test's 20 s timeout, which goes blind on a host about 2x faster than this one. A count-based guard for the type-check cost would make D1 host-independent, if the author wants that.
- **api-consistency-reviewer / security-reviewer:** The U2b bullet allows a second caller to pass "a PATH main ... stores as a blob". main_checkout then answers by the checkout's shape and memoizes a checkout directory there as d (same as 21b35ebf). That is safe only under the clean-worktree duty. Whether to state that link, or refuse a blob PATH that the checkout holds as a directory, is for those critics. Not reachable from main_imports.
- **orchestrator (rubric author):** Claim 1's reason in rubric D2 is wrong; the fix is history-only (the report files are append-only history). Record it in the next rubric section or an override correction row if the reason matters.

## Goal-Alignment Note
- Success criterion (restated verbatim): "User goal: land `feat/build-loop-u2a3c` (worktree `/workspace/.claude/wt-build-loop-u2a3c`) on main once its review-fix loop is clean." (the preamble has no separate Success criterion line; this is its goal line)
- Answered: yes. Every item in the shared brief's list of claims to check (1–6) was verdicted, by execution where possible. The 4b7f2357 guard matches 21b35ebf's codes in 21,000 differential calls, except the intended 1. Every new test fails on its target. No code defect was found; there is one Incorrect claim, in rubric history prose.
- Out of scope: review-report bodies other than the rubric's factual claims and the override rows. Design quality.
- Escalate: test-strategy (D1 guard is timing-only); api-consistency/security (the blob-PATH allowance in the U2b precondition rests on the clean-worktree duty).
- Decisions I made: I treated "any ENT path" in rubric D2 as a guard at PATH, its natural reading, and verdicted Claim 1 Incorrect on that reading. I ran TMPDIR lengths 23, 86 and 182 instead of the exact 17 and 74.
