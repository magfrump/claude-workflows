Commit: 0bb98f27

# API Consistency Review — feat/build-loop-u2a3 (loop 2 iteration 3, final confirming pass)

**Scope:** `git diff main...HEAD` on `feat/build-loop-u2a3` (base main 62d366a7, HEAD 0bb98f27). Public surface of `scripts/lib/dev-cycle-read.sh`: `main_imports`, `isimported main`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the lib header contract, the gate-checkout requirement, and the copies of the contract in A5, F11, the U2a3/U2a3c/U2b plan bullets and the override rows.
**Date:** 2026-10-06
**Based on:** fact-check summary `factcheck-summary-L3.md` (replicates `code-fact-check-report-build-loop-u2a3-L3-r1/-r2/-r3.md`); this critic's previous report `api-consistency-reviewer-review-2026-10-06-L2f-build-loop-u2a3.md` (HEAD 1898d21c)

## Baseline Conventions

I re-checked these at 0bb98f27. They have not changed since the L2f pass.

- **Readers of main's commit are named `main_*`** (`main_by_name`, `main_entry`). They read at `$MAIN_SHA` after `resolve_main`.
- **Readers that need the root exit through `need_root`.** The lib header (`dev-cycle-read.sh:12-35`) is the contract for each function's inputs and preconditions.
- **A failure is stored as a sentinel in a global** (`BRIEF_ODD=error`, `IMPORTED_MAIN=error`). Predicates answer with the refusing value on failure.
- **Result globals are paired with a `_DONE` cache key** (`IMPORTED`/`IMPORTED_DONE`). Lists are newline-framed and lower-cased.
- **Helpers have noun-phrase names and a one-line usage comment** (`lower`, `instruction_names`, `untracked_md`). Nameref locals carry a prefix.
- **Locale independence:** byte-sensitive tools run under `env LC_ALL=C` inside the lib (`:53, :326, :508, :514, :729`). Bash-side matching lists characters one by one rather than setting LC_ALL, because setting LC_ALL printed setlocale warnings (`:141-144`).
- **The sourcing inventory** (`test/scripts/dev-cycle.bats:1083-1090`) lists every lib function and global.
- **Refusals and gaps are stated in several copies:** the lib block comment (`:452-475`), the return-1 comment (`:538-549`), A5, F11, the U2a3 and U2b bullets, and the override rows.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `main_imports` | function | `main_entry`, `main_by_name`, `imported_names` | `scripts/lib/dev-cycle-read.sh:253,269,521` | Consistent: a `main_*` commit reader. Its noun order differs from `imported_names`; this was accepted in earlier passes and is not re-filed |
| `isimported main` | subcommand word | `isimported tree`, the `*)` arm | `scripts/lib/dev-cycle-read.sh:621-630` | Consistent: same predicate shape, and the same refusing answer on failure |
| `nul_list` | function | `untracked_md`, `instruction_names`, `lower` | `scripts/lib/dev-cycle-read.sh:493,514,517` | Consistent. Listed in the inventory (`dev-cycle.bats:1086`) |
| `IMPORTED_MAIN` | global | `IMPORTED`, `BRIEF_ODD` | `scripts/lib/dev-cycle-read.sh:476`, `:252` | Consistent: `IMPORTED` plus a qualifier, with an `error` sentinel |
| `IMPORTED_MAIN_DONE` | global | `IMPORTED_DONE`, `SKIP_AT` | `scripts/lib/dev-cycle-read.sh:476` | Consistent `_DONE` cache key. Listed in the inventory (`:1090`) |
| `U2a3c` (plan unit) | doc name | `U2a3b`, `U2a4` | `docs/working/plan-build-loop-handoff.md:276-279` | Consistent with the stacked-unit lettering |

No naming findings.

## Status of L2f findings (this critic)

- **1 (a tree/symlink doubled name passed):** fixed in 99cce51b with the ancestor pass at `:565`. The lib block comment, the return-1 comment and A5 now say "listed twice or as both a file and a directory". F11 and the U2a3 bullet still say only "a doubled name"; see finding 4.
- **2 (A5 "a link in link text"):** fixed. A5 now reads "a `..` after a checkout link in link text".
- **3 (header pointer, return-1 omissions):** partly fixed. The return-1 comment now names "the checkout's .md list (tracked and untracked)" and "a type but blob, link or gitlink". The header (`:33-34`) still points only at "the block above IMPORTED=", which lists shapes, not listing failures. See finding 3.
- **4 (`nul_list` empty output):** fixed (`:518`: "was empty or ended in NUL").
- **5 (U2b bullet "checkout content"):** fixed. The U2b bullet now uses the shared "anything but a plain directory at an imported path main lacks". The test names flagged then are accurate now (test 9 at `:165` names a symlink, test 3 at `:46` a file).

## Findings

#### 1. The list of checkout conversions reads as complete, but it omits `ident`

**Severity:** Minor
**Location:** `docs/working/known-issues-dev-cycle.md:18` (A5: "checkout conversions that change the bytes ...: a `working-tree-encoding` or `filter` attribute ..., and `core.symlinks=false`"); `docs/working/plan-build-loop-handoff.md:126` (F11's gap list), `:279` (U2b bullet: the set U2b "is to refuse"); `scripts/lib/dev-cycle-read.sh:470` ("checkout conversions (A5)")
**Move:** 3 (consumer contract; documentation drift)
**Confidence:** High (fact-check L3 r1, executed: a blob `@docs/x$Id$` under `ident` is checked out as `@docs/x$Id: <sha> $`, the walk returns ok, and `docs/x$Id: -`. I did not re-run it.)
**Legibility-target:** the U2b author, who builds the refusal set from the U2b bullet and A5

**Evidence:** The lib's own wording, "checkout conversions (A5)", is general and covers `ident`. A5, however, puts a colon after "checkout conversions that change the bytes git writes from the bytes main stores" and then lists two attributes and one config. A list in that form reads as the complete set. The U2b bullet names only those three as what U2b "is to refuse". A U2b author working from either copy builds a refusal that misses `ident`. The L2f security review called `ident` harmless, and the L3 r1 probe refutes that. This is a contract-completeness gap in the copies that later units consume. It is not a code defect in U2a3, which documents conversions as not covered.

**Recommendation:** Add `ident` to the list in A5, F11 and the U2b bullet. Alternatively, frame the list as examples ("such as ...") and state the rule U2b should apply: refuse any attribute that rewrites checked-out bytes on a path the walk reads.

#### 2. The walk depends on the caller's locale, and the header does not say so

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:559` (`[[ "$rec" =~ ^...$'\t'(.+)$ ]] || return 1`); header `:12-35` (caller preconditions: `-euo pipefail`, cd, `ROOT_REAL`; nothing on locale)
**Move:** 1/3 (baseline convention; consumer contract)
**Confidence:** High (fact-check L3 r3 Informational. I reproduced it here: `[[ $'a\tx\xffy.md' =~ ^a$'\t'(.+)$ ]]` matches under `LC_ALL=C` and does not match under `C.UTF-8`.)
**Legibility-target:** the U2a4/U2b caller author, who chooses the environment `--check` runs in

**Evidence:** The lib's convention is that its checks do not depend on the caller's locale. Tools run under `env LC_ALL=C`, and bash patterns list characters one by one, as the comment at `:141-144` explains. `main_imports` follows that convention for the mode, type and hash fields. The name field uses `.`, though, and under a UTF-8 locale `.` does not match an invalid byte. So when main stores a non-UTF-8 file name anywhere in its tree, the walk returns 1, and `isimported main` then answers "imported" for every path. This fails closed, so it is not a safety issue. Consumer impact: in a UTF-8 environment the gate refuses every self-merge for such a repo, and nothing in the header tells the caller why. `build-loop.sh` sets no global `LC_ALL`.

**Recommendation:** Pick one of these. (a) Make the name field locale-free, for example by testing the prefix with the existing listed-character regex and taking the name with `${rec#*$'\t'}`. (b) State it in the header: "main_imports fails on a non-UTF-8 name unless the caller runs it under LC_ALL=C". Option (a) matches the `:141-144` convention.

#### 3. The header still points readers to only one of the two cause lists

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:33-34` ("the block above IMPORTED= lists each case"); compare `:538-549` (the return-1 comment above `main_imports`)
**Move:** 3 (documentation drift in the contract)
**Confidence:** High (fact-check L3 r1, Mostly accurate; read)
**Legibility-target:** the U2a3b author, who edits the listings, and the U2a4 author, who words a failed walk

The return-1 comment is now complete for listing failures. The header, though, sends readers to the block comment, which lists shapes, not listing or blob-read failures. This is the remaining half of L2f finding 3.

**Recommendation:** Change the header to "the comments above IMPORTED= and main_imports list each case".

#### 4. F11 and the U2a3 bullet say "a doubled name"; the lib and A5 say "listed twice or as both a file and a directory"

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:126` (F11), `:276` (U2a3 bullet); compare `scripts/lib/dev-cycle-read.sh:457-458`, `:542-543` and A5 (`known-issues-dev-cycle.md:18`)
**Move:** 3 (documentation drift across copies)
**Confidence:** High (read)
**Legibility-target:** the U2a4 floor author, who reads F11 as the floor's statement of what is modelled

99cce51b widened the refusal and updated three of the five copies. "A doubled name" can be read as covering a tree/symlink pair, so a reader is not misled into thinking the walk does less than it does. But the copies no longer match word for word, and override rows rely on them agreeing.

**Recommendation:** Use the shared wording in F11 and the U2a3 bullet: "a name listed twice or as both a file and a directory".

#### 5. Test 10's name and comment, and override rows 391-392, predate the latest changes

**Severity:** Informational
**Location:** `test/scripts/build-loop-check.bats:193` (name: "the untracked list"), `:199` (comment: "git ls-files --others fails"); `docs/reviews/override-log.md:391-392` ("the U2b bullet makes the gate refuse them")
**Move:** 3 (test and documentation drift)
**Confidence:** High (fact-check L3 r1, r2, r3; read)
**Legibility-target:** the U2a3c author, who rewrites these tests, and the U2b author, who reads rows 391-392

The listing is now `ls-files --cached --others`. As 0bb98f27's own U2b bullet says, the refusal in rows 391-392 is planned and not built. The log is append-only, so a fix there means adding a new row, as was done for row 396.

**Recommendation:** Rename test 10's "untracked list" to "the checkout's .md list" and update its comment. Optionally, add a log row that qualifies rows 391-392 as "planned, not built". Test 10's masked tree-listing refusal belongs to test-strategy (fact-check L3 r3) and is not re-filed here.

## What Looks Good

- **Four of the five L2f findings are fixed, and the fifth is half done.** Every fix took the wording of the shared copies, not a new paraphrase.
- **The fail-open in L2f finding 1 is closed in code, not only in text.** The ancestor pass makes "a name listed twice or as both a file and a directory" true as the lib states it. Test 17 (`:306`) pins it.
- **The return shape is stable for later units.** U2a3c can extend it without breaking callers: 0/1, with `IMPORTED_MAIN` holding `error` or a newline-framed lower-cased list. `isimported main` answers "imported" on every failure, the same refusal as the `*)` arm.
- **The gate-checkout requirement is in every copy a later unit reads:** header, block comment, A5, F11 and the U2b bullet. All say a fresh worktree until U2a3c.
- **Naming follows the lib's families** (`main_*`, `IMPORTED*`/`_DONE`, noun-phrase helpers), and the inventory lists every new name.
- **No existing consumer changes.** `check_fix` still calls `isimported tree`, and `isimported main` has no caller before U2a4.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Checkout-conversion list reads as exhaustive but omits `ident` (U2b's planned refusal set inherits the gap) | Minor | `known-issues-dev-cycle.md:18`; `plan-build-loop-handoff.md:126, 279` | High |
| 2 | Name-field `.` makes the walk locale-dependent (non-UTF-8 name fails under UTF-8); header states no locale precondition | Minor | `dev-cycle-read.sh:559`, `:12-35` | High |
| 3 | Header points to only the block comment for "each case" | Informational | `dev-cycle-read.sh:33-34` | High |
| 4 | F11 and the U2a3 bullet keep "a doubled name" after the widening | Informational | `plan-build-loop-handoff.md:126, 276` | High |
| 5 | Test 10's name and comment, and override rows 391-392, are stale | Informational | `build-loop-check.bats:193, 199`; `override-log.md:391-392` | High |

## Overall Assessment

The public surface is consistent with the lib's conventions. Nothing is Breaking or Inconsistent, and there are no naming findings. The previous pass's one substantive gap, the tree/symlink doubled name, is fixed in code and pinned by a test. The two Minor findings are about how the contract reaches later units. Finding 1 is a missing entry in the conversion list that U2b will build its refusal from. Finding 2 is an undocumented locale precondition: it fails closed, and the lib's own convention suggests removing it rather than documenting it. Both can be fixed in place in one line each, or carried to U2b as written escalations. Neither leaves a fail-open in U2a3's code. From the consistency side, this branch is merge-ready once findings 1 and 2 are either fixed or recorded.

## Goal-Alignment Note

- **Success criterion (verbatim):** "A markdown report saved to docs/reviews/api-consistency-reviewer-review-2026-10-06-L3-build-loop-u2a3.md, structured per the api-consistency-reviewer skill."
- **Answered:** The surface (`main_imports`, `isimported main`, `nul_list`, `IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, the header contract, the gate-checkout requirement) is consistent, with no naming findings. L2f findings 1, 2, 4 and 5 are fixed, and 3 is half fixed. There are two new Minor findings (the `ident` omission, the locale dependence) and three Informational wording items.
- **Out of scope:** behaviors U2a3b changes (`import_targets`, a failing sed/grep/lower); settled override rows (cache ignoring checkout state, the unsearchable checkout directory, git-hardening bypasses deferred to U2b, `@.git` in a linked worktree, `working-tree-encoding`/`filter`/`core.symlinks`, rows 391-392 themselves); test 10's masked tree-listing refusal (test-strategy); exploitability of `ident` (security).
- **Escalate:** (a) The author or U2b owner: finding 1, adding `ident` to A5, F11 and the U2b refusal set. This matches the fact-check escalation. (b) The author or the U2a4/U2b caller: finding 2, either a locale-free name match or a documented `LC_ALL=C` precondition. (c) The author: the one-phrase fixes in findings 3-5.
