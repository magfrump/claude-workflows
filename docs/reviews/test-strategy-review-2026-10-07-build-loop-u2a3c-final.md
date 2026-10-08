Commit: 3a35c8b9

# Test Strategy: feat/build-loop-u2a3c, final confirming pass (iteration 3)

**Scope:** lib lines changed since 21b35ebf (`git diff 21b35ebf 3a35c8b9 -- scripts`: main_checkout's bottom-up memo and PATH memo, the 4096-byte link-text cap, `capped_read drain`), plus a re-check of iteration 2's surviving mutants; tests in `test/scripts/build-loop-check.bats`.
**Reviewed:** 2026-10-07
**Role:** test-strategy critic (scratch tag `ts3`), final pass.

Execution provenance: scratch dir `/tmp/u2a3c-i2-ts3-oAzj`. `head/` and `old/` are `git archive` of 3a35c8b9 and 21b35ebf (scripts, test). `p/` is HEAD's lib with the patched test file (Appendix A). `pg/` is `p/` plus the guard (Appendix B). Mutants are in `m/<name>/`, defined in `tools/mutants.py`, run by `tools/runmut.sh`, with results in `res/<name>.<tmpdir-tag>` (failing test numbers) and `.tap`. Every suite ran twice: once with `TMPDIR=/tmp/u2a3c-i2-ts3-oAzj/t/s` (26 characters) and once with `TMPDIR=/tmp/u2a3c-i2-ts3-oAzj/t/long_tmpdir_component_for_root_length_sensitivity_padding_xx` (85 characters), with `LC_ALL=C`. The worktree was not modified, apart from writing this report.

Baselines:
- HEAD, unpatched build-loop-check: 63/63 with the short TMPDIR. With the long one, **62/63: test 59 fails**, which reproduces r1's escalation.
- Patched file (65 tests) on HEAD's lib: 64/65 under both TMPDIRs. Only the new test 65 fails, as it should until the guard lands.
- Patched file on HEAD plus the guard: 65/65 under both TMPDIRs.
- HEAD plus the guard, other suites: dev-cycle.bats 78/78, fixture-hermeticity 2/2, build-loop-read 18/19. The failure there is test 4, "this repo's own docs/dev-cycle.md". It fails the same way on the unguarded HEAD copy, because the scratch copy has no `docs/`. It is a copy artifact.
- shellcheck as health-check runs it (`-x -e SC1091 -s bash -S warning`) is clean on the patched bats file and on the guarded lib.

## Test Conventions

- bats with `load ../lib/build-loop-fixtures`: each test gets a throwaway repo under `$BATS_TEST_TMPDIR/repo`, and `imps WALK PATH...` / `want PATH WORD` read a walk's answers.
- Direct unit tables call `main_checkout`/`import_work` inside `run --separate-stderr env LC_ALL=C bash -c '...' _ "$LIB"` (T1 is the model).
- Cost claims are pinned by PATH shims that count forks (the realpath shim in test 54 and the awk `IT_WORK` shim in test 59). There is one wall-clock bound, `timeout 6` in test 62.

## Mutation pass

30 mutants (16 over the new lines, 12 re-checks of iteration 2's survivors, 2 of the proposed guard). Each was run against the full patched build-loop-check under both TMPDIRs. The results were identical under both. Test numbers are the patched file's: 1-63 as at HEAD, 64 the new counted-depth test, 65 the new precondition test. Test 65 fails on every HEAD-based mutant by design, so it is left out of their "killed by" lists below.

| Mutant | Change | Killed by (HEAD tests 1-63) | Killed by new/patched tests |
|---|---|---|---|
| A01 memo-hit-ignores-value | `st="${mc_m[$c]}"` -> `st=d` on a memo hit | **survives** | equivalent (see below) |
| A02 no-break-at-memo | drop `break` at the nearest memoized ancestor | 54 62 | 64 |
| A03 no-ancestor-mode-check | drop the `^1[26]0000$` ancestor check | 13 16 51 57 58 | |
| A04 no-memo-store | drop `mc_m[$c]="$st"` | 57 62 | 64 |
| A05 memo-only-d | store only `d` (21b35ebf's shape: absent ancestors unmemoized) | 57 62 | 64 |
| A06 ancestors-bottom-up | walk `anc` from the bottom, not from the top | 57 | |
| A07 path-memo-no-x | memoize PATH as d without `-x` | 51 57 | |
| A08 no-path-memo | drop `[[ ! -x ]] \|\| mc_m[$c]=d` | **survives** | 54 with bound 14 (patched) |
| A09 link-cap-4097 | `-le 4096` -> `-le 4097` | 63 | |
| A10 link-cap-removed | drop the size check | 63 | |
| A11 link-cap-after-reads | move the size check after both whole reads | **survives** (unpatched 63 passes) | 63 patched (blob shim) |
| A12 blob-no-drain | `capped_read drain` -> `capped_read` | 53 | |
| A13 drain-always | `capped_read` always drains | **survives** | equivalent (time only) |
| A14 checkout-arm-drains | checkout arm passes `drain` | **survives** | equivalent (time only) |
| A15 old-main_checkout | 21b35ebf's main_checkout transplanted | 57 62 (host-dependent) | 64 |
| A16 cat-file-s-failure-ignored | `git cat-file -s` failure treated as size 0 | **survives** | equivalent (fails closed one line later) |
| R13 modes-skipped-below-absent | skip the mode check while `st != d` | 57 58 | |
| R14 file-ancestor-fails | plain-file ancestor returns 1 | 57 58 | |
| R16 dangling-ancestor-absent | ancestor test `! -e` only | 57 | |
| R18 no-readable-check | plain file returns 0 without `-r` | 57 | |
| R19 dir-not-plain | `[[ -d ]]` for `plaindir` at PATH | 13 57 | |
| R20 no-assoc-check | drop the `@a` check | 57 | |
| R23 symlinked-ancestor-passes | ancestor `-d && -x` | 57 | |
| R29 awk-no-wmax-cap | IT_WORK never lowers `wmax` | 60 | |
| R39 tree-no-left | tree walk passes IMPORT_WORK_MAX | 59 (short TMPDIR only; at 85 chars 59 fails on HEAD too) | 59 patched, both TMPDIRs |
| R41 checkout-no-left | checkout arm passes IMPORT_WORK_MAX | 59 (same caveat) | 59 patched |
| R42 checkout-no-charge | checkout arm charges a throwaway | 4 7 12 14 17 21 22 40 45 52-55 59 61 | |
| R43 blob-no-left | blob arm passes IMPORT_WORK_MAX | 59 (same caveat) | 59 patched |
| G01 guard-removed (on pg) | HEAD's code | — | 65 |
| G02 guard-link-only (on pg) | guard `^120000$` only | — | 65 (the gitlink rows) |

Every iteration-2 survivor that was not equivalent (M13-M23 and M29-M43 in the previous table, R* here) is now killed by tests T1-T4, which landed in 2fbd929b. M03, M07, M28 and M32 are on lines that have not changed since 21b35ebf, and their equivalence arguments still hold.

Equivalent survivors:
- **A01**: a memo value of 2 means the ancestor is absent or a plain file, so every path below it is also absent: `-e` fails, and gives ENOTDIR under a file. The mutant's `st=d` therefore sets `st=2` again at the next level down, or returns 2 at PATH's `-e` test, and the main-mode checks run either way. The outputs and memo contents match. The only cost is one stat per call, and no fork. On a static checkout, the value 2 is an optimisation and not a rule. A01 survives T1 and the counted test 64.
- **A13/A14**: draining a regular file reads it whole, so the output is the same and the only cost is time. The comment's claim is about the pipe arm, which A12 pins.
- **A16**: when `cat-file -s` fails, the next `git cat-file blob` on the same object fails too, and the walk still fails closed.

## Untested Paths Touched by the Change

- **G1** — test/scripts/build-loop-check.bats:897-912 (test 59, T3) — the cap table fixes `IMPORT_WORK_MAX=1000`, while `w` grows with ROOT_REAL's length, because `put` charges each resolved spelling. Once `4w > 1000`, which happens at a fixture root of about 56 characters, the main walk's fourth file fails, and with it the whole `bash -c`, silently under `set -e`. The arm-level caps (`:775`, `:837`, `:839`) are then unpinned on such hosts. R39, R41 and R43 cannot be told apart from HEAD there — not covered on long-TMPDIR hosts.
- **G2** — scripts/lib/dev-cycle-read.sh:738-748 — the bottom-up memo's linear cost on a deep absent token is pinned only by `timeout 6` in test 62. It catches A15 (21b35ebf) only on hosts less than about 1.8x faster than this one: 21b35ebf took 10.5-11 s here and HEAD 0.66 s, per r2/r3. Not covered host-independently.
- **G3** — scripts/lib/dev-cycle-read.sh:843 — the size check runs *before* the two whole reads at :846-847, as the comment says ("it fails before the two whole reads below"). Not covered: A11 passes unpatched test 63.
- **G4** — scripts/lib/dev-cycle-read.sh:753 — the PATH memo (`[[ ! -x "$c" ]] || mc_m[$c]=d`), which saves a longer candidate's realpath on its prefix directories. Not covered: A08 survives. Test 57's bound of 30 allows the 18 calls A08 makes, while HEAD makes 10.
- **G5** — scripts/lib/dev-cycle-read.sh:753 with :720-723 — a PATH that main stores as a link or gitlink, held as a plain searchable directory in the checkout, gets memoized as d. A later call below it then returns 0 where 21b35ebf returned 1. Executed: `l 2`, `l/f.md 0`, `g 2`, `g/f.md 0`. No test pins main_checkout's precondition, and HEAD has no guard for it. main_imports never makes such a call (`:819`/`:825` and `:870` guard on `ent`) — not covered.
- **G6** — test/scripts/build-loop-check.bats:853 and :879 (T1) — the title says the function "memoizes only plain searchable directories", but MEMO also holds the 2 entries (`f.md=2 nd2/m=2 nd2=2 nd=2`), and the test prints only the d keys. The 2 entries are not covered. No non-equivalent mutant depends on them (see A01), so this is a legibility gap.
- **G7** — test/scripts/build-loop-check.bats:822-825 — the comment gives 18 realpath calls. HEAD makes 10 (measured under both TMPDIRs); 18 is A08's count — stale text.

## Findings

### F1 — Test 59 (T3) fails on hosts with a long TMPDIR
- **Severity:** Medium. It makes the suite red on some hosts and review replicates, and it hides R39, R41 and R43 there.
- **Location:** test/scripts/build-loop-check.bats:906 (`IMPORT_WORK_MAX=1000; want=...`)
- **Evidence:** With an 85-character TMPDIR, unpatched HEAD gives `not ok 59 each walk caps every file's parser...`, and the other 62 tests pass. With the patched line `m=$((10 * w)); IMPORT_WORK_MAX=$m; ...`, HEAD passes under both 26- and 85-character TMPDIRs, and R39, R41 and R43 fail it under both.
- **Confidence:** High (executed)
- **Legibility-target:** the IMPORT_WORK_MAX comment's unit. The patch's comment says why the caps are relative: the charge includes the resolved spelling, which includes the root.

### F2 — The deep-token regression test is host-dependent; a counted companion pins it on any host
- **Severity:** Medium. The B2 fix is a performance claim, and its only guard stops discriminating on a fast host.
- **Location:** test/scripts/build-loop-check.bats:932-940 (test 62); new test 64
- **Evidence:** Test 64 counts main_checkout's executed commands (xtrace to a file) over every prefix of a token 100 and 400 levels deep. HEAD gives 4701 and 18801 (ratio 4.0). 21b35ebf's function (A15) gives 72704 and 1130804 (15.6). The bound is `b <= 6a`. Test 64 kills A02, A04, A05 and A15, and passes HEAD under both TMPDIRs. A ratio between two depths on the same host is independent of host speed. I found no fork-count shim that works here: absent ancestors take the `[[ ! -e && ! -L ]]` branch, which forks nothing, so the realpath-shim style cannot see this regression.
- **Confidence:** High (executed). That the ratio is independent of bash version is inferred: both counts come from the same interpreter.
- **Legibility-target:** the "Bottom up to the nearest decided ancestor" comment and the commit's O(D^3) claim. With test 64 carrying the kill, test 62's `timeout 6` can be relaxed (for example to 30) to cut flake risk on slow hosts. That change is optional, and I did not run it.

### F3 — The link-text test cannot see "before reading it whole"
- **Severity:** Low. The outcome is pinned and only the order is not. A read-then-reject regression costs one 4 MiB-class read per link.
- **Location:** test/scripts/build-loop-check.bats:942-950 (test 63)
- **Evidence:** A11 (the size check moved after both reads) passes unpatched 63. The patched 63 adds a `git` shim that logs each `cat-file blob` object name and expects `walk: failed / link blob unread / walk: ok / link blob read`. HEAD passes it, and A09, A10 and A11 fail it, under both TMPDIRs.
- **Confidence:** High (executed)
- **Legibility-target:** the comment "it fails before the two whole reads below" and the test title, which now holds.

### F4 — The PATH memo is unpinned (A08 survives)
- **Severity:** Low. It is a cost claim (each directory costs its realpath once per walk), and the answers do not change.
- **Location:** scripts/lib/dev-cycle-read.sh:753; test/scripts/build-loop-check.bats:831
- **Evidence:** The realpath shim counts 10 calls at HEAD and 18 under A08, under both TMPDIRs, and the bound is 30. Lowering the bound to 14 kills A08 and passes HEAD.
- **Confidence:** High (executed)
- **Legibility-target:** the lib's trailing comment at :753 ("a prefix candidate's directory, which longer ones pass through") and the test comment's count (G7).

### F5 — No test pins main_checkout's precondition; a guard would close G5
- **Severity:** Medium for U2a4/U2b. No live caller is affected, but the documented contract for another caller does not exclude the input that fails open.
- **Location:** scripts/lib/dev-cycle-read.sh:735-753, comment at :720-723
- **Evidence:** New test 65 fails on HEAD with `l 2 / l/f.md 0 / g 2 / g/f.md 0`. On HEAD plus the guard (Appendix B, one line after the `@a` check), it passes with `l 1 / l/f.md 1 / g 1 / g/f.md 1`. The guarded lib passes all 65 tests (both TMPDIRs), dev-cycle 78/78 and fixture-hermeticity. G01 (guard removed) and G02 (guard checks `^120000$` only) both fail test 65. **Test 65 is written to pass once `main_checkout` returns 1 when ENT holds PATH as a link or gitlink.** If the author instead makes :753 conditional on `ENT` lacking PATH, then `l` and `g` return 2. Change the expected rows `l 1`/`g 1` to `l 2`/`g 2`. The `l/f.md 1` and `g/f.md 1` rows, which are the fail-open rows, stay as they are.
- **Confidence:** High (executed)
- **Legibility-target:** the MEMO comment's "set only once its own and every higher ancestor's main mode passed", which the guard makes literally true, and the plan's U2b caller contract.

### F6 — T1's title and the stale "(18)" comment
- **Severity:** Low (text drift)
- **Location:** test/scripts/build-loop-check.bats:853, :879; :825
- **Evidence:** T1 prints only the d keys (`memo d`), while the full MEMO is `d=d f.md=2 nd2/m=2 nd2=2 nd=2` (executed). The patch prints `k=v` and fixes the title. The "(18)" count is 10 at HEAD.
- **Confidence:** High
- **Legibility-target:** the MEMO comment ("d for a plain searchable directory, 2 for one absent or a plain file").

## Recommended Tests

#### Derive T3's caps from w (patch to test 59)
**Closes gaps:** G1 · **Type:** unit/integration · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**What it verifies:** each parser call gets what IMPORT_WORK_MAX has left (`m, m-w, m-2w, m-3w`), on any fixture root.
**Key cases:** `m = 10w`, tree and main walks, both TMPDIR lengths. Kills R39, R41 and R43.

#### Counted linear-cost test (new test 64)
**Closes gaps:** G2 · **Type:** unit (cost) · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**Key cases:** depths 100 and 400, each prefix and `prefix/x.md`, with ratio ≤ 6. HEAD gives 4.0 and 21b35ebf gives 15.6.

#### Blob-read order in the link test (patch to test 63)
**Closes gaps:** G3 · **Type:** integration · **Priority:** medium. The 4097-byte link fails with no `cat-file blob` of it; the 4-byte link is read.

#### Tighter realpath bound (patch to test 54)
**Closes gaps:** G4, G7 · **Type:** integration (cost) · **Priority:** medium. The bound goes from 30 to 14 (HEAD 10, A08 18), and the comment count is corrected.

#### Precondition test (new test 65, with the guard)
**Closes gaps:** G5 · **Type:** unit · **Priority:** high if U2a4/U2b add a caller, otherwise medium.

#### Full memo in T1 (patch to test 57)
**Closes gaps:** G6 · **Type:** unit · **Priority:** low. It pins the 2 entries and fixes the title. It kills no extra non-equivalent mutant, because A01 is equivalent.

## What NOT to Test

- A01, A13, A14 and A16 are equivalent (reasons above). A test for them would have to observe stat or read timing.
- Raising test 62's depth so that 21b35ebf costs more than 30 s: this is host-dependent in the same way, and it costs suite time. Test 64 replaces it as the kill.
- The `/proc` rationale for using `drain` over `[[ -p ]]`: an unshare is refused here, and the code no longer depends on /proc.

## Coverage Gaps Beyond Current Scope

**1.** The work unit's dependence on root length (r1's performance escalation) is not stated next to IMPORT_WORK_MAX. F1's patch only stops the test depending on it.
**2.** No test runs the suite under a long TMPDIR. A CI or health-check run with a padded TMPDIR would have caught F1.

## Summary

The highest-value changes are the T3 fix (F1), which makes the suite green on long-TMPDIR hosts and restores the R39/R41/R43 kills there, and the counted test 64 (F2), which pins the B2 fix on any host. With the patches in Appendix A and the guard in Appendix B, every non-equivalent mutant over the lines changed since 21b35ebf is killed under both a 26- and an 85-character TMPDIR. The 4 remaining survivors (A01, A13, A14, A16) are equivalent. Every non-equivalent survivor from iteration 2 is killed at HEAD. Residual risk: if test 65 lands without the guard, it is red until the guard lands. If the author picks the conditional-memo fix instead, test 65's two PATH rows change, as F5 states.

## Goal-Alignment Note

The goal is to land feat/build-loop-u2a3c once its review-fix loop is clean. Nothing here is a defect in what the walk answers at HEAD. F1, however, is a test bug that makes the suite red on hosts with a long TMPDIR (62/63), so it should be fixed before merge: it is a one-line test patch, verified. F5's guard is one lib line, and it makes the MEMO comment true for any caller. It and test 65 are worth landing now, because U2a4/U2b are the next callers. F2-F4 and F6 are test-only, and each is verified to pass on HEAD and to fail on its target mutant. Out of scope: the docs claims (A5, F11, override rows), which the fact-check covers.

## Appendix A — test patch (`/tmp/u2a3c-i2-ts3-oAzj/tests.patch`, against 3a35c8b9)

```diff
--- head/test/scripts/build-loop-check.bats	2026-10-07 13:08:28.000000000 -0700
+++ p/test/scripts/build-loop-check.bats	2026-10-07 13:37:55.868928071 -0700
@@ -822,13 +822,14 @@
     # @a/b/c/d/e/f/g/h/x.md yields about 20 prefix candidates through eight plain
     # directories main lacks; a realpath shim counts the checks. Unmemoized, each
     # candidate re-checks every ancestor (102 calls; 74 at 3e58eb9c); memoized,
-    # each directory once, plus each candidate's own check (18).
+    # each directory once, plus each candidate's own check (10 at 2fbd929b; 18
+    # without its memo of a prefix candidate's own directory).
     mkdir -p a/b/c/d/e/f/g/h && printf 'x @y.md\n' > a/b/c/d/e/f/g/h/x.md && printf 'see @a/b/c/d/e/f/g/h/x.md\n' > CLAUDE.md && git add CLAUDE.md && git commit -qm base
     mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\necho x >> "%s/calls"\nexec %s "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v realpath)" > "$BATS_TEST_TMPDIR/bin/realpath" && chmod +x "$BATS_TEST_TMPDIR/bin/realpath"
     PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main a/b/c/d/e/f/g/h/y.md
     [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
     want walk ok; want a/b/c/d/e/f/g/h/y.md imported
-    n="$(wc -l < "$BATS_TEST_TMPDIR/calls")"; [ "$n" -le 30 ] || { echo "realpath calls: $n"; return 1; }
+    n="$(wc -l < "$BATS_TEST_TMPDIR/calls")"; [ "$n" -le 14 ] || { echo "realpath calls: $n"; return 1; }
 }
 
 @test "the checkout phase walks an untracked start when main's tree is empty (U2a3c)" {
@@ -850,14 +851,14 @@
     [ "$output" = $'1 ok [a.md] 17\n2 ok [] 24\n3 failed\n4 failed\n5 failed 31\n6 [/0]' ] || { echo "$output $stderr"; return 1; }
 }
 
-@test "main_checkout answers each checkout shape: 0 for a readable plain file, 2 where nothing loads, 1 for anything it does not model, and memoizes only plain searchable directories (U2a3c)" {
+@test "main_checkout answers each checkout shape: 0 for a readable plain file, 2 where nothing loads, 1 for anything it does not model, and memoizes plain searchable directories as d and absent or plain-file ancestors as 2 (U2a3c)" {
     mkdir -p d u sdt && printf 'r\n' > d/r.md && printf 'n\n' > d/n.md && printf 'f\n' > f.md && chmod 000 d/n.md && chmod 644 u
     ln -s d/r.md sf.md && ln -s missing.md dg.md && ln -s missing dgd && ln -s sdt sd && mkfifo ff.md
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
         declare -A E=([lnk]=120000 [gl]=160000 [nd2/m/l]=120000 [f.md]=100644) M=()
         for p in d/r.md nx.md nd/x.md f.md/x.md d u d/n.md sf.md dg.md sd ff.md u/x.md sd/nx.md dgd/x.md lnk/x.md gl/x.md nd2/m/l/x.md; do
             c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done
-        echo "memo $(for k in "${!M[@]}"; do [[ "${M[$k]}" != d ]] || echo "$k"; done | sort | tr "\n" " ")"; declare -a A=(); c=0; main_checkout A M d/r.md || c=$?; echo "ent-indexed $c"; c=0; main_checkout E A d/r.md || c=$?; echo "memo-indexed $c"' _ "$LIB"
+        echo "memo $(for k in "${!M[@]}"; do echo "$k=${M[$k]}"; done | sort | tr "\n" " ")"; declare -a A=(); c=0; main_checkout A M d/r.md || c=$?; echo "ent-indexed $c"; c=0; main_checkout E A d/r.md || c=$?; echo "memo-indexed $c"' _ "$LIB"
     chmod 755 u && chmod 644 d/n.md
     [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = "d/r.md 0
 nx.md 2
@@ -876,7 +877,7 @@
 lnk/x.md 1
 gl/x.md 1
 nd2/m/l/x.md 1
-memo d 
+memo d=d f.md=2 nd2/m=2 nd2=2 nd=2 
 ent-indexed 1
 memo-indexed 1" ] || { echo "$status $output $stderr"; return 1; }
 }
@@ -904,7 +905,8 @@
         out="$(printf "see @a.md\n" | IMPORT_WORK_LEFT=1000000 import_targets "")"; w=0; import_work out w
         for m in $((4 * w - 1)) $((4 * w)); do IMPORT_WORK_MAX=$m; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""
             imported_names && echo "$((m - 4 * w)) tree ok" || echo "$((m - 4 * w)) tree failed"; main_imports && echo "$((m - 4 * w)) main ok" || echo "$((m - 4 * w)) main failed"; done
-        IMPORT_WORK_MAX=1000; want="$(printf "%s\n" 1000 $((1000 - w)) $((1000 - 2 * w)) $((1000 - 3 * w)) | sort -n | tr "\n" " ")"
+        # The caps derive from w: each candidate is charged its resolved spelling, so w grows with the fixture root.
+        m=$((10 * w)); IMPORT_WORK_MAX=$m; want="$(printf "%s\n" $m $((m - w)) $((m - 2 * w)) $((m - 3 * w)) | sort -n | tr "\n" " ")"
         for k in tree main; do IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; rm -f "$C"
             if [[ $k == tree ]]; then imported_names; else main_imports; fi
             got="$(sort -n "$C" | tr "\n" " ")"; [[ "$got" == "$want" ]] && echo "$k caps ok" || echo "$k caps [$got] want [$want]"; done' _ "$LIB"
@@ -942,9 +944,37 @@
 @test "main walk fails on link text main stores longer than 4096 bytes before reading it whole (U2a3c i2 performance F2)" {
     printf 'r\n' > r.md && commit_all base
     l="$(head -c 4097 /dev/zero | tr '\0' a | git hash-object -w --stdin)"; k="$(printf 'r.md' | git hash-object -w --stdin)"
+    # A git shim logs each `git cat-file blob` object name: the long link must fail with no read of its blob.
+    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\n[ "$1 $2" != "cat-file blob" ] || echo "$3" >> "%s/blobs"\nexec %s "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v git)" > "$BATS_TEST_TMPDIR/bin/git" && chmod +x "$BATS_TEST_TMPDIR/bin/git"
     for b in "$l" "$k"; do
         t="$(printf '100644 blob %s\tr.md\n120000 blob %s\tCLAUDE.md\n' "$(git rev-parse main:r.md)" "$b" | git mktree)"
-        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m link)"; imps main r.md; echo "$output" | head -1
+        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m link)"; rm -f "$BATS_TEST_TMPDIR/blobs"
+        PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main r.md; echo "$output" | head -1
+        if grep -q ':CLAUDE\.md$' "$BATS_TEST_TMPDIR/blobs" 2>/dev/null; then echo "link blob read"; else echo "link blob unread"; fi
     done > "$BATS_TEST_TMPDIR/got"
-    [ "$(cat "$BATS_TEST_TMPDIR/got")" = $'walk: failed\nwalk: ok' ] || { cat "$BATS_TEST_TMPDIR/got"; return 1; }
+    [ "$(cat "$BATS_TEST_TMPDIR/got")" = $'walk: failed\nlink blob unread\nwalk: ok\nlink blob read' ] || { cat "$BATS_TEST_TMPDIR/got"; return 1; }
+}
+
+@test "main_checkout's work over a deep token's prefix candidates grows linearly with depth, counted, not timed (U2a3c i2 performance F1)" {
+    # xtrace counts the commands main_checkout runs for every prefix of a token
+    # 100 and 400 levels deep, none in the checkout. Linear work gives a ratio of
+    # about 4 (4.0 at 3a35c8b9); 21b35ebf's top-down rescan of every absent
+    # ancestor gives about 16 (15.6). A count, so no host is fast enough to hide it.
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"; t="$2"
+        for n in 100 400; do unset E M; declare -A E=() M=(); p=""
+            exec 3> "$t"; BASH_XTRACEFD=3; set -x
+            for ((i = 0; i < n; i++)); do p+="a/"; main_checkout E M "${p%/}" || true; main_checkout E M "${p}x.md" || true; done
+            set +x; exec 3>&-; echo "$(wc -l < "$t")"; done' _ "$LIB" "$BATS_TEST_TMPDIR/xtrace"
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$status $output $stderr"; return 1; }
+    a="$(sed -n 1p <<< "$output")"; b="$(sed -n 2p <<< "$output")"
+    [ "$a" -gt 0 ] && [ "$b" -le $((6 * a)) ] || { echo "commands at 100: $a, at 400: $b"; return 1; }
+}
+
+@test "main_checkout refuses a PATH main stores as a link or gitlink, so a plain checkout directory there never passes a path below it (U2a3c final)" {
+    # The checkout holds plain searchable directories where main stores a link and a gitlink.
+    mkdir -p l g && printf 'x\n' > l/f.md && printf 'x\n' > g/f.md
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        declare -A E=([l]=120000 [g]=160000) M=()
+        for p in l l/f.md g g/f.md; do c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done' _ "$LIB"
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = $'l 1\nl/f.md 1\ng 1\ng/f.md 1' ] || { echo "$status $output $stderr"; return 1; }
 }
```

## Appendix B — guard patch (`/tmp/u2a3c-i2-ts3-oAzj/guard.patch`, against 3a35c8b9)

```diff
--- head/scripts/lib/dev-cycle-read.sh	2026-10-07 13:08:28.000000000 -0700
+++ pg/scripts/lib/dev-cycle-read.sh	2026-10-07 13:31:21.253681981 -0700
@@ -734,6 +734,8 @@
   # ${x@a} on an empty array is an unbound-variable error under set -u (an
   # empty main tree, the first call's MEMO); the body reads both through :- and +set.
   set +u; [[ "${mc_e@a}" == *A* && "${mc_m@a}" == *A* ]] || return 1
+  # PATH itself is one main lacks: main's link or gitlink there refuses, before a plain checkout directory at PATH is memoized as d.
+  [[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1
   # Bottom up to the nearest decided ancestor, then top down from it (U2a3c
   # i2 performance F1: top down alone rescanned every absent ancestor).
   while [[ "$c" == */* ]]; do c="${c%/*}"; if [[ -n "${mc_m[$c]+set}" ]]; then st="${mc_m[$c]}"; break; fi; anc+=("$c"); done
```
