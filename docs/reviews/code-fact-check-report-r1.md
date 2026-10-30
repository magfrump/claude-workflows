Commit: 46342d66

# Code Fact-Check Report

**Repository:** /workspace (worktree `/workspace/.claude/wt-q180`)
**Scope:** branch diff `git diff main...HEAD`, `chore/q180-repin-pastes` (46342d66) vs main (b71a4e9e): `docs/roadmap.md`, `docs/working/checkpoint-build-loop-handoff.md`, `docs/working/questions.md`, plus the two commit messages (53bd1a56, 46342d66)
**Checked:** 2026-10-15
**Total claims checked:** 28
**Summary:** 22 verified, 5 mostly accurate, 0 stale, 1 incorrect, 0 unverifiable

Probe directory: `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/cfc-r1/` (written `$S` below). All captured outputs are in `$S/logs/`. Each probe ran in a scratch clone or scratch repo under `$S`, never in `/workspace`. The one scratch worktree (`$S/wt-r2`, detached at 09a2876f) was removed with `git worktree remove` once the probes were done. No process was left running. git version: 2.39.5. `docs/reviews/hallucination-patterns.md` was read, and no claim matches a logged pattern (this report found no fabricated symbol).

---

## Claim 1: "Cycle 2 (2026-10-14): 42 multi-file landings after cac2ba0c (cycle 1's own three landings excluded); 25/42 carry the line, 38/42 committed a rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432)"

**Location:** `docs/roadmap.md:77-80`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the counts over first-parent merges in `cac2ba0c..b279a2ba` that change more than one file. It does not establish that b279a2ba is the right end of the window: the roadmap names no end, and b279a2ba is the cycle-2 base the earlier reports used.
**Legibility-target:** for-orchestrator-synthesis

Command (cwd `/workspace/.claude/wt-q180`, 2026-10-15T21:07:19Z, exit 0): a loop over `git log --first-parent --merges --format=%h cac2ba0c..b279a2ba`. It keeps merges with more than one changed file, greps each message for `← carried from RPI`, and greps each `git diff --name-only m^1 m` for `code-review-rubric`. Output: `n=42 line=25 rubric=38 neither: df18413a 0fbf9742 b8807e76 52053432`. 188e0a7d and 90364c73 are both ancestors of cac2ba0c, so "after cac2ba0c" does exclude all three cycle-1 landings (paraphrased — no quote available because the evidence is `merge-base --is-ancestor` output).

**Evidence:** `docs/roadmap.md:77-80`, `$S/logs/counts.log`

---

## Claim 2: Checkpoint Date line: "U4c merged at 308196e7 (Q-144 [1]); U5 built and reviewed on `feat/build-loop-u5` (tip 7c91b974 …), not merged: it waits on **Q-164**"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:2`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the hashes, ancestry and Q-144 attribution. It does not establish the "loop ended escalate, narrow check held" review history, which lives on the U5 branch's rubric and was not re-read.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 308196e7` prints `Merge branch 'feat/build-loop-u4c': … step 0.1's image checks (Q-144 [1])`, and 308196e7 is an ancestor of main. `feat/build-loop-u5` resolves to 7c91b97455db…, which is not an ancestor of main (paraphrased — no quote available because the evidence is rev-parse and merge-base output).

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:2`

---

## Claim 3: Checkpoint Branch line: U5 "lands inside `merge/build-loop-u5-resolved-r2` 7326d715 or `merge/u5-and-q145-r2` 6c841192"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:3`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers that 7c91b974 is an ancestor of both branches. It does not establish the U4c worktree's existence.
**Legibility-target:** for-orchestrator-synthesis

`git log -1 --format='%p | %s' 7326d715` prints `09a2876f e088c7e3 | Merge branch 'feat/build-loop-u5' (as resolved at e088c7e3) …`. e088c7e3's parents are `46942678 7c91b974`, and 6c841192's parents are `35e13638 7326d715`.

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:3`

---

## Claim 4: "The first Q-162 paste on 2026-10-15 aborted on the override-log conflict, as its note said (a760a5e5 predated Q-178's landing); main was left clean."

**Location:** `docs/working/checkpoint-build-loop-handoff.md:10`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that merging a760a5e5 into today's main conflicts only in the override log, and that the main checkout's records are consistent with an abort. It does not observe the user's paste itself.
**Legibility-target:** for-orchestrator-synthesis

`git merge-tree --write-tree --name-only main a760a5e5` reports `CONFLICT (content): Merge conflict in docs/reviews/override-log.md` and nothing else. In the main checkout, `git -C /workspace reflog HEAD` shows `b71a4e9e HEAD@{2026-10-15 13:43:41 -0700}: reset: moving to HEAD`, which is the reflog shape of `git merge --abort`. `/workspace/.git/ORIG_HEAD` holds `b71a4e9e…` with mtime 13:43:41, and main is still b71a4e9e (paraphrased — no quote available because the evidence is reflog and file metadata).

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:10`, `$S/logs/merge-replay.log`

---

## Claim 5: "U5 built, not merged (Q-164) … (rubric `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md` on the branch) … Q-149..Q-155 and Q-103 become the live asks."

**Location:** `docs/working/checkpoint-build-loop-handoff.md:48`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the rubric path and each named entry's status on the U5 merge branches. It does not establish whether the user will treat these entries as asks.
**Legibility-target:** for-author

The rubric exists at `7c91b974:docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md` and not on main. Q-154 is not a live ask: on U5's branches it sits in the archive, already answered. `7326d715:docs/working/questions-archive.md:2730` reads `### Q-154 · build-loop-c5-cycle-cost`, followed by `**Status:** ANSWERED` and `**Answer (2026-10-04, in session; plan D12; filed 2026-10-14):** [1]`. Q-149..Q-153, Q-155 and Q-103 are `Status: OPEN` in `7326d715:docs/working/questions.md`. Precise version: "Q-149..Q-153, Q-155 and Q-103 (Q-154 is already answered)".

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:48`, `7326d715:docs/working/questions-archive.md:2730-2734`, `7326d715:docs/working/questions.md:492-772`

---

## Claim 6: Q-162: "Paste the block into the container's shell … It merges `merge/ready-2026-10-15-r2` by its reviewed tip, 09a2876f … That branch is main (as of b71a4e9e) plus seven reviewed units, the branch-verify research and spike docs …, and the decision-015 divergent design …, each merged with `--no-ff`"

**Location:** `docs/working/questions.md:84`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the branch's first-parent structure, its nine second parents and its base. It does not establish that each unit tip is the reviewed one, which the Read bullets assert and this report did not re-check.
**Legibility-target:** for-orchestrator-synthesis

`git log --first-parent main..09a2876f` lists nine two-parent merges starting from `7e509c0c b71a4e9e 4ee81106`. Their second parents are exactly 4ee81106, f5b7e49d, c8e87a69, 4a44d2f3, 8717fd72, d25254da, f050b487, 47da5a4b and f6f37fad, and no non-merge commit sits on the first-parent line (paraphrased — no quote available because the evidence is git log output).

**Evidence:** `docs/working/questions.md:84`

---

## Claim 7: "a branch name can move; the hash names fixed content once the paste has checked that no replace refs, `info/grafts` or `shallow` file exists, and the merge itself ignores replace refs"

**Location:** `docs/working/questions.md:84` (repeated by reference in `:115` and `:147`, "as for Q-162")
**Type:** Invariant
**Verdict:** Incorrect
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers what landed content can differ from the pinned hash after the paste's guard passes, under the threat the entry names itself ("an agent session can plant hooks and config" in `/workspace`). It does not establish an end-to-end exploit against the real `/workspace`, and it does not establish the GIT_GRAFT_FILE or worktree cases, which the guard handles (Claim 13).
**Legibility-target:** for-author

The guard checks only replace refs, grafts and shallow:

```
# docs/working/questions.md:90-91 (Q-162 paste, lines 2-3 of 4)
{ test -z "$(git for-each-ref refs/replace/)" && g="$(git rev-parse --git-path info/grafts)" && s="$(git rev-parse --git-path shallow)" && test ! -e "$g" && test ! -L "$g" && test ! -e "$s" && test ! -L "$s" || { echo "replace refs, info/grafts or shallow present: stop"; false; }; } && \
{ GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null merge --no-ff 09a2876f… -m "…" || { git merge --abort; echo "conflict: merge aborted, nothing deleted"; false; }; } && \
```
(excerpt ends at line 3 of the 4-line block; line 4, the worktree and branch cleanup loop, was read)

Two executed counterexamples land content that is not the pinned hash's, with the guard passing:

- **A rewritten object file.** In a scratch repo, the loose blob file of a file in a pinned commit T was overwritten with another blob's bytes. The guard conditions passed. Then `GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null merge --no-ff T` exited 0 and landed `g: EVIL` instead of `reviewed` (`$S/logs/probe-tamper.log`, cwd `$S/tamper3`, 2026-10-15T21:07:28Z, exit 0). git verifies the commit object's hash on merge (an overwritten commit object was refused with `error: hash mismatch`), but not the hashes of the blobs it reads. An agent that can write `.git/hooks` and `.git/config` can also write `.git/objects`.
- **A planted merge driver.** `.git/info/attributes` held `* merge=evil` and `merge.evil.driver` was set to `echo PLANTED > %A; true`. In a scratch clone of `/workspace` (cwd `$S/sim-drv2`, 2026-10-15T21:07:37Z), main took `chore/q180-repin-pastes` first, as the checkpoint orders, then the Q-162 paste ran. After that, Q-164's paste exited 0 and landed `PLANTED` as the content of `docs/roadmap.md` and `docs/working/questions.md` (`$S/logs/probe-merge-driver.log`). `core.hooksPath=/dev/null` does not disable merge drivers. The driver runs only when both sides changed a file. Q-162's own merge has no such file (`comm` of the two sides' changed paths is empty), so the driver case bites Q-163 and Q-164 after Q-180's landing.

Both are pre-existing classes, not new in this diff. The sentence, though, now states a sufficient condition ("once the paste has checked … the hash names fixed content") that does not hold. Precise version, for example: "the paste refuses replace refs, grafts and shallow, and the merge ignores replace refs and hooks. Content written straight into `.git/objects`, and merge drivers or filters set in `.git/config` or `info/attributes`, are not checked."

**Evidence:** `docs/working/questions.md:84`, `docs/working/questions.md:88-93`, `$S/logs/probe-tamper.log`, `$S/logs/probe-merge-driver.log`, `$S/probe-tamper.sh`

---

## Claim 8: "five of those nine merges (Q-110, doc drift, Q-160 and the two docs branches) conflict with an earlier one, each only in the append-only `docs/reviews/override-log.md`"

**Location:** `docs/working/questions.md:84`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers which of the nine merges conflict and in which file, replayed with `merge-tree` on each merge's own parents. It does not establish how each conflict was resolved; the union property is Claim 12.
**Legibility-target:** for-author

Replaying each merge (`git merge-tree --write-tree --name-only M^1 M^2`, cwd `/workspace/.claude/wt-q180`, 2026-10-15T21:07:08Z): exactly 2752471d (Q-110), c02341d1 (doc drift), c02ee84b (Q-160), 22fbfaef (branch-verify) and 7b9df857 (dd-015) conflict, each only in `docs/reviews/override-log.md`. Their messages carry `(override-log appends: both sides kept)`. The rest are clean.

"With an earlier one" is imprecise. All five tips conflict with main b71a4e9e alone, so the conflict is with main's appends since b279a2ba. Pairwise, Q-110 (f5b7e49d) and dd-015 (f050b487) conflict with no other unit tip: the conflicting pairs are only c8e87a69×f5b7e49d, c8e87a69×d25254da, 4a44d2f3×{f5b7e49d, c8e87a69, d25254da} and d25254da×f5b7e49d. Precise version: "conflict with main or with an earlier merge".

**Evidence:** `docs/working/questions.md:84`, `$S/logs/merge-replay.log`

---

## Claim 9: "Run it before Q-163 and Q-164: their pastes stop unless this merge is on main."

**Location:** `docs/working/questions.md:84`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers Q-163's and Q-164's ancestor check when Q-162 has not run (main plus Q-180's landing). It does not establish what happens if Q-162's merge commit is later reverted. The check tests ancestry of 09a2876f, not of a merge commit.
**Legibility-target:** for-orchestrator-synthesis

```
# docs/working/questions.md:120 (Q-163 paste, line 3 of 5)
{ git merge-base --is-ancestor 09a2876ff5ea6f7e5b86eea723c2aa0094759145 HEAD || { echo "Q-162's merge is not on main: run it first"; false; }; } && \
```
(excerpt ends at line 3; lines 4-5, the selection and the merge, were read)

Command `$S/sim.sh /bin/bash Q-163` (and `Q-164`; cwd `$S`, 2026-10-15T21:03Z) runs the paste with `cd /workspace` rewritten to the scratch clone. Both printed `Q-162's merge is not on main: run it first` and exited 1 with HEAD unchanged (`$S/logs/sim-only-Q-163.log`, `$S/logs/sim-only-Q-164.log`).

**Evidence:** `docs/working/questions.md:120`, `docs/working/questions.md:152`, `$S/logs/sim-only-Q-163.log`, `$S/logs/sim-only-Q-164.log`

---

## Claim 10: "the first pin, a760a5e5, was built on b279a2ba and conflicted once Q-178 landed the 0357 cycle branch (in the override log, and before that landing in the questions, questions-archive, roadmap and idea-log files)"

**Location:** `docs/working/questions.md:86`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the conflict file sets against main and against 7f711bfe (main before Q-178's landing). It does not establish the state at other intermediate main commits.
**Legibility-target:** for-orchestrator-synthesis

`merge-tree main a760a5e5` conflicts only in `docs/reviews/override-log.md`. `merge-tree 7f711bfe a760a5e5` exits 1 and lists `docs/roadmap.md`, `docs/working/idea-log.md`, `docs/working/questions-archive.md` and `docs/working/questions.md`. The merge base of a760a5e5 with b279a2ba's line is b279a2ba (paraphrased — no quote available because the evidence is merge-tree output).

**Evidence:** `docs/working/questions.md:86`, `$S/logs/merge-replay.log`

---

## Claim 11: "Its diff from a760a5e5 is exactly main's own change since then"

**Location:** `docs/working/questions.md:86`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the blob-level comparison of `a760a5e5..09a2876f` with `92f3b080..main`, where 92f3b080 is their merge base. It does not establish anything about commit metadata.
**Legibility-target:** for-author

`git diff --raw` over both ranges gives identical blobs for 18 of 19 paths. Only `docs/reviews/override-log.md` differs (`82f58e4e` vs `33501a41`). Its 15 added rows are the same lines, but r2 places them at line 828, before a760a5e5's unit rows, while main appended them at the end. The two patches differ only in that hunk's position (`@@ -825,6 +825,21 @@` vs `@@ -825,3 +825,18 @@`) (paraphrased — no quote available because the evidence is a comparison of two 3,500-line diffs, saved as `$S/d_a760_r2.diff` and `$S/d_mb_main.diff`). Precise version: "the same lines main added since then; in the override log they sit before a760a5e5's rows".

**Evidence:** `docs/working/questions.md:86`, `$S/d_a760_r2.diff`, `$S/d_mb_main.diff`

---

## Claim 12: "its override-log rows are exactly the union of a760a5e5's and main's"

**Location:** `docs/working/questions.md:86`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers line-multiset equality: r2 = a760a5e5 + (main − base 92f3b080), and r2's first 827 lines equal the base. It does not establish row order beyond that.
**Legibility-target:** for-orchestrator-synthesis

A Python Counter over the four versions of `docs/reviews/override-log.md` printed `multiset equal: True extra in r: [] missing: []`, and the base prefix check printed `True`. The line counts are a760 850, base 827, main 842 and r2 865 (850 + 15) (paraphrased — no quote available because the evidence is a script's output).

**Evidence:** `docs/working/questions.md:86`

---

## Claim 13: The pastes' guard refuses replace refs, `info/grafts` and `shallow` (including an empty file and a dangling symlink), in bash and zsh, and in a linked worktree

**Location:** `docs/working/questions.md:90` (Q-162), `:119` (Q-163), `:151` (Q-164)
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the guard line, byte-identical in all three pastes, against each planted state. It does not establish protection against object-store or merge-driver tampering (Claim 7).
**Legibility-target:** for-orchestrator-synthesis

The guard line is quoted in Claim 7. Probe: the guard line was extracted verbatim and run in bash and zsh (cwd `$S/guard2/repo`, plus the linked worktree `$S/guard2/linked`; 2026-10-15T21:07:48Z). Results: clean, rc 0. `info/grafts` from the main checkout or the linked worktree, an empty `shallow` from either, a dangling `info/grafts` symlink, a dangling `shallow` symlink, a replace ref, and `GIT_GRAFT_FILE` pointing outside `.git`: each rc 1 in both shells. In the linked worktree, `git rev-parse --git-path info/grafts` and `--git-path shallow` resolve to the common dir (`…/repo/.git/info/grafts`, `…/repo/.git/shallow`). `--git-path info/grafts` also honours `GIT_GRAFT_FILE`, which is why that case is refused. This closes security final F1.

**Evidence:** `docs/working/questions.md:90`, `$S/logs/probe-guard.log`

---

## Claim 14: The merge runs "with GIT_NO_REPLACE_OBJECTS=1 and hooks off", and `git merge --abort` runs on failure (commit 53bd1a56; the paste lines)

**Location:** `docs/working/questions.md:91` (Q-162), `:122` (Q-163), `:154` (Q-164)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers hooks in `.git/hooks` and in a configured `core.hooksPath` (pre-merge-commit, post-merge, commit-msg, prepare-commit-msg), and the abort path in Q-162. It does not establish merge drivers or filters (Claim 7). Q-162's cleanup loop runs `git worktree remove`/`git branch -d` without these settings; neither runs hooks.
**Legibility-target:** for-orchestrator-synthesis

```
# docs/working/questions.md:122 (Q-163 paste, line 5 of 5)
{ GIT_NO_REPLACE_OBJECTS=1 git -c core.hooksPath=/dev/null merge --no-ff "$B" -m "…" || { git merge --abort; echo "conflict: merge aborted; the loop rebuilds this entry's branch against main"; }; }
```

Probe (cwd `$S/hk`, 2026-10-15T21:05Z): hooks were planted in `.git/hooks` and in a repo-configured `core.hooksPath`, then that merge command ran. It exited 0 and no hook fired (`fired:` empty). The Q-162 abort path matches the old paste's form. Q-163's and Q-164's failure branches end in `echo`, not `false`, so a conflict there exits 0 after the abort. This is unchanged from main, and no prose claims otherwise (paraphrased — no quote available because the hook probe's output was a single terminal line, not captured to a file).

**Evidence:** `docs/working/questions.md:91`, `docs/working/questions.md:122`, `docs/working/questions.md:154`

---

## Claim 15: "Gate for the rebuilt tip (09a2876f, 2026-10-15): the fast suites had one red, build-loop-merge's T23 test, whose log shows the Q-145 `/tmp` race …; it passes 3/3 alone. The slow suites, run separately: 300/300. Shellcheck and the other checks passed."

**Location:** `docs/working/questions.md:104`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers the two supplied logs and an independent 3/3 re-run of the red test at 09a2876f. It does not establish that the health log was produced at 09a2876f, because the log carries no commit stamp.
**Legibility-target:** for-orchestrator-synthesis

`health-ready-r2.log` has exactly one `not ok`: `not ok 1103 --merge refuses a file or link where the merge adds a directory, … (T23, U3a2; i1 security)`, with `# find: '/tmp/bats-run-0FMk9A/bats.1565803.out': No such file or directory`. Its other markers are `✗ Fast BATS suites failed — slow suites not run`, then all-`✓` shellcheck lines and `✓ questions: structure valid, indexes current`; the only `⚠` lines are freshness and fixture-coverage warnings. `slow-ready-r2.log` has 300 `ok` and 0 `not ok`. Re-run: `timeout 600 bats -f 'merge refuses a file or link where the merge adds' test/scripts/build-loop-merge.bats` three times (cwd `$S/wt-r2` detached at 09a2876f, 2026-10-15T21:00:44Z). All three exited 0 with `ok 1`.

**Evidence:** `docs/working/questions.md:104`, `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/health-ready-r2.log`, `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/slow-ready-r2.log`, `$S/logs/t1103-alone.log`

---

## Claim 16: Q-163: "It merges `merge/q145-r2` at 35e13638 (Q-162's branch plus this unit, the override-log appends resolved), or `merge/u5-and-q145-r2` at 6c841192 (that plus U5) … The unit's own tip, c035f2e7, is unchanged inside them."

**Location:** `docs/working/questions.md:115`
**Type:** Architectural
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers parentage, and that every file c035f2e7 changes since its merge base with 09a2876f has c035f2e7's blob in both branches, except the override log. It does not establish the unit's review status.
**Legibility-target:** for-orchestrator-synthesis

35e13638's parents are `09a2876f c035f2e7` (`… (override-log appends: both sides kept)`). `git log 35e13638 ^09a2876f ^c035f2e7` lists only the merge itself. Over the 19 files changed from f5b7e49d to c035f2e7, every blob in 35e13638 and 6c841192 equals c035f2e7's, except `docs/reviews/override-log.md`, the resolved file (paraphrased — no quote available because the evidence is a blob-comparison loop).

**Evidence:** `docs/working/questions.md:115`

---

## Claim 17: "both orders of Q-163 and Q-164 were run against main and land the same tree" (and landing `chore/q180-repin-pastes` first, then the pastes, does not conflict)

**Location:** `docs/working/questions.md:115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the actual paste blocks, with only the `cd` target rewritten, run in scratch clones of `/workspace` under bash and zsh, both with and without Q-180 landed first. It does not establish behaviour if main moves again before the pastes.
**Legibility-target:** for-orchestrator-synthesis

`$S/sim.sh {bash,zsh} {a,b}` (Q-180 landed first; a = 162, 164, 163 and b = 162, 163, 164; 2026-10-15T21:02:48Z): every paste merged with status clean. The final tree is `e12d4a6a…` in all four runs, and it differs from 6c841192's only by Q-180's three files. Q-162's exit 128 comes from its cleanup loop, because the clone has no `.claude/wt-build-loop-*` worktrees; its merge did land. `$S/sim-noq180.sh bash {a,b}` (bare main): the final tree is `55bca2bf…` in both orders, equal to 6c841192's tree. Q-180's own landing merged without conflict.

**Evidence:** `docs/working/questions.md:115`, `$S/logs/sim-bash-a.log`, `$S/logs/sim-bash-b.log`, `$S/logs/sim-zsh-a.log`, `$S/logs/sim-zsh-b.log`, `$S/logs/simnoq180-a.log`, `$S/logs/simnoq180-b.log`

---

## Claim 18: Branch selection: Q-163 takes 6c841192 if U5 (7c91b974) is on main, else 35e13638; Q-164 takes 6c841192 if Q-145 (c035f2e7) is on main, else 7326d715

**Location:** `docs/working/questions.md:121` (Q-163), `:153` (Q-164)
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers both branches of each `if` as exercised by the two orders. It does not cover a main that holds one unit through some other merge.
**Legibility-target:** for-orchestrator-synthesis

```
# docs/working/questions.md:121 (Q-163, line 4 of 5)
if git merge-base --is-ancestor 7c91b97455db9fba1b155a2bb866abf6b86f1904 HEAD; then B=6c841192bf298d8cc22affc1cc5779b5ad6d5d2d; else B=35e1363882321fe15444b13a245f89bd1bc22054; fi && \
# docs/working/questions.md:153 (Q-164, line 4 of 5)
if git merge-base --is-ancestor c035f2e77f8c083156b397fb32e164dd17cc6b44 HEAD; then B=6c841192bf298d8cc22affc1cc5779b5ad6d5d2d; else B=7326d7159fe390fdb7780966fb3392ecf3a995ee; fi && \
```

In order a, Q-164 took the else branch (7326d715) and Q-163 then took the then branch (6c841192). Order b mirrored that. Both landed the same tree (Claim 17). In zsh, `if … fi &&` inside an `&&` chain parses the same as in bash (the zsh runs above).

**Evidence:** `docs/working/questions.md:121`, `docs/working/questions.md:153`, `$S/logs/sim-zsh-a.log`, `$S/logs/sim-zsh-b.log`

---

## Claim 19: Q-164: "`merge/build-loop-u5-resolved-r2` at 7326d715 (Q-162's branch plus U5, by the earlier reviewed resolution e088c7e3 …); U5's entries Q-103 and Q-149..Q-156 are byte-identical to e088c7e3's"

**Location:** `docs/working/questions.md:147`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the parentage, and byte equality of each entry (heading to the next `### Q-` or `## `) between e088c7e3 and both 7326d715 and 6c841192. It does not establish the regenerated indexes.
**Legibility-target:** for-orchestrator-synthesis

7326d715's parents are `09a2876f e088c7e3`. `git log 7326d715 ^09a2876f ^7c91b974` lists only 7326d715 and e088c7e3, and e088c7e3's other parent, 46942678, is already on main. A Python extractor printed `identical` for Q-103 and Q-149..Q-156 in both branches. Q-154 is in `questions-archive.md` on both sides, and its archived entry also compared equal (`True`) (paraphrased — no quote available because the evidence is a script's output).

**Evidence:** `docs/working/questions.md:147`

---

## Claim 20: Q-164: "main's Next 3–6 kept and U5's C5 item added as 7, both Ideas lists kept, U5's decision-015 idea dropped since main's Next 5 holds it, indexes regenerated"

**Location:** `docs/working/questions.md:147`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the roadmap of 7326d715 against 09a2876f (identical to main's roadmap) and against e088c7e3. It does not establish the questions index or the override log.
**Legibility-target:** for-author

`diff` of the 09a2876f and 7326d715 roadmaps: Next items 1–6 are unchanged, and `7. **Revisit the light pass between full cycles (C5, Q-154).**` is added. Ideas go from 28 to 35 bullets, the 28 plus U5's 7 additions (`A process for writing a repo's constraints doc` … `install.sh's archive honors replace refs`). The Now bullet `U5, the build-loop handoff's last unit` and the In-flight `Build-loop handoff` bullet are removed, and a Done bullet is added; the sentence does not mention these. The decision-015 idea (`- **Re-run decision 015's step 4 as a divergent design (Q-105 [3]).**`, `e088c7e3:docs/roadmap.md:140`) is absent, and main's Next 5 (`5. **Decision 015's re-run: apply the outcome (Q-170).**`) holds it. That idea is not U5's: `git grep "Re-run decision 015"` finds it in 46942678 (the 2026-10-14 cycle commit) and not in 7c91b974. Precise version: "the 2026-10-14 cycle's decision-015 idea (moved to Ideas by e088c7e3) dropped".

**Evidence:** `docs/working/questions.md:147`, `7326d715:docs/roadmap.md:90-105`, `e088c7e3:docs/roadmap.md:140-142`

---

## Claim 21a: Q-167(b) line 3, `cc-isolated --profile '#' --list`: on a pre-fix launcher it lists harmlessly; on the fixed launcher (f6f37fad) it prints an ERROR with exit 2

**Location:** `docs/working/questions.md:225`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers main's and f6f37fad's `devcontainer-config/cc-isolated.sh`, run from `git archive` copies with a scratch HOME. It does not establish behaviour on the user's installed host launcher.
**Legibility-target:** for-orchestrator-synthesis

On main, `--profile` stores any value and `--list` exits before the value is used:

```
# main:devcontainer-config/cc-isolated.sh:738-745 (excerpt of main()'s parse loop, :732-751 — read)
      --profile)
        …
        profiles="$2"; shift 2 ;;
```
`main:devcontainer-config/cc-isolated.sh:789-792`: `case "$action" in … list)  list_projects;  exit 0 ;;`. At f6f37fad, `devcontainer-config/cc-isolated.sh:795-796` reads `case "$2" in \#*) pasted_note_error "$2" "an egress profile" ;;`. Run (cwd `$S/cci`, 2026-10-15T21:05Z): main exited 0 with `No projects registered …`; f6f37fad exited 2 with `ERROR: \# is not an egress profile; it looks like a pasted comment.` Security final F3 is closed: line 3 no longer runs `--bless` on a pre-fix launcher.

**Evidence:** `docs/working/questions.md:225`, `main:devcontainer-config/cc-isolated.sh:732-792`, `f6f37fad:devcontainer-config/cc-isolated.sh:778-810`, `$S/logs/cci-main.log`, `$S/logs/cci-f6f37fad.log`

---

## Claim 21b: "each of the first three must print an ERROR and `exit=2` with nothing done (on a launcher older than the fix, the third prints the project list instead: the install has not taken effect, so stop there)"

**Location:** `docs/working/questions.md:220`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers lines 1–3 on both launchers, with zsh's default non-interactive-comments word splitting simulated as explicit argv. It does not establish what line 1 does on the host when `~/code/b` exists.
**Legibility-target:** for-author

The atom about the third line is true (Claim 21a). The note reads as if only the third line deviates on an older launcher, but the first two deviate too. Line 2 (`--list '#' registered projects`) on main exited 0 and printed the project list (`$S/logs/cci-line2-main.log`); on f6f37fad it exited 2 with `ERROR: \# is not a workspace`. Line 1 on main has no two-workspace check: `main:devcontainer-config/cc-isolated.sh:750` reads `*)            ws_arg="$1"; shift ;;`, so the last path wins and the launch proceeds. In the sandbox it stopped at `ERROR: devcontainer CLI not found` (exit 1, `$S/logs/cci-line1-main.log`); on the host it would stop at `ERROR: not a directory` (exit 1) or launch `~/code/b` if that exists. Precise version: "on a launcher older than the fix, the first line exits 1 (or launches) and the next two print the project list: stop at the first line that is not ERROR with exit=2".

**Evidence:** `docs/working/questions.md:220-227`, `main:devcontainer-config/cc-isolated.sh:354-367`, `$S/logs/cci-line1-main.log`, `$S/logs/cci-line2-main.log`, `$S/logs/cci-line2-f6f37fad.log`

---

## Claim 22: Q-169 pins `d25254dae30fe05fd385b3ff430104fb63c39158:docs/working/spike-cc-verify-q117.md`, and "The hash must be `032cc9a8…afb7`"

**Location:** `docs/working/questions.md:263-267`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the extracted block's sha256 at the new pin (and at the old pin a760a5e5), and that d25254da is the docs branch's tip. It does not establish the in-script `script sha256 a65f4c30ba1b8907` line.
**Legibility-target:** for-orchestrator-synthesis

The paste's own command (minus `cd`/`mkdir`, cwd `/workspace/.claude/wt-q180`, 2026-10-15T21:07:19Z) printed `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7` at both d25254da and a760a5e5. `docs/branch-verify-without-install` resolves to d25254dae30f…, and the fenced block is 498 lines with its fences.

**Evidence:** `docs/working/questions.md:263-267`, `$S/logs/counts.log`

---

## Claim 23: Q-169: "'Not verified' (12 items only this run can show)"

**Location:** `docs/working/questions.md:270`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers the item count of the section at the pinned commit. It does not establish each item's content.
**Legibility-target:** for-orchestrator-synthesis

`d25254da:docs/working/spike-cc-verify-q117.md`'s `## Not verified (needs the host run)` has numbered items `1. **Image naming**` through `12. **The build's network, time and cache.**`. The count script printed `12`.

**Evidence:** `docs/working/questions.md:270`, `$S/logs/counts.log`

---

## Claim 24: Q-170: "since 2026-09-09 88 of 116 `devcontainer-config/` commits carry `Live-verified: no`"

**Location:** `docs/working/questions.md:280`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers non-merge commits reachable from f050b487 (the DD's commit) with `^Live-verified: no` in the body. It does not establish today's count, which is 95 of 123 at 09a2876f and 88 of 110 at main, and it does not establish agreement with the DD doc, which still says 87.
**Legibility-target:** for-orchestrator-synthesis

The count loop (`git log --no-merges --since=2026-09-09 -- devcontainer-config/`, grep `^Live-verified: no`) printed `f050b487 total=116 live-no=88`. The doc this bullet tells you to read still says `**87 carry `Live-verified: no` and 1 carries a hash**` (`f050b487:docs/working/dd-015-step4-isolation-mechanism.md:34`), so the entry and its source now disagree by one. The entry's number is the correct one.

**Evidence:** `docs/working/questions.md:280`, `$S/logs/counts.log`

---

## Claim 25: Q-176: `mkdir ~/q092 && mkdir ~/q092/.claude && …`, "It also stops if `~/q092` already exists, so nothing planted there is reused"

**Location:** `docs/working/questions.md:390`, `:406`
**Type:** Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers a pre-existing directory, file or dangling symlink at `~/q092`, in bash and zsh. It does not establish safety against a same-uid writer that plants into `~/q092` after the `mkdir` succeeds.
**Legibility-target:** for-orchestrator-synthesis

Probe (`HOME=$S/q092h-<kind>-<sh>`, `mkdir ~/q092 && mkdir ~/q092/.claude && echo PROCEEDS`, 2026-10-15T21:06Z): with nothing there, rc 0. A directory, a file or a dangling symlink at `~/q092` each gave rc 1 in both shells, and the symlink's target was never created (`nowhere-exists=n`). This closes security final F4 (paraphrased — no quote available because the probe output was terminal-only, eight one-line results).

**Evidence:** `docs/working/questions.md:390`, `docs/working/questions.md:406`

---

## Claim 26: Commit 53bd1a56 message: the rebuilt hashes; "The pastes' guard also refuses info/grafts and shallow (security final F1); the merge runs with GIT_NO_REPLACE_OBJECTS=1 and hooks off; each says it runs in the container (F2)"; "Q-163 and Q-164 stop unless Q-162's merge is on main; both orders were run against main and land the same tree"; Q-167(b), Q-176, Q-169 and the wording fixes; the ready-r2 gate

**Location:** commit 53bd1a56 (`git log main..HEAD`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Scope:** Covers each bullet against Claims 6, 9, 13, 14, 15 and 17–25. It does not establish the Q-180 entry itself, which is on main and outside this diff.
**Legibility-target:** for-orchestrator-synthesis

The four hashes match `git rev-parse` of the four `-r2` branches. Q-162 says `Paste the block into the container's shell` (`docs/working/questions.md:84`), and Q-163 and Q-164 each say `run it in the container's shell, as for Q-162` (`:115`, `:147`). The commit message repeats none of Claim 7's overclaim. Its "Q-162's conflict list" wording inherits Claim 8's imprecision.

**Evidence:** `docs/working/questions.md:84`, `docs/working/questions.md:115`, `docs/working/questions.md:147`

---

## Claim 27: Commit 46342d66 message: "U5 was built on 2026-10-14 and waits on Q-164. It now records the paste order (Q-180's branch, Q-162, Q-164/Q-163, Q-156) and that the first Q-162 paste aborted cleanly on the stale pin."

**Location:** commit 46342d66 (`git log main..HEAD`)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Scope:** Covers the message against the checkpoint diff and Claims 2–4. It does not establish the U5 build date beyond its commit dates.
**Legibility-target:** for-orchestrator-synthesis

The checkpoint's Blocked-on line gives the order `land chore/q180-repin-pastes …, then Q-162 …, then Q-164 [1] and, if wanted, Q-163, in either order, then Q-156's release` (`docs/working/checkpoint-build-loop-handoff.md:10`). The abort is Claim 4.

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:10`

---

## Claims Requiring Attention

### Incorrect
- **Claim 7** (`docs/working/questions.md:84`): "the hash names fixed content once the paste has checked … replace refs, info/grafts or shallow" is not sufficient. Executed: an overwritten loose blob in `.git/objects` lands other content past the guard. A planted merge driver (`info/attributes` plus `merge.X.driver`, not covered by `core.hooksPath=/dev/null`) rewrote `docs/roadmap.md` and `questions.md` in Q-164's merge after Q-180's landing. Narrow the sentence to what the guard checks, or name these residuals.

### Mostly Accurate
- **Claim 5** (`docs/working/checkpoint-build-loop-handoff.md:48`): Q-154 is already answered and archived on U5's branches, so it is not a live ask.
- **Claim 8** (`docs/working/questions.md:84`): the five conflicts are with main (all five conflict with b71a4e9e alone). Q-110 and dd-015 conflict with no earlier unit.
- **Claim 11** (`docs/working/questions.md:86`): the added lines are the same, but in the override log they are inserted before a760a5e5's rows rather than appended, so the diff is not literally main's.
- **Claim 20** (`docs/working/questions.md:147`): the dropped decision-015 idea is the 2026-10-14 cycle's (46942678, moved to Ideas by e088c7e3), not U5's.
- **Claim 21b** (`docs/working/questions.md:220`): on a pre-fix launcher, lines 1 and 2 already deviate (line 1 exits 1 or launches; line 2 lists), not only the third.

### Unverifiable
- none

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path you were given, structured per your skill.
- Answered: yes. All 12 brief claim groups were checked, most by execution (paste simulations in both shells and orders, guard probes, merge replays, launcher runs, the 3/3 T23 re-run). F1–F4 are closed.
- Out of scope: the Q-180 entry itself (on main, not in this diff); the U5 and Q-145 code content; whether the user's host git verifies blob hashes differently from the container's git 2.39.5.
- Escalate: Claim 7. Under the threat the entry itself names (agent-writable `/workspace/.git`), object-file rewrites and planted merge drivers or filters change landed content past the guard. The merge-driver case is live for Q-163 and Q-164 in the checkpoint's order (Q-180's branch first). A config/`info/attributes` check, or `-c merge.<driver>` neutralisation, is a security-reviewer call, not a wording fix.
- Decisions I made: verdicted Claim 7 Incorrect rather than Mostly accurate because its stated sufficient condition is refuted by execution, even though both residuals predate this diff. I treated the checkpoint's order (Q-180's branch first) as the operative one for the merge-driver probe.
