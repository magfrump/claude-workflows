# API Consistency Review — feat/build-loop-u3a2 (U3a2, `--merge`), final confirming pass

**Scope:** `git diff main...HEAD -- scripts test` at HEAD 6cbca87c (scripts/build-loop.sh, test/scripts/build-loop-merge.bats), plus `git log main..HEAD` messages; the whole branch
**Date:** 2026-10-10
**Based on:** Stage 1 summary of docs/reviews/code-fact-check-report-u3a2-final-r{1,2,3}.md (k=3; merged report pending); prior reports api-consistency-review-2026-10-10-u3a2-i{1,2}.md; override-log rows 653-666 and rows 215, 494, 501, 509, 512, 524, 613, 625, 639, 642, 646

## Baseline Conventions

These are unchanged from i1 and i2. They were re-read at 6cbca87c in scripts/build-loop.sh (header :1-261, arg parse :277-295, check_line, land, merge arm :1134-1146) and in the lib's refusal texts.

- **Usage:** bad usage prints one stderr line, `WHY (usage: ...)`, and exits 1 before any git call. There is one arity message per mode.
- **Output:** each brief gets one verdict line first: `ok BRIEF TIP TREE`, `refuse BRIEF: WHY` or `skip BRIEF: WHY`. The `path`/`deny` rows follow it. A start-up gate failure prints `refuse state ...` and exits 2.
- **WHY text:** a lower-case clause naming the condition. It carries no git stderr. It may embed a SHA (`refused in the merge of $sha (tree $tree)`). Failed operations read "could not be listed/read" (e.g. :855, :865, :957). A standing state property reads "cannot be ..." (e.g. :878, "a gitlink's path in the checkout is a symlink or cannot be listed").
- **Exit:** 0 means every verdict is ok, 2 means any other verdict or a gate failure, and 1 means usage or environment. A caller reads any exit but 0 as nothing decided.
- **Header:** the `-h` text is the contract. It lists every refusal a mode produces, and it quotes exactly the literal strings a consumer may match.

## Status of earlier findings

| Earlier | Fix | Verdict at 6cbca87c |
|---|---|---|
| i1 F1-F5 | f782d9ee | Resolved; i2 confirmed it and nothing since regresses it |
| i1 F6, F7 | none | Settled (rows 660, 661) |
| i2 N1, reflog text given as exact | 6cbca87c D2 | **Resolved.** :219-221 reads `"build-loop: self-merge of STEM" (git adds ": Fast-forward" when W moves it)`, and test 1 and test 4 pin both forms |
| i2 N2, "from the environment" too broad | 6cbca87c D2 | **Resolved.** :221-224 names `GIT_AUTHOR_NAME/EMAIL and GIT_COMMITTER_NAME/EMAIL ... EMAIL or a guess from the host refuses instead`; test 3 pins the EMAIL-only refusal |
| i2 N3, path-line wording | 6cbca87c D2 | **Resolved.** :228 reads "with the ok line's path lines following" |

## Name-Pattern Audit

The table covers the whole branch's public names. `VERDICT`, `CHANGED`, `NEW`, `MERGE_WHY` and `land AUTHORITY` are script-internal, so they are not audited as public names.

| New name / text | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `--merge BRIEF --expect SHA` | CLI mode | `--check BRIEF... [--expect SHA]`, `--status BRIEF...` | `scripts/build-loop.sh:6-9, 277-295` | Consistent: a `--verb` mode word, shares `--expect` and its parsing with `--check` |
| `--merge takes one brief path and --expect SHA` | usage error | `--settings takes no arguments`, `--status needs at least one brief path`, `--check needs at least one brief path` | `scripts/build-loop.sh:280-294` | Consistent: one arity message per mode |
| `merged BRIEF TIP TREE NEW` | verdict line | `ok BRIEF TIP TREE` | `scripts/build-loop.sh:155` (header), verdict_ok | Consistent field order; the verb itself is settled (row 660) |
| `Merge branch 'BRANCH' (build-loop self-merge)` | commit message | git's `Merge branch 'X'`; this repo's `Merge branch 'feat/...': summary` | `git log main` merges (e.g. 2167ad9d) | Consistent: git's subject prefix, with a parenthesised origin |
| `Build-loop-gate: STEM` | trailer | `Co-Authored-By:`, `Claude-Session:`, `Confidence:`, `Notes:` | commit bodies on main (e.g. 6cbca87c) | Consistent: Hyphenated-Key trailer. I probed git 2.39.5: `%(trailers:key=Build-loop-gate,valueonly)` and `interpret-trailers --parse` both read it |
| `build-loop: self-merge of STEM[: Fast-forward]` | reflog message | git's `merge X: Fast-forward`, `commit: ...` | none in `scripts/` (no other reflog writer) | Consistent with git's `ACTION: detail` shape; both paths are documented |
| `... rebasing the default branch, or its rebase state cannot be read`; `... bisecting from the default branch, or its bisect state cannot be read` (new in 6cbca87c) | refusal WHY | `a gitlink's path in the checkout is a symlink or cannot be listed` | `scripts/build-loop.sh:878` | Consistent: "cannot" for a standing state property, as at :878 |
| `$in is missing` / `$in fails the state gate (refuse state ...)` (new in 6cbca87c) | refusal WHY | `the git state changed after the check (refuse state ...)` | `scripts/build-loop.sh:1099-1100` | Consistent: nests the state gate's first line in the same way as the re-gate refusal |
| `the worktrees could not be listed`, `the git directory could not be found`, `the merge commit could not be written` | refusal WHY | `the checkout's index could not be listed`, `... could not be read` | `scripts/build-loop.sh:855, 865, 957` | Consistent: "could not be" for a failed operation |

## Findings

#### F1. The header promises refusals for unreadable worktree and rebase/bisect state, but the code lands (`merged`, exit 0)

**Severity:** Inconsistent
**Location:** `scripts/build-loop.sh:229-232` (header); `:1048-1067` (land's discovery and scan)
**Move:** 3 (consumer contract, documentation drift), 4 (error consistency)
**Confidence:** High (from the executed fact-check, r2 claims 5b/5c and r3; the mechanisms confirmed by reading land in full)
**Legibility-target:** for-author

**Evidence:**
```
#             no identity is known; the worktrees or the git directory
#             cannot be read; the branch is checked out in two worktrees; a
#             worktree is rebasing it (or a paused rebase will move it) or
#             bisecting from it, or that state cannot be read; the merge commit
```
```
  git worktree list --porcelain -z > "$GATE_TMP/wts" || { MERGE_WHY="the worktrees could not be listed"; return 1; }
...
      [[ ! -e "$d/$q" ]] || { [[ -r "$d/$q" ]] && ! grep -qxF "refs/heads/$MAIN" "$d/$q"; } \
...
    [[ ! -e "$d/BISECT_START" ]] || { [[ -r "$d/BISECT_START" ]] && [[ "$(<"$d/BISECT_START")" != "$MAIN" ]]; } \
```

The header tells the orchestrator that unreadable worktree or rebase/bisect state ends in `refuse`. The code refuses only when git's own listing fails, or when a state file exists but is not readable. Three shapes pass instead:

- **An unsearchable `worktrees/` or admin dir.** `git worktree list` exits 0 and omits W, so `w=""` and the CAS moves main under W. The fact-check's probe left W's HEAD at NEW with its index and files old.
- **A state file that is a directory.** `-r` holds on a directory. `grep` then exits 2, which `!` turns into a pass, and `$(<dir)` gives `""`, which differs from `$MAIN`.
- **Any state under an unsearchable `rebase-merge/`.** `-e` is false, so the file reads as absent.

In all three the consumer sees `merged ... NEW`, exit 0. The contract says that output never comes from such a repository. This is not a Q-103 race (rows 509, 646), because the state is planted before the run. Rows 655-657 and 666 cover other cases. Commit 6cbca87c's D1 sentence ("unreadable rebase or bisect state refuses") makes the same overclaim. That commit message is immutable, so this is a note only.

**Recommendation:** Fix the code to match the header. This is the security critic's call, and the API surface needs no change if so. The fix: refuse when `$d/$q` exists and is not a regular readable file (`-f && -r`). Refuse when `$common/worktrees` or any entry under it cannot be searched (`-x`), or when an admin dir under `worktrees/` has no record in the listing. If any of this is deferred, narrow the header at :229-232 to say what is refused ("cannot be listed", "a state file that cannot be read"), and add an override row. Either way, the amber inventory should carry this.

#### F2. An empty email is accepted as a known identity

**Severity:** Informational
**Location:** `scripts/build-loop.sh:221-224` (header); `:1015-1022` (merge_ident)
**Move:** 3 (consumer contract), 8 (nullability)
**Confidence:** High (fact-check r1 executed it; I re-probed it)
**Legibility-target:** for-author

**Evidence:**
```
    [[ "$x" =~ ^([^\<\>]+)\ \<([^\<\>]*)\>\ [0123456789]+\ [-+][0123456789]{4}$ ]] || return 1
```

Take a config with only `user.name` and `committer.email`. My probe (git 2.39.5, `/tmp/u3a2i3-api-*`, removed afterwards) showed that `git -c user.useConfigOnly=true var GIT_AUTHOR_IDENT` returns `u <> ...` with exit 0, so the merge lands with an author of `u <>`. The header reads "Author and committer names and emails from ... git config", and the refusal reads "no identity is known". A reader could take that to mean an email is always present. The behaviour does match git: `git -c user.useConfigOnly=true commit` in the same setup also wrote `[u <>]`. "As git var resolves them" (merge_ident's comment) is therefore accurate, and nothing breaks.

**Recommendation:** Optional. Either add "(an empty email, as git itself accepts, included)" to the header, or make the email group `[^<>]+` and refuse. The second departs from git and needs a refusal-text tweak. Neither blocks the merge.

#### F3. A refusal after the write does not name NEW, though one branch may have moved to it

**Severity:** Informational
**Location:** `scripts/build-loop.sh:244-245` (header residual), `:255-260` (Exit); `:1110`, `:1142-1145` (merge arm)
**Move:** 3 (consumer contract), 9 (safety semantics)
**Confidence:** Medium
**Legibility-target:** for-author

**Evidence:**
```
    [[ "$(git rev-parse --verify -q "refs/heads/$MAIN")" == "$NEW" ]] || { MERGE_WHY="the default branch is not at the merge after the fast-forward in $in"; return 1; }
```
```
#             (a checkout refusal still names --check). Residual: a worktree
#             that checks the branch out, or W switching to another branch at
#             the same commit, between the checks and the move.
```

In the residual race, W switches to another branch at MAIN_SHA. `merge --ff-only` then moves that branch to NEW, and `--merge` prints `refuse BRIEF: the default branch is not at the merge ...` with exit 2. The Exit paragraph says a caller reads exit 2 as "nothing decided". Here something was written, and the refuse line carries no NEW for the consumer to find it by. The fact-check (r1) records the same gap against land's comment. The race itself is settled (rows 509, 646). Only the consumer-visible outcome goes unstated.

**Recommendation:** Optional, at U3b's `--state` or U3a3. Either append NEW to this one refusal ("...; W's branch now at NEW") or extend the header's residual sentence with "(then a refusal, with W's branch at the merge commit)". No action is needed for this unit.

## What Looks Good

- **CLI shape:** `--merge` reuses `--check`'s parser, `--expect` semantics and its error texts. It needs exactly one brief and `--expect`, and every arity mistake gets one message. Exit codes 0/1/2 mean the same thing in both modes.
- **Output grammar:** `merged BRIEF TIP TREE NEW` keeps `ok`'s first four fields. `--check`'s refusals and skips pass through unchanged, and the path lines follow every `--merge` verdict as the header now says. `--check`, `--status` and `--settings` output did not change on this branch.
- **Durable records:** the subject, the trailer and the reflog text are each one documented literal, and each is pinned by a test (tests 1 and 4). The trailer parses as a git trailer. The reflog text is the same on both paths up to git's documented suffix.
- **Identity:** the rule is deterministic and host-independent (`user.useConfigOnly`). The header and the refusal text name the same sources.
- **Refusal texts:** every `MERGE_WHY` in land appears in the header list, and every header item has code behind it (fact-check: 18 sites plus the merge arm, both ways). The 6cbca87c texts keep the established "could not be" / "cannot be" split.
- **i2 N1-N3** are all fixed as recommended.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| F1 | Header promises refusal for unreadable worktree/rebase/bisect state; an unsearchable dir or a directory-shaped state file lands `merged`, exit 0 | Inconsistent | `scripts/build-loop.sh:229-232`, `:1048-1067` | High |
| F2 | An empty email (`u <>`) is accepted as an identity (matches git commit) | Informational | `scripts/build-loop.sh:221-224`, `:1015-1022` | High |
| F3 | A post-write refusal (W's other branch moved to NEW) does not name NEW; exit 2 reads as "nothing decided" | Informational | `scripts/build-loop.sh:244-245`, `:1110` | Medium |

## Overall Assessment

The `--merge` surface is consistent with `--check` and the rest of the script: the usage, verdict grammar, exit codes and refusal style all match. i1 and i2's findings are resolved or settled, and no consumer of `--check`, `--status` or `--settings` is affected. One contract gap remains for the amber inventory. F1: the header promises a refusal for unreadable worktree and rebase/bisect state, and in three planted, non-racing shapes the code prints `merged` with exit 0. The fix belongs in land's checks, not in the surface. If it is deferred, the header must narrow to what is actually refused, and a row should record why. F2 and F3 are informational wording notes on behaviour that already matches git or is settled.

## Goal-Alignment Note
- Success criterion (restated verbatim): A markdown report saved to /workspace/.claude/wt-build-loop-u3a2/docs/reviews/api-consistency-review-2026-10-10-u3a2-final.md, structured per the api-consistency-reviewer skill.
- Answered:
  - Whole-branch public surface checked against `--check`/`--status`/`--settings` and the plan's U3a2 bullet and Script interface: CLI, usage, exit codes, verdict and path lines, merge commit subject, trailer and reflog.
  - i2 N1-N3 verified as fixed.
  - The 6cbca87c refusal texts audited.
  - Probed the trailer parsing and the empty-email identity under git 2.39.5, in `/tmp/u3a2i3-api-*` (removed).
- Out of scope:
  - Exploitability and the fix design for F1's fail-open (security).
  - The BISECT_START `-r` mutant's test gap (fact-check test gap; test-strategy).
  - Comment-level claims about internals (gate_start's repository rule, land's comment).
  - Bats suites were not run.
- Escalate: F1 belongs in the amber inventory, and the security critic should carry it. It is not covered by any override row.
