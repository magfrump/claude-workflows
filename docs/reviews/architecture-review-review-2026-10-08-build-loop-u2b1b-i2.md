Commit: a382a3f8

# Architecture Review — feat/build-loop-u2b1b (U2b1b, iteration 2)

**Scope:** `git diff 809df345..a382a3f8` (the iteration-1 fix commit): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` (header comment only), `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md`, `docs/reviews/override-log.md`. Context: the rest of the branch (cc9b69d3, 809df345) and the lib's `truthrule`, `writable`, `floor`, `lower_all`, `nul_list`.
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check `docs/reviews/code-fact-check-report-build-loop-u2b1b-i2.md` (30 claims: 25 Verified, 5 Mostly accurate, 0 Incorrect) and its summary. Iteration 1: `docs/reviews/architecture-review-review-2026-10-08-build-loop-u2b1b.md`, rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b1b.md`.

Scope check: in scope. The fix changes the gate's rule layer's dependency on the lib (`nrules` now consumes `truthrule`'s word vocabulary), the lib's documented gate caller contract (item 5), the verdict line's public format, and adds a named state-gate function (`default_gate`) that U3b's `--state` is to call.

Trust-boundary scan: the most recent dated `docs/reviews/security-review-*.md` is still `security-review-2026-10-02-digest-pass38.md` (Commit: 90364c73). Its `B1` (repo text → `--check-fix` gate → docs edit) runs through `truthrule`, which Finding 1 touches; cited there. That review predates this diff; the boundary may be stale.

## Dependency Map

- `scripts/build-loop.sh` sources `scripts/lib/dev-cycle-read.sh`; the direction is unchanged (script → lib). New edge in this commit: `nrules` → lib `truthrule` (and through it `isstart`, `writable`); the old edges `nrules` → `lower` and `nrules` → `writable` are gone. `check_line` → lib `nul_list` + `lower_all` (new; the same batch helpers U2a3c's walk uses).
- `truthrule` now has three consumers: `floor` (lib, self-merge S rules), `dev-cycle.sh --check-fix`, and `nrules` (N rules, both policies, the only rules under `--merge --approved`).
- `default_gate` (build-loop.sh:240-250) sits beside `state_gate` (:212-233) and reads the global `MAIN` that `resolve_main`/`main_by_name` set (:257-258); both are called at top level keyed on `MODE == check` (:256, :259).
- `check_line` (:575-622) is now two phases: collect diff-tree records into index-aligned local arrays (:598-603), batch checks over all of them (NUL framing :605, blob presence :609-612, one lower-case pass :614), then a judge-and-print loop calling `nrules` per index (:615-621).

## Iteration 1 findings: resolution

| It. 1 | Finding | Verdict | Basis |
|---|---|---|---|
| 1 | Three definitions of the cycle-owned set | **Resolved**, with residuals (Findings 1, 2 below) | `nrules` reads `truthrule`'s `cycle`, `settings` and `user` words (build-loop.sh:561-565); `writable` and the two named files now have one spelling; the floor's constraints reason is reused verbatim. The briefs/ and cycles/ subtrees stay an N-only widening, named in the comment at :547-548. |
| 2 | Contract item 5 contradicts the run order | **Resolved** | lib:59-65 now says the N rules run pathform first under both policies and floor's dotfile reason serves the dot paths pathform accepts. Consistent with `floor`'s own comment (lib:1131-1133). Residual wording note in Finding 4. |
| 5 | R7 check inline at top level | **Resolved** | `default_gate` is a function beside `state_gate`, prints every finding with `bad=1` rather than exiting at the first (:242-249), and its comment names U3b's `--state` as the caller of both (:235-236). The two-finding output has no test (fact-check summary, "Smaller"); that is a test gap, not structure. |

## Findings

#### 1. The N rules now depend on truthrule's precedence order, and truthrule's comment does not name them as a consumer

**Severity:** Minor
**Location:** `scripts/build-loop.sh:561-565`; `scripts/lib/dev-cycle-read.sh:1076-1095`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** whoever next edits `truthrule` for the floor's or `--check-fix`'s sake (U2c's S-rule author, a later `--check-fix` change).

Evidence (build-loop.sh:561-565, inside `nrules`, which runs :552-568):
```
    truthrule "$7" || true  # $7 is lower-cased, so no word hides cycle, settings or user
    case "$TRUTH_WHY" in
      cycle|settings) DENY="one of the dev cycle's own files" ;;
      user) DENY="the user's constraints doc, which every loop prompt carries" ;;
      *) [[ ! "$7" =~ ^docs/working/(briefs|cycles)/ ]] || DENY="one of the dev cycle's own files" ;;
```
Evidence (lib:1089-1094, inside `truthrule`, which runs :1087-1096):
```
  if [[ "$1" == *[ABCDEFGHIJKLMNOPQRSTUVWXYZ]* ]]; then TRUTH_WHY="case"
  elif isstart "$1"; then TRUTH_WHY="instr"
  elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"
  elif writable "$1"; then TRUTH_WHY="cycle"
  elif [[ "$1" == docs/dev-cycle.md ]]; then TRUTH_WHY="settings"
  elif [[ "$1" == docs/constraints.md ]]; then TRUTH_WHY="user"
```
Evidence (lib:1076): `# The read-as-truth rule --check-fix and floor share (plan D5 items 1, 2 and 4;`

`truthrule` returns one word, the first that fires, so `nrules` denies a cycle, settings or constraints path only if no earlier word (`case`, `instr`, `dot`) fires on it. Today that holds because the sets are disjoint (every `writable` path and both named files sit under `docs/` with no dot part and no instruction basename), not because `$7` is lower-cased, which only rules out `case`; the comment at :561 states one third of the invariant. Before this commit `nrules` called `writable` directly and had no ordering dependency. The dependency is new in direction too: `truthrule` was the self-merge/`--check-fix` vocabulary, and the N rules are the only rules under `--merge --approved`, so an edit made for the floor (a new word inserted ahead of `cycle`, say for `docs/working/`) would let a cycle file pass the N rules — the fail-open direction. The comment that tells an editor who depends on the order names only `--check-fix` and floor. Mitigation that keeps this Minor: T14 (build-loop-check.bats:1453-1473, every `writable` family plus `docs/dev-cycle.md` and `docs/constraints.md`) and the shared-rule test at :1104-1121 (each word pinned per path) both fail on such a shadowing, so the coupling is test-guarded for every current family.

**Security implication:** `B1` from `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: 90364c73) — security review predates this diff; boundary may be stale. `truthrule` is now shared across the `--check-fix` boundary and the merge gate's N rules; an edit to its order moves both.

**Recommendation:** Name `build-loop.sh`'s N rules in `truthrule`'s comment (lib:1076) as a third consumer that depends on `cycle`, `settings` and `user` never being shadowed by an earlier word, and make the :561 comment state the whole invariant (no `case`, `instr` or `dot` word can fire on those paths). No code change needed now.

#### 2. Plan F12 still states the narrower rule; the briefs/ and cycles/ subtree widening is recorded only in nrules' comment

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:127`; `scripts/build-loop.sh:547-548, :565`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** the U2c implementer and the U5 Q-103 reader, who read the F-table as the coverage record.

Evidence (plan:127): `| F12 | Cycle-owned files, any other brief including a new one, `briefs/closed/` | covered | N-denied via the lib's `writable()` plus `docs/dev-cycle.md` (T14) |`
Evidence (build-loop.sh:547-548): `# (truthrule's cycle and settings words: writable() and docs/dev-cycle.md,` / `# plus anything under docs/working/briefs/ or docs/working/cycles/) and the`

Iteration 1's recommendation had two parts: one source for the set, and "update plan F12 to the subtree rule if it is intended". The first is done; the fix commit's only plan edit is step 13 (R8). The widening is deliberate (rubric A1: "an N-only widening, named in nrules' comment") and T14 pins it (`docs/working/cycles/notes.md`, `docs/working/briefs/closed/x`), so the code is right; the plan row that claims F12's coverage describes a smaller rule than the gate applies under `--approved`, and `docs/constraints.md` (the `user` word) is not in F12 at all.

**Recommendation:** Reword F12's note to "writable() plus docs/dev-cycle.md and any path under docs/working/briefs/ or docs/working/cycles/ (T14)", and point `docs/constraints.md`'s N denial at its own row (or add it to F12), in this unit or as part of the next plan edit.

#### 3. check_line's parallel arrays are the right seam; nrules' positional list grows and trusts $7

**Severity:** Informational
**Location:** `scripts/build-loop.sh:576, :598-603, :614-617`; `:543-545`
**Move:** 8 (extension points), 5 (interface segregation)
**Confidence:** Medium
**Legibility-target:** the U3 `--merge` implementer (override row for architecture 3: "splits out a changed-paths step and a judge step with values") and U2c (which adds floor's stem and status inputs).

Evidence (:576): `local a="$1" out st br loop sha n tree meta p shown rc=0 i nd=0 rows=() oms=() nms=() nos=() ss=() ps=() lps=() ids=()`
Evidence (:617): `nrules "$a" "${oms[$i]}" "${nms[$i]}" "${nos[$i]}" "${ss[$i]}" "$p" "${lps[$i]}"`

The fix split `check_line`'s loop into collect, batch-check and judge phases. That is the `changed_paths` / judge seam iteration 1's Finding 3 asked for, now present inside one function: the collect phase's six index-aligned arrays (`ids` is a set, not aligned) are exactly the out-parameters a split-out `changed_paths` would fill by nameref, as `nul_list` already does. No new coupling crosses a module boundary: the arrays are locals. Two things to carry: `nrules` now takes seven positional arguments, two of them one path in two spellings, and it trusts `$7 == lower($6)` without checking (the caller guarantees it at :614 by count, not by pairing, which holds because `lower_all` maps NUL-separated fields one to one); U2c's S rules need the brief's stem and the status letter too, so the positional list will keep growing.

**Recommendation:** At U3's split (the existing override row, no new row), make the collect phase a function filling named arrays and pass `nrules` an index (or a record) rather than more positional fields.

#### 4. Contract item 5 now names a caller's internals and leaves open whether floor runs on N-denied paths

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:59-65`
**Move:** 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** the U2c implementer, who adds floor to the judge loop.

Evidence (lib:59, :62-64): `#  5. Ask floor about each changed path, in this shell, before main_entry,` … `Status change are the caller's rules; build-loop.sh's N rules apply` / `them, and pathform, under both policies before floor runs, so a path` / `pathform refuses (.github/x.yml) is denied as a path form and floor's`

The edit resolves the contradiction. Two loose ends for U2c: the lib's contract now describes one caller's rule order (the lib documenting its consumer; tolerable, since the header already says it is the one statement of the gate's duties), and "ask floor about each changed path" next to "before floor runs" does not say whether floor is asked about a path the N rules already denied. With `nrules` as an `if/elif` that sets one `DENY`, U2c will choose by construction; the output contract (one deny reason per path) suggests "only paths N passes".

**Recommendation:** When U2c adds floor, state in item 5 that floor runs only on paths the N rules pass (or that it runs on all and the first reason wins).

## What Looks Good

- `nrules` reading `truthrule`'s words instead of re-spelling `writable` + two names: one definition of the named files, and the constraints wording now matches `floor`'s byte for byte. The case-folding moved out of the rule into one batch pass in the caller, which also satisfies contract item 8 (pass `truthrule` a lower-cased path) structurally.
- `default_gate` follows `state_gate`'s convention (one `refuse state WHAT: WHY` line per finding, return 1 on any), so U3b's `--state` can call both with one handling pattern; its precondition (`MAIN` set) is stated in its comment.
- The blob-presence check is placed in the batch phase, against the gate repository through `gate_git`, keeping every object read behind the same wrapper and repository as merge-tree and diff-tree.
- The verdict line now carries TIP and TREE on refusal as on ok, so the line format is uniform for D4/F48's merge entry.
- Dependency direction is unchanged: no new lib → script edge.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | N rules depend on truthrule's precedence order; truthrule's comment names only --check-fix and floor | Minor | `scripts/build-loop.sh:561-565`; `scripts/lib/dev-cycle-read.sh:1076-1095` | Medium |
| 2 | Plan F12 states the narrower rule; subtree widening and constraints doc not in the F-table row | Minor | `docs/working/plan-build-loop-handoff.md:127` | High |
| 3 | check_line's collect/judge phases are the U3 seam; nrules' positional list grows and trusts $7 | Informational | `scripts/build-loop.sh:576, :617` | Medium |
| 4 | Contract item 5 names a caller's order; floor on N-denied paths unstated | Informational | `scripts/lib/dev-cycle-read.sh:59-65` | Medium |

Rubric mapping: no Structural (🔴) or Coupling (🟡) findings; all four are 🟢 Consider.

## Overall Assessment

The fix commit resolves iteration 1's architecture 1, 2 and 5 in place. The one new coupling it adds — the N rules reading `truthrule`'s first-match word — is real but low-impact: the word sets are disjoint today and two existing tests fail on any shadowing, so the cost is a documentation duty on `truthrule`'s comment rather than a structural change. The most important structural concern is that `truthrule` is now shared across policies (self-merge floor, `--check-fix`, and the N rules that alone guard `--approved` merges), and its comment should say so before U2c edits it. `check_line`'s new collect/judge split is a step toward the U3 seam, not away from it.

## Goal-Alignment Note

- **User goal:** land U2b1b after a clean review-fix loop.
- **This review's contribution:** confirms the three iteration-1 architecture fixes are resolved and finds no 🔴 or 🟡 architecture item in the fix range; the four 🟢 items are comment, plan-row and U2c/U3 carry-forward notes, none blocking the merge.
- **Threat class:** Finding 1 is honest-path maintainability (a future benign edit to `truthrule`), not a hostile-loop path. No finding bears on R8, which iteration 1 settled as a Q-103 residual.
- **Drift check:** no finding asks for work outside U2b1b's scope; Findings 3 and 4 fold into existing U3 and U2c triggers.
