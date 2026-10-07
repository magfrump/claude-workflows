Commit: 34edec56

# Test Strategy: feat/build-loop-u2a3 (main_imports, isimported main), iteration 2

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 34edec56): `scripts/lib/dev-cycle-read.sh` main_imports (:545-615) and isimported (:621-630); tests in `test/scripts/build-loop-check.bats`.
**Reviewed:** 2026-10-06
**Method:** 49 single-point mutants of main_imports/isimported, run against a scratch copy of the lib and suite (`/tmp/u2a3-ts-i2-cUoH/w`; the worktree's tracked files were not edited). Mutant driver: `/tmp/u2a3-ts-i2-cUoH/tools/mut.py`.

## Test Conventions

- bats (`bats_require_minimum_version 1.5.0`); each test builds a throwaway repo under `$BATS_TEST_TMPDIR` via `test/lib/build-loop-fixtures.bash` (`bl_setup`, `commit_all`).
- `imps WALK PATH...` runs one fresh `bash -c` with `set -euo pipefail`, `resolve_main`, `ROOT_REAL`, then prints `walk: ok|failed` and `PATH: imported|-`; `want PATH WORD` asserts one line. Odd main trees come from `git hash-object -w` + `git mktree` + `git commit-tree` + `git update-ref`.
- Tests that need one shell across several calls (the cache) use a bespoke `run --separate-stderr env LC_ALL=C bash -c '...' _ "$LIB"` and compare `$output` whole (prior art: the "isimported answers imported under if" tests).
- Baseline: all 15 tests pass at 34edec56 (about 6 s).

## Mutation results (baseline suite)

Killed: 37 of 49. Survivors, with what they mean:

| Mutant | Line | Change | Fail-open? | Gap |
|---|---|---|---|---|
| M02 | :549 | cache key ignores `MAIN_SHA` | yes (stale list after main moves) | G6 |
| M03 | :550 | no `IMPORTED_MAIN=error` reset at walk start | yes (a failed walk answered from the last good list on the next call) | G6 |
| M34 | :600 | drop `! -L "$p"` (checkout half of the `..`-after-symlink check) | yes | G5 |
| M42 | :586 | `100644\|100755)` becomes `100644)` | yes (executable instruction file never read) | G1 |
| M49 | :560 | executable `.md` on main not a start | yes | G1 |
| M45 | :571 | `.claude/rules` starts only for main's entries, not untracked | yes | G3 |
| M46 | :603 | link target that is itself a symlink on main not followed | yes | G4 |
| M47 | :612 | tracked regular file routed `t:` (read from the checkout) | yes | G2 |
| M06 | :556 | an unparsable ls-tree record is skipped | yes in principle; unreachable from git's output | What NOT to test |
| M18 | :581 | drop `! -L "$f"` in the directory arm | no: equivalent (blocker `dir` already refuses a symlink `f`) | What NOT to test |
| M40 | :572 | start files not marked seen | no: a start file is read twice at most | What NOT to test |
| M43 | :599 | realpath failure keeps `p` | no practical trigger (`-m` does not fail on missing parts) | What NOT to test |

With the appendix patch applied (6 new tests), every fail-open survivor above is killed: M02, M03 by test G6; M34 by G5; M42, M49 by G1; M45 by G3; M46 by G4; M47 by G2. The four non-fail-open survivors remain by design.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:586 (and :560) — the `100755` arm: an executable instruction file or import on main is read — not covered (every fixture commits mode 100644; mutants M42/M49 survive).
- **G2** — scripts/lib/dev-cycle-read.sh:612 — a tracked *regular-file* import is queued `m:` and read from main's blob, not the checkout — partially covered: test 3 pins this for a start file only, and test 6 only for tracked symlinks; a checkout edit or deletion of a tracked import is not tested (M47 survives).
- **G3** — scripts/lib/dev-cycle-read.sh:565, :571 — an untracked `.claude/rules/*.md` (top-level or nested) starts the walk — not covered (test 6 uses tracked rules; test 7 only uses an untracked rules name to fail the walk; M45 survives). Carried from iteration 1's fact-check escalation (b).
- **G4** — scripts/lib/dev-cycle-read.sh:602-603, :612 — link text naming a path that main also stores as a symlink (a chain) is queued `m:` and followed again — not covered (test 6 has single-hop links only; M46 survives). Carried from iteration 1 escalation (b).
- **G5** — scripts/lib/dev-cycle-read.sh:600 — the `! -L "$p"` half: a `..` after a component that is a symlink only in the checkout fails the walk — not covered (test 15 always has `ld` on main; M34 survives). i2 fact-check escalation.
- **G6** — scripts/lib/dev-cycle-read.sh:549-550 — the cache: a new `MAIN_SHA` re-walks, and a walk that fails before :575 resets `IMPORTED_MAIN` to `error`, so a cached second call does not answer from the previous good list — not covered (every test runs one walk per shell; M02, M03 survive).
- **G7** — scripts/lib/dev-cycle-read.sh:549 — the cache key ignores checkout state: an untracked start file added after a successful walk is unseen by a later call in the same shell — not covered, and the current behavior fails open (probe P1). Needs a contract decision before a test (Escalate).
- **G8** — scripts/lib/dev-cycle-read.sh:596-603 — link text with no `..` through a directory main stores as a symlink, checkout lacking that link (fact-check Q10/Q11) — not covered, and the current behavior fails open (probe P2). Owned by security-reviewer; a test needs the fix first (Escalate).
- **G9** — scripts/lib/dev-cycle-read.sh:549, :551 — the cache key ignores `MAIN_BY_NAME`: after a successful walk, a `resolve_main` that falls back to the current branch at the same SHA still answers `walk: ok`, though the header (:32-34) says main_imports "needs resolve_main to have found main by name, or it fails" — not covered (probe P4). Low: the list is the same commit's.
- **G10** — scripts/lib/dev-cycle-read.sh:586 — a name main stores as both a blob and a tree (`docs` blob + `docs/` tree, B14 candidate): `git cat-file blob main:docs/a.md` fails, so the walk fails closed — not covered (probe P3; also leaks git's `fatal:` line to stderr). Low.

### Evidence, severity, confidence

**G1** — Evidence (lib :586, excerpt of the case in main_imports, which continues to :615 — read):
```
      case "${ent[$f]}" in
        100644|100755) out="$(git cat-file blob "$MAIN_SHA:$f" | import_targets "$d")" || { IMPORTED_MAIN=error; return 1; } ;;
```
Severity: Medium (fail-open if the arm regresses; an executable CLAUDE.md is plausible on a Windows-origin repo). Confidence: high (mutants M42 and M49 survive; the new test kills both). Legibility-target: test name says "executable (100755)".

**G2** — Evidence (lib :612, inside the read loop :607-613 — read whole):
```
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); else queue+=("t:$p"); fi
```
Severity: High (the walk's central promise is "reads the commit, not the working tree"; a checkout edit that removes an import from a tracked file would hide main's import if this regressed). Confidence: high (M47 survives the baseline suite). Legibility-target: test asserts both an edit and a deletion.

**G3** — Evidence (lib :565 and :571):
```
  for f in "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; cand+=("t:$f"); done
    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
```
Severity: Medium. Confidence: high (M45 survives). Legibility-target: one top-level, one nested untracked rule.

**G4** — Evidence (lib :602-603, end of the 120000 arm; flow continues to :612 where `out` is queued):
```
          out="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${d:+$d/}$out" 2>/dev/null)" || out=..
          [[ "$out" != .. && "$out" != ../* ]] || { IMPORTED_MAIN=error; return 1; } ;;
```
Severity: Medium. Confidence: high (M46 survives). Legibility-target: a three-link chain across directories.

**G5** — Evidence (lib :596-601, the per-component loop; excerpt ends :601, the 120000 arm continues to :603 — read):
```
          lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"
          for c in "${parts[@]}"; do
            [[ "$c" != .. || -z "$lk" ]] || { IMPORTED_MAIN=error; return 1; }
            p="$(realpath -ms --relative-to="$ROOT_REAL" -- "$ROOT_REAL/${p:+$p/}$c" 2>/dev/null)" || p=..
            [[ "${ent[$p]:-}" != 120000 && ! -L "$p" ]] || lk=1
          done
```
Severity: High (this is the iteration-1 red's fix; half of it is unpinned). Confidence: high (M34 survives; the new test kills it and passes at HEAD). Legibility-target: test name says "a link only the checkout has".

**G6** — Evidence (lib :549-550):
```
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
  IMPORTED_MAIN=error; IMPORTED_MAIN_DONE="$MAIN_SHA $ROOT_REAL"
```
Severity: Medium now, High once U2a4 calls the walk more than once per shell (M03 yields `isimported main scripts/x.sh` = `-` after a failed walk: a fail-open answer). Confidence: high (both mutants survive the baseline, both killed by the new test). Legibility-target: the test prints a labelled line per step.

**G7** — Evidence: same :549 line as G6. Probe P1 output at 34edec56: `walk1: ok` then, after `printf "Mine: @docs/p.md\n" > CLAUDE.local.md` in the same shell, `docs/p.md: -`. Severity: Medium (no caller yet; fail-open for a long-lived U2a4 caller). Confidence: high (executed). Legibility-target: Escalate (contract first).

**G8** — Evidence: probe P2 at 34edec56 (main: `deep/evil.md` = `evil @secret.md`, `ld -> deep`, `CLAUDE.md -> ld/evil.md`; checkout `rm ld`): `walk: ok`, `deep/secret.md: -`. Severity: High (fail-open), already escalated to security-reviewer by the i2 fact-check (Claims 3, 19). Confidence: high (executed). Legibility-target: Escalate.

**G9** — Evidence: probe P4: `walk1: ok`, then `git checkout -b trunk && git branch -D main; resolve_main` gives `by_name=[]`, then `walk2: ok`. Severity: Low. Confidence: high (executed). Legibility-target: either key the cache on `MAIN_BY_NAME` or reword :32-34.

**G10** — Evidence: probe P3: `git ls-tree -r main` lists both `docs` and `docs/a.md`; walk `failed`, `docs/deep.md: imported`, stderr `fatal: path 'docs/a.md' does not exist in '8491fee4...'`. Severity: Low (fails closed). Confidence: high. Legibility-target: optional test.

## Recommended Tests

All six are in the appendix patch, checked in scratch: 21/21 pass at 34edec56, and each kills its target mutant.

#### main walk reads an executable (100755) instruction file and import on main
**Closes gaps:** G1 · **Type:** integration · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**What it verifies:** a 100755 start file and a 100755 import are both read from main.
**Key cases:** `chmod +x CLAUDE.md docs/a.md`, commit; assert `git ls-tree` mode 100755; `docs/a.md`, `docs/b.md` imported, `docs/other.md -`.
**Setup needed:** none.

#### main walk reads a tracked import from main, not its working-tree edit or deletion
**Closes gaps:** G2 · **Type:** integration · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**Key cases:** `CLAUDE.md` imports `docs/a.md` which imports `b.md`; overwrite `docs/a.md` in the checkout: `docs/b.md` imported; `rm docs/a.md`: still imported.

#### main walk starts at the checkout's untracked .claude/rules files, top-level and nested
**Closes gaps:** G3 · **Type:** integration · **Priority:** medium · **File:** test/scripts/build-loop-check.bats
**Key cases:** untracked `.claude/rules/mine.md` (`@../../docs/r.md`) and `pkg/.claude/rules/x.md` (`@../../n.md`): `docs/r.md`, `pkg/n.md` imported; `docs/other.md -`.

#### main walk follows a chain of symlinks on main to the file at its end
**Closes gaps:** G4 · **Type:** integration · **Priority:** medium · **File:** test/scripts/build-loop-check.bats
**Key cases:** `CLAUDE.md -> a.md`, `a.md -> docs/l2.md`, `docs/l2.md -> real.md`, `docs/real.md` imports `deep.md`: every hop and `docs/deep.md` imported.

#### main walk fails on symlink text with a .. after a link only the checkout has
**Closes gaps:** G5 · **Type:** integration · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**Key cases:** main `CLAUDE.md -> ld/../evil.md`, no `ld` on main: walk ok, `deep/secret.md -`; untracked `ln -s deep/inner ld`: walk failed, `deep/secret.md` imported.

#### main walk's cache: a new main commit is walked again, and a failed walk is not answered from the last good list
**Closes gaps:** G6 · **Type:** integration · **Priority:** high · **File:** test/scripts/build-loop-check.bats
**Key cases (one shell):** walk 1 ok, `docs/b.md -`; commit an import of `docs/b.md`, `resolve_main`: walk 2 ok, `docs/b.md` imported; move main to a tree listing `AGENTS.md` twice, `resolve_main`: walk 3 failed, `scripts/x.sh` imported.

#### Pending tests (not in the patch; need a fix or decision first)
- **G7**: in one shell, walk, then add `CLAUDE.local.md` importing `docs/p.md`; want `docs/p.md` imported. Fails at HEAD (P1). Lands with whatever U2a4 picks: re-walk per call, put checkout state in the key, or document "one walk per process" and test that the floor runs in a fresh shell.
- **G8**: probe P2's shape, want `walk failed`. Fails at HEAD. Lands with the security fix.
- **G9** (low): after a by-name walk, delete main and `resolve_main` to the current branch; want `walk failed` per the header contract, or reword the header.

## What NOT to Test

- **M06 (:556, record regex)**: `git ls-tree -r -z` always emits records that match; a test would need a fake git. Defensive code; leave it.
- **M18 (:581, `! -L "$f"`)**: equivalent mutant. `blocker "$f" dir` already refuses a symlink `f` (plaindir compares realpath to `ROOT_REAL/$f`). A test cannot tell them apart.
- **M40 (:572, start files marked seen)**: only stops a second read of a start file. Not observable, not fail-open.
- **M43 (:599, realpath failure)**: `realpath -m` does not fail on missing components. No hermetic trigger.
- **Parser shapes from B14** (`&#64;`, `[`/`]` in a token, backslash-escaped spaces): these belong to `import_targets`, which changes in U2a3b (stacked). Test them there.
- **`.claude/commands/`, `.claude/agents/`, non-.md files under `.claude/rules/` (B14)**: whether Claude Code loads them as instructions is a product question, not a test gap. Route it to security-reviewer / known issue A5.

## Coverage Gaps Beyond Current Scope

**1.** Failure-path tests (tests 4, 9, 10, 12) never assert stderr. P3 shows a failed walk leaks git's `fatal:` line. Whether the U2a4 caller scrubs or suppresses walk stderr should be tested in U2a4.
**2.** D8 (untracked nested repo / submodule start files) is now documented as not covered. No test pins the documented behavior (walk ok, nested start ignored), so a future fix or regression would go unnoticed. Low.

## Summary

The highest-value additions are G5 (the checkout half of the iteration-1 red's `..`-after-symlink fix is unpinned, mutant M34 survives) and G2 (nothing pins that a tracked import is read from main rather than the checkout, mutant M47 survives). G6 pins the cache, which matters as soon as U2a4 calls the walk more than once per shell. The appendix patch adds six tests. All 21 tests pass at 34edec56, and the patch kills all eight fail-open survivors. Two fail-open behaviors remain at HEAD and need code, not tests: G7 (the cache ignores untracked start files added later; probe P1) and G8 (fact-check Q10/Q11; probe P2). Open question: the cache contract for U2a4's caller (G7, G9).

## Appendix: checked patch

Checked on 2026-10-06. `git -C /workspace/.claude/wt-build-loop-u2a3 apply --check` succeeds. In the scratch copy, `TMPDIR=<scratch> bats test/scripts/build-loop-check.bats` passes 21/21 at 34edec56. Re-running mutants M02, M03, M34, M42, M45, M46, M47 and M49 with the patch kills all of them, by tests 21, 21, 20, 16, 18, 19, 17 and 16. Copy: `/tmp/u2a3-ts-i2-cUoH/g.patch`.

```diff
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -278,3 +278,76 @@
     rm CLAUDE.md && commit_all no-ld
     imps main hid.md docs/n.md deep/secret.md; want walk ok; want hid.md imported; want docs/n.md imported; want deep/secret.md -
 }
+
+@test "main walk reads an executable (100755) instruction file and import on main (U2a3 i2 test-strategy G1)" {
+    mkdir -p docs
+    printf 'Rules: @docs/a.md\n' > CLAUDE.md && printf 'More: @b.md\n' > docs/a.md
+    chmod +x CLAUDE.md docs/a.md
+    commit_all exec
+    [ "$(git ls-tree main CLAUDE.md | cut -c1-6)" = 100755 ]
+    imps main docs/a.md docs/b.md docs/other.md
+    want walk ok; want docs/a.md imported; want docs/b.md imported; want docs/other.md -
+}
+
+@test "main walk reads a tracked import from main, not its working-tree edit or deletion (U2a3 i2 test-strategy G2)" {
+    mkdir -p docs
+    printf 'Rules: @docs/a.md\n' > CLAUDE.md && printf 'More: @b.md\n' > docs/a.md
+    commit_all tracked-import
+    printf 'nothing here\n' > docs/a.md
+    imps main docs/b.md; want walk ok; want docs/b.md imported
+    rm docs/a.md
+    imps main docs/b.md; want walk ok; want docs/b.md imported
+}
+
+@test "main walk starts at the checkout's untracked .claude/rules files, top-level and nested (U2a3 i2 test-strategy G3)" {
+    mkdir -p docs .claude/rules pkg/.claude/rules
+    printf 'r\n' > docs/r.md && commit_all base
+    printf 'Mine: @../../docs/r.md\n' > .claude/rules/mine.md
+    printf 'Nested: @../../n.md\n' > pkg/.claude/rules/x.md
+    imps main docs/r.md pkg/n.md docs/other.md
+    want walk ok; want docs/r.md imported; want pkg/n.md imported; want docs/other.md -
+}
+
+@test "main walk follows a chain of symlinks on main to the file at its end (U2a3 i2 test-strategy G4)" {
+    mkdir -p docs
+    printf 'see @deep.md\n' > docs/real.md
+    ln -s a.md CLAUDE.md && ln -s docs/l2.md a.md && ln -s real.md docs/l2.md
+    commit_all chain
+    imps main a.md docs/l2.md docs/real.md docs/deep.md docs/other.md
+    want walk ok
+    for p in a.md docs/l2.md docs/real.md docs/deep.md; do want "$p" imported; done
+    want docs/other.md -
+}
+
+@test "main walk fails on symlink text with a .. after a link only the checkout has (U2a3 i2 test-strategy G5)" {
+    mkdir -p deep/inner
+    printf 'evil @secret.md\n' > deep/evil.md && printf 'top\n' > evil.md
+    ln -s ld/../evil.md CLAUDE.md
+    commit_all checkout-link
+    imps main deep/secret.md; want walk ok; want deep/secret.md -
+    # An untracked directory link: the kernel reads deep/evil.md through it.
+    ln -s deep/inner ld
+    imps main deep/secret.md; want walk failed; want deep/secret.md imported
+}
+
+@test "main walk's cache: a new main commit is walked again, and a failed walk is not answered from the last good list (U2a3 i2 test-strategy G6)" {
+    mkdir -p docs
+    printf 'Rules: @docs/a.md\n' > CLAUDE.md && commit_all one
+    run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
+        main_imports && echo "walk1: ok"
+        if isimported main docs/b.md; then echo "1 docs/b.md: imported"; else echo "1 docs/b.md: -"; fi
+        printf "Rules: @docs/b.md\n" > CLAUDE.md && git add CLAUDE.md && git commit -qm two && resolve_main
+        main_imports && echo "walk2: ok"
+        if isimported main docs/b.md; then echo "2 docs/b.md: imported"; else echo "2 docs/b.md: -"; fi
+        a="$(printf "x\n" | git hash-object -w --stdin)"
+        t="$(printf "100644 blob %s\tAGENTS.md\n100644 blob %s\tAGENTS.md\n" "$a" "$a" | git mktree)"
+        git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m dup)" && resolve_main
+        main_imports || echo "walk3: failed"
+        if isimported main scripts/x.sh; then echo "3 scripts/x.sh: imported"; else echo "3 scripts/x.sh: -"; fi' _ "$LIB"
+    [ "$status" -eq 0 ] && [ "$output" = "walk1: ok
+1 docs/b.md: -
+walk2: ok
+2 docs/b.md: imported
+walk3: failed
+3 scripts/x.sh: imported" ] || { echo "$output $stderr"; return 1; }
+}
```

## Goal-Alignment Note

- **Success criterion (verbatim):** A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-build-loop-u2a3.md naming each gap with a concrete test case, and an appendix with a checked patch (run it against the suite in your scratch copy; do not edit the worktree's tracked files).
- **Answered:** Yes. The report names gaps G1-G10, each with Evidence, Severity, Confidence and Legibility-target. G1-G6 have concrete tests in a checked patch (21/21 pass, eight fail-open mutants killed). G7-G9 have pending test cases that wait on a fix or decision. G10 is low and optional. The fact-check's test-strategy escalations are covered: the unpinned `-L` half is G5, and iteration-1's untracked rules start, symlink chain and cache are G3, G4 and G6. No tracked worktree file was edited; this report is the only file written.
- **Out of scope:** the parser shapes (`&#64;`, `[`/`]`, `\ `), which are U2a3b's import_targets. Whether Claude Code loads `.claude/commands/`, `.claude/agents/` or non-.md rule files, which is a product question.
- **Escalate:** G7 (cache ignores checkout state, fail-open, probe P1) to architecture-review/security-reviewer and the U2a4 design. G8 (Q10/Q11 fail-open, probe P2) to security-reviewer. G9 (cache ignores MAIN_BY_NAME, which contradicts the header at :32-34) to code-fact-check/architecture.
