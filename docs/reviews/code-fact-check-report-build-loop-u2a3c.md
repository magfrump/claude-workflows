Commit: 3a35c8b9
# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-build-loop-u2a3c (branch `feat/build-loop-u2a3c`)
**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 3a35c8b9) plus the commit messages of main..HEAD (3e58eb9c, cb9723c3, 27364085, 80cc6224, 61e2e734, 21b35ebf, 2fbd929b, 3a35c8b9): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c, U2b), `docs/reviews/override-log.md` (rows 439-456), and the iteration-2 rubric's claims about the code. Merged from three replicates of the final confirming pass (iteration 3): `code-fact-check-report-build-loop-u2a3c-r1.md`, `-r2.md`, `-r3.md`.
**Checked:** 2026-10-07
**Commit:** 3a35c8b9
**Replication:** k=3
**Total claims checked:** 64
**Summary:** 41 verified, 14 mostly accurate, 2 stale, 1 incorrect, 6 unverifiable

Merge method: `skills/code-review/SKILL.md`, "Merging replicate verdicts (most-severe-wins)", steps 1-5. Claims were clustered by file, overlapping line range (±5) and substance, and emitted at the finest granularity any replicate used; a replicate that verdicted only a compound records that verdict on each sub-claim row marked `(compound)`. Each claim carries the most severe replicate verdict and the winning replicate's evidence; annotations are the union of every replicate's caveats. Replicate scratch directories: r1 `/tmp/u2a3c-i2-fc1-6NBv/`, r2 `/tmp/u2a3c-i2-fc2-zy90/`, r3 `/tmp/u2a3c-i2-fc3-j0eh/`. All three replicates read the hallucination-pattern log, and none matched a logged pattern; every commit-message test count was re-checked.

Suites at HEAD, as each replicate ran them: r2 and r3 report build-loop-check 63/63, dev-cycle 78/78, build-loop-read 19/19 and fixture-hermeticity 2/2, all exit 0. r1 reports build-loop-check 62/63 under a 27-character TMPDIR (test 59 fails in the full file), with the other suites exit 0 (Claim 1).

---

## Claim 1: "Tests after fixes (2fbd929b): build-loop-check 63/63, dev-cycle 78/78, build-loop-read 19/19, fixture-hermeticity 2/2"; "shellcheck -S warning clean"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:21`
**Type:** Configuration / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suites' counts and pass status at 3a35c8b9 under two TMPDIR lengths; does not establish pass status on hosts whose bats run directory is longer than this one's.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "build-loop-check is 62/63 when the bats root is 56+ characters; test 59's fixed `IMPORT_WORK_MAX=1000` fails as `w` grows with ROOT_REAL" · r2: "does not cover the full health check's other sections at 61e2e734 ('only'), which were not re-run"; shellcheck SC2034 on `pok` at 61e2e734 and clean at HEAD verified · r3: does not establish the D=1950 (64 s) and 256 MiB (58 s, 2 GiB) figures, not re-measured.

The counts are right (`grep -c '^@test'`: 63, 78, 19; fixture-hermeticity 2). Running the suites with a 27-character TMPDIR (`/tmp/u2a3c-i2-fc1-bats-XXXX`), build-loop-check is **62/63** in two full runs: test 59 fails every time in the full file and passes when run alone (`-f`).

Cause (executed): the test fixes the walk budget at a constant,

```bash
# test/scripts/build-loop-check.bats:907
        IMPORT_WORK_MAX=1000; want="$(printf "%s\n" 1000 $((1000 - w)) $((1000 - 2 * w)) $((1000 - 3 * w)) | sort -n | tr "\n" " ")"
```

while `w` grows with ROOT_REAL's length, because `put` charges the resolved spelling:

```awk
# scripts/lib/dev-cycle-read.sh:581-584
  if (substr(c, 1, 1) != "/") c = root "/" dir "/" c
  # The resolved spelling is what costs (its length grows with the depth of
  # the importing file), so it is charged too, and each is resolved once per file.
  work += length(c); if (work > wmax) exit 3
```

r1 measured `w` for the test's file: ROOT_REAL length 55 gives 4w = 992, length 56 gives 4w = 1008. Past 1000 the caps phase's walk fails and the `set -euo pipefail` script exits silently after "0 main ok". The fixture root is `$TMPDIR/bats-run-XXXXXX/test/<N>/repo`, so test 59 fails once TMPDIR is 27+ characters. The default `/tmp` passes; a 97-character TMPDIR fails it alone too.

**Evidence:** `test/scripts/build-loop-check.bats:897-912`, `scripts/lib/dev-cycle-read.sh:580-600`; command `TMPDIR=$T LC_ALL=C timeout 900 bats test/scripts/build-loop-check.bats` (cwd worktree, exit 1, twice): `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check-run2.log`; `/tmp/u2a3c-i2-fc1-6NBv/logs/caps-tmpdir-length.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/work-vs-rootlen.log`; r2 `/tmp/u2a3c-i2-fc2-zy90/logs/bats-build-loop-check.txt`; r3 `/tmp/u2a3c-i2-fc3-j0eh/logs/build-loop-check.log`

---

## Claim 2: Rubric B2: "D=1000: 0.62 s (main 0.50, 21b35ebf 10.67). Test with a 6 s timeout fails at 21b35ebf."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:32`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the D=1000 timings and the deep-token test failing on 21b35ebf's lib; does not establish the D=1950 (64 s) figure, which no replicate re-measured.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: kill side has only 1.8x margin (21b35ebf 11.0 s against `timeout 6`), so on a host about twice as fast the regression would survive (escalated to test-strategy) · r3: "does not establish the D=1950 (64 s) and 256 MiB (58 s, 2 GiB) figures"; would not discriminate on a host more than about 1.8x faster.

r1 timed `main_imports` on one `@a/…/x.md` token 1,000 deep: 21b35ebf 10,855 ms and 11,750 ms; 2fbd929b 669 ms and 670 ms; main 532 ms. With HEAD's tests and 21b35ebf's lib, "stays linear" fails; with HEAD's lib it passes. (r2: HEAD 0.66 s, 21b35ebf 11.00 s, main 0.55 s. r3: main 511/502 ms, 21b35ebf 10461/10864 ms, HEAD 658/652 ms.)

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/deep.sh` (cwd scratch, exit 0, 2026-10-07T20:16:27Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/deep.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`; `/tmp/u2a3c-i2-fc2-zy90/logs/deep-timing.txt`; `/tmp/u2a3c-i2-fc3-j0eh/logs/deep-timing.log`

---

## Claim 3: Rubric B3: "Link text over 4096 bytes fails before it is read"

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:33`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the link-text test failing on 21b35ebf's lib and passing on HEAD's; does not re-measure the 256 MiB (58 s, 2 GiB) figure.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

With HEAD's tests and 21b35ebf's lib, "longer than 4096 bytes" fails; with HEAD's lib it passes (r1).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`, `scripts/lib/dev-cycle-read.sh:841-859`

---

## Claim 4: Rubric B4: "One survivor fails open: a link main stores two levels below a directory the checkout lacks (M13, `continue` → `break`) passed every test … T1 … and T2 … applied. HEAD was correct; the gap was the tests."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:34`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers M13 as applied to 21b35ebf's lib (`[[ -z "$st" ]] || continue` → `break`). It survives 21b35ebf's own suite (57/57 ok) and fails HEAD's T2. It does not cover the other mutants named (M14, M16, M18-M20, M23).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish that T2 alone kills a fail-open mutant of HEAD's bottom-up loop (it does not)": a mutant breaking out of the top-down loop once an ancestor is absent (HEAD analog of M13) fails T1 but passes T2 (escalated to test-strategy).

`logs/m13-vs-21b35ebf-suite.txt` shows 57 ok and 0 not ok. `logs/m13-vs-HEAD-T2.txt` shows `not ok 1 main walk fails on a path under a link main stores below a directory the checkout lacks…`. Unmutated, T2 passes at 21b35ebf (`logs/i2tests-at-21b35ebf.txt`), which matches "HEAD was correct" (r2).

**Evidence:** `test/scripts/build-loop-check.bats:884-895`, `/tmp/u2a3c-i2-fc2-zy90/logs/m13-vs-21b35ebf-suite.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/m13-vs-HEAD-T2.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/i2tests-at-21b35ebf.txt`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants3.log`

---

## Claim 5: Rubric C8: "The absent-under-checkout-dir-link shape changed 2 → 1 (stricter) … Pinned by T1 (`sd/nx.md 1`)."

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:47`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers T1's row at HEAD and at 21b35ebf. It does not re-derive the "2" of main's earlier rule.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

T1 sets `ln -s sdt sd` and expects `sd/nx.md 1`, which passes at HEAD. The ancestor `sd` fails `plaindir` (`:745`), so the call returns 1 (r2). r1 and r3 confirm the row at `test/scripts/build-loop-check.bats:871`/`:874`.

**Evidence:** `test/scripts/build-loop-check.bats:854-855`, `:874`, `scripts/lib/dev-cycle-read.sh:745`

---

## Claim 6: Rubric C9: "Gitfile 'as Claude Code does' unverifiable here … reads only add names or fail".

**Location:** `docs/reviews/code-review-rubric-2026-10-07-feat-build-loop-u2a3c.md:48`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** "Reads only add names or fail" is verified for the code: phase 2 only appends to IMPORTED_MAIN or returns 1. The Claude Code half stays unverifiable.
**Replicate verdicts:** r1=— · r2=Unverifiable · r3=— · single-replicate detection
**Replicate annotations:** none

paraphrased — no quote available because the claim's open half concerns Claude Code's binary, not this repo (r2). The repo half is quoted in Claims 22 and 39.

**Evidence:** `scripts/lib/dev-cycle-read.sh:832-875`

---

## Claim 7: Override rows 439-441, 443, 444 (U2a3c iteration 1): "Comment, A5 and the U2b bullet now say the caller clears IMPORTED_MAIN_DONE"; "A FIFO ... is never listed by `git ls-files --others`"; "the snapshot assumption is now written in the block comment and A5"; "Both callers test the code explicitly"; "its only caller"

**Location:** `docs/reviews/override-log.md:439-441,443-444`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each row's cited mitigation text as it stands at HEAD, the FIFO listing and the two call sites; does not establish whether Claude Code loads a FIFO (the row says untraced).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r2: rows before 448 treated as out of scope · r3: "Rows 439-447 are history and are not re-verdicted here" (Claim 52).

The cache-clear text is in the lib (`# the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout,` `scripts/lib/dev-cycle-read.sh:487`), in A5 ("so a caller clears `IMPORTED_MAIN_DONE` after any checkout change", `docs/working/known-issues-dev-cycle.md:18`) and in the U2b bullet ("`IMPORTED_MAIN_DONE` cleared (the cache key ignores the checkout)", `docs/working/plan-build-loop-handoff.md:279`). `git ls-files -z --others` in a repo holding a FIFO `f.md`, a link `l.md` and a file `r.md` listed only `l.md` and `r.md`. Snapshot: `# snapshot: a file swapped between its admission and its read is not seen.` (`scripts/lib/dev-cycle-read.sh:485`). Both callers capture the code: `main_checkout ent pok "$f" || c=$?` then `[[ $c -ne 1 ]] || return 1` (`:825-826`) and `main_checkout ent pok "$p" || c=$?` then `[[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }` (`:870-871`); `git grep` finds no other call outside the test (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:485-491,825-826,870-871`; `/tmp/u2a3c-i2-fc1-6NBv/logs/fifo-listing.log`

---

## Claim 8: Override row 448: "the candidates are lower-cased by lower_all under nul_list, so a tr that dies after a partial flush fails the walk; the test fails at 3e58eb9c."

**Location:** `docs/reviews/override-log.md:448`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the batch-lower path in main_imports and the N1 test's failure at 3e58eb9c. It does not establish behaviour for a `tr` that dies after a partial flush of a different shape than the test's shim, which drops 3 bytes.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish the per-file `lower` calls, which still use a plain `$(...)`".

```
# scripts/lib/dev-cycle-read.sh:700
lower_all() { local -; set -o pipefail; printf '%s\0' "$@" | tr 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' 'abcdefghijklmnopqrstuvwxyz'; }
# scripts/lib/dev-cycle-read.sh:820-821
  [[ ${#cand[@]} -eq 0 ]] || nul_list low lower_all "${cand[@]}" || return 1
  [[ ${#low[@]} -eq ${#cand[@]} ]] || return 1
```
The fix is `nul_list`'s `rc=0` sentinel (`:695`), which a failed `tr` under pipefail never prints. The 27364085 tests run against 3e58eb9c's lib give `not ok 2 main walk fails when the batch tr dies after a partial flush…` (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:695-700`, `scripts/lib/dev-cycle-read.sh:820-821`, `test/scripts/build-loop-check.bats:800-809`, `/tmp/u2a3c-i2-fc2-zy90/logs/c27364085-vs-3e58eb9c.txt`, `/tmp/u2a3c-i2-fc3-j0eh/logs/old-3e58eb9c-batch_tr_dies.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 9: Override row 449: "capped_read is the one reader for checkout files and main's blobs, and drains a pipe so git cat-file never dies of SIGPIPE under pipefail (a no-drain mutant fails the test)."

**Location:** `docs/reviews/override-log.md:449`
**Type:** Behavioral
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the drain's mechanism and its test. It does not establish the link-blob half, which row 454 already corrects.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Stale
**Replicate annotations:** r1: no-drain mutant fails the 4 MiB test with `walk: failed` · r2: no-drain mutant fails both 27364085's and HEAD's 4 MiB test; "does not re-measure the 58 s / 2 GiB pre-fix figure" (row 454) · r3: no override row amends row 449's "drains a pipe".

The row describes 27364085's `[[ ! -p /dev/stdin ]] || cat > /dev/null`. Since 2fbd929b, capped_read drains only when its caller passes the word `drain`, not whenever stdin is a pipe: `capped_read() { head -c 4194305 || return 1; [[ "${1:-}" != drain ]] || cat > /dev/null; }` (`scripts/lib/dev-cycle-read.sh:709`). Only the blob arm passes it (`:839`). Row 454 corrects the link-blob half, and the rubric's C1 records the mechanism change, but no override row amends row 449's "drains a pipe". The mutant claim still holds at HEAD: `capped_read drain |` → `capped_read |` is killed by the 4 MiB test (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:701-709`, `scripts/lib/dev-cycle-read.sh:837-840`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-nodrain.log`, `/tmp/u2a3c-i2-fc2-zy90/logs/HEAD-vs-nodrain.txt`

---

## Claim 10: Override row 450 (and commit 80cc6224): "main_checkout memoizes the ancestors it has passed (18 realpath calls in the test's walk, against 102 unmemoized and 74 at 3e58eb9c); it also fixed a crash on an empty main tree with an untracked start"

**Location:** `docs/reviews/override-log.md:450`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts at the revisions the row names: 80cc6224 = 18, an unmemoized mutant of 80cc6224 = 102, 3e58eb9c = 74, and the empty-tree test failing at 27364085. It does not cover HEAD, which now makes 10 calls (Claim 42).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: the 18 count is not HEAD's (10 at HEAD).

The count comes from a realpath shim over the memo test's shape. It reads 74 at 3e58eb9c and 27364085, 18 at 80cc6224 and 21b35ebf, and 10 at HEAD. The unmemoized mutant replaces `then mc_m[$c]=1` with `then :` in 80cc6224's lib and reads 102. The crash fix is the guarded type check:
```
# scripts/lib/dev-cycle-read.sh:736
  set +u; [[ "${mc_e@a}" == *A* && "${mc_m@a}" == *A* ]] || return 1
```
80cc6224's empty-tree test is `not ok` against 27364085's lib (r2; r1 and r3 record `line 699: mc_e: unbound variable`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:733-736`, `test/scripts/build-loop-check.bats:834-840`, `/tmp/u2a3c-i2-fc2-zy90/logs/rpcount.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/rpcount-nomemo.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/c80cc6224-emptytree-vs-27364085.txt`, `/tmp/u2a3c-i2-fc3-j0eh/logs/realpath-counts.log`

---

## Claim 11: Override row 451: "IMPORT_WORK_MAX bounds the work charged over a whole walk, so N adversarial files cost one bound … one bound still costs about 5 s"

**Location:** `docs/reviews/override-log.md:451`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk-wide accumulation and the per-file mutant's behaviour against 61e2e734's test and HEAD's T3. It does not re-measure "about 5 s" per bound, and row 455 narrows the bound to charged work only.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: one bound of the many-component shape measured 46,301,220 charged in 3,444 ms (about 5 s at 50,000,000) · r3: per-file mutant killed by T3.

```
# scripts/lib/dev-cycle-read.sh:677-682
import_work() {
  local -n iw_o="$1" iw_t="$2"; local iw_w="${iw_o##*/}"
  [[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1
  iw_o="${iw_o%/*}"; iw_o="${iw_o%$'\n'}"
  (( (iw_t += iw_w) <= IMPORT_WORK_MAX ))
}
```
The per-file mutant passes `IMPORT_WORK_LEFT=$IMPORT_WORK_MAX`. Against 61e2e734's test it prints `-1 tree ok / -1 main ok` and the test fails; against HEAD's T3 it fails both the `-1` rows and the caps rows (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-682`, `:775`, `:837-840`, `test/scripts/build-loop-check.bats:897-912`, `/tmp/u2a3c-i2-fc2-zy90/logs/c61e2e734-vs-perfile.txt`, `/tmp/u2a3c-i2-fc2-zy90/logs/HEAD-T3-vs-perfile.txt`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-perfile.log`

---

## Claim 12: Override row 452: "the rebase resolution 3e58eb9c dropped the cache-clear rule, the FIFO start and the snapshot assumption from known issue A5 and U2b's 'owes the walk three things' clause ... Iteration 2 restored"

**Location:** `docs/reviews/override-log.md:452`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers presence of the three items in A5 and the U2b clause at 2b1399ab, 3e58eb9c and HEAD; does not establish the restored wording is identical to 2b1399ab's.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that the restored MEMO rule is complete" (Claim 20b) · r3: accuracy of the restored text is checked in the A5/plan claims.

Counts per revision (A5 row: `IMPORTED_MAIN_DONE`/`FIFO`/swap-or-snapshot; U2b bullet: "three things"): 2b1399ab 1/1/1(swapped)/1; 3e58eb9c 0/0/0/0; HEAD 1/1/1/1 (r1; r2 also 21b35ebf 0/0/0).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:279`; `git show <rev>:<file> | grep -c` (cwd worktree, exit 0; paraphrased — no captured file because the counts were printed inline and are reproduced in full here)

---

## Claim 13: Override row 453: "main_imports records the parser's whole output before the seen test ... Test 'a main import of an untracked start' pins it"

**Location:** `docs/reviews/override-log.md:453`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the record-before-seen order and that a test pins it; does not establish a test by the quoted name.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "does not establish a mutant kill for that order, which was not run" · r3: "does not establish a mutation test of a per-candidate record".

The order holds: `i="$(lower "$out")" || { IMPORTED_MAIN=error; return 1; }; IMPORTED_MAIN+="$i"$'\n'` (`scripts/lib/dev-cycle-read.sh:866`) precedes the per-name loop with `[[ -z "${seen[$p]+set}" ]] || continue` (`:869`). No test is titled "a main import of an untracked start"; the pinning test is `@test "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)"` (`test/scripts/build-loop-check.bats:921`), whose `want docs/AGENTS.md imported` fails if the record moved after the seen test. Precise version: name that title (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:863-874`, `test/scripts/build-loop-check.bats:921-930`

---

## Claim 14: Override row 454: "The symlink arm fails link text over 4096 bytes (`git cat-file -s`) before reading it; test added"

**Location:** `docs/reviews/override-log.md:454`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the fix and its test; does not re-measure the cited "256 MiB link blob, 58 s and 2 GiB" (not re-run: 2 GiB of memory per run).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: a 64 MiB link blob at a start name fails the walk in 0.02 s · r3: mutant without `&& [[ "$i" -le 4096 ]]` killed.

```bash
# scripts/lib/dev-cycle-read.sh:842-843
        # Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below.
        i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }
```
(excerpt ends :843; enclosing `120000)` arm continues to :859 — read)

The test fails on 21b35ebf's lib and passes on HEAD's (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:841-859`, `test/scripts/build-loop-check.bats:942-950`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`, `/tmp/u2a3c-i2-fc2-zy90/logs/biglink.txt`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-nosizecap.log`

---

## Claim 15: Override row 455: "capped_read's drain (git inflates the whole blob, about 0.7 s per GiB) and the scan of @-less lines are uncharged, and a caller running both walks pays two bounds"

**Location:** `docs/reviews/override-log.md:455`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the drain rate on this host and which work is charged; does not establish the rate on other hosts.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2 (Medium confidence): "The drain rate is host-dependent: 0.84 s per GiB measured here, against 'about 0.7'"; a 256 MiB blob drained in 0.21 s · r3: "does not establish row 455's 'about 0.7 s per GiB', which I did not measure".

`git cat-file blob <1 GiB zeros> | (head -c 4194305; cat)` took 788 ms (4 ms without the drain). Work is charged only in `emit`, `put` and `splice` (`work +=` at `scripts/lib/dev-cycle-read.sh:566,584,617`); `scan` (`:601-613`) adds nothing; `work=0` is a local of each walk (`:757`, `:802`) (r1).

**Evidence:** inline run (cwd mktemp repo, exit 0, 2026-10-07T20:18Z; output quoted: `1GiB drain ms=788`, `no-drain ms=4`); `scripts/lib/dev-cycle-read.sh:564-629`

---

## Claim 16a: Override row 456: "Each call site is one line" (the reader, parser, trailer-strip and budget chain written out three times)

**Location:** `docs/reviews/override-log.md:456`
**Type:** Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three reader→parser→trailer→budget sites; does not assess whether they should be shared.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=—
**Replicate annotations:** r2: "does not assess the deferral".

Each site is one logical command over two physical lines, e.g. `out="$(capped_read < "$f" | IMPORT_LEFT=… import_targets "$d")" \` / `&& import_work out work || { IMPORTED=error; return 1; }` (`scripts/lib/dev-cycle-read.sh:775-776`; also `:837-838`, `:839-840`), and the budget add is a further line at each site (`:778`, `:864`). Precise version: "each call site is one statement" (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:775-778,837-840,864`

---

## Claim 16b: Override row 456: "main_checkout's comment now says why it differs from blocker"

**Location:** `docs/reviews/override-log.md:456`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the three call sites and the comment. It does not assess the deferral.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

The comment at `:730-731` reads: "unlike blocker it answers 2 below a plain file and needs a searchable directory (a second traversal on purpose)" (r2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:730-731`, `:775-776`, `:837-840`

---

## Claim 17a: Known issue A5: the checkout phase's fail rules ("under a directory main stores as a link or gitlink or under an unsearchable directory, anything but a plain file or directory there (or nothing), an unreadable checkout file, a `..` after a checkout link in link text, and a checkout listing git prints any stderr for fail it; a linked worktree's `.git` file is read like any checkout file")

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed fail rule (tests and mutants), the .git rule and the pointer; does not establish anything about Claude Code's loading of the same shapes.
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: its Mostly-accurate verdict rests on the pointer half (Claim 17b); it found every fail rule matching the code · r2: "does not establish the claim that Claude Code reads a gitfile" · r3: "does not establish behaviour under a non-default git environment, which the U2b clause covers"; mutants removing the mode check, the `-x` test or the readability test are each killed.

Every fail rule matches `main_checkout` (`scripts/lib/dev-cycle-read.sh:742,745,751-752`), the `..`-after-link check (`[[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1`, `:856`) and `checkout_md` (`[[ -z "$e" ]]`, `:716`); the suites exercising them pass. The pointer overstates: the lib's block comment holds the cache-clear and HOME rules (`:486-491`) but not the git-environment duty (`GIT_INDEX_FILE`, fsmonitor, …), which `grep` finds nowhere in the lib; it is only in the U2b bullet (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:464-491,713-755,841-859`; `grep -n GIT_INDEX_FILE scripts/lib/dev-cycle-read.sh` (no hits); `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-nomode.log`

---

## Claim 17b: Known issue A5: "The walk's cache ignores the checkout, so a caller clears `IMPORTED_MAIN_DONE` after any checkout change (the lib's block comment above `IMPORTED=` holds the caller contract; the U2b bullet names what U2b owes it)."

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Architectural / Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the cache key and the lib comment's contents. It does not establish that any caller honours the contract (none exists before U2a4/U2b).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "Precise version: 'the lib's block comment holds the cache rule; the U2b bullet holds all three duties'" · r2: verified the cache-clear sentence and the cache test (`- - z.sh`); "nothing in this pass covers whether any caller honours the clear".

The key is `"$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL"` (`scripts/lib/dev-cycle-read.sh:806-807`). The lib comment holds the cache-clear and HOME-clear duties: "so a caller whose checkout may have changed (a file added or edited) sets IMPORTED_MAIN_DONE="" to walk again ... A caller that changes HOME clears both" (`:488-491`). It does not hold the git-environment duty (GIT_INDEX_FILE, fsmonitor, sparse checkout and so on) or the `LC_ALL=C` duty. `grep -n 'GIT_INDEX_FILE\|fsmonitor\|sparse' scripts/lib/dev-cycle-read.sh` finds nothing (paraphrased — no quote available because the claim concerns text that is absent). Those duties appear only in the U2b bullet and the override log (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-496`, `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 17c: Known issue A5, not covered: "a start file that is not a regular file or symlink (git does not list a FIFO), a checkout file swapped between its admission and its read (the walk reads the checkout as one snapshot)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39's listing of a FIFO named like a start. It does not establish whether Claude Code loads a FIFO.
**Replicate verdicts:** r1=— · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish the FIFO listing claim by execution in this pass (it was executed in iteration 1, P6)".

Command (cwd: a fresh repo under `/tmp/u2a3c-i2-fc3-j0eh/fz`, holding a `mkfifo AGENTS.md` and a plain GEMINI.md): `git ls-files -z --cached --others -- ':(glob,icase)**/*.md'`. Exit 0, 2026-10-07T20:19Z. It listed only `GEMINI.md` (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:483-485`, `scripts/lib/dev-cycle-read.sh:713-716`, `/tmp/u2a3c-i2-fc3-j0eh/logs/fifo-ls.log`

---

## Claim 18: F11: "one admission check (`main_checkout`) refuses a path under a link or gitlink main stores, under an unsearchable directory, or anything but a plain file or directory, and a checkout listing git prints any stderr for fails the walk; the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the refusal list and the pointer; does not establish the omitted rule's test coverage beyond T1.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Verified
**Replicate annotations:** r2: "Precise version: '…or anything but a readable plain file or a plain directory'"; does not cover the U2a3c bullet, which lists the unreadable file · r3 (Verified): "does not cover the unreadable-file refusal, which F11 omits (A5 and the U2a3c bullet state it)".

All listed refusals are in `main_checkout`; the list omits its unreadable-plain-file refusal, `if rawfile "$c"; then [[ -r "$c" ]]; return; fi` (`scripts/lib/dev-cycle-read.sh:751`), which the U2a3c bullet and A5 both list. The U2b pointer is right (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755`, `docs/working/plan-build-loop-handoff.md:126,277,279`

---

## Claim 19: U2a3c bullet: "Built 2026-10-07 ...: the fail rules as stated ..., `capped_read`, the work bound `IMPORT_WORK_MAX` (reported by the parser's trailer, charged by `import_work`), `main_checkout`'s ancestor memo, the `.git` rule, and N1 (`lower_all` under `nul_list`)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named item's presence and its test; does not establish the bullet's carried-from-U2a3b requirements text (history).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the `.git` special case is gone (`if [[ "$p" == .git ]]` is in main's lib, not HEAD's).

Each item exists (`capped_read` `:709`, `IMPORT_WORK_MAX` `:511`, trailer `END { if (trail) print "/" (work + 0) }` `:629`, `import_work` `:677-682`, `pok` `:804`, `lower_all` `:700` used as `nul_list low lower_all "${cand[@]}"` `:820`) and its tests pass; the fail-rule mutants fail their tests (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-755,801-876`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`

---

## Claim 20a: U2b bullet: U2b "owes the walk three things: that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared (the cache key ignores the checkout); a git that prints nothing on stderr for `ls-files` (any stderr fails the walk closed); and the git environment the override log hands the caller"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Architectural / Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three duties and the MEMO rule. It does not establish that the stated rule is complete for another caller.
**Replicate verdicts:** r1=— · r2=Verified · r3=Mostly accurate (compound)
**Replicate annotations:** r2 (Verified): the cache key omits the checkout (`:806-807`), `checkout_md` fails on any stderr (`:716`); "does not verify the override log's git-environment list item by item" · r3: its Mostly-accurate verdict rests on the MEMO-rule half (Claim 20b); "The three duties match the code (`scripts/lib/dev-cycle-read.sh:716`, `:806`)".

The three duties match the code (`scripts/lib/dev-cycle-read.sh:716`, `:806`). The MEMO rule leaves out a third condition (Claim 20b) (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:486-491`, `:716`, `:806-807`, `/tmp/u2a3c-i2-fc3-j0eh/logs/memo-path-ent.log`

---

## Claim 20b: U2b bullet: "A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the contract another caller needs; does not establish any current caller other than main_imports (there is none).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r2: repro `ENT=([a]=120000)`, `main_checkout ENT MEMO a` then `a/f` → `path=a/f new=0 old=1`; fresh MEMO gives `new=1`; the random differential found the same divergence (`a/u/n`, ENT `a=160000`) when calls were allowed on ENT paths; "Followed as written, it can admit a file under a link main stores" · r3: repro `c/x.md new=2 old=1` with `E=([c]=120000)`; "The precise rule is 'a fresh MEMO per walk and ENT, and a PATH that ENT does not hold'".

The stated duties are needed but not sufficient: such a caller must also never pass a PATH that ENT holds, because the PATH arm memoizes `d` without testing PATH's own main mode (Claim 34), and a later call through it then skips that mode. main_imports meets this by calling only when `ent` lacks the path (`[[ -n "${ent[$p]+set}" ]] || main_checkout ent pok "$p"`, `scripts/lib/dev-cycle-read.sh:870`; `t:` candidates only when `ent` lacks them, `:819`). Precise version: add "and only for a path ENT does not hold" (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755,819,870`; `/tmp/u2a3c-i2-fc1-6NBv/logs/memo-path-in-ent.log`, `/tmp/u2a3c-i2-fc2-zy90/logs/repro1.txt`, `/tmp/u2a3c-i2-fc3-j0eh/logs/memo-path-ent.log`

---

## Claim 21: Lib header: "main_imports reads main's commit first and then the working tree (the checkout's start files and imported files main lacks, which can only add imports or fail it ...); imported_names, checkout_md and main_checkout read the working tree at ROOT_REAL."

**Location:** `scripts/lib/dev-cycle-read.sh:36-39`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers append-only recording and the read order. It does not establish the path checks that phase 1 makes in the checkout (main_checkout runs on imports main lacks during main's walk too), which can also only fail the walk.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

`IMPORTED_MAIN+="$i"$'\n'` is the only write to the result after `IMPORTED_MAIN=$'\n'` (`:831`, `:866`). Phase 2 starts only when `queue` is empty: `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:833`) (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:831-875`

---

## Claim 22: Block comment: "Once main's walk is done, a second phase walks the checkout's start files main lacks (untracked, ignored or only in the index) and the imported files main lacks, when each is a plain file there, and only appends. ... a checkout path it would walk ... that lies under a directory main stores as a symlink or gitlink or under an unsearchable directory, or that the checkout holds as anything but a readable plain file, a plain directory or nothing (the root included), or a checkout listing git prints any stderr for, fail the walk"

**Location:** `scripts/lib/dev-cycle-read.sh:464-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the phase ordering, append-only reads and each fail rule through the passing tests and mutants; does not give "(the root included)" a code path (the parser never yields the root: `if (index(out, pre) != 1 || length(out) <= length(pre)) return`, `:594`), so that parenthesis is inert rather than wrong.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "'Only appends' means phase 2 never removes a recorded name; it can still fail the whole walk" · r3: "does not establish behaviour for a start under `.git` (git lists none)".

Phase 2 starts only when `queue` empties: `[[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done` (`:833`); checkout reads only add to `IMPORTED_MAIN` (`:866`). The index-only case is covered (`md_ls --cached --others`, `:716`; test line 89, "an index-only start deleted from the checkout loads nothing") (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:713-755,801-876`; `test/scripts/build-loop-check.bats:77-91,782-799`; `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 23: "A linked worktree's .git file and files under .git are checkout files like any other"

**Location:** `scripts/lib/dev-cycle-read.sh:476-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the removed special case and the three tests (lines 411, 657, 700); does not establish that Claude Code reads a gitfile this way (iteration 2's C9: unverifiable here).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: nothing in main_imports special-cases `.git` (paraphrased by r3 because the claim concerns absent code).

main's `if [[ "$p" == .git ]]; then …` block is gone from HEAD's main_imports; `.git` now reaches `main_checkout` like any path main lacks. The gitfile test (`:411`), the under-.git test (`:657`) and the nested .git file test (`:700`) now expect `walk ok` and pass (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:867-874`; `git show main:scripts/lib/dev-cycle-read.sh`; `test/scripts/build-loop-check.bats:411-425,657-664,700-714`

---

## Claim 24: "the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, never the checkout, whose files it read, so a caller whose checkout may have changed (a file added or edited) sets IMPORTED_MAIN_DONE="" to walk again"

**Location:** `scripts/lib/dev-cycle-read.sh:486-491`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the key and the clear; does not establish any caller clearing it (none exists yet).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

`[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` (`:806`). The cache test's last three answers are `- - z.sh`: stale after `CLAUDE.local.md` gains `@z.sh`, fresh after the clear; it passes (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:806-807`, `test/scripts/build-loop-check.bats:330-341`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 25: "Each walk also fails once the parser's work (the candidate and comment-splice characters it scans, the unit of its per-file bound of 50,000,000, about 5 s) passes this in all"

**Location:** `scripts/lib/dev-cycle-read.sh:504-506`
**Type:** Configuration / Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the work counter charges; does not establish the time for shapes other than the many-component one.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r3: "does not establish the 'about 5 s' timing on this host (the iteration-2 fact-check measured 4.04 s at the bound)"; "A precise version: 'the candidate, resolved-path and comment-splice characters it charges'" · r1: the root-length dependence of the unit escalated to performance-reviewer.

The unit omits the largest term: `put` also charges each candidate's resolved spelling, which includes ROOT_REAL (`work += length(c)` after `c = root "/" dir "/" c`, `:581-584`). So the same file costs more work under a longer root: for `see @a.md`, w = 228 at a 50-character root and 252 at 56. "About 5 s" holds for the adversarial many-component shape but not in general: 49,063,020 units of one long name took 62 ms (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-629`; `/tmp/u2a3c-i2-fc1-6NBv/logs/work-vs-rootlen.log`; inline timing (cwd worktree, exit 0, 2026-10-07T20:19Z; quoted: `n=7000 rc=0 trailer=49063020 ms=62`)

---

## Claim 26: "reading, draining and the scan of @-less lines are not charged ... The bound is per walk: a caller that runs both walks pays up to two."

**Location:** `scripts/lib/dev-cycle-read.sh:507-510`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which work is charged and the per-walk counter; does not establish any caller's combined cost.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:** none

`local - f d p lp out used=0 work=0 …` (`:757`) and `local - rec f d p i c lk out used=0 work=0 …` (`:802`) give each walk its own counter; work is charged only in `emit`, `put` and `splice` (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-629,757,802`

---

## Claim 27: "/workspace's walks spend about 8,100 each (2026-10-07)"

**Location:** `scripts/lib/dev-cycle-read.sh:508`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace at main e5d0f838 today; does not establish the figure for other roots (it scales with the root's length: Claim 25).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: timings host-dependent (1.4 s tree, 1.9 s main measured) · r3: "The figure drifts as the checkout changes".

`import_work` wrapped to sum charges: tree walk ok, work 8,110, 1,099 ms, 128 names; main walk ok, work 8,110, 1,352 ms (r1; r2 and r3 also measured 8,110).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/wswork.sh` (cwd /workspace, exit 0, 2026-10-07T20:17:29Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/wswork.log`; `/tmp/u2a3c-i2-fc2-zy90/logs/measure-workspace.txt`; `/tmp/u2a3c-i2-fc3-j0eh/logs/workspace-work.log`

---

## Claim 28: "IMPORT_WORK_LEFT (...) Unset or empty: no trailer and only the per-file bound; not a number: 0, so the first candidate fails it"

**Location:** `scripts/lib/dev-cycle-read.sh:524-528`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers unset, empty, non-numeric, partly numeric, 0 and large values; does not establish behaviour for values the walks never pass (they always pass a non-negative integer).
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: `-5` also gives rc 1; with no `@` in the text, `abc` gives rc 0 and `/0`; "Walks always pass a computed integer, so the residue does not affect them" · r3: `5x` reads as 5; "With no candidate, `abc` succeeds and prints `/0`".

Unset and empty: output `a|ab|ab.|ab.m|ab.md`, no trailer, rc 0. `abc` and `0`: rc 1 at the first candidate. But a value with leading digits is read as those digits, not 0: `12abc` gives wmax 12 and fails at work 17 (`ENVIRON["IT_WORK"] + 0`, `:626`). Precise version: "not a number: its leading number, or 0". On a failing exit awk's END still prints the trailer (`/1`), harmless since the caller fails on the status (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:623-629,670-671`; `/tmp/u2a3c-i2-fc1-6NBv/logs/work-left-values.log`, `/tmp/u2a3c-i2-fc2-zy90/logs/trailer.txt`, `/tmp/u2a3c-i2-fc3-j0eh/logs/iwl-variants.log`

---

## Claim 29: "import_work OUT TOTAL: strips the parser's work trailer (its last line, "/N", printed when IMPORT_WORK_LEFT is set; a repo-relative name never starts with /) from the variable OUT, and adds N to the variable TOTAL. It returns 1 when the trailer is missing or TOTAL passes IMPORT_WORK_MAX."

**Location:** `scripts/lib/dev-cycle-read.sh:673-682`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the strip, the add and both failures; does not establish that a printed name can never start with / beyond `put`'s `out = substr(out, length(pre) + 1)` (`:595`), which removes the root and its slash.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: the no-leading-`/` invariant rests on `put`'s `substr(out, length(pre) + 1)` after a non-empty component.

```bash
# scripts/lib/dev-cycle-read.sh:677-682
import_work() {
  local -n iw_o="$1" iw_t="$2"; local iw_w="${iw_o##*/}"
  [[ "$iw_w" =~ ^[0123456789]+$ && ( "$iw_o" == "/$iw_w" || "$iw_o" == *$'\n'"/$iw_w" ) ]] || return 1
  iw_o="${iw_o%/*}"; iw_o="${iw_o%$'\n'}"
  (( (iw_t += iw_w) <= IMPORT_WORK_MAX ))
}
```

The test at line 842 (cases `a.md\n/12`, `/7`, `docs/12`, `b/12x`, spent budget, `/0`) passes (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:677-682`, `test/scripts/build-loop-check.bats:842-851`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 30: "lower_all ...: a tr that dies after a partial flush then fails the list rather than truncating its last name and dropping a start (U2a3b final N1)"

**Location:** `scripts/lib/dev-cycle-read.sh:696-700`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the failing tr shim; does not establish a tr that exits 0 after truncating (nothing detects that, as for any tool).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`lower_all() { local -; set -o pipefail; printf '%s\0' "$@" | tr … ; }` under `nul_list low lower_all "${cand[@]}" || return 1` (`:820`). The shim test passes at HEAD and fails with 3e58eb9c's lib (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:695,700,820-821`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 31a: capped_read: "the first 4 MiB + 1 bytes of stdin, the one reader both walks parse ... With the word drain (after git cat-file) it reads the rest, so the writer never dies of SIGPIPE ... The drain is time the work bound does not charge"

**Location:** `scripts/lib/dev-cycle-read.sh:701-709`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the byte cap, the call sites and the drain. It does not cover link blobs, which are not parsed and are capped separately (Claim 40).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: confidence Medium on its compound, owing to the /proc half · r2: "It does not test a host without /proc"; "The drained bytes never reach the parser, so nothing charges them".

`head -c 4194305` is 4·1048576 + 1. `capped_read < "$f"` (`:775`, `:837`) and `git cat-file blob ... | capped_read drain` (`:839`). The 4 MiB test passes at HEAD and fails at 3e58eb9c. The no-drain mutant is killed (Claim 9) (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:709`, `scripts/lib/dev-cycle-read.sh:775`, `scripts/lib/dev-cycle-read.sh:837-840`, `/tmp/u2a3c-i2-fc3-j0eh/logs/old-3e58eb9c-reads_only_the_first_4_MiB___1.log`

---

## Claim 31b: "an argument, not a [[ -p /dev/stdin ]] test, which needs /proc"

**Location:** `scripts/lib/dev-cycle-read.sh:706-707`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers this host's `/dev/stdin`. It does not establish bash's behaviour with /proc unmounted.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
**Replicate annotations:** r1: "the /proc dependency is established only as far as `/dev/stdin -> /proc/self/fd/0` on this host (a /proc-less run was blocked: `unshare` not permitted)" · r2: "It does not test a host without /proc" · r3: escalated to security-reviewer as unexecuted; "The change is safe either way, because the argument does not depend on /proc".

`ls -l /dev/stdin` shows `/dev/stdin -> /proc/self/fd/0`. Bash's manual says it uses these files when the OS provides them and emulates them otherwise, so with /proc absent the symlink would dangle (paraphrased — no quote available because the source is the bash manual, not this repo). Execution was blocked: `unshare -rm` fails with `Operation not permitted`, and no strace is installed. Confirming this needs a mount namespace without /proc (Q-127) (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:706-709`

---

## Claim 32: "Claude Code skips a file over 4 MiB"

**Location:** `scripts/lib/dev-cycle-read.sh:702-703`
**Type:** Behavioral
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about Claude Code's runtime. The sentence was moved unchanged from main (`git show main:scripts/lib/dev-cycle-read.sh` line 686).
**Replicate verdicts:** r1=— · r2=— · r3=Unverifiable · single-replicate detection
**Replicate annotations:** none

Verifying it needs Claude Code 2.1.292's reader, which this pass did not probe (r3; paraphrased — no quote available because the claim concerns an external binary).

**Evidence:** `scripts/lib/dev-cycle-read.sh:701-704`

---

## Claim 33: checkout_md: "fails when git exits nonzero or prints anything on stderr, since an unreadable directory goes unlisted with only a warning"

**Location:** `scripts/lib/dev-cycle-read.sh:713-716`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the stderr capture and the corrupt-index and `chmod 000` cases; does not establish every warning git can print.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`checkout_md() { local e; { e="$(md_ls --cached --others 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }`. The `hid` case (`chmod 000`, walk failed, `test/scripts/build-loop-check.bats:794`) and the corrupt-index case (`:242-244`) pass (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:716,818`, `test/scripts/build-loop-check.bats:227-251,782-799`

---

## Claim 34: MEMO "d for a plain searchable directory, 2 for one absent or a plain file (nothing below it loads), set only once its own and every higher ancestor's main mode passed. A MEMO hit skips that mode check too, so a MEMO serves one walk and one ENT."

**Location:** `scripts/lib/dev-cycle-read.sh:720-723`
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the PATH arm's memo write; the invariant does hold for every ancestor entry (`:742` before `:747`) and for main_imports, which never passes a path ENT holds (`:819`, `:870`); does not establish any live fail-open (there is no other caller today).
**Replicate verdicts:** r1=Incorrect · r2=Incorrect · r3=Mostly accurate
**Replicate annotations:** r2: "The mechanism the comment states, 'its own … main mode passed', does not run for PATH. The conclusion holds only under main_imports' unstated precondition (PATH ∉ ENT)"; chose Incorrect over Mostly accurate for that reason; "does not establish a defect for main_imports" · r3 (Mostly accurate): "'Its own ... mode passed' holds for the PATH memo (`:753`) only through the callers' guarantee that ENT lacks PATH"; fuzz with PATH allowed in ENT (`fuzz3.sh`, seed 7, 7,500 calls) found 97 mismatches against 21b35ebf, e.g. `p=c/a old=1 new=2 ENT=([c]="120000" ...)` · r1+r2+r3: escalated (security-reviewer / api-consistency-reviewer / architecture).

The PATH arm writes `d` without testing PATH's own main mode:

```bash
# scripts/lib/dev-cycle-read.sh:749-754
  [[ "$st" == d ]] || return 2
  c="$3"; [[ -e "$c" || -L "$c" ]] || return 2
  if rawfile "$c"; then [[ -r "$c" ]]; return; fi
  plaindir "$c" || return 1
  [[ ! -x "$c" ]] || mc_m[$c]=d  # a prefix candidate's directory, which longer ones pass through
  return 2
```
(excerpt ends :754; enclosing `main_checkout` ends :755 — read)

Executed: ENT `[a]=120000`, checkout `a/b/c.md` a plain file. `main_checkout ENT M a` returns 2 and memoizes `[a]=d`; then `main_checkout ENT M a/b/c.md` hits that entry, never tests `a`'s mode, and returns **0** (walk it), where 21b35ebf's version returns 1. A caller following the U2b contract (fresh MEMO and ENT) but passing a main-stored path would admit a file under a link main stores. Precise version: "set only once every higher ancestor's main mode passed, and for an ancestor its own; PATH itself is memoized without its own mode, so callers pass only paths ENT lacks" (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755,819,870`; `/tmp/u2a3c-i2-fc1-6NBv/e1.sh` (cwd `/tmp/u2a3c-i2-fc1-6NBv/e1/x`, exit 0, 2026-10-07T20:22:38Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/memo-path-in-ent.log` (shows `old(a/b/c.md)=1`, `new(a/b/c.md)=0`, `mn=([a]="d" [a/b]="d")`); `/tmp/u2a3c-i2-fc2-zy90/logs/repro-path-memo.txt`; `/tmp/u2a3c-i2-fc3-j0eh/logs/fuzz3-seed7.log`

---

## Claim 35: "0 for a readable plain checkout file to walk, 2 when nothing there loads (absent, below an absent ancestor or a plain file, or a plain directory), 1 to fail the walk: an ancestor main stores as a link or gitlink, an ancestor that is anything else but a plain searchable directory, an unreadable plain file, ENT or MEMO not an associative array, or anything else at PATH"; "Callers test 1 as a refusal, never as a plain false."

**Location:** `scripts/lib/dev-cycle-read.sh:724-728`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed code through T1's 17-row table, the indexed-array rows and three mutants; does not establish the answer for a PATH ENT holds (Claim 34).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "A MEMO hit skipping the check is exactly what makes Claim 20's precondition matter"; both callers test 1 (`:825-826`, `:870-872`) · r3: does not cover a PATH that ENT holds.

T1 passes; mutants that drop the mode check (`:742`), drop `-r` (`:751`) or break out of the loop below an absent ancestor each fail it (r1).

**Evidence:** `test/scripts/build-loop-check.bats:853-882`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants3.log`

---

## Claim 36: "unlike blocker it answers 2 below a plain file and needs a searchable directory"

**Location:** `scripts/lib/dev-cycle-read.sh:730-731`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the comparison with blocker's ancestor loop. It does not cover blocker's leaf rule.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

blocker prints the first existing non-plain-directory part: `plaindir "$p" || { printf '%s/' "$p"; return 0; }` (`:117-119`). It has no `-x` test, so a plain file ancestor blocks there, while main_checkout sets `st=2` (`:744`) and tests `[[ ! -x "$c" ]]` (`:745`) (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:114-124`, `scripts/lib/dev-cycle-read.sh:743-746`

---

## Claim 37: Iteration-1 fixes A1-A3 and C1 survive the rebase and the new commits

**Location:** `scripts/lib/dev-cycle-read.sh:736,750,825-827,870-872`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the associative-array check (A1), the start's own parent check (A2), admission before seen (A3) and the no-fork fast return (C1); does not re-derive iteration 1's findings.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r3: "does not cover start candidates main stores (`m:`), which skip main_checkout by design".

A1: `set +u; [[ "${mc_e@a}" == *A* && "${mc_m@a}" == *A* ]] || return 1` (`:736`; T1's `ent-indexed 1`, `memo-indexed 1`). A2: start candidates go through `main_checkout ent pok "$f"` (`:825`); the mode-check mutant fails the `.claude/rules` link case (`test/scripts/build-loop-check.bats:788-789`). A3: `main_checkout` (`:870`) precedes `seen[$p]=1` (`:872`), and at starts `:825` precedes `seen[$f]=1` (`:827`). C1: `c="$3"; [[ -e "$c" || -L "$c" ]] || return 2` (`:750`) before `rawfile` forks; ancestors likewise `[[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"` (`:744`) (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:732-755,822-829,867-874`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`

---

## Claim 38: main_checkout (2fbd929b): "Bottom up to the nearest decided ancestor, then top down from it" preserves the top-down version's answers

**Location:** `scripts/lib/dev-cycle-read.sh:737-748`
**Type:** Behavioral / Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every return code of 21b35ebf's top-down main_checkout against HEAD's, for random checkout shapes to depth 3, random ENT modes and random call orders of 8 paths to depth 4 sharing one MEMO, for paths ENT does not hold (main_imports' only use); does not cover paths ENT holds (Claim 34) or unreadable files (identical code on both sides).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: 15,800 in-contract calls over 4 seeds, 0 divergences; "'Every result' excludes a refusal, which is not memoized"; a skip-mode-below-absent mutant fails T1 and T2 · r3: 20,975 calls over seeds 1-4, 0 mismatches; "does not cover a PATH that ENT holds".

1,200 trees, 8,387 calls (rc 0: 245, 1: 3,554, 2: 4,588): zero mismatches, including the asked order (a shorter prefix memoized 2, then a longer path whose deeper ancestor main stores as a link: the memo hit stops the upward scan at the 2 ancestor and the link ancestor below it still meets `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1`, `:742`, which runs whatever `st` is) (r1).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/diff.sh`, `/tmp/u2a3c-i2-fc1-6NBv/diff2.sh` (cwd scratch, exit 0, 2026-10-07T20:10:29Z): `/tmp/u2a3c-i2-fc1-6NBv/diff.out`, `/tmp/u2a3c-i2-fc1-6NBv/diff2.out`; `scripts/lib/dev-cycle-read.sh:732-755`; `/tmp/u2a3c-i2-fc2-zy90/logs/diff-contract-11.txt`; `/tmp/u2a3c-i2-fc3-j0eh/logs/fuzz-seed2.log`

---

## Claim 39: main_imports header: "main_checkout refuses a start or an import main lacks, a blob or checkout file cannot be read ... or the IMPORT_OUT_MAX or IMPORT_WORK_MAX budget is spent ... Phase 2 begins when queue empties: tq's checkout files then join it, and a path main lacks reads the checkout."

**Location:** `scripts/lib/dev-cycle-read.sh:787-800`
**Type:** Error-handling / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers each listed failure's return site; does not establish the order of reads within phase 2 (main-stored imports found in phase 2 still go to `queue` and are read through main's arms, `:873`).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r2: "A phase-2 file's import of a path main stores is read through main's arms in the same loop. The header's 'a path main lacks reads the checkout' implies this, and the block comment says it".

Return sites: `:825-826`, `:837-840`, `:843`, `:846-849`, `:854`, `:859`, `:864`; the checkout arm is `case "${ent[$f]-checkout}" in checkout) …` (`:836-838`) (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:801-876`

---

## Claim 40: "Link text past PATH_MAX (4096) names nothing; it fails before the two whole reads below."

**Location:** `scripts/lib/dev-cycle-read.sh:842`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the size gate's position and the 4097-byte test; does not establish behaviour at exactly 4096 bytes (allowed by `-le`, and also unresolvable since PATH_MAX counts the NUL; failing it there would be stricter, not looser).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "Exactly 4096 bytes passes the check and is read, which is harmless"; 64 MiB link blob fails in 0.02 s · r3: `ln -s` of 4095 bytes succeeded, 4096 and 4097 refused; "The `-le 4096` check therefore admits one length that cannot be a link, which only over-reads"; does not cover other OSes.

`i="$(git cat-file -s "$MAIN_SHA:$f")" && [[ "$i" -le 4096 ]] || { IMPORTED_MAIN=error; return 1; }` (`:843`) precedes both `git cat-file blob` reads (`:846-847`) (r1, as quoted in its Claim 7).

**Evidence:** `scripts/lib/dev-cycle-read.sh:841-859`, `test/scripts/build-loop-check.bats:942-950`, `/tmp/u2a3c-i2-fc3-j0eh/logs/ln-pathmax.log`

---

## Claim 41: The three inverted U2a3b `.git` tests: the gitfile is read "as a checkout file", an imported file under `.git` is read and followed, and a nested `.git` file is read; test titles add "as Claude Code does"

**Location:** `test/scripts/build-loop-check.bats:411`, `test/scripts/build-loop-check.bats:657`, `test/scripts/build-loop-check.bats:700`
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The lib behaviour is verified by execution: all three tests pass at HEAD and walk the gitfile, `.git/notes.md` and `n/.git`. The "as Claude Code does" half needs a trace of the installed Claude Code reader, which this pass did not run. The most severe part carries the verdict.
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable · r3=Verified
**Replicate annotations:** r1: "does not establish that Claude Code reads a gitfile this way (iteration 2's C9: unverifiable here)" · r3: "It does not establish Claude Code's reading of a gitfile (rubric C9, host probe Q-126)".

```
# test/scripts/build-loop-check.bats:657-663 (whole test)
@test "the main walk reads an imported file under .git as a checkout file and follows its imports (U2a3b L2-i2 security F2, U2a3c)" {
    # .git/notes.md is a checkout file main lacks: phase 2 reads it, so docs/t.md, which it imports, counts.
    mkdir -p docs && printf 'See @.git/notes.md and @sub/../.git/info/n.md\n' > CLAUDE.md && commit_all gitdir
    printf 'see @../docs/t.md\n' > .git/notes.md
    imps main docs/t.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/t.md imported; want docs/other.md -
}
```
main's lib held the special case (`if [[ "$p" == .git ]]`, main `:785`), and HEAD's lib has none. To verify the Claude Code half, re-trace the installed Claude Code import reader on a gitfile (Q-126's host probe) (r2).

**Evidence:** `test/scripts/build-loop-check.bats:411-422`, `:657-663`, `:700-714`, `/tmp/u2a3c-i2-fc2-zy90/lib-main.sh:777-785`, `/tmp/u2a3c-i2-fc2-zy90/logs/bats-build-loop-check.txt`

---

## Claim 42: "Unmemoized, each candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized, each directory once, plus each candidate's own check (18)."

**Location:** `test/scripts/build-loop-check.bats:822-825`
**Type:** Performance
**Verdict:** Stale
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the count at HEAD; the 102 and 74 are right for the commits named; does not affect the test's `-le 30` bound, which still passes.
**Replicate verdicts:** r1=Stale · r2=Stale · r3=Stale
**Replicate annotations:** r2: "'Plus each candidate's own check (18)' now reads 10" · r3: "The comment dates from 80cc6224 (unchanged since then)"; escalated as test-text drift.

At 80cc6224 the count was 18; at HEAD (2fbd929b's lib) it is **10**, because 2fbd929b also memoizes a searchable PATH directory (`:753`), so a candidate's own check is no longer repeated by longer ones. Precise version: "(10 at 2fbd929b; 18 at 80cc6224)" (r1).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/rpcount.sh` (cwd scratch, exit 0, 2026-10-07T20:15Z): `/tmp/u2a3c-i2-fc1-6NBv/logs/rpcount.log`; `/tmp/u2a3c-i2-fc2-zy90/logs/rpcount.txt`; `/tmp/u2a3c-i2-fc3-j0eh/logs/realpath-counts.log`

---

## Claim 43: Test title "main_checkout answers each checkout shape: … and memoizes only plain searchable directories (U2a3c)"

**Location:** `test/scripts/build-loop-check.bats:853`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the test asserts about MEMO; does not establish the 2 entries' contents.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: the MEMO holds 2-valued entries such as `nd` and `f.md`; the return-code table is verified · r3: T1 kills the nomode, nox, pathmemo-any, unreadable and skip-mode-below-2 mutants; escalated as test-text drift.

MEMO also holds `2` entries (every decided ancestor, `mc_m[$c]="$st"`, `scripts/lib/dev-cycle-read.sh:747`); the test filters to `d` values: `for k in "${!M[@]}"; do [[ "${M[$k]}" != d ]] || echo "$k"; done` (`test/scripts/build-loop-check.bats:860`). Precise version: "memoizes as d only plain searchable directories" (r1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:747,753`, `test/scripts/build-loop-check.bats:853-882`

---

## Claim 44: Test "main walk fails on a path under a link main stores below a directory the checkout lacks, and walks a path under a plain file (U2a3c)"

**Location:** `test/scripts/build-loop-check.bats:884-895`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers its two halves and the mode-check mutant; does not establish that it alone pins the HEAD analog of M13 (a break below an absent ancestor survives it, because the walk's shorter prefixes memoize `a` and `a/b` first, so the link ancestor is the first undecided one; T1 kills that mutant).
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: T2 kills the nomode and skip-mode-below-2 mutants.

Passes at HEAD; the no-mode-check mutant fails it (r1).

**Evidence:** `test/scripts/build-loop-check.bats:884-895`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants3.log`

---

## Claim 45: Test "each walk caps every file's parser at what IMPORT_WORK_MAX has left, in every arm, and charges every arm"; "Four top-level files alike but for one letter cost w each: two on main, two only in the checkout, so each main_imports arm runs twice"

**Location:** `test/scripts/build-loop-check.bats:897-912`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test checks (the -1/0 boundary relative to 4w, and the four caps) and that a per-file mutant fails it; does not establish robustness to the fixture root's length, which it lacks (Claim 1).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

Two files on main (`AGENTS.md`, `GEMINI.md`, blob arm) and two in the checkout (`CLAUDE.md`, `CLAUDE.local.md`, checkout arm); the shim logs `IT_WORK`. A mutant with no walk-wide check (import_work's comparison and awk's cap both removed) fails it (r1).

**Evidence:** `test/scripts/build-loop-check.bats:897-912`; `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`

---

## Claim 46: Test "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)"

**Location:** `test/scripts/build-loop-check.bats:921-930`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the record and the start's checkout read, and the symlink refusal at the start; does not establish "once" by a read count.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** r3: "For T5's 'once', the read count holds statically (`seen`) but is not asserted".

Passes; `docs/x.md imported` is reachable only by reading the checkout's `docs/AGENTS.md` (main stores no such file) (r1).

**Evidence:** `test/scripts/build-loop-check.bats:921-930`, `/tmp/u2a3c-i2-fc1-6NBv/logs/build-loop-check.log`

---

## Claim 47: Deep-token test: "@a/a/.../x.md, 1,000 levels deep, none in the checkout: about 0.6 s; 21b35ebf's top-down loop rescanned every absent ancestor per prefix candidate (10.7 s)"; title "stays linear"

**Location:** `test/scripts/build-loop-check.bats:932-940`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the two timings on this host and the test catching 21b35ebf. It does not establish linearity (one depth only), or the test's discrimination on a host more than about 1.8× faster, where 21b35ebf would finish under `timeout 6`.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish behaviour on a host about 9x slower, where 0.67 s would pass 6 s (the test does not separate a timeout from a failure)" · r2: pass side about 9x headroom, kill side 1.8x; "on a host about twice as fast the 21b35ebf regression would finish inside the timeout and survive (escalated to test-strategy)".

Timings (r3): main 511/502 ms, 21b35ebf 10461/10864 ms and 3a35c8b9 658/652 ms. The margin at HEAD is about 9× below the 6 s timeout. The mutant that stops at a `2` ancestor without mode-checking deeper ones also times out here, and it is killed by T1 and T2 as well.

**Evidence:** `test/scripts/build-loop-check.bats:932-940`, `/tmp/u2a3c-i2-fc3-j0eh/logs/deep-timing.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/mutant-memo-skip-mode-below-2.log`

---

## Claim 48: Test title "main walk fails on link text main stores longer than 4096 bytes before reading it whole"

**Location:** `test/scripts/build-loop-check.bats:942`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the test observes; does not establish the "before reading it whole" ordering, which no assertion observes.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate
**Replicate annotations:** r2: "A reader trusting the title would think the read cost is pinned"; a `git` shim counting `cat-file blob` calls would pin the ordering · r3: "The ordering holds statically".

The test checks only `walk: failed` for 4,097 bytes and `walk: ok` for `r.md` (`:949`). It discriminates the cap (21b35ebf's lib, which reads the text, walks ok and fails the test), but a mutant that read the blob whole first and then failed on its size would pass. Precise version: "fails on link text … longer than 4096 bytes" (r1).

**Evidence:** `test/scripts/build-loop-check.bats:942-950`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 49: dev-cycle.bats function inventory gains md_ls, checkout_md, main_checkout, lower_all, capped_read, import_work

**Location:** `test/scripts/dev-cycle.bats:1110`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the existence of each listed function. It does not establish inventory completeness for other files.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

Each is defined (`scripts/lib/dev-cycle-read.sh:677`, `:693`, `:700`, `:709`, `:716`, `:732`), and dev-cycle passes 78/78 (r3).

**Evidence:** `test/scripts/dev-cycle.bats:1106-1113`, `/tmp/u2a3c-i2-fc3-j0eh/logs/dev-cycle.log`

---

## Claim 50a: Commit 3e58eb9c: "Tests: build-loop-check 51/51, build-loop-read 19/19, dev-cycle 78/78, fixture-git-env 2/2"; "its pok memo, which returns in the memo commit that follows"

**Location:** commit 3e58eb9c message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four suite results at 3e58eb9c. It does not cover suites the message does not name.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1: "does not re-run 3e58eb9c's dev-cycle or build-loop-read suites (counts only)"; 3e58eb9c's main_imports calls `main_checkout ent "$f"` (no MEMO); 80cc6224 adds `pok`.

bats over `git archive 3e58eb9c`, cwd `/tmp/u2a3c-i2-fc3-j0eh/repo-3e58`, every run exit 0: build-loop-check ok=51, build-loop-read ok=19, fixture-git-env ok=2, dev-cycle ok=78 (r3).

**Evidence:** `/tmp/u2a3c-i2-fc3-j0eh/logs/at3e58-build-loop-check.log`, `/tmp/u2a3c-i2-fc3-j0eh/logs/at3e58-dev-cycle.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/blc-3e58eb9c.log`

---

## Claim 50b: Commit 3e58eb9c: "Three U2a3b tests that pinned the interim fail-closed rule for .git paths now expect the walk to read them"; "the .git directory passes main_checkout as a plain directory, and a linked worktree's gitfile is read as a checkout file"

**Location:** commit 3e58eb9c message
**Type:** Behavioral / Reference
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** executed
**Scope:** The lib behaviour is verified by execution: all three tests pass at HEAD and walk the gitfile, `.git/notes.md` and `n/.git`. The "as Claude Code does" half needs a trace of the installed Claude Code reader, which this pass did not run. The most severe part carries the verdict.
**Replicate verdicts:** r1=Verified (compound) · r2=Unverifiable (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r3: the three tests are inverted and pass · r3: Claude Code's gitfile reading is for host probe Q-126.

r2 verdicted this together with the three test titles (Claim 41): the lib half is verified; "as Claude Code does" for gitfiles needs a trace of the installed Claude Code reader (Q-126). paraphrased — no quote available because the evidence is the same as Claim 41's, quoted there.

**Evidence:** `test/scripts/build-loop-check.bats:411-422`, `:657-663`, `:700-714`, `/tmp/u2a3c-i2-fc2-zy90/logs/bats-build-loop-check.txt`

---

## Claim 51: Commit 3e58eb9c: "squash-rebase chosen over a per-commit rebase (same final tree, review reports carried in the next commit)"; "a commit-by-commit rebase conflicted twice in the same hunks"

**Location:** commit 3e58eb9c message
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** Low
**Verification mode:** static
**Scope:** Covers nothing about the claimed equivalence; the reports-carried half is true (cb9723c3 adds them).
**Replicate verdicts:** r1=Unverifiable · r2=Unverifiable · r3=Unverifiable
**Replicate annotations:** r2: the message's other resolution claims are verified ("U2a3b already records the whole output before the loop" is `:866`; main's lib `:793-794` holds the `pok` loop HEAD replaces) · r3: verifying needs a per-commit rebase of `backup/u2a3c-pre-rebase-2b1399ab` onto 581d41d8.

The per-commit rebase it compares against was abandoned on conflicts, so no tree exists to compare. Would need: replaying cebfed35..2b1399ab onto 581d41d8 with the same resolutions and diffing trees (r1).

**Evidence:** paraphrased — no quote available because the claim concerns a rebase result that was never committed; `scripts/lib/dev-cycle-read.sh:866`

---

## Claim 52: Commit cb9723c3: "override-log.md: U2a3b's rows and U2a3c's 9 rows both kept (append-only)"; commit 21b35ebf closes four rows (N1, L2-C5, L2-C6, P2)

**Location:** commit cb9723c3 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the row counts. Rows 439-447 are history and are not re-verdicted here.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** none

The diff appends nine U2a3c rows dated 2026-10-06 (`docs/reviews/override-log.md:439-447`), four closing rows (`:448-451`) and five iteration-2 rows (`:452-456`). It deletes no rows (paraphrased — no quote available because the claim concerns the diff's shape: `git diff main...HEAD -- docs/reviews/override-log.md` shows only `+` lines) (r3).

**Evidence:** `docs/reviews/override-log.md:439-456`

---

## Claim 53: Commit 27364085: "Tests: both new tests fail on 3e58eb9c's lib; a mutant without the drain fails the 4 MiB test (walk failed)"; "imported_names reads through it too"

**Location:** commit 27364085 message
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both tests on 3e58eb9c's lib and the no-drain mutant (built on HEAD's explicit drain, equivalent at that site); does not cover 27364085's `-p` drain on a /proc-less host.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r3: "does not cover the message's 'from a pipe it drains', which described 27364085's `-p` test and was superseded in 2fbd929b"; `capped_read < "$f"` appears in imported_names (`:775`).

N1 test and 4 MiB test: not ok on 3e58eb9c's lib, ok on 27364085's; no-drain mutant: `walk: failed` (r1).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants2.log`, `scripts/lib/dev-cycle-read.sh:775`

---

## Claim 54: Commit 80cc6224: "A test's realpath count: 18, against 102 unmemoized and 74 at 3e58eb9c"; "an empty main tree with an untracked start killed the caller's shell (test added; it fails at 27364085)"

**Location:** commit 80cc6224 message
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and the crash at the commits named; does not establish the counts at HEAD (10: Claim 42).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1+r2+r3: HEAD's count is 10.

Realpath shim over the test's scenario: 3e58eb9c 74, 80cc6224 18, 80cc6224 with its memo store removed 102. Empty-tree test: 27364085 fails with `line 699: mc_e: unbound variable`, 80cc6224 passes (r1, its Claim 4).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/rpcount.log`, `/tmp/u2a3c-i2-fc1-6NBv/logs/mutants1.log`

---

## Claim 55a: Commit 61e2e734: "/workspace's walks spend about 8,100 each (1.1 s tree, 1.4 s main; the main walk now passes on this developer checkout, which failed closed before U2a3c)"; "a per-file mutant passes at 3w - 1 and fails the test"; "about 6,000x this repo's real work"; "Without IMPORT_WORK_LEFT the parser's output is unchanged"

**Location:** commit 61e2e734 message
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each figure on this host today and the mutant against 61e2e734's own test; does not establish the timings elsewhere.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: timings measured 1.4 s tree and 1.9 s main; host-dependent · r3: ran the mutant against HEAD's 4w test, not 61e2e734's test file.

8,110 work each, 1,099 ms and 1,352 ms; main's lib fails the main walk on /workspace (`main-lib: failed`). 50,000,000 / 8,110 = 6,165. The per-file mutant on 61e2e734's lib with 61e2e734's test prints `-1 tree ok`, `-1 main ok` and fails; the unmutated lib passes. Unset IMPORT_WORK_LEFT prints no trailer (r1).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/wswork.log`; mutant run (cwd `/tmp/u2a3c-i2-fc1-6NBv/rt61`, 2026-10-07T20:19Z); `/tmp/u2a3c-i2-fc1-6NBv/logs/work-left-values.log`

---

## Claim 55b: Commit 61e2e734 Notes: "the limit equals the old per-file bound, so the whole walk costs at most what one file could"

**Location:** commit 61e2e734 message
**Type:** Performance
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers charged parser work. It does not cover uncharged work.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none

This holds for charged parser work. Reading, draining and the @-less scan are uncharged, as the lib comment states: "reading, draining and the scan of @-less lines are not charged" (`scripts/lib/dev-cycle-read.sh:507-508`). Override row 455 already narrows this (r3).

**Evidence:** `scripts/lib/dev-cycle-read.sh:504-511`, `docs/reviews/override-log.md:455`

---

## Claim 56a: Commit 2fbd929b: "main_checkout walks its ancestors bottom up to the nearest decided one and memoizes every result (d or 2), and a searchable directory at PATH"; "D=1000 took 10.7 s at 21b35ebf, 0.6 s now, main 0.5 s"; "capped_read drains only when told (drain), not on [[ -p /dev/stdin ]]"; "shellcheck SC2034 on pok (passed by name) failed the health check"; "T3 replaces the work-bound test it extends"

**Location:** commit 2fbd929b message
**Type:** Performance / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the timings, the drain change (27364085-21b35ebf used `[[ ! -p /dev/stdin ]] || cat > /dev/null`), SC2034 without the directive, and the replaced test; does not re-run the repo health check.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "'Every result' excludes a refusal, which is not memoized"; shellcheck on 61e2e734's lib reports SC2034 `pok appears unused` and nothing else · r3: the inventory diff adds only `import_work`; the `:69` comment is fixed; "does not establish the shellcheck failure at 61e2e734, which I did not re-run".

Timings: 21b35ebf 10,855/11,750 ms, 2fbd929b 669/670 ms, main 532 ms. `shellcheck -S warning` is clean at HEAD and reports `SC2034 (warning): pok appears unused` with the directive removed. No test titled "bounds the parser" remains (r1).

**Evidence:** `/tmp/u2a3c-i2-fc1-6NBv/logs/deep.log`; `shellcheck -S warning scripts/lib/dev-cycle-read.sh` (cwd worktree, exit 0) and on `/tmp/u2a3c-i2-fc1-6NBv/nosc.sh` (exit 0, SC2034 printed), 2026-10-07T20:20Z; `scripts/lib/dev-cycle-read.sh:739-754`

---

## Claim 56b: Commit 2fbd929b: "Tests: … 63/78/19/2."

**Location:** commit 2fbd929b message
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and their pass status; does not establish that they pass on a host whose bats root is 56+ characters.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: `grep -c '^@test'` gives 63/19/78 at 2fbd929b and HEAD runs are 63/78/19/2 · r3: counts confirmed by running the suites.

Counts are exact; build-loop-check passes only while the fixture root is under 56 characters (Claim 1). Precise version: add "with a TMPDIR under 27 characters" or fix the test's constant (r1).

**Evidence:** `test/scripts/build-loop-check.bats:897-912`, `/tmp/u2a3c-i2-fc1-6NBv/logs/caps-tmpdir-length.log`

---

## Claims Requiring Attention

### Incorrect
- **Claim 34** (`scripts/lib/dev-cycle-read.sh:720-723`): the PATH arm memoizes `d` without PATH's own main mode (`:753`); a caller passing a path ENT holds as a link then gets 0 below it (executed: 21b35ebf 1, HEAD 0). Unreachable from main_imports; tighten the comment and the U2b contract, or test the mode before memoizing. (r1=Incorrect, r2=Incorrect, r3=Mostly accurate.)

### Stale
- **Claim 9** (`docs/reviews/override-log.md:449`): the row says capped_read "drains a pipe"; since 2fbd929b it drains only when the blob arm passes `drain`. No row amends it.
- **Claim 42** (`test/scripts/build-loop-check.bats:822-825`): the memoized realpath count is 10 at HEAD, not 18.

### Mostly Accurate
- **Claim 1** (rubric:21): build-loop-check is 62/63 when the bats root is 56+ characters; test 59's fixed `IMPORT_WORK_MAX=1000` fails as `w` grows with ROOT_REAL.
- **Claim 13** (`docs/reviews/override-log.md:453`): no test has the quoted name; cite the line-921 title.
- **Claim 16a** (`docs/reviews/override-log.md:456`): each call site is one statement over two lines.
- **Claim 17a** (`docs/working/known-issues-dev-cycle.md:18`): fail rules match; r1's compound verdict rests on the pointer (17b).
- **Claim 17b** (`docs/working/known-issues-dev-cycle.md:18`): the lib's block comment holds the cache and HOME rules, not the git-environment or `LC_ALL` duties.
- **Claim 18** (`docs/working/plan-build-loop-handoff.md:126`): F11's admission list omits the unreadable-plain-file refusal.
- **Claim 20a** (`docs/working/plan-build-loop-handoff.md:279`): three duties match; r3's compound verdict rests on the MEMO rule (20b).
- **Claim 20b** (`docs/working/plan-build-loop-handoff.md:279`): another main_checkout caller must also pass only paths ENT lacks.
- **Claim 25** (`scripts/lib/dev-cycle-read.sh:504-506`): the work unit also includes each resolved spelling (root length included); "about 5 s" holds for the many-component shape only.
- **Claim 28** (`scripts/lib/dev-cycle-read.sh:524-528`): a value with leading digits is read as that number, not 0.
- **Claim 43** (`test/scripts/build-loop-check.bats:853`): MEMO holds 2 entries too; the test checks only the d ones.
- **Claim 48** (`test/scripts/build-loop-check.bats:942`): the test cannot observe "before reading it whole".
- **Claim 55b** (commit 61e2e734): "at most what one file could" holds for charged work only.
- **Claim 56b** (commit 2fbd929b): 63/63 depends on TMPDIR length.

### Unverifiable
- **Claim 6** (rubric:48, C9): the Claude Code half of the gitfile claim needs the installed reader traced.
- **Claim 31b** (`scripts/lib/dev-cycle-read.sh:706-707`): `[[ -p /dev/stdin ]]` needing /proc needs a mount namespace without /proc (Q-127).
- **Claim 32** (`scripts/lib/dev-cycle-read.sh:702-703`): "Claude Code skips a file over 4 MiB" needs Claude Code probed.
- **Claim 41** (`test/scripts/build-loop-check.bats:411,657,700`): "as Claude Code does" for gitfiles needs Q-126's host probe.
- **Claim 50b** (commit 3e58eb9c): same Claude Code half as Claim 41.
- **Claim 51** (commit 3e58eb9c): "same final tree" compares with a rebase that was never completed.

## Escalations

- **`scripts/lib/dev-cycle-read.sh:753`** (also `:719-723`, plan `docs/working/plan-build-loop-handoff.md:279`) — raised by r1, r2, r3 — addressee: **security-reviewer / api-consistency-reviewer** (r1, r2), **architecture-review / api-consistency-reviewer** (r3). main_checkout memoizes PATH as `d` without checking `ENT[PATH]`; a caller passing a path main stores as a link or gitlink, with a plain directory in the checkout, makes later calls below it skip the link refusal (r1/r2 repro: 0 where 21b35ebf gives 1; r3 repro: 2 where 21b35ebf gives 1). main_imports is safe (both call sites guard on `ent`, `:819`/`:825`, `:870`). The U2b contract and the comment do not state the precondition; fix by stating it, or by making `:753` conditional on `[[ -z "${mc_e[$3]+set}" ]]` (r2) / returning 1 when `mc_e[$3]` is a link or gitlink (r3).
- **`test/scripts/build-loop-check.bats:897-912`** (test 59) — raised by r1 — addressee: **test-strategy**. Fixed `IMPORT_WORK_MAX=1000` against `4w` passes 1000 at a 56-character fixture root; fails in the full file with a 27-character TMPDIR (alone at 97), silently. Derive the cap from `w` (e.g. `10 * w`).
- **`test/scripts/build-loop-check.bats:932-940`** (deep-token `timeout 6`) — raised by r2, r3 — addressee: **test-strategy**. Kill-side margin is about 1.8x (21b35ebf 10.5-11.0 s); on a host about twice as fast the O(D³) regression would pass. Suggested: a relative bound, larger D (r2), or a host-independent call-count shim (r3).
- **`test/scripts/build-loop-check.bats:942-950`** (link-text test ordering) — raised by r1, r2, r3 — addressee: **test-strategy**. The test pins the outcome, not "before reading it whole"; a read-then-reject mutant survives. A `git` shim counting `cat-file blob` calls would pin the ordering (r2).
- **`test/scripts/build-loop-check.bats:884-895`** (T2 vs HEAD's M13 analog) — raised by r1 — addressee: **test-strategy**. T2 does not pin a break below an absent ancestor because the walk's prefixes memoize the absent ancestors first; only T1 kills it.
- **`scripts/lib/dev-cycle-read.sh:753`** (no test pins main_checkout's PATH ∉ ENT precondition) — raised by r2 — addressee: **test-strategy**.
- **`test/scripts/build-loop-check.bats:822-825`, `:853`** (test-text drift: the `(18)` comment, T1's "memoizes only" title) — raised by r3 — addressee: **test-strategy**.
- **`scripts/lib/dev-cycle-read.sh:504-506`, `:581-584`** (work unit is root-length dependent) — raised by r1 — addressee: **performance-reviewer**. Each candidate is charged its resolved spelling including ROOT_REAL, so the fixed IMPORT_WORK_MAX buys less real work under a long checkout path; 8,110 at /workspace would be about 4x at a 100-character root. Not a defect at 6,000x headroom, but the comment's unit omits it.
- **`scripts/lib/dev-cycle-read.sh:706-707`** (`/proc` rationale for `capped_read drain` unexecuted; Q-127) — raised by r3 (r1 records the same blocked `unshare` in its Claim 20 scope) — addressee: **security-reviewer**. The change is safe either way, because the argument does not depend on /proc.
- **`test/scripts/build-loop-check.bats:411,657,700`** (Claude Code's gitfile reading; Q-126 host probe) — raised by r2 (Goal-Alignment out-of-scope item and Claim 28 prose; r3 cites the same probe in its Claim 35 scope) — addressee: **orchestrator**.

## Verdict stability

- **Total clusters:** 64 (sub-claim rows counted separately).
- **Single-replicate clusters:** 12 (Claims 3, 6, 7, 21, 30, 32, 33, 36, 45, 49, 52, 55b).
- **Agreed (all reporting replicates gave the same verdict):** 50 of 64 (including the 12 single-replicate clusters); 38 of the 52 clusters with two or more reporting replicates.
- **Disagreed:** 14:
  - Claim 1: r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
  - Claim 9: r1=Verified (compound) · r2=Verified (compound) · r3=Stale
  - Claim 13: r1=Mostly accurate · r2=Mostly accurate · r3=Verified
  - Claim 16a: r1=Mostly accurate · r2=Verified (compound) · r3=—
  - Claim 17a: r1=Mostly accurate (compound) · r2=Verified · r3=Verified
  - Claim 17b: r1=Mostly accurate (compound) · r2=Verified (compound) · r3=Mostly accurate
  - Claim 18: r1=Mostly accurate · r2=Mostly accurate · r3=Verified
  - Claim 20a: r1=— · r2=Verified · r3=Mostly accurate (compound)
  - Claim 25: r1=Mostly accurate · r2=Verified (compound) · r3=Mostly accurate
  - Claim 31b: r1=Verified (compound) · r2=Verified (compound) · r3=Unverifiable
  - Claim 34: r1=Incorrect · r2=Incorrect · r3=Mostly accurate
  - Claim 41: r1=Verified (compound) · r2=Unverifiable · r3=Verified
  - Claim 50b: r1=Verified (compound) · r2=Unverifiable (compound) · r3=Verified (compound)
  - Claim 56b: r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
- **Agreement rate:** 78.1% (50/64) over all clusters; 73.1% (38/52) over clusters with two or more reporting replicates. Below the ≥90% on ≥20 claims falsifier, so k stays at 3. Two of the 14 disagreements (17a, 20a) arise only from a compound verdict being recorded on a sibling sub-claim per step 1, where the compound replicate's own prose attributes its severity to the other sub-claim.
