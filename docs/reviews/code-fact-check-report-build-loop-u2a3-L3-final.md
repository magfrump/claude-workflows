Commit: 0bb98f27
# Code Fact-Check Report

**Repository:** claude-workflows (worktree `/workspace/.claude/wt-build-loop-u2a3`, branch `feat/build-loop-u2a3`)
**Scope:** `git diff main...HEAD` at 0bb98f27 (base main 62d366a7), loop 2 iteration 3 (final confirming pass): the comments in `scripts/lib/dev-cycle-read.sh`, the test names and comments in `test/scripts/build-loop-check.bats` and `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` A5, `docs/working/plan-build-loop-handoff.md` F11 and the U2a3, U2a3c and U2b bullets, the rubric's Loop 2 sections, the override rows added since 0170f16a, and the commit messages since 0170f16a. Merged (most-severe-wins, annotations by union) from replicates `code-fact-check-report-build-loop-u2a3-L3-r1.md`, `-r2.md` and `-r3.md`.
**Checked:** 2026-10-06
**Commit:** 0bb98f27
**Replication:** k=3
**Total claims checked:** 62
**Summary:** 53 verified, 9 mostly accurate, 0 stale, 0 incorrect, 0 unverifiable

Merge notes. Clusters are emitted at the finest granularity any replicate used; a replicate that verdicted only a compound claim is recorded on each sub-claim row as `(compound)`. Replicate-local claim numbers inside carried text are rewritten as merged claim numbers. Scratch directories, as each replicate reported them: r1 `/tmp/u2a3-cfc3-i3-jIGM`, r2 `/tmp/u2a3-cfc3-i3-irp4`, r3 `/tmp/u2a3-cfc3-i3-3sch`; evidence paths below are written out in full. Each replicate's execution provenance (run commands, cwd, exit codes, timestamps) is in its own report. All three replicates read the hallucination-pattern log; none added an entry (no Incorrect verdict). Every replicate ran the five suites at HEAD: 115 ok, 0 not ok.

---

## Claim 1a: rubric Loop 2 iteration 2 F1: "A name main stores as both a tree and a symlink ... passed the doubled-name check ... Not a regression (same at cc1aa864)"; fixed by a "Memoised ancestor pass after the record loop ... mutant killed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:31`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's answer at HEAD, at cc1aa864 and at 2b22a082 on test 17's crafted tree, and the ancestor-pass mutant. It does not establish the rubric's report counts or agreement figures, though 40+8+7+1=56 and 37/51=72.5% are arithmetically consistent.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish the rubric's severity calls or the report tallies" · r2: "does not establish the rubric's severity labels or the reviewer-attribution lists" · r2: also ran test 17 against 664c18fe's lib (`walk: ok` / `docs/secret.md: -`) and saw a checkout write `l -> docs` while `main:l/x.md` prints `plain`

Test 17 fails against cc1aa864's lib and against 2b22a082's lib: both answer `walk: ok`, and the test wants `walk failed`. At HEAD it passes. Removing the `ent` check from the ancestor pass (`scripts/lib/dev-cycle-read.sh:565`) kills test 17 at line 310.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-565`, `test/scripts/build-loop-check.bats:306-311`, `/tmp/u2a3-cfc3-i3-3sch/logs/old-cc1aa864.out`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft-ancestor.log`, `/tmp/u2a3-cfc3-i3-3sch/logs/mutants.summary`

---

## Claim 1b: rubric F2: "Three refusals masked since dfeeb85d's index listing (newline in a tree name, NUL in link text, empty link text): tests 5, 9, 12 left a stale CLAUDE.md in the index" — fixed: "`git rm -qf CLAUDE.md` after those rebuilds ...; each mutant killed by its own test"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:32`
**Type:** Behavioral (tests)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the three named refusals, with and without the unmask lines. It does not establish that no other refusal in the suite is masked: test 10's tree-listing refusal is (merged Claim 37b).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish the rubric's severity calls or the report tallies" · r2: "does not establish the rubric's severity labels or the reviewer-attribution lists" · r2: the three mutants pass all 16 of 664c18fe's tests (masked there) and are killed at HEAD

With the three `git rm -qf CLAUDE.md` suffixes removed from a suite copy, the treenl, nulcount and emptytext mutants all pass the suite. With the suffixes kept, each is killed by its own test: treenl by 5:105, nulcount by 9:190, emptytext by 12:243.

**Evidence:** `test/scripts/build-loop-check.bats:91`, `:189`, `:242`, `/tmp/u2a3-cfc3-i3-3sch/logs/mask.summary`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft.summary`

---

## Claim 1c: rubric F5 "The gitlink arm and a failing `ls-files --cached` were unpinned ... Fixed: gitlink at a start name; a git shim failing `--cached`. The two listings are now one `--cached --others` call"; F7 "`*)` unreachable"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:35-37`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the merged listing, the gitlink arm's pin and the `--cached` failure pin. It also covers the `*)` arm's unreachability for the modes `ls-tree -r` prints, including from non-canonical modes. It does not establish behavior under a git version other than 2.39.5.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: "does not establish the rubric's severity calls or the report tallies" · r2: "does not establish the rubric's severity labels or the reviewer-attribution lists" · r1: F7 checked over eight crafted modes (100664, 100600, 100000 print as 100644; 000000, 170000, 140000 as 160000; 120777 as 120000; a tree mode on a blob makes ls-tree fail); the starcont mutant survives

The listing is one call (`scripts/lib/dev-cycle-read.sh:566`). The gitlinkarm mutant flips 12:246, the ckfail mutant (`:566 || true`) flips 10:202 and 10:206, and the starterr mutant (`*) continue`) flips nothing. Crafted modes `100664` and `40755` list as `100644` and a recursed tree.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566`, `:601-602`, `test/scripts/build-loop-check.bats:206`, `:246`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft.summary`, `/tmp/u2a3-cfc3-i3-3sch/logs/p3.out`

---

## Claim 2: rubric tallies: "56 rows: 40 Verified, 8 Mostly accurate, 7 Incorrect, 1 Unverifiable; agreement 37/51, 72.5%" (iteration 2) and "33 claims: 20 Verified, 11 Mostly accurate, 1 Stale, 0 Incorrect, 1 Unverifiable" (iteration 1)

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:27`, `:45`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers agreement with the headers of the cited reports. It does not re-derive the merge itself.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r3 (in its F1 row's scope): "does not establish the rubric's report counts or agreement figures, though 40+8+7+1=56 and 37/51=72.5% are arithmetically consistent"

The L2-final header reads 56 / `40 verified, 8 mostly accurate, 0 stale, 7 incorrect, 1 unverifiable` / `37/51 = 72.5%`; the L2 header reads 33 / `20 verified, 11 mostly accurate, 1 stale, 0 incorrect, 1 unverifiable`.

**Evidence:** `docs/reviews/code-fact-check-report-build-loop-u2a3-L2-final.md:1-12`, `docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md:1-10`

---

## Claim 3: rubric Loop 2 iteration 1: E1 "test 3 stages CLAUDE.local.md; mutant killed"; E2 "Ignored instruction files fail the walk (35 in /workspace's own checkout)"; E4 "`160000) continue`, any other type fails the walk"; E5 "fixture `zz<LF>CLAUDE.md`; a 67 KB link under `ulimit -f 0` with XFSZ ignored ... both mutants killed"

**Location:** `docs/reviews/code-review-rubric-2026-10-06-feat-build-loop-u2a3.md:49-53`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the four rows' claims about the code and tests at HEAD and the current count of start-shaped untracked/ignored .md files in /workspace; does not establish the count at the time the row was written beyond its agreement with today's count.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not establish how they behaved at 5c57d367" (r1 did not verdict E2) · r3: "does not cover the critics' severities or E3's wording items" · r1+r2: E5 link text computed as 270 × 254 + 9 = 68,589 bytes · r3: computed as 270 × 253 bytes plus `l/../t.md` = 68,319 bytes; all three agree it is about 67 KB

E1: dropping `--cached` from `:566` fails test 3 at `git add -f CLAUDE.local.md; ... want walk failed`. E2: 35 start-shaped names in /workspace's `--others` list, the first `devcontainer-config/claude-home/CLAUDE.md`. E4: the arms at `:601-602`. E5: test 7 writes `zz<LF>CLAUDE.md` (`:140`); the newline-check mutant fails test 7 and the here-string revert fails test 10, which runs under `trap "" XFSZ; ulimit -f 0`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-574`, `scripts/lib/dev-cycle-read.sh:601-602`, `test/scripts/build-loop-check.bats:140`, `test/scripts/build-loop-check.bats:211-216`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-indexhalf.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-checkoutnl.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-herestring.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`

---

## Claim 4: override row 383: "An import target under an unsearchable checkout directory reads as absent, and `git ls-files --others` exits 0 with only a warning on an unreadable directory"

**Location:** `docs/reviews/override-log.md:383`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both behaviours at HEAD. It does not establish U2a3c's planned refusal. Row 396 already records the row's missing "unless it is a plain directory" qualifier.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

With `sec/` at mode 000 and CLAUDE.md importing `@sec/inner/x.md`, the walk printed `walk: ok`; `git ls-files --others` printed `warning: could not open directory 'sec/': Permission denied` and exited 0. Both stat tests in the probe at `:612` are false under EACCES.

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `/tmp/u2a3-cfc3-i3-jIGM/probes/misc.txt`

---

## Claim 5a: override row 386: "The parent-link loop ... is O(L x depth) ... Slow, never fail-open; only text committed to main reaches it after the split"

**Location:** `docs/reviews/override-log.md:386`
**Type:** Performance / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the claims "never fail-open" and "only main's text reaches the loop". It does not re-measure the 9-16 s figure.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: verified the quoted loop shape and the O(L × depth) argument (each step copies a prefix up to L, once per depth level)

The loop's input `p` comes only from `out`, computed from `git cat-file blob "$MAIN_SHA:$f"` (`:583`, `:587-600`); the loop's one exit is a failure (`:611`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:583-613`

---

## Claim 5b: override row 387: "the lib does not set GIT_NO_REPLACE_OBJECTS; build-loop.sh exports it"

**Location:** `docs/reviews/override-log.md:387`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers where the variable is set in the lib and build-loop.sh; does not establish whether replace refs can bypass the walk (the row's own Defer).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none

A grep finds only `scripts/build-loop.sh:118`: `export GIT_LITERAL_PATHSPECS=1 GIT_NO_REPLACE_OBJECTS=1`; the lib has no match.

**Evidence:** `scripts/build-loop.sh:118`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`

---

## Claim 6: override row 389: "In a clean linked worktree `.git` is a file, so an instruction file importing `@.git` now fails the walk"

**Location:** `docs/reviews/override-log.md:389`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk in a primary checkout and in a linked worktree. It does not re-measure the row's C9 timing aside.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** none

In the primary checkout the walk printed `walk: ok` (`.git` a plain directory); in a `git worktree add` worktree it printed `walk: failed`, because `.git` is a file there and falls into the `! -e` arm of `:612`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `/tmp/u2a3-cfc3-i3-jIGM/probes/misc.txt`

---

## Claim 7: override row 390: "a name main stores as both a TREE and a SYMLINK ... passed the doubled-name check; `main:l/x.md` read the tree's blob while a checkout writes the link ... Fixed: A pass after the record loop ... (memoised ancestor walk, ~20 ms here)"

**Location:** `docs/reviews/override-log.md:390`
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the defect at 1898d21c and at cc1aa864, the fix at HEAD, what a fresh clone writes, and the pass's cost on this repo's main (2,966 entries). It does not establish the cost at other tree sizes.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified
**Replicate annotations:** r2: quoted this row's text inside its rubric F1 claim (Location the rubric, merged Claim 1a) and verdicted it Verified there · r1: pass cost about 20-30 ms (453-465 ms with, 425-434 ms without) · r3: 20, 18 and 18 ms on 2966 entries and 368 directories

Test 17's tree gives `walk: failed` with HEAD's lib and `walk: ok` / `docs/secret.md: -` with the libs at 1898d21c and cc1aa864. A fresh clone writes `l` as a symbolic link to `docs`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-565`, `test/scripts/build-loop-check.bats:306-311`, `/tmp/u2a3-cfc3-i3-jIGM/probes/treelink.txt`, `/tmp/u2a3-cfc3-i3-jIGM/probes/timing.txt`

---

## Claim 8: override rows 391, 392 (byte effects): "ISO646-DE turns a stored section sign into `@`: walk ok, `docs/secret.md: -`"; "With `core.symlinks=false` a link's text is written as the file"

**Location:** `docs/reviews/override-log.md:391-392`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git's side and the walk's answer for both conversions. It does not establish what Claude Code loads (that is not executed), and it does not cover the other conversions (see merged Claim 14e).
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r3 (its claim on the same rows): "does not establish the ISO646-DE byte effect, which was not re-run"

The blob holds UTF-8 `§docs/...` and a fresh clone writes `Rules: @docs/secret.md`; the walk gives `walk: ok` / `docs/secret.md: -`. A `core.symlinks=false` clone writes `CLAUDE.md` as a regular file holding `@docs/secret.md`.

**Evidence:** `/tmp/u2a3-cfc3-i3-jIGM/probes/convs.txt`

---

## Claim 9: override rows 391, 392 (gate wording): "`check-attr --source` needs git 2.40 ... the U2b bullet makes the gate refuse such a checkout"; "T42's config refusals do not list it yet ... the U2b bullet makes the gate refuse it"

**Location:** `docs/reviews/override-log.md:391-392`
**Type:** Reference / Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers git 2.39.5 rejecting `--source`, T42's text, and what the U2b bullet says. It does not establish the ISO646-DE byte effect, which was not re-run.
**Replicate verdicts:** r1=— · r2=— · r3=Mostly accurate · single-replicate detection
**Replicate annotations:** none

git 2.39.5 answers ``error: unknown option `source'``. T42 does not list `core.symlinks` (`docs/working/plan-build-loop-handoff.md:347`). The U2b bullet reads "U2b is to refuse (not built yet; the walk does not check this)" (`:279`). Nothing is built yet, so "makes the gate refuse" should read "asks U2b to make the gate refuse". The log is append-only; the bullet itself is now precise.

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `:347`, `/tmp/u2a3-cfc3-i3-3sch/logs/p5.out`

---

## Claim 10: override row 393: "the `*)` record-type arm is unreachable (ls-tree canonicalises modes)"

**Location:** `docs/reviews/override-log.md:393`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the eight crafted modes tried with git 2.39 here. It does not establish other git versions, and it does not cover macOS or LFS (the row leaves both untested).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "does not exhaust every 6-digit mode"; a mode-100644 entry naming a tree object reaches the walk as `100644 blob` and fails at `git cat-file blob`, not at `*)`

Every crafted mode printed as 100644, 120000 or 160000, or ls-tree failed. The starcont mutant survives.

**Evidence:** `scripts/lib/dev-cycle-read.sh:602`, `/tmp/u2a3-cfc3-i3-jIGM/probes/modes.txt`, `/tmp/u2a3-cfc3-i3-jIGM/m-starcont.out`

---

## Claim 11: override row 394: "The checkout listing and its loop cost ~17 ms here"

**Location:** `docs/reviews/override-log.md:394`
**Type:** Performance
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the listing call alone on a fresh main worktree (1452 names, 14 ms). It does not cover the loop's own time or the +150 ms at 20k figure.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r1: "Rows 384 and 394 are cost figures that this pass did not re-measure" · r2: performance figures in override rows out of scope ("performance critic's")

The listing gave `listing: 1452 names, 14 ms`, the same order as ~17 ms with the loop included.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-567`, `/tmp/u2a3-cfc3-i3-3sch/logs/p5.out`

---

## Claim 12: override row 395: dfeeb85d's "tests 9 and 3 renamed" — "(only test 9)"

**Location:** `docs/reviews/override-log.md:395`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` names at 2b22a082 and dfeeb85d; does not re-verdict dfeeb85d's message (Accepted-immutable).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** r1+r3: cite row 395 as the Accepted-immutable pointer for dfeeb85d's message

A diff of the `@test` lines between 2b22a082 and dfeeb85d shows one change, test 9.

**Evidence:** `test/scripts/build-loop-check.bats:165`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-rubric.txt`

---

## Claim 13: override row 396: "The C3 row's 'fails the walk if present' omits 'unless it is a plain directory'"

**Location:** `docs/reviews/override-log.md:396`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the plain-directory allowance. It does not cover the unsearchable-directory case, which is settled and deferred to U2a3c.
**Replicate verdicts:** r1=— · r2=— · r3=Verified · single-replicate detection
**Replicate annotations:** r1 (on row 383): "Row 396 already records the row's missing 'unless it is a plain directory' qualifier"

`:612`'s first arm admits a plain directory; the plaindirallow mutant flips 9:185 (`mkdir docs/lt.md` → `want walk ok`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:612`, `test/scripts/build-loop-check.bats:184-185`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft-plaindirallow.log`

---

## Claim 14a: A5: the walk follows symlinked start files and targets on main, starts `.claude/rules/` at any depth, and fails on "a name listed twice or as both a file and a directory, a name holding a newline", link text "that is empty, absolute, leaves the repo, holds a newline or NUL or has a `..` after a symlink", and "an imported path main lacks under a directory main stores as a symlink or gitlink"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal (each has a mutant that the suite kills) and the follow/start behaviour of test 6; does not establish how Claude Code itself resolves the three untraced shapes A5 lists.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r3: "does not establish the floor's use of the walk (U2a4, unbuilt)"

Mutants at HEAD each fail a named test: dupname 5, ancestor 17, treenl 5, emptytext 12, absolute 7, leaves 7, lk 10 and 15, nulcount 9, gitlink parent 12, immediate-parent loop 15. Extra crafted shapes (a slash-named root entry beside a link, a gitlink beside a tree, two trees named `docs`) all fail.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-565`, `scripts/lib/dev-cycle-read.sh:587-600`, `scripts/lib/dev-cycle-read.sh:611`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft2.txt`

---

## Claim 14b: A5 "Until U2a3c the walk reads main's commit only and fails closed on the checkout: a start file main lacks (untracked, ignored, or only in the checkout's index), a `..` after a checkout link in link text, or anything but a plain directory at an imported path main lacks fails the walk ..., and a path main lacks that the checkout does not hold is recorded but not walked"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the untracked, ignored, index-only (including deleted from the checkout) and checkout-link cases, and the record-not-walk case. It does not cover the settled git-hardening bypasses (GIT_INDEX_FILE, fsmonitor, sparse checkout), deferred to U2b.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r2: "does not establish what U2a3c will do"; also probed FIFOs, files, symlinks and the root at imported paths main lacks, and untracked rules files at depth

An index-only CLAUDE.local.md deleted from the checkout and an ignored one each give `walk: failed`. The start rule is `:574`. A `..` after a link only the checkout has flips 15:292 (cklinkL). A path main lacks that is absent from the checkout answers imported with walk ok (test 3, `docs/new.md`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-577`, `:597`, `:612`, `test/scripts/build-loop-check.bats:46-62`, `/tmp/u2a3-cfc3-i3-3sch/logs/p2.out`

---

## Claim 14c: A5 "A developer checkout with ignored instruction files (here, `devcontainer-config/claude-home/`) therefore always fails it; the gate needs a fresh worktree until U2a3c"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers /workspace's ignored start files and a fresh main worktree walking ok. It does not run the walk inside /workspace itself, because the shared rules forbid cd there.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** r1: ran the walk read-only with cwd `/workspace`: `walk: failed`, listing `main lacks: devcontainer-config/claude-home/CLAUDE.md` and others; in the u2a3 worktree `walk: ok` · r2: 35 start-shaped untracked/ignored files under `devcontainer-config/claude-home/`, each refused at `:574`

/workspace's `--others` .md list holds 35 start-shaped names, and `devcontainer-config/claude-home/CLAUDE.md` is ignored. Each is a start main lacks, so `:574` returns 1. A fresh detached worktree at main answers `walk ok` with 3 imports in 0.47 s.

**Evidence:** `scripts/lib/dev-cycle-read.sh:574`, `/tmp/u2a3-cfc3-i3-3sch/logs/p5.out`, `/tmp/u2a3-cfc3-i3-3sch/logs/p1.out`

---

## Claim 14d: A5 "Not covered: start files under a symlinked directory or in a submodule or untracked nested repo (neither `ls-tree -r` nor `ls-files --others` enters one), other names one file has on a case-insensitive checkout, absolute imports into the repo ... Untraced against Claude Code: ..." (gaps other than checkout conversions)

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the parenthetical (executed) and the completeness of the list against this pass's probes (crafted trees via `hash-object --literally`, non-canonical modes, slash-named entries, doubled trees, root and `.git` imports, FIFOs, deleted index entries, ignored directories, this repo's own main); does not establish completeness against Claude Code's real loader (no host probe) or against filesystems other than Linux ext4/overlay.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r1+r3: does not establish Claude Code's behaviour on the three shapes A5 lists as untraced · r1: an untracked nested repo is reported by `ls-files --others` as a directory entry, which the `**/*.md` pathspec does not match (paraphrased by r1) · r3: the walk's side of each gap checked statically (target's directory from the queued name, `:581`; lexical `realpath -ms`, `:503`; absolute imports dropped, `:502`)

`ls-files -z --cached --others` in a repo with `lnk -> real` and an untracked nested repo lists only `real/CLAUDE.md`, and a main whose `.claude/rules` is a symlink to `../shared` walks ok with `shared/secret.md: -`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:557`, `scripts/lib/dev-cycle-read.sh:566`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-misc.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft2.txt`

---

## Claim 14e: A5 "Not covered: ... checkout conversions that change the bytes git writes from the bytes main stores: a `working-tree-encoding` or `filter` attribute in main's `.gitattributes`, and `core.symlinks=false`"

**Location:** `docs/working/known-issues-dev-cycle.md:18`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the category and its two listed members, both executed (merged Claim 8), plus the `ident` and `text eol=crlf` attributes, also executed. It does not establish Claude Code's tokenizer on the `ident` bytes (host not probed).
**Replicate verdicts:** r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: "No probe found a tree or checkout state, beyond these and the settled rows, where the walk answers ok and misses an import a fresh checkout of main would load"; "does not establish completeness against Claude Code's real loader" · r3: "No main tree, crafted tree or checkout state was found where the walk answers ok while a fresh checkout of main gives Claude Code an import the walk misses, beyond the documented and settled gaps" · r1: escalated (see Escalations); the L2f security review's "treat `ident` as harmless" (`docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md:75`) is refuted by r1's execution; `text eol=crlf` executed and harmless (P8)

The category is right, but the enumeration is not complete. With `CLAUDE.md ident` in main's `.gitattributes` and a blob holding `Rules: @docs/x$Id$`, a fresh clone writes `Rules: @docs/x$Id: 5a7253f4... $`. `import_targets` reads the checkout bytes as `docs/x$Id:` and `docs/x$Id`, the blob as `docs/x$Id$`; the walk answers `walk: ok` / `docs/x$Id: -`. Precise version: "... a `working-tree-encoding`, `filter` or `ident` attribute ...". No override row covers `ident`.

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `/tmp/u2a3-cfc3-i3-jIGM/probes/ident.txt`, `/tmp/u2a3-cfc3-i3-jIGM/probes/crafted.txt`, `docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md:75`

---

## Claim 15: F11: "Floor item 1 walks main's commit (`main_imports`, U2a3: NUL-safe listings, symlinks on main followed, `.claude/rules/` at any depth as starts; ... fails the walk, so floor refuses every path). Until U2a3c it fails closed on the checkout ... so the gate needs a fresh worktree (U2b) ... Gaps: known issue A5 (... checkout conversions (`working-tree-encoding`/`filter` attributes, `core.symlinks=false`), and three shapes untraced against Claude Code)"

**Location:** `docs/working/plan-build-loop-handoff.md:126`
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk-side clauses (each as in merged Claims 14a-14d, 22a and 23) and the gap list. It does not establish the floor, which U2a4 builds; "floor refuses every path" is plan language.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not treat F11's refusal list as exhaustive (it names the file-and-directory shape only under 'a doubled name', which the crafted tree of test 17 is at the tree-object level, while a slash-named entry beside a link is refused but not named)"

Every clause matches the code, with one exception: the parenthetical list of checkout conversions omits `ident`, the same omission as merged Claim 14e. The NUL-safe listings are `nul_list ... ls-tree -r -z` and `ls-files -z` (`:557`, `:566`).

**Evidence:** `docs/working/plan-build-loop-handoff.md:126`, `scripts/lib/dev-cycle-read.sh:557-612`, `/tmp/u2a3-cfc3-i3-jIGM/probes/ident.txt`

---

## Claim 16: U2a3 bullet: "It refuses the tree and link shapes it does not model (...) ... and fails closed on the checkout (a start file main lacks, or anything but a plain directory at an imported path main lacks)"

**Location:** `docs/working/plan-build-loop-handoff.md:276`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed shape. Its "doubled name" covers the tree-and-link case through `:565`. The bullet's checkout list leaves out the `..` after a link only in the checkout. Its symlink clause covers that case by name, and it is tested (test 15, last case). It does not establish the B-row references.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: the same non-exhaustiveness note as F11 (merged Claim 15) applies; does not verify Q-119 references

The listed refusals are each pinned by the tests and mutants of merged Claims 14a and 36c. The start rule is `:573`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:561-612`, `test/scripts/build-loop-check.bats:292-293`, `/tmp/u2a3-cfc3-i3-jIGM/mutants.txt`

---

## Claim 17: U2a3c bullet: "every phase-2 item passes one admission check ... before it is marked seen (U2a3 L2 architecture F1, F5)"

**Location:** `docs/working/plan-build-loop-handoff.md:277`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the reference to the L2 architecture review's Findings 1 and 5. It does not cover the bullet's description of a phase 2 that is not built yet, which no code here implements.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** r2 (out of scope): "U2a3c's plan bullet (design for unbuilt code, verdicted only where it states current behaviour)" · r3: "The U2a3c bullet is a plan with no code to check"

The architecture review recommends "Finding 1's admission predicate at the phase-2 seeding" (`:136`) and names "`ent`, `seen` and the drain loop itself (Finding 5)" (`:176`).

**Evidence:** `docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md:136`, `:176`

---

## Claim 18: U2b bullet: "a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ignored ones included, and on anything but a plain directory at an imported path main lacks; U2b is to refuse (not built yet; the walk does not check this) a checkout whose `.gitattributes` sets `working-tree-encoding` or `filter` on a path the walk reads, or whose `core.symlinks` is false (A5)"

**Location:** `docs/working/plan-build-loop-handoff.md:279`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the walk's failures and the "not built yet; the walk does not check this" clause. It does not establish that the planned refusal set is complete: it inherits A5's omission of `ident` (merged Claim 14e), so a gate built to this bullet would still let an `ident` checkout through.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2+r3: does not establish U2b's future refusal or design · r2: no script outside the lib calls `main_imports` or `isimported main`

The ignored-start failure is executed. A grep finds 0 matches for `check-attr`, `core.symlinks` or `working-tree-encoding` in the lib or `scripts/build-loop.sh` (paraphrased by r1 — absence of code).

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `/tmp/u2a3-cfc3-i3-jIGM/probes/checkouts.txt`

---

## Claim 19: header: "and so does main_imports (it reads the checkout only to fail, until U2a3c, so the gate needs a fresh worktree; the block above IMPORTED= lists each case; it needs resolve_main to have found main by name)"

**Location:** `scripts/lib/dev-cycle-read.sh:29-35`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers every checkout read in `main_imports` (`:566-567`, `:597`, `:612`) and `main_by_name || return 1` (`:556`). It does not cover `imported_names`.
**Replicate verdicts:** r1=Mostly accurate · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that the gate's caller provides a fresh worktree (U2b's)" · r3: "does not cover git hardening (the caller's job, settled)"; `-L` probes outside the repo also only add a failure

Each checkout read can only fail the walk. However, the block above `IMPORTED=` does not list every checkout case: a failing checkout listing (`nul_list ... ls-files ... || return 1`, `:566`) appears only in the return-1 comment at `:540-541`. Precise version: "the block above IMPORTED= and the comment above main_imports list each case".

**Evidence:** `scripts/lib/dev-cycle-read.sh:29-35`, `:452-476`, `:538-549`, `:556`, `:566-574`, `:597`, `:612`

---

## Claim 20: block comment: "it starts at every instruction file stored there (and every .md under a .claude/rules/ directory at any depth, which Claude Code also loads) and follows an import into the file main stores at that path, whatever its name; a symlink there is followed to the path its text names. An imported path main lacks is recorded and not read."

**Location:** `scripts/lib/dev-cycle-read.sh:452-457`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start rule, the follow rule and the record-only rule, and covers no wrong refusal on this repo's own main. It does not establish that Claude Code loads `.claude/rules/` recursively; the comment asserts that as a fact about the host.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish that INSTRUCTION_FILE matches Claude Code's own loader list" · r3: does not establish the untraced shapes

The start test is at `:573`; the follow rule at `:609`; the record-only rule at `:606`. Test 6 passes. Fresh clones of main (62d366a7) and HEAD each gave `walk: ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:571-577`, `:604-613`, `test/scripts/build-loop-check.bats:108-130`, `/tmp/u2a3-cfc3-i3-jIGM/probes/ownmain.txt`

---

## Claim 21: block comment refusal list: "a name listed twice or as both a file and a directory, a name holding a newline, symlink text that is empty, absolute, leaves the repo, holds a newline or a NUL, or has a .. after a symlink (on main or in the checkout), an imported path main lacks that lies under a directory main stores as a symlink or gitlink, or that the checkout holds as anything but a plain directory (the root itself included), and a start file main lacks (untracked, ignored, or in the checkout's index) fail the walk, so isimported main answers imported for every path"

**Location:** `scripts/lib/dev-cycle-read.sh:457-467`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each listed refusal, the crafted-tree shapes probed (P1-P7) and the root case. It does not cover link text that leaves the repo and re-enters through the root's own directory name: that text resolves inside the repo, both lexically and in the kernel, and is followed (P7). This is consistent with "leaves the repo" read as "its target leaves".
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish behaviour when a helper (`lower`, `grep`, `sed`) fails inside the drain loop with errexit off (U2a3b's, stacked; settled errexit row)" · r3: "does not establish completeness against Claude Code beyond the documented gaps; no fail-open was found"

Each refusal is pinned by a killed mutant or a test. An import of `@.` gives `walk: failed`; `@docs` gives `walk: ok`. Crafted trees P1, P4, P5, P6 fail; P2/P3 (literal `docs/x.md` entry) are consistent with what a clone writes. Every failure arm sets `IMPORTED_MAIN=error` before `return 1`, and `isimported` answers 0 on a failed walk (`:626`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:557-612`, `:626`, `/tmp/u2a3-cfc3-i3-jIGM/probes/crafted.txt`, `/tmp/u2a3-cfc3-i3-jIGM/probes/slash.txt`, `/tmp/u2a3-cfc3-i3-jIGM/probes/misc.txt`

---

## Claim 22a: "Checkout files are not walked until U2a3c, so the walk fails closed on them. A start file answers imported only when an import reaches it (U2a4's floor names start files by its own rules)."

**Location:** `scripts/lib/dev-cycle-read.sh:465-467`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the seeding (`seen` but not appended) and the append-on-reach path; does not establish U2a4's rules.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=—
**Replicate annotations:** none

Seeding at `:575` appends nothing to `IMPORTED_MAIN`; `:606` appends every reached path. Test 3 answers `CLAUDE.md: -` with `walk ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:575`, `scripts/lib/dev-cycle-read.sh:604-608`, `test/scripts/build-loop-check.bats:57`

---

## Claim 22b: "Not covered (known issue A5): start files under a symlinked directory or in a submodule or untracked nested repo, other names one file has on a case-insensitive checkout, absolute imports, checkout conversions (A5), and three shapes A5 lists as untraced against Claude Code."

**Location:** `scripts/lib/dev-cycle-read.sh:467-471`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers agreement with A5 and the probes of merged Claim 14d; does not establish completeness against Claude Code's real loader.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1: "'Checkout conversions' is stated as a category, which covers the `ident` shape of merged Claim 14e, but A5's enumeration does not list it. It does not establish that no other unlisted gap exists beyond the shapes probed here" · r3: confidence High; checked A5's last sentence names exactly three untraced shapes

The list matches A5's item for item; `import_targets` drops absolute paths (`:497`).

**Evidence:** `docs/working/known-issues-dev-cycle.md:18`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-misc.txt`

---

## Claim 23: "IMPORTED_MAIN reads "error" until a walk succeeds; the result is cached for the commit, MAIN_BY_NAME and root in IMPORTED_MAIN_DONE, so a caller whose checkout changes between calls sets IMPORTED_MAIN_DONE="" to walk again. isimported asks either walk."

**Location:** `scripts/lib/dev-cycle-read.sh:472-477`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the initial value, the cache key and replay, and the reset. While a walk is in progress, IMPORTED_MAIN holds a partial list (`:578`); that is the settled errexit/early-set row, and no caller can observe it.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish a caller's use of the reset" · r3: "does not cover concurrent callers"; the cachereset mutant (dropping `IMPORTED_MAIN=error;`) kills test 16

The variables start as `IMPORTED_MAIN=error; IMPORTED_MAIN_DONE=""` (`:476`); the cache hit is at `:554`. Test 16 expects `- docs/b.md x.sh x.sh - y.sh` and passes.

**Evidence:** `scripts/lib/dev-cycle-read.sh:476`, `:554-555`, `:626-627`, `test/scripts/build-loop-check.bats:295-304`

---

## Claim 24: nul_list: "array NAME gets CMD's NUL-split output, or is emptied and 1 unless CMD exited 0 and its output was empty or ended in NUL."

**Location:** `scripts/lib/dev-cycle-read.sh:518-519`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers four inputs: output ending in NUL, output not ending in NUL, a non-zero exit, and empty output. It does not cover a caller array named `nl_a` (the nameref would collide; no caller uses that name).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: an `rc=0` item inside the output (`x\0rc=0\0`) gives `rc0 n=2` · r3: "does not cover a CMD that reads stdin"

`a\0b\0` gives `rc0 n=2 [a b]`; `a\0b` gives `rc1 n=0`; `a\0` with exit 3 gives `rc1 n=0`; empty output gives `rc0 n=0 []`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:519`, `/tmp/u2a3-cfc3-i3-jIGM/probes/misc.txt`

---

## Claim 25a: the return-1 comment: each listed condition makes the walk return 1 with IMPORTED_MAIN "error", every failure path is listed, and "need_root exits instead" (with `set -o pipefail  # as brief_fields`)

**Location:** `scripts/lib/dev-cycle-read.sh:538-549`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each `return 1` site in `main_imports` (`:556, :557, :559, :561, :565, :566, :567, :570, :574, :583, :587-588, :590, :595, :600, :602, :611, :612`) against the list, plus tests 4, 10 and 14 and P1; does not establish the record-type phrase's precision (merged Claim 25b) or failures of helpers whose own failure is swallowed (U2a3b, stacked).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r3: "The does-not-parse clause also fires under a UTF-8 locale on a non-UTF-8 name (P8g: `C walk ok`, `C.UTF-8 walk failed`), which fails closed and is not called out" · r3: `:557`'s refusal is masked in the suite (merged Claim 37b); the code path was executed in P7 (`walk: failed`) · r3: `set -o pipefail  # as brief_fields` (`:551`) matches brief_fields' `local - out l; set -o pipefail` (`:321`) · r1: "the root fails" (M1) for "below the root"

Each site maps to a listed cause: `:567` is "holds a newline" for checkout names; `:570` is "comes back short" (lowlen mutant fails test 10); `:583` fails only through `git cat-file`; `:599` maps a failed `realpath` to `..`, which `:600` refuses. Tests 4, 10 and 14 pass; P1 confirms the deleted-index case.

**Evidence:** `scripts/lib/dev-cycle-read.sh:509`, `scripts/lib/dev-cycle-read.sh:550-615`, `test/scripts/build-loop-check.bats:64-77`, `test/scripts/build-loop-check.bats:193-217`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-lowlen.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`

---

## Claim 25b: "a tree record ... has a type but blob, link or gitlink"

**Location:** `scripts/lib/dev-cycle-read.sh:541-542`
**Type:** Error-handling
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `case` on the record's mode at `:582-603`; does not establish that any such record can occur (ls-tree canonicalises modes, merged Claim 10).
**Replicate verdicts:** r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
**Replicate annotations:** r1+r3: the record-type cause is vacuous/unreachable — checked only on records the walk reaches, and ls-tree never prints such a mode

The check is on the stored mode, not the type word, and it runs only when the record is walked (`:582` ... `:602`). An unwalked record never fails the walk on its type. Precise wording: "a walked record's mode is not a regular file, link or gitlink".

**Evidence:** `scripts/lib/dev-cycle-read.sh:559-562`, `scripts/lib/dev-cycle-read.sh:582-603`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-craft.txt`

---

## Claim 26: ancestor-pass comment: "then a name that is also a directory of another listed name (a crafted tree) fails"

**Location:** `scripts/lib/dev-cycle-read.sh:564-565`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the pass's correctness (the memo keeps every ancestor checked against `ent`) and its completeness over `ent`'s names. It covers no wrong refusal on this repo's main. It does not cover names `ent` never holds (tree entries, since `ls-tree -r` omits them); P1 shows a doubled tree name fails through the lookup instead.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r2: "does not establish cost at scale (performance's row)"

`dir[$c]` is set only after `${ent[$c]}` is tested unset; the `break` skips nothing (paraphrased by r1 — loop invariant). The dirmemo mutant survives as an equivalent mutant; the ancestor mutant is killed by test 17. P4 and P5 fail; this repo's main gives `walk: ok`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:564-565`, `/tmp/u2a3-cfc3-i3-jIGM/probes/crafted.txt`, `/tmp/u2a3-cfc3-i3-jIGM/probes/ownmain.txt`, `/tmp/u2a3-cfc3-i3-jIGM/mutants.txt`

---

## Claim 27: the merged `ls-files --cached --others` listing: index-only and untracked/ignored starts main lacks are refused, starts main stores are skipped, and a normal repo is not wrongly refused

**Location:** `scripts/lib/dev-cycle-read.sh:566-567`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers this repo's main (a fresh `git clone` of /workspace checked out at main 62d366a7, clean, 0 status lines) and the review worktree, plus the probes of merged Claim 14b; does not establish behaviour on a sparse index or with GIT_INDEX_FILE (settled Defer row).
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** r3 (probe summary): "One wrong refusal on a normal repo: under a UTF-8 locale, a non-UTF-8 file name in main fails the walk at :559 ... It fails closed. The suite and the probes run `LC_ALL=C`, and this repo's own main walks ok"

On the fresh clone of main the walk prints `walk: ok` in 0.5 s and records three paths main does not store; on the review worktree `walk: ok` too. `:567` adds only names main lacks.

**Evidence:** `scripts/lib/dev-cycle-read.sh:566-577`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-own.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/probe-own2.txt`

---

## Claim 28: "One tr lower-cases every candidate (lower would fork per path)."

**Location:** `scripts/lib/dev-cycle-read.sh:568-570`
**Type:** Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the single `tr` over the NUL-joined list, and `lower`'s per-call fork. It does not establish the cost.
**Replicate verdicts:** r1=Verified · r2=— · r3=— · single-replicate detection
**Replicate annotations:** none

`mapfile -d '' low < <(printf '%s\0' "${cand[@]}" | tr ...)` (`:569`); `lower` forks a pipeline per call (`:484`).

**Evidence:** `scripts/lib/dev-cycle-read.sh:484`, `:569`

---

## Claim 29: "main lacks it: not walked until U2a3c"

**Location:** `scripts/lib/dev-cycle-read.sh:574`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the start-file arm; does not establish U2a3c.
**Replicate verdicts:** r1=— · r2=Verified · r3=— · single-replicate detection
**Replicate annotations:** none

`[[ "${cand[i]:0:1}" == m ]] || return 1` returns before any read of a `t:` start; the untrackedstart mutant fails tests 3, 9 and 11.

**Evidence:** `scripts/lib/dev-cycle-read.sh:574`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-untrackedstart.txt`

---

## Claim 30a: link-arm comments: "a symlink: its text names the file read, as one more import"; "$(...) drops NULs, so they are counted first; the x keeps trailing newlines"; "realpath -s reads x/.. as nothing, but the kernel follows a symlink x first: a .. after a symlink on main or in the checkout fails."

**Location:** `scripts/lib/dev-cycle-read.sh:584-598`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the NUL count, trailing-newline retention, and the per-component `..` check against main's links and checkout links; does not establish the token-side `..` (A5 untraced, settled).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none

The NUL-count mutant fails test 9 with `walk: ok`; the `notes.md\n` text fails test 7. The lk mutant fails tests 10 and 15; dropping `! -L "$p"` from `:597` fails test 15.

**Evidence:** `scripts/lib/dev-cycle-read.sh:584-600`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-nulcount.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-lk.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-lkcheckoutL.txt`

---

## Claim 30b: record-type arms: "160000) continue ;;  # a gitlink: its files are not main's"; any other type fails

**Location:** `scripts/lib/dev-cycle-read.sh:601-602`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a gitlink at a start name and the `*)` arm; does not establish submodule contents (A5's gap).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** r1+r3: the `*)` arm is unreachable; its mutant survives (merged Claims 1c, 10)

Removing the `160000)` line sends a gitlink start to `*)`, and test 12's gitlink-start step fails with `walk: failed`.

**Evidence:** `scripts/lib/dev-cycle-read.sh:601-602`, `test/scripts/build-loop-check.bats:246`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-gitlinkarm.txt`

---

## Claim 31: parent-check comment: "Main lacks p: under a link or gitlink main stores, or in the checkout as anything but a plain directory, fail."

**Location:** `scripts/lib/dev-cycle-read.sh:610-612`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every ancestor (not only the parent), links and gitlinks, and the checkout probe; does not establish the unsearchable-directory case (settled Defer to U2a3c).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover a path absent from the checkout, which passes, as intended and as the block comment states"

`^120000$` in place of `^1[26]0000$` fails test 12; an immediate-parent-only loop fails test 15; dropping the checkout probe fails tests 3, 9 and 12; `false ||` in place of the plain-directory allowance fails test 9.

**Evidence:** `scripts/lib/dev-cycle-read.sh:610-612`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-gitlinkparent.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-parentimmediate.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-checkoutprobe.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-plaindirallow.txt`

---

## Claim 32: isimported: "A failed main walk, or a walk name that is neither, answers imported (0), so a caller testing it with `if` refuses; a caller that words a failed walk runs main_imports first. Run it in the caller's shell: the walk exits through need_root and caches its result."

**Location:** `scripts/lib/dev-cycle-read.sh:616-630`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `main`, `tree` and unknown arms under `if`; does not establish behaviour of helper failures with errexit off inside the walk (settled row; U2a3b).
**Replicate verdicts:** r1=Verified · r2=Verified · r3=Verified
**Replicate annotations:** r1: "does not cover callers, because none exists yet" · r3: the blobread mutant kills tests 8 and 14

`main) main_imports || return 0; ...` and `*) return 0 ;;`. Tests 2, 8 and 14 pass.

**Evidence:** `scripts/lib/dev-cycle-read.sh:621-630`, `test/scripts/build-loop-check.bats:40-44`, `test/scripts/build-loop-check.bats:154-163`, `test/scripts/build-loop-check.bats:260-268`, `/tmp/u2a3-cfc3-i3-irp4/logs/blc.txt`

---

## Claim 33a: suite header: "Contract tests for the build-loop gate: the reader lib's import walks (scripts/lib/dev-cycle-read.sh isimported, import_targets, main_imports) ..."

**Location:** `test/scripts/build-loop-check.bats:3-4`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers which lib functions the suite exercises; does not establish U2a4/U2b's future tests.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** none

The suite's tests call `imps tree`, `imps main`, `isimported` and `main_imports` directly.

**Evidence:** `test/scripts/build-loop-check.bats:13-24`, `test/scripts/build-loop-check.bats:211-216`

---

## Claim 33b: imps helper comment: ""walk: ok" or "walk: failed" (main_imports' return; tree always reads ok)"

**Location:** `test/scripts/build-loop-check.bats:13-15`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the helper's logic. It does not cover the U2a4 and U2b tests, which do not exist yet.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified (compound)
**Replicate annotations:** none

The helper runs `if [[ "$w" != main ]] || main_imports; then echo "walk: ok"; else echo "walk: failed"; fi` (`:20`).

**Evidence:** `test/scripts/build-loop-check.bats:13-24`

---

## Claim 34: test 1/2 names (U2a2): unchanged by this diff apart from the header

**Location:** `test/scripts/build-loop-check.bats:26`, `:40`
**Type:** Staleness
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that both tests pass at HEAD. It does not re-check the token rules of U2a2.
**Replicate verdicts:** r1=Verified · r2=— · r3=Verified (compound)
**Replicate annotations:** none

Both pass in every replicate's suite run.

**Evidence:** `/tmp/u2a3-cfc3-i3-jIGM/bats-five.txt`

---

## Claim 35: test 3's name: "main's instruction files start it; a working-tree edit does not count; an untracked start or a checkout file at a path main lacks fails it until U2a3c"

**Location:** `test/scripts/build-loop-check.bats:46`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each assertion and its order: no earlier failure masks a later one, because `docs/new.md` is removed before the untracked start is added. The name does not mention the index-only start case at `:61`.
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

The test asserts `docs/wt-only.md -` after a working-tree edit, then `walk failed` for a regular file at `docs/new.md`, then `walk failed` for an untracked `CLAUDE.local.md`. The index mutant is killed by this test.

**Evidence:** `test/scripts/build-loop-check.bats:46-62`, `/tmp/u2a3-cfc3-i3-jIGM/m-index.out`

---

## Claim 36a: test 7 comment: "Symlink text with a trailing newline, an absolute one, none, or one leaving the repo: the walk fails."

**Location:** `test/scripts/build-loop-check.bats:144`
**Type:** Behavioral (test)
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each of the four iterations answering `walk failed`. It does not establish that the `''` iteration pins the empty-text check: with `:590`'s `-z` removed, empty text resolves to the root, which `:612` refuses. The empty-text check is pinned instead by test 12 (12:243).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified
**Replicate annotations:** none

The emptytext mutant flips only 12:243, while linknl, linkabs and linkleave each flip 7:150.

**Evidence:** `test/scripts/build-loop-check.bats:144-151`, `:239-243`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft-emptytext.log`

---

## Claim 36b: test 9 comment: "An import through a directory link main stores (the parent-link refusal)."

**Location:** `test/scripts/build-loop-check.bats:171`
**Type:** Behavioral (test)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what 9:172's assertion pins. It does not affect coverage of the parent-link refusal, which tests 12 and 15 pin.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "Test 9's 'unreadable too' adds no separate refusal, because the untracked start alone fails the walk"

The `docs-link` link is checked out, so with `:611` removed the walk still fails at `:612`. The parent mutant does not flip 9:172; it flips 12:246, 15:284 and 15:288. Precise version: "(the parent-link refusal, or the checkout probe, since the link is checked out)".

**Evidence:** `test/scripts/build-loop-check.bats:166-172`, `scripts/lib/dev-cycle-read.sh:611-612`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft-parent.log`

---

## Claim 36c: tests 4-9 and 11-17: names and comments match their assertions, and no refusal is masked by an earlier failure

**Location:** `test/scripts/build-loop-check.bats:64-311`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named refusal: whether some later change to the test would leave its mutant alive. Of the refusals named, only `*)`, which is unreachable, has no killing test. It does not cover test 10 (merged Claims 37a-37c).
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** r2: 19 single-point mutants each fail the test naming the refusal at the expected `want` line; checked test 9's plain-directory comment, test 12's "(sub/ is an empty directory here)" and test 15's kernel/realpath comment · r3: "Each `want walk failed` other than 9:172 (merged Claim 36b) and 10:198 (merged Claim 37b) is flipped by the mutant of the refusal it names" · r3 (in its F2 row's scope): "does not establish that no other refusal in the suite is masked: test 10's tree-listing refusal is"

Tests 5, 9 and 12 remove the stale index `CLAUDE.md` before their crafted mains (`:93`, `:190`, `:241`), and each kills its own mutant. Test 7's empty-text case is masked by the root refusal, which is why test 12 pins empty text below the top level. Every named mutant is killed by the test whose name covers it.

**Evidence:** `test/scripts/build-loop-check.bats:79-106`, `:132-152`, `:165-191`, `:229-247`, `:306-311`, `/tmp/u2a3-cfc3-i3-jIGM/mutants.txt`, `/tmp/u2a3-cfc3-i3-jIGM/mutants2.txt`

---

## Claim 37a: test 10: "fails closed ... reads a list past 64 KiB under ulimit -f 0"; "Link text past 64 KiB with a .. after main's link l, under ulimit -f 0: the .. check reads it whole"

**Location:** `test/scripts/build-loop-check.bats:193`, `:212-217`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the two size claims and that both are pinned. It does not cover the test-name wording (merged Claims 37b, 37c).
**Replicate verdicts:** r1=Verified · r2=Verified (compound) · r3=—
**Replicate annotations:** r3 (on rubric E5): computes the link text as 68,319 bytes (270 × 253 + 9) where r1 computes 68,589; both exceed 64 KiB

The import list is 320 × 210 + 14 = 67,214 bytes; the link text is 68,589 bytes. The herestring and lsfilesrc mutants are killed by this test.

**Evidence:** `test/scripts/build-loop-check.bats:209-217`, `/tmp/u2a3-cfc3-i3-jIGM/mutants2.txt`

---

## Claim 37b: test 10 name "main walk returns, not exits, when main's tree ... cannot be listed" and comment "# The docs/ tree object is missing: ls-tree -r fails part-way."

**Location:** `test/scripts/build-loop-check.bats:193`, `:196-198`
**Type:** Behavioral (test)
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what the tree-listing assertion at :198 pins. It is pinned for "returns, not exits", since status 0 is asserted. It is not pinned for "fails": the treefail mutant (`:557 … || return 1` → `|| true`) passes all 17 tests. The listing half is pinned (ckfail flips 10:202 and 10:206).
**Replicate verdicts:** r1=Mostly accurate (compound) · r2=Mostly accurate (compound) · r3=Mostly accurate
**Replicate annotations:** r1: test 10 excluded from its no-masking claim ("It does not cover test 10") · r2: test 10 excluded from its no-masking claim ("does not cover test 10's wording") · r3: escalated (see Escalations); "It is a test gap only; the lib refuses correctly (P7)"

Same masking class as rubric F2: with `:557`'s refusal gone, `ent` is empty and the index still lists `docs/CLAUDE.md`, so it becomes a `t:` start main lacks and `:574` fails the walk. With `docs/CLAUDE.md` removed from the index and the checkout, the real lib gives `walk: failed` and the treefail mutant `walk: ok`. The masking dates from dfeeb85d's index listing.

**Evidence:** `test/scripts/build-loop-check.bats:193-217`, `scripts/lib/dev-cycle-read.sh:557`, `:566-574`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft-treefail.log`, `/tmp/u2a3-cfc3-i3-3sch/logs/soft.summary`, `/tmp/u2a3-cfc3-i3-3sch/logs/p2.out`

---

## Claim 37c: test 10's name "... or the untracked list cannot be listed" and comment "A corrupt index: git ls-files --others fails."

**Location:** `test/scripts/build-loop-check.bats:193`, `:200`
**Type:** Staleness
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the wording against the listing at `:566`. It does not affect what the test asserts.
**Replicate verdicts:** r1=Mostly accurate · r2=Mostly accurate · r3=Mostly accurate (compound)
**Replicate annotations:** r2: cites the comment at `:199` (r1 `:200`); verification mode executed

Since 99cce51b the listing is one `git ls-files -z --cached --others` (`scripts/lib/dev-cycle-read.sh:566`). The name and comment still say "the untracked list" and "`ls-files --others`". Precise wording: "the checkout's .md list" and "`ls-files --cached --others`".

**Evidence:** `test/scripts/build-loop-check.bats:193`, `:200`, `:208`, `scripts/lib/dev-cycle-read.sh:566`

---

## Claim 38: dev-cycle.bats inventory adds `main_imports nul_list` and `IMPORTED_MAIN IMPORTED_MAIN_DONE`

**Location:** `test/scripts/dev-cycle.bats:1086`, `:1090`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers that the inventory names exist after sourcing. It does not cover callers.
**Replicate verdicts:** r1=Verified · r2=Verified · r3=—
**Replicate annotations:** r2: "does not establish other suites' inventories"

The inventory test passes.

**Evidence:** `test/scripts/dev-cycle.bats:1083-1094`, `/tmp/u2a3-cfc3-i3-jIGM/bats-five.txt`

---

## Claim 39a: commit 99cce51b figures: "Tests: build-loop-check.bats 17; 115 across the five suites. ... 400 changed code lines against main."

**Location:** commit `99cce51b`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the `@test` counts at 99cce51b and HEAD, a live run at HEAD, and `git diff --numstat main...99cce51b -- . ':!docs'`; does not establish the "Test lines ... joined" note beyond the line count.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1+r3: HEAD's code equals 99cce51b's; 0bb98f27 touches only docs

75 + 19 + 17 + 2 + 2 = 115 at 99cce51b and HEAD; live run 115 ok; numstat `117 9`, `268 2`, `2 2` sums to 400.

**Evidence:** `test/scripts/build-loop-check.bats`, `/tmp/u2a3-cfc3-i3-irp4/logs/blc.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/suites-rc.txt`

---

## Claim 39b: commit 99cce51b: "Mutants of the ancestor pass, the tree-name newline check, the NUL count, the empty-text check, the gitlink arm and the index half of the listing each fail."

**Location:** commit `99cce51b`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the six named mutants as reconstructed here (diffs in `logs/mut-<name>.diff`); does not establish the author's exact mutant text.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the mutants' results in other suites"

ancestor → test 17; treenl → 5; nulcount → 9; emptytext → 12; gitlinkarm → 12; indexhalf → 3, 10.

**Evidence:** `/tmp/u2a3-cfc3-i3-irp4/logs/mut-ancestor.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-treenl.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-nulcount.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-emptytext.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-gitlinkarm.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-indexhalf.txt`

---

## Claim 39c: commit 99cce51b F1, F2: the tree-and-symlink fail-open ("full paths differ ... the walk read the tree's blob while a checkout writes the link ... not a regression"), "tests 5, 9 and 12 failed on a stale index-only CLAUDE.md before reaching the refusal they name ... they now `git rm -qf CLAUDE.md` first", and "Test lines that only called imps and then want were joined"

**Location:** commit `99cce51b`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** As merged Claims 1a and 1b; does not establish the reviewer attributions.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified (compound)
**Replicate annotations:** r1: "does not establish the pre-fix masking for F2 beyond what the earlier replicate reports executed"; `git diff 1898d21c 99cce51b` removes 13 lines holding `imps main`, which fits the joined lines · r3: "The message does not claim, and this verdict does not establish, that no other refusal stayed masked (merged Claim 37b)"

Pre-fix walk ok on test 17 at 664c18fe and cc1aa864; checkout writes `l -> docs`; three mutants survive 664c18fe's tests and are killed at HEAD.

**Evidence:** `/tmp/u2a3-cfc3-i3-irp4/logs/mut-old-lib-new-test17.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-cc1-test17.txt`, `/tmp/u2a3-cfc3-i3-irp4/logs/mut-old-treenl.txt`, `test/scripts/build-loop-check.bats:91`, `test/scripts/build-loop-check.bats:189`, `test/scripts/build-loop-check.bats:242`

---

## Claim 39d: commit 99cce51b F4, F5: one `ls-files --cached --others` call; "a gitlink at a start name and a git whose `ls-files --cached` fails are pinned"; wording changes (A5 "a .. after a checkout link", nul_list "empty or ended in NUL", test 9's name, the U2b bullet)

**Location:** commit `99cce51b`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each named change at HEAD; the U2b refusal is a plan (merged Claim 18), not code.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified (compound) · r3=Verified (compound)
**Replicate annotations:** none

`:566` is one call; test 12's gitlink start and test 10's `--cached` shim are present and each is killed by its mutant. A5 holds "a `..` after a checkout link in link text"; `:518` holds "empty or ended in NUL".

**Evidence:** `scripts/lib/dev-cycle-read.sh:518`, `scripts/lib/dev-cycle-read.sh:566`, `test/scripts/build-loop-check.bats:206`, `test/scripts/build-loop-check.bats:246`, `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`

---

## Claim 39e: commit 99cce51b F3: "override rows, listed in A5 and F11; the U2b bullet makes the gate refuse them"

**Location:** commit `99cce51b`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers what the U2b bullet says. It does not cover the override rows, which say the same as merged Claim 9.
**Replicate verdicts:** r1=Unverifiable · r2=Verified (compound) · r3=Mostly accurate
**Replicate annotations:** r1: "does not establish any gate behaviour, because U2b does not exist"; "The refusal set would also miss `ident` (merged Claim 14e)" · r2: "the U2b refusal is a plan, not code"

At HEAD the bullet reads "U2b is to refuse (not built yet; the walk does not check this)" (`docs/working/plan-build-loop-handoff.md:279`). That is a plan item for U2b, not a gate that refuses. 0bb98f27 tightened the bullet in response to the fix-drift finding.

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt:1-3`

---

## Claim 40a: commit 0bb98f27 "the U2b bullet states the checkout-conversion refusal as U2b's to build ... Notes: lite-review fix-drift finding 1 on 99cce51b; output committed."

**Location:** commit `0bb98f27`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the bullet's new wording and the committed fix-drift output. It does not cover anything else.
**Replicate verdicts:** r1=Verified (compound) · r2=Verified · r3=Verified
**Replicate annotations:** none

`git show --stat 0bb98f27` lists `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt` and `docs/working/plan-build-loop-handoff.md` (1 line). The bullet now says "U2b is to refuse (not built yet; the walk does not check this)".

**Evidence:** `docs/working/plan-build-loop-handoff.md:279`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i2.txt:1-3`

---

## Claim 40b: docs-only commits: 5c57d367 and 1898d21c "fix-drift output ... (no findings)"; 0032ed5a and 664c18fe "fact-check, critic reports, rubric and override rows"

**Location:** commit `1898d21c`, `5c57d367`, `0032ed5a`, `664c18fe`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the existence and contents of the named fix-drift outputs and the presence of the report files. It does not cover the reports' contents.
**Replicate verdicts:** r1=Verified (compound) · r2=— · r3=Verified
**Replicate annotations:** r1: 664c18fe adds the L2f reports, the merged L2-final report, 7 override rows and the rubric section

`lite-review-fix-drift-build-loop-u2a3-split.txt` and `-L2i1.txt` each read `lite-review [fix-drift]: FINDINGS: NONE`.

**Evidence:** `docs/reviews/lite-review-fix-drift-build-loop-u2a3-split.txt:1`, `docs/reviews/lite-review-fix-drift-build-loop-u2a3-L2i1.txt:1`

---

## Claim 41: commit dfeeb85d figures: "build-loop-check.bats 16; 114 across the five suites. Mutants of the index listing, the link-text split (here-string revert) and the newline check each fail. 400 changed code lines against main." (test-7/test-3 wording: Accepted-immutable, `docs/reviews/override-log.md:395`, pointer only)

**Location:** commit `dfeeb85d`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures and the three mutants on dfeeb85d's own archive. It does not cover the E1-E6 prose, apart from the code states that HEAD still holds (merged Claims 3, 14b).
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: mutants reconstructed at HEAD (indexhalf, herestring, checkoutnl); E1's pre-fix behaviour equals the indexhalf mutant · r1: pointer only (Accepted-immutable, row 395)

At dfeeb85d: 16 tests pass; indexlist is killed by [3], herestring by [10] and cknl by [7]; numstat gives 400.

**Evidence:** `/tmp/u2a3-cfc3-i3-3sch/logs/oldmuts.summary`, `docs/reviews/override-log.md:395`

---

## Claim 42: commit 2b22a082 figures: "build-loop-check.bats 16; 114 across the five suites. Mutants of the untracked-start refusal, the checkout probe, the gitlink match, the parent loop (immediate parent only), the plain-directory allowance and the link-text split each fail. 392 changed code lines against main." (headline and D13 sentence: Accepted-immutable, `docs/reviews/override-log.md:388`, pointer only)

**Location:** commit `2b22a082`
**Type:** Configuration / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the figures and the six mutants, each run on 2b22a082's own archive. "Link-text split" is read as removing the split (`parts=("$out")`). A here-string revert of the split survived at 2b22a082 (`2b22a082 herestring: rc=0`); dfeeb85d later pinned it. Only the figures are verdicted here; the rest of the message has an Accepted-immutable override row.
**Replicate verdicts:** r1=— · r2=Verified · r3=Verified
**Replicate annotations:** r2: named mutants reconstructed only in their HEAD forms · r1: pointer only (Accepted-immutable, row 388)

At 2b22a082: 16 tests pass; untrackedstart killed by [3 9 11], ckprobe [3 9 12], gitlinkmatch [12], parentimm [15], plaindirallow [9], nosplit [15]; numstat 392. 114 = 75 + 19 + 16 + 2 + 2.

**Evidence:** `/tmp/u2a3-cfc3-i3-3sch/logs/oldmuts.summary`, `docs/reviews/override-log.md:388`

---

## Submitted Claims

## Claim 43: "When `main_imports` fails, `isimported main` answers "imported" for every path."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:626` (isimported's `main)` arm)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers every `return 1` exit of `main_imports`, on both the first call and the cached call, called under `if` and called bare under `set -euo pipefail`, for any `$2` (empty, spaces, a start file, an imported path, an unrelated path). It does not establish what happens on `need_root`'s failure path. That path exits the shell instead of answering, which is the documented behavior ("need_root exits instead").

The arm is `main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;`. Any non-zero return from `main_imports` short-circuits to `return 0` before `$2` is consulted. On a cached call, `main_imports` returns `[[ "$IMPORTED_MAIN" != error ]]`. `IMPORTED_MAIN=error` is set before the first check that can fail, and it is reassigned only at `IMPORTED_MAIN=$'\n'` once the start list is built, so a cached failed walk also returns 1. I read the whole of `main_imports` (lines 550–620) and the whole of `isimported` (621–629).

Executed probe (`c1.sh`). Three repos each made the walk fail in a different way: an untracked `sub/GEMINI.md` start, no `main` branch (`main_by_name` fails), and a symlink on main with absolute text. In each one, the paths `docs/a.md`, `docs/none.md`, `scripts/x.sh`, `""`, `AGENTS.md` and `"a b/c"` all printed `imported`. That held on the first call, on the cached call, and after `IMPORTED_MAIN_DONE=""`. A bare `isimported main zz/q.md` under `set -e` returned 0. The baseline repo, whose walk succeeds, answered `-` for the non-imported paths, which shows that "imported" is not a constant.

## Claim 44: "`nul_list` returns 1 and empties the array unless the command exited 0 and its output was empty or ended in NUL ("whole-listing contract")."

**Submitted by:** security-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:519` (`nul_list`)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the function body as written: the success/failure condition and the array state on both outcomes, including adversarial outputs that themselves contain `rc=0`. It does not establish behavior when the caller's array is itself named `nl_a` (a nameref self-reference). No caller does that: both callers pass `recs`.

`mapfile -d '' nl_a < <("$@" && printf rc=0 || printf rc=1)` appends a marker with no trailing NUL. When the command fails, the stream ends in `rc=1`, so the last element ends in `rc=1`. When it succeeds, the last element equals `rc=0` exactly only when the byte before the marker is a NUL or there is no byte before it. The guard is `[[ ${#nl_a[@]} -gt 0 && "${nl_a[-1]}" == rc=0 ]] || { nl_a=(); return 1; }; unset 'nl_a[-1]'`. That is exactly the stated contract.

Executed probe (`c2.sh`). Each array started as `(x)`:
- empty output with exit 0 gave rc=0 and `n=0`
- `a\0b\0` gave rc=0 and `[a b]`
- `\0` gave rc=0 and `['']`
- `rc=0\0` gave rc=0 and `[rc=0]`
- `a\nb\0` gave rc=0 and `[$'a\nb']`
- these all gave rc=1 and `n=0`: `a\0b` (no trailing NUL), `a\0` with exit 3, exit 2 with no output, a bare `rc=0` (no NUL), `x\0rc=0`, and `rc=0\0` with exit 1

## Claim 45: "The merged `git ls-files -z --cached --others -- ':(glob,icase)**/*.md'` listing returns the same set of names as the earlier pair (`untracked_md` plus `ls-files -z --cached` with the same pathspec)."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:566` (main_imports' checkout listing)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the shapes listed below on git 2.39.5, comparing both the set and the multiset (duplicates included) of the merged command against the pair as 99cce51b removed it (`untracked_md`, i.e. `GIT_LITERAL_PATHSPECS=0 git ls-files -z --others`, then `GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached`, same pathspec). It does not establish other git versions, and it does not establish output order. Order differs (`--others` entries print first in the merged form too), but the loop at line 567 classifies each name independently, so order does not affect which candidates are built or whether a `t:` start fails the walk.

The removed lines in `git show 99cce51b` are `nul_list recs untracked_md` and `nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md'`. Both names were then fed into the same loop. The pathspec and `GIT_LITERAL_PATHSPECS=0` are the same in both forms.

Executed probe (`c3.sh`) in one repo, applying these shapes one after another. After each step, the sorted multiset of the merged output was byte-identical to that of the pair:
- tracked `.md` and `.MD` files
- untracked files, including one in a new nested directory
- ignored files, both by directory and by pattern
- a tracked file deleted from the worktree
- a skip-worktree file that was removed
- an intent-to-add file
- an assume-unchanged file
- an untracked nested repo, then the same repo added as a gitlink
- a tracked file replaced by a directory holding a `.md`
- an unmerged path (listed three times in both forms)
- a non-cone sparse checkout, and a cone sparse checkout with `index.sparse=true`

In each case the unique sets were also identical.

## Claim 46: "The memo `break` in the ancestor pass keeps it linear in records plus distinct directories while still detecting every name that is also a directory of another listed name, whatever the listing order."

**Submitted by:** performance-reviewer
**Location:** `scripts/lib/dev-cycle-read.sh:565` (main_imports' ancestor pass, the `for f in "${!ent[@]}"` line)
**Type:** Behavioral / Performance
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers detection correctness for every insertion and iteration order, and the iteration count of the inner loop. "Linear" counts loop iterations and associative-array lookups. Each `${c%/*}` step also costs time proportional to path length, so the per-record constant grows with path depth. That is the deep-path cost already recorded in an override row (O(L x depth)). It does not establish bash's hash-table behavior at sizes beyond 80,000 records.

Invariant from the code (`[[ -z "${dir[$c]+set}" ]] || break; [[ -z "${ent[$c]+set}" ]] || return 1; dir[$c]=1`): a directory enters `dir` only after it has been checked against `ent`. The climb then continues to its parent. So every directory in `dir` has all of its ancestors in `dir`, each already checked. A `break` on a memoised directory therefore skips only ancestors that were already checked, and that holds whatever the iteration order. Each record does at most (new directories + 1) inner iterations, which gives O(records + distinct directories) iterations in total. The iteration is over `"${!ent[@]}"` (hash order), not the listing order, which makes the result order-independent by construction.

Executed probes (`c4.sh`, which greps that line 565 matches the pasted copy verbatim before it runs):
- 400 random name sets (1–12 names, depth 1–4, a three-letter alphabet so collisions are frequent) were compared with an O(n²) brute-force "some name is a `/`-prefix of another". There were 0 mismatches, and brute force reported a crafted tree in 281 of the sets.
- Two fixed sets inserted in 6 and 4 shuffled orders all returned 1.
- An instrumented copy counted new-directory steps. On the flat-ish set (≈2,500 distinct directories), N = 5k/20k/80k records took 46/120/437 ms. On a single 40-level directory, N = 5k/20k/80k took 38/140/603 ms with only 40 directories added. Time scales roughly linearly in N.

End to end (`c4e.sh`): I crafted a main commit with `git mktree` in which `docs/sub` is stored both as a symlink and as a tree holding `docs/sub/b.md`. `main_imports` returned 1 (`IMPORTED_MAIN=error`). A scratch mutant with line 565 removed (`c4m.sh`) printed `walk ok` on the same repo. So that line alone is what catches this shape.

---

## Claims Requiring Attention

### Incorrect
(none)

### Stale
(none)

### Mostly Accurate
- **Claim 9** (`docs/reviews/override-log.md:391-392`, r3 only): "the U2b bullet makes the gate refuse" describes an unbuilt gate; the append-only log keeps it, the plan bullet is now precise.
- **Claim 14e** (`docs/working/known-issues-dev-cycle.md:18`, r1 only): the checkout-conversion list omits `ident`; executed fail-open on git's side (walk ok, `docs/x$Id: -`).
- **Claim 15** (`docs/working/plan-build-loop-handoff.md:126`, r1 only): F11's gap list has the same `ident` omission.
- **Claim 19** (`scripts/lib/dev-cycle-read.sh:29-35`, r1 only): "the block above IMPORTED= lists each case" — a failing checkout listing appears only in the return-1 comment.
- **Claim 25b** (`scripts/lib/dev-cycle-read.sh:541-542`, r2 only): the record-type clause checks a walked record's mode, not the type word; unreachable.
- **Claim 36b** (`test/scripts/build-loop-check.bats:171`, r3 only): 9:172 is also met by the checkout probe, so it does not pin the parent-link refusal alone.
- **Claim 37b** (`test/scripts/build-loop-check.bats:193`, `:196-198`, r3 explicit; r1/r2 compound): the `:557` tree-listing refusal is masked by the index-only `docs/CLAUDE.md`; the treefail mutant survives all 17 tests.
- **Claim 37c** (`test/scripts/build-loop-check.bats:193`, `:200`, all three): "the untracked list" / "`ls-files --others`" predate the merged `--cached --others` listing.
- **Claim 39e** (commit `99cce51b`, r3; r1 Unverifiable): "the U2b bullet makes the gate refuse them" was a plan statement.

### Unverifiable
(none)

## Escalations

- `docs/working/known-issues-dev-cycle.md:18`, `docs/working/plan-build-loop-handoff.md:126`, `:279` (r1) → **author / U2b owner, security-reviewer to confirm.** An `ident` attribute in main's `.gitattributes` is a checkout conversion outside the enumerated `working-tree-encoding`/`filter`/`core.symlinks=false` set; in a fresh clone the walk answers `ok` while the checked-out bytes yield an import the walk does not record (`/tmp/u2a3-cfc3-i3-jIGM/probes/ident.txt`). No override row covers it; the U2b refusal as specified would not catch it; the L2f security review's "treat `ident` as harmless" (`docs/reviews/security-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md:75`) is refuted. r1's cheapest fix: add `ident` to A5, F11 and the U2b refusal set, or have U2b refuse any of `working-tree-encoding`, `filter`, `ident` or `text`/`eol` other than LF on a path the walk reads.
- `test/scripts/build-loop-check.bats:196-198` (r3) → **test-strategy and implementer.** The `:557` tree-listing refusal is unpinned (Claim 37b). r3's fix: before line 198, take `docs/CLAUDE.md` out of both the index and the checkout (`git rm -q --cached` alone leaves it untracked, which `--others` lists), and restore it before line 204's `commit_all again`; P7 shows the treefail mutant is then killed.
- `test/scripts/build-loop-check.bats:193`, `:199-200` (r1+r2) → **author.** Wording only (Claim 37c); r1 notes the unit is at the 400-line cap and an in-place edit changes no line count.
- `scripts/lib/dev-cycle-read.sh:541-542` (r2) → **author.** Wording only, optional (Claim 25b).
- `test/scripts/build-loop-check.bats:171` (r3) → **test-strategy** (Informational). The comment names the parent-link refusal, but the assertion is also met by the checkout probe (Claim 36b).
- `scripts/lib/dev-cycle-read.sh:559` (r3) → **U2a4/U2b caller** (Informational). Under a UTF-8 locale a non-UTF-8 name in main fails the walk (`C.UTF-8 walk failed`, P8g); fails closed, but the caller should run the walk under `LC_ALL=C`; `scripts/build-loop.sh` sets no global `LC_ALL`.
- `docs/reviews/override-log.md:391-392` (r3) → **orchestrator** (coordinator; Informational). The "makes the gate refuse" wording stays in the append-only log; the plan bullet is correct (Claim 9).
- `docs/reviews/override-log.md:384`, `:394` (r1+r2, Out of scope) → **performance-reviewer.** Cost figures in override rows were not re-measured by r1 (rows 384, 394) and r2 assigns performance figures in override rows to the performance critic; r3 measured only the listing half of row 394 (Claim 11).

## Verdict stability

- Total clusters: 62 (11 single-replicate detections: Claims 2, 4, 8, 9, 11, 12, 13, 17, 27, 28, 29).
- Clusters where all reporting replicates agreed on the verdict: 56 (45 of the 51 multi-replicate clusters).
- Clusters where verdicts disagreed (6):
  - Claim 14e: r1=Mostly accurate · r2=Verified (compound) · r3=Verified (compound)
  - Claim 15: r1=Mostly accurate · r2=Verified · r3=Verified
  - Claim 19: r1=Mostly accurate · r2=Verified · r3=Verified
  - Claim 25b: r1=Verified (compound) · r2=Mostly accurate · r3=Verified (compound)
  - Claim 36b: r1=Verified (compound) · r2=Verified (compound) · r3=Mostly accurate
  - Claim 39e: r1=Unverifiable · r2=Verified (compound) · r3=Mostly accurate
- Agreement rate: 56/62 = 90.3% over all clusters; 45/51 = 88.2% over multi-replicate clusters. Every disagreement is a single replicate calling Mostly accurate (or Unverifiable) where the others called Verified, mostly on a compound row; no Incorrect or Stale verdict was assigned by any replicate.
- Confidence differed without a verdict difference on Claim 22b (r1 Medium, r2 Medium, r3 High) and Claim 14d (r2 Medium, r1 and r3 High, all three on compound rows).
