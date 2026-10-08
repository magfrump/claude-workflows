Commit: 4ce2c6bf

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch feat/build-loop-u2a3c)
**Scope:** `git diff 83c69b48..4ce2c6bf` (one commit, 6 files) plus its commit message
**Checked:** 2026-10-07 (runs 2026-10-07T23:31Z to 2026-10-08T04:17Z)
**Commit:** 4ce2c6bf
**Replication:** k=1 (lite fix-drift check, Q-129 [1])
**Total claims checked:** 20
**Summary:** 15 verified, 3 mostly accurate, 0 stale, 0 incorrect, 2 unverifiable

Execution notes. Every executed claim ran against the worktree at 4ce2c6bf, which was clean (`git status --short` empty). Fixture repos and mutated lib copies lived in `/tmp/u2a3c-lite-fc-Ko9n`, so the worktree was never modified. Captured output is in `/tmp/u2a3c-lite-fc-Ko9n/logs/`. That is scratch space outside the worktree, because this run was told to write no other file there. Another session left 48 busy loops running from about 23:38Z, which pushed the load average to 50-66 on 16 CPUs. Timings taken between 23:38Z and 23:44Z are contended and are used only where load cannot weaken the conclusion. The 04:17Z rerun ran at a load of about 33, which was still high. I read the hallucination pattern log. One logged pattern, a commit message's test tally that disagreed with the suite ("mode1-equiv 33"), bears on Claim 15, and I checked that claim by running every suite it counts.

---

## Claim 1: "D4's \"test 77\" is build-loop-check test 4 (corrected here)"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:168`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which test D4 meant and where the correction is recorded. It does not establish that D4's own row was changed, and that row was not changed.

The identification is right. Line 77 of the suite is the start of build-loop-check's fourth test, and that test pins the read of main's blob:

```
# test/scripts/build-loop-check.bats:77
@test "main walk: main's instruction files start it; a working-tree edit does not count; ...
# :84,:89
    printf 'Rules: @docs/wt-only.md\n' > CLAUDE.md
    for p in docs/wt-only.md CLAUDE.md docs/guide.md; do want "$p" -; done
```

So "test 77" was a line number. D4's own row still reads it unchanged:

```
# docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95
| D4 | ... (test 77 pins this as intended) | Low | security F2 | Fixed (4b7f2357) | ...
```

The correction is only an annotation inside G2. The commit message lists "the rubric's test-77 reference" under its wording fixes, but someone reading D4 still sees "test 77". The precise fix is to change D4 at :95 to "build-loop-check test 4".

**Evidence:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:95`, `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:168`, `test/scripts/build-loop-check.bats:77-95`

---

## Claim 2a: "main_imports pops its queue by copying the array (`queue=(\"${queue[@]:1}\")`) ... the per-start row's \"linear\" premise ... The same pop is on main; ... no gate caller exists until U2a4"

**Location:** `docs/reviews/override-log.md:461`
**Type:** Architectural / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the quoted pop is in main_imports on both this branch and main, that the per-start row (:442) says "Linear", and that nothing in `scripts/` outside the lib calls main_imports or `isimported main`. It does not cover the timing figures, which are Claim 2b.

The quoted pop is at `scripts/lib/dev-cycle-read.sh:845`: `f="${queue[0]}"; queue=("${queue[@]:1}")`. On main, `git show main:scripts/lib/dev-cycle-read.sh` has the same line at :744, inside `main_imports() {` at :713. The per-start row reads `docs/reviews/override-log.md:442`: "Linear in instruction-named files in ignored trees". Running `grep -rn 'main_imports\|isimported main' scripts/` without the lib returned nothing. The only caller of isimported outside the lib is `scripts/dev-cycle.sh:183`: `elif isimported tree "$lp"; then`, which uses the tree walk.

**Evidence:** `scripts/lib/dev-cycle-read.sh:843-845`, `docs/reviews/override-log.md:442`, `docs/reviews/override-log.md:461`, `scripts/dev-cycle.sh:183`

---

## Claim 2b: "5,000 imported untracked files 85.8 s against 42.7 s with an index pop"

**Location:** `docs/reviews/override-log.md:461`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers only a 300-file pilot. It does not establish either 5,000-file figure, or the shape of the curve past 300 files.

I built the harness `/tmp/u2a3c-lite-fc-Ko9n/t5000.sh`. Main's CLAUDE.md imports N files that main lacks, and each one is an untracked plain file in the checkout. I also wrote an index-pop mutant, `lib-idxpop.sh`, which replaces :844-845 with a `qi` index. The pilot was `N=300 bash t5000.sh <lib> lib-idxpop.sh`, run in cwd `/tmp/u2a3c-lite-fc-Ko9n` with exit 0 at 2026-10-07T23:42:53Z. It took 11,269 ms with the copying pop and 11,528 ms with the index pop, at a load of 52, so 300 files show no difference. Under that load the 5,000-file run would have taken several minutes per variant, and the coordinator stopped the run before it could start. **Blocker:** host load from another session. To verify, run `N=5000 bash t5000.sh` on an idle host. The output was captured inline above and has no log file. paraphrased — no quote available because the pilot's output was printed to the terminal, not to a file.

**Evidence:** `/tmp/u2a3c-lite-fc-Ko9n/t5000.sh`, `/tmp/u2a3c-lite-fc-Ko9n/lib-idxpop.sh`, `scripts/lib/dev-cycle-read.sh:843-845`

---

## Claim 3: "a checkout path it would walk that lies under ... a checkout ancestor that is anything but a plain searchable directory (absent ones and plain files excepted) ... fail it"

**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what main_checkout answers for each ancestor shape it was given: a symlink to a directory, a dangling symlink, a FIFO, an unsearchable directory, an absent path and a plain file. It does not establish the memo path, where an ancestor decided earlier in the walk changes before it is reused. A5 itself names that case as a snapshot limit.

```
# scripts/lib/dev-cycle-read.sh:754-756
    if [[ "$st" == d ]]; then
      if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2
      elif ! plaindir "$c" || [[ ! -x "$c" ]]; then return 1; fi
```

(excerpt ends :756; enclosing main_checkout() continues to :766 — read)

I ran `bash /tmp/u2a3c-lite-fc-Ko9n/tanc.sh <lib>` in cwd `/tmp/u2a3c-lite-fc-Ko9n`, with exit 0 at 2026-10-07T23:43:20Z. The results were `lnk/f.md 1`, `dang/f.md 1`, `fifo/f.md 1`, `nosx/sub/f.md 1`, `absent/f.md 2`, `pf/f.md 2`, `real/f.md 0` and `ok.md 0`. Every non-plain or unsearchable ancestor fails the walk with 1. An absent ancestor and a plain-file ancestor answer 2, meaning nothing loads below them.

**Evidence:** `scripts/lib/dev-cycle-read.sh:739-766`, `scripts/lib/dev-cycle-read.sh:104-107`, `/tmp/u2a3c-lite-fc-Ko9n/logs/tanc.txt`

---

## Claim 4a: "the caller contract is in the U2b bullet"

**Location:** `docs/working/plan-build-loop-handoff.md:126` (F11)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that the U2b bullet holds the duties the old F11 text listed (cache clear, empty `ls-files` stderr, git environment) and also the clean-worktree and `LC_ALL=C` duties. It does not establish that this contract is complete, which is U2a4's deferred item.

The U2b bullet at `docs/working/plan-build-loop-handoff.md:279` reads: "owes the walk four things: that checkout a clean worktree at MAIN_SHA ...; that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared ...; a git that prints nothing on stderr for `ls-files` ...; and the git environment ...". The same bullet continues: "... and runs the walk under `LC_ALL=C` (A5)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 4b: "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, an unreadable file, or anything but a plain file or directory"

**Location:** `docs/working/plan-build-loop-handoff.md:126` (F11)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F11's list of what main_checkout refuses. It does not establish anything about the U2a3c bullet at :277, which has similar older wording outside this diff.

This line was edited in this commit, but only its caller-contract clause changed. Its refusal list still names only "an unsearchable directory" among ancestors. main_checkout also refuses a symlinked ancestor, a dangling-link ancestor and a FIFO ancestor (Claim 3 run: `lnk/f.md 1`, `dang/f.md 1`, `fifo/f.md 1`). That is the same gap G2 recorded and this commit fixed in A5 and in the lib comment. The precise version is "under any checkout ancestor but a plain searchable directory (absent ones and plain files excepted)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:754-756`, `/tmp/u2a3c-lite-fc-Ko9n/logs/tanc.txt`

---

## Claim 5: "A caller of `main_checkout` other than `main_imports` passes ... only a PATH main lacks, as `main_imports` does (at a PATH main stores, a link or gitlink answers 1 and a blob is answered by the checkout's shape, which only the clean-worktree duty makes safe; U2a3c confirm F2)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Architectural / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both call sites in main_imports and main_checkout's answers for mode-120000, mode-160000, mode-100644 and mode-100755 entries. It does not establish that U2b honours the precondition, because U2b is not built.

```
# scripts/lib/dev-cycle-read.sh:830
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f"); done
# :836
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout ent pok "$f" || c=$?
# :881
      c=0; [[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p" || c=$?
# :747
  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
```

Both calls happen only when `ent` lacks the path: `t:` candidates are only those ent lacks. A blob mode does not match :747, so control falls through to the checkout checks. Build-loop-check tests 65 and 68 passed in the suite runs listed under Claim 15. Test 68 gives `b.md 0` and `e.md 0` for main's 100644 and 100755 blobs, and test 65 gives `lx 1` and `gx 1`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:830-838`, `scripts/lib/dev-cycle-read.sh:881`, `scripts/lib/dev-cycle-read.sh:747`, `test/scripts/build-loop-check.bats:973-981`, `test/scripts/build-loop-check.bats:1006-1012`, `/tmp/u2a3c-lite-fc-Ko9n/logs/blc-short.txt`

---

## Claim 6: "main_imports walks main's commit first, listing and checking the working tree as it goes, and then reads the working tree's own files"

**Location:** `scripts/lib/dev-cycle-read.sh:36-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the order of reads: ls-tree, then the checkout listing and checks, then main's drain, then the checkout files once `queue` empties. It does not establish that phase 2 reads only checkout files. Phase 2 also reads main's blobs that checkout files import, and the plan's U2a3c bullet says so.

Main's tree is listed first, at `:820` `nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA"`. The working tree is listed at `:829` `nul_list recs checkout_md` and checked at `:836` (main_checkout on start candidates). During main's drain, `:881` checks each import main lacks, and the symlink arm tests `! -L "$p"` at `:867`. Checkout files are read only after the swap at `:844` `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done`, through the `checkout)` arm at `:848`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:812-887`

---

## Claim 7: "or under any checkout ancestor but a plain searchable directory (absent ones and plain files excepted: nothing below them loads)"

**Location:** `scripts/lib/dev-cycle-read.sh:474-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** The same coverage and residue as Claim 3, which ran the same lines.

The code is the same as quoted in Claim 3 (`:754-756`), and so is the executed run (`tanc.sh`, 2026-10-07T23:43:20Z, exit 0, cwd `/tmp/u2a3c-lite-fc-Ko9n`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:754-756`, `/tmp/u2a3c-lite-fc-Ko9n/logs/tanc.txt`

---

## Claim 8a: "each resolved spelling it joins, which for a relative name carries ROOT_REAL"

**Location:** `scripts/lib/dev-cycle-read.sh:508-509`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers put()'s charge. It does not establish anything about a `~/` name, which is joined to the home directory instead and also leaves out ROOT_REAL.

```
# scripts/lib/dev-cycle-read.sh:586,589
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  work += length(c); if (work > wmax) exit 3
```

(excerpt ends :589; enclosing put() continues to :605 — read)

**Evidence:** `scripts/lib/dev-cycle-read.sh:570-605`

---

## Claim 8b: "the unit of its per-file bound of 50,000,000, about 1-4 s here, by the name's shape"

**Location:** `scripts/lib/dev-cycle-read.sh:509-510`
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the time to reach the 50,000,000 per-file bound for six shapes on this host, at a load of about 33. It does not establish times on an idle host or for other shapes.

I ran `timeout 120 bash /tmp/u2a3c-lite-fc-Ko9n/twork.sh <lib>` in cwd `/tmp/u2a3c-lite-fc-Ko9n`, with exit 0 at 2026-10-08T04:17Z and ROOT_REAL 40 characters long. Each shape below exited at the bound with rc=1, reporting about 50,0xx,xxx of work:

| Shape | Time to reach the bound |
|---|---|
| Many-component name (`@a/a/...`) | 3,797 ms |
| `../` run | 1,060 ms |
| Flat 12,000-character name | 205 ms |
| 4,000 tokens of 120 characters | 172 ms |
| Absolute name | 76 ms |

The upper end of 4 s is right. The lower end is not: flat, absolute and many-token shapes reach the bound in well under 1 s, even on a loaded host. The precise version is "about 0.1-4 s here, by the name's shape (most for many-component names)".

**Evidence:** `scripts/lib/dev-cycle-read.sh:570-634`, `/tmp/u2a3c-lite-fc-Ko9n/twork.sh`, `/tmp/u2a3c-lite-fc-Ko9n/logs/twork.txt`

---

## Claim 9: "as awk reads a number otherwise: its numeric prefix (so 1e3 is 1000 and inf no bound), or 0, so the first name fails it"

**Location:** `scripts/lib/dev-cycle-read.sh:527-529`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the host's awk, which is `/usr/bin/mawk`. It does not establish the same reading under another awk. gawk outside POSIX mode reads `inf` and `0x10` as 0, and neither the lib nor the comment pins an awk implementation.

The input line held four names, which yield 17 prefix candidates. I ran `bash /tmp/u2a3c-lite-fc-Ko9n/tleft.sh <lib>` at 2026-10-07T23:41:27Z in cwd `/tmp/u2a3c-lite-fc-Ko9n`. The script exited 0, and the trailing `command -v gawk` returned 1 because gawk is absent. Results by IMPORT_LEFT value:

| IMPORT_LEFT | Names printed | rc |
|---|---|---|
| `1e3` | 17 | 0 |
| `inf` | 17 | 0 |
| `nan` | 17 | 0 (also no bound) |
| `1e1` | 3 | 1 |
| `10abc` | 3 | 1 |
| `0x10` | 4 | 1 (mawk reads it as 16) |
| `-5` | 0 | 1 |
| `abc` | 0 | 1 |
| `0` | 0 | 1 |

The code is `scripts/lib/dev-cycle-read.sh:630`, `left = ENVIRON["IT_LEFT"] + 0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:603`, `scripts/lib/dev-cycle-read.sh:630`, `/tmp/u2a3c-lite-fc-Ko9n/logs/tleft.txt`

---

## Claim 10: "Wording (lib comments only)" / "no lib code change"

**Location:** `scripts/lib/dev-cycle-read.sh` (commit 4ce2c6bf subject and body)
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every added and removed line of the lib in 83c69b48..4ce2c6bf. It does not establish anything about other files.

I ran `git diff 83c69b48..4ce2c6bf -- scripts/lib/dev-cycle-read.sh | grep '^[+-]' | grep -v '^+++\|^---' | grep -v '^[+-]#'` in the worktree at 2026-10-07T23:36Z. grep exited 1 with no output, so every changed line is a `#` comment (13 insertions, 9 deletions). paraphrased — no quote available because the claim is about the absence of non-comment lines (no grep match).

**Evidence:** `scripts/lib/dev-cycle-read.sh:36-39`, `scripts/lib/dev-cycle-read.sh:474-477`, `scripts/lib/dev-cycle-read.sh:508-510`, `scripts/lib/dev-cycle-read.sh:528-529`

---

## Claim 11: "main_checkout refuses a PATH main stores as a link or gitlink ...; lx and gx, a link and a gitlink main stores, are absent there and answer 1 too."

**Location:** `test/scripts/build-loop-check.bats:973-981` (test 65)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the title, the comment and the assertion. It does not cover a link entry whose checkout node is a file.

The test runs `mkdir -p l g`, so `lx` and `gx` are never created. Its assertion, `"$output" = $'l 1\nl/f.md 1\ng 1\ng/f.md 1\nlx 1\ngx 1'`, follows from :747 refusing before any existence test. The suite runs (Claim 15) report `ok 65`.

**Evidence:** `test/scripts/build-loop-check.bats:973-981`, `scripts/lib/dev-cycle-read.sh:747`, `/tmp/u2a3c-lite-fc-Ko9n/logs/blc-short.txt`

---

## Claim 12a: "4,000 tokens @nI/a/b/c/d/x.md, none in the checkout: about 2.5 s here"

**Location:** `test/scripts/build-loop-check.bats:986`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers this host. It does not establish times on other hosts.

I ran `timeout 120 bash /tmp/u2a3c-lite-fc-Ko9n/t66in.sh <lib>` in cwd `/tmp/u2a3c-lite-fc-Ko9n` at 2026-10-08T04:17:27Z, and it exited 0. It printed `ok` with main_imports taking 2,389 ms at a load of 32.8. An earlier run at a load of about 59 took 10,149 ms.

**Evidence:** `test/scripts/build-loop-check.bats:983-991`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t66-inner.txt`

---

## Claim 12b: "(6.5 s with the CPUs oversubscribed 1.5x)"

**Location:** `test/scripts/build-loop-check.bats:986-987`
**Type:** Performance
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** executed
**Scope:** Covers nothing about the 6.5 s figure. My load runs only show the test passes under heavier oversubscription.

I ran `bash /tmp/u2a3c-lite-fc-Ko9n/t66.sh`, which adds 24 of my own busy loops on 16 CPUs (PIDs killed after the run), and it exited 0 at 23:40:36Z. Another session's 48 loops were running at the same time, so oversubscription was about 4.5x, not 1.5x. Test 66 passed both times under bats, in 31.6 s and 27.8 s of total bats time including setup. **Blocker:** I could not get a clean 1.5x condition on a host another session was loading.

**Evidence:** `/tmp/u2a3c-lite-fc-Ko9n/logs/t66-summary.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t66-load-1.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t66-load-2.txt`

---

## Claim 12c: "A hang guard only: the ${x@a} cost class (44.6 s at 3a35c8b9) is pinned host-independently by the ratio test below." (timeout 60)

**Location:** `test/scripts/build-loop-check.bats:987-988,990`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 60 s timeout, and that the next test fails on the `${x@a}` regression. It does not cover the 44.6 s historical figure, which I did not re-measure.

The test line reads `run --separate-stderr timeout 60 env LC_ALL=C bash -c ...` (:990). Claim 13 shows that the following test fails for both `${x@a}` mutants.

**Evidence:** `test/scripts/build-loop-check.bats:983-991`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t67-bats-mutE.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t67-bats-mutM.txt`

---

## Claim 13: "400 calls with ENT and MEMO of 30,000 entries each, against 400 with both empty ... Constant-time type checks give a ratio near 1 (0.4-1.0 here ...); a check linear in either array (${x@a}, as at 3a35c8b9) gives 59-141. Best of three rounds against a bound of 10"

**Location:** `test/scripts/build-loop-check.bats:993-1004` (test 67 title and comments)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the setup, the best-of-three minimum, the bound of 1000 (ratio×100), main_checkout reaching its checks in both arms, and the test failing for each array's `${x@a}` mutant. It does not establish the exact ranges on an idle host. I measured them only on a contended one, where they were similar but not identical.

The test fills `BE["z$i"]=100644; BM["y$i"]=2` for 30,000 entries each and leaves `E` and `M` empty. It keeps the minimum with `[[ -n "$best" && $best -le $x ]] || best=$x`, then asserts `"$output" -le 1000`.

I ran `bash t67.sh <lib>` in a scratch repo at 2026-10-07T23:36:21Z, with exit 0. Both arms answered rc=2, so the type check passes for both empty and full arrays. Rounds gave ratios 0.66, 1.17 and 0.97.

I then made one mutant per array, swapping `${mc_e[0]@a}` or `${mc_m[0]@a}` for the whole-array form. Under `t67.sh`, the ENT mutant gave 82, 215 and 67 and the MEMO mutant gave 115, 76 and 103. In `bats -f "cost per call"` on copies of the worktree, both failed: `ratio x100: 0 8853` and `ratio x100: 0 5737`, each with exit 1. That confirms the commit's "kills ${x@a} on either array".

**Evidence:** `test/scripts/build-loop-check.bats:993-1004`, `scripts/lib/dev-cycle-read.sh:745`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t67-head.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t67-mutants.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t67-bats-mutE.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/t67-bats-mutM.txt`

---

## Claim 14: "main_checkout answers a PATH main stores as a blob by the checkout's plain file there, pinned though U2b's precondition passes only paths main lacks"

**Location:** `test/scripts/build-loop-check.bats:1006-1012` (test 68)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a 100644 or 100755 blob over a readable plain checkout file. It does not cover a blob over a checkout directory or a link.

The test sets `declare -A E=([b.md]=100644 [e.md]=100755)` and expects `$'b.md 0\ne.md 0'`. It reports `ok 68` in both suite runs.

**Evidence:** `test/scripts/build-loop-check.bats:1006-1012`, `scripts/lib/dev-cycle-read.sh:747`, `scripts/lib/dev-cycle-read.sh:760-762`, `/tmp/u2a3c-lite-fc-Ko9n/logs/blc-short.txt`

---

## Claim 15: "68/68 under a 17- and a 74-character TMPDIR; dev-cycle 78, build-loop-read 19, hermeticity 2; shellcheck clean."

**Location:** commit 4ce2c6bf message body
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and passes at 4ce2c6bf with a 12-character and a 76-character TMPDIR, and shellcheck at the project gate's severity. It does not cover shellcheck's info and style notes, which the gate does not enforce and which sit on lines this commit left unchanged.

All runs used cwd `/workspace/.claude/wt-build-loop-u2a3c` with `LC_ALL=C`:

| Command | TMPDIR | Time (UTC) | Result |
|---|---|---|---|
| `bats test/scripts/build-loop-check.bats` | `/tmp/fc-xpyF` (12 characters) | 2026-10-07T23:31Z | exit 0, 68 ok |
| `bats test/scripts/build-loop-check.bats` | 76 characters | 23:31:55-23:32:21Z | exit 0, 68 ok |
| `test/scripts/dev-cycle.bats` | `/tmp/fc-*` (the same short form) | ending 23:35:56Z | 78/78, exit 0 |
| `test/scripts/build-loop-read.bats` | `/tmp/fc-*` (the same short form) | ending 23:35:56Z | 19/19, exit 0 |
| `test/fixture-hermeticity.bats` | `/tmp/fc-*` (the same short form) | ending 23:35:56Z | 2/2, exit 0 |
| `shellcheck -x -e SC1091 -s bash -S warning` on the lib and the suite (the `scripts/health-check.sh:480` flags) | none | 23:35:56Z | exit 0, empty output |

Plain `shellcheck` on the lib exits 1 with SC2016, SC2004 and SC2015 info and style notes at :666, :758, :764, :787, :849 and :851. None of those lines is in this diff.

**Evidence:** `scripts/health-check.sh:480`, `/tmp/u2a3c-lite-fc-Ko9n/logs/blc-short.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/blc-long.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/dev-cycle.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/build-loop-read.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/fixture-hermeticity.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/shellcheck-gate.txt`, `/tmp/u2a3c-lite-fc-Ko9n/logs/shellcheck.txt`

---

## Claims Requiring Attention

### Incorrect
None.

### Stale
None.

### Mostly Accurate
- **Claim 1** (`docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:168`): the correction is only an annotation in G2. D4's own row at :95 still says "test 77" and should say build-loop-check test 4.
- **Claim 4b** (`docs/working/plan-build-loop-handoff.md:126`): F11 lists only "an unsearchable directory" among refused ancestors. main_checkout also refuses symlinked, dangling-link and FIFO ancestors, so F11 should use the wording now in A5 and the lib.
- **Claim 8b** (`scripts/lib/dev-cycle-read.sh:510`): the per-file bound costs about 0.1-4 s, not 1-4 s. Flat, absolute and many-token shapes reach it in 76-205 ms.

### Unverifiable
- **Claim 2b** (`docs/reviews/override-log.md:461`): the 85.8 s and 42.7 s figures for 5,000 files need `N=5000 bash t5000.sh` against the lib and the index-pop mutant on an idle host. Another session's load blocked it, and the 300-file pilot shows no difference.
- **Claim 12b** (`test/scripts/build-loop-check.bats:986`): "6.5 s at 1.5x oversubscription" needs a clean 1.5x load. The host carried about 4.5x, and the test still passed under that.

## Escalations

None at blocking grade. All three Mostly-accurate items are wording in docs or comments, and no lib code is affected. Claim 4b is the same gap G2 recorded for A5 and the lib comment, left in the F11 row of the plan. The two Unverifiable items are timing figures that rationale relies on, not code. Neither carries a correctness property, and the deferral in Claim 2b rests on the deferral row's trigger, not on the exact seconds. No hallucination-pattern entry was added because there is no Incorrect verdict.
