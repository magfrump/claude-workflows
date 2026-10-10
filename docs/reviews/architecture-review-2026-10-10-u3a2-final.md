# Architecture Review — feat/build-loop-u3a2 (final confirming pass)

**Scope:** `git diff main...HEAD -- scripts test` at HEAD `6cbca87c` (`scripts/build-loop.sh`, `test/scripts/build-loop-merge.bats`), plus the branch's five commit messages
**Date:** 2026-10-10
**Based on:** the Stage 1 summary of `docs/reviews/code-fact-check-report-u3a2-final-r{1,2,3}.md` (k=3 at `6cbca87c`), `docs/reviews/architecture-review-2026-10-10-u3a2-i{1,2}.md`, and override rows 653 to 666 plus 215, 494, 501, 509, 512, 524, 613, 625, 639, 642 and 646

**Scope check:** in scope. The branch adds a mode (`--merge`) and a public output line (`merged BRIEF TIP TREE NEW`). It adds a persisted data contract: the merge commit's subject, its `Build-loop-gate:` trailer and its reflog text, which U3b's `--main-log` will read. It changes `check_line`'s contract so the function also leaves its verdict as values (`VERDICT`, `CHANGED`). It adds a cross-cutting execution context: git now also runs in a second working tree, W. The test file is read for structure only.

**Trust-boundary cross-reference:** the scan found `docs/reviews/security-review-2026-10-10-u3a2-i2.md` (Commit: `f782d9ee`). That commit is neither HEAD nor the review base, so the security review predates this diff and its boundaries may be stale. Finding 1 sits on its `B4` ("worktree admin dirs → worktree list -z; head-name/BISECT_START scan, dot globs → CAS-vs-ff choice"). Its recommendation keeps the crossing where it is and only makes it stricter.

## Dependency Map

```
merge arm ── gate_start (default_gate, gate_repo, store_check, settings) ── check_line ──(VERDICT, CHANGED)──┐
   │                                                                                                         │
   ├─ policy check (self-merge only; U3a3 adds --approved here)  ◄───────────────────────────────────────────┘
   └─ land AUTHORITY
        ├─ merge_ident            (caller's global config via CALLER_GLOBAL; exports GIT_{AUTHOR,COMMITTER}_*)
        ├─ discover W             (git worktree list --porcelain -z)              ┐ two enumerations of
        ├─ rebase/bisect scan     (glob of $common and $common/worktrees/*, files) ┘ the same worktree set
        ├─ W checks               (state_gate in W, rev-parse, --git-path probes, status, CHANGED's A paths)
        ├─ write                  (gate_git commit-tree into the real object store)
        ├─ re-gate                (state_gate, default_gate, state_gate in W; row 494)
        └─ move                   (update-ref CAS | merge --ff-only in W)
```

Dependencies point one way. `check_line` produces values and knows nothing about landing. `land` consumes `VERDICT` and `CHANGED` and reuses the existing gates (`state_gate`, `default_gate`, `gate_git`). Nothing depends on `land` except the merge arm. The authority now enters `land` as an argument (`land self-merge`, `:1143`). Both the subject (`:1095`) and the reflog message (`:1044`) are built from it, so U3a3 can call `land "approved Q-NNN"` without editing `land`. The run has three execution contexts:

- the real repository, for reads and the CAS;
- the gate repository, for merge computations and commit-tree;
- W, for its own state gate, its checks and the fast-forward.

### Status of the i2 architecture findings

| i2 # | Disposition | Verified status at `6cbca87c` |
|---|---|---|
| 1 (land labels every commit "self-merge") | Fixed (D3) | **Resolved.** `land AUTHORITY` builds both `msg` (`:1044`) and the subject (`:1095`) from `$1`. The arm passes `self-merge` (`:1143`). |
| 2 (trailer literal is U3b's contract) | Row 662, Defer | Stands. One writer, and the trigger is U3a3 or U3b. Not re-filed. |
| 3 (land's split neither done nor rowed) | Row 663, Defer | Stands. Now rowed. Not re-filed. |
| 4 (verdict_ok writes check_line's `i`) | Fixed (D3) | **Resolved.** `local i` is at `:991`. |

## Findings

#### 1. land enumerates the worktrees twice, from two sources that can disagree, and treats "cannot see" as "absent" in both

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1048-1068` (enclosing `land`, `:1043-1122`, read in full)
**Move:** 7 (coupling surface: two sources of truth for one fact), 3 (module boundary: git's on-disk admin layout read as data)
**Confidence:** High (the behaviour is from the fact-check's executed probes; the structural reading is this review's)
**Legibility-target:** for-author

**Evidence:**
```
1048:  git worktree list --porcelain -z > "$GATE_TMP/wts" || { MERGE_WHY="the worktrees could not be listed"; return 1; }
1058:  common="$(git rev-parse --path-format=absolute --git-common-dir)" || { MERGE_WHY="the git directory could not be found"; return 1; }
1059:  for d in "$common" "$common"/worktrees/* "$common"/worktrees/.[!.]* "$common"/worktrees/..?*; do
1060:    [[ -d "$d" ]] || continue
1062:    for q in rebase-merge/head-name rebase-apply/head-name rebase-merge/update-refs; do
1063:      [[ ! -e "$d/$q" ]] || { [[ -r "$d/$q" ]] && ! grep -qxF "refs/heads/$MAIN" "$d/$q"; } \
1066:    [[ ! -e "$d/BISECT_START" ]] || { [[ -r "$d/BISECT_START" ]] && [[ "$(<"$d/BISECT_START")" != "$MAIN" ]]; } \
(excerpt ends inside the loop; the remainder is the bisect refusal at :1067 and `done` at :1068)
```

`land` asks two questions about the same set of worktrees. Which one has main checked out decides between the CAS and the fast-forward. Whether any of them is rebasing or bisecting main decides whether to refuse. It answers them from two different sources. The first comes from `git worktree list`, which silently leaves out a worktree whose admin dir it cannot read. The second comes from a filesystem glob, whose `-e` test reads a file inside an unsearchable directory as absent. The fact-check (r2, r3, executed) shows the consequence. With `.git/worktrees` or W's admin dir at mode 000, the list exits 0 without W, and `land` moves main by CAS under a worktree that still has main checked out. With rebase or bisect state that is a directory, or that sits under an unsearchable `rebase-merge/`, a rebase of main reads as no rebase. This is planted state, not a race, so it falls outside the Q-103 residuals. Whether it is a correctness or security finding is for those reviewers to say. The structural point is that nothing ties the two enumerations together, so a gap in either source goes unnoticed. The header's promised refusal ("the worktrees or the git directory cannot be read", "or that state cannot be read") has no single place to live. This also matters for row 663's trigger: when U3d or U3b reuses worktree discovery, it will inherit whichever of the two sources it copies.

**Recommendation:** Make one enumeration the authority and check the other against it. One way is to have the glob loop also refuse when an admin dir it finds is not searchable or readable (`[[ -x "$d" && -r "$d" ]]`, and the same for a `rebase-merge/` that exists). It should also refuse when the state path exists but is not a regular file. Then, for each `$common/worktrees/*` admin dir, require a matching `worktree` record in the list (or compare the counts). Either change keeps `B4`'s crossing where it is and only closes its "cannot see" arm. **Security implication:** this tightens `B4` (`docs/reviews/security-review-2026-10-10-u3a2-i2.md`, Commit: `f782d9ee`; the security review predates this diff, so the boundary may be stale). It does not move the boundary. The security reviewer should confirm that the refusal set is complete.

#### 2. The script's repository rule names land's writes but not its reads in W, the third execution context

**Severity:** Informational
**Location:** `scripts/build-loop.sh:903-909` (gate_start's comment); `:1073-1081` (land's reads in W)
**Move:** 4 (layer and context: which repository each git call runs in)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
904: # and refs, the branch tips, the checkout and store_check's object reads are
905: # in the real repository; the merge computations (merge-base, merge-tree,
906: # diff-tree, the blob checks) and --merge's commit-tree run through gate_git
907: # (into the real object store). --merge moves the branch in the real
908: # repository (update-ref) or in W (merge --ff-only), and merge_ident alone
909: # reads the caller's global config.
1073:    (cd "$w" && state_gate) > "$GATE_TMP/state" || { MERGE_WHY="$in fails the state gate ($(head -n 1 "$GATE_TMP/state"))"; return 1; }
```

The repository rule is the script's cross-cutting invariant: each git call says which repository it trusts. `--merge` adds W as a third context. The rule names W only for the fast-forward. W's state gate, the `rev-parse` and `--git-path` probes, and `git status` are not named. Nor are the real repository's `worktree list` and `--git-common-dir` calls, or `git var` (fact-check r3, "Mostly accurate"). U3b's `--state` is planned to take one snapshot of "the caller's environment and repo state" (row 666). It will need to know every context a decision reads, and the rule is where a reader looks for that.

**Recommendation:** Add one clause to the rule, for example: "and in W, its state gate, top level, HEAD, in-progress state and status". Also name the real-repository worktree list and `git var`. No code change.

## What Looks Good

- **Authority as an argument.** `land self-merge` closes i2 finding 1 in the cheapest way. The label `land` writes is again true where it is written. U3a3's `--approved` becomes one more `elif` in the arm (`:1142-1143`) plus a different argument, with no edit to `land`.
- **Decide, write, re-gate, move** is still the shape of `land`. Every refusal that reads the repository or W happens before `commit-tree`. The re-gate (row 494) is the last step before either move.
- **W's state gate now runs before any `git status` in W** (B1). Running the existing `state_gate` from W's directory reuses the gate as it is instead of adding a W-specific variant. The common checks run twice, which is harmless.
- **Values, not text, between check and land.** `VERDICT` and `CHANGED` are written only by `verdict_ok`, only on an ok line, and are reset at the top of `check_line`. That was row 512's request. `--check` is unaffected.
- **Identity is isolated.** `CALLER_GLOBAL` is captured between `harden` and the `GIT_CONFIG_GLOBAL=/dev/null` export, and only `merge_ident` uses it. Every other git call still reads no global config.
- **Tests stay hermetic and contract-shaped.** The new suite loads the shared fixtures, builds throwaway repos, and injects faults through a PATH shim rather than hooks in the script. That keeps the script free of test-only seams, which was row 613's concern.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Worktrees enumerated twice (worktree list for W, file glob for rebase/bisect) with no cross-check, and "cannot see" read as "absent" in both; fact-check r2/r3 show a CAS under W and a rebase of main landing | Minor | `scripts/build-loop.sh:1048-1068` | High |
| 2 | The repository rule omits land's reads in W and the real repository's worktree list and `git var` | Informational | `scripts/build-loop.sh:903-909` | High |

## Overall Assessment

The branch keeps the script's structure intact. Dependencies run one way: from check to values to land to move. The four i2 findings are resolved (1 and 4) or stand on override rows (662 and 663). The new authority argument removes the one place where `land`'s output depended on its caller's check. Nothing here is Structural or Coupling. The one finding worth acting on before the merge is finding 1. It has the same root cause as the fact-check's two "Incorrect" claims: `land` reads the same set of worktrees from two sources, and neither treats an unreadable entry as a refusal. Fixing it in one place, either with a searchability check in the glob or a cross-check against the list, closes both claims and gives U3b and U3d one discovery routine to reuse. The amber inventory from this lens is finding 1 (Minor, which maps to 🟢 Consider in the rubric, but it is the architectural side of two fact-check Incorrects that probably rate higher in the security or fact-check lens) and finding 2 (documentation only).

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/architecture-review-2026-10-10-u3a2-final.md, structured per the architecture-review skill.
- Answered: whether the whole branch keeps the script's dependency direction and module boundaries (yes); whether i2's four findings are resolved or rowed (two fixed, two rowed); which new structural items remain for the amber inventory (findings 1 and 2); the coupling that U3a3, U3b and U3d inherit (`land AUTHORITY` is ready for U3a3; the trailer is row 662; worktree discovery is finding 1 and row 663).
- Out of scope: whether the fail-open in finding 1 is a security finding and how severe it is (security-reviewer and fact-check); the empty-email identity (`<>`) and the "NEW unreachable" wording (fact-check r1); the BISECT_START `-r` mutant gap (test strategy); the Q-103 race residuals (rows 509 and 646); settled override rows.
- Escalate: none from architecture alone. If the security lens rates the fact-check's r2/r3 Incorrects as Must Fix, finding 1's recommendation gives a single fix point for both.
