Commit: 0bb98f27
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` at 0bb98f27 (base main 62d366a7), loop 2 iteration 3 (final confirming pass). Covers the comments in `scripts/lib/dev-cycle-read.sh`, the test names and comments in `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` A5, and `docs/working/plan-build-loop-handoff.md` F11 and the U2a3, U2a3c and U2b bullets. It also covers the rubric's Loop 2 sections and the override-log rows added since 0170f16a (rows 383-396). Commit messages since 0170f16a are checked in full for 99cce51b, 0bb98f27 and the docs-only commits. 2b22a082 and dfeeb85d get pointers only, because each has an Accepted-immutable row (388, 395).
**Checked:** 2026-10-06
**Replication:** k=3; this is replicate r1 (role `cfc3`, pass `i3`, scratch `/tmp/u2a3-cfc3-i3-jIGM`)
**Total claims checked:** 38 (36 numbered, with 32a/32b and 35a/35b split)
**Summary:** 33 verified, 4 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

## Execution provenance

All commands ran with `TMPDIR=/tmp/u2a3-cfc3-i3-jIGM` (`$S`). Timestamps are UTC on 2026-10-07, which is 2026-10-06 local. Probes ran from cwd `$S/probes`, and each script `cd`s into its own `$S/probes/<name>/repo`. Each probe uses a hermetic git environment (`$S/probes/common.sh`: `GIT_CONFIG_GLOBAL=/dev/null`, `GIT_CONFIG_NOSYSTEM=1`, a private `HOME`). None of them wrote to `/workspace`.

- **X1.** The five suites: `TMPDIR=$S timeout 1500 bats test/scripts/dev-cycle.bats test/scripts/build-loop-read.bats test/scripts/build-loop-check.bats test/scripts/fixture-git-env.bats test/fixture-hermeticity.bats`. Run from cwd `/workspace/.claude/wt-build-loop-u2a3` at 04:03:28Z. Exit 0 with `1..115`: 115 ok, 0 not ok. Output: `$S/bats-five.txt`.
- **X2.** Mutants. `$S/mutate.sh NAME PERL` copies `scripts/` and `test/` to `$S/m-NAME`, edits the copy's lib with `perl -0pi`, and runs `bats test/scripts/build-loop-check.bats` from cwd `$S/m-NAME`. The first batch started at 04:06:33Z (`$S/mutants.txt`) and the second at 04:10:45Z (`$S/mutants2.txt`). Each mutant's diff is in `$S/m-NAME.diff` and its output in `$S/m-NAME.out`. Results (exit code, then failing tests):
  - Killed: ancestor (1: 17), treenl (1: 5), nulcount (1: 9), emptytext (1: 12), gitlink (1: 12), index (1: 3 10), untrnl (1: 7), herestring (1: 10), lsfilesrc (1: 10; the `|| return 1` after the merged listing was dropped).
  - Survived (exit 0, 17/17): starcont (the `*)` arm changed to `continue`; the arm is unreachable, see X3 modes) and dirmemo (the memo `break` removed; an equivalent mutant).
- **X3.** Probes. Every script listed exited 0.
  - `ident.sh` at 04:07:11Z → `ident.txt`
  - `modes.sh` at 04:07:11Z → `modes.txt`
  - `crafted.sh` at 04:07:47Z → `crafted.txt`
  - `slash.sh` at 04:07:55Z → `slash.txt`
  - `ownmain.sh` at 04:08:05Z → `ownmain.txt`
  - `treelink.sh` at 04:10:58Z → `treelink.txt`
  - `misc.sh` at 04:11:09Z → `misc.txt`
  - `timing.sh` at 04:11:48Z → `timing.txt`
  - `convs.sh` at 04:12:42Z → `convs.txt`
- **X4.** A walk in two existing checkouts, at 04:08:14Z, exit 0. In cwd `/workspace` it printed `walk: failed` and listed the ignored `devcontainer-config/claude-home/**` start files that main lacks. In cwd `/workspace/.claude/wt-build-loop-u2a3` it printed `walk: ok`. Both runs only read. Output: `$S/probes/checkouts.txt`.
- **X5.** `git diff --numstat main...HEAD -- . ':!docs'` and `grep -c '^@test'` on each suite. The output is quoted in Claim 34.

I read the hallucination-pattern log (`docs/reviews/hallucination-patterns.md`). Its relevant suspect pattern is a mis-stated test tally ("All 85 tests", "mode1-equiv 33"), so Claim 34 executed the tallies, and they match. This report has no Incorrect verdicts, so the log gets no new entry.

---

## Claim 1: rubric Loop 2 iteration 2: F1 "Memoised ancestor pass ... mutant killed"; F2 "`git rm -qf CLAUDE.md` after those rebuilds ... each mutant killed by its own test"; F5 "gitlink at a start name; a git shim failing `--cached`. The two listings are now one `--cached --others` call"; F7 "`*)` unreachable"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:31-37`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each code claim in the F1, F2, F5 and F7 rows at HEAD. It does not establish the rubric's severity calls or the report tallies (Claim 2).

The ancestor pass exists: `for f in "${!ent[@]}"; do c="$f"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ -z "${dir[$c]+set}" ]] || break; [[ -z "${ent[$c]+set}" ]] || return 1; dir[$c]=1; done; done` (`scripts/lib/dev-cycle-read.sh:565`). Removing it fails test 17 (X2 ancestor). F2's three refusals are each killed by their own test: treenl by test 5, nulcount by test 9 and emptytext by test 12 (X2). The listing is a single call: `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' || return 1` (`:566`). The gitlink-start case is at `test/scripts/build-loop-check.bats:246`, and the gitlink mutant fails test 12. The `--cached` shim is at `:208`, and the lsfilesrc mutant fails test 10. F7 holds: ls-tree prints 100664, 100600 and 100000 as `100644`, prints 000000, 170000 and 140000 as `160000 commit`, and prints 120777 as `120000`. A tree mode pointing at a blob makes ls-tree fail (X3 modes.txt). So `*)` cannot be reached, and starcont survives (X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:565-566`, `:601-602`, `test/scripts/build-loop-check.bats:208`, `:246`, `$S/mutants.txt`, `$S/mutants2.txt`, `$S/probes/modes.txt`

---

## Claim 2: rubric tallies: "56 rows: 40 Verified, 8 Mostly accurate, 7 Incorrect, 1 Unverifiable; agreement 37/51, 72.5%" (iteration 2) and "33 claims: 20 Verified, 11 Mostly accurate, 1 Stale, 0 Incorrect, 1 Unverifiable" (iteration 1)

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:27`, `:45`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the headers of the cited reports. It does not re-derive the merge itself.

The merged report's header reads `**Total claims checked:** 56` / `**Summary:** 40 verified, 8 mostly accurate, 0 stale, 7 incorrect, 1 unverifiable` / `Agreement rate:** 37/51 = 72.5%` (`docs/reviews/code-fact-check-report-build-loop-u2a3-L2-final.md` header). 37/51 is 0.7255. The L2 report's header reads `33` / `20 verified, 11 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable`. The replicate counts 38, 37 and 38 match the headers of `-L2f-r1/-r2/-r3`.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3-L2-final.md:1-12`, `docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md:1-10`

---

## Claim 3: rubric Loop 2 iteration 1: E1 "The walk also lists the checkout's tracked .md files ... test 3 stages CLAUDE.local.md; mutant killed"; E4 "`160000) continue`, any other type fails the walk"; E5 "fixture `zz<LF>CLAUDE.md`; a 67 KB link under `ulimit -f 0` with XFSZ ignored ... both mutants killed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:49-53`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the code and test claims of E1, E4 and E5 at HEAD. It does not establish how they behaved at 5c57d367.

Test 3 runs `git add -f CLAUDE.local.md; imps main docs/guide.md; want walk failed` (`test/scripts/build-loop-check.bats:61`), and the index mutant fails tests 3 and 10 (X2). The arms are `160000) continue ;;` and `*) IMPORTED_MAIN=error; return 1 ;;` (`scripts/lib/dev-cycle-read.sh:601-602`). Test 7 writes `printf 'x\n' > "zz"$'\n'"CLAUDE.md"` (`test/scripts/build-loop-check.bats:140`), and the untrnl mutant fails test 7. The link text is 270 × 254 bytes plus 9, which is 68,589 bytes, or 67.0 KiB (`:214`). The test runs under `trap "" XFSZ; ulimit -f 0` (`:216`), and the herestring mutant fails test 10 (X2).

**Evidence:** `test/scripts/build-loop-check.bats:61`, `:140`, `:214-217`, `scripts/lib/dev-cycle-read.sh:601-602`, `$S/mutants.txt`, `$S/mutants2.txt`

---

## Claim 4: override row 383: "An import target under an unsearchable checkout directory reads as absent, and `git ls-files --others` exits 0 with only a warning on an unreadable directory"

**Location:** `docs/reviews/override-log.md:383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both behaviours at HEAD. It does not establish U2a3c's planned refusal. Row 396 already records the row's missing "unless it is a plain directory" qualifier.

In X3 misc.txt M2, `sec/` has mode 000 and CLAUDE.md imports `@sec/inner/x.md`. The walk printed `walk: ok`, so the path was recorded and not failed. `git ls-files --others` printed `warning: could not open directory 'sec/': Permission denied` and `ls-files --others rc=0`. The probe at `scripts/lib/dev-cycle-read.sh:612` is `[[ -d "$p" && ... ]] || [[ ! -e "$p" && ! -L "$p" ]]`, and both stat tests are false under EACCES.

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `$S/probes/misc.txt`

---

## Claim 5: override row 386: "The parent-link loop (`c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; ...`, main_imports) is O(L x depth)"; row 387: "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:386-387`
**Type:** Performance / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the quoted loop shape, the complexity argument and the grep. It does not re-measure row 386's 9-16 s figure.

The loop at `scripts/lib/dev-cycle-read.sh:611` reads `c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || ...; done`. Each step copies a prefix of length up to L, and the loop runs once per depth level, which gives O(L × depth). A grep finds 0 hits for `GIT_NO_REPLACE_OBJECTS` in the lib and 1 in build-loop.sh: `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1` (`scripts/build-loop.sh:118`) (X3 misc.txt M5).

**Evidence:** `scripts/lib/dev-cycle-read.sh:611`, `scripts/build-loop.sh:118`, `$S/probes/misc.txt`

---

## Claim 6: override row 389: "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk in a primary checkout and in a linked worktree. It does not re-measure the row's C9 timing aside.

In X3 misc.txt M3, CLAUDE.md holds `see @.git`. In the primary checkout the walk printed `walk: ok`, because `.git` is a plain directory there. In `git worktree add` it printed `walk: failed`, because `.git` is a file there and falls into the `! -e` arm of `:612`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `$S/probes/misc.txt`

---

## Claim 7: override row 390: "a name main stores as both a TREE and a SYMLINK ... passed the doubled-name check; `main:l/x.md` read the tree's blob while a checkout writes the link ... Fixed: A pass after the record loop ... (memoised ancestor walk, ~20 ms here)"

**Location:** `docs/reviews/override-log.md:390`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the defect at 1898d21c and at cc1aa864, the fix at HEAD, what a fresh clone writes, and the pass's cost on this repo's main (2,966 entries). It does not establish the cost at other tree sizes.

In X3 treelink.txt, test 17's tree gives `walk: failed` with HEAD's lib. With the libs at 1898d21c and at cc1aa864 it gives `walk: ok` / `docs/secret.md: -`. A fresh clone writes `l` as a `symbolic link` to `docs`, and `l/x.md` reads `@secret.md`. On a fresh clone of this repo's main, the walk took 453-465 ms with the pass and 425-434 ms without it, so the pass costs about 20-30 ms (X3 timing.txt).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-565`, `test/scripts/build-loop-check.bats:306-311`, `$S/probes/treelink.txt`, `$S/probes/timing.txt`

---

## Claim 8: override rows 391, 392: "ISO646-DE turns a stored section sign into `@`: walk ok, `docs/secret.md: -`"; "With `core.symlinks=false` a link's text is written as the file"

**Location:** `docs/reviews/override-log.md:391-392`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's side and the walk's answer for both conversions. It does not establish what Claude Code loads (that is not executed), and it does not cover the other conversions (see Claim 10).

In X3 convs.txt, the blob holds `302 247 d o c s / ...` (UTF-8 `§`) and a fresh clone writes `Rules: @docs/secret.md`. The walk gives `walk: ok` / `docs/secret.md: -`. A `core.symlinks=false` clone writes `CLAUDE.md` as a `regular file` holding `@docs/secret.md`, while the walk records only the path `@docs/secret.md`.

**Evidence:** `$S/probes/convs.txt`

---

## Claim 9: override row 393: "the `*)` record-type arm is unreachable (ls-tree canonicalises modes)"

**Location:** `docs/reviews/override-log.md:393`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight crafted modes tried with git 2.39 here. It does not establish other git versions, and it does not cover macOS or LFS (the row leaves both untested).

See Claim 1: X3 modes.txt shows every crafted mode printed as 100644, 120000 or 160000, or ls-tree failing. The starcont mutant survives (X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:602`, `$S/probes/modes.txt`, `$S/m-starcont.out`

---

## Claim 10: A5: "Not covered: ... checkout conversions that change the bytes git writes from the bytes main stores: a `working-tree-encoding` or `filter` attribute in main's `.gitattributes`, and `core.symlinks=false`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the category and its two listed members, both executed (Claim 8), plus the `ident` and `text eol=crlf` attributes, also executed. It does not establish Claude Code's tokenizer on the `ident` bytes (host not probed).

The category is right, but the enumeration after the colon is not complete. An `ident` attribute also changes the written bytes and splits an import token. In X3 ident.txt, main's `.gitattributes` holds `CLAUDE.md ident`. The blob holds `Rules: @docs/x$Id$`. A fresh clone writes `Rules: @docs/x$Id: 5a7253f4... $`. `import_targets` reads the checkout bytes as `docs/x$Id:` and `docs/x$Id`, but reads the blob as `docs/x$Id$`. Main stores `docs/x$Id`. The walk in the fresh clone answers `walk: ok` / `docs/x$Id: -`. By the lib's own token rules, that path is imported once checked out, so this is a miss beyond the two listed attributes. The L2f security review called `ident` harmless (`docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md:75`: "and treat `ident` as harmless"), and this execution refutes that. `text eol=crlf` is harmless: the blob and checkout token lists are identical (X3 crafted.txt P8). The precise version is: "... a `working-tree-encoding`, `filter` or `ident` attribute ...". No override row covers `ident`; rows 391-392 name only the other two.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `$S/probes/ident.txt`, `$S/probes/crafted.txt` (P8), `docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md:75`

---

## Claim 11: A5's other clauses: what it closes and refuses, "Until U2a3c ... a start file main lacks (untracked, ignored, or only in the checkout's index), a `..` after a checkout link in link text, or anything but a plain directory at an imported path main lacks fails the walk ... a path main lacks that the checkout does not hold is recorded but not walked. A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it"; "start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one)"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal and interim checkout case, the developer-checkout sentence and the start-file gap at HEAD. It does not establish the three Claude Code shapes A5 lists as untraced.

The refusals listed are each pinned by a killed mutant or a passing test (X1, X2; tests 5, 7, 9, 12, 15, 17). The interim cases map to `[[ "${cand[i]:0:1}" == m ]] || return 1` (`scripts/lib/dev-cycle-read.sh:574`), the `-L "$p"` half of `:597` and the probe at `:612`. The walk in `/workspace` printed `walk: failed`, with `main lacks: devcontainer-config/claude-home/CLAUDE.md` and others (X4). The start-file gap holds because the walk lists only `ls-tree -r` (`:557`), which does not enter a symlink or gitlink, and the listing at `:566` (paraphrased — no quote available because the claim is about git's directory traversal, not a snippet: `ls-files --others` reports an untracked nested repo as a directory entry, which the `**/*.md` pathspec does not match).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557`, `:566`, `:574`, `:597`, `:612`, `$S/probes/checkouts.txt`, `$S/bats-five.txt`

---

## Claim 12: F11: "Floor item 1 walks main's commit (`main_imports`, U2a3: NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth as starts; ... fails the walk, so floor refuses every path). Until U2a3c it fails closed on the checkout ... so the gate needs a fresh worktree (U2b) ... Gaps: known issue A5 (... checkout conversions (`working-tree-encoding`/`filter` attributes, `core.symlinks=false`), and three shapes untraced against Claude Code)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk-side clauses (each as in Claims 11, 19 and 20) and the gap list. It does not establish the floor, which U2a4 builds; "floor refuses every path" is plan language.

Every clause matches the code, with one exception: the parenthetical list of checkout conversions omits `ident`, the same omission as Claim 10 (X3 ident.txt). The NUL-safe listings are `nul_list ... ls-tree -r -z` and `ls-files -z` (`scripts/lib/dev-cycle-read.sh:557`, `:566`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:557-612`, `$S/probes/ident.txt`

---

## Claim 13: U2a3 bullet: "It refuses the tree and link shapes it does not model (a doubled name, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink, an imported path main lacks under a directory main stores as a symlink or gitlink) ... and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape. Its "doubled name" covers the tree-and-link case through `:565`. The bullet's checkout list leaves out the `..` after a link only in the checkout. Its symlink clause covers that case by name, and it is tested (test 15, last case). It does not establish the B-row references.

The listed refusals are each pinned by the tests and mutants listed under Claim 11. The bullet's checkout list leaves out the checkout-link `..` case, which A5 lists separately, but the generic "has a `..` after a symlink" clause covers it, so nothing is missing.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-612`, `test/scripts/build-loop-check.bats:292-293`, `$S/mutants.txt`

---

## Claim 14: U2a3c bullet: "every phase-2 item passes one admission check ... before it is marked seen (U2a3 L2 architecture F1, F5)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reference to the L2 architecture review's Findings 1 and 5. It does not cover the bullet's description of a phase 2 that is not built yet, which no code here implements.

The architecture review recommends structuring the walk as "one drain loop run over two seedings" with "Finding 1's admission predicate at the phase-2 seeding" (`docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:136`). It names "`ent`, `seen` and the drain loop itself (Finding 5)" as the state phase 2 shares (`:176`).

**Evidence:** `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:136`, `:176`

---

## Claim 15: U2b bullet: "a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on anything but a plain directory at an imported path main lacks; U2b is to refuse (not built yet; the walk does not check this) a checkout whose `.gitattributes` sets `working-tree-encoding` or `filter` on a path the walk reads, or whose `core.symlinks` is false (A5)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's failures and the "not built yet; the walk does not check this" clause. It does not establish that the planned refusal set is complete: it inherits A5's omission of `ident` (Claim 10), so a gate built to this bullet would still let an `ident` checkout through.

The ignored-start failure is X4's `/workspace` run. A grep finds 0 matches for `check-attr`, `core.symlinks` or `working-tree-encoding` in `scripts/lib/dev-cycle-read.sh` or `scripts/build-loop.sh`. Neither file calls `main_imports` (paraphrased — no quote available because the claim covers absence of code: no matching grep results).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `$S/probes/checkouts.txt`

---

## Claim 16: header: "and so does main_imports (it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every checkout read in `main_imports` (`:566-567`, `:597`, `:612`) and `main_by_name || return 1` (`:556`). It does not cover `imported_names`.

Each checkout read can only fail the walk; none of them adds a path or reads content. The listing only fails at `:567`/`:574`, `-L` only sets `lk` (`:597`), and the probe only fails (`:612`). However, the block above `IMPORTED=` does not list every checkout case. A failing checkout listing (a corrupt index, `nul_list ... ls-files ... || return 1`, `:566`) is a checkout state that fails the walk, and it appears only in the return-1 comment at `:540-541` ("the checkout's .md list (tracked and untracked) cannot be listed whole"). A precise version would read: "the block above IMPORTED= and the comment above main_imports list each case".

**Evidence:** `scripts/lib/dev-cycle-read.sh:29-35`, `:452-476`, `:538-549`, `:556`, `:566-574`, `:597`, `:612`

---

## Claim 17: block comment: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth, which Claude Code also loads) and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. An imported path main lacks is recorded and not read."

**Location:** `scripts/lib/dev-cycle-read.sh:452-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start rule, the follow rule and the record-only rule, and covers no wrong refusal on this repo's own main. It does not establish that Claude Code loads `.claude/rules/` recursively; the comment asserts that as a fact about the host.

The start test is `"${f##*/}" =~ $INSTRUCTION_FILE || "$f" == .claude/rules/*.md || "$f" == */.claude/rules/*.md` on the lower-cased path (`:573`), and bash's `*` there matches `/`. The follow rule is `if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi` (`:609`). Test 6 passes, with symlinks, a chain of two, `pkg/.claude/rules/` and 100755 files (X1). The record-only rule is `IMPORTED_MAIN+="$(lower "$p")"$'\n'` (`:606`), with no read for a path main lacks. A fresh clone of main (62d366a7) and of HEAD each gave `walk: ok` (X3 ownmain.txt), so the walk does not wrongly refuse a normal repo.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571-577`, `:604-613`, `test/scripts/build-loop-check.bats:108-130`, `$S/probes/ownmain.txt`

---

## Claim 18: block comment refusal list: "a name listed twice or as both a file and a directory, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and a start file main lacks (untracked, ignored, or in the checkout's index) fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:457-467`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal, the crafted-tree shapes probed (P1-P7) and the root case. It does not cover link text that leaves the repo and re-enters through the root's own directory name: that text resolves inside the repo, both lexically and in the kernel, and is followed (P7). This is consistent with "leaves the repo" read as "its target leaves".

Each refusal is pinned by a killed mutant or a test (Claims 1, 3, 11). In X3 misc.txt M1, an import of `@.` gives `walk: failed`, which confirms "the root itself included", and `@docs`, a plain directory, gives `walk: ok`. The crafted trees in X3 crafted.txt behave as follows. P1 (two trees named `docs`) fails, because git's lookup reads the first `docs`. P4 (tree plus gitlink) and P5 (tree plus blob) fail through the ancestor pass. P6 (an unsorted root) fails because a lookup misses. P2 and P3 (a literal `docs/x.md` entry name) give `walk: ok` with `docs/secret.md: imported`, and a fresh clone writes that same blob at `docs/x.md` (X3 slash.txt), so they are consistent rather than a miss. Every failure arm in `:583-612` sets `IMPORTED_MAIN=error` before `return 1`, and `isimported` answers 0 on a failed walk (`:626`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-612`, `:626`, `$S/probes/crafted.txt`, `$S/probes/slash.txt`, `$S/probes/misc.txt`

---

## Claim 19: block comment: "A start file answers imported only when an import reaches it"; "Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, checkout conversions (A5), and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:468-473`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the start-file sentence and each named gap as a gap. "Checkout conversions" is stated as a category, which covers the `ident` shape of Claim 10, but A5's enumeration does not list it. It does not establish that no other unlisted gap exists beyond the shapes probed here (X3).

The starts are queued without being recorded (`seen[...]=1; queue+=(...)`, `:575`), and only targets reach `IMPORTED_MAIN` (`:606`). Test 3 asserts `CLAUDE.md -`. `import_targets` drops absolute paths (`[[ ... "$t" != /* ]] || continue`, `:497`). For the other gaps, see Claim 11.

**Evidence:** `scripts/lib/dev-cycle-read.sh:497`, `:575`, `:606`, `test/scripts/build-loop-check.bats:57`, `$S/probes/ident.txt`

---

## Claim 20: block comment: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again. isimported asks either walk."

**Location:** `scripts/lib/dev-cycle-read.sh:474-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the initial value, the cache key and replay, and the reset. While a walk is in progress, IMPORTED_MAIN holds a partial list (`:578`); that is the settled errexit/early-set row, and no caller can observe it.

The variables start as `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""` (`:476`). On a cache hit, the code runs `[[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }` (`:554`). The cache key is never empty, because it holds two spaces and ROOT_REAL. Test 16 expects `- docs/b.md x.sh x.sh - y.sh` and passes (X1). The `case` has `main)` and `tree)` arms (`:626-627`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:476`, `:554-555`, `:626-627`, `test/scripts/build-loop-check.bats:295-304`

---

## Claim 21: nul_list: "array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output was empty or ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four inputs: output ending in NUL, output not ending in NUL, a non-zero exit, and empty output. It does not cover a caller array named `nl_a` (the nameref would collide; no caller uses that name).

In X3 misc.txt M4, each input starts from an array holding `stale`. Output `a\0b\0` gives `rc0 n=2 [a b]`. Output `a\0b` gives `rc1 n=0`. Output `a\0` with exit 3 gives `rc1 n=0`. Empty output gives `rc0 n=0 []`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519`, `$S/probes/misc.txt`

---

## Claim 22: return-1 comment above main_imports (the full list of failure causes, "(even one deleted from the checkout)", "below the root"; "need_root exits instead")

**Location:** `scripts/lib/dev-cycle-read.sh:538-549`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` in `main_imports` (`:556-612`), and finds none unlisted. The record-type cause ("has a type but blob, link or gitlink") is vacuous: it fires only when the walk dequeues such an entry (`:602`), and ls-tree never prints one (Claim 9). The verdict does not establish that `import_targets` failures are caught, which is U2a3b's work.

Each `return 1` maps to a listed cause. `:556` is "main is not found by name". `:557` and `:566` are the two listings. `:559` is a record that does not parse. `:561` is a name listed twice or holding a newline. `:565` is a name that is also a directory. `:567` is a newline in a checkout name. `:570` is a short lower-cased list. `:574` is a start main lacks. Because the listing uses `--cached`, an index entry deleted from the worktree is still listed, which matches "even one deleted from the checkout". `:583` and `:587-588` are a blob that cannot be read and the NUL count. `:590` is empty, newline or absolute text. `:595` is a `..` after a link. `:600` is a target that leaves the repo. `:602` is the type arm. `:611` is a link or gitlink parent. `:612` is "anything but a plain directory below the root", and the root fails (X3 misc.txt M1). `need_root` runs at `:553`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:538-615`, `$S/probes/misc.txt`

---

## Claim 23: ancestor-pass comment: "then a name that is also a directory of another listed name (a crafted tree) fails"

**Location:** `scripts/lib/dev-cycle-read.sh:564-565`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pass's correctness (the memo keeps every ancestor checked against `ent`) and its completeness over `ent`'s names. It covers no wrong refusal on this repo's main. It does not cover names `ent` never holds (tree entries, since `ls-tree -r` omits them); P1 shows a doubled tree name fails through the lookup instead.

`dir[$c]` is set only after `${ent[$c]}` has been tested as unset (`:565`), and the inner loop climbs until it hits a memoised ancestor. A memoised ancestor's own ancestors were all checked when it was first marked, so the `break` skips nothing (paraphrased — no quote available because the invariant is inferred from the loop's two orderings). The dirmemo mutant, which drops the `break`, survives because it is equivalent. The ancestor mutant is killed by test 17 (X2). P4 (tree plus gitlink) and P5 (tree plus blob) fail (X3 crafted.txt). This repo's main gives `walk: ok` (X3 ownmain.txt).

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-565`, `$S/probes/crafted.txt`, `$S/probes/ownmain.txt`, `$S/mutants.txt`

---

## Claim 24: "One tr lower-cases every candidate (lower would fork per path)."

**Location:** `scripts/lib/dev-cycle-read.sh:568-570`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the single `tr` over the NUL-joined list, and `lower`'s per-call fork. It does not establish the cost.

The code runs `mapfile -d '' low < <(printf '%s\0' "${cand[@]}" | tr 'ABC…' 'abc…')` (`:569`). `lower` is `printf '%s' "$1" | tr ...`, which forks a pipeline on every call (`:484`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:484`, `:569`

---

## Claim 25: the record-type arm comments: "a symlink: its text names the file read, as one more import"; "$(...) drops NULs, so they are counted first; the x keeps trailing newlines, which $(...) would also drop."; "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails."; "a gitlink: its files are not main's"

**Location:** `scripts/lib/dev-cycle-read.sh:584-601`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the 120000 and 160000 arms. It does not establish the walk's lexical resolution of `@` tokens through links, which is A5's untraced shape.

The arm reads the link text and passes the resolved `out` through the same per-target loop as imports (`:599`, `:604-613`). The NUL count is `tr -cd '\0' | wc -c` (`:587`); the nulcount mutant is killed by test 9. The `printf x` and `${out%x}` steps are at `:588-589`, and test 7's `notes.md\n` text fails the walk. The `..` check (`:595`) is pinned by test 15's main-link and checkout-link cases. A gitlink start is skipped (`:601`), so test 12's tail gives `walk: ok`, and the gitlink mutant is killed (X2).

**Evidence:** `scripts/lib/dev-cycle-read.sh:584-602`, `test/scripts/build-loop-check.bats:146-152`, `:270-293`, `$S/mutants.txt`

---

## Claim 26: parent-check comment: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail."

**Location:** `scripts/lib/dev-cycle-read.sh:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both checks, every ancestor and the root. It does not cover a path absent from the checkout, which passes, as intended and as the block comment states.

The parent check is `[[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]]` for every ancestor (`:611`). The probe is `[[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]]` (`:612`). Tests 9, 12 and 15 cover both, and the root fails (X3 misc.txt M1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:611-612`, `$S/probes/misc.txt`, `$S/bats-five.txt`

---

## Claim 27: isimported: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses ... the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:616-620`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the main, tree and unknown-name arms. It does not cover callers, because none exists yet.

The code is `main) main_imports || return 0; ...` and `*) return 0 ;;` (`:626-628`). Tests 2, 8 and 14 pass (X1).

**Evidence:** `scripts/lib/dev-cycle-read.sh:621-630`, `test/scripts/build-loop-check.bats:40-44`, `:154-163`, `:260-268`

---

## Claim 28: test file header: "the reader lib's import walks (... isimported, import_targets, main_imports)"; imps: ""walk: ok" or "walk: failed" (main_imports' return; tree always reads ok)"

**Location:** `test/scripts/build-loop-check.bats:3-4`, `:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper's logic. It does not cover the U2a4 and U2b tests, which do not exist yet.

The helper runs `if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi` (`:20`).

**Evidence:** `test/scripts/build-loop-check.bats:13-24`

---

## Claim 29: test 3's name: "main's instruction files start it; a working-tree edit does not count; an untracked start or a checkout file at a path main lacks fails it until U2a3c"

**Location:** `test/scripts/build-loop-check.bats:46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion and its order: no earlier failure masks a later one, because `docs/new.md` is removed before the untracked start is added. The name does not mention the index-only start case at `:61`.

The test asserts `docs/wt-only.md -` after a working-tree edit, then `walk failed` for a regular file at `docs/new.md`, then `walk failed` for an untracked `CLAUDE.local.md` (`:52-61`). The index mutant is killed by this test.

**Evidence:** `test/scripts/build-loop-check.bats:46-62`, `$S/m-index.out`

---

## Claim 30: tests 4-9 and 11-17: names match their assertions, and no refusal is masked by an earlier failure

**Location:** `test/scripts/build-loop-check.bats:64-311`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named refusal: whether some later change to the test would leave its mutant alive. Of the refusals named, only `*)`, which is unreachable, has no killing test. It does not cover test 10 (Claim 32).

Tests 5, 9 and 12 remove the stale index `CLAUDE.md` before their crafted mains (`git rm -qf CLAUDE.md`, `:93`, `:190`, `:241`), and each kills its own mutant. Test 7's empty-text case is masked by the root refusal, because an empty top-level link names `.`, which `:612` fails. That is why test 12 pins empty text below the top level, as its name says ("empty link text below the top level", `:229`), and the emptytext mutant is killed only by test 12 (X2). Test 9's "unreadable too" adds no separate refusal, because the untracked start alone fails the walk. Every named mutant is killed by the test whose name covers it (X2).

**Evidence:** `test/scripts/build-loop-check.bats:79-106`, `:132-152`, `:165-191`, `:229-247`, `:306-311`, `$S/mutants.txt`, `$S/mutants2.txt`

---

## Claim 31: test 1/2 names (U2a2): unchanged by this diff apart from the header

**Location:** `test/scripts/build-loop-check.bats:26`, `:40`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both tests pass at HEAD. It does not re-check the token rules of U2a2.

Both pass in X1.

**Evidence:** `$S/bats-five.txt`

---

## Claim 32a: test 10: "fails closed ... reads a list past 64 KiB under ulimit -f 0"; "Link text past 64 KiB with a .. after main's link l, under ulimit -f 0: the .. check reads it whole"

**Location:** `test/scripts/build-loop-check.bats:193`, `:212-217`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two size claims and that both are pinned. It does not cover the test-name wording (32b).

The import list is 320 × 210 bytes plus 14, which is 67,214 bytes, over 64 KiB. The link text is 68,589 bytes. The herestring mutant is killed by this test, and so is lsfilesrc (X2).

**Evidence:** `test/scripts/build-loop-check.bats:209-217`, `$S/mutants2.txt`

## Claim 32b: test 10's name "when main's tree or the untracked list cannot be listed" and comment "A corrupt index: git ls-files --others fails."

**Location:** `test/scripts/build-loop-check.bats:193`, `:200`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wording against the listing at `:566`. It does not affect what the test asserts.

Since 99cce51b the listing is one `git ls-files -z --cached --others` (`scripts/lib/dev-cycle-read.sh:566`), which lists tracked and untracked files. The test pins this by failing `--cached` with a shim (`:208`). The name and comment still say "the untracked list" and "`ls-files --others`". The precise wording is "the checkout's .md list" and "`ls-files --cached --others`".

**Evidence:** `test/scripts/build-loop-check.bats:193`, `:200`, `:208`, `scripts/lib/dev-cycle-read.sh:566`

---

## Claim 33: dev-cycle.bats inventory adds `main_imports nul_list` and `IMPORTED_MAIN IMPORTED_MAIN_DONE`

**Location:** `test/scripts/dev-cycle.bats:1086`, `:1090`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the inventory names exist after sourcing. It does not cover callers.

The inventory test passes in X1.

**Evidence:** `test/scripts/dev-cycle.bats:1083-1094`, `$S/bats-five.txt`

---

## Claim 34: 99cce51b figures: "Tests: build-loop-check.bats 17; 115 across the five suites. Mutants of the ancestor pass, the tree-name newline check, the NUL count, the empty-text check, the gitlink arm and the index half of the listing each fail. 400 changed code lines against main."

**Location:** `99cce51b` (commit message)
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts and the six named mutants at HEAD. HEAD's code equals 99cce51b's, because 0bb98f27 touches only the plan and a review artifact. It does not establish the mutants' results in other suites.

`grep -c '^@test'` gives 75 + 19 + 17 + 2 + 2 = 115, and X1 reports 115 ok. X5's numstat:

```
117	9	scripts/lib/dev-cycle-read.sh
268	2	test/scripts/build-loop-check.bats
2	2	test/scripts/dev-cycle.bats
```

That sums to 400. All six named mutants are killed: ancestor by test 17, treenl by 5, nulcount by 9, emptytext by 12, gitlink by 12, and index by 3 and 10 (X2).

**Evidence:** `$S/bats-five.txt`, `$S/mutants.txt`

---

## Claim 35a: 99cce51b behavioral bullets: F1 ("a crafted tree listing `l` as a tree and as a symlink passed the doubled-name check (full paths differ), so the walk read the tree's blob while a checkout writes the link ... not a regression"); F2 ("tests 5, 9 and 12 failed on a stale index-only CLAUDE.md before reaching the refusal they name ... they now `git rm -qf CLAUDE.md` first"); F5; "Test lines that only called imps and then want were joined"

**Location:** `99cce51b` (commit message)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers F1 at 1898d21c, at cc1aa864 and at HEAD, and the F2/F5 test changes. It does not establish the pre-fix masking for F2 beyond what the earlier replicate reports executed.

See Claim 7 for F1 (X3 treelink.txt). For F2, see Claim 30. For F5, see Claim 1. `git diff 1898d21c 99cce51b -- test/scripts/build-loop-check.bats` removes 13 lines holding `imps main`, which fits the joined lines.

**Evidence:** `$S/probes/treelink.txt`, `test/scripts/build-loop-check.bats:93`, `:190`, `:241`

## Claim 35b: 99cce51b F3: "the U2b bullet makes the gate refuse them"

**Location:** `99cce51b` (commit message)
**Type:** Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Verification mode:** static
**Scope:** Covers what the plan said at 99cce51b. It does not establish any gate behaviour, because U2b does not exist.

At 99cce51b the U2b bullet read "it also refuses a checkout whose `.gitattributes` sets `working-tree-encoding` or `filter` ... or whose `core.symlinks` is false" (`git show 99cce51b:docs/working/plan-build-loop-handoff.md`, line 279). That is a plan, and no code implements it. 0bb98f27 rewords it as "U2b is to refuse (not built yet ...)". Verifying the claim would need U2b's gate. The refusal set would also miss `ident` (Claim 10).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`

---

## Claim 36: 0bb98f27 "the U2b bullet states the checkout-conversion refusal as U2b's to build ... lite-review fix-drift finding 1 on 99cce51b; output committed"; 1898d21c and 5c57d367 "(no findings)"; 664c18fe "reports, merged fact-check, rubric, override rows"

**Location:** `0bb98f27`, `1898d21c`, `5c57d367`, `664c18fe` (commit messages)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the files each commit touches and the fix-drift outputs. It does not re-run lite-review.

0bb98f27 touches `docs/working/plan-build-loop-handoff.md` (1 line) and `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt`, whose finding 1 is the U2b bullet at `:279`. `lite-review-fix-drift-build-loop-u2a3-L2i1.txt` and `-split.txt` each read `FINDINGS: NONE`. 664c18fe adds the L2f reports, the merged L2-final report, 7 override rows and the rubric section.

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt:1-3`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i1.txt:1`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`

---

Pointers only (Accepted-immutable, not re-verdicted): 2b22a082's message is covered by override row 388 and the earlier rows. dfeeb85d's message is covered by row 395. Rows 384 and 394 are cost figures that this pass did not re-measure; both are Informational Won't-Fix or Defer rows.

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 10** (`docs/working/known-issues-dev-cycle.md:18`): the list of checkout conversions omits `ident`. An `ident` attribute splits `@docs/x$Id$` into `docs/x$Id:` and `docs/x$Id` in a fresh checkout, and the walk answers ok with `docs/x$Id: -` (executed). Add `ident` to the list, or state the class ("any attribute that changes the bytes written").
- **Claim 12** (`docs/working/plan-build-loop-handoff.md:126`): F11's gap list has the same omission.
- **Claim 16** (`scripts/lib/dev-cycle-read.sh:32-34`): "the block above IMPORTED= lists each case". A failing checkout listing appears only in the return-1 comment.
- **Claim 32b** (`test/scripts/build-loop-check.bats:193`, `:200`): "the untracked list" and "`ls-files --others`" predate the merged `--cached --others` listing.

### Unverifiable
- **Claim 35b** (`99cce51b`): "the U2b bullet makes the gate refuse them" describes a planned gate. Verifying it needs U2b's implementation.

## Escalations

- `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126` and `:279` → **author / U2b owner (security-reviewer to confirm).** New evidence not covered by any override row: an `ident` attribute in main's `.gitattributes` is a checkout conversion outside the enumerated `working-tree-encoding`/`filter`/`core.symlinks=false` set. In a fresh clone the walk answers `ok` while the checked-out bytes yield an import the walk does not record (`$S/probes/ident.txt`). This fails open on git's side. Claude Code's side is not probed, but under the lib's own token model it is a miss. It needs a human-reviewed `.gitattributes` change on main. The U2b refusal as currently specified would not catch it. The L2f security review's "treat `ident` as harmless" (`docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md:75`) is refuted. Cheapest fix: add `ident` to A5, F11 and the U2b refusal set, or have U2b refuse any of `working-tree-encoding`, `filter`, `ident` or `text`/`eol` other than LF on a path the walk reads. `text eol=crlf` was executed and is harmless (P8).
- `test/scripts/build-loop-check.bats:193`, `:200` → **author.** Wording only (Claim 32b). The unit is at the 400-line cap, and a name or comment edit changes no line count if it is done in place.

## Goal-Alignment Note

**Success criterion (verbatim):** "A code-fact-check report verdicting every checkable claim in the U2a3 diff's comments, docs and commit messages, saved at the path given below."

**Answered:**
- Every lib comment about `main_imports` (header, block, return-1, nul_list, ancestor pass, record arms, parent check, isimported) is verdicted against code, mutants and probes. Every refusal listed fails the walk, every failure path is listed, and the cache sentence holds.
- The fail-closed probe found one fail-open shape beyond the documented gaps: the `ident` attribute (Claim 10, executed). The crafted-tree shapes probed are each consistent or fail closed: doubled tree names, literal-slash names, tree plus gitlink, tree plus blob, an unsorted root, odd modes, and link text that leaves the repo and re-enters it.
- The ancestor pass is correct and complete over `ent`, with an equivalent memo, and costs about 20-30 ms. The merged listing does not wrongly refuse this repo's own main (`walk: ok` in fresh clones of 62d366a7 and 0bb98f27).
- A5, F11 and the U2a3, U2a3c and U2b bullets are checked.
- Commit figures (17; 115; 400) and all six named mutants are reproduced.
- The test names are checked, and no refusal is masked.
- The rubric's Loop 2 sections and override rows 383-396 are checked.

**Out of scope:** Claude Code's own tokenizer and loader, which no host probe covers (A5's three untraced shapes, and the `ident` bytes on Claude Code's side). U2a3b's parser changes. The cost figures in rows 384 and 394.

**Escalate:** the `ident` conversion gap (see Escalations). It is the only finding with fail-open consequence. It sits in the documented "checkout conversions" class but outside every enumerated member and outside U2b's planned refusal set.
