Commit: 1898d21c

# Test Strategy: feat/build-loop-u2a3 (loop 2, final confirming pass, ts2f)

**Scope:** `git diff main...HEAD` (base 62d366a7): `scripts/lib/dev-cycle-read.sh` (`nul_list` :516-517, `main_imports` :546-611, `isimported main` :612-626), `test/scripts/build-loop-check.bats` (16 tests), `test/scripts/dev-cycle.bats`.
**Reviewed:** 2026-10-06
**Method:** single-point mutants of a scratch copy (`git archive 1898d21c`) in `/tmp/u2a3-ts2f-i2-uWJq/` (driver `mut.sh`; `copy/` = HEAD, `p/` = patched, `m-*` = mutants, `g/` = the G5 probe). The worktree's tracked files were not edited.

## Test Conventions

Bats 1.5+, one throwaway repo per test (`test/lib/build-loop-fixtures.bash`: `bl_setup`, `commit_all`). Main-walk tests call `imps main PATH...` and assert with `want walk ok|failed` and `want PATH imported|-`. Shapes git cannot check out are built with `git hash-object -w`, `git mktree`, `git commit-tree` and `git update-ref refs/heads/main`. Failure injection uses a PATH-shimmed binary, `ulimit -f 0`, or a deleted object file. The unit is at 400 of 400 changed code lines, so the patch appends to existing lines and adds no net lines.

Baseline: 16/16 at 1898d21c.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:557 — `return 1` when a name in main's tree holds a newline — not covered. Test 5's newline case (bats :101-110) is masked: the checkout index still holds `CLAUDE.md`, which the rebuilt main lacks, so :570 fails the walk first, as an index-only start.
- **G2** — scripts/lib/dev-cycle-read.sh:583 — the NUL count on symlink text (`[[ "$i" -ne 0 ]]`) — not covered. Test 9's last case (bats :196-200) is masked by the same stale `CLAUDE.md` in the index.
- **G3** — scripts/lib/dev-cycle-read.sh:586 — `-z "$out"` (empty symlink text) — not covered. Test 12's empty-link case (bats :250-254) is masked by the same stale index entry.
- **G4** — scripts/lib/dev-cycle-read.sh:597 — `160000) continue`, which skips a gitlink at a start name — not covered. The only gitlink fixture (test 12, :256-257) is a parent directory, and that case exercises :607, not :597.
- **G5** — scripts/lib/dev-cycle-read.sh:554-560 (the doubled-name check at :557) — a name main stores as both a tree and a symlink, with the tree listed first, passes the walk — not covered, and the code fails open here (fact-check r3 13b). This needs a lib fix before the test can land.
- **G6** — scripts/lib/dev-cycle-read.sh:562 — `return 1` when `git ls-files --cached` fails — not covered. Test 10's corrupt index fails `untracked_md` (:561) first.
- **G7** — scripts/lib/dev-cycle-read.sh:598 — the `*)` record-type arm — not covered, and it cannot be reached (see What NOT to Test).

## Findings

### G1, G2, G3 — three refusals masked by the stale index (fact-check r1 24-26, r2 23)

- **Location:** lib :557 (newline in a tree name), :583 (NUL in link text), :586 (empty link text); bats :95 and :101-110 (test 5), :199-200 (test 9), :253-254 (test 12).
- **Evidence:** Each mutant was run against the original tests, and each passed 16/16 (it survived):
  - `m-M1-newline`: :557 reduced to `[[ -z "${ent[$f]+set}" ]] || return 1`.
  - `m-M2-nul`: :583 `[[ "$i" -ne 0 ]]` → `[[ "$i" -lt 0 ]]`, so the check never fires. My first version of this mutant, `-ne -1`, fired on every link and was killed by tests 6 and 15. It is not a valid probe.
  - `m-M3-empty`: :586 with `-z "$out" ||` dropped.

  In all three tests the fixture rebuilds main with `update-ref` but leaves the checkout's `CLAUDE.md` in both the index and the working tree. Because dfeeb85d added the index listing (:562-563), that file becomes a `t:` start candidate, and :570 fails the walk before the refusal under test runs. The fix appends `; git rm -qf CLAUDE.md` to each `update-ref` line, which removes the file from the index and the working tree.

  `git read-tree main` would not work for test 5: it would put the newline-holding names into the index, and then :563's newline check on the index list would mask :557 instead. `git rm -qf` works in all three tests.

  With the patch applied, each mutant is killed by exactly the test that names it: `m-P1-newline` → test 5, `m-P2-nul` → test 9, `m-P3-empty` → test 12. `m-P6-dup`, which drops the doubled-name half of :557, is still killed by test 5.
- **Severity:** Medium. All three refusals are fail-closed checks that are documented in the header (:458-460) and the return-1 comment. A regression in any of them would make the walk pass silently while the suite stays green. In G1, the newline name is shaped as a forged symlink record, so the mutant answers `docs/d.md: -` (fail-open). In G2, the mutant follows `docs/rules.mdzzz` (fail-open).
- **Confidence:** High (mutants executed before and after the patch).
- **Legibility-target:** Each fixture's comment ("Symlink text holding a NUL", "Empty symlink text", "A name holding a newline") becomes true of the check it names. The appended `# no index-only start masks ...` comment says why the `rm` is there.

### G4 — a gitlink at a start name is skipped, unpinned

- **Location:** lib :597; bats :257 (test 12).
- **Evidence:** `m-M4-gitlink` (`160000)` → `1600000)`, so a gitlink falls to the `*)` failure arm) passes 16/16 on the original tests. The patch appends a case to :257: main stores `CLAUDE.md` as `160000 commit` and `AGENTS.md` importing `@docs/x.md`, and the test expects `walk ok` and `docs/x.md imported`. `m-P4-gitlink` is then killed by test 12.
- **Severity:** Low. The mutant fails closed, so nothing opens. The pin keeps the documented contract ("a gitlink: its files are not main's") and stops a future edit from turning every superproject that has a gitlink named like an instruction file into a permanent gate refusal.
- **Confidence:** High.
- **Legibility-target:** test 12's title gains "a gitlink at a start name is skipped".

### G5 — tree-and-symlink doubled name, tree first: the walk fails open (escalated to security + author)

- **Location:** lib :554-560 (the doubled-name check at :557 compares full paths, so `l/x.md` and `l` never collide). Override row :379 probed only the blob-first order.
- **Evidence:** I reproduced r3 13b at 1898d21c. A literal tree (`git hash-object -t tree --literally`) lists `CLAUDE.md` (`see @l/x.md`), `docs/` (x.md = `@secret.md`), `l/` (x.md = `plain`) and `120000 l` → `docs`, in that order. After `git checkout -f main`, the checkout holds `l -> docs`, so Claude Code reads `docs/x.md` and imports `docs/secret.md`. The walk reads `main:l/x.md` (the tree's blob) and answers `walk ok`, `docs/secret.md: -`.

  The proposed test below (scratch `g/test/scripts/g-probe.bats`) fails at HEAD with exactly that output. It passes, along with 16/16 of the patched suite, once a candidate fix is applied in scratch. The fix appends to :560's `done`:

  `; for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${ent[$c]+set}" ]] || return 1; done; done`

  It refuses any listed name that is also a listed parent, and adds zero net lines.
- **Severity:** Medium for the test gap. The underlying code defect is the security reviewer's call: it needs a non-canonical tree that `git fsck` flags (duplicateEntries), and it is not a regression (the same at cc1aa864).
- **Confidence:** High (probe executed, and the fix was checked in scratch).
- **Legibility-target:** test 5's title ("a name the tree lists twice") would cover it as a third case. The case is not in the patch, because it fails until the lib is fixed.
- **Proposed test** (to append to test 5's last line once the lib is fixed; `x` turns a hex id into printf escapes):
  ```bash
  x() { printf '%s' "$1" | sed 's/../\\x&/g'; }
  c="$(printf 'see @l/x.md\n' | git hash-object -w --stdin)"; k="$(printf docs | git hash-object -w --stdin)"
  lt="$(printf '100644 blob %s\tx.md\n' "$(printf 'plain\n' | git hash-object -w --stdin)" | git mktree)"
  dt="$(printf '100644 blob %s\tx.md\n' "$(printf '@secret.md\n' | git hash-object -w --stdin)" | git mktree)"
  t="$(printf "100644 CLAUDE.md\0$(x "$c")40000 docs\0$(x "$dt")40000 l\0$(x "$lt")120000 l\0$(x "$k")" | git hash-object -t tree -w --literally --stdin)"
  git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m tree-and-link)"; git checkout -qf main
  imps main docs/secret.md; want walk failed; want docs/secret.md imported
  ```
  In test 5 it would need `git rm -qf`-style cleanup of the earlier fixtures' state. As written it runs in a fresh repo.

### G6 — `ls-files --cached` failure (:562), unpinned in isolation

- **Location:** lib :562; bats :216 (test 10).
- **Evidence:** `m-Q7-idxlist` (:562 `|| return 1` → `|| true`) passes 16/16 on the original tests. Test 10's corrupt index fails `ls-files --others` at :561 first. The patch appends to :216 a PATH shim `git` that exits 1 only when its arguments include `--cached` and otherwise execs the real git. The case expects `walk failed`, and the shim is removed afterwards. `m-R7-idxlist` is then killed by test 10. Without the check, a failing index listing would drop every index-only start, and the walk would pass.
- **Severity:** Low. Making `ls-files --cached` fail while `--others` succeeds takes an odd failure.
- **Confidence:** High.
- **Legibility-target:** the appended comment `# and a git whose ls-files --cached fails`.

## Recommended Tests

#### Unmask tests 5, 9, 12 (`git rm -qf CLAUDE.md` after the rebuild)
**Closes gaps:** G1, G2, G3 · **Type:** integration (bats) · **Priority:** high · **File:** test/scripts/build-loop-check.bats :95, :199, :253
**What it verifies:** each refusal fails the walk on its own, with no index-only start present.
**Key cases:**
- A tree name `we\nird/AGENTS.md` (forged record) → `walk failed`, `docs/d.md imported`.
- Link text `docs/rules.md\0zzz` → `walk failed`, `docs/rules.md imported`.
- Empty link text at `sub/AGENTS.md` → `walk failed`.
**Setup needed:** none beyond the appended `git rm -qf`.

#### Gitlink at a start name
**Closes gaps:** G4 · **Type:** integration · **Priority:** medium · **File:** bats :257
**Key cases:** `160000 commit` at `CLAUDE.md` plus `AGENTS.md` → `@docs/x.md` → `walk ok`, `docs/x.md imported`.

#### `ls-files --cached` failure
**Closes gaps:** G6 · **Type:** integration (PATH shim) · **Priority:** low · **File:** bats :216
**Key cases:** a git that fails only on `--cached` → `walk failed`, status 0.

#### Tree-and-symlink doubled name (after the lib fix)
**Closes gaps:** G5 · **Type:** integration · **Priority:** medium, blocked on the lib fix · **File:** bats test 5
**Key cases:** see the G5 block → `walk failed`, `docs/secret.md imported`.

## What NOT to Test

- **G7, lib :598 `*)`:** it cannot be reached. `ls-tree` canonicalizes modes, the :555 regex accepts only 6 octal digits, and git emits only 100644/100755/120000/160000 for `-r` leaves. `m-P8-star` (`*) ;;`) survives because no input can reach it. Pinning it would need a fake `git` that prints a forged record, which costs more than the check is worth.
- **lib :597 fall-through (`160000) ;;` without `continue`):** `m-P7-glfall` survives. It is equivalent: `out` replays the previous file's imports, which are already in `seen`, so nothing observable changes.
- **lib :608 `! -L "$p"` in the plain-directory arm:** `m-Q8-root` survives. It is equivalent, because `blocker "$p" dir` → `plaindir` already refuses a symlink at `p`.

Mutants confirmed killed by the existing tests: :607 gitlink parent (`m-M5`, test 12), :608 blocker (`Q1`, 12), :563 index or untracked newline (`Q2`, 7), :566 short list (`Q3`, 10), :570 start main lacks (`Q4`, 3/9/11), :593 checkout link (`Q5`, 15), :586 absolute link (`Q6`, 7).

## Coverage Gaps Beyond Current Scope

**1.** U2a3b's parser and the sed/grep fail-closed changes are stacked above this unit and are not reviewed here.
**2.** U2a3c's checkout phase: until it lands, every checkout-input test asserts `walk failed`, and each will need re-pinning.

## Summary

The highest-value change is the three appended `git rm -qf CLAUDE.md`. They unmask the newline, NUL and empty-link refusals that dfeeb85d's index listing hid, and each single-point mutant is then killed by its own test (5, 9, 12). The patch also pins the gitlink-at-start arm (G4) and the `ls-files --cached` failure (G6), with zero net lines (6 lines changed, 315 lines before and after) and 16/16 passing. The main residual risk is G5: a tree-and-symlink doubled name with the tree first fails open at HEAD. It needs a lib fix (a candidate was checked in scratch) before its test can land.

## Appendix: checked patch (zero net lines; test/scripts/build-loop-check.bats)

```diff
@@ -95 +95 @@
-    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"
+    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup-start)"; git rm -qf CLAUDE.md  # no index-only start masks the refusals below
@@ -199 +199 @@
-    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"
+    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m nul-link)"; git rm -qf CLAUDE.md  # no index-only start masks the NUL count
@@ -216 +216 @@
-    PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed
+    PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/tr" && printf '#!/bin/sh\ncase " $* " in *" --cached "*) exit 1;; esac\nexec %s "$@"\n' "$(command -v git)" > "$BATS_TEST_TMPDIR/bin/git" && chmod +x "$BATS_TEST_TMPDIR/bin/git"; PATH="$BATS_TEST_TMPDIR/bin:$PATH" imps main docs/b.md; [ "$status" -eq 0 ] || return 1; want walk failed; rm "$BATS_TEST_TMPDIR/bin/git"  # and a git whose ls-files --cached fails
@@ -240 +240 @@
-@test "main walk fails on a dangling checkout link at a target, a directory under a checkout link, empty link text below the top level, and a path under a gitlink (U2a3)" {
+@test "main walk fails on a dangling checkout link at a target, a directory under a checkout link, empty link text below the top level, and a path under a gitlink; a gitlink at a start name is skipped (U2a3)" {
@@ -253 +253 @@
-    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"
+    git update-ref refs/heads/main "$(git commit-tree "$(printf '040000 tree %s\tsub\n' "$s" | git mktree)" -p main -m empty-link)"; git rm -qf CLAUDE.md  # no index-only start masks the empty-text check
@@ -257 +257 @@
-    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink)"; imps main docs/x.md; want walk failed; want docs/x.md imported
+    git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink)"; imps main docs/x.md; want walk failed; want docs/x.md imported; t="$(printf '160000 commit %s\tCLAUDE.md\n100644 blob %s\tAGENTS.md\n' "$(git rev-parse main)" "$(printf 'see @docs/x.md\n' | git hash-object -w --stdin)" | git mktree)"; git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m gitlink-start)"; imps main docs/x.md; want walk ok; want docs/x.md imported
```

The full unified diff is at `/tmp/u2a3-ts2f-i2-uWJq/patch.diff`. `git diff --no-index --numstat` reports 6 insertions and 6 deletions, and the file has 315 lines before and after.

**Check runs** (`TMPDIR` under the scratch dir; bats on the scratch copy):

| Run | Lib | Tests | Result |
|---|---|---|---|
| baseline | HEAD | original | 16/16 |
| M1 :557 newline dropped | mutant | original | 16/16 (survives) |
| M2 :583 NUL count never fires | mutant | original | 16/16 (survives) |
| M3 :586 `-z` dropped | mutant | original | 16/16 (survives) |
| M4 :597 gitlink arm removed | mutant | original | 16/16 (survives) |
| Q7 :562 `|| true` | mutant | original | 16/16 (survives) |
| patched | HEAD | patched | 16/16 |
| F1 / F2 / F3 / F4 | M1 / M2 / M3 / M4 | patched | killed by 5 / 9 / 12 / 12 |
| R7 | Q7 | patched | killed by 10 |
| P6 :557 dup half dropped | mutant | patched | killed by 5 |
| G5 probe | HEAD | g-probe.bats | fails (`walk: ok`, `docs/secret.md: -`) |
| G5 probe + 16 | candidate fix | g-probe + patched | 17/17 |

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-L2f-build-loop-u2a3.md naming each gap with a concrete test case, with a checked patch in an appendix (run in your scratch copy; do not edit the worktree's tracked files) that adds no net lines to test/scripts/build-loop-check.bats."
- **Answered:** G1-G7 are named. G1-G3 (the priority) are unmasked by `git rm -qf CLAUDE.md`, and each single-point mutant is then killed. G4 (the gitlink arm) and G6 are pinned. The patch nets zero lines and passes 16/16. G5 has a concrete test that is blocked on a lib fix, and a candidate fix was checked in scratch. G7 and two equivalent mutants are in What NOT to Test.
- **Out of scope:** U2a3b's parser and fail-closed changes; U2a3c's checkout phase; the doc-wording items the fact-check routed to the author (A5, the return-1 comment, the header, nul_list, the U2b bullet, test 9's name).
- **Escalate:** G5 to security + author. A tree-and-symlink doubled name with the tree listed first fails open (lib :557; override row :379 covered only the blob-first order). The fix is the zero-net-line append at :560 shown above, and the proposed test pins it.
