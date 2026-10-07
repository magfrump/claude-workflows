Commit: 1898d21c

# API Consistency Review — feat/build-loop-u2a3 (loop 2, final confirming pass)

**Scope:** `git diff main...HEAD` on `feat/build-loop-u2a3` (base main 62d366a7, HEAD 1898d21c). Public surface of `scripts/lib/dev-cycle-read.sh`: `main_imports`, `isimported main`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the lib header contract and the documented gate-checkout requirement. Also covers the copies of that contract in A5, F11 and the plan's U2a3/U2a3c/U2b bullets.
**Date:** 2026-10-06
**Based on:** fact-check summary `factcheck-summary-L2f.md` (replicates `code-fact-check-report-build-loop-u2a3-L2f-r1/-r2/-r3.md`); this critic's loop 2 iteration 1 report `api-consistency-reviewer-review-2026-10-06-L2-build-loop-u2a3.md`

## Baseline Conventions

(Unchanged from iteration 1 and re-checked at this HEAD.)

- **Readers of main's commit are named `main_*`** (`main_by_name` :253, `main_entry` :269). They read at `$MAIN_SHA` and need `resolve_main` first.
- **Readers that need the repo root exit through `need_root`.** The lib header (:12-35) is the contract later units cite for each function's inputs and preconditions.
- **Failure state is a sentinel in a global** (`BRIEF_ODD=error`, `IMPORTED_MAIN=error`). Predicates give the refusing answer on failure: `isimported`'s `*)` arm answers imported.
- **Result globals come in pairs with a cache key** (`IMPORTED`/`IMPORTED_DONE`). Lists are newline-framed and lower-cased.
- **Listing helpers are noun phrases with a one-line usage comment** (`lower`, `instruction_names`, `untracked_md`). Nameref locals take a prefix.
- **`test/scripts/dev-cycle.bats`'s sourcing inventory (:1083-1090) lists every lib function and global.**
- **Refusals and gaps are written out in several copies:** the lib block comment (:452-473), the return-1 comment (:536-545), known issue A5, plan row F11, and the plan's U2a3 and U2b bullets. Override rows (architecture F4-F6, Won't-Fix) rely on these copies agreeing.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_imports` | function | `main_entry`, `main_by_name`, `imported_names` | `scripts/lib/dev-cycle-read.sh:253,269,518` | Consistent: a `main_*` commit reader. Its noun order differs from `imported_names`; that was accepted in earlier passes and is not re-filed |
| `isimported main` | subcommand word | `isimported tree`, the `*)` arm | `scripts/lib/dev-cycle-read.sh:617-626` | Consistent: same predicate shape, and the same refusing answer on failure |
| `nul_list` | function | `untracked_md`, `instruction_names`, `lower` | `scripts/lib/dev-cycle-read.sh:482,512,515` | Consistent. Now in the inventory (`dev-cycle.bats:1086`) |
| `IMPORTED_MAIN` | global | `IMPORTED`, `BRIEF_ODD` | `scripts/lib/dev-cycle-read.sh:252,474` | Consistent: `IMPORTED` plus a qualifier, with an `error` sentinel |
| `IMPORTED_MAIN_DONE` | global | `IMPORTED_DONE`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:109,474` | Consistent `_DONE` cache key. Now in the inventory |
| `U2a3c` (plan unit) | doc name | `U2a3b`, `U2a4` | `docs/working/plan-build-loop-handoff.md:276-281` | Consistent with the stacked-unit lettering |

No naming findings.

## Status of iteration 1 findings (this critic)

- **1 (ignored instruction files fail the walk; the gate needs a fresh worktree):** fixed. The header (:32-34), block comment (:463), A5, F11 and the U2b bullet now state it. Commit 2b22a082's D13 sentence is an Accepted-immutable override row.
- **2 (header said "anything at"):** fixed. The header now points to the block comment ("the block above IMPORTED= lists each case") and no longer has its own copy. See finding 3 for a small gap this leaves.
- **3 (`nul_list` usage omitted the NUL-ending check):** fixed. It is now stated, but the new wording is slightly too strong; see finding 4.
- **4 (not-covered list drift):** fixed. dfeeb85d made an index-only start fail the walk, so A5's extra gap is gone. The lib, A5 and F11 not-covered lists now match.
- **5 (inventory omits `nul_list`):** fixed (`dev-cycle.bats:1086`).

## Findings

#### 1. The contract says "a doubled name" fails the walk, but a name main stores as both a tree and a symlink does not

**Severity:** Minor (a gap between the contract and the code. Its exploitability belongs to security.)
**Location:** `scripts/lib/dev-cycle-read.sh:454-455` (block comment), `:539-540` (return-1 comment: "a name is listed twice"), `:557` (the check); `docs/working/plan-build-loop-handoff.md:126` (F11), `:276` (U2a3 bullet); override-log row `:379`
**Move:** 3 (consumer contract), 8 (what the result holds)
**Confidence:** High (fact-check r3 Claim 13b, executed; not re-run here)
**Legibility-target:** the U2a4 floor author, who relies on "a doubled name fails" being complete, and the security reviewer who owns row :379

**Evidence:** fact-check r3 Claim 13b. The doubled-name check compares full paths, and `ls-tree -r` prints the tree's entries (`l/x.md`) and the symlink (`l`) as different strings. Take a non-canonical tree that lists the tree before the symlink. `main:l/x.md` reads the tree's blob, but a fresh worktree writes `l -> docs`, so Claude Code reads `docs/x.md`. Result: walk ok, `docs/secret.md: -`. The same holds at cc1aa864, so this is not a regression. Every written copy of the contract says flatly that a doubled name fails. A consumer can only learn otherwise from the fact-check report. Row :379 probed only the blob-first order, which fails closed.

**Recommendation:** Do what the fact-check suggests and refuse a listed name that is a proper path prefix of another listed name. Then the contract text holds as written. If that is deferred, qualify "a doubled name" in the block comment and in A5 ("a name listed twice as the same path; a tree/symlink pair is not caught") and record a row that supersedes :379.

#### 2. A5 says "a link in link text" fails the walk; the code and the other copies say only a `..` after a link does

**Severity:** Minor
**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5: "a start file main lacks ..., a link in link text, or anything but a plain directory ... fails the walk"); compare `scripts/lib/dev-cycle-read.sh:456-457, 583-590`, F11 (`plan-build-loop-handoff.md:126`)
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check r2 7b, r3 8c; matches my reading of the component loop at :583-590: `lk` only fails on a later `..`)
**Legibility-target:** the U2a3c author, who replaces A5's interim list, and the U2a4 author reading A5 as the list of gaps

A5 claims more is refused than really is. This is the same kind of drift as last iteration's finding 2. A reader who believes a checkout symlink anywhere in link text fails the walk will not look for the link-to-link case that passes.

**Recommendation:** In A5, change "a link in link text" to "a `..` after a checkout symlink in link text". That matches the lib comment's "(on main or in the checkout)".

#### 3. The return-1 comment and the header's pointer miss two failure causes

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:32-34` (header: "the block above IMPORTED= lists each case"), `:452-465` (block comment), `:536-545` (return-1 comment), `:562` (index listing), `:598` (`*)` arm)
**Move:** 3 (documentation drift in the contract)
**Confidence:** High (fact-check, Mostly accurate across replicates; read)
**Legibility-target:** the U2a3b author, who edits these listings, and the U2a4 author, who words a failed walk

The header now points to the block comment for "each case". The block comment lists shapes, not listing failures. The return-1 comment does list listing failures, but it names only "the commit's tree or the untracked list". It leaves out the checkout's index listing that dfeeb85d added (:562), and it leaves out the `*)` arm for an unmodelled record type (:598). That arm cannot be reached today because ls-tree canonicalizes modes, but it is a documented E4 outcome. A reader following the header's pointer will not find these causes.

**Recommendation:** Change the header to "the comments above IMPORTED= and main_imports list each case". In the return-1 comment, change "or the untracked list" to "the untracked list or the index's .md list", and add "a record type it does not model".

#### 4. `nul_list`'s usage line implies empty output fails; it succeeds with an empty array

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:516-517`
**Move:** 3 (consumer contract), 8 (what the result holds)
**Confidence:** High (fact-check, Mostly accurate; read whole unit: with empty output, `mapfile` yields only `rc=0`, the test passes, and the sentinel is unset)
**Legibility-target:** the U2a3b author, who reuses `nul_list`

The comment says "is emptied and 1 unless CMD exited 0 and its output ended in NUL". Empty output does not end in NUL, yet it returns 0. That is the right behavior, because an empty tree or listing is valid. A U2a3b caller who takes the comment literally might add a redundant emptiness check, or might assume an empty result can never be success.

**Recommendation:** Change "its output ended in NUL" to "its output was empty or ended in NUL".

#### 5. Two copies outside the lib still say any checkout content at a path main lacks fails

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:279` (U2b bullet: "on checkout content at paths main lacks"); `test/scripts/build-loop-check.bats:175` (test name "a checkout symlink or file at a path main lacks"; per the fact-check, only test 3 pins a file)
**Move:** 3 (documentation and test-name drift)
**Confidence:** High (fact-check, Mostly accurate)
**Legibility-target:** the U2b author, who picks the gate's checkout

A plain directory at an imported path passes, and only imported paths count. The lib, A5, F11 and the U2a3 bullet all say "anything but a plain directory at an imported path main lacks". The U2b bullet is broader. In this direction the error is harmless: U2b would over-provision a fresh worktree, which it needs anyway.

**Recommendation:** In the U2b bullet, use the shared wording: "anything but a plain directory at an imported path main lacks". The test name can wait for U2a3c, which rewrites these tests.

## What Looks Good

- **All five iteration 1 findings are fixed.** The gate-checkout requirement is stated in every copy that a later unit reads (header, block comment, A5, F11, U2b bullet): ignored instruction files fail the walk, so the gate needs a fresh worktree until U2a3c. That was the one finding with consequences outside this unit.
- **The interim contract can be extended without breaking callers.** The return shape (0/1, with `IMPORTED_MAIN` holding either `error` or a newline-framed lower-cased list) does not change in U2a3c. Each interim refusal that U2a3c removes turns a failure into a walk. The U2a3c bullet now constrains how (one drain loop, one admission check before `seen`). The fact-check probed the fail-closed checkout contract in 22+ states with no fail-open; finding 1 concerns main's own tree.
- **dfeeb85d made the contract more uniform.** "A start file main lacks", whether untracked, ignored, or only in the index, now has one rule and one wording in every copy. Any record type other than blob, symlink or gitlink now fails, which matches the lib's FENCE_AWK-style "refuse what it does not model" convention.
- **Naming is consistent** with the lib's `main_*`, `IMPORTED*`/`_DONE` and noun-phrase helper families, and the inventory now lists every new name.
- **No existing consumer changes.** `check_fix` still calls `isimported tree`, and `isimported main` has no caller before U2a4.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | "A doubled name fails" does not hold for a tree/symlink pair at one name (walk ok, imports through the symlink missed) | Minor | `scripts/lib/dev-cycle-read.sh:454-455, 539-540, 557`; F11; U2a3 bullet; override row :379 | High |
| 2 | A5's "a link in link text" fails is broader than the code (only a `..` after a link fails) | Minor | `docs/working/known-issues-dev-cycle.md:18` | High |
| 3 | The return-1 comment omits the index listing and the `*)` arm; the header's pointer names only the block comment | Informational | `scripts/lib/dev-cycle-read.sh:32-34, 536-545` | High |
| 4 | `nul_list` usage implies empty output fails | Informational | `scripts/lib/dev-cycle-read.sh:516` | High |
| 5 | U2b bullet and test 9's name: "checkout content/file at a path main lacks" (a plain directory passes) | Informational | `plan-build-loop-handoff.md:279`; `build-loop-check.bats:175` | High |

## Overall Assessment

The public surface fits the lib's conventions, and every iteration 1 finding is fixed. The documented gate-checkout requirement now reaches each unit that will read it. Findings 2-5 are wording and need one-phrase fixes. Finding 1 is the only gap between the contract and the code: the written refusal "a doubled name" does not cover a name stored as both a tree and a symlink. That case predates the split and is not a regression. Whether it blocks merge is a security call, not a consistency one. From the consistency side it can be fixed in place: either a prefix check makes the text true, or a qualifier makes the text accurate. Nothing here is Breaking, and no consumer exists yet.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md, structured per the api-consistency-reviewer skill."
- **Answered:** The public surface (`main_imports`, `isimported main`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the header contract, the gate-checkout requirement) is consistent, and there are no naming findings. All iteration 1 findings are fixed. There are two Minor findings: finding 1 (contract and code disagree on doubled names) and finding 2 (A5 wording). Findings 3-5 are Informational.
- **Out of scope:** behaviors U2a3b changes (`import_targets`, failing sed/grep/lower); settled override rows (no reason word on a failed walk, cache ignoring checkout state, the unsearchable checkout directory, git-hardening bypasses deferred to U2b, `@.git` in a linked worktree); the three test refusals that dfeeb85d's index listing masks (test-strategy's area, fact-check r1 24-26); the commit-message inaccuracies in dfeeb85d (Accepted-immutable candidates).
- **Escalate:** (a) Security and the author: finding 1, the tree/symlink doubled-name fail-open (fact-check r3 13b), which overrides row :379's blob-first-only probe. It decides merge-readiness and is not a wording matter. (b) The author: the one-phrase fixes in findings 2-5.
