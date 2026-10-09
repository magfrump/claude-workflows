Commit: 5516c6e6

# Architecture Review: feat/build-loop-u2b3a (review-fix loop iteration 1)

**Scope:** branch diff `git diff main...HEAD` (e50aab35..5516c6e6): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report.md` (Commit 5516c6e6; 0 Incorrect, 1 Stale, 3 Mostly accurate). The shared brief's matched overrides are rows 425, 431, 432, 437 and 477. Rows 431 and 477 (outside-repo starts) belong to U2b3b and are not re-flagged here.

**Scope check:** in scope. The diff touches cross-cutting concerns: the cache key of both import walks, and the parser's input model that every floor and check_fix decision depends on. It also widens the lib's caller-facing surface with new inputs `IMPORT_READER_ROOTS` and `IMPORT_READER_HOMES`, new globals `IMPORT_ROOTS`, `IMPORT_HOMES` and `IMPORT_READERS_FOR`, and the contract item 4 wording.

**Trust-boundary cross-reference:** no-op. `ls docs/reviews/security-review-*.md` matches nothing. The security reports are named `security-reviewer-review-*`, and none of them is for U2b3a.

Probes: three scripts in the scratch dir (`u2b3a-arch-probe{1,2,3}.sh`). Each starts with `set -eu`, makes its own `mktemp -d /tmp/u2b3a-arch-XXXX` and checks `pwd -P` before any `git init`, `commit` or `worktree add`. Probe 3 only reads the worktree (it runs the walks and `git worktree list`). All three ran under `timeout`, and their temp dirs were removed.

## Dependency Map

- `build-loop.sh` (check_line, then U2c's floor loop) and `dev-cycle.sh` (check_fix, `:181`) call into the lib through `truthwalk` and `isimported`. Those call `main_imports` or `imported_names`, which now call `reader_set` before their cache check (`:1000`, `:1050`). The walks then call `import_targets` in `$(...)` per file, and `import_targets` runs `IMPORT_AWK`.
- `reader_set` (`:852-879`) depends on `import_home`, on `git worktree list --porcelain -z` (live state in the common dir that all worktrees share) and on two ambient caller variables. It publishes three globals.
- `import_targets` (`:880-906`) reads those globals as a side channel. It uses them only when `IMPORT_READERS_FOR` matches this ROOT_REAL and HOME (`:884`), and otherwise falls back to a one-root model.
- Direction is sound: the lib still reads no settings file and no caller policy. The caller-supplied part of the reader model arrives as data (U2b3b's planned `Reader roots:` line will be read by a caller and passed in). The weak points are not direction but the interface's shape: inputs come in through ambient variables, the globals act as a side channel, and the projection rule makes the reader set non-monotone.

## Findings

#### F1. Longest-root projection makes the root set non-monotone, and the invariant that makes it safe is documented but unchecked

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:733-734`, `:838-841`, `:848-850`, `:856-858`
**Move:** 7 (coupling surface), 8 (extension points)
**Confidence:** High
**Legibility-target:** for-author

Everywhere else the walks are built so that more input only adds names: a superset that fails closed. Longest-root projection breaks that for roots. Adding a root nested inside another at a non-dot path renames every absolute and `~/` name below it, so the outer repo path drops out of the set:

```
k = 0; for (i = 1; i <= nr; i++) if (index(out, pre[i]) == 1 && length(out) > length(pre[i]) && length(pre[i]) > k) k = length(pre[i])
if (!k) return
```
(excerpt ends :734; the enclosing `put()` continues to :740 with the `seen`/budget lines and the print. I read it: nothing there restores the outer spelling.)

Executed (probe 1): the repo is `R` and AGENTS.md holds `@R/docs/abs.md`. Without caller roots both walks read `docs/abs.md` as `imported`. With `IMPORT_READER_ROOTS=R/docs`, which reader_set accepts as absolute, both walks read `docs/abs.md -`. Relative names survived only because of the every-root cross-product: `@docs/rel.md` stays imported through `R/docs/docs/rel.md`. The comment states the safety condition, "the honest ones nest only under .claude/ (a dot path the floor refuses whole)" (`:839-840`), and the fact-check (Claim 16) confirmed it for /workspace's 24 entries. Nothing in reader_set enforces it, though. The same gap is half of the named residual, "registering one at a path main stores, which then takes that path's names" (`:849-850`). It matters for composition because U2b3b adds roots from a settings line and U2c's floor trusts every walk as a superset. Each new root source then becomes a way to shrink the floor's import set, not just to grow it.

**Recommendation:** in reader_set, return 1 (fail the walk) when one root lies strictly below another and the path between them has no component starting with `.`. Compare lexically on the realpath forms already computed. That is a pairwise string test over about 50 entries, with no fork. The honest layouts pass: the 22 worktrees under `/workspace/.claude/`, and `/home/magfrump/cw-egress-verify`, which nests in nothing. The documented invariant becomes a checked one, the "path main stores" half of the Q-103 residual fails closed, and U2b3b's settings-line roots become safe to add. If the check is not wanted, the superset statement (`:670-676`) should name the non-monotonicity as an exception.

#### F2. The caller's reader inputs are ambient, uninitialised and outside the gate caller contract

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:851`, `:858`, `:860`, `:63-66`; `scripts/build-loop.sh:704`; `scripts/dev-cycle.sh:181`
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The lib resets its own globals when it is sourced (`IMPORT_ROOTS=""; IMPORT_HOMES=""; IMPORT_READERS_FOR=""` at `:851`, `IMPORT_OUT_MAX=4000000` at `:616`). The two new inputs are read without any default: `[[ -z "${IMPORT_READER_ROOTS:-}" ]] || mapfile -t -O "${#rs_r[@]}" rs_r <<<"$IMPORT_READER_ROOTS"` (`:858`). Any value exported in the gate's process environment therefore becomes part of the reader model. `build-loop.sh` strips only repo-local `GIT_*` variables (`callervar`, `:534-538`). By F1, an inherited root can remove names. The gate caller contract, which the header calls "the one statement of it", mentions the variables only in a parenthetical, "so HOME and IMPORT_READER_* need no reset" (`:65-66`). It does not say who sets them, from what, or that an inherited value is not allowed. There are also two walk callers: `build-loop.sh` (floor, via main) and `dev-cycle.sh` (check_fix, `truthwalk tree`, `:181`). If U2b3b's settings line is parsed by one caller and not the other, the two decisions model different readers.

**Recommendation:** either (a) add a contract item now: "IMPORT_READER_ROOTS and IMPORT_READER_HOMES are assigned (never inherited) from main's `Reader roots:` line, the same for both walk callers", and have the lib initialise both to empty when sourced, as it does its other globals; or (b) let the lib read main's `Reader roots:` line itself. It already reads main's commit (`main_entry`, `brief_fields`), so both callers would get one reader set and the variables would remain only as a test seam. Option (b) moves settings parsing into the lib. Decide it in U2b3b's plan, but make the source-time initialisation in this unit.

#### F3. import_targets runs one of two parser models, chosen by a side-channel global whose freshness key omits the caller's lists

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:880-884`, `:845-847`
**Move:** 7 (control coupling through shared state)
**Confidence:** Medium
**Legibility-target:** for-author

```
local u d toks x="" s=(-e 's/\x0/ /g') LC_ALL=C roots="${ROOT_REAL:-}" homes
import_home || return 1
homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"
[[ "$IMPORT_READERS_FOR" != "${ROOT_REAL:-}"$'\n'"$IMPORT_HOME_DONE" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```
(excerpt ends :884; the enclosing `import_targets()` continues to :906. I read it: `roots` and `homes` reach awk only through `IT_ROOTS`/`IT_HOMES` at `:904`.)

Which model the parser runs (every root or ROOT_REAL alone) depends on what an earlier, separate function call left in a global. The guard is keyed on ROOT_REAL and HOME only, so after a change to `IMPORT_READER_ROOTS` a direct call still uses the old list. The fact-check executed this (Claim 4: `/host/cw` was still kept after the variable changed to `/other`). Inside the walks this cannot misfire, because each walk calls reader_set first. But the function's behaviour now depends on call order rather than on its arguments. U2b3b will add a new kind of import_targets call for outside seeds, and any new caller will have to know this ordering rule.

**Recommendation:** have the walks pass the lists explicitly, for example `IMPORT_TARGET_ROOTS="$IMPORT_ROOTS" IMPORT_TARGET_HOMES="$IMPORT_HOMES" import_targets ...` in the two `$(...)` calls, the same way `IMPORT_LEFT` is passed. import_targets would read those, defaulting to ROOT_REAL and import_home. That removes `IMPORT_READERS_FOR` and its guard.

#### F4. A caller-supplied alias root does not compose with the nested worktree roots, so projection depends on which spelling a session uses

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:857-858`, `:733`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

reader_set lists each registered worktree under the one spelling git prints, and the caller's roots alongside them. It does not derive "worktree under an alias of ROOT_REAL" spellings: `rs_r=("$ROOT_REAL"); for p in "${rs_l[@]}"; do [[ "$p" != "worktree "* ]] || rs_r+=("${p#worktree }"); done` (`:857`). Executed (probe 2): main checkout `R`, worktree `R/.claude/wt-b`, `IMPORT_READER_ROOTS=/host/cw`. `@R/.claude/wt-b/docs/n2.md` reads as `docs/n2.md imported` in both walks. `@/host/cw/.claude/wt-b/docs/n.md` reads as `.claude/wt-b/docs/n.md imported` and `docs/n.md -`. The comment's own rule ("a session in one reads the file there as a path of that worktree", `:731-732`) maps the alias spelling to `docs/n.md` too. The floor still refuses the dot path, so this is a gap in the model, not an open hole in the floor. It lands exactly where U2b3b's host alias (Q-123: the host's checkout is `/workspace` under `/home/magfrump/claude-workflows`) meets the container's nested worktrees.

**Recommendation:** in U2b3b, when a caller root is an alias of ROOT_REAL or of the main worktree, also add each registered worktree below that worktree re-spelled under the alias. Alternatively, name the alias-spelled nested worktree as an exception in the superset statement. Record the choice in U2b3b's sub-bullet.

#### F5. The parser's output contract cannot carry U2b3b's outside-to-outside chains as built

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:713`, `:733-734`, `:907-910`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

U2b3b's sub-bullet says outside starts' "names are resolved against their own directory, and outside-to-outside chains are followed". The parser this unit leaves behind has a single output channel: names below some root, printed repo-relative. A relative name is joined to every root, `put(roots[r] "/" dirs[i] "/" c)` (`:713`), so an absolute outside directory passed as `IT_DIR` would be re-rooted. A name below no root is dropped (`if (!k) return`, `:734`). The work trailer is told apart from names by the rule "a repo-relative name never starts with /" (`:907-909`). U2b3b will have to add an absolute-base mode and an output for outside names that does not clash with the `/N` trailer. Projection and the reader set are fine where they are. This is a note for U2b3b's plan, so the extension is designed rather than patched into `put`.

**Recommendation:** in U2b3b's plan, specify the parser mode for outside seeds: an absolute `IT_DIR` that is not multiplied across roots, and a tagged output line for outside names (e.g. a leading marker distinct from `/N`). Keep in-repo projection unchanged.

#### F6. The cache-hit path now pays for reader_set, and the key follows a registry that concurrent sessions change

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1000-1003`, `:1050-1052`, `:1186-1187`
**Move:** 2 (responsibility of the caching layer)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

`reader_set || { IMPORTED_MAIN_DONE=""; IMPORTED_MAIN=error; return 1; }` runs before every key comparison. A cache hit therefore costs `git worktree list` plus one `realpath -m` fork per root. Measured (probe 3, from this worktree, 24 roots): 20 cache-hit `isimported main` calls took 696 ms, about 35 ms each, against about 1.4 ms for the `git worktree list` alone. `truthwalk` calls the walk and then `isimported`, which calls it again (`:1186-1187`), so U2c's per-path floor pays this twice per changed path. Separately, because the key now includes the live worktree registry, a worktree another session adds between two paths of one gate decision re-walks under a different root set. The result is still a superset (subject to F1), but one decision is no longer judged against one snapshot. Contract item 4 already scopes caches to a decision through import_reset. The cost belongs to the performance critic; the structural point is that the key is recomputed by the work the cache exists to save.

**Recommendation:** compute reader_set once per decision, for example in import_reset or in a `reader_set` call made by check_line next to import_reset, and key the walks on its stored result. Then one decision has one snapshot, and a cache hit is a string compare again.

#### F7. Leftover single-root input and stale comment text

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:791`, `:904`, `:667-668`
**Move:** 3 (module boundary)
**Confidence:** High
**Legibility-target:** for-author

`dirs[0] = ENVIRON["IT_DIR"]; root = ENVIRON["IT_ROOT"]; if (root == "") exit 2` (`:791`). After this diff, `root` is used only for that empty test. The parser now has two sources for the same fact, `IT_ROOT` and `roots[1]` (fact-check Claim 10 confirms they are equal). The sentence "ROOT_REAL/DIR/name for $1 and each further directory" (`:667-668`) is the Stale Claim 5. Both are leftovers of the one-root model that a later reader could take as the authority.

**Recommendation:** derive the empty-root exit from `roots[1]` and drop `IT_ROOT`, or document `IT_ROOT` as the projection-free root. Apply the fact-check's wording fix to `:667-668`.

## What Looks Good

- **One owner for the reader model.** `reader_set` is the single place that decides who reads, and both walks call it before their cache check. U2b3b's ancestor-directory seeds ("each root's ancestor directories that lie outside every root") can read the same `IMPORT_ROOTS` rather than recompute it.
- **Correct dependency direction.** The lib takes the host alias and host HOME as data and parses no settings. The policy source (main's settings line) stays with the caller or a later lib reader, which matches plan D13 and the "read from main" rule.
- **Fails closed on what it cannot model:** a relative path, a newline, `/` alone (on the real form for roots), or a failed listing. Tests 4 and 5 hold each of these on both walks.
- **The longest-root choice is sound for the honest layouts.** Fact-check Claims 16 and 17 show every nested root sits under `.claude/`, and every-root printing cost 37 times the output. The recommendation in F1 keeps this choice and turns its precondition into a checked one.
- **Fixed where row 437 asked.** The cache key holds the reader set, which removes the HOME clause from contract item 4.
- **The tests run every case on both walks** and were red on main's lib (fact-check Claim 24).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Longest-root projection makes added roots able to drop names; the nested-only-under-dot invariant is unchecked | Coupling | `scripts/lib/dev-cycle-read.sh:733-734` (also :838-841, :856-858) | High |
| F2 | IMPORT_READER_* are inherited from the environment, not initialised when the lib is sourced, and absent from the gate caller contract; two walk callers must source them identically | Coupling | `scripts/lib/dev-cycle-read.sh:851,858,860,63-66` | Medium |
| F3 | import_targets picks its model through the IMPORT_READERS_FOR side channel, whose key omits the caller lists | Minor | `scripts/lib/dev-cycle-read.sh:880-884` | Medium |
| F4 | An alias root does not re-spell nested worktrees, so projection depends on the spelling | Minor | `scripts/lib/dev-cycle-read.sh:857-858` | Medium |
| F5 | The parser's single output channel cannot carry U2b3b's outside chains | Informational | `scripts/lib/dev-cycle-read.sh:713,734,907-910` | Medium |
| F6 | A cache hit pays reader_set (~35 ms); the key follows a live registry within one decision | Informational | `scripts/lib/dev-cycle-read.sh:1000-1003,1050-1052` | Medium |
| F7 | Leftover IT_ROOT and stale "ROOT_REAL/DIR/name" text | Informational | `scripts/lib/dev-cycle-read.sh:791,904,667-668` | High |

## Overall Assessment

The unit puts the reader model in the right place: one lib function, computed before the cache check, fed caller data by value. It keeps the superset that fails closed for every input it refuses. The structural concern that matters is F1. Longest-root projection, the right call for output size, quietly makes the root set non-monotone: adding a root can remove an import. Meanwhile the safety condition ("honest roots nest only under `.claude/`") is a comment rather than a check, and U2b3b and U2c both plan to add root sources and trust the result as a superset. A cheap pairwise check in reader_set fixes this in place: it fails the walk on any root nested under a non-dot path. That check also closes half of the named Q-103 residual. F2 is the companion fix for the caller interface: initialise the inputs when the lib is sourced and state them in the contract. F3 through F7 are fixable in place or belong in U2b3b's plan; none needs restructuring.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/architecture-review-2026-10-08-u2b3a.md, structured per the architecture-review skill, with `Commit: 5516c6e6` as its first line.
- Answered: yes
- Out of scope: U2b3b's outside-repo starts and settings line (rows 431, 477), which are not re-flagged as missing; F4 and F5 are only notes on how this unit composes with them. Hostile-loop exploitability (Q-103), which belongs to security. Fork cost beyond the one measurement in F6, which belongs to performance.
- Escalate: F1's non-monotonicity bears on security's Q-103 residual wording; the security critic may want to re-rate the residual if the pairwise check is adopted. F2(b), the lib reading main's `Reader roots:` line itself, is a U2b3b design choice for the orchestrator.
- Decisions I made: I filed the alias × nested-worktree gap (F4) as Minor, not Coupling, because the floor still refuses the dot spelling. I put F1 and F2 at Coupling, not Structural: dependency direction is intact, and both fixes stay in place.
