Commit: 809df345

# Architecture Review — feat/build-loop-u2b1b (U2b1b, iteration 1)

**Scope:** `git diff main...HEAD` (main 0e4596ce → 809df345): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/reviews/override-log.md`, `docs/working/plan-build-loop-handoff.md`; context `scripts/lib/dev-cycle-read.sh` (unchanged).
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2b1b.md` (43 claims, 0 Incorrect/Stale) and its merged summary.

Scope check: in scope. The diff adds a new rule layer (`nrules`) to the gate's public output contract (new `path`/`deny` line kinds, a new verdict form, a new `refuse state default-branch` WHAT), a new git wrapper (`gate_git`) that U3's `--merge` will reuse, and it sits against the lib's documented gate caller contract (cross-cutting). Test and doc files are read for context only.

Trust-boundary scan: the most recent `docs/reviews/security-review-*.md` is `security-review-2026-10-02-digest-pass38.md` (Commit: 90364c73), which predates this diff. Its `B1` (repo text → `--check-fix` gate → docs edit) runs through `truthrule`, which Finding 1 touches; cited there with the staleness note.

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh` (one direction; the lib never refers to the script except in comments). The lib owns the shared predicates: `pathform`, `NAMECHARS`, `writable`, `lower`, `FENCE_AWK`, `brief_fields`, `resolve_main`, and the U2a4 self-merge pieces `truthrule`, `truthwalk`, `ownfile`, `floor`, with the gate caller contract in its header (lib:43-79).
- New in the script, layered as: `gate_git` (git in the gate-owned repository, stderr is a failure) ← `merge_result` (merge-base, tree existence, merge-tree) and `own_blob` (hash-object) ← `check_line` (re-reads `status_line`, `--expect`, merge, `diff-tree` listing, NUL parse, `nrules` per path, verdict and row printing). `nrules` depends on lib `pathform`, `lower`, `writable` and on the script's `own_blob`.
- The R7 default-branch check sits at script top level (build-loop.sh:241-253), after lib `resolve_main`, separate from `state_gate` (build-loop.sh:210-236).
- `check_line` runs inside `out="$(check_line "$a")"` (build-loop.sh:612), a subshell per brief; the parent shell pre-runs `open_shared` for that reason (build-loop.sh:607).

Dependency direction is correct throughout: the script (volatile, gate policy) depends on the lib (shared, more stable); nothing new flows the other way.

## Findings

#### 1. The "dev cycle's own files" set now has three definitions; nrules' copy is wider than the lib's and the plan's

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:549-550`; `scripts/lib/dev-cycle-read.sh:202-205` (`writable`), `:1085-1096` (`truthrule`)
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** the U2c implementer (who adds the S rules beside `nrules` and words the floor's denials) and whoever next edits `writable` or `truthrule`.

Evidence (build-loop.sh:549-550):
```
  elif writable "$lp" || [[ "$lp" =~ ^docs/(dev-cycle\.md$|working/(briefs|cycles)/) ]]; then DENY="one of the dev cycle's own files"
  elif [[ "$lp" == docs/constraints.md ]]; then DENY="the user's constraints doc, which every loop prompt carries"
```
Evidence (lib:1089-1093, inside `truthrule`, which continues to :1096):
```
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
```
Evidence (plan F12): `N-denied via the lib's writable() plus docs/dev-cycle.md (T14)`.

The same concept ("cycle-owned, plus settings, plus the user's constraints") is spelled in `truthrule` (lib, shared with `--check-fix` and `floor`) and again in `nrules` (script), and `nrules` adds two prefixes (`docs/working/briefs/`, `docs/working/cycles/` subtrees) that neither `writable`, `truthrule` nor plan F12 has. Today the difference is invisible under self-merge (the floor's `docs/working/*` ownfile rule catches e.g. `docs/working/briefs/README.md` with a different reason), but under `--merge --approved` only the N rules apply (plan :213), so the script's copy is the authoritative one there and the lib's is the authoritative one for `--check-fix`. A future edit to `writable` (say a new cycle file) reaches `nrules` only through the `writable` call, not the extra regex; an edit to the regex reaches nothing else. The denial strings are also duplicated verbatim ("the user's constraints doc, which every loop prompt carries" appears in `nrules` and in `floor`, lib:1144). The plan's step-5 note says the N rule set came from F12; the code is now wider than F12 states, and the plan was not updated to say so.

**Security implication:** consolidating into `truthrule` changes `B1` from `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: 90364c73) — security review predates this diff; boundary may be stale. Widening `truthrule`'s cycle set to the subtree would also widen what `--check-fix` refuses; keep that a deliberate choice.

**Recommendation:** Name one lib predicate (e.g. `cycleown LP`, returning a reason word) that holds writable + `docs/dev-cycle.md` + the briefs/cycles subtrees + `docs/constraints.md`, called by both `truthrule` and `nrules`; or have `nrules` call `truthrule` and deny on `TRUTH_WHY` ∈ {cycle, settings, user, case}. Either way update plan F12 to the subtree rule if it is intended.

#### 2. The lib's gate caller contract item 5 now contradicts the order build-loop.sh runs, and U2c is to add the S rules beside nrules

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:59-63`; `scripts/build-loop.sh:544-547`
**Move:** 3 (module boundary), 4 (layer order)
**Confidence:** High
**Legibility-target:** the U2c implementer, and the U2b2 author who edits contract items 2-4 (override row: "Revisit trigger: U2b2's edit of the header's contract items 2-4").

Evidence (lib:59-63, the header's "one statement" of the contract, lib:43-44):
```
#  5. Ask floor about each changed path, in this shell, before pathform or
#     main_entry (so .github/x.yml is refused as a dotfile, not as badform),
#     and refuse the whole branch on any main_entry word but blob or absent
#     (rows 308, 324). Floor item 5 (symlinks, gitlinks) and the brief's own
#     Status change are the caller's rules.
```
Evidence (build-loop.sh:544-547, `nrules`, which continues to :552):
```
  if ! pathform "$6"; then DENY="not an allowed path form (letters, digits and . _ - / only, no .git part)"
  elif [[ ! "$2 $3" =~ ^(000000|100644|100755)\ (000000|100644|100755)$ ]]; then DENY="not a regular file on both sides (only modes 100644 and 100755 land)"
  elif [[ "$6" == "$1" ]]; then
```
U2b1b made `pathform` an N rule under both policies (commit cc9b69d3's Notes), so `pathform` now runs first, and the exact example item 5 cites (`.github/x.yml`) is denied by `nrules` as a path form before any floor call. With `nrules` as an `if/elif` chain that sets `DENY` once, the natural U2c addition ("U2c adds the S rules", build-loop.sh:539) runs `floor` after `pathform`: the contract item 5 order becomes impossible without reordering N inside S. The contract and the design have diverged; one of them must change, and it is the header that U2c is told to keep ("keeps every item of the lib header's numbered gate caller contract", plan :279). Also, the "Floor item 5 ... the caller's rules" sentence is now true but stale in emphasis: the caller enforces it under both policies, not only beside floor. Fact-check claim 22 notes the pathform deny reason does not explain leading `-`/`/` or empty/`.`/`..` parts, so the "badform" wording item 5 sought to avoid is real.

**Recommendation:** Edit contract item 5 in this unit (or record it explicitly for U2b2's header edit): the N rules (pathform, the mode rule, the own brief) run first under both policies; floor runs after them for the paths they pass, and the "dotfile, not badform" wording goal is met by the N deny reason instead. Keep the `floor` comment at lib:1129-1131 in step.

#### 3. check_line has become the whole per-brief pipeline in one printing function; U3's --merge needs its verdict, not its text

**Severity:** Coupling
**Location:** `scripts/build-loop.sh:558-593` (`check_line`), `:612-613` (caller)
**Move:** 2 (responsibility), 5 (interface segregation), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** the U3 `--merge` implementer.

Evidence (build-loop.sh:578, 586-593; the function starts :558):
```
  if ! gate_git diff-tree -r --no-renames --raw -z --ignore-submodules=none "$MAIN_SHA" "$tree" > "$GATE_TMP/diff"; then
...
    shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"
    nrules "$a" "$om" "$nm" "$no" "$s" "$p"
    if [[ -n "$DENY" ]]; then nd=$((nd + 1)); rows+=("deny $a $s $shown: $DENY"); else rows+=("path $a $s $shown"); fi
  done < "$GATE_TMP/diff"
  # Every record read whole: two NUL-ended fields each.
  if [[ "$(tr -cd '\000' < "$GATE_TMP/diff" | wc -c)" -ne $((2 * i)) ]]; then echo "refuse $a: the paths the merge of $br changes could not be read"; return; fi
  if [[ "$nd" -eq 0 ]]; then echo "ok $a $sha $tree"; else echo "refuse $a: $nd of $i changed paths refused"; fi
  [[ "$i" -eq 0 ]] || printf '%s\n' "${rows[@]}"
```
Evidence (caller, :612-613): `out="$(check_line "$a")"; printf '%s\n' "$out"` / `[[ "$out" == "ok "* ]] || fails=1`.

`check_line` now re-reads the brief state, checks `--expect`, computes the merge, lists the changed paths, validates the NUL framing, applies the rules and formats output; its only result is printed text whose first line the caller string-matches. Plan D7 has `--merge` run "as `--check`, then commit-tree and CAS", so U3 needs TIP, TREE and the verdict as values. The existing deferred override row ("check_line parses status_line's and check_branch's printed lines by field position", Revisit trigger: U3's `--merge`) is the same pattern one level up; this unit extends it rather than adding the seam. Splitting is cheap now (the parse loop already collects `rows`, `nd`, `i`) and expensive after U2c adds S rules into the same loop.

**Recommendation:** Before or with U2c, factor `changed_paths` (diff-tree + NUL parse + framing check, filling arrays) and a judge step that sets `VERDICT`/`TREE`/`ROWS` globals (the lib's `FLOOR_WHY`/`TRUTH_WHY` convention), leaving `check_line` as the printer. Fold this into the existing U3 override row rather than a new one if deferring.

#### 4. own_blob re-derives brief_fields' "first unfenced Status: line" with a second awk program

**Severity:** Minor
**Location:** `scripts/build-loop.sh:527-534`; `scripts/lib/dev-cycle-read.sh:355-379` (`brief_fields`)
**Move:** 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** whoever changes the brief's field grammar in `brief_fields`.

Evidence (build-loop.sh:531, inside `own_blob`, which continues to :534):
```
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ sub(/\r$/, "") } fence($0) { next } !n && /^Status:/ { n = NR } END { print n + 0 }')" || return 1
```
Evidence (lib:363-366, inside `brief_fields`):
```
    { sub(/\r$/, "") }
    fence($0) { next }
    match($0, /^(Status|Branch|Policy|Paths|Asked|Dispatched):/) {
      k = tolower(substr($0, 1, RLENGTH - 1)); if (!(k in got)) { got[k] = 1; kv[++nk] = k "\t" $0 }
```
F13's rule ("the first unfenced `Status: open`") is defined by `brief_fields`; `own_blob` copies the selection logic and relies, by comment only, on `status_line` having vetted the file (no `odd`/`infence` check of its own). The two agree today. A change to `brief_fields` (a new skip rule, a different field match) silently makes the gate's allowed blob differ from the line the state read used, which fails closed (a deny) rather than open, hence Minor.

**Recommendation:** Have `brief_fields` record the Status line's number (e.g. `BRIEF_STATUS_NR`) and let `own_blob` use it, so one program defines the line.

#### 5. The R7 check is a second, inline state gate keyed on MODE == check

**Severity:** Minor
**Location:** `scripts/build-loop.sh:238-253`
**Move:** 4 (layer placement), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** the U3 `--merge` implementer (who must extend every `MODE == check` site).

Evidence (build-loop.sh:238-250, top level):
```
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
...
if [[ "$MODE" == check ]]; then
  if git show-ref --verify --quiet refs/heads/main && git show-ref --verify --quiet refs/heads/master; then
    echo "refuse state default-branch: both main and master exist"; exit 2
  fi
  p="$(git symbolic-ref -q refs/remotes/origin/HEAD)" || true
  if [[ -n "$p" && "$p" != "refs/remotes/origin/$MAIN" ]]; then
    echo "refuse state default-branch: origin/HEAD names ${p#refs/remotes/}, but the default branch taken is $MAIN"; exit 2
```
Placement is defensible: it cannot live in `state_gate` (it needs `$MAIN`, and `state_gate` must run before `resolve_main` reads an object), and putting it in lib `resolve_main` would make `dev-cycle.sh` and `--status` refuse legitimate repos holding both names. But as unnamed top-level code it (a) duplicates the `MODE == check` guard U3 must widen in two places, (b) prints `refuse state` lines with a different discipline from `state_gate` (exit on first finding rather than one line per finding then exit, as the help at build-loop.sh:89-93 describes for the state lines generally), and (c) leaves `--status` reading the R7-ambiguous branch with no warning, an asymmetry the help does not name. None is a defect today.

**Recommendation:** Wrap it as `default_branch_gate` beside `state_gate`, called from one `gate_mode` predicate (`check`, later `merge`), and have it collect findings like `state_gate`. Optionally note in `--status`'s help that it does not apply R7.

#### 6. check_line reads the lib's NAMECHARS directly to form a second, weaker printable-path rule

**Severity:** Minor
**Location:** `scripts/build-loop.sh:586`; `scripts/lib/dev-cycle-read.sh:181-191`
**Move:** 3 (module boundary), 7 (content coupling)
**Confidence:** Medium
**Legibility-target:** the API-consistency and U3 readers of `path`/`deny` lines.

Evidence (build-loop.sh:586): `    shown="?"; [[ ! "$p" =~ ^[$NAMECHARS]+$ ]] || shown="$p"`

`NAMECHARS` is the lib's internal building block of `pathform`. The script reuses it to define a display rule that differs from `pathform` (allows a leading `-`, `..`, empty parts, `.git` parts), which is documented in the help but is a second path rule living outside the lib's "one path rule" (lib:168). The script already does this at build-loop.sh:328 for globs, so it is a pattern, not a one-off. A change to `NAMECHARS` (e.g. adding a character) changes both rules at once, which is likely intended, so impact is low.

**Recommendation:** Expose a named lib predicate (`namechars_only`) for the display rule so its relation to `pathform` is stated in one place.

#### 7. U2c's floor call will run inside check_line's subshell; the precedent that makes this safe is implicit

**Severity:** Informational
**Location:** `scripts/build-loop.sh:607`, `:612`; `scripts/lib/dev-cycle-read.sh:23-24`, `:59`
**Move:** 4 (layer order)
**Confidence:** Medium
**Legibility-target:** the U2c implementer.

Evidence (lib:23-24): `Call the exiting checks in the caller's shell, not inside $(...) or` / `` `local x="$(...)"`, where an exit ends only the subshell. ``; (lib:59) `Ask floor about each changed path, in this shell`; (build-loop.sh:607) `open_shared  # once, in this shell: check_line runs in a subshell`.

Placing `nrules` in `check_line`'s per-path loop fixes where U2c's `floor` call goes: inside `$(check_line ...)`. `floor` exits through `need_root` and caches the import walk in shell variables; in a subshell the exit loses the message (the caller sees an empty, non-ok verdict, so it fails closed) and the walk cache is rebuilt per brief. The `open_shared` precedent (run once in the parent so subshells inherit the cache) solves both if U2c runs `main_imports` in the parent before the loop, but nothing in the plan or the contract says so.

**Recommendation:** Add to the U2c note (or contract item 5) that `--check` warms `main_imports` in the parent shell before the per-brief loop, as it does `open_shared`.

#### 8. gate_git is the right seam for U3; its error channel is one shared file

**Severity:** Informational
**Location:** `scripts/build-loop.sh:502-507`, `:512-522`, `:533`
**Move:** 1 (dependency direction), 7
**Confidence:** Medium
**Legibility-target:** the U3 `--merge` implementer (commit-tree and CAS through the gate repository).

Evidence (build-loop.sh:502-507, whole function):
```
gate_git() {
  local rc=0
  (cd "$GATE_TMP/work" && "${GATE_ENV[@]}" git "$@") 2>"$GATE_TMP/err" || rc=$?
  [[ ! -s "$GATE_TMP/err" ]] || return 3
  return "$rc"
}
```
Concentrating "git in the gate repository, any stderr fails" in one function is good layering, and `merge_result` and `own_blob` both go through it. Two notes for U3: the return code 3 is a third failure class that `merge_result` folds into 2 and `check_line`'s `diff-tree` call folds into "could not be listed", so callers cannot tell "git warned" from "git failed" (fine for refusal, possibly not for `--merge`'s user-facing reason); and every call writes the same `$GATE_TMP/err`, which is safe only while calls are sequential. `own_blob` mixes repositories (real-repo `cat-file` piped into gate-repo `hash-object`), which is correct (the real repo's objects are the gate's object store) but the only place a gate decision reads through the hardened real repo rather than `gate_git`.

**Recommendation:** None required now; if U3 needs the warn/fail distinction, keep 3 distinct up to the caller rather than adding another wrapper.

#### 9. R8 (racing GATE_TMP): no structural seam closes it in-process

**Severity:** Informational
**Location:** `scripts/build-loop.sh:608` (`GATE_TMP="$(mktemp -d)"`), `gate_repo` (ends :497)
**Move:** 3
**Confidence:** Low (disposition is security-reviewer's)
**Legibility-target:** whoever records R8's disposition.

Evidence (build-loop.sh:608): `GATE_TMP="$(mktemp -d)"; trap 'rm -rf -- "$GATE_TMP"' EXIT`

Structurally, every gate decision now flows through `gate_git` into `$GATE_TMP`, so R8's reach grew in this unit (diff-tree, merge-base, hash-object all read the gate repository's config and info files). A same-uid writer can modify any directory the gate creates; the only structural responses are ones outside this script (a different uid, a read-only mount), which matches the plan's "What the gate can and cannot do" scope and the proposed Q-103 residual. Architecture has no objection to the residual; the override row should note that U2b1b widened the surface R8 covers.

## What Looks Good

- Dependency direction is clean: all new code is in the script and consumes lib predicates; nothing in the lib learned about the gate.
- `gate_git` puts the R6 discipline (stderr is failure) in one place, and moving `diff-tree` into the gate repository (A16) reuses the existing gate repository rather than adding a second isolation mechanism.
- `nrules` follows the lib's established result-variable convention (`DENY` alongside `FLOOR_WHY`/`TRUTH_WHY`), keeps the N/S split the plan names, and is called per path with plain arguments (data coupling).
- Verdict-line-first output keeps the existing caller test (`"$out" == "ok "*`) valid while adding per-path lines; the override row's "every verdict line ok" resolution is coherent with the code.
- The mode rule as an N rule removes floor item 5 as a caller-only duty earlier than planned, simplifying what U2c must remember.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Cycle-owned set defined three times; nrules' copy wider than writable/truthrule/plan F12 | Coupling | `scripts/build-loop.sh:549-550` | High |
| 2 | Lib caller contract item 5 order contradicted by nrules (pathform first); U2c builds against it | Coupling | `scripts/lib/dev-cycle-read.sh:59-63` | High |
| 3 | check_line is the whole pipeline with text-only output; U3 needs values | Coupling | `scripts/build-loop.sh:558-593` | Medium |
| 4 | own_blob duplicates brief_fields' Status-line selection | Minor | `scripts/build-loop.sh:531` | Medium |
| 5 | R7 check is an unnamed inline state gate keyed on MODE == check | Minor | `scripts/build-loop.sh:241-253` | Medium |
| 6 | check_line reads lib NAMECHARS for a second path rule | Minor | `scripts/build-loop.sh:586` | Medium |
| 7 | U2c floor will run in check_line's subshell; warm-in-parent precedent unstated | Informational | `scripts/build-loop.sh:607,612` | Medium |
| 8 | gate_git is a good seam; error class 3 folded, one shared err file | Informational | `scripts/build-loop.sh:502-507` | Medium |
| 9 | R8: surface widened by this unit; residual structurally consistent | Informational | `scripts/build-loop.sh:608` | Low |

## Overall Assessment

The change keeps the system's structure sound: dependencies flow script → lib, the new wrapper is a proper seam, and the N/S split matches the plan. The issues are all fixable in place and none needs restructuring now. The single most important concern is that the gate's rule definitions and their contract are drifting apart across the script/lib boundary: the cycle-owned set exists in two non-identical forms (Finding 1), and the lib header's "one statement" of the caller contract now describes an order the caller no longer follows (Finding 2). Both land on U2c's desk; fixing them before U2c (one lib predicate for the cycle set, a corrected item 5) is cheaper than after the S rules are added into the same `elif` chain. Finding 3 is the U3-facing counterpart and can ride the existing deferred override row.

## Goal-Alignment Note

The user goal is to land U2b1b after a clean review-fix loop. Nothing here blocks the unit's purpose (the N rules and the carried reds are structurally placed correctly); no Structural findings. The two Coupling findings with High confidence (1, 2) are cheap, documentation-plus-small-refactor fixes that keep U2c's brief truthful; Finding 3 is reasonably deferred to U3 by extending the existing override row. On R8, architecture sees no in-script fix and finds the Q-103 residual consistent with the plan's threat scope, with the note that this unit widened the surface it covers.
