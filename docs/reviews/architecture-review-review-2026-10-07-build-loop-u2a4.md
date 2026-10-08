Commit: d7cdc1ea

# Architecture Review — feat/build-loop-u2a4 (U2a4, the self-merge floor), iteration 1

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = d7cdc1ea) in /workspace/.claude/wt-build-loop-u2a4: scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, docs/working/{plan-build-loop-handoff,known-issues-dev-cycle}.md, docs/reviews/override-log.md
**Date:** 2026-10-07
**Based on:** docs/reviews/code-fact-check-report-build-loop-u2a4.md (Commit d7cdc1ea; 22 verified, 6 mostly accurate, 1 stale)

Scope check: in scope. The diff adds public lib functions (`isstart`, `prompt_dir`, `truthrule`, `truthwalk`, `ownfile`, `floor`), globals (`PROMPT_DIR`, `TRUTH_WHY`, `GATE_CODE`, `FLOOR_WHY`), widens `import_targets`' signature (extra base directories), moves check_fix's denial list into the lib, and adds a numbered caller contract (a cross-cutting caching/ordering contract). Test and doc files were read as context only.

Trust-boundary cross-reference: the most recent `docs/reviews/security-review-*.md` is `security-review-egress-zone-entries-2026-09-19.md` (Commit: 7c970bfe; an unrelated branch, predates this diff). Its map (B1-B4) covers egress profile parsing; no module boundary in this diff coincides with a labeled boundary, so no finding references it.

## Dependency Map

- `scripts/dev-cycle.sh` (CLI, volatile) sources `scripts/lib/dev-cycle-read.sh` (`READ_LIB`, :91-93) and `check_fix` now calls lib `lower`, `truthrule` and `truthwalk ... tree`. `scripts/build-loop.sh` sources the same lib (:92-94) and is where U2b/U2c will call `floor`.
- Inside the lib, the layering is: `isstart` (path predicate, built on `INSTRUCTION_FILE` and `PROMPT_DIR`) ← `truthrule` (adds dot / `writable` / settings / user / record) ← `floor` (adds `GATE_CODE`, docs/thoughts/, `ownfile`) and ← `check_fix` (adds its docs/README allowlist minus working/reviews). Separately `isstart` ← `imported_names` and `main_imports` (start selection), and `prompt_dir` (shares `PROMPT_DIR`) ← both walks → `import_targets "$d" "${xs[@]}"`. `truthwalk` → {`imported_names`, `main_imports`} → `isimported`.
- Direction is correct throughout: the lib depends on nothing in dev-cycle.sh or build-loop.sh (grep: `writable`, `isbrief`, `isclosed`, `lower`, `need_root` are all lib-defined, `scripts/lib/dev-cycle-read.sh:125`, `:194-199`, `:563`). No cycle is introduced. The only "upward" knowledge is in comments (Finding 5).

## Findings

#### 1. The floor's correctness depends on a walk cache it neither owns nor can detect as stale; item 4 is prose, not code

**Severity:** Coupling
**Location:** `scripts/lib/dev-cycle-read.sh:1011-1032` (floor), `:865` (main_imports cache), `:52-53` (contract item 4)
**Move:** 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```bash
  [[ "$IMPORTED_MAIN_DONE" == "$MAIN_SHA $MAIN_BY_NAME $ROOT_REAL" ]] && { [[ "$IMPORTED_MAIN" != error ]]; return; }
```
```
#  4. Clear IMPORTED_MAIN_DONE before each gate decision and after any checkout
#     change (rows 372, 439), and both caches when HOME, IMPORT_OUT_MAX or
#     IMPORT_WORK_MAX changes.
```
`floor` reaches the walk only through `elif truthwalk "$lp" main; then` (its last rule), so which `floor` call first triggers the walk depends on the order and content of the changed paths, and every later call in the process reuses that result through the global `IMPORTED_MAIN_DONE` key, which omits the checkout, HOME and both budgets. `floor`'s answer is therefore a function of hidden temporal state set by an earlier call (possibly an earlier gate decision), and the only protection is a caller remembering to assign a lib-internal global (`IMPORTED_MAIN_DONE=""`) by name. That is content coupling: U2b and U2c must both know the cache variable's name and the four invalidation events, and a fourth reader of the floor would need the same. This is the coupling the brief's failure class cares about (a stale walk under-reads). Fact-check Claim 16 confirms item 4's mechanism (key without checkout or HOME); the deferral to U2b in override row 466 routes the order, not this seam.

**Recommendation:** Give the gate decision an entry point in the lib (e.g. `floor_begin`, or a `gate_reset` that clears `IMPORTED_MAIN_DONE` and `IMPORTED_DONE`) so contract item 4 becomes one call U2b/U2c make, and the variable names stay lib-private. Optionally fold HOME and the two budgets into the cache key so the "when HOME changes" half needs no caller action at all.

#### 2. The prompt-base rule is split between prompt_dir and two identical call-site spellings

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:490`, `:832` (imported_names), `:894` (main_imports)
**Move:** 3 (module boundary) / 8 (extension points)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
prompt_dir() { local -n pd_m="$1"; [[ ! "$2" =~ $PROMPT_DIR ]] || pd_m[$3]="${3:0:${#BASH_REMATCH[1]}}"; }
```
and, verbatim in both walks:
```bash
    f="${queue[qi]}"; qi=$((qi + 1)); xs=(); [[ -z "${pdir[$f]+set}" ]] || xs=("${pdir[$f]}" "")
```
Passing the map by name is consistent with the lib's existing prior art (`main_checkout ENT MEMO`), and keying it on the case-kept path both walks queue is correct, so the seam itself is sound. But the rule "a prompt's names resolve against the directory holding its `.claude/` *and the top level*" lives in three places: prompt_dir computes the first base, and each walk appends `""` itself. The plan already names the next change to this rule (U2b's reader model: "a session started in any other directory", `:487-488`), which will have to edit both walks in lockstep or drift them apart, and the call sites do not know that `pdir` may already be `""` (a top-level `.claude/` yields `xs=("" "")`, a duplicate base). Fact-check Claim 20 adds that the map picks the innermost `.claude/` on a nested path, another rule U2b may revise in one place only if it is in one place.

**Recommendation:** Let the map hold the whole list of extra bases (newline- or array-encoded, deduplicated, top level included), or add a `prompt_bases MAP PATH OUTARRAY` helper both walks call, so the base-directory policy has one owner beside `PROMPT_DIR`.

#### 3. The caller contract is still stated in three places, and the copies already differ

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:42-66`; `docs/working/plan-build-loop-handoff.md:279` (U2b bullet), `:126` (F11); `docs/working/known-issues-dev-cycle.md:18` (A5); `scripts/lib/dev-cycle-read.sh:529-533`
**Move:** 3 (module boundary: where the public contract is declared)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** lib header: `# The gate caller contract, for floor and main_imports (the one statement of` / `# it; plan step 5's U2b bullet and known issue A5 point here; override row 459):`. The U2b bullet: `keeps the lib header's numbered gate caller contract (U2a4; the one statement of these duties, which the rest of this sentence predates), owing the walk four things: that checkout a clean worktree at MAIN_SHA ...`. F11: `the caller contract is in the U2b bullet`.

Placement is right: the lib header sits beside the code it governs, ships in the same file the gate runs (D6 runs main's copy), and is the one copy a future U2b/U2c author reading `floor` will see. But override row 459 was disposed as Fixed on "one numbered statement", and the plan still carries a full, older restatement that is already a different set (it lacks items 5 and 6 and the HOME/budget half of item 4; it says "four things" against seven), F11 points to the wrong copy (fact-check Claim 11, Stale), and A5 and the block above `IMPORTED=` restate subsets (Claim 9). The bullet's own disclaimer ("which the rest of this sentence predates") documents the drift instead of removing it; a U2b implementer working from the plan, which is the normal RPI entry point, reads the stale list first.

**Recommendation:** Reduce the U2b bullet's duty list and F11 to a pointer ("owes the lib header's gate caller contract, items 1-7"), keeping in the plan only what U2b must *build* (the check-attr / core.symlinks refusal), and leave A5's parenthetical as a pointer too. Then row 459's "one statement" holds literally.

#### 4. floor is a partial D5 floor: the mode rule, the own brief's Status rule and main_entry are left for each caller to compose

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:57-60` (item 5), `:1000-1010`
**Move:** 2 (responsibility boundaries) / 3
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
#  5. Ask floor about each changed path, in this shell, before pathform or
#     main_entry (so .github/x.yml is refused as a dotfile, not as badform),
#     and refuse the whole branch on any main_entry word but blob or absent
#     (rows 308, 324). Floor item 5 (symlinks, gitlinks) and the brief's own
#     Status change are the caller's rules.
```
Plan D5 defines the floor as items 1-5 (`plan-build-loop-handoff.md:69-73`); the function named `floor` implements 1-4, and D5 item 5, the own-brief exception, the floor-before-pathform order and the whole-branch main_entry refusal are an ordered composition that the contract asks each caller to reassemble. The plan names two future callers (U2b's `--check`, U2c's S rules). Splitting at the mode boundary is defensible (floor takes a path and status letter, not a mode, and the merge-tree parse that yields modes is U2b's), so this is staging, not a defect; but the name `floor` promises the whole D5 floor, and the order-sensitive part is exactly what a second caller gets wrong. Override row 466 routes this to U2b/U2c.

**Recommendation:** When U2b lands the raw diff-tree parse, add one lib function that takes (mode, status, path, stem) and applies Status → floor → mode rule → pathform/main_entry in the item-5 order, so U2c calls that rather than `floor` directly; or, now, note in floor's comment that it is "D5 items 1-4" so the name does not over-promise.

#### 5. check_fix collapses truthrule's words into a hard-coded prose list, and truthrule's comment documents check_fix's policy

**Severity:** Minor
**Location:** `scripts/dev-cycle.sh:177-179`; `scripts/lib/dev-cycle-read.sh:954-963`
**Move:** 7 (coupling) / 1 (direction of knowledge)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
  if truthrule "$lp" && [[ "$TRUTH_WHY" == cycle ]]; then echo "skip $a: one of the cycle's own files (use --check-write)"
  elif [[ -n "$TRUTH_WHY" || ! "$lp" =~ ^docs/.*\.md$|^readme\.md$ || "$lp" =~ ^docs/(working|reviews)/ ]]; then
    echo "skip $a: in-cycle fixes edit only tracked .md documentation under docs/ (not working/, human-author/, reviews/, decisions/, dev-cycle.md, constraints.md, dot-directories or dotfiles, or instruction files) and README.md; file it instead"
```
and in the lib: `# words the words and adds its own rules: check_fix allows only docs and` / `# README.md and keeps docs/thoughts/ fixable (a living doc), and floor refuses`.

The split meets the plan's ask in substance: the shared denials (instr, dot, cycle, settings, user, record) are one lib predicate, dependency direction is lib ← dev-cycle.sh, and the purposely different lists are bounded (check_fix: an allowlist of docs/*.md and README.md minus working/ and reviews/, docs/thoughts/ allowed; floor: `GATE_CODE`, docs/thoughts/, non-own working/ and reviews/), each spelled in its caller. Two residues: (a) check_fix uses only the `cycle` word and folds the other five, plus its own rules, into one sentence that re-lists truthrule's set in prose, so a new truthrule word is refused (fail-closed, good) under a message that does not name it; and the elif reads `TRUTH_WHY` left over from the `if` condition's call, an implicit out-parameter dependency. (b) The lib comment states check_fix's private policy (and omits its working/ and reviews/ refusals, fact-check Claim 1 scope), so the lib documents its caller and will go stale when check_fix changes.

**Recommendation:** Either word the five non-cycle reasons in check_fix via a `case "$TRUTH_WHY"` as floor does, or keep the prose but say "(see truthrule)" instead of re-listing; trim the lib comment to "each caller adds its own rules (check_fix in dev-cycle.sh, floor below)".

#### 6. The start rule has two spellings: isstart and instruction_names' grep, kept equal by comment and a one-off probe

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:482-483`, `:735-739`, `:763`
**Move:** 7 (coupling) / 8
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```bash
PROMPT_DIR='^(.*/)?\.claude/(commands|agents|output-styles)/'
isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }
```
```bash
instruction_names() { env LC_ALL=C grep -zaiE '(^|/)((claude|agents?|gemini)(\.[a-z0-9_-]+)?|skill)\.md$|(^|/)\.claude/(rules|commands|agents|output-styles)/.*\.md$' || [[ $? -eq 1 ]]; }
```
The plan's "one start predicate" holds for decisions (both walks and truthrule call `isstart`; main_imports' candidate loop now uses it instead of its own inline rules/ test, a real consolidation). But the tree walk only ever sees what the grep prefilter passes, so the grep is a second, independently maintained spelling of the same rule in another regex dialect, and the direction of drift that matters (isstart widened, grep not) silently under-reads in --check-fix, the brief's named failure class. The fact-check's 234,256-path probe (Claim 22) showed them equal today, but that probe is not kept; the suite's coverage is incidental (the untracked/nested `.claude/commands` fixture). The "`PROMPT_DIR`" variable is not reused by the grep, so the directory list is written twice.

**Recommendation:** Build the grep pattern from the same pieces (a `START_DIRS='rules|commands|agents|output-styles'` used by both `PROMPT_DIR`/isstart and the grep), or add a small table test asserting the prefilter passes every path `isstart` accepts over a generated set (the fact-check's p2.sh, shrunk).

#### 7. TRUTH_WHY is one global written by two functions with different vocabularies

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:964-984`, `:1016-1031`
**Move:** 5 (interface segregation)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** `truthrule` sets `TRUTH_WHY` to `instr|dot|cycle|settings|user|record` or `""`; `truthwalk` sets `TRUTH_WHY=walk` then `TRUTH_WHY=imported`. In `floor`, a caller reading `TRUTH_WHY` after a refusal sees whichever function ran last. Today both callers read it immediately after the call that set it, so nothing is wrong; the shared name just means `TRUTH_WHY`'s meaning is call-site dependent, and the `walk` word overloads both "walk failed" and "unknown WALK argument" (`*) return 0`, fail-closed, fine). `truthwalk`'s WALK parameter is a mild control flag (each caller hard-codes one value), acceptable for two values.

**Recommendation:** None required; if a third consumer appears, give truthwalk its own out-variable (e.g. `WALK_WHY`) so each function's vocabulary is closed.

#### 8. isstart is a repo-path predicate; the outside-repo starts the plan also assigned to "the one start predicate" need a different seam

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:474-483`; `docs/working/plan-build-loop-handoff.md:278`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** plan: `That predicate is also the one start predicate both walks use (...): A2's .claude/rules/, .claude/commands/*.md (...), and the outside-repo starts U2b's reader model names. Built 2026-10-07 (...) Outside-repo starts stay U2b's`. 

The deferral is recorded, and the in-repo half is done well. Note for U2b: outside-repo starts (a parent CLAUDE.md, user memory) are not paths both walks enumerate from `ls-tree`/`ls-files`, so they cannot be added to `isstart`; they will need a start *source* (a list of extra start files with their own base directories) feeding both walks' queues, which will interact with Finding 2's base-directory seam. Designing Finding 2's helper to accept externally supplied bases would make that addition local.

**Recommendation:** When U2b starts, model outside-repo starts as a second start source beside `tree_starts`/main's listing, not as an `isstart` widening; keep the plan's U2a4 line from implying the predicate will carry them.

## What Looks Good

- **Dependency direction.** The shared rule moved *down* into the lib (`truthrule`, `truthwalk`, `isstart`), dev-cycle.sh lost its inline copy of the denial list and its own `tr` call, and the lib gained no reference to its callers. This closes rows 204/322/348 the way row 322 asked ("one lib predicate that check_fix also calls"), with byte-identical --check-fix output over every tracked path (fact-check Claim 2a).
- **truthwalk owns the walk-then-ask order** (row 418) and fails closed on an unknown walk name; check_fix and floor no longer know the order.
- **Layering inside the lib** is clean: `isstart` ⊂ `truthrule` ⊂ {floor's, check_fix's} rules, with each caller's deliberate extras in that caller (floor's `GATE_CODE`/thoughts/`ownfile`; check_fix's docs allowlist), and the test "check_fix and floor share one read-as-truth rule; docs/thoughts/ differs on purpose" pins the boundary between shared and per-caller.
- **One start predicate for decisions**: `main_imports` dropped its inline `.claude/rules/*.md` test for `isstart`, and the tree walk gained rules/ by the same call, removing an existing divergence between the walks.
- **Pass-by-name map** for `prompt_dir` follows the lib's established `main_checkout ENT MEMO` convention, and `import_targets`' extra-base parameter is an additive, backward-compatible signature change (one-directory output identical to main's, Claim 25).
- **floor's interface** is narrow (path, stem, status letter → 0/1 + `FLOOR_WHY`), calls neither `pathform` nor `main_entry` (Claim 6), and leaves mode handling to the layer that has modes.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | floor depends on a walk cache it neither owns nor can detect as stale; contract item 4 is prose | Coupling | `scripts/lib/dev-cycle-read.sh:1028`, `:865`, `:52-53` | High |
| 2 | Prompt-base rule split between prompt_dir and two identical call-site spellings | Minor | `scripts/lib/dev-cycle-read.sh:490`, `:832`, `:894` | High |
| 3 | Caller contract still stated in three places, copies already differ (U2b bullet, F11, A5) | Minor | `scripts/lib/dev-cycle-read.sh:42-66`; `docs/working/plan-build-loop-handoff.md:126`, `:279` | High |
| 4 | floor implements D5 items 1-4; mode/Status/main_entry composition left to each caller | Minor | `scripts/lib/dev-cycle-read.sh:57-60`, `:1000-1010` | Medium |
| 5 | check_fix folds truthrule's words into a prose list; lib comment documents check_fix's policy | Minor | `scripts/dev-cycle.sh:177-179`; `scripts/lib/dev-cycle-read.sh:954-963` | High |
| 6 | Start rule spelled twice (isstart and the grep prefilter), equality unguarded by a test | Minor | `scripts/lib/dev-cycle-read.sh:482-483`, `:739` | High |
| 7 | TRUTH_WHY shared by truthrule and truthwalk with different vocabularies | Informational | `scripts/lib/dev-cycle-read.sh:964-984` | High |
| 8 | Outside-repo starts cannot extend isstart; U2b needs a start-source seam | Informational | `scripts/lib/dev-cycle-read.sh:474-483`; plan `:278` | Medium |

## Overall Assessment

U2a4 achieves the split the plan asked for: one shared read-as-truth predicate (`truthrule`) and one walk-order helper (`truthwalk`) in the lib, called by both check_fix and floor, with dependency direction lib ← dev-cycle.sh and no new upward or circular dependency; `isstart` is the single decision predicate for both walks and for truthrule's `instr`. The lists that differ on purpose are bounded and each lives in its caller, though check_fix still re-lists the shared set in prose (F5) and the grep prefilter is a second, unguarded spelling of the start rule (F6). Everything is fixable in place; no restructuring is indicated. The single most important structural concern is Finding 1: the floor's answer depends on a process-global walk cache keyed without the checkout, HOME or budgets, and the only invalidation is a caller assigning a lib-internal variable by name; before U2b and U2c both become callers, that duty should become one lib call. Second, the contract's "one statement" (row 459) is true of the lib header's placement but not yet of the plan, whose U2b bullet carries an older, already-divergent copy (F3).

## Goal-Alignment Note

- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. Saved at `docs/reviews/architecture-review-review-2026-10-07-build-loop-u2a4.md` with `Commit: d7cdc1ea` first; all four focus areas covered (truthrule/truthwalk/isstart split and dependency direction: F5, F6, F7, What Looks Good; prompt_dir's map-by-name seam: F2, F8; caller contract placement: F3, F4; floor-to-walk-cache coupling: F1). Each finding quotes the code or doc verbatim.
- Out of scope: correctness, security and performance of the walks (e.g. the duplicate `""` base's extra work charge is mentioned only as a seam symptom); no tests or probes were run (static review on top of the fact-check's executed results); settled override-log dispositions were not re-litigated except where F3 shows new evidence against row 459's "Fixed" (the plan copy diverges in content, not only in existence).
- Escalate: F1 is the one finding a U2b/U2c author would pay for later; whether to add a lib reset entry point now or in U2b is the orchestrator's call. F3 overlaps fact-check Claims 9 and 11 and can be fixed in the same doc edit.
- Decisions I made: rated F1 Coupling rather than Minor because two named future callers must each know a lib-internal variable and four invalidation events, and a miss under-reads; rated F4 Minor, not Coupling, because the split at the mode boundary is a deliberate, recorded staging (row 466) with no caller yet.
