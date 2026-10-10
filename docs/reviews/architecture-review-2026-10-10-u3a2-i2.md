# Architecture Review — feat/build-loop-u3a2 (iteration 2, fix batch)

**Scope:** `git diff 7d78e6d0..f782d9ee -- scripts test` (the iteration-1 fix batch: `scripts/build-loop.sh` +118/-78 with the test file, `test/scripts/build-loop-merge.bats`); the rest of `main...HEAD` read as context only
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a2-i2.md` (28 claims, 22 verified, 6 mostly accurate), `docs/reviews/architecture-review-2026-10-10-u3a2-i1.md`, the rubric `docs/reviews/code-review-rubric-2026-10-10-feat-build-loop-u3a2.md` (C3, C4, C6, C7) and override rows 653 to 661

**Scope check:** in scope. The batch changes a public output contract (`merged BRIEF NEW TIP TREE` becomes `merged BRIEF TIP TREE NEW`) and moves a responsibility between functions (the policy refusal goes from `land` to the merge dispatch arm). It also changes when `CHANGED` is filled, which is part of `check_line`'s value contract, and reorders `land`'s side effects. The test changes are read for structure only.

**Trust-boundary cross-reference:** the scan found `docs/reviews/security-review-2026-10-10-u3a2-i1.md` (Commit: `7d78e6d0`, which is this pass's review base, so it is not stale). Finding 2 touches its `B6` ("verdict values from check_line → commit-tree in gate repo → update-ref CAS / ff → refs/heads/MAIN"). No finding recommends moving a crossing.

## Dependency Map

The call chain from i1 is unchanged except for two moves:

```
merge arm → gate_start → check_line ──(VERDICT, CHANGED)──→ [policy check: merge arm]  ← moved here from land
                                                              └→ land
                                                                  ├─ merge_ident (exports GIT_{AUTHOR,COMMITTER}_*)
                                                                  ├─ decide: worktree list, rebase/bisect scan, W checks (reads CHANGED)
                                                                  ├─ write: printf msg + gate_git commit-tree           ← moved after decide
                                                                  ├─ re-gate: state_gate, default_gate, (W) state_gate
                                                                  └─ move: update-ref CAS | merge --ff-only in W
```

Dependencies still point one way. `check_line` produces values and knows nothing about landing. `land` consumes the values and existing helpers, and nothing depends on `land`. `land` no longer reads `VERDICT[policy]`; only the merge arm does. The `CHANGED` fill moved inside `verdict_ok`, so both of `check_line`'s output values are now written by a single function.

### Status of the i1 architecture findings

| i1 # | Claim in rubric | Verified status |
|---|---|---|
| 1 (policy split) | C4: partly fixed, authority value deferred (row 653) | **Resolved as claimed.** The refusal is in the merge arm (`:1130`). `land` has no policy branch. The rule-set selector in `check_line` is still keyed on `pol` (`:983`, `:996`), as row 653 records. See finding 1 for the text that `land` still hard-codes. |
| 2 (land's order and size) | C3: fixed, decide/write/re-gate/move | **Order resolved.** Every refusal before `:1083` happens before the write. The commit write now checks the `printf` too. The **split** half of the recommendation was neither done nor rowed (finding 3). |
| 3 (line position) | C5: row 654 | Deferred by row 654, unchanged. Not re-filed. |
| 4 (CHANGED on refusals; verdict_ok comment) | C6: fixed | **Resolved.** `CHANGED` is filled only inside `verdict_ok` (`:989`), and the comment now reads "Reads check_line's locals (bash scope is dynamic); called only here", which is accurate. The new loop introduces a small dynamic-scope write (finding 4). |
| 5 (repository rule; identity export) | C7: fixed (comments) | **Resolved as documentation.** The gate_start rule now names commit-tree, update-ref, the W merge and merge_ident's global config (`:900-906`), and merge_ident's comment says the export lasts "for the rest of the run". The export scope was not narrowed. That is acceptable, because the only later git writes (update-ref and the ff) create no commit. |
| 6 (on-disk rebase scan) | C7: fixed (comments) | **Resolved.** `:1050-1052` gives the reason ("worktree list shows a rebasing worktree as detached"), and the scan now covers worktree ids that start with a dot. |

## Findings

#### 1. land is policy-free in logic but still writes "self-merge" into the commit and the reflog, so the label's truth now depends on the caller

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1039`, `:1083`, `:1130-1131`
**Move:** 2 (responsibility boundaries), 7 (coupling surface)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
1039:  local x w="" p q d common in="the worktree with the default branch checked out" msg="build-loop: self-merge of ${VERDICT[stem]}"
1083:  printf "Merge branch '%s' (build-loop self-merge)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "${VERDICT[stem]}" > "$GATE_TMP/msg" \
1130:    if [[ "${VERDICT[policy]}" != self-merge ]]; then v="refuse $a: the brief's policy is review; --merge lands only a self-merge brief"
1131:    elif land; then v="merged $a ${VERDICT[tip]} ${VERDICT[tree]} $NEW"; else v="refuse $a: $MERGE_WHY"; fi
```

In i1, `land`'s own first line guaranteed that every commit it wrote with "(build-loop self-merge)" really came from a self-merge brief. With the refusal moved to the arm, which is what i1 asked for, that guarantee is now a precondition on the caller. Only the comment "under an authority the caller checked (self-merge here)" states it. Today nothing is wrong, because the arm is the only caller and it checks first. But U3a3 is planned to "reuse land" for `--approved` merges. If it adds an `--approved` branch to the arm and calls `land` as it is, every approved review-brief merge goes into main's history and the reflog labelled as a self-merge. Nothing would fail, so no test would catch it. Row 653's revisit trigger already says U3a3 passes the authority "to the commit message/reflog text", so this is a refinement inside that row, not a new deferral. It is filed only because the fix changed the row's basis: the label used to be locally true and now it is not.

**Recommendation:** The cheapest version now is to give `land` the authority as an argument (`land self-merge`) and build both `msg` and the subject from it. U3a3 would then call `land "approved Q-NNN"` with no edit to `land`. If that is left to U3a3, add "land's message and reflog text" to row 653's U3a3 checklist explicitly.

#### 2. The merge commit's format is a data contract for U3b's `--main-log`, but it is defined only inside land's printf

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1083`; consumer planned at `docs/working/plan-build-loop-handoff.md:102`, `:208`
**Move:** 7 (coupling surface), 3 (module boundary)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
1083:  printf "Merge branch '%s' (build-loop self-merge)\n\nBuild-loop-gate: %s\n" "${VERDICT[branch]}" "${VERDICT[stem]}" > "$GATE_TMP/msg" \
plan:102: `gate` is a commit-tree merge with the trailer.
```

U3b's `--main-log` classifies a first-parent commit on main as `gate` by its `Build-loop-gate:` trailer. That makes the trailer key, and possibly the subject shape, a persisted contract between `land` (the writer) and `--main-log` (the reader) in the same script. U3a3 adds a second writer with a different authority. Today the format exists only as a literal inside `land` and as a literal assertion in the bats file (`build-loop-merge.bats:49-51`). This sits on `B6` from `docs/reviews/security-review-2026-10-10-u3a2-i1.md` (Commit: `7d78e6d0`). B6 ends in the ref move, and `--main-log`'s `gate` class is what will later tell an orchestrator that a commit on main came through this crossing. A drift between writer and reader would make honest gate merges read as `other`. A loose reader would let a hand-made commit read as `gate`, but that is plan F19's residual and belongs to security. This finding is not a security finding.

**Recommendation:** When U3a3 parameterizes the message (finding 1), define the trailer key once, for example `GATE_TRAILER=Build-loop-gate` beside `land`, or a `merge_message AUTH BRANCH STEM` helper, so U3b's `--main-log` reads the same constant. No change is needed in this unit.

#### 3. land's split (i1 finding 2's second half) was neither done nor recorded

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1038-1101`; rubric row C3
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
rubric C3: | land wrote the merge commit before deciding; the message write was unchecked. | architecture 2; security F4 | Fixed: decide, write (checked), re-gate, move. |
```
(override rows 653 to 661 contain no row for splitting land)

i1 finding 2 recommended two things: reorder, and split `land` into worktree discovery, W readiness, commit and move. The reorder is done and correct. The split is not, and the rubric marks the finding "Fixed" with no row for the rest. `land` is still one function of about 60 lines that produces 16 distinct refusals. The concrete cost is small. No planned unit has been shown to need a piece of `land` on its own: U3b's `--state` composes `state_gate` and `default_gate`, which are already separate functions, and U3a3 reuses `land` whole. So this is a traceability gap rather than a structural problem.

**Recommendation:** Add an override row (Won't-Fix or Defer, trigger "a second caller needs main's worktree or the rebase/bisect scan"), or amend C3 to "order fixed; split declined". Do not split now.

#### 4. verdict_ok's new loop writes check_line's loop variable `i` through dynamic scope

**Severity:** Informational
**Location:** `scripts/build-loop.sh:987-991` (enclosing `check_line`, `:932-1003`, read in full)
**Move:** 7 (coupling: content coupling through shared locals)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
935:  local a="$1" out st pol br sha tree meta p shown co stem rc=0 i nd=0 rows=() oms=() nms=() nos=() ss=() ps=() lps=() ids=()
987:  verdict_ok() {
988:    VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem")
989:    for i in "${!ps[@]}"; do CHANGED[${ps[$i]}]="${ss[$i]}"; done
990:    echo "ok $a $sha $tree"
991:  }
...
995:  for i in "${!ps[@]}"; do
...
1001:  if [[ -n "$co" ]]; then echo "$co"; elif [[ "$nd" -eq 0 ]]; then verdict_ok; else echo ...; fi
```

`verdict_ok` declares no `local i`, so its loop assigns `check_line`'s `i`. Both call sites are after `check_line`'s last use of `i`: the zero-path return at `:992`, and `:1001` after the per-path loop. So nothing breaks today. But reading the caller's locals was the documented contract. Writing one is a new, undocumented coupling. If `verdict_ok` is ever called inside the per-path loop, or before a later use of `i`, it silently changes the iteration. One plausible trigger is U3a3 adding an early ok for N-rules-only.

**Recommendation:** Add `local i` inside `verdict_ok`. The comment can stay as it is.

## What Looks Good

- **The authority check is now in the dispatch arm.** This is where i1 asked for it. U3a3's `--approved` becomes another branch in the arm's `if`/`elif` chain (`:1130-1131`) instead of an edit inside `land`.
- **Decide, write, re-gate, move.** Every check that reads the repository or W now runs before `commit-tree`. The re-gate (row 494) is still the last step before the move. The cost of a late refusal (an unreachable commit) is stated in the comment.
- **One writer for both output values.** `VERDICT` and `CHANGED` are now set together in `verdict_ok`, so `CHANGED` can no longer outlive a refusal. That makes `CHANGED` safe for U3a3's `merge-gate-` path test as well.
- **The output field order** (`merged BRIEF TIP TREE NEW`) now extends `ok BRIEF TIP TREE` by one field, so one parser prefix serves both lines.
- **The comments now match the structure.** The repository rule names every write site. The identity export says how long it lasts. The rebase scan says why it reads files. The usage check for `--merge` runs first, so all three malformed forms get the one `--merge` message, and the test loops over the three of them.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | land still labels every commit and reflog entry "self-merge", while the check that makes the label true now lives in the caller | Informational | `scripts/build-loop.sh:1039,1083,1130` | High |
| 2 | Commit format/trailer is U3b `--main-log`'s contract but exists only as a literal in land | Informational | `scripts/build-loop.sh:1083` | Medium |
| 3 | The split half of i1 finding 2 is neither done nor rowed (rubric C3 says "Fixed") | Informational | `scripts/build-loop.sh:1038-1101` | High |
| 4 | verdict_ok's loop writes check_line's `i` (no `local i`) | Informational | `scripts/build-loop.sh:987-991` | High |

## Overall Assessment

The fix batch resolves i1 architecture findings 1, 2 (the order), 4, 5 and 6 as the rubric claims, with the deferrals in rows 653 and 654 standing. It introduces no Structural or Coupling-level issue. The reorder adds no coupling. The policy move is the right structural step for U3a3, but it leaves one implicit precondition: the "self-merge" text that `land` writes is now true only because the arm checks first (finding 1). It is also the same text that U3b's `--main-log` will rely on to recognise gate merges (finding 2). The single most useful follow-up is to pass the authority to `land` as an argument, now or as an explicit item on row 653's U3a3 trigger. Then U3a3 can reuse `land` with no edit, and U3b has one trailer definition to read. Findings 3 and 4 are bookkeeping and a one-word fix. Nothing here blocks the merge.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/architecture-review-2026-10-10-u3a2-i2.md, structured per the architecture-review skill.
- Answered:
  - Whether the fixes resolved i1 architecture findings 1 to 6: see the status table. All are resolved or rowed, except the split half of finding 2 (finding 3).
  - New coupling for U3a3 from the merge-arm move: finding 1, and finding 4 as a hazard for an N-rules-only path.
  - New coupling for U3b: finding 2 (the trailer contract). The reorder adds none, since `--state` composes helpers that already exist.
- Out of scope:
  - Whether the A1, A2 and A3 security and correctness fixes work. The fact-check i2 verified them (claims 4b, 5, 19, 22 and mutants M1, M2), and they are not re-verified here.
  - The race residuals (Q-103, rows 509 and 646).
  - The reflog suffix wording on the W path (fact-check claim 3).
- Escalate: none. Finding 1 could be folded into row 653's U3a3 trigger text, and finding 3 needs a row or a rubric note.
