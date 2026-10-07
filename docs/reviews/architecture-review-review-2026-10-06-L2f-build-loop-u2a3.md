Commit: 1898d21c

# Architecture Review — feat/build-loop-u2a3 (loop 2, final confirming pass)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 1898d21c). The structural review covers `scripts/lib/dev-cycle-read.sh` (main_imports :546-611, nul_list :517, isimported main :617-626, header :29-35 and block :452-474). The plan, the A5 known issue, the tests and the review artifacts were read for context.
**Date:** 2026-10-06
**Based on:** the loop-2 final fact-check summary (replicates `docs/reviews/code-fact-check-report-build-loop-u2a3-L2f-r1.md`, `-r2.md`, `-r3.md`, Commit 1898d21c). Trust boundaries come from `docs/reviews/security-reviewer-review-2026-10-06-L2-build-loop-u2a3.md` (Commit: 5c57d367). That review predates this diff (dfeeb85d added the index listing), so its boundaries may be stale. The skill's `security-review-*.md` glob matches only older digest reviews, so this report uses the branch's own security review instead.

**Scope check:** in scope. The diff adds a public lib function (`main_imports`), a new `isimported main` selector, a shared helper (`nul_list`, which U2a3b reuses) and module globals with a cache contract (`IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`).

**Settled rows not re-filed:** two-phase walk (taken as the split), cache ignoring checkout state, errexit off inside `isimported main`, unsearchable checkout directory (Defer to U2a3c), link_target helper, no reason word on a failed walk, submodule and nested-repo starts, the deep-token O(L x depth) cost (row :386), untested git-hardening bypasses (row :387, to U2b). Finding 1 is not covered by row :379: that row records the blob-and-tree doubled name, which fails closed. Finding 1 is the tree-and-symlink doubled name with the tree listed first, which the row did not probe.

**Probe:** `/tmp/u2a3-arch2f-i2-Bkxp/probe.sh` reproduces the fact-check's r3 Claim 13b against the worktree lib. It ran under `timeout` and left no processes behind.

## Status of the loop-2 iteration-1 architecture findings

| L2 i1 # | Status at 1898d21c | Where |
|---|---|---|
| 1 One admission predicate for phase 2 | Carried as a written constraint | plan U2a3c bullet ("every phase-2 item passes one admission check ... before it is marked seen") |
| 2 `*) continue` skips an unmodelled item | Fixed | lib :597 `160000) continue`, :598 `*)` fails |
| 3 Checkout side defined against the index | Fixed | lib :562 lists `--cached` too; a start main lacks that the index holds fails (:570) |
| 4 Gate unusable in a dirty checkout | Documented | plan U2b bullet (fresh worktree at MAIN_SHA), F11, A5, header :32-34 |
| 5 Phase 2 as one drain loop over two seedings | Carried | plan U2a3c bullet |

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` is a leaf that `dev-cycle.sh` and `build-loop.sh` source. Nothing calls `main_imports` yet; `dev-cycle.sh:181` calls only `isimported tree`. U2a4's floor will be the first caller of `isimported main`. The new code depends on:
  - lib primitives: `need_root`, `main_by_name`, `untracked_md`, `nul_list`, `blocker`, `lower`, `INSTRUCTION_FILE`
  - the shared parser `import_targets`
  - git plumbing: `ls-tree`, `ls-files`, `cat-file`

  No dependency points outward, so the dependency direction is unchanged.
- `main_imports` has this shape at HEAD:
  - **Index of main** (:553-560): `ent`, a flat map from each path `ls-tree -r` lists to its mode. Start candidates are tagged `m:`.
  - **Checkout listings** (:561-563): the untracked/ignored list and, since dfeeb85d, the index's `.md` list. Every path missing from `ent` is tagged `t:`.
  - **Start loop** (:567-573): a `t:` start fails the walk (:570); `m:` starts seed `seen` and `queue`.
  - **Drain loop** (:575-610): a dispatch on `ent[$f]` (:578-599) with a fail-closed default, then one producer (:600-609).
- **Checkout reads (B2):** :561, :562, the `-L` probes (:593) and the main-lacks shape probe (:608). Each leads only to `return 1`. So a *successful* result still depends on main's commit (B1) alone. The fact-check confirmed this across 22+ checkout states.

## Findings

#### 1. `ent` flattens main's tree to a path map but checks only exact duplicates, so a name stored as both a tree and a symlink passes and the walk reads a different file than the checkout holds

**Severity:** Minor (structural). The consequence is a fail-open in the gate's answer, so the security reviewer owns whether it blocks the merge.
**Location:** `scripts/lib/dev-cycle-read.sh:553-560` (check at :557); consumers :579 and :583-584 (`git cat-file blob "$MAIN_SHA:$f"`)
**Move:** 3 (the data model behind the module boundary), 6 (an unchecked invariant the contract relies on)
**Confidence:** High (executed: reproduced r3 Claim 13b at 1898d21c)
**Legibility-target:** Implementer of this unit, and the security reviewer, who decides merge-blocking

**Evidence:**
```
553:  nul_list recs git ls-tree -r -z --full-tree "$MAIN_SHA" || return 1
554:  for rec in "${recs[@]}"; do
555:    [[ "$rec" =~ ^([01234567]{6})\ ...\t'(.+)$ ]] || return 1
556:    f="${BASH_REMATCH[2]}"
557:    [[ -z "${ent[$f]+set}" && "$f" != *$'\n'* ]] || return 1
558:    ent[$f]="${BASH_REMATCH[1]}"
559:    [[ "$f" != *.[mM][dD] ]] || cand+=("m:$f")
560:  done
```
(:555 is abridged. The listing loop ends at :560. The rest of `main_imports`, through :611, was read in full.)

Probe output: main's root tree lists `l` twice, as a tree holding `x.md` (benign text) first and then as a symlink `l -> docs`. `AGENTS.md` imports `@l/x.md`, and `docs/x.md` imports `@secret.md`. `ls-tree -r` prints `l/x.md` and then `l`. The fresh worktree checks out `l -> docs`. The result is `walk ok`, and `IMPORTED_MAIN` holds only `l/x.md`. So the walk read the tree's blob, while Claude Code in that worktree would read `docs/x.md` and import `docs/secret.md`, which the floor would then let a loop self-merge.

The structural cause is the data model. `ent` treats main's tree as a flat, prefix-free namespace: no listed path is an ancestor of another. `ls-tree -r` never lists a tree itself, so in a canonical tree that holds. The parse checks only exact duplicates, so the invariant is assumed and not enforced. The checks that rely on it then work from a model that differs from what git checks out:
- the parent-link check (:607)
- the `-L`/`ent` link test (:593)
- the `cat-file "$MAIN_SHA:$f"` reads, which take git's first copy

This is not a regression (same at cc1aa864). It needs a non-canonical tree object (`hash-object --literally`; fsck flags `duplicateEntries`) to land on main.

**Recommendation:** Enforce the invariant where `ent` is built: after the listing loop, fail if any key's proper prefix is itself a key. That is the same `c="${c%/*}"` walk as :607, run once over `ent` and checking `${ent[$c]+set}`, which keeps the model's invariant in one place. The unit is at its 400-line cap. Finding 2's merged listing frees a line, or the check can share :607's loop shape in a small helper. Add the probe's tree-first fixture as a test; the blob-first order (row :379) already fails.

#### 2. The checkout listings are two calls with the pathspec repeated inline, which leaves phase 2's seed set defined in two places

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:515` (`untracked_md`), `:561-563`
**Move:** 2 (responsibility), 8 (extension point for U2a3c)
**Confidence:** High (code read)
**Legibility-target:** Implementer (an optional line saving under the cap), and the U2a3c author

**Evidence:**
```
515:untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }
561:  nul_list recs untracked_md || return 1; low=("${recs[@]}")
562:  nul_list recs env GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached -- ':(glob,icase)**/*.md' || return 1
563:  for f in "${low[@]}" "${recs[@]}"; do [[ "$f" != *$'\n'* ]] || return 1; [[ -n "${ent[$f]+set}" ]] || cand+=("t:$f"); done
```

dfeeb85d closed L2 i1 Finding 3 correctly: the checkout side is now "everything the checkout lists that `ent` lacks". It did so by adding a second listing beside `untracked_md`, with the env prefix and pathspec copied, and borrowing `low` as a temporary. U2a3c's phase 2 seeds from exactly this set. The set is now defined by two adjacent calls, and they must stay in step: a pathspec change to one and not the other (case, or `.mdx`) silently narrows the seeds. `imported_names` (:526) builds its own `git ls-files -z; untracked_md` pair as well.

**Recommendation:** Optional. Write one helper, such as `checkout_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md'; }`, and call it once at :561. That saves the line Finding 1 needs and gives U2a3c one named seed source. Otherwise, carry it to U2a3c.

#### 3. The index listing ties the walk's first refusal to the test checkout's index, which masks three refusals in the tests

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:562`, `:570`; `test/scripts/build-loop-check.bats` tests 5, 9 and 12 (fact-check r1 Claims 24-26, r2 Claim 23)
**Move:** 7 (coupling between the tests and the checkout state)
**Confidence:** High (on the fact-check's executed mutants, 16/16 pass for each single mutant)
**Legibility-target:** Test-strategy reviewer and the implementer

**Evidence:** Tests 5, 9 and 12 rebuild main with `update-ref` but leave the checkout's index holding a `CLAUDE.md` the new tree lacks. Each walk then fails at :570, an index-only start, before it reaches the newline-name (:557), link-NUL (:583) or empty-link (:586) check.

This is the expected structural cost of the B2 fix. The walk's precondition now includes "the checkout's index holds no start main lacks", and any fixture that moves main without moving the index trips it first. So the fixture idiom is part of the walk's contract and should be one helper, not repeated by hand.

**Recommendation:** Add a test helper that rebuilds main and syncs the checkout: `update-ref`, then `git read-tree main` and removing the stale start. Use it in tests 5, 9 and 12. This is test-strategy's route; it is noted here only because U2a3c's tests will hit the same coupling.

## What Looks Good

- **Every iteration-1 finding was taken or carried in writing.** The plan's U2a3c bullet now states the single admission predicate and the one-loop, two-seeding shape. The checkout side is defined relative to main's commit, not the index, so phase 2's seed set is correct by construction.
- **The dispatch is fail-closed by default** (:597-598). An item the loop does not model now fails the walk instead of being skipped, which keeps the module's rule "refuses what it does not model".
- **The B1/B2 split holds.** Checkout reads lead only to `return 1`, and one sentinel (`IMPORTED_MAIN=error`) carries every failure to `isimported main`'s "imported" answer (:622).
- **The interim contract is legible to callers.** The header :32-34, A5, F11 and the U2b bullet say the same thing: use a fresh worktree until U2a3c.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `ent` assumes a prefix-free namespace and checks only exact duplicates. A tree-then-symlink doubled name passes: `walk ok`, while the checkout reads through the link (reproduced). Enforce "no key is an ancestor of another key" where `ent` is built. | Minor (security decides blocking) | `scripts/lib/dev-cycle-read.sh:553-560` | High |
| 2 | The checkout seed set comes from two listings with the pathspec duplicated. One `--cached --others` helper saves a line and gives U2a3c one seed source. | Informational | `scripts/lib/dev-cycle-read.sh:515`, `:561-563` | High |
| 3 | The index precondition masks three refusals in the tests. Add a rebuild-main-and-sync-index helper. | Informational | `scripts/lib/dev-cycle-read.sh:562`; build-loop-check.bats tests 5, 9, 12 | High |

Rubric mapping: all three are 🟢 Consider on the architecture scale. There are no Structural or Coupling findings. Finding 1 is a fail-open in the gate, though, and the security tier may rate it higher.

## Overall Assessment

The unit maintains the lib's structure, and loop 2 improved it:
- The B1/B2 boundary sits where U2a3c can treat main's walk as a fixed prefix.
- The dispatch fails closed.
- The checkout side is defined against main's commit.
- The plan carries the U2a3c constraints in writing.

One structural concern remains, and it is narrow: `ent`'s prefix-free invariant is assumed, not checked (Finding 1). It is fixable in place in a few lines, and Finding 2's listing merge pays for the line. I see no need to restructure. On merge-readiness from the architecture lens, the unit is ready once Finding 1 is fixed or explicitly routed by the security reviewer. Nothing here moves B1 or B2. Finding 1 tightens how B1's input is modelled and does not relocate any crossing, and Finding 2 changes only how B2's input is listed, not where it crosses. I have no disagreement with the security review's boundary placement.

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-L2f-build-loop-u2a3.md, structured per the architecture-review skill (Structural / Coupling / Minor / Informational).

**Answered:** Yes. The report is saved at that path with three findings, each carrying Evidence, Severity, Confidence and Legibility-target, plus a status table for the five iteration-1 findings (two fixed, one documented, two carried in the plan).
- **Interim contract:** fail-closed on the checkout in every state probed here and by the fact-check.
- **What main alone would catch but the walk misses:** nothing new from the split. The tree/symlink doubled name (Finding 1) is a main-side modelling gap that predates the split.

**Out of scope:**
- Whether a non-canonical tree can reach main in practice (receive.fsckObjects, the U2b hardening) and whether Finding 1 blocks the merge: security.
- The masked refusals and the untested gitlink and `*)` arms: test-strategy.
- Comment, A5 and commit-message wording: the fact-check route.
- Parser and sed/grep failure behaviour: fixed in U2a3b (stacked).

**Escalate:**
- **Security reviewer and author:** Finding 1 (lib :557, beyond override row :379). Decide whether to fix it in this unit or route it.
- **Implementer:** Finding 2 is optional, and it frees the cap line Finding 1 needs.
- **Test-strategy:** Finding 3's fixture helper.
