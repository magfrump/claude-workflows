Commit: cc1aa864

# Test Strategy: feat/build-loop-u2a3 (main_imports, isimported main), final confirming pass

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD cc1aa864): `scripts/lib/dev-cycle-read.sh` nul_list (:520), main_imports (:549-618), isimported main (:629); tests in `test/scripts/build-loop-check.bats` (16 tests) and the dev-cycle.bats sourcing check.
**Reviewed:** 2026-10-06 (role ts, pass i3)
**Method:** 46 single-point mutants of nul_list/main_imports/isimported, run against a scratch copy of the lib and suite (`/tmp/u2a3-ts-i3-plEO/w`; driver `/tmp/u2a3-ts-i3-plEO/tools/mut.py`, results `mut1.txt`), plus four behavioural probes (`tools/probe.sh`) for the fact-check's Incorrect rows. The worktree's tracked files were not edited.

## Test Conventions

- bats >= 1.5.0; each test builds a throwaway repo under `$BATS_TEST_TMPDIR` (`test/lib/build-loop-fixtures.bash`: `bl_setup`, `commit_all`).
- `imps WALK PATH...` runs one `bash -c` (`set -euo pipefail`, `resolve_main`, `ROOT_REAL`) printing `walk: ok|failed` and then `PATH: imported|-` from `isimported`, which hits main_imports' cache in the same shell; `want PATH WORD` asserts one line. Odd trees come from `git hash-object -w` / `git mktree` / `git commit-tree` / `git update-ref`. Cache tests use a bespoke `run ... bash -c` (test 16).
- Baseline at cc1aa864: 16/16 pass (about 5 s).

## Mutation results (baseline suite)

Killed 37 of 46 (N01-N46; N46 run by hand since it edits both copies of the cache key). Survivors:

| Mutant | Line | Change | Fail-open? | Disposition |
|---|---|---|---|---|
| N33 | :614 | parent-link loop checks only the immediate parent | yes | G1 |
| N37 | :614 | loop stops at `c > 1` (misses a one-letter link name) | yes | G1 |
| N34 | :614 | parent-link refusal returns 1 without `IMPORTED_MAIN=error` | yes (the cached partial list answers the next `isimported main`) | G2 |
| N03 | :554 | cache key written without MAIN_BY_NAME (read side unchanged) | no: the key never matches, so the cache is disabled (fails slow, not open). The consistent mutant N46 (both sides) is killed by test 16 | What NOT to test |
| N06 | :556 | ls-tree `nul_list` failure ignored | no: equivalent, the leftover `rc=1` marker fails the record regex at :558 | What NOT to test |
| N10 | :520 | nul_list accepts an empty listing | no practical trigger (the `printf rc=` always writes) | What NOT to test |
| N17 | :572 | start files not pre-marked seen | no: fails *safer* (it closes G3) | see G3 |
| N39/N40 | :599, :601 | realpath failure keeps `p` / `out` | no practical trigger (`-m` does not fail on missing parts) | What NOT to test |
| N45 | :558 | an unparsable ls-tree record is skipped | unreachable from git's own output | What NOT to test |

With the Appendix A patch (3 changed lines, 3 added, all inside test 15), N33, N34 and N37 are killed by test 15, and the 16 tests still pass. That leaves no fail-open survivor among the mutants.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:614 — the parent-link loop's refusal for a link that is *not* the import's immediate parent (`@l/inner/i.md` with main storing `l` as a link), and for a one-letter link name (the `c = 1` iteration) — not covered (test 15 uses only `@ld/i.md`, the immediate parent, two letters; N33 and N37 survive).
- **G2** — scripts/lib/dev-cycle-read.sh:614 (flow into :553 and :629) — the `IMPORTED_MAIN=error` half of the parent-link refusal: after the refusal, a later `isimported main` in the same shell must answer imported — partially covered: test 15's loop asserts `walk failed` but never asks a path (N34 survives).
- **G3** — scripts/lib/dev-cycle-read.sh:572 with :610-614 — an *untracked start file* at a path main lacks under a directory main stores as a link: it is pre-marked seen at :572, so when an import reaches it, :610 skips it before the parent-link check at :614 runs, and the walk succeeds where main alone fails — not covered, and the code fails open here (probe P1; fact-check r2 Claims 13, 18, 27). Needs the implementer's fix first.
- **G4** — scripts/lib/dev-cycle-read.sh:517, :564, :579-583 — a checkout directory the walk cannot search: an import main lacks under a mode-000 directory reads as absent (`else continue` at :583), and `git ls-files --others` exits 0 with only a warning, so an untracked start inside it is not listed, while nul_list sees rc=0 — not covered, and the walk answers ok (probes P2, P3; fact-check r2 Claim 19b). Needs a contract decision first.
- **G5** — scripts/lib/dev-cycle-read.sh:596 — the remaining `<<<"$out"` here-string (link-text split) losing its input when the temp-file write fails — not covered; cannot be built through a real symlink (link text >= 64 KiB exceeds PATH_MAX). See What NOT to Test.
- **G6** — test/scripts/build-loop-check.bats:183-184 — test 9's first sub-case is commented as the checkout-symlink refusal but now trips the parent-link refusal at :614 first (fact-check informational). The checkout-symlink arm is still covered: test 12 kills N19 and N21. Legibility only.

### Evidence, severity, confidence

**G1** — Evidence (lib :614, the whole line; it sits inside the import-read loop :607-616, read whole):
```
      for (( c = ${#p}; c > 0; c-- )); do [[ "${p:c:1}" != / || "${ent[${p:0:c}]:-}" != 120000 ]] || { IMPORTED_MAIN=error; return 1; }; done
```
Mutants N33 (stops at the first `/` from the right) and N37 (`c > 1`) both survive the baseline suite. Probe P4 confirms that the real code fails `@l/inner/i.md` when main stores `l -> deep` and the checkout lacks `l`. Severity: Medium (if this regresses, the e7b5d7ed fix fails open for every import nested deeper than one level under a link). Confidence: high (both mutants survive the baseline and are killed by the patch). Legibility-target: a comment in test 15 naming "two levels below a one-letter link".

**G2** — Evidence: as G1. With N34, `imps` prints `walk: failed`, but the cache at :553 then returns 0 for the partial `IMPORTED_MAIN`, so `isimported main deep/inner/i.md` answers `-`. Test 15's loop line `imps main deep/inner/i.md; want walk failed` never reads the path line. Severity: Medium (the fail-open is on the cached path, which is exactly how U2a4's floor will call it: one walk, many `isimported`). Confidence: high (N34 survives the baseline and is killed by the patch). Legibility-target: `want deep/inner/i.md imported` beside every `want walk failed` in test 15.

**G3** — Evidence (lib :570-573 and :608-614; excerpt from the start loop, which ends :573, and the read loop, which continues to :616 — both read whole):
```
    if [[ "${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md ]]; then
      seen[${cand[i]:2}]=1; queue+=("${cand[i]}")
...
      [[ -z "${seen[$p]+set}" ]] || continue
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("m:$p"); continue; fi
      # Main lacks p: under a directory link main stores (the checkout may lack it), fail.
      for (( c = ${#p}; c > 0; c-- )); do ...
```
Probe P1 (and Appendix B test 1): main has `ld -> deep` and `CLAUDE.md` = `see @ld/CLAUDE.md`. Main alone gives `walk: failed`. A checkout where `ld` is a plain directory holding an untracked `ld/CLAUDE.md` gives `walk: ok`, `x.sh: -`. With mutant N17 (no pre-mark), the same test passes. That shows one fix shape and confirms the test exercises the right line. This contradicts the header's (:32-34) "which can only add imports or fail it". Severity: Medium (the exposure is limited to start-shaped names under a link that the checkout has replaced with a plain directory holding an *untracked* file; a branch that tracks the file there is not a start). Confidence: high (executed). Legibility-target: test name says "as main alone does".

**G4** — Evidence (lib :579-583, the `t:` arm; excerpt ends :583, and main_imports continues to :618 — read):
```
      if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }
      elif [[ -d "$f" && ! -L "$f" && -z "$(blocker "$f" dir)" ]]; then continue  # a directory: nothing loads
      elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
      else continue; fi
```
Probe P2: with `priv/` at mode 000, `-e`/`-L` are false for `priv/notes.md`, so `else continue` runs and the walk is `ok` with `priv/hidden.md: -`; git prints `warning: could not open directory 'priv/'` to stderr. Probe P3: with an untracked `sub/CLAUDE.md` under a mode-000 `sub/`, ls-files exits 0, the start is not listed, and the walk is `ok` with `sub/hid.md: -`. Severity: Low-Medium (Claude Code, running as the same user, cannot read those files either, so it would not load them while the mode stays 000; the risk is the mode being restored after the gate ran, plus the header's "a checkout file it cannot read fails the walk" being false). Confidence: high (executed). Legibility-target: the test is named for the decision, not for the mechanism.

**G5** — Evidence: lib :596 `lk=""; p="$d"; IFS=/ read -ra parts <<<"$out"` (the 120000 arm continues to :603). Severity: Low. Confidence: high that no symlink can carry it (fact-check r1/r2/r3 agree). Legibility-target: n/a.

**G6** — Evidence: test 9 line 183 comment "A tracked directory symlink, present in the checkout, that an import passes through", which now fails at :614 (`docs-link` is 120000 on main) before the `t:` arm. Severity: Low. Confidence: high. Legibility-target: reword the comment to "a directory link main stores, which an import passes through".

## Recommended Tests

#### Test 15 extension: parent-link refusal two levels deep, one-letter link, and the cached answer

**Closes gaps:** G1, G2
**Type:** integration (bats, fixture repo)
**Priority:** high
**File:** test/scripts/build-loop-check.bats, test 15 ("main walk fails on link text with a .. after a symlink ...")
**What it verifies:** an import main lacks at any depth under any link main stores fails the walk, and the failure persists for every later `isimported main` in the same shell.
**Key cases:**
- the `for how in link token` loop: `want deep/inner/i.md imported` after `want walk failed` → kills N34
- main `l -> deep`, `CLAUDE.md` = `see @l/inner/i.md`, checkout lacks `l` → `walk failed`, `deep/inner/i.md imported` → kills N33 and N37

**Setup needed:** none beyond test 15's fixture. The patch is Appendix A: 3 lines added, 1 changed. Checked: 16/16 pass, and N25, N26, N27, N32, N33, N34 and N37 are all killed by test 15.

#### Start file under a directory link main stores (after the fix)

**Closes gaps:** G3
**Type:** integration
**Priority:** high once fixed (fail-open today)
**File:** test/scripts/build-loop-check.bats. It could be folded into test 15 as three lines (Appendix B test 1).
**What it verifies:** the checkout cannot turn main's failed walk into an ok one through an untracked start.
**Key cases:** main `ld -> deep`, `CLAUDE.md` = `see @ld/CLAUDE.md` → `walk failed`; then `ld` a plain directory with an untracked `ld/CLAUDE.md` → still `walk failed`, `x.sh imported`.
**Setup needed:** none. It fails at cc1aa864 and passes under N17. Escalated.

#### Unsearchable checkout directory (after a contract decision)

**Closes gaps:** G4
**Type:** integration
**Priority:** medium (pending a decision)
**File:** test/scripts/build-loop-check.bats (Appendix B test 2)
**What it verifies:** whichever contract is chosen. As drafted, it checks that a mode-000 directory that holds an import main lacks, or an untracked start, fails the walk.
**Key cases:** `chmod 000 priv` → `walk failed`; `chmod 000 sub` → `walk failed`. Restore the mode before asserting, so bats can clean up.
**Setup needed:** a non-root runner (root ignores mode 000; guard with `[ "$(id -u)" -ne 0 ] || skip`). It fails at cc1aa864. Escalated.

## What NOT to Test

- **G5 / the :596 here-string**: there is no real symlink whose text reaches 64 KiB (PATH_MAX). Testing it would mean hand-feeding main_imports a forged blob plus an unwritable TMPDIR and an ignored SIGXFSZ, which costs far more than it is worth. The fix is either to drop the here-string or to file an override row, not a test.
- **G6**: fix the comment. No new test, since test 12 already pins the checkout-symlink arm.
- **N03, N06, N10, N39, N40, N45** (table above): equivalent, fail-safe, or unreachable from git's or realpath's real output.
- **N17**: fails safer, not open. G3's test covers the one behaviour difference that matters.
- **Line cap**: the unit is at 400 changed lines. Appendix A is +3 lines net, and Appendix B is not proposed for this unit unless the G3 fix lands here (it can fold into test 15 as +3 lines).

## Coverage Gaps Beyond Current Scope

**1.** The import_targets Unicode/NUL/Markdown cut points and the sed/grep/lower fail-closed arms are fixed in U2a3b (stacked). Test them there, not here.
**2.** `git ls-files --others` exit-0-with-warning also affects `imported_names` (the tree walk, :504). If G4's decision is "fail", the same test shape applies to `imps tree`.

## Summary

The highest-value addition is the 4-line extension to test 15 (Appendix A). It closes the only fail-open mutation survivors in the shipped code: the parent-link refusal is untested beyond the immediate parent, for one-letter names, and on the cached `isimported` path. The main residual risk is G3, a real fail-open the suite cannot pin until it is fixed: an untracked start under a link main stores turns main's failed walk into ok, which contradicts the header's "can only add imports or fail it". G4, an unsearchable checkout directory, is a contract question: the walk answers ok while the header says an unreadable checkout file fails it. Both have ready tests in Appendix B. They fail today and will turn green under the corresponding fix.

## Appendix A: checked patch (apply to test/scripts/build-loop-check.bats)

Verified in `/tmp/u2a3-ts-i3-plEO/w`: 16/16 pass, and N33, N34 and N37 are killed by test 15 (along with the already-killed N25, N26, N27 and N32).

```diff
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -288,8 +288,11 @@
         rm CLAUDE.md && ln -s deep/inner ld
         if [ "$how" = link ]; then ln -s ld/i.md CLAUDE.md; else printf 'see @ld/i.md\n' > CLAUDE.md; fi
         commit_all "$how" && rm ld
-        imps main deep/inner/i.md; want walk failed
+        imps main deep/inner/i.md; want walk failed; want deep/inner/i.md imported
     done
+    # Two levels below a one-letter link main stores, the checkout lacking it.
+    rm CLAUDE.md && ln -s deep l && printf 'see @l/inner/i.md\n' > CLAUDE.md && commit_all grand && rm l
+    imps main deep/inner/i.md; want walk failed; want deep/inner/i.md imported
     # A .. after a plain directory is followed; then a link only the checkout has.
     rm CLAUDE.md && ln -s ld/../evil.md CLAUDE.md && commit_all no-ld
     imps main hid.md docs/n.md deep/secret.md; want walk ok; want hid.md imported; want docs/n.md imported; want deep/secret.md -
```

(The later `commit_all no-ld` also commits the removal of `l`, so the rest of test 15 runs on a tree without it.)

## Appendix B: pending tests (fail at cc1aa864; checked in `/tmp/u2a3-ts-i3-plEO/w/test/scripts/pending-ts-i3.bats`)

```bash
@test "an untracked start file under a directory link main stores fails the walk as main alone does (G3)" {
    mkdir deep && ln -s deep ld && printf 'see @ld/CLAUDE.md\n' > CLAUDE.md && commit_all link-start
    imps main x.sh; want walk failed
    rm ld && mkdir ld && printf 'none\n' > ld/CLAUDE.md
    imps main x.sh; want walk failed; want x.sh imported
}

@test "an import main lacks, or an untracked start, in a checkout directory the walk cannot search fails the walk (G4)" {
    [ "$(id -u)" -ne 0 ] || skip "root ignores mode 000"
    printf 'see @priv/notes.md\n' > CLAUDE.md && commit_all priv
    mkdir priv sub && printf 'see @hidden.md\n' > priv/notes.md && printf 'see @hid.md\n' > sub/CLAUDE.md
    imps main priv/hidden.md sub/hid.md; want walk ok; want priv/hidden.md imported; want sub/hid.md imported
    chmod 000 priv; imps main x.sh; chmod 755 priv; want walk failed; want x.sh imported
    chmod 000 sub; imps main x.sh; chmod 755 sub; want walk failed; want x.sh imported
}
```

Results at cc1aa864: test 1 fails (`walk: ok`, `x.sh: -`), and test 2 fails at the `priv` step (`walk: ok`, git `warning: could not open directory 'priv/'`). Under mutant N17, test 1 passes.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-final-build-loop-u2a3.md naming each gap with a concrete test case, with a checked patch in an appendix (run in your scratch copy; do not edit the worktree's tracked files).

**Answered:** Six gaps are named. G1 and G2 are closed by a checked 4-line patch to test 15 (Appendix A: 16/16 pass, all three fail-open survivors killed). G3 and G4 have concrete tests that are confirmed to fail today (Appendix B). G5 and G6 are dispositioned as not worth a test. Only this report file was written in the worktree.

**Out of scope:** Fixing main_imports (G3/G4 fixes), the U2a3b stacked parser and fail-closed changes, and commit-message wording (fact-check r1 38b, which needs an Accepted-immutable row).

**Escalate:**
- (a) implementer: G3, a fail-open. One fix shape that this test passes under is dropping the start pre-mark at :572 (N17), or running the :614 check for starts too. Otherwise narrow the header's "can only add imports or fail it".
- (b) implementer/user: G4. Decide whether an unsearchable checkout directory (including ls-files' exit-0 warning) fails the walk. If so, the test is ready; if not, narrow the header's "a checkout file it cannot read fails the walk".
- (c) implementer: apply Appendix A (+3 lines net) under the line cap.
