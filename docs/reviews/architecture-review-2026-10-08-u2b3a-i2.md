Commit: c9197fd2

# Architecture Review: feat/build-loop-u2b3a (review-fix loop iteration 2)

**Scope:** partial, `git diff 5516c6e6..HEAD -- scripts test` (fix commits 4dba56dc and c9197fd2): `scripts/lib/dev-cycle-read.sh`, `test/scripts/build-loop-check.bats`, `test/scripts/dev-cycle.bats`. Commits up to 5516c6e6 are context only.
**Date:** 2026-10-08
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u2b3a-i2.md` (Commit c9197fd2; 0 Incorrect, 1 Stale at `:679`, 7 Mostly accurate); iteration-1 rubric `docs/reviews/code-review-rubric-2026-10-08-feat-build-loop-u2b3a.md`; my iteration-1 report `architecture-review-2026-10-08-u2b3a.md`. Matched overrides: rows 425, 431, 432, 437 and 477, plus this branch's G8, G9 (deferred to U2b3b), G11 (Won't-Fix) and G12 (Accepted-immutable). None of them is re-flagged.

**Scope check:** in scope. The fix range changes the parser's output contract (the projection rule in `put`), the reader model's caching layer (the `import_readers` memo and `import_reset`), and the lib's caller-facing surface (gate caller contract items 4 and 9, globals cleared at source time, `readers_key`).

**Trust-boundary cross-reference:** active. `docs/reviews/security-review-2026-10-08-u2b3a.md` (Commit: `5516c6e6`, iteration 1; security review predates this diff, so its boundaries may be stale) maps B1 (worktree registry → reader_set → projection), B2 (caller env IMPORT_READER_* → reader_set) and B4 (instruction text → put → printed names → floor). N1 sits on B4/B1; N2 sits on B2. Since that review, B2's source has changed from the environment to a caller assignment made after sourcing.

Probe: one script, `u2b3a2-arch/probe1.sh` in the session scratchpad. It starts with `set -eu`, makes its own `mktemp -d /tmp/u2b3a2-arch-XXXX`, checks `pwd -P` before `git init`/`commit`/`worktree add`, runs under `timeout 120`, and removes its dir through a trap (afterwards `ls /tmp | grep u2b3a2-arch` printed nothing).

## Iteration-1 findings against the fix range

| i1 | Status | Evidence |
|---|---|---|
| F1 (longest-root projection was non-monotone; the nesting invariant was unchecked) | **Resolved, and better than my suggestion.** The dotnest rule removes the non-monotonicity; it does not fail the walk. One leftover: the stale sentence at `:679` (N1). | `put` `:738-751`, BEGIN `:811-813`; fact-check Claims 11, 13, 26b; probe 1 |
| F2 (ambient, uninitialised caller inputs outside the contract) | **(a) Resolved:** cleared at source (`:873`), and contract item 9 is added. **(b) Open, routed:** which component reads the `Reader roots:` line for *both* walk callers (N2). | `:83-86`, `:873`; fact-check Claims 2, 20 |
| F3 (import_targets picks its model through a side channel with an incomplete key) | **Resolved in effect.** The key now holds the caller lists (`readers_key`). The side channel and its narrow fallback remain (N3). | `:877-880`, `:918-923`; fact-check Claim 8 |
| F4 (alias root does not re-spell nested worktrees) | Deferred to U2b3b (override row G8). Not re-flagged. | |
| F5 (single output channel) | Deferred to U2b3b (override row G9). Not re-flagged. | |
| F6 (reader set recomputed on every cache hit; key follows a live registry) | **Resolved.** Memoized until `import_reset`; one root set per decision (N4 states the condition). | `:615`, `:867-870`, `:881-888`; fact-check Claims 4, 15a; test "tree w1 -" |
| F7 (leftover IT_ROOT; stale "ROOT_REAL/DIR/name") | **Resolved.** IT_ROOT is gone, the parser exits 2 on an empty first root, and `:671` reads "ROOT/DIR/name for each reader root". | `:810`; fact-check Claim 12 |

## Dependency Map

- The callers are unchanged. `build-loop.sh` sources the lib (`:183`), calls `read_settings` once in the parent shell (`:765-773`), and then runs `check_line` per brief in a subshell; `check_line` calls `import_reset` first (`:704`). `dev-cycle.sh` runs `check_fix`, which calls `truthwalk tree` (`:181`), and needs no default branch found by name (`:186`).
- Inside the lib: `truthwalk`/`isimported` → `main_imports`/`imported_names` → `import_readers` (memo keyed by `readers_key`), then the walk cache check → `import_targets` in `$(...)` per file → `IMPORT_AWK` (`put` → `show`).
- `import_reset` is now the one invalidation point for all three caches (two walk results and the reader set). The caller lists are inputs the reset does not clear, so a caller sets them once and they survive every decision.
- The projection's hidden spellings are exactly the paths `truthrule`'s `dot` word refuses. Both use the same predicate ("some component starts with `.`"), written once in awk (`:813`) and once in bash (`:1210`). This is the one new cross-function dependency (N1).
- Direction still holds: the lib takes reader lists as data and reads no settings. The settings parser (`main_file`, `SETTINGS_AWK`, `read_settings`) lives in `build-loop.sh` (`:298`, `:322`, `:380`), which matters for U2b3b (N2).

## Findings

#### N1. The superset statement still describes longest-root projection, and the parser's one omission depends on truthrule's dot predicate with no cross-reference

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:677-680`, `:738-751`, `:811-813`, `:1210`; `test/scripts/build-loop-check.bats:1756-1768`
**Move:** 3 (module boundary: the parser's output contract), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

This finding sits on `B4` and `B1` from `docs/reviews/security-review-2026-10-08-u2b3a.md` (Commit: `5516c6e6`; security review predates this diff; boundary may be stale): the projection is where registry-derived roots decide which printed names reach the floor. The recommendation changes only wording and tests, so no crossing moves.

On the focus question: the dotnest rule is a sound general statement of the projection, and it is the better choice over my iteration-1 suggestion to refuse non-dot nesting in `import_readers`. That refusal would have failed every walk while a stale non-dot entry (`git worktree add sub; rm -rf sub`) stayed registered. The floor would then refuse every self-merge until someone pruned the entry: fail-closed, but it couples the gate's availability to registry hygiene. Dotnest prints the extra spelling instead (`sub/x.md` and `x.md`), so a non-dot nested root only adds names. It hides exactly one class of spelling: an outer root's spelling whose path down to a nested holder has a dot-led component. Probe 1 confirms this on the cases the test does not cover. A caller root at `R/sub` (non-dot) gives `sub/x.md imported` and `x.md imported` in both walks. A chain from outer to dot-nested to non-dot (`R` ⊃ `R/.claude/wt-a` ⊃ caller root `R/.claude/wt-a/sub`) gives `sub/y.md imported` and `y.md imported`, and hides only `.claude/wt-a/sub/y.md`. Fact-check Claim 26b confirms that over /workspace HEAD reproduces main's 128 names exactly.

Two things are left. First, the lib's single statement of the superset claim, which plan F11 and known issue A5 point to, still says the old rule (fact-check Claim 9, Stale):

```
# a reader root (import_readers: ROOT_REAL, every registered worktree, the
# caller's IMPORT_READER_ROOTS), and printed relative to the longest one
# holding it. A relative name is resolved against each root's copy of its
```
(excerpt `:678-680`; the sentence ends at `:680` and the exceptions list continues to `:690`, read: none of the exceptions names the dot omission.)

Second, the omission is safe only because a consumer refuses what is omitted. The parser's test is `index("/" substr(pre[j], length(pre[i]) + 1), "/.")` (`:813`), and truthrule's is `elif [[ "/$1" == */.* ]]; then TRUTH_WHY="dot"` (`:1210`). They are the same predicate in two languages. `put`'s comment says only "a dot path the floor refuses whole" (`:741`), and truthrule's comment does not mention the parser. If the dot word is ever narrowed, the parser silently stops printing names that the floor would then need, and no test would turn red. (Pathform already treats some dot paths, such as `.envrc`, differently from others, so narrowing is not hypothetical.) Override G11 covers the observable side (isimported's answer for a dot path), not this dependency.

**Recommendation:** reword `:679-680` as the fact-check suggests ("printed relative to every root holding it but an outer one whose path down to a nested holding root has a dot component"), and add the omission to the exceptions list as safe only while truthrule refuses every dot path (`:1210`). Put a one-line cross-reference in truthrule's comment. Give the "caller root inside the repo" half of test 110 the case its name promises (`T_READER_ROOTS="$r/sub"` with the stale entry pruned; fact-check Claim 21), because that row pins the property U2b3b relies on: a settings-line root can only add names.

#### N2. Contract item 9 makes each caller source the reader lists, but only build-loop.sh has a settings reader, so after U2b3b the floor and check_fix can model different readers

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:83-86`, `:43-44`; `scripts/build-loop.sh:298`, `:380`, `:765-773`; `scripts/dev-cycle.sh:181`, `:186`
**Move:** 3 (module boundary), 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

```
#  9. Set IMPORT_READER_ROOTS and IMPORT_READER_HOMES after sourcing the lib
#     (which clears them), from the default branch's settings (U2b3b), never
#     from the environment: each is newline-separated absolute paths, the host
#     spellings of this checkout and the host HOME (import_readers).
```
(`:83-86`, the item in full.)

Three things compose well. Clearing at source (`:873`) runs before `scrub_reexec`'s re-exec and again inside it, so only an assignment made after sourcing counts. `read_settings` already runs once in `build-loop.sh`'s parent shell before the `check_line` subshells (`:765-773`), and `import_reset` does not clear the lists, so a `Reader roots:` value set there reaches every decision. Because of dotnest (N1), any root that line adds can only add names, and `docs/dev-cycle.md` is itself a floor-refused path (truthrule `settings`, `:1212`), so a loop cannot self-merge a change to its own reader set.

The gap is the second walk caller. The contract is headed "for floor and main_imports" (`:43-44`). The tree walk's caller, `dev-cycle.sh`'s `check_fix` (`truthwalk tree`, `:181`), is not bound by item 9, has no settings parser (`main_file`, `SETTINGS_AWK` and `read_settings` live in `build-loop.sh`), and runs without a default branch found by name (`:186`: `resolve_main || [[ -n "$CHECK" ]]`). If U2b3b puts the `Reader roots:` parse in `read_settings`, which is the natural home, `check_fix` keeps the narrower reader set. A doc imported only through the host-alias spelling would then read `ok` for an in-cycle fix while the floor refuses it. This is the unresolved half of iteration-1 F2(b). Nothing is exposed today, since both lists are empty for both callers.

This finding sits on `B2` from `docs/reviews/security-review-2026-10-08-u2b3a.md` (Commit: `5516c6e6`; security review predates this diff; boundary may be stale).

**Recommendation:** decide this in U2b3b's plan and record it in item 9. Either (a) move the `Reader roots:` read into the lib, which already reads main's blobs through `main_entry`, so both walks get one reader set and the variables stay as a test seam; or (b) keep it in `read_settings` and give `check_fix` a stated rule: main's line when `main_by_name` succeeds, otherwise the tree's own `docs/dev-cycle.md` or the narrower set, with the reason it is acceptable for an advisory in-cycle check.

**Security implication:** option (a) moves `B2`'s source from the caller into the lib (main's blob read by the lib), so the boundary's transition point moves. Settle it in a combined U2b3b architecture/security review.

#### N3. import_targets still picks its model from the memo globals; the fallback is a narrower model, not a superset

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:646-650`, `:918-923`
**Move:** 7 (control coupling through shared state)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

```
  local u d toks x="" s=(-e 's/\x0/ /g') LC_ALL=C roots="${ROOT_REAL:-}" homes
  import_home || return 1
  homes="$IMPORT_HOME"$'\n'"$IMPORT_HOME_REAL"
  readers_key
  [[ -z "$IMPORT_READERS_DONE" || "$IMPORT_READERS_DONE" != "$READERS_KEY" ]] || { roots="$IMPORT_ROOTS"; homes="$IMPORT_HOMES"; }
```
(excerpt `:919-923`; `import_targets()` continues to `:945`, read: `roots`/`homes` reach awk only as `IT_ROOTS`/`IT_HOMES` at `:943`.)

Iteration 1's F3 defect is gone. The guard now compares the full memo key, so a changed caller list falls back rather than using a stale list (fact-check Claim 8). The shape remains: which reader model the parser runs depends on whether some earlier call left a current memo. When none is current, the function silently runs ROOT_REAL alone, a strictly smaller name set. Both walks call `import_readers` first, so nothing misfires today. U2b3b, however, adds a new class of `import_targets` call (outside seeds resolved against their own directory, G9), and that caller has to know the ordering rule.

**Recommendation:** no change in U2b3a. In U2b3b, either pass the lists explicitly to `import_targets` (as `IMPORT_LEFT` already is) or have it return 1 when no memo is current and the call comes from outside a test. Note the choice in G9's parser-mode design.

#### N4. Contract item 4's "only after a reset" holds for U2c's floor caller, but item 9 does not say when in a decision the lists may be set

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:63-67`, `:83-86`, `:867-870`
**Move:** 2 (responsibility of the caching layer)
**Confidence:** Medium
**Legibility-target:** for-author

```
#  4. Call import_reset before each gate decision and after any checkout
#     change (rows 372, 439), or when IMPORT_OUT_MAX or IMPORT_WORK_MAX
#     changes: neither walk's cache key holds them (both hold import_readers'
#     roots and homes, so HOME and IMPORT_READER_* need no reset, but the
#     worktree registry is read again only after a reset).
```
(`:63-67`, the item in full.)

On the focus question: the memo design fits item 4 and U2c's floor caller. `check_line` calls `import_reset` first (`build-loop.sh:704`). U2c's per-path floor loop then calls `truthwalk main` per path, gets a memo hit (no `git worktree list`), and so judges every path of one brief against one registry snapshot (test "tree w1 -"; fact-check Claim 15a). Each brief's subshell starts fresh in any case. "One reader set per decision" carries an unstated precondition, though: ROOT_REAL, HOME and the two lists must not change between the decision's first walk and its last. The registry is also re-read on a key change (fact-check Claim 1), so a caller that sets the lists after its first walk gets two root sets within one decision. Each set is correct, but the decision no longer rests on one snapshot. With U2b3b's read in `read_settings` before the check loop, the condition holds by construction. It is simply not written down.

**Recommendation:** add to item 9: "before the first walk of a decision (import_reset keeps them)". Fold in the fact-check's Claim 1 wording for item 4 ("re-read after a reset or a change to ROOT_REAL, HOME or the caller's lists").

## What Looks Good

- **Dotnest turns a precondition into the rule itself.** Iteration 1 asked for a check on "honest roots nest only under `.claude/`". The fix makes that check unnecessary, because a root can now hide only dot paths, whatever the layout. The rule also composes over nesting chains, since a name's holders are totally ordered by prefix (probe 1), and it costs nothing on the honest layout (main's 128 names, Claim 26b).
- **One invalidation point.** `import_reset` now clears all three caches. The reader memo's key (length-prefixed, Claim 16) covers every input that is not tied to a decision, so a caller never has to know which cache holds what.
- **The caller interface is now explicit:** cleared at source, defined in item 9, and kept by `import_reset`. Because of dotnest, an inherited or misconfigured root can only add names or fail the walk. The source-time clearing is now about having one source of truth, not about safety.
- **The settings line is self-protecting.** `docs/dev-cycle.md` is a floor-refused path (`truthrule` `settings`), so U2b3b's `Reader roots:` line cannot be self-merged by the loop it governs.
- **IT_ROOT removed (F7).** The parser has one source for its first root.
- **Tests run each case on both walks.** The new ones were red on 5516c6e6 (fact-check P5).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| N1 | Superset statement still says longest-root; the dot omission depends on truthrule's duplicated dot predicate, with no cross-reference; the caller-root test row does not nest | Minor | `scripts/lib/dev-cycle-read.sh:679` (also :738-751, :813, :1210; `build-loop-check.bats:1766`) | High |
| N2 | Item 9 leaves each caller to source the lists; only build-loop.sh has a settings reader, so check_fix's tree walk can diverge from the floor after U2b3b | Minor | `scripts/lib/dev-cycle-read.sh:83-86` (also `build-loop.sh:380`, `dev-cycle.sh:181,186`) | Medium |
| N3 | import_targets' model still comes from the memo globals; the fallback is ROOT_REAL alone, a narrower set, for any non-walk caller | Informational | `scripts/lib/dev-cycle-read.sh:919-923` | Medium |
| N4 | One reader set per decision holds for U2c, but item 9 does not say the lists must be set before a decision's first walk; item 4's "only after a reset" omits key changes | Informational | `scripts/lib/dev-cycle-read.sh:63-67, 83-86` | Medium |

## Overall Assessment

The fixes improve the structure. Iteration 1's one Coupling concern (F1, a root set that could shrink the floor's import set) is resolved by a rule that is general rather than layout-specific: a root can add names and hide only paths truthrule refuses. That is better than the refusal I suggested, which would have tied the gate's availability to registry hygiene. F2(a), F3, F6 and F7 are resolved. F4 and F5 are deferred under override rows. No regression and no Structural or Coupling finding remains. The most important leftover is N1: the superset statement is the lib's one authoritative description of the projection, it still states the old rule, and it should name the parser's new dependency on truthrule's dot predicate. N2 is the item for U2b3b's plan: the reader lists need one reader for both walk callers, or a stated rule for check_fix. All four findings can be fixed in place or belong to U2b3b's plan; nothing needs restructuring.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u2b3a/docs/reviews/architecture-review-2026-10-08-u2b3a-i2.md, structured per the architecture-review skill, with `Commit: c9197fd2` as its first line.
- Answered: yes
- Out of scope: commits before 5516c6e6 (context only); override rows G8 and G9 (U2b3b), G11 and G12, rows 431 and 477 (outside starts); the comment and commit-message figures (fact-check Claims 6, 7b, 26c, 26d, which belong to fact-check and performance); exploitability under Q-103 (security).
- Escalate: N2 is a U2b3b plan decision: where the `Reader roots:` line is read so that both walk callers share it, or what check_fix uses. Add it to U2b3b's sub-bullet beside G8 and G9. N1's `:679` rewording matches the fact-check's Stale Claim 9 and should land before merge.
- Decisions I made: I rated N1 Minor, not Coupling. The dependency is inside one lib, between two functions that use the same predicate, and today it is exact. I rated N2 Minor because nothing is exposed until U2b3b supplies non-empty lists. I treated F3 as resolved in effect and filed its remaining shape as Informational (N3).
