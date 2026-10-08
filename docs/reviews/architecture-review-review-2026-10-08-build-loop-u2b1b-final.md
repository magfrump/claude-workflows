Commit: e02d056b

# Architecture Review — feat/build-loop-u2b1b (U2b1b, final confirming pass, full branch)

**Scope:** `git diff main...HEAD` (cc9b69d3, 809df345, a382a3f8, e02d056b): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh` (two comment edits), `test/scripts/build-loop-check.bats`, the plan, the override log. Context read whole: the lib's header contract (lib:44-74), `pathform`, `writable`, `resolve_main`, `truthrule`, `truthwalk`, `floor` (lib:184-206, :490-511, :1076-1180).
**Date:** 2026-10-08
**Based on:** Stage 1 fact-check summary (k=3 at e02d056b: `code-fact-check-report-build-loop-u2b1b-final-r{1,2,3}.md`; all suites pass, every carried fix's mutant fails its test; Incorrect items test/doc only). Prior: iterations 1 and 2 (`architecture-review-review-2026-10-08-build-loop-u2b1b.md`, `-i2.md`), rubric `code-review-rubric-2026-10-08-feat-build-loop-u2b1b.md`, override rows 507-520.

Scope check: in scope. The branch changes `--check`'s public output (path and deny lines, the K-of-N verdict), adds the gate's rule layer (`nrules`) as a new consumer of the lib's `truthrule`, adds a named state-gate function (`default_gate`) that U3b's `--state` is to call, and rewords the lib's numbered gate caller contract (item 5).

Trust-boundary scan: the most recent `docs/reviews/security-review-*.md` is still `security-review-2026-10-02-digest-pass38.md` (Commit: 90364c73), which predates this diff. No finding below is a module-boundary finding under move 3 that sits on its `B1`; the scan is a no-op for this pass.

Code delta since iteration 2 (a382a3f8..e02d056b): comments, the help text, one refusal string ("names a blob the object store lacks") and one test. No settled override row has had its code changed under it; none is re-flagged.

## Dependency Map

- **Script → lib, one direction.** `build-loop.sh` sources `lib/dev-cycle-read.sh` from its own directory (:148-151). No lib → script edge exists; the lib's only references to the script are comments (truthrule's third-consumer note, lib:1077-1078; contract item 5, lib:59-65).
- **Top-level prelude** (:252-260): `state_gate` (check only, reads no object) → `resolve_main` (lib) → `main_by_name` (lib) → `default_gate` (check only, reads `MAIN`).
- **Two repositories, one object store.** Lib reads of main's files and refs (`main_entry`, `brief_fields`, `check_brief`, `check_branch`, `open_shared`) run in the real repo under `harden` + exported env (:188-198). Merge-result computations run in the gate repository through `gate_repo`/`gate_git` (:497-515): `merge_result` (:520-530), `diff-tree` (:599), the blob batch-check (:615), and `own_blob`'s `hash-object` (:542).
- **check_line** (:579-628) is the per-brief pipeline: `status_line` (verdict prerequisites) → `check_branch` re-read → `merge_result` → collect (diff-tree records into index-aligned locals, :602-607) → batch checks (NUL framing :609, blob presence :615-618, one `lower_all` pass :620) → judge-and-print (`nrules` per index, :621-627).
- **nrules** (:553-572) → lib `pathform` (path form), its own mode regex, `own_blob` (own brief), lib `truthrule` (cycle, settings, user words) plus its own N-only `docs/working/(briefs|cycles)/` widening. `truthrule` now has three consumers: `floor`, `dev-cycle.sh --check-fix`, `nrules`.

## Prior findings: resolution

| Finding | Verdict |
|---|---|
| i1 1 (three definitions of the cycle set) | Resolved (a382a3f8): nrules reads truthrule's words. |
| i1 2 (contract item 5 vs run order) | Resolved (lib:59-65). |
| i1 3 (check_line returns text only) | Deferred, row 512 (trigger U3 `--merge`); the collect/batch/judge phases are the seam. |
| i1 4, 6 (own_blob's awk; NAMECHARS display) | Won't-Fix, row 516; code unchanged. |
| i1 5 (R7 inline) | Resolved: `default_gate` (:241-251). |
| i1 7, 8 (floor in a subshell; gate_git's code 3, one err file) | Deferred, row 517 (triggers U2c, U3b). |
| i2 1 (truthrule order, consumer unnamed) | Resolved (e02d056b): truthrule's comment names the N rules and the invariant (lib:1077-1078); nrules' comment states it whole (:562-564). |
| i2 2 (plan F12) | Resolved: plan:127 names the subtree widening and the user word. |
| i2 3, 4 (positional nrules; floor on denied paths) | Rows 512, 517 updated. |

## Findings

#### 1. The gate's prelude order is top-level sequencing that U3's `--merge` and U3b's `--state` must repeat, and its first edge is pinned more weakly than its comment states

**Severity:** Minor
**Location:** `scripts/build-loop.sh:256-260`; `test/scripts/build-loop-check.bats:1588-1594`
**Move:** 4 (layer violations: ordering of the read layers), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** the U3 `--merge` and U3b `--state` implementers, who add modes that must run the same prelude.

Evidence (build-loop.sh:256-260, top level; the code before it, :252-255, sets ROOT and ROOT_REAL; read_settings and the mode dispatch follow at :262 and :630):
```
# --check refuses planted state before any git call reads an object (resolve_main does).
if [[ "$MODE" == check ]]; then state_gate || exit 2; fi
resolve_main || true
main_by_name || { echo "build-loop.sh needs a default branch found by name (origin/HEAD, main or master); found none" >&2; exit 1; }
if [[ "$MODE" == check ]]; then default_gate || exit 2; fi
```
Evidence (bats:1588, the test that pins the first edge): `@test "--check runs its state gate before resolve_main reads an object: a planted key refuses even with main's commit missing (A15, U2b1b)" {`

The invariant "no object is read before the state gate, and the default branch is unambiguous before any brief is judged" is carried by four top-level lines, each gate keyed on `MODE == check`, not by one function. U3 adds `--merge` ("as `--check`, then commit-tree and CAS", plan:213) and U3b adds `--state` (plan:207, "`state_gate`, then U2b1b's `default_gate` once main is resolved"); each must be added to both `MODE` tests and must keep `resolve_main` between them. The fact-check (r2) shows the test named for the first edge does not pin it: a mutant moving `state_gate` to just after `resolve_main` passes, because `resolve_main` falls back to the current branch when main's commit object is missing, and the test then only pins "before `main_by_name` refuses". So an edit at U3 or U3b that reorders the prelude while adding a mode would pass the suite. Honest-path maintainability, not a hostile-loop path. Minor because the order is correct today and the comment at :256 states it.

**Recommendation:** When U3 or U3b adds its mode, fold the four lines into one function (say `gate_prelude`) that every gate mode calls, and strengthen the A15 test so it fails if `state_gate` runs after `resolve_main` (for example, a planted `refs/remotes/origin/HEAD` or ref that `resolve_main` reads, rather than a missing commit that it tolerates). No change needed for U2b1b's merge.

#### 2. check_line drops status_line's POLICY field, which U2c's S rules need beside nrules

**Severity:** Informational
**Location:** `scripts/build-loop.sh:583`, `:623`; `docs/working/plan-build-loop-handoff.md:212`
**Move:** 8 (extension points)
**Confidence:** High
**Legibility-target:** the U2c implementer (S rules beside nrules).

Evidence (build-loop.sh:583, in check_line, which runs :579-628): `read -r _ _ st _ br loop sha _ <<<"$out"`
Evidence (plan:212): `` `--check BRIEF… [--expect SHA]` → D7, the N rules, and the S rules when the stricter policy is self-merge. ``

`status_line` already computes the brief's effective policy (field 4, :465: self-merge only when both settings and the brief say so), and check_line discards it. U2c's seam is otherwise ready: `nrules` is a separate function setting one `DENY`, so an S-rule function can run after it when `DENY` is empty and the policy is self-merge, and the judge loop already has the status letter (`ss`) and the brief path (from which `floor`'s full stem follows). The remaining U2c work at this seam is reading field 4, deriving the stem, and the parent-shell walk (row 517). Recorded so U2c does not re-derive the policy a second way.

**Recommendation:** At U2c, read `pol` from field 4 of status_line's line rather than recomputing it, and pass it, the stem and the status letter to the S-rule step. No change in this unit.

#### 3. Which repository a gate call runs in is a convention the code follows but no comment states; own_blob is the one function using both

**Severity:** Informational
**Location:** `scripts/build-loop.sh:536-543`; `:488-506`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** the U3 `--merge` implementer, whose commit-tree and CAS must each pick a repository.

Evidence (build-loop.sh:540, :542, own_blob's two reads and its hash; the function ends :543):
```
  n="$(git cat-file blob "$MAIN_SHA:$1" | env LC_ALL=C awk "$FENCE_AWK"'{ ... }')" || return 1
  ...
  git cat-file blob "$MAIN_SHA:$1" | N="$n" perl -pe 's/^Status: open(\r?)$/Status: done$1/ if $. == $ENV{N}' | gate_git hash-object --no-filters --stdin
```
The code's actual rule is consistent: main's committed files and every ref are read in the real repository under `harden` (the lib's readers), and every merge-result computation (merge-base, the tree checks, merge-tree, diff-tree, the blob batch-check, hash-object) runs through `gate_git`, where no repo config or attributes apply and any stderr fails. `own_blob` straddles the line by design (it reads main's blob as the lib does, then hashes as the gate does), and its errors take two different paths (real-repo `cat-file` stderr passes through; `gate_git` returns 3 on any). The gate_repo comment (:488-495) explains why merge-tree runs there but not the general rule. U3 adds `commit-tree` (an object write: naturally `gate_git`) and the CAS `update-ref` (a ref write: only the real repository has refs, and the gate repository's `refs/` is a Q-103 surface, row 509). Stating the rule once makes that choice mechanical.

**Recommendation:** At U3, add one sentence above `gate_repo`: objects the merge computes or writes go through `gate_git`; main's files and all refs, including the CAS, go through the real repository. No change in this unit.

## What Looks Good

- **Dependency direction holds:** the script consumes the lib; the lib knows the script only in comments. The new truthrule consumer is documented on both sides (lib:1077-1078, build-loop.sh:562-564), so a floor-motivated edit to truthrule's order is now visible as a cross-policy change, and T14 guards it.
- **One source for the cycle set:** `nrules` reads `truthrule`'s cycle, settings and user words; only the N-only subtree widening is spelled in the script, and plan F12 now records it.
- **`nrules` is a clean rule unit:** an `if/elif` chain of path form, mode, own brief, then cycle words, with one `DENY` result. Precedence is right (the own brief is matched before the briefs/ subtree rule that would otherwise deny it). U2c can add S rules beside it, and U3's `--approved` can select N-only by not calling them.
- **check_line's phases** (collect into index-aligned locals, batch checks, judge) are the seam row 512 asks U3 to lift into functions with values; the batch checks are already per brief, not per path.
- **`gate_repo`/`gate_git`/`merge_result`** give every merge-result object read one wrapper, one repository and one failure rule (status or any stderr), which is what made R6 and A16 fixable in one place.
- **`state_gate`/`default_gate`** share one output convention (`refuse state WHAT: WHY`, every finding printed, return 1 on any), so `--state` can call both with one handling pattern.
- **Contract item 5** now matches the run order (pathform and the mode rule before floor under both policies), and floor's own comment agrees.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Prelude order (state_gate → resolve_main → main_by_name → default_gate) is top-level sequencing U3/U3b must repeat; A15 test pins a weaker edge | Minor | `scripts/build-loop.sh:256-260`; `test/scripts/build-loop-check.bats:1588` | Medium |
| 2 | check_line drops status_line's POLICY field, which U2c's S rules need | Informational | `scripts/build-loop.sh:583` | High |
| 3 | The real-repo vs gate-repo rule is unstated; own_blob uses both; U3's commit-tree and CAS must choose | Informational | `scripts/build-loop.sh:536-543`, `:488-506` | Medium |

Rubric mapping: no Structural (🔴) or Coupling (🟡) findings; all three are 🟢 Consider. No new amber for the terminal inventory.

## Overall Assessment

The branch maintains the system's structure and improves it in places: the gate's rules are a separate unit over the lib's shared vocabulary, object reads for the merge pass through one hardened wrapper, and the state checks share one convention. Every iteration-1 and iteration-2 architecture finding is resolved or carried by a settled row whose code has not changed since. Readiness: U2c's S rules slot in beside `nrules` with one field read and the walk moved to the parent shell (row 517); U3's `--merge` reuses `merge_result`, the collect phase and `nrules`, and needs the values split of row 512 plus a stated repository rule for its CAS. The most important remaining structural concern is that the prelude order, which carries the "state gate before any object read" guarantee, is spread over top-level lines keyed on one mode, with a test that pins less than its name; it costs nothing now and should become one function when the next gate mode arrives.

## Goal-Alignment Note

- **User goal:** land U2b1b after a clean review-fix loop.
- **This review's contribution:** the terminal architecture pass over the full branch finds no 🔴 or 🟡 item; three 🟢 notes, all carry-forwards for U2c (Finding 2), U3 (Findings 1, 3) and U3b (Finding 1). None blocks the merge.
- **Threat class:** all three are honest-path maintainability; none is a hostile-loop path. R8 stays the decided Q-103 residual (row 509); Finding 3's mention of `git/refs/` is that row's surface, not a new one.
- **Agreement with the fact-check escalation:** Finding 1's test half is the same gap the fact-check escalated (r2, the A15 test name overstates its pin); this review adds the structural half (the order lives in top-level lines the next modes must repeat). Treat them as one item.
- **Drift check:** no finding asks for work outside U2b1b's scope; each names the unit where it belongs.
