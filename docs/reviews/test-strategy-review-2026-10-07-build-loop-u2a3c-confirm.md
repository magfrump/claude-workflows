Commit: 380ed01b

# Test Strategy: feat/build-loop-u2a3c, final confirming pass (after Q-128 [1])

**Scope:** the lib lines 4b7f2357 changed (`git diff 3a35c8b9 4b7f2357 -- scripts`: main_checkout's `${x[0]@a}` type check at scripts/lib/dev-cycle-read.sh:741 and its PATH link/gitlink guard at :743), a re-check of the previous pass's survivors, and the timing behaviour of the suite's timed tests. Tests are in `test/scripts/build-loop-check.bats`.
**Reviewed:** 2026-10-07

Execution provenance: scratch dir `/tmp/u2a3c-i4-ts-iXzF`. `repo/` is `git archive 380ed01b`. `p/` is HEAD's lib with the patched test file (Appendix A). `old/` is the same test file with 3a35c8b9's lib. The mutants are in `m/<name>/`, defined in `tools/mutants.py` and run by `tools/runmut.sh`; results are in `res/`. TMPDIRs: `/tmp/u2a3c-i4-ts-s-RGm9` (23 characters) and `/tmp/u2a3c-i4-ts-long-tmpdir-component-padding-for-root-length-sensitivity-9iw9` (79 characters), with `LC_ALL=C`. Load probes used 24 or 48 `while :; do :; done` loops on 16 CPUs, each under `timeout` and killed by PID. The worktree was not modified, apart from writing this report.

## Test Conventions

The project uses bats ≥ 1.5. Each test builds a throwaway repo through `bl_setup` (test/lib/build-loop-fixtures.bash). Lib functions are run in a child shell: `run --separate-stderr env LC_ALL=C bash -c '…' _ "$LIB"`. Walks are run through `imps`/`want`, and a unit test of main_checkout echoes `PATH CODE` lines and compares them with a literal. Cost guards are either counted (a realpath shim at :829, xtrace at :958) or timed (`timeout N`: :577, :595, :642, :939, :988).

## Baseline

HEAD passes 66/66 under both TMPDIRs. The patched file (68 tests) passes 68/68 under both.

## Mutation results

19 mutants. Each was run against the full patched suite under both TMPDIRs, with 8 suites in parallel, and both TMPDIRs gave identical results. Test numbers are the patched file's: 1-66 are as at HEAD, 67 is the new ratio test, and 68 is the new blob-PATH test. Test 65 is HEAD's PATH-guard test with the two rows added in Appendix A.

| Mutant | Change | Killed by HEAD tests (1-66) | Killed by new/patched tests |
|---|---|---|---|
| N01 typecheck-whole-both | `${mc_e@a}`, `${mc_m@a}` (3a35c8b9) | 66 (timed only) | 67 |
| N02 typecheck-whole-memo | `${mc_m@a}` only | 66 (timed only) | 67 |
| N03 typecheck-whole-ent | `${mc_e@a}` only | **survives** | 67 |
| N04 no-memo-typecheck | drop MEMO's check | 57 | |
| N05 no-ent-typecheck | drop ENT's check | 57 | |
| N06 guard-removed | drop :743 | 65 | |
| N07 guard-link-only | `^120000$` | 65 | |
| N08 guard-gitlink-only | `^160000$` | 65 | |
| N09 guard-broad | `[[ -z "${mc_e[$3]+set}" ]] \|\| return 1` | **survives** | 68 |
| N10 guard-returns-2 | `return 2` at the guard | 65 | |
| N11 guard-after-exists | guard moved below `[[ -e \|\| -L ]] \|\| return 2` | **survives** | 65 patched (lx, gx rows) |
| N12 no-set-plus-u | drop `set +u` | 48 tests | |
| N13 guard-any-nonblob | refuse every mode but 100644 at PATH | **survives** | 68 (the 100755 row) |
| A01 memo-hit-ignores-value | re-check | survives | equivalent (unchanged argument, previous pass) |
| A08 no-path-memo | re-check | 54 | |
| A11 link-cap-after-reads | re-check | 63 | |
| A13 drain-always | re-check | survives | equivalent (time only) |
| A14 checkout-arm-drains | re-check | survives | equivalent (time only) |
| A16 cat-file-s-failure-ignored | re-check | survives | equivalent (fails closed one line later) |

Old lib: test 67 fails at 3a35c8b9, with a ratio ×100 of 16461 against a bound of 1000. Test 68 passes there, since it pins behaviour that is unchanged.

After the patch, every non-equivalent mutant is killed under both TMPDIRs, and N01-N03 are killed host-independently. The four remaining survivors (A01, A13, A14, A16) carry the equivalence arguments of the previous pass, and the lines they touch have not changed since.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:741 — the O(1) type check on ENT (`${mc_e[0]@a}`): a check linear in ENT's size (N03) passes the whole HEAD suite. Test 66's fixture has a small main tree, so only MEMO grows there. The gap is not covered.
- **G2** — scripts/lib/dev-cycle-read.sh:741 — the O(1) type check on MEMO: only test 66's `timeout 20` covers it, and that test is host-dependent (see F2). Partly covered: there is no host-independent arm.
- **G3** — scripts/lib/dev-cycle-read.sh:743 — the guard's scope at a PATH main stores as a blob: neither the documented answer (by the checkout's shape; the U2b bullet allows "a PATH main … stores as a blob") nor its 100755 arm is pinned. N09 and N13 survive. The gap is not covered.
- **G4** — scripts/lib/dev-cycle-read.sh:743 — the guard's position before the existence test: a link or gitlink PATH that main stores but the checkout lacks answers 1 at HEAD, and 2 under N11. The comment at :724 says "main's link or gitlink at PATH answers 1". The gap is not covered.

## Findings

### F1 — The `${x@a}` cost class on ENT is unguarded, and on MEMO it is guarded only by a timing
- **Severity:** Medium
- **Location:** scripts/lib/dev-cycle-read.sh:741; test/scripts/build-loop-check.bats:982-988 (test 66)
- **Evidence:** N03 (`${mc_e@a}`) passes 66/66 under both TMPDIRs. N01 and N02 are killed only by test 66's `timeout 20`. The xtrace test (64) cannot see the cost of an expansion, so it passes on all three, which confirms the Stage-1 escalation. Timed in a single process, main_checkout's cost per call with ENT and MEMO at 30,000 entries, against both empty, is 0.41-1.08× at HEAD (idle and under 24 spinners, best of 3) and 59× (N02), 102× (N03) and 141× (N01, the 3a35c8b9 code) on the mutants.
- **Confidence:** High (executed).
- **Legibility-target:** test author. Appendix A test 67 closes it: a ratio of two timings taken in the same shell, so host speed cancels out, with a bound of 10× against a gap of 59-141×. It passes on HEAD under both TMPDIRs and fails on N01, N02, N03 and 3a35c8b9's lib.

### F2 — Test 66 has about 2-3× headroom under load, and its D1 kill needs a host no more than about 2× faster
- **Severity:** Low
- **Location:** test/scripts/build-loop-check.bats:982-988
- **Evidence:** Test 66's body (main_imports over 4,000 tokens) takes 2.41-2.58 s idle, 6.48-6.69 s under 24 spinners on 16 CPUs, and 9.36-9.38 s under 48. The timeout is 20 s, so a host about 2× slower under the same load, or a busy CI runner, goes red with no bug. In the other direction, 3a35c8b9's 44.6 s means a host about 2.2× faster no longer catches D1. The other timed tests have more headroom. Under 24 spinners, the whole tests took 0.7-2.6 s (bats `-T`, fixture setup included), against timeouts of 6-20 s. Test 5 (deep token, `timeout 6`) took 0.94 s idle and 2.6 s loaded, the tightest after 66.
- **Confidence:** Medium. The load model is synthetic, and real CI may differ.
- **Legibility-target:** test author. Once test 67 lands, D1's kill no longer depends on test 66. The optional patch is to raise 66's timeout to 60, the suite's hang-guard value (Appendix B), and to say in its comment that 67 is the D1 pin. With that patch, 66 stops killing N01/N02, and 67 still kills them. If the author keeps 20 s, nothing breaks today. This is a flake risk, not a defect.

### F3 — The blob-PATH answer is unpinned (N09, N13 survive)
- **Severity:** Low
- **Location:** scripts/lib/dev-cycle-read.sh:743; docs/working/plan-build-loop-handoff.md:279 (U2b: "a PATH main lacks or stores as a blob")
- **Evidence:** A guard that refuses every PATH main stores (N09, the "broad" guard the fact-check named) passes 66/66, as does one that refuses 100755 (N13). The contract allows a blob PATH, and with a clean worktree at MAIN_SHA, the checkout holds a plain file there.
- **Confidence:** High (executed).
- **Legibility-target:** test author. Appendix A test 68 pins the documented answer: 0 for a readable plain file at a 100644 and at a 100755 PATH. It passes on HEAD and fails on N09 and N13. I deliberately do **not** pin the directory-at-blob-PATH case: main_checkout memoizes it as d, which is safe only under U2b's clean-worktree duty. Whether to keep that or refuse it is the security/API escalation from Stage 1, and a test would bless one answer before that decision is made.

### F4 — The guard's "answers 1" is unpinned for a link/gitlink PATH absent from the checkout (N11 survives)
- **Severity:** Low
- **Location:** scripts/lib/dev-cycle-read.sh:724 (comment), :743; test/scripts/build-loop-check.bats:973-980 (test 65)
- **Evidence:** If the guard moves below the existence test (N11), a link or gitlink PATH that main stores and the checkout lacks answers 2 rather than 1. HEAD's test 65 passes, because all of its PATHs exist. main_imports never makes this call, so the difference is invisible to the walk. For a second caller it is a refusal turned into a "nothing loads", which contradicts the comment.
- **Confidence:** High (executed).
- **Legibility-target:** test author. The Appendix A patch to test 65 adds the rows `lx` and `gx` (in ENT, absent from the checkout, both expected 1). It passes on HEAD under both TMPDIRs and fails on N11, N06 and N10.

## Recommended Tests

#### Ratio guard on main_checkout's cost per call (test 67)
**Closes gaps:** G1, G2 · **Type:** unit (cost property) · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**What it verifies:** the cost per call does not depend on ENT's or MEMO's size.
**Key cases:** both arrays at 30,000 entries against both empty, 400 calls each, best of 3 rounds, with a ratio ≤ 10.
**Setup needed:** none beyond `$LIB`. Uses `EPOCHREALTIME` (bash ≥ 5.0).

#### Blob PATH answers by the checkout's plain file (test 68)
**Closes gaps:** G3 · **Type:** unit (contract) · **Priority:** medium · **File:** same.

#### Absent link/gitlink PATH rows in test 65
**Closes gaps:** G4 · **Type:** unit · **Priority:** low · **File:** same.

## What NOT to Test

- A01, A13, A14, A16: equivalent. Their arguments are in the previous pass and still hold, because the lines they touch are unchanged.
- The directory at a blob PATH (see F3): this is a design decision, not a test gap.
- `${x[0]@a}` against scalars, indexed arrays and unset variables: test 57's `ent-indexed`/`memo-indexed` rows and N04/N05 already cover them. Stage 1 checked the remaining type answers by execution.

## Coverage Gaps Beyond Current Scope

**1.** Stage 1's differential fuzz of the bottom-up memo against 21b35ebf (12,000-45,000 random-order calls) could become a kept property test. It is not needed for merge, because test 57 plus the mutants above pin each rule.

## Summary

The highest-value addition is test 67. It pins D1 (`${x@a}`'s linear cost) host-independently and also closes a gap no one had reported: the ENT side of D1 (N03) survived the whole HEAD suite. Tests 68 and the two extra rows in test 65 close the two remaining non-equivalent survivors on 4b7f2357's guard. With Appendix A, every non-equivalent mutant over the changed lines is killed under 23- and 79-character TMPDIRs, and the patched file passes 68/68 under both. Residual risk: test 66 has 2-3× headroom on a loaded host (F2), and the directory-at-blob-PATH answer is left to the security/API decision. No code defect found.

## Goal-Alignment Note

- Goal: land feat/build-loop-u2a3c once its review-fix loop is clean.
- Answered: yes. I ran a mutation pass over 4b7f2357's lib lines (13 mutants) and re-checked the earlier survivors (6), under a 23- and a 79-character TMPDIR. I weighed the escalations: the timing-only D1 guard has a host-independent replacement, test 67, which is verified. The blob-PATH answer is pinned for plain files, and the directory case is deliberately left open. I also assessed flakiness under load.
- What I found: no code defect, and the lib is correct on every mutant-distinguishing input. There are four test gaps, G1-G4, each closed by a verified patch. G1 (N03) is new. All the findings are test-only, Medium at most, and none blocks merge on correctness. Whether to land Appendix A before merge is the orchestrator's call. F1 is the one I would land, since without it D1 regressions on ENT go unseen.
- Out of scope: docs and comment wording (fact-check), and the directory-at-blob-PATH policy (security/API).

## Appendix A — test patch (verified: 68/68 on HEAD under both TMPDIRs)

```diff
--- repo/test/scripts/build-loop-check.bats
+++ p/test/scripts/build-loop-check.bats
@@ -971,12 +971,13 @@
 }
 
 @test "main_checkout refuses a PATH main stores as a link or gitlink, so a plain checkout directory there never passes a path below it (U2a3c final)" {
-    # The checkout holds plain searchable directories where main stores a link and a gitlink.
+    # The checkout holds plain searchable directories where main stores a link and a gitlink;
+    # lx and gx, a link and a gitlink main stores, are absent there and answer 1 too.
     mkdir -p l g && printf 'x\n' > l/f.md && printf 'x\n' > g/f.md
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
-        declare -A E=([l]=120000 [g]=160000) M=()
-        for p in l l/f.md g g/f.md; do c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done' _ "$LIB"
-    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = $'l 1\nl/f.md 1\ng 1\ng/f.md 1' ] || { echo "$status $output $stderr"; return 1; }
+        declare -A E=([l]=120000 [g]=160000 [lx]=120000 [gx]=160000) M=()
+        for p in l l/f.md g g/f.md lx gx; do c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done' _ "$LIB"
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = $'l 1\nl/f.md 1\ng 1\ng/f.md 1\nlx 1\ngx 1' ] || { echo "$status $output $stderr"; return 1; }
 }
 
 @test "the checkout phase stays near linear in the number of import tokens main lacks (U2a3c final performance F1)" {
@@ -989,3 +990,24 @@
         main_imports && echo ok || echo failed' _ "$LIB"
     [ "$output" = ok ] || { echo "$status $output $stderr"; return 1; }
 }
+
+@test "main_checkout's cost per call does not grow with ENT's or MEMO's size, a ratio of two timings in one process so no host is fast or slow enough to hide it (U2a3c final performance F1)" {
+    # 400 calls with ENT and MEMO of 30,000 entries each, against 400 with both
+    # empty, timed in the same shell. Constant-time type checks give a ratio near
+    # 1 (0.4-1.0 here, idle or with 24 busy loops on 16 CPUs); a check linear in
+    # either array (${x@a}, as at 3a35c8b9) gives 59-141. Best of three rounds
+    # against a bound of 10, so a stall in one round cannot fail it.
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        declare -A E=() M=() BE=() BM=(); for ((i = 0; i < 30000; i++)); do BE["z$i"]=100644; BM["y$i"]=2; done
+        t() { local s=$EPOCHREALTIME e k; for ((k = 0; k < 400; k++)); do main_checkout "$1" "$2" "q$k/x.md" || true; done; e=$EPOCHREALTIME; echo $(( ${e/./} - ${s/./} )); }
+        best=""; for r in 1 2 3; do a=$(t E M); b=$(t BE BM); x=$(( b * 100 / a )); [[ -n "$best" && $best -le $x ]] || best=$x; done; echo "$best"' _ "$LIB"
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" -le 1000 ] || { echo "ratio x100: $status $output $stderr"; return 1; }
+}
+
+@test "main_checkout answers a PATH main stores as a blob by the checkout's plain file there, as U2b's caller precondition allows (U2a3c final)" {
+    printf 'x\n' > b.md && printf 'x\n' > e.md
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        declare -A E=([b.md]=100644 [e.md]=100755) M=()
+        for p in b.md e.md; do c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done' _ "$LIB"
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = $'b.md 0\ne.md 0' ] || { echo "$status $output $stderr"; return 1; }
+}
```

Verification: test 67 fails on N01 (14129), N02 (5919), N03 (10195) and 3a35c8b9's lib (16461), and passes on HEAD at 41-108. Test 68 fails on N09 and N13. Patched test 65 fails on N06 (`l/f.md 0`), N10 and N11 (`lx 2`). Every number is a ratio ×100.

## Appendix B — optional, for F2 (not run as a mutant; 66 passes either way on HEAD)

```diff
-    # 4,000 tokens @nI/a/b/c/d/x.md, none in the checkout: about 2.5 s here; at
-    # 3a35c8b9 main_checkout's ${MEMO@a} type check cost time linear in MEMO's
-    # size, which grows with the tokens (44.6 s), so this catches it on hosts up
-    # to about 2x faster than the one it was measured on.
+    # 4,000 tokens @nI/a/b/c/d/x.md, none in the checkout: about 2.5 s here (6.5 s
+    # with the CPUs oversubscribed 1.5x). A hang guard only: the ${x@a} cost class
+    # (44.6 s at 3a35c8b9) is pinned host-independently by the ratio test below.
     { printf 'see'; for ((i = 0; i < 4000; i++)); do printf ' @n%d/a/b/c/d/x.md' "$i"; done; printf '\n'; } > CLAUDE.md && commit_all many
-    run --separate-stderr timeout 20 env LC_ALL=C bash -c '…'
+    run --separate-stderr timeout 60 env LC_ALL=C bash -c '…'
```
