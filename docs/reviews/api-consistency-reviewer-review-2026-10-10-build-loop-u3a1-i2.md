Commit: 83f75281

# API Consistency Review — feat/build-loop-u3a1 (iteration 2, fix range)

**Scope:** `git diff 65007bf8..83f75281` (docs/reviews excluded): `scripts/build-loop.sh`, `test/scripts/build-loop-check.bats`, `docs/working/plan-build-loop-handoff.md`. Public surface: `--check`'s refusal lines and `--help` header; internal API: `STATUS`/`BRIEF` as `status_fields` leaves them (U3a2's consumer).
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-build-loop-u3a1-i2.md` (0 Incorrect; stale: state_gate's header comment omits alternates); iteration 1 report and rubric (`code-review-rubric-2026-10-10-feat-build-loop-u3a1.md`, C4/C5/C9).

## Baseline Conventions

Unchanged from iteration 1 (see `api-consistency-reviewer-review-2026-10-10-build-loop-u3a1.md`): state refusals are `refuse state WHAT: WHY`, exit 2, before any verdict, WHAT a git path (`info/attributes`, `info/grafts`, `shallow`) or concept noun (`gate`, `objects`, `default-branch`); per-brief refusals are `refuse BRIEF: WHY`, naming the branch as `the tip of BRANCH` / `the merge of BRANCH` (`scripts/build-loop.sh:550`, `:881-908`); each per-brief verdict is the brief's own ("per brief path, in argument order, one verdict line", help `:108-109`); the help describes each refusal and quotes fixed per-brief texts verbatim.

## Name-Pattern Audit

| New / changed name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `refuse state objects/info/alternates: present and not an empty file` | output line (state refusal) | `refuse state info/attributes: ...`, `refuse state info/grafts: ...`, `refuse state shallow: ...` | `scripts/build-loop.sh:306-308` | Consistent — same loop, same WHAT-as-git-path form and WHY; WHAT shares the prefix `objects` with `refuse state objects:` (Finding 3) |
| `refuse state objects: ... does not hash to its id, has a second copy in the object store, or could not be read` | output line (state refusal) | iteration 1's text; `refuse state gate: its merge repository could not be set up` | `scripts/build-loop.sh:853-854` | Consistent — one added clause, the "could not be read" tail kept |
| `refuse BRIEF: an object of the tip of BRANCH or of the merge does not hash ..., has a second copy in the object store, or could not be read` | output line (per-brief refusal) | "the tip of $br is ...", "the merge of $br names a blob ...", skip "the tip of $br starts ..." | `scripts/build-loop.sh:550,881,886,908` | Consistent — iteration 1 Finding 1 fixed; help quote at `:126-128` matches runtime verbatim. Its scope claim is not what is checked (Finding 1) |
| `GATE` | global flag | `POLICY`, `MODE`, `OPEN_SHARED` | `scripts/build-loop.sh:340` | Internal; set-or-empty flag, used only in the next two lines. No finding |
| `$GATE_TMP/checked` | internal file | `$GATE_TMP/err` | `scripts/build-loop.sh:590` | Consistent with GATE_TMP's per-run scratch use |

## Findings

#### 1. A second copy found under one brief also refuses every later brief in the same run, each in its own name

**Severity:** Minor
**Location:** `scripts/build-loop.sh:614-641` (store_check's duplicate scan over all of `$GATE_TMP/checked`), `:911` (the per-brief refusal), help `:126-132`
**Move:** 3 (consumer contract), 4 (error consistency)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
      exit($n ? 0 : 1)' >> "$GATE_TMP/checked" || return 1  # REV^{tree} is never skipped, so 0 read is a fault
  ...
  } | awk 'FILENAME != "-" { want[$0]; next } ($0 in want) && n[$0]++ { bad = 1 } END { exit bad }' "$GATE_TMP/checked" -
}
  if ! store_check "$sha" "$tree"; then echo "refuse $a: an object of the tip of $br or of the merge does not hash to its id, has a second copy in the object store, or could not be read"; return; fi
```
perl appends every id that re-hashed correctly to `checked` before the duplicate scan runs, and the scan tests every id in `checked`, not this call's. So when brief X fails on a second copy of one of its own objects, that id stays in `checked`, and each later brief's scan finds it again. Probed (scratch bats, fixture repo; feat/x's work blob packed plus a loose copy):
```
y alone: 0
ok docs/working/briefs/2026-10-01-y.md 41ba79b1... 36284b81...
x then y: 2
refuse docs/working/briefs/2026-10-01-x.md: an object of the tip of feat/x or of the merge does not hash to its id, has a second copy in the object store, or could not be read
refuse docs/working/briefs/2026-10-01-y.md: an object of the tip of feat/y or of the merge does not hash to its id, has a second copy in the object store, or could not be read
```
Brief y's verdict depends on what else is on the command line, and its refusal asserts a fault in "the tip of feat/y or of the merge" that is not there. That breaks the help's per-brief verdict contract (`:108-109`) and the refusal's own scope claim, and a quoted refusal (D4: "the refusal quoted in the entry") would send the reader to the wrong branch. It fails closed and `--merge` (one brief) is unaffected, hence Minor. A hash mismatch does not cascade (the bad id is never appended); only the second-copy clause does. A second copy of a main object or an earlier brief's object that appears mid-run (a race) is reported the same way, under the current brief's name.

**Recommendation:** Scan for second copies over this call's own ids (the full list before the skip filter, kept in a per-call file), so main's ids and earlier briefs' are rescanned only as part of this brief's objects; or keep the run-wide scan and word the refusal to match ("an object the gate has checked has a second copy ..."). Add the two-brief case to the re-hash test.

#### 2. state_gate's header comment omits the new alternates file

**Severity:** Informational
**Location:** `scripts/build-loop.sh:290-292`
**Move:** 3 (documentation drift)
**Confidence:** High
**Legibility-target:** for-author

Evidence:
```
# changes merges or history), a ref under refs/replace/, and an origin/HEAD naming any branch but
  for f in info/attributes info/grafts shallow objects/info/alternates; do
```
The comment's file list still reads "an info/attributes, info/grafts or shallow that is not absent or an empty regular file"; the `--help` header (`:97-98`) and the loop name `objects/info/alternates`. This is the fact-check i2's stale item, repeated only because the comment is the contract U3b's `--state` caller reads ("U3b's --state calls both").

**Recommendation:** Add "objects/info/alternates (another object store)" to the comment's list.

#### 3. `refuse state objects:` and `refuse state objects/info/alternates:` share a WHAT prefix

**Severity:** Informational
**Location:** `scripts/build-loop.sh:306`, `:854`
**Move:** 2 (naming), 4
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Precedent: WHAT is the git path `--git-path` resolves, used in `scripts/build-loop.sh:306-308` (`info/attributes`, `info/grafts`, `shallow`)

Evidence:
```
    if [[ -s "$p" || -L "$p" || ( -e "$p" && ! -f "$p" ) ]]; then echo "refuse state $f: present and not an empty file"; bad=1; fi
  store_check "$MAIN_SHA" || { echo "refuse state objects: the default branch's commit ...
```
The alternates WHAT follows its loop's precedent exactly, so this is not a deviation. Noted only because the `:` delimiter is what separates the two; a consumer matching the prefix `refuse state objects` (without the colon) catches both. No consumer outside `docs/reviews/` matches either text today (grep over the worktree).

**Recommendation:** None required; consumers should match `refuse state WHAT:` with the colon.

## What Looks Good

- **Iteration 1 Finding 1 fixed:** the per-brief refusal now says "the tip of BRANCH ... the merge", matching every sibling; the help quote (`:126-128`) and the test string (`build-loop-check.bats`, re-hash test) carry the same text verbatim.
- **Both refusals gained the same clause** ("has a second copy in the object store"), so the state and per-brief refusals still read as one condition at two scopes, and both keep the family's "could not be read" tail. The help's state paragraph adds the gloss "(two packs, or loose and packed: git may read either)", which explains the clause without changing the runtime text.
- **The alternates refusal** reuses state_gate's file loop, so it gets the same WHY, the same "its path could not be read" failure, the same exit and ordering; the help lists it with the other files and the state-file test pins its line in sequence.
- **STATUS/BRIEF shapes now documented (iteration 1 Findings 3-4):** the comment at `:504-513` states bare values, `-` sentinels for branch/sha/date, empty reason, `ahead` 0 when absent, only `line` on a skip line, and BRIEF emptied per call. Checked against `status_fields` (`:515-563`): every return path matches (new brief: full sentinel set, BRIEF empty; check_brief skip: line only, BRIEF empty; skips after brief_fields: line only, BRIEF holds this brief's lines, as "what brief_fields read for this brief" says).
- **iteration 1 Findings 5-6 fixed:** the plan's as-built note records the startup state refusal, row 625's removal and row 512's move to U3a2; ls-tree's stderr is dropped and the missing-tree case now asserts empty stderr.
- Exit codes unchanged; no consumer outside `docs/reviews/` and the help/tests references the changed refusal texts.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | A second copy under one brief refuses every later brief in the run, each blamed on its own tip | Minor | `scripts/build-loop.sh:614-641, 911` | High |
| 2 | state_gate header comment omits objects/info/alternates | Informational | `scripts/build-loop.sh:290-292` | High |
| 3 | `objects` and `objects/info/alternates` WHATs share a prefix | Informational | `scripts/build-loop.sh:306, 854` | Medium |

## Overall Assessment

The fix batch resolves iteration 1's API findings: the per-brief wording matches the house form, the help states both changed refusals verbatim or faithfully, and STATUS's documented shapes match every path of `status_fields`. The new alternates refusal fits the state-file family exactly. One behavioral inconsistency is new: the second-copy scan is run-wide while its refusal is per brief, so in a multi-brief `--check` a duplicate under one brief refuses every later brief under that brief's own name (probed). It fails closed and does not touch `--merge`'s single-brief path, but it breaks the per-brief verdict contract; a per-call id list fixes it in place. Nothing is Breaking.

## Goal-Alignment Note

**Success criterion (restated verbatim):** "a markdown report saved at the path your dispatch names, structured per your skill."
**Answered:** Yes. Saved at `docs/reviews/api-consistency-reviewer-review-2026-10-10-build-loop-u3a1-i2.md` with `Commit: 83f75281` at the top, structured per the api-consistency-reviewer skill (baseline, name-pattern audit, findings with Severity/Location/Evidence/Confidence/Legibility-target, summary table, assessment). The dispatch's focus areas are covered: the changed refusal texts (audit rows, Finding 1, 3), the help header's statements (What Looks Good, Finding 1), and STATUS's documented shapes (What Looks Good, checked path by path).
**Out of scope:** Whether one copy per id is sufficient against forged packs (pack .idx offsets, multi-pack-index, delta bases): security's question per the brief's item 1; performance of the run-wide scan.
**Escalate:** None blocking. Finding 1 → for-author (one fix plus a two-brief test case); Finding 2 → for-author; Finding 3 → for-orchestrator-synthesis.
