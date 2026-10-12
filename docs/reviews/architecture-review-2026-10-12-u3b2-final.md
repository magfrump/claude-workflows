Commit: 4afdd68b

# Architecture Review — feat/build-loop-u3b2 (final confirming pass)

**Scope:** full branch `main...HEAD` (main b5f21758, HEAD 4afdd68b): `scripts/build-loop.sh` (`gate_msg`, `clean_merge`, `ANSWERS_AWK`, `log_class`, `main_log`, the `--main-log` dispatch and header), `scripts/lib/dev-cycle-read.sh` (ANSWER_AWK back-pointer), `test/scripts/build-loop-orchestrator.bats` (T39), the plan's U3b2 "As built" note and the eleven 2026-10-12 override rows for this branch (the U4 data contract). Read against `merge_result`/`check_line`/`land`/`state_start` in the same script.
**Date:** 2026-10-12
**Based on:** stage-1 merged summary of `docs/reviews/code-fact-check-report-2026-10-12-u3b2-final-r{1,2,3}.md` (no behavioural Incorrect; two text Incorrect in override rows 726 and 728, which are fact-check's, not re-filed here). Prior: `architecture-review-2026-10-12-u3b2-i1.md` (findings 1-5, ruled as rubric D6, D8, D10, D7, D13).

Scope check: in scope. The branch adds a public CLI mode with an output and exit contract U4 will consume, a persisted-data contract read back from history (the gate merge message and tree, the chore subject and record line, the questions-file answer grammar), and one shared writer/reader definition (`gate_msg`). The new structure since iteration 1 is `clean_merge` (cca66dc2, moved after the subject in 4afdd68b).

Ruled findings rechecked, not re-filed: i1-1 (D6, comments both ways: `dev-cycle-read.sh:2019-2020` and `build-loop.sh:1609-1610` — present and accurate), i1-2 (D8, row 724), i1-3 (D10, row 725 and the "one Branch: line per iteration" clause in row 719), i1-4 (D7, the gate_msg comment at `build-loop.sh:1368-1373` names log_class and the in-window reclassification — present and accurate), i1-5 (D13, row 726). The rulings' reasoning holds.

Probe: `bats -f main-log test/scripts/build-loop-orchestrator.bats` with `TMPDIR` under `/tmp/u3b2rv-archf-XXXX`, under `timeout 300`: both tests ok; temp dir removed.

## Dependency Map

- Dispatch `main-log` (`build-loop.sh:1714-1717`) → `state_start` (`:1220-1226`: default_gate, GATE_TMP, gate_repo, `store_check --main`) → `main_log` (`:1690`) → `log_class` (`:1649`) per first-parent commit, oldest first.
- `log_class` → `gate_git` for every read; → `clean_merge` (`:1644-1647`) for both two-parent classes; → `gate_msg` (`:1374-1377`) for gate; → `ANSWERS_AWK` (`:1612`) for answers.
- `land` → `gate_msg` (writer) and, via `check_line` (`:1268`), `merge_result` (`:1011-1021`) for the merge tree it commits.
- New in this pass: the reader's tree rule (`clean_merge`) is a second definition of "the merge land writes", beside `merge_result` (finding 1).
- Implicit contracts: ANSWERS_AWK ↔ the lib's ANSWER_AWK (pointers both ways); record name ↔ lib `writable` / `dev-cycle.sh` (row 725); the chore subject, `--no-ff`, default merge strategy and `Branch:` line ↔ U4's land (row 719).

Direction is sound: the mode depends on existing stable pieces and nothing existing depends on it; `land`'s switch to `gate_msg` is byte-identical (test 1 lands with `--merge` and reads `gate`).

## Findings

#### 1. The reader's "clean merge" is a second merge-tree definition beside merge_result, the one land's tree comes from

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1641-1647` (clean_merge); `:1007-1021` (merge_result); `:1268` (check_line's call)
**Move:** 7 (coupling surface), 3 (persisted contract: writer and reader of one fact)
**Confidence:** High
**Legibility-target:** whoever next changes how the gate computes its merge (a merge-base choice, an -X option, a rename limit in merge_result), who must know that every gate merge on main is re-derived by a separate merge-tree call in clean_merge

Evidence (verbatim):
- `:1017`: `  rc=0; out="$(gate_git merge-tree --write-tree --no-messages "$MAIN_SHA" "$1")" || rc=$?`
- `:1646`: `  t="$(gate_git merge-tree --write-tree --no-messages "${ps[0]}" "${ps[1]}")" \`
- `:1647`: `    && [[ "$t" == "$(LC_ALL=C awk '/^tree / { print $2; exit }' "$GATE_TMP/c")" ]]`
- `:1268`: `  tree="$(merge_result "$sha")" || rc=$?`

D7/row 662 made the gate *message* one definition so the writer and reader cannot drift. Iteration 1's fix (D1) then added a second persisted fact to the gate class, the *tree*, and gave it two definitions: land commits merge_result's tree, and log_class accepts the merge only if clean_merge's independent merge-tree call reproduces it. The two calls are identical today (same flags, same repository, same parent order: land's `-p "$MAIN_SHA" -p "${VERDICT[tip]}"` at `:1462` matches `ps[0] ps[1]`), so nothing is wrong now. But they are coupled by convention only: merge_result's comment does not mention the reader, and clean_merge's comment points to "--check's" merge-tree only for object writes. If merge_result ever gains an option that changes its output, every gate merge reads `other` and stops dispatch (fails closed, but each costs a judgment entry until someone traces it), exactly the drift gate_msg was introduced to prevent. The test pins agreement only for a tip based on main's tip (test 1: `--merge` right after `work feat/x`), where any merge strategy yields the tip's tree, so such drift would also go unseen by the suite. merge_result also guards what clean_merge does not (missing merge-base trees, a non-id first line); for the reader those all fail closed, so this is coupling, not correctness.

**Recommendation:** Generalise merge_result to take both sides (`merge_result OURS THEIRS`, check_line passing `"$MAIN_SHA" "$sha"`) and have clean_merge call it, so writer and reader share one merge definition as they share gate_msg; or, at minimum, add one line to merge_result's comment naming clean_merge as its reader. If deferred, an override row with the trigger "the next change to merge_result".

#### 2. clean_merge's inputs are log_class's local array and scratch file, and it splits log_class's comment from its body

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1632-1649`
**Move:** 4 (interface clarity), 3 (module boundary)
**Confidence:** High
**Legibility-target:** a reader scanning for log_class's documentation, and anyone who calls clean_merge from a second place (U3c's --cycle-diff or U4)

Evidence (verbatim):
- `:1632`: `# log_class C: --main-log's class of the first-parent commit C (gate, chore,`
- `:1641`: `# clean_merge: log_class's commit ($GATE_TMP/c, parents ps) has merge-tree's`
- `:1644`: `clean_merge() {`
- `:1649`: `log_class() {`
- `:1650`: `  local c="$1" ps=() m=() meta p x b q`

clean_merge takes no arguments: it reads `ps` through bash's dynamic scoping of log_class's `local`, and the commit text from the fixed scratch path `$GATE_TMP/c`. The comment states this honestly, so it is not a hidden dependency, but it makes clean_merge callable only from inside log_class (a call from anywhere else silently uses an unset `ps` and a stale file). Its placement between log_class's nine-line doc comment and `log_class()` means the comment headed "log_class C:" is followed by a different function. Both are small legibility costs in a 1,764-line script whose convention elsewhere is helper-above-caller with its own comment, which this mostly follows.

**Recommendation:** If finding 1 is taken, this disappears (clean_merge becomes `merge_result "${ps[0]}" "${ps[1]}"` compared with the tree inline). Otherwise move clean_merge and its comment above log_class's comment block, and pass the parents and tree as arguments (`clean_merge P1 P2 TREE`).

#### 3. The deferred shared answer-grammar fragment has no override row

**Severity:** Informational
**Location:** `docs/reviews/code-review-rubric-2026-10-12-feat-build-loop-u3b2.md` (D6 row); `docs/reviews/override-log.md:724`
**Move:** 7 (coupling surface — tracking of a deferred decoupling)
**Confidence:** High
**Legibility-target:** U3b3/U3c's author consulting the override log for what this unit deferred to the lib

Evidence (verbatim):
- rubric D6: `| D6 | Answer labels copied from the lib's ANSWER_AWK with no back-pointer | architecture 1 | Fixed (comments both ways); shared fragment deferred with D8 |`
- `override-log.md:724`: `| 2026-10-12 | `feat/build-loop-u3b2` | Three readers of `diff-tree --raw -z` (check_line, log_class's chore and answers loops) with different strictness; the whole-record rule lives in three places (i1 architecture 2) | 🟢 Consider (Minor) | Defer | Each fails closed today (the chore loop skips an unparsed record: no record, other). Revisit trigger: U3c's --cycle-diff, the fourth reader: one raw_records helper. |`

The rubric says the shared ANSWER_AWK/ANSWERS_AWK fragment is "deferred with D8", but D8's row (724) is about the raw diff-tree readers and names neither awk program nor the answer labels. The code side is fine (the comments both ways make the coupling discoverable from either file); only the deferral's revisit trigger is missing from the log the next unit reads.

**Recommendation:** Add a clause to row 724 (or a row of its own): "the answer labels and Status-blind header compare, shared by ANSWER_AWK and ANSWERS_AWK as one lib fragment the way FENCE_AWK is; trigger: the next change to --check-answer's labels".

## What Looks Good

- **gate_msg as one definition**, with a comment that now names its parser and the history consequence of a format change (D7 fixed well); land's call (`:1461`) passes `"${2-}"` so the self-merge path emits no approval line, byte-identical to before.
- **clean_merge after the subject** (4afdd68b): the expensive, store-writing step runs only on commits already shaped as gate or chore, which keeps the merge-tree cost and its object writes scoped to the two classes that need it.
- **Every read via gate_git**, so the mode inherits the existing no-repo-config, no-attributes boundary; no new trust crossing.
- **Fail-closed shape throughout:** `CLASS=other; SUBJ=-` first, every failed read `return 0`; one exit code (2) for other and refuse, with `main MAIN -` first so U4 always has main's SHA (D4).
- **The U4 contract is written down in one place each:** header (`:138-180`), plan "As built" note, and row 719 agree on the chore subject tail, mode 100644, default merge, and the per-iteration `Branch:` line.
- **Back-pointers both ways** for the answer labels (lib `:2019-2020`, script `:1609-1610`).

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Reader's clean_merge re-derives land's merge tree with a separate merge-tree call; writer/reader coupled by convention (same drift gate_msg removed for the message) | Minor | `scripts/build-loop.sh:1641-1647`, `:1007-1021`, `:1268` | High |
| 2 | clean_merge reads log_class's local `ps` and `$GATE_TMP/c`; sits between log_class's comment and body | Informational | `scripts/build-loop.sh:1632-1649` | High |
| 3 | Rubric's "shared fragment deferred with D8" has no override row or trigger | Informational | rubric D6; `docs/reviews/override-log.md:724` | High |

## Overall Assessment

The branch keeps the script's structure intact and improves it where it matters most: the merge message has one definition shared by writer and reader, every read goes through the gate repository, and the U4 contract is spelled out consistently in header, plan and override log. No Structural or Coupling findings. The one new structural point is that iteration 1's tree check (a correct security fix) re-introduced, for the merge tree, the two-definitions shape gate_msg removed for the message; it fails closed and is fixable in place by sharing merge_result, and it would also tidy finding 2. Nothing here blocks the merge.

## Goal-Alignment Note

Success criterion: "An architecture review saved to docs/reviews/architecture-review-2026-10-12-u3b2-final.md in the worktree, per the architecture-review skill." Met: saved at that path with `Commit: 4afdd68b` first, scope check, dependency map, three findings each with severity, location, move, confidence, verbatim evidence and a Legibility-target, what looks good, summary table and overall assessment. The brief's focus areas are covered: gate_msg (rechecked; What Looks Good), clean_merge (findings 1, 2), ANSWERS_AWK (finding 3, i1-1 recheck), log_class/main_log (dependency map, finding 2), the U4 data contract (What Looks Good; rows 719/725/726 not re-filed). Ruled findings were not re-filed; fact-check's text Incorrects (rows 726, 728) were left to the rubric. One probe ran under `/tmp/u3b2rv-archf-`, under `timeout`, and its directory was removed. Nothing in the worktree was written but this file.
