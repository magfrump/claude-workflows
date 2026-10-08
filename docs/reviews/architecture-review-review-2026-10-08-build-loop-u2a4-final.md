Commit: 2b6f2f91

# Architecture Review — feat/build-loop-u2a4 (U2a4, the self-merge floor), final confirming pass

**Scope:** `git diff main...HEAD` (main = 7afdb8d2, HEAD = 2b6f2f91) in /workspace/.claude/wt-build-loop-u2a4: scripts/lib/dev-cycle-read.sh, scripts/dev-cycle.sh, test/scripts/build-loop-check.bats, docs/working/{plan-build-loop-handoff,known-issues-dev-cycle}.md, docs/reviews/override-log.md
**Date:** 2026-10-08
**Based on:** the Stage 1 k=3 summary for this pass (`code-fact-check-report-build-loop-u2a4-final-r{1,2,3}.md`, 0 Incorrect); iteration 1's `architecture-review-review-2026-10-07-build-loop-u2a4.md`; the rubric `code-review-rubric-2026-10-07-feat-build-loop-u2a4.md`; override-log rows 462-480.

Scope check: in scope (public lib surface: `isstart`, `prompt_dir`, `prompt_bases`, `import_reset`, `truthrule`, `truthwalk`, `ownfile`, `floor`, `PROMPT_DIR`, `GATE_CODE`, `TRUTH_WHY`, `FLOOR_WHY`; `import_targets`' signature widened; a cross-cutting caller contract for the walk cache). Tests and docs were read as context.

Trust-boundary cross-reference: the most recent `docs/reviews/security-review-*.md` by date is `security-review-2026-10-02-digest-pass38.md` (Commit: `90364c73` — security review predates this diff; boundary may be stale). Its `B1` (`--check-fix gate, check_fix()`) and `B2` (`imported_names() walk ... → [IMPORTED refusal set]`) coincide with the truthrule/truthwalk and isstart boundaries reviewed here. No finding below recommends moving either crossing.

Executed: `bats test/scripts/build-loop-check.bats` 78/78, `test/scripts/build-loop-read.bats` 19/19, `test/scripts/dev-cycle.bats` 78/78, 0 failures (own TMPDIR; no process left running). A `prompt_bases`/`isstart` probe (below, finding 3).

## Dependency Map

- `scripts/dev-cycle.sh` (CLI) sources the lib; `check_fix` (`:171-184`) now calls only lib functions for its shared part: `lower`, `truthrule`, `truthwalk tree`. `scripts/build-loop.sh` sources the same lib; `floor` has no caller yet (U2b/U2c).
- Inside the lib: `INSTRUCTION_FILE` + `PROMPT_DIR` → `isstart` (`:485`) → {`truthrule` `instr` (`:993`), `imported_names`' start loop (`:849`), `main_imports`' start loop (`:908`)}; `instruction_names` (`:764`) is the tree walk's grep prefilter, held equal to `isstart` by test `:1172`. `PROMPT_DIR` → `prompt_dir` (`:489`) fills each walk's `pdir` map → `prompt_bases` (`:495`) → `import_targets "$d" "${xs[@]}"` (`:724`) → `IMPORT_AWK` (`IT_XDIRS`, `emit`'s base loop `:641-642`). `truthwalk` (`:1007`) → {`main_imports`, `imported_names`} → `isimported`. `floor` (`:1039`) → `truthrule`, `GATE_CODE`, `ownfile`, `truthwalk main`. `import_reset` (`:555`) clears both walk caches.
- Direction holds: the lib references nothing defined in dev-cycle.sh or build-loop.sh (`writable`, `isbrief`, `isclosed`, `lower`, `need_root` are lib-defined, `:127`, `:196-201`, `:578`). No cycle. The remaining "upward" knowledge is prose only (contract item 8 names check_fix).

## Iteration 1 follow-through

| Iter-1 finding | Disposition | Holds at 2b6f2f91? |
|---|---|---|
| F1 cache coupling (Coupling) | Fixed: `import_reset`, contract item 4 | Yes for the code: `import_reset() { IMPORTED_DONE=""; IMPORTED_MAIN_DONE=""; }` and test 78 (`import_reset makes the next floor walk again`). The cache key still omits checkout, HOME and budgets (accepted as a caller duty). Residue: four prose sites still tell callers to assign the variables (finding 1). |
| F2 prompt-base rule split | Fixed: `prompt_bases` | Yes. Both walks call one helper (`xs=(); [[ -z "${pdir[$f]+set}" ]] \|\| prompt_bases xs "${pdir[$f]}" "$f"`); the base policy has one owner, top level included once (no `("" "")`). |
| F3 contract in three places | Fixed | Yes for the plan: the U2b bullet says "keeps every item of the lib header's numbered gate caller contract (U2a4; the one statement of these duties, not restated here), and builds item 3's refusal", which is what F3 asked; F11 says "the caller contract is the lib header's numbered list (U2a4)". A5 still carries a summary list (finding 1). |
| F4 floor is D5 items 1-4 | Named; composition deferred (row 474) | Yes: `# The self-merge floor (plan D5 items 1-4)`. Row 474 (U2c) and row 466 (U2b cache clear, U2c order) are consistent with each other and with contract item 5. Right. |
| F5 check_fix prose list; lib comment described check_fix | Comment trimmed; mapping Won't-Fix (row 475) | Yes: truthrule's comment now says only "Each caller words the words and adds its own rules (docs/thoughts/ is the floor's only...)". Row 475's reasoning holds (fail-closed, message pinned by tests). Right. |
| F6 start rule spelled twice | Table test | Yes: test `:1172` compares `isstart` with `instruction_names` over generated paths; green. |
| F7 one TRUTH_WHY, two vocabularies | Won't-Fix (row 476) | Still two readers, each reading right after its own call. Right. |
| F8 outside-repo starts need a start source | Defer to U2b (row 477) | Deferral right; its stated rationale overreaches (finding 5). |

Override rows the focus named: row 322 ("one lib predicate that check_fix also calls") is met by `truthrule`; row 418 ("should own that order once") is met by `truthwalk`; row 348's revisit is closed by row 462; row 324's order and whole-branch refusal are contract item 5, routed by row 466 to U2c (no caller exists to test the order against). Row 459 ("one numbered statement") is met in placement and in the plan (finding 1 covers the residue).

## Findings

#### 1. Contract item 4 names `import_reset`, but A5 and three lib comments still prescribe assigning the cache variables by hand

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:543-548`, `:560-561`, `:569-570`, `:55-57`; `docs/working/known-issues-dev-cycle.md:18` (A5); `test/scripts/build-loop-check.bats:347` (test title)
**Move:** 7 (coupling surface) / 3 (where the public contract is declared)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
#  4. Call import_reset before each gate decision and after any checkout
#     change (rows 372, 439), or when HOME, IMPORT_OUT_MAX or IMPORT_WORK_MAX
#     changes: neither walk's cache key holds them.
```
and, in the block above `IMPORTED=`:
```
# whose files it read, so a caller whose checkout may have changed (a file
# added or edited) sets IMPORTED_MAIN_DONE="" to walk again, and a cached
# error returns 1 again. A caller that changes HOME clears both
# IMPORTED_DONE and IMPORTED_MAIN_DONE (both caches are keyed without it).
```
`IMPORT_OUT_MAX`'s comment: `# 2 KB, /workspace's about 6 KB. A caller that changes it clears IMPORTED_DONE` / `# and IMPORTED_MAIN_DONE before walking again.`; `IMPORT_WORK_MAX`'s: `# that changes it clears both caches, as for IMPORT_OUT_MAX.`; A5: `The walk's cache ignores the checkout, so a caller clears `IMPORTED_MAIN_DONE` after any checkout change (the lib header's numbered gate caller contract, U2a4, is the one statement ...`.

Iteration 1 F1 asked for the cache duty to become one lib call so the variable names stay lib-private; `import_reset` does that and is tested. But the four older sites still give the duty in its pre-U2a4 form, naming the globals, so the module now publishes two invalidation mechanisms. They agree in effect today (the fact-check: "restated (consistently) in three lib comments"), so nothing under-reads; the cost is that a U2b author who reads the comment beside `IMPORTED_MAIN_DONE` (the natural place to look when touching the cache) learns the variable is part of the interface, and a later change to the cache's shape (say, folding HOME into the key, or a third cache) has to update four prose sites or leave a caller assigning a variable that no longer suffices. A5's parenthetical also restates a summary of the contract ("a clean worktree at MAIN_SHA, empty `ls-files` stderr, the git environment, `LC_ALL=C`, the cache, the order of floor and main_entry"), which is a pointer plus a list rather than a pointer.

**Recommendation:** Replace each of the four sentences with "call `import_reset` (caller contract item 4)", and cut A5's parenthetical to the pointer. Optionally retitle test `:347` to name `import_reset`. Doc-only; no code change.

#### 2. The superset paragraph, "the one statement" A5 and F11 point to, no longer holds two of the parser's rules

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:593-617` (the paragraph), `:579-582` (import_targets' opening), `:669-674` (scan's inline comment); `docs/working/known-issues-dev-cycle.md:18`; `docs/working/plan-build-loop-handoff.md:126`
**Move:** 3 (module boundary: where a contract is declared)
**Confidence:** High (fact-check r1 Stale; r2, r3 Mostly accurate, same mechanism)
**Legibility-target:** for-author

**Evidence:**
```
# The superset claim (the one statement of it; known issue A5 and plan F11
# point here): ...
# fences too; each prefix of the run after it, up to the first blank (a NUL or
# a UNI_SPACES space counts as one), is a candidate name, ...
# made absolute (ROOT_REAL/$1/name unless it starts with /) and resolved
```
while the code reads more:
```
    if (substr(line, i + 1, 1) == "\"") names(line, i + 2, L, 1)
```
```
  for (i = 0; i <= nd; i++) put(root "/" dirs[i] "/" c)
```
The quoted-run rule (reads past blanks to the closing quote) is stated only in `scan`'s inline comment, and the extra base directories only in import_targets' opening sentence (`a relative name resolved against $1 and against each further directory given`) and `prompt_bases`. A5 says "the claim, its rules and its exceptions are stated once, in the comment above `import_targets`", which is no longer true. The direction is safe (the code over-reads relative to the text), so this is legibility, not a gap; but the "one statement" pattern is the device this initiative uses to keep the parser auditable against the next Claude Code grammar change (A5's revisit trigger), and a reviewer re-checking the superset against a new oracle from that paragraph would miss two rules that each widen what is read.

**Recommendation:** Add two clauses to the paragraph: after "up to the first blank", "and, after `@"`, the run up to the closing quote, blanks included"; and change "ROOT_REAL/$1/name" to "ROOT_REAL/DIR/name for $1 and each further directory (prompt_bases)". Leave `scan`'s comment as the why.

#### 3. ".claude/ as a path component" has three spellings, and prompt_bases' is a string prefix

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:484-485`, `:495-503`, `:764`
**Move:** 7 (coupling) / 8
**Confidence:** High (executed)
**Legibility-target:** for-author

**Evidence:**
```bash
PROMPT_DIR='(^|/)\.claude/(commands|agents|output-styles|skills)/'
isstart() { [[ "${1##*/}" =~ $INSTRUCTION_FILE ]] || [[ "$1" == *.md && ( "$1" =~ $PROMPT_DIR || "/$1" == */.claude/rules/* ) ]]; }
```
```bash
  while [[ "$rest" == */.claude/* ]]; do
    # Up to /.claude, not /.claude/: a .claude/ directly inside another keeps its slash (U2a4 i2 fact-check 1).
    rest="${rest#*/.claude}"; n=$(( ${#2} - ${#rest} - 8 ))
```
Probe (`prompt_bases xs P P`): `a/.claudex/.claude/commands/x.md -> [] [a] [a/.claudex]`; `a/.claude/skills/s/.claude/commands/y.md -> [] [a] [a/.claude/skills/s]`.

`isstart` matches `.claude` as a whole component (PROMPT_DIR's trailing `/`, the rules glob's `/.claude/rules/`), the prefilter does the same in grep's dialect, but `prompt_bases` strips to the shortest `*/.claude` prefix, so a `.claudex` (or `.claude-old`) component also contributes a base. That only adds bases (over-read, the safe direction; fact-check, all three replicates), and the i2 fix needed exactly this prefix form to keep the slash for a doubled `.claude/.claude/`. Separately, `prompt_bases` measures offsets on LP and slices PATH, which is correct only because `lower` is an ASCII `tr` that preserves byte length. Neither is a defect; both are invariants the next editor of one spelling must know about the others. The table test (`:1172`) guards isstart against the prefilter but nothing guards prompt_bases' notion of the component against PROMPT_DIR's.

**Recommendation:** None required now. If the base rule is touched again (U2b's reader model will be), compute bases from a component split (`IFS=/ read -ra`) so all three spellings agree on what a `.claude` component is, and note the LP/PATH same-length assumption in prompt_bases' comment.

#### 4. The lib's own inventories do not list the U2a4 surface

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:2-6`; `test/scripts/dev-cycle.bats:1101-1116`
**Move:** 3 (module boundary: the declared public surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:** header: `# The dev cycle's reader, ...: the output scrub, the plain-file` / `# and path-form rules, the cycle's own file names, the Markdown shapes the` / `# readers refuse (FENCE_AWK), the brief, branch and answer checks, the` / `# instruction-file import walks, and the default branch.` The sourcing test's list: `for f in scrub scrub_reexec rawfile ... main_checkout lower_all capped_read import_work; do` / `declare -F "$f" >/dev/null || echo "missing $f"`, and its variable lists, name none of `isstart`, `prompt_dir`, `prompt_bases`, `import_reset`, `truthrule`, `truthwalk`, `ownfile`, `floor`, `PROMPT_DIR`, `GATE_CODE`, `TRUTH_WHY`, `FLOOR_WHY`.

The lib now owns a new responsibility (the self-merge floor and the read-as-truth rule both gates share), but its one-paragraph statement of what it holds and the test that pins "sourcing defines its functions and calls neither git nor perl" both predate it. Behavioral tests cover each new function, so a lost definition would still fail somewhere; the cost is only that the module's declared surface understates what U2b and U2c will build on.

**Recommendation:** Add "the read-as-truth rule and the self-merge floor" to the header's list, and the twelve names to the sourcing test's lists.

#### 5. Row 477's rationale calls prompt_bases "the seam the finding asked for"; it is half of it, and the plan line still assigns outside-repo starts to the predicate

**Severity:** Informational
**Location:** `docs/reviews/override-log.md:477`; `docs/working/plan-build-loop-handoff.md:278` (U2a4 bullet); `scripts/lib/dev-cycle-read.sh:495-503`, `:727`
**Move:** 8 (extension points)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:** row 477: `| Defer | prompt_bases now returns one list of bases, the seam the finding asked for. Revisit trigger: U2b's reader model. |`. Iteration 1 F8 recommended "model outside-repo starts as a second start source beside `tree_starts`/main's listing, not as an `isstart` widening; keep the plan's U2a4 line from implying the predicate will carry them." The plan's U2a4 bullet still opens: `That predicate is also the one start predicate both walks use (...): A2's .claude/rules/, .claude/commands/*.md (...), and the outside-repo starts U2b's reader model names.` (the appended "Built" sentence then says "Outside-repo starts stay U2b's").

The deferral is right. The rationale overstates what landed: `prompt_bases NAME LP PATH` derives bases from the path alone and takes none from outside, and neither walk has a second start source; the open seam for U2b's session directories is `import_targets`' extra-argument list (`[[ $# -lt 2 ]] || x="$(printf 'x%s\n' "${@:2}")"`), which takes repo-relative bases (an absolute session directory joins as `root "/" "/abs"` and lands under the root, so U2b must pass session directories relative to ROOT_REAL or extend the parser). Outside-repo start *files* still have no entry point, since both walks read starts by repo path. A U2b author reading row 477 would expect more seam than exists.

**Recommendation:** Amend row 477's note to: "prompt_bases owns the in-repo base list; import_targets' extra bases (repo-relative) are the seam for session directories; outside-repo start files need a second start source (F8)". Trim the plan bullet's first sentence so the outside-repo starts are not listed as part of the predicate.

## What Looks Good

- **One shared read-as-truth rule, in the right layer.** `truthrule` returns one word per denial and both callers word it; check_fix's own extras (the docs/README allowlist, `working/`, `reviews/`) and floor's (`GATE_CODE`, `docs/thoughts/`, `ownfile`) each live in their caller, and test "check_fix and floor share one read-as-truth rule; docs/thoughts/ differs on purpose" pins the line between shared and per-caller. Rows 204, 322, 348 are closed as row 322 asked.
- **One start predicate, used for decisions everywhere.** `isstart` is the start test in both walks and the `instr` refusal in truthrule, so "a start file" and "a file the floor refuses as instructions" cannot drift; main_imports' inline rules/ test is gone; the prefilter's equality is now a test, not a comment.
- **truthwalk owns walk-then-ask** (row 418) for both walks, fails closed on an unknown walk name, and leaves TRUTH_WHY empty on a pass (tested).
- **prompt_bases is the single owner of the session-base policy** and the parser's extra-base parameter is additive (one-directory output unchanged; `--check-fix` byte-identical to main over 3,104 tracked paths, Stage 1). The symlinked-prompt arm fails closed rather than guessing which directory a session resolves against.
- **The caller contract is in the right place**: the lib header, beside the code it governs and in the copy D6 runs; the plan's U2b bullet keeps only what U2b must build (item 3's refusal), and F11 points to the header. `import_reset` turns item 4 into one call, with a test.
- **floor's interface stays narrow** (path, stem, status letter → 0/1 + FLOOR_WHY), calls neither pathform nor main_entry, and its comment now says it is D5 items 1-4.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | import_reset is item 4's mechanism, but A5 and three lib comments still tell callers to assign the cache variables | Minor | `scripts/lib/dev-cycle-read.sh:543-548`, `:560-561`, `:569-570`; A5 | High |
| 2 | The superset paragraph ("the one statement") omits the quoted run and the extra bases | Minor | `scripts/lib/dev-cycle-read.sh:593-617` | High |
| 3 | `.claude` component spelled three ways; prompt_bases' is a string prefix (over-read only) | Informational | `scripts/lib/dev-cycle-read.sh:484-485`, `:495-503`, `:764` | High |
| 4 | The lib header and the sourcing test do not list the U2a4 surface | Informational | `scripts/lib/dev-cycle-read.sh:2-6`; `test/scripts/dev-cycle.bats:1101-1116` | High |
| 5 | Row 477 overstates prompt_bases as the outside-repo seam; plan U2a4 line still lists outside-repo starts under the predicate | Informational | `docs/reviews/override-log.md:477`; plan `:278` | Medium |

## Overall Assessment

The branch delivers the structure the plan asked for: one shared check_fix/floor predicate (`truthrule`), one owner of the walk-then-ask order (`truthwalk`), and one start predicate (`isstart`) that both walks and the refusal rule call, all in the lib with dependency direction lib ← dev-cycle.sh and no new cycle. Iteration 1's fixes hold: `prompt_bases` is the single base-policy owner, `import_reset` makes the cache duty one call, the plan's U2b bullet and F11 point to the header's numbered contract, and the prefilter's equality with `isstart` is tested. Its deferred and won't-fix rows (466, 474-477) are right; row 477's rationale is overstated (F5). Nothing is Structural or Coupling. The two Minor findings are documentation drift against this initiative's own "one statement" device: the cache duty is stated in its old raw-variable form in four places beside `import_reset` (F1), and the superset paragraph lacks two rules the parser now applies (F2). Both are fixable in place with doc-only edits; the most important is F1, because the comment beside `IMPORTED_MAIN_DONE` is where U2b's author will look.

## Goal-Alignment Note

- Success criterion (restated verbatim): your report saved at the path your task names, structured per your skill, with every finding grounded in verbatim evidence.
- Answered: yes. Saved at `docs/reviews/architecture-review-review-2026-10-08-build-loop-u2a4-final.md`, `Commit: 2b6f2f91` first. Focus areas: truthrule/truthwalk/isstart as the one shared and one start predicate (What Looks Good, follow-through table, F3); prompt_dir/prompt_bases as the seam (F3, F5); import_reset and the cache coupling (F1); the contract's placement and the "one statement" claim (F1, F2, follow-through table); iteration 1's fixes and deferred rows (follow-through table, F5). Every finding quotes code or docs verbatim; F3 also quotes an executed probe.
- Complete amber inventory from this lens: none (no Coupling or Structural finding). Two Minor (F1, F2), three Informational (F3-F5), all 🟢.
- Out of scope: correctness, security and performance. Fact-check escalation 2 (whether A7's note or row 469 should name the prompt case, where extra bases push a 2,000-quote line past IMPORT_OUT_MAX and both walks fail closed) is a performance/wording call; structurally it is row 469's settled point that the walk-wide budgets are not scaled by base count. Escalation 1 (a start file removed from the index and edited in the checkout is read from main's copy) is covered by contract item 2's clean-worktree duty; no structural change indicated.
- Escalate: none blocking. F1 and F2 are doc-only and can share one edit; F5 is an override-row note and a plan sentence.
- Decisions I made: rated F1 Minor, not Coupling (iteration 1's F1 was Coupling), because the code seam now exists and is tested and the residue is prose that agrees in effect; took `security-review-2026-10-02-digest-pass38.md` as the most recent security review by its date (the egress review has a later mtime but an earlier date), and labelled it stale.
