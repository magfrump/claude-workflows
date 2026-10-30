Commit: 46342d66

# Code Fact-Check Report

**Repository:** /workspace/.claude/wt-q180 (branch `chore/q180-repin-pastes`, HEAD 46342d66, vs main b71a4e9e)
**Scope:** full branch diff `git diff main...HEAD` (docs/roadmap.md, docs/working/checkpoint-build-loop-handoff.md, docs/working/questions.md) plus the two commit messages in `git log main..HEAD`; claims checked against the branches and commits they name. Replicate 2.
**Checked:** 2026-10-15
**Total claims checked:** 27
**Summary:** 24 verified, 2 mostly accurate, 0 stale, 0 incorrect, 1 unverifiable

Hallucination log: `docs/reviews/hallucination-patterns.md` read; no logged pattern resembles any claim here (the closest, a miscounted test tally, does not match: every count below recounted equal).

Execution environment for all `executed` claims: bash 5 / zsh in the review container, git as installed, scratch directory `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/cfc-r2/` (abbreviated `$S` below; all logs live there because this run may write only this report). Every probe ran under `timeout`; the detached worktree and scratch clones were removed before reporting, and no process was left running.

---

## Claim 1: "Cycle 2 (2026-10-14): 42 multi-file landings after cac2ba0c (cycle 1's own three landings excluded); 25/42 carry the line, 38/42 committed a rubric, 4/42 have neither (df18413a, 0fbf9742, b8807e76, 52053432)"

**Location:** `docs/roadmap.md:77-80`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the four figures and four hashes as first-parent merges of b279a2ba after cac2ba0c touching more than one file, "line" = `← carried from RPI` in the body, "rubric" = an A/M `docs/reviews/code-review-rubric*` path; does not establish the "About 36" estimate or the cycle-3 figures.

cac2ba0c is the *latest* of cycle 1's three landings on the first-parent line (`git log --first-parent b279a2ba`: `cac2ba0c 2026-10-02 18:20`, `188e0a7d 16:51`, `90364c73 14:43`), so "after cac2ba0c" alone excludes all three, matching the parenthetical. Command `bash $S/uptake.sh b279a2ba cac2ba0c` (cwd the worktree, exit 0, 2026-10-15T14:05) printed:

```
tip=b279a2ba since=cac2ba0c skip=[] n=42 line=25 rubric=38 neither: df18413a 0fbf9742 b8807e76 52053432
```

**Evidence:** `docs/roadmap.md:77-80`; `$S/uptake.sh` (output quoted above, captured in this session's transcript; rerunnable)

---

## Claim 2: "U4c merged at 308196e7 (Q-144 [1]); U5 built and reviewed on `feat/build-loop-u5` (tip 7c91b974 …), not merged … it lands inside `merge/build-loop-u5-resolved-r2` 7326d715 or `merge/u5-and-q145-r2` 6c841192"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:2-3`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the merge commit, its subject's Q-144 tag, U5's tip and non-merge state, and ancestry of 7c91b974 in both named branches; does not establish the review history inside U5's rubric beyond its loop-outcome line.

`git log -1 308196e7`: `Merge branch 'feat/build-loop-u4c': … step 0.1's image checks (Q-144 [1])`, an ancestor of main. `git rev-parse feat/build-loop-u5` = `7c91b97455db…`; `git merge-base --is-ancestor 7c91b974 main` fails (not merged). 7326d715's second parent is e088c7e3, whose second parent is 7c91b974; 6c841192's second parent is 7326d715. The rubric's "Loop outcome" line says the final pass "met exit condition 2" and a narrow k=1 check followed (`docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md:140-144` at 7c91b974), consistent with "loop ended escalate, narrow check held".

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:2-3`; `git log --first-parent 09a2876f..6c841192`; rubric at 7c91b974 `:140-144`

---

## Claim 3: "Order for the user's pastes, all in the container's `/workspace`: land `chore/q180-repin-pastes` …, then Q-162 (`merge/ready-2026-10-15-r2`, 09a2876f), then Q-164 [1] and, if wanted, Q-163, in either order, then Q-156's release"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:10`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the branch's own Q-162/163/164 paste blocks run verbatim (only `cd /workspace` re-targeted and the deletion loop replaced by an echo) in scratch clones under bash and zsh, chore branch landed first; does not establish Q-156's release paste or behaviour on a /workspace with planted config (see Claim 9b).

Command: `bash $S/paste-run.sh {bash,zsh} $S/pr-{bash,zsh}` (cwd scratchpad, 2026-10-15T14:06:16, runner exit 0 both). Excerpt of `$S/paste-run.log`:

```
--- Q-163 before Q-162:  Q-162's merge is not on main: run it first   exit=1
--- Q-164 before Q-162:  Q-162's merge is not on main: run it first   exit=1
--- Q-162:  Merge made by the 'ort' strategy.  DELETION-STEP-REACHED   exit=0
--- Q-164:  Auto-merging docs/roadmap.md / Auto-merging docs/working/questions.md … exit=0 merged 2nd parent=7326d715
--- Q-163:  exit=0 merged 2nd parent=6c841192
final tree e12d4a6a…  expected (6c841192 merged with chore): e12d4a6a…
```

The reverse order (Q-163 then Q-164) was run with merge-tree/commit-tree in `$S/orders.sh` (log `$S/orders.log`, exit 0, 14:01:16), including the chore-first variant: every step merged cleanly and both orders give tree 55bca2bf, equal to 6c841192's.

**Evidence:** `docs/working/questions.md:88-92,117-123,149-155`; `$S/paste-run.sh`, `$S/paste-run.log`, `$S/orders.sh`, `$S/orders.log`

---

## Claim 4: "The first Q-162 paste on 2026-10-15 aborted on the override-log conflict, as its note said (a760a5e5 predated Q-178's landing); main was left clean."

**Location:** `docs/working/checkpoint-build-loop-handoff.md:10` (also commit 46342d66's body)
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** executed
**Scope:** Covers that merging a760a5e5 into main conflicts only in the override log and that the main checkout shows no merge in progress and no merge on main's reflog; does not establish from a log that the user's paste actually ran (the event itself left only indirect traces).

`git merge-tree --write-tree --name-only main a760a5e5` exits 1 with `CONFLICT (content): Merge conflict in docs/reviews/override-log.md` and no other path. `/workspace/.git/MERGE_HEAD` does not exist, `/workspace/.git/ORIG_HEAD` holds `b71a4e9e…` (what an aborted merge at main leaves), and `git reflog refs/heads/main` tops out at `b71a4e9e … merge chore/dev-cycle-2026-10-15-0357`. Medium, because ORIG_HEAD is also written by other commands (paraphrased — no quote available because the claim is about a past interactive event that left no log of its own).

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:10`; `/workspace/.git/ORIG_HEAD`; `git reflog refs/heads/main`

---

## Claim 5: "U5 was built and reviewed on 2026-10-14 (rubric `docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md` on the branch)"

**Location:** `docs/working/checkpoint-build-loop-handoff.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the file's presence at 7c91b974 and absence on main; does not establish the "Q-149..Q-155 and Q-103 become the live asks" projection, which is a plan, not a fact.

`git ls-tree 7c91b974 docs/reviews/code-review-rubric-2026-10-14-feat-build-loop-u5.md` lists blob `88ade200…`; the same `ls-tree` on main prints nothing.

**Evidence:** `docs/working/checkpoint-build-loop-handoff.md:48`

---

## Claim 6: "Paste the block into the container's shell … never in your host checkout: it runs git in `/workspace`, where an agent session can plant hooks and config." (and Q-163/Q-164: "run it in the container's shell, as for Q-162")

**Location:** `docs/working/questions.md:84`, `:115`, `:147`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each of the three pastes begins `cd /workspace` and now carries the container-shell instruction (closing prior finding F2); does not establish that hooks and config are the only agent-plantable inputs (see Claim 9b).

Each block's first line is `cd /workspace && test "$(git branch --show-current)" = main && \` (`docs/working/questions.md:89`, `:118`, `:150`), and the prose lines quoted above appear at `:84`, `:115`, `:147`.

**Evidence:** `docs/working/questions.md:84,89,115,118,147,150`

---

## Claim 7: "`merge/ready-2026-10-15-r2` … 09a2876f … That branch is main (as of b71a4e9e) plus seven reviewed units, the branch-verify research and spike docs …, and the decision-015 divergent design …, each merged with `--no-ff`"

**Location:** `docs/working/questions.md:84`, `:86`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the nine first-parent merges of 09a2876f over b71a4e9e and their second parents, and that each of a760a5e5's ten cycle-record merges is already on main; does not establish that each unit tip is the reviewed one (taken from the brief's list).

`git log --first-parent --format='%h %p %s' main..09a2876f` gives nine merges whose second parents are, in order, 4ee81106, f5b7e49d, c8e87a69, 4a44d2f3, 8717fd72, d25254da, f050b487, 47da5a4b, f6f37fad, with first parent of the oldest `b71a4e9e`; `merge-base 09a2876f main` = b71a4e9e. Of a760a5e5's chore merges, second parents de9590ad, 8781b882, b9b4d59a, 5f0f00d9, 7550465b, d4445c9a, e1ad59fd, 3356974b, 782036de and 92f3b080 are all ancestors of main.

**Evidence:** `docs/working/questions.md:84,86`; `git log --first-parent main..09a2876f`, `git log --first-parent 92f3b080..a760a5e5`

---

## Claim 8: "five of those nine merges (Q-110, doc drift, Q-160 and the two docs branches) conflict with an earlier one, each only in the append-only `docs/reviews/override-log.md`"

**Location:** `docs/working/questions.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers a replay of each of the nine merges with `git merge-tree --write-tree` on its actual first parent, and that each recorded merge tree differs from git's automatic result only in the override log; does not establish the row ordering chosen inside the resolutions.

Replay (cwd the worktree, 14:00, exit 0): `4ee81106 rc=0`, `f5b7e49d rc=1 docs/reviews/override-log.md`, `c8e87a69 rc=1 …override-log.md`, `4a44d2f3 rc=1 …override-log.md`, `8717fd72 rc=0`, `d25254da rc=1 …override-log.md`, `f050b487 rc=1 …override-log.md`, `47da5a4b rc=0`, `f6f37fad rc=0`. Diffing each recorded merge against its merge-tree result lists only `docs/reviews/override-log.md` for exactly those five commits, nothing for the other four.

**Evidence:** `docs/working/questions.md:84`; replay loop output in this session's transcript (rerunnable from the commit list in Claim 7)

---

## Claim 9a: "once the paste has checked that no replace refs, `info/grafts` or `shallow` file exists, and the merge itself ignores replace refs" (the guard's mechanics)

**Location:** `docs/working/questions.md:84`, guard at `:90`, `:119`, `:151`
**Type:** Behavioral / Error-handling
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the guard line verbatim under bash and zsh: replace refs, empty and dangling-symlink `info/grafts` and `shallow`, a linked worktree, `GIT_GRAFT_FILE`, and the failure arm's `git merge --abort`; does not establish behaviour under `GIT_REPLACE_REF_BASE` beyond what is noted, or the merge-driver residual (Claim 9b).

The guard:

```sh
# docs/working/questions.md:90
{ test -z "$(git for-each-ref refs/replace/)" && g="$(git rev-parse --git-path info/grafts)" && s="$(git rev-parse --git-path shallow)" && test ! -e "$g" && test ! -L "$g" && test ! -e "$s" && test ! -L "$s" || { echo "replace refs, info/grafts or shallow present: stop"; false; }; } && \
```

`bash|zsh $S/guard-probe.sh` (14:02:09, exit 0 both; `$S/guard-probe.log`): clean repo PASS; empty grafts, empty shallow, dangling-symlink grafts or shallow, and a replace ref each print the stop line, from the main worktree and from a linked worktree. In a linked worktree `--git-path info/grafts` and `--git-path shallow` resolve to the common dir (`…/r/.git/info/grafts`, `…/r/.git/shallow`), which is where git reads them (a per-worktree `shallow` is not read: `is-shallow: false`). `GIT_GRAFT_FILE=$P/gf` is honoured by `--git-path` (prints `$P/gf`), so that route is refused too. `GIT_REPLACE_REF_BASE=refs/alt/` passes the guard (`refs/replace/` is empty) and redirects lookups in the unguarded `merge-base --is-ancestor` selection, but `GIT_NO_REPLACE_OBJECTS=1` restores the real object for the merge (`log` of A shows `b` under the base, `a` with NO_REPLACE). Failure arm (`$S/abort-probe.log`, 14:06:58): on a real conflict it aborts, leaves no MERGE_HEAD and returns 1; on a non-conflict failure (dirty tracked file) `git merge --abort` prints `fatal: There is no merge to abort`, the line still prints "conflict: merge aborted, nothing deleted" and returns 1, so nothing merges or is deleted; only the word "conflict" is wrong in that case.

**Evidence:** `docs/working/questions.md:90-91,119-122,151-154`; `$S/guard-probe.sh`, `$S/guard-probe.log`, `$S/abort-probe.sh`, `$S/abort-probe.log`

---

## Claim 9b: "a branch name can move; the hash names fixed content once the paste has checked … and the merge itself ignores replace refs" (the guarantee the sentence gives for what the paste lands)

**Location:** `docs/working/questions.md:84`
**Type:** Invariant
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers whether the paste's merge form lands only the pinned content when /workspace's own config is agent-written; does not establish exploitability end to end in the real container or any fix.

The literal statement holds: with no replace refs, grafts or shallow, the hash names one commit graph and tree, and alternates do not change that mapping (paraphrased — no quote available because this is git's content-addressing model, not repo code). But the sentence is the reason the paste is safe to run, and the paste runs in `/workspace`, whose config the same entry says an agent can plant. `git -c core.hooksPath=/dev/null` turns off hooks only. `bash $S/driver-probe.sh $S/dp` (14:02:21, exit 0; `$S/driver-probe.log`) ran the paste's exact merge form in a repo with `merge.evil.driver` in `.git/config` and `f merge=evil` in `.git/info/attributes`:

```
Merge made by the 'ort' strategy.   merge exit=0
merged f:  planted-content
merge tree == ort tree without driver? no
driver.log: driver-ran      fsm.log lines: 4   (core.fsmonitor also ran)
```

In the documented order (chore branch first), Q-164's merge three-way merges `docs/roadmap.md` and `docs/working/questions.md` (`Auto-merging docs/roadmap.md`, `Auto-merging docs/working/questions.md` in `$S/paste-run.log`), so a planted driver would decide what lands in those two files. Gate code changes on one side only and is not passed through a driver. A precise version: "the hash names fixed content …; what lands can still differ through repo-config merge drivers or filters, so the guard does not cover a planted `.git/config`" (or add `-c` overrides / a config check for `merge.*.driver`).

**Evidence:** `docs/working/questions.md:84,91,122,154`; `$S/driver-probe.sh`, `$S/driver-probe.log`, `$S/paste-run.log`

---

## Claim 10: "then deletes the twelve build-loop branches already merged into main, along with their worktrees"

**Location:** `docs/working/questions.md:84`, loop at `:92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers that each of the twelve `feat/build-loop-<u>` branches named in the loop is an ancestor of main and has a clean worktree at `.claude/wt-build-loop-<u>`; does not establish the loop's behaviour if a removal fails midway (it stops that iteration's `&&` only).

For u3a1, u3a2, u3a3, u3b1, u3b2, u3b3, u3c, u3d, u4a, u4b1, u4b2, u4c: `merge-base --is-ancestor <branch> main` succeeds, the worktree exists, is on that branch, and `status --porcelain` is empty (output: `u3a1 merged wt on=feat/build-loop-u3a1 dirty=0` … `u4c merged wt on=feat/build-loop-u4c dirty=0`).

**Evidence:** `docs/working/questions.md:92`

---

## Claim 11: "Run it before Q-163 and Q-164: their pastes stop unless this merge is on main."

**Location:** `docs/working/questions.md:84`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers both pastes run before Q-162 under bash and zsh; does not establish behaviour if 09a2876f reached main by some other route (the check accepts any ancestry, which is the intent).

```sh
# docs/working/questions.md:120
{ git merge-base --is-ancestor 09a2876ff5ea6f7e5b86eea723c2aa0094759145 HEAD || { echo "Q-162's merge is not on main: run it first"; false; }; } && \
```

Run before Q-162, each paste printed that line and exited 1 with HEAD unchanged (`$S/paste-run.log`, both shells).

**Evidence:** `docs/working/questions.md:120,152`; `$S/paste-run.log`

---

## Claim 12: "Its diff from a760a5e5 is exactly main's own change since then"

**Location:** `docs/working/questions.md:86`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers content: outside the override log `git diff a760a5e5 09a2876f` is byte-identical to `git diff 92f3b080 main` (92f3b080 being a760a5e5's last main-side input), and in the override log the same 15 lines are added; does not establish row *position*: main's 15 rows sit at a different place relative to a760a5e5's rows, so the two patches are not byte-identical as whole files.

`cmp` of the two path-limited patches excluding `docs/reviews/override-log.md`: `REST-IDENTICAL`; `cmp` of their `+`/`-` lines inside the override log: `SAME-ADDED-LINES` (15). The whole patches first differ at the override-log hunk header (`@@ -825,6 +825,21 @@` vs `@@ -825,3 +825,18 @@`).

**Evidence:** `docs/working/questions.md:86`; `$S/d1.patch`, `$S/d2.patch`, `$S/o1`, `$S/o2`, `$S/x1`, `$S/x2`

---

## Claim 13: "its override-log rows are exactly the union of a760a5e5's and main's"

**Location:** `docs/working/questions.md:86`
**Type:** Invariant
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the set of distinct lines (853 in each); does not establish ordering, and the only repeated line is the blank line (13 copies), so no row is duplicated.

`sort -u` of a760a5e5's and main's files equals `sort -u` of 09a2876f's (`UNION-SET-EQUAL`, 853 lines); `uniq -c | awk '$1>1'` on 09a2876f's sorted file shows only `13 ` (blank).

**Evidence:** `docs/working/questions.md:86`; `$S/a.txt`, `$S/m.txt`, `$S/r.txt`, `$S/u.txt`, `$S/ru.txt`

---

## Claim 14: "The first tip, a760a5e5, added after that gate the rebuild-hint and one-workspace unit merges …, two docs-branch merges and nine cycle-record merges."

**Location:** `docs/working/questions.md:103`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the first-parent merges of a760a5e5 after 3fe6d6e3; does not establish the 3fe6d6e3 gate result itself (unchanged text).

After 3fe6d6e3 the first-parent line has rebuild-hint (c29d1acf), one-workspace (fc4c6840), two docs merges (a53e1bc2, 11184f2b) and nine `chore/dev-cycle-2026-10-15-0357` merges (7e9c039c, 9660d4f6, 184396ea, 00a27a2f, 5e6e9266, 1d67d12c, 7a9cf412, 302c3810, a760a5e5).

**Evidence:** `docs/working/questions.md:103`; `git log --first-parent 92f3b080..a760a5e5`

---

## Claim 15: "Gate for the rebuilt tip (09a2876f …): the fast suites had one red, build-loop-merge's T23 test, whose log shows the Q-145 `/tmp` race …; it passes 3/3 alone. The slow suites, run separately: 300/300. Shellcheck and the other checks passed."

**Location:** `docs/working/questions.md:104`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two logs' content and an independent 3/3 re-run of that test at 09a2876f; does not establish from the logs themselves which commit they ran at (they carry no commit stamp).

`health-ready-r2.log` has one `not ok` (`not ok 1103 --merge refuses a file or link where the merge adds a directory … (T23, U3a2; i1 security)`, with `# find: '/tmp/bats-run-0FMk9A/bats.1565803.out': No such file or directory` at `:1310`) and one `✗` (`:1772`, fast suites; slow skipped). `slow-ready-r2.log`: `1..300`, 300 `ok`, 0 `not ok`. Re-run: `timeout 600 bats -f 'merge refuses a file or link where the merge adds a directory' test/scripts/build-loop-merge.bats` in a detached worktree at 09a2876f, three times, exit 0 each (14:00:22, :24, :26), `ok 1 …`.

**Evidence:** `docs/working/questions.md:104`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/health-ready-r2.log:1301-1310,1772`; `/tmp/claude-1000/-workspace/736a173d-70f8-4751-993a-da117d91dc21/scratchpad/slow-ready-r2.log`; `$S/t23-run1.log`, `$S/t23-run2.log`, `$S/t23-run3.log`

---

## Claim 16: "Q-180 rebuilt the branch and hardened this paste (its review: `docs/reviews/code-review-rubric-2026-10-15-chore-q180-repin-pastes.md`)"

**Location:** `docs/working/questions.md:105`
**Type:** Reference
**Verdict:** Unverifiable
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the file's presence at 46342d66; does not establish whether this review will write that path.

The path does not exist at 46342d66 or in the worktree (`git ls-tree -r --name-only HEAD docs/reviews | grep -i q180` prints nothing). It is a forward reference to the rubric this review produces. It needs that file committed before landing.

**Evidence:** `docs/working/questions.md:105`

---

## Claim 17: Q-163: "It merges `merge/q145-r2` at 35e13638 (Q-162's branch plus this unit …), or `merge/u5-and-q145-r2` at 6c841192 (that plus U5) if U5 is already on main … both orders of Q-163 and Q-164 were run against main and land the same tree. The unit's own tip, c035f2e7, is unchanged inside them."

**Location:** `docs/working/questions.md:115`, paste `:117-123`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers branch composition, the `if … is-ancestor 7c91b974` selection in both cases, conflicts (override log only, resolved) and both orders; does not establish the Q-145 fix's correctness.

35e13638 = merge(09a2876f, c035f2e7); 6c841192 = merge(35e13638, 7326d715). Each conflicts only in the override log, and each recorded tree differs from git's automatic one only there. The selection `if git merge-base --is-ancestor 7c91b974… HEAD; then B=6c841192…; else B=35e13638…; fi` (`:121`) picked 35e13638 when U5 was absent and 6c841192 after Q-164 had landed 7326d715 (`$S/paste-run.log`, `$S/orders.log`); both orders end at tree 55bca2bf (= 6c841192's) on main, e12d4a6a with the chore branch first. c035f2e7 is 35e13638's second parent, so its content is unchanged inside.

**Evidence:** `docs/working/questions.md:115,121`; `$S/orders.log`, `$S/paste-run.log`

---

## Claim 18: Q-164: "`merge/build-loop-u5-resolved-r2` at 7326d715 (Q-162's branch plus U5, by the earlier reviewed resolution e088c7e3, with the questions, roadmap and override-log conflicts resolved again: main's Next 3–6 kept and U5's C5 item added as 7, both Ideas lists kept, U5's decision-015 idea dropped since main's Next 5 holds it, indexes regenerated; U5's entries Q-103 and Q-149..Q-156 are byte-identical to e088c7e3's), or `merge/u5-and-q145-r2` at 6c841192 if Q-145 is already on main"

**Location:** `docs/working/questions.md:147`, paste `:149-155`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers parentage, the conflicted paths, the roadmap resolution, entry byte-equality and index validity, and the c035f2e7 selection; does not establish that "questions" in the prose includes `questions-archive.md`, which also conflicted and was resolved (Q-154 lives there).

7326d715's parents are 09a2876f and e088c7e3. `merge-tree 09a2876f e088c7e3` conflicts in override-log, roadmap, questions-archive and questions, and the recorded tree differs from the automatic one in exactly those four. Roadmap at 7326d715: Next items 1–6 are main's (`5. **Decision 015's re-run: apply the outcome (Q-170).**`), plus `7. **Revisit the light pass between full cycles (C5, Q-154).**`; `grep -c 'Re-run decision 015'` = 0; diff main→7326d715 in Ideas is additions only. sha256 of each entry (heading to next `### Q-`): Q-103, Q-149–Q-153, Q-155, Q-156 in questions.md and Q-154 in questions-archive.md are identical across e088c7e3, 7326d715 and 6c841192 (e.g. `Q-103 e0e912961785`, `Q-154 cf6070d6e9da`). `questions.sh check` at 7326d715, 6c841192, 35e13638 and 46342d66: `structure valid, indexes current`, exit 0 (`$S/qcheck.log`). The selection `if … --is-ancestor c035f2e7… HEAD; then B=6c841192…; else B=7326d715…` picked 7326d715 first and 6c841192 after Q-163 (`$S/orders.log`).

**Evidence:** `docs/working/questions.md:147,153`; `$S/qcheck.log`, `$S/orders.log`

---

## Claim 19a: "each of the first three must print an ERROR and `exit=2` with nothing done" for line 3 `cc-isolated --profile '#' --list` (on the fixed launcher)

**Location:** `docs/working/questions.md:220`, `:225`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers f6f37fad's launcher run with a scratch HOME and config dir; does not establish the installed host copy.

```bash
# devcontainer-config/cc-isolated.sh:795-797 (f6f37fad), excerpt of main()'s option loop (continues to :811 — read)
        case "$2" in
          \#*) pasted_note_error "$2" "an egress profile" ;;
          -*)  arg_usage_error "$(printf -- '--profile needs a value, not the flag %q.' "$2")" ;;
```

`HOME=$S/home-f6f37fad bash …/cc-isolated.sh --profile '#' --list` (14:03:40) printed `ERROR: \# is not an egress profile; it looks like a pasted comment.`, the usage text, `exit=2`, and created nothing under HOME (`$S/cc-profile-probe.log`).

**Evidence:** `devcontainer-config/cc-isolated.sh:758-811` (f6f37fad); `$S/cc-profile-probe.log`

---

## Claim 19b: "(on a launcher older than the fix, the third prints the project list instead: the install has not taken effect, so stop there)"

**Location:** `docs/working/questions.md:220`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-author
**Scope:** Covers main's launcher on lines 1–3 with a scratch HOME (no devcontainer CLI); does not establish line 1's behaviour on a host where the CLI is installed and `~/code/b` exists.

Line 3 on main's launcher lists, as stated: `--profile` stores `profiles="$2"` with no check (`devcontainer-config/cc-isolated.sh:745` at main), `--list` sets `action="list"`, and `list) list_projects; exit 0` (`:790`). Run: `No projects registered …`, `exit=0` (`$S/cc-profile-probe.log`). But the third line is not the first sign. Line 2 (`cc-isolated --list  # registered projects; …`) also lists and exits 0 on the old launcher, because `#` falls to `*) ws_arg="$1"` (`:749`) and `--list` ignores it (`$S/cc-lines-probe.log`: main prints `No blessed config …`). Line 1 (`~/code/a ~/code/b`) takes the last word as the workspace and goes on toward a launch; it stopped here only at `ERROR: devcontainer CLI not found`. Precise version: "on a launcher older than the fix, the first line tries a launch and the second and third print the project list: stop at the first line that does not print an ERROR."

**Evidence:** `devcontainer-config/cc-isolated.sh:732-751,790` (main); `$S/cc-profile-probe.log`, `$S/cc-lines-probe.log`

---

## Claim 20: Q-169 paste pinned to `d25254dae30fe05fd385b3ff430104fb63c39158`; "The hash must be `032cc9a8…afb7`"; "498 lines with its fences"

**Location:** `docs/working/questions.md:263-267`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the paste's own extraction command run at d25254da (and at a760a5e5 and 09a2876f for comparison); does not establish the script's inner `script sha256 a65f4c30…` line (unchanged text).

The paste's `git -c core.useReplaceRefs=false show <c>:docs/working/spike-cc-verify-q117.md | awk '/^```bash$/{f=1;next} f&&/^```$/{exit} f'` gives sha256 `032cc9a81e4e1c9266ec3ad3b5fe7053d9876eb21f5ffa7f0a35f2ccfed4afb7` and 496 lines (498 with fences) at d25254da, a760a5e5 and 09a2876f alike. The doc has one ```` ```bash ```` fence. d25254da is the docs branch's tip and an ancestor of 09a2876f.

**Evidence:** `docs/working/questions.md:263-267`; `$S/q117-d25254dae30fe05fd385b3ff430104fb63c39158.txt`

---

## Claim 21: "'Not verified' (12 items only this run can show)"

**Location:** `docs/working/questions.md:270`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the numbered top-level items under the doc's "Not verified" heading at d25254da; does not count item 8's two sub-bullets separately.

`docs/working/spike-cc-verify-q117.md:664` (d25254da) is `## Not verified (needs the host run)`, followed by items `1. **Image naming**` … `12. **The build's network, time and cache.**`.

**Evidence:** `docs/working/spike-cc-verify-q117.md:664-690` (d25254da)

---

## Claim 22: "since 2026-09-09 88 of 116 `devcontainer-config/` commits carry `Live-verified: no`"

**Location:** `docs/working/questions.md:280`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers non-merge commits touching `devcontainer-config/` since 2026-09-09 reachable from the DD's commit f050b487, with body lines starting `Live-verified: no`; does not establish the count at later refs (88 of 110 on main, 95 of 123 at 09a2876f), and the doc this entry points to still says 87 (`dd-015-step4-isolation-mechanism.md:34`).

`bash -c 'for h in $(git log --no-merges --since=2026-09-09 --format=%H f050b487 -- devcontainer-config/); …grep -q "^Live-verified: no"…'` printed `f050b487 no-merges total=116 lvno=88` (14:04). Without `--no-merges` the total is 118, so the 116 is the non-merge count, as in the DD (`of the 116 non-merge commits touching devcontainer-config/, **87 carry`).

**Evidence:** `docs/working/questions.md:280`; `docs/working/dd-015-step4-isolation-mechanism.md:34` (09a2876f)

---

## Claim 23: "`mkdir ~/q092 && mkdir ~/q092/.claude && …`" and "It also stops if `~/q092` already exists, so nothing planted there is reused"

**Location:** `docs/working/questions.md:390`, `:406`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Verification mode:** executed
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the two `mkdir` steps (a stand-in subdirectory name was used because the harness blocks Bash writes naming `.claude` settings files) for absent, directory, symlink-to-directory, dangling symlink and regular-file `~/q092` under bash and zsh; does not establish anything about a same-uid writer racing after the `mkdir` succeeds.

`bash|zsh $S/mkdir-probe.sh` (14:04:11, exit 0; `$S/mkdir-probe.log`): absent → proceeds; existing dir, symlink to dir, dangling symlink (target not created), regular file → stops; main's old `mkdir -p` on an existing dir → proceeds. That confirms prior finding F4 is closed.

**Evidence:** `docs/working/questions.md:390,406`; `$S/mkdir-probe.sh`, `$S/mkdir-probe.log`

---

## Claim 24: Commit 53bd1a56's message (re-pins, guard, ancestor check, Q-167(b)/Q-176/Q-169 changes, wording, gate)

**Location:** commit `53bd1a56` body
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers each bullet against the diff and the claims above (branch hashes, "the old ones are kept", F1–F4 changes, 12 items, 88 of 116, gate); does not re-verify "Confidence: high", which is a judgment.

The four `-r2` hashes match `git branch --list 'merge/*'`, and the old `merge/ready-2026-10-15` a760a5e5, `merge/build-loop-u5-resolved` 0f94bb77 and `merge/u5-and-q145` a04d9776 still exist. "Each says it runs in the container (F2)" holds for Q-162/163/164 (Claim 6). "Both orders were run against main and land the same tree" is Claim 17. The other bullets are Claims 15 and 19–23. "Q-163/164 gained the Q-162-first ancestor check" matches `:120` and `:152`.

**Evidence:** `git log -1 53bd1a56`; `docs/working/questions.md:84-155`

---

## Claim 25: Commit 46342d66's message: "It now records the paste order (Q-180's branch, Q-162, Q-164/Q-163, Q-156) and that the first Q-162 paste aborted cleanly on the stale pin."

**Location:** commit `46342d66` body
**Type:** Reference
**Verdict:** Verified
**Confidence:** Medium
**Verification mode:** static
**Legibility-target:** for-orchestrator-synthesis
**Scope:** Covers the checkpoint diff carrying both statements; the "aborted cleanly" event rests on Claim 4's indirect evidence.

The checkpoint's Blocked-on line carries the order and the abort sentence (`docs/working/checkpoint-build-loop-handoff.md:10`); see Claims 3 and 4.

**Evidence:** `git log -1 46342d66`; `docs/working/checkpoint-build-loop-handoff.md:10`

---

## Claims Requiring Attention

### Incorrect
- none

### Stale
- none

### Mostly Accurate
- **Claim 9b** (`docs/working/questions.md:84`): the hash pin plus the guard does not fix what lands. Repo-config merge drivers (and `core.fsmonitor`) still run under the paste's merge form, and in the documented order Q-164 three-way merges questions.md and roadmap.md. Narrow the sentence, or add a check or `-c` override for `merge.*.driver`/filters.
- **Claim 19b** (`docs/working/questions.md:220`): on a pre-fix launcher, line 2 already prints the project list and line 1 heads for a launch, so "the third prints the project list" is not the first signal. Say to stop at the first line that does not print an ERROR.

### Unverifiable
- **Claim 16** (`docs/working/questions.md:105`): the cited rubric `docs/reviews/code-review-rubric-2026-10-15-chore-q180-repin-pastes.md` does not exist at 46342d66. Commit it before landing.

Minor notes (no verdict change): the failure arm prints "conflict" for a non-conflict merge failure too (Claim 9a). Q-170's "88" now disagrees with the DD doc's "87", which the entry tells the reader to open (Claim 22). Q-164's "questions … conflicts" also covers questions-archive.md (Claim 18).

## Goal-Alignment Note
- Success criterion (restated verbatim): a markdown report at the output path you were given, structured per your skill.
- Answered: yes. All 12 brief claim groups checked, most by execution; F1–F4 confirmed closed.
- Out of scope: the real container and host (probes ran on scratch repos and launchers with a scratch HOME); Q-156's release paste.
- Escalate: Claim 9b's residual (planted merge drivers/fsmonitor in /workspace's config still act under the hardened pastes) for the security critic to weigh; Claim 16's missing rubric before landing.
- Decisions I made: verdicted the hash sentence in two parts (literal mechanics Verified, implied landing guarantee Mostly accurate); treated "exactly main's change" as content equality and noted the row-position difference in Scope.
