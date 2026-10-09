Commit: 3d2d8c44

# Architecture Review: feat/build-loop-u2b3a (review-fix loop, final confirming pass)

**Scope:** full branch, `git diff main...HEAD -- scripts test` (`scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`), plus the plan's U2b3 bullet (`docs/working/plan-build-loop-handoff.md` step 5, lines 285-299) for claims only.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-final.md` (k=3, Commit 3d2d8c44: 34 Verified, 2 Mostly accurate, 0 Incorrect; two escalations); the rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md` (iterations 1-2); my iteration-2 report `architecture-review-2026-10-08-u2b3a-i2.md`. Matched overrides: rows 425, 431, 432, 437, 477 and this branch's nine rows. None is re-flagged.

**Scope check:** in scope. The branch changes the parser's output contract (every-root projection minus dotnest), adds a cross-cutting cache (the `import_readers` memo and the walk keys), adds a new input dependency to both walks (the worktree registry), and widens the lib's caller surface (contract items 4 and 9, two caller globals cleared at source).

**Trust-boundary cross-reference:** active. The most recent security review is `docs/reviews/security-review-2026-10-08-u2b3a-i2.md` (Commit: `c9197fd2`; security review predates this diff, so its boundaries may be stale). F1 sits on `B4` (instruction-file text: checkout file or main blob → parser → floor).

**Probe:** one script, `u2b3a3-arch/probe1.sh` in the session scratchpad. It starts with `set -eu`, makes its own `mktemp -d /tmp/u2b3a3-arch-XXXX` (removed by trap; `ls /tmp | grep u2b3a3-arch` printed nothing afterwards), runs each walk under `timeout 120`, and performs no git write (no `init`, `commit` or `worktree add`). It ran `imported_names` and `main_imports` read-only from this worktree and from `/workspace`.

## Iteration-2 findings against HEAD

| i2 | Status | Evidence |
|---|---|---|
| N1 (superset statement said "longest"; dotnest leans on truthrule's dot word with no cross-reference) | **Resolved.** | `dev-cycle-read.sh:686-689` names dotnest and says "truthrule's dot word must keep refusing every such path"; `put`'s comment says "narrowing it means changing this rule too"; truthrule's dot line reads `# the parser's dotnest omits only such paths: keep the two equal`; the test at `build-loop-check.bats:438-462` pins truthrule's `dot` answer for two dot-nested spellings and now runs a caller root at `sub/` (as written and through a symlink). |
| N2 (only build-loop.sh has a settings reader) | Deferred to U2b3b (override row; plan line 299 carries it). Not re-flagged. | |
| N3 (import_targets falls back to ROOT_REAL alone) | Deferred to U2b3b (override row; plan line 299). Not re-flagged. F2 below is a separate, adjacent gap. | |
| N4 (item 9 did not say when to set the lists; item 4 said "only after a reset") | **Resolved.** | Item 4 (`:65-69`): "the worktree registry is read again after a reset or when one of those changes, so set them before a decision's first walk: item 9"; item 9 (`:85-86`): "after sourcing the lib (which clears them) and before a decision's first walk". |

## Dependency Map

- **Callers (unchanged by this branch).** `build-loop.sh` sources the lib, calls `harden` so that "Every git call in this process, the lib's included, runs hardened" (`build-loop.sh:209`), and `check_line` calls `import_reset` first (`:704`). `dev-cycle.sh`'s `check_fix` calls `truthwalk tree` (`:181`). U2c's floor will call `truthwalk main` per changed path inside `check_line`.
- **Inside the lib:** `truthwalk`/`isimported` → `main_imports` / `imported_names` → `need_root` → `import_readers` (memo keyed by `import_readers_key`: ROOT_REAL, HOME's key, the two caller lists) → walk cache check (key: `IMPORT_ROOTS`, a blank line, `IMPORT_HOMES`) → `import_targets` per file → `IMPORT_AWK` (`emit` → `put` → `show`).
- **New inbound dependency:** both walks now read the worktree registry (`git worktree list --porcelain -z`, `:898`), shared mutable state outside the checkout. It is read once per decision; `import_reset` is the only invalidation point for all three caches.
- **Direction holds:** the lib takes the reader lists as data and reads no settings; the settings reader stays in `build-loop.sh` (U2b3b decides where `Reader roots:` is read; override row).
- **Two axes of "where a session reads from":** the branch generalizes *name resolution* to every reader root and home. *Start enumeration* is unchanged: `tree_starts` (`:995`) lists the starts of the checkout at ROOT_REAL only (`git ls-files -z && untracked_md`), and `main_imports` adds main's commit. F1 is about the gap between the two axes.

## Findings

#### F1. The reader model generalizes name resolution to every root but start enumeration to none, so the gate's verdict still depends on which checkout it runs from; the superset statement says "a session in any checkout is modelled", and neither the exception lists nor the plan's U2b3b bullet carries the gap

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:689-695`, `:600-614`, `:995`; `docs/working/plan-build-loop-handoff.md:293-299`
**Move:** 3 (module boundary: what the walk's contract claims to model), 2 (responsibility of the reader model)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

This finding sits on `B4` from `docs/reviews/security-review-2026-10-08-u2b3a-i2.md` (Commit: `c9197fd2`; the security review predates this diff, so the boundary may be stale). B4's source is "instruction-file text: checkout file or main blob". The finding is about *which* checkout's files are sources. The recommendation changes only text and the U2b3b plan, so no crossing moves now. If U2b3b seeds other roots' files, it widens B4's source set and should be settled in its combined review.

Evidence. The superset statement (`:689-695`):

```
# component (the parser's dotnest; truthrule's dot word must keep refusing
# every such path). A relative name is resolved against each root's copy of its
# directory, so a session in any checkout is modelled, and a ~/ name is joined
# to each reader home (this process's and IMPORT_READER_HOMES), in spelled and
# real forms. Known exceptions, where a session reading the file can import
# what these rules do not yield: a session in a checkout or under a home
# import_readers does not list (U2b3b's settings line names the host's), names
```
(excerpt; the exceptions list continues to `:698` with case-insensitive names, approved external includes and further decoding. None of them names another root's own start files.)

The start listing reads only the gate's checkout (`:995`, in full):

```
tree_starts() { local -; set -o pipefail; { git ls-files -z && untracked_md; } | instruction_names; }
```

The probe confirms the fact-check's r1 escalation (Claim 3 annotation). From this worktree, both walks give 64 names, and none is under `devcontainer-config/claude-home/`. From `/workspace`, both give 128, and 64 of them are under `devcontainer-config/claude-home/`. That directory is gitignored (`.gitignore:52`), and its `CLAUDE.md` exists only in `/workspace`'s working tree. A session working in `/workspace` loads that file as instructions when it reads files in that subtree, so it follows those 64 imports. The gate, run from its own worktree (D13), walks none of them. These names are not tracked paths today, so nothing is exposed. A branch that force-adds a file at one of them is answered "not imported" from a gate worktree and "imported" from `/workspace`.

Why this is structural rather than a typo. U2b3a's stated motive (plan line 286) is that the gate's verdict must not depend on the gate's own checkout: "today every gate walk drops an absolute `@/workspace/docs/x.md`". The branch removes that dependency along the names axis, but along the starts axis it is still there. The model now has three axes: resolution against every root (built), seeds outside every root (U2b3b), and checkout-only starts inside *another* root (owned by no unit). The superset statement is the one authoritative description (known issue A5 and plan F11 point to it). It now says "a session in any checkout is modelled", which overclaims. The exception lists do not name this case either: the parser's at `:693-698`, main_imports' "Not covered" at `:600-606`, and "Neither walk starts at an instruction file outside the repo" at `:612-614`. The last is about files outside the repo, and these files are inside a root. The plan's U2b3b bullet does not carry it either. Its seeds are files "outside every root" (`:293-295`). Its one named exception is "an ancestor checkout's working-tree instruction files, whose names the walk follows into main's blob at the same path" (`:297`). `devcontainer-config/claude-home/CLAUDE.md` is not in an ancestor directory of any gate worktree, and it has no blob on main. The "Carried from U2b3a's review" line (`:299`) lists i2 N2, N3, i1 F4, F5 and performance i2 F2, but not this.

**Recommendation:** (1) Before merge, as a text fix: change "so a session in any checkout is modelled" at `:690` to say that a session's *names* are resolved in any checkout. Add to the exceptions list: "start files that exist only in another reader root's working tree (untracked or ignored there: a gitignored CLAUDE.md under `/workspace`; U2b3b)". (2) Add one item to the U2b3b sub-bullet's carried line. Either seed every reader root's checkout-only start files: `untracked_md` per root, admitted only for roots checked out at main's commit, since a root on another branch reads its own files, not main's. Or name them as an exception with that reason. Cite this report and fact-check final Claim 3 (64 vs 128).

#### F2. import_readers does not enforce the "ROOT_REAL first" invariant its consumers state; an empty ROOT_REAL is skipped as a blank line, and the parser's exit-2 guard is defeated

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:899`, `:904-905`, `:576`, `:819-820`
**Move:** 6 (substitutability: a postcondition stated by consumers that the producer does not guarantee), 7
**Confidence:** Medium
**Legibility-target:** for-author

```
  rs_r=("$ROOT_REAL"); for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }"); done
  ...
  for p in "${rs_r[@]}" "${rs_h[@]}"; do
    [[ -n "$p" ]] || continue
```
(excerpt from `import_readers()` `:891-927`, read in full: the blank-skip meant for caller lines also drops an empty `rs_r[0]`, so `IMPORT_ROOTS` then starts with the first registered worktree.)

Two consumers state the invariant. The walk-cache comment says "keyed on import_readers's roots (ROOT_REAL first)" (`:576`). The parser says "IT_ROOTS and IT_HOMES: newline-separated, ROOT_REAL and the home of this process first" and guards `if (nr == 0 || roots[1] == "") exit 2` (`:819-820`). That guard is the parser's only "no root" refusal, and with a non-empty first registry entry it never fires. Fact-check final Claim 1 (r3, executed) showed `import_targets` then returning 0 with an empty ROOT_REAL, against its own comment. Both walks run `need_root` before `import_readers` (`:1048`, `:1098`), so no walk reaches this. But the invariant is held by the callers, not by the producer. U2b3b's outside-seed caller is the first caller other than a walk (override row "import_targets falls back to ROOT_REAL alone").

**Recommendation:** add `[[ -n "${ROOT_REAL:-}" ]] || return 1` at the top of `import_readers`. That makes the stated order a postcondition and restores the exit-2 refusal end to end. Alternatively, fold it into U2b3b's N3 decision. This is a one-line change; it need not block.

## What Looks Good

- **Dotnest is a general rule, not a layout assumption.** A root can add names and can hide only spellings that truthrule refuses as dot paths, and the two predicates now cross-reference each other with a test pinning the floor side. A misconfigured or stale root therefore fails toward more names (the property U2b3b's `Reader roots:` line relies on).
- **One invalidation point and one reader set per decision.** `import_reset` clears the walk caches and the reader memo together. The memo key is length-prefixed, and the walk keys take the computed roots and homes, so HOME and the caller lists need no reset. U2c's per-path floor loop gets a memo hit on every path after the first, and so judges one registry snapshot (test "tree w1 -").
- **The caller surface is explicit.** Item 9 defines the lists, sourcing the lib clears them, and item 4 says when the registry is re-read. The lib still reads no settings, so dependency direction holds.
- **The new git dependency inherits the gate's hardening** (`build-loop.sh:209`), and its failure fails closed (test: a `git worktree` shim exiting 1).
- **Tests run every case on both walks** and are named for what they check. The rubric records which were red on 5516c6e6. The fact-check notes that the newline-worktree test guards only against regression to main.
- **The plan's U2b3a sub-bullet is accurate as a record of what was built.** It covers `import_readers` (with its rename), the refusals, dotnest with its reason, the memo, clearing at source, and the Q-103 residual. Its carried line for U2b3b holds every routed override row. Its one omission is F1.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Names are resolved against every root but starts come from the gate's checkout only: from a gate worktree the walks give 64 of /workspace's 128 names. The superset statement says "a session in any checkout is modelled"; no exception list and no plan item carries this | Minor | `scripts/lib/dev-cycle-read.sh:690` (also `:693-698`, `:600-614`, `:995`; plan `:293-299`) | High |
| F2 | import_readers drops an empty ROOT_REAL as a blank line, so "ROOT_REAL first" (`:576`, `:819`) and the parser's exit 2 hold only because callers run need_root first | Informational | `scripts/lib/dev-cycle-read.sh:905` | Medium |

## Overall Assessment

The branch improves the structure. It replaces the parser's single-root, single-home model with an explicit reader set that has one producer (`import_readers`), one invalidation point, and one documented caller interface. Its projection rule fails toward more names except for paths the floor refuses anyway. No Structural or Coupling finding remains, and both iteration-2 text findings (N1, N4) are resolved. The model is sound for U2c: one reader set per decision, with the floor loop on memo hits. It is also sound for U2b3b on the names axis: the settings line only has to fill two lists the lib already validates, keys on and clears at source. The most important remaining concern is F1. The model covers where a session resolves names but not where it finds starts, so the gate's verdict still varies with the checkout it runs from, as the fact-check's 64-vs-128 measurement shows. The lib's one authoritative statement now overclaims, and the plan hands this case to no unit. Both fixes are text: one sentence and one exception in the lib, and one item on U2b3b's carried line. Nothing needs restructuring.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/architecture-review-2026-10-08-u2b3a-final.md, structured per the architecture-review skill, with `Commit: 3d2d8c44` as its first line.
- Answered: yes. The reader model is sound as built for U2c (one reader set per decision) and for U2b3b's settings line on the names axis. The plan's U2b3 bullet is an accurate record of U2b3a but an incomplete hand-off on one item: the fact-check's 64-vs-128 observation (F1).
- Out of scope: the override rows listed in the brief (deferred to U2b3b/U2c, Won't-Fix, Accepted-immutable); exploitability of the force-added-file case under Q-103 (security's); the comment figures (fact-check Claim 2, performance's).
- Escalate: F1. Land the `:690` rewording and the exception before merge if the loop accepts text fixes at this pass. Either way, add the per-root checkout-only starts to U2b3b's carried line, as a seed (only for roots checked out at main) or as a named exception. F2 can ride with fact-check Claim 1's escalation: one guard in `import_readers`, or a note in U2b3b's N3 decision.
- Decisions I made: I rated F1 Minor, not Coupling. It is not a regression (main never walked another checkout's starts), nothing tracked is exposed today, and the fix is text. It needs fixing because the lib's single statement of the superset now claims more than the code does, the same class as i2's B1. I rated F2 Informational because no walk reaches it.
