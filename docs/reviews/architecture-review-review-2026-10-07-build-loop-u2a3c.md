Commit: 21b35ebf

# Architecture Review — feat/build-loop-u2a3c (U2a3c checkout phase), loop pass 2

**Scope:** `git diff main...HEAD` (main e5d0f838, HEAD 21b35ebf): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`, `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11, U2a3c, U2b), `docs/reviews/override-log.md` (new rows). The cb9723c3 iteration-1 reports are context only.
**Date:** 2026-10-07
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2a3c.md` (Commit 21b35ebf), especially its Escalations; plan bullet U2a3c.

Scope check: in scope. Public lib surface changes (new functions `capped_read`, `lower_all`, `import_work`; `main_checkout`'s signature goes from `ENT PATH` to `ENT MEMO PATH`; new global `IMPORT_WORK_MAX`), a changed output format of the shared parser `import_targets` (the opt-in `/N` trailer), and the documented caller contract of the gate's walk, which U2a4 and U2b consume.

Trust-boundary cross-reference: `ls docs/reviews/security-review-*.md` matches only older reviews of other diffs (newest by name `security-review-2026-10-02-digest-pass38.md`, Commit 90364c73, not this branch). This branch's security review uses another file name: `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3c.md` (Commit: cebfed35). Its map is cited below where a finding touches it. That review predates this diff (pre-rebase), so the boundary may be stale.

## Dependency Map

All changes sit in one module, `scripts/lib/dev-cycle-read.sh`, a sourced bash library. Its consumers are `scripts/dev-cycle.sh` (`isimported tree` through `check_fix`) and, from U2a4 and U2b, the self-merge floor and `build-loop.sh --check` (`isimported main`). Inside the lib the layering is:

- **Primitives:** `rawfile`, `plaindir` (realpath plainness), `blocker` (top-down skip rule), `nul_list`, `md_ls`.
- **Readers:** `capped_read` (new; all parsed input), `checkout_md` (listing), `lower_all` (new; batch case-fold).
- **Parser:** `import_targets` (awk `IMPORT_AWK`). Input knobs come through the environment (`IMPORT_LEFT`, now `IMPORT_WORK_LEFT`). Output is names, now plus an optional `/N` work trailer.
- **Budget accounting:** `import_work` (new) strips the trailer and charges `IMPORT_WORK_MAX`. The `used += ${#out}` lines charge `IMPORT_OUT_MAX`.
- **Admission:** `main_checkout ENT MEMO PATH` (rewritten). It now walks ancestors itself, where 27364085 delegated to `inrepo_here`/`blocker`.
- **Walks:** `imported_names` (tree) and `main_imports` (main, then checkout phase), each composing reader → parser → budget → admission.
- **Query:** `isimported tree|main`.

Dependencies flow downward: walks → admission/parser/readers → primitives. No new upward or circular dependency. The new coupling is horizontal, a protocol between the parser and the walks (the trailer). The walk's contract upward to its callers lives in three documents (lib block comment, A5, plan U2b bullet) and now disagrees across them.

## Findings

#### F1. The walk's caller contract lost its plan and A5 homes in the rebase; U2a4/U2b would read an incomplete contract

**Severity:** Coupling
**Location:** `docs/working/plan-build-loop-handoff.md:279` (U2b bullet), `docs/working/known-issues-dev-cycle.md:18` (A5), `scripts/lib/dev-cycle-read.sh:477-489`, `docs/reviews/override-log.md:439-441,446`
**Move:** 3 (module boundary: the contract a consumer must honour), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** docs (plan U2b bullet, A5, override rows)

The walk caches without the checkout in its key. It fails closed on any `ls-files` stderr, and it trusts the git environment. Each of these puts an obligation on the caller. Before the rebase, the obligations were written where the next units' implementers read: the plan's work order for U2b and A5. Pre-rebase U2b bullet (`git show backup/u2a3c-pre-rebase-2b1399ab:docs/working/plan-build-loop-handoff.md`, line 279):

```
It names the checkout `--check` runs from (the walk reads its untracked, ignored and index-only start files and the imported files main lacks there) and owes the walk three things: that checkout final before the walk, or `IMPORTED_MAIN_DONE` cleared (the cache key ignores the checkout); a git that prints nothing on stderr for `ls-files` (any stderr fails the walk closed); and the git environment the override log hands the caller (`GIT_INDEX_FILE`, `GIT_WORK_TREE`, fsmonitor, sparse checkout, `core.ignoreCase`, replace refs); U2b is to refuse ...
```

HEAD (`plan-build-loop-handoff.md:279`):

```
It names the checkout `--check` runs from (the walk reads its untracked, ignored and index-only start files and the imported files main lacks there); U2b is to refuse (not built yet; ...
```

The "owes the walk three things" clause is gone. Pre-rebase A5 had `a start file that is not a regular file or symlink (git does not list a FIFO), a checkout file swapped between its admission and its read` in its not-covered list and `The walk's cache ignores the checkout, so a caller clears \`IMPORTED_MAIN_DONE\` after any checkout change.` HEAD's A5 has none of them (fact-check Claims 1-3). Only the lib block comment keeps the cache rule, the FIFO and the snapshot (`:480-489`). Its pointer `Not covered (known issue` / `# A5)` (`:477-478`) now names a row that lacks two of the items that follow it. Nothing in the plan or A5 points U2b at override row 387 (`Untested bypass candidates for the checkout probes: GIT_INDEX_FILE or a core.fsmonitor hook hiding an untracked start, replace refs ...`), so the git-environment obligation has no forward pointer. Three override rows (`:439`, `:440`, `:441`) record their Defer/Won't-Fix as mitigated by text that is no longer in A5 or U2b. Row `:446` cites a record-line comment that 3e58eb9c removed.

Consequence: the first caller is U2b's `--check` (plus U2a4's floor over `isimported main`). It is the one that must clear `IMPORTED_MAIN_DONE` after touching the checkout and must scrub the git environment. Its work order no longer says so. A caller that walks once, edits or merges into the checkout, and asks `isimported main` again gets the cached list for the old checkout: a stale answer at the gate. That is the failure the cache-key deferral was accepted on condition of avoiding. The lib comment is where the contract is stated, but U2b's builder plans from the bullet. The deferrals' safety now depends on a reader finding a code comment the work order does not cite.

**Recommendation:** Make the lib block comment the single statement of the walk's caller contract, and label it as such, as the lib already does for the superset claim (`the one statement of it; known issue A5 and plan F11 point here`, `:526-527`). Restore U2b's "owes the walk three things" clause as a work-order item that points there and at override row 387. Restore the FIFO and snapshot items to A5's not-covered list, or make A5 point at the lib list. Correct rows 439-441 and 446 (append a row; the log is append-only).

#### F2. The reader → parser → budget composition is spelled out at three sites, so the trailer protocol has no single owner

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:760-763` (imported_names), `:821-824` and `:846` (main_imports, both parse arms), `:625`, `:669-678`
**Move:** 7 (coupling surface: control/stamp coupling through an in-band channel), 2
**Confidence:** High
**Legibility-target:** code

```
out="$(capped_read < "$f" | IMPORT_LEFT=$((IMPORT_OUT_MAX - used)) IMPORT_WORK_LEFT=$((IMPORT_WORK_MAX - work)) import_targets "$d")" \
  && import_work out work || { IMPORTED=error; return 1; }
```

The same line appears for the checkout arm and, with `git cat-file blob "$MAIN_SHA:$f" | capped_read |`, for the blob arm. Each is followed by `(( (used += ${#out}) <= IMPORT_OUT_MAX ))` (`:763`, `:846`). The trailer itself is a sound design for this codebase. It is opt-in, and output with `IMPORT_WORK_LEFT` unset is byte-identical to main's (fact-check Claim 13). The `/` sentinel is unambiguous because `put` strips the root prefix and returns before printing a name no longer than it (Claim 15). A missing trailer fails the walk closed (`import_work` returns 1). The protocol has three parts that must stay paired: set `IMPORT_WORK_LEFT`, call `import_work` before using `out`, and charge `used` after. That pairing is now copied three times, and the no-leading-slash invariant it relies on is internal to `put`, stated only in `import_work`'s comment. Two consequences follow. A future site (a third arm, or a U2a4/U2b helper that parses one file) that sets the env var but skips `import_work` leaks `/N` into `IMPORTED*` as a name. A change to `put` that can emit a leading `/` silently breaks the stripping. This is the place the plan's "one capped and drained reader" and "charged to the same budgets" are both enforced, and it is open-coded rather than owned.

The trailer rides the parser-output channel that the branch's security review labels `B3: [checkout file bytes, S3] → [import_targets "$d" < "$f" (checkout arm)] → [IMPORTED_MAIN (gate floor input)]` (`docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a3c.md`, Commit: cebfed35, a security review that predates this diff, so the boundary may be stale). Extracting the composition into one function does not move that crossing.

**Recommendation:** Fold the three sites into one walk-private helper (for example `parse_one D OUT USED WORK`, reading stdin), so the env knobs, the trailer strip and both budget charges live in one function. Add a parser test asserting that no name line starts with `/` on adversarial input (`@/`, `@//x`, `@~/` forms), so the sentinel's invariant is pinned beside `put` and not only in a comment. Pragmatic to defer to U2a4 if the loop is at its cap.

#### F3. main_checkout re-implements blocker's top-down plainness walk instead of memoizing blocker

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:711-742` vs `:114-124`
**Move:** 2 (responsibility boundaries), 8 (extension vs modification)
**Confidence:** Medium
**Legibility-target:** code comment

The lib states one rule (`One rule decides whether an input is skipped, for files and directories alike: walking the path top down, the first part that exists but is not plain ... blocks it`, `:107-109`). At 27364085 the admission check delegated to it: `if inrepo_here "$c"; then [[ -r "$c" ]]; return; fi` / `[[ -d "$c" && ! -L "$c" && -z "$(blocker "$c" dir)" ]] || return 1`. 80cc6224 replaced that with its own loop:

```
    if [[ ! -e "$c" && ! -L "$c" ]] || rawfile "$c"; then st=2
    elif plaindir "$c" && [[ -x "$c" ]]; then mc_m[$c]=1
    else return 1; fi
```

The plan item was "memoize `blocker` per directory prefix (L2-C6)". The two walks now encode top-down plainness differently on purpose: a plain-file ancestor blocks under `blocker` but answers 2 here, and `-x` is required only here. They share only the `rawfile`/`plaindir` primitives. The comment acknowledges the relation (`The plain tests are rawfile's and plaindir's, which blocker applies top down`, `:720`), but not that the traversal is now a second copy. U2b's planned refusals (`core.symlinks=false`, case-insensitive names) and any change to what counts as plain then have two traversals to keep in step. The primitives are single-sourced, which limits the damage, so this is Minor.

**Recommendation:** Either state in main_checkout's comment that it is a deliberate second traversal (admission, not skip) and list where it differs from `blocker`, or give `blocker` an optional memo and have main_checkout layer its mode and `-x` checks on top. The comment is the cheap fix for this loop.

#### F4. main_checkout's MEMO is valid only for one ENT and one checkout snapshot, which the signature does not say

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:711-728`, `:788`
**Move:** 3, 7
**Confidence:** Medium
**Legibility-target:** code comment

The two namerefs are sound at the only call sites. `ent` is read-only data, and `pok` is a caller-owned cache declared `local -A ent=() seen=() dir=() pok=()` (`:788`), so its life is exactly one walk. The `mc_e`/`mc_m` prefixes avoid a circular nameref. A memo entry means "passed the mode check against this ENT and was a plain searchable directory when probed": `elif plaindir "$c" && [[ -x "$c" ]]; then mc_m[$c]=1`, reached only after `[[ ! "${mc_e[$c]:-}" =~ ^1[26]0000$ ]] || return 1`. The comment says only `MEMO one of the ancestors already passed`. A future caller (U2b running main_checkout on starts, as override row 440's revisit trigger suggests) that keeps a MEMO across walks or across ENTs would skip both checks for a stale entry. The same `local -; set +u` that makes the empty-array type test work is correctly scoped (fact-check Claim 20).

**Recommendation:** Add to the signature comment: "MEMO must be fresh per walk and per ENT (a local -A beside ENT)".

#### F5. "One reader" holds for parsed input only; the symlink arm is a second, uncapped reader of main's blobs

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:697-703`, `:828-829`, `docs/reviews/override-log.md:449`
**Move:** 2
**Confidence:** High
**Legibility-target:** docs (override row)

`capped_read` is the one reader of every byte the parser sees. The 120000 arm still reads each link blob in full, twice: `if ! i="$(git cat-file blob "$MAIN_SHA:$f" | tr -cd '\0' | wc -c)" ...` and `out="$(git cat-file blob "$MAIN_SHA:$f" && printf x)"`. The lib comment's `the one reader both walks parse` is precise. The L2-C5 closing row (`capped_read is the one reader for checkout files and main's blobs`) is broader than the code (fact-check Claim 17). The cost belongs to performance. The architectural point is that the plan's "one reader" boundary has one documented exception that the closing row hides.

**Recommendation:** Narrow the closing row with an appended row, or route the link arm through `capped_read` (link text over 4 MiB is refused anyway).

#### F6. The lib's surface inventory test omits import_work

**Severity:** Informational
**Location:** `test/scripts/dev-cycle.bats:1106-1110`
**Move:** 3
**Confidence:** High
**Legibility-target:** test

The sourcing test enumerates the lib's functions as its declared surface: `... md_ls checkout_md main_checkout lower_all capped_read; do` / `declare -F "$f" >/dev/null || echo "missing $f"`. `import_work`, new in 61e2e734, is missing. The vars loop lists `IMPORTED_MAIN_DONE` but not the new `IMPORT_WORK_MAX` (nor the pre-existing `IMPORT_OUT_MAX`). The inventory stops being a complete registry of what the lib exports.

**Recommendation:** Add `import_work` to the function list, and `IMPORT_OUT_MAX IMPORT_WORK_MAX` to the variable checks.

## What Looks Good

- **Plan conformance of the walk's shape.** There is one drain loop over two seedings: `while [[ ${#queue[@]} -gt 0 || ${#tq[@]} -gt 0 ]]; do [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }` (`:814-815`). There is one admission check before `seen` at both sites (`:809-811`, `:852-854`). Phase 2 shares `ent`, `seen`, `used` and `work`, so it is charged to the same budgets. No third path resolver was added: main_checkout walks components lexically and resolves nothing from import text.
- **`.git` special case removed.** Treating `.git` as an ordinary checkout path through the one admission check, instead of a branch in the walk, removes a special case (OCP in the right direction). The three inverted tests pin it.
- **`capped_read` as a named reader** with the drain inside it, not at each call site, puts the SIGPIPE/pipefail concern in one place.
- **The trailer is opt-in and fails closed.** Parser output is unchanged for direct callers and tests. A walk that expects the trailer and gets none fails.
- **`IMPORT_WORK_MAX` mirrors `IMPORT_OUT_MAX`** (global knob, `*_LEFT` passed per call, same cache-clear note), so the second budget follows an established pattern.
- **A1-A3 and C1 survived the rebase:** non-associative ENT/MEMO returns 1, the fast `[[ -e || -L ]] || return 2` comes before any fork, and admission comes before seen (fact-check Claims 19, 23).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Walk's caller contract (cache clear, empty ls-files stderr, git env, FIFO, snapshot) dropped from U2b bullet and A5; override rows cite the missing text | Coupling | `plan-build-loop-handoff.md:279`, `known-issues-dev-cycle.md:18`, `override-log.md:439-441,446` | High |
| 2 | Reader → parser → trailer-strip → budget composition triplicated; trailer protocol and its no-`/` invariant have no single owner | Minor | `dev-cycle-read.sh:760-763,821-824,846` | High |
| 3 | main_checkout is a second top-down plainness traversal beside blocker (plan said memoize blocker) | Minor | `dev-cycle-read.sh:711-742` vs `:114-124` | Medium |
| 4 | MEMO's validity (one walk, one ENT) unstated in the signature | Informational | `dev-cycle-read.sh:711-728,788` | Medium |
| 5 | Symlink arm is a second uncapped reader of main blobs; L2-C5 closing row overstates "one reader" | Informational | `dev-cycle-read.sh:828-829`, `override-log.md:449` | High |
| 6 | Surface inventory test omits `import_work`, `IMPORT_WORK_MAX` | Informational | `test/scripts/dev-cycle.bats:1106-1110` | High |

## Overall Assessment

In code, the rebased design does what the plan asked. One drain loop runs over two seedings, one admission check sits before `seen`, no third resolver was added, one capped and drained reader feeds the parser, and phase 2 is charged to the same two budgets. The new parser trailer is a sound, fail-closed coupling between `import_targets` and the walks, though its three-part protocol is open-coded at three sites (F2). The two-nameref `main_checkout` is correctly scoped at its only caller (F4). The single most important structural concern is not in the code. It is where the walk's contract lives (F1). The rebase resolution kept main's A5 and U2b wording and so dropped the obligations U2a3c places on its first callers: clear `IMPORTED_MAIN_DONE` after a checkout change, run git with silent `ls-files` stderr, and hand over a scrubbed git environment. The deferrals that accepted those risks still cite the dropped text. The fix is documentation only and can be made in place: one labelled statement in the lib, pointers from A5 and a restored U2b work-order clause, and appended override rows. No restructuring is needed.

## Goal-Alignment Note

The goal is to land `feat/build-loop-u2a3c` on main once its review-fix loop is clean. Nothing here blocks the code. There is no Structural finding. F1 (Coupling, so Must Address in the rubric) is a docs-only fix in this branch's own files (plan U2b bullet, A5, appended override rows), and it is worth making before merge. U2a4 and U2b are the next units, and they plan from those bullets. Merging without it hands them a contract that silently omits the cache-clear and git-environment obligations. F2-F6 are Consider-tier. F2 and F3 can be deferred to U2a4 with override rows if iteration 3 is the cap.
