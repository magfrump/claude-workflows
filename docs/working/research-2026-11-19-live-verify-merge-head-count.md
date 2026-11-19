# Research: how often a merge of main brings an enforcement-file change into a branch

Date: 2026-11-19
Brief: `docs/working/briefs/2026-11-19-live-verify-merge-head-count.md` (measure only; build nothing)
Branch: `docs/live-verify-merge-head-count`, dispatched at 1e826349

Failure-pattern grep: `rg -n -i 'merge|live-verif|trailer' docs/failure-patterns.md` turned up FP-012 (a stale MERGE_HEAD spoils the next merge) and FP-015 (a swallowed merge-abort failure). No entry is about this hook. FP-012 goes into the bypass list in the fix sketch below.

## What the hook does (acceptance criterion 1)

`hooks/live-verify-gate.sh` is a Bash PreToolUse hook. It only looks at a command that contains `git … commit` (see the grep at the top of the file). A plain `git merge` that finishes without conflicts never reaches it, because that command does not contain `commit`. When it does run, it reads `git diff --cached --name-only --no-renames`, which compares the index with HEAD and ignores MERGE_HEAD. That file list is checked against two regexes:

- **Boundary files** (these need a `Live-verified:` trailer): `devcontainer-config/` `Dockerfile`, `devcontainer.json`, `init-firewall.sh`, `cc-sni-proxy.py`, `link-claude-home.sh`, `cc-isolated.sh`, `install.sh` and `egress/`.
- **Host tools** (these need a `Host-tool-tested:` trailer): `cc-exit-scan.sh`, `cc-gitdir.sh`, `cc-push.sh` and `cc-verify.sh`.

A trailer's value is free text "on purpose" (header comment). `Live-verified: no — <why, and what will run it>` passes the hook, and `git log --grep 'Live-verified: no'` is the list of outstanding debt.

So the case only arises when a merge of main hits a conflict, the session resolves it by hand and finishes with `git commit`, and main's side changed a gated file. The staged diff against HEAD then includes main's change, and the hook asks for a trailer. A hand-resolved merge finished with `git merge --continue` never matches the trigger, so it skips the hook altogether. The hook also reads the index in its own working directory, the project directory. It does not follow a `cd X &&` or a `git -C X` in the command, so in a worktree flow it may not read the merge's index at all.

`docs/working/research-2026-11-16-loop-may-merge-default-in.md` item 5 calls this "friction, not a bypass". It says the loop is asked for a trailer "it cannot honestly give" and so stops. The history below contradicts the "cannot honestly give" part.

Constraints that bear on the decision (`docs/constraints.md`): S5 (establish the motive first; the status quo is a valid outcome), S10 (spend the owner's attention last; an enforcement-file change needs a review merge and a live check), H2 (a gate fails closed), and S1 (gates defend against honest slips, not a hostile loop).

## The count (acceptance criterion 2)

Method. I used `git log --merges --all` and kept merges whose second parent is on `refs/heads/main`'s first-parent line, meaning the second parent was main's tip at the time. That gives 105 merges. A message match (`Merge … main into …`) added 3 more whose second parent later fell off the first-parent line. That makes **108 merges of the default branch into another branch**. No `refs/heads/master` exists. For each merge, `git diff --name-only --no-renames <first parent> <merge>` is the file list the hook would have seen as staged against HEAD. I filtered it with today's two regexes. I used `git merge-tree --write-tree <p1> <p2>` (git 2.39) to tell whether a merge had conflicts.

Who did the merging: 75 of the 108 are the orchestrator's own `chore/dev-cycle-*` worktrees (skill step 9, "merge main into WT"). The rest are feature, review and integration branches. Most of those were owner-directed sessions from before 2026-11-16. Since the F-009 rule let build loops merge main in (2026-11-16), **one** build-loop branch has done it: `feat/worktrees-outside-dot-claude`, 2026-11-19, and it brought in no gated file.

**9 of the 108 brought in a gated file:**

| Merge | Date | Branch | Gated files brought in from main | Conflicted? | Trailer in message |
|---|---|---|---|---|---|
| 8e7d08d7 | 11-13 | chore/dev-cycle-2026-11-14-0329 | cc-verify.sh | no | none |
| 2cc33cf6 | 11-11 | chore/dev-cycle-2026-11-11-0812 | Dockerfile, cc-isolated.sh, devcontainer.json, install.sh | no | none |
| 536678c0 | 10-30 | feat/q106-host-settings-merge | Dockerfile, cc-exit-scan.sh, cc-isolated.sh, cc-verify.sh, egress/android.txt, egress/llm.txt, init-firewall.sh, install.sh | yes (link-claude-home.sh, a fact-check report) | Live-verified: no; Host-tool-tested: no |
| f3ec9de4 | 10-28 | chore/dev-cycle-2026-10-29-0133 | cc-exit-scan.sh | no | none |
| 195747b5 | 10-28 | chore/dev-cycle-2026-10-28-2136 | cc-exit-scan.sh, cc-isolated.sh, cc-verify.sh, install.sh | no | none |
| c70b221a | 09-28 | feat/hook-refuse-redirects | cc-exit-scan.sh, cc-isolated.sh | yes (override-log.md) | Live-verified: no |
| 90a70554 | 09-28 | review/q087 | Dockerfile | yes (decisions/log.md, override-log.md) | Live-verified: no |
| 2f55faef | 09-28 | review/q085 | Dockerfile | no | Live-verified: no |
| 5c878776 | 09-28 | review/q065 | Dockerfile | yes (override-log.md) | Live-verified: no |

Paths in the table are under `devcontainer-config/`.

Reading the table:

- **4 merges were in the case**: 536678c0, c70b221a, 90a70554 and 5c878776. Each had a conflict, was resolved by hand and finished with a commit, and main's side brought a gated file. Each carries an honest negative trailer that names where the real verification lives. History shows the trailers but cannot show that the hook demanded them: 2f55faef had no conflict, so the hook never ran on it, and it carries the same trailer, which means sessions add these trailers on their own. All 4 were owner-attended interactive sessions (09-28 to 10-30), not autonomous build loops. Two examples: "the Dockerfile change arrives from main (9e5477a carries its own trailer); nothing new here", and "merge of main; main's boundary commits carry their own trailers". The last case was 2026-10-30, about three weeks ago.
- 5 merges had no conflict. The four `chore/dev-cycle` ones carry no trailer because a clean `git merge` never wakes the hook. 2f55faef carries one anyway.
- In 536678c0 the branch's own side also changed a gated file (link-claude-home.sh conflicted). That trailer was needed on the branch's own account, so a MERGE_HEAD-aware hook would still have asked for it.
- The hook did not gate install.sh until 2026-09-26 (addae610) or host tools until 2026-10-14 (5650145a). I counted with today's lists, so the count can only be higher than what the hook demanded at the time. Every row is dated after addae610.
- All 9 merges are now reachable from main. The four `Live-verified: no` merge commits are among the 148 commits that `git log main --grep 'Live-verified: no'` lists as debt. Those four are false debt, because the real check belongs to main's own commits. That is the case's one real cost so far.

Out of scope for the count, but the same hook firing: e0c5b5e4 merged the old `feat/q125-cc-isolated-sandbox` into a branch cut from main. The gated changes there belonged to that branch, so its `Live-verified: no` was genuine debt. A MERGE_HEAD-aware hook should still ask in that case, and the sketch below would.

### How this could undercount

- **A stopped loop leaves no merge commit.** If a loop stops before committing, nothing lands. That outcome is the exact failure the Idea predicts, and this count cannot see it. Criterion 3 covers it through markers and records instead.
- Merges on branches that were deleted without being merged are unreachable from `--all`. Squash merges and rebased branches leave no merge commit at all.
- The owner's other repos don't count. The hook only gates paths under `devcontainer-config/`, so it can fire only in a repo that carries that directory. This repo is the only known one.
- Merges by sessions that ran with `CC_LIVE_VERIFY_GATE_DISABLE=1`, or without the hook wired, look the same in history.

## Loops that stopped on the trailer (acceptance criterion 3)

None found. The repo holds 4 `handoff: blocked` markers (27c32c32, fc2eeb03, 11d299cf, 502296b7), and no body mentions a trailer or live verification. It holds no `handoff: stopped` marker. Searching `docs/` for `MERGE_HEAD`, `live-verif … merge` and `merge … live-verif` finds 24 files. Most are about other merges (the build loop's `land` step, the Q-180 reviews). The hits about this hook are the 2026-11-16 pre-mortem item, the roadmap Idea that came from it, `docs/working/idea-log.md:296`, `docs/working/questions-archive.md:7247` (which quotes the a3ef5a38 ready marker), `docs/reviews/api-consistency-review-2026-11-19-measure-a8-cache-probe-pass3.md:21`, and this brief. Every one is a prediction or a restatement of the idea. None records a stop. `docs/harness-feedback.md` does not exist. The friction is predicted in the record and has never been observed.

## Recommendation (acceptance criterion 4)

The three options are fix now, fix later, or drop. One option dominates (divergent design Path A), so no options question is needed:

- **Fix now** is ruled out by S5 and S10. The motive doesn't hold up: in 4 of 4 real cases the hook accepted an honest `Live-verified: no — merge of main; <sha> carries its own trailer`, and no session or loop stopped. A fix is an enforcement-file change, which costs a review merge, a pre-mortem and a live check from the owner. It would remove four false-debt lines over two months.
- **Fix later** saves nothing over dropping. The Idea comes back if the case arises, so keeping it open only holds a roadmap slot.
- **Drop** is the pick. The pre-mortem's claim that a loop cannot honestly answer has no support. The hook was designed to take `no — <why>`, and interactive sessions answered exactly that way all 4 times. No build loop has met the case yet: since 2026-11-16, one loop has merged main in, and that merge brought in no gated file. The reopen trigger below covers the loop case. The only cost seen is false debt in `git log --grep 'Live-verified: no'`. A reader clears it by noticing the commit is a merge whose trailer names main's commit.

Reopen trigger: a loop's marker or a cycle record shows a stop or block on this hook during a merge of main, or false merge debt starts misleading a host-step hold (the dev-cycle skill's "hold on a host step" rule reads `Live-verified: no` trailers).

**If it is ever reopened, here is the fix sketch.** When `git rev-parse -q --verify MERGE_HEAD` succeeds, let a gated file through without a trailer only when its staged blob equals the MERGE_HEAD side's blob (`git ls-files -s` against `git rev-parse MERGE_HEAD:<path>`). Main's change taken verbatim then passes. A hand resolution, a branch-side change, or any blend of the two is still gated. A pre-mortem would list these bypass families:

1. **Forged or stale MERGE_HEAD.** A same-uid session can write `.git/MERGE_HEAD` naming a commit it made itself (FP-012 is the stale version of this). Require MERGE_HEAD to be an ancestor of `refs/heads/main` (or the resolved default branch). Read it through `git rev-parse --git-path`, because in a worktree `.git` is a file.
2. **Octopus merges** put several MERGE_HEAD lines. Require exactly one, or else gate everything.
3. **A merge commit that also edits a gated file** (`git commit -a`, or edits after the resolution). A blob that matches neither side stays gated, and `-a` must compare the worktree blob as well.
4. **Rename or mode change.** Keep `--no-renames`, and compare mode as well as blob.
5. **Look-alikes.** CHERRY_PICK_HEAD and REVERT_HEAD must not be treated as MERGE_HEAD. The sketch adds nothing for `--amend`, and the existing `--amend --no-edit` exemption is unchanged.
6. **Working-directory mismatch.** With `cd X && git commit` or `git -C X commit`, the hook reads MERGE_HEAD and the index from the project directory, not from X. That is a gap already, and the exemption would widen it: a MERGE_HEAD in the wrong checkout could let a gated file through. Resolve the target checkout first, or gate whenever the command names another directory.
7. **Fail closed (H2).** Any failure of `rev-parse` or `ls-files` must fall through to the gate, never to a pass.

## Choices made without a design fork

- Denominator: "second parent on main's first-parent line" plus a message match. Message matching alone would miss custom `-m` messages, and a plain ancestor test would mostly catch main merging feature branches (601 hits). I picked the narrower topology test and wrote down the 3 merges the message match added.
- Gated-file list: today's regexes, not the regexes in force on each date. That choice can only raise the count, which is the safe direction for a "drop" verdict.
- Brief criterion 6 says to run only `git`, `rg` and reads. The filtering also used shell loops, `awk`, `grep`, `sed -n` and `wc` over `git` output, written to a scratch directory outside the repo. Nothing ran the hook and nothing changed code or tests.

## For the dev cycle

Drop the roadmap item "The live-verify hook reads a merge commit's staged diff against HEAD only". Reason: of 108 merges of main into a branch, 9 brought in a gated file, and 4 were in the case (a conflict resolved by hand, with a gated file from main). All 4 were interactive sessions, and each carries an honest `Live-verified: no — merge of main; main's commit carries its own trailer`, which the hook accepts by design. Nothing in the repo records a stop. No build loop has met the case yet: one loop has merged main since 2026-11-16, and that merge brought in no gated file. The only cost is four false-debt lines in `git log --grep 'Live-verified: no'`, and fixing it would need an enforcement-file change with a review merge and a live check. Suggested watch: reopen if a marker or cycle record shows a stop or block on this hook during a merge of main. The fix sketch and bypass list are in this doc's Recommendation section.
