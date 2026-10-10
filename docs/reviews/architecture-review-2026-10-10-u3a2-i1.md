# Architecture Review — feat/build-loop-u3a2 (iteration 1)

**Scope:** `git diff main...HEAD` at 7d78e6d0: `scripts/build-loop.sh` (+165/-14), `test/scripts/build-loop-merge.bats` (new, 134 lines)
**Date:** 2026-10-10
**Based on:** `docs/reviews/code-fact-check-report-u3a2-i1.md` (Stage 1) and the shared review context (considered overrides rows 215, 494, 501, 509, 512, 524, 613, 625, 639, 642, 646)

**Scope check:** in scope. The diff adds a public CLI mode (`--merge BRIEF --expect SHA`), a new output line contract (`merged BRIEF NEW TIP TREE`), new cross-function values (`VERDICT`, `CHANGED`, `NEW`, `MERGE_WHY`, `CALLER_GLOBAL`), and the gate's first writes to refs and to a checkout. The test file is reviewed only for structure (the G17 shim).

**Trust-boundary cross-reference:** the most recent security review, `docs/reviews/security-review-2026-10-10-u2c2.md` (Commit: `3111ee9d`), predates this diff, so its boundaries may be stale. Its map (B1 to B6) covers the walk and the rules. None of the findings below sits on one of its labelled boundaries. The gate-repository rule (finding 5) is a trust split, but that map does not label it, and this review files no trust-boundary finding of its own.

## Dependency Map

Everything is still one script that sources `scripts/lib/dev-cycle-read.sh`. No module was added and the lib is unchanged. The new call chain is:

```
mode dispatch (merge) → gate_start → check_line ──(VERDICT, CHANGED globals)──→ land
                                                                                ├─ merge_ident → git var (real repo + CALLER_GLOBAL)
                                                                                ├─ gate_git commit-tree (gate repo; writes the real object store)
                                                                                ├─ git worktree list / $common/worktrees/*/… (real repo, on-disk layout)
                                                                                ├─ git -C W … (W's checks)
                                                                                ├─ state_gate, default_gate, (cd W && state_gate)
                                                                                └─ git update-ref (real) | git -C W merge --ff-only (W)
```

Dependencies point the right way. `check_line` knows nothing about `land`: it produces values, and `land` consumes them. `land` depends on the gate's existing helpers (`gate_git`, `state_gate`, `default_gate`), and no helper depends on `land`. The only new channel between the decision and the action is the pair of globals `VERDICT` and `CHANGED`, which is stamp coupling. Every other input to `land` is also implicit: `MAIN`, `MAIN_SHA` and `GATE_TMP` are globals and `land` takes no arguments.

## Findings

#### 1. The policy decision is split between check_line and land, and U3a3's `--approved` has to change both

**Severity:** Minor
**Location:** `scripts/build-loop.sh:971`, `:974`, `:1021`
**Move:** 2 (responsibility boundaries), 8 (extension points)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
971:  co=""; if [[ "$pol" == self-merge ]] && ! checkout_gate; then co="refuse $a: a self-merge brief needs --check run from a clean checkout ...
974:  [[ "$pol" != self-merge ]] || read_paths
1021:  [[ "${VERDICT[policy]}" == self-merge ]] || { MERGE_WHY="the brief's policy is review; --merge lands only a self-merge brief"; return 1; }
```
(also the message and reflog text, `land` lines 1023 and 1068: `"Merge branch '%s' (build-loop self-merge)\n\nBuild-loop-gate: %s\n"` and `-m "build-loop: self-merge of ${VERDICT[stem]}"`)

The question "what authorizes this merge, and which rule set judges it" is answered in two places, and both key on the brief's policy. `check_line` picks the rule set (S rules and checkout_gate) from `pol`. `land` refuses anything that is not self-merge, and it hard-codes "self-merge" in the commit message and in the reflog line. The plan (line 213) says that under `--approved` "only the N rules apply", whatever the brief's policy. U3a3 therefore has to do three things. It has to pass a rule-set control into `check_line`, which today derives the rule set from `STATUS[policy]` alone. It has to remove or bypass `land`'s first line. And it has to parameterize the message and trailer, for example to record Q-NNN. Today the land step works only because its one caller is self-merge.

**Recommendation:** Name the authority once, in the `merge` dispatch arm, as a value such as `AUTH=self-merge` or `AUTH=approved:Q-NNN`. Give it to `check_line` as the selector for the rule set, and to `land` for the message, trailer and reflog text. Then move the "policy must be self-merge" refusal from `land` into the dispatch arm, where U3a3 replaces it with `check_answer`. `land` becomes policy-free and can be reused unchanged.

#### 2. land has eight responsibilities and writes its commit before it decides

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1018-1075`
**Move:** 2 (responsibility boundaries)
**Confidence:** High
**Legibility-target:** for-author

**Evidence:**
```
1024:  x="$(gate_git commit-tree --no-gpg-sign -p "$MAIN_SHA" -p "${VERDICT[tip]}" "${VERDICT[tree]}" < "$GATE_TMP/msg")" \
1028:  git worktree list --porcelain -z > "$GATE_TMP/wts" || { MERGE_WHY="the worktrees could not be listed"; return 1; }
1065:  { state_gate && default_gate && { [[ -z "$w" ]] || (cd "$w" && state_gate); }; } > "$GATE_TMP/state" \
1068:    git update-ref -m "build-loop: self-merge of ${VERDICT[stem]}" "refs/heads/$MAIN" "$NEW" "$MAIN_SHA" 2>/dev/null \
1072:    git -C "$w" -c gc.auto=0 merge --ff-only -q "$NEW" > "$GATE_TMP/ff" 2>&1 || { MERGE_WHY="the fast-forward in $in failed"; return 1; }
```

The function is 58 lines and does eight jobs:
1. the policy check
2. identity
3. message and commit write
4. worktree discovery
5. the all-worktree rebase and bisect scan
6. W's preconditions
7. the state re-run
8. the move, by one of two strategies

It writes the merge commit (line 1024) before it runs the worktree and state checks (lines 1028 to 1066). So every refusal from those checks leaves an unreachable commit in the real object store. That is harmless for gc, but the order runs act, then decide, then act. Other upcoming units will probably need some of these pieces on their own. U3d's `--start` and U3b's `--state` may need "which worktree has main, and is any rebasing or bisecting it" (jobs 4 and 5). U3a3 needs the commit step with a different message (finding 1). Inside one function none of these pieces can be reused. Each refusal also has three copies to keep in step: the header, `land`'s comment and `MERGE_WHY`. The fact-check already found the header list missing six refusals (claim 3).

**Recommendation:** Split `land` into: `main_worktree` (jobs 4 and 5, sets W), `worktree_ready W` (job 6), `merge_commit MSG` (jobs 2 and 3), and `move_main` (jobs 7 and 8). Order the calls decide, then write, then move. Keep one list of refusals, in the comment of the function that owns each one, and have the header point to it rather than restate it.

#### 3. The merge arm assembles its output from text, while check_line now provides values

**Severity:** Minor
**Location:** `scripts/build-loop.sh:1093`, `:1102-1105`
**Move:** 7 (coupling surface)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
1093:      [[ "$(head -c 3 "$GATE_TMP/line")" == "ok " ]] || fails=1
1102:    if [[ -z "${VERDICT[tree]-}" ]]; then cat "$GATE_TMP/line"; exit 2; fi
1104:    { echo "$v"; tail -n +2 "$GATE_TMP/line"; }
```

The two consumers of `check_line` now read the ok verdict in different ways. `--check` tests the first three bytes of the text. `--merge` tests `VERDICT[tree]`. They agree today only because every `ok` line is printed through `verdict_ok`. The merge arm still depends on the text layout. Line 1104 assumes the verdict is exactly the first line and every later line is a path or deny row. That is what `check_line`'s comment promises (an ok or refuse line, "then" one row per path), but nothing enforces it. Row 512 was about retiring this kind of position parsing. The values replaced the field parsing (TIP and TREE), but the line position is still a contract.

**Recommendation:** Pick one signal. Either have `--check` test `VERDICT[tree]` too, or have `check_line` keep the verdict line in a value (for example `VERDICT[line]`) and the rows in an array, so the merge arm prints `v` and the rows without `tail`. If neither is done, state "the verdict is always line 1, exactly one line" as a contract item in `check_line`'s comment.

#### 4. CHANGED is filled on refusal paths, and the comment on verdict_ok's nesting is misleading

**Severity:** Informational
**Location:** `scripts/build-loop.sh:917-920`, `:948`, `:975-976`
**Move:** 3 (module boundary / encapsulation)
**Confidence:** High (the nesting point was probed: a function defined inside `check_line` still exists after `check_line` returns, and a function defined at top level sees `check_line`'s locals too)
**Legibility-target:** for-author

**Evidence:**
```
917:# The verdict as values (row 512), for --merge: VERDICT holds tip, tree,
918:# policy, branch and stem only after an ok line (empty otherwise), and CHANGED
919:# each changed path's status letter.
948:    ... ps+=("$p"); CHANGED[$p]="${ss[-1]}"
975:  # Defined here for its locals (bash function names are global).
976:  verdict_ok() { VERDICT=([tip]="$sha" [tree]="$tree" [policy]="$pol" [branch]="$br" [stem]="$stem"); echo "ok $a $sha $tree"; }
```

`CHANGED` is written while the diff is being read, before any verdict exists. After a refusal it can hold a partial list. VERDICT is guaranteed empty in that case and CHANGED is not. `land` is safe because it runs only when VERDICT is set, but a future reader of `CHANGED`, such as U3a3's gate-file test for the `merge-gate-` slug, has to know that rule. On the nesting: bash's dynamic scoping is what lets `verdict_ok` see `sha`, `tree` and the rest, and that works wherever the function is defined. Defining it inside `check_line` gains nothing beyond keeping the text close. The function is redefined on every call and stays callable from anywhere after the first one.

**Recommendation:** Fill `CHANGED` inside `verdict_ok` (from `ps` and `ss`), so both values exist only together with an ok verdict. Then either move `verdict_ok` to top level with a "call only from check_line" note, or reword the comment to "kept beside its one caller; it reads check_line's locals by bash's dynamic scope".

#### 5. The repository rule does not mention --merge's writes, and git var is a third config view

**Severity:** Informational
**Location:** `scripts/build-loop.sh:892-895`, `:310-312`, `:994-1001`
**Move:** 4 (layer violations / implicit layering)
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

**Evidence:**
```
892:# and the open briefs (once, in this shell). The repository rule: main's files
893:# and refs, the branch tips, the checkout and store_check's object reads are
894:# in the real repository; the merge computations (merge-base, merge-tree,
895:# diff-tree, the blob checks) run through gate_git.
```

The rule names reads only. `--merge` adds three writes, in three different places:
- `commit-tree` goes through `gate_git`, so no repo config reaches it (no `commit.gpgSign`, encoding or hooks), and it writes into the real object store.
- `update-ref` runs in the real repository.
- `merge --ff-only` runs in W, which reads W's own config once `state_gate` has passed there again.

`merge_ident` adds a third config view next to "the gate repository has no config" and "the real repository, hardened". It reads the real repository's config together with the caller's global file (`CALLER_GLOBAL`), and only for identity. Each choice has a reason in its own comment (lines 310 to 312, 994 to 997, 1071). But the one place that states the rule is now incomplete, and that rule is what a U3a3 or U3d author would consult to decide where a new git call belongs. `merge_ident` also exports `GIT_AUTHOR_*` and `GIT_COMMITTER_*` for the rest of the process, so W's `merge` and every later git call inherit them. Today that is harmless because the fast-forward writes no commit, but the scope is wider than "for commit-tree".

**Recommendation:** Extend the gate_start sentence: "writes: the merge commit through gate_git (no repo config); the branch move in the real repository, or in W after its state gate." Give the identity only to the `commit-tree` call, through `env` in front of `gate_git` or an `IDENT_ENV` array, instead of exporting it for the whole process.

#### 6. The rebase and bisect scan reads git's on-disk layout directly, while W's checks ask git

**Severity:** Informational
**Location:** `scripts/build-loop.sh:1035-1042` and `:1047-1050`
**Move:** 7 (coupling: content coupling to git internals)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
  for d in "$common" "$common"/worktrees/*; do
    ...
      [[ "$(cat "$d/$q/head-name" 2>/dev/null)" != "refs/heads/$MAIN" ]] || ...
    [[ "$(cat "$d/BISECT_START" 2>/dev/null)" != "$MAIN" ]] || ...
```
versus `x="$(git -C "$w" rev-parse --path-format=absolute --git-path "$q")"` for W.

The scan across all worktrees depends on git's private layout: `worktrees/<id>/`, `rebase-merge/head-name`, and `BISECT_START` holding a short name. W's checks go through `--git-path`. The fact-check probed this layout and confirmed it, and no porcelain command reports "rebasing branch X" (porcelain shows the worktree as detached), so the direct read is a pragmatic choice. The cost is two methods for the same kind of question, and a git layout change would break only the scan.

**Recommendation:** Keep the direct read, but add a one-line comment saying why (porcelain shows a rebasing worktree as detached), or build each worktree's path with `git -C <worktree> rev-parse --git-path` so both checks resolve paths the same way.

## What Looks Good

- **Values instead of field parsing (row 512).** `land` reads TIP, TREE, policy, branch and stem from `VERDICT`, not from positions in the ok line, and the merge arm decides on `VERDICT[tree]`. `VERDICT` is set in the same statement that prints the ok line, so the value and the text cannot disagree.
- **check_line stays unaware of landing.** The decision step has no knowledge of the action step. `--check` and `--merge` share `gate_start` and `check_line`, and only the dispatch arm differs. Folding `--merge` into the `--check` argument parser keeps the usage rules in one place.
- **The CAS is a real compare-and-swap.** `update-ref NEW MAIN_SHA` means a branch that moved is left as it is. The state gates re-run just before the move (row 494), in both the real repository and W.
- **The commit is written in the gate repository.** This keeps the commit's construction under the existing rule that the gate's own computations read no repository config.
- **The test shim (G17)** puts a fault-injecting `git` first on PATH only for the script's run, so the test's own git calls stay real. It covers the CAS race and the state planted after the check without changing production code.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Policy decision split between check_line and land; U3a3 must change both | Minor | `scripts/build-loop.sh:971,974,1021` | High |
| 2 | land has eight jobs and writes its commit before its checks | Minor | `scripts/build-loop.sh:1018-1075` | High |
| 3 | Merge arm uses line position (`tail -n +2`); `--check` and `--merge` use different ok signals | Minor | `scripts/build-loop.sh:1093,1102-1105` | Medium |
| 4 | CHANGED filled on refusal paths; verdict_ok nesting comment misleading | Informational | `scripts/build-loop.sh:917-920,948,975-976` | High |
| 5 | Repository rule omits --merge's writes; identity exported process-wide | Informational | `scripts/build-loop.sh:892-895,994-1001` | Medium |
| 6 | Rebase and bisect scan reads git's on-disk layout directly | Informational | `scripts/build-loop.sh:1035-1042` | Medium |

## Overall Assessment

The change keeps the script's structure intact. It adds a consumer of `check_line` without making `check_line` depend on it, and it starts delivering row 512's values. Nothing here is Structural or Coupling-level. The most important concern looks forward. The landing step bakes in "self-merge" in three places: the policy refusal, the message, and the reflog. The rule set is still chosen inside `check_line` from the brief's policy. U3a3's `--approved` is the next unit and has to cut across both. Lifting "the authority" into one value in the dispatch arm (finding 1), together with a modest split of `land` into decide, write and move (finding 2), turns U3a3 into an addition rather than a modification. Both fixes fit inside this unit or at the start of U3a3. No restructuring is needed.

## Goal-Alignment Note

- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/architecture-review-2026-10-10-u3a2-i1.md, structured per the architecture-review skill.
- Answered: the focus items in the brief:
  - check_line's new values: findings 3 and 4
  - land's size and responsibilities: finding 2
  - placement of the policy check for U3a3's reuse of land: finding 1
  - gate_git vs the real repository: finding 5
  - assembly of the merge output: finding 3
- Out of scope: whether the W preconditions are correct or race-safe (security and code critics; the race residuals are Q-103, rows 509 and 646), the claims the fact-check graded (not re-verified here), and test coverage beyond the shim's structure.
- Escalate: none. Finding 1 is a planning input for U3a3. If the author defers it, a row in the override log with the trigger "U3a3 `--approved`" is enough.
