Commit: 7f295cdb

# Architecture Review — feat/build-loop-u2a2 (iteration 2, first critic pass)

**Scope:** full branch, `git diff main...HEAD` (main 20347279, HEAD 7f295cdb). Code: `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, plus the tests and plan/known-issues/questions/override-log docs. The added `docs/reviews/*-build-loop-u2a*.md` files are prior-loop history, read for context only.
**Date:** 2026-10-06
**Based on:** `/home/node/.claude/jobs/814a541d/tmp/rv/fc-summary.md` (Stage-1 summary of `docs/reviews/code-fact-check-report-build-loop-u2a2.md` and `-i2.md`); U2a3's floor shape read from `feat/build-loop-u2a2-full` commit 6c41aea2 (context only); plan `docs/working/plan-build-loop-handoff.md` step 5.

**Scope check:** in scope. The diff adds public lib functions (`main_imports`, `isimported`, `import_targets`, `instruction_names`, `untracked_md`, `inrepo_here`), new globals that are part of the lib's contract (`IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`, `UNI_SPACES`), and changes a cross-cutting caller contract: `check_fix` now asks the walk through `isimported tree` rather than reading the cache. All in-scope files reviewed; test and doc files reviewed only for what they say about the structure.

**Trust-boundary cross-reference:** active. The most recent file matching `docs/reviews/security-review-*.md` by date is `docs/reviews/security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73`). Its `B2` is "instruction files → imported_names() walk → IMPORTED refusal set". That review predates this diff, so the boundary may be stale. The U2a security review (`docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a.md`) does not match the glob, but it labels the gate-side boundaries that U2a2 carries: `B2` (main's committed instruction files → main_imports → IMPORTED_MAIN refusal set) and `B3` (the checkout's untracked .md files → extra walk start set). Findings 1 and 2 below sit on those boundaries.

## Dependency Map

- `scripts/dev-cycle.sh` (the cycle CLI) sources `scripts/lib/dev-cycle-read.sh` and now depends only on the predicate `isimported tree PATH` (dev-cycle.sh:181). It no longer runs `imported_names` itself or reads `$IMPORTED`. That is the dependency direction the U0 amendment asked for (plan:192, "adds an `isimported` predicate so neither caller reads the walk's cache format").
- Inside the lib, the two walks are now peers that share three leaf helpers:
  - `import_targets DIR < text`: the token grammar plus path resolution. Both walks use it.
  - `untracked_md`: the checkout's untracked and ignored `.md` list. Both walks use it.
  - `instruction_names`: a grep prefilter. Only the tree walk uses it.
  - `imported_names` (the tree walk, which reads the working tree) depends on `inrepo_here` and `lower`.
  - `main_imports` (the main walk, which reads `MAIN_SHA` plus the checkout) depends on `main_by_name`, a prior `resolve_main`, `git ls-tree`/`cat-file`, `inrepo_here`, `blocker`, `INSTRUCTION_FILE` and `lower`.
- `isimported` is the single dispatch over both walks (lib:594-603). Its unknown-name arm fails closed.
- Downstream (not in this unit): U2a3's `floor` (6c41aea2, lib:617-630) calls `elif ! main_imports` to word a walk failure, then `elif isimported main "$lp"`. U2c's `--check` calls `floor` per changed path and prints `FLOOR_WHY`. U2b chooses the checkout `--check` runs from. Dependencies point from the volatile CLIs (`dev-cycle.sh`, later `build-loop.sh`) toward the stable lib. The lib depends on nothing in either script. No cycle is introduced.

## Findings

#### 1. The main walk's fail-closed contract depends on errexit, which its only entry points switch off

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:561`, `:549`, `:599`; consumer `6c41aea2:scripts/lib/dev-cycle-read.sh:624`
**Move:** 3 (module boundary / caller contract), 7 (coupling surface)
**Confidence:** High (mechanism executed). Practical exposure is low; see below.
**Legibility-target:** the lib's caller contract (header :12-27) and the main walk's doc comment (:516-526)

Evidence:

```
522: # file (a symlink, or under one) or a plain directory, so a caller refuses
523: # rather than reading a partial list.
561:       if inrepo_here "$f"; then out="$(import_targets "$d" < "$f")"
599:     main) main_imports || return 0; [[ "$IMPORTED_MAIN" == *$'\n'"$lp"$'\n'* ]] ;;
```
```
6c41aea2 lib:624:   elif ! main_imports; then FLOOR_WHY="the default branch's instruction files could not be walked ..."
```

`main_imports` promises callers that it never returns a partial list. It keeps that promise in two different ways:

- **Explicit checks:** the `rc=0` sentinels, `|| { IMPORTED_MAIN=error; return 1; }` at :567 and :572, and the shape tests.
- **Implicit errexit:** at :561, nothing checks whether a checkout file (an untracked start, or a target main lacks) could be read. The lib relies on `set -e` to stop the script there.

Both of the walk's documented entry points switch errexit off for the whole walk:

- `isimported main` calls `main_imports || ...`. A function body run on the left of `||` ignores `set -e`.
- U2a3's floor calls `elif ! main_imports`.

So the implicit check never fires in production use. I ran this in a scratch repo: main's commit has `AGENTS.md`, and the checkout has an untracked `agents.local.md` containing `@docs/x.md`, mode 000. The results:

- Under `if main_imports`, the shell prints "Permission denied", then `walk: ok`, and `isimported main docs/x.md` answers `-`.
- A plain `main_imports` call exits 1.

This is fact-check E2. Line 549 has the same shape: if `tr` fails inside the process substitution, `low` comes back short, and candidates are dropped without a failure.

The structural cost is that the walk's safety now depends on the caller's errexit state, which no caller can restore. Every later edit to `main_imports` must remember that any command left unchecked fails open under `floor`. That trap is easy to miss, because the lib header (:18-27) teaches the opposite habit for `check_brief` and friends ("read it as `out="$(check_brief ...)"` under set -e ... `if out=...` would carry on").

The exposure today is narrow. A same-uid gate rarely meets an unreadable checkout file, and a file the gate cannot read is probably unreadable to the session too. The cost is in future changes, not today's behaviour.

**Security implication:** none from the recommendation. It makes the walk fail closed at `B2`/`B3` (from `docs/reviews/security-reviewer-review-2026-10-06-build-loop-u2a.md`, which does not match the glob; the glob-matching `B2` is from `docs/reviews/security-review-2026-10-02-digest-pass38.md`, Commit: `90364c73` — that security review predates this diff, so the boundary may be stale). It moves no crossing.

**Recommendation:** Make every failure in `main_imports` explicit, so the walk does not depend on errexit:
- at :561, `out="$(import_targets "$d" < "$f")" || { IMPORTED_MAIN=error; return 1; }`;
- after :549, check that `${#low[@]} -eq ${#cand[@]}`.

Then state in the doc comment at :516-526 that the walk's result does not depend on the caller's `set -e`, because it always runs under `||`/`if`. Add one test in `build-loop-check.bats`: an unreadable untracked start should give "walk: failed".

#### 2. The gate walk's checkout dependency is wider than the plan's U2b hand-off names

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:457-462`, `:531-532`, `:560-564`; `docs/working/plan-build-loop-handoff.md:277`, `:126`
**Move:** 1 (dependency direction), 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** plan step 5's U2b bullet and F11 row

Evidence:

```
457: # a symlink there is followed to the path its text names. A target main does
458: # not have is read from the checkout when it is a plain file there. ...
531:   [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
563:       elif [[ -e "$f" || -L "$f" ]]; then IMPORTED_MAIN=error; return 1
```
```
plan:277: ... It names the checkout `--check` runs from (the walk's untracked starts). ...
```

The walk's result depends on three kinds of checkout state, not one:

1. the untracked and ignored start files;
2. the content of any imported target that main lacks, which the checkout supplies;
3. since 7f295cdb, whether any checkout path the walk would read is a symlink or lies under one. Any such path fails the whole walk, so `floor` refuses every path.

The cache key is `$MAIN_SHA $ROOT_REAL`. It does not cover checkout state, which is fine within one `--check` process.

For the consumer this means the gate's verdict changes with the checkout `--check` is run from. The plan routes the orchestrator's shell outside any checkout (plan:98, D13), so U2b has to pick one. The choice gives different results:

- A branch worktree supplies the branch's own versions of targets main lacks. These can only add imports.
- A branch worktree that turns such a target into a symlink makes `floor` refuse everything. This fails closed, but it blocks that branch's self-merge for a reason that `FLOOR_WHY` words as "could not be walked".
- A clean main worktree lacks `CLAUDE.local.md`.

The settled `feat/build-loop-u2a` override row (security iteration 2 F4 / architecture finding 7, Defer) covers item 1. Its revisit trigger, "U2b's --check names the checkout it runs from", has not fired. I am not re-filing that row. This finding notes only that items 2 and 3 widen what U2b must name, and the plan's U2b bullet still lists only "the walk's untracked starts".

**Recommendation:** Widen plan step 5's U2b bullet (and F11) to "the checkout `--check` runs from supplies the walk's untracked starts, the targets main lacks, and the plain-file check on each". When U2b lands, record which checkout it chose against this list.

#### 3. The lib header's caller contract omits the main walk's `resolve_main` precondition and the unguarded `inrepo_here`

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:14-23`, `:123-125`, `:533`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** lib header :12-34

Evidence:

```
20: # blocked input in SKIPPED and SKIP_AT. The caller runs resolve_main once per
21: # process (a second call re-reads main); check_brief, check_branch and
22: # check_answer skip every argument unless it returned 0 with main found by name
124: # inrepo for a caller that has run need_root itself (a walk, per path).
125: inrepo_here() { [[ -z "$(blocker "$1" file)" && -f "$1" ]]; }
533:   main_by_name || return 1
```

The header lists the functions that need `resolve_main` to have succeeded by name, and `main_imports`/`isimported main` are not among them. In fact both need it (:533).

The failure mode is safe: the walk fails, so `isimported main` answers "imported" for every path. But it is misdiagnosed. A caller that forgets `resolve_main` gets U2a3's `FLOOR_WHY` "the default branch's instruction files could not be walked", not a precondition error. U2c is the first new caller and will meet this first.

`inrepo_here` is a new lib-level name with no guard of its own, and the header does not mention it. It is safe while `ROOT_REAL` is unset, because `blocker` then reads nothing as plain. But it is the one file check in the lib that skips the `need_root` cwd check, so a helper meant only for the walks has become public surface. This is the row-214 pattern (unguarded helper after `need_root`), which was accepted. Only the documentation is missing.

**Recommendation:** Add `main_imports` and `isimported main` to the header's `resolve_main` sentence (line 21-23). Add a clause naming `inrepo_here` as the walks' per-path form, which callers outside the walks should not use. These are two header lines, and they do not reflow the paragraph that the row-319 override row covers.

#### 4. `import_targets` changed the tree walk's grammar along with the main walk's (intended, worth stating)

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:478-491`, `:509-513`
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** commit body / known-issues C-rows

Evidence:

```
-      [[ "$p" != ..* ]] || continue
+    [[ "$p" != .. && "$p" != ../* ]] || continue
+    for u in "${UNI_SPACES[@]}"; do t="${t%%"$u"*}"; done
```

Sharing one parser is the right structural move, because one grammar means the walks cannot drift on tokens. It also means that every grammar fix for the gate now changes `--check-fix` as well:

- UTF-8 spaces end a token in both walks;
- `..x` names are followed in both;
- `grep -a` reads NUL-holding text in both.

Each of these changes moves the tree walk toward refusing more, which is the safe direction for `check_fix`. But nothing records that the parser is now a shared contract with two consumers whose policies differ (the tree walk is lenient by design, A2/A3; the main walk fails closed). Only the walks' start rules are recorded as differing on purpose (override row, `feat/build-loop-u2a`, architecture iteration 2 finding 2). Nothing records that the token grammar is meant to be identical.

**Recommendation:** Add one line above `import_targets` saying that both walks share it, so a change to it changes `--check-fix` too. No code change.

## What Looks Good

- **`isimported` as the only read path.** `check_fix` no longer reads `$IMPORTED` (dev-cycle.sh:181), and U2a3's floor reads no sentinel (6c41aea2:624-625). This resolves U2a architecture finding 1's sentinel coupling. The unknown-walk arm now fails closed (`*) return 0`), where U2a's default walk was the tree walk.
- **The split is at a real seam.** U2a2 delivers a walk plus a predicate and no policy. Floor, `ownfile` and `GATE_CODE` live in U2a3, and they consume only `main_imports`' return value and `isimported main`. The 6c41aea2 shape confirms that floor needs nothing else from the walk. This matches plan step 5's U2a2/U2a3 bullets.
- **One parser, one untracked listing.** `import_targets` and `untracked_md` remove the duplicated grammar that U2a architecture finding 2 flagged. The start-set rule still differs between the walks, on purpose, per the settled row.
- **The listing contract is fixed in code.** The `cmd && printf rc=0 || printf rc=1` sentinel plus `mapfile -d ''` makes "listed whole" an explicit check, not an inference from errexit. This is the model that finding 1 asks the rest of the walk to follow.
- **A two-source queue with explicit items.** The `m:`/`t:` queue items make the commit/checkout source of each read visible at the one place it matters.
- **Cache key.** It is keyed on `MAIN_SHA` and `ROOT_REAL`, so a second `resolve_main` to a new commit recomputes, and a failed walk is cached as a failure rather than retried into a partial state.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Main walk's fail-closed contract relies on errexit, which `isimported main` (`\|\|`) and floor (`elif !`) switch off; an unreadable checkout file drops imports with "walk: ok" | Coupling | `scripts/lib/dev-cycle-read.sh:561`, `:549`, `:599` | High |
| 2 | Checkout dependency (untracked starts + targets main lacks + checkout-symlink failure) is wider than plan's U2b bullet names | Informational | `scripts/lib/dev-cycle-read.sh:457-462`; `docs/working/plan-build-loop-handoff.md:277` | Medium |
| 3 | Lib header omits `main_imports`/`isimported main`'s `resolve_main` precondition and the unguarded `inrepo_here` | Minor | `scripts/lib/dev-cycle-read.sh:14-23`, `:125` | High |
| 4 | Shared `import_targets` makes gate grammar fixes change `--check-fix` too; unstated | Informational | `scripts/lib/dev-cycle-read.sh:478-491` | High |

Rubric mapping: 1 → 🟡 Must Address; 2, 3, 4 → 🟢 Consider.

## Overall Assessment

The change improves the lib's structure:

- callers reach the walks only through one predicate;
- the walks share their grammar and untracked listing;
- the commit-reading walk sits under the floor U2a3 will add, without pulling any policy into this unit.

Dependency direction is correct, and there is no cycle. The most important structural concern is finding 1. The main walk is documented as never returning a partial list, but part of that guarantee rests on `set -e`, and both of its real entry points (`isimported`'s `||` and floor's `elif !`) switch errexit off for the whole walk. A local fix (two explicit checks and a comment) puts the guarantee in the module, where it does not depend on its callers. Findings 2 and 3 are hand-off notes for U2b and U2c: which checkout state the gate reads, and the `resolve_main` precondition. No restructuring is needed.

## Goal-Alignment Note

- **Success criterion (verbatim):** "a markdown report saved at the path given in your tail, structured per your skill, with `Commit: 7f295cdb` as its first line."
- **Answered:** an architecture review of `git diff main...HEAD` at 7f295cdb covering:
  - the two walks sharing `import_targets`/`instruction_names`/`untracked_md`;
  - `isimported` as the dispatch;
  - the lib's caller contract (findings 1, 3);
  - how U2a3's floor and U2b/U2c's `--check` consume the walk (findings 1, 2; What Looks Good).
- **Out of scope:** behavioural correctness of individual shapes (fact-check's domain); the settled rows (A5 gaps, start-file rule in both walks, walk-name asymmetry, per-blob cat-file cost, untracked-start checkout row). None of these was re-filed. Finding 2 cites the untracked-start row and does not claim its trigger fired.
- **Escalate:** none. Finding 1 is fixable in place within this unit.
- **Questions / Decisions:** none.
