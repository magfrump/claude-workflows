Commit: 83f75281

# Architecture Review: feat/build-loop-u3a1 (iteration 2)

**Scope:** partial, the fix range `65007bf8..83f75281` with docs/reviews excluded: `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, and plan step 7's U3a1/U3a2 bullets. `main...65007bf8` and `scripts/lib/dev-cycle-read.sh` were read as context only.
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1-i2.md` (0 Incorrect; two stale items: state_gate's header omits alternates, and the U3a2 bullet still cites the removed brief re-read). Also iteration 1's `architecture-review-review-2026-10-10-build-loop-u3a1.md` and its resolutions in the rubric and the override-log rows 642-644.
**Severity → rubric tier:** Structural → 🔴 Must Fix · Coupling → 🟡 Must Address · Minor and Informational → 🟢 Consider

**Scope check:** The fix range is in scope on two of the four categories:
- **Cross-cutting.** It adds the `GATE` startup flag and a new state-gate refusal.
- **Data model.** It changes store_check's contract: it now keeps state across calls in `$GATE_TMP/checked`, and it adds a duplicate-copy rule.

**Trust-boundary cross-reference:** The newest security review is `docs/reviews/security-reviewer-review-2026-10-10-build-loop-u3a1.md` (Commit: `65007bf8`). That review predates this fix range, so its boundaries may be stale. Finding 1 sits on its `B1` (store_check re-hash → verdict integrity). The recommendation does not move that crossing.

## Dependency Map

- The direction is unchanged: `build-loop.sh` sources the lib, and the lib never calls into the script.
- **`store_check` has a new input.** It now depends on `GATE_TMP`, a script global set in `gate_start`. Its comment says "Needs GATE_TMP".
- **`store_check` keeps state across calls.** It appends each verified id to `$GATE_TMP/checked` (`:632`). It reads that file twice:
  - to skip ids it has already hashed (`:624`);
  - as the whole set the duplicate scan checks (`:640`).

  Iteration 1 described store_check as reading no globals. That is no longer true: one call's result now depends on the calls before it in the same run.
- **`status_fields` writes the lib's global `BRIEF`.** It empties `BRIEF` (`:517`), and `brief_fields` then refills it.
- **The top level reads one flag.** `GATE`, set from `MODE` (`:340`), gates both `state_gate` and the skipped `reader_settings`. The `check` case arm still calls `gate_start` on its own.

## Verification of iteration 1's resolutions

| i1 # | Resolution claimed | Verified at 83f75281 |
|---|---|---|
| 1 | One `GATE` flag; A15 pins `cat-file --batch` before the first `cat-file blob` | **Yes.** `:340-348` test `GATE` at both sites, so the negative test is gone. A new gated mode now edits two places: the `GATE=` line and its case arm calling `gate_start`. That is down from three, and missing either place fails closed or is visible. The A15 assertion (`build-loop-check.bats:1941-1944`) pins the order the help text claims. |
| 2 | Row 512's values moved to U3a2; comment cites row 496 | **Yes.** The `status_fields` comment cites row 496 only. The U3a1 as-built note and the U3a2 bullet both record the move. The U3a2 bullet still says the shim "also reaches the failed brief re-read (row 625)", which contradicts the as-built note one line above. That is fact-check i2 Claim 5, not re-filed here. |
| 3 | Rowed (642); comment states the shapes | **Yes.** `:504-513` now states that a skip sets only `line`, that each field is "the bare value as printed", and that `-` means none. A `[result]` key is deferred to U3a2. |
| 4 | `BRIEF` emptied in status_fields; comment states the rule | **Yes.** `BRIEF=()` sits beside `STATUS=()`. The comment now gives the condition ("empty for a new brief or one check_brief skips") and the rule ("nothing between may call brief_fields"). `BRIEF_ODD` is not reset, but nothing in check_line reads it, and `brief_fields` empties it on every call. |
| 5 | Repository rule places store_check | **Yes.** `:846-849` say "store_check's object reads are in the real repository", and the store_check comment says the same. Both stale `status_line` mentions are fixed. |
| 6 | Defer the lib move to U3b's D6 (row 644) | **Still right, with a weaker premise.** The move is no longer a plain cut-and-paste: store_check now needs `GATE_TMP` and its `checked` file. See Finding 2. |

## Findings

#### 1. store_check's checked file carries one brief's duplicate copy into every later brief's verdict, against check_line's own "nothing carries" inventory

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:601-602`, `:624`, `:632`, `:640`, `:866-869`, `:911`
**Move:** 7 (coupling: temporal state shared through a file), 2 (responsibility)
**Confidence:** High (reproduced)
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:632 (perl appends each verified id, every call)
      exit($n ? 0 : 1)' >> "$GATE_TMP/checked" || return 1  # REV^{tree} is never skipped, so 0 read is a fault
# scripts/build-loop.sh:640 (the duplicate scan: want = the whole checked file, not this call's ids)
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/checked" -
# scripts/build-loop.sh:866-869
# Nothing but its locals and the walk caches it resets may carry from one
# brief to the next: each helper empties its own globals before use (DENY,
# PATHS and PATHS_WHY, LIST, LIST_WHY and LIST_BAD, STATUS, BRIEF, CHECKOUT_WHY, FLOOR_WHY,
# TRUTH_WHY).
```

Probe (throwaway bats file under my scratch dir, with this repo's fixtures). Two open briefs, x and y, each with its own branch. The store is repacked, and then a loose second copy of `feat/x:work-feat-x.txt` is added. That blob is not in feat/y's tip or merge.
```text
== Y alone: 0
 ok docs/working/briefs/2026-10-01-y.md 52456a83... 4f2d958d...
== X then Y: 2
 refuse docs/working/briefs/2026-10-01-x.md: an object of the tip of feat/x or of the merge does not hash to its id, has a second copy in the object store, or could not be read
 refuse docs/working/briefs/2026-10-01-y.md: an object of the tip of feat/y or of the merge does not hash to its id, has a second copy in the object store, or could not be read
== Y then X: 2
 ok docs/working/briefs/2026-10-01-y.md 52456a83... 4f2d958d...
 refuse docs/working/briefs/2026-10-01-x.md: ...
```

**Why this is a problem.** The skip cache (A2/C2) and the duplicate scan (A1) share one file, but they want different sets:
- The skip set should keep growing across calls, so that ids already hashed are not hashed again.
- The duplicate set should be "main's ids plus this call's ids".

Because one file serves both, brief y's verdict depends on which briefs came before it in argument order. y's refusal line also names "the tip of feat/y", which is false.

check_line's inventory states the invariant this breaks, and the inventory does not list `$GATE_TMP/checked`. The cache was added without updating it. The failure is fail-closed, so the harm today is a wrong attribution and an order-dependent verdict in a multi-brief `--check`, not a forged ok.

The seam matters next unit. U3a2's `--merge` runs check_line's steps and then re-runs the state gate before the ref moves (row 494). Whoever extends store_check, for example to re-scan before the CAS, has to know which of the file's two meanings they are relying on.

**Recommendation:**
- Have the perl step write this call's ids to a per-call file.
- Run the duplicate scan over main's ids (kept by `gate_start`) plus that per-call file.
- Then append the per-call ids to the skip set.
- Add `$GATE_TMP/checked` to check_line's inventory as the one deliberate carry (a skip cache only).
- Add a two-brief test that pins y's ok after x's refusal.

#### 2. store_check is no longer a self-contained primitive: it needs GATE_TMP and run-scoped state, which changes row 644's move-later premise

**Severity:** Informational
**Location:** `scripts/build-loop.sh:612-618`; `docs/reviews/override-log.md:644`
**Move:** 1 (dependency direction), 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
# scripts/build-loop.sh:612-618 (store_check's comment closes, then it opens; continues to :641)
# family, Q-103). Reads the real repository's object store, as merge-tree
# writes into it. Needs GATE_TMP.
store_check() {
  local r alg fmt o p
  fmt="$(git rev-parse --show-object-format)" && o="$(git rev-parse --path-format=absolute --git-path objects)" || return 1
  case "$fmt" in sha1) alg=1 ;; sha256) alg=256 ;; *) return 1 ;; esac
  touch "$GATE_TMP/checked" || return 1
```

Iteration 1's deferral of the lib move (Finding 6, row 644) rested on "it reads no script global, so moving it later is a cut-and-paste". That no longer holds. Under `set -u`, an unset `GATE_TMP` stops the script. If `GATE_TMP` is empty, the path becomes `/checked`, so `touch` fails and store_check returns 1 (fail-closed).

The deferral itself is still right. But the D6 move now has to carry `GATE_TMP` with it, or take the scratch path as a parameter. Finding 1's fix would add a second file.

**Recommendation:** Leave the code alone and update row 644's note: "the move carries store_check's run state (GATE_TMP/checked); pass the dir as an argument when it moves."

#### 3. `GATE` joins three other gate names that mean the merge repository

**Severity:** Informational
**Location:** `scripts/build-loop.sh:340-348`, `:568`
**Move:** 3 (module boundary: naming of a cross-cutting flag)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```bash
# scripts/build-loop.sh:340-341
GATE=""; [[ "$MODE" != check ]] || GATE=1
if [[ -n "$GATE" ]]; then state_gate || exit 2; fi
# scripts/build-loop.sh:568
GATE_TMP=""; GATE_ENV=()
```

`GATE_TMP`, `GATE_ENV` and `gate_git` all refer to the merge repository. `GATE` instead means "this mode is gated". The api-consistency lane already rowed `gate_` ambiguity as Won't-Fix (row 641). The new flag is one more instance, on the line U3a2 has to edit.

**Recommendation:** Optional. A name like `GATED` would read as a mode property. Otherwise, add a one-line comment at `:340`.

## What Looks Good

- **The startup flag closes the fail-open.** Both top-level sites read one positive flag. The A15 call log now enforces the order the help text promises, so a missed edit shows up in tests.
- **The duplicate refusal is placed well.** It lives inside store_check, the one primitive both call sites already trust. The alternates refusal joins the existing info-file loop in `state_gate`. Neither adds a new check site, and neither reaches into the walk or reader code.
- **The values seam is documented, not only patched.** The `status_fields` comment now states each shape the next consumer would otherwise relearn from the printed line: skip vs ok, `-` meaning none, an empty `BRIEF` and why. The plan records which unit owns row 512's half.
- **The repository rule now places store_check.** U3a2's `commit-tree`, `update-ref` and `merge --ff-only` can be placed by it.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The checked file serves as both skip cache and duplicate set; one brief's second copy refuses every later brief, against check_line's inventory | Coupling | `scripts/build-loop.sh:624,632,640,866-869` | High |
| 2 | store_check now needs GATE_TMP and run state; row 644's move is no longer cut-and-paste | Informational | `scripts/build-loop.sh:612-618` | High |
| 3 | `GATE` flag name overlaps the merge-repository `GATE_*`/`gate_git` names | Informational | `scripts/build-loop.sh:340` | Medium |

## Overall Assessment

All six of iteration 1's findings are resolved or correctly rowed:
- the startup has one flag;
- `BRIEF` is emptied and its rule is stated;
- the repository rule places store_check;
- row 512's half has an owner in U3a2.

The fix batch adds one coupling: a single run-scoped file serves both the skip cache and the duplicate set. That breaks check_line's per-brief independence. I reproduced it: brief y refuses after x and is ok alone. The fix is a few lines in store_check plus an inventory line. It is fail-closed, so it is not Structural. It still matters before U3a2, which builds `--merge` on store_check and check_line. Nothing here calls for restructuring.

## Goal-Alignment Note
- **Success criterion (verbatim):** a markdown report saved at the path your dispatch names, structured per your skill.
- **Answered:** yes. All four named resolutions are verified in the table: the GATE flag; the BRIEF reset in status_fields; store_check's checked-file state across calls in GATE_TMP; row 512 moved to U3a2. New coupling from the fix: Findings 1-3.
- **Out of scope:**
  - Whether one copy per id is sufficient against the pack-index, midx, promisor and delta-base cases in brief item 1. That is the security lane.
  - The duplicate scan's cost per brief. That is the performance lane.
  - The stale state_gate header and the U3a2 bullet. Fact-check i2 covers those.
- **Escalate:** none. Finding 1 can be fixed in place.
- **Decisions I made:**
  - I rated Finding 1 Coupling rather than Minor because it breaks an invariant the code states, with a reproduced order-dependent verdict, on the seam U3a2 builds on. The alternative was Minor, on the grounds that it is fail-closed.
  - My probe ran only under my scratch dir. Nothing in the worktree was edited except this report.
