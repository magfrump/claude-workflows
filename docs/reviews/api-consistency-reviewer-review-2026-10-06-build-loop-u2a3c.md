Commit: cebfed35

# API Consistency Review — feat/build-loop-u2a3c (U2a3c, review-fix loop iteration 1)

**Scope:** `git diff 5e51b58b..HEAD` (cebfed35 only): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c and U2b bullets)
**Date:** 2026-10-06
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md` (Stage 1 summary: 33 claims, 4 Incorrect, none behavioural)

The lib's functions are its internal API; its header (lines 1-35) and the per-function comments are the caller contract. The consumers are `scripts/dev-cycle.sh` (`isimported tree`), the bats suites, and the not-yet-built U2a4 floor and U2b `--check`.

## Baseline Conventions

Surveyed `need_root`, `rawfile`, `plaindir`, `blocker`, `inrepo`/`inrepo_here`, `dirok`, `skipped`, `nul_list`, `untracked_md`, `instruction_names`, `main_by_name`, `main_entry`, `brief_fields`, `imported_names`, `import_targets`, `isimported` (all `scripts/lib/dev-cycle-read.sh`).

- **Return codes.** Every helper is either a 0/1 predicate (`rawfile`, `plaindir`, `inrepo_here`, `dirok`, `main_by_name`) where 1 means "not plain / skip it", a 0/1 operation where 1 means "failed, refuse" (`nul_list`, `main_imports`), a printer that always returns 0 (`blocker`), or a string-answering function (`main_entry` answers `error`). No function in `scripts/lib/` returns a third value (`rg 'return 2' scripts test`: the only lib hit is the new `main_checkout`; other hits are in `scripts/hermeticity-lint`, `scripts/lite-review.py` and test helpers, unrelated).
- **Inputs.** Helpers take their inputs as arguments; the one helper that touches a caller's variable names it explicitly (`nul_list NAME CMD...`, `local -n nl_a="$1"`). Globals are documented in the header (`ROOT_REAL`, `MAIN_SHA`, `MAIN_BY_NAME`, `IMPORTED*`, `BRIEF`).
- **Naming.** `main_*` names read the default branch's commit (`main_by_name`, `main_entry`, `main_imports`); `<what>_md` / `<what>_names` name NUL-listing producers (`untracked_md`, `instruction_names`, `imported_names`); `*_here` marks a variant that relies on the caller's `need_root`.
- **Header contract.** Lines 28-35 sort the readers into "read the default branch's commit, never the working tree" and "reads the working tree at ROOT_REAL". The cache contract for `main_imports` is at :474-476.
- **Lib surface test.** `test/scripts/dev-cycle.bats:1084-1086` enumerates every lib function ("sourcing the reader lib defines its functions"); at 5e51b58b it listed all of them.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `checkout_md` | function (NUL-listing producer) | `untracked_md`, `instruction_names`, `imported_names` | `scripts/lib/dev-cycle-read.sh:516-519, 514` | Consistent: `<scope>_md` matches `untracked_md`. (Its pathspec duplication is Finding 4.) |
| `main_checkout` | function (admission predicate) | `main_entry`, `main_by_name`, `main_imports`; `inrepo_here`, `dirok` | `scripts/lib/dev-cycle-read.sh:253, 269, 565; 127, 130` | Inconsistent: `main_*` reads main's commit; this reads the working tree, and "main checkout" is git's own term for the primary worktree (Finding 3) |
| `tq` | local (phase-2 queue) | `queue`, `recs`, `cand` | `scripts/lib/dev-cycle-read.sh:566` | Private local; skipped from findings |

## Findings

#### 1. `main_checkout` reads the caller's `ent` by dynamic scope; called anywhere else it fails open and evaluates path text as arithmetic

**Severity:** Inconsistent
**Location:** `scripts/lib/dev-cycle-read.sh:525-535`
**Move:** 1 (baseline: inputs), 3 (consumer contract)
**Confidence:** High (mechanism, executed); Medium (that a later unit reuses it)
**Legibility-target:** the next unit's author (U2a4's floor, U2b's `--check`) reaching for "the one admission check" outside `main_imports`

Evidence:
```
# main_checkout PATH, the one admission check for main_imports' checkout phase (it
# reads the caller's ent): 0 for a plain checkout file to walk, 2 when nothing
...
  while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ && ( ! -d "$c" || -x "$c" ) ]] || return 1; done
```
(excerpt ends :531; enclosing `main_checkout()` continues to :535 — read.)

Every other helper takes its inputs as arguments, and the one that touches a caller's variable takes its name (`nul_list NAME CMD...`, `local -n nl_a="$1"`, :521). `main_checkout` instead relies on bash's dynamic scoping of `main_imports`' `local -A ent` (:567). Inside `main_imports` this is correct. Outside it, `ent` is unset, so (a) the main-link/gitlink check is silently skipped (`${ent[$c]:-}` is empty and passes), i.e. the admission check admits a path under a directory main stores as a link: fail open; and (b) bash treats the undeclared `ent` as an indexed array, so the subscript `$c` undergoes arithmetic expansion. Executed probe (fresh repo in my temp dir, lib sourced, `ROOT_REAL` set, no `ent`): `main_checkout 'a[$(touch PWNED)]/f.md'` returned 0 and created `PWNED`. No current caller does this (the two calls are at :589 and :628, both inside `main_imports`), so this is a latent contract hazard, not a live defect; but the comment advertises the function as "the one admission check", which invites reuse.

**Recommendation:** Make the dependency explicit as the lib already does for arrays: `main_checkout ENTNAME PATH` with `local -n mc_ent="$1"` (and `declare -p`/`-A` check that it names an associative array, returning 1 otherwise), or move the ancestor loop into `main_imports` and keep `main_checkout` working-tree only. At minimum, state in the comment that it must be called only from inside `main_imports`.

#### 2. A three-valued return (0/1/2) where every sibling predicate is 0/1 and 1 means "skip"; a boolean caller reads "refuse" as "skip"

**Severity:** Minor (no precedent for a 3-valued return in `scripts/lib/`; would be Inconsistent against the 0/1-means-skip predicates)
**Location:** `scripts/lib/dev-cycle-read.sh:525-535`, callers :589-590 and :628-629
**Move:** 1 (return-code baseline), 4 (error consistency)
**Confidence:** High
**Legibility-target:** a later caller of `main_checkout` that copies the predicate idiom from `imported_names`

No existing precedent in `scripts/lib/*.sh` (searched `rg 'return 2' scripts test`; the only lib hit is `main_checkout` itself)

Evidence:
```
# reads the caller's ent): 0 for a plain checkout file to walk, 2 when nothing
# there loads (absent, or a plain directory), 1 to fail the walk: a parent main
# stores as a link or gitlink, an unsearchable parent directory, or anything else.
```
and the sibling idiom it sits beside, `imported_names` :551:
```
      if [[ "$seen" != *$'\n'"$p"$'\n'* ]] && inrepo_here "$p"; then seen+="$p"$'\n'; queue+=("$p"); fi
```
`inrepo_here` (:127), `plaindir`, `rawfile`, `dirok` return 1 for "not plain, skip it". `main_checkout` reuses 1 for the opposite intent ("refuse, fail the walk") and moves "skip" to 2. Both in-tree callers handle it correctly (`c=0; main_checkout "$p" || c=$?; [[ $c -ne 1 ]] || ...`), and the contract is documented. But any `if main_checkout`, `main_checkout && …` or `|| continue` caller (the idiom every neighbour invites) treats refuse and skip alike, which in this walk is the fail-open class. `nul_list` and `main_imports` do use 1 for "failed", so 1 = refuse is defensible; the hazard is that a one-bit test cannot tell 1 from 2.

**Recommendation:** Either keep 0/1/2 and add one line to the comment ("never test it with `if` or `&&`: 1 and 2 must be told apart"), or split it so each part is a conventional 0/1 function: a refusal predicate whose 0 means refuse (as `isimported`'s fail-closed 0 does) and the existing `inrepo_here` for the walkable case.

#### 3. `main_checkout` breaks the `main_*` naming grain and reads as git's "main checkout"

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:529`
**Move:** 2 (naming)
**Confidence:** Medium
**Legibility-target:** a reader of the header's Inputs block deciding which functions read the working tree

Precedent: `main_*` names a function that reads the default branch's commit, used in `scripts/lib/dev-cycle-read.sh:253` (`main_by_name`), `:269` (`main_entry`), `:565` (`main_imports`), and the header :28-30 ("main_entry and brief_fields read the default branch's commit, never the working tree")

Evidence: `main_checkout() {` (:529), whose body is `-d`, `-x`, `-r`, `-e`, `-L`, `inrepo_here` and `blocker` on working-tree paths, plus a lookup in the caller's `ent`. "Main checkout" is also git's name for the primary worktree (`git worktree list` marks it), which is exactly the ambiguity the gate's U2b bullet is about ("It names the checkout `--check` runs from"). A reader skimming for "what reads main" will file it with the commit readers.

**Recommendation:** A name in the working-tree grain, e.g. `checkout_admit` (pairs with `checkout_md`) or `walkable_here` (pairs with `inrepo_here`, and like it relies on the caller's `need_root`).

#### 4. The pathspec override row's revisit trigger has fired, but the pathspec is still written twice and the row is untouched

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:519` and `:524`; `docs/reviews/override-log.md:402`
**Move:** 1, 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the override log's reader checking whether a deferred row was discharged

Evidence:
```
untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }
...
checkout_md() { local e; { e="$(GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }
```
and override-log :402: `The checkout .md pathspec is written twice (untracked_md for the tree walk, inline in main_imports) ... | Defer | Revisit trigger: U2a3c's phase-2 seed listing, which should take one name.`

This commit is that phase-2 seed listing. It gave the listing a name (`checkout_md`, which is an improvement on the inline form) but the `GIT_LITERAL_PATHSPECS=0 … ':(glob,icase)**/*.md'` pair is still spelled twice, and the two listings now also differ in error handling: `checkout_md` fails on any git stderr (C3's unreadable directory), while `untracked_md` (the tree walk, `--check-fix`) still reads past the same warning. The row is neither closed nor re-deferred with a new trigger, and the commit message does not mention it. The asymmetry itself is not in this unit's scope to fix (the tree walk is a different floor), but it is the kind of drift the row existed to prevent.

**Recommendation:** One name for the pathspec (e.g. `MD_PATHSPEC=':(glob,icase)**/*.md'` beside `INSTRUCTION_FILE`, or `untracked_md` defined as a call of a shared lister with `--others`), then update override-log :402: closed by U2a3c, or re-deferred with the stderr asymmetry noted and a new trigger.

#### 5. The header's Inputs block still files `main_imports` under "never the working tree"

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:28-35`
**Move:** 3 (documentation drift)
**Confidence:** High (fact-check Claim 6, Mostly accurate)
**Legibility-target:** a caller reading the header contract for which functions depend on the checkout

Evidence:
```
# Inputs: check_brief, check_branch, check_answer, main_entry and brief_fields
# read the default branch's commit, never the working tree (check_brief also
# refuses a brief path that is not plain in the working tree, which the cycle
# writes), and so does main_imports (after main's walk it walks the checkout's
# start files and imported files main lacks, which can only add imports or
# fail it; it needs resolve_main to have found main by name);
# imported_names reads the working tree at ROOT_REAL.
```
"and so does main_imports" attaches `main_imports` to "never the working tree", then the parenthetical says it walks the checkout. After this commit `main_imports` (and so `isimported main`) reads both: main's commit, then the index and working tree (`checkout_md`, `main_checkout`, the `checkout)` arm's `< "$f"`). The block is the one place a caller learns which answers move with the checkout, which matters for the cache contract at :474-476 (Finding 6). The new helpers `checkout_md` (index and working tree) and `main_checkout` (working tree plus `ent`) are not placed in either group.

**Recommendation:** Give `main_imports`/`isimported main` their own clause: "main_imports reads main's commit first, then the checkout's index and working tree (start files and imported files main lacks); its answer therefore depends on the checkout, see IMPORTED_MAIN_DONE".

#### 6. The U2b bullet and F11 no longer say which checkout `--check` must run in, or what U2b's caller must hold fixed

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:279` (U2b bullet), `:126` (F11); `scripts/lib/dev-cycle-read.sh:474-476` (cache contract)
**Move:** 3 (consumer contract), 6 (changed semantics)
**Confidence:** Medium
**Legibility-target:** U2b's implementer, who builds the only production caller of `isimported main`

Evidence, U2b bullet after the commit:
```
It names the checkout `--check` runs from (the walk reads its untracked, ignored and index-only start files and the imported files main lacks there); U2b is to refuse (not built yet; the walk does not check this) a checkout where `git check-attr` shows ... or whose `core.symlinks` is false, and runs the walk under `LC_ALL=C` (A5).
```
and before:
```
It names the checkout `--check` runs from: a fresh worktree at MAIN_SHA, since until U2a3c the walk fails on any start file main lacks, ...
```
The old bullet gave U2b a concrete requirement ("a fresh worktree at MAIN_SHA"); the new one drops it and replaces it with a description of what the walk reads, without saying which checkout's files U2b should want read. That choice now decides the answer: in a fresh worktree the checkout phase has nothing to read (no untracked or ignored files), so it is moot; in the loop's own checkout it reads the files Claude Code will load there (the point of the phase). Of the caller obligations the code now has, the bullet and A5 state `LC_ALL=C`, the attribute and `core.symlinks` refusals, and (implicitly) `resolve_main`. Not stated anywhere U2b will read: (a) run the walk only after the checkout is in its final state, or clear `IMPORTED_MAIN_DONE` (the cache key ignores the checkout, :474-476; override row deferred, now pinned by test, and since this commit a cached `ok` can omit an import a later untracked start adds, rather than merely having failed); (b) a git environment that prints nothing to stderr on `ls-files` (fact-check Claim 10b: `GIT_TRACE=1` or any warning fails the walk closed, so a noisy hardened wrapper would make the floor refuse everything); (c) the checkout-probe bypasses the override log defers to "the caller owns git config" (`GIT_INDEX_FILE`, `core.fsmonitor`, sparse checkout, replace refs), which since this commit hide a start that would now be walked. F11's summary is accurate as far as it goes, but its "U2b names the checkout `--check` runs in" has the same gap.

**Recommendation:** In the U2b bullet, name the checkout (the one the autonomous loop's Claude Code session runs in) and list the caller obligations in one sentence: final checkout state before the walk (or `IMPORTED_MAIN_DONE=""`), quiet git stderr, and the git-config/env items the override row assigns to the caller. Point A5 or F11 at that sentence rather than repeating it.

#### 7. The lib-surface test was not extended to the two new functions

**Severity:** Minor
**Location:** `test/scripts/dev-cycle.bats:1084-1086`
**Move:** 3 (test drift)
**Confidence:** High
**Legibility-target:** the suite that guards the lib's public surface

Evidence:
```
        for f in scrub scrub_reexec rawfile plaindir blocker inrepo dirok skipped pathform isbrief writable need_root \
                 oddwhy check_brief check_branch resolve_main main_by_name main_entry brief_fields lower imported_names check_answer \
                 isclosed entry_why isimported inrepo_here main_imports nul_list import_targets instruction_names untracked_md; do
```
At 5e51b58b this list held every function the lib defines (checked by diffing `rg -o '^[a-z_]+\(\)'` of the lib against it); after cebfed35 `checkout_md` and `main_checkout` are the only two missing. The list already holds the earlier walk helpers (`nul_list`, `untracked_md`, `inrepo_here`, `main_imports`).

**Recommendation:** Append `checkout_md main_checkout` to the list.

#### 8. `isimported main` now answers from the working tree: an intended narrowing of a fail-closed answer, with no production consumer yet

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:589-590`, `:628-629`, `:638-646`
**Move:** 6 (versioning impact)
**Confidence:** High
**Legibility-target:** U2a4's floor author

Evidence: removed line `[[ "${cand[i]:0:1}" == m ]] || return 1  # main lacks it: not walked until U2a3c`, replaced by the `main_checkout` admission at :589-590. Before this commit a start file main lacks failed the walk, so `isimported main` answered imported for every path; now the walk succeeds and answers per path. This is a semantic change to an existing function (a "changed semantics" case under move 6), but it is the plan's stated intent, the only callers are the bats tests (updated in the same commit; `scripts/dev-cycle.sh:181` uses `isimported tree`), and the `isimported` contract itself (a failed walk answers 0) is unchanged. Recorded so U2a4 does not inherit U2a3's "fresh worktree" assumption from older notes such as `docs/working/merge-msg-build-loop-u2a3.md`.

**Recommendation:** None for this unit.

Related (already filed by Stage 1, not re-filed): plan U2a3c bullet :277 and the commit message say the admission check runs before any checkout path is marked seen; for imports `seen[$p]=1` (:626) precedes `main_checkout` (:628) (Claims 4, 17b). The comment on `main_checkout`'s rc 2 ("absent, or a plain directory") also covers a path below a checkout file or dangling link (Claim 11).

## What Looks Good

- `checkout_md` follows the `<scope>_md` producer pattern and plugs into the existing `nul_list` contract unchanged (`nul_list recs checkout_md`), so the "listed whole or fail" rule now covers git's warnings too.
- The two `main_checkout` call sites use one identical, correct idiom (`c=0; … || c=$?; [[ $c -ne 1 ]] || fail`), and the import site's old inline checks (:610-612 at 5e51b58b) are gone, so there is one admission rule instead of two.
- `main_imports`' error contract is preserved: every new failure path either returns before `IMPORTED_MAIN=$'\n'` (start admission, listing) or sets `IMPORTED_MAIN=error` (phase-2 admission, checkout read), matching the existing arms.
- The phase-2 dispatch `${ent[$f]-checkout}` keeps main's arms authoritative for any path main stores, consistent with A5's "only appends" claim (confirmed by Stage 1).
- A5, F11 and the lib block comment now describe the same refusal list, with the "until U2a3c" fail-closed language removed everywhere it appeared.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `main_checkout` reads caller's `ent` by dynamic scope; outside `main_imports` it fails open and arithmetic-evaluates path text | Inconsistent | `scripts/lib/dev-cycle-read.sh:525-535` | High / Medium |
| 2 | 0/1/2 return where sibling predicates are 0/1 (1 = skip); boolean use conflates refuse and skip | Minor | `scripts/lib/dev-cycle-read.sh:525-535` | High |
| 3 | `main_checkout` name breaks the `main_*` = reads-main's-commit grain | Minor | `scripts/lib/dev-cycle-read.sh:529` | Medium |
| 4 | Pathspec still written twice after the override row's trigger fired; row untouched | Minor | `scripts/lib/dev-cycle-read.sh:519, 524`; `docs/reviews/override-log.md:402` | High |
| 5 | Header Inputs block files `main_imports` under "never the working tree" | Minor | `scripts/lib/dev-cycle-read.sh:28-35` | High |
| 6 | U2b bullet / F11 drop the named checkout and omit caller obligations (cache, quiet stderr, git env) | Minor | `docs/working/plan-build-loop-handoff.md:279, 126` | Medium |
| 7 | Lib-surface test omits `checkout_md`, `main_checkout` | Minor | `test/scripts/dev-cycle.bats:1084-1086` | High |
| 8 | `isimported main` semantics narrowed (intended; no production consumer) | Informational | `scripts/lib/dev-cycle-read.sh:589-590, 628-629` | High |

## Overall Assessment

The change fits the lib's conventions in its main moves: `checkout_md` matches `untracked_md` and the `nul_list` contract, `main_imports` keeps its error and fail-closed contract, and the docs drop the "until U2a3c" wording everywhere. The friction is in the new admission helper's interface. It is the lib's first three-valued return, its name sits in the commit-reader grain, and it depends on a caller's local array by dynamic scope. Inside `main_imports` all three are harmless. Called anywhere else, they fail open (and the last one runs command substitutions from path text, shown by an executed probe). Since the helper is billed as "the one admission check", a later unit will plausibly reuse it, so the interface should be made explicit before U2a4/U2b. The remaining items are documentation and test drift that can be fixed in place: the header Inputs clause, the lib-surface test list, the override row whose trigger this commit fired, and above all the U2b bullet, which should again name the checkout and list what U2b's caller must hold fixed. No finding blocks a consumer that exists today.

## Goal-Alignment Note

The goal is to land U2a3c through the review-fix loop with no fail-open in the self-merge floor's input. None of these findings is a live fail-open in the code under review. Finding 1 is the one that touches the security goal: a latent fail-open, plus code execution, that opens only if `main_checkout` is reused outside `main_imports`, and that unit's reviewers would have to catch it. Finding 6 is the next most goal-relevant. U2b is the only production caller, and it can reintroduce a fail-open (a cached `ok` walk taken before an untracked start appears) unless the plan tells it what to hold fixed. Findings 2-5 and 7 are cheap in-place fixes that cut the chance a later unit misreads the contract. Finding 8 needs no action. I found nothing that should route to U2a3b.
