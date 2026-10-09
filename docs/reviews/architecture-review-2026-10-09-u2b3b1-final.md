Commit: f56ba3f5

# Architecture Review — feat/build-loop-u2b3b1 (iteration 2, final confirming pass)

**Scope:** `git diff main...HEAD` at f56ba3f5 (scripts/lib/dev-cycle-read.sh, scripts/build-loop.sh, scripts/dev-cycle.sh, docs/dev-cycle.md; tests read for context only), with attention to the iteration-1 fix commit 1ece139d (`git diff 8ed86432 HEAD -- scripts docs/dev-cycle.md`)
**Date:** 2026-10-09
**Based on:** Stage 1 merged fact-check (k=3; docs/reviews/code-fact-check-report-build-loop-u2b3b1-final-r{1,2,3}.md, summarized in the brief's critic tail); iteration 1 report docs/reviews/architecture-review-2026-10-09-u2b3b1.md

Scope check: in scope (unchanged from iteration 1): module structure (main_file and SETTINGS_AWK moved into the lib), public API (`reader_settings`, `READERS_LINE`, `IMPORT_READER_WHY`, contract item 9), data model (two docs/dev-cycle.md keys, a fifth `--settings` line, a memoized refusal).

Settled, not re-filed: i1 F1 (two parsers; override row "Two parsers for one settings file", Defer), i1 F2 (no sentinel for a missing reader_settings call, Defer), i1 F4 (every-mode call, Won't-Fix), i1 F5 (root-set product, routed to U2b3b2). Nothing new was found about any of them: 1ece139d does not touch the parsers, and the item-9 comment now states the omission case ("a caller that never calls it models no host reader (override row)", lib:589-590), which is what that row's Defer asked for.

Trust-boundary cross-reference: active. docs/reviews/security-review-2026-10-09-u2b3b1.md (Commit: `8ed86432` — security review predates this diff's tip; boundary may be stale). Finding A1 sits on its `B5` ([import_readers memo] → [import_targets' "memo current?" test] → [roots/homes the parser projects with]).

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` remains the stable core; `scripts/build-loop.sh` and `scripts/dev-cycle.sh` source it and call `reader_settings` once at top level (build-loop.sh:307, dev-cycle.sh:194). No lib-to-caller call exists.
- Inside the lib: `reader_settings` (593-635) → `main_by_name`, `main_file` (535-550) → `main_entry`/`FENCE_AWK`; it sets `IMPORT_READER_ROOTS/HOMES/WHY` and `READERS_LINE`.
- `IMPORT_READER_WHY` is now read in five places across two files: `import_readers_key` (1007), `import_readers` (1020), `import_targets` (1065, new in 1ece139d), `floor` (1416, new) and dev-cycle.sh `check_fix` (186, new). The first three decide the refusal; the last two only word it.
- build-loop.sh `read_settings` (from 356) still decodes `SETTINGS_AWK` output itself (settled i1 F1).

## Findings

#### A1. The settings refusal now has three owners: import_readers' guard, its memoized empty IMPORT_ROOTS, and import_targets' own IMPORT_READER_WHY test

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:1014-1016`, `scripts/lib/dev-cycle-read.sh:1020`, `scripts/lib/dev-cycle-read.sh:1064-1065`
**Move:** 7 (coupling surface: content coupling), 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** U2b3b2's outside-seed caller of import_targets (override row 538) should learn "when does import_targets refuse" from one predicate, not by reading import_readers' memo encoding.

**Evidence:**
import_readers (1014-1016, 1020):
```
  # A refusal is memoized too, as an empty IMPORT_ROOTS (a result never is:
  # ROOT_REAL leads it), so a refusing decision lists the registry once (U2b3a final performance F1).
  if [[ "$IMPORT_READERS_DONE" == "$IMPORT_READERS_KEY" ]]; then [[ -n "$IMPORT_ROOTS" ]]; return; fi
...
  [[ -n "${ROOT_REAL:-}" && -z "$IMPORT_READER_WHY" ]] || return 1
```
import_targets (1063-1065):
```
  import_readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$IMPORT_READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
  [[ -z "$IMPORT_READER_WHY" ]] || return 1  # refused settings fail every reader (U2b3b1 i1 security F2)
```
IMPORT_AWK BEGIN (934):
```
  nr = split(ENVIRON["IT_ROOTS"], roots, "\n"); if (nr == 0 || roots[1] == "") exit 2
```

Iteration 1's F3 noted that import_targets re-derives import_readers' memo key and relies on an implicit "memo current and IMPORT_ROOTS empty means refused" encoding, and suggested one named state owned by import_readers. The fix in 1ece139d closes the security gap (a call outside a walk no longer projects with ROOT_REAL alone when the settings are refused) but does so by adding a third refusal path rather than consolidating: a settings refusal is now caught by import_targets' direct test, while every other import_readers refusal (a non-absolute root, a failed realpath, the registry listing failing) still reaches import_targets only as an empty IMPORT_ROOTS that IMPORT_AWK's BEGIN rejects with exit 2. Behaviour is fail-closed in every case (the fact-check verified "import_targets failing on refused settings both ways"), so this is not a defect; the cost is that the refusal rule is now spread over three sites in two functions plus an awk BEGIN clause, and a change to what import_readers refuses (U2b3b2's outside starts, U2c) must be mirrored in import_targets by convention. This sits on security `B5` from docs/reviews/security-review-2026-10-09-u2b3b1.md (Commit: `8ed86432` — security review predates this diff; boundary may be stale).

**Recommendation:** No change in this unit (397/400 lines). When U2b3b2 adds its outside-seed caller (row 538), give import_readers one named result (e.g. `IMPORT_READERS_OK`, set with the memo) that import_targets reads in place of the key comparison and the IMPORT_READER_WHY test. **Security implication:** this would move the B5 transition point from import_targets' key comparison to the named state; it must keep the settings refusal fail-closed for a call outside a walk (the case 1ece139d fixed), so defer the change to a combined review at U2b3b2.

#### A2. The superset statement's root list omits the G8 re-spelled worktrees

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:795-796`
**Move:** 3 (module boundary: contract statement)
**Confidence:** High (builds on the merged fact-check's Stale verdict for lib:794-796)
**Legibility-target:** the comment that calls itself "the one statement" of the superset claim should name the whole root set U2b3b2 will seed per root.

**Evidence:**
```
# a reader root (import_readers: ROOT_REAL, every registered worktree, the
# caller's IMPORT_READER_ROOTS), and printed relative to each root holding
```
versus import_readers (1029-1031):
```
  for rs_cr in "${rs_c[@]}"; do
    [[ -n "$rs_cr" ]] || continue
    rs_r+=("$rs_cr"); for p in "${rs_w[@]}"; do [[ -z "$rs_m" || "$p" != "$rs_m"/* ]] || rs_r+=("$rs_cr${p#"$rs_m"}"); done
  done
```

The parser's contract comment, which known issue A5 and plan F11 point to as the single statement of the superset rule, lists three root sources; G8 added a fourth (each worktree beneath the main worktree, re-spelled under each caller root), which on /workspace is about half the 49 roots. import_readers' own comment states it correctly, so the code and its local comment agree; the drift is in the cross-module statement that other docs cite. i1 F5 already noted the root set is now a product that U2b3b2's per-root seeds multiply with; a reader starting from the superset statement would not see that product.

**Recommendation:** Add ", and each worktree beneath the main worktree re-spelled under each of those" to the parenthesis (a comment edit, no code lines). Can ride U2b3b2 if this unit holds at the cap.

#### A3. Two consumers re-derive "the walk failed because of the settings" from TRUTH_WHY and IMPORT_READER_WHY

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1416`, `scripts/dev-cycle.sh:186`
**Move:** 7 (coupling: control/stamp), 2 (responsibility)
**Confidence:** Medium
**Legibility-target:** a reader adding a third walk caller (U2c's --check) should find the walk's failure cause in truthwalk's result, not reconstruct it.

**Evidence:**
lib floor (1416):
```
    if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]; then FLOOR_WHY="the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction files could not be walked for @ imports"
```
dev-cycle.sh check_fix (186):
```
    if [[ "$TRUTH_WHY" == walk && -n "$IMPORT_READER_WHY" ]]; then echo "skip $a: the reader settings of docs/dev-cycle.md cannot be used ($IMPORT_READER_WHY), so the instruction-file import walk failed; file it instead"
```

The inference is correct today (a set IMPORT_READER_WHY always fails import_readers, so the walk fails and truthwalk leaves TRUTH_WHY=walk), and the wording is per-caller, so duplicating the branch is defensible at two sites. It does mean each walk caller must know that IMPORT_READER_WHY is a cause of `walk`, a fact truthwalk (1365-1368) owns implicitly. U2c will add the first script caller of the lib's floor; if it words its own refusal, it becomes a third copy.

**Recommendation:** None for this unit. If a third caller appears, have truthwalk set a distinct TRUTH_WHY (e.g. `settings`) and let callers switch on that.

## What Looks Good

- 1ece139d resolves i1 F4(a)'s asymmetry in the right place: "no default branch found by name" is now a refusal inside reader_settings (lib:597-600), so both callers fail closed without either script adding a branch, and contract item 9 (lib:86-91) and dev-cycle.sh:192-193 say so. route: code-fact-check
- The fix stayed inside the existing module boundaries: no new lib function, no new global, no new lib-to-caller dependency; the refusal still flows through the one contract variable item 9 names.
- `READERS_LINE`'s malformed form now ends "; both import walks fail" in both producing branches (599, 630), matching build-loop.sh's documented grammar (52-53). route: code-fact-check
- The memo comment (lib:994-996) now states its one exception (an import_home failure returns before memoizing), which is the boundary U2b3b2 needs. route: code-fact-check
- Dependency direction is unchanged: the lib remains the sole owner of the reader model and both scripts reach it through one call.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| A1 | Settings refusal owned at three sites (memo empty roots, import_readers guard, import_targets' direct test); i1 F3's named state not adopted | Minor | `scripts/lib/dev-cycle-read.sh:1016,1020,1065` | Medium |
| A2 | Superset statement's root list omits G8 re-spelled worktrees (fact-check Stale) | Minor | `scripts/lib/dev-cycle-read.sh:795-796` | High |
| A3 | floor and check_fix each re-derive "settings caused the walk failure" | Informational | `scripts/lib/dev-cycle-read.sh:1416`; `scripts/dev-cycle.sh:186` | Medium |

## Overall Assessment

The branch maintains the system's structure. No Structural (red) and no Coupling (amber) finding at this pass: iteration 1's one amber item (F1) is settled by an override row and nothing in 1ece139d changes it. The fixes closed the security-relevant gaps without widening any module surface. The most important remaining structural concern is A1: the "refused" state of the reader model is now expressed three ways, which is fail-closed and tested but should be consolidated into one named result when U2b3b2 adds the next import_targets caller; A2 is a one-line comment fix that can ride this unit or the next.

## Goal-Alignment Note

The user goal is to land U2b3b1 after a clean review-fix loop. This pass finds nothing red or amber; A1 and A2 are green and both fit U2b3b2 naturally (A1 needs a combined architecture/security look at B5; A2 is a comment), so neither should cost this unit lines against its 397/400 cap. A3 is informational for U2c. From the architecture lens the branch is clean to land.
