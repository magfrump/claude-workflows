Commit: a7a4f784

# Architecture Review — feat/build-loop-u3a3 (iteration 1, loop pass)

**Scope:** `git diff main...HEAD` (18f32952 tests, a7a4f784 code): `scripts/build-loop.sh`, `scripts/lib/dev-cycle-read.sh`, `scripts/dev-cycle.sh`, `test/scripts/build-loop-{check,merge}.bats`
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a3-i1.md` (22 verified, 4 mostly accurate, no code defects)

**Scope check:** in scope. The diff changes public APIs (the `--approved Q-NNN` CLI flag; new lib globals `ANSWER_HEAD`, `TRUTH_WHERE`, `IMPORTED_WHY`; a new lib function `floor_why`; `FLOOR_WHY` changes from a sentence to a word), a data model (`VERDICT[gate]`, the `merge-STEM-SHA12` / `merge-gate-STEM-SHA12` heading contract, the `Build-loop-approved:` trailer) and a cross-cutting concern (the authorisation pipeline: `AUTH` decides rules, approval and landing). The test files are reviewed only as evidence.

**Trust-boundary cross-reference:** the newest security review by name is `docs/reviews/security-review-2026-10-10-u3a2-confirm2.md` (Commit: `2028aa89`; it predates this diff, so its boundaries may be stale). Its map (B1–B5) covers argv/env, W's git dir, refs, admin-dir state and the bare marker. None of them is the new input this diff adds: questions entry text on main's commit flowing into `approval()`. No finding below moves a labeled crossing. The new crossing is unlabeled and belongs to the security reviewer (see Overall Assessment).

## Dependency Map

- `scripts/build-loop.sh` (caller) → `scripts/lib/dev-cycle-read.sh` (shared reader). The direction is unchanged and correct: the lib defines generic readers (`check_answer`, `floor`, `truthwalk`, `GATE_CODE`), and build-loop owns the gate's data model (`VERDICT`, `CHANGED`, `AUTH`) and the policy that uses them (`approval`, `land`). No lib function reads a build-loop global.
- `scripts/dev-cycle.sh` → lib: `check_fix` now reads `TRUTH_WHERE` and no longer reaches past `truthwalk` into `IMPORT_READER_WHY`. That is a narrower dependency than before.
- Inside the lib, `truthwalk` now depends on `walk_why`, a wording function. Before, only callers worded a walk's failure. `floor_why`'s `walk` case reads `TRUTH_WHERE`, so it depends on the most recent `truthwalk`.
- Inside build-loop, the authority flows as follows:
  1. The merge arm sets the `AUTH` global (line 1209).
  2. `check_line` reads `AUTH` implicitly (line 982) to choose the S rules and the checkout check.
  3. The merge arm branches on `AUTH` to choose between the policy refusal and `approval` (lines 1215–1216).
  4. `land` receives the authority as `$1` and the question ID as `$2` (line 1217).
  5. `approval` receives the question ID as `$1` and reads `VERDICT[gate|stem|tip]`.

## Findings

#### F1. The approval heading contract has one checker and no shared producer

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1070-1084` (approval), `scripts/build-loop.sh:1041`, `scripts/build-loop.sh:222-231` (header); `docs/working/plan-build-loop-handoff.md:59-61` (D4: the orchestrator files the entry)
**Move:** 3 (module boundary), 7 (coupling surface)
**Confidence:** Medium

Evidence:
```
  [[ -z "${VERDICT[gate]}" ]] || { s="merge-gate-"; g=" (the merge changes the gate's own code)"; }
  s+="${VERDICT[stem]}-${VERDICT[tip]:0:12}"
```
```
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
```
Plan D4: "Otherwise it files one merge entry, `### Q-NNN · merge-<stem>-<first 12 of TIP>`. The entry body is `--check`'s output".

The heading string is a contract between two parties: whoever files the entry (the orchestrator, per D4) and the gate that checks it (`approval`). The diff defines that string, including the merge- vs merge-gate- decision taken over lower-cased changed paths, only inside `--merge`. `VERDICT[gate]` is filled for every run but read only by `approval`. `--check`'s output, which D4 says becomes the entry body, carries neither the gate bit nor the expected heading. The filer therefore has two options. It can re-derive the rule (lower-case each changed path, match `GATE_CODE`, take 12 hex digits) in a second place. Or it can learn the heading by running `--merge` and scraping the refusal "its heading must read ...". A mismatch fails closed (the merge refuses), so this is a change-cost and usability coupling, not a safety one. Once the filer is written, a change to the slug shape or to `GATE_CODE` will need edits in two modules that nothing ties together.

**Recommendation:** Before the filer lands (U3b/U4), give the heading one producer. For example, `--check`'s ok output or `--status` could print the expected `merge[-gate]-STEM-SHA12` slug from the same `VERDICT` values `approval` compares against. If that is deferred, route it as a plan note on the filer's bullet so the filer does not grow its own copy of the rule.
**Legibility-target:** plan step 7's U3b/U4 bullet, and the `--merge` paragraph of the build-loop.sh header (which should name where the filer gets the slug).

#### F2. ANSWER_HEAD breaks the lib header's single capture rule, and the header does not say so

**Severity:** Minor
**Location:** `scripts/lib/dev-cycle-read.sh:31-34` (header capture rule), `scripts/lib/dev-cycle-read.sh:2064-2096` (check_answer), `scripts/build-loop.sh:1074-1075`
**Move:** 3 (module boundary: two output channels), 7
**Confidence:** High

Evidence (header):
```
# check_answer answer with one printed line per argument that can echo repo
# text: print it through scrub, read it as `out="$(check_brief ...)"` under
# set -e (which stops when need_root exits; `if out=...` and `< <(...)` would
# carry on), and treat any line that is not a positive answer as a refusal.
```
Evidence (check_answer comment and caller):
```
# dropped), else empties it; a caller that reads it (build-loop.sh --approved)
# calls check_answer in its own shell, its output to a file.
```
```
  # In this shell, to a file: ANSWER_HEAD would not leave a $(...).
  check_answer "$1" > "$GATE_TMP/answer"; r="$(cat "$GATE_TMP/answer")"
```

`check_answer` now returns two things through two channels: the verdict line on stdout and the heading in a global. The global can only be read if the header's prescribed `out="$(...)"` capture is not used. The header calls itself the one statement of these rules, and it still prescribes that capture for `check_answer`. Only the function's own comment records the exception. Safety is unaffected, because `check_answer` reads only git objects and never reaches `need_root`, and running it in the caller's shell is if anything stricter. But the next caller has to discover the exception from the function body. The design also runs opposite to the pattern this same diff sets for `floor`: a function sets a word, and a separate function turns it into a sentence. The `floor`-style shape would be a setter (say, an `answer_entry` that sets the result word, the heading and the reason in the caller's shell), with `check_answer` as the printing wrapper `dev-cycle.sh --check-answer` keeps. That would leave one output per function.

**Recommendation:** At minimum, add the exception to the header's capture sentence: `check_answer` may run in the caller's shell with stdout to a file when its caller reads `ANSWER_HEAD`. A setter/printer split is optional and could ride a later unit.
**Legibility-target:** `scripts/lib/dev-cycle-read.sh` header, lines 31–34.

#### F3. The authority reaches check_line as an implicit global but land as arguments, and land's two arguments must agree

**Severity:** Minor
**Location:** `scripts/build-loop.sh:967-972`, `:982`, `:1100-1103`, `:1168-1169`, `:1209-1217`
**Move:** 7 (control coupling)
**Confidence:** High

Evidence:
```
  [[ "$pol" != self-merge || "$AUTH" == approved ]] || sm=1  # the S rules and the checkout
```
```
  [[ "$1" != approved ]] || what="approved merge"
```
```
    [[ -z "${2-}" ]] || printf 'Build-loop-approved: %s\n' "$2"; } > "$GATE_TMP/msg" \
```
```
    AUTH=self-merge; [[ -z "$APPROVED" ]] || AUTH=approved
...
    elif land "$AUTH" "$APPROVED"; then
```

Row 653 asked for the authority to be computed once and passed to `check_line` and `land`. It is computed once. But `check_line` gets it through dynamic scope (its signature is still `check_line BRIEF`), while `land` gets it positionally. `land` also keys the message on `$1 == approved` and the trailer on `$2` being non-empty. Those are two inputs that must agree, and only the merge arm's construction (`AUTH=approved` exactly when `APPROVED` is set) guarantees they do. A future authority, or a second caller of `land`, could produce "(build-loop self-merge)" with a `Build-loop-approved:` trailer, or "approved merge" with none. A third value (`--check`'s empty `AUTH`) means the same as `self-merge` to `check_line`, and that equivalence is stated only in the comment. These are small seams, but they are the seams the next authority (U3/U4) will extend.

**Recommendation:** Choose one channel. Either `land` reads `AUTH`/`APPROVED` the way `check_line` does, or `check_line` takes the authority as an argument. In `land`, key the trailer on the same test as the message (`[[ "$1" == approved ]]`), so the two cannot disagree.
**Legibility-target:** the `AUTH` comment block above `check_line`, and `land`'s header comment.

#### F4. GATE_CODE is tested at two sites; floor's comment points callers at the wrong one

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1924-1925`, `:1945`; `scripts/build-loop.sh:1041`; `scripts/build-loop.sh:228-230`
**Move:** 2, 7
**Confidence:** High

Evidence:
```
# Returns 0 with FLOOR_WHY set to a word when the floor refuses (floor_why
# words it: row 472; gate is the gate's own code, which a caller can test), else 1.
```
```
  elif [[ "$lp" =~ $GATE_CODE ]]; then FLOOR_WHY=gate
```
```
    [[ ! "${lps[$i]}" =~ $GATE_CODE ]] || gc=1
```

The regex is defined once (`GATE_CODE`) and both sites use it, so the definition cannot drift. The second test site is needed. Under `--approved`, `floor` never runs (no S rules). Under self-merge, `floor` runs only on paths that the N rules, `Self-merge never:` and `Paths:` passed, and only after `truthrule`. So `FLOOR_WHY == gate` cannot stand in for "this merge touches gate code". Floor's comment ("which a caller can test") invites exactly that misuse. The build-loop.sh header also restates the regex in prose ("scripts/build-loop.sh, dev-cycle.sh, questions.sh, anything under scripts/lib/"), a third copy that a reader must keep in step by hand.

**Recommendation:** Reword floor's clause so the gate-code test is `GATE_CODE`, as `check_line` uses it, and drop "which a caller can test". Optionally have the header name `GATE_CODE` next to its prose list.
**Legibility-target:** floor's comment block.

#### F5. The plan's gate-file list includes skills/dev-cycle/, but GATE_CODE does not, and the slug now depends on it

**Severity:** Informational
**Location:** `docs/working/plan-build-loop-handoff.md:61` vs `:71` and `scripts/lib/dev-cycle-read.sh:1915`
**Move:** 2 (responsibility boundary of "gate code")
**Confidence:** Medium

Evidence:
```
    - A change to the gate's own files (`scripts/{build-loop,dev-cycle,questions}.sh`, `scripts/lib/`, `skills/dev-cycle/`) gets its own slug, `merge-gate-…`. Plain `--approved` refuses such a change (F52).
```
```
GATE_CODE='^scripts/(build-loop|dev-cycle|questions)\.sh$|^scripts/lib/'
```

D5 (line 71) and the checkpoint's D5 list leave out `skills/dev-cycle/`, and `GATE_CODE` follows them. D4's line 61 still includes it. This inconsistency predates the diff. It now has consequences, because the `merge-` / `merge-gate-` slug decision (F52 coverage) is computed from `GATE_CODE`. A filer that follows D4's prose would choose `merge-gate-` for a skills/dev-cycle change, and the gate would refuse it (fail closed).

**Recommendation:** Reconcile D4's list with D5 in the plan (most likely by dropping `skills/dev-cycle/` from line 61, since D5 is the later decision), or extend `GATE_CODE` if skills/dev-cycle is meant to count.
**Legibility-target:** `docs/working/plan-build-loop-handoff.md:61`.

#### F6. TRUTH_WHERE is a sentence where its neighbours are words

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:1888-1895`, `:1959-1974`
**Move:** 2, 7
**Confidence:** Medium

Evidence:
```
    main) main_imports || { TRUTH_WHERE="$(walk_why "$IMPORTED_MAIN_WHY")"; return 0; } ;;
    tree) imported_names || { [[ -z "$IMPORTED_WHY" ]] || TRUTH_WHERE="$(walk_why "$IMPORTED_WHY")"; return 0; } ;;
```
```
# floor_why WORD: the sentence for a FLOOR_WHY word, as walk_why words
# IMPORTED_MAIN_WHY's; walk reads TRUTH_WHERE, so word it before the next
# truthwalk.
```

The diff moves `floor` to words that are worded later (row 472), matching `walk_why` and `entry_why`. But `truthwalk` goes the other way: it words eagerly, in a subshell, inside the walk layer. `floor_why` then carries a temporal dependency on a global that the next `truthwalk` clears. The dependency is documented, and it mirrors `walk_why`'s own read of `IMPORT_READER_WHY`, so it is a known pattern rather than a new kind of coupling. The alternative would have `TRUTH_WHERE` hold the walk's word (`IMPORTED_MAIN_WHY` / `IMPORTED_WHY`), with `floor_why` and `check_fix` calling `walk_why` themselves. That would make every `*_WHY`/`*_WHERE` global a word and remove the "word it before the next truthwalk" rule. The cost is the same one fork.

**Recommendation:** No change needed now. If a third reader of `TRUTH_WHERE` appears, switch it to a word then.
**Legibility-target:** truthwalk's comment, if changed.

#### F7. Item 5 of the gate caller contract still describes the policies, not the authorities

**Severity:** Informational
**Location:** `scripts/lib/dev-cycle-read.sh:78-87` (contract item 5); also item 3 (`:64-65`)
**Move:** 3
**Confidence:** Medium

Evidence:
```
#     caller's rules; build-loop.sh's N rules apply them, and pathform, under
#     both policies, and its S rules run floor only on a path they pass, so a
```

The answer to the brief's question "does the header need updating?" is: not for correctness. The contract binds callers of `floor` and `main_imports`, and `--merge --approved` calls neither (no S rules, no checkout check, no walk). So no contract item is violated. "Under both policies" is still true. But a reader can no longer infer from item 5 when `floor` runs. It now runs for a self-merge brief without `--approved`, which is `check_line`'s `sm`. Item 3's "for each self-merge brief" has the same gap.

**Recommendation:** Optionally change it to "under every authority, and its S rules (a self-merge brief without --approved) run floor only on a path they pass". Combine this with F2's header edit so the header is touched once.
**Legibility-target:** lib header, gate caller contract items 3 and 5.

## What Looks Good

- **One authority value with one rule decision.** `check_line` turns `AUTH` and the policy into a single local, `sm`, that drives both the checkout check and the S rules (lines 982, 1024, 1027, 1042). `--check` (empty `AUTH`) keeps its old behaviour by construction, and the fact-check confirms it.
- **Authorisation is separate from landing.** `approval` runs before `land`, and `land` stays independent of the authority except for the message text. A future authority adds a branch in the merge arm and a word in `land`, not new logic inside the landing path.
- **approval belongs in build-loop.sh.** It compares against `VERDICT`, which is build-loop's data model, and the slug shape is build-loop's convention. The lib supplies only the generic, main's-commit-only answer reader. Moving `approval` into the lib would make the lib depend on build-loop's verdict shape. The only part that might later belong in the lib is the slug computation, and only if the filer lives in another script (F1).
- **The answer has one reader.** `--approved` goes through the lib's `check_answer` rather than a second parser, so D8 (main's commit only) and the fence, dup and quoted refusals carry over unchanged. `dev-cycle.sh --check-answer`'s output is unchanged.
- **The gate bit is computed from the batch-lowered `lps`.** No extra fork is needed, and the lower-casing rule is the same one the N and S rules use.
- **floor's words.** The `floor` / `floor_why` split matches `entry_why` and `walk_why`. srules does the wording at its single call site. The `*)` fallback in `floor_why` keeps an unknown word visible rather than silent. `check_fix` no longer reaches into `IMPORT_READER_WHY`, which removes a cross-script duplicate of the readers sentence (rows 630, 634).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | The approval heading contract has one checker and no shared producer; `--check` does not expose the gate bit or the slug | Minor | `scripts/build-loop.sh:1070-1084`, `:1041` | Medium |
| 2 | ANSWER_HEAD side channel contradicts the lib header's `out="$(...)"` capture rule; the exception is recorded only at the function | Minor | `scripts/lib/dev-cycle-read.sh:31-34`, `:2064-2096` | High |
| 3 | Authority passed as an implicit global to check_line and as arguments to land; land's message and trailer key on different inputs | Minor | `scripts/build-loop.sh:982`, `:1100-1103`, `:1168-1169` | High |
| 4 | GATE_CODE tested at two necessary sites; floor's comment suggests `FLOOR_WHY==gate` as the test | Informational | `scripts/lib/dev-cycle-read.sh:1924-1925` | High |
| 5 | Plan D4 lists skills/dev-cycle/ as gate files; GATE_CODE and D5 do not | Informational | `docs/working/plan-build-loop-handoff.md:61` | Medium |
| 6 | TRUTH_WHERE is a sentence while FLOOR_WHY and TRUTH_WHY are words | Informational | `scripts/lib/dev-cycle-read.sh:1888-1895` | Medium |
| 7 | Gate caller contract items 3 and 5 describe policies, not authorities | Informational | `scripts/lib/dev-cycle-read.sh:64-65`, `:78-87` | Medium |

## Overall Assessment

The change keeps the system's structure intact. Dependencies still run one way, from build-loop.sh and dev-cycle.sh into the lib. The new authorisation step is a separate function between the verdict and the landing, which is the right seam. `AUTH` is a workable single authority value. Its weak points are about how it travels, not where it lives: an implicit global into `check_line`, arguments into `land`, and two `land` inputs that must agree (F3). Each fix is small and local. The most important concern is F1: the `merge[-gate]-STEM-SHA12` heading is now a cross-party contract with a checker and no shared producer. It is cheapest to settle before the orchestrator's filer is written. The lib header needs one sentence for `ANSWER_HEAD`'s exception to the capture rule (F2) and, optionally, an authority-aware wording in contract items 3 and 5 (F7). Nothing calls for restructuring. One note for the security reviewer, not a finding here: questions-file text on main's commit flowing into `approval()` is a new trust-boundary crossing. The latest security review's map (u3a2-confirm2, Commit `2028aa89`) does not label it.

## Goal-Alignment Note

Success criterion (verbatim): "a report saved to /workspace/.claude/wt-build-loop-u3a3/docs/reviews/architecture-review-2026-10-10-u3a3-i1.md, structured per the architecture-review skill (severity Structural / Coupling / Minor / Informational), with `Commit: a7a4f784` at the top."

This report is at that path. It opens with `Commit: a7a4f784` and follows the skill's layout: Dependency Map, Findings with Severity, Location, Move and Confidence plus verbatim evidence and a Legibility-target, What Looks Good, Summary Table, and Overall Assessment. It covers the requested focus areas:
- `AUTH` as the seam: F3 and What Looks Good.
- The `ANSWER_HEAD` side channel versus the header's capture rule: F2.
- Whether approval belongs in build-loop.sh or the lib: What Looks Good and F1.
- The floor word/wording split and `TRUTH_WHERE` against the `walk_why` / `entry_why` / `truthrule` patterns: F6 and What Looks Good.
- Whether the gate caller contract needs updating: F7. It does not for correctness; an optional wording change is suggested.
- `GATE_CODE` tested at two sites: F4. Both sites are needed, the definition is single, and floor's comment needs a reword.

No Structural or Coupling findings. Nothing was committed.
