Commit: d10cfba8

# Architecture Review: feat/build-loop-u3a1 (final confirming pass)

**Scope:** the full branch, `main...d10cfba8` with docs/reviews excluded: `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, and plan step 7's U3 split note and U3a1 as-built note. The focus is the branch as U3a2's base: the seams `--merge` will use, global state between briefs, and the `GATE_TMP` files store_check keeps.
**Date:** 2026-10-10
**Based on:**
- Fact-check k=3 (`code-fact-check-report-build-loop-u3a1-final-r{1,2,3}.md`): 0 behavioral Incorrect. Two stale items, not re-filed here: the as-built note's "ids already checked", and gate_start's "every refusal a refuse state line" (a failed mktemp exits 1 with no such line).
- Prior reports: `architecture-review-review-2026-10-10-build-loop-u3a1.md` and `...-i2.md`, with their resolutions in the rubric and in override rows 638-649.

**Severity → rubric tier:** Structural → 🔴 Must Fix · Coupling → 🟡 Must Address · Minor and Informational → 🟢 Consider

**Scope check:** In scope on two categories:
- **Cross-cutting:** the startup sequence (`GATED`, `gate_start`) and the hardening pairs.
- **Data model:** the STATUS value array, and store_check's run-scoped state in `GATE_TMP`.

**Trust-boundary cross-reference:** The newest security review is `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1-i2.md` (Commit: `83f75281`). It predates d10cfba8, so its boundaries may be stale. Finding 1 sits on its `B1` (`.git/objects → store_check re-hash + one-copy scan`). The recommendation does not move that crossing.

## Dependency Map

- **Direction is unchanged.** `build-loop.sh` sources `scripts/lib/dev-cycle-read.sh`, and the lib never calls back.
- **What store_check depends on:**
  - the real repository's object store;
  - `GATE_TMP` and three files in it:
    - `main` is the skip set. It persists for the whole run.
    - `call` holds this call's verified ids. Each call overwrites it.
    - `idx` holds the pack-index listing. Each call overwrites it.
  - The `main` file is a two-party protocol. store_check creates it empty if it is absent (`:622`). gate_start promotes the first call's `call` file to `main` (`:858`).
- **Who calls store_check:** two sites, gate_start (`"$MAIN_SHA"`) and check_line (`"$sha" "$tree"`).
- **check_line → status_fields.** status_fields writes the STATUS and BRIEF globals. check_line reads STATUS by key and takes Paths: from BRIEF. The verdict (TIP, TREE, ok/refuse) still exists only as printed lines. Moving it to values is row 643, deferred to U3a2.
- **The top level → `GATED` → state_gate and gate_start.** That is one flag read at two sites, plus the case arm.

## Verification of iteration 2's resolutions

| i2 # | Resolution claimed | Verified at d10cfba8 |
|---|---|---|
| 1 | Skip set split from the duplicate set; a test of two briefs in both orders | **Yes.** The perl output goes to `$GATE_TMP/call` (`:636`). The scan judges `main` + `call` only (`:644`). The test at `build-loop-check.bats:1892-1894` pins y ok before and after x's refusal. Not done: the inventory line (Finding 2). |
| 2 | Row 644's premise amended (row 648) | **Yes.** Row 648 records that the lib move needs the scratch dir as an argument. |
| 3 | `GATE` renamed | **Yes.** It is now `GATED`, with a comment at `:341` setting it apart from the `GATE_*` names. |

## Findings

#### 1. main's skip set is a file protocol split between store_check and gate_start, and a second `store_check "$MAIN_SHA"` in the same run re-hashes only main's root tree yet returns 0

**Severity:** Minor
**Location:** `scripts/build-loop.sh:601-602`, `:622`, `:628`, `:858`; override rows 639 and 646 (their U3a2 triggers)
**Move:** 7 (coupling: control through ambient file state), 3 (module boundary)
**Confidence:** High (probed)
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:622 (store_check: the first call in a run sees an empty skip set)
  [[ -e "$GATE_TMP/main" ]] || : > "$GATE_TMP/main" || return 1
# :628 (each id in main is filtered out before cat-file; "$r^{tree}" is a name, so it is never filtered)
    done; } | awk 'FILENAME != "-" { seen[$0]; next } !($0 in seen) { seen[$0]; print }' "$GATE_TMP/main" - | git cat-file --batch \
# :858-859 (gate_start: promotes store_check's private output file to the skip set)
  store_check "$MAIN_SHA" && mv "$GATE_TMP/call" "$GATE_TMP/main" \
    || { echo "refuse state objects: ..."; exit 2; }
```
Row 639's revisit trigger names "U3a2's --merge adding a second full pass". Row 646's trigger names "--merge (U3a2) if it runs several briefs per process".

Probe (a throwaway repo under my scratch dir, using the store_check function extracted from d10cfba8):
```text
first main call rc=0            # then mv call -> main, as gate_start does
second main call rc=0           # MAIN_SHA and every blob/subtree skipped; only "MAIN^{tree}" re-read
empty-commit tip + main tree rc=0
```

**Why it matters for U3a2:**
- Who store_check checks is set by whether a file exists. A function argument does not decide it. Two functions share the protocol:
  - store_check knows that `main` means "skip".
  - gate_start knows that `call` is store_check's output, and that promoting it is what makes the skip set.
- The obvious way for U3a2 to narrow row 646's residual is to call `store_check "$MAIN_SHA"` again just before the CAS, beside the state-gate re-run of row 494. That call would re-hash one tree and report success. It fails open for its stated purpose, silently.
- The comment does say "an id in $GATE_TMP/main ... is not read again", so this is a trap for the next author, not a bug today. Both current callers are correct.

**Recommendation:**
- Make the role an explicit parameter. For example, `store_check --main REV` writes the skip set itself (no `mv` in gate_start), and a plain call skips it.
- Add one sentence to the comment: "a re-check of main's objects within a run needs the skip set removed (or the --main form)".
- Alternatively, record this in row 639/646's notes, so the U3a2 author sees it at the trigger.

#### 2. check_line's carry inventory still omits `$GATE_TMP/main`, the one deliberate cross-brief carry

**Severity:** Informational
**Location:** `scripts/build-loop.sh:871-874`
**Move:** 2 (responsibility: the stated per-brief independence invariant)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:871-874
# Nothing but its locals and the walk caches it resets may carry from one
# brief to the next: each helper empties its own globals before use (DENY,
# PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, STATUS, BRIEF, CHECKOUT_WHY, FLOOR_WHY,
# TRUTH_WHY).
```
- `$GATE_TMP/main` does carry from one brief to the next. It is a run-scoped skip set, deliberate and now harmless, since the i2 fix judges only main's ids plus the call's ids.
- `call`, `idx`, `diff`, `status`, `err`, `others`, `tree` and `line` also stay in `GATE_TMP` between briefs. Each is overwritten before it is read, so none carries a value.
- The inventory is the place a U3a2 author checks when `--merge` reuses check_line. i2's recommendation included this line, and the fix batch did not add it.

**Recommendation:** Append one clause, for example: "...TRUTH_WHY); one file carries on purpose, store_check's skip set $GATE_TMP/main (main's ids, re-hashed once per run)."

## What Looks Good

- **i2's coupling is fixed at the root.** The skip set and the duplicate set are now two files with one job each. The two-brief test in both orders pins the per-brief independence that check_line's comment promises.
- **Startup is one function with one flag.** `GATED` gates both top-level sites. `gate_start` is the single entry point U3a2 can call. It also states the repository rule, which now places store_check's reads, so `commit-tree`, `update-ref` and `merge --ff-only` have a rule to follow.
- **Hardening stays in one place.** `core.multiPackIndex=false` was added to `harden`'s list, not as a per-call flag. It reaches every git call, `gate_git` included, because the caller's `GIT_CONFIG_*` pass through `callervar`.
- **The STATUS seam is documented as a data contract.** The comment states each key's shape, what `-` means, and the skip-vs-ok rule. check_line now reads one status pass, not three re-reads. The verdict-as-values half has a named owner (row 643, U3a2).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Skip set is a store_check/gate_start file protocol; a second `store_check "$MAIN_SHA"` re-hashes only the root tree and returns 0, which is the call U3a2's row 639/646 triggers invite | Minor | `scripts/build-loop.sh:622,628,858` | High |
| 2 | check_line's carry inventory omits `$GATE_TMP/main` | Informational | `scripts/build-loop.sh:871-874` | High |

## Overall Assessment

As U3a2's base, the branch keeps the system's structure sound:
- dependency direction is unchanged;
- startup has one entry point and one flag;
- STATUS is a documented value contract;
- each of i2's findings is fixed or rowed, and the fix is tested.

What remains is legibility at the seam U3a2 will touch. Store_check's "main" mode is implied by a file that gate_start creates by renaming store_check's output. A re-check of main within a run therefore succeeds while checking almost nothing (Finding 1). That is fixable in place with a parameter or a comment line, and it needs no restructuring. Nothing here blocks the merge.

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report saved at the path your dispatch names, structured per your skill.
- Answered: yes. Covered the full branch as U3a2's base: seams (gate_start, store_check, STATUS), state between briefs, and the GATE_TMP files; i2's resolutions verified.
- Out of scope: the fact-check's two stale items (as-built "ids already checked", gate_start's mktemp exit), already reported by fact-check; security sufficiency of the copy listing (security lane).
- Escalate: nothing.
- Decisions I made: rated Finding 1 Minor rather than Coupling, because the comment documents the skip and both current callers are correct, though a future caller would fail open; tested the hypothesis that a repeat main call returns 1 (refuted by probe: the `REV^{tree}` name is never skipped, so it returns 0).
