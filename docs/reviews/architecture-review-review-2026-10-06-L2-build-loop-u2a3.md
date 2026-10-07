Commit: 5c57d367

# Architecture Review — feat/build-loop-u2a3 (loop 2, iteration 1, after the split)

**Scope:** `git diff main...HEAD` (base 62d366a7, HEAD 5c57d367). The structural review covers `scripts/lib/dev-cycle-read.sh` (main_imports, nul_list, isimported main, header and block comments). The plan, the A5 known issue, the tests and the review artifacts were read for context.
**Date:** 2026-10-06
**Based on:** the loop-2 i1 fact-check summary (`docs/reviews/code-fact-check-report-build-loop-u2a3-L2.md`, Commit 5c57d367). Trust boundaries come from `docs/reviews/security-reviewer-review-2026-10-06-final-build-loop-u2a3.md` (Commit: cc1aa864). That review predates this diff, so its boundaries may be stale. The skill's `security-review-*.md` glob matches only older digest reviews, so this report uses the branch's own security review instead.

**Scope check:** in scope. The diff adds a public lib function (`main_imports`), a new `isimported main` selector, a shared helper (`nul_list`, which U2a3b reuses) and module globals with a cache contract (`IMPORTED_MAIN`, `IMPORTED_MAIN_DONE`).

**Settled rows not re-filed:** two-phase walk (taken as the split), cache ignoring checkout state, errexit off inside `isimported main`, unsearchable checkout directory (Defer to U2a3c), link_target helper, no reason word on a failed walk, submodule and nested-repo starts. Finding 1 builds on the earlier architecture i3 Finding 1. That finding has no override row of its own: the split took it in, and this report says what reopens it.

**Probes:** `/tmp/u2a3-arch2-i1-Tbn1/probe.sh` (P-a to P-e) and a scratch-copy mutant at `/tmp/u2a3-arch2-i1-Tbn1/copy`. All were run under `timeout`, and no processes were left behind.

## Dependency Map

- `scripts/lib/dev-cycle-read.sh` is a leaf that `dev-cycle.sh` and `build-loop.sh` source. Nothing calls `main_imports` yet; U2a4's floor will be the first caller. The new code depends on:
  - lib primitives: `need_root`, `main_by_name`, `untracked_md`, `nul_list`, `blocker`, `lower`, `INSTRUCTION_FILE`
  - the shared parser `import_targets`
  - git plumbing: `ls-tree`, `cat-file`

  No dependency points outward, so the dependency direction is unchanged.
- After the split, `main_imports` (:546-609) has this shape:
  - **Index:** `ent` (:553-560), the paths and modes main stores.
  - **Start loop** (:561-572): it seeds `seen` and `queue` from main's start files and returns 1 on any untracked start (:569).
  - **Drain loop** (:574-608): a dispatch on `ent[$f]` (:577-597) followed by one producer of new items (:598-607).
  - **Fail sites:** the producer either enqueues a path main stores, or checks a path main lacks against main's links and gitlinks (:605) and the checkout's shape (:606), then fails or records it.
- **Checkout reads (B2):** the untracked listing (:561), the start refusal (:569), the `-L` link probe (:592) and the shape probe for a path main lacks (:606). Each leads only to `return 1`, which the fact-check confirmed. So a *successful* result is a function of main's commit (B1) alone.

## Findings

#### 1. The checks that admit checkout input sit at two separate inline sites, and U2a3c reopens the earlier start-bypass class unless they become one site

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:569`, `:601-606`
**Move:** 3 (module boundary: where B2 input is admitted), 8 (extension point for a second producer)
**Confidence:** High (code read in full; the bypass mechanism was executed in the earlier i3 review)
**Legibility-target:** U2a3c author (the phase-2 design), and the plan's U2a3c bullet

**Evidence:**
```
569:      [[ "${cand[i]:0:1}" == m ]] || return 1  # untracked: not walked until U2a3c
...
601:      [[ -z "${seen[$p]+set}" ]] || continue
602:      seen[$p]=1
603:      if [[ -n "${ent[$p]+set}" ]]; then queue+=("$p"); continue; fi
604:      # Main lacks p: under a link or gitlink main stores, or held in the checkout, fail.
605:      c="$p"; while [[ "$c" == */* ]]; do c="${c%/*}"; [[ ! "${ent[$c]:-}" =~ ^1[26]0000$ ]] || { IMPORTED_MAIN=error; return 1; }; done
606:      [[ -d "$p" && ! -L "$p" && -z "$(blocker "$p" dir)" ]] || [[ ! -e "$p" && ! -L "$p" ]] || { IMPORTED_MAIN=error; return 1; }
```
(The excerpt ends at :606. The producer loop closes at :607, the drain loop at :608 and `main_imports` at :609. All of it was read.)

The split made this unit safe in a simple way. The only producer of paths main lacks is the import loop, and it runs the parent-link and gitlink check (:605) after the `seen` test. Untracked starts never enter `seen`, because :569 fails first. That is why the i3 bypass is gone: an untracked start under a directory link main stores used to be marked `seen` and skip :605.

U2a3c has to turn both :569 and :606 from "fail" into "defer to phase 2". It then adds the checkout's starts as a second producer of paths main lacks. If phase 2 seeds `seen` with those starts the same way :570 seeds main's starts, the i3 shape comes back exactly. The example is main storing `.claude/rules -> ../docs` while the checkout has a plain `.claude/rules/x.md`, which gave walk ok and `docs/x.md -` at cc1aa864.

So "U2a3c only appends" is a property of the *result*. The *code* change has to edit both fail sites and also add a site, and the check that protects one producer is not on the other's path.

**Recommendation:** No code change in this unit. Carry this as a written constraint on U2a3c, in the plan's U2a3c bullet or as a row: every item phase 2 admits goes through one admission predicate before it is marked `seen`. That covers checkout starts, deferred paths and phase-2 imports. The predicate is :605's parent check plus :606's shape check. Also add the i3 `.claude/rules`-link probe as a U2a3c test.

#### 2. The drain loop's default arm skips: a kind of queue item it does not model is dropped silently instead of failing the walk

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:577`, `:596`
**Move:** 8 (extension point), 6 (the walk's contract that "anything not modelled fails")
**Confidence:** High (the mutant was executed: 16/16 pass)
**Legibility-target:** Implementer of this unit (a one-line change), and the U2a3c author

**Evidence:**
```
577:    case "${ent[$f]}" in
...
596:      *) continue ;;
597:    esac
```
(The case statement runs :577-597 and was read in full.)

Today every queued path is a key of `ent`, so `*)` is reached only by mode 160000, a gitlink, where skipping is correct. The queue stopped carrying a source tag at the split (the `m:`/`t:` prefixes are gone), so the dispatch now assumes that every item is something main stores.

Phase 2 will queue paths main lacks. If it reuses this loop as written, `${ent[$f]}` under the caller's `set -u` aborts the shell. If the author writes `${ent[$f]:-}` to avoid that, every checkout item lands in `*) continue`: it is never read and the walk answers ok. That fails open, the reverse of the walk's stated rule that "it refuses what it does not model, as FENCE_AWK does".

A scratch copy with `160000) continue ;; *) IMPORTED_MAIN=error; return 1 ;;` passes `build-loop-check.bats` 16/16 (`/tmp/u2a3-arch2-i1-Tbn1/copy`).

**Recommendation:** Name the gitlink arm and fail the default: one line, +1 net, which fits the cap. In U2a3c, either restore a source tag on queue items or give checkout items their own arm, so the dispatch never infers an item's source from whether it happens to be missing from `ent`.

#### 3. The checkout side is defined relative to the index, not to main's commit, so the interim neither walks nor fails a start main lacks that the checkout tracks

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:561-562` (`untracked_md` at :515); start rule :566-572
**Move:** 3 (where the B1/B2 boundary is drawn)
**Confidence:** High (executed: P-c)
**Legibility-target:** Implementer of this unit (choose between a fail-closed check now and a documented carry), and the U2a3c author (phase 2's seed set)

**Evidence:** In P-c, main holds `AGENTS.md` importing `docs/a.md`. The checkout is on branch `feat`, which tracks `sub/AGENTS.md` importing `../docs/x.md`. Main lacks both files. The result is `walk: ok`, `docs/x.md -`. This is the fact-check's P1 (Claims 7, 24); A5 lists it, while the code comment and F11 omit it.

The walk is meant to split main from the checkout. But it finds the checkout's extra files with `git ls-files --others`, and that lists only what the checkout's *index* lacks. The checkout content main lacks is really two sets together:
- (index minus main): files the checkout tracks that main does not store
- untracked files

Only the second set is enumerated. Main alone does not catch this case, and it is not a regression from before the split, so this is not a new fail-open. It does mean the split's headline, "fails closed on the checkout", holds only when the checkout's index equals MAIN_SHA's tree. That is the D13 assumption the fact-check could not confirm (Claim 16).

**Recommendation:** The one-line fix is to list `git ls-files -z --cached --others` and to tag `t:` only for paths with no `ent` entry. A start-shaped path main lacks then fails the interim walk, and phase 2's seed set is defined relative to MAIN_SHA by construction. That closes this A5 item rather than carrying it. If that fix is not taken, add the item to the lib's Not-covered list and to F11, and record in the U2a3c bullet that phase 2 enumerates against MAIN_SHA, not the index.

#### 4. While U2a3c is pending, any checkout that holds an ignored or untracked start-shaped file makes U2a4's floor refuse every path

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:569`; `untracked_md` :515 (which lists ignored files on purpose, for CLAUDE.local.md); plan U2a3c/U2a4/U2b bullets
**Move:** 1 (inputs), 7 (gate availability coupled to arbitrary checkout content)
**Confidence:** High for the mechanism (P-b executed). Medium for this repo's own checkout: the listing was read, but the walk was not run there.
**Legibility-target:** Plan owner (landing order of U2a3c and U2a4), and U2b author (which checkout `--check` runs in)

**Evidence:** In P-b, a gitignored `node_modules/pkg/AGENTS.md` gives `walk: failed`, and every path reads `imported`. A read-only `git ls-files --others` in this repo's main checkout lists `devcontainer-config/claude-home/CLAUDE.md` and many `devcontainer-config/claude-home/skills/*/SKILL.md`. Each of these is a start that :569 refuses. A clean linked worktree, such as this review's, lists none.

The behaviour fails closed, so it is safe. But it ties whether the gate is usable to two things the plan does not yet state as dependencies:
- U2a3c landing before U2a4's floor is relied on
- U2b running `--check` in a checkout with no ignored or untracked start-shaped file

Commit 2b22a082's "the gate worktree D13 creates is clean at MAIN_SHA" is the assumption carrying this, and the fact-check flags it (Claim 16). The same input will reach U2a3c's phase 2 as starts to walk, including vendored files under ignored directories, so U2a3c inherits the question of which ignored files count as starts.

**Recommendation:** State in the plan that until U2a3c lands, the floor refuses every path in a checkout holding any untracked or ignored start-shaped `.md`. Then either order U2a3c before U2a4's first use, or have U2b name a fresh worktree as the gate checkout. Route the D13 wording to the override log, as the fact-check proposes.

#### 5. What phase 2 would share: the main index, `seen` and the drain loop itself, not only the result

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:547-548` (locals), `:574-608` (drain loop)
**Move:** 2 (responsibility), 8 (extension)
**Confidence:** Medium (a design inference from the code; not built)
**Legibility-target:** U2a3c author

**Evidence:** All of the walk's state is local to `main_imports`: `ent`, `seen`, `queue`, and the running `IMPORTED_MAIN`.

Phase 2 can derive its deferred set without new state, as the keys of `seen` that `ent` lacks. But phase 2 is not a separate loop that can run after phase 1. Suppose a checkout file imports a path main stores that phase 1 never reached. That path must be read from main's blob, through the 100644 and 120000 arms (:578-595), and its own imports then go through the same producer. So phase 2 re-enters phase 1's dispatch: it is a second seeding of the same drain loop, with `seen` and `ent` shared.

Bash's dynamic scoping would let a helper called from `main_imports` see these locals. That would work, but it is an implicit coupling.

**Recommendation:** In U2a3c, structure the walk as one drain loop run over two seedings: main's starts first, then the checkout's seeds once phase 1 reaches its fixpoint. Put Finding 1's admission predicate at the phase-2 seeding and Finding 2's tagged dispatch inside the loop. Do not write a second loop that duplicates the arms. Keep the state in `main_imports`' scope rather than handing it to helpers through dynamic scoping.

## What Looks Good

- **The split puts the boundary in the right place.** Every checkout read now leads only to `return 1`, so a successful `IMPORTED_MAIN` is a function of main's commit. That is the fixpoint U2a3c can treat as a fixed prefix. The earlier i3 interleaving, where B2 input wrote into `seen` before a B1 check, is gone.
- **One sentinel carries the fail-closed state.** `IMPORTED_MAIN=error` is set before any work (:551), and `isimported main` maps a failure to "imported" (:620). Every `return 1` inside the loop resets the sentinel first; the fact-check confirmed all of them are pinned.
- **`nul_list` is a good shared primitive** for "listed whole", and U2a3b reuses it.
- **The link-text split no longer uses a here-string** (:588). The earlier i3 Finding 3 is closed.
- **The deferred set needs no new state.** It can be derived from `seen` and `ent`, so U2a3c adds behaviour without widening the module's globals.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The checks that admit checkout input are inline at two sites (:569 and :605-606). U2a3c turns both into "defer" and adds checkout starts as a second producer, which reopens the i3 start bypass unless every phase-2 item passes one admission predicate. Carry it as a written constraint. | Minor | `scripts/lib/dev-cycle-read.sh:569`, `:601-606` | High |
| 2 | The dispatch's `*) continue` skips an item it does not model. Reused by phase 2, it fails open or aborts under nounset. Fix: `160000) continue; *) fail` (mutant 16/16). | Minor | `scripts/lib/dev-cycle-read.sh:577`, `:596` | High |
| 3 | The checkout side is defined against the index (`--others`), not MAIN_SHA. A start main lacks that the checkout tracks is neither walked nor failed (P-c). Fix: list `--cached --others` minus `ent`, or document the gap and carry it to U2a3c. | Minor | `scripts/lib/dev-cycle-read.sh:561-562` | High |
| 4 | Until U2a3c, any ignored or untracked start-shaped file (vendored AGENTS.md, this repo's devcontainer-config) makes the floor refuse every path. Landing order and U2b's checkout choice are undocumented dependencies. | Informational | `scripts/lib/dev-cycle-read.sh:569`; plan U2a3c/U2a4/U2b | High (mechanism) |
| 5 | Phase 2 re-enters phase 1's dispatch and shares `ent`/`seen`. Build it as one drain loop over two seedings, not a second loop. | Informational | `scripts/lib/dev-cycle-read.sh:547-548`, `:574-608` | Medium |

Rubric mapping: all five findings are 🟢 Consider. There are no Structural or Coupling findings.

## Overall Assessment

The split leaves a sound base for U2a3c's append-only checkout phase. The B1/B2 boundary now sits where it should. Checkout reads can only fail the walk, so phase 1's successful result depends on main alone, and that settles the earlier convergence concern for this unit.

The most important concern is forward-looking (Finding 1). The checks that keep checkout input from removing an answer are inline at the one producer that exists today. U2a3c must rewrite both fail sites into deferrals and add a second producer, so the constraint that every admitted checkout item passes one predicate needs to be written down before U2a3c starts.

Two cheap changes in this unit would make the base sturdier:
- Finding 2's fail-closed default arm (+1 line).
- Finding 3's index-independent listing, which closes a documented A5 gap and defines phase 2's seed set correctly.

Finding 4 is a landing-order and U2b dependency for the plan, not a code defect. I do not disagree with the security review's boundary placement: none of these recommendations moves B1 or B2. Finding 1 consolidates the B2 admission site, and Finding 3 corrects how B2's input set is enumerated (**Security implication:** B2's input set grows to include the tracked files main lacks; the crossing point does not move).

## Goal-Alignment Note

**Success criterion (verbatim):** A markdown report saved to docs/reviews/architecture-review-review-2026-10-06-L2-build-loop-u2a3.md, structured per the architecture-review skill (Structural / Coupling / Minor / Informational).

**Answered:** Yes. The report is saved at that path with five findings, each carrying Evidence, Severity, Confidence and Legibility-target.
- **Where the boundary sits:** a successful phase 1 depends on main alone, and checkout reads can only fail it (Dependency Map, What Looks Good).
- **What state phase 2 shares:** `ent`, `seen` and the drain loop itself (Finding 5), and the deferred set is derivable.
- **What would make phase 2 unsound:** an admission check missing from the second producer (Finding 1), a skip-by-default dispatch (Finding 2), and an index-relative seed set (Finding 3).
- **Interim contract:** fail-closed in every case probed. Main alone misses nothing new, and P-c is pre-split and documented in A5.

**Out of scope:** the exploitability of P-c and P-b states in the gate's real checkout (security). Test coverage for Finding 2's arm and the unpinned :562 check (test-strategy; the fact-check routed it). Parser and sed/grep failure behaviour (fixed in U2a3b, stacked). Comment and commit wording (fact-check route).

**Escalate:**
- **Implementer:** decide Finding 2 (one line, mutant 16/16) and Finding 3 (fix the listing, or document the gap in the lib's Not-covered list and F11).
- **Plan owner:** add Finding 1's admission constraint and Finding 5's loop shape to the U2a3c bullet. Record Finding 4's landing-order and checkout dependency on U2a4 and U2b, together with the fact-check's D13 override-log candidate.
- **Process note:** one read-only `git ls-files --others` was run in /workspace's main checkout to gather Finding 4's evidence. Nothing was written there.
