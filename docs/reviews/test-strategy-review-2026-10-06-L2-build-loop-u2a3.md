Commit: 5c57d367

# Test Strategy: feat/build-loop-u2a3 (loop 2, iteration 1, ts2)

**Scope:** `git diff main...HEAD` (base 62d366a7): `scripts/lib/dev-cycle-read.sh` (`nul_list` :516-517, `main_imports` :536-609, `isimported main` :610-624), `test/scripts/build-loop-check.bats` (16 tests), `test/scripts/dev-cycle.bats`.
**Reviewed:** 2026-10-06
**Method:** single-point mutants in a scratch copy of `scripts/` and `test/` (`/tmp/u2a3-ts2-i1-DjwI/m-*`, driver `mut.sh`), plus probe repos (`probe.sh`). The worktree's tracked files were not edited.

## Test Conventions

Bats 1.5+ (`bats_require_minimum_version`), one throwaway repo per test from `test/lib/build-loop-fixtures.bash` (`bl_setup`, `commit_all`). Main-walk tests call `imps main PATH...` and assert with `want walk ok|failed` / `want PATH imported|-`. Shapes git cannot check out (duplicate names, NUL or oversize link text) are built with `git hash-object -w`, `git mktree` and `git commit-tree`, then `git update-ref refs/heads/main`. Failure-injection tests use `run --separate-stderr env LC_ALL=C bash -c '...'` with `ulimit -f 0`, a PATH-shimmed `tr`, or a deleted object file. The unit is at 392 of 400 changed code lines, so every recommendation below extends an existing test.

Baseline: 16/16 pass at 5c57d367 (`m-baseline.out`).

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:562 — `return 1` when an untracked `.md` name holds a newline — not covered. Test 7's fixture (`.claude/rules/zz\ndocs.md`, bats :147) is also an untracked start file, so :569 fails the walk whether or not :562 is there.
- **G2** — scripts/lib/dev-cycle-read.sh:588-590 — the `..`-after-a-symlink check reading link text whole (loop 1 C4: `mapfile -d /` from a process substitution, not a here-string) — not covered. No test has link text past the here-string pipe size, so reverting to `IFS=/ read -ra parts <<<"$out"` passes all 16.
- **G3** — scripts/lib/dev-cycle-read.sh:569 / :561, in the contract more than the code — a start file the checkout tracks (in its index or its HEAD) but main lacks is not walked and does not fail the walk — not covered, and the code does not do it either (see the G3 finding).
- **G4** — scripts/lib/dev-cycle-read.sh:596 — `*) continue` for an import of a path main stores as a gitlink (mode 160000), answering ok — not covered. Only the stricter mutant survives, so nothing fails open.
- **G5** — scripts/lib/dev-cycle-read.sh:517 — `nl_a=()` emptying the array when `nul_list` fails (loop 1 C10) — not covered. No caller in this unit reads the array after a failure.
- **G6** — scripts/lib/dev-cycle-read.sh:606 — an import of the repo root (`@.`, `@docs/..`) fails the walk (through `blocker` → `plaindir`'s `$ROOT_REAL/.` string compare) — not covered. I probed it (`walk: failed`), and the I2-C2 comment names it.

## Findings

### G1 — the untracked-list newline check (:562) is unpinned

- **Location:** scripts/lib/dev-cycle-read.sh:562; test/scripts/build-loop-check.bats:146-151 (test 7)
- **Evidence:** I removed the check (mutant `m-untrnl`: `for f in "${recs[@]}"; do cand+=("t:$f"); done`) and the suite still passed: 16/16 with exit 0. A probe repo with a committed `CLAUDE.md` and an untracked file named `zz<LF>CLAUDE.md` answers `failed` on the current lib and `ok` on the mutant. That name is not a start, because the basename regex is anchored and `${f##*/}` keeps the `zz<LF>` prefix, so only :562 refuses it. Test 7's existing fixture name matches `.claude/rules/*.md` (bash's glob `*` matches a newline), so :569 fails it first. With the patch's fixture the mutant fails test 7 (`m-F-untrnl.out`: `not ok 7`), and the :569 mutant is still killed by tests 3, 9 and 11 (`m-F-untracked569`).
- **Severity:** Low. Under the split contract the walk never reads untracked non-start files, so the mutant changes `failed` to `ok` only for a name the walk would otherwise ignore. The pin keeps the documented refusal ("a name holding a newline ... fail[s] the walk", header :458) in place for U2a3c, which will read checkout files.
- **Confidence:** High (mutant executed, both directions).
- **Legibility-target:** test 7's comment ":146 An untracked name holding a newline fails the walk" becomes true of its fixture alone.

### G2 — C4's here-string fix (:588) is unpinned; the fail-open it closes reproduces

- **Location:** scripts/lib/dev-cycle-read.sh:588-595; test/scripts/build-loop-check.bats:202-221 (test 10)
- **Evidence:** Mutant `m-herestr` (line 588 → `IFS=/ read -ra parts <<<"$out"`) passes all 16 tests. Probe: on main, `AGENTS.md` is a symlink whose text is 270 × (`<250 zeros>/../`) followed by `l/../t.md` (68,589 bytes), and `l` is a symlink to `docs`. Run under `trap "" XFSZ; ulimit -f 0`, the current lib answers `failed` (the `..` after link `l`), and with `l` stored as 100644 instead it answers `ok`, which shows the failure comes from the :590 check. The mutant prints `line 588: cannot create temp file for here-document: File too large`, leaves `parts` empty, skips the check, and answers `ok`: the walk passes link text that the kernel would follow through `l`. Without the XFSZ trap the mutant dies with SIGXFSZ (status 153), so the trap is what models a full disk, where the write fails and returns instead of killing the shell. Patched: the mutant fails test 10 with status 0 and empty output (`m-F-herestr.out`). The added case runs in about 0.7 s (540 `realpath` forks).
- **Severity:** Low. A real checkout cannot hold a symlink whose text exceeds 4095 bytes (loop 1 rubric C4: "Unreachable through a real symlink"), so Claude Code would never read through it. The test pins the fix that commit 2b22a082 claims ("no here-string left in main_imports").
- **Confidence:** High (mutant executed, control probe run).
- **Legibility-target:** test 10's title already names "under ulimit -f 0". The new comment names loop 1 C4 and why XFSZ is ignored.
- Side note, not a gap: the :607 here-string mutant (`m-herestr607`) fails the existing 67 KB case only through SIGXFSZ (status 153). It is still killed, because the case asserts `ok` and both a crash and a silent empty read miss that.

### G3 — a start file the checkout tracks but main lacks passes the walk (contract gap, escalate)

- **Location:** scripts/lib/dev-cycle-read.sh:561-571 (`untracked_md` is `--others` only); the Not-covered list :465-470; F11 Gaps in docs/working/plan-build-loop-handoff.md
- **Evidence:** Probes on the current lib: (a) `sub/AGENTS.md` (`x @p.md`) staged in the index but not committed answers `walk: ok`; (b) the same file committed on a branch `feat` checked out over main also answers `walk: ok`. In both cases `sub/p.md` is not imported. This matches the fact-check's P1 (Claims 7 and 24). It is the one checkout input that neither fails the walk nor gets walked, which conflicts with the split's "fails closed on the checkout" headline (Claim 15).
- **Severity:** Medium if the gate's checkout can differ from MAIN_SHA, which F11 leaves to U2b. Low if U2b guarantees a clean worktree at MAIN_SHA.
- **Confidence:** High for the behavior (probed). Medium for the risk, which depends on U2b's choice of checkout.
- **Legibility-target:** the author's call. If the walk should fail closed, the test is one line at the end of test 3 (bats :60): `git add -f` a `sub/AGENTS.md` that main lacks, then `imps main docs/guide.md; want walk failed`. That line fails against the current code, so it is not in the patch. If the gap is accepted, the code's Not-covered list and F11's Gaps should name it, as A5 already does.

### G4, G5, G6 — unpinned paths where the missing arm cannot fail open

- **G4** (:596): mutant `m-case596` (`*)` fails the walk instead of `continue`) survives. An import of a path main stores as a gitlink reads nothing, as Claude Code reading a directory does. The surviving mutant is stricter, so nothing fails open. **Evidence:** `m-case596.out` 16/16. **Severity:** Low. **Confidence:** High. **Legibility-target:** none needed.
- **G5** (:517): mutant `m-nulempty` (no `nl_a=()`) survives. `main_imports` returns 1 straight after either failing `nul_list` call. The core check is pinned: `m-nulchk`, which drops the rc=0 check, fails test 10. **Evidence:** `m-nulempty.out` 16/16. **Severity:** Low here. Pin it in U2a3b when `imported_names` reads the array after a failure. **Confidence:** High. **Legibility-target:** U2a3b's test. Separately, the dev-cycle.bats defined-functions list (:1086) omits `nul_list` (fact-check).
- **G6** (:606): a root import fails through `plaindir`'s string compare (`$ROOT_REAL/.` ≠ `$ROOT_REAL`), not through an explicit rule. A regression there would move the answer from `failed` to `ok` for an import that reads nothing, which is stricter-to-looser but harmless. **Evidence:** probe `@.`, `@docs/..`, `@docs/../` → `failed`. **Severity:** Low. **Confidence:** Medium (I did not mutate `plaindir`, which is outside the diff). **Legibility-target:** the comment's "(the root itself included)".

## Recommended Tests

#### Untracked non-start name holding a newline fails the walk
**Closes gaps:** G1
**Type:** integration (fixture repo)
**Priority:** medium (cheapest pin, no added lines)
**File:** test/scripts/build-loop-check.bats, test 7 (:146-151)
**What it verifies:** :562 alone refuses an untracked `.md` name holding a newline.
**Key cases:**
- untracked `zz<LF>CLAUDE.md` (no start by either rule) → `walk: failed`, `docs/x.md: imported`
- removed → `docs/x.md: -`
**Setup needed:** none. Swap the fixture name and the `rm`.

#### Link text past 64 KiB with a `..` after main's link, under ulimit -f 0 with XFSZ ignored
**Closes gaps:** G2
**Type:** integration (crafted commit)
**Priority:** medium
**File:** test/scripts/build-loop-check.bats, test 10 (after :220)
**What it verifies:** the :588 split reads link text whole when a temp-file write would fail, so :590 still refuses `l/..`.
**Key cases:**
- `AGENTS.md` → 68,589-byte text ending `l/../t.md`, with `l` → `docs` on main → `main_imports` returns 1 (`failed`)
**Setup needed:** `git hash-object`/`mktree`/`commit-tree` (already used in this file).

#### (Conditional, not in the patch) A start file the checkout tracks but main lacks
**Closes gaps:** G3
**Type:** integration
**Priority:** high if the author makes the walk fail closed on it; otherwise none
**File:** test/scripts/build-loop-check.bats, test 3 (:60)
**Key cases:** `mkdir -p sub && printf 'x @p.md\n' > sub/AGENTS.md && git add sub/AGENTS.md; imps main docs/guide.md; want walk failed; want docs/guide.md imported`

## What NOT to Test

- **:555 record-parse refusal**: needs a fake `git ls-tree`. The tree is git's own output, and a parse failure fails closed.
- **:582-583 symlink-blob read failure**: three checks guard it (pipefail on the NUL count, the second `cat-file`, the empty-text refusal at :585), so no single-point mutant fails open.
- **:591/:594 `realpath ... || p=..`**: `realpath -m` does not fail on these inputs, and the fallback is the refusing value.
- **:606 first-arm `! -L "$p"`**: mutant `m-nolink1` is equivalent, because `blocker`'s `plaindir` refuses the link itself (probe: a checkout dir-link at a target main lacks fails on both libs).
- **G4, G5, G6**: the surviving mutants are stricter or unreachable in this unit, and the line budget is better spent on G1/G2.
- **P3 (`@.git` in a linked worktree fails)**: stricter than before the split, so it is a contract note for the author, not a test gap.

## Coverage Gaps Beyond Current Scope

**1.** U2a3b: pin `nul_list`'s array emptying (G5) once `imported_names` reads the array after a failure.
**2.** U2a3c: when checkout files are walked, the :562 newline refusal becomes load-bearing for reads. G1's fixture already pins it.
**3.** U2b: whichever checkout the gate uses decides G3's severity. A test that the gate's checkout is at MAIN_SHA belongs there.

## Summary

The highest-value addition is G2. It reproduces the loop-1 C4 fail-open on the here-string revert (the mutant answers `ok` past link text it never checked) and pins C4's fix in five added lines. G1 pins the :562 newline check by renaming test 7's fixture so it is no start file, which adds no lines. Together the patch adds 7 lines (5 new, 2 changed; 6 of them code), kills both surviving mutants the fact-check flagged, and leaves 16/16 green. The main residual risk is G3: a start file the checkout tracks but main lacks neither fails the walk nor gets walked. That is a contract question for the author and U2b, not something a test can close against the current code.

## Appendix A — checked patch (applied only in the scratch copy)

Scratch: `/tmp/u2a3-ts2-i1-DjwI/patched.bats`, diff at `/tmp/u2a3-ts2-i1-DjwI/patch.diff`.

```diff
--- base/test/scripts/build-loop-check.bats
+++ patched.bats
@@ -144,10 +144,10 @@
     want walk ok; want hid.md imported
     want ..x.md imported
     # An untracked name holding a newline fails the walk.
-    mkdir -p .claude/rules && printf 'x\n' > ".claude/rules/zz"$'\n'"docs.md"
+    printf 'x\n' > "zz"$'\n'"CLAUDE.md"
     imps main docs/x.md
     want walk failed; want docs/x.md imported
-    rm -r .claude
+    rm "zz"$'\n'"CLAUDE.md"
     imps main docs/x.md; want docs/x.md -
     # Symlink text with a trailing newline, an absolute one, none, or one leaving the repo: the walk fails.
     for text in $'notes.md\n' /etc/hosts '' ../outside/AGENTS.md; do
@@ -218,6 +218,11 @@
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; ulimit -f 0; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"
         main_imports && isimported main docs/last.md && echo ok' _ "$LIB"
     [ "$output" = ok ] || { echo "$status $output $stderr"; return 1; }
+    # Link text past 64 KiB with a .. after main's link l, under ulimit -f 0: the .. check reads it whole (loop 1 C4; XFSZ ignored, so a failed temp write returns, as a full disk does).
+    x="$(for i in $(seq 270); do printf '%0250d/../' 0; done)l/../t.md"
+    t="$(printf '120000 blob %s\tAGENTS.md\n120000 blob %s\tl\n' "$(printf '%s' "$x" | git hash-object -w --stdin)" "$(printf docs | git hash-object -w --stdin)" | git mktree)"; git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m big-link)"
+    run --separate-stderr env LC_ALL=C bash -c 'trap "" XFSZ; ulimit -f 0; source "$1"; resolve_main; ROOT_REAL="$(pwd -P)"; main_imports || echo failed' _ "$LIB"
+    [ "$output" = failed ] || { echo "$status $output $stderr"; return 1; }
 }
```

Added lines: 7 insertions (6 code, 1 comment), 2 deletions. That is within the 8-line cap.

**Check runs** (TMPDIR per run under the scratch dir; `bats` on the scratch copy):

| Run | Lib | Tests | Result |
|---|---|---|---|
| `m-baseline` | current | original | 16/16 pass |
| `m-untrnl` | :562 check removed | original | 16/16 pass (survives) |
| `m-herestr` | :588 → here-string | original | 16/16 pass (survives) |
| `m-F-baseline` | current | patched | 16/16 pass |
| `m-F-untrnl` | :562 check removed | patched | killed: test 7 |
| `m-F-herestr` | :588 → here-string | patched | killed: test 10 (status 0, empty output: the silent `ok`) |
| `m-F-untracked569` | :569 → `true` | patched | killed: tests 3, 9, 11 (unchanged by the fixture swap) |

Other mutants (original tests): `m-noblock` (:606 drop `blocker`) killed by 12; `m-nulchk` (:517 drop the rc check) killed by 10; `m-herestr607` killed by 10 (SIGXFSZ, status 153); `m-nolink1` survives, equivalent; `m-case596` and `m-nulempty` survive (G4, G5).

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/test-strategy-review-2026-10-06-L2-build-loop-u2a3.md naming each gap with a concrete test case, with a checked patch in an appendix (run in your scratch copy; do not edit the worktree's tracked files) that stays within 8 added code lines."
- **Answered:** G1-G6 are named with locations. G1 and G2 (the two fact-check escalations: :562 and the C4 here-string revert) each have a concrete test case, and the checked patch kills both mutants in 7 added lines, all 16 passing. G3 has a concrete conditional test case. G4-G6 go to What NOT to Test with reasons.
- **Out of scope:** U2a3b's parser and sed/grep fail-closed changes; U2a3c's checkout phase; the doc-wording fixes the fact-check routed to the author (:33, :516, :604, test 9's name and comment :189).
- **Escalate:** G3 to the author/coordinator. A start file the checkout tracks but main lacks passes the walk without being read (probed in two forms). Decide whether to fail closed (the one-line test above) or to name the gap in the code's Not-covered list and F11. Its severity depends on U2b's choice of checkout, as in the fact-check's override-log candidate on 2b22a082's D13 claim.
