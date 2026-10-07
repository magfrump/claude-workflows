Commit: e1654266

# Test Strategy: feat/build-loop-u2a3b, loop 2 final confirming pass (full unit)

**Scope:** `git diff main...e1654266 -- . ':!docs/reviews'`: the parser (`IMPORT_AWK`, `import_targets`, `import_home`, `UTF8_OK`), both walks (`imported_names`, `main_imports`, `tree_starts`, `instruction_names`), `isimported`, the `--check-fix` wiring in `scripts/dev-cycle.sh`, and `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`
**Reviewed:** 2026-10-07
**Method:** I read each unit whole at e1654266. I then ran 79 mutants over the unit's parser, walk and wiring changes, on `git archive e1654266` copies in `/tmp/u2a3btsfin-rZjL/` (`mut.py`, `one.sh`, `runm.sh`; logs `log-base/`, `log-pat/`). Each mutant ran against build-loop-check.bats in full and against dev-cycle.bats `-f 'check-fix|import|sourced|IMPORTED'` (52 tests at HEAD, about 12 s). I re-ran every mutant with the Appendix A patch applied (57 tests). With the patch, the four suites (build-loop-check, dev-cycle, build-loop-read, fixture-git-env) pass 146/146 at e1654266. All of this was executed unless a line says "reasoned".

## Stage-1 items in my lane

| Stage-1 item | Result here |
|---|---|
| emit's 50M work bound has no test since IMPORT_LEFT (r1 33, r2 38) | Confirmed. P01 (bound deleted) and P02 (bound ×100) pass all 52 tests. The heavy-run probe is stopped by the print budget (P17 kills it, P01 does not). See F1; Appendix A adds a test that prints nothing and kills both. |
| nested `*/.git` skip mutant survives, not equivalent (r1 44) | Confirmed. M08 (`[[ "$p" != .git ]]` only) passes all 52. With a linked worktree at `sub/` and `@sub/.github/x.md`, the main walk fails under M08 and passes at HEAD. See F2. |
| empty-HOME passwd reading unpinned (r1 22b, r2 27b, r3 21b) | Confirmed. H01 (`${HOME-…}`, so an empty HOME stays empty) and H02 (no passwd fallback) both pass. See F3. The comment's Node attribution (Incorrect) is fact-check's, not this report's. |
| Unicode-space conversion unpinned for precision (r1 32) | Confirmed. T02 (no conversion) and T03 (U+FEFF dropped) pass, because every test asserts only the read and never the token's end. P20 (tab) and P21 (CR) survive for the same reason. See F4. |
| the always-fork UTF-8 gate mutant survives (r3 41) | Confirmed: T05 passes, and so does T07 (byte test only, no UTF8_OK). These are not "time only", though. The lib header states a contract they break: "The import walks also need python3 when an instruction file holds text that is not well-formed UTF-8; without it they fail closed" (`scripts/lib/dev-cycle-read.sh:12-13`). Under T05, a host without python3 fails every walk over an `é`. See F5. |

## Test Conventions

- bats 1.8.2 with `test/lib/build-loop-fixtures.bash`. `bl_setup` gives a throwaway repo at `$BATS_TEST_TMPDIR/repo`, `HOME=$BATS_TEST_TMPDIR/home` and `LC_ALL=C`. `imps WALK PATH...` prints `walk: ok|failed` and `PATH: imported|-`, and `want` asserts one line. Most cases loop `for w in tree main`.
- Fault injection goes through PATH shims in `$BATS_TEST_TMPDIR`, and parser probes source the lib inside `bash -c`. Two title conventions: `FAILS at <sha>` for a hole a test was written against, and over-reads pinned with a "may delete on purpose" comment.

## Mutation results (79 mutants)

Killed at HEAD (52 tests), 47 of 79: P03, P04, P07-P09, P11-P13, P16-P19, P22-P28, T01, T04, T06, T08, T09, T11, T12, H05, S01-S03, W01, W02, W04, W05, W09, W11, W12, W14, W15, M03, M05-M07, M09, I01, I02, D01.

Survivors at HEAD, and their status with Appendix A:

| Mutant | Change | Appendix A | Verdict |
|---|---|---|---|
| P01 | emit work bound deleted (`:536`) | killed | real gap (F1) |
| P02 | emit work bound ×100 | killed | real gap (F1) |
| M08 | skip only a top-level `.git` (`:759`) | killed | real gap (F2) |
| H01 | empty HOME kept, no passwd (`:606`) | killed | real gap (F3) |
| H02 | no passwd fallback at all | killed | real gap (F3) |
| T02 | Unicode spaces not converted (`:614`) | killed | precision gap (F4) |
| T03 | U+FEFF dropped from UNI_SPACES | killed | precision gap (F4) |
| P20 / P21 | tab / CR does not end a name (`:574`) | killed | precision gap (F4) |
| T05 | UTF-8 gate always forks python3 (`:622`) | killed | contract gap (F5) |
| T07 | UTF-8 gate is the byte test only | killed | contract gap (F5) |
| W10 / M04 | `used =` per file, not `+=` (`:671`, `:748`) | killed | test drift (F6) |
| W16 | imported_names without its own pipefail (`:649`) | killed | real gap (F7) |
| P14 | below-root check deleted, length check kept (`:559`) | killed | precision gap (F8) |
| P05 | no trailing trim | survives | equivalent (the untrimmed prefix is emitted anyway) |
| P06 | `if (c == "") return` deleted | survives | precision only: `@\ ` in `sub/X.md` records the directory `sub`, which no check edits (reasoned) |
| P10 | only the real home form | survives | equivalent unless HOME's spelled path lies inside the repo through a symlink (reasoned) |
| P15 | `length(out) <= length(pre)` deleted | survives | equivalent (out never ends in `/`) |
| T10 | decoded text replaces raw | survives | precision only (prior N17) |
| T13, H04, W03, M01 | a failure of `import_home` or its `realpath -m` ignored | survives | unreachable here: `realpath -m` does not fail on any input I could build |
| H03 | the home cache ignores a HOME change | survives | no caller changes HOME between walks; low (below) |
| T14 | no `local LC_ALL=C` | survives | equivalent on this host (prior N14) |
| W06 | head 4194304 | survives | equivalent (prior N31) |
| W07 / M02 | a walk does not pass IMPORT_LEFT | survives | time only: the bash `used` check still fails the walk, after awk has printed up to IMPORT_OUT_MAX |
| W08, M12, W13, M10, M11 | empty-out skip, `-f` prefilter, `pok` memo removed or weakened | survives | time only |

With Appendix A, no killed mutant survives, and every survivor that changes an outcome is killed.

## Findings

**F1. Severity: medium (a stated bound with no test). Location:** `scripts/lib/dev-cycle-read.sh:536`; test `test/scripts/build-loop-check.bats:383-388`.
- **Evidence:** `work += length(c); if (work > 50000000) exit 3`. The only probe, `# Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's length is charged; the sixth run trips it): the parser returns 1.`, has been stopped by the print budget since IMPORT_LEFT (e1654266): the first run's prefixes print about 8.8M, against a default budget of 4M. P01 and P02 pass.
- **Why it matters:** the header promises that a pathological file "fails the walk rather than stalling it". The only thing between a run of escaped spaces, which prints nothing, and quadratic emit work is this line.
- **Fix:** Appendix A adds a test with `@` and 10,100 escaped spaces. Every candidate trims to empty, so nothing prints and only the work bound can stop it: rc=1 at HEAD, rc=0 under P01. It takes 0.5 s; I measured 9,900 spaces at rc=0. The patch also rewords the stale comment and the test title ("the work bound fails the walk" → "a run that prints past IMPORT_OUT_MAX fails the parser").
- **Confidence:** high. **Legibility-target:** for-author. Executed.

**F2. Severity: low (an arm of a fix with no test; it fails closed). Location:** `scripts/lib/dev-cycle-read.sh:759`.
- **Evidence:** `[[ "$p" != .git && "$p" != */.git ]] || continue`. Only the top-level arm has a test (`:391`). M08 passes.
- **Fix:** Appendix A test: `git worktree add -q --detach sub main` inside the checkout, and GEMINI.md naming `@sub/.github/x.md`. `sub/.git` is then a prefix candidate and a gitfile. Result: `walk ok` at HEAD, `walk failed` under M08. The commit message's "each fix's mutant fails a test except the parent memo and the LC_ALL=C guard" is wrong at e1654266 (fact-check's finding, which I confirmed); it becomes true for this arm once the test lands.
- **Confidence:** high. **Legibility-target:** for-orchestrator-synthesis (the commit's mutant claim). Executed.

**F3. Severity: low (a branch with no test; the mutant fails closed). Location:** `scripts/lib/dev-cycle-read.sh:606`.
- **Evidence:** `h="${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}" || h=""`. H01 and H02 pass. Under either one, an empty or unset HOME makes every `~/` name exit 4, so both walks fail. That is the safe direction, but it would refuse every `--check-fix` in a repo whose instruction files use `~/`, under a cron or `env -i` caller.
- **Fix:** Appendix A test: a `getent` shim whose passwd home is the repo's parent, with `HOME=""` and then HOME unset, for both walks. Expected: `walk ok` and `docs/home.md imported`. The test comment cites Bun's behaviour from Stage 1 (r1 22b), not Node's.
- **Confidence:** high for the mutant behaviour; the premise about Bun is Stage 1's. **Legibility-target:** for-author. Executed.

**F4. Severity: low (precision, which test titles state but no assertion pins). Location:** `scripts/lib/dev-cycle-read.sh:614` (UNI_SPACES conversion) and `:574` (tab, CR).
- **Evidence:** two titles say the spaces "end a token": `:26` ("Unicode spaces end a token") and `:53` ("every Unicode space JavaScript's \s holds ends a token"). Both tests assert only that the name before the space is read, which the prefix rule yields whether or not the token ends. T02, T03, P20 and P21 pass.
- **Fix:** Appendix A adds `want "<name><space>x" -` for all 19 spaces in both walks, `want $'docs/nb.md\xc2\xa0for' -` in `:26`, and tab and CR cases in the "a blank ends every name" test (`:528`). Each carries the existing "precision, not superset" label, so a deliberate broadening can delete them. If the author prefers not to pin precision, the alternative is to retitle `:26` and `:53` to "a name before each space is read". Either way, the title and the assertions should agree.
- **Confidence:** high. **Legibility-target:** for-author. Executed.

**F5. Severity: low (a header contract with no test). Location:** `scripts/lib/dev-cycle-read.sh:12-13` and `:622`.
- **Evidence:** `# The import walks also need python3 when an instruction file holds text that is not well-formed UTF-8; without it they fail closed.` T05 (`if true; then`) and T07 (no UTF8_OK gate) both pass. Under either one, a host without python3 fails every walk over any non-ASCII text, such as `Voilà`, so `--check-fix` refuses everything there.
- **Fix:** Appendix A test: a python3 shim that exits 1, and AGENTS.md holding `Voil\xc3\xa0: @docs/caf\xc3\xa9.md and @docs/a.md`. Both walks give `walk ok` with both names imported. The existing python3-failure test (`:573`) covers the opposite side.
- **Confidence:** high. **Legibility-target:** for-author. Executed.

**F6. Severity: medium (test drift: an earlier fix's test no longer kills its mutant). Location:** `scripts/lib/dev-cycle-read.sh:669,671` and `:726,748`; test `test/scripts/build-loop-check.bats:600-607`.
- **Evidence:** the test is "IMPORT_OUT_MAX bounds what the whole walk prints, not each file", with two files of 13 each at limits 20/25/26. At 98e3b1df it killed N23 and N24 (`used = ${#out}`). At e1654266, W10 and M04 (the same change) pass. Each walk now hands the parser `IMPORT_LEFT=$((IMPORT_OUT_MAX - used))`, and after one file a per-file `used` equals the cumulative one, so two files cannot tell them apart. The title still claims the property.
- **Fix:** Appendix A adds a third file (CLAUDE.md `see @c.md`) and moves the limits to 20/38/39. Limit 38 fails both walks at HEAD and passes both under W10 and M04. Limit 39 keeps the exact-limit boundary (W11 and M05 are still killed).
- **Confidence:** high. **Legibility-target:** for-orchestrator-synthesis (rubric L2-A4's "tested; mutant fails" no longer holds at e1654266). Executed.

**F7. Severity: medium (a fail-open that the test harness masks). Location:** `scripts/lib/dev-cycle-read.sh:649` (`local - … ; set -o pipefail`) and `:669`.
- **Evidence:** `out="$(head -c 4194305 -- "$f" | IMPORT_LEFT=… import_targets "$d")" || { IMPORTED=error; return 1; }`. W16 drops imported_names' own `set -o pipefail` and passes every test, because `imps` runs under `set -euo pipefail`. Without that pipefail, a file the walk cannot read (mode 000) gives `head` a failure that the pipeline's status hides. The walk then reads it as no imports, and its imports are dropped: `walk: ok`, `docs/b.md: -`. The lib says a caller may omit pipefail ("check_answer, … imported_names and main_imports also set pipefail for themselves"). The main walk has exactly this test (`:286`, "fails on an unreadable blob when the caller did not set pipefail"); the tree walk does not.
- **Fix:** Appendix A test: `chmod 000 docs/a.md`, where `docs/a.md` imports `b.md`, under a `set -eu` caller. Expected `walk: failed`, then `docs/b.md: imported`. It assumes a non-root runner, as the existing `chmod 000 CLAUDE.local.md` case at `:207` does.
- **Confidence:** high. **Legibility-target:** for-author. Executed.

**F8. Severity: low (precision of a stated rule). Location:** `scripts/lib/dev-cycle-read.sh:559`.
- **Evidence:** `if (index(out, pre) != 1 || length(out) <= length(pre)) return`. P14 (the `index` half deleted) passes. Under it, a sibling directory whose path is as long as the repo's (`@../repx/docs/sib.md` beside `repo`) prints `docs/sib.md` as the repo's own file. That breaks "it is kept only when it lies below ROOT_REAL".
- **Fix:** Appendix A adds the sibling to the re-entry test (`:483`), with `want docs/sib.md -`.
- **Confidence:** high. **Legibility-target:** for-author. Executed.

**F9. Severity: informational (stale test titles and comments). Location:** `test/scripts/build-loop-check.bats`.
- `:339` "~/ dropped": a `~/` name is now joined to HOME (`:543-547`). Only one outside the repo is dropped. The patch retitles it to "a ~/ name outside the repo dropped".
- `:365` and `:383-384`: the work-bound wording (F1). Patched.
- `:400` "more than IMPORT_OUT_MAX bytes": the lib counts characters (`:485`). Patched to "characters".
- `:545` "about 10 s": the test runs in 0.37 s at HEAD, and 10 s is its timeout. Patched to "a 10 s timeout".
- `:26`, `:53` "end a token": made true by F4's assertions.
- `:600-601`: F6's comment. Patched.

These are labels, not behaviour. Every other title in the range states the contract (superset, fail-closed, or precision labelled as such) rather than the implementation. I checked all 43 titles in build-loop-check.bats and the four retitled `--check-fix` tests in dev-cycle.bats.

## Untested Paths Touched by the Change

- **G1** — scripts/lib/dev-cycle-read.sh:536 — emit's candidate-work bound (`exit 3` past 50M) when nothing prints — not covered
- **G2** — scripts/lib/dev-cycle-read.sh:759 — the `*/.git` arm (a nested linked worktree's gitfile as a prefix candidate) — not covered
- **G3** — scripts/lib/dev-cycle-read.sh:606 — HOME empty or unset → the passwd entry's home — not covered
- **G4** — scripts/lib/dev-cycle-read.sh:614, :574 — a Unicode space, tab or CR ending a token (the name does not run on) — not covered; only the read side is
- **G5** — scripts/lib/dev-cycle-read.sh:622 — well-formed non-ASCII text skips python3 — not covered; only python3's failure on invalid text is
- **G6** — scripts/lib/dev-cycle-read.sh:669-671, :726-748 — `used` accumulating past the second file, now that IMPORT_LEFT carries it — no longer covered (drift)
- **G7** — scripts/lib/dev-cycle-read.sh:649, :669 — the tree walk's own pipefail when `head` cannot read a queued file — not covered (masked by the harness's pipefail)
- **G8** — scripts/lib/dev-cycle-read.sh:559 — the below-root `index` test for an outside path as long as the root — not covered
- **G9** — scripts/lib/dev-cycle-read.sh:669, :726 — walks passing IMPORT_LEFT to the parser (time only) — not covered
- **G10** — scripts/lib/dev-cycle-read.sh:607 — import_home recomputing on a HOME change — not covered

## Recommended Tests

All of these are in Appendix A and pass at e1654266.

#### Candidate-work bound with nothing printed
**Closes gaps:** G1. **Type:** unit (parser). **Priority:** high. **File:** build-loop-check.bats (new test, plus a rewording at `:365`/`:383`).
**What it verifies:** a file whose candidates print nothing still fails, rather than stalls, past the work bound.
**Key cases:** `See @` and 10,100 × `\ ` → `rc=1`.

#### Walk-wide budget across three files
**Closes gaps:** G6. **Type:** unit (both walks). **Priority:** high. **File:** build-loop-check.bats `:600`.
**Key cases:** three files of 13 each; limit 20 → both fail; 38 → both fail; 39 → both ok.

#### Tree walk: unreadable imported file, caller without pipefail
**Closes gaps:** G7. **Type:** unit (fault). **Priority:** high. **File:** build-loop-check.bats.
**Key cases:** `docs/a.md` (mode 000) imports `b.md` → `walk: failed`, `docs/b.md: imported`.

#### Nested linked worktree's `.git`
**Closes gaps:** G2. **Type:** unit (main walk). **Priority:** medium.
**Key cases:** worktree at `sub/` and `@sub/.github/x.md` → `walk ok`, with `sub/.github/x.md` and `notes/x.md` imported.

#### Empty or unset HOME reads the passwd home
**Closes gaps:** G3. **Type:** unit (both walks, getent shim). **Priority:** medium.
**Key cases:** `HOME=""` and HOME unset, `@~/<repo>/docs/home.md` → `walk ok`, `docs/home.md imported`.

#### Well-formed UTF-8 needs no python3
**Closes gaps:** G5. **Type:** unit (both walks, python3 shim). **Priority:** medium.
**Key cases:** `Voilà: @docs/café.md and @docs/a.md` with python3 failing → `walk ok`, both imported.

#### Token ends (precision, labelled)
**Closes gaps:** G4, G8. **Type:** unit (both walks). **Priority:** low.
**Key cases:** 19 Unicode spaces, NBSP in `:26`, tab, CR → the run-on name `-`; sibling `../repx/docs/sib.md` → `-`.

## What NOT to Test

- **G9 (IMPORT_LEFT wiring, W07/M02):** the outcome is identical, and the difference is awk printing up to 4M before bash stops the walk. Only a timing assertion could see it, and that would be brittle. The parser-level IMPORT_LEFT test (`:655`) covers the mechanism.
- **G10 (H03):** no caller changes HOME between walks, and a cached walk would not re-read it anyway (IMPORTED_DONE is keyed by ROOT_REAL alone).
- **`import_home` failure arms (T13, H04, W03, M01):** `realpath -m` does not fail on any path I could build, so a test would need a realpath shim that pins the implementation.
- **Equivalent or time-only mutants:** P05, P10, P15, T10, T14, W06, W08, W13, M10, M11, M12. P06 is precision only.
- **The main walk's uncapped blob read:** routed to U2a3c (override log). No new evidence.

## Coverage Gaps Beyond Current Scope

**1.** Stage 1's E1 (instruction files outside the repo, such as a parent CLAUDE.md or ~/.claude/CLAUDE.md, are not walk starts) is a scope question for security and architecture, not a test gap. If it is accepted as a known exception, A5 should name it, and a `skip "<row>"` test in the convention used at `:480-482` would keep it visible.

**2.** The "another checkout" exception also misses a relative name that re-enters through the other checkout's directory (Stage 1, r3 7/15c). If U2b takes it, a test shaped like the re-entry test at `:483`, with `@../wtB/docs/x.md`, is the natural form.

## Summary

The unit's tests mostly state the contract, but 13 non-equivalent mutants survive at e1654266. Three of them are high value. The emit work bound has no test since IMPORT_LEFT (F1). The walk-wide budget test (F6) silently stopped distinguishing a per-file budget once IMPORT_LEFT carried `used` into the parser, so rubric L2-A4's "tested" no longer holds. The tree walk's own pipefail is masked by the harness (F7), and removing it is a fail-open on an unreadable imported file. The remaining survivors are the Stage-1 items: nested `.git`, empty HOME, the precision of Unicode spaces, tab and CR, the python3-free path for well-formed UTF-8, and a below-root precision check. Appendix A kills all 13 and fixes six stale titles or comments; 146/146 tests pass in four suites. What remains are equivalent or time-only mutants and the transcription risk that A5 already names (no Claude Code harness is kept).

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: e1654266` line at the top.
- **Answered:** the mutant sweep over the whole unit (79 mutants, survivors tabled); a concrete test for each real gap; a `git apply --check`-verified patch (Appendix A); a check of titles and comments against the contract (F9).
- **Out of scope:** the lib comment's Node/Bun attribution, the commit-message claims, and the stale A3, F11 and A5 docs (fact-check's); E1 (security and architecture).
- **Escalate:** F6, because the rubric row L2-A4 says "tested; mutant fails", which is false at e1654266. F2, for the commit e1654266 mutant claim.
- **Decisions I made:** I pinned precision (F4, F8) under the existing "precision, not superset" label rather than retitling, because the titles already claimed it. I used a getent shim rather than relying on the runner's passwd entry. I did not test time-only mutants.

## Appendix A: test patch (`git apply --check` against e1654266: OK)

Source: `/tmp/u2a3btsfin-rZjL/tests.patch` (210 lines; sha256 `0747d1fd84e63b81fa1f899a3cc2f11411aff4d2878a5757f688293181d95a09`). It touches only `test/scripts/build-loop-check.bats`: 5 new tests and 7 edited ones. Applied to `git archive e1654266`, build-loop-check, dev-cycle, build-loop-read and fixture-git-env give 146/146. With the patch applied, it kills P01, P02, P14, P20, P21, T02, T03, T05, T07, H01, H02, W10, W16, M04 and M08, and keeps every mutant killed that was killed before. Apply the source file rather than a copy from this page, since Markdown rendering can alter tabs and escapes.

```diff
diff --git a/test/scripts/build-loop-check.bats b/test/scripts/build-loop-check.bats
--- a/test/scripts/build-loop-check.bats
+++ b/test/scripts/build-loop-check.bats
@@ -34,10 +34,11 @@
     commit_all tree
     # Docs/NB.MD and CLAUDE.md: isimported takes a path in any case.
     ps=(docs/nb.md docs/bom.md docs/st.md docs/st.md. ..x.md docs/hid.md docs/b.md docs/c.md claude.md docs/z.md docs/m.md Docs/NB.MD CLAUDE.md)
-    imps tree "${ps[@]}" docs/other.md docs/nb.md.
+    imps tree "${ps[@]}" docs/other.md docs/nb.md. $'docs/nb.md\xc2\xa0for'
     [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
     for p in "${ps[@]}"; do want "$p" imported; done
-    want docs/other.md -; want docs/nb.md. -
+    # The NBSP ends the token: no name runs on past it (precision; a superset may over-read it).
+    want docs/other.md -; want docs/nb.md. -; want $'docs/nb.md\xc2\xa0for' -
 }
 
 @test "isimported answers imported under if for a walk name it does not know (U2a2)" {
@@ -56,17 +57,21 @@
     sp=('\xc2\xa0' '\xe1\x9a\x80' '\xe2\x80\x80' '\xe2\x80\x81' '\xe2\x80\x82' '\xe2\x80\x83' '\xe2\x80\x84'
         '\xe2\x80\x85' '\xe2\x80\x86' '\xe2\x80\x87' '\xe2\x80\x88' '\xe2\x80\x89' '\xe2\x80\x8a' '\xe2\x80\xa8'
         '\xe2\x80\xa9' '\xe2\x80\xaf' '\xe2\x81\x9f' '\xe3\x80\x80' '\xef\xbb\xbf')
-    ps=()
-    for i in "${!sp[@]}"; do printf "@../docs/u$i.md${sp[$i]}x\\n"; ps+=("docs/u$i.md"); done > sub/SKILL.md
+    ps=() ns=()
+    for i in "${!sp[@]}"; do printf "@../docs/u$i.md${sp[$i]}x\\n"; ps+=("docs/u$i.md"); ns+=("docs/u$i.md$(printf "${sp[$i]}")x"); done > sub/SKILL.md
     commit_all spaces
-    imps main "${ps[@]}" docs/other.md
+    # ns: the names run on past each space. Neither walk reads one (precision, as the
+    # title states; a parser that is still a superset may over-read them on purpose).
+    imps main "${ps[@]}" docs/other.md "${ns[@]}"
     [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "main: $output $stderr"; return 1; }
     want walk ok; for p in "${ps[@]}"; do want "$p" imported; done; want docs/other.md -
+    for p in "${ns[@]}"; do want "$p" -; done
     # An untracked start: the tree walk reads it (the main walk fails closed on it until U2a3c).
     printf 'See @k.md\n' > docs/AGENTS.MD
-    imps tree "${ps[@]}" docs/k.md docs/other.md
+    imps tree "${ps[@]}" docs/k.md docs/other.md "${ns[@]}"
     [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "tree: $output $stderr"; return 1; }
     want walk ok; for p in "${ps[@]}" docs/k.md; do want "$p" imported; done; want docs/other.md -
+    for p in "${ns[@]}"; do want "$p" -; done
 }
 
 @test "main walk: main's instruction files start it; a working-tree edit does not count; an untracked start or a checkout file at a path main lacks fails it until U2a3c (U2a2, U2a3 split)" {
@@ -336,7 +341,7 @@
     git update-ref refs/heads/main "$(git commit-tree "$t" -p main -m tree-and-link)"; git checkout -qf main; imps main docs/secret.md; want walk failed; want docs/secret.md imported
 }
 
-@test "both walks read everything Claude Code reads (a superset): an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, ~/ dropped; an @ after a link or code span starts another import; a stray <!-- elsewhere does not shift a splice (U2a3b)" {
+@test "both walks read everything Claude Code reads (a superset): an @ after a Unicode space, Markdown and a code span around a token, ( ) in a name; ~x is over-read, a ~/ name outside the repo dropped; an @ after a link or code span starts another import; a stray <!-- elsewhere does not shift a splice (U2a3b)" {
     mkdir -p docs
     # \x60: a backtick (a code span that closes right after the name). A name
     # holding _ before a code span, <br> or emphasis is still read (my_notes); two
@@ -362,7 +367,7 @@
     done
 }
 
-@test "the superset over-reads, pinned: an @ after a letter, a prefix that is a file, a name led by an escaped space; the work bound fails the walk (U2a3b)" {
+@test "the superset over-reads, pinned: an @ after a letter, a prefix that is a file, a name led by an escaped space; a run that prints past IMPORT_OUT_MAX fails the parser (U2a3b)" {
     # These record the 2026-10-06 over-approximation decision (U2a3b iteration-4
     # gate): Claude Code 2.1.292 reads none of docs/mail.md, docs/pre.md and
     # docs/lead.md (its path filter rejects a name led by a space; emit's trim
@@ -380,8 +385,9 @@
         [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
         want walk ok; for p in "${ps[@]}"; do want "$p" imported; done; want docs/other.md -
     done
-    # Seven 4200-byte runs after an @ pass the candidate-work bound (each prefix's
-    # length is charged; the sixth run trips it): the parser returns 1.
+    # Seven 4200-byte runs after an @: the first run's prefixes alone print past
+    # IMPORT_OUT_MAX, so the parser returns 1 (the candidate-work bound, which
+    # prints nothing, has its own test).
     for i in 1 2 3 4 5 6 7; do printf '@'; head -c 4200 /dev/zero | tr '\0' x; printf '\n'; done > "$BATS_TEST_TMPDIR/heavy.txt"
     run --separate-stderr env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
         import_targets "" < "$2" >/dev/null && echo rc=0 || echo "rc=$?"' _ "$LIB" "$BATS_TEST_TMPDIR/heavy.txt"
@@ -397,7 +403,7 @@
     want walk ok; want notes/x.md imported; want .gitignore imported; want docs/other.md -
 }
 
-@test "both walks fail once the parser has printed more than IMPORT_OUT_MAX bytes in all (U2a3b L2 performance F2)" {
+@test "both walks fail once the parser has printed more than IMPORT_OUT_MAX characters in all (U2a3b L2 performance F2)" {
     mkdir -p docs && printf 'see @docs/a.md\n' > AGENTS.md && commit_all base
     run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
         IMPORT_OUT_MAX=10; imported_names && echo tree ok || echo tree failed; main_imports && echo main ok || echo main failed
@@ -482,13 +488,15 @@
 # deferred hole gets `skip "<its row>"` as its first line, not a deleted assertion.
 @test "both walks read an import that leaves the repo and re-enters it through its parent (FAILS at be94c871: L2 fact-check Claim 1 class 1)" {
     mkdir -p docs sub && n="$(basename "$(pwd -P)")"
-    printf 'See @../%s/docs/re.md\n' "$n" > AGENTS.md
+    # A sibling whose path is as long as the repo's: its docs/sib.md is not the repo's.
+    s="${n%?}x"; [[ "$s" != "$n" ]] || s="${n%?}y"
+    printf 'See @../%s/docs/re.md and @../%s/docs/sib.md\n' "$n" "$s" > AGENTS.md
     printf 'See @../../%s/docs/sub.md\n' "$n" > sub/CLAUDE.md
     commit_all reentry
     for w in tree main; do
-        imps "$w" docs/re.md docs/sub.md docs/other.md
+        imps "$w" docs/re.md docs/sub.md docs/other.md docs/sib.md
         [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
-        want walk ok; want docs/re.md imported; want docs/sub.md imported; want docs/other.md -
+        want walk ok; want docs/re.md imported; want docs/sub.md imported; want docs/other.md -; want docs/sib.md -
     done
 }
 
@@ -530,19 +538,20 @@
     # docs/cs.md (text between two code spans) and docs/dot.md; it never reads "docs/a.md x".
     mkdir -p docs
     { printf '<!-- 0 --> @docs/a<!-- 1 -->b<!-- 2 -->c.md\n'; printf 'See \x60<!--\x60 @docs/cs.md \x60-->\x60\n'
-      printf 'See @./docs/dot.md and @docs/a.md x\n'; } > AGENTS.md
+      printf 'See @./docs/dot.md and @docs/a.md x, @docs/t.md\tx and @docs/r.md\r\n'; } > AGENTS.md
     printf 'x\n' > 'docs/a.md x'
     commit_all splice3
     for w in tree main; do
-        imps "$w" docs/abc.md docs/cs.md docs/dot.md docs/a.md docs/other.md 'docs/a.md x'
+        imps "$w" docs/abc.md docs/cs.md docs/dot.md docs/a.md docs/t.md docs/r.md docs/other.md 'docs/a.md x' $'docs/t.md\tx' $'docs/r.md\r'
         [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
-        want walk ok; for p in docs/abc.md docs/cs.md docs/dot.md docs/a.md; do want "$p" imported; done
-        # Precision, not superset: the false-positive cost the design states (to the first blank).
-        want docs/other.md -; want 'docs/a.md x' -
+        want walk ok; for p in docs/abc.md docs/cs.md docs/dot.md docs/a.md docs/t.md docs/r.md; do want "$p" imported; done
+        # Precision, not superset: the false-positive cost the design states (to the first
+        # blank; a tab and a CR are blanks too, as in JavaScript's \s).
+        want docs/other.md -; want 'docs/a.md x' -; want $'docs/t.md\tx' -; want $'docs/r.md\r' -
     done
 }
 
-@test "the parser fails, not stalls, on one line of many HTML comments (FAILS at be94c871: L2 fact-check Claim 18b; about 10 s)" {
+@test "the parser fails, not stalls, on one line of many HTML comments (FAILS at be94c871: L2 fact-check Claim 18b; a 10 s timeout)" {
     # 320,000 comments in one 2.24 MB line took 27 s with status 0 at be94c871: splice's
     # copying is quadratic and outside the work bound. 124 is timeout's status, not a failure the parser chose.
     { head -c 320000 /dev/zero | sed 's/\x0/<!---->/g'; printf '\n'; } > "$BATS_TEST_TMPDIR/comments.txt"
@@ -598,12 +607,14 @@
 }
 
 @test "IMPORT_OUT_MAX bounds what the whole walk prints, not each file, and a walk that prints exactly the limit passes (U2a3b L2-i2 test-strategy)" {
-    # import_targets prints 13 bytes for each file (a, a., a.m, a.md; 26 in all).
-    printf 'see @a.md\n' > AGENTS.md && printf 'see @b.md\n' > GEMINI.md && commit_all two
+    # import_targets prints 13 bytes for each file (a, a., a.m, a.md; 39 in all). Three
+    # files, not two: the parser gets what is left (IMPORT_LEFT), and a budget that
+    # restarted at each file would look walk-wide until the third.
+    printf 'see @a.md\n' > AGENTS.md && printf 'see @b.md\n' > GEMINI.md && printf 'see @c.md\n' > CLAUDE.md && commit_all three
     run --separate-stderr timeout 60 env LC_ALL=C bash -c 'set -euo pipefail; source "$1"; resolve_main || true; ROOT_REAL="$(pwd -P)"
-        for m in 20 25 26; do IMPORT_OUT_MAX=$m; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""
+        for m in 20 38 39; do IMPORT_OUT_MAX=$m; IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""
             imported_names && echo "$m tree ok" || echo "$m tree failed"; main_imports && echo "$m main ok" || echo "$m main failed"; done' _ "$LIB"
-    [ "$output" = $'20 tree failed\n20 main failed\n25 tree failed\n25 main failed\n26 tree ok\n26 main ok' ] || { echo "$output $stderr"; return 1; }
+    [ "$output" = $'20 tree failed\n20 main failed\n38 tree failed\n38 main failed\n39 tree ok\n39 main ok' ] || { echo "$output $stderr"; return 1; }
 }
 
 @test "the tree walk reads a file of exactly 4 MiB to its last byte, as Claude Code loads it (U2a3b L2-i2 test-strategy)" {
@@ -658,3 +669,62 @@
         for n in 12 13; do printf "see @a.md\n" | IMPORT_LEFT=$n import_targets "" >/dev/null && echo "$n=0" || echo "$n=$?"; done' _ "$LIB"
     [ "$output" = $'12=1\n13=0' ] || { echo "$output $stderr"; return 1; }
 }
+
+@test "the parser fails, not stalls, when one name's candidates pass its work bound though it prints nothing (U2a3b L2-final test-strategy)" {
+    # 10,100 escaped spaces after one @: every candidate trims to nothing, so the
+    # print budget (IMPORT_LEFT) never runs, while the candidates' lengths sum to
+    # about 51 million. About 0.5 s.
+    { printf 'See @'; for i in $(seq 10100); do printf '\\ '; done; printf '\n'; } > "$BATS_TEST_TMPDIR/blank.txt"
+    run --separate-stderr env LC_ALL=C bash -c 'set -uo pipefail; source "$1"; ROOT_REAL="$(pwd -P)"
+        import_targets "" < "$2"; echo "rc=$?"' _ "$LIB" "$BATS_TEST_TMPDIR/blank.txt"
+    [ "$output" = rc=1 ] || { echo "$output $stderr"; return 1; }
+}
+
+@test "the main walk reads a linked worktree nested in the checkout: a sub/.git prefix candidate is skipped (U2a3b L2-final test-strategy)" {
+    # sub/.git is the nested worktree's .git file, which git never stores: a prefix of
+    # @sub/.github/x.md. Without the */.git arm the walk fails on it.
+    mkdir -p notes && printf 'See @sub/.github/x.md and @notes/x.md\n' > GEMINI.md && printf 'x\n' > notes/x.md
+    commit_all nested
+    git worktree add -q --detach sub main
+    imps main notes/x.md sub/.github/x.md docs/other.md
+    [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$output $stderr"; return 1; }
+    want walk ok; want notes/x.md imported; want sub/.github/x.md imported; want docs/other.md -
+}
+
+@test "both walks read ~/ against the passwd entry's home when HOME is empty or unset (U2a3b L2-final test-strategy)" {
+    # Claude Code's runtime (Bun) falls back to the passwd entry for an empty HOME as
+    # for an unset one (L2-final fact-check r1 22b). A getent shim makes the repo's
+    # parent that entry's home.
+    mkdir -p docs && printf 'See @~/%s/docs/home.md\n' "$(basename "$(pwd -P)")" > AGENTS.md && commit_all home
+    G="$BATS_TEST_TMPDIR/getent" && mkdir -p "$G" && printf '#!/bin/sh\necho "u:x:0:0::%s:/bin/sh"\n' "$(cd .. && pwd -P)" > "$G/getent" && chmod +x "$G/getent"
+    oh="$HOME"
+    for w in tree main; do
+        HOME="" PATH="$G:$PATH" imps "$w" docs/home.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w empty: $output $stderr"; return 1; }
+        want walk ok; want docs/home.md imported; want docs/other.md -
+        unset HOME; PATH="$G:$PATH" imps "$w" docs/home.md docs/other.md; export HOME="$oh"
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w unset: $output $stderr"; return 1; }
+        want walk ok; want docs/home.md imported; want docs/other.md -
+    done
+}
+
+@test "both walks read well-formed UTF-8 without python3, which only text holding an invalid sequence needs (U2a3b L2-final test-strategy)" {
+    mkdir -p docs && printf 'Voil\xc3\xa0: @docs/caf\xc3\xa9.md and @docs/a.md\n' > AGENTS.md && commit_all utf8
+    S="$BATS_TEST_TMPDIR/py" && mkdir -p "$S" && printf '#!/bin/sh\nexit 1\n' > "$S/python3" && chmod +x "$S/python3"
+    for w in tree main; do
+        PATH="$S:$PATH" imps "$w" $'docs/caf\xc3\xa9.md' docs/a.md docs/other.md
+        [ "$status" -eq 0 ] && [ -z "$stderr" ] || { echo "$w: $output $stderr"; return 1; }
+        want walk ok; want $'docs/caf\xc3\xa9.md' imported; want docs/a.md imported; want docs/other.md -
+    done
+}
+
+@test "the tree walk fails closed on an imported file it cannot read, when the caller did not set pipefail (U2a3b L2-final test-strategy)" {
+    # As the main walk's unreadable-blob test: head fails, and the walk must not read that as no imports.
+    mkdir -p docs && printf 'see @docs/a.md\n' > AGENTS.md && printf 'see @b.md\n' > docs/a.md && commit_all base
+    chmod 000 docs/a.md
+    run --separate-stderr env LC_ALL=C bash -c 'set -eu; source "$1"; ROOT_REAL="$(pwd -P)"
+        if imported_names; then echo "walk: ok"; else echo "walk: failed"; fi
+        if isimported tree docs/b.md; then echo "docs/b.md: imported"; fi' _ "$LIB"
+    chmod 644 docs/a.md
+    [ "$status" -eq 0 ] && [ "$output" = $'walk: failed\ndocs/b.md: imported' ] || { echo "$status $output $stderr"; return 1; }
+}
```
