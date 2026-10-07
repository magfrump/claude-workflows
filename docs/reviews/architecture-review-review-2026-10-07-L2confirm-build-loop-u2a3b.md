Commit: 4828727d

# Architecture Review: feat/build-loop-u2a3b (loop 2, user-granted confirming pass, full unit)

**Scope:** `git diff main...4828727d -- . ':!docs/reviews'`, looking hardest at aa379ee9 (the code) and 4828727d (the U2b bullet's Q-121 sentence). Read whole: `IMPORT_AWK`, `UTF8_WELL_FORMED`, `import_home`, `import_targets`, `tree_starts`, `imported_names`, `main_imports` and `isimported` (`scripts/lib/dev-cycle-read.sh:446-800`), check_fix's two import arms (`scripts/dev-cycle.sh:181-184`), the SKILL.md and help-text wording, known issues A3 and A5, plan F11 (`:126`) and plan step 5's U2a3c, U2a4 and U2b bullets (`:277-279`), the override-log rows for U2a3b, and the rubric's loop-2 iteration-3 rows.
**Date:** 2026-10-07
**Based on:** the Stage 1 summary (`u2a3b-L2confirm-stage1.md`: three replicates, no behavioural Incorrect, 149/149, the named mutants fail, `--check-fix` identical to main over 957 paths). I used it as fact and did not re-verify it. Prior work: my L2-final report (`architecture-review-review-2026-10-07-L2final-build-loop-u2a3b.md`, findings 1-5) and the rubric rows L2-F-A1, L2-F-A2, L2-F-C5, L2-F-C7, L2-F-C8, L2-F-C11 and L2-F-C14.

Scope check: in scope. The unit changes a contract that two walks and two later units consume (the superset statement), and it adds an environment seam (`IT_*`, `import_home`). aa379ee9 changes three things in it: the work bound's unit, the `.git` rule and the home cache key. 4828727d widens the routed reader model.

## Dependency Map

- **Callers.** `check_fix` → `imported_names` (under `elif !`, which gives a failed walk its own wording) → `isimported tree`. Floor (U2a4, not built) → `main_imports` → `isimported main`. No other script calls into the import walks (grep over `scripts/`).
- **Walk internals.** Each walk → `import_home` (once, before its loop) → per file: `import_targets "$d"` with `IMPORT_LEFT` scoped to the call. The parser calls `import_home` again, which hits the cache. Then `env sed` (blanks) → [only for text failing `UTF8_WELL_FORMED`] `python3 -I` U+FFFD copy → `env IT_DIR IT_ROOT IT_HOME IT_HOME_REAL IT_LEFT awk "$IMPORT_AWK"`.
- **Ownership.** The parser owns names: scan, splice, `emit` (trim, `~/`), `put` (absolute, lexical `..`, one `pre`), and the per-file work bound and `tried` set. The walks own everything else: starts, content source (a `head -c 4194305` cap in the tree walk, uncapped `git cat-file` in the main walk), the top-level `.git` skip and checkout-shape fail rule (main walk only), the `used` versus `IMPORT_OUT_MAX` budget (both walks) and their caches.
- **Direction.** Dependencies still point one way: callers → walks → `import_home` and the parser → POSIX tools and python3. aa379ee9 adds no edge. `tried` and the `put` charge are parser-internal. The `.git` change is walk-internal. The `import_home` rekey is internal to `import_home`.
- **Routed.** U2a3c: phase 2, one capped reader, one drain loop, no third resolver, the `blocker` memo. U2b: the three-part reader model plus Q-121's host reader. U2a4: the floor, plus the one start predicate (recorded in F11 only; see finding 3).

## Prior findings: disposition check (L2-final, commit e1654266)

| L2-final finding | Rubric disposition | Holds at 4828727d? |
|---|---|---|
| 1 (Coupling): E1 and r3 are reader-model axes; U2b routed only projection | L2-F-A1 and A2: U2b bullet rewritten in three parts; A5, both walk headers (lib `:484-486`) and F11 name the outside-repo starts; two override rows | **Yes.** The bullet has (a) loads (including parent `CLAUDE.md`, user memory, managed policy and `CLAUDE_CONFIG_DIR`), (b) resolution directory, (c) root set with longest-root projection, and the parent-working-tree "name or bar" clause (my mitigation 3). The superset statement (lib `:526-527`) names the relative re-entry case. 4828727d's Q-121 sentence has a modelling gap; see finding 1. |
| 2 (Minor): single `pre` misprojects into nested worktrees | L2-F-A2, part (c) | **Yes, as a routing** ("project a name under the longest matching root, since worktrees nest inside the main checkout"). The nested-root test is left for U2b, which is acceptable. |
| 3 (Minor): the parser reads ambient state; empty HOME is Bun's | L2-F-C5, L2-F-C8 | **Mostly.** `import_targets`' comment (`:504-506`) now names ROOT_REAL, HOME (through import_home) and IMPORT_LEFT as inputs. The U2b bullet says "The parser takes the home from its caller then, not from its own import_home call". The import_home comment says Bun. Not done: the superset's revisit trigger (`:537`) still names only "its import grammar", not the runtime's `homedir` reading. See finding 4. |
| 4 (Minor): four stale restatements | L2-F-C7 | **Yes.** A3 no longer claims absolute imports print ok. F11 and the main walk header say "one shape". Both walk headers now say "import_home or the parser (its comment lists why) fails", which points instead of enumerating. |
| 5 (Info): one start predicate belongs to U2a4 | L2-F-C14: recorded in plan F11 | **Partly.** F11 says it, but the U2a4 bullet (`:278`), which U2a4's builder reads as its brief, does not. See finding 3. |

## Findings

#### 1. Q-121's host reader is most likely the same working tree as `/workspace` under another path, not "that checkout". Part (c)'s `git worktree list` cannot produce its spelling.

**Severity:** Minor
**Location:** `docs/working/plan-build-loop-handoff.md:279` (U2b bullet, added by 4828727d)
**Move:** 3 (the reader model the floor inherits), 7 (what a later unit must derive)
**Confidence:** Medium. The identity is inferred from evidence in the container. I cannot see the host.
**Legibility-target:** for-author (of U2b's plan)
**Executed vs reasoned:** executed for the evidence (git worktree metadata, the cc-isolated script); the consequence is reasoned.

The U2b bullet's existing part (c) names the root set's source:

> (c) which absolute and `~/` paths count as repo paths and which repo path each maps to (every `git worktree list` path, the sessions' HOME; …)

4828727d's sentence then adds:

> The reader set includes the host: … the user runs one on the host in `~/claude-workflows` under the host HOME (Q-121, answered 2026-10-07), so that checkout and that HOME's instruction files are readers too, or a named exception.

Two pieces of evidence suggest `~/claude-workflows` is the same repository and working tree that the container mounts at `/workspace`:

- `devcontainer-config/cc-isolated.sh:240` says "cc-isolated mounts a repo at /workspace".
- `git worktree list` in `/workspace` lists `/home/magfrump/cw-egress-verify … prunable`. `/workspace/.git/worktrees/cw-egress-verify/gitdir` holds `/home/magfrump/cw-egress-verify/.git`, and its `commondir` holds `../..`. A worktree created on the host can register in `/workspace/.git` only if the host's repository is this `.git`. `/home/magfrump` does not exist in the container.

If that holds, the host session is not another checkout with its own files. It reads the main checkout's working tree under a second spelling: `/home/magfrump/claude-workflows` aliases `ROOT_REAL=/workspace`. Three consequences follow for U2b:

- **(c) projection.** An absolute name `/home/magfrump/claude-workflows/docs/x.md` in a file on main is a real import for a host session. The parser drops it, because it does not lie under `/workspace`. `git worktree list` in the container shows the main worktree as `/workspace`, never as its host spelling. So "every `git worktree list` path" yields host spellings only for worktrees created on the host, not for the main checkout. The alias has to come from configuration, for example the mount source cc-isolated already knows.
- **(a) starts.** The host HOME's `~/.claude/CLAUDE.md` is not the container's root-owned, bless-gated payload symlink (`/opt/claude-workflows/CLAUDE.md`). My L2-final mitigation 1 therefore does not hold for host sessions, and that start's content is unknown to any walk.
- **The parent-memory clause.** The bullet's "the main checkout's working tree is a parent of every worktree here" is false for host-created worktrees such as `/home/magfrump/cw-egress-verify`. Stage 1 S5 makes the same point.

None of this reaches the parser. A root set with longest-match projection in `put` already handles an alias root, because two roots map to the same repo path. The issue is how U2b would *derive* the set. "That checkout" invites U2b to look for a second clone. The real work is a path alias plus a different HOME.

**Recommendation:** When the bullet is next edited (no new commit is needed for merge), reword the Q-121 sentence along these lines: "the host session reads this same working tree under the host path (cc-isolated bind-mounts it at /workspace; host-created worktrees appear in `git worktree list` under host paths), so the root set needs the host spelling as an alias of ROOT_REAL from configuration, not from `git worktree list`, and the host HOME's memory file is a start the container cannot read". Before U2b relies on the identity, confirm it on the host (`git -C ~/claude-workflows rev-parse --git-common-dir`).

#### 2. The walk caches are keyed without the inputs the parser reads (HOME, IMPORT_OUT_MAX), and correctness rests on a caller rule. U2b's reader set will widen that gap.

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:665-666` (imported_names), `:712-713` (main_imports), `:480-483` and `:493-494` (comments), `:617-619` (import_home's own key)
**Move:** 7 (state ownership and cache coherence across a seam)
**Confidence:** High
**Legibility-target:** for-author (of U2b)
**Executed vs reasoned:** reasoned. Stage 1 S2 executed the stale-result case, with a stale `h1` result after a HOME change.

Here are the three cache keys. The walks are keyed on the root and the commit:

```
  [[ "$IMPORTED_DONE" == "$ROOT_REAL" ]] && { [[ "$IMPORTED" != error ]]; return; }
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
```

import_home is keyed on HOME:

```
  local h hr="" key="x${HOME+set}:${HOME-}"
  [[ "$IMPORT_HOME_DONE" != "$key" ]] || return 0
```

aa379ee9 made `import_home`'s cache follow its real input. The two walk caches sit above it and still omit HOME and IMPORT_OUT_MAX. The comments shift the obligation to "a caller that changes HOME", and Stage 1 S2 says the comment names only `IMPORTED_MAIN_DONE`. No caller changes HOME today: check_fix runs once per process, and U2a4 has not been built. So this is latent, not a defect. It becomes structural pressure at U2b. Once the parser takes a home set and a root set from its caller, the walk results are a function of (commit, root, reader set). A key that omits the reader set would let a gate that evaluates two reader sets reuse the first answer silently. That is a fail-open, because it reads a smaller set as the answer for a larger one.

**Recommendation:** No change in this unit. Add a clause to the U2b bullet: "the walk caches are keyed on everything the walk reads (the reader set, IMPORT_OUT_MAX), not on a caller-clears rule". If the comment is touched anyway, fix the wording Stage 1 S2 flags so it names both DONE variables.

#### 3. The one-start-predicate routing sits in the F11 coverage row, not in the U2a4 bullet that briefs U2a4.

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:126` (F11: "U2a4's shared predicate is where one start predicate belongs (U2a3b L2-final architecture F5)") against `:278` (U2a4 bullet: "`floor`, `ownfile` and `GATE_CODE` over U2a3's walk, with the shared check_fix/floor predicate (rows C1, C3, 308)")
**Move:** 2 (where a routed responsibility is recorded)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis
**Executed vs reasoned:** reasoned.

U2a3c's and U2b's carried items each sit in their own bullet, which is the brief the next unit reads. U2a4's carried item is only in the gap table. The walks' start rules still differ: the tree walk uses `INSTRUCTION_FILE` only, while the main walk adds `.claude/rules/**`. That is known issue A2, and U2b's out-of-repo starts would make a third rule. A U2a4 builder who reads only its bullet would build a check_fix/floor predicate over *edited* paths and leave the two *start* predicates in place.

**Recommendation:** Add "one start predicate for both walks (A2's `.claude/rules/`; the hook for U2b's out-of-repo starts; F11)" to the U2a4 bullet the next time the plan is edited. This is not a merge condition.

#### 4. The revisit trigger names only the grammar, but the parser now depends on two more runtime behaviours.

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:537` ("Re-check the superset when Claude Code changes its import grammar"); `:610-612` (import_home: "from HOME as Claude Code's runtime (Bun) reads it"); `:631-634` (the python3 U+FFFD equivalence "probed in the binary")
**Move:** 8 (revisit triggers as part of the contract)
**Confidence:** High
**Legibility-target:** for-author
**Executed vs reasoned:** reasoned.

The superset now depends on three Claude Code facts:

- its grammar;
- its runtime's `os.homedir()` reading of an empty or unset HOME, which is Bun's and not Node's;
- its UTF-8 replacement decoding matching python3's.

Only the first is in the trigger, the one place A5 and F11 tell a maintainer to look. A runtime swap or a Bun change to `homedir` would silently change the `~/` half without touching the grammar. This is residue from L2-final finding 3. It is documentation only.

**Recommendation:** Widen `:537`'s trigger to "changes its import grammar, its runtime's home-directory reading, or its file decoding", and make the same edit to A5's "Revisit trigger". This is not a merge condition.

### aa379ee9 specifically: does anything couple the parser to a reader model it should not own?

No. I checked each change:

- **`put`'s charge and `tried`** (`:559-563`). These are parser-internal and keyed on the resolved spelling. They add no input and no output, and they do not change the per-file contract. The charge counts against the same `work` bound as `emit` and `splice`, so the parser's one failure mode for a huge input is unchanged in kind.
- **`IT_HOMER` → `IT_HOME_REAL`.** This is a rename across the existing env seam. The seam is still the only place awk meets the shell.
- **`import_home` keyed on raw HOME** (`:617-623`). This moves the cache key to the function's actual input, which is correct ownership. It does deepen one existing coupling: the comment now pins the policy "the reader's home is this process's HOME, read as Bun reads it". That is reader-model policy, and it still lives in a function the parser calls. The coupling predates this commit (L2-final finding 3) and is routed ("The parser takes the home from its caller then"), so I do not re-raise it. The rekey does not make U2b's removal any harder, because the parser's only reference is `import_home || return 1` plus two `IT_*` reads.
- **`.git` rule** (`:772-778`, `[[ "$p" != .git ]] || continue`). This is walk-owned, and it moved toward the walk's general rule ("a checkout file main lacks fails"), away from a special case. It defers to U2a3c ("U2a3c walks them") rather than modelling phase 2 early, which keeps the U2a3c boundary intact. The nested `.git` directory now goes through the general plain-directory check. That removes one arm instead of adding one.
- **Callers.** `dev-cycle.sh` and SKILL.md describe the superset honestly ("names after an `@`, read broadly"; "refuses every path when the import walk fails"). They depend only on `imported_names` and `isimported`, not on the parser.

## What Looks Good

- **The parser stayed a leaf through the final fix commit** `[unverified — submitted as claim]` (lib `:541-604`, `:624-647`). aa379ee9's three behavioural changes landed in the layer that owns each concern: work accounting in the parser, the `.git` rule in the main walk, and the home cache in `import_home`. No change crossed a boundary.
- **Routing is now recorded where the next unit reads it** `[unverified — submitted as claim]` (plan `:277`, `:279`; A5; override rows 2026-10-07). U2b's bullet carries the whole reader model, and A5 and both walk headers name the outside-repo starts. The superset statement keeps them out of the name contract, so the contract stays a statement about names.
- **The generalization path is still local** `[unverified — submitted as claim]` (`put`'s single `pre`; `emit`'s `home`/`homereal` pair). A root set is a loop over `pre` with a longest match, and a home set is a loop in `emit`'s `~/` arm. Q-121's host alias (finding 1) needs nothing beyond that.
- **The fail-closed caller contract held** `[unverified — submitted as claim]` (`scripts/dev-cycle.sh:181-184`). The walk's failure is a first-class outcome with its own wording, and the help text and SKILL.md say so.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Q-121's host reader is most likely the same working tree as `/workspace` under a host path, not "that checkout". Part (c)'s `git worktree list` cannot yield that alias, and the host HOME's memory file is outside the payload's bless gate | Minor | plan `:279` | Medium |
| 2 | The walk caches omit HOME and IMPORT_OUT_MAX and rely on a caller-clears rule. U2b's reader set must be in the key | Minor | lib `:665`, `:712`, `:480-483` | High |
| 3 | The one-start-predicate routing is in F11, not in the U2a4 bullet | Informational | plan `:126`, `:278` | High |
| 4 | The revisit trigger names only the grammar, not the runtime's homedir reading or UTF-8 decoding | Informational | lib `:537`; A5 | High |

Rubric mapping: Structural (red): none. Coupling (amber): none. Minor and Informational (green): 1-4.

## Overall Assessment

The unit keeps its boundaries. The parser is a leaf with one name contract. The walks own starts, content, budgets and checkout shape. The callers depend only on the walks' public answer. Every L2-final architecture finding is fixed or routed, and the routing is in place: U2b's bullet holds the three-part reader model, and A5 and the walk headers name the outside-repo starts. aa379ee9 adds no new coupling. Each fix landed in the layer that owns it, and the one deepened coupling (import_home's Bun policy, called from the parser) was already routed to U2b's "home from its caller". Nothing here is Structural or Coupling, so from the architecture lens the unit is clean to merge. All four findings are plan or comment edits for later units, not merge conditions. The most important one is finding 1. If the host checkout is the same working tree under another path, U2b has to build its root set from a configured alias rather than from `git worktree list`, and its HOME analysis has to treat the host memory file as unknown content.

## Goal-Alignment Note

- **Success criterion (restated verbatim):** A markdown report saved at the output path named in your role section, structured per your skill, with a `Commit: 4828727d` line at the top.
- **Answered:**
  - Whether the unit's boundaries hold between the parser, the walks and the callers: yes (dependency map; the aa379ee9 section).
  - Whether the routing to U2a3c and U2b is coherent: yes. 4828727d's Q-121 addition belongs in U2b, and its modelling has a gap (finding 1).
  - Whether aa379ee9 couples the parser to a reader model it should not own: no new coupling. The pre-existing import_home policy is routed.
  - Whether the prior findings' dispositions hold: the table above. Findings 3 and 5 hold only in part (findings 3 and 4 here).
- **Out of scope:** the security weight of a host session's unknown `~/.claude/CLAUDE.md` (security-reviewer); the Stage 1 wording items S1, S3-S7 (fact-check and the author); the cost of the `tried` set (performance).
- **Escalate:** none. Finding 1 is for U2b's planning. If the orchestrator records anything, it should note the host-identity check (`git -C ~/claude-workflows rev-parse --git-common-dir` on the host) as a `you: terminal` item for U2b.
- **Questions I would have asked:** whether `~/claude-workflows` on the host is the directory cc-isolated mounts at `/workspace` (finding 1 assumes yes); and whether the host `~/.claude/CLAUDE.md` is the same payload as the container's.
- **Decisions I made:**
  - I rated finding 1 Minor, not Coupling, because the routing already exists and only its derivation is wrong. It changes no code in this unit.
  - I did not re-raise the import_home-in-parser coupling, because it is routed (override and plan) and aa379ee9 does not change its premise.
  - I ran no probe against the parser: aa379ee9's changes are local and Stage 1 executed them. I ran only read-only `git worktree list` and metadata reads for finding 1. I started no process and wrote no worktree file other than this report.
