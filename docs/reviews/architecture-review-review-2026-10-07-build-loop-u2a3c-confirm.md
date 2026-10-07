Commit: 380ed01b

# Architecture Review — feat/build-loop-u2a3c (confirming pass after Q-128 [1])

**Scope:** `git diff main...HEAD` in `/workspace/.claude/wt-build-loop-u2a3c`, read against the plan's U2a3c bullet, looking hardest at 4b7f2357. Code: `scripts/lib/dev-cycle-read.sh`. Contract docs: `docs/working/known-issues-dev-cycle.md` (A5), `docs/working/plan-build-loop-handoff.md` (F11 `:126`, U2a3c `:277`, U2b `:279`). The tests and the `docs/reviews/*` history are context only.
**Date:** 2026-10-07
**Based on:** the Stage-1 summary (`u2a3c-i4-stage1.md`) and the `## Escalations` sections of `docs/reviews/code-fact-check-report-build-loop-u2a3c-r{1,2,3}.md`, all at 380ed01b. r1 and r3 escalate the blob-PATH precondition to security and API review. r1 and r2 escalate F11's drift to API review.

## Scope check

In scope, for the same reasons as the previous pass. The diff adds an admission function with shared mutable state (`main_checkout` and its MEMO). It adds a parser output protocol (the `/N` trailer read by `import_work`), a shared reader (`capped_read`) and a walk-wide budget (`IMPORT_WORK_MAX`). It also states the walk's caller contract for U2a4 and U2b. 4b7f2357 changes `main_checkout`'s domain at PATH and the contract text in the U2b bullet, A5 and F11.

## Dependency Map

The map is unchanged since 3a35c8b9. `isimported main` calls `main_imports`. `main_imports` calls `nul_list`, `checkout_md`, `lower_all`, `main_checkout` (which calls `rawfile` and `plaindir`), `capped_read`, `import_targets` and `import_work`. `imported_names` calls the same reader, parser and budget. A grep finds no caller of `main_checkout` outside the lib and its bats files. The only "second caller" is the hypothetical one in the U2b bullet (`:279`).

4b7f2357 adds one dependency edge inside `main_checkout`: PATH's own entry in ENT. Line `:743` reads `[[ ! "${mc_e[$3]:-}" =~ ^1[26]0000$ ]] || return 1`. That is the same predicate the ancestor loop applies at `:749`.

Trust-boundary cross-reference: no `docs/reviews/security-review-*.md` exists for this diff. The most recent file is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`). Its `B2` (instruction files → the import walk → the refusal set) is the boundary whose main-walk admission step `main_checkout` implements. That security review predates this diff, so the boundary may be stale. Nothing below moves it.

## Verification of the previous pass's F1 (the reason for 4b7f2357)

The previous pass's F1 was a Coupling finding: the MEMO's validity depended on an unstated precondition that PATH is not in ENT. I recommended a broad guard, `[[ -z "${mc_e[$3]+set}" ]] || return 1`. The fix took a narrower guard, which refuses only a link or gitlink at PATH. I re-ran the previous pass's probe in scratch (`/tmp/u2a3c-i4-arch-D52U`): a checkout directory `a/` holds `f.md`, ENT varies over the values `a` can take, and the calls go `a` → `a/f.md` on one MEMO, then `a/f.md` on a fresh MEMO.

```
100644: a=2 then a/f.md=0 memo=d fresh a/f.md=0
120000: a=1 then a/f.md=1 memo=unset fresh a/f.md=1
160000: a=1 then a/f.md=1 memo=unset fresh a/f.md=1
none: a=2 then a/f.md=0 memo=d fresh a/f.md=0
```

The answer no longer depends on call order for any ENT value. The narrow guard is structurally better than the broad one I proposed. It makes PATH obey the same rule as every ancestor (`:749`): refuse main's link or gitlink, and otherwise answer by the checkout's shape. So `mc_m[$c]=d` at `:760` now holds "own and every higher ancestor's main mode passed" by construction, as the comment at `:723-724` says. The Stage-1 differential agrees: about 45,000 random-order calls matched 21b35ebf, except the intended 1 at main's link or gitlink PATH. F1 is closed.

## Findings

#### F1. The U2b bullet makes a blob PATH part of `main_checkout`'s contract, but where the caller then reads the content lives only in `main_imports`' case arm

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:279`; `scripts/lib/dev-cycle-read.sh:726-729`, `:843`
**Move:** 3 (module boundary / encapsulation), 2 (responsibility placement)
**Confidence:** Medium (the analysis is High. Whether any second caller will ever exist is unknown, because none is planned beyond this sentence.)
**Legibility-target:** the U2b bullet's sentence "A caller of `main_checkout` other than `main_imports` passes … a PATH main lacks or stores as a blob"

Evidence. 4b7f2357 wrote the domain into the plan:

> A caller of `main_checkout` other than `main_imports` passes a fresh MEMO per walk and ENT (a MEMO hit skips main's mode check too) and a PATH main lacks or stores as a blob (a link or gitlink there answers 1)

The lib comment says only:

```
# main_imports calls it only for paths main lacks.
# 0 for a readable plain checkout file to walk, 2 when nothing there loads
```

`main_imports` never acts on a 0 for a path main stores. It chooses which content to read by ENT, not by `main_checkout`'s answer (`:843`, `case "${ent[$f]-checkout}" in`, where a path main stores reads `git cat-file blob "$MAIN_SHA:$f"`). That choice is settled ("read arm chosen by absence from `ent`").

For a blob PATH, `main_checkout`'s 0 therefore means "the checkout's plain file is admissible". It does not mean "walk the checkout's bytes". The comment's "0 for a readable plain checkout file to walk" reads as the second.

The two cases a blob PATH covers differ in safety:

- **A checkout directory at a blob PATH** (answer 2, memoized `d`). This is the same answer `main_imports` already gives to an ancestor main stores as a blob (`:749` passes 100644). The walk only appends, so it can only add paths a reader of main's checkout would not see. It is safe whether or not the worktree is clean.
- **A plain checkout file at a blob PATH** (answer 0). A second caller that took the comment literally and read the checkout file would miss imports that main's blob holds and a dirty checkout lacks. That is safe only under U2b's clean-worktree duty. The duty's stated reason at `:279` names a different consequence ("an edited tracked instruction file's own imports go unread").

So the r1/r3 escalation is half right. The directory case does not need the clean-worktree duty. The file case needs it, unless the caller also routes by ENT, and nothing written tells a second caller to do that.

The design cost is small, because no second caller exists or is planned. That is also the point: the plan now widens a function's contract for a hypothetical caller. The widened part depends on a content-source rule that lives in one caller's case statement.

**Recommendation:** Pick one of two fixes. (a) Narrow the U2b sentence to "a PATH main lacks". That is `main_imports`' only use, and it makes the lib comment at `:726` the whole domain. A blob PATH then falls outside the contract, and its answers stay safe as shown above. (b) Keep the blob PATH, and add to the same sentence: "for a PATH main stores, 0 only admits it; read main's blob, as `main_imports` does". Either fix is one clause, with no code change.

#### F2. F11 now enumerates a third, partial copy of the caller contract, which drifted when 4b7f2357 added a duty to U2b

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:126` (F11) against `:279` (U2b)
**Move:** 2 (responsibility boundaries)
**Confidence:** High (fact-check r1 and r2 report the same drift, "Mostly accurate")
**Legibility-target:** F11's parenthetical "the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet"

Evidence. F11 lists three duties:

> the caller contract (cache clear, empty `ls-files` stderr, the git environment) is in the U2b bullet

The U2b bullet, as rewritten by 4b7f2357, lists more:

> owes the walk four things: that checkout a clean worktree at MAIN_SHA (the walk reads main's blob for every path main stores, so an edited tracked instruction file's own imports go unread: U2a3c final security F2)

The bullet also names `LC_ALL=C` and the `main_checkout` duties.

The settled row on the contract describes it as living in two places, the lib and the U2b bullet, with A5 now pointing at both. F11's parenthetical restates the U2b half rather than pointing at it. That makes it a third copy, and the first new duty after the deferral already missed it. This does not reopen the deferral to U2a4. It is a pointer that should not carry a list.

**Recommendation:** Replace F11's parenthetical with a bare pointer ("the caller contract is in the lib's block comment above `IMPORTED=` and the U2b bullet", matching A5), or drop it. If an override row is preferred, append it to the existing contract-split row with U2a4 as the trigger.

## Settled, not re-filed

- **The parse chain written three times, and `main_checkout` as a second traversal beside `blocker`.** The premise is unchanged: the chain is still one line at each of the three read sites, and the comment above `main_checkout` still says "a second traversal on purpose".
- **The caller contract split between the lib comment and the U2b bullet, deferred to U2a4.** The premise is unchanged for those two homes. F1 and F2 above are each a single clause inside that deferral. Neither asks for the consolidation now.
- **The read arm chosen by absence from `ent`.** It is settled, and F1 relies on it rather than contesting it.
- **The rubric D2 author note.** All three fact-check replicates say the note's reason for preferring the narrow guard (it would break T1's blob row) is wrong. That is history prose, not architecture. The narrow guard is still the better structure, for the symmetry reason given above, so no code change follows.

## What Looks Good

- **The narrow guard unifies PATH with its ancestors.** One rule now holds at every level of a path: main's link or gitlink refuses, and otherwise the checkout's shape decides. The "set only once … main mode passed" invariant is true by construction, so the MEMO is order-independent for every ENT value (probe above).
- **The O(1) type check (`${mc_e[0]@a}`) keeps the defensive ENT/MEMO type test.** Iteration 1's A1 fix survives without its linear cost, and the comment at `:740-741` says why the subscript is there.
- **4b7f2357 changes no structure.** The diff adds one line of guard, one changed test and comments. No new function, global or protocol appears, so the boundaries the earlier passes approved are intact. These include `capped_read` as the one reader, `IMPORT_WORK_MAX` sent through the existing environment channel, the removed `.git` special case, and admission before `seen` at both phase-2 sites.
- **A5 now says which part of the contract lives where**, which resolves the previous pass's "two pointers name different homes" for A5. Only F11's list remains (F2).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The U2b bullet admits a blob PATH to `main_checkout`'s contract. Its 0 there means "admissible", not "read the checkout", and that content-source rule lives only in `main_imports`' case arm. | Minor | plan `:279`; lib `:726-729`, `:843` | Medium |
| 2 | F11's parenthetical lists a third, partial copy of the caller contract, which is missing 4b7f2357's clean-worktree duty and `LC_ALL=C`. | Informational | plan `:126` vs `:279` | High |

## Overall Assessment

4b7f2357 closes the previous pass's Coupling finding, and does it better than that finding's own recommendation. Refusing only main's link or gitlink at PATH makes the PATH check identical to the ancestor check. The MEMO invariant therefore holds by construction, and call order no longer matters. The change adds no structure. Both remaining items are one-clause doc fixes, and neither involves a reachable code path. The most important one is F1. The plan now invites a hypothetical second caller to pass a blob PATH without saying that `main_checkout`'s 0 only admits it, and that content for a path main stores comes from main's blob. No trust-boundary placement is moved or contradicted.

## Goal-Alignment Note

The goal is to land `feat/build-loop-u2a3c` on main once its review-fix loop is clean.

- No Structural or Coupling finding, so nothing here is 🔴 Must Fix or 🟡 Must Address.
- F1 (Minor) and F2 (Informational) map to 🟢 Consider. Each can be a one-clause edit in a docs-only commit. Each can also go to an override row under the existing U2a4-triggered contract-split deferral without blocking the merge.
- From the architecture lens, the branch is mergeable as is. Nothing here reopens a settled decision.
