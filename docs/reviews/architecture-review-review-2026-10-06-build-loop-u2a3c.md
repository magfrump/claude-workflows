Commit: cebfed35

# Architecture Review — feat/build-loop-u2a3c (U2a3c, review-fix loop iteration 1)

**Scope:** `git diff 5e51b58b..HEAD` (commit cebfed35): `scripts/lib/dev-cycle-read.sh` (`checkout_md`, `main_checkout`, `main_imports`, header comments); tests and docs read for context only
**Date:** 2026-10-06
**Based on:** Stage 1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2a3c.md` (via the orchestrator's summary); design reference: U2a3 L2 architecture review F1, F2, F5 (`docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md`)

**Scope check:** In scope. The diff adds two library functions (`checkout_md`, `main_checkout`), changes `main_imports`' contract (it now reads the checkout as an input source instead of only failing on it), and changes a cross-cutting concern: the walk is the self-merge floor's input, and its cache (`IMPORTED_MAIN_DONE`) now covers a result that depends on the checkout. The test and doc changes are out of scope for this lens.

**Trust-boundary cross-reference:** no-op. `ls docs/reviews/security-review-*.md` matches nothing; this repo's security reviews are named `security-reviewer-review-*`, so the activation condition is not met. No finding below recommends moving the checkout/main boundary. Findings 1 and 2 sit on it, though, and would carry a security implication if a security map labelled it.

## Dependency Map

Everything here is in one lib file with no imports. Inside it, the dependency direction is:

- `main_imports` (walk, the floor's input) → `checkout_md` (seed listing) → `git ls-files`; it replaces the inline listing U2a3 had.
- `main_imports` → `main_checkout` (admission) → `inrepo_here` → `blocker` → `plaindir`/`rawfile`. Those four are the digest's working-tree predicates, which also serve `imported_names` (the tree walk).
- `main_checkout` → `main_imports`' local `ent`, by bash dynamic scope. This is a dependency back up into its only caller's state.
- `main_imports` → `import_targets` (parser, owned by U2a3b) for both main blobs and checkout files. The new `checkout)` arm feeds it a file on stdin, the same seam the 100644 arm uses.

The direction is mostly sound. The walk depends on predicates, and predicates depend on the filesystem. The exception is the upward edge from `main_checkout` into `ent` (Finding 1).

## Findings

#### 1. `main_checkout` reads its caller's `ent` through dynamic scope, so a second caller, or a rename of `ent`, gets a link check that silently passes

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:525-535` (definition), `:589`, `:628` (calls)
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** High
**Legibility-target:** U2a3c author (fix in this loop), U2a4 author (the floor will be the next caller of the walk's helpers)

**Evidence:**
```
# main_checkout PATH, the one admission check for main_imports' checkout phase (it
# reads the caller's ent): 0 for a plain checkout file to walk, 2 when nothing
...
  while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ && ( ! -d "$c" || -x "$c" ) ]] || return 1; done
```
(excerpt ends :531; enclosing `main_checkout()` continues to :535, read in full.) Compare U2a3 L2 architecture F5's recommendation, which this design was meant to realise: "Keep the state in `main_imports`' scope rather than handing it to helpers through dynamic scoping."

This is content coupling: the admission check depends on the name and shape of a local array in another function. The consequence is that it fails open. Suppose `main_checkout` is called where no `ent` is in scope (a future caller in U2a4 or U2b), or where `ent` has been renamed. Then `${ent[$c]:-}` expands to empty, the main-link/gitlink half of the check passes for every parent, and nothing reports an error. That half is the one this unit exists to enforce (U2a3 loop-1 C1/C2). The comment does document the dependency, which keeps the severity at Coupling rather than Structural. Still, the security-relevant half of the "one admission check" depends on a naming convention rather than on the function's interface. The lib already has prior art for doing this explicitly: `nul_list` takes its array by name through `local -n` (:521).

**Recommendation:** Pass the map explicitly, as `main_checkout ENTNAME PATH` with `local -n mc_ent="$1"`, in the `nul_list` style. Have it fail (`return 1`) when the named array is not an associative array, so a caller without one fails closed rather than open. That is two to three lines.

#### 2. The predicate is single, but admission is still spread over two call sites with different seen/check order and different glue

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:589-591` (start site), `:624-629` (import site)
**Move:** 3 (module boundary), 8 (extension points)
**Confidence:** High (order); Medium (that it matters beyond legibility)
**Legibility-target:** U2a3c author; plan bullet U2a3c (`docs/working/plan-build-loop-handoff.md:277`) and the commit message's "before any checkout path is marked seen"

**Evidence:**
```
      f="${cand[i]:2}"; c=0; [[ "${cand[i]:0:1}" == m ]] || main_checkout "$f" || c=$?
      [[ $c -ne 1 ]] || return 1; [[ $c -eq 0 ]] || continue
      seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f"); else tq+=("$f"); fi
```
```
      [[ -z "${seen[$p]+set}" ]] || continue
      seen[$p]=1
      if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi
      c=0; main_checkout "$p" || c=$?  # main lacks p
      [[ $c -ne 1 ]] || { IMPORTED_MAIN=error; return 1; }; [[ $c -ne 0 ]] || tq+=("$p")
```
(second excerpt ends :629; the enclosing read loop and `main_imports()` continue to :632, read.)

U2a3 L2 F1 asked that "every item phase 2 admits goes through one admission predicate before it is marked `seen`". The commit delivers one predicate, so the check is no longer copied inline twice, and that is a real improvement. It does not deliver one admission site. The start site checks and then marks seen. The import site marks seen, then routes main-stored paths, then checks. An rc of 2 leaves a start unmarked but leaves an import marked. The start site fails with a bare `return 1`, relying on `IMPORTED_MAIN=error` still holding from :570, because the reset to `$'\n'` happens only at :594. The import site sets `error` itself. The fact-check found no fail-open in this today (rc 1 aborts the walk, rc 2 is never walked), so this is not a correctness finding. It is the shape of U2a3's convergence problem, though: each producer carries its own copy of the "what happens around the check" logic. A third producer would copy one of the two variants, and the docs already state the order wrongly (fact-check claims 4 and 17b).

**Recommendation:** Fold seen, admission and enqueue into one local step that both sites call, such as an `admit PATH` that returns 1 to fail. It would check `seen`, route a main-stored path to `queue`, run `main_checkout`, then mark seen and route to `tq`. Use the same order at both sites. Failing that, at least move the import site's `main_checkout` above `seen[$p]=1` and correct the plan bullet and commit wording.

#### 3. Phase 1 does not run on main's state alone: checkout starts are already in `seen`, and "only appends" then depends on `IMPORTED_MAIN+=` preceding the `seen` dedupe

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:591`, `:595-596`, `:624-625`
**Move:** 2 (responsibility boundaries)
**Confidence:** Medium
**Legibility-target:** U2a3c author; any later editor of the drain loop (U2a4)

**Evidence:**
```
      seen[$f]=1; if [[ -n "${ent[$f]+set}" ]]; then queue+=("$f"); else tq+=("$f"); fi
...
    [[ ${#queue[@]} -gt 0 ]] || { queue=("${tq[@]}"); tq=(); }  # phase 2: main's walk is done
...
      IMPORTED_MAIN+="$(lower "$p")"$'\n'
      [[ -z "${seen[$p]+set}" ]] || continue
```

"Only appends" does hold today, and it holds mostly by construction:
- the swap at :596 fires only on an empty `queue`, so main's fixpoint is reached before any checkout file is read;
- `ent` is frozen after seeding, and dispatch keys on it (`${ent[$f]-checkout}`, :599), so a path main stores is always read through main's arms;
- the checkout's only other power is to fail the walk.

One leg is ordering inside a statement sequence rather than structure. The checkout's `t:` starts go into the shared `seen` before phase 1 runs. A main import that names a path which is also an untracked start is recorded only because :624 records before :625 dedupes. If someone reorders those two lines, a natural "skip seen paths early" edit, the path drops out of `IMPORTED_MAIN`, and the main-only result is no longer a prefix of the two-phase result. A phase-1 `seen` holding only main-reached paths would make the property independent of that line order.

**Recommendation:** Hold the `t:` starts out of `seen` until the swap: keep them in `tq` and dedupe against `seen` when phase 2 admits them. Or add a one-line comment at :624 stating that the record must precede the dedupe because `seen` holds checkout starts in phase 1. Either way, add a test with a main import of a path that is also an untracked start, so a reorder that drops the record fails.

#### 4. The admission check reuses the digest's skip predicate (`blocker`) for part of its rule, so two parent walks with different rules decide one admission

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:531-534`; `:110-121` (`blocker`), `:127` (`inrepo_here`)
**Move:** 7 (coupling surface), 2 (responsibility)
**Confidence:** Medium
**Legibility-target:** U2a3c author; whoever next edits `blocker` for the digest

**Evidence:**
```
  if inrepo_here "$1"; then [[ -r "$1" ]]; return; fi
  if [[ -d "$1" && ! -L "$1" && -z "$(blocker "$1" dir)" ]] || [[ ! -e "$1" && ! -L "$1" ]]; then return 2; fi
```
and `blocker`'s contract (:104-109): "One rule decides whether an input is skipped ... the blocking part is what the digest's section 8 lists ... An absent path is not skipped, just absent."

`main_checkout` walks the ancestors itself (main links and gitlinks, searchability). It then hands the checkout-link half to `blocker`, which walks them again with `plaindir`/`realpath`. The absent arm does not consult `blocker` at all (fact-check claim 11: below a checkout directory link whose target lacks the path is rc 2). The gate's semantics are fail-closed, while `blocker`'s are skip-and-report for the digest, and the two can drift. A digest-motivated change to `blocker`, say treating some non-plain shape as reportable-but-plain, would silently change what the floor's walk admits. Reuse is defensible here: `imported_names` already uses `inrepo_here`, and one plainness rule for the whole lib has value. But the coupling should be named, not implicit.

**Recommendation:** No restructure in this unit. Add a line to `blocker`'s header saying that `main_checkout` (the self-merge floor's walk) depends on it, so a change there needs the U2a3c tests. Or fold the parent-link probe into `main_checkout`'s own ancestor loop (`-L "$c"` → 1), so the gate's parent rules sit in one loop.

#### 5. The checkout `.md` pathspec is still written twice; the override log's revisit trigger has fired

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:519`, `:524`; `docs/reviews/override-log.md:402`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** U2a3c author; override-log maintainer

**Evidence:**
```
untracked_md() { GIT_LITERAL_PATHSPECS=0 git ls-files -z --others -- ':(glob,icase)**/*.md'; }
...
checkout_md() { local e; { e="$(GIT_LITERAL_PATHSPECS=0 git ls-files -z --cached --others -- ':(glob,icase)**/*.md' 2>&1 >&3)"; } 3>&1 && [[ -z "$e" ]]; }
```
Override row :402: "Revisit trigger: U2a3c's phase-2 seed listing, which should take one name."

The commit gives the listing a name (`checkout_md`), which is an improvement over the inline call. The pathspec literal still appears twice, now across two helpers. If the start-file glob widens (for example, Claude Code starting to load another extension), one walk changes and the other does not, and the floor walk and the tree walk then disagree about what a start is.

**Recommendation:** Hoist the pathspec into one variable (e.g. `CHECKOUT_MD_SPEC`) used by both helpers, or close the override row with a reason. Either way, record that the trigger fired.

#### 6. The cache key's omission of the checkout now hides appended imports, not only a failure

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:474-476`, `:569-570`; `docs/reviews/override-log.md:372`
**Move:** 2 (cross-cutting caching concern)
**Confidence:** Medium
**Legibility-target:** U2a4 / U2b authors (the deferral's revisit trigger)

**Evidence:**
```
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
```
Override row :372 defers this with "No caller yet ... Revisit trigger: U2a4's floor or U2b's --check calling the walk more than once per process."

Before this commit, the checkout could only fail the walk. The stale-cache case was therefore "a later failure is missed". Now the checkout is a source of imports, so the cached result's correctness depends on checkout state the key does not describe. The deferral and its trigger still hold, and the commit adds a test pinning the behaviour. Its premise has widened, though, and the U2a4 author should see it framed as "the cache covers checkout-derived imports", not only start files.

**Recommendation:** Amend override row :372's note, or the comment at :474-476, to say that the checkout now contributes imports to the cached result. No code change.

#### 7. Dispatch infers "checkout" from absence in `ent`, rather than tagging the item as L2 F2 suggested; sound here by construction

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:599-600`, `:613`
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** U2a3c author (no action needed)

**Evidence:**
```
    case "${ent[$f]-checkout}" in
      checkout) out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; } ;;
```
L2 F2 recommended to "restore a source tag on queue items or give checkout items their own arm, so the dispatch never infers an item's source from whether it happens to be missing from `ent`."

The commit gives checkout items their own arm, and the default arm now fails (`*) IMPORTED_MAIN=error; return 1`). The arm is still selected by absence from `ent`. That is correct here. `ent` is frozen after seeding, and a path main stores should be read from main whatever produced it, which is the design's intent. The sentinel `checkout` cannot collide with a six-digit mode. The fact-check confirmed that no main-stored path reaches the checkout read. So the inference expresses the policy ("main wins") rather than a guess about provenance.

**Recommendation:** None. A one-line comment at :599 ("a path main stores is read from main, whoever queued it") would make the policy explicit.

## What Looks Good

- **One drain loop, two seedings, shared `ent` and `seen` (L2 F5 realised).** The `queue`/`tq` swap at :596 is the smallest structure that guarantees main's fixpoint first and still lets phase 2 re-enter main's arms. There is no second loop and no duplicated arms.
- **One admission predicate.** The U2a3 inline parent and shape checks (two lines at the import site), plus the start refusal, collapse into `main_checkout` with a three-valued result (walk / nothing loads / fail). Starts and imports now share one rule, which closes the class behind U2a3 loop-1 C1.
- **The listing gate is separated from the per-path gate.** `checkout_md` owns "the listing is whole" (fail on any stderr). `main_checkout` owns "this path is admissible". These are different questions, and they live in different functions.
- **Dependency direction is preserved.** The walk depends on predicates and the parser seam (`import_targets` on stdin) is unchanged, so U2a3b's parser work stacks below without touching this unit's structure.
- **Fails closed at the seams.** The default dispatch arm, the checkout read's error arm and the listing's stderr check all fail the walk rather than skip.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | `main_checkout` reads caller's `ent` by dynamic scope; a caller without it fails open | Coupling | `dev-cycle-read.sh:525-535` | High |
| 2 | One predicate but two admission sites, with different seen/check order and glue | Minor | `:589-591`, `:624-629` | High |
| 3 | Phase 1 `seen` holds checkout starts; append-only leans on record-before-dedupe line order | Minor | `:591`, `:624-625` | Medium |
| 4 | Gate reuses the digest's `blocker` skip rule; two parent walks decide one admission | Minor | `:531-534`, `:110-127` | Medium |
| 5 | `.md` pathspec still written twice; override revisit trigger fired | Informational | `:519`, `:524` | High |
| 6 | Cache key omits the checkout, which now contributes imports | Informational | `:474-476`, `:569` | Medium |
| 7 | Dispatch by absence from `ent` rather than a tag; sound by construction | Informational | `:599-600` | High |

Rubric mapping: Finding 1 → 🟡 Must Address; Findings 2-7 → 🟢 Consider.

## Overall Assessment

The commit realises the design U2a3's architecture review proposed: one drain loop over two seedings, phase 2 sharing `ent` and `seen` and reading main-stored paths through main's arms, and one admission predicate. "Only appends" holds largely by construction: the swap fires only on an empty queue, `ent` is frozen and drives dispatch, and phase 2 can only add or fail. The structural concerns are about how the gate is attached, not whether it exists. The most important one is Finding 1: the security-relevant half of `main_checkout` reads `ent` through dynamic scope, so a future caller without that local gets a link check that silently passes. That is the fail-open direction, and it contradicts L2 F5's explicit advice; an explicit nameref fixes it in a few lines. Findings 2 and 3 are the residue of L2 F1: the predicate is single, but the admission site, and the seen state around it, are not yet. Folding them into one `admit` step would make "one gate" true by construction rather than by agreement between two call sites. Everything is fixable in place, and no restructuring is needed.

## Goal-Alignment Note

The user goal is to land U2a3c through pr-prep's review-fix loop, with the walk as a fail-closed self-merge floor input. This review serves that goal. Finding 1 is the one item that bears directly on fail-closed behaviour: not today, but for the next caller (U2a4's floor), which is the next unit in this initiative. Findings 2 and 3 address the convergence risk that capped U2a3's loop, where checkout input was handled per producer. Findings 5-7 are bookkeeping, and the loop need not spend an iteration on them. Nothing here recommends work outside this unit's scope or blocks the U2a3b rebase.
