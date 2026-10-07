Commit: 21b35ebf

# Test Strategy: feat/build-loop-u2a3c, review-fix loop iteration 2

**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 21b35ebf): `scripts/lib/dev-cycle-read.sh` (capped_read, lower_all, main_checkout and its memo, import_work, the awk trailer and wmax, the work charge in both walks and both main_imports arms, the `.git` special case removed, checkout_md), `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`.
**Reviewed:** 2026-10-07
**Role:** test-strategy critic (scratch tag `ts`), k=1 loop pass.

Execution provenance: bash 5.2.15, mawk, git 2.39, uid 1000 (not root, so the chmod 000/644 probes are meaningful). Scratch dir `/tmp/u2a3c-i2-ts-7T0h`: `base/` is `git archive 21b35ebf`; each mutant is a hardlinked copy `mut-<name>/` whose lib was replaced by a new inode before mutation (base untouched); mutant definitions are in `tools/mutants.py`, the runner in `tools/run.sh`, logs in `log-<mutant>-<suite>.txt`, the per-mutant results in `results-blc.txt` and `results-other.txt`. Bats ran as `TMPDIR=$(mktemp -d /tmp/u2a3c-i2-ts-XXXX) LC_ALL=C bats -j 8 <suite>`. The worktree was not modified except for this report.

Baseline at HEAD: build-loop-check 57/57 (not 60, as the shared context says; the fact-check report found the same), dev-cycle 78/78, build-loop-read 19/19.

## Test Conventions

- bats 1.5+, `load ../lib/build-loop-fixtures`: each test gets a throwaway repo under `$BATS_TEST_TMPDIR/repo` with a hermetic git env (`bl_setup`), `commit_all MSG` stages and commits.
- Walk tests use `imps WALK PATH...` (runs `main_imports`/`imported_names` under `set -euo pipefail`, then `isimported` per path) and `want PATH WORD` (`want walk ok|failed`, `want p imported|-`).
- Function-level tests run `run --separate-stderr env LC_ALL=C bash -c '...; source "$1"; ...' _ "$LIB"` and compare `$output` to one literal string.
- Faults are injected with PATH shims under `$BATS_TEST_TMPDIR/bin` (tr, realpath, python3). Titles name the unit and the finding they pin, e.g. `(U2a3c)`.
- `test/scripts/dev-cycle.bats:1101` pins the lib's function inventory (`declare -F` per name).

## Mutation pass

47 mutants over the changed lib lines, each run against build-loop-check.bats; the 16 that survived it were also run against dev-cycle.bats and build-loop-read.bats, and survived both. "Killed by" is the build-loop-check test number at HEAD; "new" is the recommended test (numbered T1-T5 below) that kills it.

| Mutant | Change | Killed by (HEAD suite) | Killed by new tests |
|---|---|---|---|
| M01 capped-no-drain | drop `cat > /dev/null` | 53 | |
| M02 capped-no-cap | `capped_read() { cat; }` | 33 53 | |
| M03 capped-head-fail-ignored | `head ... \|\| true` | **survives** | equivalent (see below) |
| M04 blob-arm-uncapped | blob arm without capped_read | 53 | |
| M05 checkout-arm-uncapped | checkout arm reads whole file | 53 | |
| M06 tree-uncapped | tree walk reads whole file | 33 | |
| M07 lower_all-no-pipefail | drop `set -o pipefail` in lower_all | **survives** | equivalent (see below) |
| M08 lower_all-not-nul_list | old `mapfile < <(...)` read | 52 | |
| M09 memo-no-lookup | drop the `mc_m` lookup | 54 | T1 |
| M10 memo-no-store | drop `mc_m[$c]=1` | 54 | T1 |
| M11 no-ancestor-mode-check | drop the 1[26]0000 check | 13 16 51 | T1 T2 |
| M12 no-gitlink-mode | `^120000$` only | 13 51 | T1 |
| M13 stop-modes-below-absent | `continue` -> `break` below an absent ancestor | **survives** | T1 T2 |
| M14 file-ancestor-fails | plain-file ancestor returns 1, not 2 | **survives** | T1 T2 |
| M15 no-search-bit | drop `[[ -x ]]` on ancestors | 51 | T1 |
| M16 dangling-ancestor-absent | dangling ancestor link counts as absent | **survives** | T1 |
| M17 dangling-target-absent | dangling link at PATH returns 2 | 13 | T1 |
| M18 no-readable-check | plain file returns 0 without `-r` | **survives** | T1 |
| M19 dir-not-plain | `[[ -d ]]` for `plaindir` at PATH | **survives** | T1 |
| M20 no-assoc-check | drop the `@a` check | **survives** | T1 |
| M21 no-set-plus-u | drop `set +u` | 39 tests | |
| M22 absent-ancestor-fails | absent ancestor returns 1 | 5 7 12 13 17 19 45 | |
| M23 symlinked-ancestor-passes | ancestor `-d && -x` instead of `plaindir` (pre-80cc6224 shape) | **survives** | T1 |
| M24 start-refusal-ignored | drop the start loop's `c -ne 1` | 10 51 | |
| M25 start-c2-queued | queue a start that answered 2 | 4 | |
| M26 import-c2-queued | queue an import that answered 2 | 38 tests | |
| M27 import-refusal-ignored | drop the import loop's `c -ne 1` | 10 13 16 51 | |
| M28 no-phase-order | checkout files join `queue`, not `tq` | **survives** | equivalent (see below) |
| M29 awk-no-wmax-cap | IT_WORK no longer lowers `wmax` | **survives** | T4 |
| M30 awk-trail-always | trailer printed with IT_WORK unset | 24 35 42 43 44 50 | |
| M31 awk-trailer-zero | trailer reports 0 | 56 | |
| M32 awk-ge-emit | `>=` for `>` in emit's bound | **survives** | not targeted (What NOT to Test) |
| M33 awk-no-put-charge | put() not charged | 49 | |
| M34 awk-no-splice-charge | splice not charged | 31 | |
| M35 iw-no-trailer-check | import_work accepts a missing trailer | 57 | |
| M36 iw-lt | `<` for `<=` | 56 | |
| M37 iw-no-strip-nl | keep the newline before the trailer | 37 57 | |
| M38 iw-no-limit | import_work never fails | 57 | |
| M39 tree-no-left | tree walk passes IMPORT_WORK_MAX, not what is left | **survives** | T3 |
| M40 tree-no-charge | tree walk charges a throwaway total | 56 | |
| M41 checkout-no-left | checkout arm passes IMPORT_WORK_MAX | **survives** | T3 |
| M42 checkout-no-charge | checkout arm charges a throwaway total | **survives** | T3 |
| M43 blob-no-left | blob arm passes IMPORT_WORK_MAX | **survives** | T3 |
| M44 blob-no-charge | blob arm charges a throwaway total | 56 | |
| M45 checkout_md-stderr-ignored | ls-files stderr dropped | 51 | |
| M46 restore-dotgit-skip | U2a3b's `.git` special case put back | 22 | |
| M47 dotgit-fails-closed | any `.git/*` or `*/.git` import fails | 40 45 | |

16 survive the current suites; the 5 recommended tests kill 13 of them. The other 3 (M03, M07, M28) are equivalent, and M32 is left as a boundary nobody can observe today:
- **M03**: `head` fails only on a read error after the redirect opened. A directory never reaches `capped_read`, because `main_checkout` admits only `rawfile` paths and the tree walk tests `-f`. An unreadable file fails at the redirect, before `head` runs.
- **M07**: `tr` is the last stage of lower_all's pipeline, so the pipeline's status is tr's with or without pipefail. pipefail matters only if `printf` fails. N1's test (52) still kills M08, the old unchecked read.
- **M28**: the arm is chosen by `ent`, not by queue position, and `seen` dedupes in both orders, so phase order shows in neither output nor budget. Override row 446's ordering concern is structural, as the fact-check found.
- **M32**: the exact-limit test (56) ends each file on a put() charge, so emit's own `>` boundary is never met at equality.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:728-730 — main's link/gitlink modes are still checked for ancestors *two or more levels* below an absent checkout ancestor (`continue`, not `break`) — not covered. Mutant M13 survives. It fails open: with the checkout lacking `a/`, an import into `a/b/l/x.md`, where main stores `a/b/l` as a link, answers 2 and the walk passes.
- **G2** — scripts/lib/dev-cycle-read.sh:731 — the `rawfile "$c"` arm, which returns 2 for a path below a plain checkout file — not covered (M14 survives; with the arm gone, the walk fails closed on any `@file.md/x` token).
- **G3** — scripts/lib/dev-cycle-read.sh:731-733 — an ancestor that is a checkout symlink to a directory, or a dangling symlink, with PATH absent below it: returns 1 now, 2 before 80cc6224 (the "2->1 shape change") — not covered directly (M23 and M16 survive). At walk level, the prefix candidate naming the link itself already fails, so only a direct call shows the difference.
- **G4** — scripts/lib/dev-cycle-read.sh:736-739 — the final shape checks: `[[ -r ]]` on a plain file (M18), `plaindir` rather than `-d` at PATH (M19), and an unsearchable directory named alone answering 2 — not covered as return codes. At walk level the read failure masks M18, and the link prefix masks M19.
- **G5** — scripts/lib/dev-cycle-read.sh:725 — ENT or MEMO not an associative array returns 1 — not covered (M20 survives; every caller passes `local -A`).
- **G6** — scripts/lib/dev-cycle-read.sh:732 — which directories the memo stores (only plain searchable ones) — covered only by the realpath count (test 54), not by content.
- **G7** — scripts/lib/dev-cycle-read.sh:760, 821, 823 — each arm passes the parser `IMPORT_WORK_MAX - work` as its cap, not the whole bound — not covered in any arm (M39, M41, M43 survive). `import_work`'s after-the-fact sum still fails the walk, so the answer is unchanged. The loss is the early stop: a regressed arm parses up to a further whole bound (about 5 s) before failing.
- **G8** — scripts/lib/dev-cycle-read.sh:821-822 — the checkout arm adds its work to the walk total — not covered (M42 survives). Test 56 has only one checkout file, and it comes last, where the cap alone already fails it. If a regression stops charging this arm, N checkout files each get the bound main's files left: the N-bounds cost P2 closed.
- **G9** — scripts/lib/dev-cycle-read.sh:622 — awk lowers `wmax` to IT_WORK when that is under 50,000,000 — not covered (M29 survives; import_work's sum masks it, as in G7).
- **G10** — test/scripts/dev-cycle.bats:1110 — the function inventory lists `md_ls checkout_md main_checkout lower_all capped_read` but not `import_work` — not covered (fact-check escalation).
- **G11** — test/scripts/build-loop-check.bats:69 — the comment "(the main walk fails closed on it until U2a3c)" is stale. The main walk reads untracked starts now, as test 4 pins (fact-check Claim 24).
- **G12** — scripts/lib/dev-cycle-read.sh:808-811, 849-855 — a main import of a path that is also an untracked start (the start loop marks it seen and puts it in tq; the import loop then skips it) — not covered (fact-check escalation). No mutant here survives, because the import loop's own `main_checkout` call catches any start-side regression, so this is a pin only.

## Findings

### F1 — fail-open path in main_checkout unpinned (G1)
- **Severity:** Medium
- **Location:** scripts/lib/dev-cycle-read.sh:730; tests: none
- **Evidence:** M13 (`[[ -z "$st" ]] || break`) passes all 57+78+19 tests (`log-M13-stop-modes-below-absent-*.txt`). Recommended T2 fails on M13 (`walk: ok` where `walk: failed` is wanted) and passes on HEAD.
- **Confidence:** high (ran)
- **Legibility-target:** whoever edits main_checkout's ancestor loop. The comment "only main's modes are left" says what `continue` is for, but no test holds it.

### F2 — main_checkout's return-code contract is pinned only through walks, which mask six of its rules (G2-G6)
- **Severity:** Medium
- **Location:** scripts/lib/dev-cycle-read.sh:711-740
- **Evidence:** M14, M16, M18, M19, M20 and M23 survive all three suites. T1 kills each of them, plus M09-M12, M15 and M17 (`tools/runnew.sh mut-<m>`).
- **Confidence:** high (ran)
- **Legibility-target:** the comment block at lines 711-720 and the plan's "an unsearchable directory named alone answers 2". T1 is a table of every shape, so a change to the comment and a change to the code fail in the same place.

### F3 — the walk-wide work bound is pinned on its total but not on its caps or on every arm's charge (G7-G9)
- **Severity:** Medium
- **Location:** scripts/lib/dev-cycle-read.sh:622, 760, 821-823; test/scripts/build-loop-check.bats:842 (test 56)
- **Evidence:** M29, M39, M41, M42 and M43 survive. T3 (four files: two on main, two only in the checkout; an awk shim logs each call's IT_WORK) kills M39, M41, M42 and M43. T4 kills M29.
- **Confidence:** high (ran)
- **Legibility-target:** the IMPORT_WORK_MAX comment ("N adversarial files cost one bound, not N"). Test 56 states this claim, but its fixture cannot falsify it for the checkout arm.

### F4 — inventory and stale comment (G10, G11)
- **Severity:** Low
- **Location:** test/scripts/dev-cycle.bats:1110; test/scripts/build-loop-check.bats:69
- **Evidence:** With the patch below, the inventory test passes on HEAD and fails with `missing import_work` when import_work is renamed (`mut-inv/`). Line 69 contradicts test 4's title.
- **Confidence:** high
- **Legibility-target:** a reader of the test file.

### F5 — untracked start also imported from main (G12)
- **Severity:** Low
- **Location:** scripts/lib/dev-cycle-read.sh:808-811, 849-855
- **Evidence:** T5 passes on HEAD. No mutant in this pass kills it, because the import loop's own admission backs up the start loop, so it is a regression pin for override row 446's revisit trigger rather than a mutation-backed gap.
- **Confidence:** medium (value is in documentation, not detection)
- **Legibility-target:** override row 446.

## Recommended Tests

All five pass on HEAD as written, in a scratch copy of the suite (62/62 with them appended; `shellcheck -S warning` clean; the SC2016 infos match the existing tests). Append them to `test/scripts/build-loop-check.bats`.

#### T1 — main_checkout's table of shapes
**Closes gaps:** G2, G3, G4, G5, G6 (and the unit half of G1) · **Type:** unit · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**What it verifies:** each shape's return code as lines 711-720 state it, and that MEMO holds only `d`.
**Kills:** M09 M10 M11 M12 M13 M14 M15 M16 M17 M18 M19 M20 M23.

#### T2 — walk level: link below an absent ancestor; path below a plain file
**Closes gaps:** G1, G2 · **Type:** integration · **Priority:** high · **Kills:** M11 M13 M14.

#### T3 — every arm's parser cap and charge
**Closes gaps:** G7, G8 · **Type:** integration (awk PATH shim) · **Priority:** medium · **Kills:** M39 M41 M42 M43.
It could replace test 56: it keeps 56's -1/0 boundary over four files.

#### T4 — the parser's own early stop at IMPORT_WORK_LEFT
**Closes gaps:** G9 · **Type:** unit · **Priority:** low · **Kills:** M29.

#### T5 — a main import of an untracked start
**Closes gaps:** G12 · **Type:** integration · **Priority:** low · **Kills:** none (a pin).

```bash

@test "main_checkout answers each checkout shape: 0 for a readable plain file, 2 where nothing loads, 1 for anything it does not model, and memoizes only plain searchable directories (U2a3c)" {
    mkdir -p d u sdt && printf 'r\n' > d/r.md && printf 'n\n' > d/n.md && printf 'f\n' > f.md && chmod 000 d/n.md && chmod 644 u
    ln -s d/r.md sf.md && ln -s missing.md dg.md && ln -s missing dgd && ln -s sdt sd && mkfifo ff.md
    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        declare -A E=([lnk]=120000 [gl]=160000 [nd2/m/l]=120000 [f.md]=100644) M=()
        for p in d/r.md nx.md nd/x.md f.md/x.md d u d/n.md sf.md dg.md sd ff.md u/x.md sd/nx.md dgd/x.md lnk/x.md gl/x.md nd2/m/l/x.md; do
            c=0; main_checkout E M "$p" || c=$?; echo "$p $c"; done
        echo "memo ${!M[*]}"; declare -a A=(); c=0; main_checkout A M d/r.md || c=$?; echo "ent-indexed $c"; c=0; main_checkout E A d/r.md || c=$?; echo "memo-indexed $c"' _ "$LIB"
    chmod 755 u && chmod 644 d/n.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] && [ "$output" = "d/r.md 0
nx.md 2
nd/x.md 2
f.md/x.md 2
d 2
u 2
d/n.md 1
sf.md 1
dg.md 1
sd 1
ff.md 1
u/x.md 1
sd/nx.md 1
dgd/x.md 1
lnk/x.md 1
gl/x.md 1
nd2/m/l/x.md 1
memo d
ent-indexed 1
memo-indexed 1" ] || { echo "$status $output $stderr"; return 1; }
}

@test "main walk fails on a path under a link main stores below a directory the checkout lacks, and walks a path under a plain file (U2a3c)" {
    mkdir -p a/b real docs && ln -s ../../real a/b/l && printf 'evil @../docs/s.md\n' > real/x.md && printf 'n\n' > docs/n.md
    printf 'see @a/b/l/x.md and @docs/n.md/x.md\n' > CLAUDE.md && commit_all deep-link
    # The checkout keeps a/b/l: the parent-link refusal.
    imps main docs/s.md; want walk failed; want docs/s.md imported
    # The checkout lacks a: main still stores a/b/l as a link, two levels below it, which the walk does not follow.
    rm -r a; imps main docs/s.md; want walk failed; want docs/s.md imported
    # A path under a plain file loads nothing and is no failure.
    git rm -q -r a && printf 'see @docs/n.md/x.md\n' > CLAUDE.md && commit_all under-file
    imps main docs/s.md docs/n.md; [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/n.md imported; want docs/s.md -
}

@test "each walk caps every file's parser at what IMPORT_WORK_MAX has left, in every arm, and charges every arm (U2a3b L2-confirm performance P2, U2a3c)" {
    # Four top-level files alike but for one letter cost w each: two on main, two
    # only in the checkout, so each main_imports arm runs twice. An awk shim logs
    # the cap each parser call is given (IT_WORK).
    printf 'see @a.md\n' > AGENTS.md && printf 'see @b.md\n' > GEMINI.md && commit_all two && printf 'see @c.md\n' > CLAUDE.md && printf 'see @d.md\n' > CLAUDE.local.md
    mkdir -p "$BATS_TEST_TMPDIR/bin" && printf '#!/bin/sh\n[ -z "${IT_WORK+x}" ] || echo "$IT_WORK" >> "%s/cap"\nexec %s "$@"\n' "$BATS_TEST_TMPDIR" "$(command -v awk)" > "$BATS_TEST_TMPDIR/bin/awk" && chmod +x "$BATS_TEST_TMPDIR/bin/awk"
    run --separate-stderr timeout 60 env LC_ALL=C PATH="$BATS_TEST_TMPDIR/bin:$PATH" C="$BATS_TEST_TMPDIR/cap" bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
        out="$(printf "see @a.md\n" | IMPORT_WORK_LEFT=1000000 import_targets "")"; w=0; import_work out w
        for m in $((4 * w - 1)) $((4 * w)); do IMPORT_WORK_MAX=$m; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""
            imported_names && echo "$((m - 4 * w)) tree ok" || echo "$((m - 4 * w)) tree failed"; main_imports && echo "$((m - 4 * w)) main ok" || echo "$((m - 4 * w)) main failed"; done
        IMPORT_WORK_MAX=1000; want="$(printf "%s\n" 1000 $((1000 - w)) $((1000 - 2 * w)) $((1000 - 3 * w)) | sort -n | tr "\n" " ")"
        for k in tree main; do IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; rm -f "$C"
            if [[ $k == tree ]]; then imported_names; else main_imports; fi
            got="$(sort -n "$C" | tr "\n" " ")"; [[ "$got" == "$want" ]] && echo "$k caps ok" || echo "$k caps [$got] want [$want]"; done' _ "$LIB"
    [ "$output" = $'-1 tree failed\n-1 main failed\n0 tree ok\n0 main ok\ntree caps ok\nmain caps ok' ] || { echo "$output $stderr"; return 1; }
}

@test "the parser stops once its work passes IMPORT_WORK_LEFT, below its per-file bound (U2a3c)" {
    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
        out="$(printf "see @abcdefgh.md\n" | IMPORT_WORK_LEFT=1000000 import_targets "")"; w=0; import_work out w
        for l in $((w - 1)) $w; do out="$(printf "see @abcdefgh.md\n" | IMPORT_WORK_LEFT=$l import_targets "")" && echo "$((l - w)) ok" || echo "$((l - w)) failed"; done' _ "$LIB"
    [ "$output" = $'-1 failed\n0 ok' ] || { echo "$output $stderr"; return 1; }
}

@test "main walk reads an untracked start that a main file also imports once, through the checkout (U2a3c; override row 446)" {
    mkdir -p docs && printf 'see @docs/AGENTS.md\n' > CLAUDE.md && commit_all base
    printf 'see @x.md\n' > docs/AGENTS.md
    imps main docs/AGENTS.md docs/x.md docs/other.md
    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
    want walk ok; want docs/AGENTS.md imported; want docs/x.md imported; want docs/other.md -
    # The same path as a checkout symlink: refused at the start, before the import meets it.
    rm docs/AGENTS.md && printf 'see @x.md\n' > docs/real.md && ln -s real.md docs/AGENTS.md
    imps main docs/x.md; want walk failed; want docs/x.md imported
}
```

### Patches for G10 and G11

```diff
--- a/test/scripts/dev-cycle.bats
+++ b/test/scripts/dev-cycle.bats
@@ -1110 +1110 @@
-                 isclosed entry_why isimported inrepo_here main_imports nul_list import_targets instruction_names untracked_md tree_starts md_ls checkout_md main_checkout lower_all capped_read; do
+                 isclosed entry_why isimported inrepo_here main_imports nul_list import_targets instruction_names untracked_md tree_starts md_ls checkout_md main_checkout lower_all capped_read import_work; do
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -69 +69 @@
-    # An untracked start: the tree walk reads it (the main walk fails closed on it until U2a3c).
+    # An untracked start: the tree walk reads it (the main walk's checkout phase does too; the next test pins it).
```

## What NOT to Test

- **M32** (`>=` in emit's bound): a test needs a file whose last charge lands exactly on the cap inside emit(), which depends on the parser's internal charging order. Such a test would be brittle, and the error it would catch is one unit of work in 50,000,000.
- **M03, M07, M28**: equivalent mutants (reasons above). A test cannot tell them apart from HEAD.
- **Timing** of the per-file early stop: T3 and T4 pin the caps by value, which is deterministic. A wall-clock test would be flaky.
- **The `local -; set +u` leak question**: `local -` restores the options on return, and M21 (dropping `set +u`) is killed by 39 tests, so the claim in the comment is already pinned.

## Coverage Gaps Beyond Current Scope

**1.** The symlink arm (`scripts/lib/dev-cycle-read.sh:828-829`) reads a 120000 blob whole, twice, with no cap (fact-check performance escalation). No test feeds a multi-MB link blob. That is a performance critic's call; if the arm moves to `capped_read`, add a test for it then.
**2.** A gate that runs both walks spends up to two IMPORT_WORK_MAX bounds. Nothing pins whether that is intended. This belongs to U2a4/U2b's caller tests.
**3.** `.git/` internals named by imports, such as `.git/info/*.md` and `.git/config`, are now read (security escalation). Tests 22, 40 and 45 pin that a `.git` file is read. No test pins a big pack file named by a prefix candidate being capped. capped_read covers it by construction, and test 33's sparse 300 MB file is the same shape for the tree walk.

## Summary

The highest-value addition is T1, a direct table over `main_checkout`. Six of the function's rules (M14, M16, M18, M19, M20, M23, including the 2->1 change at 80cc6224) survive every current suite, because the walk-level tests reach them only through masks: the prefix candidate naming the link, the read failure, and callers that always pass `local -A`. T2 closes the one survivor that is a fail-open, M13: main's link two levels below a directory the checkout lacks. T3 closes the work bound's arm-level survivors, including M42, the checkout arm going uncharged, which would bring back the N-bounds cost P2 closed. After T1-T5, the only survivors are three equivalent mutants and an untestable one-unit boundary. Open question for the author: whether T3 should replace test 56, which it subsumes.

## Goal-Alignment Note

The goal is to land U2a3c once its review-fix loop is clean. None of these gaps is a defect in HEAD's behavior: every mutant that survives changes code HEAD gets right. They are tests the loop should add so that U2a4 and U2b, which will edit `main_checkout` and the walk, cannot regress it silently. F1 and F2 (T1, T2) are worth adding before merge, because F1's regression would fail open. F3 (T3, T4) protects a performance claim. F4 is two one-line edits. F5 is optional. I found no reason to block the merge beyond adding these tests.
